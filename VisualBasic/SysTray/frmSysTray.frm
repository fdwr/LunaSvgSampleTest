VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "System Tray example - VB Center"
   ClientHeight    =   4620
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   7155
   LinkTopic       =   "Form1"
   ScaleHeight     =   308
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   477
   StartUpPosition =   3  'Windows Default
   Begin VB.Label Label1 
      Caption         =   "Note that the form's ScaleMode property is set to 3- Pixels"
      Height          =   2295
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   4335
   End
   Begin VB.Menu mnuPopup 
      Caption         =   "Popup"
      Visible         =   0   'False
      Begin VB.Menu mnuShow 
         Caption         =   "&Show"
      End
      Begin VB.Menu mnuExit 
         Caption         =   "&Exit"
      End
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub Form_Resize()

If Me.WindowState = 1 Then
'The user has minimized his window

Call Shell_NotifyIcon(NIM_ADD, IconData)

' Add the form's icon to the tray

Me.Hide

' Hide the button at the taskbar

End If

End Sub

Private Sub Form_Load()

With IconData

.cbSize = Len(IconData)
' The length of the NOTIFYICONDATA type

.hIcon = Me.Icon
' A reference to the form's icon

.hwnd = Me.hwnd
' hWnd of the form

.szTip = "My Tooltip" & Chr(0)
' Tooltip string delimited with a null character

.uCallbackMessage = WM_MOUSEMOVE
' The icon we're placing will send messages to the MouseMove event

.uFlags = NIF_ICON Or NIF_TIP Or NIF_MESSAGE
' It will have message handling and a tooltip

.uID = vbNull
' uID is not used by VB, so it's set to a Null value

End With

End Sub

Private Sub mnuExit_Click()

Unload Me
' Unload the form

End
' Just to be sure the program has ended

End Sub

Private Sub mnuShow_Click()

Me.WindowState = vbNormal
Shell_NotifyIcon NIM_DELETE, IconData
Me.Show

End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)

Dim Msg As Long

Msg = X
' The message is passed to the X value

' You must set your form's ScaleMode property to pixels in order to get the correct message

If Msg = WM_LBUTTONDBLCLK Then
' The user has double-clicked your icon

Call mnuShow_Click
' Show the window

ElseIf Msg = WM_RBUTTONDOWN Then
' Right-click

PopupMenu mnuPopup
' Popup the menu

End If

End Sub

Private Sub Form_Unload(Cancel As Integer)

Shell_NotifyIcon NIM_DELETE, IconData

End Sub

