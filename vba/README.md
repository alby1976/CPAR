# A Dummies Guide to the VBA Folder

Store exported standard modules as `.bas` and class modules as `.cls`. Document the target worksheet for worksheet event code and the target workbook for `ThisWorkbook` code.

Check exported modules for private paths, passwords, and embedded patient information before committing. UserForms and their binary companion files are excluded by default and require a deliberate review before inclusion.

The documented `CPAR_Worklist_Actions` standard module is included. Import only one version of this module to avoid duplicate procedures. Embedded workbook VBA has not been separately exported. See [import status](../docs/IMPORT_STATUS.md).
