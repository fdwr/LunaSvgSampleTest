'Calendar
'2001-5-7
DEFINT A-Z

DIM SHARED MonthDaysYtd(12)

CONST JulianYearStart = -4387
CONST JulianYearEnd = 10000

'MonthDays(0) = 31
'MonthDays(1) = 28
'MonthDays(2) = 31
'MonthDays(3) = 30
'MonthDays(4) = 31
'MonthDays(5) = 30
'MonthDays(6) = 31
'MonthDays(7) = 31
'MonthDays(8) = 30
'MonthDays(9) = 31
'MonthDays(10) = 30
'MonthDays(11) = 31
MonthDaysYtd(0) = 0 'all these days are given for a non-leap year
MonthDaysYtd(1) = 31
MonthDaysYtd(2) = 59
MonthDaysYtd(3) = 90
MonthDaysYtd(4) = 120
MonthDaysYtd(5) = 151
MonthDaysYtd(6) = 181
MonthDaysYtd(7) = 212
MonthDaysYtd(8) = 243
MonthDaysYtd(9) = 273
MonthDaysYtd(10) = 304
MonthDaysYtd(11) = 334
MonthDaysYtd(12) = 365


YearStartDay = 3
PreDate = 0
CurDate = 0
StartDate = 0   'start of selection range
EndDate = 0

WIDTH 80, 50
CLS

RedrawCalendar:
ColCount = 0
SELECT CASE CalendarMode
CASE 0
    COLOR 9
    FOR Year = 1800 TO 2000
        IF ColCount >= 10 THEN ColCount = 0: PRINT
        ColCount = ColCount + 1
        PRINT STR$(Year);
    NEXT
CASE 1
    COLOR 9
    FOR Year = 1800 TO 1825
        PRINT STR$(Year);
        FOR Month = 1 TO 12: PRINT STR$(Month); : NEXT
        PRINT
    NEXT
CASE 2
    Month = 1
    Day = 1
    MonthCol = 0
    ColCount = YearStartDay MOD 7
    Row = 0
    Col = ColCount * 3
    Clr = 9
    LOCATE Row + 1, Col + 1
    COLOR Clr
    FOR YtdDay = 0 TO 364
        IF YtdDay >= MonthDaysYtd(Month) THEN
            Month = Month + 1
            IF Clr = 9 THEN Clr = 13 ELSE Clr = 9
            IF (Month AND 3) = 1 THEN
                Row = 0
                MonthCol = MonthCol + 22
                ColCount = (YearStartDay + YtdDay) MOD 7
                Col = ColCount * 3 + MonthCol
                LOCATE Row + 1, Col + 1
                IF Clr = 9 THEN Clr = 13 ELSE Clr = 9
            END IF
            Day = 1
            COLOR Clr
        END IF

        PRINT RIGHT$("  " + STR$(Day), 3);
        ColCount = ColCount + 1
        IF ColCount MOD 7 = 0 THEN
            Row = Row + 1
            Col = MonthCol
            ColCount = 0
            LOCATE Row + 1, Col + 1
        END IF
        Day = Day + 1
    NEXT
END SELECT

DO
    key$ = INKEY$
    IF LEN(key$) THEN
        SELECT CASE key$
        CASE CHR$(0) + "K": CurDate = CurDate - 1: GOSUB ChangeDate
        CASE CHR$(0) + "M": CurDate = CurDate + 1: GOSUB ChangeDate
        CASE CHR$(0) + "H": CurDate = CurDate - 7: GOSUB ChangeDate
        CASE CHR$(0) + "P": CurDate = CurDate + 7: GOSUB ChangeDate
        CASE CHR$(0) + "s"
            IF Month > 1 OR Year > JulianYearStart THEN
                Month = Month - 1
                IF Month <= 0 THEN Year = Year - 1
                GOSUB ChangeJulianDay
            END IF
        CASE CHR$(0) + "t"
            IF Month < 12 OR Year < JulianYearEnd THEN
                Month = Month + 1
                IF Month > 12 THEN Year = Year + 1
                GOSUB ChangeJulianDay
            END IF
        CASE CHR$(13)
            CLS
            CalendarMode = (CalendarMode + 1) MOD 3
            GOTO RedrawCalendar
        CASE CHR$(27)
            EXIT DO
        END SELECT
    ELSE
        'mouse input
    END IF

    'RedrawCalCell
    IF Redraw THEN
        'redraw changed elements
        Redraw = 0
    END IF
LOOP

END

ChangeDate:
    'recalculate year-month-day
    Redraw = Redraw OR 1
RETURN

ChangeJulianDay:
    'recalculate absolute julian day
RETURN

IF Month > 2 THEN 'if after February
    IF (Year AND 3) = 0 THEN 'if leap year
        IF (Year MOD 100 <> 0) OR (Year MOD 400 = 0) THEN
            LongDate = LongDate + 1
            PRINT "extra day"
        END IF
    END IF
END IF
FOR Count = 11 TO 0 STEP -1
    IF TempDate >= MonthDaysYtd(Count) THEN
        Month = Count + 1
        Day = TempDate - MonthDaysYtd(Count) + 1
        EXIT FOR
    END IF
NEXT

SUB RedrawCalCell (YtdDay AS LONG, LeapYear, YearStartDay)

IF YtdDay < 120 + LeapYear THEN 'Jan-April
    Col = 0
ELSEIF YtdDay < 243 + LeapYear THEN 'May-August
    Col = 21
ELSE 'Sept-Dec
    Col = 42
END IF

Col = Col + YearStartDay * 3

FOR Count = 11 TO 0 STEP -1
    IF YtdDay >= MonthDaysYtd(Count) THEN
        Month = Count + 1
        Day = TempDate - MonthDaysYtd(Count) + 1
        EXIT FOR
    END IF
NEXT

END SUB

