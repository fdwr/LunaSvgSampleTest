;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Object code
; Routines for all the common GUI items (buttons, lists, prompts), including
; message handlers and miscellaneous functions. Requires Gui Definitions and
; Gui core code.
;
; None of these routines are necessary. This entire file could be left out
; and the source could still compile without errors, but you would be missing
; the main point of object oriented GUIs, the objects!
;
; Since a program may not use all of these item types, in an effort to reduce
; executable bloat, only the routines defined as 'used' are included in the
; compile. For example, if a program never uses the attribute list, just
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
; Message handler parameters:
; Although the specific parameters vary according to the message being sent,
; ALL messages include the item's data structure (as a dword on the stack and
; in ebx) and of course the message with optional flags (in eax).
;
; Acknowledging messages:
; It is important that all handlers set carry for any messages which are
; ignored or not recognized so that the container's default action will be
; taken, otherwise the item could affect expected behaviour. In the case of
; keypresses, if the item didn't return that it ignored the Tab key, the
; container would think that item used it (like a text prompt) and normal
; operation of pressing Tab (moving focus to the next group) wouldn't occur.
;
; Message Order:
; Input messages always go through the container the first, then its items.
; Some messages are checked by the container before passing them onto the
; proper items. Other messages are checked afterwards, only if the item
; ignored them. It is okay for an item to trash the message before returning
; to its container, since the container should have saved the message if was
; going to do anything with it afterwards.
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
%endif


%ifdef UseTextPromptCode
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

%endif


%ifdef UseLabelCode
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
%endif


%ifdef UseImageCode
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
%endif


%ifdef UseBorderCode
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
%endif


%ifdef UseScrollHandleCode
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
    incbin "..\gui\buttonxp.lbm"
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

%endif

%ifdef UseAtrListCode
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
%endif


%ifdef UseTabStripCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
TabStripCode:

section data
    StartMsgJtbl
    ;AddMsgJtbl Msg.Created,.Created
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    AddMsgJtbl Msg.MouseMove,.MouseMove
    AddMsgJtbl Msg.MouseIn,.MouseIn
    AddMsgJtbl Msg.MouseOut,.MouseOut
.DrawRow    equ CommonItemCode.DrawRow
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.Draw:
    ; if visible (not hidden)
    ;   get tab height/width
    ;   if full redraw || (redraw name & partial redraw)
    ;     clear redraw flag
    ;     if text
    ;       write text value
    ;     else
    ;       draw picture
    ;     endif
    ;   endif
    ;   row += tab height/width
    ; endif

    push ebp
    mov ebp,esp

    movzx ecx,byte [ebx+TabStripObj.TotalItems]
    mov dword [.DrawRow],-2<<16
    push dword [ebx+GuiObj.Flags] ;push flags for redraw checking
    mov esi,ebx
    push ecx
    jmp .FirstTabV
.Flags      equ -4
.TabCount   equ -8

.DrawNextTabV:
    test byte [esi+TabStripObj.Flags],TabStripObj.Hidden
    jnz near .HiddenTabV

    movzx ecx,byte [esi+TabStripObj.Height]

    btr dword [esi+TabStripObj.Flags],TabStripObj.Redrawb
    jc .RedrawTabV
    test dword [esp+4],GuiObj.RedrawBg|GuiObj.RedrawForced
    jz near .NoRedrawTabV
.RedrawTabV:

    push esi                    ;save tab info ptr
    push ecx                    ;save tab height
.TabPtr     equ -12
.TabHeight  equ -16

    test byte [esi+TabStripObj.Flags],TabStripObj.Separator
    jz .NotSeparatorV
    add dword [.DrawRow],byte 2 ;row += separation pixels
.NotSeparatorV:

    or ecx,(FontDefHeight+4)<<16;tab height | font height
    ;push dword GuiClrFace      ;tab bg color
    push dword DrawBorder.Convex|DrawBorder.Filled
    push dword ecx
    push dword [.DrawRow]
    ;call DrawRect
    call DrawBorder
    ;add esp,byte 12

    ;test byte [esi+TabStripObj.Flags],TabStripObj.IsPicture
    ;jnz .DrawPicture

    ; determine pixel length of text
    mov esi,[ebp+.TabPtr]
    mov eax,GuiClrTxtNormal
    test byte [esi+TabStripObj.Flags],TabStripObj.Marked
    jz .DrawUnmarkedV
    mov eax,GuiClrTxtActive
.DrawUnmarkedV:
    push dword [esi+TabStripObj.TextLen]
    mov [Font.Colors],eax
    push dword [esi+TabStripObj.TextPtr]
    call GetTextLenWidth
    ;add esp,byte 8

    ; draw name
    ;push dword [esi+TabStripObj.TextLen]
    ;push dword [esi+TabStripObj.TextPtr]
    neg eax
    add eax,[ebp+.TabHeight]    ;tab height - name height
    shr eax,1
    add eax,[.DrawRow]
  %ifdef UseSmallScreen
    push word 0                 ;left column
  %else
    push word -1                ;left column
  %endif
    push ax                     ;top row
    call BlitStringV
    ;add esp,byte 12

    add esp,byte 4+8+12;+16
    pop ecx
    pop esi
.NoRedrawTabV:
    add [.DrawRow],ecx          ;row += tab height

.HiddenTabV:
    add esi,byte TabStripObj.ItemsSizeOf
.FirstTabV:
    dec byte [esp]              ;one less tab in strip
    jge near .DrawNextTabV

    add esp,byte 8
    ;clc (add clears cf)
    mov esp,ebp
    pop ebp
    ret

;컴컴컴컴컴컴컴컴컴컴
.MouseOut:
    mov ecx,-1
    mov [ebx+TabStripObj.Hovered],cl
    jmp short .MmOwnerMsg

;컴컴컴컴컴컴컴컴컴컴
.MouseIn:
    call SetCursorImage.Default
    mov edx,[esp+8]             ;mouse row
    call .GetHoveredTab
    test ecx,ecx
    jns .MmOwnerMsg
    ;clc (test clears cf)
    ret

;컴컴컴컴컴컴컴컴컴컴
.MouseMove:
    mov edx,[esp+8]             ;mouse row
    call .GetHoveredTab
    je .MmRet
.MmOwnerMsg: ;(ecx=hovered tab)
    mov eax,TabStripMsg.Hover
    call SendOwnerMsg
    clc
.MmRet: ;(cf=0)
    ret

;컴컴컴컴컴컴컴컴컴컴
.MousePrsRls:
    test dword [Mouse.Buttons],Mouse.LeftPress
    jz .MouseNoPress
    mov [ebx+TabStripObj.Selected],cl
    mov edx,[esp+8]             ;mouse row
    call .GetHoveredTab
    mov eax,TabStripMsg.Activate
    DebugOwnerMsg "tabstrip activate"
    call SendOwnerMsg.Important
    clc
.MouseNoPress: ;(cf=0)
    ret

;컴컴컴컴컴컴컴컴컴컴
; Determines which tab the cursor is over. Returns -1 if none.
; (edx=pixel coordinate either row or column)
; (ecx=tab index, zf=if same; ebx)
.GetHoveredTab:
    xor ecx,ecx
    mov esi,ebx
    xor eax,eax

.GhtNext:
    test byte [esi+TabStripObj.Flags],TabStripObj.Hidden
    jnz .GhtHidden
    mov al,[esi+TabStripObj.Height]
    test byte [esi+TabStripObj.Flags],TabStripObj.Separator
    jz .GhtNotSeparator
    add al,byte 2               ;row += separation pixels
.GhtNotSeparator:
    sub edx,eax
    jb .GhtFound
.GhtHidden:
    inc ecx
    add esi,byte TabStripObj.ItemsSizeOf
    cmp cl,[ebx+TabStripObj.TotalItems]
    jb .GhtNext

.GhtFound:
    test byte [esi+TabStripObj.Flags],TabStripObj.Disabled
    jz .GhtRet
    mov ecx,-1
.GhtRet:
    cmp [ebx+TabStripObj.Hovered],cl
    mov [ebx+TabStripObj.Hovered],cl
    ret
%endif


%ifdef UseAtrBarCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
AtrBarCode:

section data
    StartMsgJtbl
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    AddMsgJtbl Msg.MouseMove,.MouseMove
    AddMsgJtbl Msg.MouseIn,.MouseIn
.DrawCol    equ CommonItemCode.DrawCol
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.Draw:
    ; if visible (not hidden)
    ;   get tab height
    ;   if full redraw || (redraw name & partial redraw)
    ;     clear redraw flag
    ;     if text
    ;       write text value
    ;     else
    ;       draw picture
    ;     endif
    ;   endif
    ;   row += tab height
    ; endif

    push ebp
    mov ebp,esp

    movzx ecx,byte [ebx+TabStripObj.TotalItems]
    movzx edx,byte [ebx+TabStripObj.Selected]
    mov dword [.DrawCol],0
    push dword [ebx+GuiObj.Flags] ;push flags for redraw checking
    mov esi,ebx
    push ecx
    jmp .FirstTab
.Flags      equ -4
.TabCount   equ -8

.DrawNextTab:
    test byte [esi+TabStripObj.Flags],TabStripObj.Hidden
    jnz near .HiddenTab

    movzx ecx,byte [esi+TabStripObj.Width]

    btr dword [esi+TabStripObj.Flags],TabStripObj.Redrawb
    jc .RedrawTab
    test dword [esp+4],GuiObj.RedrawBg|GuiObj.RedrawForced
    jz .NoRedrawTab
.RedrawTab:

    shl ecx,16                  ;move width into upper 16bits
    push esi                    ;save tab info ptr
    push ecx                    ;save tab height
    push edx
.TabPtr         equ -12
.TabWidth       equ -16
.TabIndex       equ -19
.TabSelected    equ -20

    test byte [esi+TabStripObj.Flags],TabStripObj.Separator
    jz .NotSeparator
    add dword [.DrawCol+2],byte 4 ;col += separation pixels
.NotSeparator:

    push dword GuiClrFace
    mov cl,FontDefHeight        ;set height
    push dword ecx              ;tab width | font height
    push dword [.DrawCol]
    call DrawRect
    ;add esp,byte 12

    ;test byte [esi+TabStripObj.Flags],TabStripObj.IsPicture
    ;jnz .DrawPicture

    ; determine pixel length of text & set color
    mov esi,[ebp+.TabPtr]
    mov eax,GuiClrTxtNormal
    mov dl,[ebp+.TabIndex]
    cmp dl,[ebp+.TabSelected]
    jne .DrawUnmarkedV
    mov eax,GuiClrTxtActive
.DrawUnmarkedV:
    push dword [esi+TabStripObj.TextLen]
    mov [Font.Colors],eax
    push dword [esi+TabStripObj.TextPtr]
    call GetTextLenWidth
    ;add esp,byte 8

    ; draw name
    ;push dword [esi+TabStripObj.TextLen]
    ;push dword [esi+TabStripObj.TextPtr]
    neg eax
    add ax,[ebp+.TabWidth+2]    ;tab width - name width
    sar ax,1
    add ax,[.DrawCol+2]
    push ax                     ;left column
    push word 0                 ;top row
    call BlitString
    ;add esp,byte 12

    add esp,byte 12+12
    pop edx
    pop ecx
    pop esi
