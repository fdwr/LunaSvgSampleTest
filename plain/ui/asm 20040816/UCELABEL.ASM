;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
LabelCode:
    cmp al,Msg.Redraw
    stc
    jne .Ignore

.Draw:
    ; determine left column based on alignment
    ;push dword 0 ; *** not done

    ; draw text string
    mov dword [Font.Colors],GuiClrTxtNormal
    push dword [ebx+LabelObj.TextLen]
    push dword [ebx+LabelObj.TextPtr]
    push dword 0                ;left column/top row
    call BlitString
    add esp,byte 12
    ;clc ;add clears cf
.Ignore:
    ret
