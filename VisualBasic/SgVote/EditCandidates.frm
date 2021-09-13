VERSION 5.00
Begin VB.Form frmEditCandidates 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Candidate Editor"
   ClientHeight    =   4800
   ClientLeft      =   150
   ClientTop       =   435
   ClientWidth     =   6360
   Icon            =   "EditCandidates.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   320
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   424
   StartUpPosition =   2  'CenterScreen
   Begin VB.PictureBox picStupid 
      AutoRedraw      =   -1  'True
      BackColor       =   &H80000005&
      ClipControls    =   0   'False
      Enabled         =   0   'False
      Height          =   2310
      Left            =   5760
      ScaleHeight     =   150
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   128
      TabIndex        =   21
      TabStop         =   0   'False
      Top             =   4200
      Width           =   1980
   End
   Begin VB.PictureBox picCandidate 
      AutoRedraw      =   -1  'True
      BackColor       =   &H80000005&
      Height          =   2310
      Left            =   1080
      ScaleHeight     =   150
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   128
      TabIndex        =   22
      TabStop         =   0   'False
      Top             =   120
      Width           =   1980
   End
   Begin VB.CommandButton cmdClearPic 
      Caption         =   "X"
      Height          =   285
      Left            =   2760
      TabIndex        =   20
      ToolTipText     =   "Clear image."
      Top             =   2520
      Width           =   300
   End
   Begin VB.CommandButton cmdGoto 
      Caption         =   "&Goto..."
      Height          =   375
      Left            =   3960
      TabIndex        =   14
      ToolTipText     =   "Opens menu to quickly select a candidate."
      Top             =   4320
      Width           =   855
   End
   Begin VB.CommandButton cmdNext 
      Caption         =   "&>>"
      Height          =   375
      Left            =   5640
      TabIndex        =   16
      ToolTipText     =   "Next"
      Top             =   4320
      Width           =   615
   End
   Begin VB.CommandButton cmdDelete 
      Caption         =   "&Delete"
      Height          =   375
      Left            =   1080
      TabIndex        =   11
      ToolTipText     =   "Delete this candidate."
      Top             =   4320
      Width           =   855
   End
   Begin VB.CommandButton cmdInsert 
      Caption         =   "&Insert"
      Height          =   375
      Left            =   120
      TabIndex        =   10
      ToolTipText     =   "Insert a new candidate."
      Top             =   4320
      Width           =   855
   End
   Begin VB.CommandButton cmdPicFile 
      Caption         =   "..."
      Height          =   285
      Left            =   2400
      TabIndex        =   19
      ToolTipText     =   "Open file list to choose image."
      Top             =   2520
      Width           =   300
   End
   Begin VB.TextBox txtPicFile 
      Alignment       =   1  'Right Justify
      BackColor       =   &H80000016&
      Height          =   285
      Left            =   1080
      Locked          =   -1  'True
      TabIndex        =   18
      TabStop         =   0   'False
      ToolTipText     =   "Bitmap name used to store candidate's picture."
      Top             =   2520
      Width           =   1260
   End
   Begin VB.ListBox lstPositions 
      Height          =   1410
      ItemData        =   "EditCandidates.frx":000C
      Left            =   4200
      List            =   "EditCandidates.frx":000E
      Style           =   1  'Checkbox
      TabIndex        =   7
      Top             =   1200
      Width           =   2055
   End
   Begin VB.TextBox txtMsg 
      Height          =   1335
      Left            =   1080
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   9
      Top             =   2880
      Width           =   5175
   End
   Begin VB.TextBox txtLname 
      Height          =   285
      Left            =   4200
      TabIndex        =   5
      Top             =   840
      Width           =   2055
   End
   Begin VB.TextBox txtFname 
      Height          =   285
      Left            =   4200
      TabIndex        =   3
      Top             =   480
      Width           =   2055
   End
   Begin VB.TextBox txtSid 
      Height          =   285
      Left            =   4200
      MaxLength       =   9
      TabIndex        =   1
      ToolTipText     =   "Student ID is usually the same as Social Security Number."
      Top             =   120
      Width           =   2055
   End
   Begin VB.CommandButton cmdPrevious 
      Caption         =   "&<<"
      Height          =   375
      Left            =   4920
      TabIndex        =   15
      ToolTipText     =   "Previous"
      Top             =   4320
      Width           =   615
   End
   Begin VB.CommandButton cmdStore 
      Caption         =   "&Store"
      Height          =   375
      Left            =   3000
      TabIndex        =   13
      ToolTipText     =   "Commit changes to database."
      Top             =   4320
      Width           =   855
   End
   Begin VB.CommandButton cmdUndo 
      Caption         =   "&Undo"
      Height          =   375
      Left            =   2040
      TabIndex        =   12
      ToolTipText     =   "Undo any changes made to this candidate's information."
      Top             =   4320
      Width           =   855
   End
   Begin VB.Image imgCandidate 
      Height          =   2310
      Left            =   1080
      Top             =   120
      Visible         =   0   'False
      Width           =   1980
   End
   Begin VB.Label lblSid 
      BackColor       =   &H80000016&
      Caption         =   "Student ID"
      Height          =   315
      Left            =   3240
      TabIndex        =   0
      Top             =   105
      Width           =   3030
   End
   Begin VB.Label lblPositions 
      BackColor       =   &H80000016&
      Caption         =   "Positions"
      Height          =   1440
      Left            =   3240
      TabIndex        =   6
      Top             =   1185
      Width           =   3030
   End
   Begin VB.Label lblMsg 
      BackColor       =   &H80000016&
      Caption         =   "&Message"
      Height          =   1365
      Left            =   120
      TabIndex        =   8
      Top             =   2865
      Width           =   6150
   End
   Begin VB.Label lblLname 
      BackColor       =   &H80000016&
      Caption         =   "&Last Name"
      Height          =   315
      Left            =   3240
      TabIndex        =   4
      Top             =   825
      Width           =   3030
   End
   Begin VB.Label lblFname 
      BackColor       =   &H80000016&
      Caption         =   "&First Name"
      Height          =   315
      Left            =   3240
      TabIndex        =   2
      Top             =   465
      Width           =   3030
   End
   Begin VB.Label lblPicFile 
      BackColor       =   &H80000016&
      Caption         =   "&Picture"
      Height          =   2715
      Left            =   120
      TabIndex        =   17
      Top             =   105
      Width           =   2955
   End
   Begin VB.Menu MnuGoto 
      Caption         =   "(goto)"
      Visible         =   0   'False
      Begin VB.Menu mnuCandidates 
         Caption         =   "Work!!"
         Index           =   0
      End
   End
