VERSION 5.00
Begin VB.Form frmSignIn 
   AutoRedraw      =   -1  'True
   BackColor       =   &H80000010&
   BorderStyle     =   0  'None
   Caption         =   "Student Sign-In Program"
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
   Icon            =   "SignIn.frx":0000
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
      Left            =   0
      Top             =   8760
      Visible         =   0   'False
      Width           =   495
      _ExtentX        =   873
      _ExtentY        =   450
   End
   Begin VB.ListBox lstPidsSM 
      BackColor       =   &H00E0F0F8&
      Height          =   3660
      IntegralHeight  =   0   'False
      ItemData        =   "SignIn.frx":0442
      Left            =   6720
      List            =   "SignIn.frx":0449
      MultiSelect     =   1  'Simple
      Sorted          =   -1  'True
      TabIndex        =   14
      Top             =   3960
      Visible         =   0   'False
      Width           =   4695
   End
   Begin VB.Timer tmrTime 
      Enabled         =   0   'False
      Interval        =   1000
      Left            =   120
      Top             =   7800
   End
   Begin VB.TextBox txtDob 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      IMEMode         =   3  'DISABLE
      Left            =   2760
      MaxLength       =   10
      TabIndex        =   12
      Top             =   6960
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.CommandButton cmdChoose 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Choose"
      Height          =   600
      Left            =   4080
      Style           =   1  'Graphical
      TabIndex        =   43
      Top             =   8160
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdDefBg 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Default"
      Height          =   600
      Left            =   7920
      Style           =   1  'Graphical
      TabIndex        =   23
      Top             =   8160
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.TextBox txtBgFilename 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   480
      TabIndex        =   39
      Top             =   7080
      Visible         =   0   'False
      Width           =   10935
   End
   Begin VB.TextBox txtStudentMsg 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   2760
      TabIndex        =   4
      ToolTipText     =   "An optional message you can show to a specific student the next time he/she signs in"
      Top             =   4560
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.TextBox txtLastName 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   2760
      TabIndex        =   10
      Top             =   6360
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.TextBox txtMiddleName 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   2760
      TabIndex        =   8
      Top             =   5760
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.TextBox txtFirstName 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   2760
      TabIndex        =   6
      Top             =   5160
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.TextBox txtStudentId 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      IMEMode         =   3  'DISABLE
      Left            =   4920
      MaxLength       =   9
      PasswordChar    =   "*"
      TabIndex        =   32
      Top             =   6240
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.ListBox lstPidsSS 
      BackColor       =   &H00E0F0F8&
      Height          =   3660
      IntegralHeight  =   0   'False
      ItemData        =   "SignIn.frx":0467
      Left            =   6720
      List            =   "SignIn.frx":046E
      Sorted          =   -1  'True
      TabIndex        =   13
      Top             =   3960
      Visible         =   0   'False
      Width           =   4695
   End
   Begin VB.DriveListBox drvBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   480
      TabIndex        =   36
      Top             =   3240
      Visible         =   0   'False
      Width           =   4695
   End
   Begin VB.TextBox txtStudentId2 
      BackColor       =   &H00E0F0F8&
      Enabled         =   0   'False
      Height          =   555
      IMEMode         =   3  'DISABLE
      Left            =   2760
      MaxLength       =   9
      PasswordChar    =   "*"
      TabIndex        =   28
      Text            =   "123456789"
      Top             =   3960
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.Timer tmrMsgClear 
      Enabled         =   0   'False
      Interval        =   22000
      Left            =   120
      Top             =   8280
   End
   Begin VB.ListBox lstActions 
      BackColor       =   &H00E0F0F8&
      Height          =   3660
      IntegralHeight  =   0   'False
      ItemData        =   "SignIn.frx":048C
      Left            =   3960
      List            =   "SignIn.frx":04A8
      TabIndex        =   35
      Top             =   3360
      Visible         =   0   'False
      Width           =   3615
   End
   Begin VB.TextBox txtDbFilename 
      BackColor       =   &H00E0F0F8&
      Height          =   555
      Left            =   2640
      TabIndex        =   18
      Top             =   3120
      Visible         =   0   'False
      Width           =   8775
   End
   Begin VB.FileListBox filBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   3570
      Hidden          =   -1  'True
      Left            =   5280
      Pattern         =   "*.jpg;*.bmp;*.gif;*.wmf"
      TabIndex        =   38
      Top             =   3240
      Visible         =   0   'False
      Width           =   6135
   End
   Begin VB.DirListBox dirBgs 
      BackColor       =   &H00E0F0F8&
      Height          =   2880
      Left            =   480
      TabIndex        =   37
      Top             =   3930
      Visible         =   0   'False
      Width           =   4695
   End
   Begin VB.CommandButton cmdSubmit 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Submit"
      Height          =   600
      Left            =   4080
      Style           =   1  'Graphical
      TabIndex        =   19
      Top             =   8160
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdSignInOut 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Sign In/Out"
      Height          =   600
      Left            =   4800
      Style           =   1  'Graphical
      TabIndex        =   15
      TabStop         =   0   'False
      Top             =   8160
      Visible         =   0   'False
      Width           =   2175
   End
   Begin VB.CommandButton cmdUpdate 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Update"
      Height          =   600
      Left            =   4080
      Style           =   1  'Graphical
      TabIndex        =   26
      Top             =   8160
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdCancel 
      BackColor       =   &H00D0E0E8&
      Cancel          =   -1  'True
      Caption         =   "Cancel"
      Height          =   600
      Left            =   6000
      Style           =   1  'Graphical
      TabIndex        =   22
      Top             =   8160
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdSetDbFile 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Set File"
      Height          =   600
      Left            =   4080
      Style           =   1  'Graphical
      TabIndex        =   34
      Top             =   8160
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdDeleteRecords 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Delete"
      Height          =   600
      Left            =   4080
      Style           =   1  'Graphical
      TabIndex        =   16
      Top             =   8160
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CommandButton cmdChangeBg 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Change"
      Height          =   600
      Left            =   2160
      Style           =   1  'Graphical
      TabIndex        =   20
      Top             =   8160
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.CheckBox chkPreview 
      BackColor       =   &H00D0E0E8&
      Caption         =   "Preview"
      Height          =   600
      Left            =   4080
      Style           =   1  'Graphical
      TabIndex        =   21
      Top             =   8160
      Value           =   1  'Checked
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.ListBox lstPidsLS 
      BackColor       =   &H00E0F0F8&
      Columns         =   2
      Height          =   4410
      ItemData        =   "SignIn.frx":053C
      Left            =   480
      List            =   "SignIn.frx":0543
      Sorted          =   -1  'True
      TabIndex        =   41
      Top             =   3240
      Visible         =   0   'False
      Width           =   11175
   End
   Begin VB.ListBox lstPidsLM 
      BackColor       =   &H00E0F0F8&
      Columns         =   2
      Height          =   4410
      ItemData        =   "SignIn.frx":0561
      Left            =   480
      List            =   "SignIn.frx":0568
      MultiSelect     =   1  'Simple
      Sorted          =   -1  'True
      TabIndex        =   42
      Top             =   3240
      Visible         =   0   'False
      Width           =   11175
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
      Top             =   0
      Width           =   345
   End
   Begin VB.Label lblTime 
      BackColor       =   &H00E0F0F8&
      BorderStyle     =   1  'Fixed Single
      Caption         =   "[time]"
      Enabled         =   0   'False
      Height          =   555
      Left            =   4920
      TabIndex        =   46
      Top             =   5280
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label lblDate 
      BackColor       =   &H00E0F0F8&
      BorderStyle     =   1  'Fixed Single
      Caption         =   "[date]"
      Enabled         =   0   'False
      Height          =   555
      Left            =   4920
      TabIndex        =   45
      Top             =   4680
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label lblExit 
      BackStyle       =   0  'Transparent
      Height          =   8895
      Left            =   0
      TabIndex        =   44
      Top             =   0
      Width           =   12015
   End
   Begin VB.Label lblTimeCaption 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Time"
      Height          =   495
      Left            =   2760
      TabIndex        =   30
      Top             =   5280
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label lblDob 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Birthdate"
      Height          =   495
      Left            =   600
      TabIndex        =   11
      Top             =   6960
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Image imgDefBg 
      Height          =   2400
      Left            =   8280
      Picture         =   "SignIn.frx":0586
      Top             =   10320
      Visible         =   0   'False
      Width           =   2400
   End
   Begin VB.Label lblMessage 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Message"
      Height          =   495
      Left            =   600
      TabIndex        =   3
      Top             =   4560
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Image imgForgot 
      Height          =   1200
      Left            =   9840
      Picture         =   "SignIn.frx":0F00
      Top             =   9000
      Visible         =   0   'False
      Width           =   840
   End
   Begin VB.Image imgDbErr 
      Height          =   1050
      Left            =   10680
      Picture         =   "SignIn.frx":1694
      Top             =   9120
      Visible         =   0   'False
      Width           =   1065
   End
   Begin VB.Image imgBye 
      Height          =   1320
      Left            =   9000
      Picture         =   "SignIn.frx":1DF4
      Top             =   9000
      Visible         =   0   'False
      Width           =   960
   End
   Begin VB.Image imgHello 
      Height          =   1200
      Left            =   8160
      Picture         =   "SignIn.frx":25DC
      Top             =   9000
      Visible         =   0   'False
      Width           =   840
   End
   Begin VB.Label lblPids 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Program"
      Height          =   495
      Left            =   4920
      TabIndex        =   40
      Top             =   3960
      Visible         =   0   'False
      Width           =   1695
   End
   Begin VB.Image imgMyMascot 
      Height          =   3915
      Left            =   600
      Picture         =   "SignIn.frx":2D70
      Top             =   9000
      Visible         =   0   'False
      Width           =   3045
   End
   Begin VB.Image Image1 
      Height          =   1215
      Left            =   360
      Picture         =   "SignIn.frx":851E
      Top             =   360
      Width           =   1215
   End
   Begin VB.Label lblDbFilename 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Filename:"
      Height          =   495
      Left            =   600
      TabIndex        =   17
      Top             =   3120
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblDateCaption 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Date"
      Height          =   495
      Left            =   2760
      TabIndex        =   29
      Top             =   4680
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label Label5 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Student ID"
      Height          =   495
      Left            =   2880
      TabIndex        =   31
      Top             =   6240
      Visible         =   0   'False
      Width           =   1935
   End
   Begin VB.Label lblKnumber 
      BackStyle       =   0  'Transparent
      Caption         =   "(Either your social security number or your K-number)"
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   12
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   375
      Left            =   2760
      TabIndex        =   33
      Top             =   6840
      Visible         =   0   'False
      Width           =   6975
   End
   Begin VB.Label Label12 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Last Name"
      Height          =   495
      Left            =   600
      TabIndex        =   9
      Top             =   6360
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label Label11 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Middle Initial"
      Height          =   495
      Left            =   600
      TabIndex        =   7
      Top             =   5760
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label lblMiddle 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "First Name"
      Height          =   495
      Left            =   600
      TabIndex        =   5
      Top             =   5160
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label Label9 
      Alignment       =   1  'Right Justify
      BackStyle       =   0  'Transparent
      Caption         =   "Student Id"
      Height          =   495
      Left            =   600
      TabIndex        =   27
      Top             =   3960
      Visible         =   0   'False
      Width           =   2055
   End
   Begin VB.Label lblInstructions 
      BackStyle       =   0  'Transparent
      Caption         =   "Initializing, loading background, opening database..."
      Height          =   2655
      Left            =   480
      TabIndex        =   2
      Top             =   2160
      Width           =   10935
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
      Left            =   3360
      TabIndex        =   24
      Top             =   1080
      Width           =   4935
   End
   Begin VB.Label lblTitle 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "Times New Roman"
         Size            =   42.75
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFC0D0&
      Height          =   1215
      Left            =   1440
      TabIndex        =   0
      Top             =   240
      Width           =   10455
   End
   Begin VB.Label lblTitleShadow 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "Times New Roman"
         Size            =   42
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00202020&
      Height          =   1215
      Left            =   1440
      TabIndex        =   1
      Top             =   360
      Width           =   10455
   End
   Begin VB.Image imgRegForm 
      Height          =   3495
      Left            =   2160
      Picture         =   "SignIn.frx":9060
      Top             =   9000
      Visible         =   0   'False
      Width           =   5955
   End
   Begin prjSignIn.DimmedBg ctlDimmed 
      Height          =   5880
      Left            =   240
      Top             =   2040
      Width           =   11550
      _ExtentX        =   20373
      _ExtentY        =   10372
   End
