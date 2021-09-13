VERSION 5.00
Begin VB.Form frmDebug 
   BorderStyle     =   0  'None
   ClientHeight    =   255
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   5655
   LinkTopic       =   "Form1"
   ScaleHeight     =   255
   ScaleWidth      =   5655
   ShowInTaskbar   =   0   'False
   Begin VB.CommandButton cmdView 
      Caption         =   "view"
      Height          =   255
      Left            =   5160
      TabIndex        =   1
      Top             =   0
      Width           =   495
   End
   Begin VB.Label lblDebug 
      Alignment       =   2  'Center
      BackStyle       =   0  'Transparent
      BorderStyle     =   1  'Fixed Single
      Height          =   255
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   5655
   End
End
Attribute VB_Name = "frmDebug"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Public GrabRow As Integer, GrabCol As Integer, GrabLock As Boolean
Public ScreenRight As Integer, ScreenBottom As Integer
Public DebugCounter As Integer

Private Sub cmdView_Click()
    Dim NewHeight As Integer
    If Height > 300 Then NewHeight = 255 Else NewHeight = 4000
    Height = NewHeight
    lblDebug.Height = NewHeight

    Call lblDebug_MouseDown(0, 0, 0, 0)
    Call lblDebug_MouseMove(0, 0, 0, 0)
    GrabLock = False
End Sub

Private Sub lblDebug_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    GrabRow = Y
    GrabCol = X
    GrabLock = True
    ScreenRight = Screen.Width - Width
    ScreenBottom = Screen.Height - Height
End Sub

Private Sub lblDebug_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim Row, Col
    If GrabLock Then
        Col = Left - GrabCol + X
        If Col < 0 Then
            Col = 0
        ElseIf Col > ScreenRight Then
            Col = ScreenRight
        End If
        Row = Top - GrabRow + Y
        If Row < 0 Then
            Row = 0
        ElseIf Row > ScreenBottom Then
            Row = ScreenBottom
        End If
        GrabLock = False
        Move Col, Row
        GrabLock = True
    End If
End Sub

Private Sub lblDebug_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    GrabLock = False
End Sub

'Private Sub Form_Load()
    'Dim FormHeight As Integer, FormWidth As Integer
    'FormHeight = Height
    'FormWidth = frmDebug.Width
    'Move Screen.Width - frmDebug.Width,Screen.Height - FormHeight
'End Sub

Public Sub SetMessage(Text As String, Source As String)
    DebugCounter = DebugCounter + 1
    lblDebug.Caption = Left(Text & " <" & DebugCounter & "> " & Source & vbCr & lblDebug.Caption, 1200)
End Sub

Public Sub Delay()
    Dim DelayCount As Long
    For DelayCount = 0 To 8000000: Next DelayCount
End Sub
