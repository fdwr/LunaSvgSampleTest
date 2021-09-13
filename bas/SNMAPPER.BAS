'Savestate viewer for ZSNES
'Started Aug 5, 1998 by FDwR

DEFINT A-Z
OPTION BASE 0
DECLARE SUB MainMenu ()
DECLARE SUB PageTitle ()
DECLARE SUB PageSceneInfo ()
DECLARE SUB PageViewPalette ()
DECLARE SUB PageViewSprites ()
DECLARE SUB PageViewScene ()
DECLARE FUNCTION PageFileSelect (FileName$, ShortName$, Title$, Mode)
DECLARE SUB EndProgram ()

DECLARE SUB LoadSaveState (FileNum)
DECLARE SUB RestoreBackground (TopRow, LeftCol, Hite, Wdth)
DECLARE SUB SetWinTitle (Title$)
DECLARE SUB ScrollWindow (TopRowPixel, LeftColPixel, BtmRowPixel, RiteColPixel, HitePixel, WdthPixel)
DECLARE SUB DrawSceneLayers (LayersPixel, TopRowPixel, LeftColPixel, BtmRowPixel, RiteColPixel)
DECLARE SUB DrawBplTile (BaseByte&, Bits, PalBase, TopRow, LeftCol, Flip)
DECLARE SUB DrawMode7Tile (BaseByte&, TopRow, LeftCol)
DECLARE SUB DrawClearBplTile (BaseByte&, BitsPixel, PalBasePixel, TopRowPixel, LeftColPixel, FlipPixel)
DECLARE SUB DrawFourTiles (BaseByte&, Bits, PalBase, TopRow, LeftCol, Flip)
DECLARE SUB DrawTileMapOld (MapBase&, Plane)
DECLARE SUB DrawSingleSprite (BaseByte&, Pal, TopRow, LeftCol)
DECLARE SUB ViewVRAM ()
DECLARE SUB ViewTilemap ()
DECLARE SUB ShowSceneOffset (Plane, TopRow, LeftCol)
DECLARE SUB PaletteConvert (Palette$, Mode)
DECLARE SUB PaletteGUIcolors ()
DECLARE SUB PaletteSet ()
DECLARE SUB PaletteSetGray ()
DECLARE SUB PaletteColormap ()

DECLARE SUB DrawStringRow (Chars$, TopRow, LeftCol, FontColor)
DECLARE SUB DrawStringShadow (Chars$, TopRow, LeftCol, FontColor, FontShadow)
DECLARE SUB DrawString (Chars$, TopRow, LeftCol, ColorFront)
DECLARE SUB DrawWindowTitle (Chars$, TopRow, LeftCol, Wdth)
DECLARE SUB DrawBorder (TopRow, BtmRow, LeftCol, RiteCol, Mode)
DECLARE SUB InvertTest (TopRow, LeftCol, BtmRow, RiteCol)
DECLARE SUB AttemptOpen (FileName$, FileNum)
DECLARE FUNCTION GetShortFileName$ (FileName$)
DECLARE FUNCTION GetFileList$ (FileMask$, FileType)
DECLARE SUB MouseFunction (Ax)
DECLARE FUNCTION MouseInfo (Buttons, Presses, PointerY, PointerX)
DECLARE FUNCTION PointerInGrid (PointerY, PointerX, TopRow, LeftCol, Hite, Wdth)
DECLARE FUNCTION PointerInArea (PointerY, PointerX, TopRow, LeftCol, Hite, Wdth)
DECLARE FUNCTION StrDim$ (FirstNum, SecondNum)
DECLARE FUNCTION StrTrim$ (FirstNum)
DECLARE FUNCTION StrYesNo$ (FirstNum)

DECLARE SUB Button.Draw (TopRow, LeftCol, BtmRow, RiteCol, Mode, Text$)
DECLARE SUB List.Draw (MenuChoices$(), TopRow, LeftCol, Hite, Wdth, MenuChoice, LastChoice, BaseChoice, PriorChoice)
DECLARE SUB List.DrawBox (TopRow, LeftCol, Hite, Wdth)
DECLARE SUB List.ReceiveKey (Key$, MenuChoices$(), MenuChoice, LastChoice, BaseChoice, Hite, PriorChoice, Change)
DECLARE SUB List.ReceiveMouse (Presses, PointerY, Hite, MenuChoice, LastChoice, BaseChoice, PriorChoice, Change)
DECLARE SUB List.JumpTo (NewChoice, MenuChoice, LastChoice, BaseChoice, Hite, PriorChoice, Change)
DECLARE SUB List.DrawFiles (MenuChoices$(), MenuTypes(), TopRow, LeftCol, Hite, Wdth, MenuChoice, LastChoice, BaseChoice, PriorChoice)
DECLARE SUB Menu.Draw (MenuChoices$(), TopRow, LeftCol, MenuChoice, PriorChoice)
DECLARE SUB Menu.DrawBox (TopRow, LeftCol, Hite, Wdth)
DECLARE SUB Menu.ParseChoices (Choices$, MenuChoices$(), NumChoice, LongestString)
DECLARE SUB Menu.ReceiveKey (Key$, MenuChoices$(), MenuChoice, Change)
DECLARE SUB Menu.ReceiveMouse (Buttons, PointerY, MenuChoices$(), MenuChoice, Change)
DECLARE SUB Prompt.Draw (Text$, Default$, TopRow, LeftCol, Wdth, CurPos, TxtLim)
DECLARE SUB Prompt.ReceiveKey (Key$, Text$, Default$, CurPos, TxtLim, Change)

'use the transparent colors of the lower eight palettes
CONST ColorBlack = 0, ColorDark = 16, ColorGray = 32, ColorWhite = 48, FontSize = 8

TYPE SnesInfoType
CycleCount AS INTEGER
VideoMode AS INTEGER '0-7
Brightness AS INTEGER '0-15
SpriteBase AS LONG
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
BP AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

DIM SHARED Regs AS RegisterType, FontBlitCode$, BackgroundBlit$, FileError, LongFileNames
DIM SHARED SnesFile$, SnesFileName$, SaveStateType$, MainMenuChoice, MainMenuSelect
DIM SHARED MousePresent, LastPress!, ClickTime!
DIM SHARED SnesPalette AS STRING * 512, PaletteTable(383), ColorMapTable(255), InverseColorTable(255), BackColor(3), UsedColors
DIM SHARED SnesInfo AS SnesInfoType, PlanesInfo(3) AS PlaneInfoType, PlaneMask, UserScrollY, UserScrollX
DIM SHARED SpriteSizes(15), VideoModeBpls(31), PlaneBitsBase, SpriteSizeBase
REDIM SHARED SpriteOAM(276), BitmapCache(16384)
REDIM SHARED VRAM(16383) AS LONG, MainBackground(16000) AS LONG
'554 for object attribute memory, the list for up to 128 sprites (SpriteOAM)
'64k for snes video ram, including tiles, sprites, & tilemap arrays (VRAM)
'32k for cache of already translated tiles and sprites (BitmapCache)
'62k for the playfield virtual screen (SceneBuffer)

SCREEN 13

RESTORE FontBlitData: READ CodeBytes: FontBlitCode$ = SPACE$(CodeBytes)
FOR CurChar = 1 TO CodeBytes: READ Char: MID$(FontBlitCode$, CurChar) = CHR$(Char): NEXT CurChar
RESTORE VideoModeBpls: FOR Index = 0 TO 31: READ VideoModeBpls(Index): NEXT Index
RESTORE SpriteSizes: FOR Index = 0 TO 15: READ SpriteSizes(Index): NEXT Index
RESTORE BackgroundBlit: READ CodeBytes: BackgroundBlit$ = SPACE$(CodeBytes)
FOR CurChar = 1 TO CodeBytes: READ Chars$: MID$(BackgroundBlit$, CurChar) = CHR$(VAL("&H" + Chars$)): NEXT CurChar
LongFileNames = 0

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

SceneInfoLabels:
DATA 33,File,Type,,Video mode,Brightness,Vertical line,Cycle count,Mosaic size,Window 1
DATA Window 2,,Bg Num,Colors,Enabled,Subscreen,Mosaic,Map size,Tile size,Height
DATA Width,Scroll X,Scroll Y,Modulus X,Modulus Y,Map base,Tile base,Window 1
DATA Window 2,,Sprite sizes,Sprite base,,Color constant,Transparency
GUIcolors:
DATA 4,0,0,0,24,24,35,48,48,63,63,63,63

VideoModeBpls:
DATA 2,2,2,2, 4,4,2,0, 4,4,0,0, 8,4,0,0, 8,2,0,0, 4,2,0,0, 4,0,0,0, 8,0,0,0
SpriteSizes:
DATA 8,16,8,32,8,64,16,32,16,64,32,64,32,64,32,64

BackgroundBlit:
DATA 57,1E,06,55,89,E5,C5,76,0A,B8,00,A0,8B,7E,0E,8E,C0
DATA 8B,5E,10,B8,40,01,29,D8,C1,EB,02,8B,56,12,85,D2
DATA 74,11,85,DB,74,0D,FC,89,D9,F3,66,A5,01,C6,01,C7
DATA 4A,75,F4,5D,07,1F,CA,08,00

SUB AttemptOpen (FileName$, FileNum)

ON ERROR GOTO FileErrHandler: FileError = 0
FileNum = FREEFILE
OPEN FileName$ FOR INPUT AS FileNum
CLOSE FileNum
IF FileError = 0 THEN OPEN FileName$ FOR BINARY AS FileNum

ON ERROR GOTO 0
IF FileError THEN FileNum = 0

END SUB

SUB Button.Draw (TopRow, LeftCol, Hite, Wdth, Mode, Text$)

PixelTopRow = TopRow * FontSize - 3
PixelLeftCol = LeftCol * FontSize - 2
PixelBtmRow = (TopRow + Hite) * FontSize + 1
PixelRiteCol = (LeftCol + Wdth) * FontSize

IF Mode >= 2 THEN Temp = 1
DrawBorder PixelTopRow, PixelBtmRow, PixelLeftCol, PixelRiteCol, Temp
DrawBorder PixelTopRow + 1, PixelBtmRow - 1, PixelLeftCol - 1, PixelRiteCol + 1, Temp

IF Wdth < 0 THEN Wdth = 0
IF Mode THEN ColorFront = ColorWhite ELSE ColorFront = ColorGray
DrawStringRow LEFT$(Text$, Wdth), TopRow, LeftCol, ColorFront

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

DEF SEG = VARSEG(VRAM(0))
Index& = Bits * 8 + BaseByte&
IF Index& > 65536 THEN Index& = BaseByte& - 65536 ELSE Index& = BaseByte&
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

