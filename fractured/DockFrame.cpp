/**
File: dockframe.cpp
Since: 2005-11-30
Remark: Dockable frame class.
*/

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#define _WIN32_WINDOWS 0x0401
// Windows Header Files:
#include <windows.h>
#include <windowsx.h>
#include <stdlib.h>
#include <math.h>

#include "basictypes.h"
#include "tchar.h"
#include "dockframe.h"

#include "debugmsg.h"	// you can remove this and delete any dbgmsg calls

////////////////////////////////////////////////////////////////////////////////

static void AlignToWindow(HWND hwnd);

////////////////////////////////////////////////////////////////////////////////

#pragma warning(disable:4312) // 'type cast' conversion from 'UINT' to 'HMENU' of greater size
#pragma warning(disable:4800) // 'type cast' conversion from 'UINT' to 'HMENU' of greater size

////////////////////////////////////////////////////////////////////////////////

static WNDCLASSEX DockFrame_WndClass = {
	sizeof(WNDCLASSEX),
	0, //style //CS_HREDRAW | CS_VREDRAW;
	(WNDPROC)&DockFrame_WndProc, //lpfnWndProc
	0, //cbClsExtra
	DLGWINDOWEXTRA, //cbWndExtra
	nullptr, //hInstance
	nullptr, //hIcon
	nullptr, //hCursor
	nullptr, //hbrBackground
	nullptr, //lpszMenuName
	DockFrameClass, //lpszClassName
	nullptr //hIconSm
};

static struct {		// it's okay for this to be static since only one window can be moved by the user
	RECT rect;		// size and offset of window (bottom and right are size, not offsets; top and left are screen relative)
	POINT pos;
	POINT distance;		// minimum distance to nearest edge
	HWND self;			// ignore self
} Dfa; // dock frame alignment


WNDCLASSEX* DockFrame_GetWndClass()
{
	//DockFrame_WndClass.cbSize = sizeof(WNDCLASSEX); 
	//DockFrame_WndClass.style			= 0;//CS_HREDRAW | CS_VREDRAW;
	//DockFrame_WndClass.lpfnWndProc	= (WNDPROC)&DockFrame_WndProc;
	//DockFrame_WndClass.cbClsExtra		= 0;
	//DockFrame_WndClass.cbWndExtra		= 0;
	  DockFrame_WndClass.hInstance		= GetModuleHandle(nullptr);
	  DockFrame_WndClass.hIcon			= LoadIcon(DockFrame_WndClass.hInstance, (LPCTSTR)IDI_APPLICATION);
	  DockFrame_WndClass.hCursor		= LoadCursor(nullptr, IDC_ARROW);
	  DockFrame_WndClass.hbrBackground	= (HBRUSH)(COLOR_WINDOW+1);
	//DockFrame_WndClass.lpszMenuName	= (LPCTSTR)0;
	//DockFrame_WndClass.lpszClassName	= DockFrameClass;
	  DockFrame_WndClass.hIconSm		= DockFrame_WndClass.hIcon; //LoadIcon(wcex.hInstance, (LPCTSTR)IDI_SMALL);

	return &DockFrame_WndClass;
}


