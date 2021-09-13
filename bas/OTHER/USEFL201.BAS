'USEFL201.BAS (includes MOUSEDJB.BAS)
'Useful routines module
'>>>>For QBasic (i.e. the "free" version that comes with MS-DOS)<<<<
'30/12/95
'Version 2.01
'[All routines in this module are for MS-DOS Ver 2.0+]
'
'Mainly written by:
'DB = Dave Burbridge (d.burbridge@ic.ac.uk)
'Other authors (see documentaion for more details):
'IM = Ian Musgrave; DG = Douggie Green; DJ = Dave Jewell; WH = Wilf Hey
'BJ = Brett Jones; MB = Bytebloc
'
'To convert to PDS, start it with the /L:QBX.QLB option.
'Delete the SUB InterruptX, & change this line:
'  InterruptX [IntNo], regsx
'to
'  InterruptX [IntNo], regsx, regsx
'wherever it occurs.
'
'Add the line '$INCLUDE: '[path]general.bi' where [path] points to your src dir.
'
' (I did try to find a way of passing regsx twice in this version, but
'  QBasic was having none of that :-( I also tried to add an Interrupt
'  version (i.e. w/out passing segment registers), but couldn't hack it)
'
'Remove the TYPE RegTypeX..END TYPE lines inclusive, and the DECLARE SUB
'  InterruptX line.
'
'NB: Possible problem: for some reason, if you run this through Windows,
' Alt+Tab to Win & back, you lose control over the mouse in the interpreter
' screen. You can regain it by issuing the command "MouseShow" in the
' Immediate window.
'---------------------------------------------------------------------------

'---------------------------------------------------------------------------
'The following lines are needed by USEFUL2: they are not part of the demo:
'
DECLARE SUB BigFont (TopRow%, LeftCol%, Colour%, Text$)
DECLARE SUB CalcSkewRect (XShift!, YShift!, PLength!, QLength!, Grad!, X!(), Y!())
DECLARE SUB Centre (QRow%, Text$)
DECLARE SUB CHDRIVE (Dr$)
DECLARE SUB ClearBuffer ()
DECLARE SUB DrawSkewEllipse (XShift!, YShift!, PLength!, QLength!, Grad!, Colour%, Res%)
DECLARE SUB GetAvailModes (AvailMode%())
DECLARE SUB GetCDRom (NoCDDrives%, FirstCD$, IsMSCDEX%)
DECLARE SUB GetCountryInfo (CountryID%, CodePage%, DateForm$, CurrSym$, CurrForm$(), ThousSep$, DecSep$, TimeSep$, Clock%, ASCIIZSep$)
DECLARE SUB GetDiskSpace (Dr$, TotalSpace&, FreeSpace&)
DECLARE SUB GetFloppyInfo (Dr$, FlopSize!, FlopCap$)
DECLARE SUB GetMachineInfo (BIOSDate$, MachType$)
DECLARE SUB GetMem (ConvMem%, ExtMem%, VideoMem%)
DECLARE SUB GetScreenMode (ScrMode%, ScrCols%, ScrRows%, CharHor%, CharVer%, ScrMaxX%, ScrMaxY%, MaxColours%, VideoMem%, Page%)
DECLARE SUB GetSysConfig (FlDrives%, CoPro%, RS232s%, GPort%, Modem%, Printers%)
DECLARE SUB MouseClear ()
DECLARE SUB MouseDriver (m0%, m1%, m2%, m3%)
DECLARE SUB MouseInfo (MouseVers!, MouseType$, MouseIRQ%)
DECLARE SUB MouseTextPos (Row%, col%, lButton%, rButton%)
DECLARE SUB MouseShow ()
DECLARE SUB ScrollDown (Top%, Left%, Bottom%, Right%)
DECLARE SUB ScrollUp (Top%, Left%, Bottom%, Right%)
DECLARE SUB Stats (XStat!(), YStat!(), Number%, XBar!, YBar!, MajGrad!, MinGrad!, MajYInt!, MinYInt!, SigmaP!, SigmaQ!, Fit!)
DECLARE SUB WaitForAnyKey (Pause!)
DECLARE FUNCTION CheckInEllipse% (XTry!, YTry!, XShift!, YShift!, PLength!, QLength!, Grad!)
DECLARE FUNCTION CheckInRect% (XTry!, YTry!, XShift!, YShift!, PLength!, QLength!, Grad!)
DECLARE FUNCTION CURDIR$ (Dr$)
DECLARE FUNCTION DIR$ (FileSpec$)
DECLARE FUNCTION GetCallingPath$ ()
DECLARE FUNCTION GetDosVer! ()
DECLARE FUNCTION GetNoDrives% ()
DECLARE FUNCTION GetPrinterStatus% ()
DECLARE FUNCTION IsAnsi% ()
DECLARE FUNCTION IsDoskey% ()
DECLARE FUNCTION IsGraftabl% ()
DECLARE FUNCTION IsHimem% ()
DECLARE FUNCTION IsPrintQ% ()
DECLARE FUNCTION IsShare% ()
DECLARE FUNCTION LRS$ (Number%)
DECLARE FUNCTION MouseCheck% ()
DECLARE FUNCTION PerpDist! (XPt!, YPt!, M!, c!)
DECLARE FUNCTION VolLab$ (Dr$)

DEFINT A-Z

CONST PI = 3.14159265358979#
CONST TRUE = -1
CONST FALSE = NOT TRUE

TYPE RegTypeX
  ax    AS INTEGER
  bx    AS INTEGER
  cx    AS INTEGER
  dx    AS INTEGER
  bp    AS INTEGER
  si    AS INTEGER
  di    AS INTEGER
  flags AS INTEGER
  ds    AS INTEGER
  es    AS INTEGER
END TYPE

DECLARE SUB InterruptX (IntNum%, regsx AS RegTypeX)

DIM SHARED regsx AS RegTypeX
DIM SHARED MousePresent
DIM SHARED MouseChecked
'
'End of required code.
'---------------------------------------------------------------------------

'---------------------------------------------------------------------------
'Start of demonstration:
'
CLS
Title$ = "Demonstration"
Centre 2, Title$
Centre 3, STRING$(LEN(Title$), "=")
PRINT
PRINT "The following is a brief tour of some of the capabilities of this package"
PRINT
PRINT "Example of use of DIR$: (Use up/dn arrows, escape to exit...)"

'This shows how to call DIR$ to find all matching files
DIM FileArray$(1 TO 500)
FileSpec$ = "C:\DOS\*.*"   'Change this as neded
Found$ = DIR$(FileSpec$)
Count = 0
DO WHILE LEN(Found$)
  Count = Count + 1
  FileArray$(Count) = Found$
  Found$ = DIR$("")
LOOP

Top = 7
Left = 1
Bottom = 25
Right = 80
Length = Right - Left + 1
TL = (Top - 1) * 256 + (Left - 1)
BR = (Bottom - 1) * 256 + (Right - 1)

IF Count < Bottom - Top + 1 THEN
  EndLine = Count
ELSE
  EndLine = Bottom - Top + 1
END IF

SCREEN 0
WIDTH 80, 25

VIEW PRINT Top TO Bottom
FOR i = 1 TO EndLine
  LOCATE i + Top - 1, 1: PRINT i; FileArray$(i);
NEXT

StartRow = 1

DO
  Char$ = INKEY$
  SELECT CASE Char$
    CASE CHR$(0) + CHR$(72)  'Up
      IF StartRow > 1 THEN
	ScrollUp Top, Left, Bottom, Right
	StartRow = StartRow - 1
	LOCATE Top, Left: PRINT StartRow; LEFT$(FileArray$(StartRow), Length);
      END IF

    CASE CHR$(0) + CHR$(80)  'Dn
      IF StartRow + (Bottom - Top) < Count THEN
	ScrollDown Top, Left, Bottom, Right
	StartRow = StartRow + 1
	LOCATE Bottom, Left: PRINT StartRow + (Bottom - Top); LEFT$(FileArray$(StartRow + (Bottom - Top)), Length);
      END IF

  END SELECT
LOOP UNTIL Char$ = CHR$(27)
VIEW PRINT 1 TO 25

CLS
Centre 2, "Example of use of BigFont"
PRINT "  Using BigFont 10, 10, 12, " + CHR$(34) + "Hello, world!" + CHR$(34)
BigFont 10, 10, 12, "Hello, world!"
LOCATE 25, 1: PRINT "Press any key or click mouse to continue...";
MouseClear
ClearBuffer
WaitForAnyKey (0)

