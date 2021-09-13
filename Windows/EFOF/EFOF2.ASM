;=============================================================================
; EFOF2.ASM
;=============================================================================
; EFOF2 - Electric Fields of Force
; Dwayne Robinson / Piken
; 2004-03-27
;
; Shows the electric fields surrounding charged particles in beautiful
; rainbow color.
;=============================================================================

[section code code]
[section data data]
[section text data]
[section bss bss]
%define ProgMemBase 400000h

;%define debug
;%define UseConsoleDebug
%define UseWindowStyles
%define UseWindowMsgs
%define UseWindowSysVars
%define UseWindowGfx
%define UseDxDraw
%include "mywininc.asm"

%include "force.inc"

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text
ProgramTitle: db "Electric Fields of Force",0
ProgramClass: db "PknEfof2",0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
MainHwnd:   dd 0
MainHdc:    dd 0
MainHpal:   dd 0

BmpWidth:   dd 640;320
BmpHeight:  dd 480;240

wc:
istruc WNDCLASS
at WNDCLASS.style,         dd CS_OWNDC
at WNDCLASS.lpfnWndProc,   dd MainWndProc
at WNDCLASS.cbClsExtra,    dd 0
at WNDCLASS.cbWndExtra,    dd 0
at WNDCLASS.hInstance,     dd ProgMemBase ;NULL (default image base is at 4MB)
at WNDCLASS.hIcon,         dd NULL
at WNDCLASS.hCursor,       dd NULL
at WNDCLASS.hbrBackground, dd NULL ;COLOR_BTNFACE + 1
at WNDCLASS.lpszMenuName,  dd NULL
at WNDCLASS.lpszClassName, dd ProgramClass
iend

PointCharges:
DefPointCharge -500000,0, 50*2,50*2, 0,0
DefPointCharge 300000,0, 150*2,160*2, 0,0
DefPointCharge 100000,0, 240*2,40*2, 0,0
DefPointCharge 500000,0, 40*2,40*2, 0,0
DefPointCharge 10000,0, 270*2,70*2, 0,0
DefPointCharge -3000,0, 260*2,180*2, 0,0
DefPointCharge -3000,0, 280*2,200*2, 0,0
DefPointCharge -3000,0, 300*2,220*2, 0,0

PointChargesTotal: dd 8

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section bss
alignb 4
;waste:      resd 1                  ;dummy variable for routines that write back
msg:        resb MSG_size
;ddsd:       resb DDSURFACEDESC_size
;ddpf        equ ddsd+DDSURFACEDESC.ddpfPixelFormat
ps:         resb PAINTSTRUCT_size

BmpInfo:
.bmiHeader: resb BITMAPINFOHEADER_size
.bmiColors: resb RGBQUAD_size*256      ;bmiColors[256]

BmpPixels:  resb 800*600

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code
global Main
Main:
    api LoadCursor, 0,IDC_ARROW
    mov [wc+WNDCLASS.hCursor],eax
    api LoadIcon, ProgMemBase,1
    mov [wc+WNDCLASS.hIcon],eax

    ; register window class
    api RegisterClass, wc
    debugwrite "RegisterClass=%X", eax
    test eax,eax
    stringz ErmWinRegister,"Could not register main window class"
    mov esi,ErmWinRegister
    jz near .EndWithErm

    ; get screen height
    ;api GetSystemMetrics, SM_CXSCREEN
    ;mov [BmpWidth],eax
    ;api GetSystemMetrics, SM_CYSCREEN
    ;mov [BmpHeight],eax

    ; create instance of window
    api CreateWindowEx, WS_EX_TOPMOST, ProgramClass,ProgramTitle, WS_POPUP|WS_MINIMIZEBOX|WS_SYSMENU, 0,0, [BmpWidth],[BmpHeight], NULL, NULL, ProgMemBase, NULL
    ;api CreateWindowEx, 0, ProgramClass,ProgramTitle, WS_POPUP|WS_MINIMIZEBOX|WS_SYSMENU, 100,100, [BmpWidth],[BmpHeight], NULL, NULL, ProgMemBase, NULL
    debugwrite "CreateWindowEx=%X", eax
    test eax,eax
    stringz ErmWinCreate,"Could not create main window"
    mov esi,ErmWinCreate
    jz near .EndWithErm
    mov [MainHwnd],eax
    api GetDC, eax              ;get window class display handle
    debugwrite "GetDC=%X",eax
    mov [MainHdc],eax

    api Rectangle, [MainHdc], 0,0, 2000,2000

    push dword BmpInfo.bmiColors, dword 0
    call EfofPaletteGen
    mov dword [BmpInfo.bmiColors-4],300h|(256<<16) ;hack since GDI will not accept the palette from the bitmap
    api CreatePalette, BmpInfo.bmiColors-4
    mov [MainHpal],eax
    api SelectPalette, [MainHdc],eax,FALSE
    push dword BmpInfo.bmiHeader, dword [BmpWidth],dword [BmpHeight], dword 8
    call BmpHeaderInit

    push dword PointCharges, dword [PointChargesTotal], dword BmpPixels, dword [BmpWidth],dword [BmpHeight],dword 0
    call EfofRender

    api ShowWindow, [MainHwnd], SW_SHOW

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    debugwrite "entering main loop .MsgLoop"
    jmp short .MsgNext
