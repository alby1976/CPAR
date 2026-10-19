let
    Source =
        File_Import_Log,

    Keep =
        Table.SelectRows(
            Source,
            each
                [ImportStatus] <> "OK"
                or
                (
                    [SchemaStatus] <> "OK"
                    and [SchemaStatus] <> "NOT_APPLICABLE"
                )
                or [DoctorValidation] <> "OK"
        ),

    AddErrorType =
        Table.AddColumn(
            Keep,
            "ErrorType",
            each
                if [ImportStatus] <> "OK" then
                    "IMPORT_ERROR"

                else if
                    [SchemaStatus] <> "OK"
                    and [SchemaStatus] <> "NOT_APPLICABLE"
                then
                    "SCHEMA_ERROR"

                else if [DoctorValidation] <> "OK" then
                    "METADATA_ERROR"

                else
                    "UNKNOWN_ERROR",
            type text
        ),

    Select =
        Table.SelectColumns(
            AddErrorType,
            {
                "PanelID",
                "Doctor",
                "SourceType",
                "FileName",
                "ReportDate",
                "ErrorType",
                "ErrorMessage",
                "SchemaStatus",
                "MissingColumns",
                "DoctorValidation"
            },
            MissingField.UseNull
        )
in
    Select
