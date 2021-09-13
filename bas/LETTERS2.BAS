'Letters2.bas by FDwR on 4-98, ver 2.2, started on 10-97 from Letters1.bas
'Written for Qb 4.5
'
'  This program is really just a demo of letter font blitting in Qbasic.
'Qbasic is a handy language for its small size and simplicity, but there are
'definitely some missing features that would really be nice. One of those nice
'features would be some decent fonts in mode 13 that can be put anywhere
'quickly. That's why I made this. If you ever wanted to put font characters
'onto the screen at any x,y and not just at specific grid row\columns, or if
'you ever wanted transparent fonts instead of annoying solid black backgrounds
'that overwrite your backgrounds, or if you ever wanted to put your text
'halfway off screen or totally off screen without some stupid 'Illegal
'Function call' stopping your program and just plain annoying you, this should
'really help you. Just try something like "LOCATE 20,-40" and see what happens.
'Or how about something like "LOCATE 20.5, 30.7". You might think that this
'would put a line halfway between two normal lines but sorry, text grid only!
'Another thing, if you try to print a string that is 60 characters long at
'(10,50) the whole bit of text will jump down to the next line!! Sometimes
'I'd like to rewrite (or do some damge to) the PRINT command. Ever wish that
'you could put multiple colors in a sinle line of text; with this, it's a lot
'simpler since you can include a color parameter with each call instead of
'using a completely separate COLOR statement. And just try some of the cool
'text tricks using transparency with simple PRINT...I don't think so!

'Anyways, now that I've put down Qbasic and vented my frustration with it,
'hope it's some use to somebody. There is both a Qbasic version (DrawCharSlow)
'and an assembly language version (DrawCharFast).

DEFINT A-Z
DECLARE SUB DrawChar (char, Row, Col, Clr)
DECLARE SUB DrawCharSlow (char, Row, Col, Clr)
DECLARE SUB DrawCharFast (char, Row, Col, Clr)
DECLARE SUB DrawCharStringFast (chars$, Row, Col, RowInc, ColInc, Clr)

TYPE RegType
 AX AS INTEGER
 BX AS INTEGER
 Cx AS INTEGER
 DX AS INTEGER
 BP AS INTEGER
 SI AS INTEGER
 DI AS INTEGER
 FLAGS AS INTEGER
 DS AS INTEGER
 ES AS INTEGER
END TYPE
DIM SHARED UseFastBlitting, Regs AS RegType, BytesPerChar AS INTEGER, CharHeight AS INTEGER
  'Global variables used among all subs
DIM SHARED FontBlitCode$
  'Important for the DrawChar and DrawCharFast sub
DIM CursorBackground(1 TO 68)
  'used to save a snapshot of screen where the cursor was

PRINT "Calling video BIOS to get font table location"
Regs.AX = &H1130 'VGA function 11:30, get character font table
Regs.BX = &H400 'Font table 8x16
CALL InterruptX(&H10, Regs, Regs)
BytesPerChar = Regs.Cx
CharHeight = Regs.DX AND 255

'  Originally, I was just going to make the position in memory of the font
'table a constant, but then I found out that every computer's video card
'stored its fonts in different spots; and unless I wanted my letters to look
'like garbage, this had to use a function that would work on any with standard
'video adapter to tell where they were. The position of the 8x8 character
'fonts in the startup BIOS 'is' a constant, but all of the good
'fonts that are used in higher screen modes can be anywhere - only the video
'card (or actually the video BIOS) knows, so just ask it. Bty, the fonts at
'in the startup BIOS are always at &hF000:FA6E.
'  This isn't meant to be a detailed explanation of all the various functions
'that the video BIOS has, but just a demo. If you want to know any more about
'things such as defining your own character table, scrolling just a window of
'the screen either up or down (instead the whole dumb thing only going down),
'or setting SVGA modes (such as 648x480 256clrs!), look in a book or just
'search the net like I did. There are also some libraries to do these things
'for those who have QB 4.5, but anybody with just QB 1.1 can still do all
'those things by using RegType and QbasicInterrupt - it's just a little more
'work for you.

'---read in data for assembly version
READ index                    'the first word tells how many bytes follow
FontBlitCode$ = SPACE$(index) 'the number of bytes reserved for the code
FOR index = 1 TO index
  READ byte
  MID$(FontBlitCode$, index) = CHR$(byte)
