;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Window Control Element code
;
; None of these routines are necessary. This entire file could be left out
; and the source could still compile without errors, but you would be missing
; the main point of object oriented GUIs, the objects!
;
; Since a program may use only some of these types, only the routines defined
; as 'used' are compiled into the executable.
; For example, if a program never uses the attribute list, just
; leave UseAtrListCode undefined.
;
; ItemCode              miscellaneous common functions
; WindowCode            moveable container for other items
; FrameCode             embedded container for other items
; WindowBgCode          generic bordered window background
; TitleBarCode          displays a window's caption, allows you to move it
; TextPromptCode        lets you type in new or editing existing text
; LabelCode             displays text
; ImageCode             displays image
; BorderCode            concave edge around item or group of items
; ScrollHandleCode      scroll position indicator
; ButtonCode            button that can be pushed/toggled/locked
; DebugObjCode          special debug object
; AtrListCode           vertical list of attribute values
; MainBgCode            generic solid background
; TabStripCode          quick 'buttons' to select different windows
; AtrBarCode            row of attributes at bottom of screen, like status bar
; ListCode              scrollable list of text rows, supporting multiple cols
; HelpBubbleCode        small, informative floating text
; ProgressBarCode       progress indicator using colored bar
; EmbedMenuCode         permanently open menu embedded into a window's side
; FloatMenuCode         floating list of choices
; MenuCode              shared menu code
;
; Complete: Container window, Button, Text prompt, Attribute list
; Mostly:   Title bar, Scroll handle, Static images, Float Menu, Main Bg
; Somewhat: Tabs, Attribute bar, Embed Menu
; Nada:     List, Help buble, Progress bar
;
; "Complete" means the object has everything it needs to be functional (as I
; originally envisioned it), but additional future features may be added.
;
; Acknowledging messages:
; For any message not recognized, a -1 should be returned. Very few functions
; should return this as a valid value, since that would make it impossible to
; tell whether the UCE did not recognize the message or did recognize it but
; simply returned a -1.
;
; Message Order:
; Input messages always go through the container the first, then its items.
; Some messages are checked by the container before passing them onto the
; proper items. Other messages are checked afterwards, only if the item
; ignored them.
;
; Returning values:
; Items can returns values in eax like any other function (assuming that
; particular message warrants a return value). Messages that are completely
; ignored should be kept the same, since some items check if the message has
; been changed. For example, when the text prompt sends a keypress message to
; its owner, it checks whether the owner wants the key ignored or translated
; by checking if the message has changed after the call. An item need not
; return the message sent to it intact if it was processed.
;
; Rules
;   Unknown messages must be returned with an error
;   Key order may changed anytime except within a KeyFocus message
;   Layer order may changed anytime except during a Redraw
;   No messages should be sent to containers or siblings during redraw

section code

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
CommonItemCode:

;컴컴컴컴컴컴컴컴컴컴
; (ebx=gui item ptr) (; ebx)
.CaptureMouse:
    mov [CommonItemCode.MouseObject],ebx
    mov eax,Msg.SetMouseFocus|MouseMsgFlags.SetContainer
    jmp SendContainerMsg

;컴컴컴컴컴컴컴컴컴컴
.ReleaseMouse:
; (ebx=gui item ptr) (cf=0)
; this function can not be used by containers, by items at the end of a chain
    cmp [CommonItemCode.MouseObject],ebx
    jne .RmEnd

;컴컴컴컴컴컴컴컴컴컴
.ReleaseMouseNow:
    ; release mouse focus
    mov eax,Msg.SetMouseFocus|MouseMsgFlags.Reset|MouseMsgFlags.SetContainer
    call SendContainerMsg
    mov [CommonItemCode.MouseObject],dword 0
.RmEnd:
    clc
    ret

;컴컴컴컴컴컴컴컴컴컴
; (ebx=gui item ptr) (cf=0; ebx)
.ConfineCursor:
    call GetItemAbsPosition
    push dword [ebx+GuiObj.Size]
    push cx
    push dx
    call ConfineCursor
    add esp,byte 8
    ret

;컴컴컴컴컴컴컴컴컴컴
; (ebx=gui item ptr, eax=optional item focus flags) (; ebx)
.GrabKeyFocus:
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jnz near SendContainerRedraw.Partial
    and eax,KeyMsgFlags.ByMouse|KeyMsgFlags.Repeat
    or eax,Msg.SetKeyFocus|KeyMsgFlags.SetContainer
    call SendContainerMsg
    jmp SendContainerRedraw.Partial


section data
align 4, db 0
.MouseObject:   dd 0            ;last object to be 'grabbed' by mouse, null if none
.CursorRow:     dd 0
.CursorCol:     dd 0

