VERSION 5.00
Begin VB.Form frmRenameFile 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Rename file"
   ClientHeight    =   1320
   ClientLeft      =   240
   ClientTop       =   1545
   ClientWidth     =   5880
   Icon            =   "RenameFile.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   88
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   392
   ShowInTaskbar   =   0   'False
   StartUpPosition =   1  'CenterOwner
   Begin VB.TextBox txtOldName 
      BackColor       =   &H8000000F&
      BorderStyle     =   0  'None
      Height          =   285
      Left            =   1080
      TabIndex        =   3
      Top             =   120
      Width           =   4680
   End
   Begin VB.CommandButton cmdCancel 
      Cancel          =   -1  'True
      Caption         =   "Cancel"
      Height          =   375
      Left            =   1440
      TabIndex        =   2
      Top             =   840
      Width           =   1215
   End
   Begin VB.CommandButton cmdRename 
      Caption         =   "Rename"
      Default         =   -1  'True
      Height          =   375
      Left            =   120
      TabIndex        =   1
      Top             =   840
      Width           =   1215
   End
   Begin VB.TextBox txtNewName 
      Height          =   285
      Left            =   1080
      TabIndex        =   0
      Top             =   480
      Width           =   4680
   End
   Begin VB.Label Label2 
      Alignment       =   1  'Right Justify
      Caption         =   "New name:"
      Height          =   255
      Left            =   120
      TabIndex        =   5
      Top             =   525
      Width           =   855
   End
   Begin VB.Label Label1 
      Alignment       =   1  'Right Justify
      Caption         =   "Old name:"
      Height          =   255
      Left            =   120
      TabIndex        =   4
      Top             =   120
      Width           =   855
   End
End
Attribute VB_Name = "frmRenameFile"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private InvalidName As Boolean

Private Sub cmdCancel_Click()
    Unload Me
End Sub

Private Sub cmdRename_Click()
    On Error GoTo SoWhatIfRenameError
    Name PicFilename As txtNewName.Text
    PicFilename = txtNewName.Text
    'change entry in list
    If PicIndex < TotalPicFiles Then
        PicFiles(PicOrder(PicIndex)) = PicFilename
        With frmSlideShower
        .lstFiles.List(PicIndex) = GetFileName(PicFilename)
        .Caption = PicFilename
        End With
    End If
    Unload Me
    Exit Sub
SoWhatIfRenameError:
    Caption = "Renamed failed!"
    InvalidName = True
End Sub

Private Sub Form_Load()
    txtOldName.Text = PicFilename
    With txtNewName
    .Text = PicFilename
    .SelStart = GetFileNamePos(PicFilename)
    .SelLength = 16384
    End With
End Sub

Private Sub Form_Deactivate()
    Unload Me
End Sub

Private Sub txtNewName_Change()
    If InvalidName Then Caption = "Rename file": InvalidName = False
End Sub

Private Sub txtOldName_GotFocus()
    With txtOldName
    .SelStart = 0
    .SelLength = 32767
    End With
End Sub

Private Sub txtOldName_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If Button And 2 Then txtOldName_GotFocus
End Sub
