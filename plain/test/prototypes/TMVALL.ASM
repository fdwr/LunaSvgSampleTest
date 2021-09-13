%define Program.TitleDef "Peekin's Tileview GUI Test"
%define Program.ClassDef "TmvGuiTest"

        DefWindow windowTiles,0,0
        ;DefWindow SlidePanel,0,0
        DefContainedItem mainbg
        DefContainedItem atrbar11
        DefContainedItem windowTiles
        DefContainedItem SlidePanel
        DefContainedItem tabstrip0
        DefContainedItem FloatMenu
        DefWindowEnd

;TextPromptCode equ NullGuiItem
;%macro DefTextPrompt 1-*
;%endmacro
;TextPromptObj.DefFlags equ GuiObj.Null

%if 0
mainbg.Gic equ MainWindow
atrbar11.Gic equ MainWindow
windowTiles.Gic equ MainWindow
SlidePanel.Gic equ MainWindow
tabstrip0.Gic equ MainWindow
mainbg.Idx equ 0
atrbar11.Idx equ 0
windowTiles.Idx equ 0
SlidePanel.Idx equ 0
tabstrip0.Idx equ 0
%endif

DefItem mainbg,MainBgCode,0,MainBgObj.DefFlags, 0,0,Screen.Height,Screen.Width
        DefTitleBar Program.Title,Program.Title_size,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MinButton

DefItem tabstrip0,TabStripCode,TabOwner,TabStripObj.DefFlags, 24,0,400,18
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
        DefTabStripItem tab10.Name,1,0,16
        DefTabStripEnd
DefItem atrbar11,AtrBarCode,AtrBarDoesNothing,TabStripObj.DefFlags, 436,20,14,620
        DefTabStrip
        DefTabStripItem atrbaritem12.Name,10,0,96
        DefTabStripItem atrbaritem13.Name,12,0,88
        DefTabStripItem atrbaritem14.Name,4,0,56
        DefTabStripItem atrbaritem15.Name,3,0,48
        DefTabStripItem atrbaritem16.Name,5,0,48
        DefTabStripItem atrbaritem17.Name,3,0,40
        DefTabStripItem atrbaritem18.Name,3,0,40
        DefTabStripItem atrbaritem19.Name,5,0,72
        DefTabStripItem atrbaritem20.Name,12,0,120
        DefTabStripEnd

DefItem SlidePanel,SlidePanelCode,NullGuiItem,FrameObj.DefFlags|GuiObj.Hidden|GuiObj.Disabled, 20,0,416,172+22+4
        ;DefContainedItem windowMode GuiObj.Hidden|
        ;DefContainedItem windowGoto
        ;DefContainedItem windowColor
        ;DefContainedItem lblUnfinished

windowUnit.Idx equ 0
windowUnit.Gic equ SlidePanel
windowMode.Idx equ 0
windowMode.Gic equ SlidePanel
windowGoto.Idx equ 0
windowGoto.Gic equ SlidePanel
windowColor.Idx equ 0
windowColor.Gic equ SlidePanel
lblUnfinished.Idx equ 0
lblUnfinished.Gic equ SlidePanel
windowMainMenu.Idx equ 0
windowMainMenu.Gic equ SlidePanel


DefItem windowTiles,FrameCode,NullGuiItem,FrameObj.DefFlags, 24,22,410,614
        DefWindow scroll86,0,0
        DefContainedItem titlebar84
        DefContainedItem border85
        DefContainedItem scroll86
        DefContainedItem scroll87
        DefContainedItem border88
        DefWindowEnd

; SlidePanel
DefItem lblUnfinished,LabelCode,0,LabelObj.DefFlags, 4,22,16,148
        DefLabel lblUnfinished.Text,24,LabelObj.AlignLeft

DefItem windowUnit,FrameCode,NullGuiItem,FrameObj.DefFlags, 4,22,416,148
        DefWindow textprompt35,0,0
        ;DefContainedItem windowbg21
        DefContainedItem titlebar23
        DefContainedItem border24
        DefContainedItem atrlist25
        DefContainedItem border30
        DefContainedItem label31
        DefContainedItem label32
        DefContainedItem label33
        DefContainedItem border34
        DefContainedItem textprompt35
        DefContainedItem border36
        DefContainedItem list37
        DefContainedItem label38
        DefContainedItem scroll39
        DefContainedItem button40
        DefContainedItem button41
        DefContainedItem button42
        DefWindowEnd

DefItem windowMode,FrameCode,NullGuiItem,FrameObj.DefFlags|GuiObj.ItemFocus, 4,22,416,148
        DefWindow atrlist49,0,0
        DefContainedItem titlebar43
        DefContainedItem border44
        DefContainedItem list45
        DefContainedItem label46
        DefContainedItem scroll47
        DefContainedItem border48
        DefContainedItem atrlist49
        DefWindowEnd

DefItem windowGoto,FrameCode,NullGuiItem,FrameObj.DefFlags|GuiObj.ItemFocus, 4,22,416,172
        DefWindow textprompt57,0,0
        DefContainedItem titlebar55
        DefContainedItem border56
        DefContainedItem textprompt57
        DefContainedItem picture58
        DefContainedItem button59
        DefContainedItem button60
        DefContainedItem button61
        DefContainedItem border62
        DefContainedItem textprompt63
        DefContainedItem border64
        DefContainedItem border65
        DefContainedItem label66
        DefContainedItem list67
        DefContainedItem scroll68
        DefContainedItem button69
        DefContainedItem button70
        DefContainedItem button71
        DefContainedItem button72
        DefContainedItem button73
        DefContainedItem button74
        DefWindowEnd

DefItem windowColor,FrameCode,NullGuiItem,FrameObj.DefFlags|GuiObj.ItemFocus, 4,22,416,148
        DefWindow textprompt77,0,0
        DefContainedItem titlebar75
        DefContainedItem border76
        DefContainedItem textprompt77
        DefContainedItem border78
        DefContainedItem list79
        DefContainedItem scroll80
        DefContainedItem border81
        DefContainedItem list82
        DefContainedItem scroll83
        DefWindowEnd

