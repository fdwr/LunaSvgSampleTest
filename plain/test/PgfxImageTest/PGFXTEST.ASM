; PGFXTEST.ASM - Tester for Plain Graphics Routines
; 20040802
;______________________________________________________________________________

section .text

%ifdef _WINDOWS
; Include Windows definitions/constants/macros
;%define debug
;%define UseConsoleDebug
;%ifdef UseWindowAll
;%define UseWindowSysVars
%define UseWindowStyles
%define UseWindowMsgs
%define UseWindowGfx
%define UseKeyboard
%define UseWindowPaint
%define UseErrorCodes
%define UseWindowControls
%include "winnasm.inc"         ;standard Windows constants, structs...

%include "pgfxtest.h"
%include "..\pgfx\pgfx.h"
%include "..\..\win\atrblist\atrblist.h"	; for attribute list

%endif

global Main
global _main

;//////////////////////////////////////////////////////////////////////////////
;// WINDOWS VERSION                                                          //
;//////////////////////////////////////////////////////////////////////////////
%ifdef _WINDOWS

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
at WNDCLASS.hbrBackground, dd COLOR_DESKTOP+1
at WNDCLASS.lpszMenuName,  dd NULL
at WNDCLASS.lpszClassName, dd .Class
iend

.ScreenRect: dd 0,0,800,600
.PanelHwnd:	dd 0

;///////////////////////////////////////
; Attribute list

%macro AlBlitItem 2
dd	AlfToggle|AlfNoCheckImage|%1, 0, NULL
	stringptrwz %2,0,%2,"  <<--"
%endmacro

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
AlBlitItem IdBlitNop, "BlitNop"
AlBlitItem IdBlitOpaque32i32i, "BlitOpaque32i32i"
AlBlitItem IdBlitOpaqueLeft32i32i, "BlitOpaqueLeft32i32i"
AlBlitItem IdBlitOpaque8i8i, "BlitOpaque8i8i"
AlBlitItem IdBlitOpaque32i32c, "BlitOpaque32i32c"
AlBlitItem IdBlitOpaque8i8c, "BlitOpaque8i8c"
AlBlitItem IdBlitTrans32i32i|AlfChecked, "BlitTrans32i32i"
AlBlitItem IdBlitTrans32i32c, "BlitTrans32i32c"
AlBlitItem IdBlitTrans32i8i32c, "BlitTrans32i8i32c"
AlBlitItem IdBlitTransFast32i32i, "BlitTransFast32i32i"
AlBlitItem IdBlitTransFast8i8i, "BlitTransFast8i8i"
AlBlitItem IdBlitAdd32i32i, "BlitAdd32i32i"
AlBlitItem IdBlitAdd8i8i, "BlitAdd8i8i"
AlBlitItem IdBlitAdd32i32c, "BlitAdd32i32c"
AlBlitItem IdBlitAdd8i8c, "BlitAdd8i8c"
AlBlitItem IdBlitSub32i32i, "BlitSub32i32i"
AlBlitItem IdBlitMul32i32i, "BlitMul32i32i"
AlBlitItem IdBlitMul8i8i, "BlitMul8i8i"
AlBlitItem IdBlitGreater32i32i, "BlitGreater32i32i"
AlBlitItem IdBlitGreater8i8i, "BlitGreater8i8i"
AlBlitItem IdBlitGreater8i8c, "BlitGreater8i8c"
AlBlitItem IdBlitLesser32i32i, "BlitLesser32i32i"
AlBlitItem IdBlitLesser8i8i, "BlitLesser8i8i"
AlBlitItem IdBlitLesser8i8c, "BlitLesser8i8c"
AlBlitItem IdBlitAnd32i32i, "BlitAnd32i32i"
AlBlitItem IdBlitOr32i32i, "BlitOr32i32i"
AlBlitItem IdBlitPal32i8i32p, "BlitPal32i8i32p"
AlBlitItem IdBlitPal8i32i32p, "BlitPal8i32i32p"
AlBlitItem IdBlitPal32i32i32p, "BlitPal32i32i32p"
AlBlitItem IdBlitScale32i32i, "BlitScale32i32i"
dd	AlfSeparatorType, 0, NULL
	dd NULL
dd	AlfTitleType, 0
	stringptrwz "Options"
	dd NULL
dd	AlfToggle|IdBlitMMX|AlfChecked, 0
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
	stringptrwz "Destination: "
	dd .GraphicChoices
dd	AlfMenu|IdGfxSrc2|AlfMenuValue(1), 0
	stringptrwz "Source a: "
	dd .GraphicChoices
dd	AlfMenu|IdGfxSrc3|AlfMenuValue(9), 0
	stringptrwz "Source b: "
	dd .GraphicChoices
dd	AlfButton|IdGfxReset, 0
	stringptrwz "Reset origins"
	dd NULL
dd	AlfButton|IdLogo, 0
	stringptrwz "Show logo"
	dd NULL
.PanelAl_entries equ (($-.PanelAl)-AttribList_size)/AttribListItem_size

;///////////////////////////////////////
; Images
.BlendOp:	dd IdBlitTrans32i32i-IdBlitFirst	; blending operation - how to combine graphic sources

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
db	0,0,	0,0,	0,0,	0,0		; IdBlitNop
db	32,255,	32,255,	32,255,	0,0		; IdBlitOpaque32i32i
db	8, 255,	8, 255,	8, 255,	0,0		; IdBlitOpaque8i8i
db	32,255,	32,255,	32,255,	0,0		; IdBlitOpaque32i32c
db	8, 255,	8, 255,	8, 255,	0,0		; IdBlitOpaque8i8c
db	32,255,	32,255,	32,255,	0,0		; IdBlitTransFast32i32i
db	32,255,	32,255,	32,255,	0,0		; IdBlitAdd32i32i
db	8, 255,	8, 255,	8, 255,	0,0		; IdBlitAdd8i8i
db	32,255,	32,255,	32,255,	0,0		; IdBlitAdd32i32c
db	8, 255,	8, 255,	8, 255,	0,0		; IdBlitAdd8i8c
db	32,255,	32,255,	32,255,	0,0		; IdBlitSub32i32i
db	32,255,	32,255,	32,255,	0,0		; IdBlitMul32i32i
db	32,255,	32,255,	32,255,	0,0		; IdBlitAnd32i32i
db	32,255,	32,255,	32,255,	0,0		; IdBlitOr32i32i
db	32,255,	32,255,	32,255,	0,0		; IdBlitTrans32i32i
db	32,255,	32,255,	32,255,	0,0		; IdBlitTrans32i32c
db	32,255,	32,255,	32,255,	0,0		; IdBlitOpaqueLeft32i32i
db	8, 255,	8, 255,	8, 255,	0,0		; IdBlitTransFast8i8i
db	8, 255,	8, 255,	8, 255,	0,0		; IdBlitMul8i8i
db	32,255,	32,255,	8, 255,	32,0	; IdBlitPal32i8i32p
db	8, 255,	8, 255,	32,255,	32,0	; IdBlitPal8i32i32p
db	32,255,	32,255,	8,255,	32,0	; IdBlitTrans32i8i32c
db	32,255,	32,255,	32,255,	0,0		; IdBlitGreater32i32i
db	32,255,	32,255,	32,255,	0,0		; IdBlitLesser32i32i
db	8,255,	8,255,	8,255,	0,0		; IdBlitGreater8i8i
db	8,255,	8,255,	8,255,	0,0		; IdBlitLesser8i8i
db	8,255,	8,255,	8,255,	0,0		; IdBlitGreater8i8c
db	8,255,	8,255,	8,255,	0,0		; IdBlitLesser8i8c
db	32,255,	32,255,	32,255,	0,0		; IdBlitScale32i32i
db	32,255,	32,255,	32,255,	32,0	; IdBlitPal32i32i32p

%if IdBlitLast != 40029
%error "Remember to update code here"	
%endif

; Below are the graphic sources used by the blending operations.
; There are four:
;	0 - the composite after blend
;	1 - original (unblended) destination image
;	2 - source image
;	3 - secound source image if present
section .bss
.GfxSrcBpps:	resd 4
.GfxSrcTypes:	resd 4
.GfxSrcPtrs:	resd 4
section .data
.GfxSrcChosen:	dd 8,8,9,9
; Three components are necessary for most blending operations
;	The size of the rectangular area to work with
;	A top/left in the destination
;	A top/left in the source (if only a portion of the bitmap is needed)
; (These values are RESET by a function call)
.GfxDestWidth:	dd Main.dibWidth-40
.GfxDestX:		dd 20
.GfxSrcX:		dd 20
.GfxDestHeight:	dd Main.dibHeight-40
.GfxDestY:		dd 20
.GfxSrcY:		dd 20

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
.ImgData01bpp:	;incbin "data\images01.zlg"   -not compressed right yet
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
.FormRects:		resw 4*.FormRectsTotal	; left,top,bottom,right
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

	call PgfxInit
	call TransSplash.First

	; expand compressed image data to DIB
	;;push .ImgData01bpp, .ImgData01bpp_size, .Images01bpp, .Images01bpp_size, 1
	;;call DecompressImageData
	push .ImgData08bpp, .ImgData08bpp_size, .Images08bpp, .Images08bpp_size, 8
	call DecompressImageData
	push .ImgData32bpp, .ImgData32bpp_size, .Images32bpp, .Images32bpp_size, 32
	call DecompressImageData
	add esp,byte 3*5*4

    ; initialize graphics sources
	call FormCalcRects
	call InitGfxSrcInfo
	call DoBlendOp

	; pause to display logo
	call TransSplash.Wait

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
	cmp dword [.msg+MSG.message],WM_KEYDOWN
	jne .MsgDispatch
	cmp dword [.msg+MSG.wParam],VK_ESCAPE
	je .End
.MsgDispatch:
    api DispatchMessage, .msg
.MsgGet:
    api GetMessage, .msg, NULL, 0, 0
    test eax,eax
    jnz .MsgTop

.End:
	api DestroyWindow, [.hwnd]
    debugwrite "terminating program"
    api ExitProcess,[.msg+MSG.wParam]

.EndWithMsg: ;(esi=msg text ptr)
    debugwrite "terminating program with message"
	api MessageBox, 0, esi, .Caption, MB_OK
    api ExitProcess,[.msg+MSG.wParam]


;//////////////////////////////////////////////////////////////////////////////
WndProc:
    params esp+4, hwnd, message, wParam, lParam

    mov eax,[.message]
    debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[.wParam+4],[.lParam]
	cmp eax,WM_CREATE
	je near .Create
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
	cmp eax,WM_MOUSEMOVE
	je near .MouseMove
	cmp eax,WM_LBUTTONDOWN
	je near .MousePress
	cmp eax,WM_RBUTTONDOWN
	je near .MousePress
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
	cmp eax,WM_NCPAINT
	je .RetFalse
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
;    mov eax,[.lParam]
;    debugwrite "nc size=%d X %d exstyle=%X", [eax+CREATESTRUCT.cx],[eax+CREATESTRUCT.cy],[eax+CREATESTRUCT.dwExStyle]
;    add dword [eax+CREATESTRUCT.cx],200
;    or dword [eax+CREATESTRUCT.dwExStyle],WS_EX_ACCEPTFILES

.Create:
;    api GetClientRect,[.hwnd+4],SurfaceRect
;    debugwrite "retval=%x top=%d left=%d right=%d bottom=%d",eax,[SurfaceRect+4],[SurfaceRect],[SurfaceRect+12],[SurfaceRect+8]
;    api GetWindowLong, [.hwnd+4],GWL_EXSTYLE
;    debugwrite "get exstyle=%X",eax
;    or eax,WS_EX_ACCEPTFILES
;    api SetWindowLong, [.hwnd+8],GWL_EXSTYLE,eax
;    ;mov eax,-1
	api GetDC, [.hwnd]
    mov [Main.hdc],eax
    ;debugwrite "get hdc=%X",eax
	api SetBkMode, [Main.hdc],1 ;TRANSPARENT
	api SetTextColor, [Main.hdc],0DDFF99h
	api CreateSolidBrush, 0777788h
	api SelectObject, [Main.hdc],eax

    extern _AtrListClassA
    mov edx,[Main.ScreenRect+RECT.bottom]
    ;mov ecx,[Main.ScreenRect+RECT.right]
    sub edx,byte 20				; height
    ;sub ecx,160					; left side
    api CreateWindowEx, 0, _AtrListClassA, _AtrListClassA, WS_CHILD|WS_VISIBLE, 0,20, 160,edx, [.hwnd+4*3], NULL, [Main.wc+WNDCLASS.hInstance], NULL
    mov [Main.PanelHwnd],eax
    api SendMessage, eax, LB_INITSTORAGE, 0,Main.PanelAl

    xor eax,eax
    ret 16

.Paint:
section .bss
.ps:	resb PAINTSTRUCT_size
;.prect: resb RECT_size
section .text
	api BeginPaint, [.hwnd+4], .ps
	api TextOutA, [Main.hdc], 0,0, "PgfxTest 3.0", 8+4
	call FormDraw
	api EndPaint, [.hwnd+4], .ps
	;api ValidateRect, [.hwnd+4], NULL
    xor eax,eax
    ret 16

.Command:
	mov eax,[.wParam]
	mov edx,[.lParam]
	push dword .RetFalse
	cmp eax,IdBlitFirst
	jb .NotCmdBlit
	cmp eax,IdBlitLast
	jbe .CmdBlit
.NotCmdBlit:
	cmp eax,IdLogo
	je near TransSplash;.CmdLogo
	cmp eax,IdBlitMMX
	je .CmdBlitMMX
	cmp eax,IdGfxSrc1
	jb .NotCmdSrc
	cmp eax,IdGfxSrc3
	jbe .CmdGfxSrc
	cmp eax,IdGfxReset
	je near .CmdGfxReset
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
	test dword [PgfxFlags],PgfxFlags.hasMMX
	jz .NoMMXSupport
	xor dword [PgfxFlags],PgfxFlags.useMMX
	;api InvalidateRect, [Main.hwnd],NULL,FALSE
	call DoBlendOp
	jmp FormDraw
	;ret
.NoMMXSupport:
	api MessageBox, [Main.hwnd], "Can not enable MMX instructions because your machine does not seem to support them (CPUID bit 24 clear)", "MMX unsupported", MB_OK|MB_ICONWARNING
	ret

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

.CmdGfxReset:
	mov dword [Main.GfxDestWidth],Main.dibWidth-40-2
	mov dword [Main.GfxDestHeight],Main.dibHeight-40-2
	mov dword [Main.GfxDestX],21
	mov dword [Main.GfxDestY],21
	mov dword [Main.GfxSrcX],21
	mov dword [Main.GfxSrcY],21
	call DoBlendOp
	jmp FormDraw

.MouseMove:
	cmp dword [.wParam],MK_LBUTTON
	jne .MouseRet
.MousePress:
	mov ecx,[.lParam]
	mov edx,ecx
	and ecx,65535					; x
	sar edx,16						; y
	push dword [.lParam]
	push dword [.wParam+4]
	call FormCheckMouse
.MouseRet:
	xor eax,eax
	ret 16

.Activate:
	cmp word [.wParam],WA_INACTIVE
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
    cmp [.wParam],byte 20h
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

	unlocals


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
	mov ecx,[Main.BlendOp]
	jmp dword [.BlendOpJtbl+edx*4]

.XiPush:
	pop edx
	mov eax,Main.dibWidth
	cmp byte [Main.BlendOpInfoTbl+ecx*8+2],8
	je .Xi8
	ja .Xi32
	shr eax,2+3
.Xi32:
	shl eax,2
.Xi8:
	push dword [Main.GfxDestWidth],dword [Main.GfxDestHeight]
	push dword [Main.GfxDestX],dword [Main.GfxDestY]
	push dword Main.Display,eax
	jmp edx
	
.XXiPush:	
	pop edx
	mov eax,Main.dibWidth
	cmp byte [Main.BlendOpInfoTbl+ecx*8+4],8
	je .XXi8
	ja .XXi32
	shr eax,2+3
.XXi32:
	shl eax,2
.XXi8:
	push dword [Main.GfxSrcX],dword [Main.GfxSrcY]
	push dword [Main.GfxSrcPtrs+2*4],eax
	jmp edx

.XXcPush:
	pop edx
	mov eax,[Main.GfxSrcPtrs+2*4]
	push dword [eax]
	jmp edx

.XXXcPush:
	pop edx
	mov eax,[Main.GfxSrcPtrs+3*4]
	push dword [eax]
	jmp edx

.XXXpPush: ; (ecx=blend op)
	pop edx
	push dword [Main.GfxSrcPtrs+3*4]
	jmp edx

.BlitNop:
	nop	;NOP! :)
	ret
.BlitOpaque32i32i:
	call .XXiPush
	call .XiPush
	call BlitOpaque32i32i
	add esp,BlitOpaque32i32i_parms*4
	ret
.BlitOpaqueLeft32i32i:
	call .XXiPush
	call .XiPush
	mov byte [esp+BlitOpaqueLeft32i32i_parms*4-1],192
	call BlitOpaqueLeft32i32i
	add esp,BlitOpaqueLeft32i32i_parms*4
	ret
.BlitOpaque8i8i:
	call .XXiPush
	call .XiPush
	call BlitOpaque8i8i
	add esp,BlitOpaque8i8i_parms*4
	ret
.BlitOpaque32i32c:
	call .XXcPush
	call .XiPush
	call BlitOpaque32i32c
	add esp,BlitOpaque32i32c_parms*4
	ret
.BlitOpaque8i8c:
	call .XXcPush
	call .XiPush
	call BlitOpaque8i8c
	add esp,BlitOpaque8i8c_parms*4
	ret
.BlitTrans32i32i:
	call .XXiPush
	call .XiPush
	call BlitTrans32i32i
	add esp,BlitTrans32i32i_parms*4
	ret
.BlitTrans32i32c:
	call .XXcPush
	call .XiPush
	mov byte [esp+BlitTrans32i32c_parms*4-1],192
	call BlitTrans32i32c
	add esp,BlitTrans32i32c_parms*4
	ret
.BlitTransFast32i32i:
	call .XXiPush
	call .XiPush
	call BlitTransFast32i32i
	add esp,BlitTransFast32i32i_parms*4
	ret
.BlitTransFast8i8i:
	call .XXiPush
	call .XiPush
	call BlitTransFast8i8i
	add esp,BlitTransFast8i8i_parms*4
	ret
.BlitAdd32i32i:
	call .XXiPush
	call .XiPush
	call BlitAdd32i32i
	add esp,BlitAdd32i32i_parms*4
	ret
.BlitAdd8i8i:
	call .XXiPush
	call .XiPush
	call BlitAdd8i8i
	add esp,BlitAdd8i8i_parms*4
	ret
.BlitAdd32i32c:
	call .XXcPush
	call .XiPush
	call BlitAdd32i32c
	add esp,BlitAdd32i32c_parms*4
	ret
.BlitAdd8i8c:
	call .XXcPush
	call .XiPush
	call BlitAdd8i8c
	add esp,BlitAdd8i8c_parms*4
	ret
.BlitSub32i32i:
	call .XXiPush
	call .XiPush
	call BlitSub32i32i
	add esp,BlitSub32i32i_parms*4
	ret
.BlitMul32i32i:
	call .XXiPush
	call .XiPush
	call BlitMul32i32i
	add esp,BlitMul32i32i_parms*4
	ret
.BlitMul8i8i:
	call .XXiPush
	call .XiPush
	call BlitMul8i8i
	add esp,BlitMul8i8i_parms*4
	ret
.BlitAnd32i32i:
	call .XXiPush
	call .XiPush
	call BlitAnd32i32i
	add esp,BlitAnd32i32i_parms*4
	ret
.BlitOr32i32i:
	call .XXiPush
	call .XiPush
	call BlitOr32i32i
	add esp,BlitOr32i32i_parms*4
	ret
.BlitPal32i8i32p:
	call .XXXpPush
	call .XXiPush
	call .XiPush
	call BlitPal32i8i32p
	add esp,BlitPal32i8i32p_parms*4
	ret
.BlitPal8i32i32p:
	call .XXXpPush
	call .XXiPush
	call .XiPush
	call BlitPal8i32i32p
	add esp,BlitPal8i32i32p_parms*4
	ret
.BlitTrans32i8i32c:
	call .XXXcPush
	call .XXiPush
	call .XiPush
	call BlitTrans32i8i32c
	add esp,BlitTrans32i8i32c_parms*4
	ret
.BlitGreater32i32i:
	call .XXiPush
	call .XiPush
	call BlitGreater32i32i
	add esp,BlitGreater32i32i_parms*4
	ret
.BlitLesser32i32i:
	call .XXiPush
	call .XiPush
	call BlitLesser32i32i
	add esp,BlitLesser32i32i_parms*4
	ret
.BlitGreater8i8i:
	call .XXiPush
	call .XiPush
	call BlitGreater8i8i
	add esp,BlitGreater8i8i_parms*4
	ret
.BlitLesser8i8i:
	call .XXiPush
	call .XiPush
	call BlitLesser8i8i
	add esp,BlitLesser8i8i_parms*4
	ret
.BlitGreater8i8c:
	call .XXcPush
	call .XiPush
	call BlitGreater8i8c
	add esp,BlitGreater8i8c_parms*4
	ret
.BlitLesser8i8c:
	call .XXcPush
	call .XiPush
	call BlitLesser8i8c
	add esp,BlitLesser8i8c_parms*4
	ret
.BlitScale32i32i:
	push dword 50<<16,50<<16					; scacle size
	push dword 0<<16,0<<16						; scale left,top
	;push dword Main.dibWidth, Main.dibHeight	; src size
	push dword 1, Main.dibHeight					; src size
	call .XXiPush
	call .XiPush
	call BlitScale32i32i
	add esp,UseBlitScale32i32i_parms*4
	ret
.BlitPal32i32i32p:
	call .XXXpPush
	call .XXiPush
	call .XiPush
	call BlitPal32i32i32p
	add esp,BlitPal32i32i32p_parms*4
	ret

; MUST be in same order as IDs!
align 4
.BlendOpJtbl:
	dd .BlitNop
	dd .BlitOpaque32i32i
	dd .BlitOpaque8i8i
	dd .BlitOpaque32i32c
	dd .BlitOpaque8i8c
	dd .BlitTransFast32i32i
	dd .BlitAdd32i32i
	dd .BlitAdd8i8i
	dd .BlitAdd32i32c
	dd .BlitAdd8i8c
	dd .BlitSub32i32i
	dd .BlitMul32i32i
	dd .BlitAnd32i32i
	dd .BlitOr32i32i
	dd .BlitTrans32i32i
	dd .BlitTrans32i32c
	dd .BlitOpaqueLeft32i32i
	dd .BlitTransFast8i8i
	dd .BlitMul8i8i
	dd .BlitPal32i8i32p
	dd .BlitPal8i32i32p
	dd .BlitTrans32i8i32c
	dd .BlitGreater32i32i
	dd .BlitLesser32i32i
	dd .BlitGreater8i8i
	dd .BlitLesser8i8i
	dd .BlitGreater8i8c
	dd .BlitLesser8i8c
	dd .BlitScale32i32i
	dd .BlitPal32i32i32p
%if IdBlitLast != 40029
%error "Remember to update code here"	
%endif


;//////////////////////////////////////////////////////////////////////////////
; Draws a single graphics source, whether destination, source, or composite.
DrawGfxSrc:
	params esp+4+12, gfxsrc, left, top
	push edi,ebx,esi
	mov ebx,[.gfxsrc]
	mov ecx,[.left]
	mov edx,[.top]
	mov eax,[Main.GfxSrcBpps+ebx*4]
	mov esi,[Main.hdc]

	; draw empty square if no bit depth for current blend op
	test eax,eax
	jnz .NonBlank
.Blank:
	api PatBlt, esi, ecx,edx, Main.dibWidth,Main.dibHeight, PATCOPY
	pop edi,ebx,esi
	ret 12
.NonBlank:
	
	; draw graphic source
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
	api SetDIBitsToDevice, esi, ecx,edx, Main.dibWidth,Main.dibHeight, 0,0, 0,Main.dibHeight, [Main.GfxSrcPtrs+ebx*4], edi, DIB_RGB_COLORS

	; outline rectangle	
	test ebx,ebx					; skip composite image
	jz near .NoRect

	api GetStockObject, HOLLOW_BRUSH ; no inside and blue outside
	api SelectObject, esi,eax
	push eax						; save old brush
	api CreatePen, PS_SOLID, 1, 0FFC8A0h
	api SelectObject, esi,eax
	push eax						; save old pen

	mov edi,[Main.GfxDestWidth]		; calc size
	mov eax,[Main.GfxDestHeight]
	mov ecx,[Main.GfxDestX]
	mov edx,[Main.GfxDestY]
	cmp ebx,1
	je .Src1
	mov ecx,[Main.GfxSrcX]
	mov edx,[Main.GfxSrcY]
.Src1:
	add ecx,[.left+8]
	add edx,[.top+8]
	push ecx,edx,ecx,edx
	add dword [esp+8],edi
	add dword [esp+12],eax

	api Rectangle, esi, void,void, void,void

	;pop eax	
	api SelectObject, esi,void		; restore pen
	api DeleteObject, eax
	;pop eax	
	api SelectObject, esi,void		; restore brush
.NoRect:

	pop edi,ebx,esi
	ret 12

	unlocals


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
; Updates the image pointer for the given graphic source after selecting a
; different image index.
SelectGfxSrc:
	params esp+4+4, gfxsrc
	push ebx
	mov ebx,[.gfxsrc]
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

	unlocals


;//////////////////////////////////////////////////////////////////////////////
; Checks whether two rectangles intersect without modifying them or producing
; a new rectangle. Just a true/false test.
RectsIntersect:
	params esp+4+8, rect1, rect2
	push edi,esi
	mov esi,[.rect1]
	mov edi,[.rect1]
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

	unlocals


;//////////////////////////////////////////////////////////////////////////////
; Calculates the coordinates of the user hotspots
FormCalcRects:
    xor eax,eax
    mov edi,Main.FormRects
    mov ecx,(Main.FormRectsEnd-Main.FormRects)/4
    rep stosd

	; hardcoded coordinates for images
	; (selfnote: original row was 128 and 376)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc0],   200					| (0<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc0+4],(200+Main.dibWidth)	|((0+Main.dibHeight)<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc1],   480					| (0<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc1+4],(480+Main.dibWidth)	|((0+Main.dibHeight)<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc2],   200					| (248<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc2+4],(200+Main.dibWidth)	|((248+Main.dibHeight)<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc3],   480					| (248<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrGfxSrc3+4],(480+Main.dibWidth)	|((248+Main.dibHeight)<<16)

	; caption buttons
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrMinButton],(160-40)|(0<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrMinButton+4],(160-20)|(20<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrCloseButton],(160-20)|(0<<16)
	mov dword [Main.FormRects+Main.FormRectSize*Main.FrCloseButton+4],(160-0)|(20<<16)

	ret

;//////////////////////////////////////////////////////////////////////////////
; Checks which rectangle a mouse click is over (if any)
FormCheckMouse:
	params esp+4+12, buttons, xy ; grouped because WM_LBUTTONDOWN message combines them
	push ebx,esi,edi

	mov ebx,Main.FormRectsTotal-1
	mov esi,Main.FormRects+(Main.FormRectsTotal-1)*Main.FormRectSize
	mov eax,[.buttons]
	movsx ecx,word [.xy]	; mouse row and col
	movsx edx,word [.xy+2]
.Next:
	; 
	cmp cx,[esi]				; x < left ?
	jl .Continue
	cmp dx,[esi+2]				; y < top ?
	jl .Continue
	cmp cx,[esi+4]				; x >= right ?
	jge .Continue
	cmp dx,[esi+6]				; y >= bottom ?
	;jge .Continue
	jl .Found
.Continue:
	sub esi,byte Main.FormRectSize	; previous rect
	dec ebx
	jge .Next
	; no rects found under cursor
	; fall through with ebx=-1
	
.Found: ; (ebx=matching rect index)
	push dword .End
	sub cx,[esi]				; mouse x -= left
	sub dx,[esi+2]				; mouse y -= top
	movsx ecx,cx
	movsx edx,dx 
	cmp ebx,Main.FrGfxSrc3
	jbe .GfxSrc
	cmp ebx,Main.FrLastButton
	jbe .CaptionButtons
	add esp,byte 4
.End:	
	pop ebx,esi,edi
	ret 8
	
.CaptionButtons: ; (ebx=rect index, eax=buttons, ecx=x, edx=y)
	cmp ebx,Main.FrCloseButton
	push dword [Main.hwnd]
	je .Close
.Minimize:
	api CloseWindow, void		; hwnd already on stack
	ret
.Close:
	api DestroyWindow, void
	ret

.GfxSrc: ; (ebx=rect index, eax=buttons, ecx=x, edx=y)
	cmp ebx,Main.FrGfxSrc0			; regardless of left/right click
	je .GfxSrc0
	test eax,MK_LBUTTON
	jnz .GfxSrcLeft
.GfxSrcRight: ; right click opens menu to select source image
	add ebx,IdGfxSrc0|AttribListById
	api SendMessage, [Main.PanelHwnd], LB_SETCURSEL, ebx, NULL
	api SendMessage, [Main.PanelHwnd], BM_CLICK, -1, [.xy+4]
.GfxSrcRet:
	ret
.GfxSrcLeft: ; left click sets composition offsets
	cmp ebx,Main.FrGfxSrc1
	je .GfxSrc1
.GfxSrc2:
	mov dword [Main.GfxSrcX],ecx	; set src top/left
	mov dword [Main.GfxSrcY],edx
	call .GfxSrcSafety
	call DoBlendOp
	jmp FormDraw
	;ret
.GfxSrc1:
	mov dword [Main.GfxDestX],ecx	; set dest top/left
	mov dword [Main.GfxDestY],edx
	call .GfxSrcSafety
	call DoBlendOp
	jmp FormDraw
	;ret
.GfxSrc0:
	sub ecx,[Main.GfxDestX]
	jle .GfxSrcRet
	sub edx,[Main.GfxDestY]
	jle .GfxSrcRet
	mov dword [Main.GfxDestWidth],ecx
	mov dword [Main.GfxDestHeight],edx
	call .GfxSrcSafety
	call DoBlendOp
	jmp FormDraw
	;ret
.GfxSrcSafety: ; check dimensions
	mov ecx,[Main.GfxDestWidth]
	mov edx,[Main.GfxDestHeight]
	add ecx,[Main.GfxDestX]				; width+top = bottom
	add edx,[Main.GfxDestY]
	sub ecx,Main.dibWidth				; get amount beyond right
	jle .DestWidthOk
	sub [Main.GfxDestWidth],ecx			; width -= amount over
.DestWidthOk:
	sub edx,Main.dibHeight				; get amount beyond bottom
	jle .DestHeightOk
	sub [Main.GfxDestHeight],edx		; height -= amount over
.DestHeightOk:
	mov ecx,[Main.GfxDestWidth]
	mov edx,[Main.GfxDestHeight]
	add ecx,[Main.GfxSrcX]				; width+top = bottom
	add edx,[Main.GfxSrcY]
	sub ecx,Main.dibWidth				; get amount beyond right
	jle .SrcWidthOk
	sub [Main.GfxSrcX],ecx				; adjust left
.SrcWidthOk:
	sub edx,Main.dibHeight				; get amount beyond bottom
	jle .SrcHeightOk
	sub [Main.GfxSrcY],edx				; adjust top
.SrcHeightOk:
	ret

	unlocals
		

;//////////////////////////////////////////////////////////////////////////////
; Calculates the coordinates of the user hotspots
FormDraw:
	push ebx,esi,edi
	mov ebx,Main.FormRectsTotal-1
.Next:
	; if item visible, expand 16bit coordinates to 32bit
	mov edx,[Main.FormRects+ebx*Main.FormRectSize+4]
	test edx,edx
	jle .Continue
	mov eax,edx
	and edx,65535				; x
	shr eax,16					; y
	mov [.rect+RECT.right],edx
	mov [.rect+RECT.bottom],eax
	mov ecx,[Main.FormRects+ebx*Main.FormRectSize]
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
	cmp ebx,Main.FrCloseButton
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
	params esp+4+12, al, id, low, high
	push ebx,esi,edi

	mov edi,[.al]
	mov ebx,[.id]
	mov ecx,[.low]
	mov edx,[.high]
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

	unlocals


;//////////////////////////////////////////////////////////////////////////////
; Decompress ZLIB/PNG data to raw DI bits
DecompressImageData:
%ifdef _MSLINK ; static MSVC linked
	params esp+4, src, srclen, dest, destlen, bpp				; parameters

	;lea edx,[esp+.destlen]
	;api compress2, [esp+.dest+16],edx, [esp+.src+8],[esp+.srclen+4], 9 ;Z_BEST_COMPRESSION
	;XTERN int ZEXPORT compress2 OF((Bytef *dest,   uLongf *destLen,
	;                              const Bytef *source, uLong sourceLen,
	;                              int level));

	lea edx,[.destlen]
	extern _uncompress
	push dword [.dest+12],edx, dword [.src+4],dword [.srclen+0]
	;call [_uncompress]
	call _uncompress
	add esp,byte 16
    ;api _uncompress, [.dest+12],edx, [.src+4],[.srclen+0]
	;ZEXTERN int ZEXPORT uncompress OF((Bytef *dest,   uLongf *destLen,
	;                                   const Bytef *source, uLong sourceLen));
	ret

%elif 1 ; plain zlib DLL
	params esp+4, src, srclen, dest, destlen, bpp				; parameters

	;lea edx,[.destlen]
	;api compress2, [.dest+16],edx, [.src+8],[.srclen+4], 9 ;Z_BEST_COMPRESSION
	;XTERN int ZEXPORT compress2 OF((Bytef *dest,   uLongf *destLen,
	;                              const Bytef *source, uLong sourceLen,
	;                              int level));

	lea edx,[.destlen]
	extern uncompress
    api uncompress, [.dest+12],edx, [.src+4],[.srclen+0]
	;ZEXTERN int ZEXPORT uncompress OF((Bytef *dest,   uLongf *destLen,
	;                                   const Bytef *source, uLong sourceLen));
	ret

%else ; statically linked PNG code
%define stacksize (Main.dibHeight*4 + 4*3)

	extern _png_create_read_struct
	extern _png_create_info_struct
	extern _png_set_rows
	extern _png_set_read_fn
	extern _png_read_png
	extern _png_destroy_read_struct

	%error "This code must be check for stack correctness"
	params esp+4+12, src, dest, bpp				; parameters
	push ebx,esi,edi
	sub esp,stacksize
	locals 0
	local .pngptr,4
	local .infoptr,4
	local .rows,4

	push .pngverstr, NULL,NULL,NULL
	call _png_create_read_struct
	test eax,eax
	jz near .InitError
	mov ebx,eax
	mov dword [esp+.infoptr],NULL
	mov [.pngptr],eax
	push eax
	call _png_create_info_struct
	test eax,eax
	jz .InfoError

	; initialize row pointers
	lea edi,[.rows]
	mov eax,[.bpp]
	mov edx,edi
	imul eax,Main.dibWidth/8			; row bytes = (bpp/8) * width
	mov esi,[.dest]
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
	mov esi,[.src]
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

	unlocals

.ReadChunk:
	params esp+4+8, pngptr2, curdest, len
	push esi,edi
	mov ecx,[esp+.len]
	mov esi,[.cursrc]
	mov edi,[esp+.curdest]
	rep movsb
	mov [.cursrc],esi
	pop esi,edi
	ret

	unlocals

section .bss
.cursrc:	resd 1
section .string
.pngverstr:	db "1.0.8",0
section .text

%endif

;//////////////////////////////////////////////////////////////////////////////
; Show translucent splash screen 20040925 for fun!
TransSplash:
	api GetTickCount
	mov [.time],eax

	api CreateCompatibleDC, [.hdcd]
	mov [.hdcs],eax
	api CreateDIBSection, eax, Main.dibInfo32,DIB_RGB_COLORS,.dibp, NULL,0
	mov [.dibh],eax
	test eax,eax
	jz near .NoDib

	; get display pixels
	api SelectObject, [.hdcs],eax
	api BitBlt, [.hdcs], 0,0, Main.dibWidth,Main.dibHeight, [.hdcd],(1024-Main.dibWidth)/2,(768-Main.dibHeight)/2, SRCCOPY

	; merge logo
	extern BlitTrans32i32i
	push dword 0,dword 0
	push dword .image,Main.dibWidth*4
	push dword Main.dibWidth,dword Main.dibHeight
	push dword 0,dword 0
	push dword [.dibp],Main.dibWidth*4
	call BlitTrans32i32i
	add esp,BlitTrans32i32i_parms*4

	; redraw back to display
	api BitBlt, [.hdcd], (1024-Main.dibWidth)/2,(768-Main.dibHeight)/2, Main.dibWidth,Main.dibHeight, [.hdcs],0,0, SRCCOPY
	;api GdiFlush
	;api SetDIBitsToDevice, [.hdcd], 0,250, Main.dibWidth,Main.dibHeight, 0,0, 0,Main.dibHeight, [.dibp], Main.dibInfo32, DIB_RGB_COLORS

	api DeleteObject, [.dibh]
.NoDib:
	api DeleteDC, [.hdcs]
	ret

.First:
	api GetDesktopWindow
	mov [.hwnd],eax
	api GetWindowDC, eax
	;api GetDCEx, eax, NULL, DCX_WINDOW|DCX_CACHE|DCX_LOCKWINDOWUPDATE
	mov [.hdcd],eax
	call TransSplash
	api ReleaseDC, [.hwnd],[.hdcd]
	ret

.Wait:
	api GetTickCount
	; 1000 - (now - then)
	sub eax,[.time]
	neg eax
	add eax,100
	jle .NoWait
	api Sleep, eax
.NoWait:
	ret
	
section .bss
alignb 4
.hwnd:	resd 1
.hdcs:	resd 1
.hdcd	equ Main.hdc
.dibh:	resd 1
.dibp:	resd 1
.time:	resd 1
section .data
.image: incbin "data\splash logo.raw"
section .text


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

