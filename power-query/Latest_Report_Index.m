let
    Source =
        File_Import_Log,

    Valid =
        Table.SelectRows(
            Source,
            each
                [PanelID] <> null
                and [ImportStatus] = "OK"
                and [DoctorValidation] = "OK"
                and
                (
                    [SchemaStatus] = "OK"
                    or [SchemaStatus] = "NOT_APPLICABLE"
                )
                and [DuplicateStatus] <> "DUPLICATE_SUPPRESSED"
        ),

    Sort =
        Table.Sort(
            Valid,
            {
                {"PanelID", Order.Ascending},
                {"SourceType", Order.Ascending},
                {"ReportDateTime", Order.Descending},
                {"FileModified", Order.Descending}
            }
        ),

    Group =
        Table.Group(
            Sort,
            {
                "PanelID",
                "SourceType"
            },
            {
                {
                    "Rows",
                    each
                        Table.AddIndexColumn(
                            _,
                            "LatestRank",
                            1,
                            1,
                            Int64.Type
                        )
                }
            }
        ),

    Expand =
        Table.ExpandTableColumn(
            Group,
            "Rows",
            List.RemoveItems(
                Table.ColumnNames(Sort),
                {
                    "PanelID",
                    "SourceType"
                }
            )
            &
            {"LatestRank"}
        ),

    AddLatest =
        Table.AddColumn(
            Expand,
            "LatestStatus",
            each
                if [LatestRank] = 1
                then "LATEST"
                else "HISTORICAL",
            type text
        )
in
    AddLatest
