VERSION 5.00
Begin VB.Form frmGateway 
   AutoRedraw      =   -1  'True
   BackColor       =   &H80000010&
   BorderStyle     =   0  'None
   Caption         =   "Open Lab Sign-In"
   ClientHeight    =   8775
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
   ScaleHeight     =   585
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   800
   ShowInTaskbar   =   0   'False
   WindowState     =   2  'Maximized
   Begin prjSignIn.msgWindow msgWindow 
      Height          =   255
      Left            =   720
      Top             =   8520
      Visible         =   0   'False
      Width           =   495
      _ExtentX        =   873
      _ExtentY        =   450
   End
   Begin VB.CommandButton cmdChoose 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Choose"
      Height          =   600
      Left            =   3960
      Style           =   1  'Graphical
      TabIndex        =   41
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.ListBox lstPurposes 
      BackColor       =   &H00E0F0F8&
      Height          =   3105
      ItemData        =   "Gateway.frx":0442
      Left            =   3000
      List            =   "Gateway.frx":0449
      Sorted          =   -1  'True
      TabIndex        =   40
      Top             =   3720
      Visible         =   0   'False
      Width           =   5535
   End
   Begin VB.CommandButton cmdDefBg 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Default"
      Height          =   600
      Left            =   7800
      Style           =   1  'Graphical
      TabIndex        =   19
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.TextBox txtBgFilename 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   5280
      TabIndex        =   37
      Top             =   6840
      Visible         =   0   'False
      Width           =   6135
   End
   Begin VB.TextBox txtStudentMsg 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   2760
      TabIndex        =   4
      ToolTipText     =   "An optional message you can show to a specific student the next time he/she signs in"
      Top             =   4800
      Visible         =   0   'False
      Width           =   3015
   End
   Begin VB.TextBox txtLastName 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   2760
      TabIndex        =   9
      Top             =   6720
      Visible         =   0   'False
      Width           =   3015
   End
   Begin VB.TextBox txtMiddleName 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   2760
      TabIndex        =   7
      Top             =   6120
      Visible         =   0   'False
      Width           =   3015
   End
   Begin VB.TextBox txtFirstName 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   2760
      TabIndex        =   5
      Top             =   5520
      Visible         =   0   'False
      Width           =   3015
   End
   Begin VB.TextBox txtStudentId 
      BackColor       =   &H00E0F0F8&
      Height          =   495
      IMEMode         =   3  'DISABLE
      Left            =   5520
      MaxLength       =   9
      PasswordChar    =   "*"
      TabIndex        =   33
      Top             =   6000
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.TextBox txtDate 
      BackColor       =   &H00E0F0F8&
      Enabled         =   0   'False
      Height          =   495
      Left            =   5520
      TabIndex        =   29
      Text            =   "[date]"
      Top             =   5400
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.ListBox lstPids 
      BackColor       =   &H00E0F0F8&
      Height          =   3105
      ItemData        =   "Gateway.frx":0464
      Left            =   6720
      List            =   "Gateway.frx":046B
      Sorted          =   -1  'True
      TabIndex        =   10
      Top             =   4080
      Visible         =   0   'False
      Width           =   4575
   End
   Begin VB.DriveListBox drvBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   600
      TabIndex        =   34
      Top             =   3000
      Visible         =   0   'False
      Width           =   4575
   End
   Begin VB.TextBox txtStudentIdLocked 
      BackColor       =   &H00E0F0F8&
      Enabled         =   0   'False
      Height          =   495
      IMEMode         =   3  'DISABLE
      Left            =   2760
      MaxLength       =   9
      PasswordChar    =   "*"
      TabIndex        =   27
      Text            =   "123456789"
      Top             =   4080
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Timer tmrMsgClear 
      Interval        =   22000
      Left            =   3480
      Top             =   8160
   End
   Begin VB.TextBox txtPage 
      Height          =   555
      Left            =   0
      TabIndex        =   11
      Top             =   8280
      Visible         =   0   'False
      Width           =   495
   End
   Begin VB.ListBox lstActions 
      BackColor       =   &H00E0F0F8&
      Height          =   3540
      ItemData        =   "Gateway.frx":0489
      Left            =   3960
      List            =   "Gateway.frx":04A5
      TabIndex        =   32
      Top             =   3360
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
   Begin VB.FileListBox filBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   3570
      Hidden          =   -1  'True
      Left            =   5280
      Pattern         =   "*.jpg;*.bmp;*.gif;*.wmf"
      TabIndex        =   36
      Top             =   3000
      Visible         =   0   'False
      Width           =   6135
   End
   Begin VB.DirListBox dirBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   3810
      Left            =   600
      TabIndex        =   35
      Top             =   3600
      Visible         =   0   'False
      Width           =   4575
   End
   Begin VB.CommandButton cmdSubmit 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Submit"
      Height          =   600
      Left            =   3960
      Style           =   1  'Graphical
      TabIndex        =   15
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdSignInOut 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Sign In/Out"
      Height          =   600
      Left            =   4680
      Style           =   1  'Graphical
      TabIndex        =   12
      TabStop         =   0   'False
      Top             =   7920
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.CommandButton cmdUpdate 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Update"
      Height          =   600
      Left            =   3960
      Style           =   1  'Graphical
      TabIndex        =   23
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdBack 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Back"
      Height          =   600
      Left            =   5880
      Style           =   1  'Graphical
      TabIndex        =   18
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdSetDbFile 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Set File"
      Height          =   600
      Left            =   3960
      Style           =   1  'Graphical
      TabIndex        =   31
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdDeleteRecords 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Delete"
      Height          =   600
      Left            =   3960
      Style           =   1  'Graphical
      TabIndex        =   13
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdChangeBg 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Change"
      Height          =   600
      Left            =   2040
      Style           =   1  'Graphical
      TabIndex        =   16
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CheckBox chkPreview 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Preview"
      Height          =   600
      Left            =   3960
      Style           =   1  'Graphical
      TabIndex        =   17
      Top             =   7920
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.Image imgDefBg 
      Height          =   2400
      Left            =   8280
      Picture         =   "Gateway.frx":052A
      Top             =   10320
      Visible         =   0   'False
      Width           =   2400
   End
   Begin VB.Label Label3 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Message"
      Height          =   495
      Left            =   600
      TabIndex        =   39
      Top             =   4800
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Image imgPreview 
      Height          =   3600
      Left            =   600
      Top             =   3000
      Visible         =   0   'False
      Width           =   4500
   End
   Begin VB.Image imgForgotSignOut 
      Height          =   1200
      Left            =   9840
      Picture         =   "Gateway.frx":0EA4
      Top             =   9000
      Visible         =   0   'False
      Width           =   840
   End
   Begin VB.Image imgDbErr 
      Height          =   1050
      Left            =   10680
      Picture         =   "Gateway.frx":1638
      Top             =   9120
      Visible         =   0   'False
      Width           =   1065
   End
   Begin VB.Image imgBye 
      Height          =   1320
      Left            =   9000
      Picture         =   "Gateway.frx":1D98
      Top             =   9000
      Visible         =   0   'False
      Width           =   960
   End
   Begin VB.Image imgHello 
      Height          =   1200
      Left            =   8160
      Picture         =   "Gateway.frx":2580
      Top             =   9000
      Visible         =   0   'False
      Width           =   840
   End
   Begin VB.Label Label13 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Program:"
      Height          =   495
      Left            =   4920
      TabIndex        =   38
      Top             =   4080
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.Image imgMyMascot 
      Height          =   2895
      Left            =   600
      Picture         =   "Gateway.frx":2D14
      Top             =   9000
      Visible         =   0   'False
      Width           =   1470
   End
   Begin VB.Image Image1 
      Height          =   1215
      Left            =   360
      Picture         =   "Gateway.frx":5CBC
      Top             =   360
      Width           =   1215
   End
   Begin VB.Label Label14 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Filename:"
      Height          =   495
      Left            =   600
      TabIndex        =   30
      Top             =   3480
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label Label8 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Current Date"
      Height          =   495
      Left            =   3360
      TabIndex        =   28
      Top             =   5400
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label Label5 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Student ID"
      Height          =   495
      Left            =   3480
      TabIndex        =   2
      Top             =   6000
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label Label6 
      BackStyle       =   0  'Transparent
      Caption         =   "(Either your social security number or K-number)"
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
      Left            =   3240
      TabIndex        =   24
      Top             =   6600
      Visible         =   0   'False
      Width           =   5055
   End
   Begin VB.Label Label12 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Last Name"
      Height          =   495
      Left            =   600
      TabIndex        =   8
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
      TabIndex        =   6
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
      TabIndex        =   26
      Top             =   4080
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label lblInstructions 
      BackStyle       =   0  'Transparent
      Caption         =   "Initializing, loading background, opening database..."
      Height          =   2655
      Left            =   480
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
      TabIndex        =   22
      Top             =   8880
      Width           =   345
   End
   Begin VB.Label lblSubtitle 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
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
      Height          =   855
      Left            =   3600
      TabIndex        =   21
      Top             =   1320
      Width           =   4455
   End
   Begin VB.Label lblConcave 
      BackStyle       =   0  'Transparent
      BorderStyle     =   1  'Fixed Single
      Height          =   5295
      Left            =   360
      TabIndex        =   25
      Top             =   2280
      Width           =   11295
   End
   Begin prjSignIn.DimmedBg ctlDimmed 
      Height          =   5295
      Left            =   360
      Top             =   2280
      Width           =   11295
      _ExtentX        =   19923
      _ExtentY        =   9340
   End
   Begin VB.Label lblTitle 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   42.75
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0D0&
      Height          =   1215
      Left            =   1560
      TabIndex        =   0
      Top             =   360
      Width           =   10335
   End
   Begin VB.Label lblTitleShadow 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "Forte"
         Size            =   42
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00202020&
      Height          =   1215
      Left            =   1560
      TabIndex        =   20
      Top             =   480
      Width           =   10335
   End
   Begin VB.Image imgRegForm 
      Height          =   3495
      Left            =   2160
      Picture         =   "Gateway.frx":67FE
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
'By Peekin, 2001-01-29:2002-02-04
'Chemeketa Open Lab Sign In
'Also adapted to tutoring center and college access programs
'
'Conditional compiling is great (assemblers have had it forever!)
'But too bad it does not also apply to control text. Instead I
'need a separate settings file for all the text.
'
'Note that any pseudocode left in here is simply for reference.
'The actual code may no longer reflect that structure.
'
'This single form is the same form for several different labs,
'shared so that updates to one benefits all the others.
'
'Open Lab - single PIDS, fed sheet
'Tutoring Center - multiple PIDs, fed sheet
'College Access - single PIDS, fed sheet
'Clerical Basics - single PIDs, no fed sheet
'
'When you look at the form, you may see what seems to be a total
'mess. Yes, frames would have somewhat organized controls within
'them, but (1) controls common to more than one frame can only
'be used in ONE frame and (2) it is harder to reach a control
'to resize or move it when buried within layers of frames.
'
'Not quite 2000 lines of code yet.
'Guess I'll have to keep on adding to it.
'
'Todo:
' Prevent network error crashes
'
'
'History:
'2001-01-29  4 1/2 hours ;)
'2001-01-30  4
'...and here I lose track of time...
'  (suffice to say, way too much)
'2001-03-01  4
'2001-03-02  1
'2001-03-07  3
'...program sufficiently complete for now
'
'2001-10-24 Added K number support
'           Now works in Win2k, without need of VB service pack 4
'           Uses database object instead of dumb data control
'           Should be a little faster (slightly)
'           Sign in/out messages displayed in brightly colored rectangles
'             instead of switching to separate screen pages.
'           Error messages can include pictures now
'2001-11-09 Nearly all messages now show kawaii characters for pleasantness
'           That way the "you forgot to sign out" message isn't so bland
'           Added a database innaccessible / network error message
'2002-01-15 Automatically logs out forgetful people if program was not shut
'           down properly the previous day
'2002-01-25 Put date text field on main sign page
'           Included default background, purple mist
'           Added background preview and text prompt to type filename
'           Changed msgWindow to use all pixels (instead of retarded twips)
'           Deleting old records also compacts and repairs the database
'2002-02-15 Demonstration/meeting with director of student services.
'2002-02-22 Add minor changes to database for new PIDs and purposes.
'2002-06-11 Clerical Basics want their own version of this program too.
'2002-08-06 Ok, too many people want this little program (little?)
'           Should store settings in a separate file instead of so many
'           different compilations.
'
Option Explicit

