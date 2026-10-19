let
    Source =
        Folder_File_Index,

    AddFileKey =
        Table.AddColumn(
            Source,
            "FileKey",
            each
                Text.Combine(
                    {
                        if [FolderPanelID] = null
                        then "UNMAPPED"
                        else [FolderPanelID],

                        [SourceType],

                        Text.Upper([Name])
                    },
                    "|"
                ),
            type text
        ),

    Sort =
        Table.Sort(
            AddFileKey,
            {
                {"FileKey", Order.Ascending},
                {"Date modified", Order.Descending}
            }
        ),

    Grouped =
        Table.Group(
            Sort,
            {"FileKey"},
            {
                {
                    "Rows",
                    each
                        let
                            GroupTable = _,
                            CountRows = Table.RowCount(GroupTable),

                            AddRank =
                                Table.AddIndexColumn(
                                    GroupTable,
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
                                )
                        in
                            AddCount
                }
            }
        ),

    Expand =
        Table.ExpandTableColumn(
            Grouped,
            "Rows",
            List.RemoveItems(
                Table.ColumnNames(Sort),
                {"FileKey"}
            )
            &
            {
                "DuplicateRank",
                "DuplicateCount"
            }
        ),

    AddDuplicateStatus =
        Table.AddColumn(
            Expand,
            "DuplicateStatus",
            each
                if [DuplicateCount] = 1 then
                    "UNIQUE"

                else if [DuplicateRank] = 1 then
                    "DUPLICATE_KEPT"

                else
                    "DUPLICATE_SUPPRESSED",
            type text
        )
in
    AddDuplicateStatus
