; View Fat - emergency recovery
; Dwayne Robinson
; 2001-09-08
; 2001-12-13
;
; Displays the FAT system of a drive when the operating system won't!,
; either because critical areas are too badly damaged or because it uses a
; drive overlay that the BIOS translation is incompatible with. Written
; because moving my old hard drive into my new computer required reformatting
; it (incompatible BIOS translation), but I wasn't about to lose everything
; I had accumulated onto it the past four+ years. Add to that the fact that I
; moved the computer while it was still on, and the poor hard drive had a nice
; FAT corrupting jar. Nice thing about this program is that it ignores disk
; errors, so a bad disk is no problem. Keep in mind though that since ViewFat
; will show you everything - including the corrupted data, files, folders -
; that is exactly what you might see, corrupted data.
;
; !Although this program does check for certain sanity errors, there are many
; it intentionally does not check, allowing you the maximum flexibility when
; reading from a drive that may be damaged. However, this assumes you know
; what you are doing. If you, for example, select the wrong operating system
; base sector (usually located at 0:0:1 or 0:1:1), it may display random
; characters, act strangely, or crash. Although I have not yet personally
; encountered it crashing from this, I'm just warning you that it MAY.
;
; To salvage data, you can navigate the file system like most other file
; managers, using the right arrow key to go deeper, left to retreat up.
; To export a file or create a folder, press Enter on the selected file. It
; will even show you deleted files; so, you may find wonderful lost treasures
; or you may find garbage.
;
; For floppy disks: If the boot sector is damaged, the operating system won't
; be able to read the files on it. It has no concern whether the files on it
; are unimportant or very important (your term final project). I've had a
; few floppys with unreadable boot sectors, so I included the option to
; assume the standard 1.44MB boot sector. Unfortunately, such a thing can't
; be done with hard disks because their is no 'standard'.
;
;
; FAT - File Allocation Table
;
; -Linked List-
; This table keeps track of file parts using a linked list array. The
; directory entry for the file or folder has the pointer to the first piece,
; (cluster or allocation unit) and the FAT holds the chained pointers to each
; next cluster, until reaching an entry with all ones (FFFFh).
;
; -Entry Size-
; The number of clusters on a drive is the number of FAT entries. Old hard
; drives with a lower number of clusters (<=65520) used used 16bit entries.
; Smaller drives like floppy diskettes used 12bit (clusters <= 4080). Huge
; ones like today's gigabyte drives use 32bit. This program supports the
; 12/16 bit entries of older drives, since the whole reason this program
; was even written was to salvage precious information off an old drive.
;
; -Special Entry Values-
; Normally each entry points to the next piece of a file. The following have
; special meaning:
;   0000      = free space
;   FFF1-FFF7 = bad sector (don't know why they waste so many values)
;   FFF8-FFFE = possible end of chain (redundant values again)
;   FFFF      = standard end of file
;
; -Address Conversion-
; Cluster -> DOS logical sector
;   DosSector = ((Cluster - 2) * SectorsPerCluster)
;             + BaseLogicalSector
; Track/Head/Sector -> DOS logical sector
;   DosSector = (Sector - 1) + (Head * Sectors)
;             + (Track * Sectors * Heads)
; DOS logical sector -> Track/Head/Sector
;   Sector = (DosSector mod Sectors) + 1
;   Head = (DosSector / Sectors) mod Heads
;   Track = DosSector / (Sectors * Heads)
;
; -Observations-
; For hard disks, the operating system code usually starts at head 1,
; track 0, sector 1.
;
; -Reading a sector-
; AH = 2
; AL = number of sectors to read  (1-128 dec.)
; CH = track/cylinder number  (0-1023 dec., see below)
; CL = sector number  (1-17 dec.)
; DH = head number  (0-15 dec.)
; DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
; ES:BX = pointer to buffer
;
; ³F³E³D³C³B³A³9³8³7³6³5-0³  CX
;  ³ ³ ³ ³ ³ ³ ³ ³ ³ ³  ÀÄÄÄÄÄ  sector number
;  ³ ³ ³ ³ ³ ³ ³ ³ ÀÄÁÄÄÄÄÄÄÄ  high order 2 bits of track/cylinder
;  ÀÄÁÄÁÄÁÄÁÄÁÄÁÄÁÄÄÄÄÄÄÄÄÄÄ  low order 8 bits of track/cyl number
;
; -Menu Options-
; select drive
; view drive info
; view sectors
; select os base
; assume floppy FAT
; view file system info
; view fat
; view file system
; choose export drive
; export all fat pieces
; export all files
; export entire media
; quit


BITS 32
GLOBAL _WdosxStart

NumStringMaxLen equ 10

Screen:
.Adr            equ 0B8000h
.Height         equ 50
.Width          equ 80

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section .bss
Regs:
.Edi            equ $+00h
.Esi            equ $+04h
.Ebp            equ $+08h
.Res            equ $+0Ch       ;Reserved by system
.Ebx            equ $+10h
.Edx            equ $+14h
.Ecx            equ $+18h
.Eax            equ $+1Ch
.Flags          equ $+20h
.Es             equ $+22h
.Ds             equ $+24h
.Fs             equ $+26h
.Gs             equ $+28h
.Ip             equ $+2Ah
.Cs             equ $+2Ch
.Sp             equ $+2Eh
.Ss             equ $+30h
                resb 32h        ;real mode register structure

Disk:
.MaxSectorSize  equ 1024
.BufferSel:     resd 1          ;DPMI selector
.BufferPtr:     resd 1          ;32bit absolute pointer
section .data
align 4
.Tracks:        dd 1            ;tracks/cylinders per size
.Sides:         dd 1            ;number of heads/sides in drive
.Sectors:       dd 1            ;sectors per track
.SectorBytes:   dd 512
.TotalSectors:  dd 0            ;total sectors in drive
.OsSectors:     dd 0            ;total sectors in OS partition
.OsSector:      dd 0            ;base boot sector of operating system
.FatSector:     dd 0            ;starting sector of file allocation table
.FatSectors:    dd 0            ;sectors used per FAT
.RootSector:    dd 0            ;starting sector of root directory
.RootEntries:   dd 512          ;entries in root directory
.DataSector:    dd 0            ;starting sector of file/folder pieces
.DataSectors:   dd 0            ;sectors used for data
.ClusterSectors:dd 0            ;sectors per cluster
.Clusters:      dd 0            ;total clusters
.CurSector:     dd 0
.PreSector:     dd 0            ;previous current sector
.Track:         dd 0            ;current track
.Side:          dd 0
.Sector:        dd 1
.Drive:         db 0;80h        ;current drive (0=floppy, 1=2nd floppy, 80h=first IDE drive, 81h=2nd drive...)
.SectorBytesShl:db 9            ;left shift for sector bytes
.ReadFlags:     db 0            ;which attributes of the disk have been read
.ReadDriveInfo  equ 1
.ReadSector     equ 2
.ReadBootSector equ 4
.ReadFat        equ 8
.ReadFolder     equ 16
.ReadSecondFat  equ 32

section .bss
BootSector:
               ;equ $+00h       ;3bytes  jump to executable code
.OemName        equ $+03h       ;8bytes  OEM name and version
.SectorBytes    equ $+0Bh       ;word    bytes per sector
.ClusterSectors equ $+0Dh       ;byte    sectors per cluster (allocation unit size)
.ReserveSectors equ $+0Eh       ;word    number of reserved sectors (starting at 0)
.NumberFats     equ $+10h       ;byte    number of FAT's on disk
.RootEntries    equ $+11h       ;word    number of root directory entries (directory size)
.TotalSectorsW  equ $+13h       ;word    number of total sectors (0 if partition > 32Mb)
.MediaDescript  equ $+15h       ;byte    media descriptor byte  (see MEDIA DESCRIPTOR)
.FatSectors     equ $+16h       ;word    sectors per FAT
.TrackSectors   equ $+18h       ;word    sectors per track  (DOS 3.0+)
.Heads          equ $+1Ah       ;word    number of heads  (DOS 3.0+)
.HiddenSectors  equ $+1Ch       ;word    number of hidden sectors  (DOS 3.0+)
.TotalSectorsD  equ $+20h       ;dword   (DOS 4+) number of sectors if offset 13 was 0
.DriveNumber    equ $+24h       ;byte    (DOS 4+) physical drive number
               ;equ $+25h       ;byte    (DOS 4+) reserved
.SignatureByte  equ $+26h       ;byte    (DOS 4+) signature byte (29h)
.SerialNumber   equ $+27h       ;dword   (DOS 4+) volume serial number
;.VolumeLabel   equ $+2Bh       ;11bytes (DOS 4+) volume label (stupid label seems to be at different offsets on different drives so forget it!)
;.VolumeLabel   equ $+47h       ;11bytes (DOS 4+) volume label
               ;equ $+36h       ;8bytes  (DOS 4+) reserved
                resb Disk.MaxSectorSize ;512 ;boot sector of operating system

Fat.Limit       equ 65521
Fat.Ptrs:       resb 65536*2    ;linked list of file pieces
Fat.Idxs:       resb 65536*2    ;indexes pointing back to starting cluster

section .data
align 4
StandardFloppyBootSector:
db 0EBh,03Ch,090h,04Dh, 053h,044h,04Fh,053h, 035h,02Eh,030h,000h, 002h,001h,001h,000h
db 002h,0E0h,000h,040h, 00Bh,0F0h,009h,000h, 012h,000h,002h,000h, 000h,000h,000h,000h
db 000h,000h,000h,000h, 000h,000h,029h,078h, 02Bh,001h,01Dh,048h, 041h,052h,044h,05Fh
db 044h,049h,053h,04Bh, 020h,020h,046h,041h, 054h,031h,036h,020h, 020h,020h,0FAh,033h
db 0C0h,08Eh,0D0h,0BCh, 000h,07Ch,016h,007h, 0BBh,078h,000h,036h, 0C5h,037h,01Eh,056h
db 016h,053h,0BFh,03Eh, 07Ch,0B9h,00Bh,000h, 0FCh,0F3h,0A4h,006h, 01Fh,0C6h,045h,0FEh
db 00Fh,08Bh,00Eh,018h, 07Ch,088h,04Dh,0F9h, 089h,047h,002h,0C7h, 007h,03Eh,07Ch,0FBh
db 0CDh,013h,072h,079h, 033h,0C0h,039h,006h, 013h,07Ch,074h,008h, 08Bh,00Eh,013h,07Ch
db 089h,00Eh,020h,07Ch, 0A0h,010h,07Ch,0F7h, 026h,016h,07Ch,003h, 006h,01Ch,07Ch,013h
db 016h,01Eh,07Ch,003h, 006h,00Eh,07Ch,083h, 0D2h,000h,0A3h,050h, 07Ch,089h,016h,052h
db 07Ch,0A3h,049h,07Ch, 089h,016h,04Bh,07Ch, 0B8h,020h,000h,0F7h, 026h,011h,07Ch,08Bh
db 01Eh,00Bh,07Ch,003h, 0C3h,048h,0F7h,0F3h, 001h,006h,049h,07Ch, 083h,016h,04Bh,07Ch
db 000h,0BBh,000h,005h, 08Bh,016h,052h,07Ch, 0A1h,050h,07Ch,0E8h, 092h,000h,072h,01Dh
db 0B0h,001h,0E8h,0ACh, 000h,072h,016h,08Bh, 0FBh,0B9h,00Bh,000h, 0BEh,0E6h,07Dh,0F3h
db 0A6h,075h,00Ah,08Dh, 07Fh,020h,0B9h,00Bh, 000h,0F3h,0A6h,074h, 018h,0BEh,09Eh,07Dh
db 0E8h,05Fh,000h,033h, 0C0h,0CDh,016h,05Eh, 01Fh,08Fh,004h,08Fh, 044h,002h,0CDh,019h
db 058h,058h,058h,0EBh, 0E8h,08Bh,047h,01Ah, 048h,048h,08Ah,01Eh, 00Dh,07Ch,032h,0FFh
db 0F7h,0E3h,003h,006h, 049h,07Ch,013h,016h, 04Bh,07Ch,0BBh,000h, 007h,0B9h,003h,000h
db 050h,052h,051h,0E8h, 03Ah,000h,072h,0D8h, 0B0h,001h,0E8h,054h, 000h,059h,05Ah,058h
db 072h,0BBh,005h,001h, 000h,083h,0D2h,000h, 003h,01Eh,00Bh,07Ch, 0E2h,0E2h,08Ah,02Eh
db 015h,07Ch,08Ah,016h, 024h,07Ch,08Bh,01Eh, 049h,07Ch,0A1h,04Bh, 07Ch,0EAh,000h,000h
db 070h,000h,0ACh,00Ah, 0C0h,074h,029h,0B4h, 00Eh,0BBh,007h,000h, 0CDh,010h,0EBh,0F2h
db 03Bh,016h,018h,07Ch, 073h,019h,0F7h,036h, 018h,07Ch,0FEh,0C2h, 088h,016h,04Fh,07Ch
db 033h,0D2h,0F7h,036h, 01Ah,07Ch,088h,016h, 025h,07Ch,0A3h,04Dh, 07Ch,0F8h,0C3h,0F9h
db 0C3h,0B4h,002h,08Bh, 016h,04Dh,07Ch,0B1h, 006h,0D2h,0E6h,00Ah, 036h,04Fh,07Ch,08Bh
db 0CAh,086h,0E9h,08Ah, 016h,024h,07Ch,08Ah, 036h,025h,07Ch,0CDh, 013h,0C3h,00Dh,00Ah
db 04Eh,06Fh,06Eh,02Dh, 053h,079h,073h,074h, 065h,06Dh,020h,064h, 069h,073h,06Bh,020h
db 06Fh,072h,020h,064h, 069h,073h,06Bh,020h, 065h,072h,072h,06Fh, 072h,00Dh,00Ah,052h
db 065h,070h,06Ch,061h, 063h,065h,020h,061h, 06Eh,064h,020h,070h, 072h,065h,073h,073h
db 020h,061h,06Eh,079h, 020h,06Bh,065h,079h, 020h,077h,068h,065h, 06Eh,020h,072h,065h
db 061h,064h,079h,00Dh, 00Ah,000h,049h,04Fh, 020h,020h,020h,020h, 020h,020h,053h,059h
db 053h,04Dh,053h,044h, 04Fh,053h,020h,020h, 020h,053h,059h,053h, 000h,000h,055h,0AAh

section .bss
Drives:
.List:          resb 26
section .data
.BiosString:    db "# ............ (00)"
.BiosStringLen  equ $-.BiosString
.FdString:      db "Floppy Drive"
.TypeStringLen  equ $-.FdString
.HdString:      db "Hard Drive  "
.DosString:     db "C:"

Folder:
.MaxFiles       equ 2048
.MaxDepth       equ 32
.Entries:       dd 0
.SelectedFile:  dd 0
.Depth:         dd 0
.PathLen:       dd 0
.Cluster:       dd 0            ;starting cluster of folder
.Sector:        dd 0            ;starting folder sector
section .bss
alignb 4
.List:          resb .MaxFiles*32   ;32 bytes per directory entry
.PathSize       equ 256
.Path:          resb .PathSize
.ParentSectors  resd .MaxDepth*4
.ParentClusters resd .MaxDepth*4
.ParentPathLens resd .MaxDepth*4
.ParentIdxs     resd .MaxDepth*4

section .data
File:
.Cluster:       dd 0
.Size:          dd 0
.Date:          dd 0
.Time:          dd 0
.Attribute:     dd 0
.AtrReadOnly    equ 1
.AtrHidden      equ 2
.AtrSystem      equ 4
.AtrLabel       equ 8
.AtrFolder      equ 16
.AtrArchive     equ 32

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

Modes:
.MainMenu           equ 0
.SelectBiosDrive    equ 1
.ViewSectors        equ 3
.SelectOsBase       equ 4
.ViewFat            equ 6
.ViewFolder         equ 7
.SelectExportDrive  equ 8
.ViewFileSector     equ 9

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section .text
global Main
_WdosxStart:
Main:
    push ds
    pop es

    ; allocate low memory area for disk data transfer
    mov eax,0100h               ;allocate low memory
    ; Physical memory reserved for it is actually twice as large as the buffer
    ; alone, just in case part of the allocated block crosses a 64k page.
    mov ebx,Disk.MaxSectorSize*2/16;paragraphs to grab
    int 31h
    jnc .BufferOk
    push dword .EndNow
    mov edx,Text.NoBuffer
    jmp WriteString.WithEol
.BufferOk:
    shl eax,4
    mov [Disk.BufferSel],dx
    mov [Disk.BufferPtr],eax
    or eax,0FFFF0000h           ;set all bits above 64k (DMA page)
    add eax,Disk.MaxSectorSize-1 ;ensure buffer doesn't cross 64k boundary
    jnc .NoWrap
    add word [Disk.BufferPtr],Disk.MaxSectorSize
.NoWrap:

    ; tell DPMI host to provide stack
    mov [Regs.Sp],dword 0
    ;mov [Regs.Ss],word 0

    ; set screen size to 80x50
    mov ax,1112h                ;ah=set character font, al=8x8
    xor bx,bx                   ;table 0
    int 10h                     ;Video BIOS

    ;-> debug hack starts here
%if 0
    jmp .End
    ;call SelectExportDrive
    call GetDriveInfo
    call ShowDriveInfo
    call LoadBootSector
    call ShowBootSectorInfo
    call LoadFat

    jmp .End
%endif
    ;<- debug hack ends

    call SelectBiosDrive

.NoKey:
    ;update timer in status bar
    call dword [.RedrawCode]
    mov dword [.RedrawCode],.DoNothing
.CheckKey:
    mov ah,1                    ;Keyboard BIOS: check for any keys pressed
    int 16h
    jz .NoKey
    xor eax,eax                 ;Keyboard BIOS: grab keypress
    int 16h
    mov esi,[.KeyListPtr]
    call ScanForKey
    jc .InvalidKey
    mov esi,[.KeyJtblPtr]
    call dword [esi+ecx*4]
    jmp short .CheckKey
.InvalidKey:
    cmp al,27
    jne .CheckKey
.EscapePressed:
    cmp byte [.Mode],Modes.MainMenu
    je .End
    call MainMenu
    jmp short .CheckKey
.End:
    ; free buffer
    mov ax,0101h                ;deallocate low memory
    mov dx,[Disk.BufferSel]
    int 31h
.EndNow:
    mov ax,4C00h
    int 21h
.DoNothing:
    ret


section .data
align 4
.RedrawCode:    dd .DoNothing
.KeyListPtr:    dd SelectBiosDrive.KeyList
.KeyJtblPtr:    dd SelectBiosDrive.KeyJtbl
.Mode:          db Modes.MainMenu
section .text


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MainMenu:
    mov byte [Main.Mode],Modes.MainMenu
    mov dword [Main.KeyListPtr],.KeyList
    mov dword [Main.KeyJtblPtr],.KeyJtbl

    ; display menu
    mov eax,[.Selected]
    mov dword [Menu.Total],.NumChoices
    mov [Menu.Selected],eax
    call DisplayClear
    mov edx,Text.MainMenu
    call WriteString
    call ShowDriveInfo
    call ShowBootSectorInfo
    jmp Menu.HighlightChoice

.EnterKey:
    mov ecx,[Menu.Selected]
    mov [.Selected],ecx
    jmp dword [.ChoiceJtbl+ecx*4]

.ExportAllFatPieces:
.Ignore:
    ret

.LeftKey:
    dec dword [File.Cluster]
    jmp short .ShowCluster
.RightKey:
    inc dword [File.Cluster]
.ShowCluster:
    mov eax,[File.Cluster]
    and eax,65535
    push dword [Fat.Idxs+eax*2]
    push dword [Fat.Ptrs+eax*2]
    mov edi,.ClusterString
    call NumToString.ToDest
    pop eax
    mov edi,.ClusterString+12
    and eax,65535
    call NumToString.ToDest
    pop eax
    mov edi,.ClusterString+24
    and eax,65535
    call NumToString.ToDest
    mov esi,.ClusterString
    mov eax,35
    mov edx,12                  ;row
    xor ecx,ecx                 ;column
    jmp DisplayText


section .data
.ClusterString: db "1234567890c 1234567890n 1234567890s"
.Selected:      dd 0
.KeyList:       db 1,4
                db 13,"HPKM"
align 4
.KeyJtbl:       dd .EnterKey,Menu.UpKey,Menu.DownKey,.LeftKey,.RightKey
.NumChoices     equ 11
.ChoiceJtbl:    dd SelectBiosDrive
                dd ViewSectors
                dd SelectOsBase
                dd AssumeFloppyFat
                dd ViewFat
                dd ViewFolder
                dd SelectExportDrive
                dd .ExportAllFatPieces
                dd ExportAllFiles
                dd ExportEntireMedia
                dd Main.End
section .text


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Menu:
.HighlightChoice:
    mov eax,[Menu.Selected]
    mov ebx,dword 1BFFh         ;CharColor
;(ax=row & col, bx=charcolor)
.DrawHighlight:
    or eax,(1<<16)|(22<<24)     ;height & width
    push ebx                    ;CharColor
    push eax
    call DisplayFill
    add esp,byte 8
    ret

.UpKey:
    mov ecx,-1
    jmp short .ChangeChoice
.DownKey:
    mov ecx,1
.ChangeChoice:
    mov eax,[Menu.Selected]
    mov ebx,dword 7FFh          ;CharColor gray
    add ecx,eax
    js .IgnoreChange
    cmp [Menu.Total],ecx
    jbe .IgnoreChange
    mov [Menu.Selected],ecx
    push dword .HighlightChoice
    jmp .DrawHighlight
    ;ret
.IgnoreChange:
    ret


section .bss
.Total:         resd 1
.Selected:      resd 1
section .text


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetDriveInfo:
    mov dl,[Disk.Drive]
    ;xor dl,dl                   ;safety hack for now, read floppy drive
; (dl=desired drive)
.Using:
    ; get disk information from BIOS
    mov byte [Regs.Eax+1],08h   ;get current drive parameters
    mov word [Regs.Es],-1       ;set sentinel value to check later
    mov [Regs.Edx],dl
    mov dword [Regs.Edi],0
    mov eax,0300h               ;simulate real mode interrupt
    mov ebx,13h                 ;DISK Bios
    xor ecx,ecx                 ;no stack copy
    mov edi,Regs
    int 31h
    bt dword [Regs.Flags],0     ;set carry if error
    jc near .End

    ; translate convoluted BIOS values into halfway useful tracks/sectors/sides
    mov byte [Disk.ReadFlags],Disk.ReadDriveInfo
    mov edx,[Regs.Edx]
    movzx ecx,word [Regs.Ecx]
    inc dh
    mov bl,cl
    mov [Disk.Sides],dh
    shr cl,6                    ;bring highest two bits down
    xchg cl,ch
    and ebx,63
    inc ecx
    mov [Disk.Sectors],ebx
    mov [Disk.Tracks],ecx
    imul ecx,dword [Disk.Sides]
    imul ecx,ebx
    mov [Disk.TotalSectors],ecx

    ; set default OS sector depending on drive type
    ; floppy boot sector starts at first sector (0:0:1), hard drive boot
    ; sectors generally start on side 1 (0:1:1), unless there is a drive
    ; overlay program or it is some strange OS.
    cmp byte [Disk.Drive],80h
    jae .HardDrive
    xor ebx,ebx
.HardDrive:
    mov [Disk.OsSector],ebx

    ; set bytes per sector
    ; I don't know why some BIOS's do not return a ptr to the Disk Base Table
    movzx eax,word [Regs.Es]
    shl eax,4                   ;segment *16
    add eax,[Regs.Edi]          ;add offset
    ;jz .InvalidBpt
    cmp eax,0FFFF0h              ;<1Mb
    jae .InvalidBpt
    mov cl,[eax+3]              ;get bytes per sector code
    mov edx,1
    add cl,7                    ;+7 shift amount
    shl edx,cl                  ;1<<(code+7) = sector bytes
    cmp edx,Disk.MaxSectorSize
    jb .ValidBpt
.InvalidBpt:
    mov edx,512                 ;default sector size of most drives
    mov cl,9
.ValidBpt:
    mov [Disk.SectorBytes],edx
    mov [Disk.SectorBytesShl],cl
    clc
.End:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Queries all BIOS supported drives and adds them to a list. May be
; unnecessary to remake the list every time, but just in case some laptop
; BIOS supports removable/dynamic drives, or something similar arises...
SelectBiosDrive:
.MaxDrives  equ 8               ;maximum number of drives this program lists
    mov byte [Main.Mode],Modes.SelectBiosDrive
    mov dword [Main.KeyListPtr],.KeyList
    mov dword [Main.KeyJtblPtr],.KeyJtbl

    ; query all BIOS drives
    mov dword [Menu.Total],0
    mov dword [Menu.Selected],0
    xor edx,edx                 ;use as drive number
.QueryNext:

    mov byte [Regs.Eax+1],08h   ;get current drive parameters
    mov [Regs.Edx],dl
    mov eax,0300h               ;simulate real mode interrupt
    mov ebx,13h                 ;DISK Bios
    xor ecx,ecx                 ;no stack copy
    mov edi,Regs
    int 31h
    test byte [Regs.Flags],1    ;check carry for error
    jnz .InvalidDrive
    cmp word [Regs.Ecx],0       ;!! some BIOS's don't set carry !!
    je .InvalidDrive            ;so we must check the other variables too
    cmp byte [Regs.Edx],1
    jae .ValidDrive
.InvalidDrive:
    cmp edx,128                 ;no more drives
    jae .EndQuery
    mov edx,128                 ;continue with hard drives now
    jmp short .QueryNext

.ValidDrive:
    mov edi,[Menu.Total]
    cmp [Disk.Drive],dl
    jne .NotSelectedDrive
    mov [Menu.Selected],edi
.NotSelectedDrive:
    mov [Drives.List+edi],dl     ;store drive in list
    inc edi
    inc edx                     ;next drive
    mov [Menu.Total],edi
    cmp edi,.MaxDrives
    jb .QueryNext
.EndQuery:

    ;call .Draw
    ;ret (fall through)

.Draw:
    call DisplayClear
    cmp dword [Menu.Total],0
    jle near .NoDrives

    xor edx,edx                 ;start with first drive (floppy)
    push dword [Menu.Total]
.DrawNextDrive:
    push edx                    ;save row
    mov al,[Drives.List+edx]
    mov esi,Drives.FdString
    cmp al,80h
    jb .DrawFloppyDrive
    mov esi,Drives.HdString
.DrawFloppyDrive:
    add dl,'0'
    cld
    mov byte [Drives.BiosString],dl
    mov edi,Drives.BiosString+2
    mov ecx,Drives.TypeStringLen
    rep movsb
    ;eax=drive number
    mov edi,Drives.BiosString+16
    mov ebx,16
    mov ecx,2
    call NumToString.OfRadix

    mov esi,Drives.BiosString
    mov eax,Drives.BiosStringLen
    mov edx,[esp]
    xor ecx,ecx                 ;col 0
    call DisplayText
    pop edx
    inc edx
    dec dword [esp]
    jg .DrawNextDrive
    pop ecx

    jmp Menu.HighlightChoice
    ;ret

.NoDrives:
    mov esi,Text.NoDrives
    call GetStrLen
    xor edx,edx                 ;row 0
    xor ecx,ecx                 ;col 0
    ;eax=string length
    ;esi=string source
    jmp DisplayText
    ;ret

.EnterKey:
    mov eax,[Menu.Selected]
    mov dl,[Drives.List+eax]
    mov [Disk.Drive],dl
    call GetDriveInfo
    call LoadBootSector
    jmp MainMenu
    ;ret

section .data
.KeyList:       db 1,2
                db 13
                db "HP"
align 4
.KeyJtbl:       dd .EnterKey,Menu.UpKey,Menu.DownKey
section .text


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SelectExportDrive:
.MaxDrives  equ 26              ;maximum number of drives this program lists
    mov byte [Main.Mode],Modes.SelectExportDrive
    mov dword [Main.KeyListPtr],.KeyList
    mov dword [Main.KeyJtblPtr],.KeyJtbl

    ; query all OS drives
%if 0
    mov ebx,1                   ;start at A:
    xor ecx,ecx
    mov [Menu.Selected],ecx
.QueryNext:
    mov eax,4408h
    int 21h
    jc .InvalidDrive
    mov [Drives.List+ecx],bl
    inc ecx
.InvalidDrive:
    inc ebx
    cmp ebx,.MaxDrives
    jbe .QueryNext
    mov [Menu.Total],ecx
%else
    mov ah,19h                  ;get current drive
    int 21h
    push eax                    ;save current drive
    xor ecx,ecx                 ;start at A:
    xor edx,edx
    mov [Menu.Selected],ecx
.QueryNext:
    mov ah,0Eh                  ;set drive
    int 21h
    mov ah,19h                  ;get drive to see if changed
    int 21h
    cmp al,dl
    jne .InvalidDrive
    mov [Drives.List+ecx],dl
    cmp dl,[.Selected]
    jne .NotSelectedDrive
    mov [Menu.Selected],ecx
.NotSelectedDrive:
    inc ecx
.InvalidDrive:
    inc edx
    cmp edx,.MaxDrives
    jb .QueryNext
    mov [Menu.Total],ecx
    pop edx                     ;restore current drive
    mov ah,0Eh
    int 21h
%endif

    ; draw list
.Draw:
    call DisplayClear

    xor edx,edx                 ;start from first drive
    push dword [Menu.Total]
.DrawNextDrive:
    push edx                    ;save row
    mov al,[Drives.List+edx]
    add al,'A'
    mov byte [Drives.DosString],al
    mov esi,Drives.DosString
    mov eax,2                   ;string length
    mov edx,[esp]               ;row
    xor ecx,ecx                 ;col 0
    call DisplayText
    pop edx
    inc edx
    dec dword [esp]
    jg .DrawNextDrive
    pop ecx

    jmp Menu.HighlightChoice
    ;ret

.EnterKey:
    mov ebx,[Menu.Selected]
    mov dl,[Drives.List+ebx]
    mov ah,0Eh                  ;DOS funtion: set current drive
    mov [.Selected],dl
    int 21h
    jmp MainMenu
    ;ret

section .data
.Selected:      db 2
.KeyList:       db 1,2
                db 13
                db "HP"
align 4
.KeyJtbl:       dd .EnterKey,Menu.UpKey,Menu.DownKey
section .text


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ViewSectors:
    call VerifyRead.DriveInfo

    mov byte [Main.Mode],Modes.ViewSectors
.GivenMode:
    mov dword [Main.KeyListPtr],.KeyList
    mov dword [Main.KeyJtblPtr],.KeyJtbl

    call DisplayClear
    push dword 1BFFh            ;CharColor
    push dword (32<<24)|(16<<16)|0<<8|2  ;row, column, height, width
    call DisplayFill
    add esp,byte 8

.Draw:
    call .FillBufferCheck

    mov eax,"    "
    mov ecx,.LsLen/4
    mov edi,.Ls
    cld
    rep stosd

    push dword .Buffer
    push dword 2
    push dword [Disk.SectorBytes]
.NextRow:
    cld
    mov esi,[esp+8]
    mov ecx,32/4
    mov edi,.Ls
    rep movsd
    lea esi,[edi-32]
    mov eax,32                  ;string length
    mov edx,[esp+4]             ;row
    xor ecx,ecx                 ;col 0
    call DisplayText
    add dword [esp+8],byte 32   ;next row in buffer
    inc dword [esp+4]           ;next row on screen
    sub dword [esp],byte 32
    jg .NextRow
    add esp,byte 12

    mov edx,Text.CurrentThs
    jmp WriteString.Formatted
    ;ret

.FillBufferCheck:
    ; if sector has either never been read, or some other code changed the
    ; current sector from the last one read
    mov eax,[Disk.CurSector]
    cmp [Disk.PreSector],eax
    jne .FillBuffer
    test byte [Disk.ReadFlags],Disk.ReadSector
    jnz .NoRefill

.FillBuffer:
    push dword .Buffer
    mov [Disk.PreSector],eax
    sub esp,byte 12
    call SectorToThs
    call ReadThs

    ; keep track/side/sector for status bar display
    pop dword [Disk.Track]
    pop dword [Disk.Side]
    pop dword [Disk.Sector]
    pop eax ;discard
    or byte [Disk.ReadFlags],Disk.ReadSector
.NoRefill:
    ret

.EscapeKey:
    cmp byte [Main.Mode],Modes.ViewFileSector
    jne near MainMenu
    jmp ViewFolder

.EnterKey:
    cmp byte [Main.Mode],Modes.ViewSectors
    je .IgnoreEnter
    cmp byte [Main.Mode],Modes.SelectOsBase
    je .SelectOsBase
    jmp ExportFile
.SelectOsBase:
    mov eax,[Disk.CurSector]
    mov [Disk.OsSector],eax
    call LoadBootSector
    jmp MainMenu
.IgnoreEnter:
    ret

.HomeKey:
    xor eax,eax
    jmp short .CheckSector
.EndKey:
    mov eax,[Disk.TotalSectors]
    dec eax
    jmp short .CheckSector
.UpKey:
.DownKey:
    mov eax,1
    jmp short .ScrollSector
.LeftKey:
.RightKey:
    mov eax,[Disk.Sectors]
    jmp short .ScrollSector
.PgUpKey:
.PgDnKey:
    mov eax,[Disk.Sectors]
    imul dword [Disk.Sides]
    ;jmp short .ScrollSector
; (eax=sector difference)
.ScrollSector:
    shr ecx,1
    jc .ScrollPositive
    neg eax
.ScrollPositive:
    add eax,[Disk.CurSector]
.CheckSector:
    js .IgnoreScroll
    cmp [Disk.TotalSectors],eax
    jbe .IgnoreScroll
    ; rather than redraw now (in case drive falls behind keyboard rate)
    ; simply set the sector, invalidate the buffer, and read later
    mov [Disk.CurSector],eax
    mov dword [Main.RedrawCode],.Draw
    and byte [Disk.ReadFlags],~Disk.ReadSector
.IgnoreScroll:
    ret

.ViewFolderKey:
    mov eax,[Disk.CurSector]
    xor esi,esi
    ;shl edx,5                   ;*32 bytes per directory entry
    ;mov cl,[Disk.SectorBytesShl]
    ;movzx ebx,word [BootSector.RootEntries]
    ;mov [Disk.RootSector],eax
    mov [Folder.Sector],eax     ;set base folder
    mov [Folder.Depth],esi
    mov [Folder.PathLen],esi
    mov [Folder.Cluster],dword 0
    mov [Folder.Entries],dword 512
    mov byte [Folder.Path],0    ;set path to root
    jmp ViewFolder


section .bss
alignb 4
.LsLen          equ 80
.Ls:            resb .LsLen
.BufferSize     equ 2048
.Buffer:        resb .BufferSize
section .data
.KeyList:       db 2,9
                db 27,13,"HPKMIQGOR"
align 4
.KeyJtbl:       dd .EscapeKey,.EnterKey,.UpKey,.DownKey,.LeftKey,.RightKey,.PgUpKey,.PgDnKey,.HomeKey,.EndKey,.ViewFolderKey
section .text


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SelectOsBase:
    call VerifyRead.DriveInfo

    mov eax,[Disk.OsSector]
    mov [Disk.CurSector],eax
    mov byte [Main.Mode],Modes.SelectOsBase
    jmp ViewSectors.GivenMode


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Fills the boot sector information with that of a standard floppy
; (in case the boot sector is unreadable or corrupted)
AssumeFloppyFat:
    call VerifyRead.DriveInfo

    mov esi,StandardFloppyBootSector
    mov edi,BootSector
    mov ecx,512/4
    cld
    rep movsd
    call LoadBootSector.Using
    jmp MainMenu


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ViewFat:
    call VerifyRead.DriveInfo
    call VerifyRead.BootSector
    mov ah,2                    ;Key BIOS: get shift status
    int 16h
    test al,1                   ;test for right shift
    jz .FirstFat
    and byte [Disk.ReadFlags],~Disk.ReadFat
    or byte [Disk.ReadFlags],Disk.ReadSecondFat
.FirstFat:
    call VerifyRead.Fat

    ;display contents
.Draw:
    ;...
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ViewFolder:
.RowsPerPage    equ 48

    call VerifyRead.DriveInfo
    call VerifyRead.BootSector
    call VerifyRead.Fat

    mov byte [Main.Mode],Modes.ViewFolder
    mov dword [Main.KeyListPtr],.KeyList
    mov dword [Main.KeyJtblPtr],.KeyJtbl

    ; read directory if not already
    test byte [Disk.ReadFlags],Disk.ReadFolder
    jnz .FolderRead
.RereadFolder:
    call ReadFolder
    or byte [Disk.ReadFlags],Disk.ReadFolder
.FolderRead:

    call DisplayClear
    mov ecx,[Folder.PathLen]
    mov edx,Folder.Path
    mov byte [edx+ecx],0
    call WriteString
    mov edx,.FileAtrTitles
    call WriteString

.Draw:
    ; draw filename, size, date/time, cluster
    push dword 0
.NextFolder:
    mov eax,[esp]
    add eax,[.TopFile]
    cmp [Folder.Entries],eax
    jbe .NoMoreFiles
    call .FormatFileInfo
    mov esi,.Ls
    mov edx,[esp]
    mov eax,.LsLen
    xor ecx,ecx
    add edx,byte 2
    call DisplayText
    inc dword [esp]
    cmp dword [esp],.RowsPerPage
    jb .NextFolder
    jmp short .DoneDrawing
.NoMoreFiles:
    pop edx
    mov eax,(.LsLen<<8)|.RowsPerPage ;height
    push dword 0FF20h           ;CharColor blank space
    sub eax,edx                 ;rows remaining = RowsPerPage-rows drawn
    shl eax,16
    lea eax,[edx+eax+2]
    push eax                    ;row, column, height, width
    call DisplayFill
    add esp,byte 4
.DoneDrawing:
    add esp,byte 4

    ;call .HighlightChoice
    ;ret

.HighlightChoice:
    mov eax,[Folder.SelectedFile]
    mov ebx,dword 1BFFh         ;CharColor
;(ax=row & col, bx=charcolor)
.DrawHighlight:
    sub eax,[.TopFile]
    js .IgnoreHighlight
    cmp eax,.RowsPerPage
    jae .IgnoreHighlight
    add eax,(1<<16)|(.LsLen<<24)|2  ;height & width
    push ebx                    ;CharColor
    push eax
    call DisplayFill
    add esp,byte 8
.IgnoreHighlight:
    ret

.SpaceKey: ;show file/folder
    call GetFileCluster
    call ClusterToSector
    cmp [Disk.TotalSectors],eax
    jbe .IgnoreSpace
    mov [Disk.CurSector],eax
    call GetFileInfo
    ; eax=absolute sector

    ; display sector
    mov byte [Main.Mode],Modes.ViewFileSector
    jmp ViewSectors.GivenMode
.IgnoreSpace:
    ret

.EnterKey:
    ; export file
    call GetFileCluster
    call GetFileInfo
    jmp ExportFile

%if 0
.PgUpKey:
    mov eax,-.RowsPerPage
    jmp short .Scroll
.PgDnKey:
    mov eax,.RowsPerPage
.Scroll:
    add eax,[.TopFile]
    jge .ScrollTopOk
    xor eax,eax
.ScrollTopOk:
    cmp [Folder.Entries],eax
    jb .ScrollBtmOk
    mov eax,[Folder.Entries]
    dec eax
    js .IgnoreScroll
.ScrollBtmOk:
    cmp [.TopFile],eax
    je .IgnoreScroll
    mov [.TopFile],eax
    jmp .Draw
.IgnoreScroll:
    ret
%endif

.PgUpKey:
    mov eax,-.RowsPerPage
    jmp short .SelectRelative
.PgDnKey:
    mov eax,.RowsPerPage
    jmp short .SelectRelative
.HomeKey:
    xor eax,eax
    jmp short .Select
.EndKey:
    mov eax,[Folder.Entries]
    dec eax
    jmp short .Select
.UpKey:
    mov eax,-1
    jmp short .SelectRelative
.DownKey:
    mov eax,1
    ;jmp short .SelectRelative
.SelectRelative:
    add eax,[Folder.SelectedFile]
.Select:
    jns .SelectTopOk
    xor eax,eax
.SelectTopOk:
    cmp [Folder.Entries],eax
    ja .SelectBtmOk
    mov eax,[Folder.Entries]
    dec eax
    je .IgnoreScroll
.SelectBtmOk:
    cmp [Folder.SelectedFile],eax
    je .IgnoreScroll
    xchg [Folder.SelectedFile],eax
    mov ebx,dword 7FFh          ;CharColor gray
    call .DrawHighlight

    ; determine if scroll is needed
    mov eax,[Folder.SelectedFile]
    mov ebx,[.TopFile]
    cmp eax,ebx
    jb .SelectScroll

    add ebx,byte .RowsPerPage-1
    cmp eax,ebx
    jb near .HighlightChoice
    sub eax,byte .RowsPerPage-1
.SelectScroll:
    mov [.TopFile],eax
    jmp .Draw
.IgnoreScroll:
    ret

.BackspaceKey: ;set folder to root
    xor esi,esi
    mov eax,[Disk.RootSector]
    mov [Folder.Depth],esi
    mov [Folder.Sector],eax     ;set starting folder to root
    mov [Folder.PathLen],esi
    mov [Folder.Cluster],esi
    mov [Folder.Entries],esi
    ret

.RightKey: ;enter deeper into path
    mov ebx,[Folder.Depth]
    cmp ebx,Folder.MaxDepth
    jae .IgnoreScroll;.IgnoreRightKey
    cld
    mov eax,[Folder.SelectedFile]
    mov ecx,[Folder.Cluster]
    mov edx,[Folder.Sector]
    mov edi,[Folder.PathLen]
    mov [Folder.ParentIdxs+ebx*4],eax
    mov [Folder.ParentClusters+ebx*4],ecx
    mov [Folder.ParentSectors+ebx*4],edx
    mov [Folder.ParentPathLens+ebx*4],edi

    call GetFileCluster
    test byte [esi+DirEntry.Attribute],File.AtrFolder
    jz .IgnoreRightKey
    cmp eax,0FFF1h              ;bad cluster or end of chain
    jae .IgnoreRightKey
    test eax,eax                ;free space
    jz .IgnoreRightKey
    cmp [Folder.Cluster],eax    ;self reference (same folder)
    je .IgnoreRightKey
    cmp byte [esi+DirEntry.Filename],02Eh ;ignore parent directory indicators
    je .IgnoreRightKey

    mov [Folder.Cluster],eax
    call ClusterToSector
    mov [Folder.Sector],eax
    call AppendFileName
    mov ax,'\'                  ;put backslash & null on end of path
    stosw
    sub edi,Folder.Path+1
    mov dword [.TopFile],0
    mov dword [Folder.SelectedFile],0
    mov [Folder.PathLen],edi
    inc dword [Folder.Depth]

    jmp .RereadFolder
.IgnoreRightKey:
    ret

.LeftKey: ;retreat up path
    mov ebx,[Folder.Depth]
    test ebx,ebx
    jle .IgnoreLeftKey
    dec ebx
    mov [Folder.Depth],ebx
    mov eax,[Folder.ParentIdxs+ebx*4]
    mov ecx,[Folder.ParentClusters+ebx*4]
    mov edx,[Folder.ParentSectors+ebx*4]
    mov edi,[Folder.ParentPathLens+ebx*4]
    mov [Folder.SelectedFile],eax
    mov [Folder.Cluster],ecx
    sub eax,byte .RowsPerPage/2
    mov [Folder.Sector],edx
    jns .TopRowOk
    xor eax,eax
.TopRowOk:
    mov [Folder.PathLen],edi
    mov [.TopFile],eax
    mov byte [Folder.Path+edi],0

    jmp .RereadFolder
.IgnoreLeftKey:
    ret

; (eax=file entry #)
.FormatFileInfo:
    mov esi,eax
    shl esi,5                   ;*32
    add esi,Folder.List
    mov edi,.LsNumber
    mov ecx,4
    mov byte [NumToString.FillChar],'0'
    call NumToString.OfLength

    mov eax,[esi+DirEntry.Date]
    push eax                    ;save two copies
    push eax
    mov edi,.LsDate
    shr eax,9                   ;select year
    mov ecx,4
    and eax,127
    add eax,1980
    call NumToString.OfLength
    pop eax
    ;mov edi,.LsDate+5
    add edi,byte 6
    shr eax,5                   ;select month
    mov ecx,2
    and eax,15
    call NumToString.OfLength
    ;mov edi,.LsDate+8
    add edi,byte 4
    pop eax
    mov ecx,2
    and eax,31                  ;select day
    call NumToString.OfLength

    mov ecx,2
    mov eax,[esi+DirEntry.Time]
    push ecx                    ;save two copies of length
    push eax                    ;and two copies of time
    push ecx
    push eax
    mov edi,.LsTime
    shr eax,9                   ;select hour
    mov ecx,2
    and eax,31
    call NumToString.OfLength
    pop eax
    ;mov edi,.LsTime+3
    add edi,byte 4
    shr eax,5                   ;select minute
    pop ecx
    and eax,63
    call NumToString.OfLength
    ;mov edi,.LsTime+6
    add edi,byte 4
    pop eax
    shl eax,1
    pop ecx
    and eax,63                  ;select second
    call NumToString.OfLength

    mov byte [NumToString.FillChar],' '
    mov eax,[esi+DirEntry.Size]
    mov edi,.LsSize
    ;mov ecx,10
    call NumToString.ToDest
    movzx eax,word [esi+DirEntry.Cluster]
    mov edi,.LsCluster
    ;mov ecx,10
    call NumToString.ToDest

    ; if attribute is 0Fh then it is invalid and is a Win95+ long filename
    mov al,[esi+DirEntry.Attribute]
    xor bl,bl
    test al,File.AtrFolder
    jz .FfiNotFolder
    mov bl,16                   ;arrow character
.FfiNotFolder:
    mov byte [.LsNumber+5],bl
    mov edi,.LsAttribute+7
    mov ecx,8
.CheckAtr:
    shr al,1
    jnc .AtrLowerCase
    and byte [edi],~32
    jmp .NextAtr
.AtrLowerCase:
    or byte [edi],32
.NextAtr:
    dec edi
    dec ecx
    jg .CheckAtr

    mov edi,.LsName
    cld
    movsd                       ;transfer filename
    movsd
    lodsd
    shl eax,8
    mov al,'.'
    stosd

    ret

section .data
align 4
.TopFile:       dd 0            ;file entry at top of list
.KeyJtbl:       dd .EnterKey
                dd .SpaceKey
                dd .BackspaceKey
                dd .UpKey
                dd .DownKey
                dd .PgUpKey
                dd .PgDnKey
                dd .HomeKey
                dd .EndKey
                dd .LeftKey
                dd .RightKey
.KeyList:       db 3,8
                db 13," ",8
                db "HPIQGOKM"
.FileAtrTitles: db 13,10,"Entry   Name  Ext Attributes     Size    Cluster    Date      Time",0
.Ls:
.LsNumber:      db "####  "
.LsName:        db "12345678.123 "
.LsAttribute:   db "xxadvshr "
.LsSize:        db "###Size### "
.LsCluster:     db "##Cluster# "
.LsDate:        db "Date-##-## "
.LsTime:        db "##:##:##"
.LsLen          equ $-.Ls
section .text


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ShowDriveInfo:
    test byte [Disk.ReadFlags],Disk.ReadDriveInfo
    jz .End

    ; display drive parameters
    mov edx,Text.DriveInfo
    jmp WriteString.Formatted
    ;ret
.End:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ShowBootSectorInfo:
    ;clear screen & display drive parameters
    test byte [Disk.ReadFlags],Disk.ReadBootSector
    jz .End
    mov edx,Text.BootSectorInfo
    jmp WriteString.Formatted
.End:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Checks that certain attributes have been read first.
; This routine does NOT return to the caller if any condition fails.
VerifyRead:

.BootSector:
    test byte [Disk.ReadFlags],Disk.ReadBootSector
    jnz .Ok
    pop eax                     ;discard return address
    call LoadBootSector
    jc .Err
    jmp ShowBootSectorInfo
    ;ret
.Err:
.Ok:
    ret

.DriveInfo:
    test byte [Disk.ReadFlags],Disk.ReadDriveInfo
    jnz .Ok
    pop eax                     ;discard return address
    jmp SelectBiosDrive

.Fat:
    test byte [Disk.ReadFlags],Disk.ReadFat
    jnz .Ok
    jmp LoadFat


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Converts absolute sector into track/side/sector.
; (eax=sector, dwords track, side, sector)
; (; esi, edi)
SectorToThs:
.Track      equ 4
.Side       equ 8
.Sector     equ 12

    xor edx,edx                 ;zero high dword
    div dword [Disk.Sectors]
    inc edx
    mov [esp+.Sector],edx       ;Sector = (AbsSector MOD Sectors) + 1
    xor edx,edx                 ;zero high dword
    div dword [Disk.Sides]
    mov [esp+.Side],edx         ;Side = (AbsSector / Sectors) MOD Sides
    mov [esp+.Track],eax        ;Track = AbsSector / (Sectors * Sides)
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Reads an absolute sector.
; (eax=sector)
ReadSector:
    push dword 0 ;no copy
    sub esp,byte 12
    call SectorToThs
    call ReadThs
    add esp,byte 16
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Reads a single sector from a BIOS drive (not DOS drive). If the information
; needs to be retained, it should be copied from the low memory buffer into
; somewhere more permanent.
;
; (dwords track, side, sector, destination)
; (cf=error; esi)
ReadThs:
.Track      equ 4
.Side       equ 8
.Sector     equ 12
.Dest       equ 16 ;pass null for no copy

    ; sure is a lot of extra junk to do just for a real mode interrupt
    mov ecx,[esp+.Track]
    mov dword [Regs.Eax],0201h ;read one sector
    mov dl,[Disk.Drive]
    ;xor dl,dl                   ;safety hack for now, read floppy drive
    xchg cl,ch                  ;stupid BIOS expects these flipped!?
    shl cl,6
    mov dh,[esp+.Side]
    or cl,[esp+.Sector]
    mov ebx,[Disk.BufferPtr]
    mov [Regs.Ebx],dword 0
    mov [Regs.Edx],edx
    shr ebx,4                   ;get segment /16
    mov [Regs.Ecx],ecx          ;set track and sector
    mov [Regs.Es],bx            ;set destination ptr

    mov eax,0300h               ;simulate real mode interrupt
    mov ebx,13h                 ;DISK Bios
    xor ecx,ecx                 ;no stack copy
    mov edi,Regs
    int 31h
    bt dword [Regs.Flags],0     ;set carry if read error
    jc .End

    ; copy from low memory to view buffer
    mov edi,[esp+.Dest]
    test edi,edi
    jz .End
    push esi
    mov ecx,[Disk.SectorBytes]
    mov esi,[Disk.BufferPtr]
    shr ecx,2                   ;/4
    cld
    rep movsd
    pop esi
    mov [esp+.Dest],edi
    ;clc
.End:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LoadBootSector:
    mov edx,Text.ReadBootSector
    call WriteString

    push dword BootSector ;copy dest
    mov eax,[Disk.OsSector]
    sub esp,byte 12
    mov [Disk.CurSector],eax
    call SectorToThs
    call ReadThs
    lea esp,[esp+16]
    jc near .Error

.Using:
    or byte [Disk.ReadFlags],Disk.ReadBootSector
    and byte [Disk.ReadFlags],~(Disk.ReadFat|Disk.ReadFolder)

    movzx ebx,word [BootSector.TotalSectorsW]
    movzx edx,byte [BootSector.ClusterSectors]
    test ebx,ebx
    jnz .FewSectors
    mov ebx,[BootSector.TotalSectorsD]
.FewSectors:
    mov [Disk.ClusterSectors],edx
    mov [Disk.OsSectors],ebx

    ; determine base sector for each main part of FAT system: fat,root,data
    ; unfortunately a lot of important variables must stupidly be derived
    ; through calculations.
    movzx eax,word [BootSector.ReserveSectors]
    add eax,[Disk.OsSector]
    movzx ebx,word [BootSector.FatSectors]
    mov [Disk.FatSector],eax
    movzx edx,word [BootSector.RootEntries]
    mov [Disk.FatSectors],ebx
    add eax,ebx
    cmp byte [BootSector.NumberFats],2
    jb .SingleFat
    add eax,ebx
.SingleFat:

    ; (eax=root sector edx=root entries)
    mov [Disk.RootEntries],edx
    xor esi,esi
    shl edx,5                   ;*32 bytes per directory entry
    mov cl,[Disk.SectorBytesShl]
    movzx ebx,word [BootSector.RootEntries]
    mov [Disk.RootSector],eax
    mov [Folder.Sector],eax     ;set starting folder to root
    mov [Folder.Depth],esi
    mov [Folder.PathLen],esi
    mov [Folder.Cluster],esi
    mov [Folder.Entries],esi
    mov byte [Folder.Path],0    ;set path to root
    shr edx,cl                  ;/sector size
    add eax,edx
    mov [Disk.DataSector],eax

    ; (eax=data sector)
    ; determine data sector & number of clusters
    neg eax
    add eax,[Disk.OsSectors]
    mov [Disk.DataSectors],eax
    xor ecx,ecx
    bsf ecx,dword [Disk.ClusterSectors]
    shr eax,cl
    cmp eax,Fat.Limit
    jb .FatSizeOk
    mov eax,Fat.Limit
.FatSizeOk:
    mov [Disk.Clusters],eax

    mov edx,Text.Done
    call WriteString.WithEol
    clc
    ret

.Error:
    mov edx,Text.Error
    call WriteString.WithEol
    stc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LoadFat:
    ;(assume this has already been checked by the caller)
    ;call VerifyRead.DriveInfo
    ;call VerifyRead.BootSector

    mov edx,Text.ReadingFat
    call WriteString

    ; read fat from disk
    push dword [Disk.FatSectors]
    mov esi,[Disk.FatSector]
    test byte [Disk.ReadFlags],Disk.ReadSecondFat
    jz .FirstFat
    add esi,[Disk.FatSectors]   ;read second FAT instead
.FirstFat:
    push dword Fat.Ptrs         ;copy dest
    sub esp,byte 12
    .Sectors    equ 16
    .Dest       equ 12
    .Sector     equ 8
    .Side       equ 4
    .Track      equ 0
.NextSector:
    mov eax,esi
    call SectorToThs
    call ReadThs
    jc near .ReadError
    dec dword [esp+.Sectors]    ;one less sector
    jle .EndFat
    inc esi                     ;next sector
    cmp dword [esp+.Dest],Fat.Ptrs+(Fat.Limit*2)
    jb .NextSector
.EndFat:
    add esp,byte 16+4

    ; if 12bit, remap to 16bit by shifting
    cmp dword [Disk.Clusters],0FF1h
    jae .16bit
    mov esi,Fat.Ptrs+((65536*12)/8)-3   ;12bit source offset
    mov edi,Fat.Ptrs+(65536*2)-4        ;16bit dest offset
    mov ecx,65536/2
.Next12bits:
    mov eax,[esi]
    sub esi,byte 3
    and eax,00FFFFFFh
    shl eax,4
    shr ax,4
    cmp ax,0FF1h
    jb .Cluster1
    or eax,0F000h
.Cluster1:
    cmp eax,0FF10000h
    jb .Cluster2
    or eax,0F0000000h
.Cluster2:
    mov [edi],eax
    sub edi,byte 4
    dec ecx
    jg .Next12bits
.16bit:

    mov edx,Text.Done
    call WriteString.WithEol

    mov edx,Text.MappingFat
    call WriteString

    ; clear array
    mov eax,-1
    mov edi,Fat.Idxs
    mov ecx,65336/4
    ;cld
    rep stosd

    ; create a table built that every FAT entry points back to its
    ; starting cluster.
    ;
    ; for count=0 to fat entries-1
    ;   if FatIdxs(count)=0FFFFh
    ;     if FatPtrs(count) != 0 && != (FFF1 to FFF7)
    ;       FatIdxs(count) = count
    ;       //follow to end of chain
    ;       piece = count
    ;       recursioncount = fatlimit
    ;       do while FatPtrs(piece) 1 to FFF1 | recursioncount-- <= 0
    ;         piece = FatPtrs(piece)
    ;         FatIdxs(piece) = count
    ;       loop
    ;     endif
    ;   endif
    ; endfor

    ; map fat indexes
    xor eax,eax
    xor ecx,ecx
.NextIdx:
    cmp word [Fat.Idxs+ecx*2],0FFFFh ;skip if entry already indexed
    jne .SkipEntry
    mov ax,[Fat.Ptrs+ecx*2]     ;get cluster holding next piece
    mov edi,Fat.Limit
    mov ebx,ecx
.NextEntry:
    test eax,eax
    lea edx,[eax+8]
    jz .SkipEntry               ;skip free cluster
    cmp dx,0FFF9h
    jae .SkipEntry              ;skip bad cluster
    cmp [Fat.Idxs+ebx*2],cx
    je .SkipEntry               ;encountered a circular reference
    mov [Fat.Idxs+ebx*2],cx     ;FatIdxs(count) = Count
    cmp ax,0FFF8h
    jae .SkipEntry              ;end of chain
    dec edi
    jle .SkipEntry              ;abort infinite recursion!
    mov ebx,eax
    mov ax,[Fat.Ptrs+eax*2]     ;get cluster holding next piece
    jmp short .NextEntry        ;recurse
.SkipEntry:
    inc ecx
    cmp [Disk.Clusters],ecx
    ja .NextIdx

    or byte [Disk.ReadFlags],Disk.ReadFat

    mov edx,Text.Done
    jmp WriteString.WithEol
    ;ret

.ReadError:
    add esp,byte 16+4
    mov edx,Text.Error
    call WriteString.WithEol
    stc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Reads the contents of a folder, its files and subfolders.
ReadFolder:
    ;(assume the caller already checked)
    ;VerifyRead.Fat

    ; determine number of directory entries
    mov eax,[Disk.SectorBytes]
    mov esi,[Folder.Sector]     ;starting sector of folder
    shr eax,5                   ;/32 bytes per directory entry
    mov edx,[Disk.ClusterSectors]
    cmp [Disk.DataSector],esi   ;check if in root folder or data section folder
    jbe .SubFolder              ;stupid, the root folder should be dynamic too
    ;mov edx,[Disk.FatSectors]
    mov edx,[Disk.RootEntries]
    mov cl,[Disk.SectorBytesShl]
    sub cl,5
    shr edx,cl
.SubFolder:
    mov dword [Folder.Entries],0

    push dword [Folder.Cluster] ;starting cluster of folder
    push eax                    ;directory entries per sector
    push edx                    ;sectors in directory
    push dword Folder.List      ;dest
    sub esp,byte 12             ;track/side/track
    .Cluster        equ 24
    .SectorEntries  equ 20
    .Sectors        equ 16
    .Dest           equ 12
    .Sector         equ 8
    .Side           equ 4
    .Track          equ 0
.NextSector:
    mov eax,esi
    cmp [Disk.TotalSectors],esi
    jbe .Error
    call SectorToThs
    call ReadThs
    inc esi                     ;next sector
    mov eax,[esp+.SectorEntries]
    add [Folder.Entries],eax
    cmp dword [Folder.Entries],Folder.MaxFiles
    jae .LastSector
    dec dword [esp+.Sectors]    ;how many sectors left in current cluster
    jg .NextSector

    cmp [Disk.DataSector],esi   ;check if in root folder or data section folder
    jae .LastSector
    mov eax,[Disk.ClusterSectors]
    mov esi,[esp+.Cluster]      ;get current cluster
    mov [esp+.Sectors],eax ;reset count for next cluster of sectors
    movzx esi,word [Fat.Ptrs+esi*2]
    test esi,esi                ;free space
    jz .LastSector
    cmp esi,0FFF1h              ;end of file or bad cluster?
    jae .LastSector
    mov [esp+.Cluster],esi      ;set current cluster to new one
    sub esi,byte 2              ;don't know why -2?
    mul esi
    add esi,[Disk.DataSector]   ;(new cluster - 2) * cluster per sector + data
    jmp short .NextSector
.LastSector:
    add esp,byte 16+12
    ;clc
    ret

.Error:
    add esp,byte 16+12
    stc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; () (eax=cluster, esi=folder list ptr)
GetFileCluster:
    ; get cluster
    mov esi,[Folder.SelectedFile]
    shl esi,5                   ;*32 bytes per entry
    add esi,Folder.List
    movzx eax,word [esi+DirEntry.Cluster]
    ;test eax,eax
    ;jz .BadCluster
    mov [File.Cluster],eax
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=cluster) (eax=sector; !edx)
ClusterToSector:
    sub eax,byte 2              ;don't know why -2?
    mul dword [Disk.ClusterSectors]
    add eax,[Disk.DataSector]   ;(new cluster - 2) * cluster per sector + data
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=dir entry ptr) (; esi)
GetFileInfo:
    mov al,[esi+DirEntry.Attribute]
    mov ebx,[esi+DirEntry.Size]
    mov cx,word [esi+DirEntry.Time]
    mov dx,word [esi+DirEntry.Date]
    mov [File.Attribute],al
    mov [File.Time],cx
    mov [File.Date],dx
    mov [File.Size],ebx
    push esi
    mov edi,[Folder.PathLen]
    call AppendFileName
    xor al,al
    stosb
    pop esi
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=source, edi=path len)
; (edi=ptr to next character after new path name)
AppendFileName:
    add edi,Folder.Path
    mov ecx,8
    call .NextPart
    cmp byte [esi],' '
    je .SkipExt
    mov al,'.'
    stosb
    mov ecx,3
    ;jmp .NextPart
