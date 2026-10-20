# A Dummies Guide to Using the CPAR Clinic Workbook

**Workbook:** AHS_CPAR_Reconcilation.xlsm  
**Version of this manual:** October 19, 2026  
**Applies to:** The clinic template with 18 sheets, 42 embedded M queries, current VBA buttons, and the PCPCM_Guide sheet. Structure, source embedding, and setup formulas were checked; live Excel query refresh and VBA execution remain untested.


## First, what do these words mean?

| Word | Plain meaning |
|---|---|
| Workbook | The Excel file, containing several sheets. |
| Panel | Patients attached to a primary care provider. |
| Query | Saved instructions that read and prepare report data. |
| Refresh | Run those instructions again using available source files. |
| Generated output | A result Excel can replace during refresh. |
| Reconcile | Compare records, investigate differences, and document the appropriate action. |

**First task:** Open README, then complete Setup_Checklist. Do not begin by editing the M code.

## 1. Your five-step routine

1. Download the three supported report types.
2. Save each report in the correct doctor and source folder.
3. In Excel, select **Data → Refresh All** and wait for completion.
4. Review **File_Errors**, **Missing_Expected_Reports**, and **File_Import_Log**.
5. Work from **Worklist_Output** and record progress in **Processed_Log**.

**An empty worklist does not establish that everything is resolved. Check the input files and refresh results first.**

## 2. What this workbook does

CPAR means Central Patient Attachment Registry. This workbook supports reconciliation using:

| Input | Purpose |
|---|---|
| CPAR submission export / Panel Submission Results information | Review submission issues and unable-to-send reasons. An EMR “sent” indicator is not the same as provincial processing confirmation. |
| Demographic Mismatch Report | Review differences between submitted patient demographics and provincial registry details. |
| Conflict Report | Review patients reported on multiple participating providers’ panels. |

The workbook reads local files, standardizes their contents, applies matching and filtering rules, and produces a worklist. It also provides import and exception queues.

It does not make changes in Ava, contact patients or other clinics, or submit corrections to the provincial registry. Those actions remain part of the clinic’s workflow.

## 3. Before you start

- Use the clinic’s Windows desktop Excel installation with Power Query available.
- Keep the workbook as **.xlsm** so its embedded VBA project is preserved.
- Confirm you can access the clinic report folder using File Explorer.
- Make a dated backup before changing configuration or queries.
- Use approved local storage for reports, workbooks, and backups.
- Keep source reports unchanged. Do not remove their preamble, rename their headers, or re-save dates merely to make them look tidier.

The current VBA is embedded. Worklist_Output has **Mark Done**, **Mark Ignore**, **Undo Last**, and **Refresh All** buttons. Enable reviewed macros according to clinic policy. If you use manual logging, follow section 9. A macro is a small program that performs a workbook action for you.

## 4. Know which sheets you can edit

| Sheet | Role | What you should do |
|---|---|---|
| README | Start-here guide | Follow the setup steps and check report compatibility. |
| Folder_Config | Report root and settings | Edit approved configuration values. |
| Setup_Checklist | Setup and acceptance checks | Mark progress after completing each check. |
| Dashboard | Summary indicators | Review after a completed refresh. |
| Doctor_Config | Doctor, panel, and folder mapping | Maintain carefully. |
| Report_Expectations | Required report types per panel | Maintain approved expectations. |
| Report_Expectation_Exceptions | Dated exceptions to expectations | Add only justified exceptions. |
| Ignore_Rules | Configurable exclusions | Edit only under the clinic’s agreed rules. |
| Master_Input | Historical date overrides | Normally leave empty. |
| Worklist_Output | Generated actionable work | Filter and review; do not enter permanent notes here. |
| Processed_Log | Permanent manual action history | Enter or update workflow records here. |
| Master_Patient_List | Generated historical reference | Review; do not edit generated rows. |
| File_Import_Log | Generated file audit | Review file identity, dates, and validation. |
| File_Errors | Generated error queue | Investigate and fix the underlying input or setup. |
| Ignored_Records | Generated exclusion audit | Review why records were excluded. |
| Missing_Expected_Reports | Generated missing-report queue | Check the period and source files. |
| State_Changes | Generated comparison with previous reports | Review changes; disappearance does not mean completion. |
| PCPCM_Guide | Payment-model link and why reconciliation matters | Read the current-rule summary and linked official sources. |

**Generated outputs can be replaced on refresh. Record permanent work in input tables or the EMR, not in output cells.**

## 5. One-time setup

### A. Set the root folder

