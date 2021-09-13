;used to read an abslute memory address anywhere, including beyond the stupid
;first megabyte boundary by using 32bit registers for addressing

;parameters passed onto it include:
;
;address&  simply a thirty bit zero-based address
;value&    the variable to hold whatever data my be at 'address'

        bits 16
        org 100

	;push ds
	;push es
	;push bp
	;mov bp,sp

	mov eax,cr0
	or al,1
	mov cr0,eax
	bits 32
	mov bx,16
	mov ds,bx
	xor di,di
	mov bx,0B800h
	mov es,bx
	mov esi,0200h
	mov ecx,100
another4bytes:
	mov edx,[esi]
;	mov [es:di],edx
;	add esi,4
;	add di,4	
	dec ecx
	dec cx
	dec ecx
;	jnz another4bytes
	
	xor al,1
	mov cr0,eax
	bits 16

	mov ax,4C00H
	int 21H