Attribute VB_Name = "modMain"
'Sort Subsystem
    DefLng A-Z
    'Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
    Private Const LB_SETTABSTOPS = &H192

'Constants
    Const Numbers = "0123456789"
    Const MaxGroups = 5000 '32k Absolute Limit
    Const LargeWindow = 2100
    Const SmallWindow = 1530

'Environment
    Public AppPath As String
    Public MinNewFiles As Integer
    Public NewFileAge As Integer
    Public OutputPath As String
    Public TemplatePath As String

'Group Database
    Public GroupCount As Integer
    Public GroupNames(1 To MaxGroups) As String
    Public GroupKeys(1 To MaxGroups, 1 To 3) As String
    Public GroupTV(1 To MaxGroups) As Boolean
    Public GroupMultiEp(1 To MaxGroups) As Boolean
    Public GroupSize(1 To MaxGroups, 1 To 2) As Long '1=Min, 2=Max - Zero in both means disabled
    
    Public GroupUpdated(1 To MaxGroups) As Boolean

'File List Database
    Public FileCount As Integer
    Public FileNames(1 To 32000) As String
    Public FileSizes(1 To 32000) As Long
    Public FileDates(1 To 32000) As Single 'Date 'dwayne

    Public FileMakers(1 To 32000) As Boolean
    Public FileUpdated(1 To 32000) As Boolean

'Sub Database (file associations)
    Public FileGroup(1 To 32000) As Integer
    Public FilePath(1 To 32000) As Integer '0 = CD-ROM

'Paths Database
    Public PathCount As Integer
    Public Paths(1 To 500, 1 To 2) As String

'Replacement Masks
    Public AlphaMask(1 To 255) As String * 1
    Public EpisodeMask(1 To 255) As String * 1
    Public NumberMask(1 To 255) As String * 1

'Operations
    Public BootUpdate As Boolean

'File Templates

    'Master List
    Public ListHeader As Variant
    Public ListEpisodeItem As Variant
    Public ListEpisodeItemBold As Variant
    Public ListEpisodeMid As Variant
    Public ListMid As Variant
    Public ListMovieItem As Variant
    Public ListMovieItemBold As Variant
    Public ListMovieMid As Variant
    Public ListEnding As Variant
    
    'Group List
    Public FileHeader As Variant
    Public FileEpisodeItem As Variant
    Public FileEpisodeItemBold As Variant
    Public FileEpisodeMid As Variant
    Public FileEnding As Variant

'dwayne
Public Declare Sub CombOrderX3 Lib "asmorder.dll" Alias "CombOrderX" _
   (ByVal TotalArrays As Long, _
    ByVal OrderArrays As Long, _
    ByVal ArraySize As Long, _
    ByVal EscCb As Long, _
    ByRef ArrayPtr1 As Any, _
    ByVal ArrayType1 As Long, _
    ByRef ArrayPtr2 As Any, _
    ByVal ArrayType2 As Long, _
    ByRef ArrayPtr3 As Any, _
    ByVal ArrayType3 As Long)

Public Declare Sub CombOrderX4 Lib "asmorder.dll" Alias "CombOrderX" _
   (ByVal TotalArrays As Long, _
    ByVal OrderArrays As Long, _
    ByVal ArraySize As Long, _
    ByVal EscCb As Long, _
    ByRef ArrayPtr1 As Any, _
    ByVal ArrayType1 As Long, _
    ByRef ArrayPtr2 As Any, _
    ByVal ArrayType2 As Long, _
    ByRef ArrayPtr3 As Any, _
    ByVal ArrayType3 As Long, _
    ByRef ArrayPtr4 As Any, _
    ByVal ArrayType4 As Long)


