# A Dummies Guide to PCPCM and CPAR Reconciliation

**Checked:** October 19, 2026.

Start with one idea: an accurate list of care relationships matters both to patient care and to the panel information used under PCPCM.

## The Model

PCPCM = Primary Care Physician Compensation Model.

### Three payment components

It combines patient encounters, time for direct/indirect care and practice management, and complexity-adjusted panel payments. [1]

### Why CPAR is connected

PCPCM panel size is derived from CPAR. Your EMR list, successful CPAR attachments, and the final PCPCM panel can differ. [2]

### The practical aim

Make the recorded panel accurately reflect ongoing primary-care relationships, and verify that intended records reach the registry.

## Three Reports, Three Checks

This workbook imports three report streams. It does not calculate PCPCM payments.

### Panel Submission Results

Check whether the upload processed, totals match the intended export, and errors were investigated. A sent indicator alone does not establish successful attachment.

### Link to payment

Unresolved technical upload failures can disrupt panel-payment data. Current guidance allows up to two manual panel payments based on the last successful upload; escalate the technical problem promptly. [3]

### Demographic Mismatch

Check identity differences against verified information. Mismatches can prevent attachment; the report also identifies deceased patients remaining on panels. [4]

### Link to payment

If an intended patient did not attach successfully, the panel used for payment may not reflect the intended EMR panel. Correct and verify; do not assume each mismatch equals a fixed dollar loss.

### Conflict Report

Review attachment to more than one participating provider. Confirm ongoing care and document appropriate coordination and panel changes. [5]

### Current conflict payment rule

As of this check, conflicts do not reduce PCPCM panel payments; affected patients are included at 100% value. Future rules may change. [3,5]

### Panel-management expectation

PCPCM requires processes addressing conflicts and demographic mismatches. Keeping accurate panels is ongoing work even while conflicts remain payable. [3]

## Why Reconcile?

The goal is accurate care relationships and reliable panel data, not just a smaller Excel list.

### Care continuity

Helps identify the provider responsible for ongoing care and reduces the risk of information going to an unintended provider. [5]

### Appropriate coordination

Clarifying attachment can reduce duplicated referrals, investigations, or prescriptions. Review clinical arrangements before removing anyone. [5]

### Reliable panel information

Distinguish missing submissions, processing failures, demographic problems, and genuine changes in attachment before interpreting panel totals.

### Eligibility awareness

The usual minimum is 500 PCPCM patients; new-to-practice provisions and other rules require separate review. Escalate genuine panel-size concerns to the physician. [6]

### Documented follow-through

Record the issue, verification, action, owner, and follow-up date. Check a later successful upload/report rather than treating an Excel status as proof.

## Common Misunderstandings

Do not use these shortcuts.

### Worklist rows are not panel size

One patient may have several issues. Filtered worklist totals cannot establish the official CPAR or PCPCM panel size.

### DONE does not mean paid

Marking DONE changes this workbook’s workflow status; it does not update the EMR, fix CPAR, or confirm a payment.

### A conflict is not an automatic removal

The category and most recent confirmation date do not, by themselves, determine who should unpanel a patient. Appropriate dual attachment can occur. [5]

### No automatic dollar-loss estimate

This workbook does not assess eligibility, apply the complexity matrix, or reconcile the physician’s payment statement.

## Monthly Routine

Assign a panel administrator, an action owner, and physician review for unclear cases.

### After upload

Verify submission processing; investigate mismatches and technical errors promptly. Check the vendor-specific upload schedule. [3]

### Before the resubmission cutoff

Arrange corrections and technical support in time for resubmission up to the 20th where applicable. [3]

### When conflict reports arrive

Download on or after the 24th, review attachment, and document decisions. The workbook missing-report list is not a release-date timer. [3]

### Close the cycle

Check later source results. For payment confirmation, use official panel/payment information outside this three-report workbook.

## Current Guidance

The October 2026 manual supersedes older statements suggesting conflicts would necessarily stop being payable in April 2026.

### Primary reference

[3] PCPCM Operations Manual V5.0, October 9, 2026; sections 2.1, 6.4 and 6.6.

- Source [1]: https://www.alberta.ca/primary-care-physician-compensation-model

- Source [2]: https://www.albertadoctors.org/practice/physician-compensation/pcpcm/pcpcm-panel-size-calculation/

- Source [3]: https://www.albertadoctors.org/media/cccl2fkq/pcpcm-operations-manual-v50-oct-9-2026-source-file.pdf

- Source [4]: https://www.albertadoctors.org/resource-centre/ciicpar-resources/panels/cpar-reports/

- Source [5]: https://www.albertadoctors.org/resource-centre/ciicpar-resources/panels/pcpcm-payments-cpar-conflicts/

- Source [6]: https://www.albertadoctors.org/practice/physician-compensation/pcpcm/pcpcm-faq/

### Use with this template

These sources explain the clinical/administrative context. Each clinic must validate file compatibility, data handling, and Excel execution before routine use.

## A small example

Imagine a fictional clinic expects 800 patients in an upload, but the submission results show fewer records.

1. Check that the EMR export used the right panel and date.
2. Check the submission’s processing result and error details.
3. Review any demographic mismatches and verify correct information.
4. Make appropriate source-system corrections and arrange resubmission when needed.
5. Check the later successful result.

The missing records are a reason to investigate. They are not enough information to calculate a dollar loss.

## What should I do first tomorrow?

1. Confirm who owns monthly report downloads.
2. Agree who investigates each report and when a physician reviews uncertainty.
3. Check the last successful upload and the latest report dates.
4. Assign outstanding items a status, owner, and follow-up date.
5. Keep evidence of the action and later verification.

Read [the workbook user manual](AHS_CPAR_User_Manual.md) for the Excel steps and [the report guide](Understanding_CPAR_Reports.md) for report interpretation.
