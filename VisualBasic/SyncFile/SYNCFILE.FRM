VERSION 5.00
Begin VB.Form frmSyncFiles 
   Caption         =   "Synchronize Files"
   ClientHeight    =   4440
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   5415
   Icon            =   "syncfile.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   4440
   ScaleWidth      =   5415
   StartUpPosition =   2  'CenterScreen
   Visible         =   0   'False
   Begin VB.CommandButton cmdRefresh 
      Caption         =   "Refresh"
      Height          =   375
      Left            =   1320
      TabIndex        =   4
      Top             =   3960
      Width           =   1215
   End
   Begin VB.CommandButton cmdSelect 
      Caption         =   "Select ->"
      Height          =   375
      Left            =   2640
      TabIndex        =   5
      Top             =   3960
      Width           =   1215
   End
   Begin VB.CommandButton cmdSyncFiles 
      Caption         =   "Sync. Files"
      Height          =   375
      Left            =   0
      TabIndex        =   3
      Top             =   3960
      Width           =   1215
   End
   Begin VB.TextBox txtSecondPath 
      Height          =   285
      Left            =   2760
      TabIndex        =   7
      Top             =   30
      Width           =   2655
   End
   Begin VB.TextBox txtFirstPath 
      Height          =   285
      Left            =   0
      TabIndex        =   6
      Top             =   30
      Width           =   2655
   End
   Begin VB.ListBox lstSecondPath 
      Height          =   3210
      Left            =   2760
      Sorted          =   -1  'True
      Style           =   1  'Checkbox
      TabIndex        =   1
      Top             =   360
      Width           =   2655
   End
   Begin VB.ListBox lstFirstPath 
      Height          =   3210
      Left            =   0
      Sorted          =   -1  'True
      Style           =   1  'Checkbox
      TabIndex        =   0
      Top             =   360
      Width           =   2655
   End
   Begin VB.Label lblFileInfo 
      BorderStyle     =   1  'Fixed Single
      Height          =   255
      Left            =   0
      TabIndex        =   2
      Top             =   3600
      Width           =   5415
   End
   Begin VB.Menu mnuSelect 
      Caption         =   "Select"
      Enabled         =   0   'False
      Visible         =   0   'False
      Begin VB.Menu mnuSelectNewer 
         Caption         =   "Select Newer"
      End
      Begin VB.Menu mnuSelectUnique 
         Caption         =   "Select Unique"
      End
      Begin VB.Menu mnuSelectNone 
         Caption         =   "Select None"
      End
      Begin VB.Menu mnuSelectAll 
         Caption         =   "Select All"
         Enabled         =   0   'False
      End
   End
End
Attribute VB_Name = "frmSyncFiles"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Const WM_SETREDRAW As Long = &HB
Const LB_ADDSTRING As Long = &H180
Const LB_INSERTSTRING As Long = &H181
Const LB_FINDSTRING As Long = &H18F
Const LB_SETTABSTOPS As Long = &H192
Const LB_SETITEMDATA As Long = &H19A
Const LB_FINDSTRINGEXACT As Long = &H1A2
Const LB_INITSTORAGE As Long = &H1A8
Const LB_ERR As Long = (-1)
'http://www.vbthunder.com/source/series/apictls2.htm
Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
Private Declare Function SendStrMsg Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lpFileName As String) As Long

Const MAX_PATH = 260
Private Declare Function FindFirstFile Lib "kernel32" Alias "FindFirstFileA" (ByVal lpFileName As String, lpFindFileData As WIN32_FIND_DATA) As Long
Private Declare Function FindNextFile Lib "kernel32" Alias "FindNextFileA" (ByVal hFindFile As Long, lpFindFileData As WIN32_FIND_DATA) As Long
Private Declare Function FindClose Lib "kernel32" (ByVal hFindFile As Long) As Long
Private Declare Function CompareFileTime Lib "kernel32.dll" (lpFileTime1 As FILETIME, lpFileTime2 As FILETIME) As Long
Private Declare Function FileTimeToSystemTime Lib "kernel32.dll" (lpFileTime As FILETIME, lpSystemTime As SYSTEMTIME) As Long
'http://161.58.84.211/ref/c/comparefiletime.html
Private Declare Function CopyFile Lib "kernel32.dll" Alias "CopyFileA" (ByVal lpExistingFileName As String, ByVal lpNewFileName As String, ByVal bFailIfExists As Long) As Long
Private Declare Function DeleteFile Lib "kernel32.dll" Alias "DeleteFileA" (ByVal lpFileName As String) As Long
Private Declare Function SHBrowseForFolder Lib "shell32.dll" Alias "SHBrowseForFolderA" (lpbi As BROWSEINFO) As Long
'http://161.58.84.211/ref/s/shbrowseforfolder.html
Private Type FILETIME
    dwLowDateTime As Long
    dwHighDateTime As Long
