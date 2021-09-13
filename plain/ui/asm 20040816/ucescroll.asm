;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Behaviour:
;  Left click on handle grabs it so you can drag it to any value
;  Left click anywhere (anywhere, not just on a little button) on either side
;   of the handle will scroll in that direction by the small increment.
;  Right click on either side of the handle will page in that direction
;   (scroll by the large increment)
;  Double clicking on point will jump immediately to it
;  Generally, they do not have key focus, but if so, the handle can be
;   changed with the arrow keys, home, end, pgup, and pgdn.
;
ScrollHandleCode:

section data
    StartMsgJtbl
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.Time,.Scroll
    AddMsgJtbl Msg.Focus,SendContainerRedraw.Partial ;CommonItemCode.GrabKeyFocus
    AddMsgJtbl Msg.KeyPress,.KeyPress
    AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    AddMsgJtbl Msg.MouseMove,.MouseMove
    AddMsgJtbl Msg.MouseIn,SetCursorImage.Default
    AddMsgJtbl Msg.MouseOut,.MouseOut
.KeysJtbl:
    dd .KeySmallStep ;left
    dd .KeySmallStep ;right
    dd .KeySmallStep ;up
    dd .KeySmallStep ;down
    dd .KeyLargeStep ;pgup
    dd .KeyLargeStep ;pgdn
    dd .KeyHome
    dd .KeyEnd
.Timer:             dd 0        ;ptr to timer process used for scrolling
.Keys:
    db 0,VK_LEFT
    db 0,VK_RIGHT
    db 0,VK_UP
    db 0,VK_DOWN
    db 0,VK_PAGEUP
    db 0,VK_PAGEDOWN
    db 0,VK_HOME
    db 0,VK_END
    db -1
section bss
    alignb 4
    .ItemLength:    resd 1      ;length of item (either height or width)
    ;.HandleSize:    resd 1      ;height or width of only handle part
    ;.HandlePos:     resd 1      ;row or col, depending on v/h orientation
  %ifdef UseSmallScreen
    .MinHandleSize  equ 8
    .MinHandleWidth equ 6
  %else
    .MinHandleSize  equ 16
    .MinHandleWidth equ 12
  %endif
    .MaxValue:      resd 1      ;total range - large step
    .Span:          resd 1      ;how many pixels handle is free to move
    .GrabPos:       resd 1      ;position offset grabbed on handle
    .DestValue:     resd 1      ;destination value to scroll to
    .DestMin:       resd 1      ;min destination value
    .DestMax:       resd 1      ;max destination value
    .ScrollInc:     resd 1      ;amount to scroll up or down
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.Draw:
    ; draw handle inset
    ; draw inset background
    ; calculate handle size/position
    ; draw handle

    ; set dwords height, width for inset bg
    push ebx
    mov edx,GuiClrDGray
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jnz .NotFullFocus
    mov edx,GuiClrBlue
.NotFullFocus:
    mov eax,[ebx+GuiObj.Size]
    push edx
  %ifdef UseSmallScreen
    sub eax,00020002h
    push eax                    ;height/width
    push dword 00010001h        ;top/left
  %else
    sub eax,00040004h
    push eax                    ;height/width
    push dword 00020002h        ;top/left
  %endif
    ;>>
    push dword DrawBorder.Concave
    push dword [ebx+GuiObj.Size]
    push dword 0
    mov eax,00000304h
    call DrawBorder.GivenColors
    add esp,byte 12
    ;<<
    call DrawRect
    add esp,byte 12
    pop ebx

%if 0
    call .CalcHandlePos         ;get size and position
    or ecx,.MinHandleWidth<<16  ;set width or height of handle
    cmp word [ebx+GuiObj.Height],.MinHandleWidth
    ja .RedrawUseHeight
    rol eax,16                  ;swap top/left
    rol ecx,16                  ;swap height/width
    ;mov [.HandlePos],eax
.RedrawUseHeight:
    ;mov [.HandleSize],ecx
