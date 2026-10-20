(FileContent as binary, FileName as text, FolderPanelID as text, FolderDoctor as text) as table =>
let
    // ============================================================
    // 1. READ THE FILE AS TEXT LINES
    //
    // AHS Conflict CSV structure:
    //
    //   report preamble
    //   report preamble
    //   Produced date...
    //   Panel ID...
    //
    //   Conflict Category,Conflict First Reported,Patient ID,...
    //   patient row
    //   patient row
    //
    // We remove the preamble BEFORE Csv.Document parses the table.
    // ============================================================
    Lines =
        Lines.FromBinary(
            FileContent,
            null,
            null,
            65001
        ),

    // ============================================================
    // 2. GENERAL TEXT NORMALIZER
    //
    // Used for searching preamble/header lines.
    //
    // - removes UTF-8 BOM
    // - removes non-breaking spaces
    // - removes control characters
    // - collapses repeated spaces
    // - uppercases text
    // ============================================================
    NormalizeText =
        (Value as any) as text =>
        let
            Original =
                if Value = null then
                    ""
                else
                    Text.From(Value),

            RemoveBOM =
                Text.Replace(
                    Original,
                    Character.FromNumber(65279),
                    ""
                ),

            RemoveNBSP =
                Text.Replace(
                    RemoveBOM,
                    Character.FromNumber(160),
                    " "
                ),

            Clean =
                Text.Clean(RemoveNBSP),

            Parts =
                List.Select(
                    Text.SplitAny(
                        Text.Trim(Clean),
                        " " & Character.FromNumber(9)
                    ),
                    each _ <> ""
                ),

            SingleSpaces =
                Text.Combine(
                    Parts,
                    " "
                )
        in
            Text.Upper(SingleSpaces),

    // ============================================================
    // 3. DOCTOR NAME NORMALIZER
    //
    // Makes these equivalent:
    //
    // Provider example identifiers removed.
    // Provider example identifiers removed.
    // Provider example identifiers removed.
    //
    // ============================================================
    NormalizeDoctorName =
        (Value as nullable text) as nullable text =>
        let
            Upper =
                if Value = null then
                    null
                else
                    Text.Upper(
                        Text.Trim(Value)
                    ),

            RemovePeriods =
                if Upper = null then
                    null
                else
                    Text.Replace(
                        Upper,
                        ".",
                        ""
                    ),

            RemoveCommas =
                if RemovePeriods = null then
                    null
                else
                    Text.Replace(
                        RemovePeriods,
                        ",",
                        ""
                    ),

            Parts =
                if RemoveCommas = null then
                    {}
                else
                    List.Select(
                        Text.Split(
                            RemoveCommas,
                            " "
                        ),
                        each _ <> ""
                    ),

            Result =
                if RemoveCommas = null then
                    null
                else
                    Text.Combine(
                        Parts,
                        " "
                    )
        in
            Result,

    // ============================================================
    // 4. NORMALIZED COPY OF EVERY LINE
    // ============================================================
    NormalizedLines =
        List.Transform(
            Lines,
            each NormalizeText(_)
        ),

    // ============================================================
    // 5. FIND PRODUCED DATE
    //
    // Example:
    //
    // Produced date: 2026-Apr-24
    //
    // Also tolerates:
    //
    // Produced   date: 2026-Apr-24
    // ============================================================
    ProducedIndex =
        List.PositionOf(
            List.Transform(
                NormalizedLines,
                each
                    Text.StartsWith(
                        _,
                        "PRODUCED DATE:"
                    )
            ),
            true
        ),

    ProducedLine =
        if ProducedIndex < 0 then
            null
        else
            Lines{ProducedIndex},

    ProducedText =
        if ProducedLine = null then
            null
        else
            try
                Text.Trim(
                    Text.AfterDelimiter(
                        ProducedLine,
                        ":"
                    )
                )
            otherwise
                null,

    ProducedDate =
        if ProducedText = null then
            null
        else
            try
                Date.FromText(
                    ProducedText,
                    [
                        Format = "yyyy-MMM-dd",
                        Culture = "en-CA"
                    ]
                )
            otherwise
                try
                    Date.From(
                        DateTime.FromText(
                            ProducedText,
                            [Culture = "en-CA"]
                        )
                    )
                otherwise
                    null,

    // ============================================================
    // 6. FIND PANEL / DOCTOR LINE
    //
    // Example:
    //
    // Provider example identifiers removed.
    // ============================================================
    PanelIndex =
        List.PositionOf(
            List.Transform(
                NormalizedLines,
                each
                    Text.StartsWith(
                        _,
                        "PANEL ID:"
                    )
            ),
            true
        ),

    PanelLine =
        if PanelIndex < 0 then
            null
        else
            NormalizedLines{PanelIndex},

    ReportPanelID =
        if PanelLine = null then
            null
        else
            try
                Text.Trim(
                    Text.BeforeDelimiter(
                        Text.AfterDelimiter(
                            PanelLine,
                            "PANEL ID:"
                        ),
                        "NAME:"
                    )
                )
            otherwise
                null,

    DoctorFromReport =
        if PanelLine = null then
            null
        else
            try
                Text.Trim(
                    Text.AfterDelimiter(
                        PanelLine,
                        "NAME:"
                    )
                )
            otherwise
                null,

    // ============================================================
    // 7. NORMALIZE FOLDER / REPORT METADATA
    // ============================================================
    FolderPanelIDClean =
        if FolderPanelID = null then
            null
        else
            Text.Trim(
                Text.From(FolderPanelID)
            ),

    FolderDoctorClean =
        NormalizeDoctorName(
            FolderDoctor
        ),

    DoctorFromReportClean =
        NormalizeDoctorName(
            DoctorFromReport
        ),

    // ============================================================
    // 8. VALIDATE REPORT AGAINST FOLDER
    //
    // PanelID remains the strongest identifier.
    // Doctor name comparison ignores punctuation differences.
    // ============================================================
    Validation =
        if ReportPanelID = null then
            "MISSING_PANEL_ID"

        else if ReportPanelID <> FolderPanelIDClean then
            "PANEL_FOLDER_MISMATCH"

        else if
            DoctorFromReportClean <> null
            and FolderDoctorClean <> null
            and DoctorFromReportClean <> FolderDoctorClean
        then
            "REPORT_NAME_MISMATCH"

        else
            "OK",

    // ============================================================
    // 9. FIND REAL PATIENT TABLE HEADER
    //
    // Actual line:
    //
    // Conflict Category,Conflict First Reported,Patient ID,...
    // ============================================================
    HeaderIndex =
        List.PositionOf(
            List.Transform(
                NormalizedLines,
                each
                    Text.StartsWith(
                        _,
                        "CONFLICT CATEGORY,"
                    )
            ),
            true
        ),

    CheckedHeaderIndex =
        if HeaderIndex < 0 then
            error
                "Conflict patient-table header not found in "
                & FileName
        else
            HeaderIndex,

    // ============================================================
    // 10. REMOVE AHS PREAMBLE
    // ============================================================
    PatientLines =
        List.Skip(
            Lines,
            CheckedHeaderIndex
        ),

    PatientText =
        Text.Combine(
            PatientLines,
            "#(cr)#(lf)"
        ),

    PatientBinary =
        Text.ToBinary(
            PatientText,
            TextEncoding.Utf8
        ),

    // ============================================================
    // 11. PARSE ONLY THE PATIENT SECTION AS CSV
    // ============================================================
    PatientRaw =
        Csv.Document(
            PatientBinary,
            [
                Delimiter = ",",
                Encoding = 65001,
                QuoteStyle = QuoteStyle.Csv
            ]
        ),

    // ============================================================
    // 12. PROMOTE PATIENT HEADERS
    // ============================================================
    Promoted0 =
        Table.PromoteHeaders(
            PatientRaw,
            [
                PromoteAllScalars = true
            ]
        ),

    // ============================================================
    // 13. CLEAN COLUMN NAMES
    // ============================================================
    Promoted =
        Table.TransformColumnNames(
            Promoted0,
            each
                Text.Trim(
                    Text.Clean(
                        Text.Replace(
                            Text.Replace(
                                _,
                                Character.FromNumber(65279),
                                ""
                            ),
                            Character.FromNumber(160),
                            " "
                        )
                    )
                )
        ),

    // ============================================================
    // 14. ADD REPORT METADATA
    // ============================================================
    AddPanel =
        Table.AddColumn(
            Promoted,
            "PanelID",
            each ReportPanelID,
            type nullable text
        ),

    AddDoctor =
        Table.AddColumn(
            AddPanel,
            "Doctor",
            each FolderDoctor,
            type nullable text
        ),

    AddProduced =
        Table.AddColumn(
            AddDoctor,
            "ProducedDate",
            each ProducedDate,
            type nullable date
        ),

    AddValidation =
        Table.AddColumn(
            AddProduced,
            "DoctorValidation",
            each Validation,
            type text
        ),

    AddFileName =
        Table.AddColumn(
            AddValidation,
            "SourceFileName",
            each FileName,
            type text
        )

in
    AddFileName
