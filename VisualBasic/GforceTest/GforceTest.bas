Attribute VB_Name = "modGforceTest"
Option Explicit

Public Const CBM_INIT = &H4           '  initialize bitmap
Public Const DIB_RGB_COLORS = 0 '  color table in RGBs

Public Type RGBQUAD
    rgbBlue As Byte
    rgbGreen As Byte
    rgbRed As Byte
    rgbReserved As Byte
End Type

Public Type BITMAPINFOHEADER '40 bytes
    Size As Long
    Width As Long
    Height As Long
    Planes As Integer
    BitCount As Integer
    Compression As Long
    SizeImage As Long
    XPelsPerMeter As Long
    YPelsPerMeter As Long
    ClrUsed As Long
    ClrImportant As Long
End Type

Public Type BITMAPINFO '40 bytes+palette size
    Size As Long
    Width As Long
    Height As Long
    Planes As Integer
    BitCount As Integer
    Compression As Long
    SizeImage As Long
    XPelsPerMeter As Long
    YPelsPerMeter As Long
    ClrUsed As Long
    ClrImportant As Long
    Palette(256) As RGBQUAD
End Type

Public BmpHeader As BITMAPINFO
Public BmpSrc(76800) As Byte
Public BmpDst(76800) As Byte

'Public Declare Function CreateDIBitmap Lib "gdi32" (ByVal hdc As Long, lpInfoHeader As BITMAPINFOHEADER, ByVal dwUsage As Long, lpInitBits As Any, lpInitInfo As BITMAPINFO, ByVal wUsage As Long) As Long
Public Declare Function CreateDIBitmap Lib "gdi32" (ByVal hdc As Long, lpInfoHeader As BITMAPINFO, ByVal dwUsage As Long, ByRef lpInitBits As Any, lpInitInfo As BITMAPINFO, ByVal wUsage As Long) As Long
Public Declare Function DeleteObject Lib "gdi32" (ByVal hObject As Long) As Long
Public Declare Function GetDC Lib "user32" (ByVal hwnd As Long) As Long
Public Declare Function BitBlt Lib "gdi32" (ByVal hDestDC As Long, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal dwRop As Long) As Long


Sub Main()
    Dim Count As Long
    'init bitmaps
    InitBitmapHeader 320, 240, 8
    'simple gray palette
    For Count = 0 To 255
        BmpHeader.Palette(Count).rgbBlue = Count
        BmpHeader.Palette(Count).rgbGreen = Count
        BmpHeader.Palette(Count).rgbRed = Count
    Next
    frmGforceTest.Show
End Sub

Sub InitBitmapHeader(Height As Long, Width As Long, Bits As Long)
    If Bits < 1 Then Bits = 1
    BmpHeader.Size = 40
    BmpHeader.Width = Width
    BmpHeader.Height = Height
    BmpHeader.Planes = 1
    BmpHeader.BitCount = Bits
    BmpHeader.Compression = 0
    BmpHeader.SizeImage = Width * Height * 8 \ Bits
    BmpHeader.XPelsPerMeter = 0
    BmpHeader.YPelsPerMeter = 0
    BmpHeader.ClrUsed = 256
    BmpHeader.ClrImportant = 256
End Sub
