'12-23-97 7609
DEFINT A-Z
CONST BufferSize = 16384, LastOption = 2

CLS
LOCATE , , , 11, 12
PRINT "ROM Pattern Finder, created by Dwayne on 11-23-97"
PRINT "Used to locate a string of tiles in a game level grid"
PRINT

DIM OptionPrompt$(0 TO 2)
newFile = 1

DO
 GOSUB GetSearchParams
 IF EndProgram GOTO Endit

 SrchLen = LEN(srchword$)
 IF SrchLen < 1 THEN PRINT "Null word": GOTO Endit
 REDIM wordArray(1 TO SrchLen)
 REDIM wordTable(0 TO 30)
 FOR subcount = 1 TO SrchLen
  temp = ASC(UCASE$(MID$(srchword$, subcount, 1)))
  IF temp >= 65 AND temp <= 90 THEN wordArray(subcount) = temp - 64 ELSE wordArray(subcount) = 0
  PRINT wordArray(subcount);
 NEXT subcount
 PRINT
 buffer$ = ""
 buffer$ = SPACE$(BufferSize)
 SkipSize = BufferSize - SrchLen
 IF SkipSize < 1 THEN PRINT "Oversize error": GOTO Endit

 FilErr = 0
 OPEN FileName$ FOR BINARY AS 1
 IF FilErr THEN PRINT "Error trying to open file": GOTO Endit
 fileLen& = LOF(1)
 IF filepos& < 1 THEN filepos& = 1

 PRINT
 PRINT "Searching for word in file:" + STR$(fileLen&) + " bytes"
 DO WHILE filepos& < fileLen& AND INKEY$ <> CHR$(27)
   outputrow = CSRLIN
   LOCATE 25, 1: PRINT "Bytes read:"; filepos&;
   GET 1, filepos&, buffer$
   LOCATE outputrow, 1
   GOSUB FindWordsInString
   filepos& = filepos& + SkipSize
 LOOP

 CLOSE 1

 PRINT "Search complete"
 PRINT

LOOP UNTIL EndProgram

Endit:
PRINT "End program"
PRINT

END

GetSearchParams:
 'FOR nextOption = 0 TO LastOption
 ' GOSUB PrintOption
 'NEXT nextOption
 'NeedOptionInfo = 1
 'CurOption = 0
 '
 'DO
 ' IF NeedOptionInfo THEN GOSUB GetOptionInfo: NeedOptionInfo = 0
 '
 ' key$ = INKEY$
 ' SELECT CASE key$
 ' CASE CHR$(0) + "H": IF CurOption <= 0 THEN nextOption = LastOption ELSE nextOption = CurOption - 1
 '  GOSUB ChngOption
 ' CASE CHR$(0) + "P": IF CurOption >= LastOption THEN nextOption = 0 ELSE nextOption = CurOption + 1
 '  GOSUB ChngOption
 ' CASE CHR$(27): END
 ' CASE ""
 ' CASE ELSE: TypePrompt OptionPrompt$(CurOption), key$, ScrnRow, ScrnCol, VisLen, RecLen, CurPos, Ofset
 ' END SELECT
 ' hank you so much
 ' abcdefgheigejhka
 'LOOP

 DO
   LINE INPUT "The file to search:", temp$
   IF temp$ = "" THEN EndProgram = 1: RETURN
   IF temp$ = "=" THEN temp$ = "\dw\emu\zelda.smc"
   IF INSTR(temp$, "*") THEN SHELL "DIR " + temp$ ELSE EXIT DO
 LOOP
 ON ERROR GOTO ErrorHandler
 FilErr = 0: OPEN temp$ FOR INPUT AS 1: fileLen& = LOF(1): CLOSE 1
 ON ERROR GOTO 0
 IF FilErr THEN
   PRINT "Could not find the specified file"
   GOTO GetSearchParams
 ELSE
   FileName$ = temp$
 END IF
 LINE INPUT "The word to find:", temp$
 srchword$ = temp$
 IF EndProgram GOTO Endit
 DO
  LINE INPUT "Number of bits:", temp$
  IF temp$ = "" THEN EndProgram = 1: RETURN
  IF INSTR("1248", temp$) AND LEN(temp$) = 1 THEN EXIT DO ELSE PRINT "Valid bit sizes are 1,2,4,8 bits"
 LOOP
 bitsize = VAL(temp$)
 PRINT "Starting byte 1 -"; STR$(fileLen&); ":";
 LINE INPUT temp$
 IF temp$ = "" THEN EndProgram = 1: RETURN
 filepos& = VAL(temp$)
