/**
\file	AtrbList.c
\author	Dwayne Robinson
\since	2003-06-10
\date	2005-05-22
\brief	Selectable list of attributes with common control functions.

*** special build for fractured ***

\par What it does:

	Each attribute in the list can be edited, disabled, or hidden independantly.
	So it has the functionality of standard dialog controls but does not
	require you to arrange them, keep track of them in code, and tab
	between them.

	The following simple behaviors are supported:

	- push buttons/hyperlinks - one click actions/commands
	- toggle buttons/checkboxes - two state values (true/false, yes/no, up/down)
	- menu buttons - clicking opens a multivalue menu of choices
	- text edit - single line text string
	- title bar - caption for single list or separator for multiple sections
	- separator - not a control, just some white space to separate attributes

\par Original Concept:

	The original concept for this control came from Spc2Midi, my SPC emulator.
	With that UI control, the focus was more on a list of numerical values with
	various ranges and step increments that could be easily edited and 
	manipulated. This version abandons the focus on numbers and adds more
	generic capabilities - a hybrid between property lists (like you find in
	Internet Properties's Advanced page) and XP Explorer's common tasks. It
	has almost all the necessary functionality of an HTML sidepage with no
	webpage overhead because there is no bloooaaated HTML library!

\par Differences:

	Unlike an ordinary list box.
	- memory is not allocated by the control, but pointed to by the caller
	- single selection only, no multiple

\par Sample appearance:

\verbatim
	Include: *Tenchi*;*.mpg;*.avi
	Exclude: *Universe*
	Size >= 1024
	Size <= 2048
	Date >= 1990-03-01
	Date <= 2003-03-01

	Case specific: yes
	Recurse containers: yes
	Search direction: up

	Find
	Reset form
	Clear list
	Queue
	Copy
\endverbatim

\par Attributes:
	- label	text description of text field or button
			must not be null
	- icon	appropriate picture for item
			may be null (no icon)
	- text	typed text or ptr to checkbox words (yes/no, true/false, up/down)
			may only be null if button
	- flags	miscellaneous attributes

\par Flag types:
	- type (button, toggle, edit)
	- disabled
	- hidden
	- separator
	- checked / button pushed
	- redraw
	- numbers only (for text prompt)
	- max length (for text prompt only)

\bug
	Does not currently like simultaneous, multithreaded messages
	
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
#define _CRT_SECURE_NO_DEPRECATE
#include <stdio.h> // need sprintf for floats :-/ since wsprintf does not work
#include <stdlib.h> // need atoi and atof
#include <windows.h>
#include <commctrl.h> // for listbox constants and the like
#include <shellapi.h>
#define ATTRIBLIST_CPP
#include "attriblist.h"
//#include <imm.h>

#define GWL_OVERLAY 0
#define GWL_OWNER 0
#ifndef IDC_HAND  
#define IDC_HAND            32649
#endif

////////////////////////////////////////////////////////////////////////////////
// define universal primitives

typedef unsigned int uint;

// Surprisingly, this essential primitive is sometimes undefined on Unix systems.
// Retardly, Visual Studio 2005 highlights the reserved name but only compiles
// correctly if the CLR is included. Bjarne Stroustrup advocates it in C++.
#if !defined(__cplusplus_cli)
# if defined(__GNUC__)
#  define nullptr __null
# elif defined(__cplusplus)
#  define nullptr 0
# else
#  define nullptr ((void*)0)
# endif
#endif

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

#define elif else if

#pragma warning(disable:4311) // pointer truncation from 'ShapeViewStruct *' to 'LONG'
#pragma warning(disable:4312) // conversion from 'LONG' to 'ShapeViewStruct *' of greater size

////////////////////////////////////////////////////////////////////////////////
// functions.

static __inline unsigned int alabs(signed int n);
static int TotalChoices(TCHAR* text);
static __inline unsigned int ReverseRGB (unsigned int rgb);

////////////////////////////////////////////////////////////////////////////////
// global/statics

enum { // misc private integral constants
	SelectById=1<<31,
	NumericBufferSize=32,
};

extern "C" WNDCLASSEX wcAttribList = {
	sizeof(WNDCLASSEX),
	CS_OWNDC|CS_DBLCLKS, //style
	(WNDPROC)&(AttribList::AttribListProc), //lpfnWndProc
	0, //cbClsExtra
	4, //DLGWINDOWEXTRA, //cbWndExtra=0;
	nullptr, //hInstance
	nullptr, //hIcon
	nullptr, //hCursor
	(HBRUSH)(COLOR_WINDOW + 1), //hbrBackground
	nullptr, //lpszMenuName
	AttribListClass, //lpszClassName
	nullptr // small icon
};

extern "C" WNDCLASSEX wcAttribOverlay = {
	sizeof(WNDCLASSEX),
	CS_NOCLOSE, //style
	(WNDPROC)&(AttribList::AttribOverlayProc), //lpfnWndProc
	0, //cbClsExtra
	4, //DLGWINDOWEXTRA, //cbWndExtra=0;
	nullptr, //hInstance
	nullptr, //hIcon
	nullptr, //hCursor
	NULL, //(HBRUSH) hbrBackground
	nullptr, //lpszMenuName
	AttribOverlayClass, //lpszClassName
	nullptr // small icon
};

// These can be global variables because at any given instant,
// there will only be one attribute list with focus, and only
// one attribute list will receive messages at a time.
// TODO: Fix this for multithreaded apps.
// could bode badly for multithread apps that sent messages from
// two different threads at the same time to different attribute
// lists. I'm assuming that will not happen.
//-static AttribList *al;			// !this variable must be set
//-static AttribListItem *ali;		//  before calling functions
//-static HWND self;				// this is set upon message entry
//-static uint item;		// number of item either hovered or selected
//-static uint selected;	// currently selected item

// shared vars
/* GOLINK complains if not defined as static
HWND HoverHwnd;					// any control can use this global variable
RECT HoverRect;					// any control using this must set HoverHwnd
uint me.hovered;
//signed int hoverwheel;		// wheel accumulator for fine grain mice
HDC hdc;
RECT rect;
HFONT GuiFont, GuiFontTitle;

HCURSOR CursorArrow;
HCURSOR CursorIbeam;
HCURSOR CursorHand;
HCURSOR CursorNumeric;
*/

#ifdef _UNICODE
const static LONG unicode = true;			// OS supports unicode
#else
static LONG unicode = false;			// OS dose not support unicode
// note this variable may be changed to true later
// if the test finds that the OS really does support
// it but the app was simply built ANSI mode.
#endif
HWND HoverHwnd;					// any control can use this global variable
RECT HoverRect;					// any control using this must set HoverHwnd
//signed int hoverwheel;		// wheel accumulator for fine grain mice
//static HDC hdc;
//static RECT rect;
static HFONT GuiFont, GuiFontTitle;

HCURSOR CursorArrow;
HCURSOR CursorIbeam;
HCURSOR CursorHand;
HCURSOR CursorNumeric;

/*static AttribList DefaultAl = {
	0,0,0,0
};
*/
static HELPINFO HelpInfo = {
	sizeof(HELPINFO),
	HELPINFO_WINDOW,
	0, 0, 0,
	0, 0};
static SCROLLINFO ScrollInfo = {sizeof(SCROLLINFO), SIF_ALL,
	0, 100,
	10, 45,
	0};
static uint ClipboardFormats[2]={CF_UNICODETEXT,CF_TEXT};
static struct {
	BITMAPINFOHEADER bih;
	uint pal[2]; //RGBQUAD array
}
ItemBitmap = {sizeof(BITMAPINFOHEADER),7,-7, 1,1,BI_RGB, 28,96,96, 2,2};
const static uint MenuPixels[7] = {128,192,224,240,224,192,128}; //triangle for menu item
const static uint CheckedPixels[7] = {2,6,142,220,248,112,32}; //right arrow
const static uint UncheckedPixels[7] = {198,238,124,56,124,238,198}; //right arrow


struct AttribListMetrics {
	// temporary vars filled in by GetItemMetrics, GetSelectedFlags, and others...
	int itemHeight; // pixel height of a single row
	int textHeight; // text cell height (either less or about same as item height)
	int iconHeight; // image list icon height (typically 16x16)
	int iconWidth;	// icon width (typically same as height)
	int visibleRows;	// number of visible item rows in attribute list
	RECT rect; // dimensions of window client
};
static uint
	CaretX,
	CaretY;

#define me (*this)

AttribList::AttribList(HWND hwnd_) :
	hwnd(hwnd_),
	total(0), //total attribute items (including disabled and separators)
	selected(0), //currently selected item
	hovered(0),
	top(0), //item at scroll top
	himl(nullptr), //handle to prefilled image list
	alis(nullptr) //array of attribute list items
{
}


LRESULT __stdcall AttribList::AttribListProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	if (message == WM_CREATE) {
		// If this window was created on NT or 9x via MSLU,
		// use the Unicode code. If created on NT but compiled
		// as ANSI build, check whether OS supports Unicode.
		#ifndef _UNICODE
		unicode = IsWindowUnicode(GetDesktopWindow());
		#endif

		HINSTANCE ProgMemBase = GetModuleHandle(nullptr);

		// initialize display context to have standard GUI font
		// transparent blitting, and NO silly pen!

		// create fonts if they do not exist yet
		HDC hdc=GetDC(hwnd);
		if (!GuiFont) {
			LOGFONT lf;
			SystemParametersInfo(SPI_GETICONTITLELOGFONT, sizeof(LOGFONT), &lf, 0);
			GuiFont = CreateFontIndirect(&lf);
		}
		SelectObject(hdc, GuiFont);
		if (!GuiFontTitle) {
			//TEXTMETRIC tm;
			NONCLIENTMETRICS ncm;
			ncm.cbSize = sizeof(NONCLIENTMETRICS);
			SystemParametersInfo(SPI_GETNONCLIENTMETRICS, 0, &ncm, 0);
			//GetTextMetrics(hdc, &tm);
			GetObject(GuiFont, sizeof(LOGFONT), &ncm.lfMessageFont);
			//debugwrite("al title=%d normal=%d", ncm.lfCaptionFont.lfHeight, tm.tmHeight);
			//ncm.lfCaptionFont.lfHeight = tm.tmHeight+1;
			//-debugwrite("al title=%d normal=%d", ncm.lfCaptionFont.lfHeight, ncm.lfMessageFont.lfHeight);
			ncm.lfCaptionFont.lfHeight = ncm.lfMessageFont.lfHeight;
			ncm.lfCaptionFont.lfWeight=FW_BOLD;
			GuiFontTitle = CreateFontIndirect(&ncm.lfCaptionFont);
		}

		// continue gfx init
		SetBkMode(hdc, TRANSPARENT);
		SelectObject(hdc, GetStockObject(NULL_PEN));
		//SetTextAlign(hdc, TA_LEFT|TA_RTLREADING);
		//SetTextAlign(hdc, TA_LEFT);

		if (!CursorArrow) CursorArrow = LoadCursor(0,IDC_ARROW);
		if (!CursorIbeam) CursorIbeam = LoadCursor(0,IDC_IBEAM);
		if (!CursorHand) CursorHand  = LoadCursor(0,(LPTSTR)IDC_HAND);
		if (!CursorNumeric) CursorNumeric = LoadCursor(0, (LPTSTR)IDC_SIZEWE);
		if (!CursorHand) // load from own module Windows version does not support it
			CursorHand = LoadCursor(ProgMemBase,(LPTSTR)IDC_HAND);

		// set Attribute List class instance pointer
		AttribList* al = new AttribList(hwnd);
		SetWindowLongPtr(hwnd, GWL_USERDATA, (LONG)al);

		// Store overlay hwnd separately since silly Windows does not allow
		// children windows to be owners. -_-
		// Also set hwnd in child overlay so it can find its poor parent
		// in the huge sea of unfriendly windows, since neither GetParent or
		// GetWindow(GW_OWNER) work correctly.
		RegisterClassEx(&wcAttribOverlay); // do again in case not done yet
		HWND hedit = CreateWindowEx(0, AttribOverlayClass,
				AttribOverlayClass, WS_POPUP|WS_CHILD, 0,0, 100,24, hwnd,NULL, ProgMemBase, al);
		SetWindowLong(hwnd,0,(long)hedit);
		SetWindowLong(hedit,0,(long)hwnd);

		return 0;

	} else {
		AttribList* al = (AttribList*)GetWindowLongPtr(hwnd, GWL_USERDATA);
		return al->AttribListSubproc(hwnd, message, wParam, lParam);
	}
}