End Type
Private Type SYSTEMTIME
    wYear As Integer
    wMonth As Integer
    wDayOfWeek As Integer
    wDay As Integer
    wHour As Integer
    wMinute As Integer
    wSecond As Integer
    wMilliseconds As Integer
End Type
Private Type WIN32_FIND_DATA
    dwFileAttributes As Long
    ftCreationTime As FILETIME
    ftLastAccessTime As FILETIME
    ftLastWriteTime As FILETIME
    nFileSizeHigh As Long
    nFileSizeLow As Long
    dwReserved0 As Long
    dwReserved1 As Long
    cFileName As String * MAX_PATH
    cAlternate As String * 14
End Type
Private Type BROWSEINFO
    hwndOwner As Long
    pidlRoot As Long
    pszDisplayName As String
    lpszTitle As String
    ulFlags As Long
    lpfn As Long
    lParam As Long
    iImage As Long
End Type
Private Type SHITEMID
  cbSize As Integer
  abID As String * 256  ' can actually be any size, not necessarily 256
End Type
Private Type ITEMIDLIST
    mkid As SHITEMID
End Type
Const BIF_EDITBOX = &H10
Const BIF_USENEWUI = &H40

Const MaxFiles = 10000
Dim FileNames(MaxFiles - 1) As String
Dim FileLocs(MaxFiles - 1) As Boolean 'location of file, first or second path
Dim FileSel(MaxFiles - 1) As Boolean  'selected
Dim FileSizes(MaxFiles - 1) As Long
Dim FileDates(MaxFiles - 1) As FILETIME

Dim FirstPath As String, SecondPath As String, FileMask As String
Dim Wfd As WIN32_FIND_DATA
Dim TotalFiles As Long
Dim Counter As Long, Result As Long
Dim ErrorOccurred As Boolean
Dim IgnoreItemCheck As Boolean

Private Sub cmdRefresh_Click()
AppendPathSlash txtFirstPath, FirstPath
AppendPathSlash txtSecondPath, SecondPath
CheckFilePath FirstPath
CheckFilePath SecondPath

TotalFiles = 0
ReadFileList 0
ReadFileList 1
BuildFileLists
End Sub

Private Sub cmdSelect_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
PopupMenu mnuSelect
End Sub

Private Sub cmdSyncFiles_Click()

MoveListFiles lstFirstPath, FirstPath, SecondPath
MoveListFiles lstSecondPath, SecondPath, FirstPath
cmdRefresh_Click

End Sub

Private Sub Form_Load()

'FirstPath = "c:\"
'SecondPath = App.Path
FirstPath = "a:\"
SecondPath = "s:\common\-\"

FileMask = "*.*"

txtFirstPath.Text = FirstPath
txtSecondPath.Text = SecondPath
'SendMessage lstFirstPath.hwnd, LB_SETTABSTOPS, 1, 8
'SendMessage lstSecondPath.hwnd, LB_SETTABSTOPS, 1, 8

Show

cmdRefresh_Click
'SelectFilesNewer
SelectFilesUnique

'Show

End Sub

'reads a single folder list contents into the array
Public Sub ReadFileList(Location As Boolean)
Dim FileHnd As Long, Path As String

If Location Then Path = SecondPath Else Path = FirstPath

FileHnd = FindFirstFile(Path & FileMask, Wfd)
Result = FileHnd
Do While Result > 0
    If (Wfd.dwFileAttributes And vbDirectory) = 0 Then
        FileNames(TotalFiles) = Wfd.cFileName
        FileLocs(TotalFiles) = Location
        FileSizes(TotalFiles) = Wfd.nFileSizeLow
        FileDates(TotalFiles) = Wfd.ftLastWriteTime
        TotalFiles = TotalFiles + 1
    End If
    Result = FindNextFile(FileHnd, Wfd)
Loop
FindClose FileHnd

End Sub

Public Sub BuildFileLists()
Dim NewIndex As Long, ListHwnd As Long

'SendMessage ListHwnd, WM_SETREDRAW, False, 0
'SendMessage ListHwnd, LB_INITSTORAGE, TotalFiles, TotalFiles * 16
lstFirstPath.Clear
lstSecondPath.Clear
For Counter = 0 To TotalFiles - 1
    If FileLocs(Counter) Then ListHwnd = lstSecondPath.hwnd Else ListHwnd = lstFirstPath.hwnd
    NewIndex = SendStrMsg(ListHwnd, LB_ADDSTRING, 0, FileNames(Counter))
    SendMessage ListHwnd, LB_SETITEMDATA, NewIndex, ByVal Counter
    'DestList.AddItem (FileNames(Counter))
    'DestList.ItemData(DestList.NewIndex) = Counter
