' Test the goat/car switching probability
DEFINT A-Z

TotalTests = 10000
Switches = 0
Stays = 0
SwitchWins = 0
StayWins = 0

CLS
FOR Count = 1 TO TotalTests
    'you always pick the door on the left regardless,
    'since it makes no difference

    'door the car is really behind
    CarDoor = INT(RND * 3)
   
    'whether to switch or not
    Switch = INT(RND * 2)
    IF Switch THEN
        Switches = Switches + 1
    ELSE
        Stays = Stays + 1
    END IF
   
    SELECT CASE CarDoor
    CASE 0
        IF Switch = 0 THEN StayWins = StayWins + 1
    CASE 1
        IF Switch THEN SwitchWins = SwitchWins + 1
    CASE 2
        IF Switch THEN SwitchWins = SwitchWins + 1
    END SELECT
NEXT

PRINT "Switches    ="; Switches
PRINT "Stays       ="; Stays
PRINT "Switch wins ="; SwitchWins
PRINT "Stay wins   ="; StayWins

'results:
'4935 switches
'5065 stays
'3320 switch wins
'1719 stay wins

