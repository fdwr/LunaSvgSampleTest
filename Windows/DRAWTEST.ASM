; Test: Create window that uses DirectDraw
; 2002-03-02
; Dwayne Robinson
;
; Trial and error:
;   Restore does not restore lost surfaces after the video mode (either the
;     bits or resolution) has been changed by another program (like the
;     Desktop properties). Instead, the primary surface must be recreated.

[section code code]
[section data data]
[section text data]
[section bss bss]

%define debug
%define UseWindowStyles
%define UseWindowMsgs
%define UseWinGfx
%define UseDxDraw
;%define UseWindowsConsole
%include "mywininc.asm"

SurfaceHeight equ 400
SurfaceWidth  equ 640

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
section code
global Main
Main:
    params .Instance, .PrevInstance, .CmdLine, .CmdShow

    api GetCommandLine          ; get pointer to the command line
    debugmsg "drawtest cmd line=%s",eax

;    mov ecx,DataEnd - DataStart
;    mov esi,DataEnd
;.Next:
;    mov al,[esi]
;    dec esi
;    loop .Next

    ;mov eax,[esp+4] ;.Instance]
    ;debugmsg "instance handle from stack=%X",eax
    ;debugmsg "code=%X",$$,DataStart
    ;mov eax,CodeStart
    ;and eax,0FFFF0000h
    ;debugmsg "code start to 64k=%X",eax

    ;push dword NULL
    ;call [GetModuleHandle]
    ;mov [wc+WNDCLASS.hInstance],eax
    ;debugmsg "instance handle from get module=%X",eax

    ;api GetStdHandle, STD_OUTPUT_HANDLE
    ;mov [StdOut], eax
    ;api WriteConsole, [StdOut], [GetModuleHandle], 100, waste, NULL
    ;mov eax,[GetModuleHandle]
    ;debugmsg "GetModuleHandle=%X %X %X",[eax+12],[eax+16],[eax+20]

    ; register window class
    debugmsg "registering class"
    api RegisterClass, wc
    debugmsg "register result=%X", eax
    test eax,eax
    mov esi,ErrMsgRegWin
    jz near EndWithErrMsg

    ; create instance of window
    api AdjustWindowRect, SurfaceRect,WS_CAPTION|WS_POPUP|WS_MINIMIZEBOX|WS_SYSMENU|WS_VISIBLE, FALSE
    mov edx,[SurfaceRect+RECT.top]
    mov ecx,[SurfaceRect+RECT.left]
    sub [SurfaceRect+RECT.bottom],edx
    sub [SurfaceRect+RECT.right],ecx
    debugmsg "creating window %dx%d",[SurfaceRect+12],[SurfaceRect+8]
    api CreateWindowEx, WS_EX_ACCEPTFILES, ProgramClass, ProgramClass, WS_CAPTION|WS_POPUP|WS_MINIMIZEBOX|WS_SYSMENU|WS_VISIBLE, 0,0, [SurfaceRect+RECT.right],[SurfaceRect+RECT.bottom], NULL, NULL, [wc+WNDCLASS.hInstance], NULL
    ;                      class    title                                pos      size    parent no menu
    debugmsg "window handle=%X", eax
    test eax,eax
    mov esi,ErrMsgWinCreate
    jz near EndWithErrMsg
    mov [hwnd],eax
    api GetDC, eax              ;get window class display handle
    debugmsg "get hdc=%X",eax
    mov [hdc],eax

