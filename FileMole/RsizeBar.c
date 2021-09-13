#include "resource.h"
#include "filemole.h"

#ifdef MYDEBUG
extern void debugwrite(char* Message, ...);
#else
#define debugwrite //
#endif

static int __stdcall ResizeBarProc(HWND hwnd, UINT message, long wParam, long lParam);
static int __stdcall SendCommand(unsigned int code);
static BOOL __stdcall SetTrack();


WNDCLASSW wcResizeBar = {
	CS_HREDRAW|CS_VREDRAW, //style
	(WNDPROC)ResizeBarProc, //lpfnWndProc
	0, //cbClsExtra
	0, //cbWndExtra=0;
	ProgMemBase, //hInstance
	NULL, //hIcon
	NULL, //hCursor
	NULL, //hbrBackground
	NULL, //lpszMenuName
	L"ResizeBar" //lpszClassName
};

// shared vars
HCURSOR CursorHorz;
HCURSOR CursorVert;
RECT rect;

// private vars
static HWND self;
static RSZN_ITEM *rszi;
static RSZN_ITEM DefaultRi = {0,0,0};
static POINT cpos;	//click pos offset
static BOOL moved;	//mouse moved during drag

static int __stdcall ResizeBarProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	self=hwnd;
	rszi=(RSZN_ITEM*)GetWindowLong(hwnd, GWL_USERDATA);
	//debugwrite("lan  msg=%X w=%X l=%X", message, wParam, lParam);
    switch (message) {
    case WM_CREATE:
		CursorHorz=LoadCursor(ProgMemBase,(LPTSTR)32644);//IDC_SIZENS);
		CursorVert=LoadCursor(ProgMemBase,(LPTSTR)32645);
		// set to structure pointed to by lParam if passed
		SetWindowLong(hwnd, GWL_USERDATA, (lParam) ? 
			(long)((CREATESTRUCT*)lParam)->lpCreateParams : (long)&DefaultRi);
		return FALSE;
	case WM_SETCURSOR:
		SetCursor(
			(GetWindowLong(hwnd, GWL_STYLE) & SBS_VERT)
			? CursorVert : CursorHorz);
		return FALSE;
		//if (lParam & 0xFFFF != HTCLIENT) goto DoDefWndProc;
	case WM_ERASEBKGND:
		return TRUE;
	case WM_PAINT:
		{
		PAINTSTRUCT ps;
		BeginPaint(hwnd, &ps);
		GetClientRect(hwnd, &rect);
		DrawEdge(ps.hdc,&rect, BDR_SUNKENOUTER|BDR_RAISEDINNER, BF_RECT);
		EndPaint(hwnd, &ps);
		return 0;
		}
	//case RSZM_SET:
	//	SetWindowLong(hwnd, GWL_USERDATA, (lParam) ? lParam : (long)&DefaultRi);
	//	return 0;
	case WM_LBUTTONDOWN:
		SetCapture(hwnd);
		DefaultRi.min = rszi->min;
		DefaultRi.max = rszi->max;
		cpos.x=lParam & 0xFFFF;
		cpos.y=lParam >> 16;
		SetTrack();
		moved=FALSE;
		debugwrite("rsz start t=%d ri=%X", rszi->track, rszi);
		SendCommand(RSZN_START);
		return 0;
	case WM_MOUSEMOVE:
		if (GetCapture()==hwnd) {
			moved=TRUE;
			if (SetTrack()) {
				SendCommand(RSZN_SIZE);
				//debugwrite("rsz move t=%d ri=%X n=%d x=%d", rszi->track, rszi, rszi->min, rszi->max);
			}
		}
		return 0;
	case WM_LBUTTONUP:
		if (GetCapture()==hwnd) {
			SetTrack();
			if (moved) {
				debugwrite("rsz stop t=%d", rszi->track);
				SendCommand(RSZN_STOP);
				moved=FALSE;
			} else {
				debugwrite("rsz click t=%d", rszi->track);
				SendCommand(RSZN_CLICK);
			}
			ReleaseCapture();
		}
		return 0;
	case WM_CAPTURECHANGED:
		// do something here...
		return 0;
	default:
		return DefWindowProc(hwnd, message, wParam, lParam);
	}
}

// Purpose:
//	Sends command msg to parent.
//
// Note:
//	code is already left shifted 16 bits by definition.
static int __stdcall SendCommand(unsigned int code)
{
	return SendMessage(GetParent(self), WM_COMMAND, 
		GetDlgCtrlID(self) | code, 
		(LPARAM)&DefaultRi);
}

// Purpose:
//	Sets the track variable in the resize structure.
//	Limits it between and min and max.
//
// Assumes:
//	self is the current window handle
//	rzsi is the resize structure ptr
//
// Returns:
//	true if bar moved/track changed
static BOOL __stdcall SetTrack()
{
	POINT mpos; //mouse pos
	register int track;

	GetCursorPos(&mpos);
	ScreenToClient(GetParent(self), &mpos);
	if (GetWindowLong(self, GWL_STYLE) & SBS_VERT) {
		track = mpos.x-cpos.x;
	} else { // horizontal
		track = mpos.y-cpos.y;
	}
	if (track > rszi->max) track=rszi->max;
	if (track < rszi->min) track=rszi->min;
	if (track != rszi->track) {
		rszi->track=track;
		return TRUE;
	}
	return false;
}