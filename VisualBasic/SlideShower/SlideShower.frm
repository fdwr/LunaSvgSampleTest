VERSION 5.00
Begin VB.Form frmSlideShower 
   Caption         =   "Peekin's SlideShower"
   ClientHeight    =   5325
   ClientLeft      =   210
   ClientTop       =   780
   ClientWidth     =   8880
   Icon            =   "SlideShower.frx":0000
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   ScaleHeight     =   355
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   592
   StartUpPosition =   3  'Windows Default
   WindowState     =   2  'Maximized
   Begin VB.ListBox lstFiles 
      Height          =   5130
      Left            =   0
      TabIndex        =   0
      ToolTipText     =   "Click on a picture's name to view it. Press Enter to view full screen."
      Top             =   2400
      Width           =   1935
   End
   Begin VB.PictureBox picContainer 
      Height          =   7815
      Left            =   2040
      ScaleHeight     =   517
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   660
      TabIndex        =   5
      TabStop         =   0   'False
      Top             =   120
      Width           =   9960
      Begin VB.Image imgPicture 
         Height          =   30720
         Left            =   0
         MouseIcon       =   "SlideShower.frx":030A
         MousePointer    =   5  'Size
         ToolTipText     =   "Left button to pan picture, Right click for full screen"
         Top             =   0
         Width           =   30720
      End
      Begin VB.Label lblBlocker 
         BackStyle       =   0  'Transparent
         Height          =   30720
         Left            =   0
         MousePointer    =   12  'No Drop
         TabIndex        =   6
         ToolTipText     =   "And here we see an admirable waste of perfectly useable blank space"
         Top             =   0
         Width           =   30720
      End
   End
   Begin VB.DirListBox dirFiles 
      Height          =   1890
      Left            =   0
      TabIndex        =   4
      ToolTipText     =   "Double click on a folder or press Enter to change"
      Top             =   480
      Width           =   1935
   End
   Begin VB.DriveListBox drvFiles 
      Height          =   315
      Left            =   0
      TabIndex        =   3
      Top             =   120
      Width           =   1935
   End
   Begin VB.TextBox txtPicDuration 
      Height          =   285
      Left            =   0
      TabIndex        =   2
      Text            =   "4"
      Top             =   7680
      Width           =   495
   End
   Begin VB.Line Line2 
      BorderColor     =   &H80000014&
      X1              =   0
      X2              =   800
      Y1              =   1
      Y2              =   1
   End
   Begin VB.Line Line1 
      BorderColor     =   &H80000010&
      X1              =   0
      X2              =   800
      Y1              =   0
      Y2              =   0
   End
   Begin VB.Label lblDuration 
      Caption         =   "second &duration"
      Height          =   255
      Left            =   600
      TabIndex        =   1
      Top             =   7680
      Width           =   1335
   End
   Begin VB.Menu mnuFile 
      Caption         =   "&File"
      Begin VB.Menu mnuOpen 
         Caption         =   "Open..."
         Shortcut        =   ^O
      End
      Begin VB.Menu mnuOpenList 
         Caption         =   "Open list"
         Shortcut        =   ^L
      End
      Begin VB.Menu mnuGotoPath 
         Caption         =   "Goto path..."
         Shortcut        =   ^G
      End
      Begin VB.Menu mnuRecurse 
         Caption         =   "Recurse"
      End
      Begin VB.Menu mnuRefresh 
         Caption         =   "Refresh"
         Shortcut        =   {F5}
      End
      Begin VB.Menu mnu1 
         Caption         =   "-"
      End
      Begin VB.Menu mnuRename 
         Caption         =   "Rename"
         Shortcut        =   ^R
      End
      Begin VB.Menu mnuDelete 
         Caption         =   "Delete"
         Enabled         =   0   'False
         Shortcut        =   {DEL}
      End
      Begin VB.Menu mnu0 
         Caption         =   "-"
      End
      Begin VB.Menu mnuClose 
         Caption         =   "E&xit"
      End
   End
   Begin VB.Menu mnuView 
      Caption         =   "&View"
      Begin VB.Menu mnuPreloadNext 
         Caption         =   "&Preload next picture"
         Checked         =   -1  'True
         Enabled         =   0   'False
      End
      Begin VB.Menu mnuFitImage 
         Caption         =   "&Fit image full screen"
      End
      Begin VB.Menu mnuKeepProportional 
         Caption         =   "Keep &proportional"
         Checked         =   -1  'True
      End
      Begin VB.Menu mnuShowFileTitle 
         Caption         =   "Show file &title"
      End
      Begin VB.Menu mnuShowFullPath 
         Caption         =   "Show full path"
      End
      Begin VB.Menu mnuLoopAtEnd 
         Caption         =   "&Loop show at end"
      End
      Begin VB.Menu mnuSortByName 
         Caption         =   "Sort by &name"
         Checked         =   -1  'True
      End
   End
   Begin VB.Menu mnuFullScreen 
      Caption         =   "F&ull screen"
   End
   Begin VB.Menu mnuSlideShow 
      Caption         =   "&Slideshow"
   End
   Begin VB.Menu mnuHelp 
      Caption         =   "&Help"
      Begin VB.Menu mnuAbout 
         Caption         =   "&About..."
      End
      Begin VB.Menu mnuCredits 
         Caption         =   "&Credits..."
      End
   End
