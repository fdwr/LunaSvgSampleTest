VERSION 5.00
Begin VB.Form frmChkKeys 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "[Keys Pressed]"
   ClientHeight    =   4545
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   4680
   Icon            =   "ChkKeys.frx":0000
   LinkTopic       =   "Form1"
   MinButton       =   0   'False
   ScaleHeight     =   4545
   ScaleWidth      =   4680
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdHide 
      Cancel          =   -1  'True
      Caption         =   "Hide"
      Height          =   255
      Left            =   2640
      TabIndex        =   4
      Top             =   120
      Width           =   855
   End
   Begin VB.CommandButton cmdClose 
      Caption         =   "Close"
      Height          =   255
      Left            =   3600
      TabIndex        =   5
      Top             =   120
      Width           =   975
   End
   Begin VB.CommandButton cmdEnable 
      Caption         =   "Disabled..."
      Height          =   255
      Left            =   120
      TabIndex        =   2
      Top             =   120
      Width           =   1455
   End
   Begin VB.TextBox txtTest 
      Height          =   285
      Left            =   120
      Locked          =   -1  'True
      TabIndex        =   0
      Text            =   "(type in here to test)"
      Top             =   480
      Width           =   4455
   End
   Begin VB.CommandButton cmdSave 
      Caption         =   "Save..."
      Height          =   255
      Left            =   1680
      TabIndex        =   3
      Top             =   120
      Width           =   855
   End
   Begin VB.Timer tmrCheckKeys 
      Enabled         =   0   'False
      Interval        =   50
      Left            =   120
      Top             =   1200
   End
   Begin VB.ListBox lstKeysPressed 
      Height          =   3570
      Left            =   120
      TabIndex        =   1
      Top             =   840
      Width           =   4455
   End
   Begin VB.Menu mnuKeyFilter 
      Caption         =   "(key filter)"
      Visible         =   0   'False
      Begin VB.Menu mnuKeyFilterValue 
         Caption         =   "Keys down only"
         Index           =   0
      End
      Begin VB.Menu mnuKeyFilterValue 
         Caption         =   "Keys up only"
         Index           =   1
      End
      Begin VB.Menu mnuKeyFilterValue 
         Caption         =   "Presses and releases"
         Index           =   2
      End
      Begin VB.Menu mnuKeyFilterValue 
         Caption         =   "Disabled"
         Index           =   3
      End
   End
End
Attribute VB_Name = "frmChkKeys"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Declare Function GetAsyncKeyState Lib "user32" (ByVal vKey As Long) As Integer
Private Declare Function ShowWindow Lib "user32" (ByVal hWnd As Long, ByVal nCmdShow As Long) As Long
Private Declare Function FindWindow Lib "user32" Alias "FindWindowA" (ByVal lpClassName As String, ByVal lpWindowName As String) As Long
Private Declare Function MapVirtualKey Lib "user32" Alias "MapVirtualKeyA" (ByVal uCode As Integer, ByVal uMapType As Integer) As Long
Private Declare Function GetKeyNameText Lib "user32" Alias "GetKeyNameTextA" (ByVal lParam As Long, ByVal lpString As String, ByVal nSize As Integer) As Long
'UINT MapVirtualKey(
'  UINT uCode,     // virtual-key code or scan code
'  UINT uMapType   // translation to perform
');
'0 uCode is a virtual-key code and is translated into a scan code. If it is a virtual-key code that does not distinguish between left- and right-hand keys, the left-hand scan code is returned. If there is no translation, the function returns 0.
'2 uCode is a virtual-key code and is translated into an unshifted character value in the low-order word of the return value. Dead keys (diacritics) are indicated by setting the top bit of the return value. If there is no translation, the function returns 0.
'int GetKeyNameText(
'  LONG lParam,      // second parameter of keyboard message
'  LPTSTR lpString,  // buffer for key name
'  int nSize         // maximum length of key name
');
'BOOL AnimateWindow(
'  HWND hwnd,     // handle to window
'  DWORD dwTime,  // duration of animation
'  DWORD dwFlags  // animation type
');

Const MaxKeyChars = 1000

