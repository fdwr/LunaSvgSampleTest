#include "resource.h"
#include "lanmole.h"

static int __stdcall LanListProc(HWND hwnd, UINT message, long wParam, long lParam);
static void __stdcall Select(unsigned int NewSelect);
static void __stdcall ScrollBy(int NewTop, long flags);
static void __stdcall Resize();
static void __stdcall Scroll(int dif);
static void __stdcall SetScrollBars();
static int __stdcall SendCommand(unsigned int code, int lParam);
int __stdcall LanList_GetIndexItem(unsigned int index, unsigned int defitem);
void __stdcall Toggle(unsigned int NewSelect);
int __stdcall LanList_GetTextAt(unsigned int index, unsigned int column, char *text);

extern short* StringCopy(short* src, short* dest, int count);

#ifdef _DEBUG
 extern void debugwrite(char* Message, ...);
 extern void debugerror();
#else
 #define debugwrite //
 #define debugerror //
#endif

WNDCLASSW wcLanList = {
	CS_OWNDC|CS_DBLCLKS, //style
	(WNDPROC)LanListProc, //lpfnWndProc
	0, //cbClsExtra
	0, //cbWndExtra=0;
	ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	(HBRUSH)(COLOR_WINDOW + 1), //hbrBackground
	0, //lpszMenuName
	L"LanItemList" //lpszClassName
};

#define TotalHeaderItems 5
#define HdrIdxName 0 //header column indexes
#define HdrIdxSize 1
#define HdrIdxTime 2
#define HdrIdxId   3
#define HdrIdxType 4

//extern unsigned int LanListTotal; //total items in list
extern unsigned int LanListTotal; //total items in list
extern unsigned int LanListSize; //viewable items in list (<total if filtered)
extern unsigned int LanListTextSize; //total bytes used by text
extern unsigned int LanListSelect; //selected item
extern unsigned int LanListTop; //item at top of list
extern unsigned int LanListView;
extern unsigned int *LanListPtr;
extern HIMAGELIST LanListHiml;

extern LanListEl LanAtrs[LanAtrsMax];
extern short LanNames[LanNamesMax]; //up to half a megabyte just for filenames

//static int LanListTop, LanListLeft=0, Height, Width, ItemHeight, ItemWidth;
//Note that although there 'could' be more than one LanList window, there is
//only meant to be ONE at any given time.

static int Top, Left=0, Height, Width, ItemHeight, ItemWidth;
unsigned int item;

// shared vars
LONG unicode;					// OS supports unicode if true
HDC hdc;
RECT rect;
WINDOWPOS wp;
HFONT GuiFont;
signed int hoverwheel;			// wheel accumulator for fine grain mice

// private vars
static HWND self;				// this is set upon message entry
static HWND HeaderHwnd;
static SYSTEMTIME stime;
static unsigned int KeyTime;	// time of last key press used for key search
static unsigned int KeyPos=0;	// character position of last matching character
#define KeyTimeMax 1000			// time allowed between character searches
static SCROLLINFO ScrollInfo = {
	sizeof(SCROLLINFO), SIF_ALL|SIF_DISABLENOSCROLL,
	0, 100,		10, 50,		0};
HD_ITEM HeaderInfo = {
	HDI_TEXT|HDI_WIDTH|HDI_IMAGE, 250, NULL, NULL, 
	0, HDF_LEFT|HDF_STRING|HDF_BITMAP_ON_RIGHT|HDF_IMAGE, 0, 
	LliAscending,0};
static char *LanTypeNames[16] =
{
	"Unknown",
	"Domain",
	"Server",
	"Share",
	"File",
	"Group",
	"Network",
	"Root",
	"ShareAdmin",
	"Folder",
	"Tree",
	"NDS",
	"Printer",
	"Computer",
	"Drive",
	"Volume"
};


