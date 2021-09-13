'1999-07-27
DEFINT A-Z
DECLARE FUNCTION OpenExistingFile% (File$)

CONST FileBufferSize = 8192

DIM SHARED DifferenceBits(16383), FileError

SCREEN 0
CLS
GOSUB GetFiles

FileHandle1 = OpenExistingFile(File1$)
IF FileHandle1 THEN
  FileHandle2 = OpenExistingFile(File2$)
  IF FileHandle2 THEN
    GOSUB CompareFiles
    GOSUB DisplayResults
    END
  END IF
  CLOSE FileHandle1
  PRINT "Second file could not be opened"
ELSE
  PRINT "First file could not be opened"
END IF

END

CompareFiles:
  DEF SEG = VARSEG(DifferenceBits(0))
  BitIndex& = 0
  FileBuffer1$ = SPACE$(FileBufferSize)
  FileBuffer2$ = SPACE$(FileBufferSize)
  FilePosition1& = 1
  FilePosition2& = 1
  FileSize1& = LOF(FileHandle1)
  FileSize2& = LOF(FileHandle2)
  IF FileSize1& < FileSize2& THEN FileBytesTotal& = FileSize1& ELSE FileBytesTotal& = FileSize2&
  IF FileBytesTotal& < 1 THEN RETURN
  FileBytes& = FileBytesTotal&
  BitsCompared& = 0
  FileBytesPercent& = FileBytesTotal& \ 100

  PRINT "Comparing:";
  DO
    LOCATE , 11
    PRINT STR$((FileBytesTotal& - FileBytes&) \ FileBytesPercent&); "%";
    GET FileHandle1, FilePosition1&, FileBuffer1$
    GET FileHandle2, FilePosition2&, FileBuffer2$
    GOSUB CompareSection
    FileBytes& = FileBytes& - FileBufferSize
    IF FileBytes& < 1 THEN EXIT DO
    FilePosition1& = FilePosition1& + FileBufferSize
    FilePosition2& = FilePosition2& + FileBufferSize
    BitsCompared& = BitsCompared& + FileBufferSize
  LOOP UNTIL INKEY$ = CHR$(27)
  BitsCompared& = BitsCompared& + (FileBufferSize + FileBytes&)

  LOCATE , 11: PRINT " 100%"

RETURN

CompareSection:
  IF BitIndex& > 32000 THEN STOP
  FOR FileBufferPos = 1 TO FileBufferSize STEP 8
    DifferenceByte = 0
    IF MID$(FileBuffer1$, FileBufferPos, 8) = MID$(FileBuffer2$, FileBufferPos, 8) GOTO NoDifferent
    IF MID$(FileBuffer1$, FileBufferPos, 1) <> MID$(FileBuffer2$, FileBufferPos, 1) THEN DifferenceByte = DifferenceByte OR 1
    IF MID$(FileBuffer1$, FileBufferPos + 1, 1) <> MID$(FileBuffer2$, FileBufferPos + 1, 1) THEN DifferenceByte = DifferenceByte OR 2
    IF MID$(FileBuffer1$, FileBufferPos + 2, 1) <> MID$(FileBuffer2$, FileBufferPos + 2, 1) THEN DifferenceByte = DifferenceByte OR 4
    IF MID$(FileBuffer1$, FileBufferPos + 3, 1) <> MID$(FileBuffer2$, FileBufferPos + 3, 1) THEN DifferenceByte = DifferenceByte OR 8
    IF MID$(FileBuffer1$, FileBufferPos + 4, 1) <> MID$(FileBuffer2$, FileBufferPos + 4, 1) THEN DifferenceByte = DifferenceByte OR 16
    IF MID$(FileBuffer1$, FileBufferPos + 5, 1) <> MID$(FileBuffer2$, FileBufferPos + 5, 1) THEN DifferenceByte = DifferenceByte OR 32
    IF MID$(FileBuffer1$, FileBufferPos + 6, 1) <> MID$(FileBuffer2$, FileBufferPos + 6, 1) THEN DifferenceByte = DifferenceByte OR 64
    IF MID$(FileBuffer1$, FileBufferPos + 7, 1) <> MID$(FileBuffer2$, FileBufferPos + 7, 1) THEN DifferenceByte = DifferenceByte OR 128
NoDifferent:
    POKE BitIndex&, DifferenceByte
    BitIndex& = BitIndex& + 1
  NEXT
RETURN

