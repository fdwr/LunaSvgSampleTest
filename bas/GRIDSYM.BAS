'Redistribute Grid Symmetrically
'Dwayne Robinson
'2001.4.25
'
'Displays a variable size grid of dots that are automatically repositioned
'to fit best symmetrically in the given width. For example, if only five
'pictures (text dots) can fit on the screen, then anything up to five will
'fit centered on one line; but six pictures requires two lines. Rather
'unevenly split the first five on the top line and the last sixth on the
'bottom line, it splits them balanced as possible; in this case, putting
'the first three on the top and last three on the bottom.
'
'This test program was written for a voting program where you could see
'pictures of each candidate on the selection screen. The number of candidates
'would change each year though, so rather than statically code the screen
'positions, the routine would have to be dynamic.
'
'Use arrow keys to adjust the total number of pictures (dots) and adjust the
'maximum width, or number pictures allowed per row.

Points = 17
PointsPerRow = 6
ScreenHeight = 25
ScreenWidth = 80
RowSep = 2
ColSep = 3

GOSUB RepositionDots
DO
    SELECT CASE INKEY$
    CASE CHR$(0) + "P": IF Points > 1 THEN Points = Points - 1: GOSUB RepositionDots
    CASE CHR$(0) + "H": IF Points < 100 THEN Points = Points + 1: GOSUB RepositionDots
    CASE CHR$(0) + "K": IF PointsPerRow > 1 THEN PointsPerRow = PointsPerRow - 1: GOSUB RepositionDots
    CASE CHR$(0) + "M": IF PointsPerRow < 20 THEN PointsPerRow = PointsPerRow + 1: GOSUB RepositionDots
    CASE CHR$(27): EXIT DO
    END SELECT
LOOP

END

RepositionDots:

CLS

Rows = (Points + PointsPerRow - 1) \ PointsPerRow
Cols = Points \ Rows
PRINT "Use arrow keys to adjust the total number of pictures (dots) and adjust the"
PRINT "maximum width, or number pictures allowed per row."
PRINT
PRINT "Points:"; Points
PRINT "Width:"; PointsPerRow
PRINT "Rows:"; Rows
PRINT "Cols:"; Cols

'LOCATE 13, 40: COLOR 15: PRINT "X";

Top = (ScreenHeight - (Rows * RowSep)) \ 2
RowMod = Points MOD Rows'(Rows * Cols)
Row = 0
FOR Count = 0 TO Points - 1
    Col = Col - 1
    IF Col <= 0 THEN
        Col = Cols
        IF Count > 0 THEN
            Row = Row + 1
            Top = Top + RowSep
        END IF
        IF Row < RowMod THEN Col = Col + 1
        Left = (ScreenWidth - (Col * ColSep)) \ 2
    END IF
    IF Top >= 0 AND Top < ScreenHeight AND Left >= 0 AND Left < ScreenWidth THEN
        LOCATE Top + 1, Left + 1
        PRINT "*";
        Left = Left + ColSep
    END IF
NEXT

RETURN

