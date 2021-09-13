;TMV Unit
.Items:
        DefContainedItem mainbg
        DefContainedItem tabstrip0
        DefContainedItem titlebar11
        DefContainedItem border12
        DefContainedItem atrlist13
        DefContainedItem border18
        DefContainedItem label19
        DefContainedItem label20
        DefContainedItem label21
        DefContainedItem border22
        DefContainedItem textprompt23
        DefContainedItem border24
        DefContainedItem list25
        DefContainedItem label26
        DefContainedItem scroll27
        DefContainedItem button28
        DefContainedItem button29
        DefContainedItem button30
        DefContainedItem titlebar31
        DefContainedItem border32
        DefContainedItem scroll33
        DefContainedItem scroll34
        DefContainedItem border35
        DefContainedItem atrbar36
        DefWindowEnd
DefItem mainbg,MainBgCode,0,GuiObj.NoKeyFocus|GuiObj.FixedLayer|GuiObj.FixedPosition, 0,0,Screen.Height,Screen.Width

DefItem tabstrip0,TabStripCode,NullGuiItem,TabStripObj.DefGuiFlags, 0,0,400,18
        DefTabStrip
        DefTabStripItem tab1.Name,4,0,48
        DefTabStripItem tab2.Name,4,0,40
        DefTabStripItem tab3.Name,5,0,48
        DefTabStripItem tab4.Name,4,0,40
        DefTabStripItem tab5.Name,4,0,48
        DefTabStripItem tab6.Name,3,0,32
        DefTabStripItem tab7.Name,3,0,40
        DefTabStripItem tab8.Name,4,0,40
        DefTabStripItem tab9.Name,5,0,40
        DefTabStripItem tab10.Name,1,0,24
        DefTabStripEnd
DefItem titlebar11,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 4,22,18,140
        DefTitleBar titlebar11.Text,15,TitleBarObj.HelpButton|TitleBarObj.CloseButton
DefItem border12,BorderCode,0,BorderObj.DefGuiFlags, 24,22,70,140
DefItem atrlist13,AtrListCode,NullGuiItem,AtrListObj.DefGuiFlags|GuiObj.GroupStart, 28,24,64,136
        DefAtrList NullGuiItem
        DefAtrListItem atrlistitem14.Name,8,atrlistitem14.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem15.Name,7,atrlistitem15.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem16.Name,8,atrlistitem16.Text,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem17.Name,5,atrlistitem17.Text,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListEnd
DefItem border18,BorderCode,0,BorderObj.DefGuiFlags, 96,22,52,140
DefItem label19,LabelCode,0,LabelObj.DefGuiFlags, 100,28,16,128
        DefLabel label19.Text,16,LabelObj.AlignLeft
DefItem label20,LabelCode,0,LabelObj.DefGuiFlags, 116,28,16,136
        DefLabel label20.Text,16,LabelObj.AlignLeft
DefItem label21,LabelCode,0,LabelObj.DefGuiFlags, 132,28,16,128
        DefLabel label21.Text,16,LabelObj.AlignLeft
DefItem border22,BorderCode,0,BorderObj.DefGuiFlags, 152,22,24,140
        textprompt23.MaxLen equ 7+50
DefItem textprompt23,TextPromptCode,NullGuiItem,TextPromptObj.DefGuiFlags|GuiObj.GroupStart, 154,24,20,136
        DefTextPrompt textprompt23.Text,7,textprompt23.MaxLen,0
DefItem border24,BorderCode,0,BorderObj.DefGuiFlags, 178,22,172,126
DefItem list25,ListCode,NullGuiItem,ListObj.DefGuiFlags, 180,24,168,122
        ;DefList ...
DefItem label26,LabelCode,0,LabelObj.DefGuiFlags, 198,26,150,120
        DefLabel label26.Text,80,LabelObj.AlignLeft
DefItem scroll27,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefGuiFlags, 178,150,172,12
        DefScrollHandle 100,0,0,1,10
DefItem button28,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags|GuiObj.GroupStart, 354,22,24,44
        DefPushButton button28.Text,3,0
DefItem button29,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 354,70,24,44
        DefPushButton button29.Text,3,0
DefItem button30,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 354,118,24,44
        DefPushButton button30.Text,3,0
DefItem titlebar31,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags|GuiObj.GroupStart, 4,166,18,470
        DefTitleBar titlebar31.Text,11,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem border32,BorderCode,0,BorderObj.DefGuiFlags ^ GuiObj.NoKeyFocus, 24,166,340,452
DefItem scroll33,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefGuiFlags, 24,620,340,12
        DefScrollHandle 100,0,0,1,10
DefItem scroll34,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefGuiFlags, 366,166,12,452
        DefScrollHandle 100,0,0,1,10
DefItem border35,BorderCode,0,BorderObj.DefGuiFlags, 366,620,12,12
DefItem atrbar36,AtrBarCode,NullGuiItem,TabStripObj.DefGuiFlags, 384,20,16,620
        DefTabStrip
        DefTabStripItem atrbaritem37.Name,10,0,96
        DefTabStripItem atrbaritem38.Name,12,0,88
        DefTabStripItem atrbaritem39.Name,4,0,56
        DefTabStripItem atrbaritem40.Name,3,0,48
        DefTabStripItem atrbaritem41.Name,5,0,48
        DefTabStripItem atrbaritem42.Name,3,0,40
        DefTabStripItem atrbaritem43.Name,3,0,40
        DefTabStripItem atrbaritem44.Name,5,0,72
        DefTabStripItem atrbaritem45.Name,12,0,120
        DefTabStripEnd

section text
        tab1.Name: db "Menu"
        tab2.Name: db "Goto"
        tab3.Name: db "Color"
        tab4.Name: db "Unit"
        tab5.Name: db "Mode"
        tab6.Name: db "Pal"
        tab7.Name: db "Map"
        tab8.Name: db "File"
        tab9.Name: db "Tiles"
        tab10.Name: db "?"
        titlebar11.Text: db "Unit Attributes"
        atrlistitem14.Name: db "Bitsize:"
        atrlistitem14.Text:  db "#16+"
        atrlistitem15.Name: db "Rshift:"
        atrlistitem15.Text:  db ">>10"
        atrlistitem16.Name: db "Bitmask:"
        atrlistitem16.Text:  db "&7"
        atrlistitem17.Name: db "Wrap:"
        atrlistitem17.Text:  db "64"
        label19.Text: db "FEDCBA9876543210"
        label20.Text: db "----------FEDCBA"
        label21.Text: db "-------------CBA"
        textprompt23.Text: db "Testing"
        times 50 db 0
        label26.Text: db "SNES Bpl VramSNES Mode 7Low nybbleHigh nybbleSMW LevelSM3 LevelZelda Level"
        button28.Text: db "Set"
        button29.Text: db "Add"
        button30.Text: db "Del"
        titlebar31.Text: db "File Window"
        atrbaritem37.Name: db "@24048576r"
        atrbaritem38.Name: db "Color Blocks"
        atrbaritem39.Name: db "=45h"
        atrbaritem40.Name: db "#4+"
        atrbaritem41.Name: db "&FFFF"
        atrbaritem42.Name: db ">>0"
        atrbaritem43.Name: db "x32"
        atrbaritem44.Name: db "Brush"
        atrbaritem45.Name: db "allstars.smc"
section data