End
Attribute VB_Name = "frmEditCandidates"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
DefLng A-Z
Option Explicit


Private Declare Function GetNearestColor Lib "gdi32" (ByVal hdc As Long, ByVal crColor As Long) As Long

Const DefaultMsg = "(insert candidate's message here)"

Dim CurCandidate, NewCandidate, ChangeMade As Boolean, ChangesMade As Boolean
Dim ActiveLabel As Label

Private Sub cmdClearPic_Click()
If picCandidate.Picture <> 0 Then
    ChangeMade = True
    picCandidate.Picture = Nothing
End If
End Sub


Private Sub cmdClearPic_GotFocus()
SetActiveLabel lblPicFile
End Sub

Private Sub cmdClearPic_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
SetActiveControl cmdClearPic
End Sub

Private Sub cmdDelete_Click()
Dim Count, SubCount, Sid

If TotalCandidates <= 0 Then Exit Sub

On Error GoTo DbError
Set SgvTbl = SgvDb.OpenRecordset("tblCandidates")
''SgvTbl.Index = "SID"
''SgvTbl.Seek "=", CandidateSids(CurCandidate)
''If not SgvTbl.NoMatch Then sgvtbl.delete
SgvDb.Execute "DELETE * FROM tblCandidates WHERE SID=" & CandidateSids(CurCandidate) & ";"
SgvTbl.Close
On Error GoTo 0

'shift all records after current one forward
For Count = CurCandidate To TotalCandidates - 2
    Set CandidatePics(Count) = CandidatePics(Count + 1)
    CandidateSids(Count) = CandidateSids(Count + 1)
    CandidateFnames(Count) = CandidateFnames(Count + 1)
    CandidateLnames(Count) = CandidateLnames(Count + 1)
    CandidateMsgs(Count) = CandidateMsgs(Count + 1)
    For SubCount = 0 To TotalPositions - 1
        CandidatePositions(Count, SubCount) = CandidatePositions(Count + 1, SubCount)
    Next
    CandidateChanged(Count) = CandidateChanged(Count + 1)