SUB DrawClearBplTile (BaseByte&, Bits, PalBase, TopRow, LeftCol, Flip)

DEF SEG = VARSEG(VRAM(0))
Index& = Bits * 8 + BaseByte&
IF Index& > 65536 THEN Index& = BaseByte& - 65536 ELSE Index& = BaseByte&
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
    IF p1 THEN PSET (LeftCol + 7, Row), p1 + PalBase
    IF p2 THEN PSET (LeftCol + 6, Row), p2 + PalBase
    IF p3 THEN PSET (LeftCol + 5, Row), p3 + PalBase
    IF p4 THEN PSET (LeftCol + 4, Row), p4 + PalBase
    IF p5 THEN PSET (LeftCol + 3, Row), p5 + PalBase
    IF p6 THEN PSET (LeftCol + 2, Row), p6 + PalBase
    IF p7 THEN PSET (LeftCol + 1, Row), p7 + PalBase
    IF p8 THEN PSET (LeftCol, Row), p8 + PalBase
  ELSE
    IF p1 THEN PSET (LeftCol, Row), p1 + PalBase
    IF p2 THEN PSET (LeftCol + 1, Row), p2 + PalBase
    IF p3 THEN PSET (LeftCol + 2, Row), p3 + PalBase
    IF p4 THEN PSET (LeftCol + 3, Row), p4 + PalBase
    IF p5 THEN PSET (LeftCol + 4, Row), p5 + PalBase
    IF p6 THEN PSET (LeftCol + 5, Row), p6 + PalBase
    IF p7 THEN PSET (LeftCol + 6, Row), p7 + PalBase
    IF p8 THEN PSET (LeftCol + 7, Row), p8 + PalBase
  END IF
NEXT CurRow

END SUB

SUB DrawFourTiles (BaseByte&, Bits, PalBase, TopRow, LeftCol, Flip)

Index& = BaseByte&
Size& = Bits * 8
DrawClearBplTile Index&, Bits, PalBase, TopRow, LeftCol, Flip
DrawClearBplTile Index& + Size&, Bits, PalBase, TopRow, LeftCol + 8, Flip
DrawClearBplTile Index& + Size& * 16, Bits, PalBase, TopRow + 8, LeftCol, Flip
DrawClearBplTile Index& + Size& * 16 + Size&, Bits, PalBase, TopRow + 8, LeftCol + 8, Flip

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

SUB DrawSceneLayers (Layers, TopRow, LeftCol, BtmRow, RiteCol)
'draws an area of the scene, including all the planes and sprites
'eventually all the planes and sprites will be drawn in the right order
'for now, the planes will be drawn one after another and then sprites
'on top of it all

'clear background to base color
BackColor = 64
VIEW SCREEN (LeftCol, TopRow)-(RiteCol, BtmRow), BackColor

DEF SEG = VARSEG(VRAM(0))
Mask = 8
FOR Plane = 3 TO 0 STEP -1
  IF (Layers AND Mask) = 0 OR PlanesInfo(Plane).Colors = 0 GOTO DisabledPlane
  ColorFactor = 1024 \ PlanesInfo(Plane).Colors
  TileSize = PlanesInfo(Plane).TileSize: IF TileSize < 1 GOTO DisabledPlane
  Draw16x16Tiles = TileSize = 16
  TileBase& = PlanesInfo(Plane).TileBase
  MapBase& = PlanesInfo(Plane).MapBase
  MapWidth = PlanesInfo(Plane).TileWidth
  MapHeight = PlanesInfo(Plane).TileHeight
  Bits = VideoModeBpls(PlaneBitsBase + Plane)
  Size& = 8 * Bits
  Colors = PlanesInfo(Plane).Colors

  Scroll& = PlanesInfo(Plane).ScrollY + CLNG(TopRow + UserScrollY)
  TopTile = (Scroll& AND PlanesInfo(Plane).PixelHeight - 1) \ TileSize
  PixelTopRow = TopRow - (Scroll& AND TileSize - 1)
  Scroll& = PlanesInfo(Plane).ScrollX + CLNG(LeftCol + UserScrollX)
  LeftTile = (Scroll& AND PlanesInfo(Plane).PixelWidth - 1) \ TileSize
  PixelLeftCol = LeftCol - (Scroll& AND TileSize - 1)
  MainTilePtr& = MapBase& + ((TopTile AND 32) * MapWidth * 2) + ((TopTile AND 31) * 64) - 65536
  LeftPtr = (LeftTile AND 32) * 64 + (LeftTile AND 31) * 2
  TilePtr& = MainTilePtr& + LeftPtr
  TileSize2 = TileSize - 1

  CurCol = PixelLeftCol: CurRow = PixelTopRow
  Ytile = TopTile: Xtile = LeftTile
  DO
    TileWord& = PEEK(TilePtr&) OR PEEK(TilePtr& + 1) * 256&
    Char = (TileWord& AND 1023)
    Pal = (TileWord& AND 7168) \ ColorFactor + PalBase
    Flip = (TileWord& AND 49152) \ 16384
    IF Draw16x16Tiles THEN
      DrawFourTiles TileBase& + (Char * Size&), Bits, Pal, CurRow, CurCol, Flip
    ELSE
      DrawClearBplTile TileBase& + (Char * Size&), Bits, Pal, CurRow, CurCol, Flip
    END IF
    'IF (Xtile AND 31) = 0 THEN LINE (CurCol, CurRow)-(CurCol + TileSize2, CurRow + TileSize2), 48, B, 21845
    'IF (Ytile AND 31) = 0 THEN LINE (CurCol, CurRow)-(CurCol + TileSize2, CurRow + TileSize2), 32, B, -21846
    CurCol = CurCol + TileSize
    IF CurCol > RiteCol THEN
      CurRow = CurRow + TileSize
      IF CurRow > BtmRow THEN EXIT DO
      CurCol = PixelLeftCol
      Xtile = LeftTile
      Ytile = Ytile + 1
      IF (Ytile AND 31) = 0 THEN GOSUB WrapPlaneRow ELSE MainTilePtr& = MainTilePtr& + 64
      TilePtr& = MainTilePtr& + LeftPtr
    ELSE
      Xtile = Xtile + 1
      IF (Xtile AND 31) = 0 THEN GOSUB WrapPlaneCol ELSE TilePtr& = TilePtr& + 2
    END IF
  LOOP
'grab tile
' check cache for tile
' if not already made, make it (8x8 or 16x16)
'blit tile to destination, with flipping and colormapping
DisabledPlane:
  Mask = Mask \ 2
NEXT Plane

VIEW

EXIT SUB

WrapPlaneCol:
  IF Xtile >= MapWidth THEN TilePtr& = MainTilePtr&: Xtile = 0 ELSE TilePtr& = MainTilePtr& + 2048
RETURN

WrapPlaneRow:
  IF Ytile >= MapHeight THEN MainTilePtr& = MapBase& - 65536: Ytile = 0 ELSE MainTilePtr& = MapBase& + MapWidth * 64 - 65536
RETURN

END SUB

SUB DrawSingleSprite (BaseByte&, Pal, TopRow, LeftCol)

TileBase& = BaseByte&

PixelTopRow = TopRow
SpriteHeight = 3
SpriteWidth = 3
FOR CurRow = 0 TO SpriteHeight
  PixelLeftCol = LeftCol
  Index& = TileBase&
  FOR CurCol = 0 TO SpriteWidth
    DrawBplTile Index&, 4, Pal, PixelTopRow, PixelLeftCol, 0
    PixelLeftCol = PixelLeftCol + 8
    Index& = Index& + 32
  NEXT CurCol
  PixelTopRow = PixelTopRow + 8
  TileBase& = TileBase& + 512
NEXT CurRow

END SUB

SUB DrawString (Chars$, TopRow, LeftCol, ColorFront)

DEF SEG = VARSEG(FontBlitCode$): Index& = SADD(Chars$): Col = LeftCol
'parameters are passed left to right
FOR CurChar = 1 TO LEN(Chars$)
 CALL ABSOLUTE(BYVAL ColorFront, BYVAL Col, BYVAL TopRow, BYVAL PEEK(Index&), SADD(FontBlitCode$))
 Col = Col + FontSize: Index& = Index& + 1
NEXT CurChar

END SUB

SUB DrawStringCentered (Chars$, TopRow, ColorFront)

LeftCol = (40 - LEN(Chars$)) * FontSize \ 2
DrawString Chars$, TopRow * 8, LeftCol, ColorFront

END SUB

SUB DrawStringRow (Chars$, TopRow, LeftCol, ColorFront)

DrawString Chars$, TopRow * FontSize, LeftCol * FontSize, ColorFront

END SUB

SUB DrawStringShadow (Chars$, TopRow, LeftCol, ColorFront, ColorShadow)

Row = TopRow * FontSize: Col = LeftCol * FontSize
DrawString Chars$, Row + 1, Col + 1, ColorShadow
DrawString Chars$, Row, Col, ColorFront

END SUB

SUB DrawTileMapOld (MapBase&, Plane)

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
  FOR CurRow = 0 TO 23
    IF Index& + 128 > 65535 THEN EXIT SUB
    FOR CurCol = 0 TO 31
      TileWord& = PEEK(Index&) OR PEEK(Index& + 1) * 256&
      Char = TileWord& AND 1023
      Pal = (TileWord& AND 7168) \ ColorFactor + PalBase
      Flip = (TileWord& AND 49152) \ 16384
      'LINE (CurCol * 8, CurRow * 8)-(CurCol * 8 + 7, CurRow * 8 + 7), Char, BF
      DrawBplTile TileBase& + (Char * Size&), Bits, Pal, CurRow * 8, CurCol * 8, Flip
      Index& = Index& + 2
    NEXT CurCol
  NEXT CurRow
END IF

END SUB

SUB DrawWindowTitle (Chars$, TopRow, LeftCol, Wdth)

PixelTopRow = TopRow * FontSize - 1
PixelLeftCol = LeftCol * FontSize - 1
PixelBtmRow = PixelTopRow + 9
PixelRiteCol = PixelLeftCol + Wdth * FontSize + 1

LINE (PixelLeftCol, PixelTopRow)-(PixelRiteCol, PixelBtmRow), ColorBlack, BF
DrawStringRow Chars$, TopRow, LeftCol, ColorWhite

END SUB

SUB EndProgram

WIDTH 80, 25
COLOR 7, 0
CLS

Title$ = "See ya..."
SetWinTitle Title$
PRINT Title$

END

END SUB

FUNCTION GetFileList$ (FileMask$, FileType) STATIC
    
  DIM DTA AS STRING * 320
  Count = 150

  IF LongFileNames = 0 THEN
    Regs.Ax = &H1A00                   'Set DTA function
    Regs.Dx = VARPTR(DTA)              'DS:DX points to our DTA
    Regs.Ds = -1                       'Use current value for DS
    CALL InterruptX(&H21, Regs, Regs)  'Do the interrupt
  END IF
    
  IF LEN(FileMask$) THEN 'FindFirst
    FileSpec$ = FileMask$ + CHR$(0)
    IF LongFileNames THEN
      Regs.Ax = &H714E
      Regs.Es = -1
      Regs.Di = VARPTR(DTA)
      Regs.Si = 0
      Regs.Flags = 0
    ELSE Regs.Ax = &H4E00
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
    ELSE Regs.Ax = &H4F00
    END IF
  END IF
    
  CALL InterruptX(&H21, Regs, Regs)
  IF FindFirst THEN FileTypeWanted = FileType: DirHandle = Regs.Ax: FindFirst = 0

  IF Regs.Flags AND 1 THEN 'Error
    GetFileList$ = ""     'Return null string
    IF LongFileNames THEN 'free Win95 handle
      Regs.Ax = &H71A1
      Regs.Bx = DirHandle
      CALL InterruptX(&H21, Regs, Regs)
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

FUNCTION GetShortFileName$ (FileName$)

  DIM DTA AS STRING * 320
  IF LongFileNames = 0 OR FileName$ = ".." GOTO NameAlreadyShort

  FileSpec$ = FileName$ + CHR$(0)
  Regs.Ax = &H714E'FindFirst
  Regs.Si = 0
  Regs.Flags = 0
  Regs.Es = -1
  Regs.Di = VARPTR(DTA)
  Regs.Cx = 255
  Regs.Ds = -1
  Regs.Dx = SADD(FileSpec$)

  CALL InterruptX(&H21, Regs, Regs)

  IF Regs.Flags AND 1 THEN 'Error
    GetShortFileName$ = ""'Return null string
  ELSE
    CurChar = INSTR(305, DTA, CHR$(0))
    IF CurChar = 305 GOTO NameAlreadyShort
    GetShortFileName = MID$(DTA, 305, CurChar - 305)
  END IF

  Regs.Ax = &H71A1
  Regs.Bx = DirHandle
  CALL InterruptX(&H21, Regs, Regs)
EXIT FUNCTION

NameAlreadyShort:
  GetShortFileName = FileName$

END FUNCTION

SUB GrabTile
'makes and returns a pointer to a converted tile for new tiles
'Also checks to see if the wanted tile already exists in the cache; if it
'does, then it will simply return the pointer to the cache bitmap.
END SUB

SUB InvertTest (TopRow, LeftCol, BtmRow, RiteCol)

FOR CurCol = LeftCol + 1 TO RiteCol
  PSET (CurCol, TopRow), InverseColorTable(POINT(CurCol, TopRow))
NEXT CurCol
FOR CurCol = LeftCol + 1 TO RiteCol
  PSET (CurCol, BtmRow), InverseColorTable(POINT(CurCol, BtmRow))
NEXT CurCol
FOR CurRow = TopRow TO BtmRow
  PSET (LeftCol, CurRow), InverseColorTable(POINT(LeftCol, CurRow))
NEXT CurRow
FOR CurRow = TopRow + 1 TO BtmRow - 1
  PSET (RiteCol, CurRow), InverseColorTable(POINT(RiteCol, CurRow))
NEXT CurRow

'FOR CurRow = TopRow TO BtmRow
' FOR CurCol = LeftCol TO RiteCol
'    PSET (CurCol, CurRow), InverseColorTable(POINT(CurCol, CurRow))
'NEXT CurCol, CurRow

END SUB

SUB List.Draw (MenuChoices$(), TopRow, LeftCol, Hite, Wdth, MenuChoice, LastChoice, BaseChoice, PriorChoice)

IF LastChoice > UBOUND(MenuChoices$) THEN LastChoice = UBOUND(MenuChoices$)

PixelLeftCol = LeftCol * FontSize: PixelRiteCol = PixelLeftCol + Wdth * FontSize - 1
MouseFunction 2
IF PriorChoice < 0 THEN
  FOR CurChoice = BaseChoice TO BaseChoice + Hite - 1
    GOSUB DrawListChoice
  NEXT CurChoice
ELSE
  CurChoice = PriorChoice: GOSUB DrawListChoice
  CurChoice = MenuChoice: GOSUB DrawListChoice
END IF
MouseFunction 1
PriorChoice = MenuChoice

EXIT SUB

DrawListChoice:
  Row = CurChoice - BaseChoice: IF Row < 0 OR Row >= Hite THEN RETURN
  PixelTopRow = (Row + TopRow) * FontSize: PixelBtmRow = PixelTopRow + 7
  IF CurChoice = MenuChoice THEN MenuColor = ColorWhite: BackColor = ColorGray ELSE MenuColor = ColorGray: BackColor = ColorDark
  LINE (PixelLeftCol, PixelTopRow)-(PixelRiteCol, PixelBtmRow), BackColor, BF
  IF CurChoice < 0 OR CurChoice > LastChoice THEN RETURN
  DrawStringRow LEFT$(MenuChoices$(CurChoice), Wdth), TopRow + Row, LeftCol, MenuColor
RETURN

END SUB

SUB List.DrawBox (TopRow, LeftCol, Hite, Wdth)

PixelTopRow = TopRow * FontSize - 2
PixelLeftCol = LeftCol * FontSize - 2
PixelBtmRow = PixelTopRow + Hite * FontSize + 3
PixelRiteCol = PixelLeftCol + Wdth * FontSize + 3

LINE (PixelLeftCol, PixelTopRow)-(PixelLeftCol, PixelBtmRow), ColorBlack, B
LINE (PixelRiteCol, PixelTopRow)-(PixelRiteCol, PixelBtmRow), ColorGray, B
LINE (PixelLeftCol, PixelTopRow)-(PixelRiteCol, PixelTopRow), ColorBlack, B
LINE (PixelLeftCol, PixelBtmRow)-(PixelRiteCol, PixelBtmRow), ColorGray, B
LINE (PixelLeftCol + 1, PixelTopRow + 1)-(PixelRiteCol - 1, PixelBtmRow - 1), ColorDark, BF

END SUB

SUB List.DrawFiles (MenuChoices$(), MenuTypes(), TopRow, LeftCol, Hite, Wdth, MenuChoice, LastChoice, BaseChoice, PriorChoice)

IF LastChoice > UBOUND(MenuChoices$) THEN LastChoice = UBOUND(MenuChoices$)

PixelLeftCol = LeftCol * FontSize: PixelRiteCol = PixelLeftCol + Wdth * FontSize - 1
MouseFunction 2
IF PriorChoice < 0 THEN
  FOR CurChoice = BaseChoice TO BaseChoice + Hite - 1
    GOSUB DrawFilesListChoice
  NEXT CurChoice
ELSE
  CurChoice = PriorChoice: GOSUB DrawFilesListChoice
  CurChoice = MenuChoice: GOSUB DrawFilesListChoice
END IF
MouseFunction 1
PriorChoice = MenuChoice

EXIT SUB

DrawFilesListChoice:
  Row = CurChoice - BaseChoice: IF Row < 0 OR Row >= Hite THEN RETURN
  PixelTopRow = (Row + TopRow) * FontSize: PixelBtmRow = PixelTopRow + 7
  IF CurChoice = MenuChoice THEN MenuColor = ColorWhite: BackColor = ColorGray ELSE MenuColor = ColorGray: BackColor = ColorDark
  LINE (PixelLeftCol, PixelTopRow)-(PixelRiteCol, PixelBtmRow), BackColor, BF
  IF CurChoice < 0 OR CurChoice > LastChoice THEN RETURN
  Chars$ = LEFT$(MenuChoices$(CurChoice), Wdth)
  IF MenuTypes(CurChoice) THEN MenuColor = ColorWhite: Chars$ = "(" + Chars$ + ")"
  DrawStringRow Chars$, TopRow + Row, LeftCol, MenuColor
RETURN

END SUB

SUB List.JumpTo (NewChoice, MenuChoice, LastChoice, BaseChoice, Hite, PriorChoice, Change)

IF NewChoice < 0 OR LastChoice < 0 THEN NewChoice = 0 ELSE IF NewChoice > LastChoice THEN NewChoice = LastChoice
IF NewChoice <> MenuChoice THEN MenuChoice = NewChoice: Change = 1

IF MenuChoice < BaseChoice THEN
  BaseChoice = MenuChoice: PriorChoice = -1: Change = 1
ELSEIF MenuChoice >= BaseChoice + Hite THEN
  BaseChoice = MenuChoice - Hite + 1: PriorChoice = -1: Change = 1
END IF

END SUB

SUB List.ReceiveKey (Key$, MenuChoices$(), MenuChoice, LastChoice, BaseChoice, Hite, PriorChoice, Change)

SELECT CASE Key$
CASE CHR$(0) + "H": NewChoice = MenuChoice - 1
CASE CHR$(0) + "P": NewChoice = MenuChoice + 1
CASE CHR$(0) + "G": IF MenuChoice > BaseChoice THEN NewChoice = BaseChoice ELSE NewChoice = 0
CASE CHR$(0) + "O": Temp = BaseChoice + Hite - 1
  IF MenuChoice < Temp THEN NewChoice = Temp ELSE NewChoice = LastChoice
CASE CHR$(0) + "I": NewChoice = MenuChoice - Hite
CASE CHR$(0) + "Q": NewChoice = MenuChoice + Hite
CASE CHR$(13): Change = 2: EXIT SUB
CASE ELSE: EXIT SUB
END SELECT

List.JumpTo NewChoice, MenuChoice, LastChoice, BaseChoice, Hite, PriorChoice, Change

END SUB

SUB List.ReceiveMouse (Presses, PointerY, Hite, MenuChoice, LastChoice, BaseChoice, PriorChoice, Change)

IF Presses AND 1 THEN
  NewChoice = PointerY + BaseChoice
  IF NewChoice < 0 THEN NewChoice = 0 ELSE IF NewChoice > LastChoice THEN NewChoice = LastChoice: IF LastChoice < 0 THEN EXIT SUB
  IF NewChoice = MenuChoice AND ClickTime! < .5 THEN Change = 2 ELSE MenuChoice = NewChoice: Change = 1
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

SUB LoadSaveState (FileNum)

'loads various elements from the savestate, including VRAM tiles, tilemaps,
'certain video registers, the palette, and sprites.

'DrawStringShadow "Loading save state", 24, 0, ColorWhite, ColorBlack

