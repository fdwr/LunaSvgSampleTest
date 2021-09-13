;Called by Qbasic to read absolute disk sectors

;Written on 4-98

;Accepts the parameters
;  drive%, startsect&, sectors%, DiskBuffer&, readerror%
;  10      12          16        18           22
;
;  Drive is if of course an integer number of the drive you want to read.
;  Startsect is the first sector to start reading from.
;  Sectors is the total integer number of sectors to be read.
;  DiskBuffer& is the memory address of the destination to write disk data.
;  It is a far address including both a segment and offset in that segment
;  Error is the word that recieves any errors from trying to read a certain
;  disk. Qbasic can read this integer to tell whether or not the call was
;  successful; if it was not, then the DiskBuffer() data is not valid.
;  Most common error would be error 2 in lower eight bits, disk not ready.
;  It means you have selected a disk that does not exist. (?)

; The drives are numbered just as they are lettered A,B,C,D is 0,1,2,3.
; So if you wanted to read from the hard disk, it would be drive 2;
; a floppy disk (A:) would be drive 0, and if you had a RAM disk which was
; letter E (could also be D?), the number would be 4. For some reason, it
; seems CD-ROM drives can not be read; don't know why.

; the starting sector is a long integer (to handle today's huge disks)
; the number of sectors to be read from the disk is a short integer since you
; can not read more than 64k anyway

        BITS 16
        ORG 0
       
        push ds         ;save all necessary segments and base pointer to the
        push es         ;stack so that when we're done, we can restore them
        push bp
        mov bp,sp       ;copy stack pointer to base pointer to set up stack
                        ;for positive ofset references to all parameters
        jmp endcode
	mov al,[bp+10]  ;load the drive number into al, hard disk or floppy
        mov cx,0FFFFh                   ;tell DOS to use a control block
        mov eax,[bp+12]                 ;read startsect&
        mov [DOScontrolblock],eax       ;write it into control block (+0)
        mov ax,[bp+16]                  ;read sectors%
        mov [DOScontrolblock+4],ax      ;write it into control block (+4)
        mov eax,[bp+18]                 ;read diskbuffer&
        mov [DOScontrolblock+6],eax     ;write it into control block (+6)
        mov bx,DOScontrolblock          ;set bx to location of control block
	
        int 25h          ;call DOS absolute disk read function

        jc error        ;jump past next instruction if carry flag is set (error)
        xor ax,ax       ;set readerror% to zero
error                   ;jump to here if there was an error (carry flag tells)
        mov bx,[bp+22]  ;get location of readerror% variable
        mov [bx],ax     ;move error into memory at readerror%
        popf            ;pull flags which DOS was so kind to leave for us (??)

endcode pop bp          ;restore segments and base pointer for Qbasic
        pop es          ;unless you want Qb to crash
        pop ds

        retf 14         ;return far and reduce stack by the
                        ;size of stack passed on to it
       
        SECTION .bss    ;start a new section for temporary DOS control block

DOScontrolblock ;Total size of control block is 10 bytes
        resd 1  ;+0 Long integer for Starting sector
        resw 1  ;+4 Short Integer Number of sectors to read
        resd 1  ;+6 Long for Disk data destination, where to put the disk data

