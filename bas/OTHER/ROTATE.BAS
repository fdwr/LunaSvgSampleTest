'2d texture zooom/rotation demo
'by Toshihiro Horie
'toshiman@uclink4.berkeley.edu

'possible optimizations:
'1) integer sinus tables
'2) defint a-z (after 1)
'3) reverse rotation mapping
CONST pi = 3.14159
xh = 40: yh = 30: ch = 16
xd = 320: yd = 170
v = 0: w = 1
SCREEN 9, , v, w
'plot some points in a box
LINE (0, 0)-(xh, yh), 15, B
DIM block(xh, yh)
FOR t = 1 TO 100
    x = INT(RND * xh): y = INT(RND * yh)
    c = INT(RND * ch)
    PSET (x, y), c
    block(x, y) = c
NEXT
'rotate it about its center
z = 0
FOR a = 0 TO pi STEP .01
        z = z + 1
        IF z > 26 THEN END
    LOCATE 1, 1: PRINT z
    Ca = COS(a)
    Sa = SIN(a)
    FOR x = 0 TO xh
    xo = (x - xh \ 2)
    FOR y = 0 TO yh
        yo = (y - yh \ 2)
        xp = xo * Ca - yo * Sa * z
        yp = yo * Ca + xo * Sa * z
        PSET (xp + xd, yp + yd), block(x, y)
    NEXT: NEXT:
    SWAP v, w: SCREEN 9, , v, w: CLS
NEXT

