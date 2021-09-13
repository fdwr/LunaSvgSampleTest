     '-------------------------------------------------------------------
     '
     '                     Q U I C K  B A S I C
     '
     '                   ллл ллл ллллл лллл  ллллл
     '                   л л л л   л   л   л   л
     '                   л  л  л   л   л   л   л
     '                   л  л  л ллллл лллл  ллллл
     '
     '               QBMIDI(TM) Library Sample Programs
     '
     '                    Q B M - D E M 2 . B A S
     '
     '                M U S I C    G E N E R A T O R
     '
     '          S H A R E W A R E    V E R S I O N    1 . 0
     '
     '                         Developed by:
     '                 AskUs! Technology Specialists
     '                          PO Box 737
     '                    Bountiful, UT 84011-0737
     '
     '-------------------------------------------------------------------
    
     DECLARE SUB GetKeypress (AsciiValueOfKey%, WaitUntilKeyIsPressed%)
     DECLARE SUB DispTextLeftJust (Row%, Col%, Text$, Attribute%)
     DECLARE SUB DispTextCenter (Row%, Text$, Attribute%)
     DECLARE SUB DispNumbLeftJust (Row%, Col%, Number%, Attribute%)


     DEFINT A-Z                                                  'Set all variables to integer unless specified

     CONST False = 0, True = NOT False                           'Set true and false constants (usable in all subs)
     CONST Bright = 15, Normal = 7                               'Set colors to use (also usable in all subs)
     CONST EscapeKey = 27, SpaceBar = 32                         'Set values to check for when keys are pressed
     CONST UpArrow = -72, DownArrow = -80
     CONST LeftArrow = -75, RightArrow = -77
     CONST HomeKey = -71, EndKey = -79
     CONST PageUp = -73, PageDown = -81
     CONST JKey = 74, NKey = 78, PKey = 80
     CONST RKey = 82, TKey = 84, VKey = 86
     CONST SKey = 83, Minus = 45, Plus = 43

     DIM Note(1 TO 6), Text$(1 TO 7)                             'Make small array for notes and functions that are displayed

     Text$(1) = " Jump Method   "                                'Set Functions to be displayed
     Text$(2) = " Random Pause  "
     Text$(3) = " Patch Number  "
     Text$(4) = " Tempo %       "
     Text$(5) = " Step Per Jump "
     Text$(6) = " Notes/Chord   "
     Text$(7) = " Velocity      "

     '-------------------------------------------------------------------
     ' See if a midi unit is installed in system
     '-------------------------------------------------------------------

     CALL SeeIfMPUExists(Found)                                  'See if unit exists in system
     IF Found = False THEN                                       'If MPU controller not found then error message and exit
          PRINT "Midi Controller not found or not responding."
          END
     END IF
     CALL ResetMpu                                               'Reset just in case some other program left if modified
     CALL SetDataInStopMode                                      'Minimize intelligence provided by MPU 401 or equivalent
     CALL OmniModeOn                                             'Set all midi data going to all midi channels
     CALL SetToPolyMode                                          'Set multivoice on

     '-------------------------------------------------------------------
     ' Display titles and a border
     '-------------------------------------------------------------------

     GOSUB DisplayBorderAndTitles                                'Call local SUB to clear screen and display border and initial screen of text


     '-------------------------------------------------------------------
     ' Set defaults - at initial runtime for starting point
     '-------------------------------------------------------------------

     JumpMethod = False                                          'Random Method (True) or Drunk (False)
     RandomPause = False                                         'Insert Random pauses enabled on True
     PatchNumber = 64                                            'Sounds like a good number to start with
     Tempo = 50                                                 'Set tempo to 100, moderate- May need to be changed when compiled
     JumpStep = 5                                                'Jump by fives when in drunken mode
     NotesPerChord = 2                                           'Play one note at a time to start
     Velocity = 64                                               'Moderate strike velocity

     GOSUB RedisplaySettings                                     'Show them on screen for the first time
     Selected = 1                                                'Which item is selected for editing
     GOSUB UpdateSelectedItem                                    'Show selected item


     '-------------------------------------------------------------------
     ' Check to see if they wish to continue
     '-------------------------------------------------------------------

     Text$ = "Press any key to begin or Esc to exit"
     Row = 22
     CALL DispTextCenter(Row, Text$, Normal)                     'Call local sub to display centered text

     WaitUntilKeyIsPressed = True
     CALL GetKeypress(Keypress, WaitUntilKeyIsPressed)                         'Keypress contains ASCII value of key, -ASCII if extended key
     IF Keypress = 27 THEN CLS : END                             'Exit program if escape key was kit


     '-------------------------------------------------------------------
     ' Change message at bottom
     '-------------------------------------------------------------------

     Text$ = "  Press Space to Pause, Esc to stop  "
     CALL DispTextCenter(22, Text$, Normal)


     '-------------------------------------------------------------------
     ' Change patch to default patch before sending any notes
     '-------------------------------------------------------------------

     CALL ChangePatchTo(PatchNumber)                             'Call QBMIDI function


     '-------------------------------------------------------------------
     ' Start loop to play notes based on Random numbers and constraints
     ' given.  Allow user to change constraints while running (listening).
     '-------------------------------------------------------------------

     RANDOMIZE TIMER                                             'Setup random number generator seed using internal clock

     DO
    
          '-------------------------------------------------------------------
          ' If pause hasn't been turned on then go play new notes, otherwise skip and just look for keypresses
          '-------------------------------------------------------------------

          IF PauseOn = 0 THEN

               '-------------------------------------------------------------------
               'Select New Starting Note based on Jump Method selected
               'where Random is truly random and drunk simulates a drunk stagger
               'moving from side to side based on Random number given
               '-------------------------------------------------------------------

               IF JumpMethod THEN                                     'Random method
                    StartingNote = (RND * 60) + 36                    'Select random Starting note between 36 and 96

               ELSE                                                   'Drunk method
                    SeedNote = (RND * 99) + 1                         'Get seed between 1 and 100
                    IF SeedNote > 50 THEN                             'If over fifty then jump up by Jump Step increment
                         StartingNote = StartingNote + JumpStep       'Set Starting note up by Jump step
                         IF StartingNote > 90 THEN StartingNote = 90  'If too high, then set at 80
                    ELSE
                         StartingNote = StartingNote - JumpStep       'Jump down by JumpStep increment
                         IF StartingNote < 42 THEN StartingNote = 42  'If too low, set bottom at 42
                    END IF

               END IF

               '-------------------------------------------------------------------
               ' Get ready to play next selected notes by truning off the ones
               ' currently playing - if any
               '-------------------------------------------------------------------

               i = 0                                                  'Set counter to zero
               DO                                                     'Start loop
                    i = i + 1                                         'Increment counter
                    IF Note(i) THEN                                   'If not was on, turn it off
                         CALL PlayNote(Note(i), 0)                    'Call PlayNote with velocity of zero
                    ELSE                                              'Until Note(i)=0
                         EXIT DO                                      'Exit sub
                    END IF
                    Note(i) = 0                                       'Clear the Note to 0
               LOOP UNTIL i = 6                                       'Loop until all six have been turned off

               '-------------------------------------------------------------------
               ' Set values for notes to play or leave at zero if not to play
               '-------------------------------------------------------------------
         
               Note(1) = StartingNote                                 'Set center point note
               IF NotesPerChord > 1 THEN Note(2) = StartingNote + 4   'If two notes are to be played, then calc second note
               IF NotesPerChord > 2 THEN Note(3) = StartingNote - 5   'If three then ... same
               IF NotesPerChord > 3 THEN Note(4) = StartingNote + 7   'And so on ..
               IF NotesPerChord > 4 THEN Note(5) = StartingNote + 12
               IF NotesPerChord > 5 THEN Note(6) = StartingNote - 12

               '-------------------------------------------------------------------
               ' Play the actual notes until you find a 0 then exit do loop
               '-------------------------------------------------------------------
         
               i = 0                                                  'Set counter to zero
               DO                                                     'Start loop
                    i = i + 1                                         'Increment counter
                    IF Note(i) THEN                                   'If a note value exists then play it
                         CALL PlayNote(Note(i), Velocity)             'Call the play routine
                    ELSE                                              'Until no more notes are found
                         EXIT DO                                      'Exit loop early if less than 6 notes are to be played
                    END IF
               LOOP UNTIL i = 6                                       'Exit if all six have been played

          ELSE                                                        'If already paused
               IF RandomPause THEN                                    'If Ok to use random pause then
                    PauseOn = PauseOn + 1                             'If already paused increment counter
                    IF PauseOn > LengthOfPause THEN                   'If Time limit exceeded then
                         PauseOn = 0                                  'Turn off pause flag
                         GOSUB ClearPauseMessage                      'Clear message off screen and continue
                         LengthOfPause = 0                            'Clear length of pause so we know to reset it later
                    END IF
               END IF
          END IF

          '-------------------------------------------------------------------
          ' If Random Pauses allowed then calculate pause delay and time to next pause
          ' or increment counter while waiting for next pause
          '-------------------------------------------------------------------

          IF RandomPause THEN                                         'If random pause OK
               IF LengthOfPause = 0 THEN                              'And length has not been set
                    ChordsToPlayBeforePause = RND * 70 + 5            'Set number of chords to play before pausing
                    LengthOfPause = RND * 75                          'Set length of pause
                    ChordsPlayed = 0                                  'Set chords played counter to zero (for when we need it)
               END IF
          
               IF PauseOn = 0 THEN                                    'If pause is not on then
                    ChordsPlayed = ChordsPlayed + 1                   'Increment chord counter
                    IF ChordsPlayed > ChordsToPlayBeforePause THEN    'and check against number of chords to play before pause
                         PauseOn = 1                                  'And if equal, set pause to on
                         GOSUB DisplayPauseMessage                    'Display pause message
                    END IF
               END IF
          END IF


          '-------------------------------------------------------------------
          ' Wait for correct time with regards to tempo setting, checking KB for valid keypresses
          '-------------------------------------------------------------------

          Time = 0                                                    'Clear time counter
          DO                                                          'Start timing delay loop
               Time = Time + 1                                        'Increment time counter
               CALL GetKeypress(Keypress, False)                      'See if key has been pressed
               IF Keypress THEN GOSUB HandleKeypress                  'If so then gosub to check it
               IF Time > Tempo * 2 THEN EXIT DO                       'Check if enough time has passed

               '-------------------------------------------------------------------
               ' While waiting - look at the midi port for data being sent back to us
               ' from the MPU and from devices attached .. ie keyboards, etc.
               '
               ' For this example, we'll look for patch changes and reflect them
               ' on screen.
               '
               ' The CALL ReceiveMidiData(Value) routine returns a -1 if no
               ' data is coming in from MIDI port, and the actual values if
               ' data is present.  See the Midi 1.0 specification for a full
               ' list of commands returned from devices connected. Many devices
               ' send only the command change once until functions are changed.
               ' Meaning, if you change the patch from the keyboard, you'll get
               ' a 192 as the command then the number as the patch pressed. If you
               ' press another patch, it skips sending the 192 since you're already
               ' in that mode. Pressing a note on the keyboard sends a 144 then the
               ' note and then velocity. Each subsequent note will not be preceeded
               ' by a 144 unless another command occurred inbetween (for example
               ' a patch change).
               '
               ' Some opular commands returned are (See your MIDI spec for more):
               ' Value = 192       Patch Change, followed by patch number
               ' Value = 144       Note on/off, followed by Note and velocity
               ' Value = 176       Portamento On/off
               '
               'Suggestion:
               ' Insert a print statement to view what's happening when you
               ' select functions or play from your Keyboard
               '-------------------------------------------------------------------
              
               CALL ReceiveMidiData(Value)                            'Look at data coming in from Midi
               IF Value <> -1 THEN                                    'If -1, no data is present
                    IF PatchChangeOn THEN                             'If Previous data was patchchange then this data is patch number so make the change
                         IF Value < 127 THEN                          'If not a command then it's still a patch
                              PatchNumber = Value                     'Set patch to Value received
                              GOSUB RedisplaySettings                 'Show them on screen for the first time
                         END IF
                    END IF
                    IF Value > 127 THEN                               'If value >127 then command was received
                         IF Value = 192 THEN                          'If 192 then a patch change came in
                              PatchChangeOn = True                    'So set Patch change on so next value read will be read above
                         ELSE                                         'Otherwise ignore
                              PatchChangeOn = False
                         END IF
                    END IF
               END IF
                    
          LOOP                                                        'Loop until time passes

     LOOP                                                             'Loop for next note
     END                                                              'Should never get to this end


