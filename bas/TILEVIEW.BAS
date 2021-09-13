'1999-07-27
DEFINT A-Z

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
BP AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

CONST FileBufferSize = 8192, ViewFileHandle = 1
DIM SHARED ViewFile$, VramFile$
DIM SHARED DTA AS STRING * 44, Regs AS RegType
DIM SHARED FileBuffer AS STRING * FileBufferSize, Vram(16383) AS LONG
DIM SHARED ColorPalette(767)

'----------------------------------------

GOSUB SetDTA

SCREEN 13

'ViewFile$ = "c:\temp\emu\zelda.smc"
'VramFile$ = "c:\temp\emu\zelda.zst"
ViewFile$ = "c:\temp\emu\dkc1.smc"
'ViewFile$ = "c:\temp\emu\mario2.smc"
'ViewFile$ = "c:\temp\emu\mario2.zs1"
'VramFile$ = "c:\temp\emu\mario2.zs1"
VramFile$ = "c:\temp\emu\dkc1.zs7"
VramBitdepth = 4
VramGraphicsBase& = 16384'57344'24576'8192'
ViewWindowUpdate = 2
ViewFilePos& = &H20C8FE'&H2DC13'&H2C8468'&H1680'&H349BFD'&H100200'&H19A5C0'&H26A388'&H329912'&H190000'&H1AC100'458871'
'3BF00-3EFA0   Forest
'1AC100-1AF780 Underground caves
'19A5C0-19EE99 Jungle
'20ACD6-20DD15 Snow
'26A388-26C047 Mine track, used with B0000
'100200-104960 Underwater reefs
'2C8028-2CA488 Ruins
'1540-1C40     Candy's Save Point
'329912-329FD1 Cranky's Cabin
'349BFD-34A2FD Funky's Flights
TileWrap = 16

PixelTableFile$ = "c:\dw\src\tmv\zpixtbl.dat"
GOSUB OpenViewingFile
IF Cancel GOTO EndProgram
ViewFileLen& = LOF(ViewFileHandle)
ViewFileBufferPos& = FileBufferSize

'VramBitdepth = ?
'VramGraphicsBase& = ?
GOSUB LoadVramGraphics
IF Cancel GOTO EndProgram

'ViewWindowUpdate = ?
'ViewFilePos& = ?
'TileWrap = ?
GOSUB UserScroll

EndProgram:
    CLOSE
    WIDTH 80, 25
    END

UserScroll:
    'ViewFileBufferPos& = -1
    GOSUB CheckViewFileBuffer
    ViewWindowChange = -1
    DO
        Key$ = INKEY$
        SELECT CASE Key$
        CASE CHR$(0) + "H": NewFilePos& = ViewFilePos& - TileWrap * 2: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "P": NewFilePos& = ViewFilePos& + TileWrap * 2: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "K": NewFilePos& = ViewFilePos& - 2: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "M": NewFilePos& = ViewFilePos& + 2: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "s": NewFilePos& = ViewFilePos& - 1: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "t": NewFilePos& = ViewFilePos& + 1: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "I": NewFilePos& = ViewFilePos& - TileWrap * 32: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "Q": NewFilePos& = ViewFilePos& + TileWrap * 32: GOSUB ChangeViewFilePos
        CASE "g"
            LOCATE 25, 1: LINE INPUT ; "Goto:", Text$: IF LEN(Text$) THEN NewFilePos& = VAL(Text$)
            IF NewFilePos& < 0 THEN NewFilePos& = NewFilePos& + 65536
            GOSUB ChangeViewFilePos
        CASE "f": LOCATE 25, 1: LINE INPUT ; "Find:", Text$: IF LEN(Text$) THEN GOSUB FindHexString
        CASE "F": GOSUB FindString
        CASE "/": NewFilePos& = ViewFilePos& - 32768: GOSUB ChangeViewFilePos
        CASE "*": NewFilePos& = ViewFilePos& + 32768: GOSUB ChangeViewFilePos
        CASE "[": IF TileWrap > 1 THEN NewTileWrap = TileWrap - 1: GOSUB ChangeTileWrap
        CASE "]": IF TileWrap < 32 THEN NewTileWrap = TileWrap + 1: GOSUB ChangeTileWrap
        CASE "{": IF TileWrap > 1 THEN NewTileWrap = TileWrap \ 2: GOSUB ChangeTileWrap
        CASE "}": IF TileWrap <= 16 THEN NewTileWrap = TileWrap * 2: GOSUB ChangeTileWrap
        CASE " ": DisplayMode = (DisplayMode + 1) MOD 2: ViewWindowChange = 2
        CASE "C": GOSUB OutputTilePixelColorTable
        CASE "W": GOSUB SaveSnapshot
        CASE "p"
            UseTilePalette = UseTilePalette XOR 1
            IF UseTilePalette THEN
                GOSUB PaletteSet
            ELSE
                PALETTE
            END IF
        CASE CHR$(13)
            IF ViewWindowUpdate THEN ViewWindowUpdate = 0 ELSE ViewWindowUpdate = 2
        CASE CHR$(27)
            EXIT DO
        CASE ""
            IF ViewWindowChange THEN
                IF ViewWindowChange AND ViewWindowUpdate THEN
                    GOSUB CheckViewFileBuffer
                    GOSUB DisplayViewingWindow
                    ViewWindowChange = 0
                END IF
                LOCATE 25, 1: PRINT "Pos:"; HEX$(ViewFilePos&); TAB(14); "Wrap:"; TileWrap;
            END IF
        END SELECT
    LOOP
