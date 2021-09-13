'4-10-98 BIN_TEXT.BAS
'Used to translate binary files into 6bit or 7bit ASCII text to be sent in a
'letter, or extract binary data from a letter you recieve.

'  Here is the problem, you have free e-mail (like Juno) but can only send
'plain unformatted text. Pictures, programs, and songs are just not allowed,
'not even the smallest ones. You want to send these just like all your other
'friends who have net access and don't even think a second thought about being
'able to add attachments whenever they feel like it.
'  The solution to this is, if you can only send text, to first translate the
'binary data into text, then send it just like any other letter. Of course,
'the contents will look a little funky, but never mind that. That is simply
'your file in a different form. On the other end, it's decoded back into
'binary as if and looks as if nothing ever happened. The translated data is
'slightly larger in text form, since certain characters are reserved and can't
'be used in email (or any type of plain text file), but that is an acceptable
'price to pay. For the least expansion (8:7), use 7bit encoding. With it, a
'35672 byte file needs at least 40768 bytes plus all the header information,
'opposed to 47562 bytes plus the header stored as 6bit (8:6). It has no built
'it compression or anything ridiculously advanced like that, so if you want
'to, you can use an archiver like PKZIP to shrink the file before sending it.
'  It supports both 7bit and 6bit conversion. For e-mail servers that allow
'extended characters, the 7bit is best. For servers that do not like them,
'for whatever reason, 6bit conversion is available. For example, Juno says
'that a file contains binary data in it if you try to insert a text file into
'your message with even one single extended character (there is a way around
'that though below). 6bit encoding is exactly the same as Base64 used by most
'attachments. I have honestly never seen 7 bit encoding and do not know why.
'  Bty, for anybody that cares about the encoded format,
'6bit,base64 uses values 64-127 (first six bits with the seventh bit set).
'7bit,base128 uses values 128-255 (first seven bits with the eighth bit set).
'  The header format is sort of similar to MIME, having keynames followed by
'a colon and their value, then actual data, but It has its own set of
'keynames specifically for BinText and file extraction.
'  I will warn you that this is really only meant for small files, not things
'that range in megabytes. For larger files that will not fit into a single
'letter though, I added the ability to split them into multiple parts and send
'the pieces in separate letters.
'  For those curious on how to put extended characters into your message, the
'key is to use the ClipBoard instead of the silly Juno "Insert Text File...".
'Just use Write to open the translated text file, Select it All, Copy, and
'then Paste into your message. You can also use Notepad if the text file is
'small enough (under 32k). As for text files over 60k, you will not be able
'to fit them into Juno (even with the 'Paste' trick); the message text is just
'limited to that. I might however be able to directly append a message to the
'Outbox, which is file usually "c:\juno\user0000\fold0001.frm" (:-)
'Who knows whether the limitation is the just the text box for composing your
'messages object or if it is actually the maximum file transfer size.

'  It was originally designed for use between me and a friend who have Juno,
'but I thought it would be nicer to share. The only cost for this program is
'one letter of appreciation if you like it :-)        FDwR@juno.com

DEFINT A-Z
DECLARE FUNCTION BIN$ (number%)    'not really needed anymore, just used as a debugging tool when I was perfecting the asm code
DECLARE SUB ConvertBinaryToText () 'definitely needed
DECLARE SUB ConvertTextToBinary () 'this too
DECLARE SUB ResetProgressDisplay (Text$, ProgressCol%)
DECLARE FUNCTION UpdateAndCheckEsc% (ProgressCol%, FilePos&)
DECLARE FUNCTION GetElementFromText (Element$, ElementDetail$, FilePos&)
DECLARE SUB PrintBox (TopRow%, BtmRow%, LftCol%, RitCol%)
DECLARE SUB PrintCenter (TopRow%, LftCol%, RitCol%, Text$)
DECLARE SUB DrawBox (TopRow%, BtmRow%, LftCol%, RitCol%)

TYPE ObjectBound
TopRow AS INTEGER
BtmRow AS INTEGER
LftCol AS INTEGER
RitCol AS INTEGER
END TYPE

