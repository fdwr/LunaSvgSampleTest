DEFINT A-Z

CONST MaxWords = 10

DIM SourceWords AS STRING
DIM DestWords AS STRING
DIM SourceWordPos(MaxWords - 1) AS INTEGER
DIM DestWordPos(MaxWords - 1) AS INTEGER
DIM Char AS STRING
DIM TotalWords AS INTEGER

SourceWords = "this is a test of the emergency broadcast system "

CLS
GOSUB ParseWords
DestWords = SPACE$(TotalWords)
DO
    GOSUB InsertWords
    GOSUB PrintWords
    PreTime# = TIMER
    DO: LOOP UNTIL TIMER - PreTime# > .1
LOOP UNTIL LEN(INKEY$)

END

ParseWords:
    TotalWords = 0
    SourceWordPos(0) = 1
    FOR CharPos = 1 TO LEN(SourceWords)
        IF MID$(SourceWords, CharPos, 1) = " " THEN
            DestWordPos(TotalWords) = TotalWords + 1
            TotalWords = TotalWords + 1
            PRINT "Word ended at"; CharPos; "Total words are now"; TotalWords
            IF TotalWords >= MaxWords THEN EXIT FOR
            SourceWordPos(TotalWords) = CharPos + 1
        END IF
    NEXT CharPos
RETURN

InsertWords:
    WordAdjust = 0
    SourceLen = LEN(SourceWords)
    FOR Count = 0 TO TotalWords - 1
        CharPos = SourceWordPos(Count)
        DestPos = DestWordPos(Count) + WordAdjust
        'IF CharPos < SourceLen THEN
        Char = MID$(SourceWords, CharPos, 1)
        IF Char <> " " THEN
            DestWords = LEFT$(DestWords, DestPos - 1) + Char + MID$(DestWords, DestPos)
            WordAdjust = WordAdjust + 1
            SourceWordPos(Count) = CharPos + 1
            DestPos = DestPos + 1
        'ELSE
        '    SourceWordPos(Count) = SourceLen
        'END IF
        END IF
        DestWordPos(Count) = DestPos
    NEXT Count
RETURN

PrintWords:
    LOCATE 12, 1
    PRINT DestWords;
RETURN

