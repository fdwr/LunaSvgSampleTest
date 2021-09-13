'1999.8.14

BITS 16
ORG 100h

SECTION .text

GetPortNumber:
        cmp byte [80],1
        jbe .NoPortGiven
        mov si,82h
        xor dx,dx
        mov cx,3
        cld
.NextDigit:
        lodsb
        cmp al,'0'
        jb .End
        cmp al,'9'
        ja .NotNumeric
        sub al,'0'
        jmp .AddDigit
.NotNumeric:
        and al,~32
        cmp al,'A'
        jb .End
        cmp al,'Z'
        ja .End
        sub al,'A'-10
.AddDigit:
        shl dx,4
        or dl,al
        dec cx
        jns .NextDigit
.End:
        cmp cx,3
        jb .PortGiven
.NoPortGiven:
        mov dx,HelpMessage
        mov ah,9
        int 21h
        jmp EndProgram
.PortGiven:

        mov ax,13h              ;simple graphics
        int 10h

DrawPortLines:
        mov ax,0A000h
        mov ds,ax
        mov es,ax
        cld

        xor bx,bx
.StartAtTop:
        xor di,di
        mov si,199
.NextLine:
        mov cx,320/4
        xor eax,eax
        rep stosd
        in al,dx
        mov bx,ax
        mov byte [bx+di-320],9
        dec si
        jns .NextLine
	mov ah,1                ;function to check key buffer status
	int 16h                 ;call BIOS
        jz .StartAtTop          ;zero flag is set, no keys are in buffer
        xor ax,ax               ;waste last keypress
	int 16h                 ;call BIOS

RestoreVideo:
        mov ax,3h               ;restore text mode
        int 10h

EndProgram:
        push cs
        pop ds
        mov ax,4C00h
        int 21h

HelpMessage:
        db "Tiny port data graphics viewer .001",13,10,"By Dwayne Robinson, 1 Aug 1999",13,10,10,"Usage: PORTVIEW hexportnumber",13,10,"$"