SCREEN 0
CLS
COLOR 7, 0
Title$ = "System config"
Centre 2, Title$
Centre 3, STRING$(LEN(Title$), "=")
PRINT
PRINT "The following routines use DOS functions to tell you stuff about the machine:"
PRINT

PRINT "Using GetAvailModes AvailMode():"
DIM AvailMode(19)
GetAvailModes AvailMode()
PRINT "ROM BIOS modes supported:"
FOR n = 0 TO 15
  IF AvailMode(n) THEN
    PRINT "&h0"; HEX$(n),
  END IF
NEXT
FOR n = 16 TO 19
  IF AvailMode(n) THEN
    PRINT "&h"; HEX$(n),
  END IF
NEXT
PRINT
PRINT "Using GetSysConfig FlDrives, CoPro, RS232s, GPort, Modem, Printers:"
GetSysConfig FlDrives, CoPro, RS232s, GPort, Modem, Printers
PRINT "Floppy drives installed:"; FlDrives
PRINT "Maths copro installed:"; CoPro
PRINT "RS232s installed:"; RS232s
PRINT
PRINT "Using GetFloppyInfo " + CHR$(34) + "B" + CHR$(34) + ", FlopSize!, FlopCap$:"
GetFloppyInfo "B", FlopSize!, FlopCap$
PRINT "Floppy drive B: ";
SELECT CASE FlopSize!
  CASE 0
   PRINT "None"
  CASE -1
    PRINT "Unknown"
  CASE ELSE
    PRINT RTRIM$(STR$(FlopSize!)); CHR$(34); " "; FlopCap$; "bytes"
END SELECT
  
PRINT
PRINT "Using GetMem ConvMem, ExtMem, VideoMem:"
GetMem ConvMem, ExtMem, VideoMem
PRINT "Conv mem:"; ConvMem; "k"
LOCATE 25, 1: PRINT "Press any key or click mouse to continue...";
MouseClear
ClearBuffer
WaitForAnyKey (0)
CLS
Title$ = "System config II"
Centre 2, Title$
Centre 3, STRING$(LEN(Title$), "=")
PRINT
PRINT "Some more DOS functions to tell you stuff about the machine:"

PRINT
PRINT "Using GetPrinterStatus:"
PRINT "Printer status: ";
SELECT CASE GetPrinterStatus
  CASE 0: PRINT "Timed out"
  CASE 3: PRINT "I/O error"
  CASE 4: PRINT "Selected"
  CASE 5: PRINT "Out of paper"
  CASE 6: PRINT "Acknowledge"
  CASE 7: PRINT "Not busy"
  CASE ELSE: PRINT "Unknown"
END SELECT

PRINT
PRINT "Using GetCountryInfo CountryID, CodePage, DateForm$, CurrSym$, CurrForm$(), ThousSep$, DecSep$, TimeSep$, Clock, ASCIIZSep$:"
DIM CurrForm(2) AS STRING
GetCountryInfo CountryID, CodePage, DateForm$, CurrSym$, CurrForm$(), ThousSep$, DecSep$, TimeSep$, Clock, ASCIIZSep$
PRINT "Country:"; CountryID; "Code page:"; CodePage
PRINT "Date format: "; DateForm$
PRINT "Currency format, without decimal: "; CurrForm$(1)
PRINT "Currency format, with decimal: "; CurrForm$(2)
PRINT "Time format:"; Clock; "hr"
PRINT

PRINT "Using GetMachineInfo BIOSDate$, MachType$:"
GetMachineInfo BIOSDate$, MachType$
PRINT "BIOS release date: "; BIOSDate$
PRINT "Machine type: "; MachType$
PRINT

PRINT "Using MouseInfo MouseVers!, MouseType$, MouseIRQ:"
MouseInfo MouseVers!, MouseType$, MouseIRQ
PRINT "Mouse driver version:"; MouseVers!

LOCATE 25, 1: PRINT "Press any key or click mouse to continue...";
MouseClear
ClearBuffer
WaitForAnyKey (0)
CLS
Title$ = "System config III"
Centre 2, Title$
Centre 3, STRING$(LEN(Title$), "=")
 
PRINT
PRINT "Yet more DOS functions to tell you stuff about the machine:"
 
PRINT
PRINT "Using GetNoDrives, GetDiskSpace " + STRING$(2, 34) + ", TotalSpace&, FreeSpace&:"
PRINT "There are"; GetNoDrives; "drives available on this system."
GetDiskSpace "", TotalSpace&, FreeSpace&
PRINT "Space available:"; FreeSpace&; "bytes"
PRINT "Total space:"; TotalSpace&; "bytes"
 
PRINT
PRINT "Using CURDIR$(" + STRING$(2, 34) + "), and VolLab$(" + STRING$(2, 34) + "):"
PRINT "Current directory is "; CURDIR$(""); ", drive labelled "; VolLab$(""); "."

PRINT
PRINT "Using GetCDRom NoCDDrives, FirstCD$, IsMSCDEX:"
GetCDRom NoCDDrives, FirstCD$, IsMSCDEX
PRINT "Number of CD drives:"; NoCDDrives
IF NoCDDrives THEN
  PRINT "First letter: "; FirstCD$
  PRINT "MSCDEX is ";
  IF NOT IsMSCDEX THEN
    PRINT "not ";
  END IF
  PRINT "loaded"
END IF

PRINT
PRINT "Using GetDosVer, IsDoskey, GetCallingPath$:"
PRINT "Dos version:"; GetDosVer
PRINT "Doskey is ";
IF NOT IsDoskey THEN
  PRINT "not ";
END IF
PRINT "loaded"
PRINT "This programme is "; GetCallingPath$

LOCATE 25, 1: PRINT "Press any key or click mouse to continue...";
MouseClear
ClearBuffer
WaitForAnyKey (0)
CLS
Title$ = "Stats"
Centre 2, Title$
Centre 3, STRING$(LEN(Title$), "=")

PRINT
PRINT "Some statistics:"

MaxPnts = 12
DIM X(MaxPnts) AS SINGLE
DIM Y(MaxPnts) AS SINGLE
PRINT "X", "Y"
FOR n = 1 TO MaxPnts
  READ X(n), Y(n)
  PRINT X(n), Y(n)
NEXT
PRINT "Using Stats X(), Y(), MaxPnts, XBar!, YBar!, MajGrad!, MinGrad!, MajYInt!, MinYInt!, SigmaP!, SigmaQ!, Fit!"
Stats X(), Y(), MaxPnts, XBar!, YBar!, MajGrad!, MinGrad!, MajYInt!, MinYInt!, SigmaP!, SigmaQ!, Fit!
PRINT "Mean X:"; XBar!; " Mean Y:"; YBar!
PRINT "Major gradient:"; MajGrad!; " Minor gradient:"; MinGrad!; " Major Y-intercept:"; MajYInt!; " Minor Y-intercept:"; MinYInt!
PRINT "Major standard deviation:"; SigmaP!; " Minor standard deviation:"; SigmaQ!
PRINT "Goodness of fit:"; Fit!
LOCATE 25, 1: PRINT "Press any key or click mouse to display the data...";
MouseClear
ClearBuffer
WaitForAnyKey (0)

CLS
SCREEN 12
WINDOW (-4, -2)-(10, 10)
LINE (-4, 0)-(10, 0), 4
LINE (0, -2)-(0, 10), 4
FOR n = 1 TO MaxPnts
  PSET (X(n), Y(n)), 14
NEXT
DrawSkewEllipse XBar!, YBar!, SigmaP!, SigmaQ!, MajGrad!, 15, 50
LOCATE 28, 1: PRINT "This ellipse illustrates a standard deviation of 1 sigma along each axis.";
LOCATE 29, 1: PRINT "Drawn using DrawSkewEllipse XBar!, YBar!, SigmaP!, SigmaQ!, MajGrad!, 15, 50";
LOCATE 30, 1: PRINT "Press any key or click mouse to continue...";
MouseClear
ClearBuffer
WaitForAnyKey (0)

LOCATE 28, 1: PRINT SPACE$(80);
LOCATE 29, 1: PRINT SPACE$(80);
LOCATE 30, 1: PRINT SPACE$(80);
DIM RectX(4) AS SINGLE
DIM RectY(4) AS SINGLE
CalcSkewRect XBar!, YBar!, SigmaP!, SigmaQ!, MajGrad!, RectX(), RectY()
LINE (RectX(1), RectY(1))-(RectX(2), RectY(2))
LINE -(RectX(3), RectY(3))
LINE -(RectX(4), RectY(4))
LINE -(RectX(1), RectY(1))
LOCATE 26, 1: PRINT "This rectangle illustrates a standard deviation of 2 sigmas along the major axis, and 3.5 along the minor axis.";
LOCATE 28, 1: PRINT "Drawn using CalcSkewRect XBar!, YBar!, SigmaP!, SigmaQ!, MajGrad!, RectX(), RectY() and LINE commands.";
LOCATE 30, 1: PRINT "Press any key or click mouse to continue...";
MouseClear
ClearBuffer
WaitForAnyKey (0)