; below are a few generic variables that can be used by any items for various
; purposes, rather than duplicating these variables in each of the item
; routines or allocating them on the stack every time. note though, these
; variables may ONLY be used in nonrecursive procedures, such as during
; the redraw of an item. anytime an item needs to send an owner/container
; message or call a nonlocal function, it should instead allocate them on the
; stack.
.DrawPos:
.DrawRowW:
.DrawColW       equ $+2
.DrawRow:       dd 0
.DrawCol:       dd 0
.DrawSize:
.DrawHeight:    dw 0
.DrawWidth:     dw 0
.SelRow:        dd 0
.SelCol:        dd 0
.GuiFlags:      dd 0
.ColorMap:      dd 0
section code


%ifdef UseWindowCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; The mother of all other items. Well, actually the container of all other
; items, including subcontainers. Note that the WindowCode has no visible
; form except that which the items inside it give it, So NO drawing is
; performed by the WindowCode. It is purely a container for other items that
; do draw themselves, which are called by simply jumping to SendRedrawMsgs.
;
; Whatever the last active item was before the window lost focus will become
; active upon the window receiving focus again. Internal set key focus
; messages are processed, but visible changes might not occur until the
; container regains focus.

WindowCode:

section data
    StartMsgJtbl
    AddMsgJtbl Msg.Created,SendMsgAllItems.GivenWinPtr
    AddMsgJtbl Msg.Destroyed,SendMsgAllItems.GivenWinPtr
    AddMsgJtbl Msg.Redraw,SendRedrawSimple.GivenWinPtr
    AddMsgJtbl Msg.Focus,.Focus
    AddMsgJtbl Msg.KeyPress,.KeyPress
    AddMsgJtbl Msg.KeyRelease,SendKeyMsg.GivenWinPtr
    AddMsgJtbl Msg.KeyChar,SendKeyMsg.GivenWinPtr
    AddMsgJtbl Msg.KeyIn,SetKeyFocus.OfActive
    AddMsgJtbl Msg.KeyOut,SetKeyFocus.OfActive
    AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    AddMsgJtbl Msg.MouseMove,SendMouseMsg
    AddMsgJtbl Msg.MouseIn,.MouseIn
    AddMsgJtbl Msg.MouseOut,SetMouseFocus.OfActive
    AddMsgJtbl Msg.Create,CreateItem
    AddMsgJtbl Msg.Destroy,DestroyItem
    AddMsgJtbl Msg.RedrawItem,SendContainerRedraw.Partial
    AddMsgJtbl Msg.SetFlags,SetItemFlags
    AddMsgJtbl Msg.MoveSize,MoveSizeItem.GivenWinPtr
    AddMsgJtbl Msg.SetItemFocus,SetItemFocus
    AddMsgJtbl Msg.SetKeyFocus,SetKeyFocus
    AddMsgJtbl Msg.SetMouseFocus,SetMouseFocus
    AddMsgJtbl Msg.SetLayer,SetLayerOrder
    AddMsgJtbl Msg.GetItemFocus,GetItemFocus
    AddMsgJtbl Msg.GetKeyFocus,GetKeyFocus
    AddMsgJtbl Msg.GetMouseFocus,GetMouseFocus
.TabMsgsTbl:
    dd FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|                       FocusMsgFlags.Reverse
    dd FocusMsgFlags.SetGroup|FocusMsgFlags.Relative
    dd FocusMsgFlags.SetItem| FocusMsgFlags.SetGroup|FocusMsgFlags.Relative
    dd FocusMsgFlags.SetItem| FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|FocusMsgFlags.Reverse
    dd FocusMsgFlags.SetItem| FocusMsgFlags.Relative
    dd FocusMsgFlags.SetItem| FocusMsgFlags.Relative|FocusMsgFlags.Reverse
    ;dd FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|FocusMsgFlags.NoWrap 
    ;dd FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|FocusMsgFlags.NoWrap|FocusMsgFlags.Reverse
.TabKeys:
    db 2,VK_TAB,    2,VK_SHIFT,     1,VK_CONTROL
    db 2,VK_TAB,                    1,VK_CONTROL
    db 0,VK_DOWN
    db 0,VK_UP
    db 0,VK_RIGHT
    db 0,VK_LEFT
    ;db 2,VK_RIGHT,  0,VK_CONTROL
    ;db 2,VK_LEFT,   0,VK_CONTROL
    db -1
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
; if mouse focus in then grab key focus too
; pass on message to active item
.MouseIn:
    push eax                    ;preserve mouse message
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.SetContainer|FocusMsgFlags.ByMouse
    call SendContainerMsg
    pop eax
    jmp SetMouseFocus.OfActive

;컴컴컴컴컴컴컴컴컴컴
; if left press then bring window to front
.MousePrsRls:
    test dword [Mouse.Buttons],Mouse.LeftPress
    jz near SendMouseMsg        ;ignore any other buttons
    push eax                    ;preserve mouse message
    mov eax,Msg.SetLayer|LayerMsgFlags.SetItem
    call SendContainerMsg
    pop eax
    jmp SendMouseMsg
    ;ret

