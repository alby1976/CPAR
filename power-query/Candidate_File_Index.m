let
    // ============================================================
    // CANDIDATE FILE INDEX - METADATA ONLY
    //
    // IMPORTANT:
    // This query deliberately DOES NOT carry the Content binary.
    //
    // It identifies which files might matter using only:
    //     filename
    //     folder
    //     doctor/panel
    //     source type
    //     modified date
    //
    // The actual CSV contents will only be retrieved AFTER
    // candidate selection.
    // ============================================================

    KeepCount = 4,

    // ============================================================
    // 1. START WITH FOLDER FILE INDEX
    // ============================================================

    Source =
        Folder_File_Index,

    // ============================================================
    // 2. REMOVE THE EXPENSIVE BINARY CONTENT IMMEDIATELY
    //
    // Do NOT include:
    //
    //     Content
    //     Attributes
    //
    // in the candidate-selection work.
    // ============================================================

    MetadataOnly =
        Table.SelectColumns(
            Source,
            {
                "Name",
                "Extension",
                "Folder Path",
                "DoctorFolder",
                "FolderDoctor",
                "FolderPanelID",
                "SourceType",
                "FolderStatus",
                "Date accessed",
                "Date modified",
                "Date created"
            },
            MissingField.UseNull
        ),

    // ============================================================
    // 3. KEEP ONLY VALID REPORT-FOLDER TYPES
    // ============================================================

    Eligible =
        Table.SelectRows(
            MetadataOnly,
            each
                [FolderStatus] = "OK"
                and
                List.Contains(
                    {
                        "CPAR",
                        "CONFLICT",
                        "DEMOGRAPHIC_MISMATCH"
                    },
                    [SourceType]
                )
        ),

    // ============================================================
    // 4. CREATE THE SAME FILE KEY USED BY File_Inventory
    //
    // A duplicate means:
    //
    // Panel + report type + filename
    // ============================================================

    AddFileKey =
        Table.AddColumn(
            Eligible,
            "FileKey",
            each
                Text.Combine(
                    {
                        if [FolderPanelID] = null
                        then "UNMAPPED"
                        else Text.From([FolderPanelID]),

                        [SourceType],

                        Text.Upper([Name])
                    },
                    "|"
                ),
            type text
        ),

    // ============================================================
    // 5. IDENTIFY DUPLICATES USING METADATA ONLY
    // ============================================================

    GroupDuplicates =
        Table.Group(
            AddFileKey,
            {"FileKey"},
            {
                {
                    "Rows",
                    each
                        let
                            Sorted =
                                Table.Sort(
                                    _,
                                    {
                                        {
                                            "Date modified",
                                            Order.Descending
                                        },
                                        {
                                            "Folder Path",
                                            Order.Ascending
                                        }
                                    }
                                ),

                            CountRows =
                                Table.RowCount(Sorted),

                            AddRank =
                                Table.AddIndexColumn(
                                    Sorted,
                                    "DuplicateRank",
                                    1,
                                    1,
                                    Int64.Type
                                ),

                            AddCount =
                                Table.AddColumn(
                                    AddRank,
                                    "DuplicateCount",
                                    each CountRows,
                                    Int64.Type
                                ),

                            AddStatus =
                                Table.AddColumn(
                                    AddCount,
                                    "DuplicateStatus",
                                    each
                                        if CountRows = 1 then
                                            "UNIQUE"

                                        else if [DuplicateRank] = 1 then
                                            "DUPLICATE_KEPT"

                                        else
                                            "DUPLICATE_SUPPRESSED",
                                    type text
                                )
                        in
                            AddStatus
                }
            }
        ),

    DuplicateColumns =
        List.RemoveItems(
            Table.ColumnNames(AddFileKey),
            {"FileKey"}
        )
        &
        {
            "DuplicateRank",
            "DuplicateCount",
            "DuplicateStatus"
        },

    ExpandDuplicates =
        Table.ExpandTableColumn(
            GroupDuplicates,
            "Rows",
            DuplicateColumns,
            DuplicateColumns
        ),

    // ============================================================
    // 6. REMOVE SUPPRESSED DUPLICATES BEFORE CANDIDATE SELECTION
    // ============================================================

    KeepNonSuppressed =
        Table.SelectRows(
            ExpandDuplicates,
            each
                [DuplicateStatus]
                    <> "DUPLICATE_SUPPRESSED"
        ),

    // ============================================================
    // 7. GROUP BY PANEL + REPORT TYPE
    //
    // Keep newest 4 metadata records.
    //
    // NO CSV HAS BEEN PARSED YET.
    // ============================================================

    GroupCandidates =
        Table.Group(
            KeepNonSuppressed,
            {
                "FolderPanelID",
                "SourceType"
            },
            {
                {
                    "Candidates",
                    each
                        let
                            Sorted =
                                Table.Sort(
                                    _,
                                    {
                                        {
                                            "Date modified",
                                            Order.Descending
                                        },
                                        {
                                            "Name",
                                            Order.Ascending
                                        }
                                    }
                                ),

                            TopFiles =
                                Table.FirstN(
                                    Sorted,
                                    KeepCount
                                ),

                            AddCandidateRank =
                                Table.AddIndexColumn(
                                    TopFiles,
                                    "CandidateRank",
                                    1,
                                    1,
                                    Int64.Type
                                )
                        in
                            AddCandidateRank
                }
            }
        ),

    CandidateColumns =
        List.RemoveItems(
            Table.ColumnNames(KeepNonSuppressed),
            {
                "FolderPanelID",
                "SourceType"
            }
        )
        &
        {
            "CandidateRank"
        },

    ExpandCandidates =
        Table.ExpandTableColumn(
            GroupCandidates,
            "Candidates",
            CandidateColumns,
            CandidateColumns
        ),

    // ============================================================
    // 8. SORT FOR HUMAN REVIEW
    // ============================================================

    SortedResult =
        Table.Sort(
            ExpandCandidates,
            {
                {
                    "FolderPanelID",
                    Order.Ascending
                },
                {
                    "SourceType",
                    Order.Ascending
                },
                {
                    "CandidateRank",
                    Order.Ascending
                }
            }
        )

in
    SortedResult
