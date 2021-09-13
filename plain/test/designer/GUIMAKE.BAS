'2000-06-14
'2002-01-20
DEFINT A-Z
DECLARE SUB Button.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB Select.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB Label.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB TextPrompt.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB ScrollBar.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB TextList.Draw (Obj AS ANY, Gui AS ANY, Choices() AS STRING)
DECLARE SUB TitleBar.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB Picture.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB GuiBorder.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB ExpandTab.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB Bubble.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB Bubble2.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB Color.Draw (Obj AS ANY, Gui AS ANY)
DECLARE SUB Scale.Draw (Gui AS ANY)
DECLARE SUB AtrList.Draw (Gui AS ANY)
DECLARE SUB AtrItem.Draw (Text AS STRING, Gui AS ANY)
DECLARE SUB BarItem.Draw (Text AS STRING, Gui AS ANY)
DECLARE SUB WindowBg.Draw (Obj AS ANY, Gui AS ANY)

DECLARE SUB AddToRedrawRegion (Top%, Left%, Btm%, Right%)
DECLARE SUB DrawTiles (ImgSrc%(), ImgHite%, ImgWdth%, Top%, Left%, Hite%, Wdth%)
DECLARE SUB DrawChar (Char%, Top%, Left%, Clr%)
DECLARE SUB DrawCharV (Char%, Top%, Left%, Clr%)
DECLARE SUB DrawCharString (Text AS STRING, Top%, Left%, Clr%)
DECLARE SUB DrawCharStringV (Text AS STRING, Top%, Left%, Clr%)
DECLARE FUNCTION TextWidth% (Text AS STRING)
DECLARE FUNCTION TextWidthLen% (Text AS STRING, Wdth%)

DECLARE SUB MouseFunction (Ax%)
DECLARE FUNCTION StrNum$ (Num AS INTEGER)
DECLARE SUB ConcatString (FirstString AS STRING, SecondString AS STRING)
DECLARE SUB ConcatDataBytes (DestString AS STRING, SrcString AS STRING, Dif AS INTEGER)
DECLARE SUB UserWait ()
DECLARE FUNCTION GetFileList$ (FileMask$, FileType%)
DECLARE FUNCTION WaitWithMsg$ (Text AS STRING)

TYPE GuiType
TopRow  AS INTEGER
LeftCol AS INTEGER
Hite    AS INTEGER
Wdth    AS INTEGER
Flags   AS LONG
END TYPE

TYPE ButtonType
State AS INTEGER
Text  AS STRING * 20
END TYPE

TYPE LabelType
Text  AS STRING * 400
Align AS INTEGER
END TYPE

TYPE TextPromptType
Text   AS STRING * 64
CsrPos AS INTEGER
END TYPE

TYPE ScrollBarType
Mode  AS INTEGER
Total AS INTEGER
Value AS INTEGER
END TYPE

TYPE TextListType
Choices   AS INTEGER
CurChoice AS INTEGER
END TYPE

TYPE SelectType
State AS INTEGER
Index AS INTEGER
Text  AS STRING * 20
END TYPE


CONST MaxObjects = 80
CONST MaxObjectTypes = 30
CONST GuiObjectDefTypes = 24
CONST GuiColorDrk = 0
CONST GuiColorDim = 1
CONST GuiColorGray = 2
CONST GuiColorLit = 3 'lighter than back
CONST GuiColorBrt = 4 'even brighter shade
CONST GuiColorWht = 5 'brightest
CONST GuiColorTop = GuiColorBrt
CONST GuiColorLeft = GuiColorLit
CONST GuiColorBack = GuiColorGray
CONST GuiColorRight = GuiColorDim
CONST GuiColorBtm = GuiColorDrk
CONST GuiObjActive = 1
CONST GuiObjRedraw = 32768
CONST GuiObjSelected = 65536
CONST GuiObjTemplate = 131072
CONST TextColorNormal = &H304
CONST TextColorActive = &H405
CONST TextColorInfo = &H305
CONST TextColorSelect = &H607
CONST TextColorLit = &H204
CONST TextColorDrk = &H203

CONST ScreenWidth = 320
CONST ScreenHeight = 200
CONST ScreenBtmRow = 25
CONST ScreenFontHeight = 16
CONST BmpBufferSize = 4000
CONST MaxFiles = 150

CONST FileDlgLoad = 0
CONST FileDlgMerge = 1
CONST FileDlgSave = 2
CONST FileDlgRename = 3

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE


DIM TestObject AS GuiType, TestButton AS ButtonType, TestPrompt AS TextPromptType
DIM TestScrollBar AS ScrollBarType, TestTextList AS TextListType, TestChoices(10) AS STRING
DIM TestTitleBar AS TextPromptType, TestSelect AS SelectType, TestLabel AS LabelType
DIM TxtDlgPrompt AS TextPromptType, TxtDlgBar AS TextPromptType, TxtDlgButton AS ButtonType
DIM GolFilename  AS STRING, Text AS STRING, TrailingText AS STRING

DIM ObjectList(MaxObjects) AS GuiType, ObjectTypeList(MaxObjects)
DIM ObjectNameList(MaxObjects) AS STRING, ObjectTextList(MaxObjects) AS STRING
DIM ObjectTypeNames(MaxObjectTypes) AS STRING, ObjectTypeUsesText(MaxObjectTypes)
DIM ObjectTypeIsItem(MaxObjectTypes)
DIM ObjectCmpSrcTbl(MaxObjectTypes), CompileString AS STRING
DIM ObjectCmpNames(MaxObjectTypes * 2) AS STRING, ObjectCmpSrc(MaxObjectTypes) AS STRING
DIM Flags AS LONG
DIM SHARED BgTop, BgLeft, BgBtm, BgRight, BgRedraw, TestImage(63), InfoRow
DIM SHARED Regs AS RegisterType, FilErr, MousePresent, MouseRow, MouseCol
DIM SHARED FontChars(1791), FontSizes(255), HideText
DIM SHARED ShowGuiSelection

Initialize:
SCREEN 13
GOSUB SetPalette
MouseFunction &H21 'software reset
DEF SEG = VARSEG(FontChars(0))
BLOAD "letters.lbm", VARPTR(FontChars(0))
DEF SEG = VARSEG(FontSizes(0))
BLOAD "lettersz.dat", VARPTR(FontSizes(0))
TestImage(0) = -1

FilErr = 0: ON ERROR GOTO FileErrorHandler
OPEN "guicomps.txt" FOR INPUT AS 1
ON ERROR GOTO 0
IF FilErr = 0 THEN
    Count = 0
    ObjType = -1
    DO UNTIL EOF(1)
        LINE INPUT #1, Text
        IF ObjType THEN
            ObjectCmpNames(Count) = Text
            ObjType = 0
        ELSEIF LEN(Text) <= 0 THEN
            Count = Count + 1
            ObjType = -1
        ELSE
            ObjectCmpSrc(Count) = ObjectCmpSrc(Count) + Text + CHR$(13) + CHR$(10)
        END IF
    LOOP
    CLOSE 1
END IF

TotalObjects = 0
TotalObjectTypes = GuiObjectDefTypes
ObjectTypeNames(0) = "titlebar":     ObjectTypeUsesText(0) = -1
ObjectTypeNames(1) = "button":       ObjectTypeUsesText(1) = -1
ObjectTypeNames(2) = "textprompt":   ObjectTypeUsesText(2) = -1
ObjectTypeNames(3) = "select":       ObjectTypeUsesText(3) = -1
ObjectTypeNames(4) = "list":         ObjectTypeUsesText(4) = -1
ObjectTypeNames(5) = "scroll":       ObjectTypeUsesText(5) = -1
ObjectTypeNames(6) = "label":        ObjectTypeUsesText(6) = -1
ObjectTypeNames(7) = "labelr":       ObjectTypeUsesText(7) = -1
ObjectTypeNames(8) = "picture"
ObjectTypeNames(9) = "border"
ObjectTypeNames(10) = "tab":         ObjectTypeUsesText(10) = -1: ObjectTypeIsItem(10) = -1
ObjectTypeNames(11) = "bubble":      ObjectTypeUsesText(11) = -1
ObjectTypeNames(12) = "color"
ObjectTypeNames(13) = "scale"
ObjectTypeNames(14) = "window"
ObjectTypeNames(15) = "windowbg"
ObjectTypeNames(16) = "atrlist"
ObjectTypeNames(17) = "atrlistitem": ObjectTypeUsesText(17) = -1: ObjectTypeIsItem(17) = -1
ObjectTypeNames(18) = "cborder"
ObjectTypeNames(19) = "tabstrip"
ObjectTypeNames(20) = "atrbar"
ObjectTypeNames(21) = "atrbaritem":  ObjectTypeUsesText(21) = -1: ObjectTypeIsItem(21) = -1
ObjectTypeNames(22) = "menu"
ObjectTypeNames(23) = "submenuitem": ObjectTypeUsesText(23) = -1: ObjectTypeIsItem(23) = -1
TestPrompt.CsrPos = LEN(ObjectTypeNames(2))
TestTextList.Choices = 1
TestSelect.State = 1
TestScrollBar.Total = 30
TestScrollBar.Value = 12

DrawClr = GuiColorWht
InfoRow = ScreenBtmRow
OldInfoRow = InfoRow

IF LEN(COMMAND$) THEN
    Text = COMMAND$
    GOSUB LoadObjectsNow
END IF
IF TotalObjects <= 0 THEN
    'GolFilename = "sample.gol"
    RESTORE DefaultDialogData
    DO
        READ ObjType
        IF ObjType < 0 THEN EXIT DO
        ObjectTypeList(TotalObjects) = ObjType
        READ ObjectList(TotalObjects).TopRow, ObjectList(TotalObjects).LeftCol, ObjectList(TotalObjects).Hite, ObjectList(TotalObjects).Wdth, ObjectList(TotalObjects).Flags, ObjectTextList(TotalObjects)
        TotalObjects = TotalObjects + 1
    LOOP
END IF

IF NOT MousePresent THEN
    COLOR GuiColorWht
    PRINT "No mouse driver loaded."
    PRINT "Although the program can still work"
    PRINT "with keys alone, it won't be nearly"
    PRINT "as much fun..."
    UserWait
END IF

GridSize = 4
StepSize = GridSize
ShowGuiSelection = 1
PreSelectedObject = SelectedObject
EditMode = 0
InsertChar = 0
GOSUB FlagRedrawAllObjects
MouseFunction 1
DO
    key$ = INKEY$
    IF (EditMode = 1 OR EditMode = 3) AND LEN(key$) THEN
EditObjectText:
        IF EditMode = 1 THEN
            NewObjectText$ = ObjectTextList(SelectedObject)
        ELSE
            NewObjectText$ = ObjectNameList(SelectedObject)
        END IF
        IF InsertChar OR (key$ >= " " AND key$ <= "ÿ") THEN
InsertCharObjText:
            IF LEN(NewObjectText$) < 128 THEN
                NewObjectText$ = NewObjectText$ + LEFT$(key$, 1)
                BgRedraw = 1
            END IF
            InsertChar = 0
        ELSEIF key$ = CHR$(8) THEN
            IF LEN(NewObjectText$) > 0 THEN
                NewObjectText$ = LEFT$(NewObjectText$, LEN(NewObjectText$) - 1)
                BgRedraw = 2
            END IF
        ELSEIF key$ = CHR$(0) + "R" THEN
            InsertChar = InsertChar XOR -1
        ELSEIF key$ = CHR$(10) THEN
            key$ = CHR$(14)
            GOTO InsertCharObjText
        ELSE
            GOTO DecideKeyPress
        END IF
        'ObjectList(SelectedObject).Flags = GuiObjRedraw
        IF BgRedraw THEN
            IF EditMode = 1 THEN
                ObjectTextList(SelectedObject) = NewObjectText$
            ELSE
                ObjectNameList(SelectedObject) = NewObjectText$
            END IF
        END IF
    ELSE
