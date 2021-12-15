; Fire Demo (with optional PC Lock mode)
; Dwayne Robinson
; 2002-04-16 / 2002-05-03
;
; System Requirements:
;   Windows 95+         works on 95/98/2k/Win7/Win10 (others unverified)
;   300MHz              probably works on less but haven't tried
;   DirectX 4+          my system has DX7
;   16MB                uses <1MB
;
; Includes a beautiful screen spectacle, flames and a rotating fireball. It
; was all written in assembler for speed and uses DirectDraw. Unfortunately
; the screen resolution, number of particles, and other variables are all
; hard coded in the program -_-. You need to change the constants and recompile.
;
; Also includes a "lock PC" mode if you hold Shift when launching.
; Press F12 to terminate the program.
; - Mildly discourages people from using your computer in a shared college
;   computer lab and closing all your programs while you were temporarily
;   away helping somebody else.
; - Disables all common Windows keypresses (Alt+Tab, Ctrl+Esc, Windows Key,
;   Alt+Esc, and even Ctrl+Alt+Del on Win9x, but not Win2k+). On Win9x, it's
;   achieved by simply never passing the messages onto DefWindowProc. On NT,
;   it's achieved by SetWindowsHookEx.
; - Prevents shut down if the annoying usurper tries to press Power button
;   (obviously not if they press it for 7 second though :b).
; - Stops screensaver from coming on.
;
; Source code:
;
;   The flame code was adapted from Gaffer's "128 byte quality fire" demo,
;   an excellent little (very little) COM file:
;       Copyright 1997 Gaffer/prometheus
;       gaffer@zip.com.au
;       ps. checkout the 256 byte fire compo page
;       http://www.zip.com.au/gaffer/compo
;
;   All the rest of the code is mine (Piken).
;
; Compiling:
;
;   GoRC 0.56 - compile RC into resource file
;   NASM 0.98 - compile source code into object file
;   ALINK 1.6 - link object file with external references
;
;   nasm.exe -fwin32 FireDemo.asm -o FireDemo.cof -dWinVer
;   gorc.exe /r FireDemo.rc
;   alink.exe -oPE FireDemo.cof WinImp.lib FireDemo.res -o FireDemo.exe -entry Main
;
; Fun Facts:
;
;   Every single second:
;      28,000 random generations + flame feedback additions
;     600,000 sine and cosine calculations
;   9,216,000 smooths of four surrounding neighbors
;
;   And that concludes today's lesson for
;   "One more thing you just can't do in VB"

[section code code]
[section data data]
[section text data]
[section bss bss]
global Main

;%define debug
%define UseWindowStyles
%define UseWindowMsgs
%define UseWindowGfx
%define UseResources
%define UseKeyboard
%define UseDxDraw
%define UseWindowHooks
%include "WinInc.asm"                   ;standard Windows constants, structs...


;-----------------------------------------------------------------------------
section data
hwnd:     dd 0          ;window handle
hdc:      dd 0          ;class device context
dxd:      dd 0          ;DirectDraw object
ddps:     dd 0          ;DirectDraw primary surface
ddcp:     dd 0          ;primary surface color palette
hkbd:     dd 0          ;keyboard hook
IsActive: dd 0          ;program is active or not

wc:
.BaseAddress    equ 400000h ;base address of program (Windows module handle)
istruc WNDCLASS
at WNDCLASS.style,         dd CS_CLASSDC
at WNDCLASS.lpfnWndProc,   dd MsgProc
at WNDCLASS.cbClsExtra,    dd 0
at WNDCLASS.cbWndExtra,    dd 0
at WNDCLASS.hInstance,     dd .BaseAddress ;(default image base is at 4MB)
at WNDCLASS.hIcon,         dd NULL
at WNDCLASS.hCursor,       dd NULL
at WNDCLASS.hbrBackground, dd NULL ;COLOR_BTNFACE + 1
at WNDCLASS.lpszMenuName,  dd NULL
at WNDCLASS.lpszClassName, dd ProgramClass
iend

EmptyRect:
dd 0, 0 ;left,top
dd 0, 0 ;right,bottom

SineTable:
.Degrees    equ 1024
incbin "sinewave.dat"