LRESULT __stdcall AttribList::AttribListSubproc(HWND hwnd, UINT message, long wParam, long lParam)
{
	AttribListMetrics alm;
	uint item; // todo: delete

	//debugwrite("al  msg=%X wParam=%X lparam=%X", message, wParam, lParam);

	switch (message) {
	//case WM_CREATE: // handled in Proc(...)
	case WmGetItems: // fills attribute list with items
		return (LRESULT)me.alis;

	case LB_GETCOUNT:
		return me.total;

	case WmSetItems: // fills attribute list with items
		{
			if (!lParam) return LB_ERR;
			AttribListItem* alis = (AttribListItem*)lParam; // set pointer to new attribute list

			if (me.alis != nullptr) {
				for (unsigned int item = 0; item < me.total; item++) {
					uint flags = me.alis[item].flags;
					if (flags & FlagNumeric) {
						delete me.alis[item].text;
					}
				}
				delete me.alis; me.alis = nullptr;
			}

			// count actual items contained
			int item;
			for (item = 0; alis[item].flags != 0; item++);
			me.total = item;

			// allocate our own local copy (in case the one we were passed
			// dissappears because it was a local variable or in case it
			// points to a read only page).
			me.alis = new AttribListItem[me.total];
			for (item = 0; alis[item].flags != 0; item++) {
				me.alis[item] = alis[item];
				uint flags = alis[item].flags;

				if (flags & FlagMenu) {
					me.alis[item].high.i = TotalChoices( alis[item].text )-1;
				}
				elif (flags & FlagNumeric) {
					// allocate local strings for editing numbers
					TCHAR* text = new TCHAR[NumericBufferSize];
					if (flags & FlagDecimal)
						_snwprintf(text, NumericBufferSize, T("%g"), alis[item].value.f);
					else
						_snwprintf(text, NumericBufferSize, T("%i"), alis[item].value.i);
					me.alis[item].text = text;
				}
			}

			GetItemMetrics(alm); // set new top if necessary...
			item = Seek(me.total,-alm.visibleRows, FlagHidden);
			if ( (unsigned)(item) < me.top) me.top = item;
			SetScrollBars(alm);
			ResizeOverlay();
			if (GetSelectedFlags(nullptr)) SetCaretX(-1);
			HoverRect.bottom=0; // force mouse recalc upon next mouse move

			InvalidateRect(hwnd, NULL, FALSE);
		}
		return 0;

	case LVM_SETIMAGELIST:
		// called ListView_SetImageList
		{
			HIMAGELIST himl = (HIMAGELIST)lParam;
			me.himl = himl;
			//GetItemMetrics...
			//SetScrollBars...
		}
		return 0;

	case WM_PAINT:
	{
		uint
			clrct = GetSysColor(COLOR_CAPTIONTEXT), //caption text
			clrit = GetSysColor(COLOR_INACTIVECAPTIONTEXT), //inactive text
			clrab = GetSysColor(COLOR_HIGHLIGHT), //active background
			clrat = GetSysColor(COLOR_HIGHLIGHTTEXT), //active text
			clrsb = GetSysColor(COLOR_BTNFACE), //selected background
			clrst = GetSysColor(COLOR_BTNTEXT), //selected text
			clrub, //=GetSysColor(COLOR_WINDOW), //unselected background
			clrut = GetSysColor(COLOR_WINDOWTEXT), //unselected background
			clrdt = GetSysColor(COLOR_GRAYTEXT), //disabled text
			//clrsb=((clrab & 0xFEFEFE) + (clrub & 0xFEFEFE)) >> 1;
			clrb, //current color of background
			clrt; //and text
		uint focus=GetFocus()==hwnd,
			fullfocus;
		uint secondpass=0; //two pass counter
		int x; //text offsets
		HFONT hlf;
		SIZE sz;
		LPTSTR text;
		RECT ur; // update rect to redraw
		HRGN urgn = CreateRectRgn(0,0,0,0); //create stupid, dummy region
		LOGBRUSH lb;

		// choose background color
		if (GetWindowLong(hwnd, GWL_EXSTYLE) & WS_EX_CLIENTEDGE) {
			clrub=GetSysColor(COLOR_WINDOW);
		}
		else {
			clrub = GetClassLong(GetParent(hwnd), GCL_HBRBACKGROUND);
			if (clrub <= 255) {
				clrub = GetSysColor(clrub-1);
			}
			else {
				GetObject( (HGDIOBJ)clrub, sizeof(lb), &lb);
				clrub = lb.lbColor;
			}
			// Just in case the contrast between background color
			// and text is really low. The default Windows color
			// scheme has no problem, but some custom schemes
			// leave difficult to read text.
			if (alabs( ( clrut        & 255) - (clrub         & 255) ) +
				alabs( ((clrut >> 8 ) & 255) - ((clrub >> 8 ) & 255) ) +
				alabs( ((clrut >> 16) & 255) - ((clrub >> 16) & 255) )
				< 128) {
				clrut=GetSysColor(COLOR_WINDOW);
			}
		}

		// get update regions
		HDC hdc = GetDC(hwnd);
		GetUpdateRect(hwnd, &ur, FALSE);
		GetUpdateRgn(hwnd, urgn, FALSE);
		ValidateRect(hwnd, NULL);

		GetItemMetrics(alm);
		//if (TextHeight < alm.itemHeight)
		CaretY = (alm.itemHeight-alm.textHeight)>>1;
		int iconY  = (alm.itemHeight-alm.iconHeight)>>1;

		RECT itemRect; // four coordinates of currently drawn item

		// draw all items in two pass loop
		while (TRUE) {

			//set item rectangle
			itemRect.left=0;
			itemRect.top=0;
			itemRect.right=16384; //any ridiculously high number
			itemRect.bottom=alm.itemHeight;
			AttribListItem* ali;

			for (
				item=me.top, ali = &(me.alis[item]);
				item < me.total;
				item++, ali++
			 )
			{
				// if visible and needs redrawing
				uint flags = ali->flags;
				if (!(flags & FlagHidden)) {
					if (flags & FlagRedraw) {
						ali->flags &= ~FlagRedraw;
						fullfocus = ((item == me.selected) & focus);
						x=2;

						// set colors according to type and whether selected
						if (fullfocus)					clrb=clrab;
						else if (item == selected)		clrb=clrsb;
						else							clrb=clrub;
						SetBkColor(hdc, clrb);

						if (flags & FlagTitle)	clrt=(focus) ? clrct : clrit;
						else if (flags & FlagDisabled)	clrt=clrdt;
						else if (fullfocus)				clrt=clrat;
						else if (item == selected)		clrt=clrst;
						else							clrt=clrut;
						SetTextColor(hdc, clrt);

						// draw background
						ExtTextOut(hdc, 0,0, ETO_OPAQUE, &itemRect, NULL,0, NULL);

						// set font bold if title, and draw background
						if (flags & FlagTitle) {
							hlf=GuiFontTitle;
							SelectObject(hdc, GetSysColorBrush(focus ? COLOR_ACTIVECAPTION : COLOR_INACTIVECAPTION));
							RoundRect(hdc, 1,itemRect.top+1, itemRect.right,itemRect.bottom, 11,12);
						} else {
							hlf=GuiFont;
						}
						SelectObject(hdc, hlf);

						// draw icon at very left (usually 16x16)
						if (ali->icon) {
							ImageList_Draw(me.himl,ali->icon, hdc,2,itemRect.top+iconY, ILD_TRANSPARENT);
							x+=(alm.iconWidth+2);
						}

						// print label, regardless of type
						text = ali->label;
						if (text != nullptr) {
							int len=lstrlen(text);
							TextOut(hdc, x,itemRect.top+CaretY, text,len);
							//DrawState(hdc, NULL, NULL, "test",4, x,itemRect.top, 0,0, DST_TEXT|DSS_DISABLED);
							GetTextExtentPoint32(hdc, text, len, &sz);
							x += sz.cx;
							if (!(ali->flags & FlagNoColon) && ali->text != nullptr) {
								TextOut(hdc, x,itemRect.top+CaretY, T(": "),2);
								GetTextExtentPoint32(hdc, T(": "), 2, &sz);
								x += sz.cx;
							}
						}

						//if (flags & AlfHorzLine) {
						//	RECT thin = {0,itemRect.top, itemRect.right,itemRect.top+1};
						//	FillRect(hdc, &thin, (HBRUSH)(COLOR_WINDOWTEXT+1));
						//}

						// print text
						const uint* pixels = nullptr; //picture to display beside item
						text = GetChoiceText(item); // for check/group buttons
						if (text != nullptr) {							
							int len = lstrlen(text);
							TextOut(hdc, x,itemRect.top+CaretY, text,len);
							GetTextExtentPoint32(hdc, text, len, &sz);
							x += sz.cx;

							if (flags & FlagMenu) pixels = MenuPixels;
						}
						if (!pixels && (flags & FlagPushable) && (ali->high.i > 0))
							pixels = (ali->value.i > 0) ? CheckedPixels : UncheckedPixels;

						// display little graphic
						if (pixels && !(flags & FlagNoImage)) {
							if (!(flags & FlagPushable) || text==nullptr) {
								// Who is the retard that came up with this bass ackwards
								// BITMAP format? Every other gfx format in the world uses
								// sensible top down format.
								ItemBitmap.pal[0]=ReverseRGB(clrb);
								ItemBitmap.pal[1]=ReverseRGB(clrt);
								SetDIBitsToDevice(hdc, x+5, itemRect.top+((alm.itemHeight-7)>>1),
									8,7, 0,0, 0,7,
									pixels, (BITMAPINFO*)&ItemBitmap, DIB_RGB_COLORS);
								//err=GetLastError();
								//debugwrite("setdib=%d err=%d",ret,err);
								//CaretY = (alm.itemHeight-TextHeight)>>1;
							}
						}

					} else if (!secondpass) {
						//mark if item needs redrawing next pass
						//because it intersects the update region
						RECT ir; // dummy intersected rect
						if (IntersectRect(&ir, &ur, &itemRect))
							ali->flags |= FlagRedraw;
					} // if redraw flag

					// move current row down one
					itemRect.top    += alm.itemHeight;
					itemRect.bottom += alm.itemHeight;
				} // if hidden
			}
			if (secondpass) break;
			secondpass=TRUE;
			SelectClipRgn(hdc, urgn); //clip to update region
		} //end two passes

		itemRect.bottom = 4096;
		//FillRect(hdc, &itemRect, (HBRUSH)(COLOR_WINDOW+1));
		SetBkColor(hdc, clrub);
		ExtTextOut(hdc, 0,0, ETO_OPAQUE, &itemRect, nullptr,0, nullptr);
		SelectClipRgn(hdc, nullptr); //no clip region
		DeleteObject(urgn);

		return 0;
	}
	case WM_SETCURSOR:
		if ((lParam & 0xFFFF) != HTCLIENT) goto DoDefWndProc;
	case WM_ERASEBKGND:
		return TRUE;

	case WM_MOUSEMOVE:
		if (!GetCapture()) {
			int x = (int)(signed short)lParam;
			int y = (signed)lParam >> 16;
			if ((GetHoverRect(y) >= 0) && (x < HoverRect.right)) {
				int flags = me.alis[me.hovered].flags;
				if (flags & FlagNumeric) {
					SetCursor(CursorNumeric);
				}
				elif (flags & (FlagPushable|FlagMenu))  {
					SetCursor(CursorHand);
				}
				elif (flags & FlagEditable) {
					SetCursor(CursorIbeam);
				}
				else {
					SetCursor(CursorArrow);
				}
			} else {
				SetCursor(CursorArrow);
			}
		}
		return 0;

	case WM_LBUTTONDBLCLK:
	case WM_LBUTTONDOWN:
		{
			int x = (int)(signed short)lParam;
			int y = (signed)lParam >> 16;
			int focus=TRUE;

			// select choice and set caret or activate choice
			if (GetHoverRect(y) >= 0) {
				int flags = me.alis[me.hovered].flags;
				if (!(flags & (FlagDisabled|FlagHidden))) {

					if (flags & (FlagEditable|FlagNumeric)) {
						SetFocus(hwnd); focus=FALSE;
						// preset focus or else I have problems putting
						// the caret where it should not be.
						SelectGiven(me.hovered, (x < HoverRect.left) ? 2:0 );
						if (x >= HoverRect.left) {

							// 20030912 now works for Japanese fonts without needing to
							// set the character set to Japanese. Does NOT work with backwards
							// texts like Hebrew since MS makes it too stinking difficult.
							// Oh well, guess the Arabic people will just suffer left to right.

							static int caret[257];
							LPTSTR text = me.alis[me.selected].text;
							int len, idx,
								pos=0, // character position
								width=32767;

							HDC hdc=GetDC(hwnd);
							SelectObject(hdc, GuiFont);
							x -= HoverRect.left;

							if (unicode) {
								// NT only, does not work on 9x
								len=lstrlen(text)+1;
								if (len>256) len=256;
								SIZE sz;
								GetTextExtentExPoint(hdc, text,len, 0,nullptr, &caret[1],&sz);
								caret[0]=0;
								for (idx=0; idx<len; idx++) {
									int dif = x-caret[idx]; //get pixel difference
									//debugwrite("i%03d c%03d d%d p%d", idx, caret[idx], dif, pos);
									if (dif<0) dif = -dif;
									if (dif < width) {
										width = dif;
										pos = idx;
									}
								}
							} else {
								// 9x only, does not sum right on NT
								// determine nearest midcharacter position clicked
								uint charval;
								while (charval = text[pos]) {
									GetCharWidth(hdc, charval,charval, &width);
									//debugwrite("char char=%d width=%d", charval, width);
									if (width >= x) break;
									x -= width;
									pos++;
								}
								if (x > width>>1) pos++;
							}
							SetCaretX(pos);
						}
					}
					elif (flags & FlagMenu) {
						SelectGiven(me.hovered,0);
						//if (x >= HoverRect.left && x < HoverRect.right)
						if (x < HoverRect.right)
							ShowSelectedChoiceMenu();
					}
					elif (flags & FlagPushable) {
						if (x > HoverRect.right)
							SelectGiven(me.hovered,0);
						else if (me.alis[me.hovered].high.i > 0) { // toggle button
							SelectGiven(me.hovered,0);
							SetSelectedButtonValue(1, 2);
						}
						else { // push button
							focus=FALSE; // do not set focus is clicked on button
							SendClickCommand(me.hovered);
						}
					}
					else {
						SelectGiven(me.hovered,0);
					}
				}
			}
			if (focus) SetFocus(hwnd); // set focus if clicked on disabled, title, separator
		}
		return 0;

	case WM_MOUSEACTIVATE:
		return MA_NOACTIVATE;
		//SetFocus(hwnd);
	case WM_RBUTTONUP:
		return TRUE;
	case WM_RBUTTONDOWN:
		SelectGiven(GetHoverRect(lParam >> 16), 2);
		debugwrite("gethoverrect=%d item=%d",GetHoverRect(lParam >> 16),item);
		ShowContextMenu(me.hovered, lParam & 0xFFFF, lParam >> 16);
		return 0;

	case WM_CONTEXTMENU:
		{
			if (!GetSelectedFlags(nullptr)) return 0; //safety just in case
			RECT rect;
			GetItemRect(me.selected, 0, &rect); //show menu just below selected row
			ShowContextMenu(me.selected, rect.left,rect.bottom);
		}
		return 0;
	/*case WM_MENUSELECT: // relay help messages to parent
	{
		// should ignore if group popup menu
		HELPINFO hi = {sizeof(HELPINFO),
		   HELPINFO_MENUITEM,
		   wParam & 0xFFFF,
		   (HANDLE)lParam,
		   (long)hwnd,
		   0, 0};
		SendMessage(GetParent(hwnd), WM_HELP, 0, (LPARAM)&hi);
		return 0;
	}*/

	case WM_COMMAND:
		debugwrite("al cmd=%08X hwnd=%08X", wParam,lParam);
		if ((wParam & 0xFFFF) <= 255) { // choice menu sent message
			uint flags;
			if (GetSelectedFlags(&flags) && !(flags & (FlagDisabled|FlagHidden)) && (flags & FlagMenu)) {
				wParam &= 255;
				if ((unsigned)wParam < (unsigned)TotalChoices(me.alis[me.selected].text))
					SetSelectedButtonValue(wParam, 0);
			}
		}
		elif ((wParam & 0xFFFF) >= IDAL_MAX) { // special parent msg
			debugwrite("al cmd custom");
			return SendMessage(GetParent(hwnd),WM_COMMAND, wParam,lParam);
		}
		else { // context menu sent message
			uint flags;

			switch (wParam & 0xFFFF) {
			case IDAL_COPY: goto CopyText;
			case IDAL_PASTE: goto PasteText;
			case IDAL_CLEAR: goto ClearText;
			case IDAL_COPYALL: goto CopyAllText;
			case IDAL_TOGGLE: 
				if (GetSelectedFlags(&flags) && !(flags & (FlagDisabled|FlagHidden)) && (flags & FlagPushable))
					SetSelectedButtonValue(1, 2);
				return 0;
			case IDAL_COMMAND:
				if (GetSelectedFlags(&flags) && !(flags & (FlagDisabled|FlagHidden)) && (flags & FlagPushable))
					SendClickCommand(me.selected);
				return 0;
			case IDAL_HELP:
				/*
				// todo:
				lParam = (long)&HelpInfo; //set helpinfo ptr
				HelpInfo.hItemHandle = hwnd; //set source to self
				HelpInfo.iCtrlId = GetDlgCtrlID(hwnd);
				HelpInfo.iContextType = HELPINFO_WINDOW;
				item = me.selected;
				goto SendHelpToParent;
				*/
				;
			}
		}
		return 0;

	case WM_COPY:
		if (wParam==-1) goto CopyAllText; // special case message to copy all
	CopyText:
		if (!GetSelectedFlags(nullptr)) return -1; // just in case no choices
		if (OpenClipboard(hwnd)) {
			HGLOBAL hmt = nullptr;
			LPTSTR src, dest;

			EmptyClipboard();
			if (hmt = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE, 256*sizeof(TCHAR)) ) {
				src = GetChoiceText(me.selected);
				if (!src) dest = me.alis[me.selected].label;
				if (src) { // if item actually has text
					dest = (LPTSTR)GlobalLock(hmt);
					RtlMoveMemory(dest, src, 256 * sizeof(TCHAR));
					//MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, (LPSTR)text,-1, dest, 256);
					//WideCharToMultiByte(CP_ACP, 0, text,-1, (LPSTR)dest, 256, nullptr,nullptr);
					GlobalUnlock(hmt);
					#ifdef _UNICODE
						SetClipboardData(CF_UNICODETEXT,hmt);
					#else
						SetClipboardData(CF_TEXT,hmt);
					#endif
				} else {
					GlobalFree(hmt);
				}
			}
			CloseClipboard();
		}
		return 0;
	CopyAllText:
		if (OpenClipboard(hwnd)) {
			HGLOBAL hmt = nullptr;
			//int item=me.total;

			EmptyClipboard();
			if (hmt = GlobalLock(GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE,4096)) ) { // if mem alloced
				// build text chunk by iteraing through all items
				// and appending each line's text

				*(TCHAR*)hmt = '\0'; // start with empty string

				for (unsigned int item=0; item < me.total; item++) {
					AttribListItem& ali = me.alis[item];
					uint flags = ali.flags;

					if (flags & (FlagDisabled|FlagHidden)) continue;
					TCHAR* text = GetChoiceText(item);
					if (ali.label == nullptr) continue;

					AppendString(&hmt, ali.label);
					AppendString(&hmt, GetChoiceText(item));
					AppendString(&hmt, T("\r\n"));
				}
				// build ANSI version of text chunk
				hmt = GlobalHandle(hmt);
				GlobalUnlock( hmt );
				#ifdef _UNICODE
					SetClipboardData(CF_UNICODETEXT,hmt);
				#else
					SetClipboardData(CF_TEXT,hmt);
				#endif
				debugwrite("setcp=%X err=%d",hmt,GetLastError());
			}
			CloseClipboard();				
		}
		return 0;

	case WM_PASTE:
	PasteText:
		{
			uint flags;
			if (!GetSelectedFlags(&flags)) return -1; // just in case no choices
			/* todo:
			if ((flags & (TypeMask|FlagDisabled|FlagHidden))==TypeEdit // ensure IS edit, not disabled, hidden, or locked
			&& (flags & FlagSizeMask) // ensure edit allows at least one character in buffer
			&& OpenClipboard(hwnd)) {
				HGLOBAL hmt; //memory handle to text
				LPTSTR src, dest;
				uint len; //string length
				uint format=GetPriorityClipboardFormat(&ClipboardFormats[0],2);

				#ifdef MYDEBUG
				format=0;
				do {
					format=EnumClipboardFormats(format);
					debugwrite("cf=%d %Xh",format,format);
				} while (format);
				format=GetPriorityClipboardFormat(&ClipboardFormats[0],2);
				#endif
				
				debugwrite("paste format=%d",format);
				if ((dest = me.alis[me.selected].text)
				&& (hmt = GetClipboardData(format))
				&& (src = (LPTSTR)GlobalLock(hmt)) )
				{
					//if (format==CF_UNICODETEXT) {
					debugwrite("paste text=%s", src);
					len = lstrlen(src);
					if (len > (flags>>FlagSizeRs)) len = flags>>FlagSizeRs;
					*(dest+len) = '\0'; // append null
					debugwrite("paste len=%d",len);
					RtlMoveMemory(dest, src, len*sizeof(TCHAR)); //*2 for Unicode					
					GlobalUnlock(hmt);
					ResizeOverlay();
					SetCaretX(-1);
				};
				CloseClipboard();				
			}
			*/
		}
		return 0;

	case WM_CLEAR:
	ClearText:
		{
			uint flags;
			if (!GetSelectedFlags(&flags)) return -1; // just in case no choices
			/*
			if ((flags & (TypeMask|FlagDisabled|FlagHidden))==TypeEdit
			&& (flags & FlagSizeMask))
			{
				LPTSTR text;
				if (text = me.alis[me.selected].text) {
					*text = '\0'; // truncate string to zero length
					ResizeOverlay();
					SetCaretX(0);
				}
			}
			*/
		}
		return 0;

	case WM_MOUSEWHEEL:
		debugwrite("mouse wheel w=%X l=%X", wParam, lParam);
		ScrollBy((wParam & 0x80000000) ? 1 : -1, 0);
		return TRUE;

	case WM_VSCROLL:
	{
		int dif, options=0;
		switch (wParam & 0xFFFF) {
		case SB_LINEUP: dif = -1; break;
		case SB_LINEDOWN: dif = 1; break;
		case SB_PAGEUP: dif = -1;  options = 1; break;
		case SB_PAGEDOWN: dif = 1; options = 1; break;
		case SB_THUMBTRACK: dif=(unsigned long)wParam >> 16; options=4; break;
		//case SB_TOP:
		//case SB_BOTTOM:
		default:
			return 0;
		}
		ScrollBy(dif, options);
		return 0;
	}

	case WM_GETDLGCODE:
		{
			uint flags;
			// if push button (not a toggle)
			// then want every key, including Enter
			if (GetSelectedFlags(&flags)
			&& (flags & FlagPushable)
			&& (me.alis[me.selected].high.i == 0))
			{
				return DLGC_WANTCHARS|DLGC_WANTARROWS|DLGC_WANTALLKEYS;
			}
		}
		// else only arrows and chars matter
		return DLGC_WANTARROWS|DLGC_WANTCHARS;

	case WM_KEYDOWN:
		// generic keys for all types
		switch (wParam) {
		//case VK_APPS: (should not be necessary because of WM_CONTEXTMENU msg)
		//	goto ShowMenuViaKey;
		case VK_DOWN:
		case VK_UP:
			Select(Seek(me.selected, (wParam == VK_DOWN) ? 1:-1, FlagHidden|FlagDisabled));
			break;
		case VK_NEXT:
		case VK_PRIOR:
			ScrollBy((wParam == VK_NEXT) ? 1:-1, 1);
			break;

		case VK_INSERT:
			if (GetKeyState(VK_CONTROL)&0x80)
				goto CopyText; // Ctrl+Ins to copy

		case VK_TAB:
			SendMessage(GetParent(hwnd), WM_NEXTDLGCTL, GetKeyState(VK_SHIFT)&0x80, 0);
			break;

		// specific keys for individual types
		default:
			{
				uint flags;

				// a disabled item or separator should never be selected, but just in case
				// some program code has changed things behind this code's back
				if (!GetSelectedFlags(&flags) || (flags & (FlagDisabled|FlagHidden))) return 0;

				if (flags & (FlagEditable|FlagNumeric)) {
					//if (flags & FlagLocked) break; // catch, don't edit the uneditable

					switch (wParam) {
					case VK_LEFT:
						if (CaretX > 0) SetCaretX(CaretX-1);
						break;
					case VK_RIGHT:
						SetCaretX(CaretX+1);
						break;
					case VK_HOME: 
						SetCaretX(0);
						break;
					case VK_END:
						SetCaretX(-1);
						break;
					case VK_BACK:
						if (CaretX > 0) {
							SetCaretX(CaretX-1);
					case VK_DELETE:
							DeleteChar();
						}
						{
							AttribListItem& ali = me.alis[me.selected];
							if (flags & FlagDecimal) {
									ali.value.f = (float)_wtof(ali.text);
							} else {
								ali.value.i = _wtoi(ali.text);
							}
						}
						break;
					case VK_INSERT:
						if (GetKeyState(VK_SHIFT)&0x80) goto PasteText; // Shift+Ins to paste
						break;
					case VK_RETURN:
						ActivateNearestButton();
						break;
					}
				}
				//elif (flags & FlagNumeric) {
				//
				//}
				elif (flags & FlagPushable) {
					if (lParam & (1<<30)) break; // catch, ignore repeated keypresses

					switch (wParam) {
					case VK_LEFT:
						SetSelectedButtonValue(-1, 1);
						break;
					case VK_RIGHT:
						SetSelectedButtonValue(1, 1);
						break;
					case VK_SPACE:
					case VK_RETURN:
						if (me.alis[me.selected].high.i == 0) // if push button, not toggleable
							SendClickCommand(me.selected);
						elif (wParam != VK_RETURN) // toggle check state
							SetSelectedButtonValue(1, 2);
						else
							ActivateNearestButton();
					}
				}
				elif (flags & FlagMenu) {
					//if (lParam & (1<<30)) break; // catch, ignore repeated keypresses
					AttribListItem& ali = me.alis[me.selected];

					switch (wParam) {
					case VK_SPACE:
					//case VK_RETURN:
					{
						MSG msg; // solely to remove the extra space character that makes the ding
						PeekMessage(&msg, 0,WM_KEYFIRST,WM_KEYLAST,PM_REMOVE);
						ShowSelectedChoiceMenu();
						break;
					}
					case VK_END: // set to last, right-most choice
						SetSelectedButtonValue(TotalChoices(ali.text)-1, 0);
						break;
					case VK_HOME: // set to first, left-most choice
						SetSelectedButtonValue(0, 0);
						break;
					case VK_RIGHT:
						{
							int value = ali.value.i+1;
							if (value < TotalChoices(ali.text))
								SetSelectedButtonValue(value, 0);
							break;
						}
					case VK_LEFT:
						SetSelectedButtonValue(-1, 1);
						break;
					}
				}
			}
		}
		return 0;
	case WM_CHAR:
		//  if text edit and flags allow
		//	  if valid character
		//	    if room in prompt
		//        insert char
		//    elif backspace
		//      if caret not at leftmost column
		//        move caret one column back
		//        delete character
		//      endif
		//    endif
		//  endif
		{
			uint flags;
			if (GetSelectedFlags(&flags) && !(flags & (FlagDisabled|FlagHidden))) {
				if (flags & FlagEditable) {
					if (wParam >= ' ') {
						if (!(flags & FlagNumeric) || ((wParam >= '0' && wParam <= '9') || wParam == '.'))
							InsertChar(wParam, (unsigned)me.alis[me.selected].high.i);
					}
				}
				if (flags & FlagNumeric) {
					AttribListItem& ali = me.alis[me.selected];
					bool valid = false;
					if (wParam >= '0' && wParam <= '9') valid = true;
					elif (wParam == '.') /* and no other period */ valid = true;
					elif (wParam == '-' && CaretX == 0 && ali.text != nullptr && ali.text[0] != '-') valid=true;
					if (valid) {
						InsertChar(wParam, NumericBufferSize);
						if (flags & FlagDecimal) {
							ali.value.f = (float)_wtof(ali.text);
						} else {
							ali.value.i = _wtoi(ali.text);
						}
					}
				}
			}
		}
		return 0;

	case WM_KILLFOCUS:
	case WM_SETFOCUS:
		//debugwrite("al gf=%X self=%X msg=%d", GetFocus(),self,message);
		{
			ResizeOverlay();
			uint flags;
			if (GetSelectedFlags(&flags)) {
				me.alis[me.selected].flags |= FlagRedraw;
				if (message==WM_SETFOCUS) SetCaretX(-1);
			}
			RedrawTitles();
			PostRedraw();
		}
		return 0;

	case LB_SETCURSEL:
		return Select(wParam ^ SelectById);

	//case BM_SETSEL:
	case LB_SETSEL:
		// SetSelectedButtonValue(wParam);
		lParam = IdToItem(lParam ^ SelectById);
		if (lParam == LB_ERR)
			return LB_ERR;

		if (me.alis[lParam].high.i > 0) {
			me.alis[lParam].value.i = (wParam) ? 1 : 0;
			me.alis[lParam].flags |= FlagRedraw;
			PostRedraw(); //redraw toggle or menu item
			HoverRect.bottom=0; // force mouse recalc upon next mouse move
			ResizeOverlay();
		}
		return 0;

	case LB_GETSEL:
		wParam = IdToItem(wParam ^ SelectById);
		if (wParam == LB_ERR)
			return LB_ERR;
		return me.alis[wParam].value.i;

	case WM_SETREDRAW: // manually refresh a changed item
		if (!lParam)
			return DefWindowProc(hwnd, message, wParam, lParam);

		lParam = IdToItem(lParam ^ SelectById);
		if (lParam == LB_ERR)
			return LB_ERR;

		me.alis[lParam].flags |= FlagRedraw;
		PostRedraw(); //redraw toggle or menu item
		HoverRect.bottom=0; // force mouse recalc upon next mouse move
		//ResizeOverlay();
		return 0;

	case BM_CLICK:
		//if (!GetGivenFlags(lParam) || (flags & (FlagDisabled|FlagHidden))) return 0;
		{
			uint flags;
			if (!GetSelectedFlags(&flags) || (flags & (FlagDisabled|FlagHidden))) return 0;

			if (flags & FlagPushable) {
				// either push button or toggle
				if (me.alis[me.selected].high.i == 0)
					SendClickCommand(me.selected);
				else
					SetSelectedButtonValue(1,1);
			}
			elif (flags & FlagMenu) {
				if (lParam)
					ShowGivenChoiceMenu(me.selected,
						(int)(signed short)lParam,
						(signed)lParam >> 16);
				else
					ShowSelectedChoiceMenu();  // todo: get rid of break's
			}
		}
		return 0;
	case WM_MOVE:
		ResizeOverlay();
		return 0;
	case WM_WINDOWPOSCHANGED:
		if (!(((LPWINDOWPOS)lParam)->flags & SWP_NOSIZE))
	case WM_SIZE:
			Resize();
		return 0;
	case WM_WINDOWPOSCHANGING:
		// redraw titles if sized horizontally
		{
			RECT rect;
			GetWindowRect(hwnd, &rect);
			if (((WINDOWPOS*)lParam)->cx != (rect.right-rect.left)) {
				RedrawTitles();
				PostRedraw();
			}
		}
		return 0;

	/*
	case WM_HELP:
		//((LPHELPINFO)lParam)->iContextType = HELPINFO_WINDOW;
		//((LPHELPINFO)lParam)->hItemHandle, //already correct
		//((LPHELPINFO)lParam)->MousePos.x,
		//((LPHELPINFO)lParam)->MousePos.y);

		// calculate hovered item
		// if valid item
		//me.top

		if (GetKeyState(VK_F1) & 0x80) {
			item = me.selected;
		} else {
			rect.top  = ((LPHELPINFO)lParam)->MousePos.y;
			rect.left = ((LPHELPINFO)lParam)->MousePos.x;
			ScreenToClient(hwnd, (POINT*)&rect);
			//debugwrite("alhelp x=%d y=%d", rect.left,rect.top);
			//rect.top  = ((LPHELPINFO)lParam)->MousePos.y - rect.top;
			//rect.left = ((LPHELPINFO)lParam)->MousePos.x - rect.left;
			item = -1;
		}
	SendHelpToParent: //(item, rect)
		// !assumes the helpinfo is valid and partially filled in
		// expects item is set valid or is -1
		if (GetItemRect(item, rect.top) >= 0
		&& (flags & AlfIdMask)) {  // must have an ID
			// ensure tooltip is not way outside control
			if (!IsWindowVisible((HWND)GetWindowLong(hwnd,GWL_OVERLAY))
			|| item != me.selected) {
				RECT crect;
				GetClientRect(hwnd,&crect);
				if (rect.right > crect.right) rect.right=crect.right;
			}				
			((LPHELPINFO)lParam)->hItemHandle = hwnd;
			((LPHELPINFO)lParam)->iCtrlId = flags & AlfIdMask;
			((LPHELPINFO)lParam)->iContextType = HELPINFO_WINDOW+4;
			((LPHELPINFO)lParam)->MousePos.y = rect.top;
			((LPHELPINFO)lParam)->MousePos.x = rect.right+2;
		}
		SendMessage(GetParent(hwnd), WM_HELP, wParam, lParam);
		return TRUE;
	*/

	case WM_DESTROY:
		DestroyWindow( (HWND)GetWindowLong(hwnd,GWL_OVERLAY) );
		// fall through

