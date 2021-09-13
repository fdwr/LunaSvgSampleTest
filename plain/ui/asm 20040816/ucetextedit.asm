;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
TextPromptCode:

section data
    StartMsgJtbl
  %ifdef UseFloatMenuCode
   %ifdef WinVer
    AddMsgJtbl MenuMsg.Activate,.MenuChoice
   %endif
  %endif
    AddMsgJtbl Msg.Created,.Created
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.Focus,CommonItemCode.GrabKeyFocus
    AddMsgJtbl Msg.KeyPress,.KeyPress
    AddMsgJtbl Msg.KeyChar,.KeyChar
    AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    AddMsgJtbl Msg.MouseMove,.MouseMove
    AddMsgJtbl Msg.MouseIn,.MouseIn
    AddMsgJtbl Msg.MouseOut,.MouseOut
.KeysJtbl:
    dd .BkSpc
    dd .SeekLeft
    dd .SeekRight
    dd .SeekHome
    dd .SeekEnd
    dd .Delete
.Keys:
    db 0,VK_BACK
    db 0,VK_LEFT
    db 0,VK_RIGHT
    db 0,VK_HOME
    db 0,VK_END
    db 0,VK_DELETE
    db -1

%ifdef UseFloatMenuCode
  %ifdef WinVer
    DefMenuList .Menu,IgnoreMsg
    DefMenuListItem .midCopy,   "Copy",   .imgCopy,   0
    DefMenuListItem .midInsert, "Insert", .imgInsert, 0
    DefMenuListItem .midDelete, "Delete", .imgDelete, 0
    DefMenuListEnd

    DefImageStruct .imgCopy,14,14
    db 0,0,0,0,0,0,2,8,2,2,2,2,2,2
    db 0,4,4,4,4,0,8,9,8,2,2,2,2,2
    db 0,4,4,4,4,8,9,9,8,2,2,2,2,2
    db 0,4,0,0,8,9,9,9,8,1,1,2,2,2
    db 0,4,4,8,9,9,9,9,8,5,1,1,2,2
    db 0,4,8,9,9,9,9,9,8,5,1,5,1,2
    db 0,4,4,8,9,9,9,9,8,5,1,1,1,1
    db 0,4,0,0,8,9,9,9,8,5,5,5,5,1
    db 0,4,4,4,4,8,9,9,8,0,0,0,5,1
    db 0,0,0,0,0,1,8,9,8,5,5,5,5,1
    db 2,2,2,2,2,1,5,8,0,0,0,0,5,1
    db 2,2,2,2,2,1,5,5,5,5,5,5,5,1
    db 2,2,2,2,2,1,1,1,1,1,1,1,1,1
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2
    DefImageStruct .imgInsert,14,14
    db 0,0,0,10,0,0,2,2,2,2,2,2,2,2,0,4,10,11,10,0,0,2,2,2,2,2,2,2,0,4,10,11,11,10,4,0,2,2,2,2,2,2,0,4,10,11,11,11,10,1,1,1,1,2,2,2,0,4,10,11,11,11,11,10,5,5,1,1,2,2,0,4,10,11,11,11,11,11,10,5,1,5,1,2,0,4,10,11,11,11,11,10,0,5,1,1,1,1,0,4,10,11,11,11,10,5,5,5,5,5,5,1,0,4,10,11,11,10,5,0,0,0,0,0,5,1,0,0,10,11,10,1,5,5,5,5,5,5,5,1,2,2,2,10,2,1,5,0,0,0,0,0,5,1,2,2,2,2,2,1,5,5,5,5,5,5,5,1,2,2,2,2,2,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    DefImageStruct .imgDelete,14,14
    db 15,15,2,2,2,2,2,15,15,2,2,2,2,2,15,15,15,2,2,2,15,15,15,2,2,2,2,2,14,15,15,15,2,15,15,15,14,2,2,2,2,2,2,14,15,15,15,15,15,14,1,1,1,2,2,2,2,2,14,15,15,15,14,5,5,5,1,1,2,2,2,2,15,15,15,15,15,5,0,0,1,5,1,2,2,15,15,15,14,15,15,15,5,5,1,1,1,1,15,15,15,14,2,14,15,15,15,5,5,5,5,1,15,15,14,2,2,1,14,15,15,0,0,0,5,1,14,14,2,2,2,1,5,3,3,5,5,5,5,1,2,2,2,2,2,1,5,0,0,0,0,0,5,1,2,2,2,2,2,1,5,5,5,5,5,5,5,1,2,2,2,2,2,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2
  %endif
