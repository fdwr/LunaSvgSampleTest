REM---------------------------------------------------------------------------
REM  Titel: SortAlgo.bas
REM  Autor: Marty Winkler
REM  Datum: 13.03.2004
REM  letzte Aenderung: 27.03.2004
REM---------------------------------------------------------------------------
REM  Info: Das Programm demonstriert verschiedene Suchverfahren. Dabei kann
REM        zwischen verschiedenen Darstellungsformen gewaehlt werden.
REM           a) keine grafische Darstellung
REM           b) Punkt-Darstellung (Position auf der y-Achse entspricht dem
REM              Wert des jeweiligen Elements)
REM           c) Linien-Darstellung (Laenge der Linie entspricht dem Wert des
REM              jeweiligen Elements)
REM        Bei den grafischen Darstellungsformen gibt die Position auf der
REM        x-Achse die Position des jeweiligen Elements im Datenfeld an.
REM
REM  Hinweis zur grafischen Darstellung:
REM        Wenn angegeben wird (siehe unten im Quellcode), dass mehrere
REM        Suchverfahren ausgefuehrt werden sollen, so wird die grafische
REM        Darstellung durch das naechste Verfahren geloescht.
REM        Daher sollte bei grafischer Darstellung nur ein Verfahren
REM        ausgefuehrt werden.
REM
REM        Bei den schnellen Sortierverfahren empfiehlt es sich die
REM        Warteschleife in den Unterprogrammen DisplayElement und
REM        DisplayElements auszukommentieren um die grafische
REM        Darstellung nachverfolgen zu koennen.
REM---------------------------------------------------------------------------


REM------ Unterprogramme
REM -> zur Darstellung und zum Ausfuehren eines Sortierverfahrens

    DECLARE SUB DisplayElement (Index)
    DECLARE SUB DisplayElements ()
    DECLARE SUB RunAlgorithm (Algorithm$, Sort$)

REM------ Unterprogramme
REM -> die implementierten Sortierverfahren

    DECLARE SUB BubbleSort ()
    DECLARE SUB ExtendedBubbleSort ()
    DECLARE SUB ShakerSort ()
    DECLARE SUB RippleSort ()
    DECLARE SUB SelectionSort ()
    DECLARE SUB InsertionSort ()
    DECLARE SUB ShellSort ()
    DECLARE SUB STWMergeSort ()
    DECLARE SUB STWMergeSortMerge (left, mid, right)
    DECLARE SUB NTWMergeSort ()

REM------ Unterprogramme
REM -> zur Erstellung der zu sortierenden Datenmenge

    DECLARE SUB SortedAsc ()
    DECLARE SUB SortedDesc ()
    DECLARE SUB Unsorted ()

REM------ globale Variablen

    DIM SHARED COUNT, RAND, CMPs, SWPs AS LONG
    DIM SHARED Display, DisplayPos AS INTEGER
    DIM SHARED TimeStart AS DOUBLE, TimeEnd AS DOUBLE, Time AS DOUBLE

REM---------------------------------------------------------------------------

SCREEN 12

REM------ Variable: RAND
REM Enthaelt den Wert, mit welchem der Zufallszahlengenerator initialisiert
REM werden soll.

    RAND = TIMER


REM------ Variable: Display
REM 0 = keine grafische Darstellung
REM 1 = Punkt-Darstellung
REM 2 = Linien-Darstellung
REM  => zusaetzlich die Variable DisplayPos beachten!

    Display = 0

REM------ Variable: DisplayPos
REM 0 = keine grafische Darstellung
REM 1 = die Darstellung wird jedesmal aktualisiert, nachdem ein Element
REM     verschoben bzw. zwei Elemente getauscht wurden
REM 2 = die Darstellung wird nach einem Durchgang der aeusseren Schleife
REM     aktualisiert
REM => 1 und 2 koennen zu 3 addiert werden
   
    DisplayPos = 1

REM------ Variable: Sort$
REM Sortierung der Datenmenge:
REM "Unsorted"   = unsortiert
REM "SortedAsc"  = aufsteigend
REM "SortedDesc" = absteigend

    Sort$ = "Unsorted"

REM------ Variable: Anzahl
REM -> gibt an, wieviele aus den per DATA angegebenen Werten
REM    verarbeitet werden sollen

    Anzahl = 1

