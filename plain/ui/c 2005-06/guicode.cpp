/*
File: guicode.cpp
Project: CS419b HW1
Date: 2005-04-08

GUI functions.
*/

/*
Since function pointers in this GUI must NEVER be null, this null item can
be used whenever an item, process, or owner needs to be set to nothing.
Function pointers must always point to valid code, even it is simply a
do-nothing return routine that ignores all messages. That way, the caller
does not need to check for a null pointer every call of its owner.

A few uses of it:
- When the cursor is over no items.
- When items are removed from a container.
- An item has no owner.
- An item that has no container (the main window at top of the heirarchy)
*/

#define guicode_cpp
#include "guidefs.h"
#include "pgfx.h"


//컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

extern "C" int  AckMsg(GuiObj* obj, int msg, ...);
extern "C" int  IgnoreMsg(GuiObj* obj, int msg, ...);
extern "C" int  PlainInit(GuiObj* root);
extern "C" int  PlainDeinit(GuiObj* root);
extern "C" HWND PlainCreateWin(GuiObj* root, LPTSTR title, int left, int top, int width, int height);
extern "C" int  PlainDestroyWin(HWND hwnd);
extern "C" void PlainDrawFrame(HWND hwnd, GuiObj* root);
static LRESULT CALLBACK PlainWindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
void inline PlainWindowProcSetFocus(GuiObj* root, int flags);

extern "C" void WriteMessage(LPTSTR msg, ...); // TEMP


//컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

//-int PlainFlags = 0;

extern "C" GuiObj NullGuiObj = {
	IgnoreMsg,				// item message handler (or intercepting code)
	NULL,					// no owner callback (intentionally cause GPF if attempted)
	&NullGuiObj,			// top level has no container
	GuiObj::null|GuiObj::noKeyFocus|GuiObj::noMouseFocus|GuiObj::hidden|GuiObj::disabled|GuiObj::notFullFocus|GuiObj::redrawAny|GuiObj::fixedLayer|GuiObj::fixedPosition|GuiObj::importantMsgs,
	-1						// use invalid container index
	// ... remaining values zeroed ...
};

#ifdef _WINDOWS
extern "C" MSG PlainThreadMsg = {};	// useful for main thread to use
#endif

extern "C" PlainKeyboard PlainKeyboard = {};

extern "C" PlainMouse PlainMouse = {
	0,0,
	#ifdef _DOS
	0,0,
	#endif
	-32768,-32768,32767,32767,
	0,
	0,0,
	#ifdef _WINDOWS
	NULL,
	#endif
	#ifdef _DOS
	0
	#endif
};

TCHAR* PlainErrorStr = NULL;

//Mouse.Buttons],Mouse.LeftDown|Mouse.RightDown|Mouse.MiddleDown

//컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴


extern "C" int AckMsg(GuiObj* obj, int msg, ...)
{
	return 0;
}

extern "C" int IgnoreMsg(GuiObj* obj, int msg, ...)
{
	return -1;
}

// Basic initialization
// There is very little that can fail in here.
extern "C" int PlainInit(GuiObj* root)
{
    // make cursor visible
	#ifdef _WINDOWS
	PlainMouse.left  = PlainMouse.top    = -32768;
	PlainMouse.right = PlainMouse.bottom =  32767;
	#endif
	#ifdef _DOS
	PlainMouse.left  = PlainMouse.top    = 0;
	PlainMouse.right = PgfxDisplay.width;
	PlainMouse.bottom = PgfxDisplay.height;
	#endif
	#ifdef PlainUseCursor
	PgfxCursorSet(&PlainCursor_Default);
	#endif

	// should verify that root is valid GuiObj
	// so non-null and has correct flags
	root->code(root, GuiMsg::created);

    //call SetItemFocus.OfActive
	return 0;
}

extern "C" int PlainDeinit(GuiObj* root)
{
	root->code(root, GuiMsg::destroyed);

   #ifdef _WINDOWS
    ClipCursor(NULL);
   #endif

	return 0;
}

#ifdef _WINDOWS

