'File Sizes
'Dwayne Robinson
'2001.3.22
'
'Scans all the folders and files on a disk, accumulating each's size, and
'displays the size and count information in a list. Bar charts are used to
'indicate each file's file relative to the total.
'
'The list can be sorted (name/size) and displayed with either all
'folders/files in a long list or in heirarchical tree.
'
'Works with both stupidly short 8.3 DOS names and long Win95+ filenames.
'
' test if long filenames are available by checking function's return code
' get allocation unit size
' read all files...
' set current path, starting at root folder
' (read first)
' read first entry (include hidden and system files too)
' if no files in folder goto no more files
' increment file count
' do
'   skip if . or ..
'   add name and information to list
'   if entry is folder
'     save current folder info, total size and file count
'     save folder DTA or handle
'     zero child folder's total size and file count
'     set current path
'     goto read first
'   endif
'   add file size to folder total
'   increment file count
'   increment folder's file count
'   (read next)
'   read next
'   if no more files in folder
'     (no more files)
'     set folder's final total size and file count
'     add child folder's totals to parent's
'     restore parent folder DTA or handle
'     set current path
'     goto read next
'   endif
' loop

DEFINT A-Z
DECLARE SUB CheckLongFilenames ()
DECLARE SUB StatusLine (Text AS STRING)
DECLARE FUNCTION GetDrive% ()
DECLARE SUB SetDta ()

CONST MaxFiles = 10000, MaxPathNesting = 20, FileNameBfrSize = 60000
CONST MaxPathChars = 260
CONST FileAtrOpen = 256, FileAtrSelected = 512, FileAtrVisible = 2048
CONST FileAtrUnsorted = 2048
CONST FileListRows = 47', IncludeFiles = 16

TYPE DtaType
Filler   AS STRING * 13
Handle   AS INTEGER
Filler2  AS STRING * 6
FileAtrb AS STRING * 1
FileTime AS INTEGER
FileDate AS INTEGER
FileSize AS LONG
FileName AS STRING * 13
END TYPE

TYPE WinDtaType
FileAtrb AS STRING * 1
Filler AS STRING * 31
FileSize AS LONG
Filler2 AS STRING * 8
FileName AS STRING * 276
END TYPE

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Fl AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

DIM SHARED LongFileNames
DIM Path AS STRING * 260, DrivePath AS STRING, FilePath AS STRING
DIM SHARED Regs AS RegType, DTA AS DtaType, WinDTA AS WinDtaType
DIM DirDTAs(MaxPathNesting) AS DtaType  'saved DTA's of parent folders
DIM DirIdxs(MaxPathNesting)             'list indexes of saved parent folders
DIM DirSizes(MaxPathNesting) AS LONG    'filesize in bytes
DIM DirAuSizes(MaxPathNesting) AS LONG  'actual bytes used, allocation units size
DIM DirCounts(MaxPathNesting)           'number of files in a folder (obviously only applies to folders)
DIM FileNames(MaxFiles - 1) AS LONG     'ptr to text filename
DIM FileParents(MaxFiles - 1)           'containing folder, or -1 if root
DIM FileDepths(MaxFiles - 1)            'depth of folder
DIM FileAtrs(MaxFiles - 1)              'attributes
DIM FileSizes(MaxFiles - 1) AS LONG     'filesize in bytes
DIM FileAuSizes(MaxFiles - 1) AS LONG   'actual bytes used, allocation units size
DIM FileCounts(MaxFiles - 1)            'number of files in a folder (obviously only applies to folders)
DIM FileList(MaxFiles - 1)              'index of each visible file in the list
DIM FileSorted(MaxFiles - 1)            'sorted indexes of each file
DIM FileNameBfr(FileNameBfrSize \ 2 - 1)
DIM FileSize AS LONG, FileAuSize AS LONG
DIM FolderSize AS LONG, FolderAuSize AS LONG
DIM BfrOfs AS LONG, SrcOfs AS LONG
DIM VisibleFileSize AS LONG, VisibleFileAuSize AS LONG
DIM Size AS LONG, SizeScale AS LONG, VisibleSizeTotal AS LONG


WIDTH 80, 50
VIEW PRINT 1 TO 50

' get current drive, its allocation unit size, & total size
Drive = GetDrive
DrivePath = CHR$(Drive + 65) + ":\"
SetDta
DiskAuMask = 16383

GOSUB StartTreeScan

GOSUB SortList
GOSUB RebuildList
FileIdx = 0 'size relative to root
GOSUB RescaleBars

