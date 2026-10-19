let
    // ============================================================
    // 1. REUSE PARSED TABLES
    // ============================================================
    ValidFiles =
        Table.SelectRows(
            Parsed_File_Cache,
            each
                [SourceType] = "DEMOGRAPHIC_MISMATCH"
                and [FolderStatus] = "OK"
                and [ImportStatus] = "OK"
                and [SchemaStatus] = "OK"
                and [DuplicateStatus] <> "DUPLICATE_SUPPRESSED"
        ),

    Tables =
        List.Select(
            Table.Column(ValidFiles, "ParsedTable"),
            each Value.Is(_, type table)
        ),

    Empty =
        #table(
            type table [
                #"Patient Id" = nullable text,
                #"Alberta Registry Patient Id" = nullable text,
                #"Panel Patient Last Name" = nullable text,
                #"Alberta Registry Patient Last Name" = nullable text,
                #"Panel Patient First Name" = nullable text,
                #"Alberta Registry Patient First Name" = nullable text,
                #"Panel Gender" = nullable text,
                #"Alberta Registry Gender" = nullable text,
                #"Panel Date Of Birth" = nullable any,
                #"Alberta Registry Date Of Birth" = nullable any,
                #"Date Of Death" = nullable any,
                PanelID = nullable text,
                Doctor = nullable text,
                ProducedDateTime = nullable datetime,
                DoctorValidation = nullable text,
                SourceFileName = nullable text
            ],
            {}
        ),

    // ============================================================
    // 2. COMBINE REPORTS
    // ============================================================
    Combined =
        if List.Count(Tables) = 0
        then Empty
        else Table.Combine(Tables),

    // ============================================================
    // 3. KEEP PATIENT ROWS
    // ============================================================
    KeepPatients =
        Table.SelectRows(
            Combined,
            each
                [#"Patient Id"] <> null
                and
                Text.Trim(
                    Text.From([#"Patient Id"])
                ) <> ""
        ),

    // ============================================================
    // 4. CLEAN TEXT FIELDS
    // ============================================================
    CleanText =
        Table.TransformColumns(
            KeepPatients,
            {
                {
                    "Patient Id",
                    each
                        if _ = null then null
                        else Text.Trim(Text.From(_)),
                    type nullable text
                },
                {
                    "Alberta Registry Patient Id",
                    each
                        if _ = null then null
                        else Text.Trim(Text.From(_)),
                    type nullable text
                },
                {
                    "Panel Patient Last Name",
                    each
                        if _ = null then null
                        else Text.Upper(Text.Trim(Text.From(_))),
                    type nullable text
                },
                {
                    "Alberta Registry Patient Last Name",
                    each
                        if _ = null then null
                        else Text.Upper(Text.Trim(Text.From(_))),
                    type nullable text
                },
                {
                    "Panel Patient First Name",
                    each
                        if _ = null then null
                        else Text.Upper(Text.Trim(Text.From(_))),
                    type nullable text
                },
                {
                    "Alberta Registry Patient First Name",
                    each
                        if _ = null then null
                        else Text.Upper(Text.Trim(Text.From(_))),
                    type nullable text
                }
            },
            null,
            MissingField.Ignore
        ),

    // ============================================================
    // 5. SAFE DATE HELPER
    // ============================================================
    ToNullableDate =
        (Value as any) as nullable date =>
            if Value = null then
                null
            else if Text.Trim(Text.From(Value)) = "" then
                null
            else
                try Date.From(Value)
                otherwise
                    try
                        Date.FromText(
                            Text.Trim(Text.From(Value)),
                            [Culture = "en-CA"]
                        )
                    otherwise null,

    // ============================================================
    // 6. CLEAN DATES
    // ============================================================
    CleanDates =
        Table.TransformColumns(
            CleanText,
            {
                {
                    "Panel Date Of Birth",
                    each ToNullableDate(_),
                    type nullable date
                },
                {
                    "Alberta Registry Date Of Birth",
                    each ToNullableDate(_),
                    type nullable date
                },
                {
                    "Date Of Death",
                    each ToNullableDate(_),
                    type nullable date
                }
            },
            null,
            MissingField.Ignore
        ),

    // ============================================================
    // 7. CLEAN METADATA
    // ============================================================
    CleanMetadata =
        Table.TransformColumns(
            CleanDates,
            {
                {
                    "PanelID",
                    each
                        if _ = null then null
                        else Text.Trim(Text.From(_)),
                    type nullable text
                },
                {
                    "Doctor",
                    each
                        if _ = null then null
                        else Text.Upper(Text.Trim(Text.From(_))),
                    type nullable text
                }
            },
            null,
            MissingField.Ignore
        ),

    // ============================================================
    // 8. CREATE OriginalPatientID
    //    123456789 (ABH) -> 12345-6789 AB
    //    12345-6789 AB  -> 12345-6789 AB
    //    Other values remain unchanged
    // ============================================================
    AddOriginalPatientID =
        Table.AddColumn(
            CleanMetadata,
            "OriginalPatientID",
            each
                let
                    Original = [#"Patient Id"],
                    OriginalText =
                        if Original = null then null
                        else Text.Trim(Text.From(Original)),

                    Digits =
                        if OriginalText = null then ""
                        else Text.Select(
                            OriginalText,
                            {"0".."9"}
                        ),

                    IsABH =
                        if OriginalText = null then false
                        else Text.EndsWith(
                            Text.Upper(OriginalText),
                            "(ABH)"
                        ),

                    IsAB =
                        if OriginalText = null then false
                        else Text.EndsWith(
                            Text.Upper(OriginalText),
                            " AB"
                        )
                in
                    if OriginalText = null then
                        null
                    else if
                        Text.Length(Digits) = 9
                        and (IsABH or IsAB)
                    then
                        Text.Insert(Digits, 5, "-") & " AB"
                    else
                        OriginalText,
            type nullable text
        ),

    // ============================================================
    // 9. CREATE PatientID
    //    12345-6789 AB -> 12345-6789
    //    Other values remain unchanged
    // ============================================================
    AddPatientID =
        Table.AddColumn(
            AddOriginalPatientID,
            "PatientID",
            each
                let
                    Original = [OriginalPatientID],
                    OriginalText =
                        if Original = null then null
                        else Text.Trim(Text.From(Original)),

                    Digits =
                        if OriginalText = null then ""
                        else Text.Select(
                            OriginalText,
                            {"0".."9"}
                        )
                in
                    if OriginalText = null then
                        null
                    else if
                        Text.Length(Digits) = 9
                        and Text.EndsWith(
                            Text.Upper(OriginalText),
                            " AB"
                        )
                    then
                        Text.Insert(Digits, 5, "-")
                    else
                        OriginalText,
            type nullable text
        ),

    // ============================================================
    // 10. EVENT DATE
    // ============================================================
    AddEventDate =
        Table.AddColumn(
            AddPatientID,
            "EventDate",
            each
                if [ProducedDateTime] = null
                then null
                else Date.From([ProducedDateTime]),
            type nullable date
        ),

    // ============================================================
    // 11. MASTER KEY
    //    PanelID|OriginalPatientID
    // ============================================================
    AddMasterKey =
        Table.AddColumn(
            AddEventDate,
            "MasterKey",
            each
                if [PanelID] = null
                    or [OriginalPatientID] = null
                then null
                else
                    [PanelID]
                    & "|"
                    & [OriginalPatientID],
            type nullable text
        ),

    // ============================================================
    // 12. RECORD ID
    // ============================================================
    AddRecordID =
        Table.AddColumn(
            AddMasterKey,
            "RecordID",
            each
                if [MasterKey] = null then null
                else
                    [MasterKey]
                    & "|DEMOGRAPHIC_MISMATCH|"
                    &
                    (
                        if [EventDate] = null
                        then "NO_DATE"
                        else Date.ToText(
                            [EventDate],
                            "yyyy-MM-dd"
                        )
                    ),
            type nullable text
        ),

    // ============================================================
    // 13. SOURCE
    // ============================================================
    AddSource =
        Table.AddColumn(
            AddRecordID,
            "Source",
            each "DEMOGRAPHIC_MISMATCH",
            type text
        ),

    // ============================================================
    // 14. ISSUE TYPE
    // ============================================================
    AddIssue =
        Table.AddColumn(
            AddSource,
            "IssueType",
            each "Demographic mismatch",
            type text
        ),

    // ============================================================
    // 15. RENAME COMMON COLUMNS
    // ============================================================
    Rename =
        Table.RenameColumns(
            AddIssue,
            {
                {
                    "Panel Patient Last Name",
                    "LastName"
                },
                {
                    "Panel Patient First Name",
                    "FirstName"
                },
                {
                    "Panel Date Of Birth",
                    "DOB"
                }
            },
            MissingField.Ignore
        ),

    // ============================================================
    // 16. PUT IMPORTANT COLUMNS FIRST
    // ============================================================
    ImportantColumns =
        {
            "RecordID",
            "MasterKey",
            "PanelID",
            "Doctor",
            "PatientID",
            "OriginalPatientID",
            "Source",
            "EventDate",
            "LastName",
            "FirstName",
            "DOB",
            "IssueType",

            "Patient Id",
            "Alberta Registry Patient Id",
            "Alberta Registry Patient Last Name",
            "Alberta Registry Patient First Name",
            "Panel Gender",
            "Alberta Registry Gender",
            "Alberta Registry Date Of Birth",
            "Date Of Death",

            "ProducedDateTime",
            "DoctorValidation",
            "SourceFileName"
        },

    ExistingImportantColumns =
        List.Select(
            ImportantColumns,
            each List.Contains(
                Table.ColumnNames(Rename),
                _
            )
        ),

    OtherColumns =
        List.RemoveItems(
            Table.ColumnNames(Rename),
            ExistingImportantColumns
        ),

    Reorder =
        Table.ReorderColumns(
            Rename,
            ExistingImportantColumns & OtherColumns
        )

in
    Reorder
