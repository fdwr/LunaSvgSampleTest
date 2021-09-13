Attribute VB_Name = "modCanvas"
Option Explicit

Public CanvasHeight As Long
Public CanvasWidth As Long
Public CanvasSize As Long
Public CanvasPixels() As Integer
Public CompressedPixels() As Integer

Public Sub NewCanvas(NewHeight As Long, NewWidth As Long)
    CanvasHeight = NewHeight
    CanvasWidth = NewWidth
    CanvasSize = CanvasHeight * CanvasWidth
    ReDim CanvasPixels(CanvasSize - 1)
End Sub

'This routine assumes the range checking
'was already done by the caller
Public Sub PlotDot(X As Long, Y As Long, Color As Integer)
    CanvasPixels(Y * CanvasWidth + X) = Color
End Sub

Public Function Cvt24To15(Color As Long) As Integer
    Cvt24To15 = &H7FFF
End Function

'compresses the canvas, from CanvasPixels to CompressedPixels
Public Sub CompressPixels()
'Like any compression, it reduces the space required to hold
'the data by eliminating redundancy and repeating patterns.
'This particular routine searches for reoccuring horizontal
'pixel patterns.
'
'When it finds a strip of similar pixels that have already been
'encoded, it simply stores a pointer and length back to the
'previous run. When it finds an alternating pattern of pixels,
'like dithered colors in GIFs, it simply stores the first pattern
'and a length. When it reaches new data that has never been encoded
'before, it stores the width of the row followed by the pixel data.
'
'Technically it compresses data, not specifically images, but it
'is probably best suited for graphics compression/decompression.
'Since it views the whole image as one long linear chunk of data,
'it can apply compression without needing to break between rows.
'It is fairly simple and does not further compress the rarer
'individual pixels to use fewer bits (no Huffman table).
'Compression is not the best, but decompression is very fast.
End Sub
