// ============================================================================
// QUERY: Processed_Log
// TYPE: COMPLETE POWER QUERY (M) - paste into Advanced Editor
// PURPOSE:
//   Reads the user-maintained Excel table tblProcessedLog, validates required
//   columns, normalizes identifiers/statuses, parses dates, and removes rows
//   without a RecordID.
//
// REQUIRED SOURCE TABLE: tblProcessedLog (Excel.CurrentWorkbook)
// REQUIRED COLUMNS: RecordID, Status
// OPTIONAL COLUMNS (created as null when absent): MasterKey, PanelID, Doctor,
//   PatientID, Source, EventDate, DateProcessed, Notes, DateStarted, ActionTaken
//
// OUTPUT: One row per nonblank RecordID INPUT ROW; this query DOES NOT
//   remove duplicate RecordID values or decide which status wins.
//
// IDENTIFIERS:
//   RecordID  = event identifier; downstream processing matches on RecordID.
//   MasterKey = patient/panel identifier; not a DONE/IGNORE match key.
//
// IMPORTANT:
//   The tblProcessedLog table is an input, not a refresh destination.
//   Loading this query over that table risks circular references/data loss.
//   DateProcessed is read from VBA-written values, NOT generated on refresh.
//   Unparseable dates are changed to null by try ... otherwise null.
//   Text values are trimmed; Status is also uppercased.
// ============================================================================

let
    // Read the Excel input table only. Never load this query back onto tblProcessedLog.
    Source = Excel.CurrentWorkbook(){[Name="tblProcessedLog"]}[Content],
    Required = {"RecordID", "Status"},
    Missing = List.Difference(Required, Table.ColumnNames(Source)),
    Validated = if List.IsEmpty(Missing) then Source else error Error.Record("Missing columns", "tblProcessedLog requires RecordID and Status", Missing),
    Fields = {"RecordID", "MasterKey", "PanelID", "Doctor", "PatientID", "Source", "EventDate", "DateProcessed", "Status", "Notes", "DateStarted", "ActionTaken"},
    Selected = Table.SelectColumns(Validated, Fields, MissingField.UseNull),
    CleanText = Table.TransformColumns(Selected,
        List.Transform({"RecordID", "MasterKey", "PanelID", "Doctor", "PatientID", "Source", "Status"},
            (name) => {name, (value) => if value = null then null else Text.Trim(Text.From(value)), type nullable text})),
    CleanStatus = Table.TransformColumns(CleanText, {{"Status", each if _ = null then null else Text.Upper(_), type nullable text}}),
    Dates = Table.TransformColumns(CleanStatus, {
        {"EventDate", each try Date.From(_) otherwise null, type nullable date},
        {"DateProcessed", each try DateTime.From(_) otherwise null, type nullable datetime},
        {"DateStarted", each try DateTime.From(_) otherwise null, type nullable datetime}
    }),
    ValidRows = Table.SelectRows(Dates, each [RecordID] <> null and [RecordID] <> "")
in
    ValidRows