CLS
WINDOW (-4, -2)-(10, 10)
LINE (-4, 0)-(10, 0), 4
LINE (0, -2)-(0, 10), 4
FOR n = 1 TO MaxPnts
  PSET (X(n), Y(n)), 14
NEXT
CIRCLE (X(3), Y(3)), .1, 13
LINE (-4, MajGrad! * -4 + MajYInt!)-(10, MajGrad! * 10 + MajYInt!), 13
LOCATE 28, 1: PRINT "The perpendicular distance from the circle to the line is given by PerpDist (X(3), Y(3), MajGrad!, MajYInt!): =";
PRINT PerpDist(X(3), Y(3), MajGrad!, MajYInt!);
LOCATE 30, 1: PRINT "Press any key or click mouse to continue...";
MouseClear
ClearBuffer
WaitForAnyKey (0)

SCREEN 0
BigFont 10, 26, 11, "BYE!"

SYSTEM

'End of demonstration
'-----------------------------------------------------------------------------------------------

10 RESUME NEXT  'Bodge line for ON ERROR in Draw__ routines

'hex data for interrupt routines
DATA  &H55, &H8B, &HEC, &H83, &HEC, &H08, &H56, &H57, &H1E, &H55, &H8B, &H5E
DATA  &H06, &H8B, &H47, &H10, &H3D, &HFF, &HFF, &H75, &H04, &H1E, &H8F, &H47
DATA  &H10, &H8B, &H47, &H12, &H3D, &HFF, &HFF, &H75, &H04, &H1E, &H8F, &H47
DATA  &H12, &H8B, &H47, &H08, &H89, &H46, &HF8, &H8B, &H07, &H8B, &H4F, &H04
DATA  &H8B, &H57, &H06, &H8B, &H77, &H0A, &H8B, &H7F, &H0C, &HFF, &H77, &H12
DATA  &H07, &HFF, &H77, &H02, &H1E, &H8F, &H46, &HFA, &HFF, &H77, &H10, &H1F
DATA  &H8B, &H6E, &HF8, &H5B, &HCD, &H21, &H55, &H8B, &HEC, &H8B, &H6E, &H02
DATA  &H89, &H5E, &HFC, &H8B, &H5E, &H06, &H1E, &H8F, &H46, &HFE, &HFF, &H76
DATA  &HFA, &H1F, &H89, &H07, &H8B, &H46, &HFC, &H89, &H47, &H02, &H89, &H4F
DATA  &H04, &H89, &H57, &H06, &H58, &H89, &H47, &H08, &H89, &H77, &H0A, &H89
DATA  &H7F, &H0C, &H9C, &H8F, &H47, &H0E, &H06, &H8F, &H47, &H12, &H8B, &H46
DATA  &HFE, &H89, &H47, &H10, &H5A, &H1F, &H5F, &H5E, &H8B, &HE5, &H5D, &HCA
DATA  &H02, &H00

DATA 5,4
DATA 4,6
DATA 5.5,7.5
DATA 6.5,6.5
DATA 7.5,7.5
DATA 8,6
DATA 3,3
DATA 6.5,4
DATA 5,6
DATA 7,7
DATA 9,7
DATA 9,9

'Writes Text$ in Colour at > normal size. Top left of new Text$ is at
' (TopRow, LeftCol).
'[DB, thanks to Jim Oliver]
SUB BigFont (TopRow, LeftCol, Colour, Text$)

  GetScreenMode ScrMode, ScrCols, ScrRows, 0, 0, 0, 0, MaxColours, 0, 0
 
  IF ScrMode <> 2 THEN
    IF Colour >= MaxColours THEN
      COLOR MaxColours - 1
    ELSE
      COLOR Colour
    END IF
  END IF

  FOR i = 1 TO LEN(Text$)
    Char = ASC(MID$(Text$, i, 1))
    FOR Row = 0 TO 7
      IF Row <= ScrRows - TopRow THEN
	DEF SEG = &HF000
	Byte = PEEK(&HFA6D + (Char * 8) + (Row + 1))
	DEF SEG
	FOR Test = 0 TO 7
	  CharPos = LeftCol + (i - 1) * 8 + Test
	  IF CharPos <= ScrCols THEN
	    LOCATE TopRow + Row, CharPos
	    Mask = 2 ^ (7 - Test)
	    IF Byte AND Mask THEN
	      PRINT CHR$(219);
	    ELSE
	      PRINT " ";
	    END IF
	  ELSE
	    Done = TRUE
	    EXIT FOR
	  END IF
	NEXT
      ELSE
	EXIT FOR
      END IF
    NEXT
    IF Done THEN EXIT FOR
  NEXT

END SUB

DEFSNG A-Z
'Calculates co-ordinates of skewed rectangle about (XShift, YShift), with
' rotated axes length PLength & QLength for maj & min respectively. Maj axes
' at gradient Grad. Puts co-ordinates into array of size X©4), Y(4).
'[DB]
SUB CalcSkewRect (XShift, YShift, PLength, QLength, Grad, X(), Y())

  'Check rect isn't point/line
  IF PLength <> 0 THEN

    'Calc angle of major axis
    Beta = ATN(Grad)

    'Calc angle to vertices from major axis
    Alpha = ATN(QLength / PLength)

    'Calc length to vertex
    r = SQR(PLength ^ 2 + QLength ^ 2)

    'Calc angles from X-axis, & vertices
    Theta1 = Beta + Alpha
    Theta2 = Beta - Alpha

    XNew1 = r * COS(Theta1)
    YNew1 = r * SIN(Theta1)
    XNew2 = r * COS(Theta2)
    YNew2 = r * SIN(Theta2)

    X(1) = XShift + XNew1
    Y(1) = YShift + YNew1
    X(2) = XShift - XNew2
    Y(2) = YShift - YNew2
    X(3) = XShift - XNew1
    Y(3) = YShift - YNew1
    X(4) = XShift + XNew2
    Y(4) = YShift + YNew2

  END IF

END SUB

DEFINT A-Z
'Prints Text$ centrally on QRow.
'[DB]
SUB Centre (QRow, Text$)

  GetScreenMode 0, ScrCols, 0, 0, 0, 0, 0, 0, 0, 0
  LOCATE QRow, (ScrCols - LEN(Text$)) \ 2
  PRINT Text$;

END SUB

DEFINT A-Z
'[DB]
SUB CHDRIVE (Dr$)

  IF Dr$ <> "" THEN
    DrNumber = ASC(UCASE$(LEFT$(Dr$, 1))) - 65
    IF DrNumber >= 0 AND DrNumber <= 25 THEN
      regsx.ax = &HE00
      regsx.dx = DrNumber
      InterruptX &H21, regsx
      regsx.ax = &H1900
      InterruptX &H21, regsx
      IF DrNumber <> (regsx.ax AND 255) THEN
	ERROR 68    'no such drive
      END IF
    END IF
  END IF

END SUB

DEFSNG A-Z
'Checks to see if point (XTry, YTry) is contained in ellipse defined as
' follows:
'  Centre (XShift, YShift), rotated axes length PLength & QLength for maj &
'  min respectively, maj axes at gradient Grad.
' Function returns TRUE for inside, FALSE for outside.
'[DB]
FUNCTION CheckInEllipse% (XTry, YTry, XShift, YShift, PLength, QLength, Grad)

  'Check that ellipse isn't point/line
  IF (PLength <> 0) AND (QLength <> 0) THEN
    'Calc angle of major axis
    Beta = ATN(Grad)

    'Calc square of length to (XTry,YTry) from (XShift,YShift)
    rTrySq = (XTry - XShift) ^ 2 + (YTry - YShift) ^ 2

    'Check for angle = 90 deg
    IF XTry = XShift THEN
      Theta = PI / 2
    ELSE 'Calc angle from x-axis to point
      Theta = ATN((YTry - YShift) / (XTry - XShift))
    END IF

    'Calc angle from major axis
    Alpha = Theta - Beta

    'Check it isn't 90 deg, & calc length to point on ellipse
    IF ABS(Alpha) = PI / 2 THEN
      rSq = QLength ^ 2
    ELSE
      TanASq = TAN(Alpha) ^ 2
      rSq = (1 + TanASq) / ((1 / PLength ^ 2) + TanASq / (QLength ^ 2))
    END IF

    'Check if 2 lengths </>
    IF rTrySq <= rSq THEN
      CheckInEllipse = TRUE
    ELSE
      CheckInEllipse = FALSE
    END IF
  ELSE
    CheckInEllipse = FALSE
  END IF

