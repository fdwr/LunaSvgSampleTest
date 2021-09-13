DEFINT A-Z
DECLARE FUNCTION GetLine (inpt$)
DECLARE SUB DefScoll (Scroll(), Row1, Row2, Col1, Col2, UpDn, Colr)
DECLARE SUB ScrollScrn (Scroll())
DECLARE SUB BarSize (Part AS LONG, Total AS LONG, BarWidth, BarLen)

CONST MaxItems = 100
DIM GroupNum AS LONG, GroupSize AS LONG, MaxFileNum AS LONG, MaxFileSize AS LONG

SCREEN 12

'Search for file, show error if not found
'read info from it
' first, number of LineItems, limit to 50
' dimension variables
' second, all individual LineItems
'  name, limit to 16 characters
'  files, must be under 32767
'  keep track of most files
'  byte size, can be double precision
'  keep track of largest byte size
' loop until all is read or 50 LineItems
'determine max
'print all LineItems, show "no LineItems" if there none
'all bars must be relative to maximum extents for particular aspect
'wait for user to press escape for scroll
' check that scroll is not greater than last LineItem
' or less than one

ON ERROR GOTO FilErrHan
FilErr = 0: OPEN "DIRSIZE.TXT" FOR INPUT AS #1: IF FilErr = 0 GOTO OpenSuccess
FilErr = 0: OPEN "C:\DIRSIZE.TXT" FOR INPUT AS #1: IF FilErr = 0 GOTO OpenSuccess
PRINT "Could not find 'dirlist.txt' in the current or root directory..."
PRINT
PRINT "If this list exists in another directory, you can type its location (path)"
PRINT "If no list has been compiled, you need to run 'dirlistx.bas' to make one"
PRINT "Type the location of the list below, or press ENTER to cancel"
DO
 'get location of file
 PRINT : LINE INPUT "Path: "; Path$: IF Path$ = "" THEN END
 FilErr = 0: OPEN Path$ + "\DIRSIZE.TXT" FOR INPUT AS #1: IF FilErr = 0 GOTO OpenSuccess
 PRINT "Could not find it in the specified directory"
LOOP
OpenSuccess:
CLS

ON ERROR GOTO FilErrRead
IF GetLine(inpt$) THEN LineItems = 0
IF GetLine(dirName$) THEN LineItems = 0
LineItems = VAL(LEFT$(inpt$, 2)): IF LineItems > MaxItems THEN LineItems = MaxItems
IF LineItems THEN Last = LineItems - 1 ELSE Last = 0
DIM Names$(0 TO Last), FileNum(0 TO Last) AS LONG, FileSize(0 TO Last) AS LONG, DirMark(0 TO Last)
LineItemOfset = 0: LineItem = 0: ShowItemBar = 1: LineItems = 0
DO UNTIL LineItems >= MaxItems
 IF GetLine(inpt$) THEN EXIT DO
  Names$(LineItems) = LEFT$(inpt$, 12)
 IF GetLine(inpt$) THEN EXIT DO
  IF LEN(inpt$) > 9 THEN FileNum& = 999999999 ELSE FileNum& = VAL(LEFT$(inpt$, 9))
  FileNum(LineItems) = FileNum&: IF FileNum& > MaxFileNum THEN MaxFileNum = FileNum&
 IF GetLine(inpt$) THEN EXIT DO
  IF LEN(inpt$) > 9 THEN FileSize& = 999999999 ELSE FileSize& = VAL(LEFT$(inpt$, 9))
  FileSize(LineItems) = FileSize&: IF FileSize& > MaxFileSize THEN MaxFileSize = FileSize&
 LineItems = LineItems + 1
LOOP
CLOSE #1
ON ERROR GOTO 0

DIM ScrollItemsUp(0 TO 6), ScrollItemsDown(0 TO 6)
DefScoll ScrollItemsDown(), 3, 29, 0, 79, 1, 0
DefScoll ScrollItemsUp(), 3, 29, 0, 79, -1, 0

GOSUB ShowAllItems
GOSUB ShowLineInfo
LOCATE 2, 1: COLOR 15: PRINT "List of directories for "; LEFT$(dirName$, 80);
DO
 SELECT CASE INKEY$
 CASE CHR$(27): EXIT DO
 CASE CHR$(0) + "H": IF LineItem > 0 THEN NewLineItem = LineItem - 1: GOSUB CheckShiftSelect: GOSUB ChangeLineItem
 CASE CHR$(0) + "P": IF LineItem < LineItems - 1 THEN NewLineItem = LineItem + 1: GOSUB CheckShiftSelect: GOSUB ChangeLineItem
 CASE CHR$(0) + "G": IF LineItem > 0 THEN NewLineItem = 1: GOSUB ChangeLineItem
 CASE CHR$(0) + "O": IF LineItem < LineItems - 1 THEN IF LineItems = 0 THEN NewLineItem = 0 ELSE NewLineItem = LineItems - 1
  GOSUB ChangeLineItem
 CASE CHR$(0) + "K": ShowItemBar = (ShowItemBar + 2) MOD 3: GOSUB ShowLineInfo: GOSUB ShowAllItems: DO UNTIL INP(96) <> 75: k$ = INKEY$: LOOP
 CASE CHR$(0) + "M": ShowItemBar = (ShowItemBar + 1) MOD 3: GOSUB ShowLineInfo: GOSUB ShowAllItems: DO UNTIL INP(96) <> 77: k$ = INKEY$: LOOP
 CASE CHR$(13): DirMark(LineItem) = DirMark(LineItem) XOR 1
  IF DirMark(LineItem) AND 1 THEN GroupSize = GroupSize + FileSize(LineItem): GroupNum = GroupNum + FileNum(LineItem) ELSE GroupSize = GroupSize - FileSize(LineItem): GroupNum = GroupNum - FileNum(LineItem)
  GOSUB ShowLineInfo: ShowItem = LineItem: GOSUB ShowLineItem
  DO UNTIL INP(96) <> 28: k$ = INKEY$: LOOP
 END SELECT
LOOP

END

CheckShiftSelect:
 DEF SEG = 0
 IF (PEEK(1047) AND 3) AND DirMark(NewLineItem) <> DirMark(LineItem) THEN
  DirMark(NewLineItem) = DirMark(LineItem)
  IF DirMark(NewLineItem) AND 1 THEN GroupSize = GroupSize + FileSize(NewLineItem): GroupNum = GroupNum + FileNum(NewLineItem) ELSE GroupSize = GroupSize - FileSize(NewLineItem): GroupNum = GroupNum - FileNum(NewLineItem)
 END IF
RETURN

ShowAllItems:
FOR ShowItem = LineItemOfset TO LineItemOfset + 26
 GOSUB ShowLineItem
NEXT ShowItem
RETURN

ChangeLineItem:
 ShowItem = LineItem: LineItem = NewLineItem: GOSUB ShowLineInfo
 OfsetChng = LineItem - LineItemOfset

 IF LineItem < LineItemOfset THEN
  LineItemOfset = LineItem
  IF OfsetChng = -1 THEN ScrollScrn ScrollItemsDown()
 ELSEIF OfsetChng > 26 THEN
  LineItemOfset = LineItem - 26
  IF OfsetChng = 27 THEN ScrollScrn ScrollItemsUp()
 END IF
 IF OfsetChng < -1 OR OfsetChng > 27 THEN GOSUB ShowAllItems ELSE GOSUB ShowLineItem: ShowItem = NewLineItem: GOSUB ShowLineItem
RETURN

ShowLineInfo:
 LOCATE 1, 1: COLOR 15
 IF LineItem > LineItems - 1 THEN PRINT "No LineItems"; TAB(80); : RETURN
 IF DirMark(LineItem) THEN
  FileSize& = GroupSize: FileNum& = GroupNum: PRINT "Group select";
 ELSE
  FileSize& = FileSize(LineItem): FileNum& = FileNum(LineItem): PRINT "Individual  ";
 END IF
 LOCATE , 13
 IF ShowItemBar > 0 THEN COLOR 12: PRINT FileNum&; "files";
 IF ShowItemBar < 2 THEN COLOR 9: PRINT TAB(31); FileSize&; "bytes"; TAB(51); FileSize& \ 1048576; "Megabyte(s)";
 PRINT TAB(80);
