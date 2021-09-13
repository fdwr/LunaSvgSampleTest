'Font Editor
'-----------
'Primer edition, by Bobby K (Insanity Dreams/Digiwerx)
'
'Remeber: If you use a .QBF file with a program you write,
'please give credit where due.  Thanx :)
'
'Should also come with FONTLOAD.BAS, and various .QBF files
'This program modifys your original .QBF files, so that
'you can get different sizes, italics, bold, etc...
'It is recomended that you keep the originals, as modifing and
'remodifing the fonts will lead to decreased resolution.
'***   NB:  CHANGING THE SIZE OF THE FONT MAY TAKE A WHILE, BUT
'YOUR COMPUTER HAS NOT CRASHED, IT IS JUST WORKING ON THE PROBLEM...***
'Hope you enjoy.
'
'*** FURTHER VRSIONS ARE PLANNED, BUT WILL NOT GO AHEAD, UNLESS I GET
'E-MAIL SAYING THAT YOU WANT ME TO (i gotta prioratise here man:) ***
'I am Bobby K, christie@intonet.co.uk
'Send me some mail is you liked this program, or wanna know:
'i) How i created the .QBF files
'ii) How you can access and muck around with them....

DEFINT A-Z
DECLARE SUB do.hbold ()
DECLARE SUB do.vbold ()
DECLARE SUB do.italic ()
DECLARE SUB do.size ()
DECLARE SUB do.smooth ()
DECLARE SUB horizontal ()
DECLARE SUB vertical ()
DECLARE SUB italic ()
DECLARE SUB size ()
DECLARE SUB save ()
DECLARE SUB new ()
DECLARE SUB resett ()
DECLARE SUB xit ()
DECLARE SUB initial ()
DECLARE SUB drawbase ()
DECLARE SUB drawedit ()
DECLARE SUB word ()
DECLARE SUB letter ()
DECLARE SUB do.saveletter ()
DECLARE SUB createline ()
DIM SHARED a$
DIM SHARED fh, fv, fi, fs, fls, fws
DIM SHARED ipl, pointer, pointer2
DIM SHARED linee(2), bit(2, 15)
DIM SHARED image(30000)

SCREEN 12
COLOR 7
new
initial
drawbase
drawedit

DO
  z$ = INKEY$
  SELECT CASE LCASE$(z$)
    CASE "w": word: drawedit
    CASE "l": letter: drawedit
    CASE "h": horizontal: drawedit
    CASE "v": vertical: drawedit
    CASE "i": italic: drawedit
    CASE "s": size: drawedit
    CASE "a": save: initial: drawbase: drawedit
    CASE "n": new: initial: drawbase: drawedit
    CASE "r": resett: drawedit
    CASE "x": xit
  END SELECT
LOOP

SUB createline
  FOR m = 1 TO ipl
    linee(m - 1) = 0
    IF bit(m - 1, 15) THEN linee(m - 1) = linee(m - 1) + 1
    IF bit(m - 1, 14) THEN linee(m - 1) = linee(m - 1) + 2
    IF bit(m - 1, 13) THEN linee(m - 1) = linee(m - 1) + 4
    IF bit(m - 1, 12) THEN linee(m - 1) = linee(m - 1) + 8
    IF bit(m - 1, 11) THEN linee(m - 1) = linee(m - 1) + 16
    IF bit(m - 1, 10) THEN linee(m - 1) = linee(m - 1) + 32
    IF bit(m - 1, 9) THEN linee(m - 1) = linee(m - 1) + 64
    IF bit(m - 1, 8) THEN linee(m - 1) = linee(m - 1) + 128
    IF bit(m - 1, 7) THEN linee(m - 1) = linee(m - 1) + 256
    IF bit(m - 1, 6) THEN linee(m - 1) = linee(m - 1) + 512
    IF bit(m - 1, 5) THEN linee(m - 1) = linee(m - 1) + 1024
    IF bit(m - 1, 4) THEN linee(m - 1) = linee(m - 1) + 2048
    IF bit(m - 1, 3) THEN linee(m - 1) = linee(m - 1) + 4096
    IF bit(m - 1, 2) THEN linee(m - 1) = linee(m - 1) + 8192
    IF bit(m - 1, 1) THEN linee(m - 1) = linee(m - 1) + 16384
    IF bit(m - 1, 0) THEN linee(m - 1) = linee(m - 1) - 32768
  NEXT m
