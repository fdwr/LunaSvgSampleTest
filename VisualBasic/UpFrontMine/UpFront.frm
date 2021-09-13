VERSION 5.00
Begin VB.Form MainForm 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "UpFront"
   ClientHeight    =   3915
   ClientLeft      =   2550
   ClientTop       =   3525
   ClientWidth     =   5115
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MousePointer    =   4  'Icon
   ScaleHeight     =   3915
   ScaleWidth      =   5115
   Begin VB.TextBox Text1 
      BackColor       =   &H00FFC0C0&
      Height          =   285
      Left            =   2400
      TabIndex        =   9
      Top             =   3000
      Width           =   2655
   End
   Begin VB.DirListBox Dir1 
      BackColor       =   &H00FFC0C0&
      Height          =   1890
      Left            =   120
      TabIndex        =   13
      Top             =   480
      Width           =   2415
   End
   Begin VB.DriveListBox Drive1 
      BackColor       =   &H00FFC0C0&
      Height          =   315
      Left            =   120
      TabIndex        =   12
      Top             =   120
      Width           =   2415
   End
   Begin VB.FileListBox File1 
      BackColor       =   &H00FFC0C0&
      Height          =   2235
      Left            =   2640
      System          =   -1  'True
      TabIndex        =   0
      Top             =   120
      Width           =   2415
   End
   Begin VB.ComboBox CmbMode 
      BackColor       =   &H00FFC0C0&
      Height          =   315
      ItemData        =   "UpFront.frx":0000
      Left            =   2400
      List            =   "UpFront.frx":000D
      TabIndex        =   11
      Text            =   "Colored Blocks"
      Top             =   3480
      Width           =   2655
   End
   Begin VB.TextBox TxtWrap 
      BackColor       =   &H00FFC0C0&
      Height          =   285
      Left            =   4200
      TabIndex        =   7
      Text            =   "16"
      Top             =   2520
      Width           =   855
   End
   Begin VB.TextBox TxtGoto 
      BackColor       =   &H00FFC0C0&
      Height          =   285
      Left            =   2400
      TabIndex        =   5
      Top             =   2520
      Width           =   855
   End
   Begin VB.CommandButton CmdStartBgm 
      Caption         =   "&BgMapper"
      Height          =   375
      Index           =   2
      Left            =   120
      TabIndex        =   3
      TabStop         =   0   'False
      Top             =   3360
      Width           =   1215
   End
   Begin VB.CommandButton CmdStartTmv 
      Caption         =   "&TileView"
      Height          =   375
      Index           =   1
      Left            =   120
      TabIndex        =   2
      TabStop         =   0   'False
      Top             =   3000
      Width           =   1215
   End
   Begin VB.CommandButton CmdStartSv 
      Caption         =   "Sprite&View"
      Height          =   375
      Index           =   0
      Left            =   120
      TabIndex        =   1
      Top             =   2640
      Width           =   1215
   End
   Begin VB.Label LabPalette 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "&Palette File:"
      Height          =   375
      Left            =   1440
      TabIndex        =   8
      Top             =   3000
      Width           =   855
   End
   Begin VB.Label LabMode 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "View &Mode:"
      Height          =   375
      Left            =   1440
      TabIndex        =   10
      Top             =   3480
      Width           =   855
   End
   Begin VB.Label LabWrap 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "&Wrap:"
      Height          =   375
      Left            =   3360
      TabIndex        =   6
      Top             =   2520
      Width           =   735
   End
   Begin VB.Label LabGoto 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "&Goto:"
      Height          =   375
      Left            =   1440
      TabIndex        =   4
      Top             =   2520
      Width           =   855
   End
   Begin VB.Image Image1 
      Appearance      =   0  'Flat
      Height          =   3975
      Left            =   0
      Picture         =   "UpFront.frx":003F
      Stretch         =   -1  'True
      Top             =   0
      Visible         =   0   'False
      Width           =   5175
   End
   Begin VB.Menu MnuFile 
      Caption         =   "&File"
      Begin VB.Menu MnuFileOpen 
         Caption         =   "&Open"
         Enabled         =   0   'False
      End
      Begin VB.Menu MnuFileSave 
         Caption         =   "&Save"
         Enabled         =   0   'False
      End
      Begin VB.Menu MnuFileRevert 
         Caption         =   "&Revert"
         Enabled         =   0   'False
      End
      Begin VB.Menu MnuFileClose 
         Caption         =   "&Close"
         Enabled         =   0   'False
      End
      Begin VB.Menu MnuSep 
         Caption         =   "-"
      End
      Begin VB.Menu MnuExit 
         Caption         =   "E&xit"
      End
   End
   Begin VB.Menu MnuStart 
      Caption         =   "&Start"
      Begin VB.Menu MnuStartBgMapper 
         Caption         =   "&BgMapper"
      End
      Begin VB.Menu MnuStartTmv 
         Caption         =   "&TileView"
      End
      Begin VB.Menu MnuStartSv 
         Caption         =   "&SpriteView"
      End
   End
   Begin VB.Menu MnuHelp 
      Caption         =   "&Help"
      Begin VB.Menu MnuHelpContents 
         Caption         =   "&Contents"
         Enabled         =   0   'False
      End
      Begin VB.Menu MnuHelpAbout 
         Caption         =   "&About"
      End
   End
End
Attribute VB_Name = "MainForm"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub CmdStartSv_Click(Index As Integer)
    StartProg ("sv.exe ")
End Sub

Private Sub CmdStartTmv_Click(Index As Integer)
    StartProg ("tmv.exe ")
End Sub

Private Sub CmdStartBgm_Click(Index As Integer)
    StartProg ("bgmapper.exe ")
End Sub

Private Sub Dir1_Change()
    File1.Path = Dir1.Path
End Sub

Private Sub Drive1_Change()
    Dir1.Path = Drive1.Drive
End Sub

Private Sub MnuExit_Click()
    End
End Sub

Private Sub MnuHelpAbout_Click()
    MsgBox ("Imitation UpFront, by Peekin 27.9.1999" & Chr$(13) & "Original (and better) version by CyBeRGoth")
End Sub

Public Sub StartProg(ProgName As String)
    Dim Dummy
    Dummy = Shell(ProgName & File1.Path & File1.FileName, vbMaximizedFocus)
End Sub
