%if 0
        DefContainedItem MainBg2
        DefContainedItem TestBtn
        DefWindowEnd

DefItem MainBg2,MainBgCode,0,GuiObj.NoKeyFocus|GuiObj.FixedLayer, 0,0,Screen.Height,Screen.Width
DefItem TestBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 24,310,12,68 ;24,54,12,68 
        DefPushButton TopBtn.Text,3,0

DummyWindow:
        %define GuiObjContainer DummyWindow
%endif

;main window list
        DefContainedItem MainBg
        DefContainedItem label0
        DefContainedItem label1
        DefContainedItem label2
        DefContainedItem label3
        DefContainedItem label4
        DefContainedItem BtmWnd
        DefContainedItem TopWnd
        DefContainedItem TopBtn
        DefContainedItem CenterBtn
        DefContainedItem BtmBtn
        ;DefContainedItem AtrWnd
        DefWindowEnd


;main window items
        db "MainBg"
        ;DefGuiObj MainBg,MainBgCode,0,GuiObj.NoMouseFocus|GuiObj.NoKeyFocus|GuiObj.FixedLayer, 0,0,Screen.Height,Screen.Width
DefItem MainBg,MainBgCode,0,GuiObj.NoKeyFocus|GuiObj.FixedLayer, 0,0,Screen.Height,Screen.Width
DefItem TopBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 24,54,12,68
        DefPushButton TopBtn.Text,3,0
DefItem CenterBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 30,34,12,68
        DefPushButton CenterBtn.Text,6,0
        db "TopWnd"
DefItem TopWnd,WindowCode,NullGuiItem,WindowObj.DefGuiFlags, 4,136,52,180
        DefWindow NullGuiItem,0,0
        ;DefContainedItem TwWinBg
        DefContainedItem border1
        DefContainedItem TwTb
        DefContainedItem border2
        DefContainedItem textprompt2
        DefContainedItem DumbLabel
        DefContainedItem SaveBtn
        DefContainedItem DiscardBtn
        DefContainedItem CancelBtn
        DefWindowEnd
;DefItem CenterBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 72,184,12,68
;CenterBtn: DefPushButton CenterBtn.Text,6,0
DefItem BtmBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 144,84,12,68
        DefPushButton BtmBtn.Text,6,0
        db "BtmWnd"
DefItem BtmWnd,WindowCode,NullGuiItem,WindowObj.DefGuiFlags, 100,30,96,180
        DefWindow NullGuiItem,0,0
        DefContainedItem BwWinBg
        DefContainedItem BwBtmTb
        DefContainedItem BwTopTb
        DefContainedItem LeftBtn
        DefContainedItem InnerWnd
        DefContainedItem RightBtn
        DefWindowEnd
DefItem label0,LabelCode,0,LabelObj.DefGuiFlags, 56,3,8,146
        DefLabel label0.Text,41,LabelObj.AlignLeft
DefItem label1,LabelCode,0,LabelObj.DefGuiFlags, 64,3,8,146
        DefLabel label1.Text,37,LabelObj.AlignLeft
DefItem label2,LabelCode,0,LabelObj.DefGuiFlags, 72,3,8,146
        DefLabel label2.Text,38,LabelObj.AlignLeft
DefItem label3,LabelCode,0,LabelObj.DefGuiFlags, 80,3,8,146
        DefLabel label3.Text,40,LabelObj.AlignLeft
DefItem label4,LabelCode,0,LabelObj.DefGuiFlags, 88,3,8,146
        DefLabel label4.Text,39,LabelObj.AlignLeft
        ;DefGuiObj AtrWnd,WindowCode,NullGuiItem,WindowObj.DefGuiFlags, 120,220,32,93
AtrWnd: DefWindow NullGuiItem,0,0
        DefContainedItem AwWinBg
        DefContainedItem border3
        DefContainedItem AtrList
        DefContainedItem scroll2
        DefWindowEnd


; top window
        %define GuiObjContainer TopWnd
;DefItem TwWinBg,WindowBgCode,0,WindowBgObj.DefGuiFlags, 0,0,32000,32000
DefItem border1,BorderCode,0,BorderObj.DefGuiFlags, 0,0,52,180
DefItem TwTb,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 2,2,9,176
        DefTitleBar TwTb.Text,27,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem border2,BorderCode,0,BorderObj.DefGuiFlags, 13,3,13,174
        textprompt2.MaxLen equ 20+50
DefItem textprompt2,TextPromptCode,NullGuiItem,TextPromptObj.DefGuiFlags, 14,4,11,172
        DefTextPrompt textprompt2.Text,20,textprompt2.MaxLen,0
DefItem DumbLabel,LabelCode,0,LabelObj.DefGuiFlags, 28,3,8,172
        DefLabel DumbLabel.Text,15,LabelObj.AlignLeft