RETURN

ShowLineItem:
'determine the actual screen line the item
 IF ShowItem > LineItems - 1 THEN RETURN
 ShowItemLine = ShowItem - LineItemOfset
 IF ShowItemLine < 0 OR ShowItemLine > 26 THEN RETURN
 IF DirMark(ShowItem) THEN TextColor = 5: BackColor = 7 ELSE TextColor = 7: BackColor = 0
 IF ShowItem = LineItem THEN TextColor = TextColor + 8: BarColor = 8 ELSE BarColor = 0

 COLOR TextColor: LOCATE ShowItemLine + 4, 1: PRINT LEFT$(Names$(ShowItem) + SPACE$(12), 12);
 BarRow = ShowItemLine * 16 + 47
 IF ShowItemBar > 0 AND MaxFileNum THEN
  BarSize FileNum(ShowItem), MaxFileNum, 536, BarLen: BarLen = BarLen - 1
  IF BarLen >= 0 THEN LINE (104, BarRow + 1)-(104 + BarLen, BarRow + 6), 4 + BarColor, BF
  LINE (104 + BarLen, BarRow + 1)-(638, BarRow + 6), 0, BF
 ELSE LINE (104, BarRow + 1)-(639, BarRow + 6), 0, BF
 END IF
 IF ShowItemBar < 2 AND MaxFileSize THEN
  BarSize FileSize(ShowItem), MaxFileSize, 536, BarLen: BarLen = BarLen - 1
  IF BarLen >= 0 THEN LINE (104, BarRow + 7)-(104 + BarLen, BarRow + 12), 1 + BarColor, BF
  LINE (104 + BarLen, BarRow + 7)-(638, BarRow + 12), 0, BF
 ELSE LINE (104, BarRow + 7)-(638, BarRow + 12), 0, BF
 END IF
 LINE (103, BarRow)-(639, BarRow + 13), BackColor, B
RETURN

FilErrHan:
FilErr = ERR
RESUME NEXT

FilErrRead:
CLS
PRINT "Error occured while reading file:"; STR$(ERR)
PRINT "Ending program"
END
RESUME NEXT

SUB BarSize (Part AS LONG, Total AS LONG, BarWidth, BarLen)

IF Part < 2147483647 \ Total THEN
 BarLen = (BarWidth * Part) \ Total
ELSE
 BarLen = (Part / Total) * BarWidth
END IF

END SUB

SUB DefScoll (Scroll(), Row1, Row2, Col1, Col2, UpDn, Colr)
P = VARPTR(Scroll(0)): DEF SEG = VARSEG(Scroll(0))
POKE P, &HB8
POKE P + 1, ABS(UpDn)
IF SGN(UpDn) = -1 THEN POKE P + 2, &H6 ELSE POKE P + 2, &H7
POKE P + 3, &HB9 'mov ax
POKE P + 4, Col1 ' Left side
POKE P + 5, Row1 ' Top Line
POKE P + 6, &HBA 'mov bx
POKE P + 7, Col2 ' Right Side
POKE P + 8, Row2 ' Bottom Line
POKE P + 9, &HB7 'mov cx
POKE P + 10, Colr'þ Back Color
POKE P + 11, &HCD'int
POKE P + 12, &H10'bios call
POKE P + 13, &HCB'retf
'  0    1    2    3            ?            9  color 11   12   13
'&HB8,&H01,&H06,&HB9,&H08,&H05,&HBA,&H0?,&H0?,&HB7,&H09,&HCD,&H10,&HCB
END SUB

FUNCTION GetLine (inpt$)
IF EOF(1) THEN GetLine = 1: inpt$ = "" ELSE LINE INPUT #1, inpt$
END FUNCTION

SUB ScrollScrn (Scroll())
DEF SEG = VARSEG(Scroll(0)): CALL absolute(VARPTR(Scroll(0)))
END SUB

