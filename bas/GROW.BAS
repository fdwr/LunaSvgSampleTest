DEFINT A-Z
''These are the subs used in this program, to see them, press F2
' Draw a streched picture image, (very advanced, at least for me anyway)
DECLARE SUB DrawStrechImage (Image$, MaxUrow, MaxDrow, MaxLcol, MaxRcol, PictHite, PictWdth)
' Draw all the little highlight/shadow borders and such
DECLARE SUB DrawBorder (Urow, Drow, Lcol, Rcol, Mode)
' Draw an option (dialog) box for the subs
DECLARE SUB DrawOptionBox (Ulin, Dlin, Llin, Rlin, Mode)
' Loads a PIX file from the disk or any other drive
DECLARE SUB LoadImage (File$, LastFile$, Image$, PictHite, PictWdth, ExitSign)
' Select a color for the background
DECLARE SUB SelectColor (ColorFore, ExitSign)
' I do not even need to tell you what this this does ??
DECLARE FUNCTION GetFilName (File$)

''Declare color scheme
' ColorPanel=light gray
' ColorVoid=black
' ColorLight=white
' ColorShadow=dark gray
' ColorText=light blue
CONST ColorPanel = 42, ColorVoid = 0, ColorLight = 63, ColorShadow = 21, ColorText = 58
''FilErr holds the file error value when a file error occurs
' FilErrHandler sets this value to the error number indicated by ERR function
DIM SHARED FilErr

''Set screen mode and palette colors
SCREEN 13
FOR PixColor = 0 TO 63
 RedClr = PixColor AND 3
 GrnClr = (PixColor AND 12) \ 4
 BluClr = (PixColor AND 48) \ 16
 OUT &H3C9, RedClr * 21
 OUT &H3C9, GrnClr * 21
 OUT &H3C9, BluClr * 21
NEXT PixColor

''Ask user whether or not he would like load a different picture
GetUserInputs:
 LoadImage File$, LastFile$, Image$, PictHite, PictWdth, ExitSign: IF ExitSign GOTO EndIt
'' If user pressed Escape, then quit, else continue
 IF File$ = "" THEN
 ''If the user does not specify a filename, set the image to a random one
  PictHite = 10: PictWdth = 20: Image$ = STRING$(PictHite * PictWdth, 0)
  FOR p = 1 TO LEN(Image$): MID$(Image$, p, 1) = CHR$(INT(RND * 40)): NEXT p
 END IF

''Ask the user what color background to make the screen
 SelectColor ColorFore, ExitSign: IF ExitSign GOTO EndIt
''If user pressed Escape, then quit, else continue
 LINE (0, 0)-(319, 199), ColorFore, BF
 IF 200 / PictHite < 320 / PictWdth THEN LastCol = (((200 * PictWdth) / PictHite) / 2) ELSE LastCol = 159

''Draw the picture scaled out
StartImageFlyby:
 FOR ColLimit = 0 TO LastCol
  DrawStrechImage Image$, 0, 199, 159 - ColLimit, 160 + ColLimit, PictHite, PictWdth
 NEXT ColLimit
''Check for the Escape key press
 DO
  kbrd$ = INKEY$: IF kbrd$ = "" THEN EXIT DO ELSE IF kbrd$ = CHR$(27) THEN END
 LOOP

''Draw the picture scaled in
 FOR ColLimit = LastCol TO 0 STEP -1
  DrawStrechImage Image$, 0, 199, 159 - ColLimit, 160 + ColLimit, PictHite, PictWdth
 NEXT ColLimit
''Clear extra key input, wait for a key press before continuing
 WHILE INKEY$ > "": WEND: DO: kbrd$ = INKEY$: LOOP UNTIL kbrd$ > ""
 IF kbrd$ = " " GOTO StartImageFlyby ELSE IF kbrd$ = CHR$(13) GOTO GetUserInputs

''End everything, set screen back to text mode with normal width
EndIt:
SCREEN 0: WIDTH 80, 25: END

''This is an error handler used to catch any file errors that might occur
FilErrHandler: FilErr = ERR: RESUME NEXT

SUB DrawBorder (Urow, Drow, Lcol, Rcol, Mode)

''If mode (bit one) is set to zero, then draw a inward border
''Else, if mode (bit one) is on, draw an outward border
''All we have to do to achieve it, is simply swap the light color with
''the shadow color and we have an inverse border
ColorFore = ColorShadow: ColorBack = ColorLight
IF Mode AND 1 THEN SWAP ColorFore, ColorBack

''The border is really just four connected lines, two light and two dark
LINE (Lcol, Urow)-(Lcol, Drow), ColorFore
LINE (Rcol, Urow)-(Rcol, Drow), ColorBack
LINE (Lcol, Urow)-(Rcol, Urow), ColorFore
LINE (Lcol, Drow)-(Rcol, Drow), ColorBack

''Bit two of mode tells whether or not to draw a blank hole (for a text box)
IF Mode AND 2 THEN LINE (Lcol + 1, Urow + 1)-(Rcol - 1, Drow - 1), ColorVoid, BF
END SUB