NEXT index
'---end of reading data
'To see the data statements or explanation, skip down to the bottom.

Vrow = 72: Hcol = 0

StartDemo:
SCREEN 13: CLS

text$ = "These are clipped words halfway off"
FOR CurLetter = 1 TO LEN(text$)
 DrawChar ASC(MID$(text$, CurLetter, 1)), -4, CurLetter * 8, 12
NEXT CurLetter

text$ = "These are unclipped words on screen"
FOR CurLetter = 1 TO LEN(text$)
 DrawChar ASC(MID$(text$, CurLetter, 1)), 8, CurLetter * 8, 14
NEXT CurLetter

text$ = "Here the left side of 'H'is clipped"
FOR CurLetter = 1 TO LEN(text$)
 DrawChar ASC(MID$(text$, CurLetter, 1)), 20, CurLetter * 8 - 12, 10
NEXT CurLetter

text$ = "Now the right side is chopped off"
FOR CurLetter = 1 TO LEN(text$)
 DrawChar ASC(MID$(text$, CurLetter, 1)), 32, CurLetter * 8 + 53, 11
NEXT CurLetter

FOR index = 78 TO 5 STEP -1  'Draw a gradient circle, nothing special, just a background
 CIRCLE (160, 100), index, (index \ 5) + 80  'Draw an ever shrinking circle
 PAINT (160, 100), (index \ 5) + 80  'Fill in that newest circle with a solid color
NEXT

text$ = "This is much faster than my old one!"
FOR CurLetter = 1 TO LEN(text$)
 DrawChar ASC(MID$(text$, CurLetter, 1)), 44, CurLetter * 8, 9
NEXT CurLetter

LINE (14, 54)-(120, 67), 75, BF  'Some more background, draw a light blue box to highlight next phrase
text$ = "Much neater too!!"
FOR CurLetter = 1 TO LEN(text$)
 DrawChar ASC(MID$(text$, CurLetter, 1)), 56, CurLetter * 8, 9
NEXT CurLetter
FOR CurLetter = 1 TO LEN(text$)
 DrawChar ASC(MID$(text$, CurLetter, 1)), 57, CurLetter * 8 + 1, 1
NEXT CurLetter
FOR CurLetter = 1 TO LEN(text$)
 DrawChar ASC(MID$(text$, CurLetter, 1)), 58, CurLetter * 8 + 2, 5
NEXT CurLetter
FOR CurLetter = 1 TO LEN(text$)
 DrawChar ASC(MID$(text$, CurLetter, 1)), 59, CurLetter * 8 + 3, 13
NEXT CurLetter

text$ = "Wouldn't you say?"
DrawCharStringFast text$, 56, 168, 0, 8, 9
DrawCharStringFast text$, 57, 169, 3, 7, 1
DrawCharStringFast text$, 58, 170, 6, 6, 5
DrawCharStringFast text$, 59, 171, 8, 4, 13

text$ = "Try out the assembly version by pressingEnter. You will notice a big difference between it and the Qbasic  equivalent inspeed. Try using the arrow keys and"
Clr = 31
FOR CurLetter = 0 TO LEN(text$) - 1
 DrawChar ASC(MID$(text$, CurLetter + 1, 1)), (CurLetter \ 40) * 8 + 72, (CurLetter MOD 40) * 8, Clr
 IF Clr >= 31 THEN ClrInc = -1 ELSE IF Clr <= 24 THEN ClrInc = 1
 Clr = Clr + ClrInc
NEXT CurLetter
text$ = "typing something. If you want to use    either the assembly or Qbasic code, feelfree to copy them into your own programs"
FOR CurLetter = 0 TO LEN(text$) - 1
 DrawChar ASC(MID$(text$, CurLetter + 1, 1)), (CurLetter \ 40) * 8 + 104, (CurLetter MOD 40) * 8, Clr
 IF Clr >= 31 THEN ClrInc = -1 ELSE IF Clr <= 24 THEN ClrInc = 1
 Clr = Clr + ClrInc
NEXT CurLetter

'All of the first 128 ASCII characters, including Bell and CReturn!
FOR CurLetter = 0 TO 127
 DrawChar CurLetter, (CurLetter \ 40) * 8 + 140, (CurLetter MOD 40) * 8, 3
