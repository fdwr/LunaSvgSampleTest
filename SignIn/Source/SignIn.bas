Attribute VB_Name = "modSignIn"
Option Explicit

Public Declare Function GetTickCount Lib "kernel32" () As Long
Public Declare Function GetKeyboardState Lib "user32" (ByRef pbKeyState As Byte) As Long
Public Declare Function SetKeyboardState Lib "user32" (ByRef lppbKeyState As Byte) As Long
Public Declare Sub keybd_event Lib "user32" (ByVal bVk As Byte, ByVal bScan As Byte, ByVal dwflags As Long, ByVal dwExtraInfo As Long)
Public Declare Function ReleaseCapture Lib "user32" () As Long

'Private Declare Function BitBlt Lib "GDI32" (ByVal hDestDC As Long, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal dwRop As Long) As Long
'Private Declare Function SendMessage Lib "USER32" Alias "SendMessageA" (ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Long) As Long
'Private Declare Function DrawState Lib "user32" Alias "DrawStateA" (ByVal hdc As Long, ByVal hBrush As Long, ByVal lpDrawStateProc As Long, ByVal lParam As Long, ByVal wParam As Long, ByVal n1 As Long, ByVal n2 As Long, ByVal n3 As Long, ByVal n4 As Long, ByVal un As Long) As Long
'Const CB_SHOWDROPDOWN = &H14F

Public Const DbFilenameDef = "StudentLog.mdb"
Public Const AverageDurationDef = 0.04167 'average duration for students using lab, 1/24 or one hour
Public Const MinDurationDef = 0.000694 'ignore if less than a minute

Public Db As Database
Public DbTbl As Recordset
Public DbIsOpen As Boolean
Public DbFilename As String
Public DbErrMsg As String
Public DbErrNum As Long
Public StudentTbl As Recordset
Public AppPath As String
Public AverageDuration As Double 'average duration student spends in lab
Public MinDuration As Double     'minimum duration to keep a record

Public ProgramTitle As String

Public Sub Main()
    AppPath = App.Path
    If Right(AppPath, 1) <> "\" Then AppPath = AppPath & "\"
    DbFilename = AppPath & DbFilenameDef
    AverageDuration = AverageDurationDef
    MinDuration = MinDurationDef
    frmSignIn.Show
End Sub

Public Sub OpenDbTable(Table As String)
    'attempt open database, catching those annoying errors!
    'if db is closed
    '  open it
    'elseif if table already open
    '  if name of last table is same, exit
    'endif

    On Error GoTo OpenDbErr
    If Db Is Nothing Then
        Set Db = OpenDatabase(DbFilename)
    ElseIf Not DbTbl Is Nothing Then
        If DbTbl.Name = Table Then Exit Sub
    End If
    Set DbTbl = Db.OpenRecordset(Table)
    DbIsOpen = True
    Exit Sub

OpenDbErr:
    DbErrMsg = Err.Description
    DbIsOpen = False
    DbErrNum = Err.Number
    Set DbTbl = Nothing
    Exit Sub

End Sub

Public Sub ExecSql(Sql As String)
    'attempt to execute SQL statement, catching those annoying errors!
    On Error GoTo OpenDbErr
    If Db Is Nothing Then Set Db = OpenDatabase(DbFilename)
    Db.Execute Sql, dbFailOnError
    DbIsOpen = True
    Exit Sub

OpenDbErr:
    DbErrMsg = Err.Description
    DbIsOpen = False
    Exit Sub

End Sub

'prevent those annoying people from leaving on Caps Lock and turning off Num Lock
'this used to be MUCH simpler until dumb Win2k
Public Sub CorrectKeyStates()
    ' Keycode constants
    Const VK_NUMLOCK = &H90
    Const VK_SCROLL = &H91
    Const VK_CAPITAL = &H14
    Const KEYEVENTF_EXTENDEDKEY = &H1
    Const KEYEVENTF_KEYUP = &H2
    Const VER_PLATFORM_WIN32_NT = 2
    Const VER_PLATFORM_WIN32_WINDOWS = 1

    Dim Keys(255) As Byte

    ' short and sweet for 95/98
    'GetKeyboardState Keys(0)
    'Keys(VK_NUMLOCK) = 1
    'Keys(VK_CAPITAL) = 0
    'SetKeyboardState Keys(0)

    ' use keybd_event instead of dumb SendKeys, which causes
    ' an unpleasant infinite loop
    GetKeyboardState Keys(0)
    If Keys(VK_CAPITAL) And 1 Then
        'Simulate Key Press
        keybd_event VK_CAPITAL, &H45, KEYEVENTF_EXTENDEDKEY Or 0, 0
        'Simulate Key Release
        keybd_event VK_CAPITAL, &H45, KEYEVENTF_EXTENDEDKEY _
        Or KEYEVENTF_KEYUP, 0
    End If
    If (Keys(VK_NUMLOCK) And 1) = 0 Then
        'Simulate Key Press
        keybd_event VK_NUMLOCK, &H45, KEYEVENTF_EXTENDEDKEY Or 0, 0
        'Simulate Key Release
        keybd_event VK_NUMLOCK, &H45, KEYEVENTF_EXTENDEDKEY _
        Or KEYEVENTF_KEYUP, 0
    End If

End Sub

'accept only SS numbers and k-numbers, ignoring hyphens, space, and letters
Public Sub AllowSidKeysOnly(KeyAscii As Integer, Obj As TextBox)
If KeyAscii >= 32 Then
    'txtStudentId.SelStart
    If KeyAscii = 107 Then KeyAscii = 75
    If KeyAscii = 75 Then
        If Obj.SelStart <> 0 Or Left$(Obj.Text, 1) = "K" Then KeyAscii = 0
    Else
        If KeyAscii < 48 Or KeyAscii > 57 Then KeyAscii = 0
    End If
End If
End Sub

'accept only numbers
Public Sub AllowNumberKeysOnly(KeyAscii As Integer, Obj As TextBox)
    If (KeyAscii < 48 Or KeyAscii > 57) And KeyAscii <> 8 Then KeyAscii = 0
End Sub

Public Sub CorrectName(Obj As TextBox)
'fix names typed in all lowercase or all uppercase by setting first character
'uppercase and following characters to lowercase.
'note that it does allow names such as McIverson.
Dim Text As String
With Obj
    Text = Trim$(.Text)
    If Text = UCase$(Text) Or Text = LCase$(Text) Then
        Text = UCase$(Left$(Text, 1)) & LCase$(Mid$(Text, 2))
    Else
        Text = UCase$(Left$(Text, 1)) & Mid$(Text, 2)
    End If
    If Right$(Text, 1) = "." Then Text = Left$(Text, Len(Text) - 1)
    .Text = Text
    .SelStart = 0
    .SelLength = 32767
End With

End Sub

'for K numbers, simply add one billion, since no SSN is that high,
'nor is expected to be that high for at least the next half century.
'originally I thought of signifying a knumber with initial zeroes,
'but then there is a the problem of New Jersey.
Public Function GetNumericSid(Text As String) As Long
    If Left$(Text, 1) = "K" Then
        GetNumericSid = Val(Mid$(Text, 2)) + 1000000000
    Else
        GetNumericSid = Val(Text)
    End If
End Function

'Simply to fix MS's inconsistency with path handling.
'If App.Path returns "C:\" it should also return "C:\Windows\"
'Either that or "C:\Windows" and "C:"
Public Function FixPath(Path As String)
    If Right$(Path, 1) <> "\" Then
        FixPath = Path & "\"
    Else
        FixPath = Path
    End If
End Function
