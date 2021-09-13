VERSION 5.00
Begin VB.Form frmSignIn 
   AutoRedraw      =   -1  'True
   BorderStyle     =   0  'None
   Caption         =   "Open Lab Sing-In"
   ClientHeight    =   9000
   ClientLeft      =   0
   ClientTop       =   0
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
   ScaleHeight     =   600
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   800
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   WindowState     =   2  'Maximized
   Begin prgSignIn.msgWindow msgError 
      Height          =   255
      Left            =   0
      Top             =   7920
      Visible         =   0   'False
      Width           =   495
      _ExtentX        =   873
      _ExtentY        =   450
   End
   Begin VB.Data datStudents 
      Connect         =   "Access 2000;"
      DatabaseName    =   ""
      DefaultCursorType=   0  'DefaultCursor
      DefaultType     =   2  'UseODBC
      Exclusive       =   0   'False
      Height          =   540
      Left            =   600
      Options         =   0
      ReadOnly        =   0   'False
      RecordsetType   =   1  'Dynaset
      RecordSource    =   ""
      Top             =   8280
      Visible         =   0   'False
      Width           =   1245
   End
   Begin VB.TextBox txtDate 
      BackColor       =   &H00E0F0F8&
      Enabled         =   0   'False
      Height          =   495
      Left            =   2640
      TabIndex        =   29
      Text            =   "[date]"
      Top             =   4680
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Timer tmrContinue 
      Interval        =   22000
      Left            =   1920
      Top             =   8280
   End
   Begin VB.TextBox txtStudentId 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      IMEMode         =   3  'DISABLE
      Left            =   6000
      MaxLength       =   9
      PasswordChar    =   "*"
      TabIndex        =   4
      Top             =   5760
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.TextBox txtFirstName 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      Left            =   2640
      TabIndex        =   8
      Top             =   5520
      Visible         =   0   'False
      Width           =   3135
   End
   Begin VB.TextBox txtLastName 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      Left            =   2640
      TabIndex        =   12
      Top             =   6720
      Visible         =   0   'False
      Width           =   3135
   End
   Begin VB.TextBox txtMiddleName 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      Left            =   2640
      TabIndex        =   10
      Top             =   6120
      Visible         =   0   'False
      Width           =   3135
   End
   Begin VB.ListBox lstProgramId 
      BackColor       =   &H00E0F0F8&
      Height          =   3105
      ItemData        =   "SignIn.frx":0442
      Left            =   6960
      List            =   "SignIn.frx":0479
      TabIndex        =   14
      Top             =   4080
      Visible         =   0   'False
      Width           =   4335
   End
   Begin VB.TextBox txtPage 
      Height          =   555
      Left            =   0
      TabIndex        =   16
      Top             =   8280
      Visible         =   0   'False
      Width           =   495
   End
   Begin VB.TextBox txtDbFilename 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      Left            =   2640
      TabIndex        =   15
      Top             =   3480
      Visible         =   0   'False
      Width           =   8655
   End
   Begin VB.TextBox txtStudentIdLocked 
      BackColor       =   &H00E0F0F8&
      Enabled         =   0   'False
      Height          =   495
      IMEMode         =   3  'DISABLE
      Left            =   2640
      MaxLength       =   9
      PasswordChar    =   "*"
      TabIndex        =   6
      Text            =   "123456789"
      Top             =   4080
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.ListBox lstActions 
      BackColor       =   &H00E0F0F8&
      Height          =   3540
      ItemData        =   "SignIn.frx":05CE
      Left            =   3960
      List            =   "SignIn.frx":05EA
      TabIndex        =   2
      Top             =   3360
      Visible         =   0   'False
      Width           =   3615
   End
   Begin VB.CommandButton cmdSignIn 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Sign In"
      Height          =   615
      Left            =   5160
      Style           =   1  'Graphical
      TabIndex        =   17
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
      TabIndex        =   22
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdContinue 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Finish"
      Height          =   615
      Left            =   5160
      Style           =   1  'Graphical
      TabIndex        =   18
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
      TabIndex        =   19
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
      TabIndex        =   26
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
      TabIndex        =   32
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
      TabIndex        =   20
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
      TabIndex        =   21
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.FileListBox filBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   4005
      Left            =   3960
      Pattern         =   "*.jpg;*.bmp"
      TabIndex        =   33
      Top             =   3120
      Visible         =   0   'False
      Width           =   3615
   End
   Begin VB.Image imgRegForm 
      Height          =   3495
      Left            =   3000
      Picture         =   "SignIn.frx":065E
      Top             =   3840
      Visible         =   0   'False
      Width           =   5955
   End
   Begin VB.Image Image1 
      Height          =   1215
      Left            =   360
      Picture         =   "SignIn.frx":1D41
      Top             =   360
      Width           =   1215
   End
   Begin VB.Label Label14 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Filename:"
      Height          =   495
      Left            =   600
      TabIndex        =   31
      Top             =   3480
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label Label8 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Date:"
      Height          =   495
      Left            =   600
      TabIndex        =   30
      Top             =   4680
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label Label13 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Field of Study:"
      Height          =   855
      Left            =   4920
      TabIndex        =   13
      Top             =   4080
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label Label5 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Student ID:"
      Height          =   495
      Left            =   3960
      TabIndex        =   3
      Top             =   5760
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
      TabIndex        =   27
      Top             =   6360
      Visible         =   0   'False
      Width           =   3855
   End
   Begin VB.Label Label12 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Last Name:"
      Height          =   495
      Left            =   600
      TabIndex        =   11
      Top             =   6720
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label Label11 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Middle Init.:"
      Height          =   495
      Left            =   600
      TabIndex        =   9
      Top             =   6120
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label Label10 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "First Name:"
      Height          =   495
      Left            =   600
      TabIndex        =   7
      Top             =   5520
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label Label9 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Student Id:"
      Height          =   495
      Left            =   600
      TabIndex        =   5
      Top             =   4080
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblInstructions 
      BackStyle       =   0  'Transparent
      Caption         =   "Initializing, loading background, opening database..."
      Height          =   2655
      Left            =   600
      TabIndex        =   1
      Top             =   2400
      Width           =   10695
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
      TabIndex        =   25
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
      TabIndex        =   24
      Top             =   1320
      Width           =   3375
   End
   Begin VB.Label Label4 
      BackStyle       =   0  'Transparent
      BorderStyle     =   1  'Fixed Single
      Height          =   5295
      Left            =   480
      TabIndex        =   28
      Top             =   2280
      Width           =   11175
   End
   Begin prgSignIn.DimmedBg ctlDimmed 
      Height          =   5295
      Left            =   480
      Top             =   2280
      Width           =   11175
      _ExtentX        =   1085
      _ExtentY        =   1296
   End
   Begin prgSignIn.DimmedBg ctlAbout 
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
      TabIndex        =   23
      Top             =   120
      Width           =   11655
   End