/** Processes messages for the dock frame.
*/
LRESULT CALLBACK DockFrame_WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	DockFrameInfo* dfi = (DockFrameInfo*) GetWindowLongPtr(hwnd, DWL_USER);

	switch (message) 
	{
	case WM_NCCREATE:
		{
			// allocate structure
			dfi = (DockFrameInfo*) GlobalAlloc(GMEM_FIXED, sizeof(DockFrameInfo));
			if (dfi == nullptr)
				return FALSE; // ??
			SetWindowLongPtr(hwnd, DWL_USER, (LONG)(LONG_PTR)dfi);
			SetWindowLongPtr(hwnd, DWL_DLGPROC, (LONG)(LONG_PTR)0);
			dfi->hwnd = hwnd; // for caller's benefit
			return DefDlgProc(hwnd, message, wParam, lParam);
		}
	//case WM_CREATE:
	// Grr.. If you create a window with WS_EX_MDICHILD,
	// inconsistent Windows does NOT pass the correct lParam you used for window creation.
	/*
	case WM_NCACTIVATE:
		dbgmsg(T("FilterFrame WM_NCACTIVATE"));
		return DefDlgProc(hwnd, message, wParam, lParam);
	case WM_MOUSEACTIVATE:
		dbgmsg(T("FilterFrame WM_MOUSEACTIVATE"));
		return DefDlgProc(hwnd, message, wParam, lParam);
	case WM_ACTIVATE:
		dbgmsg(T("FilterFrame WM_ACTIVATE"));
		return DefDlgProc(hwnd, message, wParam, lParam);
		*/
	//case WM_MOUSEACTIVATE:
	//	return MA_ACTIVATE;
	/*
	case WM_COMMAND:
		{
			if (HIWORD(wParam) == 1) wParam = LOWORD(wParam); // mask off accelerator key code
			return DoCommand(hwnd, message, wParam, lParam, (HWND)lParam, wParam);
		}
	case WM_NOTIFY:
		{
			NMHDR* pnmh = (NMHDR*)lParam;
			assert(wParam <= 65535);
			return DoCommand(hwnd, message, wParam, lParam, pnmh->hwndFrom, (pnmh->code<<16) | wParam);
		}
	*/
	/*
	case WM_SYSCOMMAND:
		{
			if ((wParam & 0xFFF0) == SC_CLOSE) {
				RECT rect;
				GetWindowRect(hwnd, &rect);
				rect.right -= rect.left;
				int height = GetSystemMetrics(SM_CYSMCAPTION) + GetSystemMetrics(SM_CXBORDER) * 2;
				SetWindowPos(hwnd, nullptr, 0,0, rect.right, height, SWP_NOACTIVATE|SWP_NOZORDER|SWP_NOMOVE|SWP_NOZORDER);
			}
			else
				return DefDlgProc(hwnd, message, wParam, lParam);
		}
		break;
	*/
	case WM_PRINTCLIENT:
	case WM_PAINT:
		{
			/*
			PAINTSTRUCT ps;
			HDC hdc = (message == WM_PRINTCLIENT) ? (HDC)wParam : BeginPaint(hwnd, &ps);

			// TODO: Add any drawing code here...

			if (message != WM_PRINTCLIENT) EndPaint(hwnd, &ps);
			*/
			PAINTSTRUCT ps;
			HDC hdc = BeginPaint(hwnd, &ps);

			// TODO: Add any drawing code here...

			EndPaint(hwnd, &ps);
		}
		break;
	//case WM_ERASEBKGND:
	//	return TRUE;
	/*
	case WM_NCPAINT:
			HDC hdc = GetDCEx(hdlg, (HRGN)wParam, DCX_WINDOW | DCX_INTERSECTRGN | 0x10000);
			RECT rect = {0,0,100,30};
			DrawCaption(hdlg, hdc, &rect, DC_ACTIVE|DC_SMALLCAP|DC_TEXT);
			ReleaseDC(hdlg, hdc);
	*/
	case WM_EXITSIZEMOVE:
		{
			// align to nearest window if any
			Dfa.distance.x =
			Dfa.distance.y = DockFrame_AlignmentMinDistance;
			Dfa.self = hwnd;
			GetWindowRect(hwnd, &Dfa.rect);
			Dfa.pos.x = Dfa.rect.left;
			Dfa.pos.y = Dfa.rect.top;

			// find nearest child window
			// must use while loop instead of EnumChildWindows
			// otherwise ALL children and subchildren are returned.
			HWND parent = GetParent(hwnd);
			HWND nextWindow = GetTopWindow(parent);
			while (nextWindow) {
				AlignToWindow(nextWindow);
				nextWindow = GetWindow(nextWindow, GW_HWNDNEXT);
			}
			//EnumChildWindows(GetParent(hwnd), &AlignToWindow, nullptr);

			// adjust coordinates from screen to parent's client
			int size;
			RECT parentRect;
			GetClientRect(parent, &parentRect);
			ScreenToClient(parent, &Dfa.pos);

			// align to inside of parent client region if close enough
			// align left to left
			if (Dfa.pos.x < DockFrame_AlignmentMinDistance) {
				Dfa.pos.x = 0;
			}
			// align right to right
			size = Dfa.rect.right - Dfa.rect.left;
			if (Dfa.pos.x + size - parentRect.right > -DockFrame_AlignmentMinDistance) {
				Dfa.pos.x = parentRect.right - size;
			}
			// align top to top
			if (Dfa.pos.y < DockFrame_AlignmentMinDistance) {
				Dfa.pos.y = 0;
			}
			// align bottom to bottom
			size = Dfa.rect.bottom - Dfa.rect.top;
			if (Dfa.pos.y + size - parentRect.bottom > -DockFrame_AlignmentMinDistance) {
				Dfa.pos.y = parentRect.bottom - size;
			}

			SetWindowPos(hwnd, nullptr,
				Dfa.pos.x, Dfa.pos.y,
				0,0,
				SWP_NOACTIVATE|SWP_NOZORDER|SWP_NOSIZE);
			return DefDlgProc(hwnd, message, wParam, lParam);
		}
		break;
	case WM_CHILDACTIVATE:
	case WM_GETMINMAXINFO:
	case WM_MOVE:
	case WM_SIZE:
	case WM_SYSCOMMAND:
		{
			if (GetWindowLong(hwnd, GWL_EXSTYLE) & WS_EX_MDICHILD) {
				LRESULT status = DefMDIChildProc(hwnd, message, wParam, lParam);

				// chain to dialog function
				LRESULT (__stdcall *dialogFunc)(HWND, UINT, WPARAM, LPARAM) =
					(LRESULT (__stdcall *)(HWND, UINT, WPARAM, LPARAM))
						GetWindowLongPtr(hwnd, DWL_DLGPROC);
				if (dialogFunc) {
					dialogFunc(hwnd, message, wParam, lParam);
				}
				
			} else {
				return DefDlgProc(hwnd, message, wParam, lParam);
			}
		}
		break;
	case WM_DESTROY:
		if (GlobalFlags(dfi) != GMEM_INVALID_HANDLE)
			GlobalFree(dfi);
		break;
	//case WM_WINDOWPOSCHANGED:
	//case WM_SIZE:

		break;
	default:
		return DefDlgProc(hwnd, message, wParam, lParam);
	}
	return 0;
}


