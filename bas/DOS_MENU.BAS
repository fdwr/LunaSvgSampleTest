DEFINT A-Z

'Sub and function declarations
DECLARE SUB Center (row%, Text$)
DECLARE SUB FancyCls (dots%, Background%)
DECLARE SUB Box (Urow%, Lcol%, Drow%, Rcol%, Fore, Back, Side, Titl$)
DECLARE SUB PictureDraw (Hite%, Widt%, Ulin%, Lcol%, Pict$, PictDims AS ANY)
DECLARE SUB PictureSnap (Hite%, Widt%, Urow%, Lcol%, Pict$, PictDims AS ANY)

DECLARE SUB Initialize ()
DECLARE SUB MenuSystem ()
DECLARE SUB PrintHelpLine (Help$)
DECLARE SUB Execute (Mode%, DATA$)
DECLARE FUNCTION Menu% (StartChoice%, MaxChoice%, Choice$(), ItemRow%(), ItemCol%(), Help$(), SubMenu%(), BarMode%)

'Constants
CONST TRUE = -1
CONST FALSE = NOT TRUE

TYPE Picture
Hite AS INTEGER
Widt AS INTEGER
Lcol AS INTEGER
Urow AS INTEGER
Rcol AS INTEGER
Drow AS INTEGER
END TYPE

'Global variables
DIM SHARED ColorPref
DIM SHARED colors(0 TO 20, 1 TO 4)
DIM SHARED Pictures$(7)
DIM SHARED MenuDims(7) AS Picture
DIM SHARED Pics

'Start program
    Initialize
    MenuSystem
    END

' Error handler for program
ErrorTrap:
  SELECT CASE ERR
    CASE ELSE
  END SELECT
  RESUME NEXT

'The following data defines the color schemes available via the main menu.
'    scrn  dots  bar  back   title  shdow  choice  curs   cursbk  shdow
DATA 0,    7,    15,  7,     0,     7,     0,      15,    0,      0
DATA 1,    9,    12,  3,     0,     1,     15,     0,     7,      0
DATA 3,    15,   13,  1,     14,    3,     15,     0,     7,      0
DATA 7,    12,   15,  4,     14,    0,     15,     15,    1,      0

SUB Box (row1, col1, row2, col2, Fore, Back, Side, Titl$)

IF row1 > row2 THEN SWAP row1, row2: Chng = Chng XOR 1
IF col1 > col2 THEN SWAP col1, col2: Chng = Chng XOR 2
COLOR Fore, Back: BoxWidth = col2 - col1 + 1

IF (Side AND 256) AND col1 < col2 THEN FOR Vset = row1 + 1 TO row2 - 1: LOCATE Vset, col1 + 1: PRINT SPACE$(BoxWidth - 2); : NEXT Vset
IF Side AND 1 THEN LOCATE row1, col1: PRINT "Ú";
IF Side AND 2 THEN LOCATE row1, col2: PRINT "¿";
IF Side AND 4 THEN LOCATE row2, col1: PRINT "À";
IF Side AND 8 THEN LOCATE row2, col2: PRINT "Ù";
IF Side AND 16 THEN IF col1 = col2 THEN LOCATE row1, col1: PRINT "Â";  ELSE LOCATE row1, col1 + 1: PRINT STRING$(BoxWidth - 2, "Ä");
IF Side AND 32 THEN IF col1 = col2 THEN LOCATE row2, col1: PRINT "Á";  ELSE LOCATE row2, col1 + 1: PRINT STRING$(BoxWidth - 2, "Ä");
IF Side AND 64 THEN IF row1 = row2 THEN LOCATE row1, col1: PRINT "Ã";  ELSE FOR Vset = row1 + 1 TO row2 - 1 STEP 1: LOCATE Vset, col1: PRINT "³"; : NEXT Vset
IF Side AND 128 THEN IF row1 = row2 THEN LOCATE row1, col2: PRINT "´";  ELSE FOR Vset = row1 + 1 TO row2 - 1 STEP 1: LOCATE Vset, col2: PRINT "³"; : NEXT Vset
'IF Side AND 16 THEN FOR Hset = Col1 + 1 TO Col2 - 1: LOCATE Row1, Hset: PRINT "Ä"; : NEXT Hset
'IF Side AND 32 THEN FOR Hset = Col1 + 1 TO Col2 - 1: LOCATE Row2, Hset: PRINT "Ä"; : NEXT Hset