RETURN

ChngOption:
 SWAP nextOption, CurOption
 GOSUB PrintOption
 nextOption = CurOption
 GOSUB PrintOption
 NeedOptionInfo = 1
RETURN

PrintOption:
 LOCATE 3 + nextOption, 1
 IF nextOption = CurOption THEN COLOR 15 ELSE COLOR 7
 SELECT CASE nextOption
 CASE 0: PRINT "The file to search: "; OptionPrompt$(0);
 CASE 1: PRINT "The word to find: "; OptionPrompt$(1);
 CASE 2: PRINT "This option not available yet: "; OptionPrompt$(2);
 END SELECT
RETURN

GetOptionInfo:
 ScrnRow = CurOption + 3
 VisLen = 60
 SELECT CASE CurOption
 CASE 0: ScrnCol = 21: RecLen = 128
 CASE 1: ScrnCol = 19: RecLen = 20
 CASE 2: ScrnCol = 32: RecLen = 0
 CASE ELSE: RETURN
 END SELECT
 Curp = LEN(OptionPrompt$(CurOption))
 LOCATE ScrnRow, ScrnCol + Curp
RETURN

'Many optimizations to be made! For one, the Boyer-Moore string search method
'instead of this slow (stupid but effective) brute force method. The second
'one which will increase it the most will be a little 32bit assembly. With far
'fewer memory accesses by using the registers and not rereading the same data
'over again, and using simpler instructions like SHR (instead of super slow
'multiplication), I estimate that with both of those optimizations, the speed
'increase might be about 20 times or so!
FindWordsInString:
 IF fileLen& - filepos& >= BufferSize THEN lastbyte = BufferSize ELSE lastbyte = fileLen& - filepos& + 1
 shiftjump = 2 ^ bitsize
 mask = shiftjump - 1
 maxshiftcount = (8 \ bitsize) - 1
 maindivshift = 1
 mainshiftcount = 0
 mainbytepos = 1
 lastbyte = (lastbyte * 8& \ bitsize) - SrchLen + 1
 FOR maincount = 1 TO lastbyte
  'shiftcount = mainshiftcount
  'divshift = maindivshift
  bytepos = mainbytepos
  lastindex = 0
  indexes = 0
  'PRINT LEFT$(STR$(ASC(MID$(buffer$, bytepos, 1)) \ divshift AND mask) + "   ", 4);  ';
  FOR subcount = 1 TO SrchLen
   unit = ASC(MID$(buffer$, bytepos, 1))' \ divshift
   'unit = unit AND mask
   'IF shiftcount >= maxshiftcount THEN divshift = 1: shiftcount = 0: bytepos = bytepos + 1 ELSE divshift = divshift * shiftjump: shiftcount = shiftcount + 1
      bytepos = bytepos + 1
   index = wordArray(subcount)
   IF index THEN
    IF index > lastindex THEN
     FOR check = 1 TO indexes
      IF wordTable(check) = unit GOTO MisMatch
     NEXT check
     wordTable(index) = unit
     lastindex = index
     indexes = indexes + 1
    ELSEIF unit <> wordTable(index) THEN GOTO MisMatch
    END IF
   END IF
  NEXT subcount
  GOSUB OutputFind
