.Items:
        DefContainedItem mainbg
        DefContainedItem btnDummy
        DefContainedItem wndRecord
        DefContainedItem FloatMenu
        DefWindowEnd

DefItem mainbg,MainBgCode,0,GuiObj.NoKeyFocus|GuiObj.FixedLayer|GuiObj.FixedPosition, 0,0,Screen.Height,Screen.Width

DefItem btnDummy,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 178,10,12,36
        DefPushButton btnStart.Text,5,0

DefItem FloatMenu,FloatMenuCode,mnuFloatOwner,FloatMenuObj.DefFlags, 138,155,180,90
        DefMenuObj mnuFileOrder

        DefSubmenu mnuFileOrder,IgnoreMsg
        DefSubmenuItem .Name,       .0,0, 0
        DefSubmenuItem .Date,       .1,0, 0
        DefSubmenuItem .Size,       .2,0, 0
        DefSubmenuItem .Type,       .3,0, 0
        DefSubmenuItem .Folders,    .4,0, 0
        DefSubmenuEnd

DefItem wndRecord,WindowCode,NullGuiItem,WindowObj.DefFlags, 0,0,56,200;169,200
        DefWindow NullGuiItem,0,0
        DefContainedItem windowbg1
        DefContainedItem titlebar2
        DefContainedItem labelr3
        DefContainedItem border4
        DefContainedItem textprompt5
        DefContainedItem btnRecordMidi
        DefContainedItem labelr7
        DefContainedItem border8
        DefContainedItem textprompt9
        DefContainedItem btnRecordDsp
        DefContainedItem labelr11
        DefContainedItem border12
        DefContainedItem textprompt13
        DefContainedItem btnRecordWave
        DefContainedItem label15
        DefContainedItem border16
        DefContainedItem txtFilename
        DefContainedItem border18
        DefContainedItem label19
        DefContainedItem label20
        DefContainedItem label21
        DefContainedItem label22
        DefContainedItem label23
        DefContainedItem label24
        DefContainedItem color25 ;unknown item
        DefContainedItem label26
        DefContainedItem label27
        DefContainedItem label28
        DefContainedItem scroll29
        DefContainedItem btnStart
        DefContainedItem picture31
        DefContainedItem btnCancel
        DefContainedItem picture33
        DefContainedItem border34
        DefContainedItem picture35
        DefContainedItem label36
        DefContainedItem border37
        DefContainedItem picture38
        DefContainedItem label39
        DefContainedItem btnFileOrder
        DefContainedItem picture41
        DefWindowEnd
        %define GuiObjContainer wndRecord
DefItem windowbg1,WindowBgCode,0,WindowBgObj.DefFlags, 0,0,2048,2048
DefItem titlebar2,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags, 2,2+20,9,196-20
        DefTitleBar titlebar2.Text,6,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem labelr3,LabelCode,0,LabelObj.DefFlags, 16,3,8,20
        DefLabel labelr3.Text,4,LabelObj.AlignRight
DefItem border4,BorderCode,0,BorderObj.DefFlags, 13,25,12,134
        textprompt5.MaxLen equ 18+50
DefItem textprompt5,TextPromptCode,NullGuiItem,TextPromptObj.DefFlags|GuiObj.NoKeyFocus, 14,26,10,132
        DefTextPrompt textprompt5.Text,18,textprompt5.MaxLen,TextPromptObj.Locked
DefItem btnRecordMidi,ButtonCode,btnRecordFileOwner,ButtonObj.DefFlags, 13,161,12,36
        DefPushButton .Text,4,0
DefItem labelr7,LabelCode,0,LabelObj.DefFlags, 30,3,8,20
        DefLabel labelr7.Text,3,LabelObj.AlignRight
DefItem border8,BorderCode,0,BorderObj.DefFlags, 27,25,12,134
        textprompt9.MaxLen equ 20+50
