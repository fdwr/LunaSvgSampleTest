VERSION 5.00
Begin VB.Form frmClozeExercise 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Cloze Exercises"
   ClientHeight    =   5655
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   7695
   BeginProperty Font 
      Name            =   "MS Sans Serif"
      Size            =   8.25
      Charset         =   0
      Weight          =   700
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   Icon            =   "EslExercise.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   5655
   ScaleWidth      =   7695
   Begin VB.Frame fraMainMenu 
      Caption         =   "Main Menu"
      Height          =   5655
      Left            =   0
      TabIndex        =   5
      Top             =   0
      Width           =   7695
      Begin VB.CommandButton cmdOpen 
         Caption         =   "Open..."
         Height          =   495
         Left            =   5880
         TabIndex        =   10
         Top             =   1920
         Visible         =   0   'False
         Width           =   1455
      End
      Begin VB.CommandButton cmdExit 
         Cancel          =   -1  'True
         Caption         =   "E&xit"
         Height          =   495
         Left            =   5880
         TabIndex        =   8
         Top             =   1200
         Width           =   1455
      End
      Begin VB.ListBox lstExercise 
         BackColor       =   &H00C0F0C0&
         Height          =   3570
         Left            =   360
         TabIndex        =   6
         Top             =   480
         Width           =   5175
      End
      Begin VB.CommandButton cmdChoose 
         Caption         =   "Choose"
         Default         =   -1  'True
         Height          =   495
         Left            =   5880
         TabIndex        =   7
         Top             =   480
         Width           =   1455
      End
      Begin VB.Label lblAbout 
         Height          =   1095
         Left            =   360
         TabIndex        =   9
         Top             =   4440
         Width           =   5175
      End
   End
   Begin VB.Frame fraExercise 
      Height          =   5655
      Left            =   0
      TabIndex        =   1
      Top             =   0
      Visible         =   0   'False
      Width           =   7695
      Begin VB.CommandButton cmdHearWords 
         Caption         =   "&Listen to words"
         Height          =   495
         Left            =   5400
         TabIndex        =   2
         Top             =   4200
         Width           =   2055
      End
      Begin VB.CommandButton cmdMenu 
         Caption         =   "&Menu"
         Height          =   495
         Left            =   5400
         TabIndex        =   3
         Top             =   4920
         Width           =   2055
      End
      Begin VB.CommandButton cmdShowPicture 
         Caption         =   "See the &picture"
         Height          =   495
         Left            =   5400
         TabIndex        =   0
         Top             =   3600
         Width           =   2055
      End
      Begin VB.Timer tmrCard 
         Enabled         =   0   'False
         Interval        =   10
         Left            =   0
         Top             =   4800
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   0
         Left            =   240
         Top             =   3600
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   1
         Left            =   240
         Top             =   4080
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   2
         Left            =   240
         Top             =   4560
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   3
         Left            =   240
         Top             =   5040
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   4
         Left            =   1920
         Top             =   3600
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   5
         Left            =   1920
         Top             =   4080
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   6
         Left            =   1920
         Top             =   4560
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   7
         Left            =   1920
         Top             =   5040
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   8
         Left            =   3600
         Top             =   3600
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   9
         Left            =   3600
         Top             =   4080
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   10
         Left            =   3600
         Top             =   4560
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin prjEslCloze.ctlWordCard ctlWordCard 
         Height          =   375
         Index           =   11
         Left            =   3600
         Top             =   5040
         Width           =   1575
         _ExtentX        =   2778
         _ExtentY        =   873
      End
      Begin VB.Label lblExercise 
         BackColor       =   &H00C0F0C0&
         BorderStyle     =   1  'Fixed Single
         BeginProperty Font 
            Name            =   "Arial"
            Size            =   12
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   3015
         Left            =   240
         TabIndex        =   4
         Top             =   360
         Width           =   7215
      End
      Begin VB.Image imgExercise 
         BorderStyle     =   1  'Fixed Single
         Height          =   3015
         Left            =   240
         Top             =   360
         Width           =   7215
      End
   End
End
Attribute VB_Name = "frmClozeExercise"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

'load cloze exercises file
'present intro
'do exercise
'  read cloze exercise
'  parse words and count total clozes
'  reformat exercise text
'  randomize cards
'  wait for all cards to be placed
'display score
'goto next exercise or return to intro

Private Declare Function PlaySound Lib "winmm.dll" Alias "PlaySoundA" (ByVal lpszName As String, ByVal hModule As Long, ByVal dwFlags As Long) As Long

Const SND_ASYNC = &H1   'Play the sound asynchronously -- return immediately after beginning to play the sound and have it play in the background.
Const SND_FILENAME = &H20000
Const SND_NODEFAULT = &H2

Const MaxClozeWords = 12
Const MaxClozeExercises = 50
Const DefaultTries = 3
Const CardFloatSteps = 10

Private Type ClozeWordType
Top As Integer
Btm As Integer
Left As Integer
Right As Integer
CharPos As Integer
CharLen As Integer
Active As Boolean
Try As Integer
End Type

Public AppPath As String

Private ClozeWords(MaxClozeWords - 1) As ClozeWordType
Public ClozeWordsLeft As Integer
Public TotalExercises As Integer
Public ExerciseFilename As String
Dim LoadedExercises(MaxClozeExercises - 1, 4) As String
Dim ExerciseListPtrs(MaxClozeExercises - 1) As Integer
Public ExerciseText As String
Public ExercisePicture As String
Public CurrentExercise As Integer

Public WordCardBdrLeft As Integer, WordCardBdrRight As Integer
Public WordCardBdrTop As Integer, WordCardBdrBtm As Integer
Public WordCardCenterRow As Integer, WordCardCenterCol As Integer
Public ErrorHandled As Boolean

Private CardFloatCount As Integer, CardFloatIndex As Integer
Private CardRow As Integer, CardRowRange As Integer
Private CardCol As Integer, CardColRange As Integer

Private Sub cmdChoose_Click()
    If lstExercise.ListIndex > -1 Then
        SelectExercise ExerciseListPtrs(lstExercise.ListIndex)
        cmdMenu.Cancel = True
        fraExercise.Visible = True
        fraMainMenu.Visible = False
        FormatExercise
    End If
End Sub

Private Sub cmdHearWords_Click()
    PlaySound GetCompleteFilename(LoadedExercises(CurrentExercise, 3)), 0, SND_ASYNC Or SND_NODEFAULT Or SND_FILENAME
End Sub

Private Sub cmdMenu_Click()
    ActivateMenu
End Sub

Private Sub Form_Load()
    'frmDebug.Show
    Randomize Timer
    AppPath = App.Path
    If Right(AppPath, 1) <> "\" Then AppPath = AppPath & "\"
    ExerciseFilename = AppPath & "exercise.txt"

    LoadExercises
    If lstExercise.ListCount > 0 Then lstExercise.ListIndex = 0
    lblAbout.Caption = "ESL Cloze Exercises" & vbCr & "Original program by Gary B. Roelofs" & vbCr & "Rewritten by Dwayne Robinson using VB6" & vbCr & "for Chemeketa Community College 2000.6.20"
    'SelectExercise 0
    'frmDebug.SetMessage ExerciseText, "frmClozeExercise:FormLoad"
    'FormatExercise
    'frmDebug.SetMessage lblExercise.Caption, "frmClozeExercise:FormLoad"
    'ResetCardBounds
    'ctlWordCard(1).cardValue = 17
End Sub

Private Sub cmdExit_Click()
    Unload frmClozeExercise
End Sub

Private Sub cmdShowPicture_Click()
    Dim Count As Integer, PictureShown As Boolean

    PictureShown = imgExercise.Visible
    For Count = 0 To TotalClozeWords
        ctlWordCard(Count).Enabled = PictureShown
    Next Count
    lblExercise.Visible = PictureShown
    PictureShown = PictureShown Xor True
    imgExercise.Visible = PictureShown
    cmdShowPicture.Caption = IIf(PictureShown, "See the e&xercise", "See the &picture")
End Sub

Private Sub ctlWordCard_WordCardDrag(Index As Integer, RowAdjust As Integer, ColAdjust As Integer)
    Dim Row As Integer, Col As Integer, Cloze As Integer

    Row = ctlWordCard(Index).Top + RowAdjust
    Col = ctlWordCard(Index).Left + ColAdjust
    ctlWordCard(Index).Move Col, Row
    'ctlWordCard(Index).Top = Row
    'ctlWordCard(Index).Left = Col
    Row = Row + WordCardCenterRow
    Col = Col + WordCardCenterCol
    'frmDebug.SetMessage "card moved to " & Row & ":" & Col, "frmClozeExercise:WordCardDrag"
    If Col < WordCardBdrLeft _
    Or Col > WordCardBdrRight _
    Or Row < WordCardBdrTop _
    Or Row > WordCardBdrBtm Then
        'frmDebug.SetMessage "card moved to " & Row & ":" & Col & " bordering " & WordCardBdrTop & ":" & WordCardBdrBtm & " x " & WordCardBdrLeft & ":" & WordCardBdrRight
        Cloze = NearestClose(Row, Col)
        ctlWordCard(Index).SetHighlight Cloze
    End If
    'if border crossing
    '  if over cloze
    '    then make card invisible and show word in text
    '    else make card visible and do not show word
End Sub

Private Sub ctlWordCard_WordCardDrop(Index As Integer, RowAdjust As Integer, ColAdjust As Integer, NewHeight As Integer, NewWidth As Integer)
    Dim Cloze As Integer, CardIndex As Integer, Response As Integer
    'if dropped over cloze
    '  if correct cloze
    '    make cloze invisible
    '    decrease remaining clozes
    '    if no more clozes then end game and show score
    '  else incorrect
    '    return cloze back to starting position
    '    count one more missed try
    'else return card to starting position
    Cloze = NearestClose(ctlWordCard(Index).Top + WordCardCenterRow, ctlWordCard(Index).Left + WordCardCenterCol)
    CardIndex = ctlWordCard(Index).CardValue

    ctlWordCard(Index).SetHighlight -1
    If Cloze = CardIndex Then
        ctlWordCard(Index).Visible = False
        'ctlWordCard(Index).Move ctlWordCard(Index).Top + RowAdjust, ctlWordCard(Index).Left + ColAdjust, NewWidth, NewHeight
        ClozeWords(CardIndex).Active = False
        Call FormatExercise
        DoEvents
        ClozeWordsLeft = ClozeWordsLeft - 1
        TotalMatches = TotalMatches + 1
    ElseIf Cloze >= 0 Then
        TotalAttempts = TotalAttempts + 1
        ClozeWords(CardIndex).Try = ClozeWords(CardIndex).Try - 1
        If ClozeWords(CardIndex).Try <= 0 Then
            ClozeWords(CardIndex).Active = False
            Call FloatCard(Index)
            ctlWordCard(Index).Height = NewHeight
            ctlWordCard(Index).Width = NewWidth
            ClozeWordsLeft = ClozeWordsLeft - 1
            TotalMisses = TotalMisses + 1
        Else
            ctlWordCard(Index).Move (Index \ 4) * 1680 + 240, (Index And 3) * 480 + 3600, NewWidth, NewHeight
        End If
    Else
        ctlWordCard(Index).Move (Index \ 4) * 1680 + 240, (Index And 3) * 480 + 3600, NewWidth, NewHeight
    End If
    If ClozeWordsLeft <= 0 Then
        Response = frmScore.GetResponse
        If Response = 2 Then
            ActivateMenu
        ElseIf Response = 1 Then
            RestartExercise
            Call FormatExercise
        Else
            If CurrentExercise + 1 >= TotalExercises Then
                ActivateMenu
            ElseIf LoadedExercises(CurrentExercise + 1, 0) <> "" Then
                ActivateMenu
            Else
                SelectExercise CurrentExercise + 1
                Call FormatExercise
            End If
        End If
    End If
End Sub

Private Sub ctlWordCard_WordCardGrab(Index As Integer, RowAdjust As Integer, ColAdjust As Integer, NewHeight As Integer, NewWidth As Integer)
    ctlWordCard(Index).ZOrder 0
    ctlWordCard(Index).Move ctlWordCard(Index).Left + ColAdjust, ctlWordCard(Index).Top + RowAdjust, NewWidth, NewHeight
    WordCardCenterRow = NewHeight \ 2
    WordCardCenterCol = NewWidth \ 2
End Sub

Private Sub Form_Unload(Cancel As Integer)
    End
End Sub

Public Sub LoadExercises()
    Dim CharPos As Integer, StartPos As Integer, EndPos As Integer
    Dim CurExercise As Integer
    Dim ExercisesText As String, AttributeName As String, AttributeData As String
    Dim ErrDesc As String

    ErrorHandled = False
    On Error GoTo ExerciseLoadError
    Open ExerciseFilename For Input As 1
    If ErrorHandled Then
        MsgBox "Could not load exercise file " & ExerciseFilename & vbCrLf & ErrDesc
    Else
        ExercisesText = Input$(LOF(1), 1)
        On Error GoTo 0
        Close 1
        lstExercise.Clear
        CharPos = 1
        CurExercise = 0
        Do Until CharPos >= Len(ExercisesText)
            Do Until Asc(Mid(ExercisesText, CharPos, 1)) > 32 Or CharPos >= Len(ExercisesText)
                CharPos = CharPos + 1
            Loop
            
            EndPos = InStr(CharPos, ExercisesText, " ")
            If EndPos < 2 Then Exit Do
            AttributeName = Mid(ExercisesText, CharPos, EndPos - CharPos)
            StartPos = InStr(EndPos, ExercisesText, "{") + 1
            If StartPos < 3 Then Exit Do
            EndPos = InStr(StartPos, ExercisesText, "}")
            If EndPos < 4 Then Exit Do
            AttributeData = Mid(ExercisesText, StartPos, EndPos - StartPos)
            CharPos = EndPos + 1

            Select Case AttributeName
            Case "Name": LoadedExercises(CurExercise, 0) = AttributeData
            Case "Title": LoadedExercises(CurExercise, 1) = AttributeData
            Case "Image": LoadedExercises(CurExercise, 2) = AttributeData
            Case "Sound": LoadedExercises(CurExercise, 3) = AttributeData
            Case "Text"
                If Len(LoadedExercises(CurExercise, 1)) > 0 Then
                    ExerciseListPtrs(lstExercise.ListCount) = CurExercise
                    lstExercise.AddItem LoadedExercises(CurExercise, 1)
                End If
                LoadedExercises(CurExercise, 4) = AttributeData
                CurExercise = CurExercise + 1
                If CurExercise >= MaxClozeExercises Then Exit Do
            End Select
        Loop
        TotalExercises = CurExercise
        CurrentExercise = 0
    End If
    Exit Sub

ExerciseLoadError:
    ErrorHandled = Err.Number
    ErrDesc = Err.Description
    Resume Next
End Sub

'finds each cloze and sets it to a word card
'any word cards not used are set invisible
'loads picture
'sets buttons enabled/disabled according to whether items exist
Public Sub SelectExercise(SelectedExercise As Integer)
    Dim CharPos As Integer, NextPos As Integer, CharLen As Integer
    Dim imgSize As Integer

    CurrentExercise = SelectedExercise
    ExerciseText = LoadedExercises(CurrentExercise, 4)

    CharPos = 1
    TotalClozeWords = 0
    Do
        CharPos = InStr(CharPos, ExerciseText, "[") + 1
        If CharPos > 1 Then
            ClozeWords(TotalClozeWords).CharPos = CharPos
            NextPos = InStr(CharPos, ExerciseText, "]")
            CharLen = NextPos - CharPos
            If CharLen < 0 Then
                CharLen = Len(ExerciseText) - CharPos + 1
            End If
            ClozeWords(TotalClozeWords).CharLen = CharLen
            ClozeWords(TotalClozeWords).Active = True
            CharPos = NextPos
            TotalClozeWords = TotalClozeWords + 1
        End If
    Loop While TotalClozeWords < MaxClozeWords And CharPos > 1

    If Len(LoadedExercises(CurrentExercise, 1)) Then
        fraExercise.Caption = LoadedExercises(CurrentExercise, 1)
    End If
    If Len(LoadedExercises(CurrentExercise, 2)) Then
        If LoadedExercises(CurrentExercise, 2) <> ExercisePicture Then
            On Error GoTo PicLoadError
            imgExercise.Picture = LoadPicture(GetCompleteFilename(LoadedExercises(CurrentExercise, 2)))
            On Error GoTo 0
            imgSize = lblExercise.Height
            If imgExercise.Height > imgSize Then
                imgExercise.Top = lblExercise.Top
                imgExercise.Height = imgSize
            Else
                imgExercise.Top = lblExercise.Top + (imgSize - imgExercise.Height) \ 2
            End If
            imgSize = lblExercise.Width
            If imgExercise.Width > imgSize Then
                imgExercise.Left = lblExercise.Left
                imgExercise.Width = imgSize
            Else
                imgExercise.Left = lblExercise.Left + (imgSize - imgExercise.Width) \ 2
            End If
            ExercisePicture = LoadedExercises(CurrentExercise, 2)
        End If
        cmdShowPicture.Enabled = True
    Else
        cmdShowPicture.Enabled = False
    End If
    If Len(LoadedExercises(CurrentExercise, 3)) Then
        cmdHearWords.Enabled = True
    Else
        cmdHearWords.Enabled = False
    End If
    lblExercise.Visible = True
    imgExercise.Visible = False

    Call RestartExercise
    
    Exit Sub

