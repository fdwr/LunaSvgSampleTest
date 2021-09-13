Attribute VB_Name = "modGateway"
Option Explicit

Public Declare Function GetTickCount Lib "kernel32" () As Long
Public Declare Function GetKeyboardState Lib "user32" (pbKeyState As Byte) As Long
Public Declare Function SetKeyboardState Lib "user32" (lppbKeyState As Byte) As Long

Public Const DbFilenameDef = "StudentLog.mdb"
Public Const AverageDuration = 0.04167 'average duration for students using lab, 1/24 or one hour

Public Db As Database
Public DbTbl As Recordset
Public DbIsOpen As Boolean
Public DbFilename As String
Public DbErrMsg As String
Public DbErrNum As Long
Public StudentTbl As Recordset
Public AppPath As String

Public Sub Main()
    AppPath = App.Path
    If Right(AppPath, 1) <> "\" Then AppPath = AppPath & "\"
    frmGateway.Show
End Sub

Public Sub OpenDbTable(Table As String)
    'attempt open database, catching those annoying errors!
    On Error GoTo OpenDbErr
    If Not DbTbl Is Nothing Then If DbTbl.Name = Table Then Exit Sub
    If Db Is Nothing Then Set Db = OpenDatabase(DbFilename)
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
'does not work under Win2k!?
Public Sub CorrectKeyStates()
    Const VK_NUMLOCK = &H90, VK_SCROLL = &H91, VK_CAPITAL = &H14
    Dim Keys(255) As Byte

    GetKeyboardState Keys(0)
    Keys(VK_NUMLOCK) = 1
    Keys(VK_CAPITAL) = 0
    SetKeyboardState Keys(0)
End Sub

Public Sub AllowNumberKeysOnly(KeyAscii As Integer, Obj As TextBox)
'accept only numbers, ignoring hyphens, space, and letters
If KeyAscii >= 32 Then
    'txtStudentId.SelStart
    If KeyAscii = 107 Then KeyAscii = 75
    If KeyAscii = 75 Then
        If Len(Obj.Text) > 0 Then KeyAscii = 0
    Else
        If KeyAscii < 48 Or KeyAscii > 57 Then KeyAscii = 0
    End If
End If
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
