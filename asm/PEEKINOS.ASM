; (very unfinished!)
; Enters protected mode ok (yeah, linear memory!), but reboots the computer
; immediately upon any attempt to set the IDT (so I simply never do so) and
; also freezes when trying to return to real mode.
; 
;
; This little demo simply illustrates how to enter protected mode from the
; computer's initial boot. It is nowhere near an operating system in itself,
; but could be expanded to become the primer of one.
;
; This is called from the boot sector. The segment and stack registers have
; already been set up for it, but it is up to this program to enter protected
; mode. I must say that it is ridiculous how much setup is involved simply to
; enter protected mode. Personally, I wish all modern PC's would automatically
; boot in 32bit, and that 16bit code was only virtual.
;
; Files:
;   Myboot.asm      boot sector code and file system information
;   PeekinOs.asm    protected mode demo code
;
; Compiling:
;   nasm -f bin peekinos.asm -o peekinos.bin  (compile to binary image)
;   copy peekinos.bin a:                      (copy to floppy)
;
; Entry conditions:
;   ss:sp   9000:FE00 purposely set up high in memory
;   cs:ip   0000:0800 purposely set up low in memory
;   ds      0
;   es      0
;
;   The stack is set high so that as much data can be loaded in low memory as
;   possible. Of course, it is very unlikely the two would ever meet. The
;   program would have to be over 540k large, and not even the most bloated
;   OS cores are that large.
;
;   The code and data are loaded low so that they have easy access to the
;   BIOS information area and interrupt table.

org 800h

section .data
DataBase        equ $
section .bss
BssBase         equ $
section .text
CodeBase        equ $
CodeOffset      equ 0;800

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Eflags:
.CF     equ 1<<0    ;carry
.PF     equ 1<<2    ;parity
.AF     equ 1<<4    ;auxilliary carry
.ZF     equ 1<<6    ;zero
.SF     equ 1<<7    ;sign
.TF     equ 1<<8    ;trap
.IF     equ 1<<9    ;interrupt enable
.DF     equ 1<<10   ;direction
.OF     equ 1<<11   ;overflow
.IOPL   equ 3<<12   ;i/o privilege level
.NT     equ 1<<14   ;nested task
.RF     equ 1<<16   ;resume
.VM     equ 1<<17   ;virtual mode
.AC     equ 1<<18
.VIF    equ 1<<19   ;virtual interrupt
.VIP    equ 1<<20   ;virtual interrupt pending
.ID     equ 1<<21   ;identification

Cr0Flags:
.PE     equ 1<<0    ;protected mode enable
.MP     equ 1<<1    ;math coprocessor present
.EM     equ 1<<2    ;FPU emulation
.TS     equ 1<<3    ;task switched
.ET     equ 1<<4    ;FPU extension type
.NE     equ 1<<5
.WP     equ 1<<16
.AM     equ 1<<18
.NW     equ 1<<29
.CD     equ 1<<30
.PG     equ 1<<31   ;paging

; Some 'duplicate' values serve different purposes
; depending on the type of selector/gate
Selector:
.A      equ 1<<8    ;accessed
.Type   equ 15<<8
.R      equ 1<<9    ;readable code segment
.W      equ 1<<9    ;writable data segment
.E      equ 1<<10   ;expansion direction
.C      equ 1<<10   ;conforming
.X      equ 1<<11   ;executable
.DG     equ 1<<11   ;default gate size (16 if clear / 32 if set)
.S      equ 1<<12   ;system
.DPL    equ 3<<13   ;descriptor privilege level
.P      equ 1<<15   ;present
.AVL    equ 1<<20   ;available
.DB     equ 1<<22   ;default bits (16 if clear / 32 if set)
.G      equ 1<<23   ;granularity

