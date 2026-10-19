Attribute VB_Name = "CPAR_Worklist_Actions"
Option Explicit

' ================================================================
' CPAR WORKLIST ACTIONS - DOCUMENTED VERSION
' ================================================================
' This file is the original VBA logic with explanatory comments added.
' Required workbook tables: tblFinalWorklist and tblProcessedLog.
' The source is Power Query output; the log is the persistent manual ledger.
' Use event-level RecordID to locate/update actions.
' MasterKey is copied for grouping/auditing; it does NOT mark other events.
' ================================================================
' Source: tblFinalWorklist; destination: tblProcessedLog.
' The log retains one row per RecordID and is the permanent action register.
Private Const WORKLIST_TABLE As String = "tblFinalWorklist"
Private Const LOG_TABLE As String = "tblProcessedLog"

' Names must match the Excel table headers exactly.
' LOGFIELDS: canonical set of nine columns written to tblProcessedLog.
' Changing this list requires matching headers in the destination table.
' Status and DateProcessed are generated, all other fields come from the worklist.
Private Function LogFields() As Variant
    LogFields = Array("RecordID", "MasterKey", "PanelID", "Doctor", _
                      "PatientID", "Source", "EventDate", "DateProcessed", "Status")
End Function

' One undo snapshot per action: array(RecordID, existedBefore, oldRowValues,
'                                      oldWorkStatus). Only the most recent batch.
' SESSION-ONLY UNDO STORAGE
' Each snapshot stores RecordID, whether the log row existed, prior nine
' log cell values (if any), and prior worklist ProcessedStatus.
' A later DONE/IGNORE action replaces this snapshot.
Private mUndo As Collection

' BUTTON: MarkDone
' Delegates to the common processor using status DONE.
Public Sub MarkDone()
    MarkSelectedRows "DONE"
End Sub

' BUTTON: MarkIgnore
' Delegates to the common processor using status IGNORE.
Public Sub MarkIgnore()
    MarkSelectedRows "IGNORE"
End Sub

' BUTTON: RefreshAllNow
' Requests workbook Refresh All. Refresh completion may be asynchronous.
' Does not check whether the queries finished or succeeded.
Public Sub RefreshAllNow()
    ThisWorkbook.RefreshAll
End Sub

