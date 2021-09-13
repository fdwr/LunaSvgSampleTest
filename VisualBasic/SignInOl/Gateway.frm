VERSION 5.00
Begin VB.Form frmGateway 
   AutoRedraw      =   -1  'True
   BackColor       =   &H80000010&
   BorderStyle     =   0  'None
   Caption         =   "Open Lab Sign-In"
   ClientHeight    =   18000
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
   Icon            =   "Gateway.frx":0000
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   1200
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   800
   ShowInTaskbar   =   0   'False
   WindowState     =   2  'Maximized
   Begin prjSignInOl.msgWindow msgWindow 
      Height          =   255
      Left            =   720
      Top             =   8520
      Visible         =   0   'False
      Width           =   495
      _ExtentX        =   873
      _ExtentY        =   450
   End
   Begin VB.ListBox lstPids 
      BackColor       =   &H00E0F0F8&
      Height          =   3105
      ItemData        =   "Gateway.frx":0442
      Left            =   6960
      List            =   "Gateway.frx":0449
      TabIndex        =   9
      Top             =   4080
      Visible         =   0   'False
      Width           =   4335
   End
   Begin VB.TextBox txtMiddleName 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   2760
      TabIndex        =   6
      Top             =   6120
      Visible         =   0   'False
      Width           =   3135
   End
   Begin VB.TextBox txtFirstName 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   2760
      TabIndex        =   4
      Top             =   5520
      Visible         =   0   'False
      Width           =   3135
   End
   Begin VB.DriveListBox drvBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   720
      TabIndex        =   32
      Top             =   2880
      Visible         =   0   'False
      Width           =   4935
   End
   Begin VB.TextBox txtStudentIdLocked 
      BackColor       =   &H00E0F0F8&
      Enabled         =   0   'False
      Height          =   495
      IMEMode         =   3  'DISABLE
      Left            =   2760
      MaxLength       =   9
      PasswordChar    =   "*"
      TabIndex        =   24
      Text            =   "123456789"
      Top             =   4080
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.TextBox txtDate 
      BackColor       =   &H00E0F0F8&
      Enabled         =   0   'False
      Height          =   495
      Left            =   2760
      TabIndex        =   26
      Text            =   "[date]"
      Top             =   4680
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
      Height          =   555
      Left            =   2760
      TabIndex        =   8
      Top             =   6720
      Visible         =   0   'False
      Width           =   3135
   End
   Begin VB.TextBox txtPage 
      Height          =   555
      Left            =   0
      TabIndex        =   10
      Top             =   8280
      Visible         =   0   'False
      Width           =   495
   End
   Begin VB.FileListBox filBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   4440
      Left            =   6120
      Pattern         =   "*.jpg;*.bmp"
      TabIndex        =   33
      Top             =   2880
      Visible         =   0   'False
      Width           =   5295
   End
   Begin VB.TextBox txtStudentId 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      IMEMode         =   3  'DISABLE
      Left            =   6000
      MaxLength       =   9
      PasswordChar    =   "*"
      TabIndex        =   30
      Top             =   5640
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.ListBox lstActions 
      BackColor       =   &H00E0F0F8&
      Height          =   3105
      ItemData        =   "Gateway.frx":0468
      Left            =   4080
      List            =   "Gateway.frx":0481
      TabIndex        =   29
      Top             =   3480
      Visible         =   0   'False
      Width           =   3615
   End
   Begin VB.TextBox txtDbFilename 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      Left            =   2640
      TabIndex        =   14
      Top             =   3480
      Visible         =   0   'False
      Width           =   8655
   End
   Begin VB.DirListBox dirBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   3810
      Left            =   720
      TabIndex        =   31
      Top             =   3480
      Visible         =   0   'False
      Width           =   4935
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
      TabIndex        =   20
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
      TabIndex        =   28
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
      TabIndex        =   13
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdSignInOut 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Sign In/Out"
      Height          =   615
      Left            =   4920
      Style           =   1  'Graphical
      TabIndex        =   11
      Top             =   7920
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.CommandButton cmdBack 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Back"
      Height          =   615
      Left            =   6120
      Style           =   1  'Graphical
      TabIndex        =   16
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.Image imgDbErr 
      Height          =   1050
      Left            =   9960
      Picture         =   "Gateway.frx":04EF
      Top             =   9000
      Visible         =   0   'False
      Width           =   1065
   End
   Begin VB.Image imgBye 
      Height          =   1320
      Left            =   9000
      Picture         =   "Gateway.frx":0C4F
      Top             =   9000
      Visible         =   0   'False
      Width           =   960
   End
   Begin VB.Image imgHello 
      Height          =   1200
      Left            =   8160
      Picture         =   "Gateway.frx":1437
      Top             =   9000
      Visible         =   0   'False
      Width           =   840
   End
   Begin VB.Label Label13 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Field of Study:"
      Height          =   855
      Left            =   4920
      TabIndex        =   34
      Top             =   4080
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Image imgMyMascot 
      Height          =   2895
      Left            =   600
      Picture         =   "Gateway.frx":1BC3
      Top             =   9000
      Visible         =   0   'False
      Width           =   1470
   End
   Begin VB.Image Image1 
      Height          =   1215
      Left            =   360
      Picture         =   "Gateway.frx":4B6B
      Top             =   360
      Width           =   1215
   End
   Begin VB.Label Label14 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Filename:"
      Height          =   495
      Left            =   600
      TabIndex        =   27
      Top             =   3480
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label Label8 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Today"
      Height          =   495
      Left            =   600
      TabIndex        =   25
      Top             =   4680
      Visible         =   0   'False
      Width           =   2055
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
      Caption         =   "(either your k-number or social security number)"
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
      Left            =   3600
      TabIndex        =   21
      Top             =   6240
      Visible         =   0   'False
      Width           =   5055
   End
   Begin VB.Label Label12 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Last Name"
      Height          =   495
      Left            =   600
      TabIndex        =   7
      Top             =   6720
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label Label11 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Middle Initial"
      Height          =   495
      Left            =   600
      TabIndex        =   5
      Top             =   6120
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label Label10 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "First Name"
      Height          =   495
      Left            =   600
      TabIndex        =   3
      Top             =   5520
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label Label9 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Student Id"
      Height          =   495
      Left            =   600
      TabIndex        =   23
      Top             =   4080
      Visible         =   0   'False
      Width           =   2055
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
      TabIndex        =   19
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
      TabIndex        =   18
      Top             =   1320
      Width           =   3375
   End
   Begin VB.Label lblConcave 
      BackStyle       =   0  'Transparent
      BorderStyle     =   1  'Fixed Single
      Height          =   5295
      Left            =   480
      TabIndex        =   22
      Top             =   2280
      Width           =   11175
   End
   Begin prjSignInOl.DimmedBg ctlDimmed 
      Height          =   5295
      Left            =   480
      Top             =   2280
      Width           =   11175
      _ExtentX        =   1085
      _ExtentY        =   1296
   End
   Begin prjSignInOl.DimmedBg ctlAbout 
      Height          =   150
      Left            =   0
      Top             =   8880
      Visible         =   0   'False
      Width           =   345
      _ExtentX        =   873
      _ExtentY        =   450
   End
   Begin VB.Label Label7 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      Caption         =   "Chemeketa Open Lab"
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
      Caption         =   "Chemeketa Open Lab"
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
      TabIndex        =   17
      Top             =   120
      Width           =   11655
   End
   Begin VB.Image imgRegForm 
      Height          =   3495
      Left            =   2160
      Picture         =   "Gateway.frx":56AD
      Top             =   9000
      Visible         =   0   'False
      Width           =   5955
   End