End
Attribute VB_Name = "frmSignIn"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'By Peekin, 2000.1.29-2001.3.12
'Chemeketa Open Lab Sign In
'
'2001.1.29 4 1/2 hours ;)
'2001.1.30 4
'...and here I lose track of time...
'2001.3.1  4
'2001.3.2  1
'2001.3.7  3
'
'Something to look into:
'It might be simpler to scan your student ID card than type in numbers.
'A small free device call CueCat from Radio Shack could be the solution.
'http://www.radioshack.com/Partners/CAT/FAQ/RSCATFAQGateway.asp
Option Explicit

'Private Declare Function BitBlt Lib "GDI32" (ByVal hDestDC As Long, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal dwRop As Long) As Long
'Private Declare Function SendMessage Lib "USER32" Alias "SendMessageA" (ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Long) As Long
Private Declare Function GetTickCount Lib "kernel32" () As Long
Private Declare Function GetKeyboardState Lib "user32" (pbKeyState As Byte) As Long
Private Declare Function SetKeyboardState Lib "user32" (lppbKeyState As Byte) As Long
'Const CB_SHOWDROPDOWN = &H14F

Dim ErrorCurrently As Boolean, CurrentPage As Long
Dim TotalStudentNumbers As Long
Dim Db As Database, DbRs As Recordset, DbIsOpen As Boolean
Dim StudentName As String, StudentLastUse As Date, StudentMsg As String
Dim SqlUpdateStatement As String
Dim DbFilename As String
Dim DbErrMsg As String
Dim BgFilename As String
Dim ErrorDisplayTime As Long
Dim EditingSid As Boolean

