VERSION 5.00
Begin VB.Form frmVote 
   AutoRedraw      =   -1  'True
   BackColor       =   &H00808080&
   BorderStyle     =   0  'None
   Caption         =   "Student Government Voting"
   ClientHeight    =   9000
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   12000
   BeginProperty Font 
      Name            =   "MS Sans Serif"
      Size            =   13.5
      Charset         =   0
      Weight          =   700
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   ScaleHeight     =   600
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   800
   ShowInTaskbar   =   0   'False
   Begin VB.TextBox txtPAC 
      BackColor       =   &H00FFC0C0&
      ForeColor       =   &H00FF7070&
      Height          =   480
      IMEMode         =   3  'DISABLE
      Left            =   8160
      MaxLength       =   4
      PasswordChar    =   "*"
      TabIndex        =   21
      Text            =   "1234"
      ToolTipText     =   "Type your 4 digit personal access code here, usually your month and day of birth."
      Top             =   6120
      Visible         =   0   'False
      Width           =   1815
   End
   Begin VB.TextBox txtVSID 
      BackColor       =   &H00FFC0C0&
      ForeColor       =   &H00FF7070&
      Height          =   480
      IMEMode         =   3  'DISABLE
      Left            =   2760
      MaxLength       =   9
      PasswordChar    =   "*"
      TabIndex        =   20
      Text            =   "123456789"
      ToolTipText     =   "Type your 9 digit student ID here, usually the same as your social security number."
      Top             =   6120
      Visible         =   0   'False
      Width           =   1815
   End
   Begin VB.ListBox lstSelections 
      BackColor       =   &H00FFC0C0&
      ForeColor       =   &H00FF7070&
      Height          =   2220
      Left            =   2760
      TabIndex        =   22
      ToolTipText     =   "These are the candidates you have selected for various positions."
      Top             =   2640
      Visible         =   0   'False
      Width           =   8055
   End
   Begin VB.Timer tmrAnimate 
      Enabled         =   0   'False
      Interval        =   100
      Left            =   120
      Top             =   12600
   End
   Begin VB.TextBox txtCndtMsg 
      BackColor       =   &H00FFC0C0&
      ForeColor       =   &H00FF7070&
      Height          =   6015
      Left            =   2760
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   19
      Text            =   "Vote.frx":0000
      Top             =   1560
      Visible         =   0   'False
      Width           =   8655
   End
   Begin VB.TextBox txtPosDesc 
      BackColor       =   &H00FFC0C0&
      ForeColor       =   &H00FF7070&
      Height          =   6015
      Left            =   600
      Locked          =   -1  'True
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   31
      Text            =   "Vote.frx":000F
      Top             =   1560
      Visible         =   0   'False
      Width           =   10815
   End
   Begin VB.Label lblPAC 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Personal Access Code:"
      ForeColor       =   &H00FFC0C0&
      Height          =   495
      Left            =   4680
      TabIndex        =   32
      Top             =   6120
      Visible         =   0   'False
      Width           =   3375
   End
   Begin VB.Label lblChoices 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "To candidates"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   8
      Left            =   7320
      TabIndex        =   30
      ToolTipText     =   "View list of candidates for this position."
      Top             =   7920
      Visible         =   0   'False
      Width           =   4335
   End
   Begin VB.Label lblChoices 
      BackStyle       =   0  'Transparent
      Caption         =   "Back to description"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   7
      Left            =   360
      TabIndex        =   29
      ToolTipText     =   "Return to previous page with description of position functions."
      Top             =   7920
      Visible         =   0   'False
      Width           =   5895
   End
   Begin VB.Label lblInstruct 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "Click on the candidate for more info"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Left            =   120
      TabIndex        =   28
      Top             =   1200
      Visible         =   0   'False
      Width           =   11775
   End
   Begin VB.Label lblChoices 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "(0)"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   9
      Left            =   1920
      TabIndex        =   1
      Top             =   2760
      Visible         =   0   'False
      Width           =   7815
   End
   Begin VB.Label lblVSID 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Student ID:"
      ForeColor       =   &H00FFC0C0&
      Height          =   495
      Left            =   960
      TabIndex        =   27
      Top             =   6120
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.Label lblChoices 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Neutral"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   3
      Left            =   9120
      TabIndex        =   23
      ToolTipText     =   "Choose this to remain neutral on this position."
      Top             =   7920
      Visible         =   0   'False
      Width           =   2535
   End
   Begin VB.Label lblChoices 
      BackStyle       =   0  'Transparent
      Caption         =   "Back to candidates"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   5
      Left            =   360
      TabIndex        =   25
      ToolTipText     =   "Return to previous page with list of candidates."
      Top             =   7920
      Visible         =   0   'False
      Width           =   5895
   End
   Begin VB.Label lblChoices 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Submit Votes"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   6
      Left            =   7680
      TabIndex        =   26
      ToolTipText     =   "If you are sure of these votes, enter your student ID and click here to submit them."
      Top             =   7920
      Visible         =   0   'False
      Width           =   3975
   End
   Begin VB.Label lblChoices 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Vote for me"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   4
      Left            =   8040
      TabIndex        =   24
      ToolTipText     =   "Select this candidate to fill the current position."
      Top             =   7920
      Visible         =   0   'False
      Width           =   3615
   End
   Begin VB.Label lblCurCandidate 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "Jared Panks"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Left            =   600
      TabIndex        =   18
      Top             =   5040
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblChoices 
      BackStyle       =   0  'Transparent
      Caption         =   "Back to Positions"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   2
      Left            =   360
      TabIndex        =   15
      ToolTipText     =   "Return to main list of Student Government positions."
      Top             =   7920
      Visible         =   0   'False
      Width           =   5415
   End
   Begin VB.Image imgCurCandidate 
      BorderStyle     =   1  'Fixed Single
      Height          =   2310
      Left            =   600
      Stretch         =   -1  'True
      Top             =   2640
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     =   1  'Fixed Single
      Height          =   2310
      Index           =   0
      Left            =   120
      Stretch         =   -1  'True
      Top             =   9120
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     =   1  'Fixed Single
      Height          =   2310
      Index           =   1
      Left            =   2160
      Stretch         =   -1  'True
      Top             =   9120
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     =   1  'Fixed Single
      Height          =   2310
      Index           =   2
      Left            =   2160
      Stretch         =   -1  'True
      Top             =   9120
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     =   1  'Fixed Single
      Height          =   2310
      Index           =   3
      Left            =   2160
      Stretch         =   -1  'True
      Top             =   9120
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     =   1  'Fixed Single
      Height          =   2310
      Index           =   4
      Left            =   2160
      Stretch         =   -1  'True
      Top             =   9120
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     =   1  'Fixed Single
      Height          =   2310
      Index           =   5
      Left            =   2160
      Stretch         =   -1  'True
      Top             =   9120
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     =   1  'Fixed Single
      Height          =   2310
      Index           =   6
      Left            =   2160
      Stretch         =   -1  'True
      Top             =   9120
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     =   1  'Fixed Single
      Height          =   2310
      Index           =   7
      Left            =   2160
      Stretch         =   -1  'True
      Top             =   9120
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     =   1  'Fixed Single
      Height          =   2310
      Index           =   8
      Left            =   2160
      Stretch         =   -1  'True
      Top             =   9120
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     =   1  'Fixed Single
      Height          =   2310
      Index           =   9
      Left            =   2160
      Stretch         =   -1  'True
      Top             =   9120
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Label lblCandidates 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "Jared Panks"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   0
      Left            =   120
      TabIndex        =   16
      Top             =   11520
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblCandidates 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   1
      Left            =   2160
      TabIndex        =   6
      Top             =   11520
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblCandidates 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   2
      Left            =   2160
      TabIndex        =   7
      Top             =   11520
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblCandidates 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   3
      Left            =   2160
      TabIndex        =   8
      Top             =   11520
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblCandidates 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   4
      Left            =   2160
      TabIndex        =   9
      Top             =   11520
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblCandidates 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   5
      Left            =   2160
      TabIndex        =   10
      Top             =   11520
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblCandidates 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   6
      Left            =   2160
      TabIndex        =   11
      Top             =   11520
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblCandidates 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   7
      Left            =   2160
      TabIndex        =   12
      Top             =   11520
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblCandidates 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   8
      Left            =   2160
      TabIndex        =   13
      Top             =   11520
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblCandidates 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   9
      Left            =   2160
      TabIndex        =   14
      Top             =   11520
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblChoices 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Cast your votes"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   0
      Left            =   6840
      TabIndex        =   3
      ToolTipText     =   "Once you are sure these are the candidates you want for these positions, click here."
      Top             =   7920
      Visible         =   0   'False
      Width           =   4815
   End
   Begin VB.Label Label1 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "Executive for..."
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Left            =   1920
      TabIndex        =   5
      Top             =   1680
      Visible         =   0   'False
      Width           =   7815
   End
   Begin VB.Label lblChoices 
      BackStyle       =   0  'Transparent
      Caption         =   "Clear Votes"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   1
      Left            =   360
      TabIndex        =   4
      ToolTipText     =   "Clear the selected candidates for all positions."
      Top             =   7920
      Visible         =   0   'False
      Width           =   3615
   End
   Begin VB.Label lblTitle 
      BackColor       =   &H00FFC0C0&
      BackStyle       =   0  'Transparent
      Caption         =   "Student Government Positions"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FF7070&
      Height          =   855
      Left            =   240
      TabIndex        =   0
      Top             =   120
      Width           =   11535
   End
   Begin VB.Shape shpTitle 
      BorderColor     =   &H00FFC0C0&
      BorderWidth     =   5
      FillColor       =   &H00FFC0C0&
      FillStyle       =   0  'Solid
      Height          =   855
      Left            =   120
      Shape           =   4  'Rounded Rectangle
      Top             =   120
      Width           =   11775
   End
   Begin VB.Label lblHighlight 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "(highlight)"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   27.75
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFB0B0&
      Height          =   615
      Left            =   120
      TabIndex        =   2
      Top             =   11760
      Visible         =   0   'False
      Width           =   2550
   End
   Begin VB.Image imgBg 
      Height          =   3690
      Left            =   4200
      Picture         =   "Vote.frx":001E
      Top             =   9120
      Width           =   6000
   End
   Begin VB.Label lblSelections 
      BackStyle       =   0  'Transparent
      Caption         =   "(selected candidate)"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   375
      Index           =   0
      Left            =   6960
      TabIndex        =   17
      Top             =   3000
      Visible         =   0   'False
      Width           =   2295
   End
