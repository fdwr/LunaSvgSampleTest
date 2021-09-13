'by William Garlow
 PLAY "MBT160O1L8CDEDCDL4ECCC>"   'Seems you got the music down well.
                                  'Also, check out the command SOUND
                                  'to specify a pitch and duration.
 FOR i = 1 TO 2
 PLAY "MBL8EL4EEL8CL4EL2G<G"
NEXT i

SCREEN 12                   'These four lines are unnecessary.
PRINT                       'When you change screen modes, it automatically
PRINT                       'clears the screen.
PRINT
RANDOMIZE TIMER
SCREEN 13
FOR i% = 1 TO 1000
  X1% = INT(RND * 320)
  X2% = INT(RND * 320)
  Y1% = INT(RND * 200)
  Y2% = INT(RND * 200)
  COL% = INT(RND * 256)
  LINE (X1%, Y1%)-(X2%, Y2%), COL%
NEXT i%
              PLAY "MBT160O1L8CDEDCDL4ECCC>"
              FOR i = 1 TO 2
              PLAY "MBL8EL4EEL8CL4EL2G<G"
              NEXT i
CLS
SCREEN 13
FOR i% = 1 TO 500
  X1% = INT(RND * 320)
  X2% = INT(RND * 320)
  Y1% = INT(RND * 200)
  Y2% = INT(RND * 200)
  COL% = INT(RND * 256)
  LINE (X1%, Y1%)-(X2%, Y2%), COL%, BF
NEXT i%
              PLAY "MBT160O1L8CDEDCDL4ECCC>"
              FOR i = 1 TO 2
              PLAY "MBL8EL4EEL8CL4EL2G<G"
              NEXT i
CLS
SCREEN 13
FOR i% = 1 TO 1000               'Okay. I think we've firnly established
  X1% = INT(RND * 320)           'that you're the undisputed master of
  X2% = INT(RND * 320)           'video pyrotechnics. Very cool.
  Y1% = INT(RND * 200)           '(Unfortunately, these sequences don't really
  Y2% = INT(RND * 200)           'go with the game, but who cares any way?)
  COL% = INT(RND * 256)
  LINE (X1%, Y1%)-(X2%, Y2%), COL%, B
NEXT i%
FOR i% = 1 TO 5
PRINT
NEXT i%
PRINT "       Press any key to continue.                                     "
FOR i% = 1 TO 5
PRINT
NEXT i%
2 a$ = INKEY$: IF a$ = "" THEN GOTO 2

    SCREEN 13
     CLS
     COLOR 4
    PRINT
    PRINT
    PLAY "MBT160O1L8CDEDCDL4ECC"
    PRINT
    PRINT "             BIRTHRIGHT"
    FOR i% = 1 TO 3
    PLAY "l16bl16cdl16cl16del16dl16efl16gl16fel16el16dcl16dl16cb" 'Cool effect
    NEXT i%
    PRINT
    PRINT
    PRINT
    PRINT
    PRINT
    PRINT
    PRINT
    PRINT "         Made by Firewalker-911"
    PRINT
    PRINT
    PRINT
    PRINT
    PRINT "     Annoying music, is it not? :-P" 'Hehe! I was thinking the same
                                                'thing. You need something
                                                'besides Mario Brothers
                                                'and the 1812 Overture
                                                'for D&D. Oh, well. It's not
                                                'Important now.
    PRINT
    PRINT
    PRINT "       Press any key to continue."
3 a$ = INKEY$: IF a$ = "" THEN GOTO 3   'Have to be different, dontcha? Most people choose 10 as their first label #. :)

     CLS
     PRINT
     PRINT
     INPUT "Your name"; NAME$    'A good option. Expect people to input 69me though. :(
     PLAY "MBT160O1L8CDEDCDL4ECC"
     PRINT
     PRINT
     PRINT
  ' EXPERIENCE
    EP% = 90
  ' MO% = money
    MO% = 120
    RANDOMIZE TIMER
    TH% = INT(RND * 20) + 10    'VERY cool. Who needs dice? But maybe you should
    CO% = INT(RND * 20) + 10    'include a point pool that people can up certain
    WI% = INT(RND * 20) + 10    'stats that they choose when you get more advanced at
    DX% = INT(RND * 20) + 10    'this programming thing. That would be a worthwhile challenge.
    ST% = INT(RND * 25) + 10    'Also, it gives the player the feeling that they have some control over
    in% = INT(RND * 50) + 50    'their life. (But we know the truth, don't we, Willy? VWAHAHAHahahahaha! (Creepy laugh))
    PRINT
    PRINT "É====»"
    PRINT "º"; ST%; "º = STRENGTH"     'Hey, did I ever explain the whole variable endings thing?
    PRINT "º----º"                     'There are five different variable endings: !, #, $, %, &.
    PRINT "º"; DX%; "º = DEXTERITY"    '% is a short integer. To the computer it's any non-decimal number
    PRINT "º----º"                     'in the range of -32768 to 32767. & is a long integer, which
    PRINT "º"; WI%; "º = WISDOM"       'is any non-decimal numberin the range of -2,147,483,648 to 2,147,483,647.
    PRINT "º----º"                     '! is a single precision number. This is a number with a decimal point that's in
    PRINT "º"; CO%; "º = CHARISMA"     'the range of -2.802597E-45 to 3.402823E+38 with up to seven digits of significance.
    PRINT "º----º"                     'E means "times ten to the power of". If none of this makes sense to you, don't worry about it.
    PRINT "º"; TH%; "º = THIEVING skills"       'Just use ! when you're dealing with decimal numbers. But if you want to learn more about it,
    PRINT "º----º"                     'look up scientific notation and significant digits in your math or science book, or just ask me.
    PRINT "º"; in%; "º = INTELLIGENCE" '# is a double precision number: a decimal number in the range of -4.940656458412465D-324 to
    PRINT "È====¼ "                    '1.79769313486231D+308 with up to 15 digits of significance. D means the same thing as E,
    PRINT                              'only you use it with double precision numbers. Confusing, huh? Anyway, you only need to use double precision number when dealing
    PRINT                              'with very LARGE numbers or very SMALL numbers, which neither of us will probably be doing soon, so I wouldn't worry too much about it.
                                       'And finally $ is a string integers, for assigning characters instead of numbers.
                                       'If you don't put !, #, $, %, or & at the end of your variable, the program will assume it's a single precision variable.
    PRINT " Press any key to continue."
4 a$ = INKEY$: IF a$ = "" THEN GOTO 4
   
    CLS
SCREEN 8   'Screen 8 gives you a resolution of 640x200 with 80 characters per line, in case you didn't know.
COLOR
   PRINT
   PLAY "MBT160O1L8CDEDCDL4ECC"
   PRINT
   PRINT
   PRINT "      "; NAME$; " steps out onto the deck of the Titanic just in time to see a"
   PRINT "flock of small sea gulls fly over with their nine foot wing spain. The sun is"
   PRINT "shining in the blood red sky. When all of the sudden a baby black sea dragon"
   PRINT "jumps out of its dark blue home grabbing three sea gulls before it retreats"
   PRINT "to the depths from which it came. You think to yourself it is a normal day in"
   PRINT "the life of an adventurer."
   PRINT "      You step off the boat to see a open market ahead of you where the old"
   PRINT "hangers tower, in the middle of the sqaure. You look left to see more docks."
   PRINT "You look right only to see a large boat unloading its finds, a large red sea"
   PRINT "dragon that has to be about a hundred feet long with nine inch fangs. You"
   PRINT "take a long look at the Titanic which has been your home for almost a year."
   PRINT "      You look around to see nothing unusual so far. You start on your walk too"
   PRINT "the castle, which is next to the tower on Blood Road. There is a BAR on your"
   PRINT "left under the castle but the entrance to the castle is on the other side."
   PRINT "There is also a free INN at the end of the street. You look up just like"
   PRINT "everyone to see whats going on at the tower. It looks as if it's ready for a"
   PRINT "hanging."
   PRINT
   PRINT "Press any key to continue."
   'I just want to stop and say that I am in awe at your writing skills. I never would have expected such vivid
   'imagery from someone so young. Your intro here is great. It really works to set the mood. You and Liz both seem to have this natural knack for detail.
5 a$ = INKEY$: IF a$ = "" THEN GOTO 5
   

COLOR
CLS
PRINT
    scale$ = "CDEFGAB"   'Hehe! A scale. Man, you're using VARPTR$ already. You're well on your way.
    PLAY "L16"
    FOR i% = 0 TO 6
        PLAY "O" + STR$(i%)
        PLAY "X" + VARPTR$(scale$)
    NEXT i%                     'You might want to set it in the background though. Even the shortest wait can grow tiresome after playing many games.
PRINT
PRINT
PRINT
PRINT "                              MAP OF LUZER VILLE."
PRINT
PRINT "         É====================================Ë=====================»"
PRINT "         º                                 B  º      INN            º"
PRINT "         º  É===========================»  L  º---------------------º"
PRINT "         º  º     CASTLE                º  O  º      HOMES          º"
PRINT "         º  º           É===============º (O) º                     º"
PRINT "         º  º           º               º  D  º---------------------º"
PRINT "         º  º           º     BAR       º     º      DOCKS          º"
PRINT "         º              º               º  R. º                     º"
PRINT "         º--------------Ê---------------Ê     Ê---------------------º"
PRINT "         È==========================================================¼"
PRINT
PRINT "( ) = TOWER"
PRINT           'The visual is good. Perhaps you should give the option to visit all those places in the future.
                'Also, I was thinking, perhaps you could include a menu system where one could type in a certain letter,
                'and the games gives them the option to check their inventory, determine the time of day, or look at their map or whatnot.
                'You could include a sub for the menu later.
PRINT "So what is it "; NAME$; "? the bar = 1, or the hanging = 2 ?"
PRINT
INPUT "The choice is yours! 1, 2 ? ", choice$
        'Speaking of SUBS, I've learned how to do one form of subroutine.
        '(though I just noticed you've learned how to also.)
        'Anyway, you can call a subroutine by including the code
        'GOSUB ThisSub       'Of course, ThisSub could be any variable.
        'Then, after the END statement of your program, you define your
        'subroutine by typing ThisSub:     'That is, the sub name with a colon afterwards
        '                       code
        '                       code
        '                       more code
        '                     RETURN    'You type RETURN when you're done. It tells the program to go back to the main program and continue.
        CLS
        IF choice$ = "2" THEN
        PRINT
        scale$ = "MB CDEFGAB"
        PLAY "L16"
        FOR i% = 0 TO 6
            PLAY "O" + STR$(i%)
            PLAY "X" + VARPTR$(scale$)
        NEXT i%
        PRINT
        PRINT
        PRINT "   OKAY "; NAME$; ", you look up at the hundred foot tower a in great amazment"
        PRINT "as they bring out the will be victim of the gullows. You ask a man standing next"
        PRINT "to you what's going on, he replies, 'That there man is going to be hung becasue"
        PRINT "he has run out of hands to chop off from stealing and you would think that would"
        PRINT "stop him but no he was stuffing buns fresh from the oven down his shirt when"
        PRINT "he could no longer stand the heat he screamed and all the bread fell out right"
        PRINT "at the store owner's feet.' You look back up at the man as they put the black"
        PRINT "mask on his face and think how did he steal with no hands? They hook the red"
        PRINT "blood socked rope up to his neck and move him into place. The King pokes his"
        PRINT "head out of his royal window. A man in a egually black mask steps out of a"
        PRINT "small hut at the top of the tower. He looks at the King and as the King's hand"
        PRINT "falls so does the man. The thief goes into a mad rage and breaks his hands"
        PRINT "lose and starts to reach for the rope but he's dead before he could ever get"
        PRINT "them one the red rope."
        PRINT "    The guards then proceed to cut the rope so they can hang a new one; because"
        PRINT "after six hangings the rope gets a little weak. The dead body starts to fall"
        PRINT "and in your mind it's all in slow motion. The body lands at your feet and you"
        PRINT "jump back so not to get any blood on your new jeans. Thats the end of it for"
        PRINT "you and that man that lays in pieces at your feet with his last regquest to"
        PRINT "have his sword by his side. You look at the finely crfted metal and then pick"
        PRINT "it up.    YOU NOW HAVE A SWORD"