/*
#include <stdarg.h>
#include <stdio.h>
void WriteMessage(LPTSTR msg, ...)
{
	char text[1024];
	va_list args;
	va_start(args, msg);
	_vsnprintf(text, sizeof(text)/sizeof(TCHAR), msg, args);
	text[1023] = '\0';
	OutputDebugString(text);
}
*/


extern "C" HWND PlainCreateWin(GuiObj* root, LPTSTR title, int left, int top, int width, int height)
{
	static WNDCLASS wc = {
		CS_OWNDC,
		&PlainWindowProc,
		0,8,	// hdc2 and hdib
		NULL,	// hInstance
		NULL,	// hIcon
		NULL,	// hCursor
		NULL,	// hbrBackground
		NULL,	//lpszMenuName; 
		T("PlainWindowClass"), //lpszClassName; 
	};

	PlainErrorStr = T("");

	// register class if not already registered
	if (!FindAtom(T("PlainWindowClass"))) {
		wc.hInstance = GetModuleHandle(NULL);
		wc.hIcon = LoadIcon(wc.hInstance, (LPCTSTR)1);

		uint8 blank[256];
		memset(&blank[0],   -1, 128);
		memset(&blank[128],  0, 128);
		wc.hCursor = CreateCursor(wc.hInstance, 0,0, 32,32, &blank[0],&blank[128]);
		if (RegisterClass(&wc) == 0) {
			DestroyCursor(wc.hCursor);
			PlainErrorStr = T("PlainCreateWin: can not register window class");
			return NULL;
		}
	}	

	// create window
	HWND hwnd;
	if (top == CW_USEDEFAULT+1) { // center in workspace
		RECT rect;
		SystemParametersInfo(SPI_GETWORKAREA, 0, &rect, FALSE);
		left = (rect.right-rect.top-width)/2 + rect.left;
		top  = (rect.bottom-rect.left-height)/2 + rect.top;
	}
	hwnd = CreateWindowEx(WS_EX_ACCEPTFILES|WS_EX_APPWINDOW,
		T("PlainWindowClass"), title,
		WS_POPUP|WS_CAPTION|WS_SYSMENU|WS_MINIMIZEBOX|WS_CLIPCHILDREN,
		left, top, width, height,
		NULL, // parent
		NULL,
		GetModuleHandle(NULL),
		root // keep track of root attached to window
	);
	if (!hwnd) {
		PlainErrorStr = T("PlainCreateWin: can not create window");
	}

	// initialize graphics

    // more to come...
    // initialize DirectX only if requested by user (otherwise GDI)

	// set up dimensions and other values
	BITMAPINFOHEADER bmih = {
		sizeof(BITMAPINFOHEADER),
		width, -height,
		1,32, BI_RGB,width*height*4,
		0,0, 0,0
	};

	//PgfxDisplay.pixels =
	PgfxDisplay.wrap = width*4;
	PgfxDisplay.left = 0;
	PgfxDisplay.top = 0;
	PgfxDisplay.width = width;
	PgfxDisplay.height = height;
	PgfxDisplay.clip.left = 0;
	PgfxDisplay.clip.top = 0;
	PgfxDisplay.clip.right = width;
	PgfxDisplay.clip.bottom = height;
	PgfxDisplay.redraw.left = 0;
	PgfxDisplay.redraw.top = 0;
	PgfxDisplay.redraw.right = width-1;
	PgfxDisplay.redraw.bottom = height-1;
	PgfxDisplay.hwnd = hwnd;

	// create graphics buffer
	HDC hdc = GetDC(hwnd);
	PgfxDisplay.hdcc = CreateCompatibleDC(hdc);
	if (!PgfxDisplay.hdcc) {
		PlainErrorStr = T("PlainCreateWin: can not create compatible display context");
	}
    PgfxDisplay.hdib = CreateDIBSection(hdc, (BITMAPINFO*)&bmih,DIB_RGB_COLORS, &PgfxDisplay.pixels,NULL,NULL);
	if (!PgfxDisplay.hdib) {
		DeleteDC(PgfxDisplay.hdcc);
		PlainErrorStr = T("PlainCreateWin: can not create graphics buffer");
	}
	//SetWindowLong(hwnd, 0, hdib);
    SelectObject(PgfxDisplay.hdcc, PgfxDisplay.hdib);
	#define _DEBUGBG
	#ifdef _DEBUGBG
	{
		RECT rect;
		HPEN hpen = CreatePen(PS_SOLID, 20, 0xFF00FF);
		SelectObject(PgfxDisplay.hdcc, hpen);
		rect.left = 0; rect.top = 0; rect.right = width; rect.bottom = height;
		FillRect(PgfxDisplay.hdcc, &rect, (HBRUSH)(COLOR_HIGHLIGHT+1));
		rect.left = 20; rect.top = 20; rect.right = width-20; rect.bottom = height-20;
		FillRect(PgfxDisplay.hdcc, &rect, (HBRUSH)(COLOR_BTNSHADOW+1));
		MoveToEx(PgfxDisplay.hdcc, 50,50, NULL);
		LineTo(PgfxDisplay.hdcc, width-50,height-50);
		Pie(PgfxDisplay.hdcc, 100,100, width-100,height-100, width-100,100, width-150,height-100);
		DeleteObject(hpen);
	}
	#endif

	// In case controls want to use Windows for text
	const static LOGFONT lf = {
		16, // lfHeight; 
		0, // LONG lfWidth; 
		0, // LONG lfEscapement; 
		0, // LONG lfOrientation; 
		700, // LONG lfWeight; 
		FALSE, // BYTE lfItalic; 
		FALSE, // BYTE lfUnderline; 
		FALSE, // BYTE lfStrikeOut; 
		ANSI_CHARSET, // BYTE lfCharSet; 
		OUT_RASTER_PRECIS, // BYTE lfOutPrecision; 
		CLIP_DEFAULT_PRECIS, // BYTE lfClipPrecision; 
		PROOF_QUALITY, // BYTE lfQuality; 
		VARIABLE_PITCH|FF_DONTCARE, // BYTE lfPitchAndFamily; 
		"Tahoma", // TCHAR lfFaceName[LF_FACESIZE]; 
	};
	HFONT hf = CreateFontIndirect(&lf);
	SelectObject(PgfxDisplay.hdcc, hf);
	SetBkMode(PgfxDisplay.hdcc, TRANSPARENT);

   #ifdef UseGuiPalette
	#error "Do not compile this yet"
    mov esi,[Display.Palette]
    sub esi,byte 4              ;point two words before, sig and length
    api CreatePalette, esi
    mov [hpal],eax              ;store logical palette handle
    api SelectPalette, [hdc],eax,FALSE
    api RealizePalette, [hdc]
    ;call TransferScreen (do later)
   #endif

	return hwnd;
}


