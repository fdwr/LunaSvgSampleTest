DEFINT A-Z
CONST FileChunkSize = 16384

CLS
PRINT "Simple file parser, this program parses huge files into smaller portable pieces"
PRINT "that can fit on floppy disks. Files that would otherwise be to large can now be"
PRINT "transferred between hard drives without slow modem connections, using the"
PRINT "floppy disk as a temporary conduit. Surprisingly, there is no standard DOS"
PRINT "command for this! This program attempts to make up for that lack of foresight."
PRINT

PRINT "Type the name of the file to parsed and copied,"
LINE INPUT "Source file:", FileSource$
IF FileSource$ = "" GOTO Endit
PRINT

PRINT "Type the name of the file to use as a transfer,"
LINE INPUT "Transfer file:", FileTrans$
PRINT
IF FileTrans$ = "" GOTO Endit

ON ERROR GOTO FilErrHan

'Check for existance of file already
OPEN FileTrans$ FOR INPUT AS 1: CLOSE 1
IF FilErr = 0 THEN
 PRINT "A transfer file with that name already exists. Using it in this process will"
 PRINT "destroy whatever data it is currently holding. If you do not want to overwrite"
 PRINT "it, type in a different name and continue. If you do not care about it,"
 PRINT "simply press Enter to accept it and continue."
 ''
 ''
 ''
END IF

PRINT "Opening both source and transfer file..."

FilErr = 0
OPEN FileSource$ FOR BINARY AS 1
OPEN FileTrans$ FOR BINARY AS 2
IF FilErr THEN
 PRINT "Error opening files."; FilErr
 GOTO Endit
END IF
ChunkBuffer$ = STRING$(FileChunkSize, 0)

FileSize& = LOF(1)
TotalChunks& = FileSize& \ FileChunkSize
FilePos& = 1
TranFilePos& = 1

PRINT "Starting read..."

FilErr = 0
FOR CurrentChunk& = 1 TO TotalChunks&
 LOCATE , 1: PRINT FilePos&; TAB(10); TranFilePos&;
 GET 1, FilePos&, ChunkBuffer$
 PUT 2, TranFilePos&, ChunkBuffer$
 IF FilErr THEN
  GOSUB BetweenDisks
  IF FREEFILE < 3 THEN FilErr = 0: OPEN FileTrans$ FOR BINARY AS 2
  IF FilErr THEN
    PRINT "Error reopening file between disk exchange."; FilErr
    GOTO Endit
  END IF
  FilErr = 0
  TranFilePos& = 1
  PUT 2, 1, ChunkBuffer$
  IF FilErr GOTO ErrorNoTransferSpace
 ELSE
  IF INKEY$ = CHR$(27) THEN
   PRINT
   PRINT "Do you really want to quit the transfer. If you abort now, you will not be able"
   PRINT "to resume the process and will have to start it all over."
   PRINT "Press Esc again to quit...any other key to resume"
   DO: kbrd$ = INKEY$: LOOP UNTIL kbrd$ > ""
   IF kbrd$ = CHR$(27) GOTO Endit
  END IF
 END IF
 TranFilePos& = TranFilePos& + FileChunkSize
 FilePos& = FilePos& + FileChunkSize
NEXT CurrentChunk&

ChunkBuffer$ = ""
ChunkBuffer$ = STRING$(FileSize& MOD FileChunkSize, 0)
GET 1, FilePos&, ChunkBuffer$
PUT 2, 1, ChunkBuffer$
CLOSE 1, 2

PRINT
PRINT "Done transferring file..."
PRINT "The last portion of the source has been written to the floppy disk transfer file"
PRINT "You can now take it out one last time and copy the end to the other hard drive."
PRINT "Then you can place it back this drive and the transfer file will be deleted."
WHILE INKEY$ = "": WEND
KILL FileTrans$

Endit:
PRINT "Ending program..."

END

FilErrHan:
 FilErr = ERR
RESUME NEXT

BetweenDisks:
 PRINT
 PRINT "The transfer disk has reached its limit for space. Now you can remove it and"
 PRINT "put it into the other computer so that the transfer file can be appended to"
 PRINT "earlier portion of the destination file."
 PRINT
 PRINT "When you are done, simply press Enter to continue and this program will copy"
 PRINT "the next portion of the source file onto the floppy transfer file."
 PRINT "You can also press Esc to abort the process."
 DO
  kbrd$ = INKEY$
  IF kbrd$ = CHR$(27) GOTO Endit
 LOOP UNTIL kbrd$ = CHR$(13)
RETURN

ErrorNoTransferSpace:
 PRINT "There is no space on this drive to work with."; FilErr
GOTO Endit