END SUB

SUB do.hbold
  IF fh = 0 THEN EXIT SUB
  IF fh > 0 THEN
    GET (0, 300)-(639 - fh, 400), image
    FOR m = 1 TO fh
      PUT (m, 300), image, OR
    NEXT m
  ELSE
    GET (0 - fh, 300)-(639, 400), image
    FOR m = 1 TO -fh
      PUT (m, 300), image, AND
    NEXT m
  END IF
END SUB

SUB do.italic
  IF fi = 0 THEN EXIT SUB
  OPEN a$ FOR RANDOM AS #1 LEN = 2
  GET #1, 1, a
  a = a * 16
  CLOSE
  IF fi < 0 THEN
    inc! = -fi / a
    a! = 0
    FOR m = 0 TO 100
      GET (0, 300 + m)-(638 - a!, 300 + m), image
      LINE (0, 300 + m)-(639, 300 + m), 0
      PUT (a!, 300 + m), image, PSET
      a! = a! + inc!
    NEXT m
  ELSE
    inc! = -fi / a
    a! = 0
    FOR m = 0 TO 100
      GET (-a!, 300 + m)-(639, 300 + m), image
      LINE (0, 300 + m)-(639, 300 + m), 0
      PUT (0, 300 + m), image, PSET
      a! = a! + inc!
    NEXT m
  END IF
END SUB

SUB do.saveletter
  startpoint = pointer
  start = -1
  endd = -1
 
  FOR m = 0 TO 100
    empty = -1
    FOR thing = 0 TO ipl - 1
    FOR n = 0 TO 15
      apoint = POINT(m, n + 300 + (thing * 16))
      IF apoint = 15 THEN
        bit(thing, n) = -1
        empty = 0
      ELSE
        bit(thing, n) = 0
      END IF
    NEXT n
    NEXT thing
    IF NOT empty AND start = -1 THEN
        start = m
        endd = m
        createline
        FOR mmm = 1 TO ipl
            PUT #2, pointer + mmm - 1, linee(mmm - 1)
        NEXT mmm
        pointer = pointer + ipl
    ELSEIF empty AND start = -1 THEN
    ELSEIF NOT empty THEN
      createline
      FOR mmm = 1 TO ipl
        PUT #2, pointer + mmm - 1, linee(mmm - 1)
      NEXT mmm
      pointer = pointer + ipl
      endd = m
    ELSE
      linee(0) = 0
      linee(1) = 0
      linee(2) = 0
      FOR mmm = 1 TO ipl
        PUT #2, pointer + mmm - 1, linee(mmm - 1)
      NEXT mmm
      pointer = pointer + ipl
    END IF
  NEXT m
  aaa = startpoint + ipl * (endd - start + 1)
  pointer2 = pointer2 + 1
  pointer = aaa
  PUT #2, pointer2, aaa
END SUB

SUB do.size
  CLOSE
  OPEN a$ FOR RANDOM AS #1 LEN = 2
  GET #1, 1, origsize
  CLOSE
  origsize = origsize * 16
  IF fs = origsize THEN EXIT SUB
  stepp! = origsize / fs
  FOR m! = 0 TO 299 STEP stepp!
    FOR n! = 300 TO 300 + origsize STEP stepp!
      image((INT(n!) - 300) + (INT(m!) * 100)) = POINT(m!, n!)
    NEXT n!
  NEXT m!
  LINE (0, 300)-(639, 479), 0, BF
  m = 0
  FOR m! = 0 TO 299 STEP stepp!
    m = m + 1
    n = 300
    FOR n! = 300 TO 300 + origsize STEP stepp!
      n = n + 1
      PSET (m, n), image((INT(n!) - 300) + (INT(m!) * 100))
    NEXT n!
  NEXT m!