DecideKeyPress:
        SELECT CASE key$
        CASE CHR$(9): IF TotalObjects > 0 THEN SelectedObject = (SelectedObject + 1) MOD TotalObjects: GOSUB FlagRedrawObject: GOSUB CheckInfoBar
        CASE CHR$(0) + "": IF TotalObjects > 0 THEN SelectedObject = (SelectedObject + TotalObjects - 1) MOD TotalObjects: GOSUB FlagRedrawObject: GOSUB CheckInfoBar
        CASE CHR$(0) + "H": RowChange = -StepSize: ColChange = 0: GOSUB RepositionObject
        CASE CHR$(0) + "P": RowChange = StepSize: ColChange = 0: GOSUB RepositionObject
        CASE CHR$(0) + "K": ColChange = -StepSize: RowChange = 0: GOSUB RepositionObject
        CASE CHR$(0) + "M": ColChange = StepSize: RowChange = 0: GOSUB RepositionObject
        CASE CHR$(0) + "I": SidePosition = 0: GOSUB RepositionToSide
        CASE CHR$(0) + "Q": SidePosition = 1: GOSUB RepositionToSide
        CASE CHR$(0) + "G": SidePosition = 2: GOSUB RepositionToSide
        CASE CHR$(0) + "O": SidePosition = 3: GOSUB RepositionToSide
        CASE "-": RowChange = -StepSize: ColChange = 0: GOSUB ResizeObject
        CASE "+": RowChange = StepSize: ColChange = 0: GOSUB ResizeObject
        CASE "/": ColChange = -StepSize: RowChange = 0: GOSUB ResizeObject
        CASE "*": ColChange = StepSize: RowChange = 0: GOSUB ResizeObject
        CASE CHR$(0) + "R": EditMode = 0: GOSUB CreateObject
        CASE CHR$(0) + "S": EditMode = 0: GOSUB DeleteObject
        CASE CHR$(0) + "s": NewTabIndex = (SelectedObject - 1 + TotalObjects) MOD TotalObjects: GOSUB ChangeTabOrder
        CASE CHR$(0) + "t": NewTabIndex = (SelectedObject + 1) MOD TotalObjects: GOSUB ChangeTabOrder
        CASE "a", "A"
            IF TotalObjects > 0 THEN
                GOSUB AddObjectToRedraw
                IF StepSize <= 1 THEN CountStep = GridSize ELSE CountStep = StepSize
                IF ASC(key$) AND 32 THEN
                    ObjectList(SelectedObject).TopRow = Top - (Top MOD CountStep)
                    ObjectList(SelectedObject).LeftCol = Left - (Left MOD CountStep)
                ELSE
                    Hite = ObjectList(SelectedObject).Hite
                    Wdth = ObjectList(SelectedObject).Wdth
                    ObjectList(SelectedObject).Hite = Hite - (Hite MOD CountStep)
                    ObjectList(SelectedObject).Wdth = Wdth - (Wdth MOD CountStep)
                END IF
                GridOriginRow = 0: GridOriginCol = 0
            END IF
        CASE "g"
            IF StepSize <= 1 THEN StepSize = GridSize ELSE StepSize = 1
            GOSUB ActiveItemInfo
        CASE "G"
            SELECT CASE GridSize
            CASE IS < 8: GridSize = 8
            CASE IS < 10: GridSize = 10
            CASE IS < 16: GridSize = 16
            CASE IS < 20: GridSize = 20
            CASE ELSE: GridSize = 4
            END SELECT
            StepSize = GridSize
            GOSUB ActiveItemInfo
        CASE "e", CHR$(8)
            EditMode = 1
            InsertChar = 0
            BgRedraw = -1
            IF key$ = CHR$(8) GOTO EditObjectText
        CASE "n"
            EditMode = 3
            InsertChar = 0
            BgRedraw = -1
        CASE "E"
            GOSUB EditPicture
            GOSUB FlagRedrawAllObjects
        CASE "o", "O"
            IF TotalObjects > 0 THEN
                GOSUB AddObjectToRedraw
                IF ASC(key$) AND 32 THEN Count = 1 ELSE Count = TotalObjectTypes - 1
                ObjectTypeList(SelectedObject) = (ObjectTypeList(SelectedObject) + Count) MOD TotalObjectTypes
            END IF
        CASE "i"
            GOSUB DisplayGolInfo
            GOSUB FlagRedrawAllObjects
        CASE "t": HideText = HideText XOR 1: GOSUB FlagRedrawAllObjects
        CASE "d": GOSUB ShowSampleScreen: GOSUB RedrawAllObjects
        CASE "s": EditMode = 0: FileDlg = FileDlgSave: GOSUB SaveObjects: GOSUB RedrawAllObjects
        CASE "S": EditMode = 0: FileDlg = FileDlgRename: GOSUB SaveObjects: GOSUB RedrawAllObjects
        CASE CHR$(19): FileDlg = FileDlgSave: GOSUB SaveObjectsNow
        CASE "l": EditMode = 0: FileDlg = FileDlgLoad: GOSUB LoadObjects: GOSUB RedrawAllObjects
        CASE "L": EditMode = 0: FileDlg = FileDlgMerge: GOSUB LoadObjects: GOSUB RedrawAllObjects
        CASE CHR$(12): FileDlg = FileDlgLoad: Text = GolFilename: GOSUB LoadObjectsNow: GOSUB RedrawAllObjects
        CASE "m"
            IF WaitWithMsg$("Press M again to merge objects") = "m" THEN GOSUB MergeObjects
            GOSUB ActiveItemInfo
        CASE "c"
            IF WaitWithMsg$("Press C again to correct objects") = "c" THEN GOSUB CorrectObjects
            GOSUB ActiveItemInfo
        CASE "z": BgRedraw = 1: IF EditMode = 2 THEN EditMode = 0 ELSE EditMode = 2
        CASE "w": GOSUB CompileItems
        CASE "W": GOSUB ExportScreenBitmap
        CASE " ": IF TotalObjects > 0 THEN ObjectList(SelectedObject).Flags = ObjectList(SelectedObject).Flags XOR GuiObjSelected
        CASE "x"
            GOSUB RescaleObjects
        CASE CHR$(0) + ";": GOSUB DisplayHelp: GOSUB RedrawAllObjects
        CASE CHR$(13), CHR$(27)
            IF EditMode THEN
                BgRedraw = 1: EditMode = 0
            ELSEIF key$ = CHR$(13) THEN
                GOSUB TestGuiObjects
            ELSE
                IF WaitWithMsg$("Press Escape again to quit") = CHR$(27) THEN EXIT DO
                GOSUB ActiveItemInfo
            END IF
        CASE ELSE: IF BgRedraw THEN GOSUB RedrawObjects
        END SELECT
    END IF

    MouseFunction 3
    'Regs.Cx = Regs.Cx \ 2  'only for mode 13h
    IF Regs.Dx <> MouseRow OR Regs.Cx <> MouseCol THEN MouseMove = -1 ELSE MouseMove = 0
    MouseButton = Regs.Bx
    MouseRow = Regs.Dx
    MouseCol = Regs.Cx
   
    IF GrabMode THEN
        'if button is released, release object
        IF (MouseButton AND 3) = 0 THEN
            GOSUB ReleaseObject
        ELSEIF MouseMove AND (MouseButton AND 1) THEN
            GOSUB AddObjectToRedraw
            IF GrabMode AND 1 THEN
                ObjectList(SelectedObject).TopRow = ((MouseRow - GrabPosRow) \ StepSize) * StepSize + GridOriginRow
            END IF
            IF GrabMode AND 2 THEN
                ObjectList(SelectedObject).LeftCol = ((MouseCol - GrabPosCol) \ StepSize) * StepSize + GridOriginCol
            END IF
            IF GrabMode AND 4 THEN
                ObjectList(SelectedObject).Hite = ((MouseRow - GrabSizeRow) \ StepSize) * StepSize + GridOriginRow
            END IF
            IF GrabMode AND 8 THEN
                ObjectList(SelectedObject).Wdth = ((MouseCol - GrabSizeCol) \ StepSize) * StepSize + GridOriginCol
            END IF
        END IF
    ELSEIF MouseButton AND 1 THEN
        'if button pressed, grab object
        GOSUB FindGrabbedObject
        IF GrabMode THEN
            GOSUB AddObjectToRedraw
            IF EditMode = 2 THEN
                NewTabIndex = (SelectedObject + 1) MOD TotalObjects
                SelectedObject = Count
                GOSUB ChangeTabOrder
            ELSE
                SelectedObject = Count
                FOR Count = 0 TO TotalObjects - 1
                    IF ObjectList(Count).Flags AND GuiObjSelected THEN
                        GOSUB AddSpecObjectToRedraw
                        ObjectList(Count).Flags = ObjectList(Count).Flags AND NOT GuiObjSelected
                    END IF
                NEXT
            END IF
            GOSUB GrabObject
        END IF
    ELSEIF MouseButton AND 2 THEN
        'find object which mouse was over
        GOSUB FindGrabbedObject
        IF GrabMode THEN
            ObjectList(Count).Flags = ObjectList(Count).Flags XOR GuiObjSelected
            IF ObjectList(Count).Flags AND GuiObjSelected THEN
                SelectedObject = Count
                GOSUB FlagRedrawObject
            ELSE
                RedrawObject = Count
                GOSUB AddSpecObjectToRedraw
            END IF
        END IF
    END IF
    IF MouseMove THEN
        IF InfoRow >= ScreenBtmRow AND MouseRow >= ScreenHeight - 20 THEN
            InfoRow = 1: GOSUB RedrawInfoBarBg
        ELSEIF InfoRow <= 1 AND MouseRow < 20 THEN
            InfoRow = ScreenBtmRow: GOSUB RedrawInfoBarBg
        END IF
        IF BgRedraw = 0 THEN GOSUB ActiveItemInfo
    END IF
LOOP

'Regs.Ax = &H3
'CALL interruptx(&H10, Regs, Regs)
'SCREEN 0 'the SCREEN command produces ANNOYING flicker when exiting program

END

'Returns Count as object found (if GrabMode >= 0)
FindGrabbedObject:
    GrabMode = 0
    FOR Count = TotalObjects - 1 TO 0 STEP -1
        Row = ObjectList(Count).TopRow
        IF MouseRow >= Row THEN
            IF MouseRow < Row + ObjectList(Count).Hite THEN
                Col = ObjectList(Count).LeftCol
                IF MouseCol >= Col THEN
                    IF MouseCol < Col + ObjectList(Count).Wdth THEN
                        GrabMode = 16384
                        EXIT FOR
                    END IF
                END IF
            END IF
        END IF
    NEXT
RETURN

GrabObject:
    Top = ObjectList(SelectedObject).TopRow
    Left = ObjectList(SelectedObject).LeftCol
    GrabPosRow = MouseRow - Top
    GrabPosCol = MouseCol - Left
    GrabSizeRow = MouseRow - ObjectList(SelectedObject).Hite
    GrabSizeCol = MouseCol - ObjectList(SelectedObject).Wdth
    GrabMode = 0
    IF GrabSizeRow - Top >= -4 THEN
        GrabMode = 4
        GridOriginRow = ObjectList(SelectedObject).Hite MOD StepSize
    END IF
    IF GrabSizeCol - Left >= -4 THEN
        GrabMode = GrabMode OR 8
        GridOriginCol = ObjectList(SelectedObject).Wdth MOD StepSize
    ELSEIF GrabMode = 0 THEN
        GrabMode = 3
        GridOriginRow = Top MOD StepSize
        GridOriginCol = Left MOD StepSize
    END IF
    GOSUB FlagRedrawObject
RETURN

ReleaseObject:
    GrabMode = 0
RETURN

RedrawAllObjects:
    BgTop = 0: BgLeft = 0: BgBtm = 1000: BgRight = 1000
RedrawObjects:
    MouseFunction 2
    LINE (BgLeft, BgTop)-(BgRight - 1, BgBtm - 1), GuiColorBack, BF
    'LINE (BgLeft, BgTop)-(BgRight - 1, BgBtm - 1), INT(RND * 15) + 32, BF
    FOR Count = 0 TO TotalObjects - 1
        Row = ObjectList(Count).TopRow
        Btm = Row + ObjectList(Count).Hite
        Col = ObjectList(Count).LeftCol
        Right = Col + ObjectList(Count).Wdth
        IF ObjectList(Count).Flags AND GuiObjRedraw THEN
            GOTO DrawObject
        END IF
        IF Row < BgBtm THEN
            IF Btm > BgTop THEN
                IF Col < BgRight THEN
                    IF Right > BgLeft THEN
DrawObject:
                        Flags = ObjectList(Count).Flags AND NOT (GuiObjRedraw OR GuiObjActive)
                        IF Count = SelectedObject THEN Flags = Flags OR GuiObjActive
                        ObjectList(Count).Flags = Flags

                        ObjType = ObjectTypeList(Count)
                        IF LEN(ObjectTextList(Count)) <= 0 AND ObjectTypeUsesText(ObjType) THEN ObjectText$ = ObjectTypeNames(ObjType) ELSE ObjectText$ = ObjectTextList(Count)
                        SELECT CASE ObjectTypeList(Count)
                        CASE 0: TestTitleBar.Text = ObjectText$
                                CALL TitleBar.Draw(TestTitleBar, ObjectList(Count))
                        CASE 1: TestButton.Text = ObjectText$
                                CALL Button.Draw(TestButton, ObjectList(Count))
                        CASE 2: TestPrompt.Text = ObjectText$
                                CALL TextPrompt.Draw(TestPrompt, ObjectList(Count))
                        CASE 3: TestSelect.Text = ObjectText$
                                CALL Select.Draw(TestSelect, ObjectList(Count))
                        CASE 4: TestChoices(0) = ObjectText$
                                CALL TextList.Draw(TestTextList, ObjectList(Count), TestChoices())
                        CASE 5: CALL ScrollBar.Draw(TestScrollBar, ObjectList(Count))
                        CASE 6, 23
                                TestLabel.Text = ObjectText$: TestLabel.Align = 0
                                CALL Label.Draw(TestLabel, ObjectList(Count))
                        CASE 7: TestLabel.Text = ObjectText$: TestLabel.Align = 1
                                CALL Label.Draw(TestLabel, ObjectList(Count))
                        CASE 8: TestLabel.Text = ObjectText$
                                CALL Picture.Draw(TestLabel, ObjectList(Count))
                        CASE 9: TestButton.Text = ObjectText$
                                CALL GuiBorder.Draw(TestButton, ObjectList(Count))
                        CASE 10: TestButton.Text = ObjectText$
                                CALL ExpandTab.Draw(TestButton, ObjectList(Count))
                        CASE 11: TestLabel.Text = ObjectText$
                                CALL Bubble.Draw(TestLabel, ObjectList(Count))
                        CASE 12: TestLabel.Text = ObjectText$
                                CALL Color.Draw(TestLabel, ObjectList(Count))
                        CASE 13
                                CALL Scale.Draw(ObjectList(Count))
                        CASE 15
                                WindowBg.Draw TestButton, ObjectList(Count)
                        CASE 14, 16, 20, 19, 22
                                CALL AtrList.Draw(ObjectList(Count))
                        CASE 17: CALL AtrItem.Draw(ObjectText$, ObjectList(Count))
                        CASE 18: CALL Bubble2.Draw(ObjectText$, ObjectList(Count))
                        CASE 21: CALL BarItem.Draw(ObjectText$, ObjectList(Count))
                        CASE ELSE:
                            IF ShowGuiSelection THEN
                                LINE (Col, Row)-(Right - 1, Btm - 1), 9, B
                                LINE (Col + 1, Row + 1)-(Right - 2, Btm - 2), 11, B
                            END IF
                        END SELECT
                        
                        IF ObjectList(Count).Flags AND (GuiObjActive OR GuiObjSelected) THEN
                            IF ShowGuiSelection THEN
                                Top = ObjectList(Count).TopRow - 1
                                Left = ObjectList(Count).LeftCol - 1
                                Hite = ObjectList(Count).Hite
                                Wdth = ObjectList(Count).Wdth
                                Btm = Top + Hite + 2
                                Right = Left + Wdth + 2
                                IF Count = SelectedObject THEN
                                    IF EditMode > 0 THEN Mask = &H7777 ELSE Mask = &H5555
                                ELSE
                                    Mask = &H1111
                                END IF
                                LINE (Left, Top)-(Right - 1, Btm - 1), 5, B, Mask
                            END IF
                        END IF
                    END IF
                END IF
            END IF
        END IF
    NEXT
    BgTop = -1000: BgLeft = -1000: BgBtm = -1000: BgRight = -1000
    IF ShowGuiSelection AND TotalObjects > 0 THEN
        GOSUB ActiveItemInfo
        Top = ObjectList(SelectedObject).TopRow - 1
        Left = ObjectList(SelectedObject).LeftCol - 1
        Btm = Top + ObjectList(SelectedObject).Hite + 2
        Right = Left + ObjectList(SelectedObject).Wdth + 2
        AddToRedrawRegion Top, Left, Btm, Right
    END IF
    MouseFunction 1
    BgRedraw = 0
