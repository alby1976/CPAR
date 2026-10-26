// Load to a dedicated worksheet table named tblArchiveLoadedRecordIDs.
// A fresh READY marker and all IDs are delivered in ONE successful refresh.
let
    Normalize = (v as any) as text => if v = null then "" else Text.Trim(Text.From(v)),

    ImportProblems = Table.RowCount(File_Errors),

    FolderProblems = Table.RowCount(Unmapped_Doctor_Files),

    MissingReports = Table.RowCount(Missing_Expected_Reports),

    InventoryCount = Table.RowCount(File_Import_Log),

    // Use every loaded report, not Latest_Report_Index or Final_Worklist.
    CPAR = Table.SelectColumns(Standardize_CPAR, {"RecordID"}),

    Demo = Table.SelectColumns(Standardize_Demographic_Mismatch, {"RecordID"}),

    Conflict = Table.AddColumn(Standardize_Conflicts, "RecordID", each
        [MasterKey] & "|CONFLICT|" &
        (if [EventDate] = null then "NO_DATE" else Date.ToText([EventDate], "yyyy-MM-dd")), type text),

    Combined = Table.Combine(
        {
            CPAR,
            Demo,
            Table.SelectColumns(
                Conflict,
                {"RecordID"}
            )
        }
    ),

    IDs = Table.Buffer(Table.Distinct(Table.SelectRows(
        Table.TransformColumns(Combined, {{"RecordID", Normalize, type text}}), each [RecordID] <> ""))),

    IDCount = Table.RowCount(IDs),
    Problems = List.RemoveNulls({
        if ImportProblems > 0
        then "File_Errors: " & Text.From(ImportProblems)
        else null,

        if FolderProblems > 0
        then "Unmapped_Doctor_Files: " & Text.From(FolderProblems)
        else null,

        if MissingReports > 0
        then "Missing_Expected_Reports: " & Text.From(MissingReports)
        else null,

        if InventoryCount = 0
        then "File_Import_Log: no inventory rows"
        else null,

        if IDCount = 0
        then "No loaded event IDs"
        else null
    }),

    Checked =
        if List.Count(Problems) > 0 then
            error Error.Record(
                "ArchiveValidationFailed",
                "Archiving blocked: " &
                    Text.Combine(Problems, "; "),
                [
                    ImportProblems = ImportProblems,
                    FolderProblems = FolderProblems,
                    MissingReports = MissingReports,
                    InventoryCount = InventoryCount,
                    IDCount = IDCount
                ]
            )
        else
            IDs,

    Stamp = DateTime.LocalNow(),
    Rows = Table.AddColumn(Table.AddColumn(Checked, "Kind", each "ID", type text),
        "RefreshedAt", each Stamp, type datetime),
    Marker = #table(type table [RecordID=text, Kind=text, RefreshedAt=datetime], {{"", "READY", Stamp}}),
    Output = Table.Combine({Marker, Rows})
in
    Output
