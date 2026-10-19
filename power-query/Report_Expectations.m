let
    Source =
        Excel.CurrentWorkbook(){[Name="tblReportExpectations"]}[Content],

    Types =
        Table.TransformColumnTypes(
            Source,
            {
                {"PanelID", type text},
                {"ReportType", type text},
                {"Expected", type logical},
                {"Notes", type text}
            }
        ),

    Keep =
        Table.SelectRows(
            Types,
            each
                [PanelID] <> null
                and Text.Trim(Text.From([PanelID])) <> ""
                and [Expected] <> false
        ),

    Clean =
        Table.TransformColumns(
            Keep,
            {
                {
                    "PanelID",
                    each Text.Trim(Text.From(_)),
                    type text
                },
                {
                    "ReportType",
                    each Text.Upper(Text.Trim(Text.From(_))),
                    type text
                }
            }
        )
in
    Clean