RETURN

DrawSelection:
    IF TotalObjects <= 0 THEN RETURN
    Top = ObjectList(SelectedObject).TopRow - 1
    Left = ObjectList(SelectedObject).LeftCol - 1
    Hite = ObjectList(SelectedObject).Hite
    Wdth = ObjectList(SelectedObject).Wdth
    Btm = Top + Hite + 2
    Right = Left + Wdth + 2
    IF EditMode > 0 THEN Mask = &H7777 ELSE Mask = &H5555
    LINE (Left, Top)-(Right - 1, Btm - 1), 5, B, Mask
    'AddToRedrawRegion Top, Left, Btm, Right
RETURN

ActiveItemInfo:
    IF TotalObjects <= 0 THEN RETURN
    Top = ObjectList(SelectedObject).TopRow
    Left = ObjectList(SelectedObject).LeftCol
    Hite = ObjectList(SelectedObject).Hite
    Wdth = ObjectList(SelectedObject).Wdth
    LOCATE InfoRow, 1
    COLOR GuiColorBrt
    IF EditMode = 1 THEN
        PRINT "Text = "; RIGHT$(ObjectTextList(SelectedObject), 31);
        COLOR GuiColorWht
        PRINT "Ý"; TAB(40);
    ELSEIF EditMode = 2 THEN
        PRINT "Zorder ="; (SelectedObject + 1) MOD TotalObjects; TAB(40);
    ELSEIF EditMode = 3 THEN
        PRINT "Name = "; RIGHT$(ObjectNameList(SelectedObject), 31);
        COLOR GuiColorWht
        PRINT "Ý"; TAB(40);
    ELSE
        Text = StrNum$(SelectedObject) + "=" + ObjectTypeNames(ObjectTypeList(SelectedObject)) + " " + StrNum$(MouseRow) + "@" + StrNum$(MouseCol) + " " + StrNum$(Top) + ":" + StrNum$(Left) + " "
        PRINT LEFT$(Text + StrNum$(Hite) + "x" + StrNum$(Wdth) + " g=" + StrNum$(StepSize) + SPACE$(20), 40);
    END IF
RETURN

RepositionObject:
    IF TotalObjects <= 0 THEN RETURN
    FOR RedrawObject = 0 TO TotalObjects - 1
        IF RedrawObject = SelectedObject OR (ObjectList(RedrawObject).Flags AND GuiObjSelected) THEN
            GOSUB AddSpecObjectToRedraw
            Top = ObjectList(RedrawObject).TopRow + RowChange
            Left = ObjectList(RedrawObject).LeftCol + ColChange
            ObjectList(RedrawObject).TopRow = Top
            ObjectList(RedrawObject).LeftCol = Left
        END IF
    NEXT
    GrabPosRow = GrabPosRow - RowChange
    GrabPosCol = GrabPosCol - ColChange
GOTO CheckInfoBar

RepositionToSide:
    IF TotalObjects <= 0 THEN RETURN
    'GOSUB AddObjectToRedraw

    Top = ObjectList(SelectedObject).TopRow
    Left = ObjectList(SelectedObject).LeftCol
    
    SELECT CASE SidePosition
    CASE 0: RowChange = -Top: ColChange = 0
    CASE 1: RowChange = ScreenHeight - Top - ObjectList(SelectedObject).Hite: ColChange = 0
    CASE 2: RowChange = 0: ColChange = -Left
    CASE 3: RowChange = 0: ColChange = ScreenWidth - Left - ObjectList(SelectedObject).Wdth
    CASE ELSE: RETURN
    END SELECT
GOTO RepositionObject

ResizeObject:
    IF TotalObjects <= 0 THEN RETURN
    GOSUB AddObjectToRedraw
    Btm = Btm + RowChange
    Right = Right + ColChange
    IF Btm - Top <= 0 AND RowChange <= 0 THEN RETURN
    IF Right - Left <= 0 AND ColChange <= 0 THEN RETURN
    ObjectList(SelectedObject).Hite = Btm - Top
    ObjectList(SelectedObject).Wdth = Right - Left
    GrabSizeRow = GrabSizeRow - RowChange
    GrabSizeCol = GrabSizeCol - ColChange
GOTO CheckInfoBar

'Assumes SelectedObject is valid
'Returns Top,Left,Btm,Right for object
'Sets object's redraw flag
AddObjectToRedraw:              'add selected object to redraw
    Top = ObjectList(SelectedObject).TopRow
    Left = ObjectList(SelectedObject).LeftCol
    Btm = Top + ObjectList(SelectedObject).Hite
    Right = Left + ObjectList(SelectedObject).Wdth
    AddToRedrawRegion Top, Left, Btm, Right
    ObjectList(SelectedObject).Flags = ObjectList(SelectedObject).Flags OR GuiObjRedraw
    'PSET (Left, Top), 6:PSET (Right - 1, Top), 7:PSET (Left, Btm - 1), 8:PSET (Right - 1, Btm - 1), 9
RETURN

'Assumes SelectedObject is valid
FlagRedrawObject:
    ObjectList(SelectedObject).Flags = ObjectList(SelectedObject).Flags OR GuiObjRedraw
    BgRedraw = -1
RETURN

'Assumes RedrawObject is valid and that a border is around it
'Returns Top,Left,Btm,Right for object
'Sets object's redraw flag
AddSpecObjectToRedraw:          'add specified object
    Top = ObjectList(RedrawObject).TopRow - 1
    Left = ObjectList(RedrawObject).LeftCol - 1
    Btm = Top + ObjectList(RedrawObject).Hite + 2
    Right = Left + ObjectList(RedrawObject).Wdth + 2
    AddToRedrawRegion Top, Left, Btm, Right
    ObjectList(RedrawObject).Flags = ObjectList(RedrawObject).Flags OR GuiObjRedraw
RETURN

FlagRedrawAllObjects:
    BgTop = 0: BgLeft = 0: BgBtm = 1000: BgRight = 1000
    BgRedraw = -1
RETURN

CreateObject:
    IF TotalObjects >= MaxObjects THEN RETURN
    IF TotalObjects <= 0 THEN
        Top = 88: Left = 136
        Hite = 24: Wdth = 48
        Flags = 0
        ObjType = 1
        ObjectText$ = ""
    ELSE
        FOR Count = TotalObjects TO SelectedObject + 2 STEP -1
            SubCount = Count - 1
            ObjectList(Count) = ObjectList(SubCount)
            ObjectTypeList(Count) = ObjectTypeList(SubCount)
            ObjectTextList(Count) = ObjectTextList(SubCount)
            ObjectNameList(Count) = ObjectNameList(SubCount)
        NEXT
        IF StepSize < 4 THEN CountStep = 4 ELSE CountStep = StepSize
        Top = ObjectList(SelectedObject).TopRow + CountStep
        Left = ObjectList(SelectedObject).LeftCol + CountStep
        Hite = ObjectList(SelectedObject).Hite
        Wdth = ObjectList(SelectedObject).Wdth
        Flags = ObjectList(SelectedObject).Flags AND NOT GuiObjTemplate
        ObjType = ObjectTypeList(SelectedObject)
        ObjectText$ = ObjectTextList(SelectedObject)
        SelectedObject = SelectedObject + 1
    END IF
    ObjectList(SelectedObject).TopRow = Top
    ObjectList(SelectedObject).LeftCol = Left
    ObjectList(SelectedObject).Hite = Hite
    ObjectList(SelectedObject).Wdth = Wdth
    ObjectList(SelectedObject).Flags = Flags
    ObjectTypeList(SelectedObject) = ObjType
    ObjectTextList(SelectedObject) = ObjectText$
    ObjectNameList(SelectedObject) = ""
    AddToRedrawRegion Top, Left, Top + Hite, Left + Wdth
    TotalObjects = TotalObjects + 1
RETURN

DeleteObject:
    IF TotalObjects <= 0 THEN RETURN
    Top = ObjectList(SelectedObject).TopRow
    Left = ObjectList(SelectedObject).LeftCol
    Btm = Top + ObjectList(SelectedObject).Hite
    Right = Left + ObjectList(SelectedObject).Wdth
    AddToRedrawRegion Top, Left, Btm, Right
           
    FOR Count = SelectedObject TO TotalObjects - 1
        SubCount = Count + 1
        ObjectList(Count) = ObjectList(SubCount)
        ObjectTypeList(Count) = ObjectTypeList(SubCount)
        ObjectTextList(Count) = ObjectTextList(SubCount)
        ObjectNameList(Count) = ObjectNameList(SubCount)
    NEXT
    TotalObjects = TotalObjects - 1
    IF SelectedObject >= TotalObjects THEN SelectedObject = 0
    GOSUB FlagRedrawObject
GOTO CheckInfoBar

ChangeTabOrder:
    IF TotalObjects < 1 THEN RETURN
    'IF NewTabIndex < 1 OR NewTabIndex > TotalObjects THEN NewTabIndex = (NewTabIndex + TotalObjects) MOD TotalObjects
    TestObject = ObjectList(SelectedObject)
    ObjType = ObjectTypeList(SelectedObject)
    ObjectText$ = ObjectTextList(SelectedObject)
    ObjectName$ = ObjectNameList(SelectedObject)
    IF NewTabIndex > SelectedObject THEN CountStep = 1 ELSE CountStep = -1
    FOR Count = SelectedObject TO NewTabIndex - CountStep STEP CountStep
        SubCount = Count + CountStep
        ObjectTypeList(Count) = ObjectTypeList(SubCount)
        ObjectList(Count).TopRow = ObjectList(SubCount).TopRow
        ObjectList(Count).LeftCol = ObjectList(SubCount).LeftCol
        ObjectList(Count).Hite = ObjectList(SubCount).Hite
        ObjectList(Count).Wdth = ObjectList(SubCount).Wdth
        ObjectTextList(Count) = ObjectTextList(SubCount)
        ObjectNameList(Count) = ObjectNameList(SubCount)
    NEXT
    ObjectTypeList(NewTabIndex) = ObjType
    ObjectTextList(NewTabIndex) = ObjectText$
    ObjectNameList(SelectedObject) = ObjectName$
    ObjectList(NewTabIndex) = TestObject
    SelectedObject = NewTabIndex
GOTO ActiveItemInfo

'Checks if the location of the status bar ocludes the selected object
'If so, it moves it accordingly.
CheckInfoBar:
    IF TotalObjects <= 0 THEN RETURN
    Row = ObjectList(SelectedObject).TopRow
    Btm = Row + ObjectList(SelectedObject).Hite
    IF InfoRow <= 1 THEN
        IF (Row < 24 AND Btm <= 176) OR (Row < 8 AND Btm <= 192) THEN InfoRow = ScreenBtmRow: GOSUB RedrawInfoBarBg
    ELSE
        IF (Row >= 24 AND Btm > 176) OR (Row >= 8 AND Btm > 192) THEN InfoRow = 1: GOSUB RedrawInfoBarBg
    END IF
RETURN

'Sets variables to Redraw portion under info bar
RedrawInfoBarBg:
    IF BgRedraw THEN GOSUB RedrawObjects
    BgLeft = 0
    BgRight = ScreenWidth
    BgTop = (OldInfoRow - 1) * ScreenFontHeight
    BgBtm = OldInfoRow * ScreenFontHeight
    OldInfoRow = InfoRow
    BgRedraw = -1
RETURN

'Arrange all the object's tab orders according a left/right, top/bottom order
ArrangeTabOrder:
RETURN

LoadObjects:
    CompleteFilename = -1
    GOSUB GetTextDialog
    IF Cancel THEN RETURN
    Text = RTRIM$(TxtDlgPrompt.Text)

