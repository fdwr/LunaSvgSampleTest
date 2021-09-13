        DefContainedItem mainbg
        ;DefContainedItem EmbedMenu
        DefContainedItem EmbedMenu2
        DefContainedItem EmbedMenu3
        ;DefContainedItem label19
        ;DefContainedItem label20
        ;DefContainedItem label21
        ;DefContainedItem label22
        ;DefContainedItem label23
        DefContainedItem btnDummy
        DefContainedItem FloatMenu
        ;DefContainedItem FloatMenu2
        ;DefContainedItem FloatMenu3
        DefWindowEnd

DefItem mainbg,MainBgCode,0,GuiObj.NoKeyFocus|GuiObj.FixedLayer|GuiObj.FixedPosition, 0,0,Screen.Height,Screen.Width

DefItem btnDummy,ButtonCode,NullGuiItem,ButtonObj.DefGuiFlags|GuiObj.GroupStart, 178,10,12,36
        DefPushButton mnuControl.1,5,0

;FloatMenu:
;DefItem FloatMenu,FloatMenuCode,MenuOwner,FloatMenuObj.DefGuiFlags, 3,3,180,55
;        DefMenuObj mnuMain

DefItem FloatMenu,FloatMenuCode,MenuOwner,FloatMenuObj.DefGuiFlags, 0,0,0,0
;DefItem EmbedMenu,EmbedMenuCode,MenuOwner,EmbedMenuObj.DefGuiFlags, 13,3,180,55
        DefMenuObj mnuMain

        DefSubmenu mnuMain,IgnoreMsg
        DefSubmenuItem .File,       .0,0, SubmenuObj.Opens, mnuFile
        DefSubmenuItem .Control,    .1,0, SubmenuObj.Opens, mnuControl
        DefSubmenuItem .Seek,       .2,0, SubmenuObj.Opens, mnuSeek
        DefSubmenuItem .Goto,       .3,0, SubmenuObj.Opens, mnuGoto
        DefSubmenuItem .View,       .4,0, SubmenuObj.Opens, mnuView
        DefSubmenuItem .Options,    .5,0, SubmenuObj.Opens|SubmenuObj.Disabled, mnuOptions
        DefSubmenuItem .Quit,       .6,0, 0
        DefSubmenuEnd

        DefSubmenu mnuFile,IgnoreMsg
        DefSubmenuItem .Load,       .0,0, 0
        DefSubmenuItem .Save,       .1,0, 0
        DefSubmenuItem .Record,     .2,0, 0
        DefSubmenuItem .Settings,   .3,0, SubmenuObj.Opens, mnuFileSets
        DefSubmenuItem .ExportWave, .4,0, SubmenuObj.Opens, mnuExportWave
        DefSubmenuItem .LogAsm,     .5,0, 0
        ;DefSubmenuItem .DumpMem,    .6,0, 0
        DefSubmenuEnd

        DefSubmenu mnuFileSets,IgnoreMsg
        DefSubmenuItem .Reload,     .0,0, 0
        DefSubmenuItem .Save,       .1,0, 0
        DefSubmenuItem .Always,     .2,0, SubmenuObj.Separator
        DefSubmenuItem .Prompt,     .3,0, 0
        DefSubmenuItem .Never,      .4,0, 0
        DefSubmenuEnd

        DefSubmenu mnuExportWave,IgnoreMsg
        DefSubmenuItem .Single,     .0,0, 0
        DefSubmenuItem .Together,   .1,0, 0
        DefSubmenuItem .All,        .2,0, 0
        DefSubmenuEnd

        DefSubmenu mnuControl,IgnoreMsg
        DefSubmenuItem .Play,       .0,0, 0
        DefSubmenuItem .Pause,      .1,0, 0
        DefSubmenuItem .Stop,       .2,0, 0
        DefSubmenuItem .Record,     .3,0, 0
        DefSubmenuItem .Reverse,    .4,0, SubmenuObj.Separator
        DefSubmenuItem .Halt,       .5,0, 0
        DefSubmenuItem .Restart,    .6,0, 0
        DefSubmenuItem .Loop,       .7,0, 0
        DefSubmenuEnd

        DefSubmenu mnuSeek,IgnoreMsg
        DefSubmenuItem .Time,       .0,0, 0
        DefSubmenuItem .Ends,       .1,0, SubmenuObj.Opens, mnuSeekEnds
        DefSubmenuItem .Note,       .2,0, SubmenuObj.Opens, mnuSeekNote
        DefSubmenuItem .Marker,     .3,0, SubmenuObj.Opens, mnuSeekMarker
        DefSubmenuEnd

        DefSubmenu mnuSeekEnds,IgnoreMsg
        DefSubmenuItem .Front,      .0,0, 0
        DefSubmenuItem .Back,       .1,0, 0
        DefSubmenuItem .ForeLoop,   .2,0, 0
        DefSubmenuItem .AftLoop,    .3,0, 0
        DefSubmenuItem .Finish,     .4,0, 0
        DefSubmenuItem .SetForeLoop,.5,0, SubmenuObj.Separator
        DefSubmenuItem .SetAftLoop, .6,0, 0
        DefSubmenuItem .SetFinish,  .7,0, 0
        DefSubmenuItem .FindRepeats,.8,0, 0
        DefSubmenuEnd

        DefSubmenu mnuSeekNote,IgnoreMsg
        DefSubmenuItem .Prev,       .0,0, 0
        DefSubmenuItem .Next,       .1,0, 0
        DefSubmenuItem .First,      .2,0, 0
        DefSubmenuItem .Last,       .3,0, 0
        DefSubmenuEnd

        DefSubmenu mnuSeekMarker,IgnoreMsg
        DefSubmenuItem .Prev,       .0,0, 0
        DefSubmenuItem .Next,       .1,0, 0
        DefSubmenuItem .Insert,     .2,0, 0
        DefSubmenuItem .Delete,     .3,0, 0
        DefSubmenuItem .Edit,       .4,0, 0
        DefSubmenuEnd

        DefSubmenu mnuGoto,IgnoreMsg
        DefSubmenuItem .Address,    .0,0, 0
        DefSubmenuItem .Page0,      .1,0, 0
        DefSubmenuItem .Page1,      .2,0, 0
        DefSubmenuItem .BrrTbl,     .3,0, 0
        DefSubmenuItem .ROM,        .4,0, 0
        DefSubmenuEnd

        DefSubmenu mnuView,IgnoreMsg
        DefSubmenuItem .Notes,      .0,0, SubmenuObj.Opens, mnuViewNotes
        DefSubmenuItem .Samples,    .1,0, 0
        DefSubmenuItem .Instruments,.2,0, 0
        DefSubmenuItem .Debugger,   .3,0, SubmenuObj.Opens, mnuViewDebugger
        DefSubmenuItem .Credits,    .4,0, 0
        DefSubmenuEnd

        DefSubmenu mnuViewNotes,IgnoreMsg
        DefSubmenuItem .VertSheet,  .0,0, 0
        DefSubmenuItem .HorzSheet,  .1,0, 0
        DefSubmenuItem .VolBars,    .2,0, 0
        DefSubmenuItem .NoteSheet,  .3,0, 0
        DefSubmenuItem .Keyboard,   .4,0, 0
        DefSubmenuItem .Waveform,   .5,0, 0
        DefSubmenuItem .FullScreen, .6,0, SubmenuObj.Separator
        DefSubmenuEnd

        DefSubmenu mnuViewDebugger,IgnoreMsg
        DefSubmenuItem .Disasm,     .0,0, 0
        DefSubmenuItem .Trace,      .1,0, 0
        DefSubmenuItem .SpcRam,     .2,0, 0
        DefSubmenuItem .DspRegs,    .3,0, 0
        DefSubmenuItem .Breakpoints,.4,0, 0
        DefSubmenuEnd

        DefSubmenu mnuOptions,IgnoreMsg
        DefSubmenuItem .Sound,      .0,0, 0
        DefSubmenuEnd


