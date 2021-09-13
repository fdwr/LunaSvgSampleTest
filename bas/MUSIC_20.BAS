DECLARE SUB MAKENOTE (note%, leng!)
DECLARE SUB EditSong (SongPart$, SongPos%)
DEFINT A-Z: SCREEN 0, , 0, 0: COLOR , 7: CLS : VIEW PRINT
CONST Mconst = .0594631: KeyBase = 25: ToneBase = 62: songlength = 1
DIM SHARED Scale(1 TO 12), Song$
Deci = 1: spd% = 30: SongPos = 1

GOSUB Scale

NoteBoard:
fore = 0: back = 0: lin = 10: Col = 17: BoxH = 3: BoxL = 58
GOSUB BoxDrawer
fore = 8: back = 1: lin = 9: Col = 16: BoxH = 3: BoxL = 58
GOSUB BoxDrawer
COLOR 0, 7
FOR h% = 18 TO 60 STEP 14
 LOCATE 11, h%: PRINT " Û Û ³ Û Û Û ³"
 LOCATE 12, h%: PRINT " Û Û ³ Û Û Û ³"
 LOCATE 13, h%: PRINT " ³ ³ ³ ³ ³ ³ ³"
NEXT h%
letters$ = "C D E F G A B "
letters$ = letters$ + letters$ + letters$ + letters$

Status:
fore = 0: back = 0: lin = 9: Col = 2: BoxH = 4: BoxL = 13
GOSUB BoxDrawer
fore = 8: back = 0: lin = 0: Col = 0: BoxH = 6: BoxL = 26
'GOSUB BoxDrawer
'GOSUB Fileprinter
fore = 8: back = 0: lin = 17: Col = 0: BoxH = 6: BoxL = 12
textC = 3: boxtext$ = SPACE$(20) + "Enter-PlaySpace-PawsL-LoopSongQ-QuitPlay"
'GOSUB BoxDrawer
'LOCATE 20, 1: COLOR 8: PRINT "ÃÄÄÄÄÄÄÄÄÄÄ´";
fore = 7: back = 0: lin = 17: Col = 12: BoxH = 6: BoxL = 68
'GOSUB BoxDrawer

'GOSUB StatusDisplay
'GOSUB MenuDisplay

'PCOPY 0, 1
lin = 5: Col = 20: BoxH = 10: BoxL = 40: fore = 10: back = 3
title$ = "About": titleC = 0: textC = 15
boxtext$ = SPACE$(114) + "Press H to get online help at anytime." + SPACE$(38)
boxtext$ = boxtext$ + "Use Keys F1-F12 to Play and the cursorKeys to change Key or Octave. To use amenu item simply press the letter that"
boxtext$ = boxtext$ + "goes to it. Press E at the  main menu or Escape to Quit.  Hope you like it!"
'GOSUB BoxDrawer
'LOCATE 7, 30: PRINT "Dwayne's Music Player"
'LOCATE 8, 35: PRINT "Version 1.2"
'WHILE INKEY$ = "": WEND
'PCOPY 1, 0

Keysdefined:
ON KEY(14) GOSUB Octdn: ON KEY(11) GOSUB Octup
KEY(11) ON: KEY(14) ON
'ON KEY(12) GOSUB ScaleL: ON KEY(13) GOSUB ScaleR
KEY(12) ON: KEY(13) ON
KEY 15, CHR$(32) + CHR$(15)
ON KEY(15) GOSUB ModeChange: KEY(15) ON
Rcrd = 0
NotePrompt:
DO
 Kbrd = INP(96): Kbrd$ = INKEY$
 SELECT CASE Kbrd
 CASE 59 TO 68: Nkey = Kbrd - 58: note = Scale(Nkey) + KeyBase': GOSUB SoundIt
 CASE 87, 88: Nkey = Kbrd - 76: note = Scale(Nkey) + KeyBase': GOSUB SoundIt
 CASE 75: IF SongPos > 1 THEN SongPos = SongPos - 1
 CASE 77: IF SongPos < LEN(Song$) THEN SongPos = SongPos + 1
 CASE ELSE: Nkey = 0: note = 0
 END SELECT
 Paws = -1
 SELECT CASE Kbrd$
 CASE ""
 CASE "": SYSTEM
 CASE CHR$(13): IF Rcrd THEN Rcrd = 0 ELSE GOSUB Playing
 CASE ELSE: Paws = 0
 END SELECT
 COLOR 15, 0: LOCATE 1, 1: PRINT note, Kbrd, Nkey, LEN(Song$), SongPos
 IF Rcrd THEN
  SongPart$ = CHR$(Nkey + 128)
  EditSong SongPart$, SongPos
  SongPos = SongPos + 1
  GOSUB FilePrint
 END IF