DisplayResults:
  SCREEN 13

  DEF SEG = &HA000
  ScreenPos& = ScreenRow * 320
  BitsIndexBase = 3092 \ 16
  TotalBits = 4000
  Change = 1

  DO
    key$ = INKEY$
    SELECT CASE key$
    CASE CHR$(27): EXIT DO
    CASE CHR$(0) + "H": BitsIndexBase = BitsIndexBase - 512: Change = -1: IF BitsIndexBase < 0 THEN BitsIndexBase = 0
    CASE CHR$(0) + "P": BitsIndexBase = BitsIndexBase + 512: Change = -1: IF BitsIndexBase > 16383 THEN BitsIndexBase = 16383
    CASE CHR$(0) + "K": BitsIndexBase = BitsIndexBase - 128: Change = -1: IF BitsIndexBase < 0 THEN BitsIndexBase = 0
    CASE CHR$(0) + "M": BitsIndexBase = BitsIndexBase + 128: Change = -1: IF BitsIndexBase > 16383 THEN BitsIndexBase = 16383
    CASE "*": BitsIndexBase = BitsIndexBase - 16: Change = -1: IF BitsIndexBase < 0 THEN BitsIndexBase = 0
    CASE "/": BitsIndexBase = BitsIndexBase + 16: Change = -1: IF BitsIndexBase > 16383 THEN BitsIndexBase = 16383
    CASE "+": BitsIndexBase = BitsIndexBase - 1: Change = -1: IF BitsIndexBase < 0 THEN BitsIndexBase = 0
    CASE "-": BitsIndexBase = BitsIndexBase + 1: Change = -1: IF BitsIndexBase > 16383 THEN BitsIndexBase = 16383
    CASE " ": LINE (0, 0)-(320, 0), 15, , -32768
    CASE "": IF Change THEN ScreenPos& = 0: GOSUB DisplayBits: Change = 0: LOCATE 25, 1: PRINT BitsIndexBase * 16&;
    END SELECT
  LOOP

RETURN

DisplayBits:
  ColCounter = 16
  IF TotalBits > 3200 THEN TotalBits = 3200
  LastBitsIndex = BitsIndexBase + TotalBits - 1
  IF LastBitsIndex > 16383 THEN LastBitsIndex = 16383
  FOR BitsIndex = BitsIndexBase TO LastBitsIndex
    POKE ScreenPos& + 0, SGN(DifferenceBits(BitsIndex) AND 1)
    POKE ScreenPos& + 1, SGN(DifferenceBits(BitsIndex) AND 2)
    POKE ScreenPos& + 2, SGN(DifferenceBits(BitsIndex) AND 4)
    POKE ScreenPos& + 3, SGN(DifferenceBits(BitsIndex) AND 8)
    POKE ScreenPos& + 4, SGN(DifferenceBits(BitsIndex) AND 16)
    POKE ScreenPos& + 5, SGN(DifferenceBits(BitsIndex) AND 32)
    POKE ScreenPos& + 6, SGN(DifferenceBits(BitsIndex) AND 64)
    POKE ScreenPos& + 7, SGN(DifferenceBits(BitsIndex) AND 128)
    POKE ScreenPos& + 8, SGN(DifferenceBits(BitsIndex) AND 256)
    POKE ScreenPos& + 9, SGN(DifferenceBits(BitsIndex) AND 512)
    POKE ScreenPos& + 10, SGN(DifferenceBits(BitsIndex) AND 1024)
    POKE ScreenPos& + 11, SGN(DifferenceBits(BitsIndex) AND 2048)
    POKE ScreenPos& + 12, SGN(DifferenceBits(BitsIndex) AND 4096)
    POKE ScreenPos& + 13, SGN(DifferenceBits(BitsIndex) AND 8192)
    POKE ScreenPos& + 14, SGN(DifferenceBits(BitsIndex) AND 16384)
    POKE ScreenPos& + 15, SGN(DifferenceBits(BitsIndex) AND 32768)
    ScreenPos& = ScreenPos& + 16
    ColCounter = ColCounter - 1: IF ColCounter <= 0 THEN ScreenPos& = ScreenPos& + 64: ColCounter = 16
  NEXT BitsIndex
RETURN

GetFiles:
  File1$ = COMMAND$
  NextPos = INSTR(File1$, " ")
  IF NextPos THEN
    File2$ = LTRIM$(MID$(File1$, NextPos))
    File1$ = LEFT$(File1$, NextPos - 1)
  END IF
RETURN

FileErrorHandler:
  FileError = -1
RESUME NEXT

FUNCTION OpenExistingFile (File$)

ON ERROR GOTO FileErrorHandler
FileError = 0
NewFile = FREEFILE
OPEN File$ FOR INPUT AS NewFile
ON ERROR GOTO 0
IF FileError THEN EXIT FUNCTION
CLOSE NewFile
OPEN File$ FOR BINARY AS NewFile
OpenExistingFile = NewFile

END FUNCTION

