Attribute VB_Name = "modSlideShower"
'2002-01-23 Added WMF,ICO,CUR filetypes to list
'           Increased file limit to 8000
'2002-01-07 Added rename and open
'2002-01-02 Started program
Option Explicit

Public Const OFN_ALLOWMULTISELECT As Long = &H200
Public Const OFN_CREATEPROMPT As Long = &H2000
'Public Const OFN_DONTADDTORECENT As Long = &H0?
Public Const OFN_ENABLEHOOK As Long = &H20
Public Const OFN_ENABLETEMPLATE As Long = &H40
Public Const OFN_ENABLETEMPLATEHANDLE As Long = &H80
Public Const OFN_EXPLORER As Long = &H80000
Public Const OFN_EXTENSIONDIFFERENT As Long = &H400
Public Const OFN_FILEMUSTEXIST As Long = &H1000
'Public Const OFN_FORCESHOWHIDDEN As Long = &H0?
Public Const OFN_HIDEREADONLY As Long = &H4
Public Const OFN_LONGNAMES As Long = &H200000
Public Const OFN_NOCHANGEDIR As Long = &H8
Public Const OFN_NODEREFERENCELINKS As Long = &H100000
Public Const OFN_NOLONGNAMES As Long = &H40000
Public Const OFN_NONETWORKBUTTON As Long = &H20000
Public Const OFN_NOREADONLYRETURN As Long = &H8000& 'see comments
Public Const OFN_NOTESTFILECREATE As Long = &H10000
Public Const OFN_NOVALIDATE As Long = &H100
Public Const OFN_OVERWRITEPROMPT As Long = &H2
Public Const OFN_PATHMUSTEXIST As Long = &H800
Public Const OFN_READONLY As Long = &H1
Public Const OFN_SHAREAWARE As Long = &H4000
Public Const OFN_SHAREFALLTHROUGH As Long = 2
Public Const OFN_SHAREWARN As Long = 0
Public Const OFN_SHARENOWARN As Long = 1
Public Const OFN_SHOWHELP As Long = &H10
Public Const OFS_MAXPATHNAME As Long = 260
Public Const MAX_PATH = 260
Public Const INVALID_HANDLE_VALUE = -1
Public Const FILE_ATTRIBUTE_DIRECTORY = &H10

Public Const VK_ESCAPE = &H1B

Public Type FILETIME
   dwLowDateTime As Long
   dwHighDateTime As Long
End Type

Public Type WIN32_FIND_DATA
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

Type POINT
X As Long
Y As Long
End Type

Public Type OPENFILENAME
  nStructSize    As Long
  hWndOwner      As Long
  hInstance      As Long
  sFilter        As String
  sCustomFilter  As String
  nMaxCustFilter As Long
  nFilterIndex   As Long
  sFile          As String
  nMaxFile       As Long
  sFileTitle     As String
  nMaxTitle      As Long
  sInitialDir    As String
  sDialogTitle   As String
  flags          As Long
  nFileOffset    As Integer
  nFileExtension As Integer
  sDefFileExt    As String
  nCustData      As Long
  fnHook         As Long
  sTemplateName  As String
End Type

Public Declare Function ShowCursor Lib "user32" (ByVal bShow As Boolean) As Long
Public Declare Sub SetCursorPos Lib "user32" (ByVal X As Integer, ByVal Y As Integer)
Public Declare Sub GetCursorPos Lib "user32" (ByRef lpPoint As POINT)
Public Declare Function TextOut Lib "gdi32" Alias "TextOutA" _
(ByVal hdc As Long, ByVal X As Long, ByVal Y As Long, ByVal _
lpString As String, ByVal nCount As Long) As Long
Public Declare Function GetOpenFileName Lib "comdlg32.dll" Alias "GetOpenFileNameA" (pOpenfilename As OPENFILENAME) As Long
Public Declare Function FindClose Lib "kernel32" (ByVal hFindFile As Long) As Long
Public Declare Function FindFirstFile Lib "kernel32" Alias "FindFirstFileA" (ByVal lpFileName As String, lpFindFileData As WIN32_FIND_DATA) As Long
Public Declare Function FindNextFile Lib "kernel32" Alias "FindNextFileA" (ByVal hFindFile As Long, lpFindFileData As WIN32_FIND_DATA) As Long
'Public Declare Function GetSaveFileName Lib "comdlg32.dll" Alias "GetSaveFileNameA" (pOpenfilename As OPENFILENAME) As Long
'Public Declare Function GetShortPathName Lib "kernel32" Alias "GetShortPathNameA" (ByVal lpszLongPath As String, ByVal lpszShortPath As String, ByVal cchBuffer As Long) As Long
Public Declare Function GetAsyncKeyState Lib "user32" (ByVal vKey As Long) As Integer

Public Const MaxPicFiles = 8000
Public Const DefaultPicDuration = 5000
Public Const MinPicDuration = 30 '1/30 second

Public TotalPicFiles As Long
Public PicFiles(MaxPicFiles - 1) As String
Public PicOrder(MaxPicFiles - 1) As Long
Public PicPath As String
Public PicFilename As String
Public NextPicFilename As String
Public PicControl As Image
Public PicObject As StdPicture
Public PicHeight As Long
Public PicWidth As Long
'Public NextPic As StdPicture
Public PicIndex As Long
Public PicDuration As Long
Public ScalePic As Boolean
Public KeepProportional As Boolean
Public ShowFileTitle As Boolean
Public ShowFullPath As Boolean
Public LoopAtEnd As Boolean

