DEFINT A-Z

CONST FileBufferSize = 8192
DIM FileBuffer AS STRING * FileBufferSize, CountTable(0 TO 255) AS LONG

File$ = COMMAND$
OPEN File$ FOR INPUT AS 1: CLOSE 1
OPEN File$ FOR BINARY AS 1
FileLeng& = LOF(1)

FilePos& = 1
DO
  GET 1, FilePos&, FileBuffer
  DEF SEG = VARSEG(FileBuffer(0))
  Index = VARPTR(FileBuffer(0))
  FOR Index = Index TO Index + FileBufferSize - 1
    CharValue = PEEK(Index)
    CountTable(CharValue) = CountTable(CharValue) + 1
  NEXT Index
  FilePos& = FilePos& + FileBufferSize
  IF FilePos& > FileLeng& THEN EXIT DO
  GOSUB PrintSearchProgress
LOOP UNTIL LEN(INKEY$)
FilePos& = FileLeng&
GOSUB PrintSearchProgress
PRINT

GOSUB SearchCounts
PRINT LowestNumber; "="; LowestCount; "times"
PRINT HighestNumber; "="; HighestCount; "times"

END

PrintSearchProgress:
  LOCATE , 1: PRINT FilePos&; "bytes searched";
RETURN

SearchCounts:
  LowestCount = 10000
  HighestCount = -1
  LowestNumber = 0
  HighestNumber = 0
  FOR Count = 0 TO 255
    IF CountTable(Count) < LowestCount THEN LowestNumber = Count: LowestCount = CountTable(Count)
    IF CountTable(Count) > HighestCount THEN HighestNumber = Count: HighestCount = CountTable(Count)
  NEXT Count
RETURN