DoDefWndProc:
	default:
		return DefWindowProc(hwnd, message, wParam, lParam);
	}
}

// This is the little text window shown whenever an editable item is
// selected in the attribute list. This code only does the very basic
// tasks necessary, such as repainting itself. Most of it is controlled
// by its parent, including key control, character editing, what text
// should be shown, and where the window is displayed.
LRESULT __stdcall AttribList::AttribOverlayProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	switch (message) {
	case WM_CREATE:
		//CurIbeam=LoadCursor(0,IDC_IBEAM);
		SetClassLong(hwnd, GCL_HCURSOR, (long)CursorIbeam);
		SetWindowLongPtr(hwnd, GWL_USERDATA, (long)nullptr);
		return 0;
	/*case WM_SETTEXT:
		if (!lParam) lParam=(long)&DefaultAl;
		SetWindowLong(hwnd, GWL_USERDATA, lParam);
		return TRUE; //return always success*/
	case WM_SETCURSOR:
	case WM_ERASEBKGND:
		return TRUE;
	case WM_PAINT:
	{
		LPTSTR text = (LPTSTR)GetWindowLongPtr(hwnd, GWL_USERDATA);
		PAINTSTRUCT ps;
		RECT rect;

		BeginPaint(hwnd, &ps);
		//ValidateRect(hwnd, nullptr);
		SelectObject(ps.hdc, GuiFont);
		SetBkColor(ps.hdc, GetSysColor(COLOR_HIGHLIGHT)); //COLOR_BTNFACE
		SetTextColor(ps.hdc, GetSysColor(COLOR_HIGHLIGHTTEXT));
		GetClientRect(hwnd, &rect);
		ExtTextOut(ps.hdc, 0,CaretY, ETO_OPAQUE, &rect, text,lstrlen(text), nullptr);
		EndPaint(hwnd, &ps);
		return 0;
	}
	case WM_LBUTTONDOWN: // for caret positioning
	case WM_RBUTTONDOWN: // for context menu
	case WM_MBUTTONDOWN: // just in case for future compat
	case WM_MOUSEMOVE:
	{
		// relay all mouse messages to owner
		HWND owner=(HWND)GetWindowLong(hwnd,GWL_OWNER);
		if (!owner) return -1;
		lParam=GetMessagePos();
		RECT rect;
		rect.left=(int)(signed short)lParam;
		rect.top =(signed)lParam>>16;
		ScreenToClient(owner, (LPPOINT)&rect);
		lParam = (rect.left & 0xFFFF) | (rect.top<<16);
		return AttribListProc(owner, message,wParam,lParam);
	}
	case WM_NCLBUTTONDOWN:
	case WM_NCMBUTTONDOWN:
	case WM_NCRBUTTONDOWN:
	case WM_ACTIVATE: // ignore any possible activation
	case WM_WINDOWPOSCHANGING:
	case WM_WINDOWPOSCHANGED:
		return 0;
	case WM_MOUSEACTIVATE:
		return MA_NOACTIVATE;
	case WM_HELP: // relay help msg to parent
		return AttribListProc((HWND)GetWindowLong(hwnd,GWL_OWNER), message,wParam,lParam);
	default:
		return DefWindowProc(hwnd, message, wParam, lParam);
	}
}


