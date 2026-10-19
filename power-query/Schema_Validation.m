(SourceType as text, ColumnNames as list) as record =>
let
    CleanSource =
        Text.Upper(
            Text.Trim(SourceType)
        ),

    CleanColumns =
        List.Transform(
            ColumnNames,
            each Text.Trim(Text.From(_))
        ),

    Required =
        if CleanSource = "CPAR" then
            {
                "LAST_NAME",
                "FIRST_NAME",
                "PHN",
                "SENT TO CPAR",
                "UNABLE_TO_SEND_REASON"
            }

        else if CleanSource = "CONFLICT" then
            {
                "Conflict Category",
                "Conflict First Reported",
                "Patient ID",
                "Last Name",
                "First Name",
                "Date of Birth"
            }

        else if CleanSource = "DEMOGRAPHIC_MISMATCH" then
            {
                "Patient Id",
                "Alberta Registry Patient Id",
                "Panel Patient Last Name",
                "Panel Patient First Name",
                "Panel Date Of Birth"
            }

        else
            {},

    Missing =
        List.Difference(
            Required,
            CleanColumns
        ),

    Status =
        if List.Count(Missing) = 0
        then "OK"
        else "MISSING_REQUIRED_COLUMN",

    Message =
        if List.Count(Missing) = 0
        then null
        else Text.Combine(Missing, ", ")
in
    [
        SchemaStatus = Status,
        MissingColumns = Message
    ]
