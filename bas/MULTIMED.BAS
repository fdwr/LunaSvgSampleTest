DEFINT A-Z
DECLARE SUB CENTER (Ulin, Text$)
DECLARE SUB PRINT2 (Vset, Hset, Scrn, Text$)
DECLARE SUB PICTDRAW (Hite, Widt, Ulin, Lcol, Pic$)
DECLARE SUB TEXTWRAP (Hite, Widt, Lcol, Ulin, Text$)
DECLARE SUB SCALE (FRACT!, TOTAL!, Urow, Lcol, Rcol, Mode)
DECLARE SUB SCROLLBAR (AF1, AF2, AT1, AT2, Side1, Side2, Lin, Mode)
DECLARE SUB BTTNDRAW (Lcol, Rcol, Ulin, Dlin, Fore, Back)
DECLARE SUB BOXDRAWR (Urow, Lcol, Drow, Rcol, Fore, Back, TitC, Titl$)
DECLARE SUB BOXDRAW5 (Row1, Row2, Col1, Col2, Fore, Back, Side, Titl$)
DECLARE SUB ENDING ()
DECLARE FUNCTION ROUND% (a!)
DECLARE FUNCTION TRUNCATE% (Nmbr1%, Nmbr2%, Mode%)
DECLARE FUNCTION BIN$ (a AS ANY)
DECLARE FUNCTION SELECTPART$ (Text$, PART)
DECLARE FUNCTION REPLACE$ (tex1$, Tex2$, Start)
DECLARE FUNCTION DSPACE$ (Text$)
DECLARE FUNCTION DELETE$ (Text$, ST, Leng)
DECLARE FUNCTION INSERT$ (a$, b$, Offset%)
DECLARE FUNCTION STRNG$ (Leng, Quote$)
DECLARE FUNCTION COUNTS% (Text$, Element$)
DECLARE FUNCTION MEMSEARCH% (Text$, Start%, endig%)
DECLARE FUNCTION STRINGPROMPT$ (Leng, RecLen, Result$, Keys$)
DIM SHARED DosV%, DosH%: DosV% = CSRLIN: DosH% = POS(0): PCOPY 0, 1
COLOR 0, 9: CLS : LOCATE , , 0
Start:

Times = Times + 1: GOSUB Reader
DelayTest:
BeforeTime# = TIMER
COLOR 23, 1: LOCATE 13
LOCATE 13, 35: PRINT "Waiting...";
DO UNTIL TIMER - BeforeTime# > 1.6
LOOP
COLOR 15, 1
DO UNTIL INKEY$ > ""
 LOCATE , 32: PRINT "Still Waiting...";
 FOR delay% = 1 TO 10000: NEXT delay%
 LOCATE , 32: PRINT SPACE$(16);
 FOR delay% = 1 TO 10000: NEXT delay%
LOOP

Times = Times + 1: GOSUB Reader
BoxDrawerTest:
DO UNTIL INKEY$ > ""
BOXDRAWR INT(RND * 12 + 1), INT(RND * 39 + 1), INT(RND * 13 + 13), INT(RND * 40 + 41), 15, 0, 7, "Boxdrawer!"
LOOP
U = 1: L = 1: D = 25: R = 80
DO
IF U + 1 > 25 THEN UD = 0 ELSE IF U - 1 <= 1 THEN UD = 1
IF UD THEN U = U + 1 ELSE U = U - 1
IF D + 1 > 25 THEN DD = 0 ELSE IF D - 1 < 1 THEN DD = 1
IF DD THEN D = D + 1 ELSE D = D - 1
IF L + 2 > 80 THEN LD = 0 ELSE IF L - 2 < 1 THEN LD = 1
IF LD THEN L = L + 2 ELSE L = L - 2
IF R + 2 > 80 THEN RD = 0 ELSE IF R - 2 < 1 THEN RD = 1
IF RD THEN R = R + 2 ELSE R = R - 2
BOXDRAW5 U, D, L, R, 15, 7, 255, ""
'FOR De = 1 TO 1000: NEXT
LOOP UNTIL INKEY$ > ""

