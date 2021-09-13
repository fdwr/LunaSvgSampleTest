
'                       BIRTHRIGHT
'
'     now remember this game is still in the makeing and I have been
'rushing throw it and have not had the time to spell check it.
'
'
'
'
DECLARE SUB weapons ()
DECLARE SUB info ()
DECLARE SUB INTRO ()
DECLARE SUB leval2 ()
DECLARE SUB leval1 ()

CALL leval1
CALL leval2

SUB info
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
17 DO: LOOP UNTIL LEN(INKEY$)
      
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
         PRINT
         PRINT
         PRINT " you know what to do."
         DO: LOOP UNTIL LEN(INKEY$)
       
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
        DO: LOOP UNTIL LEN(INKEY$)
       
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
20 DO: LOOP UNTIL LEN(INKEY$)

          CLS
          PRINT
          PRINT "                          GIANT CYCLOPS "
          PRINT
          PRINT "                          Diet: Omnivore"
          PRINT "                         Intellignce: Low"
          PRINT "                             Size: 24'"
          PRINT
          PRINT "     A diminutive rlative of true giants, cyclopskin are single-eyed gaints"
          PRINT "that live alone or in small bands."
          PRINT "     The typical cyclopskin weighs around 400 pounds, and stands 20 feet"
          PRINT "tall. A single large, red eye dominates the center of its forehead. Shaggy"
          PRINT "black or dull, deep blue hair falls in tangled mass about its head and"
          PRINT "shoulders, its skin tone vaires from rubby brown to muddy yellow, and its"
          PRINT "voice is rough and sharp. Cyclopskin commonly dress in ragged animal hides"
          PRINT "and sndals. They smell of equal parts dirt and dung. They as all giants put"
          PRINT "there brothers to rest above ground for more then the digging the hole part"
          PRINT "and they will defend there dead if there near a graveyard."
          PRINT
21 DO: LOOP UNTIL LEN(INKEY$)
          CLS
          PRINT
          PRINT "                            LIVING WALLS"
          PRINT
          PRINT "                         Diet: Assimilation"
          PRINT "                        Intelligence: variable"
          PRINT "                       Size: a rectangular area"
          PRINT
          PRINT "     Living walls appear to be normal walls of stone or brick, although they"
          PRINT "radiate both evil and magic if detected. Infravision will not detect any"
          PRINT "peculiar patterns.However, a charater who casts a true seeing spell or who"
          PRINT "peers through a gem of seeing will see past the illusion: the wall actually"
          PRINT "consists of greying and sinemy flesh of faces, hands, broken bones, feet, toes"
          PRINT "jutting from the surface. characters within 5 yards of the wall can hear the"
          PRINT "low moans of horror, pain, and sorrow issuing from it. Even if a silence spell"
          PRINT "is cast, the moans still rise."
          PRINT "     a living wall contains the melded bodies of humanoids and monsters who"
          PRINT "died within 100 yards of the wall since its cration. The wall usualy also"
          PRINT "countains its makers who could not get away in time when it came to life or"
          PRINT "sub-life."
22 DO: LOOP UNTIL LEN(INKEY$)
          CLS
          PRINT
          PRINT "                           GARGOYLES"
          PRINT
          PRINT "                        Diet: Carnivore"
          PRINT "                       Intellignce: low"
          PRINT "                             Size: 4'-9'"
          PRINT
          PRINT "     These monsters are ferocious and fear less predators of magical nature"
          PRINT "little is known, typically found amid ruins or dwellings in underground"
          PRINT "caverns."
23 DO: LOOP UNTIL LEN(INKEY$)
          CLS
          PRINT
          PRINT "                            WERERATS"
          PRINT
          PRINT "                        Diet: Scazenger"
          PRINT "                     Intelligence: Kind of"
          PRINT "                         Size: 3'-6'"
          PRINT
          PRINT "     Wreerats, also called ratmen, are humans who can transfrom themsleves"
          PRINT "into three forms: human, human-sized ratmen, and gaint rat. They are sly and"
          PRINT "evil, and usally inhabit tunnel complexes beneath cities."
          PRINT "     The wererat's human from tends to be a thin, wiry individual of shorter"
          PRINT "than average height. His eyes constantly dart around, and his nose and mouth"
          PRINT "twich if he is excited. Males often have thin, ragged moustachs."
          PRINT "     The ratman form is somewhat shorter than th human form. The head, torso,"
          PRINT "and tail are identical to those of a rat, but the limbs remain human."
          PRINT "     The thrid form is that of a gaint rat 2 feet tail from nose to rump."
          PRINT "This form is identical to that of a gaint rat. This is the perfeerd from for"
          PRINT "travel and spying on potential victims."
          PRINT
          PRINT
24 DO: LOOP UNTIL LEN(INKEY$)
          CLS
          PRINT
          PRINT "                                SCORPIONS(giant)"
          PRINT
          PRINT "                                Diet: Carnivore"
          PRINT "                               Intelligence: none"
          PRINT "                                   Size: 2'-6'"
          PRINT
          PRINT "     Gaint scorpions are vicious preditors that live almost anywhere,"
          PRINT "including relatively cold places such as dungeons, though they favor"
          PRINT "deserts and warm lands. These creatures are giant versions of the normal"
          PRINT "4 inch-long scorpian found in destert climes. "
          PRINT "     The gaint scprpion has a green carapace and yellowish green legs"
          PRINT "and pincers. The segmented tail is black, with a vicious stinger on the end."
          PRINT "There is a bittier smell associated with the scorpion, which probably comes"
          PRINT "from the venom. They make an unnerving scrabbling sound as they travel across"
          PRINT "dungeon floors."
          PRINT