RETURN

ChangeViewFilePos:
    IF NewFilePos& < 0 THEN RETURN
    IF NewFilePos& > ViewFileLen& THEN
        IF ViewFilePos& >= ViewFileLen& THEN
            ViewFilePos& = ViewFileLen& - 1
        ELSE
            RETURN
        END IF
    ELSE
        ViewFilePos& = NewFilePos&
    END IF
    ViewWindowChange = 2
RETURN

ChangeTileWrap:
    IF NewTileWrap < TileWrap THEN
        LINE (NewTileWrap * 8, 0)-(TileWrap * 8, 151), 0, BF
    END IF
    TileWrap = NewTileWrap
    ViewWindowChange = 2
RETURN

CheckViewFileBuffer:
    IF ViewFilePos& < ViewFileBufferPos& THEN
        ViewFileBufferPos& = ViewFilePos& - FileBufferSize + 832
        IF ViewFileBufferPos& < 0 THEN ViewFileBufferPos& = 0
    ELSEIF ViewFilePos& > ViewFileBufferPos& + FileBufferSize - 832 THEN
        ViewFileBufferPos& = ViewFilePos&
    ELSE RETURN
    END IF
    GET ViewFileHandle, ViewFileBufferPos& + 1, FileBuffer
RETURN

DisplayViewingWindow:
    SourcePos = ViewFilePos& - ViewFileBufferPos&
    IF ColorsPerTileFactor = 0 THEN STOP
    FOR Row = 0 TO 149 STEP 8
        FOR Col = 0 TO TileWrap * 8 - 1 STEP 8
            DEF SEG = VARSEG(FileBuffer)
            SourceAdr = SourcePos + VARPTR(FileBuffer)
            SELECT CASE DisplayMode
            CASE 0
                LINE (Col, Row)-(Col + 7, Row + 7), PEEK(SourceAdr), BF
            CASE 1
                Word& = PEEK(SourceAdr) + PEEK(SourceAdr + 1) * 256&
                DEF SEG = VARSEG(Vram(0)) + (Word& AND 1023) * 4
                TileSource = 0
                PalBase = (Word& AND 7168) \ ColorsPerTileFactor
                
                IF Word& AND 32768 THEN
                    TileSource = TileSource + 56
                    TileStep = -8
                ELSE
                    TileStep = 8
                END IF
                IF Word& AND 16384 THEN
                    FOR TileRow = Row TO Row + 7
                        PSET (Col, TileRow), PEEK(TileSource + 7) + PalBase
                        PSET (Col + 1, TileRow), PEEK(TileSource + 6) + PalBase
                        PSET (Col + 2, TileRow), PEEK(TileSource + 5) + PalBase
                        PSET (Col + 3, TileRow), PEEK(TileSource + 4) + PalBase
                        PSET (Col + 4, TileRow), PEEK(TileSource + 3) + PalBase
                        PSET (Col + 5, TileRow), PEEK(TileSource + 2) + PalBase
                        PSET (Col + 6, TileRow), PEEK(TileSource + 1) + PalBase
                        PSET (Col + 7, TileRow), PEEK(TileSource) + PalBase
                        TileSource = TileSource + TileStep
                    NEXT TileRow
                ELSE
                    FOR TileRow = Row TO Row + 7
                        PSET (Col, TileRow), PEEK(TileSource) + PalBase
                        PSET (Col + 1, TileRow), PEEK(TileSource + 1) + PalBase
                        PSET (Col + 2, TileRow), PEEK(TileSource + 2) + PalBase
                        PSET (Col + 3, TileRow), PEEK(TileSource + 3) + PalBase
                        PSET (Col + 4, TileRow), PEEK(TileSource + 4) + PalBase
                        PSET (Col + 5, TileRow), PEEK(TileSource + 5) + PalBase
                        PSET (Col + 6, TileRow), PEEK(TileSource + 6) + PalBase
                        PSET (Col + 7, TileRow), PEEK(TileSource + 7) + PalBase
                        TileSource = TileSource + TileStep
                    NEXT TileRow
                END IF
            CASE ELSE
                Word& = PEEK(SourceAdr) + PEEK(SourceAdr + 1) * 256&
                PRINT (Word& AND 1023); 'VARSEG(Vram(0))
            END SELECT
            SourcePos = SourcePos + 2
        NEXT Col
    NEXT Row