'Very brutal. I liked how the guy told the story about stealing the buns. I felt sorry for the thief though. I wanted to be able to jump in and try to save him.
        SW% = 1
        PRINT
        INPUT "TO go on press 1? ", choice$   'Of course, you'll want to change this to "Press any key to continue."
                                              'This could also be done by saying CHOICE$ = "1"
        END IF
'When you get better with subs, you should make all of these choices subs. It will keep the program more manageable.
'Also, you should run a check to make sure that if you give someone the choice to pick 1 or 2, that they
'do not pick 3. I do that in my program, so you can see how to do it. You don't want people to cheat, after all. :)


        CLS
     IF choice$ = "1" THEN
        PRINT
        PRINT
        PLAY "MBT160O1L8CDEDCDL4ECC"
        PRINT "     "; NAME$; " you step into the bar and hit the ground just in time so not to"
        PRINT "be hit be a flying bench that looks by flight path to of come from a fight in"
        PRINT "the back corners something like all the sides of a six sided dice where sixes."
        PRINT "The look around to see what's going on in other parts of the room and notices"
        PRINT "the dimly lighted corner where you see people exchange large amounts of money."
        PRINT "You scan back across the room and see the bartender knock some poor guys teeth"
        PRINT "out of his mouth and serve them to him in a mug."
                  'What a violent imagination. I, personally, like that teeth in the mug thing at the end. Wish I would've thought of it myself.
        PRINT
        PRINT "To go over to the bar press 3 ? "
        PRINT
        INPUT " So what is it? ", choice$
        END IF

CLS
IF choice$ = "3" THEN
PRINT
    scale$ = "BAGFEDC"
    PLAY "L16"
    FOR i% = 0 TO 6
        PLAY "O" + STR$(i%)
        PLAY "X" + VARPTR$(scale$)
    NEXT i%
PRINT
PRINT
PRINT "     You walk over to the bar and ask the bartender, 'Yo, man give me a drink.'"
PRINT " The bartender response to that statement was in polite terms, I don't think"
PRINT "you can handle a drink boy and he slides you the house special which will"
PRINT "cost you ten dollars. You eagerly gulp down the drink faster then he gave"
PRINT "it to you but even faster was the way it came back up all over the table, the"
PRINT "bartender begins to laugh. You jump up at of your seat and shout, 'You stuck"
PRINT "something in my drink! His respones to that was 'Oh, you won't to make something"
PRINT "out of it boy; get out of my bar!"
PRINT
PRINT " Money remaining"; MO% - 10
PRINT
INPUT " Do you stay and fight = 4 or do you leave like a chiken = 5 ?", choice$
END IF
        'The spitting the drink back out was well-done. You shouldn't assume that the player is male though.
        'Either give the player a choice at the beginning as to be male or female, or make the conversation non-gender indicative.
        'One more thing: The narrator seems biased when offering the choice to stay or leave. Perhaps the bartender
        'should say, "Do ye wanna stay an' fight? Or will ye run like a chicken?" That would seem more characteristic of him.
     CLS
     IF choice$ = "4" THEN
       IF SW% = 1 THEN
       scale$ = "BAGAGEGEFEFDDFDCDCBCBAF"
       PLAY "L16"
       FOR i% = 0 TO 6
       PLAY "O" + STR$(i%)
       PLAY "X" + VARPTR$(scale$)
       NEXT i%
       PRINT
       PRINT "    'OK boy lets go just you and me.' You say in respons, 'Ok as you draw your"
       PRINT "sword and piont it right at his throat. He moves very quick and grabs his knife"
       PRINT "but he is not quick enuff for your reflecktions and you push down cutting his"
       PRINT "throat strat throught with bairly any effort. A red stream of blood is being"
       PRINT "pumped out of his black hart and onto your new used sword which until now was"
       PRINT "black as night. YOU withdraw your blad from his neck and wach his life less body"
       PRINT "fall down to the ground like a rock. Seeing what you did, you wip your blad on"
       PRINT "his countertop and think to yourself, I did good."
       PRINT
       PRINT " EXPRIENCE WENT TO->", EP% + 50
       'Um, you DIDN'T do good. Most DM's would consider that an evil act that would redefine your alignment.
       'You should give the player the choice to kill him or let him live. A "good" player might challenge the bartender
       'but let him off the hook after he yields, while an "evil" character would gladly do him in, and think an evil though like, "I did good."
       'But, then, perhaps he would have to pay the penalty of becoming wanted for murder.
       PRINT
       INPUT "Type 5. ", choice$
       END IF
       IF SW% = 0 THEN
       PRINT
       PRINT
       PRINT "   ' Oh, leave me alone you little shrimp.' He Then proceds to pick you up by"
       PRINT "your paints and throws you out side angered and dissmad."
       PRINT      'If I try to fight, it makes me get kicked out. Something's wrong.
       INPUT " TYPE 6. ", choice$
       PRINT
       END IF
     END IF

CLS
IF choice$ = "6" THEN
PALETTE 0, 1
SCREEN 1
FOR i% = 0 TO 3: a%(i%) = i%: NEXT i%
LINE (138, 35)-(288, 165), 3, BF
LINE (20, 10)-(160, 100), 2, BF
DO
FOR i% = 0 TO 3
a%(i%) = (a%(i%) + 1) MOD 16
NEXT i%
PALETTE USING a%(0)
LOOP WHILE INKEY$ = ""
END IF
SCREEN 8
COLOR
    scale$ = "CDEFGAB"
    PLAY "L16"
    FOR i% = 0 TO 6
        PLAY "O" + STR$(i%)
        PLAY "X" + VARPTR$(scale$)
    NEXT i%
PRINT
PRINT
PRINT
PRINT
INPUT " Type 5.>", choice$
   
    CLS
    SCREEN 8
    COLOR
    IF choice$ = "5" THEN
    scale$ = "BAGFEDC"
    PLAY "L16"
    FOR i% = 0 TO 6
        PLAY "O" + STR$(i%)
        PLAY "X" + VARPTR$(scale$)
    NEXT i%
    PRINT
    PRINT "   You start out on the red brick road on your way to the free Inn at the end of"
    PRINT "the streat. You pass many stands that are selling the same old goods as when you"
    PRINT "left but there is one difference and that is that thye people all sem to be in"
    PRINT " the wores mood that you have ever seen someone in even worse then the one the"
    PRINT "bartender was in. You reach the Inn and walk in to see that it is well done up"
    PRINT "for a free Inn probley the best you have ever seen and it sems to be doing very"
    PRINT "well off of its food, which is the only way it makes money."
    PRINT "   You check in to a room and go up for a good nights rest and in the morning"
    PRINT "you will see the King about work in his old job as a ELITE LUZER VILLE INFANTRY"
    PRINT "solder"
    PRINT
    PRINT
    PRINT "Press any key to continue."
