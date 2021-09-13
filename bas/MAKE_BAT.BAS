DEFINT A-Z
DECLARE SUB ShowMainMenu (Choice, Mode)
DECLARE SUB FileLoad (File$, IoErr)
DECLARE SUB FileSave (File$, IoErr)
DECLARE FUNCTION FileIo (FileName$, Mode)
DECLARE SUB MovieListSort ()
DECLARE SUB MovieListSortOld ()
DECLARE SUB FilePrint ()
DECLARE SUB ListEditor (key$, MenuKey$)
DECLARE SUB ListTextGet (CurRow, Text$)
DECLARE SUB ListTextPut (CurRow, Text$)
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
DECLARE SUB ShowScrollBar ()
DECLARE FUNCTION TotalMovies$ ()

TYPE ListSpecsType
CurRow AS INTEGER
CurCol AS INTEGER
PreRow AS INTEGER
PreCol AS INTEGER
PageRow AS INTEGER
LastRow AS INTEGER
TextPtr AS INTEGER
TextPos AS INTEGER
TextAlter AS INTEGER
END TYPE

CONST ColorFore = 7, ColorBack = 1, ColorWall = 3, ColorSelect = 9, ColorLitFore = 15, ColorLitBack = 11
CONST ListMaxRow = 1023, MaxListLen = 10000, MaxLineLen = 255
CONST ListScrnTop = 2, ListScrnBtm = 24, ListScrnLft = 2, ListScrnRit = 78, ListPromptWidth = 77, ListScrnScrlV = 80
DIM SHARED ListScrnHite, ListScrnWdth, FilErr, FileName$
ListScrnHite = ListScrnBtm - ListScrnTop + 1: ListScrnWdth = ListScrnRit - ListScrnLft + 1
DIM SHARED ListText$, ListSpecs AS ListSpecsType, ListPtrs(0 TO ListMaxRow), SearchText$, CrLf$: CrLf$ = CHR$(13) + CHR$(10)
FOR CheckPtr = 1 TO 10: menuKeys$ = menuKeys$ + CHR$(0) + MID$(".!" + CHR$(34) + "#", CheckPtr, 1): NEXT CheckPtr

SCREEN 0: WIDTH 80, 25: LOCATE , , 0, 13, 15
VIEW PRINT: COLOR , ColorWall: CLS

DrawMainScreen:
ShowMainMenu 0, 0
ListShowLine ListScrnTop, ListScrnBtm, 1
DrawListBorder
ShowScrollBar

DO
 ListEditor key$, menuKeys$

 menuFunction = INSTR(menuKeys$, key$)
 IF key$ = CHR$(27) OR menuFunction = 1 THEN
  IF ListSpecs.TextAlter THEN
   COLOR ColorLitFore, ColorWall: CLS : LOCATE , , 0
   CenterText 11, "This file has been edited,"
   CenterText 12, "Would you like to save these changes?"
   ShowOptionText 14, 32, 0, 0, "Yes/No/Cancel"
   WaitKey
   DO
    key$ = INKEY$
    SELECT CASE UCASE$(key$)
    CASE "", "N": EndProgram
    CASE CHR$(13), "Y"
     FileSave FileName$, IoErr: IF IoErr GOTO DrawMainScreen ELSE a! = TIMER: DO UNTIL TIMER - a! > 1 OR INKEY$ > "": LOOP: EndProgram
    CASE "C", "": GOTO DrawMainScreen
    END SELECT
   LOOP
  END IF
  EndProgram
 END IF
 SELECT CASE menuFunction
 CASE 0
 CASE 3: ShowMainMenu 1, 1: IF FileIo(File$, 0) GOTO DrawMainScreen
 CASE 5: ShowMainMenu 2, 1: IF FileIo(File$, 1) GOTO DrawMainScreen
 CASE 7: ShowMainMenu 3, 1: WaitKey: FilePrint
 CASE 9
  ShowMainMenu 4, 1
  IF ListSpecs.TextAlter THEN
   COLOR ColorLitFore, ColorWall: CLS : LOCATE , , 0
   CenterText 11, "Do you really want to reload the file"
   CenterText 12, "And lose your changes to it?"
   ShowOptionText 14, 36, 0, 0, "Yes/No"
   DO
    key$ = INKEY$
    SELECT CASE UCASE$(key$)
    CASE "", "N", "": MessageBar "Revert cancelled": GOTO DrawMainScreen
    CASE CHR$(13), "Y": EXIT DO
    END SELECT
   LOOP
  ELSE WaitKey
  END IF
  FileLoad File$, IoErr
  GOTO DrawMainScreen
 CASE 13: ShowMainMenu 6, 1: GotoLine 0
 CASE 15: ShowMainMenu 7, 1: GotoLine 1: WaitKey
 CASE 19
  ShowMainMenu 9, 1: MessageBar "Created on June something, 1997, by Frank Dwayne Robinson"
  IF PLAY(0) = 0 THEN PLAY "MBt150L24O2CE-GL12A+L24p16CE-Gl12Al24p16CE-GE-l12Cp4L24o4A+GE-L12Cp16L24BGE-L12Cp16L24CE-G>C"
  CALL WaitKey: ShowMainMenu 8, 0
 'CASE "H" 'Help me!
 END SELECT
 ShowMainMenu 0, 0