;-----------------------------------------------------------------------------
section bss
msg:        resb MSG_size
ps:         resb PAINTSTRUCT_size
ddsd:       resb DDSURFACEDESC_size
ddpf        equ ddsd + DDSURFACEDESC.ddpfPixelFormat

Screen:
%if 1
.Width      equ 800
.Height     equ 600
%else
.Width      equ 640
.Height     equ 480
%endif
.Bits       equ 8
.Size       equ ((.Height+8+3) * .Width * .Bits) / 8
.Buffer:    resb .Size
.Palette:   resb 1024

Fire:
.ShadeRange equ 80              ; range of each color channel
.ShadeSep   equ 40              ; separation between color channels
.RndValue:  resd 0BFFCh

Particles:
.MaxCount   equ 10000
.Brightness equ 18
.MaxDistance equ 800
.Distance:  resd .MaxCount      ; distance of particle from center
.AngleY:    resd .MaxCount      ; y rotation (clockwise/countercw)
.AngleZ:    resd .MaxCount      ; z rotation (forward/backward)
section data
.OriginY:   dd Screen.Height / 2    ; origin for all particles to swirl around
.OriginX:   dd Screen.Width / 2     ; which follows the mouse
section bss

Passwords:
.Minimize:  resb 10
.Quit:      resb 10
.Current:   resb 10
.Size       equ $-Passwords

;-----------------------------------------------------------------------------
section text

ProgramClass:   db "PikenFireDemo",0
ProgramTitle:   db "Piken's Fire Demo",0
ErrMsgFatal:    db "Piken's Fire Demo: Fatal Error",0

ErrMsgDxInit:   db "Initializing DirectDraw",0
ErrMsgCoopLevel:db "Setting DirectDraw cooperative level",0
ErrMsgGfxMode:  db "Setting set screen mode",0
ErrMsgSurface:  db "Creating primary drawing surface",0

;-----------------------------------------------------------------------------
section code

Main:

;-------------------
; Create window
    api LoadIconA, wc.BaseAddress, 1
    mov [wc+WNDCLASS.hIcon],eax

    ; register window class
    debugwrite "registering class"
    api RegisterClassA, wc
    debugwrite "register result=%X", eax
    test eax,eax
    jz near .End

    ; create instance of window
    debugwrite "creating window"
    api CreateWindowExA, WS_EX_TOPMOST, ProgramClass, ProgramTitle, WS_POPUP|WS_MAXIMIZE|WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_VISIBLE|WS_SYSMENU, 0,0, 3000,3000, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    jz near .End
    ;mov [hwnd],eax

    ; get window class display handle
    api GetDC, eax
    debugwrite "get hdc=%X", eax
    mov [hdc],eax

;-------------------
; Initialize DirectDraw
    ; initialize direct draw
    debugwrite "initializing direct draw"
    api DirectDrawCreate, NULL,dxd,NULL
    debugwrite "direct draw result=%X", eax
    test eax,eax
    mov esi,ErrMsgDxInit
    js near EndWithErrMsg

    debugwrite "setting cooperative level"
    com IDirectDraw.SetCooperativeLevel, dxd, [hwnd], DDSCL_FULLSCREEN|DDSCL_EXCLUSIVE|DDSCL_NOWINDOWCHANGES
    debugwrite "cooperative level result=%X", eax
    test eax,eax
    mov esi,ErrMsgCoopLevel
    js near EndWithErrMsg

    debugwrite "setting screen mode"
    com IDirectDraw.SetDisplayMode, dxd, Screen.Width, Screen.Height, Screen.Bits
    debugwrite "screen mode result=%X", eax
    test eax,eax
    mov esi,ErrMsgGfxMode
    js near EndWithErrMsg

    debugwrite "creating primary surface"
    mov dword [ddsd+DDSURFACEDESC.dwSize],DDSURFACEDESC_size
    mov dword [ddsd+DDSURFACEDESC.dwFlags],DDSD_CAPS
    mov dword [ddsd+DDSURFACEDESC.ddsCaps],DDSCAPS_PRIMARYSURFACE
    com IDirectDraw.CreateSurface,dxd, ddsd,ddps,NULL
    debugwrite "create primary surface result=%X",eax
    test eax,eax
    mov esi,ErrMsgSurface
    js near EndWithErrMsg

    debugwrite "setting palette"
    call CreateFirePalette
    ;com IDirectDraw.CreatePalette,dxd, DDPCAPS_8BIT|DDPCAPS_ALLOW256|DDPCAPS_INITIALIZE|DDPCAPS_PRIMARYSURFACE,Screen.Palette,ddcp,0
    com IDirectDraw.CreatePalette,dxd, DDPCAPS_8BIT|DDPCAPS_INITIALIZE, Screen.Palette, ddcp, 0
    test  eax,eax
    js .PaletteErr                      ;Oh well, we tried.
    com IDirectDrawSurface.SetPalette,ddps, [ddcp]
