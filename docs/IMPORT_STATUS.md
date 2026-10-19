# Import status

Imported on October 19, 2026.

## Sources and versions

- `Power Queries(1).zip` (October 17 export): extracted 42 complete query formulas from the ODC PowerQueryMashupData into `power-query/`. Embedded query names were preserved. The connection file named `Final_Worklist1` contains the query `Final_Worklist`, so its extracted file is `Final_Worklist.m`.
- `CPAR_PowerQuery_and_VBA_Documented.zip` (October 19): imported the documented standard module into `vba/` and both documentation files into `docs/`.
- The newer complete `Processed_Log_documented.m` is in `power-query/revisions/`. It has not replaced the older `Processed_Log.m` export.
- Two newer patch fragments are in `docs/patches/`. They are instructions for editing queries, not standalone queries, and have not been applied.
- `AHS_CPAR_Reconcilation.xlsm` (October 15 upload) is retained unchanged in the local ignored `local/` directory. It contains a VBA project and a populated Worklist_Output sheet. It is excluded from public Git history.

## Important limits

These sources have different dates. This import preserves them without claiming that the old workbook contains the later query changes. The documented VBA module was imported from its separate source package; embedded workbook VBA was not separately exported. The original workbook retains that embedded VBA unchanged.

No macros were executed and no Power Query refresh was run. Excel import, VBA compilation, and refresh validation remain necessary before clinical use. The original Excel workbook was not modified.
