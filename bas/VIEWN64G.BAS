DEFINT A-Z

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
BP AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

CONST FileBufferSize = 16384, ViewFileHandle = 1
DIM SHARED ViewFile$, VramFile$
DIM SHARED DTA AS STRING * 44, Regs AS RegType
DIM SHARED FileBuffer AS STRING * FileBufferSize, Vram(16383) AS LONG
DIM SHARED ColorPalette(767)

'----------------------------------------

GOSUB SetDTA

SCREEN 13

'ViewFile$ = "c:\temp\n64test.rom"
ViewFile$ = "c:\temp\emu\starfox.rom"
'ViewFile$ = "c:\temp\zelda64.rom"
'ViewFile$ = "c:\temp\starfox.sav"
'VramFile$ = "c:\temp\bg\zelda.zs3"
'PixelTableFile$ = "c:\dw\src\tmv\zpixtbl.dat"
ViewFilePos& = 9303918'&H198185'&H6A0AD0'32768'9305680'458871
DisplayMode = 1
TileWrap = 44
GOSUB OpenViewingFile
IF Cancel GOTO EndProgram

GOSUB RainbowColorSet
'GOSUB GrayColorSet
FOR Col = 0 TO 255
    LINE (Col, 170)-(Col, 180), Col
NEXT Col
GOSUB PaletteSet

ViewWindowUpdate = 2
ViewFileLen& = LOF(ViewFileHandle)
ViewFileBufferPos& = FileBufferSize
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
        CASE CHR$(0) + "H": NewFilePos& = ViewFilePos& - TileWrap * 4: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "P": NewFilePos& = ViewFilePos& + TileWrap * 4: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "K": NewFilePos& = ViewFilePos& - 4: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "M": NewFilePos& = ViewFilePos& + 4: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "s": NewFilePos& = ViewFilePos& - 1: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "t": NewFilePos& = ViewFilePos& + 1: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "I": NewFilePos& = ViewFilePos& - TileWrap * 128: GOSUB ChangeViewFilePos
        CASE CHR$(0) + "Q": NewFilePos& = ViewFilePos& + TileWrap * 128: GOSUB ChangeViewFilePos
        CASE "g": LOCATE 25, 1: LINE INPUT ; "Goto:", Text$: IF LEN(Text$) THEN NewFilePos& = VAL(Text$): GOSUB ChangeViewFilePos
        CASE "/": NewFilePos& = ViewFilePos& - 32768: GOSUB ChangeViewFilePos
        CASE "*": NewFilePos& = ViewFilePos& + 32768: GOSUB ChangeViewFilePos
        CASE "[": IF TileWrap > 1 THEN NewTileWrap = TileWrap - 1: GOSUB ChangeTileWrap
        CASE "]": IF TileWrap < 64 THEN NewTileWrap = TileWrap + 1: GOSUB ChangeTileWrap
        CASE " ": DisplayMode = (DisplayMode + 1) MOD 2: ViewWindowChange = 2
        CASE "p"
            UseTilePalette = UseTilePalette XOR 1
            IF UseTilePalette THEN
                PALETTE
            ELSE
                GOSUB PaletteSet
            END IF
        CASE "W"
            GOSUB SaveSnapshot
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
                LOCATE 25, 1: PRINT "Pos:"; ViewFilePos&; TAB(20); "Wrap:"; TileWrap;
                IF DisplayMode THEN PRINT "32bit";  ELSE PRINT "16bit";
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
    'IF ViewFilePos& < ViewFileBufferPos& THEN
    '    ViewFileBufferPos& = ViewFilePos& - FileBufferSize + 8192
    '    IF ViewFileBufferPos& < 0 THEN ViewFileBufferPos& = 0
    'ELSEIF ViewFilePos& > ViewFileBufferPos& + FileBufferSize - 8192 THEN
        ViewFileBufferPos& = ViewFilePos&
    'ELSE
    '    RETURN
    'END IF
    GET ViewFileHandle, ViewFileBufferPos& + 1, FileBuffer
RETURN

