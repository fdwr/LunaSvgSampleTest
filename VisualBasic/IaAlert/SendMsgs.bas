Attribute VB_Name = "modSendMsgs"
Option Explicit

Public Type SECURITY_ATTRIBUTES
    nLength As Long
    lpSecurityDescriptor As Long
    bInheritHandle As Long
End Type

Public Type OVERLAPPED
    Internal As Long
    InternalHigh As Long
    offset As Long
    OffsetHigh As Long
    hEvent As Long
End Type

Declare Function CreateMailslot Lib "kernel32" Alias "CreateMailslotA" _
   (ByVal lpName As String, _
    ByVal nMaxMessageSize As Long, _
    ByVal lReadTimeout As Long, _
    ByVal lpSecurityAttributes As Long) As Long
'ByRef lpSecurityAttributes As SECURITY_ATTRIBUTES

Public Declare Function CloseHandle Lib "kernel32" _
   (ByVal hObject As Long) As Long

Public Declare Function ReadFile Lib "kernel32" _
   (ByVal hFile As Long, _
    ByVal lpBuffer As String, _
    ByVal nNumberOfBytesToRead As Long, _
    ByRef lpNumberOfBytesRead As Long, _
    ByVal lpOverlapped As Long) As Long
    'lpOverlapped As OVERLAPPED

Public Declare Function GetMailslotInfo Lib "kernel32" _
   (ByVal hMailslot As Long, _
    ByRef lpMaxMessageSize As Long, _
    ByRef lpNextSize As Long, _
    ByRef lpMessageCount As Long, _
    ByRef lpReadTimeout As Long) As Long

Public Declare Function GetLastError Lib "kernel32" () As Long

'Public Declare Function CreateFile Lib "kernel32" Alias "CreateFileA" (ByVal lpFileName As String, ByVal dwDesiredAccess As Long, ByVal dwShareMode As Long, lpSecurityAttributes As SECURITY_ATTRIBUTES, ByVal dwCreationDisposition As Long, ByVal dwFlagsAndAttributes As Long, ByVal hTemplateFile As Any) As Long
Public Declare Function CreateFile Lib "kernel32" Alias "CreateFileA" (ByVal lpFileName As String, ByVal dwDesiredAccess As Long, ByVal dwShareMode As Long, ByVal NulllpSecurityAttributes As Long, ByVal dwCreationDisposition As Long, ByVal dwFlagsAndAttributes As Long, ByVal hTemplateFile As Long) As Long

'Public Declare Function WriteFile Lib "kernel32" (ByVal hFile As Long, lpBuffer As Any, ByVal nNumberOfBytesToWrite As Long, lpNumberOfBytesWritten As Long, lpOverlapped As OVERLAPPED) As Long
Public Declare Function WriteFile Lib "kernel32" (ByVal hFile As Long, ByVal lpBuffer As String, ByVal nNumberOfBytesToWrite As Long, ByRef lpNumberOfBytesWritten As Long, ByVal lpOverlapped As Long) As Long

Public Declare Function GetComputerName Lib "kernel32" Alias "GetComputerNameA" (ByVal lpBuffer As String, nSize As Long) As Long

Public Declare Function SetWindowPos Lib "user32" _
   (ByVal hwnd As Long, _
    ByVal hWndInsertAfter As Long, _
    ByVal x As Long, _
    ByVal y As Long, _
    ByVal cx As Long, _
    ByVal cy As Long, _
    ByVal wFlags As Long) As Long

Public Const MailSlotPath As String = "\mailslot\iaalert"
Public Const GENERIC_WRITE = &H40000000
Public Const FILE_SHARE_WRITE = &H2
Public Const FILE_SHARE_READ = &H1
Public Const FILE_FLAG_SEQUENTIAL_SCAN = &H8000000
Public Const FILE_ATTRIBUTE_NORMAL = &H80
Public Const CREATE_ALWAYS = 2
Public Const OPEN_EXISTING = 3
Public Const INVALID_HANDLE_VALUE = -1