; To only chain messages to items, use this
;.MousePrsRls    equ SendMouseMsg

;컴컴컴컴컴컴컴컴컴컴
.KeyPress:
    ; Pass key character to active item. Upon return, if the item ignored the
    ; keypress (carry was set), check if the keypress is tab or an arrow key.
    push eax
    push ebx
    call SendKeyMsg.GivenWinPtr
    pop ebx
    pop eax
    jc .KeyCheck
.KeyIgnored:
    ret

.KeyCheck:
    ;DebugMessage "item ignored key"
    ;mov eax,[Keyboard.LastMsg]
    mov esi,.TabKeys
    call ScanForKey
    jc .KeyIgnored
    mov eax,[.TabMsgsTbl+ecx*4]
    ;push ebx                   ;window data structure
    jmp SetItemFocus            ;send key focus
    ;pop ebx
    ;clc
    ;ret

;컴컴컴컴컴컴컴컴컴컴
.Focus:
    push ebx
    call SetItemFocus.OfActive
    pop ebx
    mov eax,Msg.SetKeyFocus|KeyMsgFlags.SetContainer
    jmp SendContainerMsg
    ;ret

%endif


%ifdef UseFrameCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Exactly like WindowCode, except that clicking on a frame will not change
; its layer, and tabbing out of a frame is allowed.

FrameCode:

section data
    StartMsgJtbl
    AddMsgJtbl Msg.Created,SendMsgAllItems.GivenWinPtr
    AddMsgJtbl Msg.Destroyed,SendMsgAllItems.GivenWinPtr
    AddMsgJtbl Msg.Redraw,SendRedrawSimple.GivenWinPtr
    AddMsgJtbl Msg.Focus, .Focus
    AddMsgJtbl Msg.KeyPress,.KeyPress
    AddMsgJtbl Msg.KeyRelease,SendKeyMsg.GivenWinPtr
    AddMsgJtbl Msg.KeyChar,SendKeyMsg.GivenWinPtr
    AddMsgJtbl Msg.KeyIn,SetKeyFocus.OfActive
    AddMsgJtbl Msg.KeyOut,SetKeyFocus.OfActive
    AddMsgJtbl Msg.MousePrsRls,SendMouseMsg
    AddMsgJtbl Msg.MouseMove,SendMouseMsg
    AddMsgJtbl Msg.MouseIn,WindowCode.MouseIn
    AddMsgJtbl Msg.MouseOut,SetMouseFocus.OfActive
    AddMsgJtbl Msg.Create,CreateItem
    AddMsgJtbl Msg.Destroy,DestroyItem
    AddMsgJtbl Msg.RedrawItem,SendContainerRedraw.Partial
    AddMsgJtbl Msg.MoveSize,MoveSizeItem.GivenWinPtr
    AddMsgJtbl Msg.SetItemFocus,SetItemFocus
    AddMsgJtbl Msg.SetKeyFocus,SetKeyFocus
    AddMsgJtbl Msg.SetMouseFocus,SetMouseFocus
    AddMsgJtbl Msg.SetLayer,SetLayerOrder
    AddMsgJtbl Msg.GetItemFocus,GetItemFocus
    AddMsgJtbl Msg.GetKeyFocus,GetKeyFocus
    AddMsgJtbl Msg.GetMouseFocus,GetMouseFocus
.TabMsgsTbl:
    dd FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|FocusMsgFlags.NoWrap|FocusMsgFlags.Reverse
    dd FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|FocusMsgFlags.NoWrap
    dd FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.Relative
    dd FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|FocusMsgFlags.Reverse
    dd FocusMsgFlags.SetItem|FocusMsgFlags.Relative
    dd FocusMsgFlags.SetItem|FocusMsgFlags.Relative|FocusMsgFlags.Reverse
    ;dd FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|FocusMsgFlags.NoWrap 
    ;dd FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|FocusMsgFlags.NoWrap|FocusMsgFlags.Reverse
.TabKeys:
    db 2,VK_TAB,    0,VK_SHIFT
    db 0,VK_TAB
    db 0,VK_DOWN
    db 0,VK_UP
    db 0,VK_RIGHT
    db 0,VK_LEFT
    ;db 2,VK_RIGHT,  0,VK_CONTROL
    ;db 2,VK_LEFT,   0,VK_CONTROL
    db -1
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
; if mouse focus in then grab key focus too
; pass on message to active item
.MouseIn:
    push eax                    ;preserve mouse message
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.SetContainer|FocusMsgFlags.ByMouse
    call SendContainerMsg
    pop eax
    jmp SetMouseFocus.OfActive

;컴컴컴컴컴컴컴컴컴컴
.KeyPress:
    ; Pass key character to active item. Upon return, if the item ignored the
    ; keypress (carry was set), check if the keypress is tab or an arrow key.
    push eax
    push ebx
    call SendKeyMsg.GivenWinPtr
    pop ebx
    pop eax
    jc .KeyCheck
