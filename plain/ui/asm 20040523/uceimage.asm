;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
ImageCode:
    cmp al,Msg.Redraw
    stc
    jne .Ignore

.Draw:
    ;test dword [ebx+ImageObj.Flags],ImageObj.Transparent
    mov esi,[ebx+ImageObj.ImagePtr]
    push dword [esi+ImageStruct.TransColor]
    push esi                    ;pixels
    push dword [esi+ImageStruct.Size]
    push dword 0                ;left column/top row
    call DrawImageTrans
    add esp,byte 16
    ;clc ;add clears cf
.Ignore:
    ret