END SUB

SUB do.smooth
'DOH!
'Some other day perhaps
'  FOR m = 0 TO 100
'    FOR n = 300 TO 450
'        a1 = POINT(m - 1, n): IF a1 <> 15 THEN a1 = 0
'        a2 = POINT(m, n - 1): IF a2 <> 15 THEN a2 = 0
'        a3 = POINT(m + 1, n): IF a3 <> 15 THEN a3 = 0
'        a4 = POINT(m, n + 1): IF a4 <> 15 THEN a4 = 0
'        IF (a1 AND a2 AND NOT a3 AND NOT a4) OR (a2 AND a3 AND NOT a1 AND NOT a4) OR (a3 AND a4 AND NOT a1 AND NOT a2) OR (a4 AND a1 AND NOT a3 AND NOT a2) THEN
'            PSET (m, n), 0
'        END IF
'    NEXT n
'  NEXT m
END SUB

SUB do.vbold
  IF fv = 0 THEN EXIT SUB
  IF fv > 0 THEN
    GET (0, 300)-(639, 400), image
    FOR m = 1 TO fv
      PUT (0, 300 + m), image, OR
    NEXT m
  ELSE
    GET (0, 300)-(639, 400), image
    FOR m = 1 TO -fv
      PUT (0, 300 + m), image, AND
    NEXT m
  END IF
END SUB

SUB drawbase
  OPEN a$ FOR RANDOM AS #1 LEN = 2
  a = 0
  GET #1, 1, a
  GET #1, 2, fws
  GET #1, 3, fls
  wor$ = "Base-Font Sample.  123ABCabc"
  FOR count = 1 TO LEN(wor$)
    text$ = MID$(wor$, count, 1)
    m = ASC(text$) - 29
    IF m > 3 THEN
      GET #1, m, a1
      GET #1, m + 1, a2
      FOR n = a1 TO a2 - 1 STEP a
        FOR z = 0 TO a - 1
          GET #1, n + z, l
          LINE (p, 16 * z + 200)-(p, 15 + 16 * z + 200), 15, , l
        NEXT z
        p = p + 1
      NEXT n
      p = p + fls
    ELSE
      p = p + fws
    END IF
  NEXT count
  CLOSE
END SUB

SUB drawedit
  COLOR 15
  LOCATE 1, 1
  PRINT "Drawing...                      "
  LINE (0, 300)-(639, 479), 0, BF
  OPEN a$ FOR RANDOM AS #1 LEN = 2
  a = 0
  GET #1, 1, a
  wor$ = "Edited-Font Sample.  123ABCabc"
  FOR count = 1 TO LEN(wor$)
    text$ = MID$(wor$, count, 1)
    m = ASC(text$) - 29
    IF m > 3 THEN
      GET #1, m, a1
      GET #1, m + 1, a2
      FOR n = a1 TO a2 - 1 STEP a
        FOR z = 0 TO a - 1
          GET #1, n + z, l
          LINE (p, 16 * z + 300)-(p, 15 + 16 * z + 300), 15, , l
        NEXT z
        p = p + 1
      NEXT n
      p = p + fls
      p = p + (SGN(fi) * fi)
      IF fh > 0 THEN p = p + fh
    ELSE
      p = p + fws
    END IF
  NEXT count
  CLOSE

  do.hbold
  do.vbold
  do.italic
  do.size
  COLOR 15
  LOCATE 1, 1
  PRINT "Press a letter..."

END SUB

SUB horizontal
  LOCATE 1, 1
  COLOR 15
  PRINT "Use + and - keys, space to exit"
  PRINT
  DO
    z$ = INKEY$
    IF z$ = "=" OR z$ = "+" THEN fh = fh + 1
    IF z$ = "-" OR z$ = "_" THEN fh = fh - 1
    LOCATE 3, 20
    PRINT fh; "   "
  LOOP UNTIL z$ = " "
  LOCATE 1, 1
  PRINT "Press a letter...              "
  COLOR 7
  LOCATE 3, 20
  PRINT fh; "   "