Const CurPageMenu = 0
Const CurPageSignIn = 1
Const CurPageSubmit = 2
Const CurPageSignedIn = 3
Const CurPageSignOut = 4
Const CurPageSignedOut = 5
Const CurPageEditInfo = 6
Const CurPageDelRecords = 7
Const CurPageSetDbFile = 8
Const CurPageReSubmit = 9
Const CurPageChgBkg = 10

Const SignStatusOut = 0
Const SignStatusIn = 1
Const SignStatusForgot = 2
Const SignStatusNewTerm = 3

Const DbFilenameDef = "StudentLog.mdb"
Const BgFilenameDef As String = "Parlokia.jpg" 'default background image

Const AverageDuration = 0.04167 'average duration for students using lab, 1/24 or one hour

Const MaxMsgDuration As Long = 22000 'clear error message after 22 seconds
Const MinMsgDuration As Long = 2000  'ensure students read message!

Const DimmedColor = &HB0B0B0

Private Sub Form_Load()
    Dim Page As Long, CurDate As String

    Show        'let people know what's happening so that the delay
    DoEvents    'does not seem so long and mysterious

    Select Case Command$
    Case "in": Page = CurPageSignIn
    Case "out": Page = CurPageSignOut
    End Select

    lstActions.ListIndex = 0
    CurDate = Date$
    txtDate.Text = Mid(CurDate, 7, 4) & "-" & Mid(CurDate, 1, 2) & "-" & Mid(CurDate, 4, 2)

    filBgs.Path = App.Path
    GetSetting "StudentSignIn", "Startup", "Bg", BgFilename
    If Len(BgFilename) <= 0 Then BgFilename = App.Path & "\" & BgFilenameDef
    Picture = LoadPicture(BgFilename)
    ctlDimmed.DimThis frmSignIn.hdc, ctlDimmed, DimmedColor

    'assume we're not in the root directory
    DbFilename = App.Path & "\" & DbFilenameDef
    OpenDbTable "tblStudents"
    If Not DbIsOpen Then
        ChangePage CurPageSetDbFile
        SetErrorMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, cmdSetDbFile
    Else
        ChangePage Page
    End If
    CorrectKeyStates

End Sub