DefItem windowMainMenu,FrameCode,NullGuiItem,FrameObj.DefFlags|GuiObj.ItemFocus, 4,22,416,148
        DefWindow embedmenu86,0,0
        DefContainedItem titlebar85
        DefContainedItem embedmenu86
        DefWindowEnd


; windowUnit
DefItem titlebar23,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags, 0,0,18,148
        DefTitleBar titlebar23.Text,15,TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem border24,BorderCode,0,BorderObj.DefFlags, 20,0,70,148
DefItem atrlist25,AtrListCode,NullGuiItem,AtrListObj.DefFlags|GuiObj.GroupStart, 24,2,64,144
        DefAtrList NullGuiItem
        DefAtrListItem .0, atrlistitem26.Name,8,atrlistitem26.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .1, atrlistitem27.Name,7,atrlistitem27.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .2, atrlistitem28.Name,8,atrlistitem28.Text,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .3, atrlistitem29.Name,5,atrlistitem29.Text,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListEnd
DefItem border30,BorderCode,0,BorderObj.DefFlags, 92,0,52,148
DefItem label31,LabelCode,0,LabelObj.DefFlags, 96,18,16,112
        DefLabel label31.Text,16,LabelObj.AlignLeft
DefItem label32,LabelCode,0,LabelObj.DefFlags, 112,18,16,112
        DefLabel label32.Text,16,LabelObj.AlignLeft
DefItem label33,LabelCode,0,LabelObj.DefFlags, 128,18,16,112
        DefLabel label33.Text,16,LabelObj.AlignLeft
DefItem border34,BorderCode,0,BorderObj.DefFlags, 148,0,24,148
        textprompt35.MaxLen equ 7+50
DefItem textprompt35,TextPromptCode,NullGuiItem,TextPromptObj.DefFlags|GuiObj.GroupStart, 150,2,20,144
        DefTextPrompt textprompt35.Text,7,textprompt35.MaxLen,0
DefItem border36,BorderCode,0,BorderObj.DefFlags, 174,0,206,132
DefItem list37,ListCode,NullGuiItem,ListObj.DefFlags, 176,2,202,128
        ;DefList ...
DefItem label38,LabelCode,0,LabelObj.DefFlags, 194,4,150,124
        DefLabel label38.Text,80,LabelObj.AlignLeft
DefItem scroll39,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefFlags, 174,134,205,14
        DefScrollHandle 100,0,0,1,10
DefItem button40,ButtonCode,NullGuiItem,ButtonObj.DefFlags|GuiObj.GroupStart, 384,0,24,46
        DefPushButton button40.Text,3,0
DefItem button41,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 384,50,24,46
        DefPushButton button41.Text,3,0
DefItem button42,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 384,100,24,46
        DefPushButton button42.Text,3,0


; windowMode
DefItem titlebar43,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags, 0,0,18,148
        DefTitleBar titlebar43.Text,12,TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem border44,BorderCode,0,BorderObj.DefFlags, 20,0,140,132
DefItem list45,ListCode,NullGuiItem,ListObj.DefFlags|GuiObj.GroupStart, 22,2,136,128
        ;DefList ...
DefItem label46,LabelCode,0,LabelObj.DefFlags, 40,4,118,126
        DefLabel label46.Text,57,LabelObj.AlignLeft
DefItem scroll47,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefFlags, 20,134,140,14
        DefScrollHandle 100,0,0,1,10
DefItem border48,BorderCode,0,BorderObj.DefFlags, 164,0,243,148
DefItem atrlist49,AtrListCode,NullGuiItem,AtrListObj.DefFlags|GuiObj.GroupStart, 168,2,236,144
        DefAtrList NullGuiItem
        DefAtrListItem .0, atrlistitem50.Name,6,atrlistitem50.Text,3, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .1, atrlistitem51.Name,10,atrlistitem51.Text,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .2, atrlistitem52.Name,9,atrlistitem52.Text,3, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .3, atrlistitem53.Name,10,atrlistitem53.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListEnd


; windowGoto
DefItem titlebar55,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags, 0,0,18,172
        DefTitleBar titlebar55.Text,9,TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem border56,BorderCode,0,BorderObj.DefFlags, 20,0,24,172
        textprompt57.MaxLen equ 19+50
DefItem textprompt57,TextPromptCode,NullGuiItem,TextPromptObj.DefFlags|GuiObj.GroupStart, 22,2,20,152
        DefTextPrompt textprompt57.Text,19,textprompt57.MaxLen,0
DefItem picture58,ImageCode,0,ImageObj.DefFlags, 24,154,8,7
        DefImage picture58.Image,0
DefItem button59,ButtonCode,NullGuiItem,ButtonObj.DefFlags|GuiObj.GroupStart, 46,0,24,56
        DefPushButton button59.Text,4,0
DefItem button60,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 46,58,24,56
        DefPushButton button60.Text,4,0
DefItem button61,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 46,116,24,56
        DefPushButton button61.Text,4,0
DefItem border62,BorderCode,0,BorderObj.DefFlags, 74,0,24,172
        textprompt63.MaxLen equ 6+50
DefItem textprompt63,TextPromptCode,NullGuiItem,TextPromptObj.DefFlags|GuiObj.GroupStart, 76,2,20,168
        DefTextPrompt textprompt63.Text,6,textprompt63.MaxLen,0
DefItem border64,BorderCode,0,BorderObj.DefFlags, 100,0,254,158
DefItem border65,BorderCode,0,BorderObj.DefFlags, 102,2,20,154
DefItem label66,LabelCode,0,LabelObj.DefFlags, 106,6,16,146
        DefLabel label66.Text,8,LabelObj.AlignLeft
DefItem list67,ListCode,NullGuiItem,ListObj.DefFlags, 122,2,192,154
        ;DefList ...
DefItem scroll68,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefFlags, 100,160,254,12
        DefScrollHandle 100,0,0,1,10
