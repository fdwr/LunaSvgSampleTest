DEFINT A-Z
DECLARE SUB PaletteConvert (Palette$, ColorPalette&(), Mode%)
DECLARE SUB PaletteSet (ColorPalette&())
DECLARE FUNCTION OpenExistingFile% (File$)

CONST FileBufferSize = 8192

DIM SHARED File$, FileBuffer(8192) AS LONG, FileError, BlockSize, BlockSizeMinusOne
DIM MainPalette(0 TO 255) AS LONG
File$ = COMMAND$: BlockSize = 3: BlockSizeMinusOne = BlockSize - 1

FileHandle = OpenExistingFile("c:\dw\emu\mario2.zs1")
SEEK FileHandle, 1561
Palette$ = INPUT$(512, FileHandle)
PaletteConvert Palette$, MainPalette(), Mode
Palette$ = ""
CLOSE FileHandle
FileHandle = OpenExistingFile(File$)
IF FileHandle THEN
  SCREEN 13
  PaletteSet MainPalette()
  GOSUB DisplayBuffer
  CLOSE FileHandle
ELSE
  PRINT "File could not be opened"
END IF

END

DisplayBuffer:
  ByteBase& = 1
  TotalBytes = 6400
  ColumnsWide = 64
  ByteStep = 2
  Change = 1
  FileBufferStr$ = SPACE$(FileBufferSize)

  DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE CHR$(0) + "H": ByteBaseDif& = -512: Change = 1
    CASE CHR$(0) + "P": ByteBaseDif& = 512: Change = 1
    CASE CHR$(0) + "K": ByteBaseDif& = ColumnsWide * -2: Change = 1
    CASE CHR$(0) + "M": ByteBaseDif& = ColumnsWide * 2: Change = 1
    CASE CHR$(0) + "s": ByteBaseDif& = -100: Change = 1
    CASE CHR$(0) + "t": ByteBaseDif& = 100: Change = 1
    CASE "-": ByteBaseDif& = -1: Change = 1
    CASE "+": ByteBaseDif& = 1: Change = 1
    CASE "0" TO "9": ByteBase& = VAL(STR$(ByteBase& - 1) + Key$) + 1: Change = 2: IF ByteBase& < 1 THEN ByteBase& = 1
    CASE "": ByteBase& = VAL(LEFT$(STR$(ByteBase& - 1), LEN(STR$(ByteBase& - 1)) - 1)) + 1: Change = 2: IF ByteBase& < 1 THEN ByteBase& = 1
    CASE "/": IF ColumnsWide >= 16 THEN ColumnsWide = ColumnsWide \ 2: Change = 4
    CASE "*": IF ColumnsWide <= 128 THEN ColumnsWide = ColumnsWide * 2: Change = 4
    CASE "[": IF ColumnsWide > 8 THEN ColumnsWide = ColumnsWide - 1: Change = 4
    CASE "]": IF ColumnsWide < 256 THEN ColumnsWide = ColumnsWide + 1: Change = 4
    CASE CHR$(13): GOSUB ChangeFileByte
    CASE CHR$(9): Change = 2: IF ByteStep = 1 THEN ByteStep = 2 ELSE ByteStep = 1
    CASE CHR$(27): EXIT DO
    CASE " "
      PalBase = PalBase + 16 AND 255: Change = 1
    CASE "w"
      FileError = 0
      OPEN "pixview.pcx" FOR OUTPUT AS 2
      IF FileError = 0 THEN GOSUB WritePcx
      CLOSE 2
    CASE ""
      IF Change THEN
        IF CursorMode THEN
          CursorOffset& = CursorOffset& + ByteBaseDif&
          IF CursorOffset& < 0 THEN CursorOffset& = 0
        ELSEIF Change AND 1 THEN
          ByteBase& = ByteBase& + ByteBaseDif&
          IF ByteBase& < 1 THEN ByteBase& = 1
        END IF
        GOSUB GetFileData
        IF Change AND 4 THEN CLS
        GOSUB DisplayPixels: Change = 0: LOCATE 25, 1
        PRINT ByteBase& - 1;
        IF ByteBase& >= 3092 THEN PRINT "("; HEX$(ByteBase& - 3092); ")";
        PRINT ByteValue; "("; HEX$(ByteValue); ")"; TAB(30);
      END IF
    END SELECT
  LOOP

RETURN