%endif

    call .CalcHandlePos         ;get size and position
    mov edx,[ebx+GuiObj.Size]
    ;or ecx,.MinHandleWidth<<16  ;set width or height of handle
    cmp dx,[ebx+GuiObj.Width]
    jae .RedrawUseHeight
    shl ecx,16                  ;swap height/width
    shl eax,16                  ;swap top/left
    mov cx,dx
    mov edx,ecx
    jmp short .RedrawUsedWidth
.RedrawUseHeight:
    mov dx,cx
.RedrawUsedWidth:

    ;push dword GuiClrWhite
    push dword DrawBorder.Convex|DrawBorder.Filled
    push edx                    ;height/width
    push eax                    ;top/left
    ;call DrawRect
    call DrawBorder
    add esp,byte 12

    ;clc (ADD clears cf)
    ret

;컴컴컴컴컴컴컴컴컴컴
; calculates handle size/position
; ()
; (eax=position, ecx=height, esi=span, edi=max value)
.CalcHandlePos:
    ; get either height or width depending on orientation of handle
    movzx esi,word [ebx+GuiObj.Height]
    cmp si,[ebx+GuiObj.Width]
    jae .ChpUseHeight
    mov si,[ebx+GuiObj.Width]
.ChpUseHeight:
    mov edi,[ebx+ScrollHandleObj.Range]
    mov [.ItemLength],esi

    ; ensure range isn't zero (lest CPU complain about dumb div by 0)
    cmp [ebx+ScrollHandleObj.LargeStep],edi  ;large step < range
    mov eax,esi                 ;copy item height for calculation
    jb .ChpRangeNz
    mov ecx,esi                 ;handle size = item size
    xor edi,edi                 ;zero max value
    xor eax,eax                 ;zero handle position
    xor esi,esi                 ;zero span
    ;mov [.HandleSize],ecx
    ;mov [.HandlePos],eax
    mov [.MaxValue],edi
    mov [.Span],esi
    ret

.ChpRangeNz:
    ; calculate handle height (the button like part you grab)
    ; handle height = (large step * gui height) \ range {round up}
    ; if handle height < 8 then handle height = 8

    mul dword [ebx+ScrollHandleObj.LargeStep]
    add eax,edi                 ;+range
    dec eax                     ;-1 (round up)
    div edi                     ;/range
    cmp eax,.MinHandleSize
    jae .ChpSizeOk
    mov eax,.MinHandleSize
.ChpSizeOk:

    ; calculate maximum value & span
    ; span = item height - handle height + 1
    ; max value = range - large inc
    inc esi
    sub edi,[ebx+ScrollHandleObj.LargeStep]
    mov ecx,eax                 ;copy so next mul/div doesn't wipe
    ;mov [.HandleSize],eax
    sub esi,eax                 ;item height - handle height
    mov [.MaxValue],edi
    mov eax,esi
    mov [.Span],esi

    ; calculate handle position (pixel offset from top or left)
    ; handle row = (value * span - 1) \ max value
    mul dword [ebx+ScrollHandleObj.Value]
    test eax,eax
    jz .ChpValueZ
    dec eax
    div edi                     ;/max value
.ChpValueZ:
    ;mov [.HandlePos],eax
    ret

;컴컴컴컴컴컴컴컴컴컴
; upon mouse press
;   calculate position (setting destination value)
;   if click on bar handle
;     grab mouse cursor
;     calculate button row offset
;   else above or below handle
;     calculate clicked position
;     if double click
;       set value to clicked position (sending change message)
;     else
;       set destination value
;       if left click
;         set scroll increment to fine increment (small change)
;       elif right click
;         set scroll increment to page increment (large change)
;       endif
;       call intial timer tick
;       create & start timer
;     endif
;   endif
; end upon
; upon mouse release
;   if grabbed
;     stop any timer
;     release mouse cursor
;     send change message
;   endif
; end upon
;
.MousePrsRls:
    test dword [Mouse.Buttons],Mouse.LeftPress|Mouse.RightPress
    jz near .NoMousePress

    ;call CommonItemCode.ConfineCursor

    test dword [ebx+GuiObj.Flags],GuiObj.NoKeyFocus
    jnz .NoKeyFocus
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.ByMouse
    call SendContainerMsg