.PaletteErr:

;-------------------
; Misc Init
    call InitParticles

    cld
    mov edi,Screen.Buffer
    mov ecx,(Screen.Height*Screen.Width)/4
    xor eax,eax
    rep stosd
    mov edi,Passwords
    mov ecx,Passwords.Size/4
    rep stosd

    api ShowCursor, FALSE               ;Don't want a distracting cursor, just a fireball.

    ; Note that low level keyboard hooks are unsupported on 9x systems.
    ; No big deal, since the function will simply return NULL.
    api GetKeyState, VK_SHIFT
    test al,80h
    jz .NoPcLock
    api SetWindowsHookExA, WH_KEYBOARD_LL, LlKeyboardProc, wc.BaseAddress, NULL
    mov [hkbd],eax
.NoPcLock:

;-------------------
; Main Loop
    debugwrite "entering main loop"
    jmp short .InsideLoop
.Next:
    mov eax,[msg+MSG.message]
    cmp eax,WM_KEYFIRST
    jb .NotKey
    cmp eax,WM_KEYLAST
    jbe near .KeyPress
.NotKey:
    cmp eax,WM_MOUSEMOVE
    je .MouseMove
    cmp eax,WM_TIMER
    je .FrameUpdate
.Dispatch:
    api DispatchMessageA, msg
.InsideLoop:
    xor eax,eax
    api GetMessageA, msg, eax, eax, eax
    test eax,eax
    jnz .Next

;-------------------
; Termination
.End:
    mov eax,[hkbd]
    test eax,eax
    jz .NoKeyboardHook
    api UnhookWindowsHookEx, eax
.NoKeyboardHook:
    push dword ddcp                     ;color palette
    call ReleaseCom
    push dword ddps                     ;primary surface
    call ReleaseCom
    push dword dxd                      ;DirectX draw
    call ReleaseCom
    api ExitProcess, [msg+MSG.wParam]

;-------------------
.MouseMove:
    movsx edx,word [msg+MSG.lParam+2]   ;sign row
    movsx ecx,word [msg+MSG.lParam]     ;sign column
    mov [Particles.OriginY],edx
    mov [Particles.OriginX],ecx
    jmp short .InsideLoop

;-------------------
.FrameUpdate:
    com IDirectDrawSurface.IsLost,ddps
    jns .UpdateOk
    com IDirectDrawSurface.Restore,ddps
    test eax,eax
    js .FuError

.UpdateOk:
    ; perform animation & transfer buffer to screen
    call AdvanceFlames
    call DrawParticles

    com IDirectDrawSurface.Lock, ddps, 0, ddsd, DDLOCK_SURFACEMEMORYPTR|DDLOCK_WRITEONLY, 0 ;|DDLOCK_WAIT seems unnecessary
    test eax,eax
    js .FuError

    cld
    mov esi,Screen.Buffer
    mov edi,[ddsd+DDSURFACEDESC.lpSurface]
    mov edx,[ddsd+DDSURFACEDESC.lPitch]
    sub edx,Screen.Width * Screen.Bits / 8
    mov ebx,Screen.Height
.NextRow:
    mov ecx,Screen.Width * Screen.Bits / 32
    rep movsd
    add edi,edx
    dec ebx
    jg .NextRow

    com IDirectDrawSurface.Unlock, ddps, 0
.FuError:
    jmp .InsideLoop

