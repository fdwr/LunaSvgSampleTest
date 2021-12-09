'Bitmap to font Exporter, by Dwayne Robinson on 1998-09-07.

'Opens any 256 color .bmp and exports it to a linear bitmap.
'Useful for Qbasic screen mode 13.

DEFINT A-Z
DECLARE SUB Prompt (Text$, Key$, Csr, Lim, Row, Col)
DECLARE FUNCTION FileExists (FileName$)
DECLARE FUNCTION ValidateName$ (FileName$, FileExt$)
DECLARE FUNCTION ConvertToFont& (DataRow$)
DIM SHARED ErrorNum, ColorMapTable(0 TO 255)

ColorMapTable(0) = 0: ColorMapTable(1) = 1: ColorMapTable(2) = 2

CLS
WIDTH 80, 50
VIEW PRINT 1 TO 50
PRINT "Bitmap exporter 0.0"
PRINT "By FDwR on 1998-09-07"
PRINT

GOSUB GetCommandLine

GetSourceFilename:
  PromptText$ = "Source image:": FileName$ = SourceFile$: FileExt$ = "bmp"
  GOSUB GetFileName
  IF LEN(FileName$) = 0 THEN GOTO ProgramEnd
  SourceFile$ = ValidateName(FileName$, FileExt$)

OpenSourceFile:
  CLOSE SourceFileNum
  IF NOT FileExists(SourceFile$) THEN
    PRINT "Source could not be opened"; CHR$(13)
    GOTO GetSourceFilename
  END IF
  SourceFileNum = FREEFILE: OPEN SourceFile$ FOR BINARY AS SourceFileNum
 
  GOSUB GetBitmapInfo
  PRINT "--------------------"
  PRINT "Size of header:"; HeaderSize; "bytes"
  PRINT "Image bytes offset:"; ImageOffset&
  PRINT "Image dimensions:"; STR$(PicWidth); "x"; LTRIM$(STR$(PicHeight)); " pixels"
  PRINT "Total colors:"; STR$(2& ^ PixelBits); ","; PixelBits; "bits per pixel"
  IF PicWidth > 1024 OR PicWidth > 1024 THEN
    PRINT "Dimensions are too large, they must both be under 1024 pixels"; CHR$(13)
    GOTO GetSourceFilename
  END IF
  IF PixelBits <> 8 THEN
    PRINT "Only 256 color (8 bit) bitmaps can be read"; CHR$(13)
    GOTO GetSourceFilename
  END IF
  PRINT

GetDestFilename:
  PromptText$ = "Destination:": FileName$ = DestFile$: FileExt$ = "lbm"
  GOSUB GetFileName
  IF LEN(FileName$) = 0 THEN PRINT : GOTO GetSourceFilename
  DestFile$ = ValidateName(FileName$, FileExt$)

  IF FileExists(DestFile$) THEN
    PRINT "Destination already exists, do you want write over it? Y/N";
    DO: Key$ = UCASE$(INKEY$): LOOP UNTIL LEN(Key$)
    PRINT CHR$(13)
    IF Key$ <> CHR$(13) AND Key$ <> "Y" THEN GOTO GetDestFilename
  END IF
 
  ON ERROR GOTO ErrorHandler: ErrorNum = 0
  DestFileNum = FREEFILE
  OPEN DestFile$ FOR OUTPUT AS DestFileNum
  ON ERROR GOTO 0
  IF ErrorNum THEN
    PRINT "Could not write to destination"; CHR$(13)
    GOTO GetDestFilename
  END IF
 
StartConversion:
  PRINT "Exporting linear bitmap:";
  Row = CSRLIN: Col = POS(0): LOCATE , , 0

  VerticalRows = PicHeight
  RowBytes = PicWidth + 3 AND -4
  FilePos& = ImageOffset& + 1 + CLNG(PicHeight - 1) * RowBytes
  FileData$ = STRING$(RowBytes, 0)
  DO WHILE VerticalRows > 0
    GET SourceFileNum, FilePos&, FileData$
    DataOut$ = LEFT$(MKL$(ConvertToFont(FileData$)), 2)
    PRINT #DestFileNum, DataOut$;
    FilePos& = FilePos& - RowBytes
    VerticalRows = VerticalRows - 1
    LOCATE Row, Col: PRINT STR$((PicHeight - VerticalRows) * 100& \ PicHeight); "%";
  LOOP
  CLOSE SourceFileNum, DestFileNum
  SourceFileNum = 0: DestFileNum = 0

DoneExporting:
  PRINT
  PRINT "Done, you can type in another bitmap or press Escape"
  PRINT
  LOCATE , , 1
  GOTO GetSourceFilename

