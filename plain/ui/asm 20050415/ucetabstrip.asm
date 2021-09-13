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

