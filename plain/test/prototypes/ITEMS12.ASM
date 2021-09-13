.Items:
        DefContainedItem mainbg
        DefContainedItem tabstrip0
        DefContainedItem wndUnitAtrs
        DefContainedItem wndFile1
        DefContainedItem atrbar0
        DefContainedItem window36
        DefContainedItem window35
        DefWindowEnd

DefItem mainbg,MainBgCode,0,MainBg.DefGuiFlags, 0,0,Screen.Height,Screen.Width

DefItem tabstrip0,TabStripCode,NullGuiItem,TabStripObj.DefGuiFlags, 0,0,200,9
        DefTabStrip
        DefTabStripItem tab1.Name,4,0,24
        DefTabStripItem tab2.Name,4,0,20
        DefTabStripItem tab3.Name,5,0,24
        DefTabStripItem tab4.Name,4,0,20
        DefTabStripItem tab5.Name,4,0,24
        DefTabStripItem tab6.Name,3,0,16
        DefTabStripItem tab7.Name,3,0,20
        DefTabStripItem tab8.Name,4,0,20
        DefTabStripItem tab9.Name,5,0,20
        DefTabStripItem tab10.Name,1,0,12
        DefTabStripEnd

DefItem wndUnitAtrs,WindowCode,NullGuiItem,WindowObj.DefGuiFlags|GuiObj.GroupStart|GuiObj.FixedPosition|GuiObj.FixedLayer, 2,11,187,70
        DefWindow atrlist13,0,0
        DefContainedItem titlebar11
        DefContainedItem border12
        DefContainedItem atrlist13
        DefContainedItem border18
        DefContainedItem label19
        DefContainedItem label20
        DefContainedItem label21
        DefContainedItem border22
        DefContainedItem textprompt23
        DefContainedItem list28
        DefContainedItem border24
        DefContainedItem label25
        DefContainedItem scroll26
        DefContainedItem button27
        DefContainedItem button28
        DefContainedItem button29
        DefWindowEnd

DefItem wndFile1,WindowCode,NullGuiItem,WindowObj.DefGuiFlags|GuiObj.GroupStart|GuiObj.FixedPosition|GuiObj.FixedLayer, 2,83,187,235
        DefWindow scroll32,0,0
        DefContainedItem titlebar30
        DefContainedItem border31
        DefContainedItem scroll32
        DefContainedItem scroll33
        DefContainedItem border34
        DefWindowEnd

DefItem atrbar0,AtrBarCode,NullGuiItem,TabStripObj.DefGuiFlags, 192,10,8,310
        DefTabStrip
        DefTabStripItem tab20.Name,10,0,48
        DefTabStripItem tab21.Name,12,0,48
        DefTabStripItem tab22.Name,4,0,24
        DefTabStripItem tab23.Name,3,0,24
        DefTabStripItem tab24.Name,5,0,24
        DefTabStripItem tab25.Name,3,0,20
        DefTabStripItem tab26.Name,3,0,20
        DefTabStripItem tab27.Name,5,0,32
        DefTabStripItem tab28.Name,12,0,60
        DefTabStripEnd

DefItem window35,WindowCode,NullGuiItem,WindowObj.DefGuiFlags, 72,31+100,55,96
        DefWindow NullGuiItem,0,0
        DefContainedItem windowbg36
        DefContainedItem titlebar37
        DefContainedItem atrlist38
        DefContainedItem button42
        DefContainedItem button43
        DefWindowEnd

DefItem window36,WindowCode,NullGuiItem,WindowObj.DefGuiFlags, 100,110,60,120
        DefWindow NullGuiItem,0,0
        DefContainedItem windowbg44
        DefContainedItem titlebar45
        DefWindowEnd


        %define GuiObjContainer wndUnitAtrs
DefItem titlebar11,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 0,0,9,70
        DefTitleBar .Text,15,TitleBarObj.CloseButton
DefItem border12,BorderCode,0,BorderObj.DefGuiFlags, 10,0,35,70
DefItem atrlist13,AtrListCode,NullGuiItem,AtrListObj.DefGuiFlags|GuiObj.GroupStart, 12,1,32,68
        DefAtrList NullGuiItem
        DefAtrListItem atritem14.Name,8,atritem14.Atr,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atritem15.Name,7,atritem15.Atr,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atritem16.Name,8,atritem16.Atr,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atritem17.Name,5,atritem17.Atr,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListEnd
DefItem border18,BorderCode,0,BorderObj.DefGuiFlags, 46,0,26,70
DefItem label19,LabelCode,0,LabelObj.DefGuiFlags, 48,3,8,64
        DefLabel .Text,16,LabelObj.AlignLeft
DefItem label20,LabelCode,0,LabelObj.DefGuiFlags, 56,3,8,68
        DefLabel .Text,16,LabelObj.AlignLeft