End
Attribute VB_Name = "frmVote"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Student Government Voting
'Dwayne Robinson
'2001.4.10

DefLng A-Z
Option Explicit

Const CurPagePositions = 1
Const CurPagePosDesc = 2
Const CurPageCndts = 3
Const CurPageAboutCndt = 4
Const CurPageSelections = 5

Const lblChoiceCastVotes = 0
Const lblChoiceClearVotes = 1
Const lblChoiceBackPos = 2
Const lblChoiceNeutral = 3
Const lblChoiceVoteForMe = 4
Const lblChoiceBackCndts = 5
Const lblChoiceSubmitVotes = 6
Const lblChoicePosDesc = 7
Const lblChoiceToCndts = 8
Const lblChoicePositions = 9

Const MaxCndtsPerPage = 10
Const MaxCndtsPerRow = 5
Const PicWidth = 132
Const PicHeight = 154
Const PicRowSep = 32
Const PicColSep = 8

Dim CurPage
Dim CurPosition
Dim CurCandidate
Dim CurPosCndts 'number of candidates for current position
Dim MouseOverObject As Object
Dim MouseClickedObject As Boolean
Dim CndtsSelected(MaxPositions - 1)


Private Sub Form_Load()
Dim Count

PaintPicture imgBg.Picture, 0, 0, ScaleWidth, ScaleHeight, 0, 0, imgBg.Width, imgBg.Height, vbSrcCopy

