;Various helper routines for BgMapper
;------------------------------
;  GetStrLength
;  MakeNumString
;  PrintAsciizString
;  MenuCreate
;  MenuAddChoices
;    MenuSetAttribs
;    MenuOpen
;    MenuConstruct
;    MenuDestroy
;    MenuAcceptChoice
;    MenuReceiveKey
;    MenuReceiveMouse
;    MenuWaitForChoice
;  DrawBorder
;  SetVideoMode
;  PaletteSet
;  PaletteDim
;  FontBlitChar
;  FontBlitString
;  FontBlitCenteredString
;  FontBlitPar
;  WriteImage
;  KeyGetPress
;  KeyScan
;  UserWait
;  MouseFunction
;  MouseGetInfo
;------------------------------

BITS 32

;============================================================
; STRING ROUTINES
;============================================================

;------------------------------
; Gets the length of a null-terminated string
;
; (esi) (eax) Saves all other regs
GetStrLength:
    PushAll edi,ecx
    mov edi,esi		;copy source for string length search
        mov ecx,8192            ;maximum length of characters
    mov eax,ecx		;make a copy of max length for later
        ;null is set in al by moving 8192 into it, which the lower byte is 0
    cld			;as always, look forward
    repne scasb		;search for the end
    sub eax,ecx		;get length
    dec eax			;minus the null at the end
    PullAll edi,ecx
    ret

;------------------------------
; Turns a 32bit number into a decimal (or other) string, writing it to edi.
;
; (eax=number, edi=destination) (ecx=offset of first digit) No regs saved
NumToString:
    mov cl,8			;maximum of eight characters
; (ecx=length)
.OfLength:
    mov ebx,10			;base of the decimal system
; (ebx=radix)
.OfRadix:
    movzx ecx,cl
    xor edx,edx			;set top 32 bits of quotient to zero
    lea edi,[edi+ecx-1]	;start from right side of number
.NextChar:
    div ebx				;divide number by the decimal base
    mov dl,[.CharTable+edx] ;get ASCII character from table
    mov [edi],dl			;output result
    dec edi				;move backwards one character
    test eax,eax			;see if we are done with the number
    jz .FillInBlanks		;nothing but zeroes left
    xor dl,dl			;set edx to zero again for next division
    dec cl				;one less character to output
    jnz .NextChar
    ret

.FillInBlanks:
    mov al,' '			;fill in with spaces
        dec ecx                         ;one less than current count
        mov ebx,ecx                     ;save copy of cl
    std				;move backwards
    rep stosb			;for number of characters remaining
        mov ecx,ebx                     ;return offset of first digit
    ret

.CharTable:     db '0123456789ABCDEF'

;------------------------------
; Prints a null terminated string with a line end.
;
; (esi=source) (esi=next byte after) No regs saved
PrintAsciizString:
    call GetStrLength
    mov edx,esi
    add esi,eax
    push dword [esi]
    mov dword [esi],240A0Dh	;cr/lf/$
    mov ah,9
    int 21h
    pop dword [esi]
    ret

%if 0
;============================================================
; SelectorAllocate (esi=base, ecx=limit) (cf=error) Saves all regs
;
; Allocate selectors for certain areas of memory
SelectorAllocate:
    PushAll edx,ecx,ebx,eax
    xor eax,eax		;DPMI function 0, allocate selector
    mov ecx,1		;only one selector
    int 31h
    jc .ErrorAllocating	;uh-oh
    mov ebx,eax		;returned selector was in eax
    mov edx,[esp]		;get base address
    shld ecx,edx,16		;put upper 16 bits into ecx (cx:dx)
    mov eax,7		;DPMI function 7, set base address
    int 31h
    jc .ErrorSetting	;could not set base
    mov eax,8		;DPMI function 8, set segment limit
    mov edx,[esp+8]		;
    shld ecx,edx,16		;put upper 16 bits into ecx (cx:dx)
    int 31h
    jc .ErrorSetting	;could not set limit
    mov eax,ebx		;move selector into eax
    add esp,byte 4		;throw away old value of eax
    PullAll edx,ecx,ebx	;restore regs
    ret

.ErrorSetting:
    mov eax,1		;DPMI function 1, free selector
    int 31h			;ebx should still contain our selector
.ErrorAllocating:
    PullAll edx,ecx,ebx,eax
    ret
%endif

;============================================================
; value should be in eax
%ifdef Debug
_DebugPrintValue:
    PushAll ebx,ecx,edx,esi,edi
    mov edi,.Text
    call MakeNumString
    FontBlitStr .Text,8,[.DebugRow],1
.NextRowDown:
    ;;;add word [.DebugRow],9
    cmp word [.DebugRow],180
    jb .LineNotBelow
    mov word [.DebugRow],1
.LineNotBelow:
    PullAll ebx,ecx,edx,esi,edi
    ret

.AndWait:
    PushAll ebx,ecx,edx,esi,edi
    mov edi,.Text
    call MakeNumString
    FontBlitStr .Text,8,[.DebugRow],1
    call UserWait
    jmp short .NextRowDown

.Text:	db '01234567'
.DebugRow:	dw 100
%endif

;============================================================
; 'Window object' code
;
WindowCreate:
    ;creates a window based on coordinates, height/width, or whatever else
    ;windows can left/right, top/bottom oriented or centered
    ;allocates space for ptr to window title, window clips, and edges
    ;returns ptr to memory
WindowGetInfo:
    ;returns window coordinates / height&width / title
WindowDestroy:
    ;deallocates resources and redraws background behind window

;============================================================
; List object code
;
ListSetChoice:
    ;sets the current choice in a list to a different one
    ;adjust variables properly
ListReceiveKey:
    ;responds to arrow keys and other scroll keys
    ;modifies variables properly
ListReceiveMouse:
    ;only responds to mouse clicks
    ;also passes on input to the scroll bar
ListDraw:
    ;generic list drawer
    ;updates the scroll bar
    ;it can either redraw the entire list
    ;redraw the list plus its border
    ;or just redraw what has changed

;============================================================
; Menu object code
;------------------------------
; MenuCreate (words expected number of choices, menu type) (cf=failure, eax=to menu structure)
; Does not preserve regs
;
; Allocate the memory necessary for menu structures and sets variables to initial values
_MenuCreate:
    ;allocate memory for menu structure
    Malloc Size_Menu,eax		;allocate memory for menu structure
    jc .End				;memory error!
    movzx ecx,byte [esp+4]		;number of expected choices in menu
    shl ecx,3			;multiply by menu entry size
    Malloc ecx,edi			;allocate memory for list structure
    jc .Error			;memory error!
    mov [eax+Menu.ListSize],ecx	;save list size
    mov esi,[FontStylePtr]		;get current font style
    mov [eax+Menu.ListPtr],edi	;save list pointer
    mov [eax+Menu.FontPtr],esi	;save font style
    mov word [eax+Menu.NumChoices],0;there are no choices yet
    mov word [eax+Menu.ChoiceHeight],9;height of an individual choice
    mov word [eax+Menu.EdgeIndent],3
    mov cl,[esp+6]			;get attributes
    mov byte [eax+Menu.Redraw],-1	;full redraw
    mov [eax+Menu.Attribs],cl	;set general attributes of menu
;	mov [esp+4],eax			;pass back ptr to menu structure
.End:
    ret
.Error:
    Free eax			;free menu structure
    stc				;flag error
    ret

;------------------------------
; MenuAddChoices (dwords ptr to menu structure, ptr to new list, word number of choices) (**total number of choices)
; Does not preserve regs
;
; Adds (appends) a list of choices to an existing menu structure
; Note that a menu can not hold more than 255 choices - not like that would ever happen
; though.
;
_MenuAddChoices:
    mov ebx,[esp+4]			;get menu structure
    mov esi,[esp+8]			;get new list pointer
    mov edi,[ebx+Menu.ListPtr]	;get list structure
    movzx ecx,byte [esp+12]		;get number of new choices
    test ecx,ecx			;make sure we have some choices
    jz .End			;if no choices, don't bother
    movzx edx,byte [ebx+Menu.NumChoices];get current number of choices
    lea eax,[ecx+edx]		;get old choices plus new ones
;	jo ...				;in case over 255 choices added
    shl eax,3			;multiply total choices by eight
    cmp [ebx+Menu.ListSize],eax	;if space needed is greater than size then expand it
    jae .EnoughListRoom		;already enough space so just continue
    cmp cl,8			;reallocate only for every eight choices
    ja .EnoughChoices		;there are more than enough
    lea eax,[edx*8+64]		;get new size
.EnoughChoices:
    Realloc edi,eax,edi		;reallocate list structure to new size
    jc near .End			;memory error!
    mov [ebx+Menu.ListPtr],edi	;save new list pointer
.EnoughListRoom:
    lea edi,[edi+edx*8]		;get to choice directly after last choice
    lea eax,[edx+ecx]			;add new choices to old ones
    mov [ebx+Menu.NumChoices],al	;save new total number of choices
    cld					;move forward!
.NextChoice:
    movsd				;transfer choice string
    movsw				;transfer attributes and ID
    add edi,byte 2			;menu list choices are eight bytes
    dec cl				;do until no more choices
    jnz .NextChoice
.End:
    clc
    ret

