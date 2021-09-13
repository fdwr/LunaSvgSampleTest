;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
MainWindowCode:
    movzx esi,word [esp+12]
; (esi=new item index)
.ChangeFocus:
    cmp [MainWindow+WindowObj.TotalItems],si    ;check index is valid
    jbe .Ignore
    movzx ebx,word [MainWindow+WindowObj.KeyIdx]    ;get object that has focus
    cmp bx,si
    je .Ignore
    mov [MainWindow+WindowObj.KeyIdx],si            ;set object that has focus

    mov eax,Msg.KeyFocus
    shl ebx,GuiObj.SizeShl
    add ebx,MainWindow.Items
    push esi
    and dword [ebx+GuiObj.Flags],~GuiObj.ItemFocus
    push ebx                    ;pass gui object info
    push dword [ebx+GuiObj.Data];pass gui object's data structure
    call [ebx+GuiObj.Code]
    add esp,byte 8

    pop ebx
    mov eax,Msg.KeyFocus
    shl ebx,5
    add ebx,MainWindow.Items
    or dword [ebx+GuiObj.Flags],GuiObj.ItemFocus
    push ebx                    ;pass gui object info
    push dword [ebx+GuiObj.Data];pass gui object's data structure
    call [ebx+GuiObj.Code]
    lea esp,[esp+8]
    ret

.Ignore:
    stc
    ret

.TabForward:
    ;int3;
    movzx esi,word [MainWindow+WindowObj.KeyIdx]    ;get object that has focus
    movzx ecx,word [MainWindow+WindowObj.TotalItems]
    inc esi
    mov edx,ecx
    shl esi,GuiObj.SizeShl
    shl edx,GuiObj.SizeShl
    jmp short .TfFirst
.TfNext:
    cmp esi,edx
    jb .TfNoWrap
    xor esi,esi
.TfNoWrap:
    test dword [MainWindow+WindowObj.Items+esi+GuiObj.Flags],GuiObj.Null|GuiObj.NoKeyFocus
    jnz .TfSkip
    shr esi,GuiObj.SizeShl
    jmp .ChangeFocus
.TfSkip:
    add esi,byte GuiObj.SizeOf
.TfFirst:
    dec ecx
    jg .TfNext
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
SetKeyFocus:

    <Old Code>
    return failure if no items
    find current item, first and last items of current group
    if relative
        if ByItem
            if WithinGroup
                set limits to group start and end
            else WithinWindow
                set limits to window start and end
            endif
            search until back to start
                if enabled item && relative count <= 0
                    exit search
                endif
                relative count --
                wrap if necessary, index %= window/group length
            endsearch
        else ByGroup
            set limits to window start and end
            search until back to start
                if enabled group && relative count <= 0
                    exit search
                endif
                if group start
                    relative count --
                endif
                wrap if necessary, index %= window length
            endsearch
        endif
        goto activate item
    else absolute
        ;set advance direction based on index - current index
        if absolute item out of range or null return error
        goto activate item
    endif

    :activate item
    if (new item != current item) and (either ActivateItem or ActivateGroup)
        inform owner of focus change
        find new item's group range
        if ActivateItem
            set item to group default
            clear any other items that have group default set
        endif
        if ActivateGroup
            if new group different from current group
            endif
        endif
    endif
    if ActivateContainer
        send focus message to container
    endif
    return new item

    <Maybe this would be better?>
    if ActivateItem
        loop all items in group that can get key focus
            //turn off KeyFocus
            turn off GroupFocus
            turn off WindowFocus
        endloop
        if new item same group as current item
            inform owner of focus change
            if container is active
                send KeyFocusOut to old item
                set GroupFocus+WindowFocus for new item
                send KeyFocusIn to old item
                set current item = new item
            else
                set GroupFocus+WindowFocus for new item
            endif
        else
            set GroupFocus+WindowFocus for new item
        endif
    if ActivateGroup
    endif

    <Oldest code>
    Group item, absolute
    Group item, relative
        find last item in group
            search from current item until group flag found or back of list
        if new index < first group item
            new index += total group items
            if new index <= current index, return error
        endif
        if new index > last group item
            new index -= total group items
            if new index >= current index, return error
        endif
        if ignore disabled flag set and item can not be set, return error
        if focus forward
            start loop
                if item can be set, return item index
                if ++index > last group item, index = first item
            loop until index = current index
        elif backward
            start loop
                if item can be set, return item index
                if --index < first group item, index = last item
            loop until index = current index
        endif
        set focus to new item
    Specific item, absolute
    Specific item, relative
        if new index < first list item (0)
            new index += total list items
            if new index <= current index, return error
        endif
        if new index > last list item (total items - 1)
            new index -= total list items
            if new index >= current index, return error
        endif
        if ignore disabled flag set and item can not be set, return error
        if focus forward
            start loop
                if item can be set, break with item index
                if ++index > last list item, index = first list item
            loop until index = current index
        elif backward
            start loop
                if item can be set, break with item index
                if --index < first list item, index = last list item
            loop until index = current index
        endif
        find first item in new group
            search backwards from new item
        loop until group start flag found or front of list
        if different from previous group
            set focus to new group
        else
            set focus to new item
        endif
    Group, absolute
    Group, relative
        find last item in group
            search from current item until group flag found or end of list
        if focus forward
            index = last group item
            start loop
                if item can be set, break with item index
                if ++index > last list item, index = first list item
            loop until index = first group item
        elif backward
            index = first group item
            start loop
                if item can be set, break with item index
                if --index < first list item, index = last list item
            loop until index = last group item
        endif
        find first item in new group
            search backwards from new item
            if group default flag set, new item = current item
        loop until group flag found or front of list
        if different from previous group
            set focus to new group
        else
            return error
        endif

    Set focus to new item
        set active item to new item
        unset focus of old item
        set focus of new item
    Set focus to new group
        index = first item of old group
        unset previous group range
        index = first item of new group
        set focus new group range
    Unset focus range
        set active item to new item
        search through all items of group
            if focus is set and not window focus, unset focus
        loop until last item in group
    Set focus range
        set active item to new item
        search through all items of group
            if focus is not set
                if window or group focus, set item focus
            endif
        loop until last item in group
        if focus not already set to it, set new item focus


    Flags:
        Absolute
          Relative
        Next available item in any group /
          Next available item within current group /
          Default item of specified item's group /
          Default item of next available group
        Wrap if out of group or list
          No wrap (failure)
        Advance focus to next or previous item/group
          Ignore if specified item could not be set
        Get index only
          Activate item, setting both group and window default
          Set item as group default
          Activate item and its container

        Get specified item / Get default group item
        Get specified item / Get default window item

    Will return error if:
        No items exist
        No items are enabled
        Or the specified item could not be set when the "ignore if disabled"
         flag is set.

    mov ebx,[esp+4]             ;get window data structure
    movzx ecx,word [ebx+WindowObj.TotalItems]
    test ecx,ecx
    jnz .ItemsExist
    stc
    ret

