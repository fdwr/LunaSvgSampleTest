DEFINT A-Z

DIM FileBuffer AS STRING
DIM SrcFilename AS STRING
DIM DestFilename AS STRING
DIM Char AS STRING * 1
DIM SrcLen AS LONG
DIM SrcPtr AS LONG
DIM ErrorCount AS LONG
DIM BufferSize AS LONG
DIM SectorSize AS LONG

' get source filename from command line
SrcFilename = COMMAND$
IF LEN(SrcFilename) <= 0 THEN
    PRINT "BadCopy - file copy command"
    PRINT "Dwayne Robinson, 2002-01-16"
    PRINT
    PRINT "Similar to the command prompt's COPY command, but doesn't abort the whole"
    PRINT "copy process simply because of one little bad sector. Instead, it ignores"
    PRINT "that area and continues reading the trailing portion of the file."
    PRINT
    PRINT "Unlike the COPY command, it's a very simple program and just copies the"
    PRINT "named file to the current directory."
    PRINT
    PRINT "BadCopy e:\amvs\filename.ext"
    END
END IF

' extract filename from full path
FOR CharPos = LEN(SrcFilename) TO 1 STEP -1
    Char = MID$(SrcFilename, CharPos, 1)
    IF Char = ":" OR Char = "\" THEN EXIT FOR
NEXT
DestFilename = MID$(SrcFilename, CharPos + 1)
IF DestFilename = SrcFilename THEN
    PRINT "Source and destination are the same file"
    END
END IF

ON ERROR GOTO IgnoreError
OPEN SrcFilename FOR INPUT AS 1: CLOSE 1
OPEN SrcFilename FOR BINARY AS 1
IF ErrorCode THEN
    PRINT "Could not open source file for input"
    END
END IF
OPEN DestFilename FOR BINARY AS 2
IF ErrorCode THEN
    PRINT "Could not open destination file for output"
    END
END IF

SectorSize = 2048

SrcLen = LOF(1)
DO WHILE SrcPtr < SrcLen
    BufferSize = SrcLen - SrcPtr
    IF BufferSize > SectorSize THEN BufferSize = SectorSize
    FileBuffer = STRING$(BufferSize, 0)

    LOCATE , 1
    PRINT SrcPtr; "/"; SrcLen; ":"; ErrorCount; "errors";
    IF INKEY$ = CHR$(27) THEN EXIT DO

    ErrorCode = 0
    GET 1, SrcPtr + 1, FileBuffer
    IF ErrorCode THEN ErrorCount = ErrorCount + 1
    PUT 2, , FileBuffer
    SrcPtr = SrcPtr + BufferSize
LOOP

CLOSE 2, 1

END

IgnoreError:
    ErrorCode = ERR
RESUME NEXT