Next
If CurCandidate < TotalCandidates Then TotalCandidates = TotalCandidates - 1
If CurCandidate < TotalCandidates Then
    'CurCandidate = TotalCandidates - 1
    LoadCandidate
Else
    ClearCandidate
End If
ChangesMade = True

ChangeCaption

Exit Sub

DbError:
ShowDbError
End Sub


Private Sub cmdGoto_Click()
Dim Count, MenuUbound, Text As String

If TotalCandidates <= 0 Then Exit Sub

MenuUbound = mnuCandidates.UBound
For Count = MenuUbound To TotalCandidates + 1 Step -1
    If Count <= 0 Then Exit For 'so that first one does not get unloaded
    Unload mnuCandidates(Count)
Next

For Count = 0 To TotalCandidates - 1
    If Count > MenuUbound Then Load mnuCandidates(Count)
    Text = CandidateFnames(Count) & " " & CandidateLnames(Count)
    If Text = " " Then Text = Count
    mnuCandidates(Count).Caption = Text
Next
If TotalCandidates < MaxCandidates Then
    If TotalCandidates > MenuUbound Then Load mnuCandidates(TotalCandidates)
    mnuCandidates(TotalCandidates).Caption = "(New Candidate)"
End If

PopupMenu MnuGoto, , , , mnuCandidates(CurCandidate)
End Sub


Private Sub cmdGoto_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
cmdGoto_Click
End Sub


Private Sub cmdInsert_Click()
Dim Count, SubCount

If TotalCandidates >= MaxCandidates Then Exit Sub
If ChangeMade Then SaveCandidate
If TotalCandidates <= 0 Then Exit Sub

For Count = TotalCandidates To CurCandidate + 1 Step -1
    Set CandidatePics(Count) = CandidatePics(Count - 1)
    CandidateSids(Count) = CandidateSids(Count - 1)
    CandidateFnames(Count) = CandidateFnames(Count - 1)
    CandidateLnames(Count) = CandidateLnames(Count - 1)
    CandidateMsgs(Count) = CandidateMsgs(Count - 1)
    For SubCount = 0 To TotalPositions - 1
        CandidatePositions(Count, SubCount) = CandidatePositions(Count - 1, SubCount)
    Next
    CandidateChanged(Count) = CandidateChanged(Count - 1)
Next
CandidateSids(CurCandidate) = 0
CandidateFnames(CurCandidate) = ""
CandidateLnames(CurCandidate) = ""
CandidateMsgs(CurCandidate) = ""
Set CandidatePics(CurCandidate) = Nothing
For Count = 0 To TotalPositions - 1
    CandidatePositions(CurCandidate, Count) = False
Next
CandidateChanged(CurCandidate) = False

TotalCandidates = TotalCandidates + 1
ClearCandidate
'ChangesMade = True
'unlike the delete, here it shouldn't save until something is entered
'actually entered in any of the above fields

ChangeCaption

End Sub


Private Sub cmdPicFile_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
SetActiveControl cmdPicFile
End Sub

Private Sub cmdUndo_Click()
LoadCandidate
End Sub


Private Sub cmdNext_Click()
If CurCandidate < TotalCandidates Or ChangeMade Then
    If ChangeMade Then SaveCandidate
    NewCandidate = CurCandidate + 1
    ChangeCandidate
End If
End Sub


Private Sub cmdPicFile_Click()
'Originally I wanted to just use a StdPicture object, but since VB
'was returning the stupidest, incorrect values for height and width,
'I had to settle for an invisible image control??? Alas, dumb VB...
Dim PicFile As String ', TempImage As StdPicture

