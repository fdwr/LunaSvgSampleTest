VERSION 5.00
Begin VB.Form frmLock 
   BackColor       =   &H00000000&
   BorderStyle     =   0  'None
   Caption         =   "PC Lock"
   ClientHeight    =   2745
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   2985
   ControlBox      =   0   'False
   BeginProperty Font 
      Name            =   "Arial"
      Size            =   27.75
      Charset         =   0
      Weight          =   700
      Underline       =   0   'False
      Italic          =   -1  'True
      Strikethrough   =   0   'False
   EndProperty
   ForeColor       =   &H00AFFF80&
   Icon            =   "Lock.frx":0000
   LinkTopic       =   "Form1"
   MinButton       =   0   'False
   Moveable        =   0   'False
   ScaleHeight     =   183
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   199
   StartUpPosition =   3  'Windows Default
   Begin VB.Timer tmrAnimate 
      Interval        =   50
      Left            =   120
      Top             =   120
   End
End
Attribute VB_Name = "frmLock"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Const MaxParticles = 213

Const TextMsg As String = "Please choose a different computer (Dw)"
Const EndPassword As String = "end"
Const MinPassword As String = "min"
Const MaxPassLen As Long = 20

Dim ScreenHeight As Long, ScreenWidth As Long
Dim ScreenHalfHeight As Long, ScreenHalfWidth As Long
Dim ParticlesX(MaxParticles - 1) As Long
Dim ParticlesY(MaxParticles - 1) As Long
Dim ParticlesAngleZ(MaxParticles - 1) As Long
Dim ParticlesAngleY(MaxParticles - 1) As Long
Dim ParticlesDistance(MaxParticles - 1) As Long
Dim ParticlesBg(MaxParticles - 1) As Long
Dim ParticlesClrIdx(MaxParticles - 1) As Long
Dim ParticleClrTbl(128) As Long
Dim AnimateCenterX As Long
Dim AnimateCenterY As Long
Dim TextTop As Long
Dim TextLeft As Long
Dim Die As Boolean
Dim Typed As String

Private Declare Function SetPixelV Lib "gdi32" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal crColor As Long) As Long
'Private Declare Function SetPixel Lib "gdi32" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal crColor As Long) As Long
Private Declare Function GetPixel Lib "gdi32" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long) As Long
Private Declare Function TextOut Lib "gdi32" Alias "TextOutA" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal lpString As String, ByVal nCount As Long) As Long
Private Declare Function ShowCursor Lib "user32" (ByVal bShow As Long) As Long
Private Declare Function GetActiveWindow Lib "user32" () As Long
Private Declare Function LockSetForegroundWindow Lib "user32" (uLockCode As Long) As Long
Private Declare Function ShowWindow Lib "user32" (ByVal hwnd As Long, ByVal nCmdShow As Long) As Long
Private Declare Function GetWindowLong Lib "user32.dll" Alias "GetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long) As Long
Private Declare Function SetWindowLong Lib "user32.dll" Alias "SetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
Private Declare Function SetFocusAPI Lib "user32.dll" Alias "SetFocus" (ByVal hwnd As Long) As Long
Private Declare Function SetForegroundWindow Lib "user32.dll" (ByVal hwnd As Long) As Long
Private Declare Function SetCursorPos Lib "user32" (ByVal x As Long, ByVal y As Long) As Long
Private Declare Function SystemParametersInfo Lib "user32" Alias "SystemParametersInfoA" (ByVal uAction As Long, ByVal uParam As Long, ByVal lpvParam As Long, ByVal fuWinIni As Long) As Long
Private Declare Function SetWindowPos Lib "user32" (ByVal hwnd As Long, _
ByVal hWndInsertAfter As Long, ByVal x As Long, ByVal y As Long, ByVal cx _
As Long, ByVal cy As Long, ByVal wFlags As Long) As Long