SUB DrawOptionBox (Ulin, Dlin, Llin, Rlin, Mode)

''Calculate text line coordinates into screen graphics coordinates
Urow = (Ulin - 1) * 8 - 1: Drow = Dlin * 8 - 1
Lcol = (Llin - 1) * 8 - 1: Rcol = Rlin * 8 - 1
DrawBorder Urow - 3, Drow + 3, Lcol - 3, Rcol + 3, 1
LINE (Lcol - 2, Urow - 2)-(Rcol + 2, Drow + 2), 42, B

''Draw an blank box, or a solid box
IF Mode THEN
 DrawBorder Urow - 1, Drow + 1, Lcol - 1, Rcol + 1, 2
ELSE
 LINE (Lcol - 1, Urow - 1)-(Rcol + 1, Drow + 1), ColorPanel, BF
END IF

END SUB

SUB DrawStrechImage (Image$, MaxUrow, MaxDrow, MaxLcol, MaxRcol, PictHite, PictWdth)

''This below is the sacred code that drove me crazy trying to perfect
''I think that I have it down now though
''Now lets see if if I can explain it to you
''Detetmine the streched height and width (not the actual dimensions)
StrechHite = MaxDrow - MaxUrow + 1: StrechWdth = MaxRcol - MaxLcol + 1
''Determine whether the width or height is longer and adjust to fit
IF StrechHite / PictHite > StrechWdth / PictWdth THEN
 Lcol = MaxLcol: Rcol = MaxRcol
 StrechHite = (StrechWdth * PictHite) \ PictWdth
 Urow = (MaxDrow - MaxUrow + 1 - StrechHite) \ 2 + MaxUrow
 Drow = Urow + StrechHite - 1
ELSE
 Urow = MaxUrow: Drow = MaxDrow
 StrechWdth = (StrechHite * PictWdth) \ PictHite
 Lcol = (MaxRcol - MaxLcol + 1 - StrechWdth) \ 2 + MaxLcol
 Rcol = Lcol + StrechWdth - 1
END IF

''Set string pointer to one (first byte, or pixel) and set the row to the top
pointer = 1
priorRow = Urow
''Actually draw the dumb thing, use a lot of multiplying, dividing, you know..
FOR row = 1 TO PictHite
 nextRow = (StrechHite * row) \ PictHite + Urow - 1
 priorCol = Lcol
 FOR col = 1 TO PictWdth
  nextCol = (StrechWdth * col) \ PictWdth + Lcol - 1
  LINE (priorCol, priorRow)-(nextCol, nextRow), ASC(MID$(Image$, pointer, 1)), BF
  priorCol = nextCol + 1
  pointer = pointer + 1
 NEXT col
 priorRow = nextRow + 1
NEXT row

END SUB

FUNCTION GetFilName (File$)

''Draw (dialog) box and borders
DrawOptionBox 13, 13, 8, 33, 0
DrawBorder 94, 104, 54, 88, 2
DrawBorder 94, 104, 94, 264, 2
COLOR ColorText: LOCATE 13, 8: PRINT "Load";

''Enter get key input loop
Chng = 1
DO
 key$ = INKEY$
 SELECT CASE UCASE$(key$)
 CASE "!" TO "ÿ"
  '' If key is valid, not a DOS illegal character, and length of string is less
  '' than one-hundred twenty-eight charcters, add it to the filename string
  IF INSTR("?*+=<>|/" + CHR$(34), key$) = 0 THEN
   IF LEN(File$) < 128 THEN File$ = File$ + key$
   Chng = 1
  END IF
 CASE CHR$(8): IF LEN(File$) THEN File$ = LEFT$(File$, LEN(File$) - 1): Chng = 1
 CASE CHR$(27): GetFilName = 1: EXIT DO
 CASE CHR$(13): EXIT DO
 END SELECT

''If necessary, redraw filename, the set value of Chng indicates whether or
''not it needs to be refreshed. After drawn, it is reset back to zero
 IF Chng THEN
  LOCATE 13, 13: COLOR ColorText
  IF File$ > "" THEN
   PRINT RIGHT$(File$, 20); : COLOR ColorLight: PRINT "";
   IF LEN(File$) < 20 THEN PRINT SPACE$(20 - LEN(File$));
  ELSE PRINT "[None]";
  END IF
  Chng = 0
 END IF
LOOP

END FUNCTION

SUB LoadImage (File$, LastFile$, Image$, PictHite, PictWdth, ExitSign)

''Sets the error handler, in case there is a problem loading the user's file
ON ERROR GOTO FilErrHandler

