BITS 32                         ;flat addressing is great!

section code
GLOBAL _WdosxStart              ;great (free!) extender

NumStringMaxLen     equ 5

_WdosxStart:
    push ds
    pop es

    mov eax,13h
    int 10h
    mov eax,21h                 ;reset mouse software
    int 33h
    cmp ax,0FFFFh
    je .MousePresent
    mov ah,9
    mov edx,Text.NoMouseDriver
    int 21h
    xor eax,eax
    int 16h
    jmp EndProgram
.MousePresent:

    call ClearScreen
    mov eax,4                   ;set cursor position
    xor ecx,ecx
    xor edx,edx
    int 33h
    mov eax,1Ah                 ;set sensitivity
    mov bx,90
    mov cx,90
    mov dx,65530
    int 33h

    mov eax,1                   ;show mouse cursor
    int 33h

.NotEscape:
    mov eax,3                   ;get button status
    int 33h
    shr cx,1
    mov [Cursor.Row],dx
    mov [Cursor.Col],cx
    mov [Cursor.Buttons],bl     ;save buttons

    ;mov eax,1Bh                 ;get sensitivity
    ;int 33h
    ;mov [Cursor.Row],bx
    ;mov [Cursor.Col],cx

    mov eax,0Bh                 ;read motion counters
    int 33h
    add cx,[Cursor.FineCol]
    add dx,[Cursor.FineRow]
    mov [Cursor.FineCol],cx
    mov [Cursor.FineRow],dx
    ;sar cx,2                    ;/4
    ;sar dx,2
    ;mov [Cursor.Row],dx
    ;mov [Cursor.Col],cx

    movzx eax,word [Cursor.Row] ;get row
    mov edi,Text.MouseInfo
    call NumToString
    movzx eax,word [Cursor.Col] ;get column
    mov edi,Text.MouseInfo+6
    call NumToString
    movzx eax,word [Cursor.FineRow] ;get fine row
    shr eax,1
    mov edi,Text.MouseInfo+12
    call NumToString
    movzx eax,word [Cursor.FineCol] ;get fine column
    shr eax,1
    mov edi,Text.MouseInfo+18
    call NumToString
    mov al,[Cursor.Buttons]
    mov ebx,2                   ;binary format
    mov ecx,8                   ;eight bits
    mov edi,Text.MouseInfo+24
    call NumToString.AnyRadix

    mov ah,9
    mov edx,Text.MouseMsg
    int 21h

    mov ecx,65536/30            ;delay for 1/30th of a second
    in al,61h
    and al,10h                  ;mask bit 4
    mov ah,al
.DelayLoop:
    in al,61h
    and al,10h
    cmp al,ah
    jz .DelayLoop               ;no change so loop back
    mov ah,al
    dec ecx
    jnz .DelayLoop

    mov ah,1
    int 16h
    jz near .NotEscape
    xor eax,eax
    int 16h
    cmp al,27
    jne near .NotEscape
.EndLoop:

    mov eax,2                   ;hide cursor
    int 33h

EndProgram:
    mov eax,3
    int 10h
    mov eax,4C00h
    int 21h


NumToString:
    mov ecx,NumStringMaxLen
.AnyLength:                     ;since the largest 32bit is 4gb
    mov ebx,10              ;base of the decimal system
.AnyRadix:                      ;for hexadecimal and binary (even octal)
    xor edx,edx             ;set top 32 bits of quotient to zero
    lea edi,[edi+ecx-1]     ;start from rightmost character in number
.NextChar:
    div ebx                 ;divide number by the decimal base
    ;mov dl,[.CharTable+edx] ;get ASCII character from table
    add dl,48              ;make remainder into an ASCII character
    mov [edi],dl            ;output result
    dec edi                 ;move backwards one character
    test eax,eax            ;see if we are done with the number
    jz .FillInBlanks        ;nothing but zeroes left
    xor edx,edx             ;set edx to zero again for next division
    dec ecx                 ;one less character to output
    jnz .NextChar
    ret

.FillInBlanks:
    mov al,[.FillChar]      ;fill in with spaces or zeroes
    dec ecx                 ;one less than current count
    mov edx,ecx
    std                     ;move backwards
    rep stosb               ;for number of characters remaining
    mov ecx,edx
    ret

.FillChar:      db ' '

ClearScreen:
    cld
    xor eax,eax
    mov ecx,(Display.Height*Display.Width)/4
    mov edi,0A0000h
    rep stosd
    ret

section data

Cursor:
.Size       equ 16
.Position:
.Row:       dw 0
.Col:       dw 0
.RowOffset: dw 0
.ColOffset: dw -15
.FineRow:   dw 0;(Display.Height / 2); * .Scaling
.FineCol:   dw 0;(Display.Width  / 2); * .Scaling
.Buttons:   dd 0
.Scaling    equ 4

Text:
.MouseMsg:      ;db "Row/Col/Buttons "
.MouseInfo:     db "xxxxx:xxxxx,xxxxx:xxxxx,xxxxxxxx ",13,"$"
.NoMouseDriver: db "No mouse driver",13,"$"

Display:
.Width      equ 320
.Height     equ 200