Const GWL_STYLE = -16
Const WS_EX_TOPMOST = &H8
Const SW_SHOWNORMAL = 1
Const SW_SHOWMAXIMIZED = 3
Const SPI_SETSCREENSAVEACTIVE = 17
Const SPIF_UPDATEINIFILE = &H1
Const SPIF_SENDWININICHANGE = &H2
Const HWND_BOTTOM = 1
Const HWND_NOTOPMOST = -2
Const HWND_TOP = 0
Const HWND_TOPMOST = -1
Const SWP_FRAMECHANGED = &H20
Const SWP_DRAWFRAME = SWP_FRAMECHANGED
Const SWP_HIDEWINDOW = &H80
Const SWP_NOACTIVATE = &H10
Const SWP_NOMOVE = &H2
Const SWP_NOCOPYBITS = &H100
Const SWP_NOOWNERZORDER = &H200
Const SWP_NOREDRAW = &H8
Const SWP_NOREPOSITION = SWP_NOOWNERZORDER
Const SWP_NOSIZE = &H1
Const SWP_NOZORDER = &H4
Const SWP_SHOWWINDOW = &H40
Const SPI_SCREENSAVERRUNNING = 97
Const LSFW_LOCK = 1
Const LSFW_UNLOCK = 2

Private Sub Form_KeyPress(KeyAscii As Integer)

Typed = Right$(Typed & Chr$(KeyAscii), MaxPassLen)
If InStr(Typed, EndPassword) Then
    Typed = ""
    Die = True
    Unload Me
ElseIf InStr(Typed, MinPassword) Then
    Typed = ""
    Me.WindowState = vbMinimized
End If

End Sub

Private Sub Form_Load()
ScreenHeight = Screen.Height \ 15
ScreenWidth = Screen.Width \ 15
ScreenHalfHeight = ScreenHeight \ 2
ScreenHalfWidth = ScreenWidth \ 2

SetWindowLong hwnd, GWL_STYLE, GetWindowLong(hwnd, GWL_STYLE) Or WS_EX_TOPMOST

Top = 0
Left = 0
Height = ScreenHeight * 15 'idiotic twips!
Width = ScreenWidth * 15

TextTop = (ScreenHeight - TextHeight(TextMsg)) \ 2 '30
TextLeft = (ScreenWidth - TextWidth(TextMsg)) \ 2 '30

AnimateCenterY = ScreenHalfHeight
AnimateCenterX = ScreenHalfWidth

InitParticles

Show
ShowCursor False
SetCursorPos AnimateCenterX, AnimateCenterY
LockSetForegroundWindow LSFW_LOCK
ToggleScreenSaverActive True
DisableCtrlAltDel True

End Sub

' This does not work!?
'Private Sub Form_LostFocus()
'SetFocus
'End Sub

Private Sub InitParticles()
Dim Particle As Long, Count As Long, Value As Long

For Particle = 0 To MaxParticles - 1
    ParticlesX(Particle) = -1
    ParticlesY(Particle) = -1
    ParticlesAngleY(Particle) = Int(Rnd * 256)
    ParticlesAngleZ(Particle) = Int(Rnd * 256)
    ParticlesDistance(Particle) = Int(Rnd * 151) + 50
    ParticlesClrIdx(Particle) = Int(Rnd * 32)
Next

For Count = 0 To UBound(ParticleClrTbl) - 1
    Value = Count + &H80
    Value = Value Or ((Count + 43) And 127) * 256 + &H8000&
    Value = Value Or ((Count + 85) And 127) * 65536 + &H800000
    ParticleClrTbl(Count) = Value
Next

End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, x As Single, y As Single)
AnimateCenterX = x
AnimateCenterY = y
End Sub

Private Sub Form_Paint()
Dim Count As Long, Clr As Long, Acm As Long

Acm = 0
Clr = 0
For Count = 0 To ScreenHalfHeight - 61
    Line (0, Count)-(ScreenWidth - 1, Count), Clr
    Acm = Acm + &H501050 '&H204850
    Clr = Clr + (Acm And &H808080) \ 64
    Acm = Acm And &H3F3F3F
Next
For Count = ScreenHalfHeight - 60 To ScreenHalfHeight - 1
    Line (0, Count)-(ScreenWidth - 1, Count), Clr
    Acm = Acm + &H204080
    Clr = Clr + (Acm And &H808080) \ 64
    Acm = Acm And &H3F3F3F