%endif

section code

    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.Draw:
    push ebp
    mov ebp,esp

    push dword GuiClrGray       ;color
    push dword [ebx+GuiObj.Size]
    push dword 0|(0<<16)        ;row/col
    call DrawRect
    ;add esp,byte 12

    ; draw text string
    mov ebx,[ebp+8]             ;get data ptr
    mov dword [Font.Colors],GuiClrTxtTyped
    mov eax,[ebx+TextPromptObj.ScrollYX]
    push dword [ebx+TextPromptObj.TextLen]
    xor eax,0FFFF0000h
    push dword [ebx+TextPromptObj.TextPtr]
   %ifdef UseSmallScreen
    add eax,00020002h
   %else
    add eax,00020004h
   %endif
    push eax                    ;left column/top row
    call BlitString
    ;add esp,byte 12

    ; calculate cursor position and draw
    mov ebx,[ebp+8]             ;get data ptr
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jnz .DrawNotActive
    mov cx,[ebx+GuiObj.Height]
    push word GuiClrBright
    mov ax,[ebx+TextPromptObj.ScrollX]
    sub cx,byte 2
    neg ax
    push word cx                ;line height
    push ax                     ;left column
    movzx edx,word [ebx+TextPromptObj.CaretCol]
    push word 1                 ;top row
    ;>
    push edx                    ;cursor column is text length
    push dword [ebx+TextPromptObj.TextPtr]
    call GetTextLenWidth
    add esp,byte 8
    ;<
    add [esp+2],ax              ;-scroll column + textwidth
    call DrawVline
    ;add esp,byte 8
.DrawNotActive:

    mov esp,ebp
    pop ebp
    clc
    ret

;컴컴컴컴컴컴컴컴컴컴
.MouseIn:
    ;upon mouse in
    ;  set active
    ;  set cursor image invisible
    ;  grab cursor
    ;endupon

    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetGroup|FocusMsgFlags.SetItem|FocusMsgFlags.ByMouse
    call SendContainerMsg
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jnz .MouseIgnore
    mov esi,GuiCursor.Caret
    jmp SetCursorImage
    ;clc
    ;ret

;컴컴컴컴컴컴컴컴컴컴
.MousePrsRls:
%ifdef UseFloatMenuCode
  %ifdef WinVer

    test dword [Mouse.Buttons],Mouse.RightPress
    jnz .MouseMenu
  %endif
%endif
    test dword [Mouse.Buttons],Mouse.LeftPress
    jnz .MousePress
    test dword [Mouse.Buttons],Mouse.LeftRelease
    jnz .MouseOut
.MouseIgnore:
    ;clc
    ret

%ifdef UseFloatMenuCode
  %ifdef WinVer
.MouseMenu:
    call .MouseOut
    push dword 0                ;no height/width
    push word [Cursor.Col]      ;left
    push word [Cursor.Row]      ;top
    push dword FloatMenuObj.AlignRow|FloatMenuObj.AlignCol
    push dword ebx
    push dword .Menu
    push dword .Menu
    call FloatMenuCode.Show
    add esp,byte 24
    ret
  %endif
%endif

.MouseOut:
    ; release mouse focus
    call ConfineCursor.Release
    jmp CommonItemCode.ReleaseMouse
    ;clc
    ;ret

