VERSION 5.00
Begin VB.Form frmCountMsg 
   Caption         =   "Friendly Message"
   ClientHeight    =   3045
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   2745
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3045
   ScaleWidth      =   2745
   ShowInTaskbar   =   0   'False
   Begin VB.CommandButton cmdClose 
      BackColor       =   &H00FFC0C0&
      Cancel          =   -1  'True
      Caption         =   "Close"
      DownPicture     =   "CountMsg.frx":0000
      Height          =   495
      Left            =   840
      Style           =   1  'Graphical
      TabIndex        =   1
      Top             =   2400
      Width           =   975
   End
   Begin VB.PictureBox Picture1 
      BackColor       =   &H00C0FFFF&
      Height          =   2175
      Left            =   120
      ScaleHeight     =   2115
      ScaleWidth      =   2475
      TabIndex        =   0
      Top             =   120
      Width           =   2535
      Begin VB.Label Label2 
         BackColor       =   &H00C0FFFF&
         Caption         =   "Greetings. The time has come  to take a count. Thank you and have a great day!"
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   13.5
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   1935
         Left            =   120
         TabIndex        =   2
         Top             =   120
         Width           =   2295
      End
   End
   Begin VB.Label lblAbout 
      BackStyle       =   0  'Transparent
      Caption         =   "?"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   13.5
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FF0000&
      Height          =   375
      Left            =   2400
      TabIndex        =   3
      Top             =   2520
      Width           =   255
   End
End
Attribute VB_Name = "frmCountMsg"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit


Private Sub cmdClose_Click()
    Unload frmCurTime
    End
End Sub

Private Sub Form_Load()
    Dim CombinedWidth As Integer

    CombinedWidth = frmCountMsg.Width + frmCurTime.Width
    Left = (Screen.Width - CombinedWidth) \ 2
    frmCurTime.Left = Left + Width
    Top = (Screen.Height - Height) \ 2
    frmCurTime.Top = Top
    frmCurTime.Show
End Sub

Private Sub lblAbout_Click()
    MsgBox "DoCount 1.1" & vbCr & vbCr & "Written by the cool Brandt Hoffman," & vbCr & "Timer behaviour added by Dwayne.", vbInformation, "About"
End Sub

Private Sub Picture1_KeyPress(KeyAscii As Integer)
    If KeyAscii = vbKeyReturn Then
        Call cmdClose_Click
    End If
End Sub
