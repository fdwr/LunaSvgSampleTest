'This program is still under construction yet

DEFINT A-Z
DECLARE SUB Feed ()
DECLARE SUB Menu (Text$, Choice$)
DECLARE FUNCTION Kbrd$ (Keys$)
DECLARE FUNCTION Data$ (Part%, Ofset%, List$, Entries$)
DECLARE FUNCTION IdLn (EditMode, List$, Entries$)
: DECLARE SUB NOTYET ()

: Feed: Menu "", "     Index Viewer and Editer for simple indexes, types 1 and 2"
COLOR 7: PRINT "Before you can use this indexer, you must choose the way it stores its indexes"
PRINT "Type 2 indexes are smaller in size and hold fewer characters, while type 1"
PRINT "indexes take up more space but can also hold more characters. If you only intend"
PRINT "to make small sentences, use mode 2. If you need entries larger than 255"
PRINT "characters, or bytes, use type 1. For default, type two, press Enter.";
GOSUB QueryClear

MainMenu:
PRINT : Menu "Last file:", UCASE$(File$): COLOR 7: PRINT CHR$(13); "Index Size:"; IdLn(EditMode, List$, Entries$), "Entries:";
IF EditMode THEN PRINT LEN(List$) \ 3,  ELSE PRINT LEN(List$) \ 6,
PRINT , "Index type:"; EditMode + 1
Menu "Add extra entry, Edit entry, View entries, Delete entry", "A, E, V, D"
Menu "View Files, Load from file, Save to file, Print to file", "F, L, S, P"
Menu "Change Index mode, Clear index data, or Quit and exit", "  I, C, Q (Esc)"
DO UNTIL Done
Key$ = UCASE$(INKEY$)
DidGosub = 1
SELECT CASE Key$
CASE "A": GOSUB GetLine: DoSave = 1
CASE "E": NOTYET
CASE "V": GOSUB ViewEntry
CASE "D": NOTYET
CASE "F": Feed: LINE INPUT "Any Parameters? ", Key$
 SHELL "DIR /B/P " + Key$
CASE "L": GOSUB LoadFile
CASE "S", "P": IF Key$ = "P" THEN SaveMode = 1 ELSE SaveMode = 0
 GOSUB SaveFile
CASE "I": GOSUB IndexModeChange
CASE "C", CHR$(8)
 GOSUB QueryClear
CASE "Q", CHR$(27)
 IF DoSave THEN
: Feed: Menu "Do you want to first save your index?", "Yes No Cancel"
  Key$ = Kbrd$("YNC"): IF Key$ = "Y" THEN GOSUB SaveFile
 END IF
 IF Key$ = "N" OR (Key$ = "S" AND DoSave = 0) OR DoSave = 0 THEN Done = -1
 IF Key$ = "C" THEN PRINT
CASE ELSE: DidGosub = 0
END SELECT
IF DidGosub AND Done = 0 THEN GOTO MainMenu
LOOP
PRINT : SYSTEM

QueryClear:
 PRINT CHR$(13)
 Key$ = "Y"
 IF List$ > "" OR Entries$ > "" THEN
  Menu "Are you sure?", "Y N": Key$ = Kbrd$("YN")
  IF Key$ = "Y" THEN Entries$ = "": List$ = "": DoSave = 0: PRINT
 END IF
 IF Key$ = "Y" THEN Menu "What type of index do you want to use?", "1, 2": Key$ = Kbrd$("12" + CHR$(13)): IF Key$ = CHR$(13) THEN EditMode = 1 ELSE EditMode = VAL(Key$) - 1
 PRINT
RETURN
GetLine: Feed
Menu "Filename:", "": LINE INPUT Entry$: GOSUB AddEntry
Menu "Date:", "": LINE INPUT Entry$: GOSUB AddEntry
Menu "Decription:", "": LINE INPUT Entry$: GOSUB AddEntry
RETURN

AddEntry:
IF EditMode THEN List$ = List$ + CHR$(LEN(Entry$)) ELSE List$ = List$ + MKI$(LEN(Entries$) + 1)
Entries$ = Entries$ + Entry$
RETURN

