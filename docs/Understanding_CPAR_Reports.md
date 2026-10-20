# A Dummies Guide to Understanding the Three CPAR Reports
A practical guide for the CPAR Reconciliation Toolkit  
Prepared October 19, 2026

## Start here: three different questions

CPAR means **Central Patient Attachment Registry**. A panel is the group of patients attached to a primary care provider.

| Report | Question it helps answer |
|---|---|
| Panel Submission Results | Did the submitted file process, and which records need investigation? |
| Demographic Mismatch Report | Which patient details differ between the submitted panel and the provincial registry? |
| Conflict Report | Which patients are attached to more than one participating provider? |

This guide covers only these three reports. It distinguishes official report information from columns added by this Excel toolkit. Field labels can vary by export.

## 1. Panel Submission Results

### What to read

Check the provider/panel, submission date, processing status, total records, and processed/unprocessed counts. “Complete with Errors” requires reviewing the error details. Compare the file’s total with the EMR panel count for that submission. [1]

### How to work through it

1. Confirm you opened the intended provider’s submission.
2. Check that its date matches the upload you are investigating.
3. If processing is unfinished, check again after completion.
4. If there are errors, read each actual message before choosing an action.
5. Compare counts using the same panel and submission date.
6. Record what you investigated and verify the outcome after the next successful submission.

**Important:** A processed file does not, by itself, prove that every intended patient is successfully attached. Read the detailed results.

### Submission-related columns used by this project

| Column | How to interpret it |
|---|---|
| PHN / PatientID | Identifier used to locate the patient. Verify identity before making changes. |
| SENT TO CPAR | Submission indicator in the source export; interpret using that export’s definitions. |
| UNABLE_TO_SEND_REASON | Source explanation for why a record could not be sent. Preserve the original reason when investigating. |
| Doctor / PanelID | Provider and panel assigned by the toolkit’s configuration. Confirm the mapping is correct. |

An EMR export indicating that a record was sent is a different piece of evidence from CPAR confirming its processing. Keep those stages separate.

**Practice example — invented counts:** Your EMR panel list has 800 patients, but the submitted file contains 760. First investigate the missing 40 records and the export criteria. Do not assume the registry received all 800.

## 2. Demographic Mismatch Report

### What it means

It compares submitted patient demographics with the Provincial Client Registry (PCR). Either side can need correction. It also identifies deceased patients; these can instead appear as upload errors on an initial submission. [1]

### Read the values side by side

| Panel/EMR field | Registry field | Question to ask |
|---|---|---|
| PatientID | Alberta Registry Patient Id | Do the identifiers refer to the same person? |
| LastName | Alberta Registry Patient Last Name | Is the registered surname different? |
| FirstName | Alberta Registry Patient First Name | Is the registered first name different? |
| Panel Gender | Alberta Registry Gender | What value was submitted, and what is registered? Verify the EMR field mapping. |
| DOB | Alberta Registry Date Of Birth | Is there a date difference or a possible identity issue? |
| — | Date Of Death | Does this require verified status review under the clinic’s process? |

These are project/export labels; they are not a promise that every version of the provincial report uses identical headings.

### How to work through a row

1. Confirm the doctor, panel, report date, and patient.
2. Identify the exact field that differs.
3. Verify the information using the clinic’s approved identity and demographic-checking process.
4. Correct the EMR if its value is wrong. If the provincial record needs correction, follow the appropriate provincial correction process.
5. Document the action and check a later report following a successful upload.

**Practice example — fictional patient:** The submitted surname is “CHAN” and the registry surname is “WONG.” This comparison alone cannot tell you which is correct. Verify before editing.

A blank field is missing information, not proof that the opposite value is correct. An empty mismatch report also does not prove that the upload succeeded; check submission results.

## 3. Conflict Report

### What it means

The patient appears on multiple participating providers’ panels. The report can show confirmation dates, visit dates, the other provider’s details, and when the conflict was first reported. [1]

