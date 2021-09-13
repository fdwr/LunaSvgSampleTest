VERSION 5.00
Begin VB.Form frmSignIn 
   AutoRedraw      =   -1  'True
   BorderStyle     =   0  'None
   Caption         =   "Open Lab Sign-In"
   ClientHeight    =   8460
   ClientLeft      =   0
   ClientTop       =   75
   ClientWidth     =   12000
   BeginProperty Font 
      Name            =   "MS Sans Serif"
      Size            =   18
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   Icon            =   "SignIn.frx":0000
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   564
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   800
   ShowInTaskbar   =   0   'False
   WindowState     =   2  'Maximized
   Begin prjSignInTr.msgWindow msgWindow 
      Height          =   255
      Left            =   0
      Top             =   9000
      Visible         =   0   'False
      Width           =   495
      _extentx        =   873
      _extenty        =   450
   End
   Begin VB.CommandButton cmdSignInOut 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Sign In/Out"
      Height          =   615
      Left            =   4920
      Style           =   1  'Graphical
      TabIndex        =   10
      Top             =   7920
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.TextBox txtStudentId 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      IMEMode         =   3  'DISABLE
      Left            =   6000
      MaxLength       =   9
      PasswordChar    =   "*"
      TabIndex        =   31
      Top             =   5640
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.TextBox txtMiddleName 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      Left            =   7800
      TabIndex        =   6
      Top             =   5400
      Visible         =   0   'False
      Width           =   3015
   End
   Begin VB.TextBox txtFirstName 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      Left            =   7800
      TabIndex        =   4
      Top             =   4680
      Visible         =   0   'False
      Width           =   3015
   End
   Begin VB.DriveListBox drvBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   720
      TabIndex        =   34
      Top             =   2880
      Visible         =   0   'False
      Width           =   4935
   End
   Begin VB.TextBox txtStudentIdLocked 
      BackColor       =   &H00E0F0F8&
      Enabled         =   0   'False
      Height          =   495
      IMEMode         =   3  'DISABLE
      Left            =   3000
      MaxLength       =   9
      PasswordChar    =   "*"
      TabIndex        =   25
      Text            =   "123456789"
      Top             =   4680
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.TextBox txtDbFilename 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      Left            =   2640
      TabIndex        =   32
      Top             =   3480
      Visible         =   0   'False
      Width           =   8655
   End
   Begin VB.TextBox txtDate 
      BackColor       =   &H00E0F0F8&
      Enabled         =   0   'False
      Height          =   495
      Left            =   3000
      TabIndex        =   27
      Text            =   "[date]"
      Top             =   5400
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Timer tmrContinue 
      Interval        =   22000
      Left            =   3480
      Top             =   8160
   End
   Begin VB.TextBox txtLastName 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      Left            =   7800
      TabIndex        =   8
      Top             =   6120
      Visible         =   0   'False
      Width           =   3015
   End
   Begin VB.TextBox txtPage 
      Height          =   555
      Left            =   0
      TabIndex        =   9
      Top             =   8280
      Visible         =   0   'False
      Width           =   495
   End
   Begin VB.CommandButton cmdContinue 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Finish"
      Height          =   615
      Left            =   7920
      Style           =   1  'Graphical
      TabIndex        =   11
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdBack 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Back"
      Height          =   615
      Left            =   6120
      Style           =   1  'Graphical
      TabIndex        =   17
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.ListBox lstActions 
      BackColor       =   &H00E0F0F8&
      Height          =   3105
      ItemData        =   "SignIn.frx":0442
      Left            =   3960
      List            =   "SignIn.frx":045B
      TabIndex        =   30
      Top             =   3480
      Visible         =   0   'False
      Width           =   3615
   End
   Begin VB.ListBox lstPids 
      BackColor       =   &H00E0F0F8&
      Columns         =   2
      Height          =   3540
      ItemData        =   "SignIn.frx":04C9
      Left            =   720
      List            =   "SignIn.frx":04D6
      TabIndex        =   13
      Top             =   3720
      Visible         =   0   'False
      Width           =   10695
   End
   Begin VB.DirListBox dirBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   3810
      Left            =   720
      TabIndex        =   33
      Top             =   3480
      Visible         =   0   'False
      Width           =   4935
   End
   Begin VB.FileListBox filBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   4440
      Left            =   5880
      Pattern         =   "*.jpg;*.bmp"
      TabIndex        =   35
      Top             =   2880
      Visible         =   0   'False
      Width           =   5535
   End
   Begin VB.CommandButton cmdSignIn 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Sign In"
      Height          =   615
      Left            =   4200
      Style           =   1  'Graphical
      TabIndex        =   16
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdSubmit 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Submit"
      Height          =   615
      Left            =   4200
      Style           =   1  'Graphical
      TabIndex        =   15
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdUpdate 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Update"
      Height          =   615
      Left            =   4200
      Style           =   1  'Graphical
      TabIndex        =   21
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdSetDbFile 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Set File"
      Height          =   615
      Left            =   4200
      Style           =   1  'Graphical
      TabIndex        =   29
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdDeleteRecords 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Delete"
      Height          =   615
      Left            =   4200
      Style           =   1  'Graphical
      TabIndex        =   12
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdChangeBg 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Change"
      Height          =   615
      Left            =   4200
      Style           =   1  'Graphical
      TabIndex        =   14
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.Image imgMyMascot 
      Height          =   2895
      Left            =   600
      Picture         =   "SignIn.frx":051B
      Top             =   9000
      Visible         =   0   'False
      Width           =   1470
   End
   Begin VB.Image Image1 
      Height          =   1215
      Left            =   360
      Picture         =   "SignIn.frx":34C3
      Top             =   360
      Width           =   1215
   End
   Begin VB.Label Label14 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Filename:"
      Height          =   495
      Left            =   600
      TabIndex        =   28
      Top             =   3480
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label Label8 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Today's Date"
      Height          =   495
      Left            =   720
      TabIndex        =   26
      Top             =   5400
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.Label Label5 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Student ID"
      Height          =   495
      Left            =   3960
      TabIndex        =   2
      Top             =   5640
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label Label6 
      BackStyle       =   0  'Transparent
      Caption         =   "(usually your social security number)"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   9.75
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   255
      Left            =   4200
      TabIndex        =   22
      Top             =   6240
      Visible         =   0   'False
      Width           =   3855
   End
   Begin VB.Label Label12 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Last Name"
      Height          =   495
      Left            =   5400
      TabIndex        =   7
      Top             =   6120
      Visible         =   0   'False
      Width           =   2295
   End
   Begin VB.Label Label11 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Middle Initial"
      Height          =   495
      Left            =   5400
      TabIndex        =   5
      Top             =   5400
      Visible         =   0   'False
      Width           =   2295
   End
   Begin VB.Label Label10 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "First Name"
      Height          =   495
      Left            =   5400
      TabIndex        =   3
      Top             =   4680
      Visible         =   0   'False
      Width           =   2295
   End
   Begin VB.Label Label9 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Student Id"
      Height          =   495
      Left            =   720
      TabIndex        =   24
      Top             =   4680
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.Label lblInstructions 
      BackStyle       =   0  'Transparent
      Caption         =   "Initializing, loading background, opening database..."
      Height          =   2655
      Left            =   600
      TabIndex        =   1
      Top             =   2400
      Width           =   10935
   End
   Begin VB.Label lblAbout 
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "Small Fonts"
         Size            =   6
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FF6060&
      Height          =   150
      Left            =   0
      TabIndex        =   20
      Top             =   8880
      Width           =   345
   End
   Begin VB.Label Label2 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Community College"
      BeginProperty Font 
         Name            =   "Mistral"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFD8C0&
      Height          =   495
      Left            =   3600
      TabIndex        =   19
      Top             =   1320
      Width           =   3375
   End
   Begin VB.Label Label4 
      BackStyle       =   0  'Transparent
      BorderStyle     =   1  'Fixed Single
      Height          =   5295
      Left            =   480
      TabIndex        =   23
      Top             =   2280
      Width           =   11175
   End
   Begin prjSignInTr.DimmedBg ctlDimmed 
      Height          =   5295
      Left            =   480
      Top             =   2280
      Width           =   11175
      _extentx        =   1085
      _extenty        =   1296
   End
   Begin prjSignInTr.DimmedBg ctlAbout 
      Height          =   150
      Left            =   0
      Top             =   8880
      Visible         =   0   'False
      Width           =   345
      _extentx        =   873
      _extenty        =   450
   End
   Begin VB.Label Label7 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "Chemeketa Tutoring"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   54
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0D0&
      Height          =   1215
      Left            =   840
      TabIndex        =   0
      Top             =   240
      Width           =   11655
   End
   Begin VB.Label Label1 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "Chemeketa Tutoring"
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   56.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00404040&
      Height          =   1215
      Left            =   840
      TabIndex        =   18
      Top             =   120
      Width           =   11655
   End
   Begin VB.Image imgRegForm 
      Height          =   3495
      Left            =   2160
      Picture         =   "SignIn.frx":4005
      Top             =   9000
      Visible         =   0   'False
      Width           =   5955
   End