;.SkipExt:
;    ret

; (esi=source, edi=dest, ecx=length of part)
.NextPart:
    cld
    lodsb
    cmp al,32
    je .EndAppend
    test al,al
    jz .EndAppend
    cmp edi,Folder.Path+Folder.PathSize-2
    jae .EndAppend
    stosb
    dec ecx
    jg .NextPart
.SkipExt:
    ret
.EndAppend:
    lea esi,[esi+ecx-1]
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; () (cf=error)
ExportFile:
    ; open file
    mov eax,6C00h
    mov ecx,[File.Attribute]
    mov esi,Folder.Path
    test ecx,File.AtrFolder
    jnz near .MakeFolder
    and ecx,File.AtrReadOnly|File.AtrHidden|File.AtrSystem|File.AtrArchive
    mov ebx,1                   ;write access only
    mov edx,00010000b
    int 21h
    jnc .Ok
    cmp al,3                    ;error code - path not found
    jne .Error
    ; remove preceding path & retry
    mov eax,6C00h
    add esi,[Folder.PathLen]
    int 21h
    jc .End
.Ok:
    ; export pieces of file
    push dword [File.Size]      ;maximum length
    push dword [File.Cluster]   ;starting cluster
    push eax                    ;file handle
    call ExportFatChain
    pop ebx
    lea esp,[esp+8]
    pushf                       ;save carry

    mov eax,5701h
    mov ecx,[File.Time]
    mov edx,[File.Date]
    ;mov edi,File.Date ?? documentation must be wrong about edi
    int 21h

    ; close file
    mov ah,3Eh
    int 21h
    popf
