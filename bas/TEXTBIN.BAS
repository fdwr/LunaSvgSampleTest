'Text to Binary, started on 1998-06-01
'
'Retrieves text embeds from email letters back into binary files
'Supports superfast decoding for 6bit and 7bit text
'This is the partner prog to BinText which does just the opposite
'
'Completely homegrown and all natural, the code is hand written by me
'Please inlcude my name if you want to use the assembly
'Any other sub/function does not need credit given to me
'
'Enjoy :-) Dwayne Robinson
'Send questions to FDwR@Juno.com

DEFINT A-Z
DECLARE SUB AttemptOpen (File$, filehandle%, mode)
DECLARE SUB StatusLine (Text$)

TYPE EmbedHeader
  HeaderLocation AS LONG    'location of embed in text
  Part AS INTEGER          'which part of a larger group this embed piece is
  Size AS LONG             'size of binary data after decoding
  DataLocation AS LONG     'start of the text data to be decoded
  EmbedName AS STRING * 78 'a simple name or description
  File AS STRING * 127     'the default filename to export this embed to
  Encoding AS STRING * 20  'how the binary was encoded into text
END TYPE
CONST FileBufferSize = 8192, ConvertBufferSize = FileBufferSize, EmbedHeader = "==Embed"
CONST MaxEmbedMenuChoices = 30, LineByteLimit = 255
DIM SHARED ErrorNum, ConvertRoutines(0 TO 143), FileBufferBase&
DIM SHARED FileBuffer AS STRING * FileBufferSize, DecodeBuffer AS STRING * ConvertBufferSize
FOR BytePos = 0 TO 143
  READ ConvertRoutines(BytePos)
NEXT BytePos


SCREEN 0
LOCATE , , 0
VIEW PRINT 1 TO 24

File$ = "c:\juno\user0000\fold0000.frm"
AttemptOpen File$, TextInputFile, 0
IF TextInputFile GOTO UserInputsMenuChoice
File$ = "c:\progra~1\juno\user0000\fold0000.frm"
AttemptOpen File$, TextInputFile, 0
IF TextInputFile GOTO SuccessfullOpen

GOTO UserInputs


UserInputs:
  COLOR 7, 0: CLS
  PRINT "Text to binary converter, by FDwR on 6-1-98"
  PRINT "Used to convert 6bit/base64 or 7bit/base128 text back to their binary."
  PRINT
  PRINT "Please select the text file for input"
  PRINT "You can change to the desired directory by entering its path, then"
  PRINT "type in the textfile name or use '*' to get a directory listing."
  PRINT
  StatusLine "Waiting for input"

  DO
    GOSUB GetFileName
    IF File$ = "" THEN PRINT "End program": END
    AttemptOpen File$, TextInputFile, 0
    IF ErrorNum = 53 THEN
      PRINT "Could not find that file, maybe it is somewhere else"
    ELSEIF ErrorNum THEN
      PRINT "Error trying to open the filename given"
    END IF
  LOOP UNTIL TextInputFile

SuccessfullOpen:
  TextFile$ = File$
  FileBufferBase& = 1   'reset filebuffer to first
  TextFilePos& = 1      'reset fileposition to front
  TextFileLeng& = LOF(TextInputFile)
  GOSUB RefreshFileBuffer  'load chunk of file into a temp mem buffer

  REDIM EmbedsFound(0 TO MaxEmbedMenuChoices - 1) AS EmbedHeader
  REDIM MenuChoices(0 TO MaxEmbedMenuChoices - 1) AS STRING
  MenuTop = 5: MenuLeft = 2: MenuWidth = 78: MenuHeight = 15
  TotalChoices = 0: CurChoice = 0: MenuChoiceBase = 0
  FindEmbeds = 1: InEmbed = 0: TextEOF = 0: SearchString$ = "==Embed"
  CurEmbed = 0: MaxEmbed = MaxEmbedMenuChoices - 1: LinesPerCall = 60
 