13 a$ = INKEY$: IF a$ = "" THEN GOTO 13
    PRINT
    END IF


    CLS
    PRINT
    scale$ = "BAGAGEGEFEFDDFDCDCBCBAF"
    PLAY "L16"
    FOR i% = 0 TO 6
    PLAY "O" + STR$(i%)
    PLAY "X" + VARPTR$(scale$)
    NEXT i%
    PRINT "    You wake up from a deep nights rest and start out on your way to the castle."
    PRINT "Since you are no longer on Blood Road you are back to nice black bricks for a"
    PRINT "road. On both sides you see twevl foot walls with ten foot towers on top of them"
    PRINT "that gives it the best view in all the land, from there you can see an army"
    PRINT "comeing from a mile away. You hang a left and head for the main gate were you"
    PRINT "are chceked-in and taken to the main hall in which the King is seated on his"
    PRINT "royal thron, which is made in some parts out of sold gold."
    PRINT "    '"; NAME$; ", how have you been', asked the King. You reply 'I'ave been"
    PRINT "doing fine but I need a job and I was wondering if I could have my old job back"
    PRINT "in your army?' 'You know you can have it back and we realy need people that can"
    PRINT "act under the wire, just like you. I wont you to go to my farest kingdom"
    PRINT "TUARHIVEEL which as you know borders the GORGANS CROWN but you will not be"
    PRINT "fighting him, but his third in command the mountrous Mercury Dragon in the land"
    PRINT "of the mists which he has taken from us.'"
    PRINT "    '"; NAME$; " when you get there I wont you to take countral of my army and"
    PRINT "take back our lands and kill the Mercury Dragon"
    PRINT
    PRINT " press any key."
14 a$ = INKEY$: IF a$ = "" THEN GOTO 14
     PRINT
     PRINT
     PRINT "     Warnig these things may be inportant so you may wont to print them out."
     PRINT ""
     PRINT ""
     PRINT "                      MAP TO THE: LAND OF MISTS"
     PRINT ""
     PRINT "É==============================================================================»"
     PRINT "º                                                               THE            º"
     PRINT "º                                                               GORGANS------> º"
     PRINT "º  brick roads                           paths                  CROWN          º"
     PRINT "ºÄÄÄÄÄÂÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ------------------------Â--------------º"
     PRINT "º     ³       ³±±±± lake of death                               ³              º"
     PRINT "º     ³       ³±±±±                           your    °°°       ³   °°°²°°²°   º"
     PRINT "º     ³       ³                               men     °°°ÄÄÄÄÄÄÄÅ---°°°²²±²±   º"
     PRINT "º     ³       ³                                       °°°           °±²±²±±²   º"
     PRINT "º     ³       ³                                                    LAND OF     º"
     PRINT "º     ³       ³                                                     MISTS      º"
     PRINT "º}ÂÄÄÄÁÄÄÄÄÄÄÄ´                                                                º"
     PRINT "º ³LUZER VILLE³                                                                º"
     PRINT "È==============================================================================¼"
     PRINT
     PRINT " PRESS ANY KEY"
15 a$ = INKEY$: IF a$ = "" THEN GOTO 15
         CLS
         PRINT
         PRINT
         PRINT "                          ITEAMS THAT YOU HAVE"
         PRINT
         PRINT "    The king has given you:"
         PO% = INT(RND * 30) = 15
         SW% = 1
         SH% = 1
         AR% = 100
         HR% = 100
         PRINT
         PRINT "A BASTARD SWORD"
         PRINT "A BODY SHIELD"
         PRINT "PLATE MAIL ARMOR"
         PRINT "A SPERITED YOUNG HORES,"
         PRINT "FOOD."
         PRINT "AN ESCOURT,"
         PRINT "AND A KINGHT HOOD."
         PRINT
         PRINT " STRENGTH =          "; ST% + 10     'The problem with this is
                                                     'that it displays your strength
                                                     '10 points higher than it actually
                                                     'is. You need to say something like
                                                     'ST% = ST% + 10 first.
         PRINT " DEXTERITY =         "; DX%
         PRINT " WISDOM =            "; WI%
         PRINT " CHARISMA =          "; CO%
         PRINT " THIEVING skills =     0"
         PRINT " INTELLIGENCE =      "; in%
         PRINT
         PRINT "Press to go on"
16 a$ = INKEY$: IF a$ = "" THEN GOTO 16
        
         CLS
         PRINT
         SCREEN 8
         COLOR 4
         PRINT
         PRINT "                           THE MERCURY DRAGON     "
         PRINT
         PRINT
         PRINT "size:             25 feet"
         PRINT "diet:             omnivore"
         PRINT "intelligence:     super"
         PRINT "strength:         5000"
         PRINT
         PRINT "    Mercury dragons are fast, highly-maneuverable creatures with relatively"
         PRINT "small bodies and long tails. ALthough good in alignment, they are very"
         PRINT "whimsical, making changing decisions frequently"
         PRINT "    AT birth, a mercury dragon's scales are a dull siver. As it ages, the scales"
         PRINT "become brighter, until adult age they gain brilliant mirror finish. Sunlight or"
         PRINT "other sources of light reflecting off the scales and wings are some times"
         PRINT "blinding."
         PRINT "     Mercury dragons are unpridictable when it comes to combat, as they are in"
         PRINT "any sitution. They may parrly, they might attack instantly, or, perhaps, they"
         PRINT "might avoid combat entirely."
         PRINT
         PRINT " Press any key, back to the game."