END FUNCTION

'Checks to see if point (XTry, YTry) is contained in rectangle defined as
'follows:
'  Centre (XShift, YShift), rotated axes length PLength & QLength for maj &
'  min respectively, maj axes at gradient Grad.
' Function returns TRUE for inside, FALSE for outside.
'[DB]
FUNCTION CheckInRect% (XTry, YTry, XShift, YShift, PLength, QLength, Grad)

  'Check that rect isn't point/line
  IF (PLength <> 0) AND (QLength <> 0) THEN

    'Calc angle of major axis
    Beta = ATN(Grad)

    'Calc length from (XShift,YShift) to (XTry,YTry)
    rTrySq = (XTry - XShift) ^ 2 + (YTry - YShift) ^ 2

    'Calc angle from (XShift,YShift) to (XTry,YTry), checking for = 90 deg
    IF XTry = XShift THEN
      Theta = PI / 2
    ELSE
      Theta = ATN((YTry - YShift) / (XTry - XShift))
    END IF

    'Calc angle from major axis
    Alpha = ABS(Beta - Theta)
    IF Alpha > PI / 2 THEN
      Alpha = PI - Alpha
    END IF

    'Calc length to boundary
    Gamma = ABS(ATN(QLength / PLength))
    SELECT CASE Alpha
      CASE IS < Gamma
	rSq = (PLength / COS(Alpha)) ^ 2
      CASE IS = Gamma
	rSq = PLength ^ 2 + QLength ^ 2
      CASE IS > Gamma
	rSq = (QLength / SIN(Alpha)) ^ 2
    END SELECT

    'Check if 2 lengths </>
    IF rTrySq <= rSq THEN
      CheckInRect = TRUE
    ELSE
      CheckInRect = FALSE
    END IF
  ELSE
    CheckInRect = FALSE
  END IF

END FUNCTION

DEFINT A-Z
'[DB]
SUB ClearBuffer

  DO: LOOP UNTIL INKEY$ = ""

END SUB

'Returns current directory, for Dr$ if Dr$ is not ""
'[DB, based on code by BJ]
FUNCTION CURDIR$ (Dr$)

  DIM Buffer(128)

  aseg = VARSEG(Buffer(0))
  aptr = VARPTR(Buffer(0))

  IF Dr$ = "" THEN
    regsx.ax = &H1900
    InterruptX &H21, regsx
    DrCode = (regsx.ax AND 255) + 1
    Dr$ = CHR$(DrCode + 64)
  ELSE
    Dr$ = UCASE$(LEFT$(Dr$, 1))
    DrCode = ASC(Dr$) - 64
  END IF

  regsx.ax = &H4700
  regsx.dx = DrCode
  regsx.ds = aseg
  regsx.si = aptr

  InterruptX &H21, regsx

  IF regsx.ax = 15 THEN
    ERROR 68       'no such drive
  ELSE
    DEF SEG = aseg
    FOR a = 0 TO 128
      f$ = f$ + CHR$(PEEK(aptr + a))
    NEXT
    DEF SEG

    CURDIR$ = Dr$ + ":\" + LEFT$(f$, INSTR(f$, CHR$(0)) - 1)
  END IF

END FUNCTION

'[IM]
FUNCTION DIR$ (FileSpec$) STATIC
     
  DIM DTA AS STRING * 44 ', regsx AS RegTypeX
 
  '-----  Set up our own DTA so we don't destroy COMMAND$
  regsx.ax = &H1A00                    'Set DTA function
  regsx.dx = VARPTR(DTA)               'DS:DX points to our DTA
  regsx.ds = -1                        'Use current value for DS
  InterruptX &H21, regsx                 'Do the interrupt
     
  '-----  Check to see if this is First or Next
  IF LEN(FileSpec$) THEN              'FileSpec$ isn't null, so
				      'FindFirst
    FileSpecZ$ = FileSpec$ + CHR$(0)   'Make FileSpec$ into an ASCIIZ
				     'string
    regsx.ax = &H4E00              'Perform a FindFirst
    regsx.cx = 0                      'Only look for normal files
    regsx.dx = SADD(FileSpecZ$)       'DS:DX points to ASCIIZ file
    regsx.ds = -1                     'Use current DS
  ELSE                                'We have a null FileSpec$,
    regsx.ax = &H4F00               'so FindNext
  END IF
     
  InterruptX &H21, regsx                 'Do the interrupt
     
  '-----  Return file name or null
  IF regsx.flags AND 1 THEN            'No files found
    DIR$ = ""                        'Return null string
  ELSE
    Null = INSTR(31, DTA, CHR$(0))     'Get the filename found
    DIR$ = MID$(DTA, 31, Null - 30)  'It's an ASCIIZ string starting
  END IF                              'at offset 30 of the DTA
     
END FUNCTION

DEFSNG A-Z
'Draws skewed ellipse about (XShift, YShift), with rotated axes length PLength
'& QLength for maj & min respectively. Maj axes at gradient Grad. No of pts
'in each quadrant = Res%.
'[DB]
SUB DrawSkewEllipse (XShift, YShift, PLength, QLength, Grad, Colour%, Res%)

  'Check that ellipse isn't just a line/point
  IF PLength <> 0 THEN

    'Calc angle of major axis
    Beta = ATN(Grad)

    FOR p = 0 TO PLength STEP PLength / Res%

      'Calc p,q pts
      Sq = PLength ^ 2 - p ^ 2
      q = (QLength / PLength) * SQR(Sq)

      'Check angle isn't 90 deg
      IF p = 0 THEN
	Alpha = PI / 2
      ELSE
	Alpha = ATN(q / p)
      END IF

      'Calc length to p,q
      r = SQR(p ^ 2 + q ^ 2)

      'Calc angles from X-axis, plot points
      Theta = Beta + Alpha
      XNew = r * COS(Theta)
      YNew = r * SIN(Theta)
      ON ERROR GOTO 10
      PSET (XNew + XShift, YNew + YShift), Colour%
      PSET (-XNew + XShift, -YNew + YShift), Colour%
      ON ERROR GOTO 0
      Theta = Beta - Alpha
      XNew = r * COS(Theta)
      YNew = r * SIN(Theta)
      ON ERROR GOTO 10
      PSET (XNew + XShift, YNew + YShift), Colour%
      PSET (-XNew + XShift, -YNew + YShift), Colour%
      ON ERROR GOTO 0
    NEXT
  END IF

END SUB

DEFINT A-Z
'Returns TRUE/FALSE for BIOS screen modes 0-19
'[DB]
SUB GetAvailModes (AvailMode())

  DIM Buffer(200) AS INTEGER
  DIM Value(3) AS LONG
  DIM Val1(2) AS INTEGER
  DIM Segm AS LONG

  GetScreenMode ScrMode, ScrCols, ScrRows, 0, 0, 0, 0, 0, 0, 0

  regsx.ax = &H1B00
  regsx.bx = &H0
  regsx.es = VARSEG(Buffer(0))
  regsx.di = VARPTR(Buffer(0))

  SCREEN ScrMode          'Need to set mode immediately before calling
  WIDTH ScrCols, ScrRows  'this int, acc. to book. So let's do another bodge!

  InterruptX &H10, regsx

  DEF SEG = VARSEG(Buffer(0))
  FOR Byte = 0 TO 3
    Value(Byte) = PEEK(regsx.di + Byte)
  NEXT
  DEF SEG

  Segm = Value(3) * 256 + Value(2)
  DEF SEG = Segm
  FOR a = 0 TO 2
    Val1(a) = PEEK(Value(1) * 256 + Value(0) + a)
  NEXT
  DEF SEG

  FOR bit = 0 TO 7
    IF Val1(0) AND 2 ^ bit THEN
       AvailMode(bit) = TRUE
    END IF
  NEXT
  FOR bit = 0 TO 7
    IF Val1(1) AND 2 ^ bit THEN
       AvailMode(bit + &H8) = TRUE
    END IF
  NEXT
  FOR bit = 0 TO 3
    IF Val1(2) AND 2 ^ bit THEN
       AvailMode(bit + &H10) = TRUE
    END IF
  NEXT

END SUB