DefItem button69,ButtonCode,NullGuiItem,ButtonObj.DefFlags|GuiObj.GroupStart, 358,0,24,56
        DefPushButton button69.Text,4,0
DefItem button70,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 358,58,24,56
        DefPushButton button70.Text,4,0
DefItem button71,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 358,116,24,56
        DefPushButton button71.Text,4,0
DefItem button72,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 384,0,24,56
        DefPushButton button72.Text,6,0
DefItem button73,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 384,58,24,56
        DefPushButton button73.Text,6,0
DefItem button74,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 384,116,24,56
        DefPushButton button74.Text,4,0


; windowColor
DefItem titlebar75,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags, 0,0,18,148
        DefTitleBar titlebar75.Text,5,TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem border76,BorderCode,0,BorderObj.DefFlags, 20,0,24,148
        textprompt77.MaxLen equ 3+50
DefItem textprompt77,TextPromptCode,NullGuiItem,TextPromptObj.DefFlags|GuiObj.GroupStart, 22,2,20,144
        DefTextPrompt textprompt77.Text,3,textprompt77.MaxLen,0
DefItem border78,BorderCode,0,BorderObj.DefFlags, 46,0,284,132
DefItem list79,ListCode,NullGuiItem,ListObj.DefFlags|GuiObj.GroupStart, 48,2,280,128
        ;DefList ...
DefItem scroll80,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefFlags, 46,134,284,14
        DefScrollHandle 100,0,0,1,10
DefItem border81,BorderCode,0,BorderObj.DefFlags, 334,0,74,132
DefItem list82,ListCode,NullGuiItem,ListObj.DefFlags|GuiObj.GroupStart, 336,2,64,128
        ;DefList ...
DefItem scroll83,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefFlags, 334,134,74,14
        DefScrollHandle 100,0,0,1,10


; windowTiles
DefItem titlebar84,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags, 0,0,18,614
        DefTitleBar titlebar84.Text,12,TitleBarObj.CloseButton|TitleBarObj.MinButton
DefItem border85,BorderCode,0,BorderObj.DefFlags, 20,0,372,596
DefItem scroll86,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefFlags, 20,598,372,14
        DefScrollHandle 100,0,0,1,10
DefItem scroll87,ScrollHandleCode,NullGuiItem,ScrollHandleObj.DefFlags, 394,0,14,596
        DefScrollHandle 100,0,0,1,10
DefItem border88,BorderCode,0,BorderObj.DefFlags, 394,598,14,14


; windowMainMenu
DefItem titlebar85,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags, 0,0,18,148
        DefTitleBar titlebar85.Text,9,TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem embedmenu86,EmbedMenuCode,NullGuiItem,EmbedMenuObj.DefFlags, 20,0,388,148
        DefMenuObj mnuMain

        DefMenuList mnuMain,IgnoreMsg
        DefMenuListItem .File,       .0,.FileImg,    MenuListObj.Opens, mnuFile
        DefMenuListItem .Control,    .1,.ControlImg, MenuListObj.Opens, mnuControl
        DefMenuListItem .Seek,       .2,.SeekImg,    MenuListObj.Opens, mnuSeek
        DefMenuListItem .Goto,       .3,.GotoImg,    MenuListObj.Opens, mnuGoto
        DefMenuListItem .View,       .4,.ViewImg,    MenuListObj.Opens, mnuView
        DefMenuListItem .Options,    .5,.OptionsImg, MenuListObj.Opens, mnuOptions
        DefMenuListItem .Quit,       .6,.QuitImg,    0
        DefMenuListEnd

        DefMenuList mnuFile,IgnoreMsg
        DefMenuListItem .Load,       .0,0, 0
        DefMenuListItem .Save,       .1,0, 0
        DefMenuListItem .Record,     .2,0, 0
        DefMenuListItem .Settings,   .3,0, MenuListObj.Opens, mnuFileSets
        DefMenuListItem .ExportWave, .4,0, MenuListObj.Opens, mnuExportWave
        DefMenuListItem .LogAsm,     .5,0, 0
        ;DefMenuListItem .DumpMem,    .6,0, 0
        DefMenuListEnd

        DefMenuList mnuFileSets,IgnoreMsg
        DefMenuListItem .Reload,     .0,0, 0
        DefMenuListItem .Save,       .1,0, 0
        DefMenuListItem .Always,     .2,0, 0
        DefMenuListItem .Prompt,     .3,0, 0
        DefMenuListItem .Never,      .4,0, 0
        DefMenuListEnd

        DefMenuList mnuExportWave,IgnoreMsg
        DefMenuListItem .Single,     .0,0, 0
        DefMenuListItem .Together,   .1,0, 0
        DefMenuListItem .All,        .2,0, 0
        DefMenuListEnd

        DefMenuList mnuControl,IgnoreMsg
        DefMenuListItem .Play,       .0,0, 0
        DefMenuListItem .Pause,      .1,0, 0
        DefMenuListItem .Stop,       .2,0, 0
        DefMenuListItem .Record,     .3,0, 0
        DefMenuListItem .Reverse,    .4,0, MenuListObj.Separator
        DefMenuListItem .Halt,       .5,0, 0
        DefMenuListItem .Restart,    .6,0, 0
        DefMenuListItem .Loop,       .7,0, 0
        DefMenuListEnd

        DefMenuList mnuSeek,IgnoreMsg, mnuSeekEnds,1
        DefMenuListItem .Time,       .0,0, 0
        DefMenuListItem .Ends,       .1,0, MenuListObj.Opens, mnuSeekEnds
        DefMenuListItem .Point,      .2,0, MenuListObj.Opens, mnuSeekPoint
        DefMenuListEnd

        DefMenuList mnuSeekEnds,IgnoreMsg
        DefMenuListItem .Start,      .0,0, 0
        DefMenuListItem .Finish,     .1,0, 0
        DefMenuListItem .Repeat,     .4,0, MenuListObj.Separator
        DefMenuListItem .SetRepeat,  .7,0, 0
        DefMenuListItem .FindRepeats,.8,0, 0
        DefMenuListItem .LoopStart,  .2,0, MenuListObj.Separator
        DefMenuListItem .LoopFinish, .3,0, 0
        DefMenuListItem .SetLStart,  .5,0, 0
        DefMenuListItem .SetLFinish, .6,0, 0
        DefMenuListEnd

        DefMenuList mnuSeekPoint,IgnoreMsg
        DefMenuListItem .PrevNote,   .0,0, 0
        DefMenuListItem .NextNote,   .1,0, 0
        DefMenuListItem .Prev,       .2,0, MenuListObj.Separator
        DefMenuListItem .Next,       .3,0, 0
        DefMenuListItem .Insert,     .4,0, 0
        DefMenuListItem .Delete,     .5,0, 0
        DefMenuListItem .Edit,       .6,0, 0
        DefMenuListEnd

        DefMenuList mnuGoto,IgnoreMsg
        DefMenuListItem .Address,    .0,0, 0
        DefMenuListItem .Page0,      .1,0, 0
        DefMenuListItem .Page1,      .2,0, 0
        DefMenuListItem .BrrTbl,     .3,0, 0
        DefMenuListItem .ROM,        .4,0, 0
        DefMenuListEnd

        DefMenuList mnuView,IgnoreMsg, mnuViewNotes,0
        DefMenuListItem .Notes,      .0,0, MenuListObj.Opens, mnuViewNotes
        DefMenuListItem .Samples,    .1,0, 0
        DefMenuListItem .Instruments,.2,0, 0
        DefMenuListItem .Debugger,   .3,0, MenuListObj.Opens, mnuViewDebugger
        DefMenuListItem .Credits,    .4,0, 0
        DefMenuListEnd

        DefMenuList mnuViewNotes,IgnoreMsg
        DefMenuListItem .VertSheet,  .0,0, 0
        DefMenuListItem .HorzSheet,  .1,0, 0
        DefMenuListItem .VolBars,    .2,0, 0
        DefMenuListItem .NoteSheet,  .3,0, 0
        DefMenuListItem .Keyboard,   .4,0, 0
        DefMenuListItem .Waveform,   .5,0, 0
        DefMenuListItem .FullScreen, .6,0, MenuListObj.Separator
        DefMenuListEnd

        DefMenuList mnuViewDebugger,IgnoreMsg
        DefMenuListItem .Disasm,     .0,0, 0
        DefMenuListItem .Trace,      .1,0, 0
        DefMenuListItem .SpcRam,     .2,0, 0
        DefMenuListItem .DspRegs,    .3,0, 0
        DefMenuListItem .Breakpoints,.4,0, 0
        DefMenuListEnd

        DefMenuList mnuOptions,IgnoreMsg
        DefMenuListItem .Sound,      .0,0, 0
        DefMenuListEnd

