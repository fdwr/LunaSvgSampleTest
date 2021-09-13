;spc2midi, menu test
%define ProgramTitleDef "Spc2Midi - GUI test"
%define ProgramClassDef "Spc2Midi"
        DefWindow atrlist9,0,0
        DefContainedItem mainbg
        DefContainedItem titlebar1
        DefContainedItem border2
        DefContainedItem EmbeddedMenu

        DefContainedItem titlebar3
        DefContainedItem border4
        DefContainedItem label5
        DefContainedItem border6
        DefContainedItem titlebar7
        DefContainedItem border8
        DefContainedItem atrlist9
        DefContainedItem scroll22
        DefContainedItem titlebar23
        DefContainedItem border24
        DefContainedItem label25
        DefContainedItem border26
        DefContainedItem titlebar27
        DefContainedItem border28
        DefContainedItem atrlist29
        DefContainedItem scroll43
        DefContainedItem label44

        ;DefContainedItem InnerWnd
        DefContainedItem FloatMenu
        DefWindowEnd


DefItem mainbg,MainBgCode,0,MainBgObj.DefFlags, 0,0,Screen.Height,Screen.Width
        DefTitleBar ProgramTitle,19,TitleBarObj.CloseButton|TitleBarObj.MinButton

DefItem titlebar1,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 24,4,18,106
        DefTitleBar titlebar1.Text,9,TitleBarObj.HelpButton |TitleBarObj.GroupIndicate
DefItem border2,BorderCode,0,BorderObj.DefFlags, 44,4,372,104
DefItem EmbeddedMenu,EmbedMenuCode,MenuOwner,EmbedMenuObj.DefFlags, 44,4,372+24+8,104
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

DefItem titlebar3,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 24,115,18,258
        DefTitleBar titlebar3.Text,12,TitleBarObj.CloseButton|TitleBarObj.MaxButton |TitleBarObj.GroupIndicate
DefItem border4,HoverBorderCode,0,GuiObj.DefFlags, 44,115,130,258
DefItem label5,LabelCode,0,LabelObj.DefFlags, 177,115,16,204
        DefLabel label5.Text,28,LabelObj.AlignLeft
DefItem border6,BorderCode,0,BorderObj.DefFlags, 196+16,115,12,258
DefItem titlebar7,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 24,379,18,258
        DefTitleBar titlebar7.Text,15,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton |TitleBarObj.GroupIndicate
DefItem border8,BorderCode,0,BorderObj.DefFlags^GuiObj.NoKeyFocus, 44,378,164+16,244
DefItem atrlist9,AtrListCode,NullGuiItem,AtrListObj.DefFlags, 46,380,160+16,240
        DefAtrList scroll22
        DefAtrListItem atrlistitem10.Name,7,atrlistitem10.Text,8, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem11.Name,5,atrlistitem11.Text,11, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem12.Name,6,atrlistitem12.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem13.Name,7,atrlistitem13.Text,7, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem14.Name,5,atrlistitem14.Text,5, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem15.Name,5,atrlistitem15.Text,9, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem16.Name,6,atrlistitem16.Text,10, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem17.Name,7,atrlistitem17.Text,10, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem18.Name,5,atrlistitem18.Text,10, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem19.Name,10,atrlistitem19.Text,8, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem20.Name,7,atrlistitem20.Text,9, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem21.Name,9,atrlistitem21.Text,6, 0, 0,-1000,1000, 1,10,100
        DefAtrListEnd
DefItem scroll22,ScrollHandleCode,atrlist9,ScrollHandleObj.DefFlags, 44,625,164+16,12
        DefScrollHandle 100,0,0,1,10
DefItem titlebar23,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 216+16,115,18,258
        DefTitleBar titlebar23.Text,14,TitleBarObj.CloseButton|TitleBarObj.MaxButton |TitleBarObj.GroupIndicate
DefItem border24,HoverBorderCode,0,GuiObj.DefFlags, 236+16,115,130,258
DefItem label25,LabelCode,0,LabelObj.DefFlags, 369+16,115,16,204
        DefLabel label25.Text,28,LabelObj.AlignLeft
DefItem border26,BorderCode,0,BorderObj.DefFlags, 388+32,115,12,258
DefItem titlebar27,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 216+16,379,18,258
        DefTitleBar titlebar27.Text,17,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton |TitleBarObj.GroupIndicate
DefItem border28,BorderCode,0,BorderObj.DefFlags, 236+16,378,164+16,244
DefItem atrlist29,AtrListCode,NullGuiItem,AtrListObj.DefFlags, 238+16,380,160+16,240
        DefAtrList scroll43
        DefAtrListItem atrlistitem30.Name,7,atrlistitem30.Text,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem31.Name,5,atrlistitem31.Text,10, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem32.Name,7,atrlistitem32.Text,3, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem33.Name,9,atrlistitem33.Text,11, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem34.Name,6,atrlistitem34.Text,10, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem35.Name,6,atrlistitem35.Text,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem36.Name,5,atrlistitem36.Text,1, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem37.Name,6,atrlistitem37.Text,1, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem38.Name,9,atrlistitem38.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem39.Name,12,atrlistitem39.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem40.Name,7,atrlistitem40.Text,4, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem41.Name,8,atrlistitem41.Text,2, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem atrlistitem42.Name,9,atrlistitem42.Text,8, 0, 0,-1000,1000, 1,10,100
        DefAtrListEnd
DefItem scroll43,ScrollHandleCode,atrlist29,ScrollHandleObj.DefFlags, 236+16,625,164+16,12
        DefScrollHandle 100,0,0,1,10
