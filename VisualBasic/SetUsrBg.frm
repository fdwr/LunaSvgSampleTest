VERSION 5.00
Begin VB.Form frmSetUserBg 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Form1"
   ClientHeight    =   4290
   ClientLeft      =   2160
   ClientTop       =   1530
   ClientWidth     =   6315
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   286
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   421
   Begin VB.CommandButton cmdClose 
      Cancel          =   -1  'True
      Caption         =   "Close"
      Height          =   375
      Left            =   3000
      TabIndex        =   4
      Top             =   3840
      Width           =   1335
   End
   Begin VB.CommandButton cmdNoBg 
      Caption         =   "No background"
      Height          =   375
      Left            =   1560
      TabIndex        =   3
      Top             =   3840
      Width           =   1335
   End
   Begin VB.CommandButton cmdSetBg 
      Caption         =   "Set picture"
      Height          =   375
      Left            =   120
      TabIndex        =   2
      Top             =   3840
      Width           =   1335
   End
   Begin VB.ListBox lstPicFiles 
      Height          =   3255
      IntegralHeight  =   0   'False
      Left            =   3240
      Sorted          =   -1  'True
      TabIndex        =   1
      Top             =   480
      Width           =   3015
   End
   Begin VB.ListBox lstUsers 
      Height          =   1215
      IntegralHeight  =   0   'False
      Left            =   120
      TabIndex        =   0
      Top             =   2520
      Width           =   3015
   End
   Begin VB.Label lblPath 
      BorderStyle     =   1  'Fixed Single
      Caption         =   "Label1"
      Height          =   255
      Left            =   3240
      TabIndex        =   5
      Top             =   120
      Width           =   3015
   End
   Begin VB.Image Image1 
      BorderStyle     =   1  'Fixed Single
      Height          =   2250
      Left            =   120
      Top             =   120
      Width           =   3000
   End
End
Attribute VB_Name = "frmSetUserBg"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Dim a  As Integer
Private Sub cmdClose_Click()
    Unload Me
End Sub

Private Sub cmdSetBg_Click()
    lstPicFiles.AddItem "Test"
    lstPicFiles.AddItem vbTab & "Test"
    lstPicFiles.AddItem vbTab & vbTab & "Test"
    lstPicFiles.AddItem vbTab & vbTab & vbTab & "Test"
End Sub

Private Sub Form_Load()
End Sub
