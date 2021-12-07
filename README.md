# MicrosoftHatesGregsQuickMeasures
An external tool for creating quick measures or columns in Power BI Desktop or tabular model. Read more about it here <a href="https://www.linkedin.com/pulse/microsoft-hates-gregs-quick-measures-greg-deckler-microsoft-mvp-/">Microsoft Hates Greg's Quick Measures</a>
<img src="MSHGQM_Gamma.png" />
## Installation
1. Download the <strong>MSHGQM_Gamma.zip</strong> file
2. Extract the files in the .zip to some location, such as <strong>C:\Program Files (x86)\MicrosoftHatesGregsQuickMeasures</strong>
3. Go to where you extracted the files
4. Copy <strong>MicrosoftHatesGregsQuickMeasures.pbitool.json</strong>
5. Paste <strong>MicrosoftHatesGregsQuickMeasures.pbitool.json</strong> to your Power BI Desktop "External Tools" directory (<strong>C:\Program Files (x86)\Common Files\Microsoft Shared\Power BI Desktop\External Tools</strong>)
6. Open <strong>MicrosoftHatesGregsQuickMeasures.pbitool.json</strong> in Notepad and edit the <strong>Path</strong> element to point to the executable file. Please note that you need to use double backslashes \\ for each backslash in the file path, so for example <strong>C:\\\\Program Files\\\\MSHGQM\\\\MicrosoftHatesGregsQuickmeasures.exe</strong>
7. Launch Power BI and go to the "<strong>External Tools</strong>" tab
8. Click "<strong>Microsoft Hates Greg</strong>" icon

## How to Use
1. Choose a quick measure in the <strong>Calculations</strong> pane
2. In the quick measure's configuration pane, configure the measure
3. Click "<strong>Generate DAX</strong>"
4. In the "<strong>Dax Measure</strong>" pane, click "<strong>Create</strong>" to create the measure or column in the chosen Table

## Start Creating Your Own Quick Measures
1. Create a JSON file with the appropriate fields. More information coming otherwise find the <strong>suppotedmeasures.json</strong> file for the format
2. Launch MSHGQM and set the <strong>Custom File</strong> property
3. Click the <strong>Set</strong> button
4. Close and relaunch MSHGQM to load any custom measures

## Updates for Quick Measures
Now that quick measures can be released without recompiling, I will be releasing the supportedmeasures.json file separately. To update the quick measures in your tool simply do the following:
1. Download the latest supportedmeasures.json file
2. Close MSHGQM
3. Locate the supportedmeasures.json file in the <strong>Resources</strong> directory where you installed MSHGQM
4. Replace the file with the new version and then re-open MSHGQM

## Notes
- There are not a lot of guard rails
- There is no data type checking for example so if you try to sum a text column, that's on you. 
- Same thing if you use a column from some table you shouldn't
- Won't cause issues with measure and column creation, you just might get some DAX errors
- No, it is not open source
- Original code based on Kay Unkroth's Metadata Translator
- None of the linked charities are associated with myself, they are all just local causes I believe in and my friends sit on their boards