End
Attribute VB_Name = "frmGateway"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'By Peekin, 2000-01-29:2001-03-12
'Chemeketa Open Lab Sign In
'Note that any pseudocode left in here is simply for reference. The actual
'code may no longer reflect that structure.
'
'2001-01-29  4 1/2 hours ;)
'2001-01-30  4
'...and here I lose track of time...
'2001-03-01  4
'2001-03-02  1
'2001-03-07  3
'...program done for now
'2001-10-24 Added K number support
'           Now supported in Win2k, without need of VB service pack 4
'           Uses database object instead of dumb data control
'           Should be a little faster (very marginal)
'           Sign in/out messages displayed in brightly colored rectangles
'             instead of switching to separate screen pages.
'           Error messages can include pictures now
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

Dim CurrentPage As Long         'current page showing
Dim MessageShown As Long        'a message is displayed
Private Value As Long           'generic variable reused over and over
Private Counter As Long         'another one

Dim StudentName As String       'take a guess...
Dim StudentLastUse As Date      'last sign in or sign out
Dim StudentMsg As String        'optional message to display
Dim StudentId As Long           'either SSN or (K number)+1000000000
Dim StudentStatus As Byte       'signed in, signed out, new term...
Dim StudentPid As Long          'selected program id
'Dim SqlUpdateStatement As String
Dim BgFilename As String
Dim MsgDisplayTime As Long
Dim EditingSid As Boolean
Dim StudentSignedIn As Boolean
Dim Pids(MaxPids - 1) As String