ChangeKeyToRightArrow:           
    
     '-------------------------------------------------------------------
     ' If item is already selected then control jumps here to change the key pressed to right arrow
     ' before entering handle Keypress routine. This lets you press the key letter and increment the value
     '-------------------------------------------------------------------

     Keypress = RightArrow
     

HandleKeypress:
    
     '-------------------------------------------------------------------
     ' Handle Keypressed or ignore if not value
     '-------------------------------------------------------------------

     SELECT CASE Keypress
          CASE RightArrow, Plus
               SELECT CASE Selected
                    CASE 1                                            'JumpMethod
                         IF JumpMethod = False THEN JumpMethod = True ELSE JumpMethod = False
                    CASE 2                                            'Random Pause
                         IF RandomPause = True THEN RandomPause = False ELSE RandomPause = True
                    CASE 3                                            'Patch Number
                         PatchNumber = PatchNumber + 1
                         IF PatchNumber > 127 THEN PatchNumber = 0
                         CALL ChangePatchTo(PatchNumber)
                    CASE 4                                            'Tempo
                         Tempo = Tempo - 5
                         IF Tempo < 20 THEN Tempo = 20
                    CASE 5                                            'Jump per step
                         JumpStep = JumpStep + 1
                         IF JumpStep > 12 THEN JumpStep = 12
                    CASE 6                                            'Notes/Chord
                         NotesPerChord = NotesPerChord + 1
                         IF NotesPerChord > 6 THEN NotesPerChord = 6
                    CASE 7                                            'Velocity
                         Velocity = Velocity + 2
                         IF Velocity > 127 THEN Velocity = 127
               END SELECT
               GOSUB RedisplaySettings                                'Show them on screen for the first time

          CASE LeftArrow, Minus
               SELECT CASE Selected
                    CASE 1                                            'JumpMethod
                         IF JumpMethod = False THEN JumpMethod = True ELSE JumpMethod = False
                    CASE 2                                            'Random Pause
                         IF RandomPause = True THEN RandomPause = False ELSE RandomPause = True
                    CASE 3                                            'Patch Number
                         PatchNumber = PatchNumber - 1
                         IF PatchNumber < 0 THEN PatchNumber = 127
                         CALL ChangePatchTo(PatchNumber)
                    CASE 4                                            'Tempo
                         Tempo = Tempo + 5
                         IF Tempo > 500 THEN Tempo = 500
                    CASE 5                                            'Jump per step
                         JumpStep = JumpStep - 1
                         IF JumpStep < 1 THEN JumpStep = 1
                    CASE 6                                            'Notes/Chord
                         NotesPerChord = NotesPerChord - 1
                         IF NotesPerChord < 1 THEN NotesPerChord = 1
                    CASE 7                                            'Velocity
                         Velocity = Velocity - 2
                         IF Velocity < 1 THEN Velocity = 1
               END SELECT
               GOSUB RedisplaySettings                                'Show them on screen for the first time

          CASE SpaceBar
               IF PauseOn THEN
                    PauseOn = 0
                    GOSUB ClearPauseMessage                           'Clear the message on screen
               ELSE
                    PauseOn = 1
                    GOSUB DisplayPauseMessage                         'Display message
               END IF
               RETURN

          CASE EscapeKey                                              'Check for keypress
               GOTO EndNow
          CASE JKey
               IF Selected = 1 THEN GOTO ChangeKeyToRightArrow        'If already selected then change keypress to right arrow allowing them to increment value
               Selected = 1                                           'Otherwise set selected item at 1
          CASE RKey
               IF Selected = 2 THEN GOTO ChangeKeyToRightArrow        'Ditto
               Selected = 2
          CASE PKey
               IF Selected = 3 THEN GOTO ChangeKeyToRightArrow
               Selected = 3
          CASE TKey
               IF Selected = 4 THEN GOTO ChangeKeyToRightArrow
               Selected = 4
          CASE SKey
               IF Selected = 5 THEN GOTO ChangeKeyToRightArrow
               Selected = 5
          CASE NKey
               IF Selected = 6 THEN GOTO ChangeKeyToRightArrow
               Selected = 6
          CASE VKey
               IF Selected = 7 THEN GOTO ChangeKeyToRightArrow
               Selected = 7
          CASE UpArrow
               Selected = Selected - 1: IF Selected = 0 THEN Selected = 7
          CASE DownArrow
               Selected = Selected + 1: IF Selected = 8 THEN Selected = 1
          CASE PageUp, HomeKey
               Selected = 1
          CASE PageDown, EndKey
               Selected = 7
     END SELECT
     GOSUB UpdateSelectedItem                                         'Redraw items and highlight selected item
     RETURN


RedisplaySettings:

     '-------------------------------------------------------------------
     ' Update settings on screen
     '-------------------------------------------------------------------

     'Note: Col and Offset were already set in Borders routine

     IF JumpMethod THEN Text$ = "Random" ELSE Text$ = "Drunk "
     CALL DispTextLeftJust(14, Col + Offset, Text$, Bright)

     IF RandomPause THEN Text$ = "On " ELSE Text$ = "Off"
     CALL DispTextLeftJust(15, Col + Offset, Text$, Bright)

     CALL DispNumbLeftJust(16, Col + Offset, PatchNumber, Bright)
     T1 = (Tempo - 50) * 100                                     'Calc Tempo in Percent
     T1 = T1 / 450
     T1 = 100 - T1
     CALL DispNumbLeftJust(17, Col + Offset, T1, Bright)
     CALL DispNumbLeftJust(18, Col + Offset, JumpStep, Bright)
     CALL DispNumbLeftJust(19, Col + Offset, NotesPerChord, Bright)
     CALL DispNumbLeftJust(20, Col + Offset, Velocity, Bright)

     RETURN



ClearPauseMessage:

     '-------------------------------------------------------------------
     ' Display Paused messages
     '-------------------------------------------------------------------

     CALL DispTextLeftJust(15, Col + Offset + 12, "        ", Normal)
     Pause = 0
     LengthOfPause = 0
     Text$ = "  Press Space to Pause, Esc to stop  "
     CALL DispTextCenter(22, Text$, Normal)
     RETURN

