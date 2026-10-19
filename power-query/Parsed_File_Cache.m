let
    // ============================================================
    // 1. START WITH CANDIDATE FILES ONLY
    // ============================================================
    Source =
        Candidate_File_Content,

    // ============================================================
    // 2. INSPECT ONE FILE USING THE REAL PARSER FUNCTIONS
    //
    // This is important:
    //
    // CPAR       -> Parse_CPAR_File
    // Conflict   -> Parse_Conflict_File
    // Demo       -> Parse_Demographic_Mismatch_File
    //
    // The file binary is opened only for candidate rows.
    // ============================================================
    InspectOne =
        (r as record) as record =>
        let
            CurrentSource =
                r[SourceType],

            CurrentFileName =
                r[Name],

            // Content is supplied by Candidate_File_Content.
            // Do NOT call File.Contents() here; doing so while this
            // query references another query triggers Formula.Firewall.
            CurrentBinary =
                if
                    Record.HasFields(r, "Content")
                    and r[Content] <> null
                then
                    Binary.Buffer(r[Content])
                else
                    error
                        "No Content binary was found for candidate file: "
                        & CurrentFileName,

            CurrentPanelID =
                try
                    Text.Trim(
                        Text.From(r[FolderPanelID])
                    )
                otherwise
                    null,

            CurrentDoctor =
                try
                    Text.Upper(
                        Text.Trim(
                            Text.From(r[FolderDoctor])
                        )
                    )
                otherwise
                    null,

            // ====================================================
            // RUN THE CORRECT PARSER
            // ====================================================
            ParseTry =
                if CurrentSource = "CPAR" then
                    try
                        Parse_CPAR_File(
                            CurrentBinary,
                            r[Name],
                            r[FolderPanelID],
                            r[FolderDoctor]
                        )

                else if CurrentSource = "CONFLICT" then
                    try
                        Parse_Conflict_File(
                            CurrentBinary,
                            r[Name],
                            r[FolderPanelID],
                            r[FolderDoctor]
                        )

                else if CurrentSource = "DEMOGRAPHIC_MISMATCH" then
                    try
                        Parse_Demographic_Mismatch_File(
                            CurrentBinary,
                            r[Name],
                            r[FolderPanelID],
                            r[FolderDoctor]
                        )

                else
                    try
                        #table({}, {}),

            ParseOK =
                not ParseTry[HasError],

            ParsedTable =
                if ParseOK
                then Table.Buffer(ParseTry[Value])
                else #table({}, {}),

            // ====================================================
            // IMPORT STATUS
            // ====================================================
            ImportStatus =
                if ParseOK
                then "OK"
                else "ERROR",

            ParseError =
                if ParseOK then
                    null
                else
                    try
                        ParseTry[Error][Message]
                    otherwise
                        "Unknown parser error",

            // ====================================================
            // SCHEMA VALIDATION
            // ====================================================
            SchemaResult =
                if not ParseOK then
                    [
                        SchemaStatus = "NOT_TESTED",
                        MissingColumns = null
                    ]

                else if
                    List.Contains(
                        {
                            "CPAR",
                            "CONFLICT",
                            "DEMOGRAPHIC_MISMATCH"
                        },
                        CurrentSource
                    )
                then
                    Schema_Validation(
                        CurrentSource,
                        Table.ColumnNames(ParsedTable)
                    )

                else
                    [
                        SchemaStatus = "NOT_APPLICABLE",
                        MissingColumns = null
                    ],

            // ====================================================
            // DOCTOR VALIDATION
            //
            // CPAR gets its doctor/panel from the folder.
            //
            // Conflict and Demo parsers already produce
            // DoctorValidation.
            // ====================================================
            DoctorValidation =
                if not ParseOK then
                    "NOT_TESTED"

                else if CurrentSource = "CPAR" then
                    if
                        CurrentPanelID <> null
                        and CurrentDoctor <> null
                    then
                        "OK"
                    else
                        "UNMAPPED_DOCTOR_FOLDER"

                else if
                    CurrentSource = "CONFLICT"
                    or CurrentSource = "DEMOGRAPHIC_MISMATCH"
                then
                    if Table.RowCount(ParsedTable) = 0 then
                        "OK"
                    else
                        try
                            ParsedTable{0}[DoctorValidation]
                        otherwise
                            "MISSING_DOCTOR_VALIDATION"

                else
                    "OK",

            // ====================================================
            // REPORT DATE / DATETIME
            // ====================================================
            CPARAfterPrefix =
                if CurrentSource <> "CPAR" then
                    ""
                else
                    try
                        Text.AfterDelimiter(
                            CurrentFileName,
                            "CPAR_Submission_Summary_"
                        )
                    otherwise
                        "",

            CPARDate =
                if CurrentSource <> "CPAR" then
                    null
                else
                    try
                        Date.FromText(
                            Text.Start(
                                CPARAfterPrefix,
                                10
                            )
                        )
                    otherwise
                        null,

            ParsedReportDateTime =
                if not ParseOK then
                    null

                else if CurrentSource = "CPAR" then
                    if CPARDate = null
                    then null
                    else DateTime.From(CPARDate)

                else if CurrentSource = "CONFLICT" then
                    if Table.RowCount(ParsedTable) = 0 then
                        null
                    else
                        try
                            DateTime.From(
                                ParsedTable{0}[ProducedDate]
                            )
                        otherwise
                            null

                else if CurrentSource = "DEMOGRAPHIC_MISMATCH" then
                    if Table.RowCount(ParsedTable) = 0 then
                        null
                    else
                        try
                            ParsedTable{0}[ProducedDateTime]
                        otherwise
                            null

                else
                    null,

            // ====================================================
            // ROW COUNT
            // ====================================================
            RowCount =
                if ParseOK
                then Table.RowCount(ParsedTable)
                else null,

            // ====================================================
            // FINAL ERROR MESSAGE
            // ====================================================
            ErrorMessage =
                if not ParseOK then
                    ParseError

                else if SchemaResult[SchemaStatus] <> "OK"
                    and SchemaResult[SchemaStatus] <> "NOT_APPLICABLE"
                then
                    "Missing required columns: "
                    &
                    (
                        if SchemaResult[MissingColumns] = null
                        then ""
                        else SchemaResult[MissingColumns]
                    )

                else if DoctorValidation <> "OK" then
                    DoctorValidation

                else
                    null
        in
            [
                ParsedTable = ParsedTable,
                ImportStatus = ImportStatus,
                ErrorMessage = ErrorMessage,
                SchemaStatus = SchemaResult[SchemaStatus],
                MissingColumns = SchemaResult[MissingColumns],
                DoctorValidation = DoctorValidation,
                ParsedReportDateTime = ParsedReportDateTime,
                ParsedRowCount = RowCount
            ],

    // ============================================================
    // 3. INSPECT EVERY FILE
    // ============================================================
    AddInspection =
        Table.AddColumn(
            Source,
            "Inspection",
            each InspectOne(_),
            type record
        ),

    // ============================================================
    // 4. EXPAND INSPECTION RESULTS
    // ============================================================
    ExpandInspection =
        Table.ExpandRecordColumn(
            AddInspection,
            "Inspection",
            {
                "ParsedTable",
                "ImportStatus",
                "ErrorMessage",
                "SchemaStatus",
                "MissingColumns",
                "DoctorValidation",
                "ParsedReportDateTime",
                "ParsedRowCount"
            },
            {
                "ParsedTable",
                "ImportStatus",
                "ErrorMessage",
                "SchemaStatus",
                "MissingColumns",
                "DoctorValidation",
                "ParsedReportDateTime",
                "ParsedRowCount"
            }
        ),

    // ============================================================
    // 5. REPORT DATETIME
    //
    // Prefer the AHS report date.
    // Fall back to file modified time only when necessary.
    // ============================================================
    AddReportDateTime =
        Table.AddColumn(
            ExpandInspection,
            "ReportDateTime",
            each
                if [ParsedReportDateTime] <> null then
                    [ParsedReportDateTime]
                else
                    try
                        DateTime.From(
                            [Date modified]
                        )
                    otherwise
                        null,
            type nullable datetime
        ),

    // ============================================================
    // 6. REPORT DATE
    // ============================================================
    AddReportDate =
        Table.AddColumn(
            AddReportDateTime,
            "ReportDate",
            each
                if [ReportDateTime] = null
                then null
                else Date.From([ReportDateTime]),
            type nullable date
        ),

    // ============================================================
    // 7. STANDARD OUTPUT COLUMN NAMES
    // ============================================================
    AddPanel =
        Table.AddColumn(
            AddReportDate,
            "PanelID",
            each [FolderPanelID],
            type nullable text
        ),

    AddDoctor =
        Table.AddColumn(
            AddPanel,
            "Doctor",
            each [FolderDoctor],
            type nullable text
        ),

    AddFileName =
        Table.AddColumn(
            AddDoctor,
            "FileName",
            each [Name],
            type text
        ),

    AddFileModified =
        Table.AddColumn(
            AddFileName,
            "FileModified",
            each
                try
                    DateTime.From(
                        [Date modified]
                    )
                otherwise
                    null,
            type nullable datetime
        ),
    #"Changed Type" = Table.TransformColumnTypes(AddFileModified,{{"Date accessed", type datetimezone}, {"Date modified", type datetimezone}, {"Date created", type datetimezone}, {"ParsedReportDateTime", type datetimezone}, {"ReportDateTime", type datetimezone}, {"FileModified", type datetimezone}})

in
    #"Changed Type"
