''12-21-97
DEFINT A-Z
DECLARE SUB ShowMainMenu (Choice, Mode)
DECLARE SUB MovieListLoad (IoErr)
DECLARE SUB MovieListSave (IoErr)
DECLARE SUB MovieListSort ()
DECLARE SUB MovieListSortOld ()
DECLARE SUB MovieListPrint ()
DECLARE SUB ListEditor (key$, MenuKey$)
DECLARE SUB ListTextGet (CurRow, CurCol, Text$)
DECLARE SUB ListTextPut (CurRow, CurCol, Text$)
DECLARE SUB ListShowLine (TopRow, BtmRow, EntryOrScrn)
DECLARE SUB ListTextLineAdd (CurRow)
DECLARE SUB ListTextLineRem (CurRow, PreRow)
DECLARE SUB ListMoveCursor (CurRow, CurCol, Mode)
DECLARE SUB ListGetTextPos (CurPtr, TextPos)
DECLARE SUB TypePrompt (Text$, key$, ScrRow, ScrCol, VisLen, RecLen, Curp, Ofst, Chng, OutChng)
DECLARE SUB CenterText (CurRow, Text$)
DECLARE SUB WaitKey ()
DECLARE SUB CallScroll (TopRow, BtmRow, LftCol, RitCol, ScrollDif)
DECLARE SUB DrawBorder ()
DECLARE SUB ShowOptionText (Row, Col, Choice, Mode, Text$)
DECLARE SUB MessageBar (Text$)
DECLARE SUB EndProgram ()
DECLARE SUB DrawListBorder ()
DECLARE SUB DrawBox (Urow, Drow, Lcol, Rcol)
DECLARE SUB GotoLine (Mode)
DECLARE FUNCTION TotalMovies$ ()

TYPE ListSpecsType
CurRow AS INTEGER
CurCol AS INTEGER
PreRow AS INTEGER
PageRow AS INTEGER
LastRow AS INTEGER
TextPtr AS INTEGER
TextPos AS INTEGER
ListChanged AS INTEGER
END TYPE

CONST ColorFore = 7, ColorBack = 1, ColorWall = 3, ColorSelect = 9, ColorLitFore = 15, ColorLitBack = 11
CONST FileName$ = "movies.txt", ListMaxCol = 1, ListCols = 2, ListMaxRow = 511, ListMaxLen = 10000
CONST ListScrnTop = 2, ListScrnBtm = 24, ListScrnLft = 2, ListScrnRit = 77
DIM SHARED ListBar(ListMaxCol), EntryPrompts(0 TO ListMaxCol, 0 TO 2), ListScrnHite, ListScrnWdth, ListMaxPtr, FilErr, FilePath$
ListScrnHite = ListScrnBtm - ListScrnTop + 1: ListScrnWdth = ListScrnRit - ListScrnLft + 1
ListMaxPtr = (ListMaxRow + 1) * ListCols - 1
ListBar(0) = 20
EntryPrompts(0, 0) = 0: EntryPrompts(0, 1) = 20: EntryPrompts(0, 2) = 50
EntryPrompts(1, 0) = 21: EntryPrompts(1, 1) = 55: EntryPrompts(1, 2) = 250
DIM SHARED MovieList$, ListSpecs AS ListSpecsType, ListPtrs(0 TO ListMaxPtr), SearchTitle$
FOR CheckPtr = 1 TO 10: menuKeys$ = menuKeys$ + CHR$(0) + MID$("!" + CHR$(34) + "#", CheckPtr, 1): NEXT CheckPtr

SCREEN 0: WIDTH 80, 25: LOCATE , , 0, 13, 15
VIEW PRINT: COLOR , ColorWall: CLS

MovieListLoad 0

DrawMainScreen:
ShowMainMenu 0, 0
ListShowLine ListScrnTop, ListScrnBtm, 1
DrawListBorder

DO
 ListEditor key$, menuKeys$

 IF key$ = CHR$(27) THEN
  IF ListSpecs.ListChanged THEN
   COLOR ColorLitFore, ColorWall: CLS : LOCATE , , 0
   CenterText 10, "The movie list has been edited,"
   CenterText 11, "Would you like to save these changes?"
   CenterText 14, "You can also press Alt+Q to quit instead of Escape,"
   CenterText 15, "and it will automatically save the list before exiting"
   ShowOptionText 12, 32, 0, 0, "Yes/No/Cancel"
   WaitKey
   DO
    key$ = INKEY$
    SELECT CASE UCASE$(key$)
    CASE "", "N": EndProgram
    CASE CHR$(13), "Y"
     MovieListSave IoErr: IF IoErr GOTO DrawMainScreen ELSE a! = TIMER: DO UNTIL TIMER - a! > 1 OR INKEY$ > "": LOOP: EndProgram
    CASE "C", "": GOTO DrawMainScreen
    END SELECT
   LOOP
  END IF
  EndProgram
 END IF

 menuFunction = INSTR(menuKeys$, key$)
 SELECT CASE menuFunction
 CASE 0
 CASE 1: IF ListSpecs.ListChanged THEN MovieListSave IoErr: IF IoErr = 0 THEN EndProgram ELSE  ELSE EndProgram
 CASE 3: ShowMainMenu 1, 1: WaitKey: MovieListPrint
 CASE 5: ShowMainMenu 2, 1: WaitKey: MovieListSave 0
 CASE 7
  ShowMainMenu 3, 1
  IF ListSpecs.ListChanged THEN
   COLOR ColorLitFore, ColorWall: CLS : LOCATE , , 0
   CenterText 12, "Do you really want to reload the list"
   CenterText 13, "And lose your changes to it?"
   ShowOptionText 15, 36, 0, 0, "Yes/No"
   DO
    key$ = INKEY$
    SELECT CASE UCASE$(key$)
    CASE "", "N", "": MessageBar "Revert cancelled": GOTO DrawMainScreen
    CASE CHR$(13), "Y": EXIT DO
    END SELECT
   LOOP
  ELSE WaitKey
  END IF
  MovieListLoad IoErr
  GOTO DrawMainScreen
 CASE 9: ShowMainMenu 4, 1: WaitKey: MovieListSort'S=Resort the entries (name, date)
 CASE 11: ShowMainMenu 5, 1: GotoLine 0
 CASE 13: ShowMainMenu 6, 1: GotoLine 1: WaitKey
 CASE 17
  ShowMainMenu 8, 1: MessageBar "Created on June something, 1997, by Frank Dwayne Robinson"
  IF PLAY(0) = 0 THEN PLAY "MBt150L24O2CE-GL12A+L24p16CE-Gl12Al24p16CE-GE-l12Cp4L24o4A+GE-L12Cp16L24BGE-L12Cp16L24CE-G>C"
  CALL WaitKey: ShowMainMenu 8, 0
 CASE 19: ShowMainMenu 4, 1: WaitKey: MovieListSortOld'S=Resort the entries (name, date)
 'CASE "F" 'Find desired text
 'CASE "H" 'Help me!
 END SELECT
 ShowMainMenu 0, 0