NEXT CurLetter

text$ = "Press Esc to exit, Enter for ???? "
IF UseFastBlitting AND LEN(FontBlitCode$) > 0 THEN MID$(text$, 30) = "slow" ELSE MID$(text$, 30) = "speed"
FOR CurLetter = 1 TO LEN(text$)
 DrawChar ASC(MID$(text$, CurLetter, 1)), 182, CurLetter * 8 + 13, CurLetter MOD 7 + 1
NEXT CurLetter
FOR CurLetter = 1 TO LEN(text$)
 DrawChar ASC(MID$(text$, CurLetter, 1)), 183, CurLetter * 8 + 12, CurLetter MOD 7 + 9
NEXT CurLetter

PRINT "Byte per character:"; Regs.Cx
PRINT "Number of rows:"; Regs.DX AND 255
PRINT "Font table location: segment"; Regs.ES; "offset"; Regs.BP

'Vrow=Vertical cursor row  Hcol=Horizontal curosr column

GOSUB GetCursorBackground
DO UNTIL done    'do the loop until done <> 0
 Kbrd$ = INKEY$  'Get key from user
 IF LEN(Kbrd$) THEN
  DEF SEG = 0  'Set to segment zero for next instruction, check whether Shift key is held down
  IF (PEEK(1047) AND 11) AND INSTR(CHR$(13) + "", Kbrd$) > 0 THEN
   GOSUB PrintCharacter
     'If you hold down Shift or Alt, even control characters can be shown.
     'Ever ask yourself, I wonder what carriage return (cr) or end of file
     '(eof) actually look like, since they're not in QBasic's ASCII chart?
     'Try Shift + Enter and see a symbol you've probably never seen before!
     'Since it's always (annoyingly) interpreted as a line wrap control
     'character, you never get to see its real symbol.
  ELSE
   SELECT CASE Kbrd$
   CASE CHR$(0) + "H": IF Vrow > -7 THEN Vrow = Vrow - 1: GOSUB MoveCursor  'Up
   CASE CHR$(0) + "P": IF Vrow < 199 THEN Vrow = Vrow + 1: GOSUB MoveCursor 'Down
   CASE CHR$(0) + "K": IF Hcol > -7 THEN Hcol = Hcol - 1: GOSUB MoveCursor  'Left
   CASE CHR$(0) + "M": IF Hcol < 319 THEN Hcol = Hcol + 1: GOSUB MoveCursor 'Right
   CASE CHR$(13): UseFastBlitting = UseFastBlitting XOR 1: GOTO StartDemo  'Toggle between fastblitting and slow blitting
   CASE CHR$(27): done = 1  'set variable done when user presses Escape
   CASE CHR$(8)  'Backspace is ASCII character 8
    Hcol = Hcol - 8  'move cursor eight pixels to the left, prior column
    IF Hcol < -7 THEN Hcol = Hcol + 320: IF Vrow > 0 THEN Vrow = Vrow - 8
    GOSUB HideCursor
    LINE (Hcol, Vrow)-(Hcol + 7, Vrow + 7), 0, BF  'draw a black solid box
    GOSUB MoveCursorWithoutHide
   CASE ELSE: GOSUB PrintCharacter 'Any other key gets 'printed'
   END SELECT
  END IF
 END IF
 IF TIMER - LastTime! > .5 THEN
   'If more than .5 of a second has gone by since the last cursor blink, then
   'toggle cursor again - off goes on and on goes off - and reset timer.
  CursorState = CursorState XOR 1
  GOSUB DisplayCursor
  LastTime! = TIMER
 END IF
LOOP

WIDTH 80, 25
COLOR 7, 0: CLS

END

PrintCharacter:
 GOSUB HideCursor
 DrawChar ASC(Kbrd$), Vrow, Hcol, 10
   'Draw character to screen by calling Sub
 Hcol = Hcol + 8
   'Move to next column, eight pixels over to the right
 IF Hcol > 319 THEN Hcol = Hcol - 320: IF Vrow < 192 THEN Vrow = Vrow + 8 ELSE Vrow = Vrow - 200
   'wrap back to left of screen and down a line if past edge
 GOSUB MoveCursorWithoutHide
   'Reset cursor and grab background
RETURN

