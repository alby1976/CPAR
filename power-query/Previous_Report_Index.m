let
    Source =
        Latest_Report_Index,

    Previous =
        Table.SelectRows(
            Source,
            each [LatestRank] = 2
        )
in
    Previous
