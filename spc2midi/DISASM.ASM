;Spc2Midi - Opcode Disassembly
;============================================================

section data

align 4,db 0
SpcOpcInfo:
incbin "opcinfo.dat"

SpcOpcNames:
db 3,"mov    ",3,"adc    ",3,"sbc    ",3,"cmp    ",3,"and    ",2,"or     "
db 3,"eor    ",3,"inc    ",3,"dec    ",3,"asl    ",3,"lsr    ",3,"rol    "
db 3,"ror    ",3,"xcn    ",4,"movw   ",4,"incw   ",4,"decw   ",4,"addw   "
db 4,"subw   ",4,"cmpw   ",3,"mul    ",3,"div    ",3,"daa    ",3,"das    "
db 3,"bra    ",3,"beq    ",3,"bne    ",3,"bcs    ",3,"bcc    ",3,"bvs    "
db 3,"bvc    ",3,"bmi    ",3,"bpl    ",3,"bbs    ",3,"bbc    ",4,"cbne   "
db 4,"dbnz   ",3,"jmp    ",4,"call   ",5,"pcall  ",5,"tcall  ",3,"brk    "
db 3,"ret    ",4,"reti   ",4,"push   ",3,"pop    ",4,"set1   ",4,"clr1   "
db 4,"tset1  ",4,"tclr1  ",4,"and1   ",3,"or1    ",4,"eor1   ",4,"not1   "
db 4,"mov1   ",4,"clrc   ",4,"setc   ",4,"notc   ",4,"clrv   ",4,"clrp   "
db 4,"setp   ",2,"ei     ",2,"di     ",3,"nop    ",4,"sleep  ",4,"stop"

;SpcOpcNamesExplantory:
;db 3,"move into",3,"add with carry",3,"subtract with borrow",3,"compare",3,"and",2,"or"
;db 3,"exclusive or",3,"increment",3,"decrement",3,"arithmetic shift left",3,"LSR    ",3,"roll left"
;db 3,"roll right",3,"exchange nybbles",4,"move word",4,"increment word",4,"decrement word",4,"add word"
;db 4,"subtract word",4,"compare word",3,"multiply",3,"divide",3,"adjust decimal addition",3,"adjust decimal subtraction"
;db 3,"branch",3,"branch if equal",3,"branch if unequal",3,"branch if carry set",3,"branch if carry clear",3,"branch if overflow set"
;db 3,"branch if overflow clear",3,"branch if sign set",3,"branch if sign clear",3,"branch if bit set",3,"branch if bit clear",4,"compare to A and branch if unequal"
;db 4,"decrement and branch if not zero",3,"jmp short",4,"jump long",4,"call",5,"user page call",5,"table call",3,"break"
;db 3,"return",4,"return from interrupt",4,"push onto stack",3,"pop from stack",4,"set bit",4,"clear bit"
;db 4,"test and set bits with A",4,"test and clear bits with A",4,"and carry with",3,"or carry with",4,"exclusive or carry with",4,"not"
;db 4,"move into carry",4,"clear carry",4,"set carry",4,"complement carry",4,"clear overflow and half-carry",4,"clear direct page flag"
;db 4,"set direct page flag",2,"enable interrupts",2,"disable interrupts",3,"no operation",4,"sleep until interrupt",4,"stop execution"
;SpcOpcNamePrepositions:
;into from with

SpcOprNames:
;Special codes:  (all other characters are literal)
; 0 = end of operand string
; 1 = byte value
; 2 = word value
; 3 = value in upper nybble of opcode (tcall)
; 4 = membit
; 5 = relative jump
; 6 = value in upper three bits of opcodes
; 7 = dp address in first operand
; 8 = dp address in second operand
.HighestCode    equ 8
.None:
.A:             db "A",0
.X:             db "X",0
.Y:             db "Y",0
.YA:            db "YA",0
.Sp:            db "Sp",0
.Psw:           db "Psw",0
.C:             db "C",0
.Im:            db 1,0
.DpO:           db "[",7,"]",0
.DpO2:          db "[",8,"]",0
.DpX:           db "[X]",0
.DpXInc:        db "[X+]",0
.DpOX:          db "[",7,"+X]",0
.DpY:           db "[Y]",0
.DpOY:          db "[",7,"+Y]",0
.AbsO:          db "[",2,"]",0
.AbsOX:         db "[",2,"+X]",0
.AbsOY:         db "[",2,"+Y]",0
.InDpOX:        db "[[",7,"+X]]",0
.YInDpO:        db "[[",7,"]+Y]",0
.InAbsOX:       db "[",2,"+X]",0
.MemBit:        db "[",4,"]",0
.MemBitN:       db "[-",4,"]",0
.DpOBit:        db "[",7,".",6,"]",0
.JumpRel:       db 5,0
.JumpAbs:       db 2,0
.OpcH:          db 3,0
.UsrPage:       db 1,0

