let
    ConflictBad =
        Table.SelectRows(
            Standardize_Conflicts,
            each [DoctorValidation] <> "OK"
        ),

    DemoBad =
        Table.SelectRows(
            Standardize_Demographic_Mismatch,
            each [DoctorValidation] <> "OK"
        ),

    Combined =
        Table.Combine(
            {
                ConflictBad,
                DemoBad
            }
        )
in
    Combined
