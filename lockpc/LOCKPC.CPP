/*
File: lockpc.cpp
Author: Dwayne Robinson
Date: 2005-10-11
Since: 2005-10-11
Description: Main UI

Log:
2005-10-23	Added 'L' key and Lock item to system menu.
*/

#include "lockpc.h"
#include "resource.h"

extern "C" {
namespace {

#define ProgramClass   T("LockPcClass")
#define ProgramTitle   T("Lock PC")
#define MainWindowClassName   ProgramClass
#define LockWindowClassName   T("LockedPcClass")
#define ProgramDesktop T("MyDesktop2")	// New desktop name

////////////////////////////////////////////////////////////////////////////////

HWND MainHwnd = NULL;

WNDCLASS MainWindowClass = {
	CS_CLASSDC, //style
	(WNDPROC)MainWindowProc, //lpfnWndProc
	0, //cbClsExtra
	DLGWINDOWEXTRA, //cbWndExtra=0;
	(HINSTANCE)0, //hInstance
	0, //hIcon
	0, //hCursor
	(COLOR_BTNFACE + 1), //hbrBackground (HBRUSH)
	0, //lpszMenuName
	ProgramClass //lpszClassName
};
WNDCLASS LockWindowClass = {
	CS_CLASSDC, //style
	(WNDPROC)LockWindowProc, //lpfnWndProc
	0, //cbClsExtra
	0, //cbWndExtra=0 | DLGWINDOWEXTRA;
	(HINSTANCE)0, //hInstance
	0, //hIcon
	0, //hCursor
	0, //hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1)
	0, //lpszMenuName
	LockWindowClassName //lpszClassName
};

#define HotKeyID 100
int HotKeyCode = 'Z';

typedef struct _MY_THREAD_DATA
{
	// Data used by Library. Don't change order !
	struct _THREAD_DATA td;

	// Add here data for your thread
	char  szMsg[100];
} MY_THREAD_DATA;

MY_THREAD_DATA td;

////////////////////////////////////////////////////////////////////////////////

/*****************************************
 * Program entry point.                  *
 *****************************************/
int WINAPI WinMain(HINSTANCE hInstance, 
                   HINSTANCE hPrevInstance, 
                   LPSTR lpCmdLine, 
                   int nCmdShow)
{
    MSG						msg;		// MSG struct for message loop
   	//INITCOMMONCONTROLSEX	icc;		// Struct for common controls (property pages) initialization
	//PROPSHEETHEADER			psh;		// Property sheet header struct
	//PROPSHEETPAGE			psp[2];		// Property page struct
	//HWND					hControl;	// Property sheet control handle 


	// Initialize common control for propoerty sheets
	//icc.dwSize = sizeof(INITCOMMONCONTROLSEX);
	//icc.dwICC = ICC_BAR_CLASSES;
	//InitCommonControlsEx(&icc);

	// Create page 0
	//ZeroMemory(&psp[0], sizeof(PROPSHEETPAGE));
	//psp[0].dwSize = sizeof(PROPSHEETPAGE);
	//psp[0].hInstance = hInstance;
	//psp[0].pszTemplate = MAKEINTRESOURCE(IDD_HIDE);
	//psp[0].pfnDlgProc = PageProc;

	// Create page 1
	//ZeroMemory(&psp[1], sizeof(PROPSHEETPAGE));
	//psp[1].dwSize = sizeof(PROPSHEETPAGE);
	//psp[1].hInstance = hInstance;
	//psp[1].pszTemplate = MAKEINTRESOURCE(IDD_KEYS);
	//psp[1].pfnDlgProc = PageProc;

	// Create control
	//ZeroMemory(&psh, sizeof(PROPSHEETHEADER));
	//psh.dwSize = sizeof(PROPSHEETHEADER);
	//psh.dwFlags = PSH_PROPSHEETPAGE | PSH_MODELESS | PSH_NOAPPLYNOW | 0x02000000; // | PSH_NOCONTEXTHELP;
	//psh.hInstance = hInstance;
	//psh.pszCaption = "WinLock";
	//psh.nPages = 2;
	//psh.ppsp = (LPCPROPSHEETPAGE) &psp;

	//hControl = (HWND)PropertySheet(&psh);

	// Main loop
	WinMainInit();
	while (GetMessage(&msg, NULL, 0, 0) > 0)
	{
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
	WinMainFree();

	ExitProcess(0);
	return 0;
}

 
void WinMainInit()
{
    // main window
	HMODULE hInstance = GetModuleHandle(NULL);
	MainWindowClass.hInstance = hInstance;

	MainWindowClass.hIcon = LoadIcon(hInstance, (LPTSTR)1);
	LockWindowClass.hCursor = LoadCursor(hInstance, (LPTSTR)1);

	RegisterClassOrAbort(&MainWindowClass);
	RegisterClassOrAbort(&LockWindowClass);
	CreateWindowEx(0,
		ProgramClass,
		ProgramTitle,
		WS_POPUP|WS_SYSMENU|WS_CAPTION|WS_MINIMIZEBOX,
		//WS_MINIMIZEBOX|WS_POPUP|WS_MAXIMIZEBOX|WS_MAXIMIZE|WS_VISIBLE|WS_SYSMENU|WS_SIZEBOX| WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
		//WS_MINIMIZEBOX|WS_POPUP|WS_MAXIMIZEBOX|WS_MAXIMIZE|WS_VISIBLE|WS_SYSMENU| WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
		0,0, 200,100,
		NULL,
		NULL,
		hInstance,
		NULL);
	if (!MainHwnd) FatalErrorMessage(T("Failed to create main window"));
	ShowWindow(MainHwnd, SW_MINIMIZE);

	if (!RegisterHotKey(MainHwnd, HotKeyID, MOD_WIN, HotKeyCode))		// Alt+Tab
		FatalErrorMessage(T("Could not register hot key."));

	HMENU hm = GetSystemMenu(MainHwnd, false);
	if (hm != NULL) {
		MENUITEMINFO mii = {
			sizeof(MENUITEMINFO), // UINT    cbSize;  
			MIIM_ID|MIIM_TYPE|MIIM_STATE|MIIM_TYPE, // UINT    fMask; 
			MFT_STRING, // UINT    fType; 
			MFS_ENABLED, // UINT    fState; 
			IDM_LOCK, // UINT    wID; 
			NULL, // HMENU   hSubMenu; 
			NULL, // HBITMAP hbmpChecked; 
			NULL, // HBITMAP hbmpUnchecked; 
			0, // DWORD   dwItemData; 
			T("&Lock"), // LPTSTR  dwTypeData; 
			0 // UINT    cch; 
		};
		InsertMenuItem(hm, 0,true, &mii);
	}

	strcpy(td.td.szDesktopName, ProgramDesktop);
	strcpy(td.szMsg, "Message from new desktop !");
}


void RegisterClassOrAbort(WNDCLASS* pwc)
{
	if (!RegisterClass(pwc)) {
		TCHAR text[256];
		wsprintf(text,
			T("Failed to register window class:\n%hs\n\n")
			T("The program will probably not work right and should abort.\n"),
			pwc->lpszClassName);
		//if (MessageBox (0, text, ProgramTitle, MB_OKCANCEL|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL) != IDOK)
		MessageBox(0, text, ProgramTitle, MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
		ExitProcess(-1);
	}
}



void WinMainFree()
{
	UnregisterHotKey(MainHwnd, HotKeyID);
	DestroyWindow(MainHwnd); // just in case
}


void FatalErrorMessage(TCHAR* msg)
{
	MessageBox(NULL, msg, "Fatal error starting program", MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
	ExitProcess(-1);
}


/**************************************************
 * Callback function that handles the messages    *
 * for the window.                                *
 **************************************************/
BOOL CALLBACK MainWindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    //RECT	r;
    //int		width, height, cx, cy;
	//UINT	state;

	// Handle messages to the property page
	switch (uMsg) {
	case WM_CREATE:
		MainHwnd = hwnd;
		return 0;

	case WM_HOTKEY:
		// Initialize thread data block
		Thread_Desktop(MyThread, (THREAD_DATA *)&td);
		break;

	case WM_KEYDOWN:
		if (wParam == 'Z') PostQuitMessage(0);
		if (wParam == 'L') Thread_Desktop(MyThread, (THREAD_DATA *)&td);
		break;

	case WM_DESTROY:
		MainHwnd = NULL;
		PostQuitMessage(0);
		break;

	// Notification messages from controls
    case WM_SYSCOMMAND:
		switch(LOWORD(wParam)) {
		case IDM_LOCK:
			Thread_Desktop(MyThread, (THREAD_DATA *)&td);
			break;

		/*
		case IDC_DESKTOP:
			state = IsDlgButtonChecked(hWnd, IDC_DESKTOP);
			if (!Desktop_Show_Hide(state == BST_UNCHECKED))  
			CheckDlgButton(hWnd, IDC_DESKTOP, state == BST_CHECKED ? BST_UNCHECKED : BST_CHECKED);
			break;
		*/
		}
		//break; // fall through

	default:
		return DefWindowProc(hwnd, uMsg, wParam, lParam);
	}

	return 0;
}


/**************************************************
 * Callback function that handles the messages    *
 * for the window.                                *
 **************************************************/
BOOL CALLBACK LockWindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    //RECT	r;
    //int		width, height, cx, cy;
	//UINT	state;

	// Handle messages to the property page
	switch (uMsg) {
	case WM_CREATE:
		return 0;

	case WM_KEYDOWN:
		if (wParam == 'Z') PostMessage(hwnd, WM_CLOSE, 1234567890,0);
		break;

	case WM_CLOSE:
		// only allow close if special sentinel value
		// included; otherwise some other method was attempted?
		if (wParam == 1234567890)
			return DefWindowProc(hwnd, uMsg, wParam, lParam);
		else
			return 0;

	case WM_DESTROY:
		PostQuitMessage(0);
		break;

	/*
	case WM_TIMER:
		// animate little character
		break;
	*/

	default:
		return DefWindowProc(hwnd, uMsg, wParam, lParam);
	}

	return 0;
}



/***************************************
 * Run this thread in the new desktop. *
 ***************************************/
DWORD WINAPI MyThread(LPVOID lpParameter)
{
	SetThreadDesktop(((MY_THREAD_DATA *)lpParameter)->td.hDesk);

	RECT rect;
	rect.right  = GetSystemMetrics(SM_CXSCREEN);
	rect.bottom = GetSystemMetrics(SM_CYSCREEN);

	HWND LockHwnd = CreateWindowEx(WS_EX_TRANSPARENT,
		LockWindowClassName,
		ProgramTitle,
		WS_POPUP|WS_VISIBLE|WS_SYSMENU,
		//WS_MINIMIZEBOX|WS_POPUP|WS_MAXIMIZEBOX|WS_MAXIMIZE|WS_VISIBLE|WS_SYSMENU|WS_SIZEBOX| WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
		//WS_MINIMIZEBOX|WS_POPUP|WS_MAXIMIZEBOX|WS_MAXIMIZE|WS_VISIBLE|WS_SYSMENU| WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
		0,0, rect.right,rect.bottom,
		NULL,
		NULL,
		GetModuleHandle(NULL),
		NULL
	);
	if (!LockHwnd) {
		MessageBeep(MB_ICONHAND);
		return -1;
	}
	SetForegroundWindow(LockHwnd);

	//MessageBeep(MB_ICONASTERISK);
	//MessageBeep(MB_ICONEXCLAMATION);
	

	MSG msg;
	while (GetMessage(&msg, NULL, 0, 0))
	{
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	//MessageBox(NULL, ((MY_THREAD_DATA *)lpParameter)->szMsg, "Desktop", MB_OK);

	return 0;
}



/******************************
 * Create and start a thread. *
 ******************************/
BOOL StartThread(LPTHREAD_START_ROUTINE ThreadFunc, THREAD_DATA *td)
{
	ULONG	tid;
	HANDLE	hThread;

	// Create and start thread
	hThread = CreateThread(NULL,
						   0,
						   ThreadFunc,
						   td,
						   0,
						   &tid);

	if (!hThread)
		return FALSE;

	// Wait until thread terminates
	WaitForSingleObject(hThread, INFINITE);

	CloseHandle(hThread);

	return TRUE;

}


/************************************************
 * Create a new Desktop and run a Thread in it. *
 * (Win NT+).                                   *
 ************************************************/
int WINAPI Thread_Desktop(LPTHREAD_START_ROUTINE ThreadFunc, THREAD_DATA *td)
{
	HDESK	hOriginalThread;
	HDESK	hOriginalInput;
	HDESK	hNewDesktop;

	// Save original ...
	hOriginalThread = GetThreadDesktop(GetCurrentThreadId());
	hOriginalInput = OpenInputDesktop(0, FALSE, DESKTOP_SWITCHDESKTOP);

	// Create a new Desktop and switch to it
	hNewDesktop = CreateDesktop(td->szDesktopName, NULL, NULL, 0, GENERIC_ALL, NULL);
	SetThreadDesktop(hNewDesktop);
	SwitchDesktop(hNewDesktop);

	// Execute thread in new desktop
	td->hDesk = hNewDesktop;
	StartThread(ThreadFunc, td);

	// Restore original ...
	SwitchDesktop(hOriginalInput);
	SetThreadDesktop(hOriginalThread);

	// Close the Desktop
	CloseDesktop(hNewDesktop);

	return 0;
}

}; // namespace
}; // extern C