.NoKeyFocus:

    call .CalcHandlePos
    ;(eax=handle row, ecx=handle height, esi=span, edi=max value)

    ; get row or column, depending on vertical/horizontal orientation
    mov edx,eax                 ;swap handle row with clicked position
    mov ax,[ebx+GuiObj.Height]
    cmp ax,[ebx+GuiObj.Width]
    jae .UseMouseRow
    mov eax,[esp+12]            ;get column
    jmp short .UsedMouseCol
.UseMouseRow:
    mov eax,[esp+8]             ;get row
.UsedMouseCol:

    ; determine if click was above, below, or on handle
    push dword .SetDest
    cmp eax,edx                 ;clicked row < handle pos
    jl .ClickedAboveHandle
    sub eax,edx                 ;clicked - handle pos
    cmp eax,ecx
    jge .ClickedBelowHandle     ;(mouse row - handle pos) >= handle size
    pop edx                     ;discard return address
    mov ecx,[ebx+ScrollHandleObj.LargeStep]
    mov [.GrabPos],eax          ;else clicked on handle
    mov [.ScrollInc],ecx

    mov al,ScrollHandleMsg.Grab
    ;DebugOwnerMsg "scroll handle grab"
    call SendOwnerMsg

    jmp CommonItemCode.CaptureMouse
    ;ret

.ClickedAboveHandle:
    ; IF SbMaxValue < SbSpan THEN
    ;     'use this formula when the range is smaller than height (sparse)
    ;     NewValue = CINT((MouseRow * SbMaxValue + SbMaxValue) / SbSpan)
    ; ELSE 'SbMaxValue >= SbSpan THEN
    ;     'use this when the range is larger than height (dense)
    ;     NewValue = (MouseRow * SbMaxValue + SbSpan) \ SbSpan
    ; END IF
    mov dword [.GrabPos],-1
; (eax=click position, ecx=handle height, esi=span, edi=max value)
.CalcAboveHandle:
    cmp eax,esi                 ;click position >= span
    jge .PosBelowBtm
    test eax,eax
    jg .CahPosOk
.PosAboveTop:
    xor eax,eax                 ;return zero
    ret                         ;return to caller's caller
.PosBelowBtm:
    mov eax,edi                 ;return max value
    ret
.CahPosOk:

    mul edi                     ;* max value
    cmp edi,esi                 ;max value < span
    jb .CahSparse
    add eax,esi                 ;+ span
    jmp short .CahDense
.CahSparse:
    add eax,edi                 ;+ max value
.CahDense:
    div esi                     ;/ span
    ret

; (eax=click position-handle pos, ecx=handle height, esi=span, edi=max value)
.ClickedBelowHandle:
    ; IF SbMaxValue < SbSpan THEN
    ;     'use this formula when the range is smaller than height (sparse)
    ;     NewValue = CINT(((MouseRow - SbBarHeight + 1) * SbMaxValue) / SbSpan)
    ; ELSE 'SbMaxValue >= SbSpan THEN
    ;     'use this when the range is larger than height (dense)
    ;     NewValue = ((MouseRow - SbBarHeight + 1) * SbMaxValue) \ SbSpan + 1
    ; END IF
    add eax,edx                 ;compensate for subtraction above (click pos + handle pos)
    mov dword [.GrabPos],-2
; (eax=click position, ecx=handle height, esi=span, edi=max value)
.CalcBelowHandle:
    inc eax
    cmp [.ItemLength],eax       ;(click position+1) >= length
    jle .PosBelowBtm
    sub eax,ecx                 ;click pos + 1 - handle size
    jle .PosAboveTop

    mul edi                     ;* max value
    div esi                     ;/ span
    inc eax                     ;value+1
    ret

; round value to nearest integer
; (eax=value, esi=span, edx=remainder)
; (eax=rounded value; !edx)
.CalcIntValue:
    shl edx,1
    ;inc edx                     ;remainder * 2 + 1
    cmp esi,edx                 ;span divisor < remainder
    adc eax,0
    ret

