'Robert Anthony Moreno II
'Bob666@concentric.net
RANDOMIZE TIMER
DEFINT A-Z
DIM baddirection(10)
DIM badshoot(10)
DIM badshooting(10)
DIM badshotx(10)
DIM badshoty(10)
DIM badx(10)
DIM bady(10)
DIM dead(10)
DIM shooting(10)
DIM shotx(10)
DIM shoty(10)
DIM starc(100)
DIM stars(100)
DIM stari(100)
DIM starx(100)
DIM stary(100)
CLS
LOCATE 11, 26, 0
COLOR 11, 0
PRINT "Moreno Computer Development!"
LOCATE 13, 26, 0
COLOR 12, 0
PRINT "   P r e s e n t s . . .    "
SLEEP 3
start:
SCREEN 13
CLS
PALETTE 31, 0
PALETTE 32, 0
LOCATE 11, 12, 0
COLOR 31
PRINT "Super"
LOCATE 12, 15, 0
COLOR 32
PRINT "Galactic Wars"
FOR c = 0 TO 63
 PALETTE 32, c
NEXT c
FOR c = 0 TO 63
 PALETTE 31, c
NEXT c
PLAY "MBL25CDEFGAB"
SLEEP 1
PALETTE 1, (63 * 1) + (63 * 256) + (63 * 65536)
PALETTE 2, (55 * 1) + (55 * 256) + (55 * 65536)
PALETTE 3, (45 * 1) + (45 * 256) + (45 * 65536)
PALETTE 4, (40 * 1) + (40 * 256) + (40 * 65536)
PALETTE 8, (50 * 1) + (25 * 256) + (25 * 65536)
PALETTE 9, (25 * 1) + (25 * 256) + (25 * 65536)
PALETTE 10, (40 * 1) + (40 * 256) + (40 * 65536)
PALETTE 11, (20 * 1) + (20 * 256) + (63 * 65536)
PALETTE 12, (63 * 1) + (0 * 256) + (0 * 65536)
PALETTE 20, 0
PALETTE 21, 20
PALETTE 22, 30
PALETTE 23, 40
PALETTE 24, 50
PALETTE 25, 60
FOR i = 100 TO 110
 PALETTE i, 0
NEXT i
COLOR 11
DO
 IF t = 0 THEN
  d = 0
  c = 0
 END IF
 IF t = 100 THEN
  d = 1
  c = 11
 END IF
 IF d = 0 THEN t = t + 1
 IF d = 1 THEN t = t - 1
 COLOR c
 LOCATE 15, 10, 0
 PRINT "Press Enter To Start"
LOOP UNTIL INKEY$ = CHR$(13)
DO: LOOP UNTIL INKEY$ = ""
CLS
FOR i = 0 TO 100
 starx(i) = (RND * 320)
 stary(i) = (RND * 179) + 10
 stars(i) = (RND * 3) + 2
 starc(i) = (RND * 3) + 1
NEXT i
FOR i = 1 TO 10
 badx(i) = (RND * 195) + 100
 bady(i) = (RND * 150) + 25
 baddirection(i) = (RND * 3) + 1
NEXT i
COLOR 1
shield = 5
x = 40
y = 100
LINE (0, 9)-(320, 9), 1
LINE (0, 190)-(320, 190), 1
LOCATE 25, 1, 0
PRINT "<Esc> Exit : <P> Pause";
LOCATE 1, 1, 0
PRINT " Shields:"; shield; " Score:"; score
DO
 FOR i = 1 TO 100
  PSET (starx(i), stary(i)), 0
  stari(i) = stari(i) + 1
  IF stari(i) = stars(i) THEN
   starx(i) = starx(i) - 1
   stari(i) = 0
  END IF
  IF starx(i) < 0 THEN
   starx(i) = (RND * 50) + 320
   stary(i) = (RND * 179) + 10
   stars(i) = (RND * 3) + 2
   starc(i) = (RND * 3) + 1
  END IF
  PSET (starx(i), stary(i)), starc(i)
 NEXT i
 key$ = INKEY$
 SELECT CASE UCASE$(key$)
  CASE CHR$(27): GOTO quit
  CASE "P"
   LOCATE 25, 1, 0
   PRINT STRING$(40, CHR$(32));
   LOCATE 25, 1, 0
   PRINT "Game Paused... Press Enter";
   DO: LOOP UNTIL INKEY$ = CHR$(13)
   LOCATE 25, 1, 0
   PRINT STRING$(40, CHR$(32));
   LOCATE 25, 1, 0
   PRINT "<Esc> Exit : <P> Pause";
  CASE CHR$(13): IF shooting = 0 THEN shoot = 1
  CASE CHR$(0) + "H": direction = 1
  CASE CHR$(0) + "P": direction = 2
  CASE CHR$(0) + "K": direction = 3
  CASE CHR$(0) + "M": direction = 4
  CASE CHR$(32): direction = 0
 END SELECT
 LINE (x + 7, y - 4)-(x - 4, y - 4), 0
 LINE (x + 7, y + 4)-(x - 4, y + 4), 0
 LINE (x + 6, y - 3)-(x + 6, y + 3), 0
 LINE (x + 7, y - 3)-(x + 7, y + 3), 0
 LINE (x + 8, y - 3)-(x + 8, y + 3), 0
 LINE (x + 1, y)-(x - 2, y - 3), 0
 LINE (x + 1, y)-(x - 2, y + 3), 0
 LINE (x - 4, y - 3)-(x + 3, y - 3), 0
 LINE (x - 4, y + 3)-(x + 3, y + 3), 0
 LINE (x - 1, y)-(x + 5, y), 0
 CIRCLE (x, y), 10, 0, , , .6
 IF direction = 1 AND y > 25 THEN y = y - 1
 IF direction = 2 AND y < 174 THEN y = y + 1
 IF direction = 3 AND x > 25 THEN x = x - 1
 IF direction = 4 AND x < 295 THEN x = x + 1
 IF direction = 1 OR direction = 2 THEN
  IF y = 25 THEN direction = 0
  IF y = 174 THEN direction = 0
 END IF
 IF direction = 3 OR direction = 4 THEN
  IF x = 25 THEN direction = 0
  IF x = 295 THEN direction = 0
 END IF
 LINE (x + 7, y - 4)-(x - 4, y - 4), 100
 LINE (x + 7, y + 4)-(x - 4, y + 4), 100
 LINE (x + 6, y - 3)-(x + 6, y + 3), 100
 LINE (x + 7, y - 3)-(x + 7, y + 3), 100
 LINE (x + 8, y - 3)-(x + 8, y + 3), 100
 LINE (x + 1, y)-(x - 2, y - 3), 9
 LINE (x + 1, y)-(x - 2, y + 3), 9
 LINE (x - 4, y - 3)-(x + 3, y - 3), 11
 LINE (x - 4, y + 3)-(x + 3, y + 3), 11
 LINE (x - 1, y)-(x + 5, y), 10
 CIRCLE (x, y), 10, (shield + 20), , , .6
 IF shoot = 1 THEN
  FOR i = 1 TO 10
   IF shooting(i) = 0 THEN
    shooting(i) = 1
    shotx(i) = x + 8
    shoty(i) = y
    SOUND 100, .05
    EXIT FOR
   END IF
  NEXT i
  shoot = 0
 END IF
 FOR ii = 1 TO 10
  IF shooting(ii) = 1 THEN
   PSET (shotx(ii), shoty(ii)), 0
   shotx(ii) = shotx(ii) + 2
   IF shotx(ii) > 320 THEN shooting(ii) = 0
   pixel = POINT(shotx(ii), shoty(ii))
   IF pixel > 100 THEN
    die = pixel - 100
    FOR i = 1 TO 10
     CIRCLE (badx(die), bady(die)), i, 12
    NEXT i
    PLAY "MFL50DC"
    FOR i = 1 TO 10
     CIRCLE (badx(die), bady(die)), i, 0
     SOUND 100, .05
    NEXT i
    score = score + (badx(die) - x)
    LOCATE 1, 1, 0
    PRINT " Shields:"; shield; " Score:"; score
    i = die
    PSET (shotx(ii), shoty(ii)), 0
    LINE (badx(i) - 7, bady(i) + 4)-(badx(i) + 4, bady(i) + 4), 0
    LINE (badx(i) - 7, bady(i) - 4)-(badx(i) + 4, bady(i) - 4), 0
    LINE (badx(i) - 6, bady(i) + 3)-(badx(i) - 6, bady(i) - 3), 0
    LINE (badx(i) - 7, bady(i) + 3)-(badx(i) - 7, bady(i) - 3), 0
    LINE (badx(i) - 8, bady(i) + 3)-(badx(i) - 8, bady(i) - 3), 0
    LINE (badx(i) + 3, bady(i) + 3)-(badx(i) - 3, bady(i) - 3), 0
    LINE (badx(i) + 3, bady(i) - 3)-(badx(i) - 3, bady(i) + 3), 0
    LINE (badx(i) - 5, bady(i))-(badx(i) + 2, bady(i)), 0
    dead(i) = 1
    shotx(ii) = 325
   END IF
   PSET (shotx(ii), shoty(ii)), 12
  END IF
 NEXT ii
 FOR i = 1 TO 10
  IF dead(i) = 0 THEN
   IF badshooting(i) = 0 AND x < badx(i) THEN
    IF y > bady(i) AND direction = 1 THEN
     IF (y - bady(i)) * 2 <= (badx(i) - x) THEN badshoot(i) = 1
    END IF
    IF y < bady(i) AND direction = 2 THEN
     IF (bady(i) - y) * 2 <= (badx(i) - x) THEN badshoot(i) = 1
    END IF
    IF y = bady(i) AND direction = 0 THEN badshoot(i) = 1
   END IF
   IF badshoot(i) = 1 THEN
    badshooting(i) = 1
    badshotx(i) = badx(i) - 8
    badshoty(i) = bady(i)
    badshoot(i) = 0
    SOUND 100, .05
   END IF
   LINE (badx(i) - 7, bady(i) + 4)-(badx(i) + 4, bady(i) + 4), 0
   LINE (badx(i) - 7, bady(i) - 4)-(badx(i) + 4, bady(i) - 4), 0
   LINE (badx(i) - 6, bady(i) + 3)-(badx(i) - 6, bady(i) - 3), 0
   LINE (badx(i) - 7, bady(i) + 3)-(badx(i) - 7, bady(i) - 3), 0
   LINE (badx(i) - 8, bady(i) + 3)-(badx(i) - 8, bady(i) - 3), 0
   LINE (badx(i) + 3, bady(i) + 3)-(badx(i) - 3, bady(i) - 3), 0
   LINE (badx(i) + 3, bady(i) - 3)-(badx(i) - 3, bady(i) + 3), 0
   LINE (badx(i) - 5, bady(i))-(badx(i) + 2, bady(i)), 0
   IF baddirection(i) = 1 AND bady(i) > 25 THEN bady(i) = bady(i) - 1
   IF baddirection(i) = 2 AND bady(i) < 174 THEN bady(i) = bady(i) + 1
   IF baddirection(i) = 3 AND badx(i) > 100 THEN badx(i) = badx(i) - 1
   IF baddirection(i) = 4 AND badx(i) < 295 THEN badx(i) = badx(i) + 1
   r = (RND * 4)
   IF baddirection(i) = r THEN baddirection(i) = (RND * 4)
   IF i <= 5 THEN
    IF direction = 0 AND x < badx(i) THEN
     IF y < bady(i) THEN baddirection(i) = 1
     IF y > bady(i) THEN baddirection(i) = 2
     IF y = bady(i) THEN baddirection(i) = 0
    END IF
    FOR ii = 1 TO 10
     IF shotx(ii) > badx(i) - 25 AND shotx(ii) < badx(i) + 10 THEN
      IF shoty(ii) > bady(i) AND shoty(ii) < bady(i) + 25 THEN baddirection(i) = 1
      IF shoty(ii) < bady(i) AND shoty(ii) > bady(i) - 25 THEN baddirection(i) = 2
      IF shoty(ii) = bady(i) THEN baddirection(i) = ((RND * 1) + 1)
     END IF
    NEXT ii
   END IF
   LINE (badx(i) - 7, bady(i) + 4)-(badx(i) + 4, bady(i) + 4), (100 + i)
   LINE (badx(i) - 7, bady(i) - 4)-(badx(i) + 4, bady(i) - 4), (100 + i)
   LINE (badx(i) - 6, bady(i) + 3)-(badx(i) - 6, bady(i) - 3), (100 + i)
   LINE (badx(i) - 7, bady(i) + 3)-(badx(i) - 7, bady(i) - 3), (100 + i)
   LINE (badx(i) - 8, bady(i) + 3)-(badx(i) - 8, bady(i) - 3), (100 + i)
   LINE (badx(i) + 3, bady(i) + 3)-(badx(i) - 3, bady(i) - 3), 11
   LINE (badx(i) + 3, bady(i) - 3)-(badx(i) - 3, bady(i) + 3), 11
   LINE (badx(i) - 5, bady(i))-(badx(i) + 2, bady(i)), 8
   IF POINT(x + 8, y - 4) = (100 + i) THEN
    FOR ii = 1 TO 10
     CIRCLE (x, y), ii, 12
    NEXT ii
    PLAY "MFL50C"
    FOR ii = 1 TO 10
     CIRCLE (x, y), ii, 0
     SOUND 100, .5
    NEXT ii
    GOTO lose
   END IF
   IF POINT(x + 8, y + 4) = (100 + i) THEN
    FOR ii = 1 TO 10
     CIRCLE (x, y), ii, 12
    NEXT ii
    PLAY "MFL50C"
    FOR ii = 1 TO 10
     CIRCLE (x, y), ii, 0
     SOUND 100, .5
    NEXT ii
    GOTO lose
   END IF
   IF POINT(x - 4, y - 4) = (100 + i) THEN
    FOR ii = 1 TO 10
     CIRCLE (x, y), ii, 12
    NEXT ii
    PLAY "MFL50C"
    FOR ii = 1 TO 10
     CIRCLE (x, y), ii, 0
     SOUND 100, .5
    NEXT ii
    GOTO lose
   END IF
   IF POINT(x - 4, y + 4) = (100 + i) THEN
    FOR ii = 1 TO 10
     CIRCLE (x, y), ii, 12
    NEXT ii
    PLAY "MFL50C"
    FOR ii = 1 TO 10
     CIRCLE (x, y), ii, 0
     SOUND 100, .5
    NEXT ii
    GOTO lose
   END IF
  END IF
  IF badshooting(i) = 1 THEN
   PSET (badshotx(i), badshoty(i)), 0
   badshotx(i) = badshotx(i) - 2
   IF badshotx(i) < 0 THEN badshooting(i) = 0
   pixel = POINT(badshotx(i), badshoty(i))
   IF pixel = 100 THEN
    PSET (badshotx(i), badshoty(i)), 0
    shield = shield - 1
    badshotx(i) = -5
    IF shield = -1 THEN
     FOR ii = 1 TO 10
      CIRCLE (x, y), ii, 12
     NEXT ii
     PLAY "MFL50C"
     FOR ii = 1 TO 15
      CIRCLE (x, y), ii, 0
      SOUND 100, .5
     NEXT ii
    END IF
    IF shield = 0 THEN PLAY "MBL25DCDCDC" ELSE PLAY "MBL25C"
    LOCATE 1, 1, 0
    PRINT " Shields:"; shield; " Score:"; score
   END IF
   PSET (badshotx(i), badshoty(i)), 12
  END IF
  done = done + dead(i)
 NEXT i
 IF done = 10 THEN GOTO win ELSE done = 0
 IF shield = -1 THEN GOTO lose
 FOR i = 0 TO 50
  FOR ii = 0 TO delay: NEXT ii
 NEXT i