DefImageStruct mnuMain.FileImg,14,14
        db 2,2,2,2,2,2,14,15,15,15,15,15,15,2,2,2,2,2,2,15,14,15,15,15,15,15
        db 15,14,2,2,2,2,15,15,14,15,15,15,15,15,15,14,2,2,2,15,15,15,14,15
        db 15,15,15,15,15,14,2,2,15,15,15,15,14,15,15,15,15,15,15,14,2,15,15
        db 15,15,15,14,15,15,15,15,15,15,14,14,14,14,14,14,14,15,15,15,15,15
        db 15,15,14,15,15,15,15,15,15,15,15,15,15,15,15,15,14,15,15,15,15,15
        db 15,15,15,15,15,15,15,15,14,15,15,15,15,15,15,15,15,15,15,15,15,15
        db 14,15,15,15,15,15,15,15,15,15,15,15,15,15,14,15,15,15,15,15,15,15
        db 15,15,15,15,15,15,14,15,15,15,15,15,15,15,15,15,15,15,15,15,14,2
        db 14,14,14,14,14,14,14,14,14,14,14,14,14
DefImageStruct mnuMain.ControlImg,14,14
        db 7,7,7,7,7,7,7,7,7,7,7,7,7,2,7,7,7,6,6,7,7,7,7,7,7,7,7,6,7,7,7,6,2,6,7,7,7,7,7,7,7,6,7,7
        db 7,6,2,2,6,7,7,7,7,7,7,6,7,7,7,6,2,2,2,6,7,7,7,7,7,6,7,7,7,6,2,2,2,2,6,7,7,7,7,6,7,7,7,6,2,2,2,2,2,6
        db 7,7,7,6,7,7,7,6,2,2,2,2,2,7,7,7,7,6,7,7,7,6,2,2,2,2,7,7,7,7,7,6,7,7,7,6,2,2,2,7,7,7,7,7
        db 7,6,7,7,7,6,2,2,7,7,7,7,7,7,7,6,7,7,7,6,2,7,7,7,7,7,7,7,7,6,7,7,7,7,7,7,7,7,7,7,7,7,7,6,2,6,6,6,6,6,6,6,6,6,6,6,6,6
DefImageStruct mnuMain.SeekImg,14,14
        db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,9,8,2,9,2,2,2,2,2,2,2,2,2,9,9,8,2,9,9,2,2,2,2,2,2,2,9
        db 9,9,8,2,9,9,9,2,2,2,2,2,9,9,9,9,8,2,9,9,9,9,2,2,2,9,9,9,9,9,8,2,9,9,9,9,9,2,9,9,9,9,9,9,8,2,9,9
        db 9,9,9,9,8,9,9,9,9,9,8,2,9,9,9,9,9,8,2,8,9,9,9,9,8,2,9,9,9,9,8,8,2,2,8,9,9,9,8,2,9,9,9,8,8
        db 2,2,2,2,8,9,9,8,2,9,9,8,8,2,2,2,2,2,2,8,9,8,2,9,8,8,2,2,2,2,2,2,2,2,8,8,2,8,8,2,2,2,2,2,2,2,2,2,2,8,2,8,2,2,2,2,2