DEFSNG A-Z
'Gets path to .EXE
'[MB]
FUNCTION GetCallingPath$
 
  regsx.ax = &H6200
  InterruptX &H21, regsx
  PSPStart% = regsx.bx

  DEF SEG = PSPStart%
  EnvironStart% = PEEK(&H2D) * 256 + PEEK(&H2C)
  DEF SEG

  DEF SEG = EnvironStart%
  DO
    Char = PEEK(a)
    IF Char = 0 THEN
      a = a + 1
      Char = PEEK(a)
      IF Char = 0 THEN
	Found = TRUE
      END IF
    END IF
    a = a + 1
  LOOP UNTIL Found
  a = a + 2
  Found = FALSE
  DO
    Char = PEEK(a)
    IF Char = 0 THEN
      Found = TRUE
    ELSE
      Path$ = Path$ + CHR$(Char)
    END IF
    a = a + 1
  LOOP UNTIL Found
  DEF SEG
  GetCallingPath$ = Path$

END FUNCTION

DEFINT A-Z
'Returns number of CD drives on system, first drive's letter, & whether
' MSCDEX is loaded.
'[Based on code by WH]
SUB GetCDRom (NoCDDrives, FirstCD$, IsMSCDEX)

  '************************
  regsx.ax = &H1500
  regsx.bx = 0
  InterruptX &H2F, regsx

  NoCDDrives = regsx.bx

  IF NoCDDrives THEN
    FirstCD$ = CHR$(65 + regsx.cx)
    regsx.ax = &H150B
    regsx.bx = 0
    InterruptX &H2F, regsx
    IsMSCDEX = (regsx.bx = &HADAD)
  END IF

END SUB

'Returns country specific info about machine:
' CountryID = Dos ID number
' CodePage = Dos code page
' DateForm$ = Date format
' CurrSym$ = Currency symbol
' CurrForm$(1) = Currency format (w/out decimal)
' CurrForm$(2) = Currency format (with decimal)
' ThousSep$ = '000s separator
' DecSep$ = Decimal separator
' TimeSep$ = Time separator
' Clock = 12/24 hour clock
' ASCIIZSep$ = ASCII data list separator
'[DB]
SUB GetCountryInfo (CountryID, CodePage, DateForm$, CurrSym$, CurrForm$(), ThousSep$, DecSep$, TimeSep$, Clock, ASCIIZSep$)

  DIM Val2(40) AS INTEGER
  DIM Buffer(40) AS INTEGER
  DIM BufLength AS LONG
 
  regsx.ax = &H6501
  regsx.bx = -1
  regsx.cx = 41
  regsx.dx = -1
  regsx.es = VARSEG(Buffer(0))
  regsx.di = VARPTR(Buffer(0))

  InterruptX &H21, regsx

  DEF SEG = VARSEG(Buffer(0))
  FOR a = 0 TO 2
    Val2(a) = PEEK(regsx.di + a)
  NEXT
  DEF SEG

'  IDCode = Val2(0) 'Don't know what use this is...

  BufLength = Val2(2) * 256 + Val2(1)
 
  DEF SEG = VARSEG(Buffer(0))
  FOR a = 3 TO BufLength + 2
    Val2(a) = PEEK(regsx.di + a)
  NEXT
  DEF SEG

  CountryID = 256 * Val2(4) + Val2(3)
  CodePage = 256 * Val2(6) + Val2(5)

  DateSep$ = CHR$(Val2(&H12))
  SELECT CASE Val2(7)
    CASE 0: DateForm$ = "mm" + DateSep$ + "dd" + DateSep$ + "yy"
    CASE 1: DateForm$ = "dd" + DateSep$ + "mm" + DateSep$ + "yy"
    CASE 2: DateForm$ = "yy" + DateSep$ + "mm" + DateSep$ + "dd"
  END SELECT
 
  CurrSym$ = CHR$(Val2(9)) + CHR$(Val2(10)) + CHR$(Val2(11)) + CHR$(Val2(12)) + CHR$(Val2(13))
  CurrSym$ = LEFT$(CurrSym$, INSTR(CurrSym$, CHR$(0)) - 1)
  ThousSep$ = CHR$(Val2(&HE))
  DecSep$ = CHR$(Val2(&H10))
  TimeSep$ = CHR$(Val2(&H14))
  DigsAftDec = Val2(&H17)
 
  SELECT CASE Val2(&H16)
    CASE 0
      CurrForm$(1) = CurrSym$ + "0"
      CurrForm$(2) = CurrSym$ + "0" + DecSep$ + STRING$(DigsAftDec, "0")
    CASE 1
      CurrForm$(1) = "0" + CurrSym$
      CurrForm$(2) = "0" + DecSep$ + STRING$(DigsAftDec, "0") + CurrSym$
    CASE 2
      CurrForm$(1) = CurrSym$ + " 0"
      CurrForm$(2) = CurrSym$ + " 0" + DecSep$ + STRING$(DigsAftDec, "0")
    CASE 3
      CurrForm$(1) = "0" + " " + CurrSym$
      CurrForm$(2) = "0" + DecSep$ + STRING$(DigsAftDec, "0") + " " + CurrSym$
    CASE 4
      CurrForm$(1) = CurrSym$ + "0"
      CurrForm$(2) = "0" + CurrSym$ + STRING$(DigsAftDec, "0")
    CASE 5
      CurrForm$(1) = "0" + CurrSym$
      CurrForm$(2) = "0" + CurrSym$ + STRING$(DigsAftDec, "0")
    CASE 6
      CurrForm$(1) = CurrSym$ + " 0"
      CurrForm$(2) = "0" + CurrSym$ + STRING$(DigsAftDec, "0")
    CASE 7
      CurrForm$(1) = "0 " + CurrSym$
      CurrForm$(2) = "0" + CurrSym$ + STRING$(DigsAftDec, "0")
  END SELECT

  Clock = 12 + Val2(&H18) * 12
  ASCIIZSep$ = CHR$(Val2(&H1D))

END SUB

DEFSNG A-Z
'[DB, using calculation kludges from code by DJ]
SUB GetDiskSpace (Dr$, TotalSpace&, FreeSpace&)

  IF Dr$ = "" THEN
    DrCode = 0
  ELSE
    Dr$ = UCASE$(LEFT$(Dr$, 1))
    DrCode = ASC(Dr$) - 64
  END IF

  regsx.ax = &H3600
  regsx.dx = DrCode
  InterruptX &H21, regsx

  IF regsx.ax = &HFFFF THEN
    FreeSpace& = -1
  ELSE
    bpc& = regsx.ax
    bpc& = bpc& * regsx.cx           ' Calculate bytes per cluster
    Temp& = bpc& * (regsx.bx AND &H7FFF)    ' Multiply by total clusters
    IF (regsx.bx < 0) THEN                  ' kludge time !
      Temp& = Temp& + (bpc& * &H4000)
      Temp& = Temp& + (bpc& * &H4000)
    END IF
    FreeSpace& = Temp&
    bpc& = regsx.ax
    bpc& = bpc& * regsx.cx           ' Calculate bytes per cluster
    Temp& = bpc& * (regsx.dx AND &H7FFF)    ' Multiply by total clusters
    IF (regsx.dx < 0) THEN                  ' kludge time !
      Temp& = Temp& + (bpc& * &H4000)
      Temp& = Temp& + (bpc& * &H4000)
    END IF
    TotalSpace& = Temp&
  END IF

  ' ax = sectors per cluster or error
  ' bx = number of available clusters
  ' cx = bytes per sector
  ' dx = total number of clusters

END SUB

'[DB]
FUNCTION GetDosVer

  regsx.ax = &H3000

  InterruptX &H21, regsx

  IF regsx.ax AND 255 = 0 THEN
    GetDosVer = 1
  ELSE
    GetDosVer = (regsx.ax AND 255) + (regsx.ax AND 65280) / 25600
  END IF

'[OEM's serial number = (regsx.bx AND 65280) / 256]
'[User's serial number = (regsx.bx AND 255) * 2 ^ 16 + regsx.cx]

END FUNCTION

DEFINT A-Z
' Simple program to return floppy disk info from CMOS RAM
'[Anon, I think from a PC mag]
SUB GetFloppyInfo (Dr$, FlopSize!, FlopCap$)

  FlopSize! = -1  'Default, unknown type

  IF Dr$ <> "" THEN
    Dr$ = UCASE$(LEFT$(Dr$, 1))
    IF Dr$ = "A" OR Dr$ = "B" THEN
      OUT &H70, &H10                  ' Request data for floppy diskettes
      info = INP(&H71)               ' Get returned data
      IF Dr$ = "A" THEN
	info = info / 16
      ELSE
	info = info AND 15
      END IF
     
      SELECT CASE info
	CASE 0
	  FlopSize! = 0
	  FlopCap$ = ""
	CASE 1
	  FlopSize! = 5.25
	  FlopCap$ = "360k"
	CASE 2
	  FlopSize! = 5.25
	  FlopCap$ = "1.2M"
	CASE 3
	  FlopSize! = 3.5
	  FlopCap$ = "720k"
	CASE 4
	  FlopSize! = 3.5
	  FlopCap$ = "1.44M"
      END SELECT
    END IF
  END IF

