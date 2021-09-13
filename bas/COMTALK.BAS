DEFINT A-Z
DECLARE FUNCTION KEYWAIT$ ()
DECLARE FUNCTION DELETE$ (Text$, St, Lg)
DECLARE FUNCTION STRPROMPT$ (Leng, RcLn, Prst$, KeyOut$, KeyIn$, Colr, Bclr, CurP, CurS)
DECLARE FUNCTION ComBuffer$ ()
DECLARE FUNCTION FilExists% (file$)
DECLARE FUNCTION Sounds% ()
DECLARE SUB PARAGRAPH (Text$, Rslt$, Wdth, Hite, Scrl)
DECLARE SUB PICTDRAW (Hite, Wdth, Urow, Lcol, Pic$)
DECLARE SUB HIGHLIGHT (Lcol%, Rcol%, Hset%, Colr%)
DECLARE SUB MENU (Text$, CoLin)
DECLARE SUB KEYSTOP ()
DECLARE SUB ShowStatus (State)
DECLARE SUB EstablishModem ()
DECLARE SUB EndItAll ()
DIM SHARED Speed$, COMport$, Parity$, DATAbits$, STOPbits$, PreSet$, ModemSet, State, IgnorErrs, file$, PreLoc, Exists, TalkText$(1), Talk$(1), RcrdFile$, RcrdMode%
DEF SEG = 0: IF PEEK(1047) AND 128 THEN POKE (1047), PEEK(1047) AND 127
SCREEN 0: WIDTH 80, 25: COLOR 0, 3: CLS : LOCATE , , 0, 10, 12: Wdth = 32: Hite = 16
COLOR 12, 7: LOCATE 3, 6: PRINT "          Modem Output          ": COLOR , 0: FOR Vset = 1 TO Hite: LOCATE 3 + Vset, 6: PRINT SPACE$(32); : NEXT Vset
COLOR 9, 7: LOCATE 3, 44: PRINT "          Modem Input           ": COLOR , 0: FOR Vset = 1 TO Hite: LOCATE 3 + Vset, 44: PRINT SPACE$(32); : NEXT Vset
COLOR 14, 0: LOCATE 22, 6: PRINT SPACE$(70)
IF Sounds THEN PLAY "mbl24n40n44n45"

IF FilExists("MODEMSET.INI") THEN
 DO
  MENU "Load settings from MODEMSET.INI [_Y/_N]?", 1: ch$ = UCASE$(KEYWAIT$)
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
    CASE "DO:": PreSet$ = INPUT$(LOF(2) - SEEK(2), 2)
    END SELECT
   WEND
   IF Done = 15 THEN EstablishModem ELSE MENU "Load Error: Some of the settings were missing from MODEMSET.INI", 1: KEYSTOP
   IF ModemSet THEN PRINT #1, PreSet$; : UpdateWindow = 1: Talk$(0) = PreSet$: GOSUB UpdateWindows
   CLOSE #2: ON ERROR GOTO 0: EXIT DO
  ELSEIF ch$ = "N" OR ch$ = "" THEN EXIT DO
  END IF
 LOOP
END IF
IF NOT ModemSet THEN GOSUB GetSettings

MainMenu:
DO
 MENU "Do what? _Talk, _Dial, _Hang up, _Send, _Recieve, Set _Options, or _Exit", 1
 IF ModemSet THEN ShowStatus 0
 Choice$ = KEYWAIT$
 SELECT CASE UCASE$(Choice$)
 CASE "T", "P", "D", "H", "S", "R"
  IF NOT ModemSet THEN MENU "You need to first specify modem settings with 'Options'  Press any key..", 1: KEYSTOP: GOTO MainMenu
  SELECT CASE UCASE$(Choice$)
  CASE "T": GOSUB LetsTalk
  CASE "D": GOSUB DialMeUp
  CASE "H": GOSUB HangUp
  CASE "S": GOSUB Sendfile
  CASE "R": GOSUB ReceiveFile
  END SELECT
 CASE "O": GOSUB GetSettings
 CASE "E", "": EXIT DO
 END SELECT