DisplayPauseMessage:
    
     '-------------------------------------------------------------------
     ' Clear Paused messages and redisplay what to do at bottom
     '-------------------------------------------------------------------

     COLOR 0, Normal                                             'Set to Reverse momentairly
     CALL DispTextLeftJust(15, Col + Offset + 12, " Paused ", 0) 'Display as black
     COLOR Normal, 0                                             'Restore to normal
     Text$ = "  Press Space to Continue, Esc to stop  "
     CALL DispTextCenter(22, Text$, Normal)
     RETURN


DisplayBorderAndTitles:

     '-------------------------------------------------------------------
     ' Borders and titles are used just once, so we've put them down
     ' here and Gosub once to get things started.  This could have been
     ' placed in a SUB function and called instead, but we like to only
     ' put routines called often in Subs.
     '-------------------------------------------------------------------
    
     SCREEN 0                                                    'Set text screen
     CLS 0                                                       'Clear screen to black

     Row = 1                                                     'Which Row
     Col = 1                                                     'Which Column
     Text$ = "Щ" + STRING$(77, 205) + "Л"                        'Text to be displayed
     CALL DispTextLeftJust(Row, Col, Text$, Normal)              'Call local SUB that displays text left justified

     Text$ = "К"
     FOR Row = 2 TO 24
          CALL DispTextLeftJust(Row, 1, Text$, Normal)
          CALL DispTextLeftJust(Row, 79, Text$, Normal)
     NEXT Row

     Row = 24
     Text$ = "Ш" + STRING$(77, 205) + "М"
     CALL DispTextLeftJust(Row, Col, Text$, Normal)

     Row = 1
     Text$ = "    QBMIDI(TM) DEMO - MUSIC GENERATOR    "
     Attribute = Bright
     CALL DispTextCenter(Row, Text$, Attribute)

     Text$ = " (C) 1990 AskUs! Technology Specialists, Box 737, Bountiful, UT 84011 "     'Bottom title
     CALL DispTextCenter(25, Text$, Normal)

     Text$ = "This demonstration program uses the QBMIDI library to provide access"
     CALL DispTextCenter(4, Text$, Normal)

     Text$ = "your MIDI instruments via an MPU401 or compatible controller. Change"
     CALL DispTextCenter(5, Text$, Normal)

     Text$ = "the parameters below to hear different sound combinations.          "
     CALL DispTextCenter(6, Text$, Normal)

     Text$ = "Use the Cursor Up/Down keys or Key letter to select function"
     CALL DispTextCenter(8, Text$, Normal)

     Text$ = "Right/Left Cursor to change value, space to pause/re-start"
     CALL DispTextCenter(9, Text$, Normal)

     Col = 27
     Offset = 17

     Text$ = "Function"
     CALL DispTextLeftJust(12, Col, Text$, Normal)

     Text$ = "Setting"
     CALL DispTextLeftJust(12, Col + Offset, Text$, Normal)

     Text$ = "-----------"
     CALL DispTextLeftJust(13, Col, Text$, Normal)

     Text$ = "-------"
     CALL DispTextLeftJust(13, Col + Offset, Text$, Normal)
    
    
UpdateSelectedItem:
    
     '-------------------------------------------------------------------
     ' Redray items and highlight the one that Selected =
     '-------------------------------------------------------------------

     Item = 0
     StartRow = 13
     DO
          Item = Item + 1
          IF Item = Selected THEN
               Attribute = 0
               COLOR 0, Normal
               CALL DispTextLeftJust(StartRow + Item, Col - 1, Text$(Item), 0)
               COLOR Normal, 0
          ELSE
               CALL DispTextLeftJust(StartRow + Item, Col - 1, Text$(Item), Normal)
               CALL DispTextLeftJust(StartRow + Item, Col - 1, LEFT$(Text$(Item), 2), Bright)
          END IF
     LOOP UNTIL Item = 7
     RETURN


EndNow:
    
     '-------------------------------------------------------------------
     ' End the program, but shut off all notes before leaving
     '-------------------------------------------------------------------

     CALL AllNotesOff                                            'Don't exit without shutting off all notes (it shuts off immediately, unlike Velocity=0 that uses normal decay value of patch)
     CLS                                                         'Clear screen just to keep things tidy
     END

SUB DispNumbLeftJust (Row, Col, Number, Attribute) STATIC

     LOCATE Row, Col - 1
     COLOR Attribute
     PRINT Number; "   ";
     COLOR Normal



