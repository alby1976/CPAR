(SourceName as text, EventRecord as record) as nullable record =>
let
    // ============================================================
    // 1. GET ACTIVE RULES FOR THIS SOURCE
    // ============================================================
    CandidateRules =
        Table.SelectRows(
            Ignore_Rules,
            each
                Text.Upper(
                    Text.Trim([Source])
                )
                =
                Text.Upper(
                    Text.Trim(SourceName)
                )
        ),

    // ============================================================
    // 2. TEST EACH RULE
    // ============================================================
    AddMatch =
        Table.AddColumn(
            CandidateRules,
            "IsMatch",
            each
                let
                    ConfiguredField =
                        Text.Trim(
                            Text.From([FieldName])
                        ),

                    // --------------------------------------------
                    // FIELD ALIASES
                    //
                    // Allows old configuration names to continue
                    // working with the standardized CPAR field.
                    // --------------------------------------------
                    ActualField =
                        if
                            Text.Upper(ConfiguredField)
                            = "UNABLE_TO_SEND_REASON"
                        then
                            "UnableToSendReason"

                        else if
                            Text.Upper(ConfiguredField)
                            = "UNABLETOSENDREASON"
                        then
                            "UnableToSendReason"

                        else
                            ConfiguredField,

                    MatchType0 =
                        if [MatchType] = null
                        then ""
                        else
                            Text.Upper(
                                Text.Trim(
                                    Text.From([MatchType])
                                )
                            ),

                    Wanted =
                        if [MatchValue] = null
                        then ""
                        else
                            Text.Trim(
                                Text.From([MatchValue])
                            ),

                    ActualRaw =
                        try
                            Record.Field(
                                EventRecord,
                                ActualField
                            )
                        otherwise
                            null,

                    Actual =
                        if ActualRaw = null
                        then ""
                        else
                            Text.Trim(
                                Text.From(ActualRaw)
                            ),

                    IsMatch =
                        if MatchType0 = "EXACT" then
                            Text.Upper(Actual)
                            =
                            Text.Upper(Wanted)

                        else if MatchType0 = "CONTAINS" then
                            Text.Contains(
                                Text.Upper(Actual),
                                Text.Upper(Wanted)
                            )

                        else
                            false
                in
                    IsMatch,
            type logical
        ),

    // ============================================================
    // 3. KEEP MATCHING RULES
    // ============================================================
    Hits =
        Table.SelectRows(
            AddMatch,
            each [IsMatch] = true
        ),

    // ============================================================
    // 4. RETURN FIRST MATCH
    // ============================================================
    Result =
        if Table.RowCount(Hits) = 0 then
            null
        else
            [
                RuleID = Hits{0}[RuleID],
                Reason = Hits{0}[Reason]
            ]

in
    Result
