VERSION 5.00
Begin VB.Form frmDbConnect 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Student Government Voting"
   ClientHeight    =   735
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   3495
   ControlBox      =   0   'False
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   735
   ScaleWidth      =   3495
   StartUpPosition =   2  'CenterScreen
   Begin VB.Label lblProgress 
      Height          =   255
      Left            =   120
      TabIndex        =   1
      Top             =   360
      Width           =   3255
   End
   Begin VB.Label Label1 
      Caption         =   "Communicating with database... (SgVote.mdb)"
      Height          =   255
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   3255
   End
End
Attribute VB_Name = "frmDbConnect"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

