;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Core GUI functions
; Reading mouse and key input, redrawing items, sending misc messages...
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
; SendContainerMsg              sends message to item's container
; ChainContainerMsg             same but does not return to caller
; SendOwnerMsg                  sends message to item's owner
; SendMsgAllItems               passes single message to all contained items
; IgnoreMsg                     default jump handler for unknown messages
; AckMsg                        simply clears carry and returns
;
; SetItemFocus                  sets active item/group/container
; SetItemFocus.GetItemKeyIdx    returns key tab index of specific item
; SetItemFocus.OfActive         sets focus of all contained items
; GetItemFocus                  get current focus item
;
; SetKeyboardHandler            set keyboard interrupt handler (DOS version)
; RestoreKeyboardHandler        restores keyboard interrupt (DOS version)
; GuiKeyboardHandler            keyboard interrupt handler (only DOS version)
; GetKeyboardMsg                gets BIOS keypress info
; ScanForKey                    scans list for matching keypress
;
; GetMouseMsg                   reads mouse driver info (buttons, position)
;
; CreateItem                    adds item to container
; DestroyItem                   removes item from container
;
; SendTimeMsgs                  sends timed event messages to items
; TimerHandler                  timer interrupt handler (only DOS version)
; CreateTimer                   adds item to main timer list
; DestroyTimer                  removes item from main timer list
;
; GuiErrMsgEnd                  display fatal error message
; ShellCmdPrompt                shells to command prompt
;
; Registers:
;   Many of these routines use specific registers to:
;     eax - hold the sent message and additional message flags
;     ebx - point to the GUI item's container
;     ecx - generic counter
;     edx - hold an item's index
;     esi - point to the GUI item in it's container's list
;   Most parameters are passed by stack, but some routines use eax & ebx
;   passed to it by a GUI item. Most of the routines do not save the common
;   registers; however, many save ebx as a convenience.
;
; Typical Gui Loop:
;
; call all necessary program init routines (screen mode set, heap alloc...)
;
; startloop
;  ùall keyboard and mouse input must pass down through a heirarchy, they can
;   not go directly to objects without passing by the containers.
;  ùget keyboard input
;  ùpass down to main windows
;      ùlet window decide what to do (depending on what type of window and
;       where it was clicked).
;      ùcall code associated with window to inform of key input, where the
;       procedure can either dole out the input based on which group is
;       selected or return to allow the window code to pass input to the
;       active object. If the procedure took care of it, it should return
;       no error (indicated by clear carry flag).
;      ùif the previous keypress was Tab or Shift+Tab, a key focus
;       message is received here.
;  ùloop while more key input
;
;  ùget mouse input
;  ùpass down to main windows
;      ùlet window decide what to do (depending on what type of window and
;       where it was clicked)
;      ùcall code associated with window to inform of mouse input.
;      ùpass click/move/enter/exit to objects, which can passed directly or
;       broken down into enter/exit combinations. Movement indicates that no
;       clicks (presses or releases) occurred, just a change in mouse
;       position. Clicks, however, can combine movement with button presses
;       or releases. Enters should also be considered movement and can also
;       have clicks. Exits may never have clicks.
;       Some objects such as buttons only need to worry about Clicks and
;       Exits, Clicks to know when to depress the button and Exits to know if
;       the user moved off so that the depress can be canceled. Enters are
;       also paid attention to for setting cursor focus, but that is handled
;       by default code. Scroll bars need to pay attention to Clicks, Moves,
;       and Exits, clicks for the up/down arrows and scroll bar grab, Moves
;       for scroll bar drags (after being grabbed), and Exits for canceling a
;       drag.
;      ùdepending on the nature of the object, a mouse focus message
;       may be received here if the mouse was moved over a different object
;       or if one was clicked on.
;
;  ùpass timer events to processes & objects (this is the ONLY input which
;   can bypass a container directly to objects). Timer events can range from
;   seconds to minutes, or even zero time, meaning that it will be done every
;   time through the loop. Since GUI processes can be dynamic, it's better to
;   put any program routines here rather than hard code them in the main loop.
;
;  ùredraw entire GUI bypassing redraw messages to each of the main windows
;   which needs redrawing, cascading down to all of the individual objects.
;      ùhide cursor
;      ùhide any top layer objects (maybe sprites?)
;      ùstarting from the back layer, going forward, send Redraw messages
;       to any main windows needing redrawing.
;          ùscan through object list finding objects that have been affected.
;          ùsend Redraw's to all objects needing redrawing.
;          ùreturn extents actually redrawn
;      ùredraw top layer objects
;      ùshow cursor
;  ùcopy newly drawn portion of GUI to screen.
; endloop
;
; call all necessary program exit routines (screen mode reset, heap free...)
; end program

%ifndef GuiDefsInc
;Requires Gui Definitions
%include "guidefs.asm"          ;GUI messages and object definitions
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
aligndd

GuiFlags:
.Flags:			dd 0
.Active         equ 1
.Suspended      equ 2           ;either inactive or message box displayed
.InMenu         equ 4           ;popup menu is open (usually system menu)

;GuiStyle:       dd 0
;.Peekin         equ 0           ;my personal favorite - no surprise
;.ZSNES          equ 1           ;my favorite emulator
;.Win3x          equ 2           ;good old 3.11
;.Win4x          equ 4           ;Windows classic (95/98/2k)
;.WinXP          equ 5           ;just for completeness, though XP is ugly
;.MacOs          equ 6           ;oh, why not stick this in here too
;! These have been removed in favor of style files

; Since function pointers in this GUI must NEVER be null, this null item can
; be used whenever an item, process, or owner needs to be set to nothing.
; Function pointers must always point to valid code, even it is simply a
; do-nothing return routine that ignores all messages. That way, the caller
; does not need to check for a null pointer every call of its owner.
;
; A few uses of it:
; - When the cursor is over no items.
; - When items are removed from a container.
; - An item has no owner.
; - An item that has no container (the main window at top of the heirarchy)
                dd -1                   ;invalid container index
                dd GuiObj.Null|GuiObj.NoKeyFocus|GuiObj.NoMouseFocus|GuiObj.Hidden|GuiObj.Disabled|GuiObj.NotFullFocus|GuiObj.Redraw|GuiObj.FixedLayer|GuiObj.FixedPosition|GuiObj.FewOwnerMsgs
                dd NullGuiItem          ;top level has no container
                dd -1                   ;no owner callback (intentionally cause GPF if attempted)
                dd IgnoreMsg            ;item message handler (or intercepting code)
                ;DefGuiObj NullGuiItem,IgnoreMsg,NullGuiItem,GuiObj.Null|GuiObj.NoKeyFocus|GuiObj.NoMouseFocus|GuiObj.Hidden|GuiObj.Disabled, 0,0,0,0
NullGuiItem:

Keyboard:       aligndd
.LastMsg:       dd 0
.LastVkCode equ .LastMsg+1
.Buttons:       dd 0,0,0,0,0,0,0,0
%ifdef DosVer
.HandlerOfs:    dd 0            ;previous keyboard handler's offset
.HandlerSel:    dd 0            ;and its selector
.HeadIdx:       dd 0
.TailIdx:       dd 0
section bss
.BufferSize     equ 64
.Buffer:        resb .BufferSize
section data
.ScToVkc:       incbin "..\gui\vkc.dat",0,128   ;scancodes to virtual keycodes
.AsciiToAnsi    incbin "..\gui\vkc.dat",128,128 ;remap BIOS/KEYB chars
%endif

Mouse:          aligndd
.RowDif:        dd 0            ;pixel change, ignoring clipping
.ColDif:        dd 0
%ifdef DosVer
.RowFine:       dd 0            ;motion counter change in mickeys
.ColFine:       dd 0
%endif
.Buttons:                       ;dword of buttons
.Down:          db 0            ;buttons currently down
.Pressed:       db 0            ;pressed since last call
.Released:      db 0, 0         ;released since last call
.LastClick:     dd -1>>1
.LeftDown       equ 00001h
.RightDown      equ 00002h
.MiddleDown     equ 00004h
.LeftPress      equ 00100h
.RightPress     equ 00200h
.MiddlePress    equ 00400h
.LeftRelease    equ 10000h
.RightRelease   equ 20000h
.MiddleRelease  equ 40000h
.ClickTime:     dd 0
%ifdef WinVer
.hwnd:          dd 0
%elifdef DosVer
.NumButtons:    dd 0            ;some mouse drivers report 3 when the mouse really only has 2?
%endif                          ;>=0 also indicates the presence of a mouse (else zero if no driver)

Timer:
.Now:           dd 0            ;current time, updated each frame (or each timer message)
.Next:          dd -1>>1        ;time of next event (soonest timed item)
.TotalItems:    dd 0            ;total timed items
%ifdef DosVer
.HandlerOfs:    dd 0            ;previous timer handler's offset
.HandlerSel:    dd 0            ;and its selector
.IntAccum:      dd 0            ;accumulator to chain timer interrupt
%endif
section bss
.Items:         resd Timer.MaxItems*TimerObj_size