LOOP
win:
PLAY "MBL25CDEFGAB"
CLS
LOCATE 11, 18, 0
PRINT "Wow!"
LOCATE 12, 16, 0
PRINT "You Won!"
LOCATE 14, 15, 0
PRINT "Press  Esc"
DO: LOOP UNTIL INKEY$ = CHR$(27)
CLS
LOCATE 11, 11
PRINT "Play Again? (Y,N):"
pa$ = INPUT$(1)
IF UCASE$(pa$) = "Y" THEN
 CLEAR
 GOTO start
END IF
END
lose:
PLAY "MBL25BAGFEDC"
CLS
LOCATE 11, 16, 0
PRINT "Ha Ha Ha"
LOCATE 12, 16, 0
PRINT "You Died"
LOCATE 14, 15, 0
PRINT "Press  Esc"
DO: LOOP UNTIL INKEY$ = CHR$(27)
CLS
LOCATE 11, 11
PRINT "Play Again? (Y,N):"
pa$ = INPUT$(1)
IF UCASE$(pa$) = "Y" THEN
 CLEAR
 GOTO start
END IF
END
quit:
PLAY "MBL25BAGFEDC"
CLS
LOCATE 11, 4, 0
PRINT "Quiters Never Amount To Anything!"
LOCATE 13, 15, 0
PRINT "Press Enter"
DO: LOOP UNTIL INKEY$ = CHR$(13)
END