LOOP
CLOSE #1

IF NOT ModemSet OR NOT ModemChanged THEN EndItAll
DO
MENU "Save settings to MODEMSET.INI [_Y/_N]?", 1: ch$ = UCASE$(KEYWAIT$)
 IF ch$ = "Y" OR ch$ = CHR$(13) THEN
  OPEN "MODEMSET.INI" FOR OUTPUT AS #2
  PRINT #2, ";This file (MODEMSET.INI) is used by the BASIC program COMTALK.BAS to automatically set itself up for use with your modem"
  PRINT #2, ";Any commands after the DO: statement will be interpreted as modem commands, place your commands after the DO: statement"
  PRINT #2, "PORT=" + COMport$: PRINT #2, "SPEED=" + Speed$: PRINT #2, "PARITY=" + Parity$: PRINT #2, "DATABITS=" + DATAbits$: PRINT #2, "DO:" + CHR$(13) + PreSet$;
  CLOSE #2: EXIT DO
 ELSEIF ch$ = "N" OR ch$ = "" THEN EXIT DO
 END IF
LOOP
EndItAll

GetSettings:
IF COMport$ = "" THEN COMport$ = "COM2"
DO
 MENU "Which communication port is your modem using? Com_1 or Com_2 [" + COMport$ + "]", 1: ch$ = KEYWAIT$
 SELECT CASE ch$
 CASE ""
 CASE "": RETURN
 CASE CHR$(13): EXIT DO
 CASE ELSE: IF INSTR("12", ch$) THEN COMport$ = "COM" + ch$: EXIT DO
 END SELECT
LOOP
IF Speed$ = "" THEN Speed$ = "2400"
ch$ = Speed$
valid$ = " 75 110 150 300 600 1200 2400 4800 9600 "
DO
 MENU "What speed will you use:", 1: ch$ = STRPROMPT$(6, 5, ch$, Kbrd$, "", 112, 127, -1, 0)
 IF Kbrd$ = CHR$(13) THEN IF ch$ = "" THEN EXIT DO ELSE IF INSTR(valid$, " " + ch$ + " ") THEN Speed$ = ch$: EXIT DO ELSE MENU "Valid speeds:" + valid$ + " Press any key..", 1: KEYSTOP ELSE IF Kbrd$ = CHR$(27) THEN RETURN
LOOP
IF Parity$ = "" THEN Parity$ = "E"
DO
 MENU "Parity type? _None, _Space, _Even, _Mark, or _Odd [" + Parity$ + "]", 1
 valid$ = "NSEMO": ch$ = UCASE$(KEYWAIT$)
 IF ch$ = "" THEN RETURN
 IF ch$ = CHR$(13) THEN EXIT DO
 IF INSTR(valid$, ch$) AND ch$ > "" THEN Parity$ = ch$: EXIT DO
LOOP
IF DATAbits$ = "" THEN IF Parity$ = "N" THEN DATAbits$ = "8" ELSE DATAbits$ = "7"
ModemChanged = -1
EstablishModem
RETURN

DialMeUp:
IF Phone$ = "" THEN Phone$ = "ATDT "
MENU "Enter the phone number to dial:", 1
Kbrd$ = "": DO: Phone$ = STRPROMPT$(40, 64, Phone$, Kbrd$, "", 112, 127, -1, 5): LOOP UNTIL Kbrd$ = CHR$(13) OR Kbrd$ = ""
IF Kbrd$ = "" OR Phone$ = "" THEN RETURN
MENU "Dialing, Waiting for response from modem (or user to press any key)", 1
ShowStatus 1
PRINT #1, Phone$: PreLoc = LOC(1): Talk$(0) = Phone$ + CHR$(13): UpdateWindow = 1: GOSUB UpdateWindows
DO UNTIL INKEY$ > ""
IF LOC(1) > PreLoc THEN EXIT DO ELSE IF LOC(1) < PreLoc THEN PreLoc = LOC(1)
LOOP
Talk$(1) = ComBuffer$: UpdateWindow = 2: GOSUB UpdateWindows
RETURN

