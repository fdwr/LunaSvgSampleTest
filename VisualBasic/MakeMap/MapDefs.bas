Attribute VB_Name = "modMapDefs"
Option Explicit

Public Declare Function TextOut Lib "gdi32" Alias "TextOutA" _
(ByVal hdc As Long, ByVal X As Long, ByVal Y As Long, ByVal _
lpString As String, ByVal nCount As Long) As Long

Public Declare Sub CopyMemory Lib "Kernel32" Alias "RtlMoveMemory" _
  (xdest As Any, xsource As Any, ByVal xsize As Long)

Public Declare Function GetUpdateRect Lib "user32" (ByVal hwnd As Long, lpRect As RECT, ByVal bErase As Long) As Long

Public Declare Function SetTextColor Lib "gdi32" (ByVal hdc As Long, ByVal crColor As Long) As Long

Public Type RECT
Left As Long
Top As Long
Right As Long
Bottom As Long
End Type

Public Enum FieldAttributes
FaProtected = 4
FaUnprotected = 0
FaSkip = 8
FaStop = 0
FaNumeric = 8
FaAlphanumeric = 0
FaNormal = 0
FaBright = 16
FaNoDisplay = 48
FaCursor = 64
FaModified = 128
End Enum

Public Type FieldInfo
Top As Integer
Left As Integer
Length As Integer
Map As Integer
Attributes As Byte
Color As Byte
Kind As Byte
Redraw As Boolean
Selected As Boolean
Changed As Boolean
Label As String
Name As String
Text As String
End Type

Public Const FkField = 0
Public Const FkMap = 1
Public Const FkMapset = 2

Public BasicColors(7) As Long, BasicColorNames(7)

Public Sub FindComboEntry(cboSearch As ComboBox, KeyAscii As Integer)
    Dim Count As Long, Text As String, TextLen As Long

    'if keypress was letter/number, look through list for match
    'ignore if control key
    If KeyAscii >= 32 Then
        cboSearch.SelText = Chr(KeyAscii)
        Text = LCase(cboSearch.Text)
        TextLen = Len(Text)
        For Count = 0 To cboSearch.ListCount - 1
            If LCase(Left(cboSearch.List(Count), TextLen)) = Text Then
                cboSearch.ListIndex = Count
                cboSearch.SelStart = TextLen
                cboSearch.SelLength = 10000
            End If
        Next
        KeyAscii = 0
    End If
End Sub

Public Sub main()
    'This is dumb below, but VB got rid of the READ/DATA statements??
    BasicColors(0) = &HFF0000: BasicColorNames(0) = "(default)"
    BasicColors(1) = &HFF0000: BasicColorNames(1) = "BLUE"
    BasicColors(2) = &HFF&:    BasicColorNames(2) = "RED"
    BasicColors(3) = &HFF00FF: BasicColorNames(3) = "PINK"
    BasicColors(4) = &HFF00&:  BasicColorNames(4) = "GREEN"
    BasicColors(5) = &HFFFF00: BasicColorNames(5) = "TURQUOISE"
    BasicColors(6) = &HFFFF&:  BasicColorNames(6) = "YELLOW"
    BasicColors(7) = &HFFFFFF: BasicColorNames(7) = "WHITE"
    frmMapSet.Show
End Sub
