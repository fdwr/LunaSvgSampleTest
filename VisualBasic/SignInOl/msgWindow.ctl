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
   ScaleHeight     =   615
   ScaleWidth      =   3495
   Begin VB.Image imgSign 
      Height          =   2895
      Left            =   3720
      Picture         =   "msgWindow.ctx":0000
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

Dim BgColor As Long

Public Event CloseMe()

Public Sub SetMsg(Text As String)
    imgSign.Visible = False
    lblMsg.Caption = Text
    lblMsg.Top = 120
    lblMsg.Left = 120
    lblMsg.Width = 3255
    Height = lblMsg.Height + 240
    Width = lblMsg.Width + 240 'determine width after label's autosize
    BackColor = BgColor
End Sub

Public Sub SetPicMsg(Text As String, Pic As StdPicture, Align As Byte)
    Dim ImageWidth As Long, ImageHeight As Long
    Dim LabelWidth As Long, LabelHeight As Long
    Dim MsgWidth As Long, MsgHeight As Long

    LabelWidth = TextWidth(Text)
    If LabelWidth >= 5680 Then LabelWidth = 5680
    lblMsg.Width = LabelWidth
    lblMsg.Caption = Text
    'If lblMsg.Width > 5680 Then lblMsg.Width = 5680
    Set imgSign.Picture = Pic
    LabelHeight = lblMsg.Height
    LabelWidth = lblMsg.Width
    ImageHeight = imgSign.Height
    ImageWidth = imgSign.Width

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
        Height = lblMsg.Height + imgSign.Height + 360
        MsgWidth = IIf(ImageWidth > LabelWidth, ImageWidth, LabelWidth)
        MsgWidth = MsgWidth + 240
        imgSign.Left = (MsgWidth - ImageWidth) \ 2
        Width = MsgWidth
    Else 'align horizontal
        Width = lblMsg.Width + imgSign.Width + 360
        MsgHeight = IIf(ImageHeight > LabelHeight, ImageHeight, LabelHeight)
        MsgHeight = MsgHeight + 240
        imgSign.Top = (MsgHeight - ImageHeight) \ 2
        Height = MsgHeight
    End If

    BackColor = BgColor
    imgSign.Visible = True
End Sub

Public Sub SetColor(Color As Long)
    BgColor = Color
End Sub

Private Sub ImgSign_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    RaiseEvent CloseMe
End Sub

Private Sub lblMsg_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    RaiseEvent CloseMe
End Sub

Private Sub UserControl_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    RaiseEvent CloseMe
End Sub
