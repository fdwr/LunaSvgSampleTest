'FMHSC Player for QBasic/QuickBasic, 1994-1997 by Steve Bigras
'This is the 2nd version. A few options are implemented for the DFM
'file format compatibility.
'if option =>30h AND <=50h with a note, the instrument changes
'example ³C-4 32³ Play a C, octave 4 and change instrument 2 (ins minus 30h)
'since the DFM format uses only 32 instruments.
'This package uses HSC.LIB;HSC.QLB Library which contains the ACCURATE
'amount of microseconds waits of each data sent to the ADLIB PORT due to
'the OPL2 chip which requires much more breathing time than the OPL3.
'The OutPort SUB has been transfered to the library made in assembler.
'A lot of optimizations were added for faster processing.
'
' This code is optimized to merge in any QB program. You may use this
' code freely as long as you give me credit for it AND you MUST send me
' email for your comments and support at:  starkill@polyinter.com
' or as a last resort:  stbigras@hotmail.com
' Please read LISCENSE.TXT if you haven't yet.
'
'***NOTE*** you must load QB with the HSC.QLB, syntax:  QB.EXE /LHSC
DECLARE SUB LoadHSC (Filename$)
DECLARE SUB PlayTune ()
DECLARE SUB PlayNote (Chn%, Note%)
DECLARE SUB ResetFMChip (Bits%)
DECLARE SUB SetInst (Chn%, InstNum%)
DEFINT A-Z
'$INCLUDE: 'HSC.BI'

ResetFMChip 1 + 2 + 4
LoadHSC "NEOINTRO.HSC"

DO
A$ = INKEY$: IF A$ <> "" THEN EXIT DO
PlayTune
LOOP

ResetFMChip 2 + 4

SUB LoadHSC (Filename$)
REDIM PattTable(99)
OPEN Filename$ FOR BINARY AS 1
Tempo = 1
FOR T = 0 TO 127: GET #1, 1 + T * 12, Ins(T)
IF MID$(Ins(T), 12, 1) = CHR$(255) THEN MID$(Ins(T), 12, 1) = CHR$(0): Add = Add + 1
NEXT
FOR T = 0 TO 49: B$ = " ": GET #1, , B$: PattTable(T) = ASC(B$): NEXT: B$ = " ": GET #1, , B$
FOR P = 0 TO 49: GET #1, , Notes(P): NEXT: CLOSE 1
PlayPatt = PattTable(0)
Song$ = Ins(125) + Ins(126)
IF MID$(Ins(127), 1, 11) = STRING$(11, 255) THEN Tempo = ASC(MID$(Ins(127), 12, 1))

FOR Chn = 0 TO 8
 Pc = INT(Chn / 3)
 A = Chn - Pc * 3
 VoiceData(Chn * 11 + 2) = &H20 + Pc * 8 + A
 VoiceData(Chn * 11 + 1) = &H23 + Pc * 8 + A
 VoiceData(Chn * 11 + 4) = &H40 + Pc * 8 + A
 VoiceData(Chn * 11 + 3) = &H43 + Pc * 8 + A
 VoiceData(Chn * 11 + 6) = &H60 + Pc * 8 + A
 VoiceData(Chn * 11 + 5) = &H63 + Pc * 8 + A
 VoiceData(Chn * 11 + 8) = &H80 + Pc * 8 + A
 VoiceData(Chn * 11 + 7) = &H83 + Pc * 8 + A
 VoiceData(Chn * 11 + 11) = &HE0 + Pc * 8 + A
 VoiceData(Chn * 11 + 10) = &HE3 + Pc * 8 + A
 VoiceData(Chn * 11 + 9) = &HC0 + Pc * 3 + A
NEXT
FOR Chn = 0 TO 8
 SetInst Chn, Chn
 HscData(5, Chn) = Chn
NEXT
HscData(0, 1) = 363
HscData(0, 2) = 385
HscData(0, 3) = 408
HscData(0, 4) = 432
HscData(0, 5) = 458
HscData(0, 6) = 485
HscData(0, 7) = 514
HscData(0, 8) = 544
HscData(0, 9) = 577
HscData(0, 10) = 611
HscData(0, 11) = 647
HscData(0, 12) = 686
FOR G = 1 TO 6
HscData(1, G) = 1
HscData(1, G + 6) = 2
NEXT

G = -1
FOR G! = .03 TO .8 STEP .05
G = G + 1: Tempos!(G) = G!
NEXT
END SUB

SUB PlayNote (Chn, Note)
Oct = INT(Note / 12)
Note = (Note - 1) MOD 12 + 1
OutPort &HB0 + Chn, 0
OutPort &HA0 + Chn, HscData(0, Note)
OutPort &HB0 + Chn, 32 + Oct * 4 + HscData(1, Note)
END SUB