UserInputsMenuChoice:
  COLOR 7, 0: CLS
  PRINT "Select an embed to retrieve from the list below"
  PRINT "You can cancel and select a different file by pressing Esc or,"
  PRINT "Use the arrow keys and press Enter to make your choice"

  GOSUB ShowMenuChoices
  GOSUB ShowEmbedHeaderStats
 
  DO
    UserKey$ = INKEY$
    IF LEN(UserKey$) THEN
      SELECT CASE UserKey$
      CASE CHR$(0) + "H": IF CurChoice > 0 THEN NewChoice = CurChoice - 1: GOSUB ChangeMenuChoice
      CASE CHR$(0) + "P": IF CurChoice < TotalChoices - 1 THEN NewChoice = CurChoice + 1: GOSUB ChangeMenuChoice
      CASE CHR$(0) + "I"
        IF CurChoice > 0 THEN
          NewChoice = CurChoice - MenuHeight
          IF NewChoice < 0 THEN NewChoice = 0
          GOSUB ChangeMenuChoice
        END IF
      CASE CHR$(0) + "Q"
        IF CurChoice < TotalChoices - 1 THEN
          NewChoice = CurChoice + MenuHeight
          IF NewChoice >= TotalChoices THEN NewChoice = TotalChoices - 1
          GOSUB ChangeMenuChoice
        END IF
      CASE CHR$(13)
        IF TotalChoices THEN EXIT DO
      CASE CHR$(27)
        CLOSE TextInputFile
        GOTO UserInputs
      RETURN
      END SELECT
    END IF
    IF FindEmbeds THEN
      GOSUB CheckNextTextLine
      IF AnotherEmbed THEN
        TotalChoices = TotalChoices + 1
        MenuChoices(CurEmbed) = EmbedsFound(CurEmbed).EmbedName
        ShowChoice = CurEmbed: GOSUB ShowMenuChoice
        IF CurEmbed = CurChoice THEN GOSUB ShowEmbedHeaderStats
        CurEmbed = CurEmbed + 1: IF CurEmbed > MaxEmbed THEN TextEOF = 1'FindEmbeds = 0: GOSUB EmbedListCompleted
        AnotherEmbed = 0
      END IF
      IF TextEOF THEN FindEmbeds = 0: StatusLine "Search of text complete," + STR$(TotalChoices) + " embeds added to menu list"
    END IF
  LOOP

  IF EmbedsFound(CurChoice).Encoding = "shifted,6bit,base64 " THEN
    EncodedBits = 6: ConvertMode = 1
  ELSEIF EmbedsFound(CurChoice).Encoding = "shifted,7bit,base128" THEN
    EncodedBits = 7: ConvertMode = 3
  ELSE
    COLOR 7, 0: CLS
    PRINT "This encoding format is not familiar: "; EmbedsFound(CurChoice).Encoding
    PRINT "TextBin only supports shifted 6bit/base64 or 7bit/base128 encoding"
    DO: LOOP UNTIL LEN(INKEY$)
    GOTO UserInputsMenuChoice
  END IF
  FOR BytePos = 1 TO 127
    Char = ASC(MID$(EmbedsFound(CurChoice).File, BytePos, 1))
    IF Char = 0 OR Char = 32 THEN EXIT FOR
  NEXT BytePos
  File$ = LEFT$(EmbedsFound(CurChoice).File, BytePos - 1)
  IF LEN(File$) GOTO OpenOutputFile

UserInputsOutputFileStart:
  COLOR 7, 0: CLS
  PRINT "Choose a name for the binary file to output"
  PRINT "You can use the default name in the embed or use another"
  PRINT
  PRINT "You can change to the desired directories by entering their path, then"
  PRINT "Type in the textfile name or use '*' to get a directory listing."
  PRINT
  StatusLine "Waiting for input"

UserInputsOutputFile:
  DO
    GOSUB GetFileName
    IF File$ = "" GOTO UserInputsMenuChoice