.End:
    ret
.Error:
    stc
    ret

; (edx=folder name)
.MakeFolder:
    mov edx,esi ;(Folder.Path)
    mov ah,39h                  ;create folder
    int 21h
    jc .End
    mov eax,4301h               ;set attributes
    and ecx,File.AtrHidden|File.AtrSystem
    int 21h
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (ebx=open file handle, esi=starting cluster)
ExportRawFile:
    ; open file
    mov ah,3Ch
    xor ecx,ecx
    mov edx,Text.ExportFileName
    int 21h
    jc .Error

    ; export pieces of file
    push dword [File.Size]      ;maximum length
    push dword [File.Cluster]   ;starting cluster
    push eax                    ;file handle
    call ExportFatChain
    pop ebx
    add esp,byte 8

    ; close file
    mov ah,3Eh
    int 21h
.Error:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ExportAllFiles:
    call VerifyRead.Fat
    call DisplayClear

    ; export all files starting from current path
.ExportNextFolder:
    call ReadFolder
   %if 0 ;->
    mov dword [ViewFolder.TopFile],dword 0
    mov dword [Folder.SelectedFile],dword 0
    call ViewFolder.FolderRead
    mov esi,Folder.List
    int3
   %endif ;<-
    xor ecx,ecx
    mov esi,Folder.List
    cmp [Folder.Entries],ecx
    jbe near .EndRecursion