End
Attribute VB_Name = "frmSignIn"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'By Peekin, 2000-01-29:2001-03-12
'Chemeketa Open Lab Sign In
'
'2001-01-29 4 1/2 hours ;)
'2001-01-30 4
'...and here I lose track of time...
'2001-03-01  4
'2001-03-02  1
'2001-03-07  3
'
'Something to look into:
'It might be simpler to scan your student ID card than type in numbers.
'A small free device call CueCat from Radio Shack could be the solution.
'http://www.radioshack.com/Partners/CAT/FAQ/RSCATFAQGateway.asp
Option Explicit

'Private Declare Function BitBlt Lib "GDI32" (ByVal hDestDC As Long, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal dwRop As Long) As Long
'Private Declare Function SendMessage Lib "USER32" Alias "SendMessageA" (ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Long) As Long
'Const CB_SHOWDROPDOWN = &H14F

Const MaxPids = 200

Dim MessageShown As Boolean, CurrentPage As Long
Dim TotalStudentNumbers As Long
Dim Value As Long, Counter As Long 'two generic variables that are reused several times throughout
Dim DbIsOpen As Boolean
Dim StudentName As String, StudentLastUse As Date, StudentMsg As String
Dim StudentId As Long, StudentStatus As Byte, StudentPid As Long
Dim StudentPids(MaxPids - 1) As Boolean
Dim SqlUpdateStatement As String
Dim DbFilename As String
Dim DbErrMsg As String
Dim BgFilename As String
Dim MsgDisplayTime As Long
Dim EditingSid As Boolean
Dim Pids(MaxPids - 1) As String

Const CurPageMenu = 0
Const CurPageSignIn = 1
Const CurPageSubmit = 2
Const CurPageGetPid = 3
'Const CurPageSignedIn = 4
Const CurPageEditInfo = 5
Const CurPageDelRecords = 6
Const CurPageSetDbFile = 7
Const CurPageReSubmit = 8
Const CurPageChgBkg = 9