ProgramEnd:
  CLOSE

END

GetFileName:
  PRINT PromptText$;
  Row = CSRLIN: Col = POS(0): Csr = LEN(FileName$)
  Prompt FileName$, "", Csr, 64, Row, Col
  DO
    Key$ = INKEY$
    IF LEN(Key$) THEN
      IF Key$ = CHR$(27) THEN FileName$ = "": PRINT : RETURN ELSE IF Key$ = CHR$(13) THEN EXIT DO
      Prompt FileName$, Key$, Csr, 64, Row, Col
    END IF
  LOOP
  PRINT
  IF INSTR(FileName$, "*") THEN SHELL "dir " + FileName$: GOTO GetFileName
  ON ERROR GOTO ErrorHandler: ErrorNum = 0
  CHDIR FileName$
  ON ERROR GOTO 0
  IF ErrorNum = 0 OR FileName$ = ".." THEN
    IF ErrorNum = 0 THEN PRINT "Directory changed" ELSE PRINT "Already in root directory"
    FileName$ = ""
    GOTO GetFileName
  END IF
RETURN

GetBitmapInfo:
  Header$ = INPUT$(34, SourceFileNum)
  HeaderSize = CVI(MID$(Header$, 15, 2))
  ImageOffset& = CVL(MID$(Header$, 11, 4))
  PicWidth = CVI(MID$(Header$, 19, 2))
  PicHeight = CVI(MID$(Header$, 23, 2))
  PixelBits = CVI(MID$(Header$, 29, 2))
RETURN

GetCommandLine:
  CommandLine$ = COMMAND$
  IF LEN(CommandLine$) = 0 THEN RETURN
  ItemSep = INSTR(CommandLine$, " ")
  IF ItemSep = 0 THEN ItemSep = LEN(CommandLine$) + 1
  SourceFile$ = ValidateName(LEFT$(CommandLine$, ItemSep - 1), "bmp")
  PRINT "Source image:"; SourceFile$
  CommandLine$ = MID$(CommandLine$, ItemSep)
  IF LEN(CommandLine$) = 0 THEN DestFile$ = ValidateName(SourceFile$, "") + ".lbm" ELSE DestFile$ = CommandLine$
RETURN OpenSourceFile

ErrorHandler:
  ErrorNum = ERR
RESUME NEXT

FUNCTION ConvertToFont& (DataRow$)

BitPos& = 1
BitRow& = 0

FOR CurChar = 1 TO 8
  PixelValue = ASC(MID$(DataRow$, CurChar, 1))
  BitRow& = BitRow& OR ColorMapTable(PixelValue) * BitPos&
  BitPos& = BitPos& * 4
NEXT CurChar

ConvertToFont& = BitRow&

END FUNCTION

FUNCTION FileExists (FileName$)
  ON ERROR GOTO ErrorHandler: ErrorNum = 0
  FileNum = FREEFILE
  OPEN FileName$ FOR INPUT AS FileNum: CLOSE FileNum
  ON ERROR GOTO 0
  IF ErrorNum = 0 THEN FileExists = -1
END FUNCTION

SUB Prompt (Text$, Key$, Csr, Lim, Row, Col)

Length = LEN(Text$)
SELECT CASE Key$
CASE CHR$(0) + "K": IF Csr > 0 THEN Csr = Csr - 1
CASE CHR$(0) + "M": IF Csr < Length THEN Csr = Csr + 1
CASE CHR$(0) + "G": Csr = 0
CASE CHR$(0) + "O": Csr = Length
CASE CHR$(8): IF Csr > 0 THEN Text$ = LEFT$(Text$, Csr - 1) + MID$(Text$, Csr + 1): Csr = Csr - 1
CASE " " TO "ÿ": IF Length < Lim THEN Text$ = LEFT$(Text$, Csr) + Key$ + MID$(Text$, Csr + 1): Csr = Csr + 1
END SELECT

LOCATE Row, Col, 0
IF Length > Lim THEN
  PRINT RIGHT$(Text$, Lim);
ELSE
  PRINT Text$; SPACE$(Lim - Length);
END IF
LOCATE Row, Col + Csr, 1

END SUB

FUNCTION ValidateName$ (FileName$, FileExt$)
  IF LEN(FileExt$) THEN
    IF INSTR(FileName$, ".") = 0 THEN ValidateName = FileName$ + "." + FileExt$ ELSE ValidateName = FileName$
  ELSE
    ItemSep = INSTR(FileName$, ".")
    IF ItemSep THEN ValidateName = LEFT$(FileName$, ItemSep - 1) ELSE ValidateName = FileName$
  END IF
END FUNCTION