LoadObjectsNow:
    FilErr = 0: ON ERROR GOTO FileErrorHandlerMsg
    OPEN Text FOR INPUT AS 1
    ON ERROR GOTO 0
    IF FilErr THEN RETURN

    IF FileDlg = FileDlgLoad THEN
        GolFilename = Text
        TotalObjects = 0
        TotalObjectTypes = GuiObjectDefTypes
        NeedMerge = 0
    ELSE
        NeedMerge = -1
    END IF
    DO UNTIL EOF(1) OR TotalObjects >= MaxObjects
        INPUT #1, ObjectType$, ObjectNameList(TotalObjects), ObjectList(TotalObjects).TopRow, ObjectList(TotalObjects).LeftCol, ObjectList(TotalObjects).Hite, ObjectList(TotalObjects).Wdth, ObjectList(TotalObjects).Flags, ObjectTextList(TotalObjects _
)
        IF NeedMerge THEN ObjectList(Count).Flags = ObjectList(Count).Flags OR GuiObjTemplate

        'search for object type
        FOR Count = 0 TO TotalObjectTypes - 1
            IF ObjectType$ = ObjectTypeNames(Count) THEN GOTO SetLoadedObjType
        NEXT
        'add new object to name list if no match was found above
        IF TotalObjectTypes < MaxObjectTypes THEN
            ObjectTypeNames(TotalObjectTypes) = ObjectType$
            TotalObjectTypes = TotalObjectTypes + 1
        ELSE
            Count = 0
        END IF
SetLoadedObjType:
        ObjectTypeList(TotalObjects) = Count
        TotalObjects = TotalObjects + 1
    LOOP
    CLOSE 1
    SelectedObject = 0
RETURN

SaveObjects:
    IF NeedMerge THEN IF WaitWithMsg("Merge imported objects? (m)") = "m" THEN GOSUB MergeObjects
    NeedMerge = 0

    CompleteFilename = 0
    GOSUB GetTextDialog
    IF Cancel THEN RETURN
    Text = GolFilename
    GolFilename = RTRIM$(TxtDlgPrompt.Text)

SaveObjectsNow:
    FilErr = 0: ON ERROR GOTO FileErrorHandlerMsg
    IF FileDlg = FileDlgRename THEN
        NAME Text AS GolFilename
        IF FilErr THEN ON ERROR GOTO 0: RETURN
    ELSE
        OPEN GolFilename FOR OUTPUT AS 1
        IF FilErr THEN ON ERROR GOTO 0: RETURN
     
        FOR Count = 0 TO TotalObjects - 1
            IF (ObjectList(Count).Flags AND GuiObjTemplate) = 0 THEN
                WRITE #1, ObjectTypeNames(ObjectTypeList(Count)), ObjectNameList(Count), ObjectList(Count).TopRow, ObjectList(Count).LeftCol, ObjectList(Count).Hite, ObjectList(Count).Wdth, ObjectList(Count).Flags, ObjectTextList(Count)
            END IF
        NEXT
        CLOSE 1
    END IF
RETURN

MergeObjects:
    FOR Count = 0 TO TotalObjects - 1
        ObjectList(Count).Flags = ObjectList(Count).Flags AND NOT GuiObjTemplate
    NEXT
    NeedMerge = 0
RETURN

CompileItems:
'exports the list of items into useable source code
    'match item types to entries in compile list
    FOR Count = 0 TO TotalObjectTypes
        ObjectType$ = ObjectTypeNames(Count)
        FOR SubCount = 5 TO UBOUND(ObjectCmpNames)
            IF ObjectType$ = ObjectCmpNames(SubCount) THEN EXIT FOR
        NEXT
        IF SubCount >= MaxObjectTypes THEN ObjectCmpSrcTbl(Count) = 4 ELSE ObjectCmpSrcTbl(Count) = SubCount
    NEXT

    FilErr = 0: ON ERROR GOTO FileErrorHandlerMsg
    OPEN "guiout.asm" FOR OUTPUT AS 1
    ON ERROR GOTO 0
    IF FilErr THEN RETURN

    PRINT #1, ObjectCmpSrc(0);

    'export container entries
    FOR Count = 0 TO TotalObjects - 1
        IF NOT ObjectTypeIsItem(ObjectTypeList(Count)) THEN
            IF ObjectCmpSrcTbl(ObjectTypeList(Count)) < 5 THEN
                CompileString = ObjectCmpSrc(2)
            ELSE
                CompileString = ObjectCmpSrc(1)
            END IF
            Text = ""
            CharPos = 1
            DO
                NextPos = INSTR(CharPos, CompileString, "[")
                IF NextPos = 0 THEN
                    ConcatString Text, MID$(CompileString, CharPos)
                    EXIT DO
                END IF
                Text = Text + MID$(CompileString, CharPos, NextPos - CharPos)
                CharPos = INSTR(NextPos, CompileString, "]") + 1
                SELECT CASE MID$(CompileString, NextPos + 1, CharPos - NextPos - 2)
                CASE "name": GOSUB GetObjectCmpName
                'CASE ...
                CASE ELSE: ConcatString Text$, MID$(CompileString, NextPos, CharPos - NextPos)
                END SELECT
            LOOP
            'IF ObjectCmpSrcTbl(ObjectTypeList(Count)) <= 5 THEN MID$(Text, 1, 1) = ";"
            PRINT #1, Text;
        END IF
    NEXT
    PRINT #1, ObjectCmpSrc(3)

    ContainerTopRow = 0
    ContainerLeftCol = 0

    'export item data structures
    TrailText = 0
    FOR Count = 0 TO TotalObjects - 1
        CompileString = ObjectCmpSrc(ObjectCmpSrcTbl(ObjectTypeList(Count)))
        Text = ""
        CharPos = 1
        DO
            NextPos = INSTR(CharPos, CompileString, "[")
            IF NextPos = 0 THEN
                ConcatString Text, MID$(CompileString, CharPos)
                EXIT DO
            END IF
            ConcatString Text, MID$(CompileString, CharPos, NextPos - CharPos)
            CharPos = INSTR(NextPos, CompileString, "]") + 1
            SELECT CASE MID$(CompileString, NextPos + 1, CharPos - NextPos - 2)
            CASE "name": GOSUB GetObjectCmpName
            CASE "type": GOSUB GetObjectCmpType
            CASE "height": ConcatString Text$, StrNum$(ObjectList(Count).Hite)
            CASE "width": ConcatString Text$, StrNum$(ObjectList(Count).Wdth)
            CASE "top": ConcatString Text$, StrNum$(ObjectList(Count).TopRow - ContainerTopRow)
            CASE "left": ConcatString Text$, StrNum$(ObjectList(Count).LeftCol - ContainerLeftCol)
            CASE "text": ConcatString Text$, ObjectTextList(Count)
            CASE "bytes": ConcatDataBytes Text$, ObjectTextList(Count), 0
            CASE "picbytes": ConcatDataBytes Text$, ObjectTextList(Count), 97
            CASE "textval": ConcatString Text$, StrNum$(VAL(ObjectTextList(Count)))
            CASE "textlen": ConcatString Text$, StrNum$(LEN(ObjectTextList(Count)))
            CASE "textbefore"
                GOSUB GetObjectTextBefore
                ConcatString Text$, ObjectText$
            CASE "textafter"
                GOSUB GetObjectTextAfter
                ConcatString Text$, ObjectText$
            CASE "lenbefore"
                GOSUB GetObjectTextBefore
                ConcatString Text$, StrNum$(LEN(ObjectText$))
            CASE "lenafter"
                GOSUB GetObjectTextAfter
                ConcatString Text$, StrNum$(LEN(ObjectText$))
            CASE "trail"
                IF NOT TrailText THEN TrailText = -1: SWAP Text, TrailingText
            CASE "endtrail"
                IF TrailText THEN TrailText = 0: SWAP Text, TrailingText: EXIT DO
            CASE "container"
                ContainerTopRow = ObjectList(Count).TopRow
                ContainerLeftCol = ObjectList(Count).LeftCol
            CASE ELSE: ConcatString Text, MID$(CompileString, NextPos, CharPos - NextPos)
            END SELECT
        LOOP
        IF TrailText THEN TrailText = 0: SWAP Text, TrailingText
        PRINT #1, Text;
    NEXT
    PRINT #1,

    PRINT #1, TrailingText;
    TrailingText = ""

    CLOSE 1
RETURN

GetObjectTextBefore:
    NextPos = INSTR(ObjectTextList(Count), MID$(CompileString, CharPos, 1))
    IF NextPos <= 0 THEN NextPos = LEN(ObjectTextList(Count))
    ObjectText$ = LEFT$(ObjectTextList(Count), NextPos)
    CharPos = CharPos + 1
RETURN
GetObjectTextAfter:
    NextPos = INSTR(ObjectTextList(Count), MID$(CompileString, CharPos, 1)) + 1
    ObjectText$ = MID$(ObjectTextList(Count), NextPos)
    CharPos = CharPos + 1
RETURN
GetObjectCmpName:
    IF LEN(ObjectNameList(Count)) THEN
        ConcatString Text$, ObjectNameList(Count)
    ELSE
GetObjectCmpType:
        Text$ = Text$ + ObjectTypeNames(ObjectTypeList(Count)) + StrNum$(Count)
    END IF
RETURN

CorrectObjects:
    FOR RedrawObject = 0 TO TotalObjects - 1
        Hite = ObjectList(RedrawObject).Hite
        Wdth = ObjectList(RedrawObject).Wdth
        ObjType = ObjectTypeList(RedrawObject)
       
        SELECT CASE ObjType
        CASE 0: Hite = 9'title bar
        CASE 1: Hite = 12'button
        CASE 2: Hite = 10'textprompt
        CASE 4, 6, 7, 16: Hite = (Hite + 4) AND -8'list,labels,atrlist
        CASE 5: IF Hite < Wdth THEN Hite = 6 ELSE Wdth = 6 'scroll bar
        CASE 10: Wdth = 9
        CASE 14, 15: Hite = (Hite + 7) AND -8: Wdth = (Wdth + 7) AND -8'window,windowbg
        CASE 17: Hite = 8
        'CASE 11: 'bubble
        END SELECT

        IF Hite <> ObjectList(RedrawObject).Hite OR Wdth <> ObjectList(RedrawObject).Wdth THEN
            ObjectList(RedrawObject).Hite = Hite
            ObjectList(RedrawObject).Wdth = Wdth
            GOSUB AddSpecObjectToRedraw
        END IF
    NEXT
RETURN

GetTextDialog:
    SELECT CASE FileDlg
    CASE FileDlgLoad: TxtDlgBar.Text = "Load"
    CASE FileDlgMerge: TxtDlgBar.Text = "Merge"
    CASE FileDlgSave: TxtDlgBar.Text = "Save"
    CASE FileDlgRename: TxtDlgBar.Text = "Rename"
    END SELECT
    TxtDlgPrompt.Text = GolFilename

    REDIM FileNames(MaxFiles - 1) AS STRING, FileList(9) AS STRING
    HideText = 0
    LINE (0, 0)-(319, 199), GuiColorBack, BF

    Text = GetFileList("*.gol", 239)
    TotalFiles = 0
    DO WHILE TotalFiles < MaxFiles AND LEN(Text) > 0
        FileNames(TotalFiles) = LCASE$(Text)
        TotalFiles = TotalFiles + 1
        Text = GetFileList("", 0)
    LOOP

    FOR Count = 0 TO TotalFiles - 2
        FOR SubCount = Count + 1 TO TotalFiles - 1
            IF FileNames(Count) > FileNames(SubCount) THEN
                SWAP FileNames(Count), FileNames(SubCount)
            END IF
        NEXT
    NEXT

    TestObject.Flags = 0
    TestObject.TopRow = 16
    TestObject.LeftCol = 264
    TestObject.Hite = 12
    TestObject.Wdth = 52
    TxtDlgButton.Text = TxtDlgBar.Text
    CALL Button.Draw(TxtDlgButton, TestObject)
    TestObject.TopRow = 30
    TxtDlgButton.Text = "Cancel"
    CALL Button.Draw(TxtDlgButton, TestObject)
    TestObject.TopRow = 4
    TestObject.LeftCol = 4
    TestObject.Hite = 9
    TestObject.Wdth = 312
    TestObject.Flags = GuiObjActive
    CALL TitleBar.Draw(TxtDlgBar, TestObject)
    TestObject.TopRow = 16
    'TestObject.LeftCol = 4
    TestObject.Hite = 12
    TestObject.Wdth = 256
    TxtDlgButton.Text = "c"
    CALL GuiBorder.Draw(TxtDlgButton, TestObject)

    TxtDlgPrompt.CsrPos = 0'LEN(RTRIM$(TxtDlgPrompt.Text))
    TestObject.TopRow = 17
    TestObject.LeftCol = 5
    TestObject.Hite = 10
    TestObject.Wdth = 254
    FileShown = 0
    FileSearch = -1
    BgRedraw = -1
    DO
        key$ = INKEY$
        SELECT CASE key$
        CASE " " TO "ÿ"
            IF TxtDlgPrompt.CsrPos < 64 THEN
                MatchLen = 32767
                IF CompleteFilename THEN
                    IF FileSearch THEN
                        Text = LCASE$(LEFT$(TxtDlgPrompt.Text, TxtDlgPrompt.CsrPos))
                        FOR Count = 0 TO TotalFiles - 1
                            IF LEFT$(FileNames(Count), TxtDlgPrompt.CsrPos) = Text THEN
                                FOR CharPos = TxtDlgPrompt.CsrPos + 1 TO LEN(FileNames(Count))
                                    IF MID$(FileNames(Count), CharPos, 1) = key$ THEN
                                        IF CharPos < MatchLen THEN
                                            MatchLen = CharPos
                                            MatchIdx = Count
                                            EXIT FOR
                                        END IF
                                    END IF
                                NEXT
                            END IF
                        NEXT
                        Text = ""
                    END IF
                ELSE
                    FileShown = 0
                END IF
                IF MatchLen <> 32767 THEN
                    TxtDlgPrompt.Text = FileNames(MatchIdx)
                    TxtDlgPrompt.CsrPos = MatchLen
                    FileShown = 0
                ELSE
                    TxtDlgPrompt.Text = LEFT$(TxtDlgPrompt.Text, TxtDlgPrompt.CsrPos) + key$
                    TxtDlgPrompt.CsrPos = TxtDlgPrompt.CsrPos + 1
                    FileSearch = 0
                END IF
                BgRedraw = -1
            END IF
        CASE CHR$(8)
            IF TxtDlgPrompt.CsrPos > 0 THEN
                TxtDlgPrompt.Text = LEFT$(TxtDlgPrompt.Text, TxtDlgPrompt.CsrPos - 1)
                TxtDlgPrompt.CsrPos = TxtDlgPrompt.CsrPos - 1
                FileShown = 0
                BgRedraw = -1
            END IF
            FileSearch = -1
        CASE CHR$(13): Cancel = 0: EXIT DO
        CASE CHR$(27): Cancel = 1: EXIT DO
        CASE ELSE
            IF BgRedraw THEN
                LINE (5, 17)-(258, 26), GuiColorBack, BF
                CALL TextPrompt.Draw(TxtDlgPrompt, TestObject)
                BgRedraw = 0
            END IF
            GOSUB ShowFileList
        END SELECT
       
        MouseFunction 3
        MouseButton = Regs.Bx
        MouseRow = Regs.Dx
        MouseCol = Regs.Cx \ 2
        IF (MouseButton AND 1) THEN
            IF MouseCol >= 264 AND MouseCol < 316 THEN
                IF MouseRow >= 16 AND MouseRow < 28 THEN
                    Cancel = 0: EXIT DO
                ELSEIF MouseRow < 42 THEN
                    Cancel = 1: EXIT DO
                END IF
            END IF
        END IF
    LOOP
    ERASE FileNames
