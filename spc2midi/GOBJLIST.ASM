        DefWindow vwSongDisplay,0,0
        DefContainedItem mainbg
        DefContainedItem ttlMainMenu
        DefContainedItem emnuMain
        DefContainedItem ttlSongDisplay
        DefContainedItem border6
        DefContainedItem vwSongDisplay
        DefContainedItem pbrSongPos
        DefContainedItem lblSongPos
        DefContainedItem tlbrSongControls
        DefContainedItem ttlSampleAtrs
        DefContainedItem border32
        DefContainedItem atrlSample
        DefContainedItem scroll47
        DefContainedItem ttlSongAtrs
        DefContainedItem border16
        DefContainedItem atrlSong
        DefContainedItem scroll30
        DefContainedItem FloatMenu
        ;DefContainedItem wndMisc
        DefWindowEnd
DefItem mainbg,MainBgCode,0,MainBgObj.DefFlags, 0,0,Screen.Height,Screen.Width
        DefTitleBar Program.Title,Program.Title_size,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MinButton

DefItem ttlMainMenu,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 24,6,18,108
        DefTitleBar ttlMainMenu.Text,9,TitleBarObj.GroupIndicate  |TitleBarObj.HelpButton
DefItem emnuMain,EmbedMenuCode,MenuOwner,EmbedMenuObj.DefFlags, 44,6,400,108
        DefMenuObj mnuMain

        DefMenuList mnuMain,IgnoreMsg
        DefMenuListItem .File,       "File",.FileImg,    MenuListObj.Opens|MenuListObj.Hidden, mnuFile
        DefMenuListItem .Control,    "Control",.ControlImg, MenuListObj.Opens, mnuControl
        DefMenuListItem .Seek,       "Seek",.SeekImg,    MenuListObj.Opens, mnuSeek
        DefMenuListItem .Goto,       "Goto",.GotoImg,    MenuListObj.Opens|MenuListObj.Hidden, mnuGoto
        DefMenuListItem .View,       "View",.ViewImg,    MenuListObj.Opens, mnuView
        DefMenuListItem .Options,    "Options",.OptionsImg, MenuListObj.Opens|MenuListObj.Hidden, mnuSettings
        DefMenuListItem .Quit,       "Quit",.QuitImg,    0
        DefMenuListEnd

        DefMenuList mnuFile,IgnoreMsg
        DefMenuListItem .Load,       "Load...",0, 0|MenuListObj.Disabled
        DefMenuListItem .Save,       "Store...",0, 0|MenuListObj.Disabled
        DefMenuListItem .Close,      "Close",0, 0|MenuListObj.Disabled
        DefMenuListItem .Recent,     "Recent",0, 0|MenuListObj.Disabled
        DefMenuListItem .Midi,       "MIDI file record",0, MenuListObj.Separator|MenuListObj.Disabled
        DefMenuListItem .WaveOut,    "Wave file record",0, 0|MenuListObj.Disabled
        DefMenuListItem .WaveSingle, "Export selected sample",0, MenuListObj.Separator|MenuListObj.Disabled
        DefMenuListItem .WaveBuffer, "Entire sample buffer",0, 0|MenuListObj.Disabled
        DefMenuListItem .WaveAll,    "All individually",0, 0|MenuListObj.Disabled
        DefMenuListItem .LogAsm,     "Log assembly",0, 0|MenuListObj.Disabled
        ;DefMenuListItem .DumpMem,    .6,0, 0|MenuListObj.Disabled
        DefMenuListEnd

        DefMenuList mnuControl,IgnoreMsg
        DefMenuListItem .Play,       "Play F5",0, 0
        DefMenuListItem .Pause,      "Pause F6",0, 0
        DefMenuListItem .Record,     "Record F7",0, 0|MenuListObj.Disabled
        DefMenuListItem .Stop,       "Stop F8",0, 0
        DefMenuListItem .Reverse,    "Reverse",0, MenuListObj.Separator
        DefMenuListItem .Restart,    "Restart Sh+F5",0, 0
        DefMenuListItem .Still,      "Still Sh+F6",0, 0
        DefMenuListItem .Halt,       "Halt",0, 0|MenuListObj.Disabled
        DefMenuListItem .As,         "Audio samples",0, MenuListObj.Separator
        DefMenuListItem .Sine,       "Sine waves",0, 0
        DefMenuListItem .Dls,        "DLS",0, 0|MenuListObj.Disabled
        DefMenuListItem .Fm,         "FM synthesis",0, 0
        DefMenuListItem .Gm,         "General MIDI",0, 0
        DefMenuListItem .Mpu,        "MIDI port",0, 0
        DefMenuListItem .Tune,       "Tuning wave",0, 0
        DefMenuListEnd

        DefMenuList mnuSeek,IgnoreMsg
        DefMenuListItem .Time,       "Time",0, 0|MenuListObj.Disabled
        DefMenuListItem .Start,      "Song start",0, 0
        DefMenuListItem .Finish,     "Song finish",0, 0
        DefMenuListItem .Repeat,     "Repeat",0, MenuListObj.Separator|MenuListObj.Disabled
        DefMenuListItem .SetRepeat,  "Set repeat",0, 0|MenuListObj.Disabled
        DefMenuListItem .FindRepeats,"Find repeat",0, 0|MenuListObj.Disabled
        DefMenuListItem .LoopStart,  "Loop start",0, MenuListObj.Separator|MenuListObj.Disabled
        DefMenuListItem .LoopFinish, "Loop finish",0, 0|MenuListObj.Disabled
        DefMenuListItem .SetLStart,  "Set loop start",0, 0|MenuListObj.Disabled
        DefMenuListItem .SetLFinish, "Set loop finish",0, 0|MenuListObj.Disabled
        DefMenuListItem .PrevNote,   "Previous note",0, MenuListObj.Separator|MenuListObj.Disabled
        DefMenuListItem .NextNote,   "Next note",0, 0|MenuListObj.Disabled
        DefMenuListEnd

        DefMenuList mnuGoto,IgnoreMsg
        DefMenuListItem .Address,    "Memory address",0, 0|MenuListObj.Disabled
        DefMenuListItem .Page0,      "Direct page 0",0, 0|MenuListObj.Disabled
        DefMenuListItem .Page1,      "Direct page 1",0, 0|MenuListObj.Disabled
        DefMenuListItem .BrrTbl,     "BRR Table",0, 0|MenuListObj.Disabled
        DefMenuListItem .Pc,         "Program counter",0, 0|MenuListObj.Disabled
        DefMenuListItem .ROM,        "BIOS/ERAM",0, 0|MenuListObj.Disabled
        DefMenuListEnd

        DefMenuList mnuView,IgnoreMsg, mnuDisplay, .DisplayOfs
        DefMenuListItem .Display,    "Song display >",0, MenuListObj.Opens, mnuDisplay
        DefMenuListItem .Samples,    "Sample list",0, MenuListObj.Disabled
        DefMenuListItem .Instruments,"Instrument list",0, MenuListObj.Hidden|MenuListObj.Disabled
        DefMenuListItem .Debugger,   "Debugger >",0, MenuListObj.Opens|MenuListObj.Hidden, mnuViewDebugger
        DefMenuListItem .Credits,    "Credits",0, 0|MenuListObj.Disabled
        DefMenuListItem .FullScreen, "Full screen",0, MenuListObj.Disabled
        DefMenuListEnd

        DefMenuList mnuDisplay,IgnoreMsg
        DefMenuListItem .HorzSheet,  "Horizontal note roll",0, 0
        DefMenuListItem .VertSheet,  "Note roll vertical",0, MenuListObj.Hidden|MenuListObj.Disabled
        DefMenuListItem .VolBars,    "Volume bars",0, 0
        DefMenuListItem .SampleInfo, "Voice information",0, 0
        DefMenuListItem .Keyboard,   "Keyboard",0, 0|MenuListObj.Disabled
        DefMenuListItem .Sample,     "Selected sample",0, 0|MenuListObj.Disabled
        DefMenuListItem .WaveClear,  "Oscilliscope clear",0, 0
        DefMenuListItem .WaveFaded,  "Oscilliscope faded",0, 0
        DefMenuListItem .WaveOcean,  "Oscilliscope ocean",0, 0
        DefMenuListItem .SignalCorrelationMap,  "Correlation map",0, 0
        DefMenuListItem .SignalCorrelationBars, "Correlation bars",0, 0
        DefMenuListItem .SignalCorrelationHistogram, "Correlation histogram",0, 0
        DefMenuListItem .None,       "None",0, 0
        DefMenuListEnd

        DefMenuList mnuViewDebugger,IgnoreMsg
        DefMenuListItem .Disasm,     "Disassembly",0, 0|MenuListObj.Disabled
        DefMenuListItem .Trace,      "Opcode trace",0, 0|MenuListObj.Disabled
        DefMenuListItem .SpcRam,     "SPC RAM",0, 0|MenuListObj.Disabled
        DefMenuListItem .DspRegs,    "DSP Registers",0, 0|MenuListObj.Disabled
        DefMenuListItem .Breakpoints,"Breakpoints",0, 0|MenuListObj.Disabled
        DefMenuListEnd

        DefMenuList mnuSettings,IgnoreMsg
        DefMenuListItem .Store,      "Store settings now",0, 0|MenuListObj.Disabled
        DefMenuListItem .Load,       "Reload settings",0, 0|MenuListObj.Disabled
        DefMenuListItem .Automatic,  "Automatic save",0, 0|MenuListObj.Disabled
        DefMenuListItem .Manual,     "Manual save only",0, 0|MenuListObj.Disabled
        DefMenuListItem .Sound,      "Sound",0, MenuListObj.Separator|MenuListObj.Disabled
        DefMenuListItem .Video,      "Video",0, 0|MenuListObj.Disabled
        DefMenuListEnd

DefItem ttlSongDisplay,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 24,118,18,516
        DefTitleBar ttlSongDisplay.Text,12,TitleBarObj.GroupIndicate|TitleBarObj.MaxButton
DefItem border6,BorderCode,0,BorderObj.DefFlags, 44,118,132,516
DefItem vwSongDisplay,SongDisplayCode,0,   GuiObj.DefFlags, 46,120,128,512
;DefItem vwSongDisplay,ButtonCode,NullGuiItem,   GuiObj.DefFlags|GuiObj.GroupStart, 46,120,128,512
;        db 0,0,0,0,0,0,0,0,0,0,0,0,0
DefItem pbrSongPos,BorderCode,0,BorderObj.DefFlags, 178,118,16,384
DefItem lblSongPos,LabelCode,0,LabelObj.DefFlags, 180,506,16,128
        DefLabel lblSongPos.Text,21,LabelObj.AlignLeft
DefItem tlbrSongControls,LabelCode,0,LabelObj.DefFlags, 198,118,16,516
        DefLabel tlbrSongControls.Text,29,LabelObj.AlignLeft ;55
DefItem ttlSampleAtrs,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 220,118,18,256
        DefTitleBar ttlSampleAtrs.Text,17,TitleBarObj.GroupIndicate
DefItem border16,BorderCode,0,BorderObj.DefFlags, 240,378,204,242
DefItem atrlSample,AtrListCode,atrlSampleOwner,AtrListObj.DefFlags, 246,120,192,238
        DefAtrList scroll47
        DefAtrListItem .Sample,     .SampleN,7,     NULL,0, 0, 0,0,GlobalSample.Max-1, 10,1,100
        DefAtrListItem .BrrNum,     .BrrNumN,7,     NULL,0, 0, 0,0,255, 1,1,16
        DefAtrListItem .Freq,       .FreqN,5,       NULL,0, 0, DefaultSample.Freq,0,MaxHertz, 1,10,100
        DefAtrListItem .Volume,     .VolumeN,7,     NULL,0, 0, DefaultSample.Volume,0,8192, 1,10,100
        DefAtrListItem .Patch,      .PatchN,6,      NULL,0, 0, DefaultSample.Patch,0,127, 1,1,16
        DefAtrListItem .Drum,       .DrumN,5,       NULL,0, 0, 0,0,127, 1,1,16
        DefAtrListItem .Bank,       .BankN,5,       NULL,0, 0, DefaultSample.Bank,0,16383, 16,1,256
        DefAtrListItem .Track,      .TrackN,6,      NULL,0, 0, DefaultSample.Track,0,31, 1,1,10
        DefAtrListItem .Envelope,   .EnvelopeN,9,   NULL,0, AtrListObj.Hidden, 0,0,0, 1,1,1
        DefAtrListItem .Interpolate,.InterpolateN,12,NULL,0,AtrListObj.Hidden, 0,0,0, 1,1,1
        DefAtrListItem .Valid,      .ValidN,6,      NULL,0, 0, 0,0,1, 1,1,1
        DefAtrListItem .Length,     .LengthN,7,     NULL,0, AtrListObj.Disabled, 0,0,0, 0,0,0
        DefAtrListItem .LoopLen,    .LoopLenN,8,    NULL,0, AtrListObj.Disabled, 0,0,0, 0,0,0
        DefAtrListItem .Offset,     .OffsetN,7,     NULL,0, AtrListObj.Disabled, 0,0,0, 0,0,0
        DefAtrListItem .LoopOffset, .LoopOffsetN,11,NULL,0, AtrListObj.Disabled, 0,0,0, 0,0,0
        DefAtrListItem .Checksum,   .ChecksumN,9,   NULL,0, AtrListObj.Disabled, 0,0,0, 0,0,0
        DefAtrListEnd
DefItem scroll30,ScrollHandleCode,atrlSong,ScrollHandleObj.DefFlags, 240,622,204,12
        DefScrollHandle 0,0,0,1,10
DefItem ttlSongAtrs,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags|GuiObj.GroupStart, 220,378,18,256
        DefTitleBar ttlSongAtrs.Text,36,TitleBarObj.GroupIndicate
DefItem border32,BorderCode,0,BorderObj.DefFlags, 240,118,204,242
DefItem atrlSong,AtrListCode,atrlSongOwner,AtrListObj.DefFlags, 246,380,192,238
        DefAtrList scroll30
        DefAtrListItem .Voices,     .0n,7, .0v,8,  0, 0,-1000,1000, 1,10,100
        DefAtrListItem .Mute,       .1n,5, .1v,11, 0, 0,-1000,1000, 1,10,100
        DefAtrListItem .Speed,      .2n,6, .2v,4,  0, 100,0,2000, 1,10,100
        DefAtrListItem .Game,       .4n,5, .4v,5,  0, 0,0,0, 1,10,100
        DefAtrListItem .File,       .5n,5, .5v,9,  0, 0,0,0, 1,10,100
        DefAtrListItem .Title,      .6n,6, .6v,10, 0, 0,0,0, 1,10,100
        DefAtrListItem .Author,     .7n,7, .7v,10, 0, 0,0,0, 1,10,100
        DefAtrListItem .Date,       .8n,5, .8v,10, 0, 0,0,1000, 1,10,100
        DefAtrListItem .Copyright,  .9n,10,.9v,8,  0, 0,0,21001231, 1,10,100
        DefAtrListItem .Dumper,     .10n,7,.10v,9, 0, 0,0,0, 1,10,100
        DefAtrListItem .Comments,   .11n,9,.11v,6, 0, 0,0,0, 1,10,100
        DefAtrListItem .Length,     .LengthN,7,NULL,0, 0, 0,0,0, 1,10,100
        DefAtrListItem .FadeTime,   .FadeTimeN,10,NULL,0, 0, 0,0,0, 1,10,100
        DefAtrListEnd