END SUB

SUB DispTextCenter (Row, Text$, Attribute) STATIC

     LOCATE Row, 40 - LEN(Text$) / 2
     COLOR Attribute
     PRINT Text$;
     COLOR Normal

END SUB

 SUB DispTextLeftJust (Row, Col, Text$, Attribute) STATIC

     LOCATE Row, Col
     COLOR Attribute
     PRINT Text$;
     COLOR Normal

END SUB

SUB GetKeypress (AsciiValueOfKey, WaitUntilKeyIsPressed)

     AsciiValueOfKey = 0                                    'Clear variable
     ExtendedKey = 0                                        'Turn off extended key flag (used to show that function key was pressed)

     IF WaitUntilKeyIsPressed THEN

          DO: LOOP UNTIL INKEY$ = ""                        'Clear out keys that may be sitting in buffer

          DO                                                'Loop until a key is pressed
               Key$ = INKEY$
          LOOP WHILE Key$ = ""

     ELSE

          Key$ = INKEY$
          WaitUntilKeyIsPressed = 0
          IF LEN(Key$) = 0 THEN EXIT SUB
     END IF

     IF LEN(Key$) > 1 THEN                                  'Check for extended key (F1, Cursor, etc.) by checking for length variable >1
          Key$ = RIGHT$(Key$, 1)                            'If extended then get right character in variable
          ExtendedKey = -1                                  'Set flag to show extended key was pressed
     END IF

     AsciiValueOfKey = (ASC(UCASE$(Key$)))                  'Place ASCII value in variable to be returned
     

     IF ExtendedKey THEN                                    'If extended then convert to minus
          AsciiValueOfKey = -AsciiValueOfKey                'Convert to minus number to show extended key
     END IF

END SUB

