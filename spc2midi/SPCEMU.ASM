; Spc2Midi, SPC Emulation - by Peekin
;   There are still several instructions that remain unverified, simply
;   because I have not come accross a game that uses them. Every game I have
;   tried though works fine, including Mario World, Zelda, DKC, DKC2,
;   ChronoTrigger, Metroid 3, Mario RPG, Actraiser, StarFox, Secret of Mana...
;
;   The emulation code is mostly self contained, except for a global
;   constants defined in the main source and the DSP register functions.
;
;   .Init - call after loading a song or when completely restarting one
;   .Start - starts emulating for a period of time
;   .Continue - continues where emulation last left off. Do not call directly!
;   .DisAsm - disassembles for a period of time
;   .ReadByte/.ReadByteDp - reads a byte from RAM/ERAM/Register
;   .WriteByte/.WriteByteDp - write a byte to RAM/ERAM/Register
;   .UnverifiedOpcode - called when unverfied opcode encountered
;   .PrintBreak - prints address, program counter, and time
;
; To do:
;   reverify opcodes once more
;   simpify movzx's to mov where applicable
;   add ENDX detection just in case some game ever actually depends on it
;   check what happens on div ax,cl when ax is greater than 255
;
; Done:
;   fixed stupid typo, reading from SpcRam instead of DspRam. Didn't affect
;    any SPCs of mine except one because most games don't read from the DSP
;   found Mario RPG reads DSP register 7Dh for timing (Child Playing)
;   added data port hacks for "Sailor Moon RPG" and "Super Puyo 2" but they
;    are not yet identified and applied
;   learned SWROTJedi messes with the source directory while playing :/
;   wraps cycle counter if becomes signed, allowing songs >= 28 minutes.
;   finally figured out why some games set a key's initial pitch to 0. they
;    are setting up a huge pitch slide (Sailor Moon fighting, Macross).
;   found ChronoTrigger tries to turn off voices already off (causing problems for playing backwards)
;   verified TCALL works fine in Terranigma, and PCALL in Rudora No Hihou
;   forced kof first when ChronoTrigger turned on keys that were already on (so arpeggio in battle music would play)
;   found Mario RPG sometimes turns notes on again without turning them off first
;   inverted carry for CMPW after finding it being set in Snes9x
;   fixed sign and zero flag not being set on ROL/ROR
;   set carry for SUBW
;   found ChronoTrigger and Vortex use MOVW to registers, can't use that optimization
;   found Mario RPG uses all the timers (not just timer 0 like most games)
;   inverted carry after SBC too (silly cpu)
;   optimized dpo2 addressing
;   found DKC2 and Macross increment the DSP reg F2
;   verified that all addressing modes point correctly
;   inverted carry on all CMP's (odd)
;   corrected operand order of all dp,#imm to #imm,dp
;   changed all (d),(s) to (s),(d)
;   checked movw incw decw addw subw cmpw
;   checked that every value load has a flag test
;   checked daa das
;
; Observations: (notes to self)
;   DKC and KI constantly read EON. seems not to affect anything
;   Jurassic Park constantly reads the ENVX register, plays fine though
;   "Tenchi Muyo" "SMet3" "Mario Allstars" "Hoshi No Kirby" "SBlz" read EDL
;   SMW2 and SMPRG read EDL only once or twice
;   DOOM reads a ton of DSP registers
;   BOF1 constantly reads KON
;   Cybernator constantly reads voice volumes
;   Nosferatu constatly reads ENVX
;   Princess Maker constatly reads ENDX
;
; Questions:
;   when moving an immediate value into a register, is it really necessary
;    to set the flags?
;   must counters be limited to lowest four bits? it seems to be fine allowing
;    a full eight.
;   how is the halfcarry set in division/subw/addw?
;   how should half-carry be set on sbc?
;   does the RET command require the stack wrap between bytes
;
;
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Global SPC memory variables
;컴컴컴컴컴컴컴컴컴�
section bss
alignb 4

Rams:               ;FileRams must exactly match Rams!
SpcRam:             resb 65536
DspRam:             resb 128
SpcEram:            resb 64
RamsSizeOf          equ $-SpcRam

FileRams:           ;FileRams must exactly match Rams!
FileSpcRam:         resb 65536
FileDspRam:         resb 128
FileSpcEram:        resb 64

DspRamCopy:         resb 128
FileSpcRegs:        resb 48 ;this does not need a copy


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; SPC emulation constants
;컴컴컴컴컴컴컴컴컴�

%ifdef debug
  %define SpcEmuDebugResponse     call .UnverifiedOpcode
%else
  %define SpcEmuDebugResponse
%endif

; remapped SPC flags while in emulation
; neither completely SPC or completely PC but a combination of both
SpcFlag:        ;                                      <SPC>   <PC>
.C      equ 1   ; Carry                                 1       1
.V      equ 2   ; Overflow                              64      2048
.I      equ 4   ; Indirect master enable flag ??        4       --
.B      equ 8   ; Break, indicates interrupt occurred   16      --
.H      equ 16  ; Half-carry                            8       16
.P      equ 32  ; Direct page                           32      --
.Z      equ 64  ; Zero                                  2       64
.N      equ 128 ; Negative (sign)                       128     128
.NZ     equ 192
.NZC    equ 193
.NHZ    equ 208
.NVHZ   equ 210
.NHZC   equ 209
.NVHZC  equ 211
.mNZ    equ (.NZ    ^ -65281) | (.NZ  <<8) ;flags mask for MOV and such
.mNZC   equ (.NZC   ^ -65281) | (.NZC <<8)
.mNHZC  equ (.NHZC  ^ -65281) | (.NHZC<<8)
.mNVHZ  equ (.NVHZ  ^ -65281) | (.NHZ <<8)
.mNVHZC equ (.NVHZC ^ -65281) | (.NHZC<<8)
; ~NZ           11111100 11111111 11111111 11111111     clear N and Z in current flags
; & -65281      11111100 00000000 11111111 11111111     clear upper bits 8-15
; | NZ          11111100 00000011 11111111 11111111     clear all except N and Z in new flags
;
; ~NVHZC        00110100 11111111 11111111 11111111     clear NVHZC in current flags
; & -65281      00110100 00000000 11111111 11111111     clear upper bits 8-15
; | NHZC        00110100 10001011 11111111 11111111     clear all except NHZC in new flags

; true flags in the x86 CPU
PcFlag:
.C      equ 1   ; Carry (set when result exceeds maximum or underceeds zero)
.U1     equ 2   ; Undefined one, default on
.P      equ 4   ; Parity (set on odd number of bits)
.U2     equ 8   ; Undefined two, default off
.A      equ 16  ; Auxilliary Carry (set on carry from lowest nibble to higher)
.U3     equ 32  ; Undefined three, default off (this should be overflow!)
.Z      equ 64  ; Zero (set on all bits being off)
.S      equ 128 ; Sign (set on msbit)
.O      equ 2048; Overflow (so stupid they put it in the upper 8 bits)

; true flags in the SPC700 processor
TrueSpcFlag:
.C      equ 1   ; Carry
.Z      equ 2   ; Zero
.I      equ 4   ; Indirect master enable flag ??
.H      equ 8   ; Half-carry
.B      equ 16  ; Break ??
.P      equ 32  ; Direct page
.V      equ 64  ; Overflow
.N      equ 128 ; Negative (sign)

; Memory addresses F0-FF
SpcReg:
;Unused 1               equ 0F0h  ???
.Control                equ 0F1h; w     timer start/stop, port clear
  .Control_St0          equ 1   ;       timers are active when 1
  .Control_St1          equ 2   ;       paused when 0
  .Control_St2          equ 4
  .Control_Pc01         equ 16  ;       clear ports 0 & 1
  .Control_Pc23         equ 32  ;       clear ports 2 & 3
.DspAdr                 equ 0F2h; rw    selected register of dsp to access (address)
.DspData                equ 0F3h; rw    data sent to selected DSP register
.DataPort0              equ 0F4h; rw    external communication IO ports
.DataPort1              equ 0F5h
.DataPort2              equ 0F6h
.DataPort3              equ 0F7h
;Unused 2               equ 0F8h  ???
;Unused 3               equ 0F9h  ???
.Timer0                 equ 0FAh; w     timer count, 8KHz, 0-255
.Timer1                 equ 0FBh;                    8KHz
.Timer2                 equ 0FCh;                    64KHz
.Count0                 equ 0FDh; r     4bit counter, resets zero on read
.Count1                 equ 0FEh
.Count2                 equ 0FFh

;SpcExitCode:
;.CyclesDone     equ 0   ;no errors, normal return to caller
;.BreakPoint     equ 1   ;stop instruction was encountered
;.TimerInc       equ 2   ;one of the three timers was incremented
;.RegWrite       equ 3   ;one of the registers was written F0-FF
;.DspWrite       equ 4   ;a specific dsp register was written to
;.InvalidOp      equ 5   ;unsupported instruction was executed
;.NullRead       equ 6   ;attempt to read from a unused register
;.NullWrite      equ 7   ;attempt to write to a read-only register

;SampleDir:
;.StartAddress  equ 0   ; SA(L-H) 16 bits
;.LoopAddress   equ 2   ; LSA(L-H) 16 bits


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Core emulation code
;컴컴컴컴컴컴컴컴컴�
section code

SpcEmu:
;
; What each register holds during emulation:
;
; al  = emulated flags
; ah  = temp flags, otherwise free
; bl  = A
; bh  = Y
; bxh = instruction counter    (upper 16 bits)
; ecx = free for opcodes
; ch  = used byte read/write to return and set bytes
; dx  = free for opcode pointer use   (upper 16 bits must remain zero!)
; si  = current opcode pointer (upper 16 bits must remain zero!)
; edi = free for opcodes and register functions
; ebp = keeps current time as cycle counter
;
; X, direct page, and stack pointer are not kept in registers.
;
; Opcode routines may use ecx,edx,edi,ah.
; Read/write routines may only use ah,edi. All others must be saved.
; Some instructions require the use of specific registers, such as cl for
; shifting and ax for multiplying. For these, the registers may be saved
; or temporarily swapped with another (xchg).

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Important variables:
;
section data
align 4,db 0
.Regs:          ;FileRegs must exactly match Regs!
.AY:                            ;byte registers A and Y paired as word
.A:             db 0            ;keep A and Y paired
.Y:             db 0
.Flags:         db 0            ;SPC flags, remapped for speed
align 4,db 0                    ;use table to put in actual order
.X:
.DpX:                           ;keep X and dp paired
.Dp:            dd 0            ;direct page pointer (0000h or 0100h)
.Pc:            dd 0FFC0h       ;starts out in ROM
.Sp:            dd 1FFh         ;ranges 101h-1FFh
.TotalTime:     dd 0            ;total ticks emulated, 64khz per second (always ahead of play time unless on a really slow computer)
.RegsSizeOf     equ $-.Regs

align 4,db 0
.FileRegs:      ;FileRegs structure must exactly match Regs!
.FileAY:
.FileA:         db 0
.FileY:         db 0
.FileFlags:     db 0
align 4,db 0
.FileX:
.FileDpX:
.FileDp:        dd 0
.FilePc:        dd 0FFC0h
.FileSp:        dd 1FFh
.FileTotalTime: dd 0            ;total ticks emulated, 64khz per second (always ahead of play time unless on a really slow computer)

align 4,db 0
.ResetRegs:     ;ResetRegs must exactly match Regs!
.ResetAY:                       ;byte registers A and Y paired as word
.ResetA:        db 0            ;keep A and Y paired
.ResetY:        db 0
.ResetFlags:    db 0            ;SPC flags, remapped for speed
align 4,db 0                    ;use table to put in actual order
.ResetX:
.ResetDpX:                           ;keep X and dp paired
.ResetDp:       dd 0            ;direct page pointer (0000h or 0100h)
.ResetPc:       dd 0FFC0h       ;starts out in ROM
.ResetSp:       dd 1FFh         ;ranges 101h-1FFh
.ResetTotalTime:dd 0            ;total ticks emulated, 64khz per second (always ahead of play time unless on a really slow computer)

.Timer0:        db 16           ;timer 0 count
.Timer1:        db 16           ;timer 1
.Timer2:        db 16           ;timer 2
.Timer01:       db 224          ;decremented 8 times before incrementing 0 or 1
.NextTime:      dd 0            ;time (in cycles) of soonest event to disrupt opcode execution
.TotalCycles:   dd 0            ;total cycles emulated so far, will wrap eventually
.TotalOps:      dd 0            ;total number of instructions executed
.CyclesPerTick: dd CyclesPerTickDef
.TickTime:      dd CyclesPerTickDef ;time of next tick, when counter check will occur
.ExitTime:      dd 0            ;time when emu loop should pause and return
.VblankTime:    dd CyclesPerFrame ;for special hacks
.BreakTime:     dd -1           ;time when a abnormal exit occurred
.Checksum:      dd 0            ;checksum of all SPC RAM
.Val:           dd 0            ;temporarily holds values, for when both
                                ;operand sources are from memory, such as
                                ;dp(d),dp(s) and (X),(Y).
section code

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Call this after loading an SPC state or to completely restart one.
; If called with no state loaded, it will 'reset' the CPU.
; Must be called BEFORE DspEmu.Init
;
.Init:
.Reinit: ;(alias)
    cld

    ; Copy parts of RAM
    mov esi,FileRams
    mov edi,Rams
    mov ecx,RamsSizeOf/4
    rep movsd

    ; Copy PCALL jump table over BIOS code
    mov esi,SpcEram
    mov edi,SpcRam+0FFC0h
    mov ecx,64/4
    rep movsd

    ; Copy registers
    mov esi,.FileRegs
    mov edi,.Regs
    mov ecx,.RegsSizeOf/4
    mov eax,[.CyclesPerTick]
    cld
    rep movsd
    mov [.TickTime],eax                     ;set time of next tick
    mov dword [.VblankTime],CyclesPerFrame  ;for special hacks
    test byte [SpcEmu.Flags],SpcFlag.P      ;check direct page
	setnz [SpcEmu.Dp+1]                     ;set pointer accordingly
    mov eax,[SpcRam+SpcReg.Timer0]          ;get all three timer values
    and eax,0FFFFFFh                        ;zero top byte
    or eax,0E0000000h                       ;set timer 0,1 8x multiple to max (7*32)
    mov [.Timer0],eax                       ;set timers 0,1,2

    xor eax,eax
    mov dword [.TotalCycles],eax
    mov dword [.TotalOps],eax

    ; Restart DSP RAM
    mov esi,DspRam
    mov edi,DspRamCopy
    mov ecx,128/4                           ;make spare copy of DSP registers
    rep movsd                               ;for comparison

    ; calculate checksum for identification
    mov esi,FileSpcRam
    mov ecx,65536
    call GetCheckSum
    mov [.Checksum],eax

    ret

%if 0 ;commented because unused
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Resets CPU as if first powered on, waiting for input from the game,
; (waits for CCh from port F4h)
.Reset:
    cld
    mov esi,.Rom
    mov edi,SpcRam+0FFC0h
    mov ecx,64/4
    rep movsd
    mov esi,.ResetRegs
    mov edi,.Regs
    mov ecx,.RegsSizeOf/4
    rep movsd
    mov byte [SpcRam+SpcReg.Control],0
    ret
%endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Pass in eax the minimum number of cycles to execute (0-65535) in a single
; call. It will 'round up' to the nearest instruction, possibly executing
; a few more cycles more than passed. It may also return with fewer completed
; than specified if an irregular exit is triggered, like encountering a
; breakpoint, reading from a watched port, or executing an unsupported
; instruction.
;
; (eax=minimum cycles to emulate)
; (ebx=ops executed)
.Start:
    push ebp
    mov ebp,[.TotalCycles]      ;get total cycles done so far (ebp is used by .Enter)
    and eax,2097152-1           ;limit cycles to emulate <1 second
    test ebp,ebp                ;if sign is set then wrap all events around
    jns .NoCycleWrap
    and ebp,7FFFFFFFh           ;wrap total cycles emulated
    and dword [.TickTime],7FFFFFFFh
    and dword [.VblankTime],7FFFFFFFh
    mov [.TotalCycles],ebp
.NoCycleWrap:
    lea edx,[eax+ebp]           ;add cycles emulated with cycles to emulate to get end time
    mov [.ExitTime],edx         ;save end time
    movzx ebx,word [.AY]        ;get A & Y, and set zero instructions executed this call
    movzx esi,word [.Pc]        ;get word program counter
    mov al,[.Flags]             ;irrelevant what the rest of eax is
    call .Continue
.Stop:
    mov [.AY],bx                ;save A & Y registers
    mov [.Flags],al
    shr ebx,16                  ;instructions counted is in upper part of word
    mov [.Pc],esi               ;save program counter
    add [.TotalOps],ebx         ;add ops executed in this call to the total
    pop ebp
    ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Main Loop
;
; Emulation of opcodes is done in a tight loop until an event is expected.
; That anticipated event may be a timer count increment or return to caller.
; Other events like breakpoints and watched registers are unexpected events.
;
; Do not call this loop directly, but instead from Start.
;
; Simple structure of main loop:
;   do
;       execute opcode
;       next opcode
;       check for and respond to events
;   loop until cycles have run out
;
; Actual optimized structure (loop is inverted):
;   do
;       execute opcode
;       next opcode
;   loop for cycles until expected event
;   check for and respond to events
;   continue loop (reenter) until cycles have run out
;
; (al  = flags
;  bl  = A
;  bh  = Y
;  bxh = instruction counter    (upper 16 bits)
;  ebp = current time in cycles
;  esi = current opcode pointer (upper 16 bits must remain zero!)
; )
; (same meaning)

    ; Execute opcodes
    ; !top of loop is not entry point but a resume point!
.NextOp:                    ;opcode handlers must return here (unless special)
    lea ebx,[ebx+(1<<16)]   ;count another instruction without affecting flags
    jns .ExitOpRun          ;exit if cycles have run out or gone overtime
.InsideOpLoop:              ;better to test loop inside than at bottom
    movzx edx,byte [esi+SpcRam];get opcode value
    jmp dword [.OpcodeJumpTable+edx*4]
.ExitOpRun:
    add ebp,[.NextTime]             ;add cycles overtime to get cycles actually emulated
    mov [.TotalCycles],ebp

    ; Increment timers
    cmp [.TickTime],ebp             ;need to increment any of the timers?
    ja near .NoIncTimers
.IncTimers:
    mov cl,[SpcRam+SpcReg.Control]
    sub byte [.Timer01],32          ;timers 0,1 tick every eighth pass
    jnc .NoIncTimer1
    test cl,SpcReg.Control_St0
    jz .NoIncTimer0                 ;don't increment if timer is paused
    dec byte [.Timer0]
    jnz .NoIncTimer0                ;increment counter if timer = 0
    ; according the documentation, the counters are only 4bit, so then they
    ; should wrap every sixteenth increment, but it does not seem to
    ; adversely affect emulation by disregarding that.
    mov ch,[SpcRam+SpcReg.Timer0]   ;get time between increments
    inc byte [SpcRam+SpcReg.Count0]
    mov [.Timer0],ch                ;reset timer
.NoIncTimer0:
    test cl,SpcReg.Control_St1
    jz .NoIncTimer1                 ;don't increment if timer is paused
    dec byte [.Timer1]
    jnz .NoIncTimer1                ;increment counter if timer = 0
    mov ch,[SpcRam+SpcReg.Timer1]   ;get time between increments
    inc byte [SpcRam+SpcReg.Count1]
    mov [.Timer1],ch                ;reset timer
.NoIncTimer1:
    test cl,SpcReg.Control_St2
    jz .NoIncTimer2                 ;don't increment if timer is paused
    dec byte [.Timer2]
    jnz .NoIncTimer2                ;increment counter if timer = 0
    mov ch,[SpcRam+SpcReg.Timer2]   ;get time between increments
    inc byte [SpcRam+SpcReg.Count2]
    mov [.Timer2],ch                ;reset timer
.NoIncTimer2:
    mov edi,[.CyclesPerTick]    ;default cycles between ticks
    inc dword [.TotalTime]      ;incremented 64000 times per second
    add [.TickTime],edi         ;cycles until next anticipated tick event occurs
.NoIncTimers:

;(ebp=current cycle count, all other regs are expected to hold the values of
; the appropriate SPC registers or be free)
.Continue:
    ;Find when next event occurs, timer increment or end of emulation
    mov edi,[.TickTime]
    cmp [.ExitTime],edi         ;enough before end time for another tick?
    ja .MoreTimerIncs           ;enough time for another timer increment
    mov edi,[.ExitTime]
    cmp ebp,edi                 ;is current time >= end time?
    jae .Exit                   ;no more emulation
.MoreTimerIncs:
    mov [.NextTime],edi         ;save cycle time when next event occurs
    sub ebp,edi                 ;calculate difference until then
    ;(current time - next event time) = negative cycles until next event
    jmp .InsideOpLoop
;() (ebp=current time)
.Exit:
    ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.DisAsm:
    push ebp
    and eax,65536-1             ;limit cycles to emulate to <65536
    mov ebp,[.TotalCycles]      ;get total cycles done so far (ebp is used by .Enter)
    test ebp,ebp                ;if sign is set then wrap all events around
    jns .DisNoCycleWrap
    and ebp,7FFFFFFFh           ;wrap total cycles emulated
    and dword [.TickTime],7FFFFFFFh
    mov [.TotalCycles],ebp
.DisNoCycleWrap:
    lea edx,[eax+ebp]           ;add cycles emulated with cycles to emulate to get end time
    push edx
    movzx ebx,word [.AY]        ;get A & Y, and set zero instructions executed this call
    movzx esi,word [.Pc]        ;get word program counter
    mov al,[.Flags]             ;irrelevant what the rest of eax is
.DisAsmNext:
    lea edx,[ebp+1]             ;add cycles emulated with cycles to emulate to get end time
    mov [.ExitTime],edx         ;save end time
    call ShowOpcode.Name
    call .Continue
    ;call ShowOpcode.Path
    cmp ebp,[esp]
    js .DisAsmNext
.DisAsmStop:
    mov [.AY],bx                ;save A & Y registers
    mov [.Flags],al
    shr ebx,16                  ;instructions counted is in upper part of word
    mov [.Pc],esi               ;save program counter
    add [.TotalOps],ebx         ;add ops executed in this call to the total
    pop edx
    pop ebp
    ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Reads byte value anywhere from the 64k
; (edx=address to read, ch=value read)
;
; Other registers contain A and Y along with the current cycle count and
; number of instructions executed so far.
; May only use ah,ch,edi. All others must be saved and restored.
;
.ReadByte:
    cmp edx,0F0h                ;less than registers?
    jb .ReadByteFromRam
    cmp edx,100h                ;greater than page zero?
    jae .ReadByteFromRam
    jmp [.ReadRegJumpTable-(0F0h*4)+edx*4] ;jump to register function
  .ReadByteFromRam:
  .ReadDspAdr:                  ;F2h    rw DSP address
  .ReadDataPort:                ;F4-F7h rw
    mov ch,[SpcRam+edx]
    ret

; This is the simplest, truest version. Also slowest.
  .ReadTimer:                   ;FD-FFh r  4bit counter
    mov ch,[edx+SpcRam]
  .ResetTimer:
    mov [edx+SpcRam],dh         ;zero counter with dh (will always be zero)
    ret

; read timer count hack (saves a lot of time)
  .ReadTimerHack:               ;FD-FFh r  4bit counter
    mov ch,[edx+SpcRam]
    test ch,ch
    jnz .ResetTimer             ;only do the following if the counter is zero
    push eax
    push ebx
    mov eax,0000FF00h           ;preset with maximum possible timer count
    xor ebx,ebx

    ; check if next instruction points back to current one...
    ;SpcOpcInfo

    ;Find which timer will tick soonest
    mov al,[.Timer01]           ;timers 0&1 tick every eighth tick of timer 2
    test byte [SpcRam+SpcReg.Control],SpcReg.Control_St0
    jz .SkipTimer0
    mov ah,[.Timer0]
    dec ah                      ;compensate for 0=255
  .SkipTimer0:
    test byte [SpcRam+SpcReg.Control],SpcReg.Control_St1
    jz .SkipTimer1
    mov bl,[.Timer1]
    dec bl                      ;compensate for 0=255
    cmp bl,ah                   ;does timer 1 tick after timer 0
    ja .SkipTimer1
    mov ah,bl                   ;timer 1 occurs first
  .SkipTimer1:
    test byte [SpcRam+SpcReg.Control],SpcReg.Control_St2
    jz .SkipTimer2
    mov bl,byte [.Timer2]
    dec bl                      ;compensate for 0=255
    shl ebx,5
    cmp ebx,eax                 ;does timer 2 tick after both timer 0 and 1
    ja .SkipTimer2
    mov eax,ebx                 ;timer 2 occurs first
  .SkipTimer2:

    ;Adjust all timers forward and reset if necessary
    cmp [.Timer01],al           ;merely set carry first time
    sbb [.Timer0],ah
    sub [.Timer01],al           ;subtract and set carry this time
    sbb [.Timer1],ah
    shr eax,5                   ;64khz / 8khz = 8; 8 - 3 = 5
    sub [.Timer2],al
    add [.TotalTime],eax

    imul eax,[.CyclesPerTick]
    pop ebx
    add eax,[.TickTime]         ;get next tick time
    mov ebp,eax
    mov [.TickTime],eax
    sub ebp,[.NextTime]         ;get difference between next tick and next event
    pop eax
    ret

  %if 0
; Uncomment this little hack to majorly speed up emulation
; It's a bit unstable though. The songs lose precision because the SPC code
; does not like the counters incrementing so fast.
  .ReadTimerHack2:                ;FD-FFh r  4bit counter
    mov ch,[edx+SpcRam]
    test ch,ch
    jnz .ResetTimer             ;only do the following if the counter is zero
    add ebp,CyclesPerTimerTick*16
    add dword [.TickTime],CyclesPerTimerTick*16
    add dword [.TotalTime],CyclesPerTimerTick*16
    mov ch,1                   ;it starts too lose accuracy though
    ret
  %endif

  .ReadF4.SailorMoonRpg:
    mov ch,98h                  ;return value with high bit set to exit loop
    ret

  .ReadF4.SuperPuyo2:
    mov ch,[SpcRam+0EAh]        ;return its own wait counter
    mov edi,ebp
    add edi,[.NextTime]
    cmp [.VblankTime],edi
    jbe .ReadF4.SP2Ret
    dec ch                      ;not ready yet, return counter one less
    ret
  .ReadF4.SP2Ret:
    add dword [.VblankTime],CyclesPerVblank  ;calc cycle time of next vertical blank
    ret
    ;add dword [.VblankTime],CyclesPerFrame  ;calc cycle time of next vertical blank
    ;mov ebp,[.VblankTime]
    ;sub ebp,[.NextTime]         ;get difference between next vblank and next event
    ;ret

  .ReadF5.SuperPuyo2:
    mov ch,0FFh                 ;return sentinel value
    ret

  .ReadDspData:                 ;F3h    rw  DSP data
    mov edx,[SpcRam+SpcReg.DspAdr]
    and edx,127
    mov ch,[DspRam+edx]
  %if SpcDebugIoPrint
    pusha
    call ShowOpcode.Name
    mov edi,Text.DspRead
    call .PrintBreakWithValue
    popa
  %endif
    mov edx,0F3h                ;restore DSP data address
    ret

  .ReadUnknown:                 ;function of register is unknown
  .ReadIllegal:                 ;register is designated as write-only
    ;F0
    ;F1h w  (control)
    ;F8h ???
    ;F9h ???
    ;FAh w  timer count, 8KHz, 0-255
    ;FBh w               8KHz
    ;FCh w               64KHz
    ;mov byte [Debug.Options],1
    mov ch,[edx+SpcRam]
  %ifdef debug
    pusha
    call ShowOpcode.Name
    mov edi,Text.RegReadIllegal
    call .PrintBreakWithValue
    popa
  %endif
    ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Writes byte value anywhere into the 64k
; (edx=address to write, ch=value read)
;
; Other registers contain A and Y along with the current cycle count and
; number of instructions executed so far.
; May only use ah,ch,edi. All others must be saved.
;
.WriteByte:
    cmp edx,100h                ;less than page zero?
    jb .WriteByteRegCheck
;   cmp edx,0FFC0h              ;writing into ROM?
;   jae .WriteByteExtraRam
  .WriteByteToRam:
    mov [SpcRam+edx],ch
    ret
  .WriteByteRegCheck:
    cmp edx,0F0h                ;less than registers?
    jb .WriteByteToRam
    jmp dword [.WriteRegJumpTable-(0F0h*4)+edx*4]
;  .WriteByteExtraRam:
;    mov [SpcEram+edx-0FFC0h],ch
    ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Writes byte value into the current 256-byte page
; (edx=address to write, ch=value read)
;
; Other registers contain A and Y along with the current cycle count and
; number of instructions executed so far.
; May only use ah,ch,edi. All others must be saved.
;
.WriteByteDp:
    cmp edx,0F0h
    jb .WriteByteToRam
    cmp edx,100h
    jae .WriteByteToRam
    jmp dword [.WriteRegJumpTable-(0F0h*4)+edx*4]
  .WriteDspAdr:                 ;F2h    rw  Select DSP register
    mov [SpcRam+edx],ch
  .WriteDataPort:               ;F4-F7h wr  do nothing, simply ignore
    ret

  .WriteTimer:                  ;FA-FCh w
    ; ??? should the timer be reset here
    ; ...
    mov [SpcRam+edx],ch
    ret

  .WriteControl:                ;F1h    w   Control
    test ch,SpcReg.Control_Pc01
    jz .Ports01NotCleared
    mov word [SpcRam+SpcReg.DataPort0],0
  .Ports01NotCleared:
    test ch,SpcReg.Control_Pc23
    jz .Ports23NotCleared
    mov word [SpcRam+SpcReg.DataPort2],0
  .Ports23NotCleared:
    mov [SpcRam+SpcReg.Control],ch
    ret

  .WriteDspData:                ;F3h rw  DSP Data
    mov [SpcRam+SpcReg.DspData],ch
    mov dl,byte [SpcRam+SpcReg.DspAdr]
    ;and edx,127                 ;limit current dsp register to 0-7Fh
  %if 0;SpcDebugIoPrint
    pusha
    mov edi,Text.DspWrite
    call .PrintBreakWithValue
    popa
  %endif
    jmp dword [DspEmu.WriteRegJumpTable+edx*4]
    ;Note that it is up to the DSP code to reset edx=F3 before returning

  .WriteUnknown:                ;function of register is unknown
  .WriteIllegal:                ;register is designated as read-only
  %if SpcDebugIoPrint
    pusha
    call ShowOpcode.Name
    mov edi,Text.RegWriteIllegal
    call .PrintBreakWithValue
    popa
  %endif
    ;mov [edx+SpcRam],ch
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Opcode Macros
;컴컴컴컴컴컴컴컴컴�
; Macros use edx for the address and ch for the result read or value to write.
;
; dp(?+?) means ((?+?) & 0FFh) + direct_page
;
; DpO           offset in page
; DpO2          offset in page (use second operand)
; DpX           x-indexed in page
; DpXInc        x-indexed in page with auto increment
; DpY           y-indexed in page
; DpOX          x-indexed offset in page
; DpOY          y-indexed offset in page
; AbsO          absolute offset (16bit)
; AbsOX         x-indexed absolute offset
; AbsOY         y-indexed absolute offset
; InDpOX        x-indexed indirect offset
; YInDpO        indirect offset y-indexed
; BitAdr
;
; SetFlagsNZ
; SetFlagsNZC
; SetFlagsNVHZC
;
; PushReg
; PopReg
; SetDpBit
; ClrDpBit
; TableCall
; BranchBitSet
; BranchBitClr
; RelativeLogicJump

; Nothing special, just uses what is already in edx
%macro .ReadAdr 0
    call .ReadByte
%endmacro

; Direct page offset
; [dp(byte_offset)]
%macro .ReadDpO 0
    mov edx,[.Dp]           ;get direct page (0000h or 0100h)
    mov dl,[esi+1+SpcRam]   ;move byte constant into low part of address
    call .ReadByte
%endmacro

; Second Direct page offset, used for dp,#imm
; Uses second operand instead of first.
; [dp(byte_offset)]
%macro .ReadDpO2 0
    mov edx,[.Dp]           ;get direct page (0000h or 0100h)
    mov dl,[esi+2+SpcRam]   ;move byte constant into low part of address
    call .ReadByte
%endmacro

; Direct page offset, used for (d),(s)
; Does not reread the direct page since it is already in dh.
; Must have already called DpO first before using.
; [dp(byte_offset)]
%macro .ReadDpO3 0
    ;mov edx,[.Dp]          ;already in dh
    mov dl,[esi+2+SpcRam]   ;move byte constant into low part of address
    call .ReadByte
%endmacro

; X-Indexed
; [dp(X)]
%macro .ReadDpX 0
    mov edx,[.DpX]          ;get direct page and X (0000h or 0100h)
    call .ReadByte
%endmacro

; X-Indexed with auto-increment afterwards
; [dp(X)]
%macro .ReadDpXInc 0
    mov edx,[.DpX]          ;get direct page and X (0000h or 0100h)
    call .ReadByte
    inc dl
    mov [.X],dl             ;save incremented X
%endmacro

; Y-Indexed
; [dp(Y)]
%macro .ReadDpY 0
    mov edx,[.Dp]           ;get direct page (0000h or 0100h)
    mov dl,bh               ;Y is dp address
    call .ReadByte
%endmacro

; X-indexed Direct page offset
; [dp(byte_offset + X)]
%macro .ReadDpOX 0
    mov edx,[.DpX]          ;get direct page (0000h or 0100h) and index X
    add dl,[esi+1+SpcRam]   ;add byte constant into low part of address
    call .ReadByte
%endmacro

; Y-Indexed Direct page offset
; [dp(byte_offset + Y)]
%macro .ReadDpOY 0
    mov edx,[.Dp]           ;get direct page (0000h or 0100h)
    mov dl,[esi+1+SpcRam]   ;move byte constant into low part of address
    add dl,bh               ;with Y as index
    call .ReadByte
%endmacro

; Absolute offset
; [word_offset]
%macro .ReadAbsO 0
    mov dx,[esi+1+SpcRam]   ;word constant is absolute address
    call .ReadByte
%endmacro

; X-Indexed Absolute offset
; [word_offset + X]
%macro .ReadAbsOX 0
    movzx edx,byte [.X]     ;with X as index
    add dx,[esi+1+SpcRam]   ;word constant is absolute address
    call .ReadByte
%endmacro

; Y-Indexed Absolute offset
; [word_offset + Y]
%macro .ReadAbsOY 0
    movzx edx,bh            ;with Y as index
    add dx,[esi+1+SpcRam]   ;word constant is absolute address
    call .ReadByte
%endmacro

; X-Indexed Indirect
; [word[dp(byte_offset + X)]]
;   Read word pointer at offset plus X then read byte at pointer
%macro .ReadInDpOX 0
    mov edx,[.DpX]          ;get direct page (0000h or 0100h) with index X
    add dl,[esi+1+SpcRam]   ;add byte constant into address lsb
    ;call .ReadByte         ;assume we won't read pointer from a register
    mov dx,[edx+SpcRam]     ;move in word pointer
    call .ReadByte
%endmacro

; Indirect Y-Indexed
; [word[dp(byte_offset)] + Y]
;   Read word pointer at offset then read byte at pointer plus Y
%macro .ReadYInDpO 0
    mov edx,[.Dp]           ;get direct page (0000h or 0100h)
    movzx edi,bh            ;zero extend Y
    mov dl,[esi+1+SpcRam]   ;move byte constant into address lsb
    ;call .ReadByte         ;assume we won't read pointer from a register
    mov dx,[edx+SpcRam]     ;move in word pointer
    add dx,di               ;add Y as index
    call .ReadByte
%endmacro

; Returns with address in dx and cl holding shift value
; Low 13 bits are for 8k address, upper 3 are for selected bit
%macro .ReadMemBit 0
    mov dx,[esi+1+SpcRam]
    mov cl,dh
    and edx,1FFFh           ;mask out top 3 bits to get address
    shr cl,5                ;bring down top three bits
    call .ReadByte
%endmacro

; Direct page offset
; [dp(byte_offset)]
%macro .WriteDpO 0
    mov edx,[.Dp]           ;get direct page (0000h or 0100h)
    mov dl,[esi+1+SpcRam]   ;move byte constant into low part of address
    call .WriteByteDp
%endmacro

; Direct page offset using second operand
; [dp(byte_offset)]
%macro .WriteDpO2 0
    mov edx,[.Dp]           ;get direct page (0000h or 0100h)
    mov dl,[esi+2+SpcRam]   ;move byte constant into low part of address
    call .WriteByteDp
%endmacro

; Direct page offset using second operand
; Does not read dp since it is already in dh.
; [dp(byte_offset)]
%macro .WriteDpO3 0
    ;mov edx,[.Dp]          ;already in dh
    mov dl,[esi+2+SpcRam]   ;move byte constant into low part of address
    call .WriteByteDp
%endmacro

; X-Indexed
; [dp(X)]
%macro .WriteDpX 0
    mov edx,[.DpX]          ;get direct page (0000h or 0100h) with index X
    call .WriteByteDp
%endmacro

; X-Indexed with auto-increment afterwards
; [dp(X)]
%macro .WriteDpXInc 0
    mov edx,[.DpX]          ;get direct page (0000h or 0100h) with index X
    call .WriteByteDp
    inc dl
    mov [.X],dl             ;save incremented X
%endmacro

