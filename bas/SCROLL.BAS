'Simple BASIC Scroll-Array Creator (*.DLL *.COM)

'This program was designed to create "Screen Scroll" machine code arrays
'which can be used to rapidly move a section of text or graphics around on
'the screen so that the entire section does not have to be redrawn. It saves
'time by redrawing only the portion necessary and simply adjusting the old
'part. In a sense, it actually creates a superfast "mini-program".

'Use the "DefScroll" subprogram to define and create the array by giving it
'the four sides (Top, Bottom, Left, Right), the amount to scroll up or down,
'and a background color to fill the newly exposed area of the screen.

'Then to actually execute it, use the "ScrollScrn" sub to run it and move
'the desired portion of the screen around. Since you can reuse that same
'"Scroll-Code" as many times as you need, you only need to create it once.
'You can create other ones for other portions of the screen, or delete the
'old "Scroll-Code" array if do not need it any more. If you would rather
'not use the ScrollScrn sub to work the machine code array then you will have
'to first set the defined segment (DEF SEG) to the segment of the array and
'then call using the CALL or similar statement.

'For this to work in your program though you will have to copy the two SUBS
'DefScroll and ScrollScrn to your program or at least create your own similar
'copies of them. Also, you can save the scroll array to a file *.DLL. You do
'not need to copy the entire DefScroll sub if you instead create the code
'array using this program, view it, and then copy the data to your program;
'however, if your program uses a lot of different and constantly changing
'arrays for the screen then you should just copy the whole sub and not a
'whole boatload of data. Of course, you can remove the extra quotes from it
'if you would like to save program space and memory

'The actual machine code for those interested is as follows:
' MOV AX, absoluteUpOrDown and (6 or 7) ;depending on wether up or down
' MOV CX, leftSide and topLine          ;maximum borders for the section
' MOV DX, rightSide and bottomLine       of screen moved around
' MOV BH, backgroundColor               ;the color left behind
' INT 10                                ;calls the VGA adapter function
' RETURN or RETURNFAR                   ;wether local or far (COM or DLL)

DEFINT A-Z
DECLARE SUB DefScroll (Scroll%(), Row1%, Row2%, Col1%, Col2%, UpDn%, Colr%)
DECLARE SUB ScrollScrn (Scroll%())
DECLARE SUB WaitOnUser (Text$, Keys$, Kbrd$)
DIM Scroll(1 TO 7)

PRINT "Ú" + STRING$(78, 196) + "¿"
PRINT "³" + SPACE$(26) + "Simple scroll code creator" + SPACE$(26) + "³"
PRINT "À" + STRING$(78, 196) + "Ù"

StartMenu:
PRINT
IF ArrayCreated THEN
 WaitOnUser "(C)reate another, (T)est, (S)ave, (V)iew or (E)xit", "TVSCXE", Kbrd$
 SELECT CASE Kbrd$
 CASE "T": GOSUB Test
 CASE "V": GOSUB Viewcode
 CASE "S": GOSUB SaveArray
 END SELECT
ELSE
 WaitOnUser "(C)reate array, or (E)xit", "CXE", Kbrd$
END IF
 SELECT CASE Kbrd$
 CASE "C": GOSUB GetArrayInputs
 CASE "E", "X", "": PRINT : SYSTEM
 END SELECT
GOTO StartMenu

GetArrayInputs:
PRINT
INPUT "Top Line ÄÄÄÄÄ ", Row1
INPUT "Bottom  Line Ä ", Row2
INPUT "Left Column ÄÄ ", Col1
INPUT "Right Column Ä ", Col2
INPUT "Direction, [-?]Up or [+?]Down Ä ", Drct
INPUT "Back Color ÄÄÄ ", Colr
DefScroll Scroll%(), Row1, Row2, Col1, Col2, Drct, Colr
ArrayCreated = -1
PRINT "Array created, choose TEST to use it..."
RETURN

Viewcode:
DEF SEG = VARSEG(Scroll(1)): p = VARPTR(Scroll(1))
PRINT : PRINT "DEC: ";
FOR ViewArray% = 0 TO 12
 PRINT RIGHT$("00" + LTRIM$(STR$(PEEK(p + ViewArray%))) + " ", 4);
NEXT ViewArray%
PRINT "ÄÄÂÄÄ far return here": PRINT "HEX: ";
FOR ViewArray% = 0 TO 12
 PRINT " "; RIGHT$("0" + HEX$(PEEK(p + ViewArray%)) + " ", 3);
NEXT ViewArray%
PRINT "ÄÄÙ"
RETURN

