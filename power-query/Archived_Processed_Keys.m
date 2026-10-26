// Connection only. Manual persistent table; NEVER load output over the input.
let
    Source = Excel.CurrentWorkbook(){[Name="tblArchivedProcessedKeys"]}[Content],
    Selected = Table.SelectColumns(Source, {"RecordID", "Status", "DateProcessed"}),
    Clean = Table.TransformColumns(Selected, {
        {"RecordID", each if _ = null then "" else Text.Trim(Text.From(_)), type text},
        {"Status", each if _ = null then "" else Text.Upper(Text.Trim(Text.From(_))), type text},
        {"DateProcessed", each try DateTime.From(_) otherwise null, type nullable datetime}}),
    Valid = Table.SelectRows(Clean, each [RecordID] <> "" and List.Contains({"DONE", "IGNORE", "IGNORED"}, [Status]))
in
    Valid