'internal DLL comparison callbacks
'A=ascending D=descending
'S=signed    U=unsigned
Public Const CmpVoid     As Long = 0  '<- does nothing (for completeness ;)
Public Const CmpReserved As Long = 1  '<- might use for variants, might not
Public Const CmpLongSA   As Long = 2  '<- 32bit signed integers
Public Const CmpLongSD   As Long = 3
Public Const CmpLongUA   As Long = 4  '<- 32bit unsigned integers
Public Const CmpLongUD   As Long = 5
Public Const CmpSngA     As Long = 6  '<- floating point singles
Public Const CmpSngD     As Long = 7
Public Const CmpStrAA    As Long = 8  '<- ASCII null terminated C strings
Public Const CmpStrAD    As Long = 9
Public Const CmpStrWA    As Long = 10 '<- Widebyte Unicode C strings
Public Const CmpStrWD    As Long = 11
Public Const CmpStrBA    As Long = 12 '<- BSTR Visual Basic 4+ strings
Public Const CmpStrBD    As Long = 13
'enyawd


Sub Boot()
    SetupCleaningMasks
    DoEvents
    LoadSettings
    DoEvents
    BootUpdate = True
    StartUpdate (True)
End Sub

Function SmartTitle(FileName As String) As String
    'Smart Titler
End Function

Sub SetupCleaningMasks()
    Dim i As Integer
    For i = 1 To 255
        EpisodeMask(i) = " "
        NumberMask(i) = " "
        AlphaMask(i) = " "
    Next i
    For i = 48 To 57
        EpisodeMask(i) = Chr(i)
        AlphaMask(i) = Chr(i)
        NumberMask(i) = "!"
    Next i
    For i = 97 To 122
        AlphaMask(i) = Chr(i)
        AlphaMask(i - 32) = Chr(i)
    Next i
End Sub

Sub LoadSettings()
    Dim Temp As Variant
    AppPath = App.Path
    If Right(AppPath, 1) <> "\" Then AppPath = AppPath + "\"
    
    On Error Resume Next
    Err.Clear
    
    Open AppPath + "settings.dat" For Input As #1
    If Err.Number Then
        MinNewFiles = 10
        NewFileAge = 2
        OutputPath = "C:\Output\"
        TemplatePath = "C:\Template\"
        SaveSettings
        Err.Clear
    Else
        Line Input #1, Temp
        MinNewFiles = Val(Temp)
        Line Input #1, Temp
        NewFileAge = Val(Temp)
        Line Input #1, OutputPath
        Line Input #1, TemplatePath
        Close #1
    End If
        
    Open AppPath + "Paths.dat" For Input As #1
    If Err.Number = 0 Then
        Do While Not EOF(1)
            Line Input #1, Temp
            If Trim(Temp) <> "" Then
                PathCount = PathCount + 1
                Paths(PathCount, 1) = Trim(Temp)
            End If
        Loop
        Close #1
    End If
End Sub

Sub SaveSettings()
    Open AppPath + "settings.dat" For Output As #1
    Print #1, MinNewFiles
    Print #1, NewFileAge
    Print #1, OutputPath
    Print #1, TemplatePath
    Close #1
End Sub

Sub StartUpdate(UpdateMode As Boolean)
    OldDate = DateAdd("w", -NewFileAge, Date)
    If UpdateMode Then
        'Visible Mode
        frmUpdate.Show 1
    Else
        'Hiden Mode
        RunUpdate
    End If
End Sub

Sub RunUpdate()
    Reset
    DoEvents
    'LoadTemplates
    DoEvents
    LoadCDDatabase
    frmUpdate.NextItem
    ReadHardDisks
    If BootUpdate Then
        BootUpdate = False
    Else
        frmUpdate.NextItem
        UpdateCatalog
    End If
    Unload frmUpdate
End Sub

Sub LoadCDDatabase()
    Dim Temp As Variant
    Err.Clear
    On Error Resume Next
    Open AppPath + "CDs.dat" For Input As #1
    If Err.Number = 0 Then
        Do While Not EOF(1)
            Line Input #1, Temp
            If Trim(Temp) <> "" Then
                FileCount = FileCount + 1
                FileNames(FileCount) = Trim(Temp)
                Line Input #1, Temp
                FileSizes(FileCount) = Val(Temp)
                Line Input #1, Temp
                FileDates(FileCount) = CSng(CDate(Temp))
            End If
            DoEvents
        Loop
        Close #1
    End If
