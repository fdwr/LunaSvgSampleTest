;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
AtrListCode:

section data
    StartMsgJtbl
    AddMsgJtbl ScrollHandleMsg.Scroll,.HandleScrolled
    ;---
    AddMsgJtbl Msg.Created,.Created
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.Focus,.ItemFocus
    AddMsgJtbl Msg.KeyPress,.KeyPress
    AddMsgJtbl Msg.KeyChar,.KeyChar
    AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    AddMsgJtbl Msg.MouseMove,.MouseMove
    AddMsgJtbl Msg.MouseIn,.MouseIn
    AddMsgJtbl Msg.MouseOut,.MouseOut

.EditKeysJtbl:
    dd .KeyNum                  ;! the order of these must match the flag
    dd .KeyBkSpc                ;  constants defined for AtrListObj
    dd .KeyNormalStep
    dd .KeyNormalStep
    dd .KeySmallStep
    dd .KeySmallStep
    dd .KeyLargeStep
    dd .KeyLargeStep
    dd .KeyHome
    dd .KeyEnd

.SelectKeysJtbl:
    dd .KeyUp
    dd .KeyDown
    dd .KeyPgUp
    dd .KeyPgDn
    dd .KeyCtrlHome
    dd .KeyCtrlEnd

.EditKeysTbl:
    db AtrListObj.KeyNumB       ;0-9
    db AtrListObj.KeyNumB
    db AtrListObj.KeyNumB
    db AtrListObj.KeyNumB
    db AtrListObj.KeyNumB
    db AtrListObj.KeyNumB
    db AtrListObj.KeyNumB
    db AtrListObj.KeyNumB
    db AtrListObj.KeyNumB
    db AtrListObj.KeyNumB
    db AtrListObj.KeyBkSpcB
    db AtrListObj.KeyLargeDecB  ;Ctrl+L/R
    db AtrListObj.KeyLargeIncB
    db AtrListObj.KeySmallDecB  ;Shift+L/R
    db AtrListObj.KeySmallIncB
    db AtrListObj.KeyNormalDecB ;L/R
    db AtrListObj.KeyNormalIncB
    db AtrListObj.KeyLargeDecB  ;/ *
    db AtrListObj.KeyLargeIncB
    db AtrListObj.KeySmallDecB  ;- + numpad
    db AtrListObj.KeySmallIncB
    db AtrListObj.KeySmallDecB  ;- +
    db AtrListObj.KeySmallIncB
    db AtrListObj.KeyMinB       ;Home/End
    db AtrListObj.KeyMaxB

.EditKeys:
    db 0,VK_0
    db 0,VK_1
    db 0,VK_2
    db 0,VK_3
    db 0,VK_4
    db 0,VK_5
    db 0,VK_6
    db 0,VK_7
    db 0,VK_8
    db 0,VK_9
    db 0,VK_BACK
    db 2,VK_LEFT,   0,VK_CONTROL
    db 2,VK_RIGHT,  0,VK_CONTROL
    db 2,VK_LEFT,   0,VK_SHIFT
    db 2,VK_RIGHT,  0,VK_SHIFT
    db 0,VK_LEFT
    db 0,VK_RIGHT
    db 0,VK_DIVIDE
    db 0,VK_MULTIPLY
    db 0,VK_SUBTRACT
    db 0,VK_ADD
    db 0,VK_MINUS
    db 0,VK_PLUS
    db 2,VK_HOME,   1,VK_CONTROL
    db 2,VK_END,    1,VK_CONTROL
    db -1

.SelectKeys:
    db 0,VK_UP
    db 0,VK_DOWN
    db 0,VK_PAGEUP
    db 0,VK_PAGEDOWN
    db 0,VK_HOME
    db 0,VK_END
    db -1

.DrawRow    equ CommonItemCode.DrawRow
.DrawCol    equ CommonItemCode.DrawCol
.SelRow     equ CommonItemCode.SelRow
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.HandleScrolled:
    mov esi,[ebx+AtrListObj.ScrollHandle]
    xor edx,edx
    mov ecx,[esi+ScrollHandleObj.Value]
    call .SeekRows
    cmp [ebx+AtrListObj.Scroll],dl
    je .NoHandleScroll
    mov [ebx+AtrListObj.Scroll],dl
    mov eax,AtrListMsg.Scroll
    DebugOwnerMsg "atrlist scroll"
    call SendOwnerMsg
    mov eax,GuiObj.RedrawBg
    jmp SendContainerRedraw
