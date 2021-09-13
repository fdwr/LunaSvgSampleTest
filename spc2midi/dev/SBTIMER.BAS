'    ; The SB timer2 oddly increments up (every 320us) until a byte overflow
'    ; rather than decrementing down to zero, so the value we send it is
'    ; [256 - x]. [104 * .00032 = .03328] (roughly 1/30th of a second)
'    mov eax,(152<<8) | Sb.Timer2Count
'    call WriteSbReg
'    mov eax,(Sb.TimerReset<<8) | Sb.TimerControl
'    call WriteSbReg                 ;reset timer expired flags
'    mov eax,(Sb.Timer1Mask | Sb.Timer2Start<<8) | Sb.TimerControl
'    call WriteSbReg                 ;activate timer 2 only
'    mov edx,TimerHandlerSb          ;sound card timer handler

DEFINT A-Z
DECLARE SUB SbDataOut (Register%, Value%)

CONST SbPortBase = &H388

CALL SbDataOut(4, 0)
CALL SbDataOut(3, 0)
CALL SbDataOut(4, 2 + 64)
'CALL SbDataOut(4, 128)
'DO: LOCATE , 1: PRINT TIMER, HEX$(INP(&H388)): LOOP UNTIL LEN(INKEY$)
'CALL SbDataOut(4, 128)
'DO: LOCATE , 1: PRINT TIMER, HEX$(INP(&H388)): LOOP UNTIL LEN(INKEY$)

CALL SbDataOut(4, 128)
DO
    IF INP(&H388) AND 32 THEN
        Count = Count + 1
        LOCATE , 1: PRINT TIMER; TAB(15); Count;
        CALL SbDataOut(4, 128)
    END IF
LOOP UNTIL LEN(INKEY$)
'set reg 3 with 50   'timer value
'set reg 4 with 128  'reset
'set reg 4 with 2    'start timer 2

SUB SbDataOut (Register, Value)
    OUT SbPortBase, Register
    Dummy = INP(SbPortBase): Dummy = INP(SbPortBase): Dummy = INP(SbPortBase)
    OUT SbPortBase + 1, Value
    Dummy = INP(SbPortBase): Dummy = INP(SbPortBase): Dummy = INP(SbPortBase)
    Dummy = INP(SbPortBase): Dummy = INP(SbPortBase): Dummy = INP(SbPortBase)
END SUB

