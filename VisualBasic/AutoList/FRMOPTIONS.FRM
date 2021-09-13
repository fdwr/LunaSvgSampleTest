VERSION 5.00
Object = "{86CF1D34-0C5F-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCT2.OCX"
Begin VB.Form frmOptions 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Options"
   ClientHeight    =   2655
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   4575
   Icon            =   "frmOptions.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   2655
   ScaleWidth      =   4575
   StartUpPosition =   1  'CenterOwner
   Begin VB.CommandButton cmdOk 
      Caption         =   "&Ok"
      Default         =   -1  'True
      Height          =   375
      Left            =   2880
      TabIndex        =   5
      Top             =   2160
      Width           =   1575
   End
   Begin VB.CommandButton cmdCancel 
      Caption         =   "&Cancel"
      Height          =   375
      Left            =   120
      TabIndex        =   4
      Top             =   2160
      Width           =   1575
   End
   Begin VB.Frame Frame4 
      Caption         =   "Print how many recent files:"
      Height          =   615
      Left            =   2280
      TabIndex        =   10
      Top             =   0
      Width           =   2295
      Begin MSComCtl2.UpDown UpDown2 
         Height          =   240
         Left            =   1680
         TabIndex        =   1
         Top             =   240
         Width           =   495
         _ExtentX        =   873
         _ExtentY        =   423
         _Version        =   393216
         Value           =   1
         Max             =   100
         Min             =   1
         Orientation     =   1
         Enabled         =   -1  'True
      End
      Begin VB.Label lblRecent 
         Alignment       =   2  'Center
         Caption         =   "XX Files"
         Height          =   255
         Left            =   120
         TabIndex        =   11
         Top             =   240
         Width           =   1455
      End
   End
   Begin VB.Frame Frame3 
      Caption         =   "New files is younger than:"
      Height          =   615
      Left            =   0
      TabIndex        =   8
      Top             =   0
      Width           =   2175
      Begin MSComCtl2.UpDown UpDown1 
         Height          =   240
         Left            =   1560
         TabIndex        =   0
         Top             =   240
         Width           =   495
         _ExtentX        =   873
         _ExtentY        =   423
         _Version        =   393216
         Value           =   1
         Max             =   12
         Min             =   1
         Orientation     =   1
         Enabled         =   -1  'True
      End
      Begin VB.Label lblAge 
         Alignment       =   2  'Center
         Caption         =   "X Weeks"
         Height          =   255
         Left            =   120
         TabIndex        =   9
         Top             =   240
         Width           =   1335
      End
   End
   Begin VB.Frame Frame2 
      Caption         =   "Output Path:"
      Height          =   615
      Left            =   0
      TabIndex        =   7
      Top             =   1440
      Width           =   4575
      Begin VB.TextBox txtOutput 
         Height          =   285
         Left            =   120
         TabIndex        =   3
         Top             =   240
         Width           =   4335
      End
   End
   Begin VB.Frame Frame1 
      Caption         =   "Template Path:"
      Height          =   615
      Left            =   0
      TabIndex        =   6
      Top             =   720
      Width           =   4575
      Begin VB.TextBox txtTemplate 
         Height          =   285
         Left            =   120
         TabIndex        =   2
         Top             =   240
         Width           =   4335
      End
   End
End
Attribute VB_Name = "frmOptions"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub cmdCancel_Click()
    Unload frmOptions
End Sub

Private Sub cmdOk_Click()
    On Error Resume Next
    Err.Clear
    
    frmMain.Drive1 = txtTemplate.Text
    frmMain.Dir1 = txtTemplate.Text
    If Err.Number Or Trim(txtTemplate.Text) = "" Then
        MsgBox "Sorry, that template path was not accessible!  Please choose another."
        txtTemplate.SetFocus
        Err.Clear
        Exit Sub
    End If
        
    frmMain.Drive1 = txtOutput.Text
    frmMain.Dir1 = txtOutput.Text
    If Err.Number Or Trim(txtOutput.Text) = "" Then
        MsgBox "Sorry, that output path was not accessible!  Please choose another."
        txtOutput.SetFocus
        Err.Clear
        Exit Sub
    End If
        
    NewFileAge = UpDown1
    MinNewFiles = UpDown2
    OutputPath = txtOutput.Text
    TemplatePath = txtTemplate.Text
    If Right(OutputPath, 1) <> "\" Then OutputPath = OutputPath + "\"
    If Right(TemplatePath, 1) <> "\" Then TemplatePath = TemplatePath + "\"
    SaveSettings
    Unload frmOptions
End Sub

Private Sub Form_Load()
    On Error Resume Next
    UpDown1 = 1
    UpDown2 = 1
    UpDown1 = NewFileAge
    UpDown2 = MinNewFiles
    
    txtOutput.Text = OutputPath
    txtTemplate.Text = TemplatePath
End Sub

Private Sub Form_Terminate()
    Unload frmOptions
End Sub

Private Sub UpDown1_Change()
    If UpDown1 = 1 Then
        lblAge.Caption = UpDown1 & " Week"
    Else
        lblAge.Caption = UpDown1 & " Weeks"
    End If
End Sub

Private Sub UpDown2_Change()
    If UpDown2 = 1 Then
        lblRecent.Caption = UpDown2 & " File"
    Else
        lblRecent.Caption = UpDown2 & " Files"
    End If
End Sub


