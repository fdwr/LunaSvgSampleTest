Dw's comments on BirthRight

	'     now remember this game is still in the makeing and I have been
	'rushing throw it and have not had the time to spell check it.
That's allright, you have the will. Wait a minute, you are the very essence of 'will'. cheap pun :-)

	DECLARE SUB Intro ()
	DECLARE SUB Weapons ()
	DECLARE SUB Info ()
You need to be able to call this one at any time; at least you have it though.

	DECLARE SUB level1 ()
	DECLARE SUB level2 ()
So are you ready to add a level three?

	CALL level1
Eventually you might want to have a pause between levels so that the user can save his game or go to the bathroom or something. Just kidding about the bathroom one.
	CALL level2

It is not necessary to waste so much space in each of the creature titles to indent them over (in the 'info' sub). Rather than printing out 27 spaces manually, just use TAB to indent it. For example:
	PRINT "                           THE MERCURY DRAGON     "

	PRINT TAB(28);"THE MERCURY DRAGON     "

TAB simply moves the cursor the the 28th column by printing out 27 spaces for you. It sure beats typing out all those spaces, and it saves 'space' too. Yes, another cheap pun. :-)

Alternatively, you could use the LOCATE statement to preset the cursor for you and then use PRINT. On a few of your screens (in the 'info' sub), you use one or two PRINTs to move the cursor down, and then spaces to move it over for the creatures title.
	CLS
	PRINT
	PRINT
	PRINT "                             WATER KIN"

	CLS
	LOCATE 3,28 'Set the cursor down to row 3 and right to column 28
	PRINT "Water Kin"
 
A lot of labels are wasted by simple key waiting loops in quite a few subs. Instead of GOTO statements, try the DO or WHILE loop.
	20 IF INKEY$ = "" GOTO 20

	DO WHILE INKEY$ = "":LOOP
		or
	DO: LOOP INKEY$ > ""

The first loop loops as long as INKEY$ is equal to null; the second waits until INKEY$ is greater than null (the actual keypress can be anything, as long as it is greater than nothingness). Bty, to support older versions of BASIC, it includes another syntax of the first loop above.
	WHILE INKEY$="":WEND
Same thing, just a little shorter. I think 'WEND' stands for 'WHILE END'..?

That string below, I do not think is actually long enough to freeze your program; but if you have any after that, they are cumalative. So two PLAY statements, even though they may separated by commands in between, actually act like one if there is nothing to pause between them.
	PLAY "MB l16bl16cdl16cl16del16dl16efl16gl16fel16el16dcl16dl16cb"