SelectPositions
ClearVotes
CurPage = CurPagePositions
ChangePage

End Sub


Private Sub Form_KeyPress(KeyAscii As Integer)
    If KeyAscii = 27 Then
        KeyAscii = 0
        Select Case CurPage
        Case CurPageAboutCndt
            CurPage = CurPageCndts
            ChangePage
        Case CurPageCndts
            CurPage = CurPagePosDesc
            ChangePage
        Case CurPagePositions
            'Unload Me
            ClearVotes
        Case Else
            CurPage = CurPagePositions
            ChangePage
        End Select
    End If
End Sub


Private Sub SelectLabel(Obj As Label)

If Not MouseOverObject Is Obj Then
    If Not MouseOverObject Is Nothing Then MouseOverObject.ForeColor = &HFFC0C0
    Set MouseOverObject = Obj
    lblHighlight.Visible = False
    lblHighlight.Top = MouseOverObject.Top + 2
    lblHighlight.Left = MouseOverObject.Left + 2
    lblHighlight.Height = MouseOverObject.Height
    lblHighlight.Width = MouseOverObject.Width
    lblHighlight.Alignment = MouseOverObject.Alignment
    lblHighlight.Caption = MouseOverObject.Caption
    lblHighlight.Font.Size = MouseOverObject.Font.Size
    MouseOverObject.ForeColor = &HFFF0F0
    lblHighlight.Visible = True