Next
'SendMessage ListHwnd, WM_SETREDRAW, True, 0

End Sub

'selects files that are newer than those on the other side
Public Sub SelectFilesNewer()
Dim Count1 As Long, Count2 As Long
Dim ListCount1 As Long, ListCount2 As Long
Dim Text1 As String, Text2 As String
Dim FileTime1 As FILETIME, FileTime2 As FILETIME

ListCount1 = lstFirstPath.ListCount
ListCount2 = lstSecondPath.ListCount

IgnoreItemCheck = True
Do Until Count1 >= ListCount1 Or Count2 >= ListCount2
    Text1 = lstFirstPath.List(Count1)
    Text2 = lstSecondPath.List(Count2)
    If Text1 = Text2 Then
        FileTime1 = FileDates(lstFirstPath.ItemData(Count1))
        FileTime2 = FileDates(lstSecondPath.ItemData(Count2))
        If CompareFileTime(FileTime1, FileTime2) > 0 Then
            'file1 is newer than file2
            lstFirstPath.Selected(Count1) = True
            lstSecondPath.Selected(Count2) = False
        ElseIf CompareFileTime(FileTime1, FileTime2) Then
            'file1 is older than file2
            lstFirstPath.Selected(Count1) = False
            lstSecondPath.Selected(Count2) = True
        Else
            'files are the same
            lstFirstPath.Selected(Count1) = False
            lstSecondPath.Selected(Count2) = False
        End If
        Count1 = Count1 + 1
        Count2 = Count2 + 1
    ElseIf StrComp(Text1, Text2, vbTextCompare) > 0 Then
        'text1 > text2
        For Count2 = Count2 + 1 To ListCount2 - 1
            If StrComp(Text1, lstSecondPath.List(Count2), vbTextCompare) > 0 Then Exit For
        Next
    Else 'Text1 < Text2
        For Count1 = Count1 + 1 To ListCount1 - 1
            If StrComp(lstFirstPath.List(Count1), Text2, vbTextCompare) >= 0 Then Exit For
        Next
    End If
Loop
IgnoreItemCheck = False

lstFirstPath.Refresh
lstSecondPath.Refresh

End Sub

'selects files on both sides that are not present on the other side
Public Sub SelectFilesUnique()
Dim Count1 As Long, Count2 As Long
Dim ListCount1 As Long, ListCount2 As Long
Dim Text1 As String, Text2 As String

ListCount1 = lstFirstPath.ListCount
ListCount2 = lstSecondPath.ListCount

IgnoreItemCheck = True
Do Until Count1 >= ListCount1 Or Count2 >= ListCount2
    Text1 = lstFirstPath.List(Count1)
    Text2 = lstSecondPath.List(Count2)
    If Text1 = Text2 Then
        Count1 = Count1 + 1
        Count2 = Count2 + 1
    ElseIf StrComp(Text1, Text2, vbTextCompare) > 0 Then
        lstSecondPath.Selected(Count2) = True
        Count2 = Count2 + 1
    Else 'Text1 < Text2
        lstFirstPath.Selected(Count1) = True
        Count1 = Count1 + 1
    End If
Loop
Do Until Count1 >= ListCount1
    lstFirstPath.Selected(Count1) = True
    Count1 = Count1 + 1
Loop
Do Until Count2 >= ListCount2
    lstSecondPath.Selected(Count2) = True
    Count2 = Count2 + 1
Loop
IgnoreItemCheck = False

lstFirstPath.Refresh
lstSecondPath.Refresh

End Sub

Public Sub SelectFilesNone()

For Counter = 0 To lstFirstPath.ListCount - 1
    lstFirstPath.Selected(Counter) = False
Next
For Counter = 0 To lstSecondPath.ListCount - 1
    lstSecondPath.Selected(Counter) = False
Next

End Sub

Private Sub lstFirstPath_Click()
If IgnoreItemCheck Then Exit Sub
ShowFileInformation lstFirstPath
SetAdjacentListItem lstFirstPath, lstSecondPath
End Sub

Private Sub lstFirstPath_GotFocus()
ShowFileInformation lstFirstPath
cmdSyncFiles.Default = True
End Sub

Private Sub lstFirstPath_ItemCheck(Item As Integer)
If Not IgnoreItemCheck Then SetAdjacentListItem lstFirstPath, lstSecondPath
End Sub

Private Sub lstFirstPath_KeyDown(KeyCode As Integer, Shift As Integer)
If KeyCode = vbKeyRight Or KeyCode = vbKeyLeft Then
    KeyCode = 0: lstSecondPath.SetFocus