// purpose:
//		Seeks up/down from an item index by the given distance (+/-),
//		ignoring all hidden items in the list.
//
//		from - index of item in list to start from
//		distance - amount to go up/down
//		flagmask - items to skip and behavior flags
//
//		Default flagmask is (FlagHidden|FlagSeparator|FlagDisabled)
//		Bit 1 set is a special flag meaning to return -1 if not reached
// !assumes:
//		al points to the current attribute list
// returns:
//		new item number
//		[item]
int __stdcall AttribList::Seek(uint from, int distance, int flagmask)
{
	uint total=me.total;
	if (from > total) from=total;
	uint skipflags=flagmask & ~FlagIdMask;
	AttribListItem* ali = &(me.alis[from]);
	uint item=from;
	int traveled=distance; // rows traveled in seek operation

	if (traveled > 0)
		while (++from < total)
		{
			ali++;
			if (!(ali->flags & FlagHidden)) {
				traveled--;
				if (!(ali->flags & skipflags)) {
					item=from;
					if (traveled <= 0) break;
				}
			}
		}
	else if (traveled < 0)
		while ((signed)--from >= 0)
		{
			ali--;
			if (!(ali->flags & FlagHidden)) {
				traveled++;
				if (!(ali->flags & skipflags)) {
					item=from;
					if (traveled >= 0) break;
				}
			}
		}

	// if distance requested could not be reached, return -1
	traveled=distance-traveled;
	if ((traveled != distance) && (flagmask & 1)) 
		item = LB_ERR; //-1
	else
		if (item >= total) item=0; //safety

	//*ptraveled = traveled;
	return item;
}

// purpose:
//		Determines an item's screen row, relative to top of list,
//		ignoring all hidden items. Can return either positive or
//		negative row offsets from top. Can also be used to tell
//		the row difference between two items.
//
//		item - item to get row position of (must be 0 to total-1)
//		top - top item that all rows are relative to
//			  pass top if for relative to top of list
//
// !assumes:
//		al points to the current attribute list
// returns:
//		zero based position (in rows, not pixels)
int __stdcall AttribList::GetItemRow(uint item, uint top) {
	uint total=me.total;
	if (item > total) item=total;
	if (top > total) top=total;
	AttribListItem* ali = &(me.alis[item]);
	int traveled=0;

	if (item >= top)
		while ((signed)--item >= 0 && item >= top) {
			ali--;
			if (!(ali->flags & FlagHidden)) traveled++;
		}
	else
		while ((signed)item++ < (signed)top) {
			if (!(ali->flags & FlagHidden)) traveled--;
			ali++;
		}

	return traveled;
}

//debugwrite("i=%d f=%d d=%d t=%d", item, from, distance, traveled);
//debugwrite("i=%d t=%d", item, traveled);
//SetWindowText(GetParent(GetParent(hwnd)), debugwrite_Buffer);

// purpose:
//		sets scroll bar size and handle position
//		scrolls items into view if empty space on bottom side
// !assumes:
//		al points to the attribute list structure
void __stdcall AttribList::Resize()
{
	int style = GetWindowLong(me.hwnd, GWL_STYLE), // get initial style
		top = me.top;

	AttribListMetrics alm;
	GetItemMetrics(alm);

	// scroll items if necessary
	uint item;
	if ( item = Seek(me.total,-alm.visibleRows, FlagHidden) < top) {
		me.top = item;
		Scroll(GetItemRow(me.top, item), alm); // dif between old and new top
	} else {
		ResizeOverlay();
	}

	// set scroll bar visibility
	// if all item rows (excluding hidden) are taller than
	// than window client area, show scroll bar.
	SetScrollBars(alm);

	// if scroll bar visibility changed, either from visible to hidden vice versa,
	// then redraw all titles, since their edges depend on the width of the client
	if ((style ^ GetWindowLong(me.hwnd, GWL_STYLE)) & WS_VSCROLL) {
		RedrawTitles();
		PostRedraw();
	}
}

// purpose:
//		sizes and positions overlay window according to selected item
//		hides if offscreen, lost focus, or item is not displayable
// !assumes:
//		al points to the attribute list structure
int __stdcall AttribList::ResizeOverlay()
{
	LPTSTR text;
	SIZE sz; //height/width of overlay
	POINT pt = {2,0}; // top/left of overlay
	HWND hedit = (HWND)GetWindowLong(me.hwnd,GWL_OVERLAY);
	UINT textlen;

	// only show overlay if current selected item is valid, if it has text,
	// and if the attribute list has focus (otherwise it would show when created)
	//if (GetSelectedFlags() && GetFocus()==self && (text=me.alis[me.selected].text)) {
	uint flags;
	if (hedit != nullptr
		&& GetSelectedFlags(&flags)
		&& GetFocus()==me.hwnd
		&& (text=me.alis[me.selected].text))
	{
		AttribListMetrics alm;
		GetItemMetrics(alm);
		HDC hdc = GetDC(me.hwnd);

		// calc top and left to be directly over item
		AttribListItem* ali = &(me.alis[me.selected]);
		//text = ali->text;
		//debugwrite("sel=%d ali=%x lbl=%x", selected, ali, ali->label);
		if (ali->icon) pt.x=(alm.iconWidth+2+2);
		if (ali->label) {
			GetTextExtentPoint32(hdc, ali->label, lstrlen(ali->label), &sz);
			pt.x+=sz.cx;
			if (!(ali->flags & FlagNoColon) && ali->text != nullptr) {
				GetTextExtentPoint32(hdc, T(": "), 2, &sz);
				pt.x += sz.cx;
			}
		}
		pt.y=GetItemRow(me.selected, me.top) * alm.itemHeight;
		if (pt.x > alm.rect.right) pt.x=alm.rect.right; // so that it does not appear floating off to the right side

		// special exception to hide overlay when item scrolled off screen
		if (pt.y < 0 || pt.y >= alm.rect.bottom) {
			ShowWindow(hedit, SW_HIDE);
			return FALSE;
		}

		// calc window size based on text length
		textlen = lstrlen(text);
		text=GetChoiceText(me.selected); // for check/group buttons
		GetTextExtentPoint32(hdc, text, lstrlen(text), &sz);
		sz.cx+=2;
		sz.cy=alm.itemHeight;
		CaretY = (alm.itemHeight-alm.textHeight)>>1;

		// verify caret position still valid
		if (CaretX > textlen) SetCaretX(-1);

		// keep overlay on screen and in work area
		RECT trect; // temp rect
		SystemParametersInfo(SPI_GETWORKAREA,0, &trect, FALSE);
		//debugwrite("wa l=%d r=%d t=%d b=%d", rect.left,rect.right,rect.top,rect.bottom);
		ClientToScreen(me.hwnd, &pt);
		if (pt.x > trect.right-sz.cx)	pt.x = trect.right-sz.cx;
		if (pt.x < trect.left)			pt.x = trect.left;
		if (pt.y > trect.bottom-sz.cy)	pt.y = trect.bottom-sz.cy;
		if (pt.y < trect.top)			pt.y = trect.top;

		// adjust pos/size if overlay has an nonclient edge
		trect.left = trect.top = trect.right = trect.bottom = 0;
		AdjustWindowRectEx(&trect, GetWindowLong(hedit,GWL_STYLE), FALSE, GetWindowLong(hedit,GWL_EXSTYLE));
		pt.x += trect.left;
		pt.y += trect.top;
		sz.cx += trect.right-trect.left;
		sz.cy += trect.bottom-trect.top;

		// only show caret if IS editable
		if (flags & (FlagEditable|FlagNumeric)) {
			CreateCaret(hedit,nullptr,2,alm.itemHeight);
			ShowCaret(hedit); // GetSystemMetrics(SM_CXBORDER) is too thin a caret
		} else {
			DestroyCaret();
		}

		// position and size overlay, show if hidden
		SetWindowPos(hedit,nullptr, pt.x,pt.y, sz.cx,sz.cy, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER);
		//SetWindowText(hedit, (LPTSTR)text);
		SetWindowLong(hedit, GWL_USERDATA, (long)text);
		//SetWindowLong(hedit,GWL_ID, me.alis[me.selected].flags & FlagIdMask);
		SetWindowPos(hedit, nullptr, 0,0,0,0, SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_NOACTIVATE|SWP_SHOWWINDOW);
		//ShowWindow(hedit, SW_SHOWNOACTIVATE); (messes things for show knows why)

		PostRedrawOverlay(); // must be called since pasting text of exact same window size would not update window
		return TRUE;

	} else {
		DestroyCaret();
		ShowWindow(hedit, SW_HIDE);
		return FALSE;
	}
}

// purpose:
//		selects the given item and ensures selection is visible
// !assumes:
//		al points to the current attribute list
int __stdcall AttribList::Select(uint newitem)
{
	return SelectGiven(newitem, 1|2); // ensure visible and set caret x
}

// purpose:
//		selects the given item.
// !assumes:
//		al points to the current attribute list
// returns:
//		LB_OKAY or LB_ERR
//
// options:
//		1 - ensure selection is visible, scroll if not
//		2 - set caret to end of edit text (if item is edit)
int __stdcall AttribList::SelectGiven(uint newitem, uint options)
{
	// convert ID to position
	newitem = IdToItem(newitem);

	// check selection validity
	uint flags;
	if (newitem == LB_ERR
	|| (flags=me.alis[newitem].flags) & (FlagDisabled|FlagHidden))
		return LB_ERR;
	uint selected=me.selected;
	if (newitem==selected) return LB_OKAY;

	// set redraw flags of new selection
	if (selected < me.total) me.alis[me.selected].flags |= FlagRedraw;
	me.alis[newitem].flags |= FlagRedraw;
	me.selected = selected = newitem;

	// ensure selection is visible if option set
	// scroll into view if not
	if (options & 1) {
		uint oldTop=me.top, newTop=oldTop;
		AttribListMetrics alm;
		GetItemMetrics(alm);
		if (selected < oldTop) {
			newTop=selected;
		} else {
			uint item = Seek(selected,1-alm.visibleRows, FlagHidden);
			if (item > oldTop) newTop=item;
		}
		if (newTop != oldTop) {
			me.top = newTop;
			Scroll(-GetItemRow(newTop, oldTop), alm);
		}
	}

	ResizeOverlay();
	if ((flags & (FlagEditable|FlagNumeric)) && (options & 2)) SetCaretX(-1);

	PostRedraw();
	return LB_OKAY;
}

// purpose:
//		Sets caret position for text editing.
//		Puts caret at end of text if -1 passed.
// !assumes:
//		al points to the current attribute list
//		selected is valid (GetSelectedFlags has been called)
//
void __stdcall AttribList::SetCaretX(uint newx)
{
	HDC hdc = GetDC(me.hwnd);
	SIZE sz = {0,0};
	LPTSTR text = me.alis[me.selected].text;
	static int caret[1024+2];
	uint len;
	
	if (!text) return; // prevent access violation in case item has only a label
	len = lstrlen(text);
	if (len>1024) len=1024; // safe practical limit

	if (newx >= len)
		newx = len; //force caret pos valid
	else
		if (newx == CaretX) return; //caret pos same, so do nothing more
	CaretX=newx;

	caret[CaretX]=0;
	if (CaretX > 0) {
		/*short reorder[256];
		GCP_RESULTSW gcp = {
			sizeof(GCP_RESULTS),
			&reorder[0], nullptr, nullptr, nullptr,
			nullptr,
			nullptr,0,
			0
		};*/
		SelectObject(hdc,GuiFont);
		// Would use the gcp function below so that caret positioning would be
		// "correct" on Hebrew and other Arabic backwards reading languages,
		// but sadly the function doesn't work
		//GetCharacterPlacement(hdc, text, len,0, &gcp, GCP_REORDER); // | GCP_GLYPHSHAPE
		//sz.cx = CaretPos[CaretX];
		// passing 0 length string to extent function sometimes
		// causes a GPF in GDI for some retarded reason
		// likely an MS bug, because it only happens on some platforms
		//GetCharacterPlacement(hdc, text, len,0, &gcp, GCP_REORDER); // | GCP_GLYPHSHAPE

		if (unicode) {
			// NT only, does not work on 9x
			GetTextExtentExPoint(hdc, text,len+1, 0,nullptr, &caret[1],&sz); //NT
			SetCaretPos(caret[CaretX],0); //NT
			//debugwrite("caret=%d %d %d %d", caret[0], caret[1], caret[2], caret[3]);
		} else {
			// 9x only, does not work right on NT/XP (when combing multiple fonts)
			GetTextExtentPoint32(hdc, text, CaretX, &sz);
			SetCaretPos(sz.cx,0);
		}
	} else {
		SetCaretPos(0,0);
	}
	
	//me.alis[me.selected].flags |= FlagRedraw;
	//PostRedraw();
	//PostRedrawOverlay();
}

// purpose:
//		Deletes a single character.
// !assumes al points to the current attribute list
//		selected is the currently selected choice
//		flags is the flags of the selected choice
void __stdcall AttribList::DeleteChar()
{
	//selected=me.selected;
	//flags=me.alis[me.selected].flags;
	LPTSTR text = me.alis[me.selected].text + CaretX;
	//if (!text || !(flags & FlagSizeMask)) return; // error if text nullptr or no length
	if (!text) return; // error if text nullptr or no length
	//memmove(text, text+1, lstrlen(text));
	RtlMoveMemory( (char *)text, (const char *)(text+1), lstrlen(text) * sizeof(TCHAR));
	//me.alis[me.selected].flags |= FlagRedraw;
	//PostRedraw();
	//PostRedrawOverlay();
	ResizeOverlay();
}

// !assumes al points to the current attribute list
// Inserts a character into the string at the caret position.
void __stdcall AttribList::InsertChar(uint newchar, uint bufSize)
{
	LPTSTR text = me.alis[me.selected].text;
	uint len;
	if (!text) return; // error if text nullptr

	len=lstrlen(text);

	if (len+1 >= bufSize) return;
	if (CaretX > len) {CaretX=len;     return;}
	//if (len+1 >= (flags >> FlagSizeRs)) return;
	// todo:

	text+=CaretX;
	RtlMoveMemory(text+1, text, (len-CaretX+1) * sizeof(TCHAR));
	*(text)=newchar;
	SetCaretX(CaretX+1);

	//me.alis[me.selected].flags |= FlagRedraw;
	//PostRedraw();
	ResizeOverlay();
}

void __stdcall AttribList::PostRedraw()
{
 	PostMessage(me.hwnd, WM_PAINT, 0,0);
}

void __stdcall AttribList::PostRedrawOverlay()
{
 	//PostMessage(GetWindowLong(me.hwnd,GWL_OVERLAY), WM_PAINT, 0,0);
	InvalidateRect((HWND)GetWindowLong(me.hwnd,GWL_OVERLAY), nullptr, FALSE);
}

// !assumes al points to the current attribute list
//
// Gets the item flags of the selected item.
int __stdcall AttribList::GetSelectedFlags(uint* pflags)
{
	uint selected=me.selected;
	if (pflags == nullptr) {
		return (selected >= me.total) ? false : true;
	}
	if (selected >= me.total) {
		*pflags=FlagDisabled|FlagHidden;		
		return false; //safety just in case
	}
	*pflags=me.alis[me.selected].flags;
	return true;
}

/*
// Gets the item flags of the given item.
int __stdcall AttribList::GetGivenFlags(uint item)
{
	item=me.selected;
	if (item >= me.total) {
		flags=FlagDisabled|FlagHidden;		
		return FALSE; //safety just in case
	}
	flags=me.alis[item].flags;
	return TRUE;
}
*/


// purpose:
//		Sets the coordinates for the hover rectangle which the cursor
//		moves over.
// !assumes:
//		al points to the current attribute list
// returns:
//		the item hovered over (-1 if none)
//		[flags] of hovered item (if over valid item)
//		[HoverRect] sets the rectangular coordinates
//		[me.hovered]
int __stdcall AttribList::GetHoverRect(int y)
{
	//if (me.hovered > me.total); else
	if (me.hwnd != HoverHwnd || y < HoverRect.top || y >= HoverRect.bottom) {
		RECT rect;
		HoverHwnd = me.hwnd;
		me.hovered = GetItemRect(-1, y, &rect);
		//debugwrite("getitemrect=%d",me.hovered);
		HoverRect.left   = rect.left;
		HoverRect.top    = rect.top;
		HoverRect.right  = rect.right;
		HoverRect.bottom = rect.bottom;
		//debugwrite("hwnd=%X rt=%d rb=%d rl=%d", me.hwnd, HoverRect.top, HoverRect.bottom, HoverRect.left);
	}
	return me.hovered;
}

// purpose:
//		Calculates the rectangle surrounding an item
//		either by item number or y coordinate.
// !assumes:
//		al points to the current attribute list
// returns:
//		the item hovered over (-1 if none)
//		if the item is beyond the total, it returns  the bottom of the list
//		and sets the rectangular coordinates in rect
//		[flags] of item (if over valid item)
int __stdcall AttribList::GetItemRect(uint item, int y, RECT* prect)
{
	SIZE sz;
	LPTSTR text;
	RECT rect;
	uint len;

	if ((signed)me.total <= 0) {
		GetWindowRect(me.hwnd,prect);
		return LB_ERR; //-1
	}

	// get list item height, using current font
	AttribListMetrics alm;
	GetItemMetrics(alm);

	// determine top coordinate from item row
	// or item and top from mouse coordinate
	if ((signed)item >= 0) {	// have item so figure y
		rect.top = GetItemRow(item,me.top) * alm.itemHeight;
	} else {					// have y so figure item
		item = Seek(me.top, y/alm.itemHeight, 1);
		//debugwrite("getitemrectseek=%d",item);
		rect.top = y - (y % alm.itemHeight);
	}
	rect.left = 2;
	//debugwrite("atrlist gir item=%d y=%d",item,y);

	if ((signed)item >= 0 && item < me.total) { // over valid item
		HDC hdc = GetDC(me.hwnd);
		rect.bottom = rect.top + alm.itemHeight;
		AttribListItem* ali = &(me.alis[item]);

		if (ali->icon) rect.left+=alm.iconWidth+2;
		if (text = ali->label) {
			len=lstrlen(text);
			GetTextExtentPoint32(hdc, text, len, &sz);
			rect.left += sz.cx;
			if (!(ali->flags & FlagNoColon) && ali->text != nullptr) {
				GetTextExtentPoint32(hdc, T(": "), 2, &sz);
				rect.left += sz.cx;
			}
		}
		sz.cx=0; // in case there is no text
		text=GetChoiceText(item); // for check/group buttons
		if (text != nullptr) {
			len=lstrlen(text);
			GetTextExtentPoint32(hdc, text, len, &sz);
		}
		rect.right = rect.left + sz.cx;
	} else { // beyond end of list
		rect.right = 0;
		rect.bottom = 4096; //set to ridiculously high number
	}
	prect->left = rect.left;
	prect->top = rect.top;
	prect->right = rect.right;
	prect->bottom = rect.bottom;
	return item;
}