StatusLine "Read" + STR$(TotalFiles) + " files/folders"
GOSUB FlagFullRedraw
DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE CHR$(27): EXIT DO
    CASE " " 'tag current file/folder
    CASE CHR$(0) + "H" 'previous file
        IF FileListChc > 0 THEN
            FileChc = FileListChc - 1
            GOSUB SetFileListChc
        END IF
    CASE CHR$(0) + "P" 'next file
        IF FileListChc < VisibleFiles - 1 THEN
            FileChc = FileListChc + 1
            GOSUB SetFileListChc
        END IF
    CASE CHR$(0) + "K" 'set choice to parent
        FileIdx = FileParents(FileListIdx)
        GOSUB SeekFileListIdx
    CASE CHR$(0) + "M", "\"'set choice first entry under parent, open if necessary
        FileIdx = FileListIdx
        GOSUB ExpandFolder
        FileStart = 0: FileEnd = VisibleFiles - 1: FileChc = 1
        FileParent = FileListIdx
        GOSUB SeekFileListSiblingIn
    CASE CHR$(0) + "t" 'last sibling
        FileChc = 1
        GOSUB SeekFileListNext
    CASE CHR$(0) + "s" 'next sibling
        FileChc = -1
        GOSUB SeekFileListNext
    CASE CHR$(0) + "G" 'to first sibling
        FileChc = 1
        GOSUB SeekFileListEnd
    CASE CHR$(0) + "O" 'to last sibling
        FileChc = -1
        GOSUB SeekFileListEnd
    CASE CHR$(0) + "I" 'page up
        IF FileListBase > 0 THEN
            FileChc = FileListBase - FileListRows
            GOSUB SetFileListBase
        END IF
    CASE CHR$(0) + "Q" 'page down
        IF FileListBase < VisibleFiles - FileListRows THEN
            FileChc = FileListBase + FileListRows
            GOSUB SetFileListBase
        END IF
    CASE CHR$(0) + "w" 'to first entry in list
        FileChc = 0
        GOSUB SetFileListChc
    CASE CHR$(0) + "u" 'to last entry in list
        FileChc = VisibleFiles - 1
        GOSUB SetFileListChc
    CASE CHR$(0) + "S" 'delete selected files
    CASE CHR$(8) 'collapse parent folder
        FileListParent = FileParents(FileListIdx)
        IF FileAtrs(FileListParent) AND FileAtrOpen THEN
            FileAtrs(FileListParent) = FileAtrs(FileListParent) AND NOT FileAtrOpen
            GOSUB RebuildList
            'set current folder to parent that was closed
            FileIdx = FileListParent
            GOSUB SeekFileListIdx
            GOSUB FlagFullRedraw
        END IF
    CASE CHR$(9)
        FileBarMode = (FileBarMode + 1) MOD 3
        GOSUB FlagFullRedraw
    CASE CHR$(0) + CHR$(20)
        FileListTree = FileListTree XOR -1
        GOSUB RebuildList
        GOSUB FlagFullRedraw
    CASE CHR$(0) + "<"
        GOSUB SaveFileList
    CASE CHR$(13), "\" 'set bars relative to current folder/file
        FileIdx = FileListIdx
        GOSUB ExpandFolder
        FileIdx = FileListIdx
        GOSUB RescaleBars
        GOSUB FlagFullRedraw
    CASE "*", "/"
        FileIdx = FileListIdx
        IF Key$ = "*" THEN FileAtrb = FileAtrOpen ELSE FileAtrb = 0
        GOSUB ExpandCollapseBranch
        GOSUB RebuildList
        GOSUB FlagFullRedraw
    CASE " " TO "~"
        'if file currently selected matches keypress, do not move
        DEF SEG = VARSEG(FileNameBfr(0))
        FileParent = FileParents(FileListIdx)
        IF FileListChc <> FileListSrch THEN FileListSrch = FileListChc: SrchLen = 0
        FileChc = FileListChc
        Char = ASC(Key$)
ReseekFileName:
        DO
            FileIdx = FileList(FileChc)
            IF FileParents(FileIdx) = FileParent THEN
                SrcOfs = FileNames(FileIdx)
                IF PEEK(SrcOfs + SrchLen) = Char OR PEEK(SrcOfs + SrchLen) = (Char XOR 32) THEN
                    FOR Count = 0 TO SrchLen - 1
                        IF PEEK(SrcOfs + Count) = 0 THEN EXIT FOR
                    NEXT
                    IF Count >= SrchLen THEN
                        GOSUB SetFileListChc
                        FileListSrch = FileListChc
                        SrchLen = SrchLen + 1
                        EXIT DO
                    END IF
                END IF
            END IF
            FileChc = FileChc + 1
        LOOP UNTIL FileChc >= VisibleFiles
        IF FileChc >= VisibleFiles THEN IF SrchLen > 0 THEN SrchLen = 0: FileChc = 0: GOTO ReseekFileName
    END SELECT

    IF RedrawCount > 0 THEN
        FileChc = FileChcRedraw + FileListBase
        GOSUB FileListPrint
        FileChcRedraw = FileChcRedraw + FileChcInc
        RedrawCount = RedrawCount - 1
    END IF
    IF Redraw THEN
        IF Redraw AND 1 THEN
            FileChc = FileListOldChc
            GOSUB FileListPrint
            FileChc = FileListChc
            GOSUB FileListPrint
        END IF
        IF Redraw AND 2 THEN
            FileIdx = FileList(FileListChc)
            GOSUB GetFilePath
            COLOR 11, 0
            IF VisibleSizeTotal > 0 THEN Size = INT(CDBL(FileSizes(FileIdx)) * 100 / VisibleSizeTotal) ELSE Size = 0
            LOCATE 48, 1: PRINT "File:" + STR$(FileIdx) + " Size:" + STR$(FileSizes(FileIdx)) + " AuSize:" + STR$(FileAuSizes(FileIdx)) + " Files:" + STR$(FileCounts(FileIdx)) + STR$(Size) + "%"; TAB(80);
            LOCATE 49, 1: COLOR 11, 0: PRINT LEFT$(FilePath, 79); TAB(80);
        END IF
        FileListOldChc = FileListChc
        Redraw = 0
    END IF