.SetDest: ;(eax=new value)
    ; set it as destination and setup timer

    mov edx,[ebx+ScrollHandleObj.Value]
    mov [.DestValue],eax
    mov [.DestMin],edx
    mov [.DestMax],edx

    test dword [Mouse.Buttons],Mouse.LeftPress
    jnz .LeftPress
    mov ecx,[ebx+ScrollHandleObj.LargeStep]
    jmp short .RightPress
.LeftPress:
    mov ecx,[ebx+ScrollHandleObj.SmallStep]
.RightPress:
    mov [.ScrollInc],ecx

    ; set value now or create timer
    ; if double button click, set value immediately and return
    mov esi,[.Timer]
    test esi,esi                ;don't create another timer!
    jnz near ._SetValue
.CreateTimer:
    push ebx
    call CreateTimer
    pop eax                     ;discard
    jc .NoTimers
    mov [.Timer],esi

    ; set timer speed
    add [esi+TimerObj.Time],dword 200 ;delay initial repeat 1/5 second
.ChangeSpeed:
    mov eax,[ebx+ScrollHandleObj.ScrollSpeed]
    test dword [Mouse.Buttons],Mouse.LeftPress
    jnz .FastScroll
    shl eax,1                   ;scroll page half as fast as row
.FastScroll:
    mov [esi+TimerObj.Interval],dword eax
.NoTimers:

    call CommonItemCode.CaptureMouse
    mov al,ScrollHandleMsg.Grab
    ;DebugOwnerMsg "scroll handle grab"
    call SendOwnerMsg
    jmp .Scroll
    ;clc
    ;ret

.NoMousePress:
    test dword [Mouse.Buttons],Mouse.LeftRelease|Mouse.RightRelease
    jz near .IgnoreMouse
.MouseOut:
    ; release mouse and destroy timer
    ;call ConfineCursor.Release
    cmp [CommonItemCode.MouseObject],ebx
    jne .IgnoreMouse
    push ebx
    call DestroyTimerObj
    pop eax                     ;discard
    mov [.Timer],dword 0
    mov al,ScrollHandleMsg.Release
    DebugOwnerMsg "scroll handle release"
    call SendOwnerMsg
    jmp CommonItemCode.ReleaseMouseNow
    ;ret

;컴컴컴컴컴컴컴컴컴컴
; if grabbed
;   if button grabbed
;     calculate clicked position
;     set value (sending scroll message)
;   else
;     calculate clicked position
;    set destination value (but do not actually change until next timer)
;   endif
; endif
;
.MouseMove:
    cmp [CommonItemCode.MouseObject],ebx
    jne .IgnoreMouse

    call .CalcHandlePos
    ;(eax=handle row, ecx=handle height, esi=span, edi=max value)

    ; get row or column, depending on vertical/horizontal orientation
    mov edx,eax                 ;swap handle row with clicked position
    mov ax,[ebx+GuiObj.Height]
    cmp ax,[ebx+GuiObj.Width]
    jae .MmUseMouseRow
    mov eax,[esp+12]            ;get column
    jmp short .MmUsedMouseCol
.MmUseMouseRow:
    mov eax,[esp+8]             ;get row
.MmUsedMouseCol:

    cmp dword [.GrabPos],0
    jge .HandleGrabbed
    push dword .AdjustDest
    cmp dword [.GrabPos],-1
    je near .CalcAboveHandle
    ;cmp dword [.GrabPos],-2
    jmp .CalcBelowHandle
.AdjustDest:
    mov [.DestValue],eax
    clc
    ret

.IgnoreMouse:
    stc
    ret

.HandleGrabbed:
    sub eax,[.GrabPos]
    call .CalcAboveHandle
    ;cmp edi,esi                 ;max value < span
    cmp [.MaxValue],eax
    jbe near ._SetValue
    call .CalcIntValue
    jmp ._SetValue

;컴컴컴컴컴컴컴컴컴컴
; upon timer tick
;   scroll up or down depending on destination value by scroll size
;   if new value different send change message
; endupon
;
; (ebx=gui item ptr) (cf=0)
.Scroll:
    DebugMessage "handle scroll"
    mov edx,[.DestValue]
    mov eax,[ebx+ScrollHandleObj.Value]
    mov ecx,[.ScrollInc]
    cmp edx,eax
    je near .ScrollSame
    jb .ScrollNeg

