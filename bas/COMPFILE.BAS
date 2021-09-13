'4-10-98 1836 Scrolling, paging, and jumping included
'4-22-98 2922 Support added to open any user specified file
DEFINT A-Z

Mode$ = "First"
GOSUB GetFileName
FirstFile$ = File$
Mode$ = "Second"
GOSUB GetFileName
SecondFile$ = File$

OPEN FirstFile$ FOR BINARY AS 1
OPEN SecondFile$ FOR BINARY AS 2

CLS
LOCATE , , 0

file1leng& = LOF(1): file2leng& = LOF(2)
IF file1leng& > file2leng& THEN longerfileleng& = file1leng& ELSE longerfileleng& = file2leng&
GOSUB ShowFileSizes

byte$ = " "
row = 0
rows = 24
bytepos& = 1

DO
  IF rows > 0 THEN
    LOCATE row + 2, 1
    recordnum& = bytepos& + row
    PRINT recordnum&; TAB(22);
    IF recordnum& <= file1leng& THEN
      GET 1, recordnum&, byte$
      byte = ASC(byte$)
      PRINT byte, HEX$(byte);
    END IF
    IF recordnum& <= file2leng& THEN
      GET 2, recordnum&, byte$
      byte2 = ASC(byte$)
      IF byte <> byte2 THEN PRINT TAB(41); "û";
      PRINT TAB(51); byte2, HEX$(byte2);
    END IF
    PRINT TAB(80);
    IF row >= 23 THEN row = 0 ELSE row = row + 1
    rows = rows - 1
  END IF

  SELECT CASE INKEY$
  CASE CHR$(0) + "H": IF bytepos& > 1 THEN bytepos& = bytepos& - 1: rows = 24
  CASE CHR$(0) + "P": IF bytepos& < longerfileleng& THEN bytepos& = bytepos& + 1: rows = 24
  CASE CHR$(0) + "I": IF bytepos& > 1 THEN bytepos& = bytepos& - 25: rows = 24: IF bytepos& < 1 THEN bytepos& = 1
  CASE CHR$(0) + "Q": IF bytepos& < longerfileleng& THEN bytepos& = bytepos& + 25: rows = 24: IF bytepos& > longerfileleng& THEN bytepos& = longerfileleng&
  CASE CHR$(13): GOSUB GetNewPosition: GOSUB ShowFileSizes
  CASE CHR$(27): EXIT DO
  END SELECT
LOOP

'CLOSE 1, 2 'This line is commented out because in Qbasic it is not necessary
            'to close the files manually, since the upcoming SYSTEM statement
            'does it for me.

EndProgram:
LOCATE 25, 1
PRINT

SYSTEM

ShowFileSizes:
 LOCATE 1, 1: PRINT "Record number"; TAB(20);
 PRINT RIGHT$(FirstFile$, 12) + " is"; file1leng&; "bytes"; TAB(49);
 PRINT RIGHT$(SecondFile$, 12) + " is"; file2leng&; "bytes"; TAB(80);
RETURN

GetNewPosition:
 LOCATE 1, 1: PRINT TAB(80);
 LOCATE 1, 1: LINE INPUT "File position:", position$
 position& = VAL(position$)
 IF position& = 0 THEN RETURN
 IF position& > longerfileleng& THEN position& = longerfileleng&
 bytepos& = position&
 rows = 25
RETURN

GetFileName:
'Gets filename from user and verifies that it exists
'Fully functional file listing and directory changing abilities
  PRINT Mode$ + " file:";
  LINE INPUT File$
  IF File$ = "" THEN END'GOTO EndProgram
  File$ = UCASE$(LTRIM$(File$))
  IF INSTR(File$, "*") THEN SHELL "DIR " + File$: GOTO GetFileName
  ON ERROR GOTO FileErrorHandler
  FileError = 0: CHDIR File$
  IF FileError = 0 THEN PRINT "Directory changed": GOTO GetFileName
  TestForExist = FREEFILE
  FileError = 0: OPEN File$ FOR INPUT AS TestForExist: CLOSE TestForExist
  IF FileError THEN
    PRINT "Can not open that file, check the spelling"
    PRINT "Type *.* to get a listing of available files"
    GOTO GetFileName
  END IF
  ON ERROR GOTO 0
RETURN

FileErrorHandler:
  FileError = ERR
RESUME NEXT

