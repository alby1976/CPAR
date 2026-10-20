let
    // ============================================================
    // 1. MANUAL PROCESSED LOG
    // ============================================================

    Manual0 = Processed_Log,

    OutputColumns = {"RecordID", "MasterKey", "PanelID", "Doctor", "PatientID", "Source", "EventDate", "DateProcessed", "Status", "DateStarted", "ActionTaken", "Notes"},

    Manual =
        Table.SelectColumns(
            Manual0,
            OutputColumns,
            MissingField.UseNull
        ),

    // ============================================================
    // 2. RULES THAT ARE ALLOWED TO AUTO-PROCESS
    // ============================================================

    AutoRules0 =
        Table.SelectRows(
            Ignore_Rules,
            each
                [AutoProcess] = true
                and
                (
                    if [AutoStatus] = null then
                        false
                    else
                        Text.Upper(Text.Trim(Text.From([AutoStatus]))) = "IGNORE"
                )
        ),

    AutoRuleIDs =
        Table.Distinct(
            Table.SelectColumns(
                AutoRules0,
                {"RuleID"}
            )
        ),

    // ============================================================
    // 3. IGNORE RECORDS
    // ============================================================

    // If your actual query is named Ignored_Records rather
    // than Ignore_Records, change this one line.
    Ignored0 = Ignored_Records,

    AutoMatches0 =
        Table.NestedJoin(
            Ignored0,
            {"RuleID"},
            AutoRuleIDs,
            {"RuleID"},
            "AutoRuleMatch",
            JoinKind.Inner
        ),

    AutoMatches =
        Table.RemoveColumns(
            AutoMatches0,
            {"AutoRuleMatch"}
        ),

    // ============================================================
    // 4. CONVERT AUTOMATIC IGNORE ROWS TO PROCESSED-LOG FORMAT
    // ============================================================

    AddMasterKey =
        if Table.HasColumns(AutoMatches, {"MasterKey"}) then
            AutoMatches
        else
            Table.AddColumn(
                AutoMatches,
                "MasterKey",
                each
                    if [PanelID] = null or [PatientID] = null then
                        null
                    else
                        Text.Trim(Text.From([PanelID]))
                        & "|"
                        & Text.Trim(Text.From([PatientID])),
                type nullable text
            ),

    AddStatus =
        Table.AddColumn(
            AddMasterKey,
            "Status",
            each "IGNORE",
            type text
        ),

    AddDateStarted =
        Table.AddColumn(
            AddStatus,
            "DateStarted",
            each null,
            type nullable date
        ),

    AddDateProcessed =
        Table.AddColumn(
            AddDateStarted,
            "DateProcessed",
            each null,
            type nullable date
        ),

    AddActionTaken =
        Table.AddColumn(
            AddDateProcessed,
            "ActionTaken",
            each
                if [RuleID] = null then
                    "Automatically ignored"
                else
                    "Automatically ignored by rule "
                    & Text.From([RuleID]),
            type text
        ),

    AddNotes =
        Table.AddColumn(
            AddActionTaken,
            "AutoNotes",
            each
                let
                    Rule =
                        if [RuleID] = null then
                            ""
                        else
                            Text.From([RuleID]),

                    ReasonText =
                        try Text.Trim(Text.From([Reason]))
                        otherwise ""
                in
                    if ReasonText = "" then
                        "Automatic IGNORE"
                        &
                        (
                            if Rule = "" then
                                ""
                            else
                                " — Rule " & Rule
                        )
                    else
                        ReasonText
                        &
                        (
                            if Rule = "" then
                                ""
                            else
                                " — Rule " & Rule
                        ),
            type text
        ),

    RemoveExistingNotes =
        if Table.HasColumns(AddNotes, {"Notes"}) then
            Table.RemoveColumns(
                AddNotes,
                {"Notes"}
            )
        else
            AddNotes,

    RenameNotes =
        Table.RenameColumns(
            RemoveExistingNotes,
            {
                {"AutoNotes", "Notes"}
            }
        ),

    AutoProcessed0 =
        Table.SelectColumns(
            RenameNotes,
            OutputColumns,
            MissingField.UseNull
        ),

    // One automatic row per RecordID.
    AutoProcessed =
        Table.Distinct(
            AutoProcessed0,
            {"RecordID"}
        ),

    // ============================================================
    // 5. MANUAL ENTRY ALWAYS WINS
    //
    // If somebody has already manually processed the same
    // RecordID, do not create an automatic duplicate.
    // ============================================================

    ManualRecordIDs =
        List.Buffer(
            List.RemoveNulls(
                Manual[RecordID]
            )
        ),

    AutoNotAlreadyManual =
        Table.SelectRows(
            AutoProcessed,
            each
                [RecordID] <> null
                and not List.Contains(
                    ManualRecordIDs,
                    [RecordID]
                )
        ),

    // ============================================================
    // 6. COMBINE MANUAL + AUTOMATIC
    // ============================================================

    Combined =
        Table.Combine(
            {
                Manual,
                AutoNotAlreadyManual
            }
        ),

    RemoveBlankRecordIDs =
        Table.SelectRows(
            Combined,
            each
                [RecordID] <> null
                and Text.Trim(Text.From([RecordID])) <> ""
        ),

    Final =
        Table.TransformColumnTypes(
            RemoveBlankRecordIDs,
            {
                {"RecordID", type text},
                {"MasterKey", type text},
                {"PanelID", type text},
                {"Doctor", type text},
                {"PatientID", type text},
                {"Source", type text},
                {"EventDate", type date},
                {"Status", type text},
                {"DateStarted", type date},
                {"DateProcessed", type date},
                {"ActionTaken", type text},
                {"Notes", type text}
            }
        )

in
    Final