'Private Declare Function BitBlt Lib "GDI32" (ByVal hDestDC As Long, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal dwRop As Long) As Long
'Private Declare Function SendMessage Lib "USER32" Alias "SendMessageA" (ByVal hWnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Long) As Long
Private Declare Function DrawState Lib "user32" Alias "DrawStateA" (ByVal hdc As Long, ByVal hBrush As Long, ByVal lpDrawStateProc As Long, ByVal lParam As Long, ByVal wParam As Long, ByVal n1 As Long, ByVal n2 As Long, ByVal n3 As Long, ByVal n4 As Long, ByVal un As Long) As Long
'Const CB_SHOWDROPDOWN = &H14F

Private Value As Long           'generic variable reused over and over
Private Counter As Long         'another one

Dim CurrentPage As Long         'current page showing
Const CurPageMenu = 0
Const CurPageSignIn = 1
Const CurPageSubmit = 2
Const CurPageGetPurpose = 3
Const CurPageEditInfo = 4
Const CurPageDelRecords = 5
Const CurPageSetDbFile = 6
Const CurPageReSubmit = 7
Const CurPageChgBkg = 8

Dim MessageShown As Long        'a message is displayed
Const MessageShownNone = False
Const MessageShownImportant = 1
Const MessageShownUnimportant = True

