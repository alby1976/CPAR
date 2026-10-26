Attribute VB_Name = "CPAR_Archive_History"
Option Explicit

Private Const KEEP_MONTHS As Long = 4

' Run only after installing the M queries and Processed_Log integration.
Public Sub ArchiveOldHistory()
    Dim log As ListObject, keys As ListObject, loaded As ListObject
    Dim ids As Object, selected As Collection, qt As QueryTable
    Dim started As Date, cutoff As Date, stamp As Variant
    Dim i As Long, j As Long, n As Long, rowNo As Long, markerCount As Long
    Dim rid As String, status As String, dt As Variant, item As Variant
    Dim archive As Workbook, checkBook As Workbook, output As Worksheet
    Dim path As String, backup As String, prefix As String
    Dim data() As Variant, headers() As Variant, lr As ListRow
    Dim oldEvents As Boolean, oldScreen As Boolean, savedArchive As Boolean
    Dim deleted As Long, errorText As String
    oldEvents = Application.EnableEvents
    oldScreen = Application.ScreenUpdating
    On Error GoTo Failed
    If ThisWorkbook.ReadOnly Or Len(ThisWorkbook.Path) = 0 Then _
        Err.Raise vbObjectError + 1200, , "Save an editable local .xlsm workbook first."
    Set log = ArchiveTable("tblProcessedLog")
    Set keys = ArchiveTable("tblArchivedProcessedKeys")
    Set loaded = ArchiveTable("tblArchiveLoadedRecordIDs")
    If log Is Nothing Or keys Is Nothing Or loaded Is Nothing Then _
        Err.Raise vbObjectError + 1201, , "Install the archive tables and queries first."
    If log.DataBodyRange Is Nothing Then Exit Sub
    ' Force schema validation before any writes.
    i = log.ListColumns("RecordID").Index
    i = log.ListColumns("Status").Index
    i = log.ListColumns("DateProcessed").Index
    i = keys.ListColumns("RecordID").Index
    i = keys.ListColumns("Status").Index
    i = keys.ListColumns("DateProcessed").Index

    ' A synchronous refresh is required; stale results must not authorize deletion.
    For Each item In ThisWorkbook.Connections
        If item.Type = xlConnectionTypeOLEDB Then
            If item.OLEDBConnection.Refreshing Then _
                Err.Raise vbObjectError + 1202, , "Wait for the current refresh to finish."
        End If
    Next item
    Set qt = loaded.QueryTable
    started = Now
    If Not qt.Refresh(BackgroundQuery:=False) Then _
        Err.Raise vbObjectError + 1203, , "Archive snapshot refresh was cancelled."
    If qt.Refreshing Then Err.Raise vbObjectError + 1204, , "Archive refresh is still running."
    If loaded.DataBodyRange Is Nothing Then Err.Raise vbObjectError + 1205, , "No archive snapshot."
    Set ids = CreateObject("Scripting.Dictionary")
    ' Match Power Query's case-sensitive RecordID semantics.
    ids.CompareMode = vbBinaryCompare
    For i = 1 To loaded.ListRows.Count
        rid = Trim$(CStr(loaded.DataBodyRange.Cells(i, loaded.ListColumns("RecordID").Index).Value2))
        status = CStr(loaded.DataBodyRange.Cells(i, loaded.ListColumns("Kind").Index).Value2)
        If status = "READY" Then
            markerCount = markerCount + 1
            stamp = loaded.DataBodyRange.Cells(i, loaded.ListColumns("RefreshedAt").Index).Value
            If Not IsDate(stamp) Then Err.Raise vbObjectError + 1206, , "Invalid refresh timestamp."
            If CDate(stamp) < DateAdd("s", -2, started) Or CDate(stamp) > DateAdd("n", 1, Now) Then _
                Err.Raise vbObjectError + 1207, , "Stale archive snapshot. Nothing deleted."
        ElseIf status = "ID" And Len(rid) > 0 Then
            ids(rid) = True
        Else
            Err.Raise vbObjectError + 1208, , "Invalid archive snapshot row."
        End If
    Next i
    If markerCount <> 1 Or ids.Count = 0 Then Err.Raise vbObjectError + 1209, , "Incomplete archive snapshot."
    cutoff = DateAdd("m", -KEEP_MONTHS, Date)
    Set selected = New Collection
    For i = 1 To log.ListRows.Count
        rid = Trim$(CStr(log.DataBodyRange.Cells(i, log.ListColumns("RecordID").Index).Value2))
        status = UCase$(Trim$(CStr(log.DataBodyRange.Cells(i, log.ListColumns("Status").Index).Value2)))
        dt = log.DataBodyRange.Cells(i, log.ListColumns("DateProcessed").Index).Value
        If Len(rid) > 0 And Not ids.Exists(rid) And IsDate(dt) Then
            If CDate(dt) < cutoff And (status = "DONE" Or status = "IGNORE" Or status = "IGNORED") Then selected.Add i
        End If
    Next i
    n = selected.Count
    If n = 0 Then
        MsgBox "No completed history older than " & Format$(cutoff, "yyyy-mm-dd") & _
            " is absent from loaded reports.", vbInformation
        Exit Sub
    End If
    If MsgBox("Archive " & n & " log row(s) older than " & Format$(cutoff, "yyyy-mm-dd") & _
        "? A separate archive and full workbook backup will be saved first. Compact keys stay in this workbook.", _
        vbYesNo + vbQuestion, "Archive old history") <> vbYes Then Exit Sub
    prefix = ConfiguredArchiveFolder() & Application.PathSeparator & _
        "CPAR_" & Format$(Now, "yyyymmdd_hhnnss")
    path = prefix & "_history.xlsx"
    backup = prefix & "_before_archive.xlsm"
    If Len(Dir$(path)) > 0 Or Len(Dir$(backup)) > 0 Then _
        Err.Raise vbObjectError + 1210, , "Archive filename exists; retry with a different folder or time."
    Application.EnableEvents = False
    Application.ScreenUpdating = False
    ThisWorkbook.SaveCopyAs backup
    ReDim data(1 To n, 1 To log.ListColumns.Count)
    ReDim headers(1 To 1, 1 To log.ListColumns.Count)
    For j = 1 To log.ListColumns.Count
        headers(1, j) = log.ListColumns(j).Name
    Next j
    For i = 1 To n
        For j = 1 To log.ListColumns.Count
            data(i, j) = log.DataBodyRange.Cells(CLng(selected(i)), j).Value2
        Next j
    Next i
    Set archive = Workbooks.Add(xlWBATWorksheet)
    Set output = archive.Worksheets(1)
    output.Name = "Archived_History"
    ' Text storage prevents formula interpretation and identifier conversion.
    output.Cells.NumberFormat = "@"
    output.Cells(1, 1).Resize(1, log.ListColumns.Count).Value2 = headers
    output.Cells(2, 1).Resize(n, log.ListColumns.Count).Value2 = data
    archive.SaveAs Filename:=path, FileFormat:=xlOpenXMLWorkbook
    archive.Close SaveChanges:=False
    Set archive = Nothing
    Set checkBook = Workbooks.Open(Filename:=path, UpdateLinks:=0, ReadOnly:=True)
    For i = 1 To n
        For j = 1 To log.ListColumns.Count
            If CStr(checkBook.Worksheets(1).Cells(i + 1, j).Value2) <> CStr(data(i, j)) Then _
                Err.Raise vbObjectError + 1211, , "Archive verification failed; nothing deleted."
        Next j
    Next i
    checkBook.Close SaveChanges:=False
    Set checkBook = Nothing
    savedArchive = True
    ' Save every compact key BEFORE removing any detail. Duplicates are safe.
    For i = 1 To n
        rowNo = CLng(selected(i))
        Set lr = keys.ListRows.Add
        lr.Range.Cells(1, keys.ListColumns("RecordID").Index).NumberFormat = "@"
        lr.Range.Cells(1, keys.ListColumns("RecordID").Index).Value2 = _
            Trim$(CStr(log.DataBodyRange.Cells(rowNo, log.ListColumns("RecordID").Index).Value2))
        lr.Range.Cells(1, keys.ListColumns("Status").Index).Value2 = _
            log.DataBodyRange.Cells(rowNo, log.ListColumns("Status").Index).Value2
        lr.Range.Cells(1, keys.ListColumns("DateProcessed").Index).Value2 = _
            log.DataBodyRange.Cells(rowNo, log.ListColumns("DateProcessed").Index).Value2
    Next i
    ThisWorkbook.Save
    For i = n To 1 Step -1
        log.ListRows(CLng(selected(i))).Delete
        deleted = deleted + 1
    Next i
    ThisWorkbook.Save
    MsgBox deleted & " row(s) archived." & vbCrLf & path & vbCrLf & _
        "Keep the archive and backup. Refresh All before continuing work; do not use Undo Last Action for the previous batch.", vbInformation