; Y-Indexed
; [dp(Y)]
%macro .WriteDpY 0
    mov edx,[.Dp]           ;get direct page (0000h or 0100h)
    mov dl,bh               ;Y is dp address
    call .WriteByteDp
%endmacro

; X-indexed Direct page offset
; [dp(byte_offset + X)]
%macro .WriteDpOX 0
    mov edx,[.DpX]          ;get direct page (0000h or 0100h)
    add dl,[esi+1+SpcRam]   ;add byte constant into low part of address
    call .WriteByteDp
%endmacro

; Y-indexed Direct page offset
; [dp(byte_offset + Y)]
%macro .WriteDpOY 0
    mov edx,[.Dp]           ;get direct page (0000h or 0100h)
    mov dl,[esi+1+SpcRam]   ;move byte constant into low part of address
    add dl,bh               ;with Y as index
    call .WriteByteDp
%endmacro

; Absolute offset
; [word_offset]
%macro .WriteAbsO 0
    mov dx,[esi+1+SpcRam]   ;word constant is absolute address
    call .WriteByte
%endmacro

; X-Indexed Absolute offset
; [word_offset + X]
%macro .WriteAbsOX 0
    movzx edx,byte [.X]     ;with X as index
    add dx,[esi+1+SpcRam]   ;word constant is absolute address
    call .WriteByte
%endmacro

; Y-Indexed Absolute offset
; [word_offset + Y]
%macro .WriteAbsOY 0
    movzx edx,bh            ;with Y as index
    add dx,[esi+1+SpcRam]   ;word constant is absolute address
    call .WriteByte
%endmacro

; X-Indexed Indirect
; [word[dp(byte_offset + X)]]
;   Read word pointer at offset plus X then read byte at pointer
%macro .WriteInDpOX 0
    mov edx,[.DpX]          ;get direct page (0000h or 0100h) with index X
    add dl,[esi+1+SpcRam]   ;add byte constant into address lsb
    ;call .ReadByte          ;assume we won't read pointer from a register
    mov dx,[edx+SpcRam]     ;move in word pointer
    call .WriteByte
%endmacro

; Indirect Y-Indexed
; [word[dp(byte_offset)] + Y]
;   Read word pointer at offset then read byte at pointer plus Y
%macro .WriteYInDpO 0
    mov edx,[.Dp]           ;get direct page (0000h or 0100h)
    mov dl,[esi+1+SpcRam]   ;move byte constant into address lsb
    movzx edi,bh            ;zero extend Y
    ;call .ReadByte          ;assume we won't read pointer from a register
    mov dx,[edx+SpcRam]     ;add word pointer with Y as index
    add dx,di
    call .WriteByte
%endmacro

%macro .WriteAdr 0
    call .WriteByte
%endmacro

%macro .WriteDpAdr 0
    call .WriteByteDp
%endmacro

%macro .SetFlagsNZ 0
    lahf
    and eax,SpcFlag.mNZ
    or al,ah
%endmacro

%macro .SetFlagsNZC 0
    lahf
    and eax,SpcFlag.mNZC
    or al,ah
%endmacro

; This was needed after finding out that RCL and RCR do not set the flags!
; The macro must immediately follow the roll and assumes that the SPC carry
; flag is clear.
%macro .SetFlagsRolledNZC 1
    adc al,0
    test %1,%1
    lahf
    and eax,SpcFlag.mNZ
    or al,ah
%endmacro

; It is too bad Intel didn't simply put the overflow flag bit into the lower
; byte of the status flags so the jump test would be unnecessary.
%macro .SetFlagsNVHZC 0
    lahf
    jno %%NoOverFlow
    and eax,SpcFlag.mNHZC
    or al,SpcFlag.V         ;set overflow flag
    jmp short %%WasOverFlow
%%NoOverFlow:
    and eax,SpcFlag.mNVHZC  ;mask out overflow flag
%%WasOverFlow:
    or al,ah
%endmacro

; [100 + (Sp--)]        post-decrement
%macro .PushReg 1
    mov edx,[.Sp]
    mov [SpcRam+edx],%1
    dec dl
    mov [.Sp],dl
    inc esi
    add ebp,byte 4
    jmp .NextOp
%endmacro

; [100 + (++Sp)]        pre-increment
%macro .PopReg 1
    inc byte [.Sp]
    inc esi
    mov edx,[.Sp]
    add ebp,byte 4
    mov %1,[SpcRam+edx]
    jmp .NextOp
%endmacro

;SET1    dip.bit    x2    2     4  set direct page bit       .........
%macro .SetDpBit 1
    .ReadDpO
    or ch,%1
    call .WriteByteDp
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
%endmacro

;CLR1    dip.bit    y2    2     4  clear direct page bit     .........
%macro .ClrDpBit 1
    .ReadDpO
    and ch,~%1
    call .WriteByteDp
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
%endmacro

;Verified in Terranigma
;TCALL     n        n1    1     8   table call               .........
%macro .TableCall 1
    mov edx,[.Sp]
    lea ecx,[esi+1]         ;set to instruction after call
    mov si,[SpcRam+0FFC0h+((15-%1)*2)];get address to jump to
    mov [SpcRam+edx],ch     ;must do in two writes because of wrap
    dec dl                  ;post-decrement
    mov [SpcRam+edx],cl     ;write low byte
    dec dl                  ;post-decrement
    add ebp,byte 8
    mov [.Sp],edx
    jmp .NextOp
%endmacro

;BBS   dp.bit,rel   x3    3    5/7  branch on dp.bit=1             ...
%macro .BranchBitSet 1
    .ReadDpO
    test ch,%1
    .RelativeLogicJump jnz,3,5,7
%endmacro

;BBC   dp.bit,rel   y3    3    5/7  branch on dp.bit=0             ...
%macro .BranchBitClr 1
    .ReadDpO
    test ch,%1
    .RelativeLogicJump jz,3,5,7
%endmacro

;test condition is passed in.
;parameters are: test, instruction size, cycles no jump, cycles jump taken
%macro .RelativeLogicJump 4
    %1 %%Jump
    add esi,byte %2
    add ebp,byte %3
    jmp .NextOp
  %%Jump:
    movsx edx,byte [esi+%2-1+SpcRam]
    lea esi,[esi+edx+%2]
    and esi,0FFFFh           ;clip inside 64k
    add ebp,byte %4
    jmp .NextOp
%endmacro


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Opcodes...
;------------------------------------------------------------------------
; Mnemonic  Operand  Code Bytes Cycles Operation                    Flag
;------------------------------------------------------------------------
.Op00:
;NOP                00    1     2    no operation              .........
    inc esi                     ;next instruction
    add ebp,byte 2              ;add two cycles
    jmp .NextOp
.Op01:
;TCALL     n        n1    1     8   table call               .........
    .TableCall 0
.Op02:
;SET1    dip.bit    x2    2     4  set direct page bit       .........
    .SetDpBit 1
.Op03:
;BBS   dp.bit,rel   x3    3    5/7  branch on dp.bit=1             ...
    .BranchBitSet 1
.Op04:
;OR     A,dp        04    2     3     A <- A OR (dp)           N......Z.
    .ReadDpO
    or bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 3
    jmp .NextOp
.Op05:
;OR     A,labs      05    3     4     A <- A OR (abs)          N......Z.
    .ReadAbsO
    or bl,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.Op06:
;OR     A,(X)       06    1     3     A <- A OR (X)            N......Z.
    .ReadDpX
    or bl,ch
    .SetFlagsNZ
    inc esi
    add ebp,byte 3
    jmp .NextOp
.Op07:
;OR     A,(dp+X)    07    2     6  A <- A OR (word(dp+X))      N......Z.
    .ReadInDpOX
    or bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op08:
;OR     A,#inm      08    2     2     A <- A OR inm            N......Z.
    or bl,[SpcRam+esi+1]
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 2
    jmp .NextOp
.Op09:
;OR dp(d),dp(s) 09    3     6 (dp(d))<-(dp(d)) OR (dp(s))  N......Z.
    .ReadDpO
    mov [.Val],ch
    .ReadDpO3
    or ch,[.Val]
    .SetFlagsNZ
    .WriteDpAdr
    add esi,byte 3
    add ebp,byte 6
    jmp .NextOp
.Op0A:
;OR1    C,mem.bit   0A    3     5  C <- C OR  (mem.bit)      ........C
    SpcEmuDebugResponse
    .ReadMemBit
    shr ch,cl
    and ch,1
    or al,ch
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op0B:
;ASL      dp        0B    2     4      C << (dp)   <<0       N......ZC
    .ReadDpO
    shl ch,1
    .SetFlagsNZC
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.Op0C:
;ASL     labs       0C    3     5      C << (abs)  <<0       N......ZC
    .ReadAbsO
    shl ch,1
    .SetFlagsNZC
    .WriteAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op0D:
;PUSH     PSW       0D    1     4    push PSW to stack       .........
    movzx edx,al
    mov ch,[.FlagTable+edx]
    .PushReg ch
.Op0E:
;TSET1    labs      0E    3     6 test and set bits with A   N......Z.
    .ReadAbsO
    test ch,bl
    .SetFlagsNZ
    or ch,bl
    .WriteAdr
    add esi,byte 3
    add ebp,byte 6
    jmp .NextOp
.Op0F:;!!!
;BRK                0F    1     8   software interrupt       ...1.0..
    SpcEmuDebugResponse
    and al,~SpcFlag.I           ;clear indirect master enable??
    or  al,SpcFlag.B            ;set break flag
    inc esi
    add ebp,byte 8
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.Op10:
;BPL     rel        10    2    2/4  branch on N=0                  ...
    test al,SpcFlag.N
    .RelativeLogicJump jz,2,2,4
.Op11:
    .TableCall 1
.Op12:
;CLR1    dip.bit    y2    2     4  clear direct page bit     .........
    .ClrDpBit 1
.Op13:
    .BranchBitClr 1
.Op14:
;OR     A,dp+X      14    2     4     A <- A OR (dp+X)         N......Z.
    .ReadDpOX
    or bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.Op15:
;OR     A,labs+X    15    3     5     A <- A OR (abs+X)        N......Z.
    .ReadAbsOX
    or bl,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op16:
;OR     A,labs+Y    16    3     5     A <- A OR (abs+Y)        N......Z.
    .ReadAbsOY
    or bl,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op17:
;OR     A,(dp)+Y    17    2     6   A <- A OR (word(dp)+Y)     N......Z.
    .ReadYInDpO
    or bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op18:
;OR     dp,#inm     18    3     5  (dp) <- (dp) OR inm         N......Z.
    .ReadDpO2
    or ch,[SpcRam+esi+1]
    .SetFlagsNZ
    .WriteDpAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op19:
;OR     (X),(Y)     19    1     5   (X) <- (X) OR (Y)          N......Z.
    .ReadDpY
    mov [.Val],ch
    .ReadDpX
    or ch,[.Val]
    .SetFlagsNZ
    .WriteDpAdr
    inc esi
    add ebp,byte 5
    jmp .NextOp
.Op1A:;!! must bytes be in h-l order?
;DECW     dp        1A    2     6  Decrement dp memory pair  N......Z.
    .ReadDpO            ;read low byte
    mov cl,ch
    inc dl              ;next address
    .ReadAdr            ;read high byte
    dec cx              ;decrement word
    .SetFlagsNZ
    .WriteDpAdr         ;write high byte
    mov ch,cl
    dec dl              ;lower address
    .WriteDpAdr         ;write low byte
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op1B:
;ASL     dp+X       1B    2     5      C << (dp+X) <<0       N......ZC
    .ReadDpOX
    shl ch,1
    .SetFlagsNZC
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.Op1C:
;ASL      A         1C    1     2      C << A      <<0       N......ZC
    shl bl,1
    .SetFlagsNZC
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op1D:
;DEC      X         1D    1     2      -- X                  N......Z.
    dec byte [.X]
    .SetFlagsNZ
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op1E:
;CMP    X,labs      1E    3     4     X-(abs)                 N......ZC
    .ReadAbsO
    cmp [.X],ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.Op1F:
;JMP    (labs+X)    1F    3     6   PC <- (abs+X+1)(abs+X)         ...
    movzx edx,byte [.X]     ;with X as index
    add dx,[SpcRam+esi+1]   ;word constant is absolute address
    mov si,[SpcRam+edx]
    add ebp,byte 6
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.Op20:
;CLRP               20    1     2   clear direct page flag    ..0.....
    and al,~SpcFlag.P
    mov [.Dp+1],byte 0      ;set direct page to 0000h
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op21:
    .TableCall 2
.Op22:
    .SetDpBit 2
.Op23:
    .BranchBitSet 2
.Op24:
;AND    A,dp        24    2     3     A <- A AND (dp)          N......Z.
    .ReadDpO
    and bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 3
    jmp .NextOp
