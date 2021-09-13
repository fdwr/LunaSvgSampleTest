/**
File: DebugMsg.cpp
Since: 2005-12-02
*/

#ifdef _WINDOWS
#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#include <windows.h>
#endif
#include <stdio.h> 

#include "debugmsg.h"

#ifdef _DEBUG
#include <search.h> // binary search for message mapping
#endif

#define elmsof(element) sizeof(element)/sizeof(element[0])

#pragma warning(disable:4996) // '_snwprintf' was declared deprecated
#pragma warning(disable:4313) // '_snwprintf' : '%X' in format string conflicts with argument # of type 'type'

//#ifdef _DEBUG
//extern void WriteMessage(LPTSTR msg, ...);
//#endif

////////////////////////////////////////////////////////////////////////////////

#ifdef _DEBUG
extern "C" void dbgmsg(TCHAR* msg, ...)
{
	TCHAR text[1024];
	va_list args;
	va_start(args, msg);
	_vsntprintf(text, elmsof(text), msg, args);
	text[1023] = '\0';

	WriteDebugString(text);
	//OutputDebugString(text);
}
#endif

#ifdef _WINDOWS
#ifdef _DEBUG
typedef struct dbgwinmsg_name {
	TCHAR* name;
	int value;
} dbgwinmsg_name;