PicFile = GetOpenFile(txtPicFile.Text, "Image Files (bmp gif jpg)" + vbNullChar + "*.bmp;*.gif;*.jpg" + vbNullChar + "All Files (*.*)" + vbNullChar + "*.*" + vbNullChar, "Import Picture File", hwnd)
If Len(PicFile) Then
    On Error GoTo PicErr
    imgCandidate = LoadPicture(PicFile)
    With picCandidate
        .PaintPicture imgCandidate.Picture, 0, 0, .ScaleWidth, .ScaleHeight, 0, 0, imgCandidate.Width, imgCandidate.Height, vbSrcCopy
    End With
    ChangeMade = True
End If
Exit Sub

PicErr:
MsgBox "Could not import the selected image:" & vbNewLine & Err.Description, vbExclamation
End Sub


Private Sub cmdPicFile_GotFocus()
SetActiveLabel lblPicFile
End Sub


Private Sub cmdPrevious_Click()
If CurCandidate > 0 Then
    NewCandidate = CurCandidate - 1
    ChangeCandidate
End If
End Sub


Private Sub cmdStore_Click()
If ChangeMade Then SaveCandidate
StoreToDatabase
If Not SgvErr Then ChangesMade = False: ChangeMade = False
End Sub


'Private Sub filPics_DblClick()
'imgDbTest.Picture = LoadPicture(filPics.Path & "\" & filPics.FileName)
'End Sub


Private Sub SetActiveLabel(NewLabel As Label)
Dim Clr

If ActiveLabel Is NewLabel Then Exit Sub

If Not ActiveLabel Is Nothing Then
    ActiveLabel.BackColor = &H80000016
    ActiveLabel.ForeColor = &H80000012
End If
Set ActiveLabel = NewLabel
Clr = &HFFC0C0 'dithered looks really bad on 16 color monitors
If GetNearestColor(hdc, Clr) <> Clr Then Clr = &HFF0000
ActiveLabel.BackColor = Clr
ActiveLabel.ForeColor = &HFFFFFF
End Sub


Private Sub SetActiveControl(Item As Object)
If Item.hwnd <> Me.ActiveControl.hwnd Then Item.SetFocus
End Sub


Private Sub Form_Load()
Dim Count
With lstPositions
For Count = 0 To TotalPositions - 1
    .AddItem PositionNames(Count)
Next
End With

'CurCandidate = 0
ChangeCaption
LoadCandidate
End Sub


Private Sub Form_Unload(Cancel As Integer)
Dim Result

'if change was made to the current record or any other ones
If ChangeMade Or ChangesMade Then
    Result = MsgBox("Store changes to database before closing program?", vbQuestion Or vbYesNoCancel Or vbDefaultButton1)
    If Result = vbYes Then
        cmdStore_Click
    ElseIf Result = vbCancel Then
        Cancel = True
    End If
End If
End Sub


Private Sub lstPositions_GotFocus()
SetActiveLabel lblPositions
End Sub

Private Sub lstPositions_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
SetActiveControl lstPositions
End Sub

Private Sub mnuCandidates_Click(Index As Integer)
If Index <> CurCandidate Then
    NewCandidate = Index
    ChangeCandidate
End If
End Sub


Private Sub picCandidate_Click()
cmdPicFile_Click
End Sub


Private Sub picCandidate_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
SetActiveControl cmdPicFile
End Sub


Private Sub Picture1_Click()
Stop
End Sub

Private Sub txtFname_Change()
ChangeMade = True
End Sub


Private Sub txtFname_GotFocus()
SetActiveLabel lblFname
End Sub


Private Sub txtFname_LostFocus()
CorrectName txtFname
End Sub


Private Sub txtFname_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
SetActiveControl txtFname
End Sub

Private Sub txtLname_Change()
ChangeMade = True
End Sub


Private Sub txtLname_GotFocus()
SetActiveLabel lblLname
End Sub


Private Sub txtLname_LostFocus()
CorrectName txtLname
End Sub


Private Sub txtLname_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
SetActiveControl txtLname
End Sub

Private Sub txtMsg_Change()
ChangeMade = True
End Sub


Private Sub txtMsg_GotFocus()
SetActiveLabel lblMsg
If txtMsg.Text = DefaultMsg Then txtMsg.SelStart = 0: txtMsg.SelLength = 32767
End Sub


Private Sub txtMsg_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
SetActiveControl txtMsg
End Sub

Private Sub txtPositions_GotFocus()
SetActiveLabel lblPositions
End Sub