.NoRedrawTab:
    add [.DrawCol],ecx          ;row += tab width

.HiddenTab:
    add esi,byte TabStripObj.ItemsSizeOf
    inc dh                      ;next tab index
.FirstTab:
    dec byte [esp]              ;one less tab in strip
    jge near .DrawNextTab

    add esp,byte 8
    ;clc (add clears cf)
    mov esp,ebp
    pop ebp
    ret

;컴컴컴컴컴컴컴컴컴컴
.MouseIn:
    mov edx,[esp+8]             ;mouse row
    call .GetHoveredTab
    test ecx,ecx
    jns .MmOwnerMsg
    ;clc (test clears cf)
    ret

;컴컴컴컴컴컴컴컴컴컴
.MouseMove:
    mov edx,[esp+8]             ;mouse row
    call .GetHoveredTab
    je .MmRet
.MmOwnerMsg:
    mov eax,TabStripMsg.Hover
    DebugOwnerMsg "atrbar hover"
    call SendOwnerMsg
    clc
.MmRet: ;(cf=0)
    ret

;컴컴컴컴컴컴컴컴컴컴
.MousePrsRls:
    test dword [Mouse.Buttons],Mouse.LeftPress
    jz .MouseNoPress
    mov [ebx+TabStripObj.Selected],cl
    mov edx,[esp+8]             ;mouse row
    call .GetHoveredTab
    mov eax,TabStripMsg.Activate
    DebugOwnerMsg "atrbar activate"
    call SendOwnerMsg.Important
    clc
.MouseNoPress: ;(cf=0)
    ret

%ifdef UseTabStripCode
    .GetHoveredTab equ TabStripCode.GetHoveredTab
%else
;컴컴컴컴컴컴컴컴컴컴
; (edx=pixel coordinate) (ecx=tab index, zf=if same; ebx)
; Determines which tab the cursor is over. Returns -1 if none.
.GetHoveredTab:
    xor ecx,ecx
    mov esi,ebx
    xor eax,eax

.GhtNext:
    test byte [esi+TabStripObj.Flags],TabStripObj.Hidden
    jnz .GhtHidden
    mov al,[esi+TabStripObj.Width]
    test byte [esi+TabStripObj.Flags],TabStripObj.Separator
    jz .GhtNotSeparator
    add al,byte 4               ;row += separation pixels
.GhtNotSeparator:
    sub edx,eax
    jb .GhtFound
.GhtHidden:
    inc ecx
    add esi,byte TabStripObj.ItemsSizeOf
    cmp cl,[ebx+TabStripObj.TotalItems]
    jb .GhtNext

.GhtFound:
    test byte [esi+TabStripObj.Flags],TabStripObj.Disabled
    jnz .GhtRet
    mov ecx,-1
.GhtRet:
    cmp [ebx+TabStripObj.Hovered],cl
    mov [ebx+TabStripObj.Hovered],cl
    ret

%endif

%endif


%ifdef UseListCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
ListCode:

section data
    StartMsgJtbl
    ;AddMsgJtbl Msg.Created,.UpdateScrollHandle
    ;AddMsgJtbl Msg.Redraw,.Draw
    ;AddMsgJtbl Msg.Focus,.ItemFocus
    ;AddMsgJtbl Msg.KeyPress,.KeyPress
    ;AddMsgJtbl Msg.MousePrsRls,.MousePrsRls
    ;AddMsgJtbl Msg.MouseMove,.MouseMove
    AddMsgJtbl Msg.MouseIn,.MouseIn
    ;AddMsgJtbl Msg.MouseOut,.MouseOut

.KeysJtbl:
    ;dd .KeyUp
    ;dd .KeyDown
    ;dd .KeyLeft
    ;dd .KeyRight
    ;dd .KeyHomeRow
    ;dd .KeyEndRow
    ;dd .KeyHomeCol
    ;dd .KeyEndCol
    ;dd .KeyBkSpc

.Keys:
    db 0,VK_UP
    db 0,VK_DOWN
    db 0,VK_LEFT
    db 0,VK_RIGHT
    db 2,VK_HOME,   1,VK_CONTROL
    db 2,VK_END,    1,VK_CONTROL
    db 0,VK_HOME
    db 0,VK_END
    db 0,VK_BACK
    db -1

.DrawRow    equ CommonItemCode.DrawRowW
.DrawCol    equ CommonItemCode.DrawColW
.SelRow     equ CommonItemCode.SelRow
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
.MouseIn:
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.ByMouse
    call SendContainerMsg
    jmp SetCursorImage.Default
    ;clc
    ;ret
%endif


%ifdef UseMenuCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; The menu code is somewhat different from other objects in that there is no
; independant "menu object", which explains the lack of a message jump table
; in the data section. It is simply generic code that can be called by other
; objects such as the floating menu and embedded menus.
MenuCode:

section data
align 4, db 0
.KeysJtbl:
    dd .KeyCtrlUp
    dd .KeyCtrlDown
    dd .KeyUp
    dd .KeyDown
    dd .KeyBkSpc    ;ctrl+left
    dd .KeyLeft
    dd .KeyRight
    dd .KeyHome
    dd .KeyEnd
    dd .KeyBkSpc
    dd .KeyEnter
    dd .KeyEscape

.Keys:
    db 2,VK_UP,     0,VK_CONTROL
    db 2,VK_DOWN,   0,VK_CONTROL
    db 0,VK_UP
    db 0,VK_DOWN
    db 2,VK_LEFT,   0,VK_CONTROL
    db 0,VK_LEFT
    db 0,VK_RIGHT
    db 4,VK_HOME
    db 4,VK_END
    db 4,VK_BACK
    db 4,VK_ENTER
    db 4,VK_ESCAPE
    db -1

.ColorMapDim:   dw GuiClrBlack,GuiClrBlack,GuiClrDGray,GuiClrGray,GuiClrLGray,GuiClrBGray,GuiClrDGray,GuiClrLGray,GuiClrDGray,GuiClrLGray,GuiClrDGray,GuiClrLGray,GuiClrDGray,GuiClrLGray,GuiClrDGray,GuiClrLGray,GuiClrFace
.ColorMapNormal:dw GuiClrBlack,GuiClrDGray,GuiClrGray,GuiClrLGray,GuiClrBGray,GuiClrWhite,GuiClrPurple,GuiClrLPurple,GuiClrBlue,GuiClrLBlue,GuiClrGreen,GuiClrLGreen,GuiClrYellow,GuiClrLYellow,GuiClrRed,GuiClrLRed,GuiClrFace

align 4,        db 0
.LastChoice:    dd 0            ;keep track of last activate choice
.ChangeCount:   dd 1
.MouseCurMenu:  dd 0
.MousePrevMenu: dd 0
.MouseTop:      dd 0
.MouseLeft:     dd 0
.MouseBtm:      dd 0
.MouseRight:    dd 0
.MouseRow:      dd 0            ;last row clicked
.MouseCol:      dd 0

.DrawPos    equ CommonItemCode.DrawPos
.DrawRow    equ CommonItemCode.DrawRowW
.DrawCol    equ CommonItemCode.DrawColW
.DrawSize   equ CommonItemCode.DrawSize
.DrawWidth  equ CommonItemCode.DrawWidth
.SelRow     equ CommonItemCode.SelRow
.GuiFlags   equ CommonItemCode.GuiFlags
.ColorMap:  equ CommonItemCode.ColorMap

%ifdef UseSmallScreen
.SepSize    equ 4               ;separator bars are x pixels high
.EdgeSize   equ 3               ;menu edges are x pixels around
%else
.SepSize    equ 8               ;separator bars are x pixels high
.EdgeSize   equ 6               ;menu edges are x pixels around
%endif

section code

;컴컴컴컴컴컴컴컴컴컴
; Draws all choices in the entire menu heirarchy.
; (ebx=menu item ptr)
.DrawAllChoices:
    mov eax,[ebx+GuiObj.Flags]
    mov edi,[ebx+MenuObj.MenuList]
    mov [.GuiFlags],eax
    push ebx
    push dword [ebx+MenuObj.Selected]
    mov ebx,.EdgeSize|(.EdgeSize<<16)  ;set initial top/left
    jmp short .DacFirst
.DacNext:
    mov cl,-1
    cmp [esp],edi
    jne .DacUnselected
    test dword [.GuiFlags],GuiObj.NotFullFocus
    jnz .DacUnselected
    mov cl,[edi+MenuListObj.Selected]
.DacUnselected:
    mov [.SelRow],cl
    call .DrawChoices
    add ebx,[edi+MenuListObj.ChildPos]
    mov edi,[edi+MenuListObj.Child]
.DacFirst:
    test edi,edi
    jnz .DacNext
    pop edi                     ;discard selected MenuList ptr
    pop ebx                     ;restore menu ptr
    ;clc
    ret

;컴컴컴컴컴컴컴컴컴컴
; Draws the choices in a MenuList, including the text, pictures, and
; separator bars, but none of the menu background. Draws only the single
; MenuList passed to it, not the entire menu heirarchy. For that, the routine
; must be called once for each child.
;
; set initial row & col to menu's top/left
; do until last choice
;   if visible (not hidden)
;     get height
;     if choice needs redrawing (either individually or all)
;       if disabled
;         set text color dim
;         set picture colormap dim
;       else
;         set picture colormap normal
;         if choice selected
;           set text color bright
;         else
;           set text color normal
;         endif
;       endif
;       if menu separator
;         draw separator
;         advance row += 4
;       endif
;       if picture != null
;         if picture height > text height, choice height = picture height
;         advance col += picture width+2
;         draw picture
;       endif
;       if text != null
;         draw text string
;       endif
;     endif
;     if choice has open MenuList
;       advance row += MenuList height
;     endif
;   endif
; loop
; (edi=MenuList ptr, ebx=top/left)
; (; ebx,edi)

.DrawChoices:
.DcTotalItems   equ -4          ;total choices in menu (0-255)
.DcSelected     equ -3          ;selected choice (0-254)
.DcOpened       equ -2          ;opened choice (if opened)
.DcPos          equ 4
.DcTop          equ 4
.DcLeft         equ 6
.DcMenuList     equ 8

    cmp byte [edi+MenuListObj.TotalItems],0
    je near .DcEnd

    push edi                    ;save MenuList ptr
    push ebx                    ;save position
    push ebp
    mov ebp,esp

    or dword [edi+MenuListObj.Flags],MenuListObj.Redrawn
    mov edx,[edi+MenuListObj.Size] ;get height/width
    xor ecx,ecx                 ;zero initial choice counter
    add edx,20000h              ;width+=2
    push dword [edi+MenuListObj.TotalItems]
    mov [.DrawSize],edx

.DcNext:
    mov eax,[edi+MenuListObj.Flags]
    test eax,MenuListObj.Hidden
    jnz near .DcHidden
    call .GetChoiceHeight

    ;btr dword [edi+MenuListObj.Flags],MenuListObj.Redrawb
    ;jc .DcRedraw
    test dword [edi+MenuListObj.Flags],MenuListObj.Redraw
    jnz .DcRedraw
    test dword [.GuiFlags],GuiObj.RedrawBg|GuiObj.RedrawForced
    jz near .DcNoRedraw