CONST SourceFile = 1, DestFile = 2, TextBlockSize = 8000, BlockSizeBit6 = 6000, BlockSizeBit7 = 7000
DIM SHARED AsmConvertRoutines$, TextData AS STRING * TextBlockSize, BinData AS STRING * BlockSizeBit7
DIM SHARED ProgressText$
DIM MenuOps(0 TO 13) AS STRING

FileError = 0
OPEN "bintext.com" FOR INPUT AS 1: CLOSE 1
IF FileError THEN PRINT "Either BINTEXT1.ASC or BINTEXT2.ASC can not be found": END
OPEN "bintext.com" FOR BINARY AS 1: AsmConvertRoutines$ = INPUT$(LOF(1), 1): CLOSE 1

'set screen, draw prompts and file list on a later version
SCREEN 0: COLOR 7, 0: CLS : VIEW PRINT 1 TO 25: LOCATE , , 0

GOTO SkipOpeningPrint
'ask for source file with data to read and eventually translate, the text file
'saved from Juno.
'check that the file exists
'search in it to find the beginning of the data, default filename, and part.
'stop if user presses Escape
'select what the name of the output filename is, the original binary file be
'reconstructed. The name prompt will originally be filled with the default
'name in the text file after the 'file:' entry. Just press Enter to use its
'original name or enter a different one.
PRINT "Text/Binary Converter by FDwR in Qbasic on 4-98, ver 1"
PRINT " Used to translate binary files into extended text characters for sending email"
PRINT "letters that do not support attachments or encoded pictures (just plain text)"
PRINT "or translating receieved letters back into their binary images."
PRINT " That includes pictures, sounds, songs, and even small executables. This"
PRINT "version does not support multi-part attachments that require more than one"
PRINT "letter to send the entire file image, so any files must be smaller than the"
PRINT "maximum of the largest letter you can send. With Juno it is about 60k. Who"
PRINT "knows about any others? I do not know if Juno has anything against including"
PRINT "large files in your letters, but so far in the legal documentation I have not"
PRINT "seen anything... Bty, zipping a file before sending can definitely help!"
PRINT " Just tell it the name of the file to search. You will have to first save your"
PRINT "letter as separate message (in Juno, use File|Save message as text...) out from"
PRINT "the Inbox, since the Inbox is made up of many letters and Bin2Text would not"
PRINT "know which one to choose. It will automatically select the output name to be"
PRINT "the name it was on the computer that sent it; however you can change that by"
PRINT "simply entering a different one."
PRINT " It is not the most advanced program, but thanks to the little 32bit assembly"
PRINT "code it is quite fast...on my old 386, it translated 300k of binary to text"
PRINT "in just 15 seconds! 83 seconds for two megabytes..of course you will never"
PRINT "need this for anything that large. Sorry good old Qbasic, but you were just"
PRINT "too slow for me :("
PRINT

COLOR 0, 7: CLS

SkipOpeningPrint:
GOSUB CreateMenuChoices
GOSUB DrawMainScreen

END

CreateMenuChoices:
  'dimension all necessary variables
  MenuOps(0) = "Convert:"
  MenuOps(1) = "Source text:"
  MenuOps(2) = "Destination binary:"
  MenuOps(3) = "Source binary:"
  MenuOps(4) = "Append text:"
  MenuOps(5) = "Part length determined by:"
  MenuOps(6) = "Bytes per part:"
  MenuOps(7) = "Put name on:"
  MenuOps(8) = "Name:"
  MenuOps(9) = "Part:"
  MenuOps(10) = "Data embed:"
  MenuOps(11) = "Overwrite destination:"
  MenuOps(12) = "Binary position:"
  MenuOps(13) = "Encoding:"
  DIM MenuCoors(0 TO 13) AS ObjectBound
  DIM MenuTextIndexes(0 TO 13)
RETURN

