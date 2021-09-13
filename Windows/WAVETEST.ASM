; Copy Bad File (c)PikenSoft
; 2002-08-01 / 2002-08-01
; Dwayne Robinson (FDwR@hotmail.com)
;
; Purpose:
;   Tests wave out functions of Window's corrupt, inconsistent media library.
;
; Reason:
;   For porting Spc2Midi to Windows.
;
; Todo:
;   Not much.

[section code code]
[section data data]
[section text data]
[section bss bss]
global Main


; Include Windows definitions/constants/macros
;%define debug
;%define PollStatus
%define UseWindowStyles
%define UseWindowControls
%define UseWindowMsgs
%define UseWindowGfx
;%define UseResources
%define UseFileSystem
%define UseKeyboard
%define UseMultimedia
%include "mywininc.asm"         ;standard Windows constants, structs...

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
align 4, db 0
hwnd:   dd 0                    ;window handle
;hdc:   dd 0                    ;class device context
hfont:  dd 0                    ;default font to use for controls
focus:  dd 0                    ;control that has focus

wc:
.BaseAddress                    equ 400000h ;base address of program (Windows module handle)
istruc WNDCLASS
at WNDCLASS.style,              dd CS_CLASSDC
at WNDCLASS.lpfnWndProc,        dd MsgProc
at WNDCLASS.cbClsExtra,         dd 0
at WNDCLASS.cbWndExtra,         dd 0
at WNDCLASS.hInstance,          dd .BaseAddress ;(default image base is at 4MB)
at WNDCLASS.hIcon,              dd NULL
at WNDCLASS.hCursor,            dd NULL
at WNDCLASS.hbrBackground,      dd COLOR_BTNFACE + 1
at WNDCLASS.lpszMenuName,       dd NULL
at WNDCLASS.lpszClassName,      dd ClassNames.Program
iend

;             control name, id,     class name          text                flags                                   x  y        w h
DefWndControl lblProgInfo,      100, ClassNames.Label,  Text.ProgInfo,      0,                                      8, 8,       200,16*6
DefWndControl lblResult,        101, ClassNames.Label,  NullString,         WS_DLGFRAME,                            200-4, 8,   200,16*6
DefWndControl cmdOpen,          200, ClassNames.Button, "&Open",            WS_TABSTOP|BS_DEFPUSHBUTTON|WS_GROUP,   8+56*0,112, 52,24
DefWndControl cmdPrep,          201, ClassNames.Button, "P&repare",         0,                                      8+56*1,112, 52,24
DefWndControl cmdPlay,          202, ClassNames.Button, "&Play",            0,                                      8+56*2,112, 52,24
DefWndControl cmdStop,          203, ClassNames.Button, "&Stop",            0,                                      8+56*3,112, 52,24
DefWndControl cmdUnprep,        204, ClassNames.Button, "&Unprep",          0,                                      8+56*4,112, 52,24
DefWndControl cmdClose,         205, ClassNames.Button, "&Close",           0,                                      8+56*5,112, 52,24
DefWndControl cmdAbout,         206, ClassNames.Button, "&About",           0,                                      8+56*6,112, 52,24
DefWndControl cmdNormal,        210, ClassNames.Button, "Normal",           WS_TABSTOP|WS_GROUP|BS_AUTORADIOBUTTON|BS_PUSHLIKE, 8+36*0,112-20, 36,16
DefWndControl cmdEcho,          211, ClassNames.Button, "Echo",             BS_AUTORADIOBUTTON|BS_PUSHLIKE,         8+36*1,112-20, 36,16
DefWndControl cmdMirror,        212, ClassNames.Button, "Mirror",           BS_AUTORADIOBUTTON|BS_PUSHLIKE,         8+36*2,112-20, 36,16
DefWndControl cmdDistort,       213, ClassNames.Button, "Distort",          BS_AUTORADIOBUTTON|BS_PUSHLIKE,         8+36*3,112-20, 36,16
DefWndControl cmdShrill,        214, ClassNames.Button, "Shrill",           BS_AUTORADIOBUTTON|BS_PUSHLIKE,         8+36*4,112-20, 36,16

cmdSfx.FirstId equ 210
cmdSfx.LastId  equ 214

;rect:
;point:
;dd 0,            0             ;left,top
;dd Screen.Width, Screen.Height ;right,bottom

