Attribute VB_Name = "CPAR_Worklist_Columns"
Option Explicit

Public Sub UpdateWorklistColumns()
    Dim ws As Worksheet, lo As ListObject, candidate As ListObject
    Dim lc As ListColumn, sourceCell As Range, sourceRange As Range
    Dim keep As Object, field As Variant, sourceText As String
    Dim hasCPAR As Boolean, hasDemo As Boolean, hasConflict As Boolean
    Dim showAll As Boolean, foundVisible As Boolean, oldScreen As Boolean
    oldScreen = Application.ScreenUpdating
    On Error GoTo Failed
    For Each ws In ThisWorkbook.Worksheets
        For Each candidate In ws.ListObjects
            If StrComp(candidate.Name, "tblFinalWorklist", vbTextCompare) = 0 Then
                Set lo = candidate
                Exit For
            End If
        Next candidate
        If Not lo Is Nothing Then Exit For
    Next ws
    If lo Is Nothing Then Err.Raise vbObjectError + 1100, , "Cannot find tblFinalWorklist."
    Application.ScreenUpdating = False
    If lo.DataBodyRange Is Nothing Then
        showAll = True
    Else
        Set sourceRange = lo.ListColumns("Source").DataBodyRange
        ' Inspect row visibility directly: Source may itself have been hidden.
        For Each sourceCell In sourceRange.Cells
            If Not sourceCell.EntireRow.Hidden Then
                foundVisible = True
                If IsError(sourceCell.Value2) Then
                    showAll = True
                Else
                    sourceText = UCase$(Trim$(CStr(sourceCell.Value2)))
                    sourceText = Replace(Replace(sourceText, "_", " "), "-", " ")
                    Select Case True
                        Case InStr(sourceText, "DEMOGRAPH") > 0: hasDemo = True
                        Case InStr(sourceText, "CONFLICT") > 0: hasConflict = True
                        Case InStr(sourceText, "CPAR") > 0: hasCPAR = True
                        Case Else: showAll = True
                    End Select
                End If
            End If
        Next sourceCell
        If Not foundVisible Then showAll = True
    End If
    Set keep = CreateObject("Scripting.Dictionary")
    keep.CompareMode = vbTextCompare
    For Each field In Array("PatientID", "LastName", "FirstName", "Source", _
        "EventDate", "IssueType", "RecordID", "MasterKey", "PanelID", "Doctor", "ProcessedStatus")
        keep(CStr(field)) = True
    Next field
    If hasCPAR Then keep("UNABLE_TO_SEND_REASON") = True
    If hasDemo Then
        For Each field In Array("Alberta Registry Patient Id", _
            "Alberta Registry Patient Last Name", "Alberta Registry Patient First Name", _
            "Panel Gender", "Alberta Registry Gender", "DOB", "Panel Date of Birth", _
            "Alberta Registry Date Of Birth", "Date Of Death")
            keep(CStr(field)) = True
        Next field
    End If
    If hasConflict Then
        keep("EffectiveMasterEntryDate") = True
        keep("ConflictRule") = True
        keep("DOB") = True
    End If
    For Each lc In lo.ListColumns
        If showAll Then
            If lc.Range.EntireColumn.Hidden Then lc.Range.EntireColumn.Hidden = False
        ElseIf lc.Range.EntireColumn.Hidden <> Not keep.Exists(Trim$(lc.Name)) Then
            lc.Range.EntireColumn.Hidden = Not keep.Exists(Trim$(lc.Name))
        End If
    Next lc
Finished:
    Application.ScreenUpdating = oldScreen
    Exit Sub
Failed:
    Application.ScreenUpdating = oldScreen
    MsgBox "Could not update column visibility: " & Err.Description, vbExclamation
End Sub