### How to read it

| Field | Meaning and practical use |
|---|---|
| Patient identifier and demographics | Confirm the patient before discussing attachment. |
| Conflict First Reported | Shows when the conflict was first reported; useful for reviewing unresolved items. |
| Last Confirmation Date | When the relationship was last confirmed at that clinic. |
| Last Visit Date | Visit timing; it is a different event from confirming attachment. |
| Conflicting provider/facility | Identifies the other clinic involved. |
| Role/expertise | Helps staff recognize arrangements that need provider review. |

A recent visit or confirmation date is context, not an automatic instruction to remove the patient.

### Category 1 and Category 2 — a beginner’s guide

**Start with this question: “When did each clinic last confirm that this patient belongs on its provider’s panel?”**

Compare the **Last Confirmation Dates**. Do not use the last visit date, report date, or download date to interpret these categories.

| Category | In everyday language | What it tells you |
|---|---|---|
| **1** | “One provider’s confirmation is at least 30 days newer than the other provider’s confirmation.” | The confirmations are farther apart. Check which provider has the newer confirmation. |
| **2** | “The providers confirmed the patient on the same day or close together—within 30 days.” | The confirmations are close together. The category alone does not settle which provider should continue the attachment. |

These explanations follow the AHS definitions supplied for this guide and the category descriptions in the Panel Administrator Handbook. [1]

#### Example 1: Category 1 — confirmations farther apart

Imagine these fictional dates:

| Provider | Last Confirmation Date |
|---|---|
| Dr. A | January 1, 2026 |
| Dr. B | March 15, 2026 |

Dr. B’s confirmation is **73 days newer**. This fits Category 1.

**What to do:** Notice that Dr. B has the newer confirmation, then verify the patient’s ongoing care arrangement. This does not automatically mean Dr. A must remove the patient.

#### Example 2: Category 2 — confirmations close together

| Provider | Last Confirmation Date |
|---|---|
| Dr. A | March 1, 2026 |
| Dr. B | March 15, 2026 |

The dates are **14 days apart**. This fits Category 2. Confirmations on the **same day** also fit Category 2.

**What to do:** Review the attachment with the patient and provider under the clinic’s process. The category does not choose a provider for you.

#### What if the dates are exactly 30 days apart?

The supplied wording overlaps at this boundary: Category 1 says **30 days or more**, while Category 2 says **within 30 days**. Use the category already assigned on the official report. If you need to calculate categories yourself, ask CPAR support to confirm the exact boundary rule first.

#### How to use the category in five steps

1. Confirm you have the correct patient and panel.
2. Read the **Conflict Category** shown on the report.
3. Compare each provider’s **Last Confirmation Date**.
4. Review the patient’s current care arrangement; involve the provider when needed.
5. Document the decision and any action, then check a later report.

**Remember:** Category 1 does not mean “our clinic wins,” and Category 2 does not mean “the patient must be removed.” Both describe confirmation-date timing. Neither category, by itself, is an instruction to unpanel a patient. The workbook’s **ConflictRule** is a separate toolkit rule and is not the same as the report’s Category 1 or Category 2.

### How to work through a conflict

Confirm the patient’s ongoing primary-care arrangement, involve the provider when unclear, coordinate with the other clinic as appropriate, and document the outcome. Some dual attachments are appropriate, including certain specialty arrangements. Do not automatically unpanel every reported conflict. [3]

**Practice example — fictional patient:** A patient has a recent visit at Clinic B while remaining attached to Clinic A. Ask about their ongoing care arrangement before deciding what needs changing.

## 4. Dates: report availability and record history

### Start with your EMR’s upload date

Different EMRs upload on different days. Current AMA guidance lists the following schedule. [2]

