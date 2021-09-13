DEFINT A-Z
OPTION BASE 0
DECLARE FUNCTION StrRomBank$ (Address&, RomBankMode%)
DECLARE FUNCTION ValRomBank& (Address$, RomBankMode%)
DECLARE FUNCTION ValidKeyPress% (ValidKeys$, Key$)
DECLARE FUNCTION ConfirmCancel% ()
DECLARE SUB WaitForKeypress ()
DECLARE SUB WritePatternToFile (FileHandle%, WriteStart&, WriteBytes&, Pattern$)
DECLARE SUB TransferFile (SourceFileHandle%, DestFileHandle%, WriteBytes&)

CONST GetFilenameOnly = 0, GetFilenameOpen = 1, GetFilenameCheck = 2, FileBufferSize = 4096
CONST MaxListRecords = 150
CONST MaxRecordFields = 6, LastRecordField = MaxRecordFields - 1
CONST RecordListTopRow = 2, RecordListLeftCol = 1, RecordListHeight = 20
CONST RecordFieldOffset = 1, RecordFieldLength = 2, RecordFieldPattern = 4
CONST RecordFieldDescript = 0, RecordFieldBackup = 3, RecordFieldFile = 5
CONST QuestionLine = 23, StatusLine = 24

DIM RecordInfo(MaxListRecords - 1, 2) AS LONG 'locations and lengths
DIM RecordBackups$(MaxListRecords - 1)      'names of the backup files
DIM RecordFilenames$(MaxListRecords - 1)      'names of the work files
DIM RecordDescripts$(MaxListRecords - 1)       'descriptions of locations
DIM RecordDates$(MaxListRecords - 1)          'dates each was backed up
DIM RecordFields$(LastRecordField)
DIM SHARED ErrorHandled

SCREEN 0
Row = CSRLIN: Col = POS(0)
VIEW PRINT 1 TO 25
LOCATE Row, Col, , 13, 14

IF COMMAND$ = "-H" OR COMMAND$ = "/?" THEN
  PRINT "PeekEmu Rom Disector 0.11, Mar 1999"
  PRINT "Written in Qb by FDwR (FDwR@hotmail.com)"
  PRINT
  PRINT "This prog fills a ROM with any desired byte pattern, for the purpose of"
  PRINT "finding out what each part of it is for. For example, if the graphics"
  PRINT "or levels become messed up after changing something around, you then"
  PRINT "have an idea of what was overwritten. So that the ROM can be easily"
  PRINT "restored later to its premessed up state, the portions overwritten are"
  PRINT "backed up and kept track of in a list."
  END
END IF

TotalRecords = 0
RomBankMode = 0         'default is low rom for now
GetNumberMode = 1
FileHeaderSize = 512
File$ = COMMAND$

IF LEN(File$) THEN
  ON ERROR GOTO ErrorHandler: ErrorHandled = 0
  FileHandle = FREEFILE
  OPEN File$ FOR INPUT AS FileHandle: CLOSE FileHandle
  ON ERROR GOTO 0
  IF ErrorHandled THEN
    PRINT "Could not open given file. Err"; ErrorHandled
    PRINT
  ELSE
    GOSUB OpenWorkFileGiven
    GOTO ReadyToGosubMainChoices
  END IF
END IF
GOSUB OpenWorkFile
IF Cancel GOTO ProgEnd
    
ReadyToGosubMainChoices:
COLOR 7, 0: CLS
GOSUB MainChoices

ProgEndAndClearScreen:
COLOR 7, 0: CLS
ProgEnd:
PRINT "See ya..."
END

'do you want to blank out a portion of a file or restore a backed up portion
MainChoices:
  GOSUB PrintRecordListBorder
MainChoicesRedrawList:
  GOSUB PrintAllRecords
MainChoicesReaskQuestion:
  StatusText$ = "(A)dd/Backup/Write  (S)ort  (R)estore  (D)elete  (O)pen  Bank (M)ode  (H)eader"
  GOSUB AskQuestion

  DO
MainChoicesLoopInside:
    DO: Key$ = UCASE$(INKEY$): LOOP UNTIL LEN(Key$)
    WHILE LEN(INKEY$): WEND 'key wasting loop
         
    SELECT CASE Key$
    CASE CHR$(0) + "H": IF CurRecord > 0 THEN NewRecord = CurRecord - 1: GOSUB ChangeCurRecord
    CASE CHR$(0) + "P": IF CurRecord < TotalRecords - 1 THEN NewRecord = CurRecord + 1: GOSUB ChangeCurRecord
    CASE CHR$(0) + "I"
      IF CurRecord > 0 THEN
        NewRecord = CurRecord - RecordListHeight
        IF NewRecord < 0 THEN NewRecord = 0
        GOSUB ChangeCurRecord
      END IF
    CASE CHR$(0) + "Q"
      IF CurRecord < TotalRecords - 1 THEN
        NewRecord = CurRecord + RecordListHeight
        IF NewRecord >= TotalRecords THEN NewRecord = TotalRecords - 1
        GOSUB ChangeCurRecord
      END IF
    CASE "A", "B", "W"
        'if backup file already exists, ask if it should be overwritten
        IF TotalRecords < 1 THEN
          ERASE RecordFields$
          RecordFields$(RecordFieldPattern) = FillPattern$
        ELSEIF TotalRecords < MaxListRecords THEN
          GOSUB GetUserRecordsFromList
        ELSE
          StatusText$ = "List is full, no more can be added"
          GOSUB TellStatus
          GOTO MainChoicesLoopInside
        END IF
        RecordFields$(RecordFieldFile) = WorkFilename$
        GetUserRecordPurpose$ = "Add record/Write/Backup"
