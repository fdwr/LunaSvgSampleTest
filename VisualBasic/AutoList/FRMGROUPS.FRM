VERSION 5.00
Begin VB.Form frmGroups 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Groups"
   ClientHeight    =   5295
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   5910
   Icon            =   "frmGroups.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   5295
   ScaleWidth      =   5910
   StartUpPosition =   1  'CenterOwner
   Begin VB.Frame Frame3 
      Caption         =   "Unassigned Files:"
      Height          =   5295
      Left            =   2640
      TabIndex        =   12
      Top             =   0
      Width           =   3255
      Begin VB.ListBox lstUnassigned 
         Height          =   4935
         Left            =   120
         TabIndex        =   3
         Top             =   240
         Width           =   3015
      End
   End
   Begin VB.Frame Frame2 
      Caption         =   "Groups:"
      Height          =   4455
      Left            =   0
      TabIndex        =   11
      Top             =   0
      Width           =   2535
      Begin VB.CommandButton cmdEdit 
         Caption         =   "Edit"
         Height          =   375
         Left            =   120
         TabIndex        =   13
         Top             =   3360
         Width           =   1095
      End
      Begin VB.ListBox lstGroups 
         Height          =   2595
         Left            =   120
         TabIndex        =   0
         Top             =   240
         Width           =   2295
      End
      Begin VB.CommandButton cmdRemove 
         Caption         =   "Remove"
         Height          =   375
         Left            =   1320
         TabIndex        =   5
         Top             =   3360
         Width           =   1095
      End
      Begin VB.CommandButton cmdCreate 
         Caption         =   "Create"
         Height          =   495
         Left            =   120
         TabIndex        =   4
         Top             =   3840
         Width           =   2295
      End
      Begin VB.CommandButton cmdMoveDown 
         Caption         =   "Move Down"
         Height          =   375
         Left            =   1320
         TabIndex        =   2
         Top             =   2880
         Width           =   1095
      End
      Begin VB.CommandButton cmdMoveUp 
         Caption         =   "Move Up"
         Height          =   375
         Left            =   120
         TabIndex        =   1
         Top             =   2880
         Width           =   1095
      End
   End
   Begin VB.Frame Frame1 
      Height          =   855
      Left            =   0
      TabIndex        =   6
      Top             =   4440
      Width           =   2535
      Begin VB.Label lblVideos 
         Alignment       =   1  'Right Justify
         Caption         =   "0"
         Height          =   255
         Left            =   1320
         TabIndex        =   10
         Top             =   480
         Width           =   1095
      End
      Begin VB.Label lblOther 
         Alignment       =   1  'Right Justify
         Caption         =   "0"
         Height          =   255
         Left            =   1320
         TabIndex        =   9
         Top             =   240
         Width           =   1095
      End
      Begin VB.Label Label2 
         Caption         =   "Music Videos:"
         Height          =   255
         Left            =   120
         TabIndex        =   8
         Top             =   480
         Width           =   1095
      End
      Begin VB.Label Label1 
         Caption         =   "Non-video files:"
         Height          =   255
         Left            =   120
         TabIndex        =   7
         Top             =   240
         Width           =   1095
      End
   End
End
Attribute VB_Name = "frmGroups"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub cmdCreate_Click()
    If lstUnassigned.ListIndex > -1 Then
        
    Else
        
    End If
    Disable
    frmGroup.Show 1
    Enable
End Sub

Private Sub cmdEdit_Click()
    If lstGroups.ListIndex > -1 Then
        Disable
            
        Enable
    Else
        Beep
    End If
End Sub

Private Sub cmdMoveDown_Click()
    If lstGroups.ListIndex > -1 Then
        Disable
            
        Enable
    Else
        Beep
    End If
End Sub

Private Sub cmdMoveUp_Click()
    If lstGroups.ListIndex > -1 Then
        Disable
            
        Enable
    Else
        Beep
    End If
End Sub

Private Sub cmdRemove_Click()
    If lstGroups.ListIndex > -1 Then
        Disable
            
        Enable
    Else
        Beep
    End If
End Sub

Sub Enable()
    cmdMoveUp.Enabled = True
    cmdMoveDown.Enabled = True
    cmdEdit.Enabled = True
    cmdRemove.Enabled = True
    cmdCreate.Enabled = True
    lstGroups.Enabled = True
    lstUnassigned.Enabled = True
    lstGroups.BackColor = vbWindowBackground
    lstUnassigned.BackColor = vbWindowBackground
End Sub

Sub Disable()
    cmdMoveUp.Enabled = False
    cmdMoveDown.Enabled = False
    cmdEdit.Enabled = False
    cmdRemove.Enabled = False
    cmdCreate.Enabled = False
    lstGroups.Enabled = False
    lstUnassigned.Enabled = False
    lstGroups.BackColor = vbButtonFace
    lstUnassigned.BackColor = vbButtonFace
    DoEvents
End Sub
