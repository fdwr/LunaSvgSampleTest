DEFINT A-Z
DECLARE SUB DrawLeaf (Leafs AS ANY, LeafColor, NewRow, NewCol)
DECLARE SUB NewShoot (Leafs() AS ANY, GrowthLoop, LastLeaf, NewRow, NewCol)

SCREEN 7

'Define the plant
TYPE Leaf
Row AS INTEGER
Col AS INTEGER
Dir AS STRING * 1
END TYPE
REDIM Leafs(0 TO 255) AS Leaf
RANDOMIZE TIMER

'Make the bush position
DO
 Row = INT(RND * 200): Col = INT(RND * 320)
 Leafs(0).Row = Row: Leafs(0).Col = Col
 DO: Dir = INT(RND * 9) + 1: LOOP UNTIL Dir <> 5
 Leafs(0).Dir = LTRIM$(STR$(Dir)): LeafColor = INT(RND * 6) + 9
 LastGen = INT(RND * 7): LastLeaf = 0
 GOSUB MakeBush

 Leafs(0).Row = Row: Leafs(0).Col = Col: Leafs(0).Dir = LTRIM$(STR$(Dir))
 LeafColor = LeafColor - 8: LastLeaf = 0
 GOSUB MakeBush
LOOP UNTIL INKEY$ > ""

'End it all
SCREEN 0: WIDTH 80, 25: COLOR 7, 0: CLS
END

MakeBush:
FOR GenLoop = 0 TO LastGen
 FOR GrowthLoop = 0 TO LastLeaf
  DrawLeaf Leafs(GrowthLoop), LeafColor, NewRow, NewCol
  NewShoot Leafs(), GrowthLoop, LastLeaf, NewRow, NewCol
 NEXT GrowthLoop
NEXT GenLoop
RETURN

SUB DrawLeaf (Leafs AS Leaf, LeafColor, NewRow, NewCol)
Row = Leafs.Row: Col = Leafs.Col
SELECT CASE Leafs.Dir
CASE "8": NewRow = Row - 10: NewCol = Col
CASE "9": NewRow = Row - 10: NewCol = Col + 10
CASE "6": NewRow = Row: NewCol = Col + 10
CASE "3": NewRow = Row + 10: NewCol = Col + 10
CASE "2": NewRow = Row + 10: NewCol = Col
CASE "1": NewRow = Row + 10: NewCol = Col - 10
CASE "4": NewRow = Row: NewCol = Col - 10
CASE "7": NewRow = Row - 10: NewCol = Col - 10
END SELECT
LINE (Col, Row)-(NewCol, NewRow), LeafColor
END SUB

SUB NewShoot (Leafs() AS Leaf, GrowLeaf, LastLeaf, NewRow, NewCol)
SELECT CASE Leafs(GrowLeaf).Dir
CASE "8": Dir1$ = "7": Dir2$ = "9"
CASE "9": Dir1$ = "8": Dir2$ = "6"
CASE "6": Dir1$ = "9": Dir2$ = "3"
CASE "3": Dir1$ = "6": Dir2$ = "2"
CASE "2": Dir1$ = "1": Dir2$ = "3"
CASE "1": Dir1$ = "4": Dir2$ = "2"
CASE "4": Dir1$ = "1": Dir2$ = "7"
CASE "7": Dir1$ = "4": Dir2$ = "8"
END SELECT
IF LastLeaf < 255 THEN LastLeaf = LastLeaf + 1: Leafs(LastLeaf).Row = NewRow: Leafs(LastLeaf).Col = NewCol: Leafs(LastLeaf).Dir = Dir2$
Leafs(GrowLeaf).Row = NewRow: Leafs(GrowLeaf).Col = NewCol: Leafs(GrowLeaf).Dir = Dir1$
END SUB

