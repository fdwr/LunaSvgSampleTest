DEFINT A-Z
COLOR , 0: CLS : VIEW PRINT
CONST Mconst = .0594631: keylimit = 25: ToneBase = 64: songlength = 1
Scale = 1: deci = 1

Keysdefined:
ON KEY(1) GOSUB toneA: KEY(1) ON
ON KEY(2) GOSUB toneB: KEY(2) ON
ON KEY(3) GOSUB toneC: KEY(3) ON
ON KEY(4) GOSUB toneD: KEY(4) ON
ON KEY(5) GOSUB toneE: KEY(5) ON
ON KEY(6) GOSUB toneF: KEY(6) ON
ON KEY(7) GOSUB toneG: KEY(7) ON
ON KEY(8) GOSUB toneH: KEY(8) ON
ON KEY(9) GOSUB toneI: KEY(9) ON
ON KEY(10) GOSUB toneJ: KEY(10) ON
ON KEY(30) GOSUB toneK: KEY(30) ON
ON KEY(31) GOSUB toneL: KEY(31) ON
ON KEY(14) GOSUB Octdn: ON KEY(11) GOSUB Octup
KEY(11) ON: KEY(14) ON
ON KEY(12) GOSUB ScaleL: ON KEY(13) GOSUB ScaleR
KEY(12) ON: KEY(13) ON
KEY 15, CHR$(32) + CHR$(15)
ON KEY(15) GOSUB modechange: KEY(15) ON

GOSUB Fileprinter: Title$ = ""
Status:
fore = 8: back = 0: lin = 0: col = 0: boxH = 6: boxL = 26
GOSUB boxdrawer
fore = 8: back = 0: lin = 16: col = 10: boxH = 6: boxL = 70
GOSUB boxdrawer
fore = 8: back = 0: lin = 16: col = 0: boxH = 6: boxL = 10
GOSUB boxdrawer

NoteBoard:
fore = 8: back = 1: lin = 9: col = 16: boxH = 3: boxL = 62: shadow = 0
GOSUB boxdrawer
COLOR 8, 7
FOR hcol = 18 TO 76 STEP 2
LOCATE 13, hcol: PRINT " ³"
NEXT hcol
COLOR 0, 7
FOR vrow = 11 TO 12
FOR hcol = 18 TO 76 STEP 2
LOCATE vrow, hcol: PRINT " Û"
NEXT hcol
NEXT vrow

letters$ = "ABCDEFGHIJKL"
letters$ = letters$ + letters$ + letters$ + letters$ + letters$

GOSUB StatusDisplay
GOSUB Scale
GOTO NotePrompt

Scale:
SELECT CASE Scale
CASE 1: a = 0: b = 1: c = 2: d = 3: e = 4: f = 5
g = 6: h = 7: i = 8: j = 9: k = 10: l = 11

CASE 2: a = 0: b = 2: c = 4: d = 5: e = 7: f = 9
g = 11: h = 12: i = -1: j = -1: k = -1: l = -1

CASE 3: a = 0: b = 2: c = 3: d = 5: e = 7: f = 8
g = 10: h = 12: i = -1: j = -1: k = -1: l = -1

CASE 4: a = 0: b = 2: c = 3: d = 5: e = 7: f = 9
g = 11: h = 12: i = -1: j = -1: k = -1: l = -1

CASE 5: a = 0: b = 2: c = 3: d = 5: e = 7: f = 8
g = 11: h = 12: i = -1: j = -1: k = -1: l = -1

END SELECT
RETURN

StatusDisplay: DisplayChange = 0
COLOR 5, 0: LOCATE 15, 18: PRINT letters$
COLOR 13
FOR rpt = 1 TO 12
 letr = SCREEN(15, keylimit + rpt + 16): IF rpt = 1 THEN mkey = letr
 LOCATE 15, keylimit + rpt + 16: PRINT CHR$(letr);
NEXT rpt