End If

End Sub


Private Sub DepressLabel()

If Not MouseOverObject Is Nothing Then
    lblHighlight.ForeColor = &HFFFFFF
    MouseOverObject.Visible = False
    MouseClickedObject = True
End If

End Sub


Private Sub ReleaseLabel()

If Not MouseOverObject Is Nothing Then
    lblHighlight.ForeColor = &HFFB0B0
    MouseOverObject.Visible = True
    MouseClickedObject = False
End If

End Sub


Private Sub Form_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
If (Button And 2) Then
    If Shift = 3 Then
        Unload Me
    Else
        CurPage = CurPagePositions
        ChangePage
    End If
End If
End Sub


Private Sub lblCandidates_Click(Index As Integer)
imgCandidates_Click Index
End Sub


Private Sub lblChoices_MouseDown(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)
If Button And 1 Then DepressLabel
End Sub


Private Sub lblChoices_MouseMove(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)
SelectLabel lblChoices(Index)
End Sub


Private Sub lblChoices_MouseUp(Index As Integer, Button As Integer, Shift As Integer, X As Single, Y As Single)

If Not MouseClickedObject Then Exit Sub
ReleaseLabel

If Y < 0 Or X < 0 Or Y \ 15 >= lblChoices(Index).Height Or X \ 15 >= lblChoices(Index).Width Then Exit Sub
Select Case Index
Case lblChoiceCastVotes  'change to selected candidates page
    DisplaySelections
Case lblChoiceClearVotes  'clear selected votes
    ClearVotes
Case lblChoiceBackPos  'back to positions
    CurPage = CurPagePositions
    ChangePage
Case lblChoiceNeutral  'no specific candidate chosen
    CurCandidate = -1
    VoteForCandidate
    'CurPage = CurPagePositions
    'ChangePage
Case lblChoiceVoteForMe  'vote for current candidate
    VoteForCandidate
Case lblChoiceBackCndts  'back to candidates
    CurPage = CurPageCndts
    ChangePage
Case lblChoiceSubmitVotes  'submit votes
    SubmitVotes
Case lblChoicePosDesc       'back to position description
    CurPage = CurPagePosDesc
    ChangePage
Case lblChoiceToCndts       'to candidate selection
    CurPage = CurPageCndts
    ChangePage
Case Is >= lblChoicePositions
    CurPosition = Index - lblChoicePositions
    SelectCandidates
    txtPosDesc.Text = PositionDescs(CurPosition)
    CurPage = CurPagePosDesc
    ChangePage
'Case Else
End Select

End Sub


Private Sub imgCandidates_Click(Index As Integer)
CurCandidate = imgCandidates(Index).Tag
imgCurCandidate.Picture = CandidatePics(CurCandidate)
lblCurCandidate.Caption = CandidateFnames(CurCandidate) & " " & CandidateLnames(CurCandidate)
txtCndtMsg.Text = CandidateMsgs(CurCandidate)
CurPage = CurPageAboutCndt
ChangePage
End Sub


Private Sub lstSelections_Click()
imgCurCandidate.Picture = CandidatePics(lstSelections.ItemData(lstSelections.ListIndex))
End Sub


Private Sub txtPAC_KeyPress(KeyAscii As Integer)
If KeyAscii = 13 Then
    SubmitVotes
Else
    AllowNumbersOnly txtPAC, KeyAscii
End If
End Sub


Private Sub txtVSID_KeyPress(KeyAscii As Integer)
If KeyAscii = 13 Then
    SubmitVotes
Else
    AllowNumbersOnly txtVSID, KeyAscii
End If
End Sub


Private Sub SelectPositions()
'Space all positions accordingly depending on how many there are
'
Dim Count, Row, Index, Size
Const lblPositionTop = 184
Const lblPositionLeft = 128
Const lblPositionHeight = 260 '424-184
Const lblPositionWidth = 521