.KeyRet: ;(cf=0/1)
    ret

.KeyCheck:
    ;mov eax,[Keyboard.LastMsg]
    mov esi,.TabKeys
    call ScanForKey
    jc .KeyRet
    mov eax,[.TabMsgsTbl+ecx*4]
    push ebx                   ;window data structure
    call SetItemFocus            ;send key focus
    pop ebx
    ret
    ;jnc .KeyRet

    cmp byte [Keyboard.LastVkCode],VK_TAB
    jne .KeyRet
    debugwrite "FrameCode: could not tab focus"
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Relative
    call SendContainerMsg
    clc
    ret

;컴컴컴컴컴컴컴컴컴컴
.Focus:
    ; if relative focus set && window items > 0
    ;   if forward
    ;     get first item
    ;   else backward
    ;     get last item
    ;   endif
    ;   set item focus group relative
    ; endif
    ; set all item's focus
    ; grab key focus for frame

    test eax,FocusMsgFlags.Relative
    jz .FocusSet
    movzx ecx,word [ebx+WindowObj.TotalItems]
    test ecx,ecx
    jle .FocusSet

    test eax,FocusMsgFlags.Reverse
    jnz .FocusReverse
    movzx esi,word [ebx+WindowObj.ItemsKeyIdx+ecx*8-8]
    jmp short .FocusForward
.FocusReverse:
    movzx esi,word [ebx+WindowObj.ItemsKeyIdx]
.FocusForward:

    and eax,FocusMsgFlags.ByMouse|FocusMsgFlags.Reverse
    push dword [ebx+WindowObj.ItemsPtr+esi*8]
    push ebx
    or eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.Relative|FocusMsgFlags.SetGroup
    call SetItemFocus
    add esp,byte 8

.FocusSet:
    push ebx
    call SetItemFocus.OfActive
    pop ebx

    ; this redundancy is just in case there are no active contained items
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jnz .NotFullFocus
    mov eax,Msg.SetKeyFocus|KeyMsgFlags.SetContainer
    call SendContainerMsg
.NotFullFocus:
    ret

%endif


%ifdef UseWindowBgCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; A common convex edged window border. You can grab on the border to drag the
; window around.
;
WindowBgCode:

section data
    StartMsgJtbl
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    AddMsgJtbl Msg.MouseMove,.MouseMove
    AddMsgJtbl Msg.MouseIn,SetCursorImage.Default
    AddMsgJtbl Msg.MouseOut,CommonItemCode.ReleaseMouse
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.Draw:
; (unfinished)
; When a window redraws itself
; merge area to be redrawn within background area to be redrawn
; if any area of its background needs redrawing
;   select background type
;   when solid color
;     draw rectangle
;   when tiled pattern
;     draw pattern tile from left to right, top to bottom
;   when picture
;     draw picture starting at top left
;   endselect
; endif

    mov eax,[ebx+GuiObj.Size]
    mov ebx,[ebx+GuiObj.Container]  ;get container to find size
    push dword DrawBorder.Filled
    mov edx,[ebx+GuiObj.Size]
    cmp ax,dx
    jb .BgHeightFine
    mov ax,dx
.BgHeightFine:
    cmp eax,edx
    jb .BgWidthFine
    mov eax,edx
.BgWidthFine:

    push eax
    push dword 0                    ;top/left
    call DrawBorder
    add esp,byte 12
    ;clc (add clears cf)
    ret

;컴컴컴컴컴컴컴컴컴컴
.MousePrsRls:
    ;if left press
    ;  lock cursor relative to position clicked
    ;elif left release
    ;  if cursor locked then release
    ;endif

    test dword [Mouse.Buttons],Mouse.LeftPress
    jnz .MousePress
    test dword [Mouse.Buttons],Mouse.LeftRelease
    jnz .MouseRelease
.IgnoreMouse:
    stc
    ret

.MousePress:
    mov esi,[ebx+GuiObj.Container]
    test dword [esi+GuiObj.Flags],GuiObj.FixedPosition
    jnz .IgnoreMouse
    DebugMessage "window bg grab"
    call CommonItemCode.CaptureMouse
    mov eax,Msg.SetItemFocus|FocusMsgFlags.SetContainer|FocusMsgFlags.ByMouse
    call SendContainerMsg
    mov esi,GuiCursor.Move
    jmp SetCursorImage
    ;clc
    ;ret

.MouseRelease:
    call CommonItemCode.ReleaseMouse
    jmp SetCursorImage.Default
    ;clc
    ;ret