1. Open **Folder_Config**.
2. Locate the row whose Setting is **AHS_Root_Folder**.
3. Enter the approved root path in its **Value** cell.
4. Open the same path in File Explorer to confirm access.
5. Preserve the setting name and the table’s headers.

The template has no real clinic path. The example is only an example. A mapped drive available on one workstation may be unavailable on another. Use the clinic’s approved path. A blank or inaccessible root now produces a setup error instead of being treated as a successful empty scan.

The sheet also contains Archive_Folder and Reject_Unmapped_Doctor settings. A setting’s presence does not establish that every query uses it. Do not assume an archive operation or rejection behavior has occurred without checking the results.

### B. Create the folders

Use one doctor folder below the root. The actual embedded folder reader recognizes:

| Folder level | Example name | What belongs there |
|---|---|---|
| Root | AHS_Reports | Doctor folders |
| Doctor | Dr_Example | One provider’s source folders |
| Source | CPAR | Submission exports |
| Source | CONFLICTS | Conflict reports |
| Source | REGISTRY **or** DEMOGRAPHIC_MISMATCH | Demographic mismatch reports |

For example: `AHS_Reports\Dr_Example\CPAR\`.

Use the folder names above. The reader inspects the expected folder levels; do not assume it searches arbitrarily nested archive folders. Use one demographic folder convention consistently.

### C. Match doctors to panels

1. Open **Doctor_Config**.
2. Enter Doctor, PanelID, and FolderName inside **tblDoctorConfig**.
3. Make FolderName match the actual folder name.
4. Set Active to TRUE for a participating panel.
5. Confirm PanelID against the source report.
6. Avoid conflicting duplicate configuration rows.

The template has no configured providers. Enter your own. An active row must have Doctor, PanelID, and FolderName. Duplicate active panel IDs or folder names produce a setup error. Leave unused rows blank.

### D. Set expected reports

In **Report_Expectations**, use the exact report types:

- `CPAR`
- `CONFLICT`
- `DEMOGRAPHIC_MISMATCH`

Set Expected to TRUE for each required panel/type combination. METRICS entries exist in the workbook, but metrics are outside this project’s three-report scope.

Use **Report_Expectation_Exceptions** only when a particular panel/type should legitimately not be expected for a stated date range. Enter the dates and reason carefully. Do not suppress a missing-file warning simply because a report has not been downloaded.

### E. Preserve table boundaries

When adding an input row, type within the Excel table. If necessary, click its final cell and press **Tab** to add a row. To verify that a row belongs to a table, click it and check whether **Table Design** appears.

Do not rename tables such as tblProcessedLog or delete their header rows.

## 6. Download and file reports

1. Confirm the provider and panel before downloading.
2. Save the report in that doctor’s corresponding source folder.
3. Preserve meaningful filenames and report dates.
4. Keep historical files available to the query reader when they are needed for first-seen dates and comparisons.
5. Save corrections as controlled replacements or clearly identified versions according to clinic practice; inspect duplicate handling after refresh.

A CPAR filename example used by the workbook is `CPAR_Submission_Summary_2026-04-06_00-00-00.csv`. Conflict and mismatch parsers use report metadata/preamble information. Renaming a file’s date does not necessarily change the date extracted from its contents.

Current AMA guidance gives Ava’s automatic upload as the **6th**, demographic mismatch availability **two days after upload**, conflict availability on the **24th**, and resubmission up to the **20th**. Submission results depend on processing completion. These are download-planning dates, not a guarantee that a particular upload succeeded. [1]

## 7. Refresh and decide whether the results are trustworthy

1. Save the workbook.
2. Select **Data → Refresh All**.
3. Open **Data → Queries & Connections** to monitor refresh activity and errors.
4. Wait until refresh activity has completed before reviewing final counts.
5. Check **File_Errors**.
6. Check **Missing_Expected_Reports**.
7. Check **File_Import_Log** for the intended provider, source, and report date.
8. Review **Dashboard** and then **Worklist_Output**.

Do not repeatedly click Refresh All while a refresh is already running.

### Read the audit sheets

| Field or result | What to check |
|---|---|
| FolderStatus | Is the file in a recognized folder? |
| ImportStatus / ErrorMessage | Could the file be read? |
| SchemaStatus / MissingColumns | Are required headers present? |
| DoctorValidation | Does report metadata agree with configuration? |
| DuplicateStatus | Was a file treated as a duplicate? |
| ReportDate | Did the parser identify the intended reporting date? |
| ParsedRowCount | Is the parsed count plausible for that report? |

A file appearing in File_Import_Log is evidence of discovery, not sufficient evidence that it contributed usable records.

### Understand missing-report warnings

The embedded Missing_Expected_Reports query selects its target month from the **newest valid indexed report date**, not directly from today’s calendar date.

Consequences:

- An early-month submission can move expectations into the new month before that month’s conflict report is available.
- If every file is old, a missing-report result may still concern an old month.
- If there are no valid dates, the query can fail rather than produce a useful missing-report list.

Always read PeriodStart, PeriodEnd, ReportType, and LatestReportDate before deciding what is missing.

## 8. Work through Worklist_Output

1. Open **Worklist_Output**.
2. Use the Doctor header filter to select one provider.
3. Filter Source to work on one report stream at a time.
4. Verify the patient and review the issue against the original report.
5. Investigate and perform the appropriate action in the EMR or clinic workflow.
6. Record progress in Processed_Log.
7. Refresh when ready to recalculate the worklist.

The attached table has 14 columns:

| Column | Meaning |
|---|---|
| RecordID | Key for the individual work item; copy it exactly when logging work. |
| MasterKey | Key used to match the patient/panel within the toolkit. |
| PanelID / Doctor | Panel context. |
| PatientID | Patient identifier; verify identity before changing a record. |
| Source | Input stream that produced the item. |
| EventDate | Date derived by that source’s query. |
| EffectiveMasterEntryDate | Historical comparison date, including an override when used. |
| LastName / FirstName / DOB | Patient identification information available in this output version. |
| IssueType | Toolkit classification of the item. |
| ConflictRule | Result of the workbook’s conflict-date rule. |
| ProcessedStatus | Status matched from the processing layer. |

The attached output does **not** include all the registry comparison fields or UNABLE_TO_SEND_REASON requested in later project work. Use the original report when those details are absent. This manual does not assume later patches are installed.

## 9. Record progress in Processed_Log

### Add an item manually

1. Copy the selected work item’s identifying fields from Worklist_Output.
2. Open **Processed_Log**.
3. Click inside **tblProcessedLog**.
4. Search the RecordID column for an existing entry. Update it rather than adding a duplicate.
5. If new, use the first blank table row or add a table row.
6. Fill the matching fields and workflow details.
7. Save the workbook, then refresh to update the generated output.

| Log column | What to enter |
|---|---|
| RecordID | Exact worklist value; required for matching. |
| MasterKey | Exact worklist value. |
| PanelID, Doctor, PatientID, Source, EventDate | Corresponding values from the same row. |
| Status | Use a supported status below. |
| DateStarted | Actual date work started. |
| DateProcessed | Actual completion/processing date under clinic practice. |
| ActionTaken | Brief factual description of the action. |
| Notes | Relevant follow-up or explanation. |

Use **Paste Special → Values** where needed. Keep identifier columns as text so Excel does not alter them.

### Status meanings

| Status | Intended workflow use | Final_Worklist behavior |
|---|---|---|
| PENDING | Work still needs attention | Not removed solely by this status |
| WAITING | Waiting for a response or next step | Not removed solely by this status |
| REVIEW | Requires further review | Not removed solely by this status |
| DONE | Action complete under clinic procedure | Suppressed when the RecordID matches |
| IGNORE | Deliberately excluded with a documented reason | Suppressed when the RecordID matches |

**Use IGNORE, not IGNORED, for the manual terminal status in this version.**

The Final_Worklist query also excludes IssueType `CPAR: Yes`. Source changes and other rules can affect visibility independently of manual status.

### If the log is empty

An empty log is normal before any work has been recorded. Keep tblProcessedLog and its headers. The Processed_Log query filters out rows with blank RecordID values.

Use the existing blank table row for the first entry. If refresh fails with an empty log, record the exact query/error and investigate; do not invent a patient record to make the table nonempty.

### Correct a mistaken completion

Find the original log row, document the correction, and change its status appropriately. Check for duplicate RecordIDs: Final_Worklist gives terminal statuses priority, so another DONE/IGNORE row can keep the item hidden. Refresh, and remember that the item must still satisfy current source/actionability rules to reappear.

## 10. Ignore rules, historical dates, and state changes

### Ignore_Rules

The template contains two example CPAR unable-to-send rules, both disabled (Active = FALSE and AutoProcess = FALSE). Review them with the clinic before enabling exclusions. Disabled examples do not represent resolved patient issues.

EXACT compares the full value; CONTAINS searches within it. The inspected matching function trims text and compares without case sensitivity. Keep RuleID, Source, FieldName, MatchType, MatchValue, Active, and Reason consistent. AutoProcess and AutoStatus also affect the automatic-processing layer.

Check **Ignored_Records** after changes. Rule exclusion is not evidence that a clinical issue was corrected.

### Master_Input

Normally leave this sheet empty. For a verified historical exception, enter PanelID, the correctly formatted PatientID, OverrideMasterEntryDate, Reason, and Active.

The effective date uses the override when present; otherwise it uses the inferred FirstSeenDate. That date reflects the available input history, not necessarily the patient’s true first-ever clinic attachment.

### ConflictRule

| Value | Meaning in the inspected query |
|---|---|
| KEEP_NO_MASTER | No effective master date was available |
| KEEP_NO_EVENT_DATE | No event date was available |
| KEEP_NEW_CONFLICT | EventDate is later than EffectiveMasterEntryDate |
| OLD_CONFLICT | EventDate is equal to or earlier than EffectiveMasterEntryDate; retained by default and excluded only when Apply_Conflict_Date_Filter is TRUE |

These are workbook rules, not provincial clinical decisions. **Apply_Conflict_Date_Filter is FALSE by default**, so this date rule does not automatically exclude older conflicts. Only enable it after reviewing the clinic’s process. When enabled, a date override can change which conflicts reach the worklist.

### State_Changes

NEW_OR_REAPPEARED and STILL_PRESENT describe source presence. NO_LONGER_REPORTED describes absence from the compared current source. None automatically proves that a manual action was completed.

## 11. Troubleshooting

| Problem | What to check first |
|---|---|
| Zero worklist rows | Clear filters; confirm refresh completed; check errors, expected reports, report dates, and processing/ignore rules. |
| No files discovered | Open the configured root in File Explorer; check doctor/source folder names and folder depth. Folder-read failures can return empty tables. |
| A report seems missing | Confirm panel/type/date, filename, metadata, schema, duplicate status, and target period. |
| DONE item remains visible | Check exact RecordID, table membership, status spelling, and successful refresh. |
| PENDING item does not reappear | Check duplicate terminal statuses, current source presence, and other filters/rules. |
| Patient appears more than once | Compare panel, source, event, and RecordID; patient-level repetition is not automatically a duplicate. |
| Refresh is slow | Wait for the current refresh; capture the slow query and errors; test changes in a backup copy. Do not delete history as the first fix. |
| Header or schema error | Preserve the original report and ask the maintainer to review parser/schema expectations. |
| Changes vanished | Check whether you typed into generated output instead of an input table. |
| Setup status remains incomplete | Enter the root, at least one active provider, and expected report entries. The Dashboard setup check confirms entries exist; it does not validate actual report processing. |

## 12. End-of-cycle checklist

- Confirm the intended reports were received or exceptions were explained.
- Review errors and report dates before accepting dashboard counts.
- Save action history and follow-up notes.
- Confirm required EMR actions were actually made.
- Save the workbook and a controlled backup.
- Keep the report history required by the queries accessible.
- Check a later successful submission/report before treating a source correction as verified.

## References and scope

[1] [AMA — Monthly CPAR Upload Schedule](https://www.albertadoctors.org/resource-centre/ciicpar-resources/emr/monthly-cpar-upload-schedule/), checked October 19, 2026.

Workbook-specific instructions come from the supplied workbook. The separate **Understanding_CPAR_Reports.md** guide explains report interpretation in more detail.

The template was checked for file structure, embedded sources, button assignments, and setup-formula behavior. Live Excel refresh, network access, and VBA execution still require testing at the receiving clinic.


## 13. Use the buttons: a small practice task

Use a separate test workbook containing only fictional records.

1. Select one cell inside a fictional Worklist_Output data row.
2. Click **Mark Done**.
3. Open Processed_Log and check the copied RecordID, MasterKey, panel metadata, status, and processing timestamp.
4. Confirm a different RecordID belonging to the same fictional patient was not completed.
5. Click **Undo Last** in Worklist_Output. Check that the newest batch was reversed.
6. Repeat with **Mark Ignore**. Record why ignoring is appropriate.
7. Refresh and check which items remain. Do not assume the refresh finished just because you clicked the button.

Undo works for the latest successful button batch in the current Excel session. It does not undo an EMR change, patient conversation, or other external action. Select only intended visible rows: a selection spanning filtered-out rows can still include them in the current VBA.

## 14. Why the work matters

Read PCPCM_Guide in the workbook. PCPCM includes a panel-payment component, and accurate CPAR records help represent ongoing care relationships. As checked October 19, 2026, conflicts remain included at 100% value; do not describe each conflict as an automatic payment loss. See [PCPCM and CPAR guide](PCPCM_and_CPAR_Reconciliation.md) for the payment-model explanation and current official references.