17 a$ = INKEY$: IF a$ = "" THEN GOTO 17
        
         CLS
         COLOR 4
         PRINT
         PRINT
         PRINT "                                   ELVES"
         PRINT
         PRINT "     Elves as we call them are a little shortter then us, were they can grow to"
         PRINT "five feet we can grow to nine feet, but some of us never make it to be five feet"
         PRINT "tail. The reson elves are mad at us and hunt us down like dogs if we come on"
         PRINT "there land is becasue when we first came it was like the Brithis and the Indians"
         PRINT "in fact it's just like that exactly like that. We came over and they greated us"
         PRINT "with opean arms take us in, tret us like family and what do we do? Why we take"
         PRINT "there land and push them back, but unlike the Indians, the Elves held there own"
         PRINT "in they took over the nice dennse woods and heald them like no other. If you go"
         PRINT "back there you my be spoted be an Elves kinght and if he finds you, you can kiss"
         PRINT "your head good by."
         PRINT "     Still to day they hold us acountable, which we are, and for that resoan"
         PRINT "they are still found deep in the woods plain the day when they can make there"
         PRINT "move can come out of the woods. They will jion anybudy just to get a chance to"
         PRINT "kill one of us. this is why they rade the nearyby villages and roads not just"
         PRINT "for the food and money, but for the chance to kill a human."
         'Well, I had a few problems with this history, mostly because I don't agree with it. First of all,
         'I don't think you can say that all humans are accountable for the oppression of the elves, since this seems
         'to have happened long ago. The humans of today wouldn't be responsible for taking the elven lands, and would
         'not necessarily be accountable. This is similar to some of today's racial disputes: for example, there are some
         'people who believe that the white people of today owe the black people of today for the slavery that their ancestors
         'had to undergo. I don't agree with this because it would be like saying that you and I owe other people for wrongs
         'that were committed by other people, even though you and I might be opposed to slavery. I think you should explain
         'the taking of the land by the humans and the racial tension between the elves and the humans, but not state a moral opinion
         '(which is something that a narrator shouldn't do in this case, by the way). And you should keep in mind that there are going
         'to be elves and humans who do not hate each other and prove to be the exception to the popular opinion.

         PRINT
         PRINT
         PRINT " you know what to do."
18 a$ = INKEY$: IF a$ = "" THEN GOTO 18
         
          CLS
          PRINT
          PRINT
          PRINT "                                WERETIGERS"
          PRINT
          PRINT "size:              6-9 feet tail"
          PRINT "diet:              carnivore"
          PRINT "intelligence:      high"
          PRINT "climate / terrain: any wildernes"
          PRINT
          PRINT "     Weretigers are humans, usually female, that have the adility to transform"
          PRINT "into tigerlike forms. They have strong affinity for all felines. The human from"
          PRINT "tends to  be sleekly muscular, taller than average, and very agile. The voices"
          PRINT "of weretigers are husky and they tand to roll there R's."
          PRINT "     First form: human with sleek musicals, tail, and they roll there R's."
          PRINT "     Second form: A cat that stands on its hind legs with human features such"
          PRINT "as ther face."
          PRINT "     Third form: no human features they look like a full grown tiger."
          PRINT
          PRINT " press any key"
          PRINT
19 a$ = INKEY$: IF a$ = "" THEN GOTO 19
         
          CLS
          PRINT
          PRINT
          PRINT "                             WATER KIN"
          PRINT
          PRINT "     Many a passer by have been taken to there deaths by these water kins. They"
          PRINT "are water till they touch the air where they  become lovly females for guys"
          PRINT "and hansum men for girls and with there songs they bring you to the water and"
          PRINT "to your death, just for the fun of it."
          PRINT
          PRINT "size:          4-5 feet tail"
          PRINT "diet:          water"
          PRINT "intellignce:   very"
          PRINT
          PRINT "combat:  Water kins can spitb venom 20 feet, blinding a target for a day; the"
          PRINT "venom can be washed away with water only. they countrol water and can turn it"
          PRINT "from hard to soft to grab there victims with and pull you in. They are usualy"
          PRINT "seen with just a white cloth around there necks."
          PRINT
          PRINT "press any key"
20 a$ = INKEY$: IF a$ = "" THEN GOTO 20
         
          CLS
          SCREEN 12
          COLOR 1
          CLS
          SCREEN 8
          COLOR
          scale$ = "BAGAGEGEFEFDDFDCDCBCBAF"
          PLAY "L16"
          FOR i% = 0 TO 6
          PLAY "O" + STR$(i%)
          PLAY "X" + VARPTR$(scale$)
          NEXT i%
          PRINT
          PRINT "     You wake up after a long nights rest in the castle. The sun is just"
          PRINT "startting to rise over Luzer Ville and it's all reday time to start out on the"
          PRINT "long trip to the Land of Mists throw unfrendly Elven country side you now that"
          PRINT "you will need every man in that escourt should the Elves decide to attack."
          PRINT "     You mount your midy steed and start off on the brick road. Once you leave"
          PRINT "the castle walls all you see is farm land on your left and dense woods fare"
          PRINT "away on your right and you remember why the castle was built. When the last"
          PRINT "king lived he needed a fort to stop the elven raids, but when that King hood"
          PRINT "brook up the fort became one of the new kingdoms to form vand is the biggest"
          PRINT "and it still is today and they still have there Elve problem."
          PRINT "     You start to rouned the bend pass the lake of death, but you have no"
          PRINT "idle why they call it the lake of death."
          PRINT ""
          INPUT "speed up = 7 or draw your swords = 8 ? ", choice$
   
    IF choice$ = "8" THEN
          CLS
          PRINT
          PRINT "     You proceed very carefuly watching the woods for Elven riders. You hear"
          PRINT "something so you order swords drawn and be ready to stop an attack. All of"
          PRINT "the shoulden a preaty girl wlaks right up to your men and starts singing the"
          PRINT "most wonderiful song you have ever heard and you start to falla sleep as she"
          PRINT "continues to sing."
          scale$ = "BAGFEDC"
          PLAY "L16"
          FOR i% = 0 TO 6
          PLAY "O" + STR$(i%)
          PLAY "X" + VARPTR$(scale$)
          NEXT i%
          PRINT
          COLOR 1
          PRINT
          INPUT " type 0.  ", choice$
          END IF
   
          CLS
    IF choice$ = "0" THEN
          PRINT
          PLAY "<<l4fdcbcdfdcbl8cl8dl8cl8dl4fdfgdgfdc<l2b"
          PRINT "   You wake up in a cave of some short to see the dead bodies of your escourt"
          PRINT "liying next to you. The cave is very large and semes to be glowing blue and"
          PRINT "green. A youmg girl comes up to you and starts banigong your wounds from when"
          PRINT "you were draged down. You ask her what is going on, her repliy is, 'The water"
          PRINT "kins aren't enemys they are heros, a bunch of elves where whatting for you just"
          PRINT "around the bend with there swords drawn. The water kins saved you by bringing"
          PRINT "you here.' Then what happen to the rest of my men? They tried to fight them and"
          PRINT "wouldn't hold there breath so they drownd as they were brouht down but the rset"
          PRINT "of us went willingly with them and you were a sleep so that made it easy for"
          PRINT "them',she said. What is your name', "; NAME$; " asked. 'Jenifer', the girl"
          PRINT "answerd, 'and yours?' Why my name is "; NAME$; "' you anawerd."
          PRINT "   So you say that the water kin are nice but how come when someone dissapears"
          PRINT "from one we never see them again?', you asked. Jenifer replied, ' once you get"
          PRINT "down here and start to know the people you look back at your life to see how"
          PRINT "hopeless it was liveing under marshall law when you see the buetiy and"
          PRINT "peacefulnes down here."
          PRINT "   Not that I wouln't love to stay down here but an evil dragon is going to kill"
          PRINT "hundreds of people if I don't get to my men and stop him. Is there any way at"
          PRINT "all that I can get out of here?"
          PRINT
          INPUT " TYPE 1. ", CHOICE0000$
          END IF
          'I'm getting a little confused. You've left out some parts of the story.