static int __stdcall LanListProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	self = hwnd;

	//debugwrite("lan msg=%X w=%X l=%X", message, wParam, lParam);
    switch (message) {
    case WM_CREATE:
	{
		static HDLAYOUT hdl = {&rect, &wp};

		//create header
		HeaderHwnd=CreateWindowEx(0,
			"SysHeader32",
			NULL,
			WS_CHILD |HDS_DRAGDROP, //  |HDS_HOTTRACK|HDS_FULLDRAG,
			0,0, 4096,10,
			hwnd,
			(HMENU)IDC_LISTHEADER,
			ProgMemBase,
			NULL);
		//debugwrite("header hwnd=%d", HeaderHwnd);
		SendMessage(HeaderHwnd, WM_SETFONT, (WPARAM)GetStockObject(DEFAULT_GUI_FONT), FALSE);
		Header_SetImageList(HeaderHwnd, LanListHiml);
		HeaderInfo.pszText="Name";	HeaderInfo.cxy=220;	SendMessage(HeaderHwnd, HDM_INSERTITEM, 255, (LPARAM)&HeaderInfo);
		HeaderInfo.pszText="Size";	HeaderInfo.cxy=90;	SendMessage(HeaderHwnd, HDM_INSERTITEM, 255, (LPARAM)&HeaderInfo);
		HeaderInfo.pszText="Time";	HeaderInfo.cxy=116;	SendMessage(HeaderHwnd, HDM_INSERTITEM, 255, (LPARAM)&HeaderInfo);
		HeaderInfo.pszText="ID/IP";	HeaderInfo.cxy=90;	SendMessage(HeaderHwnd, HDM_INSERTITEM, 255, (LPARAM)&HeaderInfo);
		HeaderInfo.pszText="Type";	HeaderInfo.cxy=80;	SendMessage(HeaderHwnd, HDM_INSERTITEM, 255, (LPARAM)&HeaderInfo);

		GetClientRect(hwnd, &rect);
		Header_Layout(HeaderHwnd, (LPARAM)&hdl);
		Top=wp.cy;
		ItemWidth=220+90+116+90+80; //!!!
		SetWindowPos(HeaderHwnd, NULL, wp.x,wp.y, 4096, wp.cy, wp.flags|SWP_SHOWWINDOW);

		// determine item height from default list font
		hdc=GetDC(hwnd);
		if (!GuiFont) {
			LOGFONT lf;
			SystemParametersInfo(SPI_GETICONTITLELOGFONT, sizeof(LOGFONT), &lf, 0);
			//lf.lfCharSet=ANSI_CHARSET;
			//lf.lfFaceName[0]=0;
			GuiFont=CreateFontIndirect(&lf);
			SelectObject(hdc, GuiFont);
			ItemHeight=lf.lfHeight;
		} else {
			TEXTMETRIC tm;
			SelectObject(hdc, GuiFont);
			GetTextMetrics(hdc, &tm);
			debugwrite("tm height=%d", tm.tmHeight);
			debugwrite("tm a=%d d=%d", tm.tmAscent,tm.tmDescent);
			ItemHeight=tm.tmHeight;
		}

		SetBkMode(hdc, TRANSPARENT);
		
		if (ItemHeight<0) ItemHeight=-ItemHeight; //correct negative value
		if (ItemHeight<16) ItemHeight=16;

		SetWindowOrgEx(hdc, 0, -Top, NULL);
		//SelectObject(hdc, GetStockObject(NULL_BRUSH));
		//SelectObject(hdc, CreatePen(PS_SOLID, 2,GetSysColor(COLOR_ACTIVECAPTION)));
		Resize();
		SetScrollBars();
		return false;
	}
	case WM_PAINT:
	{
		unsigned int col; //left column
		unsigned int flags; //item flags
		unsigned int index; //index of item's row
		int secondpass=0; //two pass counter
		int clrab=GetSysColor(COLOR_HIGHLIGHT),			 
			clrat=GetSysColor(COLOR_HIGHLIGHTTEXT),
			clrsb=GetSysColor(COLOR_BTNFACE),			//((clrab & 0xFEFEFE) + (clrub & 0xFEFEFE)) >> 1;
			clrst=GetSysColor(COLOR_BTNTEXT),
			clrub=GetSysColor(COLOR_WINDOW),
			clrut=GetSysColor(COLOR_WINDOWTEXT);
		int focus=GetFocus()==hwnd;
		RECT ur, ir, hr[TotalHeaderItems]; //update rect, intersect, attribute rects
		HRGN urgn=CreateRectRgn(0,0,0,0); //create stupid, dummy region
		char text[MAX_PATH*2];

		//BeginPaint(hwnd, &ps);
		//SetBkColor(ps.hdc, 0xA08080);
		//SelectObject(hdc, GetStockObject(GRAY_BRUSH));

		hdc=GetDC(hwnd);
		GetUpdateRect(hwnd, &ur, FALSE);
		//OffsetRect(&ur, 0, -Top); //compensate for header bar
		GetUpdateRgn(hwnd, urgn, FALSE);
		ValidateRect(hwnd, NULL);
		//SelectClipRgn(hdc, NULL);

		// special case for empty list, print message
		if (LanListSize==0) {
			SelectClipRgn(hdc, urgn); //clip to update region
			FillRect(hdc, &ur, (HBRUSH)(COLOR_WINDOW+1));
			SetTextColor(hdc, clrut);
			TextOut(hdc, 3-Left,1, text,
				DefWindowProc(hwnd, WM_GETTEXT, sizeof(text),(LPARAM)text)
			);
			SelectClipRgn(hdc, NULL);
			return false;
		}

		// get header rects
		for (item=0; item<TotalHeaderItems; item++) {
			Header_GetItemRect(HeaderHwnd, item, &hr[item]);
			hr[item].left-=(Left-2);
			hr[item].right-=(Left+2);
			hr[item].top=0;
			hr[item].bottom=4096; //any huge number
		}

		//DeleteObject(SelectObject(hdc, CreateSolidBrush(GetSysColor(COLOR_HIGHLIGHT))));
		//ExcludeUpdateRgn(hdc, hwnd);
		//SelectObject(hdc, GetStockObject(NULL_PEN));
		//SelectObject(hdc, GetStockObject(NULL_BRUSH));
		while (true) // really does just two passes
		{
			int *llp=LanListPtr+LanListTop;

			//set item rectangle
			rect.left=0;
			rect.top=0;
			rect.right=Width;
			rect.bottom=ItemHeight;

			// first pass: redraw any changed items (redraw flag was set)
			// second pass: redraw any other items (invalidated update region)
			for (item=LanListTop; item<LanListSize; item++, llp++)
			{
				index = *llp; // get actual index into data array
				flags = LanAtrs[index].flags;
				///type = flags >> LlfTypeShift;
				//debugwrite("list i=%d f=%X t=%d",*llp,flags,type);
				if (flags & LlfRedraw) {
					LanAtrs[index].flags &= ~LlfRedraw;

					//TextOut(hdc, col+20,row+20, LanAtrs[index].name,lstrlen(LanAtrs[index].name));
					//if (index == LanListSelect)	Rectangle(hdc, 0,row, Width,row+ItemHeight);
					//if (index == 1)	Rectangle(hdc, 0,row, Width,row+ItemHeight);

					//set colors according to whether selected
					if (item == LanListSelect
					 || flags & LlfSelected) {
						if (focus && (item == LanListSelect)) {
							SetBkColor(hdc, clrab);
							SetTextColor(hdc, clrat);
						} else {
							SetBkColor(hdc, clrsb);
							SetTextColor(hdc, clrst);
						}
					} else {
						SetBkColor(hdc, clrub);
						SetTextColor(hdc, clrut);
					}

					// draw row background (color depends on selection)
					ExtTextOutW(hdc, 0,0, ETO_OPAQUE, &rect, NULL,0, NULL);

					// draw icon
					col=hr[HdrIdxName].left;
					if (LanListView & LlvTree) col+=(flags & LlfIndentMask)*16;
					ImageList_Draw(LanListHiml,flags>>24, hdc,col,rect.top, ILD_TRANSPARENT);

					// draw name
					LanList_GetTextAt(index, HdrIdxName, text);
					ExtTextOutW(hdc, col+20,rect.top+1,
						ETO_CLIPPED, &hr[HdrIdxName], (LPWSTR)text,lstrlenW((LPWSTR)text), NULL);
					//if (focus && item == LanListSelect) Rectangle(hdc, rect.left,rect.top, rect.right,rect.bottom);

					// draw size
					LanList_GetTextAt(index, HdrIdxSize, text);
					SetTextAlign(hdc, TA_RIGHT);
					ExtTextOutA(hdc, hr[HdrIdxSize].right-6,rect.top+1,
						ETO_CLIPPED, &hr[HdrIdxSize], text,lstrlen(text), NULL);

					// draw time
					LanList_GetTextAt(index, HdrIdxTime, text);
					SetTextAlign(hdc, TA_LEFT);
					ExtTextOutA(hdc, hr[HdrIdxTime].left,rect.top+1,
						ETO_CLIPPED, &hr[HdrIdxTime], text,lstrlen(text), NULL);

					// draw id
					if (LanList_GetTextAt(index, HdrIdxId, text)) {
						ExtTextOutA(hdc, hr[HdrIdxId].left,rect.top+1,
							ETO_CLIPPED, &hr[HdrIdxId], text,lstrlen(text), NULL);
					}

					// draw type
					if (LanList_GetTextAt(index, HdrIdxType, text)) {
						ExtTextOutA(hdc, hr[HdrIdxType].left,rect.top+1,
							ETO_CLIPPED, &hr[HdrIdxType], text,lstrlen(text), NULL);
					}

					// draw special state indications (like error, access denied, new)
					/*if (flags & LlfError) DrawState(hdc, NULL,NULL, (long)LanListIcons[flags>>24],(WPARAM)NULL, col,rect.top,0,0, DST_ICON |DSS_DISABLED);*/
					if (flags & LlfDeleted) ImageList_Draw(LanListHiml,LliDeleted, hdc,col,rect.top, ILD_TRANSPARENT);
					else if (flags & LlfIgnore) ImageList_Draw(LanListHiml,LliIgnore, hdc,col,rect.top, ILD_TRANSPARENT);
					else if (flags & LlfError) ImageList_Draw(LanListHiml,LliError, hdc,col,rect.top, ILD_TRANSPARENT);
					else if (flags & LlfDenied) ImageList_Draw(LanListHiml,LliLock, hdc,col,rect.top, ILD_TRANSPARENT);
					if (!(flags & LlfDeleted)) {
						if (flags & LlfNew) ImageList_Draw(LanListHiml,LliNew, hdc,col,rect.top, ILD_TRANSPARENT);
						else if (flags & LlfChanged) ImageList_Draw(LanListHiml,LliChanged, hdc,col,rect.top, ILD_TRANSPARENT);
					}
				} else if (!secondpass) { //first pass, mark if needs redrawing next pass
					if (IntersectRect(&ir, &ur, &rect))
						LanAtrs[index].flags |= LlfRedraw;
				}

				// move current row down one
				rect.top+=ItemHeight;
				rect.bottom+=ItemHeight;
			}
			if (secondpass) break;
			secondpass=true;
			SelectClipRgn(hdc, urgn); //clip to update region on second pass
		} //end two passes

		SelectClipRgn(hdc, NULL); //no clip region
		if (rect.top < ur.bottom) {
			if (rect.top > ur.top) ur.top=rect.top;
			FillRect(hdc, &ur, (HBRUSH)(COLOR_WINDOW+1));
		}

		//EndPaint(hwnd, &ps);
		//ValidateRgn(hwnd, NULL);
		return false;
	}
	case WM_ERASEBKGND:
		return true;
	case WM_GETDLGCODE:
		return DLGC_WANTARROWS|DLGC_WANTCHARS|DLGC_WANTALLKEYS;
	case WM_KEYDOWN:
	{
		//MessageBox(0, "KeyDown", ProgTitle, MB_OK);
		int ctrl = GetKeyState(VK_CONTROL) & 0x80; // top bit is press state
		switch (wParam) {
		case VK_UP:
			if (ctrl) {
				ScrollBy(-1,2);
			} else {
				if (LanListSelect>LanListSize) LanListSelect=LanListSize;
				Select(LanListSelect-1);
			}
			break;
		case VK_DOWN:
			if (ctrl) {
				ScrollBy(1,2);
			} else {
				if (LanListSelect>=LanListSize) Select(0);
				else Select(LanListSelect+1);
			}
			break;
		case VK_LEFT:
			if (ctrl) {
				ScrollInfo.nPos = -16;
				goto HScrollRel; // behold, evil goto
			} else {
				SendCommand(LLN_CLOSE, 0);
			}
			break;
		case VK_RIGHT:
			if (ctrl) {
				ScrollInfo.nPos = 16;
				goto HScrollRel; // behold, evil goto
			} else {
				if (LanListSelect<LanListSize) SendCommand(LLN_OPEN, 0);
			}
			break;
		case VK_SPACE:
			//only if enough time elapsed since last search
			//Toggle(LanListSelect);
			break;
		case VK_RETURN:
			if (LanListSelect<LanListSize) SendCommand(LLN_ENTER, 0);
			break;
		case VK_HOME: Select(0); break;
		case VK_END: Select(LanListSize-1); break;
		case VK_NEXT: ScrollBy(1, 3); break;
		case VK_PRIOR: ScrollBy(-1, 3); break;
		case VK_BACK: SendCommand(LLN_EXIT, 0); break;
		case VK_TAB: SendMessage(GetParent(hwnd), WM_NEXTDLGCTL, GetKeyState(VK_SHIFT) & 0x80, 0); break;
		}
		return 0;
	}
	case WM_CHAR:
		/*
		if control character, ignore and return
		select list choice based on key typed
		set search item to selected
		if been longer than acceptable time period
			reset keycount to zero
			set search item to next after selected
		search by first column on left
		do until searched all (complete wrap around)
			wrap search item if necessary
			get text of search item
			if typed character matches character in string
				select item
				advance character offset
				exit loop
			endif
			next item
		loop
		if match then select item
		else no matches so beep
		*/
		if (wParam>32) {
			char text[MAX_PATH*2];
			unsigned int item=LanListSelect;
			int column=Header_OrderToIndex(HeaderHwnd,0);
			int count=LanListSize;
			int time=GetTickCount()-KeyTime;
			KeyTime+=time;
			if (time > KeyTimeMax) {
				KeyPos=0;
				item++;
			}
			while (count-- > 0) {
				if (item >= LanListSize) item=0;
				if (column != HdrIdxName) {
					LanList_GetTextAt(*(LanListPtr+item), column, text);
				} else {

				}
				item++;
			}
		}
		return 0;
	case WM_VSCROLL:
	{
		int ScrollDif, flags=0;
		switch (wParam & 0xFFFF) {
		case SB_LINEUP: ScrollDif = -1; goto VScrollRel;
		case SB_LINEDOWN: ScrollDif = 1; goto VScrollRel;
		case SB_PAGEUP: ScrollDif = -1;  flags = 1; goto VScrollRel;
		case SB_PAGEDOWN: ScrollDif = 1; flags = 1; goto VScrollRel;
		case SB_THUMBTRACK:
			//ScrollDif=wParam>>16; (only 16bit so 65535 is limit)
			GetScrollInfo(hwnd, SB_VERT, &ScrollInfo);
			ScrollDif=ScrollInfo.nTrackPos; flags=4;
		VScrollRel:
			ScrollBy(ScrollDif, flags);
		}
		return 0;
	}
	case WM_HSCROLL:
		// Hello MS? Did you ever consider having the scrollbar
		// do all this stupid calculation for us, and just send
		// us the new thumb position?
		switch (wParam & 0xFFFF) {
		case SB_LINEUP:		ScrollInfo.nPos = -16; goto HScrollRel;
		case SB_LINEDOWN:	ScrollInfo.nPos = 16; goto HScrollRel;
		case SB_PAGEUP:		ScrollInfo.nPos = -Width; goto HScrollRel;
		case SB_PAGEDOWN:	ScrollInfo.nPos = Width; goto HScrollRel;
		case SB_THUMBTRACK:
			ScrollInfo.nPos=wParam>>16;
			goto HScrollAbs;
		HScrollRel:
			ScrollInfo.nPos+=Left; //add relative adjustment
		HScrollAbs:
			if (ScrollInfo.nPos > ItemWidth-Width) ScrollInfo.nPos=ItemWidth-Width;
			if (ScrollInfo.nPos < 0) ScrollInfo.nPos=0;
			if (ScrollInfo.nPos != Left) {
				ScrollWindow(self, Left-ScrollInfo.nPos,0, NULL,NULL);
				Left=ScrollInfo.nPos;
				SetScrollBars();
			}
		}
		return 0;
	case WM_LBUTTONDBLCLK:
	case WM_LBUTTONDOWN:
		if (wParam & MK_CONTROL)
			Toggle((((signed)lParam>>16) -Top) / ItemHeight + LanListTop);
		else
			Select((((signed)lParam>>16) -Top) / ItemHeight + LanListTop);
		return 0;
		//HDC hdc=GetDC(hwnd);
		//BitBlt(hdc,0,0,100,100,hdc,0,8,SRCCOPY);
		//BitBlt(hdc,0,20,100,100,hdc,0,0,SRCCOPY);
	case WM_MOUSEACTIVATE:
		//MessageBox(hwnd, "MouseActivate", ProgTitle, MB_OK);
		//return MA_ACTIVATE;
		//SetActiveWindow(hwnd);
		SetFocus(hwnd);
		return TRUE;
	case WM_MOUSEWHEEL:
		debugwrite("mouse wheel w=%X l=%X d=%d", wParam, lParam, (signed)wParam>>16);
		ScrollBy((wParam & 0x80000000) ? 1 : -1, 0);
		return TRUE;
	case WM_NOTIFY:
	{
		int code = ((NMHDR*)lParam)->code;
		switch (wParam) {
		case IDC_LISTHEADER: //all for now
			switch (code) {
			case HDN_ENDTRACK:
				Header_GetItemRect(HeaderHwnd, Header_OrderToIndex(HeaderHwnd,TotalHeaderItems-1), &rect);
				//Header_GetItemRect(hwnd, 4, &rect);
				//debugwrite("rect=%d %d", rect.left,rect.right);
				ItemWidth=rect.right;
				SetScrollBars();
			case HDN_ENDDRAG:
				InvalidateRect(hwnd, NULL,FALSE);
			}
		}
		return 0;
	}
	case WM_SETFOCUS:
	case WM_KILLFOCUS:
		if (LanListSelect < LanListSize) LanAtrs[*(LanListPtr+LanListSelect)].flags |= LlfRedraw;
		PostMessage(hwnd, WM_PAINT, 0,0);
		return 0;
	//case WM_ACTIVATE:
	//	MessageBox(hwnd, "Activate", ProgTitle, MB_OK);
	//	return 0;
	case WM_WINDOWPOSCHANGED:
		if (!(((LPWINDOWPOS)lParam)->flags & SWP_NOSIZE))
	case WM_SIZE:
			Resize();
	case WM_WINDOWPOSCHANGING:
	case WM_DESTROY:
		return false;
	/*case WM_SETTINGCHANGE:
		MessageBox(MainHwnd, "Setting changed", ProgTitle, MB_OK);
		if (wParam == SPI_SETICONTITLELOGFONT) LanListSetFont(GetDC(hwnd));
		return false;*/
	default:
		//if (unicode) return DefWindowProcW(hwnd, message, wParam, lParam);
		//else		 return DefWindowProcA(hwnd, message, wParam, lParam);
		return DefWindowProc(hwnd, message, wParam, lParam);
	}
}