LoadSaveState.ZSNES:
'SaveState type
SEEK FileNum, 1: Label$ = INPUT$(40, FileNum)
SaveStateType$ = Label$
'IF LEFT$(Label$, 21) <> "ZSNES Save State File" THEN EXIT SUB
IF LOF(FileNum) < 199698 THEN EXIT SUB
CurChar = INSTR(SaveStateType$, CHR$(26))
IF CurChar THEN SaveStateType$ = LEFT$(SaveStateType$, CurChar - 1)

'Brightness, Video mode, colors
SEEK FileNum, 29: Chars$ = INPUT$(2, FileNum)
  SnesInfo.CycleCount = ASC(Chars$)
  SnesInfo.Scanline = ASC(MID$(Chars$, 2))
SEEK FileNum, 79: SnesInfo.Brightness = ASC(INPUT$(1, FileNum))
SEEK FileNum, 103: SnesInfo.VideoMode = ASC(INPUT$(1, FileNum)) AND 7
SEEK FileNum, 105: Chars$ = INPUT$(3, FileNum)
Char = ASC(Chars$)
CurChar = SnesInfo.VideoMode * 4: PlaneBitsBase = CurChar
Mask = 1
FOR Index = 0 TO 3
  IF VideoModeBpls(CurChar) THEN PlanesInfo(Index).Colors = 2 ^ VideoModeBpls(CurChar) ELSE PlanesInfo(Index).Colors = 0
  IF Char AND Mask THEN PlanesInfo(Index).TileSize = 16 ELSE PlanesInfo(Index).TileSize = 8
  CurChar = CurChar + 1: Mask = Mask * 2
NEXT Index
SnesInfo.MosaicApplied = ASC(MID$(Chars$, 2, 1))
SnesInfo.MosaicSize = ASC(MID$(Chars$, 3, 1))
SEEK FileNum, 523: Chars$ = INPUT$(3, FileNum)
FOR Index = 0 TO 2
  BackColor(Index) = ASC(MID$(Chars$, Index + 1, 1))
NEXT Index

'Tilemap sizes, addresses
SEEK FileNum, 83: SnesInfo.SpriteBase = ASC(INPUT$(1, FileNum)) * 256&
SEEK FileNum, 109: Chars$ = INPUT$(8, FileNum)
CurChar = 1
FOR Index = 0 TO 3
  PlanesInfo(Index).MapBase = ASC(MID$(Chars$, CurChar, 1)) * 256&
  CurChar = CurChar + 2
NEXT Index
SEEK FileNum, 140: Chars$ = INPUT$(4, FileNum)
FOR Index = 0 TO 3
  Char = ASC(MID$(Chars$, Index + 1, 1))
  IF Char AND 2 THEN PlanesInfo(Index).TileHeight = 64 ELSE PlanesInfo(Index).TileHeight = 32
  IF Char AND 1 THEN PlanesInfo(Index).TileWidth = 64 ELSE PlanesInfo(Index).TileWidth = 32
NEXT Index
IF SnesInfo.VideoMode = 7 THEN
  PlanesInfo(0).TileHeight = 128
  PlanesInfo(0).TileWidth = 128
  PlanesInfo(0).MapBase = 0
END IF
SEEK FileNum, 145: Chars$ = INPUT$(8, FileNum)
CurChar = 1
FOR Index = 0 TO 3
  PlanesInfo(Index).TileBase = ASC(MID$(Chars$, CurChar, 1)) * 256&
  CurChar = CurChar + 2
NEXT Index
SEEK FileNum, 181: Chars$ = INPUT$(2, FileNum)
Char = ASC(Chars$): Char2 = ASC(MID$(Chars$, 2, 1)): Mask = 1: PlaneMask = 0
FOR Index = 0 TO 3
  IF Char AND Mask THEN PlanesInfo(Index).Enabled = 1: PlaneMask = PlaneMask OR Mask ELSE PlanesInfo(Index).Enabled = 0
  IF Char2 AND Mask THEN PlanesInfo(Index).Subscreen = 1: PlaneMask = PlaneMask OR Mask ELSE PlanesInfo(Index).Subscreen = 0
  PlanesInfo(Index).PixelWidth = PlanesInfo(Index).TileWidth * PlanesInfo(Index).TileSize
  PlanesInfo(Index).PixelHeight = PlanesInfo(Index).TileHeight * PlanesInfo(Index).TileSize
  Mask = Mask * 2
NEXT Index

'Scroll $97
SEEK FileNum, 152: Chars$ = INPUT$(20, FileNum)
CurChar = 1
FOR Index = 0 TO 3
  PlanesInfo(Index).ScrollX = CVI(MID$(Chars$, CurChar, 2))
  PlanesInfo(Index).ScrollY = CVI(MID$(Chars$, CurChar + 10, 2))
  CurChar = CurChar + 2
NEXT Index
UserScrollX = 0: UserScrollY = 0: UserScrollChange = 1

'OAM 218h
SEEK FileNum, 537: Chars$ = INPUT$(544, FileNum)
Index = 0
FOR CurChar = 1 TO 544 STEP 2
  SpriteOAM(Index) = CVI(MID$(Chars$, CurChar, 2)): Index = Index + 1
NEXT CurChar

'CGRAM 618-817h
SEEK FileNum, 1561: SnesPalette$ = INPUT$(512, FileNum)
PaletteConvert SnesPalette$, 0

'VRAM 20C13-30C12h
SEEK FileNum, 134164
Index = 0
FOR CharPiece = 0 TO 31
  Chars$ = INPUT$(2048, FileNum)
  FOR CurChar = 1 TO 2048 STEP 4
    VRAM(Index) = CVL(MID$(Chars$, CurChar, 4)): Index = Index + 1
  NEXT CurChar
NEXT CharPiece

END SUB

SUB MainMenu

REDIM MainMenuChoices$(0)
Menu.ParseChoices "Load state_Reload_View scene_View VRAM_View maps_Scene info_Palette_Sprites_Exit_", MainMenuChoices$(), NumChoice, LongestString

GOSUB MainMenuDraw
DO
  Key$ = INKEY$
  IF LEN(Key$) THEN
    IF Key$ = CHR$(27) THEN EXIT DO
    Menu.ReceiveKey Key$, MainMenuChoices$(), MainMenuChoice, Change
  ELSEIF MouseInfo(Buttons, Presses, PointerY, PointerX) THEN
    IF PointerInGrid(PointerY, PointerX, 1, 1, NumChoice, LongestString) THEN
      Menu.ReceiveMouse Presses, PointerY, MainMenuChoices$(), MainMenuChoice, Change
    END IF
  END IF

  IF Change AND 1 THEN Menu.Draw MainMenuChoices$(), 1, 1, MainMenuChoice, PriorChoice: Change = Change AND -2
  IF Change AND 2 THEN
    MouseFunction 2
    GOSUB MainMenuDoChoice
    MouseFunction 1
    Change = 0
  END IF
LOOP

EXIT SUB

MainMenuDoChoice:
  IF MainMenuChoice > 1 THEN LastChoiceMade = MainMenuChoice
  SELECT CASE MainMenuChoice
  CASE 0, 1
    IF MainMenuChoice THEN
      IF LEN(SnesFile$) THEN AttemptOpen FileName$, FileNum ELSE RETURN
    ELSE
      FileNum = PageFileSelect(FileName$, ShortName$, "Load savestate", 0)
    END IF
    IF FileNum THEN
      DrawStringShadow "Loading...", 24, 0, ColorWhite, ColorBlack
      LoadSaveState FileNum
      CLOSE FileNum
     
      SnesFile$ = FileName$
      SetWinTitle "Savestate Viewer" + " (" + SnesFile$ + ")"
     
      PaletteGUIcolors
      PaletteColormap
      DEF SEG = 0: IF (PEEK(1047) AND 3) = 0 THEN PaletteSet
     
      MainMenuSelect = 1: MainMenuChoice = LastChoiceMade
      IF MainMenuChoice = 0 THEN MainMenuChoice = 2
    ELSE RETURN
    END IF
  CASE 2
    PageViewScene
  CASE 3
    ViewVRAM
  CASE 4
    ViewTilemap
  CASE 5
    PageSceneInfo
  CASE 6
    PageViewPalette
  CASE 7
    PageViewSprites
  CASE 8: EXIT SUB
  END SELECT
  IF MainMenuSelect THEN MainMenuSelect = 0: IF INP(96) <> 1 THEN GOTO MainMenuDoChoice ELSE Key$ = INKEY$
  GOSUB MainMenuDraw
RETURN

MainMenuDraw:
  PriorChoice = -1
  MouseFunction 2
  Menu.DrawBox 1, 1, NumChoice, LongestString
  Menu.Draw MainMenuChoices$(), 1, 1, MainMenuChoice, PriorChoice
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
  DrawStringRow MenuChoices$(CurChoice), TopRow + CurChoice, LeftCol, MenuColor
RETURN

END SUB

SUB Menu.DrawBox (TopRow, LeftCol, Hite, Wdth)

PixelTopRow = TopRow * FontSize - 5
PixelLeftCol = LeftCol * FontSize - 5
PixelBtmRow = PixelTopRow + Hite * FontSize + 9
PixelRiteCol = PixelLeftCol + Wdth * FontSize + 9

DrawBorder PixelTopRow, PixelBtmRow, PixelLeftCol, PixelRiteCol, 2

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
  TextLen = NextChar - CurChar
  IF TextLen > LongestString THEN LongestString = TextLen
  MenuChoices$(NumChoice) = MID$(Choices$, CurChar, TextLen)
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
IF MousePresent THEN
  CALL InterruptX(&H33, Regs, Regs)
ELSEIF Ax = 0 THEN
  CALL InterruptX(&H33, Regs, Regs)
  IF Regs.Ax <> 0 THEN MousePresent = -1
END IF

END SUB

FUNCTION MouseInfo (Buttons, Presses, PointerY, PointerX)
STATIC OldPointerY, OldPointerX, OldButtons

IF MousePresent = 0 THEN EXIT FUNCTION

Regs.Ax = 3
CALL InterruptX(&H33, Regs, Regs)
PointerY = Regs.Dx
PointerX = Regs.Cx \ 2
Buttons = Regs.Bx

IF OldPointerY <> PointerY OR OldPointerX <> PointerX THEN
  OldPointerY = PointerY: OldPointerX = PointerX
  MouseInfo = 1
END IF
IF Buttons > OldButtons THEN
  ClickTime! = TIMER - LastPress!: LastPress! = TIMER
  Presses = Buttons XOR OldButtons
  MouseInfo = 2
ELSE Presses = 0
END IF
OldButtons = Buttons

END FUNCTION

FUNCTION PageFileSelect (FileName$, ShortName$, Title$, Mode)
STATIC MenuChoice, BaseChoice, Drive$, FileMask$
REDIM MenuChoices$(149), MenuTypes(149)

