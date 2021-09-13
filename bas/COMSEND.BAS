DEFINT A-Z
DECLARE FUNCTION LM$ (Row, Col)
DECLARE FUNCTION LF$ (Mode)
DECLARE SUB PROMPT (Frst$, Last$, KeyIn$, KeyOut$, Lim, Vis, Row, Col, Curp, Done)
DECLARE SUB ERRBEEP ()
DECLARE SUB Message (Mode, Text$)
DECLARE SUB InpOut (Mode, Text$)
DECLARE SUB ShowInfo ()

IntroStart:
WIDTH 80, 25: COLOR 7, 0: CLS : LOCATE 1, 1, 0
DIM SHARED Modem, InFile, OutFile, ComPort$, ComSpeed, ComParity, ComBits, ModemSet

PRINT "Communication Port Send Utility (COMSEND.BAS) Ver 1.2, 3-1996"
PRINT "Amateur BASIC Program by Dwayne Demmer. No copyright reserved"; LF(1)
PRINT "(þ   ) "'xé

END

'Division of screen lines
'1 COMSEND.BAS Name, Ver, and Date
'2 Credits, absence of copyright
'3 Separation line ÄÄÄÄÄÄÄÄÄÄ
'4 Messages
'5 Responses
'6 Keys  þ þ   
'7 Menus
'8 ...
'9 ...
'10 ..
'11 ..
'12 ..
'13 ..
'14 Separation line ÄÄÄÄÄÄÄÄÄ
'15 Format: Modem speed, Parity, COM port, Data bits, Stop bits
'16 Status: Act (þ,,,,) State 

'Set Options
'Change Settings
'Open play file
'Open record file
'Exit

MenuInform:
RETURN
ReactOnKey:
RETURN
StatusInfo:
RETURN
ChangeSettings:
Message 1, "Use the  and  keys to jump between sections and change each setting"
RETURN

DEFSNG A-Z
SUB ERRBEEP
SOUND 860, .1': SOUND 700, .2
END SUB

DEFINT A-Z
SUB InpOut (Mode, Text$)

IF ModemSet = 0 THEN EXIT SUB
SELECT CASE Mode
CASE 0: Text$ = INPUT$(LOC(Modem), Modem)
CASE 1: PRINT #Modem, Text$;
CASE 2: PRINT #Modem, Text$; : Text$ = INPUT$(LOC(Modem), Modem)
END SELECT

END SUB

DEFSNG A-Z
FUNCTION LF$ (Mode%)
IF Mode% AND 1 THEN Rslt$ = Rslt$ + CHR$(13)
IF Mode% AND 2 THEN Rslt$ = Rslt$ + CHR$(10)
LF$ = Rslt$
END FUNCTION

FUNCTION LM$ (Row%, Col%)
LOCATE Row%, Col%
END FUNCTION

DEFINT A-Z
SUB Menu (Choice$(), Frst, Last, Lim, Vis, Row, Col, KeyIn$, KeyOut$, Done)
REDIM ChoicePos(0 TO Last - 1, 0 TO 1)
'IF Row = 0 or Col
'IF Col = 0 THEN Col = POS(0)
Curp = Frst
Chng = 1
Kbrd$ = KeyIn$

MenuChoice:
COLOR 7, 0: LOCATE ChoicePos(Curp, 0) + Row, ChoicePos(Curp, 1) + Col
PRINT LEFT$(Choice$(Curp) + SPACE$(MaxLen), MaxLen);

MenuHighlight:
COLOR 0, 7: LOCATE ChoicePos(Curp, 0) + Row, ChoicePos(Curp, 1) + Col
PRINT LEFT$(Choice$(Curp) + SPACE$(MaxLen), MaxLen);

END SUB

DEFSNG A-Z
SUB Message (Mode%, Text$)
IF Mode% THEN LOCATE 13, 1 ELSE LOCATE 4, 1
PRINT RIGHT$(Text$, 80);
IF LEN(Text$) < 80 THEN PRINT SPACE$(80 - LEN(Text$));
END SUB

DEFINT A-Z
SUB PROMPT (Frst$, Last$, KeyIn$, KeyOut$, Lim, Vis, Row, Col, Curp, Done)
IF Row = 0 THEN Row = CSRLIN
IF Col = 0 THEN Col = POS(0)
Rslt$ = Frst$
Chng = 1
Kbrd$ = KeyIn$

DO
 Leng = LEN(Rslt$)
 SELECT CASE Kbrd$
 CASE ""
 CASE " " TO "ÿ": GOSUB PromptInsert: Chng = 1
 CASE CHR$(0) + "S": IF Curp < Leng AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp) + RIGHT$(Rslt$, Leng - Curp - 1): Chng = 1
 CASE CHR$(8): IF Curp > 0 AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp - 1) + RIGHT$(Rslt$, Leng - Curp): Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "K": IF Curp > 0 THEN Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "M": IF Curp < Leng THEN Curp = Curp + 1: Chng = 1
 CASE CHR$(0) + "G": Curp = 0: Chng = 1
 CASE CHR$(0) + "O": Curp = Leng: Chng = 1
 CASE ELSE: KeyOut$ = Kbrd$: Done = 1
 END SELECT

 IF Chng THEN
  Leng = LEN(Rslt$)
  IF Curp > Leng THEN Curp = Leng ELSE IF Curp < 0 THEN Curp = 0
  IF Curp < Ofst THEN Ofst = Curp ELSE IF Curp >= Ofst + Vis THEN Ofst = Curp - Vis + 1
  LOCATE , , 0: LOCATE Row, Col: PRINT MID$(Rslt$ + SPACE$(Vis), Ofst + 1, Vis);
  LOCATE , , 1: LOCATE Row, Col + (Curp - Ofst)
  Chng = 0
 END IF

 Kbrd$ = INKEY$
LOOP UNTIL Done

Last$ = Rslt$
EXIT SUB

PromptInsert:
 IF LEN(Kbrd$) + LEN(Rslt$) > Lim THEN ERRBEEP: RETURN
 Rslt$ = LEFT$(Rslt$, Curp) + Kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - Curp)
 Curp = Curp + 1
RETURN
END SUB

DEFSNG A-Z
SUB ShowInfo
LOCATE 15, 1: PRINT "Format:"
END SUB

