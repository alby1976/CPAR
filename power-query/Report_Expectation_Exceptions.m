let
    // ============================================================
    // READ REPORT EXPECTATION EXCEPTIONS
    // ============================================================
    Source =
        Excel.CurrentWorkbook(){
            [Name="tblReportExpectationExceptions"]
        }[Content],

    // ============================================================
    // SET DATA TYPES
    // ============================================================
    Types =
        Table.TransformColumnTypes(
            Source,
            {
                {"PanelID", type text},
                {"ReportType", type text},
                {"PeriodStart", type date},
                {"PeriodEnd", type date},
                {"Expected", type logical},
                {"Notes", type text}
            }
        ),

    // ============================================================
    // CLEAN KEY VALUES
    // ============================================================
    Clean =
        Table.TransformColumns(
            Types,
            {
                {
                    "PanelID",
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
                    "ReportType",
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
    // KEEP VALID EXCEPTION ROWS
    // ============================================================
    Keep =
        Table.SelectRows(
            Clean,
            each
                [PanelID] <> null
                and [PanelID] <> ""
                and [ReportType] <> null
                and [ReportType] <> ""
                and [PeriodStart] <> null
                and [PeriodEnd] <> null
        )

in
    Keep