Const SignStatusOut = 0
Const SignStatusIn = 1
Const SignStatusForgot = 2
Const SignStatusNewTerm = 3
Const SignStatusNewStudent = 4

Const DbFilenameDef = "StudentLogTr.mdb"
Const BgFilenameDef As String = "Parlokia.jpg" 'default background image

Const AverageDuration = 0.04167 'average duration for students using lab, 1/24 or one hour

Const ErrMsgDuration As Long = 22000    'clear error message after 22 seconds
Const SuccessMsgDuration As Long = 9000 'clear successful sign in message after
'Const MinMsgDuration As Long = 2000  'ensure students read message!

Const DimmedColor = &HB0B0B0

Private Sub dirBgs_Change()
    On Error Resume Next
    filBgs.Path = dirBgs.Path
    drvBgs.Drive = dirBgs.Path
End Sub

Private Sub drvBgs_Change()
    On Error Resume Next
    dirBgs.Path = drvBgs.Drive
End Sub

Private Sub Form_KeyPress(KeyAscii As Integer)
    If MessageShown Then ClrErrorMsg
End Sub

Private Sub Form_Load()
    Dim Page As Long, CurDate As String

    Show        'let people know what's happening so that the delay
    DoEvents    'does not seem so long and mysterious

    lstActions.ListIndex = 0
    CurDate = Date$
    txtDate.Text = Mid(CurDate, 7, 4) & "-" & Mid(CurDate, 1, 2) & "-" & Mid(CurDate, 4, 2)

    drvBgs.Drive = AppPath
    dirBgs.Path = AppPath
    filBgs.Path = AppPath
    GetSetting "StudentSignIn", "Startup", "Bg", BgFilename
    If Len(BgFilename) <= 0 Then BgFilename = AppPath & BgFilenameDef
    Picture = LoadPicture(BgFilename)
    ctlDimmed.DimThis frmSignIn.hdc, ctlDimmed, DimmedColor

    'read in PIDs
    DbFilename = AppPath & DbFilenameDef
    OpenDbTable "tblPids"
    If Not DbIsOpen Then
        ChangePage CurPageSetDbFile
        SetErrorMsg "Error opening database! (need tblPids)" & vbNewLine & DbErrMsg, cmdSetDbFile
    Else
        Do Until DbTbl.EOF
            Value = DbTbl("PID")
            If Value < MaxPids Then Pids(Value) = DbTbl("Name")
            DbTbl.MoveNext
        Loop
        'BuildPidList
        ChangePage Page
    End If
    CorrectKeyStates

End Sub

Private Sub cmdSignInOut_Click()
'check if student number exists
'if student does not exist
'  request information
'elseif student status = new term
'  verify information
'elseif signed in
'   sign out
'elseif forgot
'  display message
'  set status to signed out
'else signed out
'  get course
'endif
    If MessageShown Then msgWindow_CloseMe: Exit Sub

    txtStudentId.SetFocus
    If Len(txtStudentId.Text) < 9 Then
        SetErrorMsg "Your student ID is the nine digit number on the back of your card (usually the same as your social security number)", txtStudentId
        HighlightTextPrompt txtStudentId
        Exit Sub
    End If

    SetSuccessMsg "Checking status...", cmdSignInOut
    DoEvents
    OpenDbTable "tblStudents"
    If Not DbIsOpen Then
        SetErrorMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, cmdSignInOut
        Exit Sub
    End If
    Set StudentTbl = DbTbl
    StudentId = Val(txtStudentId.Text)
    StudentTbl.Index = "PrimaryKey"
    StudentTbl.Seek "=", StudentId

    txtStudentIdLocked.Text = txtStudentId.Text
    txtStudentId.Text = ""
    ' signing in
    '   no students with that SID, must be new student so get info
    '   returning student
    '     new term, verify previous information
    '     same term
    '       still signed in
    '         time difference between sign in's was > default time
    '         otherwise time difference was < average
    '       remembered to sign out last time
    ' signing out
    '   no students with that SID, must have typed wrong number
    '     signed in properly
    '     forgot to sign in, so remind them too

    If Not StudentTbl.NoMatch Then
        StudentStatus = StudentTbl("Status")
        StudentName = StudentTbl("FirstName")
        StudentLastUse = StudentTbl("LastUse")
        StudentPid = StudentTbl("PID")
        StudentMsg = StudentTbl("Msg")
    End If
    
    If StudentTbl.NoMatch Then
        'MsgBox "new student"
        'no students with that SID, must be a new student
        txtFirstName.Text = ""
        txtLastName.Text = ""
        txtMiddleName.Text = ""
        'lstPids.ListIndex = 0

        ChangePage CurPageSubmit
        txtFirstName.SetFocus
    ElseIf StudentStatus = SignStatusNewTerm Then 'returning student
        'MsgBox "new term, signing in"
        'new term, so verify previous information
        GetStudentInformation
        ChangePage CurPageReSubmit
        txtFirstName.SetFocus
    ElseIf StudentStatus = SignStatusIn Then 'currently signed in
        'MsgBox "signed in, signing out"
        SignSidOut
        SetSuccessMsg "You have been signed out " & StudentName, Nothing
        'It would be convenient to display a message to an individual
        'student if you needed to tell him/her that they left behind
        'their student ID card or perhaps a disk
    ElseIf StudentStatus = SignStatusForgot Then 'forgot to sign out
        'MsgBox "forgot to sign out"
        SetErrorMsg "Our records show that you didn't sign out the last time you visited the Tutoring Center, " & GetTimeDifMsg(Now - StudentLastUse) & ". Please remember to sign out when you are finished. Click sign in once more to continue.", cmdSignInOut
        With StudentTbl
            .Edit
            'StudentStatus = SignStatusOut
            .Fields("Status") = SignStatusOut
            .Update
        End With
        'restore SID
        txtStudentId.Text = txtStudentIdLocked.Text
    'ElseIf StudentStatus = SignStatusNewStudent Then
    Else 'If StudentStatus = SignStatusOut Then 'not signed in
        'MsgBox "signed out, signing in"
        BuildPidList
        ChangePage CurPageGetPid
    End If
