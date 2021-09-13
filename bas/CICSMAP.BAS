'2001.4.5 x10
DEFINT A-Z
DECLARE SUB MouseFunction (Ax%)
DECLARE FUNCTION MouseInfo% ()
DECLARE FUNCTION StrTrim$ (Value%)

CONST MaxMapItems = 500, MapWidth = 80, MapHeight = 24
CONST MaxTextRows = MaxMapItems * 4 - 1
CONST MaxMenuChoices = 23
CONST True = -1, False = 0

TYPE MapItemType
Kind AS INTEGER     'either field, mapset def, or comment
Map AS INTEGER      'the map which this item belongs to
Top AS INTEGER      'top row, zero based because the math is so much simpler!
Left AS INTEGER     'left column
Wdth AS INTEGER     'field width
Atrb AS INTEGER     'attributes
HlAtrb AS INTEGER   'highlight attributes
Clr AS INTEGER      'field color
Flags AS INTEGER    'misc. flags
TxtIdx AS INTEGER   'index of item's text (so that the whole string array does not need to be shifted when items are inserted/deleted)
END TYPE

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Fl AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

DIM MapItems(MaxMapItems - 1) AS MapItemType
DIM MapItemsText(MaxMapItems - 1) AS STRING 'used only in map edit mode, otherwise blank
DIM MapItemsLbl(MaxMapItems - 1)  AS STRING
DIM MapText(MaxTextRows) AS STRING  'used only in text edit mode, otherwise blank
DIM SkippableChars(255)

DIM MapsetFile AS STRING, Text AS STRING, TextLine AS STRING

DIM SHARED Regs AS RegisterType, LongFileNames
DIM SHARED MousePresent, MouseRow, MouseCol, MouseButtons, MousePresses, MouseReleases, MouseChange, ClickTime!

DIM SHARED MenuChoices(MaxMenuChoices)
DIM StatBarPos(10, 1)

'Field attributes
CONST MiaUnderline = 1
'Map Item Kinds
CONST MikField = 0, MikMap = 1, MikSet = 2
'Map Item Flags
CONST MifRedraw = 1, MifSelected = 2, MifChanged = 3

RESTORE SkippableCharsData
DO
    READ Value
    SkippableChars(Value) = -1
LOOP UNTIL Value >= 255

SCREEN 0: COLOR 7, 0: CLS
MouseFunction &H21  'reset mouse driver
MouseFunction &H1   'show mouse

GOSUB LoadMapset
GOSUB SelectFirstField
'GOSUB FlagRedrawMap
'GOSUB RedrawMap
'GOSUB RedrawStatusBar
GOSUB EditMapText
END

QkTest:
    DO
        SELECT CASE INKEY$
        CASE CHR$(0) + "H": RowAdjust = -1: ColAdjust = 0:  GOSUB MoveFields
        CASE CHR$(0) + "P": RowAdjust = 1:  ColAdjust = 0:  GOSUB MoveFields
        CASE CHR$(0) + "K": RowAdjust = 0:  ColAdjust = -1: GOSUB MoveFields
        CASE CHR$(0) + "M": RowAdjust = 0:  ColAdjust = 1:  GOSUB MoveFields
        CASE CHR$(27): EXIT DO
        END SELECT

        IF RedrawNeeded THEN GOSUB RedrawMap
    LOOP
RETURN

'edits the mapset grip more intuitively with the mouse
EditMapGrid:
    DO
        ' select key input
        ' case up/down/left/right, move all selected items
        ' case delete, delete all selected items
        ' case insert, copy all selected items
        ' case F1, display help
        ' case F2, goto item with name
        ' case F3, find/goto item with name
        ' end select
        Key$ = INKEY$
        SELECT CASE Key$
        CASE CHR$(0) + "H": RowAdjust = -1: ColAdjust = 0:  GOSUB MoveFields
        CASE CHR$(0) + "P": RowAdjust = 1:  ColAdjust = 0:  GOSUB MoveFields
        CASE CHR$(0) + "K": RowAdjust = 0:  ColAdjust = -1: GOSUB MoveFields
        CASE CHR$(0) + "M": RowAdjust = 0:  ColAdjust = 1:  GOSUB MoveFields
        CASE CHR$(0) + "G": RowAdjust = 0:  ColAdjust = -1: GOSUB MoveFieldsToSide
        CASE CHR$(0) + "O": RowAdjust = 0:  ColAdjust = 1:  GOSUB MoveFieldsToSide
        CASE CHR$(0) + "I": RowAdjust = -1: ColAdjust = 0:  GOSUB MoveFieldsToSide
        CASE CHR$(0) + "Q": RowAdjust = 1:  ColAdjust = 0:  GOSUB MoveFieldsToSide
        'CASE CHR$(0) + "s"
        'CASE CHR$(0) + "t"
        CASE CHR$(9): GOSUB SelectNextItem
        CASE CHR$(0) + CHR$(15): GOSUB SelectPrevItem
        CASE CHR$(0) + "R": GOSUB InsertFields
        CASE CHR$(0) + "S": GOSUB DeleteFields
        CASE CHR$(1) 'cheap
            IF SelectedMapItem >= 0 THEN
                MapItem = SelectedMapItem
                GOSUB FlagRedrawFieldBg
                MapItems(SelectedMapItem).Wdth = LEN(MapItemsLbl(MapItems(SelectedMapItem).TxtIdx))
            END IF
        CASE CHR$(3) 'cheap
            IF SelectedMapItem >= 0 THEN
                MapItems(SelectedMapItem).Clr = (MapItems(SelectedMapItem).Clr + 1 AND 7) + 8
                MapItem = SelectedMapItem
                GOSUB FlagRedrawField
            END IF
        CASE CHR$(19) 'cheap
            GOSUB SaveMapset
        CASE CHR$(26) 'cheap
            GOSUB OrderFieldsRightDown
        CASE CHR$(20)
            GOTO EditMapText
        CASE CHR$(127)
            IF SelectedMapItem >= 0 THEN
                MapItemsLbl(MapItems(SelectedMapItem).TxtIdx) = ""
                MapItem = SelectedMapItem
                GOSUB FlagRedrawField
            END IF
        CASE " " TO "~", CHR$(8)
            IF SelectedMapItem >= 0 THEN
                Idx = MapItems(SelectedMapItem).TxtIdx
                Text = MapItemsLbl(Idx)
                Count = LEN(Text)
                IF Key$ = CHR$(8) THEN 'backspace, delete last character
                    IF Count > 0 THEN Text = LEFT$(Text, Count - 1)
                ELSE
                    IF Count <= 0 AND Key$ <> "_" THEN MapItems(SelectedMapItem).Clr = 10
                    IF Count < MapWidth - 1 THEN 'increase field's width
                        Text = Text + Key$
                        IF Count >= MapItems(SelectedMapItem).Wdth THEN MapItems(SelectedMapItem).Wdth = Count + 1
                    END IF
                END IF
                MapItemsLbl(Idx) = Text
                MapItem = SelectedMapItem
                GOSUB FlagRedrawField
            END IF
        CASE CHR$(27): EXIT DO
        CASE ELSE
            'the redraw is put in here so that it never falls behind the
            'keyboard repeat rate, just in case you are moving around a whole
            'screenfull of fields
            IF RedrawNeeded THEN
                GOSUB RedrawMap
            END IF
        END SELECT

        Regs.Ax = &H200 'get shift status
        CALL InterruptX(&H16, Regs, Regs)
        Shift = (Regs.Ax AND 3) > 0 'used for selecting multiple fields

        'cheap
        LOCATE 25, 1: COLOR 14: PRINT MouseRow + 1; MouseCol + 1; SelectedMapItem;

        ' if mouse move or button
        '   if cursor over status bar
        '     determine which element it is over
        '     if left click over item, open menu
        '   else
        '     determine field action
        '   endif
        ' endif
        IF MouseInfo THEN
            IF MouseRow < 24 THEN 'over mapset
                GOSUB MapMouseInput
            ELSE 'over status bar
                
            END IF

        END IF
    LOOP
