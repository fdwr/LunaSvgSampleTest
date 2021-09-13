' 2003-12-17 Dwayne Robinson
' Simply calcs pi.
' Tested on P90. Calcs the first few places instantly, but needs
' 5 million iterations to give about 7 places of significance.
DIM pi AS DOUBLE
DIM n AS DOUBLE

CLS

pi = 0  'accumulated value of pi, gets closer each iteration
n = 1   'denominator
c = 0   'display counter, to speed calc by only displayng so often
DO
    pi = pi + 6 / (n * n)
    n = n + 1
    c = c + 1
    IF c >= 200 THEN
        PRINT pi, SQR(pi), n
        IF CSRLIN >= 40 THEN
            LOCATE 1            'put cursor back at top rather than scroll
            IF LEN(INKEY$) THEN EXIT DO
        END IF
        c = 0
    END IF
LOOP