Private Sub lstPositions_ItemCheck(Item As Integer)
ChangeMade = True
End Sub


Private Sub txtPicFile_GotFocus()
SetActiveLabel lblPicFile
End Sub


Private Sub txtPicFile_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
SetActiveControl txtPicFile
End Sub

Private Sub txtSid_Change()
Dim Text As String

Text = txtSid.Text
If Len(Text) Then Text = Text & ".bmp"
txtPicFile.Text = Text

ChangeMade = True
End Sub


Private Sub txtSid_GotFocus()
SetActiveLabel lblSid
End Sub


Private Sub CorrectName(TxtItem As TextBox)
Dim Text As String

With TxtItem
    Text = .Text
    If Text = UCase(Text) Then
        Text = UCase(Left(Text, 1)) & LCase(Mid(Text, 2))
    Else
        Text = UCase(Left(Text, 1)) & Mid(Text, 2)
    End If
    .Text = Text

    .SelStart = 0
    .SelLength = 32767
End With
End Sub


Private Sub txtSid_KeyDown(KeyCode As Integer, Shift As Integer)
StripHyphens txtSid
End Sub


Private Sub txtSid_KeyPress(KeyAscii As Integer)
If (KeyAscii < 48 Or KeyAscii > 57) And KeyAscii <> 8 Then KeyAscii = 0
End Sub

Private Function StripHyphens(Text As String)
Dim Pos

Pos = 1
Do Until Pos > Len(Text)
    If Mid(Text, Pos, 1) = "-" Then
        Text = Left(Text, Pos - 1) & Mid(Text, Pos + 1)
    Else
        Pos = Pos + 1
    End If
Loop

End Function


Public Sub ChangeCandidate()

If ChangeMade Then SaveCandidate
If NewCandidate < MaxCandidates Then
    CurCandidate = NewCandidate
    If CurCandidate < TotalCandidates Then
        LoadCandidate
    Else
        ClearCandidate
    End If
End If
ChangeCaption

End Sub


Public Sub LoadCandidate()
Dim Count

txtSid.Text = CandidateSids(CurCandidate)
txtFname.Text = CandidateFnames(CurCandidate)
txtLname.Text = CandidateLnames(CurCandidate)
If Len(CandidateMsgs(CurCandidate)) <= 0 Then
    txtMsg.Text = DefaultMsg
Else
    txtMsg.Text = CandidateMsgs(CurCandidate)
End If
picCandidate.Picture = CandidatePics(CurCandidate)
For Count = lstPositions.ListCount - 1 To 0 Step -1
    lstPositions.Selected(Count) = CandidatePositions(CurCandidate, Count)
Next

txtSid.SelLength = 32767
CorrectName txtFname
CorrectName txtLname

ChangeMade = False
End Sub


Public Sub SaveCandidate()
Dim Count

If CurCandidate >= TotalCandidates Then TotalCandidates = CurCandidate + 1
CandidateSids(CurCandidate) = Val(txtSid.Text)
CandidateFnames(CurCandidate) = txtFname.Text
CandidateLnames(CurCandidate) = txtLname.Text
If txtMsg.Text <> DefaultMsg Then
    CandidateMsgs(CurCandidate) = txtMsg.Text
Else
    CandidateMsgs(CurCandidate) = ""
End If
Set CandidatePics(CurCandidate) = picCandidate.Image
For Count = 0 To lstPositions.ListCount - 1
    CandidatePositions(CurCandidate, Count) = lstPositions.Selected(Count)
Next

CandidateChanged(CurCandidate) = True
ChangesMade = True
ChangeMade = False
End Sub


Public Sub ClearCandidate()
Dim Count

txtSid.Text = ""
txtFname.Text = ""
txtLname.Text = ""
txtMsg.Text = DefaultMsg
txtMsg.SelStart = 0
txtMsg.SelLength = 32767
picCandidate.Picture = Nothing
For Count = TotalPositions - 1 To 0 Step -1
    lstPositions.Selected(Count) = False
Next

ChangeMade = False
End Sub

Private Sub ChangeCaption()
Caption = "Candidate Editor - " & CurCandidate + 1 & "/" & TotalCandidates
End Sub

Private Sub txtSid_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
SetActiveControl txtSid
End Sub
