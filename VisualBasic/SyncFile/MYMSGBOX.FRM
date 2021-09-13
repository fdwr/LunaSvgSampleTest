VERSION 5.00
Begin VB.Form frmMyMsgBox 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "What to do..."
   ClientHeight    =   1560
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   4920
   Icon            =   "mymsgbox.frx":0000
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   1560
   ScaleWidth      =   4920
   ShowInTaskbar   =   0   'False
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton cmdOption 
      Caption         =   "4"
      Height          =   375
      Index           =   3
      Left            =   3720
      TabIndex        =   4
      Top             =   1080
      Visible         =   0   'False
      Width           =   1095
   End
   Begin VB.CommandButton cmdOption 
      Caption         =   "3"
      Height          =   375
      Index           =   2
      Left            =   2520
      TabIndex        =   3
      Top             =   1080
      Visible         =   0   'False
      Width           =   1095
   End
   Begin VB.CommandButton cmdOption 
      Caption         =   "2"
      Height          =   375
      Index           =   1
      Left            =   1320
      TabIndex        =   2
      Top             =   1080
      Visible         =   0   'False
      Width           =   1095
   End
   Begin VB.CommandButton cmdOption 
      Caption         =   "1"
      Height          =   375
      Index           =   0
      Left            =   120
      TabIndex        =   1
      Top             =   1080
      Width           =   1095
   End
   Begin VB.Label lblMsg 
      AutoSize        =   -1  'True
      Caption         =   "[message here]"
      Height          =   195
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   1080
   End
End
Attribute VB_Name = "frmMyMsgBox"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Option Base 0

Dim Counter As Long, ClickedButton As Long

Public Function MyMsgBox(Prompt As String, Title As String, Options As Variant) As Long
Dim Buttons As Long, Size As Long, TotalSize As Long

Buttons = UBound(Options) + 1
If Buttons <= 0 Then MyMsgBox = -1: Exit Function
ClickedButton = -1

Caption = Title
lblMsg.Caption = Prompt
TotalSize = 135
For Counter = 0 To Buttons - 1
    Size = TextWidth(Options(Counter)) + 270
    With cmdOption(Counter)
    .Left = TotalSize
    .Caption = Options(Counter)
    .Visible = True
    .Width = Size
    End With
    TotalSize = TotalSize + Size + 135
Next
Size = lblMsg.Width + 270
If Size > TotalSize Then TotalSize = Size
Width = TotalSize + (15 * 4)

Show vbModal

MyMsgBox = ClickedButton

End Function

Private Sub cmdOption_Click(Index As Integer)
ClickedButton = Index
Unload Me
End Sub

Private Sub Form_KeyPress(KeyAscii As Integer)
If KeyAscii = vbKeyEscape Then Unload Me
End Sub
