VERSION 5.00
Begin VB.Form frmGotoPath 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "Goto path"
   ClientHeight    =   945
   ClientLeft      =   2595
   ClientTop       =   4890
   ClientWidth     =   5880
   Icon            =   "GotoPath.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   945
   ScaleWidth      =   5880
   ShowInTaskbar   =   0   'False
   StartUpPosition =   1  'CenterOwner
   Begin VB.CommandButton cmdCancel 
      Cancel          =   -1  'True
      Caption         =   "Cancel"
      Height          =   375
      Left            =   1440
      TabIndex        =   2
      Top             =   480
      Width           =   1215
   End
   Begin VB.CommandButton cmdGoto 
      Caption         =   "Goto"
      Default         =   -1  'True
      Height          =   375
      Left            =   120
      TabIndex        =   1
      Top             =   480
      Width           =   1215
   End
   Begin VB.TextBox txtPath 
      Height          =   285
      Left            =   120
      TabIndex        =   0
      ToolTipText     =   "You can either type the fully qualified pathname or relative path ("".."" even works)"
      Top             =   120
      Width           =   5640
   End
End
Attribute VB_Name = "frmGotoPath"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private InvalidPath As Boolean

Private Sub cmdCancel_Click()
    Unload Me
End Sub

Private Sub cmdGoto_Click()
    Dim PathChanged As Boolean
    On Error GoTo IgnorePathError
    With frmSlideShower
        .dirFiles.Path = txtPath.Text
        If InStr(txtPath.Text, ":") Then .drvFiles.Drive = txtPath.Text
        .lstFiles.SetFocus
    End With
    Unload Me
    Exit Sub

IgnorePathError:
    InvalidPath = True
    Caption = "Invalid path!"
    With txtPath
    .SelStart = 0
    .SelLength = 32767
    End With
End Sub

Private Sub Form_Load()
    With txtPath
    .Text = PicPath
    .SelStart = 0
    .SelLength = 32767
    End With
End Sub

Private Sub Form_Deactivate()
    Unload Me
End Sub

Private Sub txtPath_Change()
    If InvalidPath Then Caption = "Goto path": InvalidPath = False
End Sub