DefImageStruct mnuMain.GotoImg,14,14
        db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,11,11,11,11,11,11,11,11,11,11,11,11,11,2,10,11,11,11,11,11,11,11
        db 11,11,11,11,10,10,2,10,11,11,11,11,11,11,11,11,11,10,10,2,2,2,10,11,11,11,11,11,11,11,10,10
        db 2,2,2,2,2,10,11,11,11,11,11,10,10,2,2,2,2,2,2,2,10,11,11,11,10,10,2,2,2,2,2,2,2,2,2,10,11,10
        db 10,2,2,2,2,2,2,2,2,2,2,2,10,10,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,11,11,11,11,11,11,11,11
        db 11,11,11,11,11,2,11,11,11,11,11,11,11,11,11,11,11,11,11,10,11,11,11,11,11,11,11,11,11,11,11,11,11,10,2,10,10,10,10,10,10,10,10,10,10,10,10,10
DefImageStruct mnuMain.ViewImg,14,14
        db 2,2,2,2,7,7,7,2,2,2,2,2,2,2,2,2,7,7,7,7,7,7,7,2,2,2,2,2,2,7,7,7,6,6,6,7,7,7,2,2,2,2,2,7,7,6,2,2,2,6,7,7,2,2
        db 2,2,7,7,6,2,2,2,2,2,6,7,7,2,2,2,7,7,6,2,2,2,2,2,2,7,7,2,2,2,7,7,6,2,2,2,2,2,2,7,7,2,2,2,6,7,7,6,2,2,2,2,6,7
        db 6,2,2,2,2,7,7,7,2,2,2,6,7,7,7,2,2,2,2,6,7,7,7,7,7,7,7,7,7,7,2,2,2,2,6,6,7,7,7,6,7,7,7,7,7,2,2,2,2,2,6,6,6,2
        db 6,7,7,7,7,6,2,2,2,2,2,2,2,2,2,6,7,7,6,2,2,2,2,2,2,2,2,2,2,2,6,6,2,2
DefImageStruct mnuMain.OptionsImg,14,14
        db 13,13,13,13,13,13,13,13,13,13,13,13,13,2,13,13,12,12,12,12,12,12,12,12,12,12,13,12,13,13,12,2,2,2,2,2,2,2,2
        db 2,13,12,13,13,13,13,13,13,13,13,13,13,13,13,13,12,13,13,13,13,13,13,13,13,13,13,13,13,13,12,13,13,12,12,13
        db 13,12,12,13,13,12,12,13,12,13,13,12,2,13,13,12,2,13,13,12,2,13,12,13,13,13,13,13,13,13,13,13,13,13,13,13,12
        db 13,13,13,13,13,13,13,13,13,13,13,13,13,12,13,13,12,12,13,13,12,12,12,12,12,12,13,12,13,13,12,2,13,13,12,2,2
        db 2,2,2,13,12,13,13,13,13,13,13,13,13,13,13,13,13,13,12,13,13,13,13,13,13,13,13,13,13,13,13,13,12,2,12,12,12,12,12,12,12,12,12,12,12,12,12
