'1999.3.9 Peekin
'Tilemap to bitmap

DEFINT A-Z
OPTION BASE 0

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Fl AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

CONST FileBufferSize = 32768
CONST TilePaletteMask = 1, TilePaletteShift = 1, TileCharMask = 1023
CONST LastBitplane = 3, TilePaletteSize = 64, TilePaletteBase = 0

DIM TileTable(16383), VramGraphics(16383) AS LONG, FileBuffer(16383)
DIM PixelStrip(16383), ColorPalette(255) AS LONG, DosReadRegs AS RegType
DIM SHARED ErrorHandled, Regs AS RegType
'FileBufferBase&

SCREEN 13

GOSUB GetTilemapVariables
GOSUB LoadTilemapFiles
IF ErrorHandled GOTO EndProg
GOSUB SetColorPalette

TileRowHeight = 8
TileColWidth = 8
GOSUB OutputImageHeader
TilemapRowCounter = TilemapHeight
DO UNTIL TilemapRowCounter <= 0
  GOSUB TranslateTilemapRow
  TilemapRowCounter = TilemapRowCounter - 1
  LOCATE 25, 1: PRINT "Rows remaining:"; TilemapRowCounter; TilemapFilePos&; TiletableFileBase&;
  'TiletableFileBase&; "   ";
  Key$ = INKEY$
  IF LEN(Key$) THEN
    Change = 0
    WHILE LEN(Key$)
      SELECT CASE Key$
      CASE CHR$(27): EXIT DO
      CASE "": TiletableFileBase& = TiletableFileBase& - 32768: Change = 1
      CASE " ": TiletableFileBase& = TiletableFileBase& + 32768: Change = 1
      CASE "-": TiletableFileBase& = TiletableFileBase& - 1: Change = 1
      CASE "+": TiletableFileBase& = TiletableFileBase& + 1: Change = 1
      CASE ".": TileGraphicsBase& = TileGraphicsBase& + 4096 AND 65535
      END SELECT
      Key$ = INKEY$
    WEND
    IF Change THEN GOSUB GetBankTable
  END IF
LOOP
GOSUB OutputImagePalette
CLOSE 1, 2, 4

LOCATE 25, 1: PRINT "Press any key to end."; TAB(40);
DO: LOOP UNTIL LEN(INKEY$)

EndProg:
  CLS
  PRINT "(-: See ya! :-)"
  END

GetTilemapVariables:
  TilemapCols = 20
  TileByteSize& = 32
  FileImageOutput$ = ""
 
  'TilemapWidth = 16
  'TilemapHeight = 160
  'FileTilemap$ = "c:\dw\emu\saves\allstars.zs7"
  'FileTiletable$ = "c:\dw\emu\allstars.smc"
  'TileGraphicsBase& = 16384
  'TilemapFilePos& = 11284'68624
  'TiletableFileBase& = &H122680'&H122EE8 - 104'&H154C39
  'FileVram$ = FileTilemap$
 
  TilemapWidth = 32
  TilemapHeight = 32
  FileTilemap$ = "c:\dw\emu\saves\metroid.zs9"
  FileTiletable$ = "c:\dw\emu\metroid.smc"
  TileGraphicsBase& = 0
  TilemapFilePos& = 68694
  TiletableFileBase& = &H20B97B - 2184'1876639'512
  FileVram$ = FileTilemap$
 
  'TilemapWidth = 64
  'TilemapHeight = 64
  'FileTilemap$ = "c:\dw\emu\saves\zelda.zs4"
  'FileTiletable$ = "c:\dw\emu\zelda.smc"
  'TileGraphicsBase& = 16384
  'TilemapFilePos& = 11284
  'TiletableFileBase& = 492033'-1
  'FileVram$ = FileTilemap$

  'TilemapWidth = 32
  'TilemapHeight = 448
  'TilemapCols = TilemapWidth
  'FileTilemap$ = "c:\dw\emu\metroid.smc"
  'FileVram$ = "c:\dw\emu\metroid.zs6"
  'FileImageOutput$ = "c:\dw\emu\metroid.pcx"
  'TileGraphicsBase& = 24576
  'TilemapFilePos& = 1737217
  'TiletableFileBase& = 134164'-1
  'FileTiletable$ = FileVram$
  'TileByteSize& = 32

  FileBufferBase& = -FileBufferSize

  PRINT "Tilemap is"; TilemapWidth; "x"; TilemapHeight
