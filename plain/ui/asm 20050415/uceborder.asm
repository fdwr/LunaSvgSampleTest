;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
BorderCode:
    cmp al,Msg.Redraw
    stc
    jne .Ignore

.Draw:
    ; (words height, width, mode)
    push dword DrawBorder.Concave
    push dword [ebx+GuiObj.Size]
    push dword 0
    call DrawBorder
    add esp,byte 12
    ;clc ;add clears cf
.Ignore:
    ret
