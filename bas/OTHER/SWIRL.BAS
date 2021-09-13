
' Somehow I found this program.  Unfortunately, after searching all the
' America Online QBasic graphics programs, I could not find the author.
' If you are the author, email me and I will give you proper credit. 
' http://members.aol.com/mkwebsite/index.html
' email: blood225@aol.com

DECLARE SUB MOUSEDRIVER (AX%, BX%, cx%, DX%)
DECLARE FUNCTION MOUSEINIT% ()
DECLARE SUB mouseshow ()
DECLARE SUB MOUSEHIDE ()
DECLARE SUB mousestats ()
DECLARE SUB mousesetpos (x%, y%)
DIM SHARED SH%, SV%, ST%, left%, Right%, mode%, b%, mx%, my%
DIM SHARED MOUSE$: MOUSE$ = SPACE$(57)


DEFINT A-Z
Right% = 2
left% = 1


FOR Ifg% = 1 TO 57
 READ a$
 h$ = CHR$(VAL("&H" + a$))
 MID$(MOUSE$, Ifg%, 1) = h$
NEXT Ifg%

DATA 55,89,E5,8B,5E,0C,8B,07,50,8B,5E,0A,8B,07,50,8B
DATA 5E,08,8B,0F,8B,5E,06,8B,17,5B,58,1E,07,CD,33,53
DATA 8B,5E,0C,89,07,58,8B,5E,0A,89,07,8B,5E,08,89,0F
DATA 8B,5E,06,89,17,5D,CA,08,00
DEFINT A-Z
allstars = 50
DIM x2(allstars), y2(allstars), angle(allstars), radius(allstars), size(allstars), c%(allstars), turnfast(allstars), g(allstars)

CLS
SCREEN 12
RANDOMIZE TIMER

pi# = 3.1415926#
x = 320
y = 200
mousesetpos x, y

 FOR i = 1 TO allstars
  c%(i) = INT(RND * 15) + 1
  radius(i) = INT(RND * 400) + 1
  angle(i) = INT(RND * 377) + 1
  turnfast(i) = (INT(RND * 3000) / 1000) + 1
 NEXT i

TopOfLoop:
  i = i + 1
  IF i > allstars THEN i = 1
  angle(i) = angle(i) - turnfast(i)
  radius(i) = radius(i) - (INT(RND * 1000) + 1) / 300
  IF angle(i) <= 0 THEN angle(i) = 359
  IF radius(i) <= 0 THEN turnfast(i) = (INT(RND * 3000) / 1000) + 1: radius(i) = 400
  a$ = INKEY$
  IF a$ = CHR$(27) THEN GOTO EndProg
  mousestats
  fg = fg + 1
  IF fg >= 100 THEN anglez = anglez + 1: fg = 0
  radiusz = 200
  IF anglez >= 3770 THEN anglez = 0
  x = mx%: y = my%
  LINE (x2(i) - size(i), y2(i) - size(i))-(x2(i) + size(i), y2(i) + size(i)), 0, BF
  x2(i) = x + COS(angle(i) * pi# / 180) * radius(i) / 1.5
  y2(i) = y - SIN(angle(i) * pi# / 180) * radius(i) / 1.5
  size(i) = radius(i) / 300
  IF x2(i) > 0 AND x2(i) < 639 AND y2(i) > 0 AND y2(i) < 479 THEN LINE (x2(i) - size(i), y2(i) - size(i))-(x2(i) + size(i), y2(i) + size(i)), c%(i), BF
 GOTO TopOfLoop


EndProg:
CLS
SCREEN 0
WIDTH 80
SYSTEM

SUB MOUSEDRIVER (AX%, BX%, cx%, DX%)
DEF SEG = VARSEG(MOUSE$)
MOUSE% = SADD(MOUSE$)
CALL ABSOLUTE(AX%, BX%, cx%, DX%, MOUSE%)
END SUB

SUB MOUSEHIDE
AX% = 2
MOUSEDRIVER AX%, 0, 0, 0
END SUB

FUNCTION MOUSEINIT%
AX% = 0
MOUSEDRIVER AX%, 0, 0, 0
MSI% = AX%
IF NOT MSI% THEN MOUSEINIT% = 0 ELSE MOUSEINIT% = 1
END FUNCTION

SUB mousesetpos (x%, y%)
AX% = 4
cx% = x%
DX% = y%
MOUSEDRIVER AX%, 0, cx%, DX%
END SUB

SUB mouseshow
AX% = 1
MOUSEDRIVER AX%, 0, 0, 0
END SUB

SUB mousestats
AX% = 3
MOUSEDRIVER AX%, BX%, cx%, DX%
b% = BX%
IF mode% = 13 THEN mx% = cx% / 2 ELSE mx% = cx%
my% = DX%
AX% = 27
BX% = 0
cx% = 0
DX% = 0
MOUSEDRIVER AX%, BX%, cx%, DX%
SH% = BX%
SV% = cx%
ST% = DX%
END SUB