.MousePress:
    DebugMessage "text prompt mouse press"
    ; confine cursor within prompt
    call CommonItemCode.ConfineCursor

    ;mov esi,GuiCursor.Blank
    ;call SetCursorImage

    ; grab key focus & mouse focus
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.SetContainer|FocusMsgFlags.ByMouse
    call SendContainerMsg
    call CommonItemCode.CaptureMouse
    jmp short .MouseMoved

;컴컴컴컴컴컴컴컴컴컴
.MouseMove:
    ; show cursor again (in case hidden because of typing)
    ; does nothing if already a caret
;    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
;    jnz .NoCursorChange
    push eax
    mov esi,GuiCursor.Caret
    call SetCursorImage
    pop eax
;.NoCursorChange:

    cmp [CommonItemCode.MouseObject],ebx
    jne .MouseNoScroll

.MouseMoved:
    ; check if mouse move is inside text prompt
    ; mouse column is too far left if <=0
    ; too far right if >= width-1
    test eax,MouseMsgFlags.HorizontalPush
    mov ecx,[esp+12]            ;mouse column
    jnz .MouseConstrain
    mov [CommonItemCode.CursorCol],dword 0
    jmp short .MouseReposCaret

.MouseConstrain:
;(ebx=gui item ptr, ecx=mouse cursor column)
    mov esi,[CommonItemCode.CursorCol]
    add esi,[Cursor.ColDif]     ;col accumulation + mouse motion
    add ecx,esi                 ;cursor column += cursor push
    mov [CommonItemCode.CursorCol],esi

.MouseReposCaret:
;(ebx=gui item ptr, ecx=mouse cursor column)
    ; map pixel coordinates to character position
    movsx edx,word [ebx+TextPromptObj.ScrollX]
    push edx                    ;save previous scroll column
    add ecx,edx                 ;mouse column + scroll column
    push ebx

    push ecx                    ;absolute cursor column
    push dword [ebx+TextPromptObj.TextLen]
    push dword [ebx+TextPromptObj.TextPtr]
    call GetTextWidthLen.Nearest
    add esp,byte 12

    mov edx,eax                 ;new cursor position
    pop ebx
    call ._SetCaretPos
    pop edx                     ;retrieve previous scroll column

    sub dx,[ebx+TextPromptObj.ScrollX]  ;get difference between scroll offset before and after the call
    je .MouseNoScroll
    movsx edx,dx
    add [CommonItemCode.CursorCol],edx
.MouseNoScroll:
    clc
    ret

;컴컴컴컴컴컴컴컴컴컴
%ifdef UseFloatMenuCode
  %ifdef WinVer
.MenuChoice:
    cmp eax,MenuMsg.Activate|(.midDelete<<16)
    je .DeleteAll
    cmp eax,MenuMsg.Activate|(.midInsert<<16)
    je .InsertAll
    cmp eax,MenuMsg.Activate|(.midCopy<<16)
    je .CopyAll
    clc
    ret

.DeleteAll:
    xor edx,edx
.SetVars:
    mov [ebx+TextPromptObj.TextLen],edx
    mov [ebx+TextPromptObj.CaretChar],edx
    mov [ebx+TextPromptObj.SelectChar],edx
    mov [ebx+TextPromptObj.CaretCol],dx
    mov [ebx+TextPromptObj.SelectCol],dx
    call .AlignText
    jmp SendContainerRedraw.Partial
    ;clc
    ;ret

.InsertAll:
    api OpenClipboard, [hwnd]
    test eax,eax
    jle .InsertOpenError

    ; get ptr to clipboard data
    api GetClipboardData, 1 ;CF_TEXT
    test eax,eax
    jz .InsertError
    mov esi,eax
    api GlobalLock, eax
    test eax,eax
    jz .InsertError

    ; copy text
    push esi
    mov ecx,[ebx+TextPromptObj.MaxLen]
    mov edi,[ebx+TextPromptObj.TextPtr]
    mov esi,eax
    test ecx,ecx
    jz .InsertFree
    ;cld
.InsertNext:
    cmp byte [esi],0
    je .InsertEnd
    movsb
    dec ecx
    jg .InsertNext