HangUp:
MENU "Hanging up, Waiting for response from modem (or user to press any key)", 1
ShowStatus 1
PRINT #1, "ATH": PreLoc = LOC(1): Talk$(0) = "ATH" + CHR$(13): UpdateWindow = 1: GOSUB UpdateWindows
DO UNTIL INKEY$ > ""
 IF LOC(1) > PreLoc THEN EXIT DO ELSE IF LOC(1) < PreLoc THEN PreLoc = LOC(1)
LOOP
Talk$(1) = ComBuffer$: UpdateWindow = 2: GOSUB UpdateWindows
RETURN

Sendfile:
MENU "Press Control-D to goto the DOS prompt, then type 'EXIT' to come back.", 25
MENU "Enter the filename to send :", 1: file$ = STRPROMPT$(47, 128, file$, Keys$, "", 112, 127, -1, 0)
IF Keys$ = CHR$(4) THEN
 PCOPY 0, 1: CLS : SHELL
 PCOPY 1, 0: GOTO Sendfile
ELSEIF Keys$ = CHR$(27) OR file$ = "" THEN
 RETURN
ELSEIF Keys$ = CHR$(13) THEN
 ON ERROR GOTO SFileTrap: OPEN file$ FOR INPUT AS #3: CLOSE #3

 MENU "_Wait for start [XON] signal from other user, or _Send anyway?", 1
 ShowStatus 0
 IF IgnorErrs THEN ON ERROR GOTO ModemTrap
 Choice$ = UCASE$(KEYWAIT$)
 IF Choice$ = "" THEN GOTO Sendfile
 IF Choice$ = "W" THEN
  ShowStatus 1
  MENU "Waiting for start signal, user to continue-ENTER, or user to cancel-ESC", 1: COLOR 26: PRINT "..."
  PreLoc = LOC(1)
  DO
   IF LOC(1) > PreLoc THEN IF INPUT$(LOC(1), 1) = CHR$(17) THEN EXIT DO ELSE  ELSE IF LOC(1) < PreLoc THEN PreLoc = LOC(1)
   SELECT CASE INKEY$: CASE "": RETURN: CASE CHR$(13): EXIT DO: END SELECT
  LOOP
 END IF

 ShowStatus 2
 OPEN file$ FOR BINARY AS #3: SEEK #1, 1
 MENU "Sending ", 1: PRINT file$ + "  File Length:" + STR$(LOF(3)); : COLOR 26: PRINT "..."
 FOR s& = 1 TO LOF(3)
  s$ = INPUT$(16, 3): PRINT #1, s$;
  DEF SEG = 0: IF PEEK(1047) AND 16 THEN Talk$(0) = s$: UpdateWindow = 1: GOSUB UpdateWindows
  IF INP(96) = 1 OR s$ = "" THEN EXIT FOR
 NEXT s&
 WHILE INKEY$ > "": WEND
 IF Sounds THEN PLAY "mbl24n40n44n45"
 CLOSE #3: ON ERROR GOTO 0
END IF
RETURN

SFileTrap:
MENU "That filename is a bad name, try again and press ENTER, or ESC to quit.", 1: KEYSTOP
RESUME Sendfile

ReceiveFile:
MENU "Press Control-D to goto the DOS prompt, then type 'EXIT' to come back.", 25
MENU "Enter the filename to recieve :", 1: file$ = STRPROMPT$(44, 128, file$, Keys$, "", 112, 127, -1, 0)
IF Keys$ = CHR$(4) THEN
 PCOPY 0, 1: CLS : SHELL
 PCOPY 1, 0: GOTO ReceiveFile
ELSEIF Keys$ = CHR$(27) OR file$ = "" THEN
 RETURN
ELSEIF Keys$ = CHR$(13) THEN
 ON ERROR GOTO RFileTrap: OPEN file$ FOR INPUT AS #3: CLOSE #3
 IF FilExists(file$) OR FilExists(file$ + ".REC") THEN SOUND 1024, 1: MENU "The filename you entered already exists, do you want to overwrite it (Y/N)", 1: IF NOT UCASE$(KEYWAIT$) = "Y" THEN GOTO ReceiveFile
 IF INSTR(file$, ".") = 0 THEN file$ = file$ + ".REC"

 MENU "Waiting to receive data, user to continue-ENTER, or user to cancel-ESC", 1: COLOR 26: PRINT "..."
 ShowStatus 1
 IF IgnorErrs THEN ON ERROR GOTO ModemTrap
 PRINT #1, CHR$(17)
 PreLoc = LOC(1)
 DO UNTIL LOC(1) > PreLoc
  IF LOC(1) < PreLoc THEN PreLoc = LOC(1)
  SELECT CASE INKEY$: CASE "": RETURN: CASE CHR$(13): EXIT DO: END SELECT
 LOOP

 MENU "Receiving to ", 1: PRINT file$; : COLOR 26: PRINT "..."
 ShowStatus 1
 OPEN file$ FOR OUTPUT AS #3
 DO UNTIL EOF(1) AND LOC(1) = 0
  s$ = INPUT$(LOC(1), 1): PRINT #3, s$;
  DEF SEG = 0: IF PEEK(1047) AND 16 THEN Talk$(1) = s$: UpdateWindow = 2: GOSUB UpdateWindows
  IF INP(96) = 1 THEN EXIT DO
 LOOP
 WHILE INKEY$ > "": WEND
 IF Sounds THEN PLAY "mbl24n40n44n45"
 CLOSE #3: ON ERROR GOTO 0
END IF
RETURN

RFileTrap:
IF ERR <> 53 THEN MENU "That filename is a bad name, try again and press ENTER, or ESC to quit.", 1: KEYSTOP ELSE RESUME NEXT
RESUME ReceiveFile

LetsTalk:
MENU " F10 = Main Menu, F2 = Switch modes, F3 = Clear window, F4 = Toggle record", 1: ShowStatus 3
ShowTalkCursor = 3: IF IgnorErrs THEN ON ERROR GOTO ModemTrap
DO
 Talk$(1) = ComBuffer: Kbrd$ = INKEY$
 IF TalkMode THEN
  IF Kbrd$ = CHR$(13) THEN Talk$(0) = Talk$ + Kbrd$: CurP = -1: CurS = 0
  IF Kbrd$ > "" THEN LOCATE 22, 6, 0: Talk$ = STRPROMPT$(70, 128, Talk$, "", Kbrd$, 14, 126, CurP, CurS)
 ELSE
  IF LEN(Kbrd$) = 1 THEN Talk$(0) = Kbrd$ ELSE Talk$(0) = ""
 END IF
 DEF SEG = 0: IF (PEEK(1047) AND 12) = 12 OR Kbrd$ = CHR$(0) + "D" THEN EXIT DO
 IF Kbrd$ = CHR$(0) + "<" THEN TalkMode = TalkMode XOR 1: IF TalkMode THEN LOCATE 22, 6: Talk$ = STRPROMPT$(70, 128, Talk$, CHR$(13), Kbrd$, 14, 126, CurP, CurS) ELSE ShowTalkCursor = 1: GOSUB UpdateWindows
 IF Kbrd$ = CHR$(0) + "=" THEN IF TalkText$(0) > "" THEN TalkText$(0) = "": PICTDRAW Hite, Wdth, 3, 5, SPACE$(Hite * Wdth): ShowTalkCursor = -1: GOSUB UpdateWindows
 IF Kbrd$ = CHR$(0) + ">" THEN IF RcrdFile$ > "" THEN RcrdMode = RcrdMode XOR 1: ShowStatus (State%): ShowTalkCursor = -1: GOSUB UpdateWindows

 IF LEN(Talk$(0)) > 0 OR LEN(Talk$(1)) > 0 THEN SOUND 12000, .024
 IF Talk$(0) > "" THEN PRINT #1, Talk$(0); : UpdateWindow = UpdateWindow OR 1: GOSUB UpdateWindows: WHILE INKEY$ > "": WEND
 IF Talk$(1) > "" THEN UpdateWindow = UpdateWindow OR 2: GOSUB UpdateWindows: IF RcrdMode THEN PRINT #4, Talk$(1);
 IF ShowTalkCursor AND Talk$(0) + Talk$(1) = "" THEN GOSUB UpdateWindows
