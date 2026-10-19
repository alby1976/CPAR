let
    Source = Excel.CurrentWorkbook(){[Name="tblDoctorConfig"]}[Content],
    Keep = Table.SelectRows(Source, each [PanelID] <> null and Text.Trim(Text.From([PanelID])) <> ""),
    Types = Table.TransformColumnTypes(Keep,{{"Doctor",type text},{"PanelID",type text},{"FolderName",type text},{"Active",type logical},{"Notes",type text}}),
    Clean = Table.TransformColumns(Types,{
        {"Doctor", each Text.Upper(Text.Trim(Text.From(_))), type text},
        {"PanelID", each Text.Trim(Text.From(_)), type text},
        {"FolderName", each Text.Upper(Text.Trim(Text.From(_))), type text}
    }),
    ActiveOnly = Table.SelectRows(Clean, each [Active] <> false)
in
    ActiveOnly
