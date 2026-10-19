(SettingName as text) as text =>
let
    Source = Excel.CurrentWorkbook(){[Name="tblFolderConfig"]}[Content],
    Match = Table.SelectRows(Source, each [Setting] = SettingName),
    Value = if Table.RowCount(Match)=0 then error "Missing setting: " & SettingName else Text.From(Match{0}[Value])
in
    Value