Private Sub cmdSignIn_Click()
'check if student number exists
'if student exists
'   if student already logged in
'       display error
'   else
'       if first time this term
'         verify information from previous term
'       else
'         just sign in student
'       endif
'   endif
'else (student does not exist)
'   let student fill in info
'   don't forget to fill out the paperwork
'endif
'don't forget to display your student ID
    Dim Status As Byte

    If ErrorCurrently Then msgError_CloseMe: Exit Sub

    txtStudentId.SetFocus
    If Len(txtStudentId.Text) < 9 Then
        SetErrorMsg "Your student ID is the nine digit number on the back of your card (usually the same as your social security number)", txtStudentId
        HighlightTextPrompt txtStudentId
        Exit Sub
    End If

    OpenDbTable "tblStudents"
    If Not DbIsOpen Then
        SetErrorMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, cmdSignIn
        Exit Sub
    End If
    datStudents.Recordset.FindFirst "SID=" & txtStudentId.Text
    'datStudents.Recordset.Seek "=", Val(txtStudentId.Text)
    ' Help says that 'Seek' is faster, but an error is displayed
    ' when it is used that says "operation not supported".

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
    '
    If Not datStudents.Recordset.NoMatch Then
        With datStudents
            Status = .Recordset("Status")
            StudentName = .Recordset("FirstName")
            'StudentMsg = .Recordset("Msg")
        End With
    End If
    If CurrentPage = CurPageSignIn Then
        If datStudents.Recordset.NoMatch Then
            'no students with that SID, must be a new student
            txtFirstName.Text = ""
            txtLastName.Text = ""
            txtMiddleName.Text = ""
            lstProgramId.ListIndex = 0

            ChangePage CurPageSubmit
            txtFirstName.SetFocus
        ElseIf Status = SignStatusNewTerm Then 'returning student
            'new term, so verify previous information
            GetStudentInformation
            ChangePage CurPageReSubmit
            HighlightTextPrompt txtFirstName
            HighlightTextPrompt txtMiddleName
            HighlightTextPrompt txtLastName
            txtFirstName.SetFocus
        Else 'same term
            StudentLastUse = datStudents.Recordset("LastUse")
            'if time difference between sign in's was < default time
            'which was figured to be about an hour,
            'then do not bother creating new record
            If Status <> SignStatusIn Or Now - StudentLastUse > AverageDuration Then
                SignForgottenSidOut
                SignSidIn
            End If
            ChangePage CurPageSignedIn
            If Status = SignStatusOut Then
                'everything okay, remembered to sign out last time
                SetTimeOut
                'It would convenient to display a message to an individual
                'student if you needed to tell him/her that they left behind
                'their student ID card or perhaps a disk
                'If Len(Msg) Then
                '   OpenDbTable "tblStudents"
                '   .recordset.edit
                '   .Recordset("Msg") = ""
                '   .recordset.update
                'end if
            Else
                'either still signed in or forgot to log out day they used the lab
                SetErrorMsg "Our records show that you didn't sign out the last time you used the lab, " & GetTimeDifMsg(Now - StudentLastUse) & ". Please remember to sign out when you are finished.", cmdContinue
                'SetErrorMsg "Our records show that you didn't sign out the last time you used the lab. Please remember to sign out when you are finished.", cmdContinue
            End If
        End If
    Else 'CurrentPage = CurPageSignOut
        If datStudents.Recordset.NoMatch Then
            'no students with that SID, must have typed wrong number
            SetErrorMsg "The student ID number entered does not match any currently signed in students. Make sure that it was entered correctly.", txtStudentId
            HighlightTextPrompt txtStudentId
        Else
            If Status = SignStatusIn Then
                'signed in properly
                SignSidOut
                ChangePage CurPageSignedOut
                SetTimeOut
            Else
                'forgot to sign in
                SetErrorMsg "You are already signed out. If you did not sign in before using the lab, please remember to do so next time.", txtStudentId
            End If
            txtStudentId.Text = ""
        End If
    End If
End Sub

Private Sub cmdSignIn_KeyPress(KeyAscii As Integer)
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
    If lstProgramId.ListIndex <= 0 Then
        SetErrorMsg "Please select your field of study from the list.", lstProgramId
        lstProgramId.SetFocus
        Exit Sub
    End If

    OpenDbTable "tblStudents"
    If Not DbIsOpen Then
        SetErrorMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, cmdSubmit
        Exit Sub
    End If

    'add new record filled with student information
    With datStudents
        .Recordset.FindFirst "SID=" & txtStudentIdLocked.Text
        'if student already exists, resubmit, otherwise create new
        If .Recordset.NoMatch Then
            .Recordset.AddNew
        Else
            .Recordset.Edit
        End If
        .Recordset("SID") = txtStudentIdLocked.Text
        StudentName = txtFirstName.Text
        .Recordset("FirstName") = StudentName
        .Recordset("LastName") = txtLastName.Text
        .Recordset("MiddleName") = txtMiddleName.Text
        .Recordset("PID") = Val(lstProgramId.Text)
        '.Recordset("Msg") = "" 'unnecessary
        StudentName = .Recordset("FirstName")

        .Recordset.Update
        'if new record was added, move to record
        'in my opinion, the record pointer should be automatically
        'moved to the new record so this silly test does not have
        'to be done.
        If .Recordset.NoMatch Then datStudents.Recordset.MoveLast
    End With

    If CurrentPage = CurPageSubmit Or CurrentPage = CurPageReSubmit Then
        'sign in student now
        SignSidIn
        ChangePage CurPageSignedIn
        imgRegForm.Visible = True
        'msgError.GrabAttention
        SetErrorMsg "This is the first time you have signed in this term, so don't forget to fill in the paperwork too.", imgRegForm
    ElseIf CurrentPage = CurPageEditInfo Then
        'simply change information, blank fields, do not sign student in
        txtStudentIdLocked.Text = ""
        txtStudentIdLocked.SetFocus
        SetErrorMsg "Changed information for " & txtFirstName.Text & " " & txtLastName.Text, cmdSubmit
        txtFirstName.Text = ""
        txtMiddleName.Text = ""
        txtLastName.Text = ""
        lstProgramId.ListIndex = 0
    End If
    SetTimeOut
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

