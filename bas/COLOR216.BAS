'2001.4.11
DEFINT A-Z

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Fl AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

CONST OutFile$ = "color216.bmp"
ImportantColors = 256'216
ColorsBase = 16'0

'  0    |   2    | (BM) - Tells us that the picture is in bmp format
'  2    |   4    | Size of the file (without header?)
'  6    |   2    | (0) Reserved1 - Must be zero
'  8    |   2    | (0) Reserved2 - Must be zero
'  10   |   4    | Number of bytes offset of the picture data
'-------+--------+--- Information Header starts here -----------------
'  14   |   4    | (40/12) Size of information header (Win3.1/OS2)
'  18   |   4    | Picture width in pixels
'  22   |   4    | Picture Height in pixels
'  26   |   2    | (1) Number of planes, must be 1
'  28   |   2    | Number of bits per pixel (bpp), must be 1,4,8 or 24
'  30   |   4    | (0) Compression - 0 means no compression, 1,2 are RLEs
'  34   |   4    | Image size in bytes
'  38   |   4    | picture width in pels per metre
'  42   |   4    | picture height in pels per metre
'  46   |   4    | (0) Number of colours used in the picture, 0 means all
'  50   |   4    | (0) Number of important colours, 0 means all

STOP 'this stop is simply here to let you know that this program
     'will create a file, a bitmap with the standard 216 color palette in it.
     'if you do not want this to happen, end the program now...

ON ERROR GOTO 0
OPEN OutFile$ FOR OUTPUT AS #1

PRINT #1, "BM"; MKL$((54 + 1024 + (ImportantColors * 4)) \ 4); MKL$(0); MKL$(54 + (ImportantColors * 4));
PRINT #1, MKL$(40); MKL$(ImportantColors); MKL$(4); MKL$(&H80001); MKL$(0);
PRINT #1, MKL$(ImportantColors * 4); MKL$(0); MKL$(0); MKL$(ImportantColors); MKL$(ImportantColors);

FileBuffer$ = STRING$(ImportantColors * 4, 0)
'RedVal=0: GrnVal=0: BluVal=0
Offset = ColorsBase * 4
FOR Count = 1 TO 216 * 4 STEP 4
    MID$(FileBuffer$, Count + Offset, 4) = MKL$(BluVal& OR GrnVal& OR RedVal&)
    'MKL$(BluVal * 4 OR GrnVal * 1024& OR RedVal * 262144)
    BluVal& = BluVal& + 51
    IF BluVal& > 255 THEN
        BluVal& = 0
        GrnVal& = GrnVal& + 13056
        IF GrnVal& > 65280 THEN
            GrnVal& = 0
            RedVal& = RedVal& + 3342336
            IF RedVal& > 16711680 THEN
                RedVal& = 0
            END IF
        END IF
    END IF
NEXT
PRINT #1, FileBuffer$;

'SEEK 1, 1079
FileBuffer$ = STRING$(ImportantColors, 0)
FOR Count = 0 TO ImportantColors - 1
    MID$(FileBuffer$, Count + 1, 1) = CHR$((Count + ColorsBase) AND 255)
NEXT
FOR Count = 1 TO 4
    PRINT #1, FileBuffer$;
NEXT

CLOSE 1

