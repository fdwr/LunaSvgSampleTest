'Show Tile Map
'Peekin
'2001-05-03
'
'Displays a scrollable map, imported from any offset in a file, shown with
'graphics imported from an SNES savestate.

DEFINT A-Z
DECLARE SUB StatusLine (Text AS STRING)
DECLARE SUB EnsureFileExists (FileName AS STRING)
DECLARE SUB UserWait ()

CONST ScreenHeight = 192
CONST ScreenWidth = 320

CONST TileModeClr = 0
CONST TileModeSnesMode7 = 1
CONST TileModeSnesBpl = 2 'not implemented

CONST MaxScrollRate = 5

TYPE RegType
  ax AS INTEGER: bx AS INTEGER: cx AS INTEGER: dx AS INTEGER
  bp AS INTEGER: si AS INTEGER: di AS INTEGER: fl AS INTEGER
  ds AS INTEGER: es AS INTEGER
END TYPE

REDIM TileMap(16383) AS LONG, TileGfx(16383) AS LONG, Vram(16383) AS LONG
DIM ColorPalette(255) AS LONG, TileColorMap(1023)
DIM SrcPtr AS LONG, DestPtr AS LONG
DIM Now AS SINGLE, ScrollTime AS SINGLE
DIM VramFilename AS STRING, VramFilePos AS LONG
DIM MapFilename AS STRING, MapFilePos AS LONG
DIM ScrollScreen(53)
DIM SHARED Regs AS RegType, TempRegs AS RegType, ErrHandled
DIM SHARED BrightClr


'RESTORE ScrollScreenCode
FOR Count = 0 TO UBOUND(ScrollScreen)
    READ ScrollScreen(Count)
NEXT
ScrollScreenCode:
DATA &H1E9C,&H5506,&HE589,&H00B8,&H8EA0,&H8ED8,&H8BC0,&H0C46
DATA &HC0BB,&HBE00,&H0140,&HD8F7,&HF289,&H0E7F,&HC301,&H457E
DATA &HC0BF,&H05EE,&H00BF,&HDAF7,&H06EB,&HC329,&H377E,&HFF31
DATA &HAF0F,&H8BF0,&H0E4E,&H40B8,&H8501,&H7EC9,&H2910,&H7EC8
DATA &H0124,&H81C6,&H3EC7,&H8301,&H02EE,&HEBFD,&H0107,&H7EC8
DATA &H2914,&HFCCE,&HE8D1,&H5756,&HC189,&HA5F3,&H5E5F,&HD701
DATA &HD601,&H7F4B,&H5DF1,&H1F07,&HCA9D,&H0004


'MapFilename = "c:\pics\vg\sommap.bmp"
'MapFilename = "c:\emu\saves\som.zs4"
MapFilename = "som.zs4"
MapFilePos = &H10C13 'read 128x512 map in upper 64k of WRAM (7F0000h)
'VramFilename = "c:\emu\saves\mariokrt.zs1"
VramFilename = MapFilename
VramFilePos = &H20C13

PRINT "Show Tilemap - simple scrollable tilemap viewer"
PRINT "PeekinSoŸt (2001-05-03)"
PRINT
PRINT "Keys:"
PRINT "  Up/Down     scroll vertically (press more for faster scroll)"
PRINT "  Left/Right  scroll horizontally"
PRINT "  Home/End    page horizontally"
PRINT "  PgUp/PgDn   page vertically"
PRINT "  Space       preview (thumbnail)"
PRINT "  Esc         quit";
UserWait

SCREEN 13

GOSUB SetTileMode
GOSUB DetermineMapBoundary

'init screen
SCREEN 13
BrightClr = 15

'should load a file specified on command line
GOSUB LoadVram
GOSUB LoadTilemap
GOSUB CacheVram
GOSUB SetPalette