ElseIf KeyCode = vbKeyDelete Then
    DeleteListFiles lstFirstPath, FirstPath
End If
End Sub

Private Sub lstSecondPath_Click()
If IgnoreItemCheck Then Exit Sub
ShowFileInformation lstSecondPath
SetAdjacentListItem lstSecondPath, lstFirstPath
End Sub

Private Sub lstSecondPath_GotFocus()
ShowFileInformation lstSecondPath
cmdSyncFiles.Default = True
End Sub

Private Sub lstSecondPath_ItemCheck(Item As Integer)
If Not IgnoreItemCheck Then SetAdjacentListItem lstSecondPath, lstFirstPath
End Sub

Private Sub lstSecondPath_KeyDown(KeyCode As Integer, Shift As Integer)
If KeyCode = vbKeyRight Or KeyCode = vbKeyLeft Then
    KeyCode = 0: lstFirstPath.SetFocus
ElseIf KeyCode = vbKeyDelete Then
    DeleteListFiles lstSecondPath, SecondPath
End If
End Sub

Public Sub SetAdjacentListItem(lstSrc As ListBox, lstDest As ListBox)
Dim SrcItem As Long, DestItem As Long

DestItem = SendStrMsg(lstDest.hwnd, LB_FINDSTRING, lstDest.ListIndex - 1, lstSrc.Text)
If DestItem <> LB_ERR Then
    SrcItem = lstSrc.ListIndex
    IgnoreItemCheck = True
    lstDest.ListIndex = DestItem
    If lstSrc.Selected(SrcItem) Then lstDest.Selected(DestItem) = False
    IgnoreItemCheck = False
End If
End Sub

Public Sub ShowFileInformation(lstSrc As ListBox)
Dim Count As Long
Dim SysTime As SYSTEMTIME

Count = lstSrc.ListIndex
If Count < 0 Then Exit Sub
Count = lstSrc.ItemData(Count)
FileTimeToSystemTime FileDates(Count), SysTime

lblFileInfo = "Date:" & SysTime.wYear & "-" & SysTime.wMonth & "-" & SysTime.wDay _
            & "  Time:" & SysTime.wHour & ":" & SysTime.wMinute & ":" & SysTime.wSecond _
            & "  Size:" & FileSizes(Count)
End Sub

Public Sub MoveListFiles(lstSrc As ListBox, SrcPath As String, DestPath As String)
Dim Text As String

For Counter = 0 To lstSrc.ListCount - 1
    If lstSrc.Selected(Counter) Then
        Text = lstSrc.List(Counter)
        Result = CopyFile(SrcPath & Text, DestPath & Text, 0)
        If Result <> 1 Then ErrorOccurred = True
    End If
Next
If ErrorOccurred Then MsgBox "Some of the files could not be copied. Sorry, don't know why.", vbInformation, "Synchronization Error"

End Sub

Public Sub DeleteListFiles(lstSrc As ListBox, SrcPath As String)

If frmMyMsgBox.MyMsgBox("Delete the selected files?", "Confirm Deletion", Array("Delete", "Cancel")) = 0 Then
    Counter = 0
    Do Until Counter >= lstSrc.ListCount
        If lstSrc.Selected(Counter) Then
            'Kill SrcPath & lstSrc.List(Counter)
            Result = DeleteFile(SrcPath & lstSrc.List(Counter))
            If Result = 1 Then lstSrc.RemoveItem Counter Else ErrorOccurred = True
        Else
            Counter = Counter + 1
        End If
    Loop
End If
If ErrorOccurred Then MsgBox "Some of the files could not be deleted, possibly because they are read-only or system files.", vbInformation, "Deletion Error"

End Sub

Private Sub mnuSelectNewer_Click()
SelectFilesNewer
End Sub

Private Sub mnuSelectNone_Click()
SelectFilesNone
End Sub

Private Sub mnuSelectUnique_Click()
SelectFilesUnique
End Sub

Private Sub txtFirstPath_GotFocus()
cmdRefresh.Default = True
End Sub

Private Sub txtSecondPath_GotFocus()
cmdRefresh.Default = True
End Sub

Public Sub AppendPathSlash(txtItem As TextBox, Text As String)
Text = txtItem.Text
If Right(Text, 1) <> "\" Then Text = Text & "\": txtItem.Text = Text
txtItem.SelStart = 0
txtItem.SelLength = 32767
End Sub

Public Sub CheckFilePath(Path As String)
Dim FileHnd As Long

FileHnd = FindFirstFile(Path & "*", Wfd)
FindClose FileHnd
If FileHnd <= 0 Then MsgBox "The path '" & Path & "' does not exist or can not be accessed.", vbExclamation, "Path Error"

End Sub
