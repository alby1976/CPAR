# CPAR Clinic Reconciliation Toolkit

Power Query M queries and Excel VBA for a local CPAR report-processing workflow.

## Purpose

Organize CPAR submission, conflict, and demographic mismatch reports into a worklist, with a record of processed actions.

This repository contains source code and documentation. Clinical reports and workbooks stay on the clinic's approved local storage.

## Repository layout

| Folder | Contents |
| --- | --- |
| `power-query/` | One query per `.m` file; filename matches the Excel query name |
| `vba/` | Exported VBA modules, classes, and worksheet code |
| `docs/` | Setup, workflow, and troubleshooting instructions |
| `examples/` | Entirely fictional examples only |

## Get started

1. See [Excel setup](docs/SETUP.md).
2. Add reviewed Power Query source files to `power-query/`.
3. Add reviewed VBA source files to `vba/`.
4. Test changes in a backup copy of the workbook before using them in the clinic.

**Status:** Source files imported. See [import status](docs/IMPORT_STATUS.md) for source dates, revisions, and validation limits. Excel execution has not been tested.

## Data handling

This repository is public. Never commit patient identifiers, patient names, dates of birth, clinical reports, real workbooks, screenshots containing patient information, or diagnostic logs containing sensitive data.

The ignore rules help exclude common data files but cannot detect sensitive information inside source code. Review every change before committing.

## Changes

Use a separate branch for each change, describe its purpose, and record how it was checked. Keep exported source files synchronized with the workbook after testing.

## A Dummies Guide to Getting Started

If this is your first time, read the guides in this order:

1. [What the project does](docs/CPAR_Project_Description.md).
2. [How to use the workbook](docs/AHS_CPAR_User_Manual.md).
3. [How to understand the three reports](docs/Understanding_CPAR_Reports.md).
4. [Why reconciliation matters under PCPCM](docs/PCPCM_and_CPAR_Reconciliation.md).

The cleaned clinic template is distributed separately from Git source. It includes configurable folders/providers, a setup checklist, and a PCPCM guide. Its parsers require compatible report layouts; different EMR exports may need adaptation. No real clinic records belong in this public repository.

The template disables example ignore rules and leaves the optional historical-conflict date filter off. Receiving clinics must validate their own reports and Excel execution before routine use.
