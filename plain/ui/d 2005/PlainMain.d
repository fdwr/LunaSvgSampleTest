/**
Author:	Dwayne Robinson
Date:	2005-11-09
Since:	2005-11-09
Remark:	Main window and thread loop.
		Note that 
*/
module plain.plainmain;

debug private import std.stdio;

public import std.intrinsic;
public import plain.plaindefs;
//public import std.c.windows.windows; // <- the import that comes with DMD is limited. You may need to replace this file with a more complete one.
private import common.windows;
//public import std.c.windows.winutil; // stupid linker errors |:-|
private import plain.plainvue;

////////////////////////////////////////
wchar* PlainErrorStr = "";

align(4) struct PlainKeyboardStruct {
	uint8[256] buttons;
}
static PlainKeyboardStruct PlainKeyboard;

align(4) struct PlainMouseStruct {
	int x,y;
	int yDif, xDif;				// pixel change, ignoring clipping
	version (DOS) {
		int yFine;			// motion counter change in mickeys
		int xFine;
	}
	int left = -32768;				// left pixel of constrained region
	int top = -32768;				// top pixel of constrained region
	int right = 32767;				// right pixel+1 of constrained region
	int bottom = 32767;				// bottom pixel+1 of constrained region
	union {
		uint32 buttons;
		struct {
			uint8 down;		// currently down
			uint8 pressed;	// pressed since last call
			uint8 released;	// released since last call
		}
	}
	// ex: if (PlainMouse.buttons & leftPress) ...
	enum {
		leftDown      = 0x00001,
		rightDown     = 0x00002,
		middleDown    = 0x00004,
		leftPress     = 0x00100,
		rightPress    = 0x00200,
		middlePress   = 0x00400,
		leftRelease   = 0x10000,
		rightRelease  = 0x20000,
		middleRelease = 0x40000
	};
	int lastPress;	// to determine time between clicks
	int pressTime;
	version (Windows) {
		HWND hwnd;
	}
	version (DOS) {
		int numButtons;			// some mouse drivers report 3 when the mouse really only has 2?
	}					// >=0 also indicates the presence of a mouse (else zero if no driver)
};
PlainMouseStruct PlainMouse;

////////////////////////////////////////

// Basic initialization
// There is very little that can fail in here.
extern (C) int PlainInit(PlainVue root)
{
    // make cursor visible
	/*
	version(Windows) {
	PlainMouse.left  = PlainMouse.top    = -32768;
	PlainMouse.right = PlainMouse.bottom =  32767;
	}
	version(DOS) {
		PlainMouse.left  = PlainMouse.top    = 0;
		PlainMouse.right = PgfxCurrentDisplay.width;
		PlainMouse.bottom = PgfxCurrentDisplay.height;
	}
	#ifdef PlainUseCursor
	PgfxCursorSet(&PlainCursor_Default);
	#endif
	*/

	// should verify that root is valid GuiObj
	// so non-null and has correct flags
	if (!(root.flags & PlainVue.Flags.dead))
		root.inserted();

    //call SetItemFocus.OfActive
	return 0;
}

extern (C) int PlainDeinit(PlainVue root)
{
	root.removed();

	version(Windows) {
		//ClipCursor(null);
	}

	return 0;
}