DisplayCursor:
 ''LOCATE 1, 1: PRINT "Cursor is at"; Vrow; Hcol; "and is "; MID$("offon", CursorState * 3 + 1, 3); TAB(40);
 IF CursorState GOTO ShowCursor ELSE GOTO HideCursor
   'Show cursor if CursorState <> 0, otherwise hide cursor
RETURN

ShowCursor:
 LINE (Hcol, Vrow)-(Hcol + 7, Vrow + 7), 12, B
   'draw red box where cursor is
RETURN

HideCursor:
 PUT (Ccol, Crow), CursorBackground, PSET
   'restore background to screen
RETURN

MoveCursor:
 GOSUB HideCursor
MoveCursorWithoutHide:
 GOSUB GetCursorBackground
 CursorState = 1    'turn cursor on while moving
 LastTime! = TIMER  'reset timer after a move for at least .5 of a second
 GOSUB DisplayCursor
RETURN

GetCursorBackground:
 IF Vrow < 0 THEN Crow = 0 ELSE IF Vrow > 192 THEN Crow = 192 ELSE Crow = Vrow
 IF Hcol < 0 THEN Ccol = 0 ELSE IF Hcol > 312 THEN Ccol = 312 ELSE Ccol = Hcol
 GET (Ccol, Crow)-(Ccol + 7, Crow + 7), CursorBackground
   'Grab background from screen and save to array CursorBackground
RETURN

FilErrHan:
 FilErr = 1
   'There has been a file error, set variable FilErr to 1 and return
RESUME NEXT

'All these confusing numbers don't mean anything except to the computer...to
'the computer, you're speaking it's native language. If you have a 'translator'
'(compilers and decompilers) that understands binary symbols and numbers and
'turns them into a slightly more 'English' form (called assembly language),
'it's not too hard to understand. For this bit of code, I used a free compiler
'called Netwide Assembler. To see them in 'English', look at 'blitfont.asm'.

DATA 167,30,6,85,137,229,184,0,240,142,216,184,0,160,142,192,139,118,10,193,230
DATA 3,129,198,110,250,139,94,12,133,219,121,11,41,222,129,195,8,0,49,255,233
DATA 24,0,137,216,191,64,1,247,231,137,199,247,219,129,195,200,0,129,251,8,0
DATA 120,3,187,8,0,129,251,1,0,15,136,86,0,139,86,14,133,210,121,11,137,209
DATA 246,217,129,194,8,0,233,19,0,1,215,48,201,247,218,129,194,64,1,129,250,8
DATA 0,120,3,186,8,0,129,250,1,0,15,136,41,0,136,213,247,218,129,194,64,1,138
DATA 70,16,138,36,70,210,224,136,239,208,228,115,8,170,254,207,117,247,233,5,0
DATA 71,254,207,117,239,1,215,254,203,117,226,93,7,31,202,8,0

'Font blitting code accepts the following parameters:
'  letter%, row%, col%, color%
'
'  letter% is any ASCII code letter 0 to 255
'  row% is a signed integer for the vertical row
'  col% is an integer for the the horizontal column
'  color% is 0 to 255

'  You can actually set letter% to anything, even to some high number like
'27694 without any annoying illegal function call; however all you will see is
'garbage. Unlike Qbasic, it does abruptly not stop your program if a number
'happens to excede 32767, since it uses unsigned numbers. If you give the
'Qbasic version (DrawCharSlow) such a high number though, you will likely
'cause an Overflow error.
'  Row% and column% can be negative numbers or positive numbers beyond the
'screen. They will be handled by clipping the edges and not drawing off the
'screen or wrapping around to the other side. Unlike the Qbasic statement to
'print a character on the screen, this one can be set to any row\column pixel
'position - not just text rows and columns. The only rules are that the font
'must be 8x8 in size and the screen mode must be mode 13. The assembly code
'provided along with this program is not necessary for it to work if you use the
'slower Qbasic version instead.
'  !! Don't mess with the name of the string used to hold the code...
'If you do decide to change the name to something other than FontBlitCode$ be
'sure that you also change the string name in the 'CALL ABSOLUTE' or else
'your program could crash and your computer possibly lock up since you would
'be calling a string that does not exist.
'  Also, if you plan to use the fast version in you own programs, be sure to
'include the lines that read in the data, the data statements above, and the
'DrawCharFast sub too.
'  The slow version does not require anything but the DrawCharSlow sub to
'work; it does not need any of the DATA statements. The DrawChar sub is meant
'just for this program; use DrawCharSlow or DrawCharFast for your own.
'Both versions have clipping and transparency; it's just a matter of speed.

