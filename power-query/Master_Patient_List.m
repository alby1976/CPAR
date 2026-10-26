let
    // ============================================================
    // 1. CPAR HISTORY
    // ============================================================
    CPARHistory =
        Table.AddColumn(
            Table.RenameColumns(
                Table.SelectColumns(
                    Standardize_CPAR,
                    {
                        "MasterKey",
                        "PanelID",
                        "Doctor",
                        "PatientID",
                        "ReportDate",
                        "LastName",
                        "FirstName",
                        "DOB",
                        "UNABLE_TO_SEND_REASON"
                    },
                    MissingField.UseNull
                ),
                {{"ReportDate", "EventDate"}}
            ),
            "SourcePriority",
            each 1,
            Int64.Type
        ),

    // ============================================================
    // 2. DEMOGRAPHIC MISMATCH HISTORY
    // ============================================================
    DemoOK =
        Table.SelectRows(
            Standardize_Demographic_Mismatch,
            each [DoctorValidation] = "OK"
        ),

    DemoHistory =
        Table.AddColumn(
            Table.SelectColumns(
                DemoOK,
                {
                    "MasterKey",
                    "PanelID",
                    "Doctor",
                    "PatientID",
                    "Alberta Registry Patient Id",
                    "EventDate",
                    "LastName",
                    "Alberta Registry Patient Last Name",
                    "FirstName",
                    "Alberta Registry Patient First Name",
                    "Panel Gender",
                    "Alberta Registry Gender",
                    "DOB",
                    "Alberta Registry Date Of Birth",
                    "Date Of Death"
                },
                MissingField.UseNull
            ),
            "SourcePriority",
            each 2,
            Int64.Type
        ),

    // ============================================================
    // 3. COMBINE HISTORY
    // ============================================================
    History =
        Table.Combine(
            {
                CPARHistory,
                DemoHistory
            }
        ),

    // ============================================================
    // 4. DECLARE COLUMNS TO PRESERVE
    // ============================================================
    DetailColumns =
        {
            "PanelID",
            "Doctor",
            "PatientID",
            "EventDate",
            "LastName",
            "FirstName",
            "DOB",
            "UNABLE_TO_SEND_REASON",
            "Alberta Registry Patient Id",
            "Alberta Registry Patient Last Name",
            "Alberta Registry Patient First Name",
            "Panel Gender",
            "Alberta Registry Gender",
            "Alberta Registry Date Of Birth",
            "Date Of Death"
        },

    // ============================================================
    // 5. FIND OLDEST RECORD FOR EACH MASTERKEY
    // ============================================================
    FirstSeen =
        Table.Group(
            History,
            {"MasterKey"},
            {
                {
                    "OldestRecord",
                    (groupTable as table) as record =>
                        let
                            DatedRecords =
                                Table.SelectRows(
                                    groupTable,
                                    each [EventDate] <> null
                                ),

                            Candidates =
                                if Table.IsEmpty(DatedRecords)
                                then groupTable
                                else DatedRecords,

                            Sorted =
                                Table.Sort(
                                    Candidates,
                                    {
                                        {"EventDate", Order.Ascending},
                                        {"SourcePriority", Order.Ascending}
                                    }
                                ),

                            Oldest =
                                Sorted{0},

                            SelectedDetails =
                                Record.SelectFields(
                                    Oldest,
                                    DetailColumns,
                                    MissingField.UseNull
                                ),

                            FirstSeenDate =
                                try Date.From(Oldest[EventDate])
                                otherwise null,

                            Result =
                                Record.AddField(
                                    SelectedDetails,
                                    "FirstSeenDate",
                                    FirstSeenDate
                                )
                        in
                            Result,
                    type record
                }
            }
        ),

    // ============================================================
    // 6. EXPAND OLDEST RECORD
    // ============================================================
    ExpandFirstSeen =
        Table.ExpandRecordColumn(
            FirstSeen,
            "OldestRecord",
            DetailColumns & {"FirstSeenDate"},
            DetailColumns & {"FirstSeenDate"}
        ),

    // ============================================================
    // 7. COLLECT MASTER KEYS
    // ============================================================
    Keys =
        Table.Distinct(
            Table.Combine(
                {
                    Table.SelectColumns(
                        ExpandFirstSeen,
                        {"MasterKey"}
                    ),
                    Table.SelectColumns(
                        Master_Overrides,
                        {"MasterKey"}
                    )
                }
            )
        ),

    // ============================================================
    // 8. JOIN OLDEST RECORDS
    // ============================================================
    JoinSeen =
        Table.NestedJoin(
            Keys,
            {"MasterKey"},
            ExpandFirstSeen,
            {"MasterKey"},
            "Seen",
            JoinKind.LeftOuter
        ),

    ExpandSeen =
        Table.ExpandTableColumn(
            JoinSeen,
            "Seen",
            DetailColumns & {"FirstSeenDate"},
            DetailColumns & {"FirstSeenDate"}
        ),

    // ============================================================
    // 9. JOIN MASTER OVERRIDES
    // ============================================================
    JoinOverride =
        Table.NestedJoin(
            ExpandSeen,
            {"MasterKey"},
            Master_Overrides,
            {"MasterKey"},
            "Override",
            JoinKind.LeftOuter
        ),

    ExpandOverride =
        Table.ExpandTableColumn(
            JoinOverride,
            "Override",
            {
                "PanelID",
                "PatientID",
                "OverrideMasterEntryDate",
                "Reason",
                "Notes"
            },
            {
                "OverridePanelID",
                "OverridePatientID",
                "OverrideMasterEntryDate",
                "OverrideReason",
                "OverrideNotes"
            }
        ),

    // ============================================================
    // 10. FILL MISSING PANEL ID
    // ============================================================
    FillPanel =
        Table.AddColumn(
            ExpandOverride,
            "PanelID_Final",
            each
                if [PanelID] <> null
                then [PanelID]
                else [OverridePanelID],
            type nullable text
        ),

    // ============================================================
    // 11. FILL MISSING PATIENT ID
    // ============================================================
    FillPatient =
        Table.AddColumn(
            FillPanel,
            "PatientID_Final",
            each
                if [PatientID] <> null
                then [PatientID]
                else [OverridePatientID],
            type nullable text
        ),

    // ============================================================
    // 12. DOCTOR LOOKUP
    // ============================================================
    DoctorLookup =
        Table.AddColumn(
            FillPatient,
            "Doctor_Final",
            each
                if [Doctor] <> null then
                    [Doctor]
                else
                    let
                        CurrentPanel = [PanelID_Final],

                        Match =
                            Table.SelectRows(
                                Doctor_Config,
                                (d) =>
                                    d[PanelID] = CurrentPanel
                            )
                    in
                        if Table.IsEmpty(Match)
                        then null
                        else Match{0}[Doctor],
            type nullable text
        ),

    // ============================================================
    // 13. EFFECTIVE MASTER ENTRY DATE
    // ============================================================
    Effective =
        Table.AddColumn(
            DoctorLookup,
            "EffectiveMasterEntryDate",
            each
                if [OverrideMasterEntryDate] <> null
                then [OverrideMasterEntryDate]
                else [FirstSeenDate],
            type nullable date
        ),

    // ============================================================
    // 14. IDENTIFY SOURCE
    // ============================================================
    AddSource =
        Table.AddColumn(
            Effective,
            "Source",
            each
                if [OverrideMasterEntryDate] <> null
                then "OVERRIDE"
                else "AUTOMATIC_FIRST_SEEN",
            type text
        ),

    // ============================================================
    // 15. SELECT FINAL OUTPUT COLUMNS
    // ============================================================
    Select =
        Table.SelectColumns(
            AddSource,
            {
                "MasterKey",
                "PanelID_Final",
                "Doctor_Final",
                "PatientID_Final",

                "FirstSeenDate",
                "OverrideMasterEntryDate",
                "EffectiveMasterEntryDate",

                "EventDate",
                "LastName",
                "FirstName",
                "DOB",

                "UNABLE_TO_SEND_REASON",

                "Alberta Registry Patient Id",
                "Alberta Registry Patient Last Name",
                "Alberta Registry Patient First Name",
                "Panel Gender",
                "Alberta Registry Gender",
                "Alberta Registry Date Of Birth",
                "Date Of Death",

                "Source"
            },
            MissingField.UseNull
        ),

    // ============================================================
    // 16. RENAME FINAL OUTPUT COLUMNS
    // ============================================================
    Rename =
        Table.RenameColumns(
            Select,
            {
                {"PanelID_Final", "PanelID"},
                {"Doctor_Final", "Doctor"},
                {"PatientID_Final", "PatientID"}
            }
        )

in
    Rename