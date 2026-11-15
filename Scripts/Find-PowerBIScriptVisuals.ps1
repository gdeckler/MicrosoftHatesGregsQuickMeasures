#Requires -Version 7.0
<#
.SYNOPSIS
  Inventory Python and R visuals in accessible Microsoft Fabric / Power BI reports.
.DESCRIPTION
  Uses Fabric REST APIs to list workspaces and reports, retrieve report definitions,
  and inspect PBIR and PBIR-Legacy JSON for pythonVisual and scriptVisual.
  The caller needs read/write permission on reports to use getDefinition.
  This does not discover workspaces the caller cannot access.
.EXAMPLE
  ./Find-PowerBIScriptVisuals.ps1 -TenantId '00000000-0000-0000-0000-000000000000'
.EXAMPLE
  ./Find-PowerBIScriptVisuals.ps1 -WorkspaceId '00000000-0000-0000-0000-000000000000' -OutputDirectory ./results
#>
[CmdletBinding()]
param(
    [string] $TenantId,
    [string] $WorkspaceId,
    [string] $OutputDirectory = (Join-Path (Get-Location) 'PowerBI-ScriptVisual-Scan'),
    [int] $MaxOperationPolls = 90
)

$ErrorActionPreference = 'Stop'
$baseUrl = 'https://api.fabric.microsoft.com/v1'
$script:accessToken = $null
$script:tokenExpiry = [datetime]::MinValue

if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    throw 'Az.Accounts is required. Install it with: Install-Module Az.Accounts -Scope CurrentUser'
}
Import-Module Az.Accounts
if ($TenantId) { Connect-AzAccount -Tenant $TenantId | Out-Null }
else { Connect-AzAccount | Out-Null }

function Get-FabricToken {
    if (-not $script:accessToken -or (Get-Date).ToUniversalTime().AddMinutes(5) -ge $script:tokenExpiry) {
        $token = Get-AzAccessToken -ResourceUrl 'https://api.fabric.microsoft.com'
        if ($token.Token -is [securestring]) {
            $script:accessToken = [System.Net.NetworkCredential]::new('', $token.Token).Password
        } else {
            $script:accessToken = [string] $token.Token
        }
        $script:tokenExpiry = $token.ExpiresOn.UtcDateTime
    }
    return $script:accessToken
}

function Get-HeaderValue {
    param($Headers, [string]$Name)
    foreach ($key in $Headers.Keys) {
        if ($key -ieq $Name) { return [string]($Headers[$key] | Select-Object -First 1) }
    }
    return $null
}