Times = Times + 1: GOSUB Reader
PictDrawTest:
COLOR , 9: CLS 0
DO UNTIL INKEY$ > ""
PICTDRAW 4, 20, 2, 30, " X ÄÄÄÄÄÄÄÄÄÄÄÄÄ  Y ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³  ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³"
PICTDRAW 8, 18, 1, 2, "   ÚÄÂÄÂÄÂÄÂÄÂÄÂÄ¿  ÚÄÂÄÂÄÂÄÂÄÂÄÂÄ¿´ ÚÄÂÄÂÄÂÄÂÄÂÄÂÄ¿´´ÚÄÂÄÂÄÂÄÂÄÂÄÂÄ¿´´´ÃÄÅÄÅÄÅÄÅÄÅÄÅÄ´´´ÙÃÄÅÄÅÄÅÄÅÄÅÄÅÄ´´Ù ÃÄÅÄÅÄÅÄÅÄÅÄÅÄ´Ù  ÀÄÁÄÁÄÁÄÁÄÁÄÁÄÙ   "
LOOP

Times = Times + 1: GOSUB Reader
ScaleTest:
COLOR 14, 7
FOR t! = 0 TO 32 STEP .5
SCALE t!, 32, 1, 1, 80, 0
SCALE t!, 32, 1, 1, 25, 1
SCALE t!, 32, 25, 80, 1, 0
SCALE t!, 32, 80, 25, 1, 1
NEXT
FOR t! = 32 TO 0 STEP -.5
SCALE t!, 32, 1, 1, 80, 0
SCALE t!, 32, 1, 1, 25, 1
SCALE t!, 32, 25, 80, 1, 0
SCALE t!, 32, 80, 25, 1, 1
NEXT
FOR t! = 0 TO 32 STEP .5
SCALE t!, 32, 1, 79, 1, 0
SCALE t!, 32, 1, 2, 25, 1
SCALE t!, 32, 25, 2, 80, 0
SCALE t!, 32, 80, 24, 1, 1
NEXT

Times = Times + 1: GOSUB Reader
GOSUB Reader
GOSUB Reader
ScrollBarTest:
DO
COLOR 15, 7
IF Kbd$ = CHR$(0) + "M" THEN H% = H% + 1
IF Kbd$ = CHR$(0) + "K" THEN H% = H% - 1
IF Kbd$ = CHR$(0) + "P" THEN V% = V% + 1
IF Kbd$ = CHR$(0) + "H" THEN V% = V% - 1
SCROLLBAR 1 + H%, 8 + H%, 1, 20, 1, 79, 1, 0
SCROLLBAR 1 + V%, 8 + V%, 1, 20, 2, 25, 1, 1
SCROLLBAR 1 + H%, 28 + H%, 1, 40, 80, 2, 25, 0
SCROLLBAR 1 + V%, 28 + V%, 1, 40, 1, 24, 80, 1
Kbd$ = INKEY$: WHILE Kbd$ = "": Kbd$ = INKEY$: WEND
LOOP UNTIL Kbd$ = "" OR Kbd$ = CHR$(13)

Times = -1
GOSUB Reader
ENDING:
PCOPY 1, 0
LOCATE DosV%, DosH%
SYSTEM

Reader:
COLOR 10, 3: LOCATE 1, 1: READ Text$
IF Times = -1 THEN Titl$ = "That's all folks" ELSE Titl$ = "Demonstration of subprograms" + STR$(Times)
BOXDRAWR 6, 7, 19, 74, 10, 3, 15, Titl$
IF Times = -1 THEN CENTER 17, "Press any key to quit" ELSE CENTER 17, "Press ESC to quit, any other key to continue"
BTTNDRAW 9, 72, 7, 15, 7, 3
 IF LEN(Text$) THEN Hite = INT(LEN(Text$) / 64) + 1
 COLOR 15, 7: TEXTWRAP Hite, 64, 8, 7, Text$
WHILE INKEY$ > "": WEND: Kbd$ = INKEY$
WHILE Kbd$ = "": Kbd$ = INKEY$: WEND
IF Kbd$ = "" THEN GOTO ENDING
IF Kbd$ = " " AND Times = -1 THEN RESTORE: GOTO Start
RETURN