extern (C) HWND PlainCreateWin(PlainVue root, wchar* title, int left, int top, int width, int height)
{
	assert(root != null);

	static WNDCLASS wc = {
		CS_OWNDC,
		&PlainWindowProc,
		0,8,	// hdc2 and hdib
		null,	// hInstance
		null,	// hIcon
		null,	// hCursor
		null,	// hbrBackground
		null,	//lpszMenuName; 
		"PlainWindowClass\0"w, //lpszClassName; 
	};

	PlainErrorStr = "";

	// register class if not already registered
	if (!FindAtomW("PlainWindowClass\0")) {
		wc.hInstance = GetModuleHandleW(null);
		wc.hIcon = LoadIconW(wc.hInstance, cast(LPCWSTR)1);

		// create blank cursor (do not simply hide cursor)
		/*uint8 blank[256];
		memset(&blank[0],   -1, 128);
		memset(&blank[128],  0, 128);
		wc.hCursor = CreateCursor(wc.hInstance, 0,0, 32,32, &blank[0],&blank[128]);
		*/
		wc.hCursor = LoadCursorW(null, cast(LPCWSTR)IDC_ARROW);
		if (RegisterClassW(&wc) == 0) {
			DestroyCursor(wc.hCursor);
			PlainErrorStr = "PlainCreateWin: can not register window class";
			return null;
		}
	}	

	// create window
	HWND hwnd;
	if (top == CW_USEDEFAULT+1) { // center in workspace
		RECT rect;
		SystemParametersInfoW(SPI_GETWORKAREA, 0, &rect, FALSE);
		left = (rect.right-rect.top-width)/2 + rect.left;
		top  = (rect.bottom-rect.left-height)/2 + rect.top;
	}
	hwnd = CreateWindowExW(WS_EX_ACCEPTFILES|WS_EX_APPWINDOW, //|WS_EX_LAYERED,
		"PlainWindowClass\0", title,
		WS_POPUP|WS_CAPTION|WS_SYSMENU|WS_MINIMIZEBOX|WS_CLIPCHILDREN,
		left, top, width, height,
		null, // parent
		null,
		GetModuleHandleW(null),
		root // keep track of root attached to window
	);
	if (!hwnd) {
		PlainErrorStr = "PlainCreateWin: can not create window";
		return null;
	}

	// initialize graphics - maybe should do this in the root code instead

    // more to come...
    // initialize DirectX only if requested by user (otherwise GDI)

	root.width = width;
	root.height = height;

	// set up dimensions and other values
	/*BITMAPINFOHEADER bmih = {
		sizeof(BITMAPINFOHEADER),
		width, -height,
		1,32, BI_RGB,width*height*4,
		0,0, 0,0
	};*/
	BITMAPINFOHEADER bmih;
	with (bmih) {
		biSize = bmih.sizeof;
		biWidth = width;
		biHeight = -height;
		biPlanes = 1;
		biBitCount =32;
		biCompression = BI_RGB;
		biSizeImage = width*height*4;
		biXPelsPerMeter = 0;
		biYPelsPerMeter = 0;
		biClrUsed = 0;
		biClrImportant = 0;
	}

	//PgfxCurrentDisplay.pixels =
	PgfxCurrentDisplay.wrap = width*4;
	PgfxCurrentDisplay.left = 0;
	PgfxCurrentDisplay.top = 0;
	PgfxCurrentDisplay.width = width;
	PgfxCurrentDisplay.height = height;
	PgfxCurrentDisplay.clip.left = 0;
	PgfxCurrentDisplay.clip.top = 0;
	PgfxCurrentDisplay.clip.right = width;
	PgfxCurrentDisplay.clip.bottom = height;
	PgfxCurrentDisplay.redraw.left = 0;
	PgfxCurrentDisplay.redraw.top = 0;
	PgfxCurrentDisplay.redraw.right = width-1;
	PgfxCurrentDisplay.redraw.bottom = height-1;
	PgfxCurrentDisplay.hwnd = hwnd;

	// create graphics buffer
	HDC hdc = GetDC(hwnd);
	PgfxCurrentDisplay.hdcc = CreateCompatibleDC(hdc);
	if (!PgfxCurrentDisplay.hdcc) {
		PlainErrorStr = "PlainCreateWin: can not create compatible display context";
	}
    PgfxCurrentDisplay.hdib = CreateDIBSection(hdc, cast(BITMAPINFO*)&bmih,DIB_RGB_COLORS, &PgfxCurrentDisplay.pixels,null,0);
	if (!PgfxCurrentDisplay.hdib) {
		DeleteDC(PgfxCurrentDisplay.hdcc);
		PlainErrorStr = "PlainCreateWin: can not create graphics buffer";
	}
	//SetWindowLong(hwnd, 0, hdib);
    SelectObject(PgfxCurrentDisplay.hdcc, PgfxCurrentDisplay.hdib);
	version(all)
	{
		RECT rect;
		HPEN hpen = CreatePen(PS_SOLID, 20, 0xFF00FF);
		SelectObject(PgfxCurrentDisplay.hdcc, hpen);
		rect.left = 0; rect.top = 0; rect.right = width; rect.bottom = height;
		FillRect(PgfxCurrentDisplay.hdcc, &rect, cast(HBRUSH)(COLOR_HIGHLIGHT+1));
		rect.left = 20; rect.top = 20; rect.right = width-20; rect.bottom = height-20;
		FillRect(PgfxCurrentDisplay.hdcc, &rect, cast(HBRUSH)(COLOR_BTNSHADOW+1));
		MoveToEx(PgfxCurrentDisplay.hdcc, 50,50, null);
		LineTo(PgfxCurrentDisplay.hdcc, width-50,height-50);
		Pie(PgfxCurrentDisplay.hdcc, 100,100, width-100,height-100, width-100,100, width-150,height-100);
		DeleteObject(hpen);
	}

	//SetLayeredWindowAttributes(hwnd, 0x00000000, 200, LWA_COLORKEY); //LWA_ALPHA|LWA_COLORKEY);
	//http://msdn.microsoft.com/library/default.asp?url=/library/en-us/winui/winui/windowsuserinterface/windowing/windows/windowreference/windowfunctions/setlayeredwindowattributes.asp

	// In case controls want to use Windows for text
	/// TODO: delete this later
	const static LOGFONT lf = {
		18, // lfHeight; 
		0, // LONG lfWidth; 
		0, // LONG lfEscapement; 
		0, // LONG lfOrientation; 
		FW_BOLD, // LONG lfWeight; 
		FALSE, // BYTE lfItalic; 
		FALSE, // BYTE lfUnderline; 
		FALSE, // BYTE lfStrikeOut; 
		ANSI_CHARSET, // BYTE lfCharSet; 
		OUT_RASTER_PRECIS, // BYTE lfOutPrecision; 
		CLIP_DEFAULT_PRECIS, // BYTE lfClipPrecision; 
		PROOF_QUALITY, // BYTE lfQuality; 
		VARIABLE_PITCH|FF_DONTCARE, // BYTE lfPitchAndFamily; 
		"Trebuchet MS\0", // TCHAR lfFaceName[LF_FACESIZE]; 
	};
	HFONT hf = CreateFontIndirectW(&lf);
	SelectObject(PgfxCurrentDisplay.hdcc, hf);
	SetBkMode(PgfxCurrentDisplay.hdcc, TRANSPARENT);

   /*#ifdef UseGuiPalette
	#error "Do not compile this yet"
    mov esi,[Display.Palette]
    sub esi,byte 4              ;point two words before, sig and length
    api CreatePalette, esi
    mov [hpal],eax              ;store logical palette handle
    api SelectPalette, [hdc],eax,FALSE
    api RealizePalette, [hdc]
    ;call TransferScreen (do later)
   #endif
   */

	return hwnd;
}