.ExportNextFile:
    ; check file is valid, skip invalid files, deleted, long filenames...
    ;cmp byte [esi],0  ;unused entry, end of folder list
    cmp byte [esi+DirEntry.Filename],32  ;skip invalid filenames
    ;jbe .SkipFile
    jbe .EndFileList
    cmp byte [esi+DirEntry.Filename],0E5h ;skip deleted files
    je .SkipFile
    test byte [esi+DirEntry.Attribute],8|64|128  ;ignore labels & long filename
    jnz .SkipFile
    cmp byte [esi+DirEntry.Filename],02Eh ;ignore parent directory indicators
    je .SkipFile

    movzx eax,word [esi+DirEntry.Cluster]
    cmp eax,0FFF1h              ;bad cluster or end of chain
    jae .SkipFile
    test eax,eax                ;free space
    jz .SkipFile
    cmp [Folder.Cluster],eax    ;self reference (same folder)
    je .SkipFile
    cmp [Disk.Clusters],eax
    jbe .SkipFile
    mov [File.Cluster],eax

    push esi
    push ecx
    .ListPtr        equ 4
    .Entry          equ 0
    call GetFileInfo
    mov edx,Folder.Path
    call WriteString.WithEol
    call ExportFile
    pop ecx
    pop esi                     ;list ptr
    xor al,al
    xchg [ExportFatChain.Aborted],al
    cmp al,27
    je near .Abort
    ;cmp al,8
    ;je near .EndRecursion
