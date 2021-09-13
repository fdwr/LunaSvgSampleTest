VERSION 5.00
Begin VB.Form frmVote 
   AutoRedraw      =   -1  'True
   BorderStyle     =   0  'None
   Caption         =   "Student Government Voting"
   ClientHeight    =   18000
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   12000
   ClipControls    = 0
   Icon            =   "Vote.frx":0000
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   ScaleHeight     =   1200
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   800
   ShowInTaskbar   = 0
   StartUpPosition =   3  'Windows Default
   WindowState     =   2  'Maximized
   Begin VB.Timer tmrTest 
      Enabled         = 0
      Interval        =   100
      Left            =   120
      Top             =   12360
   End
   Begin VB.Label lblChoices 
      BackStyle       =   0  'Transparent
      Caption         =   "Back to Positions"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   7
      Left            =   3240
      TabIndex        =   20
      Top             =   7920
      Visible         = 0
      Width           =   5535
   End
   Begin VB.Image imgCurCandidate 
      BorderStyle = 1
      Height = 2310
      Left = 600
      Top = 1800
      Visible = 0
      Width = 1980
   End
   Begin VB.Label lblCndtMsg
      BackStyle       =   0  'Transparent
      Caption         =   "(candidate message)"
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   0
      Left            =   120
      TabIndex        =   10
      Top             =   1800
      Visible         = 0
      Width           =   1935
   End
   Begin VB.Image imgCandidates 
      BorderStyle     = 1
      Height          =   2310
      Index           =   0
      Left            =   120
      Top             =   9120
      Visible         = 0
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     = 1
      Height          =   2310
      Index           =   1
      Left            =   2160
      Top             =   9120
      Visible         = 0
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     = 1
      Height          =   2310
      Index           =   2
      Left            =   2160
      Top             =   9120
      Visible         = 0
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     = 1
      Height          =   2310
      Index           =   3
      Left            =   2160
      Top             =   9120
      Visible         = 0
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     = 1
      Height          =   2310
      Index           =   4
      Left            =   2160
      Top             =   9120
      Visible         = 0
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     = 1
      Height          =   2310
      Index           =   5
      Left            =   2160
      Top             =   9120
      Visible         = 0
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     = 1
      Height          =   2310
      Index           =   6
      Left            =   2160
      Top             =   9120
      Visible         = 0
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     = 1
      Height          =   2310
      Index           =   7
      Left            =   2160
      Top             =   9120
      Visible         = 0
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     = 1
      Height          =   2310
      Index           =   8
      Left            =   2160
      Top             =   9120
      Visible         = 0
      Width           =   1980
   End
   Begin VB.Image imgCandidates 
      BorderStyle     = 1
      Height          =   2310
      Index           =   9
      Left            =   2160
      Top             =   9120
      Visible         = 0
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   0
      Left            =   120
      TabIndex        =   10
      Top             =   11520
      Visible         = 0
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   1
      Left            =   2160
      TabIndex        =   11
      Top             =   11520
      Visible         = 0
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   2
      Left            =   2160
      TabIndex        =   12
      Top             =   11520
      Visible         = 0
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   3
      Left            =   2160
      TabIndex        =   13
      Top             =   11520
      Visible         = 0
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   4
      Left            =   2160
      TabIndex        =   14
      Top             =   11520
      Visible         = 0
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   5
      Left            =   2160
      TabIndex        =   15
      Top             =   11520
      Visible         = 0
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   6
      Left            =   2160
      TabIndex        =   16
      Top             =   11520
      Visible         = 0
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   7
      Left            =   2160
      TabIndex        =   17
      Top             =   11520
      Visible         = 0
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   8
      Left            =   0
      TabIndex        =   18
      Top             =   0
      Visible         = 0
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   255
      Index           =   9
      Left            =   2160
      TabIndex        =   19
      Top             =   11520
      Visible         = 0
      Width           =   1935
   End
   Begin VB.Label lblChoices 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "Finance"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   4
      Left            =   1920
      TabIndex        =   5
      Top             =   6360
      Visible         = 0
      Width           =   7815
   End
   Begin VB.Label lblChoices 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "Clubs && Organizations"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   3
      Left            =   1920
      TabIndex        =   6
      Top             =   5400
      Visible         = 0
      Width           =   7815
   End
   Begin VB.Label lblChoices 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "College Representatives"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   2
      Left            =   1920
      TabIndex        =   1
      Top             =   4440
      Visible         = 0
      Width           =   7815
   End
   Begin VB.Label lblChoices 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "Student Relations"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   1
      Left            =   1920
      TabIndex        =   2
      Top             =   3600
      Visible         = 0
      Width           =   7815
   End
   Begin VB.Label lblChoices 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "Senate"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   0
      Left            =   1920
      TabIndex        =   3
      Top             =   2760
      Visible         = 0
      Width           =   7815
   End
   Begin VB.Label lblChoices 
      BackStyle       =   0  'Transparent
      Caption         =   "Cast your votes"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   400
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   5
      Left            =   360
      TabIndex        =   7
      Top             =   7920
      Visible         = 0
      Width           =   5055
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Left            =   1920
      TabIndex        =   9
      Top             =   1680
      Visible         = 0
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFC0C0&
      Height          =   855
      Index           =   6
      Left            =   7800
      TabIndex        =   8
      Top             =   7920
      Visible         = 0
      Width           =   3855
   End
   Begin VB.Label lblTitle 
      BackStyle       =   0  'Transparent
      Caption         =   "Student Government Positions"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   36
         Charset         =   0
         Weight          =   700
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FF7070&
      Height          =   855
      Left            =   240
      TabIndex        =   0
      Top             =   120
      Width           =   11535
   End
   Begin VB.Shape shpTitle 
      BorderColor     =   &H00FFD0D0&
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
         Underline       = 0
         Italic          = 0
         Strikethrough   = 0
      EndProperty
      ForeColor       =   &H00FFB0B0&
      Height          =   615
      Left            =   120
      TabIndex        =   4
      Top             =   8280
      Visible         = 0
      Width           =   2550
   End
   Begin VB.Image imgBg 
      Height          =   3690
      Left            =   4200
      Picture         =   "Vote.frx":0442
      Stretch         =   -1  'True
      Top             =   9120
      Width           =   6000
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
Const CurPageCndts = 2
Const CurPageAboutCndt = 3
Const CurPageSelections = 3
Const MaxCndtsPerPage = 10
Const MaxCndtsPerRow = 10
Const PicWidth = 80
Const PicHeight = 100
Const PicRowSep = 100
Const PicColSep = 150