// purpose
//		Converts an ID to an item position. If item does not
//		have SelectById set, it returns the item unchanged.
//		If the given ID was not found, -1 will be returned.
// !assumes
//		al points to the current attribute list
int __stdcall AttribList::IdToItem(uint id)
{
	uint item; // = id;
	uint total;

	if (id & SelectById) {
		total = me.total;
		id &= FlagIdMask;
		AttribListItem* ali;
		for (item = 0, ali = &(me.alis[0]);
			 item < total;
			 item++, ali++)
		{
			if ((ali->flags & FlagIdMask) == id)
				return item;
		}
		id = LB_ERR;
	} else {
		if (id >= me.total)
			id = LB_ERR;
	}

	return id;
}


// purpose:
//		sets the flags for a toggle or menu button.
//		not meant for edits
//		very simple function, but I saw myself using this exact same
//		code in several places and decided to consolidate.
//		no error checking since so much has already happened by any
//		part of the code that would call this function.
// !assumes:
//		al points to the current attribute list
//		selected is valid (GetSelectedFlags has been checked)
// input:
//		value - new value to set, absolute or relative
//		relative - specifies absolute or relative mode (0-absolute, 1-relative clipped, 2-relative wrap)
// returns:
//		nothing
void AttribList::SetSelectedButtonValue(int value, int relative)
{
	AttribListItem& ali = me.alis[me.selected];
	ali.flags |= FlagRedraw;
	PostRedraw(); //redraw toggle or menu item
	HoverRect.bottom=0; // force mouse recalc upon next mouse move

	int newValue = value;
	if (relative > 0)
		newValue += ali.value.i;
	if (newValue < 0) {
		switch (relative) {
		case 2:
			newValue = ali.high.i;
			break;
		default:
			newValue = 0;
			break;
		}
	}
	elif (newValue > ali.high.i) {
		switch (relative) {
		case 2:
			newValue %= (ali.high.i+1);
			break;
		default:
			newValue = ali.high.i;
			break;
		}
	}
	
	if (newValue != ali.value.i) {
		ali.value.i = newValue;
		SendClickCommand(me.selected);
		ResizeOverlay();
	}
}


// purpose
//		Sends command message to parent, for when button clicked.
//		A message will only be sent if the button has an ID.
// !assumes
//		al points to the current attribute list
void __stdcall AttribList::SendClickCommand(int index)
{
	uint flags = me.alis[index].flags;

	if (flags & FlagIdMask) {
		WPARAM wparam = (flags & FlagIdMask) | WnClicked;
		if (flags & FlagIdPlusValue)
			wparam += me.alis[index].value.i;
		SendMessage(GetParent(me.hwnd), WM_COMMAND, wparam, (LPARAM)me.hwnd);
	}
}


void __stdcall AttribList::ActivateNearestButton()
{
	for (unsigned int i=me.selected; i < me.total; i++) {
		uint flags = me.alis[i].flags;
		if (flags & FlagPushable)
			if (me.alis[i].high.i == 0) {
				SendClickCommand(i);
				break;
			}
	}
}


// purpose:
//		Redraws all title 
//		either by item number or y coordinate.
// !assumes:
//		al points to the current attribute list
void __stdcall AttribList::RedrawTitles()
{
	uint item;
	AttribListItem* ali;
	for (item=me.top, ali = &(me.alis[item]); item < me.total; item++, ali++)
		if (ali->flags & FlagTitle)
			ali->flags |= FlagRedraw;
}

// purpose:
//		get list item's height
//		font height
//		and image list icon's size
// !assumes:
//		al points to the current attribute list
//		GuiFont is a valid font
// returns:
//		[itemHeight] - pixel height of single item row
//		[textHeight] - text cell height
//		[iconHeight] - image list icon height
//		[iconWidth] - icon width
//		[visibleRows] - number of visible whole rows given size (not partial rows)
//		[rect] filled with client coordinates
void __stdcall AttribList::GetItemMetrics(AttribListMetrics& alm)
{
	TEXTMETRIC tm;

	// get text height
	HDC hdc=GetDC(me.hwnd);
	SelectObject(hdc, GuiFont);
	GetTextMetrics(hdc, &tm);
	alm.textHeight = tm.tmHeight;
	if (alm.textHeight < 4) alm.textHeight=4; //sanity check to prevent possible div by zero

	// get icon size
	if (me.himl)
		ImageList_GetIconSize(me.himl, &alm.iconWidth,&alm.iconHeight);
	else
		alm.iconWidth = alm.iconHeight = 0;

	// set item height to the larger of icon or text
	alm.itemHeight = (alm.iconHeight > alm.textHeight) ? alm.iconHeight : alm.textHeight;

	GetClientRect(me.hwnd, &alm.rect);
	alm.visibleRows = alm.rect.bottom / alm.itemHeight;
	//debugwrite("al h=%d a=%d d=%d", tm.tmHeight, tm.tmAscent, tm.tmDescent);
};

// purpose:
//		scrolls list by number of rows, and sets new top of list.
// !assumes:
//		al points to the current attribute list
// options:
//		(bit flags can be combined)
//		1 - scroll by page height
//		2 - move selection in parallel
//		3*- scroll by page and move selection (pgup and pgdn use this)
//		4 - absolute
void __stdcall AttribList::ScrollBy(int rows, long options)
{
	uint oldTop=me.top, newTop;
	int topDif;
	
	AttribListMetrics alm;
	GetItemMetrics(alm); // calculates and sets multiple vars

	if (options & 4) {
		newTop=Seek(0, rows, FlagHidden);
	} else {
		if (options & 1) rows *= alm.visibleRows;
		newTop=Seek(oldTop, rows, FlagHidden);
	}
	if (newTop > oldTop) {
		uint item = Seek(me.total, -alm.visibleRows, FlagHidden);
		if (newTop > item) newTop=item;
	}
	if (newTop == oldTop) return;
	me.top = newTop;

	topDif = GetItemRow(newTop, oldTop);
	//debugwrite("topdif = %d", TopDif);

	if (options & 1) {
		//Seek(me.selected, TopDif, FlagHidden);
		//Seek(item, (TopDif >= 0) ? -1:1, FlagHidden|FlagDisabled|TypeSeparator);
		//LanAtrs[*(LanListPtr+LanListSelect)].flags |= LlfRedraw;
		//LanListSelect+=newTop-LanListTop;
		//LanAtrs[*(LanListPtr+LanListSelect)].flags |= LlfRedraw;
	}
	Scroll(-topDif, alm);
}


// purpose:
//		scrolls client area
// !assumes:
//		al points to the current attribute list
//		item_height is set by a call to GetItemMetrics
//		text_height ...
//		icon_height	...
//		icon_width	...
void __stdcall AttribList::Scroll(int rows, AttribListMetrics& alm)
{
	//GetItemMetrics();
	//GetClientRect(me.hwnd, &rect);
	HoverRect.bottom=0; // force mouse recalc upon next mouse move
	//ScrollWindow(me.hwnd, 0,dif*alm.itemHeight, &rect,&rect);
	ScrollWindow(me.hwnd,0,rows*alm.itemHeight, nullptr,nullptr);
	SetScrollBars(alm);
	ResizeOverlay();
}

// purpose:
//		sets scroll bar range and position
// !assumes:
//		al points to the current attribute list
//		item_height is set by a call to GetItemMetrics
//		text_height ...
//		icon_height	...
//		icon_width	...
void __stdcall AttribList::SetScrollBars(AttribListMetrics& alm)
{
	//GetItemMetrics();
	//debugwrite("r=%d p=%d j=%d", GetItemRow(me.total, 0)-1, GetItemRow(me.top,0), alt->visibleRows);
	ScrollInfo.nMax = GetItemRow(me.total, 0)-1;
	ScrollInfo.nPage = alm.visibleRows;
	ScrollInfo.nPos = GetItemRow(me.top,0);
	SetScrollInfo(me.hwnd, SB_VERT, &ScrollInfo, TRUE);
}

// purpose:
//		selects the correct choice text of text for a toggle/menu/button.
//		it leaves the text ptr alone if other type.
//		for example, a toggle might show "yes" if checked, "no" if not.
// !assumes:
//		flags is the bitflags of the desired item (GetSelectedFlags called or similar)
// notes:
//		item type is validated.
LPTSTR __stdcall AttribList::GetChoiceText(int index)
{
	if (index < 0 || (unsigned)index >= me.total) return nullptr;

	AttribListItem& ali = me.alis[index];
	TCHAR* text = ali.text;
		if (text == nullptr) return nullptr;

	uint flags = ali.flags;

	if (flags & (FlagPushable|FlagMenu)) {
		for (int value=ali.value.i; value > 0 && *text; value--) {
			text += lstrlen(text)+1; // skip ahead by size of string + null character
		};
	}

	return text;
}

// purpose:
//		appends a Unicode string to a moveable memory object.
//		resizes it if necessary.
// !assumes:
//		the passed memory object must have been alloced as fixed
//		or moveable object that has been locked. Either way, the actual
//		address needs to be passed, not the global handle.
//
//		GlobalAlloc(GMEM_FIXED, 2048) //for internal use
//		GlobalLock(GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE, 2048)) //for clipboard
//
// returns:
//		character length of new string
int AttribList::AppendString(HGLOBAL* phmt, TCHAR* tail)
{
	TCHAR* text = (TCHAR*)*phmt; // get pointer to existing string
	uint textlen, taillen, memsize;

	//debugwrite("-@%08X %d text=%S",text,tsize,text);

	if (text==nullptr || tail==nullptr) return 0; // null pointer so return 0 size

	textlen = lstrlen(text); // length of existing text
	taillen = lstrlen(tail); // string to append length
	memsize = (UINT)GlobalSize(GlobalHandle((HGLOBAL)text)); // max size of memory object

	//debugwrite(" @%08X %d/%d dest=%S",dest,dsize,msize,dest);

	if ((textlen+taillen) * sizeof(TCHAR) >= memsize) { // reallocate if necessary
		text = (TCHAR*)GlobalHandle(text);
		GlobalUnlock( text ); // get handle from pointer and unlock (no effect if static)
		if (!(text = (TCHAR*)GlobalReAlloc(text,((textlen+taillen) * sizeof(TCHAR) )+256,GMEM_MOVEABLE)) )
			return textlen;
		*phmt = text = (TCHAR*)GlobalLock(text); // lock to get new pointer (no effect if static)
	}
	RtlMoveMemory(text+textlen, tail, (taillen+1)*sizeof(TCHAR));

	//debugwrite(" @%08X dest=%S",dest,dest);
	textlen += taillen;
	return textlen;
}


