/*
Name: AttributeList
Birth: 20030610
Modified: 20050407
Author: Dwayne Robinson

<what is it>
	A selectable list of attributes, where each attribute can be edited,
	disabled, or hidden independantly - like standard dialog controls.
	It supports behaviors for the following simple, standard controls:

	push buttons/hyperlinks - one click actions/commands
	toggle buttons/checkboxes - two state values (true/false, yes/no, up/down)
	menu buttons - clicking opens a multivalue menu of choices
	text edit - Unicode single line text string
	title bar - caption for single list or separator for multiple sections
	separator - not a control, just some white space to separate attributes

  Original Concept:
	The original concept for this control came from Spc2Midi, my SPC emulator.
	With that object, the focus was more on a list of numerical values with
	various ranges and step increments that could be easily edited and 
	manipulated. This object (while also called an attribute list) is both
	simpler and more advanced version of the earlier - a hybrid between
	property lists (like you find in Internet Properties's Advanced page)
	and XP Explorer's common tasks. Almost all the necessary functionality
	of an HTML sidepage with no webpage overhead because there is no 
	rotten HTML!

  Differences:
	Unlike an ordinary list box.
	- memory is not allocated by the control, but pointed to by the caller
	- single selection only, no multiple

<notes>
	Prints Unicode text
	Does not like simultaneous, multithreaded messages

<example>  
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


<attributes>
	label	text description of text field or button
			must not be null
	icon	appropriate picture for item
			may be null (no icon)
	text	typed text or ptr to checkbox words (yes/no, true/false, up/down)
			may only be null if button
	flags	miscellaneous attributes


<flag types>
	type (button, toggle, edit)
	disabled
	hidden
	separator
	checked / button pushed
	redraw
	numbers only (for text prompt)
	max length (for text prompt only)
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
#include <commctrl.h>
#include <shellapi.h>
#define ATRBLIST_C
#include "atrblist.h"
//#include <imm.h>

// restore what WINNT.H for some reason deffed out
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

#define ProgMemBase (HINSTANCE)0x400000
#define GWL_OVERLAY 0
#define GWL_OWNER 0
#ifndef IDC_HAND  
#define IDC_HAND            32649
#endif


////////////////////////////////////////////////////////////////////////////////

int __stdcall AtrListProc(HWND hwnd, UINT message, long wParam, long lParam);
int __stdcall AtrOverlayProc(HWND hwnd, UINT message, long wParam, long lParam);
static void __stdcall Resize();
static int __stdcall Seek(unsigned int from, int distance, int activeonly);
static int __stdcall Select(unsigned int newitem);
static void __stdcall SetCaretX(unsigned int newpos);
static void __stdcall DeleteChar();
static void __stdcall InsertChar(unsigned int newchar);
static void __stdcall PostRedraw();
static int __stdcall GetHoverRect(int y);
static void __stdcall SendClickCommand(unsigned int flags);
static int __stdcall GetSelectedFlags();
static int __stdcall IdToItem(unsigned int item);
static int __stdcall GetItemRow(unsigned int item, unsigned int top);
static int __stdcall GetItemRect(unsigned int item, int y);
static void __stdcall GetItemMetrics();
static void __stdcall RedrawTitles();
static void __stdcall ScrollBy(int dif, long flags);
static void __stdcall Scroll(int ScrollDif);
static void __stdcall SetScrollBars();
static int __stdcall SelectGiven(unsigned int newitem, unsigned int options);
static void __stdcall PostRedrawOverlay();
static int __stdcall ResizeOverlay();
static LPWSTR __stdcall GetChoiceText(short *text);
static int AppendString(HGLOBAL *hmut, short *text, int *size);
static void ShowContextMenu(unsigned int item, int x,int y);
static void ShowSelectedChoiceMenu();
static void ShowGivenChoiceMenu(unsigned int item, int x,int y);
static void SetSelectedButtonValue(unsigned int flags);
static unsigned int TotalChoices(short *text);
//static unsigned int __fastcall ReverseRGB(unsigned int rgb);
__inline static unsigned int ReverseRGB (unsigned int rgb);
__inline static unsigned int abs_(signed int n);


#ifndef T
#ifdef UNICODE
  #define T(quote) L##quote
#else
  #define T
#endif
#endif

#ifdef MYDEBUG
 extern void debugwrite(char* Message, ...);
 extern void debugerror();
#else
 #define debugwrite //
 #define debugerror //
#endif


short AtrListClassW[] = L"AttributeList";
short AtrOverlayClassW[] = L"AttributeOverlay";
char AtrListClassA[] = "AttributeList";
char AtrOverlayClassA[] = "AttributeOverlay";

WNDCLASS wcAtrList = {
	CS_OWNDC|CS_DBLCLKS, //style
	(WNDPROC)AtrListProc, //lpfnWndProc
	0, //cbClsExtra
	4, //DLGWINDOWEXTRA, //cbWndExtra=0;
	ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	(HBRUSH)(COLOR_WINDOW + 1), //hbrBackground
	0, //lpszMenuName
	AtrListClass //lpszClassName
};

WNDCLASS wcAtrOverlay = {
	CS_NOCLOSE, //style
	(WNDPROC)AtrOverlayProc, //lpfnWndProc
	0, //cbClsExtra
	4, //DLGWINDOWEXTRA, //cbWndExtra=0;
	ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	NULL, //(HBRUSH) hbrBackground
	0, //lpszMenuName
	AtrOverlayClass //lpszClassName
};

// These can be global variables because at any given instant,
// there will only be one attribute list with focus, and only
// one attribute list will receive messages at a time. Now this
// could bode badly for multithread apps that sent messages from
// two different threads at the same time to different attribute
// lists. I'm assuming that will not happen.
static AttribList *al;			// !this variable must be set
static AttribListItem *ali;		//  before calling functions
static HWND self;				// this is set upon message entry
static unsigned int item;		// number of item either hovered or selected
static unsigned int flags;		// cache this variable because it is used so often
static unsigned int selected;	// currently selected item
static int traveled;			// distance traveled in a seek operation

// shared vars
/* GOLINK complains if not defined as static
LONG unicode;					// OS supports unicode
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

static LONG unicode;					// OS supports unicode
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

int __stdcall AtrListProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	self = hwnd;
	al = (AttribList*)GetWindowLong(hwnd, GWL_USERDATA);

	//debugwrite("al  msg=%X wParam=%X lparam=%X", message, wParam, lParam);

	switch (message) {
	case WM_CREATE:
	{
		// initialize display context to have standard GUI font
		// transparent blitting, and NO silly pen!
		//NONCLIENTMETRICS ncm;
		HWND hedit;

		// It does not matter whether THIS window is Unicode, since it may
		// have been created as ANSI, but whether the OS supports Unicode.
		unicode = IsWindowUnicode(GetDesktopWindow());

		hdc=GetDC(hwnd);
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
			debugwrite("al title=%d normal=%d", ncm.lfCaptionFont.lfHeight, ncm.lfMessageFont.lfHeight);
			ncm.lfCaptionFont.lfHeight = ncm.lfMessageFont.lfHeight;
			ncm.lfCaptionFont.lfWeight=FW_BOLD;
			GuiFontTitle = CreateFontIndirect(&ncm.lfCaptionFont);
		}
		SetBkMode(hdc, TRANSPARENT);
		//SetTextAlign(hdc, TA_LEFT|TA_RTLREADING);
		//SetTextAlign(hdc, TA_LEFT);
		SelectObject(hdc, GetStockObject(NULL_PEN));

		CursorArrow=LoadCursor(0,IDC_ARROW);
		CursorIbeam=LoadCursor(0,IDC_IBEAM);
		CursorHand=LoadCursor(0,(LPTSTR)IDC_HAND);
		if (!CursorHand)
			CursorHand=LoadCursor(ProgMemBase,(LPTSTR)IDC_HAND);

		// set default Attribute List pointer just in case
		// to prevent any other functions from crashing
		SetWindowLong(hwnd, GWL_USERDATA, (long)&DefaultAl);

		// Store overlay hwnd separately since silly Windows does not allow
		// children windows to be owners. -_-
		// Also set hwnd in child overlay so it can find its poor parent
		// in the huge sea of unfriendly windows, since neither GetParent or
		// GetWindow(GW_OWNER) work correctly.
		if (unicode)
			hedit = CreateWindowExW(0, AtrOverlayClassW,
				AtrOverlayClassW, WS_POPUP|WS_CHILD, 0,0, 100,24, hwnd,NULL, ProgMemBase, &(DefaultAl.al));
		else
			hedit = CreateWindowExA(0, AtrOverlayClassA,
				AtrOverlayClassA, WS_POPUP|WS_CHILD, 0,0, 100,24, hwnd,NULL, ProgMemBase, &(DefaultAl.al));
		SetWindowLong(hwnd,0,(long)hedit);
		SetWindowLong(hedit,0,(long)hwnd);
		return 0;
	}
	case LB_INITSTORAGE: // fills attribute list with items
		if (!lParam) return LB_ERR;
		al = (AttribList*)lParam; // set pointer to new attribute list
		SetWindowLong(hwnd, GWL_USERDATA, lParam);

		GetItemMetrics(); // set new top if necessary...
		if ( (unsigned)Seek(al->total,-ItemRows, AlfHidden) < al->top) al->top = item;
		SetScrollBars();
		ResizeOverlay();
		if (GetSelectedFlags()) SetCaretX(-1);
		HoverRect.bottom=0; // force mouse recalc upon next mouse move

		InvalidateRect(hwnd, NULL, FALSE);
		return 0;

	case WM_PAINT:
	{
		unsigned int total=al->total;
		unsigned int
			clrct=GetSysColor(COLOR_CAPTIONTEXT), //caption text
			clrit=GetSysColor(COLOR_INACTIVECAPTIONTEXT), //inactive text
			clrab=GetSysColor(COLOR_HIGHLIGHT), //active background
			clrat=GetSysColor(COLOR_HIGHLIGHTTEXT), //active text
			clrsb=GetSysColor(COLOR_BTNFACE), //selected background
			clrst=GetSysColor(COLOR_BTNTEXT), //selected text
			clrub, //=GetSysColor(COLOR_WINDOW), //unselected background
			clrut=GetSysColor(COLOR_WINDOWTEXT), //unselected background
			clrdt=GetSysColor(COLOR_GRAYTEXT); //disabled text
			//clrsb=((clrab & 0xFEFEFE) + (clrub & 0xFEFEFE)) >> 1;
		unsigned int focus=GetFocus()==hwnd,
			fullfocus;
		unsigned int secondpass=0; //two pass counter
		const unsigned int *pixels; //picture to display beside item
		unsigned int clrb, clrt; //current color of background and text
		unsigned int len; //length of string, either text or label
		int x; //text offsets
		HFONT hlf;
		SIZE sz;
		LPWSTR text;
		RECT ur, ir;
		HRGN urgn=CreateRectRgn(0,0,0,0); //create stupid, dummy region
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
			if (abs_( ( clrut        & 255) - (clrub         & 255) ) +
				abs_( ((clrut >> 8 ) & 255) - ((clrub >> 8 ) & 255) ) +
				abs_( ((clrut >> 16) & 255) - ((clrub >> 16) & 255) )
				< 128) {
				clrut=GetSysColor(COLOR_WINDOW);
			}
		}

		// get update regions
		hdc=GetDC(hwnd);
		GetUpdateRect(hwnd, &ur, FALSE);
		GetUpdateRgn(hwnd, urgn, FALSE);
		ValidateRect(hwnd, NULL);

		GetItemMetrics();
		//if (TextHeight < ItemHeight)
		CaretY = (ItemHeight-TextHeight)>>1;
		IconY = (ItemHeight-IconHeight)>>1;

		// draw all items in two pass loop
		selected=al->selected;
		while (TRUE) {
			//set item rectangle
			rect.left=0;
			rect.top=0;
			//rect.right=2048; //any ridiculously high number
			rect.bottom=ItemHeight;

			for (item=al->top, ali = &(al->al[item]);
			 item < total;
			 item++, ali++
			 )
			{
				// if visible and needs redrawing
				flags = ali->flags;
				if (!(flags & AlfHidden)) {
					if (flags & AlfRedraw) {
						ali->flags &= ~AlfRedraw;
						fullfocus = ((item == selected) & focus);
						x=2;

						// set colors according to type and whether selected
						if (fullfocus)					clrb=clrab;
						else if (item == selected)		clrb=clrsb;
						else							clrb=clrub;
						SetBkColor(hdc, clrb);

						if ((flags & AlfTypeMask) == AlfTitle)
														clrt=(focus) ? clrct : clrit;
						else if (flags & AlfDisabled)	clrt=clrdt;
						else if (fullfocus)				clrt=clrat;
						else if (item == selected)		clrt=clrst;
						else							clrt=clrut;
						SetTextColor(hdc, clrt);

						// draw background
						ExtTextOutW(hdc, 0,0, ETO_OPAQUE, &rect, NULL,0, NULL);

						// set font bold if title, and draw background
						if ((flags & AlfTypeMask) == AlfTitle) {
							hlf=GuiFontTitle;
							SelectObject(hdc, GetSysColorBrush(focus ? COLOR_ACTIVECAPTION : COLOR_INACTIVECAPTION));
							RoundRect(hdc, 1,rect.top+1, rect.right,rect.bottom, 11,12);
						} else {
							hlf=GuiFont;
						}
						SelectObject(hdc, hlf);

						// draw icon at very left (usually 16x16)
						if (ali->icon) {
							ImageList_Draw(al->himl,ali->icon, hdc,2,rect.top+IconY, ILD_TRANSPARENT);
							x+=(IconWidth+2);
						}

						// print label, regardless of type
						if (text = ali->label) {
							len=lstrlenW(text);
							TextOutW(hdc, x,rect.top+CaretY, text,len);
							//DrawState(hdc, NULL, NULL, "test",4, x,rect.top, 0,0, DST_TEXT|DSS_DISABLED);
							GetTextExtentPoint32W(hdc, text, len, &sz);
							x += sz.cx;
						}

						//if (flags & AlfHorzLine) {
						//	RECT thin = {0,rect.top, rect.right,rect.top+1};
						//	FillRect(hdc, &thin, (HBRUSH)(COLOR_WINDOWTEXT+1));
						//}

						// print text
						pixels=NULL;
						if (text = ali->text) {
							text= GetChoiceText(text); // for check/group buttons
							len = lstrlenW(text);
							TextOutW(hdc, x,rect.top+CaretY, text,len);
							GetTextExtentPoint32W(hdc, text, len, &sz);
							x += sz.cx;

							if ((flags & AlfTypeMask) == AlfMenu) pixels = MenuPixels;
						}
						if ((flags & AlfTypeMask) == AlfToggle) pixels = (flags & AlfChecked) ? CheckedPixels : UncheckedPixels;

						// display little graphic
						if (pixels && !(flags & AlfNoCheckImage)) {
							// STUPID, STUPID, Windows!
							// Who is the retard that came up with this bass ackwards
							// BITMAP format? Every other gfx format in the world uses
							// sensible top down format.
							ItemBitmap.pal[0]=ReverseRGB(clrb);
							ItemBitmap.pal[1]=ReverseRGB(clrt);
							SetDIBitsToDevice(hdc, x+5, rect.top+((ItemHeight-7)>>1),
								8,7, 0,0, 0,7,
								pixels, (BITMAPINFO*)&ItemBitmap, DIB_RGB_COLORS);
							///err=GetLastError();
							///debugwrite("setdib=%d err=%d",ret,err);
							//CaretY = (ItemHeight-TextHeight)>>1;
							pixels=NULL; //reset for next loop
						}

					} else if (!secondpass) { //mark if needs redrawing next pass
						if (IntersectRect(&ir, &ur, &rect))
							ali->flags |= AlfRedraw;
					}

					// move current row down one
					rect.top    += ItemHeight;
					rect.bottom += ItemHeight;
				}
			}
			if (secondpass) break;
			secondpass=TRUE;
			SelectClipRgn(hdc, urgn); //clip to update region
		} //end two passes

		rect.bottom = 4096;
		//FillRect(hdc, &rect, (HBRUSH)(COLOR_WINDOW+1));
		SetBkColor(hdc, clrub);
		ExtTextOutW(hdc, 0,0, ETO_OPAQUE, &rect, NULL,0, NULL);
		SelectClipRgn(hdc, NULL); //no clip region
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
				////flags = al->al[HoverItem].flags;
				switch (flags & AlfTypeMask) {
				case AlfButton:
				case AlfToggle:
				case AlfMenu:
					SetCursor(CursorHand);
					break;
				case AlfEdit:
					if (x >= HoverRect.left) {
						SetCursor(CursorIbeam);
						break;
					}
					// fall through
				default: // else probably separator
					SetCursor(CursorArrow);
					break;
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

		/****{ /// just for fun
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
		}*/

		// select choice and set caret or activate choice
		if (GetHoverRect(y) >= 0) {
			////flags = al->al[HoverItem].flags;
			if (!(flags & (AlfDisabled|AlfHidden))) {
				switch (flags & AlfTypeMask) {
				case AlfEdit:
					SetFocus(hwnd); focus=FALSE;
					// preset focus or else I have problems putting
					// the caret where it should not be.
					SelectGiven(HoverItem, (x < HoverRect.left) ? 2:0 );
					if (x >= HoverRect.left) {

						// 20030912 now works for Japanese fonts without needing to
						// set the character set to Japanese. Does NOT work with backwards
						// texts like Hebrew since MS makes it too stinking difficult.
						// Oh well, guess the Arabic people will just have to suffer.

						static int caret[257];
						LPWSTR text = al->al[selected].text;
						int len, idx, pos=0, dif, width=32767;
						unsigned int charval;
						SIZE sz;

						hdc=GetDC(self);
						SelectObject(hdc, GuiFont);
						x -= HoverRect.left;

						if (unicode) {
							// NT only, does not work on 9x
							len=lstrlenW(text)+1;
							if (len>256) len=256;
							GetTextExtentExPointW(hdc, text,len, 0,NULL, &caret[1],&sz);
							caret[0]=0;
							for (idx=0; idx<len; idx++) {
								dif = x-caret[idx]; //get pixel difference
								///debugwrite("i%03d c%03d d%d p%d", idx, caret[idx], dif, pos);
								if (dif<0) dif = -dif;
								if (dif < width) {
									width = dif;
									pos = idx;
								}
							}
						} else {
							// 9x only, does not sum right on NT
							// determine nearest midcharacter position clicked
							while (charval = text[pos]) {
								GetCharWidthW(hdc, charval,charval, &width);
								//debugwrite("char char=%d width=%d", charval, width);
								if (width >= x) break;
								x -= width;
								pos++;
							}
							if (x > width>>1) pos++;
						}
						SetCaretX(pos);
					}
					break;
				case AlfButton:
					// only select push button if clicked off to side
					if (x > HoverRect.right) {
						SelectGiven(HoverItem,0);
					}else {
						focus=FALSE; // do not set focus is clicked on button
						SendClickCommand(flags);
					}
					break;
				case AlfMenu:
					SelectGiven(HoverItem,0);
					if (x >= HoverRect.left && x < HoverRect.right)
						ShowSelectedChoiceMenu();
					break;
				case AlfToggle:
					if (HoverItem == al->selected && GetFocus()==hwnd) goto MouseToggleButton;
					SelectGiven(HoverItem,0);
					if (x >= HoverRect.left && x < HoverRect.right) {
					MouseToggleButton:
						flags ^= AlfChecked;
						SetSelectedButtonValue(flags);
					}
					break;
				default:
					SelectGiven(HoverItem,0);
				}
			}
			// if not button
		}
		if (focus) SetFocus(hwnd); // set focus if clicked on disabled, title, separator
		return 0;
	}
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
		imehwnd=FindWindow("msime95main", NULL);
		//ShowWindow(imehwnd, SW_SHOW);
		//imehwnd=CreateWindow("msime95main", "msime95main", WS_VISIBLE, 200,200, 100,100, self, 0, ProgMemBase, NULL);
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
	case WM_MOUSEACTIVATE:
		return MA_NOACTIVATE;
		//SetFocus(hwnd);
	case WM_RBUTTONUP:
		return TRUE;
	case WM_RBUTTONDOWN:
		SelectGiven(GetHoverRect(lParam >> 16), 2);
		debugwrite("gethoverrect=%d item=%d",GetHoverRect(lParam >> 16),item);
		ShowContextMenu(HoverItem, lParam & 0xFFFF, lParam >> 16);
		return 0;
	case WM_CONTEXTMENU:
		if (!GetSelectedFlags()) return 0; //safety just in case
		GetItemRect(selected, 0); //show menu just below selected row
		ShowContextMenu(selected, rect.left,rect.bottom);
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
			if (GetSelectedFlags() && (flags & (AlfTypeMask|AlfDisabled|AlfHidden))==AlfMenu) {
				wParam &= 255;
				if ((unsigned)wParam < TotalChoices(al->al[selected].text))
					SetSelectedButtonValue((flags & ~AlfCheckedMask) | (wParam<<AlfCheckedRs));
			}
		} else if ((wParam & 0xFFFF) >= IDAL_MAX) { // special parent msg
			debugwrite("al cmd custom");
			return SendMessage(GetParent(hwnd),WM_COMMAND, wParam,lParam);
		} else { // context menu sent message
			switch (wParam & 0xFFFF) {
			case IDAL_COPY: goto CopyText;
			case IDAL_PASTE: goto PasteText;
			case IDAL_CLEAR: goto ClearText;
			case IDAL_COPYALL: goto CopyAllText;
			case IDAL_TOGGLE: 
				if (GetSelectedFlags() && (flags & (AlfTypeMask|AlfDisabled|AlfHidden))==AlfToggle)
					SetSelectedButtonValue(flags^AlfChecked);
				return 0;
			case IDAL_COMMAND:
				if (GetSelectedFlags() && (flags & (AlfTypeMask|AlfDisabled|AlfHidden))==AlfButton)
					SendClickCommand(flags);
				return 0;
			case IDAL_HELP:
				lParam = (long)&HelpInfo; //set helpinfo ptr
				HelpInfo.hItemHandle = hwnd; //set source to self
				HelpInfo.iCtrlId = GetDlgCtrlID(hwnd);
				HelpInfo.iContextType = HELPINFO_WINDOW;
				item = al->selected;
				goto SendHelpToParent;
			}
		}
		return 0;
	case WM_COPY:
		if (wParam==-1) goto CopyAllText; // special case message to copy all
	CopyText:
		if (!GetSelectedFlags()) return -1; // just in case no choices
		if (OpenClipboard(hwnd)) {
			HGLOBAL hmut=0,hmat=0;
			LPWSTR text,dest;

			EmptyClipboard();
			if ((hmut = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE,512))
			&&  (hmat = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE,256)) ) { // if mem alloced
				text = GetChoiceText(al->al[selected].text);
				if (!text) text=al->al[selected].label;
				if (text) { // if item actually has text
					dest=GlobalLock(hmut);
					 RtlMoveMemory(dest, text, 512);
					 GlobalUnlock(hmut);
					 SetClipboardData(CF_UNICODETEXT,hmut);
					dest=GlobalLock(hmat);
					 WideCharToMultiByte(CP_ACP, 0, text,-1, (LPSTR)dest, 256, NULL,NULL);
					 GlobalUnlock(hmat);
					 SetClipboardData(CF_TEXT,hmat);
				} else {
					GlobalFree(hmut);
					GlobalFree(hmat);
				}
			}
			CloseClipboard();
		}
		return 0;
	CopyAllText:
		if (OpenClipboard(hwnd)) {
			HGLOBAL hmut=0,hmat=0;
			LPWSTR label,text;
			int item=al->total,size=0;

			EmptyClipboard();
			if (hmut = GlobalLock(GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE,2048)) ) { // if mem alloced
				// build Unicode version of text chunk by
				// iteraing through all items and appending its text
				debugwrite("copying Unicode hmut=%X before",hmut);
				//*(short*)hmut='U';
				ali = &(al->al[0]);
				for (; (signed)item>0; item--,ali++) {
					flags = ali->flags;
					if (!(flags & (AlfDisabled|AlfHidden)) // only add if visible and
					&& (text = ali->text)) {				// has text
						label = ali->label;
						AppendString(&hmut,label,&size);
						AppendString(&hmut,GetChoiceText(text),&size);
						AppendString(&hmut,L"\r\n",&size);
					}
				}
				///*(short*)hmut='U';
				// build ANSI version of text chunk
				size=GlobalSize(GlobalHandle(hmut));
				if (size && (hmat = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE,size)) ) {
					LPSTR dest=GlobalLock(hmat);
					debugwrite("copying ANSI hmat=%X dest=%X",hmat,dest);
					WideCharToMultiByte(CP_ACP, 0, hmut,-1, dest, size, NULL,NULL);
					///*dest='A';
					GlobalUnlock(hmat);
					SetClipboardData(CF_TEXT,hmat);
				}
				debugwrite("hmut=%X after building",hmut);
				GlobalUnlock( hmut=GlobalHandle(hmut) );
				debugwrite("hmut=%X final before setting",hmut);
				hmut=SetClipboardData(CF_UNICODETEXT,hmut);
				debugwrite("setcp=%X err=%d",hmut,GetLastError());
			}
			CloseClipboard();				
		}
		return 0;
	case WM_PASTE:
	PasteText:
		if (!GetSelectedFlags()) return -1; // just in case no choices
		if ((flags & (AlfTypeMask|AlfDisabled|AlfHidden))==AlfEdit // ensure IS edit, not disabled, hidden, or locked
		&& (flags & AlfLengthMask) // ensure edit allows at least one character in buffer
		&& OpenClipboard(hwnd)) {
			HGLOBAL hmut; //memory handle to Unicode text
			LPWSTR src,text;
			unsigned int len; //string length
			unsigned int format=GetPriorityClipboardFormat(&ClipboardFormats[0],2);

			#ifdef MYDEBUG
			format=0;
			do {
				format=EnumClipboardFormats(format);
				debugwrite("cf=%d %Xh",format,format);
			} while (format);
			format=GetPriorityClipboardFormat(&ClipboardFormats[0],2);
			#endif
			
			debugwrite("paste format=%d",format);
			if ((text = al->al[selected].text)
			&& (hmut = GetClipboardData(format))
			&& (src=GlobalLock(hmut)) ) {				
				if (format==CF_UNICODETEXT) {
					debugwrite("paste unicode=%S",src);
					len = lstrlenW(src);
					if (len > (flags>>AlfLengthRs)) len = flags>>AlfLengthRs;
					*(text+len)=0; // append null
					debugwrite("paste unicode len=%d",len);
					RtlMoveMemory(text, src, len<<1); //*2 for Unicode					
				} else {
					debugwrite("paste ansi=%s",src);
					*(text+(flags>>AlfLengthRs))=0; // append null in case MBTWC function fails because text pasted is larger than buffer
					len=MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, (LPSTR)src,-1, text, flags>>AlfLengthRs);
					debugwrite("paste ansi len=%d",len);
				}

				GlobalUnlock(hmut);
				ResizeOverlay();
				SetCaretX(-1);
			};
			CloseClipboard();				
		}
		return 0;
	case WM_CLEAR:
	ClearText:
		if (!GetSelectedFlags()) return -1; // just in case no choices
		if ((flags & (AlfTypeMask|AlfDisabled|AlfHidden))==AlfEdit
		&& (flags & AlfLengthMask)) {
			LPWSTR text;
			if (text = al->al[selected].text) {
				*text='\0'; // truncate string to zero length
				ResizeOverlay();
				SetCaretX(0);
			}
		}
		return 0;
	case WM_MOUSEWHEEL:
		debugwrite("mouse wheel w=%X l=%X", wParam, lParam);
		ScrollBy((wParam & 0x80000000) ? 1 : -1, 0);
		return TRUE;
	case WM_VSCROLL:
	{
		int dif, options=0;
		GetItemMetrics();
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
		if (GetSelectedFlags())
			if ((flags & AlfTypeMask)==AlfButton)
				return DLGC_WANTCHARS|DLGC_WANTARROWS|DLGC_WANTALLKEYS;
		return DLGC_WANTARROWS|DLGC_WANTCHARS;

	case WM_KEYDOWN:
		// generic keys for all types
		switch (wParam) {
		//case VK_APPS: (should not be necessary because of WM_CONTEXTMENU msg)
		//	goto ShowMenuViaKey;
		case VK_DOWN:
		case VK_UP:
			Select(Seek(selected, (wParam == VK_DOWN) ? 1:-1, AlfHidden|AlfDisabled));
			break;
		case VK_NEXT:
		case VK_PRIOR:	ScrollBy((wParam == VK_NEXT) ? 1:-1, 1);
			break;

		case VK_INSERT:
			if (GetKeyState(VK_CONTROL)&0x80) goto CopyText; // Ctrl+Ins to copy

		case VK_TAB:
			SendMessage(GetParent(hwnd), WM_NEXTDLGCTL, GetKeyState(VK_SHIFT)&0x80, 0);
			break;

		// specific keys for individual types
		default:
			// a disabled item or separator should never be selected, but just in case
			// some program code has changed things behind this code's back
			if (!GetSelectedFlags() || (flags & (AlfDisabled|AlfHidden))) return 0;

			switch (flags & AlfTypeMask) {
			case AlfEdit:
				///if (flags & AlfLocked) break; // catch, don't edit the uneditable

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
				case VK_DELETE:
					DeleteChar();
					break;
				case VK_BACK:
					if (CaretX > 0) {
						SetCaretX(CaretX-1);
						DeleteChar();
					}
					break;
				case VK_INSERT:
					if (GetKeyState(VK_SHIFT)&0x80) goto PasteText; // Shift+Ins to paste
				}
				break;
			case AlfToggle:
				if (lParam & (1<<30)) break; // catch, ignore repeated keypresses

				switch (wParam) {
				case VK_LEFT:
					if (!(flags & AlfChecked)) break;
					flags &= ~AlfChecked;
					goto SetToggle;
				case VK_RIGHT:
					if (flags & AlfChecked) break;
					flags |= AlfChecked;
					goto SetToggle;
				case VK_SPACE:
				case VK_RETURN:
					flags ^= AlfChecked; // toggle check state
				SetToggle:
					SetSelectedButtonValue(flags);
				}
				break;
			case AlfMenu:
				//if (lParam & (1<<30)) break; // catch, ignore repeated keypresses

				switch (wParam) {
				case VK_SPACE:
				case VK_RETURN:
				{
					MSG msg; // solely to remove the extra space character that makes the ding
					PeekMessage(&msg, 0,WM_KEYFIRST,WM_KEYLAST,PM_REMOVE);
					ShowSelectedChoiceMenu();
					break;
				}
				case VK_END: // set to last, right-most choice
					flags &= ~AlfCheckedMask;
					flags |= TotalChoices(al->al[selected].text) << AlfCheckedRs;
					goto SetMenuLeft;
				case VK_HOME: // set to first, left-most choice
					flags &= ~AlfCheckedMask;
					goto SetMenu;
				case VK_RIGHT:
					if ((flags >> AlfCheckedRs)+1
						>= TotalChoices(al->al[selected].text)) break;
					flags += 1<<AlfCheckedRs;
					goto SetMenu;
				case VK_LEFT:
				SetMenuLeft:
					if (!(flags & AlfCheckedMask)) break; // catch, if already zero
					flags -= 1<<AlfCheckedRs;
					//goto SetMenu;
				SetMenu:
					SetSelectedButtonValue(flags);
				}
			case AlfButton:
				if (wParam == VK_SPACE || wParam == VK_RETURN)
					SendClickCommand(flags);
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
		if (GetSelectedFlags()
		&& (flags & (AlfTypeMask|AlfDisabled|AlfHidden)) == AlfEdit) { // if IS edit, and not disabled, hidden, or locked
			if (wParam >= 32) {
				if (!(flags & AlfNumeric) || ((wParam >= '0' && wParam <= '9') || wParam == '.'))
					InsertChar(wParam);
			}
		}
		return 0;
	case WM_KILLFOCUS:
	case WM_SETFOCUS:
		//debugwrite("al gf=%X self=%X msg=%d", GetFocus(),self,message);
		ResizeOverlay();
		if (GetSelectedFlags()) {
			al->al[selected].flags |= AlfRedraw;
			if (message==WM_SETFOCUS) SetCaretX(-1);
		}
		RedrawTitles();
		PostRedraw();
		return 0;

	case LB_SETCURSEL:
		return Select(wParam);

	//case BM_SETSEL:
	//case LB_SETSEL:
	//	return SetSelectedButtonValue(wParam);
	case BM_CLICK:
		//if (!GetGivenFlags(lParam) || (flags & (AlfDisabled|AlfHidden))) return 0;
		if (!GetSelectedFlags() || (flags & (AlfDisabled|AlfHidden))) return 0;

		switch (flags & AlfTypeMask) {
		case AlfToggle:
			flags ^= AlfChecked; // toggle check state
			SetSelectedButtonValue(flags);
			break;
		case AlfMenu:
			if (lParam)
				ShowGivenChoiceMenu(selected,
					(int)(signed short)lParam,
					(signed)lParam >> 16);
			else
				ShowSelectedChoiceMenu();
			break;
		case AlfButton:
			SendClickCommand(flags);
			break;
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
		GetWindowRect(hwnd, &rect);
		if (((WINDOWPOS*)lParam)->cx != (rect.right-rect.left)) {
			RedrawTitles();
			PostRedraw();
		}
		return 0;

	case WM_HELP:
		//((LPHELPINFO)lParam)->iContextType = HELPINFO_WINDOW;
		//((LPHELPINFO)lParam)->hItemHandle, //already correct
		//((LPHELPINFO)lParam)->MousePos.x,
		//((LPHELPINFO)lParam)->MousePos.y);

		// calculate hovered item
		// if valid item
		//al->top

		if (GetKeyState(VK_F1) & 0x80) {
			item = al->selected;
		} else {
			rect.top  = ((LPHELPINFO)lParam)->MousePos.y;
			rect.left = ((LPHELPINFO)lParam)->MousePos.x;
			ScreenToClient(hwnd, (POINT*)&rect);
			///debugwrite("alhelp x=%d y=%d", rect.left,rect.top);
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
			|| item != al->selected) {
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
			ImmGetCompositionStringW(context, GCS_RESULTSTR, chars, sizeof(chars));
			debugwrite("stringW=%S", chars);
			//ImmGetCompositionStringW(context, GCS_RESULTSTR, chars, sizeof(chars));
			//ImmReleaseContext(hwnd,context);
			ImmReleaseContext(hwnd,context);
			//ImmDestroyContext(context);
			}
		}
        return DefWindowProcW(hwnd, message, wParam, lParam);
	case WM_IME_KEYDOWN:
		debugwrite("ime keydown");
        return DefWindowProc(hwnd, message, wParam, lParam);
	case WM_IME_CHAR:
		debugwrite("ime char w=%d l=%d", wParam, lParam);
        return DefWindowProcW(hwnd, message, wParam, lParam);
*/

	case WM_DESTROY:
		DestroyWindow( (HWND)GetWindowLong(self,GWL_OVERLAY) );
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
int __stdcall AtrOverlayProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	switch (message) {
	case WM_CREATE:
		//CurIbeam=LoadCursor(0,IDC_IBEAM);
		SetClassLong(hwnd, GCL_HCURSOR, (long)CursorIbeam);
		SetWindowLong(hwnd, GWL_USERDATA, (long)&DefaultAl); //to prevent crashes
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
		LPWSTR text = (LPWSTR)GetWindowLong(hwnd, GWL_USERDATA);
		PAINTSTRUCT ps;

		BeginPaint(hwnd, &ps);
		///ValidateRect(hwnd, NULL);
		SelectObject(ps.hdc, GuiFont);
		SetBkColor(ps.hdc, GetSysColor(COLOR_HIGHLIGHT)); //COLOR_BTNFACE
		SetTextColor(ps.hdc, GetSysColor(COLOR_HIGHLIGHTTEXT));
		GetClientRect(hwnd, &rect);
		ExtTextOutW(ps.hdc, 0,CaretY, ETO_OPAQUE, &rect, text,lstrlenW(text), NULL);
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
		rect.left=(int)(signed short)lParam;
		rect.top =(signed)lParam>>16;
		ScreenToClient(owner, (LPPOINT)&rect);
		lParam = (rect.left & 0xFFFF) | (rect.top<<16);
		return AtrListProc(owner, message,wParam,lParam);
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
		return AtrListProc((HWND)GetWindowLong(hwnd,GWL_OWNER), message,wParam,lParam);
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
//		Default flagmask is (AlfHidden|AlfSeparator|AlfDisabled)
//		Bit 1 set is a special flag meaning to return -1 if not reached
// !assumes:
//		al points to the current attribute list
// returns:
//		new item number
//		[item]
//		[traveled]
static int __stdcall Seek(unsigned int from, int distance, int flagmask)
{
	unsigned int skipflags=flagmask & ~AlfIdMask;
	unsigned int total=al->total;
	if (from > total) from=total;
	ali = &(al->al[from]);
	item=from;
	traveled=distance;

	if (traveled > 0)
		while (++from < total)
		{
			ali++;
			if (!(ali->flags & AlfHidden)) {
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
			if (!(ali->flags & AlfHidden)) {
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
//			  pass al->top if for relative to top of list
//
// !assumes:
//		al points to the current attribute list
// returns:
//		zero based position (in rows, not pixels)
//		[traveled]
static int __stdcall GetItemRow(unsigned int item, unsigned int top) {
	unsigned int total=al->total;
	if (item > total) item=total;
	if (top > total) top=total;
	ali = &(al->al[item]);
	traveled=0;

	if (item >= top)
		while ((signed)--item >= 0 && item >= top) {
			ali--;
			if (!(ali->flags & AlfHidden)) traveled++;
		}
	else
		while ((signed)item++ < (signed)top) {
			if (!(ali->flags & AlfHidden)) traveled--;
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
//		self is current window
static void __stdcall Resize()
{
	int style = GetWindowLong(self, GWL_STYLE), // get initial style
		top = al->top;

	GetItemMetrics();

	// scroll items if necessary
	if ( Seek(al->total,-ItemRows, AlfHidden) < top) {
		al->top = item;
		Scroll(GetItemRow(top, item)); // dif between old and new top
	} else {
		ResizeOverlay();
	}

	// set scroll bar visibility
	// if all item rows (excluding hidden) are taller than
	// than window client area, show scroll bar.
	SetScrollBars();

	// if scroll bar visibility changed, either from visible to hidden vice versa,
	// then redraw all titles, since their edges depend on the width of the client
	if ((style ^ GetWindowLong(self, GWL_STYLE)) & WS_VSCROLL) {
		RedrawTitles();
		PostRedraw();
	}
}

// purpose:
//		sizes and positions overlay window according to selected item
//		hides if offscreen, lost focus, or item is not displayable
// !assumes:
//		al points to the attribute list structure
//		self is current window
static int __stdcall ResizeOverlay()
{
	LPWSTR text;
	SIZE sz; //height/width of overlay
	POINT pt = {2,0}; // top/left of overlay
	RECT arect = {0,0,0,0};
	HWND hedit = (HWND)GetWindowLong(self,GWL_OVERLAY);

	// only show overlayif current selected item is valid, if it has text,
	// and if the attribute list has focus (otherwise it would show when created)
	if (hedit != NULL
	  && GetSelectedFlags()
	  && GetFocus()==self
	  && (text=al->al[selected].text))
	{
		GetItemMetrics();

		// calc top and left to be directly over item
		ali = &(al->al[selected]);
		//text = ali->text;
		///debugwrite("sel=%d ali=%x lbl=%x", selected, ali, ali->label);
		if (ali->icon) pt.x=(IconWidth+2+2);
		if (ali->label) {
			GetTextExtentPoint32W(hdc, ali->label, lstrlenW(ali->label), &sz);
			pt.x+=sz.cx;
		}
		pt.y=GetItemRow(selected, al->top) * ItemHeight;
		if (pt.x > rect.right) pt.x=rect.right; // so that it does not appear floating off to the right side

		// special exception to hide overlay when item scrolled off screen
		if (pt.y < 0 || pt.y >= rect.bottom) {
			ShowWindow(hedit, SW_HIDE);
			return FALSE;
		}

		// calc window size based on text length
		text=GetChoiceText(text); // for check/group buttons
		GetTextExtentPoint32W(hdc, text, lstrlenW(text), &sz);
		sz.cx+=2;
		sz.cy=ItemHeight;
		CaretY = (ItemHeight-TextHeight)>>1;

		// keep overlay on screen and in work area
		SystemParametersInfo(SPI_GETWORKAREA,0, &rect, FALSE);
		///debugwrite("wa l=%d r=%d t=%d b=%d", rect.left,rect.right,rect.top,rect.bottom);
		ClientToScreen(self, &pt);
		if (pt.x > rect.right-sz.cx)	pt.x = rect.right-sz.cx;
		if (pt.x < rect.left)			pt.x = rect.left;
		if (pt.y > rect.bottom-sz.cy)	pt.y = rect.bottom-sz.cy;
		if (pt.y < rect.top)			pt.y = rect.top;

		// adjust pos/size if overlay has an nonclient edge
		AdjustWindowRectEx(&arect, GetWindowLong(hedit,GWL_STYLE), FALSE, GetWindowLong(hedit,GWL_EXSTYLE));
		pt.x += arect.left;
		pt.y += arect.top;
		sz.cx += arect.right-arect.left;
		sz.cy += arect.bottom-arect.top;

		// only show caret if IS edit and not locked
		if ((flags & AlfTypeMask)==AlfEdit) {
			CreateCaret(hedit,NULL,2,ItemHeight);
			ShowCaret(hedit); // GetSystemMetrics(SM_CXBORDER) is too thin a caret
		} else {
			DestroyCaret();
		}

		// position and size overlay, show if hidden
		SetWindowPos(hedit,NULL, pt.x,pt.y, sz.cx,sz.cy, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER);
		//SetWindowText(hedit, (LPTSTR)text);
		SetWindowLong(hedit, GWL_USERDATA, (long)text);
		//SetWindowLong(hedit,GWL_ID, al->al[selected].flags & AlfIdMask);
		SetWindowPos(hedit, NULL, 0,0,0,0, SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_NOACTIVATE|SWP_SHOWWINDOW);
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
static int __stdcall Select(unsigned int newitem)
{
	return SelectGiven(newitem, 1|2); // ensure visible and set caret x
}

// purpose:
//		selects the given item.
// !assumes:
//		al points to the current attribute list
// returns:
//		LB_OKAY or LB_ERR
//		[selected]
//		[flags]
//
// options:
//		1 - ensure selection is visible, scroll if not
//		2 - set caret to end of edit text (if item is edit)
static int __stdcall SelectGiven(unsigned int newitem, unsigned int options)
{
	// convert ID to position
	newitem = IdToItem(newitem);

	// check selection validity
	selected=al->selected;
	if (newitem >= al->total
	|| (flags=al->al[newitem].flags) & (AlfDisabled|AlfHidden))
		return LB_ERR;
	if (newitem==selected) return LB_OKAY;

	// set redraw flags of new selection
	if (selected < al->total) al->al[selected].flags |= AlfRedraw;
	al->al[newitem].flags |= AlfRedraw;
	al->selected = selected = newitem;

	// ensure selection is visible if option set
	// scroll into view if not
	if (options & 1) {
		unsigned int OldTop=al->top, NewTop=OldTop;
		GetItemMetrics();
		if (selected < OldTop) {
			NewTop=selected;
		} else {
			Seek(selected,1-ItemRows, AlfHidden);
			if (item > OldTop) NewTop=item;
		}
		if (NewTop != OldTop) {
			al->top = NewTop;
			Scroll(-GetItemRow(NewTop, OldTop));
		}
	}

	ResizeOverlay();
	if ((flags & AlfTypeMask)==AlfEdit && (options & 2)) SetCaretX(-1);

	PostRedraw();
	return LB_OKAY;
}

// purpose:
//		Sets caret position for text editing.
//		Puts caret at end of text if -1 passed.
// !assumes:
//		al points to the current attribute list
//		self the current window handle
//		selected is valid (GetSelectedFlags has been called)
//
static void __stdcall SetCaretX(unsigned int newx)
{
	HDC hdc = GetDC(self);
	SIZE sz = {0,0};
	LPWSTR text = al->al[selected].text;
	static int caret[258];
	unsigned int len;
	
	if (!text) return; // prevent access violation in case item has only a label
	len=lstrlenW(text);
	if (len>256) len=256; // safety for practical limit

	if (newx >= len)	newx = len; //force caret pos valid
	else				if (newx == CaretX) return; //caret pos same, so do nothing more
	CaretX=newx;

	caret[CaretX]=0;
	if (CaretX > 0) {
		/*short reorder[256];
		GCP_RESULTSW gcp = {
			sizeof(GCP_RESULTS),
			&reorder[0], NULL, NULL, NULL,
			NULL,
			NULL,0,
			0
		};*/
		SelectObject(hdc,GuiFont);
		// Would use the gcp function below so that caret positioning would be
		// "correct" on Hebrew and other Arabic backwards reading languages,
		// but sadly the function doesn't work
		//GetCharacterPlacementW(hdc, text, len,0, &gcp, GCP_REORDER); // | GCP_GLYPHSHAPE
		//sz.cx = CaretPos[CaretX];
		// passing 0 length string to extent function sometimes
		// causes a GPF in GDI for some retarded reason
		// likely an MS bug, because it only happens on some platforms
		//GetCharacterPlacementW(hdc, text, len,0, &gcp, GCP_REORDER); // | GCP_GLYPHSHAPE

		if (unicode) {
			// NT only, does not work on 9x
			GetTextExtentExPointW(hdc, text,len+1, 0,NULL, &caret[1],&sz); //NT
			SetCaretPos(caret[CaretX],0); //NT
			///debugwrite("caret=%d %d %d %d", caret[0], caret[1], caret[2], caret[3]);
		} else {
			// 9x only, does not work right on NT/XP (when combing multiple fonts)
			GetTextExtentPoint32W(hdc, text, CaretX, &sz);
			SetCaretPos(sz.cx,0);
		}
	} else {
		SetCaretPos(0,0);
	}
	
	//al->al[selected].flags |= AlfRedraw;
	//PostRedraw();
	//PostRedrawOverlay();
}

// purpose:
//		Deletes a single character.
// !assumes al points to the current attribute list
//		self the current window handle
//		selected is the currently selected choice
//		flags is the flags of the selected choice
static void __stdcall DeleteChar()
{
	//selected=al->selected;
	//flags=al->al[selected].flags;
	LPWSTR text = al->al[selected].text + CaretX;
	if (!text || !(flags & AlfLengthMask)) return; // error if text ptr NULL or no length
	//memmove(text, text+1, lstrlen(text));
	RtlMoveMemory( (char *)text, (const char *)(text+1), (lstrlenW(text)+1)<<1);
	//al->al[selected].flags |= AlfRedraw;
	//PostRedraw();
	//PostRedrawOverlay();
	ResizeOverlay();
}

// !assumes al points to the current attribute list
//          self the current window handle
//          selected is the currently selected choice
//          flags is the flags of the selected choice
//
// Inserts a character into the string at the caret position.
static void __stdcall InsertChar(unsigned int newchar)
{
	LPWSTR text = al->al[selected].text;
	unsigned int len=lstrlenW(text);

	if (CaretX > len) {CaretX=len;     return;}
	if (len >= (flags >> AlfLengthRs)) return;

	text+=CaretX;
	RtlMoveMemory(text+1, text, (len-CaretX+1)<<1);
	*(text)=newchar;
	SetCaretX(CaretX+1);

	///al->al[selected].flags |= AlfRedraw;
	///PostRedraw();
	ResizeOverlay();
}

// !assumes self the current window handle
static void __stdcall PostRedraw()
{
 	PostMessage(self, WM_PAINT, 0,0);
}

static void __stdcall PostRedrawOverlay()
{
 	//PostMessage(GetWindowLong(self,GWL_OVERLAY), WM_PAINT, 0,0);
	InvalidateRect((HWND)GetWindowLong(self,GWL_OVERLAY), NULL, FALSE);
}

// !assumes al points to the current attribute list
//
// Gets the item flags of the selected item.
static int __stdcall GetSelectedFlags()
{
	selected=al->selected;
	if (selected >= al->total) {
		flags=AlfDisabled|AlfHidden;		
		return FALSE; //safety just in case
	}
	flags=al->al[selected].flags;
	return TRUE;
}

// !assumes al points to the current attribute list
//
// Gets the item flags of the given item.
static int __stdcall GetGivenFlags(unsigned int item)
{
	item=al->selected;
	if (item >= al->total) {
		flags=AlfDisabled|AlfHidden;		
		return FALSE; //safety just in case
	}
	flags=al->al[item].flags;
	return TRUE;
}

// purpose:
//		Sets the coordinates for the hover rectangle which the cursor
//		moves over.
// !assumes:
//		al points to the current attribute list
//		self is the current window handle
// returns:
//		the item hovered over (-1 if none)
//		[flags] of hovered item (if over valid item)
//		[HoverRect] sets the rectangular coordinates
//		[HoverItem]
static int __stdcall GetHoverRect(int y)
{
	//if (HoverItem > al->total); else
	if (self != HoverHwnd || y < HoverRect.top || y >= HoverRect.bottom) {
		HoverHwnd = self;
		HoverItem = GetItemRect(-1, y);
		///debugwrite("getitemrect=%d",HoverItem);
		HoverRect.left   = rect.left;
		HoverRect.top    = rect.top;
		HoverRect.right  = rect.right;
		HoverRect.bottom = rect.bottom;
	} else if ((signed)HoverItem >= 0) { // within same rectangle as last call
		flags = al->al[HoverItem].flags;
	}
	//debugwrite("hwnd=%X rt=%d rb=%d rl=%d", self, HoverRect.top, HoverRect.bottom, HoverRect.left);
	return HoverItem;
}

// purpose:
//		Calculates the rectangle surrounding an item
//		either by item number or y coordinate.
// !assumes:
//		al points to the current attribute list
//		self is the current window handle
// returns:
//		the item hovered over (-1 if none)
//		if the item is beyond the total, it returns  the bottom of the list
//		and sets the rectangular coordinates in rect
//		[flags] of item (if over valid item)
static int __stdcall GetItemRect(unsigned int item, int y) {
	SIZE sz;
	LPWSTR text;
	unsigned int len;

	if ((signed)al->total <= 0) {
		GetWindowRect(self,&rect);
		return LB_ERR; //-1
	}

	// get list item height, using current font
	GetItemMetrics();

	// determine top coordinate from item row
	// or item and top from mouse coordinate
	if ((signed)item >= 0) {	// have item so figure y
		rect.top = GetItemRow(item,al->top) * ItemHeight;
	} else {					// have y so figure item
		item = Seek(al->top, y/ItemHeight, 1);
		///debugwrite("getitemrectseek=%d",item);
		rect.top = y - (y % ItemHeight);
	}
	rect.left = 2;
	///debugwrite("atrlist gir item=%d y=%d",item,y);

	if ((signed)item >= 0 && item < al->total) { // over valid item
		rect.bottom = rect.top + ItemHeight;
		ali = &(al->al[item]);
		if (ali->icon) rect.left+=16+2;
		if (text = ali->label) {
			len=lstrlenW(text);
			GetTextExtentPoint32W(hdc, text, len, &sz);
			rect.left += sz.cx;
		}
		sz.cx=0; // in case there is no text
		flags = ali->flags;
		if (text = ali->text) {
			text=GetChoiceText(text); // for check/group buttons
			len=lstrlenW(text);
			GetTextExtentPoint32W(hdc, text, len, &sz);
		}
		rect.right = rect.left + sz.cx;
	} else { // beyond end of list
		rect.right = 0;
		rect.bottom = 4096; //set to ridiculously high number
	}
	return item;
}


// purpose
//		Converts an ID to an item position. If item does not
//		have AttribListById set, it returns the item unchanged.
//		If the given ID was not found, -1 will be returned.
// !assumes
//		al points to the current attribute list
//		self is the current window handle
static int __stdcall IdToItem(unsigned int id) {
	unsigned int item; // = id;
	unsigned int total;

	if (id & AttribListById) {
		total=al->total;
		id &= AlfIdMask;
		for (item = 0, ali = &(al->al[0]);
			 item < total;
			 item++, ali++)
		{
			if ((ali->flags & AlfIdMask) == id)
				return item;
		}
		id = LB_ERR;
	}
	return id;
}


// purpose
//		Sends command message to parent, for when button clicked.
//		A message will only be sent if the button has an ID.
// !assumes
//		al points to the current attribute list
//		self is the current window handle
static void __stdcall SendClickCommand(unsigned int flags)
{
	if (flags & AlfIdMask)
		SendMessage(GetParent(self),
			WM_COMMAND,
			(flags & AlfIdMask)|ALN_CLICKED,
			(LPARAM)self);
}

// purpose:
//		Redraws all title 
//		either by item number or y coordinate.
// !assumes:
//		al points to the current attribute list
static void __stdcall RedrawTitles()
{
	for (item=al->top, ali = &(al->al[item]); item < al->total; item++, ali++)
		if ((ali->flags & AlfTypeMask) == AlfTitle)
			ali->flags |= AlfRedraw;
}

// purpose:
//		get list item's height
//		font height
//		and image list icon's size
// !assumes:
//		al points to the current attribute list
//		self is current window
//		GuiFont is a valid font
// returns:
//		[ItemHeight] - pixel height of single item row
//		[TextHeight] - text cell height
//		[IconHeight] - image list icon height
//		[IconWidth] - icon width
//		[ItemRows] - number of visible whole rows
//		[rect] filled with client coordinates
static void __stdcall GetItemMetrics()
{
	TEXTMETRIC tm;

	GetClientRect(self, &rect);
	hdc=GetDC(self);
	SelectObject(hdc, GuiFont);
	GetTextMetrics(hdc, &tm);
	ImageList_GetIconSize(al->himl, &IconWidth,&IconHeight);
	TextHeight = tm.tmHeight;
	if (TextHeight < 4) TextHeight=4; //sanity check to prevent possible div by zero
	// set item height to the larger of icon or text
	ItemHeight = (IconHeight > TextHeight) ? IconHeight : TextHeight;
	ItemRows = rect.bottom / ItemHeight;
	///debugwrite("al h=%d a=%d d=%d", tm.tmHeight, tm.tmAscent, tm.tmDescent);
};

// purpose:
//		scrolls list by number of rows, and sets new top of list.
// !assumes:
//		al points to the current attribute list
//		self is current window
// options:
//		(bit flags can be combined)
//		1 - scroll by page height
//		2 - move selection in parallel
//		3*- scroll by page and move selection (pgup and pgdn use this)
//		4 - absolute
static void __stdcall ScrollBy(int dif, long options)
{
	unsigned int OldTop=al->top, NewTop;
	int TopDif;
	
	GetItemMetrics(); // calculates and sets multiple vars

	if (options & 4) {
		NewTop=Seek(0, dif, AlfHidden);
	} else {
		if (options & 1) dif*=ItemRows;
		NewTop=Seek(OldTop, dif, AlfHidden);
	}
	if (NewTop > OldTop) {
		Seek(al->total,-ItemRows, AlfHidden);
		if (NewTop > item) NewTop=item;
	}
	if (NewTop == OldTop) return;
	al->top = NewTop;

	TopDif = GetItemRow(NewTop, OldTop);
	//debugwrite("topdif = %d", TopDif);

	if (options & 1) {
		//Seek(al->selected, TopDif, AlfHidden);
		//Seek(item, (TopDif >= 0) ? -1:1, AlfHidden|AlfDisabled|AlfSeparator);
		//LanAtrs[*(LanListPtr+LanListSelect)].flags |= LlfRedraw;
		//LanListSelect+=NewTop-LanListTop;
		//LanAtrs[*(LanListPtr+LanListSelect)].flags |= LlfRedraw;
	}
	Scroll(-TopDif);
}


// purpose:
//		scrolls client area
// !assumes:
//		al points to the current attribute list
//		self is current window
//		item_height is set by a call to GetItemMetrics
//		text_height ...
//		icon_height	...
//		icon_width	...
static void __stdcall Scroll(int dif)
{
	//GetItemMetrics();
	//GetClientRect(self, &rect);
	HoverRect.bottom=0; // force mouse recalc upon next mouse move
	//ScrollWindow(self, 0,dif*ItemHeight, &rect,&rect);
	ScrollWindow(self,0,dif*ItemHeight, NULL,NULL);
	SetScrollBars();
	ResizeOverlay();
}

// purpose:
//		sets scroll bar range and position
// !assumes:
//		al points to the current attribute list
//		self is current window
//		item_height is set by a call to GetItemMetrics
//		text_height ...
//		icon_height	...
//		icon_width	...
static void __stdcall SetScrollBars()
{
	//GetItemMetrics();
	///debugwrite("r=%d p=%d j=%d", GetItemRow(al->total, 0)-1, GetItemRow(al->top,0), ItemRows);
	ScrollInfo.nMax=GetItemRow(al->total, 0)-1;
	ScrollInfo.nPage=ItemRows;
	ScrollInfo.nPos=GetItemRow(al->top,0);
	SetScrollInfo(self, SB_VERT, &ScrollInfo, TRUE);
}

// purpose:
//		selects the correct choice text of text for a toggle/menu/button.
//		it leaves the text ptr alone if other type.
//		for example, a toggle might show "yes" if checked, "no" if not.
// !assumes:
//		flags is the bitflags of the desired item (GetSelectedFlags called or similar)
// notes:
//		item type is validated.
static LPWSTR __stdcall GetChoiceText(short *text)
{
	if (text) {
		unsigned int value = (flags >> AlfCheckedRs);

		if (value) {
			switch (flags & AlfTypeMask) {
			case AlfButton:
			case AlfMenu:
			case AlfToggle:
				do {
					text += lstrlenW(text)+1; // skip ahead by size of string + NULL
				} while ((signed)(--value) > 0);
			}
		}
	}
	return text;
}

// purpose:
//		appends a Unicode string to a moveable memory object.
//		resizes it if necessary.
//		calculuates length of existing string if size NULL or -1 passed
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
static int AppendString(HGLOBAL *hmut, short *text, int *sizep)
{
	short *dest = *hmut; // get pointer to existing string
	unsigned int dsize = (sizep) ? *sizep:-1;
	unsigned int tsize = lstrlenW(text); // new text size
	unsigned int msize = GlobalSize(GlobalHandle((HGLOBAL)dest)); // max size of memory object

	///debugwrite("-@%08X %d text=%S",text,tsize,text);

	if (!dest) return 0; // null pointer so return 0 size
	if ((signed)dsize<0) dsize=lstrlenW(dest); // size of exisiting string

	///debugwrite(" @%08X %d/%d dest=%S",dest,dsize,msize,dest);

	if (dsize+tsize >= msize>>1) { // reallocate if necessary
		GlobalUnlock( dest=GlobalHandle(dest) ); // get handle from pointer and unlock (no effect if static)
		if (!(dest = GlobalReAlloc(dest,((dsize+tsize)<<1)+256,GMEM_MOVEABLE)) ) return dsize;
		*hmut = dest = GlobalLock(dest); // lock to get new pointer (no effect if static)
	}
	RtlMoveMemory(dest+dsize, text, (tsize+1)<<1);

	///debugwrite(" @%08X dest=%S",dest,dest);
	dsize+=tsize;
	if (sizep) *sizep=dsize;
	return dsize;
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
static void ShowContextMenu(unsigned int item, int x,int y)
{
	HMENU menu = CreatePopupMenu();
	debugwrite("al menuhnd=%X item=%d", menu,item);

	// dynamically create menu based on whatever is selected
	if (((signed)item >= 0) && !((flags = al->al[item].flags) & (AlfDisabled|AlfHidden))) {
		if ((flags & AlfTypeMask) == AlfToggle) {
			AppendMenu(menu,MF_STRING,IDAL_TOGGLE,T("&Toggle"));
			SetMenuDefaultItem(menu,0,TRUE);
		}
		else if ((flags & AlfTypeMask) == AlfButton) {
			AppendMenu(menu,MF_STRING,IDAL_COMMAND,T("&Do command"));
			SetMenuDefaultItem(menu,0,TRUE);
		}
		//else if ((flags & (AlfTypeMask|AlfFile)) == (AlfEdit|AlfFile)) {
		//		AppendMenu(menu,MF_STRING,MidBrowse,T("&Browse"));
		//		SetMenuDefaultItem(menu,0,TRUE);
		//}
		AppendMenu(menu,MF_STRING,IDAL_COPY,T("&Copy"));
		if ((flags & AlfTypeMask) == AlfEdit) { // ensure IS edit and is NOT locked
			if (GetPriorityClipboardFormat(&ClipboardFormats[0],2) > 0)
				AppendMenu(menu,MF_STRING,IDAL_PASTE,T("&Paste"));
			AppendMenu(menu,MF_STRING,IDAL_CLEAR,T("C&lear"));
		}
		AppendMenu(menu,MF_SEPARATOR,0,0);
	}
	AppendMenu(menu,MF_STRING,IDAL_COPYALL,T("Copy &all"));
	AppendMenu(menu,MF_STRING,IDAL_HELP,T("&Help"));

	SendMessage(GetParent(self),WM_COMMAND, (flags & AlfIdMask)|ALN_CONTEXT, (LPARAM)menu);

	ClientToScreen(self, (POINT*)&x);
	SetCursor(LoadCursor(NULL, IDC_ARROW)); // otherwise menu does not show arrow
	TrackPopupMenuEx(
		menu,
		TPM_LEFTALIGN|TPM_RIGHTBUTTON|TPM_NONOTIFY,
		x, y,
		self,
		NULL);
	DestroyMenu(menu);
}


// purpose:
//		displays the popup menu for a multi choice menu item.
// !assumes:
//		al points to the current attribute list
//		selected is valid (GetSelectedFlags has been checked)
//		self refers to own hwnd
// input:
//		[selected] - currently selected item
// returns:
//		nothing, WM_COMMAND is sent to window procedure
static void ShowSelectedChoiceMenu()
{
		GetItemRect(selected, 0);
		rect.top=rect.bottom; // setup for ClientToScreen to make POINT
		ClientToScreen(self, (POINT*)&rect);
		ShowGivenChoiceMenu(selected, rect.left, rect.top);
}


// purpose:
//		displays the popup menu for a multi choice menu item.
// !assumes:
//		al points to the current attribute list
//		item is valid (GetGivenFlags has been checked)
//		self refers to own hwnd
// input:
//		item - selected item 0 to total-1
//		x - left of menu
//		y - top of menu
// returns:
//		nothing, WM_COMMAND is sent to window procedure
static void ShowGivenChoiceMenu(unsigned int item, int x,int y)
{
	HMENU menu;
	int mid; // menu item id
	char name[256];
	short *text = al->al[item].text;
			
	if (text && (menu=CreatePopupMenu())) {
		// build menu choices
		for (mid=0; *text; text+=lstrlenW(text)+1, mid++) {
			if (unicode) {
				AppendMenuW(menu,MF_STRING,mid,text);
			}
			else {
				WideCharToMultiByte(CP_ACP, 0, text,-1, name, sizeof(name), NULL,NULL);
				AppendMenuA(menu,MF_STRING,mid,name);
			}			
		}
		SetMenuDefaultItem(menu,flags >> AlfCheckedRs,TRUE);

		TrackPopupMenuEx(
			menu,
			TPM_LEFTALIGN|TPM_LEFTBUTTON|TPM_NONOTIFY,
			x, y,
			self,
			NULL);
		DestroyMenu(menu);
	}
}

// purpose:
//		sets the flags for a toggle or menu button.
//		not meant for menus or edits
//		very simple function, but I saw myself using this exact same
//		code in several places and decided to consolidate.
//		no error checking since so much has already happened by any
//		part of the code that would call this function.
// !assumes:
//		al points to the current attribute list
//		selected is valid (GetSelectedFlags has been checked)
// input:
//		[selected] - currently selected item
//		flags - new flags to set
// returns:
//		nothing
static void SetSelectedButtonValue(unsigned int flags)
{
	al->al[selected].flags = flags|AlfRedraw;
	PostRedraw(); //redraw toggle or menu item
	HoverRect.bottom=0; // force mouse recalc upon next mouse move
	SendClickCommand(flags);
	ResizeOverlay();
}


// purpose:
//		counts how many choies are in an item (almost always for menus).
//		the last choice is terminated by a double null.
// !assumes:
//		flags is the bitflags of the desired item (GetSelectedFlags called or similar)
//		item is indeed a menu item (otherwise potential GPF). Item type is not 
//		validated because this function is called so rarely, and only menu item 
//		code should even be calling this function anyway.
static unsigned int TotalChoices(short *text)
{
	int total=0;
	if (text) { // ensure not null pointer
		//if ((flags & AlfTypeMask) == AlfMenu)
		while (*text) {
			total++;
			text += lstrlenW(text)+1; // skip ahead by size of string + NULL
		}
	}
	return total;
}

// hack function to remedy MS's bitmap palette faux pau
// I don't care whether you choose RGB or BGR, but be CONSISTENT.
//static unsigned int __fastcall ReverseRGB(unsigned int rgb)
__inline static unsigned int ReverseRGB(unsigned int rgb)
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
__inline static unsigned int abs_(signed int n)
{
#ifdef _MSC_VER
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
