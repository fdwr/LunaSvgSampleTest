DEFINT A-Z

CONST SpcC = 1, SpcZ = 2, SpcI = 4, SpcH = 8, SpcB = 16, SpcP = 32, SpcV = 64, SpcN = 128
CONST EmuC = 1, EmuZ = 64, EmuI = 4, EmuH = 16, EmuB = 8, EmuP = 32, EmuV = 2, EmuN = 128

PRINT "Building table for byte values into flags..."
OPEN "flagtbl.dat" FOR OUTPUT AS 1
FOR Count = 0 TO 255
    IF Count AND SpcC THEN ByteValue = EmuC ELSE ByteValue = 0
    IF Count AND SpcZ THEN ByteValue = ByteValue OR EmuZ
    IF Count AND SpcI THEN ByteValue = ByteValue OR EmuI
    IF Count AND SpcH THEN ByteValue = ByteValue OR EmuH
    IF Count AND SpcB THEN ByteValue = ByteValue OR EmuB
    IF Count AND SpcP THEN ByteValue = ByteValue OR EmuP
    IF Count AND SpcV THEN ByteValue = ByteValue OR EmuV
    IF Count AND SpcN THEN ByteValue = ByteValue OR EmuN
    PRINT #1, CHR$(ByteValue);
NEXT Count
CLOSE 1

END