.Op25:
;AND    A,labs      25    3     4     A <- A AND (abs)         N......Z.
    .ReadAbsO
    and bl,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.Op26:
;AND    A,(X)       26    1     3     A <- A AND (X)           N......Z.
    .ReadDpX
    and bl,ch
    .SetFlagsNZ
    inc esi
    add ebp,byte 3
    jmp .NextOp
.Op27:
;AND    A,(dp+X)    27    2     6  A <- A AND (word(dp+X))     N......Z.
    .ReadInDpOX
    and bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op28:
;AND    A,#inm      28    2     2     A <- A AND inm           N......Z.
    and bl,[SpcRam+esi+1]
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 2
    jmp .NextOp
.Op29:
;AND    dp(d),dp(s) 29    3     6 (dp(d))<-(dp(d)) AND (dp(s)) N......Z.
    .ReadDpO
    mov [.Val],ch
    .ReadDpO3
    and ch,[.Val]
    .SetFlagsNZ
    .WriteDpAdr
    add esi,byte 3
    add ebp,byte 6
    jmp .NextOp
.Op2A:
;OR1    C,/mem.bit  2A    3     5  C <- C OR  !(mem.bit)     ........C
    SpcEmuDebugResponse
    .ReadMemBit
    shr ch,cl
    and ch,1
    xor ch,1
    or al,ch
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op2B:
;ROL      dp        2B    2     4      C << (dp)   <<C       N......ZC
    .ReadDpO
    btr eax,0               ;set carry for next operation
    rcl ch,1
    .SetFlagsRolledNZC ch
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.Op2C:
;ROL     labs       2C    3     5      C << (abs)  <<C       N......ZC
    .ReadAbsO
    btr eax,0               ;set carry for next operation
    rcl ch,1
    .SetFlagsRolledNZC ch
    .WriteAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op2D:
;PUSH      A        2D    1     4    push A to stack         .........
    .PushReg bl
.Op2E:
;CBNE   dp,rel      2E    3    5/7  compare A with (dp) then BNE   ...
;(verified in Mario RPG)
    .ReadDpO
    cmp bl,ch
    .RelativeLogicJump jne,3,5,7
.Op2F:
;BRA     rel        2F    2     4   branch always                  ...
    movsx edx,byte [SpcRam+esi+1]
    lea esi,[esi+edx+2]
    and esi,0FFFFh           ;clip inside 64k
    add ebp,byte 4
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.Op30:
;BMI     rel        30    2    2/4  branch on N=1                  ...
    test al,SpcFlag.N
    .RelativeLogicJump jnz,2,2,4
.Op31:
    .TableCall 3
.Op32:
    .ClrDpBit 2
.Op33:
    .BranchBitClr 2
.Op34:
;AND    A,dp+X      34    2     4     A <- A AND (dp+X)        N......Z.
    .ReadDpOX
    and bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.Op35:
;AND    A,labs+X    35    3     5     A <- A AND (abs+X)       N......Z.
    .ReadAbsOX
    and bl,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op36:
;AND    A,labs+Y    36    3     5     A <- A AND (abs+Y)       N......Z.
    .ReadAbsOY
    and bl,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op37:
;AND    A,(dp)+Y    37    2     6   A <- A AND (word(dp)+Y)    N......Z.
    .ReadYInDpO
    and bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op38:
;AND    dp,#inm     38    3     5  (dp) <- (dp) AND inm        N......Z.
    .ReadDpO2
    and ch,[SpcRam+esi+1]
    .SetFlagsNZ
    .WriteDpAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op39:
;AND    (X),(Y)     39    1     5   (X) <- (X) AND (Y)         N......Z.
    .ReadDpY
    mov [.Val],ch
    .ReadDpX
    and ch,[.Val]
    .SetFlagsNZ
    .WriteDpAdr
    inc esi
    add ebp,byte 5
    jmp .NextOp
.Op3A:;!! must bytes be in h-l order?
;INCW     dp        3A    2     6  Increment dp memory pair  N......Z.
    .ReadDpO            ;read low byte
    mov cl,ch
    inc dl
    .ReadAdr            ;read high byte
    inc cx
    .SetFlagsNZ
    .WriteDpAdr ;write high byte
    mov ch,cl
    dec dl
    .WriteDpAdr ;write low byte
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op3B:
;ROL     dp+X       3B    2     5      C << (dp+X) <<C       N......ZC
    .ReadDpOX
    btr eax,0               ;set carry for next operation
    rcl ch,1
    .SetFlagsRolledNZC ch
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.Op3C:
;ROL      A         3C    1     2      C << A      <<C       N......ZC
    btr eax,0               ;set carry for next operation
    rcl bl,1
    .SetFlagsRolledNZC bl
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op3D:
;INC      X         3D    1     2      ++ X                  N......Z.
    inc byte [.X]
    .SetFlagsNZ
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op3E:
;CMP    X,dp        3E    2     3     X-(dp)                  N......ZC
    .ReadDpO
    cmp [.X],ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 2
    add ebp,byte 3
    jmp .NextOp
.Op3F:
;CALL     labs      3F    3     8   subroutine call          ........
    mov edx,[.Sp]
    lea ecx,[esi+3]         ;set to instruction after CALL
    mov [SpcRam+edx],ch     ;must do in two writes because of wrap
    dec dl                  ;post-decrement
    mov [SpcRam+edx],cl     ;write low byte
    dec dl                  ;post-decrement
    mov si,[SpcRam+esi+1]
    mov [.Sp],edx
    add ebp,byte 8
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.Op40:
;SETP               40    1     2   set direct page flag      ..1..0..
    and al,~SpcFlag.I       ;clear indirect master enable flag
    mov [.Dp+1],byte 1      ;set dp pointer to 0100h
    or al,SpcFlag.P         ;set direct page
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op41:
    .TableCall 4
.Op42:
    .SetDpBit 4
.Op43:
    .BranchBitSet 4
.Op44:
;EOR    A,dp        44    2     3     A <- A EOR (dp)          N......Z.
    .ReadDpO
    xor bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 3
    jmp .NextOp
.Op45:
;EOR    A,labs      45    3     4     A <- A EOR (abs)         N......Z.
    .ReadAbsO
    xor bl,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.Op46:
;EOR    A,(X)       46    1     3     A <- A EOR (X)           N......Z.
    .ReadDpX
    xor bl,ch
    .SetFlagsNZ
    inc esi
    add ebp,byte 3
    jmp .NextOp
.Op47:
;EOR    A,(dp+X)    47    2     6  A <- A EOR (word(dp+X))     N......Z.
    .ReadInDpOX
    xor bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op48:
;EOR    A,#inm      48    2     2     A <- A EOR inm           N......Z.
    xor bl,[SpcRam+esi+1]
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 2
    jmp .NextOp
.Op49:
;EOR    dp(d),dp(s) 49    3     6 (dp(d))<-(dp(d)) EOR (dp(s)) N......Z.
    .ReadDpO
    mov [.Val],ch
    .ReadDpO3
    xor ch,[.Val]
    .SetFlagsNZ
    .WriteDpAdr
    add esi,byte 3
    add ebp,byte 6
    jmp .NextOp
.Op4A:
;AND1   C,mem.bit   4A    3     4  C <- C AND (mem.bit)      ........C
    SpcEmuDebugResponse
    .ReadMemBit
    shr ch,cl
    or ch,~1
    and al,ch
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.Op4B:
;LSR      dp        4B    2     4      0 >> (dp)   >>C       N......ZC
    .ReadDpO
    shr ch,1
    .SetFlagsNZC
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.Op4C:
;LSR     labs       4C    3     5      0 >> (abs)  >>C       N......ZC
    .ReadAbsO
    shr ch,1
    .SetFlagsNZC
    .WriteAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op4D:
;PUSH      X        4D    1     4    push X to stack         .........
    mov ch,[.X]
    .PushReg ch
.Op4E:
;TCLR1    labs      4E    3     6 test and clear bits with A N......Z.
    .ReadAbsO
    test ch,bl
    .SetFlagsNZ
    not bl                  ;temporarily invert A for AND
    and ch,bl
    not bl                  ;restore A
    .WriteAdr
    add esi,byte 3
    add ebp,byte 6
    jmp .NextOp
.Op4F:
;Verified in Terranigma and Rudora No Hihou
;PCALL   upage      4F    2     6   upage call               ........
    mov edx,[.Sp]
    lea ecx,[esi+2]         ;set to instruction after PCALL
    mov [SpcRam+edx],ch     ;must do in two writes because of wrap
    dec dl                  ;post-decrement
    mov [SpcRam+edx],cl     ;write low byte
    dec dl                  ;post-decrement
    movzx esi,byte [SpcRam+esi+1]
    mov [.Sp],edx
    add esi,0FF00h
    add ebp,byte 6
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.Op50:
;BVC     rel        50    2    2/4  branch on V=0                  ...
    test al,SpcFlag.V
    .RelativeLogicJump jz,2,2,4
.Op51:
    .TableCall 5
.Op52:
    .ClrDpBit 4
.Op53:
    .BranchBitClr 4
.Op54:
;EOR    A,dp+X      54    2     4     A <- A EOR (dp+X)        N......Z.
    .ReadDpOX
    xor bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.Op55:
;EOR    A,labs+X    55    3     5     A <- A EOR (abs+X)       N......Z.
    .ReadAbsOX
    xor bl,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op56:
;EOR    A,labs+Y    56    3     5     A <- A EOR (abs+Y)       N......Z.
    .ReadAbsOY
    xor bl,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op57:
;EOR    A,(dp)+Y    57    2     6   A <- A EOR (word(dp)+Y)    N......Z.
    .ReadYInDpO
    xor bl,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op58:
;EOR    dp,#inm     58    3     5  (dp) <- (dp) EOR inm        N......Z.
    .ReadDpO2
    xor ch,[SpcRam+esi+1]
    .SetFlagsNZ
    .WriteDpAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op59:
;EOR    (X),(Y)     59    1     5   (X) <- (X) EOR (Y)         N......Z.
    .ReadDpY
    mov [.Val],ch
    .ReadDpX
    xor ch,[.Val]
    .SetFlagsNZ
    .WriteDpAdr
    inc esi
    add ebp,byte 5
    jmp .NextOp
.Op5A:;!! must bytes be read in h-l order?
;CMPW    YA,dp      5A    2     4     YA - (dp+1)(dp)        N......ZC
    .ReadDpO            ;read low byte
    mov cl,ch
    inc dl
    .ReadAdr            ;read high byte
    cmp bx,cx
    cmc
    .SetFlagsNZC
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.Op5B:
;LSR     dp+X       5B    2     5      0 >> (dp+X) >>C       N......ZC
    .ReadDpOX
    shr ch,1
    .SetFlagsNZC
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.Op5C:
;LSR      A         5C    1     2      0 >> A      >>C       N......ZC
    shr bl,1
    .SetFlagsNZC
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op5D:
;MOV    X, A        5D    1     2     X <- A                   N......Z
    mov [.X],bl
    test bl,bl
    .SetFlagsNZ
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op5E:
;CMP    Y,labs      5E    3     4     Y-(abs)                 N......ZC
    .ReadAbsO
    cmp bh,ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.Op5F:
;JMP     labs       5F    3     3   jump to new location           ...
    mov si,[SpcRam+esi+1]
    add ebp,byte 3
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.Op60:
;CLRC               60    1     2   clear carry flag          .......0
    and al,~SpcFlag.C
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op61:
    .TableCall 6
.Op62:
    .SetDpBit 8
.Op63:
    .BranchBitSet 8
.Op64:
;CMP    A,dp        64    2     3     A-(dp)                  N......ZC
    .ReadDpO
    cmp bl,ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 2
    add ebp,byte 3
    jmp .NextOp
.Op65:
;CMP    A,labs      65    3     4     A-(abs)                 N......ZC
    .ReadAbsO
    cmp bl,ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.Op66:
;CMP    A,(X)       66    1     3     A-(X)                   N......ZC
    .ReadDpX
    cmp bl,ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    inc esi
    add ebp,byte 3
    jmp .NextOp
.Op67:
;CMP    A,(dp+X)    67    2     6     A-(word(dp+X))          N......ZC
    .ReadInDpOX
    cmp bl,ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op68:
;CMP    A,#inm      68    2     2     A-inm                   N......ZC
    cmp bl,[SpcRam+esi+1]
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 2
    add ebp,byte 2
    jmp .NextOp
.Op69:
;CMP    dp(d),dp(s) 69    3     6     (dp(d))-(dp(s))         N......ZC
    .ReadDpO
    mov [.Val],ch
    .ReadDpO3
    cmp ch,[.Val]
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 3
    add ebp,byte 6
    jmp .NextOp