Dim CurPage
Dim CurPosition
dim CurCandidate
dim CurPosCndts 'number of candidates for current position
Dim MouseOverObject As Object
dim CndtsSelected(MaxPositions-1)


Private Sub Form_Load()

PaintPicture imgBg.Picture, 0, 0, ScaleWidth, ScaleHeight, 0, 0, imgBg.Width, imgBg.Height, vbSrcCopy
'Set imgCurCandidate.Picture = CandidatePics(1)

ClearVotes
CurPage = CurPagePositions
ChangePage

End Sub


Private Sub Form_KeyPress(KeyAscii As Integer)
    If KeyAscii = 27 Then Unload Me
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
End If

End Sub


Private Sub ReleaseLabel()

If Not MouseOverObject Is Nothing Then
    lblHighlight.ForeColor = &HFFB0B0
    MouseOverObject.Visible = True
End If

End Sub


Private Sub imgCandidates_Click(Index As Integer)
curcandidate = imgcandidates(index).tag
imgcurcandidate.picture = Candidatepics(curcandidate)
lblCndtMsg.caption = CandidateMsgs(curcandidate)
CurPage = CurPageAboutCndt
ChangePage
End Sub


Private Sub lblChoices_MouseDown(Index As Integer, Button As Integer, Shift As Integer, x As Single, y As Single)
DepressLabel
End Sub


Private Sub lblChoices_MouseMove(Index As Integer, Button As Integer, Shift As Integer, x As Single, y As Single)
SelectLabel lblChoices(Index)
End Sub


Private Sub lblChoices_MouseUp(Index As Integer, Button As Integer, Shift As Integer, x As Single, y As Single)

ReleaseLabel

If y < 0 Or x < 0 Or y \ 15 >= lblChoices(Index).Height Or x \ 15 >= lblChoices(Index).Width Then Exit Sub
Select Case Index
Case 0 To 4
    CurPosition = Index
    SelectCandidates
    CurPage = CurPageCndts
    ChangePage
