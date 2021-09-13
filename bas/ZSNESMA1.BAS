DEFINT A-Z
OPTION BASE 0
DECLARE SUB MainMenu ()
DECLARE SUB PageTitle ()
DECLARE SUB PageSceneInfo ()
DECLARE SUB PageViewPalette ()
DECLARE SUB PageViewSprites ()
DECLARE FUNCTION PageFileLoad (PreName$, Filename$)
DECLARE SUB LoadSaveState ()
DECLARE SUB EndProgram ()

DECLARE SUB DrawBplTile (BaseByte&, Bits, PalBase, TopRow, LeftCol, Flip)
DECLARE SUB DrawMode7Tile (BaseByte&, TopRow, LeftCol)
DECLARE SUB ShowSomeTilemap (MapBase&, Plane)
DECLARE SUB ViewVRAM ()
DECLARE SUB ViewTilemap ()
DECLARE SUB PaletteConvert (Palette$)
DECLARE SUB PaletteMergeGUIcolors ()
DECLARE SUB PaletteSet ()
DECLARE SUB PaletteSetGray ()
DECLARE FUNCTION GetFileList$ (FileMask$, FileType)

DECLARE SUB DrawCharString (Chars$, TopRow, LeftCol, FontColor)
DECLARE SUB DrawShadowString (Chars$, TopRow, LeftCol, FontColor, FontShadow)
DECLARE SUB DrawWindowTitle (Chars$, TopRow, LeftCol, Wdth)
DECLARE SUB DrawBorder (TopRow, BtmRow, LeftCol, RiteCol, Mode)
DECLARE SUB List.Draw (MenuChoices$(), TopRow, LeftCol, Hite, Wdth, MenuChoice, LastChoice, BaseChoice, PriorChoice)
DECLARE SUB List.DrawBox (TopRow, LeftCol, Hite, Wdth)
DECLARE SUB List.ReceiveKey (Key$, MenuChoices$(), Hite, MenuChoice, LastChoice, Change)
DECLARE SUB List.ReceiveMouse (Presses, PointerY, Hite, MenuChoice, LastChoice, BaseChoice, PriorChoice, Change)
DECLARE SUB Menu.Draw (MenuChoices$(), TopRow, LeftCol, MenuChoice, PriorChoice)
DECLARE SUB Menu.DrawBox (TopRow, LeftCol, Hite, Wdth)
DECLARE SUB Menu.ParseChoices (Choices$, MenuChoices$(), NumChoice, LongestString)
DECLARE SUB Menu.ReceiveKey (Key$, MenuChoices$(), MenuChoice, Change)
DECLARE SUB Menu.ReceiveMouse (Buttons, PointerY, MenuChoices$(), MenuChoice, Change)
DECLARE SUB AttemptOpen (Filename$, NewFileNum)
DECLARE SUB MouseFunction (Ax)
DECLARE FUNCTION MouseInfo (Buttons, Presses, PointerY, PointerX)
DECLARE FUNCTION PointerInGrid (PointerY, PointerX, TopRow, LeftCol, Hite, Wdth)
DECLARE FUNCTION PointerInArea (PointerY, PointerX, TopRow, LeftCol, Hite, Wdth)
DECLARE FUNCTION StrDim$ (FirstNum, SecondNum)
DECLARE FUNCTION StrTrim$ (FirstNum)
DECLARE FUNCTION StrYesNo$ (FirstNum)

'use the transparent colors of the lower eight palettes
CONST ColorBlack = 0, ColorDark = 16, ColorGray = 32, ColorWhite = 48, FontSize = 8

TYPE SnesInfoType
CycleCount AS INTEGER
VideoMode AS INTEGER '0-7
Brightness AS INTEGER '0-15
SpriteBase AS INTEGER
Scanline AS INTEGER '0-224?
MosaicSize AS INTEGER '0-15 pixelation
MosaicApplied AS INTEGER
Window1Left AS INTEGER '0-255
Window1Right AS INTEGER
Window2Left AS INTEGER
Window2Right AS INTEGER
END TYPE

TYPE PlaneInfoType
Enabled  AS INTEGER
Subscreen AS INTEGER
Colors   AS INTEGER 'If colors is greater than zero, then the plane is active
TileSize AS INTEGER '8/16
TileHeight  AS INTEGER '32/64
TileWidth   AS INTEGER
PixelWidth  AS INTEGER '256/512/1024
PixelHeight AS INTEGER
ScrollX  AS INTEGER '0-2047
ScrollY  AS INTEGER
MapBase  AS LONG '*2048?
TileBase AS LONG '*8192?
Windows  AS INTEGER
END TYPE

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
BP AS INTEGER: SI AS INTEGER: DI AS INTEGER: flags AS INTEGER
Ds AS INTEGER: ES AS INTEGER
END TYPE

DIM SHARED FileError, Regs AS RegisterType, FontBlitCode$, FontSpacing, CallInterruptCode$
DIM SHARED SnesFile$, SaveStateType$, SnesFileNum, SnesPalette AS STRING * 512, PaletteTable(383), ColorMapTable(255)
DIM SHARED SnesInfo AS SnesInfoType, PlanesInfo(3) AS PlaneInfoType, SpriteSizes(1, 1), VideoModeBpls(31)
DIM SHARED SpriteOAM(276), BitmapCache(16384), PlaneBitsBase
REDIM SHARED VRAM(16383) AS LONG
'554 for object attribute memory, the list for up to 128 sprites (SpriteOAM)
'64k for snes video ram, including tiles, sprites, & tilemap arrays (VRAM)
'32k for cache of already translated tiles and sprites (BitmapCache)
'62k for the playfield virtual screen (SceneBuffer)

SCREEN 13
FontSpacing = FontSize

RESTORE FontBlitData
READ CodeBytes: FontBlitCode$ = SPACE$(CodeBytes)
FOR CurChar = 1 TO CodeBytes
  READ Char: MID$(FontBlitCode$, CurChar) = CHR$(Char)
NEXT CurChar
RESTORE VideoModeBpls
FOR Index = 0 TO 31
  READ VideoModeBpls(Index)
NEXT Index

PageTitle
MainMenu
EndProgram

FileErrHandler:
  FileError = ERR
RESUME NEXT

'This is the assembly code that blits transparent fonts to the screen
FontBlitData:
DATA 167,30,6,85,137,229,184,0,240,142,216,184,0,160,142,192,139,118,10,193,230
DATA 3,129,198,110,250,139,94,12,133,219,121,11,41,222,129,195,8,0,49,255,233
DATA 24,0,137,216,191,64,1,247,231,137,199,247,219,129,195,200,0,129,251,8,0
DATA 120,3,187,8,0,129,251,1,0,15,136,86,0,139,86,14,133,210,121,11,137,209
DATA 246,217,129,194,8,0,233,19,0,1,215,48,201,247,218,129,194,64,1,129,250,8
DATA 0,120,3,186,8,0,129,250,1,0,15,136,41,0,136,213,247,218,129,194,64,1,138
DATA 70,16,138,36,70,210,224,136,239,208,228,115,8,170,254,207,117,247,233,5,0
DATA 71,254,207,117,239,1,215,254,203,117,226,93,7,31,202,8,0

CallInterruptData:
DATA 3,202,8,0

SceneInfoLabels:
DATA 30,File,Type,,Video mode,Brightness,Vertical line,Cycle count,Mosaic size,Window 1
DATA Window 2,,Planes,Colors,Enabled,Subscreen,Mosaic,Map size,Tile size,Height
DATA Width,Scroll X,Scroll Y,Modulus X,Modulus Y,Map base,Tile base,Window 1
DATA Window 2,,Sprite sizes,Sprite base

