DEFINT A-Z
CONST VramBase = 134164, ClearStringSize = 2048
ON ERROR GOTO FileErrorHandler

PRINT "VRAM Wiper 0.1, for ZSNES savestates"
File$ = COMMAND$
IF LEN(File$) = 0 GOTO GetFileName
DO
  ErrorNum = 0
  OPEN File$ FOR INPUT AS 1: CLOSE 1
  IF ErrorNum = 0 THEN EXIT DO
  PRINT "Could not open file: "; File$
GetFileName:
  LINE INPUT "Savestate filename: ", File$
  IF LEN(File$) = 0 THEN END
LOOP
OPEN File$ FOR BINARY AS 1

SEEK 1, 11284
FOR ByteCounter = 0 TO 63
  PUT 1, , ByteCounter
NEXT ByteCounter
FOR ByteCounter = 256 TO 16128 STEP 256
  PUT 1, , ByteCounter
NEXT ByteCounter
FOR ByteCounter = 257 TO 16129 STEP 256
  PUT 1, , ByteCounter
NEXT ByteCounter
CLOSE 1
END

DO
  LINE INPUT "Offset into VRAM: ", Num$
  IF LEN(Num$) = 0 THEN END
  Offset& = VAL(LEFT$(Num$, 6))
  IF Offset& > 65535 THEN PRINT "Offset is beyond 64k" ELSE EXIT DO
LOOP
LINE INPUT "Bytes to clear: ", Num$
IF LEN(Num$) = 0 THEN END
Count& = VAL(LEFT$(Num$, 6))
IF Offset& + Count& > 65535 THEN PRINT "Space to clear is beyond 64k": END
GetClearValue:
LINE INPUT "Value to set bytes: ", Num$
ClearValue = VAL(LEFT$(Num$, 4))
IF ClearValue > 255 THEN PRINT "Bytes hold values within 0-255": GOTO GetClearValue

ClearString$ = STRING$(ClearStringSize, ClearValue)
FilePos& = VramBase + Offset&
FOR ByteCounter = 1 TO Count& \ ClearStringSize
  PUT 1, FilePos&, ClearString$
  FilePos& = FilePos& + ClearStringSize
NEXT ByteCounter
ClearString$ = STRING$(Count& MOD ClearStringSize, ClearValue)
PUT 1, FilePos&, ClearString$

PRINT "Done..."

CLOSE 1
END

FileErrorHandler:
  ErrorNum = ERR
RESUME NEXT

