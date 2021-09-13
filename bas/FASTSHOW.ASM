;used to read an abslute memory address anywhere, including beyond the stupid
;first megabyte boundary by using 32bit registers for addressing and display
;it to the text screen

;parameters passed onto it include:
;
;address&  simply a thirty bit zero-based address
;value&    the value to be returned

	bits 16
	org 0

	push ds
	push es
	push bp
	mov bp,sp

	xor di,di
	mov ax,0B800h
	mov ds,ax
	
	xor ax,ax
	mov es,ax
	mov esi,[bp+10]
	
	mov cx,24*80/4
	cld     
	
anotherbyte:
	;mov es,dx
	mov eax,[es:esi]
	add esi,4
	;mov dx,es
	;mov 
	;mov [,0B800h
	mov [ds:di],eax
	add di,4
	;stosb
	dec cx
	jnz anotherbyte
	;mov esi,[bp+10]
	;mov eax,[es:esi]
	;les di,[bp+14]
	;mov [es:di],eax

	pop bp
	pop es
	pop ds

	retf 4