End
Attribute VB_Name = "frmSlideShower"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

' these following variables are used for panning
Private GrabY As Long, GrabX As Long
Private PicY As Long, PicX As Long
Private InnerHeight As Long, InnerWidth As Long

Private KeyHoldCount As Long
Private ListClick As Boolean

Private Sub dirFiles_Change()
    PicPath = FixPath(dirFiles.Path)
    ReadFolder
End Sub

Private Sub ReadFileList()
'Reads picture filename from the current
'path into the file list
    Dim FileName As String

    On Error GoTo VeryBadPicList
    Open PicPath & "pics.lst" For Input As 1
    TotalPicFiles = 0
    With lstFiles
        .Clear
        Do Until EOF(1)
            Line Input #1, FileName
            If FileIsPicture(FileName) Then
                .AddItem GetFileName(FileName)
                If InStr(FileName, ":") = 0 Then FileName = PicPath & FileName
                PicFiles(TotalPicFiles) = FileName
                TotalPicFiles = TotalPicFiles + 1
                If TotalPicFiles >= MaxPicFiles Then Exit Do
            End If
        Loop
    End With
    Close 1
    UnorderedPicFiles
    ClearUnusedFiles
    Exit Sub
VeryBadPicList:
    MsgBox "No 'PICS.LST' file in this folder to read." & vbNewLine & vbNewLine _
         & "The picture list is simply a text file containing all the pictures to view in the slideshow. The pictures can be a selected group of pictures in the current path, or even span multiple folders if the full path is given. Notepad can be used to create this little file, or even the Command prompt ('DIR *.JPG /B > PICS.LST')", _
           vbExclamation, _
           "No picture list"
End Sub

Private Sub ReadFolder()
'Reads picture filename from the current
'path into the file list
    Dim FileName As String
    Dim Count As Long

    Caption = "Finding pictures in current folder..."

    'read all files in folder
    On Error GoTo DriveWasValidButNoMore
    FileName = Dir(PicPath, vbArchive Or vbReadOnly Or vbHidden)
    TotalPicFiles = 0
    Do While Len(FileName)
        If FileIsPicture(FileName) Then
            PicFiles(TotalPicFiles) = FileName
            TotalPicFiles = TotalPicFiles + 1
            If TotalPicFiles >= MaxPicFiles Then Exit Do
        End If
        FileName = Dir()
    Loop

    If mnuSortByName.Checked Then
        OrderPicFiles
    Else
        UnorderedPicFiles
    End If

    'add files to list
    With lstFiles
        .Clear
        For Count = 0 To TotalPicFiles - 1
            .AddItem PicFiles(PicOrder(Count))
        Next
    End With
    For Count = 0 To TotalPicFiles - 1
        PicFiles(Count) = PicPath & PicFiles(Count)
    Next
    ClearUnusedFiles
    Caption = "Found " & TotalPicFiles & " pictures in folder"

DriveWasValidButNoMore:
End Sub

