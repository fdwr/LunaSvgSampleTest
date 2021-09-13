VERSION 5.00
Begin VB.Form frmTestVxd 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Test VXD"
   ClientHeight    =   3195
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   4680
   Icon            =   "TestVxd.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3195
   ScaleWidth      =   4680
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdTest 
      Caption         =   "Test VXD"
      Height          =   495
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   1215
   End
End
Attribute VB_Name = "frmTestVxd"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Dim hDevice As Long

Private Sub cmdTest_Click()
    Stop
    hDevice = CreateFile("\\.\VWIN32", 0, 0, 0, 0, _
                          FILE_FLAG_DELETE_ON_CLOSE, 0)
    If hDevice <> -1 Then
        MsgBox hDevice
        CloseHandle hDevice
    End If
End Sub