LOOP

EndProgram

FilErrHan: FilErr = 1: RESUME NEXT

SUB CallScroll (TopRow, BtmRow, LftCol, RitCol, ScrollDif)

DIM Scroll(0 TO 6)
p = VARPTR(Scroll(0)): DEF SEG = VARSEG(Scroll(0))
POKE p, &HB8: POKE p + 1, ABS(ScrollDif)
IF ScrollDif < 0 THEN POKE p + 2, 6 ELSE POKE p + 2, 7
POKE p + 3, &HB9  'mov cx:
POKE p + 4, LftCol' left side
POKE p + 5, TopRow' top Line
POKE p + 6, &HBA  'mov dx:
POKE p + 7, RitCol' right Side
POKE p + 8, BtmRow' bottom Line
POKE p + 9, &HB7  'mov bh:
POKE p + 10, 27    'back color
POKE p + 11, &HCD 'int
POKE p + 12, &H10 'video bios (10)
POKE p + 13, &HCB 'retf
CALL ABSOLUTE(VARPTR(Scroll(0)))

'(mov ax     )(mov cx     )(mov dx     )(mov bh 9)(int 10)(far return)
'&HB8,&H01,&H06,&HB9,&H08,&H05,&HBA,&H0?,&H0?,&HB7,&H09,&HCD,&H10,&HCB

END SUB

SUB CenterText (CurRow, Text$)

IF LEN(Text$) > 80 THEN LOCATE CurRow, 1 ELSE LOCATE CurRow, (80 - LEN(Text$)) \ 2 + 1
PRINT LEFT$(Text$, 80);

END SUB

SUB DrawBox (Urow, Drow, Lcol, Rcol)

Hwid = Rcol - Lcol - 1: IF Hwid < 0 THEN Hwid = 0

COLOR ColorLitFore, ColorWall
LOCATE Urow, Lcol: PRINT "Û"; STRING$(Hwid, 223); "Û";
LOCATE Drow, Lcol: PRINT "Û"; STRING$(Hwid, 220); "Û";
FOR Vrow = Urow + 1 TO Drow - 1
 LOCATE Vrow, Lcol: PRINT "Û"; SPACE$(Hwid); "Û";
NEXT Vrow

END SUB

SUB DrawListBorder

COLOR ColorBack, ColorWall
FOR Vrow = ListScrnTop TO ListScrnBtm
 LOCATE Vrow, ListScrnLft - 1: PRINT "Þ";
 LOCATE Vrow, ListScrnRit + 1: PRINT "Ý";
NEXT Vrow

END SUB

SUB EndProgram

COLOR 7, 0: CLS : SYSTEM

END SUB

SUB GotoLine (Mode)

Urow = 12: Drow = 14
IF Mode THEN GOSUB FindLine: EXIT SUB

GotoLineRedraw:
Lcol = 7: Rcol = 74: LOCATE , , 0
DrawBox Urow, Drow, Lcol, Rcol
COLOR ColorLitBack: LOCATE Urow + 1, Lcol + 2: PRINT "Movie title:";
MessageBar "Type in a movie title to jump to"
EntryShow = 2: EntryPos = LEN(SearchTitle$)
DO
 key$ = INKEY$
 SELECT CASE key$
 CASE CHR$(27): GOSUB GotoLineRedrawBack: MessageBar "Movie title search cancelled": EXIT SUB
 CASE CHR$(13): GOSUB GotoLineRedrawBack: GOSUB FindLine
  Lcol = 26: Rcol = 55: DrawBox Urow, Drow, Lcol, Rcol
  COLOR 11: LOCATE Urow + 1, Lcol + 2: PRINT "Could not find that movieè";
  WHILE INKEY$ = "": WEND
  GOTO GotoLineRedraw
 CASE ELSE: TypePrompt SearchTitle$, key$, Urow + 1, Lcol + 15, 51, EntryPrompts(0, 2), EntryPos, EntryOfset, EntryShow, 0
 END SELECT
LOOP

GotoLineRedrawBack: ListShowLine Urow, Drow, 1: RETURN
FindLine:
 CurRow = ListSpecs.CurRow: UcaseTitle$ = UCASE$(SearchTitle$)
 DO
  IF CurRow >= ListSpecs.LastRow THEN CurRow = 0 ELSE CurRow = CurRow + 1
  ListTextGet CurRow, 0, Text$
  IF INSTR(UCASE$(Text$), UcaseTitle$) THEN ListMoveCursor CurRow, 0, 3: MessageBar "Jumped to next find of movie title": EXIT SUB
 LOOP UNTIL CurRow = ListSpecs.CurRow
 MessageBar "No matches found for '" + LEFT$(SearchTitle$, 56) + "'"
RETURN

END SUB

SUB ListEditor (key$, menuKeys$) STATIC