.NoHandleScroll:
    ret

;컴컴컴컴컴컴컴컴컴컴
.Draw:
    ; if full redraw
    ;   draw whole bg
    ;   start from top scroll attribute
    ;     if not hidden
    ;       redraw attribute
    ;       next row
    ;     endif
    ;   loop until page drawn or last attribute
    ; else
    ;   start from top scroll attribute
    ;     if not hidden
    ;       if redraw set
    ;         draw bg
    ;         redraw attribute
    ;       endif
    ;       next row
    ;     endif
    ;   loop until page drawn or last attribute
    ; endif

    push ebp
    mov ebp,esp

    mov dword [.DrawRow],0
    mov dl,[ebx+AtrListObj.Scroll]
    call .GetAtrAdr
    mov al,dl
    sub al,[ebx+AtrListObj.TotalItems]
    jae near .RedrawEnd         ;!top scroll attribute >= total items

    neg al                      ;attributes remaining below top one
    movzx edi,byte [ebx+AtrListObj.NamesWidth]
    mov cl,255                  ;default if no key focus
    test dword [ebx+GuiObj.Flags],GuiObj.ItemFocus|GuiObj.GroupFocus|GuiObj.ContainerFocus
    jnz .RedrawNoFocus
    mov cl,[ebx+AtrListObj.Selected]