section bss
msg:    resb MSG_size
;ps:    resb PAINTSTRUCT_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:   db "Test Windows waveOut 1.0 (Beta)" ;,0
NullString:     db 0
ClassNames:
.Program:       db "PknTestWaveOut",0
.Button:        db "BUTTON",0
.Label:         db "STATIC",0
;.Edit:         db "EDIT",0
;.Progress:     db "msctls_progress32",0
ErrMsg:
;.Fatal:        db "CopyBadFile: Fatal Error",0
.NoWindow:      db "Failed to create window.",0
section bss
.WaveOut:       resb MAXERRORLENGTH
section text
Text:
.ProgInfo:      db "1. Open the wave device",10
                db "2. Prepare the block",10
                db "3. Play the wave buffer",10
                db "4. Stop if necessary",10
                db "5. Unprepare the block",10
                db "6. Close the wave device",0
.About:         db "Dwayne Robinson",10
                db "PikenSoft 2002-08-01",10
                db "FDwR@hotmail.com",10
                db "http://oregonstate.edu/~robinsfr",10
                db "http://fdwr.tripod.com/",10
                db 10
                db "The short sound clip is from the",10
                db "Secret of Mana map screen",10
                db "towards the last fortress.",10
                db 0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; global program variables

section data
align 4, db 0
Playing:    dd 0                ;currently playing flag
BlockCount: dd 0                ;number of blocks sent to device

hwo:        dd 0                ;handle of waveform output

wfx:                            ;wave format header extended
istruc WAVEFORMATEX
at WAVEFORMATEX.wFormatTag,     dw 1        ; format type
at WAVEFORMATEX.nChannels,      dw 1        ; number of channels (i.e. mono, stereo...)
at WAVEFORMATEX.nSamplesPerSec, dd 11025    ; sample rate
at WAVEFORMATEX.nAvgBytesPerSec,dd 22050    ; for buffer estimation
at WAVEFORMATEX.nBlockAlign,    dw 2        ; block size of data
at WAVEFORMATEX.wBitsPerSample, dw 16       ; number of bits per sample of mono data
at WAVEFORMATEX.cbSize,         dw 0        ; the count in bytes of the size of
; no extra information (after cbSize)
iend

lpwh:
istruc WAVEHDR
at WAVEHDR.lpData,              dd WaveDataBuffer   ;pointer to locked data buffer
at WAVEHDR.dwBufferLength,      dd WaveData_size    ;length of data buffer
at WAVEHDR.dwBytesRecorded,     dd 0                ;used for input only
at WAVEHDR.dwUser,              dd 0                ;for client's use
;at WAVEHDR.dwFlags,            dd 0                ;assorted flags
;at WAVEHDR.dwLoops,            dd 0                ;loop control counter
at WAVEHDR.dwFlags,             dd WHDR_BEGINLOOP|WHDR_ENDLOOP|WHDR_DONE ;assorted flags
at WAVEHDR.dwLoops,             dd 3;-1             ;loop control counter
at WAVEHDR.lpNext,              dd 0                ;reserved for driver
at WAVEHDR.reserved,            dd 0                ;reserved for driver
iend

MmTime:
istruc MMTIME
at MMTIME.wType,                dd TIME_BYTES       ;time format
at MMTIME.sample,               dd 0
iend

align 4, db 0
;WaveData:   incbin "WAVETEST.WAV",54
WaveData:   incbin "53MAP3.WAV",54+795000,108700
;WaveData:   incbin "\WINDOWS\DESKTOP\CONFLI~1.WAV",54
WaveData_size equ $-WaveData
section bss
alignb 4
WaveDataBuffer: resb WaveData_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

Main:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create window

    api LoadCursor, 0,IDC_ARROW
    mov [wc+WNDCLASS.hCursor],eax
    api LoadIcon, wc.BaseAddress,1
    mov [wc+WNDCLASS.hIcon],eax

    ; register window class
    debugwrite "registering class"
    api RegisterClass, wc
    debugwrite "register result=%X", eax
    test eax,eax
    mov esi,ErrMsg.NoWindow
    jz near EndWithErrMsg

    ; create instance of window
    debugwrite "creating window"
    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT, ClassNames.Program, ProgramTitle, WS_MINIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME, 0,0, 408,8*21, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    jz near EndWithErrMsg
    ;mov [hwnd],eax

    mov esi,WaveData
    mov edi,WaveDataBuffer
    cld
    mov ecx,WaveData_size/4
    rep movsd

    api SendMessage, [cmdNormal],BM_SETCHECK,TRUE,0

  %ifdef PollStatus
    api SetTimer,[hwnd],1,33,NULL   ;30 times per second, no callback
  %endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Main Loop