IF CHOICE0000$ = "1" THEN
         CLS
         PRINT
         PRINT "    'Yes you can none of us are prisoners, we are free to stay or go but once"
         PRINT "you leave you can nevery come back.' Jenifer said. 'I hate to do this since this"
         PRINT "place is so nice with its green-blue walls, but I have to.'you said, 'Weres the"
         PRINT "exite"
         PRINT "    You then proced to the direction see pionted to. You walk about thirty yards"
         PRINT "and come to a lake and on the other side you can see a light. You start out in"
         PRINT "the water its very deep and cold plus there is a thick fog forming that prevents"
         PRINT "you from looking back to see Jenifer waveing good-by."
         PRINT "     You come out of a small hole that caves in right as you get your last foot"
         PRINT "out. You stop to thick about what you just gave up and if it was worth it. You"
         PRINT "come to your senses and remember why you started out on this journy. You allso"
         PRINT "see that you forgot your aromor. You turn around to look at the once hole to"
         PRINT "see janifer standing there holding your armor. She says, 'You dumdy didn't you"
         PRINT "see the dry path, no you had to do it the hard way."
         PRINT
         INPUT " type 2. ", CHOICE0000$
         END IF
      
       IF CHOICE0000$ = "2" THEN
         CLS
         PRINT
         PRINT "                                 JENIFER"
         PRINT
         PRINT
         PRINT " STRENGTH =        45"
         PRINT " DEXTERITY =       25"
         PRINT " WISDOM =          50"
         PRINT " CHARISMA =        80"
         PRINT " THIEVING skills = 90%"
         PRINT " INTELLIGENCE =    89"
         PRINT
         PRINT "Jenifer has"
         PRINT
         PRINT "2 short swords"
         PRINT "a large belt pouch"
         PRINT " food"
         PRINT " and leather aromor"
         PRINT
         INPUT " more of and about JENIFER type 3. ", CHOICE0000$
         END IF    'Jenifer joins you? Cool!

     IF CHOICE0000$ = "3" THEN
         CLS
JENIFER% = 1
         PRINT
         PRINT "                                 JENIFER"
         PRINT
         PRINT "    Jenifer has on a green shirt with her leather armor under it, and a"
         PRINT "brown skert. Her belt pouch hides her two short swords on her back. black soft"
         PRINT "boots ment for sneaking around completes her drees. Jenifer is a nieth leval"
         PRINT "thief her swords are small and very sharp to cut fast and without the person"
         PRINT "noticeing what has been done until they need some money."
         PRINT
         PRINT "                                 Theives"
         PRINT
         PRINT "     Theives are ofthen people who don't fit in elsewhere. Unlike other"
         PRINT "classes, nerly all theives are adventurers, ofthen by necessity. True, many"
         PRINT "settle permanently in a signle area and live off the local population, but"
         PRINT "when your life tends to be in defiance of the law, you have to be ready to"
         PRINT "leave at a moment's notice! ERach job is an adventure involving great risk"
         PRINT "(including, possibly, death), and there are precious few opportunities to"
         PRINT "relax and let your guard down."
         PRINT
         INPUT "To go on type 10.", choice$
         END IF


    IF choice$ = "7" THEN
          CLS
          PRINT
          PRINT
          PRINT "   You hit the gas and take off like a bat out of hell, raceing as fast as"
          PRINT "you can you have no time to look at the lake to see that plane of water just"
          PRINT "miss you and grab the man behind you. You keep on ridding until you are sure"
          PRINT "that you are past the lake and out of harms way"
          PRINT "   You stop to count your men and find that one of them is missing. You ask"
          PRINT "around and the man that was riding in the back tells you that he was grabed"
          PRINT "by this long arm that was made out of water and he was then draged under"
          PRINT "screaming his head off and all that he could see was a women in nothing but"
          PRINT "a white cloth on her shoulders."
          FOR i% = 1 TO 3
          PLAY "mbl16bl16cdl16cl16del16dl16efl16gl16fel16el16dcl16dl16cb"
          NEXT i%
          PLAY "<<<l4b l8bbl4>efl2gl4<bl8bbl4>el8ggl4fd<bbl8bbl4bl8bb>l4efl2g<l2b>fl4ege"
          PRINT
          INPUT "type 9. ", choice$
          END IF

      IF choice$ = "9" THEN
          CLS
          PRINT
          PRINT "    You think your smart, just becasue you got away from that little fight"
          PRINT "so you decide to take a little rest and as you bend over to unroll your"
          PRINT "sleeping bag, that someone let you have by dieing, an arrow hits your"
          PRINT "horse killing it. You grab your shield and draw your sword but the person"
          PRINT "is gone or so you think. From the other direction comes another arrow that"
          PRINT "you block with your sheild. You look around to see how your men are doing."
          PRINT "They have formed a cirlue of sheilds. You continue to scan, your eyes stop"
          PRINT "dead on the road and your mouth drops as you stare at the three elven"
          PRINT "knights at the end of the woods. They start to charge two going for your"
          PRINT "men and one for you. You move your sheild in front and your sword to your"
          PRINT "side. His lance hits your sheild almost nocking you off your feet, but here"
          PRINT "we go again, as he hits you you use the force to spin with the force of a"
          PRINT "dragon. Your blad has so much power it breaks throw his arrmor and he"
          PRINT "retreats to the woods. "
          PRINT "    Your men are doing something else: one of them has a two- handed"
          PRINT "long-sword and he konks them off and the rest jump of him. those two are"
          PRINT "dead, no retreat for them."
          PRINT
          INPUT "You start off again, tpye 10. ", choice$
          PRINT
          END IF

      IF choice$ = "10" THEN
         CLS
         PRINT "                                  YOUR MEN"
         PRINT
         PRINT "     THE NEXT DAY.  Your troops great you and ask, 'what happend?' You say,"
         PRINT "'never mind about that how are we doing?' 'The enemy is in the bog and hills,"
         PRINT "there not hiding they know that we wont go in there without renforcemants.'"
         PRINT "'Thats what they think give me the load down."
         PRINT
         PRINT " MEN:"
         PRINT "4 Archer units,(A)"
         PRINT "5 calvary units,(C)"
         PRINT "10 infantry 4 are elite,(I) (E)"
         PRINT "9 knights thats all of us,(K)"
         PRINT "7 scouts,"
         PRINT "and 4 dwarf archer units.(D)"
         PRINT
         PRINT " go on"
