DEFINT A-Z
CONST BufferSize = 16384, LastOption = 2

CLS
LOCATE , , 1, 13, 14
PRINT "ROM Word Finder, created by Dwayne on 11-23-97"

DIM OptionPrompt$(0 TO 2)
newFile = 1

DO
 GOSUB GetSearchParams
 IF endProgram GOTO Endit

 SrchLen = LEN(srchword$)
 IF SrchLen < 1 THEN PRINT "Null word": GOTO Endit
 REDIM wordArray(0 TO SrchLen)
 basevalue = ASC(MID$(srchword$, 1, 1))
 wordArray(0) = basevalue
 ':PRINT wordArray(0);
 FOR temp = 2 TO SrchLen
  wordArray(temp - 1) = ASC(MID$(srchword$, temp, 1)) - basevalue
  ':PRINT wordArray(Temp - 1);
 NEXT temp
 ':SLEEP
 buffer$ = ""
 buffer$ = SPACE$(BufferSize)
 SkipSize = BufferSize - SrchLen
 IF SkipSize < 1 THEN PRINT "Oversize error": GOTO Endit

 FilErr = 0
 IF FREEFILE = 1 THEN OPEN FileName$ FOR BINARY AS #1
 IF FilErr THEN PRINT "Error trying to open file": GOTO Endit
 FileLen& = LOF(1)
 filepos& = 1

 PRINT
 PRINT "Searching for word in file:" + STR$(FileLen&) + " bytes"
 DO WHILE filepos& < FileLen& AND INKEY$ <> CHR$(27)
   outputrow = CSRLIN
   LOCATE 25, 1: PRINT "Bytes read:"; filepos&;
   GET 1, filepos&, buffer$
   LOCATE outputrow, 1
   GOSUB FindWordsInString
   filepos& = filepos& + SkipSize
 LOOP

 PRINT "Search complete, press Enter to do another"
 DO: k$ = INKEY$: LOOP UNTIL k$ > ""
 PRINT

LOOP WHILE k$ = CHR$(13)

Endit:
 CLOSE #1
PRINT "End program"

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
 ' CASE ELSE: TypePrompt OptionPrompt$(CurOption), key$, ScrnRow, ScrnCol, VisLen, RecLen, Curpos, Ofset
 ' END SELECT
 '
 'LOOP

 LINE INPUT "The file to search:", temp$
 IF temp$ > "" AND FileName$ = "" THEN
   FilErr = 0: temp = FREEFILE
   OPEN temp$ FOR INPUT AS temp: CLOSE temp
   IF FilErr THEN
     PRINT "Could not find the specified file"
     GOTO GetSearchParams
   ELSE
     CLOSE #1: FileName$ = temp$
   END IF
 END IF
 LINE INPUT "The word to find:", temp$
 IF endProgram GOTO Endit
 IF temp$ = "" THEN endProgram = 1: RETURN
 srchword$ = temp$
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

FindWordsInString:
 IF FileLen& - filepos& >= BufferSize THEN lastbyte = BufferSize ELSE lastbyte = FileLen& - filepos& + 1
 FOR curbyte = 1 TO lastbyte + 1 - SrchLen
  basevalue = ASC(MID$(buffer$, curbyte, 1))
  ':PRINT CHR$(basevalue);
  FOR subcurbyte = 1 TO SrchLen - 1
   IF ASC(MID$(buffer$, curbyte + subcurbyte, 1)) - basevalue <> wordArray(subcurbyte) GOTO MisMatch
  NEXT subcurbyte
  GOSUB OutputFind
MisMatch:
 NEXT curbyte
RETURN

OutputFind:
 totalfinds& = totalfinds& + 1
 IF curbyte - 10 >= 1 AND curbyte + SrchLen + 9 <= BufferSize THEN
  DEF SEG = &HB800
  screenpos = (CSRLIN - 1) * 160 + 44: bytepos = curbyte - 10
  FOR temp = 1 TO 22
   POKE screenpos, ASC(MID$(buffer$, bytepos, 1))
   screenpos = screenpos + 2: bytepos = bytepos + 1
  NEXT temp
 
  screenpos = (CSRLIN - 1) * 160 + 92: bytepos = curbyte - 10
  basedif = wordArray(0) - basevalue
  FOR temp = 1 TO 22
   POKE screenpos, ASC(MID$(buffer$, bytepos, 1)) + basedif
   screenpos = screenpos + 2: bytepos = bytepos + 1
  NEXT temp
 END IF
 PRINT totalfinds&; ":"; filepos& + curbyte - 1;
 LOCATE , 75: PRINT basedif
RETURN

ErrorHandler:
FilErr = ERR
RESUME NEXT

SUB TypePrompt (Text$, key$, ScrnRow, ScrnCol, VisLen, RecLen, Curp, Ofst)

Leng = LEN(Text$): IF Curp > Leng THEN Curp = Leng

SELECT CASE key$
CASE " " TO "~", "€" TO "ÿ": IF LEN(key$) + LEN(Text$) > RecLen THEN SOUND 1024, .1 ELSE Text$ = LEFT$(Text$, Curp) + key$ + RIGHT$(Text$, LEN(Text$) - Curp): Curp = Curp + 1: InChng = 2
CASE CHR$(8): IF Curp > 0 AND Leng THEN Text$ = LEFT$(Text$, Curp - 1) + RIGHT$(Text$, Leng - Curp): Curp = Curp - 1: InChng = 2
CASE CHR$(0) + "S": IF Leng AND Curp < Leng THEN Text$ = LEFT$(Text$, Curp) + RIGHT$(Text$, Leng - Curp - 1): InChng = 2
CASE CHR$(0) + "K": IF Curp THEN Curp = Curp - 1: InChng = 1
CASE CHR$(0) + "M": IF Curp < Leng THEN Curp = Curp + 1: InChng = 1
CASE CHR$(0) + "G": Curp = 0: InChng = 1
CASE CHR$(0) + "O": Curp = Leng: InChng = 1
END SELECT

IF InChng THEN
 Leng = LEN(Text$)
 IF Curp < Ofst THEN
  Ofst = Curp: InChng = 2
 ELSEIF Curp >= Ofst + VisLen THEN
  Ofst = Curp - VisLen + 1: InChng = 2
 END IF
 IF Ofst > Leng THEN Ofst = Leng: InChng = 2
 IF InChng > 1 THEN
  COLOR 15, 0
  LOCATE , , 0: LOCATE ScrnRow, ScrnCol: PRINT MID$(Text$, Ofst + 1, VisLen);
  IF Leng - Ofst < VisLen THEN PRINT SPACE$(VisLen - Leng + Ofst);
  OutChng = 1
 END IF
 LOCATE ScrnRow, ScrnCol + (Curp - Ofst): LOCATE , , 1
END IF

END SUB