END SUB

SUB initial
  CLS
  COLOR 15
  PRINT "Press a letter..."
  PRINT
  COLOR 15
  PRINT "H";
  COLOR 7
  PRINT "orizontal Bold +-"
  COLOR 15
  PRINT "V";
  COLOR 7
  PRINT "ertical Bold +-"
  COLOR 15
  PRINT "I";
  COLOR 7
  PRINT "talic +-"
  COLOR 15
  PRINT "S";
  COLOR 7
  PRINT "ize +-"
  COLOR 15
  PRINT "L";
  COLOR 7
  PRINT "etter spacing +-"
  COLOR 15
  PRINT "W";
  COLOR 7
  PRINT "ord spacing +-"
  PRINT "S";
  COLOR 15
  PRINT "a";
  COLOR 7
  PRINT "ve"
  COLOR 15
  PRINT "N";
  COLOR 7
  PRINT "ew base-font"
  COLOR 15
  PRINT "R";
  COLOR 7
  PRINT "eset Values"
  PRINT "E";
  COLOR 15
  PRINT "x";
  COLOR 7
  PRINT "it"
  LOCATE 3, 20
  PRINT fh; "   "
  LOCATE 4, 20
  PRINT fv; "   "
  LOCATE 5, 20
  PRINT fi; "   "
  LOCATE 6, 20
  PRINT fs; "   "
  LOCATE 7, 20
  PRINT fls; "   "
  LOCATE 8, 20
  PRINT fws; "   "
END SUB

SUB italic
  LOCATE 1, 1
  COLOR 15
  PRINT "Use + and - keys, space to exit"
  PRINT
  bbb = fi
  aaa = fls
  DO
    z$ = INKEY$
    IF z$ = "=" OR z$ = "+" THEN fi = fi + 1
    IF z$ = "-" OR z$ = "_" THEN fi = fi - 1
    fls = aaa + (SGN(bbb) * bbb) - (SGN(fi) * fi)
    COLOR 15
    LOCATE 5, 20
    PRINT fi; "   "
    COLOR 7
    LOCATE 7, 20
    PRINT fls; "   "
  LOOP UNTIL z$ = " "
  LOCATE 1, 1
  PRINT "Press a letter...              "
  COLOR 7
  LOCATE 5, 20
  PRINT fi; "   "
  LOCATE 7, 20
  PRINT fls; "   "
END SUB

SUB letter
  LOCATE 1, 1
  COLOR 15
  PRINT "Use + and - keys, space to exit"
  PRINT
  DO
    z$ = INKEY$
    IF z$ = "=" OR z$ = "+" THEN fls = fls + 1
    IF z$ = "-" OR z$ = "_" THEN fls = fls - 1
    LOCATE 7, 20
    PRINT fls; "   "
  LOOP UNTIL z$ = " "
  LOCATE 1, 1
  PRINT "Press a letter...              "
  COLOR 7
  LOCATE 7, 20
  PRINT fls; "   "
END SUB

SUB new
  DO
    CLS
    PRINT "Base-Font's directory, path and filename?"
    PRINT "EG d:\krusty\fonts\arial.qbf"
    LINE INPUT a$
    OPEN a$ FOR BINARY AS #1
    ok = -1
    IF LOF(1) = 0 THEN
      ok = 0
      CLOSE
      KILL a$
      PRINT "File not found!"
      PRINT "Press any key"
      DO: LOOP UNTIL INKEY$ <> ""
    END IF
  LOOP UNTIL ok
  CLOSE
  OPEN a$ FOR RANDOM AS #1 LEN = 2
  GET #1, 1, fs
  fs = fs * 16
  GET #1, 2, fws
  GET #1, 3, fls
  CLOSE
END SUB