Dim BgFilename As String        'background

Dim StudentName As String       'take a guess...
Dim StudentLastUse As Date      'last sign in or sign out
Dim StudentMsg As String        'optional message to display
Dim StudentId As Long           'either SSN or (K number)+1000000000
Dim StudentStatus As Byte       'signed in, signed out, new term...
Dim StudentPid As Long          'selected program id
Dim StudentPurpose As Long      'purpose of last visit
'Dim SqlUpdateStatement As String

Dim EditingSid As Boolean       'in the middle of editing student ID
Dim StudentSignedIn As Boolean  'whether any students hav signed in
Dim ClickingAction As Boolean   'mouse button is down, waiting for release

Const MaxPids = 1000
Dim PidNames(MaxPids - 1) As String
Dim StudentPids(MaxPids - 1) As Boolean


Const MsgSuccessColor = &HC0FFC0
Const MsgErrorColor = &HC0C0FF
Const MsgInformationColor = &HFFC0C0

Const SignStatusOut = 0
Const SignStatusIn = 1
Const SignStatusForgot = 2
Const SignStatusNewTerm = 3

Const ErrMsgDuration As Long = 22000    'clear error message after 22 seconds
Const SuccessMsgDuration As Long = 9000 'clear successful sign in message after
Const ShortMsgDuration As Long = 3000 'clear successful sign in message after
'Const MinMsgDuration As Long = 2000  'ensure students read message!

Const DimmedColor = &HB0B0B0

Dim NoRegForm As Long   'default is to display a form, only true if no form
Dim NeedPurpose  As Long '0-no 1-single 2-multiple

' various messages, customized to each location
Dim WelcomeMsg As String
Dim NewTermMsg As String
Dim NewStudentMsg As String
Dim StudyAreaMsg As String

Private Sub chkPreview_Click()
    Dim PreviewOn As Boolean
    PreviewOn = chkPreview.Value
    imgPreview.Visible = PreviewOn
    drvBgs.Visible = Not PreviewOn
    dirBgs.Visible = Not PreviewOn
    txtBgFilename_Change
    filBgs.SetFocus
End Sub

Private Sub cmdChoose_Click()
    
#If ProgramType = 1 Then
    StudentPid = lstPurposes.ItemData(lstPurposes.ListIndex)
    SignSidIn
    ChangePage CurPageSignIn
    SetPicMsg vbCrLf & "You have been " & vbCrLf & "signed in " & StudentName & vbCrLf, _
        MsgSuccessColor, _
        imgHello.Picture, _
        0, _
        Nothing
    SetMsgDuration ShortMsgDuration 'override default time to shorten

#ElseIf ProgramType = 2 Then
    StudentPurpose = lstPurposes.ItemData(lstPurposes.ListIndex)

    SignSidIn
    ChangePage CurPageSignIn
    If StudentStatus = SignStatusNewTerm Then
        SetPicMsg "You have signed in, but since this is your first time this term, also fill in the paper form.", _
            MsgSuccessColor, _
            imgRegForm.Picture, _
            2, _
            Nothing
    Else
        SetPicMsg vbCrLf & "You have been " & vbCrLf & "signed in " & StudentName & vbCrLf, _
            MsgSuccessColor, _
            imgHello.Picture, _
            0, _
            Nothing
    End If
#End If
End Sub

Private Sub cmdDefBg_Click()
    RedrawBg imgDefBg.Picture
End Sub

Private Sub dirBgs_Change()
    On Error Resume Next
    filBgs.Path = dirBgs.Path
    drvBgs.Drive = dirBgs.Path
    'txtBgFilename.Text = filBgs.Path
End Sub

Private Sub dirBgs_Click()
    txtBgFilename.Text = dirBgs.List(dirBgs.ListIndex)
End Sub

Private Sub dirBgs_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyRight Then filBgs.SetFocus: KeyCode = 0
End Sub

Private Sub drvBgs_Change()
    On Error Resume Next
    dirBgs.Path = drvBgs.Drive
End Sub

Private Sub filBgs_Click()
    txtBgFilename.Text = FixPath(filBgs.Path) & filBgs.FileName
End Sub

Private Sub filBgs_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyLeft Then dirBgs.SetFocus: KeyCode = 0
End Sub

Private Sub Form_KeyPress(KeyAscii As Integer)
    If MessageShown Then ClrErrorMsg
End Sub

Private Sub Form_Load()
    Dim CurDate As String
    Dim Control As Object
    Dim TopOfs As Long, LeftOfs As Long

    ' reposition all objects based on screen size
    Show        'let people know what's happening so that the delay
    TopOfs = (ScaleHeight - 600) \ 2
    LeftOfs = (ScaleWidth - 800) \ 2
    On Error GoTo ObjHasNoPos
    For Each Control In Me
        With Control
        .Top = .Top + TopOfs
        .Left = .Left + LeftOfs
        End With
