.Items:
        DefWindow NullGuiItem,0,0
        DefContainedItem mainbg
        DefContainedItem colors0
        DefContainedItem label0
        DefContainedItem label1
        DefContainedItem label2
        DefContainedItem label3
        DefContainedItem label4
        DefContainedItem label5
        DefContainedItem label6
        DefContainedItem label7
        DefContainedItem label8
        DefContainedItem label9
        DefContainedItem label10
        DefContainedItem titlebar0
        DefContainedItem titlebar1
        DefContainedItem titlebar2
        DefContainedItem scroll0
        DefContainedItem scroll1
        DefContainedItem scroll2
        DefContainedItem scroll3
        DefWindowEnd

DefItem mainbg,MainBgCode,NullGuiItem,BorderObj.DefGuiFlags, 0,0,Screen.Height,Screen.Width
FloatMenu:
DefItem titlebar0,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 2,2,9,86
        DefTitleBar titlebar0.Text,10,0
DefItem titlebar1,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 12,2,9,86
        DefTitleBar titlebar1.Text,10,0
DefItem titlebar2,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 22,2,9,86
        DefTitleBar titlebar2.Text,10,0

DefItem scroll0,ScrollHandleCode,ScrollHandleOwner,(ScrollHandleObj.DefGuiFlags|GuiObj.GroupStart)^GuiObj.NoKeyFocus, 52,21,110,6
        DefScrollHandle -1,0,0,1,100000000
DefItem scroll1,ScrollHandleCode,ScrollHandleOwner,(ScrollHandleObj.DefGuiFlags|GuiObj.GroupStart)^GuiObj.NoKeyFocus, 52,31,110,24;6
        DefScrollHandle 100,50,0,1,10
DefItem scroll2,ScrollHandleCode,ScrollHandleOwner,(ScrollHandleObj.DefGuiFlags|GuiObj.GroupStart)^GuiObj.NoKeyFocus, 173,99,6,210
        DefScrollHandle 100,50,0,1,10
DefItem scroll3,ScrollHandleCode,ScrollHandleOwner,(ScrollHandleObj.DefGuiFlags|GuiObj.GroupStart)^GuiObj.NoKeyFocus, 183,99,6,210
        DefScrollHandle 20,7,0,1,3

DefItem colors0,ColorsCode,0,GuiObj.NoKeyFocus|GuiObj.NoMouseFocus, 160,4,32,8

DefItem label0,LabelCode,0,LabelObj.DefGuiFlags, 44,48,8,256
        DefLabel label0.Text,24,LabelObj.AlignLeft
DefItem label1,LabelCode,0,LabelObj.DefGuiFlags, 56,52,8,256
        DefLabel label1.Text,23,LabelObj.AlignLeft
DefItem label2,LabelCode,0,LabelObj.DefGuiFlags, 64,52,8,256
        DefLabel label2.Text,59,LabelObj.AlignLeft
DefItem label3,LabelCode,0,LabelObj.DefGuiFlags, 72,52,8,256
        DefLabel label3.Text,45,LabelObj.AlignLeft
DefItem label4,LabelCode,0,LabelObj.DefGuiFlags, 80,52,8,256
        DefLabel label4.Text,47,LabelObj.AlignLeft
DefItem label5,LabelCode,0,LabelObj.DefGuiFlags, 88,52,8,256
        DefLabel label5.Text,49,LabelObj.AlignLeft
DefItem label6,LabelCode,0,LabelObj.DefGuiFlags, 100,52,8,256
        DefLabel label6.Text,45,LabelObj.AlignLeft
DefItem label7,LabelCode,0,LabelObj.DefGuiFlags, 108,52,8,256
        DefLabel label7.Text,36,LabelObj.AlignLeft
DefItem label8,LabelCode,0,LabelObj.DefGuiFlags, 116,52,8,256
        DefLabel label8.Text,24,LabelObj.AlignLeft
DefItem label9,LabelCode,0,LabelObj.DefGuiFlags, 128,48,8,256
        DefLabel label9.Text,43,LabelObj.AlignLeft
DefItem label10,LabelCode,0,LabelObj.DefGuiFlags, 136,48,8,256
        DefLabel label10.Text,61,LabelObj.AlignLeft

        titlebar0.Text: db ".........."
        titlebar1.Text: db ".........."
        titlebar2.Text: db ".........."

        label0.Text: db "Scroll handle behaviour:"
        label1.Text: db "Click on handle to drag"
        label2.Text: db "Click on either side of handle to pull it in that direction"
        label3.Text: db "Left click to scroll by small increment (row)"
        label4.Text: db "Right click to scroll by large increment (page)"
        label5.Text: db "Double click on a point to immediately jump there"
        label6.Text: db "Left/Right Up/Down scroll by small amount  "
        label7.Text: db "PgUp/PgDn scroll by large amount ",26," ",27
        label8.Text: db "Home/End jump to end  "
        label9.Text: db "32bit scroll bar handles ranges 1-4 billion"
        label10.Text: db "Same object handles both vertical and horizontal orientations"

    dd ScrollHandleOwner
ScrollHandleOwner:
    mov ebx,[esp+8]
    pusha
    mov eax,[ebx+ScrollHandleObj.Value]
    mov edi,titlebar0.Text
    mov ecx,10
    call NumToString.UsingDLen
    mov ebx,titlebar0
    call SendContainerRedraw.Partial

    mov ebx,[esp+8+32]
    mov eax,[ebx+ScrollHandleObj.Range]
    mov edi,titlebar1.Text
    mov ecx,10
    call NumToString.UsingDLen
    mov ebx,titlebar1
    call SendContainerRedraw.Partial

    mov eax,[ScrollHandleCode.DestValue]
    mov edi,titlebar2.Text
    mov ecx,10
    call NumToString.UsingDLen
    mov ebx,titlebar2
    call SendContainerRedraw.Partial

    popa
    ret

ColorsCode:
    mov edi,[Display.Ptr] ;Screen.Buffer+(320*100)+4
    xor eax,eax
    mov ecx,16
.NextColorBar:
    mov [edi],eax
    mov [edi+4],eax
    mov [edi+Screen.Width],eax
    mov [edi+Screen.Width+4],eax
    add edi,Screen.Width*2
    add eax,01010101h
    loop .NextColorBar
    ret
