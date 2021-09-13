VERSION 5.00
Begin VB.Form frmCircle 
   Caption         =   "Main Form"
   ClientHeight    =   3195
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   4680
   Icon            =   "Circle.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   213
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   312
   StartUpPosition =   3  'Windows Default
   WindowState     =   2  'Maximized
   Begin VB.CommandButton cmdDraw 
      Caption         =   "Draw"
      Height          =   255
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   615
   End
End
Attribute VB_Name = "frmCircle"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

'x^2 + y^2 = 25
Private Declare Function TextOut Lib "gdi32" Alias "TextOutA" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal lpString As String, ByVal nCount As Long) As Long

Private Sub cmdDraw_Click()
    Dim x As Double
    Dim y As Double
    Const S As Double = 200 * 200&
    Dim hdc As Long

    Cls
    hdc = Me.hdc
    ForeColor = &HFF0000
    TextOut hdc, 0, 32, "Blue - X coordinate", 19
    For x = -400 To 400
        y = Sqr(Abs(S - x * x))
        PSet (x + 400, y + 300)
        PSet (x + 400, 300 - y)
    Next

    ForeColor = &HFF
    TextOut hdc, 0, 48, "Red - Y coordinate", 18
    For y = -400 To 400
        x = Sqr(Abs(S - y * y))
        PSet (x + 400, y + 300)
        PSet (400 - x, y + 300)
    Next

    ForeColor = &HFF00&
    TextOut hdc, 0, 64, "Green - Circle function", 23
    Circle (400, 300), 195
End Sub