Const CurPageMenu = 0
Const CurPageSignIn = 1
Const CurPageSubmit = 2
'Const CurPageGetPid = 3
'Const CurPageSignedIn = 4
Const CurPageEditInfo = 5
Const CurPageDelRecords = 6
Const CurPageSetDbFile = 7
Const CurPageReSubmit = 8
Const CurPageChgBkg = 9

Const MsgSuccessColor = &HC0FFC0
Const MsgErrorColor = &HC0C0FF
Const MsgInformationColor = &HFFC0C0

Const SignStatusOut = 0
Const SignStatusIn = 1
Const SignStatusForgot = 2
Const SignStatusNewTerm = 3
Const SignStatusNewStudent = 4

Const BgFilenameDef As String = "arlokia.jpg" 'default background image

Const ErrMsgDuration As Long = 22000    'clear error message after 22 seconds
Const SuccessMsgDuration As Long = 9000 'clear successful sign in message after
'Const MinMsgDuration As Long = 2000  'ensure students read message!

Const DimmedColor = &HB0B0B0

Private Sub dirBgs_Change()
    On Error Resume Next
    filBgs.Path = dirBgs.Path
    drvBgs.Drive = dirBgs.Path
End Sub

Private Sub dirBgs_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyRight Then filBgs.SetFocus: KeyCode = 0
End Sub

Private Sub drvBgs_Change()
    On Error Resume Next
    dirBgs.Path = drvBgs.Drive
End Sub

Private Sub filBgs_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyLeft Then dirBgs.SetFocus: KeyCode = 0
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

    On Error GoTo EatError
    drvBgs.Drive = AppPath
    dirBgs.Path = AppPath
    filBgs.Path = AppPath
    GetSetting "StudentSignIn", "Startup", "Bg", BgFilename
    If Len(BgFilename) <= 0 Then BgFilename = AppPath & BgFilenameDef
    Picture = LoadPicture(BgFilename)
    ctlDimmed.DimThis hdc, ctlDimmed, DimmedColor

    'read in PIDs
    DbFilename = AppPath & DbFilenameDef
    OpenDbTable "tblPids"
    If Not DbIsOpen Then
        ChangePage CurPageSetDbFile
        SetMsg "Error opening database! (need tblPids)" & vbNewLine & DbErrMsg, cmdSetDbFile, MsgErrorColor
    Else
        BuildPidList
        ChangePage Page
    End If
    CorrectKeyStates
    Exit Sub