.DcRedraw:

.DcChoicePtr    equ -8
.DcCounter      equ -12
.DcChoicePos    equ -16
.DcChoiceWidth  equ -18
.DcChoiceHeight equ -20
    push edi                    ;save menu choice ptr
    push ecx                    ;save choice counter
    push ebx                    ;top/left
    push edx                    ;choice height/width
    mov [.DrawPos],ebx

    ; set picture/text colors
    test eax,MenuListObj.Disabled
    jz .DcEnabled
    mov ebx,GuiClrTxtDim
    mov edx,.ColorMapDim
    jmp short .DcSetColors
.DcEnabled:
    mov ebx,GuiClrTxtNormal
    mov edx,.ColorMapNormal
    cmp [.SelRow],cl
    jne .DcSetColors
    mov ebx,GuiClrTxtBright
.DcSetColors:
    mov [.ColorMap],edx
    mov [Font.Colors],ebx

    ; draw separator if exists
    test eax,MenuListObj.Separator
    jz .DcNoSeparator
    push word GuiClrRight       ;color
    push word [.DrawWidth]      ;width
    push dword [.DrawPos]       ;row/col
    sub dword [esp],1<<16       ;col--
    call DrawHline
    mov word [esp+6],GuiClrLeft ;color
    inc word [esp]              ;row++
    call DrawHline
    mov edi,[ebp+.DcChoicePtr]
    add esp,byte 8
    add word [.DrawRow],byte .SepSize
.DcNoSeparator:

    ; draw image - if choice has one
    mov esi,[edi+MenuListObj.ImagePtr]
    test esi,esi
    jz .DcNoImage
    push dword [.ColorMap]      ;pixel index to color map
    push esi                    ;image ptr
    push dword [esi+ImageStruct.Size] ;height & width
    push dword [.DrawPos]       ;left column/top row
    call DrawImageTrans ;Mapped***
    mov edi,[ebp+.DcChoicePtr]  ;get menu choice ptr
    add esp,byte 16
    mov dx,[ebp+.DcChoiceWidth]
  %ifdef UseSmallScreen
    add dx,byte 2               ;pixels separation between image and text
  %else
    add dx,byte 4               ;pixels separation between image and text
  %endif
    add [.DrawCol],dx           ;col += image width
.DcNoImage:

    ; draw text - unless choice is picture only
    mov esi,[edi+MenuListObj.TextPtr]
    test esi,esi
    jz .DcNoText
    call GetStringLength
    push ecx                    ;number of characters
    ;push dword [edi+MenuListObj.TextLen] ;number of characters
    push dword esi              ;text ptr
    push dword [.DrawPos]       ;left column/top row
    call BlitString
    add esp,byte 12
.DcNoText:

    pop edx                     ;get menu choice height
    pop ebx                     ;top/left
    pop ecx                     ;restore choice counter
    pop edi                     ;restore menu choice ptr

.DcNoRedraw:
    ; add choice height to row
    ; if current choice has open MenuList
    ;   add child's menu height to draw row
    ; endif
    add bx,dx                   ;row += choice height
    cmp [ebp+.DcOpened],cl
    jne .DcClosed
    mov esi,[ebp+.DcMenuList]
    mov esi,[esi+MenuListObj.Child]
    add bx,[esi+MenuListObj.Height]
.DcClosed:

.DcHidden:
    inc ecx
    add edi,byte MenuListObj.ItemsSizeOf
    cmp [ebp+.DcTotalItems],cl
    ja near .DcNext

    ;pop eax                     ;discard counter
    mov esp,ebp
    pop ebp
    pop ebx                     ;restore position
    pop edi                     ;restore MenuList ptr
.DcEnd:
    ret

;컴컴컴컴컴컴컴컴컴컴
; Clears all the redraw flags of choices in a menu heirarchy, so that in case
; more than one menu object is sharing the same MenuList, previously redrawn
; choices are not forever redrawn.
; ()
; (; ebx,edx,edi,esi)
.ClearRedrawFlags:
    push edi
    mov edi,[ebx+MenuObj.MenuList]
    jmp short .CrfFirstMenu
.CrfNextMenu:
    test dword [edi+MenuListObj.Flags],MenuListObj.Redrawn
    jz .CrfLastChoice
    mov eax,edi
    movzx ecx,byte [edi+MenuListObj.TotalItems]
    jmp short .CrfFirstChoice
.CrfNextChoice:
    and dword [eax+MenuListObj.Flags],~(MenuListObj.Redraw|MenuListObj.Redrawn)
    add eax,byte MenuListObj.ItemsSizeOf
.CrfFirstChoice:
    dec ecx
    jge .CrfNextChoice
.CrfLastChoice:
    mov edi,[edi+MenuListObj.Child]
.CrfFirstMenu:
    test edi,edi
    jnz .CrfNextMenu
    pop edi
    ret

;컴컴컴컴컴컴컴컴컴컴
; Determines a choice's height based on its image and flags. If the image is
; taller than the standard font size, then the choice's height is that of the
; image. If smaller, the choice's height is the standard font size.
;
; (eax=choice flags, edi=MenuList choice ptr) (edx=height|width; eax,edi,ebx)
.GetChoiceHeight:
    ; compare image size to minimum height
    mov esi,[edi+MenuListObj.ImagePtr]
    mov edx,FontDefHeight|0<<16 ;choice size if no picture
    test esi,esi
    jz .GchNoImage
    mov edx,[esi+ImageStruct.Size] ;get height & width
    cmp dx,FontDefHeight
    jae .GchImageLarge
    mov dx,FontDefHeight        ;choice height always at least 8 pixels
.GchImageLarge:
.GchNoImage:

    test eax,MenuListObj.Separator
    jz .GchNoSeparator
    add dx,byte .SepSize        ;height += separator size
.GchNoSeparator:
    ret


;컴컴컴컴컴컴컴컴컴컴
; Resizes and repositions each open MenuList in the choice chain. Called after
; a MenuList is closed/opened or any other significant change that causes the
; menu to change size. The menu's size is always dependant on the cumalative
; size of all the choices in it, so if any of the choices are changed, that
; requires the menu height/width to be recalculated.
;
; Recursively calls Resize to figure out the dimensions.
.Rechain:
    mov edi,[ebx+MenuObj.MenuList] ;pass param MenuList ptr
    test edi,edi
    jz .EndChain
    push ebx                    ;save item ptr
    call .RecurseFirst
    pop ebx

    call .ResetMouseArea        ;may be unnecessary, but just in case

    mov eax,GuiObj.RedrawBg
    jmp SendContainerRedraw
.EndChain: ;(cf=0)
    ;clc
    ret

.Recurse:
    mov edi,[edi+MenuListObj.Child]
    test edi,edi
    jz .EndChain
.RecurseFirst:
    push edi
    call .Recurse
    pop edi
    ;jmp short .Resize

;컴컴컴컴컴컴컴컴컴컴
; Determines a MenuList's height/width from the size of the choices in it, and
; whether it has any open children It only calculates the size of the passed
; MenuList, not entire the chain. For that, the routine must be called once
; for each child.
;
; Since the parent's size is dependant on the accumulated children's size,
; the caller should start at the end of chain and move up.
;
; zero initial menu height
; do until last choice
;   if visible (not hidden)
;     if menu separator, MenuList height += separator size
;     choice height = 8
;     choice width = 8
;     if picture != null
;       if picture height > text height, choice height = picture height
;       choice width += picture width+2
;     endif
;     if text != null
;       choice width += string width
;     endif
;     MenuList height += choice height
;     if choice width > MenuList width, MenuList width = choice width
;     if choice has open MenuList, MenuList height += child MenuList height
;   endif
; loop
;
; (edi=MenuList ptr)
; (; edi=MenuList ptr)
.Resize:

.RsTotalItems   equ 0           ;total choices in menu (0-255)
.RsSelected     equ 1           ;selected choice (0-254)
.RsOpened       equ 2           ;opened choice (if opened)
.RsMenuList     equ 4

    mov dl,[.ChangeCount]
    cmp [edi+MenuListObj.ChangeCount],dl
    je near .RsRet
    mov [edi+MenuListObj.ChangeCount],dl

    xor ecx,ecx                 ;zero initial choice counter
    push edi                    ;save MenuList ptr
    xor ebx,ebx                 ;zero initial height/width
    push dword [edi+MenuListObj.TotalItems] ;for counter comparison
    jmp .RsFirst

.RsNext:
    mov eax,[edi+MenuListObj.Flags]
    test eax,MenuListObj.Hidden
    jnz near .RsHidden

    ; count separator if exists
    test eax,MenuListObj.Separator
    jz .RsNoSeparator
    add bx,byte .SepSize        ;menu height+=separator size
.RsNoSeparator:

    ; image - if choice has one
    mov edx,FontDefHeight       ;default choice height/width
    mov esi,[edi+MenuListObj.ImagePtr]
    test esi,esi
    jz .RsNoImage
    mov edx,[esi+ImageStruct.Size] ;height & width
    cmp dx,FontDefHeight
    jae .RsImageLarge
    mov dx,FontDefHeight
.RsImageLarge:
  %ifdef UseSmallScreen
    add edx,2<<16               ;pixel separation between image and text
  %else
    add edx,4<<16               ;pixel separation between image and text
  %endif
.RsNoImage:

    ; text - unless choice is picture only
    mov esi,[edi+MenuListObj.TextPtr]
    test esi,esi
    jz .RsNoText

    push edi                    ;save menu choice ptr
    push ebx                    ;save menu height/width
    push ecx                    ;save choice counter
    push edx                    ;save choice height/width

    call GetStringLength
    push ecx                    ;number of characters
    push dword esi              ;text ptr
    call GetTextLenWidth
    dec eax                     ;pixel width--

    add esp,byte 8
    shl eax,16                  ;shift width to upper word
    pop edx                     ;restore choice height/width
    pop ecx                     ;restore choice counter
    pop ebx                     ;restore menu height/width
    add edx,eax                 ;choice width += text width
    pop edi                     ;restore menu choice ptr
.RsNoText:

    ; if choice is wider than menu so far, widen menu to fit choice
    cmp edx,ebx
    jb .RsChoiceSmall
    and ebx,0FFFFh
    jmp short .RsAddMenuSize
.RsChoiceSmall:
    and edx,0FFFFh
.RsAddMenuSize:
    add ebx,edx

    ; if current choice has open MenuList
    ;   add child's menu height to parent
    ; endif
    cmp [esp+.RsOpened],cl
    jne .RsClosed
    mov esi,[esp+.RsMenuList]
    mov [esi+MenuListObj.ChildTop],bx ;set top
    mov esi,[esi+MenuListObj.Child]
    test esi,esi
    jz .RsClosed
    add bx,[esi+MenuListObj.Height] ;MenuList height += child menu's height
.RsClosed:

.RsHidden:
    add edi,byte MenuListObj.ItemsSizeOf
    inc ecx
.RsFirst:
    cmp [esp+.RsTotalItems],cl
    ja near .RsNext

    ; (ebx=height/width)
    pop eax                     ;discard counter
    pop edi                     ;restore MenuList ptr
    mov [edi+MenuListObj.Size],ebx

.RsRet:
    ret