LOOP

EndProgram

FilErrHan: FilErr = ERR: RESUME NEXT

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

COLOR 7, 0: CLS
SYSTEM

END SUB

FUNCTION FileIo (File$, Mode)

File$ = FileName$: CurCol = LEN(File$)
Urow = 12: Drow = 14: Lcol = 7: Rcol = 74

FileIoRedraw:
LOCATE , , 0: DrawBox Urow, Drow, Lcol, Rcol
COLOR ColorLitBack: LOCATE Urow + 1, Lcol + 2: EntryShow = 2
IF Mode THEN PRINT "Save file:";  ELSE PRINT "Open file:";
MessageBar "Type in a file name"
DO
 key$ = INKEY$
 SELECT CASE key$
 CASE CHR$(27): MessageBar "File operation cancelled": GOTO EndFileIo
 CASE CHR$(13)
  ON ERROR GOTO FilErrHan: FilErr = 0: CHDIR File$
  IF FilErr THEN GOTO GetFile
 CASE ELSE: TypePrompt File$, key$, Urow + 1, Lcol + 13, 53, 127, CurCol, EntryOfset, EntryShow, 0
 END SELECT
LOOP
EXIT FUNCTION

EndFileIo: ListShowLine Urow, Drow, 1: EXIT FUNCTION

GetFile:
 IF FilErr THEN
  IF Mode THEN
   IF File$ = FileName$ THEN
    FileSave File$, IoErr
   ELSE
    FilErr = 0: OPEN File$ FOR INPUT AS #1: CLOSE #1
    IF FilErr = 0 OR FilErr = 53 THEN
     DrawBox Urow, Drow, Lcol, Rcol
     IF FilErr THEN ShowOptionText Urow + 1, 28, 0, 0, " Create new file/Yes/No" ELSE ShowOptionText Urow + 1, 22, 0, 0, " Save over existing file?/Yes/No"
     WaitKey
     DO
      key$ = INKEY$
      SELECT CASE UCASE$(key$)
      CASE "": GOTO EndFileIo
      CASE "N", "": GOTO FileIoRedraw
      CASE CHR$(13), "Y": EXIT DO
      END SELECT
     LOOP
     FileSave File$, IoErr
    ELSE IoErr = 1
    END IF
   END IF
  ELSE
   FileLoad File$, IoErr
   IF IoErr = 0 THEN FileIo = 1
  END IF
  IF IoErr = 0 THEN
   FileName$ = File$: GOTO EndFileIo
  ELSE
   DrawBox Urow, Drow, Lcol, Rcol
   COLOR ColorLitBack: CenterText Urow + 1, "File error"
   WHILE INKEY$ = "": WEND
   GOTO FileIoRedraw
  END IF
 ELSE File$ = "": EntryShow = 2
 END IF
RETURN

END FUNCTION

SUB FileLoad (File$, IoErr)

ON ERROR GOTO FilErrHan

FilErr = 0: OPEN File$ FOR INPUT AS 1: CLOSE 1
IF FilErr THEN IoErr = 1: EXIT SUB
OPEN File$ FOR BINARY AS 1: IF LOF(1) = 0 THEN IoErr = 1: CLOSE 1: EXIT SUB

IoErr = 0
MessageBar "Loading batch file"