Set Font = lblChoices(lblChoicePositions).Font
For Count = 0 To TotalPositions - 1
    Index = lblChoicePositions + Count
    If Count > 0 Then
        'load position name label
        Load lblChoices(Index)
        Load lblSelections(Count)
        lblChoices(Index).Alignment = vbCenter
        lblChoices(Index).ZOrder (0)
        'load candidate name control
        'position control vertically according to x / total + top
        Row = (lblPositionHeight * Count) \ (TotalPositions - 1) + lblPositionTop
    Else
        Row = lblPositionTop
    End If
    Size = TextWidth(PositionNames(Count))
    lblChoices(Index).Move (lblPositionWidth - Size) \ 2 + lblPositionLeft, Row, Size, 57
    lblChoices(Index).Caption = PositionNames(Count)
    'position associated label for selected candidate
    lblSelections(Count).Move (lblPositionWidth + Size) \ 2 + lblPositionLeft + 8, _
                               Row + 16
Next

End Sub


Private Sub SelectCandidates()
'Includes all candidates applying for the selected position
'Copies their picture and name to the form
'Repositions the candidate pictures for symmetry
Dim Count
Dim Rows, Cols
Dim Row, Col, RowMod
Dim PicTop, PicLeft
'Dim PicHeight, PicWidth
Dim FormHeight, FormWidth

CurPosCndts = 0
For Count = 0 To TotalCandidates - 1
    If Count >= MaxCndtsPerPage Then Exit For
    If CandidatePositions(Count, CurPosition) Then
        imgCandidates(CurPosCndts).Tag = Count 'CandidateSids(Count)
        imgCandidates(CurPosCndts).Picture = CandidatePics(Count)
        lblCandidates(CurPosCndts).Caption = CandidateFnames(Count) & " " & CandidateLnames(Count)
        CurPosCndts = CurPosCndts + 1
    End If
Next

If CurPosCndts <= 0 Then
    lblInstruct.Caption = "No candidates for this position"
    Exit Sub
Else
    lblInstruct.Caption = "Click on the candidate for more info"
End If

FormHeight = ScaleHeight
FormWidth = ScaleWidth
'PicHeight = imgCurCandidate.Height
'PicWidth = imgCurCandidate.Width
Rows = (CurPosCndts + MaxCndtsPerRow - 1) \ MaxCndtsPerRow
Cols = CurPosCndts \ Rows
PicTop = (FormHeight - Rows * (PicHeight + PicRowSep) + PicRowSep) \ 2
RowMod = CurPosCndts Mod Rows
Count = 0
Do Until Count >= CurPosCndts
    Col = Col - 1
    If Col <= 0 Then
        If Count > 0 Then
            Row = Row + 1
            PicTop = PicTop + PicHeight + PicRowSep
        End If
        Col = Cols
        If Row < RowMod Then Col = Col + 1
        PicLeft = (FormWidth - Col * (PicWidth + PicColSep) + PicColSep) \ 2
    End If
    imgCandidates(Count).Move PicLeft, PicTop
    lblCandidates(Count).Move PicLeft, PicTop + PicHeight
    PicLeft = PicLeft + PicWidth + PicColSep
    Count = Count + 1
Loop

End Sub


Public Sub DisplaySelections()
Dim Count

For Count = 0 To TotalPositions - 1
    If CndtsSelected(Count) >= 0 Then Exit For
Next
If Count < TotalPositions Then
    lstSelections.Clear
    For Count = 0 To TotalPositions - 1
        If CndtsSelected(Count) >= 0 Then
            lstSelections.AddItem lblSelections(Count).Caption & " for " & PositionNames(Count)
            lstSelections.ItemData(lstSelections.NewIndex) = CndtsSelected(Count)
        End If
    Next
    CurPage = CurPageSelections
    txtVSID.Text = ""
    txtPAC.Text = ""
    ChangePage
    txtVSID.SetFocus
Else
    MsgBox "You need to first select at least one candidate by choosing from the positions listed.", vbInformation
End If

End Sub


Public Sub ClearVotes()
Dim Count

For Count = 0 To TotalPositions - 1
    CndtsSelected(Count) = -1
    lblSelections(Count).Caption = ""
Next

End Sub


Private Sub SubmitVotes()