ObjHasNoPos:
    Next
    On Error GoTo 0
    DoEvents    'so startup doesn't seem so long and mysterious

    LoadSettings
    lblTitle.Caption = ProgramTitle
    lblTitleShadow.Caption = ProgramTitle
    lblTitleShadow.Font.Size = lblTitle.Font.Size - 1
    lblTitleShadow.Font.Name = lblTitle.Font.Name

#If ProgramType = 1 Then
    MsgBox "I lost the original source code to the Tutoring Center version, and haven't rewritten it. So don't expect it to work fully!", vbExclamation, "Warning"
#End If

    lstActions.ListIndex = 0
    CurDate = Format$(Date$, "yyyy-mm-dd")
    txtDate.Text = CurDate

    On Error GoTo EatError
    drvBgs.Drive = AppPath
    dirBgs.Path = AppPath
    filBgs.Path = AppPath

    BgFilename = GetSetting(App.ProductName, "Startup", "BgPic", "")
    If Len(BgFilename) Then
        RedrawBg LoadPicture(BgFilename)
    Else
        RedrawBg imgDefBg.Picture
    End If
    ctlDimmed.DimThis hdc, ctlDimmed, DimmedColor
    txtBgFilename.Text = BgFilename

    'read in PIDs
    OpenDbTable "tblPids"
    DbIsOpen = True
    If Not DbIsOpen Then
        ChangePage CurPageSetDbFile
        SetMsg "Error opening database! (need tblPids)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSetDbFile
    Else
        BuildPidList
        ChangePage CurPageMenu
    End If

    ' sign out all of yesterday's students
    If GetSetting(App.ProductName, "Startup", "PrevUseDate", "") <> CurDate Then
        ' sign out yesterday's people
        ' added this line after learning that my program
        ' wasn't always being shut down properly \_/
        SignAllSidsOut
        SaveSetting App.ProductName, "Startup", "PrevUseDate", CurDate
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

    If MessageShown = MessageShownImportant Then
        SetMsgDuration 500
        'ClrErrorMsg
        Exit Sub
    ElseIf MessageShown Then
        ClrErrorMsg
    End If

    txtStudentId.SetFocus
    If Len(txtStudentId.Text) < 9 Then
        SetMsg "Your student ID can be found on the back of your ID card, and can be either your k-number or social security number. (K12345678 / 123456789)", MsgInformationColor, txtStudentId
        HighlightTextPrompt txtStudentId
        Exit Sub
    End If

    SetMsg "Checking status...", MsgInformationColor, cmdSignInOut
    DoEvents
    OpenDbTable "tblStudents"
    If Not DbIsOpen Then