LOOP

SELECT CASE UCASE$(User$)
CASE CHR$(8): IF Mode AND LEN(Song$) >= 1 THEN Song$ = MID$(Song$, 1, LEN(Song$) - 1): GOSUB FilePrint
CASE CHR$(13): GOSUB Playing
CASE CHR$(0) + "0": Deci = VAL(LEFT$(STR$(Deci), LEN(STR$(Deci)) - 1)): GOSUB MenuDisplay
CASE "": END
CASE "H": GOSUB HelpInfo
CASE ELSE: GOSUB Menu
END SELECT
GOTO NotePrompt

StatusDisplay:
COLOR 5, 0: LOCATE 15, 18: PRINT letters$
FOR rpt% = 1 TO 12
letr = SCREEN(15, KeyBase + rpt% + 16): IF rpt% = 1 THEN mkey = letr
COLOR 13: LOCATE 15, KeyBase + rpt% + 16: PRINT CHR$(letr);
NEXT rpt%
COLOR 11: LOCATE 10, 3: PRINT "KeyÄÄÄÄÄ "; CHR$(mkey)
COLOR 3: LOCATE , 3: PRINT "NoteÄÄÄÄ"
COLOR 9: LOCATE , 3: PRINT "PitchÄÄÄ"
Octave = INT((KeyBase + 11) / 12)
COLOR 1: LOCATE , 3: PRINT "OctaveÄÄ"; Octave
COLOR 5: LOCATE , 3: PRINT "KeyBaseÄ"; KeyBase
COLOR 13: LOCATE , 3: PRINT "ToneBase"; ToneBase
LOCATE 3, 1: COLOR 8: PRINT "ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´"
LOCATE 2, 3
IF Mode = 0 THEN COLOR 9: PRINT "Now in play mode only "; : COLOR 17: PRINT CHR$(17);  ELSE COLOR 12: PRINT "Now in recording mode "; : COLOR 20: PRINT CHR$(16)
RETURN

MenuDisplay:
SELECT CASE Deci
CASE 0
TEXT$ = "F for file options...O for music options..T to get help topics.Ù E-EXIT   "
COLR(1) = 12: COLR(2) = 14: COLR(3) = 10: COLR(4) = 9
CASE 1
TEXT$ = "Type O to open a songType N for a new songType S to save a songÄ B-Go Back"
COLR(1) = 9: COLR(2) = 10: COLR(3) = 14: COLR(4) = 12
CASE 2
TEXT$ = "TÄÄTune Note ToneBaseSÄÄÄChange Note ScalePÄÄÄSong Play OptionsÄ B-Go Back"
COLR(1) = 1: COLR(2) = 9: COLR(3) = 13: COLR(4) = 5
CASE 3
TEXT$ = "PÄÄHow to Play a songSOÄSaving and OpeningAÄÄAbout Music PlayerÄ B-Go Back"
COLR(1) = 12: COLR(2) = 14: COLR(3) = 10: COLR(4) = 9
CASE 20
TEXT$ = "ToneBase (60-70)Ä" + STR$(ToneBase) + " Change Base ?  (Tune)                   Ù B-Go Back"
COLR(1) = 9: COLR(2) = 10: COLR(3) = 30: COLR(4) = 12
CASE 21
TEXT$ = "JÄÄÄMajor  LÄÄMelodicNÄÄÄMinor  RÄHarmonicCÄChromatic  UÄÄÄUserÄ B-Go Back"
COLR(1) = 9: COLR(2) = 10: COLR(3) = 14: COLR(4) = 12
CASE 22
TEXT$ = "(+-)Change Play SpeedLÄÄLoop / Auto RewindSpeed =" + LEFT$(STR$(spd%) + "   ", 5) + " Loop =" + STR$(Lup) + "Ä B-Go Back"
COLR(1) = 5: COLR(2) = 13: COLR(3) = 10: COLR(4) = 9
END SELECT
FOR rpt% = 0 TO 3
TEXT$(rpt% + 1) = MID$(TEXT$, rpt% * 21 + 1, 21)
NEXT
FOR rpt% = 1 TO 4
COLOR COLR(rpt%), 0: LOCATE rpt% + 3, 3: PRINT TEXT$(rpt%) + SPACE$(21 - LEN(TEXT$(rpt%)))
NEXT
RETURN