LOOP
ON ERROR GOTO 0
RETURN

UpdateWindows:
 IF UpdateWindow AND 1 THEN
  PreWinRow = INT(LEN(TalkText$(0)) / Wdth): ShowTalkCursor = ShowTalkCursor OR 1
  PARAGRAPH TalkText$(0), Talk$(0), Wdth, Hite, Scrl: Talk$(0) = ""
  Leng = LEN(TalkText$(0)): CurWinRow = INT(Leng / Wdth): CurWinCol = INT(Leng MOD Wdth)
  IF Scrl THEN PICTDRAW Hite, Wdth, 3, 5, TalkText$(0) + SPACE$(Hite * Wdth - Leng) ELSE PICTDRAW Hite, Wdth, PreWinRow + 3, 5, RIGHT$(TalkText$(0), Wdth * (CurWinRow - PreWinRow) + CurWinCol) + SPACE$(Wdth - CurWinCol)
 END IF
 IF UpdateWindow AND 2 THEN
  PreWinRow = INT(LEN(TalkText$(1)) / Wdth): ShowTalkCursor = ShowTalkCursor OR 2
  PARAGRAPH TalkText$(1), Talk$(1), Wdth, Hite, Scrl: Talk$(1) = ""
  Leng = LEN(TalkText$(1)): CurWinRow = INT(Leng / Wdth): CurWinCol = INT(Leng MOD Wdth)
  IF Scrl THEN PICTDRAW Hite, Wdth, 3, 43, TalkText$(1) + SPACE$(Hite * Wdth - Leng) ELSE PICTDRAW Hite, Wdth, PreWinRow + 3, 43, RIGHT$(TalkText$(1), Wdth * (CurWinRow - PreWinRow) + CurWinCol) + SPACE$(Wdth - CurWinCol)
 END IF
 IF ShowTalkCursor THEN
  LOCATE , , 1, 0, 7
  IF ShowTalkCursor AND 2 THEN LOCATE INT(LEN(TalkText$(1)) / Wdth) + 4, LEN(TalkText$(1)) MOD Wdth + 44: COLOR 9, 0: PRINT "Ý";
  IF ShowTalkCursor AND 1 THEN LOCATE INT(LEN(TalkText$(0)) / Wdth) + 4, LEN(TalkText$(0)) MOD Wdth + 6: COLOR 12, 0: PRINT "Ý";
 END IF
 UpdateWindow = 0
 ShowTalkCursor = 0
RETURN

ModemTrap:
IF ERR = 24 THEN ShowStatus State
IF ERR = 57 THEN ShowStatus State
RESUME NEXT

FileExistsTrap:
IF ERR THEN Exists = 0'No
RESUME NEXT

DEFSNG A-Z
FUNCTION ComBuffer$
ComBuffer$ = INPUT$(LOC(1), 1)
END FUNCTION

DEFINT A-Z
FUNCTION DELETE$ (Text$, St, Lg)
IF SGN(Lg) = -1 THEN Lt = St + Lg: Rt = LEN(Text$) - St ELSE Lt = St: Rt = LEN(Text$) - (St + Lg)
IF Lt > LEN(Text$) THEN Lt = LEN(Text$) ELSE IF Lt < 0 THEN Lt = 0
IF Rt > LEN(Text$) THEN Rt = LEN(Text$) ELSE IF Rt < 0 THEN Rt = 0
DELETE$ = LEFT$(Text$, Lt) + RIGHT$(Text$, Rt)
END FUNCTION

DEFSNG A-Z
SUB EndItAll
IF RcrdFile$ > "" THEN CLOSE #4
COLOR 7, 0: CLS : SYSTEM
END SUB

