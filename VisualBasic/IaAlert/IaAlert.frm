VERSION 5.00
Begin VB.Form frmIaAlert 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "IA Alert"
   ClientHeight    =   6405
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   9510
   Icon            =   "IaAlert.frx":0000
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   427
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   634
   StartUpPosition =   3  'Windows Default
   Begin VB.Timer tmrCheckMsgs 
      Interval        =   10000
      Left            =   8925
      Top             =   5820
   End
   Begin VB.Timer tmrAnimate 
      Enabled         =   0   'False
      Interval        =   20
      Left            =   480
      Top             =   2610
   End
   Begin VB.Frame fraEverything 
      BorderStyle     =   0  'None
      Caption         =   "Frame1"
      Height          =   6855
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   9510
      Begin VB.Frame Frame11 
         BorderStyle     =   0  'None
         Caption         =   "Frame1"
         Height          =   150
         Left            =   60
         TabIndex        =   24
         Top             =   6210
         Width           =   840
      End
      Begin VB.Frame Frame10 
         BorderStyle     =   0  'None
         Caption         =   "Frame1"
         Height          =   195
         Left            =   105
         TabIndex        =   23
         Top             =   5250
         Width           =   840
      End
      Begin VB.Frame Frame9 
         BorderStyle     =   0  'None
         Caption         =   "Frame1"
         Height          =   195
         Left            =   75
         TabIndex        =   22
         Top             =   4290
         Width           =   840
      End
      Begin VB.Frame Frame8 
         BorderStyle     =   0  'None
         Caption         =   "Frame1"
         Height          =   150
         Left            =   105
         TabIndex        =   21
         Top             =   2955
         Width           =   840
      End
      Begin VB.Frame Frame7 
         BorderStyle     =   0  'None
         Caption         =   "Frame1"
         Height          =   195
         Left            =   60
         TabIndex        =   20
         Top             =   2010
         Width           =   840
      End
      Begin VB.Frame Frame6 
         BorderStyle     =   0  'None
         Caption         =   "Frame1"
         Height          =   165
         Left            =   75
         TabIndex        =   19
         Top             =   1080
         Width           =   840
      End
      Begin VB.Frame Frame5 
         BorderStyle     =   0  'None
         Caption         =   "Frame1"
         Height          =   2025
         Left            =   30
         TabIndex        =   18
         Top             =   4305
         Width           =   135
      End
      Begin VB.Frame Frame3 
         BorderStyle     =   0  'None
         Caption         =   "Frame1"
         Height          =   2025
         Left            =   810
         TabIndex        =   16
         Top             =   4335
         Width           =   150
         Begin VB.Frame Frame4 
            BorderStyle     =   0  'None
            Caption         =   "Frame1"
            Height          =   2025
            Left            =   0
            TabIndex        =   17
            Top             =   30
            Width           =   150
         End
      End
      Begin VB.Frame Frame2 
         BorderStyle     =   0  'None
         Caption         =   "Frame1"
         Height          =   2025
         Left            =   30
         TabIndex        =   15
         Top             =   1080
         Width           =   135
      End
      Begin VB.Frame Frame1 
         BorderStyle     =   0  'None
         Caption         =   "Frame1"
         Height          =   2025
         Left            =   810
         TabIndex        =   14
         Top             =   1080
         Width           =   150
      End
      Begin VB.CommandButton cmdClearTransferred 
         Appearance      =   0  'Flat
         Caption         =   "&Clear"
         Enabled         =   0   'False
         Height          =   855
         Left            =   120
         Picture         =   "IaAlert.frx":0442
         Style           =   1  'Graphical
         TabIndex        =   13
         TabStop         =   0   'False
         ToolTipText     =   "Clears all received/sent messages"
         Top             =   5400
         Width           =   735
      End
      Begin VB.CommandButton cmdViewMsg 
         Appearance      =   0  'Flat
         Caption         =   "&View"
         Enabled         =   0   'False
         Height          =   855
         Left            =   120
         Picture         =   "IaAlert.frx":0884
         Style           =   1  'Graphical
         TabIndex        =   12
         TabStop         =   0   'False
         ToolTipText     =   "Views the selected message in case the line is too long"
         Top             =   4440
         Width           =   735
      End
      Begin VB.CommandButton cmdSendMsg 
         Appearance      =   0  'Flat
         Caption         =   "&Send"
         Default         =   -1  'True
         Height          =   855
         Left            =   120
         Picture         =   "IaAlert.frx":0CC6
         Style           =   1  'Graphical
         TabIndex        =   11
         TabStop         =   0   'False
         ToolTipText     =   "Sends your message to any assistants listening (can also press Enter)"
         Top             =   1200
         Width           =   735
      End
      Begin VB.CommandButton cmdAbout 
         Appearance      =   0  'Flat
         Caption         =   "&Help"
         Height          =   855
         Left            =   120
         Picture         =   "IaAlert.frx":1108
         Style           =   1  'Graphical
         TabIndex        =   10
         TabStop         =   0   'False
         ToolTipText     =   "What the program does and who wrote it..."
         Top             =   2160
         Width           =   735
      End
      Begin VB.CommandButton cmdResetMsgs 
         Caption         =   "&Reset"
         Height          =   375
         Left            =   120
         TabIndex        =   5
         TabStop         =   0   'False
         ToolTipText     =   "Clears the previous message list"
         Top             =   1680
         Visible         =   0   'False
         Width           =   735
      End
      Begin VB.ComboBox cboMsg 
         BackColor       =   &H00A56E3A&
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   8.25
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H00C0FFC0&
         Height          =   2910
         Left            =   960
         Style           =   1  'Simple Combo
         TabIndex        =   4
         ToolTipText     =   "Type in your message and press Enter, or double-click one previously typed"
         Top             =   120
         Width           =   8535
      End
      Begin VB.ListBox lstTransferredMsgs 
         BackColor       =   &H00A56E3A&
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   8.25
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H00C0FFC0&
         Height          =   3150
         IntegralHeight  =   0   'False
         ItemData        =   "IaAlert.frx":154A
         Left            =   960
         List            =   "IaAlert.frx":154C
         TabIndex        =   7
         ToolTipText     =   "Double click on one of the received messages to view it"
         Top             =   3240
         Width           =   8535
      End
      Begin VB.Label Label1 
         Alignment       =   1  'Right Justify
         Caption         =   "Message:"
         Height          =   255
         Left            =   120
         TabIndex        =   2
         Top             =   165
         Width           =   735
      End
      Begin VB.Label Label2 
         Alignment       =   1  'Right Justify
         Caption         =   "Standard messages:"
         Height          =   495
         Left            =   120
         TabIndex        =   3
         Top             =   480
         Width           =   735
      End
      Begin VB.Label Label4 
         Alignment       =   1  'Right Justify
         Caption         =   "Previous messages:"
         Height          =   495
         Left            =   120
         TabIndex        =   6
         Top             =   3240
         Width           =   735
      End
      Begin VB.Label Label5 
         BorderStyle     =   1  'Fixed Single
         Height          =   60
         Left            =   0
         TabIndex        =   1
         Top             =   3105
         Width           =   9510
      End
   End
   Begin VB.PictureBox Picture1 
      BackColor       =   &H80000001&
      Enabled         =   0   'False
      Height          =   5295
      Left            =   720
      ScaleHeight     =   5235
      ScaleWidth      =   7995
      TabIndex        =   8
      TabStop         =   0   'False
      Top             =   600
      Width           =   8055
      Begin VB.Label lblAbout 
         BackStyle       =   0  'Transparent
         BeginProperty Font 
            Name            =   "Arial"
            Size            =   9.75
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H00C0FFC0&
         Height          =   5655
         Left            =   120
         TabIndex        =   9
         Top             =   120
         Width           =   7815
      End
   End