ViewEntry: Feed
IF LEN(List$) = 0 THEN Menu "There are no entries to view", "": PRINT : RETURN
Menu "Enter an entry number or `?' for all (ENTER to cancel):", "": LINE INPUT Entry$: Entry = VAL(Entry$)
IF Entry$ = "" THEN RETURN ELSE IF EditMode THEN Last = LEN(List$) \ 3 ELSE Last = LEN(List$) \ 6
IF Entry < 0 OR Entry > Last THEN Menu "Entry does not exist, valid range is", "1 -" + STR$(Last): GOTO ViewEntry
ON ERROR GOTO IdxErrHan
IF Entry$ = "?" THEN
 FOR Entry = 1 TO Last: GOSUB ShowEntry: NEXT Entry
ELSEIF Entry = 0 THEN
ELSE GOSUB ShowEntry
END IF
ON ERROR GOTO 0
RETURN

ShowEntry:
Menu "Ä" + STR$(Entry) + " " + STRING$(20, 196), "": PRINT
IF EditMode THEN
 FOR Show = Entry * 3 - 2 TO Entry * 3
  PRINT Data$(Show, 0, List$, Entries$)
 NEXT Show
ELSE
13 FOR Show = Entry * 6 - 5 TO Entry * 6 STEP 2
 Prt1 = CVI(MID$(List$, Show, 2))
 IF Show + 1 >= LEN(List$) THEN Prt2 = LEN(Entries$) + 1 ELSE Prt2 = CVI(MID$(List$, Show + 2, 2))
 PRINT MID$(Entries$, Prt1, Prt2 - Prt1)
NEXT Show
END IF
RETURN

LoadFile: FilErr = 0
: Feed: Menu "Enter a DOS filename (ENTER to cancel):", "": LINE INPUT FileName$
IF FileName$ = "" THEN RETURN ELSE ON ERROR GOTO FilErrHan
OPEN FileName$ FOR INPUT AS #1: IF FilErr = 1 THEN PRINT "File not found": GOTO LoadFile ELSE IF FilErr THEN GOTO LoadFile
CLOSE #1: OPEN FileName$ FOR BINARY AS #1: SEEK #1, 1: Type$ = INPUT$(ASC(INPUT$(1, 1)), 1)
IF Type$ <> "IDX1" AND Type$ <> "IDX2" THEN
 Menu "This appears to be an unrecognised index...Load it anyway?", "Y N": PRINT
 Key$ = Kbrd$("YN"): IF Key$ = "N" THEN CLOSE #1: RETURN
END IF
PRINT "Loading"
IF Type$ = "IDX1" THEN EditMode = 0 ELSE EditMode = 1
SEEK #1, SEEK(1) + 2
PointBytes = CVI(INPUT$(2, 1)): List$ = "": List$ = INPUT$(PointBytes, 1): Entries$ = "": Entries$ = INPUT$(LOF(1) - SEEK(1) + 1, 1): Type$ = ""
CLOSE #1: ON ERROR GOTO 0
File$ = FileName$: DoSave = 0
RETURN

SaveFile: FilErr = 0: CLOSE #1
: Feed: Menu "Enter a DOS filename (ENTER to cancel):", "": LINE INPUT FileName$
IF FileName$ = "" THEN RETURN ELSE ON ERROR GOTO FilErrHan
OPEN FileName$ FOR INPUT AS #1
IF FilErr = 0 THEN
 Menu "This file or device already exists...Write over it?", "Y N"
 Key$ = Kbrd$("YN"): PRINT : IF Key$ = "N" THEN RETURN
 CLOSE #1
ELSEIF FilErr = -1 THEN GOTO SaveFile
END IF
OPEN FileName$ FOR OUTPUT AS #1

