VERSION 5.00
Begin VB.Form frmPreview 
   Caption         =   "Model Preview"
   ClientHeight    =   3195
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   4680
   Icon            =   "Preview.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   3195
   ScaleWidth      =   4680
   StartUpPosition =   3  'Windows Default
   Begin VB.ComboBox cboView 
      Height          =   315
      Left            =   2640
      TabIndex        =   3
      Text            =   "5,6"
      Top             =   120
      Width           =   1215
   End
   Begin VB.ComboBox cboAngle 
      Height          =   315
      Left            =   1320
      TabIndex        =   2
      Text            =   "25°"
      Top             =   120
      Width           =   1215
   End
   Begin prjVrtMorph.ctlModelPreview ctlModelPreview1 
      Height          =   2535
      Left            =   120
      TabIndex        =   1
      Top             =   600
      Width           =   4455
      _ExtentX        =   7858
      _ExtentY        =   4260
   End
   Begin VB.ComboBox cboScale 
      Height          =   315
      ItemData        =   "Preview.frx":000C
      Left            =   120
      List            =   "Preview.frx":0043
      TabIndex        =   0
      Text            =   "1"
      Top             =   120
      Width           =   1095
   End
End
Attribute VB_Name = "frmPreview"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

