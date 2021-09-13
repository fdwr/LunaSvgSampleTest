VERSION 5.00
Begin VB.Form frmFnamCsum 
   Caption         =   "Filename Checksums"
   ClientHeight    =   3270
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   4680
   Icon            =   "FnamCsum.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   218
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   312
   StartUpPosition =   3  'Windows Default
   WindowState     =   2  'Maximized
   Begin VB.TextBox txtPath 
      Height          =   285
      Left            =   120
      TabIndex        =   0
      Text            =   "C:\WINDOWS"
      Top             =   120
      Width           =   2535
   End
   Begin VB.PictureBox picPlot 
      Height          =   3000
      Left            =   2760
      ScaleHeight     =   196
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   117
      TabIndex        =   4
      Top             =   120
      Width           =   1815
   End
   Begin VB.CommandButton cmdPlot 
      Caption         =   "&Plot"
      Height          =   375
      Left            =   1440
      TabIndex        =   2
      Top             =   480
      Width           =   1215
   End
   Begin VB.CommandButton cmdRefresh 
      Caption         =   "Refresh"
      Default         =   -1  'True
      Height          =   375
      Left            =   120
      TabIndex        =   1
      Top             =   480
      Width           =   1215
   End
   Begin VB.ListBox lstFilenames 
      Height          =   2160
      IntegralHeight  =   0   'False
      Left            =   120
      Sorted          =   -1  'True
      TabIndex        =   3
      Top             =   960
      Width           =   2550
   End
End
Attribute VB_Name = "frmFnamCsum"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Filename Checksum Graph
'2003-05-24
'
'This program itself is only a test visualization for another program.
'Written to visualize filename checksums for an idea I had for faster
'comparison of cross matched files. Instead of every comparing every
'string to every other string in a file list, simply compare checksums.
'First generate name checksums (32bit) for all the source files, and
'store them into a table. Then generate the checksum for the comparison
'file name, and compare it with all the others in the table. Only when
'a match is found should the names be compared, since case insensitive
'comparison is significantly slower than just comparing two numbers.
'
'The checksum algorithm should be written to distribute the values
'across a wider range for fewer collisions (fewer filenames with the
'same checksum). Originally I had written a mere checksummer that
'added all the ASCII values, but this produced too many sloping curves,
'sharp kinks, and greatly offset averages. Now the method (a very
'simple one) distributes most file listings so that the graph is nearly
'linear, and the average and median line up closely. The method simply
'shifts all the bits left by 1 each iteration - no multiplication or
'exponentation. There may still be some file listing patterns that
'cause little kinks, but it is in most cases better than the plain
'checksum.
'
'Rolling the checksum by three or some other odd number might prove
'better in distributing values than only shifting by one (which is
'subject to some sequentially increasing filenames), but neither
'shifting by one nor shifting by three is supported by Visual Basic
'because shifting operations are not supported (stupid!).

Option Explicit
Dim FnamCsums(1000) As Long
Dim TotalFnams As Long
Dim MinCsum As Long
Dim MaxCsum As Long
Dim AvgCsum As Long
Dim MedCsum As Long
Dim TotalCsum As Double

Private Sub cmdPlot_Click()
Dim Fnam As Long
Dim Range As Long
Dim YRange As Long
Dim PicWidth As Long
Dim PicHeight As Long
Dim X As Long, Y As Long

Range = MaxCsum - MinCsum
If Range <= 0 Then Range = 1
PicWidth = picPlot.Width
PicHeight = picPlot.Height
If TotalFnams > PicHeight Then YRange = TotalFnams Else YRange = PicHeight

picPlot.Cls
For Fnam = 0 To TotalFnams - 1
    X = (FnamCsums(Fnam) - MinCsum) * PicWidth \ Range
    Y = Fnam * PicHeight / YRange
    picPlot.Line (0, Y)-(X, Y), &HFFFFFF
Next
X = (AvgCsum - MinCsum) * PicWidth \ Range
picPlot.Line (X, 0)-(X, TotalFnams - 1), &HFF0000
X = PicWidth \ 2
picPlot.Line (X, 0)-(X, TotalFnams - 1), &HFF

txtPath.SelStart = 0
txtPath.SelLength = 32767
txtPath.SetFocus
End Sub

Private Sub cmdRefresh_Click()
Dim FileName As String
Dim FnamCsum As Long
Dim CharPos As Long
Dim Fnam As Long

lstFilenames.Clear
On Error GoTo cmdRefresh_IgnoreErr
FileName = txtPath.Text
If Right$(FileName, 1) <> "\" Then
    If (InStr(FileName, "*") Or InStr(FileName, "?")) = 0 Then
        FileName = FileName & "\"
    End If
End If
FileName = Dir$(FileName, vbArchive Or vbHidden Or vbReadOnly Or vbSystem)
MinCsum = 32767
MaxCsum = 0
TotalCsum = 0
For TotalFnams = 0 To UBound(FnamCsums)
    If Len(FileName$) <= 0 Then Exit For
    FnamCsum = 0
    For CharPos = 1 To Len(FileName)
        FnamCsum = (FnamCsum * 2) And 131071
        If FnamCsum And 65536 Then FnamCsum = (FnamCsum And 65535) + 1
        FnamCsum = FnamCsum + Asc(Mid$(FileName, CharPos, 1))
    Next
    If FnamCsum < MinCsum Then MinCsum = FnamCsum
    If FnamCsum > MaxCsum Then MaxCsum = FnamCsum
    TotalCsum = TotalCsum + FnamCsum
    lstFilenames.AddItem (Format$(FnamCsum, "00000") & " " & FileName)
    FileName = Dir$()
Next
For Fnam = 0 To TotalFnams - 1
    FnamCsums(Fnam) = Val(Left$(lstFilenames.List(Fnam), 5))
Next
AvgCsum = TotalCsum \ TotalFnams
MedCsum = (MaxCsum - MinCsum) \ 2

cmdPlot_Click
cmdRefresh_IgnoreErr:
End Sub

Private Sub Form_Resize()
    If ScaleHeight < 72 Then Exit Sub
    If ScaleWidth < 192 Then Exit Sub
    lstFilenames.Move 8, 64, 170, Me.ScaleHeight - 72
    picPlot.Move 184, 8, Me.ScaleWidth - 192, Me.ScaleHeight - 16
    cmdPlot_Click
End Sub

Private Sub picPlot_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
picPlot_MouseMove Button, Shift, X, Y
End Sub

Private Sub picPlot_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
Dim PicHeight As Long
Dim YRange As Long
Dim Fnam As Long

PicHeight = picPlot.Height
If TotalFnams > PicHeight Then YRange = TotalFnams Else YRange = PicHeight
Fnam = Y * YRange \ PicHeight
If Fnam >= TotalFnams Then Fnam = TotalFnams - 1
If Fnam < 0 Then Fnam = 0
Caption = FnamCsums(Fnam)

If (Button And 1) And TotalFnams > 0 Then
    lstFilenames.ListIndex = Fnam
End If
End Sub

Private Sub txtPath_GotFocus()
    txtPath.SelStart = 0
    txtPath.SelLength = 32767
End Sub