; (eax=value, edx=dest value, ecx=scroll inc)
.ScrollPos:
    mov esi,[ebx+ScrollHandleObj.Range]
    sub esi,[ebx+ScrollHandleObj.LargeStep]
    cmp [.DestMax],esi
    jae .ScrollNoMaxCheck
    cmp [.DestMax],edx
    ja .ScrollSame              ;dest < dest max
.ScrollNoMaxCheck:
    add eax,ecx
    jc .ScrollBelowMax          ;value would have to be huge for this >4bil
    cmp eax,edx
    jbe .ScrollOk
    cmp eax,esi
    jbe .ScrollPastDest
.ScrollBelowMax:
    mov eax,esi
    jmp short .ScrollPastDest

; (eax=value, edx=dest value, ecx=scroll inc)
.ScrollNeg:
    cmp [.DestMin],edx
    jb .ScrollSame              ;dest >= dest min
    neg ecx
    add eax,ecx
    jnc .ScrollAboveMax         ;negative scroll
    neg ecx
    cmp eax,edx
    jae .ScrollOk
    jmp short .ScrollPastDest
.ScrollAboveMax:
    neg ecx
    xor eax,eax
    ;jmp short .ScrollPastDest

; (eax=new value, ecx=scroll inc)
.ScrollPastDest:
    mov [.DestValue],eax
.ScrollOk:
    cmp [ebx+ScrollHandleObj.Value],eax
    je .ScrollSame
    mov [ebx+ScrollHandleObj.Value],eax

    cmp dword [.GrabPos],-1
    je .ScrollAbove
    mov [.DestMax],eax
    sub eax,ecx
    mov [.DestMin],eax
    jmp short .ScrollBelow
.ScrollAbove:
    add ecx,eax
    mov [.DestMin],eax
    mov [.DestMax],ecx
.ScrollBelow:

    ; inform owner of value change
    mov eax,ScrollHandleMsg.Scroll
    DebugOwnerMsg "scroll handle scroll"
    call SendOwnerMsg

    jmp SendContainerRedraw.Partial
    ;clc
    ;ret
.ScrollSame: ;cf=0
    ret


;컴컴컴컴컴컴컴컴컴컴
; scroll up or down depending on destination value by scroll size
;   up/down = small step
;   PgUp/PgDn = large step
;   Home/End = ends
; if new value different send change message
;
.KeyPress:
    mov esi,.Keys
    call ScanForKey
    jc .KeyNoMatch
    jmp [.KeysJtbl+ecx*4]       ;jump to the right key response
.KeyNoMatch:
    ret

.KeyHome:
    xor eax,eax
    jmp short ._SetValue
.KeyEnd:
    mov eax,[ebx+ScrollHandleObj.Range]
    sub eax,[ebx+ScrollHandleObj.LargeStep]
    jmp short ._SetValue

.KeyLargeStep:
    mov esi,[ebx+ScrollHandleObj.LargeStep]
    jmp short .KeyValueRel
.KeySmallStep:
    mov esi,[ebx+ScrollHandleObj.SmallStep]
    ;jmp short .KeyValueRel

; (eax=step to use, ecx=odd:inc/even:dec)
.KeyValueRel:
    mov edx,[ebx+ScrollHandleObj.Range]
    mov eax,[ebx+ScrollHandleObj.Value]
    sub edx,[ebx+ScrollHandleObj.LargeStep]
    bt ecx,0                    ;test if even or odd
    jc .KvrEven
    sub eax,esi
    cmp eax,edx
    jbe ._SetValue
    xor eax,eax
    jmp short ._SetValue
.KvrEven:
    add eax,esi
    cmp eax,edx
    jbe ._SetValue
    mov eax,edx
    ;jmp short ._SetValue

; (eax=value)
._SetValue:
    cmp [ebx+ScrollHandleObj.Value],eax
    je .SvSame
    mov [ebx+ScrollHandleObj.Value],eax

    ; inform owner of value change
    mov eax,ScrollHandleMsg.Scroll
    ;DebugOwnerMsg "scroll handle scroll"
    call SendOwnerMsg

    jmp SendContainerRedraw.Partial
    ;clc
    ;ret
