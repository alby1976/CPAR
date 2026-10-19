(FolderPath as text, RootPath as text) as nullable record =>
let
    Root0 = Text.Replace(RootPath, "/", "\"),

    Root =
        if Text.EndsWith(Root0, "\")
        then Root0
        else Root0 & "\",

    NormalizedPath =
        Text.Replace(FolderPath, "/", "\"),

    Relative =
        if Text.StartsWith(
            Text.Upper(NormalizedPath),
            Text.Upper(Root)
        )
        then
            Text.Range(
                NormalizedPath,
                Text.Length(Root)
            )
        else
            NormalizedPath,

    Parts =
        List.Select(
            Text.Split(Relative, "\"),
            each _ <> ""
        ),

    DoctorFolder =
        if List.Count(Parts) = 0
        then null
        else Text.Upper(Text.Trim(Parts{0})),

    Match =
        if DoctorFolder = null
        then
            #table(
                {"Doctor", "PanelID", "FolderName"},
                {}
            )
        else
            Table.SelectRows(
                Doctor_Config,
                each [FolderName] = DoctorFolder
            ),

    Result =
        if Table.RowCount(Match) = 0
        then null
        else
            [
                Doctor = Match{0}[Doctor],
                PanelID = Match{0}[PanelID],
                FolderName = Match{0}[FolderName]
            ]
in
    Result