End
Attribute VB_Name = "frmIaAlert"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Window to send to and receive messages
'Stores previous messages in list so common messages need not be retyped
'Read modIaAlert for program info
'
'2002-01-30 created
'2003-06-30 updated

'Secrets:
'   You can direct a message to a specific computer only rather
'   than broadcasting to all alert programs by typing an @ sign
'   followed by the computer name, space, message.
'
'   @PC218-04 Test message
'
'   You can send multiline messages by pressing Ctrl+Enter
Option Explicit

Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lparam As Any) As Long
Private Const LB_SETTABSTOPS = &H192

Private DefCaption As String

Private Sub cboMsg_DblClick()
    cmdSendMsg_Click
End Sub

Private Sub cboMsg_GotFocus()
    cmdSendMsg.Default = True
End Sub

Private Sub cboMsg_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyReturn And (Shift = vbCtrlMask) Then
        cboMsg.SelText = vbTab 'vbNewLine
        KeyCode = 0
    End If
End Sub

Private Sub cmdAbout_Click()
    SetWndTitle "Help"
    lblAbout.Caption = "IA Alert - help message sender" & vbNewLine _
                     & "By Dwayne Robinson (FDwR@hotmail.com)" & vbNewLine _
                     & "http://fdwr.tripod.com/" & vbNewLine _
                     & "2001-12-09 / 2002-05-06" & vbNewLine & vbNewLine _
                     & "Story:" & vbNewLine _
                     & "You are in the middle of your lecture and tell the class to print their work, " _
                     & "but the printer won't work, giving some obscure error that means nothing to " _
                     & "you. Perhaps, instead, the overhead projector with which you are trying to show " _
                     & "the class something doesn't work. So you " _
                     & "consider exiting the classroom and walking upstairs to the Open Lab for help. " _
                     & "Why interrupt your class, when you can alert them right from where " _
                     & "you are standing?" & vbNewLine & vbNewLine _
                     & "Long story made short:" & vbNewLine _
                     & "This program sends little 'help me!' messages to the " _
                     & "active lab assistants, who hearing your pleas, can come gallantly to your " _
                     & "rescue." & vbNewLine & vbNewLine _
                     & "Tech note:" & vbNewLine _
                     & "The program uses mailslots for delivery. It broadcasts the typed message to " _
                     & "any machines with an open local iaalert mailslot (in other words, this program " _
                     & "is active on their machine too). That means that multiple lab assistants and even " _
                     & "other instructors can see the messages."
    fraEverything.Visible = False
    tmrAnimate.Enabled = True 'start animation