'ColCursors 0 to ListMaxCol, 0 to 1
EntryShow = 2
GOSUB ListEditorGetPrompt
DO
 key$ = INKEY$
 SELECT CASE key$
 CASE ""
 CASE CHR$(0) + "H": IF ListSpecs.CurRow > 0 THEN GOSUB ListEditorSavePrompt: ListMoveCursor ListSpecs.CurRow - 1, 0, 2: GOSUB ResetCursors: GOSUB ListEditorGetPrompt
 CASE CHR$(0) + "P": IF ListSpecs.CurRow < ListSpecs.LastRow THEN GOSUB ListEditorSavePrompt: ListMoveCursor ListSpecs.CurRow + 1, 0, 2: GOSUB ResetCursors: GOSUB ListEditorGetPrompt
 CASE CHR$(0) + "s", CHR$(0) + CHR$(15)
  IF ListSpecs.CurCol < 1 AND ListSpecs.CurRow > 0 THEN
   GOSUB ListEditorSavePrompt: ListMoveCursor ListSpecs.CurRow - 1, ListMaxCol, 3: GOSUB ResetCursors: GOSUB ListEditorGetPrompt
  ELSEIF ListSpecs.CurCol THEN
   GOSUB ListEditorSavePrompt: ListMoveCursor 0, ListSpecs.CurCol - 1, 1: GOSUB ListEditorGetPrompt
  END IF
 CASE CHR$(0) + "t", CHR$(9), CHR$(13)
  IF ListSpecs.CurCol >= ListMaxCol AND ListSpecs.CurRow < ListSpecs.LastRow THEN
   GOSUB ListEditorSavePrompt: ListMoveCursor ListSpecs.CurRow + 1, 0, 3: GOSUB ResetCursors: GOSUB ListEditorGetPrompt
  ELSEIF ListSpecs.CurCol < ListMaxCol THEN
   GOSUB ListEditorSavePrompt: ListMoveCursor 0, ListSpecs.CurCol + 1, 1: GOSUB ListEditorGetPrompt
  ELSEIF key$ = CHR$(13) AND ListSpecs.CurRow < ListMaxRow THEN
   GOSUB ListEditorSavePrompt: ListTextLineAdd ListSpecs.LastRow + 1
   ListShowLine ListSpecs.LastRow, ListSpecs.LastRow, 0
   ListMoveCursor ListSpecs.LastRow, 0, 3: GOSUB ResetCursors: GOSUB ListEditorGetPrompt
   WaitKey
  END IF
 CASE CHR$(0) + "I"
  IF ListSpecs.CurRow > 0 THEN
   GOSUB ListEditorSavePrompt
   IF ListSpecs.CurRow > ListScrnHite THEN ListMoveCursor ListSpecs.CurRow - ListScrnHite, 0, 2 ELSE ListMoveCursor 0, 0, 2
   GOSUB ResetCursors: GOSUB ListEditorGetPrompt
  END IF
 CASE CHR$(0) + "Q"
  IF ListSpecs.CurRow < ListSpecs.LastRow THEN
   GOSUB ListEditorSavePrompt
   IF ListSpecs.CurRow + ListScrnHite < ListSpecs.LastRow THEN ListMoveCursor ListSpecs.CurRow + ListScrnHite, 0, 2 ELSE ListMoveCursor ListSpecs.LastRow, 0, 2
   GOSUB ResetCursors: GOSUB ListEditorGetPrompt
  END IF
 CASE CHR$(0) + "w": IF ListSpecs.CurRow <> 0 THEN GOSUB ListEditorSavePrompt: ListMoveCursor 0, 0, 2: GOSUB ResetCursors: GOSUB ListEditorGetPrompt
 CASE CHR$(0) + "u": IF ListSpecs.CurRow <> ListSpecs.LastRow THEN GOSUB ListEditorSavePrompt: ListMoveCursor ListSpecs.LastRow, 0, 2: GOSUB ResetCursors: GOSUB ListEditorGetPrompt
 CASE CHR$(0) + "R" 'Insert extra current line, redraw all lines below
  IF ListSpecs.CurRow <= ListSpecs.LastRow THEN
   GOSUB ListEditorSavePrompt
   ListTextLineAdd ListSpecs.CurRow
   GOSUB ResetCursors
   GOSUB ListEditorGetPrompt
  END IF
 CASE CHR$(0) + "S" 'Delete current line, redraw all lines below
  GOSUB ListEditorSavePrompt
  ListTextLineRem ListSpecs.CurRow, ListSpecs.PreRow
  GOSUB ResetCursors
  GOSUB ListEditorGetPrompt
  WaitKey
 CASE CHR$(27): EXIT DO
 CASE ELSE
  IF LEN(key$) > 1 AND INSTR(menuKeys$, key$) THEN EXIT DO
  '0=Direct it to movie title prompt, 1=Direct it to description prompt
  TypePrompt Text$, key$, EntryScrnRow, EntryScrnCol, EntryVisLen, EntryRecLen, EntryPos, EntryOfset, 0, EntryAltered
 END SELECT
LOOP

GOSUB ListEditorSavePrompt
EXIT SUB

ListEditorGetPrompt:
 'gets the text for the current prompt spot, determines screen row for prompt
 ListTextGet ListSpecs.CurRow, ListSpecs.CurCol, Text$
 ColumnItem = ListSpecs.CurCol
 EntryScrnRow = (ListSpecs.CurRow - ListSpecs.PageRow) + ListScrnTop
 EntryScrnCol = EntryPrompts(ColumnItem, 0) + ListScrnLft
 EntryVisLen = EntryPrompts(ColumnItem, 1)
 EntryRecLen = EntryPrompts(ColumnItem, 2)
 EntryAltered = 0
 EntryPos = ColCursors(ColumnItem, 0)
 EntryOfset = ColCursors(ColumnItem, 1)
 IF EntryPos > LEN(Text$) THEN EntryPos = LEN(Text$)
 TypePrompt Text$, "", EntryScrnRow, EntryScrnCol, EntryVisLen, 0, EntryPos, EntryOfset, EntryShow, 0
 EntryShow = 1
