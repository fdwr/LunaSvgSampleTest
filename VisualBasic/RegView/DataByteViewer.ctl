VERSION 5.00
Begin VB.UserControl ctlDataByteViewer 
   ClientHeight    =   3600
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   4800
   BeginProperty Font 
      Name            =   "Terminal"
      Size            =   6
      Charset         =   255
      Weight          =   700
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   PaletteMode     =   4  'None
   ScaleHeight     =   240
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   320
End
Attribute VB_Name = "ctlDataByteViewer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Type RECT
    Left       As Long
    Top        As Long
    Right      As Long
    Bottom     As Long
End Type

Private Declare Function TextOut Lib "gdi32" Alias "TextOutA" _
(ByVal hdc As Long, ByVal X As Long, ByVal Y As Long, ByVal _
lpString As String, ByVal nCount As Long) As Long

Private Declare Function FillRect Lib "user32.dll" (ByVal hdc As Long, lpRect As RECT, ByVal hBrush As Long) As Long

Private Declare Function CreateCaret Lib "user32" _
(ByVal hWnd As Long, ByVal hBitmap As Long, ByVal nWidth _
As Long, ByVal nHeight As Long) As Long

Private Declare Function DestroyCaret _
Lib "user32" () As Long

Private Declare Function ShowCaret _
Lib "user32" (ByVal hWnd As Long) As Long

Private Declare Function HideCaret _
Lib "user32" (ByVal hWnd As Long) As Long

Private Declare Function SetCaretPos _
Lib "user32" (ByVal X As Integer, ByVal Y As Integer) As Long

'Declare Function CreateSolidBrush Lib "gdi32.dll" (ByVal crColor As Long) As Long

Const StdWidth = 16 'the common width of any hexeditor
Const Twips = 15
Private CtlWidth As Long, CtlHeight As Long

Private Data() As Byte, DataLength As Long
Private DisplayText As String
Private LineHeight As Integer, LineWidth As Integer
Private TotalViewedChars As Long
Public BasePos As Long 'only public for reading, do not write
Public DisplayMode As Integer
Public CurPos As Long, CurBit As Byte
Public InsertMode As Boolean
Public HasFocus As Boolean

Private Sub UserControl_EnterFocus()
    HasFocus = True
    DataLength = 135
    CreateCaret UserControl.hWnd, 0, 2, LineHeight
    PositionCaret
    ShowCaret UserControl.hWnd
End Sub

Private Sub UserControl_ExitFocus()
    HasFocus = False
    HideCaret UserControl.hWnd
    DestroyCaret
End Sub

Private Sub PositionCaret()
    SetCaretPos (CurPos And StdWidth - 1) * LineWidth, (CurPos \ StdWidth) * LineHeight
End Sub

Private Sub UserControl_Initialize()
    'Call UserControl_Resize
End Sub

Public Sub UpdateDataSource(DataSource() As Byte, NewBasePos As Long, First As Long, Last As Long)
    Dim TempFirst As Long, TempLast As Long, Count As Long
    
    TempFirst = First: TempLast = Last: DataLength = UBound(DataSource)
    If TempLast >= DataLength Then TempLast = DataLength - 1
    If TempLast - TempFirst > TotalViewedChars Then TempLast = TempFirst + TotalViewedChars

    If NewBasePos <> BasePos Then
        For Count = 0 To TempLast
            Data(Count) = DataSource(Count - BasePos)
        Next Count
    End If
End Sub

Private Sub UserControl_KeyDown(KeyCode As Integer, Shift As Integer)
    Dim NewCurPos As Long
    Select Case KeyCode
    Case vbKeyUp: NewCurPos = CurPos - StdWidth
    Case vbKeyDown: NewCurPos = CurPos + StdWidth
    Case vbKeyLeft: NewCurPos = CurPos - 1
    Case vbKeyRight: NewCurPos = CurPos + 1
    Case vbKeyHome: NewCurPos = 0
    Case vbKeyEnd: NewCurPos = DataLength
    End Select
    If NewCurPos > DataLength Then
        NewCurPos = DataLength
    ElseIf NewCurPos < 0 Then
        NewCurPos = 0
    End If
    If NewCurPos <> CurPos Then
        CurPos = NewCurPos
        PositionCaret
    End If
End Sub