DEFSTR A-Z
SUB EstablishModem
MENU "Establishing " + COMport + " Connection..", 1
comfil = COMport + ":" + Speed + "," + Parity + "," + DATAbits$
IF LEFT$(comfil, 3) <> "COM" THEN comfil = COMport
IF FREEFILE > 1 THEN CLOSE 1
OPEN comfil FOR RANDOM AS #1
IF Sounds THEN PLAY "mbl24n40n40n45"
ModemSet% = -1
END SUB

DEFINT A-Z
FUNCTION FilExists% (file$)
ON ERROR GOTO FileExistsTrap: Exists = -1'Yes
OPEN file$ FOR INPUT AS #3: CLOSE #3
ON ERROR GOTO 0: FilExists% = Exists
END FUNCTION

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
SUB MENU (Text$, CoLin)
LOCATE CoLin, 1, 0: COLOR , 7
DO UNTIL Show >= LEN(Text$)
 Show = Show + 1: IF MID$(Text$, Show, 1) = "_" THEN COLOR 15: Show = Show + 1 ELSE COLOR 10
 Leng = Leng + 1: PRINT MID$(Text$, Show, 1);
LOOP
PreV = CSRLIN: PreH = POS(0): IF 80 - Leng > 0 THEN PRINT SPACE$(80 - Leng); : LOCATE PreV, PreH
END SUB

SUB PARAGRAPH (Text$, Rslt$, Wdth, Hite, Scrl)
 Scrl = 0: IF Wdth < 1 THEN EXIT SUB
 FOR Make = 1 TO LEN(Rslt$)
  SELECT CASE MID$(Rslt$, Make, 1)
  CASE CHR$(13): Text$ = Text$ + SPACE$(Wdth - LEN(Text$) MOD Wdth)
  CASE CHR$(10)
  CASE CHR$(9): Text$ = Text$ + SPACE$(8 - (LEN(Text$) MOD Wdth MOD 8))
  CASE ELSE: Text$ = Text$ + MID$(Rslt$, Make, 1)
  END SELECT
 NEXT Make
 IF Hite THEN WHILE LEN(Text$) >= Wdth * Hite: Text$ = RIGHT$(Text$, LEN(Text$) - Wdth): Scrl = Scrl + 1: WEND
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
SUB ShowStatus (State%)
Sign$ = MID$("xé", State% + 1, 1)
IF RcrdMode% THEN Rcrd$ = "On" ELSE Rcrd$ = "Off"
MENU " ( )-" + COMport$ + "  Speed-" + Speed$ + "  Parity-" + Parity$ + "  Data-" + DATAbits$ + "  Record-" + Rcrd$, 25
PICTDRAW 1, 3, 24, 1, "(" + Sign$ + ")"
END SUB

FUNCTION Sounds%
DEF SEG = 0: Sounds% = (PEEK(1047) AND 32)
END FUNCTION

DEFINT A-Z
FUNCTION STRPROMPT$ (Leng, RcLn, Prst$, Keys$, KeyIn$, Colr, Bclr, CurP, CurS)
IF CurP = -1 THEN CurP = LEN(Prst$)
Vlin = CSRLIN: Lcol = POS(0): Rslt$ = Prst$: Shft = -1: GOSUB StrPromptShow