RETURN

MapMouseInput:
    ' get item that cursor is currently over
    FOR Count = TotalMapItems - 1 TO 0 STEP -1
        IF MapItems(Count).Map = CurrentMap THEN
            IF MapItems(Count).Kind = MikField THEN
                IF MouseRow = MapItems(Count).Top THEN
                    Left = MapItems(Count).Left
                    Col = Left + MapItems(Count).Wdth
                    IF MouseCol >= Left THEN
                        IF MouseCol <= Col THEN EXIT FOR
                    END IF
                END IF
            END IF
        END IF
    NEXT
    MapItem = Count
    'Count is now either the item which the mouse cursor is over, or Count is
    'invalid, being < 0

    IF MousePresses THEN 'if new button press
        ' if left or right press over item
        '   if shift (call interruptx 16h ah=2)
        '     add item to selection
        '   else (no shift)
        '     select that item only (deselecting any others)
        '     if right button
        '       open menu
        '     endif
        '   endif
        ' else 'over blank area
        '   if left press and not shift
        '     deselect all
        '   else
        '     open menu
        '   endif
        ' endif
        IF (MousePresses AND 1) AND ClickTime! < .219 THEN
            IF Shift THEN 'select all
                FOR Count = 0 TO TotalMapItems - 1
                    IF MapItems(Count).Map = CurrentMap THEN
                        IF MapItems(Count).Kind = MikField THEN
                            MapItems(Count).Flags = MapItems(Count).Flags OR MifSelected OR MifRedraw
                            RedrawNeeded = True
                        END IF
                    END IF
                NEXT
                GOSUB GrabFields
            ELSE 'create field at mouse position
                IF Count >= 0 THEN 'movement was over item
                    GOSUB InsertFields
                    'GOSUB GrabFields
                ELSE
                    Top = MouseRow
                    Left = MouseCol - 1
                    IF Left < 0 THEN Left = 0
                    GOSUB AddGenericMapItem
                    GOSUB GrabFields
                    GOSUB SelectSingleItem
                END IF
            END IF
        ELSEIF Count >= 0 THEN 'press was over item
            Flags = MapItems(Count).Flags
            IF Shift THEN 'enable or drag select or deselect
                IF (Flags AND MifSelected) = 0 THEN
                    GOSUB GrabField
                    MapDragMode = 2
                ELSE
                    MapDragMode = 3
                END IF
                GOSUB SelectToggleItem
            ELSE 'simply grab the field for moving
                GOSUB GrabField
                IF (Flags AND MifSelected) = 0 THEN GOSUB SelectSingleItem
            END IF
            IF MousePresses AND 2 THEN GOSUB OpenFieldMenu 'right button
        ELSE 'press was over blank space
            IF MousePresses AND 1 THEN
                IF NOT Shift THEN 'select none
                    SelectedMapItem = -1
                    GOSUB SelectSingleItem
                END IF
                MapDragMode = 2 'enable drag selection
            ELSE 'right button, so open menu
                GOSUB OpenFieldMenu
            END IF
        END IF
    ELSEIF MapDragMode THEN
        IF MouseButtons AND 1 THEN 'if button still down from previous press
            IF MouseChange AND 1 THEN 'if mouse moved
                IF MapDragMode = 1 THEN 'drag move
                    RowAdjust = MouseRow - GrabRow: GrabRow = MouseRow
                    ColAdjust = MouseCol - GrabCol: GrabCol = MouseCol
                    GOSUB MoveFields
                ELSE 'IF MapDragMode = 2 OR MapDragMode = 3 THEN 'drag selecting
                    IF Count >= 0 THEN 'movement was over item
                        IF MapDragMode = 2 THEN
                            SelectedMapItem = Count
                            GOSUB SelectItem
                        ELSE
                            GOSUB DeselectItem
                        END IF
                    END IF
                END IF
            END IF
        ELSE 'no longer held down
            MapDragMode = False
        END IF
    END IF
RETURN

'Called specifically by MapMouseInput
GrabField:
    SelectedMapItem = Count
GrabFields:
    MapDragMode = 1
    GrabRow = MouseRow
    GrabCol = MouseCol