Private Sub RecurseFolder()
'Reads picture filename from the current
'path and every subfolder into the file list
'**for now, is no different than ReadFolder
    Dim FileName As String
    Dim FolderIdx As Long
    Dim FileHandle As Long
    Dim CurPath As String

    Caption = "Finding every file under current path..."
    TotalPicFiles = 0
    FolderIdx = MaxPicFiles
    CurPath = PicPath

    'Don't understand what's going on here?
    'It's using the same array for both files and folders
    'Files are added to the list
    'Folder names are stored to come back to later
    '
    '   read all the entries in the current path
    '   if it's a file, put add it to the bottom of the list (grow up)
    '   if it's a folder, put it at the top (grow down)
    '
    'This approach means:
    '  each folder needs only be read once
    '  don't need multiple file handles open simultaneously
    '  no recursive routines
    '  probably a little faster because all of the above
    '
    'Drawbacks:
    '  uses more memory
    '  if the recursed structure is too complex, not as many
    '    files fit into the array that otherwise might

    With lstFiles
    .Clear
    GoTo GotoFindFirstFile  'this "forbidden" goto actually
                            'makes the code easier to read
    Do
        'retreat up to parent folder
        CurPath = PicFiles(FolderIdx) & "\"
        FolderIdx = FolderIdx + 1
GotoFindFirstFile:
        FileHandle = FindFirstFile(CurPath & "*", WFD)
        If FileHandle <> INVALID_HANDLE_VALUE Then
            Do
                FileName = Left$(WFD.cFileName, InStr(WFD.cFileName, vbNullChar) - 1)
                If WFD.dwFileAttributes And FILE_ATTRIBUTE_DIRECTORY Then
                    'save path for later
                    If Left$(FileName, 1) <> "." Then
                        If FolderIdx <= TotalPicFiles Then Exit Do
                        FolderIdx = FolderIdx - 1
                        PicFiles(FolderIdx) = CurPath & FileName
                    End If
                Else
                    'add file to list
                    If FileIsPicture(FileName) Then
                        PicFiles(TotalPicFiles) = CurPath & FileName
                        .AddItem FileName
                        TotalPicFiles = TotalPicFiles + 1
                        If TotalPicFiles >= MaxPicFiles Then Exit Do
                        If TotalPicFiles > FolderIdx Then FolderIdx = FolderIdx + 1
                    End If
                End If
            Loop While FindNextFile(FileHandle, WFD)
        End If
        FindClose FileHandle
        If GetAsyncKeyState(VK_ESCAPE) And &H80 Then Exit Do
    Loop While FolderIdx < MaxPicFiles 'loop while still more unread paths
    End With

    UnorderedPicFiles
    ClearUnusedFiles

    Caption = "Found " & TotalPicFiles & " pictures total"
End Sub

Private Sub dirFiles_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyReturn Then
        With dirFiles
            .Path = .List(.ListIndex)
        End With
    End If
End Sub

Private Sub drvFiles_Change()
    On Error GoTo DriveNotReady
    dirFiles.Path = UCase$(drvFiles.Drive)
    Exit Sub
DriveNotReady:
    On Error GoTo WhoCaresIfDriveIsntReady
    MsgBox "Drive " & drvFiles.Drive & " not ready"
    drvFiles.Drive = dirFiles.Path
WhoCaresIfDriveIsntReady:
End Sub

Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyEscape Then Unload Me
End Sub

Private Sub Form_Load()
    KeepProportional = True
    PicPath = FixPath(CurDir$)
    PicDuration = DefaultPicDuration
    txtPicDuration.Text = PicDuration \ 1000
    Set PicControl = imgPicture
    Show
    DoEvents
    ReadFolder
    PicIndex = lstFiles.ListIndex
    If Len(Command) Then LoadPic Command
End Sub

Private Sub Form_Resize()
    Dim FormHeight As Long, FormWidth As Long
    Dim ItemTop As Long, ItemLeft As Long
    Dim ItemHeight As Long, ItemWidth As Long
    'FormHeight = Height \ Screen.TwipsPerPixelY
    'FormWidth = Width \ Screen.TwipsPerPixelX
    FormHeight = ScaleHeight
    FormWidth = ScaleWidth

    ItemHeight = FormHeight - 181
    If ItemHeight < 17 Then
        ItemHeight = 17
    End If
    lstFiles.Height = ItemHeight

    ItemTop = ItemHeight + 162
    txtPicDuration.Top = ItemTop
    lblDuration.Top = ItemHeight + 165

    ItemHeight = FormHeight - 8
    If ItemHeight < 6 Then ItemHeight = 6
    ItemWidth = FormWidth - 136
    If ItemWidth < 6 Then ItemWidth = 6
    With picContainer
    .Width = ItemWidth
    .Height = ItemHeight
    End With
End Sub

Private Sub imgPicture_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    If Button And 1 Then
        ' get location of grab
        ' get top left of the image within the pic box
        ' get the pic box dimensions minus border
        ' hide mouse cursor
        GetCursorPos MousePos 'bypass IDIOTIC twips!
        GrabY = MousePos.Y
        GrabX = MousePos.X
        PicY = imgPicture.Top
        PicX = imgPicture.Left
        InnerHeight = picContainer.Height
        InnerWidth = picContainer.Width
        imgPicture.MousePointer = vbCustom
        lstFiles.SetFocus 'set focus while we're at it
    ElseIf Button And 2 Then
        mnuFullScreen_Click
    End If
End Sub

Private Sub imgPicture_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Static NoRecurse As Boolean
    If NoRecurse Then Exit Sub
    
    If Button And 1 Then
        NoRecurse = True
        GetCursorPos MousePos
        SetCursorPos GrabX, GrabY
        
        PicY = PicY + MousePos.Y - GrabY
        PicX = PicX + MousePos.X - GrabX
        If PicWidth <= InnerWidth Or PicX > 0 Then
            PicX = 0
        ElseIf PicX + PicWidth < InnerWidth Then
            PicX = InnerWidth - PicWidth
        End If
        If PicHeight <= InnerHeight Or PicY > 0 Then
            PicY = 0
        ElseIf PicY + PicHeight < InnerHeight Then
            PicY = InnerHeight - PicHeight
        End If
        imgPicture.Move PicX, PicY
        DoEvents
        NoRecurse = False
    End If
End Sub

Private Sub imgPicture_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
    imgPicture.MousePointer = vbSizeAll
End Sub

Private Sub lstFiles_Click()
    Dim FileName As String

    If KeyHoldCount > 1 Then ListClick = True: Exit Sub
    ListClick = False

    FileName = PicFiles(PicOrder(lstFiles.ListIndex))
    If PicFilename = FileName Then Caption = PicFilename ': Exit Sub
    Caption = "Loading " & FileName
    If LoadPic(FileName) Then
        Caption = PicFilename
        PicIndex = lstFiles.ListIndex
        imgPicture.Refresh 'force redraw now rather than wait for PAINT msg
    Else
        Caption = "Error opening " & FileName
    End If
End Sub

Private Sub lstFiles_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyReturn Then mnuFullScreen_Click
    KeyHoldCount = KeyHoldCount + 1
End Sub

Private Sub lstFiles_KeyUp(KeyCode As Integer, Shift As Integer)
    lstFiles_LostFocus
End Sub

Private Sub lstFiles_LostFocus()
    KeyHoldCount = 0
    If ListClick Then lstFiles_Click
End Sub

Private Sub lstFiles_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    KeyHoldCount = 0
End Sub

Private Sub mnuAbout_Click()
    MsgBox "It all started with my grandma's trip to Turkey..." & vbNewLine & vbNewLine _
         & "She came back with a ton of pictures, scanned them all in (368 pics), " _
         & "then wanted to transfer them onto videotape. There no were programs " _
         & "to display a 'slideshow' to the VCR. Well, there was PowerPoint, but " _
         & "creating nearly 400 slides to make a bloated presentation that would only be used once " _
         & "seemed rather stupid. So, instead I used those countless hours to write this program." & vbNewLine _
         & vbNewLine & "Supports filetypes: BMP,GIF,JPG,ICO,CUR,WMF" & vbNewLine _
         & vbNewLine _
         & "List view:" & vbNewLine _
         & vbTab & "Pan - left drag image" & vbNewLine _
         & vbTab & "Enter full screen - Enter / right click on image" & vbNewLine _
         & vbNewLine _
         & "Full screen:" & vbNewLine _
         & vbTab & "Next picture - Down / Left click" & vbNewLine _
         & vbTab & "Previous picture - Up / Middle click / Shift+Left click" & vbNewLine _
         & vbTab & "Exit full screen - Enter / Esc / Right click" & vbNewLine _
         & vbTab & "Start/stop slide - Space" & vbNewLine _
         & vbTab & "Full speed ahead - Z" & vbNewLine, _
            vbQuestion, "About"
