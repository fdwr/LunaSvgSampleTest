DEFINT A-Z
DECLARE SUB DrawTextBorder (Urow%, Lcol%, Hite%, Wdth%)

DIM I AS INTEGER
DIM PL AS INTEGER
DIM TerrainColor AS INTEGER
DIM SZ AS DOUBLE
DIM Z(320), X(320) AS SINGLE, CLR(320) AS SINGLE

SCREEN 13
CLS
'CLEAR (pointless)

SelectedChoice = 0
TerrainColor = 0
Horizon = 0
HorizonColor = 1
Stars = 1

GetChoice:
'PL = 0
'FOR I = 100 TO 160
'    PALETTE I, 65536 * PL
'    PL = PL + 1
'NEXT I
'PRINT "Example of Voxel type terrain generation"
'PRINT "written in QuickBasic version 4.5."
DrawTextBorder 1, 4, 3, 32
LOCATE 1, 1
COLOR 11
LOCATE 2, 5: PRINT "Use arrow keys to change choices"
LOCATE 3, 5: PRINT "Press Enter to view landscape,"
LOCATE 4, 5: PRINT "Or press Esc to exit"

DrawTextBorder 7, 4, 4, 32
FOR Choice = 0 TO 3
    GOSUB DrawChoice
NEXT Choice

DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE CHR$(0) + "H": ChoiceDir = -1: GOSUB ChangeChoice
    CASE CHR$(0) + "P": ChoiceDir = 1: GOSUB ChangeChoice
    CASE CHR$(0) + "K": ChoiceDir = -1: GOSUB ChangeAtr
    CASE CHR$(0) + "M": ChoiceDir = 1: GOSUB ChangeAtr
    CASE CHR$(27): EXIT DO
    CASE CHR$(13)
        CLS
        GOSUB DrawScape
        DrawTextBorder 1, 15, 1, 8
        LOCATE 2, 16: PRINT "Done...."
        DO: LOOP UNTIL LEN(INKEY$)
        GOTO GetChoice
    END SELECT
LOOP
SCREEN 0
END


