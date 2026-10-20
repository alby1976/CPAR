# A Dummies Guide to Using the CPAR VBA Buttons

## Start here: what is VBA?

VBA is the small program behind the workbook’s buttons. A button records a workflow action; it does not change the patient’s EMR or CPAR record.

### Your first practice task

1. Use a separate workbook containing fictional records only.
2. Click one cell in a worklist data row.
3. Click **Mark Done**.
4. Check Processed_Log for the same RecordID and copied MasterKey.
5. Click **Undo Last**, then check the log again.
6. Test **Mark Ignore** and **Refresh All** after you understand the first action.

Only RecordID matches a completed event. A patient can have other open events. An empty processed log is supported; keep its table and headers.

**Before routine use:** compile the code in Excel and test the buttons. The embedded workbook keeps the standard module name Module1 for compatibility; the separate .bas file declares CPAR_Worklist_Actions. Import one version only.

## Technical reference


**Source file:** `CPAR_Worklist_Actions.bas`  
**Commented, importable version:** `CPAR_Worklist_Actions_documented.bas`  
**Purpose:** Record Excel worklist decisions in `tblProcessedLog` without refreshing Power Query for each action.

## 1. At a glance

The workflow is `tblFinalWorklist` → **MarkDone / MarkIgnore** → `tblProcessedLog` → **RefreshAllNow** → Power Query processing → rebuilt final worklist. The VBA changes the log immediately; the Power Query output is recalculated only when refreshed.

| Entry point | What it does | Notes |
|---|---|---|
| `MarkDone` | Calls `MarkSelectedRows "DONE"` | Processes chosen rows |
| `MarkIgnore` | Calls `MarkSelectedRows "IGNORE"` | Processes chosen rows |
| `UndoLastAction` | Reverses most recent successful button batch | Excel-session only |
| `RefreshAllNow` | Calls `ThisWorkbook.RefreshAll` | Does not wait/check for completion |
| `MarkSelectedRows` | Shared validation, lookup, logging, visible feedback | Private procedure |
| `LogFields` | Lists destination fields | Single canonical field list |
| `FindTableByName` | Finds tables across worksheets | Case-insensitive |
| `TableHasColumn` | Verifies an Excel table header | Case-insensitive |
| `FindRecordRow` | Finds the first matching `RecordID` | Case-insensitive and trims whitespace |

## 2. Required tables and fields

**`tblFinalWorklist`** must contain: `RecordID`, `MasterKey`, `PanelID`, `Doctor`, `PatientID`, `Source`, `EventDate`, `ProcessedStatus`.

**`tblProcessedLog`** must contain: `RecordID`, `MasterKey`, `PanelID`, `Doctor`, `PatientID`, `Source`, `EventDate`, `DateProcessed`, `Status`.

`RecordID` controls matching and update operations. `MasterKey` identifies the patient/panel and is copied for auditability. Several distinct `RecordID` values may share one `MasterKey`. Marking one record DONE does not by itself mark the other records DONE.

| Destination field | Value source | Notes |
|---|---|---|
| RecordID | Worklist | Identifier used for log matching |
| MasterKey | Worklist | Patient/panel key; **not** a processing key |
| PanelID | Worklist | Panel metadata |
| Doctor | Worklist | Physician metadata |
| PatientID | Worklist | Patient identifier |
| Source | Worklist | Report origin |
| EventDate | Worklist | Original event date; not when button was clicked |
| DateProcessed | VBA `Now` | Date **and time**; one timestamp per batch |
| Status | Button argument | DONE or IGNORE |

## 3. Detailed procedure walkthrough

### MarkDone / MarkIgnore

These are button-friendly public macros. Both call `MarkSelectedRows` with a different status. Their only difference is the status text.

### MarkSelectedRows

1. Saves the existing values of `Application.EnableEvents` and `Application.ScreenUpdating`, then turns both off during updates.
2. Looks up `tblFinalWorklist` and `tblProcessedLog`. Missing tables cause an error message.
3. Checks that all log headers exist and all source headers needed for copying exist, plus `ProcessedStatus`.
4. Verifies that the worklist contains data and the selected cells overlap its data body.
5. Builds a dictionary of selected physical row numbers, avoiding repeat updates when multiple cells in the same row are highlighted.
6. For each selected row with nonblank `RecordID`, finds the **first** matching log row using `FindRecordRow`.
7. If the log row exists, saves its prior nine values. Otherwise appends a new log row and records that it was newly created.
8. Copies the seven source fields, assigns `Status`, writes the batch-wide `DateProcessed`, and changes the displayed `ProcessedStatus`.
9. Saves the successful batch's undo snapshots in `mUndo` and reports the count.
10. Restores Excel application settings even after an error.

