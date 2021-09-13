;used to test how Qb passes parameters, since the documentation is not too
;helpful. Currently I am have some problems with an asm call and will use
;this to debug what in the world is going on!!

	bits 16
	org 0
	
Section .text
	call next
next	pop ax
	
	push ds
	push bp
	mov bp,sp
	
	lds bx,[bp+8]
	mov [bx],ax
	push cs
	pop word [bx+2]
	push ds
	pop word [bx+4]
	push es
	pop word [bx+6]
	push ss
	pop word [bx+8]
	push fs
	pop word [bx+10]
	push gs
	pop word [bx+12]
	
	pop bp
	pop ds
	retf 4