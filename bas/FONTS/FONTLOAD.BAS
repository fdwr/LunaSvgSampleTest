'After much blood and sweat, toil and trouble, an 2 uncompiled VB primer
'programs that !two hours! to run !each!,  many hours of debugging
'and much tossing and turing during sleepless nights.
'Bobby K VERY proudly presents:
'
'                  !!!WINDOWS FONTS FOR QBASIC!!!
'                  ------------------------------
'
'   Written by Bobby K (Krusty) of Insanity Dreams and Digiwerx
'
'Remeber: If you use a .QBF file with a program you write,
'please give credit where due.  Thanx :)
'
'   SEND ME MAIL (And that's an order) at christie@intonet.co.uk
'   Attached should be:
'     FONTMAKE.BAS
'     various .QBF files  (QuickBasicFont)
'  The program is fairly obvious, to get any windows fonts in one
'  of your programs:
'1)  Make sure you have the appropriate .QBF file, in the
'    correct directory or whatever.
'2)  If you want, modify the font with the fontmake.bas program
'    (eg ****TO MAKE THEM SMALLER!!!!! ******)
'3)  Add these two subroutines (fprint and fopen)
'4)  Open the file with the fopen command/sub
'5)  Print it with the fprint command/sub

DECLARE SUB fopen (file$, file%)
'file$:        The full pathname of the font (eg "d:\krusty\fonts\arial.qbf")
'file%:        The number of a free (unopened) file
'                (if you are not sure use file%=FREEFILE)
DECLARE SUB fprint (text$, textx%, texty%, colour%, file%)
'text$:        The text you want printed
'textx%,texty%:Where to place the font
'colour%:      Take a wild guess
'file%:        The number of the opened file
'                (if you are not sure use file%=FREEFILE)


SCREEN 12
INPUT "Where do your .QBF fonts reside (eg d:\krusty\fonts\)"; a$
IF LEFT$(a$, 1) <> "\" THEN a$ = a$ + "\"
CLS

fopen a$ + "arial.qbf", 1
fopen a$ + "lucidabl.qbf", 2
fopen a$ + "lucidaha.qbf", 3
fprint "Arial , YEY!", 0, 0, 1, 1
fprint "Lucida Blackletter RULES!", 100, 100, 8, 2
fprint "Hope u like :)", 50, 200, 7, 3
fprint "That's all folks", 0, 300, 15, 3
CLOSE
                                  

'                  !!!WINDOWS FONTS FOR QBASIC!!!
'                  ------------------------------
'   Written by Bobby K (Krusty) of Insanity Dreams and Digiwerx
'
'
'
SUB fopen (file$, file%)
  OPEN file$ FOR RANDOM AS file% LEN = 2
  'Just to make it easier for those of you who dont
  'understand the OPEN command yet! ;)
END SUB

'                  !!!WINDOWS FONTS FOR QBASIC!!!
'                  ------------------------------
'   Written by Bobby K (Krusty) of Insanity Dreams and Digiwerx
'
'
'
SUB fprint (text$, textx%, texty%, colour%, file%)
  'lpi: lines per integer
  'fws: font word spacing
  'fls: font letter spacing
  'p% : pointer
  GET file%, 1, lpi%
  GET file%, 2, fws%
  GET file%, 3, fls%
  FOR count% = 1 TO LEN(text$)
    m% = ASC(MID$(text$, count%, 1)) - 29
    IF m% > 3 THEN
      GET file%, m%, a1%
      GET file%, m% + 1, a2%
      FOR n% = a1% TO a2% - 1 STEP lpi%
        FOR z% = 0 TO lpi% - 1
          GET file%, n% + z%, l%
          LINE (p% + textx%, (16 * z%) + texty%)-(p% + textx%, (16 * z%) + 15 + texty%), colour%, , l%
        NEXT z%
        p% = p% + 1
      NEXT n%
      p% = p% + fls%
    ELSE
      p% = p% + fws%
    END IF
  NEXT count%
END SUB