' CORE WORKFLOW: MARK SELECTED ROWS
' 1) Locate tables, validate required headers, intersect selected cells with
'    tblFinalWorklist, and deduplicate selected physical row numbers.
' 2) For each selected nonblank RecordID, find a matching log row.
' 3) Snapshot previous values for UNDO; update or append one log row.
' 4) Copy seven worklist fields, set Status, and timestamp DateProcessed.
' 5) Display the status in Final Worklist without refreshing queries.
' CAUTION: writes are not transactional: an error mid-batch may leave some
' processed rows saved and undo storage unchanged. Inspect log on failure.
Private Sub MarkSelectedRows(ByVal NewStatus As String)
    Dim loWork As ListObject, loLog As ListObject
    Dim selectedRows As Range, area As Range, aRow As Range
    Dim rowsToProcess As Object, key As Variant, names As Variant
    Dim rowIndex As Long, logIndex As Long, n As Long, i As Long
    Dim recordID As String, sourceField As String
    Dim target As ListRow, oldData As Variant, oldWorkStatus As Variant
    Dim newSnapshot As Collection, processedCount As Long
    Dim whenProcessed As Date
    Dim oldEvents As Boolean, oldScreen As Boolean

    On Error GoTo ErrorHandler
    oldEvents = Application.EnableEvents
    oldScreen = Application.ScreenUpdating
    Application.EnableEvents = False
    Application.ScreenUpdating = False

    Set loWork = FindTableByName(WORKLIST_TABLE)
    Set loLog = FindTableByName(LOG_TABLE)
    If loWork Is Nothing Or loLog Is Nothing Then
        Err.Raise vbObjectError + 1000, , _
            "Required Excel table missing. Expected " & WORKLIST_TABLE & " and " & LOG_TABLE & "."
    End If

    names = LogFields()
    For i = LBound(names) To UBound(names)
        If Not TableHasColumn(loLog, CStr(names(i))) Then
            Err.Raise vbObjectError + 1001, , "Missing log column: " & CStr(names(i))
        End If
        If CStr(names(i)) <> "Status" And CStr(names(i)) <> "DateProcessed" Then
            If Not TableHasColumn(loWork, CStr(names(i))) Then
                Err.Raise vbObjectError + 1002, , "Missing worklist column: " & CStr(names(i))
            End If
        End If
    Next i
    If Not TableHasColumn(loWork, "ProcessedStatus") Then
        Err.Raise vbObjectError + 1003, , "Missing worklist column: ProcessedStatus"
    End If
    If loWork.DataBodyRange Is Nothing Then
        MsgBox "Final Worklist has no rows.", vbInformation
        GoTo SafeExit
    End If
    If TypeName(Selection) <> "Range" Then
        MsgBox "Select one or more cells in Final Worklist.", vbExclamation
        GoTo SafeExit
    End If
    Set selectedRows = Intersect(Selection, loWork.DataBodyRange)
    If selectedRows Is Nothing Then
        MsgBox "First select a row inside " & WORKLIST_TABLE & ".", vbExclamation
        GoTo SafeExit
    End If

    ' One physical table row per action even if many cells were selected.
    ' NOTE: manually selected hidden/filtered rows can still be included.
    Set rowsToProcess = CreateObject("Scripting.Dictionary")
    For Each area In selectedRows.Areas
        For Each aRow In area.Rows
            rowIndex = aRow.Row - loWork.DataBodyRange.Row + 1
            rowsToProcess(CStr(rowIndex)) = rowIndex
        Next aRow
    Next area

    Set newSnapshot = New Collection
    ' ONE timestamp shared by all selected rows in this button click.
    whenProcessed = Now
    For Each key In rowsToProcess.Keys
        rowIndex = CLng(rowsToProcess(key))
        recordID = Trim$(CStr(loWork.DataBodyRange.Cells( _
                       rowIndex, loWork.ListColumns("RecordID").Index).Value2))
        If Len(recordID) > 0 Then
            ' Only RecordID is used to decide whether the event was processed.
            ' Never use MasterKey here: a patient may have multiple issues.
            logIndex = FindRecordRow(loLog, recordID)
            oldWorkStatus = loWork.DataBodyRange.Cells( _
                              rowIndex, loWork.ListColumns("ProcessedStatus").Index).Value2

            If logIndex > 0 Then
                Set target = loLog.ListRows(logIndex)
                ReDim oldData(LBound(names) To UBound(names))
                For i = LBound(names) To UBound(names)
                    oldData(i) = target.Range.Cells(1, loLog.ListColumns(CStr(names(i))).Index).Value2
                Next i
                newSnapshot.Add Array(recordID, True, oldData, oldWorkStatus)
            Else
                newSnapshot.Add Array(recordID, False, Empty, oldWorkStatus)
                Set target = loLog.ListRows.Add
            End If

            ' Copy RecordID, MasterKey, PanelID, Doctor, PatientID,
            ' Source, EventDate; generate DateProcessed and Status.
            For i = LBound(names) To UBound(names)
                sourceField = CStr(names(i))
                Select Case sourceField
                    Case "Status"
                        target.Range.Cells(1, loLog.ListColumns(sourceField).Index).Value = NewStatus
                    Case "DateProcessed"
                        target.Range.Cells(1, loLog.ListColumns(sourceField).Index).Value = whenProcessed
                    Case Else
                        target.Range.Cells(1, loLog.ListColumns(sourceField).Index).Value = _
                            loWork.DataBodyRange.Cells(rowIndex, loWork.ListColumns(sourceField).Index).Value
                End Select
            Next i
            loWork.DataBodyRange.Cells( _
                rowIndex, loWork.ListColumns("ProcessedStatus").Index).Value = NewStatus
            processedCount = processedCount + 1
        End If
    Next key
    If processedCount > 0 Then
        Set mUndo = newSnapshot
        MsgBox processedCount & " record(s) marked " & NewStatus & _
               " and saved to " & LOG_TABLE & ".", vbInformation
    Else
        MsgBox "No selected rows had a RecordID.", vbInformation
    End If

SafeExit:
    Application.EnableEvents = oldEvents
    Application.ScreenUpdating = oldScreen
    Exit Sub
ErrorHandler:
    MsgBox "Action failed: " & Err.Description & vbCrLf & _
           "If some rows were written, check the log before retrying.", vbCritical
    Resume SafeExit
