let
    Source = Folder_File_Index,

    Unmapped =
        Table.SelectRows(
            Source,
            each [FolderStatus] <> "OK"
        )
in
    Unmapped