;컴컴컴컴컴컴컴컴컴컴
; Returns the size of the entire open menu chain, including outside edges.
; Used by the floating menu to know how large it should be.
; (ebx=menu item ptr)
; (edx=height, ecx=width; ebx)
.GetTotalSize:
    mov esi,[ebx+MenuObj.MenuList]
    xor eax,eax
    xor edx,edx
    push esi
    movzx ecx,word [esi+MenuListObj.Width]
    jmp short .GtsFirst

.GtsNext:
    mov ax,[esi+MenuListObj.Width]
    add eax,edx
    cmp eax,ecx
    jb .GtsLess
    mov ecx,eax
.GtsFirst:
.GtsLess:
    add dx,[esi+MenuListObj.ChildLeft]
    mov esi,[esi+MenuListObj.Child]
    test esi,esi
    jnz .GtsNext

    pop esi
    movzx edx,word [esi+MenuListObj.Height]
    add ecx,byte .EdgeSize*2
    add edx,byte .EdgeSize*2+FontDefHbody-FontDefHeight
    ret

;컴컴컴컴컴컴컴컴컴컴
; if key is cursor control
;   get selected MenuList and choice
;   do action
; endif
; if key not recognized
;   search all menu choices
;     if first letter of choice = key pressed, set cursor to
;   end search
; endif
;
.KeyPress:
    mov esi,.Keys
    call ScanForKey
    jc .KeyNoMatch
    mov edi,[ebx+MenuObj.Selected]
    mov dl,[edi+MenuListObj.Selected]
    jmp [.KeysJtbl+ecx*4]       ;jump to the right key response
.KeyNoMatch: ;(cf=1)
    ; search for menu choice with matching letter
    ;stc
    ret

.KeyChar:
    mov edi,[ebx+MenuObj.Selected]
    mov dl,[edi+MenuListObj.Selected]
    call .CalcChoiceAdr

    ; check if key is uppercase alphabetic
    cmp ah,'A'
    jb .KcNotAlpha
    cmp ah,'Z'
    ja .KcNotAlpha
    or ah,32                    ;make lowercase
.KcNotAlpha:
    mov cl,[edi+MenuListObj.TotalItems]
    mov dh,ah
    mov ch,cl
    jmp short .KcFirst

.KcNext:
    test dword [esi+MenuListObj.Flags],MenuListObj.Disabled|MenuListObj.Hidden
    jnz .KcSkip
    mov eax,[esi+MenuListObj.TextPtr]
    test eax,eax
    jz .KcSkip

    mov al,[eax]
    cmp al,'A'
    jb .KcNotAlpha2
    cmp al,'Z'
    ja .KcNotAlpha2
    or al,32                    ;make lowercase
.KcNotAlpha2:
    cmp al,dh
    je .KcMatch                 ;same as pressing Right arrow key
.KcSkip:
    inc dl
    add esi,MenuListObj.ItemsSizeOf
.KcFirst:
    cmp dl,ch
    jb .KcNoWrap
.KcNextMenu:
    xor dl,dl
    mov esi,edi
.KcNoWrap:
    dec cl
    jge .KcNext

.KcEndMenu:
    mov edi,[edi+MenuListObj.Child]
    test edi,edi
    jz .KcNoMatch
    mov cl,[edi+MenuListObj.TotalItems]
    mov ch,cl
    jmp short .KcNextMenu

.KcNoMatch:
    stc
    ret

.KcMatch:
    push edx
    push edi
    call .SetSelectedChoice
    pop edi
    pop edx
    jmp .KeyRightGiven          ;same as pressing right arrow key

.KeyEscape:
    push ebx
    debugwrite "menu canceled: escape pressed"
    mov eax,MenuMsg.Cancel
    call [ebx+GuiObj.Code]
    pop ebx
    ret

; although it isn't possible for a disabled or hidden choice to be selected
; (neither the key nor mouse selection will allow it), it is possible for the
; selected choice to become disabled by the main program. For example, the
; selected choice is "Stop", then player reaches the end of the song, and
; that choice is disabled. So it is still necessary to check the state of the
; choice before sending an activation message.
;
; if selected choice has MenuList && selected choice == open choice
;   close MenuList
; else
;   choose choice, sending owner a message
; endif
;
; (ebx=menu ptr) (cf=0)
.ActivateChoice:
    mov edi,[ebx+MenuObj.Selected]
    mov dl,[edi+MenuListObj.Selected]

.KeyEnter:  ; (edi=selected MenuList, dl=selected choice)
    call .CalcChoiceAdr
    ;test dword [esi+MenuListObj.Flags],MenuListObj.Hidden|MenuListObj.Disabled
    mov eax,[esi+MenuListObj.Flags]
    test eax,MenuListObj.Hidden|MenuListObj.Disabled
    jnz .AcDisabled

    ;mov [.LastChoice],eax       ;keep track of last activate choice
    cmp [edi+MenuListObj.Opened],dl
    je near .CloseGivenMenu

    test eax,MenuListObj.Hidden|MenuListObj.Opens
    jz .AcNotMenuList

    ;mov eax,[esi+MenuListObj.Index]
    DebugOwnerMsg "menu child activate"
    shl eax,16                  ;shift index into upper 16bits
    mov al,MenuMsg.Activate
    call SendOwnerMsg.Important
    jmp .OpenSelectedChoiceGiven
    ;clc
    ;ret

.AcNotMenuList:
    ;mov eax,[esi+MenuListObj.Index]
    DebugOwnerMsg "menu choice activate"
    shl eax,16                  ;shift index into upper 16bits
    push ebx
    mov al,MenuMsg.Activate
    call [ebx+GuiObj.Code]
    pop ebx
    clc
.AcDisabled: ;(cf=0)
    ret

.KeyRight:
; if selected choice has MenuList
;   if selected choice == open choice
;     get MenuList's child
;     set selected choice
;   else
;     choose choice
;   endif
; endif
;
; Note: A MenuList can never more than one child open. So activating another
; choice (not merely selecting) will close the currently open child MenuList
; However, not until the program actually shows the new child menu will the
; old one be closed. No opening/closing of menus actually happens here.
    call .CalcChoiceAdr
    test dword [esi+MenuListObj.Flags],MenuListObj.Opens
    jz .KsRet
.KeyRightGiven:
    cmp [edi+MenuListObj.Opened],dl
    je .KrSelectChild

    ; call owner to open child menu
    push edx
    push edi
    call .KeyEnter
    pop edi
    pop edx
    cmp [edi+MenuListObj.Opened],dl     ; if newly opened child exists,
    jne .KsRet                          ; select it

.KrSelectChild:
    call .GetMenuListChild
    mov dl,[edi+MenuListObj.Selected]
    jmp .SetSelectedChoice

.KeyLeft:  ; (edi=selected MenuList, dl=selected choice)
; close selected menu
    call .GetMenuListParent
    mov dl,[edi+MenuListObj.Selected]
    js near .SetSelectedChoiceNew
    jc .KsRet                   ;already at top of menu heirarchy
    push edi                    ;save parent MenuList ptr
    call .SetSelectedChoiceNew
    pop edi
    jmp .CloseGivenMenu

.KeyHome:   ; (edi=selected MenuList, dl=selected choice)
    mov dl,-1
    call .FindNextChoice
    jmp short .KeyHe
.KeyEnd:    ; (edi=selected MenuList, dl=selected choice)
    mov dl,-1
    call .FindPrevChoice
.KeyHe:
    jnc near .SetSelectedChoice
    clc
    ret

.KeyCtrlUp:
    call .FindPrevChoice
    jmp short .KeySeekRet
.KeyCtrlDown:
    call .FindNextChoice
.KeySeekRet:
    jnc near .SetSelectedChoicePtr
.KsRet:
    clc
    ret

.KeyUp:     ; (edi=selected MenuList, dl=selected choice)
; get selected menu
; do
;   FindPrevChoice
;   if choice found
;     if choice found <> opened choice, goto set selected choice
;     get child
;     selected choice = last
;   endif
; loop until no choice found
; get parent
; return if already at chain top
; selected choice = opened
.KuNext:
    call .FindPrevChoice
    jc .KuNoChoices
    cmp [edi+MenuListObj.Opened],dl
    jne .SetSelectedChoicePtr
    call .GetMenuListChild
    mov dl,-1                   ;no selected choice, force to start from first
    jmp short .KuNext
.KuNoChoices:
    call .GetMenuListParent
    jc .KsRet
    mov dl,[edi+MenuListObj.Opened]
    jmp short .SetSelectedChoiceNew

.KeyDown:   ; (edi=selected MenuList, dl=selected choice)
; get selected menu
; if selected choice == open choice
;   get MenuList's child
;   selected choice = first
; endif
; do
;   FindNextChoice
;   if choice found, goto set selected choice
;   get parent
;   return if already at chain top
;   selected choice = opened
; loop
    cmp [edi+MenuListObj.Opened],dl
    jne .KdNext
    call .GetMenuListChild
    mov dl,-1                   ;no selected choice, force to start from first
.KdNext:
    call .FindNextChoice
    jnc .SetSelectedChoicePtr
    call .GetMenuListParent
    jc .KsRet
    mov dl,[edi+MenuListObj.Opened]
    jmp short .KdNext

.KeyBkSpc:  ; (edi=selected MenuList, dl=selected choice)
; return if already at top of chain
; get parent menu
; selected opened choice
    call .GetMenuListParent
    mov dl,[edi+MenuListObj.Opened]
    jnc .SetSelectedChoiceNew   ;no errors, select new choice
    jns .KsRet                  ;already at top
    jmp short .SetSelectedChoiceNew ;else previously selected choice not found!

;컴컴컴컴컴컴컴컴컴컴
; Selects the given menu choice, setting the redraw flags properly. Assumes
; the parameters ARE correct. No problem. If they aren't, this routine should
; have never even been reached.
;
; (ebx=menu ptr, edi=new MenuList, edx=new choice)
; (cf=0)
.SetSelectedChoice:
    cmp [ebx+MenuObj.Selected],edi  ;compare previous MenuList
    jne .SetSelectedChoiceNew
    cmp [edi+MenuListObj.Selected],dl ;compare previous choice
    jne .SetSelectedChoiceNew
    ;clc ;(cf=0)
    ret

.SetSelectedChoiceNew:
    call .CalcChoiceAdr
.SetSelectedChoicePtr:
; (edi=new MenuList, esi=choice info ptr, edx=new choice)
    call .ClearRedrawFlags
    cmp edi,[ebx+MenuObj.Selected]
    je .SscSameMenu
    mov [edi+MenuListObj.Selected],dl ;set choice in new menu
    xchg [ebx+MenuObj.Selected],edi  ;swap old menu with new menu
    mov dl,[edi+MenuListObj.Selected] ;get choice from old menu
    jmp short .SccDifMenu
.SscSameMenu:
    xchg [edi+MenuListObj.Selected],dl
.SccDifMenu:

    ; get index of selected choice and redraw both choices
    ; (edi=old MenuList, esi=new choice ptr, dl=old choice)
    mov eax,[esi+MenuListObj.Index]
    or dword [esi+MenuListObj.Flags],MenuListObj.Redraw
    shl eax,16                      ;shift index into upper 16bits
    cmp [edi+MenuListObj.TotalItems],dl
    jbe .SccTellOwner
    call .CalcChoiceAdr
    or dword [esi+MenuListObj.Flags],MenuListObj.Redraw