DO
 ''Get the filename, exit if user presses Escape or filename prompt is empty
 IF GetFilName(File$) THEN ExitSign = 1: EXIT DO
 IF File$ = "" THEN LastFile$ = "": ExitSign = 0: EXIT DO
 IF File$ = LastFile$ THEN ExitSign = 0: EXIT DO
 ''Otherwise, try to open the file, first checking that it exists
 openFile$ = File$: GOSUB LoadImageOpen
 ''Add `pix' to the name, if the user might have left it off
 IF FilErr THEN openFile$ = File$ + ".pix": GOSUB LoadImageOpen
 IF FilErr THEN
  ''If the specified file can not be opened
  GOSUB LoadErr
 ELSE
  ''If the file does exist, reopen it for binary input
  OPEN openFile$ FOR BINARY AS #1
  IF INPUT$(4, 1) <> CHR$(3) + "PIX" THEN
   ''If filename does not start with `pix' at the beginning, assume that it
   ''is not a real pix image (linear bitmap)
   ''So, don't try to look at your autoexec.bat as a picture, it won't work
   GOSUB LoadWrongType: CLOSE #1
  ELSE
   ''Otherwise, load the file into the image string ($)
   PictHite = ASC(INPUT$(1, 1))
   PictWdth = ASC(INPUT$(1, 1))
   Image$ = INPUT$(PictHite * PictWdth, 1)
   LastFile$ = File$
   ExitSign = 0
   CLOSE #1
   EXIT DO
  END IF
 END IF
LOOP

''Reset the error handler, since we do not need it anymore
ON ERROR GOTO 0

EXIT SUB

''Test to see if the file exists
LoadImageOpen: FilErr = 0: OPEN openFile$ FOR INPUT AS #1: CLOSE #1: RETURN

''If the file does not exist, or exists somewhere else
LoadErr:
DrawOptionBox 13, 13, 8, 33, 1
LOCATE 13, 12: PRINT "Error loading file";
WHILE INKEY$ = "": WEND
RETURN

''If the image file does not start with `pix'
LoadWrongType:
DrawOptionBox 13, 13, 8, 33, 1
LOCATE 13, 11: PRINT "Not an ASCII picture";
WHILE INKEY$ = "": WEND
RETURN

END SUB

SUB SelectColor (ColorFore, ExitSign)

''Draw the usual (dialog) box and borders
DrawOptionBox 11, 15, 14, 27, 0
DrawBorder 78, 88, 142, 184, 2
DrawBorder 94, 104, 142, 184, 2
DrawBorder 110, 120, 142, 184, 2
DrawBorder 78, 120, 102, 136, 0

''Dimension a spot for red, green, and blue color values
DIM RGBs(0 TO 2)
RGBs(0) = ColorFore AND 3
RGBs(1) = (ColorFore AND 12) \ 4
RGBs(2) = (ColorFore AND 48) \ 16
''Show all the items
GOSUB SelectColorShowItems: GOSUB SelectColorOrColors
FOR item = 0 TO 2: GOSUB SelectColorShowBar: NEXT

''Start the get key input loop
DO
 kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE CHR$(0) + "H": MenuChoice = (MenuChoice + 2) MOD 3: GOSUB SelectColorShowItems
 CASE CHR$(0) + "P": MenuChoice = (MenuChoice + 1) MOD 3: GOSUB SelectColorShowItems
 CASE CHR$(0) + "K": IF RGBs(MenuChoice) > 0 THEN RGBs(MenuChoice) = RGBs(MenuChoice) - 1: item = MenuChoice: GOSUB SelectColorOrColors: GOSUB SelectColorShowBar
 CASE CHR$(0) + "M": IF RGBs(MenuChoice) < 3 THEN RGBs(MenuChoice) = RGBs(MenuChoice) + 1: item = MenuChoice: GOSUB SelectColorOrColors: GOSUB SelectColorShowBar
 CASE CHR$(13): GOSUB SelectColorOrColors: ColorFore = ColorBack: ExitSign = 0: EXIT SUB
 CASE CHR$(27): ExitSign = -1: EXIT SUB
 END SELECT
LOOP

''Combine the three color values (RGB) into one color
''Draw the little box that show the current color
SelectColorOrColors:
ColorBack = 0
ColorBack = ColorBack OR RGBs(0)
ColorBack = ColorBack OR RGBs(1) * 4
ColorBack = ColorBack OR RGBs(2) * 16
LINE (103, 79)-(135, 119), ColorBack, BF
RETURN

''Draw one of the color slide bars (which one is drawn depends on `item')
SelectColorShowBar:
 ''Draw the grey background
 Urow = item * 16 + 80: Lcol = 190
 LINE (Lcol, Urow)-(Lcol + 23, Urow + 2), ColorPanel, BF
 LINE (Lcol, Urow + 5)-(Lcol + 23, Urow + 7), ColorPanel, BF
 ''Draw the slide line
 DrawBorder Urow + 3, Urow + 4, Lcol, Lcol + 23, ColorVoid
 ''Draw the slide bar handle
 Lcol = RGBs(item) * 6 + Lcol
 DrawBorder Urow, Urow + 7, Lcol, Lcol + 5, 3
RETURN

''Draws all of the choices (Red,Green,Blue)
''Highlights the current one and dehilights the others to light blue
''The highlighted one is the `to be set' value and is colored white
SelectColorShowItems:
 FOR item = 0 TO 2
  IF item = MenuChoice THEN COLOR ColorLight ELSE COLOR ColorText
  LOCATE 11 + item * 2, 19
  PRINT MID$("Red  GreenBlue", item * 5 + 1, 5);
 NEXT item
RETURN
END SUB