.SkipFile:
    inc ecx
    add esi,byte 32             ;next folder entry
    cmp [Folder.Entries],ecx
    ja .ExportNextFile
.EndFileList:

;ÄÄÄÄÄÄÄÄÄÄ
    cmp dword [Folder.Depth],Folder.MaxDepth
    jae near .EndRecursion
    mov esi,Folder.List
    xor ecx,ecx
.RecurseNextFile:
    mov eax,100h
    int 16h
    cmp al,27
    je near .Abort
    ;cmp al,8
    ;je near .Abort2
    ;je near .EndRecursion

    ;;cmp byte [esi],0  ;unused entry, end of folder list
    cmp byte [esi+DirEntry.Filename],32  ;skip invalid filenames
    ;;jbe .SkipFile2
    jbe near .EndRecursion
    test byte [esi+DirEntry.Attribute],File.AtrFolder ;skip nonfolder
    jz near .SkipFile2
    cmp byte [esi+DirEntry.Filename],0E5h ;skip deleted files
    je near .SkipFile2
    test byte [esi+DirEntry.Attribute],8|64|128  ;ignore labels & long filename
    jnz near .SkipFile2
    cmp byte [esi+DirEntry.Filename],02Eh ;ignore parent directory indicators
    je near .SkipFile2
    movzx eax,word [esi+DirEntry.Cluster]
    cmp eax,0FFF1h              ;bad cluster or end of chain
    jae .SkipFile2
    test eax,eax                ;free space
    jz .SkipFile2
    cmp [Folder.Cluster],eax    ;self reference (same folder)
    je .SkipFile2

    ; Save current folder vars
    ; (ecx=child entry, esi=dir entry ptr, eax=cluster)
    mov ebx,[Folder.Depth]
    mov edi,[Folder.PathLen]
    mov [Folder.ParentIdxs+ebx*4],ecx  ;save entry # of folder being recursed into
    mov edx,[Folder.Sector]
    mov ecx,[Folder.Cluster]
    mov [Folder.ParentPathLens+ebx*4],edi
    mov [Folder.ParentSectors+ebx*4],edx
    mov [Folder.ParentClusters+ebx*4],ecx
    inc dword [Folder.Depth]

    ; Set new child folder vars
    ; (esi=dir entry ptr, eax=cluster, edi=path len)
    mov [Folder.Cluster],eax
    call ClusterToSector
    mov [Folder.Sector],eax
    call AppendFileName
    mov ax,'\'                  ;put backslash & null on end of path
    stosw
    sub edi,Folder.Path+1
    mov [Folder.PathLen],edi

    jmp .ExportNextFolder

