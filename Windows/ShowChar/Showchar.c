// 20021223 Show Character
// Dwayne Robinson

#define WIN32_LEAN_AND_MEAN
#define NO_STRICT
#define WINVER 0x0400
#include <windows.h>
#include <commdlg.h>
#include "showchar.h"

int __stdcall WndProc(HWND hwnd, UINT message, long wParam, long lParam);
void __stdcall FatalErrorMessage(char* Message);
void DebugWrite(char* Message, ...);

////////////////////////////////////////////////////////////////////////////////

HWND MainHwnd;
HFONT CurLfh;
unsigned short CurLetter=12353;//65;
MSG msg;
WNDCLASS wc = {
	CS_CLASSDC, //style
	(WNDPROC)WndProc, //lpfnWndProc
	0, //cbClsExtra
	0, //cbWndExtra=0;
	(HINSTANCE)ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	COLOR_BTNFACE + 1, //hbrBackground
	(char*)1, //lpszMenuName
	ProgClass //lpszClassName
};
LOGFONT lf = {
	40, //height
	0,
	0,
	0,
	FW_DONTCARE, //weight
	FALSE, //italic
	FALSE, //underline
	FALSE, //strikeout
	SHIFTJIS_CHARSET,
	//MAC_CHARSET,
	//RUSSIAN_CHARSET,
	OUT_TT_PRECIS,
	CLIP_DEFAULT_PRECIS,
	DEFAULT_QUALITY,
	DEFAULT_PITCH|FF_DONTCARE,
	"MS Gothic"
};
CHOOSEFONT cf = {
	sizeof(CHOOSEFONT),
	NULL, //owner
	NULL, //printer dc
	&lf,
	40, //point size
	CF_SCREENFONTS|CF_INITTOLOGFONTSTRUCT, //flags
	0, //no color
	0, //no custom data
	NULL, //no hook
	NULL, //no template
	NULL, //no instance ptr
	NULL, //no style
	0, //font type
	0, //no minimum
	0 //no maximum
};


////////////////////////////////////////////////////////////////////////////////

int APIENTRY WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int cmdShow)
{
	//wc.hInstance=hinstance;
	wc.hIcon=LoadIcon(ProgMemBase,(LPSTR)1);
    wc.hCursor=LoadCursor(0,IDC_ARROW);

    if (!RegisterClass(&wc)) FatalErrorMessage("Failed to register window class");

	CreateWindowEx(WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT|WS_EX_CLIENTEDGE,
        ProgClass,
        ProgTitle,
        WS_MINIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME|WS_MAXIMIZE|WS_VSCROLL,
        0,0, 800,600-32,
        NULL,
        NULL,
        ProgMemBase,
        NULL);
	if (!MainHwnd) FatalErrorMessage("Failed to create main window");

	{
	HDC hdc=GetDC(MainHwnd);
	CurLfh = CreateFontIndirect(&lf);
	SelectObject(hdc, CurLfh);
	SetBkColor(hdc, GetSysColor(COLOR_BTNFACE));
	//SetBkMode(ps.hdc, TRANSPARENT);
	}

	cf.hwndOwner=MainHwnd;

	while(GetMessage(&msg, 0, 0,0)>0)
	{
		//if (!TranslateAccelerator(MainHwnd, MainKeyAcl, &msg))
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
	DeleteObject(CurLfh);

	return 0;
}


int __stdcall WndProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	int LetterDif;
	char WindowCaption[80];

    switch (message) {
	case WM_COMMAND:
		wParam &= 0x0000FFFF;
		switch (wParam)
		{
		case IDCLOSE:
			DestroyWindow(hwnd);
			break;
		case IDOK:
			if (ChooseFont(&cf)) {
				HFONT NewLfh;
				NewLfh = CreateFontIndirect(&lf);
				DeleteObject(
					SelectObject(
						GetDC(MainHwnd),
						NewLfh));
				CurLfh=NewLfh;
				InvalidateRect(MainHwnd, NULL, TRUE);
			}
			break;
		case IDHELP:
			MessageBox(hwnd, TextAbout, ProgTitle, MB_ICONINFORMATION);
			break;
		}
		return 0;
    case WM_CREATE:
		//Recalculate the size of all variables
		//and fill with x,y,height,width values
		//Then create each window
		//HWND txtFilePath = 
		MainHwnd=hwnd;
		SetScrollRange(MainHwnd, SB_VERT, 0,65535, FALSE);
		SetScrollPos(MainHwnd, SB_VERT, CurLetter, FALSE);
		return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
	case WM_WINDOWPOSCHANGED:
	case WM_WINDOWPOSCHANGING:
		return 0;
	case WM_VSCROLL:
		switch (wParam & 0xFFFF) {
		case SB_LINEUP: LetterDif = -1; break;
		case SB_LINEDOWN: LetterDif = 1; break;
		case SB_PAGEUP: LetterDif = -16; break;
		case SB_PAGEDOWN: LetterDif = 16; break;
		case SB_TOP: CurLetter = 0; goto SetCurLetter;
		case SB_BOTTOM: CurLetter = 65535; goto SetCurLetter;
		case SB_THUMBTRACK: CurLetter=(unsigned long)wParam >> 16; goto SetCurLetter;
		default:
			return 0;
		}
		goto SetCurLetterDif;
	case WM_PAINT:
	{
		//print font character
		unsigned short LetterRow[16];
		unsigned int row, count;
		PAINTSTRUCT ps;
		//RECT rect;
		BeginPaint(hwnd, &ps);
		for (row=0; row < 16; row++) {
			for (count=0; count<16; count++) LetterRow[count] = CurLetter+(row<<4)+count;
			TextOutW(ps.hdc, 0,row*50, (LPWSTR)&LetterRow, 16);
		}
		//GetClientRect(hwnd, &rect);
		EndPaint(hwnd, &ps);
		return FALSE;
	}
	//case WM_ERASEBKGND:
	//	return FALSE;
	case WM_KEYDOWN:
		switch (wParam) {
		case VK_LEFT: LetterDif = -1; break;
		case VK_RIGHT: LetterDif = 1; break;
		case VK_UP: LetterDif = -16; break;
		case VK_DOWN: LetterDif = 16; break;
		case VK_PRIOR: LetterDif = -128; break;
		case VK_NEXT: LetterDif = 128; break;
		case VK_HOME: CurLetter = 0; goto SetCurLetter;
		case VK_END: CurLetter = 65535; goto SetCurLetter;
		default:
			return 0;
		}
SetCurLetterDif:
		CurLetter += LetterDif;
SetCurLetter:
		wsprintf((LPSTR)&WindowCaption, "Show Font Char %d U%X", CurLetter, CurLetter);
		SetScrollPos(MainHwnd, SB_VERT, CurLetter, TRUE);
		DefWindowProc(hwnd, WM_SETTEXT, 0, (LPARAM)&WindowCaption);
		InvalidateRect(MainHwnd, NULL, TRUE);
		return 0;
    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }
}


void __stdcall FatalErrorMessage(char* Message)
{
	MessageBox (0, Message, ProgTitle, MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
	ExitProcess (-1);
}