Fileprinter:
fore = 8: back = 0: lin = 0: Col = 26: BoxH = 6: BoxL = 54: titleC = 15
IF file$ = "" THEN title$ = "Untitled" ELSE title$ = UCASE$(file$)
GOSUB BoxDrawer
FilePrint:
stringlength = LEN(Song$)
COLOR 7: LOCATE 2, 27: st = 1: IF stringlength > 0 THEN PRINT ":";
FOR rpt& = 1 TO INT(stringlength / 52) + 1
LOCATE , 28: PRINT MID$(MID$((Song$ + " "), 1, 312), st, 52)
st = st + 52
NEXT rpt&
RETURN

Menu: predeci = Deci
User$ = UCASE$(User$)
SELECT CASE Deci
CASE 0 'MainMenu
IF User$ = "F" THEN Deci = 1
IF User$ = "O" THEN Deci = 2
IF User$ = "T" THEN Deci = 3
IF User$ = "E" THEN END
CASE 1 'FileMenu
IF User$ = "O" THEN GOSUB OpeningFile
IF User$ = "N" THEN GOSUB NewFile
IF User$ = "S" THEN GOSUB SavingFile
IF User$ = "B" THEN Deci = 0
CASE 2 'OptionsMenu
IF User$ = "T" THEN Deci = 20
IF User$ = "S" THEN Deci = 21
IF User$ = "P" THEN Deci = 22
IF User$ = "B" THEN Deci = 0
CASE 20 'ToneSetting
IF User$ = "+" AND ToneBase < 70 THEN ToneBase = ToneBase + 1
IF User$ = "-" AND ToneBase > 60 THEN ToneBase = ToneBase - 1
IF User$ > CHR$(47) AND User$ < CHR$(58) THEN
IF LEN(Temp$) = 1 THEN Temp$ = Temp$ + User$
IF LEN(Temp$) = 0 THEN Temp$ = Temp$ + User$
COLOR 15: LOCATE 6, 13: PRINT Temp$; " "
 IF LEN(Temp$) = 2 THEN
 ToneBase = VAL(Temp$): Temp$ = ""
 END IF
END IF
IF ToneBase < 60 THEN ToneBase = 60
IF ToneBase > 70 THEN ToneBase = 70
LOCATE 4, 21: COLOR 15: PRINT ToneBase
IF User$ = "B" THEN Deci = 2

CASE 21 'Scales
prescale = Scale
IF User$ = "C" THEN Scale = 1
IF User$ = "J" THEN Scale = 2
IF User$ = "N" THEN Scale = 3
IF User$ = "L" THEN Scale = 4
IF User$ = "R" THEN Scale = 5
IF User$ = "U" THEN Scale = 6
IF prescale <> Scale THEN
GOSUB Scale
GOSUB MenuDisplay
END IF
 SELECT CASE Scale
CASE 1: LOCATE 6, 4
CASE 2: LOCATE 4, 4
CASE 3: LOCATE 5, 4
CASE 4: LOCATE 4, 15
CASE 5: LOCATE 5, 15
CASE 6: LOCATE 6, 17
 END SELECT
