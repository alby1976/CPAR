# A Dummies Guide to the Power Query Folder

Save each Excel query as a separate `.m` file with the exact query name, for example `Final_Worklist.m`.

Preserve existing query names and dependencies. Do not include patient records, credentials, or clinic-specific file paths in exported code; use local parameters where appropriate.

42 query formulas have been imported from the October 17 connection exports. Newer complete query versions are retained separately in `revisions/`; patch fragments are in `../docs/patches/`. See [import status](../docs/IMPORT_STATUS.md).