DATA "This flashing delay test is a simple, easy way to create an     'active' pause. It is easy to make a 'pause' in a program but,  this grabs your attention with flashing animation. The first oneuses the timer to count one second before proceeding. The secondone waits until a key is pressed before moving on.
DATA "BOXDRAWR can be used to draw a simple, bordered box between any coordinates on the screen as long as their within range of its  limits. Each box really only needs four elements to draw a box: Top, Left, Bottom, and Right side. However, you can also includefore and background colors (fore, back), a title (Titl$), and a title color(Titl). The first demonstration uses randomly chosen coordinates to draw boxes while the second one uses an intricaterepeating pattern. This paragraph that you are reading actually owes thanks to BOXDRAWR for making its border.
DATA "This draws two pictures with ASCII characters using PICTDRAW"
DATA "SCALE draws a scaled bar between two points (Side1 to Side2) on the screen. It can draw the scaled bar horizontal or vertical   (which is determined by mode%). The fraction (Fract!) and total (Total!) can be any relation to each other; SCALE automatically adjusts the bar to fit between the two points while still being proportionally accurate."
DATA "Next to the box drawer, this next subprogram is one of my best. It the common yet powerful scroll bar. I'm sure you have alreadyheard of this wonderful invention, especially if have ever used windows. It was invented so that people could get a quick and   easy idea of where they were at in a selected viewing portion ofa document, picture, and so on. You can tell you wether you are at the top, bottom, or middle; you can even tell you how much   you are looking at compared to the total. If you had a scroll   bar, you would be able to tell when this paragraph would stop.
DATA " Just like the prior sub, 'ScrollBar' uses mathematical formulasto convert and strech the actual factors and ratios into propor-tionally sized drag-boxes and such that fit in between the two  coordinates (Side1, Side2) specified. The first two factors are the start and end of the present view portion. The second two   are the start and end of the total (ie. lines 20 to 40 out of 1 to 100). Lin specifies the line or column, depending on wether  it is a horizontal or vertical scroll bar which is determined bymode%. Mode% is a boolean switch so 0 would be ,1 would be .
DATA "Use the arrow keys to change the position of the drag-box withinthe bar. The () arrows control the vertical bar while the ()arrows control the horizontal bar. If either side of the the subpart (drag-box) is out of range, the shape of the sidearrow willchange to show that. When your done playing with the scroll bar press ESC. Note that the scrollbar is not directly linked to thekeyboard or mouse; instead all variables must be passed on to itfrom the part of program that calls it. Therefore, it sadly doesnot directly support a mouse.
DATA "Well, those are all of my subprogram demonstrations. For Now...
'Truncate Chooses the lesser or greater of two numbers depending on the mode
'BoxDrawr Makes bordered boxes on the screen to the given coordinates
'Replace$ Replaces part of one string of text another with another
'Condense Condenses a string of text by taking out extra spaces
'TextWrap Prints wordwrapped a string of text on the screen
'PictDraw Draws an ASCII picture anywhere on the screen
'BttnDraw Makes "3D" colored buttons with a shadow

'INT((80 - LEN(text$)) / 2) Text/Picture centering formula for left side
'INT((80 + LEN(text$)) / 2) - 1 Centering formula for right side
'Wrap = INT(SQR(LEN(text$) / (80 * 25)) * 80) + 1
'Finds the word wrap length for a given ratio
'Real = (Vset - 1) * (ScreenWidth * 2) + (Hset - 1) * 2
'Finds absolute text coordinates on screen

'ROUND((Number - 1) * (Width / Total) + 1) finds left coordinate of box
'ROUND(Boxnumber * (Width / Total)) finds right coordinate of box
'ROUND(Width / Total) finds actual length of box using screen width

'Text$ = LEFT$(Text$, LEN(Text$) - 1) used to delete the end or last
'character of a text prompt or list
'Text$ = LEFT$(Text$, ST - 1) + RIGHT$(Text$, LEN(Text$) - (ST + LG) + 1)
'Formula for deleting a certain portion out a larger portion

FUNCTION BIN$ (x)
b$ = "00000000"
IF x AND &H80 THEN MID$(b$, 1) = "1"
IF x AND &H40 THEN MID$(b$, 2) = "1"
IF x AND &H20 THEN MID$(b$, 3) = "1"
IF x AND &H10 THEN MID$(b$, 4) = "1"
IF x AND &H8 THEN MID$(b$, 5) = "1"
IF x AND &H4 THEN MID$(b$, 6) = "1"
IF x AND &H2 THEN MID$(b$, 7) = "1"
IF x AND &H1 THEN MID$(b$, 8) = "1"
BIN$ = b$
END FUNCTION