29 a$ = INKEY$: IF a$ = "" THEN GOTO 29
         END IF

         COLOR 4
         PRINT
         PRINT "                                  YOUR ENEMY"
         PRINT
         PRINT "14 Goblin infantry units (GI)"
         PRINT "2 Goblin archer units (GA)"
         PRINT "4 Goblin wolf-riders units (GW)"
         PRINT "2 Elf calvery units (EU)"
         PRINT
         PRINT " Goblins are not good climbers."
         PRINT
         PRINT " press enter"
30 a$ = INKEY$: IF a$ = "" THEN GOTO 30
       
         SCREEN 12
         SCREEN 8
         PRINT
         PRINT "                                  TERRAIN"
         PRINT
         PRINT "                                    BOGS"
         PRINT
         PRINT " No cavalary in bog."
         PRINT
         PRINT "                                    HILLS"
         PRINT
         PRINT " No cavalary, Dwarves are best on a hill."
         PRINT
         PRINT "                                    PATHS"
         PRINT
         PRINT " Great for cavalary."
         PRINT
         PRINT "press enter"
31 a$ = INKEY$: IF a$ = "" THEN GOTO 31

          CLS
          PRINT
          PRINT
          INPUT "do you wish to send out your scouts yes / no. ", CHOICE000$
          PRINT " no caps"
          PRINT

    IF CHOICE000$ = "no" THEN
          PRINT
          PRINT
          PRINT " your stupid"    'Hehe! Don't insult the player, though. If they choose no, give them the advantage of more manpower for the battle or something.
          PRINT
          PRINT
          INPUT "type yes. ", CHOICE000$
          PRINT
          PRINT
          END IF

    IF CHOICE000$ = "yes" THEN
          CLS
          PRINT
          PRINT "                                TERRAIN MAP"
          PRINT "±=bog ²=hills --=path"
          PRINT "É=========================================================================»"
          PRINT "º-----------------------------------------------(1)---------------(EC)----º"
          PRINT "º                                                  (2)  ²²²²²²²²²²²±²²²²  º"
          PRINT "º                                                  (3)   ±±±±±±(GI)±²² ²  º"
          PRINT "º                                                  (4)   ±(GW)±±²²²²² ²   º"
          PRINT "º                                                      (5)   ±²±±²²²²     º"
          PRINT "º                                                    (6)²²²²²²²²²²²²      º"
          PRINT "º                                                   (7)        (GA)      /º"
          PRINT "º                                                                      /  º"
          PRINT "º                                                                    /    º"
          PRINT "º                                                                  /      º"
          PRINT "º   [ ----------------------------------------/----------------- /        º"
          PRINT "º   [                                       /                             º "
          PRINT "º   [                                     / THE GORGANS CROWN             º"
          PRINT "º   [      ELVEN WOODS                  /                                 º"
          PRINT "º   [                                 /                                   º"
          PRINT "È=========================================================================¼"
          PRINT
          PRINT "read this map very carefuly and then go on"
34 a$ = INKEY$: IF a$ = "" THEN GOTO 34
          END IF
          CLS
          PRINT
          PRINT "                                  SUGESTION (1)"
          PRINT
          PRINT " send (D) to 2 fireing to 3."
          PRINT " send (C) to 1 charging on 1."
          PRINT " send (A) (I) to 4 in the bog"
          PRINT " send (E) (K) to 7 killing the archers"
          PRINT
          PRINT
35 a$ = INKEY$: IF a$ = "" THEN GOTO 35
          CLS
          PRINT
          PRINT "                                  SUGESTION (2)"
          PRINT
          PRINT " send (D) to 6 fireing to 7."
          PRINT " send (C) to 1 charging on 1."
          PRINT " send (A) (I) to 7 Killing the archers"
          PRINT " send (E) (K) to 4 into the bog"
          PRINT
          PRINT "you know what to do"
