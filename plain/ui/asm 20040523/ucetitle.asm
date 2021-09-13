;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
TitleBarCode:

section data
    StartMsgJtbl
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.Focus,.ItemFocus
    AddMsgJtbl Msg.MousePrsRls,WindowBgCode.MousePrsRls
    AddMsgJtbl Msg.MouseMove,WindowBgCode.MouseMove
    AddMsgJtbl Msg.MouseIn,SetCursorImage.Default
    AddMsgJtbl Msg.MouseOut,CommonItemCode.ReleaseMouse

.ButtonInc:      dd 0
.ColorMapDim:    dw GuiClrPurple,GuiClrGray,GuiClrDGray,GuiClrLGray
.ColorMapBright: dw GuiClrLPurple,GuiClrLGray,GuiClrGray,GuiClrWhite

%ifdef UseSmallScreen
.CloseImg:  db 1,2,1,0,1,2,1 ;"X"
            db 2,3,2,1,2,3,2
            db 1,2,3,2,3,2,1
            db 0,1,2,3,2,1,0
            db 1,2,3,2,3,2,1
            db 2,3,2,1,2,3,2
            db 1,2,1,0,1,2,1
.HelpImg:   db 0,1,2,2,2,1,0 ;"?"
            db 1,2,3,3,3,2,1
            db 2,3,2,2,2,3,2
            db 1,2,2,3,3,2,1
            db 0,0,1,2,2,1,0
            db 0,0,2,3,2,0,0
            db 0,0,1,2,1,0,0
.MaxImg:    db 0,0,1,2,1,0,0 ;"<<"
            db 0,1,2,3,2,1,0
            db 1,2,3,2,3,2,1
            db 2,3,2,3,2,3,2
            db 1,2,3,2,3,2,1
            db 2,3,2,1,2,3,2
            db 1,2,1,0,1,2,1
.MinImg:    db 1,2,1,0,1,2,1
            db 2,3,2,1,2,3,2
            db 1,2,3,2,3,2,1
            db 2,3,2,3,2,3,2
            db 1,2,3,2,3,2,1
            db 0,1,2,3,2,1,0
            db 0,0,1,2,1,0,0 ;">>"
%else
.CloseImg:  db 0,1,2,2,1,0,0,0,0,1,2,2,1,0 ;"X"
            db 1,2,2,2,2,1,0,0,1,2,2,2,2,1
            db 2,2,1,3,2,2,1,1,2,2,3,1,2,2
            db 2,2,3,3,3,2,2,2,2,3,3,3,2,2
            db 1,2,2,3,3,3,2,2,3,3,3,2,2,1
            db 0,1,2,2,3,3,3,3,3,3,2,2,1,0
            db 0,0,1,2,2,3,3,3,3,2,2,1,0,0
            db 0,0,1,2,2,3,3,3,3,2,2,1,0,0
            db 0,1,2,2,3,3,3,3,3,3,2,2,1,0
            db 1,2,2,3,3,3,2,2,3,3,3,2,2,1
            db 2,2,3,3,3,2,2,2,2,3,3,3,2,2
            db 2,2,1,3,2,2,1,1,2,2,3,1,2,2
            db 1,2,2,2,2,1,0,0,1,2,2,2,2,1
            db 0,1,2,2,1,0,0,0,0,1,2,2,1,0
.HelpImg:   db 0,0,1,2,2,2,2,2,2,2,2,1,0,0 ;"?"
            db 0,1,2,2,2,2,2,2,2,2,2,2,1,0
            db 1,2,2,3,3,3,3,3,3,3,3,2,2,1
            db 2,2,3,3,3,3,3,3,3,3,3,3,2,2
            db 2,2,3,3,2,2,2,2,2,2,3,3,2,2
            db 2,2,3,3,2,2,2,2,2,2,3,3,2,2
            db 1,2,2,2,2,2,3,3,3,3,3,3,2,2
            db 0,1,2,2,2,2,3,3,3,3,3,2,2,1
            db 0,0,0,0,1,2,2,2,2,2,2,2,1,0
            db 0,0,0,0,1,2,2,2,2,2,2,1,0,0
            db 0,0,0,0,2,2,3,3,2,2,0,0,0,0
            db 0,0,0,0,2,2,3,3,2,2,0,0,0,0
            db 0,0,0,0,1,2,2,2,2,1,0,0,0,0
            db 0,0,0,0,0,1,2,2,1,0,0,0,0,0
.MaxImg:    db 0,0,0,0,0,1,2,2,1,0,0,0,0,0 ;"<<"
            db 0,0,0,0,1,2,2,2,2,1,0,0,0,0
            db 0,0,0,1,2,2,3,3,2,2,1,0,0,0
            db 0,0,1,2,2,3,3,3,3,2,2,1,0,0
            db 0,1,2,2,3,3,3,3,3,3,2,2,1,0
            db 1,2,2,3,3,3,2,2,3,3,3,2,2,1
            db 2,2,3,3,3,2,3,3,2,3,3,3,2,2
            db 2,2,1,3,2,3,3,3,3,2,3,1,2,2
            db 1,2,2,2,3,3,3,3,3,3,2,2,2,1
            db 1,2,2,3,3,3,2,2,3,3,3,2,2,1
            db 2,2,3,3,3,2,2,2,2,3,3,3,2,2
            db 2,2,1,3,2,2,1,1,2,2,3,1,2,2
            db 1,2,2,2,2,1,0,0,1,2,2,2,2,1
            db 0,1,2,2,1,0,0,0,0,1,2,2,1,0
.MinImg:    db 0,1,2,2,1,0,0,0,0,1,2,2,1,0 ;">>"
            db 1,2,2,2,2,1,0,0,1,2,2,2,2,1
            db 2,2,1,3,2,2,1,1,2,2,3,1,2,2
            db 2,2,3,3,3,2,2,2,2,3,3,3,2,2
            db 1,2,2,3,3,3,2,2,3,3,3,2,2,1
            db 1,2,2,2,3,3,3,3,3,3,2,2,2,1
            db 2,2,1,3,2,3,3,3,3,2,3,1,2,2
            db 2,2,3,3,3,2,3,3,2,3,3,3,2,2
            db 1,2,2,3,3,3,2,2,3,3,3,2,2,1
            db 0,1,2,2,3,3,3,3,3,3,2,2,1,0
            db 0,0,1,2,2,3,3,3,3,2,2,1,0,0
            db 0,0,0,1,2,2,3,3,2,2,1,0,0,0
            db 0,0,0,0,1,2,2,2,2,1,0,0,0,0
            db 0,0,0,0,0,1,2,2,1,0,0,0,0,0
%endif

.ColorMap:  equ CommonItemCode.ColorMap
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.Draw:
    push ebp
    mov ebp,esp
    mov eax,GuiClrPurple
    mov ecx,GuiClrTxtNormal ;GuiClrTxtDim
    mov edx,.ColorMapDim
    test dword [ebx+GuiObj.Flags],GuiObj.ContainerFocus ;|GuiObj.GroupFocus|GuiObj.ItemFocus
    jnz .DrawInactive
    test byte [ebx+TitleBarObj.Flags],TitleBarObj.GroupIndicate
    jz .DrawActive
    test dword [ebx+GuiObj.Flags],GuiObj.GroupFocus
    jnz .DrawInactive
.DrawActive:
    mov eax,GuiClrLPurple
    mov ecx,GuiClrTxtBright
    mov edx,.ColorMapBright
.DrawInactive:

    mov ebx,[ebx+GuiObj.Size]
    push eax                    ;bar color (affected by focus)
    mov [Font.Colors],ecx
    mov [.ColorMap],edx
    push ebx

;+ebp
.ItemPtr    equ 8
.BarColor   equ -4
.Width      equ -6
.Height     equ -8
.Size       equ -8

    cmp ebx,9<<16|7FFFh
    jbe near .Vertical

.Horizontal:
    ; main black strip
    shr ebx,16
    ;mov bx,[ebp+.Width]
    push eax                    ;color
  %ifdef UseSmallScreen
    sub bx,byte 4               ;width-4 for rounded edges on both sides
    push bx
    push word 9                 ;height
    push dword 0|(2<<16)        ;row/col
  %else
    sub bx,byte 8               ;width-8 for rounded edges on both sides
    push bx
    push word 18                ;height
    push dword 0|(4<<16)        ;row/col
  %endif

    call DrawRect
    ;add esp,byte 12

  %ifdef UseSmallScreen
    ; rounded edge thick vline
    push word [ebp+.BarColor]   ;color
    push word 7                 ;height
    push dword 1|(1<<16)        ;row/col
    call DrawVline
    mov bx,[ebp+.Width]         ;get title bar width
    sub bx,byte 2
    mov [esp+2],bx              ;column
    call DrawVline
    ;add esp,byte 8

    ; rounded edge thin vline
    push word [ebp+.BarColor]   ;color
    push word 3                 ;height
    push dword 3|(0<<16)        ;row/col
    call DrawVline
    mov bx,[ebp+.Width]         ;get title bar width
    dec bx
    mov [esp+2],bx              ;column
    call DrawVline
    ;add esp,byte 8
  %else

    ; rounded edge thick vline
    push word [ebp+.BarColor]   ;color
    push word 6                 ;height
    push dword 6|(0<<16)        ;row/col
    call DrawVline
    mov dword [esp],4|(1<<16)   ;row/col
    mov word [esp+4],10
    call DrawVline
    mov dword [esp],2|(2<<16)   ;row/col
    mov word [esp+4],14
    call DrawVline
    mov dword [esp],1|(3<<16)   ;row/col
    mov word [esp+4],16
    call DrawVline
    ;add esp,byte 8

    mov bx,[ebp+.Width]         ;get title bar width
    sub bx,4
    mov [esp+2],bx              ;column
    call DrawVline
    add dword [esp],1|(1<<16)   ;row/col
    mov word [esp+4],14
    call DrawVline
    add dword [esp],2|(1<<16)   ;row/col
    mov word [esp+4],10
    call DrawVline
    add dword [esp],2|(1<<16)   ;row/col
    mov word [esp+4],6
    call DrawVline

    ; rounded edge thin vline
    ;push word [ebp+.BarColor]   ;color
    ;push word 3                 ;height
    ;push dword 3|(0<<16)        ;row/col
    ;call DrawVline
    ;mov bx,[ebp+.Width]         ;get title bar width
    ;dec bx
    ;mov [esp+2],bx              ;column
    ;call DrawVline
    ;add esp,byte 8
  %endif

    ; title text
    mov ebx,[ebp+.ItemPtr]
    push dword [ebx+TitleBarObj.TextLen]
    push dword [ebx+TitleBarObj.TextPtr]
  %ifdef UseSmallScreen
    push dword 00030001h        ;left column/top row
  %else
    push dword 00050002h        ;left column/top row
  %endif
    call BlitString
    ;add esp,byte 12

    ; draw buttons
    mov ebx,[ebp+.ItemPtr]
    mov ecx,[ebp+.Size]
    mov eax,[ebx+TitleBarObj.Flags]
    mov esi,.CloseImg
  %ifdef UseSmallScreen
    sub ecx,9<<16               ;col=titlebar width-9
    mov [.ButtonInc],dword 8<<16 ;8 pixels left
    mov cx,1                    ;set row=1
  %else
    sub ecx,18<<16              ;col=titlebar width-18
    mov [.ButtonInc],dword 16<<16 ;pixels left increment
    mov cx,2                    ;set row
  %endif
    test eax,TitleBarObj.CloseButton
    call .DrawButton
    test eax,TitleBarObj.HelpButton
    call .DrawButton
    test eax,TitleBarObj.MaxButton
    call .DrawButton
    test eax,TitleBarObj.MinButton
    call .DrawButton
    jmp .VerticalEnd

