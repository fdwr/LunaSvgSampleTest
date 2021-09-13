Attribute VB_Name = "modUnusedCode"
Option Explicit

#If False Then

Private Declare Function GetTempPath Lib "kernel32" Alias "GetTempPathA" (ByVal nBufferLength As Long, ByVal lpBuffer As String) As Long
Dim TempFilePath As String

TempFilePath = String(256, vbNullChar)
GetTempPath Len(TempFilePath), TempFilePath
TempFilePath = Left(TempFilePath, InStr(TempFilePath, vbNullChar) - 1)

Private Sub LoadDbPic2(picHnd As StdPicture)
    Dim Chunk() As Byte
    Dim FileNum As Long
    Dim FileName As String

    'get picture from database
    Chunk() = SgvTbl("Picture").GetChunk(0, SgvTbl("Picture").FieldSize)

    'save picture temporarily to disk
    FileName = TempFilePath & "~dbpic.jpg"
    FileNum = FreeFile
    Open FileName For Binary As FileNum
    Put FileNum, , Chunk()
    Close FileNum

    'load picture, then discard
    'picCandidates(TotalCandidates) = LoadPicture(FileName)
    Set picHnd = LoadPicture(FileName)
    Kill FileName

End Sub

Private Sub StoreDbPic2(picHnd As Image)
    Dim Chunk() As Byte
    Dim FileNum As Long
    Dim FileName As String

    'get temporary from disk
    FileName = TempFilePath & "~dbpic.jpg"
    FileNum = FreeFile
    
    'save picture
    'SavePicture picCandidates(TotalCandidates), FileName
    SavePicture picHnd, FileName
    Open FileName For Binary Access Read As FileNum
    ReDim Chunk(LOF(FileNum))
    Get FileNum, , Chunk()
    Close FileNum

    'put picture into database, then discard
    'Chunk() = SgvTbl("Picture").GetChunk(0, SgvTbl("Picture").FieldSize)
    SgvTbl.Edit
    SgvTbl("Picture").AppendChunk Chunk()
    SgvTbl.Update
    Kill FileName
    
End Sub

'Discard this ...
'
'Let me just say that it was idiotic that (four hours later), the only
'solution I could find to getting rid of the background flicker was to
'subclass the window procedure, intercepting those annoying ERASEBKGND
'messages.
'
'I didn't want to set the Picture attribute of the form because that
'would have used a lot of space for a small image. I tried to copy
'from an image control, but it had no hDC. Then from a Picture Box
'to the form using StrechBlt, but there was never any visible picture??
'
'Tried setting the form invisible, but then the controls within were
'not redrawn properly. Perhaps there is a way to set the hBackground
'to null, that way the DefWindowProc would not erase it.

'Public Declare Function GetWindowLong Lib "user32" Alias "GetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long) As Long
'Public Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
'Public Declare Function CallWindowProc Lib "user32" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hwnd As Long, ByVal Msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
'Private Declare Function SelectObject Lib "gdi32" (ByVal hdc As Long, ByVal hObject As Long) As Long
'Public Declare Function BitBlt Lib "gdi32" (ByVal hDestDC As Long, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal dwRop As Long) As Long
'Public Declare Function StretchBlt Lib "gdi32" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal nSrcWidth As Long, ByVal nSrcHeight As Long, ByVal dwRop As Long) As Long

'Public Const WM_PAINT = &HF
'Public Const WM_NCHITTEST = &H84
'Public Const WM_SIZE = &H5
'Public Const WM_ERASEBKGND = &H14
'Public Const GWL_EXSTYLE = (-20)
'Public Const GWL_WNDPROC = (-4)
'Public Const SRCCOPY = &HCC0020
'Public Const WS_EX_TRANSPARENT = &H20

'Code/Value (hex)     Description
'--------------------------------------------------------------------------
'BLACKNESS (42)       Turn output black.
'DSINVERT(550009)     Inverts the destination bitmap.
'MERGECOPY(C000CA)    Combines the pattern and the source bitmap using the
'                     Boolean AND operation.
'MERGEPAINT(BB0226)   Combines the inverted source bitmap with the
'                     destination bitmap using the Boolean OR operator.
'NOTSRCCOPY(330008)   Copies the inverted source bitmap to the destination.
'NOTSRCERASE(1100A6)  Inverts the result of combining the destination and
'                     source bitmap using the Boolean OR operator.
'PATCOPY(F00021)      Copies the pattern to the destination bitmap.
'PATINVERT(5A0049)    Combines the destination bitmap with the pattern using
'                     the Boolean XOR operator.
'PATPAINT(FB0A09)     Combines the inverted source bitmap with the pattern
'                     using the Boolean OR operator. Combines the result of
'                     this operation with the destination bitmap using the
'                     Boolean OR operator.
'SRCAND(8800C6)       Combines pixels of the destination and source bitmap
'                     using the Boolean AND operator.
'SRCCOPY(CC0020)      Copies the source bitmap to destination bitmap.
'SRCERASE(4400328)    Inverts the destination bitmap and combines the
'                     results with the source bitmap using the Boolean AND
'                     operator.
'SRCINVERT(660046)    Combines pixels of the destination and source bitmap
'                     using the Boolean XOR operator.
'SRCPAINT(EE0086)     Combines pixels of the destination and source bitmap
'                     using the Boolean OR operator.
'WHITENESS(FF0062)    Turns all output white.

#If False Then
Public OldProc As Long
Public FrmHwnd As Long
Public FrmDC As Long

Public Function WndProc(ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long

If wMsg = WM_ERASEBKGND Then 'ignore stupid flicker
    WndProc = -1
Else
    WndProc = CallWindowProc(OldProc, hwnd, wMsg, wParam, lParam)
End If

'set background
'imgBg.Stretch = True
'imgBg.Move 0, 0, ScaleWidth, ScaleHeight
'StretchBlt hdc, 0, 0, Width, Height, picBg.hdc, 0, 0, imgBg.Width, imgBg.Height, vbSrcCopy
'PaintPicture
'Picture = imgBg.Picture
'hDC = imgBg.Picture
'SelectObject hdc, 0
'SetWindowLong Me.hwnd, GWL_EXSTYLE, WS_EX_TRANSPARENT

' Start subclassing
'FrmHwnd = Me.hwnd
'FrmDC = Me.hDC
'OldProc = GetWindowLong(FrmHwnd, GWL_WNDPROC)
'SetWindowLong FrmHwnd, GWL_WNDPROC, AddressOf WndProc
 
'StretchBlt Me.hdc, 0, 0, Width, Height, picBg.hdc, 0, 0, picBg.Width, picBg.Height, SRCCOPY
'BitBlt Me.hdc, 0, 0, Width, Height, picBg.hdc, 0, 0, SRCCOPY

End Function
#End If





#End If
