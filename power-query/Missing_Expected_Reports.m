let
    // ============================================================
    // 1. BASE REPORT EXPECTATIONS
    //
    // These are reports normally expected for each PanelID.
    // ============================================================
    BaseExpected =
        Table.SelectRows(
            Report_Expectations,
            each [Expected] <> false
        ),

    // ============================================================
    // 2. DETERMINE CURRENT REPORTING PERIOD
    //
    // Take the newest report date found among valid indexed files.
    //
    // With your current files this should become May 2026.
    // ============================================================
    ValidDates =
        List.RemoveNulls(
            Latest_Report_Index[ReportDate]
        ),

    TargetDate =
        if List.Count(ValidDates) = 0 then
            error "Cannot determine reporting period because no valid report dates were found."
        else
            List.Max(ValidDates),

    PeriodStart =
        Date.StartOfMonth(TargetDate),

    PeriodEnd =
        Date.EndOfMonth(TargetDate),

    // ============================================================
    // 3. ADD TARGET PERIOD TO EVERY EXPECTED REPORT
    // ============================================================
    AddPeriodStart =
        Table.AddColumn(
            BaseExpected,
            "PeriodStart",
            each PeriodStart,
            type date
        ),

    AddPeriodEnd =
        Table.AddColumn(
            AddPeriodStart,
            "PeriodEnd",
            each PeriodEnd,
            type date
        ),

    // ============================================================
    // 4. GET VALID REPORTS THAT ACTUALLY BELONG TO TARGET MONTH
    //
    // IMPORTANT:
    // An April report does NOT satisfy a May expectation.
    // ============================================================
    ReportsInPeriod =
        Table.SelectRows(
            Latest_Report_Index,
            each
                [ReportDate] <> null
                and [ReportDate] >= PeriodStart
                and [ReportDate] <= PeriodEnd
        ),

    ReceivedIndex =
        Table.Distinct(
            Table.SelectColumns(
                ReportsInPeriod,
                {
                    "PanelID",
                    "SourceType",
                    "ReportDate"
                }
            )
        ),

    // ============================================================
    // 5. MATCH EXPECTED REPORTS TO RECEIVED REPORTS
    // ============================================================
    MergeReceived =
        Table.NestedJoin(
            AddPeriodEnd,
            {
                "PanelID",
                "ReportType"
            },
            ReceivedIndex,
            {
                "PanelID",
                "SourceType"
            },
            "ReceivedRows",
            JoinKind.LeftOuter
        ),

    AddReceived =
        Table.AddColumn(
            MergeReceived,
            "Received",
            each
                Table.RowCount([ReceivedRows]) > 0,
            type logical
        ),

    AddLatestReportDate =
        Table.AddColumn(
            AddReceived,
            "LatestReportDate",
            each
                if Table.RowCount([ReceivedRows]) = 0 then
                    null
                else
                    try
                        List.Max(
                            List.RemoveNulls(
                                [ReceivedRows][ReportDate]
                            )
                        )
                    otherwise
                        null,
            type nullable date
        ),

    // ============================================================
    // 6. GET ONLY EXCEPTIONS THAT APPLY TO THIS REPORTING PERIOD
    //
    // Example:
    //
    // April 1-April 30 exception
    //
    // does NOT apply to:
    //
    // May 1-May 31
    // ============================================================
    ApplicableExceptions =
        Table.SelectRows(
            Report_Expectation_Exceptions,
            each
                [Expected] = false
                and [PeriodStart] <> null
                and [PeriodEnd] <> null
                and [PeriodStart] <= PeriodEnd
                and [PeriodEnd] >= PeriodStart
        ),

    // ============================================================
    // 7. MATCH EXCEPTIONS
    //
    // ApplicableExceptions has ALREADY been limited to the target
    // month, so PanelID + ReportType is now safe for this merge.
    // ============================================================
    MergeException =
        Table.NestedJoin(
            AddLatestReportDate,
            {
                "PanelID",
                "ReportType"
            },
            ApplicableExceptions,
            {
                "PanelID",
                "ReportType"
            },
            "ExceptionRows",
            JoinKind.LeftOuter
        ),

    AddException =
        Table.AddColumn(
            MergeException,
            "HasException",
            each
                Table.RowCount([ExceptionRows]) > 0,
            type logical
        ),

    // ============================================================
    // 8. KEEP ONLY ACTUALLY MISSING REPORTS
    //
    // Missing =
    //   expected
    //   not received
    //   no valid exception for THIS month
    // ============================================================
    KeepMissing =
        Table.SelectRows(
            AddException,
            each
                [Received] = false
                and [HasException] = false
        ),

    // ============================================================
    // 9. ADD DOCTOR NAME
    // ============================================================
    AddDoctor =
        Table.AddColumn(
            KeepMissing,
            "Doctor",
            each
                let
                    CurrentPanel =
                        [PanelID],

                    Match =
                        Table.SelectRows(
                            Doctor_Config,
                            (d) =>
                                d[PanelID] = CurrentPanel
                        )
                in
                    if Table.RowCount(Match) = 0 then
                        null
                    else
                        Match{0}[Doctor],
            type nullable text
        ),

    // ============================================================
    // 10. STATUS
    // ============================================================
    AddStatus =
        Table.AddColumn(
            AddDoctor,
            "Status",
            each "MISSING_EXPECTED_REPORT",
            type text
        ),

    // ============================================================
    // 11. FINAL OUTPUT
    // ============================================================
    Select =
        Table.SelectColumns(
            AddStatus,
            {
                "PanelID",
                "Doctor",
                "ReportType",
                "PeriodStart",
                "PeriodEnd",
                "Expected",
                "Received",
                "LatestReportDate",
                "Status"
            }
        )

in
    Select