NetworkError:
        txtStudentId.Text = ""
        'If DbErrNum = 3043 Then
            SetPicMsg vbCrLf & vbCrLf & vbCrLf _
                & "The network is temporarily down..." _
                & vbCrLf & vbCrLf _
                & "Just skip the sign-in and take a computer a computer for now. " _
                & "If you receive the " & Chr$(34) & "hey, you forgot to sign out message" & Chr$(34) & " the next time you sign in, simply disregard it." & vbCrLf & vbCrLf & vbCrLf, _
                MsgErrorColor, _
                imgDbErr.Picture, _
                0, _
                Nothing
            tmrMsgClear.Enabled = False
        'Else
        '    SetMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSignInOut
        'End If
        Exit Sub
    End If
    On Error GoTo NetworkError
    Set StudentTbl = DbTbl
    StudentId = GetNumericSid(txtStudentId.Text)
    StudentTbl.Index = "PrimaryKey"
    StudentTbl.Seek "=", StudentId
    On Error GoTo 0

    'txtStudentIdLocked.Text = txtStudentId.Text 'in case new student
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
    With StudentTbl
    If Not .NoMatch Then
        StudentStatus = .Fields("Status")
        StudentName = .Fields("FirstName")
        StudentLastUse = .Fields("LastUse")
        StudentPid = .Fields("PID")
        StudentMsg = .Fields("Msg")
       #If ProgramType = 2 Then
        StudentPurpose = .Fields("Purpose")
       #End If
    End If
    End With

    If StudentTbl.NoMatch Then
    'no students with that SID, must be a new student
        'MsgBox "new student"
        ClearStudentInformation
        txtStudentIdLocked.Text = txtStudentId.Text
        txtStudentId.Text = ""
        ChangePage CurPageSubmit
        txtFirstName.SetFocus
    ElseIf Len(StudentMsg) Then
    'message waiting for student
        SetMsg StudentMsg & vbCrLf & vbCrLf & "Press Enter to continue.", MsgErrorColor, Nothing
        MessageShown = MessageShownImportant
        With StudentTbl
            .Edit
            .Fields("Msg") = ""
            .Update
        End With
    ElseIf StudentStatus = SignStatusNewTerm Then 'returning student
        txtStudentId.Text = ""
        'new term, so verify previous information
        GetStudentInformation
        ChangePage CurPageReSubmit
        txtFirstName.SetFocus
    ElseIf StudentStatus = SignStatusIn Then 'currently signed in
        txtStudentId.Text = ""
        SignSidOut
        SetPicMsg vbCrLf & "You have been " & vbCrLf & "signed out " & StudentName & vbCrLf, _
            MsgInformationColor, _
            imgBye.Picture, _
            0, _
            Nothing
        SetMsgDuration ShortMsgDuration 'override default time to shorten
        'It would be convenient to display a message to an individual
        'student if you needed to tell him/her that they left behind
        'their student ID card or perhaps a disk
    ElseIf StudentStatus = SignStatusForgot Then 'forgot to sign out
        SetPicMsg "Our records show that you didn't" & vbCrLf _
            & "sign out the last time you visited" & vbCrLf _
            & GetTimeDifMsg(Now - StudentLastUse) & ". Please remember" & vbCrLf _
            & "to sign out when you are finished." & vbCrLf _
            & "Click sign in once more to continue." & vbCrLf & vbCrLf _
            & "If you are certain that you signed out," & vbCrLf _
            & "maybe someone else mistakenly" & vbCrLf _
            & "signed in as you ^_^", _
            MsgErrorColor, _
            imgForgotSignOut, _
            0, _
            cmdSignInOut
        MessageShown = MessageShownImportant
        With StudentTbl
            .Edit
            'StudentStatus = SignStatusOut
            .Fields("Status") = SignStatusOut
            .Update
        End With
        'restore SID
    Else 'If StudentStatus = SignStatusOut Then 'not signed in
        txtStudentId.Text = ""
        If NeedPurpose Then
            GetPurpose
        Else
            SignSidIn
            SetPicMsg vbCrLf & "You have been " & vbCrLf & "signed in " & StudentName & vbCrLf, _
                MsgSuccessColor, _
                imgHello.Picture, _
                0, _
                Nothing
            SetMsgDuration ShortMsgDuration 'override default time to shorten
       End If
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
        SetMsg "The ID number can be found on the back of the student's ID card, and can be either a k-number or social security number.", MsgInformationColor, txtStudentIdLocked
        HighlightTextPrompt txtStudentIdLocked
        txtStudentIdLocked.SetFocus
        Exit Sub
    End If
    If Len(txtFirstName.Text) <= 0 Then
        SetMsg "Please enter a first name.", MsgInformationColor, txtFirstName
        txtFirstName.SetFocus
        Exit Sub
    End If
    'If GetNumericSid(txtFirstName.Text) Then
    '    ChangePage CurPageSignIn
    '    SetMsg "You entered your ID number on the information page.", txtStudentIdLocked, MsgInformationColor
    '    txtStudentId.SetFocus
    '    Exit Sub
    'End If
    If Len(txtLastName.Text) <= 0 Then
        SetMsg "Please enter a last name.", MsgInformationColor, txtLastName
        txtLastName.SetFocus
        Exit Sub
    End If
    If lstPids.ListIndex <= 0 Then
        SetMsg StudyAreaMsg, MsgInformationColor, lstPids
       '"Please select your field of study from the list (your current major)."
       '"Please select the area want help in."
       '"Please select the program you are in."
       '"Please select the area you will be working in from the list."
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
        .Seek "=", StudentId
        'if student already exists, resubmit, otherwise create new
        If .NoMatch Then .AddNew Else .Edit

        .Fields("SID") = StudentId
        StudentName = txtFirstName.Text
        .Fields("FirstName") = StudentName
        .Fields("LastName") = txtLastName.Text
        .Fields("MiddleName") = txtMiddleName.Text
        .Fields("PID") = StudentPid
        .Fields("Msg") = txtStudentMsg.Text
        If .NoMatch Then .Fields("Status") = SignStatusNewTerm
        .Update
        'if new record was added, move to record
        'in my opinion, the record pointer should be automatically
        'moved to the new record so this silly test does not have
        'to be done.
        If .NoMatch Then .MoveLast
    End With

    If CurrentPage = CurPageEditInfo Then
    'simply change information - do not sign student in
        If DbTbl.NoMatch Then
            SetMsg "Added " & txtFirstName.Text & " " & txtLastName.Text & " to database", MsgSuccessColor, cmdSubmit
        Else
            SetMsg "Changed information for " & txtFirstName.Text & " " & txtLastName.Text, MsgSuccessColor, cmdSubmit
        End If
        ClearStudentInformation
        txtStudentIdLocked.SetFocus
    'ELSE CurrentPage = CurPageSubmit Or CurrentPage = CurPageReSubmit Then
    ElseIf NeedPurpose Then
    'get student's purpose
        GetPurpose
    Else
    'sign in student and display msg
        SignSidIn
        ChangePage CurPageSignIn
        If NoRegForm Then
            SetPicMsg vbCrLf & "You have been " & vbCrLf & "signed in " & StudentName & vbCrLf, _
                MsgSuccessColor, _
                imgHello.Picture, _
                0, _
                Nothing
            SetMsgDuration ShortMsgDuration 'override default time to shorten
        Else
            SetPicMsg "You have signed in, but since this is your first time this term, also fill in the paper form.", _
                MsgSuccessColor, _
                imgRegForm.Picture, _
                2, _
                Nothing
        End If
    End If
    Exit Sub

DbErr:
    SetMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSubmit

End Sub

Private Sub cmdChangeBg_Click()
    Dim File As String, BgPicture As StdPicture

    ' load from file
    File = txtBgFilename.Text
    On Error GoTo PicErr
    If GetAttr(File) And vbDirectory Then
        dirBgs.Path = File
        'drvBgs.Drive = File
        Exit Sub
    End If

    Set BgPicture = LoadPicture(File)
    RedrawBg BgPicture
    'SaveSetting App.ProductName, "Startup", "BgPic", File
    Exit Sub

PicErr:
    SetMsg "Could not load picture" & vbNewLine & Err.Description, MsgErrorColor, cmdChangeBg
End Sub

Private Sub RedrawBg(BgPicture As StdPicture)
    Dim Row As Long, Col As Long
    Dim PicHeight As Long, PicWidth As Long
    Dim FrmHeight As Long, FrmWidth As Long

#If False Then
    Const DST_BITMAP = 4
    Const DSS_DISABLED = 32
    Dim hBitmap As Long
    hBitmap = BgPicture.Handle
    DrawState hdc, 0, 0, hBitmap, 0, 0, 0, 200, 200, DST_BITMAP Or DSS_DISABLED
#Else
    ' tile bg image
    ' Why is VB so STUPID when it comes to pictures?
    ' It is so simple, a kindergartner could get it right.
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
#End If
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
       #If ProgramType = 1 Then
        .Fields("PID") = StudentPid
       #End If
       #If ProgramType = 2 Then
        .Fields("Purpose") = StudentPurpose
       #End If
        .Update
    End With
    
    StudentSignedIn = True

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
    On Error GoTo ErrHandler
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
        .Fields("SID") = StudentId
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
    
    Exit Sub

ErrHandler:
    MsgBox "A database error occurred trying to sign you out: " & Err.Number & " " & Err.Description, vbOKOnly, "Sign Out Error"
End Sub

Private Sub SignForgottenSidOut()
    ExecSql "UPDATE tblUsage SET Duration=" & AverageDuration & " WHERE SID=" & txtStudentIdLocked.Text & " AND Duration IS NULL;"
End Sub

Private Sub SignAllSidsOut()
'used at the end of the day when lab closes and and all students
'should have logged out. Of course, you can always depend on a
'certain number of them who have not.
SetMsg "Logging out all students who forget to sign out...", MsgSuccessColor, lstActions
DoEvents