.Top:
    ;debugpause "entering main loop"

.Next:
    xor eax,eax
    api GetMessage, msg, eax,eax,eax
    test eax,eax
    jz near .End
    mov eax,[msg+MSG.message]
    debugwinmsg "process msg=%X %s W=%X L=%X", eax,edx,[msg+MSG.wParam],[msg+MSG.lParam]
    cmp eax,WM_LBUTTONDOWN
    jne .NotLbutton
    api SetWindowText, [lblResult],NullString
.NotLbutton:
    api IsDialogMessage, [hwnd],msg
    ;api DispatchMessage, msg
    cmp [Playing],dword FALSE
    je .Next

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.PlayLoop:
    debugpause "entering play loop"
    mov dword [BlockCount],0
.NextBlock:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; update information (current byte position)
    mov eax,[BlockCount]
    inc eax
    mov [BlockCount],eax
    call NumToString
    api SetWindowText, [lblResult],NumToString.Buffer

    ; check for any pending messages
.NextPeek:
    xor eax,eax
    api PeekMessage, msg, eax,eax,eax,PM_REMOVE
    test eax,eax
    jz near .NextBlock
    cmp dword [msg+MSG.message],WM_QUIT
    je .End
    api IsDialogMessage, [hwnd],msg
    ;api DispatchMessage, msg
    cmp [Playing],dword FALSE
    jne .NextPeek
    jmp .Top


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Termination
.End:
    cmp dword [hwo],0
    je .WaveClosed
    api waveOutReset, [hwo]
    api waveOutClose, [hwo]
.WaveClosed:
  %ifdef PollStatus
    api KillTimer,[hwnd],1      ;destroy 30 tick per second timer
  %endif

    ;debugpause "ending"
    api DestroyWindow, [hwnd]
    api ExitProcess, [msg+MSG.wParam]


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[esp+.wParam+4],[esp+.lParam]

    cmp eax,WM_COMMAND
    jne .NotCommand
    cmp word [esp+.wParam+2],BN_CLICKED
    je near .ButtonPushed
.NotCommand:
    cmp eax,WM_TIMER
    je near .Timer
    cmp eax,WM_ACTIVATE
    je near .Activate
    cmp eax,WM_CREATE
    je near .Create
    cmp eax,WM_SYSCOMMAND
    je near .Minimize
    cmp eax,WM_WINDOWPOSCHANGED
    je .RetFalse
    cmp eax,WM_WINDOWPOSCHANGING
    je .RetFalse
    cmp eax,WM_DESTROY
    je .Destroy

.DefProc:
    jmp [DefWindowProc]

.RetTrue:
    mov eax,TRUE
    ret 16

.Destroy:
    ;debugpause "destroying window"
    xor eax,eax
    mov [hwnd],eax
    api PostQuitMessage,eax
.RetFalse:
    xor eax,eax
    ret 16

.Create:
    mov eax,[esp+.hwnd]
    mov [hwnd],eax
    ;mov [focus],eax
    ;api GetDC, eax              ;get window class display handle
    ;debugwrite "get hdc=%X",eax
    ;mov [hdc],eax
    api GetStockObject, DEFAULT_GUI_FONT
    mov [hfont],eax

    ;api InitCommonControls

    ; create labels
    push dword lblProgInfo
    call CreateChildWindow
    push dword lblResult
    call CreateChildWindow

    ; create buttons
    push dword cmdOpen
    call CreateChildWindow
    mov [focus],eax
    push dword cmdPrep
    call CreateChildWindow
    push dword cmdPlay
    call CreateChildWindow
    push dword cmdStop
    call CreateChildWindow
    push dword cmdUnprep
    call CreateChildWindow
    push dword cmdClose
    call CreateChildWindow
    push dword cmdAbout
    call CreateChildWindow

    push dword cmdNormal
    call CreateChildWindow
    push dword cmdEcho
    call CreateChildWindow
    push dword cmdMirror
    call CreateChildWindow
    push dword cmdDistort
    call CreateChildWindow
    push dword cmdShrill
    call CreateChildWindow

    xor eax,eax
    ret 16

.EscPressed:
    api PostQuitMessage,0
    ret