25 DO: LOOP UNTIL LEN(INKEY$)
          CLS
          PRINT
          PRINT "                                   SKELETONS"
          PRINT
          PRINT "                                   Diet: NIL"
          PRINT "                               Intellignce: none"
          PRINT "                                  Size: 6'-15'"
          PRINT
          PRINT "     All skeletons are magical animated unded monsters, created as guardians"
          PRINT "or warriors by powerful evil wizards and priests."
          PRINT "     Skletons appear to have no ligaments or musculatrue which would allow"
          PRINT "movement. Instead, bones are magically jioned together during the casting of"
          PRINT "an animate dead spell. Skeletons have no eyes or internal organs."
          PRINT "     Skleltons can be made from the bones of humans and demihumans, animals"
          PRINT "of human size or smaller, or giant humanoids like bugbears and gaints."
26 DO: LOOP UNTIL LEN(INKEY$)
          CLS
          PRINT
          PRINT "                                     BASILISK"
          PRINT
          PRINT "                                  Diet: carnivore"
          PRINT "                                    Size:7'-20'"
          PRINT "                                Intelligence: average"
          PRINT
          PRINT "     These reptilian monsters all posses a gaze that enables them to turn any"
          PRINT "fleshy creature into stone."
          PRINT "     Although it has eight legs, its sluggish metabolism allows people to out"
          PRINT "run it. A basilisk is usually dull brown in color, with a yellowish underbelly"
          PRINT "Its eyes glow pale green."
'39 remaning
END SUB

SUB INTRO

  A$ = "*    *    *    *    *    *    *    *    *    *    *    *    *    *    *    *    *    "
  WHILE INKEY$ <> "": WEND 'Clear keyboard buffer

  WHILE INKEY$ = ""
    FOR A = 1 TO 5
      LOCATE 1, 1                             'print horizontal sparkles
      PRINT MID$(A$, A, 80);
      LOCATE 22, 1
      PRINT MID$(A$, 6 - A, 80);

      FOR B = 2 TO 21                         'Print Vertical sparkles
        C = (A + B) MOD 5
        IF C = 1 THEN
          LOCATE B, 80
          PRINT "*";
          LOCATE 23 - B, 1
          PRINT "*";
        ELSE
          LOCATE B, 80
          PRINT " ";
          LOCATE 23 - B, 1
          PRINT " ";
        END IF
      NEXT B
    NEXT A
  WEND

END SUB

SUB leval1
 PLAY "MBT160O1L8CDEDCDL4ECCC>"
 FOR I = 1 TO 2
 PLAY "MBL8EL4EEL8CL4EL2G<G"
NEXT I

RANDOMIZE TIMER
SCREEN 13
FOR I% = 1 TO 1000
  X1% = INT(RND * 320)
  X2% = INT(RND * 320)
  Y1% = INT(RND * 200)
  Y2% = INT(RND * 200)
  COL% = INT(RND * 256)
  LINE (X1%, Y1%)-(X2%, Y2%), COL%
NEXT I%
              PLAY "MBT160O1L8CDEDCDL4ECCC>"
              FOR I = 1 TO 2
              PLAY "MBL8EL4EEL8CL4EL2G<G"
              NEXT I
CLS
SCREEN 13
FOR I% = 1 TO 500
  X1% = INT(RND * 320)
  X2% = INT(RND * 320)
  Y1% = INT(RND * 200)
  Y2% = INT(RND * 200)
  COL% = INT(RND * 256)
  LINE (X1%, Y1%)-(X2%, Y2%), COL%, BF
NEXT I%
              PLAY "MBT160O1L8CDEDCDL4ECCC>"
              FOR I = 1 TO 2
              PLAY "MBL8EL4EEL8CL4EL2G<G"
              NEXT I
CLS
SCREEN 13
FOR I% = 1 TO 1000
  X1% = INT(RND * 320)
  X2% = INT(RND * 320)
  Y1% = INT(RND * 200)
  Y2% = INT(RND * 200)
  COL% = INT(RND * 256)
  LINE (X1%, Y1%)-(X2%, Y2%), COL%, B
NEXT I%
FOR I% = 1 TO 5
PRINT
NEXT I%
PRINT "       Press any key to continue.                                     "
FOR I% = 1 TO 5
PRINT
NEXT I%
2 DO: LOOP UNTIL LEN(INKEY$)

    SCREEN 13
     CLS
     COLOR 4
    PRINT
    PRINT
    PLAY "MBT160O1L8CDEDCDL4ECC"
    PRINT
    PRINT "             BIRTHRIGHT"
    FOR I% = 1 TO 3
    PLAY "MB l16bl16cdl16cl16del16dl16efl16gl16fel16el16dcl16dl16cb"
    NEXT I%
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
    PRINT "     Annoying music, is it not? :-P"
    PRINT
    PRINT
    PRINT "       Press any key to continue."
3 DO: LOOP UNTIL LEN(INKEY$)

     CLS
     PRINT
     PRINT
     INPUT "Your name"; NAME$
     PLAY "MBT160O1L8CDEDCDL4ECC"
     PRINT
     PRINT
     PRINT
  ' EXPERIENCE
    EP% = 90
  ' MO% = money
    MO% = 120
    RANDOMIZE TIMER
    TH% = INT(RND * 20) + 10
    CO% = INT(RND * 20) + 10
    WI% = INT(RND * 20) + 10
    DX% = INT(RND * 20) + 10
    ST% = INT(RND * 25) + 10
    in% = INT(RND * 50) + 50
    PRINT
    PRINT "É====»"
    PRINT "º"; ST%; "º = STRENGTH"
    PRINT "º----º"
    PRINT "º"; DX%; "º = DEXTERITY"
    PRINT "º----º"
    PRINT "º"; WI%; "º = WISDOM"
    PRINT "º----º"
    PRINT "º"; CO%; "º = CHARISMA"
    PRINT "º----º"
    PRINT "º"; TH%; "º = THIEVING skills"
    PRINT "º----º"
    PRINT "º"; in%; "º = INTELLIGENCE"
    PRINT "È====¼ "
    PRINT
    PRINT
    PRINT " Press any key to continue."