DefImageStruct mnuMain.QuitImg,14,14
        db 15,15,15,2,2,2,2,2,2,2,15,15,15,2,15,15,15,15,2,2,2,2,2,15,15,15,15,14,15,15,15,15,15,2,2,2,15,15,15,15,15,14
        db 14,15,15,15,15,15,2,15,15,15,15,15,14,14,2,14,15,15,15,15,15,15,15,15,15,14,14,2,2,2,14,15,15,15,15,15,15,15
        db 14,14,2,2,2,2,2,14,15,15,15,15,15,14,14,2,2,2,2,2,2,15,15,15,15,15,15,15,2,2,2,2,2,2,15,15,15,15,15,15,15,15
        db 15,2,2,2,2,15,15,15,15,15,14,15,15,15,15,15,2,2,15,15,15,15,15,14,14,14,15,15,15,15,15,2,15,15,15,15,14,14,2
        db 2,14,15,15,15,15,14,15,15,15,14,14,2,2,2,2,14,15,15,15,14,2,14,14,14,2,2,2,2,2,2,14,14,14,14


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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
        atrbaritem12.Name: db "@24048576r"
        atrbaritem13.Name: db "Color Blocks"
        atrbaritem14.Name: db "=45h"
        atrbaritem15.Name: db "#4+"
        atrbaritem16.Name: db "&FFFF"
        atrbaritem17.Name: db ">>0"
        atrbaritem18.Name: db "x32"
        atrbaritem19.Name: db "Brush"
        atrbaritem20.Name: db "allstars.smc"
        lblUnfinished.Text: db "This panel is unfinished"
        titlebar23.Text: db "Unit Attributes"
        atrlistitem26.Name: db "Bitsize:"
        atrlistitem26.Text: db "#16+"
        atrlistitem27.Name: db "Rshift:"
        atrlistitem27.Text: db ">>10"
        atrlistitem28.Name: db "Bitmask:"
        atrlistitem28.Text: db "&7"
        atrlistitem29.Name: db "Wrap:"
        atrlistitem29.Text: db "64"
        label31.Text: db "FEDCBA9876543210"
        label32.Text: db "----------FEDCBA"
        label33.Text: db "-------------CBA"
        textprompt35.Text: db "Testing"
        times 50 db 32
        label38.Text: db "SNES Bpl VramSNES Mode 7Low nybbleHigh nybbleSMW LevelSM3 LevelZelda Level"
        button40.Text: db "Set"
        button41.Text: db "Add"
        button42.Text: db "Del"
        titlebar43.Text: db "Display Mode"
        label46.Text: db "2 Hex Numbers3 ASCII Text4 Graphic Tiles5 Wave Samples"
        atrlistitem50.Name: db "Tiled:"
        atrlistitem50.Text: db "yes"
        atrlistitem51.Name: db "Color Tbl:"
        atrlistitem51.Text: db "no"
        atrlistitem52.Name: db "Color Bg:"
        atrlistitem52.Text: db "yes"
        atrlistitem53.Name: db "Tile type:"
        atrlistitem53.Text: db "SNES"
        titlebar55.Text: db "Goto/Find"
        textprompt57.Text: db ">23<=48,a,b,a,b+3ab"
        times 50 db 32
        DefImageStruct picture58.Image,8,7
        db 2,2,2,3,2,2,2,2,2,3,1,1,2,2,2,3,1,1,1,1,2,3,0,0,0,0,0,1,1,3,3,3,3,3,0,2,1,1,1,1,0,2,2,2,1,1,0,2,2,2,2,2,0,2,2,2
        button59.Text: db "Find"
        button60.Text: db "Scan"
        button61.Text: db "Frwd"
        textprompt63.Text: db "102492"
        times 50 db 32
        label66.Text: db "Position"
        button69.Text: db "Goto"
        button70.Text: db "Seek"
        button71.Text: db "Base"
        button72.Text: db "Insert"
        button73.Text: db "Delete"
        button74.Text: db "Edit"
        titlebar75.Text: db "Color"
        textprompt77.Text: db "45h"
        times 50 db 32
        titlebar84.Text: db "Tiles Window"
        titlebar85.Text: db "Main Menu"
        mnuMain.0: db "File",0
        mnuMain.1: db "Control",0
        mnuMain.2: db "Seek",0
        mnuMain.3: db "Goto",0
        mnuMain.4: db "View",0
        mnuMain.5: db "Options",0
        mnuMain.6: db "Quit",0

        mnuFile.0: db "Load...",0
        mnuFile.1: db "Save...",0
        mnuFile.2: db "Record...",0
        mnuFile.3: db "Settings >",0
        mnuFile.4: db "Export wave >",0
        mnuFile.5: db "Log disassembly",0
        ;mnuFile.5: db "Dump memory",0
        
        mnuFileSets.0: db "Reload",0
        mnuFileSets.1: db "Save",0
        mnuFileSets.2: db "Always",0
        mnuFileSets.3: db "Prompt",0
        mnuFileSets.4: db "Never",0

        mnuExportWave.0: db "Single selected",0
        mnuExportWave.1: db "All together",0
        mnuExportWave.2: db "All indidually",0

        mnuControl.0: db "Play",0
        mnuControl.1: db "Pause",0
        mnuControl.2: db "Stop",0
        mnuControl.3: db "Record",0
        mnuControl.4: db "Reverse",0
        mnuControl.5: db "Halt",0
        mnuControl.6: db "Restart",0
        mnuControl.7: db "Loop",0

        mnuSeek.0: db "Time...",0
        mnuSeek.1: db "Ends >",0
        mnuSeek.2: db "Point >",0

        mnuSeekEnds.0: db "Start",0
        mnuSeekEnds.1: db "Finish",0
        mnuSeekEnds.2: db "Loop start",0
        mnuSeekEnds.3: db "Loop finish",0
        mnuSeekEnds.4: db "Repeat",0
        mnuSeekEnds.5: db "Set loop start",0
        mnuSeekEnds.6: db "Set loop finish",0
        mnuSeekEnds.7: db "Set repeat",0
        mnuSeekEnds.8: db "Find repeats...",0

        mnuSeekPoint.0: db "Previous note",0
        mnuSeekPoint.1: db "Next note",0
        mnuSeekPoint.2: db "Previous marker",0
        mnuSeekPoint.3: db "Next marker",0
        mnuSeekPoint.4: db "Insert",0
        mnuSeekPoint.5: db "Delete",0
        mnuSeekPoint.6: db "Edit markers...",0

        mnuGoto.0: db "Address",0
        mnuGoto.1: db "Page 0",0
        mnuGoto.2: db "Page 1",0
        mnuGoto.3: db "BRR table",0
        mnuGoto.4: db "ROM",0

        mnuView.0: db "Notes >",0
        mnuView.1: db "Samples",0
        mnuView.2: db "Instruments",0
        mnuView.3: db "Debugger >",0
        mnuView.4: db "Credits",0

        mnuViewNotes.0: db "Vertical sheet",0
        mnuViewNotes.1: db "Horizontal sheet",0
        mnuViewNotes.2: db "Volume bars",0
        mnuViewNotes.3: db "Octave spiral",0
        mnuViewNotes.4: db "Keyboard",0
        mnuViewNotes.5: db "Output waveform",0
        mnuViewNotes.6: db "Full screen",0

        mnuViewDebugger.0: db "Disassembly",0
        mnuViewDebugger.1: db "Trace History",0
        mnuViewDebugger.2: db "SPC RAM",0
        mnuViewDebugger.3: db "DSP Registers",0
        mnuViewDebugger.4: db "Breakpoints",0

        mnuOptions.0: db "Sound",0



;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

dd TabOwner
TabOwner:
%if 1
    cmp al,TabStripMsg.Hover
    jne near .Ignore
    test dword [SlidePanel.Gic+GuiObj.Flags],GuiObj.NotFullFocus
    jnz near .Ignore

    debugwrite "tab hover msg"

    test ecx,ecx
    js near .Out
    mov esi,windowMainMenu
    test ecx,ecx
    je .WindowFound
    mov esi,windowGoto
    cmp ecx,1
    je .WindowFound
    mov esi,windowColor
    cmp ecx,2
    je .WindowFound
    mov esi,windowUnit
    cmp ecx,3
    je .WindowFound
    mov esi,windowMode
    cmp ecx,4
    je .WindowFound
    mov esi,lblUnfinished
.WindowFound:

    push esi
    call SlidePanelCode.Show
    pop esi

    clc
    ret

.Ignore:
    stc
    ret

.Out:
    ;cmp dword [windowSlide.Gic+WindowObj.MouseItem],windowSlide
    ;jne near WindowSlideCode.MouseOut
    clc
    ret
%endif

dd AtrBarDoesNothing
AtrBarDoesNothing:
    cmp al,TabStripMsg.Activate
    stc
    jne .Ignore
    %ifdef WinVer
  api MessageBox, [hwnd],"Attribute bar does nothing yet",Program.Title,MB_OK|MB_ICONINFORMATION|MB_SETFOREGROUND
    %endif
    clc
