VERSION 5.00
Begin VB.Form frmScore 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Got It!"
   ClientHeight    =   2175
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   3375
   Icon            =   "Score.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   2175
   ScaleWidth      =   3375
   StartUpPosition =   1  'CenterOwner
   Begin VB.CommandButton cmdResponse 
      Caption         =   "Retry"
      Height          =   495
      Index           =   1
      Left            =   1200
      TabIndex        =   1
      Top             =   1560
      Width           =   975
   End
   Begin VB.CommandButton cmdResponse 
      Caption         =   "Next"
      Default         =   -1  'True
      Height          =   495
      Index           =   0
      Left            =   120
      TabIndex        =   0
      Top             =   1560
      Width           =   975
   End
   Begin VB.CommandButton cmdResponse 
      Cancel          =   -1  'True
      Caption         =   "Menu"
      Height          =   495
      Index           =   2
      Left            =   2280
      TabIndex        =   2
      Top             =   1560
      Width           =   975
   End
   Begin VB.Label lblTries 
      BackColor       =   &H80000005&
      BackStyle       =   0  'Transparent
      Height          =   255
      Left            =   840
      TabIndex        =   6
      Top             =   240
      Width           =   2295
   End
   Begin VB.Label lblScores 
      BackColor       =   &H80000005&
      BackStyle       =   0  'Transparent
      Height          =   735
      Left            =   2040
      TabIndex        =   4
      Top             =   600
      Width           =   1095
   End
   Begin VB.Label lblScoreTitles 
      Alignment       =   1  'Right Justify
      BackColor       =   &H80000005&
      BackStyle       =   0  'Transparent
      Height          =   735
      Left            =   840
      TabIndex        =   3
      Top             =   600
      Width           =   1095
   End
   Begin VB.Image Image1 
      Height          =   480
      Left            =   240
      Picture         =   "Score.frx":0442
      Top             =   480
      Width           =   480
   End
   Begin VB.Label Label2 
      BackColor       =   &H00FFC0C0&
      BorderStyle     =   1  'Fixed Single
      Height          =   1335
      Left            =   120
      TabIndex        =   5
      Top             =   120
      Width           =   3135
   End
End
Attribute VB_Name = "frmScore"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Dim Response As Integer

Private Sub cmdResponse_Click(Index As Integer)
    Response = Index
    Unload frmScore
End Sub

Private Sub Form_Load()
    lblTries.Caption = "Took " & TotalMatches + TotalMisses & " tries to match " & TotalClozeWords & " words"
    lblScoreTitles.Caption = "Matched:" & vbCr & "Attempted:" & vbCr & "Missed:"
    lblScores.Caption = TotalMatches & vbCr & TotalAttempts & vbCr & TotalMisses
    Response = 0
End Sub

Public Function GetResponse()
    Show vbModal
    GetResponse = Response
End Function