4 DO: LOOP UNTIL LEN(INKEY$)
  
    CLS
SCREEN 8
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
5 DO: LOOP UNTIL LEN(INKEY$)
  

COLOR
CLS
PRINT
    scale$ = "MB CDEFGAB"
    PLAY "L16"
    FOR I% = 0 TO 6
        PLAY "O" + STR$(I%)
        PLAY "X" + VARPTR$(scale$)
    NEXT I%
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
PRINT
PRINT "So what is it "; NAME$; "? the bar = 1, or the hanging = 2 ?"
PRINT
INPUT "The choice is yours! 1, 2 ? ", Choice$


        CLS
        IF Choice$ = "2" THEN
        PRINT
        scale$ = "MB CDEFGAB"
        PLAY "L16"
        FOR I% = 0 TO 6
            PLAY "O" + STR$(I%)
            PLAY "X" + VARPTR$(scale$)
        NEXT I%
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
        SW% = 1
        PRINT
        INPUT "TO go on press 1? ", Choice$
        END IF


        CLS
     IF Choice$ = "1" THEN
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
        PRINT
        PRINT "To go over to the bar press 3 ? "
        PRINT
        INPUT " So what is it? ", Choice$
        END IF

CLS
IF Choice$ = "3" THEN
PRINT
    scale$ = "MB BAGFEDC"
    PLAY "L16"
    FOR I% = 0 TO 6
        PLAY "O" + STR$(I%)
        PLAY "X" + VARPTR$(scale$)
    NEXT I%
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
INPUT " Do you stay and fight = 4 or do you leave like a chiken = 5 ?", Choice$
END IF

     CLS
     IF Choice$ = "4" THEN
       IF SW% = 1 THEN
       scale$ = "MB BAGAGEGEFEFDDFDCDCBCBAF"
       PLAY "L16"
       FOR I% = 0 TO 6
       PLAY "O" + STR$(I%)
       PLAY "X" + VARPTR$(scale$)
       NEXT I%
       PRINT
       PRINT "    'OK boy lets go just you and me.' You say in respons, 'Ok as you draw your"
       PRINT "sword and piont it right at his throat. He moves very quick and grabs his knife"
       PRINT "but he is not quick enuff for your reflecktions and you push down cutting his"
       PRINT "throat strat throught with bairly any effort. A red stream of blood is being"
       PRINT "pumped out of his black hart and onto your new used sword which until now was"
       PRINT "black as night. YOU withdraw your blad from his neck and wach his life less body"
       PRINT "fall down to the ground like a rock. Seeing what you did, you wip your blad on"
       PRINT "his countertop and think to yourself was this right?"
       PRINT
       PRINT " EXPRIENCE WENT TO->", EP% + 50
       PRINT
       INPUT "Type 5. ", Choice$
       END IF
       IF SW% = 0 THEN
       PRINT
       PRINT
       PRINT "   ' Oh, leave me alone you little shrimp.' He Then proceds to pick you up by"
       PRINT "your paints and throws you out side angered and dissmad."
       PRINT
       INPUT " TYPE 5. ", Choice$
       PRINT
       END IF
     END IF
  
    CLS
    SCREEN 8
    COLOR
IF Choice$ = "5" THEN
    scale$ = "MB BAGFEDC"
    PLAY "L16"
    FOR I% = 0 TO 6
        PLAY "O" + STR$(I%)
        PLAY "X" + VARPTR$(scale$)
    NEXT I%
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
13 DO: LOOP UNTIL LEN(INKEY$)
    PRINT
    END IF


    CLS
    PRINT
    scale$ = "MB BAGAGEGEFEFDDFDCDCBCBAF"
    PLAY "L16"
    FOR I% = 0 TO 6
    PLAY "O" + STR$(I%)
    PLAY "X" + VARPTR$(scale$)
    NEXT I%
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
14 DO: LOOP UNTIL LEN(INKEY$)
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
15 DO: LOOP UNTIL LEN(INKEY$)
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
         PRINT " STRENGTH =          "; ST% + 10
         PRINT " DEXTERITY =         "; DX%
         PRINT " WISDOM =            "; WI%
         PRINT " CHARISMA =          "; CO%
         PRINT " THIEVING skills =     0"
         PRINT " INTELLIGENCE =      "; in%
         PRINT
         PRINT "Press to go on"
        DO: LOOP UNTIL LEN(INKEY$)
        CALL info
        
          CLS
          SCREEN 8
          COLOR 15
          scale$ = "MB BAGAGEGEFEFDDFDCDCBCBAF"
          PLAY "L16"
          FOR I% = 0 TO 6
          PLAY "O" + STR$(I%)
          PLAY "X" + VARPTR$(scale$)
          NEXT I%
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
          INPUT "speed up = 7 or draw your swords = 8 ? ", Choice$
  
    IF Choice$ = "8" THEN
          CLS
          PRINT
          PRINT "     You proceed very carefuly watching the woods for Elven riders. You hear"
          PRINT "something so you order swords drawn and be ready to stop an attack. All of"
          PRINT "the shoulden a preaty girl wlaks right up to your men and starts singing the"
          PRINT "most wonderiful song you have ever heard and you start to falla sleep as she"
          PRINT "continues to sing."
          scale$ = "MB BAGFEDC"
          PLAY "L16"
          FOR I% = 0 TO 6
          PLAY "O" + STR$(I%)
          PLAY "X" + VARPTR$(scale$)
          NEXT I%
          PRINT
          COLOR 1
          PRINT
          INPUT " type 0.  ", Choice$
          END IF
  
          CLS
    IF Choice$ = "0" THEN
          PRINT
          PLAY "MB <<l4fdcbcdfdcbl8cl8dl8cl8dl4fdfgdgfdc<l2b"
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
         END IF

     IF CHOICE0000$ = "3" THEN
         CLS