section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sends message to item's container. It puts the container's object ptr on the
; stack, then jumps to its code entry point. The rest of the parameters are 
; already assumed to be on the stack.
;
; ! Only called from asm code, not C code.
; ! Does not pop container's ptr off stack. Caller is expected to do that when
;	it removes the other parameters it put on.
;
; (ebx=sending item's gui ptr, [parameters on stack])
; (eax=container return value; maybe other regs from container)
SendContainerMsg:
	push dword [esp]				;duplicate return address
	mov eax,[ebx+GuiObj.Container]	;get ptr to item's container
	mov dword [esp+4],eax			;pass container's data structure
	jmp dword [eax+GuiObj.Code]

    ;lea esp,[esp+4]				;do not affect carry or any other registers
    ;ret

	;!	Does not pop container's ptr off stack
	;	Caller is expected to remove this additional dword when it removes
	;	the other parameters it pushed on.


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sends message to item's owner. It puts the owner's object ptr on the
; stack, then jumps to its code entry point. The rest of the parameters are 
; already assumed to be on the stack.
;
; ! Only called from asm code, not C code.
; ! Does not pop container's ptr off stack. Caller is expected to do that when
;	it removes the other parameters it put on.
;
; (ebx=sending item's gui ptr, [parameters on stack])
; (eax=owner return value; maybe other regs from owner)
SendOwnerMsg:
    test dword [ebx+GuiObj.Flags],GuiObj.FewOwnerMsgs
    jz .Important
    cmp byte [esp+4],255			;only important messages
    jc .Ignore
.Important:
	mov eax,[ebx+GuiObj.Owner]		;get ptr to item's container
	push dword [esp]				;duplicate return address
	mov dword [esp+4],eax			;pass container's data structure
	jmp dword [eax+OwnerCallbackObj.Code]

    ;lea esp,[esp+4]				;do not affect carry or any other registers
    ;ret

	;!	Does not pop container's ptr off stack
	;	Caller is expected to remove this additional dword when it removes
	;	the other parameters it pushed on.

.Ignore: ;(cf=1)
	sub esp,byte 4
	mov eax,-1
	stc ;redundant?
	jmp [esp+4]


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Simple function that sends a generic messages to all items in a container.
;
; (eax=message, dword item data)
; (!)
SendMsgAllItems:
    mov ebx,[esp+4]

.GivenWinPtr:
    push eax                    ;save msg
    movzx ecx,word [ebx+WindowObj.TotalItems]
    lea esi,[ebx+WindowObj.ItemsPtr]
    push ecx                    ;save item count in container
    jmp short .Start
.Next:
    push esi                    ;save container list ptr
    mov ebx,[esi]               ;get item's data ptr
    mov eax,[esp+8]             ;retrieve msg
    push ebx
    call dword [ebx+GuiObj.Code]
    pop ebx
    pop esi                     ;retrieve container list ptr
    add esi,byte WindowObjItems.SizeOf
.Start:
    dec dword [esp]
    jge .Next
    add esp,byte 8
    ;clc ;ADD clears cf
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Default routine for messages that do not have a owner/handler. Carry is set
; to indicate that the message was not handled or was ignored. At first
; glance, it looks pointless, but its invaluable in jump tables.
;
; () (cf=1)
IgnoreMsg:
	mov eax,-1
    stc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Simply clears carry and returns.
;
; () (cf=0)
AckMsg:
    clc
    ret


%ifdef DosVer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetKeyboardHandler:
    ; save existing interrupt handler
    mov eax,0204h               ;get protected-mode interrupt
    mov bl,9                    ;keyboard interrupt
    int 31h
    mov [Keyboard.HandlerOfs],edx ;save offset
    mov [Keyboard.HandlerSel],ecx ;save selector

.SetOnly:
    ; set the GUI's handler
    mov eax,0205h               ;set protected mode interrupt
    mov ecx,cs                  ;pass our code selector
    mov edx,GuiKeyboardHandler
    mov bl,9                    ;keyboard interrupt
    int 31h
    ret
%endif


%ifdef DosVer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
RestoreKeyboardHandler:
    ; restore the BIOS keyboard vector
    mov eax,0205h               ;set protected mode interrupt
    mov edx,[Keyboard.HandlerOfs] ;get offset
    mov ecx,[Keyboard.HandlerSel] ;get selector
    mov bl,9                    ;keyboard interrupt
    int 31h
    ret
%endif


%ifdef DosVer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Intercepts keypresses before passing to the BIOS (or other interceptor).
; Although handling all character translation itself would be easy enough for
; the standard US keyboard, it quickly becomes a daunting task to support all
; the various keyboard layouts.

; Minimal routine simply reads the scancode from the keyboard, and stores the
; scancode in the buffer. Mapping the scancode to a virtual key code and
; translating keypresses into ASCII characters is done by GetKeyboardMsg.
;
; () (it's an interrupt handler, so EVERYTHING is saved)
GuiKeyboardHandler:
    ; get scancode
    ; if not extended key
    ;   if key press
    ;     chain key to BIOS (or KEYB program)
    ;     convert message
    ;     stuff into buffer
    ;     check for character
    ;     if present, stuff into buffer
    ;   else key release
    ;     convert message
    ;     stuff into buffer
    ;   endif
    ; endif

    push ds
    push eax
    push ecx
    push edx
    mov ds,dword [cs:Program.DataSelector]

    ; get scancode and use BIOS to convert to character
    in al,60h                   ;get scancode from keyboard
    mov ah,al
    cmp al,0E0h                 ;ignore dumb, unnecessary extended byte
    xchg [.LastByte],ah
    je .EatKey
    cmp ah,0E0h
    jne .NoFakeShift
    cmp al,02Ah
    je .EatKey
    cmp al,0AAh
    je .EatKey
    cmp al,036h
    je .EatKey
    cmp al,0B6h
    je .EatKey
.NoFakeShift:
    cmp al,0E1h                 ;disallow pause key
    ;je .EatKey
    jne .TranslateKey
.EatKey:
    mov al,61h                  ;specific interrupt, 1
    out 20h,al
    jmp short .End
.TranslateKey:
    pushf
    call far [Keyboard.HandlerOfs]

    ; convert scancode to virtual key code
    ; and store in buffer
    shl eax,8                   ;move scancode into upper byte (al is then 0)
    mov ecx,[Keyboard.HeadIdx]  ;get end of buffer to store new keypress/release
    ;cmp ecx,[Keyboard.TailIdx]
    ;je .IgnoreChar             ;buffer is full!
    btr eax,7+8                 ;mask off and test top press/release bit
    movzx edx,ah
   %if Msg.KeyRelease-Msg.KeyPress != 1
    %error "Key release message must follow press"
   %endif
    adc al,Msg.KeyPress
    mov ah,[Keyboard.ScToVkc+edx]
    call .AddMsg
.IgnoreKey:

    ; get waiting characters from BIOS
    movzx edx,word [41Ah]       ;get BIOS keyboard buffer head
    cmp [41Ch],dx
    je .End
    mov [41Ch],dx               ;set keyboard tail (to prevent annoying beep!)
    mov ah,[400h+edx]           ;get last character
    cmp ah,32
    jb .End
    movzx edx,ah
    mov ah,[Keyboard.AsciiToAnsi+edx]
    mov al,Msg.KeyChar
    call .AddMsg

.End:
    pop edx
    pop ecx
    pop eax
    pop ds
    iret

.AddMsg:
    mov [Keyboard.Buffer+ecx],ax
    add ecx,byte 2              ;next slot in buffer
    and ecx,Keyboard.BufferSize-1  ;wrap to front
    mov [Keyboard.HeadIdx],ecx
    ret

section data
.LastByte:  db 0
section code
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Checks keyboard buffer and returns the message if any. If no
; new keys have been pressed since the last call, carry is set.
; Sets the button bits (keys pressed) appropriately in the table.
; Translates the scancode into a virtual key code.
;
; ()
; (al=message if any, ah=scancode | cf=no new keypress; ebx)
GetKeyboardMsg:

%ifdef WinVer
    ; if key down/up
    ;   translate press/release to character
    ;   convert message
    ;   set bits in table
    ; elif character && not dead key && not control character
    ;   convert message
    ; endif

    test al,2                   ;check if press/release/character
    jnz .Char                   ;is a character

    api TranslateMessage, msg
    mov eax,Msg.KeyPress
    movzx ecx,byte [msg+MSG.wParam] ;get virtual key code
    test dword [msg+MSG.lParam],80000000h ;test transition state (up/down)
    mov ah,cl
    jnz .Release
.Press:
    ; determine if first press or repeat of key
    bts [Keyboard.Buttons],ecx
    jnc .FirstPress
    or eax,KeyMsgFlags.Repeat
.FirstPress: ;(cf=0)
    mov [Keyboard.LastMsg],eax
    ;clc
    ret

.Release:
    mov al,Msg.KeyRelease
    btr [Keyboard.Buttons],ecx
    mov [Keyboard.LastMsg],eax
    clc
    ret

.Char: ;(eax=windows key msg)
    test al,1                   ;check if dead key
    jnz .Ignore                 ;ignore if so
    mov eax,Msg.KeyChar
    mov ah,byte [msg+MSG.wParam] ;get character
    cmp ah,32
    jb .Ignore
    mov [Keyboard.LastMsg],eax  ;valid character
    ;clc
    ret

.Ignore:                        ;do NOT pass control characters (confuses items)
    stc
    ret

%else

 %if 0 ;display keyboard buffer DEBUG
    cld
    mov ah,07Ah
    mov esi,Keyboard.Buffer
    mov edi,0B8000h+(160*2)
    mov ecx,Keyboard.BufferSize
.Next:
    lodsb
    stosw
    loop .Next
 %endif

    ; if tail != head
    ;   key = buffer[tail]
    ;   if key down/up
    ;     set bits in table
    ;   elif character
    ;     return
    ;   endif
    ; endif

    mov ecx,[Keyboard.TailIdx]  ;get front of buffer to read any new keypress/release
    cmp ecx,[Keyboard.HeadIdx]
    stc
    je .Done                    ;buffer is empty

    movzx eax,word [Keyboard.Buffer+ecx]
    add ecx,byte 2              ;next slot in buffer
    and ecx,Keyboard.BufferSize-1  ;wrap to front
    mov [Keyboard.TailIdx],ecx
    mov [Keyboard.LastMsg],eax

  %ifdef DosVer
  %if 0
    push eax
    mov edi,NumToString.Buffer
    mov ebx,16
    mov ecx,4
    call NumToString.UseDLRadix
    mov edx,NumToString.Buffer
    mov byte [NumToString.Buffer+4],byte 0
    call WriteString
    pop eax
  %endif
  %endif

    cmp al,Msg.KeyChar
    je .Done
    movzx edx,ah
    cmp al,Msg.KeyPress
    jne .Release

.Press:
    ; determine if first press or repeat of key
    bts [Keyboard.Buttons],edx
    jnc .FirstPress
    or eax,KeyMsgFlags.Repeat
.FirstPress: ;(cf=0)
    ;clc (OR does this)
.Done: ;(cf=1/0)
    ret

.Release:
    btr [Keyboard.Buttons],edx
    clc
    ret

%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Scans through a list of key presses/releases or characters and returns the
; index matching the keycode given, or error if it wasn't found. Simply pass
; the keycode or character (which is in ah of a keyboard message) and a scan
; structure to it, which contains a list of single key presses, key releases,
; or even multi-key combinations.
;
; Format of a key scan structure:
;   byte: key flags
;   byte: virtual keycode
;   byte: key flags
;   byte: virtual keycode
;   [...]
;   byte: key flags (-1 to end list)
;
; Key bit flags:
;   0 = key press
;   1 = key release
;   2 = key combo (combo continues until bit is no longer set)
;   4 = first press only
;  -1 = end of list
;
; Key Codes/Characters:
;   The virtual key codes match exactly the same as Windows. The character
;   set is western ANSI, not ASCII.
;
; Examples:
;   db 0,VK_RETURN      ;pressing Enter
;   db -1
;
;   db 1,VK_RETURN      ;releasing Enter
;   db -1
;
;   db 2,VK_RETURN      ;pressing Enter while holding both shift & control
;   db 2,VK_SHIFT
;   db 0,VK_CONTROL
;   db -1
;
; (eax=msg/keycode, esi=keylist struct)
; (cf=error keypress not found, ecx=keynumber; eax,ebx)
ScanForKey:
    push ebx
    xor ecx,ecx
    xor ebx,ebx
    jmp short .FirstKey

.NextKey:
    inc ecx                     ;next index
.SkipCombo:
    test dl,2                   ;check if combo key continues
.FirstKey:
    mov dx,[esi]                ;get next keycode & flags
    lea esi,[esi+2]
    jnz .SkipCombo              ;loop until combo is done
    test dl,dl                  ;end of key list?
    js .NoMatch
    cmp dh,ah                   ;key pressed =? key in list
    jne .NextKey

    test dl,4                   ;check if must be first press (not repeat)
    jz .NextCombo               ;repeat allowed
    test eax,KeyMsgFlags.Repeat
    jnz .NextKey                ;repeat not allowed

.NextCombo:
    mov bl,dh
    bt dword [Keyboard.Buttons],ebx
    jnc .Released
    xor dl,1                    ;invert pressed bit
.Released:
    test dl,1                   ;ensure key is in the correct state (up/down)
    jz .NextKey                 ;not right state, so next key
    test dl,2
    jz .Match                   ;end of key combo
    mov dx,[esi]                ;get next keycode & flags
    add esi,byte 2
    jmp short .NextCombo        ;continue checking key combo while still valid

.NoMatch:
    stc                         ;flag no new keys
.Match: ;(cf=0, ecx=index)
    pop ebx
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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
;ÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Changes the active item in a container or changes the active item in
; an item group.
;
; (eax=message|flags, dwords WindowObj ptr, [new item ptr])
; (cf=item could not be set, esi=item ptr if used as function)
GetItemFocus:
SetItemFocus:
%if 0
    <summary>
    This is by far the most complex routine in the entire GUI. Rather than
    simply one level of focus (got focus or no focus), this GUI has three. The
    first level is item focus (like the Windows active control), next is group
    focus (several similar items can be grouped together), and last is
    container focus. All three of these are independant of each other. An item
    can be the active item of a group even if that group isn't active. That
    item could also be part of the active group, but not be the active item
    within that group. Only when all three levels of focus are set can the
    item consider itself "the" active item.

    The main purpose of focus is to show where the key input is currently
    directed, but the two are not necessarily synonymous. Some items never
    receive input (label, picture, title bar) but might draw themselves
    differently depending on whether or not their group or container is
    active.

    Usually tab index order is the same as physical order for static
    containers, but it isn't always the same for the dynamic containers which
    items are created and destroyed. Tab order is also usually the same as
    layer order (window zorder), but again, may be different.

    <further notes>
    The active item always receives focus change messages before any others,
    whether focus was gained or lost. The old item in a group always receives
    messages before any other items in the group. Then new item then receives
    its message, and finally, the rest of the items receive their messages.

    Important: The item/group/container focus flags are reversed, meaning if
    these bits are 1's, the item does not have focus. If they are 0's, the
    item does. At first, this seems stupidly backwards, but I chose this way
    instead of the more common boolean standard (1=true, 0=false) for good
    reason. Because of the processor's ability to test for all zeroes (zf),
    it is easier for an item to test if it has complete focus (meaning it is
    the active item) by checking three 0's than three 1's. Otherwise, it
    would have to either load the flags, invert them (xor), and then test; or
    load the flags, mask them (and), and then compare; instead of simply
    directly TESTing the flags of the GUI object.

    This routine can also be used as a function, not to change the focus of
    anything, just return the tab index of the desired item. Depending on how
    the various flags are set, it can return: the active container item, the
    active item of any given group, the next item, the next item relative to
    a given one, the next group...  rather powerful function.

    Examples of common focus setting:
      The next/previous item within a group
      The next/previous group
      A specific item
      The default item of a specific group

    <routines>
    All these routines are private and mustn't be called outside:
     GetGroupRange  finds a group's start, end, and active item
     FindNextItem   searches forward or backward for next item
     SetItem        sets the focus of a single item
     SetRange       sets a range of items to specific focus values

    These are ok:
     Item           interprets the message+flags and set focus accordingly
     OfActive       sets the focus of all items in a window
     GetItemIdx     finds an item's group order index

    <really brief pseudocode>
    get new item, either relative or absolute
    return now if get index only
    chain focus to parent now if specified
    set new item(s) and send focus messages

    <longer pseudocode>
    return if no items

    get tab index of current focus item
    get item index of relative or absolute item
    get group range for that item
    if relative
        if relativeto
            ;get tab index of relative item
            get item key index
            get group range
        endif
        if set group
            low range start = 0
            high range end = total items
        else
            low range start = group start
            high range end = group end
        endif
        if set item
            low range end = current item
            high range start = current item+1
        else
            low range end = group start
            high range start = group end
        endif
        call FindNextItem
        if no items found, return failure

        get group range

    else absolute
        verify item can receive focus

    endif

    if not set item
        set new item to new group's default item
    endif

    if get index only, return index
    send focus change message to container's owner
    save container's current focus (for detecting nested calls)
    send focus change message to container owner

    if container focus needs setting, chain focus message up
    if container's focus changed, set masks accordingly

    if group changed
        unset item focus of old item
        unset old group
        if active item of new group changed, unset item focus of old item
        set item focus of new item
        set old group
    else
        unset item focus of old item
        set item focus of new item
    endif

    if container's focus changed, set entire range (only affects those not
      already set from above)


    When Container gains focus:
    if currently setting focus, return
    get range of current group
    set focus of active item
    set focus of item range before current group
    set focus of current group
    set focus of item range after current group

    When Container loses focus:
    set focus of active item
    set focus of all item remaining items in container
%endif

;+ebp
.StkSize        equ 48
.ItemFlags      equ -48         ;modified setting flags (also use for messages sent to item)
.ItemAnd        equ -44         ;flag and mask (used by .SetItem)
.ItemOr         equ -40         ;flag or mask  (used by .SetItem)
.OuterLow       equ -36         ;first item in low range
.InnerLow       equ -32         ;last item in low range (+1)
.InnerHigh      equ -28         ;first item in high range
.OuterHigh      equ -24         ;last item in high range (+1)
.CgLow          equ -20         ;current group start (tab index)
.CgHigh         equ -16         ;current group end (tab index +1)
.CgIdx          equ -12         ;tab index of default group item
.AiIdx          equ -8          ;tab index of container's active item
.Flags          equ -4          ;original passed setting flags
.WinPtr         equ 8           ;container ptr
.ItemPtr        equ 12          ;ptr to new item to recieve focus
section bss
alignb 4
.CgDefIdx:      resd 1          ;GetGroupRange returns as alternate default group item
section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Item: ;(public)
    push ebp
    mov ebp,esp
    push eax                    ;save message and focus flags
    sub esp,byte .StkSize-4     ;the -4 is for the push eax above

    ; use either current active item or specified one
    test eax,FocusMsgFlags.SetGroup|FocusMsgFlags.SetItem
    jz near .ItemInvalid
    mov ebx,[ebp+.WinPtr]       ;get container data structure
    mov edx,[ebx+WindowObj.FocusItem] ;get item with current focus
    call .GetItemKeyIdx
    ;jc near .ItemInvalid       ;ignore any error for now (can't find item)
    ;mov eax,[ebp+.Flags]       ;get passed flags
    mov [ebp+.AiIdx],edx        ;store active item's tab index

    test eax,FocusMsgFlags.Specified
    jz .ItemNoSpec
    mov edx,[ebp+.ItemPtr]      ;get new item to receive focus
    call .GetItemKeyIdx
    jc near .ItemInvalid        ;can't find nonexistant item
.ItemNoSpec:
    call .GetGroupRange

    ; branch here to either absolute or relative
    mov eax,[ebp+.Flags]        ;get passed flags
    test eax,FocusMsgFlags.Relative
    jz near .AbsoluteSet

;ÄÄÄÄÄÄÄÄÄÄ
; (eax=flags, edx=relative item tab idx)
.RelativeSet:
   ;if relative
   ;    if relativeto
   ;        ;get tab index of relative item
   ;        call GetItemKeyIdx
   ;        call GetGroupRange
   ;    endif
   ;    ...
   ;    if set group or no active item (any group, entire container list)
   ;        low range start = 0
   ;        high range end = total items
   ;    else (constrain within group)
   ;        low range start = group start
   ;        high range end = group end
   ;    endif

    ;mov eax,[ebp+.Flags]       ;get passed flags
    mov edi,[ebp+.CgHigh]       ;current group end (tab index +1)
    mov esi,[ebp+.CgLow]        ;current group start (tab index)

    cmp [.CgDefIdx],dword 0     ;no active items in group! mustn't limit range
    jl .RsAnyGroup              ;within group
    test eax,FocusMsgFlags.SetGroup
    jz .RsInGroup
.RsAnyGroup:
    or dword [ebp+.Flags],FocusMsgFlags.SetGroup
    movzx ecx,word [ebx+WindowObj.TotalItems]
    mov [ebp+.OuterLow],dword 0 ;limit outer search range to entire container
    mov [ebp+.OuterHigh],ecx
    jmp short .RsEndGroup
.RsInGroup:
    mov [ebp+.OuterLow],esi     ;limit outer search range within group
    mov [ebp+.OuterHigh],edi
.RsEndGroup:

   ;(edx=relative item tab index, esi=outer low, edi=outer high, eax=flags)
   ;    if set item
   ;        low range end = current item
   ;        high range start = current item+1
   ;    else
   ;        low range end = group start
   ;        high range start = group end
   ;    endif
    test eax,FocusMsgFlags.SetItem
    jz .RsNoItem
    mov [ebp+.InnerLow],edx
    inc edx
    mov [ebp+.InnerHigh],edx
    dec edx
    jmp short .RsEndItem
.RsNoItem:
    mov [ebp+.InnerLow],esi     ;InnerLow = CgLow
    mov [ebp+.InnerHigh],edi    ;InnerHigh = CgHigh
.RsEndItem:

    call .FindNextItem
    jc near .ItemInvalid        ;no available items! (either window is empty or all items are disabled)
    cmp [ebp+.CgLow],edx        ;if (item < CgLow || item >= CgHigh)
    ja .RsDifGroup              ;  GetGroupRange
    cmp [ebp+.CgHigh],edx
    ja .ItemValid               ;same group
.RsDifGroup:
    call .GetGroupRange
    mov eax,[ebp+.Flags]        ;get passed flags
    test eax,FocusMsgFlags.SetItem
    jnz .ItemValid
    mov edx,[.CgDefIdx]         ;tab by group, so get active item of new group
    jmp short .ItemValid

;ÄÄÄÄÄÄÄÄÄÄ
.AbsoluteSet:
; (eax=flags, edx=absolute item tab idx)
    ; this section verifies that the specfied item is allowed to receive
    ; focus. if not, it checks if the group in which that item is contained
    ; can receive focus. it confirms this by checking every item in
    ; the group to see if any single item can. if not, then the last, highest
    ; resort is to check if the container can receive focus. if all three of
    ; these conditions fail, then return with an error.

    ;mov eax,[ebp+.Flags]       ;get passed flags
    ; (code disabled to allow "null" be the current active item)
    ;test edx,edx
    ;js near .ItemInvalid       ;edx is -1 meaning no active item

    ; verify new item can receive focus
    test eax,FocusMsgFlags.SetItem
    jz .AsNoItem
    movzx ecx,word [ebx+WindowObj.ItemsKeyIdx+edx*8]
    mov esi,[ebx+WindowObj.ItemsPtr+ecx*8]
    test dword [esi+GuiObj.Flags],GuiObj.NoKeyFocus|GuiObj.Disabled|GuiObj.Null
    jnz .AsNoItem               ;item can not receive focus
    test eax,FocusMsgFlags.Silent
    jz .ItemValid
    mov [ebx+WindowObj.FocusItem],esi
    jmp .ItemEnd

    ; if new group can be set, focus change is valid
.AsNoItem:
    test eax,dword FocusMsgFlags.SetGroup
    jz near .ItemInvalid
    ;mov edx,[ebp+.CgIdx]
    mov edx,[.CgDefIdx]
    test edx,edx                ;check the group has any active item
    js near .ItemInvalid        ;it doesn't, and no items can be set
    
;ÄÄÄÄÄÄÄÄÄÄ
; (edx=new item key idx, eax=focus flags)
.ItemValid:

    ; return item ptr if .Get specified
    cmp al,Msg.GetItemFocus
    movzx esi,word [ebx+WindowObj.ItemsKeyIdx+edx*8]
    mov esi,[ebx+WindowObj.ItemsPtr+esi*8]
    ;clc
    je near .ItemEnd

    ; prepare message to be sent to item
    and eax,~(FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.SetContainer)
    mov al,Msg.Focus

;ÄÄÄÄÄÄÄÄÄÄ
.ItemSet:
;(eax=key focus flags, edx=new item key index, esi=new item ptr)
    ; (if focus change caused active group to change)
    ; if set group && (active item < Cglow || active item >= CgHigh)

    test dword [ebp+.Flags],FocusMsgFlags.SetGroup
    mov [ebp+.ItemFlags],eax
    mov ecx,[ebp+.AiIdx]
    jz near .IsGroupSame
    cmp [ebp+.CgLow],ecx
    jg .IsGroupChange
    cmp [ebp+.CgHigh],ecx
    jg near .IsGroupSame2
.IsGroupChange:

    ; inform old active item and group of lost focus
    mov [ebx+WindowObj.FocusItem],esi
    push dword [ebp+.CgLow]     ;save group information of current item
    push dword [ebp+.CgHigh]
    push dword [ebp+.CgIdx]
    xchg [ebp+.AiIdx],edx       ;swap old active item with new
    call .GetGroupRange
    mov [ebp+.ItemAnd],dword -1
    mov [ebp+.ItemOr],dword GuiObj.GroupFocus
    call .SetItem
    mov esi,[ebp+.CgLow]        ;current group start (tab index)
    mov edi,[ebp+.CgHigh]       ;current group end (tab index +1)
    mov [ebp+.InnerLow],esi
    mov [ebp+.InnerHigh],edi
    call .SetRange
    pop edx                     ;CgIdx
    pop dword [ebp+.InnerHigh]  ;CgHigh
    pop dword [ebp+.InnerLow]   ;CgLow

    ; inform new active item and group of gained focus
    cmp [ebp+.AiIdx],edx        ;only if new active item of group is different
    je .IsGroupAiSame
    mov [ebp+.ItemAnd],dword ~GuiObj.GroupFocus
    mov [ebp+.ItemOr],dword GuiObj.ItemFocus
    call .SetItem
.IsGroupAiSame:
    mov [ebp+.ItemAnd],dword ~(GuiObj.GroupFocus|GuiObj.ItemFocus)
    mov [ebp+.ItemOr],dword 0
    mov edx,[ebp+.AiIdx]        ;get new item of group
    call .SetItem
    mov [ebp+.ItemAnd],dword ~GuiObj.GroupFocus
    ;mov [ebp+.ItemOr],dword 0
    call .SetRange
    jmp short .IsItemSame

; (ecx=active item key idx, esi=new item ptr)
.IsGroupSame:
    ; if this focus change occurs in the active group, then set the
    ; container's active item
    cmp [ebp+.CgLow],ecx
    jle .IsGroupSame2
    cmp [ebp+.CgHigh],ecx
    jle .IsGroupChange2
.IsGroupSame2:
    mov [ebx+WindowObj.FocusItem],esi
.IsGroupChange2:

    ; inform new and old items of changed focus
    ;test [ebp+.Flags],dword FocusMsgFlags.SetItem
    ;jz .IsSameItem
    cmp [ebp+.CgIdx],edx
    je .IsItemSame
;.IsItemChange:
    xchg [ebp+.CgIdx],edx       ;swap old active group item with new
    mov [ebp+.ItemAnd],dword -1
    mov [ebp+.ItemOr],dword GuiObj.ItemFocus
    call .SetItem
    mov edx,[ebp+.CgIdx]
    mov [ebp+.ItemAnd],dword ~GuiObj.ItemFocus
    mov [ebp+.ItemOr],dword 0
    call .SetItem
.IsItemSame:

;ÄÄÄÄÄÄÄÄÄÄ
; chain focus message up to container
.ChainContainer:
    ;mov eax,[ebp+.Flags]        ;get original flags again
    test dword [ebp+.Flags],FocusMsgFlags.SetContainer
    jz .ItemEnd                 ;not supposed to set container
.ChainContainerNow: ;(eax=focus flags)
    ;test dword [ebx+GuiObj.Flags],GuiObj.ItemFocus|GuiObj.GroupFocus|GuiObj.ContainerFocus
    ;jz .ItemEnd                 ;already has focus
    mov esp,ebp
    pop ebp
    ;debugwrite "SetItemFocus: chaining to container"
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.SetContainer
    ;or eax,FocusMsgFlags.SetGroup|FocusMsgFlags.SetItem
    jmp SendContainerMsg        ;grab focus and chain up
    ;clc
    ;ret

;ÄÄÄÄÄÄÄÄÄÄ
; This point has been reached because the specified group/item could not be
; set, there are no items in the window, or the group & item flags are both 0.
; (eax=focus flags)
.ItemInvalid:
    debugwrite "SetKeyFocus: item invalid"
    ; if container focus needs setting, chain focus message up
    DebugMessage "SetItemFocus: item invalid"
    test eax,FocusMsgFlags.SetContainer
    jnz .ChainContainerNow
    mov esi,NullGuiItem
    stc

;ÄÄÄÄÄÄÄÄÄÄ
.ItemEnd:
    mov esp,ebp
    pop ebp
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Simply returns the list of index of item given its tab index. Note that
; unlike GetItemKeyIdx, this function returns the index value in esi instead
; of edx, because most calling code will want to preserve edx too.
;
; (edx=tab index, ebx=container data)
; (esi=item index, cf=error; eax; ebx, edx)
;.GetItemListIdx:
;    movzx esi,word [ebx+WindowObj.ItemsKeyIdx+edx*8]
;    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Searches through tab order list to find an item and returns its tab index.
; Since the tab order is dynamic and physical item order may be different
; as key order, this function is needed to find it. For item 2 in the list
; below (button), a tab index value of 1 would be returned because that is
; the index of the entry that points to
; it.
;
; 0=Text prompt     1
; 1=List            2 (tab index 1 points to item 2)
; 2=Button          0
;
; (edx=item ptr, ebx=container ptr)
; (edx=tab index, cf=error; eax,ebx)
.GetItemKeyIdx: ;public
    movzx ecx,word [ebx+WindowObj.TotalItems]
    lea esi,[ebx+WindowObj.ItemsPtr-8+ecx*8]  ;start at last item
    dec ecx
    js .GiiErr

.GiiNext:
    cmp [esi],edx
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Finds the first, last, and default tab indexes for an item's group
;
; Example:
; Say you were interested in the text prompt. This function would return the
; label as the group start (CgLow), scroll bar as group end (CgHigh), and the
; list as the currently active item within that group.
;
; 0=Button
; 1=Label       <- first item of group
; 2=Text prompt <- specified item
; 3=List        <- default/active group item
; 4=Scroll Bar  <- last item of group
; 5=Menu
; 6=Image
;
; If there are no separate groups in a container, the group will be the
; entire container, and the first/last group items will be the first/last
; container items.
;
; (edx=item tab index, ebx=container data)
; ([.CgHigh], [.CgLow], [.CgIdx], cf=error; ebx,edx)
.GetGroupRange:
    movzx ecx,word [ebx+WindowObj.TotalItems]
    mov [ebp+.CgIdx],dword -1   ;default group item if none is found
    mov [.CgDefIdx],dword -1    ;in case group has no items that can receive focus
    cmp edx,ecx                 ;item index >= total items
    jae near .GgrErr

; seek group end
    lea esi,[ebx+WindowObj.Items+edx*8]
    push edx                    ;save item tab index for start seek below
    push esi                    ;save ptr for start seek below

    jmp short .GgreSkip
.GgreNext:
    movzx edi,word [esi+WindowObjItems.KeyIdx]
    mov edi,[ebx+WindowObj.Items+edi*8]  ;item data structure
    mov eax,[edi+GuiObj.Flags]  ;get flags
    test eax,GuiObj.GroupStart  ;item begins a different group
    jnz .GgreEnd
    test eax,GuiObj.Null|GuiObj.NoKeyFocus|GuiObj.Disabled|GuiObj.NoItemFocus
    jnz .GgreSkip
    test eax,GuiObj.ItemFocus
    mov [.CgDefIdx],edx         ;potential group item if no others found later
    jnz .GgreSkip
    mov [ebp+.CgIdx],edx        ;default group item found
.GgreSkip:
    inc edx
    add esi,byte WindowObjItems.SizeOf
    cmp edx,ecx                 ;loop while item < items
    jb .GgreNext
.GgreEnd:
    mov [ebp+.CgHigh],edx

; seek group start
    pop esi                     ;retrieve [esi+ebx+WindowObj.Items]
    mov edx,[esp]               ;retrieve item tab index

.GgrsNext:
    movzx edi,word [esi+WindowObjItems.KeyIdx]
    mov edi,[ebx+WindowObj.Items+edi*8]  ;item data structure
    mov eax,[edi+GuiObj.Flags]  ;get flags
    test eax,GuiObj.Null|GuiObj.NoKeyFocus|GuiObj.Disabled|GuiObj.NoItemFocus
    jnz .GgrsNotItem
    test eax,GuiObj.ItemFocus
    mov [.CgDefIdx],edx         ;potential group item if no others found later
    jnz .GgrsNotItem
    mov [ebp+.CgIdx],edx        ;default group item found
.GgrsNotItem:
    test eax,GuiObj.GroupStart  ;item is beginning of current group
    jnz .GgrsEnd
.GgrsSkip:
    dec edx
    js .GgrsEnd2                ;loop while item >= 0
    sub esi,byte WindowObjItems.SizeOf
    jmp short .GgrsNext
.GgrsEnd2:
    inc edx                     ;adjust key index +1
.GgrsEnd:
    mov [ebp+.CgLow],edx

    ; By now, both start and end of group have been found, and the default
    ; group item has probably been also. If not (because somehow there is
    ; none), it will = -1. In that case, remedy the situation by electing
    ; the first available item as group default.
    cmp [ebp+.CgIdx],edx        ;default group item >= group start
    jl .GgrNoCgIdx              ;default group item wasn't found
    mov edx,[ebp+.CgIdx]
    mov [.CgDefIdx],edx         ;it was found
.GgrNoCgIdx:

    pop edx
    clc
    ret

.GgrErr:
    xor eax,eax
    mov [ebp+.CgLow],eax
    mov [ebp+.CgHigh],eax
    stc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Seeks either forward or backward within a given range to find the next
; available item that can receive key focus.
;
; (edx=item's tab index to start seek from,
;  ebx=container data
;  [.OuterLow],
;  [.InnerLow],
;  [.InnerHigh],
;  [.OuterHigh])
; (edx=new item's tab index, eax=msg flags, cf=error; ebx)
.FindNextItem:
    ;Count = (OuterHigh-OuterLow) - (InnerHigh-InnerLow)
    mov ecx,[ebp+.OuterHigh]
    mov eax,[ebp+.Flags]        ;get passed flags
    sub ecx,[ebp+.OuterLow]
    ;jle .FnifErr               ;if count <= 0, return error
    add ecx,[ebp+.InnerLow]
    sub ecx,[ebp+.InnerHigh]
    jle .FnifErr                ;if count <= 0, return error

   ;if forward
   ;    idx = InnerHigh
   ;    do
   ;        if idx => OuterHigh, idx = OuterLow
   ;        test item flags
   ;        if item is not null and can get key focus, exit
   ;        idx++
   ;        count--
   ;    loop while count >=0
   ;else ...
    test eax,FocusMsgFlags.Reverse
    jnz .FniRev
    mov edx,[ebp+.InnerHigh]
    call .FniCalcItemAdr
    jmp short .FnifFirst        ;actual loop structure is inverted

.FnifNext:
    movzx edi,word [esi]
    mov edi,[ebx+WindowObj.ItemsPtr+edi*8]
    test dword [edi+GuiObj.Flags],GuiObj.NoKeyFocus|GuiObj.Disabled|GuiObj.Null|GuiObj.NoItemFocus
    jz .FnifEnd                 ;next item found

    dec ecx
    jle .FnifErr                ;no more items to search, none found
    inc edx
    add esi,byte WindowObjItems.SizeOf

.FnifFirst:
    cmp [ebp+.OuterHigh],edx    ;check for wrap
    jg .FnifNext
    test eax,FocusMsgFlags.NoWrap
    jnz .FnifErr
    mov edx,[ebp+.OuterLow]     ;if idx >= OuterHigh, idx=OuterLow
    call .FniCalcItemAdr
    jmp short .FnifNext

.FnifErr:
    stc
.FnifEnd:
    ;clc                        ;carry should be clear from test above
    ret

.FniRev:
    ;else backward
    ;    idx = InnerLow-1
    ;    do
    ;        if idx < OuterLow, idx = OuterHigh
    ;        test item flags
    ;        if item is not null and can get key focus, exit
    ;        idx--
    ;        count--
    ;    loop while count >=0
    ;endif
    mov edx,[ebp+.InnerLow]
    dec edx                     ;start from one less than InnerLow
    call .FniCalcItemAdr
    jmp short .FnirFirst        ;actual loop structure is inverted

.FnirNext:
    movzx edi,word [esi]
    mov edi,[ebx+WindowObj.ItemsPtr+edi*8]
    test dword [edi+GuiObj.Flags],GuiObj.NoKeyFocus|GuiObj.Disabled|GuiObj.Null|GuiObj.NoItemFocus
    jz .FnirEnd                 ;next item found

    dec ecx
    jle .FnirErr                ;no more items to search, none found
    dec edx
    sub esi,byte WindowObjItems.SizeOf

.FnirFirst:
    cmp [ebp+.OuterLow],edx     ;check for wrap
    jle .FnirNext
    test eax,FocusMsgFlags.NoWrap
    jnz .FnirErr
    mov edx,[ebp+.OuterHigh]
    dec edx
    call .FniCalcItemAdr
    jmp short .FnirNext

.FnirErr:
    stc
.FnirEnd:
    ;clc                        ;carry should be clear from test above
    ret

.FniCalcItemAdr:
    lea esi,[ebx+WindowObj.ItemsKeyIdx+edx*8]
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the focus of only one item.
; (edx=item tab index, ebx=container data, [.ItemAnd], [.ItemOr])
.SetItem:
    cmp [ebx+WindowObj.TotalItems],dx
    jbe .SiEnd

    ; given key index, get list index, then item ptr
    lea esi,[ebx+WindowObj.ItemsKeyIdx+edx*8]
.SiGivenKeyIdx:
; (esi=item tab index ptr, ebx=container data, [.ItemAnd], [.ItemOr])
    movzx edi,word [esi]
    mov ebx,[ebx+WindowObj.ItemsPtr+edi*8]

    ; adjust flags
    mov ecx,[ebx+GuiObj.Flags]
    test ecx,GuiObj.Null        ;only send focus change message if should be aware (text labels do not need to be)
    jnz .SiUnaware
    mov eax,ecx                 ;copy flags for later comparison
    and ecx,[ebp+.ItemAnd]      ;set focus flags (note that 0=focus)
    or ecx,[ebp+.ItemOr]        ;unset focus flags (note that 1=not focus)
    xor eax,ecx                 ;determine changed flags
    jz .SiUnaware               ;don't send message if no change

    ; Items normally only receive focus messages that are important to them,
    ; like gaining or losing full item focus. Other levels of focus (group
    ; and container) are only received by dormant items if they have the
    ; .AllFocus flag set. A title bar is one item that should always get
    ; focus messages when its container gains/loses focus.

    ; determine if focus change is important
    xchg [ebx+GuiObj.Flags],ecx
    test ecx,GuiObj.AllFocus
    jnz .SiAllFocus
    test dword [ebx+GuiObj.Flags],GuiObj.ItemFocus|GuiObj.GroupFocus|GuiObj.ContainerFocus
    jz .SiImportant
    test ecx,GuiObj.ItemFocus|GuiObj.GroupFocus|GuiObj.ContainerFocus
    jnz .SiUnaware
.SiImportant:
    DebugMessage "important key focus"
.SiAllFocus:

    ; send item focus change message
    push edx                    ;not complete (push other item too)
    push edx                    ;push changing item
    push ebx                    ;pass gui object info
    ;and eax,FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.SetContainer
    or eax,[ebp+.ItemFlags]     ;OR changed flags with message
    call [ebx+GuiObj.Code]
    add esp,byte 12
.SiUnaware:
    mov ebx,[ebp+.WinPtr]
.SiEnd:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the focus for an entire range of items.
.SetRange:
; (ebx=container data, [InnerLow], [InnerHigh], [.ItemAnd], [.ItemOr])
   ;do from inner low to inner high-1
   ;    adjust flags
   ;    if focus change and item aware of such changes
   ;        send item message
   ;    endif
   ;    next item
   ;loop
    mov edx,[ebp+.InnerLow]
    mov ecx,[ebp+.InnerHigh]
    sub ecx,edx                 ;Count = InnerHigh - InnerLow
    jle .SrEnd
    lea esi,[ebx+WindowObj.ItemsKeyIdx+edx*8]
    push ecx
.SrNext:
    push esi
    call .SiGivenKeyIdx
    pop esi
    add esi,byte WindowObjItems.SizeOf
    dec dword [esp]
    jg .SrNext                  ;more items left to set focus

    pop ecx                     ;discard useless counter
.SrEnd:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets or clears all items in a container when the container loses/gains
; focus. Also ensures that at least one item has focus (in case changes
; happened to the window while it didn't have focus). If the previous key
; focus item no longer exists or has been disabled, the routine will first
; try to set another item in that same group, otherwise it will search for
; any item in the container that can receive focus.
;
;   if currently setting focus, return
;   get range of current group
;   set focus of active item
;   set focus of item range before current group
;   set focus of current group
;   set focus of item range after current group
;
; (dword WindowObj ptr)
; (cf always clear even if no items)
.OfActive: ;(public)
    push ebp
    mov ebp,esp
    sub esp,byte .StkSize

    mov ebx,[ebp+.WinPtr]       ;get container data structure
    mov edx,[ebx+WindowObj.FocusItem]
    call .GetItemKeyIdx         ;ignore any error for now
    test dword [ebx+GuiObj.Flags],GuiObj.ItemFocus|GuiObj.GroupFocus|GuiObj.ContainerFocus
    mov [ebp+.ItemFlags],dword Msg.Focus
    jnz near .AiClear

.AiSet:
    ; simple loop to find any items that can receive focus (if needed)
%if 0
    test edx,edx
    jg .AiFoundItem
    movzx edx,word [ebx+WindowObj.TotalItems]
    lea esi,[ebx+WindowObj.ItemsKeyIdx]  ;start at first item
    jmp short .AiFirstItem
.AiNextItem:
    movzx edi,word [esi]
    mov edi,[ebx+WindowObj.ItemsPtr+edi*8]
    test dword [edi+GuiObj.Flags],GuiObj.NoKeyFocus|GuiObj.Disabled|GuiObj.Null|GuiObj.NoItemFocus
    jz .AiFoundItem
    add esi,byte WindowObjItems.SizeOf
.AiFirstItem:
    dec edx
    jge .AiNextItem
.AiFoundItem:
%endif

    call .GetGroupRange

%if 0
    test edx,edx                ;set active item in case there is none
    jge .AiSetItems
    mov edx,[.CgDefIdx]
    test edx,edx
    jl .AiSetItems
    movzx esi,word [ebx+WindowObj.ItemsKeyIdx+edx*8]
    mov esi,[ebx+WindowObj.ItemsPtr+esi*8]
    mov [ebx+WindowObj.FocusItem],esi
%endif

.AiSetItems:
    mov [ebp+.ItemAnd],dword ~(GuiObj.ItemFocus|GuiObj.GroupFocus|GuiObj.ContainerFocus)
    mov [ebp+.ItemOr],dword 0
    call .SetItem
    ;set active group
    mov esi,[ebp+.CgLow]        ;current group start (tab index)
    mov edi,[ebp+.CgHigh]       ;current group end (tab index +1)
    mov [ebp+.ItemAnd],dword ~(GuiObj.GroupFocus|GuiObj.ContainerFocus)
    mov [ebp+.InnerLow],esi
    mov [ebp+.InnerHigh],edi
    call .SetRange
    ;set remaining items, before current group
    mov esi,[ebp+.CgLow]        ;current group start (tab index)
    mov [ebp+.ItemAnd],dword ~GuiObj.ContainerFocus
    ;mov [ebp+.ItemOr],dword GuiObj.GroupFocus
    mov [ebp+.InnerLow],dword 0
    mov [ebp+.InnerHigh],esi
    call .SetRange
    ;set remaining items, after current group
    mov edi,[ebp+.CgHigh]       ;current group end (tab index +1)
    movzx ecx,word [ebx+WindowObj.TotalItems]
    mov [ebp+.InnerLow],edi
    mov [ebp+.InnerHigh],ecx
    call .SetRange
    jmp short .AiEnd

.AiClear:
    ;set active item
    ;mov [ebp+.ItemAnd],~(GuiObj.ItemFocus|GuiObj.GroupFocus)
    mov [ebp+.ItemAnd],dword -1
    mov [ebp+.ItemOr],dword GuiObj.ContainerFocus
    call .SetItem
    movzx ecx,word [ebx+WindowObj.TotalItems]
    mov [ebp+.InnerLow],dword 0
    mov [ebp+.InnerHigh],ecx
    call .SetRange

.AiEnd:
    mov esp,ebp
    pop ebp
    clc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Calls the mouse driver to update position and button information. If either
; the buttons or position have changed, a message is returned; otherwise
; carry is set. This does absolutely no checking which item the message
; should be sent to, simply forms the message using the mouse driver's info.
;
; In Windows, it needs to do a lot of hackey translation just to support
; features the OS should have included standard. The main stupidity is total
; lack of support for mouse in/out messages. It would be SO simple for the OS
; to send a message to the previous cursor owning window, just like
; WM_SETFOCUS and WM_KILLFOCUS for keyboard but instead for mouse.
;
; Many programmers have compensated for this shortcoming by using a timer,
; and checking if the cursor is still within bounds after a short time out.
; Disliking that hack, I tried installing a mouse hook that would monitor
; target changes, but soon found out that I couldn't read my own data segment
; (that's dumb). So now it keeps the mouse in a state of perpetual capture
; (SetCapture) until some other window takes it.
;
; ()
; (al=mouse move/prs/rls message,
;  | cf=if no change)
GetMouseMsg:
%ifdef WinVer

    movzx ebx,byte [msg+MSG.wParam] ;get current buttons (zero top bits)

    ; check for mouse enter/exit from main window
    ; have to do much compensation for Window's stupidity just to know when
    ; the cursor has moved in or out.
    test byte [Mouse.Buttons],Mouse.LeftDown|Mouse.RightDown|Mouse.MiddleDown
    jnz near .Captured
    api WindowFromPoint, [msg+MSG.x],[msg+MSG.y]
    ;debugwrite "hwnd at point = %d",eax
    cmp [Mouse.hwnd],eax
    mov [Mouse.hwnd],eax
    je near .SameOwner
    or byte [Display.RedrawFlags],Display.RedrawCursor|Display.CursorMoved
    cmp [hwnd],eax
    je .MovedIn
.MouseOut: ;(ebx=buttons)
    ;debugwrite "mouse moved out from window"
    mov dword [Mouse.Buttons],0         ;no buttons/presses/releases
    mov dword [Cursor.Row],16384        ;put cursor way off (invisible)
    mov dword [Cursor.Col],16384
    mov eax,Msg.MouseOut|MouseMsgFlags.MouseMoved|MouseMsgFlags.WindowInOut
    clc
    ret
.MovedIn: ;(ebx=buttons)
    mov [Mouse.Buttons],ebx     ;set buttons, no presses/releases
    ;debugwrite "mouse moved in to window"
    movsx edx,word [msg+MSG.lParam+2]   ;sign row
    movsx ecx,word [msg+MSG.lParam]     ;sign column
    mov [Cursor.Row],edx
    mov [Cursor.Col],ecx
    ;mov dword [Cursor.RowDif],0 (not necessary)
    ;mov dword [Cursor.ColDif],0
    api SetCapture, [hwnd]              ;trap mouse so it won't get away
    ;call ConfineCursor.Release
    mov eax,Msg.MouseIn|MouseMsgFlags.MouseMoved|MouseMsgFlags.SetItem|MouseMsgFlags.WindowInOut
    clc
    ret
; same mouse owner as last time, may not mean that mouse is currently owned
; by the GUI window though.
; (eax=window handle)
.SameOwner:
    cmp [hwnd],eax
    je .Captured
    stc
    ret

.Captured: ;(ebx=buttons)
    ;debugwrite "mouse captured"
; check for mouse cursor movement
    movsx edi,word [msg+MSG.lParam+2]   ;sign row
    movsx esi,word [msg+MSG.lParam]     ;sign column
    xor eax,eax                         ;in case no change, clear msg & flags
    mov edx,edi
    mov ecx,esi

    ; determine new row and constrain if necessary
    sub edi,[Cursor.Row]
    mov [Cursor.RowDif],edi
    je .RowSame
    mov al,Msg.MouseMove
    cmp [Cursor.Top],edx
    jg .BeyondTop
    cmp [Cursor.Btm],edx
    jg .RowOk
    mov edx,[Cursor.Btm]
    dec edx
    jmp short .RowConfined
.BeyondTop:
    mov edx,[Cursor.Top]
.RowConfined:
    or eax,MouseMsgFlags.VerticalPush
.RowOk:
    mov [Cursor.Row],edx
    or eax,MouseMsgFlags.MouseMoved
    or byte [Display.RedrawFlags],Display.CursorMoved
.RowSame:

    ; determine new col and constrain if necessary
    sub esi,[Cursor.Col]
    mov [Cursor.ColDif],esi
    je .ColSame
    mov al,Msg.MouseMove
    cmp [Cursor.Left],ecx
    jg .BeyondLeft
    cmp [Cursor.Right],ecx
    jg .ColOk
    mov ecx,[Cursor.Right]
    dec ecx
    jmp short .ColConfined
.BeyondLeft:
    mov ecx,[Cursor.Left]
.ColConfined:
    or eax,MouseMsgFlags.HorizontalPush
.ColOk:
    mov [Cursor.Col],ecx
    or eax,Msg.MouseMove|MouseMsgFlags.MouseMoved
    or byte [Display.RedrawFlags],Display.CursorMoved
.ColSame:

    test eax,MouseMsgFlags.HorizontalPush|MouseMsgFlags.VerticalPush
    jz .Unconfined
    push eax
    sub dx,[msg+MSG.lParam+2]
    sub cx,[msg+MSG.lParam]
    movsx edx,dx
    movsx ecx,cx
    add edx,[msg+MSG.y]         ;get screen column
    add ecx,[msg+MSG.x]         ;get screen row
    api SetCursorPos, ecx,edx
    pop eax
.Unconfined:

; check for mouse presses, releases
.Press:
    and bl,11100111b            ;mask off silly shift and control key
    mov bh,[Mouse.Buttons]
    xor bh,bl                   ;get buttons that have changed since last time
    je .NoPressRelease
    ;mov esi,[Timer.Now]        ;get current tick time
    mov esi,[msg+MSG.time]      ;get time of event
    mov al,bh                   ;copy buttons that have changed state
    and bh,bl                   ;get buttons pressed by ANDing those changed
    jz .NoPress
    mov edi,esi
    sub esi,[Mouse.LastClick]   ;get difference between current and previous
    mov [Mouse.LastClick],edi   ;set last click time
    mov [Mouse.ClickTime],esi   ;set difference for double click comparison
.NoPress:
    ror ebx,8
    mov bh,bl                   ;get buttons released by XORing those changed
    xor bh,al                   ;with ones pressed, leaving releases only
    rol ebx,8
    mov al,Msg.MousePrsRls
.NoPressRelease:
    mov [Mouse.Buttons],ebx     ;set buttons currently down, pressed, and released

    cmp eax,1                   ;sets carry if eax is still zero
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
%elifdef DosVer
    ; call mouse drive to get current button state and motion change
    cmp [Mouse.NumButtons],byte 2
    jnc .MousePresent
    ret
.MousePresent:

    xor ebx,ebx                 ;clear buttons pressed/released flags
    mov eax,3h                  ;mouse driver: get position and buttons
    int 33h
    mov eax,0Bh                 ;mouse driver: read motion counters
    int 33h
    movsx edx,dx                ;sign row
    xor eax,eax                 ;default if no mouse change
    movsx ecx,cx                ;sign column
    add edx,[Mouse.RowFine]
    add ecx,[Mouse.ColFine]
;(eax=0, ebx=buttons, ecx=vertical row, edx=horizontal col)

    ; calculate new cursor position
    sar edx,1                   ;row/=2
    setc byte [Mouse.RowFine]
    mov [Mouse.RowDif],edx
    jz .RowSame
    or byte [Display.RedrawFlags],Display.RedrawCursor

    ; constrain cursor row
    mov eax,Msg.MouseMove|MouseMsgFlags.MouseMoved
    add edx,[Cursor.Row]
    cmp [Cursor.Top],edx
    jg .BeyondTop
    cmp [Cursor.Btm],edx
    jg .RowOk
    mov edx,[Cursor.Btm]
    dec edx
    jmp short .RowConfined
.BeyondTop:
    mov edx,[Cursor.Top]
.RowConfined:
    or eax,MouseMsgFlags.VerticalPush
.RowOk:
    mov [Cursor.Row],edx
.RowSame:

    sar ecx,1                   ;col/=2
    setc byte [Mouse.ColFine]
    mov [Mouse.ColDif],ecx
    jz .ColSame
    or byte [Display.RedrawFlags],Display.RedrawCursor

    ; constrain cursor column
    or eax,Msg.MouseMove|MouseMsgFlags.MouseMoved
    add ecx,[Cursor.Col]
    cmp [Cursor.Left],ecx
    jg .BeyondLeft
    cmp [Cursor.Right],ecx
    jg .ColOk
    mov ecx,[Cursor.Right]
    dec ecx
    jmp short .ColConfined
.BeyondLeft:
    mov ecx,[Cursor.Left]
.ColConfined:
    or eax,MouseMsgFlags.HorizontalPush
.ColOk:
    mov [Cursor.Col],ecx
.ColSame:

    mov bh,[Mouse.Buttons]
    xor bh,bl                   ;get buttons that have changed since last time
    je .NoPressRelease
    mov esi,[Timer.Now]         ;get current tick time (18.2 ticks per second)
    mov al,bh                   ;copy buttons that have changed state
    and bh,bl                   ;get buttons pressed by ANDing those changed
    jz .NoPress
    mov edi,esi
    sub esi,[Mouse.LastClick]   ;get difference between current and previous
    mov [Mouse.LastClick],edi   ;set last click time
    mov [Mouse.ClickTime],esi   ;set difference for double click comparison
.NoPress:
    ror ebx,8
    mov bh,bl                   ;get buttons released by XORing those changed
    xor bh,al                   ;with ones pressed, leaving releases only
    rol ebx,8
    mov al,Msg.MousePrsRls
    DebugMessage "mouse press"
.NoPressRelease:
    mov [Mouse.Buttons],ebx     ;set buttons currently down, pressed, and released
    cmp eax,1                   ;sets carry if eax is still zero
    ret
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Simply resets mouse boundaries to minimum
;
; (ebx=WindowObj ptr)
;.ResetArea:
;    mov ebx,[esp+.WinPtr]
;.ResetAreaByReg:
;    mov dword [ebx+WindowObj.MouseTopLeft], 32767|(32767<<16) ;set area ranges to minimum extents forcing the next SendMouseMsg to do an item rescan
;    mov dword [ebx+WindowObj.MouseBtmRight],32768|(32768<<16) ;so that the next call will force an item rescan
;    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄ
.Release:
    ; set area ranges to minimum extents so that the next mouse message will
    ; force an item rescan
    DebugMessage "mouse released"
    mov dword [ebx+WindowObj.MouseTopLeft], 32767|(32767<<16) ;set area ranges to minimum extents forcing the next SendMouseMsg to do an item rescan
    ;mov dword [ebx+WindowObj.MouseBtmRight],32768|(32768<<16)
    test eax,MouseMsgFlags.SetContainer
    jz .FocusChange
    ;jmp short .ChainContainer

;ÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

    ; scan for any empty entries (items set to null)
    ; if entry available
    ;   set new item
    ; else none available
    ;   if total items < maxitems
    ;     set new item
    ; endif
    ; set new item's container and index
    ; if requested
    ;   set item's layer order
    ;   set item's key focus
    ; endif

    mov ebx,[esp+.WinPtr]       ;get window data structure
    mov esi,[esp+.ItemPtr]

    ; first look for empty spot in list
    lea edi,[ebx+WindowObj.Items]
    xor edx,edx
    jmp short .FirstCheck
.NextCheck:
    mov ecx,[edi+WindowObjItems.Ptr]
    test dword [ecx+GuiObj.Flags],GuiObj.Null
    jz .ItemExists
    ; empty spot found, replace with new item
    mov [edi+WindowObjItems.Ptr],esi
    ; leave item's layer order and key focus unchanged for now
    jmp short .SetContainer
.ItemExists:
    inc edx                         ;next index
    add edi,byte WindowObjItems.SizeOf
.FirstCheck:
    cmp [ebx+WindowObj.TotalItems],dx
    ja .NextCheck

    ; try to add item to end of list
    ; (ecx=total items, esi=end of list, edx=item ptr, eax=flags)
    cmp [ebx+WindowObj.MaxItems],dx
    jbe .Err
    mov [edi+WindowObjItems.Ptr],esi  ;append new item to end of list
    mov [edi+WindowObjItems.Layer],dx
    mov [edi+WindowObjItems.KeyIdx],dx
    inc word [ebx+WindowObj.TotalItems]

; (esi=item ptr, edx=item index, eax=flags)
.SetContainer:
    mov [esi+GuiObj.Container],ebx
    mov [esi+GuiObj.Idx],dx

    ; adjust the key focus flags of new adopted item
    or dword [esi+GuiObj.Flags],GuiObj.ContainerFocus
    test dword [ebx+GuiObj.Flags],GuiObj.ItemFocus|GuiObj.GroupFocus|GuiObj.ContainerFocus
    jnz .NoContainerFocus
    and dword [esi+GuiObj.Flags],~(GuiObj.ContainerFocus|GuiObj.GroupFocus)
.NoContainerFocus:

    ; reset mouse boundaries
    ;test dword [ebx+GuiObj.Flags],GuiObj.NoMouseFocus|GuiObj.Disabled
    ;jz
    mov dword [ebx+WindowObj.MouseTopLeft], 32767|(32767<<16) ;set area ranges to minimum extents forcing the next SendMouseMsg to rescan all items
    ;mov dword [ebx+WindowObj.MouseBtmRight],0

    ; set layer order
    test eax,LayerMsgFlags.SetItem
    jz .NoLayerChange
    push esi                    ;pass item ptr
    push ebx                    ;pass container ptr
    call SetLayerOrder
    pop ebx
    pop esi
.NoLayerChange:

    ; clear null flag in item and redraw
    and dword [esi+GuiObj.Flags],~GuiObj.Null
    mov eax,GuiObj.Redraw
    or dword [esi+GuiObj.Flags],GuiObj.Redraw
    mov ebx,esi                 ;copy item ptr
    jmp SendContainerRedraw
    ;ret

.Err:
    stc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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
    ; if specified item is truly in container
    ;   set to GUI item
    ;   if item = (total items - 1)
    ;     shift entries (so layer and key order don't get lost)
    ;     total items--
    ;   endif
    ; endif

    mov esi,[esp+.ItemPtr]
    mov ebx,[esp+.WinPtr]       ;get window data structure
    movzx edx,word [esi+GuiObj.Idx]
    cmp [ebx+WindowObj.TotalItems],dx
    jbe .Err
    cmp [ebx+WindowObj.Items+edx*8],esi
    jne .Err

    ; add to redraw before destroying
    ; (esi=item ptr, edx=item index)
    push edx                    ;save item index
    push esi                    ;save item ptr
    call AddItemToRedraw
    pop edi
    pop edx

    ; destroy (or rather, "remove") item
    mov word [edi+GuiObj.Idx],-1
    ;or dword [edi+GuiObj.Flags],GuiObj.Null
    mov dword [ebx+WindowObj.Items+edx*8],NullGuiItem

    ; shift layer and key order
    ; these must be shifted separately, since they may differ
    lea esi,[ebx+WindowObj.ItemsLayer]
    call .ShiftIndexes
    lea esi,[ebx+WindowObj.ItemsKeyIdx]
    call .ShiftIndexes

    ; remove any trailing empty entries
    ;movzx ecx,word [ebx+WindowObj.TotalItems]
    ;lea esi,[ebx+WindowObj.Items+ecx*8-8]

    lea ecx,[edx-1]
    cmp [ebx+WindowObj.TotalItems],cx
    jb .End
    dec word [ebx+WindowObj.TotalItems]
    ;clc (if not jb then cf=0)
.End: ;(cf=1)
    ret
.Err:
    stc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=source ptr in window list, edx=index to remove)
.ShiftIndexes:
    movzx ecx,word [ebx+WindowObj.TotalItems]
    xor eax,eax                 ;zextend
    mov edi,esi
.NextShift:
    mov ax,[esi]
    cmp eax,edx
    je .SkipShift
    mov [edi],ax
    add edi,byte WindowObjItems.SizeOf
.SkipShift:
    add esi,byte WindowObjItems.SizeOf
    dec ecx
    jg .NextShift
    mov [edi],dx
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Simply sets the order of an item in a container. The layer can be set to
; the very front, very back, or relative to some other item.
;
; (eax=message|flags, dwords WindowObj ptr, item ptr)
; (cf=item could not be set)
SetLayerOrder:
;+esp
.WinPtr         equ 4           ;container ptr
.ItemPtr        equ 8           ;item to change layer order of
    mov esi,[esp+.ItemPtr]
    mov ebx,[esp+.WinPtr]       ;get window data structure
    movzx edx,word [esi+GuiObj.Idx]
    call .GetItemLayerIdx
    jc .Err

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ;test eax,LayerMsgFlags.SetContainer
    ;jnz near SendContainerMsg
      ;(cf=0)
.Err: ;(cf=1)
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sends a need redraw message to an item's container, but only if the item
; does not already have to flag set (preventing redraw messages unnecessarily
; cascading all the way up multiple times).
;
; Carry is always clear even if the item does not need to be redrawn, so that
; this function can be jumped directly to.
;
; (ebx=sending item's gui ptr, eax=redraw flags to set)
; (cf=0; ebx)
SendContainerRedraw.Bg:
    mov eax,GuiObj.RedrawBg
    jmp short SendContainerRedraw
SendContainerRedraw.Partial:
    mov eax,GuiObj.RedrawPartial
SendContainerRedraw:
    ; if item is not visible, is null, or already has redraw flags set,
    ; then do not pass on message to parent.
    test dword [ebx+GuiObj.Flags],GuiObj.Redraw|GuiObj.Hidden|GuiObj.Null
    jnz .Ignore
    DebugMessage "item needs redraw"
    push ebx                    ;save item data ptr
    or dword [ebx+GuiObj.Flags],eax
    mov ebx,[ebx+GuiObj.Container] ;get container's gui item ptr
    mov eax,Msg.RedrawItem
    push ebx                    ;pass container's data structure
    call [ebx+GuiObj.Code]
    add esp,byte 4
    or dword [Display.RedrawFlags],Display.RedrawItems
    pop ebx                     ;restore ptr
    ;clc                        ;the ADD above clears carry
    ret
.Ignore:
    DebugMessage "item wants redraw"
    or dword [ebx+GuiObj.Flags],eax
    ;clc                        ;the OR above clears carry
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.SkipItem:
    pop esi                     ;retrieve item list ptr
.ItemHidden:
    add esi,byte WindowObjItems.SizeOf
.FirstItem:
    dec dword [esp]
    jns near .NextItem

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.SkipItem:
    pop esi                     ;retrieve item list ptr
.ItemHidden:
    ;sub esi,byte WindowObjItems.SizeOf ;(for drawing reverse order)
    add esi,byte WindowObjItems.SizeOf
.FirstItem:
    dec dword [esp]
    jns near .NextItem

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SendTimeMsgs:
    ; do until end of timer list
    ;   if item should be called or is past time
    ;     call item
    ;     determine next call time
    ;     if next call time > current time
    ;       next call time = current time
    ;     endif
    ;   endif
    ; loop

    ; copy timer objects order temporarily
    mov ecx,[Timer.TotalItems]
    mov esi,Timer.Items
    push ecx
    jmp short .CoFirst
.CoNext:
    mov al,[esi+TimerObj.Order]
    mov [esi+TimerObj.CurOrder],al
    add esi,byte TimerObj_size
.CoFirst:
    dec ecx
    jge .CoNext

    mov edi,Timer.Items
  %ifdef WinVer
    mov eax,[msg+MSG.time]      ;get when WM_TIMER was recieved
    mov [Timer.Now],eax
  %else
    mov eax,[Timer.Now]
  %endif
    ;debugwrite "timer loop total=%d now=%d",[Timer.TotalItems],[Timer.Now]
    jmp short .First

.Next:
    ; check next timed item
    movzx esi,byte [edi+TimerObj.CurOrder]
    cmp esi,Timer.TotalItems
    jae .Skip
    shl esi,TimerObj.SizeShl
    add esi,Timer.Items         ;lea (CurOrder * TimeObjSize) + TimeItemList
    cmp eax,[esi+TimerObj.Time] ;skip if not time yet
    js .Skip

    ;debugwrite "timer @%X owner=%X",esi,[esi+TimerObj.Owner]

    ; call item
    push edi                    ;save timer list ptr
    mov eax,Msg.Time
    mov ebx,[esi+TimerObj.Owner]
    test ebx,ebx
    jz .null
    push esi                    ;pass timer info
    push ebx                    ;pass item ptr
    call dword [ebx+GuiObj.Code]
    add esp,byte 8              ;discard passed vars
    pop edi                     ;restore timer list ptr
.null:

    ; calculate time of next call for item
    mov edx,[edi+TimerObj.Time]
    mov eax,[Timer.Now]
    add edx,[edi+TimerObj.Interval]
    cmp eax,edx
    js .Ahead                   ;now > next time
    mov edx,eax                 ;behind or equal, set next call time to now
.Ahead:
    mov [edi+TimerObj.Time],edx ;set time of next call

.Skip:
    add edi,byte TimerObj_size
.First:
    dec dword [esp]
    jge .Next
    pop eax                     ;discard counter
    ret


%ifdef DosVer
%ifndef NoGuiTimerHandler
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Intercepts timer interrupts, then passes them to the BIOS or DOS.
;
; () (it's an interrupt handler, so EVERYTHING is saved)
GuiTimerHandler:
    push ds
    mov ds,dword [cs:Program.DataSelector]
    add dword [Timer.Now],byte 33;55
    add dword [Timer.IntAccum],(1193182/30)<<16 ;18.2 / 30 ratio
    pop ds
    jnc .NoChain                ;take care of int ourselves
    jmp far [cs:Timer.HandlerOfs]
.NoChain:
    push eax
    mov al,60h                  ;acknowledge interrupt (IRQ0)
    out 20h,al
    pop eax
    iret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (ecx=interval rate)
SetPitRate:
    cli                 ;don't want any interrupt to mess this up below
    mov al,00110100b    ;(00:11:010:0) set counter 0, lsb/msb, mode 2, binary
    out 43h,al
    in al,61h           ;i/o delay
    mov al,cl
    out 40h,al          ;write counter low byte
    in al,61h           ;i/o delay
    mov al,ch
    out 40h,al          ;write counter high byte
    sti
    ret

%endif
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Allocates a timer for a GUI item or program process, returning a pointer to
; the new timer. The default time of the next timer call is the soonest check
; in the main loop, default interval is once every frame, and the order is
; put at the end of the list (after existing timers). The item can change
; these defaults after it is created. If all timers are used (which should
; never happen!), it recycles the last one.
;
; (eax=flags, dwords item ptr)
; (esi=timer ptr, ebx=item ptr)
CreateTimer:
    ;debugpause "enter CreateTimer, total=%d",[Timer.TotalItems]
    ; find first available timer entry
    xor ecx,ecx
    mov edx,[Timer.TotalItems]
    mov esi,Timer.Items
.Next:
    cmp [esi+TimerObj.Owner],dword 0
    je .Found
    inc ecx
    add esi,byte TimerObj_size
    cmp ecx,Timer.MaxItems-1
    jb .Next
    jmp short .NotFound

    ; set default attributes for timer found
.Found:
    inc edx
    mov [Timer.TotalItems],edx
.NotFound:
    mov eax,[Timer.Now]         ;get current time
    ;debugpause "created timer, total=%d  index=%d  timer@%X  now=%d",[Timer.TotalItems],ecx,esi,eax
    mov ebx,[esp+4]             ;get owner
    mov [esi+TimerObj.Interval],dword 33
    mov [esi+TimerObj.Time],eax
    mov [esi+TimerObj.Owner],ebx
    shl edx,TimerObj.SizeShl
    mov [esi+TimerObj.Idx],cl   ;set index
    mov [Timer.Items+edx-TimerObj_size+TimerObj.Order],cl ;add to end of order

    ;debugpause "exit TimerCreate, total=%d  indexes=%X  %X  %X  owners=%X  %X  %X",[Timer.TotalItems],[Timer.Items+TimerObj.Order],[Timer.Items+TimerObj.Order+TimerObj_size],[Timer.Items+TimerObj.Order+TimerObj_size*2],  [Timer.Items+TimerObj.Owner],[Timer.Items+TimerObj.Owner+TimerObj_size],[Timer.Items+TimerObj.Owner+TimerObj_size*2]

    clc
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees a timer used by a GUI item or program process. Looks for the timer
; that points to the given object, then transfers control to DestroyTimer.
;
;
; (dword item/process ptr)
; (dword 0, ebx=item ptr)
DestroyTimerObj:
    mov edi,Timer.Items-TimerObj_size+TimerObj.Order
    mov ebx,[esp+4]
    mov ecx,[Timer.TotalItems]

    ;debugpause "enter DestroyTimerObj, total=%d @%X  indexes=%X  %X  %X  owners=%X  %X  %X",ecx,ebx,[Timer.Items+TimerObj.Order],[Timer.Items+TimerObj.Order+TimerObj_size],[Timer.Items+TimerObj.Order+TimerObj_size*2],  [Timer.Items+TimerObj.Owner],[Timer.Items+TimerObj.Owner+TimerObj_size],[Timer.Items+TimerObj.Owner+TimerObj_size*2]

.Next:
    add edi,byte TimerObj_size
    dec ecx
    js .NotFound
    movzx esi,byte [edi]        ;get timer's index
    shl esi,TimerObj.SizeShl   ;calc index from address
    ;debugpause "timer @+%X =%X",esi,[Timer.Items+esi+TimerObj.Owner]
    cmp [Timer.Items+esi+TimerObj.Owner],ebx
    jne .Next
    add esi,Timer.Items
    jmp short DestroyTimer.Given

.NotFound:
    mov [esp+4],dword 0
    ;debugpause "DestroyTimerObj: exit owner not found"
    stc
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees a timer used by a GUI item or program process. Removes any indexes to
; it from the order list, and sets both the timer's owner to null.
; You pass a pointer to the timer in the list. To instead pass a pointer to
; item using the timer (which is often simpler), call DestroyTimerObj. 
;
; (dword timer ptr)
; (dword 0; ebx)
DestroyTimer:

    ; set timer null
    mov esi,[esp+4]             ;get timer ptr
.Given: ;(esi=timer ptr)
    ;debugpause "enter destroy timer, total=%d  timer@%X",[Timer.TotalItems],esi
    xor edx,edx
    cmp [esi+TimerObj.Owner],edx;check
    je .AlreadyNull             ;bad, some item tried to free timer twice
    dec dword [Timer.TotalItems]
    jns .TotalOk                ;count ok
    mov [Timer.TotalItems],edx  ;otherwise set to zero
.TotalOk:
    mov [esi+TimerObj.Owner],edx;null owner
.AlreadyNull:
    mov [esp+4],edx             ;null passed parameter

    ;mov dl,[esi+TimerObj.Idx]  ;get timer's index
    mov edx,esi                 ;copy pointer
    mov edi,Timer.Items
    mov esi,edi
    sub edx,edi;Timer.Items     ;-base of timer list
    mov ecx,Timer.MaxItems
    shr edx,TimerObj.SizeShl    ;calc index from address

    ;debugpause "before timer shift, total=%d  index=%d  indexes=%X  %X  %X  owners=%X  %X  %X",[Timer.TotalItems],edx, [Timer.Items+TimerObj.Order],[Timer.Items+TimerObj.Order+TimerObj_size],[Timer.Items+TimerObj.Order+TimerObj_size*2],  [Timer.Items+TimerObj.Owner],[Timer.Items+TimerObj.Owner+TimerObj_size],[Timer.Items+TimerObj.Owner+TimerObj_size*2]

.Next:
    cmp [esi+TimerObj.CurOrder],dl
    jne .Other
    mov [esi+TimerObj.CurOrder],byte -1 ;just in case being called from within timer call
.Other:
    mov al,[esi+TimerObj.Order]
    cmp al,dl
    je .Delete
    mov [edi+TimerObj.Order],al
    add edi,byte TimerObj_size
.Delete:
    add esi,byte TimerObj_size
    dec ecx
    jg .Next

    ;debugpause "exit TimerDestroy, total=%d  indexes=%X  %X  %X  owners=%X  %X  %X",[Timer.TotalItems],[Timer.Items+TimerObj.Order],[Timer.Items+TimerObj.Order+TimerObj_size],[Timer.Items+TimerObj.Order+TimerObj_size*2],  [Timer.Items+TimerObj.Owner],[Timer.Items+TimerObj.Owner+TimerObj_size],[Timer.Items+TimerObj.Owner+TimerObj_size*2]
    ret


%ifdef WinVer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=error message ptr)
GuiErrMsgEnd:
    debugwrite "releasing resources"
    ;push dword DxsFg            ;primary surface
    ;call ReleaseCom
    ;push dword DxDraw
    ;call ReleaseCom
    debugwrite "exiting process from fatal error: %s", esi
    api MessageBox, [hwnd],esi,ErrMsgFatal,MB_OK|MB_ICONERROR|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST
    api DestroyWindow, [hwnd]
    api ExitProcess, -1

[section text]
ErrMsgFatal:    db Program.NameDef," fatal error",0
[section code]
%endif


%if 0 ;(not working quite right yet, environment vars are not passed)
%ifdef DosVer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; () (!)
ShellCmdPrompt:

    call RestoreKeyboardHandler
    mov eax,3
    int 10h
    mov ebx,.CommandParamBlock
    mov eax,[Program.Env]
    mov [ebx],eax
    mov [ebx+4],ds
    mov eax,[Program.PspSelector]
    mov [ebx+6+4],ax
    mov eax,4B00h
    mov edx,.CommandPrompt
    int 21h
    mov eax,13h
    int 10h
    call SetKeyboardHandler.SetOnly

    ret

section data
align 4, db 0
.CommandParamBlock: dd 0,0,0
.CommandPrompt: db "\COMMAND.COM",0
section code

%endif
%endif