.ItemsExist:
    push ebp
    mov ebp,esp
    ;find current item in list and its group start and end
    sub esp,byte 12             ;allocate 21 bytes space for call
    movzx edx,word [ebx+WindowObj.KeyIdx] ;get current active item
    call .GetItemIdx

    mov eax,[ebp+.ebpFlags]
    test eax,KeyFocusFlags.Relative
    jz .Absolute

;Relative
    test eax,KeyFocusFlags.ByGroup
    jz .ByGroup
;ByItem
    test eax,KeyFocusFlags.WithinGroup
    jz .WithinGroup
;WithinWindow

    jmp short .RiLimitsSet
.WithinGroup:
.RiLimitsSet:
    mov ecx,[esp+.StkCgIdx]     ;get relative count
    shl ecx,GuiObj.SizeShl
    lea esi,[ebx+Window.Obj+ecx]

    mov ecx,[esp+.StkNewIdx]    ;get relative count
    movzx esi,word [edi+GuiObj.KeyIdx]
.RifNext:
    mov eax,[esi+GuiObj.Flags]
    test eax,GuiObj.Null
    jz .RifNull
.RifNull:
    add esi,byte GuiObj.SizeOf
    cmp esi,edi
    jb .RiNext
    movzx ecx,word [ebx+WindowObj.TotalItems]
    shl ecx,GuiObj.SizeShl
    ;lea 
    ;mov 


.RibNext:
    mov eax,[esi+GuiObj.Flags]
    test eax,GuiObj.Null
    jz .RibNull
.RibNull:
    sub esi,byte GuiObj.SizeOf
    cmp esi,edi
    jae .RiNext

.ByGroup:

        if ByItem
            if WithinGroup
                set limits to group start and end
            else WithinWindow
                set limits to window start and end
            endif
            search until back to start
                if enabled item
                    if relative count <= 0
                        exit search
                    endif
                    relative count --
                endif
                wrap if necessary, index %= window/group length
            endsearch
        else ByGroup
            set limits to window start and end
            search until back to start
                if enabled group && relative count <= 0
                    exit search
                endif
                if group start
                    relative count --
                endif
                wrap if necessary, index %= window length
            endsearch
        endif

.Absolute:
    mov esp,ebp
    pop ebp
    ret

; Searches through tab order list to find an item.
; Also finds the first and last tab indexes of that item's group.
;
; (empty dwords first, last, current, ebx=window data, edx=item list index)
; (dwords first, last, current, ebx=window data)
.espGiiFirst    equ 4
.espGiiLast     equ 8
.espGiiCurrent  equ 12

.GetItemIdx:
    xor eax,eax
    mov [esp+.espGiiFirst],eax
    mov [esp+.espGiiLast],eax
    mov [esp+.espGiiCurrent],eax
    movzx ecx,word [ebx+WindowObj.TotalItems]
    cmp edx,ecx                 ;is passed item in list
    jb .GiiItemValid
.GiiItemInvalid:
    ret
.GiiItemValid:
    lea edi,[ebx+WindowObj.Items] ;beginning of list
    xor eax,eax
.GiiNext:
    cmp [edi+GuiObj.KeyIdx],dx  ;does tab index point to the desired item
    je .GiiItemFound
    add edi,GuiObj.SizeOf       ;next item in list
    dec ecx
    jg .GiiNext
    jmp short .GiiItemInvalid   ;error finding item in tab order list
.GiiItemFound:
    neg cx                      ;get item's tab order index by -count + total
    add cx,[ebx+WindowObj.TotalItems]
    mov [esp+.espGiiCurrent],ecx ;save tab order index
    ;call .FindGroupEnd
    ret

; Finds the first/last item of a group, starting from the given item ptr.
; (edi=item ptr, ecx=count, edx=direction)
; (edx=index, ebx=)
.FindGroupEnd:
.FgeNext:
    movzx esi,word [edi+GuiObj.KeyIdx]
    shl esi,GuiObj.SizeShl      ;*32
    lea esi,[ebx+WindowObj.Items+GuiObj.Flags+esi] ;add base ptr of window item list
    mov eax,[esi]
    test eax,GuiObj.Null
    jnz .FgeNo
    test eax,GuiObj.GroupStart
    jz .FgeNo
    ;c
.FgeNo:
    add edi,edx
    dec ecx
    jg .FgeNext
.FgeFound:
    ret

    mov eax,1

    xor ecx,ecx
    movzx edi,word [ebx+WindowObj.KeyIdx]
    add eax,edi
    mov edx,esi
    call .CheckNewIndex
    ;test [esp+],ignoredisabled
    ;jz
    ;mov ebx,[esp+4]
    ;mov esi,edi
    ;shl esi,5                   ;*32
    ;lea esi,[esi+ebx+WindowObj.Items]
    ;test [esi],
    call .FocusForward

    push eax
.SiGroupNext:                   ;find what group new item is in
    test dword [esi+GuiObj.Flags],GuiObj.GroupStart
    jnz .SiGroupFound
    sub esi,byte GuiObj.SizeOf  ;search backwards from new item until group flag found
    dec eax                     ;...or front of list
    jns .SiGroupNext
    xor eax,eax                 ;if no item starts a group, assign first item as beginning of group
.SiGroupFound:
    cmp ax,[ebx+WindowObj.ActiveGroup]  ;if different from previous group
    pop eax
    ;    set focus to new group
    ;else
    ;    set focus to new item
    ;endif
    call .ChangeItemFocus
.SiEnd:
    ret


; Only to be called within SendKeyFocusMsg
; (eax=new index, ebx=window data ptr, ecx=lower limit, edx=upper limit,
;  esi=total window items, edi=current active item)
.CheckNewIndex:
    cmp eax,ecx                 ;if new index < first list item (0)
    jns .CniNotBelow
    add eax,esi                 ;    new index += total list items
    cmp eax,edi                 ;    if new index <= current index, return error
    jle .CniError
    jmp short .CniNotAbove      ;endif