MainChoicesGetNewRecord:
        GOSUB GetUserRecordInfo
        DO UNTIL Cancel
          Count = TotalRecords
          GOSUB SetUserRecordsToList
          IF ErrorHandled THEN
            StatusText$ = "Illegal number value"
            GOSUB TellStatus
          ELSE
            'check if backup file already exists
            WriteStart& = RecordInfo(TotalRecords, 0)
            WriteBytes& = RecordInfo(TotalRecords, 1)
            File$ = RecordBackups$(TotalRecords)
            'PRINT File$; WriteStart&; WriteBytes&'debug
            'WaitForKeypress
            IF LEN(FillPattern$) THEN
              GOSUB CheckForRecordOverlap
              IF Found THEN
                NewRecord = Count: GOSUB ChangeCurRecord: GOSUB PrintAllRecords
                StatusText$ = "Another record currently has that portion backed up. Continue anyway? Y/N"
                GOSUB AskQuestion
                Cancel = ConfirmCancel
                IF Cancel = 2 GOTO MainChoicesReaskQuestion
                IF Cancel = 1 GOTO MainChoicesGetNewRecord
              END IF
            END IF
            IF LEN(File$) THEN
              GOSUB CheckForBackupInUse
              IF Found THEN
                NewRecord = Count: GOSUB ChangeCurRecord: GOSUB PrintAllRecords
                StatusText$ = "Another record is already using that backup file. Continue anyway? Y/N"
                GOSUB AskQuestion
                Cancel = ConfirmCancel
                IF Cancel = 2 GOTO MainChoicesReaskQuestion
                IF Cancel = 1 GOTO MainChoicesGetNewRecord
              END IF
            END IF
            GOSUB BackupAndFillRecord
            IF Cancel = 0 THEN
              GOSUB RemoveOldBackupsFromList
              CurRecord = TotalRecords
              TotalRecords = TotalRecords + 1
              'set choice red, meaning it has been overwritten
              IF LEN(File$) AND LEN(FillPattern$) > 0 THEN RecordInfo(CurRecord, 2) = 1 ELSE RecordInfo(CurRecord, 2) = 0
              'set choice date
              RecordDates$(CurRecord) = DATE$
              EXIT DO
            END IF
          END IF
          GOSUB GetUserRecordInfoAgain
        LOOP
        PreBase = RecordListBase
        NewRecord = CurRecord
        GOSUB ChangeCurRecord
        IF PreBase = RecordListBase THEN GOSUB PrintAllRecords
        GOTO MainChoicesReaskQuestion
    CASE "R"
      GOSUB RestoreBackups
      IF Cancel = 0 THEN GOSUB PrintAllRecords
      GOTO MainChoicesReaskQuestion
    CASE "O"
      GOSUB SaveBackupList
      COLOR 7, 0: CLS
      GOSUB OpenWorkFile
      COLOR 7, 0: CLS
      IF Cancel = 0 THEN CurRecord = 0: RecordListBase = 0
      GOTO MainChoices
    CASE "D"
      GOSUB DeleteListRecord
      IF Cancel = 0 THEN GOSUB PrintAllRecords
      GOTO MainChoicesReaskQuestion
    CASE "S"
      IF RecordSortMethod >= 1 THEN RecordSortMethod = 0 ELSE RecordSortMethod = RecordSortMethod + 1
      GOSUB SortRecordList
      GOSUB PrintAllRecords
    CASE "M"
      RomBankMode = RomBankMode + 1
      IF RomBankMode > 2 THEN
        RomBankMode = 0
        StatusText$ = "Using Low ROM banks"
      ELSEIF RomBankMode = 1 THEN
        StatusText$ = "Using High ROM banks"
      ELSE
        StatusText$ = "Using decimal offsets"
      END IF
      GOSUB TellStatus
      GOTO MainChoicesRedrawList
    CASE "H"
      SELECT CASE FileHeaderSize
      CASE IS < 512
        FileHeaderSize = 512
        StatusText$ = "File offsets are relative to smc header (+512)."
      CASE IS < 3091
        FileHeaderSize = 3091
        StatusText$ = "File offsets are relative to zsnes savestate WRAM (+3091)."
      CASE IS >= 3091
        FileHeaderSize = 0
        StatusText$ = "No header, file offsets are absolute."
      END SELECT
      GOSUB TellStatus
      GOTO MainChoicesRedrawList
    CASE CHR$(13)
      IF TotalRecords < 1 GOTO MainChoicesLoopInside
      GetUserRecordPurpose$ = "Edit record"
      GOSUB GetUserRecordsFromList
      GOSUB GetUserRecordInfo
      IF Cancel = 0 THEN
MainLoopRecheckUserRecord:
        Count = CurRecord
        GOSUB SetUserRecordsToList
        IF ErrorHandled THEN
          StatusText$ = "Illegal number value"
          GOSUB TellStatus
          GOSUB GetUserRecordInfoAgain
          IF Cancel = 0 THEN GOTO MainLoopRecheckUserRecord
        END IF
      END IF
      GOTO MainChoices
    CASE ""
      'save backup list if necessary
      GOSUB SaveBackupList
      'check if it saved correctly
      EXIT DO
    END SELECT
  LOOP