GUIColors:
DATA 0,0,0,100,100,128,192,192,255,255,255,255

VideoModeBpls:
DATA 2,2,2,2, 4,4,2,0, 4,4,0,0, 8,4,0,0, 8,2,0,0, 4,2,0,0, 4,0,0,0, 8,0,0,0

SUB AttemptOpen (Filename$, NewFileNum)

ON ERROR GOTO FileErrHandler: FileError = 0
NewFileNum = FREEFILE
OPEN Filename$ FOR INPUT AS NewFileNum
CLOSE NewFileNum
IF FileError = 0 THEN OPEN Filename$ FOR BINARY AS NewFileNum

ON ERROR GOTO 0
IF FileError THEN NewFileNum = 0

END SUB

SUB CallInterrupt (Interrupt, Regs)

'CALL ABSOLUTE(SADD(CallInterruptCode$))

END SUB

SUB DrawBorder (TopRow, BtmRow, LeftCol, RiteCol, Mode)

ColorFront = ColorGray
ColorShadow = ColorBlack
IF Mode AND 1 THEN SWAP ColorShadow, ColorFront

LINE (LeftCol, TopRow)-(LeftCol, BtmRow), ColorFront
LINE (RiteCol, TopRow)-(RiteCol, BtmRow), ColorShadow
LINE (LeftCol, TopRow)-(RiteCol, TopRow), ColorFront
LINE (LeftCol, BtmRow)-(RiteCol, BtmRow), ColorShadow
IF Mode AND 2 THEN LINE (LeftCol + 1, TopRow + 1)-(RiteCol - 1, BtmRow - 1), ColorDark, BF

END SUB

SUB DrawBplTile (BaseByte&, Bits, PalBase, TopRow, LeftCol, Flip)

IF Bits * 8 + BaseByte& > 65536 THEN EXIT SUB
DEF SEG = VARSEG(VRAM(0))
Index& = VARPTR(VRAM(0)) + BaseByte&
StartRow = 0: EndRow = 7: RowStep = 1
IF Flip AND 2 THEN SWAP StartRow, EndRow: RowStep = -RowStep
HrzFlip = Flip AND 1

FOR CurRow = StartRow TO EndRow STEP RowStep
  p1 = 0: p2 = 0: p3 = 0: p4 = 0: p5 = 0: p6 = 0: p7 = 0: p8 = 0

'Separate each bit from the raw data left to right (pixels are reversed);
'Then if is set, OR BitShift to the pixel until we get full pixel depth.
  BitShift = 1
  SubIndex& = Index&
  FOR Plane = 0 TO Bits - 1 STEP 2
    Byte = PEEK(SubIndex&)
    IF Byte AND 128 THEN p1 = p1 OR BitShift
    IF Byte AND 64 THEN p2 = p2 OR BitShift
    IF Byte AND 32 THEN p3 = p3 OR BitShift
    IF Byte AND 16 THEN p4 = p4 OR BitShift
    IF Byte AND 8 THEN p5 = p5 OR BitShift
    IF Byte AND 4 THEN p6 = p6 OR BitShift
    IF Byte AND 2 THEN p7 = p7 OR BitShift
    IF Byte AND 1 THEN p8 = p8 OR BitShift
    BitShift = BitShift * 2
    Byte = PEEK(SubIndex& + 1)
    IF Byte AND 128 THEN p1 = p1 OR BitShift
    IF Byte AND 64 THEN p2 = p2 OR BitShift
    IF Byte AND 32 THEN p3 = p3 OR BitShift
    IF Byte AND 16 THEN p4 = p4 OR BitShift
    IF Byte AND 8 THEN p5 = p5 OR BitShift
    IF Byte AND 4 THEN p6 = p6 OR BitShift
    IF Byte AND 2 THEN p7 = p7 OR BitShift
    IF Byte AND 1 THEN p8 = p8 OR BitShift
    BitShift = BitShift * 2
    SubIndex& = SubIndex& + 16
  NEXT Plane
  Index& = Index& + 2
'Draw all eight pixels to the screen
  Row = TopRow + CurRow
  IF HrzFlip THEN
    PSET (LeftCol + 7, Row), p1 + PalBase
    PSET (LeftCol + 6, Row), p2 + PalBase
    PSET (LeftCol + 5, Row), p3 + PalBase
    PSET (LeftCol + 4, Row), p4 + PalBase
    PSET (LeftCol + 3, Row), p5 + PalBase
    PSET (LeftCol + 2, Row), p6 + PalBase
    PSET (LeftCol + 1, Row), p7 + PalBase
    PSET (LeftCol, Row), p8 + PalBase
  ELSE
    PSET (LeftCol, Row), p1 + PalBase
    PSET (LeftCol + 1, Row), p2 + PalBase
    PSET (LeftCol + 2, Row), p3 + PalBase
    PSET (LeftCol + 3, Row), p4 + PalBase
    PSET (LeftCol + 4, Row), p5 + PalBase
    PSET (LeftCol + 5, Row), p6 + PalBase
    PSET (LeftCol + 6, Row), p7 + PalBase
    PSET (LeftCol + 7, Row), p8 + PalBase
  END IF
NEXT CurRow

END SUB

SUB DrawCharString (Chars$, TopRow, LeftCol, ColorFront)

IF LEN(FontBlitCode$) = 0 THEN EXIT SUB
Row = TopRow * FontSpacing: Col = LeftCol * FontSpacing

DEF SEG = VARSEG(FontBlitCode$)
FOR CurChar = 1 TO LEN(Chars$)
 '-!-parameters are passed in reverse order-!-
 CALL ABSOLUTE(BYVAL ColorFront, BYVAL Col, BYVAL Row, BYVAL ASC(MID$(Chars$, CurChar, 1)), SADD(FontBlitCode$))
 Col = Col + 8
NEXT CurChar

END SUB

SUB DrawMode7Tile (BaseByte&, TopRow, LeftCol)

IF 65 + BaseByte& > 65535 THEN EXIT SUB
DEF SEG = VARSEG(VRAM(0))
Index& = VARPTR(VRAM(0)) + BaseByte& + 1

FOR CurRow = 0 TO 7
  Row = TopRow + CurRow
  'Draw all eight pixels to the screen
  PSET (LeftCol, Row), PEEK(Index&)
  PSET (LeftCol + 1, Row), PEEK(Index& + 2)
  PSET (LeftCol + 2, Row), PEEK(Index& + 4)
  PSET (LeftCol + 3, Row), PEEK(Index& + 6)
  PSET (LeftCol + 4, Row), PEEK(Index& + 8)
  PSET (LeftCol + 5, Row), PEEK(Index& + 10)
  PSET (LeftCol + 6, Row), PEEK(Index& + 12)
  PSET (LeftCol + 7, Row), PEEK(Index& + 14)
  Index& = Index& + 16
NEXT CurRow

END SUB

SUB DrawOutline (TopRow, BtmRow, LeftCol, RiteCol)

'13107 26214 -13108 -26215
LINE (LeftCol, TopRow)-(RiteCol, BtmRow), 15, B, BitMask

END SUB

SUB DrawShadowString (Chars$, TopRow, LeftCol, ColorFront, ColorShadow)

