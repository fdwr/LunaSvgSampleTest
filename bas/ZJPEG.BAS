DEFINT A-Z
DECLARE FUNCTION GetFileList$ (FileMask$, FileType%)

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

DIM SHARED Regs AS RegisterType, FileError, LongFileNames

CONST ExtractorProgram$ = "..\dos4gw.exe ..\jpg.exe "



PRINT "Extracting jpeg's from all data files in directory..."

FileName$ = GetFileList$("*.dat", 239)
DO WHILE LEN(FileName$)
    TotalFiles = TotalFiles + 1
    COLOR 12: PRINT FileName$; : COLOR 7: PRINT TAB(16); TotalFiles
    SHELL ExtractorProgram$ + FileName$
    FileName$ = GetFileList$("", 239)
LOOP

PRINT "Total files searched:"; TotalFiles
END

FUNCTION GetFileList$ (FileMask$, FileType) STATIC
 
    DIM DTA AS STRING * 320
    Count = 150

    IF LongFileNames = 0 THEN
        Regs.Ax = &H1A00                   'Set DTA function
        Regs.Dx = VARPTR(DTA)              'DS:DX points to our DTA
        Regs.Ds = VARSEG(DTA)
        CALL InterruptX(&H21, Regs, Regs)  'Do the interrupt
    END IF

    IF LEN(FileMask$) THEN 'FindFirst
        FileSpec$ = FileMask$ + CHR$(0)
        IF LongFileNames THEN
            Regs.Ax = &H714E
            Regs.Es = VARSEG(DTA)
            Regs.Di = VARPTR(DTA)
            Regs.Si = 0
            Regs.Flags = 0
        ELSE
            Regs.Ax = &H4E00
        END IF
        Regs.Cx = FileType
        Regs.Dx = SADD(FileSpec$)
        Regs.Ds = VARSEG(FileSpec$)
        FindFirst = 1
    ELSE 'FindNext

GetNextFile:
        IF LongFileNames THEN
            Regs.Ax = &H714F
            Regs.Bx = DirHandle
            Regs.Es = VARSEG(DTA)
            Regs.Di = VARPTR(DTA)
            Regs.Si = 0
            Regs.Flags = 0
        ELSE
            Regs.Ax = &H4F00
            Regs.Dx = SADD(FileSpec$)
            Regs.Ds = VARSEG(FileSpec$)
        END IF
    END IF
  
    CALL InterruptX(&H21, Regs, Regs)
    IF FindFirst THEN FileTypeWanted = FileType: DirHandle = Regs.Ax: FindFirst = 0

    IF Regs.Flags AND 1 THEN 'Error
        FileError = Regs.Ax
        GetFileList$ = ""     'Return null string
        IF LongFileNames THEN 'free Win95 handle
            Regs.Ax = &H71A1
            Regs.Bx = DirHandle
            CALL InterruptX(&H21, Regs, Regs)
        END IF
    ELSE
        IF LongFileNames THEN
            FileType = ASC(MID$(DTA, 1, 1))
            BaseChar = 45
        ELSE
            FileType = ASC(MID$(DTA, 22, 1))
            BaseChar = 31
        END IF
        IF FileType AND FileTypeWanted THEN
            CurChar = INSTR(BaseChar, DTA, CHR$(0))
            GetFileList$ = MID$(DTA, BaseChar, CurChar - BaseChar)
        ELSEIF Count > 0 THEN
            Count = Count - 1: GOTO GetNextFile
        END IF
  END IF

END FUNCTION

