DEFINT A-Z
DECLARE FUNCTION FilExists% (file$)
DECLARE SUB STRPROMPT (Rslt$, Leng, RcLn, KeyOut$, KeyIn$, Colr, Bclr, Curp, CurS)
 DECLARE FUNCTION DELETE$ (text$, St, Lg)
 DECLARE SUB HIGHLIGHT (Lcol, Rcol, Hset, Colr)
DECLARE SUB PARAGRAPH (text$, Rslt$, Wdth, Hite, Scrl)
DECLARE SUB PICTDRAW (Hite, Wdth, Urow, Lcol, Pic$)
DECLARE SUB CENTER (Row, Lcol, Rcol, text$)
DECLARE SUB KEYSTOP ()
DECLARE FUNCTION KEYWAIT$ ()
DECLARE SUB Sounds (text$)
DECLARE SUB Menu (text$, CoLin)
DECLARE SUB ShowStatus ()
DECLARE SUB HelpLine (text$)
DECLARE SUB EndItAll ()
DECLARE SUB EstablishModem ()
DECLARE SUB ComOut (text$, Mode)
DECLARE SUB ComInp (text$, Mode)
DECLARE SUB Modem (text$, Mode)
DIM SHARED Speed$, COMport$, Parity$, DATAbits$, STOPbits$, PreSet$, ModemSet, IgnorErrs, file$, PreLoc, Exists, TalkText$(3), Talk$(3), RcrdFile$, RcrdMode
REDIM ComWin(3, 1)
RANDOMIZE TIMER
SCREEN 0: WIDTH 80, 25: COLOR 0, 3: CLS : LOCATE , , 0, 10, 12
ComWinWdth = 36: ComWinHite = 8: ComWin(0, 1) = 3: ComWin(1, 1) = 3: ComWin(2, 1) = 43: ComWin(3, 1) = 43: ComWin(0, 0) = 4: ComWin(1, 0) = 14: ComWin(2, 0) = 4: ComWin(3, 0) = 14
COLOR 15, 1: LOCATE 1, 1: CENTER 1, 1, 80, "ComTalk Ver 1.1"
CurComWin = -1: GOSUB TitleComWins
COLOR 12, 0: FOR Vset = 1 + ComWin(0, 0) TO ComWinHite + ComWin(0, 0): LOCATE Vset, ComWin(0, 1): PRINT SPACE$(ComWinWdth); : NEXT Vset
COLOR , 0: FOR Vset = 1 + ComWin(1, 0) TO ComWinHite + ComWin(1, 0): LOCATE Vset, ComWin(1, 1): PRINT SPACE$(ComWinWdth); : NEXT Vset
COLOR 9, 0: FOR Vset = 1 + ComWin(2, 0) TO ComWinHite + ComWin(2, 0): LOCATE Vset, ComWin(2, 1): PRINT SPACE$(ComWinWdth); : NEXT Vset
COLOR , 0: FOR Vset = 1 + ComWin(3, 0) TO ComWinHite + ComWin(3, 0): LOCATE Vset, ComWin(3, 1): PRINT SPACE$(ComWinWdth); : NEXT Vset
ComWinUpdt = -1: GOSUB UpdtComWins: ShowStatus

IF FilExists("MODEMSET.INI") THEN
 DO
  Menu "Load settings from MODEMSET.INI [_Y/_N]?", 2: ch$ = UCASE$(KEYWAIT$)
  IF ch$ = "Y" OR ch$ = CHR$(13) THEN
   OPEN "MODEMSET.INI" FOR INPUT AS #2
   WHILE NOT EOF(2)
    LINE INPUT #2, ch$: IF INSTR(ch$, "=") THEN Elemnt$ = LEFT$(ch$, INSTR(ch$, "=") - 1): Attrib$ = RIGHT$(ch$, LEN(ch$) - INSTR(ch$, "=")) ELSE Elemnt$ = ch$: Attrib$ = ""
    SELECT CASE UCASE$(Elemnt$)
    CASE "SPEED": Speed$ = Attrib$: Done = Done OR 1
    CASE "PORT": COMport$ = Attrib$: Done = Done OR 2
    CASE "PARITY": Parity$ = Attrib$: Done = Done OR 4
    CASE "DATABITS": DATAbits$ = Attrib$: Done = Done OR 8
    CASE "RECORD": RcrdFile$ = Attrib$: OPEN RcrdFile$ FOR APPEND AS #4
    CASE "DO:": IF SEEK(2) < LOF(2) THEN PreSet$ = INPUT$(LOF(2) - SEEK(2), 2)
    END SELECT
   WEND
   IF Done = 15 THEN EstablishModem ELSE Menu "Load Error: Some of the settings were missing from MODEMSET.INI", 2: KEYSTOP
   IF ModemSet THEN text$ = PreSet$: GOSUB ICDplay
   CLOSE #2: ON ERROR GOTO 0: EXIT DO
  ELSEIF ch$ = "N" OR ch$ = "" THEN EXIT DO
  END IF
 LOOP
