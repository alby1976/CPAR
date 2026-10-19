let
    // ============================================================
    // 1. REUSE THE PARSED TABLES FROM Parsed_File_Cache
    //
    // DoctorValidation is NOT filtered here.  Metadata_Mismatches
    // needs mismatched reports to remain visible for auditing.
    // ============================================================
    ValidFiles =
        Table.SelectRows(
            Parsed_File_Cache,
            each
                [SourceType] = "CONFLICT"
                and [FolderStatus] = "OK"
                and [ImportStatus] = "OK"
                and [SchemaStatus] = "OK"
                and [DuplicateStatus] <> "DUPLICATE_SUPPRESSED"
        ),

    Tables =
        List.Select(
            Table.Column(ValidFiles, "ParsedTable"),
            each Value.Is(_, type table)
        ),

    Empty =
        #table(
            type table [
                #"Conflict Category" = nullable text,
                #"Conflict First Reported" = nullable any,
                #"Patient ID" = nullable text,
                #"Last Name" = nullable text,
                #"First Name" = nullable text,
                #"Date of Birth" = nullable any,
                Gender = nullable text,
                #"Last Confirmation Date" = nullable any,
                #"Date of Last Visit" = nullable any,
                #"Conflicting Provider" = nullable text,
                #"Conflicting Provider Role/Expertise" = nullable text,
                #"Conflicting Provider Facility" = nullable text,
                #"Last Confirmation Date for Conflicting Provider" = nullable any,
                #"Date of Last Visit for Conflicting Provider" = nullable any,
                #"Conflicting Panel Status" = nullable text,
                PanelID = nullable text,
                Doctor = nullable text,
                ProducedDate = nullable date,
                DoctorValidation = nullable text,
                SourceFileName = nullable text
            ],
            {}
        ),

    // ============================================================
    // 3. COMBINE ALL PARSED CONFLICT REPORTS
    // ============================================================
    Combined =
        if List.Count(Tables) = 0 then
            Empty
        else
            Table.Combine(Tables),

    // ============================================================
    // 4. KEEP REAL PATIENT RECORDS
    //
    // IMPORTANT:
    // We require Patient ID.
    //
    // We DO NOT require Conflict First Reported because AHS may
    // legitimately leave that field blank.
    // ============================================================
    KeepPatients =
        Table.SelectRows(
            Combined,
            each
                [#"Patient ID"] <> null
                and
                Text.Trim(
                    Text.From([#"Patient ID"])
                ) <> ""
        ),

    // ============================================================
    // 5. CLEAN TEXT FIELDS
    // ============================================================
    CleanText =
        Table.TransformColumns(
            KeepPatients,
            {
                {
                    "Patient ID",
                    each
                        if _ = null then
                            null
                        else
                            Text.Trim(Text.From(_)),
                    type nullable text
                },

                {
                    "Last Name",
                    each
                        if _ = null then
                            null
                        else
                            Text.Upper(
                                Text.Trim(Text.From(_))
                            ),
                    type nullable text
                },

                {
                    "First Name",
                    each
                        if _ = null then
                            null
                        else
                            Text.Upper(
                                Text.Trim(Text.From(_))
                            ),
                    type nullable text
                },

                {
                    "Conflict Category",
                    each
                        if _ = null then
                            null
                        else
                            Text.Trim(Text.From(_)),
                    type nullable text
                },

                {
                    "Gender",
                    each
                        if _ = null then
                            null
                        else
                            Text.Trim(Text.From(_)),
                    type nullable text
                }
            },
            null,
            MissingField.Ignore
        ),

    // ============================================================
    // 6. HELPER FUNCTION FOR SAFE DATE CONVERSION
    //
    // Blank or malformed dates become null instead of causing
    // the whole Power Query refresh to fail.
    // ============================================================
    ToNullableDate =
        (Value as any) as nullable date =>
            if Value = null then
                null

            else if Text.Trim(Text.From(Value)) = "" then
                null

            else
                try
                    Date.From(Value)
                otherwise
                    try
                        Date.FromText(
                            Text.Trim(Text.From(Value)),
                            [Culture = "en-CA"]
                        )
                    otherwise
                        null,

    // ============================================================
    // 7. CLEAN CONFLICT FIRST REPORTED
    // ============================================================
    CleanConflictDate =
        Table.TransformColumns(
            CleanText,
            {
                {
                    "Conflict First Reported",
                    each ToNullableDate(_),
                    type nullable date
                }
            },
            null,
            MissingField.Ignore
        ),

    // ============================================================
    // 8. CLEAN DATE OF BIRTH
    // ============================================================
    CleanDOB =
        Table.TransformColumns(
            CleanConflictDate,
            {
                {
                    "Date of Birth",
                    each ToNullableDate(_),
                    type nullable date
                }
            },
            null,
            MissingField.Ignore
        ),

    // ============================================================
    // 9. CLEAN OTHER AHS DATE FIELDS
    // ============================================================
    CleanOtherDates =
        Table.TransformColumns(
            CleanDOB,
            {
                {
                    "Last Confirmation Date",
                    each ToNullableDate(_),
                    type nullable date
                },

                {
                    "Date of Last Visit",
                    each ToNullableDate(_),
                    type nullable date
                },

                {
                    "Last Confirmation Date for Conflicting Provider",
                    each ToNullableDate(_),
                    type nullable date
                },

                {
                    "Date of Last Visit for Conflicting Provider",
                    each ToNullableDate(_),
                    type nullable date
                }
            },
            null,
            MissingField.Ignore
        ),

    // ============================================================
    // 10. MAKE SURE PANEL ID / DOCTOR ARE TEXT
    // ============================================================
    CleanMetadata =
        Table.TransformColumns(
            CleanOtherDates,
            {
                {
                    "PanelID",
                    each
                        if _ = null then
                            null
                        else
                            Text.Trim(Text.From(_)),
                    type nullable text
                },

                {
                    "Doctor",
                    each
                        if _ = null then
                            null
                        else
                            Text.Upper(
                                Text.Trim(Text.From(_))
                            ),
                    type nullable text
                }
            },
            null,
            MissingField.Ignore
        ),

    // ============================================================
    // 11. PRESERVE ORIGINAL PHN FOR AUDIT
    // ============================================================
    AddOriginalPHN =
        Table.DuplicateColumn(
            CleanMetadata,
            "Patient ID",
            "OriginalPHN"
        ),

    //

    // ============================================================
    // 11a. Normalize OriginalPHN
    // ============================================================
	#"Normalize OriginalPHN" =
		Table.ReplaceValue(
			#"AddOriginalPHN",
			"Alberta ULI",
			"AB",
			Replacer.ReplaceText,
			{"OriginalPHN"}
		),

    // ===========================================================
    // 12. CLEAN PHN
    // ===========================================================
    Clean =
        Table.TransformColumns(
            #"Normalize OriginalPHN",
            {
                {
					"Patient ID",
					each
						if _ = null then null
						else
							let
								id = Text.Trim(Text.From(_)),
								parts = Text.Split(id, " "),
								number = parts{0},
								suffix = Text.Combine(List.Skip(parts, 1), " "),
								formatted =
									if Text.Length(number) = 9
										and Text.Select(number, {"0".."9"}) = number
									then Text.Start(number, 5) & "-" & Text.End(number, 4)
									else number
							in
								formatted & "",
								//(if suffix = "" then "" else " " & suffix),
					type text
				}
			}
        ),

    // ============================================================
    // 13. VALIDATE CLEANED PHN
    // ============================================================
    AddPHNValidation =
        Table.AddColumn(
            Clean,
            "PHNValidation",
            each
                if [#"Patient ID"] = null or [#"Patient ID"] = "" then
                    "MISSING_PHN"
                else if Text.Length([#"Patient ID"]) <> 10 then
                    "INVALID_PHN_LENGTH"
                else
                    "OK",
            type text
        ),

    // ============================================================
    // 14. CREATE PATIENT ID
    // ============================================================
    AddPatientID =
        Table.AddColumn(
            AddPHNValidation,
            "PatientID",
            each
                if [PHNValidation] = "OK"
                then [#"Patient ID"]
                else null,
            type nullable text
        ),

    // ============================================================
    // 15. CREATE MASTER KEY
    // ============================================================
    AddMasterKey =
        Table.AddColumn(AddPatientID, "MasterKey", each if [PanelID] = null
                    or [OriginalPHN] = null
                then null
                else Text.Trim([PanelID])
                    & "|"
                    & [OriginalPHN],
            type nullable text
        ),

    // ============================================================
    // 16. IDENTIFY SOURCE
    // ============================================================
    AddSource =
        Table.AddColumn(
            AddMasterKey,
            "Source",
            each "CONFLICT",
            type text
        ),

    // ============================================================
    // 17. STANDARDIZE COMMON COLUMN NAMES
    //
    // Conflict First Reported -> EventDate
    // Last Name               -> LastName
    // First Name              -> FirstName
    // Date of Birth           -> DOB
    // ============================================================
    Rename =
        Table.RenameColumns(
            AddSource,
            {
                {
                    "Conflict First Reported",
                    "EventDate"
                },

                {
                    "Last Name",
                    "LastName"
                },

                {
                    "First Name",
                    "FirstName"
                },

                {
                    "Date of Birth",
                    "DOB"
                }
            },
            MissingField.Ignore
        ),

    // ============================================================
    // 18. PUT THE MOST IMPORTANT COLUMNS FIRST
    //
    // We deliberately retain the detailed AHS conflict fields
    // because they are useful during reconciliation/audit.
    // ============================================================
    ImportantColumns =
        {
            "MasterKey",
            "PanelID",
            "Doctor",
            "PatientID",
            "Source",
            "EventDate",
            "LastName",
            "FirstName",
            "DOB",
            "Conflict Category",
            "Gender",
            "Last Confirmation Date",
            "Date of Last Visit",
            "Conflicting Provider",
            "Conflicting Provider Role/Expertise",
            "Conflicting Provider Facility",
            "Last Confirmation Date for Conflicting Provider",
            "Date of Last Visit for Conflicting Provider",
            "Conflicting Panel Status",
            "ProducedDate",
            "DoctorValidation",
            "SourceFileName"
        },

    ExistingImportantColumns =
        List.Select(
            ImportantColumns,
            each
                List.Contains(
                    Table.ColumnNames(Rename),
                    _
                )
        ),

    OtherColumns =
        List.RemoveItems(
            Table.ColumnNames(Rename),
            ExistingImportantColumns
        ),

    Reorder =
        Table.ReorderColumns(
            Rename,
            ExistingImportantColumns & OtherColumns
        )

in
    Reorder