DrawMainScreen:
  COLOR 15, 3: PRINT SPACE$(80);
  PrintCenter 1, 1, 80, "BinText by FDwR"
  COLOR 7, 0: PrintBox 2, 13, 1, 80
  COLOR 7, 0: PrintBox 14, 24, 1, 80
  LOCATE 3, 1
'PRINT "Convert: <binary to text> <text to binary>"
'PRINT "Source text: $$$$"
'PRINT "Destination binary: $$$$"
'PRINT "Name: $$$$"
'PRINT "Part: ##"
'PRINT "Data embed: ##"
'PRINT "Overwrite destination: <First part> <Once> <No>"
'PRINT "Binary position: #####"
'PRINT "Encoding: <6bit> <7bit> <text>"

LOCATE 3, 3: COLOR 9
'PRINT "Convert: <binary to text> <text to binary>"
'PRINT "Source binary: $$$$"
'PRINT "Append text: $$$$"
'PRINT "Name: $$$$"
'PRINT "Encoding: <6bit> <7bit> <text>"
'PRINT "Part length determined by: <length of letter> <length of binary>"
'PRINT "Bytes per part: ####"
'PRINT "Put name on: <First part only> <All parts>"
'PRINT "Binary position: #####"
PRINT "Part: ##"

RETURN

ShowVarMenuChoice:
  IF ShowChoice <> MenuChoice THEN COLOR 9 ELSE IF CurMenu THEN COLOR 11 ELSE COLOR 15
  'Convert mode converts binary into text for transfer
  GOSUB GetMenuTextIndex
  LOCATE MenuChoice + 3, 1
  PRINT MenuOps(MenuTextIndex);
  GOSUB ShowMenuChoiceObject
RETURN

GetMenuTextIndex:
  IF ConvertMode THEN MenuTextIndex = MenuTextIndexes(ShowChoice + 6) ELSE MenuTextIndex = MenuTextIndexes(ShowChoice)
RETURN

ShowMenuChoiceObject:
  IF ConvertMode THEN
    SELECT CASE ShowChoice
    CASE 0: PRINT MenuOps(MenuTextIndex);
    CASE 1
    CASE 2
    END SELECT
  ELSE
    SELECT CASE ShowChoice
    CASE 0
    CASE 1
    CASE 2
    END SELECT
  END IF
RETURN

GetBinTextVars:
'handles key input for the menu and list

  DO
    Key$ = INKEY$
    IF MenuWindow THEN



    ELSE
      SELECT CASE Key$
      CASE CHR$(0) + "H": NewChoice = (MenuChoice + 1) MOD TotalChoices
      CASE CHR$(0) + "P": NewChoice = (MenuChoice + TotalChoices - 1) MOD TotalChoices
      CASE CHR$(9): MenuWindow = MenuWindow XOR 1: GOSUB ShowVarMenuChoice
      CASE CHR$(13): GOSUB CheckChoices
      CASE CHR$(27): EXIT DO
      CASE ELSE: GOSUB ReactMenuChoice'call object and pass on key to it
      END SELECT
    END IF

  'if keypress, then call appropriate subcode
  '  if Tab, then make sure list is changed to file list or embed list
  '  if movement in vars, highlight new one
  '  if movement in list, update item in vars
  '  if Enter in list, jump back to next item in vars
  '  if Enter in vars, start or continue process if all files valid
  '    else refresh list, select invalid var, jump to filelist
  'if list needs updating then interleave retrieving of embed finds or
  '  directory list reading
  LOOP


GetBinTextListChoice:
  DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE CHR$(9), CHR$(13)
      GOTO GetBinTextVars
    CASE CHR$(27): EXIT DO
    CASE ELSE: 'call object and pass on key to it
               'if menu choice change, update associated object
    END SELECT
  'if keypress, then call appropriate subcode
  '  if Tab, then make sure list is changed to file list or embed list
  '  if movement in vars, highlight new one
  '  if movement in list, update item in vars
  '  if Enter in list, jump back to next item in vars
  '  if Enter in vars, start or continue process if all files valid
  '    else refresh list, select invalid var, jump to filelist
  'if list needs updating then interleave retrieving of embed finds or
  '  directory list reading
  LOOP


