VERSION 5.00
Begin VB.Form frmPicViewr 
   Caption         =   "Peekin's Picture Viewer"
   ClientHeight    =   4485
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   9885
   Icon            =   "PicViewr.frx":0000
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   ScaleHeight     =   299
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   659
   StartUpPosition =   3  'Windows Default
   WindowState     =   2  'Maximized
   Begin VB.CheckBox chkStrech 
      Caption         =   "&Strech Image"
      Height          =   315
      Left            =   120
      TabIndex        =   4
      Top             =   840
      Width           =   1575
   End
   Begin VB.CommandButton cmdGoto 
      Caption         =   "&Goto..."
      Height          =   255
      Left            =   120
      TabIndex        =   3
      Top             =   480
      Width           =   1575
   End
   Begin VB.PictureBox picViewed 
      ClipControls    =   0   'False
      Height          =   4260
      Left            =   1800
      ScaleHeight     =   280
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   527
      TabIndex        =   1
      Top             =   120
      Width           =   7965
      Begin VB.Image imgViewed 
         Height          =   15
         Left            =   120
         MousePointer    =   5  'Size
         ToolTipText     =   "Grab with the mouse to pan the picture. Use arrow keys to view next/previous."
         Top             =   120
         Width           =   15
      End
   End
   Begin VB.CommandButton cmdView 
      Caption         =   "View"
      Default         =   -1  'True
      Height          =   285
      Left            =   120
      TabIndex        =   2
      Top             =   120
      Width           =   1575
   End
   Begin VB.FileListBox filPics 
      Height          =   285
      Left            =   120
      TabIndex        =   0
      ToolTipText     =   "Double-click on a file in the list to view it."
      Top             =   1200
      Width           =   1575
   End
End
Attribute VB_Name = "frmPicViewr"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Simple Slideshow Picture Viewer
'Dwayne Robinson
'2001.4.12
Option Explicit

Const OFNHideReadOnly = 4, OFNFileMustExist = 4096, OFNPathMustExist = &H800
Const PicExtensions = "*.jpg;*.bmp;*.gif"

Private Type OPENFILENAME
    lStructSize As Long
    hwndOwner As Long
    hInstance As Long
    lpstrFilter As String
    lpstrCustomFilter As String
    nMaxCustFilter As Long
    nFilterIndex As Long
    lpstrFile As String
    nMaxFile As Long
    lpstrFileTitle As String
    nMaxFileTitle As Long
    lpstrInitialDir As String
    lpstrTitle As String
    flags As Long
    nFileOffset As Integer
    nFileExtension As Integer
    lpstrDefExt As String
    lCustData As Long
    lpfnHook As Long
    lpTemplateName As String
End Type 'http://www.vbcode.com/asp/showsn.asp?theID=1401

Private Declare Function GetOpenFileName Lib "comdlg32.dll" Alias "GetOpenFileNameA" (pOpenfilename As OPENFILENAME) As Long

Dim PicFile As String
Dim PicBoxHeight As Long
Dim PicBoxWidth As Long
Dim PicGrabRow As Long
Dim PicGrabCol As Long
Dim ofn As OPENFILENAME

Private Sub chkStrech_Click()
    'imgViewed.Stretch = chkStrech.Value
    ResizeImage
End Sub

