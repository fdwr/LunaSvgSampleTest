DEFINT A-Z

SourceFile$ = "c:\sb\drv\ctmidi.drv"
SourcePos = 10944
PartLength = 16'number of bytes
PartsTotal = 128

OPEN SourceFile$ FOR BINARY AS 1

FilePos = SourcePos + 1
FileData$ = STRING$(PartLength, 0)
FrontFileData$ = FileData$

GET 1, FilePos, FrontFileData$
FOR Count = 2 TO PartsTotal
    GET 1, FilePos + PartLength, FileData$
    PUT 1, FilePos, FileData$
    FilePos = FilePos + PartLength
NEXT Count
PUT 1, FilePos, FrontFileData$

CLOSE 1

END

