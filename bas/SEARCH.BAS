DIM List$, Byte%, Adrs&, Mseg&
OPEN "SRCHLIST.TXT" FOR BINARY AS #1: List$ = INPUT$(LOF(1), #1): CLOSE #1: OPEN "SRCHLIST.TXT" FOR APPEND AS #1
LINE INPUT "Annotation:", Name$: PRINT #1, "[" + Name$; "]"
Start:
FOR Mseg& = 0 TO 65535 STEP 4096
DEF SEG = Mseg&
FOR Adrs& = 0 TO 65535
'place  here what you want: locate, color, screen...
:
Byte% = PEEK(Adrs&)
'place  here what you want: locate, color, screen...
:
IF Byte% <> PEEK(Adrs&) THEN GOSUB Active
NEXT Adrs&
NEXT Mseg&
CLS : PRINT List$
PLAY "L60O1CEGO2CEGO3C"
WHILE INKEY$ > "": WEND
WHILE INKEY$ = "": PRINT CHR$(RND * 200 + 50); CHR$(29); : WEND
END

Active:
SOUND 1024, .1
Entry$ = "(" + STR$(Mseg&) + "-" + STR$(Adrs&) + ")" + STR$(Mseg& * 16 + Adrs&)
IF INSTR(List$, Entry$) THEN PreFix$ = "**" ELSE PreFix$ = ""
List$ = List$ + PreFix$ + Entry$ + CHR$(13): PRINT #1, PreFix$ + TIME$ + Entry$
RETURN