END IF
IF NOT ModemSet THEN GOSUB GetSettings

MainMenu:
RfshMenu = 1
DO
 Menu "Do what? _Talk, _Dial, _Hang up, _Send, _Recieve, Set _Options, or _Exit", 2
 IF RfshMenu THEN HelpLine "Press the first letter of the command you want, Esc quits": ShowStatus
 RfshMenu = -1: Choice$ = KEYWAIT$
 SELECT CASE UCASE$(Choice$)
 CASE "T", "P", "D", "H", "S", "R"
  IF NOT ModemSet THEN Menu "You need to first specify modem settings with 'Options'  Press any key..", 2: KEYSTOP: GOTO MainMenu
  SELECT CASE UCASE$(Choice$)
  CASE "T": GOSUB LetsTalk
  CASE "D": GOSUB DialMeUp
  CASE "H": GOSUB HangUp
  CASE "S": GOSUB SendFile
  CASE "R": GOSUB ReceiveFile
  CASE ELSE: RfshMenu = 0
  END SELECT
 CASE "O": GOSUB GetSettings
 CASE "E", "": EXIT DO
 CASE ELSE: RfshMenu = 0
 END SELECT
LOOP
CLOSE #1

IF NOT ModemSet OR NOT ModemChanged THEN EndItAll
DO
Menu "Save settings to MODEMSET.INI [_Y/_N]?", 2: ch$ = UCASE$(KEYWAIT$)
 IF ch$ = "Y" OR ch$ = CHR$(13) THEN
  OPEN "MODEMSET.INI" FOR OUTPUT AS #2
  PRINT #2, "'This file (MODEMSET.INI) is used by the BASIC program COMTALK.BAS to store"
  PRINT #2, "'modem settings so that it can set itself up whenever it starts"
  PRINT #2, "PORT=" + COMport$: PRINT #2, "SPEED=" + Speed$: PRINT #2, "PARITY=" + Parity$: PRINT #2, "DATABITS=" + DATAbits$: PRINT #2, "DO:" + CHR$(13) + PreSet$;
  CLOSE #2: EXIT DO
 ELSEIF ch$ = "N" OR ch$ = "" THEN EXIT DO
 END IF
LOOP
EndItAll

GetSettings:
IF COMport$ = "" THEN COMport$ = "COM2"
HelpLine "Press 1 or 2 to choose which port your modem uses, Esc aborts"
DO
 Menu "Which communication port is your modem using? Com_1 or Com_2 [" + COMport$ + "]", 2: ch$ = KEYWAIT$
 SELECT CASE ch$
 CASE ""
 CASE "": RETURN
 CASE CHR$(13): EXIT DO
 CASE ELSE: IF INSTR("12", ch$) THEN COMport$ = "COM" + ch$: EXIT DO
 END SELECT
LOOP: ShowStatus
IF Speed$ = "" THEN Speed$ = "2400"
ch$ = Speed$: Curp = -1
HelpLine "Use the number keys to type in a speed, F1 displays a valid list, Esc aborts"
DO
 valid$ = " 75 110 150 300 600 1200 2400 4800 9600 "
 Menu "What speed will you use:", 2: STRPROMPT ch$, 6, 5, Kbrd$, "", 112, 127, Curp, 0
 IF Kbrd$ = CHR$(13) THEN IF ch$ = "" THEN EXIT DO ELSE IF INSTR(valid$, " " + ch$ + " ") THEN Speed$ = ch$: EXIT DO ELSE Menu "Valid speeds:" + valid$, 2: KEYSTOP ELSE IF Kbrd$ = CHR$(27) THEN RETURN
 IF Kbrd$ = CHR$(0) + ";" THEN Menu "Valid speeds:" + valid$, 2: KEYSTOP