;DefItem FloatingMenu2,FloatMenuCode,MenuOwner,FloatMenuObj.DefGuiFlags, 13,103,180,55
DefItem EmbedMenu2,EmbedMenuCode,MenuOwner,EmbedMenuObj.DefGuiFlags, 13,103,180,55
        DefMenuObj mnuMain

;DefItem FloatingMenu3,FloatMenuCode,MenuOwner,FloatMenuObj.DefGuiFlags, 13,203,180,55
DefItem EmbedMenu3,EmbedMenuCode,MenuOwner,EmbedMenuObj.DefGuiFlags, 13,203,180,55
        DefMenuObj mnuMain

;DefItem label19,LabelCode,0,LabelObj.DefGuiFlags, 25,76,8,239
        DefLabel label19.Text,55,LabelObj.AlignLeft
;DefItem label20,LabelCode,0,LabelObj.DefGuiFlags, 33,76,8,239
        DefLabel label20.Text,61,LabelObj.AlignLeft
;DefItem label21,LabelCode,0,LabelObj.DefGuiFlags, 41,76,8,239
        DefLabel label21.Text,62,LabelObj.AlignLeft
;DefItem label22,LabelCode,0,LabelObj.DefGuiFlags, 53,76,8,239
        DefLabel label22.Text,60,LabelObj.AlignLeft