END SUB

'Reads BIOS to get machine info
'[DB]
SUB GetMachineInfo (BIOSDate$, MachType$)

  DEF SEG = &HF000
  BIOSDate$ = ""
  FOR Offset = &HFFF5 TO (&HFFF5 + 7)
    BIOSDate$ = BIOSDate$ + CHR$(PEEK(Offset))
  NEXT

  SELECT CASE PEEK(&HFFFE)
    CASE &H9A: MachType$ = "COMPAQ Plus"
    CASE &HFF: MachType$ = "IBM PC"
    CASE &HFE: MachType$ = "PC XT, Portable PC"
    CASE &HFD: MachType$ = "PCjr"
    CASE &HFC: MachType$ = "Personal Computer AT, PS/2 Models 50 and 60"
    CASE &HFB: MachType$ = "PC XT (after 1/10/86)"
    CASE &HFA: MachType$ = "PS/2 Model 30"
    CASE &HF9: MachType$ = "Convertible PC"
    CASE &HF8: MachType$ = "PS/2 Model 80"
    CASE ELSE: MachType$ = "Type unknown"
  END SELECT
  DEF SEG

END SUB

'Gets memory available
'[DB]
SUB GetMem (ConvMem, ExtMem, VideoMem)

  InterruptX &H12, regsx
  ConvMem = regsx.ax
  regsx.ax = &H8800
  InterruptX &H15, regsx
  ExtMem = regsx.ax
  GetScreenMode 0, 0, 0, 0, 0, 0, 0, 0, VideoMem, 0

END SUB

' Return number of online drives
'[DJ]
FUNCTION GetNoDrives

  ' First, get default drive in AL
  regsx.ax = &H1900
  InterruptX &H21, regsx

  ' Now set to the drive we're already on....
  regsx.dx = regsx.ax
  regsx.ax = &HE00
  InterruptX &H21, regsx

  GetNoDrives = regsx.ax AND 255

END FUNCTION

'Returns printer status
' 0: Timed out
' 3: I/O error
' 4: Selected
' 5: Out of paper
' 6: Acknowledge
' 7: Not busy
' ELSE: Unknown
'[DB]
FUNCTION GetPrinterStatus

  regsx.ax = &H100
  regsx.dx = 0
  InterruptX &H17, regsx
  GetPrinterStatus = regsx.ax

END FUNCTION

'Returns information on the current screen mode:
'  ScrMode = Mode set by last SCREEN statement
'  ScrCols = Number of character columns
'  ScrRows = Number of character rows
'  CharHor = Width in pixels of text character
'  CharVer = Height in pixels of text character
'  ScrMaxX = Width in pixels of screen
'  ScrMaxY = Height in pixels of screen
'  MaxColours = Number of colours
'  VideoMem = Maximum video memory (in kbytes)
'  Page = Current screen page
'[DB]
SUB GetScreenMode (ScrMode, ScrCols, ScrRows, CharHor, CharVer, ScrMaxX, ScrMaxY, MaxColours, VideoMem, Page)

  DIM Buffer(200) AS INTEGER

  regsx.ax = &H1130
  regsx.bx = &H0
  InterruptX &H10, regsx
  ScrRows = (regsx.dx AND 255) + 1

  regsx.ax = &HF00
  InterruptX &H10, regsx
  ScrCols = (regsx.ax AND 65280) / 256
  Page = (regsx.bx AND 65280) / 256

  SELECT CASE regsx.ax AND 255
    CASE 0, 1
      ScrMode = 0
      CharHor = 9
      CharVer = 16
      ScrMaxX = 0
      ScrMaxY = 0
      MaxColours = 16

    CASE 2, 3
      ScrMode = 0
      IF ScrRows = 25 THEN
	CharHor = 9
	CharVer = 16
      ELSE
	CharHor = 8
	CharVer = 8
      END IF
      ScrMaxX = 0
      ScrMaxY = 0
      MaxColours = 16
	
    CASE 4, 5
      ScrMode = 1
      CharHor = 8
      CharVer = 8
      ScrMaxX = 320
      ScrMaxY = 200
      MaxColours = 4

    CASE 6
      ScrMode = 2
      CharHor = 8
      CharVer = 8
      ScrMaxX = 640
      ScrMaxY = 200
      MaxColours = 2

    CASE 7
      ScrMode = 0
      IF ScrRows = 25 THEN
	CharHor = 9
	CharVer = 16
      ELSE
	CharHor = 8
	CharVer = 8
      END IF
      ScrMaxX = 0
      ScrMaxY = 0
      MaxColours = 16

    CASE 13
      ScrMode = 7
      CharHor = 8
      CharVer = 8
      ScrMaxX = 320
      ScrMaxY = 200
      MaxColours = 16

    CASE 14
      ScrMode = 8
      CharHor = 8
      CharVer = 8
      ScrMaxX = 640
      ScrMaxY = 200
      MaxColours = 16

    CASE 15
      ScrMode = 10
      IF ScrRows = 25 THEN
	CharHor = 8
	CharVer = 14
      ELSE
	CharHor = 8
	CharVer = 8
      END IF
      ScrMaxX = 640
      ScrMaxY = 350
      MaxColours = 4

    CASE 16
      ScrMode = 9
      IF ScrRows = 25 THEN
	CharHor = 8
	CharVer = 14
      ELSE
	CharHor = 8
	CharVer = 8
      END IF
      ScrMaxX = 640
      ScrMaxY = 350
      MaxColours = 16

    CASE 17
      ScrMode = 11
      IF ScrRows = 30 THEN
	CharHor = 8
	CharVer = 16
      ELSE
	CharHor = 8
	CharVer = 8
      END IF
      ScrMaxX = 640
      ScrMaxY = 480
      MaxColours = 2

    CASE 18
      ScrMode = 12
      IF ScrRows = 30 THEN
	CharHor = 8
	CharVer = 16
      ELSE
	CharHor = 8
	CharVer = 8
      END IF
      ScrMaxX = 640
      ScrMaxY = 480
      MaxColours = 16

    CASE 19
      ScrMode = 13
      CharHor = 8
      CharVer = 8
      ScrMaxX = 320
      ScrMaxY = 200
      MaxColours = 256

  END SELECT
 
  regsx.ax = &H1B00
  regsx.bx = &H0
  regsx.es = VARSEG(Buffer(0))
  regsx.di = VARPTR(Buffer(0))

  SCREEN ScrMode
  WIDTH ScrCols, ScrRows

  InterruptX &H10, regsx

  DEF SEG = VARSEG(Buffer(0))
  VideoMem = PEEK(regsx.di + 49)
  DEF SEG

  SELECT CASE VideoMem
    CASE 0
      VideoMem = 64
    CASE 1
      VideoMem = 128
    CASE 2
      VideoMem = 192
    CASE 3
      VideoMem = 256
  END SELECT

END SUB

'Returns system setup info:
' FlDrives = Number of floppy drives
' CoPro = Co-processor present
' RS232s = Number of RS232s
' GPort = Game port present
' Modem = Modem present
' Printers = Number of printers
'[DB]
SUB GetSysConfig (FlDrives, CoPro, RS232s, GPort, Modem, Printers)
 
  InterruptX &H11, regsx

  IF regsx.ax AND 1 THEN
    FlDrives = (regsx.ax AND 192) / 64 + 1
  END IF
 
  CoPro = ((regsx.ax AND 2) <> 0)
 
  RS232s = (regsx.ax AND 3584) / 512
  GPort = ((regsx.ax AND 4096) <> 0)
  Modem = ((regsx.ax AND 8192 <> 0))
  Printers = (regsx.ax AND 49152) / 16384

END SUB

'[IM, from code by DG]
SUB InterruptX (IntNum, regsx AS RegTypeX) STATIC

  STATIC FileNum, IntOffset, Loaded
  
  ' use fixed-length string to fix its position in memory
  ' and so we don't mess up string pool before routine
  ' gets its pointers from caller
  DIM IntCode AS STRING * 200
  IF NOT Loaded THEN                        ' loaded will be 0 first time
   
    FOR k = 0 TO 145 'bit of a bodge, this, but it works <dg>
      READ h%        'if anyone fixes it, or explains it, let me know :) <dg>
      Icode$ = Icode$ + CHR$(h%)
    NEXT             'end of bodge <dg>
    
    IntCode = Icode$  ' load routine and determine
    IntOffset = INSTR(IntCode$, CHR$(&HCD) + CHR$(&H21)) + 1 ' int # offset
    Loaded = -1
  END IF
 
  DEF SEG = VARSEG(IntCode)             ' poke interrupt number into
  POKE VARPTR(IntCode) * 1& + IntOffset - 1, IntNum' code block
  CALL absolute(regsx, VARPTR(IntCode$)) ' call routine
  DEF SEG