extern (C) int PlainDestroyWin(HWND hwnd)
{
	DeleteDC(PgfxCurrentDisplay.hdcc); PgfxCurrentDisplay.hdcc = null;
	DeleteObject(PgfxCurrentDisplay.hdib); PgfxCurrentDisplay.hdib = null;
    return DestroyWindow(hwnd);
}


extern (C) int PlainMainLoop(HWND hwnd)
{
	assert(hwnd != null);
	MSG msg;
	PlainVue root = cast(PlainVue)(cast(PlainVue*)GetWindowLongPtrW(hwnd, 0));

	while (msg.message != WM_QUIT) {
		if (PeekMessageW(&msg, null, 0,0, PM_REMOVE)) {
			if (msg.message == WM_DESTROY && cast(HWND)msg.wParam == hwnd)
				PostQuitMessage(0); // don't break immediately in case more msgs in thread
			else {
				TranslateMessage(&msg);
				DispatchMessageW(&msg);
			}
		}
		else if (PgfxCurrentFlags & (PgfxFlags.redraw|PgfxFlags.cursorMove|PgfxFlags.cursorSet)) {
			// TODO: move this into the container code.
			RedrawWindow(hwnd, null, null, RDW_INTERNALPAINT|RDW_NOERASE|RDW_NOCHILDREN);
			//InvalidateRect(hwnd, NULL, FALSE);
		}
		else {
			WaitMessage();
		}
	}

	return cast(int)msg.wParam;
}

