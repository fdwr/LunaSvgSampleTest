DEFINT A-Z
DECLARE FUNCTION BIN$ (x)
DECLARE FUNCTION StringPrompt$ (Hlin, Lcol, Length, RecLen, Result$, Kbd$)
DECLARE SUB BoxDraw1 (BoxI$, BoxS$, Titl$, Text$)
SCREEN 0, , 0, 0: COLOR 15, 0: CLS
LOCATE 1, 1, 0: PRINT "Type a filename and then press ENTER to view it or press Esc to exit File Viewer";
LOCATE 25, 1: PRINT "Or type a DOS prompt command followed by END to execute it - DIR, CD, FIND...";
BoxDraw1 "(  ", "ÄÄÄÄÄ Ä ", "File Name Prompt", ""
BoxDraw1 CHR$(0) + "P  ", "þþþþ Û Û", " File Viewer", ""
GOSUB Stats

PromptHandler: GottenName = 0
COLOR 15, 0: User$ = StringPrompt$(4, 22, 38, 128, User$, "")
DO
Keys$ = INKEY$
SELECT CASE Keys$
CASE "", " " TO "ÿ": COLOR 15, 0: User$ = StringPrompt$(4, 22, 38, 128, User$, Keys$): ChngInName = 1
CASE "": AllDone = -1
CASE CHR$(13): File$ = User$: GOSUB Opener
CASE CHR$(0) + "O": File$ = User$: GOSUB Doshell
CASE CHR$(0) + "R": Wide = (Wide + 1) MOD 3: GOSUB Stats
CASE ""
CASE ELSE: SOUND 860, .1
END SELECT
IF ChngInName THEN
 ON ERROR GOTO ExistCheck
 NextFile = FREEFILE: Exists = -1: OPEN User$ FOR INPUT AS NextFile: CLOSE NextFile
 IF Exists THEN SOUND 512, .5: SOUND 1024, .5
 ChngInName = 0
END IF
LOOP UNTIL AllDone
LOCATE , , 0
SYSTEM

ExistCheck:
Exists = 0
RESUME NEXT

Opener:
ON ERROR GOTO FilErrHan
IF LEN(File$) = 0 THEN ERROR 200
OPEN File$ FOR INPUT AS #1: CLOSE
OPEN File$ FOR BINARY ACCESS READ AS #1
LenF& = LOF(1): Part$ = " ": GOSUB Stats
VIEW PRINT 8 TO 22: COLOR 15, 0: CLS 2: LOCATE , , 0
IF Wide = 1 THEN
 left = 0: LOCATE 8
 FOR Rpt& = 1 TO LenF&
  IF INKEY$ = "" THEN EXIT FOR
  GET #1, Rpt&, Part$
  LOCATE , (left * 10) + 1
  PRINT " " + BIN$(ASC(Part$)) + " ";
  IF left = 7 THEN PRINT
  left = (left + 1) MOD 8
 NEXT Rpt&
ELSEIF Wide = 2 THEN
 FOR Rpt& = 1 TO LenF&
  IF INKEY$ = "" THEN EXIT FOR
  GET 1, Rpt&, Part$
  LOCATE , 25: PRINT Rpt&,
  LOCATE , 40: IF Part$ > CHR$(31) THEN PRINT Part$,
  LOCATE , 45: PRINT BIN$(ASC(Part$));
  LOCATE , 55: PRINT ASC(Part$)
 NEXT Rpt&
ELSE
 left = 2
 FOR Rpt& = 1 TO LenF&
  IF INKEY$ = "" THEN EXIT FOR
  GET 1, Rpt&, Part$
  LOCATE , left + 2: IF Part$ > CHR$(31) THEN PRINT Part$;  ELSE PRINT "ù";
  IF left = 77 THEN PRINT
  left = (left + 1) MOD 78
 NEXT Rpt&
END IF
VIEW PRINT
CLOSE
RETURN

Doshell:
PCOPY 0, 1: COLOR 10, 3: CLS
SHELL File$
LOCATE 25, 1: PRINT "Press any Key to go back to FileView";
SLEEP: WHILE INKEY$ > "": WEND
PCOPY 1, 0
RETURN PromptHandler