End
Attribute VB_Name = "frmSignIn"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'By Dwayne Robinson (aka Peekin), 2001-01-29:2002-09-19
'Chemeketa Sign In Program
'
'Todo:
'- Ensure all PIDs are correct for their locations.
'- Clear/compact all databases.
'- Prevent network error crashes
'- store multiple selections
'
'Note:
'- Project requires reference "Microsoft DAO 3.6 Object library" for Access 2000 databases
'- Requires reference "Microsoft DAO 3.51 Object library" on other computers
'
'Questions:
'- McCil  Same PID each term, or different each time? Fed sheet?
'- Santiam MMC  What PIDs?
'
'Hidden:
'- holding Ctrl+Shift and clicking on background shows menu
'- clicking on the lower left of screen shows about dialog
'- holding Ctrl+Shift+Alt and right clicking shows next page (to DEBUG!)
'
'0  Open Computer Lab - single PIDS, fed sheet
'1  Tutoring Center - multiple PIDs, fed sheet
'2  College Access Programs - single PIDS each time, fed sheet
'3  Clerical Basics Lab - single PIDs, no fed sheet
'4  Dallas Campus Clerical Basics
'5  McMinnville
'6  Woodburn Community Technology
'7  Woodburn Campus CIL
'8  Santiam Multimedia Center
'9  McMinnville Campus CIL
'10 Salem Nursing Program
'
'Note that any pseudocode left in here is simply for reference.
'The actual code may no longer reflect that structure.
'
'This single form is the same form for several different labs,
'shared so that updates to one benefits all the others.
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
'           Settings now stored in SignIn.ini
'2002-08-29 Registration form picture can be specified in SignIn.ini
'           Add /signin command line parameter to skip menu
'2002-09-19 Added McMinnville CIL campus.
'           Added custom pictures for sign-in/out/forgot in settings file.
'2003-07-22 Sign out all students if time wraps around to midnight.
'           Add timer on main sign in page.
'           Resized all pages to be little larger.
'2003-07-23 Moved average duration into ini.
'           Added nursing program.
'           Add custom default background
'           Add default image path
'           Removed repairdatabase because it isn't supported by DAO 3.6 (for Access 2000 db's)
'           Time stamp backups of the database each deletion.
'           Can exit to main menu by clicking almost anywhere now
'2003-07-24 Renamed all PID and Purpose in program and databases to PID and PID2
'           Brightened student message color to grab attention.
'           Added complete customizability of all message fonts on pages (type, size, weight...)
'             so that Woodburn could have their Bradley Hand ITC.
'           Resized student info text prompts to all match.
'2003-07-28 Fixed message window font error because SET and a=b are NOT the same; however VB
'             gladly allows you make that mistake.
'           Added name substitution to new term message.
'           Added minduration option to ini for ignoring really short sign-ins.
'           Changed time to labels instead of text prompts. Don't remember why they were
'             text prompts in the first place.
'           Message window now sets capture so clicking anywhere will dismiss the msg
'2003-07-29 Grr, Santiam is not done by a long shot.
'           Changed behaviour of background selection. Preview is on by default, and preview is
'             now set to the full screen, rather than just a small image box.
'           Message window sets cursor to help arrow after capturing.
'2003-09-14 Drastically changed the page sequence code
'           Changed the list building code to support multiple selection
'           Changed the page viewing code too
'           Renamed back button to cancel
'2003-09-15 Added note upon sign out for students to know long they spent in the lab
'           Implemented multiple time/PID records
'           Verify that at least one record is selected.
'2003-09-16 Single click again chooses list box item without needing to click button.
'           Added double click choose for multiple selection list box.

Option Explicit

Private Value As Long           'generic variable reused over and over
Private Counter As Long         'another one
Private ErrNum As Long          'generic error number

Dim PageVisible As Long         'current page showing
Const PageDefMenu = 0
Const PageDefSignIn = 1
Const PageDefGetName = 2        'get name of new student
Const PageDefGetPid1 = 3        'get primary PID
Const PageDefGetPid2 = 4        'get secondary PID
Const PageDefEditInfo = 5       'edit student info
Const PageDefDelRecords = 6     'delete old records
Const PageDefSetDbFile = 7      'set database location (only if necessary)
Const PageDefVerifyName = 8     'returning student similar to get name for new student
Const PageDefSelectBackground = 9 'choose a JPG or BMP file for background
Const PageDefTotal = 10          'total number of pages

Dim MessageShown As Long        'a message is displayed
Dim MessageShowTime As Long
Const MessageShownNone = False
Const MessageShownImportant = 1
Const MessageShownSkipable = 2
Const MessageShownUnimportant = True

Dim StudentName As String       'take a guess...
Dim StudentLastUse As Date      'last sign in or sign out
Dim StudentMsg As String        'optional message to display
Dim StudentId As Long           'either SSN or (K number)+1000000000
Dim StudentStatus As Byte       'signed in, signed out, new term...
Dim StudentPid1 As Long         'last selected primary program id
Dim StudentPid2 As Long         'last selected secondary program id
Dim StudentPidList1 As String   'list of PIDs for multiple selection
Dim StudentPidList2 As String   'list of PIDs for multiple selection
Dim StudentDob As Date          'when student was born (might not be used)

Dim StudentSignCount As Long    'balance of students signed in vs out (how many have forgotten)

Dim ClickingAction As Boolean   'mouse button is down, waiting for release

Const MaxPids = 1000
Dim PidNames1(MaxPids - 1) As String  'text names of primary IDs
Dim PidValues1(MaxPids - 1) As Long   'numeric identifier (program ID)
Dim PidNames2(MaxPids - 1) As String 'text names of secondary IDs
Dim PidValues2(MaxPids - 1) As Long  'numeric identifier (program ID)
Dim PidSelections1(MaxPids - 1) As Boolean 'check marks beside entry
Dim PidSelections2(MaxPids - 1) As Boolean

Const SignStatusOut = 0
Const SignStatusIn = 1
Const SignStatusForgot = 2
Const SignStatusNewTerm = 3
Const SignStatusNewStudent = 4

Dim ShowRegForm As Long
Dim NeedName As Boolean
Dim NeedDob As Boolean
Dim NeedPid1 As Long            'get list ID each sign in (program ID), rather than only once a term
Dim NeedPid2 As Long            '0-no 1-single 2-multiple
Dim PrevUseDate As Date
Dim ImagePath As String         'background path

Const NeedPidNever = 0          'never need program ID
Const NeedPidAlways = 1         'choose PID every sign in
Const NeedPidMulti = 2          'only choose when student first signs in
Const NeedPidOnceSingle = 4     'bit 2 is ignored, just set to test boolean true
Const NeedPidOnceMulti = 2
Const NeedPidAlwaysSingle = 1
Const NeedPidAlwaysMulti = 3

Dim lstPids As ListBox          'currently active listbox, since MultiSelect is readonly runtime (grr!)

Const MsgSuccessColor = &HC0FFC0
Const MsgErrorColor = &HC0C0FF
Const MsgInformationColor = &HFFC0C0
Const MsgSpecialColor = &H88DDFF 'something to grab attention

Const ErrMsgDuration As Long = 22000    'clear error message after 22 seconds
Const MinErrMsgDuration As Long = 1000    'force at least two seconds of viewing
Const SuccessMsgDuration As Long = 9000 'clear successful sign in message after
Const ShortMsgDuration As Long = 3000 'clear successful sign in message after

' various messages, customized to each location
Dim WelcomeMsg As String    'shown on main screen
Dim NewTermMsg As String    'shown each new term or new year
Dim NewStudentMsg As String 'shown for new students not in DB
Dim PidMsg1 As String       'shown when selecting PID 1
Dim PidMsg2 As String
Dim RegFormMsg As String    'shown with registration form

Dim PidCaption1 As String   'caption displayed on PID label
Dim PidCaption2 As String

Dim BgPic As StdPicture
Const DimmedColor = &HB0B0B0

Private Sub Form_Load()
    Dim CurCtl As Control
    Dim TopOfs As Long, LeftOfs As Long

    ' reposition all objects based on screen size
    Show        'let people know what's happening so that the delay
    DoEvents    'so startup doesn't seem so long and mysterious

    NeedName = True 'set permanently true for now
    NeedPid1 = 4    'set for now
    LoadSettings

    'reposition all objects to be centered on screen
    TopOfs = (ScaleHeight - 600) \ 2
    LeftOfs = (ScaleWidth - 800) \ 2
    For Each CurCtl In Me
        With CurCtl
            If TypeName(CurCtl) <> "Timer" Then
                .Top = .Top + TopOfs
                .Left = .Left + LeftOfs
            End If
        End With
    Next

    'set main title, shadow, subtitle, and background
    ProgramTitle = lblTitle.Caption
    lblTitleShadow.Caption = ProgramTitle
    lblTitleShadow.Font.Size = lblTitle.Font.Size - 1
    lblTitleShadow.Font.Name = lblTitle.Font.Name
    Set lstPids = lstPidsLS
    Set BgPic = imgDefBg.Picture
    RedrawBg BgPic

  'tutoring center only
  #If ProgramType = 1 Then
    MsgBox "I lost the original source code to the Tutoring Center version, and haven't rewritten it. So don't expect it to work fully!", vbExclamation, "Warning"
  #End If

    lstActions.ListIndex = 0
    lblDate.Caption = Format$(Date, "yyyy-mm-dd")

    On Error GoTo EatError

    dirBgs.Path = AppPath
    ErrNum = 0
    dirBgs.Path = ImagePath
    If ErrNum Then MsgBox "The image path is invalid: " & ImagePath & vbNewLine & "Edit the ImagePath=..."

    'read in PIDs
    OpenDbTable "tblPids"
    If Not DbIsOpen Then
        PageView PageDefSetDbFile
        SetMsg "Error opening database! (need tblPids)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSetDbFile
    Else
        LoadPidLists
        If Command$ = "/signin" Then
            PageView PageDefSignIn
        Else
            PageView PageDefMenu
        End If
    End If

    ' get program last use
    ' to later sign out all of yesterday's students if necessary
    PrevUseDate = GetSetting(App.ProductName, "Startup", "PrevUseDate", Date)
    SaveSetting App.ProductName, "Startup", "PrevUseDate", Date
    ' added this line after learning that my program
    ' wasn't always being shut down properly -_-
    ' aka, they were doing Ctrl+Alt+Delete to it

    CorrectKeyStates
    'force? HKEY_USERS/.DEFAULT/Control Panel/Desktop/FontSmoothing=1
    Exit Sub

EatError: 'disregard any annoying errors
    ErrNum = Err.Number
    Resume Next

End Sub

Private Sub Form_KeyPress(KeyAscii As Integer)
    If MessageShown Then ClrErrorMsg
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

    ' check for message currently being displayed
    ' ensure it is displayed long enough if important msg
    If MessageShown Then
        If MessageShown = MessageShownUnimportant Then
            ClrErrorMsg
            Exit Sub
        ElseIf (Timer - MessageShowTime) * 1000 < MinErrMsgDuration Then
            'SetMsgDuration 1000
            'MessageShown = MessageShownUnimportant
            Exit Sub
        ElseIf MessageShown = MessageShownSkipable Then
            ClrErrorMsg
        Else
            ClrErrorMsg
            Exit Sub
        End If
    End If

    ' check length of entered ID
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
        If DbErrNum = 3043 Then
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
        Else
            SetMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSignInOut
        End If
        Exit Sub
    End If
    On Error GoTo NetworkError
    Set StudentTbl = DbTbl
    StudentId = GetNumericSid(txtStudentId.Text)
    StudentTbl.Index = "PrimaryKey"
    StudentTbl.Seek "=", StudentId
    On Error GoTo 0

    txtStudentId2.Text = txtStudentId.Text
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
        If .NoMatch Then
            'no students with that SID, must be a new student
            StudentStatus = SignStatusNewStudent
            StudentPid1 = -1
            StudentPid2 = -1
            PageNext
            Exit Sub
        Else
            StudentStatus = .Fields("Status")
            StudentName = .Fields("FirstName")
            StudentLastUse = .Fields("LastUse")
            If NeedPid1 Then
                StudentPidList1 = .Fields("PIDs")
                StudentPid1 = Val(StudentPidList1)
            End If
            If NeedPid2 Then
                If Not IsNull(.Fields("PIDs2")) Then
                    StudentPidList2 = .Fields("PIDs2")
                    StudentPid2 = Val(StudentPidList2)
                Else
                    StudentPid2 = -1
                End If
            End If
            If Not IsNull(.Fields("DOB")) Then StudentDob = .Fields("DOB") Else StudentDob = 0
            StudentMsg = .Fields("Msg")
        End If
    End With


    If Len(StudentMsg) Then
    'message waiting for student
        SetMsg StudentMsg & vbCrLf & vbCrLf & "Press Enter to continue.", MsgSpecialColor, Nothing
        MessageShown = MessageShownImportant
        With StudentTbl
            .Edit
            .Fields("Msg") = ""
            .Update
        End With
    ElseIf StudentStatus = SignStatusIn Then 'currently signed in
        txtStudentId.Text = ""
        SignStudentOut
        SetPicMsg vbNewLine & "You have been " & vbNewLine & "signed out " & StudentName & vbNewLine & vbNewLine & "Last sign in was" & vbNewLine & GetTimeDifMsg(Now - StudentLastUse) & vbNewLine, _
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
            imgForgot, _
            0, _
            cmdSignInOut
        MessageShown = MessageShownSkipable
        With StudentTbl
            .Edit
            'StudentStatus = SignStatusOut
            .Fields("Status") = SignStatusOut
            .Update
        End With
        'restore SID
    'ElseIf StudentStatus = SignStatusNewTerm Then 'returning student
    '    txtStudentId.Text = ""
    '    'new term, so verify previous information
    '    FillStudentInfoPage
    '    PageView PageDefVerifyName
    'Else 'If StudentStatus = SignStatusOut Then 'not signed in
    '    txtStudentId.Text = ""
    '    If NeedPid1 Then
    '        GetPid1
    '    ElseIf NeedPid2 Then
    '        GetPid2
    '    Else
    '        SignSidIn
    '        SetPicMsg vbCrLf & "You have been " & vbCrLf & "signed in " & StudentName & vbCrLf, _
    '            MsgSuccessColor, _
    '            imgHello.Picture, _
    '            0, _
    '            Nothing
    '        SetMsgDuration ShortMsgDuration 'override default time to shorten
    '   End If
    Else '= SignStatusNewTerm || SignStatusOut
        PageNext
    End If
End Sub

Private Sub cmdSignInOut_KeyPress(KeyAscii As Integer)
    txtStudentId.SetFocus
    txtStudentId_KeyPress KeyAscii
End Sub

' does error checking on info page,
' updates student info,
' then passses control to PageNext
Private Sub cmdSubmit_Click()
' new/returning students click this after entering their info
    Dim IsNew As Boolean

    ' correct case of entered names (robinson -> Robinson)
    txtStudentId2.Text = Trim(txtStudentId2.Text)
    CorrectName txtLastName
    CorrectName txtMiddleName
    CorrectName txtFirstName

    ' validate information
    If Len(txtStudentId2.Text) < 9 Then
        SetMsg "The ID number can be found on the back of the student's ID card, and can be either a k-number or social security number.", MsgInformationColor, txtStudentId2
        HighlightTextPrompt txtStudentId2
        txtStudentId2.SetFocus
        Exit Sub
    End If
    If Len(txtFirstName.Text) <= 0 Then
        SetMsg "Please enter a first name.", MsgInformationColor, txtFirstName
        txtFirstName.SetFocus
        Exit Sub
    End If
    If Len(txtLastName.Text) <= 0 Then
        SetMsg "Please enter a last name.", MsgInformationColor, txtLastName
        txtLastName.SetFocus
        Exit Sub
    End If
    If NeedDob Then
        StudentDob = 0
        On Error Resume Next 'stupid little error handler
        StudentDob = DateValue(txtDob.Text)
        On Error GoTo 0
        If StudentDob <= 0 Then
            SetMsg "Please enter valid date of birth (you may enter in any format whether separated by slashes or dashes)." & vbNewLine & vbNewLine & "1980-09-13  or  2/5/72", MsgInformationColor, txtDob
            txtDob.SetFocus
            Exit Sub
        End If
        HighlightTextPrompt txtDob
        txtDob.Text = Format(StudentDob, "yyyy-mm-dd")
    End If
    If lstPids.ListIndex < 0 Then
        SetMsg "Please select a " & LCase$(PidCaption1) & " from the list.", MsgInformationColor, lstPids
        '"Please select your field of study from the list (your current major)."
        '"Please select the area want help in."
        '"Please select the program you are in."
        '"Please select the area you will be working in from the list."
        lstPids.SetFocus
        Exit Sub
    End If
    If GetPidsSelected(PidSelections1()) <= 0 Then
        SetMsg "Please select at least one " & LCase$(PidCaption1) & " from the list. You may select more than one.", MsgInformationColor, lstPids
        lstPids.SetFocus
        Exit Sub
    End If
    'If GetNumericSid(txtFirstName.Text) Then
    '    PageView PageDefSignIn
    '    SetMsg "You entered your ID number on the information page.", txtStudentId2, MsgInformationColor
    '    txtStudentId.SetFocus
    '    Exit Sub
    'End If
    StudentPid1 = lstPids.ItemData(lstPids.ListIndex)
    StudentName = txtFirstName.Text
    StudentStatus = SignStatusNewTerm 'set initial status of student

    'add/update record filled with student information
    OpenDbTable "tblStudents"
    If Not DbIsOpen Then GoTo DbErr
    On Error GoTo DbErr
    With DbTbl
        .Index = "PrimaryKey"
        .Seek "=", StudentId
        'if student already exists, resubmit, otherwise create new
        If .NoMatch Then
            IsNew = True
            .AddNew
        Else
            .Edit
        End If

        .Fields("SID") = StudentId
        .Fields("FirstName") = StudentName
        .Fields("LastName") = txtLastName.Text
        .Fields("MiddleName") = txtMiddleName.Text
        If NeedPid1 Then .Fields("PIDs") = StudentPid1
        If NeedPid2 Then .Fields("PIDs2") = StudentPid2
        If NeedDob Then .Fields("DOB") = StudentDob
        .Fields("Msg") = txtStudentMsg.Text
        .Fields("Status") = StudentStatus
        .Update
        'if new record was added, move to record
        'you might think the record pointer should be automatically
        'moved to the new record. Oh well.
        If IsNew Then .MoveLast
    End With

    If PageVisible = PageDefEditInfo Then
    'simply change information - do not sign student in
        If IsNew Then
            SetMsg "Added " & txtFirstName.Text & " " & txtLastName.Text & " to database", MsgSuccessColor, cmdSubmit
        Else
            SetMsg "Changed information for " & txtFirstName.Text & " " & txtLastName.Text, MsgSuccessColor, cmdSubmit
        End If
        ClearStudentInfoPage
        txtStudentId2.Text = ""
        txtStudentId2.SetFocus
    Else 'PageVisible = PageDefGetName Or PageVisible = PageDefVerifyName
        PageNext
    End If

    Exit Sub

DbErr:
    SetMsg "Error updating database record! (to tblStudents)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSubmit
    
End Sub


Private Sub cmdChoose_Click()
    Dim PID As Long

    If lstPids.ListIndex < 0 Then
        'SetMsg "Please select an item from the list.", MsgInformationColor, lstPids
        SetMsg "Please select a " _
            & LCase$(IIf(PageVisible = PageDefGetPid1, PidCaption1, PidCaption2)) _
            & " from the list.", MsgInformationColor, lstPids
        lstPids.SetFocus
        Exit Sub
    End If
    PID = lstPids.ItemData(lstPids.ListIndex)

    If PageVisible = PageDefGetPid1 Then
        StudentPid1 = PID
        If GetPidsSelected(PidSelections1()) <= 0 Then
            SetMsg "Please select at least one " & LCase$(PidCaption1) & " from the list. You may select more than one.", MsgInformationColor, lstPids
            lstPids.SetFocus
            Exit Sub
        End If
    Else
        StudentPid2 = PID
        If GetPidsSelected(PidSelections2()) <= 0 Then
            SetMsg "Please select at least one " & LCase$(PidCaption2) & " from the list. You may select more than one.", MsgInformationColor, lstPids
            lstPids.SetFocus
            Exit Sub
        End If
    End If

    PageNext

End Sub



Private Sub cmdChangeBg_Click()
    Dim File As String

    ' load from file
    File = txtBgFilename.Text
    On Error GoTo PicErr
    If GetAttr(File) And vbDirectory Then
        dirBgs.Path = File
        'drvBgs.Drive = File
        Exit Sub
    End If
  
    Set BgPic = LoadPicture(File)
    RedrawBg BgPic

    PageView PageDefMenu
    Exit Sub

PicErr:
    SetMsg "Could not load picture" & vbNewLine & Err.Description, MsgErrorColor, cmdChangeBg

End Sub

Private Sub chkPreview_Click()
    txtBgFilename_Change
    filBgs.SetFocus
End Sub

Private Sub cmdDefBg_Click()
    RedrawBg imgDefBg.Picture
    PageView PageDefMenu
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
    If KeyCode = vbKeyLeft Then If dirBgs.Visible Then dirBgs.SetFocus: KeyCode = 0
End Sub


Private Sub RedrawBg(NewPic As StdPicture)
    Dim Row As Long, Col As Long
    Dim PicHeight As Long, PicWidth As Long
    Dim FrmHeight As Long, FrmWidth As Long

  #If False Then
    'experimented with having the GDI dither the background image,
    'but the Windows GDI is severely lacking such capability in that area
    Const DST_BITMAP = 4
    Const DSS_DISABLED = 32
    Dim hBitmap As Long
    hBitmap = NewPic.Handle
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
    PicWidth = Int(NewPic.Width / 26.45) 'what is going on here!?
    PicHeight = Int(NewPic.Height / 26.45)
    For Row = 0 To FrmHeight - 1 Step PicHeight
        For Col = 0 To FrmWidth - 1 Step PicWidth
            PaintPicture NewPic, Col, Row
        Next
    Next
    ctlDimmed.DimThis hdc, ctlDimmed, DimmedColor
#End If
End Sub

Private Sub filBgs_DblClick()
    cmdChangeBg_Click
End Sub

'Private Sub cboProgramId_GotFocus()
'   SendMessage cboProgramId.hwnd, CB_SHOWDROPDOWN, 1, ByVal 0&
'End Sub

'Signs in the student, changes the page, and displays message
'Does not touch the record directly.
Private Sub SignStudentInWithMsg()
    SignStudentIn
    PageView PageDefSignIn
    If ShowRegForm Then
        SetPicMsg RegFormMsg, _
            MsgSuccessColor, _
            imgRegForm.Picture, _
            2, _
            Nothing
        MessageShown = MessageShownImportant
    Else
        SetPicMsg vbCrLf & "You have been " & vbCrLf & "signed in " & StudentName & vbCrLf, _
            MsgSuccessColor, _
            imgHello.Picture, _
            0, _
            Nothing
        SetMsgDuration ShortMsgDuration 'override default time to shorten
    End If
End Sub

'Signs in a specific student ID. Does not display anything visually
'on the screen.
Private Sub SignStudentIn()
'changes student status to signed in and refreshes date of last use
'add sign-in record to usage log
'this routine expects that the current record pointer is already
'set to the student that is signing in.
    StudentLastUse = Now

    OpenDbTable "tblStudents"
    On Error GoTo ErrHandler
    StudentTbl.Index = "PrimaryKey"
    StudentTbl.Seek "=", StudentId

    If NeedPid1 Then
        StudentPidList1 = ""
        For Counter = 0 To MaxPids - 1
            If PidSelections1(Counter) Then
                If Counter <> StudentPid1 Then StudentPidList1 = "," & Counter & StudentPidList1
            End If
        Next
        StudentPidList1 = StudentPid1 & StudentPidList1
    End If
    If NeedPid2 Then
        StudentPidList2 = ""
        For Counter = 0 To MaxPids - 1
            If PidSelections2(Counter) Then
                If Counter <> StudentPid2 Then StudentPidList2 = "," & Counter & StudentPidList2
            End If
        Next
        StudentPidList2 = StudentPid2 & StudentPidList2
    End If
    
    'change status of student to currently logged in
    'update last sign in time
    With StudentTbl
        .Edit
        .Fields("Status") = SignStatusIn 'signed in now
        .Fields("LastUse") = StudentLastUse
        ' set because can change each sign in
        ' build parsable, multiline string to hold PIDs
        If NeedPid1 Then .Fields("PIDs") = StudentPidList1
        If NeedPid2 Then .Fields("PIDs2") = StudentPidList2
        .Update
    End With
    
    StudentSignCount = StudentSignCount + 1

ErrHandler:
End Sub

'signs out single student
'changes student status to signed out and refreshes date of last use
'don't record usage log if <= 1 minute
'appends sign-in record in usage log
'this routine expects that the current record pointer is already
'set to the student that is signing in.
Private Sub SignStudentOut()
    Dim dateSignOut As Date
    Dim UsageId As Long
    dateSignOut = Now

    'opendbtable "tblStudents"
    On Error GoTo ErrHandler
    'change status of student to currently logged out
    With StudentTbl
        .Edit
        .Fields("Status") = SignStatusOut 'signed out now
        ' (already have these two things below)
        'StudentPid1 = .Fields("PID")
        'StudentLastUse = .Fields("LastUse") 'get sign in time
        ' (already set these signing in)
        'If NeedPid1 Then .Fields("PID") = StudentPid1
        'If NeedPid2 Then .Fields("PID2") = StudentPid2
        .Fields("LastUse") = dateSignOut  'set sign out time
        .Update
    End With
    StudentSignCount = StudentSignCount - 1

    If dateSignOut - StudentLastUse <= MinDuration Then Exit Sub

    'add entry to usage log
    OpenDbTable "tblTimes"
    With DbTbl
    .AddNew
    UsageId = .Fields("ID")
    'MsgBox "ID is " & UsageId
    .Fields("SID") = StudentId
    .Fields("SignIn") = StudentLastUse
    .Fields("SignOut") = dateSignOut
    .Fields("Duration") = dateSignOut - StudentLastUse
    'leave SignOut null for now to indicate not signed out yet
    .Update
    End With
    If NeedPid1 Then
        OpenDbTable "tblPidsUsed"
        AddUsagePids StudentPidList1, UsageId
    End If
    If NeedPid2 Then
        OpenDbTable "tblPidsUsed2"
        AddUsagePids StudentPidList2, UsageId
    End If

    'Originally I wanted to let students know how many hours they have
    'been using the lab, but since VB only gives me an annoyingly cryptic
    'error (object variable not set), I guess I won't! :Þ
    'datStudents.Database.OpenRecordset ("SELECT SUM(Duration) AS TotalDur FROM tblUsage WHERE SID=" & txtStudentId2.Text & ";")
    'datStudents.Database
    'DbTbl.MoveFirst
    'DbTbl.OpenRecordset ("SELECT SUM(Duration) AS TotalDur FROM tblUsage WHERE SID=" & txtStudentId2.Text & ";")
    '    .RecordSource = "SELECT SUM(Duration) AS TotalDur FROM tblUsage WHERE SID=" & txtStudentId2.Text
    '    .Refresh
    '    StudentDuration = .Recordset("TotalDur")
    'End With
    
    Exit Sub

ErrHandler:
    MsgBox "A database error occurred trying to sign you out: " & Err.Number & " " & Err.Description, vbOKOnly, "Sign Out Error"
End Sub

' parses a PID list and adds each PID to the list.
'
' input:
'   PidList - comma separated string of program IDs
'   UsageId - record identifier to match with date/duration records
'   DbTbl - open database table
'   StudentId - current student ID
Private Sub AddUsagePids(PidList As String, UsageId As Long)
    Dim CharPos As Long
    Dim PID As Long

    On Error GoTo ErrHandler
    With DbTbl
        Do
            PID = Val(Mid$(PidList, CharPos + 1))
            .AddNew
            .Fields("ID") = UsageId
            .Fields("SID") = StudentId
            .Fields("PID") = PID
            .Update
            CharPos = InStr(CharPos + 1, PidList, ",")
        Loop While CharPos
    End With
    Exit Sub

ErrHandler:
    MsgBox "A database error occurred trying to sign you out and append usage records: " & Err.Number & " " & Err.Description, vbOKOnly, "Sign Out Error"
End Sub

'Private Sub SignForgottenSidOut()
'    ExecSql "UPDATE tblUsage SET Duration=" & AverageDuration & " WHERE SID=" & txtStudentId2.Text & " AND Duration IS NULL;"
'End Sub

Private Sub SignAllSidsOut()
'used at the end of the day when lab closes and and all students
'should have logged out. Of course, you can always depend on a
'certain number of them who have not.
    SetMsg "Logging out all students who forget to sign out...", MsgSuccessColor, lstActions
    DoEvents

    ' add default usage records
    ExecSql "INSERT INTO tblUsage (SID,SignIn,SignOut,Duration,PID) " _
          & "SELECT tblStudents.SID,tblStudents.LastUse,tblStudents.LastUse+" & AverageDuration & ", " & AverageDuration & ",tblStudents.PID " _
          & "FROM tblStudents " _
          & "WHERE tblStudents.Status=1;"
    If Not DbIsOpen Then
        SetMsg "Could not add usage records (didn't execute SQL)!" & vbNewLine & DbErrMsg, MsgErrorColor, lstActions
        Exit Sub
    End If

    ' reset student status
    ExecSql "UPDATE tblStudents SET tblStudents.Status=" & SignStatusForgot & " WHERE tblStudents.Status=" & SignStatusIn & ";"
    If DbIsOpen Then
        If Db.RecordsAffected Then
            SetMsg "Signed out " & Db.RecordsAffected & " students who forgot to", MsgSuccessColor, lstActions
        Else
            'ClrErrorMsg
            SetMsg "All students are already signed out.", MsgSuccessColor, lstActions
        End If
        StudentSignCount = 0
    Else
        SetMsg "Could not reset student status (didn't execute SQL)!" & vbNewLine & DbErrMsg, MsgErrorColor, lstActions
    End If

End Sub

Private Sub cmdSetDbFile_Click()
    'If Not DbTbl Is Nothing Then If DbTbl.Name = Table Then Exit Sub
    If Not Db Is Nothing Then Db.Close: Set Db = Nothing: Set DbTbl = Nothing
    DbFilename = txtDbFilename.Text
    SetMsg "Loading program IDs from database...", MsgInformationColor, cmdSetDbFile
    DoEvents
    LoadPidLists
    If DbIsOpen Then PageView PageDefMenu
End Sub

Private Sub FillStudentInfoPage()
'reads information from the record into the appropriate control
'!assumes the current recordset is the desired student's
'matches what is in the text prompt.
    With DbTbl
        txtFirstName.Text = .Fields("FirstName")
        txtLastName.Text = .Fields("LastName")
        txtMiddleName.Text = .Fields("MiddleName")
        txtStudentMsg.Text = .Fields("Msg")
        txtDob.Text = IIf(StudentDob, Format(StudentDob, "yyyy-mm-dd"), "")
        StudentPid1 = .Fields("PIDs")
        lstPids.ListIndex = -1
        For Counter = lstPids.ListCount - 1 To 1 Step -1
            If lstPids.ItemData(Counter) = StudentPid1 Then
                lstPids.ListIndex = Counter
                Exit For
            End If
        Next
    End With
    HighlightTextPrompt txtFirstName
    HighlightTextPrompt txtMiddleName
    HighlightTextPrompt txtLastName
    HighlightTextPrompt txtStudentMsg
    HighlightTextPrompt txtDob
End Sub

' clears all the text controls on new/returning student page
Private Sub ClearStudentInfoPage()
    txtFirstName.Text = ""
    txtLastName.Text = ""
    txtMiddleName.Text = ""
    txtStudentMsg.Text = ""
    txtDob.Text = ""
    lstPidsSS.ListIndex = 0
    lstPidsSM.ListIndex = -1
    lstPidsLS.ListIndex = 0
    lstPidsLM.ListIndex = -1
End Sub

Private Sub cmdCancel_Click()
    Dim Page As Long, Duration As Long

    Select Case PageVisible
    Case PageDefGetName, PageDefVerifyName, PageDefGetPid1, PageDefGetPid2
        Page = PageDefSignIn
    Case PageDefSelectBackground
        If chkPreview.Value Then RedrawBg BgPic
        Page = PageDefMenu
    Case Else
        Page = PageDefMenu
    End Select
    PageView Page
    Exit Sub
End Sub

Private Sub cmdDeleteRecords_Click()
'deletes usage log records from entire term
'deletes old records for students who haven't use the lab for a while
    Dim StudentRecs As Long, UsageRecs As Long
    Dim TempDbFile As String

    If MsgBox("Are you really, truly, certainly, absolutely sure?", vbExclamation Or vbYesNo Or vbDefaultButton2, "Delete entire term student usage records") = vbYes Then

        SetMsg "Compacting old database...", MsgSuccessColor, cmdDeleteRecords
        'RepairDatabase DbFilename 'no longer supported by DAO 3.6 (Access 2000)
        If Not Db Is Nothing Then
            Db.Close
            Set Db = Nothing
        End If
        TempDbFile = AppPath & Format$(Now, "yyyy-mm-dd hh.mm.ss ") & DbFilenameDef
        On Error GoTo DeleteRecErr
        CompactDatabase DbFilename, TempDbFile

        SetMsg "Deleting all student records for those haven't signed in over 180 days...", MsgSuccessColor, cmdDeleteRecords
        DoEvents
        ExecSql "DELETE * FROM tblStudents WHERE [LastUse]+180<Now;"
        If Not DbIsOpen Then
            SetMsg "Could not execute SQL deletion statement!" & vbNewLine & DbErrMsg, MsgErrorColor, cmdDeleteRecords
            Exit Sub
        End If

        StudentRecs = Db.RecordsAffected
        ExecSql "UPDATE tblStudents SET tblStudents.Status=" & SignStatusNewTerm & ";"
        ExecSql "DELETE * FROM tblUsage;"
        'ExecSql "DELETE * FROM tblUsedPids;"
        UsageRecs = Db.RecordsAffected

        Db.Close 'close the database once more
        Set Db = Nothing
        
        TempDbFile = AppPath & "TEMP.MDB"
        If Len(Dir$(TempDbFile)) Then Kill TempDbFile  'just in case it already exists from a failed attempt
        Name DbFilename As TempDbFile
        CompactDatabase TempDbFile, DbFilename
        Kill TempDbFile 'now delete it for sure

        SetMsg "Deleted " & StudentRecs & " student records, reset everyone's status for new term, and cleared " & UsageRecs & " sign in records.", MsgSuccessColor, cmdDeleteRecords
    End If
    Exit Sub
    
DeleteRecErr:
    If Err.Number = 53 Then Resume Next
    SetMsg "Could not compact file. Be sure it is not read only and that you have sufficient permission:" & vbNewLine & vbNewLine & DbFilename & vbNewLine & vbNewLine & Err.Description, MsgErrorColor, cmdDeleteRecords

End Sub

' monster branching routine that moves to the next page,
' depending on what options were set in the ini file.
'
' input:
'   StudentStatus
'   NeedPid1
'   NeedPid2
Private Sub PageNext()
    Dim NewPage As Long
    Dim AskPid1 As Long
    Dim AskPid2 As Long

    ' ask for PID if first time or if needed every time
    If (StudentStatus = SignStatusNewStudent) Or (StudentStatus = SignStatusNewTerm) Then
        AskPid1 = NeedPid1
        AskPid2 = NeedPid2
    Else
        AskPid1 = NeedPid1 And NeedPidAlways
        AskPid2 = NeedPid2 And NeedPidAlways
    End If

    Select Case PageVisible
    Case PageDefSignIn
        txtStudentId.Text = "" 'always clear this regardless
        If NeedName And StudentStatus = SignStatusNewStudent Then 'first time student
            ClearStudentInfoPage
            NewPage = PageDefGetName
        ElseIf NeedName And StudentStatus = SignStatusNewTerm Then 'returning student
            'new term, so verify previous information
            FillStudentInfoPage
            NewPage = PageDefVerifyName
        Else 'StudentStatus = SignStatusOut (not signed in)
            If AskPid1 Then
                NewPage = PageDefGetPid1
            ElseIf AskPid2 Then
                NewPage = PageDefGetPid2
            Else
                SignStudentInWithMsg
            End If
        End If
    Case PageDefGetName, PageDefVerifyName, PageDefGetPid1
        If AskPid2 Then 'get student's secondary purpose (primary was already recorded)
            NewPage = PageDefGetPid2
        Else
            SignStudentInWithMsg 'sign student in, display msg, and return to main page
        End If
    Case PageDefGetPid2
        SignStudentInWithMsg 'sign student in, display msg, and return to main page
    Case PageDefEditInfo
        ClearStudentInfoPage
        txtStudentId2.Text = ""
        NewPage = PageDefEditInfo
    End Select
    
    'populate PID list boxes accordingly
    If NewPage Then
        Select Case NewPage
        Case PageDefGetName, PageDefVerifyName, PageDefEditInfo
            If NeedPid1 And NeedPidMulti Then
                Set lstPids = lstPidsSM 'small multiple
            Else
                Set lstPids = lstPidsSS 'small single
            End If
            GetPidsUsed PidSelections1
            BuildPidList lstPids, PidValues1(), PidNames1(), PidSelections1(), StudentPid1
        Case PageDefGetPid1
            If NeedPid1 And NeedPidMulti Then
                Set lstPids = lstPidsLM 'small multiple
            Else
                Set lstPids = lstPidsLS 'small single
            End If
            GetPidsUsed PidSelections1
            BuildPidList lstPids, PidValues1(), PidNames1(), PidSelections1(), StudentPid1
        Case PageDefGetPid2
            If NeedPid2 And NeedPidMulti Then
                Set lstPids = lstPidsLM 'small multiple
            Else
                Set lstPids = lstPidsLS 'small single
            End If
            GetPidsUsed PidSelections2
            BuildPidList lstPids, PidValues2(), PidNames2(), PidSelections2(), StudentPid2
        End Select

        PageView NewPage
    End If

End Sub

'the huge routine responsible for changing pages, setting certain controls
'visible, other invisible, setting default command button
Private Sub PageView(Page As Long)
    Dim CurCtl As Control

    If MessageShown Then ClrErrorMsg
    PageVisible = Page
    ClickingAction = False 'just a safety


    For Each CurCtl In Me
        With CurCtl
            If TypeName(CurCtl) <> "Timer" Then
            If CurCtl.Top >= 150 Then 'only hide if not permanent
                CurCtl.Visible = False
            End If
            End If
        End With
    Next

    Select Case PageVisible
    Case PageDefMenu:
        lstActions.Visible = True
        lstActions.SetFocus
    Case PageDefSignIn:
        Label5.Visible = True
        lblKnumber.Visible = True
        txtStudentId.Visible = True
        lblDateCaption.Visible = True
        lblDate.Visible = True
        lblTimeCaption.Visible = True
        lblTime.Visible = True
        cmdSignInOut.Visible = True
        cmdSignInOut.Default = True
        tmrTime_Timer
        txtStudentId.SetFocus
    Case PageDefSetDbFile
        txtDbFilename.Text = DbFilename
        HighlightTextPrompt txtDbFilename
        txtDbFilename.Visible = True
        cmdSetDbFile.Visible = True
        cmdSetDbFile.Default = True
        lblDbFilename.Visible = True
        cmdCancel.Visible = True
    Case PageDefGetName, PageDefEditInfo, PageDefVerifyName
        Label9.Visible = True
        lblMiddle.Visible = True
        Label11.Visible = True
        Label12.Visible = True
        txtDob.Visible = NeedDob
        lblDob.Visible = NeedDob
        txtFirstName.Visible = True
        txtMiddleName.Visible = True
        txtLastName.Visible = True
        lstPids.Visible = True
        cmdSubmit.Visible = True
        cmdSubmit.Default = True
        If Page = PageDefEditInfo Then
            txtStudentId2.Enabled = True
            txtStudentId2.PasswordChar = ""
            lblMessage.Visible = True
            txtStudentMsg.Visible = True
            txtStudentId2.Visible = True
            txtStudentId2.SetFocus
        Else
            txtStudentId2.PasswordChar = "*"
            txtStudentId2.Enabled = False
            txtStudentId2.Visible = True
            txtFirstName.SetFocus
        End If
        cmdCancel.Visible = True
    Case PageDefSelectBackground
        txtBgFilename.Visible = True
        filBgs.Visible = True
        dirBgs.Visible = True
        drvBgs.Visible = True
        cmdChangeBg.Visible = True
        cmdChangeBg.Default = True
        chkPreview.Visible = True
        cmdDefBg.Visible = True
        cmdCancel.Visible = True
    Case PageDefDelRecords
        cmdDeleteRecords.Visible = True
        cmdCancel.Visible = True
    Case PageDefGetPid1, PageDefGetPid2
        lstPids.Visible = True
        cmdChoose.Visible = True
        cmdChoose.Default = True
        cmdCancel.Visible = True
        lstPids.SetFocus
    End Select

    tmrTime.Enabled = (PageVisible = PageDefSignIn)

    Select Case PageVisible
    Case PageDefMenu: lblInstructions.Caption = "Click on the action below in the list or press Enter."
    Case PageDefSignIn: lblInstructions.Caption = WelcomeMsg
    Case PageDefGetName: lblInstructions.Caption = NewStudentMsg
    Case PageDefGetPid1: lblInstructions.Caption = Replace$(PidMsg1, "\s", StudentName)
    Case PageDefGetPid2: lblInstructions.Caption = Replace$(PidMsg2, "\s", StudentName)
    Case PageDefEditInfo: lblInstructions.Caption = "Enter the ID number of the student whose information you want to change."
    Case PageDefDelRecords: lblInstructions.Caption = "Clicking Delete will remove all records of students who have not signed in for over 180 days (half year) and clear all sign in/out logs for the current term/year. You MUST close all other programs using StudentLog.mdb (including any other open sign-in program) for the repair and compaction to work. Choose <Back> when done."
    Case PageDefSetDbFile: lblInstructions.Caption = "Enter the full path and filename to the correct student database."
    Case PageDefVerifyName: lblInstructions.Caption = NewTermMsg
    Case PageDefSelectBackground: lblInstructions.Caption = "Double click on the desired background from the file list. Preview is on by default. Choose Back to keep the previous background."
    End Select
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyNumlock Or KeyCode = vbKeyCapital Then
        CorrectKeyStates
        SetMsg "Leave NumLock on and Caps lock off for the other students", MsgInformationColor, Nothing
    'ElseIf KeyCode = vbKeyF10 Then
    '    SavePicture Image, AppPath & "TEST.BMP"
    End If
End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
'escape to main menu by holding (Control+Shift) and clicking anywhere on form
    If (Shift And 7) = 7 And (Button And 2) Then 'shift, control, alt
        PageView (PageVisible + 1) Mod PageDefTotal
    ElseIf (Shift And 3) = 3 Then 'shift and control
        PageView PageDefMenu
    End If
End Sub

'Private Sub Form_Paint()
    'Me.PaintPicture Pic
'End Sub

Private Sub Form_Unload(Cancel As Integer)
    SetMsg "Terminating program...", MsgErrorColor, lstActions
    DoEvents
    If StudentSignCount > 0 Then
        If MsgBox("At least " & StudentSignCount & " students forgot to log out. Log them out now?", vbQuestion Or vbYesNo) = vbYes Then
            SignAllSidsOut
        End If
    End If
    DoEvents
End Sub

Private Sub lblAbout_Click()
'credits and greetings
    SetPicMsg ProgramTitle & " Sign-In program, by Dwayne Robinson on 2001-01-29 : 2003-09-15" & vbNewLine & vbNewLine _
        & "Thanks to Daniel, Brian, Luke, Leanne, Linda, Susan, Shay, and Shirley for suggestions and input. " _
        & "Greets to Vahan, Shawn, Jim, Cliff, Russell, loving mom, and grumpy dad..." & vbNewLine & vbNewLine _
        & "http://fdwr.tripod.com/about.htm" & vbNewLine & "FDwR@hotmail.com", _
        MsgInformationColor, _
        imgMyMascot.Picture, _
        1, _
        Nothing
End Sub

Private Sub lblExit_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Form_MouseDown Button, Shift, X, Y
End Sub

Private Sub lstActions_Click()
    If ClickingAction Then lstActions_DblClick
End Sub

Private Sub lstActions_DblClick()
    'main menu
    ClickingAction = False
    Select Case lstActions.ListIndex
    Case 0: PageView PageDefSignIn
        'Dim dateSignOut As Date
        'dateSignOut = #4/27/2001 3:35:05 PM#
        'OpenDbTable "tblTimes"
        'seek backwards for most recent sign in record
        'since new records are always appended to previous ones, it's faster
        'to search from the back than front
        'DbTbl.FindLast "SID=" & txtStudentId2.Text & "AND SignOut=#" & dateSignOut & "#"
    Case 1: PageVisible = PageDefEditInfo
            PageNext
    Case 2: PageView PageDefSelectBackground
            filBgs.SetFocus
    Case 3: PageView PageDefSetDbFile
            txtDbFilename.SetFocus
    Case 4: PageView PageDefDelRecords
    Case 5: 'used at the end of the day when lab closes and and all students
            'should have logged out. Of course, you can always depend on a
            'certain number of them who have not.
            SignAllSidsOut
    Case 6: lblAbout_Click
    Case 7: Unload Me
    End Select
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

Private Sub lstPidsLM_Click()
    If ClickingAction Then
        ClickingAction = False
        cmdChoose_Click
    End If
End Sub

Private Sub lstPidsLM_DblClick()
    Dim idx As Long
    idx = lstPidsLM.ListIndex
    If idx > 0 Then lstPidsLM.Selected(idx) = True
    cmdChoose_Click
End Sub

Private Sub lstPidsLS_Click()
    If ClickingAction Then
        ClickingAction = False
        cmdChoose_Click
    End If
End Sub

Private Sub lstPidsLS_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    ClickingAction = True
End Sub

Private Sub lstPidsLS_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    ClickingAction = False
End Sub

Private Sub msgWindow_CloseMe()
'close error message if user clicked on it
    ClrErrorMsg
End Sub

Private Sub tmrTime_Timer()
    lblTime.Caption = LCase$(Format$(Time$, "HH:mm:ssAMPM"))
    'lblDate.Text = CSng(Date) 'Time
    If CLng(Date) <> CLng(PrevUseDate) Then
        ' sign out yesterday's people
        ' added this line after learning that some people
        ' were leaving the computer on all the time,
        ' never shutting it off; and thus, the program
        ' didn't log out previous students -_-
        SignAllSidsOut
        PrevUseDate = Date
        lblDate.Caption = Format$(PrevUseDate, "yyyy-mm-dd")
    End If
End Sub

Private Sub tmrMsgClear_Timer()
'only display error messages and sign in/out messages for so long
    tmrMsgClear.Enabled = False
    If MessageShown Then ClrErrorMsg
    'PageView PageVisible
End Sub

Private Sub SetMsgDuration(Duration As Long)
    tmrMsgClear.Enabled = False
    tmrMsgClear.Interval = Duration
    tmrMsgClear.Enabled = True
End Sub

Private Sub txtBgFilename_Change()
    If chkPreview.Value And Len(txtBgFilename.Text) > 0 Then
        Dim PreviewPic As StdPicture
        On Error GoTo PicErr
        Set PreviewPic = LoadPicture(txtBgFilename.Text)
        RedrawBg PreviewPic
    End If
PicErr:
End Sub

Private Sub txtBgFilename_GotFocus()
    HighlightTextPrompt txtBgFilename
End Sub

Private Sub txtDob_LostFocus()
    StudentDob = 0
    On Error Resume Next 'stupid little error handler
    StudentDob = DateValue(txtDob.Text)
    On Error GoTo 0
    If StudentDob Then
        txtDob.Text = Format(StudentDob, "yyyy-mm-dd")
        HighlightTextPrompt txtDob
    End If
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

Private Sub txtStudentId_KeyPress(KeyAscii As Integer)
'accept only numbers, ignoring hyphens, space, and letters
    If KeyAscii < vbKeySpace Then
        If KeyAscii = vbKeyEscape Then txtStudentId.Text = ""
    Else
        AllowSidKeysOnly KeyAscii, txtStudentId
        txtStudentId.SelText = Chr(KeyAscii)
        KeyAscii = 0
    End If
End Sub

Private Sub txtDob_KeyPress(KeyAscii As Integer)
    Dim CaretPos As Long

    If KeyAscii = 46 Or KeyAscii = 92 Then KeyAscii = 45 'period or slash to hyphen
    Select Case KeyAscii
    Case 45, 47 'check separators
        CaretPos = txtDob.SelStart
        If CaretPos Then
            Select Case Asc(Mid$(txtDob.Text, txtDob.SelStart, 1))
            Case 48 To 57 'allow numbers
            Case 45, 46, 47, 92 'replace existing separator
                txtDob.SelStart = CaretPos - 1
                txtDob.SelLength = 1
            End Select
        Else
            KeyAscii = 0
        End If
    Case 48 To 57 'allow numbers
    Case 8 'allow backspace
    Case Else
        KeyAscii = 0
    End Select
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
    MessageShowTime = Timer
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
    ReleaseCapture          'redudant release since VB does NOT! >:-| always properly send
    MessageShown = False    'the Hide event event to my control
End Sub

Private Sub txtStudentId2_Change()
'for the Edit Student info page
'after a full 9 digit SID has been typed in, read student info for that SID
    Dim Keys(255) As Byte

    If PageVisible = PageDefEditInfo And Len(txtStudentId2.Text) = 9 Then
        ' if any keys held down, wait until all up
WaitForAllKeys:
        GetKeyboardState Keys(0)
        For Counter = 32 To 128
            If Keys(Counter) And &H80 Then
                DoEvents
                GoTo WaitForAllKeys
            End If
        Next

        OpenDbTable "tblStudents"
        If DbIsOpen Then
            StudentId = GetNumericSid(txtStudentId2.Text)
            DbTbl.Index = "PrimaryKey"
            DbTbl.Seek "=", StudentId
            If Not DbTbl.NoMatch Then
                FillStudentInfoPage
                txtFirstName.SetFocus
            Else
                SetMsg "No student with that SID.", MsgErrorColor, cmdSubmit
                txtFirstName.Text = ""
                txtLastName.Text = ""
                txtMiddleName.Text = ""
                txtStudentMsg.Text = ""
                lstPidsSS.ListIndex = 0 'move caret to top of list
                lstPidsSS.ListIndex = -1 'select none
            End If
        Else
            SetMsg "Error opening database! (need tblStudents)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSubmit
        End If
        HighlightTextPrompt txtStudentId2
    End If
End Sub

Private Sub txtStudentId2_KeyPress(KeyAscii As Integer)
    AllowNumberKeysOnly KeyAscii, txtStudentId2
End Sub

Private Function GetTimeDifMsg(TimeDif As Double)
    Dim Msg As String

    Select Case TimeDif
    Case Is <= 0:     Msg = "in the future (!?)"
    Case Is < 0.0416: Msg = Int(TimeDif * 1440) & " minutes ago"
    Case Is < 1:      Msg = Format(TimeDif * 24, "0.0") & " hours ago"
    Case Is < 2:      Msg = "yesterday"
    Case Else:        Msg = Int(TimeDif) & " days ago"
    End Select

    GetTimeDifMsg = Msg

End Function

Private Sub HighlightTextPrompt(txtHighlight As TextBox)
    txtHighlight.SelStart = 0
    txtHighlight.SelLength = 32767
End Sub

' Only read once at beginning of program,
' or after changing the database file.
Private Sub LoadPidLists()

    'build primary program ID list
    OpenDbTable "tblPids"
    If NeedPid1 Then
        If DbIsOpen Then
            With DbTbl
                For Counter = 0 To MaxPids - 1
                    If .EOF Then Exit For
                    PidValues1(Counter) = .Fields("PID")
                    PidNames1(Counter) = .Fields("Name")
                    .MoveNext
                Next
            End With
        Else
            SetMsg "Could not read primary list of PIDs from database! (need tblPids)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSetDbFile
            Exit Sub
        End If
    End If
    
    'build secondary list
    If NeedPid2 Then
        OpenDbTable "tblPids2"
        If DbIsOpen Then
            With DbTbl
                For Counter = 0 To MaxPids - 1
                    If .EOF Then Exit For
                    PidValues2(Counter) = .Fields("PID")
                    PidNames2(Counter) = .Fields("Name")
                    .MoveNext
                Next
            End With
        Else
            SetMsg "Could not read secondary list of PIDs from database! (need tblPids2)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSetDbFile
            Exit Sub
        End If
    End If

End Sub


'Fills a given listbox with program IDs
'For single selection, will select appropriate item
'For multiple selection, puts previously used PIDs near front
'   NewLstPids - list box to fill
'   PidValues - program ID values (0-999)
'   PidNames - program names (Science, English...)
'   PidSelections - program IDs that have already used before (only if multi) (true if used, false if not)
'   PidValue - last used program ID (valid for single or multi)
'
' Notes:
'   PidNames and PidValues are packed towards the front,
'       with empty space at the end. The PID with value 34
'       could be in any order in the list.
'   PidSelections is sparse, with empty areas throughout.
'       If PID 34 has been used, array index 34 is true.
'       It's just this way because it is easier for other
'       parts of the code to handle it.
Private Sub BuildPidList(NewLstPids As ListBox, PidValues() As Long, PidNames() As String, PidSelections() As Boolean, PidValue)
    'Dim MultiChoose As Long
    'MultiChoose = lstPids.MultiSelect

    'clear list
    'add courses the student has already entered first
    'add remaining courses to end of list that they haven't taken
    'find pid of last course taken by student and select it
    With lstPids
        .Clear
        'lstPids.ListIndex = -1
        If PidValue < MaxPids And PidValue >= 0 Then PidSelections(PidValue) = True
        For Counter = 0 To MaxPids - 1
            If PidValues(Counter) <= 0 Then Exit For
            If PidSelections(PidValues(Counter)) Then
                .AddItem ("»" & PidNames(Counter))
                .ItemData(.NewIndex) = PidValues(Counter)
                If PidValues(Counter) = PidValue Then .ListIndex = .NewIndex
            End If
        Next
        For Counter = 0 To MaxPids - 1
            If PidValues(Counter) <= 0 Then Exit For
            If Not PidSelections(PidValues(Counter)) Then
                .AddItem PidNames(Counter)
                .ItemData(.NewIndex) = PidValues(Counter)
                If PidValues(Counter) = PidValue Then .ListIndex = .NewIndex
            End If
        Next
        If NewLstPids Is lstPidsLS Or NewLstPids Is lstPidsLM Then
            .Columns = IIf(.ListCount <= 10, 1, 2)
        End If
    End With

End Sub


' gets which items are selected from a multiple selection list box
' and sets the flags in an array.
'
' returns:
'   number of items selected (0 if none)
'   always returns 1 for a single selection list
Private Function GetPidsSelected(PidSelections() As Boolean) As Long
    Dim Value As Long
    Dim SelCount As Long

    Erase PidSelections
    If lstPids.MultiSelect = 0 Then
        GetPidsSelected = 1
        Exit Function
    End If
    With lstPids
        For Counter = 0 To .ListCount - 1
            If .Selected(Counter) Then
                Value = .ItemData(Counter)
                If Value < MaxPids Then
                    PidSelections(Value) = True
                    SelCount = SelCount + 1
                End If
            End If
        Next
    End With
    GetPidsSelected = SelCount
End Function


Private Function GetPidsUsed(PidsUsed() As Boolean)
    ' just clear all bits for now
    Erase PidsUsed

#If 0 Then
    OpenDbTable "SELECT * FROM tblUsedPids WHERE SID=" & StudentId & ";"
    If DbIsOpen Then
        lstPidsLS.Clear
        Erase UsedPids
        With DbTbl
            Do Until .EOF
                Value = .Fields("PID")
                If Value < MaxPids And Value >= 0 Then
                    UsedPids(Value) = True
                    With lstPids2
                        .AddItem ("»" & PidNames(Value))
                        .ItemData(.NewIndex) = Value
                        If Value = StudentPid1 Then .ListIndex = .NewIndex
                    End With
                End If
                .MoveNext
            Loop
        End With
    Else
        SetMsg "Error opening database! (need tblUsedPids)" & vbNewLine & DbErrMsg, MsgErrorColor, cmdSignInOut
        Exit Sub
    End If
#End If
End Function


Private Sub LoadSettings()
    Dim Line As String, KeyName As String, Equate As String
    Dim SepPos As Long
    Dim SettingsErrMsg As String

    Dim FontObject As Object
    Dim FontObjectType As String
    Dim FontName As String
    Dim FontSize As Long
    Dim FontAlign As Long
    Dim FontWeight As Long
    Dim FontItalic As Long
    Dim FontColor As Long
    Dim BackColor As Long

    On Error GoTo IgnoreMissingSettings
    Open AppPath & "SignIn.ini" For Input As 1
    On Error GoTo 0

    ' set message defaults in case settings file
    ' does not have any specific ones
    WelcomeMsg = "Welcome to the lab. Please enter your student ID number to sign in." & vbNewLine & vbNewLine & "Remember to sign out before leaving. Thank you :-)"
    NewTermMsg = "Is all this information still correct from the last time you signed in?"
    NewStudentMsg = "We do not currently have you in this system. Please enter the following information, or if you have already entered it and simply typed the wrong student ID, click <Back> to return."
    PidMsg1 = "Hello \s. Please select the area you will be working in today."
    PidMsg2 = PidMsg1
    RegFormMsg = "You have signed into the system, but since this is your first time this term, remember to also fill in the paper form."
    PidCaption1 = "Program"
    PidCaption2 = PidCaption1

    GoSub ClearFontAtrs

    Do Until EOF(1)
        Line Input #1, Line
        SepPos = InStr(Line, "=")
        If SepPos Then
            KeyName = Left$(Line, SepPos - 1)
            Equate = Replace$(Mid$(Line, SepPos + 1), "\n", vbCrLf)
            Value = Val(Equate)
            If Value = 0 Then
                Select Case LCase$(Equate)
                Case "true", "yes": Value = True
                End Select
            End If
        Else
            KeyName = Line
            Equate = ""
            Value = 0
        End If

        Select Case LCase$(KeyName)
        Case "welcomemsg": WelcomeMsg = Equate
        Case "newtermmsg": NewTermMsg = Equate
        Case "newstudentmsg": NewStudentMsg = Equate
        Case "regformmsg": RegFormMsg = Equate
        Case "pidmsg1": PidMsg1 = Equate
        Case "pidmsg2": PidMsg2 = Equate
        Case "needpid1", "needpid": NeedPid1 = Value
        Case "needpid2": NeedPid2 = Value
        Case "regformimage": LoadCustomImage Equate, imgRegForm, "registration form"
        Case "helloimage": LoadCustomImage Equate, imgHello, "sign-in greeting"
        Case "byeimage": LoadCustomImage Equate, imgBye, "sign-out"
        Case "forgotimage": LoadCustomImage Equate, imgForgot, "sign-out forgot"
        Case "backgroundimage": LoadCustomImage Equate, imgDefBg, "default background"
                                txtBgFilename.Text = Equate
        Case "imagepath": ImagePath = Equate
        Case "showregform": ShowRegForm = Value
        Case "needdob": NeedDob = Value
        Case "averageduration": AverageDuration = Value / 1440 'divide by number of minutes in day
        Case "minduration": MinDuration = Value / 1440 'divide by number of minutes in day
        Case "databasefile": DbFilename = AppPath & Equate
        Case "form"
            Set FontObject = Me
        Case "title":
            GoSub SetFontControl
            Set FontObject = lblTitle
        Case "subtitle"
            GoSub SetFontControl
            Set FontObject = lblSubtitle
        Case "instructions"
            GoSub SetFontControl
            Set FontObject = lblInstructions
        Case "message"
            GoSub SetFontControl
            Set FontObject = msgWindow
        Case ".text": FontObject.Caption = Equate
        Case ".fontname": FontName = Equate
        Case ".fontalign":
            If Not FontObject Is Me Then FontAlign = Value
        Case ".fontsize": FontSize = Value
        Case ".fontweight": FontWeight = Value
        Case ".fontitalic": FontItalic = Value
        Case ".fontcolor", ".forecolor":
            FontColor = Val("&h" & Equate) 'special case, parse hex code
            ReverseRGB FontColor
        Case ".backcolor":
            BackColor = Val("&h" & Equate) 'special case, parse hex code
            ReverseRGB BackColor
        Case "pidcaption1": PidCaption1 = Equate: lblPids.Caption = PidCaption1
        Case "pidcaption2": PidCaption2 = Equate
        End Select

    Loop
    GoSub SetFontControl 'just in case reached end of file first
    
    Close 1
    Exit Sub

' sets the font of the given control (actually, the previous one)
SetFontControl:
    If Not FontObject Is Nothing Then 'only set if previous object exists
        If FontObject Is Me Then
            For Each FontObject In Me
                FontObjectType = TypeName(FontObject)
                Select Case FontObjectType
                Case "Label", "ListBox", "msgWindow", "TextBox" '"CommandButton",
                    GoSub SetFont
                End Select
            Next
        Else
            FontObjectType = TypeName(FontObject)
            GoSub SetFont
        End If
    End If

ClearFontAtrs:
    'reset all attributes for next object
    FontName = ""
    FontSize = -2
    FontAlign = -2
    FontBold = -2
    FontItalic = -2
    FontColor = -2
    BackColor = -2
Return

' expects all the font variables are already set before calling
SetFont:
    With FontObject.Font
        If Len(FontName) Then .Name = FontName
        If FontSize > 0 Then .Size = FontSize
        If FontWeight > -2 Then .Weight = FontWeight
        If FontItalic > -2 Then .Italic = FontItalic
    End With
    If FontAlign > -2 Then
        If FontObjectType = "Label" Then FontObject.Alignment = FontAlign
    End If
    If FontColor > -2 Then FontObject.ForeColor = FontColor
    If BackColor > -2 Then
        Select Case FontObjectType
        Case "ListBox", "TextBox", "Label"
            FontObject.BackColor = BackColor
        End Select
    End If
Return

IgnoreMissingSettings:
End Sub

Private Sub LoadCustomImage(File As String, Pic As Image, ImgMsg As String)
    On Error GoTo LoadSignInImageErr
    Pic.Picture = LoadPicture(AppPath & File)
    Exit Sub

LoadSignInImageErr:
    MsgBox "Could not load " & ImgMsg & " image: " & File

End Sub

'reverse RGB byte order because stupid windows puts blue first,
'while the rest of the world, hardware manufacturers, console
'developers, other operating systems, and webpages, all put them
'in the logical order RGB (but that's windows and VB for you)
Private Sub ReverseRGB(Color As Long)
    Color = (Color And 65280) Or ((Color And 255&) * 65536) Or ((Color And 16711680) \ 65536)
End Sub