RETURN

ReactMenuChoice:
  IF ConvertMode THEN
    SELECT CASE MenuChoice
    CASE 0
    CASE 1
    CASE 2
    CASE 3
    CASE 4
    END SELECT
  ELSE
    SELECT CASE MenuChoice
    CASE 0
    CASE 1
    CASE 2
    CASE 3
    CASE 4
    END SELECT
  END IF
RETURN

'if notdecided
PRINT "Append a binary file to a letter or retrieve a file out of a letter? (A/R/Esc)"
DO: Key$ = UCASE$(INKEY$): LOOP UNTIL Key$ = CHR$(27) OR Key$ = "A" OR Key$ = "R"
IF Key$ = "R" THEN GOSUB GetRetrieveFileInputs ELSE IF Key$ = "A" THEN GOSUB GetAppendFileInputs

'CLS
END

GetAppendFileInputs:
  CLOSE SourceFile, DestFile
  IF FilesNotOpen = 0 THEN FilesNotOpen = 3
  IF FilesNotOpen AND SourceFile THEN
    PRINT "Binary file to be read..."
    GOSUB GetFileName
    IF NewFile$ = "" THEN RETURN
    SourceFilename$ = NewFile$
  END IF
  IF FilesNotOpen AND DestFile THEN
    PRINT "File to be appended..."
    GOSUB GetFileName
    IF NewFile$ = "" THEN RETURN
    DestFileName$ = NewFile$
  END IF
  ON ERROR GOTO FileErrorHandler
  FileError = 0: OPEN SourceFilename$ FOR INPUT AS SourceFile: CLOSE SourceFile
  IF FileError THEN PRINT "Source file was not found": GOTO GetAppendFileInputs ELSE OPEN SourceFilename$ FOR BINARY AS SourceFile
  FileError = 0: OPEN DestFileName$ FOR INPUT AS DestFile: CLOSE DestFile
  IF FileError AND FileError <> 53 THEN PRINT "Can not open that file for appending": GOTO GetAppendFileInputs ELSE OPEN DestFileName$ FOR APPEND AS DestFile
  IF FileError = 53 THEN PRINT "New destination file created" ELSE PRINT "Appending to existing file"
  ON ERROR GOTO 0
  PRINT "Source file is"; LOF(SourceFile); "bytes long"
  Before# = TIMER
  GOSUB AppendFile
  After# = TIMER
  PRINT "Time it took:"; After# - Before#
  CLOSE SourceFile, DestFile
RETURN

GetRetrieveFileInputs:
  CLOSE SourceFile, DestFile
  IF FilesNotOpen = 0 THEN FilesNotOpen = 3
  IF FilesNotOpen AND SourceFile THEN
    PRINT "Text file to get binary from..."
    GOSUB GetFileName
    IF NewFile$ = "" THEN RETURN
    SourceFilename$ = NewFile$
  END IF
  IF FilesNotOpen AND DestFile THEN
    PRINT "Name to save binary file as... (type '=' to use the default)"
    GOSUB GetFileName
    IF NewFile$ = "" THEN RETURN
    DestFileName$ = NewFile$
  END IF
  ON ERROR GOTO FileErrorHandler
  FileError = 0: OPEN SourceFilename$ FOR INPUT AS SourceFile: CLOSE SourceFile
  IF FileError THEN PRINT "Source file was not found": GOTO GetAppendFileInputs ELSE OPEN SourceFilename$ FOR BINARY AS SourceFile
  BaseFilePos& = GetElementFromText("==BeginData==", "", 1)
  IF BaseFilePos& = 0 THEN PRINT "There is no binary file to retrieve in this text": GOTO GetRetrieveFileInputs
  Dummy& = GetElementFromText("File:", NewFile$, BaseFilePos&)
  IF DestFileName$ = "=" THEN DestFileName$ = NewFile$
  FileError = 0: OPEN DestFileName$ FOR INPUT AS DestFile: CLOSE DestFile
  IF FileError AND FileError <> 53 THEN PRINT "Can not open the binary file for output": GOTO GetAppendFileInputs
  PRINT DestFileName$
  'GOTO GetRetrieveFileInputs
  IF FileError = 53 THEN
    OPEN DestFileName$ FOR OUTPUT AS DestFile
    PRINT "Binary file file created"
  ELSE
    PRINT "That file already exists, do you want to append or overwrite it? (A/O/Esc)"
    DO: Key$ = UCASE$(INKEY$): LOOP UNTIL Key$ = CHR$(27) OR Key$ = "A" OR Key$ = "O"
    IF Key$ = CHR$(27) THEN
      GOTO GetRetrieveFileInputs
    ELSEIF Key$ = "A" THEN
      OPEN DestFileName$ FOR APPEND AS DestFile
      PRINT "Appending to existing file"
    ELSEIF Key$ = "O" THEN
      OPEN DestFileName$ FOR OUTPUT AS DestFile: PRINT "Overwriting existing file"
    END IF
  END IF
  ON ERROR GOTO 0
  PRINT "Source file is"; LOF(SourceFile); "bytes long"
  Before# = TIMER
  GOSUB RetrieveFile
  After# = TIMER
  PRINT "Time it took:"; After# - Before#
  CLOSE SourceFile, DestFile