%if 0
                           DATA SEGMENT DESCRIPTOR

  31                23                15                7               0
 ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÑÍÑÍÑÍÑÍÍÍÍÍÍÍÍÍØÍÑÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
 º±±±±±±±±±±±±±±±±±³±³±³±³A³ LIMIT   ³±³     ³  TYPE   ³±±±±±±±±±±±±±±±±±º
 º±±±BASE 31..24±±±³G³B³0³V³ 19..16  ³P³ DPL ³         ³±±±BASE 23..16±±±º 4
 º±±±±±±±±±±±±±±±±±³±³±³±³L³         ³±³     ³1³0³E³W³A³±±±±±±±±±±±±±±±±±º
 ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÁÄÁÄÁÄÁÄÄÄÄÄÄÄÄÄÅÄÁÄÄÄÄÄÁÄÁÄÁÄÁÄÁÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶
 º±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±³                                   º
 º±±±±±±±±SEGMENT BASE 15..0±±±±±±±±±³        SEGMENT LIMIT 15..0        º 0
 º±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±³                                   º
 ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

                        EXECUTABLE SEGMENT DESCRIPTOR

  31                23                15                7               0
 ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÑÍÑÍÑÍÑÍÍÍÍÍÍÍÍÍØÍÑÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
 º±±±±±±±±±±±±±±±±±³±³±³±³A³ LIMIT   ³±³     ³  TYPE   ³±±±±±±±±±±±±±±±±±º
 º±±±BASE 31..24±±±³G³D³0³V³ 19..16  ³P³ DPL ³         ³±±±BASE 23..16±±±º 4
 º±±±±±±±±±±±±±±±±±³±³±³±³L³         ³±³     ³1³1³C³R³A³±±±±±±±±±±±±±±±±±º
 ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÁÄÁÄÁÄÁÄÄÄÄÄÄÄÄÄÅÄÁÄÄÄÄÄÁÄÁÄÁÄÁÄÁÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶
 º±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±³                                   º
 º±±±±±±±±SEGMENT BASE 15..0±±±±±±±±±³        SEGMENT LIMIT 15..0        º 0
 º±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±³                                   º
 ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

                         SYSTEM SEGMENT DESCRIPTOR

  31                23                15                7               0
 ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÑÍÑÍÑÍÑÍÍÍÍÍÍÍÍÍØÍÑÍÍÍÍÍÑÍÑÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
 º±±±±±±±±±±±±±±±±±³±³±³±³A³ LIMIT   ³±³     ³ ³       ³±±±±±±±±±±±±±±±±±º
 º±±±BASE 31..24±±±³G³X³0³V³ 19..16  ³P³ DPL ³0³ TYPE  ³±±±BASE 23..16±±±º 4
 º±±±±±±±±±±±±±±±±±³±³±³±³L³         ³±³     ³ ³       ³±±±±±±±±±±±±±±±±±º
 ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÁÄÁÄÁÄÁÄÄÄÄÄÄÄÄÄÅÄÁÄÄÄÄÄÁÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶
 º±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±³                                   º
 º±±±±±±±±SEGMENT BASE 15..0±±±±±±±±±³       SEGMENT LIMIT 15..0         º 0
 º±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±³                                   º
 ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼


        A   - ACCESSED                              E   - EXPAND-DOWN
        AVL - AVAILABLE FOR PROGRAMMERS USE         G   - GRANULARITY
        B   - BIG                                   P   - SEGMENT PRESENT
        C   - CONFORMING                            R   - READABLE
        D   - DEFAULT                               W   - WRITABLE
        DPL - DESCRIPTOR PRIVILEGE LEVEL


And now for what would have just made TOO much sense:

  31              24                16                8                0
 ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÑÍÑÍÑÍÑÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
 º±³     ³  TYPE   ³±³±³±³±³A³                                           º
 ºP³ DPL ³         ³±³G³B³0³V³        SEGMENT LIMIT 19..0                º 4
 º±³     ³1³0³E³W³A³±³±³±³±³L³                                           º
 ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÁÄÁÄÁÄÁÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶
 º                                                                       º
 º                           SEGMENT BASE 31..0                          º 0
 º                                                                       º
 ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

%endif

