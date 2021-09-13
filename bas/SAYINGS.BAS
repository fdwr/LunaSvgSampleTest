SCREEN 0: WIDTH 80, 25: LOCATE , , 0
CLS

COLOR 15, 3: LOCATE 1, 1: PRINT " File  Edit  Search                                                             ";

COLOR 0, 7
DATA "This is a test of the emergency broadcast system","All's well that ends well","Speak softly but carry a big stick","To be red is to be dead","Never look a gift horse on the mouth","Two's company, three's a croud, four's a party"
DATA "There's a balm in Gilead","This is only a test","Two heads are better than one","Too many cooks spoil the stew","I never saw a cookie I didn't like","He who does not know he is being served last, does not mind"
DATA "There's no such thing as a free lunch","The only free thing in life is life","Look before you leap","Do not judge lest you be judged","Life is like a box u' chocolates","You never know when you're going to find one that is empty"
DATA "Sometimes you gotta grin and bear it","Life is like a bowl of cherries, or was that a chair of bowlies","Try, try, try again, then give up","No sense being stupid about it","That's all folks","A penny saved is a penny earned"
DATA "Don't measure ones capacities by your limitations"
FOR Show = 2 TO 24
 READ Temp$
 IF LEN(Temp$) < 80 THEN Temp$ = Temp$ + SPACE$(80 - LEN(Temp$))
 LOCATE Show, 1: PRINT Temp$;
NEXT Show

COLOR 15, 3: LOCATE 25, 1: PRINT " Press any key to get off this silly screen of common sense sayings             ";
SLEEP

COLOR 7, 0: CLS

