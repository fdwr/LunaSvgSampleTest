' ***************************************************************************
' Source Code for The Ultimate MKJ Player v2.1
' Written by Luke Molnar
' A Molnar \ Kucalaba Productions Program 1996-97
' ***************************************************************************
' This file, like many of our others that are copied and put on other
' people's websites, originated at http://members.aol.com/mkwebsite.
' There are lots more programs there that people have yet to leech,
' so it would be worth your time to visit if you want QBasic programs.
' ***************************************************************************
' Reason #1 Why We Don't Give Out Our Source Code for Big Projects
'
'  Try running this in either QBasic or QB 4.5.  If it doesn't
'  crash while binding, it still runs way too slow.  Is that
'  the form you want something you've worked on to be viewed?
'
' ***************************************************************************



'------ Data types used in Functions ------
 TYPE FileStruct
    attrib AS INTEGER
    filedate AS STRING * 10
    filetime AS STRING * 8
    filesize AS DOUBLE
 END TYPE
 TYPE QBSucks
    Dat AS STRING * 12
 END TYPE
'-----------------------------------------

'----- Procedure Declarations -----
DECLARE FUNCTION TheyClickedVol% ()
DECLARE FUNCTION IsSolo% (Channel%)
DECLARE FUNCTION TheyClickedASolo% ()
DECLARE FUNCTION IsGreen% (Channel%)
DECLARE FUNCTION TheyClickedAMute% ()
DECLARE FUNCTION TheyClickedStop% ()
DECLARE FUNCTION TheyClickedPlay% ()
DECLARE FUNCTION ItsNotWhere% ()
DECLARE FUNCTION TheyClickedInsBar% ()
DECLARE FUNCTION ItsOverVU% ()
DECLARE FUNCTION ItsOverNotes% ()
DECLARE FUNCTION TheyClickedDisplay% ()
DECLARE FUNCTION GetFile% (PostFix$)
DECLARE FUNCTION ItsNowhere% ()
DECLARE FUNCTION ItsOverExit% ()
DECLARE FUNCTION AlreadyBright% (Col%)
DECLARE FUNCTION LoadJamFile% (File$)
DECLARE FUNCTION MouseInit% ()
DECLARE FUNCTION ItsOverDOSShell% ()
DECLARE FUNCTION ItsOverOpen% ()
DECLARE FUNCTION TheyClickedFile% ()
DECLARE FUNCTION Fixed$ (FileName$)
DECLARE FUNCTION FindCard% ()
DECLARE FUNCTION ItsNotAnyWhere% ()
DECLARE FUNCTION ItsOverAbout% ()
DECLARE FUNCTION ItsOverCont% ()
DECLARE FUNCTION ItsOverSupport% ()
DECLARE FUNCTION TheyClickedHelp% ()
DECLARE FUNCTION ItsOverInfo% ()
DECLARE FUNCTION TheyClickedSlower% ()
DECLARE FUNCTION TheyClickedFaster% ()
DECLARE FUNCTION OpenFile$ (Option$)
DECLARE FUNCTION WhereTheyClicked% ()
DECLARE FUNCTION OFUpdate% (Funct%)
DECLARE FUNCTION GetDrv% ()
DECLARE FUNCTION GetDir$ (Drive%)
DECLARE FUNCTION Dir.Find$ ()
DECLARE SUB ClearNotes ()
DECLARE SUB LoadIns (FileName$)
DECLARE SUB PopInsMenu (Channel%)
DECLARE SUB OFText (w%)
DECLARE SUB Alpha (Sort() AS ANY)
DECLARE SUB Dir.FileInfo (File AS ANY)
DECLARE SUB Dir.Init (path.o$, attrib.o%)
DECLARE SUB DrawVU ()
DECLARE SUB OFDraw ()
DECLARE SUB OFInit ()
DECLARE SUB ClearVU ()
DECLARE SUB Font (text$, XStart%, ystart%, xscale%, YScale%, Clr%)
DECLARE SUB FillMute (Channel%, Booyah%)
DECLARE SUB Center (Row%, text$)
DECLARE SUB Help ()
DECLARE SUB Support ()
DECLARE SUB About ()
DECLARE SUB DoTheVUThing ()
DECLARE SUB PlaceBar (x%)
DECLARE SUB FMVolume (Right%)
DECLARE SUB DragTheBar ()
DECLARE SUB ShowFace (x%)
DECLARE SUB PopItDown ()
DECLARE SUB ShowInfo ()
DECLARE SUB PopItUp ()
DECLARE SUB ReleaseMouse ()
DECLARE SUB CorePlay ()
DECLARE SUB GetPress ()
DECLARE SUB VuSetUp ()
DECLARE SUB PlayMusicB ()
DECLARE SUB PlayMusicA ()
DECLARE SUB DrawNote (note$, channe%, length!, position!)
DECLARE SUB Clef (a!, B!)
DECLARE SUB ShowStaff (number%)
DECLARE SUB PlayMusic ()
DECLARE SUB PopDown ()
DECLARE SUB PopUp ()
DECLARE SUB PopDownTheDamnMenu ()
DECLARE SUB MakeBright (Col%)
DECLARE SUB PopUpTheDamnMenu ()
DECLARE SUB LoadFont ()
DECLARE SUB CloseChannels ()
DECLARE SUB ResetSong ()
DECLARE SUB SBInit ()
DECLARE SUB SetIns (Channel%)
DECLARE SUB WriteReg (Reg%, value%)
DECLARE SUB DrawEverything ()
DECLARE SUB FSet (Att%, R%, G%, B%)
DECLARE SUB MouseStatus (lb%, rb%, xMouse%, yMouse%)
DECLARE SUB MouseRange (X1%, Y1%, x2%, Y2%)
DECLARE SUB MousePut (x%, y%)
DECLARE SUB MouseHide ()
DECLARE SUB MouseDriver (ax%, bx%, cx%, dx%)
DECLARE SUB MouseShow ()
DECLARE SUB UnMuteChannels ()
'----- Procedure Declarations -----

  CONST F.NOR = &H200  'constant for "normal" files (*files* displayed with DIR)
  CONST F.NON = &H100  'constant for files without any attribute
  CONST F.ARC = &H20   'constant for archive file attribute
  CONST F.DIR = &H10   'constant for directory file attribute
  CONST F.VOL = &H8    'constant for volume file attribute
  CONST F.SYS = &H4    'constant for system file attribute
  CONST F.HID = &H2    'constant for hidden file attribute (may return directory)
  CONST F.RDO = &H1    'constant for read-only file attribute
  CONST F.ANY = &H0    'constant for any of the above


'----- Program Defaults -----
'$DYNAMIC
DEFINT A-Z
CLS
SCREEN 12
DEF SEG = &HA000
ON ERROR GOTO Bad
'----- Program Defaults -----

'----- User-defined Data Types -----
TYPE BarType
 L AS INTEGER
 Decay AS SINGLE
 De AS INTEGER
END TYPE

TYPE InsType
 MMult AS INTEGER     ' Modulator's Multiple
 MLevel AS INTEGER    ' Modulator's Level
 MAttack AS INTEGER   ' Modulator's Attack
 MSustain AS INTEGER  ' Modulator's Sustain
 CMult AS INTEGER     ' Carrier's Multiple
 CLevel AS INTEGER    ' Carrier's Level
 CAttack AS INTEGER   ' Carrier's Attack
 CSustain AS INTEGER  ' Carrier's Sustain
END TYPE

TYPE ChannelType
 Defined AS INTEGER   ' Has the user defined the channel and it's notes? (1 if yes)
 Speed AS SINGLE      ' The duration of each note
 SongPtr AS INTEGER   ' A pointer to the current song position
 Pstat AS SINGLE      ' Pause counter 2
 Octave AS INTEGER    ' The Octave of each channel
 WaveForm AS INTEGER  ' The Wave Form of each channel
 Flag AS INTEGER      ' Misc control flag
 Flag2 AS INTEGER     ' Number of times to play song
 ISPlaying AS INTEGER ' Is a note playing (1=yes)
 IsDone AS INTEGER    ' Has the note stopped? (1=yes)
 Speedscale AS SINGLE ' Special feature
 Mute AS INTEGER      ' Special Feature
END TYPE

 TYPE OFType
   HighFile AS INTEGER  ' The highlighted file (File element number/pointer)
   HighDir AS INTEGER   ' The highlighted directory
   FileSpot AS INTEGER  ' The location of the arrow at the bottom of the fbox
   MaxFSpot AS INTEGER  ' The maximum number of columns of files
   DirSpot AS INTEGER   ' The location of the arrow.....dir box
   NumFiles AS INTEGER
   MaxDSpot AS INTEGER
   Time AS SINGLE       ' Timer buffer
   Flag AS INTEGER      ' Misc flag
   Opt AS STRING * 3
   CurDir AS STRING * 40
 END TYPE

'----- User-defined Data Types -----


'----- Global variable and buffer declarations -----
DIM SHARED ChannelStat(1 TO 2) AS ChannelType, Retrace%
DIM SHARED Songbuf(1 TO 2) AS INTEGER, SaveChanges%, SongDir$
DIM SHARED CurrentIns AS InsType, FileName$, ISPlaying%, Volume%, Cde%
DIM SHARED Back%(20000), DisType%, BarX%, BarY%, Left%, Right%
DIM SHARED Bars(1 TO 10) AS BarType, DecayStep!
DIM SHARED FontBuf(0) AS STRING * 10368, Choice%, Ver!, BasePort%, PostFix$
DIM SHARED Mouse$, x%, y%, lb%, rb%, notex!, CurrentArea%
DIM SHARED MaxChannel%, MaxNotes%, CurrentSong$, SongName$
DIM SHARED File(350) AS QBSucks
DIM SHARED DirList(150) AS QBSucks
DIM SHARED OF AS OFType
'----- Global variable and buffer declarations -----

'----- Bug fix variable inits -----
Mouse$ = SPACE$(57)
Volume% = 10
DisType% = 1
notex! = 50
CurrentArea% = 1
'----- Bug fix variable inits -----


'----- Mouse driver init -----
FOR I% = 1 TO 57:  READ a$:  h$ = CHR$(VAL("&H" + a$))
MID$(Mouse$, I%, 1) = h$: NEXT I%
DATA 55,89,E5,8B,5E,0C,8B,07,50,8B,5E,0A,8B,07,50,8B
DATA 5E,08,8B,0F,8B,5E,06,8B,17,5B,58,1E,07,CD,33,53
DATA 8B,5E,0C,89,07,58,8B,5E,0A,89,07,8B,5E,08,89,0F
DATA 8B,5E,06,89,17,5D,CA,08,00
RESTORE
ms% = MouseInit%
IF NOT ms% THEN ERROR 253
MouseRange 0, 0, 630, 478
'----- Mouse driver init -----


'----- Sound Blaster detection and init -----
FOR BasePort% = &H210 TO &H280 STEP &H10
 IF FindCard% = 1 THEN Yeah% = 1: EXIT FOR
NEXT
IF Yeah% = 0 THEN ERROR 254 ELSE PRINT "SB found at 0x" + HEX$(BasePort%)
SBInit
'----- Sound Blaster detection and init -----


'---- Font init -----
LoadFont
'---- Font init -----


'----- Command line parser -----
CLS
IF COMMAND$ <> "" THEN
 FileName$ = COMMAND$
 Cde% = -1
 Ret% = LoadJamFile(FileName$)
 DisType% = 2
 ISPlaying% = -1
END IF
'----- Command line parser -----

'----- Top of the main program -----
ReStart:
DrawEverything
IF DisType% = 1 THEN ShowStaff 1 ELSE VuSetUp
MouseShow
'---- Program Init crap ----

'---- Main code ----
DO

MouseStatus lb%, rb%, x%, y%


SELECT CASE lb%

 CASE -1:
        
     IF TheyClickedVol% THEN
      DragTheBar
     END IF

     IF DisType% = 2 THEN
      Poll% = TheyClickedAMute%
      IF Poll% AND (IsSolo(Poll%) = 0) THEN
        IF IsGreen%(Poll%) THEN
         FillMute Poll%, 10
         ChannelStat(Poll%).Mute = 1
        ELSE
         FillMute Poll%, 14
         ChannelStat(Poll%).Mute = 0
        END IF
        ReleaseMouse
      END IF
     
      Poll% = TheyClickedInsBar%
      IF Poll% <> 0 THEN
              PopInsMenu Poll%
      END IF

     
      Poll% = TheyClickedASolo%
      IF Poll% THEN
       
        IF IsSolo(Poll%) THEN
         FOR XY% = 1 TO MaxChannel%
          ChannelStat(XY%).Mute = 0
          FillMute XY%, 24
          FillMute XY%, 14
         NEXT
         ReleaseMouse
        ELSE
          FOR XY% = 1 TO MaxChannel%
            FillMute XY%, 10
            FillMute XY%, 24
            ChannelStat(XY%).Mute = 1
          NEXT
         FillMute Poll%, 22
         FillMute Poll%, 14
         ChannelStat(Poll%).Mute = 0
        END IF

        ReleaseMouse
      END IF
     END IF
           IF TheyClickedFaster% THEN
             FOR x% = 1 TO MaxChannel%
              IF ChannelStat(x%).Speedscale >= .4 THEN ChannelStat(x).Speedscale = ChannelStat(x%).Speedscale - .2
               IF ChannelStat(x%).Flag = -1 THEN
                ChannelStat(x%).Pstat = TIMER + ((ChannelStat(x%).Pstat - TIMER) * ChannelStat(x%).Speedscale)
               END IF
             NEXT
             ReleaseMouse
           END IF
           IF TheyClickedSlower% THEN
             FOR x% = 1 TO MaxChannel%
              IF ChannelStat(x%).Speedscale <= 4 THEN ChannelStat(x).Speedscale = ChannelStat(x%).Speedscale + .2
               IF ChannelStat(x%).Flag = -1 THEN
                ChannelStat(x%).Pstat = TIMER + ((ChannelStat(x%).Pstat - TIMER) * ChannelStat(x%).Speedscale)
               END IF
             NEXT
            ReleaseMouse
           END IF
         
          IF TheyClickedFile THEN
             Stat% = 0
             PopUpTheDamnMenu
              DO
                 MouseStatus lb%, rb%, x%, y%

                 IF TheyClickedDisplay% THEN
                  PopDownTheDamnMenu
                  PopUp
                  GOTO JumpDisplay
                 ELSEIF TheyClickedHelp THEN
                  PopDownTheDamnMenu
                  PopItUp
                  GOTO JumpHelp
                 END IF
JumpFile:
               IF ISPlaying% = -1 THEN
                 IF DisType% = 1 THEN CorePlay ELSE PlayMusicB: DoTheVUThing
               END IF
              
               IF ItsOverOpen% AND Stat% <> 1 THEN
                IF AlreadyBright(1) THEN
                 MakeBright 1: Stat% = 1
                END IF
               ELSEIF ItsOverDOSShell% AND Stat% <> 2 THEN
                IF AlreadyBright(2) THEN
                 MakeBright 2: Stat% = 2
                END IF
               ELSEIF ItsOverInfo% AND Stat% <> 3 THEN
                IF AlreadyBright(3) THEN
                 MakeBright 3: Stat% = 3
                END IF
               ELSEIF ItsOverExit% AND Stat% <> 4 THEN
                IF AlreadyBright(1) THEN
                 MakeBright 4: Stat% = 4
                END IF
               ELSEIF ItsNowhere% THEN
                IF Stat% <> -1 THEN MakeBright -1
                Choice% = 0: Stat% = -1
               END IF
            
              LOOP UNTIL lb% = 0
              PopDownTheDamnMenu

              SELECT CASE Choice%
               CASE 1:
                       IF GetBack% = -1 THEN FileName$ = "": GetBack% = 0
                       PostFix$ = "MKJ"
                       x% = GetFile%(PostFix$)
                       IF SGN(x%) = 1 THEN
                        LINE (301, 1)-(638, 23), 5, BF
                        Font "Current File : " + FileName$, 302, 10, 1, 1, 15
                        SongName$ = FileName$
                        CD% = GetDrv: swp% = CD%: path$ = GetDir$(swp%)
                        Total$ = CHR$(CD% + 65) + ":" + path$
                        Total$ = LEFT$(Total$, LEN(Total$) - 1)
                        SongDir$ = Total$ + "\"
                        CurrentSong$ = SongDir$ + SongName$
                        GetBack% = -1
                       ELSE
                        FileName$ = ""
                       END IF
               CASE 2: ISPlaying% = 0: ResetSong
                       CLS : SCREEN 0: WIDTH 80
                       PRINT "Type EXIT to exit the shell": SHELL: CLS : SCREEN 12: GOTO ReStart
               CASE 3: ShowInfo
               CASE 4: CLS : SCREEN 0: WIDTH 80: SBInit: SYSTEM
              END SELECT
           END IF
          
           IF TheyClickedDisplay% THEN
            Stat% = 0
           
            PopUp
            
              DO
                MouseStatus lb%, rb%, x%, y%
               
                IF TheyClickedFile THEN
                  PopDown
                  PopUpTheDamnMenu
                  GOTO JumpFile
                ELSEIF TheyClickedHelp THEN
                  PopDown
                  PopItUp
                  GOTO JumpHelp
                END IF


JumpDisplay:
               IF ISPlaying% = -1 THEN
                 IF DisType% = 1 THEN CorePlay ELSE PlayMusicB: DoTheVUThing
               END IF
              
               IF ItsOverNotes AND Stat% <> 1 THEN
                IF AlreadyBright(1) THEN
                 MakeBright 1: Stat% = 1
                END IF
               ELSEIF ItsOverVU AND Stat% <> 2 THEN
                IF AlreadyBright(2) THEN
                 MakeBright 2: Stat% = 2
                END IF
               ELSEIF ItsNotWhere% THEN
                IF Stat% <> -1 THEN MakeBright -1
                Choice% = 0: Stat% = -1
               END IF
             
              LOOP UNTIL lb% = 0
              PopDown
            MouseHide
            SELECT CASE Choice%
             CASE 1: ShowStaff 1: DisType% = 1: ResetSong: MakeBright -1
             CASE 2: VuSetUp: DisType% = 2: ResetSong
            END SELECT
            MouseShow
           END IF

           IF TheyClickedHelp% THEN
            Stat% = 0
            PopItUp
            DO
               MouseStatus lb%, rb%, x%, y%
              
               IF ISPlaying% = -1 THEN CorePlay

               IF TheyClickedFile THEN
                PopItDown
                PopUpTheDamnMenu
                GOTO JumpFile
               ELSEIF TheyClickedDisplay THEN
                PopItDown
                PopUp
                GOTO JumpDisplay
               END IF

JumpHelp:
               IF ISPlaying% = -1 THEN
                 IF DisType% = 1 THEN CorePlay ELSE PlayMusicB: DoTheVUThing
               END IF
               IF ItsOverCont% AND Stat% <> 1 THEN
                IF AlreadyBright(1) THEN
                 MakeBright 1: Stat% = 1
                END IF
               ELSEIF ItsOverSupport% AND Stat% <> 2 THEN
                IF AlreadyBright(2) THEN
                 MakeBright 2: Stat% = 2
                END IF
               ELSEIF ItsOverAbout AND Stat% <> 3 THEN
                IF AlreadyBright(3) THEN
                 MakeBright 3: Stat% = 3
                END IF
               ELSEIF ItsNotAnyWhere% THEN
                IF Stat% <> -1 THEN MakeBright -1
                Choice% = 0: Stat% = -1
               END IF

            LOOP UNTIL lb% = 0
            PopItDown

            SELECT CASE Choice%
              CASE 1: Help: GOTO ReStart
              CASE 2: Support
              CASE 3: About

            END SELECT

           END IF


           IF TheyClickedPlay AND ChannelStat(1).Defined = 1 THEN ISPlaying% = -1
           IF TheyClickedStop THEN
            IF DisType% = 2 THEN
                UnMuteChannels
                DrawVU
                ClearNotes
                ReleaseMouse
            END IF
            ISPlaying% = 0: ResetSong
           END IF

END SELECT





IF ISPlaying% = -1 THEN

 IF DisType% = 1 THEN
  PlayMusicA
 END IF

 IF DisType% = 2 THEN
   PlayMusicB
   DoTheVUThing
 END IF

END IF
LOOP

'---- Main code ----


CLS
SCREEN 0
WIDTH 80
SYSTEM

Bad:
CLS
SCREEN 0
WIDTH 80
COLOR 15, 1

PRINT "                                                                                "
PRINT "  An error occured which was so severe that this program could not continue to  "
PRINT "                   execute occured.  Here's a description :                     "
PRINT "                                                                                "
COLOR 14, 1

SELECT CASE ERR
 CASE 254:
PRINT "     A Sound Blaster compatible card was not found anywhere, and we checked     "
PRINT "everywhere.  (Base ports 210h through 280h)  If you don't like that, then get a "
PRINT "                           sound card that works with this.                     "
CASE 253:
PRINT "   We could not find your mouse, or more appropiately, your mouse driver.  To   "
PRINT " remedy the situation, either go buy a mouse from your local computer store or  "
PRINT "install a new mouse driver that works with this.  And, if you doubt the quality "
PRINT "  of our mouse routines, than you might be right but they have worked on every  "
PRINT "                      computer that we have ever tried them on.                 "
 CASE ELSE
PRINT " This was a very, very unexpected error.  So much, in fact, that we didn't even "
PRINT "write up a specialized error message.  Probable causes may be a file name with a"
PRINT "                          comma in it or something.                             "

END SELECT

COLOR 15, 1
PRINT "                                                                                "
PRINT "                 For technical support, email blood225@aol.com                  "
COLOR 7, 0
GetPress
SYSTEM


FontData:
DATA &H7E,&H2,&H55,&H8A,&H15,&HAB,&H52,&H20,&H3F,&H0,&HFC,&HFC,&H5B,&HF7,&HEC,&HD9,&HBA,&H7F,&H7E,&H0,&H38,&HF8,&HF0,&HC3,&HCF,&H8F,&HF,&HE,&H0,&H0,&H40,&HC0
DATA &HC1,&HC7,&H1F,&H1F,&H1C,&H10,&H0,&H0,&H80,&H41,&HD7,&HBF,&H7F,&HFF,&H74,&H61,&H0,&H0,&H0,&H2,&H2E,&H7E,&HFF,&HF8,&HE1,&H82,&H0,&H0,&H0,&H0,&H0,&H0
DATA &H0,&H0,&H0,&H0,&H0,&H0,&H80,&H7F,&HFF,&HCE,&HD,&H1B,&H76,&HEE,&HDF,&H3F,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0
DATA &H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0
DATA &H0,&H0,&H0,&H0,&HD8,&HBF,&H3F,&H5,&HA,&H94,&HF9,&HF3,&H3,&H40,&H26,&H2D,&H3C,&HCE,&H9D,&HE3,&HA1,&H25,&H13,&H80,&H3F,&H3E,&H7C,&H70,&HE0,&H80,&H0,&H1
DATA &H0,&H0,&H8,&H10,&H70,&HE0,&HE0,&HC3,&HC7,&H1F,&H0,&H0,&H0,&H90,&H30,&HF3,&HEF,&H9F,&H19,&H12,&H0,&H0,&H0,&HF8,&HF2,&H5,&H0,&H80,&H2F,&H5F,&H0,&H0
DATA &H30,&HF0,&H20,&HC1,&H9F,&H3F,&H1,&HFE,&HFC,&H1,&H0,&H44,&HDB,&HAF,&H52,&HFD,&HB2,&HC,&H10,&H0,&H0,&H0,&H1C,&H38,&H70,&HE0,&HC0,&H81,&H3,&H0,&H0,&H20
DATA &H4A,&HB6,&HFE,&HFD,&HB3,&H45,&H9,&H10,&H0,&H0,&H4,&HC,&HFC,&HF9,&H63,&H80,&H0,&H0,&H0,&H0,&H20,&HC0,&HF8,&HF3,&H7,&H6,&H4,&H0,&H0,&H10,&H20,&H40
DATA &HA0,&HC2,&H7,&H7,&H4,&H0,&H0,&H20,&HE0,&HE0,&H43,&H5,&H2,&H4,&H8,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0
DATA &H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0
DATA &H0,&H0,&H0,&H0,&H0,&H1C,&H7C,&HF9,&HE2,&H0,&H0,&H0,&H0,&H0,&H0,&H1C,&H38,&H0,&HE0,&HC0,&H1,&H0,&H0,&H0,&H50,&HF8,&HF3,&H87,&HC2,&H9F,&H3F,&H14
DATA &H0,&H0,&H20,&HE1,&H62,&HCD,&H1A,&H1D,&H12,&H0,&H0,&H0,&H60,&HC4,&HC,&HC,&HC,&HC,&HCC,&H88,&H1,&H0,&H0,&H86,&H9E,&H27,&H5D,&H6E,&HE8,&H41,&H2,&H0
DATA &H0,&H81,&H3,&H3,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H1C,&H7C,&H8C,&H9,&H2,&H0,&H0,&H0,&H0,&H0,&H82,&H8C,&HF1,&HC1,&H1,&H0,&H0,&H0,&H0,&H10
DATA &HA8,&HF0,&HC1,&H81,&H83,&HF,&H15,&H8,&H0,&H20,&H40,&HE0,&HC3,&H7,&H2,&H4,&H0,&H0,&H0,&H0,&H0,&H8,&H1C,&H18,&H0,&H0,&H0,&H0,&H0,&H80,&H0,&H1
DATA &H2,&H4,&H8,&H10,&H0,&H0,&H0,&H0,&H0,&H0,&H30,&H60,&H0,&H0,&H0,&H0,&H0,&H0,&H18,&H18,&H18,&H18,&H18,&H18,&H10,&H0,&H0,&H0,&H1F,&H7F,&HE2,&H64
DATA &H69,&HF2,&HC7,&H7,&H0,&H0,&H40,&H84,&HFC,&HF9,&H3,&H4,&H8,&H0,&H0,&H0,&HC4,&HCC,&HC9,&H92,&HE4,&H8D,&H19,&H0,&H0,&H0,&H88,&H18,&H93,&H24,&HC9,&H1F
DATA &H1B,&H0,&H0,&H0,&HC0,&HC0,&HC1,&HC2,&H94,&H3F,&H7F,&HA0,&H0,&H0,&H70,&HE2,&H4C,&H91,&H22,&H7D,&H72,&H0,&H0,&H0,&H80,&H87,&H9F,&H25,&H49,&HF2,&HC0,&H0
DATA &H0,&H0,&HC0,&H80,&H1,&H71,&HF2,&H3C,&H38,&H0,&H0,&H0,&H0,&H1B,&H7F,&H92,&H24,&HF9,&H63,&H3,&H0,&H0,&H0,&H6,&H9E,&H24,&H49,&HF3,&HC3,&H3,&H0,&H0
DATA &H0,&H0,&H0,&H30,&H63,&H6,&H0,&H0,&H0,&H0,&H0,&H0,&H0,&H64,&HCE,&HC,&H0,&H0,&H0,&H0,&H0,&H40,&HC0,&HC1,&HC6,&H98,&H20,&H0,&H0,&H0,&H0,&H40
DATA &H82,&H4,&H9,&H12,&H24,&H48,&H0,&H0,&H0,&H0,&H40,&H90,&H31,&H36,&H38,&H20,&H0,&H0,&H0,&H80,&H80,&H1,&H51,&HB2,&H3C,&H30,&H0,&H0,&H0,&H0,&H1F,&H7F
DATA &H82,&H74,&HE9,&HF2,&HC1,&H3,&H0,&H0,&H7C,&HFC,&H4C,&H98,&HE0,&H87,&HF,&H0,&H0,&H0,&H82,&HFC,&HF9,&H93,&H24,&HC9,&H1F,&H1B,&H0,&H0,&H70,&HF0,&H31,&H26
DATA &H48,&H90,&H31,&H22,&H0,&H0,&H8,&HF2,&HE7,&H4F,&H90,&H31,&H3E,&H38,&H0,&H0,&H0,&HE0,&HCF,&H9F,&H24,&H49,&H82,&H4,&H1,&H0,&H0,&HC0,&H9F,&H3F,&H9,&H12
DATA &H4,&H8,&H0,&H0,&H0,&H7,&H1F,&H63,&H82,&H44,&H99,&H23,&H7,&H0,&H80,&H3F,&H7F,&H10,&H20,&HF8,&HF3,&H7,&H0,&H0,&H0,&H0,&H82,&HFC,&HF9,&H13,&H4,&H0
DATA &H0,&H0,&H0,&H60,&HC0,&H1,&H12,&HE4,&HCF,&H8F,&H0,&H0,&H0,&H4,&HF9,&HF3,&H7,&H1,&H87,&H3B,&H63,&H0,&H0,&H0,&HF0,&HE7,&HF,&H10,&H20,&H40,&H80,&H0
DATA &H0,&HF0,&HE7,&H8F,&H3,&HE,&HE,&HFE,&HFC,&H1,&H0,&HE0,&HCF,&H1F,&H3,&HC,&H30,&HFC,&HF9,&H3,&H0,&H0,&H7,&H1F,&H63,&H82,&H8C,&HF1,&HC1,&H1,&H0,&H80
DATA &H20,&H7F,&HFE,&H24,&H49,&HF0,&HC0,&H0,&H0,&H0,&H1E,&H7E,&H84,&H88,&HF3,&HC7,&HB,&H0,&H0,&H0,&H82,&HFC,&HF9,&H93,&H20,&HC3,&H1F,&H33,&H0,&H0,&H98,&H78
DATA &HD3,&H24,&HCB,&H1C,&H19,&H0,&H0,&H0,&H8,&H10,&HE0,&HCF,&H9F,&H0,&H1,&H0,&H0,&H0,&HF0,&HE7,&HF,&H10,&H20,&H7F,&HFE,&H0,&H0,&H0,&HE0,&HC3,&HF,&H30
DATA &H60,&H7E,&H7C,&H0,&H0,&H0,&HC0,&H9F,&H3F,&H30,&H30,&HC0,&HF8,&HF3,&H7,&H0,&H80,&H21,&H67,&H78,&H60,&HE0,&H71,&H66,&H8,&H0,&H0,&H7,&H9E,&HE0,&HC1,&HF3
DATA &HE4,&H0,&H0,&H0,&H0,&H82,&H84,&H89,&H93,&HA5,&HC9,&H91,&H21,&H0,&H0,&H0,&HF8,&HF3,&H27,&H48,&H10,&H0,&H0,&H0,&H0,&H8,&H30,&HC0,&H0,&H3,&HC,&H30
DATA &HC0,&H0,&H0,&H0,&H20,&H48,&H90,&H3F,&H7F,&H0,&H0,&H0,&H0,&H0,&H1,&H3,&H3,&H3,&HC,&H30,&H40,&H0,&H0,&H0,&H20,&H40,&H80,&H0,&H1,&H2,&H4,&H8
DATA &H10,&H0,&H0,&H0,&H6,&H1C,&H20,&H0,&H0,&H0,&H0,&H0,&H20,&HE8,&H50,&HA1,&HC2,&H3,&HF,&H10,&H0,&H0,&H82,&HFC,&HF9,&H81,&H4,&H9,&H1E,&H18,&H0,&H0
DATA &HE0,&HE0,&H43,&H84,&H8,&H1B,&H14,&H0,&H0,&H0,&H80,&H81,&H7,&H49,&H92,&H1F,&H7F,&H80,&H0,&H0,&H80,&H83,&HF,&H15,&H2A,&H5C,&H30,&H0,&H0,&H0,&H0,&H89
DATA &H9F,&H3F,&H49,&H6,&H8,&H0,&H0,&H0,&H0,&H26,&H5E,&HA4,&H48,&HE1,&HE3,&H43,&H0,&H0,&H80,&H20,&H7F,&HFE,&H20,&H20,&HC0,&H7,&HF,&H0,&H0,&H0,&H88,&HF4
DATA &HE9,&H3,&H4,&H0,&H0,&H0,&H0,&HC0,&H80,&H3,&H4,&HA8,&H5F,&H1F,&H0,&H0,&H0,&H4,&HF9,&HF3,&H7,&H2,&HE,&H36,&H44,&H0,&H0,&H0,&H10,&HE4,&HCF,&H1F
DATA &H20,&H0,&H0,&H0,&H0,&HC0,&H87,&HF,&H6,&H1C,&H1C,&HF8,&HE0,&H1,&H0,&H80,&HF,&H1F,&H2,&H4,&HF8,&HE0,&H1,&H0,&H0,&H0,&HE,&H3E,&H44,&H88,&HF0,&HC1
DATA &H1,&H0,&H0,&H0,&H42,&HFC,&HF0,&H91,&H22,&HC1,&H3,&H3,&H0,&H0,&H18,&H78,&H90,&H20,&H85,&H8F,&H1F,&H21,&H0,&H0,&H88,&HF0,&HC1,&HC3,&H84,&H0,&H7,&HC
DATA &H0,&H0,&H20,&HE1,&H42,&H85,&HA,&H1D,&H12,&H0,&H0,&H0,&H0,&H40,&HC0,&HC7,&H1F,&H22,&H24,&H0,&H0,&H0,&HC0,&H83,&HF,&H10,&H20,&H3C,&HF8,&H0,&H1,&H0
DATA &H80,&H3,&HF,&H30,&H60,&H78,&H70,&H0,&H0,&H0,&H0,&HF,&H3E,&H70,&H70,&HC0,&HE1,&HC3,&H3,&H0,&H0,&H22,&H6C,&H70,&H40,&HC0,&HC1,&H86,&H8,&H0,&H0,&H9C
DATA &H78,&H81,&H2,&HC5,&H8F,&HF,&H0,&H0,&H0,&H98,&H90,&HA1,&HC3,&H85,&H9,&H19,&H0,&H0,&H0,&H20,&H40,&HE0,&HE3,&H4E,&H90,&H20,&H0,&H0,&H0,&H0,&H0,&H0
DATA &HC0,&H9D,&H3B,&H0,&H0,&H0,&H0,&H10,&H24,&HC8,&H1D,&H1F,&H8,&H10,&H0,&H0,&H0,&H40,&HC0,&H80,&H0,&H3,&H4,&HC,&H8,&H0,&H0,&H0,&H1C,&H3C,&H4C,&H8C
DATA &H30,&HC1,&H3,&H7,&H0,&H0,&H7,&H9F,&H22,&HC5,&HDA,&HA7,&H4,&H0,&H0,&H0,

REM $STATIC
SUB About
MouseHide
GET (120, 165)-(520, 335), Back%
LINE (120, 165)-(520, 335), 15, B
LINE (121, 166)-(519, 334), 5, BF
Font "The Ultimate MKJamz Player v2.1", 172, 168, 1, 3, 15
Font "Developed by Molnar \ Kucalaba Productions", 132, 200, 1, 2, 14
Font "in 1996-97", 262, 222, 1, 2, 14
Font "Read the support section for more info,", 142, 250, 1, 1, 15
Font "including where to get the newest and best", 122, 260, 1, 1, 15
Font ".MKJ songs.", 250, 270, 1, 1, 15
Font "Special thanks to Mark K Kim for his disk", 132, 285, 1, 1, 12
Font "scanning routines!", 230, 295, 1, 1, 12
Font "Hit any key to clear this box.", 182, 314, 1, 2, 15
DO
a$ = INKEY$
IF ISPlaying% = -1 THEN CorePlay
LOOP UNTIL a$ <> ""
PUT (120, 165), Back%, PSET
MouseShow
MakeBright -1
END SUB

SUB Alpha (Sort() AS QBSucks)
MaxSort% = VAL(Sort(0).Dat) - 1
DO
  Change% = 1
    FOR x% = 1 TO MaxSort%
      Pnt% = 1
        LOCATE 1, 1
        DO
          Val1% = ASC(MID$(UCASE$(Sort(x%).Dat), Pnt%, 1))
          Val2% = ASC(MID$(UCASE$(Sort(x% + 1).Dat), Pnt%, 1))
          Pnt% = Pnt% + 1
        LOOP UNTIL Val1% <> Val2%
      IF Val1% > Val2% THEN
        SWAP Sort(x%).Dat, Sort(x% + 1).Dat
        Change% = 0
      END IF
  NEXT
 MaxSort% = MaxSort% - 1
LOOP UNTIL Change% = 1
END SUB

FUNCTION AlreadyBright% (Col%)
OUT &H3C7, Col%
R% = INP(&H3C9): R% = INP(&H3C9): R% = INP(&H3C9)
IF R% < 50 THEN AlreadyBright% = 1
END FUNCTION

SUB Center (Row%, text$)
    LOCATE Row%, 41 - LEN(text$) / 2: PRINT text$
END SUB

SUB ClearNotes
FOR Channel% = 1 TO MaxChannel%
        LOCATE 20, Channel% * 7 + 3: PRINT "---"
NEXT
END SUB

SUB ClearVU
 FOR x% = 1 TO MaxChannel%
  LINE ((x% * 56) + 12, 291 - ((Volume% + 1) * 8) + 3)-((x% * 56) + 35, 161), 14, BF
 NEXT
END SUB

DEFSNG A-Z
SUB Clef (a, B)
LINE (a + 3, B + 4)-(a - 1, B + 1), 15
LINE -(a, B - 1), 15: LINE -(a + 7, B - 2), 15: LINE -(a + 9, B + 1), 15
LINE -(a + 6, B + 8), 15: LINE -(a + 1, B + 10), 15: LINE -(a - 6, B + 9), 15
LINE -(a - 7, B + 3), 15: LINE -(a - 6, B - 3), 15: LINE -(a - 3, B - 8), 15
LINE -(a + 5, B - 16), 15: LINE -(a + 4, B - 20), 15: LINE -(a + 1, B - 19), 15
LINE -(a + 2, B - 10), 15: LINE -(a + 4, B - 3), 15: LINE -(a + 3, B + 12), 15
LINE -(a + 1, B + 16), 15: LINE -(a - 2, B + 15), 15: LINE -(a - 1, B + 11), 15
LINE -(a - 3, B + 12), 15
END SUB

SUB CloseChannels
 FOR Channel% = 0 TO 9
  WriteReg &HB0 + Channel%, 0
 NEXT
END SUB

DEFINT A-Z
SUB CorePlay
notex! = notex! + .1

FOR Channel% = 1 TO MaxChannel%

  IF ChannelStat(Channel%).Defined = 0 THEN GOTO NoooGotosPleasee

  RChan% = Channel% - 1

  IF ChannelStat(Channel%).IsDone = 1 THEN
   ChannelStat(Channel%).Pstat = TIMER + ChannelStat(Channel%).Speed
   ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
   ChannelStat(Channel%).IsDone = 0
   ChannelStat(Channel%).ISPlaying = 0
  END IF

   IF ChannelStat(Channel%).ISPlaying = 0 AND Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1) <> 0 THEN
    ChannelStat(Channel%).Pstat = TIMER + ChannelStat(Channel%).Speed
     IF Songbuf(ChannelStat(Channel%).SongPtr + RChan%) <> 0 THEN
     SELECT CASE Songbuf(ChannelStat(Channel%).SongPtr + RChan%)
       CASE 68   ' "D"
         WriteReg &HA0 + RChan%, &H81
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 69   ' "E"
         WriteReg &HA0 + RChan%, &HB0
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 70   ' "F"
         WriteReg &HA0 + RChan%, &HCA
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 71    ' "G"
         WriteReg &HA0 + RChan%, &H2
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
       CASE 65 ' "A"
         WriteReg &HA0 + RChan%, &H41
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
       CASE 66   ' "B"
         WriteReg &HA0 + RChan%, &H87
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
       CASE 67  '  "C"
         WriteReg &HA0 + RChan%, &HAE
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
       CASE 17 ' "C#"
         WriteReg &HA0 + RChan%, &H6B
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 18 ' "D#"
         WriteReg &HA0 + RChan%, &H98
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 20 ' F#"
         WriteReg &HA0 + RChan%, &HE5
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 21 ' "G#"
         WriteReg &HA0 + RChan%, &H20
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
       CASE 15 ' "A#"
         WriteReg &HA0 + RChan%, &H63
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
       CASE 255
         ChannelStat(Channel%).ISPlaying = 2
         ChannelStat(Channel%).Pstat = TIMER + (Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%) / 100) * ChannelStat(Channel%).Speedscale
         ChannelStat(Channel%).Flag = -1
      CASE 254
         ChannelStat(Channel%).Octave = Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%)
         ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
       CASE 253
         ChannelStat(Channel%).Speed = (Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%) / 100) * ChannelStat(Channel%).Speedscale
         ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
       CASE 252
         ChannelStat(Channel%).WaveForm = Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%) - 300
         ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
         IF RChan% > 2 THEN RRChan% = RChan% + 6 ELSE RRChan% = 0
         WriteReg &HE0 + RChan% + RRChan%, ChannelStat(Channel%).WaveForm
       CASE 251
         ChannelStat(1).Flag2 = -1
          FOR MaxChan% = 1 TO MaxChannel%
           ChannelStat(MaxChan%).SongPtr = 1
           ChannelStat(MaxChan%).ISPlaying = 0
           ChannelStat(MaxChan%).IsDone = 0
          NEXT
         CloseChannels
         EXIT SUB
     END SELECT
     END IF
   END IF

    IF ChannelStat(Channel%).ISPlaying > 0 THEN
     IF TIMER >= ChannelStat(Channel%).Pstat THEN
      WriteReg &HB0 + RChan%, 0
      ChannelStat(Channel%).IsDone = 1
       IF ChannelStat(Channel%).Flag = -1 THEN
        ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
        ChannelStat(Channel%).Flag = 0
       END IF
     END IF
    END IF

   IF ChannelStat(Channel%).SongPtr > MaxChannel% + 1 THEN
     IF Songbuf(ChannelStat(Channel%).SongPtr + RChan%) <> 0 AND Songbuf(ChannelStat(Channel%).SongPtr - MaxChannel% + RChan%) < 250 THEN
       IF ChannelStat(Channel%).ISPlaying = 0 THEN ChannelStat(Channel%).ISPlaying = 1
     END IF
   END IF

NoooGotosPleasee:
NEXT Channel%


FOR Channel% = 1 TO MaxChannel%

 IF ChannelStat(Channel%).ISPlaying = 0 THEN
  ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
  IF ChannelStat(Channel%).SongPtr >= UBOUND(Songbuf) / MaxChannel% THEN
   ChannelStat(Channel%).SongPtr = 1
  END IF
 END IF
NEXT Channel%

       

END SUB

DEFSNG A-Z
SUB Dir.FileInfo (File AS FileStruct)
  SHARED dirfileinfo AS FileStruct

  File = dirfileinfo

END SUB

FUNCTION Dir.Find$

  '== SHARED VARIABLES ==
  SHARED dirfileinfo AS FileStruct
  SHARED dircount AS INTEGER
  SHARED dir.attrib AS INTEGER
  SHARED dir.path AS STRING
  SHARED DTAseg AS INTEGER, DTAoff AS INTEGER
  SHARED findfirst$
  SHARED findnext$

  IF dircount = -1 THEN
    pathseg% = VARSEG(dir.path)
    pathoff% = SADD(dir.path)
    asmseg% = VARSEG(findfirst$)
    asmoff% = SADD(findfirst$)
    DEF SEG = asmseg%
    CALL Absolute(dummy%, dummy%, dummy%, dummy%, dummy%, dummy%, pathseg%, pathoff%, &HFF, asmoff%)
    DEF SEG
    dircount = 0
  ELSEIF dircount = 0 THEN pathseg% = 1 'simulate error
  ELSE
    '#iab.compatibility.varseg($)
    pathseg% = VARSEG(dir.path)
    pathoff% = SADD(dir.path)
    asmseg% = VARSEG(findnext$)
    asmoff% = SADD(findnext$)
    DEF SEG = asmseg%
    CALL Absolute(dummy%, dummy%, dummy%, dummy%, dummy%, dummy%, dummy%, pathseg%, pathoff%, asmoff%)
    DEF SEG
  END IF
  'check for errors
  IF pathseg% THEN  'error existance is returned through pathseg%
    Dir.Find$ = ""
    dirfileinfo.attrib = pathoff% 'error code is stored in pathoff%
    dirfileinfo.filedate = "00-00-0000"
    dirfileinfo.filetime = "00:00:00"
  ELSE

    DO
      'get attribute of the file found
      DEF SEG = DTAseg
      attrib% = PEEK(DTAoff + &H15)
      DEF SEG
      'exit conditions:
      IF ((dir.attrib AND &H200) = &H200) AND ((attrib% AND &H21) = (attrib% AND &H3F)) THEN EXIT DO
      IF ((dir.attrib AND &H100) = &H100) AND ((attrib% AND &H3F) = 0) THEN EXIT DO
      IF (dir.attrib AND &H3F) AND (attrib% AND &H3F) THEN EXIT DO
      IF (dir.attrib AND &H3F) = 0 THEN EXIT DO
      'find next until right attributes are found
      '#iab.compatibility.varseg($)
      pathseg% = VARSEG(dir.path)
      pathoff% = SADD(dir.path)
      asmseg% = VARSEG(findnext$)
      asmoff% = SADD(findnext$)
      DEF SEG = asmseg%
      CALL Absolute(dummy%, dummy%, dummy%, dummy%, dummy%, dummy%, dummy%, pathseg%, pathoff%, asmoff%)
      DEF SEG
      IF pathseg% THEN  'error existance is returned through pathseg%
        Dir.Find$ = ""
        dirfileinfo.attrib = pathoff% 'error code is stored in pathoff%
        dirfileinfo.filedate = "00-00-000"
        dirfileinfo.filetime = "00:00:00"
        EXIT FUNCTION
      END IF
    LOOP
   
    'get name of the file found
    FileName$ = SPACE$(13)
    FOR I% = 0 TO 12
      DEF SEG = DTAseg
      ch% = PEEK(DTAoff + &H1E + I%)
      DEF SEG = VARSEG(FileName$)
      POKE SADD(FileName$) + I%, ch%
      DEF SEG
    NEXT I%
    'find location of CHR$(0) and get only up to that point
    Dir.Find$ = LEFT$(FileName$, INSTR(FileName$, CHR$(0)))

    'get attribute of the file found
    DEF SEG = DTAseg
    dirfileinfo.attrib = PEEK(DTAoff + &H15)
    DEF SEG

    'get the file's date
    DEF SEG = DTAseg
    filedate& = (PEEK(DTAoff + &H19) AND &H7F) * &H100 + PEEK(DTAoff + &H18)
     IF (PEEK(DTAoff + &H19) AND &H80) THEN filedate& = filedate& OR &H8000
    fileyear$ = LTRIM$(STR$((filedate& AND &HFE00) / &H200 + 1980))
    filemonth$ = LTRIM$(STR$((filedate& AND &H1E0) / &H20))
     IF LEN(filemonth$) < 2 THEN filemonth$ = "0" + filemonth$  'align
    fileday$ = LTRIM$(STR$(filedate& AND &H1F))
     IF LEN(fileday$) < 2 THEN fileday$ = "0" + fileday$        'align
    DEF SEG
    dirfileinfo.filedate$ = filemonth$ + "-" + fileday$ + "-" + fileyear$

    'get the file's time
    DEF SEG = DTAseg
    filetime& = (PEEK(DTAoff + &H17) AND &H7F) * &H100 + PEEK(DTAoff + &H16)
     IF (PEEK(DTAoff + &H17) AND &H80) THEN filetime& = filetime& OR &H8000
    filehour& = (filetime& AND &H7800) / &H800
     IF (filetime& AND &H8000) THEN filehour& = filehour& OR &H10
    filehour$ = LTRIM$(STR$(filehour&))
     IF LEN(filehour$) < 2 THEN filehour$ = "0" + filehour$     'align
    filemin$ = LTRIM$(STR$((filetime& AND &H7E0) / &H20))
     IF LEN(filemin$) < 2 THEN filemin$ = "0" + filemin$        'align
    filesec$ = LTRIM$(STR$((filetime& AND &H1F) * 2))
     IF LEN(filesec$) < 2 THEN filesec$ = "0" + filesec$        'align
    DEF SEG
    dirfileinfo.filetime$ = filehour$ + ":" + filemin$ + ":" + filesec$

    DEF SEG = DTAseg
    filesize& = (PEEK(DTAoff + &H1D) AND &H7F) * &H1000000
    filesize& = filesize& + PEEK(DTAoff + &H1C) * &H10000
    filesize& = filesize& + PEEK(DTAoff + &H1B) * &H100&
    filesize& = filesize& + PEEK(DTAoff + &H1A) * &H1
    IF (PEEK(DTAoff + &H1D) AND &H80) THEN filesize& = filesize& OR &H8000
    dirfileinfo.filesize = filesize&
    DEF SEG
  END IF

  dircount = dircount + 1
END FUNCTION

SUB Dir.Init (path.o$, attrib.o%)

  '== SHARED VARIABLES ==
  'general
  SHARED dirfileinfo AS FileStruct
  SHARED dircount AS INTEGER
  'control variables
  SHARED dir.attrib AS INTEGER
  SHARED dir.path AS STRING
  'machine language routines
  SHARED DTAseg AS INTEGER, DTAoff AS INTEGER
  SHARED findfirst$
  SHARED findnext$

  '== INITIALIZATION ==
  dircount = -1
  dir.attrib = attrib.o%
  dir.path = path.o$ + CHR$(0)

  '== get DTA address ==
  'initialize machine language code to get DTA address
  asm$ = ""
  asm$ = asm$ + CHR$(&H55)                           'push bp          DTA
  asm$ = asm$ + CHR$(&H89) + CHR$(&HE5)              'mov bp, sp       DTA
  asm$ = asm$ + CHR$(&HB4) + CHR$(&H2F)              'mov ah, 2f       DTA
  asm$ = asm$ + CHR$(&HCD) + CHR$(&H21)              'int 21           DTA
  asm$ = asm$ + CHR$(&H89) + CHR$(&HD8)              'mov ax, bx       DTA
  asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H8)  'mov bx, [bp+08]  DTA
  asm$ = asm$ + CHR$(&H8C) + CHR$(&H7)               'mov [bx], es     DTA
  asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H6)  'mov bx, [bp+06]  DTA
  asm$ = asm$ + CHR$(&H89) + CHR$(&H7)               'mov [bx], ax     DTA
  asm$ = asm$ + CHR$(&H5D)                           'pop bp           DTA
  asm$ = asm$ + CHR$(&HCA) + CHR$(&H12) + CHR$(&H0)  'retf 0012        DTA
  'get segment and offsets
  asmseg% = VARSEG(asm$)
  asmoff% = SADD(asm$)
  'execute
  DEF SEG = asmseg%
  CALL Absolute(dummy%, dummy%, dummy%, dummy%, dummy%, dummy%, dummy%, DTAseg, DTAoff, asmoff%)
  DEF SEG

  '== FIND FIRST ==
  'initialize machine language code
  findfirst$ = ""
  findfirst$ = findfirst$ + CHR$(&H55)                           'push bp          F1st
  findfirst$ = findfirst$ + CHR$(&H89) + CHR$(&HE5)              'mov bp, sp       F1st
  findfirst$ = findfirst$ + CHR$(&HB4) + CHR$(&H4E)              'mov ah, 4e       F1st
  findfirst$ = findfirst$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&HA)  'mov bx, [bp+0a]  F1st
  findfirst$ = findfirst$ + CHR$(&H8E) + CHR$(&H1F)              'mov ds, [bx]     F1st
  findfirst$ = findfirst$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H8)  'mov bx, [bp+08]  F1st
  findfirst$ = findfirst$ + CHR$(&H8B) + CHR$(&H17)              'mov dx, [bx]     F1st
  findfirst$ = findfirst$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H6)  'mov bx, [bp+06]  F1st
  findfirst$ = findfirst$ + CHR$(&H8B) + CHR$(&HF)               'mov cx, [bx]     F1st
  findfirst$ = findfirst$ + CHR$(&HCD) + CHR$(&H21)              'int 21           F1st
  findfirst$ = findfirst$ + CHR$(&HB9) + CHR$(&H0) + CHR$(&H0)   'mov cx, 0000     F1st
  findfirst$ = findfirst$ + CHR$(&H80) + CHR$(&HD1) + CHR$(&H0)  'adc cl, 00       F1st
  findfirst$ = findfirst$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&HA)  'mov bx, [bp+0a]  F1st
  findfirst$ = findfirst$ + CHR$(&H89) + CHR$(&HF)               'mov [bx], cx     F1st
  findfirst$ = findfirst$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H8)  'mov bx, [bp+08]  F1st
  findfirst$ = findfirst$ + CHR$(&H89) + CHR$(&H7)               'mov [bx], ax     F1st
  findfirst$ = findfirst$ + CHR$(&H5D)                           'pop bp           F1st
  findfirst$ = findfirst$ + CHR$(&HCA) + CHR$(&H12) + CHR$(&H0)  'retf 0012        F1st

  '== FIND NEXT ==
  'initialize machine language code
  findnext$ = ""
  findnext$ = findnext$ + CHR$(&H55)                           'push bp          FNxt
  findnext$ = findnext$ + CHR$(&H89) + CHR$(&HE5)              'mov bp, sp       FNxt
  findnext$ = findnext$ + CHR$(&HB4) + CHR$(&H4F)              'mov ah, 4f       FNxt
  findnext$ = findnext$ + CHR$(&HCD) + CHR$(&H21)              'int 21           FNxt
  findnext$ = findnext$ + CHR$(&HB9) + CHR$(&H0) + CHR$(&H0)   'mov cx, 0000     FNxt
  findnext$ = findnext$ + CHR$(&H80) + CHR$(&HD1) + CHR$(&H0)  'adc cl, 00       FNxt
  findnext$ = findnext$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H8)  'mov bx, [bp+08]  FNxt
  findnext$ = findnext$ + CHR$(&H89) + CHR$(&HF)               'mov [bx], cx     FNxt
  findnext$ = findnext$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H6)  'mov bx, [bp+06]  FNxt
  findnext$ = findnext$ + CHR$(&H89) + CHR$(&H7)               'mov [bx], ax     FNxt
  findnext$ = findnext$ + CHR$(&H5D)                           'pop bp           FNxt
  findnext$ = findnext$ + CHR$(&HCA) + CHR$(&H12) + CHR$(&H0)  'retf 0012        FNxt

END SUB

DEFINT A-Z
SUB DoTheVUThing
 FOR El% = 1 TO MaxChannel%
    LINE ((El% * 56) + 12, 291 - Bars(El%).L)-((El% * 56) + 35, 291 - Bars(El%).L), 14
      IF Bars(El%).L = 130 AND Bars(El%).De = 0 THEN
        Bars(El%).L = ((Volume% + 1) * 8) + 3
        LINE ((El% * 56) + 12, 294 - Bars(El%).L)-((El% * 56) + 35, 291), 10, BF
        DecayStep! = ChannelStat(El%).Speed / 25
        Bars(El%).Decay = TIMER + DecayStep!
        Bars(El%).De = 1
      END IF
      IF Bars(El%).De <> 0 THEN
        IF TIMER >= Bars(El%).Decay THEN
          Bars(El%).L = Bars(El%).L - 1
          IF Bars(El%).L = 0 THEN Bars(El%).De = 0
          Bars(El%).Decay = Bars(El%).Decay + DecayStep!
        END IF
      END IF
  NEXT
END SUB

SUB DragTheBar
Cval% = 335 + Volume% * 5
MouseHide
DO
  MouseStatus lb%, rb%, x%, y%
 
  IF (y% > Cval% + 3 AND y% < 415) THEN
   IF Volume% < 15 THEN Volume% = Volume% + 1: CD% = 1
  ELSEIF (y% < Cval% - 3 AND y% > 335) THEN
   IF Volume% > 0 THEN Volume% = Volume% - 1: CD% = 1: ClearVU
  END IF
  IF CD% = 1 THEN
   FMVolume Volume%
   ShowFace Volume%
   PlaceBar Volume%
   Cval% = 335 + Volume% * 5
   CD% = 0
  END IF
 IF ISPlaying% = -1 THEN PlayMusicB
 DoTheVUThing
LOOP UNTIL lb% <> -1
MouseShow
END SUB

SUB DrawEverything

FOR x% = 1 TO 4
 FSet x%, 35, 0, 35
NEXT

FSet 8, 0, 0, 0
FSet 6, 55, 0, 0
FSet 0, 0, 0, 29
FSet 5, 0, 0, 20
FSet 14, 45, 0, 0
FSet 12, 55, 55, 0
FSet 11, 33, 33, 33
FSet 13, 0, 0, 28

'------- Play, Stop, Fast Forward, Etc ----------
LINE (0, 445)-(639, 479), 15, B
PAINT (1, 451), 5, 15
Font "The Ultimate", 10, 443, 2, 4, 13
Font "MKJamz Player", 406, 443, 2, 4, 13
LINE (0, 445)-(639, 479), 15, B
LINE (240, 450)-(280, 475), 15, B
LINE (280, 450)-(320, 475), 15, B
LINE (320, 450)-(360, 475), 15, B
LINE (360, 450)-(400, 475), 15, B

LINE (250, 456)-(270, 469), 6, BF

LINE (375, 457)-(375, 467), 6
LINE -(380, 462), 6
LINE -(375, 457), 6
PAINT (376, 460), 6, 6
LINE (386, 457)-(386, 467), 6
LINE -(391, 462), 6
LINE -(386, 457), 6
PAINT (387, 460), 6, 6

LINE (346, 457)-(346, 467), 6
LINE -(341, 462), 6
LINE -(346, 457), 6
PAINT (345, 460), 6, 6

LINE (335, 457)-(335, 467), 6
LINE -(330, 462), 6
LINE -(335, 457), 6
PAINT (334, 460), 6, 6

LINE (292, 454)-(292, 470), 6
LINE -(307, 463), 6
LINE -(292, 454), 6
PAINT (293, 460), 6, 6


'------- Play, Stop, Fast Forward, Etc ----------

'---- Font pretty stuff ----
LINE (0, 0)-(0, 24), 15
LINE (0, 0)-(639, 24), 15, B
PAINT (2, 15), 5, 15
Font "FILE", 30, 0, 1, 3, 15
LINE (100, 0)-(100, 24), 15
Font "DISPLAY", 120, 0, 1, 3, 15
LINE (200, 0)-(200, 24), 15
LINE (300, 0)-(300, 24), 15
Font "HELP", 230, 0, 1, 3, 15
END SUB

DEFSNG A-Z
SUB DrawNote (note$, channe%, length, position)

MouseHide
noteonstaff = -(ASC(note$) - 65) * 3

nclr = 15
y = channe% * 40 + 26
y = y + noteonstaff
CIRCLE (notex!, y), 4, nclr, , , .4
 IF length > 2 THEN
  LINE (notex! - 3, y - 2)-(notex! + 2, y + 2), nclr, BF
 END IF

IF length > 1 THEN
 IF ASC(note$) < 67 THEN
  LINE (notex! + 4, y)-(notex! + 4, y - 16), nclr
   IF length > 7 THEN
    LINE -(notex! + 6, y - 10), nclr
    LINE -(notex! + 10, y - 7), nclr
    LINE -(notex! + 8, y - 5), nclr
     IF length > 15 THEN
      LINE (notex! + 4, y - 16)-(notex! + 5, y - 9), nclr
      LINE -(notex! + 10, y - 5), nclr
      LINE -(notex! + 8, y - 3), nclr
     END IF
      IF length > 31 THEN
       LINE (notex! + 5, y - 14)-(notex! + 10, y - 8), nclr
      END IF
   END IF

  ELSE
  LINE (notex! - 4, y)-(notex! - 4, y + 16), nclr
  IF length > 7 THEN
   LINE -(notex!, y + 11), nclr
   LINE -(notex! + 5, y + 7), nclr
    IF length > 15 THEN
     LINE (notex! - 4, y + 13)-(notex!, y + 9), nclr
     LINE -(notex! + 5, y + 5), nclr
      IF length > 31 THEN
       LINE (notex! - 4, y + 11)-(notex! + 5, y + 3), nclr
      END IF
    END IF
  END IF
 END IF
END IF

IF RIGHT$(note$, 1) = "#" THEN
 LINE (notex! - 7, y - 7)-(notex! - 10, y - 2), nclr
 LINE (notex! - 3, y - 7)-(notex! - 7, y - 1), nclr
 LINE (notex! - 10, y - 6)-(notex! - 2, y - 5), nclr
 LINE (notex! - 11, y - 4)-(notex! - 3, y - 3), nclr
END IF
MouseShow
END SUB

DEFINT A-Z
SUB DrawVU
MouseHide
   FOR x% = 1 TO 10
    IF x% <= MaxChannel% THEN C% = 14 ELSE C% = 11
    LINE ((x% * 56) + 10, 293)-((x% * 56) + 37, 159), 15, B
    LINE ((x% * 56) + 11, 292)-((x% * 56) + 36, 160), 8, B
    LINE ((x% * 56) + 12, 291)-((x% * 56) + 35, 161), C%, BF

    LINE ((x% * 56) + 7, 303)-((x% * 56) + 41, 321), 15, B
    LINE ((x% * 56) + 5, 302)-((x% * 56) + 42, 322), 8, B
    LINE ((x% * 56) + 4, 301)-((x% * 56) + 43, 323), 15, B


    LINE ((x% * 56) + 10, 115)-((x% * 56) + 37, 140), 15, B
    LINE ((x% * 56) + 11, 116)-((x% * 56) + 36, 139), 5, BF

    LINE ((x% * 56) + 10, 100)-((x% * 56) + 37, 75), 15, B
    LINE ((x% * 56) + 11, 99)-((x% * 56) + 36, 76), 5, BF

    IF x% <= MaxChannel% THEN C% = 14 ELSE C% = 11
     CIRCLE ((x% * 56) + 23, 87), 9, C%
     CIRCLE ((x% * 56) + 23, 127), 9, C%
     PAINT ((x% * 56) + 23, 127), C%, C%
     PAINT ((x% * 56) + 23, 87), C%, C%
    NEXT
MouseShow
END SUB

SUB FillMute (Channel%, Booyah%)
MouseHide
cx% = 87
IF Booyah% > 14 THEN Booyah% = Booyah% - 10: cx% = 127
CIRCLE ((Channel% * 56) + 23, cx%), 9, Booyah%
PAINT ((Channel% * 56) + 23, cx%), Booyah%, Booyah%
MouseShow
END SUB

DEFSNG A-Z
FUNCTION FindCard%
CALL WriteReg(&H4, &H60)
CALL WriteReg(&H4, &H80)
B = INP(BasePort% + 8)
CALL WriteReg(&H2, &HFF)
CALL WriteReg(&H4, &H21)
FOR x = 0 TO 130
   a = INP(BasePort% + 8)
NEXT x
C = INP(BasePort% + 8)
CALL WriteReg(&H4, &H60)
CALL WriteReg(&H4, &H80)
Success = 0
IF (B AND &HE0) = &H0 THEN
   IF (C AND &HE0) = &HC0 THEN
      FindCard% = 1
   END IF
END IF
END FUNCTION

FUNCTION Fixed$ (FileName$)
FileName$ = RIGHT$(FileName$, 12)
 p% = INSTR(FileName$, "\")
 IF p% <> 0 THEN
  FileName$ = RIGHT$(FileName$, LEN(FileName$) - p%)
 END IF
Fixed$ = UCASE$(FileName$)
END FUNCTION

SUB FMVolume (Right%)
OUT BasePort% + 4, &H26
OUT BasePort% + 5, (Right% + Right% * 16) AND &HFF
END SUB

SUB Font (text$, XStart%, ystart%, xscale%, YScale%, Clr%)

px% = XStart%  ' physical x and physical y
py% = ystart%

LHeight% = YScale% * 8
Optimize% = 63 \ LHeight% ' Any constant math operations done multipe times
                          ' in the main loop should, well, not be done
                          ' in the main loop.


' Instead of wasting our time with all this MID$ garbage to access bytes in
' font buffer, we'll just take a PEEK directly at them.
DEF SEG = VARSEG(FontBuf(0))

 FOR h% = 1 TO LEN(text$)
  FPtr% = 81 * (ASC(MID$(text$, h%, 1)) - 1) - 1
  FOR x% = 0 TO 8
   FOR y% = 0 TO 8

    Col% = PEEK(VARPTR(FontBuf(0)) + FPtr%)
    FPtr% = FPtr% + 1
    IF Col% THEN
            IF YScale% = 1 THEN
              PSET (px%, py%), Clr%
            ELSE
             FOR sx% = px% TO px% + xscale%
              FOR sy% = py% TO py% + YScale%
               PSET (sx%, sy%), Clr%
              NEXT
             NEXT
            END IF
    END IF
    py% = py% + YScale%
   NEXT
  px% = px% + xscale%
  py% = ystart%
  NEXT
 NEXT h%
DEF SEG
END SUB

DEFINT A-Z
SUB FSet (Att%, R%, G%, B%)
OUT &H3C8, Att%
OUT &H3C9, R%
OUT &H3C9, G%
OUT &H3C9, B%
END SUB

DEFSNG A-Z
FUNCTION GetDir$ (Drive%)

  Drive% = Drive% + 1
  'initialize assembly code
  asm$ = ""
  asm$ = asm$ + CHR$(&H55)                                  'push bp
  asm$ = asm$ + CHR$(&H89) + CHR$(&HE5)                     'mov bp, sp
  asm$ = asm$ + CHR$(&HB4) + CHR$(&H47)                     'mov ah, 47h
  asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&HA)         'mov bx, [bp+0ah]
  asm$ = asm$ + CHR$(&H8B) + CHR$(&H17)                     'mov dx, [bx]
  asm$ = asm$ + CHR$(&H1E)                                  'push ds
  asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H8)         'mov bx, [bp+08h]
  asm$ = asm$ + CHR$(&H8E) + CHR$(&H1F)                     'mov ds, [bx]
  asm$ = asm$ + CHR$(&H56)                                  'push si
  asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H6)         'mov bx, [bp+06h]
  asm$ = asm$ + CHR$(&H8B) + CHR$(&H37)                     'mov si, [bx]
  asm$ = asm$ + CHR$(&HCD) + CHR$(&H21)                     'int 21h
  asm$ = asm$ + CHR$(&H5E)                                  'pop si
  asm$ = asm$ + CHR$(&H1F)                                  'pop ds
  asm$ = asm$ + CHR$(&HBA) + CHR$(&H0) + CHR$(&H0)          'mov dx, 0000h
  asm$ = asm$ + CHR$(&H80) + CHR$(&HD2) + CHR$(&H0)         'adc dl, 00h
  asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&HA)         'mov bx, [bp+0a]
  asm$ = asm$ + CHR$(&H89) + CHR$(&H17)                     'mov [bx], dx
  asm$ = asm$ + CHR$(&H5D)                                  'pop  bp
  asm$ = asm$ + CHR$(&HCA) + CHR$(&H12) + CHR$(&H0)         'retf 0012h

  'string to store directory information
  directory$ = SPACE$(65)
  dirseg% = VARSEG(directory$)  'get segment address
  diroff% = SADD(directory$)    'get offset address

  'execute
  DEF SEG = VARSEG(asm$)
  CALL Absolute(dummy%, dummy%, dummy%, dummy%, dummy%, dummy%, Drive%, dirseg%, diroff%, SADD(asm$))
  directory$ = LEFT$(directory$, INSTR(directory$, CHR$(0)))
  IF LEFT$(directory$, 1) <> "\" THEN directory$ = "\" + directory$

  IF Drive% THEN directory$ = ""

  GetDir$ = directory$

END FUNCTION

FUNCTION GetDrv%

  'initialize assembly code
  asm$ = ""
  asm$ = asm$ + CHR$(&H55)                                  'push bp
  asm$ = asm$ + CHR$(&H89) + CHR$(&HE5)                     'mov bp, sp
  asm$ = asm$ + CHR$(&HB4) + CHR$(&H19)                     'mov ah, 19h
  asm$ = asm$ + CHR$(&HCD) + CHR$(&H21)                     'int 21h
  asm$ = asm$ + CHR$(&HB4) + CHR$(&H0)                      'mov ah, 00h
  asm$ = asm$ + CHR$(&H8B) + CHR$(&H5E) + CHR$(&H6)         'mov bx, [bp+06h]
  asm$ = asm$ + CHR$(&H89) + CHR$(&H7)                      'mov [bx], ax
  asm$ = asm$ + CHR$(&H5D)                                  'pop bp
  asm$ = asm$ + CHR$(&HCA) + CHR$(&H12) + CHR$(&H0)         'retf 0012h

  'execute
  DEF SEG = VARSEG(asm$)
  CALL Absolute(dummy%, dummy%, dummy%, dummy%, dummy%, dummy%, dummy%, dummy%, Drive%, SADD(asm$))

  GetDrv% = Drive%

END FUNCTION

DEFINT A-Z
FUNCTION GetFile (PostFix$)
ISPlaying% = 0: FileName$ = ""
ResetSong
MakeBright -1
FileName$ = OpenFile$(PostFix$)


IF FileName$ <> "" THEN
 Done% = 1
 TimeBuf! = TIMER
 IF Done% = 1 THEN
        IF PostFix$ = "MKJ" THEN
                RetVal% = LoadJamFile%(FileName$)
                IF RetVal% < 1 THEN
                        IF FileName$ <> "theyhitescape" THEN BEEP
                        CLOSE
                ELSE
                        FileName$ = Fixed(FileName$)
                        GetFile% = RetVal%
                END IF
        ELSEIF PostFix$ = "INS" THEN
               IF FileName$ = "theyhitescape" THEN
                       GetFile% = -1
               ELSE
                       FileName$ = Fixed(FileName$)
                       LoadIns FileName$
               END IF
        END IF
 END IF
END IF

ResetSong

IF DisType% = 1 THEN
 ShowStaff 1
 notex% = 50
ELSE
VuSetUp
END IF
END FUNCTION

SUB GetPress
DO: AA$ = INKEY$: LOOP WHILE AA$ = ""
END SUB

SUB Help
MouseHide
LINE (0, 26)-(639, 444), 0, BF
COLOR 15
Center 3, "THe Ultimate MKJamz Player v2.1 Help"
Center 5, "This will provide you with the basic directions.  For more help,"
Center 6, "read the ULTMKJ.TXT file that came with this, and if all else fails email us."
Center 8, "THE PULL MENUS"
Center 10, "The pull down menus allow you to do various things quickly and easily.  To"
Center 11, "open a .MKJ file, select File...Open and select a file.  For a DOS"
Center 12, "Shell, select File...DOS Shell.  For the file attributes (after you have opened"
Center 13, "a MKJ file) click File...Info.  To exit, click File....Exit."
Center 15, "THE PLAY-BOX"
Center 17, "Once you've opened a file, it will *not* automatically play.  You need to click"
Center 18, "on the play icon that is located on the bottom of your screen right now.  There"
Center 19, "are currently 3 other functions there : Stop (reset the song), and Increase or "
Center 20, "Decrease the playing speed of the song."
Center 22, "THE OTHER FEATURES"
Center 24, "There are currently two different graphical interfaces for playing a MKJ file."
Center 25, "The default is displaying the notes on a staff, and the other is real-time VU"
Center 26, "meters.  The VU meters give you an option of muting or soloing the channels."
Center 27, "You can change the interface with the Display... pull down menu."
MouseShow
DO
a$ = INKEY$
IF ISPlaying% = -1 THEN CorePlay
LOOP UNTIL a$ <> ""
END SUB

FUNCTION IsGreen% (Channel%)
IF POINT((Channel% * 56) + 23, 87) <> 10 THEN IsGreen% = 1
END FUNCTION

FUNCTION IsSolo% (Channel%)
IF POINT((Channel% * 56) + 23, 127) = 12 THEN IsSolo% = 1 ELSE IsSolo% = 0
END FUNCTION

FUNCTION ItsNotAnyWhere%
IF x% < 200 OR x% > 300 OR y% > 83 THEN ItsNotAnyWhere% = 1
END FUNCTION

FUNCTION ItsNotWhere%
IF x% < 100 OR x% > 200 OR y% > 75 THEN ItsNotWhere% = 1
END FUNCTION

FUNCTION ItsNowhere%
IF x% > 100 OR y% > 95 THEN ItsNowhere% = 1
END FUNCTION

FUNCTION ItsOverAbout%
IF x% > 200 AND x% < 300 THEN
 IF y% > 62 AND y% < 79 THEN ItsOverAbout% = 1
END IF
END FUNCTION

FUNCTION ItsOverCont%
IF x% > 200 AND x% < 300 THEN
 IF y% > 27 AND y% < 43 THEN ItsOverCont% = 1
END IF
END FUNCTION

FUNCTION ItsOverDOSShell%
IF x% > 4 AND x% < 100 THEN
 IF y% > 44 AND y% < 60 THEN ItsOverDOSShell% = 1
END IF
END FUNCTION

FUNCTION ItsOverExit%
IF x% > 4 AND x% < 100 THEN
 IF y% > 79 AND y% < 94 THEN ItsOverExit% = 1
END IF
END FUNCTION

FUNCTION ItsOverInfo%
IF x% > 4 AND x% < 100 THEN
 IF y% > 61 AND y% < 78 THEN ItsOverInfo% = 1
END IF
END FUNCTION

FUNCTION ItsOverNotes%
IF x% > 100 AND x% < 200 THEN
 IF y% > 27 AND y% < 43 THEN ItsOverNotes% = 1
END IF
END FUNCTION

FUNCTION ItsOverOpen%
IF x% > 4 AND x% < 100 THEN
 IF y% > 27 AND y% < 43 THEN ItsOverOpen% = 1
END IF
END FUNCTION

FUNCTION ItsOverSupport%
IF x% > 200 AND x% < 300 THEN
 IF y% > 44 AND y% < 61 THEN ItsOverSupport% = 1
END IF
END FUNCTION

FUNCTION ItsOverVU
IF x% > 100 AND x% < 200 THEN
 IF y% > 44 AND y% < 60 THEN ItsOverVU% = 1
END IF
END FUNCTION

SUB LoadFont
RESTORE FontData
FOR x% = 1 TO 10368 STEP 8
 READ ByteMap%
 IF (ByteMap% AND 1) / 1 THEN MID$(FontBuf(0), x%) = CHR$(16)
 IF (ByteMap% AND 2) / 2 THEN MID$(FontBuf(0), x% + 1) = CHR$(16)
 IF (ByteMap% AND 4) / 4 THEN MID$(FontBuf(0), x% + 2) = CHR$(16)
 IF (ByteMap% AND 8) / 8 THEN MID$(FontBuf(0), x% + 3) = CHR$(16)
 IF (ByteMap% AND 16) / 16 THEN MID$(FontBuf(0), x% + 4) = CHR$(16)
 IF (ByteMap% AND 32) / 32 THEN MID$(FontBuf(0), x% + 5) = CHR$(16)
 IF (ByteMap% AND 64) / 64 THEN MID$(FontBuf(0), x% + 6) = CHR$(16)
 IF (ByteMap% AND 128) / 128 THEN MID$(FontBuf(0), x% + 7) = CHR$(16)
NEXT
END SUB

DEFSNG A-Z
SUB LoadIns (FileName$)
OPEN FileName$ FOR BINARY AS #1
 IF LOF(1) < 2 THEN
  BEEP
  CLOSE
  KILL FileName$
  EXIT SUB
 END IF
 GET #1, , CurrentIns
CLOSE #1
END SUB

FUNCTION LoadJamFile% (File$)

OPEN File$ FOR BINARY AS #1

 IF LOF(1) < 2 THEN
  CLOSE #1
  KILL File$
  LoadJamFile% = -1
  EXIT FUNCTION
 END IF

 IF INPUT$(6, #1) <> "MKJamz" THEN
   LoadJamFile% = -2
   EXIT FUNCTION
 END IF

 GET #1, , Ver!
 IF Ver! > 1.11 THEN
  LoadJamFile% = -3
  EXIT FUNCTION
 END IF

 GET #1, , MaxChannel%

  SBInit

  FOR x% = 1 TO MaxChannel%
    GET #1, , CurrentIns
    Save% = x%
    SetIns x%
    x% = Save%
   NEXT

 GET #1, , MaxNotes%

  ERASE Songbuf, ChannelStat
  REDIM Songbuf(1 TO (MaxChannel% + 1) * MaxNotes%) AS INTEGER
  REDIM ChannelStat(1 TO MaxChannel%) AS ChannelType

  FOR x% = 1 TO MaxChannel%
    GET #1, , ChannelStat(x%).Defined
    ChannelStat(x%).SongPtr = 1
    ChannelStat(x%).Octave = 4
    ChannelStat(x%).Speedscale = 1
  NEXT

'FOR X% = 1 TO UBOUND(SongBuf)
'  GET #1, , SongBuf(X%)
'NEXT
 
  RemBytes& = LOF(1) - SEEK(1)  ' The size, in bytes (not ints) of song data

  BufferSize% = 2000           ' The buffer size to use.

 ' DEF SEG = VARSEG(SongBuf(1))
'  Ptr& = VARPTR(SongBuf(1))

  LeftBytes& = RemBytes& MOD BufferSize% ' The amount of left over bytes

  IF (LeftBytes& < RemBytes&) THEN
    FOR QuickLoad% = 1 TO (RemBytes& - LeftBytes&) / BufferSize%
       Buffer$ = INPUT$(BufferSize%, #1) ' Load all the data into buffer
         FOR x% = 1 TO LEN(Buffer$)
            DEF SEG = VARSEG(Songbuf(1))
            POKE VARPTR(Songbuf(1)) + Ptr&, ASC(MID$(Buffer$, x%, 1))
            Ptr& = Ptr& + 1
         NEXT
       RemBytes& = RemBytes& - BufferSize%
    NEXT
  END IF

  IF (LeftBytes& > 0) THEN
    Buffer$ = INPUT$(LeftBytes&, #1)
     FOR x% = 1 TO LEN(Buffer$)
        DEF SEG = VARSEG(Songbuf(1))
        POKE VARPTR(Songbuf(1)) + Ptr&, ASC(MID$(Buffer$, x%, 1))
        Ptr& = Ptr& + 1
     NEXT
   END IF

  DEF SEG

CLOSE #1

LoadJamFile% = Ver! * 100

END FUNCTION

DEFINT A-Z
SUB MakeBright (Col%)
FOR x% = 1 TO 4
 FSet x%, 35, 0, 35
NEXT
FSet Col%, 58, 0, 58
Choice% = Col%
END SUB

DEFLNG A-Z
SUB MouseDriver (ax%, bx%, cx%, dx%)
  DEF SEG = VARSEG(Mouse$)
  Mouse% = SADD(Mouse$)
  CALL Absolute(ax%, bx%, cx%, dx%, Mouse%)
END SUB

SUB MouseHide
 ax% = 2
 MouseDriver ax%, 0, 0, 0
END SUB

FUNCTION MouseInit%
  ax% = 0
  MouseDriver ax%, 0, 0, 0
  MouseInit% = ax%
END FUNCTION

SUB MousePut (x%, y%)
  ax% = 4
  cx% = x%
  dx% = y%
  MouseDriver ax%, 0, cx%, dx%
END SUB

SUB MouseRange (X1%, Y1%, x2%, Y2%)
  ax% = 7
  cx% = X1%
  dx% = x2%
MouseDriver ax%, 0, cx%, dx%
  ax% = 8
  cx% = Y1%
  dx% = Y2%
  MouseDriver ax%, 0, cx%, dx%
END SUB

SUB MouseShow
  ax% = 1
  MouseDriver ax%, 0, 0, 0
END SUB

SUB MouseStatus (lb%, rb%, xMouse%, yMouse%)
  ax% = 3
  MouseDriver ax%, bx%, cx%, dx%
  lb% = ((bx% AND 1) <> 0)
  rb% = ((bx% AND 2) <> 0)
  xMouse% = cx%
  yMouse% = dx%
END SUB

DEFINT A-Z
SUB OFDraw

  ' Display all file names and boxes and bull crap like that

MouseHide
LINE (58, 88)-(582, 372), 15, B
LINE (59, 89)-(581, 371), 0, BF ' whole box
LINE (60, 90)-(580, 370), 15, B ' whole box


IF PostFix$ = "MKJ" THEN
         LOCATE 7, 29: PRINT "Open a MKJamz Song (*.MKJ)"
ELSE
         LOCATE 7, 24: PRINT "Open a MKJamz Instrument (*.INS)"
END IF

LOCATE 11, 30: PRINT "Files                        Directories"
LINE (90, 190)-(435, 338), 15, B ' file box
LINE (88, 188)-(437, 340), 15, B
OFText 2


CD$ = LTRIM$(RTRIM$(OF.CurDir))
COLOR 12
Center 9, CD$
COLOR 15
'LOCATE 9, 12: PRINT Of.CurDir;

LOCATE 13, 71: PRINT ""
LOCATE 21, 71: PRINT ""
LINE (558, 190)-(570, 338), 15, B ' dir arrow box


LOCATE 23, 12: PRINT "-                                       -"
LINE (88, 350)-(437, 365), 15, B ' arrow box

  OFText 1
  MouseShow

END SUB

SUB OFInit

OF.DirSpot = 1
OF.FileSpot = 1

  FOR x% = 1 TO 150
   File(x%).Dat = ""
   DirList(x%).Dat = ""
  NEXT

  ' Store the current drive and path
  Option$ = UCASE$(OF.Opt)
  CD% = GetDrv: swp% = CD%: path$ = GetDir$(swp%)
  Total$ = CHR$(CD% + 65) + ":" + path$
  OF.CurDir = Total$
 
  ' Init the dir scan
  Total$ = LEFT$(Total$, LEN(Total$) - 1)
  IF RIGHT$(Total$, 1) <> "\" THEN Total$ = Total$ + "\"
  Dir$ = Total$ + "*.*"
  Dir.Init Dir$, F.NOR
  DIM info AS FileStruct

  ' Store all matching files into the File() buffer,
  F% = 1: Dir% = 1
  DO
    FileName$ = Dir.Find$
    Dir.FileInfo info
     IF FileName$ <> "" THEN

      IF info.attrib AND F.ARC THEN
         FileName$ = LEFT$(FileName$, LEN(FileName$) - 1)
         IF RIGHT$(FileName$, 3) = OF.Opt OR OF.Opt = "   " THEN
          File(F%).Dat = FileName$
          F% = F% + 1
         END IF
      END IF
      IF info.attrib AND F.DIR THEN
         DirList(Dir%).Dat = FileName$
         Dir% = Dir% + 1
      END IF
     ELSE
      EXIT DO
     END IF
  LOOP
  OF.MaxDSpot = Dir%
  OF.MaxFSpot = F% / 9 + 1
  OF.NumFiles = F%
  File(0).Dat = STR$(F% - 1)
  DirList(0).Dat = STR$(Dir% - 1)
  Alpha File()
  Alpha DirList()
END SUB

SUB OFText (w%)
MouseHide
SELECT CASE w%

 CASE 1:
  With% = 14: Hite% = 13
  Shown% = 0
  DO
    LOCATE Hite%, With%
    IF Shown% + OF.FileSpot = OF.HighFile THEN COLOR 14 ELSE COLOR 15
     PRINT File(Shown% + OF.FileSpot).Dat
    Shown% = Shown% + 1
    Hite% = Hite% + 1
    IF Hite% = 22 THEN
     Hite% = 13
     With% = With% + 14
    END IF
    IF With% = 56 THEN EXIT DO
  LOOP
  COLOR 15

 CASE 2:

FOR XX% = 1 TO 9
 LOCATE 12 + XX%, 58
 IF OF.HighDir = XX% + OF.DirSpot THEN COLOR 14 ELSE COLOR 15
  PRINT DirList(OF.DirSpot + XX%).Dat
NEXT
COLOR 15
LINE (456, 190)-(552, 338), 15, B ' dirs box
LINE (454, 188)-(554, 340), 15, B

END SELECT
MouseShow
END SUB

FUNCTION OFUpdate% (Funct%)
SELECT CASE Funct%
  CASE 1: Row! = (x% - 90) / 115: Col! = (y% - 190) / 16.4444444444#
          Row! = INT(Row!): Col! = INT(Col!)
          OF.HighFile = Col! + (9 * Row!) + OF.FileSpot
          OF.HighDir = 0
          IF OF.Flag = -1 THEN
            IF OF.Time > TIMER THEN
              OFUpdate% = 1: EXIT FUNCTION
            ELSE
             OF.Flag = 0
            END IF
           ELSE
            
             DO
                MouseStatus lb%, rb%, x%, y%
             LOOP UNTIL lb% = 0
           
            OF.Time = TIMER + .25
            OF.Flag = -1
           END IF
          OFText 1: OFText 2

  CASE 2: Col! = (y% - 190) / 16.44444444444#
          OF.HighDir = INT(Col!) + OF.DirSpot + 1
          OF.HighFile = 0
          IF OF.Flag = -1 THEN
            IF OF.Time > TIMER THEN
              IF DirList(OF.HighDir).Dat <> STRING$(12, " ") THEN
               LINE (91, 191)-(434, 337), 0, BF ' file box
               CHDIR DirList(OF.HighDir).Dat
               OF.HighDir = 0
               OFInit
               OFDraw
              END IF
            ELSE
              OF.Flag = 0
            END IF
           ELSE
           
            DO
                 MouseStatus lb%, rb%, x%, y%
            LOOP UNTIL lb% = 0
           
            OF.Time = TIMER + .25
            OF.Flag = -1
           END IF
          OFText 2: OFText 1
  CASE 3: IF OF.DirSpot > 1 THEN OF.DirSpot = OF.DirSpot - 1: OFText 2: OFText 1
  CASE 4: IF OF.DirSpot + 10 < OF.MaxDSpot THEN OF.DirSpot = OF.DirSpot + 1: OFText 2: OFText 1
  CASE 5:
          IF OF.FileSpot > 1 THEN
           OF.FileSpot = OF.FileSpot - 9
           OFText 1: OFText 2
          END IF
  CASE 6:
          IF (OF.FileSpot - 1) / 9 < OF.MaxFSpot - 4 THEN
           OF.FileSpot = OF.FileSpot + 9
           OFText 1: OFText 2
          END IF
END SELECT
END FUNCTION

DEFSNG A-Z
' OpenFile, the main routine
' Returns the file they selected, or a null string if none
' Options$ is the default file type to display.  A null Option$
' filters all files into the File box.
FUNCTION OpenFile$ (Option$)

  OF.Opt = UCASE$(Option$)
  OF.DirSpot = 1
  OF.HighFile = 0
  OF.HighDir = 0
  OFInit
  OFDraw

  DO
    MouseStatus lb%, rb%, x%, y%
    KeyB$ = INKEY$
    IF KeyB$ <> "" THEN
      
     SELECT CASE KeyB$
       CASE CHR$(0) + "H":
                        IF OF.HighFile <> 0 THEN
                         IF OF.HighFile > 1 THEN
                          IF OF.HighFile = OF.FileSpot THEN OF.FileSpot = OF.FileSpot - 9
                          OF.HighFile = OF.HighFile - 1
                         END IF
                         OFText 1
                        END IF
                        IF OF.HighDir <> 0 THEN
                         IF OF.HighDir > 2 THEN
                          IF OF.HighDir = OF.DirSpot + 1 THEN OF.DirSpot = OF.DirSpot - 1
                          OF.HighDir = OF.HighDir - 1
                         END IF
                         OFText 2
                        END IF
       CASE CHR$(0) + "P":
                        IF OF.HighFile <> 0 THEN
                         IF OF.HighFile < OF.NumFiles - 1 THEN
                          IF OF.HighFile - OF.FileSpot = 26 THEN OF.FileSpot = OF.FileSpot + 9
                          OF.HighFile = OF.HighFile + 1
                         END IF
                         OFText 1
                        END IF
                        IF OF.HighDir <> 0 THEN
                         IF OF.HighDir < OF.MaxDSpot - 1 THEN
                           IF OF.HighDir = OF.DirSpot + 9 THEN OF.DirSpot = OF.DirSpot + 1
                           OF.HighDir = OF.HighDir + 1
                         END IF
                         OFText 2
                        END IF
       CASE CHR$(0) + "M":
                          IF OF.HighFile <> 0 THEN
                            IF OF.HighFile + 9 <= OF.NumFiles THEN
                             IF (OF.HighFile - 1) \ 9 > (OF.FileSpot \ 9) + 1 THEN OF.FileSpot = OF.FileSpot + 9
                             IF File(OF.HighFile + 9).Dat <> "            " THEN OF.HighFile = OF.HighFile + 9
                            END IF
                            OFText 1
                          END IF

      CASE CHR$(0) + "K":
                          IF OF.HighFile <> 0 THEN
                            IF OF.HighFile - 9 >= 1 THEN
                             IF (OF.HighFile - 1) \ 9 < (OF.FileSpot \ 9) + 1 THEN OF.FileSpot = OF.FileSpot - 9
                             OF.HighFile = OF.HighFile - 9
                            END IF
                         
                            OFText 1
                          END IF

      
       CASE CHR$(13):
                      IF OF.HighDir = 0 THEN
                       OpenFile$ = File(OF.HighFile).Dat: EXIT FUNCTION
                      ELSE
                       LINE (91, 191)-(434, 337), 0, BF ' file box
                       CHDIR DirList(OF.HighDir).Dat
                       OF.HighDir = 2
                       OFInit
                       OFDraw
                      END IF
      
        CASE CHR$(9):
                     IF OF.HighDir = 0 THEN
                      OF.HighDir = 2
                      OF.HighFile = 0
                     ELSE
                      OF.HighDir = 0
                      OF.HighFile = 1
                     END IF
                     : OFText 1: OFText 2

       CASE CHR$(27): OpenFile$ = "theyhitescape": EXIT FUNCTION
     END SELECT
    END IF
    IF lb% = -1 THEN
     ' Return a function for the program to carry out
     Funct% = WhereTheyClicked%
  
     ' If they clicked a valid point, carry out each function
     IF Funct% <> 0 THEN V% = OFUpdate(Funct%)
  
     IF V% = 1 THEN
      IF File(OF.HighFile).Dat <> STRING$(12, " ") THEN
       OpenFile$ = File(OF.HighFile).Dat
       EXIT FUNCTION
      END IF
     END IF

    END IF
  LOOP

END FUNCTION

DEFINT A-Z
SUB PlaceBar (x%)
IF Volume% > 0 THEN
 Fast% = (335 + Volume% * 5) - 5
 LINE (310, Fast%)-(330, Fast% + 5), 8, BF
END IF
IF Volume% < 15 THEN
 Fast% = (335 + Volume% * 5) + 5
 LINE (310, Fast%)-(330, Fast% + 5), 8, BF
END IF
Fast% = 335 + x% * 5
LINE (310, Fast%)-(330, Fast% + 5), 12, BF
LINE (310, Fast%)-(330, Fast% + 5), 14, B
END SUB

DEFSNG A-Z
SUB PlayMusicA
notex! = notex! + .1
IF notex! > 630 THEN
        notex! = 50
        MouseHide
        ShowStaff CurrentArea%
        MouseShow
END IF

FOR Channel% = 1 TO MaxChannel%

  IF ChannelStat(Channel%).Defined = 0 THEN GOTO NoGotosPlease

  RChan% = Channel% - 1

  IF ChannelStat(Channel%).IsDone = 1 THEN
   ChannelStat(Channel%).Pstat = TIMER + ChannelStat(Channel%).Speed
   ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
   ChannelStat(Channel%).IsDone = 0
   ChannelStat(Channel%).ISPlaying = 0
  END IF

   IF ChannelStat(Channel%).ISPlaying = 0 AND Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1) <> 0 THEN
    ChannelStat(Channel%).Pstat = TIMER + ChannelStat(Channel%).Speed
         IF ChannelStat(Channel%).Speed < .2 THEN s = 8
         IF ChannelStat(Channel%).Speed > .19 AND ChannelStat(Channel%).Speed < .7 THEN s = 4
         IF ChannelStat(Channel%).Speed > .69 AND ChannelStat(Channel%).Speed < 2 THEN s = 2
         IF ChannelStat(Channel%).Speed > 1.9 THEN s = 1
     SELECT CASE Songbuf(ChannelStat(Channel%).SongPtr + RChan%)
       CASE 68   ' "D"
         DrawNote "D", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &H81
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 69   ' "E"
         DrawNote "E", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &HB0
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 70   ' "F"
         DrawNote "F", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &HCA
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 71    ' "G"
         DrawNote "G", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &H2
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
       CASE 65 ' "A"
         DrawNote "A", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &H41
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
       CASE 66   ' "B"
         DrawNote "B", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &H87
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
       CASE 67  '  "C"
         DrawNote "C", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &HAE
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
       CASE 17 ' "C#"
         DrawNote "C#", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &H6B
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 18 ' "D#"
         DrawNote "D#", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &H98
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 20 ' F#"
         DrawNote "F#", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &HE5
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
       CASE 21 ' "G#"
         DrawNote "G#", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &H20
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
       CASE 15 ' "A#"
         DrawNote "A#", Channel%, s, (ChannelStat(Channel%).SongPtr / 3)
         WriteReg &HA0 + RChan%, &H63
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave

       CASE 255
         ChannelStat(Channel%).ISPlaying = 1
         ChannelStat(Channel%).Pstat = TIMER + (Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%) / 100) * ChannelStat(Channel%).Speedscale
         ChannelStat(Channel%).Flag = -1
       CASE 254
         ChannelStat(Channel%).Octave = Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%)
         ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
       CASE 253
         ChannelStat(Channel%).Speed = (Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%) / 100) * ChannelStat(Channel%).Speedscale
         ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
       CASE 252
         ChannelStat(Channel%).WaveForm = Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%) - 300
         ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
         IF RChan% > 2 THEN RRChan% = RChan% + 6 ELSE RRChan% = 0
         WriteReg &HE0 + RChan% + RRChan%, ChannelStat(Channel%).WaveForm
       CASE 251
         ChannelStat(1).Flag2 = -1
          FOR MaxChan% = 1 TO MaxChannel%
           ChannelStat(MaxChan%).SongPtr = 1
           ChannelStat(MaxChan%).ISPlaying = 0
           ChannelStat(MaxChan%).IsDone = 0
          NEXT
         CloseChannels
         EXIT SUB
       CASE 250
           FeedBack% = Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%) - 300
           ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
           IF RChan% > 2 THEN RRChan% = RChan% + 6 ELSE RRChan% = 0
           WriteReg &HC0 + RChan% + RRChan%, FeedBack%

     END SELECT
   END IF

    IF ChannelStat(Channel%).ISPlaying = 1 THEN
     IF TIMER >= ChannelStat(Channel%).Pstat THEN
      WriteReg &HB0 + RChan%, 0
      ChannelStat(Channel%).IsDone = 1
       IF ChannelStat(Channel%).Flag = -1 THEN
        ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
        ChannelStat(Channel%).Flag = 0
       END IF
     END IF
    END IF

   IF ChannelStat(Channel%).SongPtr > MaxChannel% + 1 THEN
     IF Songbuf(ChannelStat(Channel%).SongPtr + RChan%) <> 0 AND Songbuf(ChannelStat(Channel%).SongPtr - MaxChannel% + RChan%) < 250 THEN
       IF ChannelStat(Channel%).ISPlaying = 0 THEN ChannelStat(Channel%).ISPlaying = 1
     END IF
   END IF

