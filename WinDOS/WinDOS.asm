; WinDOS Windows/DOS abstraction.
; This library just translates a few DOS/BIOS interrupts to equivalent Windows
; calls, making the port easier of a few old DOS apps. For DOS, it just calls
; the interrupts instead. The function support is very limited, just enough to
; support my own apps.
;
; By Dwayne Robinson (FDwR@hotmail.com)
; http://pikensoft.com/
; Assembly compiled with NASM (the best/least ugly assembler I've come across).

;[section code code]
;[section data data]
;[section text code]
;[section bss bss]

;%define debug


%ifdef DosVer
%elifdef WinVer
%else
    %error "Either DosVer or WinVer must be defined.""
%endif


%ifdef DosVer
    ; DOS just calls the interrupt int directly.
%elifdef WinVer
    %macro int 1
        call WinDosInt%1
    %endmacro
    
    %macro in 2
        call WinDosReadPort
    %endmacro

    %macro out 2
        call WinDosWritePort
    %endmacro
    
    %define outsb %error "You will need to break rep outsb into a loop and out dx,al statement."
%endif ;WinVer

%macro WinDosInAlDx 0
  %ifdef DosVer
    in al,dx
  %elifdef WinVer
    xor al,al
  %endif
%endmacro

%macro WinDosOutDxAl 0
  %ifdef DosVer
    out dx,al
  %elifdef WinVer
    call WinDosWritePort
  %endif
%endmacro

; Waits on the operating system for events to update state.
; The caller should provide a line label to quit the program if needed.
%macro WinDosWaitForEvent 1
  %ifdef WinVer
    call WinDosGetMessage
    cmp byte [WinDos.isActive],0
    je near %1
  %endif
%endmacro

; Polls the operating system for events to update state.
; The caller should provide a line label to quit the program if needed.
%macro WinDosCheckForEvent 1
  %ifdef WinVer
    call WinDosPeekMessage
    cmp byte [WinDos.isActive],0
    je near %1
  %endif
%endmacro

; Waits on the operating system for events to update state.
; The caller should provide a line label to quit the program if needed.
%macro WinDosWaitForNoEvents 1
  %ifdef WinVer
%%.MoreEvents:
    call WinDosPeekMessage
    cmp byte [WinDos.isActive],1
    jl near %1
    je %%.MoreEvents
  %endif
%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%ifdef WinVer

%ifndef WinDos.windowClassNameDefine
%define WinDos.windowClassNameDefine "WinDosApp"
%endif
%ifndef WinDos.defaultWindowClassName
%define WinDos.defaultWindowClassName "WinDosApp"
%endif
%ifndef WinDos.programNameDefine
%define WinDos.programNameDefine "WinDosApp"
%endif

%define UseWindowAll
%include "wininc.asm"         ;standard Windows constants, structs...

%endif ;WinVer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section data
align 4, db 0

WinDos:

section data
align 4, db 0
.commandLine:               dd 0        ;pointer to original command line
.commandLineParameterCount: dd 0        ;total parsed parameters
section bss
.commandLineEnd:            resd 1
.dummyUint32:               resd 1      ;dword to waste unused values
.commandLineParameterMax    equ 32
.commandLineParameters:     resd .commandLineParameterMax ;parsed pointers to each parameter
.commandLineParsedBufferMax equ 1024
.commandLineParsedBuffer:   resd .commandLineParsedBufferMax ;parsed command line
section data

%ifdef DosVer
.displayMemoryBase: dd 0A0000h
.pspSelector:       dd 0

%elifdef WinVer

.baseAddress        equ 400000h ;base address of program (Windows module handle)

.defaultScreenWidth equ 640
.defaultScreenHeight equ 480

.displayMemoryBase: dd 0h                   ;initialized later
.displayWidth:      dd .defaultScreenWidth
.displayHeight:     dd .defaultScreenHeight

.isActive:          dd 1                    ;true while the main window exists
.hwnd:              dd 0                    ;window handle
.hdc:               dd 0                    ;windows class device context
.hdcc:              dd 0                    ;compatible DC handle
.hpal:              dd 0                    ;palette handle
.hdib:              dd 0                    ;DIB section handle
.threadId:          dd 0                    ;thread identifier
;.scanCode:          dd 0                    ;hardware scancode
;.virtualKeyCode:    dd 0                    ;Windows virtual code key
;.keyChar:           dd 0                    ;Unicode character
.biosKeyCode:       dd 0                    ;upper byte is scan code, lower is character
.mouseX:            dd 0
.mouseY:            dd 0
.mouseButtons:      dd 0
.windowClassName:   db WinDos.windowClassNameDefine,0
.programName:       db WinDos.programNameDefine,0

align 4, db 0
.vgaColorReadRegisterIndex:     dd 0
.vgaColorWriteRegisterIndex:    dd 0
.vgaColorPaletteIsDirty:        db 0

align 4, db 0
.windowClass:
istruc WNDCLASS
at WNDCLASS.style,              dd CS_CLASSDC
at WNDCLASS.lpfnWndProc,        dd WinDosMessageProc
at WNDCLASS.cbClsExtra,         dd 0
at WNDCLASS.cbWndExtra,         dd 0
at WNDCLASS.hInstance,          dd .baseAddress ;(default image base is at 4MB)
at WNDCLASS.hIcon,              dd NULL
at WNDCLASS.hCursor,            dd NULL
at WNDCLASS.hbrBackground,      dd COLOR_BTNFACE + 1
at WNDCLASS.lpszMenuName,       dd NULL
at WNDCLASS.lpszClassName,      dd .windowClassName
iend

.bitmapHeader:
istruc BITMAPINFOHEADER
at BITMAPINFOHEADER.biSize,         dd BITMAPINFOHEADER_size
at BITMAPINFOHEADER.biWidth,        dd .defaultScreenWidth
at BITMAPINFOHEADER.biHeight,       dd -.defaultScreenHeight
at BITMAPINFOHEADER.biPlanes,       dw 1
at BITMAPINFOHEADER.biBitCount,     dw 8
at BITMAPINFOHEADER.biCompression,  dd 0 ;BI_BITFIELDS
at BITMAPINFOHEADER.biSizeImage,    dd .defaultScreenWidth*.defaultScreenHeight
at BITMAPINFOHEADER.biXPelsPerMeter,dd 0
at BITMAPINFOHEADER.biYPelsPerMeter,dd 0
at BITMAPINFOHEADER.biClrUsed,      dd 256
at BITMAPINFOHEADER.biClrImportant, dd 16
iend

align 4
.bitmapPalette:
    ;First  sixteen VGA colors.
    db 0x00*4,0x00*4,0x00*4,0, 0x00*4,0x00*4,0x2A*4,0, 0x00*4,0x2A*4,0x00*4,0, 0x00*4,0x2A*4,0x2A*4,0
    db 0x2A*4,0x00*4,0x00*4,0, 0x2A*4,0x00*4,0x2A*4,0, 0x2A*4,0x15*4,0x00*4,0, 0x2A*4,0x2A*4,0x2A*4,0
    db 0x15*4,0x15*4,0x15*4,0, 0x15*4,0x15*4,0x3F*4,0, 0x15*4,0x3F*4,0x15*4,0, 0x15*4,0x3F*4,0x3F*4,0
    db 0x3F*4,0x15*4,0x15*4,0, 0x3F*4,0x15*4,0x3F*4,0, 0x3F*4,0x3F*4,0x15*4,0, 0x3F*4,0x3F*4,0x3F*4,0
    
    times 256-16 dd 0FFFFFFh

; todo: synchronize this with the official palette.
.bitmapLogPalette:
    dw 300h
    dw 16                      ;number of colors
    db 0x00*4,0x00*4,0x00*4,0, 0x00*4,0x00*4,0x2A*4,0, 0x00*4,0x2A*4,0x00*4,0, 0x00*4,0x2A*4,0x2A*4,0
    db 0x2A*4,0x00*4,0x00*4,0, 0x2A*4,0x00*4,0x2A*4,0, 0x2A*4,0x15*4,0x00*4,0, 0x2A*4,0x2A*4,0x2A*4,0
    db 0x15*4,0x15*4,0x15*4,0, 0x15*4,0x15*4,0x3F*4,0, 0x15*4,0x3F*4,0x15*4,0, 0x15*4,0x3F*4,0x3F*4,0
    db 0x3F*4,0x15*4,0x15*4,0, 0x3F*4,0x15*4,0x3F*4,0, 0x3F*4,0x3F*4,0x15*4,0, 0x3F*4,0x3F*4,0x3F*4,0

section bss
align 4, resb 1
.msg:               resb MSG_size
.paintStruct:       resb PAINTSTRUCT_size
.dragAndDropFile:   resb MAX_PATH
.rect:
.point:             resb RECT_size      ;left,top,right,bottom
.vgaPalette:        resb 768

WinDosStackReg:     ;order of registers after using PUSHA
.edi equ 0
.esi equ 4
.ebp equ 8
.esp equ 12
.ebx equ 16
.edx equ 20
.ecx equ 24
.eax equ 28

%endif ;WinVer


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section code

WinDosInitialize:
%ifdef DosVer
    ; Nothing to initialize really.
    ret

%elifdef WinVer

    api GetCurrentThreadId
    mov [WinDos.threadId],eax

    call WinDosGetCommandLine

    api LoadCursor, 0,IDC_ARROW
    mov [WinDos.windowClass+WNDCLASS.hCursor],eax
    api LoadIcon, WinDos.baseAddress,1
    mov [WinDos.windowClass+WNDCLASS.hIcon],eax

    ; register window class
    debugwrite "registering class"
    api RegisterClass, WinDos.windowClass
    debugwrite "register result=%X", eax
    stringz .errorMessageRegisterClass,"Failed to register window class (RegisterClass)."
    mov esi,.errorMessageRegisterClass
    test eax,eax
    jz near WinDosExitWithErrorMsg

    ; create instance of window
    debugwrite "creating window"
    ; account for desired client region size.
    mov eax,[WinDos.displayWidth]
    mov ecx,[WinDos.displayHeight]
    mov [WinDos.rect+RECT.left],dword 0
    mov [WinDos.rect+RECT.top],dword 0
    mov [WinDos.rect+RECT.right],eax
    mov [WinDos.rect+RECT.bottom],ecx
    .WindowStyle equ WS_MINIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME|WS_BORDER ;WS_THICKFRAME
    api AdjustWindowRect, WinDos.rect, .WindowStyle, FALSE
    
    mov eax,[WinDos.rect+RECT.right]
    mov ecx,[WinDos.rect+RECT.bottom]
    sub eax,[WinDos.rect+RECT.left]
    sub ecx,[WinDos.rect+RECT.top]
    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT, WinDos.windowClassName, WinDos.programName, .WindowStyle, 0,0, eax,ecx, NULL, NULL, WinDos.baseAddress, NULL
    debugwrite "window handle=%X", eax
    stringz .errorMessageCreateWindow,"Failed to create window class (CreateWindow)."
    mov esi,.errorMessageCreateWindow
    test eax,eax
    jz near WinDosExitWithErrorMsg
    mov [WinDos.hwnd],eax

    ret
%endif ;WinVer


%ifdef WinVer
;-----------------------------------------------------------------------------
; Gets the command line from the OS.
; () (cf=error, esi=source, ecx=length)
WinDosGetCommandLine:
    mov esi,[WinDos.commandLine]
    test esi,esi
    jz .ReadCommandLineFromOs
    mov ecx,[WinDos.commandLineEnd]
    sub ecx,esi
    clc
    ret
    
.ReadCommandLineFromOs:
    push ebp
    mov ebp,esp

%ifdef DosVer
    mov eax,0006h               ;get segment base address
    mov bx,[WinDos.pspSelector]
    int 31h
    mov esi,ecx
    shl esi,16
    mov si,dx                   ;CX:DX = 32-bit linear base address of segment

    movzx ecx,byte [esi+80h]
    add esi,81h

%elifdef WinVer
    api GetCommandLine
    mov esi,eax
    ; call .GetWordLen            ;skip the first word, which is the module name.
    ; mov esi,ebx
    call .SkipLeadingSpaces
    api lstrlen, esi
    mov ecx,eax
    ;debugpause "command line = %s length = %d",esi,ecx
%endif

    mov [WinDos.commandLine],esi
    lea edx,[esi+ecx]
    mov [WinDos.commandLineEnd],edx
    clc
    mov esp,ebp
    pop ebp
    ret

; skip any separating space and return the new ptr
; (esi=param char ptr) (esi=new ptr; *)
.SlsNext:
    inc esi
.SkipLeadingSpaces:
    cmp byte [esi],' '
    je .SlsNext
    ret


;-------------------
; Determines length of word, up to next space, or within quotes.
; Mainly used to get filename, but can also be used for words following
; parameters.
; (esi=char ptr) (ecx=char length, ebx=ptr to following char; esi=first char)
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
    cmp al,13                   ;for DOS when normal command line start
    je .GwlEnd
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


;-----------------------------------------------------------------------------
; Parses the command line into an array of pointers.
; (ecx=word count, eax=array of word pointers, cf=error)
WinDosParseCommandLine:
    push esi, edi

    call WinDosGetCommandLine; esi=command line, ecx=char count
    debugwrite "full command line %s", esi

    ;memcpy min(WinDos.commandLineParsedBufferMax, WinDos.commandLineEnd - WinDos.commandLine)
    mov eax,WinDos.commandLineParsedBufferMax
    cmp ecx,eax
    jb .SizeOkay
    mov ecx,eax
.SizeOkay:
    mov edi,WinDos.commandLineParsedBuffer
    rep movsb

    ; Zero loop counter, and point to the buffer to parse in-place,
    ; adding nulls where needed.
    xor edi,edi
    mov esi,WinDos.commandLineParsedBuffer
    mov [WinDos.commandLineParameterCount],edi

.NextWord:
    call WinDosGetCommandLine.SkipLeadingSpaces
    call WinDosGetCommandLine.GetWordLen
    test ecx,ecx
    jz .End
    mov [WinDos.commandLineParameters+edi*4],esi
    mov byte [esi+ecx],0                ;null terminator
    inc edi
    mov esi,ebx
    inc esi                             ;skip trailing space
    mov [WinDos.commandLineParameterCount],edi
    cmp edi, WinDos.commandLineParameterMax
    jb .NextWord
.End:
    mov ecx,edi
    mov eax,WinDos.commandLineParameters
    pop esi,edi
    ret


WinDosGetMessage:
; ()->() ebx,esi,edi preserved
    xor eax,eax
    api GetMessage, WinDos.msg, eax,eax,eax
    test eax,eax
    jle .Quit
.HaveMessage:
    mov byte [WinDos.isActive],2
    debugwinmsg "process msg=%X %s W=%X L=%X", [WinDos.msg+MSG.message],edx,[WinDos.msg+MSG.wParam],[WinDos.msg+MSG.lParam]

    ;api IsDialogMessage, [WinDos.hwnd],WinDos.msg
    ;test eax,eax
    ;jnz .MessageHandled
    api TranslateMessage, WinDos.msg
.MessageHandled:
    api DispatchMessage, WinDos.msg
    ret
.Quit:
    mov byte [WinDos.isActive],0
    ret

WinDosPeekMessage:
; ()->() ebx,esi,edi preserved
    xor eax,eax
    api PeekMessage, WinDos.msg, eax,eax,eax,PM_REMOVE
    test eax,eax
    jnz near WinDosGetMessage.HaveMessage
    mov byte [WinDos.isActive],1
    cmp dword [WinDos.msg+MSG.message],WM_QUIT
    je WinDosGetMessage.Quit
.NoMessage:
    ret


;----------------------------------------
; Termination
WinDosExitProcess:
    ;debugpause "ending"
    api DestroyWindow, [WinDos.hwnd]
    api ExitProcess, [WinDos.msg+MSG.wParam]

;----------------------------------------
; (esi=error message ptr)
WinDosExitWithErrorMsg:
    debugwrite "exiting process from fatal error: %s", esi
    api MessageBox, [WinDos.hwnd],esi,WinDos.programName,MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL ;|MB_SETFOREGROUND
    api DestroyWindow, [WinDos.hwnd]
    api ExitProcess, -1

;----------------------------------------
WinDosMessageProc:
    push ebp
    push ebx
    push esi
    push edi
    mov ebp,esp
    params ebp+4+(4*4), .hwnd, .message, .wParam, .lParam

    mov eax,[.message]
    debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[.wParam+4],[.lParam]

    cmp eax,WM_KEYDOWN
    je near .KeyDown
    cmp eax,WM_CHAR
    je near .KeyChar
    cmp eax,WM_PAINT
    je near .Paint
    cmp eax,WM_MOUSEFIRST
    jb .NotMouseMessage
    cmp eax,WM_MOUSELAST_BUTTON
    jbe near .MouseMessage
.NotMouseMessage:
    ;;cmp byte [WinDos.msg+MSG.wParam],VK_ESCAPE
    ;;je near .EscPress
    ;;.NotKey:
    ;;cmp eax,WM_COMMAND
    ;;jne .NotCommand
    ;;cmp word [.wParam+2],BN_CLICKED
    ;;je near .Command
    ;;.NotCommand:
    ;;cmp eax,WM_TIMER
    ;;je near .FlashTitle
    ;;cmp eax,WM_ACTIVATE
    ;;je near .Activate
    ;;cmp eax,WM_SYSCOMMAND
    ;;je near .Minimize
    cmp eax,WM_ERASEBKGND
    je .RetTrue
    cmp eax,WM_CREATE
    je near .Create
    ;cmp eax,WM_WINDOWPOSCHANGED
    ;je .RetFalse
    ;cmp eax,WM_WINDOWPOSCHANGING
    ;je .RetFalse
    cmp eax,WM_DROPFILES
    je near .FileDropped
    cmp eax,WM_DESTROY
    je near .Destroy

.DefProc:
    pop edi
    pop esi
    pop ebx
    pop ebp
    apijump DefWindowProc, 4 ;param count

.RetTrue:
    mov eax,TRUE
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret 16

.RetFalse:
    xor eax,eax
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret 16

.Destroy:
    ;debugpause "destroying window"
    mov dword [WinDos.hwnd],0
    api PostQuitMessage,0
    jmp .RetFalse

.Paint:
    if [WinDos.vgaColorPaletteIsDirty],ne,dword 0
        call WinDosUpdatePalette
    endif

    api BeginPaint, [.hwnd],WinDos.paintStruct
    xor eax,eax
    ;todo: figure out how to update a DIB section palette after created,
    ;      so we don't have to call SetDIBitsToDevice every time.
    ;api BitBlt, [WinDos.hdc],eax,eax,[WinDos.displayWidth],[WinDos.displayHeight], [WinDos.hdcc],eax,eax, SRCCOPY
    api SetDIBitsToDevice, [WinDos.hdc],eax,eax, [WinDos.displayWidth],[WinDos.displayHeight],eax,eax, eax,[WinDos.displayHeight], [WinDos.displayMemoryBase],WinDos.bitmapHeader,DIB_RGB_COLORS
    
    api EndPaint, [.hwnd],WinDos.paintStruct

    jmp .RetFalse

.KeyDown:
    xor ebx,ebx                         ;no key modifiers by default
    api GetKeyState, VK_SHIFT
    shl al,1                            ;key is down if 80h is set
    rcl ebx,1                           ;set MOD_SHIFT
    api GetKeyState, VK_CONTROL
    shl al,1
    rcl ebx,1                           ;set MOD_CONTROL
    api GetKeyState, VK_MENU
    shl al,1
    rcl ebx,1                           ;set MOD_ALT
    
section data
    ; Just a subset of extended keys (the ones I actually care about).
    .KeyCodeEntry_size equ 4
    .KeyCodeEntryVirtualKey equ 0
    .KeyCodeEntryModifier equ 1
    .KeyCodeEntryBiosCode equ 2
    %macro KeyCodeEntry 3
        db %1,%2
        dw %3
    %endmacro
.KeyCodeTable:
    KeyCodeEntry VK_F1,0,03B00h
    KeyCodeEntry VK_F2,0,03C00h
    KeyCodeEntry VK_F3,0,03D00h
    KeyCodeEntry VK_F4,0,03E00h
    KeyCodeEntry VK_F5,0,03F00h
    KeyCodeEntry VK_F6,0,04000h
    KeyCodeEntry VK_F7,0,04100h
    KeyCodeEntry VK_F8,0,04200h
    KeyCodeEntry VK_F9,0,04300h
    KeyCodeEntry VK_F10,0,04400h
    KeyCodeEntry VK_F11,0,08500h
    KeyCodeEntry VK_F12,0,08600h
    KeyCodeEntry VK_UP,0,04800h
    KeyCodeEntry VK_DOWN,0,05000h
    KeyCodeEntry VK_LEFT,0,04B00h
    KeyCodeEntry VK_RIGHT,0,04D00h
    KeyCodeEntry VK_HOME,0,04700h
    KeyCodeEntry VK_END,0,04F00h
    KeyCodeEntry VK_NEXT,MOD_CONTROL,07600h
    KeyCodeEntry VK_PRIOR,MOD_CONTROL,08400h
    KeyCodeEntry VK_LEFT,MOD_CONTROL,07300h
    KeyCodeEntry VK_RIGHT,MOD_CONTROL,07400h
    KeyCodeEntry VK_HOME,MOD_CONTROL,07700h
    KeyCodeEntry VK_END,MOD_CONTROL,07500h
    KeyCodeEntry VK_INSERT,0,05200h
    KeyCodeEntry VK_DELETE,0,05300h
    KeyCodeEntry VK_NEXT,0,05100h
    KeyCodeEntry VK_PRIOR,0,04900h
    %undef KeyCodeEntry
.KeyCodeTableEnd:
section code

    mov eax,[.wParam]
    mov esi,.KeyCodeTable
    xor edx,edx
.KeyDownNextCheck:
    ifall [esi+.KeyCodeEntryVirtualKey],e,al,   [esi+.KeyCodeEntryModifier],e,bl
        mov dx,[esi+.KeyCodeEntryBiosCode]
        jmp short .KeyDownFoundMatch
    endif
    add esi,byte .KeyCodeEntry_size
    cmp esi,.KeyCodeTableEnd
    jl .KeyDownNextCheck
.KeyDownFoundMatch:
    mov [WinDos.biosKeyCode],edx
    jmp .RetFalse
    
.KeyChar:
    mov edx,[.lParam]
    mov eax,[.wParam]
    ;The BIOS did not understand Unicode.
    if eax,le,0FFh
        ;Merge the scan code with the key character.
        shr edx,8
        and eax,000FFh
        and edx,0FF00h
        or eax,edx
        mov [WinDos.biosKeyCode],eax
    endif
    jmp .RetFalse

.FileDropped:
    debugpause "File dropped"
    api DragQueryFile, [.wParam],0, WinDos.dragAndDropFile,MAX_PATH
    api DragFinish, [.wParam]
    debugpause "End File dropped"
    jmp .RetFalse

.Create:
    mov eax,[.hwnd]
    mov [WinDos.hwnd],eax
    api GetDC, eax              ;get window class display handle
    debugwrite "get hdc=%X",eax
    mov [WinDos.hdc],eax

    api CreateCompatibleDC, eax
    stringz .errorMessageNoCompatibleDc,"Could not create main window compatible device context (CreateCompatibleDC)."
    mov esi,.errorMessageNoCompatibleDc
    test eax,eax
    jz near WinDosExitWithErrorMsg
    mov [WinDos.hdcc],eax

    ;TODO: Update bitmapHeader to respect changes to WinDos.displayWidth.
    ;mov eax,[WinDos.displayHeight]
    ;mov [WinDos.bitmapHeader...],dword eax

    api CreateDIBSection, [WinDos.hdcc],WinDos.bitmapHeader,DIB_RGB_COLORS, WinDos.displayMemoryBase,NULL,NULL
    stringz .errorMessageNoDibSection,"Could not create main window DIB section to render into (CreateDIBSection)."
    mov esi,.errorMessageNoDibSection
    test eax,eax
    jz near WinDosExitWithErrorMsg
    mov [WinDos.hdib],eax
    
    api SelectObject, [WinDos.hdcc],eax

    %if 0 ;Not really necessary on modern displays. Only if in 256-color mode would it matter.
    api CreatePalette, WinDos.bitmapLogPalette
    mov [WinDos.hpal],eax               ;store logical palette handle
    stringz .errorMessageNoPalette,"Could not create main window palette (CreatePalette)."
    mov esi,.errorMessageNoPalette
    test eax,eax
    jz near WinDosExitWithErrorMsg
    api SelectPalette, [WinDos.hdcc],eax,FALSE
    api RealizePalette, [WinDos.hdcc]
    %endif

    jmp .RetFalse

.MouseMessage:
    ; todo: Record mouse position
    jmp .RetFalse
    
    
WinDosUpdatePalette:
    mov esi,WinDos.vgaPalette
    mov edi,WinDos.bitmapPalette
    mov ecx,256
.NextEntry:
    mov eax,[esi]
    ;*4 because old VGA ranges 0..63
    shl eax,2
    mov edx,eax
    rol eax,16                              ;swap blue and red (also messes up green though)
    and edx,00FF00h                         ;mask only green
    and eax,0FF00FFh                        ;mask red and blue
    or eax,edx
    mov [edi],eax
    add esi,byte 3
    add edi,byte 4
    dec ecx
    jnz .NextEntry
    mov byte [WinDos.vgaColorPaletteIsDirty],0
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WinDosInt10h: ;Video BIOS
    ;mov ah,0                   ; 3 - boring text mode, 13 - 320x200
    ;mov ah,2                   ;function to set cursor
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WinDosInt16h: ;BIOS
    pusha
    cmp ah,0                    ;function to get or wait for key press
    je .00
    cmp ah,1                    ;function to check key buffer status
    je .01
    ;Unsupported BIOS function
    mov dword [esp+WinDosStackReg.eax],0x8000; ;return invalid function in ah
.ReturnFailure:
    xor eax,eax
    stc                         ;set carry flag for success
    popa
    ret
.ReturnSuccess:
    popa
    clc                         ;clear carry flag for success
    ret
.00: ;read keyboard and wait for keypress
    mov eax,[WinDos.biosKeyCode]
    mov dword [WinDos.biosKeyCode],0
    mov [esp+WinDosStackReg.eax],eax
    test eax,eax
    jnz .ReturnSuccess
    WinDosWaitForEvent WinDosExitProcess
    jmp short .00
.01: ;check key buffer status
    mov eax,[WinDos.biosKeyCode]
    cmp eax,0
    mov [esp+WinDosStackReg.eax],eax
    je .ReturnFailure
    jmp short .ReturnSuccess


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WinDosInt21h: ; DOS
; Only some of the functions are implemented, which are those functions that my apps actually use.
; Those with asterisks matter. Anything else returns an error.
;
; API comments taken from the WDOSX extender readme file.
;
; Function 02h  Write character to console
; Function 09h  Write string to console
; Function 1Ah  Set disk transfer area address
; Function 1Bh  Get allocation information for default drive
; Function 1Ch  Get allocation information for specific drive
; Function 1Fh  Get drive parameter block for default drive
; Function 25h  Set interrupt vector
; Function 2Fh  Get disk transfer area address
; Function 32h  Get drive parameter block for specific drive
; Function 34h  Get address of InDos flag
; Function 35h  Get interrupt vector
; Function 39h  Create subdirectory
; Function 3Ah  Remove subdirectory
; Function 3Bh  Change current directory
;*Function 3Ch  Create new file
;*Function 3Dh  Open existing file
;*Function 3Fh  Read from file
;*Function 40h  Write to file
; Function 41h  Delete file
;*Function 42h  Get/set file position
; Function 43h  Get/set file attributes
; Function 44h  IOCTL
; Function 47h  Get current directory
; Function 48h  Allocate DOS memory block
; Function 49h  Free DOS memory block
; Function 4Ah  Resize DOS memory block
; Function 4Bh  Load and execute child program
;*Function 4Eh  Find first matching file
;*Function 4Fh  Find next matching file
; Function 56h  Rename file
; Function 5Ah  Create temporary file
;*Function 5Bh  Create new file

    pusha
    cmp ah,.FunctionTableSize
    jae .XX
    movzx edi,ah
    jmp [.FunctionTable+edi*4]
.XX:
.ReturnFailureFromLastError:
    api GetLastError
    mov [esp+WinDosStackReg.eax],eax
    ; TODO: Map error from GetLastError to actual DOS error code.
.ReturnFailure:
    debugwrite "int 21h failure, win error=%d", eax
    popa
    stc                     ;flag error to caller
    ret
.ReturnSuccess:
    popa
    clc
    ret

; --------------------------------------
; Function 09h - Write string to console
;
;  AH = 09h
;  DS:EDX -> '$'-terminated string
;
; Note: The size of the string must be less or equal 16k since this is the
; transfer buffer size of WDOSX.
;
.09:
.WriteString:
    debugwrite "int 21h 09 write string, '%d'", edx
    xor ecx,ecx
    jmp short .WriteStringFindEnd
.WriteStringNextChar:
    inc ecx
.WriteStringFindEnd:
    cmp byte [edx+ecx],'$'
    jne .WriteStringNextChar

    push edx, ecx
    api GetStdHandle, STD_INPUT_HANDLE
    mov ebx, eax
    pop edx, ecx

    api WriteConsole, ebx,edx,ecx,WinDos.dummyUint32,NULL
    test eax,eax
    je .ReturnFailureFromLastError
    jmp .ReturnSuccess

; ---------------------------------------------
; Function 1Ah - Set disk transfer area address
;
;  AH = 1Ah
;  DS:EDX -> Disk Transfer Area
;
; Note: WDOSX  will keep  an internal  buffer for  the  DTA. Upon  any Find
; First/ Find Next call, WDOSX does the necessary copying to make this call
; transparent for the user program.
;

; -----------------------------------------------------------
; Function 1Bh - Get allocation information for default drive
;
;  AH = 1Bh
;
; Returns
;
;  AL = sectors per cluster
;  CX = bytes per sector
;  DX = total number of clusters
;  DS:EBX -> media ID byte
;

; ------------------------------------------------------------
; Function 1Ch - Get allocation information for specific drive
;
;  AH = 1Bh
;  DL = drive (0 = default, 1 = A: etc.)
;
; Returns
;
;  AL = sectors per cluster
;  CX = bytes per sector
;  DX = total number of clusters
;  DS:EBX -> media ID byte
;

; ----------------------------------------------------------
; Function 1Fh - Get drive parameter block for default drive
;
;  AH = 1Fh
;
; Returns
;
;  AL = status (0 = success, -1 = invalid drive)
;  DS:EBX -> Drive Parameter Block
;

; -----------------------------------  AH = 25h
; Function 25h - Set interrupt vector
;
;  AL = interrupt number
;  DS:EDX -> new interrupt handler
;
; Note: This function sets  the protected mode interrupt  vector using DPMI
; call 0205h.
;

; ---------------------------------------------
; Function 2Fh - Get disk transfer area address
;
;  AH = 2Fh
;
; Returns
;
;  ES:EBX -> Disk Transfer Area
;
; Note: If no DTA address  is set, the default DTA  address at PSP:80h will
; be returned, otherwise the return  pointer is the same  as last passed to
; function 1Ah.
;

; -----------------------------------------------------------
; Function 32h - Get drive parameter block for specific drive
;
;  AH = 32h
;  DL = drive number (0 = default, 1 = A: etc.)
;
; Returns
;
;  AL = status (0 = success, -1 = invalid drive)
;  DS:EBX -> Drive Parameter Block
;

; ----------------------------------------
; Function 34h - Get address of InDos flag
;
;  AH = 34h
;
; Returns
;
;  ES:EBX -> InDos flag
;

; -----------------------------------
; Function 35h - Get interrupt vector
;
;  AH = 35h
;  AL = interrupt number
;
; Returns
;
;  ES:EBX -> address of interrupt handler
;
; Note: This function returns  the address of the  protected mode interrupt
; handler as obtained using DPMI call 0204h.
;

; ----------------------------------
; Function 39h - Create subdirectory
;
;  AH = 39h
;  DS:EDX -> ASCIZ pathname
;
; Returns
;
;  CF = clear on success, set on error (AX = error code)
;

; ----------------------------------
; Function 3Ah - Remove subdirectory
;
;  AH = 3Ah
;  DS:EDX -> ASCIZ pathname
;
; Returns
;  CF = clear on success, set on error (AX = error code)
;

; ---------------------------------------
; Function 3Bh - Change current directory
;
;  AH = 3Bh
;  DS:EDX -> ASCIZ pathname
;
; Returns
;
;  CF = clear on success, set on error (AX = error code)
;

; ------------------------------
; Function 3Ch - Create new file
;
;  AH = 3Ch
;  CX = file attributes
;  DS:EDX -> ASCIZ filename
;
; Returns
;
;  CF = clear on success (AX = file handle)
;  CF = set on error (AX = error code)
;
.3C:
.CreateNewFile:
    debugwrite "int 21h 3C CreateNewFile, filename='%d'", edx
    xor eax,eax
    api CreateFileA, edx, GENERIC_READ|GENERIC_WRITE,FILE_SHARE_READ, eax, CREATE_ALWAYS, eax,eax
    cmp eax,INVALID_HANDLE_VALUE
    mov [esp+WinDosStackReg.eax],eax
    je .ReturnFailureFromLastError
    jmp .ReturnSuccess

; ---------------------------------
; Function 3Dh - Open existing file
;
;  AH = 3Dh
;  AL = access mode
;  DS:EDX -> ASCIZ filename
;
; Returns
;
;  CF = clear on success (AX = file handle) set on error (AX = error code)
;
;
; Sharing mode bits (DOS 3.1+):	       Access mode bits:
;  654                                    210
;  000  compatibility mode (exclusive)    000  read access
;  001  deny others read/write access     001  write access
;  010  deny others write access          010  read/write access
;  011  deny others read access
;  100  full access permitted to all
;
.3D:
.OpenExistingFile:
    debugwrite "int 21h 3D OpenExistingFile, filename='%s'", edx
    xor eax,eax

    mov ecx,GENERIC_READ
    test al,00000011b
    jz .OpenExistingFileNoWrite
    or ecx,GENERIC_WRITE
.OpenExistingFileNoWrite:

    api CreateFileA, edx, ecx,FILE_SHARE_READ, eax, OPEN_EXISTING, eax,eax
    cmp eax,INVALID_HANDLE_VALUE
    mov [esp+WinDosStackReg.eax],eax
    je .ReturnFailureFromLastError
    jmp .ReturnSuccess

; -----------------------------
; Function 3Fh - Close file handle
;
;  AH = 3E
;  BX = file handle to close
;
; Returns:
;
;  AX = error code if CF set
;
; - if file is opened for update, file time and date stamp
;   as well as file size are updated in the directory
; - handle is freed
.3E:
.CloseFile:
    debugwrite "int 21h 3E CloseHandle"
    api CloseHandle, ebx
    test eax,eax
    je .ReturnFailureFromLastError
    jmp .ReturnSuccess

; -----------------------------
; Function 3Fh - Read from file
;
;  AH = 3Fh
;  BX = file handle
;  ECX = number of bytes to read
;  DS:EDX -> data buffer
;
; Returns
;
;  CF = clear on success (EAX = number of bytes actually read)
;  CF = set on error (AX = error code)
;
; Note: This  function allows for  reading up  to 4  gigabytes at  once (in
; theory, that is.) There is no 64k limitation as in pure DOS.
;
.3F:
.ReadFromFile:
    api ReadFile, ebx,edx,ecx,WinDos.dummyUint32,NULL
    test eax,eax
    je .ReturnFailureFromLastError
    jmp .ReturnSuccess

; ----------------------------
; Function 40h - Write to file
;
;  AH = 40h
;  BX = file handle
;  ECX = number of bytes to write
;  DS:EDX -> data buffer
;
; Returns
;
;  CF = clear on success (EAX = number of bytes actually written)
;  CF = set on error (AX = error code)
;
; Note: This  function allows for  writing up  to 4  gigabytes at  once (in
; theory, that is.) There is no 64k limitation as in pure DOS.
;
.40:
.WriteToFile:
    api WriteFile, ebx,edx,ecx,WinDos.dummyUint32,NULL
    test eax,eax
    je .ReturnFailureFromLastError
    jmp .ReturnSuccess

; --------------------------
; Function 41h - Delete file
;
;  AH = 41h
;  DS:EDX -> ASCIZ filename
;
; Returns
;
;  CF = clear on success, set on error (AX = error code)
;
.41:
.DeleteFile:
    api DeleteFileA, edx
    test eax,eax
    je .ReturnFailureFromLastError
    jmp .ReturnSuccess

; -------------------------------
; Function 42h - Set file pointer
;
;  AH = 42h
;  AL = move method
;  BX = file handle
;  CX:DX = offset
;
; Returns
;
;  CF = clear on success (DX:AX = new file pointer)
;  CF = clear on success, set on error (AX = error code)
.42:
.SetFilePointer:
    movzx eax,al                        ;get positioning mode, al->(0=FILE_BEGIN...)

    ; Coalesce from dx:ax into 32-bit value.
    movzx edx,dx                        ;combine lower 16 bits in dx with upper in cx
    shl ecx,16
    or edx,ecx

    api SetFilePointer, ebx, edx, NULL, eax
    mov [esp+WinDosStackReg.eax],eax
    cmp eax,INVALID_SET_FILE_POINTER
    je .ReturnFailureFromLastError

    ; Split from 32-bit value back into dx:ax
    mov edx,eax
    shr edx,16
    mov [esp+WinDosStackReg.edx],edx
    jmp .ReturnSuccess

; --------------------------------------
; Function 43h - Get/set file attributes
;
;  AH = 43h
;  AL = subfunction (0 = get, 1 = set)
;  DS:EDX -> ASCIZ filename
;
;  IF AL = 1: CX = file attributes
;
; Returns
;
;  CF = clear on success, set on error (AX = error code)
;  CX = file attributes
;

; --------------------
; Function 44h - IOCTL
;
;  AH = 44h
;  AL = subfunction
;
; The following subfunctions are extended:
;
;  AL = 2 (read from character device control channel)
;  BX = file handle
;  ECX = number of bytes to read
;  DS:EDX -> buffer
;
; Returns
;
;  CF = clear on success (EAX = number of bytes actually read)
;  CF = set on error (AX = error code)
;
; Note: This  function allows for  reading up  to 4  gigabytes at  once (in
; theory, that  is.) There  is no  64k limitation  as  in pure  DOS. Before
; calling the actual DOS function, max  (ECX,16k) bytes will be copied from
; DS:EDX into the  real mode transfer  buffer to allow  for passing request
; structures.
;
;  AL = 3 (write to character device control channel)
;  BX = file handle
;  ECX = number of bytes to write
;  DS:EDX -> data buffer
;
; Returns
;
;  CF = clear on success (EAX = number of bytes actually written)
;  CF = set on error (AX = error code)
;
; Note: This function allows for writing up to 4 gigabytes at once (in
; theory, that is.) There is no 64k limitation as in pure DOS.
;
;  AL = 4 (read from block device control channel)
;  BL = drive number (0 = default, 1 = A: etc.)
;  ECX = number of bytes to read
;  DS:EDX -> buffer
;
; Returns
;
;  CF = clear on success (EAX = number of bytes actually read)
;  CF = set on error (AX = error code)
;
;  Note: This  function allows for reading up  to 4  gigabytes at  once (in
; theory, that  is.) There  is no  64k limitation  as  in pure  DOS. Before
; calling the actual DOS function, max  (ECX,16k) bytes will be copied from
; DS:EDX into the  real mode transfer  buffer to allow  for passing request
; structures.
;
;  AL = 5 (write to block device control channel)
;  BL = drive number (0 = default, 1 = A: etc.)
;  ECX = number of bytes to write
;  DS:EDX -> data buffer
;
; Returns
;
;  CF = clear on success (EAX = number of bytes actually written)
;  CF = set on error (AX = error code)
;
; Note: This  function allows for  writing up  to 4  gigabytes at  once (in
; theory, that is.) There is no 64k limitation as in pure DOS.
;

; ------------------------------------
; Function 47h - Get current directory
;
;  AH = 47h
;  DL = drive number (0 = default, 1 = A: etc.)
;  DS:ESI -> 64 byte buffer to receive ASCIZ pathname
;
; Returns
;
;  CF = clear on success, set on error (AX = error code)
;

; ----------------------------------------
; Function 48h - Allocate DOS memory block
;
;  AH = 48h
;  BX = number of paragraphs to allocate
;
; Returns
;
;  CF = clear on success, (AX = selector of allocated block)
;  CF = set on error, (AX = error code, bx = size of largest block)
;

; ------------------------------------
; Function 49h - Free DOS memory block
;
;  AH = 49h
;  ES = selector of block to free
;
; Returns
;
;  CF = clear on success, set on error (AX = error code)
;

; --------------------------------------
; Function 4Ah - Resize DOS memory block
;
;  AH = 4Ah
;  BX = new size in paragraphs
;  ES = selector of block to resize
;
; Returns
;
;  CF = clear on success set on error, (AX = error code, bx = max. size
;  available)
;

; ---------------------------------------------
; Function 4Bh - Load and execute child program
;
;  AH = 4BH
;  AL = 0 (other subfunctions NOT supported)
;  DS:EDX -> ASCIZ filename of the program to execute
;  ES:EBX -> parameter block (see below)
; Returns
;
;  CF clear on success, set on error (AX = error code)
;
; Note: Unlike  under pure  DOS, under  WDOSX the  format of  the parameter
; block is as follows:
;
; Offset 00000000: 48 bit protected mode far pointer to environment string
; Offset 00000006: 48 bit protected mode far pointer to command tail
;
; This is the method most other DOS extenders  also use, so there should be
; no significant compatibility problems.
;

; ---------------------------------------
; Function 4Eh - Find first matching file
;
;  AH = 4Eh
;  AL = flag used by APPEND
;  CX = attribute mask
;  DS:EDX -> ASCIZ file name (may include path and wildcards)
;
; Returns
;
;  CF = clear on success (DTA as set with function 1Ah filled)
;  CF = set on error (AX = error code)
;
%if 0 ;TODO:
.4E:
.FindFirstFile: 
    mov esi,BgFilePath
    call GetFileName
    mov dword [esi],'*'
    api FindFirstFile, BgFilePath,FindFileData
    mov byte [esi],0
    test eax,eax
    mov ebx,eax
    js .LastFile

    api FindClose, ebx

%endif ;if 0

; --------------------------------------
; Function 4Fh - Find next matching file
;
;  AH = 4Fh
;  DTA as set with function 1Ah contains information from previous Find
;  First call (function 4Eh)
;
; Returns
;
;  CF = clear on success (DTA as set with function 1Ah filled)
;  CF = set on error (AX = error code)
;
%if 0 ;TODO:
.4F:
.NextFile:
    mov esi,FindFileData+WIN32_FIND_DATA.cFileName
    test byte [FindFileData+WIN32_FIND_DATA.dwFileAttributes],FILE_ATTRIBUTE_DIRECTORY
    jz .NotDir
    cmp byte [esi],'.'
    api FindNextFile, ebx,FindFileData
    test eax,eax
    jnz .NextFile
.LastFile:

    api FindClose, ebx

%endif ;if 0

; --------------------------
; Function 56h - Rename file
;
;  AH = 56h
;  DS:EDX -> ASCIZ filename
;  ES:EDI -> ASCIZ new filename
;
; Returns
;
;  CF = clear on success, set on error (AX = error code)
;

; ------------------------------------
; Function 5Ah - Create temporary file
;
;  AH = 5Ah
;  CX = attributes
;  DS:EDX -> buffer containing path name ending with "\" + 13 zero bytes
;
; Returns
;
;  CF = clear on success, filename appended to path name in buffer (AX =
;  file handle)
;  CF = set on error (AX = error code)
;

; ------------------------------
; Function 5Bh - Create new file
;
;  AH = 5Bh
;  CX = attributes
;  DS:EDX -> ASCIZ filename
;
; Returns
;
;  CF = clear on success, (AX = file handle)
;  CF = set on error (AX = error code)
.5B equ .CreateNewFile

.4C equ WinDosExitProcess ;Terminate program

section data
.FunctionTableSize equ 60h
.FunctionTable:
    ;   00  01  02  03  04  05  06  07  08  09  0A  0B  0C  0D  0E  0F
    dd .XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.09,.XX,.XX,.XX,.XX,.XX,.XX ; 00
    dd .XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX ; 10
    dd .XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX ; 20
    dd .XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.3C,.3D,.3E,.3F ; 30
    dd .40,.41,.42,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.4C,.XX,.XX,.XX ; 40
    dd .XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.XX,.5B,.XX,.XX,.XX,.XX ; 50

section code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WinDosInt31h: ;DPMI
    ;mov    ecx,edx             ; no, bx:cx holds amount to allocate
    ;shld   ebx,edx,16          ; get high word of edx into bx
    ;mov    ax,$501             ; allocate memory
    ;int    $31

    ;sub    esp,54              ; space for the 48 byte buffer
    ;mov    edi,esp             ; edi->buffer to hold information
    ;mov    ax,$0500            ; get free memory information
    ;int    $31
    ;pop    edx             ; edx holds largest free memory block
    ;lea    esp,[esp + 50]          ; correct stack

    ;mov    si,[_myheap_handlesi]       ; de-allocate heap
    ;mov    di,[_myheap_handledi]
    ;mov    ax,$0502
    ;int    $31

    stc
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WinDosInt33h: ;Mouse
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WinDosReadPort:
    pushf
    pusha
    movzx eax,al
    movzx edx,dx
    cmp edx,3C9h
    je .ReadVgaColorDataRegister
    xor eax,eax             ;any other port is unrecognized
.RegisterReturn:
    popa
    popf
    ret

.ReadVgaColorDataRegister: ;3C9h
    ;read the existing RBG entry, and advance the index.
    mov edx,[WinDos.vgaColorReadRegisterIndex]
    mov al,[WinDos.vgaPalette+edx]
    inc edx                                 ;advance next color byte each read
    if edx,ae,768
        xor edx,edx
    endif
    mov [WinDos.vgaColorReadRegisterIndex],edx
    mov [esp+WinDosStackReg.eax],al
    jmp .RegisterReturn


WinDosWritePort:
    pushf
    pusha
    movzx eax,al
    movzx edx,dx
    cmp edx,3C7h
    je .WriteVgaColorReadRegister
    cmp edx,3C8h
    je .WriteVgaColorWriteRegister
    cmp edx,3C9h
    je .WriteVgaColorDataRegister
.RegisterReturn:
    popa
    popf
    ret

.WriteVgaColorReadRegister: ;3C7h
    shl eax,2               ;*4
    mov [WinDos.vgaColorReadRegisterIndex],eax
    jmp .RegisterReturn
    
.WriteVgaColorWriteRegister: ;3C8h
    lea eax,[eax*2+eax]
    mov [WinDos.vgaColorWriteRegisterIndex],eax
    jmp .RegisterReturn
    
.WriteVgaColorDataRegister: ;3C9h
    ;store the new RBG entry, and advance the index.
    mov edx,[WinDos.vgaColorWriteRegisterIndex]
    mov [WinDos.vgaPalette+edx],al
    inc edx                                 ;advance next color byte every write
    if edx,ae,768
        xor edx,edx
    endif
    mov [WinDos.vgaColorWriteRegisterIndex],edx
    mov byte [WinDos.vgaColorPaletteIsDirty],1
    jmp .RegisterReturn

%endif ;WinVer