RETURN

OpenFieldMenu:
' in menu:
' select key input
' case up/down, set choice
' case home/end, set choice
' case A-Z, set choice
' case, return
' end select
' if mouse move, set choice under cursor
' if click and outside menu, return
' if mouse release and choice different than original choice, return

    'SOUND 1024, .23
RETURN

'edits the mapset text as read in from the file, cryptic commands and all
EditMapText:
    CLS
    RedrawNeeded = -1
    IF MapTextRow > MapTextRows THEN MapTextRow = MapTextRows
    TextLine = MapText(MapTextRow)
    MapSelRow = MapTextRow
    MapSelCol = MapTextCol
    GOSUB GetSelectionRange
    DO
        Regs.Ax = &H200 'get shift status
        CALL InterruptX(&H16, Regs, Regs)
        Shift = (Regs.Ax AND 3) > 0 'used for selecting multiple fields
       
        Key$ = INKEY$
        SELECT CASE Key$
        CASE CHR$(0) + "H": Row = MapTextRow - 1: GOSUB MoveTextRow
        CASE CHR$(0) + "P": Row = MapTextRow + 1: GOSUB MoveTextRow
        CASE CHR$(0) + "K": Col = MapTextCol - 1: GOSUB MoveTextCol
        CASE CHR$(0) + "M": Col = MapTextCol + 1: GOSUB MoveTextCol
        CASE CHR$(0) + "I": Row = MapTextPage - 24: GOSUB MoveTextPage
        CASE CHR$(0) + "Q": Row = MapTextPage + 24: GOSUB MoveTextPage
        CASE CHR$(0) + "w": Row = 0: GOSUB MoveTextRow
        CASE CHR$(0) + "u": Row = MapTextRows: GOSUB MoveTextRow
        CASE CHR$(0) + "G"
            FOR Col = 1 TO LEN(TextLine)
                IF MID$(TextLine, Col, 1) <> " " THEN EXIT FOR
            NEXT
            Col = Col - 1
            IF Col = MapTextCol THEN Col = 0
            GOSUB MoveTextCol
        CASE CHR$(0) + "O"
            Col = LEN(RTRIM$(LEFT$(TextLine, 71)))
            IF Col = MapTextCol THEN Col = 71
            GOSUB MoveTextCol
        CASE CHR$(0) + "s"
            GOSUB MovePreviousWord
        CASE CHR$(0) + "t"
            GOSUB MoveNextWord
        CASE CHR$(0) + "S"
            IF Shift THEN GOSUB CopyMapText 'cut, copy before deleting
            GOSUB DeleteMapText
            'ELSE 'delete next character
        CASE " " TO "~"
            'if line is not comment or part of a quote, then capitalize
            AutoCapitalize = True
            IF LEFT$(TextLine, 1) = "*" THEN
                IF TextLine = "**" THEN
                    'TextLine = STRING$(72, 42)
                END IF
                'if third asterisk on line, create an entire row of asterisks
            ELSEIF AutoCapitalize THEN
                Col = INSTR(TextLine, "'")
                IF Col = 0 OR Col > MapTextCol THEN Key$ = UCASE$(Key$)
            END IF
            PRINT Key$;
            MapTextCol = MapTextCol + 1
        CASE CHR$(9) 'tab
            'depending on what column the caret is currently in, tab over to
            'the next area or four spaces over
            IF MapTextCol < 9 THEN Col = 9 ELSE IF MapTextCol < 15 THEN Col = 15 ELSE Col = ((MapTextCol + 1) AND -4) + 3
            GOSUB SubContChar
            TextLine = LEFT$(TextLine, MapTextCol) + SPACE$(Col - MapTextCol) + MID$(TextLine, MapTextCol + 1)
            MapText(MapTextRow) = TextLine
            GOSUB AddContChar
            GOSUB MoveTextCol
        CASE CHR$(13) 'enter
            IF MapTextRows < MaxTextRows THEN
                FOR Row = MapTextRows TO MapTextRow + 1 STEP -1
                    MapText(Row + 1) = MapText(Row)
                NEXT
                MapTextRows = MapTextRows + 1
                GOSUB SubContChar

                'split line where Enter was pressed
                Text = MID$(TextLine, MapTextCol + 1)
                TextLine = LEFT$(TextLine, MapTextCol)
                MapText(MapTextRow) = TextLine
                GOSUB AddContChar

                'split right part down to next line, indenting if necessary
                MapTextRow = MapTextRow + 1
                IF LEN(TextLine) = 72 THEN MapTextCol = 15 ELSE MapTextCol = 0
                TextLine = SPACE$(MapTextCol) + LTRIM$(Text)
                MapText(MapTextRow) = Text
                GOSUB ClearSelectionRange
                GOSUB AddContChar
                RedrawNeeded = RedrawNeeded OR 4
            END IF
        CASE CHR$(20)
            GOTO EditMapGrid
        CASE CHR$(27): EXIT DO
        CASE ELSE
            IF RedrawNeeded THEN GOSUB RedrawText
        END SELECT
    LOOP
RETURN

MoveTextRow:
    IF Row < 0 OR (Row > MapTextRows AND Row > MapTextRow) OR Row = MapTextRow THEN RETURN
    MapTextRow = Row
    IF NOT Shift THEN
        MapSelRow = MapTextRow
        MapSelCol = MapTextCol
    END IF
    TextLine = MapText(MapTextRow)
    RedrawNeeded = RedrawNeeded OR 4
    GOTO GetSelectionRange
'RETURN

MoveTextCol:
    IF Col < 0 OR (Col > 72 AND Col > MapTextCol) OR Col = MapTextCol THEN RETURN
    MapTextCol = Col
    IF NOT Shift THEN
        MapSelRow = MapTextRow
        MapSelCol = MapTextCol
    END IF
    GOSUB GetSelectionRange
    RedrawNeeded = RedrawNeeded OR 4
RETURN

MoveTextPage:
    RedrawNeeded = RedrawNeeded OR 4
RETURN

MoveNextWord:
    Count = LEN(TextLine)
    Row = MapTextRow
    Col = MapTextCol
    SkipMode = -1
    DO
        IF Col >= Count THEN
            IF Row >= MapTextRows THEN EXIT DO
            Row = Row + 1
            Col = 0
            TextLine = MapText(Row)
            Count = LEN(TextLine)
            SkipMode = 0
        ELSE
            Value = ASC(MID$(TextLine, Col + 1, 1))
            IF SkippableChars(Value) THEN
                IF SkipMode THEN SkipMode = 0
            ELSEIF NOT SkipMode THEN
                EXIT DO
            END IF
            Col = Col + 1
        END IF
    LOOP
    GOSUB MoveTextRow
    GOTO MoveTextCol
'RETURN

MovePreviousWord:
    Count = LEN(TextLine)
    Row = MapTextRow
    Col = MapTextCol - 1
    IF Col >= Count THEN Col = Count - 1
    SkipMode = 0
    DO
        IF Col < 0 THEN
            IF Row <= 0 THEN Col = 0: EXIT DO
            Row = Row - 1
            TextLine = MapText(Row)
            Count = LEN(TextLine)
            Col = Count - 1
        ELSE
            Value = ASC(MID$(TextLine, Col + 1, 1))
            IF SkippableChars(Value) THEN
                IF SkipMode THEN Col = Col + 1: EXIT DO
            ELSE
                IF NOT SkipMode THEN
                    SkipMode = -1
                END IF
                IF Col <= 0 THEN EXIT DO
            END IF
            Col = Col - 1
        END IF
    LOOP
    GOSUB MoveTextRow
    GOTO MoveTextCol
'RETURN

GetSelectionRange:
    IF MapSelRow = MapTextRow THEN
        MapSelTop = MapTextRow
        MapSelBtm = MapTextRow
        MapSelLeft = MapSelCol
        MapSelRight = MapTextCol
        IF MapSelRight < MapSelLeft THEN SWAP MapSelRight, MapSelLeft
    ELSE
        MapSelTop = MapTextRow
        MapSelBtm = MapSelRow
        IF MapSelBtm < MapSelTop THEN SWAP MapSelBtm, MapSelTop
        MapSelLeft = MapTextCol
        MapSelRight = MapTextCol
    END IF
    MapSelRows = ABS(MapTextRow - MapSelRow)
RETURN

ClearSelectionRange:
    MapSelRow = MapTextRow
    MapSelCol = MapTextCol
    MapSelTop = MapTextRow
    MapSelBtm = MapTextRow
    MapSelLeft = MapTextCol
    MapSelRight = MapTextCol
RETURN

AddContChar:
    IF LEN(TextLine) < 72 THEN
        IF LEFT$(TextLine, 1) <> "*" THEN
            IF RIGHT$(TextLine, 1) = "," THEN
                TextLine = TextLine + SPACE$(71 - LEN(TextLine)) + "-"
                MapText(MapTextRow) = TextLine
                RedrawNeeded = RedrawNeeded OR 4
            END IF
        END IF
    END IF
RETURN

SubContChar:
    IF LEN(TextLine) = 72 THEN
        IF LEFT$(TextLine, 1) <> "*" THEN
            IF RIGHT$(TextLine, 1) = "-" THEN
                TextLine = RTRIM$(LEFT$(TextLine, 71))
                MapText(MapTextRow) = TextLine
                RedrawNeeded = RedrawNeeded OR 4
            END IF
        END IF
    END IF
RETURN

CopyMapText:
RETURN

DeleteMapText:
    IF MapSelRows THEN
        FOR Row = MapSelTop TO MapTextRows - MapSelRows
            MapText(Row) = MapText(Row + MapSelRows)
        NEXT
        MapTextRows = MapTextRows - MapSelRows
        MapTextRow = MapSelTop
        MapSelRow = MapTextRow
        MapSelCol = MapTextCol
        TextLine = MapText(MapTextRow)
        GOSUB GetSelectionRange
    ELSE
    END IF
    RedrawNeeded = RedrawNeeded OR 4
RETURN

InsertMapText:
RETURN

'displays window that lets you change properties of all selected map items
ChangeProperties:
'
RETURN

RedrawMap:
    ' redraw changed background
    ' for all map items
    '   if item is part of current map and is a field
    '     if redraw or item within redraw area
    '       redraw field at top/left position
    '     endif
    '   endif
    ' next

    'to reduce flicker use two screens. actually, it probably is not
    'necessary since the screen is redrawn with near unoticeable flicker even
    'on my slow 80386.
    MouseFunction &H2 'hide mouse
    PCOPY 0, 1      'copy main screen to secondary screen as buffer
    SCREEN , , 1, 0 'set secondary screen active (while still viewing main)
    IF RedrawBtm >= 0 THEN
        'BgClr = BgClr MOD 6 + 1
        COLOR 11, BgClr
        FOR Row = RedrawTop TO RedrawBtm
            LOCATE Row + 1, RedrawLeft + 1: PRINT SPACE$(RedrawRight - RedrawLeft + 1);
        NEXT
    END IF

    FOR Count = 0 TO TotalMapItems - 1
        IF MapItems(Count).Map = CurrentMap THEN
        IF MapItems(Count).Kind = MikField THEN
            Top = MapItems(Count).Top
            Left = MapItems(Count).Left
            ItemWdth = MapItems(Count).Wdth 'add one for the stupid attribute byte
            Col = Left + ItemWdth
            IF Col >= MapWidth THEN ItemWdth = MapWidth - Left - 1'clip text

            IF MapItems(Count).Flags AND MifRedraw THEN GOTO RedrawItemNow
            IF Top <= RedrawBtm THEN
            IF Top >= RedrawTop THEN
            IF Left <= RedrawRight THEN
            IF Col >= RedrawLeft THEN