'prevent those annoying people from turning on Caps Lock and turn off Num Lock
Private Sub CorrectKeyStates()
    Const VK_NUMLOCK = &H90, VK_SCROLL = &H91, VK_CAPITAL = &H14
    Dim Keys(255) As Byte

    GetKeyboardState Keys(0)
    Keys(VK_NUMLOCK) = 1
    Keys(VK_CAPITAL) = 0
    SetKeyboardState Keys(0)
End Sub

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
    .Text = Text
End With

End Sub

Private Sub SignSidIn()
'changes student status to signed in and refreshes date of last use
'add sign-in record to usage log
'this routine expects that the current record pointer is already
'set to the student that is signing in.
    Dim Pid As Integer, dateSignIn As Date
    dateSignIn = Now

    'opendbtable "tblstudents"
    'change status of student to currently logged in
    'update last sign in time
    With datStudents
        .Recordset.Edit
        .Recordset("Status") = SignStatusIn 'signed in now
        .Recordset("LastUse") = dateSignIn
        Pid = Val(.Recordset("PID"))
        .Recordset.Update
    End With

    'add entry to usage log
    OpenDbTable "tblUsage"
    With datStudents
        .Recordset.AddNew
        .Recordset("SID") = txtStudentIdLocked.Text
        .Recordset("SignIn") = dateSignIn
        'leave SignOut null for now to indicate not signed out yet
        .Recordset("PID") = Pid
        .Recordset.Update
    End With
End Sub

Private Sub SignSidOut()
'changes student status to signed out and refreshes date of last use
'completes sign-in record in usage log
'this routine expects that the current record pointer is already
'set to the student that is signing in.
    Dim dateSignOut As Date
    dateSignOut = Now

    'opendbtable "tblstudents"
    'change status of student to currently logged out
    With datStudents
        .Recordset.Edit
        .Recordset("Status") = SignStatusOut 'signed out now
        .Recordset("LastUse") = dateSignOut
        .Recordset.Update
    End With

    'add entry to usage log
    OpenDbTable "tblUsage"
    With datStudents
        'seek backwards for most recent sign in record
        'since new records are always appended to previous ones, it's faster
        'to search from the back than front
        .Recordset.FindLast "SID=" & txtStudentIdLocked.Text & "AND Duration IS NULL"
        If Not .Recordset.NoMatch Then
            .Recordset.Edit
            .Recordset("SignOut") = dateSignOut
            .Recordset("Duration") = dateSignOut - .Recordset("SignIn")
            .Recordset.Update
        End If
    End With

    'Originally I wanted to let students know how many hours they have
    'been using the lab, but since VB only gives me an annoyingly cryptic
    'error (object variable not set), I guess I won't! :Þ
    'With datStudents
    'datStudents.Database.OpenRecordset ("SELECT SUM(Duration) AS TotalDur FROM tblUsage WHERE SID=" & txtStudentIdLocked.Text & ";")
    'datStudents.Database
    'datStudents.Recordset.MoveFirst
    'datStudents.Recordset.OpenRecordset ("SELECT SUM(Duration) AS TotalDur FROM tblUsage WHERE SID=" & txtStudentIdLocked.Text & ";")
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
SetErrorMsg "Logging out all students who forget to sign out...", lstActions
DoEvents
ExecSql "UPDATE tblStudents SET tblStudents.Status=" & SignStatusForgot & " WHERE tblStudents.Status=" & SignStatusIn & ";"
ExecSql "UPDATE tblUsage SET Duration=" & AverageDuration & " WHERE Duration IS NULL;"
If DbIsOpen Then
    SetErrorMsg "Signed out " & datStudents.Database.RecordsAffected & " students who forgot to", lstActions
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
'assumes the current recordset is the student who's SID
'matches what is in the text prompt.
    Dim Count As Long, Pid As String

    With datStudents
        txtFirstName.Text = .Recordset("FirstName")
        txtLastName.Text = .Recordset("LastName")
        txtMiddleName.Text = .Recordset("MiddleName")
        Pid = .Recordset("PID")
    End With
    'get program id
    For Count = 0 To lstProgramId.ListCount - 1
        If Left(lstProgramId.List(Count), 3) = Pid Then
            lstProgramId.ListIndex = Count
            Exit For
        End If
    Next
