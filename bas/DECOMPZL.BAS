'Decompress ROM graphics using Zelda/Pokemon Silver compression method
DEFINT A-Z
DECLARE SUB StatusLine (Text$)
DECLARE SUB DisplayBplTile (TileSeg%, TileSrc%, TopRow%, LeftCol%)

CompressDataSize = 8192
DIM CompressData(CompressDataSize \ 2 - 1) AS LONG
DIM SHARED TileBplTbl(63) AS INTEGER
DIM SHARED TileBitDepth AS INTEGER
DIM FileLen AS LONG, FilePos AS LONG, NewFilePos AS LONG

CONST EditModeOpen = 0
CONST EditModeGoto = 1
CONST EditModeTileFormat = 2

WIDTH 80, 50
CLS

TileBitDepth = 3
GOSUB CalculateTileBplTbl

OPEN "c:\emu\zelda.smc" FOR BINARY AS 1
'OPEN "c:\emu\mario.smc" FOR BINARY AS 1
'OPEN "c:\emu\allstars.smc" FOR BINARY AS 1
RomFileOpen = -1
'FilePos = &H40200 'for Mario World
'FilePos = &H8BA00
FilePos = &HC0F64 'for Zelda as observed in SneQr
'FilePos = &H3A200 'for mario allstars 4bpl test
GOSUB RefreshFile
DEF SEG = VARSEG(CompressData(0))
Src = VARPTR(CompressData(0))
Dest = Src + CompressDataSize
DestEnd = Dest + CompressDataSize
GOSUB ZlDecompress
GOSUB DisplayGfx
CLOSE 1

END

EnterMode = EditModeOpen
Redraw = 1
'RomFileOpen = 0
DO
    IF Redraw THEN
        SELECT CASE EditMode
        CASE EditModeOpen: Text$ = "Open:" + RIGHT$(RomFile$, 70)
        CASE EditModeGoto: Text$ = "Goto:" + STR$(NewFilePos)
        CASE EditModeTileFormat: Text$ = "Mode:" + STR$(TileBitDepth)
        END SELECT
        LOCATE 50, 1: PRINT Text$; TAB(80);
        LOCATE 50, LEN(Text$) + 1
        Redraw = 0
    END IF

    Key$ = INKEY$
    SELECT CASE UCASE$(Key$)
    CASE ""
    CASE CHR$(0) + "H"
    CASE CHR$(0) + "P"
    CASE CHR$(0) + "K"
    CASE CHR$(0) + "M"
    CASE CHR$(0) + "I"
    CASE CHR$(0) + "Q"
    CASE CHR$(0) + "G": FilePos = 0
    CASE CHR$(0) + "O": FilePos = FileLen - 1
    CASE CHR$(2)
        EditMode = EditModeTileFormat
        Redraw = -1
    CASE CHR$(7)
        NewFilePos = FilePos
        EditMode = EditModeGoto
        Redraw = -1
    CASE CHR$(15)
        EditMode = EditModeOpen
        Redraw = -1
    CASE " " TO "ÿ"
        Value = VAL(Key$)
        SELECT CASE EditMode
        CASE EditModeOpen
            IF LEN(RomFile$) < 256 THEN
                RomFile$ = RomFile$ + Key$
                Redraw = 1
            END IF
        CASE EditModeGoto
            NewFilePos = (NewFilePos * 10 + Value) AND 16777215
            Redraw = 1
        CASE EditModeTileFormat
            SELECT CASE Value
            CASE 1, 2, 3, 4, 8: TileBitDepth = Value: Redraw = 1
            CASE ELSE
            END SELECT
        END SELECT
    CASE ""
        SELECT CASE EditMode
        CASE EditModeOpen
            IF LEN(RomFile$) THEN RomFile$ = LEFT$(RomFile$, LEN(RomFile$) - 1): Redraw = -1
        CASE EditModeGoto
            NewFilePos = NewFilePos \ 10
            Redraw = -1
        END SELECT
    CASE CHR$(13)
        SELECT CASE EditMode
        CASE EditModeOpen
            IF LEN(RomFile$) THEN
                OPEN RomFile$ FOR INPUT AS 2: CLOSE 2
                CLOSE 1
                OPEN RomFile$ FOR BINARY AS 1
                FileLen = LOF(1)
                RomFileOpen = -1
                GOSUB RefreshFile
                EditMode = EditModeGoto
                StatusLine "opened file"
                Redraw = -1
            ELSEIF RomFileOpen THEN
                CLOSE 1
                RomFileOpen = 0
                EditMode = EditModeOpen
                StatusLine "closed file"
            END IF
        CASE EditModeGoto
            FilePos = NewFilePos
            GOSUB RefreshFile
        CASE EditModeTileFormat
            DEF SEG = VARSEG(CompressData(0))
            Src = VARPTR(CompressData(0))
            Dest = Src + CompressDataSize
            DestEnd = Dest + CompressDataSize
            GOSUB ZlDecompress
            GOSUB DisplayGfx
        END SELECT
    CASE CHR$(27)
        EXIT DO
    END SELECT
