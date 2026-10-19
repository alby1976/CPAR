// ============================================================================
// QUERY TO EDIT: Processed_Records
// TYPE: PATCH FRAGMENTS - NOT A STANDALONE M QUERY
// PURPOSE:
//   Carry the new manual processing fields from Processed_Log through the
//   combined manual/automatic processing output, without losing existing
//   automatic IGNORE, Ignore_Rules, or precedence logic.
//
// DEPENDENCIES: Processed_Log plus your existing automatic processing steps.
// INPUTS: Manual records and auto-generated ignore records.
// OUTPUT: Processed records with consistent named columns listed below.
//
// INSTALLATION:
//   Open EXISTING Processed_Records > Advanced Editor.
//   Find matching steps (Manual0/Manual, OutputColumns, etc.).
//   Apply snippets in place. DO NOT paste this file as a full query.
//   Preserve step order, commas, and your real final in-expression.
//
// MATCHING:
//   Use RecordID for status matching, manual overrides and auto precedence.
//   Never apply a DONE or IGNORE status to all records sharing MasterKey.
//
// NOTES:
//   MissingField.UseNull fills absent metadata with null; it cannot invent
//   Source, EventDate or DateProcessed for automatic records.
//   The patch does not settle conflicting duplicate statuses by itself.
// ============================================================================

// PATCH FOR EXISTING Processed_Records QUERY
// DO NOT REPLACE your whole Processed_Records query: preserve the existing
// AutoRules, Ignore_Rules, automatic ignore and manual override logic.
//
// 1. Find the step defining Manual0 or Manual.
//    Make sure that step uses the query Processed_Log, NOT a direct read of an old
//    2-column tblProcessedLog schema.
//
// 2. Find OutputColumns and replace ONLY its list of output field names with:
OutputColumns = {
    "RecordID", "MasterKey", "PanelID", "Doctor", "PatientID",
    "Source", "EventDate", "DateProcessed", "Status",
    "DateStarted", "ActionTaken", "Notes"
},
//
// 3. Make sure Manual selects with MissingField.UseNull:
Manual = Table.SelectColumns(Manual0, OutputColumns, MissingField.UseNull),
//
// 4. Keep all automatic ignore logic and precedence using RecordID.
//    If auto ignore rows don't contain metadata, append SelectColumns(...,
//    OutputColumns, MissingField.UseNull) to normalize them before combining.
//    Never join DONE/IGNORE by MasterKey or PatientID.
//
// WARNING: These are fragments, not a standalone query. Adapt step names
// to your existing actual M script, then retain the original 'in Final'.