LOOP: ShowStatus
IF Parity$ = "" THEN Parity$ = "N"
HelpLine "Press the first letter of which parity mode to use (default=None), Esc aborts"
DO
 Menu "Parity type? _None, _Space, _Even, _Mark, or _Odd [" + Parity$ + "]", 2
 valid$ = "NSEMO": ch$ = UCASE$(KEYWAIT$)
 IF ch$ = "" THEN RETURN
 IF ch$ = CHR$(13) THEN EXIT DO
 IF INSTR(valid$, ch$) AND ch$ > "" THEN Parity$ = ch$: EXIT DO
LOOP
IF Parity$ = "N" THEN DATAbits$ = "8" ELSE DATAbits$ = "7"
ShowStatus
ModemChanged = -1: EstablishModem
RETURN

DialMeUp:
IF Phone$ = "" THEN Phone$ = "DT "
Curp = -1: Kbrd$ = "": DO: Menu "Enter the phone number to dial:", 2: STRPROMPT Phone$, 40, 64, Kbrd$, "", 112, 127, Curp, 3: LOOP UNTIL Kbrd$ = CHR$(13) OR Kbrd$ = ""
IF Kbrd$ = "" OR Phone$ = "" THEN RETURN
Menu "Dialing, Waiting for response from modem (or user to press any key)", 2
ComOut Phone$ + CHR$(13), 0: Talk$(0) = Phone$ + CHR$(13): ComWinUpdt = 1: GOSUB UpdtComWins
DO UNTIL INKEY$ > ""
 ComInp Talk$(2), 0: IF Talk$(2) > "" THEN EXIT DO
LOOP
ComWinUpdt = 4: GOSUB UpdtComWins
RETURN

HangUp:
Menu "Hanging up, Waiting for response from modem (or user to press any key)", 2
ComOut "H" + CHR$(13), 0: Talk$(0) = "H" + CHR$(13): ComWinUpdt = 1: GOSUB UpdtComWins
DO UNTIL INKEY$ > ""
 ComInp Talk$(2), 0: IF Talk$(2) > "" THEN EXIT DO
LOOP
ComWinUpdt = 4: GOSUB UpdtComWins
RETURN

SendFile:
HelpLine "Press Control-D to shell to the DOS prompt (type 'EXIT' to get back)"
Menu "Enter the filename to send :", 2: STRPROMPT file$, 47, 128, Keys$, "", 112, 127, -1, 0
IF Keys$ = CHR$(4) THEN
 PCOPY 0, 1: COLOR 7, 0: CLS : SHELL
 PCOPY 1, 0: GOTO SendFile
ELSEIF Keys$ = CHR$(27) OR file$ = "" THEN
 HelpLine ""
 RETURN
ELSEIF Keys$ = CHR$(13) THEN
 ON ERROR GOTO SFileTrap: OPEN file$ FOR INPUT AS #3: CLOSE #3

 Menu "_Wait for start [XON] signal from other user, or _Send anyway?", 2
 IF IgnorErrs THEN ON ERROR GOTO ModemTrap
 DO
 Choice$ = UCASE$(KEYWAIT$)
 LOOP UNTIL Choice$ = "" OR Choice$ = "W" OR Choice$ = "S"
 IF Choice$ = "" THEN GOTO SendFile
 IF Choice$ = "W" THEN
  Menu "Waiting for start signal", 2: COLOR 26: PRINT "..."
  HelpLine "Press ENTER to continue anyway, ESC to cancel"
  DO
   ComInp text$, 1: IF text$ = CHR$(17) THEN EXIT DO
   SELECT CASE INKEY$: CASE "": GOTO SendFile: CASE CHR$(13): EXIT DO: END SELECT
  LOOP
 END IF

 OPEN file$ FOR BINARY AS #3: SEEK #3, 1
 Menu "Sending ", 2: PRINT file$ + "  File Length:" + STR$(LOF(3)); : COLOR 26: PRINT "..."
 FOR s& = 1 TO LOF(3) STEP 128
  text$ = INPUT$(128, 3): ComOut text$, 1
  DEF SEG = 0: IF PEEK(1047) AND 16 THEN Talk$(1) = text$: ComWinUpdt = 2: GOSUB UpdtComWins
  IF INP(96) = 1 OR text$ = "" THEN EXIT FOR
 NEXT s&
 CLOSE #3: ON ERROR GOTO 0
 WHILE INKEY$ > "": WEND
 Sounds "o3l24n40n44n45"
END IF
HelpLine ""
RETURN

SFileTrap:
Menu "That filename is a bad name, try again and press ENTER, or ESC to quit.", 2: KEYSTOP
RESUME SendFile

ReceiveFile:
HelpLine "Press Control-D to shell to the DOS prompt (type 'EXIT' to get back)"
Menu "Enter the filename to recieve :", 2: STRPROMPT file$, 44, 128, Keys$, "", 112, 127, -1, 0
IF Keys$ = CHR$(4) THEN
 PCOPY 0, 1: COLOR 7, 0: CLS : SHELL
 PCOPY 1, 0: GOTO ReceiveFile
ELSEIF Keys$ = CHR$(27) OR file$ = "" THEN
 HelpLine ""
 RETURN
ELSEIF Keys$ = CHR$(13) THEN
 ON ERROR GOTO RFileTrap: OPEN file$ FOR INPUT AS #3: CLOSE #3
 IF FilExists(file$) OR FilExists(file$ + ".REC") THEN SOUND 1024, 1: Menu "The filename you entered already exists, do you want to overwrite it (Y/N)", 2: IF NOT UCASE$(KEYWAIT$) = "Y" THEN GOTO ReceiveFile
 IF INSTR(file$, ".") = 0 THEN file$ = file$ + ".REC"

 Menu "Waiting to receive data, user to continue-ENTER, or user to cancel-ESC", 2: COLOR 26: PRINT "..."
 IF IgnorErrs THEN ON ERROR GOTO ModemTrap
 ComOut CHR$(17), 1
 DO
  ComInp text$, 1: IF text$ > "" THEN EXIT DO
  SELECT CASE INKEY$: CASE "": GOTO ReceiveFile: CASE CHR$(13): EXIT DO: END SELECT
 LOOP

 Menu "Receiving to ", 2: PRINT file$; : COLOR 26: PRINT "..."
 OPEN file$ FOR OUTPUT AS #3
 PRINT #3, text$; : n = INT(TIMER)
 DO
  ComInp text$, 1
  IF text$ > "" THEN
   PRINT #3, text$; : n = INT(TIMER)
   DEF SEG = 0: IF PEEK(1047) AND 16 THEN Talk$(3) = text$: ComWinUpdt = 8: GOSUB UpdtComWins
  ELSE
   IF INT(TIMER) - n > 2 THEN Menu "Break in communication, Press Esc when ready", 2
  END IF
  IF INP(96) = 1 THEN EXIT DO
 LOOP
 WHILE INKEY$ > "": WEND
 Sounds "o3l24n40n44n45"
 CLOSE #3: ON ERROR GOTO 0
END IF
HelpLine ""
RETURN

RFileTrap:
IF ERR <> 53 THEN Menu "That filename is a bad name, try again and press ENTER, or ESC to quit.", 2: KEYSTOP ELSE RESUME NEXT
RESUME ReceiveFile

LetsTalk:
Menu " F10 = Main Menu, F2 = Switch window, F3 = Clear window, F4 = Toggle record", 2
HelpLine "Whatever you type into the box will be sent to the modem, F10 quits this mode"
CurComWin = TalkMode: GOSUB TitleComWins: ShowStatus: ComWinUpdt = -1
DO
 ComInp Talk$(2), 0: IF LEN(Talk$(2)) > 0 THEN ComWinUpdt = ComWinUpdt OR 4
 ComInp Talk$(3), 1: IF LEN(Talk$(3)) > 0 THEN ComWinUpdt = ComWinUpdt OR 8
 Talk$(0) = "": Kbrd$ = INKEY$
 IF LEN(Kbrd$) = 1 THEN
  ComWinUpdt = ComWinUpdt OR (TalkMode + 1): IF TalkMode THEN Talk$(1) = Kbrd$: ComOut Kbrd$, 1 ELSE Talk$(0) = Kbrd$: ComOut Kbrd$, 0
 ELSEIF Kbrd$ > "" THEN
  SELECT CASE Kbrd$
  CASE CHR$(0) + "?": text$ = "~0DT ~F": GOSUB ICDplay
  CASE CHR$(0) + "@": text$ = "~0A~R": GOSUB ICDplay
  CASE CHR$(0) + "A": text$ = "~1Hello ~G": GOSUB ICDplay
  CASE CHR$(0) + "D": EXIT DO
  CASE CHR$(0) + "<": TalkMode = (TalkMode AND 1) XOR 1: CurComWin = TalkMode: GOSUB TitleComWins
  END SELECT
 END IF
 IF ComWinUpdt THEN GOSUB UpdtComWins
LOOP
CurComWin = -1: GOSUB TitleComWins
RETURN