Next
Acm = 0
Clr = 0
For Count = ScreenHeight - 1 To ScreenHalfHeight + 60 Step -1
    Line (0, Count)-(ScreenWidth - 1, Count), Clr
    Acm = Acm + &H501050  '&H501030 '&H204850
    Clr = Clr + (Acm And &H808080) \ 64
    Acm = Acm And &H3F3F3F
Next
For Count = ScreenHalfHeight + 59 To ScreenHalfHeight Step -1
    Line (0, Count)-(ScreenWidth - 1, Count), Clr
    Acm = Acm + &H204080
    Clr = Clr + (Acm And &H808080) \ 64
    Acm = Acm And &H3F3F3F
Next

TextOut Me.hdc, TextLeft, TextTop, TextMsg, Len(TextMsg)
End Sub

Private Sub Form_Resize()
    If Me.WindowState = vbMinimized Then
        tmrAnimate.Enabled = False
    Else
        tmrAnimate.Enabled = True
        Me.WindowState = vbMaximized
    End If
End Sub

Private Sub Form_Unload(Cancel As Integer)
If Die Then
    LockSetForegroundWindow LSFW_UNLOCK
    ShowCursor True
    DisableCtrlAltDel False
    ToggleScreenSaverActive False
Else
    Cancel = True
End If
End Sub

Private Sub tmrAnimate_Timer()
Dim FormHdc As Long, Particle As Long
Dim x As Long, y As Long, Angle As Double, Distance As Long

FormHdc = Me.hdc
For Particle = 0 To MaxParticles - 1
    ' erase previous pixel
    SetPixelV FormHdc, ParticlesX(Particle), ParticlesY(Particle), ParticlesBg(Particle)
Next
For Particle = 0 To MaxParticles - 1
    Angle = ParticlesAngleY(Particle) / 32
    Distance = ParticlesDistance(Particle) * Sin(ParticlesAngleZ(Particle) / 32)
    x = Cos(Angle) * Distance + AnimateCenterX
    y = Sin(Angle) * Distance + AnimateCenterY
    ' get current pixel
    ParticlesBg(Particle) = GetPixel(FormHdc, x, y)

    ' advance movement
    ParticlesX(Particle) = x
    ParticlesY(Particle) = y
    ParticlesAngleY(Particle) = (ParticlesAngleY(Particle) + 1) And 511
    ParticlesAngleZ(Particle) = (ParticlesAngleZ(Particle) + 3) And 511
    ParticlesClrIdx(Particle) = (ParticlesClrIdx(Particle) + 3) And 127
Next
For Particle = 0 To MaxParticles - 1
    SetPixelV FormHdc, ParticlesX(Particle), ParticlesY(Particle), ParticleClrTbl(ParticlesClrIdx(Particle))
Next

If GetActiveWindow() <> Me.hwnd Then
    SetWindowPos Me.hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE
    ShowWindow hwnd, SW_SHOWNORMAL 'SW_SHOWMAXIMIZED
    SetFocusAPI hwnd 'does not work in Win2k!?
    SetForegroundWindow hwnd
    DoEvents
End If

End Sub

Public Sub ToggleScreenSaverActive(Active As Boolean)
    SystemParametersInfo SPI_SETSCREENSAVEACTIVE, IIf(Active, 1, 0), 0, 0
End Sub

Private Sub DisableCtrlAltDel(Disable As Boolean)
   SystemParametersInfo SPI_SCREENSAVERRUNNING, Disable, ByVal 0&, 0
End Sub

'Public Declare Function SendMessage Lib "user32" _
'Alias "SendMessageA" (ByVal hWnd As Long, ByVal wMsg _
'As Long, ByVal wParam As Long, ByVal lParam As Long) _
'As Long
'
'Global Const WM_SYSCOMMAND = &H112
'Global Const SC_SCREENSAVE = &HF140&
'Use this code to activate the screensaver (with the main form called frmMain) ...
'
'SendMessage frmMain.hWnd, WM_SYSCOMMAND, SC_SCREENSAVE, 0&
