; Simple Bootable Demo
;
; (not finished)
;
; Dependant only on the BIOS, this program contains all the code in it
; necessary to start up and load the rest of itself. Since you can't cram
; very much into a mere 512 bytes, simply loading the remaining code into
; memory is the extent of this microkernel's capabilities.
;
; Warning: Although there is no malevolant code in this demo, a program
; starting up before the operating system has complete control of the
; computer and is able to do anything it wants. Of course, that's little
; different from starting a program under DOS, as it could also do anything
; it wanted ;-)
;
; Files:
;   Myboot.asm      boot sector code and file system information
;   PeekinOs.asm    protected mode demo code
;
; To compile:
;   nasm -f bin myboot.asm -o myboot.bin    (compile to binary image)
;   debug myboot.bin
;       w 100 0 0 1                         (write to floppy boot sector)
;       q
;
; Overall Procedure:
;   Set realmode segments and setup stack
;   Move boot sector code into highest memory and continue executing there
;   Read code on disk from PEEKINOS.SYS into low memory
;   Jump to main program (newly loaded code)
;
; Exit conditions:
;   ss:sp   9000:FE00 purposely set up high in memory
;   cs:ip   0000:0700 purposely set up low in memory
;   ds      0
;   es      0
;
; Limitations:
;   Currently hardcoded to only boot from floppy drives
;   Expects PEEKINIO.SYS to be the first file in the directory
;   File size of PEEKINIO.SYS must be < 64k

SectorSize      equ 512         ;bytes per floppy disk sector
CodeSegment     equ 09000h      ;memory to copy boot sector to
StackSegment    equ 09000h      ;small segment for stack
DiskDataSeg     equ 0           ;memory segment to read in disk sectors
DiskDataOfs     equ 00800h      ;offset within segment
SoftReboot      equ 0           ;no

bits 16
org 0FE00h                      ;set base to upper 512 bytes of 64k page
                                ;so that loading in PEEKINOS.SYS will not
                                ;overwrite any code, no matter how large
DirEntry:
.Filename       equ 0
.FilenameLen    equ 8
;00 = Filename never used
;05 = First character of filename is E5
;E5 = File has been erased
;2E = This is a subdirectory entry
.Extension      equ 8
.ExtensionLen   equ 3
.Attribute      equ 0Bh ;byte
;³7³6³5³4³3³2³1³0³
; ³ ³ ³ ³ ³ ³ ³ ÀÄÄÄ read only
; ³ ³ ³ ³ ³ ³ ÀÄÄÄÄ hidden
; ³ ³ ³ ³ ³ ÀÄÄÄÄÄ system
; ³ ³ ³ ³ ÀÄÄÄÄÄÄ volume label
; ³ ³ ³ ÀÄÄÄÄÄÄÄ subdirectory
; ³ ³ ÀÄÄÄÄÄÄÄÄ archive
; ÀÄÁÄÄÄÄÄÄÄÄÄ unused
.Res1           equ 0Ch ;*10
.Time           equ 16h ;word
;³F³E³D³C³B³A³9³8³7³6³5³4³3³2³1³0³ 17,16
; ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ÀÄÁÄÁÄÁÄÁÄ seconds/2
; ³ ³ ³ ³ ³ ÀÄÁÄÁÄÁÄÁÄÁÄÄÄÄÄÄÄÄÄÄ minutes
; ÀÄÁÄÁÄÁÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ hours
.Date           equ 18h ;word
;³F³E³D³C³B³A³9³8³7³6³5³4³3³2³1³0³ 19,18
; ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ³ ÀÄÁÄÁÄÁÄÁÄ day 1-31
; ³ ³ ³ ³ ³ ³ ³ ÀÄÁÄÁÄÁÄÄÄÄÄÄÄÄÄÄ month 1-12
; ÀÄÁÄÁÄÁÄÁÄÁÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ year + 1980
.Cluster        equ 1Ah ;word
.Size           equ 1Ch ;dword

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BootSector:
    jmp short .AfterInfo         ;3bytes  jump to executable code
    nop
.OemName:       db "PEEKIN00"    ;8bytes  OEM name and version
.SectorBytes:   dw 512           ;word    bytes per sector
.ClusterSectors:db 1             ;byte    sectors per cluster (allocation unit size)
.ReserveSectors:dw 1             ;word    number of reserved sectors (starting at 0)
.NumberFats:    db 2             ;byte    number of FAT's on disk
.RootEntries:   dw 224           ;word    number of root directory entries (directory size)
.TotalSectorsW: dw 2880          ;word    number of total sectors (=0 if partition > 32Mb)
.MediaDescript: db 11111101b     ;byte    media descriptor byte
.FatSectors:    dw 9             ;word    sectors per FAT
.TrackSectors:  dw 18            ;word    sectors per track  (DOS 3.0+)
.Heads:         dw 2             ;word    number of heads  (DOS 3.0+)
.HiddenSectors: dw 0             ;word    number of hidden sectors  (DOS 3.0+)
.TotalSectorsD: dd 2880          ;dword   (DOS 4+) number of sectors if offset 13 was 0
.DriveNumber:   db 0             ;byte    (DOS 4+) physical drive number
                db 0             ;byte    (DOS 4+) reserved
.SignatureByte: db 29h           ;byte    (DOS 4+) signature byte (29h)
.SerialNumber:  dd 12345678h     ;dword   (DOS 4+) volume serial number
.VolumeLabel:   db "PEEKIN'S OS" ;11bytes (DOS 4+) volume label
                dd 0,0           ;8bytes  (DOS 4+) reserved
.AfterInfo:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    cli

    ; create stack and set segment regs
    mov ax,CodeSegment
    mov es,ax
    mov ss,ax
    mov sp,-512                 ;set stack pointer to top

    ; copy boot sector code to uppermost memory
    ; BIOS supposedly loads boot sector into memory at 7C000h,
    ; but I don't whether or not to trust that. So, I just use
    ; a CALL to find out for certain.
    ; (es=upper memory)
    call .GetIp
.GetIp:
    pop si
    sub si,.GetIp-$$            ;get base of boot sector code
    mov cx,SectorSize/2         ;/2 for moving words
    cld
    mov di,sp                   ;set destination to upper memory
    rep cs movsw
    jmp CodeSegment:.UpperMemory
.UpperMemory:
    sti

    ; let user know something is happening (since floppy disks are SLOW)
    mov si,Text.Loading
    call WriteString

    ; Calculate offset to first entry of root directory
    ; This part could be skipped if this program was only to ever be used
    ; on floppy disks, since the sector offsets would be constant. however,
    ; as an example of how you could do it on another drive...
    ;
    ; first fat sector = reserved sectors
    ; root sector = reserved sectors + (fat sectors * number of fats)
    ; base data sector = root sector + (root entries \ 32 * bytes per sector)
    ;
    ; Note these are only valid for FAT12 and FAT16. FAT32 is more
    ; complicated because the values are larger and the root directory is
    ; relocatable.
    push ss
    pop ds
    mov ax,[.ReserveSectors]
    mov bx,[.FatSectors]
    mov dx,[.RootEntries]
    cmp byte [BootSector.NumberFats],2
    jb .SingleFat
    shl bx,1                    ;*2
.SingleFat:
    add ax,bx                   ;get root sector
    bsf cx,[.SectorBytes]
    sub cl,5                    ;*32 bytes per directory entry
    shr dx,cl                   ;/ bytes per sector
    add dx,ax                   ;get first data sector

    ; read root directory entry to get size of system file
    ; (ds=program data)
    xor bx,bx
    ;mov bx,DiskDataSeg
    mov es,bx                   ;zero extra segment
    push bx
    mov cx,32
    push dx                     ;save base data sector
    call ReadDiskSectors

    ; (ds=program data, es=0)
    ;cld
    mov si,Text.OsFilename
    mov di,DiskDataOfs
    mov cx,8/2
    rep cmpsw
    je .FilenameMatch
    mov si,Text.FileErr
    call WriteString
    jmp short Reboot
.FilenameMatch:

    pop ax                      ;retrieve base data sector
    mov cx,[es:DiskDataOfs+DirEntry.Size]
    call ReadDiskSectors
    mov si,Text.Loaded
    call WriteString

    ; (es=0)
    pop ds                      ;zero data segment too
    jmp DiskDataSeg:DiskDataOfs

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (ax=sector, cx=bytes, es=destination segment) (ax=character)
;
ReadDiskSectors:
    mov bx,DiskDataOfs          ;memory destination ptr