function Invoke-FabricRequest {
    param(
        [ValidateSet('GET','POST')][string]$Method,
        [string]$Uri
    )
    for ($attempt = 1; $attempt -le 7; $attempt++) {
        $headers = @{ Authorization = "Bearer $(Get-FabricToken)"; Accept = 'application/json' }
        try {
            $response = Invoke-WebRequest -Method $Method -Uri $Uri -Headers $headers `
                -SkipHttpErrorCheck -ErrorAction Stop
        }
        catch {
            if ($attempt -eq 7) { throw }
            Start-Sleep -Seconds ([math]::Min(60, [math]::Pow(2,$attempt)))
            continue
        }
        $status = [int]$response.StatusCode
        if ($status -eq 429 -or $status -in 500,502,503,504) {
            if ($attempt -eq 7) { throw "HTTP $status after retries: $Method $Uri $($response.Content)" }
            $retryAfter = Get-HeaderValue $response.Headers 'Retry-After'
            $seconds = [math]::Min(300, [math]::Pow(2,$attempt))
            $parsed = 0
            if ([int]::TryParse($retryAfter, [ref]$parsed)) { $seconds = [math]::Max(1,$parsed) }
            Write-Warning "HTTP $status; retrying after $seconds seconds: $Uri"
            Start-Sleep -Seconds $seconds
            continue
        }
        if ($status -lt 200 -or $status -ge 300) {
            throw "HTTP $status: $Method $Uri : $($response.Content)"
        }
        $data = $null
        if (-not [string]::IsNullOrWhiteSpace($response.Content)) {
            $data = $response.Content | ConvertFrom-Json -Depth 100
        }
        return [pscustomobject]@{ StatusCode=$status; Headers=$response.Headers; Data=$data }
    }
}

function Get-FabricPages {
    param([string]$Uri)
    $all = [System.Collections.Generic.List[object]]::new()
    while ($Uri) {
        $requestUri = $Uri
        $page = Invoke-FabricRequest -Method GET -Uri $Uri
        foreach ($item in @($page.Data.value)) { if ($null -ne $item) { $all.Add($item) } }
        if ($page.Data.continuationUri) { $Uri = [string]$page.Data.continuationUri }
        elseif ($page.Data.continuationToken) {
            $cleanUri = ($requestUri -replace '([?&])continuationToken=[^&]*', '$1').TrimEnd('?','&')
            $separator = if ($cleanUri.Contains('?')) { '&' } else { '?' }
            $Uri = "$cleanUri${separator}continuationToken=$([uri]::EscapeDataString([string]$page.Data.continuationToken))"
        }
        else { $Uri = $null }
    }
    return $all.ToArray()
}

function Get-ReportDefinition {
    param([string]$Workspace, [string]$Report)
    $uri = "$baseUrl/workspaces/$Workspace/reports/$Report/getDefinition"
    $initial = Invoke-FabricRequest -Method POST -Uri $uri
    if ($initial.StatusCode -eq 200) { return $initial.Data }
    if ($initial.StatusCode -ne 202) { throw "Unexpected response $($initial.StatusCode)" }

    $operationId = Get-HeaderValue $initial.Headers 'x-ms-operation-id'
    if (-not $operationId) { throw '202 response did not include x-ms-operation-id' }
    for ($poll = 1; $poll -le $MaxOperationPolls; $poll++) {
        $retryAfter = Get-HeaderValue $initial.Headers 'Retry-After'
        $delay = 2
        $parsed = 0
        if ([int]::TryParse($retryAfter, [ref]$parsed)) { $delay = [math]::Max(1,$parsed) }
        Start-Sleep -Seconds $delay
        $state = Invoke-FabricRequest -Method GET -Uri "$baseUrl/operations/$operationId"
        switch ($state.Data.status) {
            'Succeeded' {
                $result = Invoke-FabricRequest -Method GET -Uri "$baseUrl/operations/$operationId/result"
                return $result.Data
            }
            'Failed' { throw "Definition retrieval failed: $($state.Data.error | ConvertTo-Json -Compress -Depth 8)" }
        }
        $initial = $state
    }
    throw "Definition retrieval timed out for report $Report (operation $operationId)"
}

function Find-VisualNodes {
    param($Node, [string]$Path, [string]$FilePath)
    if ($null -eq $Node) { return }
    if ($Node -is [string]) {
        # PBIR-Legacy can embed visual configuration as JSON-encoded strings.
        $value = $Node.Trim()
        if (($value.StartsWith('{') -and $value.EndsWith('}')) -or
            ($value.StartsWith('[') -and $value.EndsWith(']'))) {
            try {
                $parsed = $value | ConvertFrom-Json -Depth 100 -ErrorAction Stop
                Find-VisualNodes -Node $parsed -Path "$Path (embedded JSON)" -FilePath $FilePath
            } catch { }
        }
        return
    }
    if ($Node -is [System.Collections.IDictionary] -or $Node -is [pscustomobject]) {
        $properties = if ($Node -is [System.Collections.IDictionary]) {
            @($Node.Keys | ForEach-Object { [pscustomobject]@{Name=$_;Value=$Node[$_]} })
        } else { @($Node.PSObject.Properties) }
        $typeProperty = $properties | Where-Object Name -eq 'visualType' | Select-Object -First 1
        if ($typeProperty -and $typeProperty.Value -in @('pythonVisual','scriptVisual')) {
            [pscustomobject]@{
                Type = if ($typeProperty.Value -eq 'pythonVisual') {'Python'} else {'R'}
                VisualType = [string]$typeProperty.Value
                JsonPath = $Path
                FilePath = $FilePath
            }
        }
        foreach ($property in $properties) {
            Find-VisualNodes -Node $property.Value -Path "$Path.$($property.Name)" -FilePath $FilePath
        }
        return
    }
    if ($Node -is [System.Collections.IEnumerable]) {
        $i = 0
        foreach ($child in $Node) {
            Find-VisualNodes -Node $child -Path "$Path[$i]" -FilePath $FilePath
            $i++
        }
    }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$findings = [System.Collections.Generic.List[object]]::new()
$errors = [System.Collections.Generic.List[object]]::new()
$scanned = 0
$workspaceCount = 0

if ($WorkspaceId) {
    $workspaces = @([pscustomobject]@{ id=$WorkspaceId; displayName=$WorkspaceId })
} else {
    $workspaces = @(Get-FabricPages -Uri "$baseUrl/workspaces")
}

foreach ($workspace in $workspaces) {
    $workspaceCount++
    Write-Host "Workspace: $($workspace.displayName) ($($workspace.id))"
    try {
        $reports = @(Get-FabricPages -Uri "$baseUrl/workspaces/$($workspace.id)/items?type=Report")
    } catch {
        $errors.Add([pscustomobject]@{Workspace=$workspace.displayName;WorkspaceId=$workspace.id;Report='';ReportId='';Error=$_.Exception.Message})
        continue
    }
    foreach ($report in $reports) {
        $scanned++
        Write-Host "  [$scanned] $($report.displayName)"
        try {
            $definition = Get-ReportDefinition -Workspace $workspace.id -Report $report.id
            if (-not $definition.definition.parts) { throw 'Report definition has no parts' }
            foreach ($part in $definition.definition.parts) {
                if ($part.path -notmatch '\.json$') { continue }
                if ($part.payloadType -and $part.payloadType -ne 'InlineBase64') { continue }
                $jsonText = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String([string]$part.payload))
                $obj = $jsonText | ConvertFrom-Json -Depth 100
                $matches = @(Find-VisualNodes -Node $obj -Path '$' -FilePath $part.path)
                foreach ($match in $matches) {
                    $pageId = ''
                    $visualId = ''
                    if ($part.path -match 'pages/([^/]+)/visuals/([^/]+)/visual\.json$') {
                        $pageId = $Matches[1]
                        $visualId = $Matches[2]
                    }
                    $findings.Add([pscustomobject]@{
                        Workspace=$workspace.displayName
                        WorkspaceId=$workspace.id
                        Report=$report.displayName
                        ReportId=$report.id
                        Language=$match.Type
                        VisualType=$match.VisualType
                        PageId=$pageId
                        VisualId=$visualId
                        DefinitionFile=$part.path
                        JsonPath=$match.JsonPath
                        ReportUrl="https://app.powerbi.com/groups/$($workspace.id)/reports/$($report.id)"
                    })
                }
            }
        } catch {
            $errors.Add([pscustomobject]@{Workspace=$workspace.displayName;WorkspaceId=$workspace.id;Report=$report.displayName;ReportId=$report.id;Error=$_.Exception.Message})
            Write-Warning "Could not inspect '$($report.displayName)': $($_.Exception.Message)"
        }
    }
}

$findingsPath = Join-Path $OutputDirectory 'Python-R-Visuals.csv'
$errorPath = Join-Path $OutputDirectory 'Scan-Errors.csv'
$columns = 'Workspace','WorkspaceId','Report','ReportId','Language','VisualType','PageId','VisualId','DefinitionFile','JsonPath','ReportUrl'
if ($findings.Count) { $findings | Export-Csv -Path $findingsPath -NoTypeInformation -Encoding utf8 }
else { ($columns -join ',') | Set-Content -Path $findingsPath -Encoding utf8 }
if ($errors.Count) { $errors | Export-Csv -Path $errorPath -NoTypeInformation -Encoding utf8 }
else { 'Workspace,WorkspaceId,Report,ReportId,Error' | Set-Content -Path $errorPath -Encoding utf8 }

Write-Host "`nComplete. Workspaces visited: $workspaceCount; Reports attempted: $scanned; Script visuals found: $($findings.Count); Errors: $($errors.Count)"
Write-Host "Findings: $findingsPath"
Write-Host "Errors:   $errorPath"
