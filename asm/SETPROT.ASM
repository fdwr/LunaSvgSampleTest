BITS 16

;section .text

Eflags:
.CF     equ 1<<0
.PF     equ 1<<2
.AF     equ 1<<4
.ZF     equ 1<<6
.SF     equ 1<<7
.TF     equ 1<<8
.IF     equ 1<<9
.DF     equ 1<<10
.OF     equ 1<<11
.IOPL   equ 3<<12
.NT     equ 1<<14
.RF     equ 1<<16
.VM     equ 1<<17
.AC     equ 1<<18
.VIF    equ 1<<19
.VIP    equ 1<<20
.ID     equ 1<<21

Cr0Flags:
.PE     equ 1<<0
.MP     equ 1<<1
.EM     equ 1<<2
.TS     equ 1<<3
.ET     equ 1<<4
.NE     equ 1<<5
.WP     equ 1<<16
.AM     equ 1<<18
.NW     equ 1<<29
.CD     equ 1<<30
.PG     equ 1<<31

Selector:           ;(yes, some of these have duplicate values)
.A      equ 1<<8    ;accessed
.Type   equ 15<<8
.R      equ 1<<9    ;readable code segment
.W      equ 1<<9    ;writable data segment
.X      equ 1<<11   ;executable
.S      equ 1<<12   ;system
.E      equ 1<<10   ;expansion direction
.C      equ 1<<10   ;conforming
.DPL    equ 3<<13   ;descriptor privilege level
.P      equ 1<<15   ;present
.AVL    equ 1<<20   ;available
.DB     equ 1<<22   ;default bits (16 if clear / 32 if set)
.G      equ 1<<23   ;granularity

%macro ShortDelay 0
    xchg al,cl
    xor al,al
    out 70h,al
%%DelayZero:
    in al,71h
    test al,1
    jz %%DelayZero
    xor al,al
    out 70h,al
%%DelayNz:
    in al,71h
    test al,1
    jnz %%DelayNz
    xchg al,cl
%endmacro

%macro Nops 1
times %1 nop
%endmacro

org 100h

    mov ax,0B800h
    mov es,ax
    mov [es:0],byte '0'
    ShortDelay

    ; ensure flags are set right
    pushfd
    pop eax
    and eax,~(Eflags.TF|Eflags.NT|Eflags.RF|Eflags.VM|Eflags.AC|Eflags.VIF|Eflags.VIP|Eflags.DF)
    or eax,Eflags.IOPL
    push eax
    popfd
    mov eax,cr0
    and eax,~(Cr0Flags.PG|Cr0Flags.CD|Cr0Flags.NW|Cr0Flags.AM|Cr0Flags.WP|Cr0Flags.NE|Cr0Flags.TS|Cr0Flags.EM|Cr0Flags.MP)
    mov cr0,eax

    ; load GDT
    xor ebx,ebx
    mov bx,ds
    shl ebx,4
    add [GdtPtr+2],ebx
    add [IdtPtr+2],ebx
    lgdt [GdtPtr]
    ;lidt [IdtPtr] ;freezes my PC!?
    Nops 6

    mov [es:2],byte '1'
    ShortDelay

    ; set jump points, both to protected mode, and returning from
    add [EnterProtMode-6],ebx
    add [Enter16bit-6],ebx
    mov [EnterRealMode-2],cs
    Nops 6

    ; (eax=CR0, ebx=program base ptr)
    mov edx,GDT.Data
    mov edi,0B8000h
    xor ecx,ecx
    ;mov eax,cr0
    mov ebx,eax
    inc eax                     ;set PE
    Nops 6

    mov [es:4],byte '2'
    ShortDelay

    cli
    push ds
    mov cr0,eax
    Nops 6

    ;jmp short EnterProtMode
    jmp dword GDT.Code:EnterProtMode
    ;jmp dword 8:EnterProtMode
EnterProtMode:

    ; even though the PE bit has been set, the CPU is STILL executing as if
    ; it were in real mode until the far jump is taken. personally verified
    ; this by setting ecx=0FFFFh and then incrementing. instead of 10000h as
    ; it should have been, the lower word wrapped around to 0.
bits 32
    Nops 6
    ;lar ecx,edx
    Nops 6
    mov ds,dx
    mov [dword 0B8006h],byte '3'
    Nops 6
    ShortDelay
    ;mov [edi],eax
    ;mov ecx,[dword edi]
    Nops 6
    jmp dword GDT.Real:Enter16bit
Enter16bit:

;bits 16
bits 32
    Nops 6
    mov [dword 0B8008h],byte '4'
    Nops 6
    ShortDelay
    Nops 6

    mov cr0,ebx
    Nops 6
    mov [word es:10],byte '5'
    Nops 6
    ShortDelay
    Nops 6
    jmp word 0:EnterRealMode
EnterRealMode:

bits 16
    Nops 6
    mov [es:12],byte '6'
    Nops 6
    ShortDelay
    Nops 6

    pop ds
    sti


    call PrintNum
    ;mov ah,2
    mov dl,'<'
    int 21h
    mov dl,10
    int 21h

    mov ax,4C00h
    int 21h


; (ecx=number) (ah=2)
PrintNum:
    mov ah,2
    mov dh,8
.Next:
    rol ecx,4
    mov dl,cl
    and dl,15
    cmp dl,10
    jb .NotLetter
    add dl,'A'-'0'-10
.NotLetter:
    add dl,'0'
    int 21h
    dec dh
    jg .Next
.End:
    ret

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
    ; this is retarded!
    ; why did Intel scramble the bits like this?
    ; the really sad thing - people with Bachelor's degrees thought this up
    dw %1 & 0FFFFh
    dw %2
    dd %3 | (%1 & 0FFFF0000h)
%endmacro


align 2
GdtPtr:
    dw 4*8-1
    dd GDT

IdtPtr:
    dw 256*8-1
    dd IDT

align 8
GDT:
.Null equ 0
    ; selector 0 in GDT must ALWAYS be null
    ; the flags I set are actually irrelevant, ignored by the CPU
    DefSelector 0,0,Selector.S|Selector.DPL|Selector.P|Selector.DB|Selector.R|Selector.A

.Code equ 8
    ; selector for code (0-4gb)
    ; executable, nonconforming, 4k granularity, present, 32bit segment, readable, accessed
    DefSelector 0, 0FFFFFh, Selector.G|Selector.DB|Selector.P|Selector.S|Selector.X|Selector.R|Selector.A

.Data equ 16
    ; data selector (0-4gb) readable/writeable, also used for stack
    ; data, expand up, 4k granularity, ring 3 default privilege level, present, 32bit segment, readable, accessed
    DefSelector 0, 0FFFFFh, Selector.G|Selector.DB|Selector.P|Selector.S|            Selector.W|Selector.A

.Real equ 24
    ; selector for real mode code
    ; executable, byte granularity, present, 16bit segment, readable, accessed
    DefSelector 0, 0FFFFFh, Selector.DB|Selector.P|Selector.S|Selector.X|Selector.R|Selector.A

%if 0
                           DATA SEGMENT DESCRIPTOR

  31                23                15                7               0
 ษอออออออออออออออออุอัอัอัอัอออออออุอัอออัอออออออออุอออออออออออออออออป
 บฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑณฑณฑณฑณAณ LIMIT ณฑณ   ณ  TYPE   ณฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑบ
 บฑฑฑBASE 31..24ฑฑฑณGณBณ0ณVณ 19..16ณPณDPLณ         ณฑฑฑBASE 23..16ฑฑฑบ 4
 บฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑณฑณฑณฑณLณ       ณฑณ   ณ1ณ0ณEณWณAณฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑบ
 วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤมฤมฤมฤมฤฤฤฤฤฤฤลฤมฤฤฤมฤมฤมฤมฤมฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ
 บฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑณ                                 บ
 บฑฑฑฑฑฑฑฑSEGMENT BASE 15..0ฑฑฑฑฑฑฑณ      SEGMENT LIMIT 15..0        บ 0
 บฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑณ                                 บ
 ศอออออออออออออออออุอออออออออออออออุอออออออออออออออุอออออออออออออออออผ

                        EXECUTABLE SEGMENT DESCRIPTOR

  31                23              15              7               0
 ษอออออออออออออออออุอัอัอัอัอออออออุอัอออัอออออออออุอออออออออออออออออป
 บฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑณฑณฑณฑณAณ LIMIT ณฑณ   ณ  TYPE   ณฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑบ
 บฑฑฑBASE 31..24ฑฑฑณGณDณ0ณVณ 19..16ณPณDPLณ         ณฑฑฑBASE 23..16ฑฑฑบ 4
 บฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑณฑณฑณฑณLณ       ณฑณ   ณ1ณ1ณCณRณAณฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑบ
 วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤมฤมฤมฤมฤฤฤฤฤฤฤลฤมฤฤฤมฤมฤมฤมฤมฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ
 บฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑณ                                 บ
 บฑฑฑฑฑฑฑฑSEGMENT BASE 15..0ฑฑฑฑฑฑฑณ      SEGMENT LIMIT 15..0        บ 0
 บฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑณ                                 บ
 ศอออออออออออออออออุอออออออออออออออุอออออออออออออออุอออออออออออออออออผ

!! there is an error in the INTEL 80386 PROGRAMMER'S REFERENCE MANUAL 1986
   bit 11 is SET (not clear) for code segments
   twas the cause of some confusing grief...
%endif

section .bss
alignb 8
IDT:    resb 256*8
section .text