PicLoadError:
    MsgBox "Could not load exercise picture:" & vbCr & LoadedExercises(CurrentExercise, 2), vbExclamation
    Resume Next
End Sub

'dynamically adjusts the row/col locations of each cloze
Public Sub FormatExercise()
    Dim TextWord As String, CurCloze As Integer, FoundCloze As Boolean
    Dim CharPos As Integer, Char As String * 1
    Dim Row As Integer, Col As Integer, NewCol As Integer
    Dim TextLen As Integer, TextHeight As Integer, LabelWidth As Integer, WordWidth As Integer

    'stupid hack here...
    'TextWidth method can be applied to forms, but not labels!?
    Set frmClozeExercise.Font = lblExercise.Font
    '...end stupid hack
    lblExercise.Caption = ""
    LabelWidth = lblExercise.Width
    TextHeight = frmClozeExercise.TextHeight("A")
    TextLen = Len(ExerciseText)
    Row = lblExercise.Top
    CharPos = 1
    Do Until CharPos > TextLen
        Char = Mid(ExerciseText, CharPos, 1)
        If Char = "[" Then
            If ClozeWords(CurCloze).Active Then
                ClozeWords(CurCloze).Left = TextWidth(TextWord)
                TextWord = TextWord & "_____"
                CharPos = InStr(CharPos, ExerciseText, "]")
                If CharPos <= 1 Then CharPos = TextLen
                FoundCloze = True
            Else
                If CurCloze < MaxClozeWords - 1 Then CurCloze = CurCloze + 1
            End If
        ElseIf Char = "]" Then
            'do nothing, simply ignore bracket
        ElseIf Char = vbCr Then
            TextWord = TextWord & vbCrLf
            GoSub CheckWordWrap
            TextWord = ""
            Row = Row + TextHeight
            Col = 0
            CharPos = CharPos + 1
        ElseIf Char = " " Then
            TextWord = TextWord & Char
            GoSub CheckWordWrap
        Else
            TextWord = TextWord & Char
        End If
        CharPos = CharPos + 1
    Loop
    GoSub CheckWordWrap
    Exit Sub

CheckWordWrap:
    WordWidth = TextWidth(TextWord)
    NewCol = Col + WordWidth
    If NewCol >= LabelWidth Then
        lblExercise.Caption = RTrim(lblExercise.Caption) & vbCrLf & TextWord
        Row = Row + TextHeight
        NewCol = WordWidth
        Col = 0
    Else
        lblExercise.Caption = lblExercise.Caption & TextWord
    End If
    If FoundCloze Then
        ClozeWords(CurCloze).Top = Row
        ClozeWords(CurCloze).Left = ClozeWords(CurCloze).Left + Col + lblExercise.Left
        ClozeWords(CurCloze).Btm = Row + TextHeight
        ClozeWords(CurCloze).Right = ClozeWords(CurCloze).Left + TextWidth("_____")
        FoundCloze = False
        If CurCloze < MaxClozeWords - 1 Then CurCloze = CurCloze + 1
    End If
    Col = NewCol
    TextWord = ""
Return

End Sub

Private Sub ResetCardBounds()
    WordCardBdrLeft = 32000
    WordCardBdrRight = 0
    WordCardBdrTop = 32000
    WordCardBdrBtm = 0
End Sub

