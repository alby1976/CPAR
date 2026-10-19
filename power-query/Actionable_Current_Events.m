let
    Source =
        Current_Source_Events,

    AddRule =
        Table.AddColumn(
            Source,
            "IgnoreRule",
            each
                ApplyIgnoreRules(
                    [Source],
                    _
                ),
            type any
        ),

    Keep =
        Table.SelectRows(
            AddRule,
            each [IgnoreRule] = null
        ),

    Remove =
        Table.RemoveColumns(
            Keep,
            {"IgnoreRule"}
        )
in
    Remove
