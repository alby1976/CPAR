let
    Source = Excel.CurrentWorkbook(){[Name="tblDoctorConfig"]}[Content],
    TextValue = (v as any) as text => if v = null then "" else Text.Trim(Text.From(v)),
    Flag = (v as any) as logical =>
        if v = null then false else if Value.Is(v, type logical) then v
        else if List.Contains({"TRUE", "YES", "1"}, Text.Upper(TextValue(v))) then true
        else if List.Contains({"FALSE", "NO", "0", ""}, Text.Upper(TextValue(v))) then false
        else error "Doctor_Config Active must be TRUE or FALSE.",
    Filled = Table.SelectRows(Source, each TextValue([Doctor]) <> "" or TextValue([PanelID]) <> "" or TextValue([FolderName]) <> ""),
    Clean = Table.TransformColumns(Filled, {{"Doctor", each Text.Upper(TextValue(_)), type text}, {"PanelID", each TextValue(_), type text}, {"FolderName", each Text.Upper(TextValue(_)), type text}, {"Active", each Flag(_), type logical}}),
    Active = Table.SelectRows(Clean, each [Active] = true),
    Invalid = Table.SelectRows(Active, each [Doctor] = "" or [PanelID] = "" or [FolderName] = "" or Text.Contains([FolderName], "\") or Text.Contains([FolderName], "/") or List.Contains({".", ".."}, [FolderName])),
    Validated = if Table.RowCount(Invalid) > 0 then error "Clinic setup: every active provider needs Doctor, PanelID and an immediate FolderName (not a path)." else Active,
    Duplicates = Table.RowCount(Table.Distinct(Validated, {"PanelID"})) <> Table.RowCount(Validated) or Table.RowCount(Table.Distinct(Validated, {"FolderName"})) <> Table.RowCount(Validated),
    Result = if Duplicates then error "Clinic setup: active PanelID and FolderName values must each be unique." else Validated
in
    Result