Redraw = -1
DO
    key$ = INKEY$
    SELECT CASE key$
    CASE ""
        'check mouse input
        IF Redraw THEN
            IF Redraw AND 2 THEN 'redraw entire map
                TopRedraw = 0
                BtmRedraw = MapRows
                LeftRedraw = 0
                RightRedraw = MapCols
                GOSUB RedrawMap
            ELSEIF Redraw AND 1 THEN 'scroll map, redrawing only new portions  
                GOSUB ScrollMap
            END IF

            COLOR BrightClr
            LOCATE 25, 1: PRINT MapRow; MapCol;
            Redraw = 0
        END IF
    CASE CHR$(0) + "H": IF ScrollRow > 0 THEN ScrollRow = 0 ELSE IF ScrollRow > -MaxScrollRate THEN ScrollRow = ScrollRow - 1
    CASE CHR$(0) + "P": IF ScrollRow < 0 THEN ScrollRow = 0 ELSE IF ScrollRow < MaxScrollRate THEN ScrollRow = ScrollRow + 1
    CASE CHR$(0) + "K": IF ScrollCol > 0 THEN ScrollCol = 0 ELSE IF ScrollCol > -MaxScrollRate THEN ScrollCol = ScrollCol - 1
    CASE CHR$(0) + "M": IF ScrollCol < 0 THEN ScrollCol = 0 ELSE IF ScrollCol < MaxScrollRate THEN ScrollCol = ScrollCol + 1
    CASE CHR$(0) + "I": Row = -MapRows: Col = 0: GOSUB AdjustMapOrigin
    CASE CHR$(0) + "Q": Row = MapRows: Col = 0:  GOSUB AdjustMapOrigin
    CASE CHR$(0) + "G": Row = 0: Col = -MapCols: GOSUB AdjustMapOrigin
    CASE CHR$(0) + "O": Row = 0: Col = MapCols:  GOSUB AdjustMapOrigin
    CASE " ": GOSUB ShowPreview: ScrollRow = 0: ScrollCol = 0: Redraw = Redraw OR 2
    CASE CHR$(27): EXIT DO
    END SELECT

    IF ScrollRow OR ScrollCol THEN
        Now = TIMER
        IF Now <> ScrollTime THEN
            ScrollTime = Now

            Row = MapRow + ScrollRow
            Col = MapCol + ScrollCol
            GOSUB ScrollMapOrigin
        END IF
    END IF
LOOP

END

DetermineMapBoundary:
'determines scrollable edges of map,
'centering them if the map is less than the screen size
    IF MapHeight < MapRows THEN
        TopBound = (MapRows - MapHeight) \ -2
        BtmBound = TopBound
    ELSE
        TopBound = 0
        BtmBound = MapHeight - MapRows
    END IF
    IF MapWidth < MapCols THEN
        LeftBound = (MapCols - MapWidth) \ -2
        RightBound = LeftBound
    ELSE
        LeftBound = 0
        RightBound = MapWidth - MapCols
    END IF
RETURN

AdjustMapOrigin:
    ScrollRow = 0
    ScrollCol = 0
    Row = MapRow + Row
    Col = MapCol + Col

ScrollMapOrigin:
'moves the map origin, stopping the scrolling when edge is reached
    IF Row < TopBound THEN
        Row = TopBound
        IF Row <= MapRow THEN ScrollRow = 0
    ELSEIF Row > BtmBound THEN
        Row = BtmBound
        IF Row >= MapRow THEN ScrollRow = 0
    END IF
    IF Col < LeftBound THEN
        Col = LeftBound
        IF Col <= MapCol THEN ScrollCol = 0
    ELSEIF Col > RightBound THEN
        Col = RightBound
        IF Col >= MapCol THEN ScrollCol = 0
    END IF
    IF Row <> MapRow OR Col <> MapCol THEN
        Redraw = Redraw OR 1
        MapRow = Row
        MapCol = Col
    END IF
RETURN

ScrollMap:
    'determine difference between last redraw and current position
    RowDif = MapRowOld - MapRow
    ColDif = MapColOld - MapCol
    IF RowDif = 0 AND ColDif = 0 THEN RETURN

    'scroll tiles already on screen
    DEF SEG = VARSEG(ScrollScreen(0))
    CALL Absolute(BYVAL ColDif * TileWidth, BYVAL RowDif * TileHeight, VARPTR(ScrollScreen(0)))

    'redraw new portions, starting with top/bottom
    IF RowDif THEN
        LeftRedraw = 0
        RightRedraw = MapCols
        IF RowDif > 0 THEN 'MapRow < MapRowOld
            TopRedraw = 0
            BtmRedraw = RowDif
        ELSE 'MapRow > MapRowOld
            TopRedraw = MapRows + RowDif
            BtmRedraw = MapRows
        END IF
        GOSUB RedrawMap
    END IF
    'redraw left/right side
    IF ColDif THEN
        IF ColDif > 0 THEN 'MapCol < MapColOld
            LeftRedraw = 0
            RightRedraw = ColDif
        ELSE 'MapCol > MapColOld
            LeftRedraw = MapCols + ColDif
            RightRedraw = MapCols
        END IF
        IF RowDif <= 0 THEN TopRedraw = 0 ELSE TopRedraw = RowDif
        IF RowDif >= 0 THEN BtmRedraw = MapRows ELSE BtmRedraw = MapRows + RowDif

        GOSUB RedrawMap
    END IF
    MapRowOld = MapRow
    MapColOld = MapCol
