'File Character Count
'Dwayne Robinson
'2004-04-11
'Counts the number of byte values in a file
DEFINT A-Z

CONST BufSize = 4096

DIM file AS STRING
DIM buffer AS STRING * BufSize
DIM vals(256) AS LONG
DIM fpos AS LONG, flen AS LONG
DIM max AS LONG
DIM min AS LONG

DIM keypress AS STRING

WIDTH 80, 50
VIEW PRINT 1 TO 50

'LINE INPUT "File:"; file
'IF LEN(file) <= 0 THEN END

'file = "CSUMFNAM.EXE"
'file = "D:\pic\acg\hanpen~1\puu-13.jpk"
'file = "C:\WINDOWS\SYSTEM32\SHELL32.DLL"
'file = "D:\DESKTOP\CS372P~1.PDF"
'file = "d:\music\audio\techno\trance~1.mp3"
'file = "C:\WINDOWS\SYSTEM32\PROGMAN.EXE"
'file = "d:\video\outlaw~1.avi"
file = "d:\video\startr~1.mpg"

CLS

OPEN file FOR INPUT AS 1: CLOSE 1
OPEN file FOR BINARY AS 1
fpos = 0
flen = LOF(1)
DO UNTIL EOF(1)
    GET 1, , buffer
    FOR count = 1 TO BufSize
        char = ASC(MID$(buffer, count, 1))
        vals(char) = vals(char) + 1
    NEXT
    LOCATE , 1
    fpos = fpos + BufSize
    PRINT fpos; "/"; flen;
    IF INKEY$ = CHR$(27) THEN EXIT DO
LOOP
CLOSE 1

''''''''''''''''''''

CLS
col = 1
row = 1
FOR char = 0 TO 255
    LOCATE row, col
    PRINT char; "="; vals(char);
    row = row + 1
    IF row > 50 THEN
        row = 1
        col = col + 13
    END IF
NEXT

DO UNTIL LEN(INKEY$): LOOP

''''''''''''''''''''
SCREEN 13
max = 0
min = 32767
FOR char = 0 TO 255
    IF vals(char) > max THEN max = vals(char): maxchar = char
    IF vals(char) < min THEN min = vals(char): minchar = char
NEXT
'OUT &H3C8, 1
'FOR char = 1 TO 255
'    OUT &H3C9, (char \ 21) + 26
'    OUT &H3C9, (char \ 35) + 20
'    OUT &H3C9, (char \ 8) + 32
'NEXT
FOR char = 0 TO 255
    GOSUB DrawCharVal
NEXT
LOCATE 1, 1: PRINT minchar; TAB(10);

DO
    keypress = INKEY$
    IF LEN(keypress) THEN
        SELECT CASE keypress
        CASE CHR$(27): EXIT DO
        CASE CHR$(0) + "M":
            seldif = 1
            GOSUB MoveSelVal
        CASE CHR$(0) + "K":
            seldif = -1
            GOSUB MoveSelVal
        CASE CHR$(0) + "H":
            seldif = 16
            GOSUB MoveSelVal
        CASE CHR$(0) + "P":
            seldif = -16
            GOSUB MoveSelVal
        END SELECT
    END IF
LOOP


END

MoveSelVal: '(seldif)
    char = selchar
    selchar = (selchar + seldif) AND 255
    GOSUB DrawCharVal
    char = selchar
    GOSUB DrawCharVal
    LOCATE 1, 1: PRINT selchar; "="; vals(selchar); TAB(20);
RETURN

DrawCharVal: '(char, max, vals)
    clr = 9
    IF char = selchar THEN
        clr = 15
    ELSEIF char = minchar THEN
        clr = 12
    END IF
    LINE (char, 199)-(char, 199 - vals(char) * 200& \ max), clr
RETURN

