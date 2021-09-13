'HexData
'Dwayne Robinson
'2001-02-17
'
'simply reads a file and prints the bytes a hex numbers.
'you can use redirection.
DEFINT A-Z

DIM FilePos AS LONG
DIM Byte AS STRING * 1
DIM Word AS INTEGER

'FilePos = &HC0F64'&H147EA
PrintWords = -1

InFile$ = COMMAND$
IF LEN(InFile$) THEN
    ON ERROR GOTO ErrorHandler
    OPEN InFile$ FOR INPUT AS 1: CLOSE 1
    IF ErrorHandled THEN PRINT "Could not open input file.": END
    OPEN InFile$ FOR BINARY AS 1
    ON ERROR GOTO 0

    NumbersToPrint = LOF(1)
    SEEK 1, FilePos + 1
    IF PrintWords THEN
        NumbersToPrint = (NumbersToPrint + 1) \ 2
        FOR Count = 1 TO NumbersToPrint
            GET 1, , Word
            IF (Count AND 7) THEN IF Count < NumbersToPrint THEN Sep$ = "," ELSE Sep$ = "" ELSE Sep$ = CHR$(13)
            Text$ = "&H" + RIGHT$("000" + HEX$(Word), 4) + Sep$
            PRINT Text$;
        NEXT
    ELSE
        FOR Count = 1 TO NumbersToPrint
            GET 1, , Byte
            'IF (Count AND 15) = 0 THEN Sep$ = CHR$(13) + CHR$(10) ELSE IF Count < NumbersToPrint THEN Sep$ = "," ELSE Sep$ = ""
            IF (Count AND 15) THEN IF Count < NumbersToPrint THEN Sep$ = "," ELSE Sep$ = "" ELSE Sep$ = CHR$(13)
            Text$ = "&H" + RIGHT$("0" + HEX$(ASC(Byte)), 2) + Sep$
            PRINT Text$;
        NEXT
    END IF

    CLOSE 1
ELSE
    PRINT "No file was given to export hex data from."
END IF
END

ErrorHandler:
    ErrorHandled = ERR
RESUME NEXT

