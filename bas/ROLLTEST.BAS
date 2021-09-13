DEFINT A-Z
DECLARE SUB RollCarryLeft (BitString$, Carry$)
DECLARE SUB RollCarryRight (BitString$, Carry$)
DECLARE SUB ShowTextInfo (InfoText$)

SCREEN 0: CLS
CONST Zero$ = "0", One$ = "1"

BitString$ = STRING$(32, Zero$)
Carry$ = Zero$

GOSUB GetBitString
InfoText$ = "Left/Right rolls the bits, Space toggles carry, Enter allows editing"
ShowTextInfo InfoText$

Redraw = 1
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE CHR$(27): EXIT DO
  CASE CHR$(0) + "K"
    RollCarryLeft BitString$, Carry$
    RollCount = RollCount + 1: Redraw = 1
  CASE CHR$(0) + "M"
    RollCarryRight BitString$, Carry$
    RollCount = RollCount - 1: Redraw = 1
  CASE " "
    IF Carry$ = Zero$ THEN Carry$ = One$ ELSE Carry$ = Zero$
    Redraw = 1
  CASE "0", "1": Carry$ = Key$
  CASE CHR$(13)
    GOSUB GetBitString
    ShowTextInfo InfoText$
    Redraw = 1
  END SELECT

  IF Redraw THEN
    LOCATE 1, 1, 0: COLOR 15, 1: PRINT BitString$;
    LOCATE , 34: PRINT Carry$;
    COLOR 7, 0: PRINT RollCount;
    Redraw = 0
  END IF
LOOP

END

GetBitString:
  TmpString$ = BitString$
  IF CursorPos < 1 THEN CursorPos = 1
 
  ShowTextInfo "Left/Right moves the cursor, 0/1 changes, Space toggles, Enter accepts"
  COLOR 7, 1
  Redraw = 1
  DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE CHR$(27)
      RETURN
    CASE CHR$(13)
      BitString$ = TmpString$
      RETURN
    CASE " "
      IF MID$(TmpString$, CursorPos, 1) = Zero$ THEN Key$ = One$ ELSE Key$ = Zero$
      MID$(TmpString$, CursorPos, 1) = Key$: Redraw = 1
      GOSUB AdvancePromptCursor
    CASE "0", "1"
      MID$(TmpString$, CursorPos, 1) = Key$: Redraw = 1
      GOSUB AdvancePromptCursor
    CASE CHR$(0) + "K"
      IF CursorPos > 1 THEN CursorPos = CursorPos - 1: Redraw = 1
    CASE CHR$(0) + "M"
      GOSUB AdvancePromptCursor
    END SELECT

    IF Redraw THEN
      LOCATE 1, 1, 0: PRINT TmpString$;
      LOCATE , CursorPos, 1
      Redraw = 0
    END IF
  LOOP
RETURN

AdvancePromptCursor:
  IF CursorPos < LEN(TmpString$) THEN CursorPos = CursorPos + 1: Redraw = 1
RETURN

SUB RollCarryLeft (BitString$, Carry$)

Temp$ = LEFT$(BitString$, 1)
BitString$ = RIGHT$(BitString$ + Carry$, 32)
Carry$ = Temp$

END SUB

SUB RollCarryRight (BitString$, Carry$)

Temp$ = RIGHT$(BitString$, 1)
BitString$ = LEFT$(Carry$ + BitString$, 32)
Carry$ = Temp$

END SUB

SUB ShowTextInfo (InfoText$)

LOCATE 2, 1: COLOR 5, 0: PRINT InfoText$; TAB(80);

END SUB

