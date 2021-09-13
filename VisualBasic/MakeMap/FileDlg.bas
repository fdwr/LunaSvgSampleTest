Attribute VB_Name = "Module1"
Option Explicit
'// type that passes/returns value through ShowOpenDialog function
Public Type stcFileStruct
    strFileName     As String
    strFileTitle    As String
    strFilter       As String
    strDialogtitle  As String
    lngFilterIndex  As Long
    blnReadOnly     As Boolean
End Type
'// Max filename and path constants
Const cMaxPath = 260
Const cMaxFile = 260
'// Open File name type
Private Type OPENFILENAME
    lStructSize As Long           ' Filled with UDT size
    hwndOwner As Long             ' Tied to Owner
    hInstance As Long             ' Ignored (used only by templates)
    lpstrFilter As String        ' Tied to Filter
    lpstrCustomFilter As String  ' Ignored
    nMaxCustFilter As Long       ' Ignored
    nFilterIndex As Long         ' Tied to FilterIndex
    lpstrFile As String           ' Tied to FileName
    nMaxFile As Long              ' Handled internally
    lpstrFileTitle As String     ' Tied to FileTitle
    nMaxFileTitle As Long        ' Handled internally
    lpstrInitialDir As String    ' Tied to InitDir
    lpstrTitle As String         ' Tied to DlgTitle
    Flags As Long                 ' Tied to Flags
    nFileOffset As Integer       ' Ignored
    nFileExtension As Integer    ' Ignored
    lpstrDefExt As String        ' Tied to DefaultExt
    lCustData As Long             ' Ignored (needed for hooks)
    lpfnHook As Long              ' Ignored (good luck with hooks)
    lpTemplateName As Long       ' Ignored (good luck with templates)
End Type

Private Declare Function GetOpenFileName Lib "COMDLG32" _
    Alias "GetOpenFileNameA" (File As OPENFILENAME) As Long
'// flags
Public Enum EOpenFile
    OFN_READONLY = &H1
    OFN_OVERWRITEPROMPT = &H2
    OFN_HIDEREADONLY = &H4
    OFN_NOCHANGEDIR = &H8
    OFN_SHOWHELP = &H10
    OFN_ENABLEHOOK = &H20
    OFN_ENABLETEMPLATE = &H40
    OFN_ENABLETEMPLATEHANDLE = &H80
    OFN_NOVALIDATE = &H100
    OFN_ALLOWMULTISELECT = &H200
    OFN_EXTENSIONDIFFERENT = &H400
    OFN_PATHMUSTEXIST = &H800
    OFN_FILEMUSTEXIST = &H1000
    OFN_CREATEPROMPT = &H2000
    OFN_SHAREAWARE = &H4000
    OFN_NOREADONLYRETURN = &H8000
    OFN_NOTESTFILECREATE = &H10000
    OFN_NONETWORKBUTTON = &H20000
    OFN_NOLONGNAMES = &H40000
    OFN_EXPLORER = &H80000
    OFN_NODEREFERENCELINKS = &H100000
    OFN_LONGNAMES = &H200000
End Enum
'// Main function
Function VBGetOpenFileName(FileName As String, _
                           Optional FileTitle As String, _
                           Optional FileMustExist As Boolean = True, _
                           Optional MultiSelect As Boolean = False, _
                           Optional ReadOnly As Boolean = False, _
                           Optional HideReadOnly As Boolean = False, _
                           Optional filter As String = "All (*.*)| *.*", _
                           Optional FilterIndex As Long = 1, _
                           Optional InitDir As String, _
                           Optional DlgTitle As String, _
                           Optional DefaultExt As String, _
                           Optional Owner As Long = -1, _
                           Optional Flags As Long = 0) As Boolean

    Dim opfile As OPENFILENAME, s As String, afFlags As Long