LOOP

WIDTH 80, 25
END

GetPathMask:
'used in the file scan to build a filemask for the current path
    Path = DrivePath
    CharPos = LEN(DrivePath) + 1
    FOR Count = 0 TO PathNesting - 1
        SrcOfs = FileNames(DirIdxs(Count))
        DO UNTIL CharPos >= MaxPathChars
            Char = PEEK(SrcOfs)
            IF Char = 0 THEN Char = 92 'replace nul with backslash
            MID$(Path, CharPos, 1) = CHR$(Char)
            CharPos = CharPos + 1
            IF Char = 92 THEN EXIT DO
            SrcOfs = SrcOfs + 1
        LOOP
    NEXT
    MID$(Path, CharPos, 4) = "*.*" + CHR$(0)
RETURN

StartTreeScan:
    ' read all files, starting at root folder
    FolderSize = 0
    FolderFiles = 0
    PathNesting = 0
    TotalFiles = 1                  'count root as first 'file'
    FileAtrs(0) = 16 OR FileAtrOpen 'mark root as a folder and open
    FileParents(0) = 0              'root actually has no parent
    FileDepths(0) = -1
    DirIdx = 0                      'all files in the root have parent 0
   
    DEF SEG = VARSEG(FileNameBfr(0))
    BfrOfs = VARPTR(FileNameBfr(0))
    FileNames(0) = BfrOfs 'set root name to null
    FileNameBfr(BfrOfs) = 0
    BfrOfs = BfrOfs + 1

    StatusLine "Scanning disk folder tree... (press Esc to abort)"

    GOSUB GetPathMask
ReadFirstFile:
    IF LongFileNames THEN
        Regs.Ax = &H714E
        Regs.Es = VARSEG(WinDTA)
        Regs.Di = VARPTR(WinDTA)
        Regs.Si = 0
        Regs.Fl = 0
    ELSE
        Regs.Ax = &H4E00
    END IF
    Regs.Cx = 55    'include hidden & system
    Regs.Dx = VARPTR(Path)
    Regs.Ds = VARSEG(Path)
    CALL InterruptX(&H21, Regs, Regs)

    IF Regs.Fl AND 1 GOTO NoMoreFiles
    DirHandle = Regs.Ax

    DO
        'add file name and other information to list
        IF TotalFiles >= MaxFiles GOTO NoMoreFiles
        FileNames(TotalFiles) = BfrOfs
        IF LongFileNames THEN
            PRINT DirHandle; TotalFiles; LEFT$(WinDTA.FileName, 60)
            IF LEFT$(WinDTA.FileName, 1) = "." THEN GOTO ReadNextFile
            'copy file information, including name and size
            FileSize = WinDTA.FileSize
            FileAuSize = (FileSize + DiskAuMask) AND NOT DiskAuMask
            FileAtrb = ASC(WinDTA.FileAtrb)
            'IF (FileAtrb AND 16) = IncludeFiles THEN GOTO IgnoreFiles
            CharPos = 1
            DO UNTIL BfrOfs >= FileNameBfrSize
                Char = ASC(MID$(WinDTA.FileName, CharPos, 1))
                DEF SEG = VARSEG(FileNameBfr(0))
                POKE BfrOfs, Char
                CharPos = CharPos + 1
                BfrOfs = BfrOfs + 1
                IF Char = 0 THEN EXIT DO
            LOOP
        ELSE
            'skip entry if parent or current directory pointers ("." or "..")
            IF LEFT$(DTA.FileName, 1) = "." GOTO ReadNextFile

            'copy file information, including name and size
            FileSize = DTA.FileSize
            FileAuSize = (FileSize + DiskAuMask) AND NOT DiskAuMask
            FileAtrb = ASC(DTA.FileAtrb)
            'IF (FileAtrb AND 16) = IncludeFiles THEN GOTO IgnoreFiles
            CharPos = 1
            DO UNTIL BfrOfs >= FileNameBfrSize
                Char = ASC(MID$(DTA.FileName, CharPos, 1))
                DEF SEG = VARSEG(FileNameBfr(0))
                POKE BfrOfs, Char
                CharPos = CharPos + 1
                BfrOfs = BfrOfs + 1
                IF Char = 0 THEN EXIT DO
            LOOP
        END IF
        FileSizes(TotalFiles) = FileSize
        FileAuSizes(TotalFiles) = FileAuSize
        FileParents(TotalFiles) = DirIdx
        FileDepths(TotalFiles) = PathNesting
        FileAtrs(TotalFiles) = FileAtrb
        TotalFiles = TotalFiles + 1

        'go deeper into tree if folder
        IF FileAtrb AND 16 THEN
            IF PathNesting >= MaxPathNesting GOTO ReadNextFile

            ' save current folder info, DTA, handle, total size, file count...
            IF LongFileNames THEN
                DirDTAs(PathNesting).Handle = DirHandle
            ELSE
                DirDTAs(PathNesting) = DTA
            END IF
            DirSizes(PathNesting) = FolderSize
            DirAuSizes(PathNesting) = FolderAuSize
            DirCounts(PathNesting) = FolderFiles

            ' set current path to child
            DirIdx = TotalFiles - 1
            DirIdxs(PathNesting) = DirIdx
            PathNesting = PathNesting + 1
            GOSUB GetPathMask
            'COLOR 15: PRINT LEFT$(Path, 79)
            'COLOR 7

            ' zero child folder's total size and file count
            FolderSize = 0
            FolderAuSize = 0
            FolderFiles = 0
            GOTO ReadFirstFile
        END IF

