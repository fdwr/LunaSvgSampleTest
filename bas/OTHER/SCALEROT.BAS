'****************************************************************************'
'                            Rotation and Scaling                            '
'                                                                            '
'                           Done by the 'qbasic-er'                          '
'                      Email: qbasic-er@geocities.com                        '
'                                                                            '
'   This program was made and completed in about three hours of work. There  '
'are comments below on how to use the sub routine for scaling and rotating.  '
'feel free to fix what you think is wrong. The scaling routine could be      '
'improved for more speed (do it in another language). I have already tried it'
'in C, but the improvement was minimal.                                      '
'                                                                            '
'                        The Qbasic Programming Page:                        '
'          http://www.geocities.com/SiliconValley/Pines/1648/index.html      '
'                                                                            '
'****************************************************************************'


DEFINT A-Z

DECLARE SUB ClearScreen ()
DECLARE SUB WaitForKeyPress ()
DECLARE SUB Scale (Array%(), x0%, y0%, x1%, y1%, bw%, bh%, Angle%)

'*** rotation declares and assigning***

DIM SHARED SinTable(0 TO 360) AS SINGLE
DIM SHARED CosTable(0 TO 360) AS SINGLE

FOR cnt = 0 TO 360
  CosTable(cnt) = COS(cnt * 3.14159 / 180)
  SinTable(cnt) = SIN(cnt * 3.14159 / 180)
NEXT cnt

'*** Bitmap declares and assigning ***

DIM Bitmap(32, 32)

FOR x = 1 TO 32
  FOR y = 1 TO 32
    Bitmap(x, y) = 16 + x + y
  NEXT
NEXT

'****************************************************************************'
'   The first is the array where the bitmap is stored. The next four are the '
'x, y, x2, y2 coordinates where we are going to scale the bitmap into. The   '
'next two are the x and y sizes of the bitmap. Finally the last is the angle '
'which the bitmap is to be rotated at. See example.                          '
'                                                                            '
'Example:                                                                    '
'   Scale Array(), x%, y%, x2%, y2%, BitmapXsize%, BitmapYsize%, Angle%      '
'                                                                            '
'Note:                                                                       '
'   BmXs is the Bitmap X size                                                '
'   BmYs is the Bitmap Y size                                                '
'                                                                            '
'****************************************************************************'

SCREEN 13

BmXs = 32
BmYs = 32

LOCATE 1, 1: PRINT "Normal Bitmap : 32x32"
Scale Bitmap(), 140, 80, 172, 112, BmXs, BmYs, 0

WaitForKeyPress
ClearScreen

LOCATE 1, 1: PRINT "Scaled Bitmap : 83x65";
Scale Bitmap(), 100, 60, 183, 125, BmXs, BmYs, 0

WaitForKeyPress
ClearScreen

LOCATE 1, 1: PRINT "Scaled Bitmap : 30x14";
Scale Bitmap(), 140, 90, 170, 104, BmXs, BmYs, 0

WaitForKeyPress
ClearScreen

LOCATE 1, 1: PRINT "Rotated Bitmaps : 32x32 at 34" + CHR$(248) + " and 246" + CHR$(248)
Scale Bitmap(), 130, 30, 162, 62, BmXs, BmYs, 34
Scale Bitmap(), 130, 100, 162, 132, BmXs, BmYs, 246

WaitForKeyPress
ClearScreen

LOCATE 1, 1: PRINT "Rotated & Scaled Bitmap : 83x102 at 168" + CHR$(248)
Scale Bitmap(), 108, 50, 191, 152, BmXs, BmYs, 168

WaitForKeyPress
ClearScreen

SUB ClearScreen

LINE (0, 0)-(319, 199), 0, BF

END SUB

SUB Scale (Array(), x0, y0, x1, y1, bw, bh, Angle)

FOR x = x0 TO x1
 
  FOR y = y0 TO y1
   
    u = bw * (x - x0) / (x1 - x0)
    v = bh * (y - y0) / (y1 - y0)
     
      IF Angle <> 0 THEN
         
          Tx = ((x1 - x0) / 2) - (x1 - x)
          Ty = ((y1 - y0) / 2) - (y1 - y)
          nx = Tx * CosTable(Angle) - Ty * SinTable(Angle)
          ny = Ty * CosTable(Angle) + Tx * SinTable(Angle)
            nx = x0 + nx + ((x1 - x0) / 2)
            ny = y0 + ny + ((y1 - y0) / 2)
               
        PSET (nx, ny - 1), Array(u, v)
        PSET (nx - 1, ny), Array(u, v)
        PSET (nx + 1, ny), Array(u, v)
        PSET (nx, ny + 1), Array(u, v)
       
      ELSE
         
          nx = x * CosTable(Angle) - y * SinTable(Angle)
          ny = y * CosTable(Angle) + x * SinTable(Angle)

      END IF
         
        PSET (nx, ny), Array(u, v)
 
  NEXT

NEXT

END SUB

SUB WaitForKeyPress

null$ = INPUT$(1)

END SUB

