DECLARE SUB OutputLine (ByteStrip$)
'This program creates a little level for ChipChal.Bas
'After it is run and makes the file, run ChipChal to view it

DEFINT A-Z
OPEN "\DW\DRAW\CHIPCHAL.LVL" FOR OUTPUT AS #1

PRINT #1, MKI$(0);
PRINT #1, CHR$(12);
PRINT #1, CHR$(15);

OutputLine "BBBBBBBBBBBBBBBB"
OutputLine "B@@@@@@@@@@@@@@B"
OutputLine "B@@@AAAAAAAAAA@B"
OutputLine "BAAAAACCCCAAAA@B"
OutputLine "BFFFAAC@@CAAAA@B"
OutputLine "BFFFCEE@@CAAAA@B"
OutputLine "BAABBCEC@@@@@@@B"
OutputLine "BAACDCECDDCCCCCB"
OutputLine "BCCCDCCCDDBBBBBB"
OutputLine "BDDDDDDDDDAAAAAB"
OutputLine "BBBBBBB@DDDDDD@B"
OutputLine "B@@@@@@@@@@@@@@B"
OutputLine "BBBBBBBBBBBBBBBB"

CLOSE #1

SUB OutputLine (ByteStrip$)

FOR CurByte = 1 TO LEN(ByteStrip$)
 Byte = ASC(MID$(ByteStrip$, CurByte, 1)) - 64
 PRINT #1, CHR$(Byte);
NEXT CurByte

END SUB

