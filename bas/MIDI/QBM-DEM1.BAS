     '-------------------------------------------------------------------
     '
     '                     Q U I C K  B A S I C
     '    
     '                   ллл ллл ллллл лллл  ллллл
     '                   л л л л   л   л   л   л
     '                   л  л  л   л   л   л   л
     '                   л  л  л ллллл лллл  ллллл
     '
     '             QBMIDI(TM) Library and Sample Programs
     '
     '                    Q B M - D E M 1 . B A S
     '
     '              T U T O T I A L   A N D   D E M O
     '
     '          S H A R E W A R E    V E R S I O N    1 . 0
     '
     '                         Developed by:
     '                 AskUs! Technology Specialists
     '                          PO Box 737
     '                    Bountiful, UT 84011-0737
     '
     '    QBMIDI allows you to easily access a Roland Midi Processing
     '    Unit (MPU401) or compatible MIDI controller from QuickBASIC
     '    version 4.X. QBMIDI uses the files QBMIDI.QLB or QBMIDI.LIB
     '    which contain several simple to use call routines that enable
     '    you access to your MPU401 controller ... and your synthesizers!
     '
     '    If you're just learning QuickBASIC we'll show you how to
     '    start QuickBASIC with these MIDI routines available in real
     '    time, so you can edit and hear your programs work while
     '    in the QuickBASIC environment.  We've also tried to show you
     '    a better understanding of using CALLS to subs, just in case you
     '    have been reluctant to try them.
     '
     '    For sake of readability and understanding for new programmers,
     '    we've tried to write the examples in a simple to understand way
     '    rather than using boolean and subs that would speed things up at
     '    the expense of understandability.  We also use FOR NEXT loops for
     '    timing delays and yes we know they're not accurate at all speeds
     '    and suggest you use time delay routines suitable for your system.
     '    You experienced folk will see many obvious places for program
     '    improvement and by all means .... improve!  But, for this first
     '    lesson, we've written at a greatly simplified level.
     '
     '
     '        QBMIDI is a Trademark of AskUs! Technology Specialists
     '               (c) 1990 AskUs.  All rights reserved.
     '
     '---------------------------------------------------------------------


     '---------------------------------------------------------------------
     '
     ' Writing A Program That Uses QBMIDI
     '
     ' Since all QBMIDI routines deal in integer numbers, usually from 0 to
     ' 255 we use the DEFINT A-Z command to make using integer variables
     ' easier.  Using integer yields greater execution speed and saves memory
     ' space.  Also, if you compile your programs to .EXE and you avoid the
     ' floating point library (by not using floating point numbers or
     ' functions , your program size should be much smaller by up to 20K.
     '---------------------------------------------------------------------

     DEFINT A-Z                              'Always use integers unless specified for speed and space savings

     '---------------------------------------------------------------------
     ' Display Headings
     '---------------------------------------------------------------------

     SCREEN 0                                'Select normal text screen 0
     CLS                                     'Clear screen
     COLOR 15                                'Use Bright white
     PRINT "QuickBASIC MIDI DEMO          ";
     PRINT "Shareware Version 1.0         ";
     PRINT "(c) 1990 AskUs!"
     COLOR 7                                 'Use Normal white
     PRINT STRING$(80, "Ф")                  'Print line across top of screen
     VIEW PRINT 4 TO 25                      'Set viewport so messages can scroll under while leaving heading intact

     '------------------------------------------------------------------------
     ' You access the QBMIDI routines by calling them as we would call a SUB
     ' procedure or other add-in library routines.  In the next executable
     ' line we call the SeeIfMPUExists routine to do just that .. see if a
     ' MIDI controller is present. If one is found then the variable called
     ' Found will be set to the value -1, otherwise the Found variable will
     ' come back as Zero to indicate a controller was not present.
     '
     ' Now let's call the routine and handle it according to what's found.
     ' Obviously, if a controller is not found, you'd probably hang your CPU
     ' if you tried to continue, so we exit with an error message.
     '------------------------------------------------------------------------

     CALL SeeIfMPUExists(Found)              'Check for Midi Processing Unit, Sets Found to -1 if a MPU is found
     IF Found THEN                           'If found then display found message
          PRINT "MPU Found"
     ELSE                                    'Otherwise, if not found end program
          PRINT "MPU Not Found"
          END
     END IF

     '------------------------------------------------------------------------
     ' The next routine, ResetMPU, lets you restore the Midi Processing Unit
     ' to its power up state.  We like to issue a reset before starting our
     ' programs to clear out any changes that may have been made by another
     ' MIDI program - and it is much cleaner than asking you to turn your
     ' computer off to clear the unit.  ResetMPU will NOT turn off notes
     ' you may have left on and typically is used only once at the beginning
     ' of your program.
     '
     ' No variable is returned with this Call, so you omit the parenthesis
     ' and a variable name when calling.
     '------------------------------------------------------------------------

     CALL ResetMPU                           'Reset MPU to Power up defaults - just in case another program left if with settings changed

     '------------------------------------------------------------------------
     ' Following is some normal text to tell you what's going on ...
     '------------------------------------------------------------------------

     CLS
     COLOR 15
     PRINT "WELCOME TO QBMIDI ... AND A QUICK SAMPLE OF ITS USE"
     COLOR 7
     PRINT
     PRINT "When running this program we'll describe functions available to you"
     PRINT "from QBMIDI and refer you to parts of the source code for a better"
     PRINT "explanation of what's happening.  We think the best way to learn is from"
     PRINT "example, so we've included well documented examples within this source."
     PRINT
     PRINT "To continue with this program, you'll need the following:"
     PRINT "   IBM COMPATIBLE COMPUTER (6MHz 286 or better is recommended)"
     PRINT "   MIDI CONTROLLER (Roland MPU401, Voyetra OP-4001, or equivalent)"
     PRINT "         attached to the computer, (appx. $100.00 item)"
     PRINT "   SYNTHESIZER with Midi inputs and outputs (appx. $150.00 and up"
     PRINT "         depending on features and type of technology used)"
     PRINT "   MIDI CABLES connecting the Controller to the Synthesizer ($15.00ea)."
     PRINT "         Be sure MIDI OUT on the controller is connected to IN on the synth"
     PRINT "         and IN on the controller hooks to OUT on the synth."
     PRINT "   AMPLIFIED SPEAKER, most higher end synthesizers use external amps."
     PRINT
     PRINT "If you've got the above then hook it up and turn it on!  If not, please"
     PRINT "check with your local musicians shop about purchase (appx. costs given above)."
     PRINT
     GOSUB PressAnyKeyAndAllowExit                          'Ask for any keypress or Esc to exit

     '------------------------------------------------------------------------
     ' Now we'll actually play a few notes to see if your system is working
     '------------------------------------------------------------------------

     CLS
     COLOR 15
     PRINT "LET'S PLAY A SCALE TO CHECK IF THINGS ARE WORKING"
     COLOR 7
     PRINT
     PRINT "We'll now play a scale to make sure all is working. To do this we've set"
     PRINT "up a FOR NEXT loop to increment the notes when calling the QBMIDI command "
     PRINT "PlayNote.  Midi will recognizes note values from 1 to 127, but we'll play"
     PRINT "only from 41 to 107 since most synthesizers sound a bit muddy at the bottom"
     PRINT "and top ends."
     PRINT
     PRINT "Make sure all components are on, plugged in correctly. Select a sound from"
     PRINT "your front panel on your synthesizer and then press a key to hear your"
     PRINT "QuickBASIC and QBMIDI play a scale."
     PRINT
     GOSUB PressAnyKeyAndAllowExit                          'Ask for any keypress or Esc to exit

     '------------------------------------------------------------------------
     ' In the next loop, we use the CALL PlayNote command to send a Note
     ' value and velocity value to the MIDI instrument attached.  With this
     ' call routine, we set the variables Note and Velocity before calling
     ' PlayNote.
     '
     ' Explanation of variables:
     '
     ' NOTE indicates what pitch or note to play.  Each key on a keyboard has
     ' been assigned a number from 1 to 127, with middle C being 60.  Some
     ' synthesizers won't play extremely low or high notes or they remap them
     ' to lowest possible notes.  This causes you to hear the same notes repeat
     ' when playing a scale from 1 to 127.
     '
     ' VELOCITY indicates the amount of pressure applied when striking the
     ' note from a keyboard.  If you are playing a soft piece of music, the
     ' velocity may range from 40 to 80. If playing loud, you may hit the
     ' keys harder, thereby increasing the velocity of the keypress. You
     ' specify how hard the key is pressed from 1 (softest) to 127 (hardest).
     '
     ' Valid ranges for PlayNote variables are:
     '
     '    Note     = 1 to 127   1 being lowest note possible, 127 the highest
     '    Velocity = 1 to 127   1 being soft touch, 127 being hardest touch
     '
     ' Once a sound has been turned on, it will stay on until you turn it
     ' off.  Turn it off by sending a velocity of Zero (0) to PlayNote
     ' along with the Note you wish to turn off.  In the following example
     ' we turn on a note, wait a while, then turn it off using Velocity of 0.
     '
     ' No variables are changed, so the Note and Velocity variables are left
     ' intact so you can call repeatedly, without resetting the variable.
     '------------------------------------------------------------------------

     Note = 38                               'Starting note (hopefully above the muddy notes on some keyboards)
     DO                                      'Begin a loop to play the scale
          Note = Note + 3                    'Increment Note by 3 (Change to 1 and re-run)

          LOCATE , 1                         'Put cursor at beginning of line
          PRINT "Not playing note ... ";     'Display message
          COLOR 15                           'Set text to high brightness
          PRINT Note; " ";                   'Display current not being played
          COLOR 7                            'Set text color to normal brightness
          Velocity = 120                     'Strong Key Strike Velocities (Range os 1 - 127)
          CALL PlayNote(Note, Velocity)      'Send the Note out Midi to all Synths attached

          FOR tmp = 1 TO 15000: NEXT tmp     'Wait a little while (Modify on you machine as needed)

          Velocity = 0                       'Now turn off the note by sending a velocity of Zero along with which note to make zero
          CALL PlayNote(Note, Velocity)      'Send the Note out Midi to all Synths attached

     LOOP UNTIL Note > 105

     PRINT
     PRINT
     PRINT "You should have heard a scale played in steps of every third note. If not"
     PRINT "check your connections, volume, and sound you've selected then restart."
     PRINT
     GOSUB PressAnyKeyAndAllowExit           'Ask for any keypress or Esc to exit


     '------------------------------------------------------------------------
     ' Create a chord by calling PlayNote several times, specifying different
     ' notes for each call, then waiting to turn off the note.
     '------------------------------------------------------------------------

     CLS
     COLOR 15
     PRINT "CHORDS"
     COLOR 7
     PRINT
     PRINT "Now we'll play a three part chord.  This is done by sending three PlayNote"
     PRINT "commands in succession, and leaving all three turned on until we individually"
     PRINT "turn them back off.  Let's listen to a chord."
     GOSUB PressAnyKeyAndAllowExit           'Ask for any keypress or Esc to exit

     '------------------------------------------------------------------------
     ' Three PlayNote Commands Are Issued with Velocities Set to 120 (Quite Hard)
     '------------------------------------------------------------------------

     Velocity = 120                          'Strong Key Strike Velocities (Range os 1 - 127)
     Note = 29                               'Note Range is between 1 - 127
     CALL PlayNote(Note, Velocity)           'Send the Note out Midi to all Synths attached

     Velocity = 120                          'Strong Key Strike Velocities (Range os 1 - 127)
     Note = 41                               'Note Range is between 1 - 127
     CALL PlayNote(Note, Velocity)           'Send the Note out Midi to all Synths attached

     Velocity = 120                          'Strong Key Strike Velocities (Range os 1 - 127)
     Note = 60                               'Note Range is between 1 - 127
     CALL PlayNote(Note, Velocity)           'Send the Note out Midi to all Synths attached to turn the Middle C off

     PRINT
     PRINT "You're hearing a three part chord.  Notes 29, 41 and 60 were turned on"
     PRINT "above and currently still on.  Press any key to turn the chord off."
     GOSUB PressAnyKey

     '------------------------------------------------------------------------
     ' Now We'll turn off the chord by issuing the Same three PlayNote Commands
     ' except we'll set Velocity to zero.  Since PlayNote variables are not
     ' changed, we can specify Velocity once then for all three CALLS.
     '------------------------------------------------------------------------

     Velocity = 0                            'Set velocity to zero to turn off note

     Note = 29                               'Note Range is between 1 - 127
     CALL PlayNote(Note, Velocity)           'Send the Note out Midi to all Synths attached

     Note = 41                               'Note Range is between 1 - 127
     CALL PlayNote(Note, Velocity)           'Send the Note out Midi to all Synths attached

     Note = 60                               'Note Range is between 1 - 127
     CALL PlayNote(Note, Velocity)           'Send the Note out Midi to all Synths attached to turn the Middle C off

     PRINT
     PRINT "Now the chord has been turned off."
     GOSUB PressAnyKeyAndAllowExit           'Ask for any keypress or Esc to exit


     '------------------------------------------------------------------------
     ' Now we'll show changes in Velocity values
     '------------------------------------------------------------------------

     CLS
     COLOR 15
     PRINT "VELOCITY VALUES"
     COLOR 7
     PRINT "Whenever a note is turned on using PlayNote you must specify the note"
     PRINT "to play and a velocity value.  Velocity value indicates how hard the key"
     PRINT "would have been pressed if playing from a keyboard.  1 is softest up to 127"
     PRINT "as hardest hit possible. To shut off a note, we send the velocity as 0."
     PRINT
     PRINT "We'll now play the same chord at a three velocity levels, 20, 70 and 127."
     PRINT
     PRINT "Listen to a Velocity value of 20 (simulated light pressure on keyboard)"
     GOSUB PressAnyKey

     '------------------------------------------------------------------------
     ' Set the notes we'll use for this chord and call a GOSUB created to play
     ' the chord (and save some space in this program).
     '------------------------------------------------------------------------

     Note1 = 60                              'First note in chord
     Note2 = 41                              'Second Note in chord
     Note3 = 29                              'Third note in chord

     '------------------------------------------------------------------------
     ' Now set velocity and GOSUB to play the chord
     '------------------------------------------------------------------------

     Velocity = 20                           'Soft Key Strike Velocities (Range os 1 - 127)
     GOSUB PlayThreeNoteChord                'We'll use a subroutine to save some space

     PRINT "It's light pressure and may not be heard unless your volume is up."
     GOSUB PressAnyKey

     '------------------------------------------------------------------------
     ' After you've pressed a key, we'll send Zero Velocity to turn off the
     ' chord
     '------------------------------------------------------------------------

     Velocity = 0                            'Shut off Notes
     GOSUB PlayThreeNoteChord                'We'll use a subroutine to save some space

     '------------------------------------------------------------------------
     ' Now repeat for Velocity 70
     '------------------------------------------------------------------------

     PRINT
     PRINT "Listen to a Velocity value of 70 (simulated medium pressure on keyboard)"
     GOSUB PressAnyKey

     Velocity = 70                           'Medium Key Strike Velocities (Range os 1 - 127)
     GOSUB PlayThreeNoteChord                'We'll use a subroutine to save some space

     PRINT "This medium pressure should sound about twice as loud as the previous."
     GOSUB PressAnyKey

     Velocity = 0                            'Shut off Notes
     GOSUB PlayThreeNoteChord                'We'll use a subroutine to save some space

     '------------------------------------------------------------------------
     ' Now repeat for Velocity 127
     '------------------------------------------------------------------------

     PRINT
     PRINT "Listen to a Velocity value of 127 (simulated hardest pressure on keyboard)"
     GOSUB PressAnyKey

     Velocity = 127                          'Loudest Key Strike Velocities (Range os 1 - 127)
     GOSUB PlayThreeNoteChord                'We'll use a subroutine to save some space

     PRINT "Playing the hardest hit pressure (velocity) available."
     GOSUB PressAnyKey

     Velocity = 0                            'Shut off Notes
     GOSUB PlayThreeNoteChord                'We'll use a subroutine to save some space

     PRINT
     PRINT "You can also change Velocity within the notes of a chord where each key"
     PRINT "receives a different pressure when pressed. We suggest you try a little"
     PRINT "experimenting with this ... a bit later."
     PRINT
     GOSUB PressAnyKeyAndAllowExit           'Ask for any keypress or Esc to exit



     CLS
     COLOR 15
     PRINT "PLAY SCALE OF CHORDS"
     COLOR 7
     PRINT
     PRINT "We'll combine the parts learned so far (play a scale and play a chord) into"
     PRINT "a scale of Chords. We set up a loop for play the scale but call three PlayNote"
     PRINT "commands at a time to play the chord.  Let's listen."
     GOSUB PressAnyKeyAndAllowExit           'Ask for any keypress or Esc to exit

     PRINT

     Note = 38                               'Starting note (hopefully above the muddy notes on some keyboards)
     DO                                      'Begin a loop to play the scale
          Note = Note + 3                    'Increment Note by 3 (Change to 1 and re-run)

          Velocity = 120                     'Strong Key Strike Velocities (Range os 1 - 127)
          Note1 = Note - 12                  'Subtract 12 for bottom note in chord
          Note2 = Note                       'Mid note stays the same
          Note3 = Note + 19                  'Add 19 to get upper note in chord

          LOCATE , 1                         'Put cursor at beginning of line
          PRINT "Now playing notes ... ";    'Display message
          COLOR 15                           'Set text to high brightness
          PRINT Note1; "    ";               'Display current not being played
          PRINT Note2; "    ";               'Display current not being played
          PRINT Note3; "    ";               'Display current not being played
          COLOR 7                            'Set text color to normal brightness

          GOSUB PlayThreeNoteChord

          FOR tmp = 1 TO 15000: NEXT tmp     'Wait a while

          Velocity = 0                       'Now turn off the note by sending a velocity of Zero along with which note to make zero
          GOSUB PlayThreeNoteChord

     LOOP UNTIL Note > 105

     Velocity = 120                          'Hard pressure
     Note1 = 29                              'First note in chord
     Note2 = 41                              'Second Note in chord
     Note3 = 60                              'Third note in chord
     GOSUB PlayThreeNoteChord                'We'll use a subroutine to save some space

     LOCATE , 1                              'Put cursor at beginning of line
     PRINT "Now playing notes ... ";         'Display message
     COLOR 15                                'Set text to high brightness
     PRINT Note1; "    ";                    'Display current not being played
     PRINT Note2; "    ";                    'Display current not being played
     PRINT Note3; "    ";                    'Display current not being played
     COLOR 7                                 'Set text color to normal brightness

     FOR tmp = 1 TO 20000                    'Wait quite a while
          FOR j = 1 TO 10                    'Increase by factor of 10
          NEXT j                             'Next
     NEXT tmp                                'Loop til 20,000

     Velocity = 0                            'Shut off Notes
     GOSUB PlayThreeNoteChord                'We'll use a subroutine to save some space

     PRINT
     GOSUB PressAnyKey                       'Ask for any keypress or Esc to exit
     

     '----------------------------------------------------------------------
     ' A final closing note to display
     '----------------------------------------------------------------------

     CLS
     COLOR 15
     PRINT "WHAT NEXT"
     COLOR 7
     PRINT
     PRINT "List out this program and modify it using your imagination.  If you wish to"
     PRINT "go further with MIDI than this program allows, we suggest you consider"
     PRINT "purchase of the QBMIDI MUSICIANS VERSION that provides advanced features"
     PRINT "including independent sound control by midi channel, bulk sound data dumps"
     PRINT "and saves, and much more. See the QBMIDI.DOC file for more info."
     PRINT
     PRINT "We hope you like our beginners intro to MIDI and QBMIDI.  Experiment and"
     PRINT "have fun.  We've found that making music with Computers is far more enjoyable"
     PRINT "than writing other types of programs.  And besides, our world doesn't need"
     PRINT "another amortization, biorythm or ultimate menu shell program."
     PRINT
     PRINT "AskUs! for more information or Tell Us what you'd like by writing us at:"
     PRINT
     PRINT "            AskUs!, PO Box 737, Bountiful, UT 84011-0737"
     PRINT

     END