RETURN
ListEditorSavePrompt:
 IF EntryAltered THEN
  ListTextPut ListSpecs.CurRow, ListSpecs.CurCol, Text$
  ListSpecs.ListChanged = 1
 END IF
 'IF EntryOfset THEN TypePrompt Text$, "", EntryScrnRow, EntryScrnCol, EntryVisLen, 0, 0, 0, 2, 0
 ColCursors(ListSpecs.CurCol, 0) = EntryPos
 ColCursors(ListSpecs.CurCol, 1) = EntryOfset
RETURN

ResetCursors:
CurPtr = ListSpecs.CurRow * ListCols
FOR CheckPtr = 0 TO ListMaxCol
 IF ListPtrs(CurPtr) > EntryPrompts(CheckPtr, 1) - 1 THEN
  ColCursors(CheckPtr, 0) = EntryPrompts(CheckPtr, 1) - 1
 ELSE
  ColCursors(CheckPtr, 0) = ListPtrs(CurPtr)
 END IF
 ColCursors(CheckPtr, 1) = 0
 CurPtr = CurPtr + 1
NEXT CheckPtr
EntryPos = 0: EntryOfset = 0
RETURN

END SUB

SUB ListFindText (CurRow, Text$)
 MessageBar "Searching for text"
END SUB

SUB ListGetTextPos (CurPtr, TextPos)

'TextPos = 0: FOR CheckPtr = 0 TO CurPtr - 1: TextPos = TextPos + ListPtrs(CheckPtr): NEXT CheckPtr
'EXIT SUB

TextPos = ListSpecs.TextPos
IF CurPtr = 0 THEN
 TextPos = 0
ELSEIF CurPtr < ListSpecs.TextPtr THEN
 FOR CheckPtr = ListSpecs.TextPtr - 1 TO CurPtr STEP -1
  TextPos = TextPos - ListPtrs(CheckPtr)
 NEXT CheckPtr
ELSEIF CurPtr > ListSpecs.TextPtr THEN
 FOR CheckPtr = ListSpecs.TextPtr TO CurPtr - 1
  TextPos = TextPos + ListPtrs(CheckPtr)
 NEXT CheckPtr
END IF
ListSpecs.TextPtr = CurPtr
ListSpecs.TextPos = TextPos

END SUB

SUB ListMoveCursor (CurRow, CurCol, Mode)

IF Mode AND 2 THEN
 IF CurRow < ListSpecs.PageRow THEN
  ScrollDif = ListSpecs.PageRow - CurRow: ListSpecs.PageRow = CurRow
 ELSEIF CurRow > ListSpecs.PageRow + ListScrnHite - 1 THEN
  ScrollDif = (ListSpecs.PageRow + ListScrnHite) - CurRow - 1: ListSpecs.PageRow = CurRow - ListScrnHite + 1
 END IF
 IF ScrollDif AND ABS(ScrollDif) < ListScrnHite THEN CallScroll ListScrnTop - 1, ListScrnBtm - 1, ListScrnLft - 1, ListScrnRit - 1, ScrollDif
 OldRow = ListSpecs.CurRow: ListSpecs.CurRow = CurRow

 DEF SEG = 0
 IF PEEK(1047) AND 3 THEN
  LastRow = CurRow
 ELSE
  PreRow = ListSpecs.PreRow: ListSpecs.PreRow = CurRow
  FrstRow = CurRow + ScrollDif - SGN(ScrollDif): LastRow = CurRow
  IF LastRow < FrstRow THEN SWAP FrstRow, LastRow
  ListShowLine FrstRow, LastRow, 0
  LastRow = PreRow
 END IF
 FrstRow = OldRow: IF LastRow < FrstRow THEN SWAP FrstRow, LastRow
 ListShowLine FrstRow, LastRow, 0
END IF
IF Mode AND 1 THEN
 ListSpecs.CurCol = CurCol
END IF

END SUB

SUB ListShowLine (FrstRow, LastRow, EntryOrScrn)

'0=Entry line, 1=Screen line
IF EntryOrScrn THEN
 IF FrstRow < ListScrnTop THEN TopRow = ListScrnTop ELSE TopRow = FrstRow
 IF LastRow > ListScrnBtm THEN BtmRow = ListScrnBtm ELSE BtmRow = LastRow
 CurRow = TopRow - ListScrnTop + ListSpecs.PageRow
ELSE
 IF FrstRow < 0 THEN EXIT SUB
 IF FrstRow < ListSpecs.PageRow THEN TopRow = ListScrnTop: CurRow = ListSpecs.PageRow ELSE TopRow = FrstRow - ListSpecs.PageRow + ListScrnTop: CurRow = FrstRow
 IF LastRow - ListSpecs.PageRow >= ListScrnHite THEN BtmRow = ListScrnBtm ELSE BtmRow = LastRow - ListSpecs.PageRow + ListScrnTop
END IF

LOCATE , , 0
COLOR ColorWall, ColorBack
FOR Vrow = TopRow TO BtmRow
 FOR CurCol = 0 TO ListMaxCol - 1
  LOCATE Vrow, ListBar(CurCol) + ListScrnLft: PRINT "³";
 NEXT CurCol
NEXT Vrow

TopSelRow = ListSpecs.CurRow: BtmSelRow = ListSpecs.PreRow
IF TopSelRow > BtmSelRow THEN SWAP TopSelRow, BtmSelRow
COLOR , ColorBack
FOR Vrow = TopRow TO BtmRow
 IF CurRow > ListSpecs.LastRow THEN
  COLOR ColorFore
  FOR CurCol = 0 TO ListMaxCol
   LOCATE Vrow, EntryPrompts(CurCol, 0) + ListScrnLft: PRINT STRING$(EntryPrompts(CurCol, 1), 176);
  NEXT CurCol
 ELSE
  IF CurRow < TopSelRow OR CurRow > BtmSelRow THEN COLOR ColorFore ELSE IF CurRow = ListSpecs.CurRow THEN COLOR ColorLitBack ELSE COLOR ColorSelect
  FOR CurCol = 0 TO ListMaxCol
   ListTextGet CurRow, CurCol, Text$
   LOCATE Vrow, EntryPrompts(CurCol, 0) + ListScrnLft
   IF LEN(Text$) < EntryPrompts(CurCol, 1) THEN PRINT Text$; SPACE$(EntryPrompts(CurCol, 1) - LEN(Text$));  ELSE PRINT LEFT$(Text$, EntryPrompts(CurCol, 1));
  NEXT CurCol
  CurRow = CurRow + 1
 END IF
