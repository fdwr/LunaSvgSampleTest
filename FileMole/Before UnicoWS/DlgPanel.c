#include "flanscan.h"
#include "resource.h"

#ifdef _DEBUG
extern void debugwrite(char* Message, ...);
#else
#define debugwrite //
#endif

int __stdcall DlgPanelProc(HWND hwnd, UINT message, long wParam, long lParam);


WNDCLASS wcDlgPanel = {
	0, //style
	(WNDPROC)DlgPanelProc, //lpfnWndProc
	0, //cbClsExtra
	DLGWINDOWEXTRA, //cbWndExtra=0;
	ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	COLOR_BTNFACE + 1, //hbrBackground
	0, //lpszMenuName
	"DlgPanelClass" //lpszClassName
};


////////////////////////////////////////////////////////////////////////////////
// Very common global variables
RECT rect;
//WINDOWPOS wp;
//MSG msg;
//HANDLE dummy;


////////////////////////////////////////////////////////////////////////////////
// Code

int __stdcall DlgPanelProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	static int InitialNcCalc=false;

	//debugwrite("DlgPanelProc msg=%X", message);
	switch (message)
	{
	case WM_NCCREATE:
		{
        //resize as it would be without any borders
		LPCREATESTRUCT lpcs = (LPCREATESTRUCT) lParam;		
		rect.top= rect.left= rect.right= rect.bottom = 0;
		AdjustWindowRectEx(&rect, lpcs->style, FALSE, 0);
		SetWindowPos(hwnd,NULL, 0,0,
					 lpcs->cx +rect.left-rect.right+(2+2),
					 lpcs->cy +rect.top-rect.bottom+(2+2)+GetSystemMetrics(SM_CYCAPTION),
					 SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOMOVE|SWP_NOREDRAW|SWP_NOZORDER);

        //set window title
		DefWindowProc(hwnd, WM_SETTEXT, 0,(LPARAM)lpcs->lpszName);

        //resize window to WS_CAPTION, otherwise edit controls do not work!?

		SetWindowLong(hwnd, GWL_STYLE, WS_CHILD|DS_3DLOOK|WS_SYSMENU|WS_CAPTION);
		//lpcs->cy=100;
		//GetClientRect(hwnd, &rect);
		//debugwrite("DlgPanelProc h=%d w=%d", rect.bottom, rect.right);
		//debugwrite("DlgPanelProc h=%d w=%d", lpcs->cy, lpcs->cx);
		//resize window
		return true;
		}
	case WM_NCHITTEST:
		return HTBORDER;//HTCLIENT;
	case WM_NCLBUTTONDOWN:
		//check clicking on close button, otherwise ignore
		GetWindowRect(hwnd, &rect);
		//if ((lParam & 0xFFFF) > rect.right-GetSystemMetrics(SM_CXSIZE)
		//	&& ((unsigned)lParam >> 16) < rect.top+GetSystemMetrics(SM_CYSIZE))
		if ((lParam & 0xFFFF) > rect.right-GetSystemMetrics(SM_CXSIZE)-1
			&& ((signed)lParam >> 16) < rect.top+GetSystemMetrics(SM_CYSIZE))
			DefDlgProc(hwnd, WM_CLOSE, wParam, lParam);
			//SetFocus(GetNextDlgTabItem(MainHwnd, GetFocus(),TRUE));
			//DestroyWindow(hwnd);
		return false;
	//case WM_COMMAND:
        //chain to dialog procedure
		//GetWindowRect(hwnd, &rect);
		//debugwrite("dpp-command rect top=%d left=%d bottom=%d right=%d", 13,rect.left,rect.bottom,rect.right);
		//return CallWindowProc(GetWindowLong(hwnd, DWL_DLGPROC), hwnd, message, wParam, lParam);
		//debugwrite("DlgPanelProc-command=%X", GetWindowLong(hwnd, DWL_DLGPROC));
		//debugwrite("DlgPanelProc-command=%X", &FindDlgProc);
		//return 0;
	case WM_NCCALCSIZE:	//calculate client area to include a caption and inner edge
		//debugwrite("* dlgpanel nccalcsize wParam=%d NoRecurse=%d",wParam, InitialNcCalc);
		if (wParam==0 || InitialNcCalc) return 0;
		{
		LPRECT lpr = ((LPRECT) lParam);
		/*
		LPRECT lpr2 = ((LPRECT) lParam)+1;
		LPRECT lpr3 = ((LPRECT) lParam)+2;
		GetWindowRect(hwnd, &rect);
		debugwrite("dpp-calcsize wrect top=%d left=%d bottom=%d right=%d", rect.top,rect.left,rect.bottom,rect.right);
		debugwrite(">dpp-calcsize lpr1 top=%d left=%d bottom=%d right=%d", lpr->top, lpr->left, lpr->bottom, lpr->right);
		debugwrite(">dpp-calcsize lpr2 top=%d left=%d bottom=%d right=%d", lpr2->top, lpr2->left, lpr2->bottom, lpr2->right);
		debugwrite(">dpp-calcsize lpr3 top=%d left=%d bottom=%d right=%d", lpr3->top, lpr3->left, lpr3->bottom, lpr3->right);
		DefWindowProc(hwnd, message, wParam, lParam);
		*/
		lpr->top+=GetSystemMetrics(SM_CYCAPTION)+2;
		lpr->bottom-=2;
		lpr->left+=2;
		lpr->right-=2;
		/*
		debugwrite("   dpp-calcsize lpr1 top=%d left=%d bottom=%d right=%d ret=%d", lpr->top, lpr->left, lpr->bottom, lpr->right, a);
		debugwrite("   dpp-calcsize lpr2 top=%d left=%d bottom=%d right=%d", lpr2->top, lpr2->left, lpr2->bottom, lpr2->right);
		debugwrite("   dpp-calcsize lpr3 top=%d left=%d bottom=%d right=%d", lpr3->top, lpr3->left, lpr3->bottom, lpr3->right);
		*/
		return 0;
		}
	case WM_ACTIVATE:
	case WM_NCACTIVATE:
		//return false;
	case WM_NCPAINT:	// draw our own nonclient border
	{
		HDC hdc=GetWindowDC(hwnd);
		#define DC_GRADIENT         0x0020
        int CaptionStyle=DC_TEXT|DC_ICON|DC_GRADIENT;
		
		GetWindowRect(hwnd, &rect);
		OffsetRgn((HRGN)wParam, -rect.left,-rect.top);
		SelectClipRgn(hdc, (HRGN)wParam);
		OffsetRgn((HRGN)wParam, rect.left,rect.top);

        // draw panel's client edge
        // it is annoying Windows won't return the correct metric values
		rect.right-=rect.left;
		rect.left=0;
		rect.bottom-=rect.top;	
		rect.top=GetSystemMetrics(SM_CYCAPTION);
		DrawEdge(hdc, &rect, BDR_SUNKENINNER|BDR_SUNKENOUTER, BF_RECT);

        // draw caption
		rect.bottom=rect.top-1;
		rect.top=0;
        if (IsChild(GetActiveWindow(), hwnd)) CaptionStyle|=DC_ACTIVE;
        DrawCaption(hwnd, hdc, &rect, CaptionStyle);

        // draw single line between caption and edge
		rect.top=rect.bottom;
		rect.bottom++;		
		FillRect(hdc, &rect, (HBRUSH)(COLOR_BTNFACE+1));

        // draw close button
		rect.right-=2;
		rect.left=rect.right-GetSystemMetrics(SM_CXSIZE)+2;
		rect.top=2;
		rect.bottom=GetSystemMetrics(SM_CYSIZE)-2;
		DrawFrameControl(hdc, &rect, DFC_CAPTION, DFCS_CAPTIONCLOSE);

		ReleaseDC(hwnd, hdc);
		return false;
	}
	case WM_ERASEBKGND:
		return true;
	/*case WM_CTLCOLOREDIT:
	{
		//
		long Clr=COLOR_WINDOW;
		if (GetFocus()==WindowFromDC((HDC)wParam)) Clr=COLOR_INFOBK;
		SetBkColor((HDC)wParam, GetSysColor(Clr));
		return GetSysColorBrush(Clr);
	}*/
	default:
		//debugwrite("dlgpanelmsg=%x", message);
		return DefDlgProc(hwnd, message, wParam, lParam);
		//return DefWindowProc(hwnd, message, wParam, lParam);
	}
}