DefItem SaveBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 37,3,12,56
        DefPushButton SaveBtn.Text,4,0
DefItem DiscardBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 37,62,12,56
        DefPushButton DiscardBtn.Text,7,0
DefItem CancelBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 37,121,12,56
        DefPushButton CancelBtn.Text,6,0


; bottom window
        %define GuiObjContainer BtmWnd
DefItem BwWinBg,WindowBgCode,0,WindowBgObj.DefGuiFlags, 0,0,32000,32000
DefItem BwTopTb,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 2,2,9,176
        DefTitleBar BwTopTb.Text,13,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem LeftBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 40,4,12,68
        DefPushButton LeftBtn.Text,4,0
DefItem InnerWnd,WindowCode,NullGuiItem,WindowObj.DefGuiFlags, 20,28,56,124
        DefWindow NullGuiItem,0,0
        DefContainedItem IwWinBg
        DefContainedItem InnerTb
        DefContainedItem HelloBtn
        DefWindowEnd
DefItem RightBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 40,108,12,68
        DefPushButton RightBtn.Text,5,0
DefItem BwBtmTb,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 85,2,9,176
        DefTitleBar .Text,16,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton


; innermost window
        %define GuiObjContainer InnerWnd
DefItem IwWinBg,WindowBgCode,0,WindowBgObj.DefGuiFlags, 0,0,32000,32000
DefItem InnerTb,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 2,2,9,120
        DefTitleBar InnerTb.Text,20,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem HelloBtn,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 24,16,12,92
        DefPushButton .Text,17,0


; attribute window
        %define GuiObjContainer AtrWnd
DefItem AwWinBg,WindowBgCode,0,WindowBgObj.DefGuiFlags, 0,0,32000,32000
DefItem border3,BorderCode,0,BorderObj.DefGuiFlags, 3,3,26,80
DefItem AtrList,AtrListCode,AtrListOwner,AtrListObj.DefGuiFlags, 4,4,24,78
        DefAtrList scroll2
        DefAtrListItem .Name0,7,.Atr0,8, 0, 0,0,7,    1,1,1
        DefAtrListItem .Name1,7,.Atr1,2, 0, 0,0,511,  1,1,1
        DefAtrListItem .Name2,6,.Atr2,5, 0, 0,0,12543,1,1,1
        AtrList.Volume equ $-AtrListObj.Items
        DefAtrListItem .Name3,7,.Atr3+1,4, 0, 0,0,1000, 1,10,100
        DefAtrListItem .Name4,9,.Atr4,8, 0, 0,0,0, 0,0,0
        DefAtrListEnd
DefItem scroll2,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefGuiFlags, 3,84,26,6
        DefScrollHandle 7,0,0,1,5

; main window
        TopBtn.Text: db "Top"
        CenterBtn.Text: db "Center"
        BtmBtn.Text: db "Bottom"
        label0.Text: db "Click on the buttons, grab the title bars"
        label1.Text: db "to move the windows, type in the text"
        label2.Text: db "prompt, press arrow keys or hover over"
        label3.Text: db "items to shift focus, press F10 to clear"
        label4.Text: db "the screen, or F9 to redraw everything."
; top window
        TwTb.Text: db "Transparent moveable window"
        textprompt2.Text: db "Type in something..."
        times 50 db 0
        DumbLabel.Text: db "Pointless label"
        SaveBtn.Text: db "Save"
        DiscardBtn.Text: db "Discard"
        CancelBtn.Text: db "Cancel"
;bottom window
        BwTopTb.Text: db "Top title bar"
        LeftBtn.Text: db "Left"
        RightBtn.Text: db "Right"
        BwBtmTb.Text: db "Bottom title bar"
;inner window
        InnerTb.Text: db "Window within window"
        HelloBtn.Text: db "Hello from inside"
; attribute window
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
    cmp al,Msg.MousePrsRls
    je .Press
    cmp al,Msg.Redraw
    stc
    jne .NoDraw
    push dword 8                ;dark blue
    push dword 2048|(2048<<16)  ;height/width
    push dword 0                ;top/left
    call DrawRect
    add esp,byte 12
    ;clc ;add clears cf
.NoDraw:
    ret
.Press:
    test dword [Mouse.Buttons],Mouse.LeftPress
    jz .Release

    mov ebx,[ebx+GuiObj.Container] ;get ptr to item's container
    push dword TopWnd
    push ebx                    ;pass container's data structure
    mov eax,Msg.Create
    call [ebx+GuiObj.Code]
    add esp,byte 8
    ret
.Release:
    test dword [Mouse.Buttons],Mouse.RightPress
    jz .NoRelease

    mov ebx,TopWnd
    mov eax,Msg.Destroy
    jmp SendContainerMsgIdx
.NoRelease:
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