;컴컴컴컴컴컴컴컴컴컴
.MouseMove:
    ;if cursor locked
    ;  move container window by cursor change
    ;endif

    cmp [CommonItemCode.MouseObject],ebx
    jne .IgnoreMouse

    ; move container by sending message to its container
    DebugMessage "window bg drag"
    mov edx,[Cursor.RowDif]     ;mouse row difference
    mov ebx,[ebx+GuiObj.Container]
    mov ecx,[Cursor.ColDif]     ;mouse column difference
    add dx,[ebx+GuiObj.Top]
    add cx,[ebx+GuiObj.Left]
    push dword 80008000h        ;size (unchanged)
    push cx
    push dx
    mov eax,Msg.MoveSize
    call SendContainerMsg
    add esp,byte 8
    ;clc
    ret
%endif


%ifdef NotFinishedYet ;UseWindowBgCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Shadow behind window. *** unfinished ***
;
ShadowBgCode:
    cmp al,Msg.Redraw
    je .Draw
    stc
    ret

;컴컴컴컴컴컴컴컴컴컴
.Draw:
%if 1
    push dword 1
    push dword [ebx+GuiObj.Size]
    push dword 0
    call DrawShade
    add esp,byte 12
    ;clc (add clears cf)
    ret
%endif

%if 0
    mov eax,[ebx+GuiObj.Size]
    mov ebx,[ebx+GuiObj.Container]  ;get container to find size
    push dword DrawBorder.Filled
    mov edx,[ebx+GuiObj.Size]
    cmp ax,dx
    jb .BgHeightFine
    mov ax,dx
.BgHeightFine:
    cmp eax,edx
    jb .BgWidthFine
    mov eax,edx
.BgWidthFine:
%endif

%if 0
    mov edx,[ebx+GuiObj.Pos]
    mov ebx,[ebx+GuiObj.Container]  ;get container to find size
    mov eax,[ebx+GuiObj.Size]

    push edx
    push eax

    push dword 1
    push eax                    ;size
    mov [esp],dx
    sub eax,edx
    sub eax,edx
    and eax,0FFFFh
    push eax                    ;position

    ;push dword [ebx+GuiObj.Size]
    ;push dword 0
    call DrawShade
    add esp,byte 12

    pop eax
    pop edx


%if 0
    push dword 1
    push edx                    ;size
    mov [esp],ax
    sub edx,eax
    sub edx,eax
    and edx,0FFFFh
    xor edx,edx
    push edx                    ;position
%endif

    ;push dword [ebx+GuiObj.Size]
    ;push dword 0
    ;call DrawShade
    ;add esp,byte 12


    ;clc (add clears cf)
    ret
%endif
%endif


%ifdef UseMainBgCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; The main background of the GUI. My own 'non-client' region of the window.
;
MainBgCode:

section data
    StartMsgJtbl
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.Focus,SendContainerRedraw.Partial
    AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    AddMsgJtbl Msg.MouseMove,.MouseMove
    AddMsgJtbl Msg.MouseIn,SetCursorImage.Default
    AddMsgJtbl Msg.MouseOut,CommonItemCode.ReleaseMouse

.TitleRect:
%ifdef UseSmallScreen
dd 3,3, 1024,3+FontDefHeight
%else
dd 6,6, 2048,6+FontDefHeight
%endif

.ColorMapDim:    dw GuiClrFace,GuiClrDGray,0,GuiClrLGray
.ColorMapBright: dw GuiClrFace,GuiClrDGray,0,GuiClrWhite

.ColorMap:  equ CommonItemCode.ColorMap

%define a GuiClrBlack
%define b GuiClrDGray
%define i GuiClrFace
%define d GuiClrLGray
%define e GuiClrBGray
%ifdef UseSmallScreen
DefImageStruct .HandleTile, 8,8
    db 4,1,i,i,4,1,i,i
    db i,i,4,1,i,i,4,1
    db 4,1,i,i,4,1,i,i
    db i,i,4,1,i,i,4,1
    db 4,1,i,i,4,1,i,i
    db i,i,4,1,i,i,4,1
    db 4,1,i,i,4,1,i,i
    db i,i,4,1,i,i,4,1