End Sub

Private Sub cmdBack_Click()
    cmdContinue_Click
End Sub

Private Sub cmdContinue_Click()
    Dim Page As Long, Duration As Long

    Select Case CurrentPage
    Case CurPageSignedIn, CurPageSubmit, CurPageReSubmit
        Page = CurPageSignIn
        If CurrentPage = CurPageSignedIn Then GoSub WaitForMsg
    Case CurPageSignedOut
        Page = CurPageSignOut
        GoSub WaitForMsg
    Case Else
        Page = CurPageMenu
    End Select
    ChangePage Page
    If CurrentPage <> 0 Then txtStudentId.SetFocus
    Exit Sub

WaitForMsg:
'don't allow students to simply ignore message,
'by forcing a minimum reading time
    If ErrorCurrently Then
        'ensure students have read the error message
        Duration = GetTickCount - ErrorDisplayTime
        If Duration < MinMsgDuration Then
            SetTimeOutTo MinMsgDuration - Duration
            Exit Sub
        Else
            ClrErrorMsg
        End If
    End If
Return

End Sub

Private Sub cmdDeleteRecords_Click()
'deletes usage log records from entire term
'deletes old records for students who haven't use the lab for a while
    Dim StudentRecs As Long, UsageRecs As Long

    If MsgBox("Are you really, truly, certainly, absolutely sure?", vbExclamation Or vbYesNo Or vbDefaultButton2, "Delete entire term student usage records") = vbYes Then
        SetErrorMsg "Deleting all student records for those haven't signed in over 180 days...", cmdDeleteRecords
        DoEvents
    
        ExecSql "DELETE * FROM tblStudents WHERE [LastUse]+180<Now;"
        If Not DbIsOpen Then
            SetErrorMsg "Could not execute SQL deletion statement!" & vbNewLine & DbErrMsg, cmdDeleteRecords
        Else
            StudentRecs = datStudents.Database.RecordsAffected
            ExecSql "UPDATE tblStudents SET tblStudents.Status=" & SignStatusNewTerm & ";"
            ExecSql "DELETE * FROM tblUsage;"
            UsageRecs = datStudents.Database.RecordsAffected
            SetErrorMsg "Deleted " & StudentRecs & " student records, reset everyone's status for new term, and cleared " & UsageRecs & " sign in records.", cmdDeleteRecords
        End If
        'CompactDatabase
    End If
End Sub

