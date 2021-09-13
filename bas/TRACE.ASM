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

	mov ax,[9*4]			;get current key handler location
	mov [cs:KeyHandler],ax		;store location
	mov ax,[9*4+2]
	mov [cs:KeyHandler+2],ax

	cli
	mov word [9*4],CheckKeys	;grab keypresses
	mov [9*4+2],cs
	mov word [1*4],BreakPoint	;output status
	mov [1*4+2],cs
	sti

;	mov ax,2501h	;DOS function 25h, set interrupt 1 (single step)
;	mov dx,BreakPoint		;single step handler
;	int 21h
	mov dx,EndOfProgram		;get total number of bytes in prog
	int 27h		;give up control but stay resident in memory (TSR)

CheckKeys:		;called before BIOS whenever a key is pressed
;	push bp
;	mov bp,sp
;	xor word [bp+8],8	;toggle instruction stepping on or off
;	pop bp
	mov [cs:TempReg],ax
	cld
	in al,60h		;read keyboard signal
	cmp al,2Ah		;compare to Shift
	jz ClearText
	cmp al,1Dh		;compare to Ctrl
	jnz AnyOtherKey
	push es			;save vars!
	push di
	push cx
	mov ax,0A000h		;video screen segment
	mov es,ax
	xor di,di		;set destination to zero to start at top left
	mov cx,64000/2		;320x200 pixels on screen
	mov ax,8888h		;two pixels of color index 128
	rep stosw		;blast pixels
	jmp RestoreRegs
    ClearText:
	push ds
	xor ax,ax
	mov ds,ax
	mov word [1*4],BreakPoint
	mov [1*4+2],cs
	pop ds
	pop ax
	xor ax,256
	push ax
	jmp AnyOtherKey
	push es
	push di
	push cx
	mov ax,0B800h		;text screen segment
	mov es,ax
	xor di,di		;set destination to zero to start at top left
	mov cx,2000		;80x25 chars on screen
	mov ax,((3*16)<<8)+176	;ASCII character 187, bg color 3
	rep stosw		;blast chars to text screen
    RestoreRegs:	
	pop cx			;restore vars!
	pop di
	pop es
    AnyOtherKey:
	mov ax,[cs:TempReg]
	jmp far [cs:KeyHandler]	;pass key to BIOS

BreakPoint:
	push ds
	push eax
	push di
	mov ax,0B800h
	mov ds,ax
	xor di,di
	;lds di,[cs:ScreenBase]
	mov eax,[cs:InstructionCounter]
	mov [di],eax
	inc dword [cs:InstructionCounter]
	pop di
	pop eax
	pop ds
	iret

section .data

ScreenBase: dw 0,0B800h
InstructionCounter: dw 0
KeyHandler: dw 0,0FFFFh
WasActive: dw 0,0FFFFh
TraceToggle: db 0
TempReg: dw 0,0

EndOfProgram: