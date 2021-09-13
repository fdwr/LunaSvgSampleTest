VERSION 5.00
Begin VB.Form frmGetInput 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Get Input"
   ClientHeight    =   1695
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   3240
   Icon            =   "GetInput.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   1695
   ScaleWidth      =   3240
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdCancel 
      Cancel          =   -1  'True
      Caption         =   "Cancel"
      Height          =   375
      Left            =   1680
      TabIndex        =   3
      Top             =   1200
      Width           =   1455
   End
   Begin VB.CommandButton cmdOk 
      Caption         =   "Ok"
      Default         =   -1  'True
      Height          =   375
      Left            =   120
      TabIndex        =   2
      Top             =   1200
      Width           =   1455
   End
   Begin VB.TextBox txtInput 
      Height          =   285
      Left            =   120
      TabIndex        =   1
      Top             =   720
      Width           =   3015
   End
   Begin VB.Label lblMsg 
      Height          =   495
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   3015
   End
End
Attribute VB_Name = "frmGetInput"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub cmdCancel_Click()
    txtInput.Text = ""
    Hide
End Sub

Private Sub cmdOk_Click()
    If Len(txtInput.Text) > 0 Then
        Hide
    Else
        txtInput.SetFocus
    End If
End Sub

Public Function GetInput(Title As String, Msg As String, Owner As Form) As Long
    Caption = Title
    lblMsg.Caption = Msg
    Show vbModal, Owner
    If Len(txtInput.Text) = 0 Then
        GetInput = -1
    Else
        GetInput = Val(txtInput.Text)
        Unload Me
    End If
End Function

Private Sub Form_Unload(Cancel As Integer)
    cmdCancel_Click
End Sub

'Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
'    If KeyCode = vbKeyReturn Then
'        Hide
'    ElseIf KeyCode = vbKeyEscape Then
'        txtWeight.Text = ""
'        Hide
'    End If
'End Sub

