/*
File: lockpc.h
Author: Dwayne Robinson
Date: 2005-10-11
Since: 2005-10-11
Description: Header for main UI
*/

#define WIN32_LEAN_AND_MEAN
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

////////////////////////////////////////////////////////////////////////////////

typedef struct _THREAD_DATA
{
	HDESK hDesk;
	TCHAR szDesktopName[20];
} THREAD_DATA;

////////////////////////////////////////////////////////////////////////////////

extern "C" {
void WinMainInit();
void WinMainFree();
void FatalErrorMessage(TCHAR* msg);
void RegisterClassOrAbort(WNDCLASS* wc);
BOOL CALLBACK MainWindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
BOOL CALLBACK LockWindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

DWORD WINAPI MyThread(LPVOID lpParameter);
BOOL StartThread(LPTHREAD_START_ROUTINE ThreadFunc, THREAD_DATA *td);
int WINAPI Thread_Desktop(LPTHREAD_START_ROUTINE ThreadFunc, THREAD_DATA *td);
}

////////////////////////////////////////////////////////////////////////////////

#ifdef UNICODE
#define T(string) L##string
#else
#define T(string) string
#endif