IgnoreFiles:
        FolderSize = FolderSize + FileSize
        FolderAuSize = FolderAuSize + FileAuSize
        FolderFiles = FolderFiles + 1

        UserCheck = UserCheck + 1
        IF UserCheck > 50 THEN
            IF INKEY$ = CHR$(27) THEN
                GOSUB EndTreeScan
                EXIT DO
            END IF
            COLOR 11
            LOCATE 49, 1: PRINT LEFT$(Path, 68); TAB(69); TotalFiles; "files";
            COLOR 7
            UserCheck = 0
        END IF

ReadNextFile:
        IF LongFileNames THEN
            Regs.Ax = &H714F
            Regs.Bx = DirHandle
            Regs.Es = VARSEG(WinDTA)
            Regs.Di = VARPTR(WinDTA)
            Regs.Si = 0
            Regs.Fl = 0
        ELSE
            Regs.Ax = &H4F00
        END IF
        Regs.Dx = VARPTR(Path)
        Regs.Ds = VARSEG(Path)
        CALL InterruptX(&H21, Regs, Regs)

        IF Regs.Fl AND 1 THEN 'no more files in folder
NoMoreFiles:
            IF LongFileNames THEN
                'free folder handle
                Regs.Ax = &H71A1
                Regs.Bx = DirHandle
                CALL InterruptX(&H21, Regs, Regs)
            END IF

            ' set folder's final total size and file count
            FileCounts(DirIdx) = FolderFiles
            FileSizes(DirIdx) = FolderSize
            FileAuSizes(DirIdx) = FolderAuSize
            'COLOR 15: PRINT FolderFiles; FolderSize
            'PRINT #1, RIGHT$("      " + STR$(FolderSize), 8) + " " + RTRIM$(Path)

            IF PathNesting <= 0 THEN EXIT DO

            PathNesting = PathNesting - 1
            ' restore parent folder DTA or handle
            IF LongFileNames THEN
                DirHandle = DirDTAs(PathNesting).Handle
            ELSE
                DTA = DirDTAs(PathNesting)
            END IF
            ' add child folder's totals to parent's
            FolderFiles = FolderFiles + DirCounts(PathNesting)
            FolderSize = FolderSize + DirSizes(PathNesting)
            FolderAuSize = FolderAuSize + DirAuSizes(PathNesting)

            ' set current path back to parent
            DirIdx = FileParents(DirIdx)
            GOSUB GetPathMask
            'PRINT LEFT$(Path, 79): COLOR 7

            GOTO ReadNextFile
        END IF
        'PRINT DTA.FileName
    LOOP
    StatusLine "List read"
RETURN

EndTreeScan:
'used in the file scan if the scan ends prematurely because the user aborted
'or the arrays were filled.
    DO
        IF LongFileNames THEN
            'free folder handle
            Regs.Ax = &H71A1
            Regs.Bx = DirHandle
            CALL InterruptX(&H21, Regs, Regs)
        END IF

        ' set folder's final total size and file count
        FileCounts(DirIdx) = FolderFiles
        FileSizes(DirIdx) = FolderSize
        FileAuSizes(DirIdx) = FolderAuSize
        'COLOR 15: PRINT FolderFiles; FolderSize

        IF PathNesting <= 0 THEN EXIT DO

        PathNesting = PathNesting - 1
        ' restore parent folder handle
        IF LongFileNames THEN DirHandle = DirDTAs(PathNesting).Handle
        ' add child folder's totals to parent's
        FolderFiles = FolderFiles + DirCounts(PathNesting)
        FolderSize = FolderSize + DirSizes(PathNesting)
        FolderAuSize = FolderAuSize + DirAuSizes(PathNesting)

        ' set current path back to parent
        DirIdx = FileParents(DirIdx)
    LOOP
RETURN

GetFilePath:
'builds the full path of the current file
'do not call during the file scan
'(FileIdx)
'(FilePath)
    PathNesting = FileDepths(FileIdx)

    ' trace back all of file's/folder's parents
    DirIdx = FileIdx
    FOR Count = PathNesting - 1 TO 0 STEP -1
        DirIdx = FileParents(DirIdx)
        DirIdxs(Count) = DirIdx
    NEXT

    ' build full path, folder by folder, followed by filename/folder
    Path = DrivePath
    DEF SEG = VARSEG(FileNameBfr(0))
    CharPos = LEN(DrivePath) + 1
    FOR Count = 0 TO PathNesting
        IF Count >= PathNesting THEN
            SrcOfs = FileNames(FileIdx)
        ELSE
            SrcOfs = FileNames(DirIdxs(Count))
        END IF
        DO UNTIL CharPos >= MaxPathChars
            Char = PEEK(SrcOfs)
            IF Char = 0 THEN 'replace nul with backslash
                IF Count < PathNesting THEN Char = 92 ELSE EXIT DO
            END IF
            MID$(Path, CharPos, 1) = CHR$(Char)
            CharPos = CharPos + 1
            IF Char = 92 THEN EXIT DO
            SrcOfs = SrcOfs + 1
        LOOP
    NEXT
    FilePath = LEFT$(Path, CharPos - 1)
RETURN

FlagFullRedraw:
    FileChcRedraw = 0
    FileChcInc = 1
    RedrawCount = FileListRows
    Redraw = 2
RETURN

GetFileListLine:
'returns a single line of text information for a file/folder, including name,
'size, contained files, and a horizontal bar representing one of those values.
'(FileIdx)

    Text$ = SPACE$(79)
    FileAtrb = FileAtrs(FileIdx)

    'get file name
    IF FileDepths(FileIdx) < 0 THEN
        MID$(Text$, 1) = "(" + DrivePath + ")"
    ELSE
        DEF SEG = VARSEG(FileNameBfr(0))
        SrcOfs = FileNames(FileIdx)
        CharPos = 1

        DO UNTIL CharPos >= MaxPathChars
            Char = PEEK(SrcOfs)
            IF Char = 0 THEN 'replace nul with backslash
                IF FileAtrb AND 16 THEN Char = 92 ELSE EXIT DO
            END IF
            MID$(Path, CharPos, 1) = CHR$(Char)
            CharPos = CharPos + 1
            IF Char = 92 THEN EXIT DO
            SrcOfs = SrcOfs + 1
        LOOP
        MID$(Text$, 1, 21) = SPACE$(FileDepths(FileIdx)) + LEFT$(Path, CharPos - 1)
    END IF
   
    'print file info
    MID$(Text$, 22) = RIGHT$("         " + STR$(FileSizes(FileIdx)), 10)
    IF FileAtrb AND 16 THEN MID$(Text$, 32) = RIGHT$("    " + STR$(FileCounts(FileIdx)), 6)

    'print horizontal size bar
    SELECT CASE FileBarMode
    CASE 0: Size = FileSizes(FileIdx):   SizeScale = VisibleFileSize
    CASE 1: Size = FileAuSizes(FileIdx): SizeScale = VisibleFileAuSize
    CASE 2: Size = FileCounts(FileIdx):  SizeScale = VisibleFileCount
    END SELECT
    Size = INT(CDBL(Size) * 40 / SizeScale)
    IF Size < 1 THEN Size = 1 ELSE IF Size > 40 THEN Size = 40
    MID$(Text$, 39) = STRING$(Size, 220)
RETURN

FileListPrint:
'prints a single line of the file list
'(FileChc)
    IF FileChc < FileListBase THEN RETURN
    IF FileChc >= FileListBase + FileListRows THEN RETURN

    LOCATE FileChc - FileListBase + 1, 1
    IF FileChc >= VisibleFiles THEN 'just print blank line
        COLOR 7, 0
        PRINT TAB(80);
        RETURN
    END IF

    FileIdx = FileList(FileChc)
    GOSUB GetFileListLine
    'FileAtrb = FileAtrs(FileIdx)

    'print file info
    IF FileChc = FileListChc THEN
        COLOR 15, 1
    ELSE
        IF FileAtrs(FileIdx) AND FileAtrSelected THEN ForeColor = 15 ELSE ForeColor = 7
        COLOR ForeColor, 0
    END IF
    
    PRINT LEFT$(Text$, 38);

    'print horizontal size bar
    IF FileChc = FileListChc THEN
        COLOR 10
    ELSE
        SELECT CASE FileBarMode
        CASE 0: COLOR 9
        CASE 1: COLOR 12
        CASE 2: COLOR 14
        END SELECT
    END IF
    PRINT MID$(Text$, 39);