DisplayViewingWindow:
    SourcePos = ViewFilePos& - ViewFileBufferPos&
    DEF SEG = VARSEG(FileBuffer)
    SourceAdr = SourcePos + VARPTR(FileBuffer)
    IF DisplayMode THEN SourceInc = 2 ELSE SourceInc = 4
    FOR Row = 0 TO 63 STEP 1
        FOR Col = 0 TO TileWrap - 1
            SELECT CASE DisplayMode
            CASE 0
                PSET (Col, Row), PEEK(SourceAdr)
                'LINE (Col, Row)-(Col + 7, Row + 7), PEEK(SourceAdr), BF
            CASE 1
                ColorValue& = PEEK(SourceAdr + 2) + (PEEK(SourceAdr + 3) * 256&)
                ColorValue = (ColorValue& AND 62) \ 11 + ((ColorValue& AND 1984) \ 341) * 6 + ((ColorValue& AND 63488) \ 10922) * 36
                PSET (Col, Row), ColorValue
            CASE 2
                ColorValue = (PEEK(SourceAdr) \ 43) + (PEEK(SourceAdr + 1) \ 43) * 6 + (PEEK(SourceAdr + 2) \ 43) * 36
                PSET (Col, Row), ColorValue
            CASE 3
                ColorValue& = PEEK(SourceAdr + 2) + (PEEK(SourceAdr + 3) * 256&)
                ColorValue = (ColorValue& AND 62) \ 11 + ((ColorValue& AND 1984) \ 341) * 6 + ((ColorValue& AND 63488) \ 10922) * 36
                PSET (Col, Row), ColorValue
                ColorValue& = PEEK(SourceAdr) + (PEEK(SourceAdr + 1) * 256&)
                ColorValue = (ColorValue& AND 62) \ 11 + ((ColorValue& AND 1984) \ 341) * 6 + ((ColorValue& AND 63488) \ 10922) * 36
                PSET (Col + 1, Row), ColorValue
            END SELECT
            SourceAdr = SourceAdr + SourceInc' + SourceInc
        NEXT Col
    NEXT Row
RETURN

OpenViewingFile:
    'call OpenFile(FileName$,FileHandle)
    OPEN ViewFile$ FOR INPUT AS ViewFileHandle: CLOSE ViewFileHandle
    OPEN ViewFile$ FOR BINARY AS ViewFileHandle
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
        OUT &H3C9, ColorPalette(Index) \ 4
        OUT &H3C9, ColorPalette(Index + 1) \ 4
        OUT &H3C9, ColorPalette(Index + 2) \ 4
    NEXT Index
RETURN

RainbowColorSet:
    Rcolor = 0: Gcolor = 0: Bcolor = 0
    FOR Index = 0 TO 767 STEP 3
        ColorPalette(Index) = Rcolor * 43'30 + 105
        ColorPalette(Index + 1) = Gcolor * 43'30 + 105
        ColorPalette(Index + 2) = Bcolor * 43'30 + 105
        Bcolor = Bcolor + 1
        IF Bcolor > 5 THEN
            Bcolor = 0: Gcolor = Gcolor + 1
            IF Gcolor > 5 THEN
                Gcolor = 0: Rcolor = Rcolor + 1
                IF Rcolor > 5 THEN Rcolor = 0
            END IF
        END IF
    NEXT Index
RETURN

GrayColorSet:
    Rcolor = 0
    FOR Index = 0 TO 767 STEP 3
        ColorPalette(Index) = Rcolor
        ColorPalette(Index + 1) = Rcolor
        ColorPalette(Index + 2) = Rcolor
        Rcolor = Rcolor + 1
    NEXT Index
RETURN

SaveSnapshot:
    CONST ImageHeight = 200, ImageWidth = 320
    OPEN "snapshot.bmp" FOR OUTPUT AS #3
   
    DEF SEG = &HA000
    ImageSize& = CLNG(ImageHeight) * ImageWidth
    PRINT #3, "BM" + MKL$((54 + 1024 + 3 + ImageSize&) / 4) + MKL$(0) + MKL$(54 + 1024) + MKL$(40);
    PRINT #3, MKL$(ImageWidth) + MKL$(ImageHeight) + MKI$(1) + MKI$(8) + MKL$(0);
    PRINT #3, MKL$(ImageSize&) + MKL$(0) + MKL$(0) + MKL$(0) + MKL$(0);

    FOR Index = 0 TO 767 STEP 3
        PRINT #3, CHR$(ColorPalette(Index + 2)) + CHR$(ColorPalette(Index + 1)) + CHR$(ColorPalette(Index)) + CHR$(0);
    NEXT

    BytePos& = CLNG(ImageHeight) * ImageWidth - 320
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

'2-63 64-2047 2048-65535  bit 0 is transparency
'PSET (Col, Row), (ColorValue& AND 62) \ 11
'PSET (Col, Row), ((ColorValue& AND 1984) \ 331) * 6
'PSET (Col, Row), ((ColorValue& AND 63488) \ 10582) * 36