UpdtComWins:
 FOR ComWindow = 0 TO 3
  IF ComWinUpdt AND 2 ^ ComWindow THEN
   PreWinRow = LEN(TalkText$(ComWindow)) \ ComWinWdth
   PARAGRAPH TalkText$(ComWindow), Talk$(ComWindow), ComWinWdth, ComWinHite, Scrl: Talk$(ComWindow) = ""
   Leng = LEN(TalkText$(ComWindow)): CurWinRow = Leng \ ComWinWdth: CurWinCol = Leng MOD ComWinWdth
   IF Scrl THEN
    PICTDRAW ComWinHite, ComWinWdth, ComWin(ComWindow, 0), ComWin(ComWindow, 1) - 1, TalkText$(ComWindow) + SPACE$(ComWinHite * ComWinWdth - Leng)
   ELSE
    PICTDRAW ComWinHite, ComWinWdth, PreWinRow + ComWin(ComWindow, 0), ComWin(ComWindow, 1) - 1, RIGHT$(TalkText$(ComWindow), ComWinWdth * (CurWinRow - PreWinRow) + CurWinCol) + SPACE$(ComWinWdth - CurWinCol)
   END IF
   IF ComWindow AND 2 THEN COLOR 9, 0 ELSE COLOR 12, 0
   LOCATE CurWinRow + ComWin(ComWindow, 0) + 1, CurWinCol + ComWin(ComWindow, 1): PRINT "Ý";
  END IF
 NEXT ComWindow
 ComWinUpdt = 0
RETURN
TitleComWins:
 IF CurComWin = 0 THEN COLOR 15, 7 ELSE COLOR 12, 7
 CENTER ComWin(0, 0), ComWin(0, 1), ComWin(0, 1) + ComWinWdth - 1, "Control Output"
 IF CurComWin = 1 THEN COLOR 15 ELSE COLOR 12
 CENTER ComWin(1, 0), ComWin(1, 1), ComWin(1, 1) + ComWinWdth - 1, "Data Output"
 COLOR 9, 7: CENTER ComWin(2, 0), ComWin(2, 1), ComWin(2, 1) + ComWinWdth - 1, "Control Input"
 COLOR , 7: CENTER ComWin(3, 0), ComWin(3, 1), ComWin(3, 1) + ComWinWdth - 1, "Data Input"
RETURN

ICDplay:
ComWinICD = CurComWin AND 1
ICDWinUpt = 2 ^ TalkMode
FOR Make = 1 TO LEN(text$)
 SELECT CASE MID$(text$, Make, 1)
 CASE "~"
  SELECT CASE MID$(text$, Make + 1, 1)
  CASE "0" TO "3": ComWinICD = VAL(MID$(text$, Make + 1, 1)): ICDWinUpt = 2 ^ ComWinICD
  CASE "E": CurComICD = CurComWin AND 1
  CASE "F", "G": CurComWin = ASC(MID$(text$, Make + 1, 1)) - 70: TalkMode = CurComWin: GOSUB TitleComWins
  CASE "L": Talk$(ComWinICD) = CHR$(10): CASE "R": Talk$(ComWinICD) = CHR$(13)
  CASE "T": Talk$(ComWinICD) = "~"
  END SELECT
  Make = Make + 1
 CASE ELSE: Talk$(ComWinICD) = MID$(text$, Make, 1)
 END SELECT
 ComOut Talk$(ComWinICD), ComWinICD: ComWinUpdt = ICDWinUpt
 ComInp Talk$(2), 0: IF LEN(Talk$(2)) > 0 THEN ComWinUpdt = ComWinUpdt OR 4
 ComInp Talk$(3), 1: IF LEN(Talk$(3)) > 0 THEN ComWinUpdt = ComWinUpdt OR 8
 GOSUB UpdtComWins
NEXT Make
RETURN

ModemTrap:
RESUME NEXT

FileExistsTrap:
IF ERR THEN Exists = 0'No
RESUME NEXT

SUB CENTER (Row, Lcol, Rcol, text$)
IF Lcol > Rcol THEN EXIT SUB ELSE Leng = Rcol - Lcol + 1
IF LEN(text$) > Leng THEN Part$ = LEFT$(text$, Leng) ELSE Part$ = SPACE$(Leng): MID$(Part$, (Leng - LEN(text$)) \ 2 + 1, Leng) = text$
LOCATE Row, Lcol: PRINT Part$;
END SUB

SUB ComInp (text$, Mode%)
'ComBuffer$ = INPUT$(LOC(1), 1)
: Modem text$, (Mode AND 1) + 2
END SUB