RedrawItemNow:
                LOCATE Top + 1, Left + 1
                IF MapItems(Count).Flags AND MifSelected THEN Clr = 7 ELSE Clr = 0
                'IF MapItems(Count).HlAtrb AND MiaUnderline THEN Text = STRING$(ItemWdth, "_") ELSE Text = STRING$(ItemWdth, "ú")
                IF LEN(MapItemsLbl(MapItems(Count).TxtIdx)) <= 0 THEN Text = STRING$(ItemWdth, "X") ELSE Text = STRING$(ItemWdth, "ú")
                COLOR MapItems(Count).Clr, 0
                PRINT "ù";
                COLOR , Clr
                PRINT LEFT$(MapItemsLbl(MapItems(Count).TxtIdx) + Text, ItemWdth);
                MapItems(Count).Flags = MapItems(Count).Flags AND NOT MifRedraw
            END IF
            END IF
            END IF
            END IF
        END IF
        END IF
    NEXT
    SCREEN , , 0, 0     'restore main screen active
    PCOPY 1, 0          'copy secondary screen back to main
    MouseFunction &H1   'show mouse

    RedrawNeeded = 0    'flag no more redraw needed
    RedrawBtm = -32768  'special value to indicate null region
RETURN

RedrawText:
    LOCATE 25, 1, 0
    PRINT MapTextRow; MapTextCol; MapSelRow; MapSelCol; MapSelTop; MapSelBtm;
    'IF RedrawCount < 1 THEN RedrawCount = 1
    'RedrawRow = MapTextRow
    IF RedrawNeeded AND 4 THEN
        Clr = (Clr + 2) MOD 6 + 9
        FOR Count = 0 TO 23
            LOCATE Count + 1, 1
            COLOR 10, 0
            IF Count >= MapTextRows THEN 'print blank line
                PRINT SPACE$(80);
            ELSEIF Count = MapSelRow AND MapSelLeft <> MapSelRight THEN
                Text = MapText(Count)
                PRINT LEFT$(Text, MapSelLeft);
                COLOR 15, 7
                PRINT MID$(Text, MapSelLeft + 1, MapSelRight - MapSelLeft);
                COLOR 10, 0
                IF MapSelRight > LEN(Text) THEN
                    PRINT SPACE$(80 - LEN(Text));
                ELSE
                    PRINT MID$(Text + SPACE$(80), MapSelRight + 1, 80 - MapSelRight);
                END IF
            ELSE
                IF Count >= MapSelTop AND Count < MapSelBtm THEN COLOR 15, 7
                PRINT LEFT$(MapText(Count) + SPACE$(80), 80);
            END IF
        NEXT
        'redraw row
    END IF
    IF RedrawNeeded AND 6 THEN
        Row = MapTextRow - MapTextPage
        IF Row >= 0 AND Row < 24 THEN LOCATE Row + 1, MapTextCol + 1, 1
    END IF
    RedrawNeeded = 0
RETURN

RedrawStatusBar:
    LOCATE 25, 1
    'COLOR 11, 3
    'PRINT "Menu  MAPSET1  TELEPHO  @300  25:12  x48  ..P.A...  ..B.....  Turquoise";
    COLOR 0, 3: PRINT "Ý";
    COLOR 11: PRINT "Menu";
    COLOR 0: PRINT "³";
    COLOR 11: PRINT "MAPSET1";
    COLOR 0: PRINT "³";
    COLOR 11: PRINT "TELEPHO";
    COLOR 0: PRINT "³";
    COLOR 11: PRINT "#300";
    COLOR 0: PRINT "³";
    COLOR 11: PRINT "@23:12";
    COLOR 0: PRINT "³";
    COLOR 11: PRINT "x48";
    COLOR 0: PRINT "³";
    COLOR 11: PRINT "..P.A...";
    COLOR 0: PRINT "³";
    COLOR 11: PRINT "..B.....";
    COLOR 0: PRINT "³";
    COLOR 11: PRINT "Turquoise";
    COLOR 0: PRINT "³";
    COLOR 11: PRINT "11:56";
    DO: LOOP UNTIL LEN(INKEY$)
RETURN

'Redraw entire map
FlagRedrawMap:
    RedrawTop = 0
    RedrawBtm = MapHeight - 1
    RedrawLeft = 0
    RedrawRight = MapWidth - 1
    FOR Count = 0 TO TotalMapItems - 1
        MapItems(Count).Flags = MapItems(Count).Flags OR MifRedraw
    NEXT
    RedrawNeeded = True
RETURN

'Redraw field after drawing background and other items behind it
FlagRedrawFieldBg:
    Top = MapItems(MapItem).Top
    Left = MapItems(MapItem).Left
    Col = Left + MapItems(MapItem).Wdth
    IF Col >= MapWidth THEN Col = MapWidth - 1
    IF RedrawBtm >= 0 THEN
        IF Top < RedrawTop THEN RedrawTop = Top
        IF Top > RedrawBtm THEN RedrawBtm = Top
        IF Left < RedrawLeft THEN RedrawLeft = Left
        IF Col > RedrawRight THEN RedrawRight = Col
    ELSE
        RedrawTop = Top
        RedrawBtm = Top
        RedrawLeft = Left
        RedrawRight = Col
    END IF

'Simply redraw field
FlagRedrawField:
    MapItems(MapItem).Flags = MapItems(MapItem).Flags OR MifRedraw
    RedrawNeeded = True
RETURN

'simply selects a field
'(MapItem)
SelectItem:
    MapItems(MapItem).Flags = (MapItems(MapItem).Flags OR MifSelected) OR MifRedraw
    RedrawNeeded = True
RETURN

'simply selects a field
'(MapItem)
DeselectItem:
    MapItems(MapItem).Flags = (MapItems(MapItem).Flags AND NOT MifSelected) OR MifRedraw
    RedrawNeeded = True
RETURN

'selects the next or previous item, unselecting all others
SelectPrevItem:
    Dir = -1
    GOTO SelectNextPrev
SelectNextItem:
    Dir = 1
SelectNextPrev:
    MapItem = SelectedMapItem + Dir
SelectNextPrevFrom:
    IF MapItem < 0 THEN MapItem = TotalMapItems - 1
    FOR Count = 0 TO TotalMapItems - 1
        IF MapItem >= TotalMapItems THEN MapItem = 0
        IF MapItems(MapItem).Map = CurrentMap THEN
        IF MapItems(MapItem).Kind = MikField THEN
            SelectedMapItem = MapItem
            GOSUB SelectSingleItem
            EXIT FOR
        END IF
        END IF
        MapItem = MapItem + Dir
    NEXT
RETURN

'selects only the specified item, unselecting all others
'(SelectedMapItem)
SelectSingleItem:
    FOR Count = 0 TO TotalMapItems - 1
        Flags = MapItems(Count).Flags
        IF Count = SelectedMapItem THEN
            MapItems(Count).Flags = Flags OR MifSelected OR MifRedraw
            RedrawNeeded = True
        ELSEIF Flags AND MifSelected THEN
            MapItems(Count).Flags = (Flags AND NOT MifSelected) OR MifRedraw
            RedrawNeeded = True
        END IF
    NEXT
RETURN

'either selects or deselects a field, toggling its state each call
'(MapItem)
SelectToggleItem:
    MapItems(MapItem).Flags = (MapItems(MapItem).Flags XOR MifSelected) OR MifRedraw
    RedrawNeeded = True
RETURN

'sets the first field of a map to the current one
SelectFirstField:
    SelectedMapItem = -1
    FOR Count = 0 TO TotalMapItems - 1
        IF MapItems(Count).Map = CurrentMap THEN
        IF MapItems(Count).Kind = MikField THEN
            SelectedMapItem = Count
            EXIT FOR
        END IF
        END IF
    NEXT
RETURN

'Moves all selected fields by a given amount.
'(RowAdjust,ColAdjust)
MoveFields:
    FOR MapItem = 0 TO TotalMapItems - 1
        IF MapItems(MapItem).Flags AND MifSelected THEN
            GOSUB FlagRedrawFieldBg
            MapItems(MapItem).Top = (MapItems(MapItem).Top + RowAdjust + MapHeight) MOD MapHeight
            MapItems(MapItem).Left = (MapItems(MapItem).Left + ColAdjust + MapWidth) MOD MapWidth
            'GOSUB FlagRedrawFieldBg
        END IF
    NEXT
RETURN

'Positions fields to left/right/top/bottom edge of map.
MoveFieldsToSide:
    IF SelectedMapItem < 0 THEN RETURN

    Top = MapItems(SelectedMapItem).Top
    Left = MapItems(SelectedMapItem).Left
    IF RowAdjust < 0 THEN
        RowAdjust = -Top
    ELSEIF RowAdjust > 0 THEN
        RowAdjust = ScreenHeight - Top - 1
    END IF
    IF ColAdjust < 0 THEN
        ColAdjust = -Left
    ELSEIF ColAdjust > 0 THEN
        ColAdjust = ScreenWidth - Left - MapItems(SelectedMapItem).Wdth - 1
    END IF
    GOTO MoveFields
'RETURN

InsertFields:
    FOR Count = 0 TO TotalMapItems - 1
        IF MapItems(Count).Flags AND MifSelected THEN EXIT FOR
    NEXT
    IF Count < TotalMapItems THEN
        FOR Count = Count TO TotalMapItems - 1
            IF MapItems(Count).Flags AND MifSelected THEN GOSUB AddMapItem
        NEXT
    ELSE  'no items selected so add generic field in middle of screen
        Top = 12
        Left = 30
        GOSUB AddGenericMapItem
    END IF
RETURN

'Called specially by InsertFields
'Creates a copy of the selected item, deselecting the source, setting the
'copy's map the current map, setting its text, and counting another item.
'(Count, TotalMapItems)
AddMapItem:
    IF TotalMapItems >= MaxMapItems THEN RETURN
   
    MapItems(TotalMapItems) = MapItems(Count)
    MapItems(Count).Flags = MapItems(Count).Flags AND NOT MifSelected OR MifRedraw
    MapItem = TotalMapItems
    GOSUB FlagRedrawField

    IF MapItems(TotalMapItems).Map = SelectedMap THEN
        Top = MapItems(TotalMapItems).Top + 1
        IF Top < MapHeight THEN MapItems(TotalMapItems).Top = Top
    ELSE
        MapItems(TotalMapItems).Map = SelectedMap
    END IF
   
    FOR NextFreeText = NextFreeText TO MaxMapItems - 1
        IF LEN(MapItemsText(NextFreeText)) = 0 THEN EXIT FOR
    NEXT
    IF NextFreeText >= MaxMapItems THEN NextFreeText = MaxMapItems - 1
    MapItemsText(NextFreeText) = MapItemsText(MapItems(Count).TxtIdx)
    MapItemsLbl(NextFreeText) = MapItemsLbl(MapItems(Count).TxtIdx)
    MapItems(TotalMapItems).TxtIdx = NextFreeText

    IF Count = SelectedMapItem THEN SelectedMapItem = TotalMapItems
   
    TotalMapItems = TotalMapItems + 1
RETURN

'Called by InsertFields and others
'Creates a generic field if no others exist or none are selected.
'(Top, Left; TotalMapItems, SelectedMap)
AddGenericMapItem:
    IF TotalMapItems >= MaxMapItems THEN RETURN
  
    MapItems(TotalMapItems).Flags = MifSelected OR MifRedraw
    MapItems(TotalMapItems).Top = Top
    MapItems(TotalMapItems).Left = Left
    MapItems(TotalMapItems).Wdth = 7
    MapItems(TotalMapItems).Map = SelectedMap
    MapItems(TotalMapItems).Clr = 11
    MapItems(TotalMapItems).Atrb = 0
    MapItems(TotalMapItems).HlAtrb = 0
    FOR NextFreeText = 0 TO MaxMapItems - 1
        IF LEN(MapItemsText(NextFreeText)) = 0 THEN EXIT FOR
    NEXT
    IF NextFreeText >= MaxMapItems THEN NextFreeText = MaxMapItems - 1
    MapItemsText(NextFreeText) = "         DFHMDF"
    MapItemsLbl(NextFreeText) = ""
    MapItems(TotalMapItems).TxtIdx = NextFreeText
    SelectedMapItem = TotalMapItems

    RedrawNeeded = True

    TotalMapItems = TotalMapItems + 1
RETURN

'Deletes all selected fields
DeleteFields:
    FOR MapItem = 0 TO TotalMapItems - 1
        IF MapItems(MapItem).Flags AND MifSelected THEN EXIT FOR
    NEXT
    Count = MapItem
    FOR MapItem = MapItem TO TotalMapItems - 1
        IF MapItems(MapItem).Flags AND MifSelected THEN GOSUB DeleteMapItem ELSE GOSUB ShiftMapItem
    NEXT
    TotalMapItems = Count
   
    'since the selected map item was likely affected
    'in the deletion, seek the next mapset field.
    Dir = 1
    MapItem = SelectedMapItem
    IF MapItem < 0 THEN MapItem = 0
    GOTO SelectNextPrevFrom
'RETURN

'Deletes the current map, meaning all the fields in it
DeleteMap:
    Count = 0
    FOR MapItem = 0 TO TotalMapItems - 1
        IF MapItems(MapItem).Map = CurrentMap THEN GOSUB DeleteMapItem ELSE GOSUB ShiftMapItem
    NEXT
    TotalMapItems = Count

    GOSUB FlagRedrawMap
    GOTO SelectFirstField
'RETURN

'Called specially by DeleteFields and DeleteMap
'(Count)
DeleteMapItem:
    Idx = MapItems(MapItem).TxtIdx
    MapItemsText(Idx) = ""
    MapItemsLbl(Idx) = ""
    NextFreeText = MapItem
    IF MapItem < SelectedMapItem THEN SelectedMapItem = SelectedMapItem - 1
    GOTO FlagRedrawFieldBg
'RETURN

'Called specially by DeleteFields and DeleteMap
'(Count, MapItem)
ShiftMapItem:
    MapItems(Count) = MapItems(MapItem)
    Count = Count + 1
RETURN

'rearranges fields
'!currently will scramble the order of fields and any related comments
OrderFieldsRightDown:
    FOR MapItem = 0 TO TotalMapItems - 2
        LowItem = MapItem
        FOR Count = MapItem + 1 TO TotalMapItems - 1
            IF MapItems(Count).Top <= MapItems(LowItem).Top THEN
                IF MapItems(Count).Top < MapItems(LowItem).Top THEN
                    LowItem = Count
                ELSEIF MapItems(Count).Left <= MapItems(LowItem).Left THEN
                    LowItem = Count
                END IF
            END IF
        NEXT
        IF LowItem <> MapItem THEN SWAP MapItems(LowItem), MapItems(MapItem)
    NEXT
RETURN

'parses the text in a mapset into individual screen items
ParseMapset:
' zero map items
' for text lines
'   if "*" in column 1, then treat as comment
'   if unrecognized field, treat as comment
'   if any characters present in first 8 characters, always new line
'   if continuation "-" in column 72, then same line (add comma if missing)
'   if ending comma, then same line (add continuation character if missing)
'   if new line
'     output previous line
'     increment map items
'     if type is comment
'       append current to previous line separated with a line feed
'     elseif field
'       set default parameters of field
'       if map start
'         increment maps total
'       endif
'       interpret field
'     endif
'   else
'     if type is comment
'       append current to previous line separated with a line feed
'     elseif field
'       interpret field
'     endif
' endfor
' if any previous line
'   output previous line
'   increment map items
' endif

' interpret field attributes and their paremeters
' strip continuation character if any
' strip right spaces
' search for missing parenthesis or quotes
' if appending
'   strip left spaces
'   if no ending comma on previous line, add one
'   concatenate current line with previous line
' else
'   previous line = current line
' endif

'NextFreeText=
RETURN

'formats the individual screen items back into cryptic mapset text commands
FormatMapset:
' zero text lines
' order all mapset items so fields of a certain map are all grouped together
' for all map items
'   if map item is field or map start
'       if field has changed in any way
'         for all attibutes, set correct parameters (POS= COLOR= INITIAL=...)
'       endif
'       do until end of text line
'           search for ending comma of first attribute
'           output line
'       loop
'   else
'       do until end of text line
'           search for line feed
'           output line
'       loop
'   endif
' endfor
RETURN

'simply reads the mapset in line by line
'does not do any parsing, so it must be parsed after calling
LoadMapset:
'restore MapsetData
    TotalMapItems = 0
    READ Map
    DO
        MapItems(TotalMapItems).Kind = 0 'field
        MapItems(TotalMapItems).Map = Map
        READ MapItems(TotalMapItems).Top, MapItems(TotalMapItems).Left, MapItems(TotalMapItems).Wdth, MapItems(TotalMapItems).Clr, MapItemsLbl(TotalMapItems)
        MapItemsText(TotalMapItems) = "         DFHMDF"
        MapItems(TotalMapItems).Atrb = 0
        MapItems(TotalMapItems).HlAtrb = 0
        MapItems(TotalMapItems).Flags = 0
        MapItems(TotalMapItems).TxtIdx = TotalMapItems
        TotalMapItems = TotalMapItems + 1
        READ Map
    LOOP UNTIL Map < 0
    NextFreeText = TotalMapItems
    MapItems(5).Flags = MifSelected
    MapItems(7).Flags = MifSelected

    MapTextRows = 0
    READ Text
    DO WHILE LEN(Text)
        MapText(MapTextRows) = Text
        MapTextRows = MapTextRows + 1
        READ Text
    LOOP
RETURN
    TotalMapItems = 0
    DO UNTIL EOF(1) OR TotalMapItems >= MaxMapItems
        LINE INPUT #1, MapText(TotalMapItems)
        TotalMapItems = TotalMapItems + 1
    LOOP
RETURN

