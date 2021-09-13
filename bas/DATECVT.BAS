DECLARE SUB PrintDate (Year%, Month%, Day%, LongDate AS LONG)
'2001.4.25
'Date Conversions
'Dwayne Robinson
'
'Apparently I've been alive 7560 days,
'The time difference between being born and writing this program.
'
'!!LongToDate does not work correctly with leap years on Dec.31
DEFINT A-Z
DECLARE SUB DateToLong (Year, Month, Day, LongDate AS LONG)
DECLARE SUB LongToDate (Year, Month, Day, LongDate AS LONG)

DIM SHARED JulMonthDays(11)
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
JulMonthDays(0) = 0 'all these days are given for a non-leap year
JulMonthDays(1) = 31
JulMonthDays(2) = 59
JulMonthDays(3) = 90
JulMonthDays(4) = 120
JulMonthDays(5) = 151
JulMonthDays(6) = 181
JulMonthDays(7) = 212
JulMonthDays(8) = 243
JulMonthDays(9) = 273
JulMonthDays(10) = 304
JulMonthDays(11) = 334

DIM DateLong AS LONG, DateLong2 AS LONG

WIDTH 80, 50
CLS
'FOR Count = 0 TO 11: PRINT JulMonthDays(Count): NEXT

Year = 1952: Month = 10: Day = 5
'Year = 1980: Month = 8: Day = 13
DateToLong Year, Month, Day, DateLong
PrintDate Year, Month, Day, DateLong
Year = 2001: Month = 4: Day = 25
DateToLong Year, Month, Day, DateLong2
PrintDate Year, Month, Day, DateLong2
PRINT DateLong2 - DateLong; "days"
PRINT

Year = 5: Month = 1: Day = 1
'Year = 1: Month = 1: Day = 1
'Year = 5: Month = 1: Day = 1
DateToLong Year, Month, Day, DateLong
PrintDate Year, Month, Day, DateLong
LongToDate Year, Month, Day, DateLong
PrintDate Year, Month, Day, DateLong

'Converts Gregorian Calendar date to linear date (32bit long)
SUB DateToLong (Year, Month, Day, LongDate AS LONG)

'simple calculation, not considering leap years
TempYear = Year - 1
IF Month <= 0 OR Month > 12 THEN Month = 1
LongDate = TempYear * 365& + JulMonthDays(Month - 1) + (Day - 1)
PRINT "without leap year accumulation"; LongDate
PRINT "days since beginning of year"; JulMonthDays(Month - 1) + (Day - 1)

'now calculate leap year accumulation into date
PRINT "leap year accumulation"; (TempYear \ 4) - (TempYear \ 100) + (TempYear \ 400)
LongDate = LongDate + (TempYear \ 4) - (TempYear \ 100) + (TempYear \ 400)
'   mov eax,[Year]
'   mov esi,365
'   mov ebx,[Month]
'   mov ecx,eax
'   imul esi        ;Year * 365
'   add eax,[JulMonths + ebx]
'   shr ecx,2       ;\4
'   add eax,[Day]
'   mov ebx,25
'   add eax,ecx     ;+= (Year \ 4)
'   xor edx,edx
'   div ebx         ;\100 [4*25]
'   sub eax,ecx     ;-= (Year \ 100)
'   shr ecx,2       ;\400 [4*25*4]
'   add eax,ecx     ;+= (Year \ 400)

' if month is after February, then determine if it is a leap year
'   if year is evenly divisible by four
'     if not divisible by one hundred
'     or if divisible by four hundred
'       leap year, so add one to day
'     endif
'   endif
' endif
IF Month > 2 THEN 'if after February
    IF (Year AND 3) = 0 THEN 'if leap year
        IF (Year MOD 100 <> 0) OR (Year MOD 400 = 0) THEN
            LongDate = LongDate + 1
            PRINT "extra day"
        END IF
    END IF
END IF
'   mov ecx,[Year]
'   cmp ebx,2
'   jb .NoLeap      ;not past February so ignore leap year
'   test ecx,3
'   jnz .NoLeap     ;not evenly divisible by four, so not leap year
'   mov ebx,100
'   xchg eax,ecx    ;swap with eax for sake of stupid DIV instruction
'   xor edx,edx
'   div ebx         ;Year \ 100
'   xchg eax,ecx
'   test edx,edx
'   jnz .IsLeap     ;not evenly divisible by one hundred, so is leap year
'   test eax,3
'   jnz .NoLeap     ;not evenly divisible by four hundred, so not leap year
'.IsLeap
'   inc eax
'.NoLeap:

END SUB

'Converts Linear date (32bit long) to Gregorian Calendar date
SUB LongToDate (Year, Month, Day, LongDate AS LONG)

DIM TempDate AS LONG

'remove leap year accumulation from date
'PRINT (((LongDate MOD 146097) MOD 36524) MOD 1461) MOD 365
TempDate = LongDate - (LongDate \ 146097)
TempDate = TempDate + (TempDate \ 36524)
TempDate = TempDate - ((TempDate - 365) \ 1461)
PRINT "leap year accumulation"; LongDate - TempDate
'? (((365&*4)+1)*25-1)*4+1
PRINT "without leap years"; TempDate

IF TempDate MOD 1460 = 0 THEN
    Year = TempDate \ 365
    'TempDate = TempDate MOD 365&
    Month = 12
    Day = 31
ELSE
    Year = TempDate \ 365 + 1
    IF (TempDate MOD 1461) = 0 THEN
    ELSE
        TempDate = TempDate MOD 365&
    END IF

    PRINT "days since beginning of year"; TempDate
    'Day = TempDate
    IF TempDate >= 59 THEN
        IF (Year AND 3) = 0 THEN
            IF (Year MOD 100 <> 0) OR (Year MOD 400 = 0) THEN
                TempDate = TempDate - 1
            END IF
        END IF
    END IF
    FOR Count = 11 TO 0 STEP -1
        IF TempDate >= JulMonthDays(Count) THEN
            Month = Count + 1
            Day = TempDate - JulMonthDays(Count) + 1
            EXIT FOR
        END IF
    NEXT

END IF

END SUB

SUB PrintDate (Year, Month, Day, LongDate AS LONG)

COLOR 15
PRINT MID$(STR$(Year), 2) + "-" + RIGHT$(STR$(Month + 100), 2) + "-" + RIGHT$(STR$(Day + 100), 2) + " =" + STR$(LongDate)
COLOR 7

END SUB

