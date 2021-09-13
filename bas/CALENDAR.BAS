'1-22-97 885 bytes
DECLARE SUB CENTER (Ulin%, text$)

DIM ms$(1 TO 12)
FOR GetDates% = 1 TO 12
 READ ms$(GetDates%)
 DATA "January","February","March","April","May","June","July","August","September","October","November","December"
NEXT GetDates%

LOCATE , , 0
COLOR 3, 7
CENTER 9, "Û" + STRING$(30, "ß") + "Û"
CENTER 10, "Û" + SPACE$(30) + "Û"
CENTER 11, "Û" + SPACE$(30) + "Û"
CENTER 12, "Û" + STRING$(30, "Ü") + "Û"

WHILE INKEY$ = ""
 tempdat$ = DATE$: temptim$ = TIME$
 COLOR 11: CENTER 10, "Day" + STR$(VAL(MID$(DATE$, 4, 2))) + " of " + ms$(VAL(MID$(DATE$, 1, 2))) + "," + " Year " + MID$(DATE$, 7, 4)
 COLOR 15: CENTER 11, MID$(tempdat$, 7, 4) + ":" + LEFT$(tempdat$, 2) + ":" + MID$(tempdat$, 4, 2) + ":" + LEFT$(temptim$, 3) + MID$(temptim$, 4, 3) + MID$(temptim$, 7, 2)
WEND

SUB CENTER (Ulin%, text$)
LOCATE Ulin%, CINT((80 - LEN(text$)) / 2): PRINT text$;
END SUB

