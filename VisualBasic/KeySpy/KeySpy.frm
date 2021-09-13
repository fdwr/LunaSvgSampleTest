VERSION 5.00
Begin VB.Form frmKeySpy 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Key Spy"
   ClientHeight    =   4365
   ClientLeft      =   2940
   ClientTop       =   1800
   ClientWidth     =   5025
   Icon            =   "KeySpy.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   4365
   ScaleWidth      =   5025
   Begin VB.CommandButton cmdHide 
      Caption         =   "Hide"
      Enabled         =   0   'False
      Height          =   375
      Left            =   1440
      TabIndex        =   4
      Top             =   3840
      Width           =   1215
   End
   Begin VB.CommandButton cmdClear 
      Caption         =   "Clear"
      Height          =   375
      Left            =   120
      TabIndex        =   3
      Top             =   3840
      Width           =   1215
   End
   Begin VB.Timer tmrCheckKeys 
      Interval        =   50
      Left            =   4680
      Top             =   0
   End
   Begin VB.TextBox txtKeys 
      Height          =   3255
      Left            =   2520
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   2
      Top             =   480
      Width           =   2415
   End
   Begin VB.ListBox lstKeys 
      Height          =   3255
      IntegralHeight  =   0   'False
      Left            =   120
      TabIndex        =   1
      Top             =   480
      Width           =   2295
   End
   Begin VB.TextBox txtTestKeys 
      Height          =   285
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   4815
   End
End
Attribute VB_Name = "frmKeySpy"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub cmdClear_Click()
    txtKeys.Text = ""
    lstKeys.Clear
End Sub

Private Sub Form_Load()
Dim KeyCode As Long
Dim ScanCode As Long

For KeyCode = 1 To 254
    ScanCode = MapVirtualKey(KeyCode, 0) And 255
    KeyScancodes(KeyCode) = ScanCode
    GetKeyNameText ScanCode * 65536, KeyNameBuffer, Len(KeyNameBuffer)
    KeyNames(ScanCode) = Trim$(KeyNameBuffer)
    KeysDown(KeyCode) = (GetAsyncKeyState(KeyCode) And 32768) \ 256&
Next

End Sub

Private Sub tmrCheckKeys_Timer()
Dim KeyCode As Long
Dim State As Long

For KeyCode = 1 To 254
    State = (GetAsyncKeyState(KeyCode) And 32768) \ 256&
    'lstKeys.AddItem State, 0
    If State <> KeysDown(KeyCode) Then
        KeysDown(KeyCode) = State
        If State And 128 Then
            txtKeys.SelStart = 32767
            If KeyCode = vbKeyReturn Then
                txtKeys.SelText = vbNewLine
            ElseIf KeyCode >= 32 Then
                'ToAscii(KeyCode, KeyScancodes(KeyCode) Or -32768, KeysDown(0), ByVal StrPtr(AsciiChars), 0)
                'txtKeys.SelText = AsciiChars
                txtKeys.SelText = Chr$(KeyCode)
            End If
            lstKeys.AddItem KeyNames(KeyScancodes(KeyCode))
            lstKeys.ListIndex = lstKeys.NewIndex
        End If
    End If
Next
End Sub