End Sub

Private Sub mnuCredits_Click()
    Do While MsgBox("PeekinSoft creation" & vbNewLine & "Dwayne Robinson" & vbNewLine & "2002-01-23", vbAbortRetryIgnore Or vbInformation, "Slideshower 1.0 Credits") = vbRetry: Loop
End Sub

Private Sub mnuClose_Click()
    Unload Me
End Sub

Private Sub mnuFile_Click()
    mnuRename.Enabled = Len(PicFilename)
End Sub

Private Sub mnuFitImage_Click()
    ScalePic = Not mnuFitImage.Checked
    mnuFitImage.Checked = ScalePic
End Sub

Private Sub mnuFullScreen_Click()
    frmFullScreen.Show vbModal
    If PicIndex >= 0 Then If PicIndex < lstFiles.ListCount Then lstFiles.ListIndex = PicIndex
End Sub

Private Sub mnuGotoPath_Click()
    frmGotoPath.Show
End Sub

Private Sub mnuKeepProportional_Click()
    KeepProportional = Not mnuKeepProportional.Checked
    mnuKeepProportional.Checked = KeepProportional
End Sub

Private Sub mnuLoopAtEnd_Click()
    LoopAtEnd = Not mnuLoopAtEnd.Checked
    mnuLoopAtEnd.Checked = LoopAtEnd
End Sub

Private Sub mnuOpen_Click()
    With OFN
        If Len(PicFilename) Then
            OfnFilename = PicFilename & vbNullChar
            .sInitialDir = vbNullChar
        Else
            OfnFilename = vbNullChar
            .sInitialDir = dirFiles.Path & vbNullChar
        End If
        .hWndOwner = Me.hWnd
        .sFile = OfnFilename
        .nMaxFile = Len(OfnFilename)
        .sDialogTitle = "Open picture" & vbNullChar

        If GetOpenFileName(OFN) Then
            PicPath = Left$(.sFile, .nFileOffset)
            dirFiles.Path = PicPath
            drvFiles.Drive = PicPath
            PicFilename = Left$(.sFile, InStr(.sFile, vbNullChar) - 1)
            KeyHoldCount = 0
            SelectMatchingFile
            lstFiles.SetFocus
        End If
    End With
End Sub

Private Sub mnuOpenList_Click()
    ReadFileList
    lstFiles.SetFocus
End Sub

Private Sub mnuRecurse_Click()
    RecurseFolder
    SelectMatchingFile
End Sub

Private Sub mnuRefresh_Click()
    ReadFolder
    SelectMatchingFile
End Sub

Private Sub mnuRename_Click()
    frmRenameFile.Show
End Sub

Private Sub mnuShowFileTitle_Click()
    ShowFileTitle = Not mnuShowFileTitle.Checked
    mnuShowFileTitle.Checked = ShowFileTitle
End Sub

Private Sub mnuShowFullPath_Click()
    ShowFullPath = Not mnuShowFullPath.Checked
    mnuShowFullPath.Checked = ShowFullPath
End Sub

Private Sub mnuSlideShow_Click()
    frmFullScreen.StartSlideShow
    mnuFullScreen_Click
End Sub

Private Sub mnuSortByName_Click()
    Dim Checked As Boolean
    Checked = mnuSortByName.Checked
    mnuSortByName.Checked = Not Checked
    mnuRefresh_Click
End Sub

Private Sub txtPicDuration_Change()
    PicDuration = Left$(Val(txtPicDuration), 3) * 1000
    If PicDuration <= MinPicDuration Then PicDuration = MinPicDuration
End Sub

Private Sub txtPicDuration_GotFocus()
    txtPicDuration.SelStart = 0
    txtPicDuration.SelLength = 32767
End Sub

Private Sub txtPicDuration_KeyDown(KeyCode As Integer, Shift As Integer)
    If KeyCode = vbKeyReturn Then mnuFullScreen_Click
End Sub

Public Sub SelectMatchingFile()
    Dim Count As Long
    PicIndex = 0
    For Count = 0 To TotalPicFiles - 1
        If PicFiles(PicOrder(Count)) = PicFilename Then
            PicIndex = Count
            lstFiles.ListIndex = Count
            Exit For
        End If
    Next
End Sub
