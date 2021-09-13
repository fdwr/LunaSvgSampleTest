'Text to Binary, by FDwR on 1998-06-01
DEFINT A-Z
DECLARE SUB AttemptOpen (File$, filehandle%, Mode)
DECLARE SUB StatusLine (Text$)

TYPE EmbedHeader
  EmbedLocation AS LONG    'location of embed in text
  Part AS INTEGER          'which part of a larger group this embed piece is
  Size AS LONG             'size of binary data after decoding
  DataLocation AS LONG     'start of the text data to be decoded
  EmbedName AS STRING * 78 'a simple name or description
  File AS STRING * 127     'the default filename to export this embed to
  Encoding AS STRING * 20  'how the binary was encoded into text
END TYPE
CONST FileBufferSize = 8192, ConvertBufferSize = FileBufferSize
DIM SHARED ErrorNum, ConvertRoutines(0 TO 143), Embed AS EmbedHeader
DIM SHARED FileBuffer AS STRING * FileBufferSize, EncodeBuffer AS STRING * ConvertBufferSize
FOR BytePos = 0 TO 143
  READ ConvertRoutines(BytePos)
NEXT BytePos


SCREEN 0: WIDTH 80, 25
LOCATE , , 0
VIEW PRINT 1 TO 24
IF LEN(COMMAND$) THEN File$ = COMMAND$: GOTO AttemptParameterOpen
GOTO UserInputs


UserInputs:
  CLOSE BinInputFile
  COLOR 7, 0: CLS
  PRINT "Binary to text converter, by FDwR on 6-7-98"
  PRINT "Used to convert binary data into 6bit/base64 or 7bit/base128 text."
  PRINT
  PRINT "Please select the binary file for input"
  PRINT "You can change to the desired directory by entering its path, then"
  PRINT "type in the binary file name or use '*' to get a directory listing."
  PRINT
  StatusLine "Waiting for input"

  DO
    GOSUB GetFileName
    IF File$ = "" THEN PRINT "End program": END
AttemptParameterOpen:
    AttemptOpen File$, BinInputFile, 0
    IF ErrorNum = 53 THEN
      PRINT "Could not find that file, maybe it is somewhere else"
    ELSEIF ErrorNum THEN
      PRINT "Error trying to open the filename given"
    END IF
  LOOP UNTIL BinInputFile
  BinFile$ = File$
  BinFilePos& = 1      'reset fileposition to front
  BinFileLeng& = LOF(BinInputFile)

  PRINT "Do you want to encode in 6bit or 7bit text, [6]/[7]?";
  AcceptedKeys$ = CHR$(13) + CHR$(27) + "67"
  DO: UserKey$ = UCASE$(INKEY$): LOOP UNTIL UserKey$ > "" AND INSTR(AcceptedKeys$, UserKey$)
  IF INSTR(AcceptedKeys$, UserKey$) AND 1 THEN
    EncodedBits = 6: ConvertMode = 0
  ELSEIF INSTR(AcceptedKeys$, UserKey$) = 2 THEN
    GOTO UserInputs
  ELSE EncodedBits = 7: ConvertMode = 2
  END IF
 
  Embed.File = SPACE$(LEN(Embed.File)): Embed.File = BinFile$
  FOR BytePos = LEN(BinFile$) TO 1 STEP -1
    IF MID$(BinFile$, BytePos, 1) = "\" THEN BinFile$ = RIGHT$(BinFile$, LEN(BinFile$) - BytePos): EXIT FOR
  NEXT BytePos
  Embed.Size = BinFileLeng&

UserInputsOutputFileStart:
  COLOR 7, 0: CLS
  PRINT "Select the text file to add the the binary file encoded text to"
  PRINT
  PRINT "You can change to the desired directory by entering its path, then"
  PRINT "type in the textfile name or use '*' to get a directory listing."
  PRINT
  StatusLine "Waiting for input"