With opfile
    .lStructSize = Len(opfile)

    ' Add in specific flags and strip out non-VB flags
    .Flags = (-FileMustExist * OFN_FILEMUSTEXIST) Or _
             (-MultiSelect * OFN_ALLOWMULTISELECT) Or _
             (-ReadOnly * OFN_READONLY) Or _
             (-HideReadOnly * OFN_HIDEREADONLY) Or _
             (Flags And CLng(Not (OFN_ENABLEHOOK Or _
                                  OFN_ENABLETEMPLATE)))
    ' Owner can take handle of owning window
    If Owner <> -1 Then .hwndOwner = Owner
    ' InitDir can take initial directory string
    .lpstrInitialDir = InitDir
    ' DefaultExt can take default extension
    .lpstrDefExt = DefaultExt
    ' DlgTitle can take dialog box title
    .lpstrTitle = DlgTitle

    ' To make Windows-style filter, replace | and : with nulls
    Dim ch As String, i As Integer
    For i = 1 To Len(filter)
        ch = Mid$(filter, i, 1)
        If ch = "|" Or ch = ":" Then
            s = s & vbNullChar
        Else
            s = s & ch
        End If
    Next
    ' Put double null at end
    s = s & vbNullChar & vbNullChar
    .lpstrFilter = s
    .nFilterIndex = FilterIndex

    ' Pad file and file title buffers to maximum path
    s = FileName & String$(cMaxPath - Len(FileName), 0)
    .lpstrFile = s
    .nMaxFile = cMaxPath
    s = FileTitle & String$(cMaxFile - Len(FileTitle), 0)
    .lpstrFileTitle = s
    .nMaxFileTitle = cMaxFile
    ' All other fields set to zero

    If GetOpenFileName(opfile) Then
        VBGetOpenFileName = True
        FileName = StrZToStr(.lpstrFile)
        FileTitle = StrZToStr(.lpstrFileTitle)
        Flags = .Flags
        ' Return the filter index
        FilterIndex = .nFilterIndex
        ' Look up the filter the user selected and return that
        filter = FilterLookup(.lpstrFilter, FilterIndex)
        If (.Flags And OFN_READONLY) Then ReadOnly = True
    Else
        VBGetOpenFileName = False
        FileName = Empty
        FileTitle = Empty
        Flags = 0
        FilterIndex = -1
        filter = Empty
    End If
End With
End Function
'// convert the filter to standard required by windows api
Private Function FilterLookup(ByVal sFilters As String, ByVal iCur As Long) As String
    Dim iStart As Long, iEnd As Long, s As String
    iStart = 1
    If sFilters = Empty Then Exit Function
    Do
        ' Cut out both parts marked by null character
        iEnd = InStr(iStart, sFilters, vbNullChar)
        If iEnd = 0 Then Exit Function
        iEnd = InStr(iEnd + 1, sFilters, vbNullChar)
        If iEnd Then
            s = Mid$(sFilters, iStart, iEnd - iStart)
        Else
            s = Mid$(sFilters, iStart)
        End If
        iStart = iEnd + 1
        If iCur = 1 Then
            FilterLookup = s
            Exit Function
        End If
        iCur = iCur - 1
    Loop While iCur
End Function
'// show open dialog function (pass/return filestruct)
Public Function ShowOpenDialog(filestruct As stcFileStruct) As Boolean
    With filestruct
        If .strFilter = Empty Then .strFilter = "All Files|*.*"
        ShowOpenDialog = VBGetOpenFileName(.strFileName, .strFileTitle, True, , .blnReadOnly, , .strFilter, .lngFilterIndex, , .strDialogtitle)
    End With
    StripFileStruct filestruct '// Return FileStruct
End Function
'// Removes nulls from the two strings in stcFileStruct
Private Sub StripFileStruct(filestruct As stcFileStruct)
    With filestruct
        .strFileName = StripTerminator(.strFileName)
        .strFileTitle = StripTerminator(.strFileTitle)
    End With
End Sub
'// Removes trailing nulls from a string
Function StripTerminator(ByVal strString As String) As String
    Dim intZeroPos As Integer
    intZeroPos = InStr(strString, Chr$(0))
    If intZeroPos > 0 Then
        StripTerminator = Left$(strString, intZeroPos - 1)
    Else
        StripTerminator = strString
    End If
End Function

Function StrZToStr(s As String) As String
    StrZToStr = Left$(s, Len(s))
End Function

'Form Code
Private Sub cmdOpen_Click()
    Dim File As stcFileStruct
    '// fill values (not required)
    File.strDialogtitle = "Select file to open"
    File.strFilter = "Text Files *.txt|*.txt" '// use same format as commondialog Control
    '// pass stcFileStruct
    ShowOpenDialog File
    '// get return values (passed back through type)
    With File
        MsgBox "FileName: " & .strFileName
        MsgBox "ReadOnly: " & .blnReadOnly
        MsgBox "FileTitle: " & .strFileTitle
        MsgBox "Filter Index: " & .lngFilterIndex
    End With
End Sub

