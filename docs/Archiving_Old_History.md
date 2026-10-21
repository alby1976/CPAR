# A Dummies Guide to Archiving Old CPAR History

Keep recent work in the active log. Move old detail into a separate local archive while keeping a small permanent list of processed event keys.

## What qualifies?

All four conditions must hold:

- DateProcessed is a valid date older than 4 months.
- Status is DONE, IGNORE or IGNORED.
- RecordID is nonblank and absent from every successfully loaded standardized report, including historical reports still loaded.
- A new archive snapshot refresh succeeds with no import errors, unmapped folders or missing expected reports.

Blank or invalid dates, open statuses and still-loaded IDs stay in the log. Even an empty loaded-event inventory blocks cleanup. A missing CSV alone is not enough to qualify a recent action. The cutoff uses DateProcessed, not the report date. Change KEEP_MONTHS in the VBA module if the clinic chooses another period.

## Install once, in this order

1. Back up the workbook. Test with fictional data in a separate copy first.
2. Create a blank manual Excel table on a new sheet named Archive_Keys. Give it the table name **tblArchivedProcessedKeys** and these exact headers: **RecordID**, **Status**, **DateProcessed**. Format RecordID as Text. This is persistent input, not a query destination.
3. Create the connection-only query [Archived_Processed_Keys](../power-query/Archived_Processed_Keys.m).
4. Replace Processed_Log with [this version](../power-query/Processed_Log.m). It reads both the active log and compact archive keys. Do not load it back onto either input table. Downstream Processed_Records/Final_Worklist keep their existing connections to it.
5. Create [Archive_Loaded_RecordIDs](../power-query/Archive_Loaded_RecordIDs.m). Load it to a dedicated sheet and name its output table **tblArchiveLoadedRecordIDs**. Leave its READY marker and timestamp untouched.
6. Import [CPAR_Archive_History.bas](../vba/CPAR_Archive_History.bas) through the VBA editor's File > Import File. Choose Debug > Compile VBAProject.
7. On Folder_Config, enter an existing secure archive folder in the Value cell beside Archive_Folder in tblFolderConfig. The macro finds the setting by name, even if its row moves. Both history .xlsx and backup .xlsm are saved there. Blank, duplicate, relative or unavailable settings stop archiving. Drive and UNC network paths are supported; folders are not created automatically.
8. Replace [Folder_File_Index_Raw](../power-query/Folder_File_Index_Raw.m) with this branch's version, which excludes the configured archive folder from doctor-folder discovery.
9. Assign **ArchiveOldHistory** to a Form Control button named Archive Old History.

## Use the button

1. Finish ordinary refreshes and resolve report/folder warnings.
2. Save the workbook locally. Click Archive Old History.
3. The macro synchronously refreshes the archive snapshot. It refuses a cancelled, failed, empty, incomplete or stale result.
4. Review the count and cutoff. Choose Yes to continue. The macro reads Archive_Folder from tblFolderConfig on Folder_Config; no folder picker is shown.
5. The macro writes a full pre-archive workbook backup and a separate .xlsx containing all selected log columns. It closes, reopens and checks every saved data cell against the source values.
6. It appends compact keys and saves the workbook BEFORE deleting detail rows. Then it deletes bottom-up and saves again.
7. Keep both external files. Refresh All before continuing work. Do not use the previous action batch's Undo after archiving.

Declining confirmation changes no log records, although the archive snapshot may have refreshed. Cleanup considers all log rows, including filtered/hidden rows; worksheet filters do not limit the archive batch.

## What stays where?

| Location | Contents |
|---|---|
| tblProcessedLog | Recent, open, undated and still-loaded detailed history |
| tblArchivedProcessedKeys | RecordID, Status and DateProcessed for archived actions |
| Separate history .xlsx | Every original log column for the archived rows |
| Separate before_archive.xlsm | Complete workbook state before the archive writes |

The history file stores original values as text to preserve identifiers and avoid formula interpretation. Excel dates are stored as their original serial values, not human-readable formatted dates. The backup preserves the workbook's original formatting. Archive files may contain patient information and require the same access controls as the working workbook. Never commit populated archives or backups to GitHub.

## If an old report returns

Processed_Log combines active detail with compact keys. Its RecordIDs remain DONE/IGNORE downstream even after the detail leaves the active log. The compact table grows over time; this reduces detailed storage, not the number of remembered events. It is not a complete solution to Excel's row limit. Duplicated compact keys from a failed attempt are safe for downstream grouping, but inspect and reconcile them before retrying.

To deliberately reopen an archived event, locate its detailed archive, remove all corresponding terminal entries from the compact table and active log as appropriate, then refresh. Adding a PENDING entry alone will not override an older terminal status in the existing Final_Worklist rules.

## Failures and recovery

Archiving is not a database transaction. File permissions, disk space, protection or a crash can stop a batch. The error reports the number of detail rows removed in that run and the backup path. Earlier writes may already exist. Preserve all files and inspect before retrying. For full recovery, close the working workbook and open a copy of before_archive.xlsm; do not overwrite your only backup.

The macro does not automatically delete source CSVs, run unattended, or change the clinic's record-retention policy. Folder access can change after the snapshot; keep the source folders stable during the operation.

## Checks before routine use

In desktop Excel, test old absent DONE, old present DONE, recent absent DONE, blank date, nonterminal status, duplicate keys, an old CSV returning, zero loaded events, import errors, a missing report, cancellation and an unwritable archive directory. Confirm the archived values and compact keys before accepting any deletion. Test an interrupted run by using a disposable copy, then restore the backup.

Source structure and links were checked here. Desktop Excel VBA compilation, Power Query execution, refresh synchronization and file round-trip behavior remain untested. The downloadable workbook binary has not been changed; install this addition in a test copy first.
