VERSION 5.00
Begin VB.Form frmUpdate 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Updating Catalog"
   ClientHeight    =   2355
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   5445
   Icon            =   "frmUpdate.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   2355
   ScaleWidth      =   5445
   StartUpPosition =   2  'CenterScreen
   Begin VB.Timer tmrLoad 
      Interval        =   1
      Left            =   4920
      Top             =   1800
   End
   Begin VB.Timer tmrBlink 
      Interval        =   200
      Left            =   1920
      Top             =   1800
   End
   Begin VB.Image imgPic 
      Height          =   480
      Index           =   2
      Left            =   0
      Picture         =   "frmUpdate.frx":058A
      Top             =   1080
      Width           =   480
   End
   Begin VB.Image imgPic 
      Height          =   480
      Index           =   1
      Left            =   0
      Picture         =   "frmUpdate.frx":09CC
      Top             =   600
      Width           =   480
   End
   Begin VB.Image imgPic 
      Height          =   480
      Index           =   0
      Left            =   0
      Picture         =   "frmUpdate.frx":0E0E
      Top             =   120
      Width           =   480
   End
   Begin VB.Label Label3 
      Caption         =   "Compiling Catalog..."
      BeginProperty Font 
         Name            =   "Arial"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   495
      Left            =   600
      TabIndex        =   2
      Top             =   1080
      Width           =   5295
   End
   Begin VB.Label Label2 
      Caption         =   "Reading Hard Disk(s)..."
      BeginProperty Font 
         Name            =   "Arial"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   495
      Left            =   600
      TabIndex        =   1
      Top             =   600
      Width           =   5295
   End
   Begin VB.Label Label1 
      Caption         =   "Loading CD Database..."
      BeginProperty Font 
         Name            =   "Arial"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   495
      Left            =   600
      TabIndex        =   0
      Top             =   120
      Width           =   5295
   End
   Begin VB.Image imgPic3 
      Height          =   480
      Left            =   1320
      Picture         =   "frmUpdate.frx":1250
      Top             =   1800
      Visible         =   0   'False
      Width           =   480
   End
   Begin VB.Image imgPic1 
      Height          =   480
      Left            =   120
      Picture         =   "frmUpdate.frx":1692
      Top             =   1800
      Visible         =   0   'False
      Width           =   480
   End
   Begin VB.Image imgPic2 
      Height          =   480
      Left            =   720
      Picture         =   "frmUpdate.frx":1AD4
      Top             =   1800
      Visible         =   0   'False
      Width           =   480
   End
End
Attribute VB_Name = "frmUpdate"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Public CurrentItem As Integer
Dim BlinkTick As Integer

Private Sub Form_Load()
    If BootUpdate Then
        'Just Load Database
        frmUpdate.Height = 1530
    Else
        'Load Database and Update Catalog
        frmUpdate.Height = 2070
    End If
End Sub

Private Sub tmrBlink_Timer()
    BlinkTick = BlinkTick + 1
    If BlinkTick = 2 Then
        imgPic(CurrentItem) = imgPic3
    ElseIf BlinkTick = 3 Then
        BlinkTick = 0
        imgPic(CurrentItem) = imgPic2
    End If
End Sub

Private Sub tmrLoad_Timer()
    tmrLoad.Enabled = False
    RunUpdate
    'Unload frmUpdate
End Sub

Sub NextItem()
    CurrentItem = CurrentItem + 1
    imgPic(CurrentItem - 1) = imgPic1
    DoEvents
End Sub
