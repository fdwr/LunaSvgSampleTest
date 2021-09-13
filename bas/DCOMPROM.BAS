'DCompRom.bas - Decompress Rom Data
'Peekin 2001.2.24
DEFINT A-Z
DECLARE SUB StatusLine (Text AS STRING)
DECLARE SUB TextPrompt (Text AS STRING, Row%, Col%, Wdth%)
DECLARE SUB DisplayDialog (Title AS STRING, Hite%, Wdth%)
DECLARE SUB HideDialog ()
DECLARE SUB DisplayBplTile (TileSeg%, TileSrc%, TopRow%, LeftCol%)

CONST ScreenHeight = 50, ScreenWidth = 80, ScreenSeg = &HB800
CONST FileBufferSize = 65536, DcmpBufferSize = 65536
CONST ViewFileTileHeight = 6, ViewFileTileWidth = 10
CONST TileHite = 8
CONST StatBarMode.Goto = 0
CONST StatBarMode.Format = 1
CONST StatBarMode.Dcmp = 2

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
BP AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

'cheap hack type created for fasting file loading
TYPE DwordBlock
A AS LONG
B AS LONG
C AS LONG
D AS LONG
E AS LONG
F AS LONG
G AS LONG
H AS LONG
END TYPE

DIM FileBuffer(FileBufferSize \ 32 - 1) AS DwordBlock
DIM DcmpBuffer(FileBufferSize \ 32 - 1) AS DwordBlock
DIM SHARED TileBplTbl(63), TileBits

DIM SHARED Regs AS RegisterType
DIM SHARED DlgRow, DlgCol, DlgHite, DlgWdth
REDIM SHARED DlgBg(0)
DIM FilePos AS LONG, NewFilePos AS LONG, FileLen AS LONG, FileBase AS LONG
DIM Src AS LONG

'Initialize...
WIDTH 80, 50

FileBufferSeg = VARSEG(FileBuffer(0))
FileBufferOfs = VARPTR(FileBuffer(0))
DcmpBufferSeg = VARSEG(DcmpBuffer(0))
DcmpBufferOfs = VARPTR(DcmpBuffer(0))

FilePos = &H8BA00'&H80200 link
TileWrap = 16
TileFormat = 3
GOSUB SetTileFormat
RomFile$ = "c:\emu\zelda.smc"

GOSUB FileOpenPrompt

GOSUB ViewFileScroll
'GOSUB ViewDcmpQuick

CLOSE
END