static dbgwinmsg_name dbgwinmsg_names[] = {
	_T("WM_NULL"), 0x0000,
	_T("WM_CREATE"), 0x0001,
	_T("WM_DESTROY"), 0x0002,
	_T("WM_MOVE"), 0x0003,
	_T("WM_SIZE"), 0x0005,
	_T("WM_ACTIVATE"), 0x0006,
	_T("WM_SETFOCUS"), 0x0007,
	_T("WM_KILLFOCUS"), 0x0008,
	_T("WM_ENABLE"), 0x000A,
	_T("WM_SETREDRAW"), 0x000B,
	_T("WM_SETTEXT"), 0x000C,
	_T("WM_GETTEXT"), 0x000D,
	_T("WM_GETTEXTLENGTH"), 0x000E,
	_T("WM_PAINT"), 0x000F,
	_T("WM_CLOSE"), 0x0010,
	_T("WM_QUERYENDSESSION"), 0x0011,
	_T("WM_QUERYOPEN"), 0x0013,
	_T("WM_ENDSESSION"), 0x0016,
	_T("WM_QUIT"), 0x0012,
	_T("WM_ERASEBKGND"), 0x0014,
	_T("WM_SYSCOLORCHANGE"), 0x0015,
	_T("WM_SHOWWINDOW"), 0x0018,
	_T("WM_SETTINGCHANGE"), 0x001A,
	_T("WM_DEVMODECHANGE"), 0x001B,
	_T("WM_ACTIVATEAPP"), 0x001C,
	_T("WM_FONTCHANGE"), 0x001D,
	_T("WM_TIMECHANGE"), 0x001E,
	_T("WM_CANCELMODE"), 0x001F,
	_T("WM_SETCURSOR"), 0x0020,
	_T("WM_MOUSEACTIVATE"), 0x0021,
	_T("WM_CHILDACTIVATE"), 0x0022,
	_T("WM_QUEUESYNC"), 0x0023,
	_T("WM_GETMINMAXINFO"), 0x0024,
	_T("WM_PAINTICON"), 0x0026,
	_T("WM_ICONERASEBKGND"), 0x0027,
	_T("WM_NEXTDLGCTL"), 0x0028,
	_T("WM_SPOOLERSTATUS"), 0x002A,
	_T("WM_DRAWITEM"), 0x002B,
	_T("WM_MEASUREITEM"), 0x002C,
	_T("WM_DELETEITEM"), 0x002D,
	_T("WM_VKEYTOITEM"), 0x002E,
	_T("WM_CHARTOITEM"), 0x002F,
	_T("WM_SETFONT"), 0x0030,
	_T("WM_GETFONT"), 0x0031,
	_T("WM_SETHOTKEY"), 0x0032,
	_T("WM_GETHOTKEY"), 0x0033,
	_T("WM_QUERYDRAGICON"), 0x0037,
	_T("WM_COMPAREITEM"), 0x0039,
	_T("WM_GETOBJECT"), 0x003D,
	_T("WM_COMPACTING"), 0x0041,
	_T("WM_COMMNOTIFY"), 0x0044,
	_T("WM_WINDOWPOSCHANGING"), 0x0046,
	_T("WM_WINDOWPOSCHANGED"), 0x0047,
	_T("WM_POWER"), 0x0048,
	_T("WM_COPYDATA"), 0x004A,
	_T("WM_CANCELJOURNAL"), 0x004B,
	_T("WM_NOTIFY"), 0x004E,
	_T("WM_INPUTLANGCHANGEREQUEST"), 0x0050,
	_T("WM_INPUTLANGCHANGE"), 0x0051,
	_T("WM_TCARD"), 0x0052,
	_T("WM_HELP"), 0x0053,
	_T("WM_USERCHANGED"), 0x0054,
	_T("WM_NOTIFYFORMAT"), 0x0055,
	_T("WM_CONTEXTMENU"), 0x007B,
	_T("WM_STYLECHANGING"), 0x007C,
	_T("WM_STYLECHANGED"), 0x007D,
	_T("WM_DISPLAYCHANGE"), 0x007E,
	_T("WM_GETICON"), 0x007F,
	_T("WM_SETICON"), 0x0080,
	_T("WM_NCCREATE"), 0x0081,
	_T("WM_NCDESTROY"), 0x0082,
	_T("WM_NCCALCSIZE"), 0x0083,
	_T("WM_NCHITTEST"), 0x0084,
	_T("WM_NCPAINT"), 0x0085,
	_T("WM_NCACTIVATE"), 0x0086,
	_T("WM_GETDLGCODE"), 0x0087,
	_T("WM_SYNCPAINT"), 0x0088,
	_T("WM_NCMOUSEMOVE"), 0x00A0,
	_T("WM_NCLBUTTONDOWN"), 0x00A1,
	_T("WM_NCLBUTTONUP"), 0x00A2,
	_T("WM_NCLBUTTONDBLCLK"), 0x00A3,
	_T("WM_NCRBUTTONDOWN"), 0x00A4,
	_T("WM_NCRBUTTONUP"), 0x00A5,
	_T("WM_NCRBUTTONDBLCLK"), 0x00A6,
	_T("WM_NCMBUTTONDOWN"), 0x00A7,
	_T("WM_NCMBUTTONUP"), 0x00A8,
	_T("WM_NCMBUTTONDBLCLK"), 0x00A9,
	_T("WM_NCXBUTTONDOWN"), 0x00AB,
	_T("WM_NCXBUTTONUP"), 0x00AC,
	_T("WM_NCXBUTTONDBLCLK"), 0x00AD,
	_T("WM_INPUT"), 0x00FF,
	_T("WM_KEYFIRST"), 0x0100,
	_T("WM_KEYDOWN"), 0x0100,
	_T("WM_KEYUP"), 0x0101,
	_T("WM_CHAR"), 0x0102,
	_T("WM_DEADCHAR"), 0x0103,
	_T("WM_SYSKEYDOWN"), 0x0104,
	_T("WM_SYSKEYUP"), 0x0105,
	_T("WM_SYSCHAR"), 0x0106,
	_T("WM_SYSDEADCHAR"), 0x0107,
	_T("WM_UNICHAR"), 0x0109,
	_T("WM_KEYLAST"), 0x0109,
	_T("WM_KEYLAST"), 0x0108,
	_T("WM_IME_STARTCOMPOSITION"), 0x010D,
	_T("WM_IME_ENDCOMPOSITION"), 0x010E,
	_T("WM_IME_COMPOSITION"), 0x010F,
	_T("WM_IME_KEYLAST"), 0x010F,
	_T("WM_INITDIALOG"), 0x0110,
	_T("WM_COMMAND"), 0x0111,
	_T("WM_SYSCOMMAND"), 0x0112,
	_T("WM_TIMER"), 0x0113,
	_T("WM_HSCROLL"), 0x0114,
	_T("WM_VSCROLL"), 0x0115,
	_T("WM_INITMENU"), 0x0116,
	_T("WM_INITMENUPOPUP"), 0x0117,
	_T("WM_MENUSELECT"), 0x011F,
	_T("WM_MENUCHAR"), 0x0120,
	_T("WM_ENTERIDLE"), 0x0121,
	_T("WM_MENURBUTTONUP"), 0x0122,
	_T("WM_MENUDRAG"), 0x0123,
	_T("WM_MENUGETOBJECT"), 0x0124,
	_T("WM_UNINITMENUPOPUP"), 0x0125,
	_T("WM_MENUCOMMAND"), 0x0126,
	_T("WM_CHANGEUISTATE"), 0x0127,
	_T("WM_UPDATEUISTATE"), 0x0128,
	_T("WM_QUERYUISTATE"), 0x0129,
	_T("WM_CTLCOLORMSGBOX"), 0x0132,
	_T("WM_CTLCOLOREDIT"), 0x0133,
	_T("WM_CTLCOLORLISTBOX"), 0x0134,
	_T("WM_CTLCOLORBTN"), 0x0135,
	_T("WM_CTLCOLORDLG"), 0x0136,
	_T("WM_CTLCOLORSCROLLBAR"), 0x0137,
	_T("WM_CTLCOLORSTATIC"), 0x0138,
	_T("WM_MOUSEFIRST"), 0x0200,
	_T("WM_MOUSEMOVE"), 0x0200,
	_T("WM_LBUTTONDOWN"), 0x0201,
	_T("WM_LBUTTONUP"), 0x0202,
	_T("WM_LBUTTONDBLCLK"), 0x0203,
	_T("WM_RBUTTONDOWN"), 0x0204,
	_T("WM_RBUTTONUP"), 0x0205,
	_T("WM_RBUTTONDBLCLK"), 0x0206,
	_T("WM_MBUTTONDOWN"), 0x0207,
	_T("WM_MBUTTONUP"), 0x0208,
	_T("WM_MBUTTONDBLCLK"), 0x0209,
	_T("WM_MOUSEWHEEL"), 0x020A,
	_T("WM_XBUTTONDOWN"), 0x020B,
	_T("WM_XBUTTONUP"), 0x020C,
	_T("WM_XBUTTONDBLCLK"), 0x020D,
	_T("WM_MOUSELAST"), 0x020D,
	_T("WM_MOUSELAST"), 0x020A,
	_T("WM_MOUSELAST"), 0x0209,
	_T("WM_PARENTNOTIFY"), 0x0210,
	_T("WM_ENTERMENULOOP"), 0x0211,
	_T("WM_EXITMENULOOP"), 0x0212,
	_T("WM_NEXTMENU"), 0x0213,
	_T("WM_SIZING"), 0x0214,
	_T("WM_CAPTURECHANGED"), 0x0215,
	_T("WM_MOVING"), 0x0216,
	_T("WM_POWERBROADCAST"), 0x0218,
	_T("WM_DEVICECHANGE"), 0x0219,
	_T("WM_MDICREATE"), 0x0220,
	_T("WM_MDIDESTROY"), 0x0221,
	_T("WM_MDIACTIVATE"), 0x0222,
	_T("WM_MDIRESTORE"), 0x0223,
	_T("WM_MDINEXT"), 0x0224,
	_T("WM_MDIMAXIMIZE"), 0x0225,
	_T("WM_MDITILE"), 0x0226,
	_T("WM_MDICASCADE"), 0x0227,
	_T("WM_MDIICONARRANGE"), 0x0228,
	_T("WM_MDIGETACTIVE"), 0x0229,
	_T("WM_MDISETMENU"), 0x0230,
	_T("WM_ENTERSIZEMOVE"), 0x0231,
	_T("WM_EXITSIZEMOVE"), 0x0232,
	_T("WM_DROPFILES"), 0x0233,
	_T("WM_MDIREFRESHMENU"), 0x0234,
	_T("WM_IME_SETCONTEXT"), 0x0281,
	_T("WM_IME_NOTIFY"), 0x0282,
	_T("WM_IME_CONTROL"), 0x0283,
	_T("WM_IME_COMPOSITIONFULL"), 0x0284,
	_T("WM_IME_SELECT"), 0x0285,
	_T("WM_IME_CHAR"), 0x0286,
	_T("WM_IME_REQUEST"), 0x0288,
	_T("WM_IME_KEYDOWN"), 0x0290,
	_T("WM_IME_KEYUP"), 0x0291,
	_T("WM_MOUSEHOVER"), 0x02A1,
	_T("WM_MOUSELEAVE"), 0x02A3,
	_T("WM_NCMOUSEHOVER"), 0x02A0,
	_T("WM_NCMOUSELEAVE"), 0x02A2,
	_T("WM_WTSSESSION_CHANGE"), 0x02B1,
	_T("WM_TABLET_FIRST"), 0x02C0,
	_T("WM_TABLET_LAST"), 0x02DF,
	_T("WM_CUT"), 0x0300,
	_T("WM_COPY"), 0x0301,
	_T("WM_PASTE"), 0x0302,
	_T("WM_CLEAR"), 0x0303,
	_T("WM_UNDO"), 0x0304,
	_T("WM_RENDERFORMAT"), 0x0305,
	_T("WM_RENDERALLFORMATS"), 0x0306,
	_T("WM_DESTROYCLIPBOARD"), 0x0307,
	_T("WM_DRAWCLIPBOARD"), 0x0308,
	_T("WM_PAINTCLIPBOARD"), 0x0309,
	_T("WM_VSCROLLCLIPBOARD"), 0x030A,
	_T("WM_SIZECLIPBOARD"), 0x030B,
	_T("WM_ASKCBFORMATNAME"), 0x030C,
	_T("WM_CHANGECBCHAIN"), 0x030D,
	_T("WM_HSCROLLCLIPBOARD"), 0x030E,
	_T("WM_QUERYNEWPALETTE"), 0x030F,
	_T("WM_PALETTEISCHANGING"), 0x0310,
	_T("WM_PALETTECHANGED"), 0x0311,
	_T("WM_HOTKEY"), 0x0312,
	_T("WM_PRINT"), 0x0317,
	_T("WM_PRINTCLIENT"), 0x0318,
	_T("WM_APPCOMMAND"), 0x0319,
	_T("WM_THEMECHANGED"), 0x031A,
	_T("WM_HANDHELDFIRST"), 0x0358,
	_T("WM_HANDHELDLAST"), 0x035F,
	_T("WM_AFXFIRST"), 0x0360,
	_T("WM_AFXLAST"), 0x037F,
	_T("WM_PENWINFIRST"), 0x0380,
	_T("WM_PENWINLAST"), 0x038F,
	_T("WM_USER"), 0x0400,
	_T("WM_APP"), 0x8000
};