COLOR 11: LOCATE 10, 3: PRINT "KeyÄÄÄÄÄ "; CHR$(mkey)
COLOR 3: LOCATE , 3: PRINT "NoteÄÄÄÄ"
COLOR 9: LOCATE , 3: PRINT "PitchÄÄÄ"
octave = INT((keylimit + 11) / 12)
COLOR 1: LOCATE , 3: PRINT "OctaveÄÄ"; octave
COLOR 5: LOCATE , 3: PRINT "KeyBaseÄ"; keylimit
COLOR 13: LOCATE , 3: PRINT "ToneBase"; ToneBase

LOCATE 3, 1: COLOR 8: PRINT "ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´"
SELECT CASE deci
CASE 0
LOCATE , 4: COLOR 12: PRINT "F for file options..."
LOCATE , 4: COLOR 14: PRINT "O for music options.."
LOCATE , 4: COLOR 10: PRINT "Type H for MSC help.."
LOCATE , 4: COLOR 9: PRINT "Ù E-EXIT   "
CASE 1
LOCATE , 4: COLOR 9: PRINT "Type O to open a song"
LOCATE , 4: COLOR 10: PRINT "Type N for a new song"
LOCATE , 4: COLOR 14: PRINT "Type S to save a song"
LOCATE , 4: COLOR 12: PRINT "Ù B-Go Back"
CASE 2
LOCATE , 4: COLOR 9: PRINT "TÄÄTune Note ToneBase"
LOCATE , 4: COLOR 10: PRINT "SÄÄÄChange Note Scale"
LOCATE , 4: COLOR 14: PRINT "PÄÄÄSong Play Options"
LOCATE , 4: COLOR 12: PRINT "Ù B-Go Back"
CASE 3
LOCATE , 4: COLOR 2: PRINT "CÄÄChanging Play Mode"
LOCATE , 4: COLOR 10: PRINT "PÄÄHow to Play a song"
LOCATE , 4: COLOR 14: PRINT "SOÄSaving and Opening"
LOCATE , 4: COLOR 12: PRINT "Ù B-Go Back"
CASE 20
LOCATE , 4: COLOR 9: PRINT "ToneBase (50-70)Ä"; ToneBase
LOCATE , 4: COLOR 10: PRINT "Change Base ?  (Tune)"
LOCATE , 4: COLOR 30: PRINT "                    "
LOCATE , 4: COLOR 12: PRINT "Ù B-Go Back"
CASE 21
LOCATE , 4: COLOR 9: PRINT "JÄÄÄMajor  LÄÄMelodic"
LOCATE , 4: COLOR 10: PRINT "NÄÄÄMinor  RÄHarmonic"
LOCATE , 4: COLOR 14: PRINT "CÄChromatic  UÄÄÄUser"
LOCATE , 4: COLOR 12: PRINT "Ù B-Go Back"
END SELECT
LOCATE 2, 4
SELECT CASE mode
CASE 0: COLOR 9: PRINT "Now in play mode only "; : COLOR 17: PRINT CHR$(17)
CASE 1: COLOR 12: PRINT "Now in recording mode "; : COLOR 20: PRINT CHR$(16)
END SELECT
RETURN

Fileprinter:
fore = 8: back = 0: lin = 0: col = 26: boxH = 6: boxL = 54: titleC = 15
IF file$ = "" THEN Title$ = "Untitled" ELSE Title$ = UCASE$(file$)
GOSUB boxdrawer
FilePrint:
stringlength = LEN(playstring$)
COLOR 7: LOCATE 2, 27: st = 1: IF stringlength > 0 THEN PRINT ":";
FOR rpt = 1 TO INT(stringlength / 52) + 1
LOCATE , 28: PRINT MID$(MID$((playstring$ + " "), 1, 312), st, 52)
st = st + 52
NEXT rpt
RETURN

NotePrompt:
SLEEP: user$ = INKEY$: IF user$ = CHR$(27) THEN END
GOSUB Menu
stringlength = LEN(playstring$)
IF mode = 1 AND user$ = "" AND stringlength >= 1 THEN
playstring$ = MID$(playstring$, 1, LEN(playstring$) - 1)
GOSUB FilePrint
END IF
IF user$ = CHR$(13) THEN GOSUB Playing
IF user$ <> CHR$(32) AND user$ > CHR$(1) THEN GOTO NotePrompt
GOSUB Sounding
IF mode = 1 THEN
stringpart$ = CHR$(x + keylimit + 128)
IF user$ = " " THEN stringpart$ = CHR$(32)
playstring$ = playstring$ + stringpart$
GOSUB FilePrint
END IF
GOTO NotePrompt