void __stdcall Select(unsigned int NewSelect)
{
	unsigned int OldTop=LanListTop;

	if (NewSelect >= LanListSize || NewSelect == LanListSelect) return;
	if (LanListSelect < LanListSize)
		LanAtrs[*(LanListPtr+LanListSelect)].flags |= LlfRedraw;
	LanListSelect = NewSelect;
	LanAtrs[*(LanListPtr+LanListSelect)].flags |= LlfRedraw;

	//scroll list if necessary
	if (LanListSelect < LanListTop)
		LanListTop = LanListSelect;
	else {
		unsigned int RowHeight = Height / ItemHeight;
		if (LanListSelect - LanListTop >= RowHeight) LanListTop = LanListSelect - RowHeight+1;
	}

	if (OldTop!=LanListTop) Scroll(OldTop-LanListTop);
	else PostMessage(self, WM_PAINT, 0,0);
}

void __stdcall Toggle(unsigned int NewSelect)
{
	unsigned register int *flagptr;

	if (NewSelect >= LanListSize) return;
	flagptr = &LanAtrs[*(LanListPtr+NewSelect)].flags;
	*flagptr |= LlfRedraw;
	*flagptr ^= LlfSelected;
	PostMessage(self, WM_PAINT, 0,0);
}


// flags:
//   1 - scroll by page height
//   2 - move selection in parallel
//  (3)- scroll by page and move selection (pgup and pgdn use this)
//   4 - absolute
static void __stdcall ScrollBy(int NewTop, long flags)
{
	int RowHeight = Height / ItemHeight;
	int TopDif;
	if (flags & 1) NewTop*=RowHeight;
	if (!(flags & 4)) NewTop+=(signed)LanListTop;

	if ((unsigned)(NewTop + RowHeight) > LanListSize) NewTop = (signed)LanListSize - RowHeight;
	if ((signed)NewTop < 0) NewTop=0;
	if ((unsigned)NewTop==LanListTop) return;

	if (flags & 2) {
		if (LanListSelect < LanListSize)
			LanAtrs[*(LanListPtr+LanListSelect)].flags |= LlfRedraw;
		LanListSelect+=NewTop-LanListTop;
		if (LanListSelect < LanListSize)
			LanAtrs[*(LanListPtr+LanListSelect)].flags |= LlfRedraw;
	}

	TopDif=LanListTop-NewTop;
	LanListTop=NewTop;
	Scroll(TopDif);
}