UserInputsOutputFile:
  DO
    GOSUB GetFileName
    IF File$ = "" GOTO UserInputs
    StatusLine "Opening for appending..."
    filehandle = FREEFILE
    ON ERROR GOTO ErrHandler: ErrorNum = 0
    OPEN File$ FOR APPEND AS filehandle
    ON ERROR GOTO 0
    IF ErrorNum THEN PRINT "Could not add to file, it may be write protected"
  LOOP WHILE ErrorNum
 
  TextOutputFile = filehandle
  GOSUB StartEmbedEncode
  CLOSE TextOutputFile
  StatusLine "Waiting for keypress"
  IF BinEOF THEN
    PRINT "Embed encoded succesfully,"; BinFileLeng&; "bytes converted, press any key to continue"
    DO: LOOP UNTIL LEN(INKEY$)
    GOTO UserInputs
  ELSE
    PRINT "The embed was not completely encoded, press any key to continue"
    DO: LOOP UNTIL LEN(INKEY$)
    GOTO UserInputsOutputFileStart
  END IF
RETURN


'ChangeMenuChoice:
'  SWAP CurChoice, NewChoice
'  IF CurChoice < MenuChoiceBase THEN
'    MenuChoiceBase = CurChoice
'    GOSUB ShowMenuChoices
'  ELSEIF CurChoice > MenuChoiceBase + MenuHeight - 1 THEN
'    MenuChoiceBase = CurChoice - MenuHeight + 1
'    GOSUB ShowMenuChoices
'  ELSE
'    ShowChoice = NewChoice: GOSUB ShowMenuChoiceSkipCheck
'    ShowChoice = CurChoice: GOSUB ShowMenuChoiceSkipCheck
'  END IF
'RETURN


'ShowMenuChoice: 'eventually I want this to be a sub
'  IF ShowChoice < MenuChoiceBase OR ShowChoice > MenuChoiceBase + MenuHeight - 1 THEN RETURN
'ShowMenuChoiceSkipCheck:
'  LOCATE ShowChoice - MenuChoiceBase + MenuTop, MenuLeft
'  IF ShowChoice = CurChoice THEN COLOR 15, 7 ELSE COLOR 7, 0
'  PRINT LEFT$(MenuChoices(ShowChoice), MenuWidth);
'  IF LEN(MenuChoices(ShowChoice)) < MenuWidth THEN PRINT SPACE$(MenuWidth - LEN(MenuChoices(ShowChoice)));
'RETURN


'ShowMenuChoices:
'  FOR ShowChoice = MenuChoiceBase TO MenuChoiceBase + MenuHeight - 1
'    GOSUB ShowMenuChoiceSkipCheck
'  NEXT ShowChoice
'RETURN


StartEmbedEncode:
'Initiates and coordinates retrieving of embeds
'Assumes that the input and output files are already open
  GOSUB PrintHeader
 
  BinFilePos& = 1
  BinEOF = 0
  LinesPerCall = 100
  LineByteLimit = 64
  BytesToInput = (ConvertBufferSize * CLNG(EncodedBits)) \ 8
  GOSUB DecodeAndInputBin
  DO
    GOSUB EncodeText
    UserKey$ = INKEY$
    IF UserKey$ = CHR$(27) THEN
      PRINT "Cancel this encoding, [N]o/[Y]es?"
      StatusLine "Waiting for user input"
      AcceptedKeys$ = CHR$(27) + CHR$(13) + "YN"
      DO: UserKey$ = UCASE$(INKEY$): LOOP UNTIL UserKey$ > "" AND INSTR(AcceptedKeys$, UserKey$)
      IF INSTR(AcceptedKeys$, UserKey$) AND 1 THEN EXIT DO
      PRINT "Encoding continued"
    END IF
    StatusLine "Encoding," + STR$(BinFilePos&)
  LOOP UNTIL BinEOF

  GOSUB PrintTrail
RETURN


EncodeText:
  LinesThisCall = LinesPerCall
  DO
    IF BytesToOutput& - BufferPos > LineByteLimit THEN
      LineText$ = MID$(EncodeBuffer, BufferPos + 1, LineByteLimit)
      PRINT #TextOutputFile, LineText$
      BufferPos = BufferPos + LineByteLimit
    ELSE
      LineText$ = MID$(EncodeBuffer, BufferPos + 1, BytesToOutput& - BufferPos)
      PRINT #TextOutputFile, LineText$
      BufferPos = BufferPos + LineByteLimit
      BinEOF = 1: EXIT DO
    END IF
    IF BufferPos >= ConvertBufferSize THEN GOSUB DecodeAndInputBin
    LinesThisCall = LinesThisCall - 1
  LOOP WHILE LinesThisCall
RETURN