SUB BOXDRAW5 (Row1, Row2, Col1, Col2, Fore, Back, Side, Titl$)
IF Row1 > Row2 THEN SWAP Row1, Row2: Chng = Chng XOR 1
IF Col1 > Col2 THEN SWAP Col1, Col2: Chng = Chng XOR 2
COLOR Fore, Back: BoxWidth = Col2 - Col1 + 1

IF (Side AND 256) AND Col1 < Col2 THEN FOR Vset = Row1 + 1 TO Row2 - 1: LOCATE Vset, Col1 + 1: PRINT SPACE$(BoxWidth - 2); : NEXT Vset
IF Side AND 1 THEN LOCATE Row1, Col1: PRINT "Ú";
IF Side AND 2 THEN LOCATE Row1, Col2: PRINT "¿";
IF Side AND 4 THEN LOCATE Row2, Col1: PRINT "À";
IF Side AND 8 THEN LOCATE Row2, Col2: PRINT "Ù";
IF Side AND 16 THEN IF Col1 = Col2 THEN LOCATE Row1, Col1: PRINT "Â";  ELSE LOCATE Row1, Col1 + 1: PRINT STRING$(BoxWidth - 2, "Ä");
IF Side AND 32 THEN IF Col1 = Col2 THEN LOCATE Row2, Col1: PRINT "Á";  ELSE LOCATE Row2, Col1 + 1: PRINT STRING$(BoxWidth - 2, "Ä");
IF Side AND 64 THEN IF Row1 = Row2 THEN LOCATE Row1, Col1: PRINT "Ã";  ELSE FOR Vset = Row1 + 1 TO Row2 - 1 STEP 1: LOCATE Vset, Col1: PRINT "³"; : NEXT Vset
IF Side AND 128 THEN IF Row1 = Row2 THEN LOCATE Row1, Col2: PRINT "´";  ELSE FOR Vset = Row1 + 1 TO Row2 - 1 STEP 1: LOCATE Vset, Col2: PRINT "³"; : NEXT Vset
'IF Side AND 16 THEN FOR Hset = Col1 + 1 TO Col2 - 1: LOCATE Row1, Hset: PRINT "Ä"; : NEXT Hset
'IF Side AND 32 THEN FOR Hset = Col1 + 1 TO Col2 - 1: LOCATE Row2, Hset: PRINT "Ä"; : NEXT Hset

IF Chng AND 1 THEN LOCATE Row2 ELSE LOCATE Row1
LOCATE , Col1 + (BoxWidth - LEN(LEFT$(Titl$, BoxWidth))) / 2: PRINT LEFT$(Titl$, BoxWidth);
IF Chng AND 1 THEN SWAP Row1, Row2
IF Chng AND 2 THEN SWAP Col1, Col2
END SUB

SUB BOXDRAWR (Urow, Lcol, Drow, Rcol, Fore, Back, TitC, Titl$)
COLOR Fore, Back
BoxWidth = Rcol - Lcol + 1: Side$ = "³" + SPACE$(BoxWidth - 2) + "³"
LOCATE Urow, Lcol: PRINT "Ú"; STRING$(BoxWidth - 2, "Ä"); "¿";
FOR Hset = Urow + 1 TO Drow - 1: LOCATE Hset, Lcol: PRINT Side$; : NEXT Hset
LOCATE Drow, Lcol: PRINT "À"; STRING$(BoxWidth - 2, "Ä"); "Ù";
LOCATE Urow, Lcol + (BoxWidth - LEN(MID$(Titl$, 1, BoxWidth - 2))) / 2
COLOR TitC, Back: PRINT MID$(Titl$, 1, BoxWidth)
END SUB

SUB BTTNDRAW (Lcol, Rcol, Ulin, Dlin, Fore, Back)
IF Dlin > 25 THEN Dlin = 25
IF Rcol > 80 THEN Rcol = 80
Lcol = TRUNCATE(Lcol, 1, 1)
Bwidth = TRUNCATE(Rcol, 80, 0) - TRUNCATE(Lcol, 1, 1) + 1

COLOR Back, Fore
FOR Hset = TRUNCATE(Ulin, 1, 1) TO Dlin
 LOCATE Hset, Lcol: PRINT SPACE$(Bwidth);
