let
    // ============================================================
    // STATE_CHANGES - OPTIMIZED
    //
    // Compares CURRENT actionable events against PREVIOUS events.
    //
    // Performance improvements:
    //   - Keeps only required columns before joins
    //   - Deduplicates StateKey values
    //   - Joins against small StateKey-only lookup tables
    //   - Buffers only the small lookup tables
    //   - Removes temporary nested-table columns before output
    // ============================================================


    // ============================================================
    // 1. CURRENT ACTIONABLE EVENTS
    // ============================================================

    Current0 =
        Actionable_Current_Events,


    // Keep only fields required for State_Changes.
    CurrentSlim =
        Table.SelectColumns(
            Current0,
            {
                "MasterKey",
                "Source",
                "IssueType",
                "PanelID",
                "Doctor",
                "PatientID"
            },
            MissingField.UseNull
        ),


    // Create a unique state identifier.
    CurrentWithKey =
        Table.AddColumn(
            CurrentSlim,
            "StateKey",
            each
                Text.From([MasterKey] ?? "")
                & "|"
                & Text.From([Source] ?? "")
                & "|"
                & Text.From([IssueType] ?? ""),
            type text
        ),


    // Keep only final identifying columns.
    CurrentKeyRows0 =
        Table.SelectColumns(
            CurrentWithKey,
            {
                "StateKey",
                "PanelID",
                "Doctor",
                "PatientID",
                "Source"
            },
            MissingField.UseNull
        ),


    // Remove duplicate current states.
    CurrentKeyRows =
        Table.Buffer(
            Table.Distinct(
                CurrentKeyRows0,
                {"StateKey"}
            )
        ),


    // ============================================================
    // 2. PREVIOUS EVENTS
    // ============================================================

    Previous0 =
        Previous_Source_Events,


    PreviousSlim =
        Table.SelectColumns(
            Previous0,
            {
                "MasterKey",
                "Source",
                "IssueType",
                "PanelID",
                "Doctor",
                "PatientID"
            },
            MissingField.UseNull
        ),


    PreviousWithKey =
        Table.AddColumn(
            PreviousSlim,
            "StateKey",
            each
                Text.From([MasterKey] ?? "")
                & "|"
                & Text.From([Source] ?? "")
                & "|"
                & Text.From([IssueType] ?? ""),
            type text
        ),


    PreviousKeyRows0 =
        Table.SelectColumns(
            PreviousWithKey,
            {
                "StateKey",
                "PanelID",
                "Doctor",
                "PatientID",
                "Source"
            },
            MissingField.UseNull
        ),


    // Remove duplicate previous states.
    PreviousKeyRows =
        Table.Buffer(
            Table.Distinct(
                PreviousKeyRows0,
                {"StateKey"}
            )
        ),


    // ============================================================
    // 3. CREATE SMALL PRESENCE LOOKUP TABLES
    // ============================================================

    CurrentPresence =
        Table.Buffer(
            Table.SelectColumns(
                CurrentKeyRows,
                {"StateKey"}
            )
        ),


    PreviousPresence =
        Table.Buffer(
            Table.SelectColumns(
                PreviousKeyRows,
                {"StateKey"}
            )
        ),


    // ============================================================
    // 4. CREATE MASTER LIST OF ALL STATES
    //
    // Current rows are placed first so current doctor/patient
    // metadata is preferred when the state exists in both periods.
    // ============================================================

    CombinedKeys =
        Table.Combine(
            {
                CurrentKeyRows,
                PreviousKeyRows
            }
        ),


    AllKeys =
        Table.Distinct(
            CombinedKeys,
            {"StateKey"}
        ),


    // ============================================================
    // 5. CURRENT PRESENCE CHECK
    // ============================================================

    MergeCurrent =
        Table.NestedJoin(
            AllKeys,
            {"StateKey"},
            CurrentPresence,
            {"StateKey"},
            "_CurrentMatch",
            JoinKind.LeftOuter
        ),


    AddCurrentPresent =
        Table.AddColumn(
            MergeCurrent,
            "CurrentPresent",
            each
                not Table.IsEmpty([_CurrentMatch]),
            type logical
        ),


    // ============================================================
    // 6. PREVIOUS PRESENCE CHECK
    // ============================================================

    MergePrevious =
        Table.NestedJoin(
            AddCurrentPresent,
            {"StateKey"},
            PreviousPresence,
            {"StateKey"},
            "_PreviousMatch",
            JoinKind.LeftOuter
        ),


    AddPreviousPresent =
        Table.AddColumn(
            MergePrevious,
            "PreviousPresent",
            each
                not Table.IsEmpty([_PreviousMatch]),
            type logical
        ),


    // ============================================================
    // 7. DETERMINE STATE STATUS
    // ============================================================

    AddStatus =
        Table.AddColumn(
            AddPreviousPresent,
            "SourcePresenceStatus",
            each
                if [CurrentPresent] = true
                    and [PreviousPresent] = false
                then
                    "NEW_OR_REAPPEARED"

                else if [CurrentPresent] = true
                    and [PreviousPresent] = true
                then
                    "STILL_PRESENT"

                else if [CurrentPresent] = false
                    and [PreviousPresent] = true
                then
                    "NO_LONGER_REPORTED"

                else
                    "UNKNOWN",
            type text
        ),


    // ============================================================
    // 8. REMOVE TEMPORARY NESTED TABLE COLUMNS
    //
    // This prevents [Table] cells from appearing in Excel.
    // ============================================================

    RemoveTemporaryColumns =
        Table.RemoveColumns(
            AddStatus,
            {
                "_CurrentMatch",
                "_PreviousMatch"
            },
            MissingField.Ignore
        ),


    // ============================================================
    // 9. FINAL COLUMN ORDER
    // ============================================================

    Final =
        Table.ReorderColumns(
            RemoveTemporaryColumns,
            {
                "StateKey",
                "PanelID",
                "Doctor",
                "PatientID",
                "Source",
                "CurrentPresent",
                "PreviousPresent",
                "SourcePresenceStatus"
            },
            MissingField.Ignore
        ),


    // ============================================================
    // 10. SORT OUTPUT
    // ============================================================

    Sorted =
        Table.Sort(
            Final,
            {
                {"Doctor", Order.Ascending},
                {"PatientID", Order.Ascending},
                {"Source", Order.Ascending}
            }
        )

in
    Sorted