// purpose:
//		displays the context menu for an item and picks the appropriate menu
//		choices based on the selected item type and clipboard contents.
// !assumes:
//		al points to the current attribute list
//		or moveable object that has been locked. Either way, the actual
// input:
//		item - selected item 0 to total-1 or -1 for none
//		x - left of menu
//		y - top of menu
// returns:
//		nothing, WM_COMMAND is sent to window procedure
void AttribList::ShowContextMenu(uint item, int x,int y)
{
	HMENU menu = CreatePopupMenu();
	debugwrite("al menuhnd=%X item=%d", menu,item);

	uint flags;

	// dynamically create menu based on whatever is selected
	if (((signed)item >= 0)
	&& (item < me.total)
	&& !((flags = me.alis[item].flags) & (FlagDisabled|FlagHidden)))
	{
		if (flags & FlagPushable) {
			if (me.alis[item].high.i > 0) {
				AppendMenu(menu,MF_STRING,IDAL_TOGGLE,T("&Toggle"));
			}
			else {
				AppendMenu(menu,MF_STRING,IDAL_COMMAND,T("&Do command"));
			}
			SetMenuDefaultItem(menu,0,TRUE);
		}
		//else if ((flags & (TypeMask|TypeFile)) == (TypeEdit|AlfFile)) {
		//		AppendMenu(menu,MF_STRING,MidBrowse,T("&Browse"));
		//		SetMenuDefaultItem(menu,0,TRUE);
		//}
		AppendMenu(menu,MF_STRING,IDAL_COPY,T("&Copy"));
		if (flags & (FlagEditable|FlagNumeric)) { // ensure IS edit and is NOT locked
			if (GetPriorityClipboardFormat(&ClipboardFormats[0],2) > 0)
				AppendMenu(menu,MF_STRING,IDAL_PASTE,T("&Paste"));
			AppendMenu(menu,MF_STRING,IDAL_CLEAR,T("C&lear"));
		}
		AppendMenu(menu,MF_SEPARATOR,0,0);
	}
	AppendMenu(menu,MF_STRING,IDAL_COPYALL,T("Copy &all"));
	AppendMenu(menu,MF_STRING,IDAL_HELP,T("&Help"));

	SendMessage(GetParent(me.hwnd),WM_COMMAND, (flags & FlagIdMask)|WnContext, (LPARAM)menu);

	ClientToScreen(me.hwnd, (POINT*)&x);
	SetCursor(LoadCursor(nullptr, IDC_ARROW)); // otherwise menu does not show arrow
	TrackPopupMenuEx(
		menu,
		TPM_LEFTALIGN|TPM_RIGHTBUTTON|TPM_NONOTIFY,
		x, y,
		me.hwnd,
		nullptr);
	DestroyMenu(menu);
}


// purpose:
//		displays the popup menu for a multi choice menu item.
// !assumes:
//		al points to the current attribute list
//		selected is valid (GetSelectedFlags has been checked)
// input:
// returns:
//		nothing, WM_COMMAND is sent to window procedure
void AttribList::ShowSelectedChoiceMenu()
{
	RECT rect;
	GetItemRect(me.selected, 0, &rect);
	rect.top=rect.bottom; // setup for ClientToScreen to make POINT
	ClientToScreen(me.hwnd, (POINT*)&rect);
	ShowGivenChoiceMenu(selected, rect.left, rect.top);
}


// purpose:
//		displays the popup menu for a multi choice menu item.
// !assumes:
//		al points to the current attribute list
//		item is valid (GetGivenFlags has been checked)
// input:
//		item - selected item 0 to total-1
//		x - left of menu
//		y - top of menu
// returns:
//		nothing, WM_COMMAND is sent to window procedure
void AttribList::ShowGivenChoiceMenu(uint item, int x,int y)
{
	HMENU menu;
	int mid; // menu item id
	TCHAR* text = me.alis[item].text;
			
	if (text && (menu=CreatePopupMenu())) {
		// build menu choices
		for (mid=0; *text; text+=lstrlen(text)+1, mid++) {
			AppendMenu(menu,MF_STRING,mid,text);
		}
		//SetMenuDefaultItem(menu,flags >> FlagCheckedRs,TRUE);
		//todo:

		TrackPopupMenuEx(
			menu,
			TPM_LEFTALIGN|TPM_LEFTBUTTON|TPM_NONOTIFY,
			x, y,
			me.hwnd,
			nullptr);
		DestroyMenu(menu);
	}
}

// purpose:
//		counts how many choies are in an item (almost always for menus).
//		the last choice is terminated by a double null.
// !assumes:
//		flags is the bitflags of the desired item (GetSelectedFlags called or similar)
//		item is indeed a menu item (otherwise potential GPF). Item type is not 
//		validated because this function is called so rarely, and only menu item 
//		code should even be calling this function anyway.
static int TotalChoices(TCHAR* text)
{
	int total=0;
	if (text != nullptr) {
		//if ((flags & TypeMask) == TypeMenu)
		while (*text) {
			total++;
			text += lstrlen(text)+1; // skip ahead by size of string + null character
		}
	}
	return total;
}

// hack function to remedy MS's bitmap palette faux pau
// I don't care whether you choose RGB or BGR, but be CONSISTENT.
//static uint __fastcall ReverseRGB(uint rgb)
static __inline uint ReverseRGB(uint rgb)
{
#ifdef _MSC_VER
	__asm {
	mov eax,rgb
	mov cl,ah
	rol eax,16
	mov ah,cl
	and eax,0xFFFFFF
	}
#else
	return ((rgb & 255)<<16) | (rgb & (255<<8)) | ((rgb & (255<<16)) >> 16);
	//       red                green               blue
#endif
}


// just to avoid including the whole math library
__inline static uint alabs(signed int n)
{
#if defined(_MSC_VER) && defined(WANTASMFORSOMEREASON)
	__asm {
	mov eax,n
	test eax,eax
	jns abs_pos
	neg eax
abs_pos:
	}
#else
	return (n >= 0 ? n : -n);
#endif
}

HMENU AttribList::AttribListToMenu(AttribListItem* alis)
{
	// dynamically build menu
	HMENU hmMain = CreateMenu(),
	      hmChild = nullptr;
	TCHAR title[256]; // current title (following items are under it)
		title[0] = '&'; title[1] = '\0';
	TCHAR label[256]; // item label
		label[0] = '&'; label[1] = '\0';
	uint item;

	for (item = 0; alis[item].flags != 0; item++) {
		uint flags = alis[item].flags;
		if (flags & FlagHidden) continue;
		
		// add submenu
		if (flags & FlagTitle) {
			if (hmChild != nullptr) {
				AppendMenu(hmMain, MF_POPUP, (UINT_PTR)hmChild, title);
				//hmChild = nullptr;
			}
			lstrcpy(&title[1], alis[item].label);
			hmChild = CreateMenu();
		}
		// add choice from button
		elif (flags & FlagPushable) {
			if (alis[item].high.i == 0) {
				lstrcpy(&label[1], alis[item].label);
				AppendMenu(hmChild, MF_STRING, flags & FlagIdMask, label);
			}
		}
		//case TypeToggle: // toggle button with checked/unchecked
		//case TypeMenu: // multichoice menu
	}
	if (hmChild != nullptr) {
		AppendMenu(hmMain, MF_POPUP, (UINT_PTR)hmChild, title);
		//hmChild = nullptr;
	}
	return hmMain;
	//SetMenu(GetParent(...), hmMain); // let caller do this assignment
}

////////////////////////////////////////////////////////////////////////////////
// JUNK CODE - DELETABLE EXPERIMENTS
////////////////////////////////////////////////////////////////////////////////

	// Was trying to get the IME for 95/98 to show up, but inconsistent results
	//ImmSetOpenStatus(
	//	ImmGetContext(hwnd),
	//	TRUE);
	/*	ImmSetOpenStatus(
		ImmCreateContext(),
		TRUE);
	SendMessage(ImmGetDefaultIMEWnd(hwnd),
		WM_IME_CONTROL,
		IMC_OPENSTATUSWINDOW,
		0);
	{
		HWND imehwnd;
		imehwnd=FindWindow("msime95main", nullptr);
		//ShowWindow(imehwnd, SW_SHOW);
		//imehwnd=CreateWindow("msime95main", "msime95main", WS_VISIBLE, 200,200, 100,100, self, 0, ProgMemBase, nullptr);
		/*SendMessage(imehwnd, WM_ACTIVATEAPP, TRUE, 0);
		SendMessage(imehwnd, WM_IME_NOTIFY, IMN_OPENSTATUSWINDOW, 0);
		//SetActiveWindow(imehwnd);
		SendMessage(imehwnd, WM_IME_CONTROL, IMC_OPENSTATUSWINDOW, 0);
		SendMessage(imehwnd, WM_IME_SETCONTEXT, 1, 0xC000000F);
		DefWindowProc(hwnd,  WM_IME_SETCONTEXT, 1, 0xC000000F);
		SendMessage(imehwnd, WM_IME_NOTIFY, IMN_OPENSTATUSWINDOW, 0);
	}
	return 0;
	*/

		/*
		{ // just for fun
			SHFILEINFO sfi;
			HIMAGELIST himl;
			HDC hdc=GetDC(hwnd);

			himl=(HIMAGELIST)SHGetFileInfo("C:\\WINDOWS",0,&sfi,sizeof(sfi), SHGFI_SYSICONINDEX);
			debugwrite("large=%X idx=%d", himl,sfi.iIcon);
			if (himl)
			ImageList_Draw(himl, sfi.iIcon, hdc,0,0, ILD_TRANSPARENT);
			himl=(HIMAGELIST)SHGetFileInfo("C:\\WINDOWS",0,&sfi,sizeof(sfi), SHGFI_SYSICONINDEX|SHGFI_SMALLICON);
			debugwrite("small=%X idx=%d", himl,sfi.iIcon);
			if (himl)
			ImageList_Draw(himl, sfi.iIcon, hdc,0,32, ILD_NORMAL);
			ImageList_Destroy(himl); // >:-)

			ReleaseDC(hwnd,hdc);
			return 0;
		}
		*/

/*	case WM_IME_SETCONTEXT:
		debugwrite("ime setcontext");
        return DefWindowProc(hwnd, message, wParam, lParam);
	case WM_IME_STARTCOMPOSITION:
		debugwrite("ime startscomps");
        return DefWindowProc(hwnd, message, wParam, lParam);
	case WM_IME_COMPOSITION:
		debugwrite("ime compose %X %X", wParam, lParam);
		if (lParam & GCS_RESULTSTR) {
			debugwrite("getting composition string");
			{
			short chars[256];
			HIMC context=ImmGetContext(hwnd);
			context=ImmGetContext(hwnd);
			//HIMC context=ImmCreateContext();
			ImmGetCompositionStringA(context, GCS_RESULTSTR, chars, sizeof(chars));
			debugwrite("stringA=%s", chars);
			ImmGetCompositionString(context, GCS_RESULTSTR, chars, sizeof(chars));
			debugwrite("stringW=%S", chars);
			//ImmGetCompositionString(context, GCS_RESULTSTR, chars, sizeof(chars));
			//ImmReleaseContext(hwnd,context);
			ImmReleaseContext(hwnd,context);
			//ImmDestroyContext(context);
			}
		}
        return DefWindowProc(hwnd, message, wParam, lParam);
	case WM_IME_KEYDOWN:
		debugwrite("ime keydown");
        return DefWindowProc(hwnd, message, wParam, lParam);
	case WM_IME_CHAR:
		debugwrite("ime char w=%d l=%d", wParam, lParam);
        return DefWindowProc(hwnd, message, wParam, lParam);
*/