static int dbgmsgwinname_cmp(const int* elem1, const dbgwinmsg_name* elem2)
{
	//-WriteMessage(T("%d, %d"), *elem1, elem2->value);
	if (*elem1 <  elem2->value) return -1;
	if (*elem1 >  elem2->value) return  1;
	return  0;
};

// returns pointer to constant string name for windows message.
extern "C" TCHAR* dbgmsgwinname(int message)
{
	//-WriteMessage(T("message=%d"), message);
	dbgwinmsg_name* match = (dbgwinmsg_name*)
		bsearch(&message, dbgwinmsg_names, elmsof(dbgwinmsg_names), sizeof(dbgwinmsg_name), (int (__cdecl *)(const void *,const void *))&dbgmsgwinname_cmp);
	if (match == NULL) {
		static TCHAR text[64]; // possible multithreading issue here :-/
		_sntprintf(text, elmsof(text), _T("WM_%04X??"), message);
		return text;
	}
	return match->name;
}

// prints windows message
extern "C" void dbgmsgwin(HWND hwnd, int message, WPARAM wparam, LPARAM lparam)
{
	TCHAR text[1024];
	_sntprintf(text, elmsof(text), _T("h=%X %s w=%d l=%d"), hwnd, dbgmsgwinname(message), wparam, lparam);
	text[1023] = '\0';

	WriteDebugString(text);
	//OutputDebugString(text);
}
#endif
#endif