RETURN

PrintRecord:
  IF Count < RecordListBase OR Count >= RecordListBase + RecordListHeight THEN RETURN
  IF Count = CurRecord THEN COLOR , 1 ELSE COLOR , 0
  LOCATE Count - RecordListBase + RecordListTopRow, RecordListLeftCol
  IF Count >= TotalRecords THEN
    PRINT SPACE$(80);
  ELSE
    IF RecordInfo(Count, 2) THEN
      IF Count = CurRecord THEN COLOR 13 ELSE COLOR 12
    ELSE
      IF Count = CurRecord THEN COLOR 9 ELSE COLOR 7
    END IF
    Number& = RecordInfo(Count, 0)
    PRINT USING "\                                               \  \      \ ########  \        \"; RecordDescripts$(Count); StrRomBank$(Number& - FileHeaderSize, RomBankMode); RecordInfo(Count, 1); RecordDates$(Count);
  END IF
RETURN

PrintAllRecords:
  FOR Count = RecordListBase TO RecordListBase + RecordListHeight - 1
    GOSUB PrintRecord
  NEXT Count
RETURN

PrintRecordListBorder:
  LOCATE 1, 1: COLOR 9, 0: PRINT "ออออออออออออ Location's description ออออออออออออออ Offset อออ Length อออ Date ออ";
  LOCATE 22, 1: PRINT STRING$(80, 205);
RETURN

ChangeCurRecord:
  IF NewRecord < 0 OR NewRecord >= TotalRecords THEN RETURN
  SWAP CurRecord, NewRecord
  IF CurRecord < RecordListBase THEN
    RecordListBase = CurRecord
    GOSUB PrintAllRecords
  ELSEIF CurRecord >= RecordListBase + RecordListHeight THEN
    RecordListBase = CurRecord - RecordListHeight + 1
    GOSUB PrintAllRecords
  ELSE
    Count = NewRecord: GOSUB PrintRecord
    Count = CurRecord: GOSUB PrintRecord
  END IF
RETURN

OpenWorkFile:
  PRINT "You can use '*' for a list of files in the current directory,"
  PRINT "Or change to a different directory by typing in its name."
  PRINT "Simply press Enter without typing anything to cancel."
  PRINT
 
  GetFilenameMode = GetFilenameOpen
  PromptText$ = "Work file:"
  Cancel = 0
  DO
    GOSUB GetFilename
    IF Cancel OR FileHandle = 0 THEN RETURN

OpenWorkFileGiven:
    ON ERROR GOTO ErrorHandler: ErrorHandled = 0
    OPEN File$ FOR BINARY AS FileHandle
    ON ERROR GOTO 0
    IF ErrorHandled = 0 THEN EXIT DO
    PRINT "Could not open ROM"
  LOOP
  CLOSE WorkFileHandle
  
  WorkFileHandle = FileHandle
  FileLeng& = LOF(WorkFileHandle)

  SubCount = LEN(File$)
  FOR Count = SubCount TO 1 STEP -1
    Char = ASC(MID$(File$, Count, 1))
    IF Char = 47 OR Char = 92 THEN EXIT FOR
  NEXT Count
  Count = Count + 1
  FOR SubCount = Count TO SubCount
    IF ASC(MID$(File$, SubCount, 1)) = 46 THEN EXIT FOR
  NEXT SubCount
  WorkFile$ = LCASE$(File$)
  WorkFilename$ = LCASE$(MID$(WorkFile$, Count))
  WorkBasename$ = LEFT$(WorkFilename$, SubCount - Count)
  WorkPathname$ = LEFT$(WorkFile$, Count - 1)
  'PRINT WorkFilename$, WorkBasename$, WorkPathname$, WorkExtname$'debug

  PRINT
  IF MID$(WorkFile$, SubCount, 3) = ".zs" THEN
    FileHeaderSize = 3091
    PRINT "ZSNES savestate opened."
  ELSE
    FileHeaderSize = FileLeng& AND 512
    PRINT UCASE$(LEFT$(WorkBasename$, 1)); MID$(WorkBasename$, 2); "'s size is"; FileLeng&; "bytes ("; LTRIM$(STR$((FileLeng& - FileHeaderSize) \ 131072)); "mbit, ";
    IF FileHeaderSize THEN PRINT "header present)" ELSE PRINT "no header)"
  END IF

  'print info on backed up parts, number of
  PRINT "Reading list,";
  GOSUB GetBackedUpParts
  IF ErrorHandled THEN PRINT " not created yet";  ELSE PRINT TotalRecords; "records";
  PRINT " ("; RecordListBasename$; ")"
  WaitForKeypress
RETURN

GetUserRecordsFromList:
  RecordFields$(RecordFieldOffset) = StrRomBank$(RecordInfo(CurRecord, 0) - FileHeaderSize, RomBankMode)
  RecordFields$(RecordFieldLength) = StrRomBank$(RecordInfo(CurRecord, 1), RomBankMode)
  RecordFields$(RecordFieldDescript) = RecordDescripts$(CurRecord)
  RecordFields$(RecordFieldBackup) = RecordBackups$(CurRecord)
  RecordFields$(RecordFieldPattern) = FillPattern$
  RecordFields$(RecordFieldFile) = RecordFilenames$(Count)
