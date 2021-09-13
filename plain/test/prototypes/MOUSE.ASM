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
    ;xor eax,eax
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

.NotEscape:
    mov eax,3                   ;get button status
    int 33h
    mov eax,0Bh                 ;read motion counters
    int 33h
    add cx,[Cursor.FineCol]
    add dx,[Cursor.FineRow]
    mov [Cursor.FineCol],cx
    mov [Cursor.FineRow],dx
    sar cx,2                    ;/4
    sar dx,2
    shl ecx,16
    mov cx,dx

    push ecx                    ;save row/col
    push ebx                    ;save buttons
    movzx eax,dx                ;get row
    mov edi,Text.MouseInfo
    call NumToString
    movzx eax,word [esp+6]      ;get column
    mov edi,Text.MouseInfo+6
    call NumToString
    pop edx                     ;get buttons
    mov ebx,2                   ;binary format
    mov ecx,8                   ;eight bits
    movzx eax,dx
    mov edi,Text.MouseInfo+12
    call NumToString.AnyRadix

    call ClearCursorImage
    pop dword [Cursor.Position]
    call DrawCursorImage

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
%if 0
    cmp al,'+'
    jne .NotColInc
    inc word [Cursor.Col]
.NotColInc:
    cmp al,'-'
    jne .NotColDec
    dec word [Cursor.Col]
.NotColDec:
    cmp al,'*'
    jne .NotRowInc
    inc word [Cursor.Row]
.NotRowInc:
    cmp al,'/'
    jne .NotRowDec
    dec word [Cursor.Row]
.NotRowDec:
%endif
    cmp al,27
    jne near .NotEscape
.EndLoop:

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


DrawCursorImage:
    mov esi,Cursor.Image
    mov eax,[Cursor.Position]
    shld ebx,eax,16
    add ax,[Cursor.RowOffset]
    add bx,[Cursor.ColOffset]
    movsx eax,ax
    movsx ebx,bx

    mov ecx,Cursor.Size
    test eax,eax
    jns .TopOk
    cmp eax,-Cursor.Size
    jbe .RowOffscreen
    add ecx,eax
    shl eax,4                   ;depends on cursor size
    xor edi,edi
    sub esi,eax
    jmp short .BtmOk
.RowOffscreen:
    ret
.TopOk:
    mov edx,eax
    mov edi,eax
    shl edx,6
    shl edi,8
    add edi,edx
    sub eax,Display.Height-Cursor.Size
    jbe .BtmOk
    cmp eax,Cursor.Size
    jae .RowOffscreen           ;!!! <- optimize
    sub ecx,eax
.BtmOk:

    mov edx,Cursor.Size
    test ebx,ebx
    jns .LeftOk
    cmp ebx,-Cursor.Size
    jbe .End
    sub esi,ebx
    add edx,ebx
    jmp short .RightOk
.LeftOk:
    add edi,ebx
    sub ebx,Display.Width-Cursor.Size
    jbe .RightOk
    cmp ebx,Cursor.Size
    jae .End
    sub edx,ebx
.RightOk:

    cmp ecx,Cursor.Size
    ja near Err
    cmp edx,Cursor.Size
    ja near Err

    ;add edx,byte 3
    ;shr edx,2                   ;/4 for dwords
    mov ebx,Display.Width
    sub ebx,edx                 ;get DisplayWidth - ColumnsWide
    mov eax,Cursor.Size
    sub eax,edx                 ;get CursorSize - ColumnsWide for source increment

    ;add edi,0A0000h
    push eax                    ;save source increment
    push edx                    ;save columns count
    ;mov al,32
.NextDot:
    cmp edi,Display.Height*Display.Width
    jae near Err
    mov al,[0A0000h+edi]
    and al,0                    ;...
    or al,[esi]
    mov [0A0000h+edi],al
    inc esi
    inc edi
    dec edx                     ;one less column
    jnz .NextDot
    add esi,[esp+4]
    add edi,ebx
    mov edx,[esp]               ;reset columns count
    dec ecx                     ;one less row
    jnz .NextDot
    add esp,byte 8

.End:
    ret

ClearCursorImage:
    mov eax,[Cursor.Position]
    shld ebx,eax,16
    add ax,[Cursor.RowOffset]
    add bx,[Cursor.ColOffset]
    movsx eax,ax
    movsx ebx,bx

    test eax,eax
    jns .RowOkayTop
    xor eax,eax
    xor edi,edi
    jmp short .RowOkay
.RowOkayTop:
    cmp eax,Display.Height-Cursor.Size
    jb .RowOkayBtm
    mov eax,Display.Height-Cursor.Size
.RowOkayBtm:
    mov edx,eax
    mov edi,eax
    shl edx,6
    shl edi,8
    add edi,edx
.RowOkay:
    test ebx,ebx
    jns .ColOkayLeft
    xor ebx,ebx
    jmp short .ColOkay
.ColOkayLeft:
    cmp ebx,Display.Width-Cursor.Size
    jb .ColOkayRight
    mov ebx,Display.Width-Cursor.Size
.ColOkayRight:
    add edi,ebx
.ColOkay:

    cld
    mov eax,08080808h
    mov edx,Cursor.Size
    cmp edi,Display.Height*Display.Width
    jae Err
    add edi,0A0000h
.NextRow:
    mov ecx,Cursor.Size/4
    rep stosd
    add edi,Display.Width-Cursor.Size
    dec edx
    jnz .NextRow
    ret

ClearScreen:
    cld
    xor eax,eax
    mov ecx,(Display.Height*Display.Width)/4
    mov edi,0A0000h
    rep stosd
    ret

Err:
    int3;
    ret

section data

Cursor:
.Size       equ 16
.Position:
.Row:       dw 0
.Col:       dw 0
.RowOffset: dw 0
.ColOffset: dw -15
.FineRow:   dw (Display.Height / 2) * .Scaling
.FineCol:   dw (Display.Width  / 2) * .Scaling
.Scaling    equ 4
.Image:     incbin "cursors.lbm",0,256

Text:
.MouseMsg:      db "Row/Col/Buttons "
.MouseInfo:     db "xxxxx:xxxxx:xxxxxxxx ",13,"$"
.NoMouseDriver: db "No mouse driver",13,"$"

Display:
.Width      equ 320
.Height     equ 200