%else
DefImageStruct .HandleTile, 16,12
 %if 0 ;8bit
    db 4,1,i,i,i,i,4,1,i,i,i,i
    db 3,0,i,i,i,i,3,0,i,i,i,i
    db i,i,i,4,1,i,i,i,i,4,1,i
    db i,i,i,3,0,i,i,i,i,3,0,i
    db 4,1,i,i,i,i,4,1,i,i,i,i
    db 3,0,i,i,i,i,3,0,i,i,i,i
    db i,i,i,4,1,i,i,i,i,4,1,i
    db i,i,i,3,0,i,i,i,i,3,0,i
    db 4,1,i,i,i,i,4,1,i,i,i,i
    db 3,0,i,i,i,i,3,0,i,i,i,i
    db i,i,i,4,1,i,i,i,i,4,1,i
    db i,i,i,3,0,i,i,i,i,3,0,i
    db 4,1,i,i,i,i,4,1,i,i,i,i
    db 3,0,i,i,i,i,3,0,i,i,i,i
    db i,i,i,4,1,i,i,i,i,4,1,i
    db i,i,i,3,0,i,i,i,i,3,0,i
 %else ;16bit
    dw e,b,i,i,i,i,e,b,i,i,i,i
    dw d,a,i,i,i,i,d,a,i,i,i,i
    dw i,i,i,e,b,i,i,i,i,e,b,i
    dw i,i,i,d,a,i,i,i,i,d,a,i
    dw e,b,i,i,i,i,e,b,i,i,i,i
    dw d,a,i,i,i,i,d,a,i,i,i,i
    dw i,i,i,e,b,i,i,i,i,e,b,i
    dw i,i,i,d,a,i,i,i,i,d,a,i
    dw e,b,i,i,i,i,e,b,i,i,i,i
    dw d,a,i,i,i,i,d,a,i,i,i,i
    dw i,i,i,e,b,i,i,i,i,e,b,i
    dw i,i,i,d,a,i,i,i,i,d,a,i
    dw e,b,i,i,i,i,e,b,i,i,i,i
    dw d,a,i,i,i,i,d,a,i,i,i,i
    dw i,i,i,e,b,i,i,i,i,e,b,i
    dw i,i,i,d,a,i,i,i,i,d,a,i
 %endif
%endif
%undef a
%undef b
%undef i
%undef d
%undef e

%ifdef WinVer
section bss
alignb 4
.EdgeRect:  resb RECT_size      ;used when user grabs window to move it
                                ;holds the dimensions of the desktop area
%endif

section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.Draw:
; (unfinished)
; When a window redraws itself
; merge area to be redrawn within background area to be redrawn
; if any area of its background needs redrawing
;   select background type
;   when solid color
;     draw rectangle
;   when tiled pattern
;     draw pattern tile from left to right, top to bottom
;   when picture
;     draw picture starting at top left
;   endselect
; endif

    push ebp
    mov edi,[ebx+GuiObj.Container]  ;get container to find size
    mov ebp,esp
    push dword [ebx+TitleBarObj.Flags]
    push dword [edi+GuiObj.Size];container height/width

