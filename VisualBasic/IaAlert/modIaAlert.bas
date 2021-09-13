Attribute VB_Name = "modIaAlert"
'2002-01-30 Add system tray behaviour to minimizing
'2002-04-22 Allows only one instance now

Option Explicit

'simply contains global variables and constants
Public Const InsMsgFileName As String = "InstructorMsgs.txt"
Public Const IaMsgFileName As String = "AssistantMsgs.txt"
Public Const ProgramTitle As String = "IA Alert"
Public Const MaxMsgs As Long = 20

Public Declare Function SendMessage Lib "user32" Alias "SendMessageA" _
   (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As _
    Long, ByVal lparam As Long) As Long
Public Declare Function SendMessageStr Lib "user32" Alias "SendMessageA" _
   (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As _
    Long, ByVal lparam As Any) As Long
Public Declare Function SetForegroundWindow Lib "user32" _
    (ByVal hwnd As Long) As Long
Public Declare Function GetWindowText Lib "user32" Alias "GetWindowTextA" _
    (ByVal hwnd As Long, ByVal lpString As String, ByVal cch As Long) As Long
Public Declare Function EnumWindows Lib "user32" (ByVal lpEnumFunc As Long, ByVal lparam As Long) As Long

'Public Declare Function FindWindow Lib "user32" Alias "FindWindowA" _
'    (ByVal lpClassName As String, ByVal lpWindowName As String) As Long
'Public Declare Function GetClassName Lib "user32" Alias "GetClassNameA" _
'    (ByVal hwnd As Long, ByVal lpClassName As String, ByVal nMaxCount As Long) As Long
'Public Declare Function TextOut Lib "gdi32" Alias "TextOutA" _
'   (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, _
'    ByVal lpString As String, ByVal nCount As Long) As Long
'Public Declare Function CreateMutex Lib "kernel32" Alias "CreateMutexA" _
'    (lpMutexAttributes As Any, _
'     ByVal bInitialOwner As Long, ByVal lpName As String) As Long
'Public Declare Function GetLastError Lib "kernel32" () As Long

'constants for searching the ComboBox
Public Const CB_FINDSTRINGEXACT = &H158
Public Const CB_FINDSTRING = &H14C

'constants for searching the ListBox
Public Const LB_FINDSTRINGEXACT = &H1A2
Public Const LB_FINDSTRING = &H18F

Public Const MB_TASKMODAL = 8192&
Public Const MB_SETFOREGROUND = 65536
Public Const MB_TOPMOST = 262144

Public MsgsChanged As Boolean
Public AppPath As String
Public MsgFile As String

Public PrevHwnd As Long

Public Sub Main()
    'If App.PrevInstance Then

    'PrevHwnd = FindWindow(vbNullString, ProgramTitle & " -")
    'If PrevHwnd Then
    '    Dim TempStr As String * 128
    '    GetWindowText PrevHwnd, TempStr, Len(TempStr)
    '    MsgBox TempStr
    '    SetForegroundWindow PrevHwnd
    '    End
    'End If

    EnumWindows AddressOf WndEnumerator, 0
    If PrevHwnd Then
        SetForegroundWindow PrevHwnd
        SendMessage PrevHwnd, WM_MOUSEMOVE, 0, WM_LBUTTONDOWN
        End
    End If

    AppPath = App.Path
    If Right$(AppPath, 1) <> "\" Then AppPath = AppPath & "\"
    If Command$ = "/ia" Then
        MsgFile = AppPath & IaMsgFileName
    ElseIf Command$ = "" Then
        MsgFile = AppPath & InsMsgFileName
    Else
        MsgBox "The only valid command line parameter is '/ia'" & vbNewLine & "to start the program with the IA messages instead of usual instructor messages", vbInformation Or vbOKOnly, "IaAlert - Invalid Parameter"
    End If

    frmIaAlert.Show
End Sub

Public Function WndEnumerator(ByVal hwnd As Long, ByVal lparam As Long) As Long
    Dim WindowTitle As String * 100
    GetWindowText hwnd, WindowTitle, Len(WindowTitle)
    If InStr(WindowTitle, ProgramTitle & " -") Then
        PrevHwnd = hwnd
    Else
        WndEnumerator = True
    End If
End Function