.Op6A:
;AND1   C,/mem.bit  6A    3     4  C <- C AND !(mem.bit)     ........C
    SpcEmuDebugResponse
    .ReadMemBit
    shr ch,cl
    or ch,~1
    xor ch,1
    and al,ch
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.Op6B:
;ROR      dp        6B    2     4      C >> (dp)   >>C       N......ZC
    .ReadDpO
    btr eax,0               ;set carry for next operation
    rcr ch,1
    .SetFlagsRolledNZC ch
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.Op6C:
;ROR     labs       6C    3     5      C >> (abs)  >>C       N......ZC
    .ReadAbsO
    btr eax,0               ;set carry for next operation
    rcr ch,1
    .SetFlagsRolledNZC ch
    .WriteAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op6D:
;PUSH      Y        6D    1     4    push Y to stack         .........
    .PushReg bh
.Op6E:
;DBNZ   dp,rel      6E    3    5/7  decrement memory (dp) then JNZ ...
    .ReadDpO
    dec ch
    .WriteDpAdr
    test ch,ch
    .RelativeLogicJump jnz,3,5,7
.Op6F:
;RET                6F    1     5   return from subroutine   ........
    ;mov edx,[.Sp]
    ;mov si,[SpcRam+edx+1]  ;ignore wrap (is this code safe?)
    ;add dl,2
    mov edx,[.Sp]
    inc dl                  ;preincrement
    mov cl,[SpcRam+edx]     ;must do in two reads because of wrap
    inc dl                  ;preincrement
    mov ch,[SpcRam+edx]
    mov si,cx               ;copy to pc
    mov [.Sp],edx
    add ebp,byte 5
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.Op70:
;BVS     rel        70    2    2/4  branch on V=1                  ...
    test al,SpcFlag.V
    .RelativeLogicJump jnz,2,2,4
.Op71:
    .TableCall 7
.Op72:
    .ClrDpBit 8
.Op73:
    .BranchBitClr 8
.Op74:
;CMP    A,dp+X      74    2     4     A-(dp+X)                N......ZC
    .ReadDpOX
    cmp bl,ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.Op75:
;CMP    A,labs+X    75    3     5     A-(abs+X)               N......ZC
    .ReadAbsOX
    cmp bl,ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op76:
;CMP    A,labs+Y    76    3     5     A-(abs+Y)               N......ZC
    .ReadAbsOY
    cmp bl,ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op77:
;CMP    A,(dp)+Y    77    2     6     A-(word(dp)+Y)          N......ZC
    .ReadYInDpO
    cmp bl,ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op78:
;CMP    dp,#inm     78    3     5     (dp)-inm                N......ZC
    .ReadDpO2
    cmp ch,[SpcRam+esi+1]
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op79:
;CMP    (X),(Y)     79    1     5     (X)-(Y)                 N......ZC
    .ReadDpY
    mov [.Val],ch
    .ReadDpX
    cmp ch,[.Val]
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    inc esi
    add ebp,byte 5
    jmp .NextOp
.Op7A:;!! must bytes be in h-l order?
;ADDW    YA,dp      7A    2     5   YA  <- YA + (dp+1)(dp)   NV..H..ZC
    .ReadDpO                ;read low byte
    mov cl,ch
    inc dl
    .ReadAdr                ;read high byte
    add bx,cx
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.Op7B:
;ROR     dp+X       7B    2     5      C >> (dp+X) >>C       N......ZC
    .ReadDpOX
    btr eax,0               ;set carry for next operation
    rcr ch,1
    .SetFlagsRolledNZC ch
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.Op7C:
;ROR      A         7C    1     2      C >> A      >>C       N......ZC
    btr eax,0               ;set carry for next operation
    rcr bl,1
    .SetFlagsRolledNZC bl
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op7D:
;MOV    A, X        7D    1     2     A <- X                   N......Z
    mov bl,[.X]
    test bl,bl
    .SetFlagsNZ
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op7E:
;CMP    Y,dp        7E    2     3     Y-(dp)                  N......ZC
    .ReadDpO
    cmp bh,ch
    cmc                     ;invert carry flag (@#$!?)
    .SetFlagsNZC
    add esi,byte 2
    add ebp,byte 3
    jmp .NextOp
.Op7F:;!!! unverified because never found a game that uses it
;RET1               7F    1     6   return from interrupt   (Restored)
    SpcEmuDebugResponse
    mov edx,[.Sp]
    inc dl                  ;preincrement
    movzx ecx,byte [SpcRam+edx]
    mov al,[.FlagTable+ecx]
    test al,SpcFlag.P       ;check direct page
    setnz [.Dp+1]           ;set dp pointer accordingly
    inc dl                  ;preincrement
    mov cl,[SpcRam+edx]     ;must do in two reads because of wrap
    inc dl                  ;preincrement
    mov ch,[SpcRam+edx]
    mov si,cx               ;copy to pc
    mov [.Sp],edx
    add ebp,byte 6
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.Op80:
;SETC               80    1     2   set carry flag            .......1
    or al,SpcFlag.C
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op81:
    .TableCall 8
.Op82:
    .SetDpBit 16
.Op83:
    .BranchBitSet 16
.Op84:
;ADC    A,dp        84    2     3     A <- A+(dp)+C           NV..H..ZC
    .ReadDpO
    bt eax,0                ;set carry for next operation
    adc bl,ch
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 3
    jmp .NextOp
.Op85:
;ADC    A,labs      85    3     4     A <- A+(abs)+C          NV..H..ZC
    .ReadAbsO
    bt eax,0                ;set carry for next operation
    adc bl,ch
    .SetFlagsNVHZC
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.Op86:
;ADC    A,(X)       86    1     3     A <- A+(X)+C            NV..H..ZC
    .ReadDpX
    bt eax,0                ;set carry for next operation
    adc bl,ch
    .SetFlagsNVHZC
    inc esi
    add ebp,byte 3
    jmp .NextOp
.Op87:
;ADC    A,(dp+X)    87    2     6     A <- A+((dp+X+1)(dp+X)) NV..H..ZC
    .ReadInDpOX
    bt eax,0                ;set carry for next operation
    adc bl,ch
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op88:
;ADC    A,#inm      88    2     2     A <- A+inm+C            NV..H..ZC
    bt eax,0                ;set carry for next operation
    adc bl,[SpcRam+esi+1]
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 2
    jmp .NextOp
.Op89:
;ADC    dp(d),dp(s) 89    3     6 (dp(d))<-(dp(d))+(dp(s))+C  NV..H..ZC
    .ReadDpO
    mov [.Val],ch
    .ReadDpO3
    bt eax,0                ;set carry for next operation
    adc ch,[.Val]
    .SetFlagsNVHZC
    .WriteDpAdr
    add esi,byte 3
    add ebp,byte 6
    jmp .NextOp
.Op8A:
;EOR1   C,mem.bit   8A    3     5  C <- C EOR (mem.bit)      ........C
    .ReadMemBit
    shr ch,cl
    and ch,1
    xor al,ch
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op8B:
;DEC      dp        8B    2     4      -- (dp)               N......Z.
    .ReadDpO
    dec ch
    .SetFlagsNZ
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.Op8C:
;DEC     labs       8C    3     5      -- (abs)              N......Z.
    .ReadAbsO
    dec ch
    .SetFlagsNZ
    .WriteAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op8D:
;MOV    Y, #inm    8D    2     2     Y <- inm                  N......Z
    mov bh,[SpcRam+esi+1]
    test bh,bh
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 2
    jmp .NextOp
.Op8E:
;POP      PSW       8E    1     4    pop PSW from stack     (Restored)
;(verified in Mario RPG and Cybernator)
    inc byte [.Sp]          ;preincrement
    mov edx,[.Sp]
    movzx ecx,byte [SpcRam+edx]
    mov al,[.FlagTable+ecx]
    ;add sp,1
    ;jb .StackUnderflow      ;zero or carry
    test al,SpcFlag.P       ;check direct page
    setnz [.Dp+1]           ;set dp pointer accordingly
    inc esi
    add ebp,byte 4
    jmp .NextOp
.Op8F:
;MOV    dp,#inm     8F    3     5    (dp) <- inm               ........
    mov ch,[SpcRam+esi+1]   ;get immediate value
    .WriteDpO2
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.Op90:
;BCC     rel        90    2    2/4  branch on C=0                  ...
    test al,SpcFlag.C
    .RelativeLogicJump jz,2,2,4
.Op91:
    .TableCall 9
.Op92:
    .ClrDpBit 16
.Op93:
    .BranchBitClr 16
.Op94:
;ADC    A,dp+X      94    2     4     A <- A+(dp+X)+C         NV..H..ZC
    .ReadDpOX
    bt eax,0                ;set carry for next operation
    adc bl,ch
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.Op95:
;ADC    A,labs+X    95    3     5     A <- A+(abs+X)+C        NV..H..ZC
    .ReadAbsOX
    bt eax,0                ;set carry for next operation
    adc bl,ch
    .SetFlagsNVHZC
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op96:
;ADC    A,labs+Y    96    3     5     A <- A+(abs+Y)+C        NV..H..ZC
    .ReadAbsOY
    bt eax,0                ;set carry for next operation
    adc bl,ch
    .SetFlagsNVHZC
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op97:
;ADC    A,(dp)+Y    97    2     6     A <- A+((dp+1)(dp)+Y)   NV..H..ZC
    .ReadYInDpO
    bt eax,0                ;set carry for next operation
    adc bl,ch
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.Op98:
;ADC    dp,#inm     98    3     5  (dp) <- (dp)+inm+C         NV..H..ZC
    .ReadDpO2
    bt eax,0                ;set carry for next operation
    adc ch,[SpcRam+esi+1]
    .SetFlagsNVHZC
    .WriteDpAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.Op99:
;ADC    (X),(Y)     99    1     5   (X) <- (X)+(Y)+C          NV..H..ZC
    .ReadDpY
    mov [.Val],ch
    .ReadDpX
    bt eax,0                ;set carry for next operation
    adc ch,[.Val]
    .SetFlagsNVHZC
    .WriteDpAdr
    inc esi
    add ebp,byte 5
    jmp .NextOp
.Op9A:;!! must bytes be in h-l order?
;SUBW    YA,dp      9A    2     5   YA  <- YA - (dp+1)(dp)   NV..H..ZC
    .ReadDpO            ;read low byte
    mov cl,ch
    inc dl                  ;next dp address
    .ReadAdr            ;read high byte
    sub bx,cx
    cmc
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.Op9B:
;DEC     dp+X       9B    2     5      -- (dp+X)             N......Z.
    .ReadDpOX
    dec ch
    .SetFlagsNZ
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.Op9C:
;DEC      A         9C    1     2      -- A                  N......Z.
    dec bl
    .SetFlagsNZ
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op9D:
;MOV    X, SP       9D    1     2     X <- SP                  N......Z
    mov ch,[.Sp]
    mov [.X],ch
    test ch,ch
    .SetFlagsNZ
    inc esi
    add ebp,byte 2
    jmp .NextOp
.Op9E:;!!! flags are not all set correctly?
;DIV      YA,X      9E    1    12    Q:A B:Y <- YA / X       NV..H..Z.
    mov ecx,[.X]
    and ecx,0FFh
    jz .DivError
    xchg eax,ebx            ;swap flags with YA
    xor edx,edx             ;zero top part
    div cx                  ;divide YA by X
    xchg eax,ebx            ;reswap flags with YA
    test bl,bl              ;test quotient in A
    lahf
    and eax,SpcFlag.mNVHZ
    or al,ah
    test bh,bh              ;test high quotient
    jz .NoDivOverflow
    or al,SpcFlag.V         ;set overflow
.NoDivOverflow:
    mov bh,dl               ;move remainder to Y
    inc esi
    add ebp,byte 12
    jmp .NextOp
.DivError:
    mov bx,0FFFFh                   ;set YA to infinity
    and al,~SpcFlag.Z               ;not zero
    or al,SpcFlag.V|SpcFlag.N|SpcFlag.H ;indicate overflow
    inc esi
    add ebp,byte 12
    jmp .NextOp
.Op9F:
;XCN      A         9F    1     5      A(7-1) <-> A(3-0)     N......Z.
    rol bl,4                ;exchange high and low nybbles
    .SetFlagsNZ
    inc esi
    add ebp,byte 5
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.OpA0:
;EI                 A0    1     3  set interrupt enable flag  .....1..
    SpcEmuDebugResponse
    or al,SpcFlag.I
    inc esi
    add ebp,byte 3
    jmp .NextOp
.OpA1:
    .TableCall 10
.OpA2:
    .SetDpBit 32
.OpA3:
    .BranchBitSet 32
.OpA4:
;SBC    A,dp        A4    2     3     A <- A-(dp)-!C          NV..H..ZC
    .ReadDpO
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb bl,ch
    cmc
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 3
    jmp .NextOp
.OpA5:
;SBC    A,labs      A5    3     4     A <- A-(abs)-!C         NV..H..ZC
    .ReadAbsO
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb bl,ch
    cmc
    .SetFlagsNVHZC
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.OpA6:
;SBC    A,(X)       A6    1     3     A <- A-(X)-!C           NV..H..ZC
    .ReadDpX
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb bl,ch
    cmc
    .SetFlagsNVHZC
    inc esi
    add ebp,byte 3
    jmp .NextOp
.OpA7:
;SBC    A,(dp+X)    A7    2     6  A <- A-(word(dp+X))    -!C NV..H..ZC
    .ReadInDpOX
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb bl,ch
    cmc
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.OpA8:
;SBC    A,#inm      A8    2     2     A <- A-inm-!C           NV..H..ZC
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb bl,[SpcRam+esi+1]
    cmc
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 2
    jmp .NextOp
.OpA9:
;SBC    dp(d),dp(s) A9    3     6 (dp(d))<-(dp(d))-(dp(s))-!C NV..H..ZC
    .ReadDpO
    mov [.Val],ch
    .ReadDpO3
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb ch,[.Val]
    cmc
    .SetFlagsNVHZC
    .WriteDpAdr
    add esi,byte 3
    add ebp,byte 6
    jmp .NextOp
.OpAA:
;MOV1   C,mem.bit   AA    3     4  C <- (mem.bit)            ........C
;Mario RPG and StarFox use this opcode but still work even completely
;commented, regardless of how carry is set. However, DOOM freezes if wrong.
    .ReadMemBit
    shr ch,cl
    and al,~SpcFlag.C       ;clear carry flag
    and ch,1
    or al,ch
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.OpAB:
;INC      dp        AB    2     4      ++ (dp)               N......Z.
    .ReadDpO
    inc ch
    .SetFlagsNZ
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.OpAC:
;INC     labs       AC    3     5      ++ (abs)              N......Z.
    .ReadAbsO
    inc ch
    .SetFlagsNZ
    .WriteAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.OpAD:
;CMP    Y,#inm      AD    2     2     Y-inm                   N......ZC
    cmp bh,[SpcRam+esi+1]
    cmc
    .SetFlagsNZC
    add esi,byte 2
    add ebp,byte 2
    jmp .NextOp
.OpAE:
;POP       A        AE    1     4    pop A from stack        .........
    .PopReg bl
.OpAF:
;MOV    (X)+,A     AF    1     4     A -> (X) with auto inc    ........
    mov ch,bl
    .WriteDpXInc
    inc esi
    add ebp,byte 4
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.OpB0:
;BCS     rel        B0    2    2/4  branch on C=1                  ...
    test al,SpcFlag.C
    .RelativeLogicJump jnz,2,2,4
.OpB1:
    .TableCall 11
.OpB2:
    .ClrDpBit 32
.OpB3:
    .BranchBitClr 32
.OpB4:
;SBC    A,dp+X      B4    2     4     A <- A-(dp+X)-!C        NV..H..ZC
    .ReadDpOX
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb bl,ch
    cmc
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.OpB5:
;SBC    A,labs+X    B5    3     5     A <- A-(abs+X)-!C       NV..H..ZC
    .ReadAbsOX
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb bl,ch
    cmc
    .SetFlagsNVHZC
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.OpB6:
;SBC    A,labs+Y    B6    3     5     A <- A-(abs+Y)-!C       NV..H..ZC
    .ReadAbsOY
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb bl,ch
    cmc
    .SetFlagsNVHZC
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.OpB7:
;SBC    A,(dp)+Y    B7    2     6  A <- A-(word(dp)+Y)  -!C   NV..H..ZC
    .ReadYInDpO
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb bl,ch
    cmc
    .SetFlagsNVHZC
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.OpB8:
;SBC    dp,#inm     B8    3     5  (dp) <- (dp)-inm-!C        NV..H..ZC
    .ReadDpO2
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb ch,[SpcRam+esi+1]
    cmc
    .SetFlagsNVHZC
    .WriteDpAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.OpB9:
;SBC    (X),(Y)     B9    1     5   (X) <- (X)-(Y)-!C         NV..H..ZC
    .ReadDpY
    mov [.Val],ch
    .ReadDpX
    bt eax,0                ;set carry for next operation
    cmc                     ;invert carry flag (@#$!?)
    sbb ch,[.Val]
    cmc
    .SetFlagsNVHZC
    .WriteDpAdr
    inc esi
    add ebp,byte 5
    jmp .NextOp
.OpBA:;!! must bytes be in h-l order?
;MOVW     YA,dp     BA    2     5     YA <- (dp+1)(dp)       N......Z.
    .ReadDpO
    mov bl,ch
    inc dl
    .ReadAdr
    mov bh,ch
    test bx,bx
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.OpBB:
;INC     dp+X       BB    2     5      ++ (dp+X)             N......Z.
    .ReadDpOX
    inc ch
    .SetFlagsNZ
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.OpBC:
;INC      A         BC    1     2      ++ A                  N......Z.
    inc bl
    .SetFlagsNZ
    inc esi
    add ebp,byte 2
    jmp .NextOp
.OpBD:
;MOV    SP, X       BD    1     2    SP <- X                   ........
    ;mov ecx,100h
    ;mov [.Sp],ecx
    mov ch,[.X]
    mov [.Sp],ch
    inc esi
    add ebp,byte 2
    jmp .NextOp
.OpBE:  ;!! flags do not seem set right, what about the half-carry?
;DAS       A        BE    1     3    decimal adjust for sub  N......ZC
    SpcEmuDebugResponse
    mov ah,al
    sahf            ;set flags for DAA
    xchg ebx,eax    ;swap A|Y with PF (does not affect flags set above)
    daa
    xchg ebx,eax    ;swap adjusted result in A with PF
    .SetFlagsNZC
    inc esi
    add ebp,byte 3
    jmp .NextOp
.OpBF:
;MOV    A, (X)+    BF    1     4     A <- (X) with auto inc    N......Z
    .ReadDpXInc
    test ch,ch
    mov bl,ch           ;copy return value into A
    .SetFlagsNZ
    inc esi
    add ebp,byte 4
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.OpC0:
;DI                 C0    1     3  clear interrupt enable flag .....0..
    SpcEmuDebugResponse
    and al,~SpcFlag.I
    inc esi
    add ebp,byte 3
    jmp .NextOp
.OpC1:
    .TableCall 12
.OpC2:
    .SetDpBit 64
.OpC3:
    .BranchBitSet 64
.OpC4:
;MOV    dp,A       C4    2     4     A -> (dp)                 ........
    mov ch,bl
    .WriteDpO
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.OpC5:
;MOV    labs,A     C5    3     5     A -> (abs)                ........
    mov ch,bl
    .WriteAbsO
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.OpC6:
;MOV    (X),A      C6    1     4     A -> (X)                  ........
    mov ch,bl
    .WriteDpX
    inc esi
    add ebp,byte 4
    jmp .NextOp
.OpC7:
;MOV    (dp+X),A   C7    2     7     A -> (word(dp+X))         ........
    mov ch,bl
    .WriteInDpOX
    add esi,byte 2
    add ebp,byte 7
    jmp .NextOp
.OpC8:
;CMP    X,#inm      C8    2     2     X-inm                   N......ZC
    mov ch,[SpcRam+esi+1]
    cmp [.X],ch
    cmc
    .SetFlagsNZC
    add esi,byte 2
    add ebp,byte 2
    jmp .NextOp
.OpC9:
;MOV    labs,X     C9    3     5     X -> (abs)                ........
    mov ch,[.X]
    .WriteAbsO
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.OpCA:
;MOV1   mem.bit,C   CA    3     6  C -> (mem.bit)            .........
;Seiken Densetsu 3 - 1-05 Walls and Steels uses it, but even completely
;commenting out the opcode does not affect emulation.
    SpcEmuDebugResponse
    .ReadMemBit
    ;;inc cl
    ;;ror ch,cl
    ;;bt eax,C
    ;;rcl ch,cl
    ror ch,cl               ;bring desired bit into lowest position 0
    and ch,~1               ;clear lowest bit
    bt eax,0                ;set carry for next operation
    adc ch,0                ;put carry into lowest bit
    rol ch,cl               ;restore bit to previous position
    .WriteAdr
    add esi,byte 3
    add ebp,byte 6
    jmp .NextOp
.OpCB:
;MOV    dp,Y       CB    2     4     X -> (dp)                 ........
    mov ch,bh
    .WriteDpO
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.OpCC:
;MOV    labs,Y     CC    3     5     X -> (abs)                ........
    mov ch,bh
    .WriteAbsO
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.OpCD:
;MOV    X, #inm    CD    2     2     X <- inm                  N......Z
    mov ch,[SpcRam+esi+1]
    mov [.X],ch
    test ch,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 2
    jmp .NextOp
.OpCE:
;POP       X        CE    1     4    pop X from stack        .........
    inc byte [.Sp]
    mov edx,[.Sp]
    mov ch,[SpcRam+edx]
    mov [.X],ch
    inc esi
    add ebp,byte 4
    jmp .NextOp
.OpCF:  ;??? Intel says flags after multiplication are undefined
;MUL      YA        CF    1     9    YA(16 bits) <- Y * A    N......Z.
    xchg eax,ebx            ;swap flags with YA
    mul ah                  ;multiply A by Y
    xchg eax,ebx            ;restore flags and YA
    test bx,bx
    .SetFlagsNZ
    inc esi
    add ebp,byte 9
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.OpD0:
;BNE     rel        D0    2    2/4  branch on Z=0                  ...
    test al,SpcFlag.Z
    .RelativeLogicJump jz,2,2,4
.OpD1:
    .TableCall 13
.OpD2:
    .ClrDpBit 64
.OpD3:
    .BranchBitClr 64
.OpD4:
;MOV    dp+X,A     D4    2     5     A -> (dp+X)               ........
    mov ch,bl
    .WriteDpOX
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.OpD5:
;MOV    labs+X,A   D5    3     6     A -> (abs+X)              ........
    mov ch,bl
    .WriteAbsOX
    add esi,byte 3
    add ebp,byte 6
    jmp .NextOp
.OpD6:
;MOV    labs+Y,A   D6    3     6     A -> (abs+Y)              ........
    mov ch,bl
    .WriteAbsOY
    add esi,byte 3
    add ebp,byte 6
    jmp .NextOp
.OpD7:
;MOV    (dp)+Y,A   D7    2     7     A -> (word(dp)+Y)         ........
    mov ch,bl
    .WriteYInDpO
    add esi,byte 2
    add ebp,byte 7
    jmp .NextOp
.OpD8:
;MOV    dp,X       D8    2     4     X -> (dp)                 ........
    mov ch,[.X]
    .WriteDpO
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.OpD9:
;MOV    dp+Y,X     D9    2     5     X -> (dp+Y)               ........
    mov ch,[.X]
    .WriteDpOY
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.OpDA:;!! must bytes be in h-l order?
;MOVW     dp,YA     DA    2     4    (dp+1)(dp) <- YA         .........
    mov ch,bl
    .WriteDpO
    inc dl
    mov ch,bh
    .WriteDpAdr
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.OpDB:
;MOV    dp+X,Y     DB    2     5     Y -> (dp+X)               ........
    mov ch,bh
    .WriteDpOX
    add esi,byte 2
    add ebp,byte 5
    jmp .NextOp
.OpDC:
;DEC      Y         DC    1     2      -- Y                  N......Z.
    dec bh
    .SetFlagsNZ
    inc esi
    add ebp,byte 2
    jmp .NextOp
.OpDD:
;MOV    A, Y        DD    1     2     A <- Y                   N......Z
    mov bl,bh
    test bh,bh
    .SetFlagsNZ
    inc esi
    add ebp,byte 2
    jmp .NextOp
.OpDE:
;CBNE  dp+X,rel     DE    3    6/8  compare A with (dp+X) then BNE ...
    .ReadDpOX
    cmp bl,ch
    .RelativeLogicJump jne,3,6,8
.OpDF:  ;!! flags do not seem set right, what about the half-carry?
;DAA       A        DF    1     3    decimal adjust for add  N......ZC
    SpcEmuDebugResponse
    mov ah,al       ;copy PF into ah
    sahf            ;set flags for DAA
    xchg ebx,eax    ;swap A|Y with PF (does not affect flags)
    daa
    xchg ebx,eax    ;swap adjusted result in A with PF
    .SetFlagsNZC
    inc esi
    add ebp,byte 3
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.OpE0:
;CLRV               E0    1     2   clear V and H             .0..0...
    and al,~(SpcFlag.V|SpcFlag.H)
    inc esi
    add ebp,byte 2
    jmp .NextOp
.OpE1:
    .TableCall 14
.OpE2:
    .SetDpBit 128
.OpE3:
    .BranchBitSet 128
.OpE4:
;MOV    A, dp      E4    2     3     A <- (dp)                 N......Z
    .ReadDpO
    mov bl,ch           ;copy return value into A
    test ch,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 3
    jmp .NextOp
.OpE5:
;MOV    A, labs    E5    3     4     A <- (abs)                N......Z
    .ReadAbsO
    mov bl,ch           ;copy return value into A
    test ch,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.OpE6:
;MOV    A, (X)     E6    1     3     A <- (X)                  N......Z
    .ReadDpX
    mov bl,ch                       ;copy return value into A
    test ch,ch
    .SetFlagsNZ
    inc esi
    add ebp,byte 3
    jmp .NextOp
.OpE7:
;MOV    A, (dp+X)  E7    2     6     A <- (word(dp+X))         N......Z
    .ReadInDpOX
    mov bl,ch           ;copy return value into A
    test ch,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.OpE8:;is it necessary to set flags on moving in an immediate ???
;MOV    A, #inm    E8    2     2     A <- inm                  N......Z
    mov bl,[SpcRam+esi+1]
    test bl,bl
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 2
    jmp .NextOp
.OpE9:
;MOV    X, labs    E9    3     4     X <- (abs)                N......Z
    .ReadAbsO
    mov [.X],ch                     ;copy return value into X
    test ch,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.OpEA:
;NOT1   mem.bit     EA    3     5  complement (mem.bit)      .........
    .ReadMemBit
    mov ah,1
    shl ah,cl
    xor ch,ah
    ;ror ch,cl
    ;xor ch,1
    ;rol ch,cl
    .WriteAdr
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.OpEB:
;MOV    Y, dp      EB    2     3     Y <- (dp)                 N......Z
    .ReadDpO
    mov bh,ch           ;copy return value into Y
    test ch,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 3
    jmp .NextOp
.OpEC:
;MOV    Y, labs    EC    3     4     Y <- (abs)                N......Z
    .ReadAbsO
    mov bh,ch           ;copy return value into Y
    test ch,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 4
    jmp .NextOp
.OpED:
;NOTC               ED    1     3   complement carry flag     .......C
    xor al,SpcFlag.C
    inc esi
    add ebp,byte 3
    jmp .NextOp
.OpEE:
;POP       Y        EE    1     4    pop Y from stack        .........
    .PopReg bh
.OpEF:
;SLEEP              EF    1     3    standby SLEEP mode      .........
;       (see FF)
    add ebp,byte 3
    jmp .NextOp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.OpF0:
;BEQ     rel        F0    2    2/4  branch on Z=1                  ...
    test al,SpcFlag.Z
    .RelativeLogicJump jnz,2,2,4
.OpF1:
    .TableCall 15
.OpF2:
    .ClrDpBit 128
.OpF3:
    .BranchBitClr 128
.OpF4:
;MOV    A, dp+X    F4    2     4     A <- (dp+X)               N......Z
    .ReadDpOX
    mov bl,ch           ;copy return value into A
    test ch,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.OpF5:
;MOV    A, labs+X  F5    3     5     A <- (abs+X)              N......Z
    .ReadAbsOX
    mov bl,ch           ;copy return value into A
    test ch,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.OpF6:
;MOV    A, labs+Y  F6    3     5     A <- (abs+Y)              N......Z
    .ReadAbsOY
    mov bl,ch           ;copy return value into A
    test ch,ch
    .SetFlagsNZ
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.OpF7:
;MOV    A, (dp)+Y  F7    2     6     A <- (word(dp)+Y)         N......Z
    .ReadYInDpO
    mov bl,ch           ;copy return value into A
    test ch,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 6
    jmp .NextOp
.OpF8:
;MOV    X, dp      F8    2     3     X <- (dp)                 N......Z
    .ReadDpO
    mov [.X],ch                     ;copy return value into X
    test ch,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 3
    jmp .NextOp
.OpF9:
;MOV    X, dp+Y    F9    2     4     X <- (dp+Y)               N......Z
    .ReadDpOY
    mov [.X],ch                     ;copy return value into X
    test ch,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.OpFA:
;MOV    dp(d),dp(s) FA    3     5    (dp(d)) <- (dp(s))        ........
    .ReadDpO                   ;value is in reg
    .WriteDpO3
    add esi,byte 3
    add ebp,byte 5
    jmp .NextOp
.OpFB:
;MOV    Y, dp+X    FB    2     4     Y <- (dp+X)               N......Z
    .ReadDpOX
    mov bh,ch           ;copy return value into Y
    test ch,ch
    .SetFlagsNZ
    add esi,byte 2
    add ebp,byte 4
    jmp .NextOp
.OpFC:
;INC      Y         FC    1     2      ++ Y                  N......Z.
    inc bh
    .SetFlagsNZ
    inc esi
    add ebp,byte 2
    jmp .NextOp
.OpFD:
;MOV    Y, A        FD    1     2     Y <- A                   N......Z
    mov bh,bl
    test bl,bl
    .SetFlagsNZ
    inc esi
    add ebp,byte 2
    jmp .NextOp
.OpFE:
;DBNZ    Y,rel      FE    2    4/6  decrement Y then JNZ           ...
    dec bh
    .RelativeLogicJump jnz,2,4,6
.OpFF:
;STOP               FF    1     3    standby STOP mode       .........
    add ebp,byte 3
    jmp .NextOp

%ifdef debug
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
.UnverifiedOpcode:
    add dword [.OpcodeJumpTable+edx*4],byte 5
    pusha
	mov [SpcEmu.AY],bx
	mov [SpcEmu.Pc],si
	mov [SpcEmu.Flags],al
    mov edi,MakeOperandString.Buffer
	call MakeOperandString
    mov edx,MakeOperandString.Buffer
	call WriteString
    mov edi,Text.UnverifiedOpcode
    call .PrintBreak
    popa
    ret
%endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Prints address, program counter, time, and value.
;
;(edi=buffer destination, all registers are expected to be saved on stack)
.PrintBreakWithValue:
    mov eax,[esp+StackReg.Cx+1+4]   ;value written
    mov ecx,8                       ;eight bits
    add edi,byte 3
    call MakeHexNum
    sub edi,byte 5
;Prints address, program counter, and time.
;(same as above)
.PrintBreak:
    mov eax,[esp+StackReg.Dx+4]     ;dsp register or opcode number
    mov ecx,8                       ;eight bits
    call MakeHexNum
    mov eax,[esp+StackReg.Si+4]     ;program address
    mov ecx,16                      ;sixteen bits
    add edi,byte 5
    call MakeHexNum
    mov eax,[esp+StackReg.Bp+4]     ;get cycles until next event
    add eax,[.NextTime]             ;get difference of cycles before next event and cycles actually emulated
    mov ecx,32                      ;32 bits
    add edi,byte 2
    call MakeHexNum
    lea edx,[edi-21]
    jmp WriteString
    ;ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
section data

align 4, db 0
.OpcodeJumpTable:
dd .Op00,.Op01,.Op02,.Op03,.Op04,.Op05,.Op06,.Op07,.Op08,.Op09,.Op0A,.Op0B,.Op0C,.Op0D,.Op0E,.Op0F
dd .Op10,.Op11,.Op12,.Op13,.Op14,.Op15,.Op16,.Op17,.Op18,.Op19,.Op1A,.Op1B,.Op1C,.Op1D,.Op1E,.Op1F
dd .Op20,.Op21,.Op22,.Op23,.Op24,.Op25,.Op26,.Op27,.Op28,.Op29,.Op2A,.Op2B,.Op2C,.Op2D,.Op2E,.Op2F
dd .Op30,.Op31,.Op32,.Op33,.Op34,.Op35,.Op36,.Op37,.Op38,.Op39,.Op3A,.Op3B,.Op3C,.Op3D,.Op3E,.Op3F
dd .Op40,.Op41,.Op42,.Op43,.Op44,.Op45,.Op46,.Op47,.Op48,.Op49,.Op4A,.Op4B,.Op4C,.Op4D,.Op4E,.Op4F
dd .Op50,.Op51,.Op52,.Op53,.Op54,.Op55,.Op56,.Op57,.Op58,.Op59,.Op5A,.Op5B,.Op5C,.Op5D,.Op5E,.Op5F
dd .Op60,.Op61,.Op62,.Op63,.Op64,.Op65,.Op66,.Op67,.Op68,.Op69,.Op6A,.Op6B,.Op6C,.Op6D,.Op6E,.Op6F
dd .Op70,.Op71,.Op72,.Op73,.Op74,.Op75,.Op76,.Op77,.Op78,.Op79,.Op7A,.Op7B,.Op7C,.Op7D,.Op7E,.Op7F
dd .Op80,.Op81,.Op82,.Op83,.Op84,.Op85,.Op86,.Op87,.Op88,.Op89,.Op8A,.Op8B,.Op8C,.Op8D,.Op8E,.Op8F
dd .Op90,.Op91,.Op92,.Op93,.Op94,.Op95,.Op96,.Op97,.Op98,.Op99,.Op9A,.Op9B,.Op9C,.Op9D,.Op9E,.Op9F
dd .OpA0,.OpA1,.OpA2,.OpA3,.OpA4,.OpA5,.OpA6,.OpA7,.OpA8,.OpA9,.OpAA,.OpAB,.OpAC,.OpAD,.OpAE,.OpAF
dd .OpB0,.OpB1,.OpB2,.OpB3,.OpB4,.OpB5,.OpB6,.OpB7,.OpB8,.OpB9,.OpBA,.OpBB,.OpBC,.OpBD,.OpBE,.OpBF
dd .OpC0,.OpC1,.OpC2,.OpC3,.OpC4,.OpC5,.OpC6,.OpC7,.OpC8,.OpC9,.OpCA,.OpCB,.OpCC,.OpCD,.OpCE,.OpCF
dd .OpD0,.OpD1,.OpD2,.OpD3,.OpD4,.OpD5,.OpD6,.OpD7,.OpD8,.OpD9,.OpDA,.OpDB,.OpDC,.OpDD,.OpDE,.OpDF
dd .OpE0,.OpE1,.OpE2,.OpE3,.OpE4,.OpE5,.OpE6,.OpE7,.OpE8,.OpE9,.OpEA,.OpEB,.OpEC,.OpED,.OpEE,.OpEF
dd .OpF0,.OpF1,.OpF2,.OpF3,.OpF4,.OpF5,.OpF6,.OpF7,.OpF8,.OpF9,.OpFA,.OpFB,.OpFC,.OpFD,.OpFE,.OpFF

.ReadRegJumpTable:
dd .ReadUnknown         ;F0  ???
dd .ReadIllegal         ;F1h w  (Control)
dd .ReadDspAdr          ;F2h rw Dsp Address
dd .ReadDspData         ;F3h rw Dsp Data
dd .ReadDataPort        ;F4h rw
dd .ReadDataPort        ;F5h rw
dd .ReadDataPort        ;F6h rw
dd .ReadDataPort        ;F7h rw
dd .ReadUnknown         ;F8h ???
dd .ReadUnknown         ;F9h ???
dd .ReadIllegal         ;FAh w  timer count, 8KHz, 0-255
dd .ReadIllegal         ;FBh w               8KHz
dd .ReadIllegal         ;FCh w               64KHz
dd .ReadTimerHack       ;FDh r  4bit counter
dd .ReadTimerHack       ;FEh r
dd .ReadTimerHack       ;FFh r

.WriteRegJumpTable:
dd .WriteUnknown        ;F0
dd .WriteControl        ;F1h w
dd .WriteDspAdr         ;F2h rw
dd .WriteDspData        ;F3h rw
dd .WriteDataPort       ;F4h rw
dd .WriteDataPort       ;F5h rw
dd .WriteDataPort       ;F6h rw
dd .WriteDataPort       ;F7h rw
dd .WriteUnknown        ;F8h
dd .WriteUnknown        ;F9h
dd .WriteTimer          ;FAh w  timer count, 8KHz, 0-255
dd .WriteTimer          ;FBh w               8KHz
dd .WriteTimer          ;FCh w               64KHz
dd .WriteIllegal        ;FDh r  (4bit counter 0)
dd .WriteIllegal        ;FEh r       (counter 1)
dd .WriteIllegal        ;FFh r       (counter 2)

; flag remapping table (for push psw, pop psw, and loading savestates)
.FlagTable:
    incbin "flagtbl.dat"    ;from byte value to register flags or vice-verse

.Rom:
    incbin "spcrom.dat"     ;startup code in upper 64 bytes of SPC memory