RETURN

ShowFileList:
    IF FileShown = 0 THEN Top = 30: Left = 4
    IF Top <= 192 THEN
        LINE (Left, Top)-(Left + 63, Top + 8), GuiColorBack, BF
        IF FileShown < TotalFiles THEN
            Text = LEFT$(TxtDlgPrompt.Text, TxtDlgPrompt.CsrPos)
            FOR FileShown = FileShown TO TotalFiles - 1
                IF LEFT$(FileNames(FileShown), LEN(Text)) = Text THEN
                    CALL DrawCharString(FileNames(FileShown), Top, Left, TextColorSelect)
                    FileShown = FileShown + 1
                    EXIT FOR
                END IF
            NEXT
        END IF
        IF Left < 196 THEN Left = Left + 64 ELSE Left = 4: Top = Top + 9
    END IF
RETURN

FileErrorHandler:
    FilErr = ERR
RESUME NEXT

FileErrorHandlerMsg:
    FilErr = ERR
    IF WaitWithMsg$("Error" + STR$(FilErr) + " occurred when opening file") = CHR$(13) THEN
        RESUME
    ELSE
        RESUME NEXT
    END IF

TestGuiObjects:
    ShowGuiSelection = 0: GOSUB RedrawAllObjects
    DO
        key$ = INKEY$
        SELECT CASE key$
        CASE CHR$(27): EXIT DO
        CASE "W": GOSUB ExportScreenBitmap
        END SELECT
    LOOP
    ShowGuiSelection = 1: GOSUB FlagRedrawObject
RETURN

SetPalette:
    RESTORE GuiPaletteData
    'SCREEN 13
    OUT &H3C8, 0
    DO
        READ RedVal, GrnVal, BluVal
        OUT &H3C9, RedVal
        OUT &H3C9, GrnVal
        OUT &H3C9, BluVal
    LOOP UNTIL BluVal >= 64
RETURN

ShowSampleScreen:
    LINE (0, 0)-(319, 199), GuiColorBack, BF
    TestObject.Flags = 0
    TestObject.TopRow = 15
    TestObject.LeftCol = 15
    TestObject.Hite = 66
    TestObject.Wdth = 82
    TestButton.Text = ""
    GuiBorder.Draw TestButton, TestObject

    RESTORE TestImageData
    FOR RedrawObject = 0 TO 4
        FOR Count = 0 TO UBOUND(TestImage)
            READ TestImage(Count)
        NEXT
        CALL DrawTiles(TestImage(), 8, 8, 16, 16, 64, 80)
        DO: key$ = INKEY$: LOOP UNTIL LEN(key$)
        IF key$ = CHR$(27) THEN EXIT FOR
    NEXT
RETURN

EditPicture: '(text)
    REDIM PicGrid(31, 31)
    Hite = ObjectList(SelectedObject).Hite
    Wdth = ObjectList(SelectedObject).Wdth
    IF Hite > 32 THEN Hite = 32
    IF Wdth > 32 THEN Wdth = 32

    Text = ObjectTextList(SelectedObject)
    IF LEN(Text) THEN
        DEF SEG = VARSEG(Text)
        SrcAdr& = SADD(Text)
        FOR Row = 0 TO Hite - 1
            FOR Col = 0 TO Wdth - 1
                PicGrid(Row, Col) = PEEK(SrcAdr&) - 97
                SrcAdr& = SrcAdr& + 1
            NEXT
        NEXT
    END IF

    MouseFunction 2
    CLS
    MouseFunction 1

    Redraw = 6
    DO
        key$ = INKEY$
        SELECT CASE key$
        CASE "*": IF Wdth < 32 THEN Wdth = Wdth + 1: Redraw = 2
        CASE "/": IF Wdth > 1 THEN Wdth = Wdth - 1: Redraw = 2
        CASE "+": IF Hite < 32 THEN Hite = Hite + 1: Redraw = 2
        CASE "-": IF Hite > 1 THEN Hite = Hite - 1: Redraw = 2
        CASE CHR$(13): EXIT DO
        CASE CHR$(27): ERASE PicGrid: RETURN
        END SELECT

        MouseFunction 3
        Regs.Cx = Regs.Cx \ 2
        IF Regs.Dx <> MouseRow OR Regs.Cx <> MouseCol THEN MouseMove = -1 ELSE MouseMove = 0
        MouseRow = Regs.Dx
        MouseCol = Regs.Cx
        IF (Regs.Bx AND 3) AND ((MouseMove) OR (Regs.Bx > MouseButton)) THEN
            IF MouseCol > 200 THEN 'pick color
                DrawClr = (MouseRow - 35) \ 10
                Redraw = Redraw OR 4
            ELSE 'plot pixel
                Row = MouseRow \ 6
                Col = MouseCol \ 6
                IF Row < Hite AND Col < Wdth THEN
                    IF Regs.Bx AND 1 THEN
                        PicGrid(Row, Col) = DrawClr
                        Redraw = Redraw OR 1
                    ELSE
                        DrawClr = PicGrid(Row, Col)
                        Redraw = Redraw OR 4
                    END IF
                END IF
            END IF
        END IF
        MouseButton = Regs.Bx

        IF Redraw THEN
            MouseFunction 2
            IF Redraw AND 1 THEN
                Clr = PicGrid(Row, Col)
                Top = Row * 6 + 1
                Left = Col * 6 + 1
                LINE (Left, Top)-(Left + 5, Top + 5), Clr, BF
                PSET (Col + 194, Row + 1), Clr
            ELSEIF Redraw AND 2 THEN
                LINE (0, 0)-(Wdth * 6 + 1, Hite * 6 + 1), GuiColorWht, B
                LINE (193, 0)-(194 + Wdth, Hite + 1), GuiColorWht, B
                LINE (193, 34)-(226, 195), GuiColorWht, B
                Top = 1
                FOR Row = 0 TO Hite - 1
                    Left = 1
                    FOR Col = 0 TO Wdth - 1
                        Clr = PicGrid(Row, Col)
                        LINE (Left, Top)-(Left + 5, Top + 5), Clr, BF
                        PSET (Col + 194, Row + 1), Clr
                        Left = Left + 6
                    NEXT
                    Top = Top + 6
                NEXT
                Top = 35
                FOR Clr = 0 TO 15
                    LINE (200, Top)-(225, Top + 9), Clr, BF
                    Top = Top + 10
                NEXT
            END IF
            IF Redraw AND 4 THEN
                LINE (194, 35)-(199, 194), DrawClr, BF
            END IF
            MouseFunction 1
            Redraw = 0
        END IF
    LOOP

    Count = (Hite * Wdth) - LEN(Text)
    IF Count > 0 THEN Text = Text + STRING$(Count, DrawClr)
    DEF SEG = VARSEG(Text)
    DestAdr& = SADD(Text)
    FOR Row = 0 TO Hite - 1
        FOR Col = 0 TO Wdth - 1
            POKE DestAdr&, PicGrid(Row, Col) + 97
            DestAdr& = DestAdr& + 1
        NEXT
    NEXT
    ObjectTextList(SelectedObject) = Text
    ObjectList(SelectedObject).Hite = Hite
    ObjectList(SelectedObject).Wdth = Wdth
    ERASE PicGrid
RETURN

DisplayHelp:
    RESTORE HelpTextData
    HideText = 0
    GOTO DisplayHelpNewPage
    DO UNTIL LEN(Text) = 0
        CALL DrawCharString(Text, Top, 4, TextColorSelect)
        IF LEN(INKEY$) THEN RETURN
        Top = Top + 9
        IF Top >= 182 THEN
            CALL DrawCharString("Press a key or click to continue...", 192, 4, TextColorSelect)
            UserWait
DisplayHelpNewPage:
            Top = 4
            LINE (0, 0)-(319, 199), 0, BF
        END IF
        READ Text
    LOOP
    UserWait
RETURN

DisplayGolInfo:
    REDIM ObjectTypesCount(0 TO MaxObjectTypes - 1)
    HideText = 0
    LINE (0, 0)-(319, 199), 0, BF

    CALL DrawCharString("total objects" + STR$(TotalObjects), 4, 4, TextColorSelect)
    FOR Count = 0 TO TotalObjects - 1
        ObjType = ObjectTypeList(Count)
        ObjectTypesCount(ObjType) = ObjectTypesCount(ObjType) + 1
    NEXT
    Top = 17
    FOR Count = 0 TO TotalObjectTypes - 1
        IF ObjectTypesCount(Count) > 0 THEN
            CALL DrawCharString(ObjectTypeNames(Count) + STR$(ObjectTypesCount(Count)), Top, 4, TextColorSelect)
            Top = Top + 9
        END IF
    NEXT
    UserWait

    ERASE ObjectTypesCount
RETURN

ExportScreenBitmap:
    REDIM FileFlags(999)
    Text = GetFileList$("guipx???.bmp", 239)
    DO WHILE LEN(Text) > 0
        FileFlags(VAL(MID$(Text, 6, 3))) = 1
        Text = GetFileList("", 0)
    LOOP
    FOR Count = 0 TO UBOUND(FileFlags)
        IF FileFlags(Count) = 0 THEN EXIT FOR
    NEXT
    IF Count > UBOUND(FileFlags) THEN ERASE FileFlags: RETURN
    ERASE FileFlags

    ON ERROR GOTO 0
    OPEN "guipx" + RIGHT$("00" + LTRIM$(STR$(Count)), 3) + ".bmp" FOR OUTPUT AS #1

    PRINT #1, "BM"; MKL$((54 + 1024 + 64000) \ 4); MKL$(0); MKL$(54 + 1024);
    PRINT #1, MKL$(40); MKL$(ScreenWidth); MKL$(ScreenHeight); MKL$(&H80001); MKL$(0);
    PRINT #1, MKL$(CLNG(ScreenWidth) * ScreenHeight); MKL$(0); MKL$(0); MKL$(0); MKL$(0);

    FileBuffer$ = SPACE$(1024)
    RESTORE GuiPaletteData
    FOR CharPos = 1 TO 1024 STEP 4
        READ RedVal, GrnVal, BluVal
        MID$(FileBuffer$, CharPos, 4) = MKL$(BluVal * 4 OR GrnVal * 1024& OR RedVal * 262144)
        IF BluVal >= 64 THEN EXIT FOR
    NEXT
    PRINT #1, FileBuffer$;
    FileBuffer$ = ""

    MouseFunction 2
    Regs.Bx = FILEATTR(1, 2)
    Regs.Cx = BmpBufferSize
    Regs.Ds = &HA000
    SEEK 1, 1079

    DEF SEG = &HA000
    FOR SrcAdr& = 0 TO 63999 STEP BmpBufferSize
        Regs.Ax = &H4000
        IF SrcAdr& < 32768 THEN Regs.Dx = SrcAdr& ELSE Regs.Dx = SrcAdr& - 65536
        CALL interruptx(&H21, Regs, Regs)
    NEXT
    MouseFunction 1
   
    'FileBuffer$ = SPACE$(BmpBufferSize)
    'SEEK 1, Filepos&
    'DEF SEG = &HA000
    'FOR SrcAdr& = 0 TO 63999 STEP BmpBufferSize
    '    FOR CharPos = 1 TO BmpBufferSize
    '        MID$(FileBuffer$, CharPos, 1) = CHR$(PEEK(SrcAdr& + CharPos - 1))
    '    NEXT
    '    PRINT #1, FileBuffer$;
    'NEXT

    CLOSE 1
RETURN

RescaleObjects:
    ScaleFactor = 2
    FOR Count = 0 TO TotalObjects - 1
        ObjectList(Count).Hite = ObjectList(Count).Hite * ScaleFactor
        ObjectList(Count).Wdth = ObjectList(Count).Wdth * ScaleFactor
        ObjectList(Count).TopRow = ObjectList(Count).TopRow * ScaleFactor
        ObjectList(Count).LeftCol = ObjectList(Count).LeftCol * ScaleFactor
    NEXT
GOTO RedrawAllObjects


