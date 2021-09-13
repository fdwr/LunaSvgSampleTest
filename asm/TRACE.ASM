;TRACE.COM by FDwR, 5-28-98
;used to trace slowly through DOS programs to see how they work

;set trace break to this program by using DOS set interrupt
;turn on breakpoint
;terminate and stay resident

	bits 16
	org 100h

	;mov ax,3509h	;DOS function 35h, get interrupt 9 (BIOS key handler)
	;int 21h
	;mov [KeyHandler],bx		;store BIOS offset
	;mov [KeyHandler+2],es		;store BIOS segment
	;mov dx,BorrowedKeys		;check key presses before BIOS
	;mov bx,dx
	;mov ax,cs
	;mov ds,ax
	;mov es,ax
	;mov ax,2509h	;DOS function 25h, set interrupt 9 (key interrupt)
	;int 21h
	xor ax,ax
	mov ds,ax

	mov ax,[9*4]
	mov [cs:KeyHandler],ax
	mov ax,[9*4+2]
	mov [cs:KeyHandler+2],ax

	cli
	mov word [9*4],BorrowedKeys	;grab keypresses
	mov [9*4+2],cs
	mov word [1*4],BreakPoint	;output status
	mov [1*4+2],cs
	sti

;	mov ax,2501h	;DOS function 25h, set interrupt 1 (single step)
;	mov dx,BreakPoint		;single step handler
;	int 21h
	mov dx,EndOfProgram		;get total number of bytes in prog
	int 27h		;give up control but stay resident in memory (TSR)

BorrowedKeys:		;called before BIOS whenever a key is pressed
;	push bp
;	mov bp,sp
;	xor word [bp+8],8	;toggle instruction stepping on or off
;	pop bp
	push ax
	push es
	push di
	push cx
	in al,60h
	cmp al,2Ah
	jz ClearText
	cmp al,1Dh
	jnz AnyOtherKey
	mov ax,0A000h
	mov es,ax
	xor di,di
	mov cx,32768
	mov ax,(15<<8)+15
	rep stosw
	jmp AnyOtherKey
    ClearText:
	mov ax,0B800h
	mov es,ax
	xor di,di
	mov cx,2000
	mov ax,((3*16)<<8)+176
	rep stosw
    AnyOtherKey:
	pop cx
	pop di
	pop es
	pop ax
	jmp far [cs:KeyHandler]	;pass key to BIOS

BreakPoint:
	push ds
	push ax
	push di
	mov ax,0B800h
	mov ds,ax
	xor di,di
	;lds di,[cs:ScreenBase]
	mov ax,[cs:InstructionCounter]
	mov [di],ax
	inc word [cs:InstructionCounter]
	pop di
	pop ax
	pop ds
	iret

section .data

ScreenBase: dw 0,0B800h
InstructionCounter: dw 0
KeyHandler: dw 0,0FFFFh
WasActive: dw 0,0FFFFh
TraceToggle: db 0

EndOfProgram: