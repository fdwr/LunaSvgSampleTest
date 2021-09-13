'Insertion Sort
'2001.3.22 Dwayne Robinson
'
'Like any insertion sort, it takes each value from the array and finds where
'it would next fit, inserts it, and shifts over all the entries. Unlike many
'insertion sorts, it sorts in place (no separate destination array).
'
'A few small changes can significantly change the number of shifts and
'comparisons for the better. Moving the index back by one after each shift
'nearly halves the comparisons. Moving IdxBase forward by one after each
'shift does not impact any particular result very much, but overall is better
'than simply moving forward when there isn't a swap or insertion. The
'greatest speed increase of all though comes from reversing direction, rather
'than always proceding in one (whether forward or backward). Reversing at the
'end of a search is good; reversing immediately after each shift is better;
'and a combination of the two is by far the best, decreasing all factors. On
'average, both the total shifts and comparisons are least halved. I'll admit
'though that that the logic for this final, fastest variation is (no surprise)
'the most complex.
'
'Time results:
'
'With 28 random entries
'Shifts Moves   Comparisons
'63     224     623     always forward
'77     238     361     move back one
'49     210     560     move forward one
'77     238     884     restart after shift
'60     221     594     reverse direction at each end
'37     198     258     reverse direction at each shift
'33     194     273     combination reverse at shift and end
'
'With 51 random entries
'189    791     2806    always forward
'262    864     1218    move back one
'174    776     2665    move forward one
'262    864     5059    restart after shift (as you can see, this one is bad)
'125    727     1877    reverse direction at each end
'81     683     864     reverse direction at each shift
'69     671     796     combination reverse at shift and end
'
'With 90 random entries
'328    2273    5926    always forward
'682    2627    3479    move back one
'307    2252    5685    move forward one
'682    2627    21987   restart after shift (as you can see, this one is bad)
'233    2178    6787    reverse direction at each end
'140    2085    2308    reverse direction at each shift
'135    2080    2283    combination reverse at shift and end
'
'With 90 random entries
'623    7365    22122   always forward
'...    ...     ...
'263    7005    7347    combination reverse at shift and end
DEFINT A-Z

CONST SortForward = 0
CONST SortBackOne = 1
CONST SortFrwdOne = 2
CONST SortBackBase = 3
CONST SortRevEnds = 4
CONST SortRevShift = 5
CONST SortRevShEnd = 6
DIM SortArray(300)

SortMode = SortRevShEnd
UseRandom = 1

'Initialize sort array
IF UseRandom THEN
    'RANDOMIZE TIMER
    SortNumbers = UBOUND(SortArray) - 1
    FOR Count = 0 TO SortNumbers
        SortArray(Count) = INT(RND * 100)
    NEXT
ELSE
    RESTORE SortData
    GOTO ReadSortDataStart
    'Count=0
    DO
        SortArray(SortNumbers) = Value
        SortNumbers = SortNumbers + 1
ReadSortDataStart:
        READ Value
    LOOP UNTIL Value <= 0
END IF



'Sort array
CLS
LOCATE , , 0
GOSUB PrintSortArry
Moves = 0: Shifts = 0
DO
    IdxBase = 0
    DO UNTIL IdxBase >= SortNumbers - 1
        'GOSUB PrintSortArry
        Comps = Comps + 1
        IF SortArray(IdxBase) > SortArray(IdxBase + 1) THEN
            Value = SortArray(IdxBase)
            IdxCmp = IdxBase + 1
            GOTO ShiftArray
        END IF
        IdxBase = IdxBase + 1
    LOOP
    EXIT DO

    DO
NormalDirection:
        Value = SortArray(IdxBase)
        IdxCmp = IdxBase + 1
        Comps = Comps + 1
        IF Value > SortArray(IdxCmp) THEN
