DEFINT A-Z
'drive, starting sector, number of sectors, destination

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Fl AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE
DIM SHARED Regs AS RegType
DIM PrintableCharTable(255)

CONST DiskBufferSize = 512
CONST DiskDrive = &H80
CONST SectorSaveFile$ = "\bootsect.dat"
CONST SectorsToSave = 126

DIM DiskBuffer AS STRING * DiskBufferSize

'--------------------

FOR Count = 0 TO 255
    PrintableCharTable(Count) = Count
NEXT
READ Value
DO
    PrintableCharTable(Value) = 250
    READ Value
LOOP WHILE Value

'--------------------
  
GOSUB GetDiskInfo

SelectChoice:
DO
    CLS
    PRINT "(D)isplay first sector"
    PRINT "(S)ave sectors to file"
    PRINT "(R)estore sectors from file"
    PRINT "(Q)uit"
    PRINT
    PRINT "Drive type: ";
    SELECT CASE DiskType
    CASE 1: PRINT "5¬ 360Kb"
    CASE 2: PRINT "5¬ 1.2Mb"
    CASE 3: PRINT "3« 720Kb"
    CASE 4: PRINT "3« 1.44Mb"
    CASE ELSE: PRINT "Hard drive"
    END SELECT
    PRINT "Sides:"; DiskSides
    PRINT "Sectors per track:"; DiskSectors
    PRINT "Tracks:"; DiskTracks
SelectChoiceGetKey:
    Key$ = UCASE$(INKEY$)
    SELECT CASE Key$
    CASE "D"
        CLS
        GOSUB DisplaySector
        GOSUB PressKeyWait
    CASE "S"
        CLS
        PRINT "Saving"; SectorsToSave; "sectors to "; SectorSaveFile$
        GOSUB SaveSectors
        PRINT "Saved sectors ("; SectorsToSave * 512&; "bytes )"
        GOSUB PressKeyWait
    CASE "R"
        PRINT
        PRINT "Are you sure? This will overwrite the master boot record! (Y/N)"
        GOSUB KeyWait
        IF UCASE$(Key$) = "Y" THEN
            CLS
            PRINT "Restoring sectors from "; SectorSaveFile$
            GOSUB RestoreSectors
            PRINT "Restored"; SectorsRestored; "sectors ("; SectorsRestored * 512&; "bytes )"
            GOSUB PressKeyWait
        END IF
    CASE CHR$(27), "Q": EXIT DO
    CASE ELSE: GOTO SelectChoiceGetKey
    END SELECT
LOOP
END


GetDiskInfo:
    'Get drive parameters
    Regs.Ax = &H800
    Regs.Dx = DiskDrive
    CALL InterruptX(&H13, Regs, Regs)
    DiskSectors = Regs.Cx AND 63
    IF (Regs.Fl AND 1) OR DiskSectors = 0 THEN RETURN'Error getting drive information!
    DiskSides = Regs.Dx \ 256 + 1
    DiskTracks = ((Regs.Cx \ 256) OR ((Regs.Cx AND 192) * 4)) + 1
    DiskType = Regs.Bx AND 255
RETURN


DisplaySector:
    PRINT "Reading disk..."; " d"; LTRIM$(STR$(DiskDrive)); " h"; LTRIM$(STR$(DiskSide)); " t"; LTRIM$(STR$(DiskTrack)); " s"; LTRIM$(STR$(DiskSector))
    DiskSide = 0
    DiskTrack = 0
    DiskSector = 1
    GOSUB ReadSector
    PRINT "Return code:"; DiskStatus
    SELECT CASE Regs.Ax \ 256
    CASE 0: PRINT "Data:"
            FOR Count = 1 TO DiskBufferSize
                Value = ASC(MID$(DiskBuffer, Count, 1))
                PRINT CHR$(PrintableCharTable(Value));
            NEXT
    CASE 1: PRINT "Bad command passed to driver"
    CASE 4: PRINT "Sector not found"
    CASE 6: PRINT "Diskette changed or removed"
    END SELECT
RETURN

WriteSector:
    Regs.Ax = &H301 'function 3, 1 sector to write
    GOTO ReadWriteSector
ReadSector:
    Regs.Ax = &H201 'function 2, 1 sector to read
ReadWriteSector:
    Regs.Dx = DiskDrive OR (DiskSide * 256&)
    DEF SEG = VARSEG(Regs.Cx)
    Adr = VARPTR(Regs.Cx)
    POKE Adr, DiskSector OR ((DiskTrack \ 4) AND 192)
    POKE Adr + 1, DiskTrack
    Regs.Es = VARSEG(DiskBuffer)
    Regs.Bx = VARPTR(DiskBuffer)
    CALL InterruptX(&H13, Regs, Regs)
    DiskStatus = Regs.Ax \ 256
RETURN


SaveSectors:
    OPEN SectorSaveFile$ FOR BINARY AS 1
    DiskSide = 0
    DiskTrack = 0
    DiskSector = 1
    FOR Count = 1 TO SectorsToSave
        GOSUB ReadSector
        PUT #1, , DiskBuffer
        DiskSector = DiskSector + 1
        IF DiskSector > DiskSectors THEN
            DiskSector = 1
            DiskSide = DiskSide + 1
            IF DiskSide >= DiskSides THEN
                DiskTrack = DiskTrack + 1
            END IF
        END IF
    NEXT
    CLOSE 1
RETURN


RestoreSectors:
    OPEN SectorSaveFile$ FOR BINARY AS 1
    DiskSide = 0
    DiskTrack = 0
    DiskSector = 1
    FOR Count = 1 TO SectorsToSave
        GOSUB WriteSector
        GET #1, , DiskBuffer
        IF EOF(1) THEN EXIT FOR
        DiskSector = DiskSector + 1
        IF DiskSector > DiskSectors THEN
            DiskSector = 1
            DiskSide = DiskSide + 1
            IF DiskSide >= DiskSides THEN
                DiskTrack = DiskTrack + 1
            END IF
        END IF
        SectorsRestored = SectorsRestored + 1
    NEXT
    CLOSE 1
RETURN


PressKeyWait:
    PRINT "Press a key to continue..."
KeyWait:
    DO: LOOP WHILE LEN(INKEY$) 'clear any waiting keys
    DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)'wait until keypress
RETURN


UnprintableCharData:
DATA 7,9,10,11,12,13,28,29,30,31,0

