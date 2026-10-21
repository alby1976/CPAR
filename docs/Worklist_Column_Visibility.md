# A Dummies Guide to Automatic Worklist Columns

Filter Source and Excel shows the columns needed by the visible reports.
This changes column visibility only; it does not change patient records or the processed log.

## Install once

1. Save a backup of your macro-enabled workbook.
2. Press Alt+F11, choose File > Import File, and import [CPAR_Worklist_Columns.bas](../vba/CPAR_Worklist_Columns.bas). Replace an earlier copy of UpdateWorklistColumns rather than keeping duplicates.
3. Return to the worklist sheet. In an unused cell outside the table (for example AA1, only if unused), enter `=SUBTOTAL(103,tblFinalWorklist[Source])`. Keep this formula outside the Power Query output area.
4. Right-click the worklist sheet tab > View Code. Paste [the worksheet event code](../vba/events/Worklist_Output_worksheet.txt) there. Do not import it as a standard module. If Worksheet_Calculate already exists, merge the call into that event; keep only one Option Explicit.
5. Select Formulas > Calculation Options > Automatic. Save as .xlsm with macros enabled.
6. Filter Source. Columns should update without clicking a button. You can also run UpdateWorklistColumns with Alt+F8.

## What appears?

Patient identifiers, names, Source, EventDate, IssueType, RecordID, MasterKey, PanelID, Doctor and ProcessedStatus remain visible.

| Visible source | Additional columns |
|---|---|
| CPAR | UNABLE_TO_SEND_REASON |
| Demographic mismatch | Registry ID/names, panel/registry gender, DOB or Panel Date of Birth, registry DOB, Date Of Death |
| Conflict | EffectiveMasterEntryDate, ConflictRule, DOB |
| Multiple sources | Combined columns for those sources |
| Empty table, no visible rows, blank/error/unrecognized source | All columns |

Source matching is case-insensitive and recognizes DEMOGRAPH, CONFLICT or CPAR in the value. Unknown sources show everything so information stays accessible. Other filters and manually hidden rows also affect the visible-source result.

## Things to know

- Excel hides whole worksheet columns, including cells above and below the table.
- Existing table columns not listed for a visible source are hidden. Update the mapping when adding new fields.
- The SUBTOTAL helper triggers worksheet calculation on filter changes. Other recalculations also run the event; there is no row-count cache, so equal-sized filter results are checked again.
- The macro scans visible rows and only changes column visibility when needed. Large worklists may still take time.
- Protected sheets must permit column formatting or be unprotected before running.
- This addition is supplied as source and installation instructions. It is not embedded into the downloadable workbook yet.

## Quick check in Excel

Use fictional rows to try CPAR only, demographic only, conflict only, mixed sources, an unknown source, and zero matches. Switch between two filters with the same visible row count. Confirm appropriate columns appear and data values stay unchanged.

VBA compilation and filter-event behavior require validation in desktop Excel; they have not been executed in this environment.