REM------ DATA
REM -> diese Zeilen enthalten verschiedene Groessen der Datenmenge
REM    (Anzahl der Elemente), auf welche die Sortierverfahren
REM    angewendet werden sollen
  
    'DATA 10000, 5000, 1000
    DATA 128
    DATA 100, 30, 20, 10

REM---------------------------------------------------------------------------
 
REM------
REM -> Dies ist die Haupt-Schleife.

FOR Index = 1 TO Anzahl

  REM-- die naechste Elemente-Anzahl holen und das Datenfeld deklarieren
    
    READ COUNT
    REDIM SHARED array(0 TO COUNT - 1) AS INTEGER

  REM-- die Anzahl der Elemente ausgeben
    
    PRINT : PRINT "Elemente: " + STR$(COUNT)

  REM-- die Sortierverfahren ausfuehren
  REM-- Verfahren, welche nicht verwendet werden sollen, koennen
  REM-- auskommentiert werden (mit einem Hochkomma: ')

    RunAlgorithm "BubbleSort", Sort$
    RunAlgorithm "ExtendedBubbleSort", Sort$
    RunAlgorithm "ShakerSort", Sort$
    RunAlgorithm "RippleSort", Sort$
    RunAlgorithm "SelectionSort", Sort$
    RunAlgorithm "InsertionSort", Sort$
    RunAlgorithm "ShellSort", Sort$
    RunAlgorithm "STWMergeSort", Sort$
    RunAlgorithm "NTWMergeSort", Sort$

NEXT

SUB BubbleSort
 
  FOR i = COUNT - 1 TO 1 STEP -1
    
      changed = 0
      FOR j = 0 TO i - 1
          CMPs = CMPs + 1
          IF array(j) > array(j + 1) THEN
             SWPs = SWPs + 1
             changed = 1
             h = array(j)
             array(j) = array(j + 1)
             array(j + 1) = h
            
             DisplayElement j
             DisplayElement j + 1
          END IF
      NEXT

      DisplayElements

  NEXT

END SUB

SUB DisplayElement (Index)
 
  IF (DisplayPos AND 1) = 0 THEN EXIT SUB

  SELECT CASE Display
   CASE 1:
          value = 15 * (array(Index) / COUNT) + 1
          LINE (Index, 0)-(Index, COUNT - array(Index) - 1), 0
          LINE (Index, COUNT - array(Index) + 1)-(Index, COUNT), 0
          PSET (Index, COUNT - array(Index)), value
   CASE 2:
          COUNT2 = COUNT / 2
          array2 = array(Index) / 2
          value = 15 * (array(Index) / COUNT) + 1

          LINE (Index, 0)-(Index, COUNT2 - array2), 0
          LINE (Index, COUNT2 + array2)-(Index, COUNT), 0

          LINE (Index, COUNT2 - array2)-(Index, COUNT2 + array2), value
   CASE 3:
          COUNT2 = COUNT / 2
          value = 15 * (array(Index) / COUNT) + 1
          CIRCLE (COUNT2, COUNT2), Index / 2, value
  END SELECT
 
  'Start = TIMER
  'DO: LOOP WHILE TIMER - Start < .0001

END SUB

SUB DisplayElements

  IF (DisplayPos AND 2) = 0 THEN EXIT SUB

  SELECT CASE Display
   CASE 1:
          FOR i = 0 TO COUNT - 1
              value = 15 * (array(i) / COUNT) + 1
              LINE (i, 0)-(i, COUNT - array(i) - 1), 0
              LINE (i, COUNT - array(i) + 1)-(i, COUNT), 0
              PSET (i, COUNT - array(i)), value
          NEXT
   CASE 2:
          COUNT2 = COUNT / 2
          FOR i = 0 TO COUNT - 1
              array2 = array(i) / 2
              value = 15 * (array(i) / COUNT) + 1

              LINE (i, 0)-(i, COUNT2 - array2), 0
              LINE (i, COUNT2 + array2)-(i, COUNT), 0

              LINE (i, COUNT2 - array2)-(i, COUNT2 + array2), value
          NEXT
   CASE 3:
          COUNT2 = COUNT / 2
          FOR i = 0 TO COUNT - 1
              value = 15 * (array(i) / COUNT) + 1
              CIRCLE (COUNT2, COUNT2), i / 2, value
          NEXT
  END SELECT

  'Start = TIMER
  'DO: LOOP WHILE TIMER - Start < .0001

END SUB

SUB ExtendedBubbleSort

  FOR i = COUNT - 1 TO 1 STEP -1
     
      changed = 0
      FOR j = 0 TO i - 1
          CMPs = CMPs + 1
          IF array(j) > array(j + 1) THEN
             SWPs = SWPs + 1
             changed = 1
             h = array(j)
             array(j) = array(j + 1)
             array(j + 1) = h
     
             DisplayElement j
             DisplayElement j + 1
          END IF
      NEXT

      IF changed = 0 THEN EXIT SUB

      DisplayElements

  NEXT

END SUB

SUB InsertionSort

  FOR i = 1 TO COUNT - 1
     
      t = array(i)
      j = i - 1
     
      DO WHILE j >= 0
         CMPs = CMPs + 1
        
         IF t >= array(j) THEN EXIT DO
        
'         SWPs = SWPs + 1
         array(j + 1) = array(j)

         DisplayElement j + 1
        
         j = j - 1
      LOOP
     
      SWPs = SWPs + 1
      array(j + 1) = t

      DisplayElement j + 1
     
      DisplayElements

  NEXT

END SUB

SUB NTWMergeSort

  DO
    rr = -1
    DO WHILE rr < COUNT - 1
       ll = rr + 1
       mm = ll
       DO WHILE mm < COUNT - 1
          CMPs = CMPs + 1
          IF array(mm + 1) < array(mm) THEN EXIT DO
          mm = mm + 1
       LOOP
       IF mm < COUNT - 1 THEN
          rr = mm + 1
          DO WHILE rr < COUNT - 1
             CMPs = CMPs + 1
             IF array(rr + 1) < array(rr) THEN EXIT DO
             rr = rr + 1
          LOOP
          STWMergeSortMerge ll, mm, rr
       ELSE
          rr = mm
       END IF
    LOOP
  LOOP UNTIL ll = 0

END SUB

SUB RippleSort

  FOR i = 0 TO COUNT - 2
      FOR j = i + 1 TO COUNT - 1
          CMPs = CMPs + 1
          IF array(i) > array(j) THEN
             SWPs = SWPs + 1
             h = array(i)
             array(i) = array(j)
             array(j) = h
            
             DisplayElement i
             DisplayElement j
          END IF
      NEXT

      DisplayElements
 
  NEXT

END SUB

SUB RunAlgorithm (Algorithm$, Sort$)

  RANDOMIZE RAND
  SELECT CASE LCASE$(Sort$)
         CASE "unsorted":
              Unsorted
         CASE "sortedasc":
              SortedAsc
         CASE "sorteddesc":
              SortedDesc
  END SELECT

  tempDisplayPos = DisplayPos
    DisplayPos = 2
    DisplayElements
  DisplayPos = tempDisplayPos

  CMPs = 0: SWPs = 0
  TimeStart = TIMER
  SELECT CASE LCASE$(Algorithm$)
         CASE "bubblesort":
              BubbleSort
         CASE "extendedbubblesort":
              ExtendedBubbleSort
         CASE "shakersort":
              ShakerSort
         CASE "ripplesort":
              RippleSort
         CASE "selectionsort":
              SelectionSort
         CASE "insertionsort":
              InsertionSort
         CASE "shellsort":
              ShellSort
         CASE "stwmergesort":
              STWMergeSort
         CASE "ntwmergesort":
              NTWMergeSort
  END SELECT
 
  TimeEnd = TIMER
  Time = TimeEnd - TimeStart

  tempDisplayPos = DisplayPos
    DisplayPos = 2
    DisplayElements
  DisplayPos = tempDisplayPos

  PRINT "[" + Sort$ + "] " + Algorithm$, "V: " + STR$(CMPs), "T/E: " + STR$(SWPs), "Zeit: " + STR$(Time)

END SUB

SUB SelectionSort

  FOR i = 0 TO COUNT - 2
     
      minStelle = i
      FOR j = i + 1 TO COUNT - 1
          CMPs = CMPs + 1
          IF array(minStelle) > array(j) THEN
             minStelle = j
          END IF
      NEXT

      SWPs = SWPs + 1

      h = array(minStelle)
      array(minStelle) = array(i)
      array(i) = h

      DisplayElement minStelle
      DisplayElement i

      DisplayElements
 
  NEXT

END SUB

SUB ShakerSort
 
  FOR i = COUNT - 2 TO INT((COUNT - 1) / 2) STEP -1
  
      changed = 0
      FOR j = COUNT - i - 2 TO i
          CMPs = CMPs + 1
          IF array(j) > array(j + 1) THEN
             SWPs = SWPs + 1
             changed = 1
            
             h = array(j)
             array(j) = array(j + 1)
             array(j + 1) = h
         
             DisplayElement j
             DisplayElement j + 1
          END IF
      NEXT
     
      IF changed = 0 THEN EXIT SUB
     
      changed = 0
      FOR j = i TO COUNT - i - 1 STEP -1
          CMPs = CMPs + 1
          IF array(j - 1) > array(j) THEN
             SWPs = SWPs + 1
             changed = 1
            
             h = array(j - 1)
             array(j - 1) = array(j)
             array(j) = h
         
             DisplayElement j - 1
             DisplayElement j
          END IF
      NEXT
  
      IF changed = 0 THEN EXIT SUB
     
      DisplayElements
 
  NEXT

END SUB

SUB ShellSort
  
  h = 1
  DO
    h = 4 * h + 1
  LOOP UNTIL h >= COUNT

  DO
    h = INT(h / 4)
    i = h

    DO
      v = array(i)
      j = i
       
      DO WHILE array(j - h) > v
         CMPs = CMPs + 1
         SWPs = SWPs + 1
         array(j) = array(j - h)

         DisplayElement j

         j = j - h
         IF j <= h THEN
            EXIT DO
         END IF
      LOOP
      CMPs = CMPs + 1

      SWPs = SWPs + 1
      array(j) = v
   
      DisplayElement j
   
      i = i + 1

    LOOP WHILE i < COUNT

    DisplayElements

  LOOP UNTIL h = 1

END SUB

SUB SortedAsc

  FOR i = 0 TO COUNT - 1
      array(i) = i
  NEXT

END SUB

SUB SortedDesc
 
  FOR i = 0 TO COUNT - 1
      array(i) = COUNT - i + 1
  NEXT

END SUB

SUB STWMergeSort

  size = 1
  DO WHILE size < COUNT
     rr = -1
     DO WHILE rr + size < COUNT
        ll = rr + 1
        mm = ll + size - 1
        IF mm + size <= COUNT THEN
           rr = mm + size
        ELSE
           rr = COUNT - 1
        END IF
        STWMergeSortMerge ll, mm, rr
     LOOP
     size = 2 * size
  LOOP

END SUB

SUB STWMergeSortMerge (left, mid, right)

  DIM TempArr(0 TO COUNT - 1) AS INTEGER

  Offset1 = left
  Offset2 = mid + 1
  Index = 0

  DO WHILE (Offset1 <= mid) AND (Offset2 <= right)
     CMPs = CMPs + 1
     SWPs = SWPs + 1
     IF array(Offset1) <= array(Offset2) THEN
        TempArr(Index) = array(Offset1)
        Offset1 = Offset1 + 1
     ELSE
        TempArr(Index) = array(Offset2)
        Offset2 = Offset2 + 1
     END IF
     Index = Index + 1
  LOOP
 
  IF Offset1 <= mid THEN
     FOR offset3 = mid TO Offset1 STEP -1
         SWPs = SWPs + 1
         Offset2 = Offset2 - 1
         array(Offset2) = array(offset3)
        
         DisplayElement Offset2
     NEXT
  END IF

 
  Offset1 = left
  FOR Index = 0 TO Offset2 - left - 1
      SWPs = SWPs + 1
      array(Offset1) = TempArr(Index)
     
      DisplayElement Offset1

      Offset1 = Offset1 + 1
  NEXT

  DisplayElements

END SUB

SUB Unsorted

  DIM Table(0 TO COUNT - 1) AS STRING * 1

  FOR i = 0 TO COUNT - 1
again:
      value = INT(COUNT * RND)
      IF Table(value) = "A" THEN
         GOTO again
      END IF
      Table(value) = "A"
      array(i) = value
  NEXT

END SUB