NoGotosPlease:
NEXT Channel%


FOR Channel% = 1 TO MaxChannel%

 IF ChannelStat(Channel%).ISPlaying = 0 THEN
  ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
  IF ChannelStat(Channel%).SongPtr >= UBOUND(Songbuf) / MaxChannel% THEN
   ChannelStat(Channel%).SongPtr = 1
  END IF
 END IF
NEXT Channel%
END SUB

SUB PlayMusicB

COLOR 15
FOR Channel% = 1 TO MaxChannel%

  IF ChannelStat(Channel%).Defined = 0 THEN GOTO NoGotosPleasee

  RChan% = Channel% - 1

  IF ChannelStat(Channel%).IsDone = 1 THEN
   ChannelStat(Channel%).Pstat = TIMER + ChannelStat(Channel%).Speed
   ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
   ChannelStat(Channel%).IsDone = 0
   ChannelStat(Channel%).ISPlaying = 0
  END IF

   IF ChannelStat(Channel%).ISPlaying = 0 AND Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1) <> 0 THEN
    ChannelStat(Channel%).Pstat = TIMER + ChannelStat(Channel%).Speed
     Datta% = Songbuf(ChannelStat(Channel%).SongPtr + RChan%)
    IF ChannelStat(Channel%).Mute = 0 THEN
     SELECT CASE Datta%
       CASE 68   ' "D"
         WriteReg &HA0 + RChan%, &H81
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "D  "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
       CASE 69   ' "E"
         WriteReg &HA0 + RChan%, &HB0
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "E  "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
       CASE 70   ' "F"
         WriteReg &HA0 + RChan%, &HCA
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "F  "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
       CASE 71    ' "G"
         WriteReg &HA0 + RChan%, &H2
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "G  "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
       CASE 65 ' "A"
         WriteReg &HA0 + RChan%, &H41
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "A  "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
       CASE 66   ' "B"
         WriteReg &HA0 + RChan%, &H87
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "B  "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
       CASE 67  '  "C"
         WriteReg &HA0 + RChan%, &HAE
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "C  "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
       CASE 17 ' "C#"
         WriteReg &HA0 + RChan%, &H6B
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "C# "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
       CASE 18 ' "D#"
         WriteReg &HA0 + RChan%, &H98
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "D# "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
       CASE 20 ' F#"
         WriteReg &HA0 + RChan%, &HE5
         WriteReg &HB0 + RChan%, &H21 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "F# "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
       CASE 21 ' "G#"
         WriteReg &HA0 + RChan%, &H20
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "G# "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
       CASE 15 ' "A#"
         WriteReg &HA0 + RChan%, &H63
         WriteReg &HB0 + RChan%, &H22 + 4 * ChannelStat(Channel%).Octave
         LOCATE 20, Channel% * 7 + 3: PRINT "A# "
         Bars(Channel%).L = 130: Bars(Channel%).De = 0
      END SELECT
     END IF
      SELECT CASE Datta%
       CASE 255
         ChannelStat(Channel%).ISPlaying = 2
         ChannelStat(Channel%).Pstat = TIMER + (Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%) / 100) * ChannelStat(Channel%).Speedscale
         ChannelStat(Channel%).Flag = -1
         LOCATE 20, Channel% * 7 + 3: PRINT "---"

       CASE 254
         ChannelStat(Channel%).Octave = Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%)
         ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
       CASE 253
         ChannelStat(Channel%).Speed = (Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%) / 100) * ChannelStat(Channel%).Speedscale
         ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
       CASE 252
         ChannelStat(Channel%).WaveForm = Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%) - 300
         ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
         IF RChan% > 2 THEN RRChan% = RChan% + 6 ELSE RRChan% = 0
         WriteReg &HE0 + RChan% + RRChan%, ChannelStat(Channel%).WaveForm
       CASE 251
         ChannelStat(1).Flag2 = -1
          FOR MaxChan% = 1 TO MaxChannel%
           ChannelStat(MaxChan%).SongPtr = 1
           ChannelStat(MaxChan%).ISPlaying = 0
           ChannelStat(MaxChan%).IsDone = 0
          NEXT
         CloseChannels
         EXIT SUB
       CASE 250
           FeedBack% = Songbuf(ChannelStat(Channel%).SongPtr + Channel% - 1 + MaxChannel%) - 300
           ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
           IF RChan% > 2 THEN RRChan% = RChan% + 6 ELSE RRChan% = 0
           WriteReg &HC0 + RChan% + RRChan%, FeedBack%

     END SELECT
    
   END IF

    IF ChannelStat(Channel%).ISPlaying > 0 THEN
     IF TIMER >= ChannelStat(Channel%).Pstat THEN
      WriteReg &HB0 + RChan%, 0
      ChannelStat(Channel%).IsDone = 1
       IF ChannelStat(Channel%).Flag = -1 THEN
        ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
        ChannelStat(Channel%).Flag = 0
       END IF
     END IF
    END IF
 
   IF ChannelStat(Channel%).SongPtr > MaxChannel% + 1 THEN
     IF Songbuf(ChannelStat(Channel%).SongPtr + RChan%) <> 0 AND Songbuf(ChannelStat(Channel%).SongPtr - MaxChannel% + RChan%) < 250 THEN
       IF ChannelStat(Channel%).ISPlaying = 0 THEN ChannelStat(Channel%).ISPlaying = 1
     END IF
   END IF

NoGotosPleasee:
NEXT Channel%


FOR Channel% = 1 TO MaxChannel%

 IF ChannelStat(Channel%).ISPlaying = 0 THEN
  ChannelStat(Channel%).SongPtr = ChannelStat(Channel%).SongPtr + MaxChannel%
  IF ChannelStat(Channel%).SongPtr >= UBOUND(Songbuf) / MaxChannel% THEN
   ChannelStat(Channel%).SongPtr = 1
  END IF
 END IF
NEXT Channel%

        
END SUB

DEFINT A-Z
SUB PopDown
MouseHide
PAINT (102, 2), 5, 15
PUT (100, 25), Back%, PSET
MouseShow
END SUB

SUB PopDownTheDamnMenu
MouseHide
PAINT (2, 2), 5, 15
PUT (0, 25), Back%, PSET
MouseShow
END SUB

SUB PopInsMenu (Channel%)
' Displays the Instrument menu over the specified channel
' added 6-13-97

UnMuteChannels
DrawVU
ClearNotes
ISPlaying% = 0
ResetSong
MouseHide

GET ((Channel% * 56) - 48, 240)-((Channel% * 58) + 84, 312), Back%


' Do a fun menu-expansion effect
XCenter% = Channel% * 56 + 18: YCenter% = 276: YScale% = 3
FOR x% = 0 TO 66
        LINE (XCenter% - x%, YCenter% - YScale%)-(XCenter% + x%, YCenter% + YScale%), 5, BF
        LINE (XCenter% - x%, YCenter% - YScale%)-(XCenter% + x%, YCenter% + YScale%), 15, B
        IF x% > 33 THEN YScale% = YScale% + 1
NEXT

LINE ((Channel% * 56) - 48, 240)-((Channel% * 58) + 84, 312), 5, BF
LINE ((Channel% * 56) - 48, 240)-((Channel% * 58) + 84, 312), 15, B

VBSux% = Channel% * 56 - 46
Font "Instrument Menu", VBSux%, 242, 1, 1, 12
Font CHR$(26) + " Change     ", VBSux%, 258, 1, 1, 1
Font CHR$(26) + " Save       ", VBSux%, 268, 1, 1, 2
Font CHR$(26) + " Close Menu ", VBSux%, 278, 1, 1, 3
Font "Save all", VBSux% + 56, 290, 1, 1, 14
Font "changes.", VBSux% + 60, 300, 1, 1, 14

LINE (VBSux% + 4, 293)-(VBSux% + 16, 305), 5, BF
LINE (VBSux% + 4, 293)-(VBSux% + 16, 305), 15, B

IF SaveChanges% = 0 THEN
        Font "No", VBSux% + 20, 295, 1, 1, 15
ELSE
        Font "Yes", VBSux% + 20, 295, 1, 1, 15
        LINE (VBSux% + 4, 293)-(VBSux% + 16, 305), 15
        LINE (VBSux% + 16, 293)-(VBSux% + 4, 305), 15
END IF

