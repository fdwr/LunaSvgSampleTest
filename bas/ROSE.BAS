DEFINT A-Z
DECLARE SUB NUMPROMPT (Rslt$, KeyIn$, Lim, Vis, Row, Col, Curp)

CONST Pi! = 3.14159
RoseLoop! = 6
RoseThik! = .1
RoseSizT! = 9
RoseColr = 12

GetInfo:
SCREEN 0: COLOR 7, 0: CLS : WIDTH 80, 25
PRINT "This algorithm draws a rose pattern on the screen"
PRINT "Simply assign the value for each rose attribute"
PRINT "Use the arrow keys to choose between attributes"
PRINT "Then press Enter to draw it, or press Esc to quit"
FOR Choice = 0 TO 3
 GOSUB GetResult
 GOSUB ShowEntry
NEXT Choice
NewPrompt = 1
NewChoice = 0
DO
 IF NewPrompt THEN
  Choice = NewChoice
  COLOR 15: GOSUB GetResult: GOSUB ShowEntry
  Curp = -1: Col = LEN(Text$) + Col + 1: RfshPrompt = 1: NewPrompt = 0
 END IF
 kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE ""
 CASE CHR$(27): UserDone = 1
 CASE CHR$(13): ReDrawRose = 1
 CASE CHR$(0) + "H": NewChoice = (Choice + 3) MOD 4: NewPrompt = 1
 CASE CHR$(0) + "P": NewChoice = (Choice + 1) MOD 4: NewPrompt = 1
 CASE ELSE: RfshPrompt = 1
 END SELECT
 IF RfshPrompt THEN NUMPROMPT Rslt$, kbrd$, Lim, Lim + 1, Row, Col, Curp: RfshPrompt = 0
 IF NewPrompt OR ReDrawRose THEN
  SELECT CASE Choice: CASE 0: RoseLoop! = VAL(Rslt$): CASE 1: RoseSizT! = VAL(Rslt$): CASE 2: RoseThik! = VAL(Rslt$): CASE 3: RoseColr = VAL(Rslt$): END SELECT
  IF RoseThik! = 0! THEN RoseThik! = .1
  RoseColr = RoseColr AND 15: IF RoseColr = 0 THEN RoseColr = 12
  RoseSize! = RoseSizT! * 9
  COLOR 7: GOSUB GetResult: GOSUB ShowEntry
 END IF
 IF ReDrawRose THEN GOSUB DrawRose: LOCATE 25, 1: PRINT "Press any key to return to options"; : WHILE INKEY$ > "": WEND: WHILE INKEY$ = "": WEND: ReDrawRose = 0: GOTO GetInfo
LOOP UNTIL UserDone
END
GetResult: SELECT CASE Choice: CASE 0: Rslt$ = LTRIM$(STR$(RoseLoop!)): CASE 1: Rslt$ = LTRIM$(STR$(RoseSizT!)): CASE 2: Rslt$ = LTRIM$(STR$(RoseThik!)): CASE 3: Rslt$ = LTRIM$(STR$(RoseColr)): END SELECT: RETURN
ShowEntry: GOSUB GetPrompt: LOCATE Row, Col: PRINT Text$; " "; LEFT$(Rslt$ + SPACE$(Lim), Lim); : RETURN

GetPrompt:
Lim = 5: Col = 1
SELECT CASE Choice
CASE 0: Row = 6: Text$ = "(0-?) Number of loops -"
CASE 1: Row = 7: Lim = 2: Text$ = "(0-30) Size of petals -"
CASE 2: Row = 8: Text$ = "(.1-9) Rose thickness -"
CASE 3: Row = 10: Lim = 2: Text$ = "(1-15) Color of rose --"
END SELECT
RETURN

DrawRose:
SCREEN 7
ScreenHite = 200: ScreenWidth = 320
FOR RoseAngle! = 0 TO 360 STEP RoseThik!
 RoseRadian! = Pi! * CSNG(RoseAngle!) / 180
 RoseCord! = RoseSize! * SIN(RoseLoop! * RoseRadian!)
 RoseX = (ScreenWidth \ 2) + INT(RoseCord! * COS(RoseRadian!))
 RoseY = (ScreenHeight \ 2) - INT(RoseCord! * SIN(RoseRadian!))
 PSET (RoseX, RoseY + 100), RoseColr
NEXT RoseAngle!
RETURN

SUB NUMPROMPT (Rslt$, KeyIn$, Lim, Vis, Row, Col, Curp)
IF Curp = -1 THEN Curp = LEN(Rslt$)

'Decipher Key Input
 Leng = LEN(Rslt$)
 SELECT CASE KeyIn$
 CASE ""
 CASE "0" TO "9": GOSUB PromptInsert
 CASE ".": IF INSTR(Rslt$, ".") = 0 THEN GOSUB PromptInsert
 CASE CHR$(8): IF Curp > 0 AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp - 1) + RIGHT$(Rslt$, Leng - Curp): Curp = Curp - 1
 CASE CHR$(0) + "S": IF Curp < Leng AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp) + RIGHT$(Rslt$, Leng - Curp - 1)
 CASE CHR$(0) + "K": IF Curp > 0 THEN Curp = Curp - 1
 CASE CHR$(0) + "M": IF Curp < Leng THEN Curp = Curp + 1
 CASE CHR$(0) + "G": Curp = 0
 CASE CHR$(0) + "O": Curp = Leng
 END SELECT

 Leng = LEN(Rslt$)
 IF Curp > Leng THEN Curp = Leng ELSE IF Curp < 0 THEN Curp = 0
 IF Curp < Ofst THEN Ofst = Curp ELSE IF Curp >= Ofst + Vis THEN Ofst = Curp - Vis + 1
 LOCATE , , 0
 LOCATE Row, Col: PRINT MID$(Rslt$ + SPACE$(Vis), Ofst + 1, Vis);
 LOCATE Row, Col + (Curp - Ofst)
 LOCATE , , 1, 14, 15

'End SubProgram
EXIT SUB

PromptInsert:
 IF Rslt$ = "0" THEN Rslt$ = LEFT$(KeyIn$, Lim): RETURN
 IF LEN(KeyIn$) + LEN(Rslt$) > Lim THEN SOUND 1024, .1: RETURN
 Rslt$ = LEFT$(Rslt$, Curp) + KeyIn$ + RIGHT$(Rslt$, LEN(Rslt$) - Curp)
 Curp = Curp + LEN(KeyIn$)
RETURN
END SUB

