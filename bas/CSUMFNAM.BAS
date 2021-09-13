'Savestate viewer for ZSNES
'Started Aug 5, 1998 by FDwR

DEFINT A-Z
OPTION BASE 0

DECLARE FUNCTION GetShortFileName$ (FileName$)
DECLARE FUNCTION GetFileList$ (FileMask$, FileType)

DIM SHARED LongFileNames AS INTEGER


TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
BP AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

DIM SHARED Regs AS RegisterType, FileError AS INTEGER
DIM CsumFnam(1000) AS INTEGER

COLOR 11: CLS

LongFileNames = 1
FileName$ = GetFileList("C:\WINDOWS\*.*", 239)

MaxCsum = 0
MinCsum = 32767
FOR TotalFnams = 0 TO UBOUND(CsumFnam)
    IF LEN(FileName$) <= 0 THEN EXIT FOR

    NameSum = 0
    FOR CharPos = 1 TO LEN(FileName$)
        NameSum = NameSum + ASC(MID$(FileName$, CharPos, 1))
    NEXT
    PRINT NameSum, FileName$
    CsumFnam(TotalFnams) = NameSum
    IF NameSum < MinCsum THEN MinCsum = NameSum
    IF NameSum > MaxCsum THEN MaxCsum = NameSum

    FileName$ = GetFileList("", 0)
NEXT


'END

PRINT "Minumum csum:"; MinCsum
PRINT "Maximum csum:"; MaxCsum

CLS
SCREEN 12
FOR Count = 0 TO TotalFnams - 1
    PSET (CsumFnam(Count) \ 4, Count), 15
NEXT


END

FileErrHandler:
  FileError = ERR
RESUME NEXT

FUNCTION GetFileList$ (FileMask$, FileType) STATIC
    
  DIM DTA AS STRING * 320
  Count = 150

  IF LongFileNames = 0 THEN
    Regs.Ax = &H1A00                   'Set DTA function
    Regs.Dx = VARPTR(DTA)              'DS:DX points to our DTA
    Regs.Ds = -1                       'Use current value for DS
    CALL InterruptX(&H21, Regs, Regs)  'Do the interrupt
  END IF
    
  IF LEN(FileMask$) THEN 'FindFirst
    FileSpec$ = FileMask$ + CHR$(0)
    IF LongFileNames THEN
      Regs.Ax = &H714E
      Regs.Es = -1
      Regs.Di = VARPTR(DTA)
      Regs.Si = 0
      Regs.Flags = 0
    ELSE Regs.Ax = &H4E00
    END IF
    Regs.Cx = FileType
    Regs.Dx = SADD(FileSpec$)
    Regs.Ds = -1
    FindFirst = 1
  ELSE 'FindNext

GetNextFile:
    IF LongFileNames THEN
      Regs.Ax = &H714F
      Regs.Bx = DirHandle
      Regs.Es = -1
      Regs.Di = VARPTR(DTA)
      Regs.Si = 0
      Regs.Flags = 0
    ELSE Regs.Ax = &H4F00
    END IF
  END IF
    
  CALL InterruptX(&H21, Regs, Regs)
  IF FindFirst THEN FileTypeWanted = FileType: DirHandle = Regs.Ax: FindFirst = 0

  IF Regs.Flags AND 1 THEN 'Error
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
    ELSEIF Count > 0 THEN Count = Count - 1: GOTO GetNextFile
    END IF
  END IF

END FUNCTION

FUNCTION GetShortFileName$ (FileName$)

  DIM DTA AS STRING * 320
  IF LongFileNames = 0 OR FileName$ = ".." GOTO NameAlreadyShort

  FileSpec$ = FileName$ + CHR$(0)
  Regs.Ax = &H714E'FindFirst
  Regs.Si = 0
  Regs.Flags = 0
  Regs.Es = -1
  Regs.Di = VARPTR(DTA)
  Regs.Cx = 255
  Regs.Ds = -1
  Regs.Dx = SADD(FileSpec$)

  CALL InterruptX(&H21, Regs, Regs)

  IF Regs.Flags AND 1 THEN 'Error
    GetShortFileName$ = ""'Return null string
  ELSE
    CurChar = INSTR(305, DTA, CHR$(0))
    IF CurChar = 305 GOTO NameAlreadyShort
    GetShortFileName = MID$(DTA, 305, CurChar - 305)
  END IF

  Regs.Ax = &H71A1
  Regs.Bx = DirHandle
  CALL InterruptX(&H21, Regs, Regs)
EXIT FUNCTION

NameAlreadyShort:
  GetShortFileName = FileName$

END FUNCTION