Private Sub UserControl_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim NewCurPos As Long
    If Button And 1 Then
        NewCurPos = (X + 2) \ LineWidth
        If NewCurPos >= StdWidth Then NewCurPos = StdWidth - 1
        NewCurPos = NewCurPos + (Y \ LineHeight) * StdWidth
        If NewCurPos > DataLength Then
            NewCurPos = DataLength
        ElseIf NewCurPos < 0 Then
            NewCurPos = 0
        End If
        If NewCurPos <> CurPos Then
            CurPos = NewCurPos
            PositionCaret
        End If
    End If
End Sub

Private Sub UserControl_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Call UserControl_MouseDown(Button, Shift, X, Y)
End Sub

Private Sub UserControl_Paint()
    HideCaret UserControl.hWnd
    'UserControl.PaintPicture
    'UserControl.Height
    RedrawLines BasePos, BasePos + TotalViewedChars
    'drawtext
    ShowCaret UserControl.hWnd
End Sub

Private Sub UserControl_Resize()
    Dim Count As Integer

    LineHeight = UserControl.TextHeight("0")
    LineWidth = UserControl.TextWidth("0")
    CtlHeight = UserControl.Height \ Twips
    CtlWidth = UserControl.Width \ Twips
    TotalViewedChars = (CtlHeight \ LineHeight) * StdWidth

    'DisplayMode = 1
    ReDim Data(TotalViewedChars - 1)
    For Count = 0 To TotalViewedChars - 1
        Data(Count) = Int(Rnd * 256)
    Next Count
    If DisplayMode = 1 Then
        DisplayText = Space(StdWidth * 3)
    Else
        DisplayText = Space(StdWidth)
    End If
End Sub

'thanks to VB stupidly starting string indexes from 1,  !@#$
'lots of ones have to be added here and there, and
'the multiplication result must have 2 subtracted afterwards,
Private Sub RedrawLines(First As Long, Last As Long)
    Dim TempFirst As Long, TempLast As Long
    Dim Count As Integer, SubCount As Integer
    Dim Row As Integer, hdc As Long

    If First <= 0 Then
        TempFirst = 0
    Else
        TempFirst = (First - BasePos) And -16
    End If
    If Last <= DataLength Then
        TempLast = TotalViewedChars
    Else
        TempLast = Last
    End If


'    hBrush = CreateSolidBrush(&H808080) ' create a solid yellow brush
'
    hdc = UserControl.hdc
    'Line (0, 0)-(UserControl.Width, UserControl.Height), &HD0B000 Or Count * 15, BF
    Row = (TempFirst \ StdWidth) * LineHeight
    UserControl.CurrentY = Row
    For Count = TempFirst \ StdWidth To (TempLast - 1) \ StdWidth
        Line (0, Row)-(CtlWidth - 1, Row + LineHeight - 1), &H801000 Or Count * 15, BF
        'FillRect hdc, bgRect, UserControl.FillStyle
        'simply fill the rest with space if there is no more text
        If TempFirst < TempLast Then
            If DisplayMode = 0 Then 'ascii
                'build the row of text
                For SubCount = 1 To StdWidth
                    If TempFirst >= TempLast Then
                        Mid(DisplayText, SubCount) = Space((StdWidth + 1) - SubCount)
                        TempFirst = TempFirst + (StdWidth + 1) - SubCount
                        Exit For
                    End If
                    Mid(DisplayText, SubCount, 1) = Chr(Data(TempFirst))
                    TempFirst = TempFirst + 1
                Next SubCount
            ElseIf DisplayMode = 1 Then 'hex
                'build the row of text
                For SubCount = 1 To StdWidth
                    If TempFirst >= TempLast Then
                        Mid(DisplayText, SubCount) = Space((StdWidth * 3 + 1) - SubCount)
                        TempFirst = TempFirst + (StdWidth + 1) - SubCount
                        Exit For
                    End If
                    Mid(DisplayText, SubCount * 3 - 2, 3) = Right("0" & Hex(Data(TempFirst)) & " ", 3)
                Next SubCount
            End If

            'UserControl.CurrentX = 0
            'UserControl.CurrentY = Row
            TextOut hdc, 0, Row, DisplayText, StdWidth
            'Print DisplayText; 'print wasn't printing control characters!
            Row = Row + LineHeight
        End If
    Next Count

End Sub