RETURN

GetFileName:
  LINE INPUT "Filename:", NewFile$
  IF UserEscape THEN NewFile$ = ""
  IF NewFile$ = "" THEN RETURN ELSE NewFile$ = UCASE$(LTRIM$(NewFile$))
  IF INSTR(NewFile$, "*") THEN SHELL "dir " + NewFile$: GOTO GetFileName
  ON ERROR GOTO FileErrorHandler
  FileError = 0: CHDIR NewFile$
  IF FileError = 0 THEN PRINT "Directory changed": GOTO GetFileName
  ON ERROR GOTO 0
RETURN

AppendFile: 'assumes that files have already been opened
  ResetProgressDisplay "Bytes output to text from binary file:", ProgressCol
  FileLeng& = LOF(SourceFile)
  PRINT #DestFile, "--start--"
  PRINT #DestFile, "file:" + SourceFilename$
  PRINT #DestFile, "part:1"
  PRINT #DestFile, "data:" + LTRIM$(STR$(FileLeng&))
  FilePos& = 1
  DO UNTIL FilePos& > FileLeng& OR UpdateAndCheckEsc(ProgressCol, FilePos&)
    GET SourceFile, FilePos&, BinData 'Read in 700 bytes from source to BinData
    ConvertBinaryToText               'Convert 700 bytes to ASCII text
    IF FileLeng& - FilePos& + 1 >= BinBlockSize THEN
      PRINT #DestFile, ":"; TextData  'Print the 800 bytes of tranlsated text
    ELSE
      bytes = FileLeng& - FilePos& + 1
      IF bytes MOD 7 THEN bytes = (bytes * 8 \ 7) + 1 ELSE bytes = bytes * 8 \ 7
      PRINT #DestFile, ":"; LEFT$(TextData, bytes)'Print remaining bytes of tranlsated text
    END IF
    FilePos& = FilePos& + BinBlockSize    'Move onto next chunk
  LOOP
  PRINT #DestFile, "--stop--"
  LOCATE , ProgressCol: PRINT FileLeng&
RETURN