**Important:** The displayed `ProcessedStatus` is temporary on the Power Query-loaded worklist. The log entry is the persistent record. The macro deliberately does not refresh after each click.

### UndoLastAction

Works backward through the last saved batch. For rows which existed before the button click, it restores the nine saved log values. For newly created log rows it deletes the row. It then restores the old visible worklist status **if** that `RecordID` is still present. It clears `mUndo` after a successful pass. Closing Excel or resetting VBA clears the undo snapshot. It does not preserve a multi-level history.

### RefreshAllNow

Calls `ThisWorkbook.RefreshAll`. Some query connections can refresh in the background; the routine does not report refresh success, trigger error handling on stale query results, or validate final row counts.

### FindTableByName / TableHasColumn / FindRecordRow

The first locates a named table across worksheets, the second checks column names, and the third performs a row-by-row `RecordID` comparison. A duplicate `RecordID` in `tblProcessedLog` is **not** detected as an error: the first matching row is used.

## 4. Button installation — beginner guide

1. Save a backup of the `.xlsm` workbook.
2. Press **Alt+F11** to open the Visual Basic Editor.
3. Right-click your old action module → **Export File** to preserve a backup.
4. Remove the old module, then choose **File → Import File** and select `CPAR_Worklist_Actions_documented.bas`. Do not import it alongside an existing module with the same public procedure names.
5. Verify both Excel table names under **Table Design → Table Name** and ensure all listed columns exist.
6. Return to Excel and assign the four public procedures to Form Control buttons as needed.
7. Select one test worklist row and click DONE. Inspect `tblProcessedLog`: confirm all nine columns and a real date/time in `DateProcessed`.
8. Click Undo before refreshing. Verify that the original row is restored or the newly created row was removed.
9. Repeat for IGNORE. Then perform a Power Query refresh and verify that only the corresponding event is filtered from the worklist.

## 5. Test cases

| Test | Expected behavior |
|---|---|
| New RecordID → DONE | New log row with all nine fields |
| Existing RecordID → IGNORE | First matching log row updated; no new row |
| Same MasterKey, different RecordIDs | Decisions remain event-specific |
| Multiple selected cells in one row | Row processed once |
| Multiple selected rows | All nonblank RecordIDs processed; same DateProcessed timestamp |
| Selected row has blank RecordID | Skipped |
| Missing required column | Explicit error message |
| Undo new entry | New log row deleted |
| Undo modified entry | Prior nine log values restored |
| Refresh after DONE | Power Query must join/filter by RecordID for correct results |

## 6. Limitations and precautions

- **No transaction rollback:** if an error occurs halfway through a batch, earlier rows may have been written. The handler warns you to inspect the log. Undo storage is assigned only after a successful batch; do not assume Undo will fix partial failures.
- **Undo is session-only:** closes/resets lose the snapshot; a second action replaces the first action's undo state.
- **Duplicate RecordIDs:** `FindRecordRow` finds only the first; enforce uniqueness in `tblProcessedLog` if multiple rows could be created by other methods.
- **Performance:** `FindRecordRow` scans rows linearly; large logs and multi-row selections can be slow.
- **Filtered selections:** the code intersects the selection with the table range; it does not explicitly limit updates to visible rows.
- **Source data validation:** blank `RecordID` is skipped, but other fields are not individually checked for blank values or errors.
- **Patient information:** `PatientID`, Doctor, etc. may be confidential. Store files and logs only in approved, access-controlled locations and avoid copying real patient rows into troubleshooting messages.
- **Power Query:** this VBA does not edit M queries. `Processed_Log`, `Processed_Records`, and `Final_Worklist` must preserve the same `RecordID` semantics and relevant fields.

## 7. Example (fictional identifiers)

Two worklist events share `PanelA|12345-6789 AB` as `MasterKey` but have `CPAR|...` and `DEMO|...` as separate RecordIDs. Marking CPAR DONE updates only its own log record. The DEMO event stays open unless a separate manual or automatic processing rule applies.
