;This is the full assembler source that goes with the new HSC routines in
;QuickBasic.  Requires QB 4.0+ which it can use QuickLibrary (.QLB;.LIB)
;I assume NO responsabilities due to the misuse of this code or any
;warranties. If you don't know how to use assembler, I strongly recommend not
;to try modifying the code.
;SUB routines are:  OutPort (register,data)
;                   PlayFreq (reg1,data1,reg2,data2,reg3,data3)
;
; A86 macro assembler v3.71 was used to compile
;
; Here's how to compile and combine it in QuickBasic.
; Files required: A86.COM/HSC.ASM/LIB.EXE/LINK.EXE/BQLB45.LIB
;
; A86 hsc.asm hsc.obj
; del hsc.lib
; lib hsc +hsc.obj                          [press ENTER at List file:]
; link /q /se:200 HSC.LIB,,nul,BQLB45.lib;
;
; If you wish to add other libraries like QB.LIB, here's how:
;
; lib hsc +qb.lib                           [press ENTER at List file:]
; link /q /se:200 HSC.LIB,,nul,BQLB45.lib;
;
; QB.LIB has been added to HSC.LIB and reconverted to HSC.QLB


OutPort:            ;Routine to send the register# and data to ADLIB ports.
push bp
mov bp, sp

mov bx, [BP + 08]
mov al, byte ptr [bx]    ;Get first parameter.
mov dx, 388h             ;Set port 388.
out dx, al               ;OUT &H388, register
in  al, dx
in  al, dx
in  al, dx            ;These 6 INs are required to put the right amount
in  al, dx            ;of time for the register port.
in  al, dx
in  al, dx

INC dx                ;Increase dx of 1 = 389h (Data port)

mov bx, [BP + 06]
mov al, byte ptr [bx]    ;Get second parameter.
out dx, al               ;OUT &H389, data
in  al, dx
in  al, dx
in  al, dx               ;The data port requires much more waits than
in  al, dx               ;the register port. *NOTE this applies only
in  al, dx               ;to the OPL2 chip (ADLIB). OPL3+ (SBPRO/SB16)
in  al, dx               ;and other sound cards equipped with the OPL3
in  al, dx               ;requires a lot less.
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
pop bp
retf 4       ;Return (far) to QB with 4 bytes used for parameters

PlayFreq:
push bp
mov bp, sp

mov dx,388h
mov bx, [BP + 16]
mov al, byte ptr [bx]   ;Parameter 1.
out dx, al              ;OUT &H388, &HB0 + Chn
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx

inc dx
mov bx, [BP + 14]
mov al, byte ptr [bx]   ;Parameter 2.
out dx, al              ;OUT &H389, 0
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx

dec dx
mov bx, [BP + 12]
mov al, byte ptr [bx]   ;Parameter 3.
out dx, al              ;OUT &H388, &HA0 + Chn
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx

inc dx
mov bx, [BP + 10]
mov al, byte ptr [bx]   ;Parameter 4.
out dx, al              ;OUT &H389, Fr + Signed * 1.3
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx

dec dx
mov bx, [BP + 08]
mov al, byte ptr [bx]   ;Parameter 5.
out dx, al              ;OUT &H388, &HB0 + Chn
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx

inc dx
mov bx, [BP + 06]
mov al, byte ptr [bx]   ;Parameter 6.
out dx, al              ;OUT &H389, 32 + Oct * 4 + FIX(Fr / 256)
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx
in  al, dx

pop bp
retf 12
