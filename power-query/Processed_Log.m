let
    Source =
        Excel.CurrentWorkbook(){[Name="tblProcessedLog"]}[Content],

    Keep =
        Table.SelectRows(
            Source,
            each
                [RecordID] <> null
                and Text.Trim(Text.From([RecordID])) <> ""
        ),

    Clean =
        Table.TransformColumns(
            Keep,
            {
                {
                    "RecordID",
                    each Text.Trim(Text.From(_)),
                    type text
                },
                {
                    "Status",
                    each
                        if _ = null
                        then null
                        else Text.Upper(Text.Trim(Text.From(_))),
                    type nullable text
                }
            }
        )
in
    Clean
