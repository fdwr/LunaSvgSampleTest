VERSION 5.00
Begin VB.UserControl GforceImage 
   BackColor       =   &H80000005&
   CanGetFocus     =   0   'False
   ClientHeight    =   3600
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   4800
   ScaleHeight     =   240
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   320
End
Attribute VB_Name = "GforceImage"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit


Dim Bmi2 As BITMAPINFO
Dim BmpHnd As Long

Public Sub SetImage(ByRef Bmi As Object, Pixels() As Byte)
    If BmpHnd Then DeleteObject BmpHnd
    BmpHnd = CreateDIBitmap(GetDC(Me.hwnd), Bmi, CBM_INIT, Pixels(0), Bmi, DIB_RGB_COLORS)
End Sub

Private Sub UserControl_Paint()
    If BmpHnd Then

    '    BitBlt
    
    End If
End Sub

Private Sub UserControl_Terminate()
    If BmpHnd Then DeleteObject BmpHnd
End Sub