;DefItem label23,LabelCode,0,LabelObj.DefGuiFlags, 61,76,8,239
        DefLabel label23.Text,61,LabelObj.AlignLeft

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
        mnuFileSets.2: db "Automatic save",0
        mnuFileSets.3: db "Prompt",0
        mnuFileSets.4: db "Manually",0

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
        mnuSeek.2: db "Note >",0
        mnuSeek.3: db "Marker >",0

        mnuSeekEnds.0: db "Front",0
        mnuSeekEnds.1: db "Back",0
        mnuSeekEnds.2: db "Foreloop",0
        mnuSeekEnds.3: db "Aftloop",0
        mnuSeekEnds.4: db "Finish",0
        mnuSeekEnds.5: db "Set foreloop",0
        mnuSeekEnds.6: db "Set aftloop",0
        mnuSeekEnds.7: db "Set finish",0
        mnuSeekEnds.8: db "Find repeats",0

        mnuSeekNote.0: db "Previous",0
        mnuSeekNote.1: db "Next",0
        mnuSeekNote.2: db "First",0
        mnuSeekNote.3: db "Last",0

        mnuSeekMarker.0 equ mnuSeekNote.0
        mnuSeekMarker.1 equ mnuSeekNote.1
        mnuSeekMarker.2: db "Insert",0
        mnuSeekMarker.3: db "Delete",0
        mnuSeekMarker.4: db "Edit...",0

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

        label19.Text: db "Unlike Window's menus, this menu stays open to whatever"
        label20.Text: db "was last selected, so you don't have to go through the entire"
        label21.Text: db "path again to select another choice that was in the same list."
        label22.Text: db "When you move the mouse over it, the menu pops out. When you"
        label23.Text: db "move out, the menu hides, but the path itself stays expanded."

        DefImageStruc submenuitem18.Image,0,8
        ;DefImageStruc submenuitem18.Image,7,8
        db 15,15,14,16,16,15,15,14,15,15,15,14,15,15,15,14,16,15,15,15,15,15,14,16,16,16,15,15,15,14,16,16,16,15,15,15,15,15,14,16,15,15,15,14,15,15,15,14,15,15,14,16,16,15,15,14,16,1,16,16,16,1,16,16,16,16,16,16,16,16,16,0,3,4,16,16,16,16,16,16,16,16,16,0,3,16,16,16,16,16,16,16,16,16,16,0,3,4,16,16,16,16,16,16,16,16,16,0,3,16,16,16,16,16,16,16,16,16,16,16,16


section code

    dd MenuOwner
MenuOwner:
    cmp eax,MenuMsg.Activate|(mnuMain.Quit<<16)
    je .EndProgram
    ;cmp al,MenuMsg.Activate
    ;jne .Ignore
    ;mov ebx,[esp+8]
    ;mov dword [esp+4],ebx
    ;jmp MenuCode.OpenSelectedChoice
.Ignore:
    stc
    ret

.EndProgram:
    and dword [GuiFlags],~GuiFlags.Active
    ;clc
    ret

section data