Private CurrentApp_hWnd As Long
Private KeysDown(255) As Integer
Private VirtualKeyNames(255) As String
Private VirtualKeyChars(255) As Byte
Private KeyValueIgnore As Integer

Private Sub cmdClose_Click()
    End
End Sub

Private Sub cmdEnable_Click()
    Dim KeyValue As Integer, Count As Long

    PopupMenu mnuKeyFilter, , cmdEnable.Left, cmdEnable.Top
End Sub

Private Sub cmdHide_Click()
    Hide
End Sub

Private Sub cmdSave_Click()
    Dim Count As Integer

    Open "c:\temp\keys.txt" For Output As 1
    For Count = 0 To lstKeysPressed.ListCount - 1
        Print #1, lstKeysPressed.List(Count)
    Next
    Close 1
End Sub

Private Sub Form_Load()
    Dim PrevHwnd As Long
    Dim Count As Long, Text As String, TextLen As Long, ScanCode As Long

    If App.PrevInstance Then
        PrevHwnd = FindWindow("ThunderRT6FormDC" & vbNullChar, "Keys Pressed")
        'txtTest.Text = PrevHwnd
        ShowWindow PrevHwnd, 5
        End
    End If
    Caption = "Keys Pressed"
    txtTest.SelStart = 16384
    Text = Space(64)
    For Count = 1 To 255
        VirtualKeyChars(Count) = MapVirtualKey(Count, 2)
        ScanCode = MapVirtualKey(Count, 0)
        TextLen = GetKeyNameText(ScanCode * 65536, Text, Len(Text))
        VirtualKeyNames(Count) = Left(Text, TextLen)
        'lstKeysPressed.AddItem Text
    Next
End Sub

Private Sub Form_Resize()
    Dim ControlSize As Long

    ControlSize = Width - 360
    txtTest.Width = ControlSize
    lstKeysPressed.Width = ControlSize
    ControlSize = Height - 10 * 120
    If ControlSize < 120 Then ControlSize = 120
    lstKeysPressed.Height = ControlSize
End Sub

Private Sub mnuKeyFilterValue_Click(Index As Integer)
    Dim Count As Long, ChkEnabled As Boolean, KeyValue As Integer

    KeyValueIgnore = Index
    For Count = 0 To 3
        mnuKeyFilterValue(Count).Checked = Count = Index
    Next

    Select Case Index
    Case 0: cmdEnable.Caption = "Key presses..."
    Case 1: cmdEnable.Caption = "Key release..."
    Case 2: cmdEnable.Caption = "All keys..."
    Case 3: cmdEnable.Caption = "Disabled..."
    End Select

    ChkEnabled = (Index < 3)
    If ChkEnabled Then
        txtTest.SetFocus
        For Count = 8 To 255
            KeyValue = GetAsyncKeyState(Count)
            If KeyValue Then KeyValue = 1
            KeysDown(Count) = KeyValue
        Next
    End If
    tmrCheckKeys.Enabled = ChkEnabled
End Sub

Private Sub tmrCheckKeys_Timer()
    Dim KeyValue As Integer, Count As Long, KeyDir As String, KeyChange As Boolean

    For Count = 8 To 255
        KeyValue = GetAsyncKeyState(Count)
        If KeyValue Then KeyValue = 1
        If KeyValue <> KeysDown(Count) Then
            KeyChange = True
            KeysDown(Count) = KeyValue
            If KeyValue <> KeyValueIgnore Then
                If KeyValue Then
                    txtTest.SelText = Chr(VirtualKeyChars(Count))
                    KeyDir = " +"
                Else
                    KeyDir = " -"
                End If
                lstKeysPressed.AddItem Str(Count) & vbTab & "(" & Chr(Count) & ")" & KeyDir & vbTab & VirtualKeyNames(Count)
            End If
        'End If
        End If
    Next
    If KeyChange Then
        lstKeysPressed.ListIndex = lstKeysPressed.NewIndex
        Do While lstKeysPressed.ListCount > MaxKeyChars
            lstKeysPressed.RemoveItem 0
        Loop
        If Len(txtTest.Text) > MaxKeyChars + 100 Then
            txtTest.Text = Right(txtTest.Text, MaxKeyChars)
        End If
    End If
End Sub