.SccTellOwner:
    mov al,MenuMsg.Select
    DebugOwnerMsg "menu choice select"
    call SendOwnerMsg
    jmp SendContainerRedraw.Partial

;컴컴컴컴컴컴컴컴컴컴
.ItemFocus:
    call .ClearRedrawFlags
    call .ValidateSelection
    mov edi,[ebx+MenuObj.Selected]
    mov dl,[edi+MenuListObj.Selected]
    call .CalcChoiceAdr
    or dword [esi+MenuListObj.Flags],MenuListObj.Redraw
    jmp SendContainerRedraw.Partial
    ;clc
    ;ret

;컴컴컴컴컴컴컴컴컴컴
; validate that selected choice is still in chain
; if not, set to last choice in chain
.ValidateSelection:
    mov edi,[ebx+MenuObj.Selected]
    call MenuCode.GetMenuListParent
    jnc .VsOk
    jns .VsOk
    mov dl,[edi+MenuListObj.Selected]
    jmp MenuCode.SetSelectedChoiceNew
.VsOk:
    ret

;컴컴컴컴컴컴컴컴컴컴
; Searches through a MenuList for next selectable choice. Has no concept of
; the larger picture, simply stays within the given MenuList. Never returns
; a disabled or hidden choice. Returns error if at end of menu or no more
; enabled/visible choices were left in the menu.
;
; (edi=MenuList ptr, dl=starting choice number)
; (esi=choice info ptr, edx=choice number, cf=error; ebx,edi)
.FindNextChoice:
    movzx edx,dl
    movzx ecx,byte [edi+MenuListObj.TotalItems]
    inc edx                     ;starting choice++
    cmp edx,ecx
    jbe .FncNoWrap
    xor edx,edx                 ;no selected choice, so start from first one
.FncNoWrap:
    mov esi,edx
    shl esi,MenuListObj.ItemsSizeShl
    add esi,edi                 ;calculate menu choice offset
    jmp short .FncFirst         ;in case the menu is empty
.FncNext:
    test dword [esi+MenuListObj.Flags],MenuListObj.Hidden|MenuListObj.Disabled
    jz .FncMatch
    inc edx
    add esi,byte MenuListObj.ItemsSizeOf
.FncFirst:
    cmp edx,ecx
    jb .FncNext
    stc                         ;no next choice found
.FncMatch: ;(cf=0)
    ret

; (edi=MenuList ptr, dl=starting choice number)
; (esi=choice info ptr, edx=choice number, cf=error; ebx,edi)
.FindPrevChoice:
    movzx edx,dl
    movzx ecx,byte [edi+MenuListObj.TotalItems]
    dec edx                     ;starting choice--
    cmp edx,ecx
    jl .FpcNoWrap
    lea edx,[ecx-1]             ;no selected choice, so start from first one
.FpcNoWrap:
    mov esi,edx
    shl esi,MenuListObj.ItemsSizeShl
    add esi,edi                 ;calculate menu choice offset
    jmp short .FpcFirst         ;in case the menu is empty
.FpcNext:
    test dword [esi+MenuListObj.Flags],MenuListObj.Hidden|MenuListObj.Disabled
    jz .FpcMatch
    dec edx
    sub esi,byte MenuListObj.ItemsSizeOf
.FpcFirst:
    cmp edx,ecx
    jb .FpcNext
    stc                         ;no next choice found
.FpcMatch: ;(cf=0)
    ret

;컴컴컴컴컴컴컴컴컴컴
; Finds a MenuList's parent by searching through the chain. Returns an error
; if already at the top of the chain, or if no ptr to the passed MenuList was
; found in the chain (bad error!).
;
; (ebx=gui item ptr, edi=child MenuList ptr)
; (edi=parent MenuList ptr or last MenuList in chain if error,
;  cf=error, sf=child not found)
.GetMenuListParent:
    mov esi,[ebx+MenuObj.MenuList]
    mov eax,edi
    cmp esi,edi                 ;passed MenuList == top MenuList
    je .GspAtTop

.GspNext:
    mov edi,esi
    mov esi,[esi+MenuListObj.Child]
    test esi,esi
    jz .GspError                ;end of chain too soon!?
    cmp esi,eax
    jne .GspNext
    ;clc                        ;parent found
    ret
; reached end of chain prematurely or was already at top
.GspError: ;(esi=0)
    sub esi,byte 1              ;set sign and carry flag to indicate
    ;stc                        ;child wasn't found (DEC won't work)
    ret

.GspAtTop:
    stc
    ret

;컴컴컴컴컴컴컴컴컴컴
; The only reason why this is a routine instead of the caller just doing it
; for itself is safety, in case of a null child pointer. If somehow the
; opened variable is anything but -1, and the child is null, it sets opened
; to its proper -1.
;
; (edi=MenuList ptr) (edi=child MenuList ptr)
.GetMenuListChild:
    mov esi,[edi+MenuListObj.Child]
    test esi,esi
    jz .GscNull
    mov edi,esi
    ret
.GscNull:
    mov byte [edi+MenuListObj.Opened],-1 
    ret

;컴컴컴컴컴컴컴컴컴컴
; Simple routine for something that is done often, calculating the ptr to
; a given choice.
;
; (edi=MenuList ptr, dl=choice) (esi=choice info ptr; eax,ebx,ecx,edi)
.CalcChoiceAdr:
    movzx esi,dl
    shl esi,MenuListObj.ItemsSizeShl
    add esi,edi                 ;(choice number * byte size) + MenuList ptr
    ret

;컴컴컴컴컴컴컴컴컴컴
; if left press
;   get hovered choice
;   if valid
;     select hovered choice
;     activate choice
;   endif
; elif left release
;   if row <> last row by 3 || col <> last col by 3
;     get hovered choice
;     if choice <> last choice
;       select hovered choice
;       activate choice
;     endif
;   endif
; endif
.MousePrsRls:
    mov edx,[Cursor.Row]
    mov ecx,[Cursor.Col]

    test dword [Mouse.Buttons],Mouse.LeftPress
    jz .MprNoPress              ;ignore any other button presses

    mov [.MouseRow],edx
    mov [.MouseCol],ecx
    call .GetHoveredSubmenu
    jc .MprRet
    ;debugpause "MenuCode: left click edi=%X edx=%X",edi,edx
    call .SetSelectedChoice     ;edi and dl
    jmp .ActivateChoice

.MprNoPress:
    test dword [Mouse.Buttons],Mouse.LeftRelease|Mouse.RightRelease
    jz .MprIgnore               ;ignore any other button releases

    sub edx,[.MouseRow]
    jns .MprRowPos
    neg edx
.MprRowPos:
    cmp edx,byte 3
    jae .MprMoved

    sub ecx,[.MouseCol]
    jns .MprColPos
    neg ecx
.MprColPos:
    cmp ecx,byte 3
    jb .MprAck

.MprMoved:
    call .GetHoveredSubmenu
    jc .MprAck

    call .CalcChoiceAdr
    cmp [edi+MenuListObj.Opened],dl
    je .MprRet                  ;cf=0
    ;mov eax,[esi+MenuListObj.Index]
    ;cmp [.LastChoice],ax        ;keep track of last activate choice
    ;je .MprRet                  ;cf=0

    call .SetSelectedChoice
    jmp .ActivateChoice
.MprAck:
    clc
.MprRet:  ;(cf=0/1)
    ret

.MprIgnore:
    stc
    ret

;컴컴컴컴컴컴컴컴컴컴
.MouseIn:
    call SetCursorImage.Default
    call MenuCode.ResetMouseArea
    mov edx,[esp+8]
    mov ecx,[esp+12]
    mov [.MouseRow],edx
    mov [.MouseCol],ecx
    ;jmp .MouseMove

;컴컴컴컴컴컴컴컴컴컴
; get hovered choice
; if valid
;   select hovered choice
; elif new hovered choice <> old hovered choice
;   close menu
; endif
.MouseMove:
    call .GetHoveredSubmenu
    jc .MouseMoveOutside        ;edi and dl
    call .SetSelectedChoice     ;edi and dl
    cmp [.MousePrevMenu],dword 0
    ja .MmIgnore
    ;debugwrite "mouse moved in to MenuList"
    mov eax,MenuMsg.MouseIn
    jmp short .MmTellItem

.MouseMoveOutside:
    cmp edi,[.MousePrevMenu]
    jae .MmIgnore
    test edi,edi                ;if null menu, ignore
    jnz .MmIgnore
    ;debugwrite "mouse moved out from MenuList"
    mov eax,MenuMsg.MouseOut

.MmTellItem: ;(eax=message)
    push ebx
    call [ebx+GuiObj.Code]
    pop ebx
.MmIgnore:
    clc
    ret

;컴컴컴컴컴컴컴컴컴컴
.ResetMouseArea:
    mov dword [.MouseTop],32768
    mov dword [.MouseCurMenu],0
    ret

;컴컴컴컴컴컴컴컴컴컴
; Returns the MenuList ptr & choice number hovered by the mouse. Sets carry if
; cursor is not over any choice, either over a separator or completely out of
; the menu. Returns null menu ptr and -1 choice number.
;
; (ebx=gui item ptr, dummy dword, mouse row, mouse col)
; (edi=MenuList ptr if found, dl=choice, cf=error)
.GetHoveredSubmenu:
.GhsMouseCol    equ 16
.GhsMouseRow    equ 12

; if still in bounds of last choice
;   return no change
; else ...

    mov edx,[esp+.GhsMouseRow]
    mov ecx,[esp+.GhsMouseCol]
    mov edi,[.MouseCurMenu]
    cmp edx,[.MouseTop]
    mov [.MousePrevMenu],edi
    jl .GhsOut
%if 0
    cmp edx,[.MouseBtm]
    jge .GhsOut
    cmp ecx,[.MouseLeft]
    jl .GhsOut
    cmp ecx,[.MouseRight]
    jge .GhsOut
    cmp edi,1024                ;set carry (only invalid values will set carry)
    jc .GhsRet
    mov dl,[edi+MenuListObj.Selected]
    ;clc
.GhsRet:
    ret
%endif

.GhsOut:
    mov dword [.MouseTop],-32768
    mov dword [.MouseBtm],32767
    mov dword [.MouseLeft],-32768
    mov dword [.MouseRight],32767

; starting from top of heirarchy
; reset mouse bounds
; if row < top or col < left, return error
; do
;   if child exists
;     do
;       if col < child left, return parent
;       if row < child top, exit if
;       if row < child bottom, exit if
;       child becomes parent
;     loop while child exists
;   endif
;   if col >= right
;     set mouse left = right
;     return error
;   endif
; loop

    push ebp
    sub ecx,.EdgeSize
    jge .GhsLeftOk
    mov dword [.MouseRight],.EdgeSize
    jmp .GhsNone                ;col beyond left
.GhsLeftOk:
    mov edi,[ebx+MenuObj.MenuList]
    sub edx,.EdgeSize
    jge .GhsTopOk
    mov dword [.MouseBtm],.EdgeSize
    jmp short .GhsNone          ;row above top
