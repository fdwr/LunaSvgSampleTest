CLS

t = 0
a = 0'90
b = 90'180
s = .1
FOR c = a TO b STEP s
    t = t + COS(c * .0174532784356#)
NEXT
'PRINT s, s / 15.7
PRINT t, t * s / (b - a)

t = 0
a = 1.57
b = 3.14159
s = .01
FOR c = a TO b STEP .01
    t = t + COS(c)
NEXT
PRINT t, t * s / (b - a)