LOOP

END

ZlDecompress:
    StatusLine "decompressing..."
    DO
        Byte = PEEK(Src)
        Count = Byte AND 31
        Code = Byte AND 224
        Src = Src + 1

ZlDecompressDoCode:
        'check that the count does not overflow the destination
        IF Dest + Count > DestEnd THEN EXIT DO
        IF Src > CompressDataSize \ 2 THEN EXIT DO

        SELECT CASE Code
        CASE 0
            'transfer a run of bytes directly from source
            '12 34 56 78 90 ...
            '[byte run]
            FOR Dest = Dest TO Dest + Count
                POKE Dest, PEEK(Src)
                Src = Src + 1
            NEXT
        CASE &H20
            'repeat a single byte multiple times
            '12 34 56 78 90 12 12 12 ...
            '               [byte repeat]
            Byte = PEEK(Src)
            Src = Src + 1
            FOR Dest = Dest TO Dest + Count
                POKE Dest, Byte
            NEXT
        CASE &H40
            'repeat two bytes multiple times (alternating even/odd)
            '12 34 56 78 90 12 34 12 34 12 ...
            '               [alternating repeat]
            Byte = PEEK(Src)
            Byte2 = PEEK(Src + 1)
            Src = Src + 2
            
            DO
                POKE Dest, Byte
                Dest = Dest + 1
                Count = Count - 1
                IF Count < 0 THEN EXIT DO
                POKE Dest, Byte2
                Dest = Dest + 1
                Count = Count - 1
            LOOP WHILE Count >= 0
        CASE &H60
            'fill with zeroes
            '12 34 56 78 90 00 00 00 ...
            '               [zero run]
            Byte = PEEK(Src)
            Src = Src + 1
            FOR Dest = Dest TO Dest + Count
                POKE Dest, Byte
                Byte = Byte + 1
            NEXT
        CASE &H80, &HA0, &HC0
            'duplicate a run of bytes already read into the buffer
            '12 34 56 78 90 34 56 78
            '   [------] -> [-copy-]
            ReSrc = PEEK(Src + 1) * 256 + PEEK(Src)
            Src = Src + 2
            FOR Dest = Dest TO Dest + Count
                POKE Dest, PEEK(ReSrc)
                ReSrc = ReSrc + 1
            NEXT
        CASE &HE0
            'special code for extra long runs (up to 1024 instead of only 32)
            IF Byte = &HFF THEN EXIT DO
            Count = (Byte AND 3) * 256 + PEEK(Src)
            Src = Src + 1
            Code = (Byte AND 28) * 8     'shift bits 2-4 up to 5-7
            GOTO ZlDecompressDoCode
        END SELECT
    LOOP
    StatusLine "decompressed"
    'OPEN "out.tmp" FOR OUTPUT AS 3
    'Src = CompressDataSize
    'FOR Count = 1 TO 1000
    '    IF (Count AND 15) THEN Sep$ = "," ELSE Sep$ = CHR$(13) + CHR$(10)
    '    PRINT RIGHT$("0" + HEX$(PEEK(Src)), 2) + Sep$;
    '    Src = Src + 1
    'NEXT
    'CLOSE 3
