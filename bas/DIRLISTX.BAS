DEFINT A-Z
DECLARE FUNCTION DeComma$ (text$)
DECLARE FUNCTION SelectPart$ (text$, Part, Ofst)
Nl$ = CHR$(13)

CLS : VIEW PRINT: LOCATE , , 0

PRINT "ÄÄ Directory size lister ÄÄ"; Nl$
PRINT "  This program creates a list of how many files are in each main directory and"
PRINT "how much space each one holds on the hard disk. You can choose a different"
PRINT "directory though by pressing D at the choice of what directory to make a list."
PRINT "Whatever directory is chosen, it will show the space taken by each child (or"
PRINT "subdirectory) of the parent one."; Nl$
PRINT "  It sends the results to a file called DIRSIZE.TXT. If would like to only see"
PRINT "the results on the screen, you can press S and it will not send any information"
PRINT "to DIRSIZE.TXT. Pressing F will send it only to the file. Pressing ENTER will"
PRINT "show the information on both the screen and to the file. Once the file is made,"
PRINT "you can use DirSizer to view the data on graphically with scales for both the"
PRINT "total number of files and bytes."; Nl$
PRINT "Do not press Ctrl+Break because during the information gathering because"
PRINT " (a) It may make the results inaccurate"
PRINT "      It causes a break in the info gathering process"
PRINT " (b) It will not do anything anyway"
PRINT "      The keypress is received by the command prompt"
PRINT "To stop and abort, just press ESCAPE instead"; Nl$

PRINT "Press S, F, or ENTER to continue, any other key cancels"
DO: kbrd$ = UCASE$(INKEY$): LOOP UNTIL kbrd$ > ""
IF kbrd$ <> "F" AND kbrd$ <> CHR$(13) AND kbrd$ <> "S" THEN END
ToScrn = 1: ToFile = 1
IF kbrd$ = "S" THEN ToFile = 0: PRINT "To screen only"
IF kbrd$ = "F" THEN ToScrn = 0: PRINT "To file only"
IF ToScrn AND ToFile THEN PRINT "To both screen and file"

PRINT Nl$; "Create list on current, root, or another directory"
PRINT "Press C, R, A, or ENTER (for root) to start";
DO: kbrd$ = UCASE$(INKEY$): LOOP UNTIL kbrd$ > "": PRINT
IF kbrd$ <> "R" AND kbrd$ <> CHR$(13) AND kbrd$ <> "C" AND kbrd$ <> "A" THEN END
IF kbrd$ = "R" OR kbrd$ = CHR$(13) THEN
 CHDIR "C:\"
ELSEIF kbrd$ = "A" THEN
 PRINT Nl$; "Type in a name or press ENTER to cancel";
 ON ERROR GOTO FilErrHan
 DO
  PRINT : LINE INPUT "Directory: "; DirName$
  IF DirName$ = "" THEN END
  FilErr = 0: CHDIR DirName$
  IF FilErr THEN
   PRINT "No such directory or full path is not included"
  ELSE EXIT DO
  END IF
 LOOP
END IF

SHELL "DIR /AD/B > c:\~DIRLIST.TMP"
OPEN "c:\~DIRLIST.TMP" FOR INPUT AS #1
IF ToFile THEN OPEN "DIRSIZE.TXT" FOR OUTPUT AS #3
IF ToFile THEN PRINT #3, "          "
SHELL "CD > c:\~SUBLIST.TMP"
OPEN "c:\~SUBLIST.TMP" FOR INPUT AS #2
LINE INPUT #2, InfoLine$
IF ToFile THEN PRINT #3, InfoLine$
CLOSE #2

Entries = 0
DO UNTIL EOF(1)
 LINE INPUT #1, DirLine$
 IF ToScrn THEN PRINT Nl$; "Reading Directory: "; DirLine$;
 IF ToFile THEN PRINT #3, DirLine$
 Entries = Entries + 1: DirFiles& = 0: DirSize& = 0
 SHELL "DIR " + DirLine$ + " /S/A-D > c:\~SUBLIST.TMP"
 OPEN "c:\~SUBLIST.TMP" FOR INPUT AS #2
 DO
  LINE INPUT #2, InfoLine$
  IF INSTR(InfoLine$, "Total files") THEN EXIT DO
  IF INSTR(InfoLine$, "file(s)") THEN
   IF ToScrn THEN PRINT Nl$; InfoLine$;
   DirFiles& = DirFiles& + VAL(LEFT$(DeComma(SelectPart(InfoLine$, 1, 0)), 9))
   DirSize& = DirSize& + VAL(LEFT$(DeComma(SelectPart(InfoLine$, 3, 0)), 9))
  END IF
 LOOP UNTIL EOF(2)
 CLOSE #2
 TotalDirFiles& = TotalDirFiles& + DirFiles&
 TotalDirSize& = TotalDirSize& + DirSize&
 IF ToScrn THEN PRINT Nl$; DirFiles&; "total files", DirSize&; "total bytes";
 IF ToFile THEN PRINT #3, LTRIM$(STR$(DirFiles&)): PRINT #3, LTRIM$(STR$(DirSize&))
 IF INKEY$ = CHR$(27) THEN
  IF ToScrn AND DirLine$ > "" THEN PRINT
  PRINT "Search stopped by user"; : EXIT DO
 END IF
LOOP
PRINT Nl$; Nl$; "Total directories"; Entries
PRINT "Total dir files"; TotalDirFiles&
PRINT "Total dir bytes"; TotalDirSize&
IF ToFile THEN SEEK 3, 1: PRINT #3, LTRIM$(STR$(Entries));

CLOSE

KILL "c:\~DIRLIST.TMP"
KILL "c:\~SUBLIST.TMP"

END

FilErrHan:
FilErr = 1
RESUME NEXT

FUNCTION DeComma$ (text$)

Search = 1
outText$ = text$
DO UNTIL Search > LEN(outText$)
 IF MID$(outText$, Search, 1) = "," THEN outText$ = LEFT$(outText$, Search - 1) + RIGHT$(outText$, LEN(outText$) - Search) ELSE Search = Search + 1
LOOP

DeComma = outText$

END FUNCTION

FUNCTION SelectPart$ (text$, Part, Ofst)

FOR Search = 1 TO LEN(text$)
 IF MID$(text$, Search, 1) = " " THEN Son = 0 ELSE IF Son = 0 THEN Son = -1: Ofst = Search: Count = Count + 1: IF Count >= Part THEN EXIT FOR
NEXT Search

IF Count < Part THEN
 Ofst = LEN(text$)
 SelectPart$ = ""
ELSE
 IF INSTR(Ofst, text$, " ") THEN Dlmt = INSTR(Ofst, text$, " ") - 1 ELSE Dlmt = LEN(text$)
 SelectPart$ = MID$(text$, Ofst, Dlmt - Ofst + 1)
END IF

END FUNCTION