Case 5 'cast votes
    DisplaySelections
Case 6 'clear votes
    ClearVotes
Case 7 'back to positions
    CurPage = CurPagePositions
    ChangePage
case 8 'vote for me
    VoteForCandidate
case 9 'back to candidates
    CurPage = CurPageCndts
    ChangePage
case 10 'submit votes
    SubmitVotes CndtsSelected()
    ClearVotes    
'Case Else
End Select

End Sub


private sub SelectCandidates
'Includes all candidates applying for the selected position
'Copies their picture and name to the form
'Repositions the candidate pictures for symmetry
dim Count
dim Rows, Cols
dim Row, Col, RowMod
dim PicTop, PicLeft
dim ScreenHeight, ScreenWidth

Count = TotalCandidates-1

for Count = 0 to TotalCandidates-1
    if Count >= MaxCndtsPerPage then exit for
    if CandidatePositions(Count, curposition) then
        imgCandidates(CurPosCndts).visible = true
        imgCandidates(CurPosCndts).tag = CandidateSids(Count)
        imgCandidates(CurPosCndts).picture = CandidatePics(Count)
        lblCandidates(CurPosCndts).caption = CandidateFnames(Count) & " " & CandidateLnames(Count)
        CurPosCndts =CurPosCndts+1
    end if
next

if CurPosCndts <= 0 then exit sub

ScreenHeight=height
screenwidth=width
PicTop = (ScreenHeight - (Rows * PicRowSep)+PicRowSep) \ 2
RowMod = CurPosCndts MOD Rows
Count = 0
do until Count >= CurPosCndts
    Col = Col - 1
    IF Col <= 0 THEN
        IF Count > 0 THEN
            Row = Row + 1
            PicTop = PicTop + PicRowSep
        END IF
        Col = Cols
        IF Row < RowMod THEN Col = Col + 1
        PicLeft = (ScreenWidth - (Col * PicColSep)+ PicColSep) \ 2
    END IF
    PicLeft = PicLeft + ColSep
    imgcandidates(count).move picleft,pictop
loop

end sub


public sub DisplaySelections()
dim Count

for Count = 0 to MaxPositions-1
    if CndtsSelected(count) >=0 then exit for
next
if count<MaxPositions then
    lstSelections.clear
    for count = 0 to maxpositions-1
        lstSelections.additem lblSelections(count).caption & " for " & PositionNames(count)
    next
    CurPage = CurPageSelections
    ChangePage
else
    msgbox "You need to first select at least one candidate by choosing one of the positions listed above."
end if

end sub


public sub ClearVotes()
dim Count

for Count = 0 to MaxPositions-1
    CndtsSelected(count)=-1
    lblSelections(count).caption =""
next

end sub


public sub VoteForCandidate()
'advance to next position
'or to vote submission if last position was just voted for

lblSelections(curposition).caption = CandidateFnames(curcandidate) & " " & CandidateLnames(curcandidate)
curposition = curposition+1
if  curposition < maxpositions then
    SelectCandidates
    CurPage = CurPageCndts
    ChangePage
else
    DisplaySelections
end if

end sub


Public Sub ChangePage()

Dim Count, PageVisible As Boolean, ItemVisible As Boolean
Select Case CurPage
Case CurPagePositions
    lblTitle.Caption = "Student Government Voting"
Case CurPageCndts
    lblTitle.Caption = PositionNames(CurPosition)
Case CurPageAboutCndt
End Select

PageVisible = (CurPage = CurPagePositions)
Label1.Visible = PageVisible
For Count = 0 To 6
    lblChoices(Count).Visible = PageVisible
Next

PageVisible = (CurPage = CurPageCndts)
For Count = 7 To 7
    lblChoices(Count).Visible = PageVisible
Next
For Count = 0 To MaxCndtsPerPage - 1
    ItemVisible = PageVisible and (Count < CurPosCndts)
    imgCandidates(Count).Visible = ItemVisible
    lblCandidates(Count).Visible = ItemVisible
Next

PageVisible = (CurPage = CurPageAboutCndt)
if pagevisible then
    imgCurCandidate.picture = imgCandidates(curcandidate)
end if
imgCurCandidate.Visible = PageVisible
lblCndtMsg.Visible = PageVisible

lblHighlight.Visible = False

End Sub