36 a$ = INKEY$: IF a$ = "" THEN GOTO 36
          CLS
          PRINT
          PRINT "                                  SUGESTION (3)"
          PRINT
          PRINT " send (D) to 2 fireing to 3."
          PRINT " send (K) (E) to 1 charging on 1."
          PRINT " send (I) (A) to 4 in the bog"
          PRINT " send (C) to 7 killing archers"
          PRINT
          PRINT " your almost there"
          PRINT
          INPUT " So what is it gedog? ", CHOICE0$

          'You've got some major strategy potential here. I'd like to see where this goes.
   IF CHOICE0$ = "1" THEN
         PRINT ""; MO% + 300
         CLS
         PRINT
         PRINT "     Your plains and your men have just won you a full blown victory that no."
         PRINT "one can say other wise about. Still you find out that the Mercury Dragon that"
         PRINT "you were sent to kill was killed by the GORGAN befor you every had a chance."
         PRINT "     You are well comed back at Luzer Ville. The King as a reword gives you"
         PRINT "a bounes of 300 dollors and a new horse. The King asks you to stay on with"
         PRINT "the army but you turned him down so you could go exploring in the west. You"
         PRINT "look back at the castle and wave goodby to the King as you ride out, but not"
         PRINT "into the sunset, but, the sunrise."
         FOR i% = 1 TO 2
         PLAY "<l4fdcbcdfdcbl8cl8dl8cl8dl4fdfgdgfdcl2b"
         NEXT i%
         PRINT
         PRINT
         INPUT " type 99. ", choice$
         PRINT
     END IF
      
       IF CHOICE0$ = "2" THEN
         PRINT ""; MO% + 300
         CLS
         PRINT
         PRINT "     Your plains and your men have just won you a full blown victory that no."
         PRINT "one can say other wise about. Still you find out that the Mercury Dragon that"
         PRINT "you were sent to kill was killed by the GORGAN before you every had a chance."
         PRINT "Plus some of the goblins got away but not many."
         PRINT "     You are well comed back at Luzer Ville. The King as a reword gives you"
         PRINT "a bounes of 200 dollors and a new horse. The King asks you to stay on with"
         PRINT "the army but you turned him down so you could go exploring in the west. You"
         PRINT "look back at the castle and wave goodby to the King as you ride out, but not"
         PRINT "into the sunset, but, the sunrise."
         FOR i% = 1 TO 2
         PLAY "<l4fdcbcdfdcbl8cl8dl8cl8dl4fdfgdgfdcl2b"
         NEXT i%
         PRINT
         PRINT
         INPUT " type 99. ", choice$
         PRINT
         END IF
  
  
   IF CHOICE0$ = "3" THEN
         PRINT ""; MO% + 300
         CLS
         PRINT
         PRINT "     Your plains and your men have just won you a full blown victory that no."
         PRINT "one can say other wise about. Still you find out that the Mercury Dragon that"
         PRINT "you were sent to kill was killed by the GORGAN befor you every had a chance."
         PRINT "     You are well comed back at Luzer Ville. The King as a reword gives you"
         PRINT "a bounes of 300 dollors and a new horse. The King asks you to stay on with"
         PRINT "the army but you turned him down so you could go exploring in the west. You"
         PRINT "look back at the castle and wave goodby to the King as you ride out, but not"
         PRINT "into the sunset, but, the sunrise."
         FOR i% = 1 TO 2
         PLAY "<l4fdcbcdfdcbl8cl8dl8cl8dl4fdfgdgfdcl2b"
         NEXT i%
         PRINT
         PRINT
         INPUT " type 99. ", choice$
         PRINT
     END IF

    
     IF choice$ = "99" THEN
          SCREEN 13
           COLOR 4
           PRINT
           PRINT "    THE"
           PRINT                'The End? No! This CAN'T be the end already!
           PRINT "           END"
           PRINT
           PRINT " MADE BY: firewalker-911"
           END IF

 'Okay. Here's my synopsis: You've managed to impress the hell out of me. I
 'couldn't believe that you had learned this much and put this whole thing
 'together in so little time. I hope you'll keep working on it. I'm sending
 'you my game, but it palls in comparison, and 'tis very short thus far.
 'Also, hopefully I corrected some of your spelling errors and saved it as another
 'file. You might want to check that file out too.

SUB colors
SCREEN 12
PRINT "Press any key to continue."
RANDOMIZE TIMER
10 a$ = INKEY$: IF a$ = "" THEN GOTO 10
SCREEN 13
FOR i% = 1 TO 100
  X1% = INT(RND * 320)
  X2% = INT(RND * 320)
  Y1% = INT(RND * 200)
  Y2% = INT(RND * 200)
  COL% = INT(RND * 256)
  LINE (X1%, Y1%)-(X2%, Y2%), COL%
NEXT i%
END



    scale$ = "MB CDEFGAB"
    PLAY "L16"
    FOR i% = 0 TO 6
        PLAY "O" + STR$(i%)
        PLAY "X" + VARPTR$(scale$)
    NEXT i%
  
'    PALETTE 0, 1
'    SCREEN 1
'    FOR i% = 0 TO 3: a%(i%) = i%: NEXT i%
'    LINE (138, 35)-(288, 165), 3, BF
 '   LINE (20, 10)-(160, 100), 2, BF
 '   DO
'        FOR i% = 0 TO 3
'            a%(i%) = (a%(i%) + 1) MOD 16
'        NEXT i%
'        PALETTE USING a%(0)
'    LOOP WHILE INKEY$ = ""
''
'    PALETTE 0, 1
'    SCREEN 1
'    FOR i% = 0 TO 3: a%(i%) = i%: NEXT i%
'    LINE (138, 35)-(288, 165), 3, BF
'    LINE (20, 10)-(160, 100), 2, BF
'    DO
'        FOR i% = 0 TO 3
'            a%(i%) = (a%(i%) + 1) MOD 16
'        NEXT i%
'        PALETTE USING a%(0)
 '   LOOP WHILE INKEY$ = ""
'

END SUB

SUB music
        
           scale$ = ">bceedcfagafedc"
           PLAY "l2"
           PLAY "O" + STR$(i%)
           PLAY "X" + VARPTR$(scale$)
         
           PLAY "<bL4cL4dL4eL4fL4gL4abL4aL4gL4fL4eL4dL4cb"
         
           FOR i% = 1 TO 2
           PLAY "<bl4bl4fl8fl8fcl8dl8cbfl4al4bal4fl8gl8efl4el4dl4cl8abl4fl4el4dl4cl8bab"
           NEXT i%
          
            FOR i% = 1 TO 3
            PLAY "l16bl16cdl16cl16del16dl16efl16gl16fel16el16dcl16dl16cb"
            NEXT i%
          
            PLAY "<l4fdcbcdfdcbl8cl8dl8cl8dl4fdfgdgfdcl2b"
           
             FOR i% = 1 TO 2
             PLAY "l4<c<a>l8ccl4<a>l8ccddeel4d<l8aaaa>edc<a>l4c<a>l8ccl4c"
             NEXT i%
            
              PLAY "<l4b l8bbl4>efl2gl4<bl8bbl4>el8ggl4fd<bbl8bbl4bl8bb>l4efl2g<l2b>fl4ege"

END SUB