.InsertEnd:
    mov edx,edi
    sub edx,[ebx+TextPromptObj.TextPtr]
    call .SetVars

.InsertFree: ;(memory handle on stack)
    ; free object and redraw
    api GlobalUnlock;, esi

.InsertError:
    api CloseClipboard
.InsertOpenError:
    clc
    ret

.CopyAll:
    api OpenClipboard, [hwnd]
    test eax,eax
    jle .CopyOpenError

    ; allocate memory for text
    mov ecx,[ebx+TextPromptObj.TextLen]
    inc ecx
    api GlobalAlloc, 2|8192, ecx ;GMEM_DDESHARE|GMEM_MOVEABLE
    test eax,eax
    jz .CopyError
    mov esi,eax
    api GlobalLock, eax
    test eax,eax
    jnz .CopyLock
    api GlobalFree,esi
    jmp short .CopyError

.CopyLock: ;(eax=ptr to memory)
    ; copy text to memory object
    push esi                    ;for GlobalUnlock
    push esi                    ;for SetClipbboardData
    mov edi,eax
    mov ecx,[ebx+TextPromptObj.TextLen]
    mov esi,[ebx+TextPromptObj.TextPtr]
    ;cld
    rep movsb
    mov [edi],byte 0            ;append null character for Window's sake
    api GlobalUnlock;, esi

    ; set on clipboard
    api EmptyClipboard
    api SetClipboardData, 1;, esi ;CF_TEXT
.CopyError:
    api CloseClipboard
.CopyOpenError:
    clc
    ret

  %endif
%endif

;컴컴컴컴컴컴컴컴컴컴
%ifdef UseFloatMenuCode
  %ifdef WinVer
.KeyMenu:
    call .MouseOut
    push dword [ebx+GuiObj.Size]
    call GetItemAbsPosition
    ;push word [Cursor.Col]      ;left
    ;push word [Cursor.Row]      ;top
    push cx
    push dx
    push dword FloatMenuObj.AlignRow|FloatMenuObj.AlignCol
    push dword ebx
    push dword .Menu
    push dword .Menu
    call FloatMenuCode.Show
    add esp,byte 24
    ret
  %endif
%endif

;컴컴컴컴컴컴컴컴컴컴
.KeyPress:
    ;upon keypress
    ;  if cursor control key
    ;    move caret
    ;      Left/Right = one character
    ;      Home/End = ends
    ;  elif backspace
    ;    if character position > 0
    ;      delete character before position
    ;      move caret back
    ;    endif
    ;  elif key alphanumeric
    ;    if text length < maxlength
    ;      add character in between position
    ;      advance caret
    ;    endif
    ;  else unrecognized keypress
    ;    return
    ;  endif
    ;  if cursor grabbed
    ;    get width of text up to caret position
    ;    set cursor column position
    ;  endif
    ;endupon

    ; check if key is cursor control (left/right/home/end...) or backspace

  %ifdef UseFloatMenuCode
   %ifdef WinVer
    cmp ah,VK_APPS
    je near .KeyMenu
   %endif
  %endif
    mov esi,.Keys
    call ScanForKey
    jc .KeyNoMatch
    push dword [.KeysJtbl+ecx*4];jump to the right key response
    jmp .BlankCursor

.KeyChar:
    test dword [ebx+TextPromptObj.Flags],TextPromptObj.Locked
    jnz .KeyAck
    call SendOwnerMsg           ;inform owner of key character
    cmp al,Msg.KeyChar          ;did owner change character?
    jne .KeyNoMatch
    push eax                    ;save character
    call .DeleteSelection
    call .BlankCursor
    pop eax
    mov al,ah                   ;bring down ASCII character
    call .InsertChar
    jc .KeyAck
.Change:
    call .AlignText
    ; inform owner of text change
    mov eax,TextPromptMsg.Change
    call SendOwnerMsg.Important ;inform owner of change
.KeyAck:
    clc