GuiPaletteData:
DATA 0,0,0,    21,19,23, 30,26,32, 41,38,46, 52,48,55, 63,63,63
DATA 36,26,42, 40,30,60, 20,20,40, 20,20,60,  0,40,0,   0,60,0
DATA 40,40,0,  63,60,0,  40,0,0,   63,0,64
'DATA 40,0,40, 60,0,60,  0,0,40,   0,0,58,   0,40,0,   0,60,0
'DATA 40,40,0, 63,60,0,  40,0,0,   63,0,64
'DATA 32,0,32, 0,0,32,   0,32,0,   32,30,0,  32,0,0
'DATA 63,0,63, 0,0,63,   0,63,0,   63,60,0,  63,0,64

TestImageData:
'Scattered Particulate
DATA 2,2,2,1,2,1,2,2
DATA 1,2,2,2,2,2,2,2
DATA 2,2,1,2,2,2,1,2
DATA 1,2,2,2,1,2,2,2
DATA 2,2,2,2,2,2,1,2
DATA 2,1,2,1,2,2,2,2
DATA 2,2,2,2,2,1,2,1
DATA 2,1,2,2,2,2,2,2

'Honeycomb
DATA 0,2,1,0,1,0,1,2
DATA 2,1,1,1,2,1,1,1
DATA 1,0,1,2,0,2,1,0
DATA 2,1,1,1,2,1,1,1
DATA 0,2,1,0,1,0,1,2
DATA 2,1,1,1,2,1,1,1
DATA 1,0,1,2,0,2,1,0
DATA 2,1,1,1,2,1,1,1

'Darker Honeycomb
DATA 0,2,1,0,1,0,1,2
DATA 2,1,0,1,2,1,0,1
DATA 1,0,1,2,0,2,1,0
DATA 2,1,0,1,2,1,0,1
DATA 0,2,1,0,1,0,1,2
DATA 2,1,0,1,2,1,0,1
DATA 1,0,1,2,0,2,1,0
DATA 2,1,0,1,2,1,0,1

'ZigZag Waves
DATA 3,1,2,2,1,1,2,4
DATA 2,2,4,4,3,1,3,4
DATA 4,4,2,2,4,3,1,3
DATA 2,2,1,3,4,2,1,1
DATA 1,1,2,4,3,1,2,2
DATA 3,1,3,4,2,2,4,4
DATA 4,3,1,3,4,4,2,2
DATA 4,2,1,1,2,2,1,3

'Raised Dots
DATA 4,3,2,0,0,2,3,4
DATA 3,2,1,2,2,1,2,3
DATA 2,1,2,3,3,2,1,2
DATA 0,2,3,4,4,3,2,0
DATA 0,2,3,4,4,3,2,0
DATA 2,1,2,3,3,2,1,2
DATA 3,2,1,2,2,1,2,3
DATA 4,3,2,0,0,2,3,4

DefaultDialogData:
DATA 6,141,72,16,174,0,"The dialog window above is just an examplePress F1 for help on the keys to make your own"
DATA 9,1,1,102,256,0,""
DATA 0,4,4,9,166,0,"Load Image"
DATA 2,16,4,12,108,0,"uylum.bmp"
DATA 4,30,4,60,99,0,"uylum.bmp"
DATA 5,30,104,60,8,0,
DATA 1,16,118,12,52,0,"Load"
DATA 1,31,118,12,52,0,"Cancel"
DATA 1,46,118,12,52,0,"Preview"
DATA 3,70,118,8,52,0,"Read"
DATA 3,79,118,8,52,0,"Write"
DATA 6,93,6,8,52,0,"C:\Pics\Anime"
DATA 7,93,118,8,52,0,"12534 bytes"
DATA 0,4,173,9,81,0,"Image Preview"
DATA 9,15,173,85,81,0,"concave"
'DATA 8,44,205,20,20,0,"fffffffffffffffffffffffffffffeeefffffffffffffffebbqbbdffffffffffffdbbbbccdcffffffffffdcdbbbbcdcefffffffffcccbbbbbccdffffffffebbbcbbbbbbcefffffffebbbdccbbccdeffffffffbbbcdeccdcceffffffffedcc
'deeddccefffffffffecddeeedbbdfffffffffebcddddcbbdfffffffffdccddddccbbeffffffffddeddddcccbdfffffffeddeeedecceeeffffffecdeedddedcdeeeffffedbddddddddccddefffffccddcddeeeeccdeffffdqcddcdeeddeecdeffffcbcddcdeeddddedde"
DATA 10,5,257,32,10,0,"Load"
DATA 10,37,257,32,10,0,"Save"
DATA 10,69,257,32,10,0,"View"
DATA 11,46,24,12,95,0,"Toggles the preview pane"
DATA -1

HelpTextData:
DATA Simple/Quick/Dirty GUI Helper - Peekin 2002-03-14
DATA Brings the simplicity of VB (kind of) to assembly
DATA " "
DATA Grab the object center with the mouse to reposition
DATA Or grab the bottom/right sides to resize.
DATA " "
DATA Arrow keys = move object around on screen
DATA Home End PgUp PgDn = move object to screen edges
DATA + - * / = resize object
DATA Tab Shift+Tab = next/previous object
DATA Ctrl+(Left/Right) = change object tab order
DATA Delete Insert = delete or create new object
DATA Enter = view objects full screen
DATA Escape = quit program
DATA " "
DATA l load saved objects from text file
DATA L merge object list from file into current list
DATA Ctrl+L quick reload
DATA s save object positions to specified text file
DATA S rename save file
DATA Ctrl+S quick save
DATA g toggle grid
DATA G increment grid size
DATA a align position to grid
DATA A align size to grid
DATA e edit object text
DATA n edit object name
DATA o change object type (cycles through them; Shift+o=reverse)
DATA t toggle text on/off (to speed redrawing up)
DATA i object information page
DATA W save screenshot to bitmap
DATA z sequence object's z-order
DATA

SUB AddToRedrawRegion (Top, Left, Btm, Right)

IF BgTop <= -1000 THEN
    BgTop = Top: BgLeft = Left: BgBtm = Btm: BgRight = Right
ELSE
    IF Top < BgTop THEN BgTop = Top
    IF Left < BgLeft THEN BgLeft = Left
    IF Btm > BgBtm THEN BgBtm = Btm
    IF Right > BgRight THEN BgRight = Right
END IF
BgRedraw = -1

END SUB

SUB AtrItem.Draw (Text AS STRING, Gui AS GuiType)

Top = Gui.TopRow
IF Gui.Flags AND GuiObjActive THEN Clr = TextColorActive ELSE Clr = TextColorNormal
CharPos = 1
Count = INSTR(Text, ":")
IF Count <= 0 THEN Count = LEN(Text)
DrawCharString MID$(Text, Count + 1, LEN(Text) - Count), Top, Gui.LeftCol + 40, Clr
Text = LEFT$(Text$, Count)
DrawCharString Text, Top, Gui.LeftCol + 36 - TextWidth(Text) + 1, Clr

END SUB

SUB AtrList.Draw (Gui AS GuiType)

IF ShowGuiSelection THEN
    Top = Gui.TopRow
    Bottom = Gui.TopRow + Gui.Hite - 1
    Left = Gui.LeftCol
    Right = Gui.LeftCol + Gui.Wdth - 1
    LINE (Left, Top)-(Right, Bottom), 9, B, &HAAAA
END IF

END SUB

SUB BarItem.Draw (Text AS STRING, Gui AS GuiType)

IF Gui.Flags AND GuiObjActive THEN Clr = TextColorActive ELSE Clr = TextColorNormal
DrawCharString Text, Gui.TopRow, (Gui.Wdth - TextWidth(Text) + 1) \ 2 + Gui.LeftCol, Clr

END SUB

SUB Bubble.Draw (Obj AS LabelType, Gui AS GuiType)

Top = Gui.TopRow
Left = Gui.LeftCol
Btm = Top + Gui.Hite - 1
Right = Left + Gui.Wdth - 1
LINE (Left + 1, Top + 1)-(Right - 1, Btm - 1), 8, BF
LINE (Left + 2, Top)-(Right - 2, Top), 9
LINE (Left + 2, Btm)-(Right - 2, Btm), 9
LINE (Left, Top + 2)-(Left, Btm - 2), 9
LINE (Right, Top + 2)-(Right, Btm - 2), 9
PSET (Left + 1, Top + 1), 9
PSET (Left + 1, Btm - 1), 9
PSET (Right - 1, Top + 1), 9
PSET (Right - 1, Btm - 1), 9

Top = Top + 3
Left = Left + 3
CharPos = 1
Count = LEN(RTRIM$(Obj.Text))
DO UNTIL CharPos > Count
    NextPos = INSTR(CharPos, Obj.Text, "")
    IF NextPos <= 0 THEN NextPos = Count + 1
    Text$ = MID$(Obj.Text, CharPos, NextPos - CharPos)
    DrawCharString Text$, Top, Left, TextColorInfo
    Top = Top + 8
    CharPos = NextPos + 1
LOOP

END SUB

SUB Bubble2.Draw (Text AS STRING, Gui AS GuiType)

Top = Gui.TopRow
Left = Gui.LeftCol
Btm = Top + Gui.Hite - 1
Right = Left + Gui.Wdth - 1
Clr = VAL(Text)
LINE (Left + 1, Top + 1)-(Right - 1, Btm - 1), Clr - 1, BF
LINE (Left + 2, Top)-(Right - 2, Top), Clr
LINE (Left + 2, Btm)-(Right - 2, Btm), Clr
LINE (Left, Top + 2)-(Left, Btm - 2), Clr
LINE (Right, Top + 2)-(Right, Btm - 2), Clr
PSET (Left + 1, Top + 1), Clr
PSET (Left + 1, Btm - 1), Clr
PSET (Right - 1, Top + 1), Clr
PSET (Right - 1, Btm - 1), Clr

END SUB

SUB Button.Draw (Obj AS ButtonType, Gui AS GuiType)

Top = Gui.TopRow + 1
Bottom = Gui.TopRow + Gui.Hite - 2
Left = Gui.LeftCol + 1
Right = Gui.LeftCol + Gui.Wdth - 2

'LINE (Left, Top)-(Right, Bottom), GuiColorBack, BF
IF Obj.State THEN
    LINE (Gui.LeftCol, Top)-(Gui.LeftCol, Bottom), GuiColorDim
    LINE (Left, Top)-(Left, Bottom), GuiColorDim
    LINE (Right + 1, Top)-(Right + 1, Bottom), GuiColorLit
    LINE (Left, Gui.TopRow)-(Right, Gui.TopRow), GuiColorDrk
    LINE (Left, Top)-(Right, Top), GuiColorDim
    LINE (Left, Bottom + 1)-(Right, Bottom + 1), GuiColorBrt
ELSE
    LINE (Gui.LeftCol, Top)-(Gui.LeftCol, Bottom), GuiColorLeft
    LINE (Right + 1, Top)-(Right + 1, Bottom), GuiColorRight
    LINE (Left, Gui.TopRow)-(Right, Gui.TopRow), GuiColorTop
    LINE (Left, Bottom + 1)-(Right, Bottom + 1), GuiColorBtm
END IF

IF Gui.Flags AND GuiObjActive THEN Clr = TextColorActive ELSE Clr = TextColorNormal
DrawCharString Obj.Text, Top + 2, (Gui.Wdth - TextWidth(Obj.Text) + 1) \ 2 + Gui.LeftCol, Clr

END SUB

SUB Color.Draw (Obj AS LabelType, Gui AS GuiType)

Top = Gui.TopRow
Left = Gui.LeftCol
Btm = Top + Gui.Hite - 1
Right = Left + Gui.Wdth - 1
LINE (Left, Top)-(Right, Btm), VAL(Obj.Text), BF

END SUB

SUB ConcatDataBytes (DestString AS STRING, SrcString AS STRING, Dif AS INTEGER)

DIM Text AS STRING

TextLen = LEN(SrcString)
IF TextLen <= 0 THEN EXIT SUB
CharPos = LEN(DestString)
DestString = DestString + SPACE$(TextLen * 4)

Count = 1
Text = StrNum$(ASC(LEFT$(SrcString, 1)) - Dif)
GOTO CdbInLoop
DO
    Text = "," + StrNum$(ASC(MID$(SrcString, Count, 1)) - Dif)
CdbInLoop:
    MID$(DestString, CharPos + 1) = Text
    CharPos = CharPos + LEN(Text)
    Count = Count + 1
LOOP UNTIL Count > TextLen

DestString = LEFT$(DestString, CharPos)

END SUB

SUB ConcatString (DestString AS STRING, SrcString AS STRING)

DestString = DestString + SrcString

END SUB

'Blits a two color, transparent character to screen using default 2bit font
'set. Aborts blit if ASCII character < 16 or either height or width <= 0.
SUB DrawChar (Char, Top, Left, Clr)

IF Char < 16 THEN EXIT SUB

SrcAdr& = (Char - 16) * 32 + VARPTR(FontChars(0))
'SrcAdr& = Char * 8 + &HFA6E

CharHeight = 8: CharWidth = 8
IF Top < 0 THEN
    Hite = CharHeight + Top
    SrcAdr& = SrcAdr& - Top
    DestAdr& = 0
ELSE
    DestAdr& = Top * CLNG(ScreenWidth)
    Hite = ScreenHeight - Top
    IF Hite > CharHeight THEN Hite = CharHeight
END IF
IF Hite < 1 THEN EXIT SUB

IF Left < 0 THEN
    Wdth = CharWidth + Left
    IF Wdth < 1 THEN EXIT SUB
    Shift = 4& ^ -Left
ELSE
    DestAdr& = DestAdr& + Left
    Shift = 1
    Wdth = ScreenWidth - Left
    IF Wdth > CharWidth THEN Wdth = CharWidth ELSE IF Wdth < 1 THEN EXIT SUB
END IF

'For an odd italic effect, delete the +1
Wrap = ScreenWidth - Wdth + 1
FontSeg = VARSEG(FontChars(0))
'FontSeg = &HF000

