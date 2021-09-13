DECLARE SUB GifLoad (a$)

GifLoad ""

DEFINT A-Z
SUB GifLoad (a$)
DIM Prefix(4095), Suffix(4095), OutStack(4095), shiftout(8)
DIM Ybase AS LONG, powersof2(11) AS LONG, WorkCode AS LONG
DIM ColorIndexes(0 TO 255)

FOR a = 0 TO 7: shiftout(8 - a) = 2 ^ a: NEXT a
FOR a = 0 TO 11: powersof2(a) = 2 ^ a: NEXT a
IF a$ = "" THEN INPUT "GIF file"; a$: IF a$ = "" THEN END
IF INSTR(a$, ".") = 0 THEN a$ = a$ + ".gif"
OPEN a$ FOR BINARY AS #1
a$ = "      ": GET #1, , a$
'IF A$ <> "GIF87a" THEN PRINT "Not a GIF87a file.": END
GET #1, , TotalX: GET #1, , TotalY: GOSUB GetByte
NumColors = 2 ^ ((a AND 7) + 1): NoPalette = (a AND 128) = 0
GOSUB GetByte: Background = a
GOSUB GetByte: IF a <> 0 THEN PRINT "Bad screen descriptor.": END
IF NoPalette = 0 THEN p$ = SPACE$(NumColors * 3): GET #1, , p$
DO
    GOSUB GetByte
    IF a = 44 THEN
        EXIT DO
    ELSEIF a <> 33 THEN
        PRINT "Unknown extension type.": END
    END IF
    GOSUB GetByte
    DO: GOSUB GetByte: a$ = SPACE$(a): GET #1, , a$: LOOP UNTIL a = 0
LOOP
GET #1, , XStart: GET #1, , YStart: GET #1, , XLength: GET #1, , YLength
XEnd = XStart + XLength: YEnd = YStart + YLength: GOSUB GetByte
IF a AND 128 THEN PRINT "Can't handle local colormaps.": END
Interlaced = a AND 64: PassNumber = 0: PassStep = 8
GOSUB GetByte
ClearCode = 2 ^ a
EOSCode = ClearCode + 1
FirstCode = ClearCode + 2: NextCode = FirstCode
StartCodeSize = a + 1: CodeSize = StartCodeSize
StartMaxCode = 2 ^ (a + 1) - 1: MaxCode = StartMaxCode

BitsIn = 0: BlockSize = 0: BlockPointer = 1
x = XStart: y = YStart: Ybase = y * 320&

SCREEN 13: DEF SEG = &HA000
IF NoPalette = 0 THEN
    OUT &H3C7, 0: OUT &H3C8, 0
    FOR a = 1 TO NumColors * 3: OUT &H3C9, ASC(MID$(p$, a, 1)) \ 4: NEXT a
END IF
'LINE (0, 0)-(319, 199), Background, BF
DO
    GOSUB GetCode
    IF Code <> EOSCode THEN
        IF Code = ClearCode THEN
            NextCode = FirstCode
            CodeSize = StartCodeSize
            MaxCode = StartMaxCode
            GOSUB GetCode
            CurCode = Code: LastCode = Code: LastPixel = Code
            IF x < 320 THEN POKE x + Ybase, LastPixel: ColorIndexes(LastPixel) = ColorIndexes(LastPixel) + 1
            x = x + 1: IF x = XEnd THEN GOSUB NextScanLine
        ELSE
            CurCode = Code: StackPointer = 0
            IF Code > NextCode THEN EXIT DO
            IF Code = NextCode THEN
                CurCode = LastCode
                OutStack(StackPointer) = LastPixel
                StackPointer = StackPointer + 1
            END IF

            DO WHILE CurCode >= FirstCode
                OutStack(StackPointer) = Suffix(CurCode)
                StackPointer = StackPointer + 1
                CurCode = Prefix(CurCode)
            LOOP

            LastPixel = CurCode
            IF x < 320 THEN POKE x + Ybase, LastPixel: ColorIndexes(LastPixel) = ColorIndexes(LastPixel) + 1
            x = x + 1: IF x = XEnd THEN GOSUB NextScanLine

            FOR a = StackPointer - 1 TO 0 STEP -1
                IF x < 320 THEN POKE x + Ybase, OutStack(a): ColorIndexes(OutStack(a)) = ColorIndexes(OutStack(a)) + 1
                x = x + 1: IF x = XEnd THEN GOSUB NextScanLine
            NEXT a

            IF NextCode < 4096 THEN
                Prefix(NextCode) = LastCode
                Suffix(NextCode) = LastPixel
                NextCode = NextCode + 1
                IF NextCode > MaxCode AND CodeSize < 12 THEN
                    CodeSize = CodeSize + 1
                    MaxCode = MaxCode * 2 + 1
                END IF
            END IF
            LastCode = Code
        END IF
    END IF
LOOP UNTIL DoneFlag OR Code = EOSCode
CLOSE #1

FOR a = 0 TO 255
    LINE (a, 200)-(a, 200 - ColorIndexes(a)), a
NEXT a
SLEEP
IF UCASE$(INKEY$) = "S" THEN
 LINE INPUT "Save palette?:", a$
 IF LEN(a$) THEN
  OPEN a$ FOR OUTPUT AS 1
  NumColors = 0
  FOR a = 0 TO 255
   IF ColorIndexes(a) THEN
    PRINT #1, MID$(p$, a * 3 + 1, 3);
    NumColors = NumColors + 1
   END IF
  NEXT a
  CLOSE 1
  PRINT "Number of colors saved to "; a$; " was"; NumColors
  DO: LOOP UNTIL LEN(INKEY$)
 END IF
END IF
EXIT SUB

GetByte: a$ = " ": GET #1, , a$: a = ASC(a$): RETURN

NextScanLine:
    IF Interlaced THEN
        y = y + PassStep
        IF y >= YEnd THEN
            PassNumber = PassNumber + 1
            SELECT CASE PassNumber
            CASE 1: y = 4: PassStep = 8
            CASE 2: y = 2: PassStep = 4
            CASE 3: y = 1: PassStep = 2
            END SELECT
        END IF
    ELSE
        y = y + 1
    END IF
    x = XStart: Ybase = y * 320&: DoneFlag = y > 199
RETURN
GetCode:
    IF BitsIn = 0 THEN GOSUB ReadBufferedByte: LastChar = a: BitsIn = 8
    WorkCode = LastChar \ shiftout(BitsIn)
    DO WHILE CodeSize > BitsIn
        GOSUB ReadBufferedByte: LastChar = a
        WorkCode = WorkCode OR LastChar * powersof2(BitsIn)
        BitsIn = BitsIn + 8
    LOOP
    BitsIn = BitsIn - CodeSize
    Code = WorkCode AND MaxCode
RETURN
ReadBufferedByte:
    IF BlockPointer > BlockSize THEN
        GOSUB GetByte: BlockSize = a
        a$ = SPACE$(BlockSize): GET #1, , a$
        BlockPointer = 1
    END IF
    a = ASC(MID$(a$, BlockPointer, 1)): BlockPointer = BlockPointer + 1
RETURN

END SUB

