DECLARE SUB KeyWait ()
DEFINT A-Z

CLS
ON ERROR GOTO ErrHan
OPEN "bintext.com" FOR INPUT AS 1: CLOSE 1
OPEN "bintext.com" FOR BINARY AS 1
  index = LOF(1)
  PRINT index
  REDIM TestCode(0 TO index \ 2)
  FOR index = 1 TO index STEP 2
    GET 1, index, TestCode(index \ 2)
  NEXT index
CLOSE 1
DIM SegRegTable(0 TO 7) 'ip,cs,ds,es,ss,fs,gs

SCREEN 0: COLOR 15, 3: CLS : LOCATE , , 0
PRINT LEN(TestCode)
PRINT VARSEG(TestCode(0)); VARPTR(TestCode(0))
PRINT VARSEG(SegRegTable(0)); VARPTR(SegRegTable(0))
PRINT

'FOR index = 0 TO UBOUND(TestCode)
'  PRINT TestCode(index) AND 255
'  PRINT (TestCode(index) AND (-1 XOR 255)) \ 256
'NEXT index

DEF SEG = VARSEG(TestCode(0))
'test.com
'CALL absolute(BYVAL VARSEG(SegRegTable(0)), BYVAL VARPTR(SegRegTable(0)), VARPTR(TestCode(0)))

DIM SourceString AS STRING * 40, DestString AS STRING * 40
SourceString = STRING$(40, ">")'"Hola world out there, how is ya? :-)"
PRINT SourceString

CALL absolute(BYVAL 24, BYVAL &HB800, BYVAL 0, BYVAL VARSEG(SourceString), BYVAL VARPTR(SourceString), BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 24, BYVAL VARSEG(DestString), BYVAL VARPTR(DestString), BYVAL &HB800, BYVAL 0, BYVAL 1, VARPTR(TestCode(0)))
PRINT DestString
KeyWait
a# = TIMER
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
CALL absolute(BYVAL 65535, BYVAL &HB800, BYVAL 0, BYVAL &HC000, BYVAL 0, BYVAL 0, VARPTR(TestCode(0)))
b# = TIMER
PRINT b# - a#

FOR index = 0 TO 7
  PRINT SegRegTable(index)
NEXT index

END

ErrHan:
  PRINT ERR
  PRINT "Could not load 'test.com'"
  END
RESUME NEXT

SUB KeyWait
PRINT "Press any key to continue"
WHILE INKEY$ = "": WEND
END SUB

