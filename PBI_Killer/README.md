# Static Web Admin — Azure Static Web Apps

A self-contained `public/admin.html` interface for managing deployed website assets: folders, file uploads/downloads/deletions, text previews, and per-folder/per-file access policies. The HTML contains all CSS, JavaScript and icons, with no CDN dependencies. Offline mode stages files and exports a website ZIP or restorable workspace backup. Live mode calls the included managed Azure Functions API.

## Architecture

Browser → same-origin `/api/admin/*` → GitHub Git API → one atomic branch commit → GitHub Actions → Azure Static Web Apps deployment.

Azure Static Web Apps has no writable hosted-files filesystem. Consequently, publication is a repository/deployment operation, not an immediate filesystem upload. This manages a **single configured app repository, branch and static root**, not all Azure resources. It does not change the Azure hosting plan, DNS, app settings, subscription roles or user role assignments. No credentials are stored in the HTML.

## Files

- `public/admin.html`: entire administration frontend; open directly to use offline mode.
- `public/staticwebapp.config.json`: admin route protection, runtime and sign-in behavior.
- `public/index.html`: replaceable starter homepage.
- `api/admin/index.js`: HTTP API implemented with Node.js 22 managed Functions; no npm dependencies.
- `api/admin/function.json`, `api/host.json`, `api/package.json`: Functions deployment metadata.
- `.github/workflows/azure-static-web-apps.yml`: GitHub Actions deployment template.
- `tests/`: backend integration tests with mocked GitHub and frontend logic/ZIP checks.

## Set up a new app

1. Extract this package and push its contents to a private GitHub repository. The repository root should contain `public/`, `api/`, and `.github/`.
2. In Azure Portal, create an **Azure Static Web App**, select **Free**, and connect it to that repository's `main` branch. Select Custom build configuration, app location `public`, API location `api`, and leave output location blank.
3. Azure can generate a workflow automatically. Keep exactly one deployment workflow: use the included template or adjust the generated workflow to those locations. The included template expects the GitHub repository secret `AZURE_STATIC_WEB_APPS_API_TOKEN`, containing this app's deployment token. If Azure generated a differently named secret, change the workflow reference to that name. Never place the deployment token in committed source files.
4. Create a fine-grained GitHub personal access token, scoped to **only this repository**, with **Contents: Read and write**. This token remains server-side. Use a dedicated account/token and set an expiration. Do not use the workflow's automatically issued `GITHUB_TOKEN`: its commits typically do not trigger another workflow run. Branch protections requiring PR approval can prevent direct publish; this version intentionally does not bypass them.
5. In the Static Web App's Azure application settings, configure the values below and save. These settings are available to the managed API.
6. In Azure Portal → Static Web App → Role management, invite your account through Microsoft Entra ID or GitHub with the custom role **`swa_admin`**. Accept the invitation while signed into the intended account. The invitation identity provider must match the one you subsequently use to sign in.
7. Wait for the initial GitHub Actions deployment to succeed. Visit `https://YOUR-APP.azurestaticapps.net/admin.html`, sign in, open **Connection & exports**, and click **Connect & load**.
8. Stage a small test file/folder and publish. Follow the workflow link and verify the deployed URL and access rules after the workflow succeeds.

### Required Azure application settings

| Setting | Example / meaning |
| --- | --- |
| `GITHUB_OWNER` | GitHub user or organization name |
| `GITHUB_REPO` | Repository name only |
| `GITHUB_TOKEN` | Fine-grained repository token; Contents read/write |
| `GITHUB_BRANCH` | `main`; must match the workflow's watched production branch |
| `STATIC_ROOT` | `public`; must match the workflow's deployed app directory |
| `ADMIN_ALLOWED_ORIGINS` | Exact full origins, comma-separated, e.g. `https://YOUR-APP.azurestaticapps.net,https://www.example.com`; no trailing slash or paths |

The API intentionally supports a nonempty static-root directory. For existing sites built with a framework, use a separate directory that the build copies to its output or adapt the deployment layout. Do not point this tool at React source files and assume those files are direct deployable assets.

## Use an existing instance

Add `admin.html` to the deployed static directory, merge the configuration rather than overwriting it, and add the API function to your existing managed API. Keep both administrative routes first, before broader access, redirect or rewrite rules:

```json
[
  { "route": "/api/admin/*", "allowedRoles": ["swa_admin"] },
  { "route": "/admin.html", "allowedRoles": ["swa_admin"] }
]
```

Use `platform.apiRuntime: "node:22"` when appropriate for the rest of your managed API. Configure the repository settings and invitation above. The backend preserves other configuration fields and existing route rules, and restores these admin protections on every publish. Update the protected admin HTML directly through GitHub when upgrading this application.

## File operations