End Sub

Private Sub cmdClearTransferred_Click()
    lstTransferredMsgs.Clear
    cmdViewMsg.Enabled = False
    cmdClearTransferred.Enabled = False
    cboMsg.SetFocus
    SetWndTitle "List cleared"
End Sub

Private Sub cmdResetMsgs_Click()
    cboMsg.SetFocus
    'If cboMsg.ListCount <= 0 Then
    '    MsgBox "Clearly, it's already cleared."
    '    Exit Sub
    'End If
    On Error GoTo IgnoreNoKill
    cboMsg.Clear
    AddStandardMsgs
    Kill MsgFile
    AddStandardMsgs
    SetWndTitle "List cleared"
IgnoreNoKill:
End Sub

Private Sub cmdSendMsg_Click()
    Dim Msg As String
    Dim DestPc As String

    With cboMsg
        If Len(.Text) <= 0 Then
            MsgBox "Type in a message to send"
            .SelStart = 0
            .SelLength = 32767
            .SetFocus
            Exit Sub
        End If
    End With

  #If DebugVersion Then
    Msg = "NONAME" & vbTab & cboMsg.Text
    SendMsg Msg, PcName  'send to myself for debugging
  #Else
    DestPc = "*"
    Msg = cboMsg.Text
    If Left$(Msg, 1) = "@" Then
        Dim CharPos As Long
        CharPos = InStr(Msg + " ", " ")
        DestPc = Mid$(Msg, 2, CharPos - 2)
        Msg = Trim$(Mid$(Msg, CharPos))
    End If
    Msg = PcName & vbTab & Msg
    SetWndTitle "Sending message to \\" & DestPc & MailSlotPath
    SendMsg Msg, DestPc
  #End If
    AddTransferredMsg Msg
    'cboMsg.ListIndex = 0
    SetWndTitle "Waiting for reply..."
End Sub

Private Sub cmdViewMsg_Click()
    ShowTransferredMsg vbInformation, "Previous message"
End Sub

Private Sub Form_Click()
    EndAnimation
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyF1 Then
        cmdAbout_Click
    ElseIf tmrAnimate.Enabled Then
        EndAnimation
    ElseIf KeyCode = vbKeyEscape Then
        WindowState = vbMinimized
    End If
End Sub