END SUB

'Returns whether ANSI.SYS is loaded
'[DB, from code by WH]
FUNCTION IsAnsi
 
  regsx.ax = &H1A00
  InterruptX &H2F, regsx
  IsAnsi = ((regsx.ax AND &HFF) <> 0)

END FUNCTION

'Returns whether DOSKEY.COM is loaded
'[DB, from code by WH]
FUNCTION IsDoskey
   
  regsx.ax = &H4800
  InterruptX &H2F, regsx
  IsDoskey = ((regsx.ax AND &HFF) <> 0)

END FUNCTION

'Returns whether GRAFTABL.SYS is loaded
'[DB, from code by WH]
FUNCTION IsGraftabl
 
  regsx.ax = &HB00
  InterruptX &H2F, regsx
  IsGraftabl = ((regsx.ax AND &HFF) <> 0)

END FUNCTION

'Returns whether HIMEM.SYS is loaded
'[DB, from code by WH]
FUNCTION IsHimem

  regsx.ax = &H4300
  InterruptX &H2F, regsx
  IsHimem = ((regsx.ax AND &HFF) <> 0)

END FUNCTION

'Returns whether there is a print queue
'[DB, from code by WH]
FUNCTION IsPrintQ
 
  regsx.ax = &H100
  InterruptX &H2F, regsx
  IsPrintQ = ((regsx.ax AND &HFF) <> 0)

END FUNCTION

'Returns whether SHARE.EXE, or Windows similar, is loaded
'[DB, from code by WH]
FUNCTION IsShare

  regsx.ax = &H1000
  InterruptX &H2F, regsx
  IsShare = ((regsx.ax AND &HFF) <> 0)

END FUNCTION

'Function returns number (integer) converted to string format, with leading &
' trailing spaces stripped.
'[DB]
FUNCTION LRS$ (Number%)

  LRS$ = LTRIM$(RTRIM$(STR$(Number%)))
  
END FUNCTION

'Limit mouse movement
'[DB]
SUB MouseBorder (row1, col1, row2, col2) STATIC

  regsx.ax = &H1130
  regsx.bx = &H0
  InterruptX &H10, regsx
  ScrRows = (regsx.dx AND 255) + 1

  regsx.ax = &HF00
  InterruptX &H10, regsx
  ScrCols = (regsx.ax AND 65280) / 256

  SELECT CASE regsx.ax AND 255
    CASE 0, 2, 5, 7, 8, 9, 10, 11, 12  'Not used

    CASE 1, 4, 13, 19  'Screen 0/1/2, Width 40 x __//Screen 7/8/9, Width 40 x 25//Screen 13
      CharHor = 16
      CharVer = 8

    CASE 3, 6, 14  'Screen 0/1/2, Width 80 x __//Screen 7/8, Width 80 x 25
      CharHor = 8
      CharVer = 8

    CASE 15, 16  'Screen 10//Screen 9, Width 80 x __
      IF ScrRows = 25 THEN
	CharHor = 8
	CharVer = 14
      ELSE
	CharHor = 8
	CharVer = 8
      END IF

    CASE 17, 18  'Screen 11/12
      IF ScrRows = 30 THEN
	CharHor = 8
	CharVer = 16
      ELSE
	CharHor = 8
	CharVer = 8
      END IF

  END SELECT

  MouseDriver 7, 0, (col1 - 1) * CharHor, (col2 - 1) * CharHor
  MouseDriver 8, 0, (row1 - 1) * CharVer, (row2 - 1) * CharVer

END SUB

'Similar to MouseInit, but returns mouse status
'
FUNCTION MouseCheck

  MouseDriver 0, 0, 0, 0
  MouseCheck = MousePresent

END FUNCTION

'Waits until neither mouse button is pressed
'[DB]
SUB MouseClear

  DO
    MouseTextPos Row%, col%, lButton%, rButton%
  LOOP UNTIL NOT (lButton% OR rButton%)

END SUB

'General interrupt routine for mouse. See more advanced programming
' information for list of possible parameters.
'[DB, from code by MS]
SUB MouseDriver (m0, m1, m2, m3) STATIC

  IF NOT (MouseChecked) THEN
    DEF SEG = 0
    MouseSegment& = 256& * PEEK(207) + PEEK(206)
    MouseOffset& = 256& * PEEK(205) + PEEK(204)
    DEF SEG = MouseSegment&

    IF (MouseSegment& = 0 AND MouseOffset& = 0) OR PEEK(MouseOffset&) = 207 THEN
      MousePresent = FALSE
      MouseChecked = TRUE
      DEF SEG
    END IF
  END IF

  IF NOT (MouseChecked) OR MousePresent THEN

    ' Calls interrupt &H33 to invoke mouse functions in the MS Mouse Driver.
    regsx.ax = m0
    regsx.bx = m1
    regsx.cx = m2
    regsx.dx = m3

    InterruptX &H33, regsx

    m0 = regsx.ax
    m1 = regsx.bx
    m2 = regsx.cx
    m3 = regsx.dx

    IF NOT MouseChecked THEN
      ' Check for successful mouse initialization
      IF m0 THEN
	MousePresent = TRUE
	DEF SEG
      END IF
      MouseChecked = TRUE
    END IF
  END IF

END SUB

'Hides mouse cursor
'[MS]
SUB MouseHide

  MouseDriver 2, 0, 0, 0

END SUB

'MouseVers = Mouse driver version (x.xx)
'MouseType$ = Describes mouse
'MouseIRQ = IRQ being used by mouse (0 = PS/2 system)
'[DB]
SUB MouseInfo (MouseVers!, MouseType$, MouseIRQ)

  m0% = &H24
  MouseDriver m0%, m1%, m2%, m3%

  MouseVers! = ((m1% AND &HFF00) / 256) + ((m1% AND 255) / 100)
  SELECT CASE (m2% AND &HFF00) / 256
    CASE 1: MouseType$ = "Bus"
    CASE 2: MouseType$ = "Serial"
    CASE 3: MouseType$ = "InPort"
    CASE 4: MouseType$ = "PS/2"
    CASE 5: MouseType$ = "HP"
    CASE ELSE: MouseType$ = "Unknown"
  END SELECT
  MouseIRQ = m2% AND 255

END SUB

'Mouse driver's initialisation routine
'[MS]
SUB MouseInit

  MouseDriver 0, 0, 0, 0

END SUB

'Sets limits for the mouse (XMin, YMin)-(XMax, YMax)
'[MS]
SUB MouseLimit (XMin, YMin, XMax, YMax)

  MouseDriver 7, 0, XMin, XMax
  MouseDriver 8, 0, YMin, YMax

END SUB

'Polls mouse driver, then sets parameters accordingly
' NB: This routine returns the >character< position of the mouse cursor, even
'   though the >graphics< position is passed back by MouseDriver. This leads
'   to problems in some screens, with the cursor apparently pointing lower
'   than it actually is.
'     For safety in these cases, use MouseTextPos.
'     This routine works fine for SCREEN 0: WIDTH 80, 25.
'     For other modes, please see the file MOUSEDJB.TXT
'     I have not changed this querk, in order to maintain compatibility.
'[DB, from code by MS]
SUB MousePoll (Row, col, lButton, rButton) STATIC

  MouseDriver 3, button, col, Row
  Row = Row / 8 + 1
  col = col / 8 + 1

  IF button AND 1 THEN
    lButton = TRUE
  ELSE
    lButton = FALSE
  END IF

  IF button AND 2 THEN
    rButton = TRUE
  ELSE
    rButton = FALSE
  END IF

END SUB

'Polls mouse driver, then sets parameters accordingly
'[MS]
SUB MousePos (XPos, YPos, lButton, rButton) STATIC

  MouseDriver 3, button, XPos, YPos

  regsx.ax = &HF00
  InterruptX &H10, regsx
  Test = regsx.ax AND 255
  IF (Test = 4) OR (Test = 5) OR (Test = 13) OR (Test = 19) THEN
    XPos = XPos / 2
  END IF

  IF button AND 1 THEN
    lButton = TRUE
  ELSE
    lButton = FALSE
  END IF

  IF button AND 2 THEN
    rButton = TRUE
  ELSE
    rButton = FALSE
  END IF

