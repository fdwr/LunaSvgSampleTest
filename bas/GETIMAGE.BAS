DEFINT A-Z
DECLARE SUB KeyWait ()
CONST MainMenuChoices = 9, ImageBMP = 0, ImageGIF = 1, ImagePCX = 2, ImageLBM = 3, ImagePAL = 4
CONST TRUE = -1, FALSE = 0
TYPE RegType
  ax AS INTEGER: bx AS INTEGER
  cx AS INTEGER: dx AS INTEGER
  bp AS INTEGER: si AS INTEGER
  di AS INTEGER: fl AS INTEGER
  ds AS INTEGER: es AS INTEGER
END TYPE
DIM SHARED regs AS RegType

SCREEN 0: VIEW PRINT 1 TO 25: LOCATE , , 0

NewImage = 1
'Allocate image buffer and define main menu
DIM ImageBuffer(0 TO 16382) AS LONG, ImagePalette(0 TO 255) AS LONG
REDIM MainMenuOps$(0 TO MainMenuChoices - 1)
MainMenuOps$(0) = "View an image (BMP, GIF, PCX, LBM) in buffer"
MainMenuOps$(1) = "Save image into a single linear bitmap (LBM)"
MainMenuOps$(2) = "Export an image into a linear bitmap collection"
MainMenuOps$(3) = "Append to a Qbasic program as DATA statements"
MainMenuOps$(4) = "Save last palette to a raw file (PAL)"
MainMenuOps$(5) = "Edit a linear bitmap collection"
MainMenuOps$(6) = "View image buffer (last picture loaded)"
MainMenuOps$(7) = "Restore default palette to image buffer"
MainMenuOps$(8) = "Draw a test pattern into the image buffer"
'submenu of multi-lbm's includes
'  condense collection (useful if you've done a lot of saving\resaving)
'  output pointers of all lbm's to a text file (or Qbasic program)
'  delete a lbm from the collection
'  move (shift) a single or entire group of lbm's around
'  edit the names of each individual lbm

'GOSUB GetStartPath
'IF LEN(COMMAND$) THEN NewFile$ = COMMAND$: GOSUB OpenImage

MainMenu:
CLS
VIEW PRINT 1 TO 25
PRINT "Bitmap importer by FDwR, written in Qbasic, compiled with QB 4.5  Ver 0.2 : 4-98"
PRINT "If you have ever wanted to import a bitmap you drew with PaintBrush, a picture"
PRINT "you stole using PrntScrn, some cool GIF's you found on the Internet, or a sprite"
PRINT "you ripped out of some elses game, this can help you to get them in there and"
PRINT "liven up your Qbasic games with graphics that you thought were impossible in"
PRINT "this small language. It also includes some fast assembly code you can use."
PRINT "Use the arrow keys and Enter to make your choice, press Esc to quit when done"
PRINT "If you want some more info about GETIMAGE, F1 will bring up some meager help."
PRINT

MenuRow = 10: MenuCol = 15
ShowChoice = -1 'Set to show all choices
LastChoice = MainMenuChoices - 1
GOSUB ShowMainMenu 'Draw the menu

DO
  SELECT CASE INKEY$
  CASE CHR$(0) + "H"
    NewChoice = MenuChoice - 1
    IF NewChoice < 0 THEN NewChoice = LastChoice
  CASE CHR$(0) + "P"
    NewChoice = MenuChoice + 1
    IF NewChoice > LastChoice THEN NewChoice = 0
  CASE CHR$(13)
    LOCATE 20, 1: COLOR 7
    SELECT CASE MenuChoice
    CASE 0
      CLS
      PRINT "Type in the filename to load an image from, or nothing and Enter to cancel"
      PRINT "You can also get a list of images in the current directory by typing a wildcard"
      PRINT "in the name; for example, '*.bmp' would list all the bitmaps whatever their"
      PRINT "name is. Changing directory is possible with '..' to go back one and the name"
      PRINT "of the directorty to go forward into. Typing 'GAMES' from 'C:\WINDOWS' would"
      PRINT "take you to 'C:\WINDOWS\GAMES'. Typing 'C:\' would go back to the root directory"
      DO
        GOSUB GetFileName 'If the user entered a name
        IF LEN(NewFile$) THEN
          GOSUB OpenImage
          IF NoSuccess = 0 THEN EXIT DO
        ELSE EXIT DO
        END IF
      LOOP
      GOTO MainMenu
    CASE 1
      GOSUB ExportImageToLBM
      GOTO MainMenu
    CASE 2
    CASE 3
    CASE 4
      GOSUB SavePalette
      GOTO MainMenu
    CASE 6
      GOSUB ViewImage
      GOTO MainMenu
    CASE 7
      GOSUB MakeDefaultPalette
    CASE 8
      GOSUB MakeTestPattern
      GOSUB ViewImage
      GOTO MainMenu
    END SELECT
  CASE CHR$(0) + ";"
    GOSUB ShowOpeningHelp
    GOTO MainMenu
  CASE CHR$(27): EXIT DO
  END SELECT

  IF NewChoice <> MenuChoice THEN
    ShowChoice = MenuChoice
    MenuChoice = NewChoice
    GOSUB ShowMainMenu
    ShowChoice = MenuChoice
    GOSUB ShowMainMenu
  END IF