'displays the file contents as graphic tiles
ViewFileScroll:
    ' do
    '   switch keypress
    '   scroll up/down/left/right
    '   end switch
    '   if tiles need redrawing
    '     if no file open
    '       print no file open
    '       tiles need redrawing=0
    '     else
    '       {check file buffer}
    '       if file position > buffer end
    '           reload file buffer
    '           adjust tile ptr
    '       endif
    '       tiles need redrawing --
    '       redraw tile
    '     endif
    '   endif
    ' loop
    '
    StatBarMode = StatBarMode.Goto
    NewFilePos = FilePos
    GOSUB ViewFileRedraw
    DO
        Key$ = INKEY$
        SELECT CASE Key$
        CASE CHR$(0) + "H": NewFilePos = FilePos - (TileBytes * TileWrap): GOSUB ChangeFilePos
        CASE CHR$(0) + "P": NewFilePos = FilePos + (TileBytes * TileWrap): GOSUB ChangeFilePos
        CASE CHR$(0) + "K": NewFilePos = FilePos - TileBytes: GOSUB ChangeFilePos
        CASE CHR$(0) + "M": NewFilePos = FilePos + TileBytes: GOSUB ChangeFilePos
        CASE CHR$(0) + "I": NewFilePos = FilePos - (TileBytes * TileWrap * 16): GOSUB ChangeFilePos
        CASE CHR$(0) + "Q": NewFilePos = FilePos + (TileBytes * TileWrap * 16): GOSUB ChangeFilePos
        CASE CHR$(0) + "G": NewFilePos = 0: GOSUB ChangeFilePos
        CASE CHR$(0) + "O": NewFilePos = FileLen - 1: GOSUB ChangeFilePos
        CASE CHR$(0) + "s": NewFilePos = FilePos - 1: GOSUB ChangeFilePos
        CASE CHR$(0) + "t": NewFilePos = FilePos + 1: GOSUB ChangeFilePos
        CASE CHR$(0) + ";"
            ErrorText$ = "Help has not been created yet"
            GOSUB DisplayError
        CASE "o": GOSUB FileOpenPrompt
        CASE "g"
            NewFilePos = FilePos
            StaBarIdx = StatBarMode.Goto
            GOSUB SetStatBarMode
        CASE "b"
            StaBarIdx = StatBarMode.Format
            GOSUB SetStatBarMode
        CASE "d"
            StaBarIdx = StatBarMode.Dcmp
            GOSUB SetStatBarMode
        CASE "D"
            GOSUB ViewDcmpQuick
            GOSUB ViewFileRedraw
        CASE "n"
            NewFilePos = FilePos + SrcEnd
            GOSUB ChangeFilePos
            SrcEnd = 0
        CASE "0" TO "9"
            Value = VAL(Key$)
            SELECT CASE StatBarMode
            CASE StatBarMode.Goto
                NewFilePos = (NewFilePos * 10 + Value) AND 67108863
                IF NewFilePos >= FileLen THEN
                    NewFilePos = NewFilePos \ 10
                ELSE
                    Redraw = -1
                END IF
            CASE StatBarMode.Format
                SELECT CASE Value
                CASE 1, 2, 3, 4, 5, 7, 8
                    TileFormat = Value
                    GOSUB SetTileFormat
                    GOSUB RestartTileDisplay
                END SELECT
            CASE StatBarMode.Dcmp
            END SELECT
        CASE CHR$(8)
            IF StatBarMode = StatBarMode.Goto THEN
                NewFilePos = NewFilePos \ 10
                Redraw = -1
            END IF
        CASE CHR$(13)
            SELECT CASE StatBarMode
            CASE StatBarMode.Goto
                GOSUB ChangeFilePos
            CASE StatBarMode.Dcmp
                GOSUB ViewDcmpQuick
                GOSUB ViewFileRedraw
            END SELECT
        CASE CHR$(27): EXIT DO
        END SELECT

        IF Redraw THEN
            LOCATE ScreenHeight, 1
            StaBarIdx = StatBarMode.Goto
            GOSUB SetStatBarClr
            PRINT " Goto:" + STR$(NewFilePos); TAB(20);
            StaBarIdx = StatBarMode.Format
            GOSUB SetStatBarClr
            PRINT " Bits:" + STR$(TileFormat); TAB(40);
            StaBarIdx = StatBarMode.Dcmp
            GOSUB SetStatBarClr
            PRINT " Decompression:" + STR$(DcmpMode); TAB(80);
        END IF
        IF TilesToRedraw > 0 THEN
            IF FileOpen THEN
                IF FilePos < FileBase OR FilePos + TileWndBytes > FileBase + FileBufferSize THEN GOSUB RefillFileBuffer
                TileOfs = FilePos - FileBase + VARPTR(FileBuffer(0))
                GOSUB DisplayNextTile
            ELSE
                LOCATE 1, 1
                COLOR 7, 0
                PRINT "No file opened. Press O to open one, F1 for help, Esc to quit.";
                TilesToRedraw = 0
            END IF
        END IF
    LOOP
RETURN

ViewFileRedraw:
    LOCATE , , 0
    COLOR 7, 0
    CLS
    Redraw = -1

    TileSeg = FileBufferSeg
    GOSUB RestartTileDisplay
RETURN

SetStatBarClr:
    IF StaBarIdx = StatBarMode THEN COLOR 15, 3 ELSE COLOR 9, 3
RETURN

SetStatBarMode:
    SELECT CASE StatBarMode
    CASE StatBarMode.Goto
        NewFilePos = FilePos
    'CASE StatBarMode.Format
    'CASE StatBarMode.Dcmp
    END SELECT
    Redraw = -1
    StatBarMode = StaBarIdx
RETURN

ChangeFilePos:
    IF NewFilePos < 0 THEN NewFilePos = 0
    IF NewFilePos >= FileLen THEN NewFilePos = FileLen - 1
    IF NewFilePos = FilePos THEN RETURN
    FilePos = NewFilePos
    TilesToRedraw = ViewFileTileHeight * TileWrap
RETURN

'previews the current file contents as uncompressed graphic tiles
ViewDcmpQuick:
    ' set tiles remaining
    ' do
    '   if tiles remaining
    '     decompress enough of data for next tile
    '     tiles need redrawing --
    '     display tile
    '   endif
    ' loop until keypress
    COLOR 7, 0: CLS

    GOSUB RefillFileBuffer
    GOSUB ZlDecompress

    TileSeg = DcmpBufferSeg
    TileOfs = DcmpBufferOfs
    GOSUB RestartTileDisplay
    DO
        GOSUB DisplayNextTile
    LOOP WHILE TilesToRedraw > 0
    DO: LOOP UNTIL LEN(INKEY$)
RETURN

'displays a block of decompressed data from the file as graphic tiles
ViewDcmpScroll:
    ' reload file buffer
    ' decompress entire block of data from file to buffer
    ' do
    '   switch keypress
    '   scroll up/down/left/right
    '   end switch
    '   if tiles need redrawing
    '     redraw tile
    '     tiles need redrawing --
    '   endif
    ' loop until exit
RETURN

RestartTileDisplay:
    TilesToRedraw = ViewFileTileHeight * TileWrap
ResetTileDisplay:
    TileAdr = 0
    TileRows = 0
    TileCols = 0
    TileRow = 0
    TileCol = 0
RETURN

DisplayNextTile:
'this routine is called from multiple points, so it must be versatile

    'display current tile to text screen
    DisplayBplTile TileSeg, TileAdr + TileOfs, TileRow, TileCol

    'advance to next tile, skipping any that are not on the screen
    DO
        TilesToRedraw = TilesToRedraw - 1
        TileAdr = TileAdr + TileBytes
        TileCols = TileCols + 1
        IF TileCols >= TileWrap THEN
            TileCol = 0
            TileCols = 0
            TileRows = TileRows + 1
            IF TileRows >= ViewFileTileHeight THEN
                GOSUB ResetTileDisplay
            ELSE
                TileRow = TileRow + TileHite
            END IF
        ELSE
            TileCol = TileCol + 8
        END IF
        IF TilesToRedraw <= 0 THEN
            GOSUB ResetTileDisplay
            EXIT DO
        END IF
    LOOP UNTIL TileCols < ViewFileTileWidth
RETURN

FileOpenPrompt:
    NewFile$ = RomFile$
    DO
        DisplayDialog "Open file", 5, 60
        TextPrompt NewFile$, DlgRow + 2, DlgCol + 1, 58
        HideDialog
        IF LEN(NewFile$) <= 0 THEN EXIT DO

        ErrHandled = 0: ON ERROR GOTO ErrHan
        'attempt open
        OPEN NewFile$ FOR INPUT AS 2: CLOSE 2
        ON ERROR GOTO 0
        IF ErrHandled THEN
            ErrorText$ = "Could not open file"
            GOSUB DisplayError
        ELSE
            RomFile$ = NewFile$
            CLOSE 1: OPEN RomFile$ FOR BINARY AS 1
            FileLen = LOF(1)
            FileBase = -FileBufferSize
            FileOpen = -1
            EXIT DO
        END IF
    LOOP
RETURN

RefillFileBuffer:
    IF FilePos < FileBase THEN
        FileBase = FilePos - FileBufferSize + TileWndBytes
        IF FileBase < 0 THEN FileBase = 0
    ELSE
        FileBase = FilePos
    END IF
    SEEK 1, FileBase + 1
    FOR Count = 0 TO FileBufferSize \ 32 - 1
        GET 1, , FileBuffer(Count)
    NEXT
RETURN

SetTileFormat:
    IF TileFormat = 7 THEN 'mode 7
        TileBits = 8
    ELSE
        'generate tile table for bitplane routine
        TileTblIdx = 0
        'special case for NES tiles
        IF TileFormat = 5 THEN TileBits = 2 ELSE TileBits = TileFormat
        FOR Row = 0 TO 7
            FOR Bpl = 0 TO TileBits - 1
                SELECT CASE TileFormat
                CASE 1: Idx = Row
                CASE 2: Idx = Row * 2 + Bpl
                CASE 3
                    IF Bpl < 2 THEN
                        Idx = Row * 2 + Bpl
                    ELSE
                        Idx = 16 + Row
                    END IF
                CASE 5
                CASE 4, 8
                    Idx = Row * 2 + ((Bpl AND 254) * 8) + (Bpl AND 1)
                END SELECT
                TileBplTbl(TileTblIdx) = Idx
                TileTblIdx = TileTblIdx + 1
            NEXT
        NEXT
    END IF
    TileBytes = TileBits * TileHite
    TileWndBytes = ViewFileTileHeight * TileBytes * TileWrap
RETURN

