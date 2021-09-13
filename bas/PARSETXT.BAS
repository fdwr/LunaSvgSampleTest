DEFINT A-Z

CONST FileBufferSize = 8192, MaxLineWidth = 1000
DIM SHARED FileBuffer AS STRING * FileBufferSize
DIM TextLine AS STRING, CommandLine AS STRING

LineIndent = 0
LineWidth = 76
ParseMode = 0
NewLine = -1

SourceFile$ = COMMAND$ + ".wwt"
DestFile$ = COMMAND$ + ".txt"
GOSUB OpenIoFiles

FilePos& = 1
FileBufferPos& = 1
FileLen& = LOF(1)

CLS
GET 1, FileBufferPos&, FileBuffer
DO
    GOSUB ParseFile
    LOCATE , 1: PRINT TotalLines;
LOOP UNTIL FilePos& > FileLen& OR INKEY$ = CHR$(27)
IF LEN(TextLine) THEN
    GOSUB WriteLines
END IF
LOCATE , 1: PRINT TotalLines; "total wrapped lines"

CLOSE 1, 2
END

OpenIoFiles:
    OPEN SourceFile$ FOR INPUT AS 1: CLOSE 1
    OPEN SourceFile$ FOR BINARY AS 1
    OPEN DestFile$ FOR OUTPUT AS 2
RETURN

ParseFile:
    BufferEnd = FileLen& - FileBufferPos& + 2
    BufferPos = FilePos& - FileBufferPos& + 1
    IF BufferEnd > FileBufferSize THEN
        BufferEnd = FileBufferSize + 1
    END IF
ParseFileReselect:
    SELECT CASE ParseMode
    CASE 0
        NextParseMode = 1
        NextBufferPos = BufferEnd 'FileBufferSize+1
        Find$ = CHR$(13): FindParseMode = 2
        GOSUB FindNextText
        Find$ = "{": FindParseMode = 3
        GOSUB FindNextText
        ParseMode = 1
        GOTO ParseFileReselect
    CASE 1
        IF LEN(TextLine) > LineWidth THEN
            GOSUB WriteLine
        ELSE
            IF NextBufferPos - BufferPos > MaxLineWidth THEN
                TextLine = TextLine + MID$(FileBuffer, BufferPos, MaxLineWidth)
                BufferPos = BufferPos + MaxLineWidth
                IF BufferPos >= NextBufferPos THEN ParseMode = NextParseMode
            ELSE
                TextLine = TextLine + MID$(FileBuffer, BufferPos, NextBufferPos - BufferPos)
                BufferPos = NextBufferPos
                ParseMode = NextParseMode
            END IF
        END IF
    CASE 2
        GOSUB WriteLines
        ParseMode = 0
        BufferPos = BufferPos + 2
        NewLine = -1
        TotalLines = TotalLines + 1
    CASE 3
        BufferPos = BufferPos + 1
        'CommandLine=CommandLine+"<I>"
        NextFind = INSTR(BufferPos, FileBuffer, "}")
        IF NextFind >= BufferEnd THEN NextFind = 0
        IF NextFind THEN
            CommandLine = CommandLine + MID$(FileBuffer, BufferPos, NextFind - BufferPos)
            SELECT CASE LEFT$(CommandLine, 1)
            CASE "I": LineIndent = LEN(TextLine)
            CASE "{": TextLine = TextLine + "{"
            END SELECT
            BufferPos = NextFind + 1
            ParseMode = 0
            CommandLine = ""
        ELSE
            IF LEN(CommandLine) < 1000 THEN CommandLine = CommandLine + MID$(FileBuffer, BufferPos, BufferEnd - BufferPos)
            BufferPos = BufferEnd
        END IF
    END SELECT
    FilePos& = FileBufferPos& + BufferPos - 1
    IF BufferPos > FileBufferSize THEN
        FileBufferPos& = FilePos&
        GET 1, FileBufferPos&, FileBuffer
        ParseMode = 0
    END IF
RETURN

WriteLine:
    IF NewLine OR LineIndent = 0 THEN
        AdjustedWidth = LineWidth
        NewLine = 0
    ELSE
        AdjustedWidth = LineWidth - LineIndent
        PRINT #2, SPACE$(LineIndent);
        'PRINT STRING$(LineIndent, "ù");
    END IF
    'find last space if longer than line
    IF LEN(TextLine) > AdjustedWidth THEN
        FOR Count = AdjustedWidth + 1 TO 1 STEP -1
            IF MID$(TextLine, Count, 1) = " " THEN EXIT FOR
        NEXT Count
        IF Count THEN
            'PRINT MID$(TextLine, 1, Count - 1); "*"; TAB(LineWidth + 2); "1"
            PRINT #2, MID$(TextLine, 1, Count - 1)
            TextLine = MID$(TextLine, Count + 1)
        ELSE
            'PRINT MID$(TextLine, 1, LineWidth); "*"; TAB(LineWidth + 2); "2"
            PRINT #2, MID$(TextLine, 1, LineWidth)
            TextLine = MID$(TextLine, LineWidth + 1)
        END IF
    ELSE
        'PRINT TextLine$; "*"; TAB(LineWidth + 2); "3"
        PRINT #2, TextLine
        TextLine$ = ""
    END IF
RETURN

WriteLines:
    DO
        GOSUB WriteLine
    LOOP UNTIL LEN(TextLine) = 0
RETURN

FindNextText:
    NextFind = INSTR(BufferPos, FileBuffer, Find$)
    IF NextFind THEN
        IF NextFind < NextBufferPos THEN
            NextBufferPos = NextFind
            NextParseMode = FindParseMode
        END IF
    END IF
RETURN