;------------------------------
; MenuSetChoiceAttribs (dword ptr to menu structure, words basechoice, count, attributes) (cf=error)
; Does not preserve regs
;
; Sets the attributes of a single choice or several choices, depending on count
; It might be easier to simply parse all the choices and then set the attributes for each one
; or a group of ones. This is mainly meant for setting which choices are disabled, but could
; also set the divider and submenu option.
; It starts from the last choice and works forward if basechoice = -1 (255)
; Attributes consist of an AND mask (high) and an OR mask (low). A value of FF00 would not
; change anything.
;
_MenuSetChoiceAttribs:
    mov ebx,[esp+4]			;get menu structure
    movzx eax,byte [esp+8]		;get choice to be set or group base
    mov cl,[esp+10]		;get count of choices
    mov ch,[ebx+Menu.NumChoices];get number of menu choices
    cmp al,255			;is last choice to be set?
    jne .StartFromBase	;no, start from base given
    mov al,ch			;set choice to be set to last choice
    sub al,cl			;start on first choice
.StartFromBase:
    cmp al,ch				;check that base is not past last choice
    jae .ErrorEnd			;just end (carry will be set)
    xor dl,dl				;set error indicator to zero
    add cl,al				;add count to choice to get last choice
    jc .SetLastChoice			;last choice went past number of choices
    cmp cl,ch				;check that last choice is not past last choice
    jbe .CountOkay		;count did not go past last choice
.SetLastChoice:
    inc dl				;set error
    mov cl,ch				;set last choice to number of choices
.CountOkay:
    mov edi,[ebx+Menu.ListPtr]	;get ptr to menu list
    lea edi,[edi+eax*8]		;get address of choice in list to be set
    sub cl,al				;get loop count by subtracting first from last
    jz .End				;zero choices to add (not considered an error)
    mov ax,[esp+12]			;get attributes
.NextChoice:
    and [edi+MenuList.Attribs],ah	;filter out attributes
    or [edi+MenuList.Attribs],al	;set attributes
    add edi,byte Size_MenuList	;next choice
    dec cl
    jnz .NextChoice
    shr dl,1				;get carry by testing error indicator
.End:						;if set, not all choices were changed
    ret
.ErrorEnd:
    stc
    ret

;------------------------------
; MenuOpen (ptr menu structure, words toprow, leftcol, mode) (dword to dimensions)
; Does not preserve regs
; *not finished
;
; Constructs the menu and depending on whether it to be a full or embedded menu
; Sets the menu's top row and left column based on the info passed to it
; It will save the background and let MenuDraw know that it should draw the back border
; before drawing the menu choices
;
;MenuOpen:
;	ret

;------------------------------
; MenuConstruct (ptr menu structure, words TopRow, LeftCol) (ax=width, dx=height)
; Does not preserve regs
;
; 'Builds' the menu by figuring its height and width by each of the choices in it
;
MenuConstruct:
    mov ebx,[esp+4]			;get menu structure
    mov edi,[ebx+Menu.ListPtr]	;get list structure
    xor ecx,ecx			;set menu attributes to nada
    mov edx,3			;set menu height
    mov cl,[ebx+Menu.NumChoices]	;get current number of choices
    mov [ebx+Menu.ChoiceWidth],word 1	;set initial menu width
    test cl,cl			;make sure there some choices
    jz .End				;nope, just skip to end
.NextChoice:
    test ch,MenuListDivider		;check whether last choice had a divider
    jz .NoDivider			;choice had none
    add edx,byte 5			;add divider pixel size
    .NoDivider:
    mov [edi+MenuList.Pos],dx	;save choices top row to position
    mov esi,[edi+MenuList.Text]	;get text ptr
    call GetStrLength		;get choice string length (in ax)
    shl ax,3			;multiply string length by character width
    cmp [ebx+Menu.ChoiceWidth],ax		;increase menu width if choice will not fit
    jae .WideEnough			;menu is already wide enough, so don't worry about it
    mov [ebx+Menu.ChoiceWidth],ax		;adjust menu width to fit choice
    .WideEnough:
    mov ch,[edi+MenuList.Attribs]	;get new choice attributes and ID
    add edi,byte Size_MenuList	;next choice
    add edx,[ebx+Menu.ChoiceHeight];add choice height to menu height
    dec cl				;do until no more choices
    jnz .NextChoice
.End:
    mov ax,[ebx+Menu.ChoiceWidth]
    add ax,6				;add size borders
    add dx,2				;add bottom border
    mov [ebx+Menu.Width],ax		;set final width
    mov [ebx+Menu.Height],dx	;adjust total menu height

    mov ecx,[esp+8]			;get top row and left column
    test cx,cx
    jns .DontCenterVrt
    add cx,dx				;get given height - menu height
    neg cx
    shr cx,1
.DontCenterVrt:
    ror ecx,16				;get left column
    test cx,cx
    jns .DontCenterHrz
    add cx,ax				;get given width - menu height
    neg cx
    shr cx,1
.DontCenterHrz:
    rol ecx,16				;adjust order to top row/left column
    mov [ebx+Menu.TopRow],ecx	;set top row and left column
    mov [esp+8],ecx
    ret

;------------------------------
; MenuDestroy (dword ptr to menu structure) (cf=failure)
; Does not preserve regs, except eax
;
; Frees the memory used by the menu structures
;
_MenuDestroy:
    push eax				;save menu choice
    ;call _MenuClose			;restore background and free image memory
    mov esi,[esp+8]			;get menu structure
    mov edi,[esi+Menu.ListPtr]	;get list pointer
    Free edi			;free memory for list structure
    Free esi			;free memory for menu structure
    pull eax				;retrieve menu choice
.End:
    ret

;------------------------------
; MenuClose (Ptr menu structure) ()
;
; Restores the background if a full menu was created, otherwise returns
; Frees the memory used to hold that image
;
;_MenuClose:
;	nop
;	ret

;------------------------------
; MenuDraw (Ptr menu structure) ()
;
; Draws the menu border and menu choices
; starting with background menu face, then dividers, then choices
; It has three modes:
; A complete redraw, menu and all choices
; Full redraw, draw all choices
; and partial redraw that only draws choices that have changed
; Resets priorchoice to current choice
;
MenuDraw:
    call Pointer.Hide				;hide mouse pointer
    mov ebx,[esp+4]					;get menu structure
    test byte [ebx+Menu.Redraw],MenuDrawComplete	;complete redraw?
    jz near .ChoicesOnly				;do not draw background, just choices
;draws the menu border and face
;	cmp [ebx+Menu.Attribs],MenuAttribEmbedded
    sub esp,byte 10					;allocate space for call
    mov [esp+8],word 2				;convex border with solid face
    mov dx,[ebx+Menu.TopRow]			;get menu's top row
    mov cx,[ebx+Menu.LeftCol]			;get menu's left column
    mov [esp],dx					;set top row
    mov [esp+4],cx					;set left column
    add dx,[ebx+Menu.Height]
    add cx,[ebx+Menu.Width]
    dec edx
    dec ecx
    mov [esp+2],dx					;set bottom row
    mov [esp+6],cx					;set right column
    call _DrawBorder				;draw background menu face
    add esp,byte 10					;free stack space
    mov ebx,[esp+4]					;get menu structure again

;loop through all the choices checking for dividers
;draws a horizontal bar wherever one is found
    mov cl,[ebx+Menu.NumChoices]		;get number of menu choices
    mov esi,[ebx+Menu.ListPtr]		;get ptr to menu choice list
    sub cl,1				;draw one less than the total number of choices
    jc near .End				;end if no choices in menu
    jz near .NextRow			;if the menu had just one choice, just show it
    sub esp, byte 14			;make variable storage for words and DrawLine
    mov [esp+10],cl				;save count
    mov dx,[ebx+Menu.TopRow]		;get menu's top row
    mov cx,[ebx+Menu.LeftCol]	;get menu's left column
    add cx,[ebx+Menu.EdgeIndent]
    mov [esp+4],cx				;set left column
    add dx,[ebx+Menu.ChoiceHeight]	;add choice height to get bottom row
    add cx,[ebx+Menu.ChoiceWidth]		;add width to get right
    dec cx
    inc edx
    mov [esp+12],dx				;set top row for dividers
    mov [esp+6],cx				;set right column
.NextChoice:
    test byte [esi+MenuList.Attribs],MenuListDivider ;choice has a divider?
    jz .NoDivider					;no divider
    ;mov [esp+14],esi				;save menu choice source ptr
    add dx,[esi+MenuList.Pos]			;get choice's row position
    mov [esp+8],word ColorLrDark       ;set color dark gray
    mov [esp],dx					;set top row
    mov [esp+2],dx					;set bottom row
    call _DrawBox
    ;add dword [esp],10001h			;next top and bottom row
    inc word [esp]					;next top row
    inc word [esp+2]				;next bottom row
    mov [esp+8],word ColorLrLight      ;set color to light gray
    call _DrawBox
    ;mov esi,[esp+14]				;get menu choice source again
    mov dx,[esp+12]					;get menu's top row
    .NoDivider:
    add esi,byte Size_MenuList		;next choice
    dec byte [esp+10]				;do until no more choices
    jnz .NextChoice					;more choices left
    add esp,byte 14					;free stack variable space
    mov ebx,[esp+4]				;get menu structure ptr again
    xor byte [ebx+Menu.Redraw],MenuDrawComplete	;turn off complete redraw

;redraw choices, either all or just the two that have changed
.ChoicesOnly:
    test byte [ebx+Menu.Redraw],MenuDrawFull
    jnz .Full								;redraw all choices

;a full redraw actually starts with the last choice and go backwards for simplicity
.Full:
    xor byte [ebx+Menu.Redraw],MenuDrawFull	;turn off full choice redraw
    movzx ecx,byte [ebx+Menu.NumChoices]	;get count
    dec ecx					;start out with one less than total choices
    js .End					;are there choices to display?
.NextRow:
    call .PrintChoice			;print out choice
    dec ecx					;was last choice printed?
    jns .NextRow				;no negative sign so more choices to go
    mov cl,[ebx+Menu.CurChoice]		;get current choice
    mov [ebx+Menu.PriorChoice],cl		;set prior choice to current choice
.End:
    call Pointer.Show
    ret

; ecx is expected to contain the choice to display, ebx points to the menu structure
; they are preserved, all other registers are not
.PrintChoice:
    mov edi,[ebx+Menu.ListPtr]		;get ptr to list structure
    lea esi,[edi+ecx*8]			;get ptr to choice in list
    mov al,[esi+MenuList.Attribs]		;get attributes
    and eax,MenuListDisabled		;mask out all but disabled flag bit
    cmp [ebx+Menu.CurChoice],cl		;is choice to be drawn the current choice?
    jnz .NotCurrentChoice			;no
    or al,1					;it is the active choice, set to highlighted color
    .NotCurrentChoice:
    PushAll ebx,ecx				;save menu structure ptr and counter
    lea eax,[MenuColors+eax*8]		;get color set
    mov [FontColorsPtr],eax			;set current font color set
    mov dx,[ebx+Menu.TopRow]		;get menu's top row
    mov cx,[ebx+Menu.LeftCol]		;get menu's left column
    add dx,[esi+MenuList.Pos]		;add choice's vertical position
    add cx,[ebx+Menu.EdgeIndent]		;add indent to column
    mov esi,[esi+MenuList.Text]		;get ptr to choice text
    call GetStrLength			;find choice's text length (in ax)
    FontBlitStr esi, ax, dx, cx;print out the choice
    PullAll ebx,ecx				;restore menu structure ptr and counter
    ret

;------------------------------
; MenuSetCurrentChoice (dword ptr to menu structure, word new choice) (al=change, ah=choice)
; Does not preserve regs
;
; Sets the current choice in a menu, which can be used by the main program or other menu
; routines. If it is called by other menu routines, the choice number is passed on to it,
; otherwise a choice number or a choice's ID can be passed to it, depending on bit eight of
; the new choice passed on (set=by number, clear=by ID). If the menu is staticly created,
; passing absolute choice numbers is fine, but otherwise ID's should be passed since the
; choices can be moved around and passing a number might set the wrong choice.
; Handy if a menu should be opened starting at a specific choice.
;
_MenuSetCurrentChoice:
    mov ebx,[esp+4]
    movzx ecx,byte [esp+8]		;get new choice
    xor eax,eax			;clear return status
    test byte [esp+9],1		;are we setting by choice number or choice ID?
    jnz .ByChoiceNum2		;by the choice's number
;otherwise by ID, loop through choices looking for the one with the desired ID
    mov ah,cl			;copy ID to ah
    movzx ecx,byte [ebx+Menu.NumChoices] ;get total count of choices
    mov esi,[ebx+Menu.ListPtr]	;get ptr to menu choices
    test ecx,ecx			;are there any choices?
    jz .NoChange			;there aren't any choices to search
    dec cl				;start out with one less than total choices
    lea esi,[esi+ecx*8]		;get address of last choice
.NextChoice:
    cmp [esi+MenuList.ChoiceID],ah	;does this choice have the desired ID
    je .IdMatch			;yes, so onward to setting the current choice
    sub esi,byte Size_MenuList	;previous choice
    dec ecx				;has the last one been checked?
    jns .NextChoice			;no negative sign so more choices to go
.NoChange:				;search failed, no choice had the desired ID
    ret
.ByChoiceNum:				;called only from other menu routines
    and al,~MenuChngSelect
.ByChoiceNum2:				;status is already clear
    cmp cl,[ebx+Menu.NumChoices]	;is new choice is out of range?
    jae .NoChange		;greater than or equal to total choices
    ;jae .ChoiceError		;greater than or equal to total choices
.IdMatch:				;skip the last choice check
    cmp [ebx+Menu.CurChoice],cl	;is new choice different than current choice?
    je .NoChange			;choices are the same
    mov esi,[ebx+Menu.ListPtr]	;get ptr to menu choice list
    mov [ebx+Menu.CurChoice],cl	;set current choice to new choice
    or al,MenuChngSelect		;let caller know the choice has changed
    mov ah,[esi+ecx*8+MenuList.ChoiceID];get choice's numeric ID and return it
    ret
;.ChoiceError:				;!? Choice given is out of bounds
;	movzx ecx,byte [ebx+Menu.NumChoices] ;get total count of choices
;	sub ecx,byte 1			;one less choice than the total
;	jnc .IdMatch			;if there was at least one choice then return
;	ret

;------------------------------
; MenuAcceptChoice (ebx=ptr to menu structure, ecx=choice) (al=change, ah=choice)
; Does not preserve regs
;
; Returns the necessary values for a choice being accepted. It also will not return a choice
; as being accepted if it is disabled.
; Only called by other menu routines
;
MenuAcceptChoice:
    and al,~MenuChngAccept			;clear return status
    cmp cl,[ebx+Menu.NumChoices]		;check if new choice is out of range
    jae .NoChange				;is greater than or equal to total choices
    mov esi,[ebx+Menu.ListPtr]		;get ptr to menu choice list
    test byte [esi+ecx*8+MenuList.Attribs],MenuListDisabled
    jnz .NoChange				;do not allow disabled choices to be accepted
    or al,MenuChngAccept			;flag choice was accepted
    mov ah,[esi+ecx*8+MenuList.ChoiceID]	;get choice's numeric ID and return it
.NoChange:
    ret

;------------------------------
; MenuReceiveKey (dword ptr to menu structure, word key) (al=change, ah=choice)
;
; Decides what to do with key input directed to the menu
; Either selects a different choice or lets the caller know a choice was chosen
; Calls MenuSetCurrentChoice to change the choice and return status
; If the choice was changed, al contains a flag that indicates a change and ah contains the
; byte ID of that choice, otherwise it is null
;
MenuReceiveKey:
    mov ebx,[esp+4]				;get menu structure
    xor eax,eax				;set return value to nada
    movzx ecx,byte [ebx+Menu.CurChoice]	;get current choice with top 24 bits zeroed
    mov dx,[esp+8]                      ;get keypress

.0:	cmp dx,'P'<<8				;compare keypress to down key
    jne .1
    inc cl					;one choice down
    cmp [ebx+Menu.NumChoices],cl		;choice greater than last one?
    ja near _MenuSetCurrentChoice.ByChoiceNum ;no, choice is in range
    xor cl,cl				;set choice to first one
    jmp _MenuSetCurrentChoice.ByChoiceNum
.1:	cmp dx,'H'<<8				;up key?
    jne .2
    test cl,cl				;are we on the first choice?
    jnz .ChoiceNotFirst			;no, choice is in range
    mov cl,[ebx+Menu.NumChoices]		;set choice to number of choices
    .ChoiceNotFirst:
    dec cl					;one choice up
    jmp _MenuSetCurrentChoice.ByChoiceNum
.2: cmp dl,' '                  ;is key space or above?
    jb .3                       ;no if control character
    cmp dl,'~'                  ;is key tilde or below?
    ja .4                       ;no if extended character, ignore keypress
    inc cl                      ;start one choice after current choice
    mov ah,[ebx+Menu.NumChoices];get number of choices
    cmp cl,ah                   ;starting choice isn't past last choice?
    jb .CountOkay				;nope, just continue with current choice
    xor cl,cl                   ;set starting choice to zero
    .CountOkay:
    mov esi,[ebx+Menu.ListPtr]  ;get ptr to list of choices
    lea esi,[esi+ecx*8]			;get current choice in list
    mov ch,ah                   ;make a copy for count
    sub ah,1                    ;one fewer choices than total
    jc .End                     ;total choices is zero, just end
    call .MakeUppercase			;for comparison in loop
    mov dh,dl                   ;move letter to dh
    .NextChoice:
    mov edi,[esi+MenuList.Text] ;get choice's text ptr
    mov dl,[edi]				;get first letter of choice
    call .MakeUppercase
    cmp dl,dh                   ;compare the first letter of the choice with KeyPress
    je .ChoiceMatch				;letters match
    .ReturnFromMatch:
    cmp cl,ah                   ;if last choice has been reached, wrap around to the first
    je .WrapChoice
    inc cl                      ;next choice number
    add esi,Size_MenuList       ;next choice
    .ReturnFromWrap:
    dec ch                      ;one less choice to check
    jnz .NextChoice
    test al,al                  ;is key match flag set?
    jz .End                     ;no, so just end
    movzx ecx,byte [.ChoiceFound]
    jmp MenuAcceptChoice

  .ChoiceMatch:
    test al,al                  ;if this is the second choice matched
    jnz .ChoiceMatched          ;set as current choice
    mov [.ChoiceFound],cl       ;otherwise, store choice found for later
    or al,1                     ;flag a choice find
    test byte [esi+MenuList.Attribs],MenuListDisabled ;disabled choice?
    jz .ReturnFromMatch         ;return to loop to look for more
  .ChoiceMatched:
    movzx ecx,byte [.ChoiceFound];get choice number that was
    jmp _MenuSetCurrentChoice.ByChoiceNum
  .WrapChoice:
    mov esi,[ebx+Menu.ListPtr]  ;set choice in list to first one
    xor cl,cl                   ;set choice to first one
    jmp short .ReturnFromWrap
