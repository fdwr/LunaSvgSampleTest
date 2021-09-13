BITS 32                         ;flat addressing is great!

SECTION .text
GLOBAL _WdosxStart              ;great (free!) extender

_WdosxStart:
    push ds
    pop es

    mov eax,13h
    int 10h
    mov eax,21h
    ;xor eax,eax
    int 33h
    cmp ax,0FFFFh
    jne near EndProgram

    call ClearScreen

.NotEscape:
    mov eax,3
    int 33h
    test ebx,2
    jnz .EndLoop
    mov eax,0Bh                 ;read for motion counters
    int 33h
    add cx,[Cursor.FineCol]
    add dx,[Cursor.FineRow]
    mov [Cursor.FineCol],cx
    mov [Cursor.FineRow],dx
    sar cx,2                    ;/4
    sar dx,2

    push cx
    push dx
    call ClearCursorImage
    pop word [Cursor.Row]
    pop word [Cursor.Col]
    call DrawCursorImage

    mov ecx,65536/30    ;delay for 1/30th of a second
    in al,61h
    and al,10h          ;mask bit 4
    mov ah,al
.CheckAgain:
    in al,61h
    and al,10h
    cmp al,ah
    jz .CheckAgain      ;no change so loop back
    mov ah,al
    dec ecx
    jnz .CheckAgain

    mov ah,1
    int 16h
    jz .NotEscape
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
    jne .NotEscape
.EndLoop:

EndProgram:
    mov eax,3
    int 10h
    mov eax,4C00h
    int 21h

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
    jns .RowOkayTop
    cmp eax,-Cursor.Size
    jbe .RowOffscreen
    add ecx,eax
    shl eax,4                   ;depends on cursor size
    xor edi,edi
    sub esi,eax
    jmp short .RowOkayBottom
.RowOffscreen:
    ret
.RowOkayTop:
    mov edx,eax
    mov edi,eax
    shl edx,6
    shl edi,8
    add edi,edx
    sub eax,Display.Height-Cursor.Size
    jbe .RowOkayBottom
    cmp eax,Cursor.Size
    jae .RowOffscreen
    sub ecx,eax
.RowOkayBottom:

    mov edx,Cursor.Size
    test ebx,ebx
    jns .ColOkayLeft
    cmp ebx,-Cursor.Size
    jbe .End
    sub esi,ebx
    add edx,ebx
    jmp short .ColOkayRight
.ColOkayLeft:
    add edi,ebx
    sub ebx,Display.Width-Cursor.Size
    jbe .ColOkayRight
    cmp ebx,Cursor.Size
    jae .End
    sub edx,ebx
.ColOkayRight:

    cmp ecx,Cursor.Size
    ja near Err
    cmp edx,Cursor.Size
    ja near Err

    ;add edx,byte 3
    ;shr edx,2                   ;/4 for dwords
    mov ebx,Display.Width
    sub ebx,edx                 ;get DisplayWidth - ColumnsWide
    mov eax,Cursor.Size
    sub eax,edx                 ;get CursorSize - ColumnsWide

    ;add edi,0A0000h
    push eax
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
    mov eax,07070707h
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
    mov eax,07070707h
    mov ecx,(Display.Height*Display.Width)/4
    mov edi,0A0000h
    rep stosd
    ret

Err:
    int3;
    ret

section .data

Cursor:
.Size       equ 16
.Position:
.Row:       dw 0
.Col:       dw 0
.RowOffset: dw 0
.ColOffset: dw 0
.FineRow:   dw (Display.Height / 2) * .Scaling
.FineCol:   dw (Display.Width  / 2) * .Scaling
.Scaling    equ 4
.Image:     incbin "cursors.lbm"

Display:
.Width      equ 320
.Height     equ 200