.RedrawNoFocus:
    shl edi,16                  ;move col into upper 16 bits
    mov [.SelRow],cl
    mov [.DrawCol],edi
    test dword [ebx+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.RedrawForced
    push dword [ebx+AtrListObj.PageRows]
    push eax                    ;push counter
    jz .RedrawPartial

.RedrawBg:
    push edx                    ;attribute item index
    push esi                    ;item ptr
    push dword GuiClrFace
    push dword 1024|(1024<<16)  ;height & width unnecessarily large
    push dword 0                ;top/left
    call DrawRect
    add esp,byte 12
    pop esi
    pop edx
.RbNext:
    test dword [esi+AtrListObj.Flags],AtrListObj.Hidden
    jnz .RbHidden
    call .DrawAttribute
    dec byte [esp+4]            ;one less row in page
    jz .RedrawEnd
    add [.DrawRow],byte FontDefHeight
.RbHidden:
    inc edx
    add esi,byte AtrListObj.Items_size
    dec byte [esp]              ;one less attribute left
    jnz .RbNext
    jmp short .RedrawEnd

; (edx=item index, esi=item ptr)
.RedrawPartial:
.RpNext:
    test dword [esi+AtrListObj.Flags],AtrListObj.Hidden
    jnz .RpHidden
    test dword [esi+AtrListObj.Flags],AtrListObj.Redraw
    jz .RpNoRedraw
    push edx
    push esi
    push dword GuiClrFace
    push dword FontDefHeight|(2048<<16) ;height | width ridiculously large
    push dword [.DrawRow]
    call DrawRect
    add esp,byte 12
    pop esi
    pop edx
    call .DrawAttribute
.RpNoRedraw:
    dec byte [esp+4]            ;one less row in page
    jz .RedrawEnd
    add [.DrawRow],byte FontDefHeight
.RpHidden:
    inc edx
    add esi,byte AtrListObj.Items_size
    dec byte [esp]              ;one less attribute left
    jnz .RpNext
    ;jmp short .RedrawEnd

.RedrawEnd:
    mov esp,ebp
    pop ebp
    ret

; (edx=item index, esi=item ptr)
.DrawAttribute:
    ; clear redraw flag
    ; write name
    ; if text
    ;   write text value
    ; else
    ;   draw picture
    ; endif
    push edx
    push esi

    ; set font color based on whether attribute is selected or not
    cmp [.SelRow],dl
    mov eax,GuiClrTxtActive
    je .DaSelected
    mov eax,GuiClrTxtNormal
.DaSelected:
    mov dword [Font.Colors],eax

    ; if value changed, get new value string from owner
    test dword [esi+AtrListObj.Flags],AtrListObj.GetValue
    jz .DaSameValue
    mov eax,AtrListMsg.GetValue
    mov ebx,[ebp+8]             ;get item ptr
    mov ecx,[esi+AtrListObj.Value] ;pass value
    mov ah,dl                   ;pass item index
    call SendOwnerMsg
    jc .DaSameValue
    test ecx,ecx
    jns .DaLengthGiven
    call GetStringLength
.DaLengthGiven:
    mov ebx,esi
    mov esi,[esp]
    mov dword [esi+AtrListObj.TextPtr],ebx  ;ptr to picture or string, depending on type
    mov dword [esi+AtrListObj.TextLen],ecx  ;number of characters in attribute text
.DaSameValue:
    and dword [esi+AtrListObj.Flags],~(AtrListObj.Redraw|AtrListObj.GetValue)
    ; (esi=attribute ptr)

    ; determine pixel width of text
    push dword [esi+AtrListObj.NameLen]
    push dword [esi+AtrListObj.NamePtr]
    call GetTextLenWidth
    ;add esp,byte 8
    neg eax                     ;right align
    sub eax,byte 4              ;col-4
    shl eax,16                  ;move col into upper 16bits
    add eax,[.DrawCol]          ;text width - names width

    ; draw name
    ;push dword [esi+AtrListObj.NameLen]
    ;push dword [esi+AtrListObj.NamePtr]
    or eax,[.DrawRow]
    push eax                    ;left column/top row
    call BlitString
    ;add esp,byte 12

    mov esi,[esp+12]
    ;test [esi+AtrListObj.Flags],AtrListObj.IsPicture
    ;jnz .DrawPicture

    ; draw value string
    mov eax,[.DrawRow]
    or eax,[.DrawCol]
    push dword [esi+AtrListObj.TextLen]
    push dword [esi+AtrListObj.TextPtr]
    push dword eax              ;left column|top row
    call BlitString
    add esp,byte 12+12

    pop esi
    pop edx
    ret

;컴컴컴컴컴컴컴컴컴컴
.ItemFocus:
    call .GetCursorAtrAdr
    jc .IfIgnore
    or dword [esi+AtrListObj.Flags],AtrListObj.Redraw
    jmp CommonItemCode.GrabKeyFocus
.IfIgnore:
    ;clc
    ret

;컴컴컴컴컴컴컴컴컴컴
; if key not recognized
;   search all attribute names
;     if first letter of name = key pressed, set cursor to
;   end search
; elif...
;
.KeyPress:
    mov esi,.EditKeys
    call ScanForKey
    jc .NotEditKey

    call .GetCursorAtrAdr
    jc .KeyNoMatch
    test dword [esi+AtrListObj.Flags],AtrListObj.Disabled|AtrListObj.Dimmed
    jnz .KeyNoMatch
    mov cl,byte [.EditKeysTbl+ecx]  ;convert key index to change type
    bt [ebx+AtrListObj.Flags],ecx
    jnc .NoKeyPreview

    push esi                    ;save value block ptr
    push edx                    ;save selected attribute
    push ecx                    ;save change type
    DebugOwnerMsg "atrlist keypress"
    call SendOwnerMsg
    pop ecx
    pop edx
    pop esi
    jnc .KeyPreviewed
.NoKeyPreview:
    jmp [.EditKeysJtbl+ecx*4]   ;jump to the right key response

.NotEditKey:
    mov esi,.SelectKeys
    call ScanForKey
    jc .KeyNoMatch
    jmp [.SelectKeysJtbl+ecx*4] ;jump to the right key response
.KeyNoMatch: ;(cf=0/1)
.KeyPreviewed: ;(cf=0)
    ret

; scan the names of all attributes for one starting with the letter key
; pressed, starting from the current one (cursor) and wrapping if necessary.
.KeyChar:
    ; check if key is alphanumeric
    or ah,32                    ;make ASCII character lowercase
    cmp ah,'a'
    jb .NoKeyChar
    cmp ah,'z'
    ja .NoKeyChar
    mov dl,[ebx+AtrListObj.Selected]
    inc dl
    call .GetAtrAdr
    movzx ecx,byte [ebx+AtrListObj.TotalItems]
    jmp short .FirstName
.NextName:
    test dword [esi+AtrListObj.Flags],AtrListObj.Hidden
    jnz .NameHidden
    mov edi,[esi+AtrListObj.NamePtr]
    mov al,[edi]
    or al,32
    cmp al,ah
    je near .SetSelect
.NameHidden:
    inc edx
    add esi,byte AtrListObj.Items_size
.FirstName:
    dec ecx
    jle .NoKeyChar
    cmp [ebx+AtrListObj.TotalItems],dl
    ja .NextName
    xor edx,edx
    mov esi,ebx
    jmp short .NextName
.NoKeyChar:
    stc
    ret

;컴컴컴컴컴컴컴컴컴컴
; elif home
;   set value to min
; elif end
;   set value to max
; elif left
;   get -normal step
;   adjust value
; elif right
;   get normal step
;   adjust value
; elif '/'
;   get -large step
;   adjust value
; elif '*'
;   get large step
;   adjust value
; elif '-'
;   get -small step
;   adjust value
; elif '+'
;   get small step
;   adjust value
;
.KeyHome:
    mov eax,AtrListObj.Min
    jmp short .KeyValueAbs
.KeyEnd:
    mov eax,AtrListObj.Max
    ;jmp short .KeyValueAbs
.KeyValueAbs:
    mov eax,[esi+eax]           ;read low or high value, and set value without
    jmp short .SvRangesOk       ;checking ranges, since they are valid

.KeyLargeStep:
    mov eax,AtrListObj.LargeStep
    jmp short .KeyValueRel
.KeySmallStep:
    mov eax,AtrListObj.SmallStep
    jmp short .KeyValueRel
.KeyNormalStep:
    mov eax,AtrListObj.NormalStep
    ;jmp short .KeyValueRel
; (eax=step to use, ecx=odd:inc/even:dec)
.KeyValueRel:
    mov eax,[esi+eax]           ;get step
    bt ecx,0                    ;test if even or odd
    jc .KvrEven
    neg eax                     ;negate increment to decrement
.KvrEven:
    add eax,[esi+AtrListObj.Value]
    ;jmp short ._SetValue

; (eax=value, esi=attribute block offset)
._SetValue:
    cmp [esi+AtrListObj.Min],eax
    jle .SvLowRangeOk
    mov eax,[esi+AtrListObj.Min]
    jmp short .SvRangesOk
.SvLowRangeOk:
    cmp [esi+AtrListObj.Max],eax
    jge .SvRangesOk
    mov eax,[esi+AtrListObj.Max]
.SvRangesOk:
    cmp [esi+AtrListObj.Value],eax
    je .SvSame
    mov [esi+AtrListObj.Value],eax

    ; redraw attribute
    or dword [esi+AtrListObj.Flags],AtrListObj.Redraw|AtrListObj.GetValue
    call SendContainerRedraw.Partial

    ; inform owner of value change
    mov eax,AtrListMsg.Change
    mov ah,[ebx+AtrListObj.Selected]
    DebugOwnerMsg "atrlist change"
    call SendOwnerMsg.Important

    clc
.SvSame: ;cf=0
    ret

;컴컴컴컴컴컴컴컴컴컴
.KeyBkSpc:
    mov eax,[esi+AtrListObj.Value]
    mov ecx,10
    xor edx,edx
    div ecx
    jmp short ._SetValue

.KeyNum:
    movzx eax,ah
    mov ecx,[esi+AtrListObj.Value]
    sub eax,byte '0'            ;convert ASCII char to number
    imul ecx,10
    add eax,ecx
    jmp short ._SetValue

;컴컴컴컴컴컴컴컴컴컴
; Returns a given value from the current attribute. That value can include
; the number value, min, max, small step, large step... Also calculates
; offset to attribute info block.
;
; (ebx=gui item ptr)
; (esi=attribute info ptr, dl=cursor index, cf=error; eax,ebx,ecx)
.GetCursorAtrAdr:
    mov dl,[ebx+AtrListObj.Selected]
    cmp [ebx+AtrListObj.TotalItems],dl
    jbe .CursorInvalid
; (dl=atr index, ebx=gui item ptr)
; (esi=attribute info ptr; eax,ebx,ecx,edx)
.GetAtrAdr:
    movzx esi,dl
    imul esi,AtrListObj.Items_size
    add esi,ebx
    ;clc
    ret
.CursorInvalid:
    stc
    ret

;컴컴컴컴컴컴컴컴컴컴
; if up
;   seek next atr backward
;   end if no change (top of list)
;   set cursor (selected attribute)
;   flag redraw for both old and new cursor
;   scroll list if necessary
; elif down
;   seek next atr forward
;   end if no change (bottom of list)
;   set cursor (selected attribute)
;   flag redraw for both old and new cursor
;   scroll list if necessary
; elif page up
;   seek -rows per page back from current scroll
;   end if no change (top of list)
;   set scroll (top attribute in list)
;   seek -(actual rows back + rows per page) from current cursor
;   set cursor (selected attribute)
;   redraw entire list
; elif page down
;   seek (rows per page * 2)-1 rows forward from current scroll
;   end if no change (bottom of list)
;   seek (actual rows forward - rows per page +1) from current scroll
;   set scroll (top attribute in list)
;   seek (actual rows forward - rows per page +1) from current cursor
;   set cursor (selected attribute)
;   redraw entire list
; elif ctrl+home
;   seek 0 rows forward from 0
;   end if no change (top of list)
;   set cursor (selected attribute)
;   flag redraw for both old and new cursor
;   scroll list if necessary
; elif ctrl+end
;   seek 0 rows backward from last row
;   end if no change (bottom of list)
;   set cursor (selected attribute)
;   flag redraw for both old and new cursor
;   scroll list if necessary
; endif

.KeyPgUp:
    movzx ecx,byte [ebx+AtrListObj.PageRows]
    mov dl,[ebx+AtrListObj.Scroll]
    push ecx
    neg ecx
    call .SeekRows
    pop eax
    jc .NoPgUpDn

    mov [ebx+AtrListObj.Scroll],dl
    add ecx,eax                 ;returned remaining count + page rows
    mov dl,[ebx+AtrListObj.Selected]
    neg ecx
    call .SeekRows
    mov [ebx+AtrListObj.Selected],dl
    mov eax,GuiObj.RedrawBg
    call SendContainerRedraw
    jmp .UpdateScrollHandle

.KeyPgDn:
    movzx ecx,byte [ebx+AtrListObj.PageRows]
    mov dl,[ebx+AtrListObj.Scroll]
    shl ecx,1
    dec ecx
    call .SeekRows
    jc .NoPgUpDn

    movzx eax,byte [ebx+AtrListObj.PageRows]
    neg ecx
    add ecx,eax
    mov dl,[ebx+AtrListObj.Scroll]
    push ecx
    call .SeekRows
    mov [ebx+AtrListObj.Scroll],dl
    pop ecx
    mov dl,[ebx+AtrListObj.Selected]
    call .SeekRows
    mov [ebx+AtrListObj.Selected],dl
    mov eax,GuiObj.RedrawBg
    call SendContainerRedraw
    jmp .UpdateScrollHandle

.NoPgUpDn:
    clc
    ret

.KeyCtrlHome:
    mov ecx,-255
    jmp short .SetSelectRel
.KeyCtrlEnd:
    mov ecx,255
    jmp short .SetSelectRel
.KeyUp:
    mov ecx,-1
    jmp short .SetSelectRel
.KeyDown:
    mov ecx,1
    ;jmp short .SetSelectRel
; (ebx=gui item ptr, ecx=seek count)
.SetSelectRel:
    mov dl,[ebx+AtrListObj.Selected]
    call .SeekRows
    jnc .SetSelectNow
    jmp short .EnsureSelectedVisible
.SameCursor: ;cf=0
    ret

; (dl=attribute index)
.SetSelect:
    cmp [ebx+AtrListObj.Selected],dl
    je .SameCursor              ;no cursor change
    ; redraw old and new cursor
.SetSelectNow:
    call .GetAtrAdr
    or dword [esi+AtrListObj.Flags],AtrListObj.Redraw
    xchg [ebx+AtrListObj.Selected],dl
    call .GetAtrAdr
    or dword [esi+AtrListObj.Flags],AtrListObj.Redraw
    call SendContainerRedraw.Partial

    mov eax,AtrListMsg.Select
    mov ah,[ebx+AtrListObj.Selected]
    DebugOwnerMsg "atrlist select"
    call SendOwnerMsg
    ;jmp short .EnsureSelectedVisible

; checks that cursor is visible in the current page and not above or below.
.EnsureSelectedVisible:
    mov dl,[ebx+AtrListObj.Selected]
    cmp [ebx+AtrListObj.Scroll],dl
    ja .SelectedScroll
    movzx ecx,byte [ebx+AtrListObj.PageRows]
    neg ecx
    inc ecx
    call .SeekRows
    cmp [ebx+AtrListObj.Scroll],dl
    jb .SelectedScroll
    ;clc
    ret

.SelectedScroll:
    mov [ebx+AtrListObj.Scroll],dl
    mov eax,AtrListMsg.Scroll
    DebugOwnerMsg "atrlist scroll"
    call SendOwnerMsg
    mov eax,GuiObj.RedrawBg
    call SendContainerRedraw
    ;jmp short .UpdateScrollHandle

; () (cf=0) no return
.UpdateScrollHandle:
    ; update scroll bar
    movzx ecx,byte [ebx+AtrListObj.Rows]
    movzx edx,byte [ebx+AtrListObj.PageRows]
    movzx eax,byte [ebx+AtrListObj.Scroll]
    mov ebx,[ebx+AtrListObj.ScrollHandle]
    test dword [ebx+GuiObj.Flags],GuiObj.Null
    jnz .UshNull
    mov [ebx+ScrollHandleObj.Range],ecx
    mov [ebx+ScrollHandleObj.LargeStep],edx
    mov [ebx+ScrollHandleObj.Value],eax
    jmp SendContainerRedraw.Partial
.UshNull: ;(cf=0)
    ret

.Created:
    mov esi,ebx
    movzx ecx,byte [ebx+AtrListObj.TotalItems]
    xor eax,eax
    test ecx,ecx
    jz .CiEmpty
.CiCountNext:
    test dword [esi+AtrListObj.Flags],AtrListObj.Hidden
    jnz .CiHidden
    inc eax
.CiHidden:
    add esi,byte AtrListObj.Items_size
    dec ecx
    jg .CiCountNext
.CiEmpty:
    mov [ebx+AtrListObj.Rows],al
    jmp short .UpdateScrollHandle
    ;ret

;컴컴컴컴컴컴컴컴컴컴
; if left press
;   constrain mouse
;   grab mouse
;   if column >= name width
;     send owner click message
;   else
;     grab mouse
;   endif
; elif left release
;   release mouse
; endif
.MousePrsRls:
    test dword [Mouse.Buttons],Mouse.LeftPress|Mouse.RightPress
    jz .NoMousePress

    mov ecx,[esp+8]             ;mouse row
    mov dl,[ebx+AtrListObj.Scroll]
    sar ecx,FontDefHshift       ;/FontDefHeight
    call .SeekRows
    call .SetSelect

    xor eax,eax
    mov ah,[ebx+AtrListObj.Selected]
    test dword [Mouse.Buttons],Mouse.LeftPress
    jnz .LeftPress
    mov al,AtrListMsg.AltActivate
    DebugOwnerMsg "atrlist altactivate"
    call SendOwnerMsg
    clc
    ret

.LeftPress:
    mov ecx,[esp+12]            ;mouse column
    cmp [ebx+AtrListObj.NamesWidth],cl
    ja .NameClick
    mov al,AtrListMsg.Activate
    DebugOwnerMsg "atrlist activate"
    call SendOwnerMsg
    jc .NameClick               ;owner ignored activation
    ;clc
    ret

.NameClick:
    ; grab key focus & mouse focus
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.SetContainer|FocusMsgFlags.ByMouse
    call SendContainerMsg
    mov eax,Msg.SetMouseFocus|MouseMsgFlags.SetContainer
    call SendContainerMsg

    ; confine cursor
    call CommonItemCode.CaptureMouse
    jmp CommonItemCode.ConfineCursor
    ;clc
    ;ret

.NoMousePress:
    test dword [Mouse.Buttons],Mouse.LeftRelease
    jz .IgnoreMouse
.MouseOut:
    ; release mouse focus
    call ConfineCursor.Release
    jmp CommonItemCode.ReleaseMouse
    ;ret

.IgnoreMouse:
    stc
    ret

.MouseMove:
    cmp [CommonItemCode.MouseObject],ebx
    jne .IgnoreMouse

    mov ecx,[esp+8]             ;mouse row
    test eax,MouseMsgFlags.VerticalPush
    mov edx,ecx                 ;default for if no push
    jz .MouseNoPush

    mov ecx,[CommonItemCode.CursorRow]
    add ecx,[Cursor.RowDif]     ;row accumulation + mouse motion push
    mov [CommonItemCode.CursorRow],ecx
    mov edx,8
    js .MouseScrollUp
    cmp [ebx+GuiObj.Height],cx
    ja .IgnoreMouse
    neg edx
.MouseScrollUp:
    add edx,ecx

; (edx=adjusted cursor row, ecx=actual row)
.MouseNoPush:
    mov [CommonItemCode.CursorRow],edx
    mov dl,[ebx+AtrListObj.Scroll]
    sar ecx,FontDefHshift       ;/FontDefHeight
    call .SeekRows
    jmp .SetSelect
    ;clc
    ;ret

;컴컴컴컴컴컴컴컴컴컴
.MouseIn:
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.ByMouse
    call SendContainerMsg
    jmp SetCursorImage.Default
    ;clc
    ;ret

;컴컴컴컴컴컴컴컴컴컴
; Seeks either forward or backward a given number of rows to find the next
; available item that can receive key focus. If the item row can not be set
; (because the cursor is either at the front or end of list) the remaining
; count will be returned. For example, if told to go 5 rows up, but there are
; only 2 rows above, the remaining count returned is 3.
;
; (dl=attribute index to start seek from,
;  ecx=rows to count forward or backward,
;  ebx=gui item ptr)
; (edx=new attribute index,
;  ecx=remaining count,
;  esi=attribute info offset,
;  ; ebx)
.SeekRows:
    cmp [ebx+AtrListObj.TotalItems],dl
    jbe .SrErr
    movzx edx,dl
    mov esi,edx
    mov eax,edx                 ;set starting attribute
    imul esi,AtrListObj.Items_size
    push edx                    ;save for later comparison
    add esi,ebx                 ;add item obj offset
    test ecx,ecx                ;check if count < 0 or >= 0
    js .SrbHidden               ;skip current item

.SrfNext:
    test dword [esi+AtrListObj.Flags],AtrListObj.Hidden
    jnz .SrfHidden
    dec ecx
    mov edx,eax
    jl .SrfEnd
.SrfHidden:
    inc eax
    add esi,AtrListObj.Items_size
    cmp [ebx+AtrListObj.TotalItems],al
    ja .SrfNext
.SrfEnd:
    inc ecx
    jmp short .SrEnd

.SrbNext:
    test dword [esi+AtrListObj.Flags],AtrListObj.Hidden
    jnz .SrbHidden
    inc ecx
    mov edx,eax
    jge .SrEnd
.SrbHidden:
    sub esi,AtrListObj.Items_size
    dec eax
    jns .SrbNext
    ;jmp short .SrEnd

.SrEnd:
    pop eax
    cmp dl,al
    clc
    jne .SrChange
.SrErr:
    stc                         ;return if seek caused no change
.SrChange:
    ret

%if 0
;컴컴컴컴컴컴컴컴컴컴
; (dword GUI item ptr, edi=str ptr, ecx=str len, edx=attribute index)
.SetAtr:
    mov ebx,[esp+4]
    cmp [ebx+AtrListObj.TotalItems],dl
    jbe .SvsErr
    call .GetAtrAdr
    mov [esi+AtrListObj.TextPtr],edi
    mov [esi+AtrListObj.TextLen],ecx
    bts dword [esi+AtrListObj.Flags],AtrListObj.Redrawb
    cmc
    jnc .SvsEnd
    jmp SendContainerRedraw.Partial
    ;ret
.SvsErr:
    stc
.SvsEnd:
    ret
%endif
