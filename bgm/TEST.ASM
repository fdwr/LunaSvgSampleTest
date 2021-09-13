BITS 32
GLOBAL _WdosxStart
SECTION .text

_WdosxStart:
push ds
pop es

mov ax,13h
int 10h

cld
mov edi,ScreenBuffer
xor eax,eax
mov ecx,64000/4
rep stosd

xor ebx,ebx
.NextDot:
mov byte [ScreenBuffer+ebx],0
add ebx,321
cmp ebx,64000
jb .DotInBuffer
sub ebx,64000
.DotInBuffer:
mov byte [ScreenBuffer+ebx],15
cld
mov esi,ScreenBuffer
mov edi,0A0000h
mov ecx,64000/4
rep movsd
mov ah,1
int 16h
jz .NextDot

mov ah,4Ch
int 21h

section .bss
ScreenBuffer:   resb 64000
