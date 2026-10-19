(FileContent as binary, FileName as text, FolderPanelID as text, FolderDoctor as text) as table =>
let
    Raw =
        Csv.Document(
            FileContent,
            [
                Delimiter = ",",
                Encoding = 65001,
                QuoteStyle = QuoteStyle.Csv
            ]
        ),

    ColumnNames = Table.ColumnNames(Raw),

    FirstColName =
        if List.Count(ColumnNames) = 0
        then error "CSV contains no columns: " & FileName
        else ColumnNames{0},

    FirstCol =
        List.Transform(
            Table.Column(Raw, FirstColName),
            each
                if _ = null
                then ""
                else Text.Trim(Text.From(_))
        ),

    FirstColUpper =
        List.Transform(
            FirstCol,
            each Text.Upper(_)
        ),

    HeaderIndex =
        List.PositionOf(
            FirstColUpper,
            "LAST_NAME"
        ),

    Body =
        if HeaderIndex < 0
        then error "LAST_NAME header not found in " & FileName
        else Table.Skip(Raw, HeaderIndex),

    Promoted0 =
        Table.PromoteHeaders(
            Body,
            [PromoteAllScalars = true]
        ),

    Promoted =
        Table.TransformColumnNames(
            Promoted0,
            each Text.Trim(_)
        ),

    AfterPrefix =
        try
            Text.AfterDelimiter(
                FileName,
                "CPAR_Submission_Summary_"
            )
        otherwise
            "",

    DateText =
        Text.Start(
            AfterPrefix,
            10
        ),

    ReportDate =
        try Date.FromText(DateText)
        otherwise null,

    AddPanel =
        Table.AddColumn(
            Promoted,
            "PanelID",
            each FolderPanelID,
            type text
        ),

    AddDoctor =
        Table.AddColumn(
            AddPanel,
            "Doctor",
            each FolderDoctor,
            type text
        ),

    AddReportDate =
        Table.AddColumn(
            AddDoctor,
            "ReportDate",
            each ReportDate,
            type nullable date
        ),

    AddFileName =
        Table.AddColumn(
            AddReportDate,
            "SourceFileName",
            each FileName,
            type text
        )
in
    AddFileName