CleanExit:
    Application.EnableEvents = oldEvents
    Application.ScreenUpdating = oldScreen
    Exit Sub
Failed:
    errorText = Err.Description
    On Error Resume Next
    If Not archive Is Nothing Then archive.Close SaveChanges:=False
    If Not checkBook Is Nothing Then checkBook.Close SaveChanges:=False
    Application.EnableEvents = oldEvents
    Application.ScreenUpdating = oldScreen
    On Error GoTo 0
    MsgBox "Archive stopped: " & errorText & vbCrLf & _
        deleted & " detail row(s) removed. Do not retry blindly; inspect the log, compact keys, archive and backup." & _
        vbCrLf & backup, vbCritical
End Sub

Private Function ArchiveTable(ByVal tableName As String) As ListObject
    Dim ws As Worksheet, lo As ListObject
    For Each ws In ThisWorkbook.Worksheets
        For Each lo In ws.ListObjects
            If StrComp(lo.Name, tableName, vbTextCompare) = 0 Then
                Set ArchiveTable = lo
                Exit Function
            End If
        Next lo
    Next ws
End Function

Private Function ConfiguredArchiveFolder() As String
    Dim config As ListObject, i As Long, count As Long
    Dim folder As String, fs As Object
    Set config = ArchiveTable("tblFolderConfig")
    If config Is Nothing Then Err.Raise vbObjectError + 1220, , "Missing tblFolderConfig."
    If config.DataBodyRange Is Nothing Then Err.Raise vbObjectError + 1221, , "Enter Archive_Folder on Folder_Config."
    For i = 1 To config.ListRows.Count
        If StrComp(Trim$(CStr(config.DataBodyRange.Cells(i, _
            config.ListColumns("Setting").Index).Value2)), "Archive_Folder", vbTextCompare) = 0 Then
            count = count + 1
            folder = Trim$(CStr(config.DataBodyRange.Cells(i, config.ListColumns("Value").Index).Value2))
        End If
    Next i
    If count <> 1 Or Len(folder) = 0 Then Err.Raise vbObjectError + 1222, , _
        "Enter exactly one nonblank Archive_Folder setting on Folder_Config."
    folder = Replace(folder, "/", "\")
    If Not ((Len(folder) >= 3 And Mid$(folder, 2, 2) = ":\") Or Left$(folder, 2) = "\\") Then _
        Err.Raise vbObjectError + 1223, , "Archive_Folder must be an absolute drive or UNC path."
    Set fs = CreateObject("Scripting.FileSystemObject")
    If Not fs.FolderExists(folder) Then Err.Raise vbObjectError + 1224, , _
        "Archive_Folder does not exist or is unavailable. Create it and check access."
    folder = fs.GetAbsolutePathName(folder)
    If Right$(folder, 1) = "\" Then folder = Left$(folder, Len(folder) - 1)
    ConfiguredArchiveFolder = folder
End Function