.NextSector:
    push cx                     ;save byte count
    push ax                     ;save absolute sector
    push bx                     ;save memory destination ptr

    ; convert absolue sector to convoluted head/track/sector mess
    xor dx,dx
    div word [BootSector.TrackSectors]
    ;Sector = (AbsSector MOD Sectors) + 1
    mov cx,dx
    xor dx,dx
    div word [BootSector.Heads]
    ;Side = (AbsSector / Sectors) MOD Sides
    ;Track = AbsSector / (Sectors * Sides)

    xchg al,ah                  ;stupid BIOS expects tracks flipped!?
    shl al,6                    ;again... what retard thought this up?
    inc ax                      ;sector++ because it is one based
    add cx,ax                   ;merge sector with track

    xchg dl,dh                  ;swap drive with side (drive 0 A:, head 0)
    ;es already set
    mov ax,0201h                ;2 = BIOS function - read disk sectors
                                ;1 = number of sectors to read
    int 13h
    jc .Err                     ;could not read boot sector

    ; show progress
    xor bx,bx                   ;page 0
    mov ax,0E00h|'.'            ;Video BIOS - write character in teletype mode
    int 10h                     ;write character

    pop bx
    pop ax
    pop cx
    add bx,[BootSector.SectorBytes]
    inc ax                      ;sector++
    sub cx,[BootSector.SectorBytes]
    jg .NextSector
    ret

.Err:
    mov si,Text.ReadErr
    call WriteString
    ;jmp short Reboot

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; There a few ways to reboot a computer. Besides the more obvious reset
; button and Ctrl+Alt+Del keypress, you can also execute the bootstrap loader
; or long jump to the BIOS ROM (as if the PC were reset). Depending on the
; method taken (soft/warm/cold), the BIOS will either do a full test or skip
; a few of them. Executing the bootstrap loader is the gentlest of them all,
; as it does not clear memory, retest RAM, blank the screen, or reset
; hardware. Unfortunately, it isn't always dependable.
Reboot:
%if SoftReboot
    xor ax,ax
    int 16h
    mov dl,80h                  ;drive to boot from
    int 19h                     ;execute bootstrap loader
%else
    xor ax,ax
    mov ds,ax                   ;BIOS data segment
    int 16h
    mov word [0472h],1234h      ;indicate to BIOS to do soft reset
    jmp 0FFFFh:0
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (si=string ptr, cx=string length, ss=string segment) (; si)
WriteString:
    push es
    push cs
    pop es

    mov ah,3                    ;Video BIOS Function - get cursor position
    xor bh,bh                   ;page zero
    int 10h
    mov ax,1301h                ;13 = Video BIOS Function - write string
                                ;01 = chars only, move cursor
    mov bx,000Bh                ;page 0, color 11 (turquoise)
    mov cx,[es:si-2]            ;get length of string
    mov bp,si                   ;copy string ptr for BIOS function
    ;(cx=string length)
    ;(es already set)
    ;(dh=row, dl=column)
    int 10h
    pop es
    ret

%if 0
    ; determine string length
    mov ax,1000h                ;set character to search for (null)
    mov cx,ax
    mov di,si
    rep scasb                   ;scan for null in string
    neg cx
    add cx,ax
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
%macro EndString 1
    %1Eos equ $
%endmacro

%macro String 1
  %ifdef StringName
    EndString StringName
  %endif
  %ifidn %1,END
    %define StringName
  %else
    %1 equ $+2
    %define StringName %1
    dw %1Eos - %1
  %endif
%endmacro

Text:
String .Loading
    db "Peekin's simple boot demo 0.0",13,10
    db "Dwayne Robinson 2001-11-27",13,10
    db "Loading."
String .Loaded
    db "Loaded :)",13,10
String .ReadErr
    db "Error reading "
.OsFilename db "PEEKINOS.SYS!"
String .FileErr
    db "First file entry is not PEEKINOS.SYS!"
String END

    ; fill with blank space up to end of sector
    ; to include special signature to tell BIOS this disk is bootable
    times 510-($-$$) db 0
    dw 0AA55h

    ; beginning of second sector