NEXT Vrow

END SUB

SUB ListTextGet (CurRow, CurCol, Text$)

Text$ = ""
IF CurRow < 0 OR CurRow > ListSpecs.LastRow THEN STOP: EXIT SUB
IF CurCol < 0 OR CurCol > ListMaxCol THEN STOP: EXIT SUB
ListPtr = CurRow * ListCols + CurCol: IF ListPtr > ListMaxPtr THEN STOP: EXIT SUB

ListGetTextPos ListPtr, TextPos
Text$ = MID$(MovieList$, TextPos + 1, ListPtrs(ListPtr))

END SUB

SUB ListTextLineAdd (CurRow)

IF CurRow < 0 OR CurRow - 1 > ListSpecs.LastRow THEN EXIT SUB
ListPtr = CurRow * ListCols
IF ListSpecs.LastRow * ListCols + ListCols > ListMaxPtr THEN SOUND 1024, .3: EXIT SUB
FOR CheckPtr = ListSpecs.LastRow * ListCols + ListMaxCol TO ListPtr STEP -1
 ListPtrs(CheckPtr + ListCols) = ListPtrs(CheckPtr)
NEXT CheckPtr
FOR CheckPtr = 0 TO ListMaxCol: ListPtrs(ListPtr + CheckPtr) = 0: NEXT CheckPtr
ListSpecs.LastRow = ListSpecs.LastRow + 1

ListGetTextPos 0, 0
ListShowLine ListSpecs.CurRow, ListSpecs.LastRow, 0

END SUB

SUB ListTextLineRem (CurRow, PreRow)

FrstRow = CurRow: LastRow = PreRow: IF LastRow < FrstRow THEN SWAP FrstRow, LastRow
IF FrstRow < 0 THEN FrstRow = 0 ELSE IF FrstRow > ListSpecs.LastRow THEN EXIT SUB
IF LastRow > ListSpecs.LastRow THEN LastRow = ListSpec.LastRow ELSE IF LastRow < 0 THEN EXIT SUB

RemRows = LastRow - FrstRow + 1
IF ListSpecs.LastRow AND RemRows <= ListSpecs.LastRow THEN
 ListPtr = FrstRow * ListCols
 ListGetTextPos ListPtr, TextPos
 FOR CheckRow = FrstRow TO LastRow
  FOR CheckPtr = 0 TO ListMaxCol
   Leng = Leng + ListPtrs(ListPtr): ListPtr = ListPtr + 1
  NEXT CheckPtr
 NEXT CheckRow
 MovieList$ = LEFT$(MovieList$, TextPos) + RIGHT$(MovieList$, LEN(MovieList$) - TextPos - Leng)
 ListPtr = ListSpecs.TextPtr: PtrAdjust = RemRows * ListCols
 FOR CheckPtr = ListPtr TO (ListSpecs.LastRow - RemRows + 1) * ListCols - 1
  ListPtrs(CheckPtr) = ListPtrs(CheckPtr + PtrAdjust)
 NEXT CheckPtr
 OldRow = ListSpecs.LastRow: ListSpecs.LastRow = ListSpecs.LastRow - RemRows
 IF FrstRow > ListSpecs.LastRow THEN TopRow = ListSpecs.LastRow ELSE TopRow = FrstRow
 ListSpecs.PreRow = TopRow: ListMoveCursor TopRow, 0, 2
ELSE
 MovieList$ = "": ListPtrs(0) = 0: OldRow = ListSpecs.LastRow: ListSpecs.LastRow = 0
 ListSpecs.CurRow = 0: ListSpecs.PreRow = 0: ListSpecs.PageRow = 0
END IF
ListShowLine FrstRow, OldRow, 0

END SUB

SUB ListTextPut (CurRow, CurCol, Text$)

IF CurRow < 0 OR CurRow - 1 > ListSpecs.LastRow THEN STOP: EXIT SUB
IF CurCol < 0 OR CurCol > ListMaxCol THEN STOP: EXIT SUB
ListPtr = CurRow * ListCols + CurCol: IF ListPtr > ListMaxPtr THEN STOP: EXIT SUB

ListGetTextPos ListPtr, TextPos: PtrAdjust = LEN(Text$) - ListPtrs(ListPtr)
IF PtrAdjust > 0 THEN
 MovieList$ = LEFT$(MovieList$, TextPos) + SPACE$(PtrAdjust) + RIGHT$(MovieList$, LEN(MovieList$) - TextPos)
ELSEIF PtrAdjust < 0 THEN
 MovieList$ = LEFT$(MovieList$, TextPos) + RIGHT$(MovieList$, LEN(MovieList$) - TextPos + PtrAdjust)
END IF
ListPtrs(ListPtr) = LEN(Text$): IF LEN(Text$) THEN MID$(MovieList$, TextPos + 1) = Text$

END SUB

SUB MessageBar (Text$)

COLOR ColorBack, ColorWall
LOCATE 25, 1: PRINT SPACE$(80);
CenterText 25, Text$

END SUB

SUB MovieListLoad (IoErr)

MessageBar "Loading movie list"
ON ERROR GOTO FilErrHan

