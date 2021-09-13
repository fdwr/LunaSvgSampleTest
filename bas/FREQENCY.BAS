DEFINT A-Z
CONST tone! = .0594631, MaxLnote = 0, MaxHnote = 96

SCREEN 0: COLOR 15, 0: CLS : LOCATE , , 0
LOCATE 4, 7: PRINT "Use the arrow keys to change the note and hold Space Bar to play it"
PRINT "      Left and Right move one note while Up and Down move an entire octave"
PRINT "      You can also change the note and play the sound at the same time"

CurrNote = 0: Chng = 1
DO
 kbrd = INP(96)
 SELECT CASE INKEY$
 CASE CHR$(0) + "M": IF CurrNote < MaxHnote THEN CurrNote = CurrNote + 1: Chng = 1
 CASE CHR$(0) + "K": IF CurrNote > MaxLnote THEN CurrNote = CurrNote - 1: Chng = 1
 CASE CHR$(0) + "H": CurrNote = CurrNote + 12: Chng = 1: IF CurrNote > MaxHnote THEN CurrNote = MaxHnote
 CASE CHR$(0) + "P": CurrNote = CurrNote - 12: Chng = 1: IF CurrNote < MaxLnote THEN CurrNote = MaxLnote
 CASE CHR$(27): EXIT DO
 END SELECT
 IF kbrd = 57 THEN Snd = -1 ELSE IF kbrd = 185 THEN Snd = 0
 IF Chng THEN Note = CurrNote: GOSUB ShowHertz: Chng = 0
 IF Snd AND PLAY(0) = 0 THEN Note = CurrNote: GOSUB GetFreq: SOUND Freq, .5
LOOP
END

ShowHertz:
GOSUB GetFreq
Bar$ = STRING$(49, 32): IF Note AND 1 THEN Char$ = "Þ" ELSE Char$ = "Ý"
IF Note >= 0 AND Note + 1 <= LEN(Bar$) * 2 THEN MID$(Bar$, (Note \ 2) + 1, 1) = Char$

COLOR 15, 0: LOCATE 1, 16: PRINT "Note ="; LEFT$(STR$(Note) + "   ", 3);
LOCATE 1, 49: PRINT "Pitch ="; LEFT$(STR$(Freq!) + "          ", 10);
LOCATE 2, 16: COLOR 15, 1: PRINT Bar$;
RETURN

GetFreq:
Freq! = 64 * INT(2 ^ (Note \ 12))
FOR l = 1 TO Note MOD 12: Freq! = Freq! + (tone! * Freq!): NEXT l
Freq = INT(Freq!)
RETURN

COLOR 7, 0: LOCATE 6, 1
SYSTEM