EatError: 'disregard any annoying errors
    Resume Next

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
    If MessageShown = True Then msgWindow_CloseMe: Exit Sub

    txtStudentId.SetFocus
    If Len(txtStudentId.Text) < 9 Then
        SetMsg "Your student ID can be found on the back of your ID card, and can be either your k-number or social security number.", txtStudentId, MsgInformationColor
        HighlightTextPrompt txtStudentId
        Exit Sub
    End If

    SetMsg "Checking status...", cmdSignInOut, MsgInformationColor
    DoEvents
    OpenDbTable "tblStudents"
    If Not DbIsOpen Then
        'If DbErrNum = 3043 Then
            msgWindow.SetColor MsgErrorColor
            msgWindow.SetPicMsg vbCrLf & vbCrLf & vbCrLf & "The network is either down or the database can not be connected to..." & vbCrLf & vbCrLf & "Just skip the sign-in and take a computer a computer for now" & vbCrLf & vbCrLf & vbCrLf, imgDbErr.Picture, 0
            ShowMsg Nothing
        'Else
        '    SetMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, cmdSignInOut, MsgErrorColor
        'End If
        Exit Sub
    End If
    Set StudentTbl = DbTbl
    StudentId = GetNumericSid(txtStudentId.Text)
    StudentTbl.Index = "PrimaryKey"
    StudentTbl.Seek "=", StudentId

    txtStudentIdLocked.Text = txtStudentId.Text 'in case new student
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
        lstPids.ListIndex = 0

        ChangePage CurPageSubmit
        txtFirstName.SetFocus
    ElseIf StudentStatus = SignStatusNewTerm Then 'returning student
        'MsgBox "new term, signing in"
        'new term, so verify previous information
        GetStudentInformation
        ChangePage CurPageReSubmit
        txtFirstName.SetFocus
    ElseIf StudentStatus = SignStatusIn Then 'currently signed in
        SignSidOut
        msgWindow.SetColor MsgInformationColor
        msgWindow.SetPicMsg vbCrLf & "You have been " & vbCrLf & "signed out " & StudentName & vbCrLf, imgBye.Picture, 0
        ShowMsg Nothing
        'It would be convenient to display a message to an individual
        'student if you needed to tell him/her that they left behind
        'their student ID card or perhaps a disk
    ElseIf StudentStatus = SignStatusForgot Then 'forgot to sign out
        'MsgBox "forgot to sign out"
        SetMsg "Our records show that you didn't sign out the last time you visited the Open Lab, " & GetTimeDifMsg(Now - StudentLastUse) & ". Please remember to sign out when you are finished. Click sign in once more to continue.", cmdSignInOut, MsgErrorColor
        MessageShown = 1
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
        SignSidIn
        'SetMsg "You have been signed in " & StudentName & ".", Nothing, MsgSuccessColor
        msgWindow.SetColor MsgSuccessColor
        msgWindow.SetPicMsg vbCrLf & "You have been " & vbCrLf & "signed in " & StudentName & vbCrLf, imgHello.Picture, 0
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
        SetMsg "Your student ID is the nine digit number on the back of your card (usually the same as your social security number)", txtStudentIdLocked, MsgInformationColor
        txtStudentIdLocked.SetFocus
        Exit Sub
    End If
    If Len(txtFirstName.Text) <= 0 Then
        SetMsg "Please enter a first name.", txtFirstName, MsgInformationColor
        txtFirstName.SetFocus
        Exit Sub
    End If
    If Len(txtLastName.Text) <= 0 Then
        SetMsg "Please enter a last name.", txtLastName, MsgInformationColor
        txtLastName.SetFocus
        Exit Sub
    End If
    If lstPids.ListIndex <= 0 Then
        SetMsg "Please select your field of study from the list (your current major).", lstPids, MsgInformationColor
        lstPids.SetFocus
        Exit Sub
    End If

    OpenDbTable "tblStudents"
    If Not DbIsOpen Then GoTo DbErr
    On Error GoTo DbErr

    StudentPid = lstPids.ItemData(lstPids.ListIndex)
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

        .Fields("SID") = StudentId
        StudentName = txtFirstName.Text
        .Fields("FirstName") = StudentName
        .Fields("LastName") = txtLastName.Text
        .Fields("MiddleName") = txtMiddleName.Text
        .Fields("PID") = StudentPid
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
            SetMsg "Added " & txtFirstName.Text & " " & txtLastName.Text & " to database", cmdSubmit, MsgSuccessColor
        Else
            SetMsg "Changed information for " & txtFirstName.Text & " " & txtLastName.Text, cmdSubmit, MsgSuccessColor
        End If
        txtFirstName.Text = ""
        txtMiddleName.Text = ""
        txtLastName.Text = ""
    Else 'CurrentPage = CurPageSubmit Or CurrentPage = CurPageReSubmit
        SignSidIn
        ChangePage CurPageSignIn
        msgWindow.SetColor MsgSuccessColor
        msgWindow.SetPicMsg "This is the first time you have signed in this term, so don't forget to fill in the paperwork.", imgRegForm.Picture, 2
        ShowMsg Nothing
    End If
    Exit Sub