Private Sub cmdGoto_Click()
    Dim Count As Long, File As String, SepPos As Long

    ofn.lStructSize = Len(ofn)
    ofn.hwndOwner = Me.hWnd
    ofn.hInstance = App.hInstance
    ofn.lpstrFilter = "Picture files (bmp jpg png gif)" & vbNullChar & PicExtensions & vbNullChar & "All files (*.*)" & vbNullChar & "*.*" & vbNullChar
    ofn.lpstrFile = Space$(254)
    ofn.nMaxFile = 255
    ofn.lpstrFileTitle = Space$(254)
    ofn.nMaxFileTitle = 255
    ofn.lpstrInitialDir = CurDir
    ofn.lpstrTitle = "Select Picture File"
    ofn.flags = OFNHideReadOnly Or OFNFileMustExist Or OFNPathMustExist

    If GetOpenFileName(ofn) Then
        File = Trim$(ofn.lpstrFile)
        Caption = File
        SepPos = InStrRev(File, "\")
        If SepPos Then
            filPics.Path = Left(File, SepPos - 1)
            File = UCase(Mid(File, SepPos + 1, Len(File) - SepPos - 1))
            For Count = 0 To filPics.ListCount - 1
                If UCase(filPics.List(Count)) = File Then
                    filPics.ListIndex = Count
                    cmdView_Click
                    Exit For
                End If
            Next
        End If
    End If
End Sub

Private Sub cmdView_Click()
    Dim File As String

    imgViewed.Stretch = False 'need to get picture's true size
    File = filPics.Path & "\" & filPics.FileName
    On Error GoTo PicReadErr
    Caption = "Picture Viewer - Loading " & File
    imgViewed.Picture = LoadPicture(File)
    PicFile = File
    Caption = "Picture Viewer - " & PicFile
    ResizeImage
    Exit Sub
PicReadErr:
    MsgBox "Could not open " & File
    Caption = "Peekin's Picture Viewer - " & PicFile
End Sub

Private Sub ResizeImage()

PicBoxHeight = picViewed.ScaleHeight
PicBoxWidth = picViewed.ScaleWidth
If chkStrech.Value Then
    imgViewed.Stretch = True
    imgViewed.Move 0, 0, PicBoxWidth, imgViewed.Height * PicBoxWidth \ imgViewed.Width
Else
    imgViewed.Stretch = False
    imgViewed.Move 0, 0 ', PicBoxWidth, PicBoxHeight
End If

End Sub

Private Sub RepositionImage(Row As Long, Col As Long)

PicBoxHeight = picViewed.ScaleHeight
PicBoxWidth = picViewed.ScaleWidth

If Row > 0 Or imgViewed.Height <= PicBoxHeight Then
    Row = 0
ElseIf Row + imgViewed.Height < PicBoxHeight Then
        Row = PicBoxHeight - imgViewed.Height
End If
If Col > 0 Or imgViewed.Width <= PicBoxWidth Then
    Col = 0
ElseIf Col + imgViewed.Width < PicBoxWidth Then
        Col = PicBoxWidth - imgViewed.Width
End If
imgViewed.Move Col, Row

End Sub

Private Sub filPics_DblClick()
    cmdView_Click
End Sub

Private Sub Form_KeyPress(KeyAscii As Integer)
    If KeyAscii = vbKeyEscape Then Unload Me
End Sub

Private Sub Form_Load()
    filPics.Pattern = PicExtensions
    filPics.Hidden = True
    filPics.System = True
    'filPics.Path = "c:\Dwayne's\Pics"
    'filPics.Path = "s:\common\fdwr"
    'filPics.Path = "s:\common\fdwr\SignIn"
    'filPics.Path = "c:\Windows"
End Sub

Private Sub Form_Resize()
    Dim WindowHeight As Long, WindowWidth As Long, ItemSize As Long

    WindowHeight = ScaleHeight
    WindowWidth = ScaleWidth
    ItemSize = WindowHeight - 80: If ItemSize < 13 Then ItemSize = 3
    filPics.Height = ItemSize
    ItemSize = WindowHeight - 16: If ItemSize < 6 Then ItemSize = 6
    picViewed.Height = ItemSize
    ItemSize = WindowWidth - 128: If ItemSize < 6 Then ItemSize = 6
    picViewed.Width = ItemSize
    RepositionImage imgViewed.Top, imgViewed.Left
End Sub

Private Sub imgViewed_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    'grab picture for panning
    If Button And 1 Then
        picViewed.SetFocus
        PicBoxHeight = picViewed.ScaleHeight
        PicBoxWidth = picViewed.ScaleWidth
        PicGrabRow = Y
        PicGrabCol = X
    End If
End Sub

Private Sub imgViewed_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)

'adjust image top/left
If Button And 1 Then
    RepositionImage imgViewed.Top + (Y - PicGrabRow) \ 15, imgViewed.Left + (X - PicGrabCol) \ 15
End If

End Sub

Private Sub picViewed_KeyDown(KeyCode As Integer, Shift As Integer)
    Dim Idx As Long, Last As Long

    Idx = filPics.ListIndex
    Last = filPics.ListCount - 1
    If KeyCode = vbKeyUp Then 'previous pic
        If Idx > 0 Then filPics.ListIndex = Idx - 1: cmdView_Click
    ElseIf KeyCode = vbKeyDown Then 'next pic
        If Idx < Last Then filPics.ListIndex = Idx + 1: cmdView_Click
    ElseIf KeyCode = vbKeyHome Then
         If Idx < filPics.ListCount And Idx <> 0 Then filPics.ListIndex = 0: cmdView_Click
    ElseIf KeyCode = vbKeyEnd Then
         If filPics.ListCount > 0 And Idx <> Last Then filPics.ListIndex = Last: cmdView_Click
    End If
End Sub