;-------------------
.KeyPress:
    mov al,[msg+MSG.wParam]
    cmp al,VK_F12
    je near .End
    cmp al,VK_ESCAPE
    je near .End
    cmp al,VK_F11
    jne near .InsideLoop
    api ShowWindow, [hwnd],SW_MINIMIZE
    jmp .InsideLoop


;-----------------------------------------------------------------------------
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    ;ShowWinMsgName "win msg=%X %s W=%X L=%X", eax,esi,[esp+.wParam+4],[esp+.lParam]
    cmp eax,WM_CREATE
    je near .Created
    cmp eax,WM_CLOSE
    je near .Close
    cmp eax,WM_SYSCOMMAND
    je near .DisableScreensaver
    cmp eax,WM_QUERYENDSESSION
    je near .QueryEndSession
    cmp eax,WM_WINDOWPOSCHANGING
    je .RetFalse
    cmp eax,WM_WINDOWPOSCHANGED
    je .RetFalse
    cmp eax,WM_MOVING
    je .RetTrue
    cmp eax,WM_DESTROY
    je .Destroy
    cmp eax,WM_ERASEBKGND
    je .RetTrue
    ;cmp eax,WM_PAINT
    ;je near .Paint
    cmp eax,WM_ACTIVATEAPP
    je .ChangeFocus
    ;cmp eax,WM_NCACTIVATE
    ;je .ChangeFocus ; Use WM_ACTIVATEAPP instead.
    ;cmp eax,...

    jmp [DefWindowProcA]                ;just tail call the default

.RetTrue:
    mov eax,TRUE
    ret 16

.Destroy:
    debugwrite "destroying window"
    api PostQuitMessage, 0
.RetFalse:
    xor eax,eax
    ret 16

;-------------------
.ChangeFocus:
    cmp word [esp+.wParam],FALSE
    je near .LoseFocus
.GainFocus:
    debugwrite "enable timer"
    api SetTimer, [hwnd], 1, 33, NULL    ;30 times per second, no callback
    api SetWindowPos, [hwnd],0, 0,0,0,0, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOSIZE|SWP_NOZORDER|SWP_NOREDRAW
    mov dword [IsActive],TRUE
    xor eax,eax
    ret 16
.LoseFocus:
    debugwrite "disable timer"
    api KillTimer, [hwnd], 1            ;destroy 30 tick per second timer
    api PeekMessageA, msg, 0, WM_TIMER, WM_TIMER, PM_REMOVE
    api SetWindowPos, [hwnd],0, -10000,-10000,0,0, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOSIZE|SWP_NOZORDER
    xor eax,eax
    mov dword [IsActive],eax ;FALSE
    ret 16

;-------------------
.Paint:
    debugwrite "paint background"
    api ValidateRect, [hwnd], EmptyRect
    ; No need to call BeginPaint+EndPaint, since we redraw frequently via timer.
    xor eax,eax
    ret 16

;-------------------
.Created:
    mov eax,[esp+.hwnd]
    mov [hwnd],eax
.QueryEndSession:                       ;return FALSE to stop shut down
.Ignore:
    xor eax,eax
    ret 16

;-------------------
.Close:
    cmp dword [IsActive],TRUE
    je .Ignore
    jmp [DefWindowProcA]

;-------------------
.DisableScreensaver:
    mov eax,[esp+.wParam]
    and eax,0FFFFFFF0h
    cmp eax,SC_SCREENSAVE
    je .Ignore
    cmp eax,SC_MONITORPOWER
    je .Ignore
    jmp [DefWindowProcA]


;-------------------
LlKeyboardProc:
    params .nCode, .message, .kbInfo

    cmp dword [IsActive],TRUE           ;return immediately if inactive (different program has focus)
    jne .Chain
    cmp dword [esp+.nCode],0            ;return immediately if code is negative
    js .Chain
    mov ecx,[esp+.kbInfo]
    mov al,[ecx+KBDLLHOOKSTRUCT.vkCode]
    cmp al,VK_TAB
    je .NoChain
    cmp al,VK_ESCAPE
    je .NoChain
    cmp al,VK_LWIN
    je .NoChain
    cmp al,VK_RWIN
    je .NoChain
.Chain:
    api CallNextHookEx, [hkbd], [esp+8+.nCode],[esp+4+.message],[esp+.kbInfo]
    ret 12
.NoChain:
    mov eax,TRUE                        ;return nonzero result to end chain
    ret 12


;-----------------------------------------------------------------------------
; create fire palette
CreateFirePalette:
    cld
    mov edi,Screen.Palette
    mov ecx,256
    mov eax,4                           ;PC_RESERVED=1, PC_EXPLICIT=2, PC_NOCOLLAPSE=4
    rep stosd

    ;mov edi,Screen.Palette+2           ;for blue fire instead
    mov edi,Screen.Palette
    mov dl,3
.NextColor:                             ;alternate palette generation
    xor eax,eax
    push edi
    xor ebx,ebx                         ;zero accumulator
    mov cl,Fire.ShadeRange-1            ;ecx already = 0
.L1:
    mov ah,al
    shl ah,2
    mov [edi],ah
    add ebx,(4194304/Fire.ShadeRange)<<16
    adc eax,0
    add edi,byte 4
    loop .L1
    ;ecx=0
    ;mov cl,256-Fire.ShadeRange+1
.L2:
    mov [edi],ah
    add edi,byte 4
    cmp edi,Screen.Palette+1024
    jb .L2
    pop edi
    ;add edi,Fire.ShadeSep*4-1 ;for blue fire
    add edi,Fire.ShadeSep*4+1
    dec dl
    jg .NextColor
    ret


;-----------------------------------------------------------------------------
InitParticles:
    mov edi,(Particles.MaxCount - 1) * 4
;%define UseSimpleRnd
%ifdef UseSimpleRnd
    mov eax,0BFFCh
%else
    mov eax,082775212h                  ;set initial seed values
    mov ebx,03914AC5Fh
    mov ecx,0B460D9C3h
%endif
.Next:
    call .GetRng
    and esi,SineTable.Degrees-1
    mov dword [Particles.AngleY+edi],esi
    call .GetRng
    and esi,SineTable.Degrees-1
    mov dword [Particles.AngleZ+edi],esi
    call .GetRng
    push eax
    xor edx,edx
    mov esi,Particles.MaxDistance
    div esi
    mov dword [Particles.Distance+edi],200
    pop eax
    sub edi,byte 4
    jge .Next
    ret

; (eax=previous random value)
; (eax=new random value, edx=eax)
.GetRng:
%ifdef UseSimpleRnd
    mov ecx,33797
    mul ecx
    inc eax
%else
    mov edx,ecx                 ; R4=R3
    mov ecx,ebx                 ; R3=R2
    mov ebx,eax                 ; R2=R1

    mov eax,edx                 ; R1 = R4 + (R3<=R2 ? R3 : R2)
    cmp ecx,ebx
    jbe .Less
    add eax,ebx                 ; +R2
    jmp short .EndRng
.Less:
    add eax,ecx                 ; +R3
.EndRng:
%endif
    mov esi,eax                 ;make copy
    ret


;-----------------------------------------------------------------------------
; advance flames by one frame
AdvanceFlames:

    ; flame animation + smoothing
    xor edx,edx
    mov ecx,Screen.Width
    xor eax,eax
    mov ebx,(Screen.Height/2)+1
    mov edi,Screen.Buffer
.FsNext:
    mov ax,[edi+(Screen.Width*2)-1]     ;get current pixel and neighbor to the left
    add al,ah
    setc ah
    mov dl,[edi+(Screen.Width*2)+1]     ;get neighbor pixel to the right
    add eax,edx
    mov dl,[edi+(Screen.Width*4)]       ;get neighbor pixel below
    add eax,edx
    shr eax,2                           ;/4 average pixels
    jz .Zero
    dec eax                             ;cool a bit...
.Zero:
    stosb
    add eax,edx                         ;double the fire intensity
    shr eax,1
    adc eax,0
    mov [edi+Screen.Width-1],al
    loop .FsNext
    mov ecx,Screen.Width
    add edi,ecx                         ;skip a line
    dec ebx
    jg .FsNext


;%if 1
; flame generator bottom bar
    mov ecx,Screen.Width
    ; assumes edi=generator bar offset (bottom of flame buffer)
.FgNext:
    ;in ax,40h                  ; read from timer
    ;push ax
    ;add ax,[Fire.RndValue]
    ;pop word [Fire.RndValue]   ; "seed" is first two bytes of code
    ;mov ah,al
    mov eax,33797
    mul dword [Fire.RndValue]
    inc eax
    mov [Fire.RndValue],eax
    and ah,03Fh
    add ah,100;0CFh
    mov al,ah
    stosw
    stosw
    loop .FgNext
;%endif

; flame feedback
; feeds fire back into itself for more turbulent flame variation
    mov ecx,Screen.Width
    mov edi,Screen.Buffer+(Screen.Width*(Screen.Height+4))  ;plasma (likely my favorite)
.FfNext:
    mov al,[edi+(Screen.Width*-101)]    ;top of flames feed back into bottom
    ;shl al,5                           ;select top three bits
    ;and al,111011b
    ;xor al,1010110b
    shl al,3                            ;select top bits
    add [edi],al
    inc edi
    loop .FfNext

DoNothing:
    ret


;-----------------------------------------------------------------------------
DrawParticles:
    mov ebx,(Particles.MaxCount - 1) * 4
.Next:
    ; xy distance = z * distance
    mov eax,[Particles.AngleZ+ebx]
    mov eax,[SineTable+eax*4]
    imul eax,[Particles.Distance+ebx]
    sar eax,16

    ; x & y
    mov edx,[Particles.AngleY+ebx]
    mov ecx,edx
    mov edx,[SineTable+edx*4]
    add ecx,256                         ;get cosine, shifted 90/360 degrees (or 256/1024)
    imul edx,eax
    and ecx,1024-1                      ;mask index within bounds of table
    sar edx,16
    mov ecx,[SineTable+ecx*4]
    imul ecx,eax
    sar ecx,16
    add edx,[Particles.OriginY]
    add ecx,[Particles.OriginX]

; (edx=row, ecx=col)
.At:
    cmp edx,Screen.Height
    jae .OffScreen
    cmp ecx,Screen.Width
    jae .OffScreen
%if Screen.Width=320
    mov eax,edx
    shl edx,6
    shl eax,8
    add edx,eax
%elif Screen.Width=640
    mov eax,edx
    shl edx,7
    shl eax,9
    add edx,eax
%else
    imul edx,Screen.Width
%endif
    add [Screen.Buffer+edx+ecx],byte Particles.Brightness
    jnc .NoOverFlow
    mov [Screen.Buffer+edx+ecx],byte 255
.NoOverFlow:
.OffScreen:

    ; move particle for next frame
    add dword [Particles.AngleY+ebx],byte 2
    and dword [Particles.AngleY+ebx],SineTable.Degrees-1
    add dword [Particles.AngleZ+ebx],byte 3
    and dword [Particles.AngleZ+ebx],SineTable.Degrees-1

    sub ebx,byte 4
    jns near .Next
    ret


;-----------------------------------------------------------------------------
; Releases COM interface and nulls the pointer.
; (dword com object indirect ptr)
; (HRESULT)
ReleaseCom:
    mov edx,[esp+4]             ;get indirect ptr to COM object
    xor eax,eax
    xchg [edx],eax              ;nullify COM ptr and get previous
    test eax,eax
    jz .Ret                     ;already null
    debugwrite "setting COM object null"
    mov edx,[eax]               ;get function table
    mov [esp+4],eax             ;pass object
    jmp [edx+8]                 ;call release function (tail call is legal)
.Ret:
    debugwrite "COM object already null"
    ret 4


;-----------------------------------------------------------------------------
; (esi=error message ptr)
EndWithErrMsg:
    debugwrite "releasing resources"
    push dword ddcp             ;color palette
    call ReleaseCom
    push dword ddps             ;primary surface
    call ReleaseCom
    push dword dxd              ;directx draw
    call ReleaseCom
    debugwrite "exiting process from fatal error: %s", esi
    api MessageBoxA, [hwnd], esi, ErrMsgFatal, MB_OK|MB_ICONERROR|MB_SETFOREGROUND
    api DestroyWindow, [hwnd]
    api ExitProcess, -1
