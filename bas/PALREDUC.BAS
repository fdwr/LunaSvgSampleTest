'Palette Reducer
DEFINT A-Z

DIM SHARED ColorPalette(383)
DIM CursorFrames(7)
PaletteFile$ = "c:\temp\bg\metroid3.zs2"

FOR Count = 0 TO 7
    READ CursorFrames(Count)
NEXT Count

GOSUB LoadPalette
IF ErrorHandled GOTO EndProgram

SCREEN 13
GOSUB PaletteSet
GOSUB FindConstrastColors

UsePrimaryColor = -1
GOSUB DisplayColorBlocks

EndProgram:
END

DisplayColorBlocks:
    CursorFrame = 0
    CursorColor = 15
   
    COLOR BrightestColor
    GOSUB ClearScreen
    GOSUB DrawColorBlocks
    GOSUB ShowColor
    GOSUB SetPrimaryColor
    GOSUB GetPrimaryColorValues
    GOSUB DrawColorContrastInfo
    PreCursorTime# = TIMER
    DO
        Key$ = INKEY$
        SELECT CASE Key$
        CASE CHR$(0) + "H": NewColor = CurColor - 16: GOSUB SetCurColor
        CASE CHR$(0) + "P": NewColor = CurColor + 16: GOSUB SetCurColor
        CASE CHR$(0) + "K": NewColor = CurColor - 1: GOSUB SetCurColor
        CASE CHR$(0) + "M": NewColor = CurColor + 1: GOSUB SetCurColor
        CASE " "
            UsePrimaryColor = UsePrimaryColor XOR -1
            GOSUB SetPrimaryColor
            GOSUB DrawColorContrastInfo
        CASE CHR$(13): GOTO DisplayColorContrastBars
        CASE CHR$(27): EXIT DO
        END SELECT
        CursorTime# = TIMER - PreCursorTime#
        IF CursorTime# <> 0 THEN
            CursorFrame = (CursorFrame + 1) AND 255
            DEF SEG = VARSEG(ColorPalette(0))
            BytePos = CurColor * 3: BytePos2 = CursorFrame * 3
            IF PEEK(BytePos) = PEEK(BytePos2) AND PEEK(BytePos + 1) = PEEK(BytePos2 + 1) AND PEEK(BytePos + 2) = PEEK(BytePos2 + 2) THEN
                CursorFrame = (CursorFrame + 1) AND 255
            ELSE
                CursorColor = CursorFrame
            END IF
            GOSUB ShowColor
            PreCursorTime# = TIMER
        END IF
    LOOP
RETURN

SetCurColor:
    IF UsePrimaryColor THEN
        PrimaryColor = NewColor AND 255
        GOSUB ShowColor
        CurColor = PrimaryColor
        GOSUB ShowColor
    ELSE
        SecondaryColor = NewColor AND 255
        GOSUB ShowColor
        CurColor = SecondaryColor
        GOSUB ShowColor
    END IF
    GOSUB GetPrimaryColorValues
    GOSUB DrawColorContrastInfo
RETURN

ShowColor:
    Row = (CurColor \ 16) * 9
    Col = (CurColor AND 15) * 9
    LINE (Col, Row)-(Col + 8, Row + 8), CurColor, BF
    IF CurColor = PrimaryColor OR CurColor = SecondaryColor THEN
        LINE (Col, Row)-(Col + 8, Row + 8), CursorColor, B
    END IF
RETURN

SetPrimaryColor:
    IF UsePrimaryColor THEN
        CurColor = PrimaryColor
    ELSE
        CurColor = SecondaryColor
    END IF
RETURN

LoadPalette:
    OPEN PaletteFile$ FOR INPUT AS 1: CLOSE 1
    OPEN PaletteFile$ FOR BINARY AS 1
    SEEK 1, 1561: Palette$ = INPUT$(512, 1)
    CLOSE 1
    DEF SEG = VARSEG(ColorPalette(0))
    BytePos = 0
    FOR Count = 1 TO 512 STEP 2
      ColorValue = CVI(MID$(Palette$, Count, 2))
      POKE BytePos, (ColorValue AND 31) * 2
      POKE BytePos + 1, (ColorValue AND 992) \ 16
      POKE BytePos + 2, (ColorValue AND 31744) \ 512
      BytePos = BytePos + 3
    NEXT Count
    Palette$ = ""
RETURN

PaletteSet:
    DEF SEG = VARSEG(ColorPalette(0))
    OUT &H3C8, 0
    FOR BytePos = 0 TO 767 STEP 3
        OUT &H3C9, PEEK(BytePos)
        OUT &H3C9, PEEK(BytePos + 1)
        OUT &H3C9, PEEK(BytePos + 2)
    NEXT BytePos
RETURN