IF Chng AND 1 THEN LOCATE row2 ELSE LOCATE row1
LOCATE , col1 + (BoxWidth - LEN(LEFT$(Titl$, BoxWidth))) / 2: PRINT LEFT$(Titl$, BoxWidth);
IF Chng AND 1 THEN SWAP row1, row2
IF Chng AND 2 THEN SWAP col1, col2

END SUB

DEFSNG A-Z
SUB Center (row%, Text$)
 LOCATE row%, 41 - LEN(Text$) / 2
 PRINT Text$;
END SUB

DEFINT A-Z
SUB Execute (Mode, DATA$) STATIC
IF DosLin <= 0 THEN DosLin = 25
IF DosCol <= 0 THEN DosCol = 1

IF Mode THEN
PCOPY 1, 0: IF DATA$ > "" THEN LOCATE 25, 1: COLOR colors(2, ColorPref), 0: PRINT SPACE$(80); : LOCATE DosLin, DosCol: SHELL DATA$: DosLin = CSRLIN: DosCol = POS(0): PCOPY 0, 1
ELSE
PCOPY 0, 1: COLOR colors(7, ColorPref), colors(4, ColorPref)
END IF
END SUB

SUB FancyCls (dots, Background)

  VIEW PRINT 2 TO 24
  COLOR dots, Background
  CLS 2

  FOR a = 95 TO 1820 STEP 45
    row = a / 80 + 1
    col = a MOD 80 + 1
    LOCATE row, col
    PRINT CHR$(250);
  NEXT a

  VIEW PRINT

END SUB

DEFSNG A-Z
SUB Initialize

 SCREEN 0
 WIDTH 80, 25
 VIEW PRINT

 FOR ColorSet% = 1 TO 4
  FOR X% = 1 TO 10
   READ colors%(X%, ColorSet%)
  NEXT X%
 NEXT ColorSet%
 ColorPref% = 2

END SUB

DEFINT A-Z
FUNCTION Menu (StartChoice, MaxChoice, Choice$(), ItemRow(), ItemCol(), Help$(), SubMenu(), BarMode)
CurrChoice = StartChoice: COLOR colors(7, ColorPref), colors(4, ColorPref)

IF Pics >= SubMenu(0) AND Pics > 0 THEN IF ItemRow(MaxChoice) - ItemRow(1) + 4 = MenuDims(Pics - 1).Hite OR BarMode THEN TheSame = TRUE: Pics = Pics - 1 ELSE PictureDraw 0, 0, 0, 0, Pictures$(Pics - 1), MenuDims(Pics - 1): Pics = Pics - 1

GOSUB DesignMenu

SELECT CASE CurrChoice
 CASE IS > 0
  IF SubMenu(CurrChoice) = TRUE THEN Pics = Pics + 1 ELSE IF SubMenu(CurrChoice) = 1 AND Pics > 0 THEN DO: PictureDraw 0, 0, 0, 0, Pictures$(Pics), MenuDims(Pics): Pictures$(Pics) = "": Pics = Pics - 1: LOOP UNTIL Pics = -1: Pics = 0 ELSE PictureDraw 0, 0, 0, 0, Pictures$(Pics), MenuDims(Pics): Pictures$(Pics) = ""
 CASE 0: PictureDraw 0, 0, 0, 0, Pictures$(Pics), MenuDims(Pics): Pictures$(Pics) = ""
END SELECT

Menu = CurrChoice
EXIT FUNCTION

DesignMenu:
IF BarMode THEN
 Bar = 0
 FOR a = 1 TO MaxChoice
  IF SubMenu(a) AND 16 THEN Bar = Bar + 1
  ItemCol(a) = Bar + 2
  ItemRow(a) = ItemRow(1)
  Bar = Bar + LEN(Choice$(a)) + 2
 NEXT a
 IF NOT TheSame THEN PictureSnap 1, 80, 0, 0, Pictures$(Pics), MenuDims(Pics)
 LOCATE ItemRow(1), 1: PRINT SPACE$(80);
