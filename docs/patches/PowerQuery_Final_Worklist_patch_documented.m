// ============================================================================
// QUERY TO EDIT: Final_Worklist
// TYPE: PATCH FRAGMENTS - NOT A STANDALONE M QUERY
// PURPOSE:
//   Preserve event-level DONE/IGNORE filtering with RecordID as the join key.
//   Keep MasterKey joins solely for patient/panel master details, especially
//   EffectiveMasterEntryDate.
//
// DEPENDENCIES: Actionable_Current_Events, Master_Patient_List,
//               Processed_Records.
// INPUT:  Current actionable records, patient master data, processed statuses.
// OUTPUT: Open worklist rows; DONE and IGNORE records excluded.
//
// INSTALLATION:
//   Your earlier Final_Worklist ALREADY joins processed status by RecordID.
//   Verify the steps described below; do not replace the whole query with
//   this fragment. Preserve its IssueType = "CPAR: Yes" filtering.
//
// EVENT RULE:
//   Same MasterKey + different RecordID = different processing events.
//   A DONE/IGNORE for one must not hide the other.
//
// CAUTION:
//   This patch only looks up RecordID and Status from Processed_Records.
//   Other log columns are not displayed in the active worklist by default.
// ============================================================================

// PATCH FOR EXISTING Final_Worklist QUERY
// Current query ALREADY merges status using RecordID (correct):
// Table.NestedJoin(CleanCurrentRecordID, {"RecordID"}, ProcessedByRecord,
//                  {"RecordID"}, "ProcessedMatch", JoinKind.LeftOuter)
// KEEP THIS JOIN UNCHANGED. The MasterKey join to Master_Patient_List is only
// for EffectiveMasterEntryDate and must remain separate.
//
// In ProcessedSource, retain exactly these fields for status lookup:
ProcessedSource = Table.SelectColumns(Processed_Records, {"RecordID", "Status"}, MissingField.UseNull),
//
// Retain your existing status cleaning, Group by RecordID, and DONE/IGNORE filter.
// They correctly keep different events belonging to the same MasterKey separate.
//
// DateProcessed and other metadata belong in Processed_Log / Processed_Records.
// Don't add DateProcessed to the active Final_Worklist unless you want to
// display history for open records; processed DONE rows are filtered out.
