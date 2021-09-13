VERSION 5.00
Begin VB.Form frmFullScreen 
   BackColor       =   &H00000000&
   BorderStyle     =   0  'None
   Caption         =   "Full screen preview"
   ClientHeight    =   8595
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   11880
   ControlBox      =   0   'False
   ForeColor       =   &H00FFFFFF&
   Icon            =   "FullScreen.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   MouseIcon       =   "FullScreen.frx":000C
   MousePointer    =   99  'Custom
   ScaleHeight     =   573
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   792
   ShowInTaskbar   =   0   'False
   WindowState     =   2  'Maximized
   Begin VB.Timer tmrDuration 
      Enabled         =   0   'False
      Left            =   0
      Top             =   0
   End
End
Attribute VB_Name = "frmFullScreen"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Dim ScreenHeight As Long, ScreenWidth As Long
Const NoPicMsg As String = "No picture loaded"

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
    Select Case KeyCode
    Case vbKeyDown: NextPic 1
    Case vbKeyUp: NextPic -1
    Case vbKeySpace:
        If tmrDuration.Enabled Then
            tmrDuration.Enabled = False
        Else
            NextPic 1
            StartSlideShow
        End If
    Case vbKeyEscape, vbKeyReturn: Unload Me
    Case vbKeyZ
        'the timer must be turned off, then on again for the
        'interval change to take effect
        tmrDuration.Enabled = False
        tmrDuration.Interval = MinPicDuration
        tmrDuration.Enabled = True
    End Select
End Sub

Private Sub Form_Load()
    ScreenHeight = Screen.Height \ Screen.TwipsPerPixelY
    ScreenWidth = Screen.Width \ Screen.TwipsPerPixelX
    tmrDuration.Interval = PicDuration
End Sub

Private Sub Form_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If Button And 1 Then
        If Shift And 3 Then
            NextPic -1
        Else
            NextPic 1
        End If
    ElseIf Button And 2 Then
        Unload Me
    ElseIf Button And 4 Then 'middle button
        NextPic -1
    End If
End Sub

Private Sub Form_Paint()
    Dim TopRow As Long, LeftCol As Long
    Dim TempHeight As Long, TempWidth As Long

    If PicObject Is Nothing Then DisplayTextMsg NoPicMsg: Exit Sub

    If ScalePic Then
        If KeepProportional Then
            TempHeight = ScreenHeight 'for now
            TempWidth = PicWidth * ScreenHeight \ PicHeight
            TopRow = (ScreenHeight - TempHeight) \ 2
            LeftCol = (ScreenWidth - TempWidth) \ 2
            PaintPicture PicObject, LeftCol, TopRow, TempWidth, TempHeight
        Else
            PaintPicture PicObject, 0, 0, ScreenWidth, ScreenHeight
        End If
    Else
        TopRow = (ScreenHeight - PicHeight) \ 2
        LeftCol = (ScreenWidth - PicWidth) \ 2
        PaintPicture PicObject, LeftCol, TopRow
    End If

    If ShowFileTitle Then
        If ShowFullPath Then
            DisplayTextMsg PicFilename
        Else
            DisplayTextMsg GetFileName(PicFilename)
        End If
    End If
End Sub

Private Function NextPic(Direction As Long) As Boolean
    If Direction > 0 Then
        Do While PicIndex < TotalPicFiles - 1
            PicIndex = PicIndex + 1
            If LoadPic(PicFiles(PicOrder(PicIndex))) Then NextPic = True: ResetTimer: Exit Do
        Loop
        'tmrDuration.Enabled = false
    Else
        Do While PicIndex > 0
            PicIndex = PicIndex - 1
            If LoadPic(PicFiles(PicOrder(PicIndex))) Then NextPic = True: ResetTimer: Exit Do
        Loop
    End If
End Function

Public Sub StartSlideShow()
    If TotalPicFiles > 0 Then tmrDuration.Enabled = True
End Sub

'Private Sub Form_Unload(Cancel As Integer)
'    ShowCursor True
'End Sub

Private Sub tmrDuration_Timer()
    If Not NextPic(1) Then
        If LoopAtEnd Then
            PicIndex = -1
            If NextPic(1) Then Exit Sub 'continue slide show from beginning
        End If
        DisplayTextMsg "Last picture for slideshow"
        tmrDuration.Enabled = False
    End If
End Sub

Private Sub ResetTimer()
    If tmrDuration.Enabled Then
        tmrDuration.Enabled = False
        tmrDuration.Enabled = True
    End If
    Refresh
End Sub

Private Sub DisplayTextMsg(Text As String)
    Dim LeftCol As Long, TempWidth As Long

    TempWidth = TextWidth(Text)
    LeftCol = (ScreenWidth - TempWidth) \ 2
    Line (LeftCol - 1, 2)-(LeftCol + TempWidth + 2, TextHeight(Text) + 1), 0, BF
    TextOut hdc, LeftCol, 2, Text, Len(Text)
End Sub