jenifer% = 1
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
         PRINT "leave at a moment's notice! Each job is an adventure involving great risk"
         PRINT "(including, possibly, death), and there are precious few opportunities to"
         PRINT "relax and let your guard down."
         PRINT
         INPUT "To go on type 10.", Choice$
         END IF


    IF Choice$ = "7" THEN
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
          FOR I% = 1 TO 3
          PLAY "mbl16bl16cdl16cl16del16dl16efl16gl16fel16el16dcl16dl16cb"
          NEXT I%
          PLAY "MB <<<l4b l8bbl4>efl2gl4<bl8bbl4>el8ggl4fd<bbl8bbl4bl8bb>l4efl2g<l2b>fl4ege"
          PRINT
          INPUT "type 9. ", Choice$
          END IF

      IF Choice$ = "9" THEN
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
          INPUT "You start off again, tpye 10. ", Choice$
          PRINT
          END IF

      IF Choice$ = "10" THEN
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
60 DO: LOOP UNTIL LEN(INKEY$)
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
70 DO: LOOP UNTIL LEN(INKEY$)
      
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
75 DO: LOOP UNTIL LEN(INKEY$)

          CLS
          PRINT
          PRINT
          INPUT "do you wish to send out your scouts yes / no. ", CHOICE000$
          PRINT " no caps"
          PRINT

    IF CHOICE000$ = "no" THEN
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
80 DO: LOOP UNTIL LEN(INKEY$)
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
85 DO: LOOP UNTIL LEN(INKEY$)
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
90 DO: LOOP UNTIL LEN(INKEY$)
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
          PRINT
          INPUT " So what is it gedog? ", CHOICE0$
    

   IF CHOICE0$ = "1" THEN
         PRINT ""; MO% + 100
         MO% = MO% + 100
         CLS
         PRINT
         PRINT "     Your plains and your men have just won you a full blown victory that no."
         PRINT "one can say other wise about. Still you find out that the Mercury Dragon that"
         PRINT "you were sent to kill was killed by the GORGAN before you every had a chance."
         PRINT "     You are well comed back at Luzer Ville. The King as a reword gives you"
         PRINT "a bounes of 100 dollors and a new horse. The King asks you to stay on with"
         PRINT "the army but you turned him down so you could go exploring in the west. You"
         PRINT "look back at the castle and wave goodby to the King as you ride out, but not"
         PRINT "into the sunset, but, the sunrise."
         FOR I% = 1 TO 2
         PLAY "MB <l4fdcbcdfdcbl8cl8dl8cl8dl4fdfgdgfdcl2b"
         NEXT I%
         PRINT
         PRINT
         INPUT " type 99. ", Choice$
         PRINT
     END IF
     
       IF CHOICE0$ = "2" THEN
         PRINT ""; MO% + 50
         MO% = MO% + 100
         CLS
         PRINT
         PRINT "     Your plains and your men have just won you a full blown victory that no."
         PRINT "one can say other wise about. Still you find out that the Mercury Dragon that"
         PRINT "you were sent to kill was killed by the GORGAN before you every had a chance."
         PRINT "Plus some of the goblins got away but not many."
         PRINT "     You are well comed back at Luzer Ville. The King as a reword gives you"
         PRINT "a bounes of 50 dollors and a new horse. The King asks you to stay on with"
         PRINT "the army but you turned him down so you could go exploring in the west. You"
         PRINT "look back at the castle and wave goodby to the King as you ride out, but not"
         PRINT "into the sunset, but, the sunrise."
         FOR I% = 1 TO 2
         PLAY "MB <l4fdcbcdfdcbl8cl8dl8cl8dl4fdfgdgfdcl2b"
         NEXT I%
         PRINT
         PRINT
         INPUT " type 99. ", Choice$
         PRINT
         END IF
 
 
   IF CHOICE0$ = "3" THEN
         PRINT ""; MO% + 100
         MO% = MO% + 100
         CLS
         PRINT
         PRINT "     Your plains and your men have just won you a full blown victory that no."
         PRINT "one can say other wise about. Still you find out that the Mercury Dragon that"
         PRINT "you were sent to kill was killed by the GORGAN before you every had a chance."
         PRINT "     You are well comed back at Luzer Ville. The King as a reword gives you"
         PRINT "a bounes of 100 dollors and a new horse. The King asks you to stay on with"
         PRINT "the army but you turned him down so you could go exploring in the west. You"
         PRINT "look back at the castle and wave goodby to the King as you ride out, but not"
         PRINT "into the sunset, but, the sunrise."
         FOR I% = 1 TO 2
         PLAY "MB <l4fdcbcdfdcbl8cl8dl8cl8dl4fdfgdgfdcl2b"
         NEXT I%
         PRINT
         PRINT
         INPUT " type 99. ", Choice$
         PRINT
     END IF

   
     IF Choice$ = "99" THEN
          SCREEN 13
           COLOR 4
           PRINT
           PRINT
           PRINT
           PRINT "          THE"
           PRINT
           PRINT
           PRINT
           PRINT
           PRINT "                  END"
           PRINT
           PRINT
           PRINT
           PRINT
           PRINT "          of leavel 1"
100 DO: LOOP UNTIL LEN(INKEY$)
           CALL leval2
           END IF

END SUB

SUB leval2
     CLS
     SCREEN 8
     COLOR 4
     PRINT
     PRINT
     PRINT
     MO% = 90
     LI% = 60
     PO% = ST%
     PRINT
     PRINT
     PRINT "                                   level 2 "
     PRINT
     COLOR 2
     FOR I% = 1 TO 3
     PLAY "MB l16bl16cdl16cl16del16dl16efl16gl16fel16el16dcl16dl16cb"
     NEXT I%
     CALL INTRO
101 DO: LOOP UNTIL LEN(INKEY$)
  
         CLS
         COLOR 15
         PRINT
         PRINT "     A young theif named Jenifer jions you on your quest.( some of you may"
         PRINT "remember her)"
         PRINT
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
         PRINT "a dagger"
         PRINT " food"
         PRINT " and leather aromor"
         PRINT