IF LEN(FileMask$) = 0 THEN Drive$ = "c:": FileMask$ = "*.zs?"
GOSUB FileSelect.Draw
GOSUB FileSelect.GetList

List.JumpTo MenuChoice, MenuChoice, LastChoice, BaseChoice, 17, PriorChoice, Change
Change = 1:  NewChoice = 1: PriorChoice = -1
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE ""
    IF MouseInfo(0, Presses, PointerY, PointerX) > 1 THEN
      IF PointerInGrid(PointerY, PointerX, 5, 13, 17, 26) THEN
        List.ReceiveMouse Presses, PointerY, 17, MenuChoice, LastChoice, BaseChoice, PriorChoice, Change
        IF Change AND 1 THEN NewChoice = 1
      ELSEIF PointerInGrid(PointerY, PointerX, 23, 13, 1, 5) THEN
        EXIT DO
      ELSEIF PointerInGrid(PointerY, PointerX, 23, 19, 1, 4) THEN
        Change = 2
      END IF
    END IF
  CASE CHR$(27): EXIT DO
  CASE CHR$(0) + ">": IF LongFileNames THEN LongFileNames = 0 ELSE LongFileNames = 1
    GOSUB FileSelect.GetList
    IF MenuChoice > LastChoice THEN MenuChoice = LastChoice: IF LastChoice < 0 THEN MenuChoice = 0
    Change = 1: PriorChoice = -1
    TextChange = 1: Text$ = "": Default$ = MenuChoices$(MenuChoice): CurPos = 0
  CASE ELSE
    Prompt.ReceiveKey Key$, Text$, Default$, CurPos, 26, TextChange
    List.ReceiveKey Key$, MenuChoices$(), MenuChoice, LastChoice, BaseChoice, 17, PriorChoice, Change
    IF Change AND 1 THEN NewChoice = 1
  END SELECT
 
  IF Change > 1 THEN
    ON ERROR GOTO FileErrHandler: FileError = 0
    IF LEFT$(Default$, LEN(Text$)) = LCASE$(Text$) THEN FileName$ = Default$ ELSE FileName$ = Text$
    IF MID$(FileName$, 2, 1) = ":" THEN Drive$ = LEFT$(FileName$, 2): FileName$ = MID$(FileName$, 3)
    IF INSTR(FileName$, "*") THEN
      FileMask$ = FileName$: GOSUB FileSelectTitle
    ELSEIF LEN(FileName$) THEN
      ShortName$ = GetShortFileName$(FileName$)
      CHDIR ShortName$
    END IF
    IF FileError THEN
      AttemptOpen ShortName$, FileNum
      IF FileNum THEN PageFileSelect = FileNum: EXIT DO' ELSE SOUND 1024, 1
    ELSE
      ON ERROR GOTO 0
      GOSUB FileSelect.GetList
      IF MenuChoices$(0) = ".." AND LastChoice > 0 THEN MenuChoice = 1 ELSE MenuChoice = 0
      Change = 1: BaseChoice = 0: PriorChoice = -1
      TextChange = 1: Text$ = "": Default$ = MenuChoices$(MenuChoice): CurPos = 0
      ListMatch = 0: ListChoice = 0
    END IF
  END IF
  IF Change THEN
    List.DrawFiles MenuChoices$(), MenuTypes(), 5, 13, 17, 26, MenuChoice, LastChoice, BaseChoice, PriorChoice
    IF NewChoice THEN Default$ = MenuChoices$(MenuChoice): Text$ = LEFT$(Default$, LEN(Text$)): CurPos = LEN(Text$): TextChange = 1
    Change = 0: NewChoice = 0
  END IF
  IF TextChange THEN
    Text$ = LCASE$(Text$)
    Prompt.Draw Text$, Default$, 3, 13, 26, CurPos, 0
    IF TextChange > 1 THEN ListMatch = 1: IF TextChange = 2 THEN ListChoice = 0
    TextChange = 0
  END IF
  IF ListMatch THEN
    Chars$ = LEFT$(MenuChoices$(ListChoice), LEN(Text$))
    IF Chars$ = Text$ THEN
      IF ListChoice <> MenuChoice OR LEN(Default$) = 0 THEN
        List.JumpTo ListChoice, MenuChoice, LastChoice, BaseChoice, 17, PriorChoice, Change
        TextChange = 1: Default$ = MenuChoices$(MenuChoice)
      END IF
      ListMatch = 0
    ELSE
      IF Chars$ > Text$ OR ListChoice >= LastChoice THEN
        List.JumpTo ListChoice, MenuChoice, LastChoice, BaseChoice, 17, PriorChoice, Change
        TextChange = 1: Default$ = ""
        ListMatch = 0: ListChoice = 0
      ELSE ListChoice = ListChoice + 1
      END IF
    END IF
  END IF
LOOP

MouseFunction 2
RestoreBackground 1, 13, 23, 26

EXIT FUNCTION

FileSelect.Draw:
  Menu.DrawBox 1, 13, 23, 26
  GOSUB FileSelectTitle

  List.DrawBox 3, 13, 1, 26
  List.DrawBox 5, 13, 17, 26

  IF Mode THEN Chars$ = "Save" ELSE Chars$ = "Load"
  Button.Draw 23, 13, 1, 5, 0, "Close"
  Button.Draw 23, 19, 1, 4, 0, Chars$
  MouseFunction 1
RETURN
FileSelectTitle:
  DrawWindowTitle Title$ + " [" + FileMask$ + "]", 1, 13, 26
RETURN

FileSelect.GetList:
  Label$ = GetFileList(Drive$ + "*.*", 16)
  FOR CurChoice = 0 TO 99
    Label$ = LCASE$(GetFileList("", 0))
    IF LEN(Label$) = 0 THEN EXIT FOR
    MenuChoices$(CurChoice) = LCASE$(Label$)
    MenuTypes(CurChoice) = 16
  NEXT
  Label$ = GetFileList(Drive$ + FileMask$, 239)
  DO
    IF LEN(Label$) = 0 THEN EXIT DO
    MenuChoices$(CurChoice) = LCASE$(Label$)
    MenuTypes(CurChoice) = FileType
    CurChoice = CurChoice + 1
    Label$ = LCASE$(GetFileList("", 0))
  LOOP WHILE CurChoice < 150
  LastChoice = CurChoice - 1
  GOSUB SortFileList
RETURN

SortFileList:
  FOR CurChoice = 0 TO LastChoice - 1
    ClosestMatch = 0
    FOR CompareChoice = CurChoice + 1 TO LastChoice
      IF MenuChoices$(CompareChoice) < MenuChoices$(CurChoice) THEN
        SWAP MenuChoices$(CompareChoice), MenuChoices$(CurChoice)
        SWAP MenuTypes(CompareChoice), MenuTypes(CurChoice)
      END IF
    NEXT CompareChoice
  NEXT CurChoice
RETURN

END FUNCTION

SUB PageSceneInfo
STATIC BaseChoice, MenuChoice
RESTORE SceneInfoLabels: READ LastChoice
REDIM MenuChoices$(LastChoice)

GOSUB SceneInfo.Draw
GOSUB SceneInfo.MakeList

Change = 1: PriorChoice = -1
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE ""
    IF MouseInfo(0, Presses, PointerY, PointerX) > 1 THEN
      IF PointerInGrid(PointerY, PointerX, 3, 1, 19, 38) THEN
        List.ReceiveMouse Presses, PointerY, 19, MenuChoice, LastChoice, BaseChoice, PriorChoice, Change
      ELSEIF PointerInGrid(PointerY, PointerX, 23, 1, 1, 5) THEN EXIT DO
      END IF
    END IF
  CASE CHR$(27), CHR$(13): EXIT DO
  CASE ELSE: List.ReceiveKey Key$, MenuChoices$(), MenuChoice, LastChoice, BaseChoice, 19, PriorChoice, Change
  END SELECT

  IF Change THEN
    List.Draw MenuChoices$(), 3, 1, 19, 38, MenuChoice, LastChoice, BaseChoice, PriorChoice
    Change = 0
  END IF
LOOP

MouseFunction 2
RestoreBackground 1, 1, 23, 38

EXIT SUB

SceneInfo.Draw:
  IF LEN(SnesFile$) = 0 THEN Chars$ = " [no savestate loaded]"
  Menu.DrawBox 1, 1, 23, 38
  DrawWindowTitle "Scene info" + Chars$, 1, 1, 38
  List.DrawBox 3, 1, 19, 38
  Button.Draw 23, 1, 1, 5, 0, "Close"
  Button.Draw 23, 7, 1, 9, 0, "Save info"
  MouseFunction 1
RETURN

SceneInfo.MakeList:
  DO
    READ Label$
    IF LEN(Label$) = 0 OR NumChoice > LastChoice THEN
      FOR CurChoice = NewBlock TO NumChoice - 1
        MenuChoices$(CurChoice) = MenuChoices$(CurChoice) + SPACE$(LongestString - LEN(MenuChoices$(CurChoice)) + 1)
      NEXT CurChoice
      NewBlock = NumChoice + 1
      LongestString = 0
      IF NumChoice > LastChoice THEN EXIT DO
    ELSEIF LEN(Label$) > LongestString THEN
      LongestString = LEN(Label$)
    END IF
    MenuChoices$(NumChoice) = Label$
    NumChoice = NumChoice + 1
  LOOP

  NumChoice = 0
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
      CASE 0: Chars$ = "(" + StrTrim(Index + 1) + ")"
      CASE 1: Chars$ = StrTrim(PlanesInfo(Index).Colors)'VideoModeColors
      CASE 2: Chars$ = StrYesNo(PlanesInfo(Index).Enabled)
      CASE 3: Chars$ = StrYesNo(PlanesInfo(Index).Subscreen)
      CASE 4: Chars$ = StrYesNo(SnesInfo.MosaicApplied AND 2 ^ Index)
      CASE 5: Chars$ = StrDim(PlanesInfo(Index).TileWidth, PlanesInfo(Index).TileHeight)
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
  Label$ = StrDim(SpriteSizes(SpriteSizeBase), SpriteSizes(SpriteSizeBase)) + ", " + StrDim(SpriteSizes(SpriteSizeBase + 1), SpriteSizes(SpriteSizeBase + 1)): GOSUB SceneInfo.AddLine
  Label$ = LTRIM$(STR$(SnesInfo.SpriteBase)): GOSUB SceneInfo.AddLine
  Label$ = StrTrim(BackColor(0)) + STR$(BackColor(1)) + STR$(BackColor(2)): GOSUB SceneInfo.AddLine
RETURN

SceneInfo.AddLine:
  IF NumChoice > LastChoice THEN RETURN
  MenuChoices$(NumChoice) = MenuChoices$(NumChoice) + RTRIM$(Label$)
  NumChoice = NumChoice + 1
  IF NumChoice > LastChoice THEN RETURN
  IF LEN(MenuChoices$(NumChoice)) = 0 THEN NumChoice = NumChoice + 1
RETURN

END SUB

SUB PageTitle

AttemptOpen "zsnesmap.pal", 0
IF FileError = 0 THEN
  SnesPalette$ = INPUT$(512, 1)
  PaletteConvert SnesPalette$, 0
  CLOSE 1
END IF
PaletteGUIcolors
PaletteColormap
PaletteSet

ON ERROR GOTO FileErrHandler
DEF SEG = VARSEG(MainBackground(0)): BLOAD "zsnesmap.pic", 0
ON ERROR GOTO 0

RestoreBackground 1, 1, 23, 38
Menu.DrawBox 10, 7, 6, 26
IF FileError THEN ColorBack = ColorDark ELSE ColorBack = ColorBlack
DrawStringShadow "Ver 0.02 for Qb, by FDwR, Sept 14, 1998", 0, 0, ColorWhite, ColorBack
DrawStringShadow "ZMapper", 11, 8, ColorWhite, ColorBlack
DrawStringShadow "Savestate Viewer", 11, 16, ColorGray, ColorBlack
DrawStringRow "Compatible with ZSNES .4", 13, 8, ColorGray
DrawStringRow "Savestates type .6", 14, 11, ColorGray
DrawStringShadow "Memory free:" + STR$(FRE(-1) \ 1024) + "k", 2, 1, ColorWhite, ColorBack
IF FileError THEN Chars$ = "Could not load background?" ELSE Chars$ = "Background loaded"
DrawStringShadow Chars$, 3, 1, ColorWhite, ColorBack
MouseFunction 0: MouseFunction 1
IF MousePresent THEN Chars$ = "Mouse detected" ELSE Chars$ = "Where is your mouse?"
DrawStringShadow Chars$, 4, 1, ColorWhite, ColorBack
SetWinTitle "Zsnes Savestate Viewer, Ver 0.02"
DrawStringShadow "Press whatever key you want to continue", 24, 0, ColorWhite, ColorBack

DO: LOOP UNTIL LEN(INKEY$) OR MouseInfo(0, 0, 0, 0) > 1

COLOR 48
MouseFunction 2
RestoreBackground 1, 1, 23, 38
InvertTest 117, 178, 132, 193
MouseFunction 1

END SUB

SUB PageViewPalette

Menu.DrawBox 1, 1, 23, 38
DrawWindowTitle "View palette", 1, 1, 38
Button.Draw 23, 1, 1, 5, 0, "Close"
Button.Draw 23, 7, 1, 6, 0, "Change"
Button.Draw 23, 14, 1, 10, 0, "Export pal"
Button.Draw 23, 25, 1, 10, 0, "Export raw"
DrawStringRow "Color value", 21, 1, ColorWhite
GOSUB ViewPal.DrawColors
MouseFunction 1

CurColor = 1: LastColor = 255
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE ""
    IF MouseInfo(0, Presses, PointerY, PointerX) THEN
      IF PointerInArea(PointerY, PointerX, TopRow, LeftCol, BtmRow, RiteCol) THEN
        NewColor = (PointerY \ Hite) * 16 + PointerX \ Wdth
      ELSEIF PointerInArea(PointerY, PointerX, 152, 8, 159, 311) THEN
        NewColor = PointerX \ Wdth + 256
        IF CurColor > 255 THEN CurColor = NewColor
      ELSEIF Presses THEN
        IF PointerInGrid(PointerY, PointerX, 23, 1, 1, 5) THEN EXIT DO
      END IF
    END IF
  CASE CHR$(27), CHR$(13): EXIT DO
  CASE CHR$(0) + "H": NewColor = CurColor - 16: IF NewColor < 0 THEN NewColor = 256 + (NewColor AND 15)
  CASE CHR$(0) + "P": NewColor = CurColor + 16: IF NewColor > 271 THEN NewColor = NewColor AND 15
  CASE CHR$(0) + "K": NewColor = CurColor - 1: IF NewColor < 0 THEN NewColor = 271 ELSE IF NewColor > 255 THEN NewColor = 255
  CASE CHR$(0) + "M": NewColor = CurColor + 1: IF NewColor > 256 THEN NewColor = 0
  END SELECT
 
  IF NewColor <> CurColor THEN
    MouseFunction 2
    GOSUB ViewPal.DrawColor
    'NewColor = NewColor AND LastColor
    CurColor = NewColor
    GOSUB ViewPal.HighlightColor
    MouseFunction 1
  END IF
LOOP

MouseFunction 2
RestoreBackground 1, 1, 23, 38

EXIT SUB

ViewPal.DrawColors:
  TopRow = 20: LeftCol = 8: Hite = 8: Wdth = 19: CurColor = 0
  BtmRow = TopRow + 16 * Hite - 1: RiteCol = LeftCol + 16 * Wdth - 1
  BlockHite = Hite - 1: BlockWdth = Wdth - 1

  DrawBorder TopRow - 1, BtmRow + 1, LeftCol - 1, RiteCol + 1, 1
  DrawBorder 151, 160, 7, 312, 1
  FOR Row = TopRow TO BtmRow STEP Hite
    FOR Col = LeftCol TO RiteCol STEP Wdth
      LINE (Col, Row)-(Col + BlockWdth, Row + BlockHite), ColorMapTable(CurColor), BF
      CurColor = CurColor + 1
    NEXT Col
  NEXT Row
  GOSUB ViewPal.BackColor
RETURN

ViewPal.HighlightColor:
  GOSUB ViewPal.GetBorder
  DrawBorder PixelTopRow, PixelBtmRow, PixelLeftCol, PixelRiteCol, 0
  DrawBorder PixelTopRow + 1, PixelBtmRow - 1, PixelLeftCol + 1, PixelRiteCol - 1, 1
  IF CurColor < 256 THEN
    ColorValue = CVI(MID$(SnesPalette$, CurColor * 2 + 1, 2))
    Chars$ = "#" + StrTrim(CurColor)
  ELSE
    ColorValue = BackColor(3)
    Chars$ = "Back"
  END IF
  Chars$ = Chars$ + ":" + HEX$(ColorValue) + " (" + StrTrim(ColorValue AND 31) + STR$((ColorValue AND 992) \ 32) + STR$((ColorValue AND 31744) \ 1024) + ")"
  LINE (112, 168)-(271, 175), ColorDark, BF
  DrawStringRow Chars$, 21, 14, ColorWhite
RETURN

ViewPal.DrawColor:
  'Row = (CurColor \ 16) * Hite + TopRow: Col = (CurColor AND 15) * Wdth + LeftCol
  GOSUB ViewPal.GetBorder
  IF CurColor > 255 THEN ColorValue = 64 ELSE ColorValue = ColorMapTable(CurColor)
  LINE (PixelLeftCol, PixelTopRow)-(PixelRiteCol, PixelBtmRow), ColorValue, BF
RETURN

ViewPal.GetBorder:
  IF CurColor < 256 THEN
    PixelTopRow = (CurColor \ 16) * Hite + TopRow: PixelLeftCol = (CurColor AND 15) * Wdth + LeftCol
    PixelBtmRow = PixelTopRow + BlockHite: PixelRiteCol = PixelLeftCol + BlockWdth
  ELSE
    PixelTopRow = 152: PixelBtmRow = 159
    PixelLeftCol = 8: PixelRiteCol = 311
  END IF
RETURN

ViewPal.BackColor:
  LINE (8, 152)-(311, 159), 64, BF
RETURN

END SUB

SUB PageViewScene

'Clicking in a tile will tell its plane, coordinates, size, number of colors,
'palette, wether it is flipped, and of course its tile number.
'Selecting a sprite will tell all the same things plus that sprite's number.
'You can export an individual tile, a single sprite, a whole tilemap, or
'the entire visible scene all from here.
'This sub depends largely on the DrawSceneLayers to redraw revealed portions
'as you pan around.
'The visible window is from column 0-319, row 0-179

IF SceneBufferOwner <> 1 OR UserScrollChange THEN UserScrollChange = 2
LastScrollY = UserScrollY: LastScrollX = UserScrollY

MouseFunction 1
DO
  Key$ = INKEY$
  SELECT CASE MID$(Key$, 2, 1)
  CASE ""
    SELECT CASE Key$
    CASE CHR$(27): EXIT DO
    CASE "+": UserScrollNewY = 1
    CASE "-": UserScrollNewY = -1
    CASE "*": UserScrollNewX = 1
    CASE "/": UserScrollNewX = -1
    CASE "": UserScrollY = 0: UserScrollX = 0: UserScrollChange = 1
    CASE "1" TO "5": PlaneMask = PlaneMask XOR 2 ^ (VAL(Key$) - 1): UserScrollChange = 2
    CASE "6": PlaneMask = -1: UserScrollChange = 2
    CASE ""
      IF MouseInfo(0, Presses, PointerY, PointerX) THEN
        IF Presses THEN Plane = Plane + 1: IF Plane > 3 THEN Plane = 0:  ELSE IF PlanesInfo(Plane).Colors = 0 THEN Plane = 0
        ShowSceneOffset Plane, PointerY, PointerX
      END IF
    END SELECT
  CASE "P": UserScrollNewY = 12
  CASE "H": UserScrollNewY = -12
  CASE "M": UserScrollNewX = 12
  CASE "K": UserScrollNewX = -12
  CASE "Q": UserScrollNewY = 128
  CASE "I": UserScrollNewY = -128
  CASE "O": UserScrollNewX = 128
  CASE "G": UserScrollNewX = -128
  END SELECT
  IF UserScrollNewY OR UserScrollNewX THEN
    UserScrollY = UserScrollY + UserScrollNewY
    UserScrollX = UserScrollX + UserScrollNewX
    UserScrollNewY = 0: UserScrollNewX = 0
    UserScrollChange = UserScrollChange OR 1
  END IF

  IF UserScrollChange AND LEN(Key$) = 0 THEN
    'scroll unchanged portion in buffer
    'determine new parts and draw only them
    Hite = UserScrollY - LastScrollY: LastScrollY = UserScrollY
    Wdth = UserScrollX - LastScrollX: LastScrollX = UserScrollX
    MouseFunction 2
    IF UserScrollChange > 1 THEN
      DrawSceneLayers PlaneMask, 0, 0, 179, 319
    ELSE
      IF ABS(Hite) > 180 THEN Hite = 180 * SGN(Hite)
      IF ABS(Wdth) > 320 THEN Wdth = 320 * SGN(Wdth)
      ScrollWindow 0, 0, 179, 319, Hite, Wdth
      IF Hite THEN
        IF Hite > 0 THEN TopRow = 180 - Hite ELSE TopRow = 0
        BtmRow = TopRow + ABS(Hite) - 1
        DrawSceneLayers PlaneMask, TopRow, 0, BtmRow, 319
        'InvertTest TopRow, 0, BtmRow, 319
        'LINE (0, TopRow)-(319, BtmRow), ColorWhite, B, 4369
        IF Hite > 0 THEN BtmRow = TopRow - 1: TopRow = 0 ELSE TopRow = BtmRow + 1: BtmRow = 179
      ELSE TopRow = 0: BtmRow = 179
      END IF
      IF Wdth THEN
        IF Wdth > 0 THEN LeftCol = 320 - Wdth ELSE LeftCol = 0
        RiteCol = LeftCol + ABS(Wdth) - 1
        DrawSceneLayers PlaneMask, TopRow, LeftCol, BtmRow, RiteCol
        'LINE (LeftCol, TopRow)-(RiteCol, BtmRow), ColorWhite, B, 26214
      END IF
    END IF
    MouseFunction 1
    UserScrollChange = 0
  END IF
