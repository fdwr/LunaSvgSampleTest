VERSION 5.00
Begin VB.UserControl DimmedBg 
   AutoRedraw      =   -1  'True
   BackColor       =   &H80000010&
   CanGetFocus     =   0   'False
   ClientHeight    =   3600
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   4800
   ClipBehavior    =   0  'None
   BeginProperty Font 
      Name            =   "Small Fonts"
      Size            =   6
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   ScaleHeight     =   240
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   320
   Windowless      =   -1  'True
End
Attribute VB_Name = "DimmedBg"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'Private Declare Function ReleaseDC Lib "USER32" (ByVal hWnd As Long, ByVal hdc As Long) As Long
'Private Declare Function GetDC Lib "USER32" (ByVal hWnd As Long) As Long
Private Declare Function BitBlt Lib "gdi32" (ByVal hDestDC As Long, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal dwRop As Long) As Long
Private Declare Function GetPixel Lib "gdi32" (ByVal hDestDC As Long, ByVal X As Long, ByVal Y As Long) As Long
Private Declare Function SetPixel Lib "gdi32" (ByVal hDestDC As Long, ByVal X As Long, ByVal Y As Long, ByVal Clr As Long) As Long
Private Declare Function TextOut Lib "gdi32" Alias "TextOutA" (ByVal hdc As Long, ByVal X As Long, ByVal Y As Long, ByVal lpString As String, ByVal nCount As Long) As Long
Private Declare Function LineTo Lib "gdi32" (ByVal hdc As Long, ByVal X As Long, ByVal Y As Long) As Long
Private Declare Function MoveToEx Lib "gdi32" (ByVal hdc As Long, ByVal X As Long, ByVal Y As Long, lpPoint As POINTAPI) As Long
'Private Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
'Private Declare Function GetWindowLong Lib "user32" Alias "GetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long) As Long
Private Declare Function DrawEdge Lib "user32" (ByVal hdc As Long, qrc As RECT, ByVal edge As Long, ByVal grfFlags As Long) As Long

Private Type POINTAPI
X As Long
Y As Long
End Type

Private Type RECT
Left As Long
Top As Long
Right As Long
Bottom As Long
End Type

'Const GWL_STYLE = (-16)
'Const WS_BORDER = &H800000
'Const WS_DLGFRAME = &H400000

Const BDR_RAISEDOUTER = 1
Const BDR_SUNKENOUTER = 2
Const BDR_RAISEDINNER = 4
Const BDR_SUNKENINNER = 8
    
Public Enum EDEDBorderParts
Bf_left = 1
Bf_Top = 2
Bf_right = 4
Bf_bottom = 8
BF_TOPLEFT = Bf_left Or Bf_Top
Bf_BOTTOMRIGHT = Bf_right Or Bf_bottom
BF_RECT = Bf_left Or Bf_Top Or Bf_right Or Bf_bottom
BF_MIDDLE = &H800
BF_SOFT = &H1000
BF_ADJUST = &H2000
BF_FLAT = &H4000
BF_MONO = &H8000
BF_ALL = BF_RECT Or BF_MIDDLE Or BF_SOFT Or BF_ADJUST Or BF_FLAT Or BF_MONO
End Enum

Const NOTSRCCOPY = &H330008 ' dest = (NOT source)
Const NOTSRCERASE = &H1100A6 ' dest = (NOT src) AND (NOT dest)
Const BLACKNESS = &H42 ' dest = BLACK
Const DSTINVERT = &H550009 ' dest = (NOT dest)
Const MERGECOPY = &HC000CA ' dest = (source AND pattern)
Const MERGEPAINT = &HBB0226 ' dest = (NOT source) OR dest
Const PATCOPY = &HF00021 ' dest = pattern
Const PATINVERT = &H5A0049 ' dest = pattern XOR dest
Const PATPAINT = &HFB0A09 ' dest = DPSnoo
Const SRCAND = &H8800C6 ' dest = source AND dest
Const SRCCOPY = &HCC0020 ' dest = source
Const SRCERASE = &H440328 ' dest = source AND (NOT dest )
Const SRCINVERT = &H660046 ' dest = source XOR dest
Const SRCPAINT = &HEE0086 ' dest = source OR dest
Const WHITENESS = &HFF0062  ' dest = WHITE

Public Sub DimThis(SrcDc As Long, Myself As Object, Clr As Long)
    Dim DestHdc As Long
    Dim DestTop As Long, DestLeft As Long
    Dim DestHeight As Long, DestWidth As Long
    Dim UselessPt As POINTAPI
    Dim WndRect As RECT

    DestWidth = Width
    DestHeight = Height
    DestHdc = UserControl.hdc
    Call BitBlt(DestHdc, 0, 0, DestWidth, DestHeight, SrcDc, Myself.Left, Myself.Top, SRCCOPY)
    ForeColor = Clr
    'For DestLeft = -DestWidth To DestWidth Step 2
    '    Line (DestLeft, 0)-(DestLeft + DestHeight, DestHeight)
    'Next
    'Exit Sub
    For DestLeft = -DestWidth To DestWidth Step 2
        MoveToEx DestHdc, DestLeft, 0, UselessPt
        LineTo DestHdc, DestLeft + DestHeight, DestHeight
    Next

    WndRect.Top = 0: WndRect.Left = 0
    WndRect.Right = UserControl.ScaleWidth
    WndRect.Bottom = UserControl.ScaleHeight
    DrawEdge DestHdc, WndRect, BDR_SUNKENINNER Or BDR_SUNKENOUTER, BF_RECT
End Sub

Public Sub PrintMerge(SrcDc As Long, Myself As Object, Text As String)
    Dim SrcTop As Long, SrcLeft As Long
    Dim DestTop As Long, DestLeft As Long
    Dim DestWidth As Long, DestHeight As Long, DestHdc As Long

    BackColor = 0
    ForeColor = &H101010
    DestHdc = UserControl.hdc
    TextOut DestHdc, 0, 0, Text, Len(Text)
    DestWidth = ScaleWidth - 1
    SrcTop = Myself.Top
    SrcLeft = Myself.Left
    For DestTop = 0 To ScaleHeight - 1
        For DestLeft = 0 To DestWidth
            SetPixel DestHdc, DestLeft, DestTop, GetPixel(SrcDc, SrcLeft + DestLeft, SrcTop + DestTop) + GetPixel(DestHdc, DestLeft, DestTop)
        Next
    Next
End Sub

Private Sub UserControl_Initialize()
    '
End Sub
