VERSION 5.00
Begin VB.Form frmSetTiming 
   Caption         =   "Set Metronome"
   ClientHeight    =   1740
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   2520
   Icon            =   "SetTiming.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   1740
   ScaleWidth      =   2520
   StartUpPosition =   3  'Windows Default
   Begin VB.TextBox txtInterval 
      Height          =   285
      Left            =   1320
      TabIndex        =   6
      Text            =   "2000"
      Top             =   840
      Width           =   1095
   End
   Begin VB.Timer tmrAnimate 
      Enabled         =   0   'False
      Interval        =   2000
      Left            =   0
      Top             =   0
   End
   Begin VB.CommandButton cmdStop 
      Cancel          =   -1  'True
      Caption         =   "Stop"
      Height          =   375
      Left            =   1320
      TabIndex        =   5
      Top             =   1320
      Width           =   1095
   End
   Begin VB.CommandButton cmdStart 
      Caption         =   "Start"
      Default         =   -1  'True
      Height          =   375
      Left            =   120
      TabIndex        =   4
      Top             =   1320
      Width           =   1095
   End
   Begin VB.TextBox txtSets 
      Height          =   285
      Left            =   1320
      TabIndex        =   1
      Text            =   "1000"
      Top             =   480
      Width           =   1095
   End
   Begin VB.TextBox txtTotal 
      Height          =   285
      Left            =   1320
      TabIndex        =   0
      Text            =   "0"
      Top             =   120
      Width           =   1095
   End
   Begin VB.Label Label3 
      Alignment       =   1  'Right Justify
      Caption         =   "Interval (ms):"
      Height          =   255
      Left            =   120
      TabIndex        =   7
      Top             =   840
      Width           =   1095
   End
   Begin VB.Label Label2 
      Alignment       =   1  'Right Justify
      Caption         =   "Sets:"
      Height          =   255
      Left            =   120
      TabIndex        =   3
      Top             =   480
      Width           =   1095
   End
   Begin VB.Label Label1 
      Alignment       =   1  'Right Justify
      Caption         =   "Total:"
      Height          =   255
      Left            =   120
      TabIndex        =   2
      Top             =   120
      Width           =   1095
   End
End
Attribute VB_Name = "frmSetTiming"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

'Private Declare Function PlaySound Lib "winmm.dll" Alias "PlaySoundA" (ByVal lpszName As String, ByVal hModule As Long, ByVal dwFlags As Long) As Long
Private Declare Function PlaySound Lib "winmm.dll" Alias "PlaySoundA" (ByVal dataptr As Any, ByVal hModule As Long, ByVal dwFlags As Long) As Long
Private Const SND_ASYNC = &H1         '  play asynchronously
Private Const SND_FILENAME = &H20000     '  name is a file name
Private Const SND_MEMORY = &H4         '  lpszSoundName points to a memory file

Dim TotalDone As Long
Dim SetsLeft As Long

Dim WaveBytes As String

Private Sub cmdStart_Click()
    TotalDone = Val(txtTotal.Text)
    SetsLeft = Val(txtSets.Text)
    tmrAnimate.Interval = Val(txtInterval.Text)
    tmrAnimate_Timer
    tmrAnimate.Enabled = True
End Sub

Private Sub cmdStop_Click()
    tmrAnimate.Enabled = False
End Sub

Private Sub Form_Load()
    'load metronome sound effect into memory
    Open App.Path & "\SetBeep.wav" For Binary As 1
    WaveBytes = String(LOF(1), 0)
    Get #1, , WaveBytes
    Close 1
End Sub

Private Sub tmrAnimate_Timer()
    'count one more set and play sound
    If SetsLeft > 0 Then
        TotalDone = TotalDone + 1
        SetsLeft = SetsLeft - 1
        PlaySound WaveBytes, 0, SND_ASYNC Or SND_FILENAME Or SND_MEMORY
        txtTotal.Text = TotalDone
        txtSets.Text = SetsLeft
    End If
    If SetsLeft <= 0 Then tmrAnimate.Enabled = False
End Sub