COLOR 15
PRINT "û"
IF User$ = "B" THEN Deci = 2
 CASE 22 'PlayOptions
IF User$ = "L" THEN IF Lup = 0 THEN Lup = 1 ELSE Lup = 0
IF User$ = "+" AND spd% > 10 THEN spd% = spd% - 1
IF User$ = "-" AND spd% < 250 THEN spd% = spd% + 1
LOCATE 6, 4: COLOR 10: PRINT "Speed ="; spd%; "  ";
LOCATE , 17: COLOR 10: PRINT "Loop ="; Lup
IF User$ = "B" THEN Deci = 2
CASE 3
IF User$ = "P" THEN Deci = 31: GOSUB HelpInfo
IF User$ = "S" OR User$ = "O" THEN Deci = 32: GOSUB HelpInfo
IF User$ = "A" THEN Deci = 33: GOSUB HelpInfo
Deci = 3
IF User$ = "B" THEN Deci = 0
END SELECT
IF predeci <> Deci THEN GOSUB MenuDisplay
RETURN

Playing:
PlayMode = -1: GOSUB PlayDisplay
FOR SongPos = SongPos TO LEN(Song$)
 SELECT CASE UCASE$(INKEY$)
 CASE ""
 CASE "L": Lup = Lup XOR 1: GOSUB PlayDisplay
 CASE ELSE: EXIT FOR
 END SELECT
 note = ASC(MID$(Song$, SongPos, 1)) - 128
 MAKENOTE note, .2
 SOUND 128 + (note * 5), .023
NEXT
PlayMode = 0: GOSUB PlayDisplay
RETURN

PlayDisplay: LOCATE 18, 3
IF Lup = 0 THEN PRINT "  " ELSE PRINT "Ù";
IF PlayMode THEN LOCATE 18, 5: PRINT "PLAY ";  ELSE LOCATE 18, 5: PRINT "STOP þ";
RETURN

Sounding:
Pitch% = ToneBase
FOR increment% = 1 TO note%
Pitch% = (Mconst * Pitch%) + Pitch%
NEXT increment%
IF note% <= 0 OR User$ = CHR$(32) THEN Pitch% = 0: note% = 0
SOUND INT(Pitch%), spd% / 16
COLOR 3, 0: LOCATE 11, 11: PRINT note%
LOCATE 12, 13: PRINT "   "
COLOR 9, 0: LOCATE 12, 11: PRINT RTRIM$(STR$(INT(Pitch%)))
User$ = "play"
RETURN

NewFile:
Song$ = ""
file$ = ""
GOSUB Fileprinter
RETURN

OpeningFile:
ON ERROR GOTO ErrHan
COLOR 9: LOCATE 2, 27: INPUT ":", file$
IF INSTR(file$, ".") = 0 THEN file$ = file$ + ".msc"
OPEN file$ FOR INPUT AS #1: CLOSE #1
OPEN file$ FOR BINARY AS #1: Song$ = INPUT$(LOF(1), #1): CLOSE #1
GOSUB StatusDisplay
GOSUB Fileprinter
RETURN

SavingFile:
ON ERROR GOTO ErrHan
LOCATE 3, 4: PRINT SPACE$(22)
LOCATE 3, 4: INPUT "Filename: ", sfile$
IF sfile$ = "" THEN RETURN
OPEN sfile$ FOR OUTPUT AS #1: PRINT #1, Song$; : CLOSE #1
GOSUB StatusDisplay
RETURN