Menu: predeci = deci
user$ = UCASE$(user$)
SELECT CASE deci
CASE 0 'MainMenu
IF user$ = "F" THEN deci = 1
IF user$ = "O" THEN deci = 2
IF user$ = "H" THEN deci = 3
IF user$ = "E" THEN END
CASE 1 'FileMenu
IF user$ = "O" THEN GOSUB OpeningFile
IF user$ = "N" THEN GOSUB NewFile
IF user$ = "S" THEN GOSUB SavingFile
IF user$ = "B" THEN deci = 0
CASE 2 'OptionsMenu
IF user$ = "T" THEN deci = 20
IF user$ = "S" THEN deci = 21
IF user$ = "B" THEN deci = 0

CASE 20 'ToneSetting
IF user$ = "+" AND ToneBase < 70 THEN ToneBase = ToneBase + 1
IF user$ = "-" AND ToneBase > 50 THEN ToneBase = ToneBase - 1
IF user$ > CHR$(47) AND user$ < CHR$(58) THEN
IF LEN(Temp$) = 1 THEN Temp$ = Temp$ + user$
IF LEN(Temp$) = 0 THEN Temp$ = Temp$ + user$
COLOR 15: LOCATE 6, 13: PRINT Temp$; " "
 IF LEN(Temp$) = 2 THEN
 ToneBase = VAL(Temp$): Temp$ = ""
 END IF
END IF
IF ToneBase < 50 THEN ToneBase = 50
IF ToneBase > 70 THEN ToneBase = 70
LOCATE 4, 20: COLOR 15: PRINT ToneBase
IF user$ = "B" THEN deci = 2

CASE 21 'Scales
prescale = Scale
IF user$ = "C" THEN Scale = 1
IF user$ = "J" THEN Scale = 2
IF user$ = "N" THEN Scale = 3
IF user$ = "L" THEN Scale = 4
IF user$ = "R" THEN Scale = 5
IF prescale <> Scale THEN
GOSUB Scale
GOSUB StatusDisplay
END IF
 SELECT CASE Scale
CASE 1: LOCATE 6, 4
CASE 2: LOCATE 4, 4
CASE 3: LOCATE 5, 4
CASE 4: LOCATE 4, 15
CASE 5: LOCATE 5, 15
END SELECT
COLOR 15
PRINT "û"
IF user$ = "B" THEN deci = 2
CASE 3
IF user$ = "B" THEN deci = 0
END SELECT
IF predeci <> deci THEN GOSUB StatusDisplay
RETURN

NewFile:
playstring$ = ""
file$ = ""
GOSUB Fileprinter
RETURN

OpeningFile:
ON ERROR GOTO FilErrHan
CHDIR "C:\MUSIC"
COLOR 9: LOCATE 2, 27: INPUT ":", file$
IF file$ = "" THEN file$ = "test.msc"
OPEN file$ FOR INPUT AS #1
IF NOT EOF(1) THEN
INPUT #1, playstring$
ELSE
GOSUB StatusDisplay
COLOR 3: PRINT "File Empty!": SLEEP: GOTO NotePrompt
END IF
CLOSE : GOSUB Fileprinter
RETURN

SavingFile:
ON ERROR GOTO FilErrHan
CHDIR "C:\MUSIC"
LOCATE 3, 4: COLOR 12: PRINT "Save ?  Yes or No Y/N"
SLEEP: user$ = INKEY$
IF UCASE$(user$) = "Y" THEN
LOCATE 3, 4: PRINT SPACE$(22)
LOCATE 3, 4: INPUT "Filename: ", file$
OPEN file$ FOR OUTPUT AS #1
PRINT #1, playstring$: CLOSE
END IF
GOSUB StatusDisplay
RETURN

Playing:
keyoff = keylimit: keylimit = 0
FOR rpt = 1 TO stringlength
x = ASC(MID$(playstring$, rpt, 1)) - 128
SOUND 32535, .3
puser$ = UCASE$(INKEY$): IF puser$ = " " THEN SLEEP
IF UCASE$(puser$) > "L" THEN lup = 0: EXIT FOR
IF puser$ = "L" THEN
IF lup = 0 THEN lup = 1 ELSE lup = 0
END IF