FilErr = 0: OPEN FilePath$ + FileName$ FOR INPUT AS #1
IF FilErr THEN FilErr = 0: OPEN "\" + FileName$ FOR INPUT AS #1: IF FilErr = 0 THEN FilePath$ = "\"
IF FilErr THEN
 CLOSE #1: COLOR ColorLitFore, ColorWall: CLS
 CenterText 10, "Could not find movie list to load (" + FileName$ + ")"
 CenterText 12, "Can not find it in the current or root directory"
 CenterText 13, "It might not have ever been created, or may be simply in a different place"
 CenterText 14, "You can type in the location of it below, or press Enter to make a new one"
 COLOR 15, 1
 Chng = 2
 DO
  key$ = INKEY$
  SELECT CASE key$
  CASE CHR$(27): EndProgram
  CASE CHR$(13)
   IF FilePath$ = "" THEN ON ERROR GOTO 0: EXIT SUB
   IF RIGHT$(FilePath$, 1) <> "\" THEN FilePath$ = FilePath$ + "\"
   FilErr = 0: OPEN FilePath$ + FileName$ FOR INPUT AS #1
   IF FilErr THEN
    CLOSE #1
    COLOR ColorLitFore, ColorWall
    LOCATE 16, 11, 0: PRINT SPACE$(60)
    CenterText 16, "List was not found in that directory (" + LEFT$(FilePath$, 20) + ")"
    WHILE INKEY$ = "": WEND
    COLOR 15, 1: Chng = 2
   ELSE
    EXIT DO
   END IF
  CASE ELSE
   TypePrompt FilePath$, key$, 16, 11, 60, 128, Curp, Ofst, Chng, 0
  END SELECT
 LOOP
END IF

MovieList$ = "": ListSpecs.LastRow = 0
IF NOT EOF(1) THEN
 DO
  LINE INPUT #1, Text$
  IF LEN(Text$) + LEN(MovieList$) > ListMaxLen THEN IoErr = 1: EXIT DO
  MovieList$ = MovieList$ + Text$
  ListPtrs(ListPtr) = LEN(Text$)
  IF EOF(1) THEN EXIT DO
  IF ListPtr >= ListMaxPtr THEN IoErr = 1: EXIT DO ELSE ListPtr = ListPtr + 1
  IF CurCol >= ListMaxCol THEN CurCol = 0: ListSpecs.LastRow = ListSpecs.LastRow + 1 ELSE CurCol = CurCol + 1
 LOOP
END IF
CLOSE #1
ON ERROR GOTO 0

IF ListSpecs.CurRow > ListSpecs.LastRow THEN ListSpecs.CurRow = ListSpecs.LastRow: IF ListSpecs.CurRow < ListSpecs.PageRow THEN ListSpecs.PageRow = ListSpecs.CurRow
ListGetTextPos 0, 0
ListSpecs.ListChanged = 0
IF IoErr THEN MessageBar "Entire movie list could not be loaded (" + TotalMovies + ")" ELSE MessageBar "Movie list loaded (" + TotalMovies + ")"

END SUB

SUB MovieListPrint

ON ERROR GOTO FilErrHan
WIDTH LPRINT 80
LPRINT CHR$(4);
MessageBar "Printing movie list"

Bar$ = "Printing (" + FileName + ") -": CurRow = 0: LastRow = ListSpecs.LastRow
DO
 IF FilErr THEN
  MessageBar "Paused, printer error, press Escape to cancel or any other to retry"
  SOUND 900, 1
  DO
   key$ = INKEY$
   IF key$ > "" THEN
    IF key$ = CHR$(27) THEN MessageBar "Printing aborted after error": EXIT SUB
    FilErr = 0: LPRINT CHR$(13);
    IF FilErr = 0 THEN EXIT DO
    SOUND 800, .9
   END IF
  LOOP
 ELSE
  key$ = INKEY$
  IF key$ = " " THEN
   MessageBar "Printing paused by user"
   DO: key$ = INKEY$: LOOP UNTIL key$ > ""
  END IF
  IF key$ = CHR$(27) THEN
   MessageBar "Printing cancelled": EXIT SUB
  END IF
 END IF
 ListTextGet CurRow, 0, Text$: LPRINT LEFT$(Text$, 22); TAB(24);
 ListTextGet CurRow, 1, Text$: LPRINT LEFT$(Text$, 57)
 IF CurRow >= LastRow THEN EXIT DO ELSE CurRow = CurRow + 1
 MessageBar Bar$ + STR$((100& * CurRow) \ ListSpecs.LastRow) + "%"
LOOP
LPRINT CHR$(12);
ON ERROR GOTO 0

MessageBar "Done printing"

END SUB

SUB MovieListSave (IoErr)

MessageBar "Saving movie list"
ON ERROR GOTO FilErrHan
OPEN FilePath$ + FileName$ FOR OUTPUT AS #1
IF FilErr THEN
 CLOSE #1: ON ERROR GOTO 0
 MessageBar "Can not open (" + FileName$ + ") for file output": IoErr = 1
 EXIT SUB
END IF

CurRow = 0: CurCol = 0: TextPos = 1: ListPtr = 0
DO
 PRINT #1, MID$(MovieList$, TextPos, ListPtrs(ListPtr))
 IF FilErr THEN EXIT DO
 TextPos = TextPos + ListPtrs(ListPtr): ListPtr = ListPtr + 1
 IF CurCol >= ListMaxCol THEN
  IF CurRow >= ListSpecs.LastRow THEN EXIT DO ELSE CurRow = CurRow + 1: CurCol = 0
 ELSE
  CurCol = CurCol + 1
 END IF
LOOP
CLOSE #1
ON ERROR GOTO 0
IF FilErr THEN
 MessageBar "Could not write to disk": IoErr = 1
ELSE
 ListSpecs.ListChanged = 0
 MessageBar "Movie list saved (" + TotalMovies$ + ")"
END IF

END SUB

SUB MovieListSort

MessageBar "Sorting list (" + TotalMovies + ")"