FontSpacing = 1
DrawCharString Chars$, TopRow * 8 + 1, LeftCol * 8 + 1, ColorShadow
FontSpacing = FontSize
DrawCharString Chars$, TopRow, LeftCol, ColorFront

END SUB

SUB DrawWindowTitle (Chars$, TopRow, LeftCol, Wdth)

RealTopRow = TopRow * 8 - 1
RealLeftCol = LeftCol * 8 - 1
RealBtmRow = RealTopRow + 9
RealRiteCol = RealLeftCol + Wdth * 8 + 1

LINE (RealLeftCol, RealTopRow)-(RealRiteCol, RealBtmRow), ColorBlack, BF
DrawCharString Chars$, TopRow, LeftCol, ColorWhite

END SUB

SUB EndProgram

WIDTH 80, 25
COLOR 7, 0
CLS

PRINT "See ya..."

END

END SUB

'[IM]
FUNCTION GetFileList$ (FileMask$, FileType) STATIC
    
  DIM DTA AS STRING * 44

  '-----  Set up our own DTA so we don't destroy COMMAND$
  Regs.Ax = &H1A00                   'Set DTA function
  Regs.Dx = VARPTR(DTA)              'DS:DX points to our DTA
  Regs.Ds = -1                       'Use current value for DS
  CALL InterruptX(&H21, Regs, Regs)  'Do the interrupt
    
  '-----  Check to see if this is First or Next
  IF LEN(FileMask$) THEN             'FileMask$ isn't null, so FindFirst
    FileSpecZ$ = FileMask$ + CHR$(0) 'Make FileMask$ into an ASCIIZ string
    Regs.Ax = &H4E00                 'Perform a FindFirst
    Regs.Cx = FileType               'Only look for normal files
    Regs.Dx = SADD(FileSpecZ$)       'DS:DX points to ASCIIZ file
    Regs.Ds = -1                     'Use current DS
  ELSE                               'We have a null FileMask$,
    Regs.Ax = &H4F00                 'so FindNext
  END IF
    
  CALL InterruptX(&H21, Regs, Regs)  'Do the interrupt
    
  '-----  Return file name or null
  IF Regs.flags AND 1 THEN           'No files found
    GetFileList$ = ""                'Return null string
  ELSE
    CurChar = INSTR(31, DTA, CHR$(0))'Get the filename found
    GetFileList$ = MID$(DTA, 31, CurChar - 31)
  END IF  'It's an ASCIIZ string starting at offset 30 of the DTA

END FUNCTION

SUB GrabTile
'makes and returns a pointer to a converted tile for new tiles
'Also checks to see if the wanted tile already exists in the cache; if it
'does, then it will simply return the pointer to the cache bitmap.
END SUB

SUB List.Draw (MenuChoices$(), TopRow, LeftCol, Hite, Wdth, MenuChoice, LastChoice, BaseChoice, PriorChoice)

MouseFunction 2

IF LastChoice > UBOUND(MenuChoices$) THEN LastChoice = UBOUND(MenuChoices$)
IF MenuChoice < BaseChoice THEN
  BaseChoice = MenuChoice: PriorChoice = -1
ELSEIF MenuChoice >= BaseChoice + Hite THEN
  BaseChoice = MenuChoice - Hite + 1: PriorChoice = -1
END IF

RealLeftCol = LeftCol * 8
RealRiteCol = RealLeftCol + Wdth * 8 - 1
IF PriorChoice < 0 THEN
  FOR CurChoice = BaseChoice TO BaseChoice + Hite - 1
    GOSUB DrawListChoice
  NEXT CurChoice
ELSE
  CurChoice = PriorChoice: GOSUB DrawListChoice
  CurChoice = MenuChoice: GOSUB DrawListChoice
END IF
PriorChoice = MenuChoice

MouseFunction 1

EXIT SUB

DrawListChoice:
  Row = CurChoice - BaseChoice: IF Row < 0 OR Row >= Hite THEN RETURN
  RealTopRow = (Row + TopRow) * 8: RealBtmRow = RealTopRow + 7
  IF CurChoice = MenuChoice THEN MenuColor = ColorWhite: BackColor = ColorGray ELSE MenuColor = ColorGray: BackColor = ColorDark
  LINE (RealLeftCol, RealTopRow)-(RealRiteCol, RealBtmRow), BackColor, BF
  IF CurChoice < 0 OR CurChoice > LastChoice THEN RETURN
  DrawCharString LEFT$(MenuChoices$(CurChoice), Wdth), TopRow + Row, LeftCol, MenuColor
RETURN

END SUB

SUB List.DrawBox (TopRow, LeftCol, Hite, Wdth)

RealTopRow = TopRow * 8 - 2
RealLeftCol = LeftCol * 8 - 2
RealBtmRow = RealTopRow + Hite * 8 + 3
RealRiteCol = RealLeftCol + Wdth * 8 + 3

LINE (RealLeftCol, RealTopRow)-(RealLeftCol, RealBtmRow), ColorBlack, B
LINE (RealRiteCol, RealTopRow)-(RealRiteCol, RealBtmRow), ColorGray, B
LINE (RealLeftCol, RealTopRow)-(RealRiteCol, RealTopRow), ColorBlack, B
LINE (RealLeftCol, RealBtmRow)-(RealRiteCol, RealBtmRow), ColorGray, B
LINE (RealLeftCol + 1, RealTopRow + 1)-(RealRiteCol - 1, RealBtmRow - 1), ColorDark, BF

END SUB

SUB List.ReceiveKey (Key$, MenuChoices$(), Hite, MenuChoice, LastChoice, Change)

TempKey$ = UCASE$(Key$)
SELECT CASE TempKey$
CASE CHR$(0) + "H": NewChoice = MenuChoice - 1
CASE CHR$(0) + "P": NewChoice = MenuChoice + 1
CASE CHR$(0) + "G": NewChoice = 0
CASE CHR$(0) + "O": NewChoice = LastChoice
CASE CHR$(0) + "I": NewChoice = MenuChoice - Hite
CASE CHR$(0) + "Q": NewChoice = MenuChoice + Hite
CASE CHR$(13): Change = 2: EXIT SUB
CASE ELSE: EXIT SUB
END SELECT

IF NewChoice < 0 THEN NewChoice = 0 ELSE IF NewChoice > LastChoice THEN NewChoice = LastChoice: IF LastChoice < 0 THEN EXIT SUB
IF NewChoice <> MenuChoice THEN MenuChoice = NewChoice: Change = 1

END SUB

SUB List.ReceiveMouse (Presses, PointerY, Hite, MenuChoice, LastChoice, BaseChoice, PriorChoice, Change)

IF Presses AND 1 THEN
  NewChoice = PointerY + BaseChoice
  IF NewChoice > LastChoice THEN NewChoice = LastChoice ELSE IF NewChoice < 0 THEN NewChoice = 0
  IF NewChoice = MenuChoice THEN Change = 2 ELSE MenuChoice = NewChoice: Change = 1
ELSEIF Presses AND 2 THEN
  SELECT CASE PointerY
  CASE 0: NewChoice = BaseChoice - Hite
  CASE 1: NewChoice = BaseChoice - 1
  CASE Hite - 1: NewChoice = BaseChoice + Hite
  CASE Hite - 2: NewChoice = BaseChoice + 1
  CASE ELSE: EXIT SUB
  END SELECT
  Temp = LastChoice - Hite + 1: IF NewChoice > Temp THEN NewChoice = Temp
  IF NewChoice < 0 THEN NewChoice = 0
  IF NewChoice <> BaseChoice THEN
    BaseChoice = NewChoice: Change = 1: PriorChoice = -1
    IF MenuChoice < BaseChoice THEN MenuChoice = BaseChoice ELSE Temp = BaseChoice + Hite - 1: IF MenuChoice > Temp THEN MenuChoice = Temp
  END IF
