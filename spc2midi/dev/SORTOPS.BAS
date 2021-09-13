'1999.7.17
DEFINT A-Z

DIM TextLines$(499), TextLineValues(499)

OPEN "miscops.txt" FOR INPUT AS 1
OPEN "sortops.txt" FOR OUTPUT AS 2

'read in all lines
TotalLines = 0
DO UNTIL EOF(1)
    LINE INPUT #1, TextLines$(TotalLines)
    IF LEN(TextLines$(TotalLines)) THEN TotalLines = TotalLines + 1
LOOP
PRINT "Total of"; TotalLines; "lines read in"
   
PRINT "Reading opcode values..."
FOR CurLine = 0 TO TotalLines - 1
    TextLine$ = TextLines$(CurLine)
    CommentPos = INSTR(TextLine$, ";")
    IF CommentPos THEN
        StartPos = CommentPos + 1
        DO UNTIL StartPos > LEN(TextLine$) OR MID$(TextLine$, StartPos, 1) <> " "
            StartPos = StartPos + 1
        LOOP
        NextPos = INSTR(StartPos, TextLine$, " ")
        IF NextPos THEN
            OpcodeValue = VAL("&H" + MID$(TextLine$, StartPos, NextPos - StartPos))
        ELSE
            OpcodeValue = VAL("&H" + MID$(TextLine$, StartPos))
        END IF
        TextLineValues(CurLine) = OpcodeValue
        TextLines$(CurLine) = LEFT$(TextLine$, CommentPos) + " " + RIGHT$("0" + HEX$(OpcodeValue), 2)
    ELSE
        TextLineValues(CurLine) = -1
    END IF
NEXT CurLine

PRINT "Sorting..."
OpcodeValue = 0
DO UNTIL TotalLines <= 0
    FOR CurLine = 0 TO TotalLines - 1
        IF TextLineValues(CurLine) = OpcodeValue GOTO OpcodeMatch
    NEXT CurLine
    OpcodeValue = OpcodeValue + 1
    GOTO BtmOfSortLoop
OpcodeMatch:
    OpcodeValue = OpcodeValue + 1
    PRINT #2, TextLines$(CurLine)
    TotalLines = TotalLines - 1
    TextLines$(CurLine) = TextLines$(TotalLines)
    TextLineValues(CurLine) = TextLineValues(TotalLines)
    TextLines$(TotalLines) = ""
BtmOfSortLoop:
    IF OpcodeValue > 255 OR INKEY$ = CHR$(27) THEN EXIT DO
LOOP

PRINT "Remaining"; TotalLines; "lines"
FOR CurLine = 0 TO TotalLines - 1
    PRINT #2, TextLines$(CurLine)
NEXT CurLine

CLOSE 1, 2