DbErr:
    SetMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, cmdSubmit, MsgErrorColor

End Sub

Private Sub cmdChangeBg_Click()
    Dim File As String, BgPicture As StdPicture
    Dim Row As Long, Col As Long
    Dim PicHeight As Long, PicWidth As Long
    Dim FrmHeight As Long, FrmWidth As Long

    ' load from file
    File = filBgs.Path & "\" & filBgs.FileName
    On Error GoTo PicErr
    Set BgPicture = LoadPicture(File)

    ' tile bg image
    ' Why is VB so STUPID when it comes to pictures?
    ' It is so simple, a kindergartner could it right.
    ' If I ask for the pictures height, I want (surprise!)
    ' how many pixels high it is, not some funky, nonsense
    ' value * 26.45?? And (while I'm on a tangent) who is
    ' the idiot that had to complicate every graphic operation
    ' with something insane called "twips"?? If only common
    ' sense ruled MicroSoft...
    FrmHeight = Height \ 15 'stupid, stupid twips!
    FrmWidth = Width \ 15
    PicWidth = Int(BgPicture.Width / 26.45) 'what is going on here!?
    PicHeight = Int(BgPicture.Height / 26.45)
    For Row = 0 To FrmHeight - 1 Step PicHeight
        For Col = 0 To FrmWidth - 1 Step PicWidth
            PaintPicture BgPicture, Col, Row
        Next
    Next
    ctlDimmed.DimThis hdc, ctlDimmed, &HB0B0B0
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

Private Sub SignSidIn()
'changes student status to signed in and refreshes date of last use
'add sign-in record to usage log
'this routine expects that the current record pointer is already
'set to the student that is signing in.
    StudentLastUse = Now

    OpenDbTable "tblstudents"
    On Error GoTo ErrHandler
    StudentTbl.Index = "PrimaryKey"
    StudentTbl.Seek "=", StudentId

    'change status of student to currently logged in
    'update last sign in time
    With StudentTbl
        .Edit
        .Fields("Status") = SignStatusIn 'signed in now
        .Fields("LastUse") = StudentLastUse
        .Update
    End With
    StudentSignedIn = True

#If 0 Then
    'add entry to usage log
    OpenDbTable "tblUsage"
    With DbTbl
        .AddNew
        .Fields("SID") = txtStudentIdLocked.Text
        .Fields("SignIn") = StudentLastUse
        'leave SignOut null for now to indicate not signed out yet
        .Fields("PID") = StudentPid
        .Update
    End With
    Exit Sub
#End If

ErrHandler:
End Sub

Private Sub SignSidOut()
'changes student status to signed out and refreshes date of last use
'don't record usage log if <= 1 minute
'appends sign-in record in usage log
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
        'StudentPid = .Fields("PID")
        'StudentLastUse = .Fields("LastUse") 'get sign in time
        .Fields("LastUse") = dateSignOut  'set sign out time
        .Update
    End With
    
    If dateSignOut - StudentLastUse <= 0.000694 Then Exit Sub

    'add entry to usage log
    OpenDbTable "tblUsage"
    With DbTbl
        .AddNew
        .Fields("SID") = txtStudentIdLocked.Text
        .Fields("SignIn") = StudentLastUse
        .Fields("SignOut") = dateSignOut
        .Fields("Duration") = dateSignOut - StudentLastUse
        'leave SignOut null for now to indicate not signed out yet
        .Fields("PID") = StudentPid
        .Update
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
SetMsg "Logging out all students who forget to sign out...", lstActions, MsgSuccessColor
DoEvents

ExecSql "INSERT INTO tblUsage (SID,SignIn,SignOut,Duration,PID) " _
      & "SELECT tblStudents.SID,tblStudents.LastUse,Now(), Now()-tblStudents.LastUse,tblStudents.PID " _
      & "FROM tblStudents " _
      & "WHERE tblStudents.Status=1;"
ExecSql "UPDATE tblStudents SET tblStudents.Status=" & SignStatusForgot & " WHERE tblStudents.Status=" & SignStatusIn & ";"
If DbIsOpen Then
    SetMsg "Signed out " & Db.RecordsAffected & " students who forgot to", lstActions, MsgSuccessColor
    StudentSignedIn = False
