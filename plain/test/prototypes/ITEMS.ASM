; Just a list of GUI item data structures
; Separated from the rest of the code for simplicity

.Items:
        DefContainedItem TiWnd1
        DefContainedItem TiWnd2
        DefContainedItem TiTb
        DefContainedItem TiPb1
        DefContainedItem TiPb2
        DefContainedItem TiPb3
        DefContainedItem TiPb4
        DefContainedItem TiPb5
        DefContainedItem TiPb6
        DefContainedItem TiLbl
        DefContainedItem TiBdr
        DefContainedItem TiTp
        DefContainedItem TiBdr1
        DefContainedItem TiTp1
        DefContainedItem TiBdr2
        DefContainedItem TiTp2
        DefContainedItem TiPb9
        DefContainedItem TiPb10
        DefContainedItem TiPb11
        DefContainedItem TiPb12
        DefContainedItem TiPb13
        DefContainedItem TiPb14
        DefContainedItem TiPb15
        DefWindowEnd

;Test items
DefItem TiWnd1,WindowCode,NullGuiItem,WindowObj.DefGuiFlags, 100,270,90,40
        DefWindow TiPb20,0,0
.Items:
        DefContainedItem TiTb2
        DefContainedItem TiPb20
        DefContainedItem TiPb21
        DefWindowEnd

DefItem TiWnd2,WindowCode,NullGuiItem,WindowObj.DefGuiFlags, 5,150,90,40;100,220,90,40
        DefWindow TiTb3,0,0
.Items:
        DefContainedItem TiTb3
        DefWindowEnd

DefItem TiTb,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags|GuiObj.GroupStart, 8,4,9,220
        dd TiTb.Text
        dd TiTb.TextLen
        db TitleBarObj.HelpButton|TitleBarObj.CloseButton
DefItem TiPb1 ,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 28,20,12,64
        DefPushButton TiPb.Text,TiPb.TextLen,2
DefItem TiPb2 ,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 44,20,12,56
        DefPushButton TiPb.Text,TiPb.TextLen,0
DefItem TiPb3 ,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 60,20,12,48
        DefPushButton TiPb.Text,TiPb.TextLen,0
DefItem TiPb4 ,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 76,20,12,40
        DefPushButton TiPb.Text,TiPb.TextLen,0
DefItem TiPb5 ,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags|GuiObj.NoMouseFocus, 92,20,12,32
        DefPushButton TiPb.Text,TiPb.TextLen,0
DefItem TiPb6 ,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags|GuiObj.NoKeyFocus, 108,20,12,24
        DefPushButton TiPb.Text,TiPb.TextLen,0
DefItem TiLbl ,LabelCode,NullGuiItem,LabelObj.DefGuiFlags|GuiObj.GroupStart, 32,114,10,48
        DefLabel TiLbl.Text,TiLbl.TextLen,0
DefItem TiBdr ,BorderCode,0,BorderObj.DefGuiFlags, 39,113,12,50
        TiTp.MaxLen equ 100
DefItem TiTp  ,TextPromptCode,NullGuiItem,TextPromptObj.DefGuiFlags, 40,114,10,48
        DefTextPrompt TiTp.Text,TiTp.TextLen,TiTp.MaxLen,0
DefItem TiBdr1,BorderCode,0,BorderObj.DefGuiFlags, 52,113,12,50
DefItem TiTp1 ,TextPromptCode,NullGuiItem,TextPromptObj.DefGuiFlags, 53,114,10,48
        DefTextPrompt TiTp1.Text,TiTp1.TextLen,TiTp.MaxLen,2
DefItem TiBdr2,BorderCode,0,BorderObj.DefGuiFlags, 65,113,12,50
DefItem TiTp2 ,TextPromptCode,NullGuiItem,TextPromptObj.DefGuiFlags, 66,114,10,48
        DefTextPrompt TiTp2.Text,TiTp2.TextLen,TiTp.MaxLen,1
DefItem TiPb9 ,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags|GuiObj.GroupStart, 74,166,12,56
        DefPushButton TiPbt.Text,TiPbt.TextLen,2
DefItem TiPb10,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 94,188,12,56
        DefPushButton TiPbt.Text,TiPbt.TextLen,2
DefItem TiPb11,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 114,158,12,56
        DefPushButton TiPbt.Text,TiPbt.TextLen,2
DefItem TiPb12,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags|GuiObj.GroupStart, 144,28,12,80
        DefPushButton TiPbt.Text,TiPbt.TextLen,2
DefItem TiPb13,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 144,112,12,80
        DefPushButton TiPbl.Text,TiPbl.TextLen,4
DefItem TiPb14,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 160,28,12,80
        DefPushButton TiPbl.Text,TiPbl.TextLen,4
DefItem TiPb15,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 160,112,12,80
        DefPushButton TiPbl.Text,TiPbl.TextLen,4

        %define GuiObjContainer TiWnd1
DefItem TiTb2,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 2,2,9,36
        dd TiTb.Text
        dd TiTb.TextLen
        db TitleBarObj.HelpButton|TitleBarObj.CloseButton
DefItem TiPb20,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 15,5,10,30
        DefPushButton TiPbt.Text,TiPb.TextLen,2
DefItem TiPb21,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 25,5,20,30
        DefPushButton TiPb.Text,TiPb.TextLen,0
;DefItem TiPb21,DbgObjCode,NullGuiItem,ButtonObj.DefGuiFlags, 25,-5,20,30

        %define GuiObjContainer TiWnd2
DefItem TiTb3,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 57,2,9,36
        dd TiTb.Text
        dd TiTb.TextLen
        db TitleBarObj.CloseButton

TiTb.Text:      db "Title Bar"
                TiTb.TextLen equ $-TiTb.Text
TiPb.Text:      db "Push Button"
                TiPb.TextLen equ $-TiPb.Text
TiPbt.Text:     db "Toggle Button"
                TiPbt.TextLen equ $-TiPbt.Text
TiPbl.Text:     db "Lock Button"
                TiPbl.TextLen equ $-TiPbl.Text
;TiTp.Text:      db "Just a long string of text to see if the text prompt works"
TiTp.Text:      db "left"
                TiTp.TextLen equ $-TiTp.Text
                times TiTp.MaxLen-TiTp.TextLen db 0
TiTp1.Text:     db "center"
                TiTp1.TextLen equ $-TiTp1.Text
                times TiTp.MaxLen-TiTp1.TextLen db 0

TiTp2.Text:     db "right"
                TiTp2.TextLen equ $-TiTp2.Text
                times TiTp.MaxLen-TiTp2.TextLen db 0
TiLbl.Text:     db "Label"
                TiLbl.TextLen equ $-TiLbl.Text