ZlDecompress:
    StatusLine "decompressing..."
    Src = 0
    Dest = 0
    DestEnd = 8192
    DO
        DEF SEG = FileBufferSeg
ZlDecompressGetByte:
        Byte = PEEK(Src)
        Count = Byte AND 31
        Code = Byte AND 224
        Src = Src + 1

ZlDecompressDoCode:
        'check that the count does not overflow the destination
        IF Dest + Count > DestEnd THEN EXIT DO
        IF Src > DcmpBufferSize - 1028 THEN EXIT DO

        SELECT CASE Code
        CASE 0
            'transfer a run of bytes directly from source
            '12 34 56 78 90 ...
            '[byte run]
            FOR Dest = Dest TO Dest + Count
                DEF SEG = FileBufferSeg
                Byte = PEEK(Src)
                DEF SEG = DcmpBufferSeg
                POKE Dest, Byte
                Src = Src + 1
            NEXT
        CASE &H20
            'repeat a single byte multiple times
            '12 34 56 78 90 12 12 12 ...
            '               [byte repeat]
            Byte = PEEK(Src)
            Src = Src + 1
            DEF SEG = DcmpBufferSeg
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
            DEF SEG = DcmpBufferSeg
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
            'fill with incrementing value
            '12 34 56 78 90 00 01 02 ...
            '               [inc run]
            Byte = PEEK(Src)
            Src = Src + 1
            DEF SEG = DcmpBufferSeg
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
            DEF SEG = DcmpBufferSeg
            FOR Dest = Dest TO Dest + Count
                POKE Dest, PEEK(ReSrc)
                ReSrc = ReSrc + 1
            NEXT
        CASE &HE0
            'special code for extra long runs (up to 1024 instead of only 32)
            IF Byte = &HFF THEN
                Src = Src + 1
                SrcEnd = Src
                EXIT DO
            END IF
            'IF Byte = &HFF THEN Src = Src + 1: GOTO ZlDecompressGetByte
            Count = (Byte AND 3) * 256 + PEEK(Src)
            Src = Src + 1
            Code = (Byte AND 28) * 8     'shift bits 2-4 up to 5-7
            GOTO ZlDecompressDoCode
        END SELECT
    LOOP
    StatusLine "decompressed, ended at" + STR$(SrcEnd)
    'OPEN "out.tmp" FOR OUTPUT AS 3
    'Src = CompressDataSize
    'FOR Count = 1 TO 1000
    '    IF (Count AND 15) THEN Sep$ = "," ELSE Sep$ = CHR$(13) + CHR$(10)
    '    PRINT RIGHT$("0" + HEX$(PEEK(Src)), 2) + Sep$;
    '    Src = Src + 1
    'NEXT
    'CLOSE 3
RETURN

DisplayError:
    DisplayDialog "Error", 5, LEN(ErrorText$) + 2
    LOCATE DlgRow + 3, DlgCol + 2
    COLOR 9, 3
    PRINT ErrorText$;
    DO: LOOP UNTIL LEN(INKEY$)
    HideDialog
RETURN

ErrHan:
    ErrHandled = ERR
RESUME NEXT

SUB DisplayBplTile (TileSeg, TileSrc, TopRow, LeftCol)
    DIM TilePixels(7) AS INTEGER

    ScrnDest = (TopRow * ScreenWidth + LeftCol) * 2
    TileTblIdx = 0

    'Bpl = 0
    'FOR Row = 0 TO 7
    '    FOR Col = 0 TO 7
    '        DEF SEG = TileSeg
    '        Byte = PEEK(TileSrc + Bpl)
    '        DEF SEG = &HB800
    '        POKE ScrnDest, 219'Byte
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
        FOR Bpl = 0 TO TileBits - 1
            Byte = PEEK(TileSrc + TileBplTbl(TileTblIdx))
            'this could have been done with a for loop, but this is faster
            IF Byte AND 128 THEN TilePixels(0) = TilePixels(0) OR BplMask
            IF Byte AND 64 THEN TilePixels(1) = TilePixels(1) OR BplMask
            IF Byte AND 32 THEN TilePixels(2) = TilePixels(2) OR BplMask
            IF Byte AND 16 THEN TilePixels(3) = TilePixels(3) OR BplMask
            IF Byte AND 8 THEN TilePixels(4) = TilePixels(4) OR BplMask
            IF Byte AND 4 THEN TilePixels(5) = TilePixels(5) OR BplMask
            IF Byte AND 2 THEN TilePixels(6) = TilePixels(6) OR BplMask
            IF Byte AND 1 THEN TilePixels(7) = TilePixels(7) OR BplMask
            BplMask = BplMask * 2
            TileTblIdx = TileTblIdx + 1
        NEXT

        DEF SEG = &HB800
        FOR Col = 0 TO 7
            POKE ScrnDest, 219
            POKE ScrnDest + 1, TilePixels(Col)
            ScrnDest = ScrnDest + 2
        NEXT
        ScrnDest = ScrnDest + (ScreenWidth * 2) - 16
    NEXT