.ButtonPushed:
    mov eax,[esp+.wParam]
    push dword .RetFalse
    cmp eax,IDCANCEL
    je .EscPressed
    cmp eax,cmdSfx.FirstId
    jb .NotSfx
    cmp eax,cmdSfx.LastId
    jbe near .cmdSfx
  .NotSfx:
    cmp eax,cmdOpen.Id;|(BN_CLICKED<<16)
    je near .cmdOpen
    cmp eax,cmdClose.Id
    je near .cmdClose
    cmp eax,cmdAbout.Id
    je near .cmdAbout
    cmp eax,cmdStop.Id
    je .cmdStop
    cmp eax,cmdPlay.Id
    je .cmdPlay
    cmp eax,cmdPrep.Id
    je .cmdPrep
    cmp eax,cmdUnprep.Id
    je .cmdUnprep
    ret

.cmdStop:
    api waveOutReset, [hwo]
    jmp ShowMmError
.cmdPlay:
    api waveOutWrite, [hwo],lpwh,WAVEHDR_size
    jmp ShowMmError
.cmdPrep:
    ;mov dword [lpwh+WAVEHDR.dwLoops],2000
    ;mov dword [lpwh+WAVEHDR.dwFlags],WHDR_BEGINLOOP|WHDR_ENDLOOP
    api waveOutPrepareHeader, [hwo],lpwh,WAVEHDR_size
    jmp ShowMmError
.cmdUnprep:
    api waveOutUnprepareHeader, [hwo],lpwh,WAVEHDR_size
    jmp ShowMmError
.cmdClose:
    api waveOutClose, [hwo]
    call ShowMmError
    test eax,eax
    jnz .DontClose
    mov [hwo],dword 0
.DontClose:
    ret
.cmdOpen:
    ;api waveOutOpen, hwo,WAVE_MAPPER, wfx,0,0, WAVE_ALLOWSYNC
    api waveOutOpen, hwo,0, wfx,[hwnd], 0,CALLBACK_WINDOW|WAVE_ALLOWSYNC
    call ShowMmError
    ;debugpause "waveform output handle = %X",[hwo]
    ret
.cmdAbout:
    api MessageBox, [hwnd],Text.About,ProgramTitle,MB_OK|MB_ICONINFORMATION ;|MB_SETFOREGROUND
    ret

.cmdSfx:
    push ebx,esi,edi

    mov edi,WaveDataBuffer
    mov ecx,WaveData_size/4
    mov esi,WaveData
    rep movsd

    mov edi,WaveDataBuffer
    mov ecx,WaveData_size/2
    push dword .cmdSoundFxRet
    cmp eax,cmdEcho.Id
    je .cmdEcho
    cmp eax,cmdMirror.Id
    je .cmdMirror
    mov ecx,WaveData_size/4
    cmp eax,cmdDistort.Id
    je .cmdDistort
    cmp eax,cmdShrill.Id
    je .cmdShrill
    ;cmp eax,cmdNormal.Id
    ;je .cmdNormal
    pop eax
.cmdSoundFxRet:
    pop ebx,esi,edi
    ret

.cmdEcho:
    lea esi,[edi+1000]
    cmp esi,WaveDataBuffer+WaveData_size
    jb .DwSrcOk
    sub esi,WaveData_size
.DwSrcOk:
    movsx eax,word [esi]
    movsx ebx,word [edi]
    ;sar ebx,1
    add eax,ebx
    sar eax,1
    mov [edi],ax
    ;    jno .NoOverflow
    ;    mov ax,8000h
    ;    js .OverflowNegative
    ;    mov ax,7FFFh
    ;.OverflowNegative:
    ;    mov [edi],ax
    ;.NoOverflow:
    add edi,byte 2
    loop .cmdEcho
    ret

.cmdMirror:
    test word [edi],8000h
    jns .SfxmUnsigned
    neg word [edi]
.SfxmUnsigned:
    add edi,byte 2
    loop .cmdMirror
    ret

.cmdDistort:
    ;not word [edi]
    ;xor word [edi],3FFFh
    ;xor dword [edi],08000800h
    ;xor dword [edi],66666666h
    xor dword [edi],060006000h
    sar word [edi],1
    sar word [edi+2],1
    add edi,byte 4
    loop .cmdDistort
    ret

.cmdShrill:
    not word [edi]
    ;xor word [edi],3FFFh
    ;xor dword [edi],08000800h
    ;xor dword [edi],66666666h
    ;xor dword [edi],060006000h
    ;sar word [edi],1
    ;sar word [edi+2],1
    add edi,byte 4
    loop .cmdShrill
    ret

.Activate:
    cmp word [esp+.wParam],WA_INACTIVE
    je .LoseFocus
    debugwrite "new focus hwnd=%X",[focus]
    api SetFocus, [focus]
    xor eax,eax
    ret 16