Test:
RANDOMIZE TIMER
CLS : FOR t = 1 TO 920: COLOR TestColr + 1: PRINT "AB"; : TestColr = (TestColr + 1) MOD 15: NEXT t%
COLOR 15: PRINT "Press ENTER to try test, SPACE to restart, ESC to end it";
DO
 SELECT CASE INKEY$
 CASE "": COLOR 7: CLS : RETURN
 CASE CHR$(13): ScrollScrn Scroll%()
  COLOR 15: LOCATE 24, 1: PRINT "Press ENTER to try test, SPACE to restart, ESC to end it";
 CASE " ": GOTO Test
 END SELECT
LOOP
COLOR 7
RETURN

SaveArray:
PRINT : LINE INPUT "Enter FileName or ENTER for none:", file$
IF file$ = "" THEN RETURN
IF INSTR(file$, ".") = 0 THEN file$ = file$ + ".DLL"

FileExists = -1: ON ERROR GOTO SaveNameTrap: OPEN file$ FOR INPUT AS #1: CLOSE #1
IF FileExists THEN
 WaitOnUser "File already exists, Replace it? (Y)es or (N)o", "YN" + CHR$(13), Kbrd$
 IF Kbrd$ = "N" OR Kbrd$ = "" THEN GOTO SaveArray
END IF

SavingIt:
ON ERROR GOTO SaveErrTrap
OPEN file$ FOR OUTPUT AS #1
FOR SaveArray% = 1 TO 6
 PRINT #1, MKI$(Scroll%(SaveArray%));
NEXT SaveArray%
PRINT #1, MID$(MKI$(Scroll%(SaveArray%)), 1, 1);
IF INSTR(UCASE$(file$), ".COM") THEN PRINT #1, CHR$(&HC3);  ELSE PRINT #1, MID$(MKI$(Scroll%(SaveArray%)), 2, 1);
CLOSE #1: ON ERROR GOTO 0
RETURN

SaveErrTrap:
PRINT : PRINT "There was an unexpected file error when trying to write to this file"
PRINT "Make sure it is allowed to be written to by the file operating system"
PRINT "Would you like to retry it or cancel the save operation?"
WaitOnUser "(R)etry or (C)ancel", "RC", Kbrd$
IF Kbrd$ = "R" THEN RESUME SavingIt
RESUME SaveArray

SaveNameTrap:
FilErr = ERR
IF FilErr = 53 THEN FileExists = 0 ELSE IF FilErr THEN PRINT "Bad file name, try again...": RESUME SaveArray
RESUME NEXT

SUB DefScroll (Scroll(), Row1, Row2, Col1, Col2, UpDn, Colr)
p = VARPTR(Scroll(1)): DEF SEG = VARSEG(Scroll(1))
POKE p, &HB8
POKE p + 1, ABS(UpDn)
IF SGN(UpDn) = -1 THEN POKE p + 2, &H6 ELSE POKE p + 2, &H7
POKE p + 3, &HB9 '?
POKE p + 4, Col1 ' Left side
POKE p + 5, Row1 ' Top Line
POKE p + 6, &HBA '?
POKE p + 7, Col2 ' Right Side
POKE p + 8, Row2 ' Bottom Line
POKE p + 9, &HB7 '?
POKE p + 10, Colr'þ Back Color
POKE p + 11, &HCD'?
POKE p + 12, &H10'?
POKE p + 13, &HCB'?
'  0    1    2    3    4    5    6    7    8    9   10   11   12   13
'  ?    ?    ?    ?            ?            ?  color  ?    ?    ?
'&HB8,&H01,&H06,&HB9,&H08,&H05,&HBA,&H0?,&H0?,&HB7,&H09,&HCD,&H10,&HCB
END SUB

DEFSNG A-Z
SUB ScrollScrn (Scroll%())
DEF SEG = VARSEG(Scroll%(1))
CALL Absolute(VARPTR(Scroll%(1)))
END SUB

DEFINT A-Z
SUB WaitOnUser (Text$, Keys$, Kbrd$)
 PRINT Text$;
 DO: Kbrd$ = UCASE$(INKEY$): LOOP UNTIL INSTR(Keys$, Kbrd$) AND Kbrd$ > ""
 KeySpot = INSTR(Text$, "(" + Kbrd$ + ")")
 IF KeySpot THEN LOCATE , 1: PRINT LEFT$(Text$, KeySpot); : COLOR 15: PRINT MID$(Text$, KeySpot + 1, 1): COLOR 7 ELSE PRINT
END SUB

