VERSION 5.00
Begin VB.Form frmEdgeWeight 
   BorderStyle     =   4  'Fixed ToolWindow
   Caption         =   "Get Edge Weight"
   ClientHeight    =   285
   ClientLeft      =   45
   ClientTop       =   285
   ClientWidth     =   1935
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   19
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   129
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Visible         =   0   'False
   Begin VB.TextBox txtWeight 
      Height          =   285
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   1935
   End
End
Attribute VB_Name = "frmEdgeWeight"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Public Function GetEdgeWeight(X As Long, Y As Long) As Long
    Top = Y - Height \ 2
    Left = X - Width \ 2
    Show vbModal
    GetEdgeWeight = Val(txtWeight.Text)
    Unload Me
End Function

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyReturn Then
        Hide
    ElseIf KeyCode = vbKeyEscape Then
        txtWeight.Text = ""
        Hide
    End If
End Sub