.Ignore:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SlidePanelCode:

section data
    StartMsgJtbl
    AddMsgJtbl Msg.Created,.ChainDown
    AddMsgJtbl Msg.Destroyed,.ChainDown
    AddMsgJtbl Msg.Redraw,.Redraw
    AddMsgJtbl Msg.Focus,.Focus

    AddMsgJtbl Msg.KeyPress,.KeyPress
    AddMsgJtbl Msg.KeyRelease,.ChainDown
    AddMsgJtbl Msg.KeyChar,.ChainDown
    AddMsgJtbl Msg.KeyIn,.KeyIn
    AddMsgJtbl Msg.KeyOut,.KeyOut

    AddMsgJtbl Msg.MousePrsRls,.SendMouseMsg
    AddMsgJtbl Msg.MouseMove,.SendMouseMsg
    AddMsgJtbl Msg.MouseIn,.MouseIn
    AddMsgJtbl Msg.MouseOut,.MouseOut

    AddMsgJtbl Msg.RedrawItem,SendContainerRedraw.Partial

    AddMsgJtbl Msg.SetItemFocus,SendContainerMsg
    AddMsgJtbl Msg.SetKeyFocus,SendContainerMsg
    AddMsgJtbl Msg.SetMouseFocus,SendContainerMsg

    AddMsgJtbl Msg.GetItemFocus,.ReturnItem
    AddMsgJtbl Msg.GetKeyFocus,.ReturnItem
    AddMsgJtbl Msg.GetMouseFocus,.SendMouseMsg

section code

    debugwrite "panel msg eax=%X",eax
    mov esi,[SlidePanel+GuiObj.Owner]
    UseMsgJtbl

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Redraw:
%if 1
    call SaveClips              ;save maximum clips

    call CopyClips.RedrawToDisplay
    test dword [SlidePanel+GuiObj.Flags],GuiObj.RedrawBg|GuiObj.RedrawForced
    jz .RedrawInternal
%endif

    push dword DrawBorder.Convex|DrawBorder.Filled
    push dword [SlidePanel+GuiObj.Size]
    push dword 0
    call DrawBorder
    add esp,byte 12
    ;clc ;add clears cf
.RedrawInternal:

%if 1
    mov eax,[SlidePanel+GuiObj.Flags]
    mov ebx,[SlidePanel+GuiObj.Owner]
    and eax,GuiObj.RedrawBg|GuiObj.RedrawForced
    or [ebx+GuiObj.Flags],eax
    mov esi,esp
    call SetGuiItemClips
    ;call SetGuiItemRedraw.FromRedraw
    push ebx
    mov eax,Msg.Redraw
    call [ebx+GuiObj.Code]
    DrawItemOverlay
    pop ebx                     ;get item data ptr
    and dword [ebx+GuiObj.Flags],~GuiObj.Redraw
    call OffsetGuiClips
    mov edi,esp
    call OrClips.FromDisplay

    call RestoreClips
%endif
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=message, ebx=panel ptr, esi=contained panel item ptr)
.KeyPress:
    mov ebx,esi
    push esi
    call [esi+GuiObj.Code]
    pop ebx
    jc .KeyCheck
    ret
.KeyCheck:
    cmp byte [Keyboard.LastVkCode],VK_ESCAPE
    jne .KeyIgnore
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Relative|FocusMsgFlags.SetGroup
    call SendContainerMsg
    ;clc
    ret
.KeyIgnore:
    stc
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=message, ebx=panel ptr, esi=contained panel item ptr)
.MouseIn:
    or dword [esi+GuiObj.Flags],GuiObj.MouseFocus
    jmp short .SendMouseMsg

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=message, ebx=panel ptr, esi=contained panel item ptr)
.MouseOut:
    and dword [esi+GuiObj.Flags],~GuiObj.MouseFocus
    ;jmp short .SendMouseMsg

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=message, ebx=panel ptr, esi=contained panel item ptr)
.SendMouseMsg:
    mov ebx,esi
    movzx edx,word [esi+GuiObj.Top]
    movzx ecx,word [esi+GuiObj.Left]    ;make coordinates relative to item's top/left
    sub [esp+8],edx
    sub [esp+12],ecx
    mov [esp+4],ebx
    jmp [ebx+GuiObj.Code]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=message, ebx=panel ptr, esi=contained panel item ptr)
.KeyIn:
    or dword [esi+GuiObj.Flags],GuiObj.KeyFocus
    jmp short .ChainDown

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=message, ebx=panel ptr, esi=contained panel item ptr)
.KeyOut:
    and dword [esi+GuiObj.Flags],~GuiObj.KeyFocus
    ;jmp short .ChainDown

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=message, ebx=panel ptr, esi=contained panel item ptr)
.ChainDown:
    mov ebx,esi
    push esi
    call [esi+GuiObj.Code]
    pop ebx
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=message, ebx=panel ptr, esi=contained panel item ptr)
; (cf=0, esi=contained item)
.ReturnItem:
    mov esi,[SlidePanel+GuiObj.Owner]
    mov ebx,esi
    push ebx
    call [ebx+GuiObj.Code]
    pop ebx
    clc
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (dword ptr to new item owner) (; ebx)
.Show:
    debugwrite "PanelCode.Show: enter"

    push ebx
    mov esi,[esp+8]
    mov ebx,SlidePanel
    cmp esi,[SlidePanel+GuiObj.Owner]
    je .SameOwner

    debugwrite "PanelCode.Show: dif owner"
    ; resize panel
    mov cx,[esi+GuiObj.Width]
    add cx,22+4
    push cx
    push word -32768
    push dword 80008000h
    mov eax,Msg.MoveSize
    call SendContainerMsg
    add esp,byte 8

    and dword [SlidePanel+GuiObj.Flags],~(GuiObj.Hidden|GuiObj.NoMouseFocus|GuiObj.Disabled|GuiObj.NoKeyFocus)
    call SendContainerRedraw.Bg

    mov ebx,[esp+8]
    xchg ebx,[SlidePanel+GuiObj.Owner]
    call .Deactivate
    mov ebx,SlidePanel