SUB resett
  fh = 0
  fv = 0
  fi = 0
  OPEN a$ FOR RANDOM AS #1 LEN = 2
  GET #1, 1, fs
  GET #1, 2, fws
  GET #1, 3, fls
  fs = fs * 16
  CLOSE
  COLOR 7
  LOCATE 3, 20
  PRINT fh; "   "
  LOCATE 4, 20
  PRINT fv; "   "
  LOCATE 5, 20
  PRINT fi; "   "
  LOCATE 6, 20
  PRINT fs; "   "
  LOCATE 7, 20
  PRINT fls; "   "
  LOCATE 8, 20
  PRINT fws; "   "
END SUB

SUB save
  CLS
  COLOR 15
  PRINT "File Name?"
  INPUT b$
  OPEN b$ FOR RANDOM AS #2 LEN = 2
  ipl = fs / 16
  IF ipl <> INT(ipl) THEN ipl = INT(ipl) + 1
  PUT #2, 1, ipl
  PUT #2, 2, fws
  PUT #2, 3, fls
  pointer = 99
  PUT #2, 4, pointer
  pointer2 = 4
 
  OPEN a$ FOR RANDOM AS #1 LEN = 2
  GET #1, 1, orig
  orig = orig * 16
  CLOSE

  FOR m = 33 - 29 TO 126 - 29
    OPEN a$ FOR RANDOM AS #1 LEN = 2
    
    p = 0
    IF fi > 0 THEN p = p + fi
    GET #1, m, a1
    GET #1, m + 1, a2
    FOR n = a1 TO a2 - 1 STEP orig / 16
      FOR z = 0 TO (orig / 16) - 1
        GET #1, n + z, l
        LINE (p, 16 * z + 300)-(p, 15 + 16 * z + 300), 15, , l
      NEXT z
      p = p + 1
    NEXT n
    CLOSE
    do.hbold
    do.vbold
    do.italic
    do.size
    '''IF fs > orig THEN do.smooth
    OPEN b$ FOR RANDOM AS #2 LEN = 2
    do.saveletter
    CLS
  NEXT m
  CLOSE

END SUB

SUB size
  LOCATE 1, 1
  COLOR 15
  PRINT "Use + and - keys, space to exit"
  PRINT
  DO
    z$ = INKEY$
    IF z$ = "=" OR z$ = "+" THEN fs = fs + 1
    IF z$ = "-" OR z$ = "_" THEN fs = fs - 1
    IF fs > 48 THEN fs = 48
    IF fs < 1 THEN fs = 1
    LOCATE 6, 20
    PRINT fs; "   "
  LOOP UNTIL z$ = " "
  LOCATE 1, 1
  PRINT "Press a letter...              "
  COLOR 7
  LOCATE 6, 20
  PRINT fs; "   "
END SUB

SUB vertical
  LOCATE 1, 1
  COLOR 15
  PRINT "Use + and - keys, space to exit"
  PRINT
  DO
    z$ = INKEY$
    IF z$ = "=" OR z$ = "+" THEN fv = fv + 1
    IF z$ = "-" OR z$ = "_" THEN fv = fv - 1
    LOCATE 4, 20
    PRINT fv; "   "
  LOOP UNTIL z$ = " "
  LOCATE 1, 1
  PRINT "Press a letter...              "
  COLOR 7
  LOCATE 4, 20
  PRINT fv; "   "
END SUB

SUB word
  LOCATE 1, 1
  COLOR 15
  PRINT "Use + and - keys, space to exit"
  PRINT
  DO
    z$ = INKEY$
    IF z$ = "=" OR z$ = "+" THEN fws = fws + 1
    IF z$ = "-" OR z$ = "_" THEN fws = fws - 1
    LOCATE 8, 20
    PRINT fws; "   "
  LOOP UNTIL z$ = " "
  LOCATE 1, 1
  PRINT "Press a letter...              "
  COLOR 7
  LOCATE 8, 20
  PRINT fws; "   "
END SUB

SUB xit
  SYSTEM
END SUB

