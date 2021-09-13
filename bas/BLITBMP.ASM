;Bitmap blitter for Qbasic program (CNVRTBMP.BAS)
;
;By FDR on 4-6-98
;extra 32bit speed added on 5-9-98
;
;Accepts the parameters
;  sourceseg%, source%, height%, width%, toprow%, leftcol%
;
;  sourceseg is the segment of the source bitmap
;  source points to the bitmap tp be shown
;  height and width are pretty easy to guess
;  toprow is the row on screen to show the top row of the bitmap
;  leftcol is the same as toprow except it aligns the left column

	BITS 16
	ORG 0
	
        push ds         ;save all necessary segments and base pointer
	push es
	push bp
        mov bp,sp       ;copy stack pointer to base pointer to set up stack
                        ;for positive ofset references to all parameters
	
	mov ax,0A000h
	mov es,ax       ;set extra segment (destination) to screen
	mov ax,[bp+10]   ;get segment for source, six bytes from base pointer
	mov ds,ax       ;set data segment (source) to bitmap
	mov si,[bp+12]   ;add ofset from segment to existing pixel ofset

	;junk testing code below
;	mov ax,[bp+10]
;	mov [es:0],ax
;	mov ax,[bp+12]
;	mov [es:2],ax
;	mov ax,[bp+14]
;	mov [es:4],ax
;	mov ax,[bp+16]
;	mov [es:6],ax
;	jmp endblit
	;back to the real code

	mov bx,[bp+14]  ;move height into BX
	mov dx,[bp+16]  ;move width into BX
	mov di,[bp+18]  ;get toprow and put into destination
	mov ax,di       ;copy toprow from DI (destination) to AX
	shl di,8        ;shift toprow right in DI (multiply by 2^8, 256)
	shl ax,6        ;shift toprow right in AX (multiply by 2^6, 64)
 	add di,ax       ;add AX to DI (essentially multiplying by 320, 256+64)
	add di,[bp+20]  ;add leftcol to DI to get pixel ofset
	mov bp, 320
	sub bp,dx
	shl dx,6
	shr dl,6

blitnextrow:
	mov cx,dx
	shr cx,8
	rep movsd
	mov cx,dx
	xor ch,ch
	rep movsb
	add di,bp
	dec bx
	jnz blitnextrow
	
endcode	pop bp		;restore segments and base pointer for Qbasic
	pop es		;unless you want Qb to crash
	pop ds

	retf 12		;return far and reduce stack by the number of
			;parameters passed on to it times two (6*2=12)

;blitnextrow:
;	mov cx,dx
;	shr cx,8
;blitnextpixel:
;	mov al,[si]
;	inc si
;	mov [es:di],al
;	inc di
;	dec ch
;	jnz blitnextpixel
;	add di,bp
;	dec bx
;	jnz blitnextrow