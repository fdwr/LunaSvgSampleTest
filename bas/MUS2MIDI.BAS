DIM file AS STRING

FOR filenum = 0 TO 28
    file$ = "rip" + RIGHT$("0000" + LTRIM$(STR$(filenum)), 4)
    SHELL "C:\programs\ripper5\mus2midi.exe " + file$ + ".MUS " + file$ + ".MID"
NEXT