Try not to play such long strings though...if you play more than 32 notes at time, it will overflow the buffer and freeze your program until they are all played. Sometimes, that might be what you want, the program to wait until all the notes are played. Maybe there is a demo or little story that you only want to come up once the song has had a chance to finish. If you do that though, it also stops the user from pressing a key and being able to bypass the song (especially if he's already heard the annoying song and wants to get right into playing your game). In that case you could use a loop that tested for a key that has been pressed or until the notes are all played.

Using the PLAY function will tell us how many notes wait in the play buffer (remember, the play buffer can hold a max of 32 notes in background mode). Note that there is a difference between the function and the statement...as a statement it plays notes, as a function it returns how notes are remain to be played.
	PLAY "MB L4EDCDEEEP4DDDP4EGGP4EDCDEEEP4EDDEDC"
Plays 'Mary Had a Little Lamb'
	LISTEN$ = "T180 o2 P2 P8 L8 GGG L2 E-"
	FATE$ = "P24 P8 L8 FFF L2 D"
	PLAY LISTEN$ + FATE$
Plays the first few notes of Beethoven's Fifth Symphony
	NotesRemaining = PLAY(0)
Returns how many notes remain at the time it was called. If you call it after the song has stopped, it will return zero, simply meaning there are notes left and nothing is currently playing. You can use that as a test to tell when your song has stopped (if you ever need to). Don't ask me why you're supposed to include the silly parenthesis with a zero. The zero can actually be anything - all I know is that is the way it works. (:-\

If each note in your song is the same length, it is not necessary include a length behind each one. Once the length for the average note is set with an 'L?', simply place the notes.
	PLAY "MB l16bl16cdl16cl16del16dl16efl16gl16fel16el16dcl16dl16cb"
Long and hard to read
	PLAY "MB L16bcdcdedefgfeedcdcb"
Shorter and easier to read

Only if you want to change the length of the notes do you need to include the length; however for pauses, you must always include the length. (:-\
	PLAY "MB L16cccdddL4eeegggP6ffeeddccccc"
No, that isn't really a song. It firsts plays six sixteenths and then seventeen quarter notes, but only set the length twice.

If you want to just change one note out of the norm, simply include the length after that one individual note.
	PLAY "MB L16ededecg1ededcdegc1"
Most of the notes are sixteenths, but two need to be whole notes

Once you have defined the music to be in the background, you don't need again.
The old way:
	PLAY "MBT160O1L8CDEDCDL4ECCC>"
	FOR I = 1 TO 2
	    PLAY "MBL8EL4EEL8CL4EL2G<G"
	NEXT I
Include this statement in your MAIN sub before you call any others and it sets all other play statements that follow to background for you (unless of course you change it back and turn background off, but why would anyone want to do that?).
	PLAY "MB"
Then the following statements
	PLAY "T160O1L8CDEDCDL4ECCC>"
	FOR I = 1 TO 2
	    PLAY "L8EL4EEL8CL4EL2G<G"
	NEXT I
Bty, good use of octaves.

These would be interesting squares if your game wasn't a game.
	FOR I% = 1 TO 1000
	    X1% = INT(RND * 320)
	    X2% = INT(RND * 320)
	    Y1% = INT(RND * 200)
	    Y2% = INT(RND * 200)
	    COL% = INT(RND * 256)
	    LINE (X1%, Y1%)-(X2%, Y2%), COL%
	NEXT I%
For a game though, wouldn't an opening story be better?
Bty, where did you get that snippet of code?

Try to keep your  introduction in the MAIN sub or another rather than the smaller ones like individual levels. If you ever make your game to where a player can save their progress and the current level they are on, you won't want the main intro to be on level one and nothing on any of the others. If would be fine though for each level to have its own intro.
	SUB OpeningTitle ()
	    CLS
	    COLOR 15
	    FOR I% = 1 TO 3
	        PLAY "L16bcdcdedefgfeedcdcb"
	    NEXT I%
	    LOCATE 11,10
	    PRINT "Made by Firewalker-911"; 'Whoever that is?
	    LOCATE 16,6
	    PRINT "Annoying music, is it not? :-P"; '  :-\    :-)    :-(    >:-|
	    LOCATE 19,8
	    PRINT "Press any key to continue."
	    Text$="<< Birthright >>"
	    TitleColumn = 40 - (LEN(Text$) \ 2) 'This simple formula centers it for you
	    TitleColor = 9 'Bright blue color
	    DO 'This little loop flashes your title in six different colors until a key is pressed
	        IF TitleColor => 14 THEN TitleColor = 9 ELSE TitleColor = TitleColor + 1
	        COLOR TitleColor 
	        LOCATE 3, TitleColumn: PRINT Text$;	        
	    LOOP UNTIL LEN(INKEY$)
	END SUB

Also, if you do a lot of centering and don't want to calculate each row:col position manually, try using a SUB that does it for you. Just pass onto it the text to be printed and the line you want it on.
	SUB Center ()
	    : ScreenWidth = 40 '<- Just for this particular demo
	    'The width depends on your current screen mode
	    IF LEN(Text$) > ScreenWidth THEN
	        LOCATE Row,1 'Set cursor the first column on the left
	        PRINT LEFT$(Text$, ScreenWidth); 'Print only the first 40 left characters of text$
	    ELSE
	        LOCATE Row, ScreenWidth - (LEN(Text$) \ 2) + 1
	        'Center cursor to column and add one, since the first column is one and not zero
	        PRINT Text$;
	    END IF
	END SUB

You have some good maps; it's a shame that the user can only access them once and they are gone forever.

Good job on the writing - it must have taken a while. I'm not worried about the spelling mistakes since they are always easy to correct (fixing spelling mistakes is a lot easier than debugging a program!).

Well, I'm sure that was more than enough for you to digest. There is more I could say, but (a) I want to just worry about the main things first and (b) I don't want to lose a friend by talking on and on. If you would like, we'll talk about some other things as the game procedes? That other guy had good comments too! How long have you known Qb commands? Like he said, great for a newbie. Bty, what was the name of his game that he was going to send to you?