.GhsTopOk:
    cmp [edi+MenuListObj.Height],dx
    jg .GhsBtmOk
    mov dx,[edi+MenuListObj.Height]
    add edx,byte .EdgeSize
    mov [.MouseTop],edx
    jmp short .GhsNone          ;row below bottom
.GhsBtmOk:

    ; get first child and enter loop
    mov esi,[edi+MenuListObj.Child]
    mov eax,ecx                 ;just in case not inside child
    mov ebp,edx                 ;just in case not inside child
    jmp short .ChsCheckChild

.GhsMoreChildren:
    sub ax,[edi+MenuListObj.ChildLeft]
    jl .GhsInParent
    sub bp,[edi+MenuListObj.ChildTop]
    jge .GhsCheckBtm
    neg bp
    add ebp,[esp+.GhsMouseRow+4]    ;child top = -relative row + mouse row
    mov dword [.MouseBtm],ebp
    jmp short .GhsCheckRight
.GhsCheckBtm:
    cmp [esi+MenuListObj.Height],bp
    jg .GhsInChild
    sub bp,[esi+MenuListObj.Height]
    neg ebp
    add ebp,[esp+.GhsMouseRow+4]    ;child bottom = -(relative row - height)
    mov dword [.MouseTop],ebp       ;               + mouse row
    jmp short .GhsCheckRight

.GhsInChild:
    ; check yet another even deeper child
    mov edi,esi
    mov esi,[esi+MenuListObj.Child]
    mov ecx,eax                 ;set new col within child
    mov edx,ebp                 ;set new row within child
.ChsCheckChild:
    test esi,esi
    jnz .GhsMoreChildren        ;loop while another child (not null)

.GhsCheckRight:
    ; ensure col is within MenuList width
    cmp [edi+MenuListObj.Width],cx
    jg .GhsInParent
    ; completely out of menu
    sub cx,[edi+MenuListObj.Width]
    neg ecx
    add ecx,[esp+.GhsMouseCol+4]    ;child right = -(relative col - width)
    mov dword [.MouseLeft],ecx      ;              + mouse col

.GhsNone:
    xor edi,edi
    DebugMessage "no MenuList"
    pop ebp
    mov [.MouseCurMenu],edi
    stc
    ret

; (edx=relative row, ecx=relative col  both positive)
.GhsInParent:
    DebugMessage "over MenuList"
    mov [.MouseCurMenu],edi

    ; set mouse left and right
    neg ecx
    add ecx,[esp+.GhsMouseCol+4]    ;child left = -relative col + mouse col
    mov dword [.MouseLeft],ecx
    add cx,[edi+MenuListObj.Width]
    mov dword [.MouseRight],ecx


; find choice:
; set cursor boundary left\right
; do until last choice
;   if visible (not hidden)
;     get choice height
;     row -= height
;     if row < 0
;       if no menu separator || row < -separator size
;         return choice number
;       else
;         return -1
;       endif
;     endif
;     if choice has open MenuList
;       row -= child MenuList height
;       if row < 0
;         right = child's left
;         exit with choice number
;       endif
;     endif
;   endif
;   choice number++
; loop
; set cursor boundaries
;
; (edi=MenuList ptr, edx=row, ebp on stack)
; (dl=hovered choice, cf=error; edi)

.GhcMouseRow    equ 12+12
.GhcMenuList    equ 4
.GhcOpened      equ 2           ;opened choice (if opened)
.GhcSelected    equ 1           ;selected choice (0-254)
.GhcTotalItems  equ 0           ;total choices in menu (0-255)
    xor ecx,ecx                 ;zero initial choice counter
    push edi                    ;save MenuList ptr
    push dword [edi+MenuListObj.TotalItems] ;for counter comparison
    mov ebp,edx
    jmp short .GhcFirst

.GhcNext:
    mov eax,[edi+MenuListObj.Flags]
    test eax,MenuListObj.Hidden
    jnz .GhcHidden
    call .GetChoiceHeight
;    test eax,MenuListObj.Separator
;    jz .GhcNoSeparator
;    cmp bp,.SepSize
;    jl .GhcNone
;.GhcNoSeparator:
    sub bp,dx
    jl .GhcOverChoice

    cmp [esp+.GhcOpened],cl
    jne .GhcHidden
    mov esi,[esp+.GhcMenuList]
    mov esi,[esi+MenuListObj.Child]
    mov dx,[esi+MenuListObj.Height]
    sub bp,dx
    jl .GhcOverChild

.GhcHidden:
    inc ecx
    add edi,byte MenuListObj.ItemsSizeOf
.GhcFirst:
    cmp [esp+.GhcTotalItems],cl
    ja .GhcNext

.GhcNone:
    DebugMessage "no choice"
    ;mov dl,-1                  ;no choice hovered
    stc
.GhcRet:
    pop eax                     ;discard count
    pop edi                     ;restore MenuList ptr
    pop ebp
    ret

.GhcOverChild:  ;(bp=relative row)
    mov esi,[.MouseLeft]
    add esi,byte 8
    mov [.MouseRight],esi
.GhcOverChoice: ;(bp=relative row)
    neg bp
    movzx edx,dx
    add ebp,[esp+.GhcMouseRow]
    mov [.MouseBtm],ebp
    sub ebp,edx
    mov [.MouseTop],ebp

    ;set top/bottom/right
    ;mov [.MouseTop],bp
    ;set top/bottom
    jmp short .GhcFound
.GhcFound:
    test eax,MenuListObj.Disabled|MenuListObj.Hidden
    mov edx,ecx                 ;return choice number
    jnz .GhcNone
    DebugMessage "over choice"
    ;(cf=0)
    jmp short .GhcRet

;컴컴컴컴컴컴컴컴컴컴
; Opens a child MenuList under the selected branch of menu object.
;
; if selected choice < total choices
;   if choice is valid (not disabled or hidden)
;     if choice has MenuList (not null)
;       open MenuList under selected choice
;     endif
;   endif
; endif
;
; (dword gui item ptr)
; (cf=0; !)
.OpenSelectedChoice:
    mov ebx,[esp+4]
.OpenSelectedChoiceGiven:
    mov edi,[ebx+MenuObj.Selected]
    mov dl,[edi+MenuListObj.Selected]
    cmp dl,[edi+MenuListObj.TotalItems]
    jae .OscRet
    call .CalcChoiceAdr
    test dword [esi+MenuListObj.Flags],MenuListObj.Hidden|MenuListObj.Disabled
    mov esi,[esi+MenuListObj.Submenu]
    jnz .OscRet
    test esi,esi
    jnz .OpenGivenMenu
.OscRet: ;(cf=0)
    ret

;컴컴컴컴컴컴컴컴컴컴
; Opens a child MenuList under the selected branch of menu object.
;
; open choice = selected choice
; parent's child = new MenuList
; contained all children
; if any children contained by another object
;   send notify message to other menu object
; endif
; do entire message sibling chain
;   if open applies menu
;     send open message
;   endif
; enddo
;
; (ebx=menu object,
;  edi=parent MenuList ptr,
;  esi=new child MenuList ptr,
;  dl=choice to open under)
; (cf=0; ebx)
.OpenGivenMenu:
    mov [edi+MenuListObj.Opened],dl
    mov [edi+MenuListObj.Child],esi
    inc dword [.ChangeCount]
    test ebx,ebx
    jz .OgmEnd                  ;null, end now since no container

    ; contain MenuList chain unless already contained by another menu object
    push edi
    call .ContainChain
    push ebx                    ;save menu item ptr
    jnc .OgmUncontained
    mov ebx,eax                 ;give remaining chain to previous menu
    ;esi=MenuList ptr
    call .ContainChainGiven
    ;mov esi,[esp]               ;opened menu should be notified of any changes
    ;call .InsertSibling
    ;mov ebx,esi                 ;restore opened menu

    mov esi,[esp]               ;opened menu should be notified of any changes
    xchg ebx,esi                ;restore opened menu
    call .InsertSibling

;Notify all relevant menu siblings of change
;Loop through linked list until returned to start
;(ptr to owner menu, MenuList ptr)
.OgmMenuList    equ 4
.OgmContainer   equ 0
.OgmNext:
    mov edi,[esp+.OgmMenuList]   ;get ptr to MenuList that was opened
.OgmUncontained:
    call .ScanChain
    jc .OgmSkip
    push ebx
    mov eax,MenuMsg.Open
    call [ebx+GuiObj.Code]
    pop ebx
.OgmSkip:
    mov ebx,[ebx+MenuObj.Sibling]
    cmp [esp+.OgmContainer],ebx
    jne .OgmNext

    ;clc
    pop ebx
    pop edi
.OgmEnd: ;(cf=0)
    ret

;컴컴컴컴컴컴컴컴컴컴
; (edi=parent MenuList ptr)
; (cf=0; !)
.CloseGivenMenu:
.CgmMenuList    equ 8
.CgmChild       equ 4
.CgmContainer   equ 0
    xor esi,esi
    mov al,-1
    xchg [edi+MenuListObj.Child],esi
    inc dword [.ChangeCount]
    xchg [edi+MenuListObj.Opened],al
    test esi,esi
    mov ebx,[edi+MenuListObj.Container]
    jz .CgmEnd                  ;already closed, end now
    mov [edi+MenuListObj.Selected],al
    test ebx,ebx
    jz .CgmEnd                  ;null, end now since no container

