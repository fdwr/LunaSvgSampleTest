''' Simple frame animator, created 10-28-96
DEFINT A-Z
''' Set screen and print static text
WIDTH 80, 50
COLOR 7
 LOCATE 3, 1, 0
 PRINT "Use the up and down arrow keys to change the animation clip"
 PRINT "Use the left and right keys to change the frame time or speed"
COLOR 15
 LOCATE 1, 5
 PRINT "Clip:"; TAB(30); "Frames per second:";

''' Define animation parameters
ClipMax = 5
DIM Clips$(1 TO ClipMax)
FOR clip = 1 TO ClipMax
 READ Clips$(clip)
 DATA " Ûþùú","*+ùúù+*","ABCDEFGHIJKLMNOPQRSTUVWXYZ",""," °±²Û²±°"
NEXT clip
CONST timech# = .015625: frametime# = .125: clip = 1: frame = 1
GOSUB SetClip

''' Show animation clips until done
DO
 Kbrd$ = INKEY$
DecideKeyInput:
 SELECT CASE Kbrd$
 CASE CHR$(0) + "H": IF clip < ClipMax THEN clip = clip + 1: GOSUB SetClip ELSE clip = ClipMax
 CASE CHR$(0) + "P": IF clip > 1 THEN clip = clip - 1: GOSUB SetClip ELSE clip = 1
 CASE CHR$(0) + "K": IF frametime# < 2 THEN frametime# = frametime# + timech#: GOSUB ShowInfo
 CASE CHR$(0) + "M": IF frametime# > timech# THEN frametime# = frametime# - timech#: GOSUB ShowInfo
 CASE CHR$(13), CHR$(27): END
 END SELECT

 GOSUB FrameShower
LOOP

FrameShower:
DO

 IF TIMER - pretime# > frametime# THEN
  ''' Reset the frame timer
  pretime# = TIMER

  ''' Print the frame on to the screen
  LOCATE 1, 1: PRINT MID$(frames$, frame, 1);

  ''' Increment to the next frame or loop back to first
  IF frame >= LEN(frames$) THEN frame = 1 ELSE frame = frame + 1
 END IF

 ''' Check the keyboard
 Kbrd$ = INKEY$
 IF Kbrd$ > "" THEN RETURN DecideKeyInput

LOOP

SetClip: frames$ = Clips$(clip): GOSUB ShowInfo: RETURN

ShowInfo:
 LOCATE 1, 10: PRINT clip; "out of"; ClipMax;
 LOCATE , 48: PRINT frametime#; "      ";
RETURN