DefItem label44,LabelCode,0,LabelObj.DefFlags, 404+32,116,16,520
        DefLabel label44.Text,26,LabelObj.AlignLeft
%if 0
DefItem InnerWnd,WindowCode,NullGuiItem,WindowObj.DefFlags, 240,216,112,248 ;|GuiObj.Disabled|GuiObj.Hidden
        DefWindow NullGuiItem,0,0
        DefContainedItem TiWinBg
        DefContainedItem InnerTb
        DefContainedItem HelloBtn
        DefContainedItem HelloBtn2
        DefWindowEnd
%endif

%if 0
;innermost window
DefItem TiWinBg,WindowBgCode,0,WindowBgObj.DefFlags, 0,0,32000,32000
DefItem InnerTb,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags, 4,4,18,240
        DefTitleBar InnerTb.Text,19,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton
DefItem HelloBtn,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 48,40,24,184
        DefPushButton HelloBtn.Text,5,0
DefItem HelloBtn2,ButtonCode,NullGuiItem,ButtonObj.DefFlags, 74,32,24,184
        DefPushButton HelloBtn.Text,5,0
%endif

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

[section text]
        titlebar1.Text: db "Main Menu"
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

        titlebar3.Text: db "Song Display"
        label5.Text: db "    ",26,"              "

        titlebar7.Text: db "Song Attributes"
        atrlistitem10.Name: db "Voices:"
        atrlistitem10.Text: db "12345678"
        atrlistitem11.Name: db "Mute:"
        atrlistitem11.Text: db "Solo Sample"
        atrlistitem12.Name: db "Speed:"
        atrlistitem12.Text: db "120%"
        atrlistitem13.Name: db "Sample:"
        atrlistitem13.Text: db "Flute 3"
        atrlistitem14.Name: db "Game:"
        atrlistitem14.Text: db "Zelda"
        atrlistitem15.Name: db "File:"
        atrlistitem15.Text: db "zelda.sp3"
        atrlistitem16.Name: db "Title:"
        atrlistitem16.Text: db "Boss Music"
        atrlistitem17.Name: db "Author:"
        atrlistitem17.Text: db "Koji Kondo"
        atrlistitem18.Name: db "Date:"
        atrlistitem18.Text: db "1991-08-03"
        atrlistitem19.Name: db "Copyright:"
        atrlistitem19.Text: db "Nintendo"
        atrlistitem20.Name: db "Dumper:"
        atrlistitem20.Text: db "(unknown)"
        atrlistitem21.Name: db "Comments:"
        atrlistitem21.Text: db "(none)"
        titlebar23.Text: db "Sample Display"
        label25.Text equ label5.Text ;db "    *              "
        titlebar27.Text: db "Sample Attributes"
        atrlistitem30.Name: db "BrrNum:"
        atrlistitem30.Text: db "39"
        atrlistitem31.Name: db "Freq:"
        atrlistitem31.Text: db "440hz (A5)"
        atrlistitem32.Name: db "Volume:"
        atrlistitem32.Text: db "128"
        atrlistitem33.Name: db "Keyboard:"
        atrlistitem33.Text: db "(play keys)"
        atrlistitem34.Name: db "Instr:"
        atrlistitem34.Text: db "Soft Flute"
        atrlistitem35.Name: db "Patch:"
        atrlistitem35.Text: db "43"
        atrlistitem36.Name: db "Bank:"
        atrlistitem36.Text: db "0"
        atrlistitem37.Name: db "Track:"
        atrlistitem37.Text: db "0"
        atrlistitem38.Name: db "Envelope:"
        atrlistitem38.Text: db "ADSR"
        atrlistitem39.Name: db "Interpolate:"
        atrlistitem39.Text: db "None"
        atrlistitem40.Name: db "Length:"
        atrlistitem40.Text: db "1012"
        atrlistitem41.Name: db "LoopLen:"
        atrlistitem41.Text: db "64"
        atrlistitem42.Name: db "Checksum:"
        atrlistitem42.Text: db "1A358B9F"
        label44.Text: db "Status bar Goes Down here!"

;inner window
        InnerTb.Text: db "Innermost Title Bar"
        HelloBtn.Text: db "Hello"

NotReadyMsg:    db "This is a test and only a test,",13,13
                db "Had this been a real emergency,",13
                db "the beep you just heard would have been followed",13
                db "by at least some semi-useful reaction",0

[section code]
    dd MenuOwner
MenuOwner:
    cmp al,MenuMsg.Activate
    jne .Ignore
    cmp eax,MenuMsg.Activate|(mnuMain.Quit<<16)
    je .EndProgram
    cmp eax,MenuMsg.Activate|(mnuFile.Load<<16)
    jb .Ignore
    cmp eax,MenuMsg.Activate|(mnuFile.Record<<16)
    ja .Ignore
%ifdef WinVer
    api MessageBeep, MB_OK
    api MessageBox, [hwnd],NotReadyMsg,ProgramTitle,MB_ICONEXCLAMATION|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST
%endif
.Ignore:
    stc
    ret

.EndProgram:
  %ifdef WinVer
    api PostQuitMessage,0
    clc
  %else
    and dword [GuiFlags],~GuiFlags.Active
    ;clc
  %endif
    ret

; It's so stinkin easy to subclass!
HoverBorderCode:
    cmp al,Msg.MouseIn
    jne near BorderCode
    mov eax,Msg.SetItemFocus|ItemFocusFlags.Specified|ItemFocusFlags.SetGroup|ItemFocusFlags.SetItem
    jmp SendContainerMsg

__SECT__
