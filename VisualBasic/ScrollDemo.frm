VERSION 5.00
Begin VB.Form frmScrollDemo 
   Caption         =   "Scroll(ing) Demo"
   ClientHeight    =   2820
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   4680
   LinkTopic       =   "Form1"
   ScaleHeight     =   2820
   ScaleWidth      =   4680
   StartUpPosition =   3  'Windows Default
   Begin VB.Frame Frame1 
      BorderStyle     =   0  'None
      Height          =   1455
      Left            =   1560
      TabIndex        =   0
      Top             =   120
      Width           =   1455
      Begin VB.OptionButton Option1 
         BackColor       =   &H80000018&
         Caption         =   "A"
         Height          =   255
         Index           =   0
         Left            =   120
         TabIndex        =   2
         Top             =   120
         Width           =   1215
      End
      Begin VB.OptionButton Option1 
         BackColor       =   &H80000018&
         Caption         =   "B"
         Height          =   255
         Index           =   1
         Left            =   120
         TabIndex        =   3
         Top             =   360
         Width           =   1215
      End
      Begin VB.OptionButton Option1 
         BackColor       =   &H80000018&
         Caption         =   "C"
         Height          =   255
         Index           =   2
         Left            =   120
         TabIndex        =   4
         Top             =   600
         Width           =   1215
      End
      Begin VB.OptionButton Option1 
         BackColor       =   &H80000018&
         Caption         =   "D"
         Height          =   255
         Index           =   3
         Left            =   120
         TabIndex        =   5
         Top             =   840
         Width           =   1215
      End
      Begin VB.OptionButton Option1 
         BackColor       =   &H80000018&
         Caption         =   "E"
         Height          =   255
         Index           =   4
         Left            =   120
         TabIndex        =   6
         Top             =   1080
         Width           =   1215
      End
      Begin VB.Label Label1 
         BackColor       =   &H80000018&
         BorderStyle     =   1  'Fixed Single
         Height          =   1455
         Left            =   0
         TabIndex        =   1
         Top             =   0
         Width           =   1455
      End
   End
   Begin VB.Timer Timer1 
      Interval        =   50
      Left            =   4200
      Top             =   2280
   End
   Begin VB.HScrollBar hsbDemo 
      Height          =   255
      LargeChange     =   10
      Left            =   1320
      Max             =   100
      TabIndex        =   7
      Top             =   1920
      Width           =   2175
   End
   Begin VB.Label lblScrollStatus 
      Height          =   255
      Left            =   1320
      TabIndex        =   11
      Top             =   1680
      Width           =   2175
   End
   Begin VB.Label lblCurOptionBtn 
      Height          =   375
      Left            =   3240
      TabIndex        =   10
      Top             =   120
      Width           =   735
   End
   Begin VB.Label lblScrollie 
      Appearance      =   0  'Flat
      BackColor       =   &H80000005&
      BackStyle       =   0  'Transparent
      Caption         =   "Hey Sharon! Look down here  :-)      "
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FF8080&
      Height          =   255
      Left            =   120
      TabIndex        =   9
      Top             =   2520
      Width           =   10005
   End
   Begin VB.Label lblScrollPos 
      Appearance      =   0  'Flat
      BackColor       =   &H80000005&
      BackStyle       =   0  'Transparent
      Caption         =   "Not changed yet"
      ForeColor       =   &H80000008&
      Height          =   255
      Left            =   1320
      TabIndex        =   8
      Top             =   2160
      Width           =   2175
   End
End
Attribute VB_Name = "frmScrollDemo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Dim ffStrech As Integer, ffSpaces As Integer, ffSpacing As Integer
Dim ffOptionIndex As Integer

Private Sub Form_Load()
    ffStrech = Len(lblScrollie.Caption) - 1
    ffSpaces = 0
    ffSpacing = 5
End Sub

Private Sub hsbDemo_Change()
    lblScrollStatus.Caption = "Change"
    lblScrollPos.Caption = hsbDemo.Value
    Timer1.Interval = 0
End Sub


Private Sub hsbDemo_Scroll()
    lblScrollStatus.Caption = "Scroll"
    lblScrollPos.Caption = hsbDemo.Value
End Sub

Private Sub Option1_Click(Index As Integer)
    ffOptionIndex = Index
    lblCurOptionBtn.Caption = Str$(Index)
End Sub

Private Sub Timer1_Timer()
    lblScrollie.Caption = StrechString(lblScrollie.Caption, ffStrech, ffSpaces, ffSpacing)
End Sub

Public Function StrechString(Text As String, Strech As Integer, Spaces As Integer, Spacing As Integer)
    Text = Left(Text, Strech) & " " & Mid(Text, Strech + 1)
    Spaces = Spaces + 1
    If Spaces >= Spacing Then
        If Len(Text) > 100 Then
            Text = Left(Text, 100)
        End If
        If Strech > 0 Then
            Strech = Strech - 1
        End If
        Spaces = 0
    End If
    StrechString = Text
End Function
