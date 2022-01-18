# RELEASES

## Delta
Planned Release:  June 2022<br/>
Possible Features: 
- Added editor for creating new custom measure definitions
- Added editing of existing measure definitions
- Added ability to edit labels
- Added suggested code and comments for new measure definitions
- Added a "Raw" button to view raw code before replacements happen
- Added automatic reload for Calculations pane
- Added support for measures as well as columns when choosing a column
- DAX editor now supports returns and tabs
- Added Data Category JSON field and GUI setting
- Added Group field to categorize measure definitions
- Added a table selector interface in DAX Source pane
- Added ability to control tooltips and tooltips GUI
- Added a "MaxMin" type for aggregation comboboxes that defaults to Maximum in stead of Minimum
- Exposed Type field to visually verify if measure or column is created
- Added Create and Set buttions with File dialogs to create or set Custom Measure File
- Added the ability to remove custom measure definitions
- Added ability to hide/show Notes panel
- Expanded DAX code editing text box
- Added ability to set Display Folder
- Various minor fixes
- Added Ascending/Descending control
- Added Skip/Dense control
- Added Yes/No control
- Added "on-the-fly" measure creation
- Preview tooltips
- Speed improvements
- 3 New measure definitions
- AND Slicer (Patient cohort) quick measure
- AND Slicer (Count) quick measure
- MC Aggregations quick measure


## Future
- Add automatic or manual "reload" button for the Model
- Add ability to change order of controls
- Add Details pane for specifying AggregationType, etc.
- Make Calculations pane expand and collapse groups/filter
- Make Model columns pane expand and collapse groups/filter
- Add ability to add custom unit conversion types
- Fix expansion of Notes pane
- Add Data type for columns?
- Include DAX Template JSON support from powerbi.tips? 
- Add color formatting to DAX source code? 
- Add intellisense? 
- Add Days, Months, Quarters, Years control 

## Past Releases
### Gamma
Planned Release:  February 2022<br/>
Planned Features: 
- Remove initial column selection pane
- Consolidate to a single, dynamic measure configuration pane
- Preserve table name and column name when choosing a column in the column selection pane
- Refactor DAX formulas accordingly
- Additional formulas

Actual Release:   December 6th, 2021<br/>
Features and Fixes<br/>
- Removed initial column selection pane
- Consolidated to a single, dynamic measure configuration pane
- Preserved table name and column name when choosing a column in the column selection pane
- Refactored DAX formulas accordingly
- Added YouTube channel link
- Added GitHub link replacing Panic button
- Updated icon
- Expanded DAX source code text box
- Added ability to edit creation table
- Added ability to edit custom format string
- Added measure creation confirmation dialog
- Added Notes and Links pane
- Added custom measures JSON file support
- Added the ability to create you very own custom quick measures!
- 18 additional formulas (Now over 100 quick measures!!)
- BINOM.DIST (Simple)
- BINOM.DIST.CUMULATIVE (Simple)
- BINOM.INV (Simple)
- NEGBINOM.DIST (Simple)
- NEGBINOM.DIST.CUMULATIVE (Simple)
- Days in Month
- DAX 445 Calendar
- Count of Items in List
- The Replacements
- CAPS!
- Text Duration Converter
- Keywords
- Text Accumulator
- Decminal Days to Duration
- Open Tickets
- SVG Blinking Dot
- Dynamic Slicer Title
- Measure Totals, The Final Word
- Custom Measure Demo
#### supportedmeasures.json
- Updated 12/20/2021 to include all out-of-the-box quick measures in Power BI Desktop
- Updated 12/27/2021 to include 37 new measures (The "SVG" Update):
  - Percent of Total
  - Compound Annual Growth Rate
  - Rank per category
  - Table/Matrix Totals
  - Simple Aggregations
  - Simple Iterator Aggregations
  - Aggregation on Last Date
  - Stephen Few 'Red Dot'
  - Normalize Numeric Data
  - Linear Interpolation
  - The Most Amazing, Mind Blowing Dynamic Slicer Title Measure Ever
  - Simple SVG KPI
  - SVG Trend Indicator
  - SVG Sparklines
  - SVG Sparklines Categorical Columns
  - SVG Color and Shape Indicators
  - SVG Color and Shape Indicators 2
  - SVG Color Star Rating
  - SVG Heart
  - SVG Flatline
  - SVG Beating Heart
  - SVG Bouncing Dot
  - SVG Spinner
  - SVG Square Animation
  - SVG Swipe
  - SVG Twirl
  - SVG Gauge
  - SVG Harveyball
  - SVG Harveybox
  - First Working Day of Week
  - Is First Working Day of Week
  - Last Working Day of Week
  - Is Last Working Day of Week
  - First Working Day of Month
  - Is First Working Day of Month
  - Last Working Day of Month
  - Is Last Working Day of Month
- Updated 1/4/2022 to include 35 new measures (Total 200 measures!) (The "Excel" Update):
  - First Working Day of Year
  - Is First Working Day of Year
  - Last Working Day of Year
  - Is Last Working Day of Year
  - COMPLEX
  - IMAGINARY
  - IMREAL
  - IMCONJUGATE
  - IMSUM
  - IMLN
  - IMLOG10
  - IMLOG2
  - IMEXP
  - IMPOWER
  - IMCOS
  - IMSIN
  - IMSQRT
  - DAYS360
  - LARGE
  - SMALL
  - F.DIST
  - F.DIST.CUMULATIVE
  - F.DIST.RT
  - F.INV
  - F.INV.RT
  - BASE
  - DECIMAL
  - DEC2HEX
  - DEC2OCT
  - DEC2BIN
  - BIN2DEC
  - XOR
  - ARABIC
  - ROMAN
  - SERIESSUM

### Beta
Planned Release:  December 2021<br/>
Planned Features: 
- Code clean-up and refactoring
- 30 additional formulas

Actual Release:   October 25th, 2021<br/>
Features and Fixes<br/>
-	Fixed bug in Lookup Min/Max not switch between measures and columns - Note on 11/8/2021 uploaded a minor DAX fix for these
-	Fixed minor DAX code error in Week Ending and Week Starting
-	45 New Formulas
- WEEKDAY
- WEEKNUM
- FIND or SEARCH
- Near (Distance)
- Near (Square)
- Overlap
- No Overlap
- Fuzzy
- Blowout!
- The Mythical DAX Index
- WEIBULL.DIST
- WEIBULL.DIST.CUMULATIVE
- NEGBINOM.DIST
- NEGBINOM.DIST.CUMULATIVE
- BINOM.DIST
- BINOM.DIST.CUMULATIVE
- BINOM.INV
- HARMEAN
- MULTINOMIAL
- FISHER
- FISHERINV
- DEVSQ
- Transitive Closure
- For Loop
- While Loop
- Jarque-Bera
- Compound Interest
- Kendall's Tau
- Is Prime
- Unix2UTC
- UTC2Unix
- Is Leap Year
- Days in Year
- Day of Year
- Date of Year
- Greeting
- Sequential
- Shannon Entropy
- Covariance
- Running Product
- DELTA
- Macauly Duration
- Previous Row
- Gross Margin %
- Revenue
- Cost

### Alpha
Released: October 6th, 2021
- 30+ formulas