LOOP

LOCATE 25, 1: PRINT
SYSTEM

ShowMainMenu:
  IF ShowChoice = -1 THEN ShowChoice = 0: LastItem = LastChoice ELSE LastItem = ShowChoice
  FOR CurItem = ShowChoice TO LastItem
    IF CurItem = MenuChoice THEN COLOR 15 ELSE COLOR 7
    LOCATE MenuRow + CurItem, MenuCol
    PRINT MainMenuOps$(CurItem);
  NEXT CurItem
RETURN

ShowOpeningHelp:
  CLS
  PRINT "Sorry, no help yet...I did say it was meager!"
  KeyWait
RETURN

OpenImage:
  GOSUB DetermineType
  IF NoSuccess THEN KeyWait
  GOSUB OpenBinaryFile 'Open the file
  IF FilErr THEN PRINT "Could not open that image, did you spell it right?"; FilErr: KeyWait: RETURN'If there weren't any file errors
  ImageFileName$ = NewFile$
  GOSUB GetImageAttributes 'Read the picture's header
  IF NoSuccess THEN CLOSE 1: RETURN    'If picture was the right type
  GOSUB DecodeFileImage    'Load uncompressed pixel data into buffer
  CLOSE 1
  IF NoSuccess THEN NoSuccess = 0: RETURN  'If user pressed Esc
  GOSUB ViewImage
  NoSuccess = 0
RETURN

DetermineType:
  ImageType = INSTR(".BMP.GIF.PCX.LBM.PAL", RIGHT$(NewFile$, 4))
  IF ImageType = 0 THEN
    PRINT "Type of image not known, this program does support:"
    PRINT "  BMP - Standard Windows 256 color bitmaps"
    PRINT "  GIF - Non-interlaced graphics information files"
    PRINT "  PCX - Paintbrush picture format"
    PRINT "  LBM - Generic (Qbasic compatible) linear bitmap"
    NoSuccess = 1
  ELSE
    NoSuccess = 0
    ImageType = (ImageType - 1) \ 4
  END IF
RETURN

ViewImage:
  'Shows the image buffer on the screen in mode 13 (320x200 256 colors)
  'Responsible for loading in the bitmap blitting code, setting the screen
  'mode, centering the image, and displaying it
  'Expects that the image buffer actually has an image in it loaded before
  'it is called. If you try to display an empty buffer, it will give an error
  IF ImageHeight = 0 OR ImageWidth = 0 THEN
    PRINT "! Image buffer is blank, can not display it !"
    KeyWait 'Wait until key is pressed
    CLS
    RETURN MainMenu
  END IF
  IF LEN(BlitBmpCode$) = 0 THEN
    GOSUB LoadPixelBlitCode
    IF NoSuccess AND TriedCodeLoad = 0 THEN
      PRINT "Fast pixel blitting code is missing; could not find BLIT_BMP.COM"
      PRINT "Be sure that it is in the same directory as GETIMAGE.BAS: " + RIGHT$(Path$, 22)
      PRINT "Will simply use slower Qbasic FOR:NEXT loop and PSET instead";
      KeyWait
      TriedCodeLoad = 1
    END IF
  END IF
  IF PaletteFilled = 0 THEN GOSUB MakeDefaultPalette
 
  SCREEN 13
  LINE (0, 0)-(319, 199), BgColor, BF
  GOSUB SetToImagePalette

  TopRow = (200 - EvenHeight) \ 2
  LeftCol = (320 - EvenWidth) \ 2

  IF LEN(BlitBmpCode$) THEN
    'LeftCol TopRow Width Height SourceOfset SourceSeg
    DEF SEG = VARSEG(BlitBmpCode$)
    CALL ABSOLUTE(BYVAL LeftCol, BYVAL TopRow, BYVAL EvenWidth, BYVAL EvenHeight, BYVAL VARPTR(ImageBuffer(0)), BYVAL VARSEG(ImageBuffer(0)), SADD(BlitBmpCode$))
  ELSE
    DEF SEG = VARSEG(ImageBuffer(0))
    Index& = VARPTR(ImageBuffer(0))
    Row = 0: Col = 0
    'COLOR 98
    WHILE Row < EvenHeight
      WHILE Col < EvenWidth
        'IF PEEK(Index&) = 248 THEN POKE Index&, 8
        PSET (Col, Row), PEEK(Index&)
        Index& = Index& + 1
        Col = Col + 1
      WEND
      'LOCATE 25, 1: PRINT Index&; Index& - LastIndex&;
      LastIndex& = Index&
      Row = Row + 1
      Col = 0
    WEND
  END IF
  KeyWait
  WIDTH 80, 25: SCREEN 0
