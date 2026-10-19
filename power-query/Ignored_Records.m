let
    Source =
        Current_Source_Events,

    AddRule =
        Table.AddColumn(
            Source,
            "IgnoreRule",
            each
                ApplyIgnoreRules(
                    [Source],
                    _
                ),
            type any
        ),

    AddRuleID =
        Table.AddColumn(
            AddRule,
            "RuleID",
            each
                if [IgnoreRule] = null
                then null
                else [IgnoreRule][RuleID],
            type nullable text
        ),

    AddReason =
        Table.AddColumn(
            AddRuleID,
            "IgnoreReason",
            each
                if [IgnoreRule] = null
                then null
                else [IgnoreRule][Reason],
            type nullable text
        ),

    KeepIgnored =
        Table.SelectRows(
            AddReason,
            each [RuleID] <> null
        ),

    Select =
        Table.SelectColumns(
            KeepIgnored,
            {
                "RecordID",
                "PanelID",
                "Doctor",
                "PatientID",
                "Source",
                "EventDate",
                "RuleID",
                "IgnoreReason",
                "SourceFileName"
            },
            MissingField.UseNull
        ),

    Rename =
        Table.RenameColumns(
            Select,
            {
                {"IgnoreReason", "Reason"}
            }
        )
in
    Rename