RetrieveFile:
  FileLeng& = LOF(SourceFile)
  FileSize& = GetElementFromText("SIZE", ElementDetail$, BaseFilePos&)
  FileSize& = VAL(ElementDetail$)
  PRINT FileSize&
  FilePos& = GetElementFromText("DATA", "", BaseFilePos&) + 5
  PRINT FilePos&
  LengthCount& = 0
  PRINT LengthCount&
  TextDataCount = 0
  FileInputCount = 1
  ResetProgressDisplay "Bytes output to binary file from text:", ProgressCol
  DO UNTIL FilePos& > FileLeng& OR UpdateAndCheckEsc(ProgressCol, LengthCount&)
    'GET SourceFile, FilePos&, FileInput'Read in 256 bytes from source to FileInput
    'if linebreak in FileInput then
    '  move pointer foward to two ahead of cr and lb
    '  set newline to true
    'else last break is end of FileInput
    '  move pointer to end of FileInput
    'commit FileInput to TextData, clipping if larger than TextData though
    'if larger than TextData then translate and print, reset TextDataCount=0
    ' and readjusting pointer if necessary
    'check that pointer is not beyond end of FileInput
    ' if so, load a new page into FileInput, subtracting 256 from pointer
    'if newline then check that next line continues the data stream, else quit
    ' if it does continue, add one to filePos& to skip the colon
  LOOP
  'FileInput = ""
  LOCATE , ProgressCol: PRINT FilePos&
RETURN

RetrieveFileStart2:
  FileInputPos = 1
  TextDataPos = 0
  FilePos& = BaseFilePos&
  TextFile = 1
  GET TextFile, FilePos&, FileInput
RETURN

RetrieveFile2:
  'TextDataPos=1
  'fill buffer with text file data
  'remove all CRs from text buffer
  'if newline then check for a preceding space before it
  '  if it does not, convert the buffer and print it to dest
  'if none left and data buffer full, then convert the buffer
  'return to caller every so many bytes output
  'BytesToOutput equals whatever the caller sets it to
  'it ensures that this sub will return after so many have been translated
  'so that the caller can update the status display and check for Esc presses
  DO
    TextDataRemaining = LEN(TextData) - TextDataPos
    'NextFilePos = INSTR(FileInput, CHR$(13), FileInputPos)
    IF NextFilePos = 0 THEN
    'commit remaining bytes to TextData
    'get next page
    'reset FileInputPos
      'if TextDataPos +
      FilePos& = FilePos& + LEN(FileInput)'1024
      GET TextFile, FilePos&, FileInput
      FileInputPos = 1
    ELSE
      'move FileInputPos forward by two, check that we have not exceeded the
      'current page. check next character; continue if it is a space
      'flush BinData and return to caller if not.


    END IF
  LOOP
RETURN

FileErrorHandler:
  FileError = ERR
RESUME NEXT

Diagnose:
  CLS
  FOR count = 1 TO 25
    LOCATE count, 1: PRINT STRING$(79, 4);
  NEXT count
  ByteLength = 49
  BinData = STRING$(ByteLength, 8)
  BinData = "H llo everybody"
  LOCATE 2, 1: PRINT LEFT$(BinData, ByteLength)
  FOR count = 1 TO ByteLength
    PRINT BIN$(ASC(MID$(BinData, count, 1))); " ";
  NEXT count
  PRINT CHR$(13)
  DEF SEG = VARSEG(BinToText$)
  'CALL absolute(BYVAL ByteLength, BYVAL VARSEG(TextData), BYVAL VARPTR(TextData), BYVAL VARSEG(BinData), BYVAL VARPTR(BinData), SADD(BinToText$))
  DEF SEG = &HB800
  FOR count = 0 TO ByteLength - 1
    MID$(TextData, count + 1, 1) = CHR$(PEEK(count))
    PRINT BIN$(PEEK(count)); " ";
  NEXT count
  PRINT CHR$(13)
  SLEEP
  DEF SEG = VARSEG(TextToBin$)
  'CALL absolute(BYVAL ByteLength, BYVAL VARSEG(BinData), BYVAL VARPTR(BinData), BYVAL VARSEG(TextData), BYVAL VARPTR(TextData), SADD(TextToBin$))
  DEF SEG = &HB800
  FOR count = 0 TO ByteLength - 1
    PRINT BIN$(PEEK(count)); " ";
  NEXT count
RETURN