RETURN

SetToImagePalette:
  DEF SEG = VARSEG(ImagePalette(0))
  OUT &H3C8, 0
  FOR BytePos = VARPTR(ImagePalette(0)) TO VARPTR(ImagePalette(0)) + 1023 STEP 4
    OUT &H3C9, PEEK(BytePos + 2) \ 4
    OUT &H3C9, PEEK(BytePos + 1) \ 4
    OUT &H3C9, PEEK(BytePos + 0) \ 4
  NEXT BytePos
  'Alternate method
  'OUT &h3C9,(RGBtuple& AND 16711680) \ 262144 'Red
  'OUT &h3C9,(RGBtuple& AND 65280) \ 1024      'Green
  'OUT &h3C9,(RGBtuple& AND 255) \ 4           'Blue
RETURN

MakeDefaultPalette:
  PRINT "Setting colors..."
  DEF SEG = VARSEG(ImagePalette(0))
  Rcolor = 0: Gcolor = 0: Bcolor = 0
  FOR BytePos = VARPTR(ImagePalette(0)) TO VARPTR(ImagePalette(0)) + 1023 STEP 4
    POKE BytePos, Rcolor * 51
    POKE BytePos + 1, Gcolor * 51
    POKE BytePos + 2, Bcolor * 51
    Rcolor = Rcolor + 1
    IF Rcolor > 5 THEN Rcolor = 0: Gcolor = Gcolor + 1: IF Gcolor > 5 THEN Gcolor = 0: Bcolor = Bcolor + 1
  NEXT BytePos
  PRINT "Default palette set"
  PaletteFilled = 1
RETURN

OpenBinaryFile:
  ON ERROR GOTO FilErrHan: FilErr = 0
  OPEN NewFile$ FOR INPUT AS 1: CLOSE 1
  ON ERROR GOTO 0
  IF FilErr THEN RETURN
  OPEN NewFile$ FOR BINARY AS 1
RETURN