RETURN

PkDecompress:
    StatusLine "decompressing..."
    DO
        Byte = PEEK(Src)
        Count = Byte AND 31
        Code = Byte AND 224
        Src = Src + 1

PkDecompressDoCode:
        'check that the count does not overflow the destination
        IF Dest + Count > DestEnd THEN EXIT DO
        IF Src > CompressDataSize \ 2 THEN EXIT DO

        SELECT CASE Code
        CASE 0
            'transfer a run of bytes
            '12 34 56 78 90 ...
            '[byte run]
            FOR Dest = Dest TO Dest + Count
                POKE Dest, PEEK(Src)
                Src = Src + 1
            NEXT
        CASE &H20
            'repeat a single byte multiple times
            '12 34 56 78 90 12 12 12 ...
            '               [byte repeat]
            Byte = PEEK(Src)
            Src = Src + 1
            FOR Dest = Dest TO Dest + Count
                POKE Dest, Byte
            NEXT
        CASE &H40
            'repeat two bytes multiple times (alternating even/odd)
            '12 34 56 78 90 12 34 12 34 12 ...
            '               [alternating repeat]
            Byte = PEEK(Src)
            Byte2 = PEEK(Src + 1)
            Src = Src + 2
            FOR Dest = Dest TO Dest + Count
                IF Count AND 1 THEN POKE Dest, Byte2 ELSE POKE Dest, Byte
            NEXT
        CASE &H60
            'fill with zeroes
            '12 34 56 78 90 00 00 00 ...
            '               [zero run]
            FOR Dest = Dest TO Dest + Count
                POKE Dest, 0
            NEXT
        CASE &H80
            'duplicate a run of bytes already read into the buffer
            '12 34 56 78 90 34 56 78
            '   [------] -> [-copy-]
            Byte = PEEK(Src)
            IF Byte AND 128 THEN
                Src = Src + 1
                ReSrc = Dest - (Byte AND 127) - 1
            ELSE
                Src = Src + 2
                ReSrc = Byte * 256 + PEEK(Src + 1) + 1
            END IF
            FOR Dest = Dest TO Dest + Count
                POKE Dest, PEEK(ReSrc)
                ReSrc = ReSrc + 1
            NEXT
        CASE &HA0
            'duplicate a run already read into the buffer, reverse bit order
            'duplicate a run of bytes already read into the buffer
            '12 34 56 78 90 2C 6A 1E
            '   [------] -> [-copy-]
            Byte = PEEK(Src)
            IF Byte AND 128 THEN
                Src = Src + 1
                ReSrc = Dest - (Byte AND 127) - 1
            ELSE
                Src = Src + 2
                ReSrc = Byte * 256 + PEEK(Src + 1) + 1
            END IF
            FOR Dest = Dest TO Dest + Count
                Byte = PEEK(ReSrc)
                ReSrc = ReSrc + 1
                Byte2 = 0
                'reverse the bits in Byte to Byte2
                'shortcut loop by testing if Byte has any set bits left
                DO WHILE Byte > 0
                    Byte2 = Byte2 * 2
                    Byte2 = Byte2 OR (Byte AND 1)
                    Byte = Byte \ 2
                LOOP
                POKE Dest, Byte2
            NEXT
        CASE &HC0
            'duplicate a run already read into the buffer, going backwards
            'duplicate a run of bytes already read into the buffer
            '12 34 56 78 90 78 56 34
            '   [------] -> [-copy-]
            Byte = PEEK(Src)
            IF Byte AND 128 THEN
                Src = Src + 1
                ReSrc = Dest - (Byte AND 127) - 1
            ELSE
                Src = Src + 2
                ReSrc = Byte * 256 + PEEK(Src + 1) + 1
            END IF
            FOR Dest = Dest TO Dest + Count
                POKE Dest, PEEK(ReSrc)
                ReSrc = ReSrc - 1
            NEXT
        CASE &HE0
            'special code for extra long runs (up to 1024 instead of only 32)
            Count = (Byte AND 3) * 256 + PEEK(Src)
            Src = Src + 1
            Code = (Byte AND 28) * 8     'shift bits 2-4 up to 5-7
            GOTO PkDecompressDoCode
        END SELECT
    LOOP
    StatusLine "decompressed"
