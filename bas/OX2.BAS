DEFINT A-Z
DECLARE FUNCTION VertiMenu (Kbrd$, Item, Items)
DECLARE SUB DrawSign (Urow, Drow, Lcol, Rcol, Sign, SignColor, BackColor)

CONST BoardHite = 400, BoardWdth = 400, BoardVertOfst = 16: BoardHorzOfst = 120
SCREEN 12

SUB DefGrid (Hite, Wdth)
'Defines the dimensions of the grid and absolute screen corrdinates
END SUB

SUB DrawCell (Row, Col, Mode)

'check bounds for limits
'figure out rectagular bounds
'get sign from row:col
IF Mode AND 1 THEN SignColor = 15 ELSE IF Sign = 79 THEN SignColor = 9 ELSE IF Sign = 88 THEN SignColor = 12
IF Mode AND 2 THEN BackColor = 7 ELSE BackColor = 1
DrawSign Urow, Drow, Lcol, Rcol, Sign, SignColor, BackColor

END SUB

SUB DrawSign (Urow, Drow, Lcol, Rcol, Sign, SignColor, BackColor)
'Draws the X's, O's, and blank spaces for the game board
'Normally called by DrawGridCell to draw a single character, but can also be
'called by itself

END SUB

SUB DrawWholeGrid

'Draws the entire grid rather than a single grid cell, including the board
'lines and shadow. Uses DefGrid to define the grid before it draws. Used to
'redraw grid when a new game is started or when a user toggles back from the
'escape menu.
END SUB

SUB ScrnPal (Mode)
'Depending on Mode, turns the screen palette on or off so that drawing can be
'done in secret and then flipped on.
END SUB

FUNCTION VertiMenu (Kbrd$, Item, Items)
'This function serves as a vertical menu reactor by responding to key presses
'of the up and down arrows. An up key press will lower the current item number
'while a down key press will heighten the number. A overbound either direction
'will result in recursion. When an arrow key is pressed in any options screen,
'the keypress is transparently passed onto this routine which modifies the
'item value depending on the total number of items.

IF Kbrd$ = CHR$(0) + "P" THEN
 Item = (Item + 1) MOD Items
 VertiMenu = 1
ELSEIF Kbrd$ = CHR$(0) + "H" THEN
 Item = (Item + Items - 1) MOD Items
 VertiMenu = 1
ELSE VertiMenu = 0
END IF

END FUNCTION

