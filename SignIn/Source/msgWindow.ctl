VERSION 5.00
Begin VB.UserControl msgWindow 
   BackColor       =   &H00FFC0C0&
   CanGetFocus     =   0   'False
   ClientHeight    =   615
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   3495
   BeginProperty Font 
      Name            =   "MS Sans Serif"
      Size            =   13.5
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   MousePointer    =   14  'Arrow and Question
   ScaleHeight     =   41
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   233
   Begin VB.Image imgSign 
      Height          =   2895
      Left            =   3720
      Top             =   120
      Width           =   1470
   End
   Begin VB.Label lblMsg 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Height          =   360
      Left            =   120
      TabIndex        =   0
      Top             =   120
      Width           =   3255
      WordWrap        =   -1  'True
   End
End
Attribute VB_Name = "msgWindow"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Displays a borderless message window with just text or text
'and a picture. The color might indicate an error or success.

Private Declare Function SetCapture Lib "user32" (ByVal hwnd As Long) As Long
Private Declare Function ReleaseCapture Lib "user32" () As Long
'Private Declare Function SetCursor Lib "user32" (ByVal hCursor As Long) As Long
'Private Declare Function LoadCursor Lib "user32" Alias "LoadCursorA" (ByVal hInstance As Long, ByVal lpCursorName As String) As Long

Public Event CloseMe()

Public Sub SetMsg(Text As String, Color As Long)
    imgSign.Visible = False
    Set lblMsg.Font = UserControl.Font
    lblMsg.Caption = Text
    lblMsg.Top = 10
    lblMsg.Left = 10
    lblMsg.Width = 220
    Height = (lblMsg.Height + 20) * Screen.TwipsPerPixelY
    Width = (lblMsg.Width + 20) * Screen.TwipsPerPixelX 'determine width after label's autosize

    BackColor = Color

    CaptureCursor
End Sub

Public Sub SetPicMsg(Text As String, Color As Long, Pic As StdPicture, Align As Long)
    Dim ImageWidth As Long, ImageHeight As Long
    Dim LabelWidth As Long, LabelHeight As Long
    Dim MsgWidth As Long, MsgHeight As Long

    Set lblMsg.Font = UserControl.Font
    LabelWidth = TextWidth(Text)
    If LabelWidth >= 400 Then LabelWidth = 400
    lblMsg.Width = LabelWidth
    lblMsg.Caption = Text
    LabelHeight = lblMsg.Height
    If Len(Text) = 0 Then LabelHeight = 0
    LabelWidth = lblMsg.Width

    'imgSign.Stretch = False
    Set imgSign.Picture = Pic
    ImageHeight = imgSign.Height
    ImageWidth = imgSign.Width
    'If ImageWidth > 40 Then
    '    ImageWidth = 40
    '    imgSign.Width = ImageWidth
    '    imgSign.Stretch = True
    'End If
    'If ImageHeight > 30 Then
    '    ImageHeight = 30
    '    imgSign.Height = ImageHeight
    '    imgSign.Stretch = True
    'End If

    If Align = 0 Then
        lblMsg.Left = 20 + ImageWidth
    Else
        lblMsg.Left = 10
    End If
    If Align = 1 Then
        imgSign.Left = 20 + LabelWidth
    Else
        imgSign.Left = 10
    End If
    If Align = 2 Then
        lblMsg.Top = 20 + ImageHeight
    Else
        lblMsg.Top = 10
    End If
    If Align = 3 Then
        imgSign.Top = 20 + LabelWidth
    Else
        imgSign.Top = 10
    End If

    If Align And 2 Then 'align vertical
        'text
        '----
        'picture
        MsgHeight = LabelHeight + ImageHeight + 20
        If LabelHeight > 0 Then MsgHeight = MsgHeight + 10
        Height = MsgHeight * Screen.TwipsPerPixelY
        
        MsgWidth = IIf(ImageWidth > LabelWidth, ImageWidth, LabelWidth)
        MsgWidth = MsgWidth + 20
        imgSign.Left = (MsgWidth - ImageWidth) \ 2
        Width = MsgWidth * Screen.TwipsPerPixelX
    Else 'align horizontal
        'text | picture
        MsgWidth = LabelWidth + ImageWidth + 20
        If LabelWidth > 0 Then MsgWidth = MsgWidth + 10
        Width = MsgWidth * Screen.TwipsPerPixelX

        MsgHeight = IIf(ImageHeight > LabelHeight, ImageHeight, LabelHeight)
        MsgHeight = MsgHeight + 20
        imgSign.Top = (MsgHeight - ImageHeight) \ 2
        Height = MsgHeight * Screen.TwipsPerPixelY
    End If

    imgSign.Visible = True
    BackColor = Color

    CaptureCursor
