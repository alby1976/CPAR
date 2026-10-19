# Excel setup

## 1. Make a working copy

1. Back up the existing clinic workbook.
2. Make a separate test copy on approved local storage.
3. Keep reports and workbooks outside this repository.

## 2. Add Power Query source

1. In Excel, select **Data → Queries & Connections**.
2. Right-click the query to change and select **Edit**.
3. In Power Query Editor, select **Home → Advanced Editor**.
4. Back up the existing M code, then paste the reviewed code from the matching `power-query/*.m` file.
5. Keep the query name unchanged so dependent queries still work.
6. Check the preview for errors, then select **Close & Load**.

For a new query, use **Data → Get Data → From Other Sources → Blank Query**, open Advanced Editor, paste the code, and name the query exactly as documented. Import dependencies first.

## 3. Add VBA source

1. Save the test workbook as an **Excel Macro-Enabled Workbook (.xlsm)**.
2. Press **Alt+F11** to open the VBA editor.
3. Review existing modules before importing to avoid duplicate procedures.
4. For exported standard or class modules, use **File → Import File**.
5. Paste worksheet event code into the specified worksheet module; paste workbook event code into **ThisWorkbook**.
6. Select **Debug → Compile VBAProject**.
7. Enable macros only for reviewed code, following the clinic's security policy.

## 4. Verify a change

- Use fictional reports to check query refresh and expected output columns.
- Confirm keys such as MasterKey and RecordID remain intact wherever required.
- Check processed and ignored records, repeated actions, and empty input tables.
- Test buttons and worksheet events in the test workbook.
- Compare results before moving the reviewed change into the working workbook.

Source files are now available. See [import status](IMPORT_STATUS.md) before choosing revisions or applying patch fragments.
