VERSION 5.00
Begin VB.Form frmDeferPc 
   BackColor       =   &H00000000&
   BorderStyle     =   0  'None
   Caption         =   "Form1"
   ClientHeight    =   3195
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   4680
   BeginProperty Font 
      Name            =   "Comic Sans MS"
      Size            =   18
      Charset         =   0
      Weight          =   700
      Underline       =   0   'False
      Italic          =   -1  'True
      Strikethrough   =   0   'False
   EndProperty
   LinkTopic       =   "Form1"
   ScaleHeight     =   3195
   ScaleWidth      =   4680
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Begin VB.Timer Timer1 
      Interval        =   30
      Left            =   720
      Top             =   1080
   End
End
Attribute VB_Name = "frmDeferPc"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Declare Function TextOut Lib "gdi32" Alias "TextOutA" _
(ByVal hdc As Long, ByVal X As Long, ByVal Y As Long, ByVal _
lpString As String, ByVal nCount As Long) As Long

Const Msg As String = "Please Choose A Different Computer :-)"

Public TextColor As Long, LineColor As Long
Public DeferEffect As Long
Public ScreenHeight As Long, ScreenWidth As Long
Public ScreenHalfHeight As Long, ScreenHalfWidth As Long
Public LineHashHeight As Long, LineHashWidth As Long
Public LineHashCount As Long
Const LineHashStep = 25 * 15
Const TotalDeferEffects = 3

Private Sub Form_Click()
    Line (0, 0)-(ScreenWidth, ScreenHeight), 0, BF
    DeferEffect = (DeferEffect + 1) Mod TotalDeferEffects
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyEscape Then Unload Me
End Sub

Private Sub Form_Load()
    ScreenHeight = Screen.Height
    ScreenWidth = Screen.Width
    ScreenHalfHeight = ScreenHeight \ 2
    Move 0, 0, ScreenWidth, ScreenHeight

    LineColor = &H808080
    DeferEffect = 1

    LineHashHeight = ScreenHeight + ScreenWidth
End Sub

Private Sub Form_Paint()
    Dim Count As Long, RowTop As Long, RowBtm As Long, ColLeft As Long, ColRight As Long

    ColLeft = (Screen.Width - TextWidth(Msg)) \ 2 \ Screen.TwipsPerPixelX
    RowTop = (Screen.Height - TextHeight(Msg)) \ 2 \ Screen.TwipsPerPixelY
    ForeColor = TextColor
    TextOut Me.hdc, ColLeft, RowTop, Msg, Len(Msg)
    ForeColor = TextColor Xor &H808080
    TextOut Me.hdc, ColLeft + 2, RowTop + 2, Msg, Len(Msg)

    Select Case DeferEffect
    Case 2
        ColLeft = 0
        ColRight = ScreenWidth
        For Count = LineHashCount To ScreenHeight Step LineHashStep
            RowTop = ScreenHalfHeight + Count
            RowBtm = ScreenHeight + ScreenHalfHeight - Count
            Line (ColLeft, RowTop)-(ColRight, RowBtm), LineColor
        Next
        For Count = LineHashCount To ScreenHeight Step LineHashStep
            RowTop = -ScreenHalfHeight + Count
            RowBtm = ScreenHalfHeight - Count
            Line (ColLeft, RowTop)-(ColRight, RowBtm), LineColor
        Next
    Case 1
        RowTop = 0
        ColLeft = 0
        ColRight = ScreenWidth - 15
        For Count = LineHashCount To ScreenWidth Step LineHashStep
            Line (Count, RowTop)-(ColLeft, ScreenHeight - Count - 15), LineColor
        Next
        RowBtm = ScreenHeight - ScreenWidth
        For Count = LineHashCount To ScreenWidth Step LineHashStep
            Line (Count, RowTop)-(ColRight, Count + RowBtm), LineColor
        Next
        RowBtm = ScreenHeight - 15
        For Count = LineHashCount To ScreenWidth Step LineHashStep
            Line (ColRight, RowTop + Count)-(ScreenWidth - Count - 15, RowBtm), LineColor
        Next
        For Count = LineHashCount To ScreenWidth Step LineHashStep
            Line (ColLeft, RowTop + Count)-(Count, RowBtm), LineColor
        Next
        
    End Select
End Sub

Private Sub Timer1_Timer()
    Call Form_Paint
    TextColor = (TextColor + &H30405) And &HFFFFFF
    LineColor = (LineColor + &H30405) And &HFFFFFF
    LineHashCount = (LineHashCount + 15) Mod LineHashStep
End Sub
