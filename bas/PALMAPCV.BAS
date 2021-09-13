'Palette Map Converter
'2002-03-15

DEFINT A-Z
'OPEN "\src\asm\image.pal" FOR BINARY AS 1
OPEN "\src\win\DRAWTEST.RGB" FOR BINARY AS 1
OPEN "\src\win\DRAWTEST.PAL" FOR BINARY AS 2

TYPE RgbTupleType
Red AS STRING * 1
Grn AS STRING * 1
Blu AS STRING * 1
END TYPE

DIM RgbTuple AS RgbTupleType
DIM RgbLong AS LONG
DIM RedDiv AS LONG, GrnDiv AS LONG, BluDiv AS LONG
DIM RedMul AS LONG, GrnMul AS LONG, BluMul AS LONG

'r \ 8
'g \ 4 * 32
'b \ 8 * 2048

PixelBits = 15
SELECT CASE PixelBits
CASE 15
    RedDiv = 2: GrnDiv = 2: BluDiv = 2
    RedMul = 1024&: GrnMul = 32&: BluMul = 1&
CASE 16
    RedDiv = 2: GrnDiv = 4: BluDiv = 2
    RedMul = 2048&: GrnMul = 32&: BluMul = 1&
CASE 24, 32
    RedDiv = 1: GrnDiv = 1: BluDiv = 1
    RedMul = 262144: GrnMul = 1024&: BluMul = 4&
END SELECT

CLS
FOR Count = 0 TO 255
    GET 1, , RgbTuple
    RgbLong = (ASC(RgbTuple.Blu) \ BluDiv) * BluMul OR (ASC(RgbTuple.Grn) \ GrnDiv) * GrnMul OR (ASC(RgbTuple.Red) \ RedDiv) * RedMul
    PRINT HEX$(RgbLong); " ";
    PUT 2, , RgbLong
NEXT

CLOSE 2, 1