Else
    SetMsg "Could not execute SQL update!" & vbNewLine & DbErrMsg, lstActions, MsgErrorColor
End If

End Sub

Private Sub cmdSetDbFile_Click()
    'If Not DbTbl Is Nothing Then If DbTbl.Name = Table Then Exit Sub
    If Not Db Is Nothing Then Db.Close: Set Db = Nothing: Set DbTbl = Nothing
    DbFilename = txtDbFilename.Text
    SetMsg "Loading program IDs from database...", cmdSetDbFile, MsgInformationColor
    DoEvents
    BuildPidList
    If DbIsOpen Then ChangePage CurPageMenu
End Sub

Private Sub GetStudentInformation()
'reads information from the record into the appropriate control
'!assumes the current recordset is the desired student's
'matches what is in the text prompt.
    With DbTbl
        txtFirstName.Text = .Fields("FirstName")
        txtLastName.Text = .Fields("LastName")
        txtMiddleName.Text = .Fields("MiddleName")
        StudentPid = .Fields("PID")
        For Counter = lstPids.ListCount - 1 To 1 Step -1
            If lstPids.ItemData(Counter) = StudentPid Then Exit For
        Next
        lstPids.ListIndex = Counter
    End With
    HighlightTextPrompt txtFirstName
    HighlightTextPrompt txtMiddleName
    HighlightTextPrompt txtLastName
End Sub

Private Sub cmdBack_Click()
    Dim Page As Long, Duration As Long

    Select Case CurrentPage
    Case CurPageSubmit, CurPageReSubmit
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
        SetMsg "Deleting all student records for those haven't signed in over 180 days...", cmdDeleteRecords, MsgSuccessColor
        DoEvents
    
        ExecSql "DELETE * FROM tblStudents WHERE [LastUse]+180<Now;"
        If Not DbIsOpen Then
            SetMsg "Could not execute SQL deletion statement!" & vbNewLine & DbErrMsg, cmdDeleteRecords, MsgErrorColor
        Else
            StudentRecs = Db.RecordsAffected
            ExecSql "UPDATE tblStudents SET tblStudents.Status=" & SignStatusNewTerm & ";"
            ExecSql "DELETE * FROM tblUsage;"
            'ExecSql "DELETE * FROM tblStudentPids;"
            UsageRecs = Db.RecordsAffected
            SetMsg "Deleted " & StudentRecs & " student records, reset everyone's status for new term, and cleared " & UsageRecs & " sign in records.", cmdDeleteRecords, MsgSuccessColor
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

    'student information page
    PageVisible = (Page = CurPageSubmit) Or (Page = CurPageEditInfo) Or (Page = CurPageReSubmit)
    Label8.Visible = PageVisible
    Label9.Visible = PageVisible
    Label10.Visible = PageVisible
    Label11.Visible = PageVisible
    Label12.Visible = PageVisible
    Label13.Visible = PageVisible
    txtStudentIdLocked.Visible = PageVisible
    txtFirstName.Visible = PageVisible
    txtMiddleName.Visible = PageVisible
    txtLastName.Visible = PageVisible
    cmdSubmit.Visible = PageVisible
    cmdSubmit.Default = PageVisible
    txtDate.Visible = PageVisible
    lstPids.Visible = PageVisible
    imgRegForm.Visible = False

    'back button
    PageVisible = PageVisible Or (Page = CurPageDelRecords) Or (Page = CurPageSetDbFile) Or (Page = CurPageChgBkg)
    cmdBack.Visible = PageVisible
    cmdBack.Cancel = PageVisible

    'student course page
    'PageVisible = (Page = CurPageGetPid)
    'cmdSignIn.Visible = PageVisible
    'cmdSignIn.Default = PageVisible
    'lstPids.Visible = PageVisible

    PageVisible = (Page = CurPageEditInfo)
    txtStudentIdLocked.Enabled = PageVisible

    ' select background image
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
    Case CurPageSignIn: lblInstructions.Caption = "Welcome to the Open Lab. Before using any of the computer equipment in this room, please enter your student ID number. After signing in, you may use any free computer." & vbNewLine & vbNewLine & "Remember to sign out before leaving. Thank you :-)"
    Case CurPageSubmit: lblInstructions.Caption = "We do not currently have you in our system. Please enter the following information, or if you have already entered it and simply made a typing mistake, click <Back> to return."
    'Case CurPageGetPid: lblInstructions.Caption = "Hello " & StudentName & ". Please select the area in which you will be working."
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

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
'escape to main menu by holding (Control+Shift) and right clicking anywhere on form
    If (Button And vbRightButton) And ((Shift And 3) = 3) Then
        ChangePage CurPageMenu
    End If
