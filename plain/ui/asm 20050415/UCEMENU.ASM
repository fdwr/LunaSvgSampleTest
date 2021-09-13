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