SUB DrawChar (char, Row, Col, Clr)

CharHeight = 16
CharWidth = 8
IF UseFastBlitting AND LEN(FontBlitCode$) > 0 THEN
 DEF SEG = VARSEG(FontBlitCode$)
 CALL absolute(BYVAL Clr, BYVAL Col, BYVAL Row, BYVAL char, SADD(FontBlitCode$))
 '!parameters are passed in reverse order
 EXIT SUB
END IF

'source& = char * 8 + &HFA6E '&hF000
source& = char * BytesPerChar + Regs.BP

IF Row < 0 THEN
 hite = CharHeight + Row
 source& = source& - Row
 dest& = 0
ELSE
 dest& = Row * 320&
 hite = 200 - Row
 IF hite > CharHeight THEN hite = CharHeight
END IF
IF hite < 1 THEN EXIT SUB

IF Col < 0 THEN
 wdth = CharWidth + Col
 Shift = -Col
ELSE
 dest& = dest& + Col
 Shift = 0
 wdth = 320 - Col
 IF wdth > CharWidth THEN wdth = CharWidth
END IF
IF wdth < 1 THEN EXIT SUB

wrap = 321 - wdth
'For some weird italic effect, change the 321 to 320
Shift = 2 ^ Shift

FOR currow = 1 TO hite
 DEF SEG = Regs.ES
 byte = PEEK(source&)
 byte = byte * Shift
 DEF SEG = &HA000
 FOR curcol = 2 TO wdth
  IF byte AND 128 THEN POKE dest&, Clr
  byte = byte * 2
  dest& = dest& + 1
 NEXT curcol
 IF byte AND 128 THEN POKE dest&, Clr
 dest& = dest& + wrap
 source& = source& + 1
NEXT currow

END SUB

SUB DrawCharFast (char, Row, Col, Clr)

IF LEN(FontBlitCode$) = 0 THEN EXIT SUB

DEF SEG = VARSEG(FontBlitCode$)
CALL absolute(BYVAL Clr, BYVAL Col, BYVAL Row, BYVAL char, SADD(FontBlitCode$))
'!parameters are passed in reverse order

END SUB

SUB DrawCharSlow (char, Row, Col, Clr)

source& = char * 8 + &HFA6E

IF Row < 0 THEN
 hite = 8 + Row
 source& = source& - Row
 dest& = 0
ELSE
 dest& = Row * 320&
 hite = 200 - Row
 IF hite > 8 THEN hite = 8
END IF
IF hite < 1 THEN EXIT SUB

IF Col < 0 THEN
 wdth = 8 + Col
 Shift = -Col
ELSE
 dest& = dest& + Col
 Shift = 0
 wdth = 320 - Col
 IF wdth > 8 THEN wdth = 8
END IF
IF wdth < 1 THEN EXIT SUB

wrap = 321 - wdth
'For some weird italic effect, change the 321 to 320
Shift = 2 ^ Shift

FOR currow = 1 TO hite
 DEF SEG = &HF000
 byte = PEEK(source&)
 byte = byte * Shift
 DEF SEG = &HA000
 FOR curcol = 2 TO wdth
  IF byte AND 128 THEN POKE dest&, Clr
  byte = byte * 2
  dest& = dest& + 1
 NEXT curcol
 IF byte AND 128 THEN POKE dest&, Clr
 dest& = dest& + wrap
 source& = source& + 1
NEXT currow

END SUB

SUB DrawCharStringFast (chars$, Row, Col, RowInc, ColInc, Clr)

IF LEN(FontBlitCode$) = 0 THEN EXIT SUB
TmpRow = Row: TmpCol = Col

DEF SEG = VARSEG(FontBlitCode$)
FOR index = 1 TO LEN(chars$)
 CALL absolute(BYVAL Clr, BYVAL TmpCol, BYVAL TmpRow, BYVAL ASC(MID$(chars$, index, 1)), SADD(FontBlitCode$))
 TmpRow = TmpRow + RowInc: TmpCol = TmpCol + ColInc
NEXT index
'!parameters are passed in reverse order
END SUB