BaseRow = 0: BasePos = 0: LastRow = ListSpecs.LastRow
REDIM TempListPtrs(0 TO ListMaxCol)
a& = TIMER
DO
 Text$ = MID$(MovieList$, BasePos + 1, ListPtrs(BaseRow * ListCols))
 ClosestText$ = Text$
 MovePos = BasePos: MoveRow = BaseRow: TextPos = BasePos
 FOR CheckRow = BaseRow + 1 TO LastRow
  CurPtr = CheckRow * ListCols
  FOR CheckPtr = 0 TO ListMaxCol
   TextPos = TextPos + ListPtrs(CurPtr + CheckPtr - ListCols)
  NEXT CheckPtr
  IF MID$(MovieList$, TextPos + 1, ListPtrs(CurPtr)) < Text$ THEN
   MoveRow = CheckRow: MovePos = TextPos
   Text$ = MID$(MovieList$, TextPos + 1, ListPtrs(CurPtr))
  END IF
 NEXT CheckRow
 IF MoveRow > BaseRow THEN
  CurPtr = MoveRow * ListCols: Leng = 0
  FOR CheckPtr = 0 TO ListMaxCol
   Leng = Leng + ListPtrs(CurPtr + CheckPtr)
   TempListPtrs(CheckPtr) = ListPtrs(CurPtr + CheckPtr)
  NEXT CheckPtr
  IF MovePos > BasePos THEN
   Text$ = MID$(MovieList$, MovePos + 1, Leng)
   MID$(MovieList$, BasePos + Leng + 1) = MID$(MovieList$, BasePos + 1, MovePos - BasePos)
   MID$(MovieList$, BasePos + 1) = Text$ 'Move entry to BackText$'s position
  END IF
  FOR CheckPtr = MoveRow * ListCols - 1 TO BaseRow * ListCols STEP -1
   ListPtrs(CheckPtr + ListCols) = ListPtrs(CheckPtr)
  NEXT CheckPtr
  CurPtr = BaseRow * ListCols
  FOR CheckPtr = 0 TO ListMaxCol
   ListPtrs(CurPtr + CheckPtr) = TempListPtrs(CheckPtr)
  NEXT CheckPtr
 END IF
 LOCATE , 1: PRINT STR$(BaseRow + 1);

 IF BaseRow >= LastRow OR INP(96) = 1 THEN WaitKey: EXIT DO
 CurPtr = BaseRow * ListCols
 FOR CheckPtr = 0 TO ListMaxCol: BasePos = BasePos + ListPtrs(CurPtr + CheckPtr): NEXT CheckPtr
 BaseRow = BaseRow + 1
LOOP
b& = TIMER
MessageBar STR$(BaseRow + 1) + " lines were sorted in" + STR$(b& - a&) + " seconds"

ListGetTextPos 0, 0
ListSpecs.PreRow = ListSpecs.CurRow
ListShowLine 0, ListSpecs.LastRow, 0

END SUB

SUB MovieListSortBak

BaseRow = 0: BasePos = 0: LastRow = ListSpecs.LastRow
REDIM TempListPtrs(0 TO ListMaxCol)
DO
 : COLOR 7, 0: CLS
 'ListShowLine 2, 24, 1: SLEEP
 Text$ = MID$(MovieList$, BasePos + 1, ListPtrs(BaseRow * ListCols))
 PRINT "Pretext:"; BaseRow; BasePos; ListPtrs(BaseRow * ListCols); TAB(24); LEFT$(Text$ + "", 55); ""
 ClosestText$ = Text$
 MovePos = BasePos: MoveRow = BaseRow: TextPos = BasePos
 FOR CheckRow = BaseRow + 1 TO LastRow
  CurPtr = CheckRow * ListCols
  FOR CheckPtr = 0 TO ListMaxCol
   TextPos = TextPos + ListPtrs(CurPtr + CheckPtr - ListCols)
  NEXT CheckPtr
  : PRINT "Compare:"; CheckRow; TextPos; TAB(22); LEFT$(MID$(MovieList$, TextPos + 1, ListPtrs(CurPtr)) + "", 55); "";
  IF MID$(MovieList$, TextPos + 1, ListPtrs(CurPtr)) > Text$ THEN
   : LOCATE , 20: PRINT ">";
   MoveRow = CheckRow: MovePos = TextPos
   Text$ = MID$(MovieList$, TextPos + 1, ListPtrs(CurPtr))
  END IF
  : IF (CheckRow - BaseRow) MOD 23 = 0 THEN SLEEP
  PRINT
 NEXT CheckRow
 'SLEEP
 : COLOR 0, 3: PRINT " Stats and other numbers "; : COLOR 7, 0: PRINT
 : PRINT "  Base row"; BaseRow; " Base pos"; BasePos; " Shift bytes"; MovePos - BasePos; " List Len"; LEN(MovieList$)
 IF MoveRow > BaseRow THEN
  CurPtr = MoveRow * ListCols: Leng = 0
  FOR CheckPtr = 0 TO ListMaxCol
   Leng = Leng + ListPtrs(CurPtr + CheckPtr)
   TempListPtrs(CheckPtr) = ListPtrs(CurPtr + CheckPtr)
  NEXT CheckPtr
  : PRINT "  Move row"; MoveRow; " Move pos"; MovePos; " Move length"; Leng
  Text$ = MID$(MovieList$, MovePos + 1, Leng)
  : COLOR 0, 3: PRINT " Move text, Length"; Leng; : COLOR , 0: COLOR 7, 0: PRINT : PRINT LEFT$(Text$, 478) + "<<"
  : COLOR 0, 3: PRINT " To be shifted, Length"; MovePos - BasePos: COLOR 7, 0: PRINT LEFT$(MID$(MovieList$, BasePos + 1, MovePos - BasePos), 478) + "<<"
  IF MovePos > BasePos THEN
   MID$(MovieList$, BasePos + Leng + 1) = MID$(MovieList$, BasePos + 1, MovePos - BasePos)
   MID$(MovieList$, BasePos + 1) = Text$ 'Move entry to BackText$'s position
  END IF
  : COLOR 0, 3: PRINT " Text changed, Length"; LEN(MovieList$): COLOR 7, 0: PRINT LEFT$(MovieList$, 478) + "<<";
  FOR CheckPtr = MoveRow * ListCols - 1 TO BaseRow * ListCols STEP -1
   ListPtrs(CheckPtr + ListCols) = ListPtrs(CheckPtr)
  NEXT CheckPtr
  CurPtr = BaseRow * ListCols
  FOR CheckPtr = 0 TO ListMaxCol
   ListPtrs(CurPtr + CheckPtr) = TempListPtrs(CheckPtr)
  NEXT CheckPtr
 ELSE : PRINT "  No matches for current row";
 END IF
 
 IF BaseRow >= LastRow OR INP(96) = 29 THEN EXIT DO
 WHILE INKEY$ > "": WEND
 DO: key$ = INKEY$: LOOP UNTIL key$ > "": IF key$ = "" THEN EXIT DO
 CurPtr = BaseRow * ListCols
 FOR CheckPtr = 0 TO ListMaxCol: BasePos = BasePos + ListPtrs(CurPtr + CheckPtr): NEXT CheckPtr
 BaseRow = BaseRow + 1
 PRINT : PRINT