Private Sub Form_Load()
'init mail slot
'load messages

    'I would use the StartUpPosition
    'here instead of manually setting it,
    'if it weren't for the stupid fact
    'that VB does it after the form load.
    Dim ScreenHeight As Long
    ScreenHeight = Screen.Height
    If ScreenHeight <= 7200 Then
        Top = 0
    Else
        Top = (ScreenHeight - Height) \ 2
    End If
    Left = (Screen.Width - Width) \ 2

    SetWndTitle "Initializing mailslot messaging..."
    With IconData
    .cbSize = Len(IconData)
    ' The length of the NOTIFYICONDATA type
    .hIcon = Icon
    ' A reference to the form's icon
    .hwnd = hwnd
    ' hWnd of the form
    .szTip = ProgramTitle & vbNullChar
    ' Tooltip string delimited with a null character
    .uCallbackMessage = WM_MOUSEMOVE
    ' The icon we're placing will send messages to the MouseMove event
    .uFlags = NIF_ICON Or NIF_TIP Or NIF_MESSAGE
    ' It will have message handling and a tooltip
    .uID = vbNull
    ' uID is not used by VB, so it's set to a Null value
    End With

    If Command$ = "/ia" Then WindowState = vbMinimized
    
    Show
    
    InitMsgs

    SetWndTitle "Loading messages..."
    SetListTabStops lstTransferredMsgs.hwnd, 35, 80
    Dim Msg As String
    On Error GoTo NoMsgFile
    Open MsgFile For Input As 1
    With cboMsg
        Do Until EOF(1)
            Line Input #1, Msg
            .AddItem Msg
        Loop
    End With
    Close 1
NoMsgFile:
    On Error GoTo 0
    AddStandardMsgs

    DefCaption = ProgramTitle & " - " & PcName
    Caption = DefCaption

End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, x As Single, y As Single)
    Dim Msg As Long
    Msg = x ' The message is passed to the X value

    ' You must set your form's ScaleMode property to pixels in order to get the correct message
    If Msg = WM_LBUTTONDOWN Then ReshowForm
    ' The user has clicked your icon in the system tray
End Sub

Private Sub Form_Resize()

If WindowState = vbMinimized Then
    'The user has minimized his window
    Call Shell_NotifyIcon(NIM_ADD, IconData)
    ' Add the form's icon to the tray
    Hide
    ' Hide the button at the taskbar
End If

End Sub

Private Sub Form_Unload(Cancel As Integer)

    'check that they aren't trying to simply
    'close the help
    If fraEverything.Visible = False Then
        Cancel = True
        EndAnimation
        Exit Sub
    End If

'release mail slot
'store messages

    SetWndTitle "Releasing mailslot messaging..."
    DeinitMsgs

#If 0 Then
    If MsgsChanged Then
        SetWndTitle "Storing messages..."
        With cboMsg
            Dim Msg As String
            Dim Idx As Long

            On Error GoTo NoMsgFile
            Open MsgFile For Input As 1
            Do Until EOF(1)
                Line Input #1, Msg
                Idx = SendMessageStr(.hwnd, CB_FINDSTRINGEXACT, -1, ByVal Msg)
                If Idx = -1 Then .AddItem Msg, 0
            Loop
            Close 1
NoMsgFile:
            On Error GoTo 0
            On Error GoTo NoChanges
            Open MsgFile For Output As 1
            Dim Count As Long
            On Error GoTo AbortStore
            For Count = 0 To .ListCount - 1
                Print #1, .List(Count)
            Next
AbortStore: Close 1
        End With
    End If
NoChanges:
#End If

    Shell_NotifyIcon NIM_DELETE, IconData

End Sub

Private Sub EndAnimation()
    tmrAnimate.Enabled = False
    fraEverything.Visible = True
    Caption = DefCaption
End Sub

Private Sub lstTransferredMsgs_DblClick()
    cmdViewMsg_Click
End Sub

Private Sub lstTransferredMsgs_GotFocus()
    cmdViewMsg.Default = True
End Sub

Private Sub tmrAnimate_Timer()
    Static BaseRow As Long, BaseClr As Long
    Dim Row As Long, Clr As Long
    Dim FrmWidth As Long, FrmHeight As Long

    Clr = BaseClr
    FrmWidth = ScaleWidth
    FrmHeight = ScaleHeight
    For Row = BaseRow To FrmWidth + FrmHeight Step 20
        Line (0, Row)-(FrmWidth, Row - FrmWidth), Clr
        Clr = ((Clr And &H7F7F7F) + &H9080A) Or &H808080
    Next
    BaseClr = ((BaseClr And &H7F7F7F) + &H10203) Or &H808080
    BaseRow = (BaseRow + 1) Mod 20
