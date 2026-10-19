let
    Source = Folder_File_Index,

    Keep =
        Table.SelectRows(
            Source,
            each
                [SourceType] = "CONFLICT"
                and [FolderStatus] = "OK"
        )
in
    Keep