private extern (Windows) LRESULT PlainWindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	// get root of current window
	// TODO: there CAN exist more than one root but in a different window, but haven't fixed this yet.
	PlainVue root = cast(PlainVue)(cast(PlainVue*)GetWindowLongPtrW(hwnd, 0));
	
	switch (uMsg) {
	case WM_CREATE:
		//SetWindowLongPtr(hwnd, 0, (LONG)((CREATESTRUCT*)lParam)->lpCreateParams); // keep track of root attached to window
		SetWindowLongW(hwnd, 0, cast(LONG)(cast(CREATESTRUCT*)lParam).lpCreateParams); // keep track of root attached to window
		break;

	case WM_PAINT:
		{
			// todo: Move all of this drawing code into the root itself.
			debug writefln("WM_PAINT");
			PAINTSTRUCT ps;

			//HDC hdc = GetDC(hwnd);
			PlainDraw(hwnd, root); // combine any drawing into this paint
			//InvalidateRgn(hwnd, NULL, FALSE);
			BeginPaint(hwnd, &ps);
			// api SetDIBitsToDevice, [PgfxDisplay.hdc],eax,eax, Screen.Width,Screen.Height,eax,eax, eax,Screen.Height, [PgfxDisplay.pixels],Display.BmpHeader,DIB_RGB_COLORS
			BitBlt(ps.hdc, 0,0, PgfxCurrentDisplay.width,PgfxCurrentDisplay.height, PgfxCurrentDisplay.hdcc, 0,0, SRCCOPY);
			/*UpdateLayeredWindow(hwnd,
				//HDC hdcDst,
				//POINT *pptDst,
				//SIZE *psize,
				//HDC hdcSrc,
				//POINT *pptSrc,
				//COLORREF crKey,
				//BLENDFUNCTION *pblend,
				//DWORD dwFlags
			);*/ //http://msdn.microsoft.com/library/default.asp?url=/library/en-us/winui/winui/windowsuserinterface/windowing/windows/windowreference/windowfunctions/updatelayeredwindow.asp
			EndPaint(hwnd, &ps);
		}
		break;

	case WM_NCACTIVATE:
		return TRUE;
	case WM_NCCALCSIZE:
	case WM_NCPAINT:
	case WM_WINDOWPOSCHANGING:
		return FALSE;

	case WM_WINDOWPOSCHANGED:
		{
			WINDOWPOS* lpwp = cast(WINDOWPOS*) lParam;
			PlainMsgMove.Flags moveFlags = PlainMsg.nop;
			if (!(lpwp.flags & SWP_NOSIZE)) {
				moveFlags |= moveFlags.sizeHeight | moveFlags.sizeWidth | PlainMsg.moved;
			}
			if (!(lpwp.flags & SWP_NOMOVE)) {
				moveFlags |= moveFlags.moveLeft | moveFlags.moveTop | PlainMsg.moved;
			}
			if (!(lpwp.flags & SWP_NOZORDER)) {
				moveFlags |= moveFlags.moveLayer | PlainMsg.moved;
			}
			if (moveFlags & PlainMsg.midMask)
				root.moved(moveFlags);
		}
		return false;

    case WM_CAPTURECHANGED:
		debug writefln("capture changed");
		if (cast(HWND)lParam != PlainMouse.hwnd) {
	case WM_CANCELMODE:
			ReleaseCapture();
			debug writefln("cancel mode");
			PlainMouse.hwnd = null;
			PlainMouse.buttons = 0;
			PgfxCurrentCursor.x = PgfxCurrentCursor.y = 16384;
			PgfxCurrentFlags |= PgfxFlags.cursorMove;
			//RedrawWindow(hwnd, NULL,NULL, RDW_INTERNALPAINT|RDW_NOERASE|RDW_NOCHILDREN);
		}
		return 0;

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
		return FALSE;
		//break;
    case WM_KILLFOCUS:
		//root->flags |= GuiObj.containerFocus;
		//PlainWindowProcSetFocus(root, GuiMsg.keyOut|KeyMsgFlags.windowInOut);
		return FALSE;
		//break;

	case WM_KEYDOWN:
	case WM_KEYUP:
	case WM_CHAR:
	case WM_DEADCHAR:
	case WM_SYSKEYDOWN:
	case WM_SYSKEYUP:
	case WM_SYSCHAR:
	case WM_SYSDEADCHAR:
		{
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
			//-debug(verbose) writefln("keymsg=%d", uMsg);
		
			if (uMsg & 2) { // is character
				//-debug(verbose) writefln("keymsg char=%d", uMsg);
				// only if not dead character and not control character
				if ((uMsg & 1) || wParam < 32) break; // unicode is accepted by all controls
				root.keyChar(PlainMsg.keyChar, wParam);
			}
			else { // else press/release
				//TranslateMessage(&msg);
				if (lParam & (1<<31)) { // key release (test transition state)
					//-debug(verbose) writefln("keymsg rls=%d", uMsg);
					if (wParam < PlainKeyboard.buttons.length)
						PlainKeyboard.buttons[wParam] &= ~1;
					root.keyRelease(PlainMsg.keyRelease, wParam);
				}
				else { // key press
					//-debug(verbose) writefln("keymsg press=%d", uMsg);
					PlainMsgKey.Flags keyFlags = PlainMsg.keyPress;
					if (lParam & (1<<30))
						keyFlags |= PlainMsgKey.Flags.repeat;
					if (wParam < PlainKeyboard.buttons.length)
						PlainKeyboard.buttons[wParam] = PlainKeyboard.buttons[wParam] ^ 2 | 1;
					root.keyPress(keyFlags, cast(int)wParam);
				}
			}
		}
		//if (uMsg == WM_XBUTTONDOWN) return true;
		break;

	case WM_MOUSEACTIVATE:
		MessageBeep(MB_OK);
		return MA_ACTIVATEANDEAT;

	case WM_ACTIVATE:
		MessageBeep(MB_ICONEXCLAMATION);
		return FALSE;

	case WM_LBUTTONDOWN:
	case WM_LBUTTONUP:
	case WM_LBUTTONDBLCLK:
	case WM_RBUTTONDOWN:
	case WM_RBUTTONUP:
	case WM_RBUTTONDBLCLK:
	case WM_MBUTTONDOWN:
	case WM_MBUTTONUP:
	case WM_MBUTTONDBLCLK:
	case WM_MOUSEMOVE:
	//case WM_XBUTTONDOWN:
	//case WM_MOUSEWHEEL:
	//case WM_MOUSEHWHEEL:
	/*#define WM_MOUSEHWHEEL                            0x020E
	#define SPI_GETWHEELSCROLLCHARS                   0x006C
	#define SPI_SETWHEELSCROLLCHARS                   0x006D
	#define DEFAULT_CHARS_TO_SCROLL_WITH_EMULATION    0x01
	// http://msdn.microsoft.com/library/default.asp?url=/library/en-us/dnwui/html/BestPracticesforSupportingMicrosoftMouseandKeyboardDevices.asp
	*/
	/// TODO: add mousewheel, attend to double clicks, 
	{
		static int HIWORD(int L)	{	return L >> 16;	}
		static int LOWORD(int L)	{	return cast(short)L;	}

		HWND mouseHwnd = PlainMouse.hwnd;
		PlainMsgMouse msg;
		msg.flags = 0;	// use as sentinel value for later
		msg.button = -1;
		int buttons = wParam & (MK_LBUTTON|MK_RBUTTON|MK_MBUTTON);// & PlainMouse.leftDown;
		int x = LOWORD(lParam), y = HIWORD(lParam);
		PlainMouse.x = x; PlainMouse.y = y;
		//-debug writefln("mouse move x,y=(%d,%d)", x,y);

		//RedrawWindow(hwnd, NULL, NULL, RDW_INTERNALPAINT|RDW_NOERASE|RDW_NOCHILDREN);
		//break;
		//PgfxFlags |= PgfxFlags_redraw|PgfxFlags_cursorMove;

		// if no buttons down
		if (!(buttons & (PlainMouse.leftDown|PlainMouse.middleDown|PlainMouse.rightDown))) {
			POINT pt;
			int pos = GetMessagePos();
			pt.x = LOWORD(pos);
			pt.y = HIWORD(pos);
			mouseHwnd = WindowFromPoint(pt);
		}

		// check for mouse enter/exit from main window
		// have to do much compensation for Window's stupidity
		// just to know when the cursor has moved in or out.
		if (mouseHwnd != PlainMouse.hwnd) {
			debug writefln("mouseHwnd != hwnd");
			if (mouseHwnd == hwnd) { // moved in
				PlainMouse.buttons = buttons;
				PgfxCurrentCursor.x = x;
				PgfxCurrentCursor.y = y;
				SetCapture(hwnd);
				//ConfineCursor.release()
				msg.flags = PlainMsg.mouseIn|PlainMsgMouse.Flags.mouseMoved|PlainMsgMouse.Flags.setItem|PlainMsgMouse.Flags.windowInOut;
			}
			else { // moved out
				PlainMouse.buttons = 0;
				PgfxCurrentCursor.x = PgfxCurrentCursor.y = 16384;
				msg.flags = PlainMsg.mouseOut|PlainMsgMouse.Flags.mouseMoved|PlainMsgMouse.Flags.windowInOut;
				ReleaseCapture();
			}
			PlainMouse.hwnd = mouseHwnd;
			PgfxCurrentFlags |= PgfxFlags.cursorMove;
		}
		// catch cursor movement
		else if (mouseHwnd == hwnd) {
			PlainMouse.xDif = PgfxCurrentCursor.x - x;
			if (PgfxCurrentCursor.x != x) {
				if (x < PlainMouse.left) {
					x = PlainMouse.left;
					msg.flags |= PlainMsgMouse.Flags.horizontalPush;
				}
				else if (x >= PlainMouse.right) {
					x = PlainMouse.right-1;
					msg.flags |= PlainMsgMouse.Flags.horizontalPush;
				}
				else {
					msg.flags |= PlainMsgMouse.Flags.mouseMoved;
				}
				PgfxCurrentCursor.x = x;
			}
			PlainMouse.yDif = PgfxCurrentCursor.y - y;
			if (PgfxCurrentCursor.y != y) {
				if (y < PlainMouse.top) {
					y = PlainMouse.top;
					msg.flags |= PlainMsgMouse.Flags.verticalPush;
				}
				else if (y >= PlainMouse.bottom) {
					y = PlainMouse.bottom-1;
					msg.flags |= PlainMsgMouse.Flags.verticalPush;
				}
				else {
					msg.flags |= PlainMsgMouse.Flags.mouseMoved;
				}
				PgfxCurrentCursor.y = y;
			}
			/*if (msg & PlainMsgMouse.Flags.horizontalPush|PlainMsgMouse.Flags.verticalPush) {
				SetCursorPos(y - HIWORD(lParam) + PlainThreadMsg.pt.y,
								x - LOWORD(lParam) + PlainThreadMsg.pt.x);
			}*/

			uint8 xor = (PlainMouse.down ^ buttons);
			if (xor) {
				PlainMouse.down     = buttons;
				debug writefln("down=%d", PlainMouse.down);
				PlainMouse.pressed  = xor & buttons;
				PlainMouse.released = xor & PlainMouse.pressed;
				if (PlainMouse.pressed) {
					int time = GetMessageTime();
					PlainMouse.pressTime = time - PlainMouse.lastPress;
					PlainMouse.lastPress = time;
					msg.mid = PlainMsg.mousePress;
					//SetFocus(hwnd);
					SetActiveWindow(hwnd);
				}
				else {
					msg.mid = PlainMsg.mouseRelease;
				}
			}
			else if (msg.flags & (PlainMsgMouse.Flags.mouseMoved|PlainMsgMouse.Flags.verticalPush|PlainMsgMouse.Flags.horizontalPush)) {
				msg.mid = PlainMsg.mouseMove;
				//-debug writefln("mouse moved");
				PgfxCurrentFlags |= PgfxFlags.cursorMove;
			}
		}
		// such a case should not happen, but...
		else {
			debug writefln(" mouse exception hovered=%X prev=%X main=%X x=%d y=%d", mouseHwnd, PlainMouse.hwnd, hwnd, PgfxCurrentCursor.x, PgfxCurrentCursor.y );
			break;
		}

		msg.x = x - root.left;
		msg.y = y - root.top;
		switch (uMsg) {
		case WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK:
			msg.button = 1; break;
		case WM_RBUTTONDOWN, WM_RBUTTONUP, WM_RBUTTONDBLCLK:
			msg.button = 2; break;
		case WM_MBUTTONDOWN, WM_MBUTTONUP, WM_MBUTTONDBLCLK:
			msg.button = 3; break;
		default: // ignore other errors
			break;
		}
		msg.down = buttons;
		msg.pressTime = PlainMouse.pressTime;
		// if any message was set in preceding code, send it now
		if (msg.mid != 0)
			root.send(msg.msg);

		break;
	}

	//case WM_APPCOMMAND:
	//	return DefWindowProcW(hwnd, uMsg, wParam, lParam);

    case WM_DESTROY:
		PostThreadMessageW(GetCurrentThreadId(), WM_DESTROY, cast(uint)hwnd, GetWindowLongPtrW(hwnd, 0));
		break;

	default:
		return DefWindowProcW(hwnd, uMsg, wParam, lParam);
	}
	return false;
}


extern (C) void PlainDraw(HWND hwnd, PlainVue root)
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
	//PgfxCursorHide();
	//debug writefln("PlainDraw entered");
	if (root.flags & PlainVue.Flags.redrawAny) {
		debug(verbose) writefln("PlainDraw drawing root");
		root.draw();
		InvalidateRect(hwnd, null, false);
		root.flags &= ~PlainVue.Flags.redrawAny;
	}
	//PgfxCursorShow();
	/*
	HPEN hpen = CreatePen(PS_SOLID, 20, 0xFF00FF);
	SelectObject(PgfxCurrentDisplay.hdcc, hpen);
	MoveToEx(PgfxCurrentDisplay.hdcc, 100,100, null);
	LineTo(PgfxCurrentDisplay.hdcc, 300,300);
	DeleteObject(hpen);
	MoveToEx(PgfxCurrentDisplay.hdcc, 50,50, null);
	//LineTo(PgfxCurrentDisplay.hdcc, 300,300);
	const static RECT rect = {150,150,200,200};
	//GetUpdateRect(hwnd, &rect, FALSE);
	//WriteMessage(T("Top left bottom right = %d,%d %d,%d %d\r\n"), ps.rcPaint.top, ps.rcPaint.left, ps.rcPaint.right, ps.rcPaint.bottom, GetTickCount());
	FillRect(PgfxCurrentDisplay.hdcc, &rect, cast(HBRUSH)(COLOR_DESKTOP+1));
	*/

	PgfxCurrentFlags &= ~(PgfxFlags.redraw|PgfxFlags.cursorSet|PgfxFlags.cursorMove);
}