'Used for returning the string of a number in binary. (13-->1011) Note that
'this returns it in little endian format (for easier reading) meaning that
'the lowest bits are on the left and the they grow higher to the right.
'Surprised that Qbasic does not have its own native function for something
'like this, even though they have OCT$ and HEX$.
FUNCTION BIN$ (number)
  Text$ = STRING$(8, 48)
  bitmask = 1
  FOR count = 1 TO 8
    IF number AND bitmask THEN MID$(Text$, count) = "1"
    bitmask = bitmask * 2
  NEXT count
  BIN$ = Text$
END FUNCTION

SUB ConvertBinaryToText 'no parameters
  DEF SEG = VARSEG(BinToText$)
  'CALL absolute(BYVAL BinBlockSize, BYVAL VARSEG(TextData), BYVAL VARPTR(TextData), BYVAL VARSEG(BinData), BYVAL VARPTR(BinData), SADD(BinToText$))
END SUB

SUB ConvertDataBlock (Convert)
  'Simply calls 32bit assembly to convert a data block from binary data to
  'text or text back into binary data, depending which function (routine)
  'is called. It can also convert either 6bit or 7bit both ways.

  'The parameters it passes on to it include, the number of bytes to be
  'translated (must be an even multiple of eight!), the segment:offset of
  'the destination to put the converted data, the segment:offset of the
  'source to read the raw data, and the routine to be called. It actually
  'passes them the other way around, because Qb puts parameters on the stack
  'in reverse order. Because it uses unrolled loops for a big speed increase,
  'the asm will round down the length to the nearest even multiple of eight,
  'so just set your destination to the right size. Although the asm itself
  'is designed to accept any length (as long as they multiples of eight),
  'this sub actually converts a constant sized chunk. The source and
  'destination should be passed as segment:offset using VARSEG and VARPTR.
  'The available four routines to be called include Encode6bit, Decode6bit,
  'Encode7bit, and Decode7bit (bty, those are their names in the asm). If you
  'select a non-existant routine (anything out of 0-3) you computer will
  'explode. All the parameters are passed by value using BYVAL.

  'For more info on the how 6bit and 7bit are stored and how the routines do
  'their cool work, see the asm that came with BinText (I think anything is
  'cool that is fast enough to convert 1114112 bytes of data per second on a
  '386 ;-). Bty, if you select a routine that does not exist, it will simply
  'ignore your flub and return without doing anything - it could not blow up
  'your computer if it tried :-)

  'If you decide to use my code in one of your own programs, please include my
  'name in it. It is one of the most tedious bits of code that I worked on,
  'to debug and optimise. If you're knowledgable in assembly code and just
  'happen to see something that could make it even faster (like it's really
  'necessary), please tell me how! :-)

  DEF SEG = VARSEG(AsmConvertRoutines$)
  IF Mode AND 1 THEN
    CALL Absolute(BYVAL BinBlockSize, BYVAL VARSEG(BinData), BYVAL VARPTR(BinData), BYVAL VARSEG(TextData), BYVAL VARPTR(TextData), Convert, SADD(AsmConvertRoutines$))
  ELSE
    CALL Absolute(BYVAL BinBlockSize, BYVAL VARSEG(TextData), BYVAL VARPTR(TextData), BYVAL VARSEG(BinData), BYVAL VARPTR(BinData), Convert, SADD(AsmConvertRoutines$))
  END IF
END SUB

SUB ConvertTextToBinary
  'Simply calls 32bit assembly and leaves all the work to it.
  'The parameters it passes on to it include, the number of bytes to be
  'translated, the segment:offset of the destination to put binary data
  '(TextData), and the segment:offset of the source to read the binary data.
  'No matter how many bytes really need to be translated, it just does a full
  '800-->700 transfer. It's so fast, I just decided to make things simpler by
  'not added a whole bunch of IF statements and parameters to be passed on to
  'the ConvertTextToBinary sub.

  'If you decide to use my code in one of your own programs, please include my
  'name in it. It is one of the most tedious bits of code that I worked on,
  'to debug and optimise. If you're knowledgable in assembly code and just
  'happen to see something that could make it even faster (like it's really
  'necessary), please tell me how! :)

  DEF SEG = VARSEG(TextToBin$)
  'CALL absolute(BYVAL BinBlockSize, BYVAL VARSEG(BinData), BYVAL VARPTR(BinData), BYVAL VARSEG(TextData), BYVAL VARPTR(TextData), SADD(TextToBin$))