LOOP

END SUB

SUB PageViewSprites
STATIC MenuChoice, BaseChoice
REDIM MenuChoices$(127)

GOSUB ViewSprites.Draw

OldBaseChoice = 19: PriorChoice = -1: Change = 1: ChoiceChange = 1
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE ""
    IF MouseInfo(0, Presses, PointerY, PointerX) > 1 THEN
      IF PointerInGrid(PointerY, PointerX, 3, 1, 16, 19) THEN
        List.ReceiveMouse Presses, PointerY, 16, MenuChoice, 127, BaseChoice, PriorChoice, Change
      ELSEIF PointerInGrid(PointerY, PointerX, 23, 1, 1, 5) THEN EXIT DO
      END IF
    END IF
    IF ChoiceChange THEN
      Char = SpriteOAM(MenuChoice * 2 + 1) AND 511
      Pal = (SpriteOAM(MenuChoice * 2 + 1) AND 3584) \ 512
      TileBase& = Char * 32 + SnesInfo.SpriteBase: PalBase = Pal * 16 + 128
      TopRow = 24
      MouseFunction 2
      LOCATE 22, 2: PRINT MenuChoice; Char; TileBase&; Pal; PalBase; TAB(30);
      DrawSingleSprite TileBase&, PalBase, TopRow, 184
      FOR CurColor = PalBase TO PalBase + 15
        LINE (168, TopRow)-(175, TopRow + 7), CurColor, BF
        TopRow = TopRow + 8
      NEXT CurColor
      MouseFunction 1
      ChoiceChange = 0
    END IF
  CASE CHR$(27): EXIT DO
  CASE "0" TO "9"
    Chars$ = StrTrim(MenuChoice)
    IF LEN(Chars$) < 3 THEN
      NewChoice = VAL(Chars$ + Key$)
      List.JumpTo NewChoice, MenuChoice, 127, BaseChoice, 16, PriorChoice, Change
    END IF
  CASE CHR$(8)
    Chars$ = StrTrim(MenuChoice)
    IF LEN(Chars$) THEN
      NewChoice = VAL(LEFT$(Chars$, LEN(Chars$) - 1))
      List.JumpTo NewChoice, MenuChoice, 127, BaseChoice, 16, PriorChoice, Change
    END IF
  CASE ELSE: List.ReceiveKey Key$, MenuChoices$(), MenuChoice, 127, BaseChoice, 16, PriorChoice, Change
  END SELECT

  IF Change > 1 THEN MainMenuChoice = 2: MainMenuSelect = 1: EXIT DO
  IF Change THEN
    IF BaseChoice <> OldBaseChoice THEN GOSUB ViewSprites.RemakeList: OldBaseChoice = BaseChoice
    List.Draw MenuChoices$(), 3, 1, 16, 19, MenuChoice, 127, BaseChoice, PriorChoice
    Change = 0
    ChoiceChange = 1
  END IF
LOOP

MouseFunction 2
RestoreBackground 1, 1, 23, 38

EXIT SUB

ViewSprites.Draw:
  Menu.DrawBox 1, 1, 23, 38
  DrawWindowTitle "Sprite List", 1, 1, 38
  List.DrawBox 3, 1, 16, 19
  List.DrawBox 3, 23, 16, 16
  List.DrawBox 3, 21, 16, 1
  List.DrawBox 20, 1, 2, 38
  Button.Draw 23, 1, 1, 5, 0, "Close"
  Button.Draw 23, 7, 1, 13, 0, "Export sprite"
  Button.Draw 23, 21, 1, 9, 0, "Save list"
  DrawStringRow "Num Tile Size  Position Pal Layer Flip", 20, 1, ColorGray
  DrawStringRow "107 467  16x32 512,97   6   2     H", 21, 1, ColorGray
  MouseFunction 1
RETURN

ViewSprites.RemakeList:
  DEF SEG = VARSEG(SpriteOAM(0))
  IF VARPTR(SpriteOAM(0)) THEN STOP
  BtmChoice = BaseChoice + 16: IF BtmChoice > 127 THEN BtmChoice = 127
  FOR Index = BaseChoice TO BtmChoice
    IF LEN(MenuChoices$(Index)) = 0 THEN
      Chars$ = SPACE$(20)
      MID$(Chars$, 1) = StrTrim(Index)
      MID$(Chars$, 5) = StrTrim(PEEK(BytePos)) + "," + StrTrim(PEEK(BytePos + 1))
      MID$(Chars$, 13) = StrTrim(PEEK(BytePos + 2) + 256 * (PEEK(BytePos + 3) AND 1))
      BytePos = BytePos + 4
      MenuChoices$(Index) = Chars$
    END IF
  NEXT Index
RETURN

END SUB

SUB PaletteColormap

REDIM InverseMapTemp(189)

DEF SEG = VARSEG(PaletteTable(0))

BytePos = VARPTR(PaletteTable(0)) + UsedColors * 48
FOR Index = 0 TO 2
  POKE BytePos + Index, BackColor(Index) * 2
NEXT Index
UsedColors = UsedColors + 1
BackColor(3) = BackColor(0) OR BackColor(1) * 32 OR BackColor(2) * 1024

BytePos = VARPTR(PaletteTable(0))
FOR CurColor = 0 TO 255
  ColorMapTable(CurColor) = CurColor
  ColorValue = PEEK(BytePos) + PEEK(BytePos + 1) + PEEK(BytePos + 2)
  IF ColorValue < 189 THEN InverseMapTemp(ColorValue) = CurColor
  BytePos = BytePos + 3
NEXT CurColor

CurChar = 1
FOR CurColor = 0 TO UsedColors * 16 - 1 STEP 16
  ColorValue = CVI(MID$(SnesPalette$, CurChar, 2))
  Red = (ColorValue AND 31) * 2
  Green = (ColorValue AND 992) \ 16
  Blue = (ColorValue AND 31744) \ 512
  BytePos = VARPTR(PaletteTable(0))
  ClosestContrast = 255
  FOR CompareColor = 0 TO 255
    ColorContrast = ABS(Red - PEEK(BytePos)) + ABS(Green - PEEK(BytePos + 1)) + ABS(Blue - PEEK(BytePos + 2))
    IF ColorContrast < ClosestContrast THEN
      IF CompareColor AND 207 THEN
        ClosestMatch = CompareColor: IF ColorContrast = 0 THEN EXIT FOR ELSE ClosestContrast = ColorContrast
      END IF
    END IF
    BytePos = BytePos + 3
  NEXT CompareColor
  ColorMapTable(CurColor) = ClosestMatch
  CurChar = CurChar + 32
NEXT CurColor

ClosestMatch = 0
FOR CurColor = 0 TO 189
  CompareColor = InverseMapTemp(CurColor)
  IF CompareColor THEN ClosestMatch = CompareColor ELSE InverseMapTemp(CurColor) = ClosestMatch
NEXT CurColor

BytePos = VARPTR(PaletteTable(0))
FOR CurColor = 0 TO 255
  ColorValue = (PEEK(BytePos) + PEEK(BytePos + 1) + PEEK(BytePos + 2) + 94) MOD 189
  InverseColorTable(CurColor) = InverseMapTemp(ColorValue)
  'CurChar = VARPTR(PaletteTable(0))
  'ClosestContrast = 255
  'FOR CompareColor = 0 TO 255
  '  ColorContrast = ABS(Red - PEEK(CurChar)) + ABS(Green - PEEK(CurChar + 1)) + ABS(Blue - PEEK(CurChar + 2))
  '  IF ColorContrast < ClosestContrast THEN ClosestMatch = CompareColor: IF ColorContrast = 0 THEN EXIT FOR ELSE ClosestContrast = ColorContrast
  '  CurChar = CurChar + 3
  'NEXT CompareColor
  'InverseColorTable(CurColor) = ClosestMatch
  BytePos = BytePos + 3
NEXT CurColor

END SUB

SUB PaletteConvert (Palette$, Mode)
'Converts a 15bit SNES palette to a more useable 24bit format

IF Mode THEN
  Red = 8: Green = 4: Blue = 128
ELSE
  Red = 2: Green = 16: Blue = 512
END IF

DEF SEG = VARSEG(PaletteTable(0))
BytePos = VARPTR(PaletteTable(0))
FOR CurColor = 1 TO 512 STEP 2
  ColorValue = CVI(MID$(Palette$, CurColor, 2))
  POKE BytePos, (ColorValue AND 31) * Red
  POKE BytePos + 1, (ColorValue AND 992) \ Green
  POKE BytePos + 2, (ColorValue AND 31744) \ Blue
  BytePos = BytePos + 3
NEXT CurColor

END SUB

SUB PaletteGUIcolors

RESTORE GUIcolors
READ UsedColors
DEF SEG = VARSEG(PaletteTable(0))
BytePos = VARPTR(PaletteTable(0))
FOR CurColor = 0 TO UsedColors - 1
  READ Red, Green, Blue
  POKE BytePos, Red
  POKE BytePos + 1, Green
  POKE BytePos + 2, Blue
  BytePos = BytePos + 48
NEXT CurColor

END SUB

SUB PaletteSet

DEF SEG = VARSEG(PaletteTable(0))
BytePos = VARPTR(PaletteTable(0))
OUT &H3C8, 0
FOR CurColor = 0 TO 255
  OUT &H3C9, PEEK(BytePos)
  OUT &H3C9, PEEK(BytePos + 1)
  OUT &H3C9, PEEK(BytePos + 2)
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
'Returns wether or not the mouse is in a certain text grid and returns the
'reduced pointer coordinates. Used mainly for menus or lists.

Row = PointerY \ FontSize: Col = PointerX \ FontSize
IF Row < TopRow OR Col < LeftCol THEN EXIT FUNCTION