;Notify all relevant menu siblings of change
;Loop through linked list until returned to start
;(ptr to owner menu, MenuList's child ptr, closed MenuList ptr)
    push edi
    push esi
    push ebx
.CgmNext:
    mov edi,[esp+.CgmMenuList]   ;get ptr to closed MenuList
    call .ScanChain
    jnc .CgmSendMsg
    mov edi,[esp+.CgmChild]     ;get ptr to child of closed MenuList
    call .ScanChain
    jc .CgmSkip
    call .ContainChain
    jmp short .CgmSkip
.CgmSendMsg:
    push ebx
    mov eax,MenuMsg.Close
    call [ebx+GuiObj.Code]
    pop ebx
.CgmSkip:
    mov ebx,[ebx+MenuObj.Sibling]
    cmp [esp+.CgmContainer],ebx
    jne .CgmNext
    add esp,byte 12

.CgmEnd: ;(cf=0)
    ret

;컴컴컴컴컴컴컴컴컴컴
; Sets the container of a MenuList chain, starting from the given MenuList
; and setting each child below. Stops at the end of the chain or upon
; reaching MenuList already owned by some other gui item.
;
; The importance of this routine is to ensure that any changes made to the
; MenuLists will be reflected to menu objects currently displaying them.
; Otherwise a choice could be disabled and yet it might still appear enabled
; on the screen because the container was never informed to redraw it.
;
; Sets carry if could not set the entire branch because of one child being
; already owned/contained by another menu, and returns ptr to other owner.
;
; (ebx=gui item ptr, edi=MenuList ptr)
; (cf=already owned, eax=other owner, esi=last branch; ebx,edi,edx)
.ContainChainTop:
    mov edi,[ebx+MenuObj.MenuList]
.ContainChain:
    mov esi,edi
.ContainChainGiven: ;(esi=ptr)
.CcNext:
    mov eax,[esi+MenuListObj.Container]
    cmp eax,ebx
    je .CcSkip
    test eax,eax
    jnz .CcEnd
    mov [esi+MenuListObj.Container],ebx
.CcSkip:
    mov esi,[esi+MenuListObj.Child]
    test esi,esi
    jnz .CcNext
    ;clc
    ret
.CcEnd:
    stc
    ret

;컴컴컴컴컴컴컴컴컴컴
; Scans the MenuList heirarchy of a menu item to determine whether a MenuList
; is in it. This can be used to tell which messages are important to which
; menu items. It would be wasteful to send a message related to a MenuList
; that isn't even in the menu.
;
; (ebx=gui item ptr, edi=MenuList to find)
; (cf=not found; ebx,edi)
.ScanChain:
    mov esi,[ebx+MenuObj.MenuList]
.ScNext:
    cmp esi,edi
    je .ScFound
    mov esi,[esi+MenuListObj.Child]
    test esi,esi                ;end of chain if null
    jnz .ScNext
    stc                         ;not found in chain
.ScFound: ;(cf=0)
    ret

;컴컴컴컴컴컴컴컴컴컴
; Inserts a new menu into the sibling chain so that it will be updated
; properly of MenuList changes, but only if it is not already in the chain.
;
; do
;   menu ptr = next sibling
;   if menu ptr = new menu, return
; loop until reached beginning
; swap old next sibling with new menu
; menu ptr = new menu 
; do
;   menu ptr = next sibling
; loop until reached last
; set last menu's next sibling = original
;
; (ebx=menu ptr, esi=new menu sibling)
; (; ebx,esi)
.InsertSibling:
    mov edi,ebx
.IsNext:
    mov edi,[edi+MenuObj.Sibling]
    cmp edi,esi
    je .IsOld
    cmp edi,ebx
    jne .IsNext

.IsNew:
    mov eax,esi
    mov edi,esi
    xchg [ebx+MenuObj.Sibling],eax
.IsNext2:
    mov edi,[edi+MenuObj.Sibling]
    cmp [edi+MenuObj.Sibling],esi
    jne .IsNext2
    mov [edi+MenuObj.Sibling],eax

.IsOld:
    ret

;컴컴컴컴컴컴컴컴컴컴
; (ebx=menu ptr)
; (; ebx)
.DeleteSibling:
    mov esi,ebx
.DsNext:
    mov edi,esi
    mov esi,[esi+MenuObj.Sibling]
    cmp esi,ebx
    jne .DsNext

    mov esi,[ebx+MenuObj.Sibling]
    mov [ebx+MenuObj.Sibling],ebx
    mov [edi+MenuObj.Sibling],esi
    ret

%endif


%ifdef UseFloatMenuCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
section data
aligndd
DefItem FloatMenu,FloatMenuCode,NullGuiItem,FloatMenuObj.DefFlags, 0,0,0,0
        DefMenuObj 0
section code

FloatMenuCode:

section data
    StartMsgJtbl
    AddMsgJtbl MenuMsg.MouseOut,.MenuMouseOut
    AddMsgJtbl MenuMsg.Close,.Close
    AddMsgJtbl MenuMsg.Open,.Open
    ;AddMsgJtbl MenuMsg.Change,.Change
    ;AddMsgJtbl MenuMsg.Rechain,.Rechain
    AddMsgJtbl MenuMsg.Cancel,.Cancel
    AddMsgJtbl MenuMsg.Activate,.Activate
    ;AddMsgJtbl Msg.Created,.Created
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.Focus,MenuCode.ItemFocus
    AddMsgJtbl Msg.KeyPress,MenuCode.KeyPress
    AddMsgJtbl Msg.KeyChar,MenuCode.KeyChar
    AddMsgJtbl Msg.KeyOut,.Hide
    AddMsgJtbl Msg.MousePrsRls,MenuCode.MousePrsRls
    AddMsgJtbl Msg.MouseMove,MenuCode.MouseMove
    AddMsgJtbl Msg.MouseIn,MenuCode.MouseIn
    AddMsgJtbl Msg.MouseOut,MenuCode.MouseMove;.Hide

.Pos:
.Top:       dw 0
.Left:      dw 0
.Size:
.Height:    dw 0
.Width:     dw 0
.KeyItem:   dd NullGuiItem      ;item that had focus prior to menu
.Alignment:
.Flags:     dd 0
section code


    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
; draw main menu background
; draw choices
; do until last child
;   if menu has key focus && MenuList is selected, MenuList shows focus
;   draw MenuList
;   draw choices
; end do
.Draw:
    test dword [ebx+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.RedrawForced
    jz near MenuCode.DrawAllChoices

.DrawBg:
    ; get top level menu
    ; do
    ;   calculate dimensions of all sides
    ;   draw background and edges
    ;   get child MenuList
    ; loop until last menu

    push dword [Display.ClipLeft]
    push ebx
    mov edi,[ebx+MenuObj.MenuList]
    xor eax,eax                 ;top|left
    test dword [.Alignment],FloatMenuObj.AlignHeight|FloatMenuObj.AlignWidth
    jz .DrawBgNext
    mov ebx,[.Size]             ;get size of item that menu is based on
    push edi
  %ifdef UseSmallScreen
    lea edx,[ebx-(1<<16)]       ;bottom|right = height|width - 1 columns
  %else
    lea edx,[ebx-(2<<16)]       ;bottom|right = height|width - 2 columns
  %endif
    push edx                    ;save for later
    push dword DrawBorder.Filled;|DrawBorder.Concave
    jmp short .DrawBorder

.DrawBgNext:
    mov ebx,[edi+MenuListObj.Size]
    push edi
    add ebx,MenuCode.EdgeSize*2+FontDefHbody-FontDefHeight | (MenuCode.EdgeSize<<17) ;height|width
  %ifdef UseSmallScreen
    lea edx,[eax+ebx-(1<<16)]   ;bottom|right = top|left + height|width - 1 columns
  %else
    lea edx,[eax+ebx-(2<<16)]   ;bottom|right = top|left + height|width - 2 columns
  %endif
    push edx                    ;save for later

    push dword DrawBorder.Filled
.DrawBorder:
    push ebx                    ;height|width
    push eax                    ;top|left
    call DrawBorder
    pop eax                     ;retrieve top|left
    add esp,byte 8              ;discard size and draw mode

    pop edx                     ;get bottom|right
    pop edi                     ;get MenuList ptr
    shr edx,16
    cmp [Display.ClipLeft],edx
    jae .DrawBgNoClip
    mov [Display.ClipLeft],edx
.DrawBgNoClip:

    add eax,[edi+MenuListObj.ChildPos]
    mov edi,[edi+MenuListObj.Child]
    test edi,edi
    jnz near .DrawBgNext

    pop ebx
    pop dword [Display.ClipLeft]
    jmp MenuCode.DrawAllChoices
    ;ret

;컴컴컴컴컴컴컴컴컴컴
; Minor change to one of the choices in a MenuList (such as text change or
; disabled/enabled).
.Change:

;컴컴컴컴컴컴컴컴컴컴
; Major change to one of the choices in a MenuList, forcing the heirarchy
; chain to be resized (such as choice being hidden/shown or separator bar
; being removed/inserted).
.Rechain:
    int3;
    ret

;컴컴컴컴컴컴컴컴컴컴
; A branch of a MenuList used by this object has been closed.
; The owner of the MenuList is always notified first, followed by any other
; siblings that are also showing the same MenuList. Any unowned MenuLists will
; be claimed.
.Close:

;컴컴컴컴컴컴컴컴컴컴
; A child of a MenuList used by this object has been opened.
; The owner of the MenuList is always notified first, followed by any other
; siblings that are also showing the same MenuList.
.Open:

;컴컴컴컴컴컴컴컴컴컴
.Repos:  ;(ebx=menu item ptr) (; ebx)
    call MenuCode.Rechain       ; resize each child of MenuList chain
    call MenuCode.GetTotalSize  ; get entire size of floating menu

    test dword [.Alignment],FloatMenuObj.AlignHeight|FloatMenuObj.AlignWidth
    jz .SizeOk
    cmp dx,[.Height]
    jae .HeightOk
    mov dx,[.Height]
.HeightOk:
    cmp cx,[.Width]
    jae .WidthOk
    mov cx,[.Width]
.WidthOk:
.SizeOk:
    push cx                     ;width
    push dx                     ;height

    ; reposition menu column based on current alignment
    mov al,[.Alignment]
    mov cx,[.Left]
    mov di,[.Width]
    test al,FloatMenuObj.AlignWidth
    jnz .LeftOk
    test al,FloatMenuObj.AlignLeft
    jnz .AlignLeft
    test al,FloatMenuObj.AlignRight
    jnz .AlignRight
    test al,FloatMenuObj.AlignCol
    jnz .AlignCol
    mov cx,[FloatMenu+GuiObj.Left]
    jmp short .ColCheck

.AlignRight:
    test al,FloatMenuObj.AlignCol
    jnz .ColCheck
    add cx,di
    jmp short .ColCheck

.AlignLeft:
    sub cx,[esp+2]
    test al,FloatMenuObj.AlignCol
    jz .ColCheck
    add cx,di
    jmp short .ColCheck

.AlignCol:
    sub di,[esp+2]
    sar di,1
    add cx,di
    ;jmp short .ColCheck

.ColCheck:
    mov edi,ecx
    mov esi,[FloatMenu+GuiObj.Container]
    add di,[esp+2]
    sub di,[esi+GuiObj.Width]
    jle .RightOk
    sub cx,di
.RightOk:
    test cx,cx
    jge .LeftOk
    xor ecx,ecx
.LeftOk:

    ; reposition menu row based on current alignment
    ;mov al,[.Alignment] (already in al)
    mov dx,[.Top]
    mov di,[.Height]
    test al,FloatMenuObj.AlignHeight
    jnz .TopOk
    test al,FloatMenuObj.AlignTop
    jnz .AlignTop
    test al,FloatMenuObj.AlignBtm
    jnz .AlignBtm
    test al,FloatMenuObj.AlignRow
    jnz .AlignRow
    mov dx,[FloatMenu+GuiObj.Top]
    jmp short .RowCheck

.AlignBtm:
    test al,FloatMenuObj.AlignRow
    jnz .RowCheck
    add dx,di
    jmp short .RowCheck

.AlignTop:
    sub dx,[esp]
    test al,FloatMenuObj.AlignRow
    jz .RowCheck
    add dx,di
    jmp short .RowCheck

.AlignRow:
    sub di,[esp]
    sar di,1
    add dx,di
    ;jmp short .RowCheck

.RowCheck:
    mov edi,edx
    ;mov esi,[FloatMenu+GuiObj.Container]
    add di,[esp]
    sub di,[esi+GuiObj.Height]
    jle .BtmOk
    sub dx,di
.BtmOk:
    test dx,dx
    jge .TopOk
    xor edx,edx
.TopOk:

    push cx                     ;left
    push dx                     ;top
    mov eax,Msg.MoveSize
    call SendContainerMsg
    add esp,byte 8
    ret

;컴컴컴컴컴컴컴컴컴컴
; (dword parent MenuList ptr,
;  dword selected MenuList,
;  dword owner,
;  dword flags/alignment
;  words top,left
;  words height,width)
; (; ebx)
.Show:
    push ebx
    mov edi,[esp+8]
    mov esi,[esp+12]
    mov ebx,[esp+16]
    mov eax,[esp+20]
    mov ecx,[esp+24]
    mov edx,[esp+28]
    mov [FloatMenu+MenuObj.MenuList],edi
    mov [FloatMenu+MenuObj.Selected],esi
    mov [FloatMenu+GuiObj.Owner],ebx
    mov [.Flags],eax
    mov [.Pos],ecx
    mov [.Size],edx

    mov ebx,FloatMenu
    call .Repos

    ; get item with current key focus and set focus to self
    mov edx,[ebx+GuiObj.Flags]
    and dword [ebx+GuiObj.Flags],~(GuiObj.Hidden|GuiObj.Disabled|GuiObj.NoKeyFocus|GuiObj.NotFullFocus|GuiObj.Redraw)
    test edx,GuiObj.Hidden|GuiObj.Disabled
    jz .AlreadyVisible
    mov eax,Msg.GetKeyFocus|KeyMsgFlags.Recurse
    mov esi,FloatMenu           ;in case message is ignored
    call SendContainerMsg
    mov [.KeyItem],esi

    push ebx                    ;save ptr to self
    mov ebx,[esi+GuiObj.Container] ;get ptr to item's container
    mov eax,Msg.SetKeyFocus|KeyMsgFlags.SetContainer
    push ebx                    ;pass container's data structure
    call [ebx+GuiObj.Code]
    pop eax                     ;discard ptr
    pop ebx                     ;restore ptr to self
.AlreadyVisible:

    call MenuCode.ItemFocus

    call MenuCode.ContainChainTop
    jnc .Uncontained
    mov esi,eax
    call MenuCode.InsertSibling ;newly shown menu should be notified of any changes
.Uncontained:

    mov eax,GuiObj.RedrawBg
    call SendContainerRedraw
    pop ebx
    ret

;컴컴컴컴컴컴컴컴컴컴
; A choice has been activated (with no child MenuList)
.Activate:
    ;mov eax,MenuMsg.Activate
    call SendOwnerMsg.Important
    mov eax,MenuMsg.Destroy|MenuMsg.ChoiceDestroy
    call SendOwnerMsg
    jc .Hide
    ret

;컴컴컴컴컴컴컴컴컴컴
; Escape was pressed
.Cancel:
    ;mov eax,MenuMsg.Cancel
    call SendOwnerMsg
    mov eax,MenuMsg.Destroy|MenuMsg.KeyDestroy
    call SendOwnerMsg
    jc .Hide
    stc
    ret

;컴컴컴컴컴컴컴컴컴컴
; Mouse was moved out of menu
.MenuMouseOut:
    ;mov eax,MenuMsg.MouseOut
    ;call SendOwnerMsg
    mov eax,MenuMsg.Destroy|MenuMsg.MouseDestroy
    call SendOwnerMsg
    jc .Hide
    ;clc
    ret

;컴컴컴컴컴컴컴컴컴컴
; Hides the floating menu. Sets disabled and hidden flags. Restores key focus
; to whatever item had it before the menu.
;
; (al=cancel||mouseout||?) (cf=0; ebx)
.Hide:
    push ebx
    mov dword [FloatMenu+GuiObj.Owner],NullGuiItem
    mov ebx,FloatMenu

    mov eax,Msg.GetKeyFocus|KeyMsgFlags.Recurse
    mov esi,FloatMenu           ;in case message is ignored
    call SendContainerMsg
    push esi                    ;save ptr to item with key focus

    ; get item with current key focus and set focus to self
    ;or dword [ebx+GuiObj.Flags],GuiObj.Hidden|GuiObj.Disabled|GuiObj.NotFullFocus
    push dword [ebx+GuiObj.Flags]
    mov eax,Msg.SetFlags
    ;or dword [esp],GuiObj.Hidden|GuiObj.Disabled|GuiObj.NotFullFocus|GuiObj.NoKeyFocus
    or dword [esp],GuiObj.Hidden|GuiObj.Disabled|GuiObj.NoKeyFocus|GuiObj.NoItemFocus
    call SendContainerMsg
    pop eax                     ;discard flags

    pop esi

    cmp ebx,esi                 ;only restore focus to previous item if menu still has focus    jne .HideNoKeyFocus
    jne .HideNoKeyFocus
    mov ebx,[.KeyItem]
    mov eax,Msg.SetKeyFocus|KeyMsgFlags.SetContainer
    call SendContainerMsg
.HideNoKeyFocus:
    pop ebx
    clc
    ret

%else

%define FloatMenu NullGuiItem

%endif


%ifdef UseEmbedMenuCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
EmbedMenuCode:

section data
    StartMsgJtbl
    AddMsgJtbl MenuMsg.Destroy,.Destroy
    ;AddMsgJtbl MenuMsg.Rechain,.Rechain
    ;AddMsgJtbl MenuMsg.Change,.Change
   %ifdef UseFloatMenuCode
    ;AddMsgJtbl MenuMsg.MouseIn,.MenuMouseIn
   %endif
    AddMsgJtbl MenuMsg.Close,.Close
    AddMsgJtbl MenuMsg.Open,.Open
    ;AddMsgJtbl MenuMsg.Cancel,AckMsg
   %ifdef UseFloatMenuCode
    AddMsgJtbl MenuMsg.Select,.Select
   %else
    AddMsgJtbl MenuMsg.Select,SendOwnerMsg
   %endif
    AddMsgJtbl MenuMsg.Activate,SendOwnerMsg.Important
    AddMsgJtbl Msg.Created,.Created
    AddMsgJtbl Msg.Redraw,.Draw
    AddMsgJtbl Msg.Focus,.ItemFocus
    AddMsgJtbl Msg.KeyPress,MenuCode.KeyPress
    AddMsgJtbl Msg.KeyChar,MenuCode.KeyChar
    AddMsgJtbl Msg.MousePrsRls,MenuCode.MousePrsRls
    AddMsgJtbl Msg.MouseMove,MenuCode.MouseMove
    AddMsgJtbl Msg.MouseIn,.MouseIn
    ;AddMsgJtbl Msg.MouseOut,MenuCode.MouseOut
section code

    UseMsgJtbl

;컴컴컴컴컴컴컴컴컴컴
; contain MenuList chain
; if already contained by another menu object
;   insert sibling
; endif
; rechain MenuList chain
.Created:
    call MenuCode.ContainChainTop
    jnc near MenuCode.Rechain
    mov esi,eax
    call MenuCode.InsertSibling
    jmp MenuCode.Rechain

;컴컴컴컴컴컴컴컴컴컴
; draw main menu background
; draw choices
.Draw:
  %ifdef UseFloatMenuCode
    cmp [FloatMenu+GuiObj.Owner],ebx
    je .DeferToFloatMenu
  %endif

    test dword [ebx+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.RedrawForced
    jz .DrawPartial
    push ebx
    push dword DrawBorder.Filled|DrawBorder.NoEdge
    push dword [ebx+GuiObj.Size]
    push dword 0
    call DrawBorder
    add esp,byte 12
    pop ebx
.DrawPartial:

    call MenuCode.DrawAllChoices

    push dword DrawBorder.Concave
    push dword [ebx+GuiObj.Size]
    push dword 0
    call DrawBorder
    add esp,byte 12
    ret

;컴컴컴컴컴컴컴컴컴컴
; A branch of a MenuList used by this object has been closed.
; The owner of the MenuList is always notified first, followed by any other
; siblings that are also showing the same MenuList. Any unowned MenuLists will
; be claimed.
.Close:

;컴컴컴컴컴컴컴컴컴컴
; A child of a MenuList used by this object has been opened.
; The owner of the MenuList is always notified first, followed by any other
; siblings that are also showing the same MenuList.
.Open:

;컴컴컴컴컴컴컴컴컴컴
.Rechain:
  %ifdef UseFloatMenuCode
    cmp [FloatMenu+GuiObj.Owner],ebx
    je .DeferToFloatMenu
  %endif

    call MenuCode.Rechain
    mov eax,GuiObj.RedrawBg
    jmp SendContainerRedraw

.DeferToFloatMenu:
    ret

;컴컴컴컴컴컴컴컴컴컴
; Abort destruction of floating menu if either pressing Escape or choosing a
; choice is the cause. Any other reason, continue destruction.
.Destroy:
    test eax,MenuMsg.KeyDestroy|MenuMsg.ChoiceDestroy
    jnz .DestroyAbort
    stc
.DestroyAbort:
    ret

;컴컴컴컴컴컴컴컴컴컴
%ifdef UseFloatMenuCode
.Select:
    cmp [FloatMenu+GuiObj.Owner],ebx
    jne .SelectNoFloatMenu
    mov eax,[FloatMenu+MenuObj.Selected]
    mov [ebx+MenuObj.Selected],eax
.SelectNoFloatMenu:
    jmp SendOwnerMsg
%endif

;컴컴컴컴컴컴컴컴컴컴
.ItemFocus:
%ifdef UseFloatMenuCode
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jnz .NotFullFocus
    push eax
    mov eax,Msg.SetKeyFocus|KeyMsgFlags.SetContainer
    call SendContainerMsg
    pop eax
    ;test eax,FocusMsgFlags.ByMouse
    jmp .ShowFloatMenu
.NotFullFocus:
    cmp [FloatMenu+GuiObj.Owner],ebx
    je near FloatMenuCode.Hide
%else
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jnz .NotFullFocus
    mov eax,Msg.SetKeyFocus|KeyMsgFlags.SetContainer
    call SendContainerMsg
.NotFullFocus:
%endif
    jmp MenuCode.ItemFocus

%ifdef UseFloatMenuCode
;컴컴컴컴컴컴컴컴컴컴
.ShowFloatMenu:
    call GetItemAbsPosition
    push dword [ebx+GuiObj.Size]
    push cx                     ;left
    push dx                     ;top
    push dword FloatMenuObj.AlignHeight|FloatMenuObj.AlignWidth
    push dword ebx
    push dword [ebx+MenuObj.Selected]
    push dword [ebx+MenuObj.MenuList]
    call FloatMenuCode.Show
    add esp,byte 24
    ret
%endif

;컴컴컴컴컴컴컴컴컴컴
.MouseIn:
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetGroup|FocusMsgFlags.SetItem|FocusMsgFlags.ByMouse
    call SendContainerMsg
    jmp MenuCode.MouseIn

;컴컴컴컴컴컴컴컴컴컴
%ifdef UseFloatMenuCode
.MenuMouseIn:
    cmp [FloatMenu+GuiObj.Owner],ebx
    je .MmiRet
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jz .ShowFloatMenu
.MmiRet:
    ret
%endif

%endif


%ifdef UseHelpBubbleCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
HelpBubbleCode:
; While shown, it checks every 30th second for mouse or key changes. Upon
; either the cursor being moved or a key being pressed, it queries the active
; item for a help message and its screen position. If that message is already
; being displayed, do nothing. Otherwise, resize based on the message text,
; reposition based on the active item's screen position, and redraw with the
; new help text.
%endif

%ifdef UseHelpBubbleCode
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
ProgressBarCode:
;
%endif