DO
DEF SEG = 0: Nsrt = PEEK(1047) AND 128: Shft = PEEK(1047) AND 3
IF Nsrt THEN LOCATE , , , 3, 6 ELSE LOCATE , , , 5, 6
Chng = -1: IF KeyIn$ > "" THEN Kbrd$ = KeyIn$: Done = -1 ELSE Kbrd$ = INKEY$
SELECT CASE Kbrd$
CASE "": Chng = 0
CASE " " TO "ÿ": GOSUB StrPromptInsert
CASE CHR$(0) + "K": IF CurP > 0 THEN CurP = CurP - 1
CASE CHR$(0) + "M": IF CurP < LEN(Rslt$) THEN CurP = CurP + 1
CASE CHR$(0) + "G": CurP = 0
CASE CHR$(0) + "O": CurP = LEN(Rslt$)
CASE CHR$(0) + "S": IF CurP - CurS THEN Rslt$ = DELETE(Rslt$, CurS, CurP - CurS): IF CurS < CurP THEN CurP = CurS ELSE  ELSE Rslt$ = DELETE$(Rslt$, CurP, 1)
CASE CHR$(0) + "R"
CASE CHR$(0) + "s": Lttr = 0
 FOR Srch = CurP TO 1 STEP -1
  IF INSTR(" ÿ()/\.	", MID$(Rslt$, Srch, 1)) = 0 THEN Lttr = -1 ELSE IF Lttr THEN CurP = Srch: EXIT FOR
 NEXT Srch: IF Srch = 0 THEN CurP = 0
CASE CHR$(0) + "t": Lttr = 0
 FOR Srch = CurP + 1 TO LEN(Rslt$)
  IF INSTR(" ÿ()/\.	", MID$(Rslt$, Srch, 1)) THEN Lttr = -1 ELSE IF Lttr THEN CurP = Srch - 1: EXIT FOR
 NEXT Srch: IF Srch = LEN(Rslt$) + 1 THEN CurP = LEN(Rslt$)
CASE ELSE
 IF Nsrt AND LEN(Kbrd$) < 2 THEN
  GOSUB StrPromptInsert
 ELSE
  SELECT CASE Kbrd$
  CASE CHR$(8): Rslt$ = DELETE$(Rslt$, CurP, -1): CurP = CurP - 1
  CASE ELSE: Chng = 0: Done = -1: Keys$ = Kbrd$
  END SELECT
 END IF
END SELECT
IF Chng THEN GOSUB StrPromptShow: Chng = 0
LOOP UNTIL Done

STRPROMPT$ = Rslt$
EXIT FUNCTION
StrPromptShow:
 IF CurP < 0 THEN CurP = 0 ELSE IF CurP > LEN(Rslt$) THEN CurP = LEN(Rslt$)
 IF CurP < RsCr THEN RsCr = CurP ELSE IF CurP > RsCr + Leng THEN RsCr = CurP - Leng
 IF Shft = 0 THEN CurS = CurP
 IF Leng - (LEN(Rslt$) - RsCr) >= 0 THEN Tail$ = SPACE$(Leng - (LEN(Rslt$) - RsCr)) ELSE Tail$ = ""
 PICTDRAW 1, Leng, Vlin - 1, Lcol - 1, MID$(Rslt$, RsCr + 1, Leng) + Tail$
 IF CurP < CurS THEN CurL = CurP - RsCr: CurR = CurS - RsCr ELSE CurL = CurS - RsCr: CurR = CurP - RsCr
 IF CurL < 0 THEN CurL = 0
 IF CurR > Leng THEN CurR = Leng
 CurL = CurL + Lcol: CurR = CurR + Lcol
 IF CurL > Lcol THEN HIGHLIGHT Lcol, CurL - 1, Vlin, Colr
 IF CurP - CurS THEN HIGHLIGHT CurL, CurR - 1, Vlin, Bclr
 IF CurR < Leng + Lcol THEN HIGHLIGHT CurR, Leng + Lcol - 1, Vlin, Colr
 IF CurP >= RsCr AND CurP < RsCr + Leng THEN LOCATE Vlin, Lcol + (CurP - RsCr), 1 ELSE LOCATE Vlin, , 0
RETURN
StrPromptInsert:
 Rslt$ = DELETE(Rslt$, CurS, CurP - CurS): IF CurS < CurP THEN CurP = CurS
 IF LEN(Rslt$) + LEN(Kbrd$) > RcLn THEN SOUND 860, .1: RETURN
 IF CurP >= 0 AND CurP <= LEN(Rslt$) THEN Rslt$ = LEFT$(Rslt$, CurP) + Kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - CurP): Shft = 0
 CurP = CurP + LEN(Kbrd$)
RETURN
END FUNCTION