OpenOutputFile:
    ON ERROR GOTO ErrHandler: ErrorNum = 0
    filehandle = FREEFILE
    OPEN File$ FOR INPUT AS filehandle: CLOSE filehandle
    ON ERROR GOTO 0
    IF ErrorNum = 0 THEN
      PRINT "That file already exists, do you want to overwrite it, [N]o/[Y]es?"
      AcceptedKeys$ = CHR$(27) + CHR$(13) + "NY"
      DO: UserKey$ = UCASE$(INKEY$): LOOP UNTIL UserKey$ > "" AND INSTR(AcceptedKeys$, UserKey$)
      IF INSTR(AcceptedKeys$, UserKey$) AND 1 GOTO UserInputsOutputFile
    ELSEIF ErrorNum = 53 THEN ErrorNum = 0
    END IF
  LOOP WHILE ErrorNum
  StatusLine "Opening for output..."
  BinOutputFile = filehandle
  ON ERROR GOTO ErrHandler: ErrorNum = 0
  OPEN File$ FOR OUTPUT AS BinOutputFile
  ON ERROR GOTO 0
  IF ErrorNum THEN PRINT "Could not overwrite file, it may be write protected": GOTO UserInputsOutputFile
  GOSUB StartEmbedRetrieve
  CLOSE BinOutputFile
  IF EmbedsFound(CurChoice).Size <> BytesOutput& OR TextEOF = 0 THEN
    COLOR 7, 0: CLS
    PRINT "Warning, the number of bytes output and the stated size of the embed data"
    PRINT "is not the same; be careful about using the output file for anything."
    DO: LOOP UNTIL LEN(INKEY$)
    GOTO UserInputsOutputFile
  ELSE
    PRINT "Embed retrieved succesfully, press any key to continue"
    DO: LOOP UNTIL LEN(INKEY$)
    GOTO UserInputsMenuChoice
  END IF
RETURN


ChangeMenuChoice:
  SWAP CurChoice, NewChoice
  IF CurChoice < MenuChoiceBase THEN
    MenuChoiceBase = CurChoice
    GOSUB ShowMenuChoices
  ELSEIF CurChoice > MenuChoiceBase + MenuHeight - 1 THEN
    MenuChoiceBase = CurChoice - MenuHeight + 1
    GOSUB ShowMenuChoices
  ELSE
    ShowChoice = NewChoice: GOSUB ShowMenuChoiceSkipCheck
    ShowChoice = CurChoice: GOSUB ShowMenuChoiceSkipCheck
  END IF
  GOSUB ShowEmbedHeaderStats
RETURN


ShowMenuChoice: 'eventually I want this to be a sub
  IF ShowChoice < MenuChoiceBase OR ShowChoice > MenuChoiceBase + MenuHeight - 1 THEN RETURN
ShowMenuChoiceSkipCheck:
  LOCATE ShowChoice - MenuChoiceBase + MenuTop, MenuLeft
  IF ShowChoice = CurChoice THEN COLOR 15, 7 ELSE COLOR 7, 0
  PRINT LEFT$(MenuChoices(ShowChoice), MenuWidth);
  IF LEN(MenuChoices(ShowChoice)) < MenuWidth THEN PRINT SPACE$(MenuWidth - LEN(MenuChoices(ShowChoice)));
RETURN


ShowMenuChoices:
  FOR ShowChoice = MenuChoiceBase TO MenuChoiceBase + MenuHeight - 1
    GOSUB ShowMenuChoiceSkipCheck
  NEXT ShowChoice
RETURN


ShowEmbedHeaderStats: 'always prints to a fixed location on screen
  COLOR 7, 0: LOCATE 21, 1
  PRINT "Filename:"; LEFT$(EmbedsFound(CurChoice).File, 71)
  PRINT "Header location:"; EmbedsFound(CurChoice).HeaderLocation; TAB(40);
  PRINT "Start of data:"; EmbedsFound(CurChoice).DataLocation; TAB(80);
  PRINT "Encoding type:"; EmbedsFound(CurChoice).Encoding; TAB(40);
  PRINT "Size of binary data:"; EmbedsFound(CurChoice).Size; TAB(80);
RETURN