.SkipFile2:
    inc ecx
    add esi,byte 32             ;next folder entry
    cmp [Folder.Entries],ecx
    ja near .RecurseNextFile
.EndRecursion:

    ; Restore parent folder vars
    mov ebx,[Folder.Depth]
    dec ebx
    jl .End
    mov [Folder.Depth],ebx
    mov eax,[Folder.ParentSectors+ebx*4]
    mov edx,[Folder.ParentClusters+ebx*4]
    mov edi,[Folder.ParentPathLens+ebx*4]
    mov [Folder.Sector],eax
    mov [Folder.Cluster],edx
    mov [Folder.PathLen],edi
    mov byte [Folder.Path+edi],0 ;set null on end of file

    ; Reread folder and scan through until next folder is found
    push dword [Folder.ParentIdxs+ebx*4]
    call ReadFolder
   %if 0 ;->
    mov ecx,[esp]
    mov dword [ViewFolder.TopFile],dword 0
    mov dword [Folder.SelectedFile],dword ecx
    call ViewFolder.FolderRead
    mov esi,Folder.List
    int3
   %endif ;<-
    pop ecx
    inc ecx
    mov esi,ecx
    shl esi,5
    add esi,Folder.List         ;esi list ptr=(entry# * 32) + Folder.List
    jmp .RecurseNextFile

.End:
    call MainMenu
    clc
    ret

.Abort:
    call MainMenu
    stc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (dwords open file handle, starting cluster, max file length)
ExportFatChain:
.FileHandle     equ 4
.FirstCluster   equ 8
.Length         equ 12

    ;read sector
    ;subtract sector size from file size
    ;write sector to file
    ;end if file size exceeded
    ;get next part
    ;end if user aborts
    ;end if last part of chain

    mov esi,[esp+.FirstCluster]
    ;mov si,[Fat.Idxs+esi*2]     ;get starting cluster of chain
    push dword Fat.Limit        ;to prevent possible infinite recursion
    push dword esi
    push dword [Disk.ClusterSectors]
    push dword 0 ;no buffer copy
    sub esp,byte 12
    .StackSize      equ 28
    .RecurseCount   equ 24
    .Cluster        equ 20
    .Sectors        equ 16
    .Dest           equ 12
    .Sector         equ 8
    .Side           equ 4
    .Track          equ 0
.NextCluster:
    cmp [Disk.Clusters],esi
    jbe near .Error
    sub esi,byte 2
    imul esi,dword [Disk.ClusterSectors]
    add esi,[Disk.DataSector]
.NextSector:
    cmp [Disk.TotalSectors],esi
    jbe near .Error
    mov eax,esi
    call SectorToThs
    call ReadThs
    ; ignore any read errors
    mov ecx,[Disk.SectorBytes]
    sub [esp+.StackSize+.Length],ecx
    jae .WholeSector
    add ecx,[esp+.StackSize+.Length]
.WholeSector:
    mov ebx,[esp+.StackSize+.FileHandle]
    mov edx,[Disk.BufferPtr]
    mov ah,40h
    int 21h
    jc .Error

    ; check for user abort
    mov ah,1                    ;Keyboard BIOS: check keypress status
    int 16h
    jz .NoKeys
    xor eax,eax                 ;Keyboard BIOS: get keypress
    int 16h
    cmp al,27
    je .Abort                   ;user pressed Escape
    cmp al,8
    je .Abort                   ;user pressed backspace
.NoKeys:

    cmp dword [esp+.StackSize+.Length],0
    jle .Eof
    inc esi                     ;next sector
    dec dword [esp+.Sectors]
    jg .NextSector              ;still more sectors in current cluster
    dec dword [esp+.RecurseCount]
    jle .Eof

    ; get next cluster
    mov eax,[Disk.ClusterSectors]
    mov esi,[esp+.Cluster]
    mov [esp+.Sectors],eax      ;reset counter
    test esi,esi                ;encountered free space
    jz .Eof
;    cmp [Fat.Ptrs+esi*2],word 0
;    ja .ValidFatPtr
;    inc esi
;    jmp short .PrematureEof
;.ValidFatPtr:
    mov si,[Fat.Ptrs+esi*2]
.PrematureEof:
    cmp esi,0FFF1h              ;end of file or bad cluster?
    mov [esp+.Cluster],esi
    jb near .NextCluster
.Eof:
    add esp,byte .StackSize
    ;clc
    ret

.Abort:
    mov byte [.Aborted],al
.Error:
    add esp,byte .StackSize
    stc
    ret

section .bss
.Aborted: resb 1
section .text


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; ()
ExportEntireMedia:
    call VerifyRead.DriveInfo

    push dword MainMenu         ;call this routine after returning
    call DisplayClear
    mov edx,Text.ExportMedia
    call WriteString

    ; wait for Enter keypress to continue
    xor eax,eax
    int 16h
    cmp al,13
    jne near .End

    ; create destination file
    mov ah,3Ch
    xor ecx,ecx
    mov edx,Text.ExportFileName
    int 21h
    mov edx,Text.ExportFileErr
    jc near DisplayErrMsg
    push eax

    call DisplayClear
    call ShowDriveInfo

    ; save cursector, zero cursector
    push dword [Disk.CurSector]
    push dword [Disk.TotalSectors]
    mov dword [Disk.CurSector],0
    push dword 0 ;no disk data copy
    sub esp,byte 12
    .StackSize      equ 28
    .FileHandle     equ 24
    .CurSector      equ 20
    .SectorsLeft    equ 16
    .Dest           equ 12
    .Sector         equ 8
    .Side           equ 4
    .Track          equ 0

.NextSector:
    ; translate linear sector into THS and display
    mov eax,[Disk.CurSector]
    call SectorToThs
    mov eax,[esp+.Track]
    mov ebx,[esp+.Side]
    mov ecx,[esp+.Sector]
    mov [Disk.Track],eax
    mov [Disk.Side],ebx
    mov [Disk.Sector],ecx
    mov edx,Text.CurrentThs
    call WriteString.Formatted

    ; clear buffer in case of read error
    cld
    mov ecx,[Disk.SectorBytes]
    mov edi,[Disk.BufferPtr]
    xor eax,eax
    shr ecx,2                   ;/4
    rep stosd

    ; read sector from source and write to file
    call ReadThs
    mov ah,40h
    mov ebx,[esp+.FileHandle]
    mov ecx,[Disk.SectorBytes]
    mov edx,[Disk.BufferPtr]
    int 21h

    ; next sector until last
    inc dword [Disk.CurSector]
    dec dword [esp+.SectorsLeft]
    jle .Abort

    ; end if Escape pressed
    mov ah,1
    int 16h
    cmp al,27
    jne .NextSector
    xor eax,eax
    int 16h

.Abort:
    add esp,byte 20
    pop dword [Disk.CurSector]

    ; close destination file
    pop ebx
    mov ah,3Eh
    int 21h

.End:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the length of a null-terminated string (ASCIIZ)
;
; (esi)
; (eax; *)
GetStrLen:
    mov ecx,8192                ;maximum length of characters
    mov edi,esi                 ;copy source for string length search
    mov eax,ecx                 ;make a copy of max length for later
    ;null is set in al by moving 8192 into it, which the lower byte is 0
    cld                         ;as always, look forward
    repne scasb                 ;search for the end
    sub eax,ecx                 ;get length
    dec eax                     ;minus the null at the end
	ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Turns a 32bit number into a decimal (or other) string, writing it to edi.
; By default, it converts a number to a decimal string, maximum of ten
; characters, stored in NumToString.Buffer. To change where the string is
; stored, the length, or radix, these variables can be passed to a different
; entry point. If an alternate destination is supplied, the default is a
; decimal number up to ten characters. If a length is supplied, so must the
; destination; and if the radix, so must both destination and length be given.
;
; (eax=number, ?edi=destination, ?ecx=maximum length, ?ebx=radix)
; (ecx=offset of first significant digit, ebx=radix used; esi)
NumToString:
    mov edi,.Buffer
;(edi=destination)
.ToDest:
    mov ecx,NumStringMaxLen ;default maximum of ten characters, since the largest 32bit number is 4 gigabytes
;(ecx=number of digits, edi=destination)
.OfLength:
	mov ebx,10              ;base of the decimal system
;(ebx=radix, ecx=number of digits, edi=destination)
.OfRadix:                   ;for hexadecimal and binary (even octal)
	xor edx,edx             ;set top 32 bits of quotient to zero
    lea edi,[edi+ecx-1]     ;start from rightmost character in number
.NextChar:
	div ebx                 ;divide number by the decimal base
    mov dl,[.NumberTable+edx] ;get ASCII character from table
    ;add dl,'0'             ;make remainder into an ASCII character
	mov [edi],dl            ;output result
    dec edi                 ;move backwards one character
	test eax,eax            ;see if we are done with the number
	jz .FillInBlanks        ;nothing but zeroes left
	xor edx,edx             ;set edx to zero again for next division
	dec ecx                 ;one less character to output
	jnz .NextChar
	ret

.FillInBlanks:
    mov al,[.FillChar]      ;fill in with spaces, zeroes, asterisks
    dec ecx                 ;one less than current count
    mov edx,ecx
    std                     ;move backwards
    rep stosb               ;for number of characters remaining
    mov ecx,edx             ;return offset of first digit
	ret

section .data
.FillChar:      db ' '
.NumberTable:   db "0123456789ABCDEF"
section .bss
.Buffer:    resb NumStringMaxLen
section .text


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (edx=row, ecx=col, eax=string length, esi=string source)
; (; edx, ecx)
DisplayText:
    mov edi,edx
    imul edi,80
    add edi,ecx
    cld
    lea edi,[Screen.Adr+edi*2]

.Next:
    movsb                       ;transfer text character
    inc edi                     ;skip color attribute
    dec al;eax
    jg .Next

    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DisplayClear:
    mov eax,07000700h
.UsingColor:
    mov ecx,(Screen.Height*Screen.Width)/2
    mov edi,Screen.Adr
    cld
    rep stosd
.CursorOnly:
    mov ah,02                   ;Video BIOS: set cursor position
    xor ebx,ebx                 ;page 0
    xor edx,edx                 ;top left (0:0)
    int 10h
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Fills a rectangular block of screen with specific color, character, or both.
; CharColor determines what to fill, low byte holding text character and high
; holding color attribute. 0FFh in either byte will leave that attribute
; alone. Of course, that means character 255 or pure white can be never be
; put on the screen, but who cares about those anyway.
;
; (bytes row, column, height, width, dword CharColor)
DisplayFill:
.Row        equ 4
.Col        equ 5
.Height     equ 6
.Width      equ 7
.CharColor  equ 8

    movzx edi,byte [esp+.Row]
    movzx ebx,byte [esp+.Height]
    xor ecx,ecx
    movzx edx,byte [esp+.Col]
    imul edi,80
    add edi,edx                 ;((row * 80) + column) * 2
    lea edi,[Screen.Adr+edi*2]  ;calculate offset to char or color attribute
    mov dl,Screen.Width
    mov eax,[esp+.CharColor]
    sub dl,[esp+.Width]
    shl dl,1                    ;(80-width)*2

    cmp ah,0FFh
    je .ByteNextRow             ;text character only
    cmp al,0FFh
    jne .WordNextRow            ;both text and color attribute
    inc edi                     ;color only
    mov al,ah

.ByteNextRow:
    mov cl,[esp+.Width]
.ByteNextCol:
    mov [edi],al
    add edi,byte 2
    dec ecx
    jg .ByteNextCol
    add edi,edx
    dec ebx
    jg .ByteNextRow
    ret

.WordNextRow:
    mov cl,[esp+.Width]
.WordNextCol:
    mov [edi],ax
    add edi,byte 2
    dec ecx
    jg .WordNextCol
    add edi,edx
    dec ebx
    jg .WordNextRow
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Scans through a list of key presses and returns the index matching the
; keypress given, or error if it wasn't found. Simply pass the keycode (which
; holds the ASCII character in al and scancode in ah) and a scan structure to
; it, which contains a list of keys, number of normal keys, and number of
; extended.
;
; The key list is limited to 255 keys to compare with.
;
; (ax=keycode, esi=keylist struct)
; (cf=error keypress not found, ecx=keynumber; eax,esi,ebx)
ScanForKey:
    cld
    lea edi,[esi+2]
    movzx ecx,byte [esi]
    test al,al
    jz .ExtendedKey
    repne scasb
    jnz .NotFound
    not cl
    add cl,[esi]
    clc
    ret