RETURN

OpenViewingFile:
    'call OpenFile(FileName$,FileHandle)
    OPEN ViewFile$ FOR INPUT AS ViewFileHandle: CLOSE ViewFileHandle
    OPEN ViewFile$ FOR BINARY AS ViewFileHandle
RETURN

LoadVramGraphics:
    IF LEN(VramFile$) THEN
        VramFileHandle = 2
        OPEN VramFile$ FOR INPUT AS VramFileHandle: CLOSE VramFileHandle
        OPEN VramFile$ FOR BINARY AS VramFileHandle
    ELSE
        VramFileHandle = ViewFileHandle
    END IF

    SEEK VramFileHandle, 1561: Palette$ = INPUT$(512, VramFileHandle)
    BytePos = 1
    FOR Index = 0 TO 767 STEP 3
      ColorValue = CVI(MID$(Palette$, BytePos, 2))
      ColorPalette(Index) = (ColorValue AND 31) * 2
      ColorPalette(Index + 1) = (ColorValue AND 992) \ 16
      ColorPalette(Index + 2) = (ColorValue AND 31744) \ 512
      BytePos = BytePos + 2
    NEXT Index
    ColorsPerTile = 2 ^ VramBitdepth
    ColorsPerTileFactor = 1024 \ ColorsPerTile
    Palette$ = ""
    
    SEEK VramFileHandle, 134164 + VramGraphicsBase&
    VramWrap& = 65536 - VramGraphicsBase&
    TileByteSize = VramBitdepth * 8
    SourcePos = FileBufferSize
    VramDest = 0
    LeftCol = 0
    FOR Tile = 0 TO 1023
        IF SourcePos >= FileBufferSize THEN
            GET VramFileHandle, , FileBuffer
            SourcePos = 0
            VramWrap& = VramWrap& - FileBufferSize
            IF VramWrap& <= 0 THEN VramWrap& = 65536: SEEK VramFileHandle, 134164
        END IF

        RowSourcePos = SourcePos + VARPTR(FileBuffer)
        FOR Row = 0 TO 7
            DEF SEG = VARSEG(FileBuffer)
            BplSourcePos = RowSourcePos
            BitShift = 1
            p1 = 0: p2 = 0: p3 = 0: p4 = 0
            p5 = 0: p6 = 0: p7 = 0: p8 = 0
            FOR Plane = 1 TO VramBitdepth STEP 2
                Byte = PEEK(BplSourcePos)
                IF Byte AND 128 THEN p1 = p1 OR BitShift
                IF Byte AND 64 THEN p2 = p2 OR BitShift
                IF Byte AND 32 THEN p3 = p3 OR BitShift
                IF Byte AND 16 THEN p4 = p4 OR BitShift
                IF Byte AND 8 THEN p5 = p5 OR BitShift
                IF Byte AND 4 THEN p6 = p6 OR BitShift
                IF Byte AND 2 THEN p7 = p7 OR BitShift
                IF Byte AND 1 THEN p8 = p8 OR BitShift
                BitShift = BitShift * 2
                Byte = PEEK(BplSourcePos + 1)
                IF Byte AND 128 THEN p1 = p1 OR BitShift
                IF Byte AND 64 THEN p2 = p2 OR BitShift
                IF Byte AND 32 THEN p3 = p3 OR BitShift
                IF Byte AND 16 THEN p4 = p4 OR BitShift
                IF Byte AND 8 THEN p5 = p5 OR BitShift
                IF Byte AND 4 THEN p6 = p6 OR BitShift
                IF Byte AND 2 THEN p7 = p7 OR BitShift
                IF Byte AND 1 THEN p8 = p8 OR BitShift
                BitShift = BitShift * 2
                BplSourcePos = BplSourcePos + 16
            NEXT Plane
            RowSourcePos = RowSourcePos + 2
            DEF SEG = VARSEG(Vram(0))
            POKE VramPos&, p1
            POKE VramPos& + 1, p2
            POKE VramPos& + 2, p3
            POKE VramPos& + 3, p4
            POKE VramPos& + 4, p5
            POKE VramPos& + 5, p6
            POKE VramPos& + 6, p7
            POKE VramPos& + 7, p8
            VramPos& = VramPos& + 8

            PSET (LeftCol, Row), p1
            PSET (LeftCol + 1, Row), p2
            PSET (LeftCol + 2, Row), p3
            PSET (LeftCol + 3, Row), p4
            PSET (LeftCol + 4, Row), p5
            PSET (LeftCol + 5, Row), p6
            PSET (LeftCol + 6, Row), p7
            PSET (LeftCol + 7, Row), p8
        NEXT Row
        LeftCol = (LeftCol + 8) AND 255
        SourcePos = SourcePos + TileByteSize
    NEXT Tile
    IF VramFileHandle <> ViewFileHandle THEN CLOSE VramFileHandle
RETURN

SetDTA:
    Regs.Ax = &H1A00                   'Set DTA function
    Regs.Dx = VARPTR(DTA)              'DS:DX points to our DTA
    Regs.Ds = -1                       'Use current value for DS
    CALL InterruptX(&H21, Regs, Regs)
RETURN

PaletteSet:
    OUT &H3C8, 0
    FOR Index = 0 TO 767 STEP 3
        OUT &H3C9, ColorPalette(Index)
        OUT &H3C9, ColorPalette(Index + 1)
        OUT &H3C9, ColorPalette(Index + 2)
    NEXT Index
RETURN

OutputTilePixelColorTable:
    LOCATE 25, 1: PRINT "Writing pixel color table..."
    OPEN PixelTableFile$ FOR OUTPUT AS 3
    FOR PalBase = 0 TO 7 * ColorsPerTile STEP ColorsPerTile
        LOCATE 25, 1: PRINT PalBase;
        FOR Tile = 0 TO 1023
            DEF SEG = VARSEG(Vram(0)) + Tile * 4
            Red = 0: Green = 0: Blue = 0
            FOR BytePos = 0 TO 63
                Index = (PEEK(BytePos) + PalBase) * 3
                Red = Red + ColorPalette(Index)
                Green = Green + ColorPalette(Index + 1)
                Blue = Blue + ColorPalette(Index + 2)
            NEXT BytePos
            Red = Red \ 64
            Green = Green \ 64
            Blue = Blue \ 64
            PreColorDif = 1000
            FOR Index = 0 TO 767 STEP 3
                ColorDif = ABS(Red - ColorPalette(Index)) + ABS(Green - ColorPalette(Index + 1)) + ABS(Blue - ColorPalette(Index + 2))
                IF ColorDif < PreColorDif THEN PreColorDif = ColorDif: ClosestColor = Index
            NEXT Index
            ClosestColor = ClosestColor \ 3
            PRINT #3, CHR$(ClosestColor);
        NEXT Tile
    NEXT PalBase
    CLOSE 3
    LOCATE 25, 1: PRINT "Done!"
RETURN

SaveSnapshot:
    CONST SnapshotHeight = 200, SnapshotWidth = 320
    OPEN "snapshot.bmp" FOR OUTPUT AS #3
  
    DEF SEG = &HA000
    SnapshotSize& = CLNG(SnapshotHeight) * SnapshotWidth
    PRINT #3, "BM" + MKL$((54 + 1024 + 3 + SnapshotSize&) / 4) + MKL$(0) + MKL$(54 + 1024) + MKL$(40);
    PRINT #3, MKL$(SnapshotWidth) + MKL$(SnapshotHeight) + MKI$(1) + MKI$(8) + MKL$(0);
    PRINT #3, MKL$(SnapshotSize&) + MKL$(0) + MKL$(0) + MKL$(0) + MKL$(0);

    FOR Index = 0 TO 767 STEP 3
        PRINT #3, CHR$(ColorPalette(Index + 2)) + CHR$(ColorPalette(Index + 1)) + CHR$(ColorPalette(Index)) + CHR$(0);
    NEXT

    BytePos& = CLNG(SnapshotHeight) * SnapshotWidth - 320
    Row = 200
    DO
        Col = 320
        DO
            PRINT #3, CHR$(PEEK(BytePos&));
            BytePos& = BytePos& + 1
            Col = Col - 1
        LOOP WHILE Col
        Row = Row - 1
        BytePos& = BytePos& - 640
    LOOP WHILE Row

    CLOSE #3
RETURN

FindHexString:




FindString:
    SourcePos = ViewFilePos& - ViewFileBufferPos&
'instr()
'ViewFilePos&
RETURN