End Sub

Private Sub cmdSignIn_Click()
    If lstPids.ListIndex < 0 Then
        SetErrorMsg "Please select your field of study from the list.", cmdSignIn
        lstPids.SetFocus
        Exit Sub
    End If

    StudentPid = lstPids.ItemData(lstPids.ListIndex)
    SignSidIn
    AddStudentPid

    ChangePage CurPageSignIn
    'If StudentStatus = SignStatusNewStudent Then
    If StudentPids(StudentPid) Then
        SetSuccessMsg "You have been signed in " & StudentName & ".", Nothing
    Else
        msgWindow.SuccessColor
        msgWindow.SetPicMsg "Since this is the first time you have signed in for this area this term, don't forget to fill in the paperwork.", imgRegForm.Picture, 2
        ShowMsg Nothing
    End If
End Sub

Private Sub cmdSignInOut_KeyPress(KeyAscii As Integer)
    txtStudentId.SetFocus
    txtStudentId_KeyPress KeyAscii
End Sub

Private Sub cmdSubmit_Click()
    Dim Text As String

    'check for valid information
    txtStudentIdLocked.Text = Trim(txtStudentIdLocked.Text)
    CorrectName txtLastName
    CorrectName txtMiddleName
    CorrectName txtFirstName
    If Len(txtStudentIdLocked.Text) < 9 Then
        SetErrorMsg "Your student ID is the nine digit number on the back of your card (usually the same as your social security number)", txtStudentIdLocked
        txtStudentIdLocked.SetFocus
        Exit Sub
    End If
    If Len(txtFirstName.Text) <= 0 Then
        SetErrorMsg "Please enter a first name.", txtFirstName
        txtFirstName.SetFocus
        Exit Sub
    End If
    If Len(txtLastName.Text) <= 0 Then
        SetErrorMsg "Please enter a last name.", txtLastName
        txtLastName.SetFocus
        Exit Sub
    End If

    OpenDbTable "tblStudents"
    If Not DbIsOpen Then
        SetErrorMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, cmdSubmit
        Exit Sub
    End If

    'add/update record filled with student information
    With DbTbl
        .Index = "PrimaryKey"
        .Seek "=", Val(txtStudentIdLocked.Text)
        'if student already exists, resubmit, otherwise create new
        If .NoMatch Then
            StudentStatus = SignStatusNewStudent
            .AddNew
            .Fields("Status") = StudentStatus
        Else
            .Edit
        End If

        .Fields("SID") = txtStudentIdLocked.Text
        StudentName = txtFirstName.Text
        .Fields("FirstName") = StudentName
        .Fields("LastName") = txtLastName.Text
        .Fields("MiddleName") = txtMiddleName.Text
        '.Recordset("Msg") = "" 'unnecessary
        .Update
        'if new record was added, move to record
        'in my opinion, the record pointer should be automatically
        'moved to the new record so this silly test does not have
        'to be done.
        If .NoMatch Then .MoveLast
    End With

    If CurrentPage = CurPageEditInfo Then
        'simply change information, blank fields, do not sign student in
        txtStudentIdLocked.Text = ""
        txtStudentIdLocked.SetFocus
        If DbTbl.NoMatch Then
            SetSuccessMsg "Added " & txtFirstName.Text & " " & txtLastName.Text & " to database", cmdSubmit
        Else
            SetSuccessMsg "Changed information for " & txtFirstName.Text & " " & txtLastName.Text, cmdSubmit
        End If
        txtFirstName.Text = ""
        txtMiddleName.Text = ""
        txtLastName.Text = ""
    Else 'CurrentPage = CurPageSubmit Or CurrentPage = CurPageReSubmit
        BuildPidList
        ChangePage CurPageGetPid
    End If

End Sub

Private Sub cmdChangeBg_Click()
    Dim File As String

    File = filBgs.Path & "\" & filBgs.FileName
    On Error GoTo PicErr
    Picture = LoadPicture(File)
    ctlDimmed.DimThis frmSignIn.hdc, ctlDimmed, &HB0B0B0
    SaveSetting "StudentSignIn", "Startup", "Bg", File
    Exit Sub

PicErr:
    MsgBox "Could not load picture" & vbNewLine & Err.Description, vbExclamation
End Sub

Private Sub filBgs_DblClick()
    cmdChangeBg_Click
End Sub

'Private Sub cboProgramId_GotFocus()
'   SendMessage cboProgramId.hwnd, CB_SHOWDROPDOWN, 1, ByVal 0&
'End Sub

Private Sub CorrectName(Obj As TextBox)
'fix names typed in all lowercase or all uppercase by setting first character
'uppercase and following characters to lowercase.
'note that it does allow names such as McIverson.
Dim Text As String
With Obj
    Text = Trim(.Text)
    If Text = UCase$(Text) Or Text = LCase$(Text) Then
        Text = UCase(Left(Text, 1)) & LCase$(Mid(Text, 2))
    Else
        Text = UCase(Left(Text, 1)) & Mid(Text, 2)
    End If
    If Right(Text, 1) = "." Then Text = Left$(Text, Len(Text) - 1)
    .Text = Text
    .SelStart = 0
    .SelLength = 32767