extern "C" int PlainDestroyWin(HWND hwnd)
{
    return DestroyWindow(hwnd);
}


static LRESULT CALLBACK PlainWindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	GuiObj* root = (GuiObj*)GetWindowLong(hwnd, 0);
	/*{
		char text[1024];
		wsprintf(text, "msg=%X  hdcc=%X\r\n", uMsg, PgfxDisplay.hdcc);
		OutputDebugString(text);
	}*/ // hack:

	switch (uMsg) {
	case WM_CREATE:
		SetWindowLong(hwnd, 0, (LONG)((CREATESTRUCT*)lParam)->lpCreateParams); // keep track of root attached to window
		break;

	case WM_PAINT:
		{
			PAINTSTRUCT ps;
			//HDC hdc = GetDC(hwnd);
			PlainDrawFrame(hwnd, root); // combine any drawing into this paint
			//InvalidateRgn(hwnd, NULL, FALSE);
			BeginPaint(hwnd, &ps);
			// api SetDIBitsToDevice, [PgfxDisplay.hdc],eax,eax, Screen.Width,Screen.Height,eax,eax, eax,Screen.Height, [PgfxDisplay.pixels],Display.BmpHeader,DIB_RGB_COLORS
			BitBlt(ps.hdc, 0,0, PgfxDisplay.width,PgfxDisplay.height, PgfxDisplay.hdcc, 0,0, SRCCOPY);
			//MoveToEx(ps.hdc, 100,100, NULL);
			//LineTo(ps.hdc, 300,300);
			RECT rect = {100,100,300,200};
			//GetUpdateRect(hwnd, &rect, FALSE);
			//WriteMessage(T("Top left bottom right = %d,%d %d,%d %d\r\n"), ps.rcPaint.top, ps.rcPaint.left, ps.rcPaint.right, ps.rcPaint.bottom, GetTickCount());
			//FillRect(ps.hdc, &rect, (HBRUSH)(COLOR_DESKTOP+1));
			EndPaint(hwnd, &ps);
			break;
		}

	case WM_NCCALCSIZE:
		return FALSE;
	/*
	case WM_NCPAINT:
		return FALSE;
	case WM_WINDOWPOSCHANGING:
		return FALSE;
	case WM_WINDOWPOSCHANGED:
		return FALSE;
		*/

	case WM_CANCELMODE:
		ReleaseCapture();
		break;
    case WM_CAPTURECHANGED:
		if ((HWND)lParam != PlainMouse.hwnd) {
			PlainMouse.hwnd = NULL;
			PlainMouse.buttons = 0;
			PgfxCursor.col = PgfxCursor.row = 16384;
			PgfxFlags |= PgfxFlags_cursorMove;
			//RedrawWindow(hwnd, NULL,NULL, RDW_INTERNALPAINT|RDW_NOERASE|RDW_NOCHILDREN);
		}
		break;

    //cmp eax,WM_DROPFILES
    //je near .FileDropped

    // case WM_SETCURSOR:
		/*
	case WM_MOVING:
		return TRUE;
		*/
	case WM_NCHITTEST:
		return HTCLIENT;

	case WM_ERASEBKGND:
		return TRUE;

    case WM_SETFOCUS:
		//root->flags &= ~GuiObj.containerFocus;
		//PlainWindowProcSetFocus(root, GuiMsg.keyIn|KeyMsgFlags.windowInOut|KeyMsgFlags.setItem);
		break;
    case WM_KILLFOCUS:
		//root->flags |= GuiObj.containerFocus;
		//PlainWindowProcSetFocus(root, GuiMsg.keyOut|KeyMsgFlags.windowInOut);
		break;

    case WM_DESTROY:
		PostThreadMessage(GetCurrentThreadId(), WM_DESTROY, (unsigned int)hwnd, GetWindowLong(hwnd, 0));
		DeleteDC(PgfxDisplay.hdcc);
		DeleteObject(PgfxDisplay.hdib);
		break;

	case WM_KEYDOWN:
	case WM_KEYUP:
	case WM_CHAR:
	case WM_DEADCHAR:
	case WM_SYSKEYDOWN:
	case WM_SYSKEYUP:
	case WM_SYSCHAR:
	case WM_SYSDEADCHAR:
		// if character
		//   set character
		// else keycode
		//   if release
		//     clear key
		//   else press
		//     set key
		//     if repeat, set flag
		//   endif
		//   set keycode
		// endif
		// call root object

		if (uMsg & 2) { // is character
			// only if not dead character and not control character
			if ((uMsg & 1) || wParam < 32) break;
			PlainKeyboard.msg = GuiMsg::keyChar;
		}
		else { // else press/release
			//TranslateMessage(&msg);

			if (lParam & 0x80000000) { // test transition state (up/down)
				PlainKeyboard.msg = GuiMsg::keyRelease;
				PlainKeyClear(wParam);
			}
			else { // press
				PlainKeyboard.msg = GuiMsg::keyPress;
				if (PlainKeyDown(wParam))
					PlainKeyboard.msg |= KeyMsgFlags::repeat;
				PlainKeySet(wParam);
			}
		}
		PlainKeyboard.code = (int)wParam;
		root->code(root, PlainKeyboard.msg, PlainKeyboard.code);
		break;

	case WM_MOUSEACTIVATE:
		MessageBeep(MB_OK);
		return FALSE;

	//case WM_ACTIVATE:
	//	MessageBeep(MB_ICONEXCLAMATION);
	//	return FALSE;

	case WM_LBUTTONDOWN:
	case WM_LBUTTONUP:
	case WM_MOUSEMOVE:
	case WM_LBUTTONDBLCLK:
	case WM_RBUTTONDOWN:
	case WM_RBUTTONUP:
	case WM_RBUTTONDBLCLK:
	case WM_MBUTTONDOWN:
	case WM_MBUTTONUP:
	case WM_MBUTTONDBLCLK:
	//case WM_MOUSEWHEEL:
	{
		HWND mouseHwnd = PlainMouse.hwnd;
		int msg = 0;
		int buttons = wParam & (MK_LBUTTON|MK_RBUTTON|MK_MBUTTON) & PlainMouse.leftDown;
		int col = LOWORD(lParam), row = HIWORD(lParam);

		//RedrawWindow(hwnd, NULL, NULL, RDW_INTERNALPAINT|RDW_NOERASE|RDW_NOCHILDREN);
		//break;
		//PgfxFlags |= PgfxFlags_redraw|PgfxFlags_cursorMove;

		// if no buttons down
		if (!(buttons & (PlainMouse.leftDown|PlainMouse.middleDown|PlainMouse.rightDown))) {
			mouseHwnd = WindowFromPoint(PlainThreadMsg.pt);
			//-WriteMessage("mouse window at %X\r\n", mouseHwnd);
		}

		// check for mouse enter/exit from main window
		// have to do much compensation for Window's stupidity
		// just to know when the cursor has moved in or out.
		if (mouseHwnd != PlainMouse.hwnd) {
			if (mouseHwnd == hwnd) { // moved in
				PlainMouse.buttons = buttons;
				PgfxCursor.col = col;
				PgfxCursor.row = row;
				SetCapture(hwnd);
				//ConfineCursor.release()
				msg = GuiMsg::mouseIn|MouseMsgFlags::mouseMoved|MouseMsgFlags::setItem|MouseMsgFlags::windowInOut;
			}
			else { // moved out
				PlainMouse.buttons = 0;
				PgfxCursor.col = PgfxCursor.row = 16384;
				msg = GuiMsg::mouseOut|MouseMsgFlags::mouseMoved|MouseMsgFlags::windowInOut;
				ReleaseCapture();
			}
			PlainMouse.hwnd = mouseHwnd;
			PgfxFlags |= PgfxFlags_cursorMove;
		}
		// catch cursor movement
		else if (mouseHwnd == hwnd) {
			PlainMouse.colDif = PgfxCursor.col - col;
			if (PgfxCursor.col != col) {
				if (col < PlainMouse.left) {
					col = PlainMouse.left;
					msg |= MouseMsgFlags::horizontalPush;
				}
				else if (col >= PlainMouse.right) {
					col = PlainMouse.right-1;
					msg |= MouseMsgFlags::horizontalPush;
				}
				else {
					msg |= MouseMsgFlags::mouseMoved;
				}
				PgfxCursor.col = col;
			}
			PlainMouse.rowDif = PgfxCursor.row - row;
			if (PgfxCursor.row != row) {
				if (row < PlainMouse.top) {
					row = PlainMouse.top;
					msg |= MouseMsgFlags::verticalPush;
				}
				else if (row >= PlainMouse.bottom) {
					row = PlainMouse.bottom-1;
					msg |= MouseMsgFlags::verticalPush;
				}
				else {
					msg |= MouseMsgFlags::mouseMoved;
				}
				PgfxCursor.row = row;
			}
			/*if (msg & MouseMsgFlags::horizontalPush|MouseMsgFlags::verticalPush) {
				SetCursorPos(row - HIWORD(lParam) + PlainThreadMsg.pt.y,
								col - LOWORD(lParam) + PlainThreadMsg.pt.x);
			}*/
			
			if (uint8 xor = (PlainMouse.down ^ buttons)) {
				PlainMouse.down     = buttons;
				PlainMouse.pressed  = xor & buttons;
				PlainMouse.released = xor & PlainMouse.pressed;
				if (PlainMouse.pressed) {
					PlainMouse.clickTime = PlainThreadMsg.time - PlainMouse.lastClick;
					PlainMouse.lastClick = PlainThreadMsg.time;
					msg |= GuiMsg::mousePress | (PlainMouse.pressed << MouseMsgFlags::buttonsLs);
					//SetFocus(hwnd);
					SetActiveWindow(hwnd);
				}
				else {
					msg |= GuiMsg::mouseRelease | (PlainMouse.released << MouseMsgFlags::buttonsLs);;
				}
			}
			else if (msg & MouseMsgFlags::mouseMoved) {
				msg |= GuiMsg::mouseMove | (buttons << MouseMsgFlags::buttonsLs);
				PgfxFlags |= PgfxFlags_cursorMove;
			}
		}
		// such a case should not happen, but...
		else {
			//-WriteMessage(" mouse exception hover=%X prev=%X main=%X col=%d row=%d\r\n", mouseHwnd, PlainMouse.hwnd, hwnd, PgfxCursor.col, PgfxCursor.row );
			break;
		}
		// if any message was set in preceding code, send it now
		if (msg & GuiMsg::mask)
			root->code(root, msg, col - root->left, row - root->top);
		break;
	}

	default:
		return DefWindowProc(hwnd, uMsg, wParam, lParam);
	}
	return FALSE;
}