ELSE
 FOR a = 1 TO MaxChoice
  IF LEN(Choice$(a)) > MaxLen THEN MaxLen = LEN(Choice$(a))
 NEXT a
 MaxBar = 0
 FOR a = 2 TO MaxChoice
  IF SubMenu(a) AND 16 THEN MaxBar = MaxBar + 2 ELSE MaxBar = MaxBar + 1
  ItemRow(a) = MaxBar + ItemRow(1)
 NEXT a
 IF NOT TheSame THEN PictureSnap ItemRow(MaxChoice) - ItemRow(1) + 4, MaxLen + 6, ItemRow(1) - 2, ItemCol(1) - 2, Pictures$(Pics), MenuDims(Pics)
 Box ItemRow(1) - 1, ItemCol(1) - 1, ItemRow(MaxChoice) + 1, ItemCol(1) + MaxLen + 3, colors(7, ColorPref), colors(4, ColorPref), 511, ""
END IF

COLOR colors(7, ColorPref), colors(4, ColorPref)
FOR a = 1 TO MaxChoice
 Ver = ItemRow(a) - 1: Hor = ItemCol(a) - 1
 IF BarMode THEN Bar$ = " " + Choice$(a) + " " ELSE Bar$ = LEFT$(" " + Choice$(a) + SPACE$(MaxLen + 2), MaxLen + 3)
 IF (SubMenu(a) AND 1) AND NOT BarMode THEN MID$(Bar$, MaxLen + 3, 1) = ""
 IF SubMenu(a) AND 16 THEN IF BarMode THEN LOCATE ItemRow(a), Hor: PRINT "³";  ELSE LOCATE Ver, Hor: PRINT "Ã" + STRING$(MaxLen + 3, "Ä") + "´";
 LOCATE ItemRow(a), ItemCol(a): PRINT Bar$;
NEXT a
 
 finished = FALSE
 Chng = TRUE
 DO UNTIL finished
        
  IF Chng THEN
   GOSUB MenuShowCursor
   PrintHelpLine Help$(CurrChoice)
   Chng = FALSE
  END IF
  LastChoice = CurrChoice
  GOSUB MenuGetKey
 
  SELECT CASE UCASE$(Kbd$)
   CASE CHR$(0) + "H": GOSUB MenuUp
   CASE CHR$(0) + "P": GOSUB MenuDown
   CASE CHR$(0) + "K": GOSUB MenuLeft
   CASE CHR$(0) + "M": GOSUB MenuRight
   CASE CHR$(13): finished = TRUE
   CASE CHR$(27): CurrChoice = 0: finished = TRUE
   CASE " " TO ""
    FOR s = CurrChoice TO MaxChoice + CurrChoice
     IF LEFT$(Choice$(s MOD MaxChoice + 1), 1) = UCASE$(Kbd$) THEN CurrChoice = s MOD MaxChoice + 1: EXIT FOR
    NEXT s
   CASE ELSE
  END SELECT

  IF LastChoice <> CurrChoice THEN GOSUB MenuHideCursor: Chng = TRUE
 LOOP
RETURN

MenuUp:
 IF BarMode THEN
  IF SubMenu(CurrChoice) = TRUE THEN finished = TRUE
 ELSE
  CurrChoice = (CurrChoice + MaxChoice - 2) MOD MaxChoice + 1
  IF Choice$(CurrChoice) = "" THEN CurrChoice = CurrChoice - 1
 END IF
 RETURN

MenuLeft:
 IF BarMode THEN
  CurrChoice = (CurrChoice + MaxChoice - 2) MOD MaxChoice + 1
 END IF
 RETURN

MenuRight:
 IF BarMode THEN
  CurrChoice = (CurrChoice) MOD MaxChoice + 1
 ELSE
  IF SubMenu(CurrChoice) AND 1 THEN finished = TRUE
 END IF
 RETURN

MenuDown:
 IF BarMode THEN
  IF SubMenu(CurrChoice) AND 1 THEN finished = TRUE
 ELSE
  CurrChoice = (CurrChoice) MOD MaxChoice + 1
 END IF
 RETURN

MenuShowCursor:
 COLOR colors(8, ColorPref), colors(9, ColorPref)
 LOCATE ItemRow(CurrChoice), ItemCol(CurrChoice)
 IF NOT BarMode THEN
  Bar$ = LEFT$(" " + Choice$(CurrChoice) + SPACE$(MaxLen + 2), MaxLen + 3)
  IF SubMenu(CurrChoice) AND 1 THEN MID$(Bar$, MaxLen + 3, 1) = ""
  PRINT Bar$;
  COLOR colors(4, ColorPref), colors(9, ColorPref)
  LOCATE ItemRow(CurrChoice), ItemCol(CurrChoice) - 1: PRINT "Ý";
  LOCATE , ItemCol(CurrChoice) + MaxLen + 3: PRINT "Þ";
 ELSE
  PRINT " "; Choice$(CurrChoice); " ";
 END IF
 RETURN

MenuGetKey:
 DO: Kbd$ = UCASE$(INKEY$): LOOP UNTIL Kbd$ > ""
 RETURN

MenuHideCursor:
 COLOR colors(7, ColorPref), colors(4, ColorPref)
 LOCATE ItemRow(LastChoice), ItemCol(LastChoice)
 IF NOT BarMode THEN
  Bar$ = LEFT$(" " + Choice$(LastChoice) + SPACE$(MaxLen + 2), MaxLen + 3)
  IF SubMenu(LastChoice) AND 1 THEN MID$(Bar$, MaxLen + 3, 1) = ""
  PRINT Bar$;
  LOCATE ItemRow(LastChoice), ItemCol(LastChoice) - 1: PRINT "³";
  LOCATE , ItemCol(LastChoice) + MaxLen + 3: PRINT "³";
 ELSE
  PRINT " " + Choice$(LastChoice) + " ";
 END IF
 RETURN

END FUNCTION

SUB MenuSystem

 DIM Choice$(20), MenuRow(0 TO 20), MenuCol(0 TO 20), Help$(20), SubMenu(0 TO 20)
 LOCATE , , 0
 finished = FALSE

 WHILE NOT finished
   GOSUB Choices
   SELECT CASE Choice
   CASE 0: IF Path$ = "" THEN  ELSE Path$ = LEFT$(Path$, LEN(Path$) - 1)
   END SELECT
   FOR d = 1 TO 20: SubMenu(d) = 0: NEXT d
 WEND
EXIT SUB

Choices:
SELECT CASE Path$
CASE ""
 COLOR colors(7, ColorPref), colors(4, ColorPref)
 Choice$(1) = "File"
 Choice$(2) = "View"
 FOR d = 1 TO 2
  MenuRow(d) = 1
  SubMenu(d) = 17
 NEXT d
 MenuRow(0) = 1
 SubMenu(0) = 1
 Help$(1) = "Choose this to do things that pertain to files"
 Help$(2) = "View lets you change the way that you see things"

 IF MainChoice < 1 THEN MainChoice = 1
  Choice = Menu((MainChoice), 2, Choice$(), MenuRow(), MenuCol(), Help$(), SubMenu(), TRUE)
 SELECT CASE Choice
 CASE 1 TO 2: Path$ = LTRIM$(STR$(Choice))
 END SELECT
 IF Choice > 0 THEN MainChoice = Choice

CASE "1"
 Choice$(1) = "Load..."
 Choice$(2) = "Find..."
 Choice$(3) = "Exit"
 FOR d = 1 TO 3: MenuRow(d) = 2 + d: MenuCol(d) = 2: NEXT d
 Help$(1) = "Loads a program that you specify"
 Help$(2) = "Finds all the listings of a file"
 Help$(4) = "Exits the DW DOS Menu"
 SubMenu(0) = 2
 SubMenu(1) = 0
 SubMenu(2) = 0
 SubMenu(3) = 16

 Choice = Menu(1, 3, Choice$(), MenuRow(), MenuCol(), Help$(), SubMenu(), FALSE)

 SELECT CASE Choice
  CASE 1
   Execute 0, ""
   Box 9, 19, 14, 61, 0, 7, 511, "Load Program": LOCATE 11, 22: INPUT "", file$: PCOPY 1, 0
   Execute 1, file$
  CASE 2:
   Execute 0, ""
   Box 9, 19, 14, 61, 0, 7, 511, "Find File": LOCATE 11, 22: INPUT "", file$: PCOPY 1, 0
   Execute 1, "DIR /S " + file$
  CASE 3: finished = TRUE
 END SELECT

CASE "2"
 Choice$(1) = "List directory files"
 Choice$(2) = "Directory options"
 Choice$(3) = "Change directory..."
 Choice$(4) = "Clear the Screen"
 Choice$(5) = "Change Colors"
 FOR d = 1 TO 7: MenuRow(d) = 2 + d: MenuCol(d) = 8: NEXT d
 SubMenu(2) = 1
 SubMenu(3) = 17
 SubMenu(4) = 16
 SubMenu(5) = 1
 SubMenu(0) = 2
 Help$(1) = "This lists the files in the current directory"
 Help$(2) = "Use this to change the way that files are shown with the directory command"
 Help$(3) = "Changes from one directory to another"
 Help$(4) = "Clears the Screen. Like you needed help for that"
 Help$(5) = "Changes the DOSMenu and DOS color schemes"

 IF ViewChoice < 1 THEN ViewChoice = 1
 Choice = Menu(ViewChoice, 5, Choice$(), MenuRow(), MenuCol(), Help$(), SubMenu(), FALSE)
 IF Choice > 0 THEN ViewChoice = Choice
 SELECT CASE Choice
  CASE 1: Execute 1, "DIR" + DirWide$ + DirAlph$ + DirPage$ + DirHid$
  CASE 2: Path$ = "21"
  CASE 3: Execute 0, ""
   Box 9, 19, 14, 61, 0, 7, 511, "Change Directory": LOCATE 11, 22: LINE INPUT "", file$: PCOPY 1, 0
   Execute 1, "CD " + file$: Execute 1, "CD"
  CASE 4: FancyCls colors(2, ColorPref), colors(1, ColorPref)
  CASE 5: Path$ = "26"
 END SELECT

CASE "21"
 IF ViewDirWide THEN Choice$(1) = "Wide" ELSE Choice$(1) = "Skinny"
 Choice$(2) = "Pause on page": IF ViewDirPage THEN Choice$(5) = Choice$(5) + " û" ELSE Choice$(5) = Choice$(5) + " X"
 Choice$(3) = "Alphabetized": IF DirSort$ = "/ON" THEN Choice$(4) = Choice$(4) + "  *"
 Choice$(4) = "Extension": IF DirSort$ = "/OE" THEN Choice$(4) = Choice$(4) + " *"
 Choice$(5) = "By Size": IF DirSort$ = "/OS" THEN Choice$(4) = Choice$(4) + "  *"
 Choice$(6) = "Date & Time": IF DirSort$ = "/OD" THEN Choice$(4) = Choice$(4) + " *"
 Choice$(7) = "Reverse Order"
 Choice$(8) = "Hidden"': IF ViewDirHid THEN Choice$(10) = Choice$(10) + "   û" ELSE Choice$(10) = Choice$(10) + "    X"
 Choice$(9) = "Archive"': IF ViewDirArc THEN Choice$(11) = Choice$(11) + "   û" ELSE Choice$(11) = Choice$(11) + "   X"
 Choice$(10) = "Read only"': IF ViewDirRed THEN Choice$(12) = Choice$(12) + "   û" ELSE Choice$(12) = Choice$(12) + " X"
 Choice$(11) = "System"': IF ViewDirSys THEN Choice$(13) = Choice$(13) + "   û" ELSE Choice$(13) = Choice$(13) + "    X"
 FOR d = 1 TO 13: MenuRow(d) = 2 + d: MenuCol(d) = 35: NEXT d
 SubMenu(4) = 16: SubMenu(8) = 16
 Help$(1) = "Toggles between fat and skinny"
 Help$(2) = "Determines how to sort files"
 Help$(4) = "Shows hidden files if it is checked"
 Help$(5) = "Pauses the file listing output for every page, press any key to continue"
 SubMenu(0) = 1

 IF DirChoice < 1 THEN DirChoice = 1
 Choice = Menu(DirChoice, 11, Choice$(), MenuRow(), MenuCol(), Help$(), SubMenu(), FALSE)
 IF Choice > 0 THEN DirChoice = Choice
 IF Choice = 2 THEN Path$ = "211"
