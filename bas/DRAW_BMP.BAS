DEFINT A-Z
DECLARE SUB DrawPix (Image$, Iheight%, Iwidth%, Urow%, Lcol%)
DECLARE SUB FileLoad (FileNum, Image$, Iheight, Iwidth, TypErr)
DECLARE SUB UserHelp (Text$)
DECLARE SUB Prompt (Text$, Key$, Info AS ANY)
DECLARE SUB CrtPrompt (Info AS ANY, Urow, Lcol, Colr, Lim, Vis, Curp, Ofst)
TYPE DefPrompt
Lcol AS INTEGER
Urow AS INTEGER
Colr AS INTEGER
Lim AS INTEGER
Vis AS INTEGER
Curp AS INTEGER
Ofst AS INTEGER
END TYPE

SCREEN 0: WIDTH 80, 50: VIEW PRINT

DIM NameInfo AS DefPrompt: CrtPrompt NameInfo, 1, 17, 240, 64, 64, 0, 0
DrawPix "123456werthwertjkhkjqhwbekjqwetqrt", 4, 4, 1, 1
END
DO UNTIL UserDone
 GOSUB GetOpenFileName: IF UserDone THEN EXIT DO
 'OPEN File$ FOR BINARY AS #1

LOOP

WIDTH 80, 25: SYSTEM

GetOpenFileName:
UserHelp "Filename or Esc:"
Prompt File$, "", NameInfo
DO
 Key$ = INKEY$
 SELECT CASE Key$
 CASE ""
 CASE CHR$(27): UserDone = 1: RETURN
 CASE CHR$(13): EXIT DO
 CASE ELSE: Prompt File$, Key$, NameInfo
 END SELECT
LOOP
'***************
RETURN


'Get filename input from user or cancel on Esc
'Verifie file exists
'Open file
'Verify type of picture
'Display file onto screen
'Close file
'Wait for user to enter another filename or cancel

SUB CrtPrompt (Info AS DefPrompt, Urow, Lcol, Colr, Lim, Vis, Curp, Ofst)
Info.Urow = Urow
Info.Lcol = Lcol
Info.Colr = Colr
Info.Lim = Lim
Info.Vis = Vis
Info.Curp = Curp
Info.Ofst = Ofst
END SUB

SUB DrawPix (Image$, Iheight, Iwidth, Urow, Lcol)
IF LEN(Image$) < CSNG(Iheight) * Iwidth THEN EXIT SUB
FOR Vset = 0 TO Iheight - 1
FOR Hset = 0 TO Iwidth - 1
 Bar = ASC(MID$(Image$, Vset * Hset + 1, 1)): COLOR Bar AND 15
 LOCATE Vset + Urow, Hset + Lcol: PRINT "Û";
NEXT Hset, Vset
END SUB

SUB FileLoad (FileNum, Image$, Iheight, Iwidth, TypErr)
TypErr = 0

IF LOF(1) < 1 THEN Image$ = "": TypErr = 1: EXIT SUB
Bar$ = INPUT$(1, 1): Bar$ = INPUT$(ASC(Bar$), 1)
SELECT CASE Bar$
CASE "ASCIIPIX"
CASE ELSE: TypErr = 2: EXIT SUB
END SELECT


END SUB

SUB Prompt (Text$, Key$, Info AS DefPrompt)

Curp = Info.Curp: IF Curp < 0 THEN Curp = LEN(Text$) ELSE IF Curp > LEN(Text$) THEN Curp = LEN(Text$)
Ofst = Info.Ofst: Vis = Info.Vis: IF Ofst > LEN(Text$) THEN Ofst = LEN(Text$)
SELECT CASE Key$
CASE CHR$(0) + "K": IF Curp > 0 THEN Curp = Curp - 1
CASE CHR$(0) + "M": IF Curp < LEN(Text$) THEN Curp = Curp + 1
CASE CHR$(0) + "G": Curp = 0
CASE CHR$(0) + "O": Curp = LEN(Text$)
CASE CHR$(0) + "S": IF Curp < LEN(Text$) THEN Curp = Curp + 1: GOSUB PromptDelete
CASE "": IF Curp > 0 THEN GOSUB PromptDelete
CASE " " TO "ÿ": GOSUB PromptInsert
END SELECT

IF Curp < Ofst THEN Ofst = Curp ELSE IF Curp >= Ofst + Vis THEN Ofst = Curp - Vis + 1
LOCATE , , 0: LOCATE Info.Urow, Info.Lcol: COLOR Info.Colr AND 15, (Info.Colr \ 16) AND 15
Bar$ = SPACE$(Vis): MID$(Bar$, 1) = MID$(Text$, Ofst + 1, Vis): PRINT Bar$;
LOCATE Info.Urow, Info.Lcol + Curp - Ofst, 1
Info.Curp = Curp: Info.Ofst = Ofst
EXIT SUB

PromptInsert:
IF LEN(Text$) < Info.Lim THEN Text$ = LEFT$(Text$, Curp) + Key$ + RIGHT$(Text$, LEN(Text$) - Curp): Curp = Curp + 1
RETURN
PromptDelete:
IF Curp > 0 THEN Text$ = LEFT$(Text$, Curp - 1) + RIGHT$(Text$, LEN(Text$) - Curp): Curp = Curp - 1
RETURN
END SUB

SUB UserHelp (Text$)
COLOR 15, 7: LOCATE 1, 1
IF LEN(Text$) > 80 THEN
 PRINT LEFT$(Text$, 80);
ELSE
 PRINT Text$; SPACE$(80 - LEN(Text$));
END IF
END SUB