DecodeAndInputBin:
  FileBuffer = INPUT$(BytesToInput, BinInputFile)
  DEF SEG = VARSEG(ConvertRoutines(0))
  CALL ABSOLUTE(BYVAL ConvertBufferSize, BYVAL VARSEG(EncodeBuffer), BYVAL VARPTR(EncodeBuffer), BYVAL VARSEG(FileBuffer), BYVAL VARPTR(FileBuffer), BYVAL ConvertMode, VARPTR(ConvertRoutines(0)))
 
  BytesToOutput& = ((BinFileLeng& - BinFilePos& + 1) * 8& + EncodedBits - 1) \ EncodedBits
  BinFilePos& = BinFilePos& + BytesToInput
  BufferPos = 0
RETURN


RefreshFileBuffer:
  EncodeBuffer = INPUT$(BytesToInput, BinInputFile)
RETURN


PrintHeader:
  PRINT #TextOutputFile, "==EmbedBegin=="
  PRINT #TextOutputFile, "Name: "; LCASE$(RTRIM$(Embed.File)); ", "; DATE$
  PRINT #TextOutputFile, "File: "; BinFile$
  PRINT #TextOutputFile, "Encoding: ";
  IF EncodedBits = 6 THEN PRINT #TextOutputFile, "shifted,6bit,base64" ELSE PRINT #TextOutputFile, "shifted,7bit,base128"
  PRINT #TextOutputFile, "Data:"; STR$(Embed.Size)
RETURN


PrintTrail:
  PRINT #TextOutputFile, "==EmbedEnd=="
RETURN


GetFileName:
  LINE INPUT "filename:", File$
  IF File$ = "" THEN RETURN
  IF INSTR(File$, "*") OR INSTR(File$, "?") THEN
    SHELL "dir " + File$
    GOTO GetFileName
  END IF
  ON ERROR GOTO ErrHandler: ErrorNum = 0
  CHDIR File$
  ON ERROR GOTO 0
  IF ErrorNum = 0 GOTO GetFileName
RETURN


ErrHandler:
  ErrorNum = ERR
RESUME NEXT


'Assembly code for shifting encoding
'BINTEXT.COM
DATA 1566,-30379,-29723,2654,-1151,4,6771,30405,-15348,4222,20107,-12012,12003
DATA -24693,46,-5695,-31485,29897,-1021,-11265,1885,-13793,12,54,120,176,234
DATA 16570,26176,26285,-15479,-16026,1248,-5951,-16382,744,-12279,26283,-5951
DATA -16116,744,-5952,2306,-21552,26285,-23537,3288,-5951,-16382,744,-12279
DATA 26283,-5951,-16116,744,-5952,2306,-21552,30025,-15422,-21146,-8000,-16126
DATA 736,-16026,1256,26283,-5951,-16372,736,-16026,4832,-16211,736,-5951,26114
DATA -16191,-21752,-16026,3296,-16211,736,-5951,26114,-16191,-21756,30025
DATA -15415,-32582,26240,26285,-15479,-16026,736,-5935,-5936,-12279,26283
DATA -5951,-12018,-12056,2536,-21552,-21146,26190,-23537,1752,-5935,-5936
DATA -12279,26283,-5951,-12273,2536,-21552,30025,-15414,-21146,-7984,-7983
DATA -16026,744,26283,-5951,-12274,26336,-7999,-21231,-7984,-5935,-16026,3264
DATA 26283,-7999,-21242,-7984,-5935,-16026,2752,26283,-5951,-22000,30025
DATA -15413

'mode=0 Input
'mode=1 Output
SUB AttemptOpen (File$, filehandle, Mode)
  ON ERROR GOTO ErrHandler: ErrorNum = 0
  filehandle = FREEFILE
  OPEN File$ FOR INPUT AS filehandle: CLOSE filehandle
  ON ERROR GOTO 0
  IF ErrorNum THEN
    IF Mode = 0 OR (Mode AND ErrorNum <> 53) THEN filehandle = 0: EXIT SUB
  END IF
  OPEN File$ FOR BINARY AS filehandle
END SUB

SUB StatusLine (Text$)
  CsrRow = CSRLIN: CsrCol = POS(0)
  LOCATE 25, 1: PRINT LEFT$(Text$, 79); TAB(80);
  LOCATE CsrRow, CsrCol
END SUB

