let
    // Default FALSE: retain older conflicts until the clinic opts into this rule.
    ApplyHistoricalFilter = List.Contains({"TRUE", "YES", "1"}, Text.Upper(Text.Trim(try ConfigValue("Apply_Conflict_Date_Filter") otherwise "FALSE"))),
    Source =
        Table.SelectRows(
            Standardize_Conflicts,
            each [DoctorValidation] = "OK"
        ),

    MergeMaster =
        Table.NestedJoin(
            Source,
            {"MasterKey"},
            Master_Patient_List,
            {"MasterKey"},
            "Master",
            JoinKind.LeftOuter
        ),

    Expand =
        Table.ExpandTableColumn(
            MergeMaster,
            "Master",
            {"EffectiveMasterEntryDate"},
            {"EffectiveMasterEntryDate"}
        ),

    Rule =
        Table.AddColumn(
            Expand,
            "ConflictRule",
            each
                if [EffectiveMasterEntryDate] = null then
                    "KEEP_NO_MASTER"

                else if [EventDate] = null then
                    "KEEP_NO_EVENT_DATE"

                else if [EventDate] > [EffectiveMasterEntryDate] then
                    "KEEP_NEW_CONFLICT"

                else
                    "OLD_CONFLICT",
            type text
        ),

    KeepActionable =
        Table.SelectRows(
            Rule,
            each not ApplyHistoricalFilter or [ConflictRule] <> "OLD_CONFLICT"
        ),

    AddRecordID =
        Table.AddColumn(
            KeepActionable,
            "RecordID",
            each
                [MasterKey]
                & "|CONFLICT|"
                &
                (
                    if [EventDate] = null
                    then "NO_DATE"
                    else Date.ToText([EventDate], "yyyy-MM-dd")
                ),
            type text
        ),

    AddIssue =
        Table.AddColumn(
            AddRecordID,
            "IssueType",
            each
                "Conflict: "
                &
                (
                    if [#"Conflict Category"] = null
                    then ""
                    else Text.From([#"Conflict Category"])
                ),
            type text
        ),

    RemoveTemporaryMasterDate =
        Table.RemoveColumns(
            AddIssue,
            {"EffectiveMasterEntryDate"}
        )
in
    RemoveTemporaryMasterDate