RETURN

RedrawMap:
    IF TopRedraw < 0 THEN TopRedraw = 0
    IF BtmRedraw > MapRows THEN BtmRedraw = MapRows
    IF LeftRedraw < 0 THEN LeftRedraw = 0
    IF RightRedraw > MapCols THEN RightRedraw = MapCols

    'draw top/bottom blank areas
    LeftCol = LeftRedraw * TileWidth
    RightCol = RightRedraw * TileWidth - 1
    Row = -MapRow
    IF TopRedraw < Row THEN 'draw top blank area
        IF Row > MapRows THEN Row = MapRows
        LINE (LeftCol, TopRedraw * TileHeight)-(RightCol, Row * TileHeight - 1), 0, BF
        TopRedraw = Row
    END IF
    Row = MapHeight - MapRow
    IF BtmRedraw > Row THEN 'draw bottom blank area
        IF Row < 0 THEN Row = 0
        LINE (LeftCol, Row * TileHeight)-(RightCol, BtmRedraw * TileHeight - 1), 0, BF
        BtmRedraw = Row
    END IF

    'draw left/right blank areas
    IF TopRedraw < BtmRedraw THEN
        TopRow = TopRedraw * TileHeight
        BtmRow = BtmRedraw * TileHeight - 1
        Col = -MapCol
        IF LeftRedraw < Col THEN 'draw blank left area
            IF Col > MapCols THEN Col = MapCols
            LINE (LeftRedraw * TileWidth, TopRow)-(Col * TileWidth - 1, BtmRow), 0, BF
            LeftRedraw = Col
        END IF
        Col = MapWidth - MapCol
        IF RightRedraw > Col THEN 'draw right blank area
            IF Col < 0 THEN Col = 0
            LINE (Col * TileWidth, TopRow)-(RightRedraw * TileWidth - 1, BtmRow), 0, BF
            RightRedraw = Col
        END IF
    END IF

    'draw tiles
    DEF SEG = VARSEG(TileMap(0))
    Row = TopRedraw * TileHeight
    LeftCol = LeftRedraw * TileWidth
    SrcWrap = RightRedraw - LeftRedraw
    SrcWrap = (MapWidth - SrcWrap) * TileBytes
    SrcPtr = (CLNG(TopRedraw + MapRow) * MapWidth + (LeftRedraw + MapCol)) * TileBytes
    FOR RowCount = TopRedraw TO BtmRedraw - 1
        Col = LeftCol
        FOR ColCount = LeftRedraw TO RightRedraw - 1
            PUT (Col, Row), TileGfx(PEEK(SrcPtr) * 17), PSET
            Col = Col + TileWidth
            SrcPtr = SrcPtr + TileBytes
        NEXT
        Row = Row + TileHeight
        SrcPtr = SrcPtr + SrcWrap
    NEXT
RETURN

SetTileMode:
'cheap hack for now
    TileMode = TileModeSnesMode7
    TileHeight = 8
    TileWidth = 8
    TileBytes = 1
    TileGfxBytes = TileHeight * TileWidth
    TotalTiles = 256
    MapHeight = 102
    MapWidth = 512
    MapRows = ScreenHeight \ TileHeight
    MapCols = ScreenWidth \ TileWidth
    MapRow = (MapHeight - MapRows) \ 2
    MapCol = (MapWidth - MapCols) \ 2
    MapRowOld = MapRow
    MapColOld = MapCol
RETURN

LoadVram:
    StatusLine "Loading VRAM..."

    EnsureFileExists VramFilename
    OPEN VramFilename FOR BINARY AS 1
    SEEK 1, VramFilePos + 1
    Regs.ax = &H3F00 'DOS: Read file
    Regs.bx = FILEATTR(1, 2)
    Regs.cx = -32768
    Regs.ds = VARSEG(Vram(0))
    Regs.dx = VARPTR(Vram(0))

    CALL interruptx(&H21, Regs, TempRegs) 'read first 32k VRAM
    Regs.dx = VARPTR(Vram(8192))
    CALL interruptx(&H21, Regs, TempRegs) 'read second 32k

    'expand SNES's 15bit palette in CGRAM to more usable 3 bytes
    REDIM SnesCgram(255)
    SEEK 1, 1561
    Regs.cx = 512
    Regs.ds = VARSEG(SnesCgram(0))
    Regs.dx = VARPTR(SnesCgram(0))
    CALL interruptx(&H21, Regs, Regs)
    DEF SEG = VARSEG(ColorPalette(0))
    DestPtr = VARPTR(ColorPalette(1))
    FOR Count = 1 TO 255
        Value = SnesCgram(Count)
        POKE DestPtr, (Value AND 31) * 2
        POKE DestPtr + 1, (Value AND 992) \ 16
        POKE DestPtr + 2, (Value AND 31744) \ 512
        DestPtr = DestPtr + 4
    NEXT
    ERASE SnesCgram
   
    CLOSE 1
RETURN

SetPalette:
    DEF SEG = VARSEG(ColorPalette(0))
    SrcPtr = VARPTR(ColorPalette(1))
    BrightClr = 15
    HighValue = 0
    OUT &H3C8, 1
    FOR Count = 1 TO 255
        OUT &H3C9, PEEK(SrcPtr)
        OUT &H3C9, PEEK(SrcPtr + 1)
        OUT &H3C9, PEEK(SrcPtr + 2)
        Value = PEEK(SrcPtr) + PEEK(SrcPtr + 1) + PEEK(SrcPtr + 2)
        IF Value > HighValue THEN HighValue = Value: BrightClr = Count
        SrcPtr = SrcPtr + 4
    NEXT
    IF HighValue < 141 THEN PALETTE 15, &H3F3F3F: BrightClr = 15
RETURN

LoadTilemap:
'  0    |   2    | (BM) - Tells us that the picture is in bmp format
'  2    |   4    | Size of the file (without header?)
'  6    |   2    | (0) Reserved1 - Must be zero
'  8    |   2    | (0) Reserved2 - Must be zero
'  10   |   4    | Number of bytes offset of the picture data
'-------+--------+--- Information Header starts here -----------------
'  14   |   4    | (40/12) Size of information header (Win3.1/OS2)
'  18   |   4    | Picture width in pixels
'  22   |   4    | Picture Height in pixels
'  26   |   2    | (1) Number of planes, must be 1
'  28   |   2    | Number of bits per pixel (bpp), must be 1,4,8 or 24
'  30   |   4    | (0) Compression - 0 means no compression, 1,2 are RLEs
'  34   |   4    | Image size in bytes
'  38   |   4    | picture width in pels per metre
'  42   |   4    | picture height in pels per metre
'  46   |   4    | (0) Number of colours used in the picture, 0 means all
'  50   |   4    | (0) Number of important colours, 0 means all
    StatusLine "Loading tilemap..."

    EnsureFileExists MapFilename
    OPEN MapFilename FOR BINARY AS 1
    SEEK 1, MapFilePos + 1
    Regs.ax = &H3F00 'DOS: Read file
    Regs.bx = FILEATTR(1, 2)
    Regs.cx = -32768
    Regs.ds = VARSEG(TileMap(0))
    Regs.dx = VARPTR(TileMap(0))
    CALL interruptx(&H21, Regs, TempRegs) 'read first 32k VRAM
    Regs.dx = VARPTR(TileMap(8192))
    CALL interruptx(&H21, Regs, TempRegs) 'read second 32k
    CLOSE 1
    StatusLine "Tilemap loaded"
RETURN

LoadVramMap:
'reads in the 128x128 mode 7 map from VRAM
    StatusLine "Loading tilemap..."
    SrcSeg = VARSEG(Vram(0))
    SrcPtr = VARPTR(Vram(0))
    DestSeg = VARSEG(TileMap(0))
    DestPtr = VARPTR(TileMap(0))
    FOR Count = 0 TO MapHeight * MapWidth - 1
        DEF SEG = SrcSeg
        Value = PEEK(SrcPtr)
        DEF SEG = DestSeg
        POKE DestPtr, Value
        SrcPtr = SrcPtr + 2
        DestPtr = DestPtr + 1
    NEXT
    StatusLine "Tilemap loaded"
RETURN