RETURN

SetFileListChc:
    IF FileListChc = FileChc OR FileChc < 0 THEN RETURN
    FileListChc = FileChc
    IF FileChc < FileListBase THEN
        FileListBase = FileListChc
        FileChcRedraw = 0'FileListChc
        FileChcInc = 1
        RedrawCount = FileListRows
    ELSEIF FileChc >= FileListBase + FileListRows THEN
        FileListBase = FileListChc - FileListRows + 1
        FileChcRedraw = FileListRows - 1'FileListChc
        FileChcInc = -1
        RedrawCount = FileListRows
    END IF
    Redraw = 3
    FileListIdx = FileList(FileListChc)
RETURN

SetFileListBase:
    IF FileChc >= VisibleFiles - FileListRows THEN FileChc = VisibleFiles - FileListRows
    IF FileChc < 0 THEN FileChc = 0
    FileListChc = FileListChc - FileListBase
    IF FileChc < FileListBase THEN
        FileListBase = FileChc
        FileChcRedraw = 0'FileListBase
        FileChcInc = 1
        RedrawCount = FileListRows
    ELSEIF FileChc > FileListBase THEN
        FileListBase = FileChc
        FileChcRedraw = FileListRows - 1
        FileChcInc = -1
        RedrawCount = FileListRows
    END IF
    Redraw = 3
    FileListChc = FileListChc + FileListBase
    FileListIdx = FileList(FileListChc)
RETURN

SeekFileListNext:
' Seeks the next or previous sibling
' (FileChc)     1 if forward, -1 if backward
    IF FileChc > 0 THEN FileEnd = VisibleFiles - 1 ELSE FileEnd = 0
    FileStart = FileListChc + FileChc

SeekFileListSibling:
    FileParent = FileParents(FileListIdx)
SeekFileListSiblingIn:
' (FileParent, FileStart, FileEnd)
    FOR FileChc = FileStart TO FileEnd STEP FileChc
        FileIdx = FileList(FileChc)
        IF FileParents(FileIdx) = FileParent THEN
            GOSUB SetFileListChc
            EXIT FOR
        END IF
    NEXT
RETURN

SeekFileListEnd:
'Seeks the first or last sibling
'(FileChc)     1 if first, -1 if last
    IF FileChc > 0 THEN FileStart = 0 ELSE FileStart = VisibleFiles - 1
    FileEnd = FileListChc - FileChc
GOTO SeekFileListSibling

SeekFileListIdx:
'Seeks a specific file/folder in list. Seeks backward rather than forward
'because the most common reason this function is called is to retreat to the
'parent entry.
' (FileIdx)
    FOR FileChc = VisibleFiles - 1 TO 0 STEP -1
        IF FileList(FileChc) = FileIdx THEN
            GOSUB SetFileListChc
            EXIT FOR
        END IF
    NEXT
RETURN

SortList2:
'Sorts by name/size/ausize/file count using slow linear sort
    StatusLine "Sorting list..."

    FOR Count = 0 TO TotalFiles - 1
        FileAtrs(Count) = FileAtrs(Count) OR FileAtrUnsorted
    NEXT
    SortDepth = 0
    FOR SortCount = 0 TO TotalFiles - 1
        IF SortDepth > 0 THEN
            'grab previous lowest find again
            FileIdx = FileSorted(MaxFiles - SortDepth)
            SortDepth = SortDepth - 1
        ELSE
            'no previous find on stack, so start from front
            FOR FileIdx = 0 TO TotalFiles - 1
                IF FileAtrs(FileIdx) AND FileAtrUnsorted THEN EXIT FOR
            NEXT
        END IF
        FOR CmpFile = FileIdx + 1 TO TotalFiles - 1
            IF FileAtrs(CmpFile) AND FileAtrUnsorted THEN
                GOSUB SortComparison
                IF SortResult THEN
                    'save previous lowest find
                    SortDepth = SortDepth + 1
                    FileSorted(MaxFiles - SortDepth) = FileIdx
                    'substitute with new lowest find
                    FileIdx = CmpFile
                END IF
            END IF
        NEXT
        FileSorted(SortCount) = FileIdx
        FileAtrs(FileIdx) = FileAtrs(FileIdx) XOR FileAtrUnsorted
    NEXT

    StatusLine "List sorted"
RETURN

