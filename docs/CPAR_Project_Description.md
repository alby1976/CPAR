# A Dummies Guide to the CPAR Clinic Reconciliation Project

## What is this project?

A reusable Excel toolkit that helps Alberta clinics organize three CPAR report streams: **Panel Submission Results information**, **Demographic Mismatch Reports**, and **Conflict Reports**.

CPAR stands for **Central Patient Attachment Registry**. A panel is the group of patients attached to a primary care provider. Reconciliation means comparing information, investigating differences, taking the appropriate action, and checking the result.

## What is inside?

| Part | Plain meaning |
|---|---|
| Excel sheets and tables | Places to enter clinic settings, read results, and record actions. |
| 42 Power Query M definitions | Instructions that read and prepare report data. |
| VBA buttons | Programs for marking events DONE or IGNORE, undoing the latest batch, and requesting refresh. |
| Audit sheets | Places to investigate file errors, missing reports, and exclusions. |
| PCPCM_Guide | Why accurate CPAR information matters to patient care and panel-based compensation. |

## How does a clinic start?

1. Save a working copy of the cleaned macro-enabled workbook.
2. Follow README and Setup_Checklist.
3. Enter the local report root, providers, panel IDs, folder names, and expected report types.
4. Confirm that exported reports match the supported headers and metadata layout.
5. Test with fictional data before routine use.
6. Refresh, investigate exceptions, work the list, and log progress.

## Will it work with every EMR?

It is configurable for different clinics, but it is **not automatically compatible with every EMR export**. The submission parser expects the listed Ava-style fields. Other layouts may need parser and schema changes followed by validation.

## What does it not do?

The workbook does not update the EMR or provincial registry, choose the patient’s primary provider, calculate PCPCM entitlement, or confirm that payment was made.

## Which guide should I read?

| If you want to… | Read… |
|---|---|
| Use the workbook | [Workbook user manual](AHS_CPAR_User_Manual.md) |
| Understand the three reports | [Report interpretation](Understanding_CPAR_Reports.md) |
| Understand the payment-model connection | [PCPCM and CPAR](PCPCM_and_CPAR_Reconciliation.md) |

The template contains no real doctor or patient records. Receiving clinics must test Excel compilation and live refresh using their own approved workflow.