Private Function NearestClose(Row As Integer, Col As Integer)
    Dim Count As Integer
    Static Color As Long

    WordCardBdrLeft = 0
    WordCardBdrRight = 32000
    WordCardBdrTop = 0
    WordCardBdrBtm = 32000
    'Line (0, 0)-(10000, 10000), &HFFFFFF, BF
    For Count = 0 To TotalClozeWords - 1
        If ClozeWords(Count).Active Then
            If Row < ClozeWords(Count).Top Then
                If ClozeWords(Count).Top < WordCardBdrBtm Then WordCardBdrBtm = ClozeWords(Count).Top
            ElseIf Row > ClozeWords(Count).Btm Then
                If ClozeWords(Count).Btm > WordCardBdrTop Then WordCardBdrTop = ClozeWords(Count).Btm
            End If
            If Col < ClozeWords(Count).Left Then
                If ClozeWords(Count).Left < WordCardBdrRight Then WordCardBdrRight = ClozeWords(Count).Left
            ElseIf Col > ClozeWords(Count).Right Then
                If ClozeWords(Count).Right > WordCardBdrLeft Then WordCardBdrLeft = ClozeWords(Count).Right
            End If
            If Row < ClozeWords(Count).Btm And Row > ClozeWords(Count).Top _
            And Col < ClozeWords(Count).Right And Col > ClozeWords(Count).Left Then
                WordCardBdrTop = ClozeWords(Count).Top
                WordCardBdrBtm = ClozeWords(Count).Btm
                WordCardBdrLeft = ClozeWords(Count).Left
                WordCardBdrRight = ClozeWords(Count).Right
                'Line (WordCardBdrLeft, WordCardBdrTop)-(WordCardBdrRight, WordCardBdrBtm), Color, BF
                'Color = (Color + &H373536) And &HFFFFFF
                Exit For
            End If
            'Line (WordCardBdrLeft, WordCardBdrTop)-(WordCardBdrRight, WordCardBdrBtm), Color, B
            'Color = (Color + &H373536) And &HFFFFFF
        End If
    Next Count
    If Count >= TotalClozeWords Then Count = -1
    NearestClose = Count
End Function

Private Sub lstExercise_DblClick()
    Call cmdChoose_Click
End Sub

Private Sub tmrCard_Timer()
    If CardFloatCount < 0 Then
        tmrCard.Enabled = False
        Call FormatExercise
        ctlWordCard(CardFloatIndex).Visible = False
    Else
        ctlWordCard(CardFloatIndex).Move CardCol - (CardColRange * CLng(CardFloatCount) \ CardFloatSteps), _
                                         CardRow - (CardRowRange * CLng(CardFloatCount) \ CardFloatSteps)
        CardFloatCount = CardFloatCount - 1
    End If
    
End Sub

Private Sub FloatCard(Index As Integer)
    Dim CardIndex As Integer
    CardIndex = ctlWordCard(Index).CardValue
    CardRow = ClozeWords(CardIndex).Top
    CardCol = ClozeWords(CardIndex).Left
    CardRowRange = CardRow - ctlWordCard(Index).Top
    CardColRange = CardCol - ctlWordCard(Index).Left
    CardFloatCount = CardFloatSteps
    CardFloatIndex = Index
    tmrCard.Enabled = True
End Sub

Private Sub RestartExercise()
    Dim RandomArray(0 To MaxClozeWords - 1) As Integer, NewIndex As Integer
    Dim Count As Integer, RndPick As Integer

    'randomize word cards
    For Count = 0 To TotalClozeWords - 1
        RandomArray(Count) = Count
    Next Count
    For Count = TotalClozeWords - 1 To 0 Step -1
        NewIndex = Int(Rnd * Count)
        RndPick = RandomArray(NewIndex)
        RandomArray(NewIndex) = RandomArray(Count)
        'RandomArray(Count) = RndPick
        ctlWordCard(Count).Visible = True
        ctlWordCard(Count).SetWord Mid(ExerciseText, ClozeWords(RndPick).CharPos, ClozeWords(RndPick).CharLen)
        ctlWordCard(Count).CardValue = RndPick
        ctlWordCard(Count).Move (Count \ 4) * 1680 + 240, (Count And 3) * 480 + 3600
        ctlWordCard(Count).Enabled = True
        Call ctlWordCard(Count).ExpandCard
        ClozeWords(RndPick).Try = DefaultTries
        ClozeWords(RndPick).Active = True
    Next Count
    For Count = TotalClozeWords To MaxClozeWords - 1
        ctlWordCard(Count).Visible = False
        ClozeWords(Count).Active = False
    Next Count

    'reset scores
    ClozeWordsLeft = TotalClozeWords
    TotalMatches = 0
    TotalMisses = 0
    TotalAttempts = 0
End Sub

Private Sub ActivateMenu()
    cmdExit.Cancel = True
    fraExercise.Visible = False
    fraMainMenu.Visible = True
End Sub

Private Function GetCompleteFilename(FileName As String)
        If InStr(FileName, ":") > 0 Then
            GetCompleteFilename = FileName
        Else
            GetCompleteFilename = AppPath & FileName
        End If

End Function