.3: cmp dl,13                   ;Enter pressed?
    je near MenuAcceptChoice    ;yes, current choice was accepted
.4:
.End:
    ret                         ;simply return

.MakeUppercase:
    cmp dl,'z'
    ja .AlreadyUppercase
    cmp dl,'a'
    jb .AlreadyUppercase
    sub dl,32
.AlreadyUppercase:
    ret

.ChoiceFound:	db 0

;------------------------------
; MenuReceiveMouse (dword ptr to menu structure, word mouse row, presses)
; (al=change, ah=choice)
; Does not preserve regs
;
; Decides how to react to mouse input, both movements and clicks
; Moving the mouse over the menu will change to the choice the mouse is over
; Reduced mouse coordinates are passed onto it rather than it directly checking the
; coordinates
;
MenuReceiveMouse:
%if Debug > 1
    mov [FontColorsPtr],dword FontColors2
    inc word [.MessageWasCalled]
    FontBlitStr .MessageWasCalled,8,170,1
%endif
    mov ebx,[esp+4]				;get menu structure
    mov ax,[esp+8]				;get row
    cmp byte [ebx+Menu.NumChoices],0 ;are there any choices in the menu?
    jz near .NoChange			;just return without any change
    movzx ecx,byte [ebx+Menu.CurChoice]	;get current menu choice
    mov esi,[ebx+Menu.ListPtr]  ;get ptr to menu choice list
;check pointer to see if it is already over the current choice
    test ax,ax
    js short .NoChange
    mov dx,[esi+ecx*8+MenuList.Pos] ;get current menu choice's position (toprow)
    cmp ax,dx                   ;is pointer above choice
    jb .CheckChoices			;look for another choice
    add dx,[ebx+Menu.ChoiceHeight] ;get choice's bottom row
    cmp ax,dx                   ;is the pointer below choice
    jge .CheckChoices			;look for another choice
    xor eax,eax                 ;set return value to null
;check for mouse button presses - if over a valid choice
.CheckButtons:
    test byte [esp+10],1			;check for left mouse button
    jz .End
%if Debug > 1
    PushAll eax,ebx,ecx
    inc word [.MessageChange]
    FontBlitStr .MessageChange,8,190,1
    PullAll eax,ebx,ecx
%endif
    jmp MenuAcceptChoice			;accept the choice
.NoChange:
    xor eax,eax
.End:
    ret

;it looks through all the choices for the choice the pointer is closest to
;starting with last choice and going towards the first
.CheckChoices:
%if Debug > 1
    PushAll eax,esi,ebx
    inc word [.MessageChecked]
    FontBlitStr .MessageChecked,8,180,1
    PullAll eax,esi,ebx
%endif
    movzx ecx,byte [ebx+Menu.NumChoices];get total menu choices
    dec ecx					;start out with one less choice than total
    lea esi,[esi+ecx*8]			;get address of last choice
.NextChoice:
    cmp ax,[esi+MenuList.Pos]		;is pointer greater than choice's position
    jae .CheckHeight			;exit loop and check if pointer is not too low
    sub esi,byte Size_MenuList		;previous choice
    dec ecx					;has the last one been checked?
    jns .NextChoice				;no negative sign so more choices to go
    jmp short .NoChange			;!? somehow all choices were checked but no matches
.CheckHeight:
    sub ax,[ebx+Menu.ChoiceHeight]		;get pointer below menu choice's position
    cmp ax,[esi+MenuList.Pos]		;is choice's position less or equal to pointer
    jge .NoChange				;pointer is below choice
    xor eax,eax
    call _MenuSetCurrentChoice.ByChoiceNum ;set the current choice to under the pointer
    jmp .CheckButtons

%if Debug > 1
.MessageWasCalled: db '00 Call '
.MessageChecked:	db '00 Check'
.MessageChange:	db '00 Change'
%endif

;------------------------------
; MenuWait (esi=ptr to menu list structure) (cf=cancel or error, al=choice)
MenuCreateAndWait:
    push esi
    mov dword [FontStylePtr],FontOutline ;set font for menu
    MenuCreate [esi+MenuStructChoices],0 ;allocate space for standard menu
    jc .Error                           ;if error creating
    mov esi,[esp]
    push word  [esi+MenuStructChoices]  ;number of choices
    push dword [esi+MenuStructList]     ;ptr to new choices to add
    push eax                            ;ptr to menu structure
    call _MenuAddChoices
    mov esi,[esp+10]
    push dword [esi+MenuStructPosition] ;row/col for MenuWaitForChoice
    push dword [esi+MenuStructPreChoice]
    push dword [esp+8]          ;menu ptr
    call _MenuSetCurrentChoice
    pop eax                     ;get menu ptr
    mov [esp],eax
    call MenuWait               ;wait for user to make a choice
    lahf                        ;save flags
    call _MenuDestroy           ;free up the menu we don't need
    add esp,byte 18             ;restore stack now
    pop esi
    sahf                        ;retrieve flags for carry bit
    jc .Cancel
    mov [esi+MenuStructPreChoice],al
.Cancel:
    ret
.Error:
    add esp,byte 4
    stc
    ret

;------------------------------
; MenuWait (dword ptr to menu structure, words toprow, leftcol) (cf=cancel, ax=status:choice)
; Does not preserve regs
;
; Waits for user to make a choice, and then returns it to the caller
;
MenuWait:
    push dword [esp+8]	;top row/left column
    push dword [esp+8]	;menu ptr
    call MenuConstruct	;(ax=width, dx=height)
    call MenuDraw
    add esp,byte 4
    pop dword [esp+8]

    call MouseClearChanges	;in case any buttons are down
.InputLoop:
    call KeyGetPress		;any keys pressed?
    jc .DecideKey			;guess so
    call MouseGetInfo		;mouse moved? any clicks?
    test al,al			;check return value
    jz .InputLoop			;nothing changed
    mov ax,[MouseRow]		;get mouse's row
    sub ax,word [esp+8]	;subtract menu's top row
    push word [MouseBtnsPressed]
    push ax				;pass relative mouse row
    push dword [esp+8]		;main menu structure
    call MenuReceiveMouse		;let menu respond to input
    add esp,byte 8
    jmp short .Change		;in case of a change
.DecideKey:
    cmp al,27			;escape pressed?
    je .ErrorEnd
    push ax			;pass key press
    push dword [esp+6]	;pass menu structure
    call MenuReceiveKey
    add esp,byte 6

.Change:
    test al,MenuChngAccept		;user chose a menu choice?
    jnz .EndLoop			;yes, so quit the main menu
    test al,MenuChngSelect		;was the current choice changed?
    jz .InputLoop			;no, so continue loop
    push dword [esp+4]		;main menu structure
    call MenuDraw			;update screen
    add esp,byte 4
    jmp short .InputLoop		;continue loop
.EndLoop:
    xchg al,ah			;swap status and choice
    clc				;choice was selected, no cancel
    ret
.ErrorEnd:
    xor eax,eax
    stc				;error creating menu or user canceled
    ret

;============================================================
; Gui borders
;------------------------------
; For drawing all those windows, menus, buttons, and borders
;
; DrawBorder (words TopRow, BtmRow, LeftCol, RiteCol, Mode)
; Does not preserve regs
;
_DrawBorder:
    mov ax,[GuiColorTop]
    mov bx,[GuiColorBottom]
    test byte [esp+12],1	;is border in or out?
    jz .ConvexBorder	;border is normal
    xchg ax,bx		;swap border colors
.ConvexBorder:
    push bx			;save two colors: forecolor, backcolor
    push ax

;Left border
    mov dx,[esp+12]		;get leftcol
    mov cx,[esp+10]		;get btmrow
    mov bx,[esp+8]		;get toprow
    push ax			;set box forecolor
    push dx			;set box ritecol to leftcol
    push dx			;set box leftcol
    push cx			;set box btmrow
    push bx			;set box toprow
    call _DrawBox		;destroys all regs!

;Right border
    mov ax,[esp+12]		;get backcolor
    mov [esp+8],ax		;set box backcolor
    mov dx,[esp+24]		;get ritecol
    mov [esp+4],dx		;set box leftcol to ritecol
    mov [esp+6],dx		;set box ritecol
                ;don't bother changing toprow or btmrow
    call _DrawBox

;Top border
    mov ax,[esp+10]		;get forecolor
    mov [esp+8],ax		;set box forecolor
    mov bx,[esp+18]		;get toprow
    mov dx,[esp+22]		;get leftcol
    mov [esp],bx		;set box toprow
    mov [esp+2],bx		;set box btmrow to toprow
    mov [esp+4],dx		;set box leftcol
    mov dx,[esp+24]		;get ritecol
    mov [esp+6],dx		;set box ritecol

    call _DrawBox