END SUB

'Shows mouse cursor
'[MS]
SUB MouseShow

  MouseDriver 1, 0, 0, 0

END SUB

'Polls mouse driver, then sets parameters accordingly.
' (Only tested on VGA screen)
'[DB]
SUB MouseTextPos (Row, col, lButton, rButton) STATIC

  MouseDriver 3, button, col, Row

  regsx.ax = &H1130
  regsx.bx = &H0
  InterruptX &H10, regsx
  ScrRows = (regsx.dx AND 255) + 1

  regsx.ax = &HF00
  InterruptX &H10, regsx
  ScrCols = (regsx.ax AND 65280) / 256

  SELECT CASE regsx.ax AND 255
    CASE 0, 2, 5, 7, 8, 9, 10, 11, 12  'Not used

    CASE 1, 4, 13, 19  'Screen 0/1/2, Width 40 x __//Screen 7/8/9, Width 40 x 25//Screen 13
	 CharHor = 16
	 CharVer = 8

    CASE 3, 6, 14  'Screen 0/1/2, Width 80 x __//Screen 7/8, Width 80 x 25
	 CharHor = 8
	 CharVer = 8

    CASE 15, 16  'Screen 10//Screen 9, Width 80 x __
	 IF ScrRows = 25 THEN
	   CharHor = 8
	   CharVer = 14
	 ELSE
	   CharHor = 8
	   CharVer = 8
	 END IF

    CASE 17, 18  'Screen 11/12
	 IF ScrRows = 30 THEN
	   CharHor = 8
	   CharVer = 16
	 ELSE
	   CharHor = 8
	   CharVer = 8
	 END IF

  END SELECT

  Row = FIX(Row / CharVer) + 1
  col = FIX(col / CharHor) + 1

  IF button AND 1 THEN
    lButton = TRUE
  ELSE
    lButton = FALSE
  END IF

  IF button AND 2 THEN
    rButton = TRUE
  ELSE
    rButton = FALSE
  END IF

END SUB

DEFSNG A-Z
'Calculates perpendicular distance of point (XPt, YPt) from line y = mx + c
'[DB]
FUNCTION PerpDist (XPt, YPt, M, c)

  IF ABS((YPt - c) / M) < .0000001 THEN
    XPos = 0
  ELSE
    XPos = (M * (YPt - c) + XPt) / (M ^ 2 + 1)
  END IF

  'Checks which side of line pt is
  IF YPt < M * XPt + c THEN
    Factor = -1
  ELSE
    Factor = 1
  END IF

  PerpDist = Factor * SQR((YPt - (M * XPos + c)) ^ 2 + (XPt - XPos) ^ 2)

END FUNCTION

DEFINT A-Z
'[DB]
SUB ScrollDown (Top, Left, Bottom, Right)

  regsx.ax = &H601
  regsx.bx = &H0
  regsx.cx = (Top - 1) * 256 + (Left - 1)
  regsx.dx = (Bottom - 1) * 256 + (Right - 1)
  InterruptX &H10, regsx

END SUB

'[DB]
SUB ScrollUp (Top, Left, Bottom, Right)

  regsx.ax = &H701
  regsx.bx = &H0
  regsx.cx = (Top - 1) * 256 + (Left - 1)
  regsx.dx = (Bottom - 1) * 256 + (Right - 1)
  InterruptX &H10, regsx

END SUB

DEFSNG A-Z
'Performs basic stats operations on (XStat(), YStat()) data.
'[DB]
SUB Stats (XStat(), YStat(), Number%, XBar, YBar, MajGrad, MinGrad, MajYInt, MinYInt, SigmaP, SigmaQ, Fit)

  FOR Pnt% = 1 TO Number%
    SumX = SumX + XStat(Pnt%)
    SumXSq = SumXSq + (XStat(Pnt%)) ^ 2
    SumY = SumY + YStat(Pnt%)
    SumYSq = SumYSq + (YStat(Pnt%)) ^ 2
    SumXY = SumXY + XStat(Pnt%) * YStat(Pnt%)
  NEXT
 
  XBar = SumX / Number%
  YBar = SumY / Number%
  Numer = Number% * SumXY - SumX * SumY
  Denom = Number% * SumXSq - SumX ^ 2
 
  IF Numer = 0 THEN
    IF Denom = 0 THEN
      MajGrad = 1E+10
    ELSE
      MajGrad = 1E-10
    END IF
  ELSE
    IF Denom = 0 THEN
      IF Numer > 0 THEN
	MajGrad = 1E+10
      END IF
    ELSE
      MajGrad = Numer / Denom
    END IF
  END IF

  MinGrad = -1 / MajGrad

  IF XBar = 0 THEN
    IF MajGrad < .0000001 THEN
      MajYInt = YBar - MajGrad * XBar
      MinYInt = 1E+20
    ELSEIF MinGrad < .0000001 THEN
      MajYInt = 1E+20
      MinYInt = YBar + XBar / MajGrad
    END IF
  ELSE
    MajYInt = YBar - MajGrad * XBar
    MinYInt = YBar + XBar / MajGrad
  END IF

  FOR Pnt% = 1 TO Number%
    Dist1 = PerpDist(XStat(Pnt%), YStat(Pnt%), MinGrad, MinYInt)
    Dist2 = PerpDist(XStat(Pnt%), YStat(Pnt%), MajGrad, MajYInt)
    SumP = SumP + Dist1
    SumPSq = SumPSq + Dist1 ^ 2
    SumQ = SumQ + Dist2
    SumQSq = SumQSq + Dist2 ^ 2
  NEXT

  IF SumPSq = 0 THEN
    Sq = 0
  ELSE
    IF ABS(1 - (SumP ^ 2) / (Number% * SumPSq)) < .0000001 THEN
      Sq = 0
    ELSE
      Sq = SumPSq / Number% - (SumP / Number%) ^ 2
    END IF
  END IF
  SigmaP = SQR(Sq)

  IF SumQSq = 0 THEN
    Sq = 0
  ELSE
    IF ABS(1 - (SumQ ^ 2) / (Number% * SumQSq)) < .0000001 THEN
      Sq = 0
    ELSE
      Sq = SumQSq / Number% - (SumQ / Number%) ^ 2
    END IF
  END IF
  SigmaQ = SQR(Sq)

'  Fit = (Number% * SumXY - SumX * SumY) / SQR((Number% * SumXSq - SumX ^ 2) * (Number% * SumYSq - SumY ^ 2))

END SUB

DEFINT A-Z
'Returns the volume label for drive Dr$: based on Ian Musgrave's DIR$
'[DB, from code by BJ]
FUNCTION VolLab$ (Dr$)

  DIM DTA AS STRING * 44

  '-----  Set up our own DTA so we don't destroy COMMAND$
  regsx.ax = &H1A00                    'Set DTA function
  regsx.dx = VARPTR(DTA)               'DS:DX points to our DTA
  regsx.ds = -1                        'Use current value for DS
  InterruptX &H21, regsx                 'Do the interrupt
    
  IF Dr$ <> "" THEN
    Dr$ = UCASE$(LEFT$(Dr$, 1)) + ":"
  END IF

  DrZ$ = Dr$ + "\*.*" + CHR$(0)                           ' make a$ asciiz

  regsx.ax = &H4E00              'Perform a FindFirst
  regsx.cx = 8
  regsx.dx = SADD(DrZ$)       'DS:DX points to ASCIIZ file
  regsx.ds = -1                     'Use current DS
    
  InterruptX &H21, regsx                 'Do the interrupt
    
  '-----  Return file name or null
  IF regsx.flags AND 1 THEN            'No files found
    VolLab$ = ""                        'Return null string
  ELSE
    Null = INSTR(31, DTA, CHR$(0))     'Get the filename found
    Temp$ = MID$(DTA, 31, Null - 31)  'It's an ASCIIZ string starting
  END IF                              'at offset 30 of the DTA
  Dot = INSTR(Temp$, ".")
  IF Dot THEN
    Temp$ = LEFT$(Temp$, Dot - 1) + MID$(Temp$, Dot + 1)
  END IF
 
  VolLab$ = LTRIM$(RTRIM$(Temp$))

END FUNCTION

DEFSNG A-Z
'[DB]
SUB WaitForAnyKey (Pause)

  Start# = TIMER
  DO
    MouseTextPos Row%, col%, lButton%, rButton%
  LOOP UNTIL ((Pause <> 0) AND (TIMER - Start# >= Pause)) OR (INKEY$ <> "") OR lButton% OR rButton%

END SUB