IF SaveMode = 0 THEN
 IF EditMode = 0 OR EditMode = 1 THEN  ELSE RETURN
 PRINT "Saving"
 PRINT #1, CHR$(4); : IF EditMode THEN PRINT #1, "IDX2" ELSE PRINT #1, "IDX1";
 PRINT #1, CHR$(0); CHR$(3); MKI$(LEN(List$)); List$; Entries$;
 File$ = FileName$: DoSave = 0
ELSE
 ON ERROR GOTO IdxErrHan
 PRINT "Printing"
 IF EditMode THEN
  FOR Show = 1 TO LEN(List$)
   PRINT #1, Data$(Show, 0, List$, Entries$)
   IF Show MOD 3 = 0 THEN PRINT #1,
  NEXT Show
 ELSE
  Leng = LEN(List$) - 1
  FOR Show = 1 TO Leng STEP 2
   Prt1 = CVI(MID$(List$, Show, 2))
   IF Show >= Leng THEN Prt2 = LEN(Entries$) + 1 ELSE Prt2 = CVI(MID$(List$, Show + 2, 2))
   PRINT #1, MID$(Entries$, Prt1, Prt2 - Prt1)
   IF Show MOD 6 = 5 THEN PRINT #1,
  NEXT Show
 END IF
END IF
CLOSE #1: ON ERROR GOTO 0
RETURN

IndexModeChange:
IF EditMode = 1 THEN Last = LEN(List$): ListTemp$ = SPACE$(LEN(List$) * 2) ELSE Last = LEN(List$) \ 2: ListTemp$ = SPACE$(LEN(List$) \ 2)
: Feed: PRINT "Changing index mode"
IF EditMode = 0 THEN
 FOR Entry = 0 TO Last - 1
  Prt1 = CVI(MID$(List$, Entry * 2 + 1, 2))
  IF (Entry * 2) + 2 >= LEN(List$) THEN Prt2 = LEN(Entries$) + 1 ELSE Prt2 = CVI(MID$(List$, (Entry * 2) + 3, 2))
  MID$(ListTemp$, Entry + 1, 1) = CHR$(Prt2 - Prt1)
 NEXT Entry
 List$ = ListTemp$
 EditMode = 1
ELSE
 FOR Entry = 1 TO Last
 NEXT Entry
END IF
ListTemp$ = ""
PRINT "Index mode changed"
RETURN

FilErrHan:
IF ERR <> 53 THEN
PRINT : PRINT "The file name you entered isn't acceptable ?"
PRINT "Try a different file name or respell this one"
FilErr = -1
ELSE FilErr = 1
END IF
RESUME NEXT

IdxErrHan:
IF ERL = 13 THEN Feed: PRINT "There is a pointer error in this index"
PRINT "I can work with it. It might not be in index format"
RESUME MainMenu

FUNCTION Data$ (Part, Ofset, List$, Entries$)
Ofset = 1
IF Part > LEN(List$) OR Part < 1 THEN Data$ = "": EXIT FUNCTION
FOR Show = 1 TO Part - 1
 Ofset = Ofset + ASC(MID$(List$, Show, 1))
NEXT Show
Leng = ASC(MID$(List$, Part, 1))
Data$ = MID$(Entries$, Ofset, Leng)
END FUNCTION

DEFSNG A-Z
SUB Feed : PRINT CHR$(13): END SUB

DEFINT A-Z
FUNCTION IdLn (IdxMode, List$, Entries$)
SELECT CASE IdxMode
CASE 0, 1: IdLn = LEN(List$) + LEN(Entries$) + 9
END SELECT
END FUNCTION

DEFSNG A-Z
FUNCTION Kbrd$ (Keys$)
 DO
  Key$ = INKEY$
  IF LEN(Key$) = 1 THEN Key$ = UCASE$(Key$): IF INSTR(Keys$, Key$) THEN Kbrd = Key$: EXIT FUNCTION
 LOOP
END FUNCTION

SUB Menu (Text$, Choice$)
COLOR 7: PRINT Text$; "  "; : COLOR 15: PRINT Choice$;
END SUB

DEFINT A-Z
SUB NOTYET
Feed
PRINT "That function has not yet been added..."
END SUB

