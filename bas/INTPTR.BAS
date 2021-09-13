DEFINT A-Z

LINE INPUT "Interrupt number:", Num$
IF Num$ = "" THEN END
IF LEN(Num$) > 3 THEN PRINT "Number too great": END
IntPtr = VAL(Num$) * 4
IF IntPtr < 0 OR IntPtr > 255 THEN PRINT "Number out of range": END
DEF SEG = 0
PRINT HEX$(PEEK(IntPtr + 3)); HEX$(PEEK(IntPtr + 2)); ":"; HEX$(PEEK(IntPtr + 1)); HEX$(PEEK(IntPtr))