%if 0
    ; initialize direct draw
    debugmsg "initializing direct draw"
    api DirectDrawCreate, NULL,DxDraw,NULL
    ;debugmsg "direct draw result=%X",eax
    test eax,eax
    mov esi,ErrMsgDxInit
    js near EndWithErrMsg

    debugmsg "setting cooperative level"
    com IDirectDraw.SetCooperativeLevel,DxDraw, [hwnd],DDSCL_NORMAL
    ;com IDirectDraw.SetCooperativeLevel,DxDraw, [hwnd],DDSCL_FULLSCREEN|DDSCL_EXCLUSIVE|DDSCL_ALLOWREBOOT|DDSCL_NOWINDOWCHANGES
    debugmsg "cooperative level result=%X",eax
    test eax,eax
    mov esi,ErrMsgCoopLevel
    js near EndWithErrMsg

    ;debugmsg "setting screen mode"
    ;com IDirectDraw.SetDisplayMode,DxDraw, 320,240,16
    ;debugmsg "screen mode result=%X",eax
    ;test eax,eax
    ;mov esi,ErrMsgGfxMode
    ;js near EndWithErrMsg

    debugmsg "creating primary surface"
    mov dword [ddsd+DDSURFACEDESC.dwSize],DDSURFACEDESC_size
    mov dword [ddsd+DDSURFACEDESC.dwFlags],DDSD_CAPS
    mov dword [ddsd+DDSURFACEDESC.ddsCaps],DDSCAPS_PRIMARYSURFACE
    com IDirectDraw.CreateSurface,DxDraw, ddsd,DxsFg,NULL
    debugmsg "create primary surface result=%X",eax
    test eax,eax
    mov esi,ErrMsgSurface
    js near EndWithErrMsg
%endif

%if 0
    ;mov dword [ddsd+DDSURFACEDESC.dwSize],DDSURFACEDESC_size
    mov dword [ddsd+DDSURFACEDESC.dwFlags],DDSD_CAPS|DDSD_HEIGHT|DDSD_WIDTH|DDSD_PITCH|DDSD_LPSURFACE|DDSD_PIXELFORMAT
    mov dword [ddsd+DDSURFACEDESC.dwHeight],SurfaceHeight
    mov dword [ddsd+DDSURFACEDESC.dwWidth],SurfaceWidth
    mov dword [ddsd+DDSURFACEDESC.lPitch],SurfaceWidth
    mov dword [ddsd+DDSURFACEDESC.lpSurface],BgBuffer
    mov dword [ddsd+DDSURFACEDESC.ddsCaps],DDSCAPS_SYSTEMMEMORY
    mov dword [ddsd+DDSURFACEDESC.ddpfPixelFormat+DDPIXELFORMAT.dwSize],DDPIXELFORMAT_size
    mov dword [ddsd+DDSURFACEDESC.ddpfPixelFormat+DDPIXELFORMAT.dwFlags],0
    mov dword [ddsd+DDSURFACEDESC.ddpfPixelFormat+DDPIXELFORMAT.dwRGBBitCount],8
    com IDirectDraw.CreateSurface,DxDraw, ddsd,DxsFg,NULL
    debugmsg "create bg surface result=%X",eax
    test eax,eax
    mov esi,ErrMsgSurface
    js near EndWithErrMsg
%endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
    ; message loop
    debugmsg "entering main loop"
MsgLoop:
    jmp .Inside

.Top:
;    cmp dword [msg+MSG.message],WM_NCLBUTTONDOWN
;    jne .NotNcl
;    api LockWindowUpdate,[hwnd]
;    api LockWindowUpdate,0
;    jmp short .Inside
;.NotNcl:
    mov eax,[msg+MSG.message]
    call GetWinMsgName
    debugmsg "thread msg=%X %s", eax,esi

%if 0
    cmp dword [msg+MSG.message],WM_LBUTTONDOWN
    jne .NotLdn
    ;mov dword [msg+MSG.message],WM_SYSCOMMAND
    ;mov dword [msg+MSG.wParam],SC_MOVE
    ;api DispatchMessage, msg
    push dword [msg+MSG.lParam]
    push dword SC_MOVE
    push dword WM_SYSCOMMAND
    push dword [hwnd]
    call [DefWindowProc]
    jmp short .Inside
.NotLdn:
%endif

%if 0
    cmp dword [msg+MSG.message],WM_LBUTTONDOWN
    jne .NotLdn
    api ShowCursor, FALSE
    jmp short .Inside
.NotLdn:
    cmp dword [msg+MSG.message],WM_LBUTTONUP
    jne .NotLup
    api ShowCursor, TRUE
    jmp short .Inside
.NotLup:
%endif


%if 0
    cmp dword [msg+MSG.message],WM_LBUTTONDOWN
    jne .NotLdn
    api ClipCursor, CursorClipRect
    jmp short .Inside
