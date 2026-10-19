let
    Source =
        Excel.CurrentWorkbook(){[Name="tblMasterInput"]}[Content],

    Keep =
        Table.SelectRows(
            Source,
            each
                [PanelID] <> null
                and [PatientID] <> null
                and [OverrideMasterEntryDate] <> null
                and [Active] <> false
        ),

    Types =
        Table.TransformColumnTypes(
            Keep,
            {
                {"PanelID", type text},
                {"PatientID", type text},
                {"OverrideMasterEntryDate", type date}
            }
        ),

    Clean =
        Table.TransformColumns(
            Types,
            {
                {
                    "PanelID",
                    each Text.Trim(Text.From(_)),
                    type text
                },
                {
                    "PatientID",
                    each Text.Trim(Text.From(_)),
                    type text
                }
            }
        ),

    AddMasterKey =
        Table.AddColumn(
            Clean,
            "MasterKey",
            each [PanelID] & "|" & [PatientID],
            type text
        )
in
    AddMasterKey