| EMR | Automatic monthly upload |
|---|---|
| Accuro | 2nd |
| CHR | 4th |
| Ava | 6th |
| Juno | 7th |
| Healthquest | 8th |
| Okaki | 9th |
| Med Access / PS Suite | 11th or 12th |

These upload dates do not prove that this workbook supports every EMR’s export layout. Check the required headers and parser compatibility.

| Milestone | Expected timing |
|---|---|
| Automatic panel upload | 6th of each month |
| Demographic Mismatch Report | Two days after upload; normally around the 8th |
| Panel resubmission cutoff | Up to the 20th |
| Conflict Report | 24th |
| Panel Submission Results | Check once the particular upload has processed; no fixed release day is stated here |

The milestone table uses Ava as its example. Other clinics should start from their own upload date. These dates follow the current AMA schedule. A failed or delayed upload can affect the practical review date. Older handbook timing should not replace the current schedule. [2]

### Do not mix up these dates

| Date | What to keep separate |
|---|---|
| Upload/submission date | When the panel was submitted |
| Report date | Date assigned to the report |
| Download date | When staff saved a copy |
| Conflict first reported | Start of the reported conflict history |
| Last confirmation / last visit | Two separate relationship and visit events |
| EventDate in the toolkit | A query-derived date; inspect the source-specific mapping before using it as a clinical or submission date |
| EffectiveMasterEntryDate | A toolkit comparison date, not an official report release date |

Compare like with like. A download made today can still contain an older report.

## 5. Understanding the combined Excel worklist

| Toolkit column | How to use it |
|---|---|
| Source | Identifies which input stream produced the item. |
| IssueType | Toolkit classification; read it with the original report information. |
| RecordID | Identifier used by the processing workflow for an individual item/event. |
| MasterKey | Key used for matching across the toolkit. It is not proof of patient identity. |
| ProcessedStatus | Internal workflow status; does not establish that CPAR accepted a correction. |
| ConflictRule | Toolkit rule result; does not replace reviewing the original conflict details. |

Use this sequence: **read the source → verify the issue → act in the appropriate system → record the action → verify a later result**.

Mark an item complete only when it meets the clinic’s completion rule. If an item is ignored, document why and whether follow-up is needed. Clearing an Excel worklist item does not update the EMR or CPAR.

## Sources

1. [AMA — CPAR Panel Administrator Handbook](https://www.albertadoctors.org/media/o5uk0x0e/cpar-panel-administrator-handbook.pdf), April 2023, especially pages 6, 9–10, and 14–16. Used for report interpretation; its historical schedule is superseded by source 2.
2. [AMA — Monthly CPAR Upload Schedule](https://www.albertadoctors.org/resource-centre/ciicpar-resources/emr/monthly-cpar-upload-schedule/), checked October 19, 2026.
3. [AMA — CPAR Conflicts](https://www.albertadoctors.org/resource-centre/ciicpar-resources/panels/cpar-conflicts/), checked October 19, 2026.

Project-specific explanations describe how to read the exported fields and toolkit labels. They do not certify that the imported queries or macros have passed Excel execution testing.


## 6. Why checking these reports matters under PCPCM

Think of it as three checks: **Did the information get there? Does the patient information match? Is the care relationship recorded correctly?**

PCPCM is the Primary Care Physician Compensation Model. It includes encounter, time, and complexity-adjusted panel payments. CPAR information helps determine the panel used under the model. A smaller Excel worklist is not proof of correct attachment or correct payment.

As checked October 19, 2026, conflicts remain payable at 100% value, but this may change. Clinics are still expected to maintain processes addressing conflicts and demographic mismatches. See [A Dummies Guide to PCPCM and CPAR Reconciliation](PCPCM_and_CPAR_Reconciliation.md).

Current reference: [PCPCM Operations Manual V5.0, October 9, 2026](https://www.albertadoctors.org/media/cccl2fkq/pcpcm-operations-manual-v50-oct-9-2026-source-file.pdf), especially sections 2.1, 6.4, and 6.6.