Row = Row - TopRow: Col = Col - LeftCol
IF Row > Hite - 1 OR Col > Wdth - 1 THEN EXIT FUNCTION

PointerY = Row: PointerX = Col
PointerInGrid = -1

END FUNCTION

SUB Prompt.Draw (Text$, Default$, TopRow, LeftCol, Wdth, CurPos, TxtLim)

TextLen = LEN(Text$)
PixelLeftCol = LeftCol * FontSize
PixelRiteCol = PixelLeftCol + Wdth * FontSize - 1
PixelTopRow = TopRow * FontSize: PixelBtmRow = PixelTopRow + 7

MouseFunction 2
LINE (PixelLeftCol, PixelTopRow)-(PixelRiteCol, PixelBtmRow), ColorDark, BF
DrawStringRow LEFT$(Text$, Wdth), TopRow, LeftCol, ColorGray
DrawStringRow MID$(Default$, TextLen + 1), TopRow, LeftCol + TextLen, ColorBlack
PixelLeftCol = (LeftCol + CurPos) * FontSize
IF CurPos < Wdth THEN LINE (PixelLeftCol, PixelTopRow)-(PixelLeftCol + 1, PixelBtmRow), ColorWhite, BF
MouseFunction 1

END SUB

SUB Prompt.ReceiveKey (Key$, Text$, Default$, CurPos, TxtLim, Change)

TextLen = LEN(Text$)
SELECT CASE Key$
CASE CHR$(8): IF CurPos > 0 THEN Text$ = LEFT$(Text$, CurPos - 1) + MID$(Text$, CurPos + 1): CurPos = CurPos - 1: Change = 2
CASE CHR$(0) + "K": IF CurPos > 0 THEN CurPos = CurPos - 1: Change = 1
CASE CHR$(0) + "M"
  IF CurPos < TextLen THEN
    CurPos = CurPos + 1: Change = 1
  ELSEIF CurPos < LEN(Default$) THEN
    CurPos = CurPos + 1: Change = 1
    Text$ = Text$ + MID$(Default$, CurPos, 1)
  END IF
CASE " " TO "ÿ": IF TextLen < TxtLim THEN Text$ = LEFT$(Text$, CurPos) + Key$ + MID$(Text$, CurPos + 1): CurPos = CurPos + 1: Change = 3
END SELECT

END SUB

SUB RestoreBackground (TopRow, LeftCol, Hite, Wdth)

PixelTopRow = (TopRow - 1) * FontSize * 320
PixelLeftCol = (LeftCol - 1) * FontSize
Source = CVI(MKI$(PixelTopRow + PixelLeftCol)): Dest = Source

'parameters are passed left to right
DEF SEG = VARSEG(BackgroundBlit$)
CALL ABSOLUTE(BYVAL (Hite + 2) * FontSize, BYVAL (Wdth + 2) * FontSize, BYVAL Dest, BYVAL VARSEG(MainBackground(0)), BYVAL Source, SADD(BackgroundBlit$))

END SUB

SUB ScrollWindow (TopRow, LeftCol, BtmRow, RiteCol, Hite, Wdth)

IF Hite > BtmRow - TopRow OR Wdth > RiteCol - LeftCol THEN EXIT SUB
IF Hite >= 0 THEN Temp = TopRow: NextRow = 320 ELSE Temp = BtmRow: NextRow = -320
Source& = (Temp + Hite) * 320&: Dest& = Temp * 320&
IF Wdth >= 0 THEN Temp = LeftCol: NextCol = 1 ELSE Temp = RiteCol: NextCol = -1
Source& = Source& + Temp + Wdth: Dest& = Dest& + Temp

DEF SEG = &HA000
LastCol = RiteCol - LeftCol - ABS(Wdth) + 1
FOR CurRow = 1 TO BtmRow - TopRow - ABS(Hite) + 1
  TempSource& = Source&: TempDest& = Dest&
  FOR CurCol = 1 TO LastCol
    POKE TempDest&, PEEK(TempSource&)
    TempSource& = TempSource& + NextCol: TempDest& = TempDest& + NextCol
  NEXT CurCol
  Source& = Source& + NextRow
  Dest& = Dest& + NextRow
NEXT CurRow

END SUB

SUB SetWinTitle (Title$)

'EXIT SUB

Title$ = Title$ + CHR$(0)

Regs.Ax = &H168E'set/get Window attribute
Regs.Bx = 0
Regs.Cx = 0
Regs.Dx = 0'set window Title
Regs.Cx = LEN(Title$)
Regs.Es = VARSEG(Title$)
Regs.Di = SADD(Title$)

CALL InterruptX(&H2F, Regs, Regs)

END SUB

SUB ShowSceneOffset (Plane, TopRow, LeftCol)

IF PlanesInfo(Plane).Colors < 1 THEN EXIT SUB
TileSize = PlanesInfo(Plane).TileSize: IF TileSize < 1 THEN EXIT SUB
TileBase& = PlanesInfo(Plane).TileBase
MapBase& = PlanesInfo(Plane).MapBase
MapWidth = PlanesInfo(Plane).TileWidth
MapHeight = PlanesInfo(Plane).TileHeight
Bits = VideoModeBpls(PlaneBitsBase + Plane)
Colors = PlanesInfo(Plane).Colors

LOCATE 24, 1: PRINT Plane; ";";
Scroll& = PlanesInfo(Plane).ScrollY + TopRow + UserScrollY
TopTile = (Scroll& AND PlanesInfo(Plane).PixelHeight - 1) \ TileSize
PixelTopRow = TopRow - (Scroll& AND TileSize - 1)
PRINT Scroll&; TopTile; PixelTopRow; ";";

Scroll& = PlanesInfo(Plane).ScrollX + LeftCol + UserScrollX
LeftTile = (Scroll& AND PlanesInfo(Plane).PixelWidth - 1) \ TileSize
PixelLeftCol = LeftCol - (Scroll& AND TileSize - 1)
PRINT Scroll&; LeftTile; PixelLeftCol; TAB(40);

MainTilePtr& = MapBase& + ((TopTile AND 32) * MapWidth * 2) + ((TopTile AND 31) * 64)
LeftPtr = (LeftTile AND 32) * 64 + (LeftTile AND 31) * 2
TilePtr& = MainTilePtr& + LeftPtr
LOCATE 25, 1: PRINT MainTilePtr&; LeftPtr; TilePtr&; TAB(25);

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

CLS

MapBase& = PlanesInfo(0).MapBase: Change = 1
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE CHR$(27): EXIT DO
  CASE "1" TO "4"
    Temp = VAL(Key$) - 1: MapBase& = PlanesInfo(Temp).MapBase: Change = 1
    IF PlanesInfo(Temp).Colors THEN Plane = Temp
  CASE " "
    Plane = Plane + 1
    IF Plane > 3 THEN Plane = 0 ELSE IF PlanesInfo(Plane).Colors <= 0 THEN Plane = 0
    Change = 1
  CASE CHR$(0) + "P": IF MapBase& < 64512 THEN MapBase& = MapBase& + 1024: Change = 1
  CASE CHR$(0) + "H": IF MapBase& >= 1024 THEN MapBase& = MapBase& - 1024: Change = 1
  CASE CHR$(0) + "M": IF MapBase& < 65472 THEN MapBase& = MapBase& + 64: Change = 1
  CASE CHR$(0) + "K": IF MapBase& >= 64 THEN MapBase& = MapBase& - 64: Change = 1
  CASE CHR$(13): Change = 1: PlanesInfo(Plane).TileBase = PlanesInfo(Plane).TileBase + 2048: IF PlanesInfo(Plane).TileBase > 65535 THEN PlanesInfo(Plane).TileBase = 0
  END SELECT
 
  IF Change THEN
    DrawTileMapOld MapBase&, Plane
    LOCATE 25, 1: PRINT Plane; MapBase&; TAB(12);
    WHILE LEN(INKEY$): WEND
    Change = 0
  END IF
LOOP

RestoreBackground 1, 1, 23, 38

END SUB

SUB ViewVRAM

CLS

GOSUB PlaneSet
Change = 1
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE CHR$(0) + "P": IF TileBase& + PageSize& < 65536 THEN TileBase& = TileBase& + PageSize&: GOSUB CheckVRAMptr
  CASE CHR$(0) + "H": IF TileBase& > 0 THEN TileBase& = TileBase& - PageSize&: GOSUB CheckVRAMptr
  CASE CHR$(0) + "M": CurPal = (CurPal + 1) AND 15: Change = 1
  CASE CHR$(0) + "K": CurPal = (CurPal - 1) AND 15: Change = 1
  CASE "1" TO "3": Bits = 2 ^ VAL(Key$): GOSUB BplSet: GOSUB CheckVRAMptr
  CASE "4": Linear = 1: Bits = 8: Size = 128: PageSize& = Size * 256&: GOSUB CheckVRAMptr
  CASE " "
    Plane = Plane + 1
    IF Plane > 3 THEN Plane = 0 ELSE IF PlanesInfo(Plane).Colors <= 0 THEN Plane = 0
    GOSUB PlaneSet
    Change = 1
  CASE CHR$(27): EXIT DO
  END SELECT

  IF Change THEN GOSUB DrawTilesWindow: Change = 0
LOOP

EXIT SUB

PlaneSet:
  Bits = VideoModeBpls(PlaneBitsBase + Plane)
  Colors = PlanesInfo(Plane).Colors
  IF SnesInfo.VideoMode = 7 THEN Linear = 1: Bits = 8: Size = 128 ELSE Linear = 0: Size = 8 * Bits
  PageSize& = Size * 256&
RETURN

BplSet:
  Colors = 2 ^ Bits
  Size = 8 * Bits
  PageSize& = Size * 256&
  Linear = 0
RETURN

DrawTilesWindow:
  TopRow = 0: LeftCol = 0: TempBase& = TileBase&: PalBase = CurPal * Colors
 
  FOR CurChar = 0 TO 255
    IF Linear THEN DrawMode7Tile TempBase&, TopRow, LeftCol ELSE DrawBplTile TempBase&, Bits, PalBase, TopRow, LeftCol, 0
    TempBase& = TempBase& + Size
    LeftCol = LeftCol + 8
    IF LeftCol >= 128 THEN TopRow = TopRow + 8: LeftCol = 0
  NEXT CurChar
  LOCATE 25, 1: PRINT TileBase&; Plane; Bits; CurPal; TAB(30);
RETURN

CheckVRAMptr:
  IF TileBase& < 0 THEN TileBase& = 0
  IF TileBase& > 65535 - PageSize& THEN TileBase& = 65536 - PageSize&
  Change = 1
RETURN

RestoreBackground 1, 1, 23, 38

END SUB