RETURN

SetUserRecordsToList:
  RecordInfo(Count, 0) = ValRomBank(RecordFields$(RecordFieldOffset), RomBankMode) + FileHeaderSize
  RecordInfo(Count, 1) = ValRomBank(RecordFields$(RecordFieldLength), RomBankMode)
  RecordDescripts$(Count) = RecordFields$(RecordFieldDescript)
  RecordBackups$(Count) = RecordFields$(RecordFieldBackup)
  RecordFilenames$(Count) = RecordFields$(RecordFieldFile)
  FillPattern$ = RecordFields$(RecordFieldPattern)
  RecordListChange = 1
RETURN

'can be used to change existing records, add new ones, or simply get info for
'backing up or writing a portion of the file
GetUserRecordInfo:
  COLOR 9, 0
  LOCATE 9, 1: PRINT "อ"; LEFT$(GetUserRecordPurpose$ + STRING$(79, 205), 79);
  LOCATE 16, 1: PRINT STRING$(80, 205);
GetUserRecordInfoAgain:
  GOSUB GetUserRecordPrintAll
  Count = RecordField
  GOSUB GetUserRecordGetField
  GOSUB GetUserRecordRefreshField

  DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE CHR$(0) + "H": NewRecordField = (RecordField + LastRecordField) MOD MaxRecordFields: GOSUB GetUserRecordChangeField
    CASE CHR$(0) + "P": NewRecordField = (RecordField + 1) MOD MaxRecordFields: GOSUB GetUserRecordChangeField
    CASE CHR$(0) + "K": IF CsrPos > 0 THEN CsrPos = CsrPos - 1: Change = 1
    CASE CHR$(0) + "M": IF CsrPos < LEN(Text$) THEN CsrPos = CsrPos + 1: Change = 1
    CASE CHR$(0) + "G": CsrPos = 0: Change = 1
    CASE CHR$(0) + "O": CsrPos = LEN(Text$): Change = 1
    CASE " " TO "ÿ": IF LEN(Text$) + 1 <= FieldLength THEN Text$ = LEFT$(Text$, CsrPos) + Key$ + MID$(Text$, CsrPos + 1): CsrPos = CsrPos + 1: Change = 1
    CASE CHR$(8): IF LEN(Text$) AND CsrPos > 0 THEN CsrPos = CsrPos - 1: Text$ = LEFT$(Text$, CsrPos) + MID$(Text$, CsrPos + 2): Change = 1
    CASE CHR$(0) + "S": IF LEN(Text$) THEN Text$ = LEFT$(Text$, CsrPos) + MID$(Text$, CsrPos + 2): Change = 1
    CASE CHR$(13)
      RecordFields$(RecordField) = Text$
      Cancel = 0: EXIT DO
    CASE "": Cancel = 1: EXIT DO
    END SELECT

    IF Change = 1 THEN
      COLOR 9, 1: LOCATE RecordField + 10, FieldOffset, 0: PRINT Text$; TAB(80);
      LOCATE , FieldOffset + CsrPos, 1
      Change = 0
    END IF
  LOOP
  LOCATE , , 0
RETURN

GetUserRecordChangeField:
  RecordFields$(RecordField) = Text$
  SWAP RecordField, NewRecordField
  Count = NewRecordField'is actually the old field now
  GOSUB GetUserRecordPrintField
  Count = RecordField
  GOSUB GetUserRecordGetField
  GOSUB GetUserRecordPrintField
GetUserRecordRefreshField:
  GOSUB GetUserRecordPrintHelp
  Text$ = RecordFields$(RecordField)
  CsrPos = LEN(Text$)
  Change = 1
RETURN

GetUserRecordPrintField:
  IF Count >= MaxRecordFields THEN RETURN
  IF Count = RecordField THEN COLOR 9, 1 ELSE COLOR 7, 0
  LOCATE Count + 10, 1, 0: PRINT FieldName$; ": ";
  LOCATE , FieldOffset: PRINT RecordFields$(Count); SPACE$(81 - FieldOffset - LEN(RecordFields$(Count)));
RETURN

GetUserRecordPrintAll:
  FOR Count = 0 TO LastRecordField
    GOSUB GetUserRecordGetField
    GOSUB GetUserRecordPrintField
  NEXT Count
RETURN

GetUserRecordGetField:
  SELECT CASE Count
  CASE RecordFieldOffset: FieldName$ = "Starting offset": FieldLength = 9
  CASE RecordFieldLength: FieldName$ = "Length of data": FieldLength = 9
  CASE RecordFieldPattern: FieldName$ = "Fill pattern": FieldLength = 32
  CASE RecordFieldBackup: FieldName$ = "Backup file": FieldLength = 64
  CASE RecordFieldDescript: FieldName$ = "Description": FieldLength = 64
  CASE RecordFieldFile: FieldName$ = "Filename": FieldLength = 64
  END SELECT
  FieldOffset = LEN(FieldName$) + 3
RETURN