;Bottom border
    mov ax,[esp+12]		;get backcolor
    mov [esp+8],ax		;set box backcolor
    mov bx,[esp+20]		;get btmrow
    mov [esp],bx		;set box toprow to btmrow
    mov [esp+2],bx		;set box btmrow
                ;don't bother changing leftcol or ritecol
    call _DrawBox

;Inner area (if requested)
    test byte [esp+26],2	;is border filled in?
    jz .NoInnerArea		;just an outline
    add esp,byte 10		;clear prior stack
    mov dx,[esp+14]		;get ritecol
    mov cx,[esp+12]		;get leftcol
    mov bx,[esp+10]		;get btmrow
    mov ax,[esp+8]		;get toprow
    dec dx			;move box inside border by one pixel
    inc cx
    dec bx
    inc ax
    push word [GuiColorFront];set box color to window area
    push dx			;set box ritecol
    push cx			;set box leftcol
    push bx			;set box btmrow
    push ax			;set box toprow
    call _DrawBox
.NoInnerArea:

    add esp,byte 14		;clear stack and two saved colors
    ret

;============================================================
; VIDEO SETTING ROUTINES
;============================================================
; These are not done yet

;------------------------------
SetFullVideoMode:
    call SetVideoMode
    ;if ScreenListMode=0
    mov dword [ScreenPalettePtr],ScreenPalette
.End:
    ret

;------------------------------
; Silly set video mode - not done yet at all!
; When it supports VBE2, then I'll be done :-)
; Hopefully it will be 640x480:65536 someday, me hopes
;
; (*) - Preserves all regs
SetVideoMode:
.DefaultGraphics:
    PushAll eax,ebx
    mov ax,13h			;For now 320x200:256 will do
    int 10h				;VGA BIOS function 0, set screen mode
    mov [ScreenPtr],dword 0A0000h	;video memory
    mov ax,[ScreenModesInfo+4]	;get bits per pixel
    mov [ScreenBits],ax		;set current bits
    mov ax,[ScreenModesInfo]	;get screen mode height
    mov bx,[ScreenModesInfo+2]	;get screen mode width
    mov [ScreenHeight],ax		;set current height
    mov [ScreenWidth],bx		;set current width
    jmp short ResetScreenClips.ByRegs
                    ;reset clipped regions to maximum screen dimensions
.Text:
    mov ax,3	;boring text mode
    int 10h		;VGA BIOS function 0, set screen mode
    ret

;------------------------------
; ResetScreenClips () - Preserves all regs
;
ResetScreenClips:
    PushAll eax,ebx
    mov ax,[ScreenHeight]		;screen mode height
    mov bx,[ScreenWidth]		;screen mode width
.ByRegs:				;called only from SetVideoMode
    dec ax				;clip is one less than size
    dec bx
    shl eax,16			;zero out bottom 16 bits
    shl ebx,16
    mov [ScreenClipTop],eax		;set both top and bottom
    mov [ScreenClipLeft],ebx	;set both left and right
    PullAll eax,ebx
    ret

;------------------------------
; PaletteSet (al=first color, cx=number of colors) () - Preserves all other regs
;
PaletteSet:
    PushAll esi,edx
    ;movzx eax,al               ;zero top 24 bits
    xor eax,eax                 ;a cheap hack for now
    mov ecx,256
    mov esi,[ScreenPalettePtr];get pointer to palette
    test esi,esi		;has one been allocated?
    jz .End			;croak if not
    mov edx,3C8h    ;palette index port
    out dx,al		;tell VGA adapter the color index to start setting
    add esi,eax     ;get starting index in palette by
    inc edx         ;select the VGA color palette port (3C9h)
    lea esi,[esi+eax*2] ;multiplying index by three (esi+(eax+eax*2))
    ;lea ecx,[ecx+ecx*2] ;do the same with count
    cld			;as always read forward
.Next:
    lodsb
    out dx,al       ;port accepts consecutive bytes of color values in RGB order
    lodsb
    out dx,al       ;port accepts consecutive bytes of color values in RGB order
    lodsb
    out dx,al       ;port accepts consecutive bytes of color values in RGB order
    loop .Next
.End:
    PullAll esi,edx
    ret

;------------------------------
; PaletteDim () () - Does not save regs
;
; Dims the 256 color palette by half
; Does not update the screen palette
;
PaletteDim:
    mov ecx,768/4
    mov esi,[ScreenPalettePtr];get pointer to palette
    test esi,esi		;has one been allocated?
    jz .End			;croak if not
.NextColor:
    mov eax,[esi]
    shr eax,1
    and eax,7F7F7F7Fh
    mov [esi],eax
    add esi,byte 4
    dec ecx
    jnz .NextColor
.End:
    ret

;------------------------------
; PaletteSetGuiColors () - Preserves all regs
;
; Sets the 256 color palette to include the GUI colors
; Does not update the screen palette
;
PaletteSetGuiColors:
    PushAll edi,esi,ecx
    mov edi,[ScreenPalettePtr] ;dest is the palette
    test edi,edi		;has one been allocated?
    jz .End			;croak if not
    mov esi,GuiColorsData	;source is the color constants
    mov ecx,GuiColorsNum	;number of GUI colors
.NextColor:
    movsw
    movsb
    add edi,byte 3*16-3	;jump forward 16 rgb color entries
    dec ecx
    jnz .NextColor
.End:
    mov [GuiColorBlack],word ColorLrBlack
    mov [GuiColorDark],word ColorLrDark
    mov [GuiColorGray],word ColorLrGray
    mov [GuiColorLight],word ColorLrLight
    mov [GuiColorWhite],word ColorLrWhite
    mov [GuiColorBack],word ColorLrGray
    mov [GuiColorFront],word ColorLrGray
    mov [GuiColorTop],word ColorLrLight
    mov [GuiColorBottom],word ColorLrDark
    PullAll edi,esi,ecx
    ret

;------------------------------
; PaletteColormap () - Preserves all regs
;
; Takes the current palette (only for 256 color mode) and the SNES palette and remaps the
; colors used by GUI or background color constant to the nearest ones in the current
; palette, yielding a colormap
;
;PaletteColormap:
;	ret

;============================================================
; GRAPHICS ROUTINES
;============================================================
; The caller need not know what video mode the display is using or what the dimensions are
; This is all taken into consideration by these functions
; Of course for now there is only one possible video mode!

;------------------------------
; (ax=color, di=dest) () - Preserves all regs
;
; Meant to be used by the line drawer (if I make it)
;
align 16			;extra speed??
_DrawPixel:
    push edi
    and edi,0FFFFh		;fit into 64k
    mov [edi+0A0000h],al	;single pixel written
    pull edi
    ret

;------------------------------
; DrawPixelAt (ax=color, ebx=row, ecx=col) () - Preserves all regs
;
; Does not clip (for speeds sake)
;
align 16			;extra speed??
_DrawPixelAt:
    PushAll edi,ebx
    mov edi,ebx		;make a copy
    shl ebx,6		;multiply by 64
    shl edi,8		;now by 256
    add edi,ebx		;multiplied by 320
    add edi,ecx		;add left column
    and edi,0FFFFh		;fit into 64k
    mov [edi+0A0000h],al	;single pixel written
    PullAll edi,ebx
    ret

;------------------------------
; FontBlitChar (words Char, TopRow, LeftCol, dwords FontSet, ColorTable) ()
; Does not save regs (there is a reason for this though)
;
; The last two parameters are optional and usually set to the default
; It only draws 8x8 characters, but it would not be too hard to allow other sizes
; FontSet is not used and currently defaults to FontStylePtr
; Will someday support 15bit blitting and clipping too
;
;	esi=char bitmap in font set
;	edi=screen destination
;	ebx=four color table
;	cl=roll (not used yet)
;	ch=col
;	cl2=row (the upper bits 16-23)
;	ax=masked pixels
;	dx=char bitmap row
;	ebp=wrap width
align 16			;extra speed??
_FontBlitChar:
    mov al,[esp+4]		;get character
        movzx edx,word [esp+6]  ;get toprow
        movzx ecx,word [esp+8]  ;get leftcolumn
;(al=character, edx=top row,ecx=left column)
.ByRegs:				;only called if regs are already setup!
    movzx eax,al		;make sure is in range 0-255
    shl eax,4		;multiply by 16 (16 bits per row)
    mov ebx,[FontStylePtr]	;the current font being used
    lea esi,[ebx+eax]	;point character bitmap in set
        ;movzx edx,dx            ;row
        ;movzx ecx,cx            ;left column
    mov edi,edx		;make a copy of row
    shl edx,6		;multiply by 64
    shl edi,8		;multiply by 256
    add edi,edx		;64+256=320
    add edi,ecx		;add left column
    and edi,0FFFFh		;just in case of a bad parameter
;	add edi,[ScreenPtr]
    add edi,0A0000h		;set to video memory
    push ebp		;save base pointer
    mov ebx,[FontColorsPtr]	;for now
    xor eax,eax		;zero out upper bits for loop
    mov ebp, 320-8		;wrap width (for now)
    mov cl,8		;8 rows to do
    cld			;as always, go forward

.NextRow:
    rol ecx,16		;get access to preroll and column counter
    mov ch,8		;8 columns to do
    mov dx,[esi]		;grab first row of char bitmap (16bits)
    add esi,byte 2		;for next row