.CniNotBelow:
    cmp eax,edx                 ;if new index >= (last list item + 1)
    jb .CniNotAbove             ;
    sub eax,esi                 ;    new index -= total list items
    cmp eax,edi                 ;    if new index >= current index, return error
    jae .CniError               ;endif
.CniNotAbove:
    ret
.CniError:
    add esp,byte 4
    stc
    ret


;Only to be called within SendKeyFocusMsg
; (eax=desired new index, ebx=window data ptr, ecx=lower limit,
;     edx=upper limit, edi=current active item)
; (eax=new item index, esi=item's gui ptr)
.FocusForward:
    mov esi,eax
    shl esi,5                   ;*32
    lea esi,[esi+ebx+WindowObj.Items]
.FfNext:                        ;start loop
    test dword [esi+GuiObj.Flags],GuiObj.Null|GuiObj.NoKeyFocus
    jz .FfMatch                 ;   if item can be set, break with item index
    inc eax
    cmp eax,edx                 ;   if ++index > last item, index = first item
    jae .FfAbove
    add esi,byte GuiObj.SizeOf
.FfAboveResume:
    cmp eax,edi                 ;loop until index = current index
    jne .FfNext
    add esp,byte 4
    stc
    ret
.FfAbove:
    mov eax,ecx                 ;index = first item
    lea esi,[ebx+WindowObj.Items]
    jmp short .FfAboveResume
.FfMatch:
    ret


;Only to be called within SendKeyFocusMsg
; (eax=desired new index, ebx=window data ptr, ecx=lower limit,
;     edx=upper limit, edi=current active item)
; (eax=new item index, esi=item's gui ptr)
.FocusBackward:
    mov esi,eax
    shl esi,5                   ;*32
    lea esi,[esi+ebx+WindowObj.Items]
.FbNext:                        ;start loop
    test dword [esi+GuiObj.Flags],GuiObj.Null|GuiObj.NoKeyFocus
    jz .FbMatch                 ;   if item can be set, break with item index
    dec eax
    cmp eax,ecx                 ;   if --index < first list item, index = last list item
    jl .FbBelow
    sub esi,byte GuiObj.SizeOf
.FbBelowResume:
    cmp eax,edi                 ;loop until index = current index
    jne .FbNext
    add esp,byte 4
    stc
    ret
.FbBelow:
    mov esi,edx                 ;copy high index
    lea eax,[edx-1]             ;index = last item
    shl esi,5                   ;*32
    lea esi,[ebx+esi+WindowObj.Items-GuiObj.SizeOf]
    jmp short .FbBelowResume
.FbMatch:
    ret

.ChangeItemFocus:
    mov esi,eax
    shl esi,5                   ;*32
    lea esi,[ebx+esi+WindowObj.Items]
    push esi
    xchg [ebx+WindowObj.KeyIdx],ax   ;set active item to new item

    cmp ax,[ebx+WindowObj.TotalItems]
    jae .CifSkipUnset

    mov esi,eax
    shl esi,5                   ;*32
    lea ebx,[ebx+esi+WindowObj.Items]
    and dword [ebx+GuiObj.Flags],~GuiObj.KeyFocus
    mov eax,Msg.KeyOut
    push ebx
    push dword [ebx+GuiObj.Data]
    call [ebx+GuiObj.Code]      ;unset focus of old item
    add esp,byte 8

  .CifSkipUnset:
    pop ebx
    mov eax,Msg.KeyIn
    or dword [ebx+GuiObj.Flags],GuiObj.KeyFocus
    push ebx
    push dword [ebx+GuiObj.Data]
    call [ebx+GuiObj.Code]      ;set focus of new item
    lea esp,[esp+8]
    ret


.ChangeGroupFocus:
.SetFocusRange:
.UnsetFocusRange:
    ;ret

;section data
;align 4
;.IdxPtr:
;.IdxStartPtr:
;.IdxEndPtr:
;section code

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
MainWindowCode:

    movzx esi,word [esp+12]
; (esi=new item index)
.ChangeFocus:
    cmp [MainWindow+WindowObj.TotalItems],si    ;check index is valid
    jbe .Ignore
    movzx ebx,word [MainWindow+WindowObj.KeyIdx]    ;get object that has focus
    cmp bx,si
    je .Ignore
    mov [MainWindow+WindowObj.KeyIdx],si            ;set object that has focus

    mov eax,Msg.KeyFocus
    shl ebx,GuiObj.SizeShl
    add ebx,MainWindow.Items
    push esi
    and dword [ebx+GuiObj.Flags],~GuiObj.ItemFocus
    push ebx                    ;pass gui object info
    push dword [ebx+GuiObj.Data];pass gui object's data structure
    call [ebx+GuiObj.Code]
    add esp,byte 8

    pop ebx
    mov eax,Msg.KeyFocus
    shl ebx,5
    add ebx,MainWindow.Items
    or dword [ebx+GuiObj.Flags],GuiObj.ItemFocus
    push ebx                    ;pass gui object info
    push dword [ebx+GuiObj.Data];pass gui object's data structure
    call [ebx+GuiObj.Code]
    lea esp,[esp+8]
    ret

.TabForward:
    ;int3;
    movzx esi,word [MainWindow+WindowObj.KeyIdx]    ;get object that has focus
    movzx ecx,word [MainWindow+WindowObj.TotalItems]
    inc esi
    mov edx,ecx
    shl esi,GuiObj.SizeShl
    shl edx,GuiObj.SizeShl
    jmp short .TfFirst
.TfNext:
    cmp esi,edx
    jb .TfNoWrap
    xor esi,esi
.TfNoWrap:
    test dword [MainWindow+WindowObj.Items+esi+GuiObj.Flags],GuiObj.Null|GuiObj.NoKeyFocus
    jnz .TfSkip
    shr esi,GuiObj.SizeShl
    jmp .ChangeFocus
.TfSkip:
    add esi,byte GuiObj.SizeOf
.TfFirst:
    dec ecx
    jg .TfNext
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
GetContainerClips:
    jmp short .RectSet
.SpecifiedRect:
    mov ecx,[esp+.Position]
    mov [ebx+WindowObj.MouseTopLeft],ecx
    add cx,[esp+.Height]
    rol ecx,16
    add cx,[esp+.Width]
    rol ecx,16
    mov dword [ebx+WindowObj.MouseBtmRight],ecx
.RectSet:


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
<GUICODE.ASM>
    cld
    xor ecx,ecx
    movzx edx,word [ebx+WindowObj.TotalItems]
    lea esi,[ebx+WindowObj.Items]
    test edx,edx
    jz .End
.NextItem2:
    movzx edi,word [esi+GuiObj.Top]
    mov eax,edi
    shl edi,8
    shl eax,6
    add edi,eax
    movzx eax,word [esi+GuiObj.Left]
    lea edi,[0A0000h+edi+eax]
    push edi
    mov al,15
    mov cx,[esi+GuiObj.Width]
    rep stosb
    dec edi
    mov cx,[esi+GuiObj.Height]
.NextRowLeft:
    mov byte [edi],12
    add edi,320
    loop .NextRowLeft
    pop edi
    mov cx,[esi+GuiObj.Height]
.NextRowRight:
    mov byte [edi],14
    add edi,320
    loop .NextRowRight
    sub edi,320
    mov al,13
    mov cx,[esi+GuiObj.Width]
    rep stosb
    add esi,byte 32
    dec edx
    jnz .NextItem2
.End:
    mov al,5


<GFX.ASM>
%if 0
%ifdef UseGuiGfx
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Subtracts the given area and the current redraw bounds from the clips.
;
; (esi=redraw area words)
; (; ebx,esi)
SubtractAreaRedrawClips:

.ClipTop    equ 0
.ClipLeft   equ 2
.ClipBtm    equ 4
.ClipRight  equ 6

    ; leave alone top/left of display
    ; leave alone display ptr

    movsx eax,word [esi+.ClipTop]
    movsx ecx,word [esi+.ClipLeft]

    cmp [Display.RedrawTop],eax
    jge .UseArea
    mov eax,[Display.RedrawTop]
.TopArea:
    cmp [Display.ClipTop],eax
    jge .TopSame
    mov eax,[Display.ClipTop]
.ClipTop:
    mov [Display.ClipTop],eax

    movsx edx,word [esi+.ClipBtm]
    cmp [Display.RedrawLeft],ecx
    jge .LeftSame
    mov ecx,[Display.RedrawLeft]
.LeftSame:
    mov [Display.ClipLeft],ecx
    movsx eax,word [esi+.ClipRight]
    cmp [Display.RedrawBtm],edx
    jle .BtmSame
    mov edx,[Display.RedrawBtm]
.BtmSame:
    mov [Display.ClipBtm],edx
    cmp [Display.RedrawRight],eax
    jle .RightSame
    mov eax,[Display.RedrawRight]
.RightSame:
    mov [Display.ClipRight],eax
    ret
%endif
%endif


%if 0
%ifdef UseGuiGfx
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Subtracts the GUI item's dimensions from stack saved clips of a container's
; redraw area, yielding that item's redraw area. Used by containers to set
; the affected redrawn area before passing to items.
;
; (ebx=gui item, esi=stack saved clips)
; (; ebx,esi)
SubtractGuiClipsRedraw:
    movsx edx,word [ebx+GuiObj.Top]
    movsx ecx,word [ebx+GuiObj.Left]

    mov eax,[Display.ClipTop]
    mov edi,[Display.ClipLeft]
    sub eax,ecx
    sub edi,edx
    neg ecx
    neg edx
    add ecx,[Display.ClipBtm]
    add edx,[Display.ClipRight]

    ; merge into clips
    cmp [esi+SavedClips.ClipTop],eax
    jle .TopSame
    mov eax,[esi+SavedClips.ClipTop]
.TopSame:
    mov [Display.RedrawTop],eax
    cmp [esi+SavedClips.ClipLeft],edi
    jle .LeftSame
    mov edi,[esi+SavedClips.ClipLeft]
.LeftSame:
    mov [Display.RedrawLeft],edi
    cmp [esi+SavedClips.ClipBtm],edx
    jge .BtmSame
    mov edx,[esi+SavedClips.ClipBtm]
.BtmSame:
    mov [Display.RedrawBtm],edx
    cmp [esi+SavedClips.ClipRight],ecx
    jge .RightSame
    mov ecx,[esi+SavedClips.ClipRight]
.RightSame:
    mov [Display.RedrawRight],ecx
    ret
%endif
%endif


%if 0
%ifdef UseGuiGfx
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Adds dimensions of GUI item with the stack saved clips of the item's
; container, setting the stack saved clips (not the screen clips!). Used by
; containers to combine all redrawn items into their accumulated redraw area.
;
; (esi=stack saved clips, ebx=gui item)
; (; ebx,esi)
AddGuiSavedClips:

    movsx edx,word [ebx+GuiObj.Top]
    movsx ecx,word [ebx+GuiObj.Left]
    mov eax,[Display.ClipTop]
    mov edi,[Display.ClipLeft]
    add eax,edx
    add edi,ecx
    add edx,[Display.ClipBtm]
    add ecx,[Display.ClipRight]
    ;cmp [esi+SavedClips.ClipBtm],dword 0
    ;jg .MergeArea
    ;
    ;; first time accumulation so just copy item clip dimensions to redraw area
    ;mov [esi+SavedClips.ClipTop],eax
    ;mov [esi+SavedClips.ClipLeft],edi
    ;mov [esi+SavedClips.ClipBtm],edx
    ;mov [esi+SavedClips.ClipRight],ecx
    ;jmp short .AreaMerged

    ; merge item clip with existing redraw area
.MergeArea:
    cmp [esi+SavedClips.ClipTop],eax
    jle .TopSame
    mov [esi+SavedClips.ClipTop],eax
.TopSame:
    cmp [esi+SavedClips.ClipLeft],edi
    jle .LeftSame
    mov [esi+SavedClips.ClipLeft],edi
.LeftSame:
    cmp [esi+SavedClips.ClipBtm],edx
    jge .BtmSame
    mov [esi+SavedClips.ClipBtm],edx
.BtmSame:
    cmp [esi+SavedClips.ClipRight],ecx
    jge .RightSame
    mov [esi+SavedClips.ClipRight],ecx
.RightSame:
.AreaMerged:
    ret
%endif
%endif


<GFX.ASM>
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
SetGuiItemClips:
    ; add GUI items relative top/left to display top/left
    ; calculate display ptr  (top*width)+left
    movsx edx,word [ebx+GuiObj.Top]
    movsx ecx,word [ebx+GuiObj.Left]
    mov eax,edx                 ;copy TopRow for later
    push ecx                    ;save LeftCol
    push ecx                    ;save LeftCol
    add edx,[esi+SavedClips.Top]
    add ecx,[esi+SavedClips.Left]
    mov [Display.Top],edx
    mov [Display.Left],ecx
    imul edx,[Display.Width]    ;row * screen byte width
    add edx,[Display.BasePtr]   ;+ offset in memory of screen
    add edx,ecx                 ;+ left column
    mov ecx,eax                 ;copy TopRow again
    mov [Display.Ptr],edx

    ; if gui top >= sclip top
    ;   clip top = 0
    ; else
    ;   clip top = sclip top - gui top
    ; endif
    ;(ecx=GuiObj.Top)
    sub eax,[esi+SavedClips.ClipTop]
    jge .TopOkay
    neg eax
    mov [Display.ClipTop],eax
    mov [Display.RedrawTop],eax
    jmp short .CheckBtm
.TopOkay:
    mov dword [Display.ClipTop],0
    mov dword [Display.RedrawTop],0

.CheckBtm:
    ; if sclip bottom - gui top <= item height
    ;   clip bottom = height
    ; else
    ;   clip bottom = sclip bottom - gui top
    ; endif
    sub ecx,[esi+SavedClips.ClipBtm]
    neg ecx
    cmp [ebx+GuiObj.Height],cx
    jge .ClippedBtm
    movzx ecx,word [ebx+GuiObj.Height]
.ClippedBtm:
    mov [Display.ClipBtm],ecx
    mov [Display.RedrawBtm],ecx

.CheckLeft:
    ; if gui left >= clip left
    ;   clip left = 0
    ; else
    ;   clip left = sclip left - gui left
    ; endif
    pop eax                     ;restore LeftCol
    pop ecx                     ;restore LeftCol
    sub eax,[esi+SavedClips.ClipLeft]
    jge .LeftOkay
    neg eax
    mov [Display.ClipLeft],eax
    mov [Display.RedrawLeft],eax
    jmp short .CheckRight
.LeftOkay:
    mov dword [Display.ClipLeft],0
    mov dword [Display.RedrawLeft],0

.CheckRight:
    ; if sclip right - gui left <= item width
    ;   clip right = width
    ; else
    ;   clip right = sclip right - gui left
    ; endif
    sub ecx,[esi+SavedClips.ClipRight]
    neg ecx
    cmp [ebx+GuiObj.Width],cx
    jge .ClippedRight
    movzx ecx,word [ebx+GuiObj.Width]
.ClippedRight:
    mov [Display.ClipRight],ecx
    mov [Display.RedrawRight],ecx
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
GetFontClips:
    movsx eax,word [esp+8]      ; get top row
    movzx ecx,byte [Font.Height]; get character height
    mov esi,[Font.CharsPtr]
    mov edi,[Display.Width]
    mov ebx,eax                 ; copy top row
.CheckTop:
    cmp [Display.ClipTop],eax   ; if top row < top clip
    jle .TopOk                  ;   difference = bottom clip - bottom column
    mov edx,[Display.ClipTop]   ;   set top row to top clip
    mov eax,edx
    sub edx,ebx                 ;   *4 bytes per character row
    lea esi,[esi+edx*4]         ; endif
.TopOk:
.CheckBtm:
    add ebx,ecx                 ; bottom row = top row + height
    cmp [Display.ClipBtm],ebx   ; if bottom row > bottom clip
    jge .BtmOk                  ;   set bottom row to bottom clip
    mov ebx,[Display.ClipBtm]   ; endif
.BtmOk:
    sub ebx,eax                 ; clipped height = bottom side - top side
    mov [Display.ClipHeight],ebx ; set character height
    jle .FullClip               ; exit if clipped height <= 0

    imul edi,eax                ; destination = top row * screen width
    movzx ecx,byte [Font.Width] ; get character width
    mov [Display.ClipCharsPtr],esi
    mov [Display.ClipWidth],ecx ; set character width

    movsx eax,word [esp+10]     ; get left column
    mov ebx,[Display.ClipLeft]
    mov edx,[Display.ClipRight]
    sub edx,ecx                 ; right clip - char width
    add ebx,edi                 ; left clip + row ptr
    add edx,edi                 ; (right clip - char width) + row ptr
    add edi,eax                 ; destination = row ptr + left column
    mov [Display.ClipLeftPtr],ebx
    mov [Display.ClipRightPtr],edx
    mov [Display.ClipPtr],edi

    clc
    ret

.FullClip:
    stc
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
%if 0
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Unlike all the other graphics routines, the cursor is NOT clipped to the
; current rectangle, only the screen.
DrawCursorImage:
    xor esi,esi
    ;mov eax,[Cursor.Row]
    ;mov ebx,[Cursor.Col]
    ;add eax,[Cursor.RowOffset]
    ;add ebx,[Cursor.ColOffset]
    mov eax,[Cursor.RowPrev]
    mov ebx,[Cursor.ColPrev]

    mov ecx,Cursor.Size
    test eax,eax
    jns .TopOk
    cmp eax,-Cursor.Size
    jbe .RowOffscreen
    add ecx,eax                 ;clipped height = cursor height - difference
    shl eax,4                   ;depends on cursor size
    xor edi,edi
    sub esi,eax                 ;skip clipped rows in cursor image
    jmp short .BtmOk
.RowOffscreen:
    ret
.TopOk:
    mov edx,eax
    mov edi,eax
    shl edx,6
    shl edi,8
    add edi,edx
    sub eax,Screen.Height-Cursor.Size
    jbe .BtmOk
    cmp eax,Cursor.Size         ;end if entire cursor is clipped
    jae .RowOffscreen
    sub ecx,eax                 ;clipped height = cursor height - difference
.BtmOk:

    mov edx,Cursor.Size
    test ebx,ebx
    jns .LeftOk
    cmp ebx,-Cursor.Size
    jbe .End
    sub esi,ebx                 ;skip clipped columns in cursor image
    add edx,ebx
    jmp short .RightOk
.LeftOk:
    add edi,ebx
    sub ebx,Screen.Width-Cursor.Size
    jbe .RightOk
    cmp ebx,Cursor.Size
    jae .End
    sub edx,ebx
.RightOk:

    ;cmp ecx,Cursor.Size
    ;ja near Err
    ;cmp edx,Cursor.Size
    ;ja near Err

    ;add edx,byte 3
    ;shr edx,2                   ;/4 for dwords
    mov ebx,Screen.Width
    mov eax,Cursor.Size
    sub ebx,edx                 ;get DisplayWidth - ColumnsWide
    sub eax,edx                 ;get CursorSize - ColumnsWide for source increment

    add edi,[Display.Ptr]
    ;add edi,Screen.Adr
    push eax                    ;save source increment
    mov dh,dl                   ;copy columns count
.NextDot:
    mov al,[edi]
    and al,[Cursor.Mask+esi]
    or al,[Cursor.Image+esi]
    mov [edi],al
    inc esi
    inc edi
    dec dl
    jnz .NextDot
    add esi,[esp]
    add edi,ebx
    mov dl,dh                   ;reset columns count
    dec ecx                     ;one less row
    jnz .NextDot
    add esp,byte 4
.End:
    ret


;컴컴컴컴컴컴컴컴컴컴
HideCursorImage:
    mov eax,[Cursor.RowPrev]
    mov ebx,[Cursor.ColPrev]
    call ClipCursorTransfer
    jmp TransferCursorImage


;컴컴컴컴컴컴컴컴컴컴
GrabCursorImage:
    mov eax,[Cursor.Row]
    mov ebx,[Cursor.Col]
    sub eax,[Cursor.RowOffset]
    sub ebx,[Cursor.ColOffset]
    mov [Cursor.RowPrev],eax
    mov [Cursor.ColPrev],ebx
    call ClipCursorTransfer
    xchg esi,edi
    xchg eax,ebx
    jmp TransferCursorImage


;컴컴컴컴컴컴컴컴컴컴
; Clips the row and column for an image transfer.
;
; (eax=row, ebx=column)
; (esi=bg image buffer, edi=destination, eax=source increment, ebx=dest increment)
ClipCursorTransfer:
    ;mov eax,[Cursor.Row]
    ;mov ebx,[Cursor.Col]
    ;add eax,[Cursor.RowOffset]
    ;add ebx,[Cursor.ColOffset]

    test eax,eax
    jns .TopOk
    xor eax,eax
    xor edi,edi
    jmp short .RowOkay
.TopOk:
    cmp eax,Screen.Height-Cursor.Size
    jb .BtmOk
    mov eax,Screen.Height-Cursor.Size
.BtmOk:
    mov edx,eax
    mov edi,eax
    shl edx,6
    shl edi,8
    add edi,edx
.RowOkay:
    test ebx,ebx
    jns .LeftOk
    xor ebx,ebx
    jmp short .ColOkay
.LeftOk:
    cmp ebx,Screen.Width-Cursor.Size
    jb .RightOk
    mov ebx,Screen.Width-Cursor.Size
.RightOk:
    add edi,ebx                 ;add column to destination
.ColOkay:

    xor eax,eax
    mov ebx,Screen.Width-Cursor.Size
    mov esi,Cursor.BgImage
    add edi,[Display.Ptr]
    ;add edi,Screen.Adr
    ret


;컴컴컴컴컴컴컴컴컴컴
; Either transfer image under cursor to buffer or from buffer back to screen.
;
; (esi=screen/buffer, edi=screen/buffer, eax=source increment, ebx=dest inc.)
TransferCursorImage:
    cld
    mov edx,Cursor.Size
.NextRow:
    mov ecx,Cursor.Size/4
    rep movsd
    add esi,eax
    add edi,ebx
    dec edx
    jnz .NextRow
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Old Scroll Handle button drawing
  %if 0
    mov cl,GuiClrWhite
    rol ecx,16                  ;swap width with color
    sub cx,byte 2               ;width -2
    add eax,1<<16               ;col+1
    push ecx                    ;width/color
    push eax                    ;row/col
    call DrawHline              ;top

    mov ax,[.HandleSize]        ;get height
    mov [esp+6],byte GuiClrBlack
    add ax,[.HandlePos]
    dec ax                      ;get bottom row
    mov [esp],ax                ;set top row
    call DrawHline              ;bottom

    mov eax,GuiClrLGray<<16
    mov ecx,[.HandlePos]        ;row/col
    mov ax,[.HandleSize]        ;get height
    sub ax,byte 2
    inc cx                      ;row+1
    push eax
    push ecx
    call DrawVline              ;left

    mov ax,[.HandleSize+2]      ;get width
    mov [esp+6],byte GuiClrDGray
    add ax,[.HandlePos+2]
    dec ax                      ;get right column
    mov [esp+2],ax              ;set left column
    call DrawVline              ;right

    mov eax,[.HandleSize]       ;height/width
    mov ecx,[.HandlePos]        ;row/col
    sub eax,20000h              ;width-2
    add ecx,10000h              ;row+1
    sub ax,byte 2               ;height-2
    inc cx                      ;left+1
    push dword GuiClrFace       ;color
    push eax                    ;height/width
    push ecx                    ;row/col
    call DrawRect
    add esp,byte 12+8+8
  %endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Old Scan for key
; Scans through a list of key presses and returns the index matching the
; keypress given, or error if it wasn't found. Simply pass the keycode (which
; holds the ASCII character and scancode in bytes 2&3 of eax) and a scan
; structure to it, which contains a list of keys, number of normal keys, and
; number of extended.
;
; The key list is limited to 255 keys to compare with.
;
; (eax=msg/keycode, esi=keylist struct)
; (cf=error keypress not found, ecx=keynumber; eax,esi,ebx)
ScanForKeyOld:
    stc ;hack for now
    ret

    push eax
    cld
    lea edi,[esi+2]
    movzx ecx,byte [esi]
    test ah,ah
    jz .ExtendedKey
    mov al,ah
    repne scasb
    jnz .NotFound
    not cl
    add cl,[esi]
    pop eax
    clc
    ret

.ExtendedKey:
    add edi,ecx
    shr eax,16              ;bring down scancode
    mov cl,[esi+1]
    repne scasb
    jnz .NotFound
    not cl
    add cl,[esi+1]
    add cl,[esi]
    ;clc (add does this)
    pop eax
    ret

.NotFound:
    stc
    pop eax
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Old Cursor drawing ruotines GFX.ASM
DrawCursorImage:

    ; first grab region of screen under cursor
    mov eax,[Cursor.Row]
    mov ebx,[Cursor.Col]
    sub eax,[Cursor.RowOffset]
    sub ebx,[Cursor.ColOffset]

    ; clip the row and column for an image transfer
    test eax,eax
    jns .TopOk2
    xor eax,eax
    jmp short .BtmOk2
.TopOk2:
    cmp eax,Screen.Height-Cursor.Size
    jb .BtmOk2
    mov eax,Screen.Height-Cursor.Size
.BtmOk2:
    test ebx,ebx
    jns .LeftOk2
    xor ebx,ebx
    jmp short .RightOk2
.LeftOk2:
    cmp ebx,Screen.Width-Cursor.Size
    jb .RightOk2
    mov ebx,Screen.Width-Cursor.Size
.RightOk2:

 %ifdef UseDisplayBuffer
    push eax
    push ebx
 %else
    mov [Cursor.RowPrev],eax
    mov [Cursor.ColPrev],ebx
 %endif

    call CalcCursorBgAdr
    xchg eax,ebx                ;swap wrap increments
    xchg esi,edi                ;swap buffer with bg img (buffer -> bg img)
    call TransferCursorImage

;컴컴컴컴컴컴컴컴컴컴
    ; now draw the cursor
    xor esi,esi
    mov eax,[Cursor.Row]
    mov ebx,[Cursor.Col]
    sub eax,[Cursor.RowOffset]
    sub ebx,[Cursor.ColOffset]

    ; clip vertically
    mov ecx,Cursor.Size
    test eax,eax
    jns .TopOk
    cmp eax,-Cursor.Size
    jbe .RowOffscreen
    add ecx,eax                 ;clipped height = cursor height - difference
    shl eax,4                   ;depends on cursor size
    xor edi,edi
    sub esi,eax                 ;skip clipped rows in cursor image
    jmp short .BtmOk
.RowOffscreen:
 %ifdef UseDisplayBuffer
    add esp,byte 8
 %endif
    ret
.TopOk:
 %if Screen.Width=320
    mov edx,eax
    mov edi,eax
    shl edx,6                   ;row * 64
    shl edi,8                   ;row * 256
    add edi,edx                 ;(row * 64) + (row * 256) = row * 320
 %else
    mov edi,eax
    imul edi,Screen.Width       ;row * screen width
 %endif
    sub eax,Screen.Height-Cursor.Size
    jbe .BtmOk
    cmp eax,Cursor.Size         ;end if entire cursor is clipped
    jae .RowOffscreen
    sub ecx,eax                 ;clipped height = cursor height - difference
.BtmOk:

    ; clip horizontally
    mov edx,Cursor.Size
    test ebx,ebx
    jns .LeftOk
    cmp ebx,-Cursor.Size
    jbe .ColOffscreen
    sub esi,ebx                 ;skip clipped columns in cursor image
    add edx,ebx
    jmp short .RightOk
.ColOffscreen:
 %ifdef UseDisplayBuffer
    add esp,byte 8
 %endif
    ret
.LeftOk:
    add edi,ebx
    sub ebx,Screen.Width-Cursor.Size
    jbe .RightOk
    cmp ebx,Cursor.Size
    jae .End
    sub edx,ebx
.RightOk:

    ;add edx,byte 3
    ;shr edx,2                   ;/4 for dwords
    mov ebx,Screen.Width
    mov eax,Cursor.Size
    sub ebx,edx                 ;get DisplayWidth - ColumnsWide
    sub eax,edx                 ;get CursorSize - ColumnsWide for source increment

    ; draw cursor over screen
    add edi,Screen.Buffer
    push eax                    ;save source increment
    mov dh,dl                   ;copy columns count
.NextDot:
    mov al,[edi]
    and al,[Cursor.Mask+esi]
    or al,[Cursor.Image+esi]
    mov [edi],al
    inc esi
    inc edi
    dec dl
    jnz .NextDot
    add esi,[esp]
    add edi,ebx
    mov dl,dh                   ;reset columns count
    dec ecx                     ;one less row
    jnz .NextDot
    add esp,byte 4

;컴컴컴컴컴컴컴컴컴컴
    ; finally, transfer changed rectangle to virtual screen

 %ifdef UseDisplayBuffer
    mov eax,[Cursor.RowPrev]
    mov ebx,[Cursor.ColPrev]
    call CalcCursorImgAdr
    call TransferCursorImage    ;virtual buffer -> physical screen
    pop ebx
    pop eax
    mov [Cursor.ColPrev],ebx
    mov [Cursor.RowPrev],eax
    call CalcCursorImgAdr
    jmp TransferCursorImage     ;virtual buffer -> physical screen
 %endif
.End:
    ret
%endif
%endif


%ifdef UseGuiCursor
;컴컴컴컴컴컴컴컴컴컴
HideCursorImage:
    mov eax,[Cursor.RowPrev]
    mov ebx,[Cursor.ColPrev]
    push dword TransferCursorImage
    jmp CalcCursorBgAdr
%endif


%ifdef UseGuiCursor
;컴컴컴컴컴컴컴컴컴컴
CalcCursorBgAdr:
    call CalcCursorAdr
    xor eax,eax
    mov esi,Cursor.BgImage
    add edi,Screen.Buffer
    mov ebx,Screen.Width-Cursor.Size
    ret
%endif


%ifdef UseGuiCursor
%ifdef UseDisplayBuffer
;컴컴컴컴컴컴컴컴컴컴
CalcCursorImgAdr:
    call CalcCursorAdr
    lea esi,[Screen.Buffer+edi]
    mov eax,Screen.Width-Cursor.Size
%ifdef DosVer
    add edi,Screen.Adr
%endif
    mov ebx,eax
    ret
%endif
%endif


%ifdef UseGuiCursor
;컴컴컴컴컴컴컴컴컴컴
; Simply calculates screen pointers based on row/col.
;
; (eax=row, ebx=column)
CalcCursorAdr:
%if Screen.Width=320
    mov edx,eax
    mov edi,eax
    shl edx,6                   ;row * 64
    shl edi,8                   ;row * 256
    add edi,edx                 ;(row * 64) + (row * 256) = row * 320
%else
    mov edi,eax
    imul edi,Screen.Width       ;row * screen width
%endif
    add edi,ebx                 ;add column to destination
    ret
%endif


%ifdef UseGuiCursor
;컴컴컴컴컴컴컴컴컴컴
; Either transfer image under cursor to buffer or from buffer back to screen.
;
; (esi=screen/buffer, edi=screen/buffer, eax=source increment, ebx=dest inc.)
TransferCursorImage:
    cld
    mov edx,Cursor.Size
.NextRow:
    mov ecx,Cursor.Size/4
    rep movsd
    add esi,eax
    add edi,ebx
    dec edx
    jnz .NextRow
    ret

%endif


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Failed idea to capture mouse
.HookProc:
    params .nCode, .message, .mouseInfo

    cmp dword [esp+.nCode],0
    jl .Chain

    mov edx,[esp+.mouseInfo]
    ;debugwrite "mouse hookproc @%X thwnd=%X chwnd=%X",edx,[hwnd],[edx+MOUSEHOOKSTRUCT.hwnd]

    mov eax,[edx+MOUSEHOOKSTRUCT.hwnd]
    cmp [hwnd],eax
    je .Chain

    ;api PostThreadMessage, [tid], WM_MOUSEMOVE, 0, 32767|(32767<<16)
    ;mov ecx,[hwnd]
    mov ecx,[tid]
    ;mov ecx,[MainWindow+GuiObj.Flags]
    debugwrite "hookproc: moved out, tid = %X",ecx
    ;debugwrite "hookproc: moved out, tid = %s",ProgramTitle
    
.Chain:
    api CallNextHookEx, [Mouse.Hook], [esp+8+.nCode],[esp+4+.message],[esp+.mouseInfo]
    ret 12

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Ineffective idea to capture mouse #2
GetMouseMsg:
    mov eax,Msg.MouseMove               ;initial message, no flags
    movsx edx,word [msg+MSG.lParam+2]   ;sign row
    movsx ecx,word [msg+MSG.lParam]     ;sign column
    cmp [Cursor.Row],edx
    jne .Moved
    cmp [Cursor.Col],ecx
    je .NotMoved
.Moved:
    or eax,MouseFocusFlags.MouseMoved
    or byte [Display.RedrawFlags],Display.RedrawCursor
.NotMoved:
    xchg [Cursor.Row],edx
    xchg [Cursor.Col],ecx
    sub edx,[Cursor.Row]
    sub ecx,[Cursor.Col]
    neg edx
    neg ecx
    mov [Cursor.RowDif],edx
    mov [Cursor.ColDif],ecx
    pop ecx
    pop edx



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

    not bh
    and bl,bh
    test bl,Mouse.LeftDown|Mouse.RightDown|Mouse.MiddleDown
    jnz near .Captured
    push eax
    api WindowFromPoint, [msg+MSG.x],[msg+MSG.y]
    ;debugwrite "hwnd at point = %d",eax
    mov edx,eax
    xchg [Mouse.hwnd],eax
    cmp eax,edx
    je near .SameHwnd
    cmp [hwnd],edx
    pop ecx                     ;waste previous message
    je .MovedIn
.MouseOut:
    debugwrite "mouse moved out window"
    ;api ClipCursor, NULL
    mov dword [Cursor.Row],32767
    mov dword [Cursor.Col],32767
    or byte [Display.RedrawFlags],Display.RedrawCursor
    mov eax,Msg.MouseOut|MouseFocusFlags.MouseMoved
    ret
.MovedIn:
    debugwrite "mouse moved in window"
    ;mov dword [rect+RECT.left],   -4096
    ;mov dword [rect+RECT.top],    -4096
    ;mov dword [rect+RECT.right],  4096
    ;mov dword [rect+RECT.bottom], 4096
    ;api ClipCursor, rect
    api SetCapture, [hwnd]
    mov eax,Msg.MouseIn|MouseFocusFlags.MouseMoved
    ret
.SameHwnd:
    pop eax
.Captured:

    cmp eax,1
    ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Old GetItemKeyIdx
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
%if 0
    movzx ecx,word [ebx+WindowObj.TotalItems]
    lea esi,[ebx+WindowObj.ItemsKeyIdx-8+ecx*8]  ;start at last item
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


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 Shows scancode keypress in handler
.ShowKey:
    pusha
    and eax,255
    mov byte [NumToString.FillChar],' '
    mov edi,NumToString.Buffer
    mov ebx,16
    mov ecx,4
    call NumToString.UseDLRadix

    mov edi,[.ScrnPtr]
    mov al,[NumToString.Buffer]
    mov [edi],al
    mov al,[NumToString.Buffer+1]
    mov [edi+2],al
    mov al,[NumToString.Buffer+2]
    mov [edi+4],al
    mov al,[NumToString.Buffer+3]
    mov [edi+6],al

    add edi,byte 4*2
    cmp edi,0B8000h+(80*25*2)
    jb .ScrnPtrOk
    push es
    push ds
    pop es
    mov eax,' '|(7<<8)|(' '<<16)|(7<<24)
    mov edi,0B8000h
    mov ecx,(80*25*2)/4
    rep stosd
    mov edi,0B8000h
    pop es
.ScrnPtrOk:
    mov [.ScrnPtr],edi

    popa
    ret

section data
.ScrnPtr:   dd 0B8000h
section code






%if 0
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Sends message to item's container without saving item's data ptr
;
; (eax=message, ebx=sending item's gui ptr)
; (container's return value; !)
SendContainerMsgNoSave:
    mov ebx,[ebx+GuiObj.Container] ;get ptr to item's container
SendMsg: ;(eax=message, ebx=item's gui ptr)
    push ebx                    ;pass item's/container's data structure
    call [ebx+GuiObj.Code]
    lea esp,[esp+4]             ;do not affect carry or any other registers
    ret
%endif

%if 0
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Useful for chaining a message to the container with no need to return
;
; (eax=message, dword sending item's gui ptr, ebx=also item ptr, optional params...)
; (!no return)
ChainContainerMsg:
    mov ebx,[ebx+GuiObj.Container] ;get ptr to item's container
    mov [esp+4],ebx
    jmp [ebx+GuiObj.Code]
%endif

%if 0
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Useful for chaining a message to the container with no need to return
;
; (eax=message, dword sending item's gui ptr, duplicate item ptr)
; (!no return)
ChainContainerMsgIdx:
    mov si,[ebx+GuiObj.Idx]        ;note: list idx is actually a word
    mov ebx,[ebx+GuiObj.Container] ;get ptr to item's container
    mov [esp+8],si
    mov [esp+4],ebx
    jmp [ebx+GuiObj.Code]
%endif




;컴컴컴컴
;--.Items:                         ;all the objects in a window (8*x)
;.ItemsPtr:      resd 1          ;ptr to item data
;.ItemsLayer:    resw 1          ;mouse layer, index points to another item in the window list
;.ItemsKeyIdx:   resw 1          ;key order, index points to another item in the window list
;.Items_size     equ 8


struc WindowObjItems
.Ptr:           resd 1          ;ptr to item data
.Layer:         resw 1          ;mouse layer, index points to another item in the window list
.KeyIdx:        resw 1          ;key order, index points to another item in the window list
.SizeOf:                        ;size of each entry in container list
endstruc

