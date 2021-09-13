'File Part
'Dwayne Robinson
'2001-05-24
'
'Transfers a specified chunk from one file into another. For example, if you
'wanted to export a single icon from an executable or font set from a game,
'this program would help you. After specifying the source and destination
'files, simply tell it where to start the transfer from and how many bytes to
'transfer.
DEFINT A-Z

TYPE Register
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Fl AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

CONST FileBufferSize = 8192

DIM SHARED Regs AS Register, ErrHandled
DIM FileBuffer AS STRING
DIM Params AS STRING, Word AS STRING

DIM SrcFile AS STRING   'c:\emu\zelda64.rom
DIM DestFile AS STRING  'c:\emu\z64fonts.bin"
DIM SrcStart AS LONG    '&H4DA000
DIM SrcLength AS LONG   '65536
DIM DestStart AS LONG   '0


DestStart = -1

GOSUB GetParameters

'open files
ErrHandled = 0
ON ERROR GOTO ErrHandler
OPEN SrcFile$ FOR INPUT AS 1: CLOSE 1
IF ErrHandled THEN
    PRINT "Could not open source file"
    GOTO ProgramEnd
END IF
OPEN SrcFile$ FOR BINARY AS 1
OPEN DestFile$ FOR BINARY AS 2

'set transfer variables
IF SrcLength <= 0 THEN SrcLength = LOF(1) 'transfer entire file
IF SrcLength <= 0 THEN
    PRINT "Source file is empty"
    GOTO CloseFiles
END IF
IF DestStart < 0 THEN DestStart = LOF(2)  'append

'transfer file in chunks
SEEK 1, SrcStart + 1
SEEK 2, DestStart + 1
Count& = SrcLength
FileBuffer = SPACE$(FileBufferSize)
DO UNTIL Count& >= FileBufferSize
    GET 1, , FileBuffer
    PUT 2, , FileBuffer
    IF ErrHandled THEN GOTO TransferError
    LOCATE , 1: PRINT Count&;
    Count& = Count& - FileBufferSize
LOOP
'transfer last remaining chunk
IF Count& > 0 THEN
    FileBuffer = SPACE$(Count&)
    GET 1, , FileBuffer
    PUT 2, , FileBuffer
    IF ErrHandled THEN GOTO TransferError
    LOCATE , 1: PRINT Count&;
END IF
LOCATE , 1: PRINT "Part transferred"

'truncate file to size
IF TruncateDest THEN
    Regs.Ax = &H4000          'DOS: write data using file handle
    Regs.Bx = FILEATTR(2, 2)  'The true DOS file handle, not Qbasic's
    Regs.Cx = 0               'Number of bytes to write, none
    Regs.Ds = 0
    Regs.Dx = 0
    CALL INTERRUPTX(&H21, Regs, Regs)
END IF

CloseFiles:
CLOSE 2, 1

ProgramEnd:
END

'Parses any parameters on the command line
GetParameters:
    Params = COMMAND$
    ParamsLen = LEN(Params)
    CharPos = 1
    'ParamPart = 0

    DO
        GOSUB GetNextParam
        IF LEN(Word) THEN
            IF LEFT$(Word, 1) = "/" THEN
                SELECT CASE MID$(Word, 2)
                CASE "T": TruncateDest = -1
                CASE "M": MultiPart = -1
                END SELECT
            ELSE
                SELECT CASE ParamPart
                CASE 0: SrcFile = Word
                CASE 1: DestFile = Word
                CASE 2: SrcStart = VAL(Word)
                CASE 3: SrcLength = VAL(Word)
                CASE 4: DestStart = VAL(Word)
                END SELECT
                ParamPart = ParamPart + 1
            END IF
        ELSE
            EXIT DO
        END IF
    LOOP

    'parameter error
    IF ParamPart < 4 THEN
        IF ParamsLen <= 0 THEN
            PRINT "FilePart"
            PRINT "Dwayne Robinson"
            PRINT "2001-05-24"
            PRINT
            PRINT "Transfers a specified chunk from one file into another. For example, if you"
            PRINT "wanted to export a single icon from an executable or font set from a game,"
            PRINT "this program would help you. After specifying the source and destination"
            PRINT "files, simply tell it where to start the transfer from and how many bytes to"
            PRINT "transfer."
        ELSE
            SELECT CASE ParamPart
            CASE 0: PRINT "Need source file"
            CASE 1: PRINT "Need destination file"
            CASE 2: PRINT "Need source starting position"
            CASE 3: PRINT "Need source transfer length"
            END SELECT
        END IF

        PRINT
        PRINT "Usage:  filepart [/options] SrcFile DestFile SrcStart SrcLength [DestStart]"
        PRINT
        PRINT "SrcFile - source file to read from"
        PRINT "DestFile - destination file to write to"
        PRINT "SrcStart - file byte position to start transfer from"
        PRINT "SrcLength - number of bytes to transfer"
        PRINT "DestStart - destination file position (append assumed)"
        PRINT
        PRINT "/T - truncate destination file to transfer length"

        GOTO ProgramEnd
    END IF
RETURN

GetNextParam:
    IF CharPos > ParamsLen THEN Word = "": RETURN

    DO UNTIL MID$(Params, CharPos, 1) <> " "
        CharPos = CharPos + 1
    LOOP
    NextPos = CharPos
    DO UNTIL NextPos > ParamsLen OR MID$(Params, NextPos, 1) = " "
        NextPos = NextPos + 1
    LOOP

    Word = MID$(Params, CharPos, NextPos - CharPos)
    CharPos = NextPos
RETURN

ErrHandler:
    ErrHandled = ERR
RESUME NEXT

TransferError:
    PRINT
    PRINT "An error occurred while transferring the file data:"; ErrHandled
    PRINT "Ending program..."
GOTO CloseFiles