ExecSql "INSERT INTO tblUsage (SID,SignIn,SignOut,Duration,PID) " _
      & "SELECT tblStudents.SID,tblStudents.LastUse,tblStudents.LastUse+" & AverageDuration & ", " & AverageDuration & ",tblStudents.PID " _
      & "FROM tblStudents " _
      & "WHERE tblStudents.Status=1;"
ExecSql "UPDATE tblStudents SET tblStudents.Status=" & SignStatusForgot & " WHERE tblStudents.Status=" & SignStatusIn & ";"
If DbIsOpen Then
    SetMsg "Signed out " & Db.RecordsAffected & " students who forgot to", MsgSuccessColor, lstActions
    StudentSignedIn = False
Else
    SetMsg "Could not execute SQL update!" & vbNewLine & DbErrMsg, MsgErrorColor, lstActions
End If

End Sub

Private Sub cmdSetDbFile_Click()
    'If Not DbTbl Is Nothing Then If DbTbl.Name = Table Then Exit Sub
    If Not Db Is Nothing Then Db.Close: Set Db = Nothing: Set DbTbl = Nothing
    DbFilename = txtDbFilename.Text
    SetMsg "Loading program IDs from database...", MsgInformationColor, cmdSetDbFile
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
        txtStudentMsg.Text = .Fields("Msg")
        StudentPid = .Fields("PID")
        For Counter = lstPids.ListCount - 1 To 1 Step -1
            If lstPids.ItemData(Counter) = StudentPid Then Exit For
        Next
        lstPids.ListIndex = Counter
    End With
    HighlightTextPrompt txtFirstName
    HighlightTextPrompt txtMiddleName
    HighlightTextPrompt txtLastName
    HighlightTextPrompt txtStudentMsg
End Sub

Private Sub ClearStudentInformation()
    txtStudentIdLocked.Text = ""
    txtFirstName.Text = ""
    txtLastName.Text = ""
    txtMiddleName.Text = ""
    txtStudentMsg.Text = ""
    lstPids.ListIndex = 0
End Sub

Private Sub cmdBack_Click()
    Dim Page As Long, Duration As Long

    Select Case CurrentPage
    Case CurPageSubmit, CurPageReSubmit, CurPageGetPurpose
        Page = CurPageSignIn
    Case CurPageChgBkg
        imgPreview.Picture = Nothing
        Page = CurPageMenu
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
    Dim TempDbFile As String

    If MsgBox("Are you really, truly, certainly, absolutely sure?", vbExclamation Or vbYesNo Or vbDefaultButton2, "Delete entire term student usage records") = vbYes Then
        SetMsg "Deleting all student records for those haven't signed in over 180 days...", MsgSuccessColor, cmdDeleteRecords
        DoEvents

        ExecSql "DELETE * FROM tblStudents WHERE [LastUse]+180<Now;"
        If Not DbIsOpen Then
            SetMsg "Could not execute SQL deletion statement!" & vbNewLine & DbErrMsg, MsgErrorColor, cmdDeleteRecords
        Else
            StudentRecs = Db.RecordsAffected
            ExecSql "UPDATE tblStudents SET tblStudents.Status=" & SignStatusNewTerm & ";"
            ExecSql "DELETE * FROM tblUsage;"
            'ExecSql "DELETE * FROM tblStudentPids;"
            UsageRecs = Db.RecordsAffected
            SetMsg "Deleted " & StudentRecs & " student records, reset everyone's status for new term, and cleared " & UsageRecs & " sign in records.", MsgSuccessColor, cmdDeleteRecords

            On Error Resume Next
            Db.Close
            Set Db = Nothing
            RepairDatabase DbFilename
            TempDbFile = AppPath & "temp.mdb"
            CompactDatabase DbFilename, TempDbFile
            Kill DbFilename
            Name TempDbFile As DbFilename
        End If
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
    Label8.Visible = PageVisible
    txtStudentId.Visible = PageVisible
    txtDate.Visible = PageVisible
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
    Label9.Visible = PageVisible
    Label10.Visible = PageVisible
    Label11.Visible = PageVisible
    Label12.Visible = PageVisible
    Label13.Visible = PageVisible
    txtStudentIdLocked.Visible = PageVisible
    txtFirstName.Visible = PageVisible
    txtMiddleName.Visible = PageVisible
    txtLastName.Visible = PageVisible
    lstPids.Visible = PageVisible
    cmdSubmit.Visible = PageVisible
    cmdSubmit.Default = PageVisible

    'back button
    PageVisible = PageVisible Or (Page = CurPageDelRecords) Or (Page = CurPageSetDbFile) Or (Page = CurPageChgBkg) Or (Page = CurPageGetPurpose)
    cmdBack.Visible = PageVisible
    cmdBack.Cancel = PageVisible

    PageVisible = (Page = CurPageEditInfo)
    txtStudentIdLocked.Enabled = PageVisible
    Label3.Visible = PageVisible
    txtStudentMsg.Visible = PageVisible

    ' select background image
    PageVisible = (Page = CurPageChgBkg)
    txtBgFilename.Visible = PageVisible
    filBgs.Visible = PageVisible
    dirBgs.Visible = PageVisible
    drvBgs.Visible = PageVisible
    cmdChangeBg.Visible = PageVisible
    cmdChangeBg.Default = PageVisible
    chkPreview.Visible = PageVisible
    cmdDefBg.Visible = PageVisible

    'delete records
    cmdDeleteRecords.Visible = (Page = CurPageDelRecords)

    'get purpose of visit
    PageVisible = (Page = CurPageGetPurpose)
    lstPurposes.Visible = PageVisible
    cmdChoose.Visible = PageVisible
    cmdChoose.Default = PageVisible

    Select Case Page
    Case CurPageMenu: lblInstructions.Caption = "Click on the action below in the list or press Enter."
    Case CurPageSignIn: lblInstructions.Caption = WelcomeMsg
    '"Welcome to the Open Lab. Before using any of the computer equipment in this room, please enter your student ID number. After signing in, you may use any free computer." & vbNewLine & vbNewLine & "Remember to sign out before leaving. Thank you :-)"
    '"Welcome to Chemeketa's Tutoring Center. Please enter your student ID number and then choose what area you want help in." & vbNewLine & vbNewLine & "Before leaving, remember to sign out. Thank you :-)"
    '"Welcome to Chemeketa's College Access Programs. Please enter your student ID number and then choose why you are here today." & vbNewLine & vbNewLine & "Before leaving, remember to sign out. Thank you :-)"
    '"Welcome to Chemeketa's Clerical Basics Lab. Please enter your student ID number and then select the reason for your visit today." & vbNewLine & vbNewLine & "Before leaving, remember to sign out. Thank you :-)"
    '#End If
    Case CurPageSubmit: lblInstructions.Caption = NewStudentMsg
    Case CurPageGetPurpose: lblInstructions.Caption = "Hello " & StudentName & ". " & StudyAreaMsg
    Case CurPageEditInfo: lblInstructions.Caption = "Enter the ID number of the student whose information you want to change."
    Case CurPageDelRecords: lblInstructions.Caption = "Clicking Delete will remove all records of students who have not signed in for over 180 days (half year) and clear all sign in/out logs for the current term/year. You MUST close all other programs using StudentLog.mdb (including any other open sign-in program) for the repair and compaction to work."
    Case CurPageSetDbFile: lblInstructions.Caption = "Enter the full path and filename to the correct student database."
    Case CurPageReSubmit: lblInstructions.Caption = NewTermMsg
    Case CurPageChgBkg: lblInstructions.Caption = "Double click on the desired background. Click Back for main menu."
    End Select
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyNumlock Or KeyCode = vbKeyCapital Then
        CorrectKeyStates
        SetMsg "Leave NumLock on and Caps lock off for the other students", MsgInformationColor, Nothing
    End If
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
    SetMsg "Terminating program...", MsgErrorColor, lstActions
    If StudentSignedIn Then
        If MsgBox("Log out any forgetful students?", vbQuestion Or vbYesNo) = vbYes Then
            SignAllSidsOut
        End If
    End If
    DoEvents