GetUserRecordPrintHelp:
  SELECT CASE Count
  CASE RecordFieldOffset
    Number& = FileLeng& - FileHeaderSize - 1
    StatusText$ = "Offset from 0 to" + STR$(Number&) + " (" + StrRomBank(Number&, RomBankMode) + "), may be in decimal or hex bank (xx:xxxx)."
  CASE RecordFieldLength: StatusText$ = "Number of bytes backed up and filled with pattern."
  CASE RecordFieldPattern: StatusText$ = "Byte value (0-255) or a string pattern if prefixed by equal sign (=ABC)."
  CASE RecordFieldBackup: StatusText$ = "Name of the file this portion of the ROM is backed up to."
  CASE RecordFieldDescript: StatusText$ = "Description of what is contained at this location."
  CASE RecordFieldFile: StatusText$ = "Name of the file this record is for (current file is " + LEFT$(WorkFilename$, 20) + ")"
  END SELECT
  GOSUB AskQuestion
RETURN

BackupAndFillRecord:
  Cancel = 0
  IF LEN(File$) THEN
    StatusText$ = "Backed up"
    IF LEN(FillPattern$) THEN StatusText$ = StatusText$ + " and filled"
  ELSEIF LEN(FillPattern$) THEN
    StatusText$ = "Filled"
  ELSE
    StatusText$ = "Nothing backed up or filled."
    RETURN
  END IF
 
  IF WriteStart& >= FileLeng& THEN
    StatusText$ = "Offset is beyond file length (" + LTRIM$(STR$(WriteStart&)) + " >" + STR$(FileLeng&) + ")"
    GOSUB TellStatus
    Cancel = 1: RETURN
  END IF
 
  IF LEN(File$) = 0 GOTO SkipDataBackup
  FileHandle = FREEFILE
  ON ERROR GOTO ErrorHandler: ErrorHandled = 0
  OPEN File$ FOR OUTPUT AS FileHandle: CLOSE FileHandle
  IF ErrorHandled = 0 THEN OPEN File$ FOR BINARY AS FileHandle
  ON ERROR GOTO 0
  IF ErrorHandled THEN
    StatusText$ = "Could not open that file for output; access was denied. Err:" + STR$(ErrorHandled)
    GOSUB TellStatus
    Cancel = 1: RETURN
  END IF
  SEEK WorkFileHandle, WriteStart& + 1'Qbasic does not use zero-based files
  TransferFile WorkFileHandle, FileHandle, WriteBytes&
  CLOSE FileHandle

SkipDataBackup:
  IF LEN(FillPattern$) = 0 GOTO SkipDataFill
  WritePatternToFile WorkFileHandle, WriteStart&, WriteBytes&, FillPattern$

SkipDataFill:
  StatusText$ = StatusText$ + STR$(WriteBytes&) + " bytes, from" + STR$(WriteStart&) + " to" + STR$(WriteStart& + WriteBytes& - 1)
  GOSUB TellStatus

RETURN

RestoreBackups:
  Cancel = 1
  IF TotalRecords < 1 THEN RETURN
  IF CurRecord >= TotalRecords OR CurRecord < 0 THEN RETURN
  'check that record was actually backed up
  File$ = RecordBackups$(CurRecord)
  IF LEN(File$) = 0 THEN
    StatusText$ = "This record has no backup file."
    GOSUB TellStatus
    RETURN
  END IF
 
  'check if record needs to be restored
  IF RecordInfo(CurRecord, 2) = 0 THEN
    StatusText$ = "This record does not need to be restored. Continue anyway? Y/N"
    GOSUB AskQuestion
    Cancel = ConfirmCancel
    IF Cancel THEN RETURN
  END IF
  StatusText$ = "Restoring this record..."
  GOSUB AskQuestion
 
  'get length of portion
  'could not open backup file?
  'if file error then return
  WriteStart& = RecordInfo(CurRecord, 0)
  WriteBytes& = RecordInfo(CurRecord, 1)
  'PRINT File$; WriteStart&; WriteBytes&'debug
  'WaitForKeypress
  FileHandle = FREEFILE
  ON ERROR GOTO ErrorHandler: ErrorHandled = 0
  OPEN File$ FOR INPUT AS FileHandle: CLOSE FileHandle
  IF ErrorHandled = 0 THEN OPEN File$ FOR BINARY AS FileHandle
  ON ERROR GOTO 0
  IF ErrorHandled THEN
    StatusText$ = "Could not open the backup file. Err:" + STR$(ErrorHandled)
    GOSUB TellStatus
    RETURN
  END IF
  SEEK WorkFileHandle, WriteStart& + 1'Qbasic does not use zero-based files
  TransferFile FileHandle, WorkFileHandle, WriteBytes&
  CLOSE FileHandle

  'turn off red
  RecordInfo(CurRecord, 2) = 0
  RecordListChange = 1
  StatusText$ = "Portion restored from backup," + STR$(WriteBytes&) + " bytes"
  GOSUB TellStatus

  'ask if backup can be deleted now
  'StatusText$ = "Delete its backup file now? Y/N (" + File$ + ")"
  'GOSUB AskQuestion
  'Cancel = ConfirmCancel
  'IF Cancel = 0 THEN
  '  ON ERROR GOTO ErrorHandler: ErrorHandled = 0
  '  KILL File$
  '  ON ERROR GOTO 0
  '  IF ErrorHandled THEN
  '    StatusText$ = "Could not delete "
  '  ELSE
  '    StatusText$ = "Deleted "
  '    RecordBackups$(CurRecord) = ""
  '  END IF
  '  StatusText$ = StatusText$ + File$
  '  GOSUB TellStatus
  'END IF
  Cancel = 0
