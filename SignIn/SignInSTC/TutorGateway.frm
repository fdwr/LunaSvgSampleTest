VERSION 5.00
Begin VB.Form frmTutorGateway 
   BorderStyle     =   0  'None
   Caption         =   "Student Gateway"
   ClientHeight    =   9000
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   12000
   Icon            =   "TutorGateway.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   450
   ScaleMode       =   2  'Point
   ScaleWidth      =   600
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
End
Attribute VB_Name = "frmTutorGateway"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
If (Button And 1) And (Shift And 3) = 3 Then Unload Me
End Sub