DrawChoice:
    SELECT CASE Choice
    CASE 0: MenuIndex = TerrainColor: MenuText$ = "Ice\Jungle\Desert\Mountain"
    CASE 1: MenuIndex = Horizon:      MenuText$ = "Horizon\Star"
    CASE 2: MenuIndex = Stars:        MenuText$ = "Clear sky\Stars"
    CASE 3: MenuIndex = HorizonColor: MenuText$ = "Yellow\Blue\Pink\Green"
    END SELECT
    IF Choice = SelectedChoice THEN ChoiceClr = 11 ELSE ChoiceClr = 3
    Index = 0
    CurPos = 1
    LOCATE Choice + 8, 6
    DO
        NextPos = INSTR(CurPos, MenuText$, "\")
        IF NextPos <= 0 THEN
            MenuChoiceLen = LEN(MenuText$) - NextPos
        ELSE
            MenuChoiceLen = NextPos - CurPos
        END IF
        IF Index = MenuIndex THEN
            'COLOR 15:        PRINT "<";
            COLOR 15:        PRINT "";
            COLOR ChoiceClr: PRINT MID$(MenuText$, CurPos, MenuChoiceLen);
            COLOR 15:        PRINT "";
        ELSE
            COLOR ChoiceClr
            PRINT " "; MID$(MenuText$, CurPos, MenuChoiceLen); " ";
        END IF
        Index = Index + 1
        CurPos = NextPos + 1
    LOOP WHILE NextPos
RETURN


ChangeChoice:
    Choice = SelectedChoice
    SelectedChoice = (SelectedChoice + ChoiceDir + 4) MOD 4
    GOSUB DrawChoice
    Choice = SelectedChoice
    GOSUB DrawChoice
RETURN


ChangeAtr:
    SELECT CASE SelectedChoice
    CASE 0: TerrainColor = (TerrainColor + ChoiceDir) AND 3
    CASE 1: Horizon = Horizon XOR 1
    CASE 2: Stars = Stars XOR 1
    CASE 3: HorizonColor = (HorizonColor + ChoiceDir) AND 3
    END SELECT
    Choice = SelectedChoice
    GOSUB DrawChoice
RETURN


DrawScape:
    PL = 0
    FOR I = 100 TO 160
        PLL = CINT(PL * .67)
        IF PLL > 60 THEN PLL = 60
        SELECT CASE TerrainColor
        CASE 0: PALETTE I, 65536 * PL
        CASE 1: PALETTE I, 65536 + 256 * PL
        CASE 2: PALETTE I, 65536 + 256 * PLL + PL
        CASE 3: PALETTE I, 65536 * PL + 256 * PL + PL
        END SELECT
        PL = PL + 1
    NEXT I
    'set horizon palette
    PL = 0
    FOR I = 170 TO 230
        PLL = PL * 2
        IF PLL > 60 THEN PLL = 60
        SELECT CASE HorizonColor
        CASE 0: PALETTE I, 65536 * PL + 256 * PLL + PLL 'yellow
        CASE 1: PALETTE I, 65536 * PLL + 256 * PL + PL  'blue
        CASE 2: PALETTE I, 65536 * PL + 256 * PL + PLL  'pink
        CASE 3: PALETTE I, 65536 * PL + 256 * PLL + PL  'green
        END SELECT
        PL = PL + 1
    NEXT I

    'draw either horizon or sun
    Z = 10 + 300 * RND: ZZ = 100 - 95 * RND: MV = 20 * RND
    'EEE = 100 * RND
    'IF EEE < 30 THEN
    IF Horizon THEN
        FOR I = 0 TO 60
            CIRCLE (Z, ZZ), 80 - I, 170 + I
            PAINT (Z, ZZ), 170 + I, 170 + I
        NEXT I
    ELSE
        FOR I = 0 TO 60
            LINE (0, 99 - I)-(319, 99 - I), 230 - I
        NEXT I
        LINE (0, 100)-(319, 199), 230, BF
    END IF

    'stars
    IF Stars THEN
        FOR I = 0 TO 500
            DO
                X = 319 * RND: XX = 190 * RND: XCLR = POINT(X, XX)
            LOOP WHILE XCLR > 220
            IF XCLR > 180 THEN VCLR = (31 - ((220 - XCLR) / 4) * RND) ELSE VCLR = 17 + 13 * RND
            PSET (X, XX), VCLR
        NEXT I
    END IF

    Z(0) = 0: X(0) = 100: SZ = 1: CLR(0) = 130
    FOR I = 1 TO 320
        Z(I) = Z(I - 1) + SZ
        X(I) = X(I - 1) - SZ + (SZ * 2) * RND
        CLR(I) = CLR(I - 1) - 5 + (10 * RND)
        IF CLR(I) < 100 THEN
            CLR(I) = 100
        ELSEIF CLR(I) > 160 THEN
            CLR(I) = 160
        END IF
        'LINE (Z(i), X(i))-(Z(i) + SZ, X(i) + SZ), CLR(i), BF
    NEXT I

    'landscape
    DO
        SZ = SZ * 1.012
        CHK = 0
        Z(0) = 0 - (SZ - 1) * 160: X(0) = X(0) + SZ * RND
        FOR I = 1 TO 320
            Z(I) = Z(I - 1) + SZ
            X(I) = X(I) - SZ / 4 + SZ * RND
            IF X(I) < X(I - 1) - SZ THEN X(I) = X(I - 1) - SZ
            IF X(I) > X(I - 1) + SZ THEN X(I) = X(I - 1) + SZ
            IF Z(I) >= -4 AND Z(I) < 320 THEN
                CLR(I) = CLR(I) - 4 + (8 * RND)
                IF CLR(I) < CLR(I - 1) - 3 THEN CLR(I) = CLR(I - 1) - 3
                IF CLR(I) > CLR(I - 1) + 3 THEN CLR(I) = CLR(I - 1) + 3
                IF CLR(I) < 100 THEN
                    CLR(I) = 100
                ELSEIF CLR(I) > 160 THEN
                    CLR(I) = 160
                END IF
                LINE (Z(I), X(I))-(Z(I) + SZ + 1, X(I) + SZ + 1), CLR(I), BF
            END IF
            IF X(I) > 199 THEN CHK = CHK + 1
         NEXT I
    LOOP UNTIL LEN(INKEY$) OR CHK > 319
RETURN


1 SCREEN 13: CLS : CLEAR
5 GOTO 1000
10 SCREEN 13: CLS
11 PL = 0
12 FOR I = 100 TO 160: PLL = CINT(PL * .67): IF PLL > 60 THEN PLL = 60
13 IF T = 1 THEN PALETTE I, 65536 * PL
14 IF T = 2 THEN PALETTE I, 65536 + 256 * PL
15 IF T = 3 THEN PALETTE I, 65536 + 256 * PLL + PL
17 IF T = 4 THEN PALETTE I, 65536 * PL + 256 * PL + PL
20 PL = PL + 1: NEXT I
21 PL = 0
22 FOR I = 170 TO 230: PLL = PL * 2: IF PLL > 60 THEN PLL = 60
23 PALETTE I, 65536 * PLL + 256 * PL + PL: PL = PL + 1: NEXT I
30 Z = 10 + 300 * RND: ZZ = 100 - 95 * RND: MV = 20 * RND
35 EEE = 100 * RND: IF EEE < 30 THEN GOTO 40 ELSE GOTO 50
40 FOR I = 0 TO 60: LINE (0, 99 - I)-(319, 99 - I), 230 - I: NEXT I
42 LINE (0, 100)-(319, 199), 230, BF
45 GOTO 80
50 FOR I = 0 TO 60: CIRCLE (Z, ZZ), 80 - I, 170 + I
52 PAINT (Z, ZZ), 170 + I, 170 + I
55 NEXT I
80 FOR I = 0 TO 500
81 X = 319 * RND: XX = 190 * RND: XCLR = POINT(X, XX)
82 IF XCLR > 220 THEN GOTO 81
83 IF XCLR > 180 THEN VCLR = (31 - ((220 - XCLR) / 4) * RND) ELSE VCLR = 17 + 13 * RND
85 PSET (X, XX), VCLR: NEXT I

'100 DIM Z(320), X(320), CLR(320)
110 Z(0) = 0: X(0) = 100: SZ = 1: CLR(0) = 130
120 FOR I = 1 TO 320: Z(I) = Z(I - 1) + SZ
125 X(I) = X(I - 1) - SZ + (SZ * 2) * RND
127 CLR(I) = CLR(I - 1) - 5 + (10 * RND): IF CLR(I) < 100 THEN CLR(I) = 100
128 IF CLR(I) > 160 THEN CLR(I) = 160
130 LINE (Z(I), X(I))-(Z(I) + SZ, X(I) + SZ), CLR(I), BF: NEXT I
180 CHK = 0
190 SZ = SZ * 1.012
195 Z(0) = 0 - (SZ - 1) * 160: X(0) = X(0) + SZ * RND
200 FOR I = 1 TO 320: Z(I) = Z(I - 1) + SZ
205 X(I) = X(I) - SZ / 4 + SZ * RND: IF X(I) < X(I - 1) - SZ THEN X(I) = X(I - 1) - SZ
207 IF X(I) > X(I - 1) + SZ THEN X(I) = X(I - 1) + SZ
209 IF Z(I) < -1 OR Z(I) > 320 THEN GOTO 220
210 CLR(I) = CLR(I) - 4 + (8 * RND)
211 IF CLR(I) < CLR(I - 1) - 3 THEN CLR(I) = CLR(I - 1) - 3
212 IF CLR(I) > CLR(I - 1) + 3 THEN CLR(I) = CLR(I - 1) + 3
217 IF CLR(I) < 100 THEN CLR(I) = 100
218 IF CLR(I) > 160 THEN CLR(I) = 160
219 LINE (Z(I), X(I))-(Z(I) + SZ + 1, X(I) + SZ + 1), CLR(I), BF
220 IF X(I) > 199 THEN CHK = CHK + 1: IF CHK > 319 THEN GOTO 300
225 NEXT I
230 KY$ = INKEY$: IF KY$ = "" THEN GOTO 240 ELSE GOTO 300
240 CHK = 0: GOTO 190
300 LOCATE 1, 1: PRINT "Done...."
310 KY$ = INKEY$: IF KY$ = "" THEN GOTO 310
350 GOTO 1000
1000 PL = 0
1001 FOR I = 100 TO 160: PALETTE I, 65536 * PL: PL = PL + 1: NEXT I
1020 LOCATE 1, 1
1030 PRINT "Example of Voxel type terrain generation"
1035 PRINT "written in QuickBasic version 4.5."
1040 PRINT "": PRINT "    Select color choice:"
1050 PRINT "1 - DESERT"
1055 PRINT "2 - ICE"
1070 PRINT "3 - EXIT"
1080 R = 100 * RND: KY$ = INKEY$: IF KY$ = "1" THEN T = 3: GOTO 1100
1081 IF KY$ = "2" THEN T = 4: GOTO 1100
1084 IF KY$ = "3" THEN END
1085 GOTO 1080
1100 GOTO 10

SUB DrawTextBorder (Urow, Lcol, Hite, Wdth)

X = Lcol * 8
Y = Urow * 8
X2 = X + Wdth * 8
Y2 = Y + Hite * 8
LINE (X - 4, Y - 4)-(X2 + 3, Y2 + 3), 7, BF
LINE (X - 2, Y - 2)-(X2 + 1, Y2 + 1), 0, BF

END SUB