If Len(txtVSID.Text) = 9 Then
    If Len(txtPAC.Text) = 4 Then
        StoreDbVotes Val(txtVSID.Text), Val(txtPAC.Text), CndtsSelected()
        If Not SgvErr Then
            ClearVotes
            MsgBox "Thankyou for casting your vote!", vbQuestion
            CurPage = CurPagePositions
            ChangePage
        End If
    Else
        MsgBox "Your personal access code is the same 4 digit number you used to register your classes, usually your month and day of birth.", vbExclamation
        With txtPAC
        .SelStart = 0
        .SelLength = 32767
        .SetFocus
        End With
    End If
Else
    MsgBox "Your student ID number is the 9 digit number of your student card, usually the same as your social security number.", vbExclamation
    With txtVSID
    .SelStart = 0
    .SelLength = 32767
    .SetFocus
    End With
End If

End Sub

Public Sub VoteForCandidate()
'advance to next position
'or to vote submission if last position was just voted for

CndtsSelected(CurPosition) = CurCandidate
If CurCandidate >= 0 Then
    lblSelections(CurPosition).Caption = CandidateFnames(CurCandidate) & " " & CandidateLnames(CurCandidate)
Else
    lblSelections(CurPosition).Caption = ""
End If
If CurPosition + 1 < TotalPositions Then
    CurPosition = CurPosition + 1
    txtPosDesc.Text = PositionDescs(CurPosition)
    SelectCandidates
    CurPage = CurPagePosDesc
    ChangePage
Else
    DisplaySelections
End If

End Sub


Public Sub ChangePage()

Dim Count, PageVisible As Boolean, ItemVisible As Boolean
Select Case CurPage
Case CurPagePositions, CurPageSelections
    lblTitle.Caption = "Student Government Voting"
Case CurPagePosDesc
    lblTitle.Caption = PositionNames(CurPosition) & " functions"
Case CurPageCndts
    lblTitle.Caption = PositionNames(CurPosition)
'Case CurPageAboutCndt
End Select

PageVisible = (CurPage = CurPagePositions)
Label1.Visible = PageVisible
lblChoices(lblChoiceCastVotes).Visible = PageVisible
lblChoices(lblChoiceClearVotes).Visible = PageVisible
For Count = 0 To TotalPositions - 1
    lblChoices(lblChoicePositions + Count).Visible = PageVisible
    lblSelections(Count).Visible = PageVisible
Next

PageVisible = (CurPage = CurPagePosDesc)
lblChoices(lblChoiceBackPos).Visible = PageVisible Or (CurPage = CurPageSelections)
lblChoices(lblChoiceToCndts).Visible = PageVisible
txtPosDesc.Visible = PageVisible

PageVisible = (CurPage = CurPageCndts)
lblInstruct.Visible = PageVisible
lblChoices(lblChoicePosDesc).Visible = PageVisible
lblChoices(lblChoiceNeutral).Visible = PageVisible
For Count = 0 To MaxCndtsPerPage - 1
    ItemVisible = PageVisible And (Count < CurPosCndts)
    imgCandidates(Count).Visible = ItemVisible
    lblCandidates(Count).Visible = ItemVisible
Next

PageVisible = (CurPage = CurPageAboutCndt)
lblChoices(lblChoiceVoteForMe).Visible = PageVisible
lblChoices(lblChoiceBackCndts).Visible = PageVisible
txtCndtMsg.Visible = PageVisible
PageVisible = PageVisible Or (CurPage = CurPageSelections)
lblCurCandidate.Visible = PageVisible
imgCurCandidate.Visible = PageVisible

PageVisible = (CurPage = CurPageSelections)
lstSelections.Visible = PageVisible
txtVSID.Visible = PageVisible
txtPAC.Visible = PageVisible
lblVSID.Visible = PageVisible
lblPAC.Visible = PageVisible
lblChoices(lblChoiceSubmitVotes).Visible = PageVisible

ItemVisible = Not MouseOverObject Is Nothing
If ItemVisible Then ItemVisible = MouseOverObject.Visible
lblHighlight.Visible = ItemVisible

End Sub


Public Sub AllowNumbersOnly(TxtItem As TextBox, KeyAscii As Integer)
If (KeyAscii < 48 Or KeyAscii > 57) And KeyAscii <> 8 Then
    KeyAscii = 0 'only allow numbers
End If
End Sub