End Sub

'Private Sub Form_Paint()
    'Me.PaintPicture Pic
'End Sub

Private Sub Form_Unload(Cancel As Integer)
    SetMsg "Terminating program...", lstActions, MsgErrorColor
    If StudentSignedIn Then
        If MsgBox("Log out all forgetful students?", vbQuestion Or vbYesNo) = vbYes Then
            SignAllSidsOut
        End If
    End If
    DoEvents
End Sub

Private Sub lblAbout_Click()
'credits and greetings
    With msgWindow
    .SetColor MsgInformationColor
    .SetPicMsg "Chemeketa Open Lab Sign-In program, by Dwayne Robinson on 2001-01-30" & vbNewLine & vbNewLine & "Thanks to Daniel, Brian, Luke, Leanne, Linda, Susan, Shay, and Shirley for suggestions and input. Greets to Vahan, Shawn, Jim, Cliff, my cool cousin Russell, loving mom, grumpy dad, and beautiful Jessica...", imgMyMascot.Picture, 1
    End With
    ShowMsg Nothing
    SetTimeOutTo ErrMsgDuration
End Sub

Private Sub lblConcave_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Form_MouseDown Button, Shift, X, Y
End Sub

Private Sub lblInstructions_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Form_MouseDown Button, Shift, X, Y
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
        AllowNumberKeysOnly KeyAscii, txtStudentId
        txtStudentId.SelText = Chr(KeyAscii)
        KeyAscii = 0
    End If
End Sub

Private Sub SetMsg(Text As String, RelatedField As Object, Color As Long)
'set text for an error/information and shows message
'usually relative to some window control, like the button or
'text field which the error is related to
    With msgWindow
    .SetColor Color
    .SetMsg Text
    End With
    ShowMsg RelatedField
    SetTimeOutTo ErrMsgDuration
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

Private Sub txtStudentIdLocked_Change()
'for the Edit Student info page
'after a full 9 digit SID has been typed in, read student info for that SID
    If CurrentPage = CurPageEditInfo And Len(txtStudentIdLocked.Text) = 9 Then
        OpenDbTable "tblStudents"
        EditingSid = False
        If DbIsOpen Then
            StudentId = GetNumericSid(txtStudentIdLocked.Text)
            DbTbl.Index = "PrimaryKey"
            DbTbl.Seek "=", StudentId
            If Not DbTbl.NoMatch Then
                GetStudentInformation
                EditingSid = True
            Else
                SetMsg "No student with that SID.", cmdSubmit, MsgErrorColor
                txtFirstName.Text = ""
                txtLastName.Text = ""
                txtMiddleName.Text = ""
                lstPids.ListIndex = 0
            End If
        Else
            SetMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, cmdSubmit, MsgErrorColor
        End If
    End If
End Sub

Private Sub txtStudentIdLocked_KeyPress(KeyAscii As Integer)
    AllowNumberKeysOnly KeyAscii, txtStudentIdLocked
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

#If 0 Then
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
    '    SetMsg "Error opening database! (need tblStudentPids)" & vbNewLine & DbErrMsg, cmdSignIn, MsgErrorColor
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
#Else
Public Sub BuildPidList()
    OpenDbTable "tblPids"
    If DbIsOpen Then
        lstPids.Clear
        lstPids.AddItem ("(select program id)")
        With DbTbl
            Do Until .EOF
                Value = .Fields("PID")
                With lstPids
                    .AddItem DbTbl.Fields("Name")
                    .ItemData(.NewIndex) = Value
                End With
                .MoveNext
            Loop
        End With
    Else
        SetMsg "Could not read program IDs from database! (need tblPids)" & vbNewLine & DbErrMsg, cmdSetDbFile, MsgErrorColor
        Exit Sub
    End If
End Sub
#End If
