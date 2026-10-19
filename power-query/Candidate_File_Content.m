let
    // ============================================================
    // CANDIDATE_FILE_CONTENT
    //
    // Purpose:
    // Attach the binary [Content] column to ONLY the rows already
    // selected by Candidate_File_Index.
    //
    // This query does NOT call Folder.Files() or File.Contents().
    // It only references existing Power Query queries, which avoids
    // the Formula.Firewall pattern in Parsed_File_Cache.
    // ============================================================

    Candidates0 =
        Candidate_File_Index,

    // Remove Content if a previous version already carried it.
    // We will attach the authoritative Content from
    // Folder_File_Index_Raw below.
    Candidates =
        Table.RemoveColumns(
            Candidates0,
            {"Content"},
            MissingField.Ignore
        ),

    RawFiles0 =
        Folder_File_Index_Raw,

    RawFiles =
        Table.SelectColumns(
            RawFiles0,
            {
                "Folder Path",
                "Name",
                "Content"
            },
            MissingField.UseNull
        ),

    // Match each candidate to the original Folder.Files row.
    MergeRawFile =
        Table.NestedJoin(
            Candidates,
            {
                "Folder Path",
                "Name"
            },
            RawFiles,
            {
                "Folder Path",
                "Name"
            },
            "RawFile",
            JoinKind.LeftOuter
        ),

    AddContent =
        Table.ExpandTableColumn(
            MergeRawFile,
            "RawFile",
            {"Content"},
            {"Content"}
        )

in
    AddContent