GetImageAttributes:
  'Loads in height, width, colors, & type from the image's file header
  'Palette and image data are left to 'DecodeFileImage'
  'It assumes the file has already been opened
  IF ImageType = ImageBMP THEN
    PRINT "File size:"; LOF(1)
    Header$ = SPACE$(34)
    GET 1, 1, Header$
    HeaderSize = CVI(MID$(Header$, 15, 4))
    PRINT "Size of header:"; HeaderSize
    ImageFileOffset& = CVI(MID$(Header$, 11, 4)) + 1
    PRINT "Number of bytes offset from beginning "; ImageFileOffset&
    PixelBits = CVI(MID$(Header$, 29, 4))
    PRINT "Bits per pixel:"; PixelBits
    IF PixelBits <> 8 AND PixelBits <> 4 THEN PRINT "Can only 256 color or 16 color bitmaps": NoSuccess = 1: RETURN
    IF PixelBits = 8 THEN FilePalette$ = SPACE$(1024) ELSE FilePalette$ = SPACE$(64)
    ImageWidth = CVL(MID$(Header$, 19, 4))
    PRINT "Width:"; ImageWidth
    ImageHeight = CVL(MID$(Header$, 23, 4))
    PRINT "Height:"; ImageHeight
    PRINT "Loading palette..."
    GET 1, 55, FilePalette$
    Index = 0
    RGBbackground = 255
    FOR BytePos = 1 TO LEN(FilePalette$) STEP 4
      RGBtuple& = CVL(MID$(FilePalette$, BytePos, 4))
      Rcolor = (RGBtuple& AND 16711680) \ 65536
      Gcolor = (RGBtuple& AND 65280) \ 256
      Bcolor = RGBtuple& AND 255
      ImagePalette(Index) = RGBtuple&
      RGBtuple& = Rcolor + Gcolor + Bcolor
      IF RGBtuple& < RGBbackground THEN BgColor = Index: RGBbackground = RGBtuple&
      Index = Index + 1
    NEXT BytePos
    '>>Older slower method
    'Rcolor = ASC(MID$(FilePalette$, BytePos + 2, 1)) \ 4: OUT &H3C9, Rcolor
    'Gcolor = ASC(MID$(FilePalette$, BytePos + 1, 1)) \ 4: OUT &H3C9, Gcolor
    'Bcolor = ASC(MID$(FilePalette$, BytePos, 1)) \ 4: OUT &H3C9, Bcolor
    FilePalette$ = "": NoSuccess = 0
    PaletteFilled = 1
    IF HeaderSize = 40 THEN IF CVL(MID$(Header$, 31, 4)) THEN PRINT "RLE compression is not supported": NoSuccess = 1: RETURN
  ELSEIF ImageType = ImageGIF OR ImageType = ImagePCX OR ImageType = ImagePAL THEN
    PRINT "Loading palette..."
    FilePalette$ = SPACE$(769)
    IF ImageType = ImagePCX THEN
      GET 1, LOF(1) - 767, FilePalette$ 'standard 256-color pcx palette
    ELSEIF ImageType = ImageGIF THEN
      GET 1, 13, FilePalette$ 'standard 256-color gif palette
    ELSE
      GET 1, 1, FilePalette$ '256-color pal palette with no picture data
    END IF
    BytePos = 1
    FOR Index = 0 TO 255
      ImagePalette(Index) = CVL(MID$(FilePalette$, BytePos, 4))
      BytePos = BytePos + 3
    NEXT Index
    PaletteFilled = 1
    FilePalette$ = "": NoSuccess = 0
  ELSEIF ImageType = ImageLBM THEN '256 color image data without palette
    PRINT "File size:"; LOF(1)
    GET 1, 1, ImageHeight
    PRINT "Height: "; ImageHeight
    GET 1, 3, ImageWidth
    PRINT "Width: "; ImageWidth
    ImageFileOffset& = 5
    PRINT "Number of bytes offset from beginning: "; ImageFileOffset&
    PixelBits = 8
    PRINT "Bits per pixel: "; PixelBits
    PRINT "No palette data, using existing one"
  END IF
RETURN

DecodeFileImage: 'BMP GIF PCX
  'Grabs the palette and uncompresses any image data into ImageBuffer()
  'Attributes from the image's header are by 'GetImageAttributes'
  'It assumes the file has already been opened and the header been read
  PRINT "Loading image..."
  SELECT CASE ImageType
  CASE ImageBMP, ImageLBM
    BytePos& = ImageFileOffset&
    RowBytes = ImageWidth * CLNG(PixelBits) \ 8
    'PixelRow = space$(RowBytes)
    EvenWidth = (ImageWidth + 3) AND -4&
    IF EvenWidth > 320 THEN RowJump = EvenWidth - 320: EvenWidth = 320 ELSE RowJump = 0
    IF ImageHeight > 200 THEN EvenHeight = 200: BytePos& = BytePos& ELSE EvenHeight = ImageHeight
    MultWidth = EvenWidth \ 4
    IF ImageType = ImageBMP THEN
      Index = (EvenHeight - 1) * MultWidth
      IndexBack = MultWidth + MultWidth
    ELSE
      Index = 0
      IndexBack = 0
    END IF
    IF PixelBits = 4 THEN
      'RowJump = 2'EvenWidth - ImageWidth
      FOR Row = 1 TO EvenHeight
        FOR Col = 1 TO MultWidth
          GET 1, BytePos&, PixelStrip
          ImageBuffer(Index) = ((PixelStrip AND 15) * 256) OR ((PixelStrip AND 240) \ 16) OR ((PixelStrip AND 3840) * 65536) OR ((PixelStrip AND 61440) * 16)
          BytePos& = BytePos& + 2
          Index = Index + 1
        NEXT
        Index = Index - IndexBack
        BytePos& = BytePos& + RowJump
      NEXT
    ELSE
      FOR Row = 1 TO EvenHeight
        FOR Col = 1 TO MultWidth
          GET 1, BytePos&, ImageBuffer(Index)
          BytePos& = BytePos& + 4
          Index = Index + 1
        NEXT
        Index = Index - IndexBack
        'BytePos& = BytePos& + RowJump
      NEXT
    END IF
  CASE ImageGIF, ImagePCX
    PRINT "Sorry, do not support GIF or PCX yet, but will soon..."
    PRINT "Until that time, just use a paint program to convert them in a bitmap (BMP)."
    KeyWait
    NoSuccess = 1
    RETURN
  END SELECT
  NewImage = 0
