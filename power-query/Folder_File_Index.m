let
    // ============================================================
    // FOLDER FILE INDEX
    //
    // Maps the physical doctor folder discovered by
    // Folder_File_Index_Raw to Doctor_Config.
    //
    // Both sides of the join are normalized so differences in
    // upper/lower case and accidental spaces do not cause UNMAPPED.
    // ============================================================


    // ============================================================
    // 1. SOURCE FILE LIST
    // ============================================================

    Source =
        Folder_File_Index_Raw,


    // ============================================================
    // 2. NORMALIZE DoctorFolder FROM THE FILE SYSTEM
    //
    // Example:
    //
    // Dr._Amy_Leung
    //
    // becomes:
    //
    // DR._AMY_LEUNG
    //
    // We keep the original DoctorFolder column for display.
    // ============================================================

    AddDoctorFolderKey =
        Table.AddColumn(
            Source,
            "DoctorFolderKey",
            each
                if [DoctorFolder] = null then
                    null
                else
                    Text.Upper(
                        Text.Trim(
                            Text.From(
                                [DoctorFolder]
                            )
                        )
                    ),
            type nullable text
        ),


    // ============================================================
    // 3. PREPARE Doctor_Config LOOKUP
    // ============================================================

    DoctorLookup0 =
        Doctor_Config,


    // ============================================================
    // 4. CREATE THE SAME NORMALIZED KEY IN Doctor_Config
    // ============================================================

    DoctorLookup =
        Table.AddColumn(
            DoctorLookup0,
            "DoctorFolderKey",
            each
                if [FolderName] = null then
                    null
                else
                    Text.Upper(
                        Text.Trim(
                            Text.From(
                                [FolderName]
                            )
                        )
                    ),
            type nullable text
        ),


    // ============================================================
    // 5. MERGE WITH Doctor_Config
    //
    // Match normalized key to normalized key.
    // ============================================================

    MergeDoctorConfig =
        Table.NestedJoin(
            AddDoctorFolderKey,
            {
                "DoctorFolderKey"
            },
            DoctorLookup,
            {
                "DoctorFolderKey"
            },
            "DoctorConfig",
            JoinKind.LeftOuter
        ),


    // ============================================================
    // 6. EXPAND DOCTOR INFORMATION
    //
    // Doctor_Config should contain:
    //
    //     Doctor
    //     PanelID
    //
    // ============================================================

    ExpandDoctorConfig =
        Table.ExpandTableColumn(
            MergeDoctorConfig,
            "DoctorConfig",
            {
                "Doctor",
                "PanelID"
            },
            {
                "FolderDoctor",
                "FolderPanelID"
            }
        ),


    // ============================================================
    // 7. DETERMINE MAPPING STATUS
    // ============================================================

    AddFolderStatus =
        Table.AddColumn(
            ExpandDoctorConfig,
            "FolderStatus",
            each
                if [FolderPanelID] = null then
                    "UNMAPPED"
                else
                    "OK",
            type text
        ),


    // ============================================================
    // 8. REMOVE INTERNAL JOIN KEY
    //
    // Users do not need to see DoctorFolderKey downstream.
    // ============================================================

    RemoveDoctorFolderKey =
        Table.RemoveColumns(
            AddFolderStatus,
            {
                "DoctorFolderKey"
            }
        ),


    // ============================================================
    // 9. PUT IMPORTANT COLUMNS FIRST
    // ============================================================

    ImportantColumns =
        {
            "Name",
            "Extension",
            "Folder Path",
            "DoctorFolder",
            "FolderDoctor",
            "FolderPanelID",
            "SourceType",
            "FolderStatus"
        },

    ExistingImportantColumns =
        List.Select(
            ImportantColumns,
            each
                List.Contains(
                    Table.ColumnNames(
                        RemoveDoctorFolderKey
                    ),
                    _
                )
        ),

    OtherColumns =
        List.RemoveItems(
            Table.ColumnNames(
                RemoveDoctorFolderKey
            ),
            ExistingImportantColumns
        ),

    Reorder =
        Table.ReorderColumns(
            RemoveDoctorFolderKey,
            ExistingImportantColumns
                &
            OtherColumns
        )

in
    Reorder