SUB PlayTune
IF TIMER > TM! THEN
   TM! = TIMER + Tempos!(Tempo)
   IF PlayRow > -1 THEN
      FOR Chn = 0 TO 8
      IF PattTable(PlayPatt) = 255 THEN PlayPatt = 0
      IF PlayRow > -1 THEN
	 B$ = MID$(Notes(PattTable(PlayPatt)), 1 + Chn * 2 + PlayRow * 18, 2)
	 HscData(3, Chn) = 0
	 Note = ASC(MID$(B$, 1, 1))
	 Opt = ASC(MID$(B$, 2, 1))
	 N = Note
	 IF Opt > 239 THEN
	    Tempo = Opt - 240
	    TM! = TIMER + Tempos!(Tempo)
	 END IF
	 IF Note < 97 AND Note > 0 AND Opt > 47 AND Opt < 81 AND HscData(5, Chn) <> Opt THEN
	    Opt = Opt - 48
	    FOR P = 1 TO 11
	     OutPort VoiceData(Chn * 11 + P), ASC(MID$(Ins(Opt), P, 1))
	    NEXT
	    HscData(5, Chn) = Opt
	 END IF
	 IF Note = 128 THEN
	    FOR P = 1 TO 11
	     OutPort VoiceData(Chn * 11 + P), ASC(MID$(Ins(Opt), P, 1))
	    NEXT
	    HscData(5, Chn) = Opt
	    GOTO SkipRow
	  ELSE
	    IF Note = 0 AND Opt = 1 THEN PlayPatt = PlayPatt + 1: PlayRow = -1: GOTO SkipRow
	 END IF

	 IF Opt > 159 AND Opt < 176 THEN Value = Opt - 161: OutPort VoiceData(Chn * 11 + 3), Value * 4
	 IF Opt > 175 AND Opt < 190 THEN Value = (Opt - 176): OutPort VoiceData(Chn * 11 + 4), Value * 4
	 IF Opt > 191 AND Opt < &HCF + 1 THEN Vlm = (207 - Opt): OutPort VoiceData(Chn * 11 + 3), 64 - (Vlm * 4)
	 IF Opt > 9 AND Opt < 48 THEN IF Opt < 32 THEN HscData(3, Chn) = (Opt - 16) ELSE IF Opt > &H19 THEN HscData(3, Chn) = -(Opt - 31)
	 Oct = INT(Note / 12)
	 Note = (Note - 1) MOD 12 + 1
	 IF HscData(0, Note) = 686 THEN Oct = Oct - 1
	 IF N = 127 THEN
	    OutPort VoiceData(Chn * 11 + 5), 245
	    OutPort VoiceData(Chn * 11 + 6), 4
	    HscData(4, Chn) = 1
	  ELSE
	    IF HscData(4, Chn) AND Note > 0 THEN
	       HscData(4, Chn) = 0
	       OutPort VoiceData(Chn * 11 + 5), ASC(MID$(Ins(HscData(5, Chn)), 5, 1))
	       OutPort VoiceData(Chn * 11 + 6), ASC(MID$(Ins(HscData(5, Chn)), 6, 1))
	    END IF
	 END IF
	 IF Note = 0 OR Oct > 9 THEN
	    IF HscData(3, Chn) THEN OutPort 160 + Chn, HscData(2, Chn) - (HscData(3, Chn) / 1.2)
	   ELSE
	    A$ = HEX$(ASC(MID$(Ins(HscData(5, Chn)), 12, 1)))
	    IF LEN(A$) = 1 THEN S$ = "&H0" ELSE S$ = "&H" + MID$(A$, 1, 1)
	    Signed = VAL(S$) - HscData(3, Chn)
	    HscData(2, Chn) = HscData(0, Note) + Signed
	    PlayFreq 176 + Chn, 0, 160 + Chn, HscData(0, Note) + Signed * 1.3, 176 + Chn, 32 + Oct * 4 + HscData(1, Note)
	 END IF
      END IF
SkipRow:
      NEXT
      PlayRow = PlayRow + 1: IF PlayRow > 63 THEN PlayPatt = PlayPatt + 1: PlayRow = 0
   END IF
END IF
END SUB

SUB ResetFMChip (Bits)
IF Bits AND 1 THEN
   FOR T = 0 TO 255
    OutPort T, 0
   NEXT
END IF
IF Bits AND 2 THEN
   FOR G = 0 TO 8: OutPort &HA0 + G, 0: NEXT
   FOR G = 0 TO 8: OutPort &HB0 + G, 0: NEXT
   FOR G = 0 TO 8: OutPort &HC0 + G, 32: NEXT
END IF
IF Bits AND 4 THEN
   FOR G = 0 TO 255
   OutPort G, 0
   NEXT
   OutPort 1, 0
   FOR G = &HB0 TO &HB8
   OutPort G, 0
   NEXT
   FOR G = &H80 TO &H8D
   OutPort G, 255
   NEXT
   FOR G = &H90 TO &H95
   OutPort G, 255
   NEXT
END IF
END SUB

SUB SetInst (Chn, InstNum)
FOR P = 1 TO 11
    OutPort VoiceData(Chn * 11 + P), ASC(MID$(Ins(InstNum), P, 1))
NEXT
HscData(5, Chn) = InstNum
END SUB