End With

End Sub

Private Sub SignSidIn()
'changes student status to signed in and refreshes date of last use
'add sign-in record to usage log
'this routine expects that the current record pointer is already
'set to the student that is signing in.
    Dim dateSignIn As Date
    dateSignIn = Now

    OpenDbTable "tblstudents"
    On Error GoTo ErrHandler
    StudentTbl.Index = "PrimaryKey"
    StudentTbl.Seek "=", StudentId

    'change status of student to currently logged in
    'update last sign in time
    With StudentTbl
        .Edit
        .Fields("Status") = SignStatusIn 'signed in now
        .Fields("LastUse") = dateSignIn
        .Fields("PID") = StudentPid
        .Update
    End With

    'add entry to usage log
    OpenDbTable "tblUsage"
    With DbTbl
        .AddNew
        .Fields("SID") = txtStudentIdLocked.Text
        .Fields("SignIn") = dateSignIn
        'leave SignOut null for now to indicate not signed out yet
        .Fields("PID") = StudentPid
        .Update
    End With
    Exit Sub

ErrHandler:
End Sub

Private Sub SignSidOut()
'changes student status to signed out and refreshes date of last use
'completes sign-in record in usage log
'this routine expects that the current record pointer is already
'set to the student that is signing in.
    Dim dateSignOut As Date
    dateSignOut = Now

    'opendbtable "tblstudents"
    'On Error GoTo ErrHandler
    'change status of student to currently logged out
    With StudentTbl
        .Edit
        .Fields("Status") = SignStatusOut 'signed out now
        .Fields("LastUse") = dateSignOut
        .Update
    End With

    'add entry to usage log
    OpenDbTable "SELECT * FROM tblUsage WHERE SID=" & StudentId & " AND Duration IS NULL;"
    With DbTbl
        'seek backwards for most recent sign in record
        'since new records are always appended to previous ones, it's faster
        'to search from the back than front
        '.FindLast "SID=" & txtStudentIdLocked.Text & "AND Duration IS NULL"
        If DbTbl.RecordCount > 0 Then
            .Edit
            .Fields("SignOut") = dateSignOut
            .Fields("Duration") = dateSignOut - .Fields("SignIn")
            .Update
        End If
    End With

    'Originally I wanted to let students know how many hours they have
    'been using the lab, but since VB only gives me an annoyingly cryptic
    'error (object variable not set), I guess I won't! :Þ
    'datStudents.Database.OpenRecordset ("SELECT SUM(Duration) AS TotalDur FROM tblUsage WHERE SID=" & txtStudentIdLocked.Text & ";")
    'datStudents.Database
    'DbTbl.MoveFirst
    'DbTbl.OpenRecordset ("SELECT SUM(Duration) AS TotalDur FROM tblUsage WHERE SID=" & txtStudentIdLocked.Text & ";")
    '    .RecordSource = "SELECT SUM(Duration) AS TotalDur FROM tblUsage WHERE SID=" & txtStudentIdLocked.Text
    '    .Refresh
    '    StudentDuration = .Recordset("TotalDur")
    'End With
End Sub

Private Sub SignForgottenSidOut()
    ExecSql "UPDATE tblUsage SET Duration=" & AverageDuration & " WHERE SID=" & txtStudentIdLocked.Text & " AND Duration IS NULL;"
End Sub

Private Sub SignAllSidsOut()
'used at the end of the day when lab closes and and all students
'should have logged out. Of course, you can always depend on a
'certain number of them who have not.
SetSuccessMsg "Logging out all students who forget to sign out...", lstActions
DoEvents
ExecSql "UPDATE tblStudents SET tblStudents.Status=" & SignStatusForgot & " WHERE tblStudents.Status=" & SignStatusIn & ";"
ExecSql "UPDATE tblUsage SET Duration=" & AverageDuration & " WHERE Duration IS NULL;"
If DbIsOpen Then
    SetSuccessMsg "Signed out " & Db.RecordsAffected & " students who forgot to", lstActions
Else
    SetErrorMsg "Could not execute SQL update!" & vbNewLine & DbErrMsg, lstActions
End If

End Sub

Private Sub cmdSetDbFile_Click()
    DbFilename = txtDbFilename.Text
    ChangePage CurPageMenu
End Sub

Private Sub GetStudentInformation()
'reads information from the record into the appropriate control
'!assumes the current recordset is the desired student's
'matches what is in the text prompt.
    Dim Count As Long, Pid As String

    With DbTbl
        txtFirstName.Text = .Fields("FirstName")
        txtLastName.Text = .Fields("LastName")
        txtMiddleName.Text = .Fields("MiddleName")
        Pid = .Fields("PID")
    End With
    HighlightTextPrompt txtFirstName
    HighlightTextPrompt txtMiddleName
    HighlightTextPrompt txtLastName
End Sub

Private Sub cmdBack_Click()
    Dim Page As Long, Duration As Long

    Select Case CurrentPage
    Case CurPageSubmit, CurPageReSubmit, CurPageGetPid
        Page = CurPageSignIn
    Case Else
        Page = CurPageMenu
    End Select
    ChangePage Page
    If CurrentPage <> 0 Then txtStudentId.SetFocus
    Exit Sub
End Sub