GOSUB Sounding
NEXT rpt
keylimit = keyoff
IF lup = 1 THEN GOTO Playing
RETURN


Sounding:
temptone = ToneBase
FOR repeat% = 1 TO x + keylimit
pitch = Mconst * temptone: temptone = pitch + temptone
NEXT repeat%
playnote% = temptone
IF x < 0 OR user$ = CHR$(32) THEN playnote% = 0
SOUND playnote%, 2
COLOR 3: LOCATE 11, 11: PRINT x + keylimit
COLOR 9: LOCATE 12, 13: PRINT "   "
COLOR 9: LOCATE 12, 11: PRINT RTRIM$(STR$(playnote%))
RETURN

toneA: x = a: RETURN
toneB: x = b: RETURN
toneC: x = c: RETURN
toneD: x = d: RETURN
toneE: x = e: RETURN
toneF: x = f: RETURN
toneG: x = g: RETURN
toneH: x = h: RETURN
toneI: x = i: RETURN
toneJ: x = j: RETURN
toneK: x = k: RETURN
toneL: x = l: RETURN

Octdn: DisplayChange = 1
keylimit = keylimit - 12: IF keylimit <= 1 THEN keylimit = 1
GOSUB StatusDisplay
RETURN NotePrompt

Octup: DisplayChange = 1
keylimit = keylimit + 12: IF keylimit >= 60 - 12 THEN keylimit = 49
GOSUB StatusDisplay
RETURN NotePrompt

ScaleL: DisplayChange = 1
IF keylimit > 1 THEN
keylimit = keylimit - 1
GOSUB StatusDisplay
END IF
RETURN NotePrompt

ScaleR: DisplayChange = 1
IF keylimit < 60 - 11 THEN
keylimit = keylimit + 1
GOSUB StatusDisplay
END IF
RETURN NotePrompt

modechange:
IF mode = 0 THEN mode = 1 ELSE mode = 0
GOSUB StatusDisplay
RETURN NotePrompt

boxdrawer:
COLOR fore, back
LOCATE lin + 1, col + 1: PRINT "Ú"; STRING$(boxL - 2, 196); "¿"
FOR height% = 1 TO boxH
LOCATE lin + height% + 1, col + 1: PRINT "³"; SPACE$(boxL - 2); "³"
NEXT height%
LOCATE lin + height% + 1, col + 1: PRINT "À"; STRING$(boxL - 2, 196); "Ù"
IF shadow = 1 THEN
COLOR 0: LOCATE lin + 2, col + 1 + boxL: PRINT "Û"
FOR height% = 1 TO boxH
LOCATE lin + height% + 2, col + 1 + boxL: PRINT "Û"
NEXT height%
LOCATE lin + height% + 2, col + 2: PRINT STRING$(boxL, 219)
shadow = 0
END IF
Title:
textover = boxL - LEN(MID$(Title$, 1, boxL))
textover = INT(textover / 2): COLOR titleC
LOCATE lin + 1, col + 1 + textover: PRINT MID$(Title$, 1, boxL)
Text:
COLOR textcolor: LOCATE lin + 2, col + 2: PRINT MID$(Boxtext$, 1, boxL - 2)
LOCATE lin + 2, col + 1: PRINT MID$(boxtext2$, 1, boxL)
RETURN

HelpInfo:
lin = 16: col = 2: boxH = 1: boxL = 22: fore = 10: back = 3
Title$ = "Help Line": titlecolor = 0: textcolor = 15
GOSUB boxdrawer: Title$ = ""
RETURN

FilErrHan:
 LOCATE 3, 4: COLOR 15
 IF ERR = 53 THEN PRINT "Sorry can not find it"
 IF ERR = 64 THEN PRINT "Bad Dog!  I mean name"
 IF ERR = 61 THEN PRINT "Dis Disk way too full"
 IF ERR = 58 THEN PRINT "Kill de existing file"
SLEEP: GOSUB StatusDisplay
RESUME NotePrompt:

