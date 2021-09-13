/**
\file	TransFrame.h
\author	Dwayne Robinson
\since	2005-07-06
\date	2005-07-06
\brief	Transparent frame to contain other controls but show background.
*/
////////////////////////////////////////////////////////////////////////////////

#define WIN32_LEAN_AND_MEAN
#define NO_STRICT
#define WINVER 0x0401
#define _WIN32_WINDOWS 0x0401
#define NOATOM
#define NOMETAFILE
#define NOSERVICE
#define NOSOUND
#define NOWH
#define NOCOMM
#define NOHELP
#define NOPROFILER
#define NOMCX
#define OEMRESOURCE
#include <windows.h>
//#include <commctrl.h>
//#include <shellapi.h>
#define transframe_c
#include "TransFrame.h"
//#include <imm.h>

// restore what WINNT.H for some reason deffed out
/*-
#ifdef RtlMoveMemory
 #undef RtlMoveMemory
 WINBASEAPI
 HANDLE
 WINAPI
 RtlMoveMemory (
   VOID UNALIGNED *Destination,
   CONST VOID UNALIGNED *Source,
   SIZE_T Length
   );    
#endif
*/

#define ProgMemBase (HINSTANCE)0x400000
/*-
#define GWL_OVERLAY 0
#define GWL_OWNER 0
#ifndef IDC_HAND  
#define IDC_HAND            32649
#endif
*/


////////////////////////////////////////////////////////////////////////////////

LRESULT __stdcall TransFrameProc(HWND hwnd, UINT message, long wParam, long lParam);

//-#pragma warning(disable:4311) // pointer truncation from 'ShapeViewStruct *' to 'LONG'
//-#pragma warning(disable:4312) // conversion from 'LONG' to 'ShapeViewStruct *' of greater size

#ifndef T
#ifdef UNICODE
  #define T(string) L##string
#else
  #define T(string) string
#endif
#endif

#ifdef MYDEBUG
 extern void debugwrite(char* Message, ...);
 extern void debugerror();
#else
 #define debugwrite //
 #define debugerror //
#endif


short TransFrameClassW[] = L"TransFrame";
char  TransFrameClassA[] = "TransFrame";

WNDCLASS wcTransFrame = {
	CS_OWNDC|CS_DBLCLKS, //style
	(WNDPROC)TransFrameProc, //lpfnWndProc
	0, //cbClsExtra
	DLGWINDOWEXTRA, //cbWndExtra=0;
	ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	NULL,//(HBRUSH)COLOR_WINDOW+1), //hbrBackground
	0, //lpszMenuName
	TransFrameClass //lpszClassName
};

/*-
// These can be global variables because at any given instant,
// there will only be one attribute list with focus, and only
// one attribute list will receive messages at a time. Now this
// could bode badly for multithread apps that sent messages from
// two different threads at the same time to different attribute
// lists. I'm assuming that will not happen for now :-/
static AttribList *al;			// !this variable must be set
static AttribListItem *ali;		//  before calling functions
static HWND self;				// this is set upon message entry
static unsigned int item;		// number of item either hovered or selected
static unsigned int flags;		// cache this variable because it is used so often
static unsigned int selected;	// currently selected item
static int traveled;			// distance traveled in a seek operation
*/

// shared vars
/*- GOLINK complains if not defined as static
HWND HoverHwnd;					// any control can use this global variable
RECT HoverRect;					// any control using this must set HoverHwnd
unsigned int HoverItem;
//signed int hoverwheel;		// wheel accumulator for fine grain mice
HDC hdc;
RECT rect;
HFONT GuiFont, GuiFontTitle;

HCURSOR CursorArrow;
HCURSOR CursorIbeam;
HCURSOR CursorHand;
*/

/*-
static LONG unicode;			// OS supports unicode
HWND HoverHwnd;					// any control can use this global variable
RECT HoverRect;					// any control using this must set HoverHwnd
unsigned int HoverItem;
//signed int hoverwheel;		// wheel accumulator for fine grain mice
static HDC hdc;
static RECT rect;
static HFONT GuiFont, GuiFontTitle;

HCURSOR CursorArrow;
HCURSOR CursorIbeam;
HCURSOR CursorHand;

static AttribList DefaultAl = {
	0,0,0,0
};
static HELPINFO HelpInfo = {
	sizeof(HELPINFO),
	HELPINFO_WINDOW,
	0, 0, 0,
	0, 0};
static SCROLLINFO ScrollInfo = {sizeof(SCROLLINFO), SIF_ALL,
	0, 100,
	10, 45,
	0};
static unsigned int ClipboardFormats[2]={CF_UNICODETEXT,CF_TEXT};
static struct {
	BITMAPINFOHEADER bih;
	unsigned int pal[2]; //RGBQUAD array
}
ItemBitmap = {sizeof(BITMAPINFOHEADER),7,-7, 1,1,BI_RGB, 28,96,96, 2,2};
const static unsigned int MenuPixels[7] = {128,192,224,240,224,192,128}; //triangle for menu item
const static unsigned int CheckedPixels[7] = {2,6,142,220,248,112,32}; //right arrow
const static unsigned int UncheckedPixels[7] = {198,238,124,56,124,238,198}; //right arrow

static int		// temporary vars filled in by GetItemMetrics
	ItemHeight, // pixels height of a single
	TextHeight, // text cell height
	IconHeight, // image list icon height (typically 16x16)
	IconWidth,	// icon width (typically same as height)
	ItemRows,	// number of visible item rows in attribute list
	IconY;
static unsigned int
	CaretX,
	CaretY;
*/

LRESULT __stdcall TransFrameProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	//debugwrite("al  msg=%X wParam=%X lparam=%X", message, wParam, lParam);

	switch (message) {
	case WM_CREATE:
	{
		HDC hdc=GetDC(hwnd);
		SetBkMode(hdc, TRANSPARENT);
		//SetTextAlign(hdc, TA_LEFT|TA_RTLREADING);
		//SetTextAlign(hdc, TA_LEFT);
		SelectObject(hdc, GetStockObject(NULL_PEN));
		//CursorArrow = LoadCursor(0,IDC_ARROW);
		return 0;
	}

	case WM_PAINT:
	{
		/*
		// get update regions
		hdc = GetDC(hwnd);
		GetUpdateRect(hwnd, &ur, FALSE);
		GetUpdateRgn(hwnd, urgn, FALSE);
		ValidateRect(hwnd, NULL);
		*/
		PAINTSTRUCT ps;
		POINT pt = {0,0};
		BeginPaint(hwnd, &ps);
		MapWindowPoints(hwnd, GetParent(hwnd), &pt, 1);
		SetWindowOrgEx(ps.hdc, pt.x,pt.y, NULL);
		SendMessage(GetParent(hwnd), WM_PRINT, (WPARAM)ps.hdc, PRF_CHECKVISIBLE|PRF_CLIENT|PRF_ERASEBKGND);
		SetWindowOrgEx(ps.hdc, 0,0, NULL);
		EndPaint(hwnd, &ps);
		return FALSE;
	}
	case WM_ERASEBKGND:
		return TRUE;

	case WM_COMMAND:
		return SendMessage(GetParent(hwnd), message, wParam, lParam);

	// todo ... relay other notifications here

	//case WM_VSCROLL:
	//case WM_HSCROLL:
	//{
	//	return 0;
	//}
	case WM_GETDLGCODE:
		return DLGC_BUTTON; //DLGC_STATIC;

	//case WM_MOVE:
	//case WM_SIZE:
	//	return 0;
	//case WM_WINDOWPOSCHANGED:
	//	if (!(((LPWINDOWPOS)lParam)->flags & SWP_NOSIZE))
	//		Resize();
	//	return 0;
	//case WM_WINDOWPOSCHANGING:
	//	return 0;
	//-case WM_SETCURSOR:
	//	if ((lParam & 0xFFFF) != HTCLIENT) goto DoDefWndProc;

	//case WM_DESTROY:
		// fall through

	default:
		return DefDlgProc(hwnd, message, wParam, lParam);
	}
}