WritePcx:
  PRINT #2, CHR$(10); CHR$(5); CHR$(1); CHR$(8); MKL$(0); MKI$(ColumnsWide - 1); MKI$(511); MKI$(512); MKI$(ColumnsWide); STRING$(49, 0); CHR$(1); MKI$(ColumnsWide); MKI$(0); STRING$(58, 0);

  TotalBytes& = ColumnsWide * 1024
  GOSUB GetFileData
  DEF SEG = VARSEG(FileBuffer(0))
  BytePos& = 0
  WHILE BytePos& < TotalBytes&
    ByteValue = PEEK(BytePos&)
    IF ByteValue >= 192 THEN PRINT #2, CHR$(193);
    PRINT #2, CHR$(ByteValue);
    BytePos& = BytePos& + ByteStep
  WEND
  PRINT #2, CHR$(12);

  OUT &H3C7, 0 'Set the read index, not the write index
  FOR BytePos = BytePos TO 767 + BytePos STEP 3
   PRINT #2, CHR$(INP(&H3C9) * 6 AND 255);
   PRINT #2, CHR$(INP(&H3C9) * 6 AND 255);
   PRINT #2, CHR$(INP(&H3C9) * 6 AND 255);
  NEXT BytePos
RETURN

DisplayPixels:
  DEF SEG = VARSEG(FileBuffer(0))
  ColCounter = ColumnsWide
  LastByte = TotalBytes - 1
  IF LastByte > 16383 THEN LastByte = 16383
  Row = 0: Column = 0
  IF ByteStep > 1 THEN
    BytePos& = 0
    FOR Row = 0 TO 191 STEP BlockSize
      FOR Col = 0 TO ColumnsWide * BlockSize - 1 STEP BlockSize
        LINE (Col, Row)-(Col + BlockSizeMinusOne, Row + BlockSizeMinusOne), PEEK(BytePos&), BF
        BytePos& = BytePos& + 2
    NEXT Col, Row
  ELSE
    FOR BytePos& = 0 TO LastByte
      LINE (Column, Row)-(Column + 2, Row + 2), (PEEK(BytePos&) AND 15) + PalBase, BF
      ColCounter = ColCounter - 1: IF ColCounter <= 0 THEN Row = Row + 3: Column = 0: ColCounter = ColumnsWide:  ELSE Column = Column + 3
    NEXT BytePos&
  END IF
  ByteValue = PEEK(0)
RETURN

GetFileData:
  Index = 0
  FOR BytePos& = ByteBase& TO ByteBase& + 16000 STEP FileBufferSize
    GET 1, BytePos&, FileBufferStr$
    BufferPos = 1
    FOR Index = Index TO Index + FileBufferSize \ 4 - 1
      FileBuffer(Index) = CVL(MID$(FileBufferStr$, BufferPos, 4))
      BufferPos = BufferPos + 4
    NEXT Index
  NEXT BytePos&
RETURN

ChangeFileByte:
  LOCATE 25, 1
  LINE INPUT ; "Data:"; Text$
  IF LEN(Text$) <= 0 THEN RETURN
  Text$ = CHR$(VAL(LEFT$(Text$, 4)) AND 255)
  PUT 1, ByteBase&, Text$
  Change = 2
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

SUB PaletteConvert (Palette$, ColorPalette() AS LONG, Mode)

IF Mode THEN
  Red = 8: Green = 4: Blue = 128
ELSE
  Red = 2: Green = 16: Blue = 512
END IF

DEF SEG = VARSEG(ColorPalette(0))
BytePos = VARPTR(ColorPalette(0))
FOR CurColor = 1 TO 512 STEP 2
  ColorValue = CVI(MID$(Palette$, CurColor, 2))
  POKE BytePos, (ColorValue AND 31) * Red
  POKE BytePos + 1, (ColorValue AND 992) \ Green
  POKE BytePos + 2, (ColorValue AND 31744) \ Blue
  BytePos = BytePos + 4
NEXT CurColor

END SUB

SUB PaletteSet (ColorPalette() AS LONG)

DEF SEG = VARSEG(ColorPalette(0))
BytePos = VARPTR(ColorPalette(0))
OUT &H3C8, 0
FOR CurColor = 0 TO 255
  OUT &H3C9, PEEK(BytePos)
  OUT &H3C9, PEEK(BytePos + 1)
  OUT &H3C9, PEEK(BytePos + 2)
  BytePos = BytePos + 4
NEXT CurColor

END SUB

