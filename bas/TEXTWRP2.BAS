'Wrap Text, by FDwR 7-25-99
DEFINT A-Z

CONST TextLinesBufferSize = 4096
CONST LineFindNextStop = 0, LineFindTextEnd = 2, LineFindCr = 3, LineFindTagOpen = 4, LineFindTagClose = 5
DIM TextLinesBuffer AS STRING * TextLinesBufferSize

LineEndChar$ = CHR$(13)
LineWrap = 76

CLS
GOSUB GetFilenames
IF SourceFile$ = DestFile$ THEN
    PRINT "Source and destination must be different."
    END
END IF

OPEN SourceFile$ FOR INPUT AS 1: CLOSE 1
OPEN SourceFile$ FOR BINARY AS 1
OPEN DestFile$ FOR OUTPUT AS 2

SourceFileLeng& = LOF(1)
SourceFilePos& = 1

LineChars = 0

DO
    GOSUB OutputBufferLines
LOOP UNTIL LEN(INKEY$) OR SourceFilePos& > SourceFileLeng&

CLOSE 1, 2

END

GetFilenames:
    SourceFile$ = COMMAND$ + ".wwt"
    DestFile$ = COMMAND$ + ".txt"
RETURN

OutputBufferLines:
    BufferPos = 1
    IF LineWrap < 1 THEN LineWrap = 80
    IF SourceFilePos& + TextLinesBufferSize > SourceFileLeng& THEN
        BufferEnd = SourceFileLeng& - SourceFilePos& + 1
    ELSE
        BufferEnd = TextLinesBufferSize
    END IF

    LOCATE , 1: PRINT SourceFilePos&;
    SearchingFor = LineFindNextStop
    GET #1, SourceFilePos&, TextLinesBuffer
    DO
        SELECT CASE SearchingFor
        CASE LineFindTextEnd
            IF LineChars >= LineWrap THEN
                'search for end of line
                'output text line without spaces
                '
                LineCheckPos = LEN(TextLine$)
                DO UNTIL LineCheckPos < 1
                    IF MID$(TextLine$, LineCheckPos, 1) = " " THEN EXIT DO ELSE LineCheckPos = LineCheckPos - 1
                LOOP
                IF LineCheckPos < 1 THEN    'no space was found
                    'COLOR 12: PRINT TextLine$
                    PRINT #2, TextLine$
                    TextLine$ = ""
                    LineChars = 0
                ELSE
                    'abc defgh*ijklm
                    'COLOR 12: PRINT RTRIM$(LEFT$(TextLine$, LineCheckPos))
                    PRINT #2, RTRIM$(LEFT$(TextLine$, LineCheckPos))
                    TextLine$ = MID$(TextLine$, LineCheckPos + 1)
                    LineChars = LEN(TextLine$)
                END IF
            END IF
            BufferLineEnd = BufferPos + LineWrap - LineChars
            IF BufferLineEnd >= BufferNextStop THEN
                'COLOR 9: PRINT MID$(TextLinesBuffer, BufferPos, BufferNextStop - BufferPos);
                TextLine$ = TextLine$ + MID$(TextLinesBuffer, BufferPos, BufferNextStop - BufferPos)
                'temporary
                IF BufferNextStop < BufferEnd THEN
                    'COLOR 12: PRINT : PRINT TextLine$
                    PRINT #2, TextLine$
                    TextLine$ = ""
                    LineChars = 0
                    SearchingFor = LineFindCr
                ELSE
                    'COLOR 12: PRINT TextLine$;
                    'PRINT #2, TextLine$;
                    LineChars = LEN(TextLine$)
                END IF
                BufferPos = BufferNextStop
            ELSE
                'COLOR 9: PRINT MID$(TextLinesBuffer, BufferPos, BufferLineEnd - BufferPos);
                TextLine$ = TextLine$ + MID$(TextLinesBuffer, BufferPos, BufferLineEnd - BufferPos)
                'IF INSTR(TextLine$, "does not intend") THEN STOP
                LineChars = LEN(TextLine$)
                BufferPos = BufferLineEnd
            END IF
        CASE LineFindNextStop
            BufferNextStop = INSTR(BufferPos, TextLinesBuffer, LineEndChar$)
            IF BufferNextStop = 0 OR BufferNextStop > BufferEnd THEN
                BufferNextStop = BufferEnd + 1
            END IF
            SearchingFor = LineFindTextEnd
        CASE LineFindCr
            BufferPos = BufferPos + 2
            SearchingFor = LineFindNextStop
        'CASE LineFindTagClose
        END SELECT
    LOOP UNTIL BufferPos >= BufferEnd
    'if insidebracket
    'instr(TextLinesBuffer,"<")
    'else
    'instr(TextLinesBuffer,">")
    'PRINT #2, TextLinesBuffer;
    SourceFilePos& = SourceFilePos& + TextLinesBufferSize
RETURN