RETURN

AskQuestion:
  LOCATE QuestionLine, 1
AskQuestionInside:
  COLOR 7, 0
  PRINT LEFT$(StatusText$ + SPACE$(80), 80);
RETURN

TellStatus:
  LOCATE StatusLine, 1
GOTO AskQuestionInside

ClearQuestion:
  COLOR 7, 0
  LOCATE QuestionLine, 1
  PRINT SPACE$(80);
RETURN

DeleteListRecord:
  Cancel = 1
  IF TotalRecords < 1 THEN RETURN
  IF CurRecord >= TotalRecords OR CurRecord < 0 THEN RETURN
  StatusText$ = "Delete this record? Y/N"
  IF RecordInfo(CurRecord, 2) THEN StatusText$ = StatusText$ + " You will not be able to restore it later!"
  GOSUB AskQuestion
  Cancel = ConfirmCancel
  IF Cancel THEN RETURN
  File$ = RecordBackups$(CurRecord)
  IF LEN(File$) THEN
    StatusText$ = "Delete its backup file too? Y/N (" + File$ + ")"
    GOSUB AskQuestion
    Cancel = ConfirmCancel
    IF Cancel = 0 THEN
      ON ERROR GOTO ErrorHandler: ErrorHandled = 0
      KILL File$
      ON ERROR GOTO 0
      IF ErrorHandled THEN
        StatusText$ = "Could not delete "
      ELSE
        StatusText$ = "Deleted "
      END IF
      StatusText$ = StatusText$ + File$
      GOSUB TellStatus
    ELSEIF Cancel = 2 THEN
      RETURN
    END IF
  END IF
  FOR Count = CurRecord TO TotalRecords - 2
    SubCount = Count + 1
    RecordInfo(Count, 0) = RecordInfo(SubCount, 0)
    RecordInfo(Count, 1) = RecordInfo(SubCount, 1)
    RecordInfo(Count, 2) = RecordInfo(SubCount, 2)
    RecordBackups$(Count) = RecordBackups$(SubCount)
    RecordDescripts$(Count) = RecordDescripts$(SubCount)
    RecordDates$(Count) = RecordDates$(SubCount)
  NEXT Count
  TotalRecords = TotalRecords - 1
  RecordListChange = 1
  Cancel = 0
  IF CurRecord >= TotalRecords THEN IF TotalRecords > 0 THEN CurRecord = TotalRecords - 1 ELSE CurRecord = 0
RETURN

SortRecordList:
  BackupListChange = 1
  FOR Count = 0 TO TotalRecords - 2
    LowestRecord = Count
    SELECT CASE RecordSortMethod
    CASE 0
      LowestValue& = RecordInfo(Count, 0)
      'search through for the lowest location record
      FOR SubCount = Count + 1 TO TotalRecords - 1
        IF RecordInfo(SubCount, 0) < LowestValue& THEN LowestRecord = SubCount: LowestValue& = RecordInfo(SubCount, 0)
      NEXT SubCount
    CASE 1
      LowestValue$ = UCASE$(RecordDescripts$(Count))
      'search through for the lowest location record
      FOR SubCount = Count + 1 TO TotalRecords - 1
        IF UCASE$(RecordDescripts$(SubCount)) < LowestValue$ THEN LowestRecord = SubCount: LowestValue$ = UCASE$(RecordDescripts$(SubCount))
      NEXT SubCount
    END SELECT
    IF LowestRecord <> Count THEN
      SWAP RecordInfo(LowestRecord, 0), RecordInfo(Count, 0)
      SWAP RecordInfo(LowestRecord, 1), RecordInfo(Count, 1)
      SWAP RecordInfo(LowestRecord, 2), RecordInfo(Count, 2)
      SWAP RecordBackups$(LowestRecord), RecordBackups$(Count)
      SWAP RecordDescripts$(LowestRecord), RecordDescripts$(Count)
      SWAP RecordDates$(LowestRecord), RecordDates$(Count)
    END IF
    IF INKEY$ = CHR$(27) THEN EXIT FOR
  NEXT Count
  IF RecordSortMethod THEN
    StatusText$ = "Sorted alphabetically."
  ELSE
    StatusText$ = "Sorted by order."
  END IF
  GOSUB TellStatus
RETURN

GetFilename:
  PRINT PromptText$; " ";
  LINE INPUT File$
  IF LEN(File$) = 0 THEN Cancel = 1: RETURN
 
