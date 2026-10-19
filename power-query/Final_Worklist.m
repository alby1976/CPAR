let
    // ============================================================
    // FINAL_WORKLIST
    //
    // Starts from Actionable_Current_Events.
    //
    // Removes:
    //   - ProcessedStatus = DONE
    //   - ProcessedStatus = IGNORE
    //   - IssueType = CPAR: Yes
    //
    // Processed_Records is the combined processing layer containing:
    //   - manually processed records
    //   - automatically processed ignore records
    // ============================================================


    // ============================================================
    // 1. CURRENT ACTIONABLE EVENTS
    // ============================================================

    Source =
        Actionable_Current_Events,


    // ============================================================
    // 2. PRESERVE EXISTING EFFECTIVE MASTER ENTRY DATE
    // ============================================================

    PreserveExistingMasterDate =
        if Table.HasColumns(
            Source,
            {"EffectiveMasterEntryDate"}
        ) then
            Table.RenameColumns(
                Source,
                {
                    {
                        "EffectiveMasterEntryDate",
                        "SourceEffectiveMasterEntryDate"
                    }
                }
            )
        else
            Table.AddColumn(
                Source,
                "SourceEffectiveMasterEntryDate",
                each null,
                type nullable date
            ),


    // ============================================================
    // 3. MERGE MASTER PATIENT LIST
    // ============================================================

    MergeMaster =
        Table.NestedJoin(
            PreserveExistingMasterDate,
            {"MasterKey"},
            Master_Patient_List,
            {"MasterKey"},
            "Master",
            JoinKind.LeftOuter
        ),


    // ============================================================
    // 4. EXPAND MASTER EFFECTIVE DATE
    // ============================================================

    ExpandMaster =
        Table.ExpandTableColumn(
            MergeMaster,
            "Master",
            {
                "EffectiveMasterEntryDate"
            },
            {
                "MasterEffectiveMasterEntryDate"
            }
        ),


    // ============================================================
    // 5. FINAL EFFECTIVE MASTER ENTRY DATE
    //
    // Prefer the date already supplied by the source.
    // Otherwise use Master_Patient_List.
    // ============================================================

    AddEffectiveMasterEntryDate =
        Table.AddColumn(
            ExpandMaster,
            "EffectiveMasterEntryDate",
            each
                if [SourceEffectiveMasterEntryDate] <> null then
                    [SourceEffectiveMasterEntryDate]
                else
                    [MasterEffectiveMasterEntryDate],
            type nullable date
        ),


    // ============================================================
    // 6. REMOVE MASTER-DATE HELPER COLUMNS
    // ============================================================

    RemoveMasterHelpers =
        Table.RemoveColumns(
            AddEffectiveMasterEntryDate,
            {
                "SourceEffectiveMasterEntryDate",
                "MasterEffectiveMasterEntryDate"
            },
            MissingField.Ignore
        ),


    // ============================================================
    // 7. PREPARE PROCESSED RECORDS
    //
    // Processed_Records includes:
    //
    //   Manual Processed_Log
    //
    //              +
    //
    //   Automatic records where:
    //       AutoProcess = TRUE
    //       AutoStatus  = IGNORE
    // ============================================================

    ProcessedSource =
        Table.SelectColumns(
            Processed_Records,
            {
                "RecordID",
                "Status"
            },
            MissingField.UseNull
        ),


    // ============================================================
    // 8. NORMALIZE PROCESSED RECORD IDS AND STATUS
    // ============================================================

    CleanProcessedStatus =
        Table.TransformColumns(
            ProcessedSource,
            {
                {
                    "RecordID",
                    each
                        if _ = null then
                            null
                        else
                            Text.Trim(
                                Text.From(_)
                            ),
                    type nullable text
                },

                {
                    "Status",
                    each
                        if _ = null then
                            null
                        else
                            Text.Upper(
                                Text.Trim(
                                    Text.From(_)
                                )
                            ),
                    type nullable text
                }
            }
        ),


    // ============================================================
    // 9. REMOVE BLANK PROCESSED RECORD IDS
    // ============================================================

    ValidProcessed =
        Table.SelectRows(
            CleanProcessedStatus,
            each
                [RecordID] <> null
                and [RecordID] <> ""
        ),


    // ============================================================
    // 10. COLLAPSE DUPLICATE PROCESSED RECORD IDS
    //
    // Priority:
    //
    //   DONE
    //   IGNORE
    //   PENDING
    //   WAITING
    //   REVIEW
    //
    // A terminal status wins if more than one status exists
    // for the same RecordID.
    // ============================================================

    ProcessedByRecord =
        Table.Group(
            ValidProcessed,
            {
                "RecordID"
            },
            {
                {
                    "ProcessedStatus",
                    each
                        let
                            Statuses =
                                List.RemoveNulls(
                                    [Status]
                                ),

                            NonBlankStatuses =
                                List.Select(
                                    Statuses,
                                    each
                                        Text.Trim(
                                            Text.From(_)
                                        ) <> ""
                                ),

                            Result =
                                if List.Contains(
                                    NonBlankStatuses,
                                    "DONE"
                                ) then
                                    "DONE"

                                else if List.Contains(
                                    NonBlankStatuses,
                                    "IGNORE"
                                ) then
                                    "IGNORE"

                                else if List.Contains(
                                    NonBlankStatuses,
                                    "PENDING"
                                ) then
                                    "PENDING"

                                else if List.Contains(
                                    NonBlankStatuses,
                                    "WAITING"
                                ) then
                                    "WAITING"

                                else if List.Contains(
                                    NonBlankStatuses,
                                    "REVIEW"
                                ) then
                                    "REVIEW"

                                else if
                                    List.Count(
                                        NonBlankStatuses
                                    ) > 0
                                then
                                    NonBlankStatuses{0}

                                else
                                    null
                        in
                            Result,
                    type nullable text
                }
            }
        ),


    // ============================================================
    // 11. NORMALIZE CURRENT RECORD ID
    //
    // Helps prevent a failed match caused by leading/trailing
    // spaces in RecordID.
    // ============================================================

    CleanCurrentRecordID =
        Table.TransformColumns(
            RemoveMasterHelpers,
            {
                {
                    "RecordID",
                    each
                        if _ = null then
                            null
                        else
                            Text.Trim(
                                Text.From(_)
                            ),
                    type nullable text
                }
            }
        ),


    // ============================================================
    // 12. MERGE WITH PROCESSED_RECORDS
    // ============================================================

    MergeProcessed =
        Table.NestedJoin(
            CleanCurrentRecordID,
            {"RecordID"},
            ProcessedByRecord,
            {"RecordID"},
            "ProcessedMatch",
            JoinKind.LeftOuter
        ),


    // ============================================================
    // 13. EXPAND PROCESSED STATUS
    // ============================================================

    ExpandProcessed =
        Table.ExpandTableColumn(
            MergeProcessed,
            "ProcessedMatch",
            {
                "ProcessedStatus"
            },
            {
                "LoggedProcessedStatus"
            }
        ),


    // ============================================================
    // 14. ASSIGN CURRENT WORKLIST STATUS
    //
    // No processing record:
    //
    //      NEW
    //
    // Otherwise preserve the processing status.
    // ============================================================

    AddProcessedStatus =
        Table.AddColumn(
            ExpandProcessed,
            "ProcessedStatus",
            each
                if [LoggedProcessedStatus] = null
                    or
                    Text.Trim(
                        Text.From(
                            [LoggedProcessedStatus]
                        )
                    ) = ""
                then
                    "NEW"

                else
                    Text.Upper(
                        Text.Trim(
                            Text.From(
                                [LoggedProcessedStatus]
                            )
                        )
                    ),
            type text
        ),


    // ============================================================
    // 15. REMOVE HELPER STATUS COLUMN
    // ============================================================

    RemoveStatusHelper =
        Table.RemoveColumns(
            AddProcessedStatus,
            {
                "LoggedProcessedStatus"
            },
            MissingField.Ignore
        ),


    // ============================================================
    // 16. REMOVE DONE AND IGNORE
    //
    // These records have already reached a terminal state
    // and should not remain in the active worklist.
    // ============================================================

    FilterOpen =
        Table.SelectRows(
            RemoveStatusHelper,
            each
                not List.Contains(
                    {
                        "DONE",
                        "IGNORE"
                    },
                    [ProcessedStatus]
                )
        ),


    // ============================================================
    // 17. REMOVE IssueType = "CPAR: Yes"
    //
    // Handles capitalization and extra spaces:
    //
    //   CPAR: Yes
    //   CPAR: YES
    //   cpar: yes
    //    CPAR: Yes
    //
    // Null IssueType remains in the worklist.
    // ============================================================

    RemoveCPARYes =
        Table.SelectRows(
            FilterOpen,
            each
                [IssueType] = null
                or
                Text.Upper(
                    Text.Trim(
                        Text.From(
                            [IssueType]
                        )
                    )
                ) <> "CPAR: YES"
        ),


    // ============================================================
    // 18. SELECT FINAL WORKLIST COLUMNS
    // ============================================================

    SelectColumns =
        Table.SelectColumns(
            RemoveCPARYes,
            {
                "RecordID",
                "MasterKey",
                "PanelID",
                "Doctor",
                "PatientID",
                "Source",
                "EventDate",
                "EffectiveMasterEntryDate",
                "LastName",
                "FirstName",
                "DOB",
                "IssueType",
                "ConflictRule",
                "ProcessedStatus"
            },
            MissingField.UseNull
        ),


    // ============================================================
    // 19. FINAL DATA TYPES
    // ============================================================

    Types =
        Table.TransformColumnTypes(
            SelectColumns,
            {
                {"RecordID", type text},
                {"MasterKey", type text},
                {"PanelID", type text},
                {"Doctor", type text},
                {"PatientID", type text},
                {"Source", type text},
                {"EventDate", type date},
                {"EffectiveMasterEntryDate", type date},
                {"LastName", type text},
                {"FirstName", type text},
                {"DOB", type date},
                {"IssueType", type text},
                {"ConflictRule", type text},
                {"ProcessedStatus", type text}
            }
        ),


    // ============================================================
    // 20. SORT FINAL ACTIVE WORKLIST
    // ============================================================

    Final =
        Table.Sort(
            Types,
            {
                {"Doctor", Order.Ascending},
                {"Source", Order.Ascending},
                {"EventDate", Order.Ascending},
                {"PatientID", Order.Ascending}
            }
        )

in
    Final