.SameOwner:
    debugwrite "PanelCode.Show: setting focus"
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetGroup|FocusMsgFlags.SetItem|FocusMsgFlags.SetContainer
    call SendContainerMsg

    mov ebx,[SlidePanel+GuiObj.Owner]
    call .Activate
    pop ebx

    debugwrite "PanelCode.Show: exit"
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; () (!)
.Hide:
    push ebx
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Relative|FocusMsgFlags.SetGroup
    mov ebx,SlidePanel
    call SendContainerMsg
    test dword [SlidePanel+GuiObj.Flags],GuiObj.NotFullFocus
    jz .ForceHide
    pop ebx
    ret
.ForceHide:
    mov ebx,[SlidePanel+GuiObj.Owner]
    call .Deactivate
    call .Close
    pop ebx
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=message, ebx=panel ptr, esi=contained panel item ptr)
.Focus:
    debugwrite "PanelCode.Focus"
    mov edx,[SlidePanel+GuiObj.Flags]
    and dword [esi+GuiObj.Flags],~(GuiObj.ItemFocus|GuiObj.GroupFocus|GuiObj.ContainerFocus)
    and edx,GuiObj.ItemFocus|GuiObj.GroupFocus|GuiObj.ContainerFocus
    or [esi+GuiObj.Flags],edx

    mov ebx,esi
    push esi
    call [esi+GuiObj.Code]
    pop ebx

    test dword [SlidePanel+GuiObj.Flags],GuiObj.NotFullFocus
    jz .CloseRet
    call .Deactivate
    ; fall through

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; () (!)
.Close:

    debugwrite "PanelCode.Close"
    mov dword [SlidePanel+GuiObj.Owner],NullGuiItem
    mov ebx,SlidePanel
    push dword [SlidePanel+GuiObj.Flags]
    mov eax,Msg.SetFlags
    or dword [esp],GuiObj.Hidden|GuiObj.Disabled
    call SendContainerMsg
    pop edx                     ;discard flags

.CloseRet:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (ebx=contained gui item)
.Activate:
    debugwrite "PanelCode.Activate: enter"
    ;test dword [ebx+GuiObj.Flags],GuiObj.NoKeyFocus|GuiObj.NoItemFocus|GuiObj.NoMouseFocus|GuiObj.Disabled
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jz .AiFullFocus
    debugwrite "PanelCode.Activate: sending focus"
    and dword [ebx+GuiObj.Flags],~GuiObj.NotFullFocus
    mov eax,Msg.Focus|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.Specified
    push ebx
    call [ebx+GuiObj.Code]
    pop ebx
.AiFullFocus:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (ebx=contained gui item)
.Deactivate:
    debugwrite "PanelCode.Dectivate: enter"

    mov edx,[ebx+GuiObj.Flags]
    or dword [esi+GuiObj.Flags],GuiObj.GroupFocus|GuiObj.ContainerFocus
    test edx,GuiObj.GroupFocus|GuiObj.ContainerFocus
    jnz .DiNoFocus
    debugwrite "PanelCode.Dectivate: sending focus"
    mov eax,Msg.Focus|FocusMsgFlags.SetGroup|FocusMsgFlags.SetContainer|FocusMsgFlags.Specified
    push ebx
    call [ebx+GuiObj.Code]
    pop ebx
.DiNoFocus:

    btr dword [SlidePanel+GuiObj.Flags],GuiObj.KeyFocusB
    jnc .DiNoKeyFocus
    mov eax,Msg.KeyOut
    push ebx
    call [ebx+GuiObj.Code]
    pop ebx
.DiNoKeyFocus:
    btr dword [SlidePanel+GuiObj.Flags],GuiObj.MouseFocusB
    jnc .DiNoMouseFocus
    mov eax,Msg.MouseOut
    push dword 16384
    push dword 16384
    push ebx
    call [ebx+GuiObj.Code]
    pop ebx
    add esp,byte 8
.DiNoMouseFocus:
    ret








windowSlide:
WindowSlideCode:
    cmp al,Msg.KeyPress
    je .SendKeyPress
    cmp al,Msg.Focus
    je .Focus
    ;cmp al,Msg.MouseOut
    ;je .MouseOut
    jmp FrameCode

.Focus:
    push ebx
    call SetItemFocus.OfActive
    pop ebx
    test dword [ebx+GuiObj.Flags],GuiObj.NotFullFocus
    jnz .Hide
    mov eax,Msg.SetKeyFocus|KeyMsgFlags.SetContainer
    jmp SendContainerMsg

%if 0
.MouseOut:
    cmp dword [windowSlide.Gic+WindowObj.MouseItem],tabstrip0
    jne .Hide
    ret
%endif

.Hide:
    debugwrite "hiding panel"
    mov dword [windowSlide+WindowObj.ItemsPtr+WindowObj.Items_size],NullGuiItem
    push dword [windowSlide+GuiObj.Flags]
    mov eax,Msg.SetFlags
    or dword [esp],GuiObj.Hidden|GuiObj.Disabled ;|GuiObj.NotFullFocus
    call SendContainerMsg
    pop edx                     ;discard flags
    clc
    ret

.SendKeyPress:
    push eax
    push ebx
    call SendKeyMsg.GivenWinPtr
    pop ebx
    pop eax
    jc .KeyCheck
    ret

.KeyCheck:
    test eax,KeyMsgFlags.Repeat
    jnz .IgnoreRepeat
    cmp ah,VK_ESCAPE
    je near .Refocus
.IgnoreRepeat:
    jmp WindowCode.KeyCheck

.Refocus:
    mov eax,Msg.SetItemFocus|FocusMsgFlags.SetGroup|FocusMsgFlags.SetItem|FocusMsgFlags.Relative
    call SendContainerMsg
    clc
    ret
