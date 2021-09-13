;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
ButtonCode:

section data
    StartMsgJtbl
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.Focus,CommonItemCode.GrabKeyFocus
    AddMsgJtbl Msg.KeyPress,.KeyPress
    AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    AddMsgJtbl Msg.MouseIn,.MouseIn
    AddMsgJtbl Msg.MouseOut,.MouseOut
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.Draw:
    ;draw sides and fill
    ;if button has focus set bright colors
    ;get stringwidth
    ;draw text
    ;  set color bright if active else normal
    ;  center text
    ;    get length of string
    ;    set column (button width - string width) / 2
    ;    set row (button height - string height) / 2

    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus;!!!
    jz near .skinhack;!!!

    mov al,[ebx+ButtonObj.Value];get button state
    and al,1                    ;isolate button state (in/out ) to determine convex or concave
    or al,2                     ;fill in center of button
    push eax
    push dword [ebx+GuiObj.Size]
    push dword 0
    call DrawBorder
    add esp,byte 12

    mov ebx,[esp+4]
    mov eax,GuiClrTxtNormal
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jnz .DrawNotActive
    mov eax,GuiClrTxtActive
.DrawNotActive:
    mov [Font.Colors],eax
    push dword [ebx+ButtonObj.TextLen]
    push dword [ebx+ButtonObj.TextPtr]
    call GetTextLenWidth
    mov ebx,[esp+4+8]
    xor edx,edx
    mov ecx,[ebx+GuiObj.Size]   ;get button height/width
    mov dl,[Font.BodyHeight]
    sub cx,dx                   ;subtract text height
    sar cx,1                    ;/2
    ror ecx,16
    sub cx,ax                   ;subtract text pixel length from width
    sar cx,1                    ;/2
    ror ecx,16
    push ecx
    call BlitString
    add esp,byte 12

    ;clc ;the add does this
    ret

.skinhack:
    push dword .ButtonXpPix     ;pixels
    push dword 75<<16|23
    push dword 0                ;left column/top row
    call DrawImageOpaque
    add esp,byte 12
    ;clc ;the add does this
    ret
section data
.ButtonXpPix:
    incbin "dev\buttonxp.lbm"
section code


;컴컴컴컴컴컴컴컴컴컴
.MouseIn:
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.ByMouse
    call SendContainerMsg
    call SetCursorImage.Default
    jmp .MousePrsRls
    ;clc
    ;ret

.MouseOut:
    ; if button is pressed in
    ;   unpush button
    ; endif
    cmp byte [ebx+ButtonObj.Value],ButtonObj.Pressed
    jne .ButtonNotPushed
.ButtonPushed:
    mov byte [ebx+ButtonObj.Value],0
    jmp SendContainerRedraw.Partial
    ;ret

.ButtonNotPushed:
    clc
    ret

;컴컴컴컴컴컴컴컴컴컴
.KeyPress:
    ;if key = space or enter then activate button
    cmp ah,VK_RETURN
    je .KeyActivate
    cmp ah,VK_SPACE
    je .KeyActivate
  .IgnoreKey:
    stc                         ;ignore unknown keypress
    ret
  .KeyActivate:
    ; if push button
    ;   unpush button (if pressed in)
    ;   send change msg
    ; if toggle button
    ;   toggle button state
    ;   send change msg
    ; endif

    ;            in   = event
    ;            out  = event reset
    ;     toggle in   = event push
    ;     toggle out  = event reset
    ;lock        in   = event push
    ;lock        out  =
    mov al,[ebx+ButtonObj.Value]
    cmp al,ButtonObj.Lock|ButtonObj.Pressed ;if button locked then skip
    je .IgnoreKey
    test al,al                  ;if push button and button not down
    jz .SendChangeEvent
    xor al,ButtonObj.Pressed    ;else toggle button state
    jmp short .SendChangeEvent

;컴컴컴컴컴컴컴컴컴컴
.MousePrsRls:
    ;            in   =       push
    ;            out  = event reset
    ;     toggle in   = event push
    ;     toggle out  = event reset
    ;lock        in   = event push
    ;lock        out  =

    ;DebugMessage "button press"
    mov edx,[Mouse.Buttons]
    mov al,[ebx+ButtonObj.Value]
    test edx,Mouse.LeftPress
    jz .NoMousePress
    ; if button is not already locked
    ;   invert button state
    ;   if button is toggle or lock type (not push button)
    ;     send change event
    ;   endif
    ;   redraw
    ; endif
    ;test flags,.MouseFocus
    ;jnz .HasMouseFocus
    push eax
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.SetContainer|FocusMsgFlags.ByMouse
    call SendContainerMsg
    pop eax
.HasMouseFocus:
    cmp al,ButtonObj.Lock|ButtonObj.Pressed ;if button locked then skip
    je .NoMousePrsRls
    xor al,ButtonObj.Pressed    ;toggle button state
    cmp al,ButtonObj.Pressed    ;is button push/release type
    jne .SendChangeEvent        ;if not push button, send change
    mov [ebx+ButtonObj.Value],al
    jmp SendContainerRedraw.Partial
    ;ret
  .NoMousePrsRls:
    stc
    ret
  .NoMousePress:
    test edx,Mouse.LeftRelease
    jz .NoMousePrsRls
    ; if push button is pressed in
    ;   unpush button
    ;   send change event
    ; endif
    cmp al,1
    jne .NoMousePrsRls
    and al,~1
    ;jmp short .SendChangeEvent

;컴컴컴컴컴컴컴컴컴컴
;(ebx=gui item ptr, al=new button state)
.SendChangeEvent:
    mov [ebx+ButtonObj.Value],al
    mov eax,PushButtonMsg.Change
    DebugOwnerMsg "button push/toggle"
    call SendOwnerMsg.Important ;inform owner of change
    jmp SendContainerRedraw.Partial
    ;ret