;	rol edx,cl		;preroll for when off screen
.NextCol:
        mov eax,edx             ;make a copy
    shr edx,2		;adjust for next pixel
        and eax,3               ;filter bottom two bits
    jz .SkipCol		;skip to next pixel
    mov al,[ebx+eax*2]	;index into color table
    stosb			;single pixel written
    dec ch
    jnz .NextCol
    jmp short .ToNextRow
.SkipCol:
        inc di
    dec ch
    jnz .NextCol
.ToNextRow:	
    ror ecx,16		;get access to upper part of ecx
    add edi,ebp		;add wrap width to get to next row
    dec cl			;row counter
    jnz .NextRow		;still going

    pop ebp			;restore base pointer
    ret

;------------------------------
; FontBlitStr (dword String, words Length, TopRow, LeftCol, dwords FontSet, ColorTable) ()
; Does not preserve any regs (must be done by caller)
;
; Simply calls FontBlitChar in a tight loop
;
FontBlitStr.Stack       equ 10
FontBlitStr.TextPtr	equ 0
FontBlitStr.Length	equ 4
FontBlitStr.TopRow	equ 6
FontBlitStr.LeftCol	equ 8

_FontBlitStr:
.NextChar:
    cmp word [esp+8],0	;test if there are any characters
    jle .End
    mov esi,[esp+4]		;get ptr to string
    mov al,[esi]		;grab next character
    inc dword [esp+4]	;for next character
    movzx edx,word [esp+10] ;get toprow
    movzx ecx,word [esp+12] ;get leftcol
    call _FontBlitChar.ByRegs
    ;calling by register saves from having to create a stack
    ;and reread it for every call through the loop
    add word [esp+12],byte 8;next column is eight pixels to the right
    dec word [esp+8]		;one less character to output
    jnz .NextChar
.End:
    ret

%if 0
;------------------------------
; FontBlitCenteredStr (dword String, words Length, TopRow) ()
; Does not preserve any regs (must be done by caller)
_FontBlitCenteredStr:
    movzx eax,word [ScreenWidth]
        movzx ebx,word [esp+8]  ;get length
    shl ebx,3		;multiply length by eight
    sub eax,ebx		;subtract length from screen width
    shr eax,1		;divide in half to get left column
    push ax			;put LeftCol
    push word [esp+12]	;put TopRow
    push word [esp+12]	;put string length
    push dword [esp+10]	;put string pointer
    call _FontBlitStr
    add esp,byte 10		;correct stack
    ret
%endif

;------------------------------
; FontBlitPar (dword String, words TopRow, LeftCol; dwords FontSet, ColorTable) ()
; No regs preserved
;
; Prints formatted text, calling font blitter in a tight loop.
;
_FontBlitPar:
        mov ax,[esp+10]
        mov [.LeftColumn],ax
.NextChar:
    mov esi,[esp+4]		;get ptr to string
    mov al,[esi]		;grab next character
    inc dword [esp+4]	;for next character
        cmp al,1
        js .ControlCharacter
        movzx edx,word [esp+8] ;get toprow
        movzx ecx,word [esp+10] ;get leftcol
        call _FontBlitChar.ByRegs ;calling by register saves from having to create a stack
                ;and reread it for every call through the loop
        add word [esp+10],byte 8;next column is eight pixels to the right
        jmp short .NextChar
.ControlCharacter:
        test al,al
    jz .End
        cmp al,129
    ja .NotNewLine
        mov ax,[.LeftColumn]
        mov [esp+10],ax
        add word [esp+8],byte 9        ;next row is eight pixels down
        jmp short .NextChar
.NotNewLine:
        movzx eax,al
        lea edi,[FontColors0-(130*8)+eax*8]
        mov [FontColorsPtr],edi
        jmp short .NextChar
.End:
        ret

.LeftColumn:    dw 0

;------------------------------
; DrawBox (words TopRow, BtmRow, LeftCol, RiteCol, Color) () - Does not preserve any regs
;
; This routine clips finally (and beautifully too)
; It should theoretically work in any linear 8bit resolution
; Will also draw to 15bit mode soon
;
DrawBox.Stack	equ 10
DrawBox.TopRow	equ 0	;\ paired
DrawBox.BtmRow	equ 2	;/
DrawBox.LeftCol	equ 4	;\ paired
DrawBox.RiteCol	equ 6	;/
DrawBox.Color	equ 8

_DrawBox:
    mov ax,[esp+8]		;get leftcol
    cmp ax,[ScreenClipLeft]	;check that not less
    jge .LeftColValid	;ok
    mov ax,[ScreenClipLeft]	;set it to clip
    mov [esp+8],ax		;and parameter
.LeftColValid:
    mov bx,[esp+10]		;get ritecol
    cmp bx,[ScreenClipRite]	;check that not greater
    jle .RiteColValid	;ok
    mov bx,[ScreenClipRite]	;set it to clip
    mov [esp+10],bx		;and parameter
.RiteColValid:
    sub bx,ax		;get width
    js near .End		;negative width
    inc bx			;adjust by one

;	movzx edx,[ScreenWidth]
    mov edx,320		;get screen width
    sub dx,bx		;get wrap width

    shl ebx,16		;keep width in safe part of bx
    mov ax,[esp+4]		;get toprow
    cmp ax,[ScreenClipTop]	;check that not less
    jge .TopRowValid	;ok
    mov ax,[ScreenClipTop]	;set it to clip
    mov [esp+4],ax		;and parameter
.TopRowValid:
    mov bx,[esp+6]		;get btmrow
    cmp bx,[ScreenClipBtm]	;check that not greater
    jle .BtmRowValid	;ok
    mov bx,[ScreenClipBtm]	;set it to clip
    mov [esp+6],bx		;and parameter
.BtmRowValid:
    sub bx,ax		;get height
    js .End			;negative height
    inc bx			;adjust by one
    ;height is now in lower part and width in higher part of ebx

    movzx eax,word ax	;zero out top 16 bits
    mov edi,eax		;make a copy
    shl eax,6		;multiply by 64
    shl edi,8		;now by 256
    add edi,eax		;multiplied by 320
;	imul ax,[ScreenWidth]
    movzx eax,word [esp+8]	;get left column
    lea edi,[0A0000h+eax+edi] ;add left column
;	add edi,[ScreenPtr]	;set to screen

    mov al,[esp+12]		;get color
    mov ah,al		;copy color byte to second byte
    shrd ecx,eax,16	;copy color word to top part of ecx
    shld eax,ecx,16	;eax now consists of four pixels all the same color
    xor ecx,ecx		;zero out top 17 bits
    cld			;as always, go forward
.NextLine:
    shld ecx,ebx,14		;get width divided by 4
    rep stosd
    shld ecx,ebx,16		;get width
    and ecx,3		;get modulus 4
    rep stosb
    add edi,edx
    dec bx
    jnz .NextLine
.End:
    ret

;------------------------------
; RedrawBackground (words TopRow, BtmRow, LeftCol, RiteCol) () - Does not preserve any regs
;
; Redraws an area of the background
; Background is pointed to by BackgroundPtr
; it might not necessarily point to BgScene.SceneBuffer
;
%if 0
RedrawBackground:
    xor ecx,ecx		;zero out top 17 bits
    cld			;as always, go forward
.NextLine:
    shld ecx,ebx,14		;get width divided by 4
    rep movsd
    shld ecx,ebx,16		;get width
    and cl,3		;get modulus 4
    rep movsb
    add edi,edx
    dec bx
    jnz .NextLine
.End:
%endif

;------------------------------
; (al=color) () - Saves all regs except modifying upper 24 bits of eax
;
; Simply clears the screen
;
DrawClearScreen:
    PushAll edi,cx
    mov ah,al		;copy color to second byte
    shrd ecx,eax,16	;make a copy
    shld eax,ecx,16	;shift into upper part
    mov ecx,(320*200)/4		;320x200=64000
    mov edi,0A0000h		;base of video memory
    cld			;as always, go forward
    rep stosd		;here we go
    PullAll edi,cx
    ret

;============================================================
; OUTPUT ROUTINES
;============================================================
;
;------------------------------
; FindNextNumberedFile (esi=source filename mask, edi=result):(cf=error)
; Does not save regs
;
;
%if 0
    mov edi,esi		;copy source for string length search
    mov ecx,127		;maximum filename length of 127 characters
    mov edx,ecx		;make a copy of max length for later
    mov al,'?'		;looking for double wildcard '??'
    cld			;as always, look forward
    repne scasb		;search for the end
    cmp cl,1		;if less than one then end
    jc .End
    sub edx,ecx		;get length

.End:
    ret

section .bss
.Name:	resb 128
section .text
%endif

WriteImage:		;these routines only work with 8bit images
;------------------------------
; (dword file handle, eax=height, ebx=width) Does not save regs
;
.BmpHeader:
    mov [.BmpHeader_Height],eax		;set header height
    mov [.RowsLeft],eax			;set rows remaining
    mov [.BmpHeader_Width],ebx		;set header width
    imul ebx					;get height times width
    mov [.BmpHeader_ImageSize],eax	;set image size in bytes
    add eax,1078				;add header size
    shr eax,2					;divide by four
    mov [.BmpHeader_DwordFileSize],eax	;set total bitmap size in dwords
    mov edx,.BmpHeaderFormat
    mov ebx,[esp+4]				;get file handle
    mov ecx,54					;total size of header
    mov ah,40h                  ;DOS: write file
    int 21h
    ret