GetFilenameCheck:
  IF INSTR(File$, "*") THEN SHELL "DIR " + File$: GOTO GetFilename
  ON ERROR GOTO ErrorHandler: ErrorHandled = 0
  CHDIR File$
  ON ERROR GOTO 0
  IF ErrorHandled = 0 THEN PRINT "Changed directory.": GOTO GetFilename

  ON ERROR GOTO ErrorHandler: ErrorHandled = 0
  FileHandle = FREEFILE
  OPEN File$ FOR INPUT AS FileHandle: CLOSE FileHandle
  ON ERROR GOTO 0
  IF GetFilenameMode = GetFilenameCheck OR GetFilenameMode = GetFilenameCheckWait THEN
    'check for file's existance before overwriting
    IF ErrorHandled = 0 THEN
      PRINT "That file already exists. ";
      IF GetFilenameMode = GetFilenameCheckWait THEN
        PRINT "Do you want to overwrite it? Y/N";
        Cancel = ConfirmCancel
        PRINT
        IF Cancel GOTO GetFilename
      ELSE
        PRINT "It will be overwritten unless cancelled."
      END IF
    ELSEIF ErrorHandled <> 53 THEN
      PRINT "The specified file could not be opened for some unknown reason. Err:"; ErrorHandled
      GOTO GetFilename
    END IF
  ELSEIF GetFilenameMode = GetFilenameOpen THEN
    IF ErrorHandled = 53 THEN
      PRINT "That file does not exist or could be in some other directory."
      GOTO GetFilename
    ELSEIF ErrorHandled THEN
      PRINT "The specified file could not be opened for some unknown reason. Err:"; ErrorHandled
      GOTO GetFilename
    END IF
  END IF
RETURN

CheckForBackupInUse:
  Found = 0
  FOR Count = 0 TO TotalRecords - 1
    IF RecordInfo(Count, 2) THEN
      IF RecordBackups$(Count) = File$ THEN Found = 1: EXIT FOR
    END IF
  NEXT Count
RETURN

'accepts WriteStart&, WriteBytes&
CheckForRecordOverlap:
  Found = 0
  WriteEnd& = WriteStart& + WriteBytes&
  FOR Count = 0 TO TotalRecords - 1
    IF RecordInfo(Count, 2) THEN
      IF RecordInfo(Count, 0) < WriteEnd& THEN
        a& = RecordInfo(Count, 0) 'don't ask me why the stupid compiler will
        b& = RecordInfo(Count, 1) 'not work without this!?
        IF a& + b& > WriteStart& THEN
          IF RecordFilenames$(Count) = WorkFilename$ THEN Found = 1: EXIT FOR
        END IF
      END IF
    END IF
  NEXT Count
RETURN

RemoveOldBackupsFromList:
  IF LEN(File$) = 0 THEN RETURN
  FOR Count = 0 TO TotalRecords - 1
    IF RecordBackups$(Count) = File$ THEN RecordBackups$(Count) = ""
  NEXT Count
RETURN

GetBackedUpParts:
  'attempts to open the file used along with the work file (*.rml)
  'reads in all the file parts, labels, backup filenames, and positions
  RecordListBasename$ = WorkBasename$ + ".rml"
  RecordListFilename$ = WorkPathname$ + RecordListBasename$
  BackupListChange = 0
  TotalRecords = 0
  FileHandle = FREEFILE
  ON ERROR GOTO ErrorHandler: ErrorHandled = 0
  OPEN RecordListFilename$ FOR INPUT AS FileHandle
  IF ErrorHandled THEN ON ERROR GOTO 0: RETURN
  
  FOR Count = 0 TO MaxListRecords - 1
    IF EOF(FileHandle) OR ErrorHandled THEN EXIT FOR
    INPUT #FileHandle, RecordInfo(Count, 0), RecordInfo(Count, 1), RecordInfo(Count, 2), RecordDates$(Count)
    LINE INPUT #FileHandle, RecordDescripts$(Count)
    LINE INPUT #FileHandle, RecordBackups$(Count)
    LINE INPUT #FileHandle, RecordFilenames$(Count)
    TotalRecords = TotalRecords + 1
  NEXT Count
  ON ERROR GOTO 0
  CLOSE FileHandle

  IF ErrorHandled THEN
    PRINT "An error occured while reading the list; it might not have loaded completely."
    WaitForKeypress
  END IF
RETURN

SaveBackupList:
  IF RecordListChange = 0 THEN RETURN
  FileHandle = FREEFILE
  ON ERROR GOTO ErrorHandler: ErrorHandled = 0
  OPEN RecordListFilename$ FOR OUTPUT AS FileHandle
  IF ErrorHandled THEN
    StatusText$ = "List could not be saved to " + RecordListFilename$ + "!"
    GOSUB TellStatus
    WaitForKeypress
    Cancel = 1: RETURN
  END IF

  FOR Count = 0 TO TotalRecords - 1
    WRITE #FileHandle, RecordInfo(Count, 0), RecordInfo(Count, 1), RecordInfo(Count, 2), RecordDates$(Count)
    PRINT #FileHandle, RecordDescripts$(Count)
    PRINT #FileHandle, RecordBackups$(Count)
    PRINT #FileHandle, RecordFilenames$(Count)
    IF ErrorHandled THEN EXIT FOR
  NEXT Count
  ON ERROR GOTO 0
  CLOSE FileHandle
  RecordListChange = 0

  IF ErrorHandled THEN
    PRINT "An error occured while saving the list; it might not have saved completely."
    WaitForKeypress
  END IF
RETURN

ErrorHandler:
  ErrorHandled = ERR
RESUME NEXT

'TYPE RegType
'Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
'Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Fl AS INTEGER
'Ds AS INTEGER: Es AS INTEGER
'END TYPE
'Code for opening randomly named file
'DummyPath$ = ".\" + CHR$(0) + SPACE$(64)
'Regs.Ax = &H5A00
'Regs.Cx = 0
'Regs.Ds = VARSEG(DummyPath$)
'Regs.Dx = SADD(DummyPath$)
'CALL interruptx(&H21, Regs, Regs)
'Regs.Bx = Regs.Ax
'Regs.Ax = &H3E00
'CALL interruptx(&H21, Regs, Regs)