RETURN

MakeTestPattern:
  ImageWidth = 256: EvenWidth = ImageWidth
  ImageHeight = 200: EvenHeight = ImageHeight
  Index = 0
  BgColor = 210
  FOR Row = 0 TO 255 STEP 32
    FOR RowJump = 1 TO 4
      FOR Col = 0 TO 31
        RGBtuple& = CVL(STRING$(4, Row + Col))
        ImageBuffer(Index) = RGBtuple&
        ImageBuffer(Index + 1) = RGBtuple&
        ImageBuffer(Index + 64) = RGBtuple&
        ImageBuffer(Index + 65) = RGBtuple&
        ImageBuffer(Index + 128) = RGBtuple&
        ImageBuffer(Index + 129) = RGBtuple&
        ImageBuffer(Index + 192) = RGBtuple&
        ImageBuffer(Index + 193) = RGBtuple&
        Index = Index + 2
      NEXT Col
      Index = Index + 192
    NEXT RowJump
  NEXT Row
  FOR Col = 0 TO 255 STEP 4
    RGBtuple& = CVL(CHR$(Col) + CHR$(Col + 1) + CHR$(Col + 2) + CHR$(Col + 3))
    FOR Row = 0 TO 4544 STEP 64
      ImageBuffer(Index + Row) = RGBtuple&
    NEXT Row
    Index = Index + 1
  NEXT Col
RETURN

ExportImageToLBM:
  IF ImageHeight = 0 OR ImageWidth = 0 THEN PRINT "! Image buffer is blank, nothing to save !": KeyWait: RETURN
  DO
    PRINT "Type in the filename to save this image as, or nothing to cancel"
    GOSUB GetFileName
    IF NewFile$ = "" THEN RETURN
    DEF SEG = 0: IF PEEK(1047) AND 3 THEN SaveDimensions = 0 ELSE SaveDimensions = -1
    IF INSTR(RIGHT$(NewFile$, 4), ".") = 0 THEN NewFile$ = NewFile$ + ".LBM"
    PRINT NewFile$
    ON ERROR GOTO FilErrHan: FilErr = 0
    OPEN NewFile$ FOR INPUT AS 1: CLOSE 1
    ON ERROR GOTO 0
    IF FilErr = 0 THEN
      PRINT "Do you want to overwrite the existing one? Y/N"
      DO: key$ = INKEY$: LOOP UNTIL LEN(key$)
      IF UCASE$(key$) = "Y" THEN EXIT DO
    ELSEIF FilErr = 53 THEN EXIT DO
    ELSE PRINT "Could not save to that file"
    END IF
  LOOP
  ImageBytes& = EvenHeight * CLNG(EvenWidth)
  PRINT "Exporting";
  OPEN NewFile$ FOR OUTPUT AS 1
  IF SaveDimensions THEN
    PRINT " dimension info and pixels";
    PRINT #1, MKI$(EvenHeight); MKI$(EvenWidth);
  ELSE
    PRINT " without dimension info, pixels only";
  END IF
  PRINT "..."
  FOR Index = 0 TO (ImageBytes& \ 4) - 1
      PRINT #1, MKL$(ImageBuffer(Index));
  NEXT Index
  CLOSE 1
  IF SaveDimensions THEN ImageBytes& = ImageBytes& + 4
  PRINT ImageBytes&; "bytes written to "; NewFile$
  SLEEP 2: KeyWait
RETURN

