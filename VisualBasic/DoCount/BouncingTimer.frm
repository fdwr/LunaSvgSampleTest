VERSION 5.00
Begin VB.Form frmCurTime 
   Caption         =   "Current Time"
   ClientHeight    =   3045
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   3030
   LinkTopic       =   "Form2"
   ScaleHeight     =   3045
   ScaleWidth      =   3030
   Begin VB.Timer Timer1 
      Interval        =   10
      Left            =   0
      Top             =   0
   End
   Begin VB.Frame fraBounce 
      Caption         =   "My how time flies!"
      Height          =   855
      Left            =   600
      TabIndex        =   0
      Top             =   600
      Width           =   1935
      Begin VB.Label lblCurTime 
         Alignment       =   2  'Center
         BackColor       =   &H00C0FFFF&
         BorderStyle     =   1  'Fixed Single
         Caption         =   "Time"
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   13.5
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   495
         Left            =   120
         TabIndex        =   1
         Top             =   240
         Width           =   1695
      End
   End
End
Attribute VB_Name = "frmCurTime"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Dim DeltaX As Integer, DeltaY As Integer   ' Declare variables.
Dim MouseX As Integer, MouseY As Integer, MouseGrab As Boolean


Private Sub Form_KeyPress(KeyAscii As Integer)
    If KeyAscii = vbKeyEscape Then
        Unload frmCurTime
    End If
End Sub

Private Sub Form_Load()
   Timer1.Interval = 10   ' Set Interval.
   DeltaX = 20   ' Initialize variables.
   DeltaY = 20
End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If Button And 1 Then
        MouseGrab = True
        MouseX = X: MouseY = Y
    Else
        MouseGrab = False
        Call Form_Resize
    End If
End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    MouseX = X: MouseY = Y
End Sub

Private Sub Form_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    MouseGrab = False
End Sub

Private Sub Form_Resize()
    DeltaX = Width \ 70 * Sgn(DeltaX)
    DeltaY = Height \ 70 * Sgn(DeltaY)
    If fraBounce.Left + fraBounce.Width > ScaleWidth + ScaleLeft Then
        fraBounce.Left = ScaleWidth + ScaleLeft - fraBounce.Width
    End If
    If fraBounce.Top + fraBounce.Height > ScaleHeight + ScaleTop Then
        fraBounce.Top = ScaleHeight + ScaleTop - fraBounce.Height
    End If
End Sub

Private Sub Timer1_Timer()
    Dim NewLeft As Integer, NewTop As Integer
    lblCurTime.Caption = Time   ' Update time display.

    NewLeft = fraBounce.Left + DeltaX
    NewTop = fraBounce.Top + DeltaY
    If NewLeft < ScaleLeft Then DeltaX = Abs(DeltaX): NewLeft = NewLeft + DeltaX
    If NewLeft + fraBounce.Width > ScaleWidth + ScaleLeft Then DeltaX = -Abs(DeltaX): NewLeft = NewLeft + DeltaX
    If NewTop < ScaleTop Then DeltaY = Abs(DeltaY): NewTop = NewTop + DeltaY
    If NewTop + fraBounce.Height > ScaleHeight + ScaleTop Then DeltaY = -Abs(DeltaY): NewTop = NewTop + DeltaY
    fraBounce.Move NewLeft, NewTop

    If MouseGrab Then
        If MouseX < fraBounce.Left Then
            DeltaX = DeltaX - 20
        Else
            DeltaX = DeltaX + 20
        End If
        If Abs(DeltaX) > 200 Then DeltaX = Sgn(DeltaX) * 200
        If MouseY < fraBounce.Top Then
            DeltaY = DeltaY - 20
        Else
            DeltaY = DeltaY + 20
        End If
        If Abs(DeltaY) > 200 Then DeltaY = Sgn(DeltaY) * 200
    End If
End Sub
