#if !defined(MYDEBUG) && defined(MYDEBUGLIST)
#define MYDEBUG
#endif

#ifdef MYDEBUG

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
#define _X86_

#include <excpt.h>
#include <stdarg.h>
#include <windef.h>
#include <winbase.h>
#include <wingdi.h>
#include <winuser.h>

#ifdef UNICODE
  #define T(quote) L##quote
#else
  #define T
#endif


void debuginit();
void debugwrite(char* Message, ...);
void debugerror();
void debugflush();
void debugfinish();
char debugwrite_Buffer[256];

#ifdef MYDEBUGLIST
HWND DbgHwnd;
#endif

// create debug window
void debuginit() {
  #ifdef MYDEBUGLIST
	LOGFONT lf = {12,0, 0,0,
		FW_NORMAL, 0,0,0,
		DEFAULT_CHARSET, OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,PROOF_QUALITY,
		FF_DONTCARE, L"Small Fonts"};
	HINSTANCE hi = GetModuleHandle(NULL);
	DbgHwnd=CreateWindowEx(WS_EX_NOPARENTNOTIFY|WS_EX_CLIENTEDGE|WS_EX_TOOLWINDOW|WS_EX_APPWINDOW, //WS_EX_TOPMOST|
		L"LISTBOX",
		L"Debug window",
		WS_SIZEBOX|WS_CAPTION|WS_SYSMENU|WS_VSCROLL|LBS_HASSTRINGS,
		640,0, 160,400,
		NULL,
		NULL,
		hi,
		NULL);
	SetWindowPos(DbgHwnd,NULL,0,0,0,0,SWP_NOSIZE|SWP_NOMOVE|SWP_NOZORDER|SWP_NOACTIVATE|SWP_SHOWWINDOW);
	//SendMessage(DbgHwnd, WM_SETFONT, (WPARAM)GetStockObject(DEFAULT_GUI_FONT), (LPARAM)false);
	SendMessageA(DbgHwnd, WM_SETFONT, (WPARAM)CreateFontIndirect(&lf), (LPARAM)FALSE);
	SendMessageA(DbgHwnd, WM_SETICON, (WPARAM)FALSE, (LPARAM)LoadIcon(hi, (LPTSTR)1));
	SendMessageA(DbgHwnd, WM_SETICON, (WPARAM)FALSE, (LPARAM)NULL);
  #endif
}

// write formatted debug string for debugger to catch
void debugwrite(char* Message, ...)
{
	int strlen;

	//wvsprintf((LPTSTR)Buffer, Message, (va_list)(&Message)+4);
	wvsprintfA((LPSTR)debugwrite_Buffer, (LPSTR)Message, (char*)((&Message)+1));
	strlen=lstrlenA((LPSTR)debugwrite_Buffer);
	debugwrite_Buffer[strlen]='\n';
	debugwrite_Buffer[strlen+1]='\0';
	OutputDebugStringA((LPSTR)debugwrite_Buffer);

  #ifdef MYDEBUGLIST
	debugwrite_Buffer[strlen]='\0';
	if (DbgHwnd) {
		int index = SendMessageA(DbgHwnd, LB_INSERTSTRING, -1, (LPARAM)debugwrite_Buffer);		
		if (index == LB_ERRSPACE)
			SendMessageA(DbgHwnd, LB_RESETCONTENT, 0,0);
		else
			SendMessageA(DbgHwnd, LB_SETCURSEL, index, FALSE);
	}
  #endif
}

// print function's return value and GetLastError()
// this MUST be called immediately after the tested
// function if you don't want the eax register to be
// trashed and show a garbage result.
void debugerror()
{
	unsigned int success; //return value
	__asm {
		mov success,eax	// save function's return value in variable
	}
	debugwrite("lasterr=%d ret=%d %Xh", GetLastError(), success,success);
}

// flushes any debug output before proceding
//
// !only to be called by main thread, otherwise will do nothing
//
// Necessary because of some multithreading issues I found later
// where a different thread than the one which created the debug
// window calls debugwrite. In that case, the user system halts
// the calling thread and waits for primary thread to call GetMessage.
// However, if the main thread is already waiting on the other thread
// for any reason, you have dead lock >_<
void debugflush() {
  #ifdef MYDEBUGLIST
	MSG msg;

	Sleep(0); //yield timeslice to other threads
	while (PeekMessage(&msg, DbgHwnd, 0,0, PM_REMOVE)>0)
		DispatchMessage(&msg);
	Sleep(0); //yield timeslice to other threads once more
  #endif
}

// destroys debug window if one was created
void debugfinish() {
  #ifdef MYDEBUGLIST
	debugflush();
	DestroyWindow(DbgHwnd);
  #endif
}

#endif