ListText$ = ""
IF LOF(1) > MaxListLen THEN
 ListText$ = INPUT$(MaxListLen, 1)
 IoErr = 1
ELSE
 ListText$ = INPUT$(LOF(1), 1)
END IF
CLOSE #1
ON ERROR GOTO 0

MessageBar "Parsing batch file"

TextPos = 1
NextLineBreak = INSTR(NextLineBreak + 1, ListText$, CrLf$)
DO WHILE NextLineBreak
 ListPtrs(ListPtr) = NextLineBreak - TextPos
 IF ListPtr >= ListMaxRow THEN IoErr = 1: EXIT DO
 ListPtr = ListPtr + 1: TextPos = NextLineBreak + 2
 NextLineBreak = INSTR(TextPos, ListText$, CrLf$)
LOOP
ListPtrs(ListPtr) = LEN(ListText$) - TextPos + 1
ListSpecs.LastRow = ListPtr
TextPos = ListPtrs(0) + 1
'FOR ListPtr = 1 TO ListSpecs.LastRow
' LineBreak = LineBreak + 2
' Leng = ListPtrs(ListPtr)
' MID$(ListText$, TextPos) = MID$(ListText$, TextPos + LineBreak, Leng)
'NEXT ListPtr

ListSpecs.CurRow = 0: ListSpecs.PreRow = 0: ListSpecs.CurCol = ListPtrs(0): ListSpecs.PageRow = 0
ListGetTextPos 0, 0: ListSpecs.TextAlter = 0
IF IoErr THEN MessageBar "Entire file could not be loaded (" + TotalMovies + ")" ELSE MessageBar "File loaded (" + TotalMovies + ")"

END SUB

SUB FilePrint

ON ERROR GOTO FilErrHan
WIDTH LPRINT 80
LPRINT CHR$(4);
MessageBar "Printing movie list"

Bar$ = "Printing (" + FileName$ + ") -": CurRow = 0: LastRow = ListSpecs.LastRow
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
 ListTextGet CurRow, Text$: LPRINT LEFT$(Text$, 80)
 IF CurRow >= LastRow THEN EXIT DO ELSE CurRow = CurRow + 1
 MessageBar Bar$ + STR$((100& * CurRow) \ ListSpecs.LastRow) + "%"
LOOP
LPRINT CHR$(12);
ON ERROR GOTO 0

MessageBar "Done printing"

END SUB

SUB FileSave (File$, IoErr)

MessageBar "Saving movie list"
FilErr = 0: ON ERROR GOTO FilErrHan
OPEN File$ FOR OUTPUT AS #1
IF FilErr THEN
 CLOSE #1: ON ERROR GOTO 0
 MessageBar "Can not open (" + File$ + ") for file output": IoErr = 1
 EXIT SUB
END IF

IoErr = 0: CurRow = 0: CurCol = 0: TextPos = 1: ListPtr = 0
DO
 PRINT #1, MID$(ListText$, TextPos, ListPtrs(ListPtr))
 IF FilErr THEN EXIT DO
 TextPos = TextPos + ListPtrs(ListPtr): ListPtr = ListPtr + 1
 IF CurRow >= ListSpecs.LastRow THEN EXIT DO ELSE CurRow = CurRow + 1
LOOP
CLOSE #1
ON ERROR GOTO 0
IF FilErr THEN
 MessageBar "Could not write to disk": IoErr = 1
ELSE
 ListSpecs.TextAlter = 0
 MessageBar "Movie list saved (" + TotalMovies$ + ")"
END IF

END SUB

SUB GotoLine (Mode)

Urow = 12: Drow = 14
IF Mode THEN GOSUB FindLine: EXIT SUB

GotoLineRedraw:
Lcol = 7: Rcol = 74: LOCATE , , 0: DrawBox Urow, Drow, Lcol, Rcol
COLOR ColorLitBack: LOCATE Urow + 1, Lcol + 2: PRINT "Search text:";
MessageBar "Type in text to search for"
EntryShow = 2: CurCol = LEN(SearchText$)
DO
 key$ = INKEY$
 SELECT CASE key$
 CASE CHR$(27): GOSUB GotoLineRedrawBack: MessageBar "Text search cancelled": EXIT SUB
 CASE CHR$(13): GOSUB GotoLineRedrawBack: GOSUB FindLine
  Lcol = 26: Rcol = 53: DrawBox Urow, Drow, Lcol, Rcol
  COLOR 11: LOCATE Urow + 1, Lcol + 2: PRINT "Could not find that text";
  WHILE INKEY$ = "": WEND
  GOTO GotoLineRedraw
 CASE ELSE: TypePrompt SearchText$, key$, Urow + 1, Lcol + 15, 51, MaxLineLen, CurCol, EntryOfset, EntryShow, 0
 END SELECT
