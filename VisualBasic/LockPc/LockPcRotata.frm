VERSION 5.00
Begin VB.Form frmRotate 
   BackColor       =   &H00000000&
   BorderStyle     =   0  'None
   Caption         =   "Form1"
   ClientHeight    =   9000
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   12000
   DrawWidth       =   2
   FontTransparent =   0   'False
   ForeColor       =   &H00FFFFFF&
   LinkTopic       =   "Form1"
   ScaleHeight     =   600
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   800
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Begin VB.Timer tmrAnimate 
      Interval        =   30
      Left            =   120
      Top             =   120
   End
End
Attribute VB_Name = "frmRotate"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Declare Function SetPixel Lib "GDI32" (ByVal hDestDC As Long, ByVal x As Long, ByVal y As Long, ByVal Clr As Long) As Long
Private Declare Sub GetCursorPos Lib "User32" (lpPoint As POINTAPI)

Private Type RotationPoint
ZDegree As Long
ZInc    As Long
XDegree As Long
XInc    As Long
Length  As Long
x       As Long
y       As Long
Color   As Long
End Type

Private Type POINTAPI ' This holds the logical cursor information
   x As Long
   y As Long
End Type

Dim FieldCenterY As Long, FieldCenterX As Long
Dim MousePos As POINTAPI

Const MaxPoints = 200
Dim Points(MaxPoints - 1) As RotationPoint
Dim SineTable(16383) As Double

Private Sub Form_Click()
    Unload Me
End Sub

Private Sub Form_Load()
    Dim Count As Long

    For Count = 0 To MaxPoints - 1
        With Points(Count)
        .ZDegree = Int(Rnd * 16384)
        .XDegree = Int(Rnd * 16384)
        '.ZInc = Int(Rnd * 64) + 64
        '.XInc = Int(Rnd * 256) + 256
        .ZInc = Int(Rnd * 64) + 64
        .XInc = Int(Rnd * 64) + 64
        .Length = Int(Rnd * 300) + 16
        .Color = Int(Rnd * 16777216)
        End With
    Next
    
    FieldCenterX = Me.ScaleWidth \ 2
    FieldCenterY = Me.ScaleHeight \ 2
    
    For Count = 0 To 16383
        SineTable(Count) = Sin(Count / 2607.5967901604)
    Next
    
    GetCursorPos MousePos
End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, x As Single, y As Single)
    If x < MousePos.x - 5 Or x > MousePos.x + 5 Or y < MousePos.y - 3 Or y > MousePos.y + 3 Then
        MsgBox "Please choose a different computer. This one is being used :-)", vbInformation, "Just letting you know..."
        GetCursorPos MousePos
    Else
        MousePos.x = x: MousePos.y = y
    End If
End Sub

Private Sub tmrAnimate_Timer()
    Dim Count As Long
    Dim Length As Long
    Dim x As Long, y As Long
    Dim FrmHdc As Long

    FrmHdc = Me.hDC

    For Count = 0 To MaxPoints - 1
        With Points(Count)
        Length = .Length * SineTable(.XDegree)
        x = SineTable(.ZDegree) * Length + FieldCenterX
        y = SineTable((.ZDegree + 4096) And 16383) * Length + FieldCenterY
        .ZDegree = (.ZDegree + .ZInc) And 16383
        .XDegree = (.XDegree + .XInc) And 16383
        'PSet (.X, .Y), 0
        'PSet (X, Y), .Color
        SetPixel FrmHdc, .x, .y, 0
        SetPixel FrmHdc, x, y, .Color
        'Line (FieldCenterX, FieldCenterY)-(.X, .Y), 0
        'Line (FieldCenterX, FieldCenterY)-(X, Y), .Color
        .x = x
        .y = y
        End With
    Next
End Sub
