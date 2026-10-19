let
    LatestFiles =
        Table.SelectRows(
            Latest_Report_Index,
            each [LatestStatus] = "LATEST"
        ),

    LatestCPAR =
        Table.SelectRows(
            LatestFiles,
            each [SourceType] = "CPAR"
        ),

    LatestConflict =
        Table.SelectRows(
            LatestFiles,
            each [SourceType] = "CONFLICT"
        ),

    LatestDemo =
        Table.SelectRows(
            LatestFiles,
            each [SourceType] = "DEMOGRAPHIC_MISMATCH"
        ),

    CPAR =
        Table.NestedJoin(
            Standardize_CPAR,
            {
                "PanelID",
                "SourceFileName"
            },
            LatestCPAR,
            {
                "PanelID",
                "FileName"
            },
            "Latest",
            JoinKind.Inner
        ),

    Conflict =
        Table.NestedJoin(
            Conflict_Actionable,
            {
                "PanelID",
                "SourceFileName"
            },
            LatestConflict,
            {
                "PanelID",
                "FileName"
            },
            "Latest",
            JoinKind.Inner
        ),

    DemoSource =
        Table.SelectRows(
            Standardize_Demographic_Mismatch,
            each [DoctorValidation] = "OK"
        ),

    Demo =
        Table.NestedJoin(
            DemoSource,
            {
                "PanelID",
                "SourceFileName"
            },
            LatestDemo,
            {
                "PanelID",
                "FileName"
            },
            "Latest",
            JoinKind.Inner
        ),

    Combined =
        Table.Combine(
            {
                Table.RemoveColumns(
                    CPAR,
                    {"Latest"}
                ),
                Table.RemoveColumns(
                    Conflict,
                    {"Latest"}
                ),
                Table.RemoveColumns(
                    Demo,
                    {"Latest"}
                )
            }
        )
in
    Combined