LOOP

GotoLineRedrawBack: ListShowLine Urow, Drow, 1: RETURN
FindLine:
 CurRow = ListSpecs.CurRow: UcaseTitle$ = UCASE$(SearchText$)
 DO
  IF CurRow >= ListSpecs.LastRow THEN CurRow = 0 ELSE CurRow = CurRow + 1
  ListTextGet CurRow, Text$
  IF INSTR(UCASE$(Text$), UcaseTitle$) THEN ListMoveCursor CurRow, 0, 3: MessageBar "Jumped to next find of search text": EXIT SUB
 LOOP UNTIL CurRow = ListSpecs.CurRow
 MessageBar "No matches found for '" + LEFT$(SearchText$, 56) + "'"
RETURN

END SUB

SUB ListEditor (key$, menuKeys$) STATIC

EntryShow = 2
GOSUB ListEditorGetPrompt
DO
 key$ = INKEY$
 SELECT CASE key$
 CASE ""
 CASE CHR$(0) + "H": IF ListSpecs.CurRow > 0 THEN GOSUB ListEditorSavePrompt: ListMoveCursor ListSpecs.CurRow - 1, 0, 2: GOSUB ResetCursors: GOSUB ListEditorGetPrompt
 CASE CHR$(0) + "P": IF ListSpecs.CurRow < ListSpecs.LastRow THEN GOSUB ListEditorSavePrompt: ListMoveCursor ListSpecs.CurRow + 1, 0, 2: GOSUB ResetCursors: GOSUB ListEditorGetPrompt
 'CASE CHR$(0) + "s"
 'CASE CHR$(0) + "t"
 CASE CHR$(13)
  GOSUB ListEditorSavePrompt
  IF ListSpecs.CurCol = 0 THEN PtrAdjust = 0 ELSE PtrAdjust = 1
  ListTextLineAdd ListSpecs.CurRow + PtrAdjust
  ListMoveCursor ListSpecs.CurRow + 1, 0, 3
  GOSUB ResetCursors
  GOSUB ListEditorGetPrompt
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
  TypePrompt Text$, key$, EntryScrnRow, ListScrnLft, ListPromptWidth, MaxLineLen, ListSpecs.CurCol, EntryOfset, 0, ListSpecs.TextAlter
 END SELECT
LOOP

GOSUB ListEditorSavePrompt
EXIT SUB

ListEditorGetPrompt:
 'gets the text for the current prompt spot, determines screen row for prompt
 ListTextGet ListSpecs.CurRow, Text$
 EntryScrnRow = (ListSpecs.CurRow - ListSpecs.PageRow) + ListScrnTop
 TypePrompt Text$, "", EntryScrnRow, ListScrnLft, ListPromptWidth, 0, ListSpecs.CurCol, EntryOfset, EntryShow, 0
 EntryShow = 1
RETURN
ListEditorSavePrompt:
 IF ListSpecs.TextAlter THEN ListTextPut ListSpecs.CurRow, Text$
RETURN
ResetCursors: EntryOfset = 0: RETURN

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
 ShowScrollBar
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

TopSelRow = ListSpecs.CurRow: BtmSelRow = ListSpecs.PreRow
IF TopSelRow > BtmSelRow THEN SWAP TopSelRow, BtmSelRow
COLOR , ColorBack
FOR Vrow = TopRow TO BtmRow
 IF CurRow > ListSpecs.LastRow THEN
  COLOR ColorFore
  LOCATE Vrow, ListScrnLft: PRINT STRING$(ListPromptWidth, 176);
 ELSE
  IF CurRow < TopSelRow OR CurRow > BtmSelRow THEN COLOR ColorFore ELSE IF CurRow = ListSpecs.CurRow THEN COLOR ColorLitBack ELSE COLOR ColorSelect
  ListTextGet CurRow, Text$
  LOCATE Vrow, ListScrnLft
  IF LEN(Text$) < ListPromptWidth THEN PRINT Text$; SPACE$(ListPromptWidth - LEN(Text$));  ELSE PRINT LEFT$(Text$, ListPromptWidth);
  CurRow = CurRow + 1
 END IF