End Sub

Sub ReadHardDisks()
    
End Sub

Sub UpdateCatalog()

End Sub

Sub AddFolder(Path)
    Dim Dirs(1 To 500)
    Dim DirC As Integer, X As Integer
    If Right(Path, 1) <> "\" Then Path = Path + "\"
    DoEvents
    frmMain.Dir1 = Path
    frmMain.File1.Refresh
    frmMain.Dir1.Refresh
    DirC = frmMain.Dir1.ListCount
    If frmMain.File1.ListCount Then
        For X = 0 To frmMain.File1.ListCount - 1
            'AddItem frmMain.File1.List(X), Path
        Next X
    End If
    If DirC Then
        For X = 0 To DirC - 1
            Dirs(X + 1) = frmMain.Dir1.List(X)
        Next X
        For X = 1 To DirC
            AddFolder Dirs(X)
        Next X
    End If
End Sub

Sub LoadTemplates()
    Dim File As Variant
    'Dim X As Long, Y As Long
    Dim X(1 To 8) As Long
    Dim i As Integer
    
    File = LoadFile(TemplatePath & "template (index).html")
    
    X(1) = InStr(File, "<!--1-->")
    For i = 2 To 8
        X(i) = InStr(X(i - 1), File, "<!--" & i & "-->")
    Next i
    
    ListHeader = Replace(Left(File, X(1) - 1), "%DATE%", Date & " - " & Time)
    ListEpisodeItem = Mid(File, X(1) + 8, X(2) - X(1) - 8)
    ListEpisodeMid = Mid(File, X(2) + 8, X(3) - X(2) - 8)
    ListEpisodeItemBold = Mid(File, X(3) + 8, X(4) - X(3) - 8)
    ListMid = Mid(File, X(4) + 8, X(5) - X(4) - 8)
    ListMovieItem = Mid(File, X(5) + 8, X(6) - X(5) - 8)
    ListMovieMid = Mid(File, X(6) + 8, X(7) - X(6) - 8)
    ListMovieItemBold = Mid(File, X(7) + 8, X(8) - X(7) - 8)
    ListEnding = Mid(File, X(8) + 8)
    
    DoEvents
    
    File = LoadFile(TemplatePath & "template (files).html")
    
    X(1) = InStr(File, "<!--1-->")
    For i = 2 To 4
        X(i) = InStr(X(i - 1), File, "<!--" & i & "-->")
    Next i
    
    FileHeader = Left(File, X(1) - 1)
    FileEpisodeItem = Mid(File, X(1) + 8, X(2) - X(1) - 8)
    FileEpisodeMid = Mid(File, X(2) + 8, X(3) - X(2) - 8)
    FileEpisodeItemBold = Mid(File, X(3) + 8, X(4) - X(3) - 8)
    FileEnding = Mid(File, X(4) + 8)
End Sub

Function LoadFile(File As Variant) As Variant
    Dim X As Long
    On Error Resume Next
    X = FileLen(File)
    If X > 0 Then
    Open File For Binary As #1
    LoadFile = StrConv(InputB(X, 1), vbUnicode)
    Close #1
    End If
End Function

Sub Reset()
    GroupCount = 0
    Erase GroupNames
    Erase GroupKeys
    Erase GroupTV
    Erase GroupMultiEp
    Erase GroupSize
    Erase GroupUpdated
    FileCount = 0
    Erase FileNames
    Erase FileSizes
    Erase FileDates
    Erase FileMakers
    Erase FileUpdated
    Erase FileGroup
    Erase FilePath
End Sub

'dwayne
'this does nothing right now, just here for later
Public Function CombOrderEscCb() As Long
    CombOrderEscCb = False
End Function
'enyawd
