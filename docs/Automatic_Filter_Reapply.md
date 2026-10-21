# A Dummies Guide to Reapplying Worklist Filters

When an edited value no longer matches an active filter, reapply the filter automatically.
Example: filter ProcessedStatus to blanks, change a visible row to DONE, and that row disappears.

## Install

1. Install [the column visibility module and helper formula](Worklist_Column_Visibility.md).
2. Right-click the worklist worksheet tab > View Code.
3. Use [the combined worksheet event code](../vba/events/Worklist_Output_worksheet.txt). Keep just one Option Explicit, one Worksheet_Change and one Worksheet_Calculate. Merge with existing event logic rather than deleting unrelated code.
4. Save as .xlsm, compile through Debug > Compile VBAProject, and test in desktop Excel.

The event watches data cells in columns with an active filter, preserves the existing criteria, reapplies once per edit/paste, and updates column visibility. It restores the previous EnableEvents setting on failure. An error after the edit does not undo the edit.

## Mark Done / Mark Ignore need an explicit call

The action macro disables events while writing, so Worksheet_Change cannot handle those writes.
In MarkSelectedRows, after the entire For Each key processing loop (after Next key), use:

```vb
If processedCount > 0 Then
    ' Preserve undo before a later display/filter operation can fail.
    Set mUndo = newSnapshot
    If loWork.AutoFilter.FilterMode Then
        loWork.AutoFilter.ApplyFilter
    End If
    UpdateWorklistColumns
End If
```

Keep the existing success-message block afterward. Its repeated Set mUndo assignment is harmless, or remove that duplicate assignment. Install the column module first, since UpdateWorklistColumns is a dependency.

Do not reapply inside the row loop. Finish writing the whole batch before rows disappear.
This is an installation patch; the existing action module and workbook binary have not been modified automatically.

## Check with fictional data

- Filter ProcessedStatus to blanks; edit one row to DONE. It should hide.
- Paste changes into several visible rows. The criteria should stay in place.
- Edit an unfiltered column. No filter reapplication is needed.
- Test Mark Done only after installing the explicit post-loop call.
- Check the processed log before retrying an action that reports an error: the log write may already have succeeded.

Direct edits can lose Excel's native Undo history when event VBA runs. Formula recalculations do not trigger Worksheet_Change, and this is not a Power Query refresh-completion handler. Protected sheets can prevent filtering or column formatting.

Validation: source and installation order reviewed; live VBA compilation and Excel event behavior have not been tested in this environment.