Stats:
IF Wide = 0 THEN Text$ = "Wide"
IF Wide = 1 THEN Text$ = "Binary"
IF Wide = 2 THEN Text$ = "Skinny"
BoxDraw1 "  ", "ÚÄÀÄÄ³Ä ", "View Mode", Text$
BoxDraw1 "=  ", "Ä¿ÄÙÄ Ä³", "Statistics", "Length:" + STR$(LenF&)
RETURN
FilErrHan:
PCOPY 0, 1
SELECT CASE ERR
CASE 6: Text$ = "      Avalanche, Too Much to load       This file takes up too much memory    to translate."
CASE 53: Text$ = "        Sorry can not find it          You might have spelled the filename   wrong or typed in a file that does    not exist. If you know that it exists make sure the path is right."
CASE 64: Text$ = "      You just said a bad word!       I got a severe reprimand for that filename you gave me. Now you did not justspell it wrong. Be careful with these characters : | / \ < > . ? or *"
CASE 76: Text$ = "        Well, You got me lost          Either this path does not exist, or   you're on the wrong computer. Then    again, maybe you simply can't spell?"
CASE 75: Text$ = "        *#!@ I am confused +=-%        You have your path to a file mixed    up, either that or you are trying to  access an invisible part of the path  itself, such as a directory."
CASE 200: Text$ = "   No filename is in the prompt!"
CASE ELSE: Text$ = STR$(ERR)
END SELECT
BoxDraw1 CHR$(0) + "" + CHR$(INT(LEN(Text$) / 40) + 3) + "(  ", "!!!!    ", "Error Info ÄÄ Error" + STR$(ERR), Text$
CLOSE
WHILE INKEY$ = "": WEND
PCOPY 1, 0
CLOSE
RESUME PromptHandler

FUNCTION BIN$ (x)
Binary$ = "00000000"
IF (x XOR 128) < x THEN MID$(Binary$, 1) = "1"
IF (x XOR 64) < x THEN MID$(Binary$, 2) = "1"
IF (x XOR 32) < x THEN MID$(Binary$, 3) = "1"
IF (x XOR 16) < x THEN MID$(Binary$, 4) = "1"
IF (x XOR 8) < x THEN MID$(Binary$, 5) = "1"
IF (x XOR 4) < x THEN MID$(Binary$, 6) = "1"
IF (x XOR 2) < x THEN MID$(Binary$, 7) = "1"
IF (x XOR 1) < x THEN MID$(Binary$, 8) = "1"
BIN$ = Binary$
END FUNCTION

SUB BoxDraw1 (BoxI$, BoxS$, Titl$, Text$) '"Ú¿ÀÙÄ³Ä³"
COLOR ASC(MID$(BoxI$, 1, 1)), ASC(MID$(BoxI$, 2, 1))
BoxH = ASC(MID$(BoxI$, 3, 1))
BoxL = ASC(MID$(BoxI$, 4, 1))
Ulin = ASC(MID$(BoxI$, 5, 1))
Lcol = ASC(MID$(BoxI$, 6, 1))
Dlin = ASC(MID$(BoxI$, 7, 1))
Rcol = ASC(MID$(BoxI$, 8, 1))
LOCATE Ulin, Lcol: PRINT MID$(BoxS$, 1, 1); STRING$(BoxL - 2, MID$(BoxS$, 5, 1)); MID$(BoxS$, 2, 1)
FOR Rpt = 1 TO BoxH - 2: LOCATE Ulin + Rpt, Lcol: PRINT MID$(BoxS$, 6, 1);
LOCATE Ulin + Rpt, Lcol + BoxL - 1: PRINT MID$(BoxS$, 8, 1); : NEXT Rpt
LOCATE Ulin + Rpt, Lcol: PRINT MID$(BoxS$, 3, 1); STRING$(BoxL - 2, MID$(BoxS$, 7, 1)); MID$(BoxS$, 4, 1)
'Title
LOCATE Ulin, Lcol + INT((BoxL - LEN(MID$(Titl$, 1, BoxL))) / 2)
PRINT MID$(Titl$, 1, BoxL)
'Text
COLOR 15: Hlin = 1
FOR Show = 1 TO LEN(Text$) STEP BoxL - 2
LOCATE Ulin + Hlin, 1 + Lcol: PRINT LEFT$(MID$(Text$, Show) + SPACE$(BoxL), BoxL - 2);
Hlin = Hlin + 1
NEXT Show
PRINT MID$(Text$, Show, BoxL - 2);
END SUB

FUNCTION StringPrompt$ (Hlin, Lcol, Length, RecLen, Result$, Kbd$)

 SELECT CASE Kbd$
  CASE " " TO "ÿ"
   IF LEN(Result$) < RecLen THEN
    Result$ = Result$ + Kbd$
    Change = -1
   ELSE
    SOUND 860, .1
   END IF
  CASE CHR$(8)
   IF LEN(Result$) > 0 THEN Result$ = LEFT$(Result$, LEN(Result$) - 1)
    Change = -1
 END SELECT

 LOCATE , , 0: LOCATE Hlin, Lcol: PRINT RIGHT$(Result$, Length);
 IF LEN(Result$) < Length THEN
  PRINT SPACE$(Length - LEN(Result$));
  LOCATE Hlin, Lcol + LEN(Result$), 1, 5, 6
 ELSE LOCATE Hlin, Lcol + Length, 1, 5, 6
 END IF
 
StringPrompt$ = Result$
END FUNCTION

