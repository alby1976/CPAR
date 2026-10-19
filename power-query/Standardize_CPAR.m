let
    // ============================================================
    // 1. REUSE PARSED TABLES FROM CACHE
    // ============================================================
    ValidFiles =
        Table.SelectRows(
            Parsed_File_Cache,
            each
                [SourceType] = "CPAR"
                and [FolderStatus] = "OK"
                and [ImportStatus] = "OK"
                and [SchemaStatus] = "OK"
                and [DuplicateStatus] <> "DUPLICATE_SUPPRESSED"
        ),

    ValidTables =
        List.Select(
            Table.Column(ValidFiles, "ParsedTable"),
            each Value.Is(_, type table)
        ),

    Empty =
        #table(
            type table [
                PHN = nullable text,
                LAST_NAME = nullable text,
                FIRST_NAME = nullable text,
                #"SENT TO CPAR" = nullable text,
                UNABLE_TO_SEND_REASON = nullable text,
                PanelID = nullable text,
                Doctor = nullable text,
                ReportDate = nullable date,
                SourceFileName = nullable text
            ],
            {}
        ),

    Combined =
        if List.Count(ValidTables) = 0
        then Empty
        else Table.Combine(ValidTables),

    // ============================================================
    // 2. REMOVE EMPTY PHN ROWS
    // ============================================================
    Keep =
        Table.SelectRows(
            Combined,
            each
                [PHN] <> null
                and Text.Trim(Text.From([PHN])) <> ""
        ),

    // ============================================================
    // 3. SET DATA TYPES
    // ============================================================
    Types =
        Table.TransformColumnTypes(
            Keep,
            {
                {"PanelID", type text},
                {"Doctor", type text},
                {"ReportDate", type date},
                {"PHN", type text},
                {"LAST_NAME", type text},
                {"FIRST_NAME", type text},
                {"SENT TO CPAR", type text},
                {"UNABLE_TO_SEND_REASON", type text}
            }
        ),

    // ============================================================
    // 4. PRESERVE ORIGINAL PHN FOR AUDIT
    // ============================================================
    AddOriginalPHN =
        Table.DuplicateColumn(
            Types,
            "PHN",
            "OriginalPHN"
        ),

    // ============================================================
    // 5. CLEAN PHN AND PATIENT NAMES
    // ============================================================
    Clean =
        Table.TransformColumns(
            AddOriginalPHN,
            {
                {
                    "PHN",
                    each
                        if _ = null then null
                        else Text.Select(
                            Text.From(_),
                            {"0".."9"}
                        ),
                    type nullable text
                },
                {
                    "LAST_NAME",
                    each
                        if _ = null then null
                        else Text.Upper(
                            Text.Trim(Text.From(_))
                        ),
                    type nullable text
                },
                {
                    "FIRST_NAME",
                    each
                        if _ = null then null
                        else Text.Upper(
                            Text.Trim(Text.From(_))
                        ),
                    type nullable text
                }
            }
        ),

    // ============================================================
    // 6. VALIDATE CLEANED PHN
    // ============================================================
    AddPHNValidation =
        Table.AddColumn(
            Clean,
            "PHNValidation",
            each
                if [PHN] = null or [PHN] = "" then
                    "MISSING_PHN"
                else if Text.Length([PHN]) <> 9 then
                    "INVALID_PHN_LENGTH"
                else
                    "OK",
            type text
        ),


    // ============================================================
    // 7. CREATE PATIENT ID (12345-6789)
    // ============================================================
    AddPatientID =
        Table.AddColumn(
            AddPHNValidation,
            "PatientID",
            each
                if [PHNValidation] = "OK" then
                    Text.Insert([PHN], 5, "-")
                else
                    null,
            type nullable text
        ),

    // ============================================================
    // 7A. FORMAT ORIGINAL PHN (12345-6789 AB)
    // ============================================================
    FormatOriginalPHN =
        Table.TransformColumns(
            AddPatientID,
            {
                {
                    "OriginalPHN",
                    each
                        if _ = null then null
                        else
                            let
                                Original = Text.Trim(Text.From(_)),
                                Digits = Text.Select(
                                    Original,
                                    {"0".."9"}
                                )
                            in
                                if Text.Length(Digits) = 9
                                    and Text.EndsWith(
                                        Text.Upper(Original),
                                        "AB"
                                    )
                                then
                                    Text.Insert(Digits, 5, "-") & " AB"
                                else
                                    Original,
                    type nullable text
                }
            }
        ),


    // ============================================================
    // 8. CREATE MASTER KEY
    // ============================================================
    AddMasterKey =
        Table.AddColumn(
            FormatOriginalPHN,
            "MasterKey",
            each
                //if [PanelID] = null
                //    or [PatientID] = null
                //then null
                //else
                    Text.Trim([PanelID])
                    & "|"
                    & [OriginalPHN],
            type nullable text
        ),

    // ============================================================
    // 9. CREATE RECORD ID
    // ============================================================
    AddRecordID =
        Table.AddColumn(
            AddMasterKey,
            "RecordID",
            each
                if [MasterKey] = null then null
                else
                    [MasterKey]
                    & "|CPAR|"
                    &
                    (
                        if [ReportDate] = null
                        then "NO_DATE"
                        else Date.ToText(
                            [ReportDate],
                            "yyyy-MM-dd"
                        )
                    ),
            type nullable text
        ),

    // ============================================================
    // 10. ADD SOURCE AND DOB
    // ============================================================
    AddSource =
        Table.AddColumn(
            AddRecordID,
            "Source",
            each "CPAR",
            type text
        ),

    AddDOB =
        Table.AddColumn(
            AddSource,
            "DOB",
            each null,
            type nullable date
        ),

    // ============================================================
    // 11. CREATE ISSUE TYPE
    // ============================================================
    AddIssue =
        Table.AddColumn(
            AddDOB,
            "IssueType",
            each
                "CPAR: "
                &
                (
                    if [#"SENT TO CPAR"] = null
                    then ""
                    else Text.From([#"SENT TO CPAR"])
                ),
            type text
        ),

    // ============================================================
    // 12. SELECT OUTPUT COLUMNS
    // ============================================================
    Select =
        Table.SelectColumns(
            AddIssue,
            {
                "RecordID",
                "MasterKey",
                "PanelID",
                "Doctor",
                "PatientID",
                "OriginalPHN",
                "PHNValidation",
                "Source",
                "ReportDate",
                "LAST_NAME",
                "FIRST_NAME",
                "DOB",
                "IssueType",
                "UNABLE_TO_SEND_REASON",
                "SourceFileName"
            }
        )
in
    Select
