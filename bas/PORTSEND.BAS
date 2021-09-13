'1999.11.6
DEFINT A-Z

CONST CurrentPort = 1, ByteSent = 2, ByteRecieved = 4
SCREEN 0: CLS : LOCATE , , 0

GOSUB DrawPortLabels

Port&(0) = 96: Port&(1) = 96
Update = CurrentPort
DO
    IF Update AND CurrentPort THEN
          LOCATE 1, 15: PRINT Port&(0); HEX$(Port&(0)); TAB(30);
          LOCATE 1, 53: PRINT Port&(1); HEX$(Port&(1)); TAB(700);
          Update = Update XOR CurrentPort
    END IF
    IF Update AND ByteSent THEN
          LOCATE 3, 18: IF Byte > 31 THEN PRINT char$;  ELSE PRINT "ù";
          PRINT TAB(20); Byte; HEX$(Byte); "   ";
          Update = Update XOR ByteSent
    END IF
    IF PortWatch OR (Update AND ByteRecieved) THEN
          Byte = INP(Port&(1))
          LOCATE 4, 18: IF Byte > 31 THEN PRINT CHR$(Byte);  ELSE PRINT "ù";
          PRINT TAB(20); Byte; HEX$(Byte); "   ";
          Update = 0
    END IF
    char$ = INKEY$
    IF LEN(char$) THEN
          DEF SEG = 0: IF PEEK(1047) AND 3 THEN InOut = 1 ELSE InOut = 0
          SELECT CASE char$
          CASE CHR$(27): EXIT DO
          CASE CHR$(0) + "H": Port&(InOut) = Port&(InOut) + 32 AND 65535: Update = CurrentPort
          CASE CHR$(0) + "P": Port&(InOut) = Port&(InOut) - 32 AND 65535: Update = CurrentPort
          CASE CHR$(0) + "M": Port&(InOut) = Port&(InOut) + 1 AND 65535: Update = CurrentPort
          CASE CHR$(0) + "K": Port&(InOut) = Port&(InOut) - 1 AND 65535: Update = CurrentPort
          CASE CHR$(0) + "I": Port&(InOut) = Port&(InOut) + 1024 AND 65535: Update = CurrentPort
          CASE CHR$(0) + "Q": Port&(InOut) = Port&(InOut) - 1024 AND 65535: Update = CurrentPort
          CASE CHR$(0) + "G": Port&(InOut) = 0: Update = CurrentPort
          CASE CHR$(0) + "O": Port&(InOut) = 65535: Update = CurrentPort
          CASE CHR$(0) + "R": IF PortWatch THEN PortWatch = 0 ELSE PortWatch = 1
          CASE CHR$(0) + "S": Update = ByteRecieved
          CASE ELSE: IF LEN(char$) = 1 THEN Byte = ASC(char$): OUT Port&(0), Byte: Update = ByteSent
          END SELECT
    END IF
LOOP

COLOR 7, 0: CLS
END

DrawPortLabels:
    PRINT "Output port --"; TAB(40); "Input port --";
    PRINT
    PRINT "Byte sent ------"
    PRINT "Byte recieved --"
    PRINT
    PRINT "Left/Right - 1  Up/Down - 32  PgUp/PgDn - 1024"
    PRINT
    PRINT "Ins - Toggle continous read mode"
    PRINT "Del - Read next byte from port"
    PRINT
    PRINT "Any other alphanumeric keys sends byte to port"
RETURN

