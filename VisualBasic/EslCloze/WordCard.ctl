VERSION 5.00
Begin VB.UserControl ctlWordCard 
   BackColor       =   &H00FFC0C0&
   CanGetFocus     =   0   'False
   ClientHeight    =   375
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   1575
   MousePointer    =   15  'Size All
   ScaleHeight     =   375
   ScaleWidth      =   1575
   Begin VB.Label lblWord 
      Alignment       =   2  'Center
      Appearance      =   0  'Flat
      BackColor       =   &H00FFC0C0&
      BackStyle       =   0  'Transparent
      BeginProperty Font 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H80000008&
      Height          =   585
      Left            =   7
      TabIndex        =   0
      Top             =   -105
      Width           =   1560
   End
   Begin VB.Shape shpBorder 
      BorderColor     =   &H00000000&
      BorderWidth     =   3
      Height          =   375
      Left            =   0
      Top             =   0
      Width           =   1575
   End
End
Attribute VB_Name = "ctlWordCard"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public Event WordCardGrab(RowAdjust As Integer, ColAdjust As Integer, NewHeight As Integer, NewWidth As Integer)
Public Event WordCardDrag(RowAdjust As Integer, ColAdjust As Integer)
Public Event WordCardDrop(RowAdjust As Integer, ColAdjust As Integer, NewHeight As Integer, NewWidth As Integer)
Public Enabled As Boolean

Const DefaultCardWidth = 1575
Const DefaultCardHeight = 375

Public CardValue As Integer

Private GrabCard As Boolean, GrabRow As Integer, GrabCol As Integer

Private Sub lblWord_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If Enabled Then
        GrabCard = False
        GrabRow = Y
        GrabCol = X
        ShrinkAndGrabCard
        DoEvents
        'UserControl.MousePointer = 2
        GrabCard = True
        'frmDebug.SetMessage "card lock at " & GrabRow & ":" & GrabCol, "ctlWordCard:MouseDown"
    End If
End Sub

Private Sub lblWord_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If GrabCard Then
        GrabCard = False
        'frmDebug.SetMessage "card moved by " & Y & ":" & X, "ctlWordCard:MouseMove"
        'Call frmDebug.Delay
        RaiseEvent WordCardDrag(Y - GrabRow, X - GrabCol)
        GrabCard = True

        'just in case the mouse up event missed
        If (Button And 1) = 0 Then Call lblWord_MouseUp(Button, Shift, X, Y)
    End If
End Sub

Private Sub lblWord_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If GrabCard Then
        GrabCard = False
        Call ExpandAndReleaseCard
        'UserControl.MousePointer = 15
        'frmDebug.SetMessage "card released", "ctlWordCard:MouseUp"
    End If
End Sub

Public Sub SetWord(Text As String)
    lblWord.Caption = vbCr & LCase(Text)
End Sub

Private Sub ShrinkAndGrabCard()
    Dim CardWidth As Integer

    Set UserControl.Font = lblWord.Font
    CardWidth = UserControl.TextWidth(lblWord.Caption) + 64
    'UserControl.Size CardWidth, DefaultCardHeight
    GrabCol = GrabCol - (DefaultCardWidth - CardWidth) \ 2

    shpBorder.Width = CardWidth
    lblWord.Width = CardWidth
    RaiseEvent WordCardGrab(0, (DefaultCardWidth - CardWidth) \ 2, DefaultCardHeight, CardWidth)
End Sub

Private Sub ExpandAndReleaseCard()
    Dim CardWidth As Integer

    CardWidth = UserControl.Width
    lblWord.Width = DefaultCardWidth
    'UserControl.Width = DefaultCardWidth
    shpBorder.Width = DefaultCardWidth
    GrabCol = GrabCol + (DefaultCardWidth - CardWidth) \ 2

    RaiseEvent WordCardDrop(0, 0, DefaultCardHeight, DefaultCardWidth)
End Sub

Public Sub ExpandCard()
    Width = DefaultCardWidth
    Height = DefaultCardHeight
    lblWord.Width = DefaultCardWidth
    shpBorder.Width = DefaultCardWidth
End Sub

Public Sub SetHighlight(Mode As Integer)
    If Mode >= 0 Then
        UserControl.BackColor = &HFFF8F8
        'Border.BorderColor = &HFFFFFF
    Else
        UserControl.BackColor = &HFFC0C0
        'Border.BorderColor = &H0
    End If
End Sub

Private Sub UserControl_Initialize()
    Enabled = True
End Sub