NEXT Vrow

END SUB

SUB ListTextGet (CurRow, Text$)

Text$ = ""
IF CurRow < 0 OR CurRow > ListSpecs.LastRow THEN STOP: EXIT SUB
IF CurRow > ListMaxRow THEN STOP: EXIT SUB

ListGetTextPos CurRow, TextPos
Text$ = MID$(ListText$, TextPos + 1, ListPtrs(CurRow))

END SUB

SUB ListTextLineAdd (CurRow)

IF CurRow < 0 OR CurRow - 1 > ListSpecs.LastRow THEN EXIT SUB
IF CurRow >= ListMaxRow THEN SOUND 1024, .3: EXIT SUB
FOR CheckPtr = ListSpecs.LastRow TO CurRow STEP -1
 ListPtrs(CheckPtr + 1) = ListPtrs(CheckPtr)
NEXT CheckPtr
ListPtrs(CurRow) = 0
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
 ListGetTextPos FrstRow, TextPos
 ListPtr = FrstRow
 FOR CheckRow = FrstRow TO LastRow
  Leng = Leng + ListPtrs(ListPtr): ListPtr = ListPtr + 1
 NEXT CheckRow
 ListText$ = LEFT$(ListText$, TextPos) + RIGHT$(ListText$, LEN(ListText$) - TextPos - Leng)
 FOR CheckPtr = FrstRow TO ListSpecs.LastRow - RemRows
  ListPtrs(CheckPtr) = ListPtrs(CheckPtr + RemRows)
 NEXT CheckPtr
 OldRow = ListSpecs.LastRow: ListSpecs.LastRow = ListSpecs.LastRow - RemRows
 IF FrstRow > ListSpecs.LastRow THEN TopRow = ListSpecs.LastRow ELSE TopRow = FrstRow
 ListSpecs.PreRow = TopRow: ListMoveCursor TopRow, 0, 2
ELSE
 ListText$ = "": ListPtrs(0) = 0: OldRow = ListSpecs.LastRow: ListSpecs.LastRow = 0
 ListSpecs.CurRow = 0: ListSpecs.PreRow = 0: ListSpecs.PageRow = 0
END IF
ListShowLine FrstRow, OldRow, 0

END SUB

SUB ListTextPut (CurRow, Text$)

IF CurRow < 0 OR CurRow - 1 > ListSpecs.LastRow THEN STOP: EXIT SUB
IF CurRow > ListMaxRow THEN STOP: EXIT SUB

ListGetTextPos CurRow, TextPos: PtrAdjust = LEN(Text$) - ListPtrs(CurRow)
IF PtrAdjust > 0 THEN
 ListText$ = LEFT$(ListText$, TextPos) + SPACE$(PtrAdjust) + RIGHT$(ListText$, LEN(ListText$) - TextPos)
ELSEIF PtrAdjust < 0 THEN
 ListText$ = LEFT$(ListText$, TextPos) + RIGHT$(ListText$, LEN(ListText$) - TextPos + PtrAdjust)
END IF
ListPtrs(CurRow) = LEN(Text$): IF LEN(Text$) THEN MID$(ListText$, TextPos + 1) = Text$

END SUB

SUB MessageBar (Text$)

COLOR ColorBack, ColorWall
LOCATE 25, 1: PRINT SPACE$(80);
CenterText 25, Text$

END SUB

SUB ShowMainMenu (Choice, Mode)

ShowOptionText 1, 3, Choice, Mode, "Quit/Open/Save/Print/Revert/Copy/Find/Goto/Help/About"

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

SUB ShowScrollBar

CurRow = (ListScrnHite * ListSpecs.CurRow) \ (ListSpecs.LastRow + 1) + ListScrnTop
COLOR ColorLitBack, ColorBack
FOR Vrow = ListScrnTop TO ListScrnBtm
 LOCATE Vrow, ListScrnScrlV
 IF Vrow <> CurRow THEN PRINT "°";  ELSE PRINT "Û";
NEXT Vrow

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