Private Sub ChangePage(Page As Long)
'the huge routine responsible for changing pages, setting certain controls
'visible, other invisible, setting default command button
    Dim PageVisible As Boolean

    If ErrorCurrently Then ClrErrorMsg
    CurrentPage = Page

    Select Case Page
    Case CurPageMenu: lblInstructions.Caption = "Double click on the action below in the list or press Enter."
    Case CurPageSignIn: lblInstructions.Caption = "Before using any of the computer equipment in this room, please enter your student ID number." & vbNewLine & vbNewLine & "Remember to sign out at the Sign-Out station before leaving. Thank you :-)"
         cmdSignIn.Caption = "Sign In"
    Case CurPageSubmit: lblInstructions.Caption = "We do not currently have you in our system. Please enter the following information, or click <Back> if you made a typing mistake."
    Case CurPageSignedIn
         lblInstructions.Caption = "You are signed in, " & StudentName & ". You can choose any free computer, put up your student ID card, and start working. Don't forget to sign out when you are done."
         If Len(StudentMsg) Then lblInstructions.Caption = StudentMsg & vbNewLine & vbNewLine & lblInstructions.Caption
    Case CurPageSignOut: lblInstructions.Caption = "Please remember to sign out before leaving the lab."
         cmdSignIn.Caption = "Sign Out"
    Case CurPageSignedOut: lblInstructions.Caption = "You are signed out, " & StudentName & ". Don't forget your student ID card."
    Case CurPageEditInfo: lblInstructions.Caption = "Enter the student ID number to change the information for."
    Case CurPageDelRecords: lblInstructions.Caption = "Clicking Delete will remove all records of students who have not signed in for over 180 days, delete all sign in/out logs for the current term, and reset student records for a new term."
    Case CurPageSetDbFile: lblInstructions.Caption = "Enter the full path and filename to the current student database."
    Case CurPageReSubmit: lblInstructions.Caption = "Is all this information from a previous term still correct?"
    Case CurPageChgBkg: lblInstructions.Caption = "Double click on the desired background. Click Back for main menu."
    End Select

    'main choice page
    PageVisible = (Page = CurPageMenu)
    lstActions.Visible = PageVisible

    'show student id text field for both sign in and out
    PageVisible = (Page = CurPageSignIn) Or (Page = CurPageSignOut)
    Label5.Visible = PageVisible
    Label6.Visible = PageVisible
    txtStudentId.Visible = PageVisible
    cmdSignIn.Visible = PageVisible
    cmdSignIn.Default = PageVisible

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
    lstProgramId.Visible = PageVisible
    cmdSubmit.Visible = PageVisible
    cmdSubmit.Default = PageVisible
    txtDate.Visible = PageVisible
    imgRegForm.Visible = False

    PageVisible = PageVisible Or (Page = CurPageDelRecords) Or (Page = CurPageSetDbFile) Or (Page = CurPageChgBkg)
    cmdBack.Visible = PageVisible Or (Page = CurPageDelRecords)
    cmdBack.Cancel = PageVisible Or (Page = CurPageDelRecords)

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
    cmdChangeBg.Visible = PageVisible
    cmdChangeBg.Default = PageVisible

    'show continue button for both sign in and out acknowledgment
    PageVisible = (Page = CurPageSignedIn) Or (Page = CurPageSignedOut)
    cmdContinue.Visible = PageVisible
    cmdContinue.Default = PageVisible
    cmdContinue.Cancel = PageVisible

    'delete records
    cmdDeleteRecords.Visible = (Page = CurPageDelRecords)
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
    If ErrorCurrently Then ClrErrorMsg
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
    msgError.SetPicMsg "Chemeketa Open Lab Sign-In program, by Dwayne Robinson on 2001-01-30" & vbNewLine & vbNewLine & "Thanks to Daniel, Brian, Luke, Leanne, Linda, Susan, Shay, and Shirley for suggestions and input. Greets to Vahan, Shawn, Jim, Cliff, my cool cousin Russell, loving mom, grumpy dad, and beautiful Jessica..."
    msgError.Top = (ScaleHeight - msgError.Height) \ 2
    msgError.Left = (ScaleWidth - msgError.Width) \ 2
    msgError.Visible = True
    ErrorCurrently = True 'not actually an error, but every other instance of this message is an error
End Sub