ShiftArray:
            IdxCmp = IdxCmp + 1
            DO UNTIL IdxCmp >= SortNumbers
                Comps = Comps + 1
                IF Value <= SortArray(IdxCmp) THEN EXIT DO
                IdxCmp = IdxCmp + 1
            LOOP
            FOR Count = IdxBase TO IdxCmp - 2
                SortArray(Count) = SortArray(Count + 1)
            NEXT
            SortArray(Count) = Value
            Shifts = Shifts + 1
            Moves = Moves + (IdxCmp - IdxBase)

            IdxSwapped = Count
            GOSUB PrintSortArry

            'Using either of the two lines below slightly increases speeds
            'by moving IdxBase back. in a random test of a small array, the
            'second line reduced the time to 80%, but it also increased time
            'to 150% in a small array. The first line though significantly
            'reduced it to only 50-58% in both cases. Do combine the step
            'back lines with direction reversing because, all independantly
            'they both increase performance, together they are
            'counterproductive.
            IF SortMode = SortBackOne THEN IF IdxBase > 0 THEN IdxBase = IdxBase - 1
            IF SortMode = SortFrwdOne THEN IF IdxBase < SortNumbers - 1 THEN IdxBase = IdxBase + 1
            IF SortMode = SortBackBase THEN IdxBase = 0
            'IdxBase = IdxBase + 1 'depending on the data, can very slightly improve reverse at shift
            IF (SortMode = SortRevShift) OR (SortMode = SortRevShEnd) THEN IF IdxBase > 0 THEN GOTO ReverseDirection
        ELSE
            IdxBase = IdxBase + 1
        END IF
    LOOP UNTIL IdxBase >= SortNumbers - 1

    IF (SortMode <> SortRevEnds) AND (SortMode <> SortRevShEnd) THEN GOTO NoReverse

DoReverse:
    IdxBase = SortNumbers - 1
    DO UNTIL IdxBase <= 0
        'GOSUB PrintSortArry
        Comps = Comps + 1
        IF SortArray(IdxBase) < SortArray(IdxBase - 1) THEN
            Value = SortArray(IdxBase)
            IdxCmp = IdxBase - 1
            GOTO ShiftArrayRight
        END IF
        IdxBase = IdxBase - 1
    LOOP
    EXIT DO

    DO
ReverseDirection:
        Value = SortArray(IdxBase)
        IdxCmp = IdxBase - 1
        Comps = Comps + 1
        IF Value < SortArray(IdxCmp) THEN
ShiftArrayRight:
            IdxCmp = IdxCmp - 1
            DO UNTIL IdxCmp < 0
                Comps = Comps + 1
                IF Value >= SortArray(IdxCmp) THEN EXIT DO
                IdxCmp = IdxCmp - 1
            LOOP
            FOR Count = IdxBase TO IdxCmp + 2 STEP -1
                SortArray(Count) = SortArray(Count - 1)
            NEXT
            SortArray(Count) = Value
            Shifts = Shifts + 1
            Moves = Moves - (IdxCmp - IdxBase)

            IdxSwapped = Count
            GOSUB PrintSortArry

            'Using either of the two lines below slightly increases speeds
            'by moving IdxBase back. in a random test of a small array, the
            'second line reduced the time to 80%, but it also increased time
            'to 150% in a small array. The first line though significantly
            'reduced it to only 50-58% in both cases.
            'IF IdxBase < SortNumbers-1 THEN IdxBase = IdxBase + 1
            'IdxBase = SortNumbers-1
            IF SortMode = SortRevShift OR (SortMode = SortRevShEnd) THEN IF IdxBase < SortNumbers - 1 THEN GOTO NormalDirection
        ELSE
            IdxBase = IdxBase - 1
        END IF
    LOOP UNTIL IdxBase <= 0
    IF SortMode = SortRevShift THEN GOTO DoReverse
NoReverse:
LOOP
GOSUB PrintSortArry
COLOR 9: PRINT "Shifts:"; Shifts; "Moves:"; Moves; "Comparisons:"; Comps

END

PrintSortArry:
    LOCATE 1, 1
    Count = SortNumbers
    FOR Count = 0 TO SortNumbers - 1
        IF Count = IdxBase THEN COLOR 15 ELSE IF Count = IdxSwapped THEN COLOR 11 ELSE COLOR 9
        PRINT RIGHT$("  " + STR$(SortArray(Count)), 3);
    NEXT
    PRINT
RETURN

SortData:
DATA 6,9,12,7,8,10,11,5,4,3,2,13,1,0
'DATA 2,3,4,5,6,7,8,9,1,0
'DATA 5,6,1,2,3,4,7,8,9,0