void inline PlainWindowProcSetFocus(GuiObj* root, int flags)
{
	//((WindowObj*)root)->setItemFocus(flags);
}

extern "C" void PlainDrawFrame(HWND hwnd, GuiObj* root)
{
	/*
	if item redraw, cursor change, move, palette change
	hide cursor
	if items
		save vars
		draw all items
		restore vars
	endif
	draw cursor
	*/
	GdiFlush();
    //InvalidateRect(hwnd, (RECT*)&PgfxDisplay.clip, FALSE);
	PgfxCursorHide();
	if (root->flags & GuiObj::redrawAny) {
		root->code(root, GuiMsg::draw);
		InvalidateRect(hwnd, NULL, FALSE);
		root->flags &= ~GuiObj::redrawAny;
	}
	PgfxCursorShow();
	/*
	HPEN hpen = CreatePen(PS_SOLID, 20, 0xFF00FF);
	SelectObject(PgfxDisplay.hdcc, hpen);
	MoveToEx(PgfxDisplay.hdcc, 100,100, NULL);
	LineTo(PgfxDisplay.hdcc, 300,300);
	DeleteObject(hpen);
	*/

	PgfxFlags &= ~(PgfxFlags_redraw|PgfxFlags_cursorSet|PgfxFlags_cursorMove);
}