RETURN

LoadTilemapFiles:
  'open tilemap file
  OPEN FileTilemap$ FOR INPUT AS 1: CLOSE 1
  OPEN FileTilemap$ FOR BINARY AS 1
  'open tiletable file
  OPEN FileTiletable$ FOR BINARY AS 2
  'open vram file
  OPEN FileVram$ FOR BINARY AS 3
  IF LEN(FileImageOutput$) THEN OPEN FileImageOutput$ FOR OUTPUT AS 4
 
  'load in tile table
  GOSUB GetBankTable
 
  'load in vram graphics
  SEEK 3, 134164'-1
  DosReadRegs.Ax = &H3F00
  DosReadRegs.Bx = FILEATTR(3, 2)
  DosReadRegs.Ds = VARSEG(VramGraphics(0))
  DosReadRegs.Dx = VARPTR(VramGraphics(0))
  CALL interruptx(&H21, DosReadRegs, Regs)
  DosReadRegs.Dx = DosReadRegs.Dx + -32768
  CALL interruptx(&H21, DosReadRegs, Regs)
 
  'load in palette too from vram file
  SEEK 3, 1561
  CgramPalette$ = INPUT$(512, 3)
  DEF SEG = VARSEG(ColorPalette(0))
  ByteDest = 0
  FOR Count = 1 TO 512 STEP 2
    Word = CVI(MID$(CgramPalette$, Count, 2))
    POKE ByteDest + 2, (Word AND 31744) \ 512'blue
    POKE ByteDest + 1, (Word AND 992) \ 16'green
    POKE ByteDest + 0, (Word AND 31) * 2'red
    ByteDest = ByteDest + 4
  NEXT Count
  CgramPalette$ = ""
 
  'close vram file
  CLOSE 3
RETURN

TranslateTilemapRow:
  'make sure needed data is in buffer, load it in if not
  BufferOffset& = TilemapFilePos& - FileBufferBase&
  IF BufferOffset& + TilemapWidth * 2 > FileBufferSize THEN
    'SEEK TilemapFile, TilemapFilePos&
    SEEK 1, TilemapFilePos&
    DosReadRegs.Ax = &H3F00
    DosReadRegs.Bx = FILEATTR(1, 2)
    DosReadRegs.Cx = -32768
    DosReadRegs.Ds = VARSEG(FileBuffer(0))
    DosReadRegs.Dx = VARPTR(FileBuffer(0))
    CALL interruptx(&H21, DosReadRegs, Regs)
    BufferOffset& = 0
    FileBufferBase& = TilemapFilePos&
  END IF
 
  BufferOffset = BufferOffset&' \ 2
  CurTileIndex = BufferOffset
  ColCounter = TilemapCols
  'PixelStripWrap = TilemapWidth * 16
  PixelStripWrap = 320'TilemapWidth * 8
  PixelStripDest = 0
  'ByteDestRow& = 0
  TileImageDest& = &HA000
  GOTO TTRInsideTopLoop
  DO                                    'translate top strip of 16x16 tiles
    CurTileIndex = CurTileIndex + 1