LOOP

ListGetTextPos 0, 0
ListShowLine 0, ListSpecs.LastRow, 0

END SUB

SUB MovieListSortOld

CurRow = 0
a& = TIMER
DO UNTIL CurRow >= ListSpecs.LastRow
 ListTextGet CurRow, 0, Text$
 ListTextGet CurRow + 1, 0, NextText$
 IF NextText$ < Text$ THEN
  ListTextPut CurRow, 0, NextText$
  ListTextPut CurRow + 1, 0, Text$
  FOR CurCol = 1 TO ListMaxCol
   ListTextGet CurRow, CurCol, Text$: ListTextGet CurRow + 1, CurCol, NextText$
   ListTextPut CurRow + 1, CurCol, Text$: ListTextPut CurRow, CurCol, NextText$
  NEXT CurCol
  IF INP(96) = 1 THEN WaitKey: EXIT DO
  IF CurRow > 0 THEN CurRow = CurRow - 1
 ELSE
  CurRow = CurRow + 1
 END IF
LOOP
b& = TIMER
MessageBar STR$(CurRow + 1) + " lines were sorted in" + STR$(b& - a&) + " seconds"

ListGetTextPos 0, 0
ListShowLine 0, ListSpecs.LastRow, 0

END SUB

SUB ShowMainMenu (Choice, Mode)

ShowOptionText 1, 3, Choice, Mode, "Quit&Save/Print/Update/Revert/Sort/Find/Goto/Help/About"

END SUB

SUB ShowOptionText (Row, Col, Choice, Mode, Text$)

COLOR , ColorWall
LOCATE Row, Col, 0: ChoiceBeg = 1: ShowChoice = 0
DO
 ChoiceEnd = INSTR(ChoiceBeg, Text$, "/")
 IF ChoiceEnd = 0 THEN ChoiceLen = LEN(Text$) - ChoiceBeg + 1 ELSE ChoiceLen = ChoiceEnd - ChoiceBeg
 IF Mode THEN
  IF ShowChoice = Choice AND Mode THEN COLOR ColorLitFore ELSE COLOR 8
  PRINT MID$(Text$, ChoiceBeg, ChoiceLen);
 ELSEIF ChoiceLen THEN
  COLOR ColorLitFore: PRINT MID$(Text$, ChoiceBeg, 1);
  COLOR ColorLitBack: PRINT MID$(Text$, ChoiceBeg + 1, ChoiceLen - 1);
 END IF
 IF ChoiceEnd THEN PRINT "  ";  ELSE EXIT DO
 ShowChoice = ShowChoice + 1
 ChoiceBeg = ChoiceEnd + 1
LOOP


END SUB

FUNCTION TotalMovies$
TotalMovies$ = LTRIM$(STR$(ListSpecs.LastRow + 1)) + " lines"
END FUNCTION

SUB TypePrompt (Text$, key$, ScrnRow, ScrnCol, VisLen, RecLen, Curp, Ofst, InChng, OutChng)

Leng = LEN(Text$): IF Curp > Leng THEN Curp = Leng

SELECT CASE key$
CASE " " TO "~", "€" TO "ÿ": IF LEN(key$) + LEN(Text$) > RecLen THEN SOUND 1024, .1 ELSE Text$ = LEFT$(Text$, Curp) + key$ + RIGHT$(Text$, LEN(Text$) - Curp): Curp = Curp + 1: InChng = 3
CASE CHR$(8): IF Curp > 0 AND Leng THEN Text$ = LEFT$(Text$, Curp - 1) + RIGHT$(Text$, Leng - Curp): Curp = Curp - 1: InChng = 3
CASE "": IF Leng AND Curp < Leng THEN Text$ = LEFT$(Text$, Curp) + RIGHT$(Text$, Leng - Curp - 1): InChng = 3
CASE CHR$(0) + "K": IF Curp THEN Curp = Curp - 1: InChng = 1
CASE CHR$(0) + "M": IF Curp < Leng THEN Curp = Curp + 1: InChng = 1
CASE CHR$(0) + "G": Curp = 0: InChng = 1
CASE CHR$(0) + "O": Curp = Leng: InChng = 1
END SELECT

IF InChng THEN
 Leng = LEN(Text$)
 IF Curp < Ofst THEN Ofst = Curp: InChng = InChng + 1 ELSE IF Curp >= Ofst + VisLen THEN Ofst = Curp - VisLen + 1: InChng = InChng + 1
 IF Ofst > Leng THEN Ofst = Leng: InChng = InChng = InChng + 1
 IF InChng > 1 THEN
  COLOR ColorLitBack, ColorBack
  LOCATE , , 0: LOCATE ScrnRow, ScrnCol: PRINT MID$(Text$, Ofst + 1, VisLen);
  IF Leng - Ofst < VisLen THEN PRINT SPACE$(VisLen - Leng + Ofst);
  IF InChng > 2 THEN OutChng = 1
 END IF
 LOCATE , , 1: LOCATE ScrnRow, ScrnCol + (Curp - Ofst)
 InChng = 0
END IF

END SUB

SUB WaitKey

DO UNTIL INP(96) AND 128
 null$ = INKEY$
LOOP
null$ = INKEY$

END SUB