END IF

END SUB

SUB LoadSaveState

'loads various elements from the savestate, including VRAM tiles, tilemaps,
'certain video registers, the palette, and sprites.

'DrawShadowString "Loading save state", 24, 0, ColorWhite, ColorBlack

LoadSaveState.ZSNES:
'SaveState type
SEEK SnesFileNum, 1: Label$ = INPUT$(40, SnesFileNum)
SaveStateType$ = Label$
IF LEFT$(Label$, 21) <> "ZSNES Save State File" THEN EXIT SUB
IF LOF(SnesFileNum) < 199698 THEN EXIT SUB
CurChar = INSTR(SaveStateType$, CHR$(26))
IF CurChar THEN SaveStateType$ = LEFT$(SaveStateType$, CurChar - 1)

'Brightness, Video mode, colors
SEEK SnesFileNum, 29: Chars$ = INPUT$(2, SnesFileNum)
  SnesInfo.CycleCount = ASC(Chars$)
  SnesInfo.Scanline = ASC(MID$(Chars$, 2))
SEEK SnesFileNum, 79: SnesInfo.Brightness = ASC(INPUT$(1, SnesFileNum))
SEEK SnesFileNum, 103: SnesInfo.VideoMode = ASC(INPUT$(1, SnesFileNum))
SEEK SnesFileNum, 105: Chars$ = INPUT$(3, SnesFileNum)
Char = ASC(Chars$)
CurChar = (SnesInfo.VideoMode AND 7) * 4: PlaneBitsBase = CurChar
Mask = 1
FOR Index = 0 TO 3
  IF VideoModeBpls(CurChar) THEN PlanesInfo(Index).Colors = 2 ^ VideoModeBpls(CurChar) ELSE PlanesInfo(Index).Colors = 0
  IF Char AND Mask THEN PlanesInfo(Index).TileSize = 16 ELSE PlanesInfo(Index).TileSize = 8
  CurChar = CurChar + 1: Mask = Mask * 2
NEXT Index
SnesInfo.MosaicApplied = ASC(MID$(Chars$, 2, 1))
SnesInfo.MosaicSize = ASC(MID$(Chars$, 3, 1))

'Tilemap sizes, addresses
SEEK SnesFileNum, 109: Chars$ = (INPUT$(8, SnesFileNum))
CurChar = 1
FOR Index = 0 TO 3
  PlanesInfo(Index).MapBase = ASC(MID$(Chars$, CurChar, 1)) * 256&
  CurChar = CurChar + 2
NEXT Index
SEEK SnesFileNum, 140: Chars$ = (INPUT$(4, SnesFileNum))
FOR Index = 0 TO 3
  Char = ASC(MID$(Chars$, Index + 1, 1))
  IF Char AND 1 THEN PlanesInfo(Index).TileHeight = 64 ELSE PlanesInfo(Index).TileHeight = 32
  IF Char AND 2 THEN PlanesInfo(Index).TileWidth = 64 ELSE PlanesInfo(Index).TileWidth = 32
NEXT Index
IF SnesInfo.VideoMode = 7 THEN
  PlanesInfo(0).TileHeight = 128
  PlanesInfo(0).TileWidth = 128
  PlanesInfo(0).MapBase = 0
END IF
SEEK SnesFileNum, 145: Chars$ = (INPUT$(8, SnesFileNum))
CurChar = 1
FOR Index = 0 TO 3
  PlanesInfo(Index).TileBase = ASC(MID$(Chars$, CurChar, 1)) * 256&
  CurChar = CurChar + 2
NEXT Index
SEEK SnesFileNum, 181: Chars$ = INPUT$(2, SnesFileNum)
Char = ASC(Chars$): Char2 = ASC(MID$(Chars$, 2, 1)): Mask = 1
FOR Index = 0 TO 3
  IF Char AND Mask THEN PlanesInfo(Index).Enabled = 1 ELSE PlanesInfo(Index).Enabled = 0
  IF Char2 AND Mask THEN PlanesInfo(Index).Subscreen = 1 ELSE PlanesInfo(Index).Subscreen = 0
  PlanesInfo(Index).PixelWidth = PlanesInfo(Index).TileWidth * PlanesInfo(Index).TileSize
  PlanesInfo(Index).PixelHeight = PlanesInfo(Index).TileHeight * PlanesInfo(Index).TileSize
  Mask = Mask * 2
NEXT Index

'Scroll $97
SEEK SnesFileNum, 152: Chars$ = INPUT$(20, SnesFileNum)
CurChar = 1
FOR Index = 0 TO 3
  PlanesInfo(Index).ScrollX = CVI(MID$(Chars$, CurChar, 2))
  PlanesInfo(Index).ScrollY = CVI(MID$(Chars$, CurChar + 10, 2))
  CurChar = CurChar + 2
NEXT Index

'OAM 218h
SEEK SnesFileNum, 537: Chars$ = INPUT$(544, SnesFileNum)
Index = 0
FOR CurChar = 1 TO 544 STEP 2
  SpriteOAM(Index) = CVI(MID$(Chars$, CurChar, 2)): Index = Index + 1
NEXT CurChar

'CGRAM 618-817h
SEEK SnesFileNum, 1561: SnesPalette$ = INPUT$(512, SnesFileNum)
PaletteConvert SnesPalette$
PaletteMergeGUIcolors
PaletteSet

'VRAM 20C13-30C12h
SEEK SnesFileNum, 134164
Index = 0
FOR CharPiece = 0 TO 31
  Chars$ = INPUT$(2048, SnesFileNum)
  FOR CurChar = 1 TO 2048 STEP 4
    VRAM(Index) = CVL(MID$(Chars$, CurChar, 4)): Index = Index + 1
  NEXT CurChar
NEXT CharPiece

END SUB

SUB MainMenu

REDIM MainMenuChoices$(0)
Menu.ParseChoices "Load game_Scene info_View scene_View VRAM_Edit WRAM_Palette_Sprites_Exit_", MainMenuChoices$(), NumChoice, LongestString

'remove
Menu.DrawBox 15, 20, 5, 14
DrawCharString ">Hello World!<", 15, 20, 92
DrawCharString "> Look at me <", 17, 20, 166
DrawCharString ">Sweet dreams<", 19, 20, 246

MenuChoice = 0: PriorChoice = MenuChoice
Menu.DrawBox 1, 1, NumChoice, LongestString
Menu.Draw MainMenuChoices$(), 1, 1, MenuChoice, -1
MouseFunction 1

DO
  Key$ = INKEY$
  IF LEN(Key$) THEN
    IF Key$ = CHR$(27) THEN EXIT DO
    Menu.ReceiveKey Key$, MainMenuChoices$(), MenuChoice, Change
  ELSEIF MouseInfo(Buttons, Presses, PointerY, PointerX) THEN
    IF PointerInGrid(PointerY, PointerX, 1, 1, NumChoice, LongestString) THEN
      Menu.ReceiveMouse Presses, PointerY, MainMenuChoices$(), MenuChoice, Change
    END IF
  END IF
 
  IF Change THEN Menu.Draw MainMenuChoices$(), 1, 1, MenuChoice, PriorChoice: Change = Change AND -2
  IF Change > 1 THEN Change = 0: MouseFunction 2: GOSUB MainMenuDoChoice