TTRInsideTopLoop:
    ColCounter = ColCounter - 1
    'IF CurTileIndex AND 1 THEN
    '    TileUnitValue = (FileBuffer(CurTileIndex \ 2) AND 65280) \ 256
    'ELSE
    '    TileUnitValue = FileBuffer(CurTileIndex \ 2) AND 255'4095
    'END IF
    TileUnitValue = FileBuffer(CurTileIndex) AND 1023
    'IF TileUnitValue = &H111 THEN STOP
    'TileWord = TileUnitValue
    TileWord = TileTable(TileUnitValue * 4)         'look up value in table
    GOSUB ConvertTileWord                           'pass it to converter
    PixelStripDest = PixelStripDest + 8
    TileWord = TileTable(TileUnitValue * 4 + 1)
    GOSUB ConvertTileWord
    PixelStripDest = PixelStripDest + 8
  LOOP WHILE ColCounter > 0
  'output to file
  CurTileIndex = BufferOffset
  ColCounter = TilemapCols
  ByteDestRow& = ByteDestRow& + 2560
  PixelStripDest = 0
  GOTO TTRInsideBtmLoop
  DO                                                'translate bottom strip
    CurTileIndex = CurTileIndex + 1
TTRInsideBtmLoop:
    'IF CurTileIndex AND 1 THEN
    '    TileUnitValue = (FileBuffer(CurTileIndex \ 2) AND 65280) \ 256
    'ELSE
    '    TileUnitValue = FileBuffer(CurTileIndex \ 2) AND 255'4095
    'END IF
    TileUnitValue = FileBuffer(CurTileIndex) AND 1023
    ColCounter = ColCounter - 1
    'TileUnitValue = FileBuffer(CurTileIndex) AND 255'4095
    'TileWord = TileUnitValue
    TileWord = TileTable(TileUnitValue * 4 + 2)'look up value in table
    GOSUB ConvertTileWord                           'pass it to converter
    PixelStripDest = PixelStripDest + 8
    TileWord = TileTable(TileUnitValue * 4 + 3)
    GOSUB ConvertTileWord
    PixelStripDest = PixelStripDest + 8
  LOOP WHILE ColCounter > 0
  'output to file

  TilemapFilePos& = TilemapFilePos& + TilemapWidth' * 2
  ByteDestRow& = ByteDestRow& + 2560
  IF ByteDestRow& >= 61440 THEN ByteDestRow& = 0
RETURN