MisMatch:
  'IF mainshiftcount >= maxshiftcount THEN maindivshift = 1: mainshiftcount = 0: mainbytepos = mainbytepos + 1 ELSE maindivshift = maindivshift * shiftjump: mainshiftcount = mainshiftcount + 1
     mainbytepos = mainbytepos + 1
 NEXT maincount
RETURN

OutputFind:
 totalfinds& = totalfinds& + 1
 IF mainbytepos + SrchLen + 20 <= BufferSize THEN
  DEF SEG = &HB800
  screenpos = (CSRLIN - 1) * 160 + 44: bytepos = mainbytepos
  shiftcount = mainshiftcount
  divshift = maindivshift
  bytepos = mainbytepos
  FOR subcount = 1 TO 22
   unit = ASC(MID$(buffer$, bytepos, 1)) \ divshift AND mask
   IF shiftcount >= maxshiftcount THEN divshift = 1: shiftcount = 0: bytepos = bytepos + 1 ELSE divshift = divshift * shiftjump: shiftcount = shiftcount + 1
   POKE screenpos, unit
   screenpos = screenpos + 2
  NEXT subcount
 
  screenpos = (CSRLIN - 1) * 160 + 92: bytepos = mainbytepos
  shiftcount = mainshiftcount
  divshift = maindivshift
  bytepos = mainbytepos
  FOR subcount = 1 TO 22
   unit = ASC(MID$(buffer$, bytepos, 1)) \ divshift AND mask
   IF shiftcount >= maxshiftcount THEN divshift = 1: shiftcount = 0: bytepos = bytepos + 1 ELSE divshift = divshift * shiftjump: shiftcount = shiftcount + 1
   POKE screenpos, unit
   screenpos = screenpos + 2
  NEXT subcount
 END IF
 PRINT totalfinds&; ":"; filepos& + mainbytepos - 1
RETURN

ErrorHandler:
FilErr = ERR
RESUME NEXT

SUB TypePrompt (Text$, key$, ScrnRow, ScrnCol, VisLen, RecLen, CurPos, Ofst)

Leng = LEN(Text$): IF CurPos > Leng THEN CurPos = Leng

SELECT CASE key$
CASE " " TO "~", "€" TO "ÿ": IF LEN(key$) + LEN(Text$) > RecLen THEN SOUND 1024, .1 ELSE Text$ = LEFT$(Text$, CurPos) + key$ + RIGHT$(Text$, LEN(Text$) - CurPos): CurPos = CurPos + 1: Review = 2
CASE CHR$(8): IF CurPos > 0 AND Leng THEN Text$ = LEFT$(Text$, CurPos - 1) + RIGHT$(Text$, Leng - CurPos): CurPos = CurPos - 1: Review = 2
CASE CHR$(0) + "S": IF Leng AND CurPos < Leng THEN Text$ = LEFT$(Text$, CurPos) + RIGHT$(Text$, Leng - CurPos - 1): Review = 2
CASE CHR$(0) + "K": IF CurPos THEN CurPos = CurPos - 1: Review = 1
CASE CHR$(0) + "M": IF CurPos < Leng THEN CurPos = CurPos + 1: Review = 1
CASE CHR$(0) + "G": CurPos = 0: Review = 1
CASE CHR$(0) + "O": CurPos = Leng: Review = 1
END SELECT

IF Review THEN
 Leng = LEN(Text$)
 IF CurPos < Ofst THEN
  Ofst = CurPos: Review = 2
 ELSEIF CurPos >= Ofst + VisLen THEN
  Ofst = CurPos - VisLen + 1: Review = 2
 END IF
 IF Ofst > Leng THEN Ofst = Leng: Review = 2
 IF Review > 1 THEN
  COLOR 15, 0
  LOCATE , , 0: LOCATE ScrnRow, ScrnCol: PRINT MID$(Text$, Ofst + 1, VisLen);
  IF Leng - Ofst < VisLen THEN PRINT SPACE$(VisLen - Leng + Ofst);
 END IF
 LOCATE ScrnRow, ScrnCol + (CurPos - Ofst): LOCATE , , 1
END IF

END SUB