110 DO: LOOP UNTIL LEN(INKEY$)
         CLS
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
         PRINT "leave at a moment's notice! Each job is an adventure involving great risk"
         PRINT "(including, possibly, death), and there are precious few opportunities to"
         PRINT "relax and let your guard down."
         PRINT
         PRINT
120 DO: LOOP UNTIL LEN(INKEY$)
         CALL weapons
130 DO: LOOP UNTIL LEN(INKEY$)
  PRINT
  PRINT
  PRINT
  PRINT "Your weapons include:"
  PRINT " one short sword"
  SW% = 1
  PRINT " 3 daggers"
  DW% = 3
  PRINT " armor is padded."
  PRINT " life = 60"
  PRINT
  PRINT
135 DO: LOOP UNTIL LEN(INKEY$)

 COLOR 15

 '                      weapon and armor codes of play
 LI% = 60
 P0% = ST%
' SW% = "short sword"
' BOHW% = "one-handed bastard sword"
' BTHW% = "two-handed bastard sword"
' LW% = "loong sword"
' TH% = "two-handed sword"
' WW% = "warhammer"
' BXW% = "battle axe"
' DW% = "dagger"
' SBW% = "short bow"
' LBW% = "long bow"
' LCW% = "light crossbow"
' HCW% = "heavey crossbow"
' PA% = "padded armor"
' LA% = "leather armor"
' SLA% = "studded leather armor"
' CM% = "chain mail armor"
' FPA% = "field plate armor"
' FUPA% = "full plate armor"
' SA% = "small sheild"
' MA% = "midium sheild"
' BA% = "body sheild"
' H% = "hourse
' C% = "candles"
' R% = "rope"
' RH% = "Rase health"
' BP% = "backpack"
' GH% = "grappling hook

 CLS
 PRINT
 PRINT
 PRINT "     You and jenifer start out on your trip down to deep blue which got its name"
 PRINT "from the sky that covers it at night. the sky over deep blue is just that deep"
 PRINT "blue and in the evnig it is the most betiful site that you will ever see and for"
 PRINT "that reson so many people from all parts of the world have made there home there"
 PRINT "in deep blue. "
 PRINT "     In deep blue there is a Inn, a wepons shop, an armor shop, and bar. "
 PRINT
 PRINT "your money at this time is "; MO%
 PRINT
 PRINT "     Would you like to go huntting and bring in some hids to exchange for cash."
 PRINT
 INPUT "yes or no  ", choice1$

IF choice1$ = "yes" THEN
   CLS
   PRINT
   PRINT
   PRINT "     You ask jenifer 'what types of animals live in these woods and how much"
   PRINT "there worth?'"
   PRINT "     She repiles you can get a lot of money for bringing in a 2 foot scorpian"
   PRINT " thats worth about 60 dollors in Deep Blue?"
   PRINT "     You start off into the dark woods in sherch of the game. The woods are"
   PRINT "thick and a fog is rolling in from the west. Jenifer taps you on the shoulder"
   PRINT "and says, 'look right here, scorpian traks and they lead off twords that"
   PRINT "small hill.'"
138 DO: LOOP UNTIL LEN(INKEY$)
   CLS
   PRINT
   PRINT
   PRINT "     You reach the top of the hill to see a three foot scorpian eatting a"
   PRINT "large deer not even looking around this would be an easy kill if it wasn't"
   PRINT "so big. You and jenifer crep a round to the flanks of the scorpian. You raise"
   PRINT "your dagger ready to throw it when the sun bounces of the blade and hits the"
   PRINT "scorpian right in the eye. He whips around and stairs you down. you freeze"
   PRINT "but lucky for you jenifer is ready and jabs one of her swords right into its"
   PRINT "back. The scorpian whips its tail around throwing her across hill you take"
   PRINT "the chance to cut off that tail before it has a chance to show you its piont"
   PRINT "just as allways he swings to look at you, he reaches out with his claw to"
   PRINT "slash you opean but your ready for this one and you leap back to safty."
   PRINT "Jenifer goes back to her sword and finishes him as you distrack him by"
   PRINT "jumping back in range for a sec before you leap back out. His hard head"
   PRINT "was the hardest ever that jenifer had seen so to speed things jump you jump"
   PRINT "on and help her push it in. "
   PRINT
   PRINT "     You enter Deep Blue and get your reword 60 dollars "
   PRINT
   MO% = MO% + 60
140 DO: LOOP UNTIL LEN(INKEY$)
END IF

 CLS
 COLOR 4
 PRINT
 PRINT "                        Weapons Shope"
 PRINT
 PRINT ""
 PRINT "SWORDS"
 PRINT " (1)  Short               8 power     $30.00"
 PRINT "   Bastard"
 PRINT " (2)   One-handed        10 power     $45.00"
 PRINT " (3) Warhammer           6  power     $18.00"
 PRINT " (4) Dagger              4  power     $ 5.00"
 PRINT
 PRINT "To skeep this shope and not come back press enter."
 PRINT "Pick a number but remember armor that is still to come."
 INPUT "But remember you only get one keep trake of all weapons.  ", Choice10$

IF Choice10$ = "1" THEN
   COLOR 15
   PRINT
   PRINT " You now have 2 short swords"
   SW% = 2
   PO% = PO% = 16
   MO% = MO% - 30
   PRINT "your new power level "; PO%
   PRINT "money left = "; MO%
141 DO: LOOP UNTIL LEN(INKEY$)
END IF

IF Choice10$ = "2" THEN
    COLOR 15
    PRINT
    PRINT " You now have a one-habed basterd sword."
    BOHW% = 1
    PO% = PO% + 18
    MO% = MO% - 45
    PRINT "your new power level is "; PO%
    PRINT "money left = "; MO%
142 DO: LOOP UNTIL LEN(INKEY$)
END IF