CheckNextTextLine:
  LinesThisCall = LinesPerCall
  DO
    IF InEmbed = 1 THEN
      GOSUB GetNextTextLine
      NextPos = INSTR(LineText$, ":")
      IF NextPos THEN
        LineTextKey$ = LCASE$(MID$(LineText$, 1, NextPos - 1))
        LineTextVars$ = LTRIM$(MID$(LineText$, NextPos + 1))
      ELSE
        LineTextKey$ = LineText$
      END IF
      SELECT CASE LineTextKey$
      CASE "==EmbedEnd==": AnotherEmbed = 1: InEmbed = 0: EXIT DO
      CASE "name": EmbedsFound(CurEmbed).EmbedName = LineTextVars$
      CASE "file": EmbedsFound(CurEmbed).File = LineTextVars$
      CASE "encoding": EmbedsFound(CurEmbed).Encoding = LineTextVars$ + " "
      CASE "data"
        InEmbed = 2
        EmbedsFound(CurEmbed).Size = VAL(LineTextVars$)
        EmbedsFound(CurEmbed).DataLocation = TextFilePos&
      END SELECT
      LinesThisCall = LinesThisCall - 1
    ELSE
      BytesToInput = 30000
      GOSUB FindStringInTextFile
      IF NextPos THEN
        GOSUB GetNextTextLine
        IF LineText$ = "==EmbedEnd==" THEN
          IF InEmbed THEN AnotherEmbed = 1: InEmbed = 0: EXIT DO
        ELSEIF LineText$ = "==EmbedBegin==" THEN
          InEmbed = 1: EmbedsFound(CurEmbed).HeaderLocation = TextFilePos&
        END IF
      END IF
      LinesThisCall = LinesThisCall - 3
    END IF
    StatusLine "Searching for embeds" + STR$(TextFilePos&)
    IF TextEOF THEN IF InEmbed THEN AnotherEmbed = 1: RETURN ELSE RETURN
  LOOP WHILE LinesThisCall > 0
RETURN
  

GetNextTextLine:
'Returns a line to caller from the text buffer and automatically increments
'the pointer to the next line in one call. The end of line chars are stripped
'off from the returned string.

'Checks if requested line is in buffer.
'If not, load in data from buffer, if it is already in do nothing.
'Find end of line, either terminated by a eol (CR/LF) or by the length of the
'buffer itself.
  IF TextFilePos& < FileBufferBase& OR TextFilePos& + LineByteLimit > FileBufferBase& + FileBufferSize THEN
    FileBufferBase& = TextFilePos&
    GOSUB RefreshFileBuffer
  END IF
  CurPos = TextFilePos& - FileBufferBase& + 1
  NextPos = INSTR(CurPos, FileBuffer, CHR$(13))
  IF NextPos = 0 THEN
    LineLength = FileBufferSize - CurPos + 1
  ELSE
    LineLength = NextPos - CurPos
    TextFilePos& = TextFilePos& + (INSTR(NextPos, FileBuffer, CHR$(10)) - NextPos + 1)
    'Originally I just had the above statement say that TextFilePos& should
    'be moved forward two bytes to skip the silly CR/LF combo, but then I
    'found out that some stupid email programs (including my very own Juno)
    'were adding an extra CR for whatever reason. Who knows, maybe it is some
    'type of bug. Whatever the reason I had to make compensation for it so
    'the next line started after the LF, whether it was just paired like
    'CR/LF or CR/CR/LF. Personally, I feel the whole CR/LF deal is silly.
    'There should simply be one separater character.
  END IF
  IF LineLength > LineByteLimit THEN LineLength = LineByteLimit
  TextFilePos& = TextFilePos& + LineLength
  LineText$ = MID$(FileBuffer, CurPos, LineLength)
  IF TextFilePos& > TextFileLeng& THEN TextEOF = 1
RETURN


FindStringInTextFile:
  IF FileBufferSize = 0 THEN RETURN
  MaxFilePos& = TextFilePos& + BytesToInput
  IF TextFilePos& >= FileBufferBase& AND TextFilePos& + LEN(SearchString$) <= FileBufferBase& + FileBufferSize THEN
    CurPos = TextFilePos& - FileBufferBase& + 1
    GOTO SkipFindStringRebuffer
  END IF
  DO
    CurPos = 1
    FileBufferBase& = TextFilePos&
    GOSUB RefreshFileBuffer
SkipFindStringRebuffer:
    NextPos = INSTR(CurPos, FileBuffer, SearchString$)
    IF NextPos THEN
      TextFilePos& = TextFilePos& + NextPos - CurPos
      IF TextFilePos& < MaxFilePos& THEN RETURN ELSE TextFilePos& = MaxFilePos&: EXIT DO
    END IF
    NextPos = FileBufferSize - CurPos - LEN(SearchString$) + 2
    TextFilePos& = TextFilePos& + NextPos
    IF TextFilePos& > TextFileLeng& THEN TextEOF = 1: EXIT DO
    BytesToInput = BytesToInput - NextPos
  LOOP WHILE BytesToInput > 0
  NextPos = 0