ConvertTileWord:
  'it is simply passed TileWord and PixelStripDest
  TilePalette = (TileWord AND 7168) \ TilePaletteSize '+TilePaletteBase
  TileChar = TileWord AND TileCharMask
  FlipHrz = TileWord AND 16384
  FlipVrt = TileWord AND -32768
 
  ByteSource& = TileGraphicsBase& + TileChar * TileByteSize&
  IF FlipVrt THEN
    ByteDest& = PixelStripDest + ByteDestRow& + 7 * PixelStripWrap
    ByteDestInc = -PixelStripWrap
    'ByteDestInc = -320
  ELSE
    ByteDest& = PixelStripDest + ByteDestRow&
    ByteDestInc = PixelStripWrap
    'ByteDestInc = 320
  END IF
 
  FOR BplRow = 0 TO 7
    p0 = 0: p1 = 0: p2 = 0: p3 = 0: p4 = 0: p5 = 0: p6 = 0: p7 = 0
    BitMask = 1
    DEF SEG = VARSEG(VramGraphics(0))
    SubByteSource& = ByteSource&
    FOR BplPlane = 0 TO LastBitplane STEP 2
      Byte = PEEK(SubByteSource&)
      IF Byte AND 1 THEN p0 = p0 OR BitMask
      IF Byte AND 2 THEN p1 = p1 OR BitMask
      IF Byte AND 4 THEN p2 = p2 OR BitMask
      IF Byte AND 8 THEN p3 = p3 OR BitMask
      IF Byte AND 16 THEN p4 = p4 OR BitMask
      IF Byte AND 32 THEN p5 = p5 OR BitMask
      IF Byte AND 64 THEN p6 = p6 OR BitMask
      IF Byte AND 128 THEN p7 = p7 OR BitMask
      BitMask = BitMask * 2
      Byte = PEEK(SubByteSource& + 1)
      IF Byte AND 1 THEN p0 = p0 OR BitMask
      IF Byte AND 2 THEN p1 = p1 OR BitMask
      IF Byte AND 4 THEN p2 = p2 OR BitMask
      IF Byte AND 8 THEN p3 = p3 OR BitMask
      IF Byte AND 16 THEN p4 = p4 OR BitMask
      IF Byte AND 32 THEN p5 = p5 OR BitMask
      IF Byte AND 64 THEN p6 = p6 OR BitMask
      IF Byte AND 128 THEN p7 = p7 OR BitMask
      BitMask = BitMask * 2
      SubByteSource& = SubByteSource& + 16
    NEXT BplPlane
    DEF SEG = TileImageDest&
    'DEF SEG = &HA000
    IF FlipHrz THEN
      POKE ByteDest&, p0 + TilePalette
      POKE ByteDest& + 1, p1 + TilePalette
      POKE ByteDest& + 2, p2 + TilePalette
      POKE ByteDest& + 3, p3 + TilePalette
      POKE ByteDest& + 4, p4 + TilePalette
      POKE ByteDest& + 5, p5 + TilePalette
      POKE ByteDest& + 6, p6 + TilePalette
      POKE ByteDest& + 7, p7 + TilePalette
    ELSE
      POKE ByteDest& + 7, p0 + TilePalette
      POKE ByteDest& + 6, p1 + TilePalette
      POKE ByteDest& + 5, p2 + TilePalette
      POKE ByteDest& + 4, p3 + TilePalette
      POKE ByteDest& + 3, p4 + TilePalette
      POKE ByteDest& + 2, p5 + TilePalette
      POKE ByteDest& + 1, p6 + TilePalette
      POKE ByteDest&, p7 + TilePalette
    END IF
    ByteSource& = ByteSource& + 2
    ByteDest& = ByteDest& + ByteDestInc
  NEXT BplRow
RETURN

TranslateTilemapSingleRow:
  'make sure needed data is in buffer, load it in if not
  BufferOffset& = TilemapFilePos& - FileBufferBase&
  IF BufferOffset& + TilemapWidth * 2 > FileBufferSize THEN
    'SEEK TilemapFile, TilemapFilePos&
    SEEK 1, TilemapFilePos&
    DosReadRegs.Ax = &H3F00
    DosReadRegs.Bx = FILEATTR(1, 2)
    DosReadRegs.Cx = -32768
    DosReadRegs.Ds = VARSEG(FileBuffer(0))
    DosReadRegs.Dx = VARPTR(FileBuffer(0))
    CALL interruptx(&H21, DosReadRegs, Regs)
    BufferOffset& = 0
    FileBufferBase& = TilemapFilePos&
  END IF

  BufferOffset = BufferOffset& \ 2
  CurTileIndex = BufferOffset
  ColCounter = TilemapCols
  ByteDestRow& = 0
  PixelStripWrap = 320'TilemapWidth * 8
  PixelStripDest = 0
  GOTO TTSRInsideTopLoop
  DO
    CurTileIndex = CurTileIndex + 1
TTSRInsideTopLoop:
    ColCounter = ColCounter - 1
    TileWord = FileBuffer(CurTileIndex)
    'PRINT TileWord;
    TileImageDest& = &HA000'VARSEG(PixelStrip(0))
    PixelStripWrap = 320
    GOSUB ConvertTileWord                           'pass it to converter
    TileImageDest& = VARSEG(PixelStrip(0))
    PixelStripWrap = TilemapWidth * 8
    GOSUB ConvertTileWord                           'pass it to converter
    PixelStripDest = PixelStripDest + 8
  LOOP WHILE ColCounter > 0
  GOSUB OutputImageRowToFile
  'output to file
  TilemapFilePos& = TilemapFilePos& + TilemapWidth * 2
  'ByteDestRow& = ByteDestRow& + 2560
  'IF ByteDestRow& >= 61440 THEN ByteDestRow& = 0