MouseShow
                ReleaseMouse
               
                DO
                        
                        MouseStatus lb%, rb%, x%, y%
   
                        ' toggle save box
                        IF lb% = -1 THEN
                        IF x% > VBSux% + 4 AND x% < VBSux% + 16 THEN
                                IF y% > 293 AND y% < 305 THEN
                                        IF SaveChanges% = 1 THEN SaveChanges% = 0 ELSE SaveChanges% = 1
                                                MouseHide
                                                IF SaveChanges% = 0 THEN
                                                        LINE (VBSux% + 20, 295)-(VBSux% + 48, 305), 5, BF
                                                       
                                                        Font "No", VBSux% + 20, 295, 1, 1, 15
                                                        LINE (VBSux% + 5, 294)-(VBSux% + 15, 304), 5, BF
                                                ELSE
                                                        LINE (VBSux% + 20, 295)-(VBSux% + 48, 305), 5, BF
                                                        Font "Yes", VBSux% + 20, 295, 1, 1, 15
                                                        LINE (VBSux% + 4, 293)-(VBSux% + 16, 305), 15
                                                        LINE (VBSux% + 16, 293)-(VBSux% + 4, 305), 15
                                                END IF
                                                MouseShow
                                                ReleaseMouse
                                END IF
                        END IF
                        END IF


                        ' 3 menu choices
                        IF x% > VBSux% AND x% < VBSux% + 140 THEN
                                IF y% > 257 AND y% < 265 THEN
                                        IF Stat% <> 1 THEN
                                                IF AlreadyBright(1) THEN
                                                        MakeBright 1: Stat% = 1
                                                END IF
                                        END IF
                                ELSEIF y% > 267 AND y% < 275 THEN
                                        IF Stat% <> 2 THEN
                                                IF AlreadyBright(2) THEN
                                                        MakeBright 2: Stat% = 2
                                                END IF
                                        END IF
                                ELSEIF y% > 277 AND y% < 285 THEN
                                        IF Stat% <> 3 THEN
                                                IF AlreadyBright(3) THEN
                                                        MakeBright 3: Stat% = 3
                                                END IF
                                        END IF
                                ELSE
                                        IF Choice% <> 0 THEN MakeBright -1
                                        Choice% = 0: Stat% = -1
                                END IF
                        END IF

                        IF lb% = -1 AND Choice% <> 0 THEN EXIT DO
                LOOP



                SELECT CASE Choice%
                        CASE 1:
                                MouseHide
                                PUT ((Channel% * 56) - 48, 240), Back%, PSET
                                MouseShow
                                PostFix$ = "INS"
                                x% = GetFile%(PostFix$)
                                IF x% <> -1 THEN
                                        SetIns Channel%
                                        IF SaveChanges% = 1 THEN
                                                OPEN CurrentSong$ FOR BINARY AS #1
                                                Ident$ = INPUT$(6, #1)
                                                GET #1, , Ver!
                                                GET #1, , MaxChannel%
                                                FOR XY% = 1 TO Channel% - 1
                                                        I$ = INPUT$(16, #1)
                                                NEXT
                                                PUT #1, , CurrentIns
                                                CLOSE #1
                                        END IF
                                END IF
                                ReleaseMouse
                                MakeBright -1
                       CASE 2:
                                CD% = GetDrv: swp% = CD%: path$ = GetDir$(swp%)
                                Total$ = CHR$(CD% + 65) + ":" + path$
                                Total$ = LEFT$(Total$, LEN(Total$) - 1)
                                MouseHide
                                PUT ((Channel% * 56) - 48, 240), Back%, PSET
                                GET (VBSux% - 5, 240)-(VBSux% + 260, 312), Back%
                               
                                LINE (VBSux% - 5, 260)-(VBSux% + 260, 290), 0, BF
                                LINE (VBSux% - 5, 260)-(VBSux% + 260, 290), 15, B
                                Font Total$, VBSux% - 5, 261, 1, 1, 12
                                LOCATE 18, ((Channel% - 1) * 7) + 2
                               
                                OPEN CurrentSong$ FOR BINARY AS #1

                                Ident$ = INPUT$(6, #1)
                                GET #1, , Ver!
                                GET #1, , MaxChannel%
                                FOR XY% = 1 TO Channel%
                                        GET #1, , CurrentIns
                                        Save% = x%
                                        x% = Save%
                                NEXT
                                CLOSE #1
                                INPUT FileName$
                                IF FileName$ = "" THEN FileName$ = "null.ins"
                                IF INSTR(FileName$, ".") = 0 THEN
                                        FileName$ = FileName$ + ".INS"
                                END IF
                                OPEN FileName$ FOR BINARY AS #1
                                        PUT #1, , CurrentIns
                                CLOSE #1

                                PUT (VBSux% - 5, 240), Back%, PSET
                                MouseShow
                                MakeBright -1
                                ReleaseMouse
                                EXIT SUB

                        CASE 3: ReleaseMouse

                END SELECT

MouseHide
PUT ((Channel% * 56) - 48, 240), Back%, PSET
MouseShow
END SUB

SUB PopItDown
MouseHide
PAINT (202, 2), 5, 15
PUT (200, 25), Back%, PSET
MouseShow
END SUB

SUB PopItUp
MouseHide
PAINT (202, 2), 9, 15
GET (200, 25)-(300, 80), Back%
LINE (200, 25)-(300, 80), 15, B
LINE (201, 26)-(299, 79), 5, BF
Font "Contents", 202, 27, 1, 2, 1
Font "Support", 202, 44, 1, 2, 2
Font "About", 202, 61, 1, 2, 3
MouseShow
END SUB

SUB PopUp
MouseHide
PAINT (102, 2), 9, 15
GET (100, 25)-(200, 68), Back%
LINE (100, 25)-(200, 68), 15, B
LINE (100, 25)-(200, 25), 8
LINE (101, 26)-(199, 67), 5, BF
Font "Notes", 103, 27, 1, 2, 1
Font "VU Meters", 103, 44, 1, 2, 2
MouseShow
END SUB

SUB PopUpTheDamnMenu
MouseHide
GET (0, 25)-(100, 105), Back%
PAINT (2, 2), 9, 15
LINE (0, 25)-(100, 100), 15, B
LINE (0, 25)-(100, 25), 8
LINE (1, 26)-(99, 99), 5, BF
Font "Open", 4, 27, 1, 2, 1
Font "DOS Shell", 4, 44, 1, 2, 2
Font "Info", 4, 61, 1, 2, 3
Font "Exit", 4, 78, 1, 2, 4
MouseShow
END SUB

SUB ReleaseMouse
DO
IF ISPlaying% = -1 THEN CorePlay
MouseStatus lb%, rb%, x%, y%
LOOP UNTIL lb% = 0
END SUB

DEFSNG A-Z
SUB ResetSong
           CloseChannels
            FOR x% = 1 TO MaxChannel%
             ChannelStat(x%).ISPlaying = 0
             ChannelStat(x%).IsDone = 0
             ChannelStat(x%).SongPtr = 1
             ChannelStat(x%).Speedscale = 1
             ChannelStat(x%).Speed = .25
             ChannelStat(x%).Flag = 0
            NEXT
            IF DisType% = 1 THEN
             ShowStaff 1
             notex! = 50
             ReleaseMouse
            END IF
END SUB

SUB SBInit
   FOR z% = 1 TO &HF5
     CALL WriteReg(z%, 0)
   NEXT z%
END SUB

SUB SetIns (Channel%)

CarChan% = Channel% - 1

IF Channel% > 3 THEN CarChan% = CarChan% + 5
IF Channel% > 6 THEN CarChan% = CarChan% + 5


WriteReg &H20 + CarChan%, CurrentIns.CMult  'Plays carrier note at specified octave ch. 1
WriteReg &H23 + CarChan%, CurrentIns.MMult  'Plays modulator note at specified octave ch. 1
WriteReg &H40 + CarChan%, CurrentIns.CLevel   'Set carrier total level to softest ch. 1
WriteReg &H43 + CarChan%, CurrentIns.MLevel   'Set modulator level to loudest ch. 1
WriteReg &H60 + CarChan%, CurrentIns.CAttack  'Set carrier attack and decay ch. 1
WriteReg &H63 + CarChan%, CurrentIns.MAttack  'Set modulator attack and decay ch. 1
WriteReg &H80 + CarChan%, CurrentIns.CSustain 'Set carrier sustain and release ch. 1
WriteReg &H83 + CarChan%, CurrentIns.MSustain 'Set modulator sustain and release ch. 1
END SUB

SUB ShowFace (x%)
CIRCLE (225, 380), 30, 15, , , 1.1
PAINT (225, 390), 12, 15
LINE (213, 365)-(216, 380), 8, BF
LINE (233, 365)-(236, 380), 8, BF
Aspect! = x% / 16: CIRCLE (225, 390), 14, 8, 3, .2, Aspect!
CIRCLE (225, 391), 14, 8, 3, .2, Aspect!

CIRCLE (415, 380), 30, 15, , , 1.1
PAINT (415, 390), 12, 15
LINE (403, 365)-(406, 380), 8, BF
LINE (423, 365)-(426, 380), 8, BF
Aspect! = x% / 16: CIRCLE (415, 390), 14, 8, 3, .2, Aspect!
CIRCLE (415, 391), 14, 8, 3, .2, Aspect!

END SUB

DEFINT A-Z
SUB ShowInfo
MouseHide
GET (120, 165)-(520, 315), Back%
LINE (120, 165)-(520, 315), 15, B
LINE (121, 166)-(519, 314), 5, BF
IF FileName$ = "" THEN FileName$ = "No selected file"
xyz% = 244 - ((LEN(FileName$) * 8) / 2)
Font "File Name : " + SongName$, xyz%, 168, 1, 2, 15
IF FileName$ = "No selected file" THEN FileName$ = ""
Font "File Version  : " + STR$(Ver!), 212, 220, 1, 1, 15
Font "Channels      : " + STR$(MaxChannel%), 212, 230, 1, 1, 15
Font "Notes/Channel : " + STR$(MaxNotes%), 212, 240, 1, 1, 15
Font "Hit any key to clear this box.", 182, 294, 1, 2, 15
DO
a$ = INKEY$
IF ISPlaying% = -1 THEN CorePlay
LOOP UNTIL a$ <> ""
PUT (120, 165), Back%, PSET
MouseShow
MakeBright -1
END SUB

SUB ShowStaff (number)
MouseHide
IF MaxChannel% = 0 THEN Sheyit% = 1: MaxChannel% = 3
LINE (0, 26)-(639, 444), 0, BF
  SELECT CASE number
    CASE 1
      FOR yy = 1 TO MaxChannel% * 40 STEP 40
        FOR p = 50 + yy TO 75 + yy STEP 6
         LINE (0, p)-(639, p), 7
        NEXT
       Clef 20, yy + 65
      NEXT
    CASE 2
      FOR I = 50 TO 400 STEP 10
       IF I > 190 AND I < 250 THEN LINE (0, I)-(639, I), 7 ELSE LINE (0, I)-(639, I), 16
      NEXT
  END SELECT
MouseShow
IF Sheyit% = 1 THEN MaxChannel% = 0
END SUB

SUB Support
MouseHide
GET (120, 165)-(520, 315), Back%
LINE (120, 165)-(520, 315), 15, B
LINE (121, 166)-(519, 314), 5, BF
Font "The Ultimate MKJamz Player v2.1 Support", 142, 168, 1, 3, 15
Font "EMail : blood225@aol.com", 202, 215, 1, 2, 14
Font "WWW : http://members.aol.com/mkwebsite/", 144, 235, 1, 2, 14
Font "FTP : ftp://users.aol.com/blood225/", 156, 255, 1, 2, 14
Font "Hit any key to clear this box.", 182, 294, 1, 2, 15
DO
a$ = INKEY$
IF ISPlaying% = -1 THEN CorePlay
LOOP UNTIL a$ <> ""
PUT (120, 165), Back%, PSET
MakeBright -1
MouseShow
END SUB

FUNCTION TheyClickedAMute%
FOR XY% = 1 TO MaxChannel%
 va% = XY% * 56
 IF x% > va% + 10 AND x% < va% + 37 THEN
  IF y% > 75 AND y% < 100 THEN TheyClickedAMute% = XY%
 END IF
NEXT
END FUNCTION

FUNCTION TheyClickedASolo%
FOR XY% = 1 TO MaxChannel%
 va% = XY% * 56
 IF x% > va% + 10 AND x% < va% + 37 THEN
  IF y% > 115 AND y% < 140 THEN TheyClickedASolo% = XY%
 END IF
NEXT
END FUNCTION

FUNCTION TheyClickedDisplay%
IF x% > 100 AND x% < 200 THEN
 IF y% > 0 AND y% < 24 THEN TheyClickedDisplay% = 1
END IF
END FUNCTION

FUNCTION TheyClickedFaster%
IF x% > 360 AND x% < 400 THEN
 IF y% > 450 AND y% < 475 THEN
  TheyClickedFaster% = 1
 END IF
END IF
END FUNCTION

FUNCTION TheyClickedFile%
IF x% > 0 AND x% < 100 THEN
 IF y% > 0 AND y% < 24 THEN TheyClickedFile% = 1
END IF
END FUNCTION

FUNCTION TheyClickedHelp%
IF x% > 200 AND x% < 300 THEN
 IF y% > 0 AND y% < 24 THEN TheyClickedHelp% = 1
END IF
END FUNCTION

FUNCTION TheyClickedInsBar%
FOR XY% = 1 TO MaxChannel%
        IF y% > 160 AND y% < 292 THEN
                IF x% > (XY% * 56) + 12 AND x% < (XY% * 56) + 35 THEN
                        TheyClickedInsBar% = XY%
                        EXIT FUNCTION
                END IF
        END IF
NEXT
END FUNCTION

FUNCTION TheyClickedPlay%
IF x% > 280 AND x% < 320 THEN
 IF y% > 450 AND y% < 475 THEN
  TheyClickedPlay% = 1
 END IF
END IF
END FUNCTION

FUNCTION TheyClickedSlower%
IF x% > 320 AND x% < 360 THEN
 IF y% > 450 AND y% < 475 THEN
  TheyClickedSlower% = 1
 END IF
END IF
END FUNCTION

FUNCTION TheyClickedStop%
IF x% > 240 AND x% < 280 THEN
 IF y% > 450 AND y% < 475 THEN TheyClickedStop% = 1
END IF

END FUNCTION

FUNCTION TheyClickedVol%
Fast% = 335 + Volume% * 5
IF x% > 310 AND x% < 330 THEN
 IF y% > Fast% AND y% < Fast% + 5 THEN TheyClickedVol% = 1
END IF
END FUNCTION

SUB UnMuteChannels
' Take all channels off mute
         FOR XY% = 1 TO MaxChannel%
                ChannelStat(XY%).Mute = 0
         NEXT
END SUB

SUB VuSetUp

MouseHide

LINE (0, 26)-(639, 444), 0, BF

DrawVU

LINE (185, 330)-(455, 436), 5, BF
LINE (185, 330)-(455, 436), 15, B

LINE (0, 75)-(40, 100), 15, B
LINE (1, 76)-(39, 99), 5, BF

LINE (0, 115)-(40, 140), 15, B
LINE (1, 116)-(39, 139), 5, BF

LINE (0, 218)-(40, 241), 15, B
LINE (1, 219)-(39, 240), 5, BF

LINE (0, 301)-(40, 324), 15, B
LINE (1, 302)-(39, 323), 5, BF

Font "Mute", 2, 77, 1, 2, 14
Font "Solo", 2, 117, 1, 2, 14
Font "VU", 2, 220, 1, 2, 14
Font "Note", 2, 303, 1, 2, 14

LINE (309, 334)-(331, 417), 15, B
LINE (310, 336)-(330, 416), 8, BF

Font "Volume", 295, 417, 1, 2, 15
Font "Quiet", 263, 335, 1, 1, 15
Font "Loud", 333, 408, 1, 1, 15


FMVolume Volume%
ShowFace Volume%
PlaceBar Volume%

MakeBright -1
MouseShow
END SUB

FUNCTION WhereTheyClicked%
' 1 = on a file name
' 2 = on a directory
' 3 = up, dir select
' 4 = down, dir select
' 5 = left, dir select
' 6 = right, dir select

IF x% > 90 AND x% < 435 THEN
 IF y% > 190 AND y% < 338 THEN WhereTheyClicked% = 1
END IF
IF x% > 456 AND x% < 552 THEN
 IF y% > 190 AND y% < 338 THEN WhereTheyClicked% = 2
END IF
IF x% > 558 AND x% < 570 THEN
 IF y% > 190 AND y% < 210 THEN WhereTheyClicked% = 3
 IF y% > 320 AND y% < 338 THEN WhereTheyClicked% = 4
END IF
IF y% > 350 AND y% < 365 THEN
 IF x% > 88 AND x% < 104 THEN WhereTheyClicked% = 5
 IF x% > 420 AND x% < 437 THEN WhereTheyClicked% = 6
END IF
END FUNCTION

SUB WriteReg (Reg%, value%)
OUT BasePort% + 8, Reg%
 FOR V% = 1 TO 6
  Buf% = INP(BasePort% + 8)
 NEXT
OUT BasePort% + 9, value%
 FOR V% = 1 TO 34
  Buf% = INP(BasePort% + 9)
 NEXT
END SUB