DefItem scroll47,ScrollHandleCode,atrlSample,ScrollHandleObj.DefFlags, 240,362,204,12
        DefScrollHandle 0,0,0,1,10



DefImageStruct mnuMain.FileImg,16,16
    incbin "data\tb_file.lbm"
DefImageStruct mnuMain.ControlImg,16,16
    incbin "data\tb_play2.lbm"
DefImageStruct mnuMain.SeekImg,16,16
    incbin "data\tb_seek.lbm"
DefImageStruct mnuMain.GotoImg,16,16
    incbin "data\tb_goto.lbm"
DefImageStruct mnuMain.ViewImg,16,16
    incbin "data\tb_view.lbm"
DefImageStruct mnuMain.OptionsImg,16,16
    incbin "data\tb_opt.lbm"
DefImageStruct mnuMain.QuitImg,16,16
    incbin "data\tb_quit.lbm"

%if 0
DefItem wndMisc,WindowCode,NullGuiItem,WindowObj.DefFlags, 100,100,56,200;169,200
        DefWindow NullGuiItem,0,0
        DefContainedItem wbgMisc
        DefContainedItem ttlMisc
        DefWindowEnd
DefItem wbgMisc,WindowBgCode,0,WindowBgObj.DefFlags, 0,0,56-10,200-10
DefItem ttlMisc,TitleBarCode,NullGuiItem,TitleBarObj.DefFlags, 4,4,18,196-10
        DefTitleBar ttlMainMenu.Text,9,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MaxButton
