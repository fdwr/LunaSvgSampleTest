VERSION 5.00
Begin VB.Form frmMain 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "AutoLister (Beta 2)"
   ClientHeight    =   3255
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   5175
   Icon            =   "frmMain.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   3255
   ScaleWidth      =   5175
   StartUpPosition =   2  'CenterScreen
   Begin VB.CommandButton cmdTestOrder 
      Caption         =   "Test Order"
      Height          =   375
      Left            =   1800
      TabIndex        =   14
      Top             =   720
      Width           =   1575
   End
   Begin VB.ListBox lstSort 
      Height          =   1035
      Left            =   2640
      TabIndex        =   13
      Top             =   3360
      Visible         =   0   'False
      Width           =   1215
   End
   Begin VB.DriveListBox Drive1 
      Height          =   315
      Left            =   0
      TabIndex        =   12
      Top             =   4200
      Visible         =   0   'False
      Width           =   1215
   End
   Begin VB.FileListBox File1 
      Height          =   1065
      Left            =   1320
      TabIndex        =   11
      Top             =   3360
      Visible         =   0   'False
      Width           =   1215
   End
   Begin VB.DirListBox Dir1 
      Height          =   765
      Left            =   0
      TabIndex        =   10
      Top             =   3360
      Visible         =   0   'False
      Width           =   1215
   End
   Begin VB.Timer tmrBoot 
      Interval        =   1
      Left            =   4560
      Top             =   360
   End
   Begin VB.Frame Frame2 
      Caption         =   "Paths:"
      Height          =   2055
      Left            =   0
      TabIndex        =   9
      Top             =   0
      Width           =   5175
      Begin VB.CommandButton cmdEditPath 
         Caption         =   "Edit Path"
         Height          =   375
         Left            =   1800
         TabIndex        =   2
         Top             =   1560
         Width           =   1575
      End
      Begin VB.CommandButton cmdRemovePath 
         Caption         =   "&Remove Path"
         Height          =   375
         Left            =   3480
         TabIndex        =   3
         Top             =   1560
         Width           =   1575
      End
      Begin VB.CommandButton cmdAddPath 
         Caption         =   "&Add Path"
         Height          =   375
         Left            =   120
         TabIndex        =   1
         Top             =   1560
         Width           =   1575
      End
      Begin VB.ListBox lstPaths 
         Height          =   1230
         Left            =   120
         TabIndex        =   0
         Top             =   240
         Width           =   4935
      End
   End
   Begin VB.Frame Frame1 
      Height          =   1215
      Left            =   0
      TabIndex        =   8
      Top             =   2040
      Width           =   5175
      Begin VB.CommandButton cmdGroups 
         Caption         =   "&Groups"
         Height          =   375
         Left            =   2640
         TabIndex        =   5
         Top             =   240
         Width           =   2415
      End
      Begin VB.CommandButton cmdAddCDs 
         Caption         =   "Add &CD's"
         Height          =   375
         Left            =   120
         TabIndex        =   6
         Top             =   720
         Width           =   2415
      End
      Begin VB.CommandButton cmdUpdate 
         Caption         =   "&Update Catalog"
         Default         =   -1  'True
         Height          =   375
         Left            =   2640
         TabIndex        =   7
         Top             =   720
         Width           =   2415
      End
      Begin VB.CommandButton cmdOptions 
         Caption         =   "&Options"
         Height          =   375
         Left            =   120
         TabIndex        =   4
         Top             =   240
         Width           =   2415
      End
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Private Sub cmdAddCDs_Click()
    Disable
    
    Enable
End Sub

Private Sub cmdAddPath_Click()
    Disable
    frmPath.Show 1
    Enable
End Sub

Private Sub cmdEditPath_Click()
    If lstPaths.ListIndex > -1 Then
        Disable
        frmPath.drvDrive = lstPaths.List(lstPaths.ListIndex)
        frmPath.dirDir = lstPaths.List(lstPaths.ListIndex)
        frmPath.Show 1
        Enable
    Else
        Beep
    End If
End Sub

Private Sub cmdGroups_Click()
    Disable
    frmGroups.Show 1
    Enable
End Sub

Private Sub cmdOptions_Click()
    Disable
    frmOptions.Show 1
    Enable
End Sub

Private Sub cmdRemovePath_Click()
    If lstPaths.ListIndex > -1 Then
        Disable
        If MsgBox("Are you sure you wish to remove this group?" & vbNewLine & "(" & lstPaths.List(lstPaths.ListIndex) & ")", vbQuestion + vbYesNo, "Confirm") = vbYes Then
            
        End If
        Enable
    Else
        Beep
    End If
End Sub

Private Sub cmdTestOrder_Click()
    frmTestOrder.Show vbModal
End Sub

Private Sub cmdUpdate_Click()
    Disable
    StartUpdate (True)
    Enable
End Sub

Private Sub Dir1_Change()
    File1 = Dir1
End Sub

Private Sub tmrBoot_Timer()
    tmrBoot.Enabled = False
    Boot
End Sub

Sub Disable()
    cmdAddPath.Enabled = False
    cmdRemovePath.Enabled = False
    cmdOptions.Enabled = False
    cmdAddCDs.Enabled = False
    cmdUpdate.Enabled = False
    cmdGroups.Enabled = False
    cmdEditPath.Enabled = False
    lstPaths.Enabled = False
    lstPaths.BackColor = vbButtonFace
    frmMain.Enabled = False
    DoEvents
End Sub

Sub Enable()
    frmMain.Enabled = True
    cmdAddPath.Enabled = True
    cmdRemovePath.Enabled = True
    cmdOptions.Enabled = True
    cmdAddCDs.Enabled = True
    cmdUpdate.Enabled = True
    cmdGroups.Enabled = True
    cmdEditPath.Enabled = True
    lstPaths.Enabled = True
    lstPaths.BackColor = vbWindowBackground
    cmdUpdate.SetFocus
End Sub