IF Choice10$ = "3" THEN
    COLOR 15
    PRINT
    PRINT " You now have a warhammer"
    WW% = 1
    PO% = PO% + 14
    MO% = MO% - 18
    PRINT "your new power levle is "; PO%
    PRINT "money left = "; MO%
143 DO: LOOP UNTIL LEN(INKEY$)
END IF

IF Choice10$ = "4" THEN
    COLOR 15
    PRINT
    PRINT "You now have a dagger"
    DW% = 4
    PO% = PO% + 24
    MO% = MO% - 5
    PRINT "Your new power levle is "; PO%
    PRINT "money left = "; MO%
144 DO: LOOP UNTIL LEN(INKEY$)
END IF

  CLS
  PRINT
  PRINT "                   Armor Shope"
  PRINT
  PRINT "(1) padded              - 1 power      $10.00"
  PRINT "(2) leather             - 3 power      $15.00"
  PRINT "(3) Studded leather     - 5 power      $25.00"
  PRINT
  INPUT "Same rules here as the weapon shope.  ", CHOICE09$
 
IF CHOICE09$ = "1" THEN
  PRINT
  PRINT " Its your money and you just got yuorself padded armor."
  PA% = 2
  LI% = LI% + 1
  MO% = MO% - 10
  PRINT "your new life level is "; LI%
  PRINT "money left = "; MO%
146 DO: LOOP UNTIL LEN(INKEY$)
END IF
 
IF CHOICE09$ = "2" THEN
  PRINT
  PRINT " You just got yuorself some studded leather armor."
  LA% = 1
  LI% = LI% + 3
  MO% = MO% - 15
  PRINT "your new life level is "; LI%
  PRINT "money left = "; MO%
147 DO: LOOP UNTIL LEN(INKEY$)
END IF

IF CHOICE09$ = "3" THEN
  PRINT
  PRINT "You just got yourself some studded leather."
  SLA% = 1
  LI% = LI% + 5
  MO% = MO% - 25
  PRINT "your new life level is "; LI%
  PRINT "money left = "; MO%
148 DO: LOOP UNTIL LEN(INKEY$)
END IF

   CLS
   PRINT
   PRINT "     There is a nice in in the middle of the twon which carges 10 dollars"
   PRINT "a night, but that will inprove your life by 10."
   PRINT
   PRINT "Would you like to stay a night or would you like to pass this building by?"
   PRINT
   INPUT " stay or pass?  ", Choice08$

IF Choice08$ = "stay" THEN
   CLS
   PRINT
   PRINT "     You step throw the doors and onto nice red carpet which runs the whole"
   PRINT "way up to the main desk were a man smiels and says, 'How may I help you today?'"
   PRINT "You walk on the red carpet up to the solid wood desk and ask if they have a"
   PRINT "room he says, 'yes we do I will take you to one if you wont'?"
   PRINT "     You get to the room its very nice with a fresh straw bed against the far"
   PRINT "wall with candles on both sides. To your left there is a window in the stone"
   PRINT "looking at the armor shope which you just came from."
   LI% = LI% + 10
   MO% = MO% - 10
   PRINT "    You wake up freash the next day and start off for the bar to get a drink"
   PRINT "and some food. your new life = "; LI%; " money = "; MO%
155 DO: LOOP UNTIL LEN(INKEY$)

END IF

   CLS
   PRINT "     You start to walk again down to the local bar which is in the direction"
   PRINT "you were heading (for what reson I Don't know you just walked). The road"
   PRINT "here is not made out of stones like the buildings but of wood. You stop to"
   PRINT "think about why they would wont to make a street out of wood."
   PRINT "     The bar is about half way down the road with another store of some-kind"
   PRINT "at the end. You walk in and look around to make sure no chairs are coming"
   PRINT "your way fast. There is a old man and women working the counter and they"
   PRINT "smile as you walk over"
   PRINT "      'what can we get for you sony?' the old man asked."
156 DO: LOOP UNTIL LEN(INKEY$)

   CLS
   PRINT
   PRINT
   PRINT "                             The Menu"
   PRINT
   PRINT "           every thing here will help your life%"
   PRINT
   PRINT "(1) Ham and eggs             $ 2.00"
   PRINT "(2) Drink                    $ 1.00"
   PRINT "(3) Bread                    $ 1.00"
   PRINT
   INPUT " you get one thing!   ", Choice07$

IF Choice07$ = "1" THEN
   PRINT
   PRINT
   PRINT
   PRINT "   You eat the meal and thank the people."
   MO% = MO% - 2
   LI% = LI% + 3
   PRINT "Your new life value = "; LI%
   PRINT "Money left = "; MO%
160 DO: LOOP UNTIL LEN(INKEY$)
END IF

IF Choice07$ = "2" THEN
    PRINT
    PRINT
    PRINT
    PRINT "   You drink the beer and leve."
    MO% = MO% - 1
    LI% = LI% + 1
   PRINT "Your new life value = "; LI%
   PRINT "Money left = "; MO%
162 DO: LOOP UNTIL LEN(INKEY$)
END IF
  
IF Choice07$ = "3" THEN
   PRINT
   PRINT
   PRINT
   PRINT " You eat the bread and leve."
   MO% = MO% - 1
   LI% = LI% + 1
   PRINT "Your new life value = "; LI%
   PRINT "Money left = "; MO%
164 DO: LOOP UNTIL LEN(INKEY$)
END IF

  CLS
  PRINT
  PRINT
  PRINT "                          Iteam shope"
  PRINT
  PRINT "(1) Candles 20                                        $10.00"
  PRINT "(2) Candles 10                                        $ 5.00"
  PRINT "(3) Rope 50'                                          $ 7.00"
  PRINT "(4) Rope 100'                                         $13.00"
  PRINT "(5) Rase health  +5                                   $10.00"
  PRINT "(asked at the end or hit enter) Back pack             $ 2.00"
  PRINT "(when you buy rope) Grappling hook                    $ 3.00"
  PRINT
  PRINT
  INPUT "so what would you like?   ", Choice06$