;+ebp
.ItemPtr    equ 8
.Flags      equ -4
.Width      equ -6
.Height     equ -8
.Size       equ -8

 %ifdef UseTitleBarCode
    test dword [ebx+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.RedrawForced
    jnz .RedrawAll
    mov esi,.TitleRect
    call AndClips.ToDisplay
.RedrawAll:
 %endif

    push dword GuiClrFace
    push dword 2048|(2048<<16)  ;height/width
    push dword 0                ;top/left
    call DrawRect
    ;add esp,byte 12
    push dword DrawBorder.Convex
    push dword [ebp+.Size]      ;height/width
    push dword 0                ;top/left
    call DrawBorder
    ;add esp,byte 12

 %ifdef UseTitleBarCode
    ; title text
   %ifdef UseSmallScreen
    cmp dword [Display.ClipTop],12
   %else
    cmp dword [Display.ClipTop],24
   %endif
    jae near .DrawNoTitle
    mov ebx,[ebp+.ItemPtr]

    ; set bright color if program active
    mov ecx,GuiClrTxtNormal
    mov edx,.ColorMapDim
    test dword [ebx+GuiObj.Flags],GuiObj.ContainerFocus
    jnz .DrawInactive
    mov ecx,GuiClrTxtBright
    mov edx,.ColorMapBright
.DrawInactive:
    mov dword [Font.Colors],ecx
    mov [.ColorMap],edx

    ; draw string
    push dword [ebx+TitleBarObj.TextLen]    ;< this is for GetTextLenWidth
    push dword [ebx+TitleBarObj.TextPtr]    ;>
    push dword [ebx+TitleBarObj.TextLen]
    push dword [ebx+TitleBarObj.TextPtr]
   %ifdef UseSmallScreen
    push dword 00030003h        ;left column/top row
   %else
    push dword 00060006h        ;left column/top row
   %endif
    call BlitString
    add esp,byte 12

    ; calculate handle width
    ;push dword [ebx+TitleBarObj.TextLen]
    ;push dword [ebx+TitleBarObj.TextPtr]
    call GetTextLenWidth
    ;add esp,byte 8
  %ifdef UseSmallScreen
    add eax,byte 3+2            ;text width += spacing left side
  %else
    add eax,byte 6+4            ;text width += spacing left side
  %endif
    movzx ecx,word [ebp+.Width] ;item height/width
    mov edx,[ebp+.Flags]
    sub ecx,eax                 ;item width - text width - left side
    and edx,TitleBarObj.CloseButton|TitleBarObj.HelpButton|TitleBarObj.MaxButton|TitleBarObj.MinButton
.FirstButtonBit:
    jz .LastButtonBit
.NextButtonBit:
    shr edx,1
    jnc .FirstButtonBit
  %ifdef UseSmallScreen
    sub ecx,byte 8              ;handle width -= button spacing
  %else
    sub ecx,byte 16             ;handle width -= button spacing
  %endif
    jmp short .NextButtonBit
.LastButtonBit:
  %ifdef UseSmallScreen
    sub ecx,byte 3+2-1          ;handle width -= spacing right side
  %else
    sub ecx,byte 6+4-2          ;handle width -= spacing right side
  %endif

  %if 1
    ; draw rivets, the 'handle' portion
    push dword .HandleTile
    push cx                     ;width
   %ifdef UseSmallScreen
    push word 8                 ;height
    push ax                     ;left
    push word 3                 ;top
   %else
    push word 16                ;height
    push ax                     ;left
    push word 5                 ;top
   %endif
    call DrawImageTiled
    ;add esp,byte 12

  %else
    ; draw horizontal grips, the 'handle' portion
    push dword DrawBorder.Concave
    push cx                     ;width
    push word 4                 ;height
    push ax                     ;left
    push word 5                 ;top
    call DrawBorder
    add word [esp],byte 5
    call DrawBorder
    add word [esp],byte 5
    call DrawBorder
    ;add esp,byte 12
  %endif

    ; draw buttons
    mov eax,[ebp+.Flags]
    mov ecx,[ebp+.Size]         ;container height/width
    mov esi,TitleBarCode.CloseImg
   %ifdef UseSmallScreen
    sub ecx,(7+3)<<16           ;col=titlebar width-button size
    mov [TitleBarCode.ButtonInc],dword 8<<16 ;8 pixels left
    mov cx,3                    ;set row=1
   %else
    sub ecx,(14+6)<<16          ;col=titlebar width-button size
    mov [TitleBarCode.ButtonInc],dword 16<<16 ;pixels left increment
    mov cx,6                    ;set row
   %endif
    test eax,TitleBarObj.CloseButton
    call TitleBarCode.DrawButton
    test eax,TitleBarObj.HelpButton
    call TitleBarCode.DrawButton
    test eax,TitleBarObj.MaxButton
    call TitleBarCode.DrawButton
    test eax,TitleBarObj.MinButton
    call TitleBarCode.DrawButton
 %endif


 %if 0 ;palette debugging
    mov eax,3020100h
    mov edi,Screen.Buffer;+(Screen.Width*(Screen.Height-12))
.NextPixelRow:
    mov ecx,32
.NextPixelDw:
    mov [edi],eax
    add edi,Screen.Width
    loop .NextPixelDw
    add edi,4-(Screen.Width*32)
    add eax,4040404h
    cmp al,252
    jg .NextPixelRow
 %endif

.DrawNoTitle:
    ;clc
    mov esp,ebp
    pop ebp
    ret

;컴컴컴컴컴컴컴컴컴컴
.MousePrsRls:
    ;if left press
    ;  lock cursor relative to position clicked
    ;elif left release
    ;  if cursor locked then release
    ;endif

    test dword [Mouse.Buttons],Mouse.LeftPress
    jnz near .MousePress
    test dword [Mouse.Buttons],Mouse.RightPress
    jnz .MouseMenu
    test dword [Mouse.Buttons],Mouse.LeftRelease
    jnz .MouseRelease
.IgnoreMouse:
    stc
    ret

.MouseRelease:
    call CommonItemCode.ReleaseMouse
    jmp SetCursorImage.Default
    ;clc
    ;ret

.MouseMenu:
  %ifdef WinVerz
    ; show Window's system menu
    cmp dword [esp+8],22        ;mouse row
    jae .IgnoreMenu
    api GetSystemMenu, [hwnd],FALSE
    push eax
    push eax,dword SC_MOVE,dword MF_ENABLED
    push eax,dword SC_MINIMIZE,dword MF_ENABLED
    api EnableMenuItem
    api EnableMenuItem
    pop eax
    api TrackPopupMenuEx, eax, 0,[msg+MSG.x],[msg+MSG.y], [hwnd],NULL
  %endif
.IgnoreMenu:
    stc
    ret

%ifdef WinVer
.Help:
    api MessageBox, [hwnd],"Sorry, no help yet. Have a nice day :)",Program.Title,MB_OK|MB_ICONEXCLAMATION|MB_SETFOREGROUND|MB_TOPMOST
    ret
.Close:
    api PostQuitMessage, 0
    ret
.Minimize:
    ;api ReleaseCapture
    api ShowWindow, [hwnd],SW_MINIMIZE
    ret
%else

.Close:
    and dword [GuiFlags],~GuiFlags.Active
.Help:
.Minimize:
    ret

%endif

.MousePress:
    ; if over buttons
    ;   switch
    ;   case minimize
    ;   case close
    ;   case help
    ;   endswitch
    ; else
    ;   capture mouse
    ;   set cursor image
    ; endif

  %ifdef UseTitleBarCode
    mov edx,[esp+8]             ;mouse row
   %ifdef UseSmallScreen
    cmp edx,11
    jae .HandleGrab
    cmp edx,3
    jb .HandleGrab
   %else
    cmp edx,22
    jae .HandleGrab
    cmp edx,6
    jb .HandleGrab
   %endif

    mov edi,[ebx+GuiObj.Container]  ;get container to find size
    mov eax,[ebx+TitleBarObj.Flags]
    movzx edx,word [edi+GuiObj.Size+2]
    sub edx,[esp+12]                ;width-mouse col
   %ifdef UseSmallScreen
    sub edx,byte 3
    js .HandleGrab
    shr edx,3                       ;/8
   %else
    sub edx,byte 6
    js .HandleGrab
    shr edx,4                       ;/16
   %endif

    test eax,TitleBarObj.CloseButton
    jz .NotClose
    dec edx
    js .Close
.NotClose:
    test eax,TitleBarObj.HelpButton
    jz .NotHelp
    dec edx
    js .Help
.NotHelp:
    test eax,TitleBarObj.MinButton
    jz .NotMinimize
    dec edx
    js .Minimize
.NotMinimize:
    ; fall through if no buttons were clicked
  %endif

.HandleGrab:
  %ifdef WinVer
    xor eax,eax
    api SystemParametersInfo, SPI_GETWORKAREA, eax,.EdgeRect, eax
    api GetWindowRect, [hwnd],rect
    mov edx,[rect+RECT.bottom]
    mov ecx,[rect+RECT.right]
    sub edx,[rect+RECT.top]         ;get height
    sub ecx,[rect+RECT.left]        ;get width
    sub [.EdgeRect+RECT.bottom],edx ;set bottom edge
    sub [.EdgeRect+RECT.right],ecx  ;set right edge
    call CommonItemCode.CaptureMouse
    mov edx,[Cursor.Row]
    mov ecx,[Cursor.Col]
    mov [CommonItemCode.CursorRow],edx
    mov [CommonItemCode.CursorCol],ecx
    mov esi,GuiCursor.Move
    jmp SetCursorImage
    ;clc
    ;ret
  %else
    stc
    ret
  %endif

;컴컴컴컴컴컴컴컴컴컴
.MouseMove:
    ;if cursor locked
    ;  move entire window by cursor change
    ;endif

    cmp [CommonItemCode.MouseObject],ebx
    jne .IgnoreMove

  %ifdef WinVer
    mov eax,[msg+MSG.y]
    mov esi,[.EdgeRect+RECT.top]
    sub eax,[CommonItemCode.CursorRow] ;mouse row difference
    call .AlignEdge
    mov esi,[.EdgeRect+RECT.bottom]
    call .AlignEdge
    mov edx,eax

    mov eax,[msg+MSG.x]
    mov esi,[.EdgeRect+RECT.left]
    sub eax,[CommonItemCode.CursorCol]
    call .AlignEdge
    mov esi,[.EdgeRect+RECT.right]
    call .AlignEdge
    mov ecx,eax

    xor eax,eax
    api SetWindowPos, [hwnd],eax, ecx,edx, eax,eax, SWP_NOACTIVATE|SWP_NOSIZE|SWP_NOZORDER|SWP_NOSENDCHANGING
  %endif
.IgnoreMove:
    clc
    ret

%ifdef WinVer
; Aligns a window to the neaest edge if close enough, to make the window seem
; to 'stick' to the edges.
; (eax=row/column, esi=nearest row/column)
; (eax=aligned row/column)
.AlignEdge:
    mov edi,eax
    sub edi,esi
    cmp edi,-16
    jle .NoAlign
    cmp edi,16
    jge .NoAlign
    mov eax,esi
.NoAlign:
    ret
%endif

%endif


%ifdef UseTitleBarCode
%include "ucetitle.asm"
%endif


%ifdef UseTextPromptCode
%include "ucetextedit.asm"
%endif


%ifdef UseLabelCode
%include "ucelabel.asm"
%endif


%ifdef UseImageCode
%include "uceimage.asm"
%endif


%ifdef UseBorderCode
%include "uceborder.asm"
%endif

%ifdef UseButtonCode
%include "ucebutton.asm"
%endif


%ifdef UseScrollHandleCode
%include "ucescroll.asm"
%endif

%ifdef UseAtrListCode
%include "uceatrlist.asm"
%endif


%ifdef UseTabStripCode
%include "ucetabstrip.asm"
%endif


%ifdef UseListCode
%include "ucelist.asm"
%endif


%ifdef UseMenuCode
%include "ucemenu.asm"
%endif


%ifdef UseHelpBubbleCode
%include "ucebubble.asm"
%endif

%ifdef UseProgressBarCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
ProgressBarCode:
;
%endif