.SvSame: ;cf=0
    ret

.SetValue:
    mov edx,[ebx+ScrollHandleObj.Range]
    sub edx,[ebx+ScrollHandleObj.LargeStep]
    cmp eax,edx
    jbe ._SetValue
.SvErr:
    stc
    ret

    ; RecalculatePosition:
    ;  if on handle
    ;    destination value = (row - bar position clicked) \ ?
    ;  elif above scroll bar button
    ;    destination value = row \ ?
    ;  elif below
    ;    destination value = (row - bar size) \ ?
    ;  endif
%endif


%ifdef UseButtonCode
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
%endif


%if GuiDebugMode & 2
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
DebugObjCode:
    cmp al,Msg.Redraw
    je .Draw
    cmp al,Msg.KeyPress
    je .Ignore
    cmp al,Msg.MouseMove
    ;je .Ignore
    ;jmp SendContainerRedraw.Partial
    jmp short .Ignore
.Draw:

    push dword [ebx+GuiObj.Flags]
    push dword DrawBorder.Filled
    push dword [ebx+GuiObj.Size]
    push dword 0
    call DrawBorder
    add esp,byte 12
    pop edx

    mov esi,.FlagTiles
    mov edi,[Display.Ptr]
    test edx,GuiObj.ItemFocus
    call .DrawFlag
    test edx,GuiObj.GroupFocus
    call .DrawFlag
    test edx,GuiObj.ContainerFocus
    call .DrawFlag
    test edx,GuiObj.MouseFocus
    call .DrawFlag
    test edx,GuiObj.RedrawBg
    call .DrawFlag
    clc
    ret
.Ignore:
    stc
    ret

.DrawOverlay:
    pusha
    mov ebx,[esp+32+4]
    pushf
    mov edx,[Display.Top]
    cmp edx,Screen.Height-5
    jae .Clipped
    mov ecx,[Display.Left]
    cmp ecx,Screen.Width-4 ;-(4*6)
    jae .Clipped
    mov edx,[ebx+GuiObj.Flags]
    mov esi,.FlagTiles
    xor edx,GuiObj.NotFullFocus
    mov edi,[Display.Ptr]
    test edx,GuiObj.ItemFocus
    call .DrawFlag
    test edx,GuiObj.GroupFocus
    call .DrawFlag
    test edx,GuiObj.ContainerFocus
    call .DrawFlag
    test edx,GuiObj.MouseFocus
    call .DrawFlag
    test edx,GuiObj.KeyFocus
    call .DrawFlag
    test edx,GuiObj.RedrawBg
    call .DrawFlag
.Clipped:
    popf
    popa
    ret

.DrawFlag:
    mov ebx,0
    jz .DfDim
    mov ebx,2020202h
.DfDim:
    push edi
    mov ecx,5
.DfNext:
    lodsd
    add eax,ebx
    mov [edi],eax
    add edi,[Display.Width] ;Screen.Width
    dec ecx
    jg .DfNext
    pop edi
    add edi,byte 4              ;four pixel to the right
    ret

section data
align 4, db 0
.FlagTiles:
    db 0,3,0,0;I
    db 0,3,0,0
    db 0,3,0,0
    db 0,3,0,0
    db 0,3,0,0
    db 0,3,3,0;G
    db 3,0,0,0
    db 3,3,3,0
    db 3,0,3,0
    db 0,3,0,0
    db 0,3,0,0;C
    db 3,0,3,0
    db 3,0,0,0
    db 3,0,3,0
    db 0,3,0,0
    db 3,0,3,0;M
    db 3,3,3,0
    db 3,0,3,0
    db 3,0,3,0
    db 3,0,3,0
    db 3,0,0,3;K
    db 3,3,3,0
    db 3,3,0,0
    db 3,0,3,0
    db 3,0,0,3
    db 3,3,0,0;B
    db 3,0,3,0
    db 3,3,0,0
    db 3,0,3,0
    db 3,3,0,0
section code