'simply writes the mapset out line by line
'does not do any formatting, so it must be formatted before calling
SaveMapset:
    MapsetFile = "out.txt"
    OPEN MapsetFile FOR OUTPUT AS 1

    PRINT #1, "* Dwayne Robinson"
    PRINT #1, "* CICS - David Gentry"
    PRINT #1, "* Program # Map"
    PRINT #1, "* 2001.#.#"
    PRINT #1, "*"
    PRINT #1, "         PRINT NOGEN"
    PRINT #1, "VIDS3D   DFHMSD TYPE=&SYSPARM,                                         -"
    PRINT #1, "               LANG=COBOL,                                             -"
    PRINT #1, "               MODE=INOUT,                                             -"
    PRINT #1, "               TERM=3270-2,                                            -"
    PRINT #1, "               CTRL=FREEKB,                                            -"
    PRINT #1, "               STORAGE=AUTO,                                           -"
    PRINT #1, "               DSATTS=(COLOR,HILIGHT),                                 -"
    PRINT #1, "               MAPATTS=(COLOR,HILIGHT),                                -"
    PRINT #1, "               TIOAPFX=YES"
    PRINT #1, STRING$(71, 42)
    PRINT #1, "VIDS3M1  DFHMDI SIZE=(24,80),                                          -"
    PRINT #1, "               LINE=1,                                                 -"
    PRINT #1, "               COLUMN=1"
    PRINT #1, STRING$(71, 42)

    FOR Count = 0 TO TotalMapItems - 1
        PRINT #1, "         DFHMDF POS=(" + StrTrim$(MapItems(Count).Top + 1) + "," + StrTrim$(MapItems(Count).Left + 1) + "),"
        PRINT #1, "               LENGTH=" + StrTrim$(MapItems(Count).Wdth) + ","
        'PRINT #1, "               ATTRB=(),"
        'PRINT #1, "               HILIGHT=(),"
        SELECT CASE MapItems(Count).Clr
        CASE 9: Text = "BLUE"
        CASE 10: Text = "GREEN"
        CASE 11: Text = "TURQUOISE"
        CASE 12: Text = "RED"
        CASE 13: Text = "PINK"
        CASE 14: Text = "YELLOW"
        CASE 15: Text = "WHITE"
        CASE ELSE: Text = ""
        END SELECT
        IF LEN(Text) THEN PRINT #1, "               COLOR=" + Text + ","
        Text = MapItemsLbl(MapItems(Count).TxtIdx)
        IF LEN(Text) THEN PRINT #1, "               INITIAL='" + Text + "'"
    NEXT

    PRINT #1, "DUMMY    DFHMDF POS=(24,79),                                           -"
    PRINT #1, "               LENGTH=1,                                               -"
    PRINT #1, "               ATTRB=(DRK,PROT,FSET),                                  -"
    PRINT #1, "               COLOR=YELLOW"
    PRINT #1, STRING$(71, 42)
    PRINT #1, "         DFHMSD TYPE=FINAL"
    PRINT #1, "         END"

    CLOSE 1
RETURN
    OPEN MapsetFile FOR OUTPUT AS 1
    FOR MapItem = 0 TO TotalMapItems - 1
        PRINT #1, MapText(MapItem)
    NEXT
    CLOSE 1
RETURN

SkippableCharsData:
DATA 9,32,39,40,42,41,44,45,61,255

MapsetData:
DATA 0,0,0,12,15,"Upper left"
DATA 0,23,0,12,15,"Lower left"
DATA 0,0,68,12,15,"Upper right"
DATA 0,23,68,12,15,"Lower right"
DATA 0,14,5,12,15,"Unselected"
DATA 0,15,5,12,15,"Selected"
DATA 0,4,10,12,12,"Red"
DATA 0,5,11,12,13,"Pink"
DATA 0,6,12,12,9,"Blue"
DATA 0,7,13,12,11,"Turquoise"
DATA 0,8,14,12,10,"Green"
DATA 0,9,15,12,14,"Yellow"
DATA 0,10,16,12,15,"White"
DATA 0,20,69,20,11,"Text clipped"
DATA -1

DATA "* Cics Mapper"
DATA "* 2001.4.1"
DATA "         DFHMSD"
DATA "         DFHMDI"
DATA "         DFHMFD POS=(1,2),                                             -"
DATA "               ATTRB=ASKIP,                                            -"
DATA "               INITIAL='Dwayne Robinson'"
DATA "DUMMY    DFHMDF POS=(24,79),                                           -"
DATA "               LENGTH=1,                                               -"
DATA "               (no continuation character on line),"
DATA "               ATTRB=(DRK,PROT,FSET),                                  -"
DATA "               COLOR=YELLOW"
DATA

'do:key$ = inkey$:for count = 1 to len(key$):print asc(mid$(key$,count,1));mid$(key$,count,1);:next count:loop until key$ = chr$(27)

SUB MouseFunction (Ax)

Regs.Ax = Ax
IF MousePresent THEN
  CALL InterruptX(&H33, Regs, Regs)
ELSEIF Ax = 0 OR Ax = &H21 THEN
  CALL InterruptX(&H33, Regs, Regs)
  IF Regs.Ax = True THEN MousePresent = True
END IF

END SUB

' Returns:
'   0 - no change
'   1 - cursor movement
'   2 - button release
'   4 - button press
FUNCTION MouseInfo

STATIC OldRow, OldCol, OldButtons, OldTime!

IF NOT MousePresent THEN EXIT FUNCTION

Regs.Ax = 3
CALL InterruptX(&H33, Regs, Regs)
MouseButtons = Regs.Bx
MouseRow = Regs.Dx \ 8
MouseCol = Regs.Cx \ 8
MouseChange = 0 'assume no change

IF MouseRow <> OldRow OR MouseCol <> OldCol THEN
    OldRow = MouseRow
    OldCol = MouseCol
    MouseChange = 1
END IF

MouseReleases = OldButtons AND NOT MouseButtons
IF MouseReleases THEN MouseChange = MouseChange OR 2
MousePresses = MouseButtons AND NOT OldButtons
IF MousePresses THEN
    MouseChange = MouseChange OR 4
    IF MousePresses AND 1 THEN
        ClickTime! = TIMER - OldTime!
        OldTime! = OldTime! + ClickTime!
    END IF
END IF
OldButtons = MouseButtons

MouseInfo = MouseChange

END FUNCTION

FUNCTION StrTrim$ (Value)
StrTrim = LTRIM$(STR$(Value))
END FUNCTION

