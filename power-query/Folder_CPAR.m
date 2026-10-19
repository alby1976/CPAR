let
    Source = Folder_File_Index,

    Keep =
        Table.SelectRows(
            Source,
            each
                [SourceType] = "CPAR"
                and [FolderStatus] = "OK"
        )
in
    Keep
