# Query export update — October 26, 2026

The attached 44-query connection export was compared with the repository. This change imports seven changed query definitions from the export. Provider names and panel numbers in comments were removed; query logic was retained.

Four earlier exported definitions were deliberately not substituted for newer main versions:

- Folder_File_Index_Raw: keep direct Folder_Config validation, useful access errors and archive-folder exclusion.
- Doctor_Config: keep validation for active entries and duplicate mappings.
- Conflict_Actionable: keep the opt-in historical conflict filter.
- Archive_Loaded_RecordIDs: keep the corrected `each` syntax and detailed validation messages.

Review notable behavior in the imported scripts: Standardize_CPAR filters SENT TO CPAR to NO before downstream processing; the exported demographic query omits OriginalPatientID and Patient Id from its final selected columns; the master list and final worklist change field selection and ordering. Confirm that master-list history, downstream columns and archiving eligibility still satisfy the clinic workflow. Since the archive query reads Standardize_CPAR, already-submitted CPAR events do not appear in its ID snapshot in this version.

This is source inspection and a proposed update, not proof of successful execution. Test refresh, archive eligibility and reloading old report events in a disposable workbook with fictional data before clinical use. The workbook binary and manual log tables are not changed.