END SUB

SUB FindFileStart (NewFile$)

END SUB

FUNCTION GetElementFromText (Element$, ElementDetail$, FilePos&)
  ElementDetail$ = ""
  ResetProgressDisplay "Searching for element:" + Element$, ProgressCol
  FileLeng& = LOF(SourceFile)
  LineBreak$ = CHR$(13) + CHR$(10)
  GET SourceFile, FilePos&, TextData
  DO UNTIL FilePos& > LOF(SourceFile) OR UpdateAndCheckEsc(ProgressCol, FilePos&)
    NextPos = INSTR(NextPos + 1, TextData, Element$)
    IF NextPos THEN
      IF FilePos& < 3 AND NextPos THEN
        GOTO GetElement
      ELSEIF MID$(TextData, NextPos - 2, 2) = LineBreak$ THEN
        GOTO GetElement
      END IF
    ELSE
      FilePos& = FilePos& + TextBlockSize - LEN(Element$) - 2
      GET SourceFile, FilePos&, TextData
    END IF
  LOOP
  LOCATE , ProgressCol: PRINT FileLeng&
EXIT FUNCTION

GetElement:
  IF INSTR(NextPos, TextData, LineBreak$) = 0 THEN FilePos& = FilePos& + NextPos - 1: NextPos = 1: GET SourceFile, FilePos&, TextData
  EndOfElement = INSTR(NextPos, TextData, LineBreak$)
  IF EndOfElement = 0 OR EndOfElement > 256 THEN EndOfElement = 256
  ElementDetail$ = MID$(TextData, LEN(Element$) + 1, EndOfElement - LEN(Element$) - 1)
  GetElementFromText = FilePos& + NextPos - 1
 'search from after the file: line to before the first data: statement or
 'blank line
END FUNCTION

SUB Menu.React (Key$)

END SUB

SUB MultipleOption.React (Bounds AS ObjectBound, Text$)

END SUB

SUB PrintBox (TopRow, BtmRow, LftCol, RitCol)
  ColWidth = RitCol - LftCol - 1
  IF ColWidth < 0 THEN ColWidth = 0
  LOCATE TopRow, LftCol: PRINT "Û"; STRING$(ColWidth, 223); "Û";
  FOR Row = TopRow + 1 TO BtmRow - 1
    LOCATE Row, LftCol: PRINT "Û"; SPACE$(ColWidth); "Û";
  NEXT Row
  LOCATE BtmRow, LftCol: PRINT "Û"; STRING$(ColWidth, 220); "Û";
END SUB

SUB PrintCenter (TopRow, LftCol, RitCol, Text$)
  ColWidth = RitCol - LftCol + 1
  IF ColWidth < 0 THEN ColWidth = 0
  IF LEN(Text$) > ColWidth THEN
    LOCATE TopRow, LftCol
  ELSE
    LOCATE TopRow, (ColWidth - LEN(Text$)) \ 2 + LftCol - 1
  END IF
  PRINT LEFT$(Text$, ColWidth);
END SUB

SUB ResetProgressDisplay (Text$, ProgressCol)
  IF LEN(Text$) THEN ProgressText$ = Text$
  PRINT ProgressText$;
  ProgressCol = POS(0)
END SUB

FUNCTION UpdateAndCheckEsc (ProgressCol, FilePos&)
  LOCATE , ProgressCol: PRINT FilePos&;
  IF LEN(INKEY$) THEN
    PRINT CHR$(13); "Do you want to quit? Press Esc to end or any other key to continue...";
    Key$ = INPUT$(1): PRINT
    IF Key$ = CHR$(27) THEN UpdateAndCheckEsc = 1 ELSE ResetProgressDisplay "", ProgressCol
  END IF
END FUNCTION