IF Choice06$ = "1" THEN
  CLS
  PRINT
  PRINT
  PRINT
  PRINT " You now have 20 candles to light your way in the dark."
  C% = 20
  MO% = MO% - 10
  PRINT
  PRINT "Would you like some rope?"
  PRINT
  INPUT "If yes then press 3 for 50'-$7.00 or 4 for 100'-$13.00   ", Choice06$
168 DO: LOOP UNTIL LEN(INKEY$)
END IF

IF Choice06$ = "2" THEN
  CLS
  PRINT
  PRINT " You now have 10 candles to light your way in the dark."
  C% = 20
  MO% = MO% - 5
  PRINT
  PRINT
  PRINT
  PRINT "Would you like some rope?"
  PRINT
  INPUT "If yes then press 3 for 50'-$7.00 or 4 for 100'-$13.00   ", Choice06$
169 DO: LOOP UNTIL LEN(INKEY$)
END IF

IF Choice06$ = "5" THEN
   CLS
   PRINT
   PRINT
   PRINT
   PRINT " You just rased your health 5 pionts."
   LI% = LI% + 5
   MO% = MO% - 10
   PRINT
   PRINT "Your new level is "; LI%
   PRINT
   PRINT
   INPUT "If yes then press 3 for 50'-$7.00 or 4 for 100'-$13.00   ", Choice06$
170 DO: LOOP UNTIL LEN(INKEY$)
END IF

IF Choice06$ = "3" THEN
   CLS
   PRINT
   PRINT
   PRINT
   PRINT "You just got yourself 50' of rope."
   R% = 50
   MO% = MO% - 7
   PRINT
   INPUT "Would you like a (7) grappling hook for $ 2.00?  ", Choice06$
   PRINT
   PRINT
   PRINT
171 DO: LOOP UNTIL LEN(INKEY$)
END IF

IF Choice06$ = "4" THEN
   CLS
   PRINT
   PRINT
   PRINT
   PRINT "You just got yourself 100' of rope."
   R% = 100
   MO% = MO% - 13
   PRINT
   INPUT "Would you like a (7) grappling hook for $ 2.00?  ", Choice06$
   PRINT
172 DO: LOOP UNTIL LEN(INKEY$)
END IF

IF Choice06$ = "7" THEN
   CLS
   PRINT
   PRINT
   PRINT
   PRINT "Wis choice now you can throw your rope and have it hook something"
   GH% = 1
   MO% = MO% - 3
   PRINT
   PRINT
173 DO: LOOP UNTIL LEN(INKEY$)
END IF

 CLS
 PRINT
 PRINT
 PRINT
 PRINT "Would you like a backpack to hold everything?"
 PRINT
 PRINT
 INPUT "yes  /  no   ", Choice06$

IF Choice06$ = "yes" THEN
  CLS
  PRINT
  PRINT
  PRINT
  PRINT "You now have somything to hold all your goodies in."
  BP% = 1
  MO% = MO% - 2
  PRINT
  PRINT
  DO: LOOP UNTIL LEN(INKEY$)
END IF
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT "               Money now = "; MO%
174 DO: LOOP UNTIL LEN(INKEY$)

   CLS
   PRINT
   PRINT "   You look back at deep blue as you leve the some twon and then you think"
   PRINT "will this be the last thing I see? You start out for lose-souls a twon right"
   PRINT "next to a grave yard and thats not how it got its name. You start off on the"
   PRINT "hard soil trail which goes right to lose-souls though some thick woods were lots of scorpians live that are worth there weight in gold alive in lo"
   PRINT
   PRINT
   PRINT
   PRINT
   PRINT
   PRINT

END SUB

SUB music
        
           scale$ = ">bceedcfagafedc"
           PLAY "l2"
           PLAY "O" + STR$(I%)
           PLAY "X" + VARPTR$(scale$)
         
           PLAY "<bL4cL4dL4eL4fL4gL4abL4aL4gL4fL4eL4dL4cb"
         
           FOR I% = 1 TO 2
           PLAY "<bl4bl4fl8fl8fcl8dl8cbfl4al4bal4fl8gl8efl4el4dl4cl8abl4fl4el4dl4cl8bab"
           NEXT I%
          
            FOR I% = 1 TO 3
            PLAY "l16bl16cdl16cl16del16dl16efl16gl16fel16el16dcl16dl16cb"
            NEXT I%
          
            PLAY "<l4fdcbcdfdcbl8cl8dl8cl8dl4fdfgdgfdcl2b"
           
             FOR I% = 1 TO 2
             PLAY "l4<c<a>l8ccl4<a>l8ccddeel4d<l8aaaa>edc<a>l4c<a>l8ccl4c"
             NEXT I%
            
              PLAY "<l4b l8bbl4>efl2gl4<bl8bbl4>el8ggl4fd<bbl8bbl4bl8bb>l4efl2g<l2b>fl4ege"

END SUB