DefItem textprompt9,TextPromptCode,NullGuiItem,TextPromptObj.DefFlags|GuiObj.NoKeyFocus, 28,26,10,132
        DefTextPrompt textprompt9.Text,20,textprompt9.MaxLen,TextPromptObj.Locked
DefItem btnRecordDsp,ButtonCode,btnRecordFileOwner,ButtonObj.DefFlags, 27,161,12,36
        DefPushButton .Text,6,0
DefItem labelr11,LabelCode,0,LabelObj.DefFlags, 44,3,8,20
        DefLabel labelr11.Text,4,LabelObj.AlignRight
DefItem border12,BorderCode,0,BorderObj.DefFlags, 41,25,12,134
        textprompt13.MaxLen equ 50+50
DefItem textprompt13,TextPromptCode,NullGuiItem,TextPromptObj.DefFlags|GuiObj.NoKeyFocus, 42,26,10,132
        DefTextPrompt textprompt13.Text,50,textprompt13.MaxLen,TextPromptObj.Locked
DefItem btnRecordWave,ButtonCode,btnRecordFileOwner,ButtonObj.DefFlags, 41,161,12,36
        DefPushButton .Text,6,0
DefItem label15,LabelCode,0,LabelObj.DefFlags|GuiObj.GroupStart, 56,3,8,194
        DefLabel label15.Text,50,LabelObj.AlignLeft
DefItem border16,BorderCode,0,BorderObj.DefFlags, 65,3,12,194
        txtFilename.MaxLen equ 3+50
DefItem txtFilename,TextPromptCode,NullGuiItem,TextPromptObj.DefFlags, 66,4,10,192
        DefTextPrompt .Text,3,.MaxLen,0
DefItem border18,BorderCode,0,BorderObj.DefFlags, 78,3,74,187
DefItem label19,LabelCode,0,LabelObj.DefFlags, 80,5,8,52
        DefLabel label19.Text,8,LabelObj.AlignLeft
DefItem label20,LabelCode,0,LabelObj.DefFlags, 88,9,8,52
        DefLabel label20.Text,3,LabelObj.AlignLeft
DefItem label21,LabelCode,0,LabelObj.DefFlags, 96,13,8,52
        DefLabel label21.Text,5,LabelObj.AlignLeft
DefItem label22,LabelCode,0,LabelObj.DefFlags, 104,17,8,52
        DefLabel label22.Text,4,LabelObj.AlignLeft
DefItem label23,LabelCode,0,LabelObj.DefFlags, 112,21,8,52
        DefLabel label23.Text,9,LabelObj.AlignLeft
DefItem label24,LabelCode,0,LabelObj.DefFlags, 120,21,8,52
        DefLabel label24.Text,10,LabelObj.AlignLeft
DefItem color25,BorderCode,NullGuiItem,BorderObj.DefFlags, 127,4,8,185
DefItem label26,LabelCode,0,LabelObj.DefFlags, 128,21,8,52
        DefLabel label26.Text,11,LabelObj.AlignLeft
DefItem label27,LabelCode,0,LabelObj.DefFlags, 136,21,8,52
        DefLabel label27.Text,6,LabelObj.AlignLeft
DefItem label28,LabelCode,0,LabelObj.DefFlags, 144,21,8,52
        DefLabel label28.Text,7,LabelObj.AlignLeft
DefItem scroll29,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefFlags, 78,191,74,6
        DefScrollHandle 100,0,0,1,10
DefItem btnStart,ButtonCode,btnStartOwner,ButtonObj.DefFlags|GuiObj.GroupStart, 154,3,12,36
        DefPushButton .Text,5,0
DefItem picture31,ImageCode,0,ImageObj.DefFlags, 156,5,8,8
        DefImage picture31.Image,0
DefItem btnCancel,ButtonCode,btnCancelOwner,ButtonObj.DefFlags, 154,41,12,36
        DefPushButton .Text,6,0
DefItem picture33,ImageCode,0,ImageObj.DefFlags, 156,43,8,8
        DefImage picture33.Image,0
DefItem border34,BorderCode,0,BorderObj.DefFlags, 154,79,12,36
DefItem picture35,ImageCode,0,ImageObj.DefFlags, 156,81,8,8
        DefImage picture35.Image,0
DefItem label36,LabelCode,0,LabelObj.DefFlags, 157,91,8,24
        DefLabel label36.Text,6,LabelObj.AlignLeft
DefItem border37,BorderCode,0,BorderObj.DefFlags, 154,117,12,36
DefItem picture38,ImageCode,0,ImageObj.DefFlags, 156,119,8,8
        DefImage picture38.Image,0
DefItem label39,LabelCode,0,LabelObj.DefFlags, 157,129,8,24
        DefLabel label39.Text,4,LabelObj.AlignLeft
DefItem btnFileOrder,ButtonCode,btnFileOrderOwner,ButtonObj.DefFlags, 154,155,12,36
        DefPushButton .Text,4,2
DefItem picture41,ImageCode,0,ImageObj.DefFlags, 156,157,8,8
        DefImage picture41.Image,0

        titlebar2.Text: db "Record"
        labelr3.Text: db "MIDI"
        textprompt5.Text: db "c:\music\zelda.mid"
        times 50 db 0
        btnRecordMidi.Text: db "Stop"
        labelr7.Text: db "DSP"
        textprompt9.Text: db "c:\src\spc\zelda.dsp"
        times 50 db 0
        btnRecordDsp.Text: db "Record"
        labelr11.Text: db "Wave"
        textprompt13.Text: db "c:\music\sounds\raw\somereallylongfolder\zelda.wav"
        times 50 db 0
        btnRecordWave.Text: db "Record"
        label15.Text: db "Super Magicom SNES ROM   524388 bytes   1996-05-23"
        txtFilename.Text: db "mar"
        times 50 db 0
        label19.Text: db "[Drives]"
        label20.Text: db "C:\"
        label21.Text: db "Games"
        label22.Text: db "SNES"
        label23.Text: db "mario.zs3"
        label24.Text: db "mariow.zmv"
        label26.Text: db "mariow2.smc"
        label27.Text: db "(pics)"
        label28.Text: db "(saves)"
        btnStart.Text: db "Start"
        DefImageStruc picture31.Image,8,8
        db 2,2,2,2,2,2,11,2,2,2,2,2,2,11,11,11,2,2,2,2,11,11,11,10,2,11,2,11,11,11,10,10,11,11,11,11,11,10,10,2,10,11,11,11,10,10,2,2,2,10,11,10,10,2,2,2,2,2,10,10,2,2,2,2,2,2,2,2,2,2,2,0,3,4,2,2,2,2,2,2,2,2,2,0,3,2,2,2,2,2,2,2,2,2,2,0,3,4,2,2,2,2,2,2,2,2,2,0,3,2,2,2,2,2,2,2,2,2,2,2,2
        btnCancel.Text: db "Cancel"
        DefImageStruc picture33.Image,8,8
        db 2,15,2,2,2,15,2,2,15,15,15,2,15,15,15,2,1,15,15,15,15,15,1,1,2,1,15,15,15,1,1,2,2,15,15,15,15,15,2,2,15,15,15,1,15,15,15,2,1,15,1,1,1,15,1,1,2,1,1,2,2,1,1,2,2,2,2,2,2,2,2,0,3,4,2,2,2,2,2,2,2,2,2,0,3,2,2,2,2,2,2,2,2,2,2,0,3,4,2,2,2,2,2,2,2,2,2,0,3,2,2,2,2,2,2,2,2,2,2,2,2
        DefImageStruc picture35.Image,8,8
        db 2,2,2,2,2,15,2,2,2,2,2,2,13,15,15,12,2,2,2,13,13,13,12,12,2,2,13,13,13,12,12,2,2,13,13,13,12,12,2,2,13,13,13,12,12,2,2,2,13,13,12,12,2,2,2,2,2,12,12,2,2,2,2,2,2,2,2,2,2,2,2,0,3,4,2,2,2,2,2,2,2,2,2,0,3,2,2,2,2,2,2,2,2,2,2,0,3,4,2,2,2,2,2,2,2,2,2,0,3,2,2,2,2,2,2,2,2,2,2,2,2
        label36.Text: db "Action"
        DefImageStruc picture38.Image,8,8
        db 2,9,9,9,9,8,2,2,9,9,9,9,9,9,8,2,9,9,8,8,9,9,8,2,2,8,9,9,9,9,8,2,2,2,9,9,9,8,8,2,2,2,2,8,8,8,2,2,2,2,9,9,8,2,2,2,2,2,9,9,8,2,2,2,2,2,2,2,2,2,2,0,3,4,2,2,2,2,2,2,2,2,2,0,3,2,2,2,2,2,2,2,2,2,2,0,3,4,2,2,2,2,2,2,2,2,2,0,3,2,2,2,2,2,2,2,2,2,2,2,2
        label39.Text: db "Info"
        btnFileOrder.Text: db "View"
        DefImageStruc picture41.Image,8,8
        db 2,2,7,7,2,2,2,2,2,7,6,6,7,2,2,2,7,6,2,2,6,7,2,2,7,2,2,2,2,7,2,2,6,7,2,2,7,7,2,2,2,6,7,7,7,7,7,2,2,2,6,6,6,7,7,7,2,2,2,2,2,6,7,6,2,2,2,2,2,2,2,0,3,4,2,2,2,2,2,2,2,2,2,0,3,2,2,2,2,2,2,2,2,2,2,0,3,4,2,2,2,2,2,2,2,2,2,0,3,2,2,2,2,2,2,2,2,2,2,2,2

        mnuFileOrder.0: db "Name",0
        mnuFileOrder.1: db "Date",0
        mnuFileOrder.2: db "Size",0
        mnuFileOrder.3: db "Type",0
        mnuFileOrder.4: db "Folders",0

section code
    dd btnStartOwner
btnStartOwner:
    cld
    mov esi,txtFilename.Text
    mov edi,textprompt5.Text
    mov ecx,textprompt5.MaxLen
    mov edx,[txtFilename+TextPromptObj.TextLen]
    rep movsb
    mov [textprompt5+TextPromptObj.TextLen],edx
    jmp short btnCancelOwner

    dd btnRecordFileOwner
btnRecordFileOwner:
    cmp word [wndRecord+GuiObj.Height],56
    ja btnCancelOwner
    mov eax,Msg.SetKeyFocus|KeyFocusFlags.Specified|KeyFocusFlags.SetGroup|KeyFocusFlags.SetItem
    mov ebx,txtFilename
    call SendContainerMsg

    push dword 169|(200<<16)    ;size (unchanged)
    push dword 80008000h        ;pos unchanged
    jmp short SetRecordWindowSize

    dd btnCancelOwner
btnCancelOwner:
    push dword 56|(200<<16)     ;size (unchanged)
    push dword 80008000h        ;pos unchanged

SetRecordWindowSize:
    mov eax,Msg.MoveSize
    mov ebx,wndRecord
    call SendContainerMsg
    add esp,byte 8
    ;clc
    ret

    dd btnFileOrderOwner
btnFileOrderOwner:
    mov ebx,btnFileOrder
    mov byte [ebx+ButtonObj.Value],2
    call GetItemAbsPosition
    push dword [ebx+GuiObj.Size]
    push cx
    push dx
    push dword FloatMenuObj.AlignRow|FloatMenuObj.AlignCol
    push dword mnuFloatOwner
    push dword mnuFileOrder
    call FloatMenuCode.Show
    add esp,byte 20
    ret

    dd mnuFloatOwner
mnuFloatOwner:
    cmp al,MenuMsg.Activate
    jne .Ignore
    call FloatMenuCode.Hide
    clc
    ret
.Ignore:
    stc
    ret

section data