End Sub

Private Sub lblAbout_Click()
'credits and greetings
    SetPicMsg ProgramTitle & " Sign-In program, by Dwayne Robinson on 2001-01-30" & vbNewLine & vbNewLine & "Thanks to Daniel, Brian, Luke, Leanne, Linda, Susan, Shay, and Shirley for suggestions and input. Greets to Vahan, Shawn, Jim, Cliff, my cool cousin Russell, loving mom, grumpy dad, and beautiful Jessica..." & vbNewLine & vbNewLine & "http://fdwr.tripod.com/snes.htm" & vbNewLine & "FDwR@hotmail.com", _
        MsgInformationColor, _
        imgMyMascot.Picture, _
        1, _
        Nothing
End Sub

Private Sub lblConcave_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Form_MouseDown Button, Shift, X, Y
End Sub

Private Sub lblInstructions_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Form_MouseDown Button, Shift, X, Y
End Sub

Private Sub lblTitle_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Form_MouseDown Button, Shift, X, Y
End Sub

Private Sub lstActions_Click()
    If ClickingAction Then lstActions_DblClick
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
    Case 1: ClearStudentInformation
            ChangePage CurPageEditInfo
            txtStudentIdLocked.SetFocus
    Case 2: ChangePage CurPageChgBkg
            imgPreview.Visible = False
            chkPreview.Value = False
            filBgs.SetFocus
    Case 3: ChangePage CurPageSetDbFile
            txtDbFilename.SetFocus
    Case 4: ChangePage CurPageDelRecords
    Case 5: 'used at the end of the day when lab closes and and all students
            'should have logged out. Of course, you can always depend on a
            'certain number of them who have not.
            SignAllSidsOut
    Case 6: lblAbout_Click
    Case 7: Unload Me
    End Select
    ClickingAction = False
End Sub

Private Sub lstActions_KeyPress(KeyAscii As Integer)
'pressing Enter same as double clicking
    If KeyAscii = vbKeyReturn Then lstActions_DblClick
End Sub

Private Sub lstActions_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    ClickingAction = True
End Sub

Private Sub lstActions_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    ClickingAction = False
End Sub

'#If ProgramType = 1 Or ProgramType = 2 Then
Private Sub lstPurposes_Click()
    If ClickingAction Then
        ClickingAction = False
        cmdChoose_Click
    End If
End Sub
'#End If

Private Sub lstPurposes_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    ClickingAction = True
End Sub

Private Sub lstPurposes_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    ClickingAction = False
End Sub

Private Sub msgWindow_CloseMe()
'close error message if user clicked on it
    ClrErrorMsg
End Sub

Private Sub tmrMsgClear_Timer()
'only display error messages and sign in/out messages for so long
    tmrMsgClear.Enabled = False
    If MessageShown Then ClrErrorMsg
    'ChangePage CurrentPage
End Sub

Private Sub SetMsgDuration(Duration As Long)
    tmrMsgClear.Enabled = False
    tmrMsgClear.Interval = Duration
    tmrMsgClear.Enabled = True
End Sub

Private Sub txtBgFilename_Change()
    If chkPreview.Value Then
        Dim File As String, BgPicture As StdPicture
        On Error GoTo PicErr
        File = txtBgFilename.Text
        Set imgPreview = LoadPicture(File)
        imgPreview.Stretch = False
        If imgPreview.Height > 240 Then imgPreview.Height = 240: imgPreview.Stretch = True
        If imgPreview.Width > 300 Then imgPreview.Width = 300: imgPreview.Stretch = True
    End If
PicErr:
End Sub

Private Sub txtBgFilename_GotFocus()
    HighlightTextPrompt txtBgFilename
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

Private Sub SetMsg(Text As String, Color As Long, RelatedField As Object)
'set text for an error/information and shows message
'usually relative to some window control, like the button or
'text field which the error is related to
    msgWindow.SetMsg Text, Color
    ShowMsgAt RelatedField
End Sub

Private Sub SetPicMsg(Text As String, Color As Long, Pic As StdPicture, Align As Long, RelatedField As Object)
'set text for an error/information and shows message and picture
'usually relative to some window control, like the button or
'text field which the error is related to
    msgWindow.SetPicMsg Text, Color, Pic, Align
    ShowMsgAt RelatedField
End Sub