LOOP

EXIT SUB

MainMenuDoChoice:
  SELECT CASE MenuChoice
  CASE 0
    NewFileNum = PageFileLoad(SnesFile$, Filename$)
    IF NewFileNum THEN
      'CLOSE SnesFileNum
      SnesFileNum = NewFileNum
      SnesFile$ = Filename$
      LoadSaveState
      CLOSE SnesFileNum
      PageSceneInfo
      MenuChoice = 2
    END IF
  CASE 1
    PageSceneInfo
  CASE 2
    ViewTilemap
  CASE 3
    ViewVRAM
  CASE 4
    LOCATE 13, 1: PRINT "Sorry, not made yet";
    DO: LOOP UNTIL LEN(INKEY$)
    LOCATE 13, 1: PRINT SPC(19);
  CASE 5
    PageViewPalette
  CASE 6
    PageViewSprites
  CASE 7: EXIT SUB
  END SELECT
  MouseFunction 1
RETURN

END SUB

SUB MakeTiledBitmap
'makes a bitmap from a given tile source, with height, width, and bit depth
END SUB

SUB Menu.Draw (MenuChoices$(), TopRow, LeftCol, MenuChoice, PriorChoice)

MouseFunction 2

LastChoice = UBOUND(MenuChoices$)
IF PriorChoice < 0 THEN
  FOR CurChoice = 0 TO LastChoice
    GOSUB DrawMenuChoice
  NEXT CurChoice
ELSE
  CurChoice = PriorChoice: GOSUB DrawMenuChoice
  CurChoice = MenuChoice: GOSUB DrawMenuChoice
END IF
PriorChoice = MenuChoice

MouseFunction 1

EXIT SUB

DrawMenuChoice:
  IF CurChoice = MenuChoice THEN MenuColor = ColorWhite ELSE MenuColor = ColorGray
  IF CurChoice > LastChoice THEN RETURN
  'LOCATE TopRow + 1 + CurChoice, LeftCol + 1
  'PRINT MenuChoices$(CurChoice);
  DrawCharString MenuChoices$(CurChoice), TopRow + CurChoice, LeftCol, MenuColor
RETURN

END SUB

SUB Menu.DrawBox (TopRow, LeftCol, Hite, Wdth)

RealTopRow = TopRow * 8 - 4
RealLeftCol = LeftCol * 8 - 4
RealBtmRow = RealTopRow + Hite * 8 + 7
RealRiteCol = RealLeftCol + Wdth * 8 + 7

DrawBorder RealTopRow, RealBtmRow, RealLeftCol, RealRiteCol, 2

END SUB

'Given a single string with several choices in it, each separated by a "_",
'it will parse them into a string array. It also returns the length of the
'longest string found.
SUB Menu.ParseChoices (Choices$, MenuChoices$(), NumChoice, LongestString)

NumChoice = 0
CurChar = 1
DO
  NextChar = INSTR(CurChar, Choices$, "_"): IF NextChar < 1 THEN EXIT DO
  NumChoice = NumChoice + 1: CurChar = NextChar + 1
LOOP

IF NumChoice < 1 THEN REDIM MenuChoices$(0): EXIT SUB
REDIM MenuChoices$(NumChoice - 1)

LongestString = 0
NumChoice = 0
CurChar = 1
DO
  NextChar = INSTR(CurChar, Choices$, "_"): IF NextChar < 1 THEN EXIT DO
  ChoiceLen = NextChar - CurChar
  IF ChoiceLen > LongestString THEN LongestString = ChoiceLen
  MenuChoices$(NumChoice) = MID$(Choices$, CurChar, ChoiceLen)
  NumChoice = NumChoice + 1: CurChar = NextChar + 1
LOOP

END SUB

SUB Menu.ReceiveKey (Key$, MenuChoices$(), MenuChoice, Change)

LastChoice = UBOUND(MenuChoices$)

TempKey$ = UCASE$(Key$)
SELECT CASE TempKey$
CASE CHR$(0) + "H": Change = 1: IF MenuChoice <= 0 THEN MenuChoice = LastChoice ELSE MenuChoice = MenuChoice - 1
CASE CHR$(0) + "P": Change = 1: IF MenuChoice >= LastChoice THEN MenuChoice = 0 ELSE MenuChoice = MenuChoice + 1
CASE CHR$(13): Change = 2
CASE " " TO "ÿ"
  CurChoice = MenuChoice
  FOR Index = 0 TO LastChoice - 1
    IF CurChoice >= LastChoice THEN CurChoice = 0 ELSE CurChoice = CurChoice + 1
    IF TempKey$ = UCASE$(LEFT$(MenuChoices$(CurChoice), 1)) THEN
      MenuChoice = CurChoice: Change = 1: EXIT FOR
    END IF
  NEXT Index
END SELECT

END SUB

SUB Menu.ReceiveMouse (Presses, PointerY, MenuChoices$(), MenuChoice, Change)

LastChoice = UBOUND(MenuChoices$)
IF PointerY <> MenuChoice AND PointerY >= 0 AND PointerY <= LastChoice THEN MenuChoice = PointerY: Change = 1
IF Presses THEN Change = 2

END SUB

SUB MouseFunction (Ax)

Regs.Bx = 0: Regs.Cx = 0: Regs.Dx = 0: Regs.Ax = Ax
CALL InterruptX(&H33, Regs, Regs)

END SUB

FUNCTION MouseInfo (Buttons, Presses, PointerY, PointerX)

STATIC OldPointerY, OldPointerX, OldButtons

Regs.Ax = 3
CALL InterruptX(&H33, Regs, Regs)
PointerY = Regs.Dx
PointerX = Regs.Cx \ 2
Buttons = Regs.Bx

IF OldPointerY <> PointerY OR OldPointerX <> PointerX THEN
  OldPointerY = PointerY: OldPointerX = PointerX: t = 3: MouseInfo = 1
END IF
IF Buttons > OldButtons THEN MouseInfo = 2: Presses = Buttons XOR OldButtons ELSE Presses = 0
OldButtons = Buttons

END FUNCTION

FUNCTION PageFileLoad (PreName$, Filename$)

Filename$ = PreName$
FileMask$ = "*.*"
REDIM MenuChoices$(99)
GOSUB FileLoadPage.Draw
MouseFunction 1

GOSUB FileLoadPage.GetFileList
Change = 1: PriorChoice = -1
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE ""
    IF MouseInfo(0, Presses, PointerY, PointerX) > 1 THEN
      IF PointerInGrid(PointerY, PointerX, 5, 26, 17, 12) THEN
        List.ReceiveMouse Presses, PointerY, 17, MenuChoice, LastChoice, BaseChoice, PriorChoice, Change
      END IF
    END IF
  CASE CHR$(27): EXIT DO 'Clear screen
  CASE CHR$(8): IF LEN(Filename$) THEN Filename$ = LEFT$(Filename$, LEN(Filename$) - 1)
  CASE " " TO "ÿ": IF LEN(Filename$) < 128 THEN Filename$ = Filename$ + Key$
  CASE IS > "": List.ReceiveKey Key$, MenuChoices$(), 17, MenuChoice, LastChoice, Change
  END SELECT
 
  IF Change > 1 THEN
    ON ERROR GOTO FileErrHandler: FileError = 0
    CHDIR Filename$
    IF FileError THEN
      AttemptOpen Filename$, NewFileNum
      IF NewFileNum THEN PageFileLoad = NewFileNum: EXIT DO
    ELSE
      ON ERROR GOTO 0
      GOSUB FileLoadPage.GetFileList
      PriorChoice = -1
    END IF
  END IF
  IF Change THEN
    List.Draw MenuChoices$(), 5, 26, 17, 12, MenuChoice, LastChoice, BaseChoice, PriorChoice
    Filename$ = MenuChoices$(MenuChoice)
    Change = 0
  END IF
  'remove
  LOCATE 12, 1: PRINT Filename$; TAB(20);
  LOCATE 13, 1: PRINT MenuChoices$(MenuChoice); TAB(20);
  LOCATE 14, 1: PRINT MenuChoice
