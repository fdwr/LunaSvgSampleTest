DEFINT A-Z

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: SI AS INTEGER: DI AS INTEGER: FLAGS AS INTEGER
DS AS INTEGER: ES AS INTEGER
END TYPE

CONST TotalChars = 256, CharHeight = 8, CharTableBytes = CharHeight * TotalChars
DIM Regs AS RegType, DummyRegs AS RegType, OutputBits AS STRING * CharTableBytes

SCREEN 13

'color attribute must be in bl, length in cx, pointer in bp
'bh is page, always set to zero
Regs.Ax = &H900                 'Print single character
Regs.Bx = 15                    'Color attribute
Regs.Cx = 1                     'Just one character

FOR CurChar = 0 TO 255
  Regs.Ax = &H900 OR CurChar
  CALL interrupt(&H10, Regs, DummyRegs)
  CurCharPos = CurChar * CharHeight + 1
  GOSUB GrabChar
NEXT CurChar

LOCATE 2, 1: PRINT "Total characters grabbed:"; TotalChars
PRINT "Character size: 8x"; LTRIM$(STR$(CharHeight))
PRINT "Byte size of table:"; CharTableBytes

GetFileName:
  LINE INPUT "Output file:", File$
  IF LEN(File$) = 0 THEN END
  ON ERROR GOTO FileErrHandler
  FileError = 0
  OPEN File$ FOR INPUT AS 1
  CLOSE 1
  IF FileError = 0 THEN
    PRINT "Overwrite existing file (Y/N)"
    SLEEP: IF UCASE$(INKEY$) <> "Y" GOTO GetFileName
  END IF
  OPEN File$ FOR OUTPUT AS 1
  ON ERROR GOTO 0
  IF FileError THEN PRINT "Some sort of error trying to open file": GOTO GetFileName

PRINT #1, OutputBits;

END

GrabChar:
  FOR Row = 0 TO CharHeight - 1
    BitLine = 0
    CurBit = 128
    FOR Col = 0 TO 7
      IF POINT(Col, Row) THEN BitLine = BitLine OR CurBit
      CurBit = CurBit \ 2
    NEXT Col
    MID$(OutputBits, CurCharPos) = CHR$(BitLine)
    CurCharPos = CurCharPos + 1
  NEXT Row
RETURN

FileErrHandler:
  FileError = -1
RESUME NEXT

