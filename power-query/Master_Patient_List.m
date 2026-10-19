let
    CPARHistory =
        Table.RenameColumns(
            Table.SelectColumns(
                Standardize_CPAR,
                {
                    "MasterKey",
                    "PanelID",
                    "Doctor",
                    "PatientID",
                    "ReportDate",
                    "LAST_NAME",
                    "FIRST_NAME",
                    "DOB"
                }
            ),
            {
                {"ReportDate", "EventDate"},
                {"LAST_NAME", "LastName"},
                {"FIRST_NAME", "FirstName"}
            }
        ),

    DemoOK =
        Table.SelectRows(
            Standardize_Demographic_Mismatch,
            each [DoctorValidation] = "OK"
        ),

    DemoHistory =
        Table.SelectColumns(
            DemoOK,
            {
                "MasterKey",
                "PanelID",
                "Doctor",
                "PatientID",
                "EventDate",
                "LastName",
                "FirstName",
                "DOB"
            }
        ),

    History =
        Table.Combine(
            {
                CPARHistory,
                DemoHistory
            }
        ),

    FirstSeen =
        Table.Group(
            History,
            {
                "MasterKey",
                "PanelID",
                "Doctor",
                "PatientID"
            },
            {
                {
                    "FirstSeenDate",
                    each
                        try
                            List.Min(
                                List.RemoveNulls([EventDate])
                            )
                        otherwise
                            null,
                    type nullable date
                },
                {
                    "LastName",
                    each
                        try List.First(List.RemoveNulls([LastName]))
                        otherwise null,
                    type nullable text
                },
                {
                    "FirstName",
                    each
                        try List.First(List.RemoveNulls([FirstName]))
                        otherwise null,
                    type nullable text
                },
                {
                    "DOB",
                    each
                        try List.First(List.RemoveNulls([DOB]))
                        otherwise null,
                    type nullable date
                }
            }
        ),

    Keys =
        Table.Distinct(
            Table.Combine(
                {
                    Table.SelectColumns(
                        FirstSeen,
                        {"MasterKey"}
                    ),
                    Table.SelectColumns(
                        Master_Overrides,
                        {"MasterKey"}
                    )
                }
            )
        ),

    JoinSeen =
        Table.NestedJoin(
            Keys,
            {"MasterKey"},
            FirstSeen,
            {"MasterKey"},
            "Seen",
            JoinKind.LeftOuter
        ),

    ExpandSeen =
        Table.ExpandTableColumn(
            JoinSeen,
            "Seen",
            {
                "PanelID",
                "Doctor",
                "PatientID",
                "FirstSeenDate",
                "LastName",
                "FirstName",
                "DOB"
            },
            {
                "PanelID",
                "Doctor",
                "PatientID",
                "FirstSeenDate",
                "LastName",
                "FirstName",
                "DOB"
            }
        ),

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

    FillPanel =
        Table.AddColumn(
            ExpandOverride,
            "PanelID_Final",
            each
                if [PanelID] <> null
                then [PanelID]
                else [OverridePanelID],
            type text
        ),

    FillPatient =
        Table.AddColumn(
            FillPanel,
            "PatientID_Final",
            each
                if [PatientID] <> null
                then [PatientID]
                else [OverridePatientID],
            type text
        ),

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
                        if Table.RowCount(Match) = 0
                        then null
                        else Match{0}[Doctor],
            type nullable text
        ),

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
                "LastName",
                "FirstName",
                "DOB",
                "Source"
            }
        ),

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