LOOP

'redraw background

EXIT FUNCTION

FileLoadPage.Draw:
  Menu.DrawBox 1, 25, 23, 14
  DrawWindowTitle "Load file", 1, 25, 14

  List.DrawBox 3, 26, 1, 12
  List.DrawBox 5, 26, 17, 12
RETURN

FileLoadPage.GetFileList:
  Label$ = GetFileList(FileMask$, 20)
  FOR CurChoice = 0 TO 99
    Label$ = LCASE$(GetFileList("", 0))
    IF LEN(Label$) = 0 THEN EXIT FOR
    MenuChoices$(CurChoice) = LCASE$(Label$)
  NEXT
  LastChoice = CurChoice - 1
  BaseChoice = 0
  IF MenuChoices$(0) = ".." AND LastChoice > 0 THEN MenuChoice = 1 ELSE MenuChoice = 0
RETURN

END FUNCTION

SUB PageSceneInfo

Menu.DrawBox 1, 1, 23, 38
IF SnesFileNum = 0 THEN Chars$ = " [no savestate loaded]"
DrawWindowTitle "Scene info" + Chars$, 1, 1, 38
List.DrawBox 3, 1, 20, 38
MouseFunction 1

RESTORE SceneInfoLabels: READ LastChoice
REDIM MenuChoices$(LastChoice)
GOSUB SceneInfo.MakeList
Change = 1: MenuChoice = 0: PriorChoice = -1
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE ""
    IF MouseInfo(0, Presses, PointerY, PointerX) > 1 THEN
      IF PointerInGrid(PointerY, PointerX, 3, 1, 20, 38) THEN
        List.ReceiveMouse Presses, PointerY, 20, MenuChoice, LastChoice, BaseChoice, PriorChoice, Change
      END IF
    END IF
  CASE CHR$(27), CHR$(13): EXIT DO
  CASE ELSE: List.ReceiveKey Key$, MenuChoices$(), 20, MenuChoice, LastChoice, Change
  END SELECT

  IF Change THEN
    List.Draw MenuChoices$(), 3, 1, 20, 38, MenuChoice, LastChoice, BaseChoice, PriorChoice
    Change = 0
  END IF
LOOP

'redraw background
'DEF SEG = &HA000: BLOAD "zsnesmap.pic", 0

EXIT SUB

SceneInfo.MakeList:
  DO
    READ Label$
    IF LEN(Label$) = 0 OR NumChoice > LastChoice THEN
      FOR CurChoice = MenuChoice TO NumChoice - 1
        MenuChoices$(CurChoice) = MenuChoices$(CurChoice) + SPACE$(LongestString - LEN(MenuChoices$(CurChoice)) + 1)
      NEXT CurChoice
      MenuChoice = NumChoice + 1
      LongestString = 0
      IF NumChoice > LastChoice THEN EXIT DO
    ELSEIF LEN(Label$) > LongestString THEN
      LongestString = LEN(Label$)
    END IF
    MenuChoices$(NumChoice) = Label$
    NumChoice = NumChoice + 1
  LOOP

  MenuChoice = 0
  Label$ = SnesFile$: GOSUB SceneInfo.AddLine
  Label$ = SaveStateType$: GOSUB SceneInfo.AddLine
  Label$ = StrTrim(SnesInfo.VideoMode): GOSUB SceneInfo.AddLine
  Label$ = StrTrim(SnesInfo.Brightness): IF SnesInfo.Brightness >= 15 THEN Label$ = Label$ + " (max)"
    GOSUB SceneInfo.AddLine
  Label$ = StrTrim(SnesInfo.Scanline): GOSUB SceneInfo.AddLine
  Label$ = StrTrim(SnesInfo.CycleCount): GOSUB SceneInfo.AddLine
  Label$ = StrTrim(SnesInfo.MosaicSize): GOSUB SceneInfo.AddLine
  Label$ = StrTrim(SnesInfo.Window1Left) + "-" + StrTrim(SnesInfo.Window1Right): GOSUB SceneInfo.AddLine
  Label$ = StrTrim(SnesInfo.Window2Left) + "-" + StrTrim(SnesInfo.Window2Right): GOSUB SceneInfo.AddLine
  IF SnesInfo.VideoMode = 7 THEN Mask = -1 ELSE Mask = 2047
  FOR CurChoice = 0 TO 16
    Label$ = SPACE$(28)
    CurChar = 1
    FOR Index = 0 TO 3
      SELECT CASE CurChoice
      CASE 0: Chars$ = "(" + StrTrim(Index) + ")"
      CASE 1: Chars$ = StrTrim(PlanesInfo(Index).Colors)'VideoModeColors
      CASE 2: Chars$ = StrYesNo(PlanesInfo(Index).Enabled)
      CASE 3: Chars$ = StrYesNo(PlanesInfo(Index).Subscreen)
      CASE 4: Chars$ = StrYesNo(SnesInfo.MosaicApplied AND 2 ^ Index)
      CASE 5: Chars$ = StrDim(PlanesInfo(Index).TileHeight, PlanesInfo(Index).TileHeight)
      CASE 6: Chars$ = StrDim(PlanesInfo(Index).TileSize, PlanesInfo(Index).TileSize)
      CASE 7: Chars$ = StrTrim(PlanesInfo(Index).PixelHeight)
      CASE 8: Chars$ = StrTrim(PlanesInfo(Index).PixelWidth)
      CASE 9: Chars$ = StrTrim(PlanesInfo(Index).ScrollX AND Mask)
      CASE 10: Chars$ = StrTrim(PlanesInfo(Index).ScrollY AND Mask)
      CASE 11: Chars$ = StrTrim(PlanesInfo(Index).ScrollX AND PlanesInfo(Index).PixelWidth - 1)
      CASE 12: Chars$ = StrTrim(PlanesInfo(Index).ScrollY AND PlanesInfo(Index).PixelHeight - 1)
      CASE 13: Chars$ = LTRIM$(STR$(PlanesInfo(Index).MapBase))
      CASE 14: Chars$ = LTRIM$(STR$(PlanesInfo(Index).TileBase))
      CASE 15, 16
        IF CurChoice = 15 THEN Mask = 1 ELSE Mask = 4
        IF PlanesInfo(Index).Windows AND Mask THEN
          IF PlanesInfo(Index).Windows AND Mask * 2 THEN Chars$ = "in" ELSE Chars$ = "out"
        ELSE
          Chars$ = "."
        END IF
      END SELECT
      MID$(Label$, CurChar) = Chars$
      CurChar = CurChar + 7
    NEXT Index
    GOSUB SceneInfo.AddLine
  NEXT CurChoice
  Label$ = StrDim(SpriteSizes(0, 0), SpriteSizes(0, 1)) + ", " + StrDim(SpriteSizes(1, 0), SpriteSizes(1, 1)): GOSUB SceneInfo.AddLine
  Label$ = StrTrim(SnesInfo.SpriteBase): GOSUB SceneInfo.AddLine