Private Sub ShowMsgAt(RelatedField As Object)
'Displays the message window, positioning it either relative
'to a specific object or in the center of the screen.
'If 'Nothing' is passed, it is placed in the middle
'of the screen.
'
'RelatedField - object which the message is related to
    Dim MsgTop As Long, MsgLeft As Long
    Dim MsgHeight As Long, MsgWidth As Long

    MessageShown = True
    SetMsgDuration ErrMsgDuration
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
                SetMsg "No student with that SID.", MsgErrorColor, cmdSubmit
                txtFirstName.Text = ""
                txtLastName.Text = ""
                txtMiddleName.Text = ""
                txtStudentMsg.Text = ""
                lstPids.ListIndex = 0
            End If
        Else
            SetMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSubmit
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

#If ProgramType = 0 Or ProgramType = 3 Then
Public Sub BuildPidList()
'build simple list
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
        SetMsg "Could not read program IDs from database! (need tblPids)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSetDbFile
        Exit Sub
    End If
End Sub

#ElseIf ProgramType = 1 Then
Private Sub BuildPidList()
    OpenDbTable "tblPids"
    If DbIsOpen Then
        With DbTbl
            Do Until .EOF
                Value = .Fields("PID")
                If Value < MaxPids Then
                    PidNames(Value) = .Fields("Name")
                    With lstPids
                        .AddItem DbTbl.Fields("Name")
                        .ItemData(.NewIndex) = Value
                    End With
                End If
                .MoveNext
            Loop
        End With
    Else
        SetMsg "Could not read program IDs from database! (need tblPids)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSetDbFile
        Exit Sub
    End If
End Sub

Public Sub RebuildPidList()
End Sub

#ElseIf ProgramType = 2 Then
Public Sub BuildPidList()
'build simple list
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
        SetMsg "Could not read program IDs from database! (need tblPids)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSetDbFile
        Exit Sub
    End If

    OpenDbTable "tblPurposes"
    If DbIsOpen Then
        lstPurposes.Clear
        With DbTbl
            Do Until .EOF
                Value = .Fields("PID")
                With lstPurposes
                    .AddItem DbTbl.Fields("Name")
                    .ItemData(.NewIndex) = Value
                End With
                .MoveNext
            Loop
        End With
    Else
        SetMsg "Could not read purpose list from database! (need tblPurposes)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSetDbFile
        Exit Sub
    End If

End Sub

#End If

Public Sub GetPurpose()

If NeedPurpose = 1 Then 'simple single purpose (college access programs)
    Dim Count As Long

    lstPurposes.ListIndex = -1
    For Count = 0 To lstPurposes.ListCount - 1
        If lstPurposes.ItemData(Count) = StudentPurpose Then
            lstPurposes.ListIndex = Count
            Exit For
        End If
    Next

Else 'NeedPurpose=2  'tutoring center
'builds list customized according to the student signing in,
'so that the courses which the student has already chosen before appear
'at the top of the list.

    'clear list
    'add courses the student has already entered first
    'add remaining courses to end of list that they haven't taken
    'find pid of last course taken by student and select it

    OpenDbTable "SELECT * FROM tblStudentPids WHERE SID=" & StudentId & ";"
    If DbIsOpen Then
        lstPurposes.Clear
        Erase StudentPids
        With DbTbl
            Do Until .EOF
                Value = .Fields("PID")
                If Value < MaxPids And Value >= 0 Then
                    StudentPids(Value) = True
                    With lstPurposes
                        .AddItem ("»" & PidNames(Value))
                        .ItemData(.NewIndex) = Value
                        If Value = StudentPid Then .ListIndex = .NewIndex
                    End With
                End If
                .MoveNext
            Loop
        End With
    Else
        SetMsg "Error opening database! (need tblStudentPids)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSignInOut
        Exit Sub
    End If

    For Value = 0 To MaxPids - 1
        If Not StudentPids(Value) Then
            If Len(PidNames(Value)) Then
                With lstPurposes
                    .AddItem (PidNames(Value))
                    .ItemData(.NewIndex) = Value
                End With
            End If
        End If
    Next
End If
    
ChangePage CurPageGetPurpose
lstPurposes.SetFocus

End Sub

Public Sub LoadSettings()
    Dim Line As String, KeyName As String, Equate As String
    Dim SepPos As Long
    Dim CurObject As Label

    On Error GoTo IgnoreMissingSettings
    Open AppPath & "SignIn.ini" For Input As 1
    On Error GoTo 0

    ' set message defaults in case settings file
    ' does not have any specific ones
    WelcomeMsg = "Welcome to the " & ProgramTitle & ". Please enter your student ID number to sign in." & vbNewLine & vbNewLine & "Remember to sign out before leaving. Thank you :-)"
    NewTermMsg = "Is all this information still correct from the last time you signed in?"
    NewStudentMsg = "We do not currently have you in this system. Please enter the following information, or if you have already entered it and simply typed the wrong student ID, click <Back> to return."
    StudyAreaMsg = "Please select the area you will be working in today."

    Do Until EOF(1)
        Line Input #1, Line
        SepPos = InStr(Line, "=")
        If SepPos Then
            KeyName = Left$(Line, SepPos - 1)
            Equate = Replace$(Mid$(Line, SepPos + 1), "\n", vbCrLf)
            Value = Val(Equate)
        Else
            KeyName = Line
            Equate = ""
            Value = 0
        End If

        Select Case KeyName
        Case "ProgramTitle": ProgramTitle = Equate
        Case "Title": Set CurObject = lblTitle
        Case "Subtitle": Set CurObject = lblSubtitle
        Case "WelcomeMsg": WelcomeMsg = Equate
        Case "NewTermMsg": NewTermMsg = Equate
        Case "StudyAreaMsg": StudyAreaMsg = Equate
        Case ".Text": CurObject.Caption = Equate
        Case ".Align": CurObject.Alignment = Value
        Case ".lfName": CurObject.Font.Name = Equate
        Case ".lfSize": CurObject.Font.Size = Value
        Case "NeedPurpose": NeedPurpose = Value
        Case "NoRegForm": NoRegForm = Value
        Case "Instructions": Set CurObject = lblInstructions
        End Select
    Loop
    
    Close 1
IgnoreMissingSettings:
End Sub
