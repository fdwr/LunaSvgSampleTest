; GFXTEST.ASM - Tester for Plain Graphics Routines
; 20040802
;______________________________________________________________________________

section .text

%ifndef DosVer
%define WinVer
%endif

%ifdef WinVer
; Include Windows definitions/constants/macros
;%define debug
;%define UseConsoleDebug
;%ifdef UseWindowAll
;%define UseWindowSysVars
%define UseWindowStyles
%define UseWindowMsgs
%define UseWindowGfx
%define UseWindowPaint
%define UseErrorCodes
%define UseWindowControls
%include "mywininc.asm"         ;standard Windows constants, structs...

%include "pgfxtest.h"
%include "..\src\pgfx.h"
%include "..\..\win\atrblist\atrblist.h"	; for attribute list

%endif

global Main
global _main

;//////////////////////////////////////////////////////////////////////////////
;// WINDOWS VERSION                                                          //
;//////////////////////////////////////////////////////////////////////////////
%ifdef WinVer

_main:	;redudant entry point for messed up C linkers
Main:

;///////////////////////////////////////
; Window variables
section .data
.hwnd:		dd 0
.hdc:		dd 0
.wc:
istruc WNDCLASS
at WNDCLASS.style,         dd CS_CLASSDC
at WNDCLASS.lpfnWndProc,   dd WndProc
at WNDCLASS.cbClsExtra,    dd 0
at WNDCLASS.cbWndExtra,    dd 0
at WNDCLASS.hInstance,     dd 400000h ;NULL (default image base is at 4MB)
at WNDCLASS.hIcon,         dd NULL
at WNDCLASS.hCursor,       dd NULL
at WNDCLASS.hbrBackground, dd COLOR_BACKGROUND+1
at WNDCLASS.lpszMenuName,  dd NULL
at WNDCLASS.lpszClassName, dd .Class
iend

.ScreenRect: dd 0,0,800,600
.PanelHwnd:	dd 0

;///////////////////////////////////////
; Attribute list
section .data
.PanelAl:
istruc AttribList
at AttribList.total,	dd .PanelAl_entries
at AttribList.selected,	dd 8
at AttribList.top,		dd 0
at AttribList.himl,		dd NULL
iend
dd	AlfSeparatorType, 0, NULL
	dd NULL
dd	AlfTitleType, 0, NULL
	stringptrwz "Blending Operation"
dd	AlfToggle|AlfNoCheckImage|IdBlitNop, 0, NULL
	stringptrwz "BlitNop",0,"< BlitNop >"
dd	AlfToggle|AlfNoCheckImage|IdBlitOpaque32i32i, 0, NULL
	stringptrwz "BlitOpaque32i32i",0,"< BlitOpaque32i32i >"
dd	AlfToggle|AlfNoCheckImage|IdBlitOpaque8i8i, 0, NULL
	stringptrwz "BlitOpaque8i8i",0,"< BlitOpaque8i8i >"
dd	AlfToggle|AlfNoCheckImage|IdBlitOpaque32i32c, 0, NULL
	stringptrwz "BlitOpaqueColor32i32c",0,"< BlitOpaqueColor32i32c >"
dd	AlfToggle|AlfNoCheckImage|IdBlitOpaque8i8c, 0, NULL
	stringptrwz "BlitOpaqueColor8i8c",0,"< BlitOpaqueColor8i8c >"
dd	AlfToggle|AlfNoCheckImage|IdBlitTransFast32i32i, 0, NULL
	stringptrwz "BlitTransFast32i32i",0,"< BlitTransFast32i32i >"
dd	AlfToggle|AlfNoCheckImage|IdBlitAdd32i32i|AlfChecked, 0, NULL
	stringptrwz "BlitAdd32i32i",0,"< BlitAdd32i32i >"
dd	AlfToggle|AlfNoCheckImage|IdBlitAdd8i8i, 0, NULL
	stringptrwz "BlitAdd8i8i",0,"< BlitAdd8i8i >"
dd	AlfToggle|AlfNoCheckImage|IdBlitAdd32i32c, 0, NULL
	stringptrwz "BlitAddColor32i32c",0,"< BlitAddColor32i32c >"
dd	AlfToggle|AlfNoCheckImage|IdBlitAdd8i8c, 0, NULL
	stringptrwz "BlitAddColor8i8c",0,"< BlitAddColor8i8c >"
dd	AlfToggle|AlfNoCheckImage|IdBlitSub32i32i, 0, NULL
	stringptrwz "BlitSub32i32i",0,"< BlitSub32i32i  >"
dd	AlfSeparatorType, 0, NULL
	dd NULL
dd	AlfTitleType, 0
	stringptrwz "Options"
	dd NULL
dd	AlfToggle|IdBlitMMX, 0
	stringptrwz "Use MMX: "
	stringptrwz "no",0,"yes"
dd	AlfSeparatorType, 0
	dd NULL
	dd NULL
dd	AlfTitleType, 0
	stringptrwz "Graphic sources"
	dd NULL
stringw .GraphicChoices, "216 web-colors map",0,"grayscale map",0,"horizontal color bars",0,"vertical color bars",0,"fairy mask",0,"radial mask",0,"vertical mask",0,"horizontal mask",0,"isudon_ff4-hi.jpg",0,"ghost_r&n.jpg",0,"ghost_fairy.jpg",0,0
.AliGfxSrc:
dd	AlfMenu|IdGfxSrc1|AlfMenuValue(8), 0
	stringptrwz "graphic 1: "
	dd .GraphicChoices
dd	AlfMenu|IdGfxSrc2|AlfMenuValue(1), 0
	stringptrwz "graphic 2: "
	dd .GraphicChoices
dd	AlfMenu|IdGfxSrc3|AlfMenuValue(9), 0
	stringptrwz "graphic 3: "
	dd .GraphicChoices

.PanelAl_entries equ (($-.PanelAl)-AttribList_size)/AttribListItem_size

;///////////////////////////////////////
; Images
.BlendOp:	dd 6	; blending operation - how to combine graphic sources

.dibWidth	equ 256
.dibHeight	equ 224
.dibPixels	equ .dibWidth*.dibHeight
.dibInfo1:	dd BITMAPINFOHEADER_size
			dd .dibWidth
			dd -.dibHeight
			dw 1
			dw 1
			dd BI_RGB
			dd .dibPixels/8
			dd 10000
			dd 10000
			dd 2
			dd 2
			db 0,0,0,0
			db 255,255,255,0
.dibInfo8:	dd BITMAPINFOHEADER_size
			dd .dibWidth
			dd -.dibHeight
			dw 1
			dw 8
			dd BI_RGB
			dd .dibPixels*1
			dd 10000
			dd 10000
			dd 256
			dd 236
			incbin "data\gray.pal"
.dibInfo32:	dd BITMAPINFOHEADER_size
			dd .dibWidth
			dd -.dibHeight
			dw 1
			dw 32
			dd BI_RGB
			dd .dibPixels*4
			dd 10000
			dd 10000
			dd 0
			dd 0

.BlendOpInfoTbl: ; MUST be in same order as IDs!
db	0,0,	0,0,	0,0,	0,0	; IdBlitNop
db	32,255,	32,255,	32,255,	0,0	; IdBlitOpaque32i32i
db	8, 255,	8, 255,	8, 255,	0,0	; IdBlitOpaque8i8i
db	32,255,	32,255,	32,255,	0,0	; IdBlitOpaque32i32c
db	8, 255,	8, 255,	8, 255,	0,0	; IdBlitOpaque8i8c
db	32,255,	32,255,	32,255,	0,0	; IdBlitTransFast32i32i
db	32,255,	32,255,	32,255,	0,0	; IdBlitAdd32i32i
db	8, 255,	8, 255,	8, 255,	0,0	; IdBlitAdd8i8i
db	32,255,	32,255,	32,255,	0,0	; IdBlitAdd32i32c
db	8, 255,	8, 255,	8, 255,	0,0	; IdBlitAdd8i8c
db	32,255,	32,255,	32,255,	0,0	; IdBlitSub32i32i

section .bss
.GfxSrcBpps:	resd 4
.GfxSrcTypes:	resd 4
.GfxSrcPtrs:	resd 4
section .data
.GfxSrcChosen:	dd 8,8,1,9

.ImagesTotal equ 11
section .bss
.Images01bpp:	resb (.dibPixels*.ImagesTotal)/8
.Images01bpp_size equ $-.Images01bpp
.Images08bpp:	resb .dibPixels*1*.ImagesTotal
.Images08bpp_size equ $-.Images08bpp
.Images32bpp:	resb .dibPixels*4*.ImagesTotal
.Images32bpp_size equ $-.Images32bpp
.Display:		resb .dibPixels*4 *2 ; double size for protection
section .data
.ImgData01bpp:	incbin "data\images01.zlg"
.ImgData01bpp_size equ $-Main.ImgData01bpp
.ImgData08bpp:	incbin "data\images08.zlg"
.ImgData08bpp_size equ $-Main.ImgData08bpp
.ImgData32bpp:	incbin "data\images32.zlg"
.ImgData32bpp_size equ $-Main.ImgData32bpp

;///////////////////////////////////////
; User rectangles
section .bss
.FormRectsTotal	equ 20
.FormRectSize	equ 8
.FormRects:		resw 4*.FormRectsTotal
.FormRectsEnd:
.FrGfxSrc0 		equ 0
.FrGfxSrc1 		equ 1
.FrGfxSrc2 		equ 2
.FrGfxSrc3 		equ 3
.FrMinButton	equ 4
.FrCloseButton	equ 5
.FrLastButton	equ 5

;///////////////////////////////////////
section .string
	.Caption:			db "Piken's GFX Tester",0
	.Class:				db "PknGfxTester",0
	.ErrMsgWinReg:  	db "Could not register main window!",0
	.ErrMsgWinCreate:	db "Could not create main window!",0
;///////////////////////////////////////
section .text

	; register windows
	xor ebx,ebx
	api GetModuleHandle, ebx
	mov [.wc+WNDCLASS.hInstance],eax
	api LoadIcon, [.wc+WNDCLASS.hInstance], 1
	mov [.wc+WNDCLASS.hIcon],eax
	api LoadCursor, NULL, IDC_ARROW
	mov [.wc+WNDCLASS.hCursor],eax

	debugwrite "registering window class"
	api RegisterClass, .wc
	debugwrite "register result=%X", eax
	test eax,eax
	mov esi,.ErrMsgWinReg
	jz near .EndWithMsg
	extern _wcAtrList
	api RegisterClass, _wcAtrList
	extern _wcAtrOverlay
	api RegisterClass, _wcAtrOverlay

    ; initialize graphics sources
	call FormCalcRects
	call InitGfxSrcInfo

	; expand compressed image data to DIB
	;;push .ImgData01bpp, .ImgData01bpp_size, .Images01bpp, .Images01bpp_size, 1
	;;call DecompressImageData
	push .ImgData08bpp, .ImgData08bpp_size, .Images08bpp, .Images08bpp_size, 8
	call DecompressImageData
	push .ImgData32bpp, .ImgData32bpp_size, .Images32bpp, .Images32bpp_size, 32
	call DecompressImageData
	add esp,byte 3*5*4
	
	call DoBlendOp

	api CreateWindowEx, 0, .Class, .Class, WS_POPUP|WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_MAXIMIZE|WS_SYSMENU|WS_VISIBLE|WS_CLIPCHILDREN, 0,0, [.ScreenRect+RECT.right],[.ScreenRect+RECT.bottom], NULL, NULL, [.wc+WNDCLASS.hInstance], NULL
    ;                      class    title                                pos      size    parent no menu
	debugwrite "window handle=%X", eax
	test eax,eax
	mov esi,.ErrMsgWinCreate
	jz near .EndWithMsg
	mov [.hwnd],eax
	;api GetDC, eax              ;get window class display handle
	;debugwrite "get hdc=%X",eax
    ;mov [.hdc],eax

;//////////////////////////////////////////////////////////////////////////////
; message loop
section .bss
alignb 4
.msg:        resb MSG_size
section .text
    debugwrite "entering main message loop"
.MsgLoop:
    jmp short .MsgGet
.MsgTop:
    api DispatchMessage, .msg
.MsgGet:
    api GetMessage, .msg, NULL, 0, 0
    test eax,eax
    jnz .MsgTop

.End:
    debugwrite "terminating program"
    api ExitProcess,[.msg+MSG.wParam]

.EndWithMsg: ;(esi=msg text ptr)
    debugwrite "terminating program with message"
	api MessageBox, 0, esi, .Caption, MB_OK
    api ExitProcess,[.msg+MSG.wParam]


;//////////////////////////////////////////////////////////////////////////////
WndProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[esp+.wParam+4],[esp+.lParam]
	cmp eax,WM_CREATE
	je .Create
	;cmp eax,WM_NCCREATE
	;je .NcCreate
	;cmp eax,WM_KEYDOWN
	;je .KeyDown
	cmp eax,WM_PAINT
	je near .Paint
	;cmp eax,WM_ERASEBKGND
	;je .RetTrue
	;cmp eax,WM_NCHITTEST
	;je .NcHitTest
	cmp eax,WM_NCPAINT
	je .RetFalse
	cmp eax,WM_LBUTTONDOWN
	je near .LeftPress
	cmp eax,WM_COMMAND
	je near .Command
	cmp eax,WM_ACTIVATE
	je near .Activate
	cmp eax,WM_WINDOWPOSCHANGING
	je .RetFalse
	cmp eax,WM_WINDOWPOSCHANGED
	je .RetFalse
	cmp eax,WM_MOVING
	je .RetTrue
	cmp eax,WM_DESTROY
	je near .Destroy
    ;cmp eax,...
.DefWindowProc:
%ifdef _MSLINK
    jmp _DefWindowProcA@16
%else
    jmp [DefWindowProc]
%endif
.RetTrue:
    mov eax,TRUE
    ret 16
.RetFalse:
    xor eax,eax
    ret 16


;.NcCreate:
;    mov eax,[esp+.lParam]
;    debugwrite "nc size=%d X %d exstyle=%X", [eax+CREATESTRUCT.cx],[eax+CREATESTRUCT.cy],[eax+CREATESTRUCT.dwExStyle]
;    add dword [eax+CREATESTRUCT.cx],200
;    or dword [eax+CREATESTRUCT.dwExStyle],WS_EX_ACCEPTFILES

.Create:
;    api GetClientRect,[esp+.hwnd+4],SurfaceRect
;    debugwrite "retval=%x top=%d left=%d right=%d bottom=%d",eax,[SurfaceRect+4],[SurfaceRect],[SurfaceRect+12],[SurfaceRect+8]
;    api GetWindowLong, [esp+.hwnd+4],GWL_EXSTYLE
;    debugwrite "get exstyle=%X",eax
;    or eax,WS_EX_ACCEPTFILES
;    api SetWindowLong, [esp+.hwnd+8],GWL_EXSTYLE,eax
;    ;mov eax,-1
	api CreateSolidBrush, 0777788h
	push eax
	api GetDC, [esp+.hwnd+4]
    mov [Main.hdc],eax
    ;debugwrite "get hdc=%X",eax
	push eax
	api SelectObject, void,void ;, eax, eax
	api SetBkMode, [Main.hdc],1 ;TRANSPARENT
	api SetTextColor, [Main.hdc],0DDFF99h

    extern _AtrListClassA
    mov edx,[Main.ScreenRect+RECT.bottom]
    ;mov ecx,[Main.ScreenRect+RECT.right]
    sub edx,byte 20				; height
    ;sub ecx,160					; left side
    api CreateWindowEx, 0, _AtrListClassA, _AtrListClassA, WS_CHILD|WS_VISIBLE, 0,20, 160,edx, [esp+.hwnd+4*3], NULL, [Main.wc+WNDCLASS.hInstance], NULL
    mov [Main.PanelHwnd],eax
    api SendMessage, eax, LB_INITSTORAGE, 0,Main.PanelAl

    xor eax,eax
    ret 16

.Paint:
section .bss
.ps:	resb PAINTSTRUCT_size
;.prect: resb RECT_size
section .text
	api BeginPaint, [esp+.hwnd+4], .ps
	api TextOutA, [Main.hdc], 0,0, "PgfxTest 3.0", 8+4
	call FormDraw
	api EndPaint, [esp+.hwnd+4], .ps
	;api ValidateRect, [esp+.hwnd+4], NULL
    xor eax,eax
    ret 16

.Command:
	mov eax,[esp+.wParam]
	mov edx,[esp+.lParam]
	push dword .RetFalse
	cmp eax,IdBlitFirst
	jb .NotCmdBlit
	cmp eax,IdBlitLast
	jbe .CmdBlit
.NotCmdBlit:
	cmp eax,IdBlitMMX
	je .CmdBlitMMX
	cmp eax,IdGfxSrc1
	jb .NotCmdSrc
	cmp eax,IdGfxSrc3
	jbe .CmdGfxSrc
.NotCmdSrc:
	ret

.CmdBlit:
	lea edx,[eax-IdBlitFirst]
	mov [Main.BlendOp],edx
	push Main.PanelAl, eax, IdBlitFirst, IdBlitLast
	call SetAttributeListSelection
	;api InvalidateRect, [Main.hwnd],NULL,FALSE
	call InitGfxSrcInfo
	call DoBlendOp
	jmp FormDraw
	;ret

.CmdBlitMMX:
	extern Pgfx.Flags
	xor dword [Pgfx.Flags],Pgfx.FlagsUseMMX
	;api InvalidateRect, [Main.hwnd],NULL,FALSE
	call DoBlendOp
	jmp FormDraw
	;ret

.CmdGfxSrc:
	sub eax,IdGfxSrc1-1
	%if AttribListItem_size!=16
	%error "AttribListItem_size changed. Update shift instruction to match."
	%endif
	mov edx,eax
	shl eax,4						; get attribute list item
	mov ecx,[Main.AliGfxSrc+eax-AttribListItem_size]	; get flags from item
	shr ecx,AlfCheckedRs			; get selected menu choice
	mov [Main.GfxSrcChosen+edx*4],ecx	; store choice
	push edx
	call SelectGfxSrc				; update image ptr
	call DoBlendOp
	jmp FormDraw
	;ret

.LeftPress:
	mov ecx,[esp+.lParam]
	mov edx,ecx
	and ecx,65535					; x
	sar edx,16						; y
	call FormCheckMouse
	;mov eax,[Main.ScreenRect+RECT.right]
	cmp ecx,160
	ja .Menu
	cmp ecx,160-20
	jge .Close
	cmp ecx,160-40
	jge .Minimize
.Menu:
	xor eax,eax
	ret 16

.Close:
	api DestroyWindow, [esp+.hwnd]
	xor eax,eax
	ret 16
.Minimize:
	api CloseWindow, [esp+.hwnd]
	xor eax,eax
	ret 16
.Activate:
	cmp word [esp+.wParam],WA_INACTIVE
	je .Inactive
	api SetFocus, [Main.PanelHwnd]
.Inactive:
	xor eax,eax
	ret 16

.Destroy:
    debugwrite "destroying window",eax
    api PostQuitMessage,0
    xor eax,eax                 	;is this necessary?
    ret 16

%if 0
.KeyDown:
    cmp [esp+.wParam],byte 20h
    jne .DefWindowProc
    api MessageBox, [hwnd],.KeyDownMsg,.KeyDownMsg,MB_OK
    ret 16
%endif

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

;//////////////////////////////////////////////////////////////////////////////
DoBlendOp:
	push esi,edi
	mov edi,Main.Display
	mov ecx,[Main.GfxSrcBpps+1*4]
	mov esi,[Main.GfxSrcPtrs+1*4]
	mov [Main.GfxSrcBpps+0*4],ecx
	mov dword [Main.GfxSrcPtrs+0*4],Main.Display
	imul ecx,(Main.dibHeight*Main.dibWidth/8)/4
	;cld
	rep movsd
	mov edx,[Main.BlendOp]
	;cmp eax,IdBlitLast
	;jae .
	pop esi,edi
	jmp dword [.BlendOpJtbl+edx*4]

.BlitNop:
	nop	;NOP! :)
	ret
.BlitOpaque32i32i:
	extern BlitOpaque32i32i
	push dword Main.Display,Main.dibWidth*4, dword 20,dword 20, dword Main.dibWidth-40,dword Main.dibHeight-40,  dword [Main.GfxSrcPtrs+2*4],dword Main.dibWidth*4, dword 20,dword 20
	call BlitOpaque32i32i
	add esp,BlitOpaque32i32i_parms*4
	ret
.BlitOpaque8i8i:
	extern BlitOpaque8i8i
	push dword Main.Display,Main.dibWidth, dword 20,dword 20, dword Main.dibWidth-40,dword Main.dibHeight-40,  dword [Main.GfxSrcPtrs+2*4],dword Main.dibWidth, dword 20,dword 20
	call BlitOpaque8i8i
	add esp,BlitOpaque8i8i_parms*4
	ret
.BlitOpaque32i32c:
	extern BlitOpaque32i32c
	mov eax,[Main.GfxSrcPtrs+2*4]
	push dword Main.Display,Main.dibWidth*4, dword 20,dword 20, dword Main.dibWidth-40,dword Main.dibHeight-40,  dword [eax]
	call BlitOpaque32i32c
	add esp,BlitOpaque32i32c_parms*4
	ret
.BlitOpaque8i8c:
	extern BlitOpaque8i8c
	mov eax,[Main.GfxSrcPtrs+2*4]
	push dword Main.Display,Main.dibWidth, dword 20,dword 20, dword Main.dibWidth-40,dword Main.dibHeight-40,  dword [eax]
	call BlitOpaque8i8c
	add esp,BlitOpaque8i8c_parms*4
	ret
.BlitTransKey32i32i:
	extern BlitTransKey32i32i
	push dword Main.Display,Main.dibWidth*4, dword 20,dword 20, dword Main.dibWidth-40,dword Main.dibHeight-40,  dword [Main.GfxSrcPtrs+2*4],dword Main.dibWidth*4, dword 20,dword 20
	call BlitTransKey32i32i
	add esp,BlitTransKey32i32i_parms*4
	ret
.BlitAdd32i32i:
	extern BlitAdd32i32i
	push dword Main.Display,Main.dibWidth*4, dword 20,dword 20, dword Main.dibWidth-40,dword Main.dibHeight-40,  dword [Main.GfxSrcPtrs+2*4],dword Main.dibWidth*4, dword 20,dword 20
	call BlitAdd32i32i
	add esp,BlitAdd32i32i_parms*4
	ret
.BlitAdd8i8i:
	extern BlitAdd8i8i
	push dword Main.Display,Main.dibWidth, dword 20,dword 20, dword Main.dibWidth-40,dword Main.dibHeight-40,  dword [Main.GfxSrcPtrs+2*4],dword Main.dibWidth, dword 20,dword 20
	call BlitAdd8i8i
	add esp,BlitAdd8i8i_parms*4
	ret
.BlitAdd32i32c:
	extern BlitAdd32i32c
	mov eax,[Main.GfxSrcPtrs+2*4]
	push dword Main.Display,Main.dibWidth*4, dword 20,dword 20, dword Main.dibWidth-40,dword Main.dibHeight-40,  dword [eax]
	call BlitAdd32i32c
	add esp,BlitAdd32i32c_parms*4
	ret
.BlitAdd8i8c:
	extern BlitAdd8i8c
	mov eax,[Main.GfxSrcPtrs+2*4]
	push dword Main.Display,Main.dibWidth, dword 20,dword 20, dword Main.dibWidth-40,dword Main.dibHeight-40,  dword [eax]
	call BlitAdd8i8c
	add esp,BlitAdd8i8c_parms*4
	ret
.BlitSub32i32i:
	extern BlitSub32i32i
	push dword Main.Display,Main.dibWidth*4, dword 20,dword 20, dword Main.dibWidth-40,dword Main.dibHeight-40,  dword [Main.GfxSrcPtrs+2*4],dword Main.dibWidth*4, dword 20,dword 20
	call BlitSub32i32i
	add esp,BlitSub32i32i_parms*4
	ret

; MUST be in same order as IDs!
align 4
.BlendOpJtbl:
	dd .BlitNop					; IdBlitNop
	dd .BlitOpaque32i32i		; IdBlitOpaque32i32i
	dd .BlitOpaque8i8i			; IdBlitOpaque8i8i
	dd .BlitOpaque32i32c		; IdBlitOpaque32i32c
	dd .BlitOpaque8i8c			; IdBlitOpaque8i8c
	dd .BlitTransKey32i32i		; IdBlitTransKey32i32i
	dd .BlitAdd32i32i			; IdBlitAdd32x32
	dd .BlitAdd8i8i				; IdBlitAdd8i8i
	dd .BlitAdd32i32c			; IdBlitAdd32i32c
	dd .BlitAdd8i8c				; IdBlitAdd8i8c
	dd .BlitSub32i32i			; IdBlitSub32x32

;//////////////////////////////////////////////////////////////////////////////
DrawGfxSrc:
	paramsrel 12, .gfxsrc, .left, .top
	push edi,ebx
	mov ebx,[esp+.gfxsrc]
	mov ecx,[esp+.left]
	mov edx,[esp+.top]
	mov eax,[Main.GfxSrcBpps+ebx*4]
	test eax,eax
	jz .Blank
	cmp al,8
	jb .1bit
	cmp al,32
	jb .8bit
.32bit:
	mov edi,Main.dibInfo32
	jmp short .Draw
.8bit:
	mov edi,Main.dibInfo8
	jmp short .Draw
.1bit:
	mov edi,Main.dibInfo1
	;jmp short .Draw
.Draw:
	api SetDIBitsToDevice, [Main.hdc], ecx,edx, Main.dibWidth,Main.dibHeight, 0,0, 0,Main.dibHeight, [Main.GfxSrcPtrs+ebx*4], edi, DIB_RGB_COLORS
	pop edi,ebx
	ret 12
.Blank:
	api PatBlt, [Main.hdc], ecx,edx, Main.dibWidth,Main.dibHeight, PATCOPY
	pop edi,ebx
	ret 12

;//////////////////////////////////////////////////////////////////////////////
; Initializes the graphics source table with images for the current blend
; operation. Should be called after the blend operation is changed.
InitGfxSrcInfo:
	push ebx,esi
	mov esi,[Main.BlendOp]
	mov ebx,3
	lea esi,[Main.BlendOpInfoTbl+(esi*2*4)+6]
.Next:
	movzx eax,byte [esi]
	mov [Main.GfxSrcBpps+ebx*4],eax
	mov al,[esi+1]
	mov [Main.GfxSrcTypes+ebx*4],eax
	push ebx
	call SelectGfxSrc
	; ... todo ... ensure that currently selected item is valid
	; for given bitdepth and type
	sub esi,byte 2
	dec ebx
	jge .Next
	pop ebx,esi
	ret

;//////////////////////////////////////////////////////////////////////////////
SelectGfxSrc:
	paramsrel 8, .gfxsrc
	push ebx
	mov ebx,[esp+.gfxsrc]
	mov ecx,[Main.GfxSrcChosen+ebx*4]
	mov eax,[Main.GfxSrcBpps+ebx*4]
	imul ecx,Main.dibPixels
	test eax,eax
	jz .Blank
	cmp al,8
	jb .1bit
	cmp al,32
	jb .8bit
.32bit:
	lea ecx,[Main.Images32bpp+ecx*4]
	jmp short .Set
.8bit:
	add ecx,Main.Images08bpp
	jmp short .Set
.1bit:
	shr ecx,3
	add ecx,Main.Images01bpp
	;jmp short .Set
.Set:
	mov [Main.GfxSrcPtrs+ebx*4],ecx
.Blank:
	pop ebx
	ret 4

;//////////////////////////////////////////////////////////////////////////////
; Checks whether two rectangles intersect without modifying them or producing
; a new rectangle. Just a true/false test.
RectsIntersect:
	paramsrel 12, .rect1, .rect2
	push edi,esi
	mov esi,[esp+.rect1]
	mov edi,[esp+.rect1]
	xor eax,eax					; set initially false
	mov ecx,[esi+RECT.left]
	mov edx,[esi+RECT.top]
	cmp ecx,[edi+RECT.right]
	jge .False
	cmp edx,[edi+RECT.bottom]
	jge .False
	mov ecx,[edi+RECT.left]
	mov edx,[edi+RECT.top]
	cmp ecx,[esi+RECT.right]
	jge .False
	cmp edx,[esi+RECT.bottom]
	jge .False
	inc eax						; set true, they do intersect
.False:
	pop edi,esi
	test eax,eax
	ret 8

;//////////////////////////////////////////////////////////////////////////////
; Calculates the coordinates of the user hotspots
FormCalcRects:
    xor eax,eax
    mov edi,Main.FormRects
    mov ecx,(Main.FormRectsEnd-Main.FormRects)/4
    rep stosd

	; hardcoded coordinates for images
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc0],   200					| (128<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc0+4],(200+Main.dibWidth)	|((128+Main.dibHeight)<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc1],   480					| (128<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc1+4],(480+Main.dibWidth)	|((128+Main.dibHeight)<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc2],   200					| (376<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc2+4],(200+Main.dibWidth)	|((376+Main.dibHeight)<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc3],   480					| (376<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc3+4],(480+Main.dibWidth)	|((376+Main.dibHeight)<<16)

	; caption buttons
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrMinButton],(160-40)|(0<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrMinButton+4],(160-20)|(20<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrCloseButton],(160-20)|(0<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrCloseButton+4],(160-0)|(20<<16)

	ret

;//////////////////////////////////////////////////////////////////////////////
; Checks which rectangle a mouse click is over (if any)
FormCheckMouse:
	ret

;//////////////////////////////////////////////////////////////////////////////
; Calculates the coordinates of the user hotspots
FormDraw:
	push ebx,esi,edi
	mov ebx,Main.FormRectsTotal
.Next:
	; if item visible, expand 16bit coordinates to 32bit
	mov edx,[Main.FormRects+ebx*8+4]
	test edx,edx
	jle .Continue
	mov eax,edx
	and edx,65535				; x
	shr eax,16					; y
	mov [.rect+RECT.right],edx
	mov [.rect+RECT.bottom],eax
	mov ecx,[Main.FormRects+ebx*8]
	mov edx,ecx
	and ecx,65535				; x
	shr edx,16					; y
	mov [.rect+RECT.left],ecx
	mov [.rect+RECT.top],edx

	push dword .Continue
	cmp ebx,Main.FrGfxSrc3
	jbe .GfxSrc
	cmp ebx,Main.FrLastButton
	jbe .CaptionButtons
	add esp,byte 4
.Continue:
	dec ebx
	jge .Next
	pop ebx,esi,edi
	ret

.GfxSrc:
	push ebx,ecx,edx
	call DrawGfxSrc
	ret

.CaptionButtons:
	cmp ebx,5
	mov eax,DFCS_CAPTIONCLOSE|DFCS_FLAT
	je .Close
	mov eax,DFCS_CAPTIONMIN|DFCS_FLAT
.Close:
	api DrawFrameControl, [Main.hdc],.rect, DFC_CAPTION, eax
	ret

section .bss
.rect: resb RECT_size
section .text

;//////////////////////////////////////////////////////////////////////////////
; Set a single choice in an attribute list
SetAttributeListSelection: ;(eax=id selected) (edx=destroyed)
	params .al, .id, .low, .high
	push ebx,esi,edi

	mov edi,[esp+12+.al]
	mov ebx,[esp+12+.id]
	mov ecx,[esp+12+.low]
	mov edx,[esp+12+.high]
	mov esi,[edi+AttribList.total]
	add edi,byte AttribList.al
	test esi,esi
	jle .End
.Next:
	mov eax,[edi+AttribListItem.flags]
	;and eax,AlfIdMask
	cmp ax,cx
	jb .Continue
	cmp ax,dx
	ja .Continue
	cmp ax,bx
	je .Match
	and eax,~AlfChecked
	jmp short .SetFlags
.Match:
	or eax,AlfChecked
	;jmp short .Continue
.SetFlags:
	or eax,AlfRedraw
	mov [edi+AttribListItem.flags],eax
.Continue:
	add edi,byte AttribListItem_size
	dec esi
	jg .Next
.End:
	pop ebx,esi,edi
	ret 16

;//////////////////////////////////////////////////////////////////////////////
; Decompress ZLIB/PNG data to raw DI bits
DecompressImageData:
%ifdef _MSLINK ; static MSVC linked
	params .src, .srclen, .dest, .destlen, .bpp				; parameters

	;lea edx,[esp+.destlen]
	;api compress2, [esp+.dest+16],edx, [esp+.src+8],[esp+.srclen+4], 9 ;Z_BEST_COMPRESSION
	;XTERN int ZEXPORT compress2 OF((Bytef *dest,   uLongf *destLen,
	;                              const Bytef *source, uLong sourceLen,
	;                              int level));

	lea edx,[esp+.destlen]
	extern _uncompress
	push dword [esp+.dest+12],edx, dword [esp+.src+4],dword [esp+.srclen+0]
	;call [_uncompress]
	call _uncompress
	add esp,byte 16
    ;api _uncompress, [esp+.dest+12],edx, [esp+.src+4],[esp+.srclen+0]
	;ZEXTERN int ZEXPORT uncompress OF((Bytef *dest,   uLongf *destLen,
	;                                   const Bytef *source, uLong sourceLen));
	ret

%elif 1 ; plain zlib DLL
	params .src, .srclen, .dest, .destlen, .bpp				; parameters

	;lea edx,[esp+.destlen]
	;api compress2, [esp+.dest+16],edx, [esp+.src+8],[esp+.srclen+4], 9 ;Z_BEST_COMPRESSION
	;XTERN int ZEXPORT compress2 OF((Bytef *dest,   uLongf *destLen,
	;                              const Bytef *source, uLong sourceLen,
	;                              int level));

	lea edx,[esp+.destlen]
	extern uncompress
    api uncompress, [esp+.dest+12],edx, [esp+.src+4],[esp+.srclen+0]
	;ZEXTERN int ZEXPORT uncompress OF((Bytef *dest,   uLongf *destLen,
	;                                   const Bytef *source, uLong sourceLen));
	ret

%else ; statically linked PNG code
%define stacksize (Main.dibHeight*4 + 4*3)
%define espbase esp+12+stacksize

	extern _png_create_read_struct
	extern _png_create_info_struct
	extern _png_set_rows
	extern _png_set_read_fn
	extern _png_read_png
	extern _png_destroy_read_struct

	params .src, .dest, .bpp				; parameters
	push ebx,esi,edi
	sub esp,stacksize
	paramsrel 0,.pngptr, .infoptr, .rows	; local variables

	push .pngverstr, NULL,NULL,NULL
	call _png_create_read_struct
	test eax,eax
	jz near .InitError
	mov ebx,eax
	mov dword [esp+.infoptr],NULL
	mov [esp+.pngptr],eax
	push eax
	call _png_create_info_struct
	test eax,eax
	jz .InfoError

	; initialize row pointers
	lea edi,[esp+.rows]
	mov eax,[espbase+.bpp]
	mov edx,edi
	imul eax,Main.dibWidth/8			; row bytes = (bpp/8) * width
	mov esi,[espbase+.dest]
	mov ecx,Main.dibHeight-1
.NextRow:
	mov [edi+ecx*4],esi
	add esi,eax
	dec ecx
	jge .NextRow

	push ebx,dword [esp+.infoptr+4],edi
    call _png_set_rows

	; read PNG from virtual file (memory)
	//if (setjmp(png_jmpbuf(png_ptr)))
	mov esi,[espbase+.src]
	mov [.cursrc],esi
	push ebx, NULL, .ReadChunk
	call _png_set_read_fn
	push ebx,dword [esp+.infoptr+8], 0, NULL
    call _png_read_png

    ;jmp short .End

.InfoError:
	lea eax,[esp+.infoptr]
	lea edx,[esp+.pngptr]
	push edx,eax,NULL
	call _png_destroy_read_struct
.InitError:
	// Unexpected error initializing PNG library
.End:
	add esp,stacksize
	pop ebx,esi,edi
	ret 12

.ReadChunk:
	paramsrel 12, .pngptr2, .curdest, .len
	push esi,edi
	mov ecx,[esp+.len]
	mov esi,[.cursrc]
	mov edi,[esp+.curdest]
	rep movsb
	mov [.cursrc],esi
	pop esi,edi
	ret

section .bss
.cursrc:	resd 1
section .string
.pngverstr:	db "1.0.8",0
section .text
%endif

;//////////////////////////////////////////////////////////////////////////////
;// DOS VERSION                                                              //
;//////////////////////////////////////////////////////////////////////////////
%else
Main:
	mov ah,9					;print string
	mov edx,.Text
	int 21h
	xor eax,eax
	int 16h
	cmp al,27
	je .End


.End:
    mov eax,4C00h               ;die
	int 21h

section .string
	.Text: db "GFX Tester",13,10
	       db "Ready to start test...$"
section .text
%endif

;______________________________________________________________________________


;    cmp dword [msg+MSG.message],WM_NCLBUTTONDOWN
;    jne .NotNcl
;    api LockWindowUpdate,[hwnd]
;    api LockWindowUpdate,0
;    jmp short .Inside
;.NotNcl:
    ;mov eax,[msg+MSG.message]
    ;call GetWinMsgName
    ;debugwrite "thread msg=%X %s", eax,esi

    ;cmp dword [msg+MSG.message],WM_LBUTTONDOWN
    ;jne .NotLdn
    ;mov dword [msg+MSG.message],WM_SYSCOMMAND
    ;mov dword [msg+MSG.wParam],SC_MOVE
    ;api DispatchMessage, msg
	;cmp dword [msg+MSG.message],WM_LBUTTONUP


%if 0
	extern PgGfx.Flags
	//or dword [PgGfx.Flags],PgGfx.FlagsUseMMX

	push .dibits, .dibWidth*.dibBpp/8, 20,20, 280,200, .dibits2,.dibWidth*.dibBpp/8, 0,0
;%define Blitter BlitOpaque32x32
;%define Blitter BlitAdd32x32
%define Blitter BlitTransKey32x32
;%define Blitter BlitSub32x32
	extern Blitter
	call Blitter
	add esp,byte 10*4

	api GetDesktopWindow
	mov [.hwnd],eax
	api GetDCEx, eax, NULL, DCX_WINDOW|DCX_LOCKWINDOWUPDATE|DCX_CACHE
	mov [.hdc],eax					; assume success
	api SetDIBitsToDevice, eax, 0,0, .dibWidth,.dibHeight, 0,0, 0,.dibHeight, .dibits, .dibinfo, DIB_RGB_COLORS
	;api Rectangle, eax, 0,0, 320,240
	api ReleaseDC, [.hwnd],[.hdc]
	ret
%endif


    ; create instance of window
    ;api AdjustWindowRect, SurfaceRect,WS_CAPTION|WS_POPUP|WS_MINIMIZEBOX|WS_SYSMENU|WS_VISIBLE, FALSE
    ;mov edx,[SurfaceRect+RECT.top]
    ;mov ecx,[SurfaceRect+RECT.left]
    ;sub [SurfaceRect+RECT.bottom],edx
    ;sub [SurfaceRect+RECT.right],ecx
    ;debugwrite "creating window %dx%d",[SurfaceRect+12],[SurfaceRect+8]