DrawColorBlocks:
    Count = 0
    FOR Row = 0 TO 135 STEP 9
        FOR Col = 0 TO 135 STEP 9
            LINE (Col, Row)-(Col + 8, Row + 8), Count, BF
            Count = Count + 1
        NEXT Col
    NEXT Row
RETURN

DisplayColorContrastBars:
    GOSUB GetPrimaryColorValues
    GOSUB ClearScreen
    GOSUB DrawColorContrastBars
    GOSUB DrawColorContrastInfo
    GOSUB DrawColorContrastSlider
    DO
        Key$ = INKEY$
        SELECT CASE Key$
        CASE CHR$(0) + "P": NewColor = CurColor - 16: GOSUB SetCurColorBar
        CASE CHR$(0) + "H": NewColor = CurColor + 16: GOSUB SetCurColorBar
        CASE CHR$(0) + "K": NewColor = CurColor - 1: GOSUB SetCurColorBar
        CASE CHR$(0) + "M": NewColor = CurColor + 1: GOSUB SetCurColorBar
        CASE " "
            UsePrimaryColor = UsePrimaryColor XOR -1
            GOSUB SetPrimaryColor
            GOSUB DrawColorContrastInfo
        CASE CHR$(13): GOTO DisplayColorBlocks
        CASE CHR$(27): EXIT DO
        END SELECT
    LOOP
RETURN

DrawColorContrastBars:
    BytePos = 0
    FOR Col = 0 TO 255
        ColorValue = 188 - ABS(RedValue - PEEK(BytePos)) - ABS(GreenValue - PEEK(BytePos + 1)) - ABS(BlueValue - PEEK(BytePos + 2))
        LINE (Col, -1)-(Col, ColorValue), Col
        LINE (Col, ColorValue + 1)-(Col, 189), DarkestColor
        BytePos = BytePos + 3
    NEXT Col
RETURN

DrawColorContrastInfo:
    BytePos = SecondaryColor * 3
    COLOR BrightestColor
    LOCATE 1, 35: PRINT PrimaryColor;
    LOCATE 2, 35: PRINT SecondaryColor;
    LOCATE 3, 35: PRINT RedValue + GreenValue + BlueValue;
    LOCATE 4, 35: PRINT STR$(INT((189 - ABS(RedValue - PEEK(BytePos)) - ABS(GreenValue - PEEK(BytePos + 1)) - ABS(BlueValue - PEEK(BytePos + 2))) / 1.89)); "%";
    LOCATE 6, 36
    IF UsePrimaryColor THEN
        CurColor = PrimaryColor
        PRINT "Pri.";
    ELSE
        CurColor = SecondaryColor
        PRINT "Sec.";
    END IF
RETURN

DrawColorContrastSlider:
    LINE (0, 190)-(319, 195), DarkestColor, BF
    LINE (0, 196)-(319, 197), PrimaryColor, BF
    LINE (0, 198)-(319, 199), SecondaryColor, BF
    LINE (PrimaryColor, 190)-(PrimaryColor, 195), PrimaryColor, BF
    LINE (SecondaryColor, 190)-(SecondaryColor, 195), SecondaryColor, BF
RETURN

GetPrimaryColorValues:
    DEF SEG = VARSEG(ColorPalette(0))
    BytePos = PrimaryColor * 3
    RedValue = PEEK(BytePos)
    GreenValue = PEEK(BytePos + 1)
    BlueValue = PEEK(BytePos + 2)
RETURN

SetCurColorBar:
    IF UsePrimaryColor THEN
        CurColor = NewColor AND 255
        PrimaryColor = CurColor
        GOSUB GetPrimaryColorValues
        GOSUB ClearScreen
        GOSUB DrawColorContrastBars
    ELSE
        CurColor = NewColor AND 255
        SecondaryColor = CurColor
        GOSUB GetPrimaryColorValues
    END IF
    GOSUB DrawColorContrastInfo
    GOSUB DrawColorContrastSlider
RETURN

FindConstrastColors:
    DEF SEG = VARSEG(ColorPalette(0)): BytePos = 0
    DarkestColor = 0: DarkestValue = 1000
    BrightestColor = 15: BrightestValue = 0
    FOR Count = 0 TO 255
        ColorValue = PEEK(BytePos) + PEEK(BytePos + 1) + PEEK(BytePos + 2)
        IF ColorValue < DarkestValue THEN
            DarkestValue = ColorValue
            DarkestColor = Count
        END IF
        IF ColorValue > BrightestValue THEN
            BrightestValue = ColorValue
            BrightestColor = Count
        END IF
        BytePos = BytePos + 3
    NEXT Count
RETURN

ClearScreen:
    LINE (0, 0)-(319, 199), DarkestColor, BF
RETURN

CursorFramesData:
DATA &H3333,&H7777,&HFFFF,&HEEEE,&HCCCC,&H8888,0,&h1111