- Upload several files, or import a directory preserving its relative paths.
- Navigate folders using the breadcrumb trail. Search filters the current folder.
- Create folders; empty folders have a blank `.swa-folder` marker. This contains no secrets and may be served as an empty asset. It is hidden from the file table.
- Download files or view their text without executing uploaded HTML/JavaScript.
- Delete a file or an entire folder recursively. Deletions are staged with the other changes.
- Existing names can be replaced only after an explicit browser confirmation.
- **Review & publish** commits all staged changes. Completion means a Git commit succeeded; deployment success must be checked separately in GitHub Actions.
- A branch-head mismatch or non-fast-forward update fails rather than overwriting another administrator's changes. Export a backup before reloading if you want to retain your staged edits.
- On a timeout/network failure, the commit may have succeeded even if the browser did not receive a response. Check GitHub or reload before retrying.

## Permissions and their limits

Choose **Public**, **Signed in**, **Specific roles**, or **Inherit**. These become `allowedRoles` route rules; they are not filesystem ACLs or Azure RBAC assignments. Multiple roles use OR semantics. Folder routes use `/folder/*`; file routes use `/folder/file.ext`. Inherit removes the exact explicit rule, letting another matching route apply, or default public access when none applies.

Rules are evaluated in array order. Newly staged policies are placed before existing non-admin routes, and later staged policies appear before earlier staged policies. For a private folder with a public file exception, stage the folder policy first and the file policy second; inspect **Access rules** before publishing. The tool preserves existing redirects, rewrites, methods and headers; its table displays simple first-match role policies, not a full simulation of complex routing configurations.

Built-in Entra authentication on Free accepts accounts beyond your own tenant. “Signed in” therefore does not mean “employee.” Use invited custom roles for a small restricted audience. Free's built-in invitation system supports custom roles for up to 25 users. Role invitations and removals are performed in Azure Portal. Tenant-specific custom provider configuration requires Standard.

Routing rules do not protect data embedded in downloaded JavaScript, client-side navigation, or requests served through `navigationFallback`. Use API authorization for sensitive application data. For protected files, avoid fallback behavior that bypasses route protection, test actual file URLs, and inspect the existing configuration. Downloaded copies cannot be revoked retroactively.

The frontend/API require `swa_admin`; the backend independently checks the trusted Static Web Apps client principal on every request. Publish also requires an explicitly allowlisted browser origin and custom request header. Do not expose this Function behind an unrelated public gateway that allows clients to forge `x-ms-client-principal`. All users with `swa_admin` can upload executable website assets, so they must be trusted site administrators. This is not an untrusted public file-submission portal.

The sample workflow deploys production pushes only; it intentionally does not deploy pull requests. Do not give untrusted preview code access to server application settings or a writable production repository token. Credentials may be available across SWA environments, so review any existing preview workflows before attaching the backend.

## Limits

- Tool limit: 8 MiB per upload/download, 12 MiB raw upload bytes and 100 combined operations per publish.
- Browser complete-site ZIP export: up to 40 MiB of source asset data. Larger sites should be exported from the repository checkout. Backups of remote files also require API downloads.
- ASCII paths only: letters, digits, spaces, hyphens, underscores and periods. No hidden segments, traversal, route wildcards or reserved `api`, `admin.html`, and `staticwebapp.config.json` root paths. Existing files outside this naming convention can be listed/downloaded but not edited through this tool.
- Backend guards 15,000 files and 250 MiB raw assets; Azure enforces its own actual quotas. Storage across preview environments and shared monthly bandwidth are not tracked by this tool.
- GitHub API quotas and the SWA 45-second request ceiling still apply. Large batches may time out; use smaller batches if needed.
- No rename/move operation, live deployment polling, Azure resource provisioning, or built-in user invitation UI in this version.
- The HTML stages in memory. Closing/reloading loses unexported staging. Save workspace backups when needed. Backups contain actual file data.
- For offline ZIPs, unzip the contents into the static deployment folder and deploy normally. Exported ZIPs contain frontend assets/config, not the backend; install `api/` from this package for live management.

## Verification

From the package root, with Node.js 22 or newer:

```sh
node --test tests/backend.test.js tests/frontend.test.js
```

Tests cover unauthorized calls, publish origin checks, protected paths, binary content, optimistic concurrency, recursive folder deletion, configuration preservation and ZIP CRCs. GitHub calls are mocked. A real Azure deployment and browser layout verification have not been performed in the creation environment; complete the small live smoke test in step 8 before relying on the app.

## Official references

- https://learn.microsoft.com/en-us/azure/static-web-apps/overview
- https://learn.microsoft.com/en-us/azure/static-web-apps/apis-functions
- https://learn.microsoft.com/en-us/azure/static-web-apps/apis-overview
- https://learn.microsoft.com/en-us/azure/static-web-apps/user-information
- https://learn.microsoft.com/en-us/azure/static-web-apps/authentication-authorization
- https://learn.microsoft.com/en-us/azure/static-web-apps/configuration
- https://docs.github.com/en/rest/git/trees
- https://docs.github.com/en/rest/git/refs