align 4,db 0
.Table:
dd .None   ,.A      ,.X      ,.Y      ,.YA     ,.Sp     ,.Psw    ,.Im
dd .DpX    ,.DpXInc ,.DpY    ,.DpO    ,.DpOX   ,.DpOY   ,.AbsO   ,.AbsOX
dd .AbsOY  ,.InDpOX ,.YInDpO ,.JumpRel,.JumpAbs,.MemBit ,.MemBitN,.DpOBit
dd .InAbsOX,.OpcH   ,.UsrPage,.C      ,.DpO2

SpcFlagNames:
db "n",SpcFlag.N
db "v",SpcFlag.V
db "p",SpcFlag.P
db "b",SpcFlag.B
db "h",SpcFlag.H
db "i",SpcFlag.I
db "z",SpcFlag.Z
db "c",SpcFlag.C


section code

;==============================
; Shows a disassembled opcode line or displays a graphical path of the PC
;
;(esi=opcode address, bx=A:Y, al=flags)
ShowOpcode:
.Name:
    mov [SpcEmu.AY],bx
    mov [SpcEmu.Pc],si
    mov [SpcEmu.Flags],al
    pusha
    mov edi,MakeOperandString.Buffer
    call MakeOperandString
    mov edx,MakeOperandString.Buffer
    call WriteString
    popa
    ret

%if 0 ;shows the path of opcode execution graphically
.Path:
	;push eax
	mov ah,[.PathTable+esi]
	inc ah
    or ah,128
	;push ds
	;mov es,[AbsoluteSelector]
	;mov [es:0A0000h+esi],ah
.NoTableOverflow:
	mov [.PathTable+esi],ah
	mov [0A0000h+esi],ah
	;pop es
	;pop eax
	ret

.PathInit:
	mov edi,.PathTable
	mov ecx,65536/4
	xor eax,eax
	cld
	rep stosd

    call .SetVideoMode

	mov edi,0A0000h
	mov eax,4030201h
	mov ecx,64

.NextColorBarSection:
	stosd
	add eax,4040404h
	loop .NextColorBarSection
	ret

section bss
alignb 4
.PathTable:     resb 65536
section code
%endif

%if 0 ;sets mode 13h and fills gray palette
.SetVideoMode:
	mov eax,13h
	int 10h
	xor eax,eax
	mov dx,3c8h
	out dx,al
	inc edx
    xor ecx,ecx
.NextGrayColor:
    ;not al
    out dx,al
    ;not al
    out dx,al
    ;not al
    out dx,al
    ;not al
	add ah,64
	adc al,0
	dec cl
	jnz .NextGrayColor
    ret
%endif


;==============================
;(edi=destination buffer)
;turns the current opcode and its 0 to 2 operands into a mnemonic string
;also shows the current PC,A,Y,X,Sp and flag values
MakeOperandString:

section data
.MaxOpcIndent   equ 15

 align 4, db 0  ;! must be in the same order as the values in SpcOprNames
.OprJumpTable:  dd .OprEnd,.OprByte,.OprWord,.OprOpcode,.OprMemBit,.OprJumpRel,.OprOpcode2,.OprDpO,.OprDpO2
.Options:       db -1   ;which parts to display
.OptionsAddress equ 1
.OptionsFlags   equ 2
.OptionsRegs    equ 4
.OptionsOps     equ 8
.SpBase         db 0    ;used for indentation

section bss
 alignb 4
.Opcode:        resd 1  ;holds current opcode byte value and operand values
.OpcodeInfo:    resd 1  ;holds info about opcode like type, size, operands
.Buffer:        resb 256

section code
	cld

	mov esi,[SpcEmu.Pc]
	mov edx,[esi+SpcRam]            ;get opcode and any operands
    mov [.Opcode],edx
    movzx ebx,dl                    ;get opcode value
    mov eax,[SpcOpcInfo+ebx*4]      ;get opcode type and operands
    mov [.OpcodeInfo],eax           ;store info about opcode type

	test byte [.Options],.OptionsAddress
	jz .NoAddress
	mov eax,esi                     ;copy program counter address
    mov ecx,16                      ;sixteen bits
    call MakeHexNum
    mov dword [edi],"    "          ;separate address
    add edi,byte 2
.NoAddress:

    ;(edx=opcode)
	test byte [.Options],.OptionsRegs
	jz .NoRegs
    mov eax,"Y:"<<16
    mov bl,[SpcEmu.Y]               ;and Y
    call .RegisterValue
    mov eax,"A:"<<16                ;set name of register
    mov bl,[SpcEmu.A]               ;get value of SPC register A
    call .RegisterValue             ;print value of register with trailing space
    mov eax,"X:"<<16
    mov bl,[SpcEmu.X]               ;same with X
    call .RegisterValue
    mov eax,"S:"<<16
    mov bl,[SpcEmu.Sp]              ;stack pointer
    call .RegisterValue
    mov eax,"O:"<<16
    mov bl,dl                       ;opcode value
    call .RegisterValue
    mov eax,"M:"<<16
    mov ebx,[SpcEmu.Dp]
    mov bl,byte [.Opcode+1]         ;get first operand
    mov bl,[SpcRam+ebx]             ;get value at dp mem
    call .RegisterValue
    ;mov eax,"C:"<<16
    ;mov bl,[SpcEmu.Timer0]
    ;call .RegisterValue
    stosb                           ;separate with a double space
.NoRegs:

    ;(edx=opcode)
	test byte [.Options],.OptionsFlags
	jz .NoFlags
	mov esi,SpcFlagNames
	mov cl,8
	mov ch,[SpcEmu.Flags]
.NextFlag:
	lodsw                           ;get flag letter and mask
	test ch,ah
	jz .FlagNotSet
	and al,~32                      ;capitalize flag letter if set
.FlagNotSet:
	stosb
	dec cl
	jnz .NextFlag
	mov ax,"  "
	stosw
.NoFlags:

    ;(edx=opcode)
	test byte [.Options],.OptionsOps
    jz near .NoOps
    movzx ecx,byte [SpcEmu.Sp]      ;stack pointer
    not cl
    mov bl,cl
    sub cl,[.SpBase]
    jc .IndentTooFarLeft
    cmp cl,.MaxOpcIndent
    jbe .IndentOps
    mov cl,.MaxOpcIndent
    sub bl,cl
    mov [.SpBase],bl
    jmp .IndentOps
.IndentTooFarLeft:
    mov [.SpBase],bl
    xor cl,cl
.IndentOps:
    mov al," "
    rep stosb
    movzx ebx,byte [.OpcodeInfo]    ;get opcode type
    lea esi,[SpcOpcNames+1+ebx*8]   ;point to mnemonic name for type
    movzx ecx,byte [esi-1]          ;get mnemonic length
    rep movsb                       ;copy string name
    movzx ebx,byte [.OpcodeInfo+1]  ;get type of first operand
    cmp bl,Opr.None                 ;quit if none
    je .NoOps
    mov al," "                      ;separate next operand with a space
    mov esi,[SpcOprNames.Table+ebx*4];get string to make
    call .OprString
    movzx ebx,byte [.OpcodeInfo+2]  ;get type of second operand
    cmp bl,Opr.None
    je .NoOps
    mov al,","                      ;separate next operand with a comma
    mov esi,[SpcOprNames.Table+ebx*4];get string to make
    call .OprString
.NoOps:
.Done:
    mov dword [edi],0A0Dh
    ret

;(esi=formatted string, eax=first character 0-0FF, ebx=operand type 0-0FF, edi=buffer)
;Prints a formatted operand string into the buffer
.OprString:
    movzx eax,al                    ;zero out top bits