.ExtendedKey:
    add edi,ecx
    mov al,ah
    mov cl,[esi+1]
    repne scasb
    jnz .ExtendedKeyNotFound
    not cl
    add cl,[esi+1]
    xor al,al               ;put null back into al
    add cl,[esi]
    clc
    ret

.ExtendedKeyNotFound:
    xor al,al               ;put null back into al
.NotFound:
    stc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Writes an ASCIIZ string to screen, not terminated by stupid "$"
; (edx=ptr to string)
; (edx; esi)
WriteString:
    mov ecx,1024            ;maximum length of characters
	mov edi,edx             ;copy source for string length search
	mov eax,ecx             ;make a copy of max length for later and set al to null
    ;xor al,al              ;;look for null
    cld
    repne scasb             ;search for the end
    ;neg ecx                ;;get negative count
    ;dec ecx                ;;minus the null at the end
	not ecx                 ;negate count and subtract null at the end
	add ecx,eax             ;get length
; (edx=ptr to string, ecx=count)
.OfLength:
    mov ebx,1               ;console output handle
    mov ah,40h              ;DOS: Write to file
	int 21h
    ret

; Writes ASCIIZ string and appends end of line
; (edx=ptr to string)
.WithEol:
    mov ecx,1024            ;maximum length of characters
	mov edi,edx             ;copy source for string length search
	mov eax,ecx             ;make a copy of max length for later and set al to null
    ;xor al,al              ;;look for null
    cld
    repne scasb             ;search for the end
	not ecx                 ;negate count and subtract null at the end
    dec edi
    lea ecx,[ecx+eax+2]     ;get length
    push dword [edi]
    mov dword [edi],120D0Ah
    call .OfLength
    pop dword [edi]
    ret