END SUB

SUB DisplayDialog (Title AS STRING, Hite, Wdth)

DlgRow = (ScreenHeight - Hite) \ 2
DlgCol = (ScreenWidth - Wdth) \ 2
DlgHite = Hite
DlgWdth = Wdth

REDIM DlgBg(Hite * Wdth)

'I wish dumb Qbasic would have had a Byte type.
'It would make SO MANY things much easier.
DlgBgSeg = VARSEG(DlgBg(0))
Dest = VARPTR(DlgBg(0))
SrcRow = (DlgRow * ScreenWidth + DlgCol) * 2
FOR Row = 0 TO Hite - 1
    Src = SrcRow
    FOR Col = 0 TO Wdth - 1
        DEF SEG = &HB800
        Char = PEEK(Src)
        Clr = PEEK(Src + 1)
        Src = Src + 2

        DEF SEG = DlgBgSeg
        POKE Dest, Char
        POKE Dest + 1, Clr
        Dest = Dest + 2
    NEXT
    SrcRow = SrcRow + ScreenWidth * 2
NEXT

'And another thing, just because I feel like ranting..
'Why does Qb stupidly make cursor row/columns one based? It makes
'calculations harder (or at least messier than really need to be).
LOCATE DlgRow + 1, DlgCol + 1, 0
COLOR 15, 1
PRINT " "; LEFT$(Title + STRING$(Wdth, 32), Wdth - 2); " "
COLOR 1, 3
FOR Row = 0 TO Hite - 3
    LOCATE , DlgCol + 1
    PRINT "Ý"; STRING$(Wdth - 2, 32); "Þ"
    'PRINT "³"; STRING$(Wdth - 2, 32); "³"
NEXT
COLOR 1, 1
LOCATE , DlgCol + 1
PRINT STRING$(Wdth, 32);


END SUB

SUB HideDialog

'I wish dumb Qbasic would have had a Byte type.
'It would make SO MANY things much easier.
DlgBgSeg = VARSEG(DlgBg(0))
Src = VARPTR(DlgBg(0))
DestRow = (DlgRow * ScreenWidth + DlgCol) * 2
FOR Row = 0 TO DlgHite - 1
    Dest = DestRow
    FOR Col = 0 TO DlgWdth - 1
        DEF SEG = DlgBgSeg
        Char = PEEK(Src)
        Clr = PEEK(Src + 1)
        Src = Src + 2
       
        DEF SEG = &HB800
        POKE Dest, Char
        POKE Dest + 1, Clr
        Dest = Dest + 2
    NEXT
    DestRow = DestRow + ScreenWidth * 2
NEXT

REDIM DlgBg(0)

END SUB

SUB StatusLine (Text AS STRING)

LOCATE ScreenHeight, 1
COLOR 9, 3
PRINT Text; TAB(80);

END SUB

SUB TextPrompt (Text AS STRING, Row, Col, Wdth)

Redraw = -1
DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE " " TO "ÿ": IF LEN(Text$) < 256 THEN Text$ = Text$ + Key$: Redraw = -1
    CASE CHR$(8): IF LEN(Text$) > 0 THEN Text$ = LEFT$(Text$, LEN(Text$) - 1): Redraw = -1
    CASE CHR$(27): Text$ = "": EXIT DO
    CASE CHR$(13): EXIT DO
    END SELECT

    IF Redraw THEN
        LOCATE Row + 1, Col + 1, 1
        COLOR 9, 1
        PRINT RIGHT$(Text$, Wdth);
        IF LEN(Text$) < Wdth THEN
            COLOR 15, 1
            PRINT STRING$(Wdth - LEN(Text$), 32);
            LOCATE , Col + LEN(Text$) + 1 'set cursor position
        END IF
        Redraw = 0
    END IF
LOOP
LOCATE , , 0    'don't leave cursor on screen

END SUB

