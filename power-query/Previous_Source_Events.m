let
    PreviousFiles =
        Previous_Report_Index,

    PreviousCPAR =
        Table.SelectRows(
            PreviousFiles,
            each [SourceType] = "CPAR"
        ),

    PreviousConflict =
        Table.SelectRows(
            PreviousFiles,
            each [SourceType] = "CONFLICT"
        ),

    PreviousDemo =
        Table.SelectRows(
            PreviousFiles,
            each [SourceType] = "DEMOGRAPHIC_MISMATCH"
        ),

    CPAR =
        Table.NestedJoin(
            Standardize_CPAR,
            {
                "PanelID",
                "SourceFileName"
            },
            PreviousCPAR,
            {
                "PanelID",
                "FileName"
            },
            "Previous",
            JoinKind.Inner
        ),

    Conflict =
        Table.NestedJoin(
            Conflict_Actionable,
            {
                "PanelID",
                "SourceFileName"
            },
            PreviousConflict,
            {
                "PanelID",
                "FileName"
            },
            "Previous",
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
            PreviousDemo,
            {
                "PanelID",
                "FileName"
            },
            "Previous",
            JoinKind.Inner
        ),

    Combined =
        Table.Combine(
            {
                Table.RemoveColumns(
                    CPAR,
                    {"Previous"}
                ),
                Table.RemoveColumns(
                    Conflict,
                    {"Previous"}
                ),
                Table.RemoveColumns(
                    Demo,
                    {"Previous"}
                )
            }
        ),

    AddRule =
        Table.AddColumn(
            Combined,
            "IgnoreRule",
            each
                ApplyIgnoreRules(
                    [Source],
                    _
                ),
            type any
        ),

    KeepActionable =
        Table.SelectRows(
            AddRule,
            each [IgnoreRule] = null
        ),

    RemoveRule =
        Table.RemoveColumns(
            KeepActionable,
            {"IgnoreRule"}
        )
in
    RemoveRule