NEXT Hset

COLOR Sfor
IF Rcol < 80 AND Bwidth > 0 THEN
 IF Ulin > 0 THEN PRINT2 Ulin, Rcol + 1, 80, "Ü": Prow = ((Ulin - 1) * 80 + Rcol) * 2 + 1: POKE Prow, (PEEK(Prow) AND 240) OR Sfor
 FOR Hset = TRUNCATE(Ulin, 0, 1) + 1 TO Dlin
  LOCATE Hset, Rcol + 1: PRINT "Û";
 NEXT Hset
END IF
IF Bwidth > 0 THEN
 Prow = Dlin * 80
 FOR Show = (Prow + Lcol) * 2 TO (Prow + Rcol) * 2 STEP 2
  POKE Show + 1, (PEEK(Show + 1) AND 240) OR Sfor
 NEXT Show
 PRINT2 Dlin + 1, TRUNCATE(Lcol + 1, 1, 1), 80, STRING$(TRUNCATE(Rcol, 79, 0) - TRUNCATE(Lcol, 0, 1) + 1, "ß")
END IF
END SUB

DEFSNG A-Z
SUB CENTER (Ulin%, Text$)
LOCATE Ulin%, CINT((80 - LEN(Text$)) / 2): PRINT Text$
END SUB

DEFINT A-Z
FUNCTION COUNTS (Text$, Element$)
ElemLen = LEN(Element$)

FOR s = 1 TO LEN(Text$)
 IF MID$(Text$, s, ElemLen) = Element$ THEN c = c + 1
NEXT s

COUNTS = c
END FUNCTION

DEFSNG A-Z
FUNCTION DELETE$ (Text$, ST%, Lg%) : DELETE$ = LEFT$(Text$, TRUNCATE(ST% - 1 + TRUNCATE(Lg%, 0, 0), 0, 1)) + RIGHT$(Text$, TRUNCATE(LEN(Text$) - (ST% + TRUNCATE(Lg%, 0, 1)) + 1, 0, 1)): END FUNCTION

FUNCTION DSPACE$ (Text$)
WHILE INSTR(1, Text$, "  ")
Text$ = LEFT$(Text$, INSTR(1, Text$, "  ")) + LTRIM$(RIGHT$(Text$, LEN(Text$) - INSTR(1, Text$, "  ")))
WEND
DSPACE$ = Text$
END FUNCTION

FUNCTION INSERT$ (a$, b$, Offset%) : IF Offset% < 0 OR Offset% > LEN(a$) THEN INSERT$ = a$: END FUNCTION ELSE INSERT$ = LEFT$(a$, Offset%) + b$ + RIGHT$(a$, LEN(a$) - Offset%): END FUNCTION

DEFINT A-Z
SUB MAKENOTE (x%)
'n# - Note Multiple Constant
't% - Pitch Multiple base
'l% - Note Sound Limit
CONST n# = 1.059463094359296#, t% = 64, L% = 107
tone# = t%
IF x > L THEN x = L
FOR note = 1 TO x
 tone# = n# * tone#
 PRINT note, tone#
