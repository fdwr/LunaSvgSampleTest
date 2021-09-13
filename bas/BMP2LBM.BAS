'2000.1.30
DEFINT A-Z
DECLARE FUNCTION NumberStr$ (Number%)

DIM SourceFile AS STRING, DestFile AS STRING, PixelStrip AS STRING
DIM BitmapHeight, BitmapWidth, BitmapBytesPerRow

BitmapFile$ = COMMAND$
SourceFile$ = BitmapFile$ + ".BMP"
DestFile$ = BitmapFile$ + ".LBM"
BitmapHeight = 128
BitmapWidth = 16

PRINT "-------------------------------"
PRINT "Windows bitmap to linear bitmap"
PRINT "-------------------------------"
PRINT "Source file: "; SourceFile$
PRINT "Dest file:   "; DestFile$


ON ERROR GOTO ErrorHandler
ErrorHandled = 0
OPEN SourceFile$ FOR INPUT AS 1: CLOSE
IF ErrorHandled THEN
    PRINT "Error opening source"
    GOTO ErrorEnd
END IF
OPEN SourceFile$ FOR BINARY AS 1
GET 1, 11, FilePos&
GET 1, 19, BitmapWidth
GET 1, 23, BitmapHeight
PRINT "Bitmap size: "; NumberStr$(BitmapWidth); "x"; NumberStr$(BitmapHeight)
PRINT "Data starts: "; NumberStr$(INT(FilePos&))

OPEN DestFile$ FOR OUTPUT AS 2
IF ErrorHandled THEN
    PRINT "Error opening source"
    GOTO ErrorEnd
END IF
ON ERROR GOTO 0


BitmapBytesPerRow = (BitmapWidth + 3) AND -4
FilePos& = FilePos& + (BitmapHeight - 1) * BitmapBytesPerRow + 1
PixelStrip = STRING$(BitmapWidth, 0)
FOR Count = 1 TO BitmapHeight
    GET 1, FilePos&, PixelStrip
    PRINT #2, PixelStrip;
    FilePos& = FilePos& - BitmapBytesPerRow
    LOCATE , 1: PRINT "Writing...   "; NumberStr$(Count * 100 \ BitmapHeight); "%";
NEXT Count
PRINT

ErrorEnd:
CLOSE
END

ErrorHandler:
    ErrorHandled = ERR
RESUME NEXT

FUNCTION NumberStr$ (Number)
    NumberStr$ = LTRIM$(STR$(Number))
END FUNCTION