%endif

section text
        ttlMainMenu.Text: db "Main Menu"
        ttlSongDisplay.Text: db "Song Display"
        lblSongPos.Text: db "012:30.33 / 023:12.44"
        ;tlbrSongControls.Text: db "    ",26,"                L  |  A  S  D  F  G  H  M  T"
        tlbrSongControls.Text: db "(Song control bar unfinished)"
        ttlSongAtrs.Text: db "Song Attributes (these are all fake)"
        atrlSong.0n: db "Voices:"
        atrlSong.0v: db "12345678"
        atrlSong.1n: db "Mute:"
        atrlSong.1v: db "Solo Sample"
        atrlSong.2n: db "Speed:"
        atrlSong.2v: db "120%"
        atrlSong.4n: db "Game:"
        atrlSong.4v: db "Zelda"
        atrlSong.5n: db "File:"
        atrlSong.5v: db "zelda.sp3"
        atrlSong.6n: db "Title:"
        atrlSong.6v: db "Boss Music"
        atrlSong.7n: db "Author:"
        atrlSong.7v: db "Koji Kondo"
        atrlSong.8n: db "Date:"
        atrlSong.8v: db "1991-08-03"
        atrlSong.9n: db "Copyright:"
        atrlSong.9v: db "Nintendo"
        atrlSong.10n: db "Dumper:"
        atrlSong.10v: db "(unknown)"
        atrlSong.11n: db "Comments:"
        atrlSong.11v: db "(none)"
        atrlSong.LengthN: db "Length:",0
        atrlSong.LengthV: db "#### seconds",0
        atrlSong.FadeTimeN: db "Fade time:",0
        atrlSong.FadeTimeV: db "#### msecs",0
        ttlSampleAtrs.Text: db "Sample Attributes"
        atrlSample.SampleN: db "Sample:"
        atrlSample.SampleV: db "Flute 3"
        atrlSample.BrrNumN: db "BrrNum:"
        atrlSample.BrrNumV: db "###",0
        atrlSample.FreqN: db "Freq:"
        atrlSample.FreqV: db "#####hz (G10)",0
        atrlSample.VolumeN: db "Volume:"
        atrlSample.VolumeV: db "####",0
        atrlSample.PatchN: db "Patch:"
        atrlSample.PatchV: db "### "
                           times 22+1 db 0
        atrlSample.DrumN: db "Drum:"
        atrlSample.DrumV: db "###"
                          times 22+1 db 0
        atrlSample.BankN: db "Bank:"
        atrlSample.BankV: db "#####",0
        atrlSample.TrackN: db "Track:"
        atrlSample.TrackV: db "##",0
        atrlSample.ValidN: db "Valid:"
        atrlSample.ValidV: db "yes"
        atrlSample.EnvelopeN: db "Envelope:"
        atrlSample.EnvelopeV: db "ADSR"
        atrlSample.InterpolateN: db "Interpolate:"
        atrlSample.InterpolateV: db "None"
        atrlSample.LengthN: db "Length:"
        atrlSample.LengthV: db "######",0
        atrlSample.LoopLenN: db "LoopLen:"
        atrlSample.LoopLenV: db "######",0
        atrlSample.OffsetN: db "Offset:"
        atrlSample.OffsetV: db "#####",0
        atrlSample.None equ atrlSong.11v
        atrlSample.LoopOffsetN: db "LoopOffset:"
        atrlSample.LoopOffsetV: db "#####",0
        atrlSample.ChecksumN: db "Checksum:"
        atrlSample.ChecksumV: db "########",0