Scale:
SELECT CASE Scale
CASE 0: FOR DefScl = 1 TO 12: Scale(DefScl) = DefScl: NEXT DefScl
CASE 2: a = 0: b = 2: c = 4: d = 5: e = 7: f = 9
g = 11: h = 12: i = -1: j = -1: k = -1: l = -1
CASE 3: a = 0: b = 2: c = 3: d = 5: e = 7: f = 8
g = 10: h = 12: i = -1: j = -1: k = -1: l = -1
CASE 4: a = 0: b = 2: c = 3: d = 5: e = 7: f = 9
g = 11: h = 12: i = -1: j = -1: k = -1: l = -1
CASE 5: a = 0: b = 2: c = 3: d = 5: e = 7: f = 8
g = 11: h = 12: i = -1: j = -1: k = -1: l = -1
CASE 6: a = 0: b = 2: c = 4: d = 5: e = 7: f = 9
g = 11: h = 1: i = 3: j = 6: k = 8: l = 10
END SELECT
RETURN

Octdn:
IF KeyBase = 1 THEN RETURN
KeyBase = KeyBase - 12
IF KeyBase <= 1 THEN KeyBase = 1
GOSUB StatusDisplay
RETURN

Octup:
IF KeyBase = 49 THEN RETURN
KeyBase = KeyBase + 12
IF KeyBase >= 60 - 12 THEN KeyBase = 49
GOSUB StatusDisplay
RETURN

ScaleL:
IF KeyBase > 1 THEN
KeyBase = KeyBase - 1
GOSUB StatusDisplay
END IF
RETURN

ScaleR:
IF KeyBase < 60 - 11 THEN
KeyBase = KeyBase + 1
GOSUB StatusDisplay
END IF
RETURN

ModeChange:
IF Mode THEN Mode = 0 ELSE Mode = 1
GOSUB StatusDisplay
RETURN

BoxDrawer:
lin% = lin + 1: Col% = Col + 1
COLOR fore, back: LOCATE lin%, Col%: PRINT "Ú"; STRING$(BoxL - 2, 196); "¿";
FOR height% = 1 TO BoxH: LOCATE lin% + height%, Col%: PRINT "³"; SPACE$(BoxL - 2); "³"; : NEXT height%
LOCATE lin% + height%, Col%: PRINT "À"; STRING$(BoxL - 2, 196); "Ù";

IF title$ > "" THEN 'Titler
LOCATE lin%, Col% + INT((BoxL - LEN(MID$(title$, 1, BoxL))) / 2)
COLOR titleC: PRINT MID$(title$, 1, BoxL): title$ = ""
END IF
IF boxtext$ > "" THEN 'Text
COLOR textC, back: st = 1
FOR rpt& = 1 TO INT(LEN(boxtext$) / BoxL + 1) + 1
LOCATE lin% + rpt&, Col% + 1: PRINT MID$(boxtext$, st, BoxL - 2);
st = st + BoxL - 2: NEXT rpt&: boxtext$ = ""
END IF
RETURN

HelpInfo:
PCOPY 0, 1
lin = 8: Col = 20: BoxH = 5: BoxL = 40: fore = 10: back = 3
title$ = "Help Line": titleC = 0: textC = 15
SELECT CASE Deci
CASE 0: boxtext$ = "þChoose File for disk activities such as Loading from disk or Saving to DiskþChoose Options to change options likescales, playing, or to tune the keys  þChoose Help topics for Help topics!"
CASE 1: boxtext$ = "þIf you know the name of a song, type its name at the prompt to open it up  þNew will totally clear the song box  þWhen you save a song, you can specify the path and name / same or different"
CASE 2: boxtext$ = "þYou can tune the keys for true pitch þChange the scale pattern to either:  Major, Minor, Chromatic, Melodic or ? þYou can also change songplay options like loop(auto-rewind) and play speed"
CASE 20: boxtext$ = "þEnter a tonebase, 60-70.  A tonebase is the base which DWMUSIC uses as the multiplicand for its note pitch. True piano pitch for " + CHR$(34) + "Middle C" + CHR$(34) + " is 62. Per-fect Binary pitch% starts on 64."
CASE 21: boxtext$ = "þA Scale is a pattern that uses only acertain pattern of notes in an an oct-ave. Many times you only need to use acertain group of notes out of an oct- ave. The SCALE cuts out all the rest. The Chromatic scale includes all the  notes of an octave. All of the rest   except user which is user-definable   are variations of the 7-note scale"
boxtext$ = boxtext$ + "(In other words they only use 7 out of the available 12 notes in an octave).": BoxH = 11: lin = 5
CASE 22: boxtext$ = "þUse the + and - keys  to change the  song playback speed and L to specify  wether or not the player should auto- rewind when it is done and start over.þNote: The speed is a fraction, so it gets faster as the number gets smaller": BoxH = 6
CASE 3: boxtext$ = "þWhat is there to say - Help is Help.  Choose which ever you need Help on!": BoxH = 2
CASE 31: boxtext$ = "þFor simple playing use the keys F1-F12         þTo change keys, use the numeric keypad left andright arrows (Right-One key up / Left-One down).þUse the Keypad Up and Down arrows to go up or  down an entire octave yet stay in the same key. þThere are also two different modes: Play mode  and Recording mode. To switch in between these  two modes press the Tab key."
boxtext$ = boxtext$ + " In play mode,  all the notes that you play are only played, but in recording mode your notes are added to the song.þFor playing songs using the player press enter.During play, you can press the SpaceBar to pauseL to loop the song, and Q to quit the song play.When the song is paused, you can press Enter to continue or keep on pressing the SpaceBar to go one note at a time."
lin = 3: Col = 15: BoxL = 50: BoxH = 16: title$ = "How to play in DWMUSIC"
CASE 32: boxtext$ = "To Save and Open you need to go to the file menu. Once    there, press O to get the FileOpen prompt where you can   type in the Drive, Path, and FileName. If you load an     *.msc (music) file, you only need to type in the name, notthe extension. If you open a file other than an *.msc fileit will still load but when you play it, there most likelywill be no sound."
boxtext$ = boxtext$ + "To save a file press S, then you will beasked wether or not you want to save - if so press Y, any-thing else for no. You can put your own extension on the  filename but if you do not, an *.msc extension will be    saved to it": BoxL = 60: BoxH = 11: Col = 10: lin = 6: title$ = "Saving and Opening"
CASE 33: boxtext$ = "Dwayne Demmer's Music PlayerVersion 1.2 (literally) 1995": BoxL = 30: Col = 25: lin = 10: BoxH = 2: title$ = "About"
END SELECT
GOSUB BoxDrawer
WHILE INKEY$ = "": WEND
PCOPY 1, 0
RETURN

ErrHan:
PCOPY 0, 1
lin = 8: Col = 20: BoxH = 5: BoxL = 40: fore = 10: back = 3
title$ = "Error Info": titleC = 0: textC = 15
IF ERR = 53 THEN boxtext$ = "        Sorry can not find it          You might have spelled the filename   wrong or not typed in an *.msc file.  If you know it exists, make sure the  path is right C:\MUSIC\BETHOVEN.MSC"
IF ERR = 64 THEN boxtext$ = "        Bad Dog!  I mean name          I thought you already knew the rules  for naming a file - OK here it goes   Your filename can't be longer than 8  characters or have <|>/*\or: in them"
IF ERR = 61 THEN boxtext$ = "        Dis Disk way too full"
IF ERR = 58 THEN boxtext$ = "        Kill de existing file"
GOSUB BoxDrawer
PRINT ERR
WHILE INKEY$ = "": WEND
PCOPY 1, 0
GOSUB StatusDisplay
RESUME NotePrompt

DEFSNG A-Z
SUB EditSong (SongPart$, SongPos%)
IF SongPos% > LEN(Song$) THEN
 Song$ = Song$ + STRING$(SongPos% - LEN(Song$) - 1, 128) + SongPart$
ELSE
 MID$(Song$, SongPos%) = SongPart$
END IF
END SUB

SUB MAKENOTE (note%, leng!)
IF note% < 0 OR note% > 107 THEN EXIT SUB
freq# = (2 ^ INT(note% / 12)) * 64
FOR n% = 1 TO note% MOD 12
freq# = 1.059463 * freq#
NEXT n%
IF freq# = 64 THEN freq# = 32767
SOUND INT(freq#), leng!
END SUB