SUB ComOut (text$, Mode)
: Modem text$, Mode AND 1
END SUB

FUNCTION DELETE$ (text$, St, Lg)
IF SGN(Lg) = -1 THEN Lt = St + Lg: Rt = LEN(text$) - St ELSE Lt = St: Rt = LEN(text$) - (St + Lg)
IF Lt > LEN(text$) THEN Lt = LEN(text$) ELSE IF Lt < 0 THEN Lt = 0
IF Rt > LEN(text$) THEN Rt = LEN(text$) ELSE IF Rt < 0 THEN Rt = 0
DELETE$ = LEFT$(text$, Lt) + RIGHT$(text$, Rt)
END FUNCTION

DEFSNG A-Z
SUB EndItAll
IF RcrdFile$ > "" THEN CLOSE #4
COLOR 7, 0: CLS : SYSTEM
END SUB

DEFSTR A-Z
SUB EstablishModem
: ModemSet% = -1
: EXIT SUB
Menu "Establishing " + COMport + " Connection..", 2
comfil = COMport + ":" + Speed + "," + Parity + "," + DATAbits$
IF LEFT$(comfil, 3) <> "COM" THEN comfil = COMport
IF FREEFILE > 1 THEN CLOSE 1
OPEN comfil FOR RANDOM AS #1
Sounds "o3l24n40n40n45"
ModemSet% = -1
END SUB

DEFINT A-Z
FUNCTION FilExists% (file$)
ON ERROR GOTO FileExistsTrap: Exists = -1'Yes
OPEN file$ FOR INPUT AS #3: CLOSE #3
ON ERROR GOTO 0: FilExists% = Exists
END FUNCTION

SUB HelpLine (text$)
COLOR 15, 3: CENTER 25, 1, 80, text$
END SUB

SUB HIGHLIGHT (Lcol, Rcol, Hset, Colr)
DEF SEG = &HB800: Oset = (Hset - 1) * 80
FOR Show = Lcol - 1 TO Rcol - 1 STEP SGN(Rcol - Lcol) OR 1
 POKE (Oset + Show) * 2 + 1, Colr
NEXT Show
END SUB

DEFSNG A-Z
SUB KEYSTOP
WHILE INKEY$ > "": WEND
WHILE INKEY$ = "": WEND
END SUB

FUNCTION KEYWAIT$
K$ = "": WHILE K$ = "": K$ = INKEY$: WEND: KEYWAIT$ = K$
END FUNCTION

DEFINT A-Z
SUB Menu (text$, CoLin)
LOCATE CoLin, 1, 0: COLOR , 7
DO UNTIL Show >= LEN(text$)
 Show = Show + 1: IF MID$(text$, Show, 1) = "_" THEN COLOR 15: Show = Show + 1 ELSE COLOR 10
 Leng = Leng + 1: PRINT MID$(text$, Show, 1);
LOOP
PreV = CSRLIN: PreH = POS(0): IF 80 - Leng > 0 THEN PRINT SPACE$(80 - Leng); : LOCATE PreV, PreH
END SUB

SUB Modem (text$, Mode) STATIC
IF Mode = 0 THEN
 FOR Make = 1 TO LEN(text$)
  SELECT CASE MID$(text$, Make, 1)
  CASE CHR$(13): NextCmnd = 1
  CASE CHR$(27): ModmCmnd$ = ""
  CASE CHR$(10)
  CASE " ": IF LEN(ModmCmnd$) > 0 AND LEN(ModmCmnd$) < 63 THEN ModmCmnd$ = ModmCmnd$ + " "
  CASE ELSE: IF LEN(ModmCmnd$) < 63 THEN ModmCmnd$ = ModmCmnd$ + MID$(text$, Make, 1)
  END SELECT
 NEXT Make
ELSEIF Mode = 2 THEN
 text$ = ""
 IF NextCmnd THEN
  ModmCmnd$ = UCASE$(ModmCmnd$)
  SELECT CASE LEFT$(ModmCmnd$, 1)
  CASE "A": IF ModmRing THEN text$ = "HOST CONNECT": ModmCnct = 1: ModmRing = 0 ELSE text$ = "NO RING"
  CASE "D": text$ = MID$("BUSY   CONNECTNO TONE", INT(RND * 3) * 7 + 1, 7): Sounds "O3L16CEGDF"
   IF text$ = "CONNECT" THEN text$ = "USER CONNECT": ModmCnct = 1: ModmRing = 0
  CASE "H": IF ModmCnct THEN text$ = "USER HANGUP": ModmCnct = 0 ELSE text$ = "NO CONNECT"
  CASE "B": IF RTRIM$(ModmCmnd$) > "B" THEN text$ = "BAUD SET" ELSE text$ = "NO BAUD"
  CASE "T": text$ = "TEST": Sounds "O1L50CEG>CEG>CEG>C"
  CASE ""
  CASE ELSE: text$ = "ERROR"
  END SELECT
  IF text$ > "" THEN text$ = text$ + CHR$(13)
  NextCmnd = 0
  ModmCmnd$ = ""
 ELSEIF ModmCnct = 0 THEN
  IF ModmRing THEN
   IF INT(TIMER) - ModmCont& > 2 THEN ModmCont& = INT(TIMER): text$ = "RING" + CHR$(13): Sounds "O3L48CGCGCGCG": IF INT(RND * 3) = 1 THEN ModmRing = 0
  ELSE IF INT(RND * 5000) = 1 THEN ModmRing = 1
  END IF
 ELSEIF ModmCnct THEN
  IF INT(RND * 10000) = 1 THEN ModmRing = 0: ModmCnct = 0: text$ = "HOST HANGUP" + CHR$(13): Sounds "O0L64Cp32c"
 ELSE
 END IF
ELSEIF Mode = 3 THEN
 IF ModmCnct AND INT(RND * 80) = 1 THEN text$ = CHR$(INT(RND * 256)) ELSE text$ = ""
END IF
END SUB

SUB PARAGRAPH (text$, Rslt$, Wdth, Hite, Scrl)
 Scrl = 0: IF Wdth < 1 THEN EXIT SUB
 FOR Make = 1 TO LEN(Rslt$)
  SELECT CASE MID$(Rslt$, Make, 1)
  CASE CHR$(13): text$ = text$ + SPACE$(Wdth - LEN(text$) MOD Wdth)
  CASE CHR$(10)
  CASE CHR$(9): text$ = text$ + SPACE$(8 - (LEN(text$) MOD Wdth MOD 8))
  CASE ELSE: text$ = text$ + MID$(Rslt$, Make, 1)
  END SELECT
 NEXT Make
 IF Hite THEN WHILE LEN(text$) >= Wdth * Hite: text$ = RIGHT$(text$, LEN(text$) - Wdth): Scrl = Scrl + 1: WEND
END SUB

SUB PICTDRAW (Hite, Wdth, Urow, Lcol, Pic$)
IF Wdth = 0 OR Hite = 0 THEN EXIT SUB ELSE IF Hite > INT((LEN(Pic$) / Wdth)) THEN Vhit = INT((LEN(Pic$) / Wdth)) - 1 ELSE Vhit = Hite - 1
DEF SEG = &HB800: Vcol = Lcol * 2: Rcol = (Lcol + Wdth - 1) * 2
FOR Vset = Urow * 160 TO (Urow + Vhit) * 160 STEP 160
 FOR Hset = Vcol TO Rcol STEP 2
  Move = Move + 1
  POKE Vset + Hset, ASC(MID$(Pic$, Move, 1))
NEXT Hset, Vset
END SUB

DEFSNG A-Z
SUB ShowStatus
IF RcrdMode% THEN Rcrd$ = "On " ELSE Rcrd$ = "Off"
Part$ = "Ý      ³ Speed:     ³ Parity:  ³ Data:  ³ Record:    Þ"
MID$(Part$, 3, 4) = COMport$
MID$(Part$, 16, 4) = Speed$
MID$(Part$, 30, 1) = Parity$
MID$(Part$, 39, 1) = DATAbits$
MID$(Part$, 50, 3) = Rcrd$
COLOR 3, 0: LOCATE 24, 1: PRINT Part$;
END SUB

SUB Sounds (text$)
DEF SEG = 0: SndOnf% = (PEEK(1047) AND 32)
IF SndOnf% AND PLAY(0) = 0 THEN PLAY "MB" + text$
END SUB

DEFINT A-Z
SUB STRPROMPT (Rslt$, Leng, RcLn, Keys$, KeyIn$, Colr, Bclr, Curp, CurS)
IF Curp = -1 THEN Curp = LEN(Rslt$)
Vlin = CSRLIN: Lcol = POS(0): Shft = -1: GOSUB StrPromptShow

DO
DEF SEG = 0: Shft = PEEK(1047) AND 3
IF Nsrt THEN LOCATE , , , 3, 6 ELSE LOCATE , , , 5, 6
Chng = -1: IF KeyIn$ > "" THEN Kbrd$ = KeyIn$: Done = -1 ELSE Kbrd$ = INKEY$
SELECT CASE Kbrd$
CASE "": Chng = 0
CASE " " TO "ÿ": GOSUB StrPromptInsert
CASE CHR$(0) + "K": IF Curp > 0 THEN Curp = Curp - 1
CASE CHR$(0) + "M": IF Curp < LEN(Rslt$) THEN Curp = Curp + 1
CASE CHR$(0) + "G": Curp = 0
CASE CHR$(0) + "O": Curp = LEN(Rslt$)
CASE CHR$(0) + "S": IF Curp - CurS THEN Rslt$ = DELETE(Rslt$, CurS, Curp - CurS): IF CurS < Curp THEN Curp = CurS ELSE  ELSE Rslt$ = DELETE$(Rslt$, Curp, 1)
CASE CHR$(0) + "R"
CASE CHR$(0) + "s": Lttr = 0
 FOR Srch = Curp TO 1 STEP -1
  IF INSTR(" ÿ()/\.	", MID$(Rslt$, Srch, 1)) = 0 THEN Lttr = -1 ELSE IF Lttr THEN Curp = Srch: EXIT FOR
 NEXT Srch: IF Srch = 0 THEN Curp = 0
CASE CHR$(0) + "t": Lttr = 0
 FOR Srch = Curp + 1 TO LEN(Rslt$)
  IF INSTR(" ÿ()/\.	", MID$(Rslt$, Srch, 1)) THEN Lttr = -1 ELSE IF Lttr THEN Curp = Srch - 1: EXIT FOR
 NEXT Srch: IF Srch = LEN(Rslt$) + 1 THEN Curp = LEN(Rslt$)
CASE ELSE
 IF Nsrt AND LEN(Kbrd$) < 2 THEN
  GOSUB StrPromptInsert
 ELSE
  SELECT CASE Kbrd$
  CASE CHR$(8): Rslt$ = DELETE$(Rslt$, Curp, -1): Curp = Curp - 1
  CASE ELSE: Chng = 0: Done = -1: Keys$ = Kbrd$
  END SELECT
 END IF
END SELECT
IF Chng THEN GOSUB StrPromptShow: Chng = 0
LOOP UNTIL Done
EXIT SUB

StrPromptShow:
 IF Curp < 0 THEN Curp = 0 ELSE IF Curp > LEN(Rslt$) THEN Curp = LEN(Rslt$)
 IF Curp < RsCr THEN RsCr = Curp ELSE IF Curp > RsCr + Leng THEN RsCr = Curp - Leng
 IF Shft = 0 THEN CurS = Curp
 IF Leng - (LEN(Rslt$) - RsCr) >= 0 THEN Tail$ = SPACE$(Leng - (LEN(Rslt$) - RsCr)) ELSE Tail$ = ""
 PICTDRAW 1, Leng, Vlin - 1, Lcol - 1, MID$(Rslt$, RsCr + 1, Leng) + Tail$
 IF Curp < CurS THEN CurL = Curp - RsCr: CurR = CurS - RsCr ELSE CurL = CurS - RsCr: CurR = Curp - RsCr
 IF CurL < 0 THEN CurL = 0
 IF CurR > Leng THEN CurR = Leng
 CurL = CurL + Lcol: CurR = CurR + Lcol
 IF CurL > Lcol THEN HIGHLIGHT Lcol, CurL - 1, Vlin, Colr
 IF Curp - CurS THEN HIGHLIGHT CurL, CurR - 1, Vlin, Bclr
 IF CurR < Leng + Lcol THEN HIGHLIGHT CurR, Leng + Lcol - 1, Vlin, Colr
 IF Curp >= RsCr AND Curp < RsCr + Leng THEN LOCATE Vlin, Lcol + (Curp - RsCr), 1 ELSE LOCATE Vlin, , 0
RETURN
StrPromptInsert:
 Rslt$ = DELETE(Rslt$, CurS, Curp - CurS): IF CurS < Curp THEN Curp = CurS
 IF LEN(Rslt$) + LEN(Kbrd$) > RcLn THEN SOUND 860, .1: RETURN
 IF Curp >= 0 AND Curp <= LEN(Rslt$) THEN Rslt$ = LEFT$(Rslt$, Curp) + Kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - Curp): Shft = 0
 Curp = Curp + LEN(Kbrd$)
RETURN
END SUB