'------------------------------- G O S U B S ------------------------------------


     '----------------------------------------------------------------------
     ' When playing chords, it's easiest to GOSUB to a routine that plays
     ' or shuts off all three (or more) notes in the cord.  We've played
     ' three notes simultaneously but more can be played in a chord or
     ' at once by adding another CALL PlayNote.  Experiment and have fun!
     '----------------------------------------------------------------------

PlayThreeNoteChord:

     'Note1, Note2 and Note3 should contain the notes to play
     'Velocity should contain desired play velocity or 0 to shut off the
     'note currently playing.

     CALL PlayNote(Note1, Velocity)
     CALL PlayNote(Note2, Velocity)
     CALL PlayNote(Note3, Velocity)

     RETURN


     '----------------------------------------------------------------------
     ' We use the press any key in two forms. One that allows exit to the
     ' system and one that doesn't.  We don't allow an exit while notes are
     ' being played.  Again, it's lengthy for readability purposes only.
     '----------------------------------------------------------------------

PressAnyKeyAndAllowExit:
     ExitAllowed = -1                             'Set flag (Variable) showing that exit is acceptable

PressAnyKey:                                      'Display message at bottom, wait for key, check for escape and end or erase message and return
     DO                                           'Start simple loop to clear out keyboard buffer, just in case characters were left there
     LOOP UNTIL INKEY$ = ""                       'Loop until no more keys are found
     COLOR 15                                     'Use bright level text
     PRINT "Press any key ";                      'Display message
     IF ExitAllowed THEN                          'If Exit OK then ...
          PRINT "(or Esc to quit)";               'Display extended message to say it's ok to use escape
     END IF                                       'End of If Exit check
     COLOR 7                                      'Go back to Normal level text
     DO                                           'Start loop to wait for keypress
          a$ = INKEY$                             'Look for keypress using inkey
     LOOP UNTIL LEN(a$)                           'Loop until length of A$ is greater than 0, in otherwords loop until a character is in A$, LEN(A$)>1
     IF ExitAllowed = -1 THEN                     'If Exit OK then check if escape was pressed
          IF a$ = CHR$(27) THEN                   'Check for the escape key
               PRINT                              'Space to next line
               PRINT "Program stopped"            'Display what happened
               END                                'End the program
          END IF                                  'End of Check for escape key If condition
     END IF                                       'End of Exit Allowed If condition
     LOCATE , 1                                   'Send cursor back to beginning of line
     PRINT STRING$(42, " ");                      'Erase the Press any key message
     LOCATE , 1                                   'Send cursor back to beginning of line for next line to print
     ExitAllowed = 0                              'Set exit OK flag to false in case it was used this time in
     RETURN                                       'Jump back where Gosub brought us here