/** Creates dockable frame with appropriate flags.

*/
HWND DockFrame_Create(HWND parent, LPTSTR title, DWORD style, DWORD styleEx, int x,int y, int width,int height, int id, LRESULT (__stdcall *dialogFunc)(HWND, UINT, WPARAM, LPARAM) )
{
	/*HWND hwnd = CreateWindowEx(
		DockFrameExStyleChild, //DockFrameExStylePopup,
		DockFrameClass, title,
		DockFrameStyleChild, //DockFrameStylePopup,
		x,y, width, height,
		parent, nullptr, GetModuleHandle(nullptr), dialogFunc);
		*/

	if (parent != nullptr && !(style & WS_POPUP)) style |= WS_CHILD;
	HWND hwnd = CreateWindowEx(
		WS_EX_TOPMOST | styleEx | DockFrameStyleExChild, //DockFrameStylePopup,
		DockFrameClass, title,
		style | DockFrameStyleChild, //DockFrameExStylePopup,
		x,y, width, height,
		parent, nullptr, GetModuleHandle(nullptr), nullptr);

	if (hwnd != nullptr) {
		//if (docked...) {
		//SetWindowLong(hwnd, GWL_STYLE, DockFrameStyleChild);
		//SetWindowLong(hwnd, GWL_EXSTYLE, DockFrameExStyleChild);
		//SetParent(hwnd, parent);
		//SetWindowPos(hwnd, HWND_TOP, x,y, width,height, SWP_SHOWWINDOW|SWP_NOACTIVATE|SWP_NOZORDER|SWP_NOSIZE|SWP_NOMOVE);
		//SetWindowPos(hwnd, HWND_TOP, x,y, width,height, SWP_SHOWWINDOW|SWP_NOACTIVATE|SWP_NOZORDER);
		//SetWindowPos(hwnd, HWND_TOPMOST, 0,0, 0,0, SWP_NOACTIVATE|SWP_NOSIZE|SWP_NOMOVE); <- why does this not work for children >:-|
		if (dialogFunc) {
			SetWindowLongPtr(hwnd, DWL_DLGPROC, (LONG)(LONG_PTR)dialogFunc);
			dialogFunc(hwnd, WM_INITDIALOG, 0, 0);
		}
	}	
	return hwnd;
}