DefItem label21,LabelCode,0,LabelObj.DefGuiFlags, 64,3,8,64
        DefLabel .Text,16,LabelObj.AlignLeft
DefItem border22,BorderCode,0,BorderObj.DefGuiFlags, 74,0,12,70
        textprompt23.MaxLen equ 7+50
DefItem textprompt23,TextPromptCode,NullGuiItem,TextPromptObj.DefGuiFlags|GuiObj.GroupStart, 75,1,10,68
        DefTextPrompt .Text,9,textprompt23.MaxLen,0
DefItem border24,BorderCode,0,BorderObj.DefGuiFlags, 87,0,86,63
DefItem list28,ListCode,0,ListObj.DefGuiFlags|GuiObj.NoKeyFocus, 89,2,84,61
        ;DefList ...
DefItem label25,LabelCode,0,LabelObj.DefGuiFlags, 89,2,84,61
        DefLabel .Text,6,LabelObj.AlignLeft
DefItem scroll26,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefGuiFlags, 87,64,86,6
        DefScrollHandle 100,0,0,1,10
DefItem button27,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags|GuiObj.GroupStart, 175,0,12,22
        DefPushButton .Text,3,0
DefItem button28,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 175,24,12,22
        DefPushButton .Text,3,0
DefItem button29,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 175,48,12,22
        DefPushButton .Text,3,0


        %define GuiObjContainer wndFile1
DefItem titlebar30,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 0,0,9,235
        DefTitleBar .Text,11,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem border31,BorderCode,0,BorderObj.DefGuiFlags, 10,0,170,226
DefItem scroll32,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefGuiFlags^GuiObj.NoKeyFocus, 10,310-83,170,6
        DefScrollHandle 100,0,0,1,10
DefItem scroll33,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefGuiFlags, 181,0,6,226
        DefScrollHandle 100,0,0,1,10
DefItem border34,BorderCode,0,BorderObj.DefGuiFlags, 181,310-83,6,6


        %define GuiObjContainer window35
DefItem windowbg36,WindowBgCode,0,WindowBgObj.DefGuiFlags, 0,0,2048,2048
DefItem titlebar37,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 2,2,9,92
        DefTitleBar .Text,15,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem atrlist38,AtrListCode,NullGuiItem,AtrListObj.DefGuiFlags|GuiObj.GroupStart, 14,4,24,88
        DefAtrList NullGuiItem
        DefAtrListItem atrlistitem39.Name,10,atrlistitem39.Atr,10, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem40.Name,7,atrlistitem40.Atr,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem41.Name,6,atrlistitem41.Atr,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListEnd
DefItem button42,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags|GuiObj.GroupStart, 40,3,12,44
        DefPushButton .Text,6,0
DefItem button43,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags, 40,49,12,44
        DefPushButton .Text,6,0


        %define GuiObjContainer window36
DefItem windowbg44,WindowBgCode,0,WindowBgObj.DefGuiFlags, 0,0,2048,2048
DefItem titlebar45,TitleBarCode,NullGuiItem,TitleBarObj.DefGuiFlags, 2,2,9,116
        DefTitleBar .Text,12,TitleBarObj.HelpButton|TitleBarObj.CloseButton


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

        tab20.Name: db "@24048576r"
        tab21.Name: db "Color Blocks"
        tab22.Name: db "=45h"
        tab23.Name: db "#4+"
        tab24.Name: db "&FFFF"
        tab25.Name: db ">>0"
        tab26.Name: db "x32"
        tab27.Name: db "Brush"
        tab28.Name: db "allstars.smc"

        titlebar11.Text: db "Unit Attributes"
        atritem14.Name: db "Bitsize:"
        atritem14.Atr:  db "#16+"
        atritem15.Name: db "Rshift:"
        atritem15.Atr:  db ">>10"
        atritem16.Name: db "Bitmask:"
        atritem16.Atr:  db "&7"
        atritem17.Name: db "Wrap:"
        atritem17.Atr:  db "64"
        label19.Text: db "FEDCBA9876543210"
        label20.Text: db "----------FEDCBA"
        label21.Text: db "-------------CBA"
        textprompt23.Text: db "Hello :-)"
        times 50 db 0
        label25.Text: db "Custom"
        button27.Text: db "Set"
        button28.Text: db "Add"
        button29.Text: db "Del"

        titlebar30.Text: db "File Window"

        titlebar37.Text: db "Insertion Order"
        atrlistitem39.Name: db "Direction:"
        atrlistitem39.Atr:  db "right/down"
        atrlistitem40.Name: db "Height:"
        atrlistitem40.Atr:  db "32"
        atrlistitem41.Name: db "Width:"
        atrlistitem41.Atr:  db "32"
        button42.Text: db "Accept"
        button43.Text: db "Cancel"

        titlebar45.Text: db "Dummy window"