End Sub

' finish up common code between the two
Private Sub CaptureCursor()
    SetCapture UserControl.hwnd
    UserControl.MousePointer = vbArrowQuestion
End Sub


#If 0 Then
' old code
Public Sub SetPicMsg(Text As String, Pic As StdPicture, Align As Byte)
    Dim ImageWidth As Long, ImageHeight As Long
    Dim LabelWidth As Long, LabelHeight As Long
    Dim MsgWidth As Long, MsgHeight As Long

    lblMsg.Font = UserControl.Font
    LabelWidth = TextWidth(Text)
    If LabelWidth >= 5680 Then LabelWidth = 5680
    lblMsg.Width = LabelWidth
    lblMsg.Caption = Text
    'If lblMsg.Width > 5680 Then lblMsg.Width = 5680
    Set imgSign.Picture = Pic
    LabelHeight = lblMsg.Height
    If Len(Text) = 0 Then LabelHeight = 0
    LabelWidth = lblMsg.Width
    ImageHeight = imgSign.Height
    ImageWidth = imgSign.Width
    If ImageWidth > 100 Then ImageWidth = 100: imgSign.Width = ImageWidth
    If ImageHeight > 100 Then ImageHeight = 100: imgSign.Height = ImageHeight

    If Align = 0 Then
        lblMsg.Left = 240 + ImageWidth
    Else
        lblMsg.Left = 120
    End If
    If Align = 1 Then
        imgSign.Left = 240 + LabelWidth
    Else
        imgSign.Left = 120
    End If
    If Align = 2 Then
        lblMsg.Top = 240 + ImageHeight
    Else
        lblMsg.Top = 120
    End If
    If Align = 3 Then
        imgSign.Top = 240 + LabelWidth
    Else
        imgSign.Top = 120
    End If

    If Align And 2 Then 'align vertical
        Height = LabelHeight + ImageHeight + 240
        If LabelHeight > 0 Then Height = Height + 120
        MsgWidth = IIf(ImageWidth > LabelWidth, ImageWidth, LabelWidth)
        MsgWidth = MsgWidth + 240
        imgSign.Left = (MsgWidth - ImageWidth) \ 2
        Width = MsgWidth
    Else 'align horizontal
        Width = LabelWidth + ImageWidth + 240
        If LabelWidth > 0 Then Width = Width + 120
        MsgHeight = IIf(ImageHeight > LabelHeight, ImageHeight, LabelHeight)
        MsgHeight = MsgHeight + 240
        imgSign.Top = (MsgHeight - ImageHeight) \ 2
        Height = MsgHeight
    End If

    BackColor = BgColor
    imgSign.Visible = True
End Sub
#End If

Private Sub ImgSign_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    RaiseEvent CloseMe
End Sub

Private Sub lblMsg_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    RaiseEvent CloseMe
End Sub

Private Sub UserControl_Hide()
    ReleaseCapture
End Sub

Private Sub UserControl_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    RaiseEvent CloseMe
End Sub

Public Property Get Font() As Font
    Set Font = UserControl.Font
End Property

Public Property Let ForeColor(Color As Long)
    lblMsg.ForeColor = Color
End Property