.MsgLoop:
    api DispatchMessage, msg
.MsgNext:
    api GetMessage, msg, NULL, 0, 0
    test eax,eax
    jg .MsgLoop

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.End:
    api DestroyWindow, [MainHwnd]
    api ExitProcess,0

.EndWithErm: ;(esi=error message string)
    api MessageBox, NULL,esi,ProgramTitle,MB_OK|MB_ICONERROR|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST
    ;api DestroyWindow, [MainHwnd]
    api ExitProcess,-1


%if 0
    ;api MessageBox, NULL,"draw to display...",ProgramTitle,MB_OK|MB_INFORMATION|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST
    api CreateDC, "DISPLAY",NULL, 0, NULL
    mov [MainDc],eax
    debugpause "CreateDC=%d",eax
    api Rectangle, [MainDc], 0,0, 800,600
    debugpause "ending"
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MainWndProc:
    params 4, .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]

    cmp eax,WM_ERASEBKGND
    je .RetTrue
    cmp eax,WM_PAINT
    je .Paint
    cmp eax,WM_DESTROY
    je .Destroy
    cmp eax,WM_QUERYNEWPALETTE
    je near .QueryNewPalette
    cmp eax,WM_KEYDOWN
    je near .KeyDown
    cmp eax,WM_LBUTTONDOWN
    je near .MouseLbDown
    cmp eax,WM_MOUSEMOVE
    je near .MouseMove

.DefWindowProc:
    ;extern DefScreenSaverProc
    ;jmp [DefScreenSaverProc]
    jmp [DefWindowProc]
.RetTrue:
    mov eax,TRUE
    ret 16
;.RetFalse:
;    xor eax,eax
;    ret 16

.Destroy:
    api PostQuitMessage,0
    xor eax,eax
    ret 16

.Paint:
    ;api BeginPaint, [MainHwnd],ps
    api SetDIBitsToDevice, [MainHdc], 0,0, [BmpWidth],[BmpHeight], 0,0, 0,[BmpHeight], BmpPixels, BmpInfo,DIB_RGB_COLORS
    ;api EndPaint, [MainHwnd],ps
    api ValidateRect, [MainHwnd],NULL
    xor eax,eax
    ret 16

.QueryNewPalette:
    api RealizePalette, [MainHdc]
    mov eax,TRUE
    ret 16
.KeyDown:
    api PostQuitMessage, 0
    xor eax,eax
    ret 16

.MouseLbDown:
    mov ecx,[esp+.lParam]
    mov edx,ecx
    and ecx,0FFFFh
    shr edx,16
    mov [PointCharges+PointCharge.x],ecx
    mov [PointCharges+PointCharge.y],edx
    push ebx,esi,edi
    push dword PointCharges, dword [PointChargesTotal], dword BmpPixels, dword [BmpWidth],dword [BmpHeight],dword 0
    call EfofRender
    pop ebx,esi,edi
    api InvalidateRect, [MainHwnd],NULL,FALSE
    xor eax,eax
    api PostMessage, [MainHwnd], WM_PAINT, eax,eax
    xor eax,eax
    ret 16

.MouseMove:
    test dword [esp+.wParam],1
    jz .MouseMoveSkip
    mov ecx,[esp+.lParam]
    mov edx,ecx
    and ecx,0FFFFh
    shr edx,16
    mov [PointCharges+PointCharge.x],ecx
    mov [PointCharges+PointCharge.y],edx
    push ebx,esi,edi
    push dword PointCharges, dword [PointChargesTotal], dword BmpPixels, dword [BmpWidth],dword [BmpHeight],dword 0
    call EfofRender
    pop ebx,esi,edi
    api InvalidateRect, [MainHwnd],NULL,FALSE
    xor eax,eax
    api PostMessage, [MainHwnd], WM_PAINT, eax,eax
.MouseMoveSkip:
    xor eax,eax
    ret 16

    unlocals

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (ptr BITMAPINFOHEADER header, int width, int height, int bits)
; ()
BmpHeaderInit:
    params 4, .header, .width, .height, .bits
    mov edi,[esp+.header]
    mov ecx,[esp+.width]
    mov edx,[esp+.height]
    mov ebx,[esp+.bits]
    xor eax,eax                 ; zero value
    neg edx
    mov dword [edi+BITMAPINFOHEADER.biSize],40
    mov dword [edi+BITMAPINFOHEADER.biWidth],ecx
    mov dword [edi+BITMAPINFOHEADER.biHeight],edx   ;-height
    neg edx
    imul edx,ecx
    mov dword [edi+BITMAPINFOHEADER.biPlanes],1
    imul edx,ebx
    mov dword [edi+BITMAPINFOHEADER.biBitCount],ebx
    shr edx,3
    mov dword [edi+BITMAPINFOHEADER.biCompression],eax
    mov dword [edi+BITMAPINFOHEADER.biSizeImage],edx ;(width*height*Bits) >> 3
    mov ecx,256
    mov dword [edi+BITMAPINFOHEADER.biXPelsPerMeter],eax
    mov dword [edi+BITMAPINFOHEADER.biYPelsPerMeter],eax
    mov dword [edi+BITMAPINFOHEADER.biClrUsed],ecx
    mov dword [edi+BITMAPINFOHEADER.biClrImportant],ecx
    ret 4*4

    unlocals


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

%include "force.asm"