%if 0
; (eax=number)
.Number:
    call NumToString
    lea edx,[NumToString.Buffer+ecx]
    neg ecx
    add ecx,NumStringMaxLen
    jmp short .OfLength
%endif

.FormattedEnd:
    ret

; (edx=formatted string, dwords Number1, Number2...)
.Formatted:
    lea esi,[esp+4]         ;set number parameter ptr to first one

.FormattedNext:
    ; get length of string part up to either next % or end
    mov ecx,1024|"%"        ;maximum length of characters
	mov edi,edx             ;copy source for string length search
    mov eax,ecx             ;make a copy of max length for later and set al to null
    ;xor al,al              ;look for null
    cld
    repne scasb             ;search for the end
	not ecx                 ;negate count and subtract null at the end
    add ecx,eax             ;part length = previous length - remaining length
    call .OfLength
    mov bl,[edi]
    lea edx,[edi+1]          ;advance to next section of string
    test bl,bl
    je .FormattedEnd

    cmp bl,'s'
    jne .NotString
    push edx
    mov ecx,[edx+4]
    mov edx,[edx]
    call .OfLength
    pop edx
    add edx,byte 8
    jmp .FormattedNext
.NotString:
           
    ; check if number is pointed to in string or on stack
    cmp bl,'p'
    je .FormattedPtr
    mov eax,[esi]
    add esi,byte 4
    jmp short .FormattedStack
.FormattedPtr:
    mov ebx,[edx]               ;indirect pointer
    mov eax,[ebx]
    add edx,byte 5
    mov bl,[edx-1]
.FormattedStack:

    ; determine number type and print accordingly
    push edx                ;save text ptr
    push dword .FormattedNum
    cmp bl,'b'
    je .FormatByte
    cmp bl,'w'
    je .FormatWord
    cmp bl,'d'
    je near NumToString
    cmp bl,'h'
    je .FormatHex
    cmp bl,'%'              ;two % in a row means not a control code
    jne .FormatNone
    push edx
    mov dl,bl
    mov ah,2
    int 21h
    pop edx
.FormatHex:
    mov ebx,16
    mov ecx,NumStringMaxLen
    mov edi,NumToString.Buffer
    jmp NumToString.OfRadix
.FormatByte:
    movzx eax,al
    jmp NumToString
.FormatWord:
    movzx eax,ax
    jmp NumToString
.FormattedNum:
    lea edx,[NumToString.Buffer+ecx]
    neg ecx
    add ecx,NumStringMaxLen
    call .OfLength
.FormatNone:
    pop edx                 ;retrieve text ptr
    jmp .FormattedNext


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Displays an error message, and waits for keypress.
; (edx=ptr to string)
; (!)
DisplayErrMsg:
    call WriteString
.NextKey:
    xor eax,eax                 ;wait for keypress
    int 16h
    mov ah,1                    ;check if any more keypresses remain
    int 16h
    jnz .NextKey                ;if so, waste them
    stc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section .data

Text:
.NoBuffer:      db "Could not allocate low memory disk IO buffer!",0
.ReadingFat:    db "Reading entire file allocation table...",0
.MappingFat:    db "Mapping/tracing FAT entries...",0
.ReadBootSector:db "Reading operating system boot sector...",0
.NoDrives:      db "No drives (did you boot from a CD!?)",0
.Error:         db "Error",0
.Done:          db "Done",0
.ExportFileErr: db "Error creating export file: FILE0001.CHK",0
.MainMenu:      db "Select BIOS drive",13,10
                db "View sectors",13,10
                db "Select os base",13,10
                db "Assume standard floppy",13,10
                db "View fat*",13,10
                db "View file system",13,10
                db "Choose export drive",13,10
                db "Export all fat pieces*",13,10
                db "Export all files",13,10
                db "Export entire media",13,10
                db "Quit",13,10
                db 0
.ExportMedia:   db "This will export a raw sector read of the entire media to a huge file.",13,10
                db "Ensure the destination drive has enough free space to hold it all. Any",13,10
                db "read errors from damaged areas of the disk will be IGNORED and skipped.",13,10
                db "The exported file can then be opened with either a hex editor or MS-DOS",13,10
                db "Edit in binary mode. Then, assuming the files you need are contiguous,",13,10
                db "you may be able to copy selected ranges of data to their own files.",13,10
                db "This will take a while (depending on the disk size and speed), so press",13,10
                db "Escape to abort. Press Enter to proceed...",0
.CurrentThs:    db "Absolute: %p"
                dd Disk.CurSector
                db "d Track: %p"
                dd Disk.Track
                db "d Side: %p"
                dd Disk.Side
                db "d Sector: %p"
                dd Disk.Sector
                db "d              ",13,"%",0
.DriveInfo:     db 10,"Driveúúúú%p"
                dd  Disk.Drive
                db  "b (0=1rst floppy, 1=2nd, 128=1rst hard drive, 129=2nd...)",13,10
                db "Tracksúúú%p"
                dd  Disk.Tracks
                db  "d (1-1024)",13,10
                db "Sidesúúúú%p"
                dd  Disk.Sides
                db  "d (1-255)",13,10
                db "Sectorsúú%p"
                dd  Disk.Sectors
                db  "d (1-63)",13,10
                db "Totalúúúú%p"
                dd Disk.TotalSectors
                db "d sectors",13,10
                db "%",0
.BootSectorInfo:db 10,"OEM Nameúúúúúúúúúúúúú%s"
                dd  BootSector.OemName,8
                db  13,10
                ;db "Volume Labelúúúúúúúúú%s"
                ;dd  BootSector.VolumeLabel,11
                ;db  13,10
                db "Serial numberúúúúúúúú%p"
                dd  BootSector.SerialNumber
                db  "h",13,10
                db "Total sectorsúúúúúúúú%p"
                dd  Disk.OsSectors
                db  "d",13,10
                db "Reserved sectorsúúúúú%p"
                dd  BootSector.ReserveSectors
                db  "w",13,10
                db "Hidden sectorsúúúúúúú%p"
                dd  BootSector.HiddenSectors
                db  "w",13,10
                db "Bytes per sectorúúúúú%p"
                dd  Disk.SectorBytes
                db  "d",13,10
                db "Sectors per clusterúú%p"
                dd  Disk.ClusterSectors
                db  "d",13,10
                db "Number of FATsúúúúúúú%p"
                dd  BootSector.NumberFats
                db  "b",13,10
                db "FAT sectorsúúúúúúúúúú%p"
                dd Disk.FatSectors
                db  "d",13,10
                db "Root entriesúúúúúúúúú%p"
                dd  Disk.RootEntries
                db  "d",13,10
                db "Sectors per trackúúúú%p"
                dd  BootSector.TrackSectors
                db  "w",13,10
                db "Sidesúúúúúúúúúúúúúúúú%p"
                dd  BootSector.Heads
                db  "w",13,10
                db 10
                db "OS base sectorúúúúúúú%p"
                dd  Disk.OsSector
                db  "d",13,10
                db "Fat base sectorúúúúúú%p"
                dd  Disk.FatSector
                db  "d",13,10
                db "Root base sectorúúúúú%p"
                dd  Disk.RootSector
                db  "d",13,10
                db "Data base sectorúúúúú%p"
                dd  Disk.DataSector
                db  "d",13,10
                db "Total data sectorsúúú%p"
                dd  Disk.DataSectors
                db  "d",13,10
                db "Total clustersúúúúúúú%p"
                dd  Disk.Clusters
                db  "d",13,10
                db "%",0
.ExportFileName:db "FILE0001.CHK",0