.Vertical:
    ; main black strip
    push eax                    ;color
    ;mov bx,[ebp+.Height]
  %ifdef UseSmallScreen
    sub bx,byte 4               ;height-4 for rounded edges on both sides
    push word 9                 ;width
    push bx
    push dword 2|(0<<16)        ;row/col
  %else
    sub bx,byte 8               ;height-8 for rounded edges on both sides
    push word 18                ;width
    push bx
    push dword 4|(0<<16)        ;row/col
  %endif
    call DrawRect
    ;add esp,byte 12

    ; rounded edge thick vline
    push word [ebp+.BarColor]   ;color
    push word 7                 ;width
    push dword 1|(1<<16)        ;row/col
    call DrawHline
    mov bx,[ebp+.Height]        ;get title bar height
    sub bx,byte 2
    mov [esp],bx                ;row
    call DrawHline
    ;add esp,byte 8

    ; rounded edge thin vline
    push word [ebp+.BarColor]   ;color
    push word 3                 ;width
    push dword 0|(3<<16)        ;row/col
    call DrawHline
    mov bx,[ebp+.Height]        ;get title bar height
    dec bx
    mov [esp],bx                ;row
    call DrawHline
    ;add esp,byte 8

    ; title text
    mov ebx,[ebp+8]
    push dword [ebx+TitleBarObj.TextLen]
    push dword [ebx+TitleBarObj.TextPtr]
  %ifdef UseSmallScreen
    push dword 00000003h        ;left column/top row
  %else
    push dword 00000006h        ;left column/top row
  %endif
    call BlitStringV
    ;add esp,byte 12

    mov ecx,1<<16               ;left col
    mov ebx,[ebp+8]
    mov cx,[ebp+.Height]
    mov [.ButtonInc],dword 8    ;8 pixels up
    mov eax,[ebx+TitleBarObj.Flags]
    mov esi,.CloseImg
    sub ecx,byte 9              ;row=titlebar height-9
    test eax,TitleBarObj.CloseButton
    call .DrawButton
    test eax,TitleBarObj.HelpButton
    call .DrawButton
    test eax,TitleBarObj.MaxButton
    call .DrawButton
.VerticalEnd:

    ;clc
    mov esp,ebp
    pop ebp
    ret

;컴컴컴컴컴컴컴컴컴컴
.DrawButton:
;(zf=blit or not, esi=button image ptr, ecx=left column/top row)
;(cf=0, ecx=new top/left, esi=next image; eax)
    jz .DbRet
    push eax                    ;save flags

    push dword [.ColorMap]      ;pixel index to color map
    push esi                    ;image ptr
  %ifdef UseSmallScreen
    push dword 7|(7<<16)        ;height & width
  %else
    push dword 14|(14<<16)      ;height & width
  %endif
    push ecx                    ;left column/top row
    call DrawImageMapped
    pop ecx
    mov esi,[esp+4]
    add esp,byte 12
    sub ecx,[.ButtonInc]        ;move either left or down

    pop eax
.DbRet:
  %ifdef UseSmallScreen
    add esi,byte 7*7
  %else
    add esi,14*14
  %endif
.IgnoreKeyFocus:
    ret

;컴컴컴컴컴컴컴컴컴컴
.ItemFocus:
    test eax,FocusMsgFlags.SetContainer
    jnz near SendContainerRedraw.Partial
    test byte [ebx+TitleBarObj.Flags],TitleBarObj.GroupIndicate
    jz .IgnoreKeyFocus
    test eax,FocusMsgFlags.SetGroup
    jz .IgnoreKeyFocus
    jmp SendContainerRedraw.Partial