RETURN

DisplayGfx:
    TileInc = TileBitDepth * 8
    TileAdr = 0
    FOR Row = 0 TO 47 STEP 8
        FOR Col = 0 TO 63 STEP 8
            'DisplayBplTile VARSEG(CompressData(0)), VARPTR(CompressData(0)) + TileAdr, Row, Col
            DisplayBplTile VARSEG(CompressData(0)), VARPTR(CompressData(0)) + TileAdr + CompressDataSize, Row, Col
            TileAdr = TileAdr + TileInc
        NEXT
        TileAdr = TileAdr + TileInc * 8
    NEXT
RETURN

RefreshFile:
    IF NOT RomFileOpen THEN RETURN
    StatusLine "reading file..."
    SEEK 1, FilePos + 1
    FOR Count = 0 TO CompressDataSize \ 4 - 1
        GET 1, , CompressData(Count)
    NEXT
    StatusLine "read file"
RETURN

CalculateTileBplTbl:
    FOR Row = 0 TO 7
        FOR Bpl = 0 TO TileBitDepth - 1
            SELECT CASE TileBitDepth
            CASE 1: Idx = Row
            CASE 2: Idx = Row * 2 + Bpl
            CASE 3
                IF Bpl < 2 THEN
                    Idx = Row * 2 + Bpl
                ELSE
                    Idx = 16 + Row
                END IF
            CASE 4, 8
                Idx = Row * 2 + ((Bpl AND 254) * 8) + (Bpl AND 1)
            END SELECT
            TileBplTbl(TileTblIdx) = Idx
            TileTblIdx = TileTblIdx + 1
        NEXT
    NEXT
RETURN

SUB DisplayBplTile (TileSeg, TileSrc, TopRow, LeftCol)

    DIM TilePixels(7) AS INTEGER

    ScrnDest = TopRow * 160 + LeftCol * 2
    TileTblIdx = 0

    'Bpl = 0
    'FOR Row = 0 TO 7
    '    FOR Col = 0 TO 7
    '        DEF SEG = TileSeg
    '        Byte = PEEK(TileSrc + Bpl)
    '        DEF SEG = &HB800
    '        POKE ScrnDest, 65'Byte
    '        POKE ScrnDest + 1, Byte'15
    '        ScrnDest = ScrnDest + 2
    '        Bpl = Bpl + 1
    '    NEXT
    '    ScrnDest = ScrnDest + 144
    'NEXT
    'EXIT SUB

    FOR Row = 0 TO 7
        FOR Bit = 0 TO 7
            TilePixels(Bit) = 0
        NEXT
        DEF SEG = TileSeg
        BplMask = 1
        FOR Bpl = 0 TO TileBitDepth - 1
            Byte = PEEK(TileSrc + TileBplTbl(TileTblIdx))
            BitMask = 128
            FOR Bit = 0 TO 7
                IF Byte AND BitMask THEN TilePixels(Bit) = TilePixels(Bit) OR BplMask
                BitMask = BitMask \ 2
            NEXT
            BplMask = BplMask * 2
            TileTblIdx = TileTblIdx + 1
        NEXT

        DEF SEG = &HB800
        FOR Col = 0 TO 7
            POKE ScrnDest, 219
            POKE ScrnDest + 1, TilePixels(Col)
            ScrnDest = ScrnDest + 2
        NEXT
        ScrnDest = ScrnDest + 144
    NEXT

END SUB

SUB StatusLine (Text$)
    LOCATE 49, 1: PRINT Text$; TAB(80);
END SUB