.KeyNoMatch: ;(cf=1)
    ret

.BkSpc:
    test dword [ebx+TextPromptObj.Flags],TextPromptObj.Locked
    jnz .DeleteAckCfr
    call .DeleteSelection
    jnc .Change
    mov edx,[ebx+TextPromptObj.CaretChar]
    dec edx
    js .DeleteAck
    call ._SetCaretPos
.Delete:
    test dword [ebx+TextPromptObj.Flags],TextPromptObj.Locked
    jnz .DeleteAckCfr
    mov edx,1
    call .DsLength
    jnc .Change
.DeleteAck:
    clc
.DeleteAckCfr: ;(cf=0)
    ret

.SeekHome:
    xor edx,edx
    jmp short .ScpNoVerify
.SeekEnd:
    mov edx,[ebx+TextPromptObj.TextLen]
    jmp short .ScpNoVerify
.SeekLeft:
    mov edx,-1
    jmp short .ScpRel
.SeekRight:
    mov edx,1
    ;jmp short .ScpRel

;컴컴컴컴컴컴컴컴컴컴
.ScpRel:
;(ebx=gui item ptr, edx=relative caret offset)
;(cf=0 even if cursor pos invalid or same)
    add edx,[ebx+TextPromptObj.CaretChar]
._SetCaretPos:
;(ebx=gui item ptr, edx=caret position)
;(cf=0)
    ; check that position is valid, return if not
    cmp [ebx+TextPromptObj.TextLen],edx
    jb .ScpIgnore
;(ebx=gui item ptr, edx=caret position)
.ScpNoVerify:
    ; check that position is different, return if not
    cmp [ebx+TextPromptObj.CaretChar],edx
    je .ScpIgnore
;(ebx=gui item ptr, edx=caret position)
.ScpNoCheck:
    mov [ebx+TextPromptObj.CaretChar],edx
    mov [ebx+TextPromptObj.SelectChar],edx
    mov [ebx+TextPromptObj.CaretCol],dx
    mov [ebx+TextPromptObj.SelectCol],dx

;(ebx=gui item ptr, edx=caret position)
.ScpCheckScroll:
    ; check that cursor is visible, if not then scroll left or right
    push ebx                    ;save item data
    push edx                    ;cursor position is text length
    push dword [ebx+TextPromptObj.TextPtr]
    call GetTextLenWidth
    add esp,byte 8
    pop ebx

    sub ax,[ebx+TextPromptObj.ScrollX]  ;check if cursor is too far left
    jl .ScpScroll
    sub ax,[ebx+GuiObj.Width]   ;check if cursor is too far right
    inc ax
    jle .ScpNoScroll
.ScpScroll:
;(ax=new base col)
    add [ebx+TextPromptObj.ScrollX],ax
    DebugMessage "text cursor scrolled"
    mov eax,TextPromptMsg.Scroll
    DebugOwnerMsg "text prompt scroll"
    call SendOwnerMsg           ;inform owner of scroll
.ScpNoScroll:

    ; inform owner of caret move
    mov eax,TextPromptMsg.Select
    DebugOwnerMsg "text prompt select"
    call SendOwnerMsg
    jmp SendContainerRedraw.Partial
.ScpIgnore:
    clc
    ret

;컴컴컴컴컴컴컴컴컴컴
.DeleteSelection:
;(ebx=gui item ptr)
;(cf=no change or error; ebx,eax [if no change])
    mov edx,[ebx+TextPromptObj.CaretChar]
    sub edx,[ebx+TextPromptObj.SelectChar]
    jz .DsIgnore
    jns .DsPositive
    add [ebx+TextPromptObj.SelectChar],edx
    not edx
    jmp short .DsWasNegative
.DsPositive:
    sub [ebx+TextPromptObj.CaretChar],edx