.NotLdn:
%endif


%if 0 ;testing cursor clipping
    cmp dword [msg+MSG.message],WM_LBUTTONDOWN
    jne .NotClip
    api ClipCursor, CursorClipRect
    jmp short .Inside
.NotClip:
    cmp dword [msg+MSG.message],WM_LBUTTONUP
    jne .NotUnclip
    api ClipCursor, NULL
    jmp short .Inside
.NotUnclip:
%endif


%if 0 ;testing directx blitting
    cmp dword [msg+MSG.message],WM_LBUTTONDOWN ;WM_PAINT
    jne .NotPaint
    call TestPixelPlot
    jmp short .Inside
.NotPaint:
%endif

    cmp dword [msg+MSG.message],WM_RBUTTONDOWN
    jne .NotRepaint
    call TestDibBlit
    jmp short .Inside
.NotRepaint:

    api DispatchMessage, msg

.Inside:
    api GetMessage, msg, NULL, 0, 0
    test eax,eax
    jnz near .Top

.End:
    ;debugmsg "restoring screen mode"
    ;com IDirectDraw.SetDisplayMode,DxDraw, 800,600,16
    debugmsg "releasing directx resources"
    push dword DxsFg            ;primary surface
    call ReleaseCom
    push dword DxDraw
    call ReleaseCom
    debugmsg "terminating program"
    api ExitProcess,[msg+MSG.wParam]

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; (esi=error message ptr)
EndWithErrMsg:
    debugmsg "releasing resources"
    push dword DxsFg            ;primary surface
    call ReleaseCom
    push dword DxDraw
    call ReleaseCom
    debugmsg "exiting process from fatal error: %s", esi
    api MessageBox, [hwnd],esi,ErrMsgFatal,MB_OK|MB_ICONERROR|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST
    api DestroyWindow, [hwnd]
    api ExitProcess, -1

    xor eax,eax                 ;is this necessary?
    ret 16

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    call GetWinMsgName
    debugmsg "win msg=%X %s W=%X L=%X", eax,esi,[esp+.wParam+4],[esp+.lParam]
;   cmp eax,WM_CREATE
;   je .Create
;   cmp eax,WM_NCCREATE
;   je .NcCreate
    cmp eax,WM_KEYDOWN
    je .KeyDown
    cmp eax,WM_PAINT
    je .Paint
    cmp eax,WM_ERASEBKGND
    je .RetTrue
    ;cmp eax,WM_NCHITTEST
    ;je .NcHitTest
    cmp eax,WM_WINDOWPOSCHANGING
    je .RetFalse
    cmp eax,WM_WINDOWPOSCHANGED
    je .RetFalse
    cmp eax,WM_MOVING
    je .RetTrue
    cmp eax,WM_DESTROY
    je .Destroy
    ;cmp eax,...
.DefWindowProc:
    jmp [DefWindowProc]
.RetTrue:
    mov eax,TRUE
    ret 16
.RetFalse:
    xor eax,eax
    ret 16


;.NcCreate:
;    mov eax,[esp+.lParam]
;    debugmsg "nc size=%d X %d exstyle=%X", [eax+CREATESTRUCT.cx],[eax+CREATESTRUCT.cy],[eax+CREATESTRUCT.dwExStyle]
;    add dword [eax+CREATESTRUCT.cx],200
;    or dword [eax+CREATESTRUCT.dwExStyle],WS_EX_ACCEPTFILES

;.Create:
;    api GetClientRect,[esp+.hwnd+4],SurfaceRect
;    debugmsg "retval=%x top=%d left=%d right=%d bottom=%d",eax,[SurfaceRect+4],[SurfaceRect],[SurfaceRect+12],[SurfaceRect+8]
;    api GetWindowLong, [esp+.hwnd+4],GWL_EXSTYLE
;    debugmsg "get exstyle=%X",eax
;    or eax,WS_EX_ACCEPTFILES
;    api SetWindowLong, [esp+.hwnd+8],GWL_EXSTYLE,eax
;    ;mov eax,-1
;    xor eax,eax
;    ret 16

.KeyDown:
    cmp [esp+.wParam],byte 20h
    jne .DefWindowProc
    api MessageBox, [hwnd],.KeyDownMsg,.KeyDownMsg,MB_OK
    ret 16

%if 0
.NcHitTest:
    push dword [esp+16]
    push dword [esp+16]
    push dword [esp+16]
    push dword [esp+16]
    call [DefWindowProc]
.NcGetHitTest:
    cmp eax,HTCLIENT
    jne .IgnoreHitTest
    mov eax,HTCAPTION
.IgnoreHitTest:
    ret 16
%endif

.Paint:
    call TestDibBlit
    xor eax,eax
    ret 16

.Destroy:
    debugmsg "destroying window",eax
    api PostQuitMessage,0
    jmp MsgLoop.End

    xor eax,eax                 ;is this necessary?
    ret 16

section text
.KeyDownMsg: db "space down",0
section code

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
TestPixelPlot:
    api GetClientRect,[hwnd],SurfaceRect
    debugmsg "top=%d left=%d right=%d bottom=%d",[SurfaceRect+4],[SurfaceRect],[SurfaceRect+12],[SurfaceRect+8]
    api ClientToScreen,[hwnd],SurfaceRect

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
    debugmsg "surface lost"
    com IDirectDrawSurface.Restore,DxsFg
    debugmsg "restore=%X",eax
    cmp eax,DDERR_WRONGMODE
    jne .NotLost

    ; release old primary surface
    debugmsg "releasing primary surface"
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
    debugmsg "recreate primary surface result=%X",eax
    test eax,eax
    jns .NotLost
    ret
.NotLost:

    com IDirectDrawSurface.Lock,DxsFg, 0,ddsd,DDLOCK_SURFACEMEMORYPTR,0 ;|DDLOCK_WAIT
    test eax,eax
    jns .NoErr
    debugmsg "lock error"
    ret
.NoErr:

%if 0 ;black vertical lines
    mov edi,[ddsd+DDSURFACEDESC.lpSurface]
    mov ecx,800*600*2/4
.Next:
    ;xor dword [edi],33333333h
    ;not dword [edi]
    ;and dword [edi],0000FFFFh
    mov word [edi],0h
    add edi,byte 4
    dec ecx
    jg .Next

%elif 0 ;blue hash
    mov edi,[ddsd+DDSURFACEDESC.lpSurface]
    mov edx,600
.NextRow:
    mov ecx,800*2/4
.NextCol:
    mov word [edi],1Fh
    add edi,byte 4
    dec ecx
    jg .NextCol
    xor edi,2
    dec edx
    jg .NextRow

%elif 1
    mov edi,[SurfaceRect+RECT.top]
    mov edx,SurfaceHeight
    imul edi,[ddsd+DDSURFACEDESC.lPitch]
    mov ecx,[SurfaceRect+RECT.left]
    mov esi,SurfacePixels
    xor ebx,ebx
    add edi,[ddsd+DDSURFACEDESC.lpSurface]
    mov eax,[ddpf+DDPIXELFORMAT.dwRGBBitCount]
    push dword .EndBlit
    cld
    ; (edi=screen ptr, esi=source image, ecx=left, eax=bits, ebx=null ptr)

.8bit:
    cmp eax,8
    jne .16bit

;-- 8bit
    add edi,ecx
.NextRow8:
    mov ecx,SurfaceWidth/4
    rep movsd
    add edi,[ddsd+DDSURFACEDESC.lPitch] ;(800-SurfaceWidth)
    dec edx
    lea edi,[edi-SurfaceWidth]
    jg .NextRow8
    ret

.16bit:
    cmp eax,16
    jne .24bit

;-- 16bit (also works for 15bit)
    lea edi,[edi+ecx*2]
.NextRow16:
    mov ecx,SurfaceWidth/2
.NextCol16:
    mov bl,[esi+1]
    mov eax,[SurfacePalMap+ebx*4]
    mov bl,[esi]
    shl eax,16
    or eax,[SurfacePalMap+ebx*4]
    add esi,byte 2
    stosd
    dec ecx
    jg .NextCol16
    add edi,[ddsd+DDSURFACEDESC.lPitch] ;(800-SurfaceWidth)*2
    dec edx
    lea edi,[edi-(SurfaceWidth*2)]
    jg .NextRow16
    ret

.24bit:
    cmp eax,24
    jne .32bit

;-- 24bit
    lea ecx,[ecx*2+ecx]
    add edi,ecx
.NextRow24:
    mov ecx,SurfaceWidth
.NextCol24:
    mov bl,[esi]
    mov eax,[SurfacePalMap+ebx*4]
    add eax,0F0F0F0h
    mov [edi],ax
    shr eax,8
    inc esi
    mov [edi+2],ah
    add edi,byte 3
    dec ecx
    jg .NextCol24
    add edi,[ddsd+DDSURFACEDESC.lPitch] ;(800-SurfaceWidth)*3
    dec edx
    lea edi,[edi-(SurfaceWidth*3)]
    jg .NextRow24
    ret

.32bit:
    cmp eax,32
    jne .UnknownBits

;-- 32bit
    lea edi,[edi+ecx*4]
.NextRow32:
    mov ecx,SurfaceWidth/2
.NextCol32:
    mov bl,[esi]
    mov eax,[SurfacePalMap+ebx*4]
    mov [edi],eax
    mov bl,[esi+1]
    mov eax,[SurfacePalMap+ebx*4]
    mov [edi+4],eax
    add esi,byte 2
    add edi,byte 8
    dec ecx
    jg .NextCol32
    add edi,[ddsd+DDSURFACEDESC.lPitch] ;(800-SurfaceWidth)*4
    dec edx
    lea edi,[edi-(SurfaceWidth*4)]
    jg .NextRow32

.UnknownBits:
    ret
.EndBlit:
%endif

    com IDirectDrawSurface.Unlock,DxsFg, 0
    debugmsg "video mem ptr=%X pitch=%d", [ddsd+DDSURFACEDESC.lpSurface], [ddsd+DDSURFACEDESC.lPitch]
    debugmsg "bitdepth=%d", [ddpf+DDPIXELFORMAT.dwRGBBitCount]
    ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
TestDibBlit:
    ; get window DC
    ; create device dependant bitmap from linear bitmap
    ; blit bitmap
    ; release DC

    ;api GetDC, 0
    ;push eax
    ;debugmsg "get hdc=%X",eax
    ;api SetPixelV, eax,0,0,0FFFFFFh
    ;api ReleaseDC, 0 ;,[hdc]
    ;debugmsg "release dc=%X",eax

%if 1
    api BeginPaint, [hwnd],ps
    debugmsg "begin paint=%X",eax
    xor eax,eax
    api SetDIBitsToDevice, [hdc],eax,eax, SurfaceWidth,SurfaceHeight,eax,eax, eax,SurfaceHeight, SurfacePixels,SurfaceHeader,DIB_RGB_COLORS
    debugmsg "set di bits=%X",eax
    api EndPaint, [hwnd],ps
    debugmsg "end paint=%X",eax
%endif

%if 0 ;draw solid redraw area of cycling color
    api BeginPaint, [hwnd],ps
    debugmsg "begin paint=%X",eax
    ;test eax,eax
    ;jz near .Uhoh
    api CreateSolidBrush, [BrushColor]
    debugmsg "create solid brush=%X",eax
    api SelectObject,[ps],eax
    debugmsg "select solid brush=%X",eax
    api DeleteObject,eax
    debugmsg "delete previous brush=%X",eax
    api Rectangle, [ps], 0,0, 640,480
    debugmsg "draw rectangle=%X",eax
    add dword [BrushColor],201030h
    api EndPaint, [hwnd],ps
    debugmsg "end paint=%X",eax
.Uhoh:
%endif