SUB weapons
 CLS
 PRINT
 COLOR 8
 PRINT "                           WEAPONS"
 PRINT
 PRINT "SWORDS"
 PRINT "   Short            8 power      $30.00"
                                                 SW$ = "short sword"
                                                'SW$ = 8PO$
 PRINT "   Bastard"
 PRINT "     One-handed     10 power     $45.00"
                                                 BOHW$ = "one-handed bastard sword"
                                                'BOHW$ = 10PO%
 PRINT "     Two-handed     13 power     $50.00"
                                                 BTHW$ = "two-handed bastard sword"
                                                'BTHW$ = 13PO%
 PRINT "   Long             15 power     $60.00"
                                                 LW$ = "loong sword"
                                                'LW$ = 15PO%
 PRINT "   Two-handed       20 power     $100.00"
                                                 TH$ = "two-handed sword"
                                                'TH$ = 20PO%
 PRINT "Warhammer           6  power     $18.00"
                                                  WW$ = "warhammer"
                                                 'WW$ = 6PO%
 PRINT "Battle axe          10 power     $20.00"
                                                 BXW$ = "battle axe"
                                                'BXW$ = 10PO%
 PRINT "Dagger              4  power     $ 5.00"
                                                 DW$ = "dagger"
                                                'DW$ = 4PO%
 PRINT "Spear               3 power      $ 2.00"
                                                 SPW$ = "spear"
                                                 'SPW$=3PO%
 PRINT "BOWS "
 PRINT "   Short           +3 * power    $45.00"
                                                 SBW$ = "short bow"
                                                'SBW$ = PO%+3
 PRINT "   Long            +5 * power    $50.00"
                                                 LBW$ = "long bow"
                                                'LBW$ = PO%+5
 PRINT "   light crossbow  +4 * power    $55.00"
                                                 LCW$ = "light crossbow"
                                                'LCW$ = PO%+4
 PRINT "   Heavy crossbow  +6 * power    $60.00"
                                                 HCW$ = "heavey crossbow"
                                                'HCW$ = PO%+6
 PRINT
 PRINT " * = the type of arrow will give you a higher piont avergae."
 PRINT
 INPUT "Type 1   ", Choice00000001$

IF Choice00000001$ = "1" THEN
 CLS
 PRINT
 PRINT "                            ARMOR"
 PRINT
 PRINT "padded              - 1 power      $10.00"
                                                    PA$ = "padded armor"
                                                    'PA$ = LI%+1
 PRINT "leather             - 3 power      $15.00"
                                                    LA$ = "leather armor"
                                                    'LA$ = LI%+3
 PRINT "Studded leather     - 5 power      $25.00"
                                                    SLA$ = "studded leather armor"
                                                   'SLA$ = LI%+5
 PRINT "chain mail          -10 power      $60.00"
                                                     CM$ = "chain mail armor"
                                                   'CM$ = LI% = 10
 PRINT "field plate         -13 power      $110.00"
                                                    FPA$ = "field plate armor"
                                                    'FPA$ = LI%=13
 PRINT "full plate          -16 power      $130.00"
                                                     FUPA$ = "full plate armor"
                                                     'FUPA$ = LI%+16
 PRINT "Shields"
 PRINT "   small            - 4            $15.00"
                                                     SA$ = "small sheild"
                                                     'SA$ = LI%+4
 PRINT "   midium           - 8            $25.00"
                                                      MA$ = "midium sheild"
                                                     'MA$ = LI%+8
 PRINT "   body             -12            $55.00"
                                                      BA$ = "body sheild"
                                                     'BA$ = LI%+12
 PRINT
 PRINT
 PRINT " There may be rare armors latter on that aren't here."
 PRINT
 INPUT "type 2   ", Choice000000001$
END IF

IF Choice000000001$ = "2" THEN
 CLS
 PRINT
 COLOR 15
 PRINT "                             WEAPONS"
 PRINT
 PRINT "   Short swords: a short sword is just that a short sword"
 PRINT "   Bastard swords: a bastard sword has a longer hilt then a long sword."
 PRINT "   Long swords: a long sword is about five feet long and is used to slash. "
 PRINT "   Two-handed: a two handed sword needs to be held in both hands and there fore"
 PRINT "there can be no shield. it is six feet long and used as the long sword."
 PRINT "   Warhammer: a warhammer is a giant hammer used to smash your enemy into dust."
 PRINT "   Dagger: a dagger is a small knife made to be thrown at your enemy."
 PRINT "   Battle axe: a battle axe is a large axe with a short handle."
 PRINT "   Short bow: a short bow is fore up close 10-80 yards."
 PRINT "   Long bow: a long bow is bigger and for long rage 70-150 yards."
 PRINT "   Light crossbow: a short crossbow is easy to load but shouts with more power,"
 PRINT "same rang as a short bow."
 PRINT "   Heavy croosbow: a heavy crossbow used the same as a light but shots llike a "
 PRINT "long bow."
 PRINT
 INPUT "type 3   ", Choice00000001$
END IF

IF Choice00000001$ = "3" THEN
 CLS
 PRINT
 PRINT "                                ARMOR"
 PRINT
 PRINT "   Padded armor: padded armor is the worest you can have. After some time passes"
 PRINT "things start to live in it like rats, lice, and it starts to smell."
 PRINT "   Leather armor: leather armor is strong and is all moat the best for an"
 PRINT "adventure."
 PRINT "   Studded leather: studded leather is the best for someone who wonts to be"
 PRINT "quite and more fast and at the same time have some protection"
 PRINT "   chain mail: chain mail is a bunch of ringlets conected together, but it makes"
 PRINT "alot of nosie"
 PRINT "   Field plate / Full plate : these plate armor are to heavy for you to walk "
 PRINT "around in and you will get the mony need in (leval 2)"
 PRINT
 INPUT "type 4   ", Choice000000001$
END IF

IF Choice000000001$ = "4" THEN
  CLS
  PRINT
  PRINT "                              Iteams"
  PRINT
  PRINT "Horses                            $100.00"
                                                          'H% = 1
  PRINT "Candles 20                        $10.00"
                                                          'C% = 20
  PRINT "Candles 10                        $ 5.00"
                                                          'C% = 10
  PRINT "Rope 50'                          $ 7.00"
                                                          'R% = 50
  PRINT "Rope 100'                         $13.00"
                                                          'R% = 100
  PRINT "Rase health  +5                   $10.00"
                                                          'RH% = 1
                                                          'LI% + 5
  PRINT "Rase health +10                   $20.00"
                                                          'RH% = 2
                                                          'LI% + 10
  PRINT "Back pack                         $ 1.00"
                                                          'BP% = 1
  PRINT "Grappling hook                    $ 3.00"
END IF                                                           'GH% = 1

END SUB