CASE "211"
 Choice$(1) = "Further"
 Choice$(2) = "Back"
 SubMenu(0) = 1
 FOR d = 1 TO 2: MenuRow(d) = 2 + d: MenuCol(d) = 50: SubMenu(1) = TRUE: NEXT d
 Choice = Menu(1, 2, Choice$(), MenuRow(), MenuCol(), Help$(), SubMenu(), FALSE)
 IF Choice = 1 THEN Path$ = "2111"
CASE "2111"
 Choice$(1) = "Low Sound"
 Choice$(2) = "High Sound"
 SubMenu(0) = 1
 FOR d = 1 TO 2: MenuRow(d) = 2 + d: MenuCol(d) = 60: NEXT d
 Choice = Menu(1, 2, Choice$(), MenuRow(), MenuCol(), Help$(), SubMenu(), FALSE)
 IF Choice = 1 THEN SOUND 1000, 3
 IF Choice = 2 THEN SOUND 3000, 3

CASE "26"
 DO
 Choice$(1) = "Monochrome Scheme"
 Choice$(2) = "Cyan/Blue Scheme"
 Choice$(3) = "Blue/Cyan Scheme"
 Choice$(4) = "Red/Grey Scheme"
 Choice$(5) = "User Defined..."
 FOR d = 1 TO 5: MenuRow(d) = 6 + d: MenuCol(d) = 35: NEXT d
 Help$(1) = "Color scheme for monochrome and LCD displays"
 Help$(2) = "Color scheme featuring cyan"
 Help$(3) = "Color scheme featuring blue"
 Help$(4) = "Color scheme featuring red"
 SubMenu(0) = 1
 SubMenu(5) = 16

 Choice = Menu(ColorPref, 5, Choice$(), MenuRow(), MenuCol(), Help$(), SubMenu(), FALSE)

 SELECT CASE Choice
  CASE 1 TO 4
   ColorPref = Choice
 END SELECT
 LOOP UNTIL Choice < 1

CASE ELSE: LOCATE 25, 1: PRINT "Invalid Menu Path Error-"; Path$; "!": Choice = 0: SOUND 1024, 1
END SELECT
RETURN

END SUB

SUB PictureDraw (Hite, Widt, Urow, Lcol, Pict$, PictDims AS Picture)
IF Hite = 0 OR Widt = 0 THEN
Hite = PictDims.Hite: Widt = PictDims.Widt
Urow = PictDims.Urow: Lcol = PictDims.Lcol
END IF

DEF SEG = &HB800: Move = 1
FOR Vset = Urow * 160 TO (Urow + Hite - 1) * 160 STEP 160
 FOR Hset = Vset + Lcol * 2 TO Vset + (Lcol + Widt - 1) * 2 STEP 2
 POKE Hset + 1, ASC(MID$(Pict$, Move + 1, 1))
 POKE Hset, ASC(MID$(Pict$, Move, 1)): Move = Move + 2
NEXT Hset, Vset

END SUB

SUB PictureSnap (Hite, Widt, Urow, Lcol, Pict$, PictDims AS Picture)
PictDims.Hite = Hite: PictDims.Widt = Widt
PictDims.Urow = Urow: PictDims.Lcol = Lcol

DEF SEG = &HB800: Move = 1: Pict$ = SPACE$(Hite * Widt * 2)
FOR Vset = Urow * 160 TO (Urow + Hite - 1) * 160 STEP 160
 FOR Hset = Vset + Lcol * 2 TO Vset + (Lcol + Widt - 1) * 2 STEP 2
 MID$(Pict$, Move + 1, 1) = CHR$(PEEK(Hset + 1))
 MID$(Pict$, Move, 1) = CHR$(PEEK(Hset)): Move = Move + 2
NEXT Hset, Vset

END SUB

'PrintHelpLine:
'  Prints help text on the bottom row in the proper color
SUB PrintHelpLine (Help$)
    COLOR colors(5, ColorPref), colors(4, ColorPref)
    LOCATE 25, 1
    PRINT SPACE$(80);
    Center 25, Help$
END SUB