;(base, limit, flags)
%macro DefSelector 3
    ; this is retarded!
    ; why did Intel scramble the bits like this?
    ; the really sad thing - people with Bachelor's degrees thought this up
    dw %2 & 0FFFFh
    dw %1 & 0FFFFh
    dd %3 | ((%1>>16)&255) | (%1 & 0FF000000h) | (%2 & 0F0000h)
%endmacro

;(routine name, routine selector, flags)
%macro DefInterruptGate 3
    ; why did Intel scramble the bits like this?
    dw %1 & 0FFFFh
    dw %2
    dd %3 | (%1 & 0FFFF0000h) 
%endmacro



;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; enter protected mode
; grab keyboard int
; grab timer int
; set timer interval

bits 16
SetupProtMode:

    ; ensure flags are set right (in both Eflags and control register 0)
    pushfd
    pop eax
    and eax,~(Eflags.IF|Eflags.TF|Eflags.NT|Eflags.RF|Eflags.VM|Eflags.AC|Eflags.VIF|Eflags.VIP|Eflags.DF)
    or eax,Eflags.IOPL          ;give less privileged ring i/o rights
    push eax
    popfd
    mov eax,cr0
    and eax,~(Cr0Flags.PG|Cr0Flags.CD|Cr0Flags.NW|Cr0Flags.AM|Cr0Flags.WP|Cr0Flags.NE|Cr0Flags.TS|Cr0Flags.EM|Cr0Flags.MP)
    mov cr0,eax

    ; set up interrupt table
    cld
    mov si,IdtRoutines
    les di,[IdtSeg]
    jmp short .FirstInt
.NextInt:
    sub si,byte 8               ;compensate for movsd
.CopyInt:
    movsd                       ;transfer first dword of descriptor
    movsd
    dec cx
    jg .NextInt
.FirstInt:
    mov cx,[si]                 ;get repeat count
    add si,byte 4               ;skip count
    test cx,cx                  ;loop until count=0
    jnz .CopyInt

    ; don't bother creating an unnecessary task state because this simple
    ; program doesn't use multitasking

    ; enter protected mode
    ; (eax=CR0)
    cli                         ;disable interrupts before entering prot mode
    lgdt [GdtPtr]               ;load global descriptor table
    inc ax                      ;set bit 0 PE (protected mode)
    ;or eax,Cr0Flags.PE
    mov bx,GDT.Data             ;setup bx for multiple segment set after jump
    mov cr0,eax                 ;enable protected mode

    ; only partially in protected mode
    ; Even though the PE bit has been set, the CPU is STILL executing as if
    ; it were in 16bit real mode until the far jump is taken.
    ; Personally verified this by setting ecx=0FFFFh and then incrementing.
    ; Instead of being 10000h, as it should have been, the lower word wrapped
    ; around to 0.
    jmp dword GDT.Code:EnteredProtMode ;serialize instruction cache

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
align 2
IdtSeg:
    dw 0                        ;always paragraph aligned
    dw ((IDT-BssBase)+BssOffset)/16