Private Sub lstActions_DblClick()
'main menu
    Select Case lstActions.ListIndex
    Case 0: ChangePage CurPageSignIn
    Case 1: ChangePage CurPageSignOut
    Case 2: txtStudentIdLocked.Text = ""
            txtFirstName.Text = ""
            txtLastName.Text = ""
            txtMiddleName.Text = ""
            lstProgramId.ListIndex = 0
            ChangePage CurPageEditInfo
            txtStudentIdLocked.SetFocus
    Case 3: ChangePage CurPageChgBkg
            filBgs.SetFocus
    Case 4: ChangePage CurPageSetDbFile
            txtDbFilename.SetFocus
    Case 5: ChangePage CurPageDelRecords
    Case 6: 'used at the end of the day when lab closes and and all students
            'should have logged out. Of course, you can always depend on a
            'certain number of them who have not.
            SignAllSidsOut
    Case 7: Unload Me
    End Select
End Sub

Private Sub lstActions_KeyPress(KeyAscii As Integer)
'pressing Enter same as double clicking
    If KeyAscii = vbKeyReturn Then lstActions_DblClick
End Sub

Private Sub msgError_CloseMe()
'close error message if user clicked on it
    ClrErrorMsg
End Sub

Private Sub tmrContinue_Timer()
'only display error messages and sign in/out messages for so long
    tmrContinue.Enabled = False
    If ErrorCurrently Then ClrErrorMsg

    Select Case CurrentPage
    Case CurPageSignedIn: CurrentPage = CurPageSignIn
    Case CurPageSignedOut: CurrentPage = CurPageSignOut
    End Select
    ChangePage CurrentPage
End Sub

Private Sub SetTimeOut()
    SetTimeOutTo MaxMsgDuration
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

'Private Sub txtPage_Change()
''solely for debugging
'    ChangePage Val(txtPage.Text)
'    HighlightTextPrompt  txtPage
'End Sub

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

Private Sub SetErrorMsg(Text As String, ErrorField As Object)
'set an error message relative to some window control
'usually the button or text field which the error is related to
    Dim MsgTop As Long, MsgLeft As Long
    Dim MsgHeight As Long, MsgWidth As Long

    msgError.SetMsg Text
    MsgTop = ErrorField.Top - (msgError.Height - ErrorField.Height) \ 2
    MsgLeft = ErrorField.Left - msgError.Width
    If MsgLeft < 0 Then MsgLeft = ErrorField.Left + ErrorField.Width
    If MsgLeft > ScaleWidth - msgError.Width Then MsgLeft = ScaleWidth - msgError.Width
    If MsgTop < 0 Then MsgTop = 0 Else If MsgTop + msgError.Height > ScaleHeight Then MsgTop = ScaleHeight - msgError.Height
    msgError.Top = MsgTop
    msgError.Left = MsgLeft
    msgError.Visible = True
    SetTimeOut
    ErrorDisplayTime = GetTickCount
    ErrorCurrently = True
End Sub

Private Sub ClrErrorMsg()
        msgError.Visible = False
        'msgError.NormalAttention
        ErrorCurrently = False
End Sub

Public Sub OpenDbTable(Table As String)
    'attempt open database, catching those annoying errors!
    On Error GoTo OpenDbErr
    datStudents.DatabaseName = DbFilename
    datStudents.RecordSource = Table
    datStudents.Refresh
    DbIsOpen = True
    Exit Sub

OpenDbErr:
    datStudents.DatabaseName = ""
    DbErrMsg = Err.Description
    DbIsOpen = False
    Exit Sub

End Sub

Private Sub ExecSql(Sql As String)
    'attempt to execute SQL statement, catching those annoying errors!
    On Error GoTo OpenDbErr
    datStudents.DatabaseName = DbFilename
    datStudents.Database.Execute Sql, dbFailOnError
    DbIsOpen = True
    Exit Sub

OpenDbErr:
    datStudents.DatabaseName = ""
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
            datStudents.Recordset.FindFirst "SID=" & Val(txtStudentIdLocked.Text)
            If Not datStudents.Recordset.NoMatch Then
                GetStudentInformation
                HighlightTextPrompt txtFirstName
                HighlightTextPrompt txtMiddleName
                HighlightTextPrompt txtLastName
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