.LoseFocus:
    api GetFocus
    test eax,eax
    jz .NullFocus
    mov [focus],eax
    debugwrite "old focus hwnd=%X",eax
    xor eax,eax
.NullFocus:
    ret 16

.Minimize:
    cmp dword [esp+.wParam],SC_MINIMIZE
    jne .NotMinimize
    api GetFocus
    mov [focus],eax
    debugwrite "old focus hwnd=%X",eax
.NotMinimize:
    jmp [DefWindowProc]

.Timer:
  %ifdef PollStatus
    cmp dword [hwo],0
    je .TimerWaveClosed
    api waveOutGetPosition, [hwo], MmTime,MMTIME_size
    ;mov eax,[MmTime+MMTIME.wType]
    mov eax,[MmTime+MMTIME.sample]
    ;mov eax,[lpwh+WAVEHDR.dwFlags]
    ;and eax,WHDR_DONE;INQUEUE
    call NumToString
    api SetWindowText, [lblResult],NumToString.Buffer
.TimerWaveClosed:
  %endif
    xor eax,eax
    ret 16


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Copies a control structure onto parameter stack and calls CreateWindowEx.
; Sets the font for each control, assumes the standard GUI font has already
; been obtained.
CreateChildWindow:
    push esi,edi
    mov esi,[esp+12]
    xor eax,eax                 ;null window creation data
    push eax
    push dword wc.BaseAddress
    push dword [esi+WndControlStruct.hId]
    push dword [hwnd]
    ;cld
    sub esp,byte 7*4
    add esi,byte WndControlStruct.lpClassName
    mov ecx,7
    mov edi,esp
    rep movsd
    ;push eax                    ;no ex style
    push dword WS_EX_NOPARENTNOTIFY|WS_EX_CONTEXTHELP
    api CreateWindowEx
    push eax
    mov [esi+WndControlStruct.hwnd-WndControlStruct_size],eax
    api SendMessage, eax,WM_SETFONT,[hfont],FALSE
    pop eax
    pop esi,edi
    ret 4

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=error message ptr)
EndWithErrMsg:
    debugwrite "exiting process from fatal error: %s", esi
    api MessageBox, [hwnd],esi,ProgramTitle,MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL ;|MB_SETFOREGROUND
    api DestroyWindow, [hwnd]
    api ExitProcess, -1

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (eax) (; eax,!)
ShowMmError:
    push eax
    api waveOutGetErrorText, eax,ErrMsg.WaveOut,MAXERRORLENGTH
    api SetWindowText, [lblResult],ErrMsg.WaveOut

    ;debugpause "Media error: %d %s",eax,ErrMsg.WaveOut
    ;mov edi,ErrMsg.WaveOut
    ;mov ecx,5
    ;jmp NumToString.UsingDLen
    pop eax
    ret

%if 0
    mov eax,MB_OK|MB_TOPMOST|MB_ICONEXCLAMATION|MB_TASKMODAL
    cmp dword [esp],0
    ja .Error
    xor eax,MB_ICONASTERISK|MB_ICONEXCLAMATION
.Error:
    api MessageBox, [hwnd],ErrMsg.WaveOut,ProgramTitle,eax

    mov eax,[lpwh+WAVEHDR.dwFlags]
    call NumToString

%endif


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
; (eax=number, ?ecx=maximum length, ?edi=destination, ?ebx=radix)
; (ecx=offset of first significant digit, ebx=radix used; esi)
NumToString:
    mov edi,.Buffer
;(edi=destination)
.UsingDest:
    mov ecx,[.MaxLen]       ;default maximum of ten characters, since the largest 32bit number is 4 gigabytes
;(edi=destination, ecx=number of digits)
.UsingDLen:
	mov ebx,10              ;base of the decimal system
;(edi=destination, ecx=number of digits, ebx=radix)
.UsingDLRadix:              ;for hexadecimal and binary (even octal)
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
	ret

.FillInBlanks:
    mov al,[.FillChar]      ;fill in with spaces, zeroes, asterisks
    dec ecx                 ;one less than current count
    mov edx,ecx
    std                     ;move backwards
    rep stosb               ;for number of characters remaining
    cld                     ;clear df so dumb Windows doesn't crash
    mov ecx,edx             ;return offset of first digit
    ret

section data
align 4
.DefMaxLen      equ 10
.MaxLen:        dd .DefMaxLen
.FillChar:      db ' '
.NumberTable:   db "0123456789ABCDEF"
section bss
.Buffer:        resb .DefMaxLen+1
section code


%if 0
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
%endif