GdtPtr:
    dw 4*8-1                    ;limit is in bytes (#descriptors * 8 - 1)
    dd GDT                      ;linear byte offset

IdtPtr:
    dw 256*8-1
    dd IDT

RmIdtPtr:
    dw 256*8-1
    dd 0

align 8
GDT:
.Null equ 0
    ; selector 0 in GDT must ALWAYS be null
    ; the flags I set are actually irrelevant, ignored by the CPU
    DefSelector 0,0,        Selector.S|Selector.DPL|Selector.P|Selector.DB|Selector.R|Selector.A

.Code equ 8
    ; selector for code (0-4gb)
    ; executable, nonconforming, 4k granularity, present, 32bit segment, readable, accessed
    DefSelector 0, 0FFFFFh, Selector.S|Selector.G|Selector.DB|Selector.P|Selector.X|Selector.R|Selector.A

.Data equ 16
    ; data selector (0-4gb) readable/writeable, also used for stack
    ; data, expand up, 4k granularity, ring 3 default privilege level, present, 32bit segment, readable, accessed
    DefSelector 0, 0FFFFFh, Selector.S|Selector.G|Selector.DB|Selector.P|           Selector.W|Selector.A

.Real equ 24
    ; selector for real mode code
    ; executable, byte granularity, present, 16bit segment, readable, accessed
    DefSelector 0, 00FFFFh, Selector.S|                       Selector.P|Selector.X|Selector.R|Selector.A

IdtRoutines:
    dd 256
    DefInterruptGate IntDoNada-CodeBase,GDT.Code,Selector.P|Selector.DG|Selector.R|Selector.C
    dd 0

section .bss
alignb 16
IDT:    resb 256*8
section .text

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
bits 32
; (bx=GDT.Data)
EnteredProtMode:
    ; reload segment registers (base 0, limit 4gb)
    ; since they still contain their contents from realmode
    mov ss,ebx
    mov esp,0A0000h-4           ;set stack ptr just below video memory
    mov ds,ebx
    mov es,ebx
    mov fs,ebx
    mov gs,ebx

    ; load interrupt table
    ;lidt [IdtPtr]
    ;sti

    ; don't bother with io map since all hardware should be accessible

    ; change PIT's silly value of 18.2 ticks to a more sensible 30fps
    ;mov cx,39600
    ;call SetPitRate

    ;jmp Main

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; decompress bitmaps
; set video mode
; do
;   render scene
; loop until escape
; reboot
;
Main:

.Loop:
    inc dword [0B8000h]
    in al,60h
    cmp al,1
    jne .Loop

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; There a few ways to reboot a computer. Besides the more obvious reset
; button and Ctrl+Alt+Del keypress, you can also execute the bootstrap loader
; or long jump to the BIOS ROM (as if the PC were reset). Depending on the
; method taken (soft/warm/cold), the BIOS will either do a full test or skip
; a few of them. Executing the bootstrap loader is the gentlest of them all,
; as it does not clear memory, retest RAM, blank the screen, or reset
; hardware. Unfortunately, it isn't always dependable.
Reboot:

    ; restore default rate of 18.2065hz
    ;xor cx,cx
    ;call SetPitRate

    ; return from protected mode to real mode
    mov dword [0472h],1234h     ;indicate to BIOS to do soft reset
    mov eax,cr0
    ;and eax,~Cr0Flags.PE
    dec eax                     ;clear bit 0 (protected mode)
    cli
    mov cr0,eax
    jmp word GDT.Real:ExitedProtMode ;serialize instruction cache

ExitedProtMode:
bits 16
    mov ax,cs
    mov ss,ax
    mov sp,0FFF0h
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    ;lidt [RmIdtPtr]
    jmp word 0FFFFh:0   ;jump BIOS ROM for reset
bits 32

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetPitRate:
    cli                 ;don't want any interrupt to mess this up below
    mov al,00110100b    ;(00:11:010:0) set counter 0, lsb/msb, mode 2, binary
    out 43h,al
    in al,61h           ;force i/o delay
    mov al,cl
    out 40h,al          ;write counter low byte
    in al,61h           ;force i/o delay
    mov al,ch
    out 40h,al          ;write counter high byte
    sti
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
IntDoNada:
    push eax
    mov al,20h                  ;nonspecific EOI
    out 20h,al                  ;acknowledge IRQ to PIC
    pop eax
    iret
IntDeadEnd:                     ;infinite loop is safety net
    hlt                         ; to catch fatal errors
    jmp short IntDeadEnd


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;WaitOnKey:
;.ShiftPressed:
;    in al,60h
;    cmp al,54
;    jne .ShiftPressed
;.ShiftReleased:
;    in al,60h
;    cmp al,182
;    jne .ShiftReleased
;    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section .data
Text:
.Status:    db "System loaded!",13,10
            db "Press Escape once bored and ready to reboot",13,10,10,10

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; these declarations are necessary because of Nasm modular compilation
; otherwise, it won't allow arithmetic with offsets
section .text
align 4
DataOffset      equ CodeOffset+($-CodeBase)
section .data
align 4
BssOffset       equ DataOffset+($-DataBase)