static void __stdcall Resize()
{
	GetClientRect(self, &rect);
	Height=rect.bottom-Top;
	Width=rect.right;
	SetScrollBars();
	GetClientRect(self, &rect); // get height once more just in case
	Height=rect.bottom-Top;		// horizontal scroll appeared/disappeared
}

// Height and ItemHeight must be set correctly
static void __stdcall Scroll(int dif)
{
	rect.top=0;			rect.left=0;
	rect.bottom=Height;	rect.right=Width;
	ScrollWindow(self, 0,dif*ItemHeight, &rect,&rect);
	//ScrollWindow(self, 0,dif*ItemHeight, NULL,NULL);
	SetScrollBars();
}

// Height and ItemHeight must be set correctly
static void __stdcall SetScrollBars()
{
	ScrollInfo.fMask=SIF_ALL|SIF_DISABLENOSCROLL;
	ScrollInfo.nMax=LanListSize-1;
	ScrollInfo.nPage=Height/ItemHeight;
	ScrollInfo.nPos=LanListTop;
	SetScrollInfo(self, SB_VERT, &ScrollInfo, true);
	//FlatSB_SetScrollInfo(self, SB_VERT, &ScrollInfo, true); (on second thought, I don't really like these)

	ScrollInfo.fMask=SIF_ALL;
	ScrollInfo.nMax=ItemWidth-1;
	ScrollInfo.nPage=Width;
	ScrollInfo.nPos=Left;
	SetScrollInfo(self, SB_HORZ, &ScrollInfo, true);
	//FlatSB_SetScrollInfo(self, SB_HORZ, &ScrollInfo, true);
}

static int __stdcall SendCommand(unsigned int code, int lParam)
{
	return SendMessage(GetParent(self), WM_COMMAND, 
		GetDlgCtrlID(self) | code, 
		(LPARAM)self);
}

// purpose:
//	finds which item in the list is the given file index.
//	defitem can be used as a sentinel code or as a default
//	item to return if no match is found.
//
// returns:
//	the item/row number. returns defitem if not found.
int __stdcall LanList_GetIndexItem(unsigned int index, unsigned int defitem)
{
	unsigned int item;
	unsigned int *llp=LanListPtr;

	for (item=0; item<LanListSize; item++,llp++) {
		if (index == *llp) return item;
	}
	return defitem;
}


// purpose:
//	formats the text for the given item and column.
//
// note:
//	!returns ANSI string for all columns except Unicode for name column
//	!the text buffer is assumed to be at least MAX_PATH*2 bytes.
//	the index passed is not the row, but rather the actual index.
int __stdcall LanList_GetTextAt(unsigned int index, unsigned int column, char *text)
{
	LanListEl *lle;
	static char sep[]=",";
	const static NUMBERFMT nfm = {0,FALSE,3, sep,sep, FALSE};
	//unsigned int flags; //item flags
	//unsigned int type; //type of item

	if (index >= LanListTotal || column >= TotalHeaderItems) {
		*text=0;
		return FALSE;
	}

	lle = &LanAtrs[index];
	//flags = lle->flags;
	//type = flags >> LlfTypeShift;

	switch (column) {
	case HdrIdxName:
		// todo: format name as Mix case, lower case, or normal
		StringCopy(lle->name, (short*)text, MAX_PATH);
		StringLower(text);
		break;
	case HdrIdxSize:
		wsprintf(&text[16], "%u", lle->size);
		GetNumberFormat(LOCALE_USER_DEFAULT,0, &text[16],&nfm , text, 16);
		break;
	case HdrIdxTime:
		FileTimeToSystemTime((FILETIME*)&lle->timel, &stime);
		wsprintf(text, "%04u-%02u-%02u %02u:%02u:%02u", stime.wYear, stime.wMonth, stime.wDay, stime.wHour, stime.wMinute, stime.wSecond);
		break;
	case HdrIdxId:
		switch (lle->flags & LlfTypeMask) {
		register unsigned int id;
		case LlfServer:
			{
			static int ips[4]={0,0,0,0};
			id=lle->ip;
			//RtlMoveMemory(text, inet_ntoa(lle->ip), 16);
			// !! the ntoa function is evil. Simply calling it once
			// slowed my screen updates by half. The function code
			// must be really CRUDDY. So it was easy to make my own.
			__asm { // separate dword into bytes
			 mov eax,id				//lle->ip
			 mov byte ptr ips[0],al //don't worry about upper
			 mov byte ptr ips[4],ah //24 bits. they are
			 rol eax,16				//statically zero extended
			 mov byte ptr ips[8],al
			 mov byte ptr ips[12],ah
			}
			wsprintf(text, "%d.%d.%d.%d", ips[0],ips[1],ips[2],ips[3]);
			break;
			}
		case LlfVolume:
			id=lle->serial;
			wsprintf(text, "%04X-%04X", id>>16,id&0xFFFF); //lle->serial
			break;
		default:
			*text=0; // set empty string
			return FALSE; // premature exit!
		}
		break;
	case HdrIdxType:
		if (lle->flags <= (LlfTypeMax|~LlfTypeMask)) {
			lstrcpy(text, LanTypeNames[ lle->flags>>LlfTypeShift ]); //why are lstrcpy's parameters backwards!?
		} else {
			*text=0; // set empty string
			return FALSE; // premature exit!
		}
		break;
	}
	return TRUE;
}


//void LanListSetFont(HDC hdc);
//void LanListSetFont(HDC hdc)
//{
//	LOGFONT lf;
//	SystemParametersInfo(SPI_GETICONTITLELOGFONT, sizeof(LOGFONT), &lf, 0);
//	SelectObject(hdc, CreateFontIndirect(&lf));
//}
