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
;	bits 32
;	db 66h
	mov bx,0F10h
	xor edx,edx
;	mov ds,bx
	mov esi,0200h
	mov edx,[esi]
	bits 16
	mov bx,0B800h
	mov ds,bx
	xor bx,bx
	mov [bx],edx
	xor edx,edx
	mov edx,[esi+4]
	mov bx,0B800h
	mov ds,bx
	mov bx,4
	mov [bx],edx
	xor al,1
	mov cr0,eax
	
	mov ax,4C00H
	int 21H