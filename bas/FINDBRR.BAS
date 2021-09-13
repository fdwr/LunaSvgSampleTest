DEFINT A-Z
DECLARE SUB OpenFile (File$, FileHandle%)

CONST FileBufferSize = 8192
CONST TRUE = -1, FALSE = 0

DIM SHARED ErrorHandled
DIM FileBuffer AS STRING * FileBufferSize

GOSUB GetFilename
CALL OpenFile(SoundFile$, SoundFileHandle)
IF SoundFileHandle = 0 THEN
    PRINT "Could not open sound source file."
    END
END IF

CLS

FileLen& = LOF(SoundFileHandle)
FilePos& = 0
FileBufferBase& = 0'FileBufferSize
BrrBufferPos = 0
DO
    'gosub CheckFileBuffer
    GOSUB FindBrrSounds
    IF BrrMatch THEN
        PRINT FilePos&; TAB(10); ByteValue
    END IF
LOOP UNTIL INKEY$ = CHR$(27) OR FilePos& > FileLen&

CLOSE SoundFileHandle

END

FindBrrSounds:
    DEF SEG = VARSEG(FileBuffer)
    FileBufferAdr = VARPTR(FileBuffer)
    FOR BufferPos = BufferPos TO FileBufferSize - 1
        ByteValue = PEEK(BufferPos + FileBufferAdr)
        'if loop and end bits are not set
        IF (ByteValue AND 3) = 0 THEN
            'if range is less than 13 (13*16=208)
            IF ByteValue < 208 THEN
                BytePos = BufferPos + FileBufferAdr
                'if ByteValue | peek(BytePos+9)
                FilePos& = FileBufferBase& + BufferPos
                BrrMatch = TRUE
                BufferPos = BufferPos + 1
                RETURN
            END IF
        END IF
        'if match then exit
    NEXT BufferPos
    BrrMatch = FALSE
    FilePos& = FileBufferBase& + BufferPos
RETURN

CheckFileBuffer:
RETURN

GetFilename:
    SoundFile$ = "c:\dw\emu\zelda.smc"
RETURN

ErrorHandler:
    ErrorHandled = ERR
RESUME NEXT

SUB OpenFile (File$, FileHandle)

ON ERROR GOTO ErrorHandler
ErrorHandled = 0

FileHandle = FREEFILE
OPEN File$ FOR INPUT AS FileHandle
IF ErrorHandled THEN
    FileHandle = 0
ELSE
    CLOSE FileHandle
    ErrorHandled = 0
    OPEN File$ FOR BINARY AS FileHandle
    IF ErrorHandled THEN
        FileHandle = 0
    END IF
END IF
ON ERROR GOTO 0

END SUB

