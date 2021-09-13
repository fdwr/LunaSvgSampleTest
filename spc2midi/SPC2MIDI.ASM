; Spc2Midi - Main Routines
; SPC700 DSP to MIDI converter
; PikenSoŸt (c)2004
;
; By Dwayne Robinson (Peekin)
; Born 1999-11-21
; Updated 2003-05-03
; Platform DOS/Win32 assembler
; http://fdwr.tripod.com/snes.htm
; FDwR@hotmail.com
;
; Major Thanks to:
;   zsKnight for answering my annoying questions
;   AntiRes for a copy of the SF Sound Manual
;   And Ledi for transcribing it into text for all of us to read
;   _Demo_ for letting me see the SPCPLAY 2.0 source code
;   Gau for his SPC document
;   CyberGoth for encouragement
;   Authors of NASM/WDOSX/Alink for the great tools to create this program
;
;   And of course, the awesome SNES music writers (like Koji Kondo!)
;   who gave me a reason to write this
;
; Files:
;   Main
;       spc2midi.asm    main program that calls everything else
;       spcgui.asm      object event handlers and GUI code
;       songview.asm    display modes for notes playing (like visualizations)
;       gobjlist.asm    all objects and attributes of main window
;       file.asm        file related, such as loading spc's and zst's
;       settings.asm    reading/writing settings file
;
;   Emulation
;       spcemu.asm      SPC700 CPU emulation core, opcodes/timers/registers
;       dspemu.asm      DSP emulation, interpret/record DSP register writes
;       sample.asm      miscellaneous global/local sample table routines
;       disasm.asm      disassembly of opcodes
;
;   Sound
;       dspsim.asm      sound synthesis (DA/FM/MPU/Sine/GM) and MIDI logging
;       sound.asm       generic sound init/output routines (DA/FM/MPU)
;       midi.asm        generic MIDI file routines
;
;   Others (not included)
;       guidefs.asm     GUI definitions/constants/macros
;       guicode.asm     main GUI functions
;       guiobjs.asm     common UI objects code
;       gfxdefs.asm     graphics definitions/constants/macros
;       gfx.asm         lines/borders/fonts
;       mywininc.asm    small subset include of windows.h
;
; Overview:
;   If you want to jump straight to the code...
;
;   Windows: Main (spc2midi.asm) creates high priority thread
;   DOS: Main sets timer interrupt handler
;   Main loop calls SpcEmu to emulate
;   SpcEmu (spcemu.asm) emulates opcodes/timers/registers, calls DspEmu
;    DspEmu (dspemu.asm) interprets/records all DSP register writes to buffer
;   DOS: TimerHandler (spc2midi.asm) calls PlaySounds every PIT interrupt
;   Windows: PlayThread loops, calling PlaySounds every 1/30 second
;    PlaySounds (dspsim.asm) calls each individual sound output function
;     VoiceEmu (dspsim.asm) simulates each voice, reading from the DSP buffer
;
; Compiling:
;   NASM 0.98 (Netwide Assembler)
;   ALINK 1.6 (Linker by Anthony Williams)
;   WDOSX 0.96 (Wuschel's DOS Extender)
;
;   DOS with GUI:
;    nasm -f win32 spc2midi.asm -o spc2midi.cof -dDosVer
;    alink -oPE spc2midi.cof -entry Main -subsys con
;    stubit -nowfse spc2midi.exe
;
;   DOS with console only:
;    nasm -f win32 spc2midi.asm -o spc2midi.cof -dDosVer -dConVer
;    alink -oPE spc2midi.cof -entry Main -subsys con
;    stubit -nowfse spc2midi.exe
;
;   Windows:
;    nasm -f win32 spc2midi.asm -o spc2midi.exe -dWinVer
;    alink -oPE spc2midi.cof winimp.lib -entry Main
;
;   Windows with console only:
;    nasm -f win32 spc2midi.asm -o spc2midi.exe -dWinVer
;    alink -oPE spc2midi.cof winimp.lib -entry Main -subsys con
;
;   Note that all compilations are compiled to PE. Yes, even the DOS version
;   is actually compiled into a Windows 32bit executable (yet run in a DOS
;   environment thanks to WDOSX).
;
; DSP Write Buffering:
;   Unlike most SPC players which play directly as they emulate, this player
;   stores DSP writes to a large buffer, which is what it really plays from.
;   This allows the song to easily be skipped forward, backward, or to
;   any position you like without having to restart from the beginning - even
;   play backwards!
;
;   It also greatly increases speed on the second play (after the initial run
;   through), since the emulation has already finished and the program can
;   focus purely on playing from the buffer. Typical CPU% on my machine (PII
;   350Mhz) is 12% for both emulation and sound output, but just 3% for sound
;   output only, with the buffer filled. On my old one (386 25mhz) it takes
;   more than the little processor is capable of to both emulate and play,
;   but it can play in realtime at 11khz once buffered.
;
;   But wouldn't that store huge amounts of information!? Yes :)
;   But isn't that why you have 64MB of RAM? No, actually it works on a mere
;   4MB DOS machine (my original development platform) because the recorder
;   only keeps important information. Many games send unnecessary, redundant
;   commands to the DSP port, which it discards. The DSP emulation never
;   records key on/off commands that affect no voices, pitches that are the
;   same, duplicate times, register changes in inactive voices (KOF), or
;   register changes to unsupported features (like ECHO).
;
;   Depending on how many unique commands the song requires, the buffer can
;   hold from a few minutes to several. In any case, more than enough to hold
;   the longest songs I've ever heard.
;
; FM Synthesis
;   Another speed advantage for slow machines is that it can play only a few
;   synthesized notes every 1/30th of a second rather than up to 8*32000 wave
;   samples per second. Admittedly these simplified sounds don't do justice
;   to the mood of the real music though :( None of those beautiful samples,
;   no smooth slides, cool stereo panning... Yep, take all those away, and
;   what do you have, a MIDI! ;)
;
; Sample Identification
;   Unlike SpcTool, Spc2Midi does not assign attributes to a sample's
;   directory entry (a number 0-255), instead it assigns them to the sample.
;   Each valid sample is uniquely identified by its length, loop length, and
;   a 32bit checksum. So that means if you set the attributes for a sample in
;   one SPC of Zelda, those same attributes automatically apply to that same
;   sample in another SPC, regardless of where it may have been remapped to
;   in the directory table.
;
; Human Hearing:
;   In human hearing, a note that is twelve semitones above another (or one
;   whole octave), is actually twice as high in frequency. If a note played
;   at the rate of 4096 (32khz) sounded a middle C, 2048 would be one octave
;   below, and 8192 would be an octave above. This exponential curve must be
;   converted to a linear scale to obtain the MIDI note.
;
; Converting Play Rates
;   BRR sample play rates (0-16383) can't be converted directly to MIDI notes,
;   since each sample may be recorded at its own pitch. For example, a flute
;   instrument sound may be recorded at middle C, but a piano sound might be
;   recorded at G. I'm not sure why the music programmers choose these
;   seemingly arbitrary pitches rather than make them all have the same base
;   pitch. To compensate for this though, the play rates are multiplied by
;   their sample's apparent pitch. This is the pitch as heard by the human
;   ear (when played at actual recording speed of 32khz) rather than some
;   other frequency determinant like fourier analysis. This product (after
;   being shifted back down because of the multiplication) indexes into a
;   large table, to convert the exponential value into a linear note number.
;   The default apparent pitch for all samples is 440hz (A5).
;
;   PitchValue = (PlayRate * ApparentPitch) >> 12 [4096]
;   NoteNumber = HertzToNoteTable [PitchValue]
;
; Hertz to Pitch Table
;   MIDI notes (C0-G10 or 0-127) range in frequency from 8hz to 12543hz, with
;   any pitches outside that range constrained. So, it would make sense to
;   build a table from 0-12543, but because the lower frequencies are so
;   close (notes 4 and 5 can both be rounded to 10hz), I'd rather double the
;   table size for more precision.
;
;   PitchValue = (PlayRate * (ApparentPitch*2)) >> 13 [8192]
;
;=============================================================================

[section code code]
CodeStart:
[section data data]
[section text data]
[section bss bss]

;%define debug
%ifdef ConVer
%define UseConsoleDebug
%endif
%ifdef DosVer
%define UseConsoleDebug
%endif
%ifndef ConVer
%define GuiVer
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Global program constants/variables
;
; A few other Global variables found in other source files include:
;   SpcRam
;   DspRam
;   DspRamCopy
;   SpcEram
;
;   DspBuffer       huge buffer to store DSP writes
;   LocalSample     information table for samples locally loaded in SPC state
;   GlobalSample    additional information for global samples across states
;   SamplesBuffer   digital audio cache for decompressed samples
;
;   MainSongPos
;   FmSongPos
;   WaveSongPos
;   MpuSongPos
;   GmSongPos
;   SineSongPos
;
%define Program.VersionDef ".133"
%define Program.NameDef    "Spc2Midi"
%define Program.ClassDef   "PknSpc2Midi"

SpcDebugIoPrint     equ 0   ;show register reads/writes
PlayThreaded        equ 1   ;set zero for debugging sound routines (crashing in any INT8 routine is a really BAD thing to do!)
PlayHighPriority    equ 0   ;interrupt other programs so sound does not skip
SupportPitchSlide   equ 1   ;record pitch slide and do effects

CyclesPerSecond     equ 2496000
CyclesPerFrame      equ 83200   ;1/30
CyclesPerVblank     equ 41600   ;1/60
CyclesPerTickDef    equ 39      ;default cycles per SPC700 timer tick
TicksPerSecond      equ 63990   ;64000 is the true speed, but isn't evenly divisible by 30
TicksPerFrame       equ TicksPerSecond/30   ;ticks to advance for every timer interrupt or thread call (1.1931817MHz / 30)
MaxPlayLag          equ 6       ;maximum allowable time difference between main loop and interrupt play (in frame counts)
DspBufferSize       equ 262144*4;megabyte buffer to store DSP writes
MaxHertz            equ 12543

Opr.None            equ 0
FilePathMaxLen      equ 260

StackReg:           ;order of registers after using PUSHA
.Di     equ 0
.Si     equ 4
.Bp     equ 8
.Sp     equ 12
.Bx     equ 16
.Dx     equ 20
.Cx     equ 24
.Ax     equ 28

section bss
Program:
%ifdef DosVer
.DataSelector:      resd 1  ;necessary for sound interrupt handler
.PspSelector:       resd 1  ;selector to PSP
.Env:               resd 1  ;command environment strings
.PicBaseMaster:     resb 1
.PicBaseSlave:      resb 1
%elifdef WinVer
.BaseAddress        equ 400000h ;base address of program (Windows module handle)
%endif
section text
%ifdef WinVer
.Class:             db "PknSpc2Midi",0
%endif
%ifdef debug
.Title:             db "**DEBUG VERSION** ",Program.NameDef," ",Program.VersionDef,0
%else
.Title:             db Program.NameDef," ",Program.VersionDef," **PREVIEW**",0
%endif
.Title_size         equ $-.Title-1

section bss
SpcFileName:        resb FilePathMaxLen
SpsFileName:        resb FilePathMaxLen
MidiFileName:       resb FilePathMaxLen

%if 0
%ifdef DosVer
; real mode register structure
Regs:
.edi                resd 1
.esi                resd 1
.ebp                resd 1
.res                resd 1  ;Reserved by system
.ebx                resd 1
.edx                resd 1
.ecx                resd 1
.eax                resd 1
.flags              resw 1
.es                 resw 1
.ds                 resw 1
.fs                 resw 1
.gs                 resw 1
.ip                 resw 1
.cs                 resw 1
.sp                 resw 1
.ss                 resw 1
%endif
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Play status variables
;
section data
align 4, db 0

PlayOptions:
.FmVoices           equ 1       ;play using FM synthesis
.AsVoices           equ 2       ;play using digital audio samples (like any other SPC player)
.SineVoices         equ 4       ;simulate with sine waves
.DlsVoices          equ 8       ;simulate with downloadable sounds
.GmVoices           equ 16      ;send MIDI commands to synthesizer
.MpuVoices          equ 32      ;send MIDI commands to MIDI port (MPU401)
.Sample             equ 64      ;play the selected BRR sample
.TuningWave         equ 128     ;A440hz for pitch comparison
.WaveLog            equ 256     ;record wave output to file
.MidiLog            equ 512     ;log to a MIDI file
.MidiLogBit         equ 9       ;
.ShowInfo           equ 1024    ;display sample info
.DumpBrr            equ 2048    ;dump wave buffer
.ConOnly            equ 4096    ;console interface, no gui
.FileGiven          equ 8192    ;initial file specified
.FileGivenBit       equ 13      ;
.Pause              equ 16384   ;all music paused, sounds can still play though
.Stop               equ 32768
.Emulate            equ 65536   ;emulate SPC or stop emulation (when the buffer is full)
.Suspend            equ 131072  ;sound output thread totally halted
.Terminate          equ 262144  ;flags to thread it should die
.Interrupted        equ 524288  ;flag that code was interrupted by timer
.InterruptedBit     equ 19
.InInterrupt        equ 1048576 ;flags we're currently in the interrupt to
.InInterruptBit     equ 20      ;prevent possible recursion on slow machines
.Disassemble        equ 2097152
.SlowPlay           equ 8388608 ;do NOT preemulate
                    dd .Suspend|.Stop

PlayTimeStart:      dd 0        ;time before interrupt (start of time range)
PlayTimeEnd:                    ;time after interrupt (end of time range) alias of PlayTime
PlayTime:           dd 0        ;actual time (based on timer interrupt)
PlayTimePrev:       dd 0        ;previous play time
PlayStall:          dd 0        ;counter telling sound handler to wait because main loop is behind
PlaySpeed:          dd TicksPerFrame ;number of ticks every 1/30 of a second
PlayRepeatPoint:    dd -1       ;point melody first repeats
PlayAdvance:        dd TicksPerFrame ;number of ticks to advance (may be temporarily different from PlaySpeed)
PlayLoopStart:      dd 0        ;loop starts as beginning of song
PlayLoopFinish:     dd -1       ;set end to max possible value

DspBufferEnd:       dd 0        ;pointer in buffer to last write
DspBufferTime:      dd 0        ;time of last event written to buffer
DspFlags:
.NewVoice           equ 1
.NewVoiceBit        equ 0
.PitchSlide         equ 2
                    dd .PitchSlide

EnabledVoices:      dd 255      ;default all voices active (1=active 0=muted)

SelectedSample:     dd 0
DefaultInstrument:  dd DefaultSample.Instrument
DefaultFreq:        dd DefaultSample.Freq
DefaultVolume:      dd DefaultSample.Volume


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; GUI definitions
;
%ifdef GuiVer
    GuiDebugMode equ 0
    %define GuiVer
    %define UseAtrListCode
    %define UseBorderCode
    %define UseButtonCode
    %define UseEmbedMenuCode
    %define UseFloatMenuCode
    %define UseImageCode
    %define UseLabelCode
    %define UseMainBgCode
    %define UseScrollHandleCode
    %define UseTextPromptCode   ;include code for...
    %define UseTitleBarCode     ;include code for title bars
    %define UseWindowCode       ;include code for window
    %define UseWindowBgCode         ;window background
    %define NoGuiTimerHandler
    Timer.MaxItems equ 16
    %include "gui\guidefs.asm"

    %define UseGuiGfx
    %define UseDisplayBuffer 1  ;draw to buffer before copying to screen
    %define UseGuiPalette       ;include the standard GUI palette
    %define UseGuiCursor        ;use mouse and cursor
    %define UseGuiFonts         ;include standard handdrawn fonts
    %ifdef WinVer
     Screen.Height       equ 452
     Screen.Width        equ 640
    %else
     %define UseDefaultVgaScreen;use standard (but old) mode 320x200:256
    %endif
    %define Screen.Palette GuiPalette
    %include "gui\gfxdefs.asm"      ;graphics color constants, font characters...

%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Windows definitions/declarations
;
%ifdef WinVer
    %define UseWindowStyles
    %define UseFileSystem
    %define UseProcess
    %define UseThreads
    %define UseMultimedia
    %define UseTextConsole
    %ifdef ConVer
      %define UseKeyboard
    %elifdef GuiVer
      %define UseWindowMsgs
      %define UseWindowPaint
      %define UseWindowGfx
      %define UseWindowSysVars
    %endif

    %include "win\mywininc.asm"

    section data
    align 4, db 0
    dummy:  dd 0                ;dword to waste unused values
    hout:   dd 0                ;standard output handle (text console)
    hin:    dd 0                ;standard input handle (keyboard)

  %ifdef GuiVer
    section data
    align 4, db 0
    hwnd:   dd 0                ;window handle
    hdc:    dd 0                ;class device context
    ;hdcc:   dd 0                ;compatible device context
    hpal:   dd 0                ;palette handle
    hdib:   dd 0                ;DIB section handle
    tid:    dd 0                ;thread identifier
    
    wc:
    istruc WNDCLASS
    at WNDCLASS.style,         dd CS_CLASSDC
    at WNDCLASS.lpfnWndProc,   dd MsgProc
    at WNDCLASS.cbClsExtra,    dd 0
    at WNDCLASS.cbWndExtra,    dd 0
    at WNDCLASS.hInstance,     dd Program.BaseAddress ;(default image base is at 4MB)
    at WNDCLASS.hIcon,         dd NULL
    at WNDCLASS.hCursor,       dd NULL
    at WNDCLASS.hbrBackground, dd NULL ;COLOR_BTNFACE + 1
    at WNDCLASS.lpszMenuName,  dd NULL
    at WNDCLASS.lpszClassName, dd Program.Class
    iend
    
    section bss
    rect:
    point:  resb RECT_size      ;left,top,right,bottom
    msg:    resb MSG_size
    ps:     resb PAINTSTRUCT_size
  %endif

%else
    %macro debugwrite 1-*
    %endmacro
    %macro debugpause 1-*
    %endmacro
    NULL equ 0
%endif

;=============================================================================
; MAIN ENTRY POINT
;=============================================================================

section code
global Main

%ifdef WinVer

%ifdef GuiVer
;=============================================================================
; WINDOWS GUI MAIN
;=============================================================================

Main:
    ; defeat Window's on demand page loading, so bits and pieces aren't read
    push dword .AfterPageLoad
.DemandPageLoad:
    mov esi,CodeStart
    mov ecx,TextEnd
    sub ecx,esi                 ;TextEnd-CodeStart = total page bytes
    shr ecx,12                  ;/4096 = total pages
.NextPage:
    mov eax,[esi]               ;force page fault
    add esi,4096                ;next 4k page
    dec ecx
    jg .NextPage
    ret
.AfterPageLoad:

    ;mov eax,BssEnd
    ;sub eax,CodeStart
    ;debugpause "mem = %d",eax

  %ifdef debug
  %ifdef UseConsoleDebug
    api AllocConsole
    api SetConsoleTitle, Program.Title
    api GetStdHandle, STD_OUTPUT_HANDLE
    test eax,eax
    js near .Terminate
    mov [hout],eax
    push dword FALSE            ;cursor invisible
    push dword 1                ;dummy size percentage
    api SetConsoleCursorInfo, eax, esp
    add esp,byte 8              ;free PCONSOLE_CURSOR_INFO
    ;api SetConsoleTextAttribute, [hout],FOREGROUND_GREEN|FOREGROUND_INTENSITY
    api FillConsoleOutputAttribute, [hout],FOREGROUND_GREEN|FOREGROUND_INTENSITY,80*50,0,dummy
  %endif
  %endif

    ; Check command line parameters
    call CheckStartParams
    jnc .ParamsOk
.TerminateWithMsg:              ; (edx=message text ptr)
    ;api MessageBox, 0, edx, Program.Title, MB_ICONINFORMATION
    cmp edx,Text.About
    jne .ShowMsgGiven
    mov edx,Program.Title
.ShowMsgGiven:
    api MessageBox, 0, Text.About,edx, MB_ICONINFORMATION
    jmp [ExitProcess]
.ParamsOk:

    api GetCurrentThreadId
    mov [tid],eax

    CreateGuiWin                ;create main ui window
    push dword MainWindow       ;window data structure
    InitGfx                     ;initialize graphics
    InitGui                     ;initialize user interface elements
    api ShowWindow, [hwnd],SW_SHOWDEFAULT

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; load file & initialize core
    test dword [PlayOptions],PlayOptions.FileGiven
    jz .NoFileLoaded
    call LoadSpcState
    jnc .FileLoaded
    api MessageBox, 0, edx, Program.Title, MB_ICONINFORMATION
    jmp short .NoFileLoaded
.FileLoaded:
    and dword [PlayOptions],~PlayOptions.Stop
    or dword [PlayOptions],PlayOptions.Emulate
.NoFileLoaded:

    ; load configuration file...
    call DspEmu.Init            ;clear brr sample table, flag all samples as unused
    call LoadMainSettings

    call SpcEmu.Init            ;copy RAM, registers, set timers
    call DspEmu.Reinit          ;clear brr sample table, flag all samples as unused
    call LocalSamplesInfo
    call MatchLocalSamples

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; initialize audio output
    call InitDaSound.IfEnabled  ;open digital audio (for wave samples)
    call InitFmSound.IfEnabled  ;open FM audio device
    call InitMpu.IfEnabled      ;open MIDI port output
    call InitGm.IfEnabled       ;initialize internal synthesizer
    call DspSim.Init            ;initialize DSP simulation structures and enable at least one type of sound output, expand 128 MIDI notes into 22k pitch table
    call OutputMidiFile.StartIfEnabled
    call PlayThread.Init

    call SongView.Init
    api UpdateWindow, [hwnd]
    ;api MessageBox, [hwnd], Text.PreviewOnly,Program.Title, MB_ICONEXCLAMATION
    and dword [PlayOptions],~PlayOptions.Suspend

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.MainLoop:
.NoMsg:
    call .Redraw

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Emulate as needed
.NextEmuRun:
    test dword [PlayOptions],PlayOptions.Emulate
    jz .NoEmu
    mov eax,CyclesPerFrame      ;for normal playing (~1/30 second cycles)
    call SpcEmu.Start
.ValidateVoice:
    btr dword [DspFlags],DspFlags.NewVoiceBit
    jnc .NoNewVoices
    ;call MatchBrrSamples.New
.NoNewVoices:

    ; if emu-dsp > 1 minute || buffer full, then stop emulation
    mov eax,[SpcEmu.TotalTime]
    sub eax,[DspBufferTime]
    cmp eax,60*TicksPerSecond
    jae .StopEmu
    cmp dword [DspBufferEnd],DspBufferSize    ;stop emulation if buffer full
    jb .EmuDone
.StopEmu:
    and dword [PlayOptions],~PlayOptions.Emulate
    jmp short .EmuDone
.NoEmu:
    ;api Sleep,33
    api WaitMessage
.EmuDone:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Update miscellaneous
    btr dword [PlayOptions],PlayOptions.InterruptedBit
    jnc near .NoUpdate

    ; loop play if necessary
    test dword [PlayOptions],PlayOptions.Stop|PlayOptions.Pause
    jnz .NoLoop
    mov eax,[PlayTime]
    cmp [PlayLoopFinish],eax
    ja .NoLoop
    mov eax,[PlayLoopStart]
    mov [PlayTime],eax
.NoLoop:

  %if PlayThreaded=0
    call PlaySounds
  %endif

    test dword [PlayOptions],PlayOptions.MidiLog
    jz .NoMidiOutput
    call OutputMidiFile
.NoMidiOutput:

    test dword [PlayOptions],PlayOptions.Pause|PlayOptions.Stop|PlayOptions.Suspend
    jnz .NoVisual
    test dword [GuiFlags],GuiFlags.Suspended
    jnz .NoVisual
    call [SongView.Handler]
    mov ebx,vwSongDisplay
    call SendContainerRedraw.Partial
.NoVisual:

%ifdef debug
  section data
    .DebugCounter:  dd 0
  section code
    dec dword [.DebugCounter]
    jns .SkipDebugPrint
    ;call PrintDebugInfo
    mov dword [.DebugCounter],6
.SkipDebugPrint:
%endif

.NoUpdate:
    mov [PlayStall],dword 0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.NextMsg:
    xor eax,eax
    api PeekMessage, msg, eax,eax,eax,PM_REMOVE
    test eax,eax
    jz near .NoMsg
    mov eax,[msg+MSG.message]
    cmp eax,WM_TIMER
    je near .Timer
    ;debugwinmsg "thread msg=%X %s",eax,edx

    cmp eax,WM_KEYFIRST
    jb .NotKeyMsg
    cmp eax,WM_KEYLAST
    jbe near .KeyMsg
.NotKeyMsg:
    cmp eax,WM_MOUSEFIRST
    jb .NotMouseMsg
    cmp eax,WM_MOUSELAST_BUTTON
    jbe near .MouseMsg
.NotMouseMsg:
    ;cmp eax,WM_TIMER
    ;je near .Timer
    cmp eax,WM_PAINT
    je near MsgProc.ThreadPaint
    cmp eax,WM_QUIT
    je .Quit

    api DispatchMessage, msg
    jmp .NextMsg

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Quit:
    debugwrite "terminating program"

    call PlayThread.Release
    call OutputMidiFile.Stop
    call InitGm.Release
    call InitMpu.Release
    call InitFmSound.Release
    call InitDaSound.Release

    push dword MainWindow       ;window data structure (maybe redundant push)
    DeinitGui
    DeinitGfx
.Terminate:
    api ExitProcess,[msg+MSG.wParam]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (dword main window, eax=message)
.KeyMsg:
    call GetKeyboardMsg
    jc near .NextMsg
    ;push dword MainWindow      ;window data structure
    call SendKeyMsg             ;send keypress to active window
    ;lea esp,[esp+4]
    jnc near .NextMsg

    mov eax,[Keyboard.LastMsg]  ;access character and scancode
    ;if ALT key, focus on menu

    cmp al,Msg.KeyPress
    jne near .NextMsg           ;ignore releases

   %ifdef debug
    cmp al,VK_F10
    je .NoClearScreen
    push eax
    call ClearScreen
    api InvalidateRect, [hwnd],NULL,0
    pop eax
    .NoClearScreen:
   %endif

    mov esi,WindowCode.TabKeys
    call ScanForKey
    jc .NotTab
    mov eax,[WindowCode.TabMsgsTbl+ecx*4]
    ;push dword 0               ;pass on dummy index
    ;push dword MainWindow      ;window data structure
    call SetItemFocus           ;set active focus
    ;add esp,byte 8
    jmp .NextMsg
.NotTab:

    mov esi,.ControlKeys
    call ScanForKey
    jc near .NextMsg
    push dword .NextMsg
    jmp [.ControlKeyJtbl+ecx*4]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (dword main window, eax=message)
.MouseMsg:
    call GetMouseMsg
    jc near .NextMsg

    test dword [Mouse.Buttons],Mouse.LeftPress|Mouse.RightPress|Mouse.MiddlePress
    jz .NoMouseActivate
    test dword [GuiFlags],GuiFlags.Suspended
    jz .NoMouseActivate
    push eax
    xor edx,edx
    api SetWindowPos, [hwnd],HWND_TOP, edx,edx, edx,edx, SWP_NOMOVE|SWP_NOSIZE|SWP_NOSENDCHANGING
    pop eax
.NoMouseActivate:

    ;debugwrite "mouse %d %d %X fk=%X",[Cursor.Row],[Cursor.Col],[Mouse.Buttons],[msg+MSG.wParam]
    push dword [Cursor.Col]
    push dword [Cursor.Row]
    push dword MainWindow       ;send mouse message to window cursor is over or window which grabbed focus
    call SendMouseMsg           ;click/move/enter/exit
    add esp,byte 12
    jmp .NextMsg

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Timer:
    push dword .NextMsg
    jmp SendTimeMsgs

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Redraw:
    test byte [Display.RedrawFlags],Display.RedrawItems|Display.RedrawCursor|Display.RedrawPalette|Display.CursorMoved
    jz .NoRedraw
    api GdiFlush                ;ensure that BitBlt from previous call is done
.RedrawNow:

    call HideCursor
    test byte [Display.RedrawFlags],Display.RedrawItems
    jz .RedrawCursor            ;only cursor moved or palette changed

    call SaveDisplayVars        ;save main window's display vars
    push dword MainWindow
    call SendRedrawComplex      ;redraw all main items, cascading down to each contained item
    ;call SendRedrawSimple       ;redraw all main items, cascading down to each contained item
    pop ebx                     ;discard window ptr
    and dword [MainWindow+GuiObj.Flags],~GuiObj.Redraw
    api InvalidateRect, [hwnd],Display.Clips,FALSE
    ;api InvalidateRect, [hwnd],NULL,FALSE ;(debug-redraw all)
    call RestoreDisplayVars     ;restore main window's display vars

.RedrawCursor:
    call DrawCursor
    and byte [Display.RedrawFlags],~(Display.RedrawItems|Display.RedrawCursor|Display.RedrawPalette|Display.CursorMoved)
.NoRedraw:
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MsgProc:
    params 4, .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    ;debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[esp+.wParam+4],[esp+.lParam]

    ;cmp eax,WM_DESTROY
    ;je near .Destroy
    ;jmp [DefWindowProc]

    ; WM_KEYDOWN, WM_SYSKEYDOWN send key msg
    ; WM_SETFOCUS flag active
    ; WM_KILLFOCUS flag inactive
    ; WM_ENTERMENULOOP flag inactive
    ; WM_EXITMENULOOP flag active (partially)
    ; WM_PALETTECHANGED call UpdateColors
    ; WM_QUERYNEWPALETTE call RealizePalette

;   cmp eax,WM_CREATE
;   je .Create
;   cmp eax,WM_NCCREATE
;   je .NcCreate
;   cmp eax,WM_ACTIVATE
;   je near .Activate

    ;cmp eax,WM_QUERYNEWPALETTE
    ;je near .SetPalette
    ;cmp eax,WM_PALETTECHANGED
    ;je near .PaletteChanged
    ;cmp eax,WM_TIMER
    ;je near .Timer
    cmp eax,WM_PAINT
    je near .Paint
    cmp eax,WM_CAPTURECHANGED
    je near .CaptureChanged
    cmp eax,WM_DROPFILES
    je near .FileDropped
    ;cmp eax,WM_SETCURSOR
    ;je .RetTrue
    cmp eax,WM_NCPAINT
    je .RetFalse
    cmp eax,WM_NCCALCSIZE
    je .RetFalse
    cmp eax,WM_NCACTIVATE
    je .RetTrue
    cmp eax,WM_NCHITTEST
    je .RetTrue
    cmp eax,WM_WINDOWPOSCHANGING
    je .RetFalse
    cmp eax,WM_ERASEBKGND
    je .RetTrue
    cmp eax,WM_WINDOWPOSCHANGED
    je .RetFalse
    cmp eax,WM_MOVING
    je .RetTrue
    ;cmp eax,WM_CANCELMODE
    ;je .RetFalse
    cmp eax,WM_SETFOCUS
    je .GainFocus
    cmp eax,WM_KILLFOCUS
    je .LoseFocus

    cmp eax,WM_DESTROY
    je .Destroy
    ;cmp eax,...

    extern DefWindowProc
    jmp [DefWindowProc]

.RetTrue:
    mov eax,TRUE
    ret 16

.Destroy:
    ;debugwrite "destroying window"
    api PostQuitMessage,0
.RetFalse:
    xor eax,eax
    ret 16

.GainFocus:
    mov eax,Msg.KeyIn|KeyMsgFlags.WindowInOut|KeyMsgFlags.SetItem
    and dword [GuiFlags],~(GuiFlags.Suspended|GuiFlags.InMenu)
    and dword [MainWindow+GuiObj.Flags],~GuiObj.ContainerFocus
    ;call .GetExclusiveColors
    jmp short .SetFocus
.LoseFocus:
    mov eax,Msg.KeyOut|KeyMsgFlags.WindowInOut
    or dword [GuiFlags],GuiFlags.Suspended
    or dword [MainWindow+GuiObj.Flags],GuiObj.ContainerFocus
    ;api SetSystemPaletteUse, [hdc],SYSPAL_STATIC
.SetFocus:
    test dword [GuiFlags],GuiFlags.Active
    jz .InactiveFocus
    push dword MainWindow, eax, esi,edi,ebx
    call SetItemFocus.OfActive
    mov eax,[esp+4]
    call SetKeyFocus.OfActive
    pop edx, eax,esi,edi,ebx
.InactiveFocus:
    xor eax,eax
    ret 16

.ThreadPaint:
    sub esp,byte 12             ;dummy stack adjustment
    push dword [msg+MSG.hwnd]
    push dword Main.NextMsg
.Paint:
    push esi,edi,ebx
    call Main.Redraw            ;combine any required redrawing into this
    api BeginPaint, [hwnd],ps
    ;api BeginPaint, [esp+.hwnd+16],ps
    call TransferScreen
    api EndPaint, [hwnd],ps
    ;api EndPaint, [esp+.hwnd+16],ps
    pop esi,edi,ebx
    xor eax,eax
    ret 16

.CaptureChanged:
    mov edx,[esp+.lParam]       ;get window handle with mouse capture
    xor eax,eax                 ;return FALSE
    cmp [hwnd],edx
    je .CaptureSame
    mov [Mouse.hwnd],eax
.CaptureSame:
    ret 16

.FileDropped:
    push ebx,esi,edi

    ; ask whether to save settings
    ; save if requested

    api DragQueryFile, [esp+.wParam+12+12],0, SpcFileName,MAX_PATH
    api DragFinish, [esp+.wParam+12]

    call LoadSpcState
    jc near .FileDropError

   %if PlayThreaded
    api EnterCriticalSection, DspCriticalSection
   %endif

    ; turn off all playing voices
    call StopSounds

    ; reset time, play speed, voices
    mov [PlayTime],dword 0      ;reset time
    mov [PlayTimeStart],dword 0
    mov [PlayLoopStart],dword 0 ;reset loop
    mov [PlayLoopFinish],dword -1
    mov dword [PlayAdvance],TicksPerFrame
    mov dword [PlaySpeed],TicksPerFrame
    mov dword [EnabledVoices],255;enable all voices

    ; reinitialize DSP/SPC/samples
    call SpcEmu.Reinit          ;copy RAM, registers, set timers
    call DspEmu.Reinit          ;clear brr sample table, flag all samples as unused
    call LocalSamplesInfo
    call MatchLocalSamples
    call DspSim.Reinit          ;initialize DSP simulation structures and enable at least one type of sound output

   %if PlayThreaded
    api LeaveCriticalSection, DspCriticalSection
   %endif

    ; resume in case emulation stopped (reached end of buffer)
    or dword [PlayOptions],PlayOptions.Emulate
    and dword [PlayOptions],~(PlayOptions.Suspend|PlayOptions.Stop)

.FileDropError:
    pop ebx,esi,edi
    xor eax,eax
    ret 16

	unlocals

%else
;=============================================================================
; WINDOWS CONSOLE MAIN
;=============================================================================

Main:
    ; defeat Window's on demand page loading, so bits and pieces aren't read
    mov esi,CodeStart
    mov ecx,TextEnd
    sub ecx,esi                 ;TextEnd-CodeStart = total page bytes
    shr ecx,12                  ;/4096 = total pages
.NextPage:
    mov eax,[esi]               ;force page fault
    add esi,4096                ;next 4k page
    dec ecx
    jg .NextPage

    ; get I/O handles and display title
    api SetConsoleTitle, Program.Title
    api GetStdHandle, STD_OUTPUT_HANDLE
    test eax,eax
    js near .Terminate
    mov [hout],eax
    push dword FALSE            ;cursor invisible
    push dword 1                ;dummy size percentage
    api SetConsoleCursorInfo, eax, esp
    add esp,byte 8              ;free PCONSOLE_CURSOR_INFO
    ;api SetConsoleTextAttribute, [hout],FOREGROUND_GREEN
    api GetStdHandle, STD_INPUT_HANDLE
    test eax,eax
    js near .Terminate
    mov [hin],eax
    api SetConsoleMode, eax,ENABLE_PROCESSED_INPUT
    mov edx,Text.FullTitle
    call WriteString

    ; Console handler does not do any good!?
    ;api SetConsoleCtrlHandler, ConsoleHandler, TRUE

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; Check command line parameters
    call CheckStartParams
    jc .TerminateWithMsg
    test dword [PlayOptions],PlayOptions.FileGiven
    mov edx,Text.About
    jz .TerminateWithMsg        ;no file was given
    call LoadSpcState
    jnc .FileLoaded             ;end program and print error message
.TerminateWithMsg:              ; (edx=message text ptr)
    call WriteString.WithEol
    api ReadConsole, [hin],dummy, 1,dummy, NULL
    jmp [ExitProcess]
.FileLoaded:
    and dword [PlayOptions],~PlayOptions.Stop
    or dword [PlayOptions],PlayOptions.Emulate

    ; load configuration file...
    call DspEmu.Init            ;clear brr sample table, flag all samples as unused
    call LoadMainSettings

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; initialize core
    call SpcEmu.Init            ;copy RAM, registers, set timers
    call DspEmu.Reinit          ;clear brr sample table, flag all samples as unused
    call LocalSamplesInfo
    call MatchLocalSamples

    ; export brr info/wave if desired
    test dword [PlayOptions],PlayOptions.ShowInfo|PlayOptions.DumpBrr
    jz .PlayNormal
    test dword [PlayOptions],PlayOptions.ShowInfo
    jz .NoInfo
    call DumpBrrBuffer.Info
.NoInfo:
    test dword [PlayOptions],PlayOptions.DumpBrr
    jz .NoDump
    call DumpBrrBuffer
.NoDump:
    jmp [ExitProcess]
.PlayNormal:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; initialize audio output
    call InitDaSound.IfEnabled  ;open digital audio (for wave samples)
    call InitFmSound.IfEnabled  ;open FM audio device
    call InitMpu.IfEnabled      ;open MIDI port output
    call InitGm.IfEnabled       ;initialize internal synthesizer
    call DspSim.Init            ;initialize DSP simulation structures and enable at least one type of sound output, expand 128 MIDI notes into 22k pitch table
    call OutputMidiFile.StartIfEnabled

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    call PlayThread.Init
    call MainConLoop
    call PlayThread.Release

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    call OutputMidiFile.Stop
    call InitGm.Release
    call InitMpu.Release
    call InitFmSound.Release
    call InitDaSound.Release

.Terminate:
    extern ExitProcess
    jmp [ExitProcess]
    ;ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ConsoleHandler:
;    debugpause "terminating consoloe"
;    api ExitProcess;, 0

%endif


%else
;=============================================================================
; DOS GUI/CONSOLE MAIN
;=============================================================================

Main:

    ; store important program variables
    mov [Program.Env],ebp           ;and command environment strings
    mov dword [Program.PspSelector],es
    mov dword [Program.DataSelector],ds
    mov ax,0400h                    ;get DPMI version
    int 31h
    mov [Program.PicBaseMaster],dh  ;interrupt chip base virtualization
    mov [Program.PicBaseSlave],dl   ;they are probably always 08h and 70h
    push ds
    pop es
    ;mov [Regs.sp],dword 0           ; tell DPMI host to provide stack
    ;mov [Regs.ss],word 0

    ; disable cursor and display title
    ;mov ax,1112h               ;ah=set character font, al=8x8
    ;xor bx,bx                  ;table 0
    ;int 10h                    ;Video BIOS call (set screen 80x50)
    mov ah,1                    ;set cursor type
    mov ecx,2000h               ;turn off cursor for faster disassembly
    int 10h                     ;Video BIOS call
    mov edx,Text.FullTitle
    call WriteString

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; check command line parameters
    call CheckStartParams
    jc .TerminateWithMsg
    test dword [PlayOptions],PlayOptions.FileGiven
    jnz .LoadFile
  %ifdef GuiVer
    test dword [PlayOptions],PlayOptions.ConOnly
    jz .ParamsOk
  %endif
    mov edx,Text.About
.TerminateWithMsg:              ; (edx=message text ptr)
    call WriteString.WithEol
    mov ah,1                    ;set cursor type
    mov ecx,0708h               ;turn on cursor
    int 10h
    mov eax,4C01h               ;die
	int 21h
.LoadFile:
    call LoadSpcState
    jc .TerminateWithMsg        ;end program and print error message
    and dword [PlayOptions],~PlayOptions.Stop
    or dword [PlayOptions],PlayOptions.Emulate
.ParamsOk:

    ; load configuration file...
    call DspEmu.Init            ;clear brr sample table, flag all samples as unused
    call LoadMainSettings

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; initialize core
    call SpcEmu.Init            ;copy RAM, registers, set timers
    call DspEmu.Reinit          ;clear brr sample table, flag all samples as unused, expand 128 MIDI notes into 22k pitch table
    call LocalSamplesInfo
    call MatchLocalSamples

    ; export brr info/wave if desired
    test dword [PlayOptions],PlayOptions.ShowInfo|PlayOptions.DumpBrr
    jz .PlayNormal
    test dword [PlayOptions],PlayOptions.ShowInfo
    jz .NoInfo
    call DumpBrrBuffer.Info
.NoInfo:
    test dword [PlayOptions],PlayOptions.DumpBrr
    jz .NoDump
    call DumpBrrBuffer
.NoDump:
    jmp .Terminate
.PlayNormal:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; initialize audio outputs, then init DSP simulation
    call GetBlasterVars
    call InitDaSound.IfEnabled  ;initialize digital audio (for wave samples)
    call InitFmSound.IfEnabled  ;initialize waveform select, disable rhythm mode
    call InitMpu.IfEnabled      ;initialize MIDI port output
    call InitDmaTransfer
    call DspSim.Init            ;initialize DSP simulation structures and enable at least one type of sound output
    call OutputMidiFile.StartIfEnabled

    call TimerHandler.Init      ;hook timer interrupt for sound
%ifdef ConVer
    call MainConLoop
%elifdef GuiVer
    push dword .StopPlay
    test dword [PlayOptions],PlayOptions.ConOnly
    jnz near MainConLoop

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    push dword MainWindow       ;window data structure
    InitGfx
    InitGui
    and dword [PlayOptions],~PlayOptions.Suspend

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.NextMsg:
.GetKey:
    call GetKeyboardMsg
    jc near .NoKeyMsg           ;return value is irrelevant if cf set
    cmp ah,VK_F12;ESCAPE            ;quit?
    je near .Quit

    ;push dword MainWindow      ;window data structure
    call SendKeyMsg             ;send keypress to active window
    ;lea esp,[esp+byte 4]
    jnc .GetKey

    mov eax,[Keyboard.LastMsg]  ;access character and scancode
    ;if ALT key, focus on menu

    cmp al,Msg.KeyPress
    jne .GetKey                 ;ignore releases

    mov esi,WindowCode.TabKeys
    call ScanForKey
    jc .NotTab
    mov eax,[WindowCode.TabMsgsTbl+ecx*4]
    ;push dword 0               ;pass on dummy index
    ;push dword MainWindow      ;window data structure
    call SetItemFocus           ;set active focus
    ;add esp,byte 8
    jmp short .GetKey
.NotTab:

    mov esi,.ControlKeys
    call ScanForKey
    jc .GetKey
    push dword .GetKey
    jmp [.ControlKeyJtbl+ecx*4]

.NoKeyMsg:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.GetMouse:
    call GetMouseMsg            ;press/release/move
    jc .NoMouseChange

    push dword [Cursor.Col]
    push dword [Cursor.Row]
    push dword MainWindow       ;send mouse message to window cursor is over or window which grabbed focus
    call SendMouseMsg           ;click/move/enter/exit
    add esp,byte 12
.NoMouseChange:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Emulate as needed
.NextEmuRun:
    ;test dword [PlayOptions],PlayOptions.Emulate
    ;jz .NoEmu
    mov eax,CyclesPerFrame      ;for normal playing (~1/30 second cycles)
    call SpcEmu.Start
    btr dword [DspFlags],DspFlags.NewVoiceBit
    jnc .NoNewVoices
    ;call MatchBrrSamples.New
.NoNewVoices:

    ; if emu-dsp > 1 minute || buffer full, then stop emulation
    mov eax,[SpcEmu.TotalTime]
    sub eax,[DspBufferTime]
    cmp eax,60*TicksPerSecond
    jae .StopEmu
    cmp dword [DspBufferEnd],DspBufferSize    ;stop emulation if buffer full
    jb .EmuDone
.StopEmu:
    and dword [PlayOptions],~PlayOptions.Emulate
.NoEmu:
    hlt
.EmuDone:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Update miscellaneous
    btr dword [PlayOptions],PlayOptions.InterruptedBit
    jnc .NoUpdate

    ; loop play if necessary
    test dword [PlayOptions],PlayOptions.Stop|PlayOptions.Pause
    jnz .NoLoop
    mov eax,[PlayTime]
    cmp [PlayLoopFinish],eax
    ja .NoLoop
    mov eax,[PlayLoopStart]
    mov [PlayTime],eax
.NoLoop:

    test dword [PlayOptions],PlayOptions.MidiLog
    jz .NoMidiOutput
    call OutputMidiFile
.NoMidiOutput:

    test dword [PlayOptions],PlayOptions.Pause|PlayOptions.Stop|PlayOptions.Suspend
    jnz .NoVisual
    call [SongView.Handler]
    mov ebx,vwSongDisplay
    call SendContainerRedraw.Partial
.NoVisual:

  %if PlayThreaded=0
    call PlaySounds
  %endif

.NoUpdate:
    mov [PlayStall],dword 0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    call SendTimeMsgs

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; tell any items that need to redraw themselves to do it now

.Redraw:
    test byte [Display.RedrawFlags],Display.RedrawItems|Display.RedrawCursor|Display.RedrawPalette|Display.CursorMoved
    jz .NoRedraw

    call HideCursor
    test byte [Display.RedrawFlags],Display.RedrawItems
    jz .RedrawCursor

    call SaveDisplayVars        ;save main window's display vars
    push dword MainWindow
    call SendRedrawComplex      ;redraw all main items, cascading down to each contained item
    pop ebx                     ;discard window ptr
    and dword [MainWindow+GuiObj.Flags],~GuiObj.Redraw
    call RestoreDisplayVars     ;restore main window's display vars

.RedrawCursor:
    call DrawCursor
  %ifdef UseDisplayBuffer
    call TransferScreen
  %endif
    and byte [Display.RedrawFlags],~(Display.RedrawItems|Display.RedrawCursor|Display.RedrawPalette|Display.CursorMoved)
.NoRedraw:

    test dword [GuiFlags],GuiFlags.Active
    jnz near .NextMsg

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Quit:
    push dword MainWindow       ;window data structure (redundant push)
    DeinitGui
    DeinitGfx
    mov edx,Text.FullTitle
    call WriteString

%endif
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.StopPlay:
    call TimerHandler.Release

    ;mov eax,3                   ;restore text mode
    ;int 10h
    ;mov ax,1112h                ;ah=set character font, al=8x8
    ;xor bx,bx                   ;table 0
    ;int 10h                     ;Video BIOS call (set screen 80x50)

    call OutputMidiFile.Stop
    call InitDmaTransfer.Stop
    call InitMpu.Release
    call InitFmSound.Release
    call InitDaSound.Release

    ; save configuration file...

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Terminate:
    mov ah,1                   ;set cursor type
    mov ecx,0708h              ;turn on cursor
    int 10h

    mov eax,4C00h
	int 21h

%endif


; Used by both DOS/Win GUI versions
%ifdef GuiVer
section data
align 4,db 0
Main.ControlKeyJtbl:
    dd MainCommand.Nada
    dd MainCommand.Nada
    dd MainCommand.Restart
    dd MainCommand.Play
    dd MainCommand.Still
    dd MainCommand.Pause
    dd MainCommand.Stop
    dd Main.Quit
Main.ControlKeys:
    db 0,VK_F9
    db 0,VK_F10
    db 6,VK_F5,     0,VK_SHIFT
    db 4,VK_F5
    db 6,VK_F6,     0,VK_SHIFT
    db 4,VK_F6
    db 4,VK_F8
    db 4,VK_ESCAPE
    db -1
section code
%endif


;=============================================================================
; WINDOWS/DOS CONSOLE LOOP
;=============================================================================
; do
;   if CyclesEmulated < CyclesToEmulate then
;     emulate for short time
;     update window if changed
;   endif
;   check keypresses and act on them
; loop
;
; note the sound is played in the interrupt or secondary thread
;
MainConLoop:
    test dword [PlayOptions],PlayOptions.Disassemble
    jnz .NoShowKeys
    mov edx,Text.Keys
    call WriteString
.NoShowKeys:
    and dword [PlayOptions],~PlayOptions.Suspend

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Emulate as needed
.NextEmuRun:
    test dword [PlayOptions],PlayOptions.Emulate
    jz .NoEmu
    ;and dword [PlayOptions],~PlayOptions.Emulate;****

    test dword [PlayOptions],PlayOptions.Disassemble
    jnz .Disassemble
    mov eax,CyclesPerFrame      ;for normal playing (~1/30 second cycles)
    call SpcEmu.Start
    jmp short .ValidateVoice
.Disassemble:
    mov eax,500                 ;smaller value for disassembly
    call SpcEmu.DisAsm
.ValidateVoice:
    btr dword [DspFlags],DspFlags.NewVoiceBit
    jnc .NoNewVoices
    ;call MatchBrrSamples.New
.NoNewVoices:

    ; if emu-dsp > 1 minute || buffer full, then stop emulation
    mov eax,[SpcEmu.TotalTime]
    sub eax,[DspBufferTime]
    cmp eax,60*TicksPerSecond
    jae .StopEmu
    cmp dword [DspBufferEnd],DspBufferSize    ;stop emulation if buffer full
    jb .MoreEmu
.StopEmu:
    and dword [PlayOptions],~PlayOptions.Emulate
.NoEmu:
  %ifdef WinVer
    api WaitForSingleObject, [hin],-1
  %elifdef DosVer
    ;hlt
    ;Win2k hates this multitasking, energy saving instruction!?@#
    ;Works great on Win95/98 reducing the CPU usage (on my PC anyway) from
    ;100% to only 12% (P133) and 3.5% (PII350)
    ;Lame 2k/XP
  %endif
.MoreEmu:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Update miscellaneous
    btr dword [PlayOptions],PlayOptions.InterruptedBit
    jnc .NoUpdate

    ;or dword [PlayOptions],PlayOptions.Emulate;****

    test dword [PlayOptions],PlayOptions.MidiLog
    jz .NoMidiOutput
    call OutputMidiFile
.NoMidiOutput:

  %ifdef debug
    ;call PrintDebugInfo
  %endif

  %if 0 ;timer display disabled
    mov eax,[PlayTime]
    mov esi,Text.CurTime
    call .TimeToString
    mov eax,[DspBufferTime]
    mov esi,Text.CurTime+13
    call .TimeToString
    mov edx,Text.CurTime
    call WriteString
  %endif

  %if PlayThreaded=0
    call PlaySounds
  %endif

.NoUpdate:
    mov [PlayStall],dword 0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Check keyspresses
    ; the key processing code below is presently an innefficient nightmare

.CheckInput:
  %ifdef WinVer
    push eax
    api GetNumberOfConsoleInputEvents, [hin],esp
    pop eax
    test eax,eax
    jz near .NextEmuRun
    api ReadConsoleInput, [hin],.InputRecord, 1,dummy
    cmp word [.InputRecord+INPUT_RECORD.EventType],KEY_EVENT
    jne near .CheckInput
    cmp dword [.InputRecordEvent+KEY_EVENT_RECORD.bKeyDown],TRUE
    jne near .CheckInput
    ;debugwrite "keydown=%X repeat=%d keycode=%X scan=%X char=%X ctrl=%X",[.InputRecordEvent+KEY_EVENT_RECORD.bKeyDown], [.InputRecordEvent+KEY_EVENT_RECORD.wRepeatCount], [.InputRecordEvent+KEY_EVENT_RECORD.wVirtualKeyCode], [.InputRecordEvent+KEY_EVENT_RECORD.wVirtualScanCode], [.InputRecordEvent+KEY_EVENT_RECORD.uChar], [.InputRecordEvent+KEY_EVENT_RECORD.dwControlKeyState]
    mov al,[.InputRecordEvent+KEY_EVENT_RECORD.uChar]
    mov ah,[.InputRecordEvent+KEY_EVENT_RECORD.wVirtualKeyCode]
  %elifdef DosVer
	mov ah,1
	int 16h
    jz near .NextEmuRun
    xor eax,eax
    int 16h
  %endif

    push dword .CheckInput
  %ifdef WinVer
    cmp ax,VK_RIGHT<<8
    mov ecx,TicksPerSecond
    je near .IncPos
    cmp ax,VK_LEFT<<8
    je near .DecPos
  %elifdef DosVer
    cmp ax,'M'<<8
    mov ecx,TicksPerSecond
    je near .IncPos
    cmp ax,'K'<<8
    je near .DecPos
  %endif
    cmp al,','
    mov ecx,TicksPerFrame
    je near .DecPos
    cmp al,'.'
    je near .IncPos
    cmp al,'9'
    ja .NotChannel
    je near .AllVoicesOn
    cmp al,'0'
    je near .AllVoicesOff
    ja near .ToggleVoice
.NotChannel:
  %ifdef WinVer
    cmp ax,VK_UP<<8
    mov ebx,1
    je near .IncSample
    cmp ax,VK_DOWN<<8
    je near .DecSample
  %elifdef DosVer
    cmp ax,'H'<<8
    mov ebx,1
    je near .IncSample
    cmp ax,'P'<<8
    je near .DecSample
  %endif
    cmp al,' '
    je near .TogglePause
    cmp al,8
    je near .Reverse
  %ifdef WinVer
    cmp ax,VK_HOME<<8
    je near .Restart
    cmp ax,VK_END<<8
    je near .SeekEnd
  %elifdef DosVer
    cmp ax,'G'<<8
    je near .Restart
    cmp ax,'O'<<8
    je near .SeekEnd
  %endif
    cmp al,'p'
    je near .TogglePitchSlide
    cmp al,'+'
    mov ecx,[PlaySpeed]
    je near .IncSpeed
    cmp al,'-'
    je near .DecSpeed
    cmp al,'f'
    je near .ToggleFm
    cmp al,'a'
    je near .ToggleAs
    cmp al,'d'
    je near .ToggleDls
    cmp al,'s'
    je near .ToggleSine
    cmp al,'g'
    je near .ToggleGm
    cmp al,'h'
    je near .ToggleMpu
    cmp al,'t'
    je near .ToggleTune
  %ifdef WinVer
    cmp ax,VK_F5<<8
    je near .Play
    cmp ax,VK_F6<<8
    je near .Pause
    cmp ax,VK_F8<<8
    je near .Stop
  %elifdef DosVer
    cmp ax,'?'<<8
    je near .Play
    cmp ax,'@'<<8
    je near .Pause
    cmp ax,'B'<<8
    je near .Stop
  %endif
    cmp al,'e'
    je near .EnableEmu
    cmp al,'i'
    je near .Info
    cmp al,27                   ;Escape pressed?
    jne .NotEscape
    pop eax                     ;discard return address if ending
.NotEscape:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.DecPos:
    neg ecx
.IncPos:
    add ecx,[PlayTime]
    jns .PosOk
    xor ecx,ecx
.PosOk:
    mov [PlayTime],ecx
    ret

.ToggleVoice:
    movzx eax,al
    sub eax,byte '1'
    btc [EnabledVoices],eax
    ret
.AllVoicesOff:
    mov byte [EnabledVoices],0
    ret
.AllVoicesOn:
    mov byte [EnabledVoices],255
    ret

.DecSample:
    neg ebx
.IncSample:
    add ebx,[SelectedSample]
    and ebx,GlobalSample.Max-1
    mov [SelectedSample],ebx
    and dword [PlayOptions],~PlayOptions.Sample
    bt dword [GlobalSample.Used],ebx
    jnc .SampleInvalid
    mov esi,ebx
    call SampleEmu.Start
.SampleInvalid:
    ret

.Info:
    call LocalSamplesInfo
    call MatchLocalSamples
    jmp DumpBrrBuffer.Info
    ;ret

.Reverse:
    neg dword [PlayAdvance]
    neg dword [PlaySpeed]
    ret

.Restart:
    mov [PlayTime],dword 0      ;reset time
    mov [PlayTimeStart],dword 0 ;reset time
    mov dword [PlayAdvance],TicksPerFrame
    mov dword [PlaySpeed],TicksPerFrame
    ret

.SeekEnd:
    mov eax,[DspBufferTime]
    mov [PlayTime],eax
    ret

.IncSpeed:
    add ecx,TicksPerSecond/(30*27)
    jz .ChangeSpeed
    jnc short .ChangeSpeed
    ret
.DecSpeed:
    sub ecx,TicksPerSecond/(30*27)
    jc .NotDecSpeed
.ChangeSpeed:
    mov [PlayAdvance],ecx
    mov [PlaySpeed],ecx
.NotDecSpeed:
    ret

.ToggleTune:
    xor byte [PlayOptions],PlayOptions.TuningWave
    test byte [PlayOptions],PlayOptions.TuningWave
    jz .TuneOff
    call GenerateSineWave.Start
    test byte [SoundFlags],SoundFlags.Da
    jz .EnableAudio
.TuneOff:
    ret

.ToggleAs:
    xor byte [PlayOptions],PlayOptions.AsVoices
    test byte [SoundFlags],SoundFlags.Da
    jz .EnableAudio
    ret

.ToggleDls:
    xor byte [PlayOptions],PlayOptions.DlsVoices
    test byte [SoundFlags],SoundFlags.Da
    jz .EnableAudio
    ret

.ToggleSine:
    xor byte [PlayOptions],PlayOptions.SineVoices
    test byte [SoundFlags],SoundFlags.Da
    jz .EnableAudio
    ret

.EnableAudio:
  %ifdef WinVer
    jmp InitDaSound
  %elifdef DosVer
    call InitDaSound
    jmp InitDmaTransfer
  %endif

.ToggleFm:
    test byte [SoundFlags],SoundFlags.Fm
    jz .EnableFm
    mov ebx,PlayOptions.FmVoices
    mov esi,FmEmu.Given
    mov edi,FmSongPos
    jmp short .ToggleMidiSound
.EnableFm:
    or byte [PlayOptions],PlayOptions.FmVoices
    jmp InitFmSound

%ifdef WinVer
.ToggleGm:
    test byte [SoundFlags],SoundFlags.Gm
    jz .EnableGm
    mov ebx,PlayOptions.GmVoices
    mov esi,GmEmu.Given
    mov edi,GmSongPos
    jmp short .ToggleMidiSound
.EnableGm:
    or byte [PlayOptions],PlayOptions.GmVoices
    jmp InitGm
%endif

.EnableMpu:
    or byte [PlayOptions],PlayOptions.MpuVoices
    jmp InitMpu
.ToggleMpu:
%ifdef DosVer
.ToggleGm:
%endif
    test byte [SoundFlags],SoundFlags.Mpu
    jz .EnableMpu
    mov ebx,PlayOptions.MpuVoices
    mov esi,MpuEmu.Given
    mov edi,MpuSongPos
    ;jmp short .ToggleMidiSound

.ToggleMidiSound:
    xor dword [PlayOptions],ebx
    test dword [PlayOptions],ebx
    jnz .ToggledOn
  %ifdef WinVer
   %if PlayThreaded
    ; simply synchronize if necessary
    api EnterCriticalSection, DspCriticalSection
    api LeaveCriticalSection, DspCriticalSection
   %endif
  %endif
    mov al,[edi+SongPos.Heard]
    shl eax,24
    xchg [edi+SongPos.Active],ah ;swap zero for active voices
    mov [edi+SongPos.Changed],eax
    call esi
.ToggledOn:
    ret

.TogglePause:
    test dword [PlayOptions],PlayOptions.Pause
    jnz .Play
.Pause:
    or dword [PlayOptions],PlayOptions.Pause|PlayOptions.Emulate
    and dword [PlayOptions],~PlayOptions.Sample
    jmp SilenceSounds
    ;ret
.Play:
    and dword [PlayOptions],~(PlayOptions.Pause|PlayOptions.Stop)
    or dword [PlayOptions],PlayOptions.Emulate
    ret

.Stop:
    or dword [PlayOptions],PlayOptions.Stop
    and dword [PlayOptions],~PlayOptions.Emulate
    jmp StopSounds
    ;ret

.TogglePitchSlide:
    xor dword [DspFlags],DspFlags.PitchSlide
    ret

.EnableEmu:
    or dword [PlayOptions],PlayOptions.Emulate
    ret

.TimeToString:
    mov byte [NumToString.FillChar],'0'

    mov ebx,TicksPerSecond      ;~64000 ticks per second
    xor edx,edx
    div ebx
    lea edi,[esi+7]
    mov ecx,3
    push eax
    mov eax,edx
    shr eax,6                   ;/64
    call NumToString.UseDLen

    mov ebx,60                  ;seconds
    pop eax
    xor edx,edx
    div ebx
    lea edi,[esi+4]
    mov ecx,2
    push eax
    mov eax,edx
    call NumToString.UseDLen

    pop eax                     ;minutes
    mov edi,esi
    mov ecx,3
    call NumToString.UseDLen

    ret

%ifdef WinVer
section bss
.InputRecord:   resb INPUT_RECORD_size
.InputRecordEvent equ .InputRecord+INPUT_RECORD.Event
section code
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Checks the command line parameters and sets options accordingly.
; Can return text with error.
; Does not directly end the program, but returns carry to tell the caller to
; end it.
;
; () (cf=error, edx=error message)
CheckStartParams:
    push ebp
    mov ebp,esp

%ifdef DosVer
    mov eax,0006h               ;get segment base address
    mov bx,[Program.PspSelector]
    int 31h
    mov esi,ecx
    shl esi,16
    mov si,dx                   ;CX:DX = 32-bit linear base address of segment


    movzx ecx,byte [esi+80h]
    add esi,81h
%else
    api GetCommandLine
    mov esi,eax
    call .GetWordLen
    mov esi,ebx
    call GetStringLength
    ;debugpause "command line = %s length = %d",esi,ecx
%endif

    add ecx,esi
    mov [.EndPtr],ecx
    call .GetNextParam          ;skip any initial space
.NextParam:
    jae .End                    ;cf=0
    push dword .NextParam
    push dword .CheckNextParam
    cmp byte [esi],'/'          ;is it an DOS switch?
    je .Option
    cmp byte [esi],'-'          ;is it an Unix switch?
    jne near .NonSwitchParam    ;if not, assume it might be a filename
.Option:
    mov ebx,.List
    inc esi                     ;skip '/'
    call .MatchWord
    mov edx,Text.InvalidParameter
    jc .End
    jmp dword [.Jtbl+eax*4]
; (edx=error message ptr)
.Err:
    stc
; (edx=error message ptr if carry set)
.End:
    mov esp,ebp
    pop ebp
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Verifies the next parameter is separated properly by either a space, slash,
; null, or some other valid character.
; If all is okay, it will skip any separating space and return the new ptr.
; If there is an error in the parameter line, this routine will NOT return,
; but instead abort with an error message.
; (esi=param char ptr) (esi=new ptr)
.CheckNextParam:
    movzx eax,byte [esi]
    bt dword [.SepChars],eax
    mov edx,Text.InvalidParameter ;just in case invalid parameter
    jc .End                     ;cf=1

; skip any separating space and return the new ptr
; (esi=param char ptr) (esi=new ptr, ae=past end; *)
.GetNextParam:
    dec esi
.SkipSpace:
    inc esi
    cmp byte [esi],' '
    je .SkipSpace
    cmp esi,[.EndPtr]
    ;jae .End                    ;cf=0
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Searches through a string list for given text and returns matching index.
; Mainly used to match switch parameters, but can actually be used for any.
; (esi=search text, ebx=string list) (cf=error no match, eax=index)
.MatchWord:
    xor eax,eax                 ;start with first word in string list
    xor ecx,ecx
    ;cld
    jmp short .MwFirstCompare
.MwNextCompare:
    mov edx,ecx                 ;copy word length
    mov edi,ebx                 ;set to word in list for comparison
    rep cmpsb
    je .MwMatch                 ;word matched (cf=0)
    add esi,ecx                 ;compensate for change in esi after search
    add ebx,edx                 ;advance next string in list
    inc eax                     ;next word in list
    sub esi,edx
.MwFirstCompare:
    mov cl,[ebx]                ;get of length compare string
    inc ebx                     ;skip length byte to first character
    test ecx,ecx
    jnz .MwNextCompare          ;continue until word length = 0
    stc                         ;no words left, none matched
.MwMatch:                       ;match from above (cf=0)
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Determines length of word, up to next space, or within quotes.
; Mainly used to get filename, but can also be used for words following
; parameters.
; (esi=char ptr) (ecx=char length, ebx=ptr to following char; esi)
.GetWordLen:
    xor ecx,ecx
    cmp byte [esi],'"'
    mov ah,' '
    jne .GwlUnquoted
    inc esi
    mov ah,'"'
.GwlUnquoted:
    mov ebx,esi                 ;copy parameter char ptr
.GwlNext:
    mov al,[ebx]                ;get char
    test al,al                  ;is null? for when in Windows or Wudebug
    jz .GwlEnd
  %ifdef DosVer
    cmp al,13                   ;for when normal command line start
    je .GwlEnd
  %endif
    cmp al,ah                   ;is space or ending quote
    je .GwlEnd
    inc ebx
    inc ecx                     ;count another character in word
    jmp short .GwlNext
.GwlEnd:
    cmp al,'"'
    jne .GwlNoLastQuote
    inc ebx                     ;skip closing quote
.GwlNoLastQuote:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns a number from the current parameter, adjusted char ptr to the
; character immediately after the last number.
; If the number is missing, this routine will NOT return, but instead abort
; with an error message.
; (esi=ptr to number)
; (eax=value, esi=first character after number)
.GetNumber:
    mov ebx,10                  ;default is decimal numbers
; (ebx=alternate radix)
.GetNumberOfRadix:
    call .GetNextParam          ;skip any initial space
    mov edx,Text.MissingParameter ;set message in case error
    jae near .Err
    movzx eax,byte [esi]
    bt dword [.SepChars],eax
    jnc near .Err               ;no number so end
    cmp al,'0'
    mov edx,Text.InvalidParameter ;just in case invalid parameter
    jb near .Err                ;not numeric so end
    cmp al,'9'
    ja near .Err                ;not numeric so end
    call StringToNum.UseRadix
    mov edx,Text.MissingParameter ;set message in case error
    jz near .Err                ;no number so end
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.NonSwitchParam:
    ;cld
    bts dword [PlayOptions],PlayOptions.FileGivenBit
    mov edx,Text.MultipleParameters
    jc near .Err
    call .GetWordLen
    mov edi,SpcFileName
    rep movsb
    mov byte [edi],0            ;put null on end of filename
    mov esi,ebx                 ;skip trailing " or space
    ret
.Help:
    call .CheckNextParam
    mov edx,Text.About
    jmp .Err
.SampleRate:
    call .GetNumber
    mov edx,Text.InvalidSampleRate  ;set message in case error
    cmp eax,Sound.MaxSampleRate
    ja near .Err
    cmp eax,Sound.MinSampleRate
    jb near .Err
    mov [Sound.SampleRate],eax
    mov [Sound.MixRate],eax
    mov [SoundDumpHeader.SampleRate],eax
    shl eax,1
    mov [SoundDumpHeader.SampleRate+4],eax
    ret
.MixRate:
    call .GetNumber
    mov edx,Text.InvalidMixingRate  ;set message in case error
    cmp eax,Sound.MaxMixRate
    ja near .Err
    cmp eax,Sound.MinMixRate
    jb near .Err
    mov [Sound.MixRate],eax
    ret
.Info:
    or dword [PlayOptions],PlayOptions.ShowInfo
    ret
.DumpBrr:
    or dword [PlayOptions],PlayOptions.DumpBrr
    ret
.8bit:
    or byte [SoundFlags],SoundFlags.Force8bit
    ret
.16bit:
    or byte [SoundFlags],SoundFlags.Supports16bit
    ret
.Fm:
    or byte [SoundFlags],SoundFlags.Fm
    or dword [PlayOptions],PlayOptions.FmVoices
    ret
.DefaultPatch:
    call .GetNumber
    dec eax
    cmp eax,127
    mov edx,Text.InvalidPatch
    ja near .Err
    mov [DefaultInstrument],al
    ;push esi
    ;call GetMidiPatchName       ;(esi=ptr to name, ecx=char length)
    ;mov edx,esi
    ;call WriteString.OfLength
    ;pop esi
    ret
.DefaultDrum:
    call .GetNumber
    dec eax
    cmp eax,127
    mov edx,Text.InvalidPatch
    ja near .Err
    mov [DefaultInstrument+1],al
    ret
.DefaultBank:
    call .GetNumber
    cmp eax,16383
    mov edx,Text.InvalidBank
    ja near .Err
    mov [DefaultInstrument+2],ax
    ret
.DefaultVolume:
    call .GetNumber
    mov [DefaultVolume],eax
    ret
.DefaultFreq:
    call .GetNumber
    cmp eax,MaxHertz
    mov edx,Text.InvalidFreq
    ja near .Err
    mov [DefaultFreq],eax
    ret
.As:
    or byte [SoundFlags],SoundFlags.Da
    or dword [PlayOptions],PlayOptions.AsVoices
    ret
.Sine:
    or byte [SoundFlags],SoundFlags.Da
    or dword [PlayOptions],PlayOptions.SineVoices
    ret
.Gm:
%ifdef WinVer
    or dword [SoundFlags],SoundFlags.Gm
    or dword [PlayOptions],PlayOptions.GmVoices
    ret
%endif
.Mpu:
    or byte [SoundFlags],SoundFlags.Mpu
    or dword [PlayOptions],PlayOptions.MpuVoices
    ret
.Dls:
    or byte [SoundFlags],SoundFlags.Da
    or dword [PlayOptions],PlayOptions.DlsVoices
    ret
.TuningWave:
    call .GetNumber
    cmp eax,MaxHertz
    mov edx,Text.InvalidTune
    ja near .Err
    mov [GenerateSineWave.Hertz],eax
    or dword [PlayOptions],PlayOptions.TuningWave
    jmp GenerateSineWave.Start
    ;ret
.NoFm:
    and byte [SoundFlags],~SoundFlags.Fm
    ret
.NoDa:
    and byte [SoundFlags],~SoundFlags.Da
    ret
.NoGm:
%ifdef WinVer
    and byte [SoundFlags],~SoundFlags.Gm
    ret
%endif
.NoMpu:
    and byte [SoundFlags],~SoundFlags.Mpu
    ret
.ConOnly:
    or dword [PlayOptions],PlayOptions.ConOnly
    ret
.Solo:
    call .GetNextParam          ;skip any initial space
    mov edx,Text.MissingParameter ;set message in case error
    jae near .Err               ;cf=0

    xor eax,eax
    xor ebx,ebx
.SoloNext:
    mov al,[esi]
    cmp al,'0'
    je .SoloSkip
    sub al,'1'
    jc .SoloEnd
    cmp al,8
    jae .SoloEnd
    bts ebx,eax
.SoloSkip:
    inc esi
    jmp short .SoloNext
.SoloEnd:
    and byte [EnabledVoices],bl
    ret
.Pause:
    or dword [PlayOptions],PlayOptions.Pause
    ret
.DisAsm:
    or dword [PlayOptions],PlayOptions.Disassemble
    ret
.Midi:
    or dword [PlayOptions],PlayOptions.MidiLog
    ret
.Slow:
    or dword [PlayOptions],PlayOptions.SlowPlay
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
align 4, db 0
.EndPtr:    dd 0
.SepChars:  ;characters that can separate parameters
    dd 11111111111111111101101111111110b  ;(control characters)
    dd 11111111111111110111111111111110b  ;?>=<;:9876543210/.-,+*)('&%$#"! 
    dd 11101111111111111111111111111111b  ;_^]\[ZYXWVUTSRQPONMLKJIHGFEDCBA@
    dd 11111111111111111111111111111111b  ;~}|{zyxwvutsrqponmlkjihgfedcba`
    dd 11111111111111111111111111111111b  ;Ÿœ›š™˜—–•”“’‘Œ‹Š‰ˆ‡†…„ƒ‚€
    dd 11111111111111111111111111111111b  ;¿¾½¼»º¹¸·¶µ´³²±°¯®­¬«ª©¨§¦¥¤£¢¡ 
    dd 11111111111111111111111111111111b  ;ßŞİÜÛÚÙØ×ÖÕÔÓÒÑĞÏÎÍÌËÊÉÈÇÆÅÄÃÂÁÀ
    dd 11111111111111111111111111111111b  ;ÿşıüûúùø÷öõôóòñğïîíìëêéèçæåäãâáà

.Jtbl:      ;jump table for parameters
    dd .Help
    dd .Help
    dd .DisAsm
    dd .SampleRate
    dd .SampleRate
    dd .Gm
    dd .Midi
    dd .Mpu
    dd .MixRate
    dd .MixRate
    dd .Info
    dd .DumpBrr
    dd .8bit
    dd .16bit
    dd .Fm
    dd .As
    dd .Sine
    dd .Dls
    dd .TuningWave
    dd .NoFm
    dd .NoDa
    dd .NoGm
    dd .NoMpu
    dd .ConOnly
    dd .DefaultPatch
    dd .DefaultDrum
    dd .DefaultBank
    dd .DefaultVolume
    dd .DefaultFreq
    dd .Solo
    dd .Pause
    dd .Slow
.List:      ;parameter word strings
    ;first byte is length of string
    ;following bytes are characters of parameter string (1-255)
    ;last length of list is zero
    db 1,"h"
    db 1,"?"
    db 3,"asm"
    db 4,"rate"
    db 1,"r"
    db 2,"gm"
    db 4,"midi"
    db 3,"mpu"
    db 3,"mix"
    db 1,"m"
    db 4,"info"
    db 4,"dbrr"
    db 1,"8"
    db 2,"16"
    db 2,"fm"
    db 2,"as"
    db 4,"sine"
    db 3,"dls"
    db 4,"tune"
    db 4,"nofm"
    db 4,"noda"
    db 4,"nogm"
    db 5,"nompu"
    db 3,"con"
    db 2,"dp"
    db 2,"dd"
    db 2,"db"
    db 2,"dv"
    db 2,"df"
    db 4,"solo"
    db 5,"pause"
    db 4,"slow"
    db 0
section code


%ifdef DosVer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; This is called upon interrupt 8 from the pc timer (30fps). If play time in
; the main loop lags too far behind, it's given a chance to catch up.
;
; I've tried my best to time this exactly to the speed of the real games, and
; must say it's quite precise (at least on my computer). Started the Zelda
; dark world music playing both on the SNES and computer, came back a few
; minutes later (microwaved my Ramen lunch), and Spc2Midi was only an
; acceptable 1/30 second behind.
;
; The routine will exit if any one of several conditions are true:
;   Play is untimed (either suspended or as fast as possible)
;   Emulation is behind real time
;   GUI loop has fallen behind and not acknowledged interrupts
;   File logging has not finished (so that previous wave data is not lost)
;
; //only if emulation is up to or ahead of realtime and main loop is not
; //lagging behind
; if (Timed
; && PlayTime - TickCount < MaxPlayLag
; && PlayTime + TicksPerFrame < TickTotal) then
;     PlayTime += TicksPerFrame
;     if (playing sounds) then
;         save all registers
;         read note buffer up to current time and play sounds
;         restore all registers
;     endif
; endif
; if InterruptAccum + ModRatio < 2^32 then
;     handle interrupt
; else
;     pass interrupt to BIOS and let it handle it
; endif
;
TimerHandler:
    push ds
    push es
    push eax
    mov ax,[cs:Program.DataSelector]
    mov ds,ax

  %ifdef GuiVer
    ; increment GUI time counter
    add dword [Timer.Now],byte 33;55
  %endif

    ; check for recursion or a main loop that is too slow
    bts dword [PlayOptions],PlayOptions.InInterruptBit
    jc near .NoChain
    or dword [PlayOptions],PlayOptions.Interrupted
    test dword [PlayOptions],PlayOptions.Suspend
    jnz .NoPlay

    ; check if main loop is behind (data may need to be logged to file first)
    cmp dword [PlayStall],MaxPlayLag
    ja .NoPlay
    mov es,ax
    inc dword [PlayStall]

    ; advance tick time
    test dword [PlayOptions],PlayOptions.Pause|PlayOptions.Stop
    jnz .NoTimerAdvance
    mov eax,[PlayTime]
    cmp [SpcEmu.TotalTime],eax  ;don't play faster than the emulation
    jb .NoTimerAdvance
    add eax,[PlayAdvance]       ;get next time frame
    jns .CheckTime
    jc .CheckTime
    xor eax,eax                 ;tick time went negative
    jmp short .TimeOk
.CheckTime:
    cmp [DspBufferTime],eax     ;can't play ahead of the buffer end
    jae .TimeOk
    mov eax,[DspBufferTime]
    inc eax
.TimeOk:
    mov [PlayTime],eax          ;advance time
.NoTimerAdvance:

  %if PlayThreaded
    sti                         ;enabled interrupts in case we take too long
    pusha
    call PlaySounds
    popa
  %endif

.NoPlay:
    and dword [PlayOptions],~PlayOptions.InInterrupt
    add dword [.IntAccum],(1193182/30)<<16 ;18.2 / 30 ratio
    jnc .NoChain                ;take care of int ourselves
    pop eax
    pop es
    pop ds
    jmp far [cs:.OldHandler]
.NoChain:
    mov al,60h                  ;acknowledge interrupt (IRQ0)
    out 20h,al
    pop eax
    pop es
    pop ds
    iret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Saves the old timer interrupt handler and set my new one.
.Init:
    ;save existing interrupt handler
    mov ax,0204h                ;get protected-mode interrupt
    mov bl,8                    ;timer interrupt
    int 31h
    mov [.OldHandler],edx       ;save offset
    mov [.OldHandler+4],ecx     ;save selector

    ;increase rate to more precise rate of 30hz rather than only 18.2
    ;mov cx,39772               ;1193182/30=39772.7 (1.1931817MHz / 30hz)
    ;mov ecx,1193182/10         ;temp hack for 10 times per second
    mov ecx,39600               ;this value syncs better with the real SNES
    call .SetPitRate

    mov edx,TimerHandler
;(edx=handler address)
.SetNewHandler:
    mov bl,8                    ;timer interrupt
    mov ax,0205h                ;set protected mode interrupt
    mov ecx,cs                  ;pass our code selector
    int 31h
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Release:
    ;restore old interrupt handler
    mov bl,8                    ;timer interrupt
    mov ax,0205h                ;set protected mode interrupt
    mov ecx,[.OldHandler+4]     ;get selector
    mov edx,[.OldHandler]       ;get offset
    int 31h

    ;restore default rate of 18.2065hz
    xor ecx,ecx
    call .SetPitRate
    ret

.SetPitRate:
    cli                 ;don't want any interrupt to mess this up below
    mov al,00110100b    ;(00:11:010:0) set counter 0, lsb/msb, mode 2, binary
    out 43h,al
    in al,61h           ;i/o delay
    mov al,cl
    out 40h,al          ;write counter low byte
    in al,61h           ;i/o delay
    mov al,ch
    out 40h,al          ;write counter high byte
    sti
    ret

section bss
alignb 4
.OldHandler:    resd 1
                resd 1
section data
align 4, db 0
.IntAccum:      dd 0        ;keeps track of when to chain to original int 8 handler
section code
%endif


%ifdef WinVer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; This high priority thread is responsible for incrementing timers and
; calling the function to play sounds. If the main loop lags too far behind,
; this thread bows down, giving its parent a chance to catch up.
;
; do
;   get system millisecond tick time
;   call playsounds
; loop until termination
;
; () ()
PlayThread:

.PeriodTime     equ 33          ;-= 1000/30
.MinSleepTime   equ 8

    api timeGetTime
    mov [.Tick],eax
    jmp .Resume

.Top:
  %ifdef GuiVer
    ;test dword [GuiFlags],GuiFlags.Suspended
    ;jnz .NoPost
    api PostThreadMessage, [tid],WM_TIMER,1,0
;.NoPost:
  %endif
  %if 0
    api timeGetTime
    sub eax,[.Tick]             ;sleep time = now - previous time
    debugwrite "time dif=%d",eax
  %endif

    test dword [PlayOptions],PlayOptions.Pause|PlayOptions.Stop
    jnz .Paused
    mov eax,[PlayTime]
    add eax,[PlayAdvance]       ;get next time frame
    jns .TimeForward
    xor eax,eax                 ;zero to beginning
.TimeForward:
    ;cmp [DspBufferTime],eax    ;can't play ahead of the buffer end
    ;mov eax,[SpcEmu.TotalTime];can't play faster than emulation****
    cmp [SpcEmu.TotalTime],eax  ;can't play faster than emulation
    jb .BeyondEnd
    mov [PlayTime],eax          ;set next time frame
.BeyondEnd:
.Paused:

  %if PlayThreaded
    call PlaySounds
  %endif
.Suspended:

    ; advance period timer and sleep
    ; sleep exactly long enough to return at the right moment
.CalcSleep:
    or dword [PlayOptions],PlayOptions.Interrupted
    api timeGetTime
    sub eax,[.Tick]             ;sleep time = now - previous time
.NextInc:
    mov edx,.PeriodTime
    add dword [.IntAccum],0803311531 ;20/30 ratio = 2863311531/4294967296
    adc edx,0
    add [.Tick],edx
    sub eax,edx
    jg .NextInc                 ;loop in case fallen behind
    neg eax                     ;negative -> positive
    cmp eax,.MinSleepTime
    jge .Sleep
    mov eax,.MinSleepTime       ;must be a slow PC or sound gen took too long
.Sleep:
    api Sleep,eax
.Resume:
    test dword [PlayOptions],PlayOptions.Terminate|PlayOptions.Suspend
    jz near .Top
    test dword [PlayOptions],PlayOptions.Terminate
    jz .CalcSleep
    api ExitThread; ,0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Creates the thread for playing
.Init:
    mov esi,.StartingPlay
    call StatusMessage

    xor eax,eax
    api CreateThread, eax, eax, PlayThread,eax,CREATE_SUSPENDED, .Tid
    ; (assume it was created)
    mov [.Th],eax
    api SetThreadPriority, eax,THREAD_PRIORITY_TIME_CRITICAL;THREAD_PRIORITY_HIGHEST
  %if PlayHighPriority
    api GetCurrentProcess
    api SetProcessPriority, eax,HIGH_PRIORITY_CLASS ;(so others don't mess up playing)
    api GetCurrentThread
    api SetThreadPriority,eax,THREAD_PRIORITY_LOWEST
  %endif
    api timeBeginPeriod, 1
    api ResumeThread, [.Th]
    ;api 
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Does not destory the thread directly, rather flags it to destroy itself.
; Then waits on thread to die. If it does NOT die (perhaps an infinite loop
; somehow), the thread will be killed.
.Release:
    mov esi,.StoppingPlay
    call StatusMessage

    or dword [PlayOptions],PlayOptions.Terminate|PlayOptions.Suspend
    api WaitForSingleObject, [.Th], 4000  ;give it a generous 4 seconds
    cmp eax,WAIT_TIMEOUT
    jne .Close
    api TerminateThread, [.Th],-1
.Close:
    api CloseHandle, [.Th]
    api timeEndPeriod, 1
    ret

section data
align 4, db 0
.Tid:           dd 0            ;thread unique identifier
.Th:            dd 0            ;thread handle
.IntAccum:      dd 0
section bss
alignb 4
.Tick:          resd 1
section text
.StartingPlay:  db "Starting play",0
.StoppingPlay:  db "Stopping play",0
section code
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=source)
; (ecx=length, zf=zero length; esi,edx)
GetStringLength:
    mov eax,1024            ;maximum length of characters
; (al=character to search for, eax=maximum length of characters to search)
.UntilChar:
    mov ecx,eax             ;make a copy of max length for later
    mov edi,esi             ;copy source for string length search
    cld                     ;as always, look forward
    repne scasb             ;search for the end, until character is found
    ;neg ecx                ;;get negative count
    ;dec ecx                ;;minus the character at the end
    not ecx                 ;negate count and subtract character at the end
    add ecx,eax             ;get length (conveniently sets zf)
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=source of text)
StatusMessage:
%if 0;def GuiVer
    test byte [GuiFlags],GuiFlags.Active
    jz .Console                 ;use gui instead of DOS to print msg
    ;not done
    ret
.Console:
%endif
    mov edx,esi
    jmp WriteString.WithEol
.Pending:
%if 0;def GuiVer
    test byte [GuiFlags],GuiFlags.Active
    jz .ConsolePending          ;use gui instead of DOS to print msg
    ;not done
    ret
.ConsolePending:
%endif
    mov edx,esi
    jmp WriteString


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Turns a 32bit number into a decimal (or other) string, writing it to edi.
; By default, it converts a number to a decimal string, maximum of ten
; characters, stored in NumToString.Buffer. To change where the string is
; stored, the length, or radix, these variables can be passed to a different
; entry point. However, all variables before that point must also be defined.
; For example, changing the destination alone is fine, but to change the
; default max length, you must also pass the buffer ptr. To change the radix,
; all three variables must be passed.
;
; If number to be converted would exceed the default buffer size (this would
; only happen with a low radix like binary) a different buffer must be given.
; If a series of numbers will all share the same max character length, the
; .MaxLen variable can be set rather than passing it everytime.
;
; 2002-09-03
; (eax=number, edi=destination, ?ecx=maximum length, ?ebx=radix)
; (esi=ptr to first significant digit, ebx=radix used; none)
NumToString:
    mov edi,.Buffer
;(edi=destination)
.UseDest:
    mov ecx,[.MaxLen]       ;default maximum of ten characters, since the largest 32bit number is 4 gigabytes
;(edi=destination, ecx=number of digits)
.UseDLen:
	mov ebx,10              ;base of the decimal system
;(edi=destination, ecx=number of digits, ebx=radix)
.UseDLRadix:                ;for hexadecimal and binary (even octal)
	xor edx,edx             ;set top 32 bits of quotient to zero
    lea edi,[edi+ecx-1]     ;start from rightmost character in number
.NextChar:
	div ebx                 ;divide number by the decimal base
    mov dl,[.NumberTable+edx] ;get ASCII character from table
    ;add dl,'0'             ;make remainder into an ASCII character
	mov [edi],dl            ;output result
    dec edi                 ;move backwards one character
	test eax,eax            ;see if we are done with the number
	jz .FillInBlanks        ;nothing but zeroes left
	xor edx,edx             ;set edx to zero again for next division
	dec ecx                 ;one less character to output
	jnz .NextChar
    lea esi,[edi+1]         ;return ptr to first significant character
	ret

.FillInBlanks:
    mov al,[.FillChar]      ;fill in with spaces, zeroes, asterisks
    lea esi,[edi+1]         ;return ptr to first significant character
    dec ecx                 ;one less than current count
    ;mov edx,ecx
    std                     ;move backwards
    rep stosb               ;for number of characters remaining
    ;mov ecx,edx            ;return offset of first digit
    cld                     ;for dumb Windows sake (so it doesn't crash)
    ret

section data
align 4
.DefMaxLen      equ 10
.MaxLen:        dd .DefMaxLen
.FillChar:      db ' '
.NumberTable:   db "0123456789ABCDEF"
section bss
.Buffer:    resb .DefMaxLen
section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; String to Number
; (esi=text source, ?ebx=radix, ?ecx=length of string)
; (eax=value, esi=character immediately after, zf=no number)
;
; Turns a string representation of a number into a 32bit unsigned number.
; Ends at a non-numeric digit, including puncuation, extended characters,
; null, or any other control character. Returns zero for a an empty string.
;
StringToNum:
    ;set default returned number to zero
    ;start at first number
    ;do until number (<0 >9 <A >Z)
    ;  multiply by radix and add to value
    ;loop
    ;return value and string length
    mov ebx,10              ;base of the decimal system
.UseRadix:                  ;for hexadecimal and binary (even octal)
    mov ecx,.DefMaxLen
.UseRLength:
    xor edx,edx             ;set top 32 bits of digit place to zero
    mov edi,ecx             ;copy length
    xor eax,eax             ;set return value to zero
.NextChar:
    mov dl,[esi]            ;get digit
    sub dl,48               ;"0"=48->0  "9"=57->9
    jc .End                 ;character is less than '0'
    cmp dl,10
    jb .AddPlaceValue       ;digit is 0-9
    and dl,~32              ;make uppercase by turning off fifth bit
    cmp dl,'A'-48
    jb .End                 ;character is less than 'A'
    cmp dl,'F'-48
    ja .End                 ;character is greater than 'F' (15)
    sub dl,7                ;(65-48)+10  "A"=65->10  "F"=86->15
.AddPlaceValue:
    cmp dl,bl
    jae .End
    imul eax,ebx            ;multiply existing number by radix
    add eax,edx             ;add new digit
    inc esi                 ;move forwards one character
    dec cl                  ;one less character to check
    jnz .NextChar
.End:
    sub edi,ecx             ;set zero flag accordingly
    ;mov ecx,edi
    ret

.DefMaxLen  equ 10          ;default maximum since the largest 32bit is 4gb

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax=midi patch number)
; (esi=ptr to name, ecx=char length)
GetMidiPatchName:
    ;and eax,127
    mov esi,Text.InstrumentList
    xor ecx,ecx
.Next:
    add esi,ecx
    mov cl,[esi]
    inc esi
    dec al
    jns .Next
    ret


%ifdef DosVer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; search through environment for specific variable
; (esi=variable string) (cf=not found, esi=ptr just after name if found)
GetEnvVar:
    call GetStringLength
    cld
    mov ebx,[Program.Env]
    mov edi,esi
    mov edx,ecx
    jmp short .FirstVariable
.NextVariable:
    rep cmpsb
    je .VariableFound
    add edi,ecx
    add ebx,byte 4
    sub edi,edx
    mov ecx,edx
.FirstVariable:
    mov esi,[ebx]
    test esi,esi
    jnz .NextVariable
    stc
.VariableFound: ;cf=0
    ret

%if 0 ;print all environment strings
    mov esi,[Program.Env]
    jmp short .FirstVariable
.NextVariable:
    call WriteString
.FirstVariable:
    mov edx,[esi]
    add esi,byte 4
    test edx,edx
    jnz .NextVariable
    ret
%endif
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
%include "spcemu.asm"           ; Emulation
%include "dspemu.asm"
%include "dspsim.asm"
%include "sample.asm"
%include "disasm.asm"

%include "file.asm"             ; File I/O
%include "settings.asm"

%include "midi.asm"             ; Sound
%include "sound.asm"

%ifdef GuiVer                   ; GUI
    %include "gui\guicode.asm"
    %include "gui\guiobjs.asm"
    %include "gui\gfx.asm"

  section data
    IncDefFonts

    ;%assign Screen.PalColors 256
    IncDefPalette
    ;incbin "rainbow.pal",64

    RainbowColorTable:
    db 16,46,76,106,136,166,196,226
    db 31,61,91,121,151,181,211,241

    IncDefCursors
    GuiCursor.SmallPointer:
    incbin "cursorcl.lbm",0,2048
    dd 0,30                    ;hot spot row/col

    ; This is the top of the heirarchy, the container that contains all
    ; others. Technically it can be named anything, since none of it is
    ; hard coded into the GUI routines. No item is aware of anything but its
    ; container and siblings, making things a lot more abstract, and yet,
    ; a lot simpler!
    MainWindow.Idx equ 0
    MainWindow.Gic equ NullGuiItem
    DefItem MainWindow,WindowCode,NullGuiItem,GuiObj.Redraw|GuiObj.RedrawHandled|GuiObj.RedrawComplex|GuiObj.MouseFocus|GuiObj.FixedPosition|GuiObj.FixedLayer|GuiObj.KeyFocus, 0,0,Screen.Height,Screen.Width
    ;DefWindow NullGuiItem,0,0 ;<- use for an empty field
    ;DefContainedItem mainbg
    ;DefWindowEnd

    %include "gobjlist.asm"
  section code

    %include "songview.asm"
    %include "spcgui.asm"

%endif

%ifdef debug
section code
%include "debug.asm"
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text
Text:
.FullTitle:         db Program.NameDef," ",Program.VersionDef," - (incomplete) DSP to MIDI converter",13,10
                %ifdef debug
                    db "DEBUG "
                %endif
                %ifdef WinVer
                    db "Windows "
                %elifdef DosVer
                    db "DOS "
                %endif
                %ifdef ConVer
                    db "console"
                %else
                    db "GUI"
                %endif
                    db " version (c)2002 PeekinSoŸt",13,10
                    db 10,0
.About:             db "Usage:  Spc2Midi [-/options] filename.ext",13,10                    
                    db 10
                    db "Options:",13,10
                    db "  as    - audio samples (default)       noda  - disable all wave audio",13,10
                    db "  fm    - play FM synthesis             nofm  - disable FM initialization",13,10
                    db "  mpu   - MIDI through external port    nompu - disable MPU MIDI output",13,10
                %ifdef WinVer
                    db "  gm    - internal MIDI synthesizer     nogm  - disable synthesizer output",13,10
                %endif
                    db "  sine  - sine wave synthesis           dls   - (someday...)",13,10
                    db "  midi  - export to MIDI file           tune# - constant tone (def A440hz)",13,10
                    db "  solo# - solo one or more voices",13,10
                    db 10
                    db "  r#    - sound card sampling rate 5000-64000  (32000khz)",13,10
                    db "  m#    - internal mixing rate 2000-200000 (32000khz)",13,10
                    db "  dp#   - default GM patch 1-128 (46)   dd#   - default percussion sound 1-128",13,10
                    db "  db#   - default bank 0-16383 (0)      dv#   - default volume (512)",13,10
                    db "  df#   - default frequency 0-12543 (440hz)",13,10
                    db "  8     - force 8bit on 16bit sound cards (16)",13,10
                    db "  16    - force 16bit on cards <= DSP3",13,10
                    db 10
                %ifdef ConVer
                    db "  info  - display sample table info     dbrr  - dump BRR buffer ",13,10
                    db "  asm   - disassembly trace",13,10
                %endif
                %ifdef DosVer
                %ifdef GuiVer
                    db "  con   - text console only",13
                %endif
                %endif
                    db 0
.PreviewOnly:       db "The included GUI version is a PREVIEW",13
                    db "It is only an incomplete PREVIEW",13
                    db "Do not make any final judgements",13
                    db "Most all of the menu options are unfinished",13
                    db "Options won't show error messages, just do nothing",13
                    db "You can supply a filename after the program,",13
                    db "or drag&drop files from Explorer onto it for now.",0
.Ready:             db "Ready for emulation. Press a key...",13,10,0
.Keys:              db 10
                    db "Play Control:                 Toggle Sound Output:",13,10
                    db "  Space  Pause                  a      Audio samples",13,10
                    db "  Home   Restart                s      Sine wave synth",13,10
                    db "  End    End of emulation       d      (DLS someday)",13,10
                    db "  BkSpc  Reverse play           f      FM",13,10
                %ifdef WinVer
                    db "  - +    Change tempo           g      General MIDI",13,10
                    db "  <- ->  Seek one second        h      Hardware MIDI port",13,10
                %else
                    db "  - +    Change tempo           g/h    General MIDI (MPU401)",13,10
                    db "  <- ->  Seek one second",13,10
                %endif
                    db "  , .    Fine seek adjustment",13,10
                    db 10
                    db "Muting:                       Other:",13,10
                    db "  1-8    Mute/Enable            ",24," ",25,"    Change sample",13,10
                    db "  0      Mute all               Esc    Quit",13,10
                    db "  9      Enable all",13,10
                    db "  p      Disable pitch slide",13,10
                    db 0
.UnverifiedOpcode:  db "##    @#### <########> - Unverified opcode. Emulation may procede incorrectly.",13,10,0
.DspWrite:          db "##:## @#### <########> - DSP written to.",13,10,0
.DspRead:           db "##:## @#### <########> - DSP read from.",13,10,0
.DspWriteIllegal:   db "##:## @#### <########> - Write to invalid DSP register.",13,10,0
.RegWriteIllegal:   db "##:## @#### <########> - Write to read-only register.",13,10,0
.RegReadIllegal:    db "##:## @#### <########> - Read from write-only register.",13,10,0
.MissingParameter:  db "! Missing parameter value",0
.InvalidParameter:  db "! Invalid parameter",0
.MultipleParameters:db "! More than one filename was given",0
.InvalidSampleRate: db "! Invalid sample rate (5000-64000)",0
.InvalidMixingRate: db "! Invalid mixing rate (2000-200000)",0
.InvalidPatch:      db "! Invalid MIDI tone (1-128)",0
.InvalidBank:       db "! Invalid MIDI bank (0-16383)",0
.InvalidFreq:       db "! Invalid base frequency (<12543)",0
.InvalidTune:       db "! Invalid tuning frequency (<12543)",0
.FileTypeBad:       db "Unrecognized filetype. Can only load SPC/ZST/ZMV files.",0
.FileOpenError:     db "Could not open the given file. Check the spelling and path.",0
.NoSpcFileData:     db "File does not contain SPC data.",0
.SpcReadError:      db "! File is corrupt and may play incorrectly",0
.LoadingSpcFile:    db "Loading SPC capture state",0
.LoadingZstFile:    db "Loading ZSNES savestate",0
.LoadingBios:       db "Loading ROM BIOS",0
.DspOutputError:    db "! Could not open the DSP output file",0
.ValidatingSamples: db "Checking valid BRR samples",0
.BufferingSamples:  db "Buffering BRR sound samples",0
.IdentifyingSamples:db "Identifying unique samples",0
.ExportBrrBuffer:   db "Exporting entire buffer to BRROUT.WAV",0
.LoadingSettings:   db "Loading settings (spc2midi.ini)",0
.SampleInfoTitles:  db "Sample    Offset   Valid  Len Loop   Checksum",13,10,0
.SampleInfo:        db "###    ##### #####  ##  ##### #####  ########  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$",13,10,0,0
.CurTime:           db "###:##.### / ###:##.###",13,0
.Yes:               db "yes"
.Null               db 0
.No:                db "no",0
.InstrumentList:
; PIANO
db 14,"Acoustic Grand"
db 15,"Bright Acoustic"
db 14,"Electric Grand"
db 10,"Honky-Tonk"
db 16,"Electric Piano 1"
db 16,"Electric Piano 2"
db 11,"Harpsichord"
db  8,"Clavinet"
; CHROMATIC PERCUSSION
db  7,"Celesta"
db 12,"Glockenspiel"
db 9,"Music Box"
db 10,"Vibraphone"
db  7,"Marimba"
db  9,"Xylophone"
db 13,"Tubular Bells"
db  8,"Dulcimer"
; ORGAN
db 13,"Drawbar Organ"
db 16,"Percussive Organ"
db 10,"Rock Organ"
db 12,"Church Organ"
db 10,"Reed Organ"
db  9,"Accordian"
db  9,"Harmonica"
db 15,"Tango Accordian"
; GUITAR
db 19,"Nylon String Guitar"
db 19,"Steel String Guitar"
db 20,"Electric Jazz Guitar"
db 21,"Electric Clean Guitar"
db 21,"Electric Muted Guitar"
db 17,"Overdriven Guitar"
db 17,"Distortion Guitar"
db 16,"Guitar Harmonics"
; BASS
db 13,"Acoustic Bass"
db 22,"Electric Bass (finger)"
db 20,"Electric Bass (pick)"
db 13,"Fretless Bass"
db 11,"Slap Bass 1"
db 11,"Slap Bass 2"
db 12,"Synth Bass 1"
db 12,"Synth Bass 2"
; SOLO STRINGS
db  6,"Violin"
db  5,"Viola"
db  5,"Cello"
db 10,"Contrabass"
db 15,"Tremolo Strings"
db 17,"Pizzicato Strings"
db 18,"Orchestral Strings"
db  7,"Timpani"
; ENSEMBLE
db 17,"String Ensemble 1"
db 17,"String Ensemble 2"
db 14,"SynthStrings 1"
db 14,"SynthStrings 2"
db 10,"Choir Aahs"
db 10,"Voice Oohs"
db 11,"Synth Voice"
db 13,"Orchestra Hit"
; BRASS
db  7,"Trumpet"
db  8,"Trombone"
db  4,"Tuba"
db 13,"Muted Trumpet"
db 11,"French Horn"
db 13,"Brass Section"
db 12,"SynthBrass 1"
db 12,"SynthBrass 2"
; REED
db 11,"Soprano Sax"
db  8,"Alto Sax"
db  9,"Tenor Sax"
db 12,"Baritone Sax"
db  4,"Oboe"
db 12,"English Horn"
db  7,"Bassoon"
db  8,"Clarinet"
; PIPE
db  7,"Piccolo"
db  5,"Flute"
db  8,"Recorder"
db  9,"Pan Flute"
db 12,"Blown Bottle"
db 10,"Skakuhachi"
db  7,"Whistle"
db  7,"Ocarina"
; SYNTH LEAD
db 15,"Lead 1 (square)"
db 17,"Lead 2 (sawtooth)"
db 17,"Lead 3 (calliope)"
db 14,"Lead 4 (chiff)"
db 16,"Lead 5 (charang)"
db 14,"Lead 6 (voice)"
db 15,"Lead 7 (fifths)"
db 18,"Lead 8 (bass+lead)"
; SYNTH PAD
db 15,"Pad 1 (new age)"
db 12,"Pad 2 (warm)"
db 17,"Pad 3 (polysynth)"
db 13,"Pad 4 (choir)"
db 13,"Pad 5 (bowed)"
db 16,"Pad 6 (metallic)"
db 12,"Pad 7 (halo)"
db 13,"Pad 8 (sweep)"
; SYNTH EFFECTS
db 11,"FX 1 (rain)"
db 17,"FX 2 (soundtrack)"
db 14,"FX 3 (crystal)"
db 17,"FX 4 (atmosphere)"
db 17,"FX 5 (brightness)"
db 14,"FX 6 (goblins)"
db 13,"FX 7 (echoes)"
db 13,"FX 8 (sci-fi)"
; ETHNIC
db  5,"Sitar"
db  5,"Banjo"
db  8,"Shamisen"
db  4,"Koto"
db  7,"Kalimba"
db  7,"Bagpipe"
db  6,"Fiddle"
db  6,"Shanai"
; PERCUSSIVE
db 11,"Tinkle Bell"
db  5,"Agogo"
db 11,"Steel Drums"
db  9,"Woodblock"
db 10,"Taiko Drum"
db 11,"Melodic Tom"
db 10,"Synth Drum"
db 14,"Reverse Cymbal"
; SOUND EFFECTS
db 17,"Guitar Fret Noise"
db 12,"Breath Noise"
db  8,"Seashore"
db 10,"Bird Tweet"
db 14,"Telephone Ring"
db 10,"Helicopter"
db  8,"Applause"
db  7,"Gunshot"

section data
SoundDumpHeader:    db "RIFF"
                    dd 4+24+8+SamplesBufferSize
                    db "WAVEfmt "
                    dd 16
                    dw 1,1          ;PCM/Mono
.SampleRate:        dd 11025,11025*2;much lower than actual rate (32khz)
                    dw 2,16         ;block alignment/16bit audio
                    db "data"
                    dd SamplesBufferSize
SoundDumpHeader.Size equ $-SoundDumpHeader
SoundDumpFileName:  db "BRROUT.WAV",0

[section text]
TextEnd:
[section bss]
BssEnd:
