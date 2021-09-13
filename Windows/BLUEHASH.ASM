; Blue Hash: Test window that uses DirectDraw
; 2002-03-02 / 2004-07-02
; Dwayne Robinson
;
; Purpose:
;	Draws a blue hash over the entire screen, allowing you to watch the partial
;	redraws of programs. Supports 8/16/24/32 bit displays.
;
; Learned:
;	'Restore' does not restore lost surfaces after the video mode (either the
;	bits or resolution) has been changed by another program (like the
;	Desktop properties). Instead, the primary surface must be recreated.
;
;	Every display tested has the lowest byte as blue. So bits 0-7 are blue,
;	8-15 are green, and 16-23 are red (24-31 are ignored on 32bit displays).
;
; History:
;	2002-03-02	Created test program
;				Added DirectDraw blitting to 8/16 bit displays
;				Mouse hover over window clears screen
;				Add About on click
;	2004-07-02	Updated to support 24/32 bit displays
;	2004-08-15	Added program icon (a blue circle)
;				Added F12 hotkey to clear screen

;%define debug
%define UseWindowStyles
%define UseWindowGfx
%define UseWindowMsgs
%define UseWindowConsole
%define UseWindowControls
%define UseDxDraw
%define UseKeyboard
%include "mywininc.asm"

section .text

;_____________________________________________________________________________
section code
global Main
global _main
_main:
Main:
    params .Instance, .PrevInstance, .CmdLine, .CmdShow

    debugwrite "program started"

    api GetModuleHandle, NULL
    mov [wc+WNDCLASS.hInstance],eax
    api LoadIcon, eax, 1
    mov [wc+WNDCLASS.hIcon],eax
    ;debugwrite "instance handle from get module=%X",eax

    ; register window class
    debugwrite "registering class"
    api RegisterClass, wc
    debugwrite "register result=%X", eax
    test eax,eax
    mov esi,ErrMsgRegWin
    jz near EndWithErrMsg

    ; create instance of window
    debugwrite "creating window"
    ;api CreateWindowEx, 0, AppName, AppName, WS_POPUP | WS_VISIBLE, 0,0, 120,100, NULL, NULL, [wc+WNDCLASS.hInstance], NULL
    ;api CreateWindowEx, 0, AppName, Instructions,WS_SYSMENU|WS_CAPTION|WS_POPUP|WS_VISIBLE, 0,0, 200,90, NULL, NULL, [wc+WNDCLASS.hInstance], NULL
    api CreateWindowEx, WS_EX_TOPMOST, AppName, Title,WS_SYSMENU|WS_DLGFRAME|WS_VISIBLE|WS_MINIMIZEBOX, 0,0, 200,74, NULL, NULL, [wc+WNDCLASS.hInstance], NULL
    ;                      class    title                                pos      size    parent no menu
    debugwrite "window handle=%X", eax
    test eax,eax
    mov esi,ErrMsgWinCreate
    jz near EndWithErrMsg
    mov [hwnd],eax

    ; initialize direct draw
    debugwrite "initializing direct draw"
    api DirectDrawCreate, NULL,DxDraw,NULL
    ;debugwrite "direct draw result=%X",eax
    test eax,eax
    mov esi,ErrMsgDxInit
    js near EndWithErrMsg

    debugwrite "setting cooperative level"
    com IDirectDraw.SetCooperativeLevel,DxDraw, [hwnd],DDSCL_NORMAL
    ;com IDirectDraw.SetCooperativeLevel,DxDraw, [hwnd],DDSCL_FULLSCREEN|DDSCL_EXCLUSIVE|DDSCL_ALLOWREBOOT|DDSCL_NOWINDOWCHANGES
    debugwrite "cooperative level result=%X",eax
    test eax,eax
    mov esi,ErrMsgCoopLevel
    js near EndWithErrMsg

    ;debugwrite "setting screen mode"
    ;com IDirectDraw.SetDisplayMode,DxDraw, 320,240,16
    ;debugwrite "screen mode result=%X",eax
    ;test eax,eax
    ;mov esi,ErrMsgGfxMode
    ;js near EndWithErrMsg

    debugwrite "creating primary surface"
    mov dword [ddsd+DDSURFACEDESC.dwSize],DDSURFACEDESC_size
    mov dword [ddsd+DDSURFACEDESC.dwFlags],DDSD_CAPS
    mov dword [ddsd+DDSURFACEDESC.ddsCaps],DDSCAPS_PRIMARYSURFACE
    com IDirectDraw.CreateSurface,DxDraw, ddsd,DxsFg,NULL
    debugwrite "create primary surface result=%X",eax
    test eax,eax
    mov esi,ErrMsgSurface
    js near EndWithErrMsg

;_____________________________________________________________________________
    ; message loop
    debugwrite "entering main loop"
    jmp short MsgLoop.Inside
MsgLoop:
    debugwrite "dispatching message=%X", [msg+MSG.message]
    api DispatchMessage, msg

    cmp dword [msg+MSG.message],WM_LBUTTONDOWN
    jne .NotLbd
    api MessageBox, 0,WhatsIt,Title,MB_OK|MB_ICONINFORMATION|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST
.NotLbd:
    cmp dword [msg+MSG.message],WM_MOUSEMOVE
    jne .Inside
    call TestPixelPlot

.Inside:
    api GetMessage, msg, NULL, 0, 0
    test eax,eax
    jnz MsgLoop
.End:
    ;debugwrite "restoring screen mode"
    ;com IDirectDraw.SetDisplayMode,DxDraw, 800,600,16
    debugwrite "releasing directx resources"
    push dword DxsFg            ;primary surface
    call ReleaseCom
    push dword DxDraw
    call ReleaseCom
    debugwrite "terminating program"
    api ExitProcess,[msg+MSG.wParam]

;_____________________________________________________________________________
; (esi=error message ptr)
EndWithErrMsg:
    debugwrite "releasing resources"
    push dword DxsFg            ;primary surface
    call ReleaseCom
    push dword DxDraw
    call ReleaseCom
    debugwrite "exiting process from fatal error: %s", esi
    api MessageBox, [hwnd],esi,ErrMsgFatal,MB_OK|MB_ICONERROR|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST
    api DestroyWindow, [hwnd]
    api ExitProcess, -1

;_____________________________________________________________________________
MsgProc:
    params .hwnd, .message, .wParam, .lParam
    mov eax,[esp+.message]
    ;debugwrite "window message=%X wparam=%X lparam=%X",eax,[esp+.wParam+4],[esp+.lParam]
    cmp eax,WM_CREATE
    je .Create
    cmp eax,WM_HOTKEY
    je .HotKey
    cmp eax,WM_DISPLAYCHANGE
    je .DisplayChange
    cmp eax,WM_DESTROY
    je .Destroy
    ;cmp eax,...
    jmp [DefWindowProc]

.HotKey:
    call TestPixelPlot
    xor eax,eax                 ;is this necessary?
    ret 16

.Destroy:
    debugwrite "destroying window",eax
	api UnregisterHotKey, [esp+.hwnd+1*4], 20040815
    push dword 0
    extern PostQuitMessage
    call [PostQuitMessage]
    xor eax,eax                 ;is this necessary?
    ret 16

.DisplayChange:
    debugwrite "display change"
    xor eax,eax
    ret 16

.Create:
    push FALSE					; 4rth SendMessage parm
    api GetStockObject, DEFAULT_GUI_FONT
    push eax					; 3rth SendMessage parm
    push dword WM_SETFONT		; 2nd SendMessage parm
    api GetClientRect, [esp+.hwnd+1*4 +3*4], rect
    api CreateWindowEx, WS_EX_STATICEDGE|WS_EX_NOPARENTNOTIFY, "STATIC", Instructions, WS_CHILD|WS_VISIBLE|SS_CENTER, 0,0, [rect+RECT.right],[rect+RECT.bottom], [esp+.hwnd+3*4 +3*4], 100, NULL, NULL
    push eax
    api SendMessage, void,void,void,void
	
    ;api RegisterHotKey, [esp+.hwnd+3*4], 20040815, MOD_CONTROL, VK_SNAPSHOT
    api RegisterHotKey, [esp+.hwnd+3*4], 20040815, 0, VK_F12
    xor eax,eax                 ;is this necessary?
    ret 16

;_____________________________________________________________________________
TestPixelPlot:
    ; if surface = null
    ;   recreate primary surface
    ; elif lost
    ;   restore
    ;   if wrong mode (someone changed it on us)
    ;     recreate primary surface
    ;   endif
    ; endif
    cmp dword [DxsFg],0
    je .Recreate
    com IDirectDrawSurface.IsLost,DxsFg
    cmp eax,DDERR_SURFACELOST
    jne near .NotLost
    debugwrite "surface lost"
    com IDirectDrawSurface.Restore,DxsFg
    debugwrite "restore=%X",eax
    cmp eax,DDERR_WRONGMODE
    jne .NotLost

    ; release old primary surface
    debugwrite "releasing primary surface"
    xor eax,eax
    xchg [DxsFg],eax
    mov edx,[eax]               ;get function table
    push eax
    call [edx+IDirectDrawSurface.Release]

.Recreate:
    mov dword [ddsd+DDSURFACEDESC.dwSize],DDSURFACEDESC_size
    mov dword [ddsd+DDSURFACEDESC.dwFlags],DDSD_CAPS
    mov dword [ddsd+DDSURFACEDESC.ddsCaps],DDSCAPS_PRIMARYSURFACE
    com IDirectDraw.CreateSurface,DxDraw, ddsd,DxsFg,NULL
    debugwrite "recreate primary surface result=%X",eax
    test eax,eax
    jns .NotLost
    ret
.NotLost:

    com IDirectDrawSurface.Lock,DxsFg, 0,ddsd,DDLOCK_SURFACEMEMORYPTR|DDLOCK_WRITEONLY,0 ;|DDLOCK_WAIT
    test eax,eax
    jns .NoErr
    debugwrite "lock error"
    ret
.NoErr:

%if 1 ;blue hash
    mov eax,[ddsd+DDSURFACEDESC.dwWidth]
    mov ebx,[ddpf+DDPIXELFORMAT.dwRGBBitCount]
    mov edi,[ddsd+DDSURFACEDESC.lpSurface]
    shr eax,1
    mov edx,[ddsd+DDSURFACEDESC.dwHeight]
	cmp ebx,8
	jbe .8bit
	cmp ebx,16
	jbe .16bit
	cmp ebx,24
	jbe .24bit

.32bit:
.32NextRow:
    mov ecx,eax					;copy column count
    push edi					;save screen ptr
.32NextCol:
    mov dword [edi],0000FFh		;write blue pixel
    add edi,byte 8
    dec ecx
    jg .32NextCol
    pop edi
    add edi,[ddsd+DDSURFACEDESC.lPitch] ;next line
    xor edi,4                   ;toggle between odd and even pixels
    dec edx
    jg .32NextRow
    jmp short .EndRows

.24bit:
.24NextRow:
    mov ecx,eax					;copy column count
    push edi					;save screen ptr
.24NextCol:
    mov word [edi],00FFh		;write blue pixel
    mov byte [edi+2],000h		;write red pixel = 0
    add edi,byte 6
    dec ecx
    jg .24NextCol
    pop edi
    add edi,[ddsd+DDSURFACEDESC.lPitch] ;next line
    xor edi,3                   ;toggle between odd and even pixels
    dec edx
    jg .24NextRow
    jmp short .EndRows

.16bit:
.16NextRow:
    mov ecx,eax					;copy column count
    push edi					;save screen ptr
.16NextCol:
    mov word [edi],1Fh
    add edi,byte 4
    dec ecx
    jg .16NextCol
    pop edi
    add edi,[ddsd+DDSURFACEDESC.lPitch] ;next line
    xor edi,2                   ;toggle between odd and even pixels
    dec edx
    jg .16NextRow
    jmp short .EndRows

.8bit:
.8NextRow:
    mov ecx,eax					;copy column count
    push edi					;save screen ptr
.8NextCol:
    mov byte [edi],9			;write blue pixel
    add edi,byte 2
    dec ecx
    jg .8NextCol
    pop edi
    add edi,[ddsd+DDSURFACEDESC.lPitch] ;next line
    xor edi,1                   ;toggle between odd and even pixels
    dec edx
    jg .8NextRow
    ;jmp short .EndRows

.EndRows:
%elif 0 ;black vertical lines

%endif

    com IDirectDrawSurface.Unlock,DxsFg, 0
    debugwrite "video mem ptr=%X pitch=%d", [ddsd+DDSURFACEDESC.lpSurface], [ddsd+DDSURFACEDESC.lPitch]
    debugwrite "height=%d width=%d", [ddsd+DDSURFACEDESC.dwHeight], [ddsd+DDSURFACEDESC.dwWidth]
    debugwrite "bitdepth=%d", [ddpf+DDPIXELFORMAT.dwRGBBitCount]
    ret

;_____________________________________________________________________________
; Releases COM interface and nulls the pointer.
; (dword com object indirect ptr)
; (HRESULT)
ReleaseCom:
    mov edx,[esp+4]             ;get indirect ptr to COM object
    xor eax,eax
    xchg [edx],eax              ;null COM ptr and get previous
    test eax,eax
    jz .Ret                     ;already null
    ;debugwrite "setting COM object null"
    mov edx,[eax]               ;get function table
    mov [esp+4],eax             ;pass object
    jmp [edx+8]                 ;call release function
.Ret:
    ;debugwrite "COM object already null"
    ret 4

;_____________________________________________________________________________
section .data

hwnd:       dd 0
;StdOut:    dd 0
DxDraw:     dd 0
DxsFg:      dd 0

wc:
istruc WNDCLASS
at WNDCLASS.style,         dd 0
at WNDCLASS.lpfnWndProc,   dd MsgProc
at WNDCLASS.cbClsExtra,    dd 0
at WNDCLASS.cbWndExtra,    dd 0
at WNDCLASS.hInstance,     dd 400000h ;NULL (default image base is at 4MB)
at WNDCLASS.hIcon,         dd NULL
at WNDCLASS.hCursor,       dd NULL
at WNDCLASS.hbrBackground, dd COLOR_BTNFACE + 1
at WNDCLASS.lpszMenuName,  dd NULL
at WNDCLASS.lpszClassName, dd AppName
iend

section .strings
AppName:        db "PknDdrawTest",0
Instructions:   db "Move the mouse over me",13,10,"or press the F12 key",13,10,"to clear the screen",0
Title:        	db "Blue Hash 20040815",0
WhatsIt:        db "Blue Hash",13
                db "Dwayne Robinson",13
                db "NASM and ALINK",13
                db "2002-03-07",13,10,10
                db "This program was my first little test",13
                db "for DirectDraw, bypassing the intolerably",13
                db "slow and cumbersome GDI, and blitting",13
                db "directly to the screen. The blue hash",13
                db "simply lets you see how other programs",13
                db "perform their drawing.",0
ErrMsgFatal:    db "Blue Hash: Fatal Error",0
ErrMsgDxInit:   db "DirectDraw would not initialize",0
ErrMsgCoopLevel:db "Setting DirectDraw cooperative level",0
ErrMsgGfxMode:  db "Setting set screen mode",0
ErrMsgSurface:  db "Creating drawing surface",0
ErrMsgRegWin:   db "Registering window class",0
ErrMsgWinCreate:db "Creating window",0

section .bss
alignb 4
msg:        resb MSG_size
ddsd:       resb DDSURFACEDESC_size
ddpf        equ ddsd+DDSURFACEDESC.ddpfPixelFormat
rect:		resb RECT_size