/*
GetMouseMsg:
%ifdef WinVer

    movzx ebx,byte [msg+MSG.wParam] ;get current buttons (zero top bits)

    ; check for mouse enter/exit from main window
    ; have to do much compensation for Window's stupidity just to know when
    ; the cursor has moved in or out.
    test byte [Mouse.Buttons],Mouse.LeftDown|Mouse.RightDown|Mouse.MiddleDown
    jnz near .Captured
    api WindowFromPoint, [msg+MSG.x],[msg+MSG.y]
    ;debugwrite "hwnd at point = %d",eax
    cmp [Mouse.hwnd],eax
    mov [Mouse.hwnd],eax
    je near .SameOwner
    or byte [Display.RedrawFlags],Display.RedrawCursor|Display.CursorMoved
    cmp [hwnd],eax
    je .MovedIn
.MouseOut: ;(ebx=buttons)
    ;debugwrite "mouse moved out from window"
    mov dword [Mouse.Buttons],0         ;no buttons/presses/releases
    mov dword [Cursor.Row],16384        ;put cursor way off (invisible)
    mov dword [Cursor.Col],16384
    mov eax,Msg.MouseOut|MouseMsgFlags.MouseMoved|MouseMsgFlags.WindowInOut
    clc
    ret
.MovedIn: ;(ebx=buttons)
    mov [Mouse.Buttons],ebx     ;set buttons, no presses/releases
    ;debugwrite "mouse moved in to window"
    movsx edx,word [msg+MSG.lParam+2]   ;sign row
    movsx ecx,word [msg+MSG.lParam]     ;sign column
    mov [Cursor.Row],edx
    mov [Cursor.Col],ecx
    ;mov dword [Cursor.RowDif],0 (not necessary)
    ;mov dword [Cursor.ColDif],0
    api SetCapture, [hwnd]              ;trap mouse so it won't get away
    ;call ConfineCursor.Release
    mov eax,Msg.MouseIn|MouseMsgFlags.MouseMoved|MouseMsgFlags.SetItem|MouseMsgFlags.WindowInOut
    clc
    ret
; same mouse owner as last time, may not mean that mouse is currently owned
; by the GUI window though.
; (eax=window handle)
.SameOwner:
    cmp [hwnd],eax
    je .Captured
    stc
    ret

.Captured: ;(ebx=buttons)
    ;debugwrite "mouse captured"
; check for mouse cursor movement
    movsx edi,word [msg+MSG.lParam+2]   ;sign row
    movsx esi,word [msg+MSG.lParam]     ;sign column
    xor eax,eax                         ;in case no change, clear msg & flags
    mov edx,edi
    mov ecx,esi

    ; determine new row and constrain if necessary
    sub edi,[Cursor.Row]
    mov [Cursor.RowDif],edi
    je .RowSame
    mov al,Msg.MouseMove
    cmp [Cursor.Top],edx
    jg .BeyondTop
    cmp [Cursor.Btm],edx
    jg .RowOk
    mov edx,[Cursor.Btm]
    dec edx
    jmp short .RowConfined
.BeyondTop:
    mov edx,[Cursor.Top]
.RowConfined:
    or eax,MouseMsgFlags.VerticalPush
.RowOk:
    mov [Cursor.Row],edx
    or eax,MouseMsgFlags.MouseMoved
    or byte [Display.RedrawFlags],Display.CursorMoved
.RowSame:

    ; determine new col and constrain if necessary
    sub esi,[Cursor.Col]
    mov [Cursor.ColDif],esi
    je .ColSame
    mov al,Msg.MouseMove
    cmp [Cursor.Left],ecx
    jg .BeyondLeft
    cmp [Cursor.Right],ecx
    jg .ColOk
    mov ecx,[Cursor.Right]
    dec ecx
    jmp short .ColConfined
.BeyondLeft:
    mov ecx,[Cursor.Left]
.ColConfined:
    or eax,MouseMsgFlags.HorizontalPush
.ColOk:
    mov [Cursor.Col],ecx
    or eax,Msg.MouseMove|MouseMsgFlags.MouseMoved
    or byte [Display.RedrawFlags],Display.CursorMoved
.ColSame:

    test eax,MouseMsgFlags.HorizontalPush|MouseMsgFlags.VerticalPush
    jz .Unconfined
    push eax
    sub dx,[msg+MSG.lParam+2]
    sub cx,[msg+MSG.lParam]
    movsx edx,dx
    movsx ecx,cx
    add edx,[msg+MSG.y]         ;get screen column
    add ecx,[msg+MSG.x]         ;get screen row
    api SetCursorPos, ecx,edx
    pop eax
.Unconfined:

; check for mouse presses, releases
.Press:
    and bl,11100111b            ;mask off silly shift and control key
    mov bh,[Mouse.Buttons]
    xor bh,bl                   ;get buttons that have changed since last time
    je .NoPressRelease
    ;mov esi,[Timer.Now]        ;get current tick time
    mov esi,[msg+MSG.time]      ;get time of event
    mov al,bh                   ;copy buttons that have changed state
    and bh,bl                   ;get buttons pressed by ANDing those changed
    jz .NoPress
    mov edi,esi
    sub esi,[Mouse.LastClick]   ;get difference between current and previous
    mov [Mouse.LastClick],edi   ;set last click time
    mov [Mouse.ClickTime],esi   ;set difference for double click comparison
.NoPress:
    ror ebx,8
    mov bh,bl                   ;get buttons released by XORing those changed
    xor bh,al                   ;with ones pressed, leaving releases only
    rol ebx,8
    mov al,Msg.MousePrsRls
.NoPressRelease:
    mov [Mouse.Buttons],ebx     ;set buttons currently down, pressed, and released

    cmp eax,1                   ;sets carry if eax is still zero
    ret

;컴컴컴컴컴컴컴컴컴컴
*/

#endif