Private Sub cmdDeleteRecords_Click()
'deletes usage log records from entire term
'deletes old records for students who haven't use the lab for a while
    Dim StudentRecs As Long, UsageRecs As Long

    If MsgBox("Are you really, truly, certainly, absolutely sure?", vbExclamation Or vbYesNo Or vbDefaultButton2, "Delete entire term student usage records") = vbYes Then
        SetSuccessMsg "Deleting all student records for those haven't signed in over 180 days...", cmdDeleteRecords
        DoEvents
    
        ExecSql "DELETE * FROM tblStudents WHERE [LastUse]+180<Now;"
        If Not DbIsOpen Then
            SetErrorMsg "Could not execute SQL deletion statement!" & vbNewLine & DbErrMsg, cmdDeleteRecords
        Else
            StudentRecs = Db.RecordsAffected
            ExecSql "UPDATE tblStudents SET tblStudents.Status=" & SignStatusNewTerm & ";"
            ExecSql "DELETE * FROM tblUsage;"
            ExecSql "DELETE * FROM tblStudentPids;"
            UsageRecs = Db.RecordsAffected
            SetSuccessMsg "Deleted " & StudentRecs & " student records, reset everyone's status for new term, and cleared " & UsageRecs & " sign in records.", cmdDeleteRecords
        End If
        'CompactDatabase
    End If
End Sub

Private Sub ChangePage(Page As Long)
'the huge routine responsible for changing pages, setting certain controls
'visible, other invisible, setting default command button
    Dim PageVisible As Boolean

    If MessageShown Then ClrErrorMsg
    CurrentPage = Page

    'main choice page
    PageVisible = (Page = CurPageMenu)
    lstActions.Visible = PageVisible

    'show student id text field for sign in
    PageVisible = (Page = CurPageSignIn)
    Label5.Visible = PageVisible
    Label6.Visible = PageVisible
    txtStudentId.Visible = PageVisible
    cmdSignInOut.Visible = PageVisible
    cmdSignInOut.Default = PageVisible

    'student information page
    PageVisible = (Page = CurPageSubmit) Or (Page = CurPageEditInfo) Or (Page = CurPageReSubmit)
    Label8.Visible = PageVisible
    Label9.Visible = PageVisible
    Label10.Visible = PageVisible
    Label11.Visible = PageVisible
    Label12.Visible = PageVisible
    txtStudentIdLocked.Visible = PageVisible
    txtFirstName.Visible = PageVisible
    txtMiddleName.Visible = PageVisible
    txtLastName.Visible = PageVisible
    cmdSubmit.Visible = PageVisible
    cmdSubmit.Default = PageVisible
    txtDate.Visible = PageVisible
    imgRegForm.Visible = False

    'back button
    PageVisible = PageVisible Or (Page = CurPageDelRecords) Or (Page = CurPageSetDbFile) Or (Page = CurPageChgBkg) Or (Page = CurPageGetPid)
    cmdBack.Visible = PageVisible
    cmdBack.Cancel = PageVisible

    'student course page
    PageVisible = (Page = CurPageGetPid)
    cmdSignIn.Visible = PageVisible
    cmdSignIn.Default = PageVisible
    lstPids.Visible = PageVisible

    'set db filename
    PageVisible = (Page = CurPageSetDbFile)
    If PageVisible Then
        txtDbFilename.Text = DbFilename
        HighlightTextPrompt txtDbFilename
    End If
    txtDbFilename.Visible = PageVisible
    cmdSetDbFile.Visible = PageVisible
    cmdSetDbFile.Default = PageVisible
    Label14.Visible = PageVisible

    PageVisible = (Page = CurPageEditInfo)
    txtStudentIdLocked.Enabled = PageVisible

    PageVisible = (Page = CurPageChgBkg)
    filBgs.Visible = PageVisible
    dirBgs.Visible = PageVisible
    drvBgs.Visible = PageVisible
    cmdChangeBg.Visible = PageVisible
    cmdChangeBg.Default = PageVisible

    'show continue button for sign in acknowledgment
    'PageVisible = (Page = CurPageSignedIn)
    'cmdContinue.Visible = PageVisible
    'cmdContinue.Cancel = PageVisible

    'delete records
    cmdDeleteRecords.Visible = (Page = CurPageDelRecords)

    Select Case Page
    Case CurPageMenu: lblInstructions.Caption = "Double click on the action below in the list or press Enter."
    Case CurPageSignIn: lblInstructions.Caption = "Welcome to the Tutoring Center. Please sign in by entering your student ID number." & vbNewLine & vbNewLine & "Remember to sign out before leaving. Thank you :-)"
    Case CurPageSubmit: lblInstructions.Caption = "We do not currently have you in our system. Please enter the following information, or if you have already entered it and simply made a typing mistake, click <Back> to return."
    Case CurPageGetPid: lblInstructions.Caption = "Hello " & StudentName & ". Please select the area in which you will be working."
        lstPids.SetFocus
    Case CurPageEditInfo: lblInstructions.Caption = "Enter the ID number of the student whose information you want to change."
    Case CurPageDelRecords: lblInstructions.Caption = "Clicking Delete will remove all records of students who have not signed in for over 180 days, delete all sign in/out logs for the current term, and reset student records for a new term."
    Case CurPageSetDbFile: lblInstructions.Caption = "Enter the full path and filename to the current student database."
    Case CurPageReSubmit: lblInstructions.Caption = "You have used the Tutoring Center before. Is all this information from a previous term still correct?"
    Case CurPageChgBkg: lblInstructions.Caption = "Double click on the desired background. Click Back for main menu."
    End Select
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyNumlock Or KeyCode = vbKeyCapital Then CorrectKeyStates
End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
'escape to main menu by holding (Control+Shift) and right clicking anywhere on form
    If (Button And vbRightButton) And ((Shift And 3) = 3) Then
        ChangePage CurPageMenu
    End If