Public OFN As OPENFILENAME
Public WFD As WIN32_FIND_DATA
Public MousePos As POINT
Public OfnFilename As String * 512
Public Const OfnExts As String = "Pictures (JPG BMP GIF)" & vbNullChar & "*.jpg;*.bmp;*.gif" & vbNullChar & "All files" & vbNullChar & "*" & vbNullChar & vbNullChar

Public Sub Main()

With OFN
    .flags = OFN_LONGNAMES Or OFN_EXPLORER Or OFN_HIDEREADONLY Or OFN_FILEMUSTEXIST Or OFN_PATHMUSTEXIST
    .nStructSize = Len(OFN)
    .sFilter = OfnExts
End With
frmSlideShower.Show

End Sub

Public Function FixPath(Path As String) As String
' little routine to append the annoyingly missing
' backslash on the ends of paths, which SHOULD already
' be put on there so we don't need to write silly
' routines like this ;-/
    If Right$(Path, 1) <> "\" Then
        FixPath = Path & "\"
    Else
        FixPath = Path
    End If
End Function

Public Function FileIsPicture(FileName As String) As Boolean
    Dim Extension As String

    Extension = UCase$(Right$(FileName, 4))
    FileIsPicture = True
    Select Case Extension
    Case ".JPG", ".GIF", ".BMP", ".JPE", ".ICO", ".CUR", ".WMF"
    Case Else: FileIsPicture = False
    End Select
End Function

Public Function LoadPic(FileName As String) As Boolean
    On Error GoTo IgnoreLoadError
    Set PicObject = LoadPicture(FileName)
    Set PicControl.Picture = PicObject
    PicControl.Move 0, 0
    With PicControl
        PicHeight = .Height
        PicWidth = .Width
    End With
    PicFilename = FileName
    LoadPic = True
IgnoreLoadError:
End Function

Public Function GetFileName(FileName As String) As String
    Dim SepPos As Long, Char As Byte

    GetFileName = Mid$(FileName, GetFileNamePos(FileName) + 1)
End Function

Public Function GetFileNamePos(FileName As String) As Long
    Dim SepPos As Long, Char As Byte

    For SepPos = Len(FileName) To 1 Step -1
        Char = Asc(Mid$(FileName, SepPos, 1))
        If Char = 92 Or Char = 58 Then
            'SepPos = SepPos + 1
            Exit For
        End If
    Next
    GetFileNamePos = SepPos
End Function

Public Sub OrderPicFiles()
'orders picture files (in place) using
'a simple semi-recursive linear search
'
'overview:
'   the simplest linear sort would scan from start
'   to finish for each lowest filename. this one,
'   after reaching the end of the list, steps back
'   to the previous lowest and resumes from there.
'
'pseudocode:
'   <search for lowest filename>
'   count from current base to end of table
'     if current filename < previous lowest name
'       save previous lowest to stack
'       set previous lowest to current
'     endif
'   end count
'   <exchange entries and resume search>
'   if lower filename was found
'     swap indexes of base and current lowest
'     advance table base
'     if stack exists && previous last unsorted
'       resume from previous last
'     else
'       clear entire stack
'     endif
'   else
'     advance table base
'   endif

    Dim OrderStack(MaxPicFiles - 1) As Long
    Dim Cmp     As Long
    Dim Base    As Long
    Dim Stack   As Long
    Dim Lowest  As Long
    Dim LowIdx As Long

    'initially set all order indexes sequentially
    UnorderedPicFiles
    Base = 0
    Do Until Base >= TotalPicFiles
        Lowest = Base
FindLowest:
        LowIdx = PicOrder(Lowest)
        Cmp = Base + 1
        'search for a filename lower than the base file
        Do Until Cmp >= TotalPicFiles
            If StrComp(PicFiles(PicOrder(Cmp)), PicFiles(LowIdx), vbTextCompare) < 0 Then
                OrderStack(Stack) = Lowest
                Stack = Stack + 1
                Lowest = Cmp
                LowIdx = PicOrder(Lowest)
            End If
            Cmp = Cmp + 1
        Loop
        'if a lower filename was found
        'otherwise, just leave filename where at
        If Lowest > Base Then
            'swap lowest entry with base entry
            'LowIdx = PicOrder(Lowest) 'unnecessary
            PicOrder(Lowest) = PicOrder(Base)
            PicOrder(Base) = LowIdx
            Base = Base + 1
            If Stack Then
                Stack = Stack - 1
                Lowest = OrderStack(Stack)
                If Lowest > Base Then GoTo FindLowest
                Stack = 0 'clear entire stack
            End If
        Else
            Base = Base + 1
        End If
    Loop
End Sub

Public Sub UnorderedPicFiles()
'set all order indexes sequentially (default unordered)
    Dim Base As Long
    For Base = 0 To TotalPicFiles - 1
        PicOrder(Base) = Base
    Next
End Sub

Public Sub ClearUnusedFiles()
    Dim Count As Long
    For Count = TotalPicFiles To MaxPicFiles - 1
        PicFiles(Count) = ""
    Next
End Sub