RETURN

OutputImageHeader:
  IF LEN(FileImageOutput$) = 0 THEN RETURN
  TotalColPixels = TilemapWidth * TileColWidth
  TotalRowPixels = TilemapHeight * TileRowHeight
  PRINT #4, CHR$(10); CHR$(5); CHR$(1); CHR$(8); MKL$(0); MKI$(TotalColPixels - 1); MKI$(TotalRowPixels - 1); MKI$(TotalColPixels); MKI$(TotalRowPixels); STRING$(49, 0); CHR$(1); MKI$(TotalColPixels); MKI$(0); STRING$(58, 0);
  SEEK 4, 129
RETURN

OutputImageRowToFile:
  IF LEN(FileImageOutput$) = 0 THEN RETURN
  DEF SEG = VARSEG(PixelStrip(0))
  ByteSrcPos& = 0
  ByteDstPos& = 16384
  TotalPixels = TileRowHeight * TilemapWidth * TileColWidth
  IF TotalPixels > 8192 THEN ERROR 200
  'FOR RowCounter = 1 TO TotalPixels
  '  DataByte = PEEK(ByteSrcPos&)
  '  ByteSrcPos& = ByteSrcPos& + 1
  '  'IF DataByte >= 192 THEN
  '  '  POKE ByteDstPos&, 193
  '  '  POKE ByteDstPos& + 1, DataByte
  '  '  ByteDstPos& = ByteDstPos& + 2
  '  'ELSE
  '    POKE ByteDstPos&, DataByte AND 127
  '    ByteDstPos& = ByteDstPos& + 1
  '  'END IF
  'NEXT RowCounter
  DosReadRegs.Ax = &H4000
  DosReadRegs.Bx = FILEATTR(4, 2)
  DosReadRegs.Ds = VARSEG(PixelStrip(0))
  DosReadRegs.Dx = 0'16384
  DosReadRegs.Cx = TotalPixels'ByteDstPos& - 16384
  CALL interruptx(&H21, DosReadRegs, Regs)
RETURN

GetBankTable:
  SEEK 2, TiletableFileBase& + 1
  DosReadRegs.Ax = &H3F00
  DosReadRegs.Bx = FILEATTR(2, 2)
  DosReadRegs.Cx = -32768
  DosReadRegs.Ds = VARSEG(TileTable(0))
  DosReadRegs.Dx = VARPTR(TileTable(0))
  CALL interruptx(&H21, DosReadRegs, Regs)
RETURN

OutputImagePalette:
  IF LEN(FileImageOutput$) = 0 THEN RETURN
  PRINT #4, CHR$(12);
  DEF SEG = VARSEG(ColorPalette(0))
  FOR ByteSource = 0 TO 1023 STEP 4
    PRINT #4, CHR$(PEEK(ByteSource) * 4);
    PRINT #4, CHR$(PEEK(ByteSource + 1) * 4);
    PRINT #4, CHR$(PEEK(ByteSource + 2) * 4);
  NEXT ByteSource
RETURN

SetColorPalette:
  OUT &H3C8, 0
  DEF SEG = VARSEG(ColorPalette(0))
  ByteSource = 0
  FOR Count = 0 TO 255
    OUT &H3C9, PEEK(ByteSource + 0)' \ 2
    OUT &H3C9, PEEK(ByteSource + 1)' \ 2
    OUT &H3C9, PEEK(ByteSource + 2)' \ 2
    ByteSource = ByteSource + 4
  NEXT Count
  PALETTE 0, 0
  PALETTE 15, 4144959
RETURN

BushSearch:
  FOR a = 0 TO 16383
    IF TileTable(a) = 6528 THEN STOP
  NEXT a
RETURN