CacheVram:
'caches tile graphics from VRAM
    StatusLine "Caching VRAM..."
    SELECT CASE TileMode
    CASE TileModeSnesMode7
        SrcSeg = VARSEG(Vram(0))
        SrcPtr = VARPTR(Vram(0)) + 1
        DestSeg = VARSEG(TileGfx(0))
        DestPtr = VARPTR(TileGfx(0))
        FOR Count = 0 TO 255
            TileGfx(Count * 17) = 524352
            DestPtr = DestPtr + 4
            FOR Count2 = 0 TO 63
                DEF SEG = SrcSeg
                Value = PEEK(SrcPtr)
                DEF SEG = DestSeg
                POKE DestPtr, Value
                SrcPtr = SrcPtr + 2
                DestPtr = DestPtr + 1
            NEXT
        NEXT
    CASE TileModeSnesBpl
    END SELECT

    StatusLine "VRAM cached"
RETURN

ShowPreview:
'shows small preview of map
    IF NOT TilesColorMapped THEN GOSUB ColorMapTiles

    'center horizontally
    SrcWrap = MapWidth - ScreenWidth
    Col = 0
    IF SrcWrap >= 0 THEN
        LeftRedraw = 0
        RightRedraw = ScreenWidth - 1
        Col = MapCol - (ScreenWidth - MapCols) \ 2
        IF Col < 0 THEN
            Col = 0
        ELSEIF Col + ScreenWidth > MapWidth THEN
            Col = MapWidth - ScreenWidth
        END IF
    ELSE
        SrcWrap = 0
        LeftRedraw = SrcWrap \ 2
        RightRedraw = LeftRedraw + MapWidth - 1
    END IF

    'center vertically
    Row = 0
    IF MapHeight >= ScreenHeight THEN
        TopRedraw = 0
        BtmRedraw = ScreenHeight - 1
        Row = MapRow - (ScreenHeight - MapRows) \ 2
        IF Row < 0 THEN
            ColCount = 0
        ELSEIF Row + ScreenHeight > MapHeight THEN
            Row = MapHeight - ScreenHeight
        END IF
    ELSE
        TopRedraw = (ScreenHeight - MapHeight) \ 2
        BtmRedraw = TopRedraw + MapHeight - 1
    END IF
   
    DEF SEG = VARSEG(TileMap(0))
    SrcPtr = (Row * MapWidth) + Col

    'draw tilemap
    CLS
    FOR RowCount = TopRedraw TO BtmRedraw
        FOR ColCount = LeftRedraw TO RightRedraw
            PSET (ColCount, RowCount), TileColorMap(PEEK(SrcPtr))
            SrcPtr = SrcPtr + TileBytes
        NEXT
        SrcPtr = SrcPtr + SrcWrap
    NEXT
    
    'draw border to indicate current viewing area
    Col = LeftRedraw + MapCol - Col
    Row = TopRedraw + MapRow - Row
    LINE (Col - 1, Row - 1)-(Col + MapCols, Row + MapRows), BrightClr, B

    UserWait
RETURN

ColorMapTiles:
'maps every tile number to a palette index by finding each one's dominate color
    StatusLine "Calculating tile color map..."
    DEF SEG = VARSEG(TileGfx(0))
    SrcPtr = VARPTR(TileGfx(0))
    FOR Count = 0 TO TotalTiles - 1
        REDIM ColorCounts(255)
        SrcPtr = SrcPtr + 4
        FOR Count2 = 0 TO TileGfxBytes - 1
            Value = PEEK(SrcPtr)
            ColorCounts(Value) = ColorCounts(Value) + 1
            SrcPtr = SrcPtr + 1
        NEXT
        Value = 1
        HighValue = 0
        FOR Count2 = 0 TO 255
            IF ColorCounts(Count2) > HighValue THEN HighValue = ColorCounts(Count2): Value = Count2
        NEXT
        TileColorMap(Count) = Value
    NEXT
    ERASE ColorCounts
    TilesColorMapped = -1
RETURN

ErrHandler:
    ErrHandled = ERR
RESUME NEXT

SUB EnsureFileExists (FileName AS STRING)

ON ERROR GOTO ErrHandler
OPEN FileName FOR INPUT AS 1: CLOSE 1
IF ErrHandled <> 0 THEN
    PRINT "Could not open " + FileName
    UserWait
    END
END IF
ON ERROR GOTO 0

END SUB

SUB StatusLine (Text AS STRING)
COLOR BrightClr
LOCATE 25, 1
PRINT LEFT$(Text, 39); TAB(40);
END SUB

SUB UserWait

DO: LOOP WHILE LEN(INKEY$)
DO: LOOP UNTIL LEN(INKEY$)

END SUB

