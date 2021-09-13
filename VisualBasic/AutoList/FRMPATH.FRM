VERSION 5.00
Begin VB.Form frmPath 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Add / Edit Path"
   ClientHeight    =   3360
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   5415
   Icon            =   "frmPath.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3360
   ScaleWidth      =   5415
   StartUpPosition =   1  'CenterOwner
   Begin VB.CommandButton cmdCancel 
      Caption         =   "Cancel"
      Height          =   375
      Left            =   120
      TabIndex        =   5
      Top             =   2880
      Width           =   1575
   End
   Begin VB.CommandButton cmdOk 
      Caption         =   "&Ok"
      Default         =   -1  'True
      Height          =   375
      Left            =   3720
      TabIndex        =   6
      Top             =   2880
      Width           =   1575
   End
   Begin VB.DirListBox dirDir 
      Height          =   1665
      Left            =   0
      TabIndex        =   2
      Top             =   0
      Width           =   5415
   End
   Begin VB.DriveListBox drvDrive 
      Height          =   315
      Left            =   0
      TabIndex        =   1
      Top             =   1680
      Width           =   5415
   End
   Begin VB.Frame Frame1 
      Caption         =   "Map to server path:"
      Height          =   615
      Left            =   0
      TabIndex        =   0
      Top             =   2160
      Width           =   5415
      Begin VB.TextBox txtMap 
         Enabled         =   0   'False
         Height          =   285
         Left            =   120
         TabIndex        =   4
         Top             =   240
         Width           =   5175
      End
      Begin VB.CheckBox chkEnable 
         Caption         =   "Enable"
         Height          =   255
         Left            =   1680
         TabIndex        =   3
         Top             =   0
         Width           =   855
      End
   End
End
Attribute VB_Name = "frmPath"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Dim OldDrive As String
Dim OldPath As String

Private Sub chkEnable_Click()
    If chkEnable.Value = 1 Then
        txtMap.Enabled = True
    Else
        txtMap.Enabled = False
    End If
End Sub

Private Sub cmdCancel_Click()
    Unload frmPath
End Sub

Private Sub cmdOk_Click()
    Unload frmPath
End Sub

Private Sub dirDir_Change()
    On Error GoTo ErrorHandle
    OldPath = dirDir
    Exit Sub
    
ErrorHandle:
    MsgBox "Sorry, the selected folder is not avalible.", vbCritical + vbOKOnly, "Drive Error"
    If OldPath <> "" Then
        dirDir = OldPath
    Else
        dirDir = "c:\"
    End If
    
End Sub

Private Sub drvDrive_Change()
    On Error GoTo ErrorHandle
    dirDir.Enabled = False
    dirDir.BackColor = vbButtonFace
    DoEvents
    dirDir = drvDrive
    dirDir.Enabled = True
    dirDir.BackColor = vbWindowBackground
    OldDrive = drvDrive
    Exit Sub
    
ErrorHandle:
    MsgBox "Sorry, the selected drive is not avalible.", vbCritical + vbOKOnly, "Drive Error"
    If OldDrive <> "" Then
        drvDrive = OldDrive
    Else
        drvDrive = "c:"
    End If
    
End Sub

Private Sub Form_Terminate()
    Unload frmPath
End Sub