EdgeColor = Clr \ 256
FOR Row = 1 TO Hite
    DEF SEG = FontSeg
    Word& = PEEK(SrcAdr&) + (PEEK(SrcAdr& + 1) * 256&)
    Word& = Word& \ Shift
    DEF SEG = &HA000
    FOR Col = 2 TO Wdth
        IF Word& AND 2 THEN POKE DestAdr&, EdgeColor ELSE IF Word& AND 1 THEN POKE DestAdr&, Clr
        'IF Word& AND 2 THEN PSET (Left + Col - 2, Top + Row - 1), EdgeColor ELSE IF Word& AND 1 THEN PSET (Left + Col - 2, Top + Row - 1), Clr
        Word& = Word& \ 4
        DestAdr& = DestAdr& + 1
    NEXT
    'Word& = PEEK(SrcAdr&)' * Shift
    'DEF SEG = &HA000
    'FOR Col = 2 TO Wdth
    '    IF Word& AND 128 THEN POKE DestAdr&, Clr
    '    Word& = Word& * 2
    '    DestAdr& = DestAdr& + 1
    'NEXT
    DestAdr& = DestAdr& + Wrap
    'SrcAdr& = SrcAdr& + 1
    SrcAdr& = SrcAdr& + 4
NEXT

END SUB

SUB DrawCharString (Text AS STRING, Top, Left, Clr)
IF HideText THEN EXIT SUB

Col = Left
FOR Count = 1 TO LEN(Text)
    Char = ASC(MID$(Text, Count, 1))
    IF Char AND 223 THEN CALL DrawChar(Char, Top, Col, Clr)
    Col = Col + FontSizes(Char) + 1
NEXT

END SUB

SUB DrawCharStringV (Text AS STRING, Top, Left, Clr)
IF HideText THEN EXIT SUB

Row = Top
FOR Count = 1 TO LEN(Text)
    Char = ASC(MID$(Text, Count, 1))
    IF Char AND 223 THEN CALL DrawCharV(Char, Row, Left, Clr)
    Row = Row + FontSizes(Char) + 1
NEXT

END SUB

'Blits a two color, transparent character to screen using default 2bit font
'set. Characters are oriented vertical.
SUB DrawCharV (Char, Top, Left, Clr)

IF Char < 16 THEN EXIT SUB

SrcAdr& = (Char - 16) * 32 + VARPTR(FontChars(0))
'SrcAdr& = Char * 8 + &HFA6E

CharHeight = 8: CharWidth = 8
IF Top < 0 THEN
    Hite = CharHeight + Top
    Shift = 4& ^ -Top
    DestAdr& = 0
ELSE
    DestAdr& = Top * CLNG(ScreenWidth)
    Hite = ScreenHeight - Top
    Shift = 1
    IF Hite > CharHeight THEN Hite = CharHeight
END IF
IF Hite < 1 THEN EXIT SUB

IF Left < 0 THEN
    Wdth = CharWidth + Left
    SrcAdr& = SrcAdr& - Left
ELSE
    DestAdr& = DestAdr& + Left
    Wdth = ScreenWidth - Left
    IF Wdth > CharWidth THEN Wdth = CharWidth
END IF
IF Wdth < 1 THEN EXIT SUB

Wrap = Hite * -ScreenWidth - 1
FontSeg = VARSEG(FontChars(0))
'FontSeg = &HF000

EdgeColor = Clr \ 256
FOR Col = 0 TO Wdth - 1
    DEF SEG = FontSeg
    Word& = PEEK(SrcAdr&) + (PEEK(SrcAdr& + 1) * 256&)
    Word& = Word& \ Shift
    DEF SEG = &HA000
    FOR Row = 0 TO Hite - 1
        IF Word& AND 2 THEN POKE DestAdr&, EdgeColor ELSE IF Word& AND 1 THEN POKE DestAdr&, Clr
        'IF Word& AND 2 THEN PSET (Left - Col, Top + Row), EdgeColor ELSE IF Word& AND 1 THEN PSET (Left - Col, Top + Row), Clr
        Word& = Word& \ 4
        DestAdr& = DestAdr& + ScreenWidth
    NEXT
    'Word& = PEEK(SrcAdr&)' * Shift
    'DEF SEG = &HA000
    'FOR Col = 2 TO Wdth
    '    IF Word& AND 128 THEN POKE DestAdr&, Clr
    '    Word& = Word& * 2
    '    DestAdr& = DestAdr& + 1
    'NEXT
    DestAdr& = DestAdr& + Wrap
    'SrcAdr& = SrcAdr& + 1
    SrcAdr& = SrcAdr& + 4
NEXT

END SUB

SUB DrawTiles (ImgSrc(), ImgHite, ImgWdth, Top, Left, Hite, Wdth)
    DEF SEG = &HA000
    DestRowAdr& = Top * ScreenWidth + Left
    ImgRowWrap = ImgHite
    SrcRowIdx = 0
    FOR Row = 1 TO Hite
        DestAdr& = DestRowAdr&
        ImgColWrap = ImgWdth
        SrcIdx = SrcRowIdx
        FOR Col = 1 TO Wdth
            POKE DestAdr&, ImgSrc(SrcIdx)
            SrcIdx = SrcIdx + 1
            ImgColWrap = ImgColWrap - 1
            IF ImgColWrap <= 0 THEN ImgColWrap = ImgWdth: SrcIdx = SrcRowIdx
            DestAdr& = DestAdr& + 1
        NEXT
        SrcRowIdx = SrcRowIdx + ImgWdth
        ImgRowWrap = ImgRowWrap - 1
        IF ImgRowWrap <= 0 THEN ImgRowWrap = ImgHite: SrcRowIdx = 0
        DestRowAdr& = DestRowAdr& + ScreenWidth
    NEXT
END SUB

SUB ExpandTab.Draw (Obj AS ButtonType, Gui AS GuiType)

Top = Gui.TopRow
Bottom = Gui.TopRow + Gui.Hite - 1
Left = Gui.LeftCol
Right = Gui.LeftCol + Gui.Wdth - 1

LINE (Left, Top + 1)-(Right - 1, Bottom - 1), GuiColorBack, BF
LINE (Right, Top + 1)-(Right, Bottom - 1), GuiColorLit
LINE (Left, Top)-(Right - 1, Top), GuiColorBrt
LINE (Left, Bottom)-(Right - 1, Bottom), GuiColorDim

IF Gui.Flags AND GuiObjActive THEN Clr = TextColorActive ELSE Clr = TextColorNormal
'DrawCharStringV Obj.Text, (Gui.Hite - LEN(RTRIM$(Obj.Text)) * 7 + 1) \ 2 + Gui.TopRow, Left + 1, Clr
DrawCharStringV Obj.Text, (Gui.Hite - TextWidth(Obj.Text) + 1) \ 2 + Gui.TopRow, Left + 6, Clr

END SUB

FUNCTION GetFileList$ (FileMask$, FileType) STATIC

DIM DTA AS STRING * 320
Count = 150

IF LEN(FileMask$) THEN 'FindFirst
    FileSpec$ = FileMask$ + CHR$(0)
    IF LongFileNames THEN
        Regs.Ax = &H714E
        Regs.Es = -1
        Regs.Di = VARPTR(DTA)
        Regs.Si = 0
        Regs.Flags = 0
    ELSE
        Regs.Ax = &H1A00                   'Set DTA function
        Regs.Dx = VARPTR(DTA)              'DS:DX points to our DTA
        Regs.Ds = -1                       'Use current value for DS
        CALL interruptx(&H21, Regs, Regs)  'Do the interrupt
        Regs.Ax = &H4E00
    END IF
    Regs.Cx = FileType
    Regs.Dx = SADD(FileSpec$)
    Regs.Ds = -1
    FindFirst = 1
ELSE 'FindNext

GetNextFile:
    IF LongFileNames THEN
        Regs.Ax = &H714F
        Regs.Bx = DirHandle
        Regs.Es = -1
        Regs.Di = VARPTR(DTA)
        Regs.Si = 0
        Regs.Flags = 0
    ELSE
        Regs.Ax = &H4F00
    END IF
END IF
  
CALL interruptx(&H21, Regs, Regs)
IF FindFirst THEN FileTypeWanted = FileType: DirHandle = Regs.Ax: FindFirst = 0

IF Regs.Flags AND 1 THEN 'Error
  GetFileList$ = ""     'Return null string
  IF LongFileNames THEN 'free Win95 handle
    Regs.Ax = &H71A1
    Regs.Bx = DirHandle
    CALL interruptx(&H21, Regs, Regs)
  END IF
ELSE
  IF LongFileNames THEN
    FileType = ASC(MID$(DTA, 1, 1))
    BaseChar = 45
  ELSE
    FileType = ASC(MID$(DTA, 22, 1))
    BaseChar = 31
  END IF
  IF FileType AND FileTypeWanted THEN
    CurChar = INSTR(BaseChar, DTA, CHR$(0))
    GetFileList$ = MID$(DTA, BaseChar, CurChar - BaseChar)
  ELSEIF Count > 0 THEN Count = Count - 1: GOTO GetNextFile
  END IF
END IF

END FUNCTION

SUB GuiBorder.Draw (Obj AS ButtonType, Gui AS GuiType)

Top = Gui.TopRow
Bottom = Gui.TopRow + Gui.Hite - 1
Left = Gui.LeftCol
Right = Gui.LeftCol + Gui.Wdth - 1
IF INSTR(Obj.Text, "f") THEN LINE (Left + 1, Top + 1)-(Right - 1, Bottom - 1), GuiColorBack, BF
IF INSTR(Obj.Text, "d") THEN
    Clr1 = GuiColorLit
    Clr2 = GuiColorDim
    Clr3 = GuiColorLit
    Clr4 = GuiColorDim
ELSE
    Clr1 = GuiColorLeft
    Clr2 = GuiColorRight
    Clr3 = GuiColorTop
    Clr4 = GuiColorBtm
END IF
IF INSTR(Obj.Text, "c") THEN
    LINE (Left, Top + 1)-(Left, Bottom - 1), Clr2
    LINE (Right, Top + 1)-(Right, Bottom - 1), Clr1
    LINE (Left + 1, Top)-(Right - 1, Top), Clr4
    LINE (Left + 1, Bottom)-(Right - 1, Bottom), Clr3
ELSE
    LINE (Left, Top + 1)-(Left, Bottom - 1), Clr1
    LINE (Right, Top + 1)-(Right, Bottom - 1), Clr2
    LINE (Left + 1, Top)-(Right - 1, Top), Clr3
    LINE (Left + 1, Bottom)-(Right - 1, Bottom), Clr4
END IF
'CALL DrawTiles(TestImage(), 8, 8, Top + 1, Left + 1, Gui.Hite - 2, Gui.Wdth - 2)

END SUB

SUB Label.Draw (Obj AS LabelType, Gui AS GuiType)

Top = Gui.TopRow
CharPos = 1
Count = LEN(RTRIM$(Obj.Text))
DO UNTIL CharPos > Count
    NextPos = INSTR(CharPos, Obj.Text, "")
    IF NextPos <= 0 THEN NextPos = Count + 1
    Text$ = MID$(Obj.Text, CharPos, NextPos - CharPos)
    IF Obj.Align THEN
        Left = Gui.LeftCol + Gui.Wdth - TextWidth(Text$) + 1
    ELSE
        Left = Gui.LeftCol
    END IF
    DrawCharString Text$, Top, Left, TextColorNormal
    Top = Top + 8
    CharPos = NextPos + 1
LOOP

END SUB

SUB MouseFunction (Ax)

Regs.Ax = Ax
IF MousePresent THEN
  CALL interruptx(&H33, Regs, Regs)
ELSEIF Ax = 0 OR Ax = &H21 THEN
  CALL interruptx(&H33, Regs, Regs)
  IF Regs.Ax = -1 THEN MousePresent = -1
END IF
END SUB

SUB OldScrollBar.Draw (Obj AS ScrollBarType, Gui AS GuiType)

Top = Gui.TopRow
Bottom = Top + Gui.Hite - 1
Left = Gui.LeftCol
Right = Left + Gui.Wdth - 1

BarHeight = 8
IF Gui.Wdth > Gui.Hite THEN 'Horizontal
    IF Obj.Total > 0 THEN
        BarOffset = (Gui.Wdth - BarHeight) * Obj.Value \ Obj.Total
    END IF

    'LINE (Left, Top)-(Right, Bottom + 7), GuiColorBack, B'cheap eraser line
    LINE (Left, Top + 2)-(Left, Top + 5), GuiColorDrk
    LINE (Right, Top + 2)-(Right, Top + 5), GuiColorLit
    LINE (Left + 1, Top + 1)-(Right - 1, Top + 1), GuiColorDrk
    LINE (Left + 1, Top + 6)-(Right - 1, Top + 6), GuiColorBrt
    LINE (Left + 1, Top + 2)-(Right - 1, Top + 5), GuiColorDim, BF

    Top = Top + 1
    Bottom = Top + 5
    Left = Left + BarOffset + 1
    Right = Left + BarHeight - 3
  
    LINE (Left, Top)-(Right, Bottom), GuiColorBack, BF
    LINE (Left - 1, Top)-(Left - 1, Bottom), GuiColorLit
    LINE (Right + 1, Top)-(Right + 1, Bottom), GuiColorDim
    LINE (Left, Top - 1)-(Right, Top - 1), GuiColorBrt
    LINE (Left, Bottom + 1)-(Right, Bottom + 1), GuiColorDrk

    IF DrawArrow THEN
        LINE (Left, Top + 1)-(Left + 5, Top + 1), GuiColorDim
        LINE (Left, Top + 2)-(Left + 2, Top + 4), GuiColorLit
        LINE (Left + 3, Top + 4)-(Left + 5, Top + 2), GuiColorWht
        LINE (Left + 1, Top + 2)-(Left + 4, Top + 2), GuiColorBrt
        LINE (Left + 2, Top + 3)-(Left + 3, Top + 3), GuiColorBrt
    END IF