SortList:
   'merge
   '1 6 2 5 4 7 8 10 9 3 (original)
   '1 6 10 5 4 7 8 2 9 3 (odd/even swap)
   '1 6.5 10.4 7.2 8.3 9
   '1 5 6 10.2 4 7 8.3 9
   '1 2 4 5 6 7 8 10.3 9
   '1 2 3 4 5 6 7 8 9 10

   '1 2 4 5 6 7 8 10.3 9

   'if total file count is odd, set final file
   IF TotalFiles AND 1 THEN FileSorted(TotalFiles - 1) = TotalFiles - 1
   'swap every file that is greater with its adjacent entry
   FOR FileIdx = 0 TO TotalFiles - 2 STEP 2
      CmpFile = FileIdx + 1
      GOSUB SortComparison
      IF SortResult THEN
         FileSorted(FileIdx) = CmpFile
         FileSorted(FileIdx + 1) = FileIdx
      ELSE
         FileSorted(FileIdx) = FileIdx
         FileSorted(FileIdx + 1) = CmpFile
      END IF
   NEXT
   SortStep = 2
   DO UNTIL SortStep >= TotalFiles
      FOR SortBase = 0 TO TotalFiles - 1 STEP SortStep * 2
         LeftIdx = SortBase
         LeftEnd = LeftIdx + SortStep
         RightIdx = LeftEnd
         RightEnd = RightIdx + SortStep
         StackPtr = SortBase
         IF RightIdx >= TotalFiles THEN EXIT FOR
         IF RightEnd > TotalFiles THEN RightEnd = TotalFiles
         Shift = RightEnd - LeftEnd
         DO
            FileIdx = FileSorted(LeftIdx)
            CmpFile = FileSorted(RightIdx)
            GOSUB SortComparison
            IF SortResult THEN 'right size is greater
               FileList(StackPtr) = CmpFile
               StackPtr = StackPtr + 1
               RightIdx = RightIdx + 1
               IF RightIdx >= RightEnd THEN
                  'copy remaining left side,
                  'then transfer values saved on stack
                  FOR Count = LeftEnd - 1 TO LeftIdx STEP -1
                     FileSorted(Count + Shift) = FileSorted(Count)
                  NEXT
                  FOR Count = SortBase TO StackPtr - 1
                     FileSorted(Count) = FileList(Count)
                  NEXT
                  EXIT DO
               END IF
            ELSE 'left side greater
               FileList(StackPtr) = FileIdx
               StackPtr = StackPtr + 1
               LeftIdx = LeftIdx + 1
               IF LeftIdx >= LeftEnd THEN
                  'leave remaining right side right where it is,
                  'then transfer values saved on stack
                  FOR Count = SortBase TO StackPtr - 1
                     FileSorted(Count) = FileList(Count)
                  NEXT
                  EXIT DO
               END IF
            END IF
         LOOP
      NEXT
      StatusLine "Sorting list..." + STR$(SortStep * 200& \ TotalFiles) + "%"
      SortStep = SortStep * 2
   LOOP

   StatusLine "List sorted"
RETURN

SortComparison:
'compares two file list items and returns true if compare file is greater
    SELECT CASE SortMode
    CASE 0
        IF FileSizes(CmpFile) > FileSizes(FileIdx) THEN SortResult = -1 ELSE SortResult = 0
    CASE 1
    CASE 2
    CASE 3
    END SELECT
RETURN

PrintSorted:
   LOCATE 1, 1: PRINT "Sorting"; TotalFiles; "files, step ="; SortStep
   FOR Count = 0 TO 47
      IF Count >= TotalFiles THEN EXIT FOR
      IF (Count AND (SortStep - 1)) = 0 THEN COLOR 15 ELSE COLOR 9
      PRINT Count; TAB(10); FileSorted(Count); TAB(20); FileSizes(FileSorted(Count)); "    "
   NEXT
   DO: LOOP UNTIL LEN(INKEY$)
RETURN

RebuildList:
'this reformats the list after a folder is opened or closed
'depending on how the list should be displayed, it will either arrange them
'all into a single long list, or arrange them heirarchically.
    VisibleFiles = 0
    IF FileListTree THEN
        FileParent = 0
        PathNesting = 0
        Count = 0
RebuildListBranch:
        FOR Count = Count TO TotalFiles - 1
            FileIdx = FileSorted(Count)
            IF FileParents(FileIdx) = FileParent THEN
                FileList(VisibleFiles) = FileIdx
                VisibleFiles = VisibleFiles + 1
                IF (FileAtrs(FileIdx) AND (FileAtrOpen OR FileAtrFolder)) = (FileAtrOpen OR FileAtrFolder) THEN
                    'be sure this is not the root, to prevent infinite recursion
                    IF FileDepths(FileIdx) >= 0 THEN
                        DirIdxs(PathNesting) = Count
                        PathNesting = PathNesting + 1
                        FileParent = FileIdx
                        Count = 0
                        GOTO RebuildListBranch
                    END IF
                END IF
            END IF
        NEXT
        PathNesting = PathNesting - 1
        IF PathNesting >= 0 THEN
            Count = DirIdxs(PathNesting)
            FileParent = FileParents(FileSorted(Count))
            Count = Count + 1
            GOTO RebuildListBranch
        END IF
    ELSE
        'Root is always visible
        FileAtrs(0) = FileAtrs(0) OR FileAtrVisible OR FileAtrOpen
        'read sequentially through all the files marking each one as visible
        'or not visible. simply put, if my parent is both open and visible,
        'then I'm visible too.
        FOR Count = 1 TO TotalFiles - 1
            FileAtrb = FileAtrs(Count)
            IF (FileAtrs(FileParents(Count)) AND (FileAtrVisible OR FileAtrOpen)) = (FileAtrVisible OR FileAtrOpen) THEN
                FileAtrs(Count) = FileAtrb OR FileAtrVisible
            ELSE
                FileAtrs(Count) = FileAtrb AND NOT FileAtrVisible
            END IF
        NEXT
        FOR Count = 0 TO TotalFiles - 1
            FileIdx = FileSorted(Count)
            IF FileAtrs(FileIdx) AND FileAtrVisible THEN
                FileList(VisibleFiles) = FileIdx
                VisibleFiles = VisibleFiles + 1
            END IF
        NEXT
    END IF
