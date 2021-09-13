DEFINT A-Z

CONST EditFile$ = "c:\emu\saves\metroid.zs3"
CONST FilePos& = 88085
CONST FileValue& = &H8514
CONST FileValueInc& = &H1

OPEN EditFile$ FOR INPUT AS 1: CLOSE 1
OPEN EditFile$ FOR BINARY AS 1
SEEK 1, FilePos& + 1
GOSUB FileXorTest16bit
CLOSE 1

END

FileFill16bit:
    Value = FileValue&
    FOR Count = 0 TO 15
        PUT 1, , Value
        Value = Value + FileValueInc&
    NEXT
RETURN

FileFill32bit:
    Value& = FileValue&
    FOR Count = 0 TO 15
        PUT 1, , Value&
        Value& = Value& + FileValueInc&
    NEXT
RETURN

FileXorTest16bit:
    Value = FileValue&
    PUT 1, , Value
    BitMask = 1
    FOR Count = 0 TO 15
        Value = FileValue& XOR BitMask
        PUT 1, , Value
        IF BitMask AND -16384 THEN BitMask = -32768 ELSE BitMask = BitMask * 2
    NEXT
RETURN