Public Const GWL_STYLE = -16
Public Const WS_EX_TOPMOST = &H8
Public Const SW_SHOWNORMAL = 1
Public Const SW_SHOWMAXIMIZED = 3
Public Const SPI_SETSCREENSAVEACTIVE = 17
Public Const SPIF_UPDATEINIFILE = &H1
Public Const SPIF_SENDWININICHANGE = &H2
Public Const HWND_BOTTOM = 1
Public Const HWND_NOTOPMOST = -2
Public Const HWND_TOP = 0
Public Const HWND_TOPMOST = -1
Public Const SWP_FRAMECHANGED = &H20
Public Const SWP_DRAWFRAME = SWP_FRAMECHANGED
Public Const SWP_HIDEWINDOW = &H80
Public Const SWP_NOACTIVATE = &H10
Public Const SWP_NOMOVE = &H2
Public Const SWP_NOCOPYBITS = &H100
Public Const SWP_NOOWNERZORDER = &H200
Public Const SWP_NOREDRAW = &H8
Public Const SWP_NOREPOSITION = SWP_NOOWNERZORDER
Public Const SWP_NOSIZE = &H1
Public Const SWP_NOZORDER = &H4
Public Const SWP_SHOWWINDOW = &H40
Public Const SPI_SCREENSAVERRUNNING = 97

Global hndMsgIn  As Long
Global hndMsgOut As Long
Global PcName As String

Private MsgCount As Long    'number of messages waiting
Private MsgSize As Long     'byte length of mail message
Private MaxMsgSize As Long
Private MsgTimeout As Long
Private MsgTransferred As Long
Private Result As Long

Public Function ReadMsg(Msg As String) As Boolean
' reads any mail sent to the local mailslot on this pc

    GetMailslotInfo hndMsgIn, MaxMsgSize, MsgSize, MsgCount, MsgTimeout
    If MsgCount > 0 And MsgSize > 0 Then
        Msg = String$(MsgSize, 32)
        ReadFile hndMsgIn, Msg, MsgSize, MsgTransferred, 0
        'MsgBox MsgCount & " message(s)" & vbNewLine & "Message is " & MsgSize & " bytes" & vbNewLine & Msg
        ReadMsg = True
    Else
        ReadMsg = False
    End If
End Function

Public Sub SendMsg(Msg As String, Dest As String)
    'MsgBox "Pretending to have sent message to " & Dest & "..."

    hndMsgOut = CreateFile("\\" & Dest & MailSlotPath & vbNullChar, GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0)

    If hndMsgOut = INVALID_HANDLE_VALUE Then
        MsgBox "Error opening remote computer's mailslot: " & Dest, vbExclamation
    Else
        If WriteFile(hndMsgOut, Msg, Len(Msg), MsgTransferred, 0) = 0 Then
            MsgBox "Write failed to " & Dest & vbNewLine _
                 & "Error code:" & GetLastError()
        End If
        'MsgBox "Bytes written: " & MsgTransferred
        'MsgsWritten = MsgsWritten + 1
        'lblWrittenSize.Caption = MsgsWritten & " messages sent, " & MsgWritten & " bytes written"
        CloseHandle hndMsgOut: hndMsgOut = 0
    End If
End Sub

Public Sub InitMsgs()
    'MsgBox "Creating local input mailslot"
    hndMsgIn = CreateMailslot("\\." & MailSlotPath & vbNullChar, 256, 500, 0)
    'MsgBox "Mailslot handle: " & hndMsgIn
    PcName = String$(256, 0)
    GetComputerName PcName, Len(PcName)
    PcName = Left$(PcName, InStr(PcName, vbNullChar) - 1)

    If hndMsgIn = INVALID_HANDLE_VALUE Then MsgBox "Could not create local mailslot: \\." & MailSlotPath & vbNewLine & "Error code:" & GetLastError(), vbExclamation
End Sub

Public Sub DeinitMsgs()
    'MsgBox "Closing input mailslot"
    CloseHandle hndMsgIn: hndMsgIn = 0
End Sub
