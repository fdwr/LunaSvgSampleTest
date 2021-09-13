     'BXW$ = 10PO%
 PRINT "Dagger              4  power     $ 5.00"
                                                 DW$ = "dagger"
                                                'DW$ = 4PO%
 PRINT "Spear               3 power      $ 2.00"
                                                 SPW$ = "spear"
                                                 'SPW$=3PO%
 PRINT "BOWS "
 PRINT "   Short           +3 * power    $45.00"
                                                 SBW$ = "short bow"
          'BXW$ = 10PO%
 PRINT "Dagger              4  power     $ 5.00"
                                                 DW$ = "dagger"
                                                'DW$ = 4PO%
 PRINT "Spear               3 power      $ 2.00"
                                                 SPW$ = "spear"
                                                 'SPW$=3PO%
 PRINT "BOWS "
 PRINT "   Short           +3 * power    $45.00"
                                                 SBW$ = "short bow"
     RND * 7)
DIM SHARED GlA%
 GlA% = INT(RND * 15)
DIM SHARED HA%
 HA% = INT(RND * 30)
DIM SHARED GHA%
 GHA% = INT(RND * 8)
DIM SHARED GWA%
 GWA% = INT(RND * 8)
DIM SHARED FLA%
 FLA% = INT(RND * 15)
DIM SHARED WEA%
 WEA% = INT(RND * 29)
DIM SHARED KWA%
 KWA% = INT(RND * 50)


DIM SHARED RW$
 RW$ = "rapier sword"
DIM SHARED TKW$
 TKW$ = "throwing knife"
DIM SHARED SW$
 SW$ = "spear"
DIM SHARED BDW$
 BDW$ = "bone dagger"
DIM SHARED PDW$
 PDW$ = "pision dart"
DIM SHARED THAW$
 THAW$ = "two-handed axe"

DIM SHARED RW%
 RW% = 0
DIM SHARED TKW%
 TKW% = 0
DIM SHARED SW%
 SW% = 0
DIM SHARED BDW%
 BDW% = 0
DIM SHARED PDW%
 PDW% = 0
DIM SHARED THAW%
 THAW% = 0

SUB intro2
DEFINT A-Z
'  Creates flashing border for intro screen

   LOCATE , , 0
  a$ = "ß    ßß    ßß    ßß    ßß    ßß    ßß    ßß    ßß    ßß    ßß    ßß    ßß    ßß    ßß    ßß    ßß    ßß"
  WHILE INKEY$ <> "": WEND

  WHILE INKEY$ = ""
    FOR a = 1 TO 6
      WAIT &H3DA, 8: WAIT &H3DA, 8, 8
      LOCATE 1, 2: PRINT MID$(a$, a, 79);
      LOCATE 22, 1: PRINT MID$(a$, 8 - a, 80);
    
      IF a AND 1 THEN
       FOR b = 1 TO 21
        c = ((a \ 2) + b) MOD 3
        IF c = 0 THEN
         LOCATE b, 80: PRINT "Ü";
         LOCATE 22 - b, 1: PRINT "ß";
        ELSEIF c = 1 THEN
         LOCATE b, 80: PRINT "ß";
         LOCATE 22 - b, 1: PRINT "Ü";
        ELSE
         LOCATE b, 80: PRINT " ";
         LOCATE 22 - b, 1: PRINT " ";
        END IF
       NEXT b
      ELSE
       FOR b = 1 TO 21
        c = ((a \ 2) + b) MOD 3
        IF c = 1 THEN
         LOCATE b, 80: PRINT "Û";
         LOCATE 22 - b, 1: PRINT "Û";
        ELSE
         LOCATE b, 80: PRINT " ";
         LOCATE 22 - b, 1: PRINT " ";
        END IF
       NEXT b
      END IF
    NEXT a
  WEND

END SUB

