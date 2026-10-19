let
    // ============================================================
    // FOLDER_FILE_INDEX_RAW
    //
    // Required doctor-folder structure:
    //
    // DoctorFolder
    //   ├── CPAR
    //   ├── CONFLICTS
    //   └── REGISTRY
    //
    // OR
    //
    // DoctorFolder
    //   ├── CPAR
    //   ├── CONFLICTS
    //   └── DEMOGRAPHIC_MISMATCH
    //
    // REGISTRY and DEMOGRAPHIC_MISMATCH both become:
    //
    // SourceType = DEMOGRAPHIC_MISMATCH
    //
    // Folder.Files() is NOT used because it recursively scans
    // the entire tree and was causing very long refreshes.
    // ============================================================


    // ============================================================
    // 1. GET ROOT FOLDER
    // ============================================================

    FolderConfig =
        Excel.CurrentWorkbook(){[Name="tblFolderConfig"]}[Content],

    RootMatch =
        Table.SelectRows(
            FolderConfig,
            each
                Text.Upper(
                    Text.Trim(
                        Text.From([Setting])
                    )
                ) = "AHS_ROOT_FOLDER"
        ),

    Root0 =
        if Table.RowCount(RootMatch) = 0 then
            error "Missing AHS_Root_Folder in tblFolderConfig"
        else
            Text.Trim(
                Text.From(
                    RootMatch{0}[Value]
                )
            ),

    NormalizedRoot =
        Text.Replace(
            Root0,
            "/",
            "\"
        ),

    Root =
        if Text.EndsWith(
            NormalizedRoot,
            "\"
        )
        then
            NormalizedRoot
        else
            NormalizedRoot & "\",


    // ============================================================
    // 2. HELPER FUNCTIONS
    // ============================================================

    EmptyFolder =
        #table(
            {
                "Content",
                "Name",
                "Extension",
                "Date accessed",
                "Date modified",
                "Date created",
                "Attributes",
                "Folder Path"
            },
            {}
        ),

    ReadFolder =
        (FolderPath as text) as table =>
        let
            Attempt =
                try
                    Folder.Contents(
                        FolderPath
                    )
        in
            if Attempt[HasError] then
                EmptyFolder
            else
                Attempt[Value],

    IsDirectory =
        (AttributeValue as any) as logical =>
        try
            AttributeValue[Directory] = true
        otherwise
            false,

    IsSupportedFile =
        (ExtensionValue as any) as logical =>
        let
            E =
                if ExtensionValue = null then
                    ""
                else
                    Text.Lower(
                        Text.Trim(
                            Text.From(
                                ExtensionValue
                            )
                        )
                    )
        in
            List.Contains(
                {
                    ".csv",
                    ".xlsx",
                    ".xls"
                },
                E
            ),


    // ============================================================
    // 3. GET TOP-LEVEL DOCTOR FOLDERS
    // ============================================================

    RootContents =
        ReadFolder(
            Root
        ),

    RootFolders =
        Table.SelectRows(
            RootContents,
            each
                IsDirectory(
                    [Attributes]
                )
        ),

    DoctorFolders0 =
        Table.SelectColumns(
            RootFolders,
            {
                "Name"
            }
        ),

    DoctorFolders =
        Table.RenameColumns(
            DoctorFolders0,
            {
                {
                    "Name",
                    "DoctorFolder"
                }
            }
        ),


    // ============================================================
    // 4. FUNCTION TO READ ONE REPORT FOLDER
    // ============================================================

    GetFilesFromReportFolder =
        (
            DoctorPath as text,
            ReportFolder as text,
            LogicalSourceType as text
        ) as table =>
        let
            Path =
                DoctorPath
                & ReportFolder
                & "\",

            Contents =
                ReadFolder(
                    Path
                ),

            FilesOnly =
                Table.SelectRows(
                    Contents,
                    each
                        not
                            IsDirectory(
                                [Attributes]
                            )
                        and
                            IsSupportedFile(
                                [Extension]
                            )
                ),

            AddReportFolder =
                Table.AddColumn(
                    FilesOnly,
                    "ReportFolder",
                    each ReportFolder,
                    type text
                ),

            AddSourceType =
                Table.AddColumn(
                    AddReportFolder,
                    "SourceType",
                    each LogicalSourceType,
                    type text
                )
        in
            AddSourceType,


    // ============================================================
    // 5. GET FILES FOR ONE DOCTOR
    // ============================================================

    GetDoctorFiles =
        (DoctorFolderName as text) as table =>
        let
            DoctorPath =
                Root
                & Text.Trim(
                    DoctorFolderName
                )
                & "\",


            // ----------------------------------------------------
            // Read the doctor's immediate folders.
            // ----------------------------------------------------

            DoctorContents =
                ReadFolder(
                    DoctorPath
                ),

            ChildFolders =
                Table.SelectRows(
                    DoctorContents,
                    each
                        IsDirectory(
                            [Attributes]
                        )
                ),

            ChildFolderNames =
                List.Transform(
                    ChildFolders[Name],
                    each
                        Text.Upper(
                            Text.Trim(
                                Text.From(_)
                            )
                        )
                ),


            // ----------------------------------------------------
            // Required demographic folder:
            //
            // REGISTRY
            //       OR
            // DEMOGRAPHIC_MISMATCH
            // ----------------------------------------------------

            HasRegistry =
                List.Contains(
                    ChildFolderNames,
                    "REGISTRY"
                ),

            HasDemographicMismatch =
                List.Contains(
                    ChildFolderNames,
                    "DEMOGRAPHIC_MISMATCH"
                ),

            HasRequiredDemographicFolder =
                HasRegistry
                or
                HasDemographicMismatch,


            // ----------------------------------------------------
            // CPAR
            // ----------------------------------------------------

            CPARFiles =
                GetFilesFromReportFolder(
                    DoctorPath,
                    "CPAR",
                    "CPAR"
                ),


            // ----------------------------------------------------
            // CONFLICTS
            // ----------------------------------------------------

            ConflictFiles =
                GetFilesFromReportFolder(
                    DoctorPath,
                    "CONFLICTS",
                    "CONFLICT"
                ),


            // ----------------------------------------------------
            // REGISTRY
            //
            // Only read it when it actually exists.
            // ----------------------------------------------------

            RegistryFiles =
                if HasRegistry then
                    GetFilesFromReportFolder(
                        DoctorPath,
                        "REGISTRY",
                        "DEMOGRAPHIC_MISMATCH"
                    )
                else
                    #table(
                        {
                            "Content",
                            "Name",
                            "Extension",
                            "Date accessed",
                            "Date modified",
                            "Date created",
                            "Attributes",
                            "Folder Path",
                            "ReportFolder",
                            "SourceType"
                        },
                        {}
                    ),


            // ----------------------------------------------------
            // DEMOGRAPHIC_MISMATCH
            //
            // Only read it when it actually exists.
            // ----------------------------------------------------

            DemographicFiles =
                if HasDemographicMismatch then
                    GetFilesFromReportFolder(
                        DoctorPath,
                        "DEMOGRAPHIC_MISMATCH",
                        "DEMOGRAPHIC_MISMATCH"
                    )
                else
                    #table(
                        {
                            "Content",
                            "Name",
                            "Extension",
                            "Date accessed",
                            "Date modified",
                            "Date created",
                            "Attributes",
                            "Folder Path",
                            "ReportFolder",
                            "SourceType"
                        },
                        {}
                    ),


            // ----------------------------------------------------
            // Combine files.
            //
            // If neither demographic folder exists, return no
            // demographic files. Folder validation is added below.
            // ----------------------------------------------------

            Combined =
                Table.Combine(
                    {
                        CPARFiles,
                        ConflictFiles,
                        RegistryFiles,
                        DemographicFiles
                    }
                ),

            AddDemographicFolderStatus =
                Table.AddColumn(
                    Combined,
                    "DemographicFolderStatus",
                    each
                        if HasRequiredDemographicFolder then
                            "OK"
                        else
                            "MISSING_REGISTRY_OR_DEMOGRAPHIC_MISMATCH",
                    type text
                )

        in
            AddDemographicFolderStatus,


    // ============================================================
    // 6. RUN FOR EVERY POTENTIAL DOCTOR FOLDER
    // ============================================================

    AddFiles =
        Table.AddColumn(
            DoctorFolders,
            "Files",
            each
                GetDoctorFiles(
                    Text.From(
                        [DoctorFolder]
                    )
                )
        ),


    // ============================================================
    // 7. EXPAND
    // ============================================================

    ExpandFiles =
        Table.ExpandTableColumn(
            AddFiles,
            "Files",
            {
                "Content",
                "Name",
                "Extension",
                "Date accessed",
                "Date modified",
                "Date created",
                "Attributes",
                "Folder Path",
                "ReportFolder",
                "SourceType",
                "DemographicFolderStatus"
            },
            {
                "Content",
                "Name",
                "Extension",
                "Date accessed",
                "Date modified",
                "Date created",
                "Attributes",
                "Folder Path",
                "ReportFolder",
                "SourceType",
                "DemographicFolderStatus"
            }
        ),


    // ============================================================
    // 8. REMOVE EMPTY / NULL FILE RECORDS
    // ============================================================

    KeepValidFileNames =
        Table.SelectRows(
            ExpandFiles,
            each
                [Name] <> null
                and
                Text.Trim(
                    Text.From([Name])
                ) <> ""
        ),


    // ============================================================
    // 9. FINAL COLUMN ORDER
    // ============================================================

    Reorder =
        Table.ReorderColumns(
            KeepValidFileNames,
            {
                "Name",
                "Extension",
                "Folder Path",
                "DoctorFolder",
                "ReportFolder",
                "SourceType",
                "DemographicFolderStatus",
                "Date modified",
                "Date created",
                "Date accessed",
                "Attributes",
                "Content"
            },
            MissingField.Ignore
        )

in
    Reorder
