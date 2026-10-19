let
    Source =
        Excel.CurrentWorkbook(){[Name="tblIgnoreRules"]}[Content],

    Types =
        Table.TransformColumnTypes(
            Source,
            {
                {"RuleID", type text},
                {"Source", type text},
                {"FieldName", type text},
                {"MatchType", type text},
                {"MatchValue", type text},
                {"AutoProcess", type logical},
                {"AutoStatus", type text},
                {"Active", type logical},
                {"Reason", type text}
            }
        ),

    Keep =
        Table.SelectRows(
            Types,
            each
                [Active] <> false
                and [RuleID] <> null
                and [Source] <> null
                and [FieldName] <> null
                and [MatchValue] <> null
        ),

    Clean =
        Table.TransformColumns(
            Keep,
            {
                {
                    "Source",
                    each Text.Upper(Text.Trim(Text.From(_))),
                    type text
                },
                {
                    "FieldName",
                    each Text.Trim(Text.From(_)),
                    type text
                },
                {
                    "MatchType",
                    each Text.Upper(Text.Trim(Text.From(_))),
                    type text
                },
                {
                    "MatchValue",
                    each Text.Trim(Text.From(_)),
                    type text
                }
            }
        )
in
    Clean
