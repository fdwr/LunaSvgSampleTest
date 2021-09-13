;attribute list test
%define ProgramTitleDef "Attribute list test"
        DefWindow AtrList,0,0        
        ;DefContainedItem MainBg
        DefContainedItem border1
        DefContainedItem AtrList
        DefWindowEnd

;main window items
        db "MainBg"
;DefItem MainBg,MainBgCode,0,GuiObj.NoMouseFocus|GuiObj.NoKeyFocus|GuiObj.FocusUnaware|GuiObj.FixedLayer, 0,0,Screen.Height,Screen.Width
        DefTitleBar ProgramTitle,17,TitleBarObj.HelpButton

DefItem border1,BorderCode,0,BorderObj.DefFlags, 2,2,52,104
DefItem AtrList,AtrListCode,AtrListOwner,AtrListObj.DefFlags, 4,4,48,100
        DefAtrList NullGuiItem ;no scroll bar
        DefAtrListItem AtrList.Name0,7,AtrList.Atr0,8, 0, 0,0,7,    1,1,1
        DefAtrListItem AtrList.Name1,7,AtrList.Atr1,2, 0, 0,0,511,  1,1,1
        DefAtrListItem AtrList.Name2,6,AtrList.Atr2,5, 0, 0,0,12543,1,1,1
        AtrList.Volume equ $-AtrListObj.Items
        DefAtrListItem AtrList.Name3,7,AtrList.Atr3+1,4, 0, 0,0,1000, 1,10,100
        DefAtrListItem AtrList.Name4,9,AtrList.Atr4,8, 0, 0,0,0, 0,0,0
        DefAtrListEnd

        AtrList.Name0: db "Voices:"
        AtrList.Atr0:  db "12345678"
        AtrList.Name1: db "Sample:"
        AtrList.Atr1:  db "36"
        AtrList.Name2: db "Pitch:"
        AtrList.Atr2:  db "440hz"
        AtrList.Name3: db "Volume:"
        AtrList.Atr3:  db " 100%"
        AtrList.Name4: db "Checksum:"
        AtrList.Atr4:  db "2B1548F9"

%if 0
section code
MainBgCode:
    cmp al,Msg.Redraw
    stc
    jne .NoDraw
    push dword 8
    push dword 2048|(2048<<16)  ;height/width
    push dword 0                ;top/left
    call DrawRect
    add esp,byte 12
    ;clc ;add clears cf
.NoDraw:
    ret
%endif

    align 4
    dd AtrListOwner             ;owner code ptr for item
AtrListOwner:
    cmp ax,AtrListMsg.Change|(3<<8) ;one of the attribute values was changed by user
    jne .Ignore
    mov eax,[AtrList.Volume+AtrListObj.Value]
    mov edi,AtrList.Atr3
    mov ecx,4
    call NumToString.UsingDLen
    lea edi,[edi+ecx+1]
    neg ecx
    mov edx,3                   ;attribute index
    add ecx,byte 5
    mov dword [esp+4],AtrList
    jmp AtrListCode.SetAtr
    ;ret
.Ignore:
    stc
    ret
