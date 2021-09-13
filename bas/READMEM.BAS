'very cheap program designed to read four bytes anywhere in 32bit memory
'no practical user interface, it's really just a test program, so far it
'seems to work though!!
DEFINT A-Z

CONST ReadMemoryFile$ = "fastshow.com"
DIM SHARED ReadMemory$

OPEN ReadMemoryFile$ FOR INPUT AS 1: CLOSE 1
OPEN ReadMemoryFile$ FOR BINARY AS 1: ReadMemory$ = INPUT$(LOF(1), 1): CLOSE 1

IF LEN(ReadMemory$) = 0 THEN
  PRINT "What happened to 'readmem.com'...it is needed for this program to work."
  END
END IF

LINE INPUT "Memory address to be read:", text$
IF text$ = "" THEN END
address& = VAL(text$)

DEF SEG = VARSEG(ReadMemory$)
CALL absolute(BYVAL address&, SADD(ReadMemory$))
'CALL absolute(SEG memdata&, BYVAL address&, SADD(ReadMemory$))

PRINT "Data at address"; address&; "is:"; memdata&
text$ = MKL$(memdata&)
FOR byte = 1 TO 4
  PRINT ASC(MID$(text$, byte, 1));
NEXT byte
PRINT

END