End Sub

Private Sub tmrCheckMsgs_Timer()
'checks for mew messages periodically
'loops until all messages waiting have been read
'since sending a message to everyone includes the sending
'  computer, a copy also gets returned. so ignore any
'  self-referential messages.
'don't know why, but one some computers two messages come
'  back instead of just one. so I put a hack to ignore dups.

    Dim Msg As String, PrevMsg As String

    If ReadMsg(Msg) Then
        Do
            If GetMsgSrcPc(Msg) <> PcName Then
                If Msg <> PrevMsg Then
                    AddTransferredMsg Msg
                    ShowTransferredMsg vbExclamation Or MB_TASKMODAL Or MB_SETFOREGROUND Or MB_TOPMOST, "Incoming Message"
                    ReshowForm
                    Caption = DefCaption
                End If
            End If
            PrevMsg = Msg
        Loop While ReadMsg(Msg)
    End If
End Sub

Private Sub AddMsg(Msg As String)
    Dim Idx As Long

    With cboMsg
        Idx = SendMessageStr(.hwnd, CB_FINDSTRINGEXACT, -1, ByVal Msg)
        If Idx >= 0 Then
            .RemoveItem Idx
        End If
        .AddItem Msg, 0
        'MsgsChanged = True
    End With
End Sub

Public Function GetMsgSrcPc(Msg As String) As String
    Dim MsgPos As Long

    MsgPos = InStr(Msg, vbTab) - 1
    If MsgPos < 0 Then MsgPos = 0
    GetMsgSrcPc = Left$(Msg, MsgPos)
End Function

Public Sub ReshowForm()
    If WindowState = vbMinimized Then
        Shell_NotifyIcon NIM_DELETE, IconData
    End If
    WindowState = vbNormal
    Show
    SetWindowPos hwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE Or SWP_NOMOVE
    'SetWindowPos hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOSIZE Or SWP_NOMOVE
    ' the statement below seems redundant since SetWindowPos 'should'
    ' activate the window, but alas, it does not always for who knows why
    SetForegroundWindow hwnd
End Sub

Public Sub AddStandardMsg(Msg As String)
    With cboMsg
        If SendMessageStr(.hwnd, CB_FINDSTRINGEXACT, -1, ByVal Msg) < 0 Then .AddItem Msg
    End With
End Sub

Public Sub SetWndTitle(NewTitle)
    Caption = ProgramTitle & " - " & NewTitle
End Sub

Public Sub AddStandardMsgs()
    If Command$ = "/ia" Then
        AddStandardMsg "Be there soon"
    Else
        AddStandardMsg "EMERGENCY, CALL SECURITY"
        AddStandardMsg "Please send instructional assistance ASAP"
        AddStandardMsg "Could use instructional assistance if available"
        AddStandardMsg "Need assistance with instructor equipment"
        AddStandardMsg "Need assistance with student station"
        AddStandardMsg "Please send someone to lock door"
        AddStandardMsg "Printer is not working (Help ASAP)"
        AddStandardMsg "Printer is not working (FYI)"
        AddStandardMsg "LCD projector is not working (Help ASAP)"
        AddStandardMsg "LCD projector Is Not working(FYI)"
        AddStandardMsg "Toner Low Message"
    End If
End Sub

Public Sub SetListTabStops(ListHandle As Long, _
    ParamArray ParmList() As Variant)
    Dim i As Long
    Dim ListTabs() As Long
    Dim NumColumns As Long

    ReDim ListTabs(UBound(ParmList))
    For i = 0 To UBound(ParmList)
        ListTabs(i) = ParmList(i)
    Next i
    NumColumns = UBound(ParmList) + 1

    Call SendMessage(ListHandle, LB_SETTABSTOPS, _
        NumColumns, ListTabs(0))
End Sub

Public Sub ShowTransferredMsg(Mode As Long, Title As String)
    MsgBox Replace(lstTransferredMsgs.Text, vbTab, vbNewLine), Mode, Title
End Sub

Public Sub AddTransferredMsg(Msg As String)
    With lstTransferredMsgs
    .AddItem Format(Now, "HH:mm:ss ") & vbTab & Msg, 0
    .ListIndex = 0
    End With
    cmdViewMsg.Enabled = True
    cmdClearTransferred.Enabled = True
End Sub