RETURN

RescaleBars:
'Rescales horizontal bars to whatever file/folder should be used as the
'relative reference
'(FileIdx)
    VisibleSizeTotal = FileSizes(FileIdx)
    FileParent = FileIdx
    VisibleFileSize = 40
    VisibleFileAuSize = 40
    VisibleFileCount = 40
    FOR Count = 0 TO VisibleFiles - 1
        FileIdx = FileList(Count)
        IF FileParents(FileIdx) = FileParent AND FileDepths(FileIdx) >= 0 THEN
            IF FileSizes(FileIdx) > VisibleFileSize THEN VisibleFileSize = FileSizes(FileIdx)
            IF FileAuSizes(FileIdx) > VisibleFileAuSize THEN VisibleFileAuSize = FileAuSizes(FileIdx)
            IF FileCounts(FileIdx) > VisibleFileCount THEN VisibleFileCount = FileCounts(FileIdx)
        END IF
    NEXT
RETURN

ExpandFolder:
'Expands a single folder
'(FileIdx)
    IF (FileAtrs(FileIdx) AND FileAtrOpen) = 0 THEN
        FileAtrs(FileIdx) = FileAtrs(FileIdx) OR FileAtrOpen
        GOSUB RebuildList
        GOSUB FlagFullRedraw
    END IF
RETURN

ExpandCollapseBranch:
'Expands or collapse an entire branch, including every subfolder
'(FileIdx) branch to exand
'(FileAtrb) open or close
    PathNesting = FileDepths(FileIdx)
    FileAtrs(FileIdx) = (FileAtrs(FileIdx) AND NOT FileAtrOpen) OR FileAtrb
    FOR Count = FileIdx + 1 TO TotalFiles - 1
        IF FileDepths(Count) <= PathNesting THEN EXIT FOR
        FileAtrs(Count) = (FileAtrs(Count) AND NOT FileAtrOpen) OR FileAtrb
    NEXT
RETURN

SaveFileList:
    StatusLine "Saving list..."
    OPEN "filelist.tmp" FOR OUTPUT AS 1
    FOR Count = 0 TO VisibleFiles - 1
        FileIdx = FileList(Count)
        GOSUB GetFileListLine
        PRINT #1, RTRIM$(Text$)
    NEXT
    CLOSE 1
    StatusLine "List saved to 'filelist.tmp'"
RETURN

FUNCTION GetDrive

Regs.Ax = &H1900
CALL InterruptX(&H21, Regs, Regs)
GetDrive = Regs.Ax AND 255

END FUNCTION

SUB SetDta
'sets DTA to either DOS or Windows 95+ DTA. verifies long filename ability
'by trying to read a file (any file) on the root directory of the current
'drive

FileSpec$ = "\*" + CHR$(0)
Regs.Ax = &H714E    'find first
Regs.Es = -1
Regs.Di = VARPTR(WinDTA)
Regs.Si = 0
Regs.Fl = 1         'preset carry
Regs.Cx = 55        'allow all filetypes, exclude none
Regs.Dx = SADD(FileSpec$)
Regs.Ds = VARSEG(FileSpec$)
CALL InterruptX(&H21, Regs, Regs)

IF Regs.Fl AND 1 THEN
    LongFileNames = 0
    Regs.Ax = &H1A00            'Set DOS DTA function
    Regs.Dx = VARPTR(DTA)       'DS:DX points to our DTA
    Regs.Ds = VARSEG(DTA)
    CALL InterruptX(&H21, Regs, Regs)
ELSE
    PRINT Regs.Ax; WinDTA.FileName
    LongFileNames = -1
    Regs.Bx = Regs.Ax
    Regs.Ax = &H71A1            'free folder handle
    CALL InterruptX(&H21, Regs, Regs)
END IF

END SUB

SUB StatusLine (Text AS STRING)

LOCATE 50, 1: COLOR 11, 0: PRINT LEFT$(Text, 79); TAB(80);

END SUB