End Sub

Private Sub Form_Unload(Cancel As Integer)
    SetErrorMsg "Terminating program...", lstActions
    If MsgBox("Log out all forgetful students?", vbQuestion Or vbYesNo) = vbYes Then
        SignAllSidsOut
    End If
    DoEvents
End Sub

Private Sub lblAbout_Click()
'credits and greetings
    With msgWindow
    .ErrorColor
    .SetPicMsg "Chemeketa Open Lab Sign-In program, by Dwayne Robinson on 2001-01-30" & vbNewLine & vbNewLine & "Thanks to Daniel, Brian, Luke, Leanne, Linda, Susan, Shay, and Shirley for suggestions and input. Greets to Vahan, Shawn, Jim, Cliff, my cool cousin Russell, loving mom, grumpy dad, and beautiful Jessica...", imgMyMascot.Picture, 1
    End With
    ShowMsg Nothing
    'SetTimeOutTo ErrMsgDuration 'no time out
End Sub

Private Sub lstActions_DblClick()
'main menu
    Select Case lstActions.ListIndex
    Case 0: ChangePage CurPageSignIn
        'Dim dateSignOut As Date
        'dateSignOut = #4/27/2001 3:35:05 PM#
        'OpenDbTable "tblUsage"
        'seek backwards for most recent sign in record
        'since new records are always appended to previous ones, it's faster
        'to search from the back than front
        'DbTbl.FindLast "SID=" & txtStudentIdLocked.Text & "AND SignOut=#" & dateSignOut & "#"
    Case 1: txtStudentIdLocked.Text = ""
            txtFirstName.Text = ""
            txtLastName.Text = ""
            txtMiddleName.Text = ""
            ChangePage CurPageEditInfo
            txtStudentIdLocked.SetFocus
    Case 2: ChangePage CurPageChgBkg
            filBgs.SetFocus
    Case 3: ChangePage CurPageSetDbFile
            txtDbFilename.SetFocus
    Case 4: ChangePage CurPageDelRecords
    Case 5: 'used at the end of the day when lab closes and and all students
            'should have logged out. Of course, you can always depend on a
            'certain number of them who have not.
            SignAllSidsOut
    Case 6: Unload Me
    End Select
End Sub

Private Sub lstActions_KeyPress(KeyAscii As Integer)
'pressing Enter same as double clicking
    If KeyAscii = vbKeyReturn Then lstActions_DblClick
End Sub

Private Sub lstPids_dblClick()
    cmdSignIn_Click
End Sub

Private Sub msgWindow_CloseMe()
'close error message if user clicked on it
    ClrErrorMsg
End Sub

Private Sub tmrContinue_Timer()
'only display error messages and sign in/out messages for so long
    tmrContinue.Enabled = False
    If MessageShown Then ClrErrorMsg
    'ChangePage CurrentPage
End Sub

Private Sub SetTimeOutTo(Duration As Long)
    tmrContinue.Enabled = False
    tmrContinue.Interval = Duration
    tmrContinue.Enabled = True
End Sub

Private Sub txtFirstName_LostFocus()
    CorrectName txtFirstName
End Sub

Private Sub txtLastName_LostFocus()
    CorrectName txtLastName
End Sub

Private Sub txtMiddleName_LostFocus()
    CorrectName txtMiddleName
End Sub

Private Sub txtPage_Change()
'solely for debugging
    ChangePage Val(txtPage.Text)
    HighlightTextPrompt txtPage
End Sub

Private Sub txtStudentId_KeyPress(KeyAscii As Integer)
'accept only numbers, ignoring hyphens, space, and letters
    If KeyAscii < vbKeySpace Then
        If KeyAscii = vbKeyEscape Then txtStudentId.Text = ""
    Else
        AllowNumberKeysOnly KeyAscii
        txtStudentId.SelText = Chr(KeyAscii)
        KeyAscii = 0
    End If
End Sub

Private Sub SetErrorMsg(Text As String, RelatedField As Object)
'set an error message relative to some window control
'usually the button or text field which the error is related to
    With msgWindow
    .ErrorColor
    .SetMsg Text
    End With
    ShowMsg RelatedField
    SetTimeOutTo ErrMsgDuration
End Sub

Private Sub SetSuccessMsg(Text As String, RelatedField As Object)
'set message of success either relative to some control
'or in center of screen
    With msgWindow
    .SuccessColor
    .SetMsg Text
    End With
    ShowMsg RelatedField
    SetTimeOutTo SuccessMsgDuration
End Sub

Private Sub ShowMsg(RelatedField As Object)
'Displays a message, positioning it either relative
'to a specific object or in the center of the screen.
'
'MsgObject - object which the message is related to
    Dim MsgTop As Long, MsgLeft As Long
    Dim MsgHeight As Long, MsgWidth As Long

    With msgWindow
        MsgHeight = .Height
        MsgWidth = .Width
    
        If RelatedField Is Nothing Then
            .Top = (ScaleHeight - MsgHeight) \ 2
            .Left = (ScaleWidth - MsgWidth) \ 2
        Else
            MsgTop = RelatedField.Top - (MsgHeight - RelatedField.Height) \ 2
            MsgLeft = RelatedField.Left - MsgWidth
            If MsgLeft < 0 Then MsgLeft = RelatedField.Left + RelatedField.Width
            If MsgLeft > ScaleWidth - MsgWidth Then MsgLeft = ScaleWidth - MsgWidth
            If MsgTop < 0 Then MsgTop = 0 Else If MsgTop + MsgHeight > ScaleHeight Then MsgTop = ScaleHeight - MsgHeight
            .Top = MsgTop
            .Left = MsgLeft
        End If

        .Visible = True
        MessageShown = True
        MsgDisplayTime = GetTickCount
    End With