NEXT note
 SOUND INT(tone#), 2
END SUB

FUNCTION MEMSEARCH (Text$, Start, endig)
FOR SG = Start TO endig - LEN(Text$)
 IF CHR$(PEEK(SG)) = LEFT$(Text$, 1) THEN
  FOR SG2 = 0 TO LEN(Text$) - 1
   text2$ = text2$ + CHR$(PEEK(SG + SG2))
  NEXT SG2
 END IF
 IF text2$ = Text$ THEN SEARCH = SG: EXIT FUNCTION ELSE text2$ = ""
NEXT SG
SEARCH = -1
END FUNCTION

SUB PICTDRAW (Hite, Wdth, Urow, Lcol, Pic$)
DEF SEG = &HB800
IF Hite <> INT((LEN(Pic$) / Wdth)) THEN Vite = INT((LEN(Pic$) / Wdth)) ELSE Vite = Hite
FOR Vset = Urow TO Urow + Hite - 1
FOR Hset = Lcol TO Lcol + Wdth - 1
Move = Move + 1: POKE (Vset * 80 + Hset) * 2, ASC(MID$(Pic$, Move, 1))
NEXT Hset, Vset
END SUB

SUB PRINT2 (Urow, Lcol, Scrn%, Text$)
DEF SEG = &HB800: Real = (Urow - 1) * Scrn% + (Lcol - 1)
FOR Show = 0 TO LEN(Text$) - 1
 POKE (Real + Show) * 2, ASC(MID$(Text$, Show + 1, 1))
NEXT Show
END SUB

DEFSNG A-Z
FUNCTION REPLACE$ (tex1$, Tex2$, Start%)

Tex3$ = tex1$
IF Start% < 1 THEN
 tex4$ = RIGHT$(Tex2$, LEN(Tex2$) + Start% - 1)
ELSE
 tex4$ = Tex2$
END IF

IF tex1$ > "" AND Start% <= LEN(tex1$) THEN
 MID$(Tex3$, TRUNCATE(Start%, 1, 1)) = tex4$
END IF
REPLACE$ = Tex3$

END FUNCTION

FUNCTION ROUND% (a!)
IF a! - INT(a!) >= .5 THEN ROUND% = INT(a!) + 1 ELSE ROUND% = INT(a!)
END FUNCTION

DEFINT A-Z
SUB SCALE (FRACT!, TOTAL!, Urow, Lcol, Rcol, Mode)
IF Lcol > Rcol THEN LENGT = Lcol - Rcol + 1 ELSE LENGT = Rcol - Lcol + 1
PART = CINT((FRACT! * LENGT) / TOTAL!)
IF PART > LENGT THEN PART = LENGT

IF Mode THEN
IF Lcol > Rcol THEN
FOR Vset = Lcol TO Lcol - PART + 1 STEP -1
LOCATE Vset, Urow: PRINT "Û";
NEXT Vset
FOR Vset = Lcol - PART TO Rcol STEP -1
LOCATE Vset, Urow: PRINT "°";
NEXT Vset
ELSE
FOR Vset = Lcol TO Lcol + PART - 1 STEP 1
LOCATE Vset, Urow: PRINT "Û";
NEXT Vset
FOR Vset = Lcol + PART TO Rcol STEP 1
LOCATE Vset, Urow: PRINT "°";
NEXT Vset
END IF
ELSEIF Mode = 0 THEN
IF Lcol > Rcol THEN
LOCATE Urow, Rcol
PRINT STRING$(LENGT - PART, "°") + STRING$(PART, "Û");
ELSE
LOCATE Urow, Lcol
PRINT STRING$(PART, "Û") + STRING$(LENGT - PART, "°");
END IF
END IF
END SUB

SUB SCROLLBAR (AF1, AF2, AT1, AT2, Side1, Side2, Lin, Mode)

TBL = ABS(Side2 - Side1 + SGN(Side2 - Side1)) - 2
ABL = ABS(AT1 - AT2 + SGN(AT1 - AT2))
 IF TBL < 1 OR ABL = 0 THEN EXIT SUB
TPL = TRUNCATE(TRUNCATE(ABS(AF1 - AF2 + SGN(AF1 - AF2)), 1, 1) * TBL / ABL, 1, 1)
TPO = (TRUNCATE((AF1), (AF2), 0) - AT1) * TBL / TRUNCATE((AT1), (AT2), 1)

RPL = TRUNCATE(TPL - TRUNCATE(TPO + TPL - TBL, 0, 1), 0, 1): RPO = TPO
IF TPO < 0 THEN RPL = TRUNCATE(TPL + TPO, 0, 1): RPO = 0 ELSE IF TPO >= TBL THEN RPO = 0
Bar$ = STRING$(TBL, 176): MID$(Bar$, 1 + RPO, RPL) = STRING$(RPL, "Û")

IF Mode THEN
 LOCATE Side1, Lin: IF TPO < 0 THEN PRINT "";  ELSE PRINT "";
 LOCATE Side2, Lin: IF TPO + TPL > TBL THEN PRINT "";  ELSE PRINT "";
 FOR Vset = 1 TO TBL
  LOCATE Side1 + Vset, Lin
  PRINT MID$(Bar$, Vset, 1);
 NEXT Vset
ELSE
 LOCATE Lin, Side1: IF TPO < 0 THEN PRINT "®";  ELSE PRINT "";
 LOCATE Lin, Side2: IF TPO + TPL > TBL THEN PRINT "¯";  ELSE PRINT "";
 LOCATE Lin, TRUNCATE((Side1), (Side2), 0) + 1: PRINT Bar$;
END IF
END SUB

FUNCTION SELECTPART$ (Text$, PART)
FOR SEARCH = 1 TO LEN(Text$)
 IF MID$(Text$, SEARCH, 1) = " " THEN Son = 0 ELSE IF Son = 0 THEN Son = -1: Part1 = SEARCH: Count = Count + 1: IF Count >= PART THEN EXIT FOR
NEXT SEARCH

IF Count < PART THEN
 SELECTPART$ = ""
ELSE
 IF INSTR(Part1, Text$, " ") THEN Part2 = INSTR(Part1, Text$, " ") - 1 ELSE Part2 = LEN(Text$)
 SELECTPART$ = MID$(Text$, Part1, Part2 - Part1 + 1)
END IF
END FUNCTION

FUNCTION STRINGPROMPT$ (Length, RecLen, Result$, Keys$) STATIC
Hlin = CSRLIN
Lcol = POS(0)
Change = -1
Done = 0

DO
IF Change THEN
LOCATE Hlin, Lcol, 0: PRINT RIGHT$(Result$, Length);
PreCur = CSRLIN: PrePos = POS(0)
IF LEN(Result$) < PreLen AND LEN(Result$) < Length THEN
 PRINT SPACE$(PreLen - LEN(Result$));
END IF
LOCATE PreCur, PrePos
IF PrintAll THEN LOCATE , , 1, 3, 6 ELSE LOCATE , , 1, 5, 6
PreLen = LEN(Result$)
Change = 0
END IF

Kbd$ = INKEY$
SELECT CASE Kbd$
  CASE " " TO "~", "€" TO "ÿ"
IF LEN(Result$) < RecLen THEN
Result$ = Result$ + Kbd$: Change = -1
ELSE SOUND 860, .1
END IF
PrintAll = 0
CASE ""
 IF PrintAll THEN
  IF LEN(Result$) < RecLen THEN Result$ = Result$ + Kbd$: Change = -1: PrintAll = 0 ELSE SOUND 860, .1
 ELSE
  PrintAll = -1: Change = -1
 END IF
CASE ELSE
 IF PrintAll AND Kbd$ > "" THEN
  IF LEN(Result$) < RecLen THEN Result$ = Result$ + Kbd$: Change = -1: PrintAll = 0 ELSE SOUND 860, .1
 ELSEIF Kbd$ > "" THEN
  IF Kbd$ = CHR$(8) THEN
   IF Result$ > "" THEN Result$ = LEFT$(Result$, LEN(Result$) - 1)
  ELSEIF Kbd$ = CHR$(0) + "S" THEN IF Result$ > "" THEN Result$ = RIGHT$(Result$, LEN(Result$) - 1)
  ELSEIF Kbd$ = CHR$(27) THEN Result$ = "": Keys$ = "": EXIT DO
  ELSE IF Kbd$ > "" THEN Keys$ = Kbd$: Done = -1
  END IF
 Change = -1
 END IF
END SELECT
LOOP UNTIL Done

STRINGPROMPT$ = Result$

END FUNCTION

DEFSNG A-Z
FUNCTION STRNG$ (Leng%, Quote$)
DO UNTIL LEN(Result$) + LEN(Quote$) > Leng%
 Result$ = Result$ + Quote$
LOOP
STRNG$ = Result$ + LEFT$(Quote$, Leng% - LEN(Result$))
END FUNCTION

DEFINT A-Z
SUB TEXTWRAP (Hite, Widt, Lcol, Ulin, Text$)
IF (Widt OR Hite) = 0 THEN EXIT SUB
FOR Vset = 0 TO Hite - 1
LOCATE Ulin + Vset, 1 + Lcol: PRINT MID$(Text$, Vset * Widt + 1, Widt)
NEXT Vset
END SUB

FUNCTION TRUNCATE (Nmbr1, Nmbr2, Mode)
IF Mode THEN
 IF Nmbr1 > Nmbr2 THEN TRUNCATE = Nmbr1 ELSE TRUNCATE = Nmbr2
 'Choose the Greater
ELSE
 IF Nmbr1 < Nmbr2 THEN TRUNCATE = Nmbr1 ELSE TRUNCATE = Nmbr2
 'Choose the Lesser
END IF
END FUNCTION

