ORG 100h

Main:
mov dx,di       ;save di
mov ax,0B800h
mov es,ax

mov ah,15       ;set color to white
mov cx,4
mov di,200h
.NextChar
rol dx,4
mov bx,dx
and bx,15
mov al,[NumberTable+bx]
stosw
dec cx
jnz .NextChar

ret

NumberTable:    db "0123456789ABCDEF"