FUNCTION ConfirmCancel 'true if cancelled, false if Y pressed

DO: Key$ = UCASE$(INKEY$): LOOP UNTIL ValidKeyPress("YN", Key$)
IF Key$ = "N" THEN ConfirmCancel = 1 ELSE IF Key$ = "" THEN ConfirmCancel = 2

END FUNCTION

SUB Prompt (Text$, Key$, CsrRow, CsrCol)

'SELECT CASE Text$
'CASE CHR$(0) + "K"
'CASE CHR$(0) + "M"
'END SELECT

END SUB

FUNCTION StrRomBank$ (Address&, RomBankMode)

IF RomBankMode > 1 THEN
  StrRomBank = LTRIM$(STR$(Address&))
ELSE
  IF RomBankMode THEN
    RomBankSize& = 65536
  ELSE
    RomBankSize& = 32768
  END IF
  StrRomBank = RIGHT$("0" + HEX$(Address& \ RomBankSize&), 2) + ":" + RIGHT$("000" + HEX$(Address& AND RomBankSize& - 1), 4)
END IF

END FUNCTION

SUB TransferFile (SourceFileHandle, DestFileHandle, WriteBytes&)
'this routine assumes the caller has already set the starting file positions
'within both source and destination.
'the caller must have also already opened both files in binary mode.

'DumbCounter& = FileBufferSize
FileBuffer$ = STRING$(FileBufferSize, 0)
FOR Count = 1 TO WriteBytes& \ FileBufferSize
  'PRINT "Transferred"; DumbCounter&; "bytes"'debug
  'DumbCounter& = DumbCounter& + FileBufferSize
  GET SourceFileHandle, , FileBuffer$
  PUT DestFileHandle, , FileBuffer$
NEXT Count
FileBuffer$ = STRING$(WriteBytes& MOD FileBufferSize, 0)
GET SourceFileHandle, , FileBuffer$
PUT DestFileHandle, , FileBuffer$

'PRINT "Transferred"; WriteBytes& MOD FileBufferSize; "last bytes"'debug

END SUB

FUNCTION ValidKeyPress (ValidKeys$, Key$)

IF LEN(Key$) <> 1 THEN EXIT FUNCTION
IF INSTR(ValidKeys$, Key$) THEN ValidKeyPress = 1

END FUNCTION

FUNCTION ValRomBank& (Address$, RomBankMode)

IF RomBankMode THEN RomBankSize& = 65536 ELSE RomBankSize& = 32768

ON ERROR GOTO ErrorHandler: ErrorHandled = 0
IF INSTR(Address$, ":") THEN
  Number& = VAL("&h0" + MID$(Address$, INSTR(Address$, ":") + 1))
  IF Number& < 0 THEN Number& = Number& AND 65535 '<--stupid val!
  ValRomBank = Number& + VAL("&h0" + Address$) * RomBankSize&
ELSE
  ValRomBank = VAL(Address$)
END IF
ON ERROR GOTO 0

END FUNCTION

SUB WaitForKeypress

DO: LOOP UNTIL LEN(INKEY$)

END SUB

SUB WritePatternToFile (FileHandle, WriteStart&, WriteBytes&, FillPattern$)

'assume pattern size is not larger than filebuffersize

IF LEFT$(FillPattern$, 1) = "=" THEN
  Pattern$ = MID$(FillPattern$, 2)
  PatternSize = LEN(Pattern$)
  PatternBufferSize = FileBufferSize - (FileBufferSize MOD PatternSize)
  FileBuffer$ = STRING$(PatternBufferSize, 0)
  FOR Count = 1 TO PatternBufferSize STEP PatternSize
    MID$(FileBuffer$, Count) = Pattern$
  NEXT Count
ELSE
  IF LEN(FillPattern$) <= 0 THEN EXIT SUB'error
  FileBuffer$ = STRING$(FileBufferSize, VAL(LEFT$(FillPattern$, 3)) AND 255)
  PatternBufferSize = FileBufferSize
END IF
'assume PatternBufferSize > 0

'if x > lof then exit or x = ...
'WriteEnd& = WriteStart& + WriteBytes& - FileBufferSize

'assume count will not overflow
Count = WriteBytes& \ PatternBufferSize

'PRINT "start at"; WriteStart&; "write bytes"; WriteBytes&; "end at"; WriteStart& + WriteBytes& - 1
'PRINT Count; "*"; PatternBufferSize; "="; CLNG(Count) * PatternBufferSize; "bytes output in first loop"

SEEK FileHandle, WriteStart& + 1'Qbasic uses 1-based files
'DumbCounter& = PatternBufferSize
FOR Count = 1 TO WriteBytes& \ PatternBufferSize
  'PRINT "Output"; DumbCounter&; "bytes"'debug
  'DumbCounter& = DumbCounter& + PatternBufferSize
  PUT FileHandle, , FileBuffer$
NEXT Count

'output remaining pattern
Count = WriteBytes& MOD PatternBufferSize
'PRINT "Output"; Count; "last bytes"'debug
FileBuffer$ = MID$(FileBuffer$, 1, WriteBytes& MOD PatternBufferSize)
PUT FileHandle, , FileBuffer$

END SUB

