;Simple program to test video memory speed verse RAM speed
;It automatically adjust the tests according the computer's speed.
;
;On my system, video writes and reads are five times slower than normal memory.
;Misalignment also makes a very significant difference. Compared to 20 cycles
;when the dwords writes were aligned to even bank boundaries, it took 45
;cycles. For reads it took 60 instead of 36.
;
BITS 32                 ;flat addressing is great!
GLOBAL _WDOSXStart      ;great (free!) extender

TimerAddress	equ 1132	;memory location used to keep track of timer
TestSize        equ 65536/4

SECTION .text
_WDOSXStart:

	mov ax,ds
	mov es,ax

	mov ax,13h		;set video mode 13h
	int 10h			;call video BIOS

	mov edx,PurposeText
	mov ah,9
	int 21h

    xor eax,eax                 ;BIOS function, wait for keypress
    int 16h                     ;call BIOS
    cmp al,27                   ;Escape presssed?
    je near .End                ;yes, so end program

    mov edx,SyncText
	mov ah,9
	int 21h

    mov edx,[TimerAddress]      ;get timer count
.TimerLoop:
    cmp [TimerAddress],edx      ;check timer count
    je .TimerLoop
    xor ebx,ebx
    add edx,37                  ;little more than two seconds ahead of now
.NextMemSync:
    mov esi,TestSpace
    mov ecx,TestSize
    rep lodsd
    mov ecx,[TimerAddress]
    inc ebx
    sub ecx,edx                 ;timer count - expected time >= 37
    jge .EndMemSync
    cmp ecx,-37                 ;check that time didn't wrap from midnight
    jg .NextMemSync
.EndMemSync:
    mov [TestBlocks],ebx

;First test video write
    mov edx,WriteVid
    call PrepMemTest

    mov ebx,[TestBlocks]
    mov eax,4030201h
.NextVidWrite:
    mov edi,0A0000h
    mov ecx,TestSize
    add eax,1010101h
	rep stosd
    dec ebx
    jg .NextVidWrite

	sub edx,[TimerAddress]
	neg edx
	call PrintNumber

;Next test normal memory
    mov edx,WriteMem
    call PrepMemTest

    mov ebx,[TestBlocks]
    mov eax,4030201h
.NextMemWrite:
    mov edi,TestSpace
    mov ecx,TestSize
    add eax,1010101h
	rep stosd
    dec ebx
    jg .NextMemWrite

	sub edx,[TimerAddress]
	neg edx
	call PrintNumber

;Test video read
    mov edx,ReadVid
    call PrepMemTest

    mov ebx,[TestBlocks]
.NextVidRead:
    mov esi,0A0000h
    mov ecx,TestSize
    rep lodsd
    dec ebx
    jg .NextVidRead

	sub edx,[TimerAddress]
	neg edx
	call PrintNumber

;Test normal memory read
    mov edx,ReadMem
    call PrepMemTest

    mov ebx,[TestBlocks]
.NextMemRead:
    mov esi,TestSpace
    mov ecx,TestSize
    rep lodsd
    dec ebx
    jg .NextMemRead

	sub edx,[TimerAddress]
	neg edx
	call PrintNumber

;End dumb little program
    xor eax,eax     ;BIOS function, wait for keypress
	int 16h			;call BIOS
    mov ax,3h       ;reset video mode to text
	int 10h			;call video BIOS
.End:
    mov eax,4C00h
	int 21h

PrepMemTest:
;(edx=message ptr)
    mov ah,9
    int 21h
	cld			;write forwards!
    mov edx,[TimerAddress]      ;get timer count
    ret

PrintNumber:
	mov eax,edx
	mov ebx,10		;base radix of decimal system
	mov ecx,10		;maximum numer size is ten characters
	xor edx,edx		;set top 32 bits to zero
	mov edi,OutputNumber+15
.NextChar:
    div ebx                     ;divide eax:edx by ebx
    add dl,48                   ;make remainder into an ASCII character
    mov [edi],dl                ;output result
    dec edi                     ;move backwards one character
    test eax,eax                ;see if we are done with the number
    jz .FillInBlanks            ;nothing but zeroes left
    xor dl,dl                   ;set edx to zero again for next division
    dec cl                      ;one less character to output
	jnz .NextChar
	jmp short .Output

.FillInBlanks:
    mov al,' '                  ;fill in with spaces
    dec cl                      ;one less than current count
    std                         ;move backwards
    rep stosb                   ;for number of characters remaining
;	jmp short .Output

.Output:
	mov edx,OutputNumber
	mov ah,9
	int 21h
	ret

align 4
TestBlocks:     dd 200 ;good number for my system, 25Mhz 386
PurposeText:    db 'Press any key to compare video memory   speed verse normal memory (to see how   much slower video memory is).',13,10,10,'$'
SyncText:       db 'Adjusting test to computer speed.',13,10,'$'
ReadVid:        db 'Reading from video...',13,10,'$'
ReadMem:        db 'Reading from RAM...',13,10,'$'
WriteVid:       db 'Writing to video...',13,10,'$'
WriteMem:       db 'Writing to RAM...',13,10,'$'
OutputNumber:	db '0123456789012345 clicks',13,10,'$'

SECTION .bss

TestSpace:	resb 65536