SavePalette:
  PRINT "Type in the filename to save the current palette as, or nothing to cancel"
  PRINT "It will tell you whether or not one with that name already exists"
  DO
    GOSUB GetFileName
    IF NewFile$ = "" THEN RETURN
    DEF SEG = 0: IF PEEK(1047) AND 3 THEN LowShades = -1 ELSE LowShades = 0
    IF INSTR(RIGHT$(NewFile$, 4), ".") = 0 THEN NewFile$ = NewFile$ + ".PAL"
    ON ERROR GOTO FilErrHan: FilErr = 0
    OPEN NewFile$ FOR INPUT AS 1: CLOSE 1
    ON ERROR GOTO 0
    IF FilErr = 0 THEN
      PRINT "Do you want to overwrite the existing one? Y/N"
      SLEEP: IF UCASE$(INKEY$) = "Y" THEN EXIT DO
    ELSEIF FilErr = 53 THEN EXIT DO
    ELSE PRINT "Could not save to that file"
    END IF
  LOOP
  PRINT "Exporting ";
  IF LowShades THEN
    PRINT "64 shade palette...";
    PalShift = 4
  ELSE
    PRINT "256 shade palette...";
    PalShift = 1
  END IF
  OPEN NewFile$ FOR OUTPUT AS 1
  DEF SEG = VARSEG(ImagePalette(0))
  FOR BytePos = VARPTR(ImagePalette(0)) TO VARPTR(ImagePalette(0)) + 1023 STEP 4
    PRINT #1, CHR$(PEEK(BytePos + 2) \ PalShift);
    PRINT #1, CHR$(PEEK(BytePos + 1) \ PalShift);
    PRINT #1, CHR$(PEEK(BytePos + 0) \ PalShift);
  NEXT BytePos
  CLOSE 1
  PRINT "768 bytes written to "; NewFile$
  SLEEP 2: WHILE LEN(INKEY$): WEND
RETURN

LoadPixelBlitCode:
  NewFile$ = Path$ + "BLITBMP.ASC"
  GOSUB OpenBinaryFile
  IF FilErr THEN NoSuccess = 1: RETURN
  BlitBmpCode$ = INPUT$(LOF(1), 1)
  CLOSE 1
  NoSuccess = 0
RETURN

GetFileName:
  LINE INPUT "Filename:", NewFile$
  IF UserEscape THEN NewFile$ = ""
  IF NewFile$ = "" THEN RETURN ELSE NewFile$ = UCASE$(NewFile$)
  IF INSTR(NewFile$, "*") THEN SHELL "dir " + NewFile$: GOTO GetFileName
  ON ERROR GOTO FilErrHan
  FilErr = 0: CHDIR NewFile$
  IF FilErr = 0 THEN PRINT "Directory changed": GOTO GetFileName
  ON ERROR GOTO 0
RETURN

'GetStartPath:
  regs.ax = &H6200
  'CALL InterruptX(&H21, regs, regs)
  PSPStart% = regs.bx
  DEF SEG = PSPStart%
  EnvironStart% = PEEK(&H2D) * 256 + PEEK(&H2C)
  DEF SEG = EnvironStart%
  BytePos = 0
  DO
    IF PEEK(BytePos) = 0 THEN
      Char = PEEK(BytePos + 1)
      BytePos = BytePos + 1
      IF Char = 0 THEN BytePos = BytePos + 1: EXIT DO
    END IF
    BytePos = BytePos + 1
  LOOP
  BytePos = BytePos + 2
  DO
    Char = PEEK(BytePos)
    BytePos = BytePos + 1
    IF Char = 0 THEN EXIT DO ELSE Path$ = Path$ + CHR$(Char)
  LOOP
  FOR BytePos = LEN(Path$) TO 1 STEP -1
    IF MID$(Path$, BytePos, 1) = "\" THEN EXIT FOR
  NEXT BytePos
  IF BytePos < 3 THEN Path$ = LEFT$(Path$, 3) ELSE Path$ = LEFT$(Path$, BytePos)
  'PRINT Path$
  'PRINT "Length"; LEN(Path$), "Last backslash"; BytePos
  'WHILE INKEY$ = "": WEND
RETURN

FilErrHan:
  FilErr = ERR
RESUME NEXT

'ELSEIF nbits = 4 THEN
' y = picheight - 1
' x = 0
' dat$ = " "
' WHILE y >= 0
'  WHILE x < picwidth
'   GET 1, , dat$
'   LOCATE 1, 1
'   p1 = ASC(dat$) AND 15
'   p2 = ASC(dat$) AND 240 / 16
'   PSET (x, y), p1
'   PSET (x + 1, y), p2
'   x = x + 2
'  WEND
'  y = y - 1
'  x = 0
' WEND
'END IF

SUB KeyWait
DO: LOOP UNTIL LEN(INKEY$)
END SUB

SUB ShowMenuChoices (MenuRow, MenuCol, ShowChoice, MenuOps$())

'empty, not implemented yet

END SUB