//static BOOL CALLBACK AlignToWindow(HWND hwnd, LPARAM lParam) // for enumchildwindows
static void AlignToWindow(HWND hwnd)
{
	RECT rect;
	GetWindowRect(hwnd, &rect);
	int distance;

	if (!IsWindowVisible(hwnd)
	||  hwnd == Dfa.self)
	{
		return;
	}
	//return;

	if (rect.top - Dfa.rect.bottom <= DockFrame_AlignmentMinDistance
	&&  Dfa.rect.top - rect.bottom <= DockFrame_AlignmentMinDistance)
	{
		// align left to left
		distance = abs(Dfa.rect.left - rect.left);
		if (distance < Dfa.distance.x) {
			Dfa.pos.x = rect.left;
			Dfa.distance.x = distance;
		}
		// align left to right
		distance = abs(Dfa.rect.left - rect.right);
		if (distance < Dfa.distance.x) {
			Dfa.pos.x = rect.right;
			Dfa.distance.x = distance;
		}
		// align right to right
		distance = abs(Dfa.rect.right - rect.right);
		if (distance < Dfa.distance.x) {
			Dfa.pos.x = rect.right
				- (Dfa.rect.right - Dfa.rect.left);
			Dfa.distance.x = distance;
		}
		// align right to left
		distance = abs(Dfa.rect.right - rect.left);
		if (distance < Dfa.distance.x) {
			Dfa.pos.x = rect.left
				- (Dfa.rect.right - Dfa.rect.left);
			Dfa.distance.x = distance;
		}
	}
	if (rect.left - Dfa.rect.right <= DockFrame_AlignmentMinDistance
	&&  Dfa.rect.left - rect.right <= DockFrame_AlignmentMinDistance)
	{
		// align top to top
		distance = abs(Dfa.rect.top - rect.top);
		if (distance < Dfa.distance.y) {
			Dfa.pos.y = rect.top;
			Dfa.distance.y = distance;
		}
		// align top to bottom
		distance = abs(Dfa.rect.top - rect.bottom);
		if (distance < Dfa.distance.y) {
			Dfa.pos.y = rect.bottom;
			Dfa.distance.y = distance;
		}
		// align bottom to bottom
		distance = abs(Dfa.rect.bottom - rect.bottom);
		if (distance < Dfa.distance.y) {
			Dfa.pos.y = rect.bottom
				- (Dfa.rect.bottom - Dfa.rect.top);
			Dfa.distance.y = distance;
		}
		// align bottom to top
		distance = abs(Dfa.rect.bottom - rect.top);
		if (distance < Dfa.distance.y) {
			Dfa.pos.y = rect.top
				- (Dfa.rect.bottom - Dfa.rect.top);
			Dfa.distance.y = distance;
		}
	}
}
