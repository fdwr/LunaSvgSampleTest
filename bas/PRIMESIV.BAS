'prime number sieve 99/3/20
DEFINT A-Z
OPTION BASE 0

DIM Primes(16383) AS LONG, Counters(16383) AS LONG, LastPrimeIndex
DIM Graph(319)

GOSUB PrimeCounter

WIDTH 80, 25
SCREEN 0

END

PrimeCounter:
  SCREEN 13
 
  CheckKeyCount = 0
  LastPrimeIndex = -1
  FOR PrimeNum& = 2 TO 1048576
    Composites = 0
    FOR CurNum = 0 TO LastPrimeIndex
      NewCount = Counters(CurNum) - 1
      IF NewCount < 1 THEN Counters(CurNum) = Primes(CurNum): Composites = 1 ELSE Counters(CurNum) = NewCount
    NEXT CurNum
    IF Composites = 0 THEN
      LOCATE 25, 1: PRINT PrimeNum&;
      LastPrimeIndex = LastPrimeIndex + 1
      Primes(LastPrimeIndex) = PrimeNum&
      Counters(LastPrimeIndex) = PrimeNum&
      BarColumn = PrimeNum& \ 1000
      Graph(BarColumn) = Graph(BarColumn) + 1
      LINE (BarColumn, 0)-(BarColumn, Graph(BarColumn) - 1), 11
    END IF
    CheckKeyCount = CheckKeyCount + 1
    IF CheckKeyCount >= 100 THEN
      IF LEN(INKEY$) THEN EXIT FOR
      CheckKeyCount = 0
    END IF
    'LOCATE 1, 1: PRINT PrimeNum&; LastPrimeIndex + 1
  NEXT PrimeNum&
  
RETURN

PrimeSieve:
  SCREEN 13

  DEF SEG = &HA000
  FOR PrimeNum& = 2 TO 61439
    IF PEEK(PrimeNum&) = 0 THEN
      LOCATE 25, 1: PRINT LTRIM$(STR$(PrimeNum&));
      FOR CompositeNum& = PrimeNum& + PrimeNum& TO 61439 STEP PrimeNum&
        POKE (CompositeNum&), 7
      NEXT CompositeNum&
    END IF
  NEXT PrimeNum&

  LOCATE 25, 1: PRINT "Done"; TAB(40);
  DO: LOOP UNTIL LEN(INKEY$)

RETURN