RETURN

SceneInfo.AddLine:
  IF MenuChoice > LastChoice THEN RETURN
  MenuChoices$(MenuChoice) = MenuChoices$(MenuChoice) + RTRIM$(Label$)
  MenuChoice = MenuChoice + 1
  IF MenuChoice > LastChoice THEN RETURN
  IF LEN(MenuChoices$(MenuChoice)) = 0 THEN MenuChoice = MenuChoice + 1
RETURN

END SUB

SUB PageTitle

AttemptOpen "zsnesmap.pal", 0
IF FileError = 0 THEN
  SnesPalette$ = INPUT$(512, 1)
  PaletteConvert SnesPalette$
  CLOSE 1
END IF
PaletteMergeGUIcolors
PaletteSet

ON ERROR GOTO FileErrHandler: FileError = 0
DEF SEG = &HA000: BLOAD "zsnesmap.pic", 0
ON ERROR GOTO 0

Menu.DrawBox 9, 7, 6, 26
DrawShadowString "Ver 0.0 for Qbasic, by FDwR, Aug 5, 1998", 0, 0, ColorWhite, ColorBlack
DrawCharString "ZSNES", 10, 9, ColorWhite', ColorBlack
DrawShadowString "Savestate Viewer", 10, 15, ColorGray, ColorBlack
DrawCharString "Compatible with ZSNES .4", 12, 8, ColorGray
DrawCharString "Or savestates type .6", 13, 10, ColorGray
DrawShadowString "Press whatever key you want to continue", 24, 0, ColorWhite, ColorBlack
IF FileError THEN
  Menu.DrawBox 20, 7, 1, 26
  DrawShadowString "Could not load background?", 20, 7, ColorWhite, ColorBlack
END IF

MouseFunction 0: MouseFunction 1

DO: LOOP UNTIL LEN(INKEY$) OR MouseInfo(0, 0, 0, 0) > 1

MouseFunction 2
COLOR 48
'DEF SEG = &HA000: BLOAD "zsnesmap.pic", 0

END SUB

SUB PageViewPalette

Menu.DrawBox 1, 1, 23, 38
DrawWindowTitle "View palette", 1, 1, 38
GOSUB ViewPal.DrawColors
MouseFunction 1

CurColor = 1: LastColor = 255
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE ""
    IF MouseInfo(0, Presses, PointerY, PointerX) THEN
      IF Presses THEN EXIT DO
      IF PointerInArea(PointerY, PointerX, TopRow, LeftCol, BtmRow, RiteCol) THEN
        NewColor = (PointerY \ Hite) * 16 + PointerX \ Wdth
      END IF
    END IF
  CASE CHR$(27), CHR$(13): EXIT DO
  CASE CHR$(0) + "H": NewColor = CurColor - 16
  CASE CHR$(0) + "P": NewColor = CurColor + 16
  CASE CHR$(0) + "K": NewColor = CurColor - 1
  CASE CHR$(0) + "M": NewColor = CurColor + 1
  END SELECT
  
  IF NewColor <> CurColor THEN
    MouseFunction 2
    GOSUB ViewPal.DrawColor
    CurColor = NewColor AND LastColor
    GOSUB ViewPal.HighlightColor
    MouseFunction 1
  END IF

LOOP

'redraw background

EXIT SUB

ViewPal.DrawColors:
  TopRow = 20: LeftCol = 16: Hite = 10: Wdth = 18: CurColor = 0
  BtmRow = TopRow + 16 * Hite - 1: RiteCol = LeftCol + 16 * Wdth - 1
  BlockHite = Hite - 1: BlockWdth = Wdth - 1
 
  DrawBorder TopRow - 1, BtmRow + 1, LeftCol - 1, RiteCol + 1, 1
  FOR Row = TopRow TO BtmRow STEP Hite
    FOR Col = LeftCol TO RiteCol STEP Wdth
      LINE (Col, Row)-(Col + BlockWdth, Row + BlockHite), CurColor, BF
      CurColor = CurColor + 1
    NEXT Col
  NEXT Row
RETURN

ViewPal.HighlightColor:
  Row = (CurColor \ 16) * Hite + TopRow: Col = (CurColor AND 15) * Wdth + LeftCol
  DrawBorder Row, Row + BlockHite, Col, Col + BlockWdth, 0
  ColorValue = CVI(MID$(SnesPalette$, CurColor * 2 + 1, 2))
  LINE (16, 184)-(118, 191), ColorDark, BF
  Chars$ = StrTrim(CurColor) + ":" + STR$(ColorValue AND 31) + STR$((ColorValue AND 992) \ 32) + STR$((ColorValue AND 31744) \ 1024)
  DrawCharString Chars$, 23, 2, ColorWhite
RETURN

ViewPal.DrawColor:
  Row = (CurColor \ 16) * Hite + TopRow: Col = (CurColor AND 15) * Wdth + LeftCol
  LINE (Col, Row)-(Col + BlockWdth, Row + BlockHite), CurColor, BF
RETURN

END SUB

SUB PageViewSprites

Menu.DrawBox 1, 1, 23, 38
DrawWindowTitle "Sprite List", 1, 1, 38

END SUB

SUB PaletteConvert (Palette$)

DEF SEG = VARSEG(PaletteTable(0))
BytePos = VARPTR(PaletteTable(0))
FOR CurColor = 1 TO 512 STEP 2
  ColorValue = CVI(MID$(Palette$, CurColor, 2))
  POKE BytePos, (ColorValue AND 31) * 8
  POKE BytePos + 1, (ColorValue AND 992) \ 4
  POKE BytePos + 2, (ColorValue AND 31744) \ 128
  BytePos = BytePos + 3
NEXT CurColor

END SUB

SUB PaletteMergeGUIcolors

RESTORE GUIColors
DEF SEG = VARSEG(PaletteTable(0))
BytePos = VARPTR(PaletteTable(0))
FOR CurColor = 0 TO 3
  READ ColorValue: POKE BytePos, ColorValue
  READ ColorValue: POKE BytePos + 1, ColorValue
  READ ColorValue: POKE BytePos + 2, ColorValue
  BytePos = BytePos + 48
NEXT CurColor

END SUB

SUB PaletteSet

DEF SEG = VARSEG(PaletteTable(0))
BytePos = VARPTR(PaletteTable(0))
OUT &H3C8, 0
FOR CurColor = 0 TO 255
  OUT &H3C9, PEEK(BytePos) \ 4
  OUT &H3C9, PEEK(BytePos + 1) \ 4
  OUT &H3C9, PEEK(BytePos + 2) \ 4
  BytePos = BytePos + 3
NEXT CurColor

END SUB

SUB PaletteSetGray

DEF SEG = VARSEG(PaletteTable(0))
BytePos = VARPTR(PaletteTable(0))
FOR CurColor = 0 TO 255
  POKE BytePos, CurColor
  POKE BytePos + 1, CurColor
  POKE BytePos + 2, CurColor
  BytePos = BytePos + 3
NEXT CurColor
PaletteSet

END SUB

FUNCTION PointerInArea (PointerY, PointerX, TopRow, LeftCol, BtmRow, RiteCol)
'returns wether or not the mouse is in a certain area and returns reduced
'pointer coordinates. used mainly for buttons and objects that can be aligned
'to any pixel position.