.DsWasNegative:
.DsLength:
;(ebx=gui item ptr, edx=length)
;(cf=no change or error; ebx)
    mov ecx,[ebx+TextPromptObj.TextLen]
    mov edi,[ebx+TextPromptObj.CaretChar]
    sub ecx,edx                 ;length -= sellength
    jl .DsIgnore                ;error!
    sub ecx,edi                 ;count = new length - cursor
    jl .DsIgnore
    sub [ebx+TextPromptObj.TextLen],edx  ;length -= sellength
    add edi,[ebx+TextPromptObj.TextPtr]  ;cursor + textptr
    cld
    lea esi,[edi+edx]
    rep movsb                   ;shift remaining text left
    jmp SendContainerRedraw.Partial
    ;ret

.DsIgnore:
    stc
    ret

;컴컴컴컴컴컴컴컴컴컴
.InsertChar:
;(al=character)
;(cf=error or max chars)
    mov ecx,[ebx+TextPromptObj.TextLen]
    mov edi,[ebx+TextPromptObj.TextPtr]
    cmp [ebx+TextPromptObj.MaxLen],ecx
    jbe .IcIgnore
    add edi,ecx                 ;destptr = text ptr + text length
    inc ecx                     ;text length++
    mov [ebx+TextPromptObj.TextLen],ecx
    mov edx,[ebx+TextPromptObj.CaretChar]
    lea esi,[edi-1]             ;srcptr = destptr - 1
    inc edx                     ;cursor++
    sub ecx,edx                 ;shift count = text length - cursor pos
    jl .IcIgnore

    ; shift text after text to the right first & insert character
    std
    rep movsb                   ;shift remaining text right
    cld                         ;clear df so dumb Windows doesn't crash
    mov [edi],al                ;insert typed character

    call ._SetCaretPos

    ; container redraw
    jmp SendContainerRedraw.Partial
    ;ret

.IcIgnore   equ .DsIgnore

;컴컴컴컴컴컴컴컴컴컴
.Created:
    mov edx,[ebx+TextPromptObj.CaretChar]
    call .ScpCheckScroll
    ;call .AlignText
    ;ret

;컴컴컴컴컴컴컴컴컴컴
.AlignText:
; Aligns to according the specified alignment. Also if a change in the text
; left blank space on either side of text, If so, it scrolls so that as more
; of the text fits (shows) in the prompt.

    ; determine pixel width of text
    push ebx                    ;save item data
    push dword [ebx+TextPromptObj.TextLen]
    push dword [ebx+TextPromptObj.TextPtr]
    call GetTextLenWidth
    add esp,byte 8
    pop ebx
    inc ax
    sub ax,[ebx+GuiObj.Width]   ;text width - item width + 1
    jge .AtWide

.AtThin:
    test dword [ebx+TextPromptObj.Flags],TextPromptObj.AlignRight
    jnz .AtRight
    test dword [ebx+TextPromptObj.Flags],TextPromptObj.AlignCenter
    jnz .AtCenter
.AtLeft:
    xor ax,ax
    jmp short .AtScroll
.AtCenter:
    sar ax,1
    jmp short .AtScroll

.AtRight:
.AtScroll:
    ; inform owner of scroll change
    cmp [ebx+TextPromptObj.ScrollX],ax
    je .AtNoChange
.AtScrollNow:
    mov [ebx+TextPromptObj.ScrollX],ax
    mov eax,TextPromptMsg.Scroll
    DebugOwnerMsg "text prompt scroll"
    call SendOwnerMsg
.AtNoScroll:
    clc
.AtNoChange: ;(cf=0)
    ret

.AtWide:
    cmp [ebx+TextPromptObj.ScrollX],ax
    jg .AtScrollNow
    xor ax,ax
    cmp [ebx+TextPromptObj.ScrollX],ax
    jl .AtScrollNow
    clc
    ret

;컴컴컴컴컴컴컴컴컴컴
.BlankCursor:
    test dword [ebx+GuiObj.Flags],GuiObj.MouseFocus
    jz .NoBlankCursor
    mov esi,GuiCursor.Blank
    jmp SetCursorImage
.NoBlankCursor:
    ret