%if 0 ;blit by creating a bitmap
    api GetDC, [hwnd]
    mov [hdc],eax
    debugmsg "get hdc=%X",eax
    api CreateDIBitmap, eax,SurfaceHeader,CBM_INIT,SurfacePixels,SurfaceHeader,DIB_RGB_COLORS
    debugmsg "create bitmap=%X",eax
    push eax
    api CreateCompatibleDC, [hdc]
    debugmsg "bmp hdc=%X",eax
    push eax

    ;api SetPixelV, [hdc],0,0,0FFFFFFh
    api SelectObject, eax,[esp+4]
    debugmsg "select gdi=%X",eax
    api BitBlt, [hdc],0,0,SurfaceWidth,SurfaceHeight, [esp+12], 0,0, SRCCOPY
    debugmsg "bit blit=%X",eax

    ;pop eax
    api DeleteDC;, eax
    debugmsg "delete hdc=%X",eax
    ;pop eax
    api DeleteObject;, eax
    debugmsg "delete object=%X",eax
    ;api ReleaseDC, [hwnd],[hdc]    (class DCs need not be released)
    ;debugmsg "release dc=%X",eax
%endif
    ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Frees resources used by a COM interface, first checking if already null,
; setting it to null (so it isn't released again), then calling its release
; function.
;
; (dword com object indirect ptr)
; (HRESULT)
ReleaseCom:
    mov edx,[esp+4]             ;get indirect ptr to COM object
    xor eax,eax
    xchg [edx],eax              ;null COM ptr and get previous
    test eax,eax
    jz .Ret                     ;already null
    ;debugmsg "setting COM object null"
    mov edx,[eax]               ;get function table
    mov [esp+4],eax             ;pass object
    jmp [edx+8]                 ;call release function
.Ret:
    ;debugmsg "COM object already null"
    ret 4

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
section data

hwnd:       dd 0
hdc:        dd 0
DxDraw:     dd 0
DxsFg:      dd 0

wc:
istruc WNDCLASS
at WNDCLASS.style,         dd CS_CLASSDC
at WNDCLASS.lpfnWndProc,   dd MsgProc
at WNDCLASS.cbClsExtra,    dd 0
at WNDCLASS.cbWndExtra,    dd 0
at WNDCLASS.hInstance,     dd 400000h ;NULL (default image base is at 4MB)
at WNDCLASS.hIcon,         dd NULL
at WNDCLASS.hCursor,       dd NULL
at WNDCLASS.hbrBackground, dd NULL ;COLOR_BTNFACE + 1
at WNDCLASS.lpszMenuName,  dd NULL
at WNDCLASS.lpszClassName, dd ProgramClass
iend

SurfaceRect:
SurfacePoint equ SurfaceRect
dd 0,            0             ;left,top
dd SurfaceWidth, SurfaceHeight ;right,bottom

CursorClipRect:
dd -2000,100
dd 2000,500

BrushColor: dd 404040h

SurfaceHeader:
dd BITMAPINFOHEADER_size        ;.biSize
dd SurfaceWidth                 ;.biWidth
dd -SurfaceHeight               ;.biHeight
dw 1                            ;.biPlanes
dw 8                            ;.biBitCount
dd 0                            ;.biCompression
dd SurfaceWidth*SurfaceHeight   ;.biSizeImage
dd 0                            ;.biXPelsPerMeter
dd 0                            ;.biYPelsPerMeter
dd 256                          ;.biClrUsed
dd 256                          ;.biClrImportant
SurfacePalette: incbin "drawtest.pal"
SurfacePixels:  incbin "\tempfile\untitle2.lbm" ;"drawtest.lbm"
SurfacePalMap:  incbin "drawtest.rgb"

section text
ProgramClass:   db "PknDdrawTest",0
ErrMsgFatal:    db "Peekin's Test: Fatal Error",0
ErrMsgDxInit:   db "DirectDraw would not initialize",0
ErrMsgCoopLevel:db "Setting DirectDraw cooperative level",0
ErrMsgGfxMode:  db "Setting screen mode",0
ErrMsgSurface:  db "Creating drawing surface",0
ErrMsgRegWin:   db "Registering window class",0
ErrMsgWinCreate:db "Creating window",0

section bss
alignb 4
waste:      resd 1                  ;dummy variable for routines that write back
msg:        resb MSG_size
ddsd:       resb DDSURFACEDESC_size
ddpf        equ ddsd+DDSURFACEDESC.ddpfPixelFormat
ps:         resb PAINTSTRUCT_size

BgBmpHdr:   resb BITMAPINFOHEADER_size

BgBuffer:   resb 320*SurfaceHeight