End Sub

' BUTTON: UndoLastAction
' Reverses only the most recent successful batch within this Excel session.
' Existing rows: restore the nine old log fields; newly added rows: delete.
' Also restores ProcessedStatus if the matching worklist row still exists.
' Does NOT reverse external Power Query effects or previous batches.
Public Sub UndoLastAction()
    Dim loWork As ListObject, loLog As ListObject
    Dim snapshot As Variant, names As Variant, oldData As Variant
    Dim i As Long, j As Long, logIndex As Long, workIndex As Long
    Dim oldEvents As Boolean, oldScreen As Boolean
    On Error GoTo ErrorHandler
    If mUndo Is Nothing Then
        MsgBox "No recent action to undo in this Excel session.", vbInformation
        Exit Sub
    End If
    If mUndo.Count = 0 Then Exit Sub

    Set loWork = FindTableByName(WORKLIST_TABLE)
    Set loLog = FindTableByName(LOG_TABLE)
    If loLog Is Nothing Then Err.Raise vbObjectError + 1004, , "Missing processed log table."
    names = LogFields()
    oldEvents = Application.EnableEvents
    oldScreen = Application.ScreenUpdating
    Application.EnableEvents = False
    Application.ScreenUpdating = False

    For i = mUndo.Count To 1 Step -1
        snapshot = mUndo(i)
        logIndex = FindRecordRow(loLog, CStr(snapshot(0)))
        If CBool(snapshot(1)) Then
            If logIndex > 0 Then
                oldData = snapshot(2)
                For j = LBound(names) To UBound(names)
                    loLog.DataBodyRange.Cells(logIndex, _
                       loLog.ListColumns(CStr(names(j))).Index).Value = oldData(j)
                Next j
            End If
        Else
            If logIndex > 0 Then loLog.ListRows(logIndex).Delete
        End If
        If Not loWork Is Nothing Then
            workIndex = FindRecordRow(loWork, CStr(snapshot(0)))
            If workIndex > 0 Then
                loWork.DataBodyRange.Cells(workIndex, _
                    loWork.ListColumns("ProcessedStatus").Index).Value = snapshot(3)
            End If
        End If
    Next i
    Set mUndo = Nothing
    MsgBox "Most recent DONE / IGNORE batch was undone.", vbInformation
SafeExit:
    Application.EnableEvents = oldEvents
    Application.ScreenUpdating = oldScreen
    Exit Sub
ErrorHandler:
    MsgBox "Undo failed: " & Err.Description, vbCritical
    Resume SafeExit
End Sub

' HELPER: locate a ListObject by name on any worksheet of ThisWorkbook.
Private Function FindTableByName(ByVal tableName As String) As ListObject
    Dim ws As Worksheet, lo As ListObject
    For Each ws In ThisWorkbook.Worksheets
        For Each lo In ws.ListObjects
            If StrComp(lo.Name, tableName, vbTextCompare) = 0 Then
                Set FindTableByName = lo
                Exit Function
            End If
        Next lo
    Next ws
End Function

' HELPER: case-insensitive existence check for a named table column.
Private Function TableHasColumn(ByVal lo As ListObject, ByVal columnName As String) As Boolean
    Dim lc As ListColumn
    For Each lc In lo.ListColumns
        If StrComp(lc.Name, columnName, vbTextCompare) = 0 Then
            TableHasColumn = True
            Exit Function
        End If
    Next lc
End Function

' HELPER: linear search for first matching RecordID (case-insensitive,
' trims surrounding spaces). Returns 0 if absent. If duplicates exist,
' only the first matching log entry is updated.
Private Function FindRecordRow(ByVal lo As ListObject, ByVal recordID As String) As Long
    Dim i As Long, columnIndex As Long
    If lo Is Nothing Then Exit Function
    If lo.DataBodyRange Is Nothing Then Exit Function
    columnIndex = lo.ListColumns("RecordID").Index
    For i = 1 To lo.ListRows.Count
        If StrComp(Trim$(CStr(lo.DataBodyRange.Cells(i, columnIndex).Value2)), _
                   recordID, vbTextCompare) = 0 Then
            FindRecordRow = i
            Exit Function
        End If
    Next i
End Function
