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
     '                    Q B M - D E M 3 . B A S
     '
     '           S I M P L E   K E Y B O A R D   S P L I T
     '
     '          S H A R E W A R E    V E R S I O N    1 . 0
     '
     '                         Developed by:
     '                 AskUs! Technology Specialists
     '                          PO Box 737
     '                    Bountiful, UT 84011-0737
     '
     '      QBMIDI is a trademark of AskUs! Technology Specialists
     '              (c) 1990 AskUs! Technology Specialists
     '-------------------------------------------------------------------

     DEFINT A-Z                                                  'Set all to integer
    
     CONST False = 0, True = NOT False                           'Set boolean constants

     CALL SeeIfMPUExists(Found)                                  'Stop if no
     IF Found = 0 THEN PRINT "Midi Controller Missing": END      'MPU is found

     CALL ResetMpu                                               'Reset to power on status
     CALL AllNotesOff                                            'Just in case
     CALL SetDataInStopMode                                      'Turn off MPU intelligence
     CALL OmniModeOn                                             'Set omni on - so all uses midi data

     CLS                                                         'Titles
     PRINT "QBMIDI SIMPLE KEYBOARD SPLIT                               (c) 1990 AskUs!"
     PRINT
     PRINT "This will read the MIDI data coming in and select a datch number based on"
     PRINT "where it is with regards to a split point you select.  Set the split location"
     PRINT "you desire by pressing a key on your MIDI keyboard. We suggest starting with"
     PRINT "middle C.  You can press Esc on the Computer keyboard to exit."
     PRINT
     PRINT "Press the key where a split will occur now ... ";
     GOSUB SelectKeyForSplit
     PRINT " Key"; SplitAtKeyNumber; "selected"
     PRINT

     PRINT "Now select the patch (Voice) you'd like to use as the lower patch. You must"
     PRINT "press the patch select on your keyboard ... ";
     GOSUB SelectPatch: PatchOne = Patch
     PRINT "Lower Patch will be"; PatchOne
    
     PRINT
     PRINT "And select the patch to use as the upper patch.  Press the patch on your"
     PRINT "keyboard ... ";
     GOSUB SelectPatch: PatchTwo = Patch
     PRINT "Upper Patch will be"; PatchTwo
    
     PRINT
     PRINT
     PRINT "Split established.  You may now play the keyboard or select new."
     PRINT "Press Esc on the computer's keyboard to exit."
  
     'IMPORTANT NOTE:
     'Some midi instruments save time by sending command changes only when
     'the command changes to another type of command. For example, if playing
     'a series of notes, MIDI might receive a 144 60 64 meaning 144 (command
     'to turn note on), 60 (Note to play), and 64 (Velocity). A subsequent
     'key pressed would send only two bytes - Note and Velocity.  Until you
     'change the commands, like patch change, only two bytes will be sent.
     'Your programs must be ready to receive these three and two byte
     'commands and treat them accordingly.  The following uses flags as
     'toggles to determine statuc of commands being received.

     DO
          GOSUB WaitForMidiData                             'Wait for midi
          IF Value > 127 THEN                               'If command then
               NoteOnOff = False                            'Turn off flags
               PatchChange = False
               SELECT CASE Value                            'See what command
               CASE IS = 144                                'was sent. If Note
                    NoteOnOff = True                        'on/off then set
                    GOSUB WaitForMidiData                   'flag, and get Note
              
               CASE IS = 192                                'If Patch change then
                    GOSUB WaitForMidiData                   'Get patch number
                    IF UsingPatchOne THEN                   'Depending on what
                         PatchOne = Value                   'patch is active,
                    ELSE                                    'change value to
                         PatchTwo = Value                   'new patch selected
                    END IF
               END SELECT
          END IF
          IF NoteOnOff THEN                                 'If note was pressed
               Note = Value                                 'Set note = to Value captured above
               GOSUB WaitForMidiData: Velocity = Value      'Get the Velocity
          END IF
          IF OldNote THEN CALL PlayNote(OldNote, 0)         'Turn off old note
          OldNote = Note                                    'Set old note to note
         
         
          IF UsingPatchOne THEN                             'Based on patch
               IF (Note <= SplitAtKeyNumber) THEN           'currently in use,
                    CALL PlayNote(Note, Velocity)           'either play the
               ELSE                                         'note or make a
                    CALL ChangePatchTo(PatchTwo)            'Patch change and play
                    UsingPatchOne = False                   'the note
                    CALL PlayNote(Note, Velocity)
               END IF
         
          ELSE                                              'Ditto, except Not
               IF Note <= SplitAtKeyNumber THEN             'using PatchOne
                    CALL ChangePatchTo(PatchOne)
                    UsingPatchOne = True
                    CALL PlayNote(Note, Velocity)
               ELSE
                    CALL PlayNote(Note, Velocity)
               END IF
          END IF
     LOOP
  

WaitForMidiData:                                            'Wait for any midi
     DO                                                     'info
          CALL ReceiveMidiData(Value)                       'Since ReceiveMidiData
                                                            'returns -1 if idle, wait
                                                            'for >-1 to exit loop
          IF INKEY$ = CHR$(27) THEN GOTO Ending             'Unless they press ESC
     LOOP UNTIL Value > True                                'Wait for Value >-1
     RETURN


SelectKeyForSplit:
     DO                                                     'Wait for keypress
          GOSUB WaitForMidiData                             'On MIDI keyboard
          IF Value = 144 THEN
               GOSUB WaitForMidiData
               SplitAtKeyNumber = Value                     'and set split at
          END IF                                            'the key pressed
     LOOP UNTIL (SplitAtKeyNumber > 0)
     RETURN

SelectPatch:                                                'Select patch. Note
                                                            'that this will
                                                            'catch accidental
                                                            'keyboard presses
                                                            'between time we
                                                            'select first patch
                                                            'and second
     Patch = False
     DO
          GOSUB WaitForMidiData                             'Wait for midi
          IF Value > 127 THEN                               'If command
               IF Value <> 192 THEN                         'and not patch
                    PatchSelect = False                     'set flag off
               ELSE                                         'otherwise
                    PatchSelect = True                      'set flag true
                    GOSUB WaitForMidiData                   'and get patch value
               END IF
          END IF
          IF PatchSelect = True THEN                        'If patch select
               Patch = Value                                'then Value will be
          END IF                                            'patch selected
     LOOP UNTIL (Patch > 0)
     RETURN


Ending:
     CALL AllNotesOff                                       'Don't leave any on
     END

