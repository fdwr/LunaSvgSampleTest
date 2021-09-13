VERSION 5.00
Begin VB.Form frmPainter 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Paint"
   ClientHeight    =   4095
   ClientLeft      =   1215
   ClientTop       =   1755
   ClientWidth     =   5055
   Icon            =   "Painter.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   273
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   337
   StartUpPosition =   2  'CenterScreen
   Begin VB.PictureBox picPenColor 
      Height          =   780
      Left            =   120
      ScaleHeight     =   48
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   24
      TabIndex        =   2
      Top             =   3240
      Width           =   420
   End
   Begin VB.PictureBox picPalette 
      Height          =   780
      Left            =   600
      ScaleHeight     =   48
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   288
      TabIndex        =   1
      Top             =   3240
      Width           =   4380
   End
   Begin VB.PictureBox picCanvas 
      AutoRedraw      =   -1  'True
      BackColor       =   &H00000000&
      Height          =   3060
      Left            =   120
      MousePointer    =   2  'Cross
      ScaleHeight     =   200
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   320
      TabIndex        =   0
      Top             =   120
      Width           =   4860
   End
End
Attribute VB_Name = "frmPainter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Dwayne Robinson
'2002-01-28
'Test paint program to attempt PPR compression
'PPR = previous pixel run
Option Explicit

Private Declare Function PtInRect Lib "user32.dll" (lpRect As RECT, ByVal X As Long, ByVal Y As Long) As Long

Private Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

Private Type POINTAPI
    X As Long
    Y As Long
End Type

Dim PenTool As Long
Dim PenColor As Long
Dim PenColorInt As Integer

Dim MouseOver As Long
Const MouseOverCanvas As Long = 1
Const MouseOverPalette As Long = 2
Dim MouseRect As RECT

Const PaletteCellSize As Long = 8
Dim PaletteOrder As Long
Dim PaletteEntries(255) As Long

Private Sub Form_Load()

NewCanvas picCanvas.Height, picCanvas.Width
SetPaletteOrder
SetPenColor &HFFFFFF

End Sub

Private Sub picPalette_MouseDown(Button As Integer, Shift As Integer, Xs As Single, Ys As Single)

MouseOver = MouseOverPalette
With picPalette
    MouseRect.Right = .ScaleWidth
    MouseRect.Bottom = .ScaleHeight
End With
picPalette_MouseMove Button, Shift, Xs, Ys

End Sub

Private Sub picPalette_MouseMove(Button As Integer, Shift As Integer, Xs As Single, Ys As Single)

If MouseOver = MouseOverPalette Then
    Dim X As Long, Y As Long
    X = Int(Xs): Y = Int(Ys)
    If PtInRect(MouseRect, X, Y) Then
        SetPenColor PaletteEntries(((X \ PaletteCellSize) Mod 36) + (Y \ PaletteCellSize) * 36)
        'SetPenColor ((X \ PaletteCellSize) Mod 6) * &H33& _
        '           + (X \ (PaletteCellSize * 6)) * &H3300& _
        '           + (Y \ PaletteCellSize) * &H330000
    End If
End If

End Sub

Private Sub picPalette_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
MouseOver = 0
End Sub

Private Sub picPalette_Paint()

Dim X As Long, Y As Long
Dim Color As Long
Dim Count As Long

Color = 0
Count = 0
For Y = 0 To PaletteCellSize * 6 - 1 Step PaletteCellSize
    For X = 0 To PaletteCellSize * 36 - 1 Step PaletteCellSize
        Color = PaletteEntries(Count)
        picPalette.Line (X, Y)-(X + PaletteCellSize - 1, Y + PaletteCellSize - 1), Color, BF
        If Color = PenColor Then
            picPalette.Line (X, Y)-(X + PaletteCellSize - 1, Y + PaletteCellSize - 1), Color Xor &HFFFFFF, B
        End If
        Count = Count + 1
    Next
Next

End Sub

Private Sub picCanvas_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)

MouseOver = MouseOverCanvas
With picCanvas
    MouseRect.Right = .ScaleWidth
    MouseRect.Bottom = .ScaleHeight
End With
PenDraw Int(X), Int(Y)

End Sub

Private Sub picCanvas_MouseMove(Button As Integer, Shift As Integer, Xs As Single, Ys As Single)
'Why!? did they pass X and Y as singles?
'VB would be an awesome language if they had just
'ridded it of some of the little annoyances

If MouseOver = MouseOverCanvas Then
    Dim X As Long, Y As Long
    X = Int(Xs): Y = Int(Ys)
    If PtInRect(MouseRect, X, Y) Then
        PenDraw X, Y
    End If
End If

End Sub

Private Sub picCanvas_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
MouseOver = 0
End Sub


Public Sub PenDraw(X As Long, Y As Long)

Select Case PenTool
Case 0
    picCanvas.PSet (X, Y), PenColor
    PlotDot X, Y, PenColorInt
    's
'case ...
End Select

End Sub

Public Sub SetPenColor(Color As Long)

If Color <> PenColor Then
    PenColor = Color
    PenColorInt = Cvt24To15(PenColor)
    picPalette_Paint
    picPenColor.BackColor = PenColor
End If

End Sub

Public Sub SetPaletteOrder()
'1   1   2   2   3   3
'2   3   3   1   1   2
'3   2   1   3   2   1
Dim PaletteMask1 As Long, PaletteMask2 As Long, PaletteMask3 As Long
Dim PaletteInc1 As Long, PaletteInc2 As Long, PaletteInc3 As Long
Dim Count As Long
Dim Color As Long

PaletteMask1 = &HFF&
PaletteMask2 = &HFF00&
PaletteMask3 = &HFF0000
PaletteInc1 = &H33&
PaletteInc2 = &H3300&
PaletteInc3 = &H330000

Color = 0
For Count = 0 To 255
    PaletteEntries(Count) = Color
    If (Color And PaletteMask1) >= PaletteMask1 Then
        Color = Color And Not PaletteMask1
        If (Color And PaletteMask2) >= PaletteMask2 Then
            Color = Color And Not PaletteMask2
            If (Color And PaletteMask3) >= PaletteMask3 Then
                Color = Color And Not PaletteMask3
            Else
                Color = Color + PaletteInc3
            End If
        Else
            Color = Color + PaletteInc2
        End If
    Else
        Color = Color + PaletteInc1
    End If
Next

End Sub