;------------------------------
; (dword file handle)
;
.BmpPalette:
    Malloc 1024,edi				;temporary space to hold palette
    jc .BmpPaletteEnd           ;skip if could not allocate memory
    push edi                    ;edi=allocated pallete ptr
    mov esi,[ScreenPalettePtr]
    mov ecx,256
    cld                         ;move forward
  .BmpPaletteNextColor:
    lodsd						;grab three byte RGB tuple
    mov ebx,eax                 ;copy RGB
    rol eax,16                  ;don't ask me why Windows stores the RGB backwards
    mov ah,bh                   ;set green
    shl eax,2					;multiply by four (64 shade to 256)
    dec esi                     ;backtrack one pixel
    and eax,111111001111110011111100b	;clear top byte
    stosd						;store RGB tuble
    dec ecx                     ;one less color
    jnz .BmpPaletteNextColor
    mov edx,[esp]				;ptr to temporary palette
    mov ebx,[esp+8]				;get file handle
    mov ecx,1024				;size of palette
    mov ah,40h                  ;DOS: write file
    int 21h
    call _myheap_free_2         ;release temporary palette
    pull edi					;pull its address off stack
    .BmpPaletteEnd:
    ret

;------------------------------
; (dword file handle, esi=source, ecx=numbers rows)
; !Either BmpHeader must be called first or the height:width values must be set manually.
;
.BmpRows:
    cmp ecx,2048				;should never have even this many rows
    ja near .BmpRowsNoneLeft		;it must be an error if there are
    mov edx,[.RowsLeft]			;get rows remaining
    sub edx,ecx					;get rows remaining after subtracting rows to write
    ja .BmpRowsRemain
    lea ecx,[ecx+edx]				;set rows to write to rows remaining
    xor edx,edx					;set rows remaining to zero
.BmpRowsRemain:
    test ecx,ecx				;make sure there are at least some rows to write
    jz near .BmpRowsNoneLeft
    mov [.RowsLeft],edx			;set rows remaining
    mov ebx,[.BmpHeader_Width]
    lea eax,[ecx-1]				;one less row
    imul eax,ebx				;get (height-1) x width for address offset
    add esi,eax					;add offset to source
    push ecx					;push rows on as counter
    push esi					;save address of current row

    ;seek position in file
    imul edx,ebx				;get offset into file
    ;add fileheader size + palette size
    add edx,1078				;add header size and palette to get correct offset
    shld ecx,edx,16				;cx contains high word of file location
    mov ebx,[esp+12]            ;get file handle
    mov ax,4200h				;function to set file pointer
    int 21h

    ;output rows
    mov ecx,[.BmpHeader_Width]		;get the byte length of a single row
    pop edx					;get address of current row (count is still on stack)
    ;mov ebx,[esp+12]				;get file handle
.BmpRowsNext:
    ;mov edx,[esp]				;get address of current row
    ;sub [esp],ecx				;jump up one row
    mov ah,40h                  ;DOS: write file
    int 21h
    sub edx,ecx
    dec dword [esp]				;one less row
    jnz .BmpRowsNext
    add esp,byte 4
.BmpRowsNoneLeft:
    ret
;.BmpRowsNoneLeft:
;    int3
;    ret

;------------------------------
; (dword file handle, [ScreenPalettePtr])
;
.RgbPalette:
    mov edx,[ScreenPalettePtr]  ;set source of palette
    mov ecx,768                 ;total size of palette
; (edx=source, ecx=length)
.AnyPalette:
    mov ebx,[esp+4]				;get file handle
    mov ah,40h                  ;DOS: write file
    int 21h
    ret

;------------------------------
SECTION .data
.RowsLeft:		dd 0
.BmpHeaderFormat:
    db 'BM'
.BmpHeader_DwordFileSize:
    dd (1078+64000)/4	;file size in dwords
    dd 0			;reserved
    dd 1078		;byte offset to bitmap data

    dd 40			;size of header
.BmpHeader_Width:
    dd 320		;width
.BmpHeader_Height:
    dd 200		;height
    dw 1			;pixel planes
    dw 8			;bits per pixel
    dd 0			;compression
.BmpHeader_ImageSize:
    dd 320*200		;byte size of image
    dd 0,0		;pixels per meter, X and Y
    dd 0			;all 256 colors used
    dd 0			;number of important colors, all of them
SECTION .text

;============================================================
; INPUT ROUTINES
;============================================================
;------------------------------
; KeyGetPress () (ax=last keypress cf=keys pressed)
; Saves all regs except returning keypress in ax
;
; Besides simply returning key input, it also clears the keyboard buffer if there is more
; than one press waiting, so that annoying beeping won't ever happen.
;
KeyGetPress:
    PushAll edx,ecx
    xor edx,edx	;set initial keypress to null
    mov cl,16		;maximum count of 16 loops to clear buffer
.CheckKey:
    mov ah,1		;BIOS function 1, check key status
    int 16h
    jz .NoneWaiting		;zero flag set if nothing has been pressed
    mov ah,0		;BIOS function 0, get last key press
    int 16h
    mov edx,eax	;save KeyPress since calling for key status again destroys it
%if Debug > 1
    PushAll ecx,edx
    mov word [.LastPress],ax
    FontBlitStr .LastPress, 2, 9, 100
    PullAll ecx,edx
%endif
    dec cl			;one less key to clear
    jnz .CheckKey		;loop until no keys are waiting or count is up
.NoneWaiting:
    cmp cl,16		;if count equals original value, nothing changed and carry is clear
    mov eax,edx
    PullAll edx,ecx
    ret

%if Debug > 1
.LastPress:	dw 0
%endif

;------------------------------
; KeyGetPress.Single () (ax=last keypress cf=keys pressed)
; Saves all regs except returning keypress in ax
;
; Returns only the first waiting keypress. Does not completely clear the key buffer.
;
KeyGetPress.Single:
    mov ah,1		;BIOS function 1, check key status
    int 16h
    jz .NoKeypresses		;zero flag set if nothing has been pressed
    mov ah,0		;BIOS function 0, get last key press
    int 16h
    stc
    ret

.NoKeypresses:
    xor eax,eax
    ;clc
    ret

;------------------------------
; (esi=keylist struct) (cf=true if keypress found, ecx=keynumber)
;
; Pass a scan structure to it, which points to a list of keys, number of
; normal keys, and number of extended. Returns true (cf) if key was found,
; also then returns its index.
;
KeyScan:
    cld
    mov edi,[esi]
    movzx ecx,byte [esi+4]
    test al,al
    jz .ExtendedKey
    repne scasb
    jnz .NotFound
    not cl
    add cl,[esi+4]
    stc
    ret

.ExtendedKey:
    add edi,ecx
    mov al,ah
    mov cl,[esi+5]
    repne scasb
    jnz .ExtendedKeyNotFound
    not cl
    add cl,[esi+5]
    add cl,[esi+4]
    xor al,al		;put null back into al
    stc
    ret

.ExtendedKeyNotFound:
    xor al,al		;put null back into al
.NotFound:
    clc
    ret

;------------------------------
; () (ax=keypress) - Saves all other regs
;
; Waits for a key to be pressed before proceding
;
UserWait:
    call KeyGetPress	;clears waiting keys
.CheckKey:
    call MouseGetInfo
    cmp al,2		;greater than mouse movement?
    jae .End		;user clicked a button
%if Debug > 1
    FontBlitStr MouseCol, 2, 0, 0
%endif
    mov ah,1		;BIOS function 1, check key status
    int 16h
    jz .CheckKey		;no keys pressed yet
    mov ah,0		;BIOS function 0, get last key press
    int 16h
%if Debug > 1
    mov [KeyGetPress.LastPress],ax
    FontBlitStr KeyGetPress.LastPress, 2, 9, 0
%endif
.End:
    ret

;------------------------------
; (ax=mouse function) () - Preserves all not passed back by the mouse driver function
;
; Most most calls can just be done directly since they only require a 'mov' and 'int'.
; This simply makes sure that the mouse was detected by MouseInitialize before calling.
; Be sure not to use show or hide functions with the mouse driver since the mouse driver's
; pointer always remains hidden; the only pointer is the one that comes with this prog.
; Using this routine for any functions that would cause the mouse pointer to move will not
; automatically update the pointer. Use PointerMoveMouse instead for repositioning it.
;
MouseFunction:
    cmp byte [MouseButtons],0
    jz .End			;simply quit if no mouse
    int 33h			;mouse driver call
.End:
    ret

;------------------------------
; () (al=status | ah=buttons pressed since last call, cf=change) - Does not preserve regs
; *not finished
;
; Responsible for checking whether or not the mouse has moved or a button has been pressed or
; released. Returns the current status of it in al (0=nothing  1=mouse move  2=mouse press).
; Anything non-zero means a change, then the other variables tell more info.
; It also moves the pointer if the mouse has been moved. Since BgMapper draws the pointer
; rather than the mouse driver, and since there is no handler called when mouse events happen,
; this function must be polled to keep the pointer active. It is possible that this function
; could miss a mouse click if not called at the right time, but most loops are tight enough
; to not worry about that.
;
align 16			;extra speed??
MouseGetInfo:
    cmp byte [MouseButtons],0;check that a mouse does exist
    jz .End			;simply quit if no mouse
    mov ax,3        ;Mouse driver: get status
    int 33h
    xor eax,eax		;assume no change
    mov ah,[MouseBtnsDown];get previous buttons down
    ;cmp bl,ah           ;check if buttons down now are different than last time
    ;je .NoPresses              ;no new presses or releases
    not ah                      ;flip bits of previous buttons down
    and ah,bl                   ;compare the two and mask new presses
    mov [MouseBtnsDown],bl      ;set buttons held down
    mov [MouseBtnsPressed],ah   ;set new buttons pressed
    jz .NoPresses
    mov esi,[Timer]		;get current timer value
    mov ebx,esi			;make a copy
    sub esi,[MouseLastClick];get time between clicks (subtract last click from timer)
    mov [MouseLastClick],ebx ;save time of last click
    mov [MouseClickTime],esi ;so outside routines can use it for detecting 'double clicks'
    mov al,2			;flag button press
