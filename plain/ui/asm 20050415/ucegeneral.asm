;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; General Object functions
; Reading redrawing items, sending mouse messages...
;
; Some of these routines are used by the main program, others by items, and
; others only by windows or items based on (subclassed) off the window data
; structure.
;
; Todo:
;   Release mouse confinement when moving back in
;   Decide SetItemFocus chain container
;
; Sokay:
;   send timer msgs (doesn't always destroy the timer)
;   keyboard character translation for DOS
;
; Parameter Notation:
;   Before each routine, you see a set of parameters in parenthesis. The
;   first set is the parameters in, either on the stack or in a register. The
;   second set is the parameters out, either return values or the regs
;   preserved. Unlike C routines, expect these functions to use any/all
;   general registers (but leave alone any segment registers, esp, and ebp).
;   So save any that need to be retained. An exclamation mark between the
;   parenthesis means that none are saved.
;
; Returns Values:
;   Most GUI functions and object items indicate an error by setting cf. When
;   sending messages, cf means the message was unrecognized or ignored. For
;   example, keyboard input sent to a label (which can't accept key input)
;   would be ignored, and carry would be set.
;
; Pseudocode:
;   For some of the more complex functions I kept the pseudocode. It should
;   make the code easier to understand. Sometimes I need to reread it just to
;   understand again.
;
; Object types:
;   Many of these routines deal specifically with the WindowObj type.
;   Attempting to call these (SendKeyMsg, SendMouseMsg, SetItemFocus...) on
;   an object like a text prompt will cause a GPF. Only program code that
;   knows exactly what an item type is or object code that is based off the
;   WindowObj type should ever directly call these. Contained items or
;   sibling items should always call other items with a message for safety.
;
;
; SendKeyMsg                    passes message to contained items
; SetKeyFocus                   sets item which takes key input
; SetKeyFocus.OfActive          sends gain/lost message to active item
; GetKeyFocus                   get current key focus item
;
; SendMouseMsg                  passes message to contained items
; SendMouseMsg.GetItemAt        returns item cursor is over
; ConfineCursor                 restricts cursor movement to area
; GetItemAbsPosition            returns position on screen of given point
; SetMouseFocus                 sets item with cursor focus
; SetMouseFocus.OfActive        sets mouse focus to item under cursor
; GetMouseFocus                 sets item with cursor focus
;
; -CreateItem					adds item to container
; -DestroyItem					removes item from container
; MoveItem						changes item position/size
; SetOrder						changes item zlayer order (before, behind)
; SetItemFlags                  modifies flags, reacting accordingly
;
; AddItemToRedraw               merges item bounds to container redraw area
; SendContainerRedraw           tells container than an item needs redrawn
; SendRedrawSimple              tells all items in container to redraw now
; SendRedrawComplex             redraws all items in zlayer order
;

%ifndef GuiDefsInc
;Requires Gui Definitions
%include "guidefs.asm"          ;GUI messages and object definitions
%endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
section data
aligndd

section code


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Sends keypress to item with current key focus. Note that key messages are
; always sent through containers first before being passed on to their items;
; however, the container usually checks the keys after the contained item
; gets its chance. Although a container might preview a keypress before
; forwarding to its active item, checking it afterwards gives the item a
; chance to interpret it first. For example, the arrow keys usually change
; key focus in a container, but while a text prompt is active, the arrow keys
; should be instead be processed by the prompt for proper caret movement.
; Only if the item ignores the keypress should the container do its default
; action.
;
; (eax=message, dword WindowObj ptr)
; (cf=item ignored message; !)
SendKeyMsg:
    ; simply pass message to active item
    mov ebx,[esp+4]             ;get window data structure
.GivenWinPtr:
    mov ebx,[ebx+WindowObj.KeyItem]
.GivenItemPtr:
    test dword [ebx+GuiObj.Flags],GuiObj.Disabled|GuiObj.Null ;|GuiObj.NoKeyFocus
    stc
    jnz .Err
    push ebx                    ;pass item data
    call [ebx+GuiObj.Code]
    pop ebx                     ;discard, do not affect carry, in case item ignored it
.Err: ;(cf=1)
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Sets which item key input is sent to. The change fails if the new item is
; disabled, null, or can not receive key focus. If successful, both the old
; and new items will receive messages. If the new item is the same one, no
; messages are sent.
;
; Setting .Silent and .Container flags are exclusive, since silence prevents
; it from sending a message to the container.
;
; (eax=message|flags, dwords WindowObj ptr, new item ptr)
; (!, cf=item could not be set, esi=item ptr if used as function)
SetKeyFocus:

;+esp
.WinPtr         equ 4           ;container ptr
.ItemPtr        equ 8           ;ptr to new item to recieve focus

    mov esi,[esp+.WinPtr]       ;get container data structure

    ; check if new item is permitted key focus & and if any change
    mov ebx,[esp+.ItemPtr]
    test dword [ebx+GuiObj.Flags],GuiObj.NoKeyFocus|GuiObj.Disabled|GuiObj.Null
    stc
    jnz .NoChange
    test dword [ebx+GuiObj.Flags],GuiObj.KeyFocus
    jz .Inactive
    cmp [esi+WindowObj.KeyItem],ebx ;new item = old item
    je .NoChange
.Inactive:

    ; set new item & chain to container if necessary
    xchg [esi+WindowObj.KeyItem],ebx ;swap new item with one mouse was previously over
    test eax,KeyMsgFlags.Silent
    jnz .NoChange
    test dword [esi+GuiObj.Flags],GuiObj.KeyFocus
    jnz .HasFocus
    test eax,KeyMsgFlags.SetContainer
    jz .NoChange
;컴컴컴컴컴
.ChainContainer:
    ;debugwrite "SetKeyFocus: chain container"
    push esi                    ;set the key focus to the container
    mov ebx,[esi+GuiObj.Container]
    push ebx                    ;call the container's container
    ;mov eax,Msg.SetKeyFocus (already set)
    call [ebx+GuiObj.Code]
    add esp,byte 8
    ;clc
    ret
.HasFocus:

    ; send KeyOut message to previous item
    test dword [ebx+GuiObj.Flags],GuiObj.Null|GuiObj.Disabled|GuiObj.NoKeyFocus
    jnz .IgnoreOld
    push eax
    push ebx                    ;pass item's/container's data structure
    and eax,~KeyMsgFlags.SetItem
    and dword [ebx+GuiObj.Flags],~GuiObj.KeyFocus
    mov al,Msg.KeyOut
    call [ebx+GuiObj.Code]
    pop ebx
    pop eax
.IgnoreOld:

    ; send KeyIn messsage to new item
    ;test dword [esi+GuiObj.Flags],GuiObj.NoKeyFocus|GuiObj.Disabled|GuiObj.Null
    ;jnz .IgnoreNew
    mov ebx,[esp+.ItemPtr]
    or eax,KeyMsgFlags.SetItem
    push ebx
    mov al,Msg.KeyIn
    or dword [ebx+GuiObj.Flags],GuiObj.KeyFocus
    call [ebx+GuiObj.Code]
    pop ebx
.IgnoreNew:
    ;clc

.NoChange:
    ret


;컴컴컴컴컴
; Relays container's key focus changes to last active item. Depending on
; whether the container is gaining or losing focus, it will either send key
; out or key in.
;
; (eax=focus change message, dword WindowObj ptr)
; (!)
.OfActive:
    ; if container is losing focus
    ;   send focus out msg
    ; elif gaining focus
    ;   use previous item (or maybe find new item?)
    ;   send focus in msg
    ; endif

    mov ebx,[esp+.WinPtr]
    ;test dword [ebx+GuiObj.Flags],GuiObj.KeyFocus
    test eax,KeyMsgFlags.SetItem
    mov ebx,[ebx+WindowObj.KeyItem]
    jnz .In

.Out:
    ;mov eax,Msg.KeyOut (already set)
    and dword [ebx+GuiObj.Flags],~GuiObj.KeyFocus
    jmp short .SendMsg           ;send mouse focus out message to old item
    ;ret

.In:
    ;debugwrite "SetKeyFocus: gained focus"
    ;mov eax,Msg.Key|KeyMsgFlags.SetItem (already set)
    or dword [ebx+GuiObj.Flags],GuiObj.KeyFocus
    ;jmp short .SendMsg          ;send mouse focus out message to old item
    ;ret

;컴컴컴컴컴
; (eax=msg|flags, ebx=item ptr)
; (cf=0)
.SendMsg:
    test dword [ebx+GuiObj.Flags],GuiObj.NoKeyFocus|GuiObj.Disabled|GuiObj.Null
    jnz .IgnoreSend
.SendNoCheck:
    push ebx                    ;pass item's/container's data structure
    mov al,Msg.KeyOut
    call [ebx+GuiObj.Code]
    pop ebx
    clc
.IgnoreSend:
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Function to return the current contained item with key focus, optionally
; recursing down to the lowest level.
;
; (eax=message|flags, dwords WindowObj ptr)
; (!, cf=0, esi=key focus item ptr)
GetKeyFocus:

;+esp
.WinPtr         equ 4           ;container ptr
.ItemPtr        equ 8           ;ptr to new item to recieve focus

    mov esi,[esp+.WinPtr]       ;get container data structure
    test eax,KeyMsgFlags.Recurse
    mov ebx,[esi+WindowObj.KeyItem]
    jz .ReturnKeyItem
    test dword [ebx+GuiObj.Flags],GuiObj.Disabled|GuiObj.NoKeyFocus|GuiObj.Null
    jnz .ReturnSelf
    ;debugwrite "GetKeyFocus: recursing ebx=%X",ebx
    push ebx
    mov esi,ebx
    call [ebx+GuiObj.Code]
    pop ebx
    clc
    ret
.ReturnKeyItem: ;(cf=0)
    mov esi,ebx
.ReturnSelf: ;(cf=0)
    debugwrite "GetKeyFocus: returning esi=%X",ebx
    ;clc
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Sends mouse move, press, or release to item which cursor is currently over.
; If the cursor has moved out from one item over to another one, this routine
; will send MouseOut to the old item, search through the list for the new one,
; and send MouseIn to the new one. It searches through the list starting from
; the top layer to the back, same order as drawing. If the item ignores the
; message or no item exists under the mouse cursor to receive the message, the
; container may do its default action.
;
; (eax=message, dword item data, window gui, row, column)
; (cf=item ignored message)
SendMouseMsg:
    ;translate coordinates relative to previous object's top/left
    ;if in bounds of previous area
    ;  send message to current object
    ;else out of bounds of previous area
    ;  find new object and recalculate object area
    ;  if still in bounds of previous object (new object = old object)
    ;    send message to current object
    ;  else
    ;    send MouseOut to previous object
    ;      the object must ignore any buttons pressed, because they were not
    ;      pressed while over the item losing mouse focus
    ;    send MouseIn to new object
    ;      the object may also check for any buttons pressed
    ;  endif
    ;endif
    ;
    ;when sending mouse messages:
    ;  translate coordinates relative to new object's top/left
    ;  send message

;+esp
.WinPtr         equ 4   ;container ptr
.CursorRow      equ 8   ;row offset relative within container
.CursorCol      equ 12  ;column offset ...
section data
align 4
.Counter:       dd 0
.AreaTopLeft:
.AreaTop:       dw 0
.AreaLeft:      dw 0
.AreaBtmRight:
.AreaBtm:       dw 32767
.AreaRight:     dw 32767
section code

;컴컴컴컴컴컴컴컴컴컴
; Called to relay mouse moves/presses/releases
;
    mov ebx,[esp+.WinPtr]       ;get window data structure
    mov edx,[esp+.CursorRow]    ;get cursor row
    mov ecx,[esp+.CursorCol]    ;& column
    call .GetItemAt
    cmp [ebx+WindowObj.MouseItem],esi ;new item = old item
    je .Send                    ;same item

.ItemChanged:
    ; (eax=message, esi=item found)
    DebugMessage "mouse focus change"
    push esi                    ;save item found
    push eax                    ;save message and flags
    xor edi,edi
    xchg [ebx+WindowObj.MouseItem],esi ;swap new item with one mouse was previously over
    mov al,Msg.MouseOut
    call .Focus                 ;send mouse focus out message to old item
    pop eax
    pop esi
    mov al,Msg.MouseIn
    mov edi,GuiObj.MouseFocus
    mov ebx,[esp+.WinPtr]
    mov edx,[esp+.CursorRow]
    mov ecx,[esp+.CursorCol]
    or eax,MouseMsgFlags.SetItem
    ;call .Focus                ;send mouse focus in message to new item
    ;ret

;컴컴컴컴컴컴컴컴컴컴
; Updates flags appropriately before sending mouse focus changes
;
; (eax=message
;  esi=item ptr,
;  edi=mouse focus flag,
;  ecx/edx=mouse position)
; (!)
.Focus:
    mov ebx,[esi+GuiObj.Flags]
    test ebx,GuiObj.Null ;|GuiObj.NoMouseFocus
    jnz .IgnoreSend             ;just in case one of the flags was set between calls
    and ebx,~GuiObj.MouseFocus
    or ebx,edi
    mov [esi+GuiObj.Flags],ebx
    jmp short .SendNoCheck
    ;ret

;컴컴컴컴컴컴컴컴컴컴
; Actually sends the message
;
; (eax=message,
;  esi=item ptr,
;  ecx/edx=mouse position)
; (!)
.Send:
    test dword [esi+GuiObj.Flags],GuiObj.NoMouseFocus|GuiObj.Disabled|GuiObj.Null
    jnz .IgnoreSend
; (al=message, esi=item ptr, ecx/edx=mouse position)
.SendNoCheck:
    sub cx,[esi+GuiObj.Left]    ;make coordinates relative to item's top/left
    sub dx,[esi+GuiObj.Top]
    mov ebx,esi
    movsx ecx,cx
    movsx edx,dx
    push edx                    ;row
    push ecx                    ;column
	push eax					;message
    push esi                    ;pass gui item's data structure
    call [esi+GuiObj.Code]
    lea esp,[esp+16]
    ret
.IgnoreSend:
    stc
    ret

;컴컴컴컴컴컴컴컴컴컴
; Tests current item boundaries and if outside, searches through all items
; to find the one the mouse if currently over.
;
;(ebx=WindowObj ptr, ecx=column, edx=row)
;(esi=new item found ptr; eax,ebx)
.GetItemAt:
    ; verify cursor is inside item boundaries
    cmp [ebx+WindowObj.MouseTop],dx  ;top > row
    jg .SearchItems
    cmp [ebx+WindowObj.MouseBtm],dx  ;bottom <= row
    jle .SearchItems
    cmp [ebx+WindowObj.MouseLeft],cx ;left > column
    jg .SearchItems
    cmp [ebx+WindowObj.MouseRight],cx;right <= column
    jle .SearchItems
    mov esi,[ebx+WindowObj.MouseItem]  ;same item mouse was previously over
    ret

;(eax=message, ebx=WindowObj ptr)
;(esi=new item ptr; ebx)
.SearchItems:
    ;DebugMessage "mouse area change"

    ; recalculate area and find which item mouse cursor is over
    movzx esi,word [ebx+WindowObj.TotalItems]
    dec esi
    jns .NoError
    mov dword [ebx+WindowObj.MouseTopLeft],-32768|(-32768<<16)
    mov dword [ebx+WindowObj.MouseBtmRight],32767|(32767<<16)
    mov esi,NullGuiItem
    ret
.NoError:

    push eax                    ;save message
    mov [.Counter],esi
    lea edi,[ebx+WindowObj.ItemsLayer+esi*8]
    mov dword [.AreaTopLeft],0  ;set area ranges to maximum extents
    mov dword [.AreaBtmRight],32767|(32767<<16)

.CheckNextItem:
    movzx esi,word [edi]        ;get layer index
    push ebx
    mov esi,[ebx+WindowObj.ItemsPtr+esi*8]  ;get ptr to item data
    test dword [esi+GuiObj.Flags],GuiObj.NoMouseFocus|GuiObj.Disabled|GuiObj.Null
    jnz .SkipItem

    ;do from first object to last
    ;  if mouse row >= object top
    ;    if mouse row < object bottom (top + height)
    ;      if mouse column >= object left
    ;        if mouse column < object right (left + width)
    ;          (object has been found)
    ;          if object top > area top
    ;            area top = object top
    ;          endif
    ;          if object bottom < area bottom
    ;            area bottom = object bottom
    ;          endif
    ;          if object left > area left
    ;            area left = object left
    ;          endif
    ;          if object right < area right
    ;            area right = object right
    ;          endif
    ;          set mouse area ranges to those found
    ;          exit loop and return object's ptr
    ;        else mouse column >= object right
    ;          if object right > area left
    ;            area left = object right
    ;          endif
    ;        endif
    ;      else mouse column < object left
    ;        if object left < area right
    ;          area right = object left
    ;        endif
    ;      endif
    ;    else mouse row >= object bottom
    ;      if object bottom > area top
    ;        area top = object bottom
    ;      endif
    ;    endif
    ;  else mouse row < object top side
    ;    if object top < area bottom
    ;      area bottom = object top
    ;    endif
    ;  endif
    ;loop
    ;set item to null if none were found
    ;set mouse area ranges to those found

    ;compare top/bottom/left/right sides
    mov bx,[esi+GuiObj.Top]
    cmp dx,bx                   ;if mouse row >= object top
    jl .BeyondTop
    add bx,[esi+GuiObj.Height]
    cmp dx,bx                   ;if mouse row < object bottom (top + height)
    jge .BeyondBottom
    mov ax,[esi+GuiObj.Left]
    cmp cx,ax                   ;if mouse column >= object left
    jl .BeyondLeft
    add ax,[esi+GuiObj.Width]
    cmp cx,ax                   ;if mouse column < object right (left + width)
    ;jge .BeyondRight
    jl near .ItemFound

  .BeyondRight:                 ;(ax=object right)
    cmp [.AreaLeft],ax          ;if area left < object right
    jnl .SkipItem               ;  area left = object right
    mov [.AreaLeft],ax
    jmp short .SkipItem
  .BeyondLeft:                  ;(ax=object left)
    cmp [.AreaRight],ax         ;if area right > object left
    jng .SkipItem               ;  area right = object left
    mov [.AreaRight],ax
    jmp short .SkipItem
  .BeyondBottom:                ;(bx=object bottom)
    cmp [.AreaTop],bx           ;if area top < object bottom
    jnl .SkipItem               ;  area top = object bottom
    mov [.AreaTop],bx
    jmp short .SkipItem
  .BeyondTop:                   ;(bx=object top)
    cmp [.AreaBtm],bx           ;if area bottom > object top
    jng .SkipItem               ;  area bottom = object top
    mov [.AreaBtm],bx
    ;jmp short .SkipItem

.SkipItem:
    sub edi,byte WindowObjItems.SizeOf
    dec dword [.Counter]
    pop ebx                     ;retrieve WindowObj ptr
    jns near .CheckNextItem
    DebugMessage "mouse area null"
    mov esi,NullGuiItem         ;item was not found

.EndSearch:
    mov eax,[.AreaTopLeft]
    mov edi,[.AreaBtmRight]
    mov [ebx+WindowObj.MouseTopLeft],eax
    mov [ebx+WindowObj.MouseBtmRight],edi
    pop eax                     ;retrieve saved message
    ret

; (esi=item ptr, ax=item right, bx=item bottom)
; (; esi)
.ItemFound:
    ;object found, limit area extents to those of object found

    cmp [.AreaBtm],bx           ;if area bottom > object bottom
    jng .SkipBottom             ;  area bottom = object bottom
    mov [.AreaBtm],bx
  .SkipBottom:
    mov bx,[esi+GuiObj.Top]
    cmp [.AreaTop],bx           ;if area top < object top
    jnl .SkipTop                ;  area top = object top
    mov [.AreaTop],bx
  .SkipTop:
    cmp [.AreaRight],ax         ;if area right > object right
    jng .SkipRight              ;  area right = object right
    mov [.AreaRight],ax
  .SkipRight:
    mov ax,[esi+GuiObj.Left]
    cmp [.AreaLeft],ax          ;if area left < object left
    jnl .SkipLeft               ;  area left = object left
    mov [.AreaLeft],ax
  .SkipLeft:
    pop ebx                     ;retrieve WindowObj ptr
    DebugMessage "mouse area determined"
    jmp short .EndSearch

;컴컴컴컴컴컴컴컴컴컴
; Simply resets mouse boundaries to minimum
;
; (ebx=WindowObj ptr)
;.ResetArea:
;    mov ebx,[esp+.WinPtr]
;.ResetAreaByReg:
;    mov dword [ebx+WindowObj.MouseTopLeft], 32767|(32767<<16) ;set area ranges to minimum extents forcing the next SendMouseMsg to do an item rescan
;    mov dword [ebx+WindowObj.MouseBtmRight],32768|(32768<<16) ;so that the next call will force an item rescan
;    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Confines the mouse cursor within a specified rectangle.
; (words top, left, height, width)
; (; ebx)
ConfineCursor:
    movsx edx,word [esp+4]
    movsx ecx,word [esp+6]
    mov [Cursor.Top],edx        ;top and left are actually dwords
    mov [Cursor.Left],ecx
    add dx,[esp+8]
    add cx,[esp+10]
    movsx edx,dx
    movsx ecx,cx
    mov [Cursor.Btm],dx
    mov [Cursor.Right],cx
    ret
.Release:
%ifdef WinVer
    ; set clip ranges so large that there practically is none
    mov dword [Cursor.Top],-32768
    mov dword [Cursor.Left],-32768
    mov dword [Cursor.Btm],32767
    mov dword [Cursor.Right], 32767
    ret
%endif
.Display:                       ;(default for DOS version)
    ; set clips to screen size
    mov edx,[Display.Height]
    mov ecx,[Display.Width]
    mov dword [Cursor.Top],0
    mov dword [Cursor.Left],0
    mov [Cursor.Btm],edx        ;Screen.Height
    mov [Cursor.Right],ecx      ;Screen.Width
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Returns the absolute top/left coordinates of an item on the screen by
; summing all the relative offsets of its containers. This routine assumes
; that all containers are standard GUI items, which they SHOULD be.
;
; Used mainly to determine mouse clipping ranges and to properly places menus
; or help tips.
;
; (ebx=gui item)
; (edx=row, ecx=col; eax,ebx)
GetItemAbsPosition:
    xor edx,edx                 ;zero row
    xor ecx,ecx                 ;zero column
.Relative:
; (ebx=gui item, edx=row, ecx=col)
; (edx=row, ecx=col)
    push ebx
.Next:
    add dx,[ebx+GuiObj.Top]
    add cx,[ebx+GuiObj.Left]
    mov ebx,[ebx+GuiObj.Container]
    test dword [ebx+GuiObj.Flags],GuiObj.Null ;|GuiObj.Hidden
    jz .Next

    movsx edx,dx
    movsx ecx,cx
    pop ebx
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Grabs complete mouse focus for specified item. Usually items that already
; have focus and want to grab full focus will send this message, but items
; that don't have mouse focus can also steal it. MouseFocus changes messages
; will be sent to both the item that focus was taken away from and the one
; focus was given to (unless, of course, they are the same item).
;
; To capture and release mouse focus, this routine simply sets the mouse
; boundaries and then chains to SendMouseMsg to do the rest of the hard work
; (determining which items are affected and recalculating any new mouse
; boundaries).
;
; (eax=message|flags, dwords WindowObj ptr, item ptr)
; (cf=item could not be set)
SetMouseFocus:
;+esp
.WinPtr         equ 4           ;container ptr
.ItemPtr        equ 8           ;item to grab control of mouse (all input)

    mov ebx,[esp+.WinPtr]       ;get window data structure
    mov esi,[ebx+WindowObj.MouseItem]  ;return with current mouse focus item

    ; check if item already grabbed full focus and is releasing it
    test eax,MouseMsgFlags.Reset
    jz .Capture

;컴컴컴컴컴
.Release:
    ; set area ranges to minimum extents so that the next mouse message will
    ; force an item rescan
    DebugMessage "mouse released"
    mov dword [ebx+WindowObj.MouseTopLeft], 32767|(32767<<16) ;set area ranges to minimum extents forcing the next SendMouseMsg to do an item rescan
    ;mov dword [ebx+WindowObj.MouseBtmRight],32768|(32768<<16)
    test eax,MouseMsgFlags.SetContainer
    jz .FocusChange
    ;jmp short .ChainContainer

;컴컴컴컴컴
.ChainContainer:
    push ebx
    mov ebx,[ebx+GuiObj.Container]
    test dword [ebx+GuiObj.Flags],GuiObj.Null
    jnz .LastContainer
    push ebx
    call [ebx+GuiObj.Code]
    pop esi                     ;discard ptr
.LastContainer:
    pop ebx
    ret

;컴컴컴컴컴
.Capture:
    ; check item validity
    DebugMessage "mouse captured"
    mov esi,[esp+.ItemPtr]
    test dword [esi+GuiObj.Flags],GuiObj.NoMouseFocus|GuiObj.Disabled|GuiObj.Null
    jnz near .Err

    ; set new item & area ranges to maximum
    xchg [ebx+WindowObj.MouseItem],esi  ;swap old item with new
    mov dword [ebx+WindowObj.MouseTopLeft], 32768|(32768<<16)
    mov dword [ebx+WindowObj.MouseBtmRight],32767|(32767<<16)
    test eax,MouseMsgFlags.SetContainer
    jnz .ChainContainer

;컴컴컴컴컴
; check if focus change messages are necessary
;
; (eax=msg, ebx=WindowObj ptr)
.FocusChange:
    ;test eax,MouseMsgFlags.Silent
    ;jnz .Silent
    ; switch mouse focus from old item to new
    cmp [ebx+WindowObj.MouseItem],esi ;check if new item is the same as previous one
    je .Silent                  ;new item and old are the same
    test dword [ebx+GuiObj.Flags],GuiObj.MouseFocus
    jz .Silent

    call GetItemAbsPosition
    neg ecx
    neg edx
    add edx,[Cursor.Row]        ;set coordinates relative to item's top/left
    add ecx,[Cursor.Col]

    ; deactivate old item and activate new one
    mov eax,Msg.MouseOut
    xor edi,edi                 ;clear focus
    push edx                    ;save row
    push ecx                    ;save col
    call .SendMsg               ;send mouse focus out message to old item
    pop ecx
    pop edx
    mov eax,Msg.MouseOut|MouseMsgFlags.SetItem
    mov ebx,[esp+.WinPtr]       ;get container data structure
    mov edi,GuiObj.MouseFocus   ;set focus
    mov esi,[ebx+WindowObj.MouseItem]
    jmp .SendMsg                ;send mouse focus in message to new item
    ;clc ;Focus returns cf=0
    ;ret

.Err:
    stc
.Silent: ;(cf=0)
    ret

;컴컴컴컴컴
; Updates flags appropriately before sending mouse focus changes
;
; (ebx=WindowObj ptr,
;  eax=msg,
;  esi=item ptr mouse is over,
;  edi=mouse focus flag
;  edx/ecx=row/col)
; (cf always clear; !)
.SendMsg:
    mov ebx,esi
    mov esi,[esi+GuiObj.Flags]
    test esi,GuiObj.NoMouseFocus|GuiObj.Disabled|GuiObj.Null
    jnz .Err                    ;just in case one of the flags was set between calls
    and esi,~GuiObj.MouseFocus
    or esi,edi
    mov [ebx+GuiObj.Flags],esi

    sub cx,[ebx+GuiObj.Left]    ;make coordinates relative to item
    sub dx,[ebx+GuiObj.Top]
    movsx ecx,cx
    movsx edx,dx
    push ecx                    ;column
    push edx                    ;row
    push ebx                    ;pass gui item's data structure
    call [ebx+GuiObj.Code]
    add esp,byte 12
    ;clc ;ADD clears cf
    ret


;컴컴컴컴컴컴컴컴컴컴
; Relays mouse focus changes of container to contained item under cursor.
; Depending on whether the container is gaining or losing focus, it will
; either send mouse out, or set mouse focus to whatever item is under the
; cursor and send mouse in.
;
; if container is losing focus
;   send focus out msg
; elif gaining focus
;   find new item
;   send focus in msg
; endif
;
; (eax=focus change message, dwords WindowObj ptr, mouse row, col)
; (!)
.OfActive:

.CursorRow      equ 8   ;row offset relative within container
.CursorCol      equ 12  ;column offset ...
    ; if container is losing focus
    ;   send focus out msg
    ; elif gaining focus
    ;   find new item
    ;   send focus in msg
    ; endif
    mov ebx,[esp+.WinPtr]
    mov edx,[esp+.CursorRow]
    mov ecx,[esp+.CursorCol]

    ;test dword [ebx+GuiObj.Flags],GuiObj.MouseFocus
    test eax,MouseMsgFlags.SetItem
    jnz .In

.Out:
    ;mov eax,Msg.MouseOut
    xor edi,edi
    mov esi,[ebx+WindowObj.MouseItem]
    jmp .SendMsg                ;send mouse focus out message to old item
    ;ret

.In:
    call SendMouseMsg.GetItemAt
    ;mov eax,Msg.MouseIn|MouseMsgFlags.SetItem (already set)
    mov edi,GuiObj.MouseFocus
    mov [ebx+WindowObj.MouseItem],esi  ;set new mouse item
    jmp .SendMsg                ;send mouse focus out message to old item
    ;ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Returns the current mouse focus item.
;
; (eax=message|flags, dwords WindowObj ptr, item ptr)
; (cf=0, esi=mouse focus item ptr)
GetMouseFocus:
;+esp
.WinPtr         equ 4           ;container ptr

    mov ebx,[esp+.WinPtr]       ;get window data structure
    ;test eax,MouseMsgFlags.Specified
    ;jz .Capture
    mov esi,[ebx+WindowObj.MouseItem]  ;return with current mouse focus item
    clc
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Creates item in container. Sets item's container to the container it was
; created in. Set's item's list index. Sets layer order if requested.
;
; Only layer order and key order are shifted. No item indexes are changed in
; creation, so that items can depend on their list indexes always being valid.
;
; (eax=message|flags, dwords WindowObj ptr, item ptr)
; (!)
CreateItem:
;+esp
.WinPtr         equ 4           ;container ptr
.ItemPtr        equ 8           ;ptr of new item to include

    jmp SendContainerRedraw
    ;ret

.Err:
    stc
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Destroys item in container. Does not modify item in any way. Simply sets
; the item ptr to null GUI item.
;
; No item entries get shifted around, so that other item's can always depend
; on their list indexes being valid. Only the key order and layer orders are
; changed.
;
; (eax=message|flags, dwords WindowObj ptr, item ptr)
; (!)
DestroyItem:
;+esp
.WinPtr         equ 4           ;container ptr
.ItemPtr        equ 8
    ;clc (if not jb then cf=0)
.End: ;(cf=1)
    ret
.Err:
    stc
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Moves or resizes and item, adjusting the redraw area accordingly and
; resetting the mouse area if necessary.
;
; (eax=message|flags, dwords WindowObj ptr, item ptr, dummy
;  words top, left, height, width)
; (!)
MoveSizeItem:
;+esp
.WinPtr         equ 4           ;container ptr
.ItemPtr        equ 8           ;item to move
.Position       equ 16          ;top and left
.Top            equ 16
.Left           equ 18
.Size           equ 20          ;height and width
.Height         equ 20
.Width          equ 22

    mov ebx,[esp+.WinPtr]       ;get window data structure
.GivenWinPtr:
    mov esi,[esp+.ItemPtr]
    test dword [esi+GuiObj.Flags],GuiObj.Null ;|.FixedPosition
    stc                         ;in case error jump is taken
    jnz .Err

    ; add item's old position to window redraw area
    test eax,MoveSizeFlags.Invisible
    jnz .NoRedraw
    call AddItemToRedraw
.NoRedraw:

    ; reset mouse area (if the mouse if not captured) by setting range
    ; extents so that the next call will force an item rescan
    cmp dword [ebx+WindowObj.MouseTopLeft], 32768|(32768<<16)
    je .NoMouseReset
    mov dword [ebx+WindowObj.MouseTopLeft], 32767|(32767<<16) ;set area ranges to minimum extents forcing the next SendMouseMsg to rescan all items
.NoMouseReset:

    mov ecx,[esp+.Position]
    mov edx,[esp+.Size]
    cmp cx,-32768
    je .SkipTop
    mov [esi+GuiObj.Top],cx
.SkipTop:
    shr ecx,16
    cmp dx,-32768
    je .SkipHeight
    mov [esi+GuiObj.Height],dx
.SkipHeight:
    shr edx,16
    cmp cx,-32768
    je .SkipLeft
    mov [esi+GuiObj.Left],cx
.SkipLeft:
    cmp dx,-32768
    je .SkipWidth
    mov [esi+GuiObj.Width],dx
.SkipWidth:
    clc
.Err: ;(cf=1)
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Simply sets the order of an item in a container. The layer can be set to
; the very front, very back, or relative to some other item.
;
; (eax=message|flags, dwords WindowObj ptr, item ptr)
; (cf=item could not be set)
SetOrder:
;+esp
.WinPtr         equ 4           ;container ptr
.ItemPtr        equ 8           ;item to change layer order of
    mov esi,[esp+.ItemPtr]
    mov ebx,[esp+.WinPtr]       ;get window data structure
    movzx edx,word [esi+GuiObj.Idx]
    call .GetItemLayerIdx
    jc .Err

;컴컴컴컴컴컴컴컴컴컴
; (eax=flags, ebx=window data ptr, edx=item's layer index)
.ShiftItemOrder:
    test eax,LayerMsgFlags.SetItem
    jz .SioFalse
    push ebp
    push eax                    ;save msg/flags

    ; determine source and destination
    test eax,LayerMsgFlags.Reverse
    mov ebp,WindowObjItems.SizeOf
    jz .SioForward
    mov ecx,edx
    neg ebp
    test edx,edx
    jmp short .SioReverse
.SioForward:
    movzx ecx,word [ebx+WindowObj.TotalItems]
    sub ecx,edx
    dec ecx
.SioReverse:
    jle .SioUnmoveable

    ; shift items
    ; (esi=item index, edi=item list ptr, ecx=count, eax=dir inc,
    ;  edx=item's layer index)
    lea edi,[ebx+WindowObj.ItemsLayer+edx*8]
    lea esi,[edi+ebp]
    push dword [edi]            ;save first item's index
    push esi                    ;save list ptr
.SioNextItem:
    movzx edx,word [esi]
    mov eax,[ebx+WindowObj.ItemsPtr+edx*8]
    test dword [eax+GuiObj.Flags],GuiObj.FixedLayer
    jnz .SioStop
    mov [edi],dx                ;shift index
    add esi,ebp                 ;source += inc
    add edi,ebp                 ;dest += inc
    dec ecx
    jg .SioNextItem
.SioStop:
    pop ecx                     ;get starting source ptr
    pop edx                     ;retrieve first item's index
    cmp ecx,esi                 ;ending source ptr = starting source ptr?
    je .SioUnmoveable           ;no shift happened
    mov [edi],dx                ;replace last item's index with first item's

    ; redraw item whose layer changed
    mov esi,[esp+.ItemPtr+8]
    or dword [esi+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.RedrawForced
    ;;call AddItemToRedraw
    call SendContainerRedraw.Partial

.SioUnmoveable:
    pop eax                     ;retrieve msg/flags
    pop ebp
.SioFalse:

;컴컴컴컴컴컴컴컴컴컴
    ;test eax,LayerMsgFlags.SetContainer
    ;jnz near SendContainerMsg
      ;(cf=0)
.Err: ;(cf=1)
    ret

;컴컴컴컴컴컴컴컴컴컴
; Searches through layer order list to find an item and returns its layer
; index. Since the order is dynamic and physical item order may be different
; from layer order, this function is needed to find it.
;
; (edx=item index, ebx=container data)
; (edx=layer index, cf=error; eax,ebx)
.GetItemLayerIdx: ;public
    movzx ecx,word [ebx+WindowObj.TotalItems]
    lea esi,[ebx+WindowObj.ItemsLayer-8+ecx*8]  ;start at last item
    cmp edx,ecx                 ;item index >= items
    jae .GiiErr
    dec ecx

.GiiNext:
    cmp word [esi],dx
    je .GiiEnd                  ;found item's tab index
    sub esi,byte WindowObjItems.SizeOf
.GiiFirst:
    dec ecx
    jge .GiiNext                ;loop while count-- >= 0
.GiiErr:
    mov edx,-1                  ;not found, so return -1
    stc
    ret

.GiiEnd:
    mov edx,ecx
    ;clc (if je then cf should already be clear)
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Modifies a contained item's flags, responding accordingly to the requested
; change. For example:
;
; -If an item hides itself, the area behind that item is
;  redrawn.
; -If an item becomes disabled, mouse focus is force released.
; -If an item can't receive key focus anymore, key focus is force released
;
; (eax=message|flags, dwords WindowObj ptr, item ptr, dummy, newflags)
; (cf=item's return value; !)
SetItemFlags:
;+esp
.WinPtr         equ 4           ;container ptr
.ItemPtr        equ 8           ;item to change layer order of
.Flags          equ 16
    mov edi,[esp+.Flags]
    mov esi,[esp+.ItemPtr]
    mov ebx,[esp+.WinPtr]       ;get window data structure
    push edi                    ;save new flags
    xor edi,[esi+GuiObj.Flags]
    push edi                    ;save changed flags
    and edi,[esp]               ;get set flags

    test edi,GuiObj.NoMouseFocus|GuiObj.Null|GuiObj.Disabled
    jz .MouseSame
    cmp [ebx+WindowObj.MouseItem],esi
    jne .MouseSame
    mov dword [ebx+WindowObj.MouseItem],NullGuiItem
    mov dword [ebx+WindowObj.MouseTopLeft], 32767|(32767<<16) ;set area ranges to minimum extents forcing the next SendMouseMsg to rescan all items
.MouseSame:
    ;test edi,GuiObj.NoKeyFocus|GuiObj.Null|GuiObj.Disabled
    ;jz .KeySame
    ;cmp [ebx+WindowObj.MouseItem],esi
    ;jne .MouseSame
    ;mov dword [ebx+WindowObj.FocusItem],NullGuiItem
.KeySame:
    test edi,GuiObj.Hidden|GuiObj.Null
    jz .VisibleSame
    call AddItemToRedraw
    clc
.VisibleSame:

    pop edi                     ;retrieve changed flags
    mov ebx,[esp+.ItemPtr+4]    ;get item ptr
    pop dword [ebx+GuiObj.Flags];set new flags
    mov eax,Msg.FlagsChanged
    push ebx
    call [ebx+GuiObj.Code]
    pop ebx
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Adds an item's size/position to the redraw area. Very simple, but very
; useful. Called internally, not by item code.
;
; (ebx=WindowObj ptr, esi=item ptr)
; (; ebx)
AddItemToRedraw:
    test dword [esi+GuiObj.Flags],GuiObj.Hidden|GuiObj.Null
    jnz .End
    or dword [esi+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.RedrawForced

    mov ax,[esi+GuiObj.Top]
    mov dx,[esi+GuiObj.Left]

.MergeArea:
    cmp [ebx+WindowObj.RedrawTop],ax
    jle .TopSame
    mov [ebx+WindowObj.RedrawTop],ax
.TopSame:
    add ax,[esi+GuiObj.Height]
    cmp [ebx+WindowObj.RedrawLeft],dx
    jle .LeftSame
    mov [ebx+WindowObj.RedrawLeft],dx
.LeftSame:
    add dx,[esi+GuiObj.Width]
    cmp [ebx+WindowObj.RedrawBtm],ax
    jge .BtmSame
    mov [ebx+WindowObj.RedrawBtm],ax
.BtmSame:
    cmp [ebx+WindowObj.RedrawRight],dx
    jge .RightSame
    mov [ebx+WindowObj.RedrawRight],dx
.RightSame:

    jmp SendContainerRedraw.Partial

.End:
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; The routines below send redraw messages to the contained items in a window
; or frame. There are three possible cases where an item needs to redraw
; itself. One, the item simply needs to redraw something itself (perhaps a
; new list item was selected), the item should completely redraw itself
; (total refresh because the list contents were totally changed), or the
; redrawing of some other overlapping (or underlapping) forces the item to
; redraw part or all of itself.
; 
; Clipping is already set for the items before calling, so the they do not
; need to worry about anything but calling the graphics routines to render
; themselves. Additionally, the redraw area variables are set, telling them
; what actually needs to be redrawn. This is ignored by small items, but
; larger ones (with slow redrawing) or subcontainers use this.
;
; Since items may not redraw their entire screen space (they might only
; redraw the portion of themselves that needs redrawing), they may return
; the area actually drawn. This is added to the accumulated redrawn area of
; the window, which will be returned to the window's container. Note this
; routine does NOT restore the screen clips to their original state, so that
; it can return that redraw area information in them.
;
; Any redrawing of the background window must be done by the container before
; this routine is called, since foreground items have to be drawn afterwards
; to appear in front of their container window.
;
; Rather than save all the clips before redrawing each item, clipping to the
; item, and then restoring the clips, it only saves the clips once. Then, for
; each item, the clipping is calculated from already stack saved clips.
;
; (dword WindowObj ptr, [Display.Clips],[Display.Redraws])
; (cf=0; !)
%if 0
SendRedrawMsgs:
    mov ebx,[esp+4]             ;get window data structure
.GivenWinPtr: ;(ebx=win ptr)
    test [ebx+GuiObj.Flags],GuiObj.RedrawComplex
    jnz near SendRedrawComplex.GivenWinPtr
    ; fall through
%endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Sends redraw messages to items within a window. This simpler, slightly
; faster routine, is intended only for simple windows like dialog boxes where
; all the items maintain their own screen spaces in the same layer and none
; overlap. It's faster because it doesn't redraw items in higher layers that
; were affected by drawing in a lower layer, because such a thing should
; never happen if all the items have their own separate areas.
;
; (dword WindowObj ptr, [Display.Clips],[Display.Redraws])
; (cf=0; !)
SendRedrawSimple:
    ; save clips of entire container
    ; save clips of only redraw area
    ; count item from first to last
    ;   if item is visible & needs redrawn
    ;     if item needs completely redrawn
    ;       set clips to max item extents
    ;       set redraw area to max item extents
    ;     elif item is within the area redrawn
    ;       set item's redraw forced flag
    ;       if item already needed to be redrawn
    ;         set clips to item extents (merged with container)
    ;       else
    ;         set clips within item (merged with area needing redrawing)
    ;         set redraw area to clips
    ;       endif
    ;     elif item needs to be redrawn
    ;       set clips to item (merged with container)
    ;       set redraw area empty
    ;     else
    ;       skip to next item
    ;     endif
    ;     send Redraw
    ;     clear redraw flags of item
    ;     add area of redrawn object to total area
    ;   endif
    ; next item
    ; restore clips
    ; set area redrawn to total area actually redrawn

;+ebp
.WinPtr         equ 8           ;container ptr
%define .WholeClipSet   -SavedClips.SizeOf
%define .PartialClipSet -(SavedClips.SizeOf*2)
%define .AccumClipSet   -(SavedClips.SizeOf*3)

    mov ebx,[esp+4]             ;get window data structure
.GivenWinPtr: ;(ebx=win ptr)
    push ebp
    mov ebp,esp

    ; depending on whether the window needed to be redrawn because an item
    ; inside requiring it or because some other window's drawing overlapped,
    ; either just set the window's redraw area (an internal rectangle defining
    ; which items within the window should be redrawn) or merge the window's
    ; redraw area with any its own container's may have.

    ; make two initial clip sets
    call SaveClips              ;save window's maximum clips
    ;test [ebx+GuiObj.Flags],GuiObj.RedrawBg
    ;jz .NoAreaMerge             ;no need, since entire window needs redrawing
    lea esi,[ebx+WindowObj.RedrawBounds]
    test dword [ebx+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.RedrawForced
    mov eax,SetRedrawArea       ;just set the redraw area to window's (since container does not have an intersecting one)
    jz .SetArea
    mov eax,OrRedrawArea        ;combine the two redraw areas
.SetArea:
    call eax
    call AndClips.RedrawToDisplay ;intersect redraw area with clips
;.NoAreaMerge:
    call SaveClips              ;save again for window's redraw area clips
    call SaveClips              ;save once more for window's accumulated redrawn area

%if 0
    ; scan all items for bg redraw flag and add (merge) them to redraw area
    movzx ecx,word [ebx+WindowObj.TotalItems]
    lea edi,[ebx+WindowObj.ItemsPtr]
    jmp short .ChkFirstBg
.ChkNextBg:
    mov esi,[edi]
    test dword [esi+GuiObj.Flags],GuiObj.RedrawBg
    jz short .SkipBgChk
    ;call AddItemToRedraw
.SkipBgChk:
    add esi,byte WindowObjItems.SizeOf
.ChkFirstBg:
    dec ecx
    jns .ChkNextBg
%endif

    movzx ecx,word [ebx+WindowObj.TotalItems]
    lea esi,[ebx+WindowObj.Items]
    push ecx
    jmp .FirstItem

;컴컴컴컴컴컴컴컴컴�
; (esi=item list ptr)
.NextItem:
    mov ebx,[esi]               ;get item ptr
    mov eax,[ebx+GuiObj.Flags]
    test eax,GuiObj.Hidden|GuiObj.Null
    jnz near .ItemHidden
    push esi                    ;save item list ptr

    test eax,GuiObj.RedrawBg
    lea esi,[ebp+.WholeClipSet] ;entire container
    jz .PartialRedraw
    call SetGuiItemClips
    call CopyClips.DisplayToRedraw
    jmp short .Draw

; (eax=flags, ebx=item data ptr, esi=whole clip set)
.PartialRedraw:
    ; determine if item overlaps redraw area
    mov dx,[ebx+GuiObj.Top]
    mov cx,[ebx+GuiObj.Left]
    cmp [ebp+.PartialClipSet+SavedClips.ClipBtm],dx
    jle .NoOverlap              ;window redraw bottom <= item top
    add dx,[ebx+GuiObj.Height]
    cmp [ebp+.PartialClipSet+SavedClips.ClipRight],cx
    jle .NoOverlap              ;window redraw right <= item left
    add cx,[ebx+GuiObj.Width]
    cmp [ebp+.PartialClipSet+SavedClips.ClipTop],dx
    jge .NoOverlap              ;window redraw top >= item bottm
    cmp [ebp+.PartialClipSet+SavedClips.ClipLeft],cx
    jge .NoOverlap              ;window redraw left >= item right
    ; it does overlap, so it must be redrawn

    or dword [ebx+GuiObj.Flags],GuiObj.RedrawForced
    test eax,GuiObj.Redraw
    jnz .RedrawAlreadySet
    lea esi,[ebp+.PartialClipSet] ;redraw area within container
    call SetGuiItemClips
    call CopyClips.DisplayToRedraw
    jmp short .Draw

; (ebx=item data ptr, esi=full clip set)
.RedrawAlreadySet:
    call SetGuiItemClips
    lea esi,[ebp+.PartialClipSet] ;redraw area within container
    call SetGuiItemRedraw
    jmp short .Draw

; (eax=flags, ebx=item data ptr, esi=clip ptr)
.NoOverlap:
    test eax,GuiObj.Redraw
    jz .SkipItem
    call SetGuiItemClips
    call EmptyClips.Redraw

;컴컴컴컴컴컴컴컴컴�
; (ebx=item ptr)
.Draw:
    ; draw item, then add item's redraw bounds to accumulated area
    push ebx
    mov eax,Msg.Redraw
    call [ebx+GuiObj.Code]
    DrawItemOverlay
    pop ebx                     ;get item data ptr
%ifdef UseDisplayBuffer
    test dword [ebx+GuiObj.Flags],GuiObj.RedrawHandled
    jnz .RedrawHandled
    call AddClipsToRedrawRange
.RedrawHandled:
%endif
    call OffsetGuiClips
    lea edi,[ebp+.AccumClipSet]
    call OrClips.FromDisplay
.NoItemMerge:

%if ~GuiDebugMode & 4
    and dword [ebx+GuiObj.Flags],~GuiObj.Redraw
%endif

;컴컴컴컴컴컴컴컴컴�
.SkipItem:
    pop esi                     ;retrieve item list ptr
.ItemHidden:
    add esi,byte WindowObjItems.SizeOf
.FirstItem:
    dec dword [esp]
    jns near .NextItem

;컴컴컴컴컴컴컴컴컴�
    ; restore original clips & pass back dimensions of area actually redrawn
    ; (ebx=window data)
    pop ecx                     ;discard counter
    call RestoreClips           ;restore second clip set for return to caller
    mov edi,[ebp+.WinPtr]
    mov dword [edi+WindowObj.RedrawTopLeft],32767|(32767<<16)
    mov dword [edi+WindowObj.RedrawBtmRight],(-32768 & 65535)|(-32768<<16)

    mov esp,ebp
    pop ebp
    clc
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Sends redraw messages to top layer windows. This more advanced version is
; designed to handle multiple, layered, overlapping windows which may all
; contain items within themselves. When layer order matters, this routine
; uses the painters algorithm, so items must be drawn from back to front.
; This forces any items to be redrawn that are in front of other items that
; need redrawing.
;
; (dwords WindowObj ptr, [Display.Clips],[Display.Redraws])
; (cf=0; !)
SendRedrawComplex:
    ;<summary>
    ; save window clips
    ; combine window redraw area with its container's redraw area
    ; draw all items
    ;   preclip for item
    ;   redraw item (send it a message)
    ;   or item's redrawn area to accumulated window redraw
    ; loop
    ; return clips to container
    ;
    ;<less summarized>
    ; save clips of entire container
    ; save clips of only redraw area
    ; count item from first to last
    ;   get next zlayer
    ;   get item at current layer
    ;   if item is visible
    ;     if item needs completely redrawn
    ;       set clips to max item extents
    ;       set redraw area to max item extents
    ;     elif item is within the area redrawn
    ;       set item's redraw forced flag
    ;       if item already needed to be redrawn
    ;         set clips to item extents (merged with container)
    ;       else
    ;         set clips within item (merged with area needing redrawing)
    ;         set redraw area to clips
    ;       endif
    ;     elif item needs to be redrawn
    ;       set clips to item (merged with container)
    ;       set redraw area empty
    ;     else
    ;       skip to next item
    ;     endif
    ;     send Redraw
    ;     clear redraw flags of item
    ;     add area of redrawn object to total area
    ;   endif
    ; next item
    ; restore clips
    ; return total area actually redrawn

;+ebp
.WinPtr         equ 8           ;container ptr
%define .WholeClipSet   -SavedClips.SizeOf
%define .PartialClipSet -(SavedClips.SizeOf*2)


    mov ebx,[esp+4]             ;get window data structure
.GivenWinPtr: ;(ebx=win ptr)
    push ebp
    mov ebp,esp

    ; depending on whether the window needed to be redrawn because an item
    ; inside requiring it or because some other window's drawing overlapped,
    ; either just set the window's redraw area (an interal rectangle defining
    ; which items within the window should be redrawn) or merge the window's
    ; redraw area with any its own container's may have.

    ; make two initial clip sets
    call SaveClips              ;save window's maximum clips
    ;test [ebx+GuiObj.Flags],GuiObj.RedrawBg
    ;jz .NoAreaMerge             ;no need, since entire window needs redrawing
    lea esi,[ebx+WindowObj.RedrawBounds]
    test dword [ebx+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.RedrawForced
    mov eax,SetRedrawArea       ;just set the redraw area to window's (since container does not have an intersecting one)
    jz .SetArea
    mov eax,OrRedrawArea        ;combine the two redraw areas
.SetArea:
    call eax
    call AndClips.RedrawToDisplay ;intersect redraw area with clips
;.NoAreaMerge:
    call SaveClips              ;save once more for window's redraw area clips

    movzx ecx,word [ebx+WindowObj.TotalItems]
    ;lea esi,[ebx+WindowObj.Items+ecx*8-WindowObjItems.SizeOf] ;(for drawing reverse order)
    lea esi,[ebx+WindowObj.Items]
    push ecx
    jmp .FirstItem

;컴컴컴컴컴컴컴컴컴�
; (esi=item list ptr)
.NextItem:
    movzx edx,word [esi+WindowObjItems.Layer]
    mov edi,[ebp+.WinPtr]       ;get window data structure
    mov ebx,[edi+WindowObj.ItemsPtr+edx*8]
    mov eax,[ebx+GuiObj.Flags]
    test eax,GuiObj.Hidden|GuiObj.Null
    jnz near .ItemHidden
    push esi                    ;save item list ptr

    test eax,GuiObj.RedrawBg
    lea esi,[ebp+.WholeClipSet] ;entire container
    jz .PartialRedraw
    call SetGuiItemClips
    call CopyClips.DisplayToRedraw
    jmp short .Draw

; (eax=flags, ebx=item data ptr, esi=whole clip set)
.PartialRedraw:
    ; determine if item overlaps redraw area
    mov dx,[ebx+GuiObj.Top]
    mov cx,[ebx+GuiObj.Left]
    cmp [ebp+.PartialClipSet+SavedClips.ClipBtm],dx
    jle .NoOverlap              ;window redraw bottom <= item top
    add dx,[ebx+GuiObj.Height]
    cmp [ebp+.PartialClipSet+SavedClips.ClipRight],cx
    jle .NoOverlap              ;window redraw right <= item left
    add cx,[ebx+GuiObj.Width]
    cmp [ebp+.PartialClipSet+SavedClips.ClipTop],dx
    jge .NoOverlap              ;window redraw top >= item bottm
    cmp [ebp+.PartialClipSet+SavedClips.ClipLeft],cx
    jge .NoOverlap              ;window redraw left >= item right
    ; it does overlap, so it must be redrawn

    or dword [ebx+GuiObj.Flags],GuiObj.RedrawForced
    test eax,GuiObj.Redraw
    jnz .RedrawAlreadySet
    lea esi,[ebp+.PartialClipSet] ;redraw area within container
    call SetGuiItemClips
    call CopyClips.DisplayToRedraw
    jmp short .Draw

; (ebx=item data ptr, esi=full clip set)
.RedrawAlreadySet:
    call SetGuiItemClips
    lea esi,[ebp+.PartialClipSet] ;redraw area within container
    call SetGuiItemRedraw
    jmp short .Draw

; (eax=flags, ebx=item data ptr, esi=full clip set)
.NoOverlap:
    test eax,GuiObj.Redraw
    jz .SkipItem
    call SetGuiItemClips
    call EmptyClips.Redraw

;컴컴컴컴컴컴컴컴컴�
; (ebx=item ptr)
.Draw:
    ; draw item, then add item's redraw bounds to accumulated area
    push ebx
    mov eax,Msg.Redraw
    call [ebx+GuiObj.Code]
    DrawItemOverlay
    pop ebx                     ;get item data ptr
%ifdef UseDisplayBuffer
    test dword [ebx+GuiObj.Flags],GuiObj.RedrawHandled
    jnz .RedrawHandled
    call AddClipsToRedrawRange
.RedrawHandled:
%endif
    ;test dword [ebx+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.RedrawForced
    ;jz .NoItemMerge
    call OffsetGuiClips
    lea edi,[ebp+.PartialClipSet]
    call OrClips.FromDisplay
.NoItemMerge:
%if ~GuiDebugMode & 4
    and dword [ebx+GuiObj.Flags],~GuiObj.Redraw
%endif

;컴컴컴컴컴컴컴컴컴�
.SkipItem:
    pop esi                     ;retrieve item list ptr
.ItemHidden:
    ;sub esi,byte WindowObjItems.SizeOf ;(for drawing reverse order)
    add esi,byte WindowObjItems.SizeOf
.FirstItem:
    dec dword [esp]
    jns near .NextItem

;컴컴컴컴컴컴컴컴컴�
    ; restore original clips & pass back dimensions of area actually redrawn
    ; (ebx=window data)
    pop ecx                     ;discard counter
    call RestoreClips           ;restore second clip set for return to caller
    mov edi,[ebp+.WinPtr]
    mov dword [edi+WindowObj.RedrawTopLeft],32767|(32767<<16)
    mov dword [edi+WindowObj.RedrawBtmRight],(-32768 & 65535)|(-32768<<16)
    ;add esp,byte SavedClips.SizeOf ;release first clip set

    mov esp,ebp
    pop ebp
    clc
    ret


%if 0 ;before drawing
    nop
    nop
    nop
    pusha

    ;mov ebx,[ebp+.WinPtr]
    ;push dword Screen.Width|(11<<16)
    ;push dword [ebx+GuiObj.Size]
    ;and dword [esp],0000FFFFh
    ;dec dword [esp]
    ;push dword Screen.Width|(10<<16)
    ;push dword 0
    ;call DrawHline
    ;add esp,byte 8
    ;call DrawHline
    ;add esp,byte 8

    mov ebx,[ebp+.WinPtr]
    push dword Screen.Width|(13<<16)
    push dword [Display.RedrawBtm]
    and dword [esp],0000FFFFh
    dec dword [esp]
    push dword Screen.Width|(12<<16)
    push dword [Display.RedrawTop]
    and dword [esp],0000FFFFh
    call DrawHline
    add esp,byte 8
    call DrawHline
    add esp,byte 8

    mov ebx,[ebp+.WinPtr]
    push dword Screen.Height|(11<<16)
    push dword [Display.RedrawRight-2]
    and dword [esp],0FFFF0000h
    dec dword [esp]
    push dword Screen.Height|(10<<16)
    push dword [Display.RedrawLeft-2]
    and dword [esp],0FFFF0000h
    call DrawVline
    add esp,byte 8
    call DrawVline
    add esp,byte 8

    popa
    nop
    nop
    nop
%endif

%if 0 ;after drawing
    nop
    nop
    nop
    mov ebx,[esp+4]             ;get window data structure
    push dword Screen.Width|(9<<16)
    push dword [Display.ClipBtm]
    and dword [esp],0000FFFFh
    dec dword [esp]
    push dword Screen.Width|(8<<16)
    push dword [Display.ClipTop]
    and dword [esp],0000FFFFh
    ;call DrawHline
    add esp,byte 8
    ;call DrawHline
    add esp,byte 8
    nop
    nop
    nop
%endif