End Sub

Private Sub ClrErrorMsg()
    msgWindow.Visible = False
    MessageShown = False
End Sub

Public Sub OpenDbTable(Table As String)
    'attempt open database, catching those annoying errors!
    On Error GoTo OpenDbErr
    If Db Is Nothing Then Set Db = OpenDatabase(DbFilename)
    Set DbTbl = Db.OpenRecordset(Table)
    DbIsOpen = True
    Exit Sub

OpenDbErr:
    DbErrMsg = Err.Description
    DbIsOpen = False
    Exit Sub

End Sub

Private Sub ExecSql(Sql As String)
    'attempt to execute SQL statement, catching those annoying errors!
    On Error GoTo OpenDbErr
    If Db Is Nothing Then Set Db = OpenDatabase(DbFilename)
    Db.Execute Sql, dbFailOnError
    DbIsOpen = True
    Exit Sub

OpenDbErr:
    DbErrMsg = Err.Description
    DbIsOpen = False
    Exit Sub

End Sub

Private Sub txtStudentIdLocked_Change()
'for the Edit Student info page
'after a full 9 digit SID has been typed in, read student info for that SID
    If CurrentPage = CurPageEditInfo And Len(txtStudentIdLocked.Text) = 9 Then
        OpenDbTable "tblStudents"
        EditingSid = False
        If DbIsOpen Then
            StudentId = Val(txtStudentIdLocked.Text)
            DbTbl.Index = "PrimaryKey"
            DbTbl.Seek "=", StudentId
            If Not DbTbl.NoMatch Then
                GetStudentInformation
                EditingSid = True
            Else
                SetErrorMsg "No student with that SID.", cmdSubmit
            End If
        Else
            SetErrorMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, cmdSubmit
        End If
    End If
End Sub

Private Sub txtStudentIdLocked_KeyPress(KeyAscii As Integer)
    AllowNumberKeysOnly KeyAscii
End Sub

Public Sub AllowNumberKeysOnly(KeyAscii As Integer)
'accept only numbers, ignoring hyphens, space, and letters
If KeyAscii >= 32 Then
    If KeyAscii < 48 Or KeyAscii > 57 Then KeyAscii = 0
End If
End Sub

Private Sub txtStudentIdLocked_KeyUp(KeyCode As Integer, Shift As Integer)
    If EditingSid Then
        txtFirstName.SetFocus
        HighlightTextPrompt txtStudentIdLocked
        EditingSid = False
    End If
End Sub

Private Function GetTimeDifMsg(TimeDif As Double)
    Dim Msg As String

    Select Case TimeDif
    Case Is < 0.0416    'minutes
        Msg = Int(TimeDif * 1440) & " minutes ago"
    Case Is < 1         'hours
        Msg = Format(TimeDif * 24, "0.0") & " hours ago"
    Case Is < 2         'yesterday
        Msg = "yesterday"
    Case Else           'days
        Msg = Int(TimeDif) & " days ago"
    End Select

    GetTimeDifMsg = Msg

End Function

Private Sub HighlightTextPrompt(txtHighlight As TextBox)
    txtHighlight.SelStart = 0
    txtHighlight.SelLength = 32767
End Sub

Public Sub BuildPidList()
'builds list customized according to the student signing in,
'so that the courses which the student has already chosen before appear
'at the top of the list.

    'clear list
    'add courses the student has already entered first
    'add remaining courses to end of list that they haven't taken
    'find pid of last course taken by student and select it

    lstPids.Clear
    Erase StudentPids
    OpenDbTable "SELECT * FROM tblStudentPids WHERE SID=" & StudentId & ";"
    If DbIsOpen Then
        With DbTbl
            Do Until .EOF
                Value = .Fields("PID")
                If Value < MaxPids And Value >= 0 Then
                    StudentPids(Value) = True
                    With lstPids
                        .AddItem ("»" & Pids(Value))
                        .ItemData(.NewIndex) = Value
                        If Value = StudentPid Then .ListIndex = .NewIndex
                    End With
                End If
                .MoveNext
            Loop
        End With
    'Else
    '    SetErrorMsg "Error opening database! (need tblStudentPids)" & vbNewLine & DbErrMsg, cmdSignIn
    '    Exit Sub
    End If

    For Value = 0 To MaxPids - 1
        If Not StudentPids(Value) Then
            If Len(Pids(Value)) Then
                With lstPids
                    .AddItem (Pids(Value))
                    .ItemData(.NewIndex) = Value
                End With
            End If
        End If
    Next
End Sub

Public Sub AddStudentPid()
    OpenDbTable "tblStudentPids"
    If DbIsOpen Then
        With DbTbl
            .Index = "PrimaryKey"
            .Seek "=", StudentId, StudentPid
            If .NoMatch Then
                .AddNew
                .Fields("SID") = StudentId
                .Fields("PID") = StudentPid
                .Update
            End If
        End With
    'Else
    '    SetErrorMsg "Error opening database! (need tblStudentPids)" & vbNewLine & DbErrMsg, cmdSignIn
    '    Exit Sub
    End If
End Sub