.NoPresses:
    ;shr cx,1		;divide column in half, at least while in 320x200 mode
    ;cmp dx,[MouseRow]	;has row changed?
    ;jne .MouseMove
    ;cmp cx,[MouseCol]	;has column changed?
    ;je .NoMouseMove
    shl ecx,16		;move column into upper part of dword
    shr ecx,1		;divide column in half, at least while in 320x200 mode
    mov cx,dx		;copy row to dword
    cmp [MousePos],ecx
    je .NoMouseMove
;.MouseMove:
    mov [MousePos],ecx
    or al,1		;flag mouse movement
    ;mov [MouseRow],dx	;save row and column for next call
    ;mov [MouseCol],cx
    ;push eax		;save mouse change flags
    ;call PointerMove
    ;pull eax		;retrieve mouse change flags
.NoMouseMove:
    cmp al,1
    cmc
    ret
.End:
    xor al,al
    ret

MouseClearChanges:
    mov eax,[Timer]			;get current tick time
    sub eax,1000h			;make difference large enough to cancel double clicks
    mov [MouseLastClick],eax	;save last click time
    mov byte [MouseBtnsPressed],0	;set new buttons down to none
    ret

;============================================================
; POINTER ROUTINES
;============================================================
; The pointer is actually drawn by this ZMapper rather than by the mouse driver since it
; doesn't support SVGA modes. Because of this, the pointer can be visible even if there was
; no mouse detected. That is how the scene viewer is able to have a cursor. It also allows
; the cursor image to have three shades of color plus transparency.
;
SECTION .bss
alignb 4
MouseButtons:       resb 1      ;number of buttons on mouse, zero if no mouse
MouseBtns:                      ;(Mouse buttons group)
MouseBtnsPressed:	resb 1		;which buttons were pressed since the last call
MouseBtnsReleased:  resb 1      ;which buttons were released since the last call
MouseBtnsDown:		resb 1		;which buttons are currently down (or at least a while ago)
MouseLastClick:		resd 1		;when the last press occurred (using the timer)
MouseClickTime:		resd 1		;time between latest click and last click
MousePos:                       ;(Row:Column) pair
MouseRow:           resw 1      ;mouse row last time called
MouseCol:           resw 1      ;mouse column last time called
PointerRow:         resw 1      ;the pointer image's coordinates
PointerCol:         resw 1
CursorRowOffset:    resw 1      ;displacement from cursor hot spot
CursorColOffset:    resw 1
;PointerBitmapPtr:   resd 1     ;address of packed cursor image
alignb 4
CursorImageAnd:     resb 16*20  ;cursor pixel mask
CursorImageOr:      resb 16*20  ;current cursor image pixels
;CursorBackground:   resb 16*16  ;screen behind pointer
SECTION .text

;------------------------------
; () (ax=TRUE if mouse present, cf=if no mouse) - No regs preserved
;
; Called to check for existance of mouse, and must be called before mouse
; routines. Resets mouse driver if found and sets MouseButtons, otherwise
; MouseButtons set to 0.
;
MouseInitialize:
    ;mov dword [PointerBitmapPtr],PointerImageDefault
    ;make cursor image out of packed image
    mov eax,21h                 ;Mouse driver: sofware reset
    int 33h
    cmp ax,0FFFFh               ;should be -1 (true)
    jne .NoMouseDriver          ;no mouse driver
    mov [MouseButtons],bl       ;2 or 3 buttons
    jmp MouseGetInfo
.NoMouseDriver:
    mov byte [MouseButtons],0   ;no mouse or at least no driver loaded
    ret

Pointer:
.Show:                          ;draws the cursor over screen
    mov ax,1                    ;** temp hack
    jmp MouseFunction
    ;call MouseFunction
    ;ret
.Hide:                          ;redraws the screen background
    mov ax,2                    ;** temp hack
    jmp MouseFunction
;   call MouseFunction
;   ret

CursorShow:
    mov ebx,4
    mov ecx,000F0404h
    mov edx,320-16
    xor esi,esi
    movzx edi,word [MouseRow]
    mov eax,edi
    shl edi,8
    shl eax,6
    add edi,eax
    movzx eax,word [MouseCol]
    lea edi,[edi+eax+0A0000h]
.NextRow:
    mov cl,ch
.NextBlock:
    mov eax,[edi]
    and eax,[CursorImageAnd+esi+4]
    or eax,[CursorImageOr+esi+4]
    mov [edi],eax
    add esi,byte 4
    add edi,byte 4
    dec cl
    jnz .NextBlock
    add esi,ebx
    add edi,edx
    sub ecx,65536
    jns .NextRow
    ret

CursorSetImage:
    xor eax,eax
    mov edi,CursorImageAnd
    mov ecx,00001000h           ;set row counter to 16
    jmp short .RowDone
.NextRow:
    mov cl,16                   ;set column counter to 16
.NextPixel:
    mov al,[esi]
    inc esi
    test al,al
    jz .Transparent
    mov al,[CursorColorTable+eax-1]
    mov [edi],byte 0
    mov [edi+(CursorImageOr-CursorImageAnd)],al
    inc edi
    dec cl
    jnz .NextPixel
    jmp short .RowDone
.Transparent:
    mov [edi],byte 0FFh
    mov [edi+(CursorImageOr-CursorImageAnd)],byte 0
    inc edi
    dec cl
    jnz .NextPixel
.RowDone:
    mov [edi],dword 0FFFFFFFFh
    mov [edi+(CursorImageOr-CursorImageAnd)],dword 0
    add edi,byte 4
    sub ecx,240
    jns .NextRow
    ret

%if 0
:
CursorSetOffset:

CursorShow:
height = 16: width = 16
if row < 0 then height = row + 16
edi=0
esi=0
if row > (320-16) then height = 320 - row
esi=row*20
edi=row*320
if col < 0 then width = col + 16
if col > (200-16) then width = 200 - col
add width,3
and width,~3
ebx = 16 - width
edx = 320 - width
shr ecx,

xor ebx,ebx
mov ecx,00100404h
mov edx,320-16
mov edi,0A0000h+(10*320)+10
xor esi,esi
.NextRow:
mov cl,ch
.NextBlock:
mov eax,[edi]
and eax,[CursorImageAnd + esi]
or eax,[CursorImageOr+esi]
mov [edi],eax
add edi,byte 4
dec cl
jnz .NextBlock
add esi,ebx
add edi,edx
sub ecx,65536
jns .NextRow

CursorHide:


%endif

%ifdef codeready
.SaveBackground:
.Draw:
    ;calculate starting row and number of rows
    ;determine starting shift block if clipped
    ;adjust esi & edi accordingly
.Col1:
    mov eax,[esi]
    mov ebx,[esi+4]
    and [edi],eax
    and [edi+4],ebx
.Col2:
    mov eax,[esi+8]
    mov ebx,[esi+12]
    and [edi+8],eax
    and [edi+12],ebx
.Col3:
    mov eax,[esi+16]
    mov ebx,[esi+20]
    and [edi+16],eax
    and [edi+20],ebx
.Col4:
    mov eax,[esi+24]
    mov ebx,[esi+28]
    and [edi+24],eax
    and [edi+28],ebx
    ;finish off any remaining pixels
    ;esi=esi + cursor bytes per row
    ;edi=edi+ (screen width - cursor with)
    ;next row
%endif

;------------------------------
; Tests for a point being inside a list of areas.
; If the pointer was not in any area searched, carry is false,
; otherwise the index is returned with reduced coordinates to that area.
;
; (esi=ptr to list of area, ax=row, bx=column) (ecx=index, ax=reduced row,
;  bx=reduced column, cf=true if area found)
;
ScanMouseAreas:
    mov edi,[esi+4]             ;get total number of areas to check
    mov ecx,-1                  ;compensate for next INC
    mov esi,[esi]               ;get ptr to area list
.Next:
    inc ecx                     ;next area (or start at first area)
    cmp ecx,edi
    jge .NoMatches
    mov dx,[esi+ecx*8]
    cmp ax,dx
    jb .Next
    add dx,[esi+ecx*8+4]
    cmp ax,dx
    jae .Next
    mov dx,[esi+ecx*8+2]
    cmp bx,dx
    jb .Next
    add dx,[esi+ecx*8+6]
    cmp bx,dx
    jae .Next
    sub ax,[esi+ecx*8]          ;return reduced coordinates, row and column
    sub bx,[esi+ecx*8+2]
    stc                         ;set true, matching area was found
    ret
.NoMatches:
    xor ecx,ecx                 ;also clears carry
    ;clc
    ret

;------------------------------
