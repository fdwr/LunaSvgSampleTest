DEFINT A-Z
SCREEN 13

GetFileName:
'Get filename
LOCATE 1, 1: PRINT "File with palette to load or  = * \ ."
INPUT "", k$
CLS
IF k$ = "" THEN
 END
ELSEIF k$ = "=" THEN PALETTE: GOTO CreateBlocks
ELSEIF k$ = "\" THEN OldFile$ = f$: f$ = "C:\WINDOWS\OBBLUE.BMP"
ELSEIF k$ = "." THEN SWAP OldPalet$, Palet$: SWAP OldFile$, f$
ELSEIF INSTR(k$, "*") THEN LOCATE 3, 1: FILES k$: GOTO GetFileName
ELSE OldFile$ = f$: f$ = UCASE$(k$)
END IF
PRINT f$
IF k$ = "." GOTO SetPalette

OPEN f$ FOR INPUT AS 1: CLOSE 1
OPEN f$ FOR BINARY AS 1

'Get palette
OldPalet$ = Palet$
IF INSTR(f$, ".BMP") THEN
 Palet$ = SPACE$(1024)
 GET #1, 40 + 15, Palet$ 'standard windows bmpinfosize = 40
ELSEIF INSTR(f$, ".GIF") THEN
 Palet$ = SPACE$(768)
 GET #1, 13, Palet$ 'standard 256-color gif palette
ELSEIF INSTR(f$, ".PCX") THEN
 Palet$ = SPACE$(768)
 GET #1, LOF(1) - 768, Palet$ 'standard 256-color gif palette
ELSE
 PRINT "Unrecognised file type";
 SLEEP 2
END IF

CLOSE 1

SetPalette:
'Set palette
OUT &H3C8, 0
IF INSTR(f$, ".BMP") THEN
 FOR colors = 1 TO 256 * 4 STEP 4
  OUT &H3C8, setcolor
  OUT &H3C9, ASC(MID$(Palet$, colors + 2, 1)) \ 4
  OUT &H3C9, ASC(MID$(Palet$, colors + 1, 1)) \ 4
  OUT &H3C9, ASC(MID$(Palet$, colors, 1)) \ 4
  setcolor = setcolor + 1
 NEXT colors
ELSEIF INSTR(f$, ".GIF") OR INSTR(f$, ".PCX") THEN
 FOR colors = 1 TO 256 * 3 STEP 3
  OUT &H3C9, ASC(MID$(Palet$, colors, 1)) \ 4
  OUT &H3C9, ASC(MID$(Palet$, colors + 1, 1)) \ 4
  OUT &H3C9, ASC(MID$(Palet$, colors + 2, 1)) \ 4
 NEXT colors
ELSE
 PRINT "No palette set"
 SLEEP 2
END IF

CreateBlocks:
'Show color blocks
blockspace = 10
blocksize = blockspace - 2
toprow = 16
setcolor = 0
FOR row = 1 + toprow TO 16 * blockspace + toprow STEP blockspace
 FOR col = 1 TO 16 * blockspace STEP blockspace
  LINE (col, row)-(col + 8, row + 8), setcolor, BF
  setcolor = setcolor + 1
NEXT col, row

PRINT "Press any key"; : SLEEP
LOCATE , 1: PRINT TAB(40);
GOTO GetFileName