RETURN


StartEmbedRetrieve:
'Initiates and coordinates retrieving of embeds
'Assumes that the input and output files are already open
'Note that this routine does prepare the variables but does actually do any
'decoding at all
  IF EncodedBits = 6 THEN LowBase = 64: HighBase = 127 ELSE LowBase = 128: HighBase = 255
  TextFilePos& = EmbedsFound(CurChoice).DataLocation
  TextEOF = 0
  LinesPerCall = 60
  BytesOutput& = 0
  BytesToOutput = 0
  FullBufferOutput = ConvertBufferSize * CLNG(EncodedBits) \ 8
  DO
    GOSUB DecodeText
    UserKey$ = INKEY$
    IF UserKey$ = CHR$(27) THEN
      PRINT "Cancel this decoding, [N]o/[Y]es?"
      StatusLine "Waiting for user input"
      AcceptedKeys$ = CHR$(27) + CHR$(13) + "YN"
      DO: UserKey$ = UCASE$(INKEY$): LOOP UNTIL UserKey$ > "" AND INSTR(AcceptedKeys$, UserKey$)
      IF INSTR(AcceptedKeys$, UserKey$) AND 1 THEN EXIT DO
      PRINT "Decoding continued"
    END IF
    StatusLine "Decoding," + STR$(BytesOutput&)
  LOOP UNTIL TextEOF
RETURN


DecodeText:
  LinesThisCall = LinesPerCall
  DO
    GOSUB GetNextTextLine
    Byte = ASC(LineText$)
    IF Byte < LowBase OR Byte > HighBase THEN GOSUB DecodeAndOutputBinary: TextEOF = 1: EXIT DO
    MID$(DecodeBuffer, BytesToOutput + 1) = LineText$
    BytesToOutput = BytesToOutput + LEN(LineText$)
    IF BytesToOutput >= ConvertBufferSize THEN
      OverBytes = BytesToOutput - ConvertBufferSize
      BytesToOutput = ConvertBufferSize
      GOSUB DecodeAndOutputBinary
      BytesToOutput = OverBytes
      DecodeBuffer = RIGHT$(LineText$, BytesToOutput)
    END IF
    IF TextEOF THEN GOSUB DecodeAndOutputBinary: EXIT DO
    LinesThisCall = LinesThisCall - 1
  LOOP WHILE LinesThisCall
RETURN


DecodeAndOutputBinary:
  DEF SEG = VARSEG(ConvertRoutines(0))
  CALL ABSOLUTE(BYVAL ConvertBufferSize, BYVAL VARSEG(DecodeBuffer), BYVAL VARPTR(DecodeBuffer), BYVAL VARSEG(DecodeBuffer), BYVAL VARPTR(DecodeBuffer), BYVAL ConvertMode, VARPTR(ConvertRoutines(0)))

  IF BytesToOutput = ConvertBufferSize THEN
    PRINT #BinOutputFile, LEFT$(DecodeBuffer, FullBufferOutput);
    BytesOutput& = BytesOutput& + FullBufferOutput
  ELSE
    BytesToOutput = BytesToOutput * CLNG(EncodedBits) \ 8
    PRINT #BinOutputFile, LEFT$(DecodeBuffer, BytesToOutput);
    BytesOutput& = BytesOutput& + BytesToOutput
  END IF
RETURN


RefreshFileBuffer:
  GET TextInputFile, FileBufferBase&, FileBuffer
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


'Assembly code for shifting decoding
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
SUB AttemptOpen (File$, filehandle, mode)
  ON ERROR GOTO ErrHandler: ErrorNum = 0
  filehandle = FREEFILE
  OPEN File$ FOR INPUT AS filehandle: CLOSE filehandle
  ON ERROR GOTO 0
  IF ErrorNum THEN
    IF mode = 0 OR (mode AND ErrorNum <> 53) THEN filehandle = 0: EXIT SUB
  END IF
  OPEN File$ FOR BINARY AS filehandle
END SUB

SUB StatusLine (Text$)
  CsrRow = CSRLIN: CsrCol = POS(0)
  LOCATE 25, 1: PRINT LEFT$(Text$, 79); TAB(80);
  LOCATE CsrRow, CsrCol
END SUB