.OprStringContinue:
	stosb                           ;write precharacter or last literal
.OprStringNext:
	lodsb                           ;get next character in string
	cmp al,SpcOprNames.HighestCode  ;check if literal character or code
    ja .OprStringContinue           ;continue in loop if literal
	jmp [.OprJumpTable+eax*4]
;.OprEnd: see below in RegisterValue
.OprOpcode:
	mov al,dl                       ;copy opcode
	shr al,4                        ;get top four bits
    mov al,[eax+NumToString.NumberTable]  ;make ASCII character
    jmp short .OprStringContinue
.OprOpcode2:
	mov al,dl                       ;copy opcode
    shr al,5                        ;get top three bits
    add al,'0'                      ;make ASCII character
    jmp short .OprStringContinue
.OprWord:
	mov eax,edx                     ;copy operand
	shl eax,8                       ;adjust word to top of dword
	mov ecx,4                       ;four hex chars
    jmp short .OprNum
.OprByte:
	mov eax,edx                     ;copy operand
	shl eax,16                      ;adjust byte to top of dword
	mov ecx,2                       ;two hex chars
;(eax=value, ecx=nybbles in number)
.OprNum:
    mov ebx,NumToString.NumberTable
.OprNumNextDigit:
	and eax,0FFFF0000h              ;mask off unused bits
	rol eax,4                       ;bring up next four bits
	xlatb                           ;turn nybble into ASCII character
	stosb
	dec ecx
    jnz .OprNumNextDigit
	xor eax,eax                     ;rezero for pointer use
    jmp short .OprStringNext
.OprMemBit:
	mov eax,edx                     ;copy operand
    and eax,1FFF00h                 ;get address
    mov ecx,16                      ;sixteen bits
    push esi
    shl eax,8                       ;move address to top of dword
    call MakeHexNum.NoAdjust
    pop esi
	mov eax,edx                     ;copy operand
    and eax,0E00000h                ;get selected bit
    shr eax,13                      ;put into ah
    add eax,'.0'                    ;make ASCII character
    stosw
	xor eax,eax                     ;rezero for pointer use
    jmp short .OprStringNext
.OprJumpRel:
    movzx ecx,byte [.OpcodeInfo+3]  ;get opcode byte length
    movsx eax,byte [.Opcode+ecx-1]  ;get relative distance (-128 - +127)
    add eax,ecx                     ;add opcode length to offset
    add eax,[SpcEmu.Pc]             ;add program counter offset
	shl eax,16                      ;adjust word to top of dword
	mov ecx,4                       ;two hex chars
    jmp short .OprNum
.OprDpO:
    mov al,dh                       ;copy first operand
.OprDpOMututal:
    test byte [SpcEmu.Flags],SpcFlag.P
    setnz ah
    shl eax,20                      ;adjust 12 bits to top
    mov ecx,3
    jmp short .OprNum
.OprDpO2:
    mov al,[.Opcode+2]              ;copy second operand
    jmp short .OprDpOMututal

; Prints a register name and byte value.
; (eax=register name, bl=byte value, edi=buffer)
.RegisterValue:
    movzx ecx,bl
    and ebx,15                      ;make ptr of lower nybble
    shr ecx,4                       ;make ptr of upper nybble
    mov ah,[ebx+NumToString.NumberTable]   ;get ASCII character
    mov al,[ecx+NumToString.NumberTable]   ;get ASCII character
    rol eax,16                      ;make register name come first
    stosd
    mov al," "
    stosb
.OprEnd:
    ret

;==============================
; Prints a hex value of varying digit length, from nybble to word.
; (upper eax=byte/word/dword value, ecx=bits, edi=buffer) (edi=byte after last character output)
; (saves edx)
MakeHexNum:
    ror eax,cl              ;adjust nybble/byte/word to top of dword
;(eax=value at top of dword)
.NoAdjust:
    cld
.NextDigit:
    rol eax,4               ;bring up next four bits
    mov ebx,eax
    and ebx,15              ;make pointer
    lea esi,[NumToString.NumberTable+ebx]
    movsb
    sub ecx,byte 4
    ja .NextDigit
	ret
