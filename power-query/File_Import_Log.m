let
    Source =
        Parsed_File_Cache,

    // The parsed patient tables are used only by downstream
    // Standardize_* queries. Do not expose them in the audit log.
    RemoveParsedTable =
        Table.RemoveColumns(
            Source,
            {"ParsedTable"},
            MissingField.Ignore
        )
in
    RemoveParsedTable