IF PointerY < TopRow OR PointerX < LeftCol THEN EXIT FUNCTION

'Row = PointerY - TopRow: Col = PointerX - LeftCol
'IF Row > Hite - 1 OR Col > Wdth - 1 THEN EXIT FUNCTION

IF PointerY > BtmRow OR PointerX > RiteCol THEN EXIT FUNCTION
PointerY = PointerY - TopRow: PointerX = PointerX - LeftCol

'PointerY = Row: PointerX = Col
PointerInArea = 1

END FUNCTION

FUNCTION PointerInGrid (PointerY, PointerX, TopRow, LeftCol, Hite, Wdth)
'returns wether or not the mouse is in a certain text grid and returns the
'reduced pointer coordinates. used mainly for menus or lists.

Row = PointerY \ 8: Col = PointerX \ 8
IF Row < TopRow OR Col < LeftCol THEN EXIT FUNCTION

Row = Row - TopRow: Col = Col - LeftCol
IF Row > Hite - 1 OR Col > Wdth - 1 THEN EXIT FUNCTION

PointerY = Row: PointerX = Col
PointerInGrid = 1

END FUNCTION

SUB ShowSomeTilemap (MapBase&, Plane)

DEF SEG = VARSEG(VRAM(0))
Index& = VARPTR(VRAM(0)) + MapBase&
Bits = VideoModeBpls(PlaneBitsBase + Plane)
Size& = Bits * 8
TileBase& = PlanesInfo(Plane).TileBase
ColorFactor = PlanesInfo(Plane).Colors
IF ColorFactor THEN ColorFactor = 1024 \ ColorFactor ELSE EXIT SUB

IF SnesInfo.VideoMode = 7 THEN
  Size& = 128
  FOR CurRow = 0 TO 31
    SubIndex& = Index&
    IF Index& + 256 > 65535 THEN EXIT SUB
    FOR CurCol = 0 TO 39
      Char = PEEK(SubIndex&)
      DrawMode7Tile Char * Size&, CurRow * 8, CurCol * 8
      'LOCATE CurRow + 1, CurCol + 1: PRINT RIGHT$(HEX$(Char), 1);
      SubIndex& = SubIndex& + 2
    NEXT CurCol
    Index& = Index& + 256
  NEXT CurRow
ELSE
  IF SnesInfo.VideoMode = 0 THEN PalBase = Plane * 32
  FOR CurRow = 0 TO 31
    IF Index& + 128 > 65535 THEN EXIT SUB
    FOR CurCol = 0 TO 31
      TileWord& = PEEK(Index&) OR PEEK(Index& + 1) * 256&
      Char = TileWord& AND 1023
      Pal = (TileWord& AND 7168) \ ColorFactor + PalBase
      Flip = (TileWord& AND 49152) \ 16384
      'LINE (CurCol * 8, CurRow * 8)-(CurCol * 8 + 7, CurRow * 8 + 7), Char, BF
      DrawBplTile TileBase& + (Char * Size&), Bits, Pal, CurRow * 8, CurCol * 8, Flip
      'LOCATE CurRow + 1, CurCol + 1: PRINT RIGHT$(HEX$(Char), 1);
      Index& = Index& + 2
    NEXT CurCol
  NEXT CurRow
END IF

END SUB

FUNCTION StrDim$ (FirstNum, SecondNum)
  StrDim = LTRIM$(STR$(FirstNum)) + "x" + LTRIM$(STR$(SecondNum))
END FUNCTION

FUNCTION StrTrim$ (FirstNum)
  StrTrim$ = LTRIM$(STR$(FirstNum))
END FUNCTION

FUNCTION StrYesNo$ (FirstNum)
  IF FirstNum THEN StrYesNo = "yes" ELSE StrYesNo = "no"
END FUNCTION

SUB ViewTilemap

Change = 1
MapBase& = PlanesInfo(0).MapBase
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE CHR$(27): EXIT DO
  CASE " "
    IF Plane >= 3 THEN Plane = 0 ELSE Plane = Plane + 1
    IF PlanesInfo(Plane).Colors = 0 THEN Plane = 0
    Change = 1
  CASE CHR$(13)
    IF Plane >= 3 THEN Plane = 0 ELSE Plane = Plane + 1
    IF PlanesInfo(Plane).Colors = 0 THEN Plane = 0
    MapBase& = PlanesInfo(Plane).MapBase: Change = 1
  CASE CHR$(0) + "P": IF MapBase& + 1024 < 65535 THEN MapBase& = MapBase& + 1024: Change = 1
  CASE CHR$(0) + "H": IF MapBase& - 1024 >= 0 THEN MapBase& = MapBase& - 1024: Change = 1
  CASE CHR$(0) + "M": IF MapBase& + 32 < 65535 THEN MapBase& = MapBase& + 64: Change = 1
  CASE CHR$(0) + "K": IF MapBase& - 32 >= 0 THEN MapBase& = MapBase& - 64: Change = 1
  END SELECT
 
  IF Change = 1 THEN Change = 0: ShowSomeTilemap MapBase&, Plane: LOCATE 25, 1: PRINT Plane; MapBase&;
LOOP

END SUB

SUB ViewVRAM

GOSUB SetVramViewer

Change = 1
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE CHR$(0) + "P": IF TileBase& + 256& * Size < 65536 THEN TileBase& = TileBase& + 256& * Size: Change = 1
  CASE CHR$(0) + "H": IF TileBase& > 0 THEN TileBase& = TileBase& - 256& * Size: Change = 1
  CASE CHR$(0) + "M": CurPal = (CurPal + 1) AND 15: Change = 1
  CASE CHR$(0) + "K": CurPal = (CurPal - 1) AND 15: Change = 1
  CASE "1" TO "3": Bits = 2 ^ VAL(Key$): GOSUB SetVramBpl: Change = 1
  CASE "4": Linear = 1: Bits = 8: Size = 128: Change = 1
  CASE " "
    IF Plane >= 3 THEN Plane = 0 ELSE Plane = Plane + 1
    IF PlanesInfo(Plane).Colors <= 0 THEN Plane = 0
    GOSUB SetVramViewer
    Change = 1
  CASE CHR$(27): EXIT DO
  END SELECT

  IF Change THEN Change = 0: GOSUB DrawSNEStiles
LOOP

EXIT SUB

SetVramViewer:
  Bits = VideoModeBpls(PlaneBitsBase + Plane)
  Colors = PlanesInfo(Plane).Colors
  IF SnesInfo.VideoMode = 7 THEN Linear = 1: Bits = 8: Size = 128 ELSE Linear = 0: Size = 8 * Bits
RETURN

SetVramBpl:
  Colors = 2 ^ Bits
  Size = 8 * Bits
  Linear = 0
RETURN

DrawSNEStiles:
  TopRow = 0: LeftCol = 0: TempBase& = TileBase&: PalBase = CurPal * Colors
 
  FOR CurChar = 0 TO 255
    IF Linear THEN DrawMode7Tile TempBase&, TopRow, LeftCol ELSE DrawBplTile TempBase&, Bits, PalBase, TopRow, LeftCol, 0
    TempBase& = TempBase& + Size
    LeftCol = LeftCol + 8
    IF LeftCol >= 128 THEN TopRow = TopRow + 8: LeftCol = 0
  NEXT CurChar
  LOCATE 25, 1: PRINT TileBase&; Plane; CurPal; TAB(20);
RETURN

END SUB