ELSE 'Vertical
    IF Obj.Total > 0 THEN
        BarOffset = (Gui.Hite - BarHeight) * Obj.Value \ Obj.Total
    END IF

    LINE (Left, Top)-(Left + 7, Bottom), GuiColorBack, B 'cheap eraser line
    LINE (Left + 1, Top + 1)-(Left + 1, Bottom - 1), GuiColorDrk
    LINE (Left + 6, Top + 1)-(Left + 6, Bottom - 1), GuiColorLit
    LINE (Left + 2, Top)-(Left + 5, Top), GuiColorDrk
    LINE (Left + 2, Bottom)-(Left + 5, Bottom), GuiColorBrt
    LINE (Left + 2, Top + 1)-(Left + 5, Bottom - 1), GuiColorDim, BF

    Top = Top + BarOffset + 1
    Bottom = Top + BarHeight - 3
    Left = Left + 1
    Right = Left + 5
   
    LINE (Left, Top)-(Right, Bottom), GuiColorBack, BF
    LINE (Left - 1, Top)-(Left - 1, Bottom), GuiColorLit
    LINE (Right + 1, Top)-(Right + 1, Bottom), GuiColorDim
    LINE (Left, Top - 1)-(Right, Top - 1), GuiColorBrt
    LINE (Left, Bottom + 1)-(Right, Bottom + 1), GuiColorDrk

    IF DrawArrow THEN
        LINE (Left, Top + 1)-(Left + 5, Top + 1), GuiColorDim
        LINE (Left, Top + 2)-(Left + 2, Top + 4), GuiColorLit
        LINE (Left + 3, Top + 4)-(Left + 5, Top + 2), GuiColorWht
        LINE (Left + 1, Top + 2)-(Left + 4, Top + 2), GuiColorBrt
        LINE (Left + 2, Top + 3)-(Left + 3, Top + 3), GuiColorBrt
    END IF
END IF

END SUB

SUB Picture.Draw (Obj AS LabelType, Gui AS GuiType)

Top = Gui.TopRow
Left = Gui.LeftCol
Btm = Top + Gui.Hite - 1
Right = Left + Gui.Wdth - 1
'LINE (Left, Top)-(Right, Btm), GuiColorDim, B

IF HideText THEN EXIT SUB
DEF SEG = VARSEG(Obj.Text)
SrcAdr& = VARPTR(Obj.Text)
FOR Row = Top TO Btm
    FOR Col = Left TO Right
        PSET (Col, Row), PEEK(SrcAdr&) - 97
        SrcAdr& = SrcAdr& + 1
    NEXT
NEXT

'Vertical lines
'Clr = 6
'FOR Col = Left TO Right
'    LINE (Col, Top)-(Col, Btm), Clr
'    Clr = Clr + 2
'    IF Clr > 15 THEN Clr = ((Clr + 1) AND 1) + 6
'NEXT

END SUB

SUB Scale.Draw (Gui AS GuiType)

Top = Gui.TopRow: Btm = Top + Gui.Hite - 1
Left = Gui.LeftCol: Right = Left + Gui.Wdth - 1
ScaleStep = 256
FOR Row = Top TO Btm
    IF ScaleStep <= 0 THEN
        LINE (Left, Row)-(Right, Row), GuiColorDim
    ELSE
        FOR Col = Left TO Right STEP ScaleStep
            PSET (Col, Row), GuiColorDim
        NEXT
        ScaleStep = ScaleStep \ 2
    END IF
NEXT

END SUB

SUB ScrollBar.Draw (Obj AS ScrollBarType, Gui AS GuiType)

Top = Gui.TopRow
Bottom = Top + Gui.Hite - 1
Left = Gui.LeftCol
Right = Left + Gui.Wdth - 1

BarHeight = 12
IF Gui.Wdth > Gui.Hite THEN 'Horizontal
    IF Obj.Total > 0 THEN
        BarOffset = (Gui.Wdth - BarHeight) * Obj.Value \ Obj.Total
    END IF

    LINE (Left, Top + 1)-(Left, Top + 4), GuiColorDrk
    LINE (Right, Top + 1)-(Right, Top + 4), GuiColorLit
    LINE (Left + 1, Top)-(Right - 1, Top), GuiColorDrk
    LINE (Left + 1, Top + 5)-(Right - 1, Top + 5), GuiColorBrt
    LINE (Left + 1, Top + 1)-(Right - 1, Top + 4), GuiColorDim, BF

    Bottom = Top + 5
    Left = Left + BarOffset
    Right = Left + BarHeight - 1
 
    LINE (Left + 1, Top + 1)-(Right - 1, Bottom - 1), GuiColorBack, BF
    LINE (Left, Top + 1)-(Left, Bottom - 1), GuiColorLit
    LINE (Right, Top + 1)-(Right, Bottom - 1), GuiColorDrk
    LINE (Left + 1, Top)-(Right - 1, Top), GuiColorBrt
    LINE (Left + 1, Bottom)-(Right - 1, Bottom), GuiColorDrk

    IF DrawArrow THEN
        LINE (Left, Top + 1)-(Left + 5, Top + 1), GuiColorDim
        LINE (Left, Top + 2)-(Left + 2, Top + 4), GuiColorLit
        LINE (Left + 3, Top + 4)-(Left + 5, Top + 2), GuiColorWht
        LINE (Left + 1, Top + 2)-(Left + 4, Top + 2), GuiColorBrt
        LINE (Left + 2, Top + 3)-(Left + 3, Top + 3), GuiColorBrt
    END IF
ELSE 'Vertical
    IF Obj.Total > 0 THEN
        BarOffset = (Gui.Hite - BarHeight) * Obj.Value \ Obj.Total
    END IF

    LINE (Left, Top + 1)-(Left, Bottom - 1), GuiColorDrk
    LINE (Left + 5, Top + 1)-(Left + 5, Bottom - 1), GuiColorLit
    LINE (Left + 1, Top)-(Left + 4, Top), GuiColorDrk
    LINE (Left + 1, Bottom)-(Left + 4, Bottom), GuiColorBrt
    LINE (Left + 1, Top + 1)-(Left + 4, Bottom - 1), GuiColorDim, BF

    Top = Top + BarOffset
    Bottom = Top + BarHeight - 1
    Right = Left + 5

    LINE (Left, Top)-(Left, Bottom), GuiColorLit
    LINE (Right, Top)-(Right, Bottom), GuiColorDim
    LINE (Left + 1, Top - 1)-(Right - 1, Top - 1), GuiColorBrt
    LINE (Left + 1, Bottom + 1)-(Right - 1, Bottom + 1), GuiColorDrk
    LINE (Left + 1, Top)-(Right - 1, Bottom), GuiColorBack, BF

    IF DrawArrow THEN
        LINE (Left, Top + 1)-(Left + 5, Top + 1), GuiColorDim
        LINE (Left, Top + 2)-(Left + 2, Top + 4), GuiColorLit
        LINE (Left + 3, Top + 4)-(Left + 5, Top + 2), GuiColorWht
        LINE (Left + 1, Top + 2)-(Left + 4, Top + 2), GuiColorBrt
        LINE (Left + 2, Top + 3)-(Left + 3, Top + 3), GuiColorBrt
    END IF
END IF

END SUB

SUB Select.Draw (Obj AS SelectType, Gui AS GuiType)

Top = Gui.TopRow
Left = Gui.LeftCol

IF Obj.State THEN
    FOR Count = 0 TO 2
        LINE (Left + Count, Top + Count)-(Left + Count, Top - Count + 5), 9
    NEXT
END IF

IF Gui.Flags AND GuiObjActive THEN Clr = TextColorActive ELSE Clr = TextColorNormal
DrawCharString Obj.Text, Top, Left + 6, Clr

END SUB

FUNCTION StrNum$ (Num AS INTEGER)
StrNum$ = LTRIM$(STR$(Num))
END FUNCTION

SUB TextList.Draw (Obj AS TextListType, Gui AS GuiType, Choices() AS STRING)

Top = Gui.TopRow
Bottom = Gui.TopRow + Gui.Hite - 1
Left = Gui.LeftCol
Right = Gui.LeftCol + Gui.Wdth - 1

'LINE (Left, Top)-(Right, Bottom), GuiColorBack, BF
'LINE (Gui.LeftCol, Top)-(Gui.LeftCol, Bottom), GuiColorRight
'LINE (Right + 1, Top)-(Right + 1, Bottom), GuiColorLeft
'LINE (Left, Gui.TopRow)-(Right, Gui.TopRow), GuiColorBtm
'LINE (Left, Bottom + 1)-(Right, Bottom + 1), GuiColorTop

CharWidth = Right - Left
'Top already set above
FOR Index = 0 TO Obj.Choices - 1
    Clr = TextColorSelect
    IF Index = CurChoice THEN
        LINE (Left, Top)-(Right, Top + 7), GuiColorDim, BF
        IF Gui.Flags AND GuiObjActive THEN Clr = TextColorActive
    END IF
    DrawCharString LEFT$(Choices(Index), TextWidthLen(Choices(Index), CharWidth)), Top + 1, Left + 1, Clr
    Top = Top + 8
NEXT

END SUB

SUB TextPrompt.Draw (Obj AS TextPromptType, Gui AS GuiType)

Top = Gui.TopRow
Bottom = Gui.TopRow + Gui.Hite - 1
Left = Gui.LeftCol
Right = Gui.LeftCol + Gui.Wdth - 2

'LINE (Left, Top)-(Right, Bottom), 2, BF
'LINE (Gui.LeftCol, Top)-(Gui.LeftCol, Bottom), GuiColorRight
'LINE (Right + 1, Top)-(Right + 1, Bottom), GuiColorLeft
'LINE (Left, Gui.TopRow)-(Right, Gui.TopRow), GuiColorBtm
'LINE (Left, Bottom + 1)-(Right, Bottom + 1), GuiColorTop

IF Gui.Flags AND GuiObjActive THEN
    Col = Left + TextWidth(LEFT$(Obj.Text, Obj.CsrPos))
    LINE (Col, Top + 1)-(Col, Bottom - 1), GuiColorWht, BF
END IF

DrawCharString Obj.Text, Top + 2, Left + 1, TextColorSelect

END SUB

FUNCTION TextWidth (Text AS STRING)

FOR Count = 1 TO LEN(RTRIM$(Text))
    Col = Col + FontSizes(ASC(MID$(Text, Count, 1))) + 1
NEXT
TextWidth = Col

END FUNCTION

FUNCTION TextWidthLen (Text AS STRING, Wdth)

FOR Count = 1 TO LEN(RTRIM$(Text))
    Col = Col + FontSizes(ASC(MID$(Text, Count, 1))) + 1
    IF Col > Wdth THEN EXIT FOR
    Length = Length + 1
NEXT
TextWidthLen = Length

END FUNCTION

SUB TitleBar.Draw (Obj AS TextPromptType, Gui AS GuiType)

Top = Gui.TopRow
Left = Gui.LeftCol
Right = Gui.LeftCol + Gui.Wdth - 1
IF Gui.Flags AND GuiObjActive THEN Clr = GuiColorDim ELSE Clr = GuiColorDrk
IF Gui.Flags AND GuiObjActive THEN TxtClr = TextColorActive ELSE TxtClr = TextColorDrk
IF Gui.Wdth > Gui.Hite THEN
    LINE (Left, Top + 3)-(Left, Top + 5), Clr
    LINE (Left + 1, Top + 1)-(Left + 1, Top + 7), Clr
    LINE (Left + 2, Top)-(Right - 2, Top + 8), Clr, BF
    LINE (Right - 1, Top + 1)-(Right - 1, Top + 7), Clr
    LINE (Right, Top + 3)-(Right, Top + 5), Clr

    DrawCharString Obj.Text, Top + 1, Left + 3, TxtClr
ELSE
    Bottom = Gui.TopRow + Gui.Hite - 1
    LINE (Left + 3, Top)-(Left + 5, Top), Clr
    LINE (Left + 1, Top + 1)-(Left + 7, Top + 1), Clr
    LINE (Left, Top + 2)-(Left + 8, Bottom - 2), Clr, BF
    LINE (Left + 1, Bottom - 1)-(Left + 7, Bottom - 1), Clr
    LINE (Left + 3, Bottom)-(Left + 5, Bottom), Clr

    DrawCharStringV Obj.Text, Top + 3, Left + 7, TxtClr
END IF

END SUB

SUB UserWait

'Waste any keys pending in buffer
DO: key$ = INKEY$: LOOP WHILE LEN(key$)

'Wait for next keypress or mouse click
Press = 0
DO
    key$ = INKEY$
    MouseFunction 3
    IF (Regs.Bx AND 1) = 0 THEN Press = 1
LOOP UNTIL LEN(key$) OR (Regs.Bx AND Press)

END SUB

FUNCTION WaitWithMsg$ (Text AS STRING)

LOCATE InfoRow, 1: COLOR 15: PRINT Text; TAB(40);
DO: key$ = INKEY$: LOOP UNTIL LEN(key$)
WaitWithMsg$ = key$

END FUNCTION

SUB WindowBg.Draw (Obj AS ButtonType, Gui AS GuiType)

Obj.Text = ""
GuiBorder.Draw Obj, Gui
IF TestImage(0) <> -1 THEN
    DrawTiles TestImage(), 8, 8, Gui.TopRow + 1, Gui.LeftCol + 1, Gui.Hite - 2, Gui.Wdth - 2
END IF

END SUB

