//Install the KB hook by passing the handle of the application to be hooked 
//and the address of the KB procedure which will handle all the KB events
if(!ActivateKBHook(hInstance, LLKeyboardHookCallbackFunction))
{
    MessageBox(GetActiveWindow(), 
        TEXT("Couldn't intall hook...Terminating"), 
        TEXT("Warning"), NULL);
    exit(1);
}

//LLKeyboardHookCallbackFunction is the funtion 
//whose address we passed to the system while installing the hook.
//so all the KB events will bring the control to this procedure.
//Here we want that when the user presse left 
//or right key it should be interpreted as an UP key
//so now you can allow the user to configure 
//the key boards the way he/she wants it
LRESULT CALLBACK LLKeyboardHookCallbackFunction( int nCode, 
                              WPARAM wParam, LPARAM lParam ) 
{
    if(((((KBDLLHOOKSTRUCT*)lParam)->vkCode) == VK_LEFT) || 
      ((((KBDLLHOOKSTRUCT*)lParam)->vkCode) == VK_RIGHT))
    {
        //Generate the keyboard press event of the mapped key
        keybd_event(VK_UP, 0, 0, 0); 

        //release the mapped key
        keybd_event(VK_UP, 0, KEYEVENTF_KEYUP, 0); 
    }

    //let default processing take place
    return CallNextHookEx(g_hInstalledLLKBDhook, nCode, wParam, lParam);
}


//we are done with the hook. now uninstall it.
DeactivateKBHook();
1:  Public Function KeyboardCallback(ByVal Code As Long, _
2:    ByVal wParam As Long, ByVal lParam As Long) As Long
3:
4:    Static Hookstruct As KBDLLHOOKSTRUCT
5:
6:    If (Code = HC_ACTION) Then
7:    ' Copy the keyboard data out of the lParam (which is a pointer)
8:      Call CopyMemory(Hookstruct, ByVal lParam, Len(Hookstruct))
9:
10:     If (IsHooked(Hookstruct)) Then
11:       KeyboardCallback = 1
12:       Exit Function
13:     End If
14:
15:   End If
16:
17:   KeyboardCallback = CallNextHookEx(KeyboardHandle, _
18:     Code, wParam, lParam)
19:
20: End Function

Syntax

VOID keybd_event(          BYTE bVk,
    BYTE bScan,
    DWORD dwFlags,
    PTR dwExtraInfo
);
Parameters

bVk
[in] Specifies a virtual-key code. The code must be a value in the range 1 to 254. For a complete list, see Virtual-Key Codes. 
bScan
This parameter is not used. 
dwFlags
[in] Specifies various aspects of function operation. This parameter can be one or more of the following values. 
KEYEVENTF_EXTENDEDKEY
If specified, the scan code was preceded by a prefix byte having the value 0xE0 (224).
KEYEVENTF_KEYUP
If specified, the key is being released. If not specified, the key is being depressed.
dwExtraInfo
[in] Specifies an additional value associated with the key stroke. 






http://www.hpcnec.com/programs/RemapMPCPPfile.cpp

///////////////////////////////////////////////////////////////////////////////////////////////
///               RemapMP - Remap MobilePro Keyboard - ANSI CPP - LEAN AND MEAN             ///
/// Because this app sets a system-wide keyboard hook, this app is optimized for execution  ///
/// speed and code size. As such, there are no classes, just plain old fashioned functions. ///
///                                                                                         ///
/// Author:  Mike Welch, Dallas Texas                                                       ///
/// Contr. : Piotr Gawrysiak, Warsaw Poland
/// Purpose: Remap the MobilePro keyboard using "unsupported" keyboard hooks in WinCE.      ///
/// Notes:   This app exports the hook function within the EXE (no DLL is required).  See   ///
//           the related utilities that I wrote when testing to see if hooks were supported ///
///          in WindowsCE.                                                                  /// 
///                                                                                         ///
///          I've been a Delphi developer since it was in beta, so I've added some newbie   ///
///          notes as I learned eVC++.                                                      ///
/// Source:  (C)opyright 2004-2005 by Mike Welch, all rights reserved; for what I do not    ///
///          know. If you get rich using this source, you have to share :)                  ///
/// Legal:   This app is Open Source and uses the Mike Welch Common Sense Legal Agreement.  ///
/// MWCLSA:  By involving yourself with this project in any way you agree not to sue anyone ///
///          involved with this project for any reason.                                     ///
///                                                                                         ///
///          CONTRIBUTORS: You are required to send to me any updates you have produced     ///
///          using this source so that others may benefit from it too (this probably goes   ///
///          without saying).  In the unlikely event this becomes worked on by several      ///
///          people, we'll give it a sourceforge home.  Until then, I'm the ReMap Czar.     ///
///                                                                                         ///
///          - Mike Welch                                                                   ///
///                                                                                         ///
///                                    _________________                                    ///
///                                                                                         ///
///                        "Freely you have been given, freely give"                        ///
///                        -El Yeshua Immanuel                                              /// 
///                                                                                         ///
///////////////////////////////////////////////////////////////////////////////////////////////

mwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmw
mw    B R I E F   V E R S I O N   H I S T O R Y  -  P L E A S E  K E E P  U P D A T E D       mw
mwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmw

Contributor			Ver  Description of changes
--------------		---  ----------------------------------------------------------------------------
Mike Welch/mw		1.00 Initial public release. MobilePro 780, 790, 900c all tested working.
Mike Welch/mw		.   Um...I didn't keep a history.  I'll be sure to flog myself for this.
Mike Welch/mw		.   Put it in the tray instead of having it just toggle itself on/off when run.
Mike Welch/mw		.   Added ability to disable keyboard. Does not work on brightness & contrast.
Mike Welch/mw		.   Added ability to disable remap without having to exit and restart app.
Mike Welch/mw		.   Other stuff I forgot
Mike Welch/mw		1.10 Restructured for lite shared development and released source.
Piotr Gawrysiak/gwr	1.19 Added remapping of Polish diacritics with Alt key ("Polish programmers" keyboard layout
mwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmwmw

#include "stdafx.h"
#include "RemapMP.h"
#include "mmsystem.h"
#include "shellapi.h"
#include "hooks.h"
#include "windowsx.h"
#include "wingdi.h"


//Put a text buffer on the clipboard - gwr

BOOL PutTextOnClipboard(HWND hwnd, LPTSTR pszText)
{
	BOOL bSuccess = FALSE;

	if ( IsWindow(hwnd) && OpenClipboard(hwnd) )
	{
		EmptyClipboard();

		LPTSTR pszCopy = (LPTSTR)LocalAlloc(LMEM_MOVEABLE, (_tcslen(pszText)+1) * sizeof(TCHAR));

		if ( pszCopy )
		{
			_tcscpy(pszCopy, pszText);

			UINT uiFormat;
			#ifdef UNICODE
			uiFormat = CF_UNICODETEXT;
			#else
			uiFormat = CF_TEXT;
			#endif
			bSuccess = (SetClipboardData(uiFormat, pszCopy) != NULL);

			// if the clipboard doesn't own the data, we need to free it
			if ( bSuccess == FALSE )
				LocalFree(pszCopy);
		}

		CloseClipboard();
	}

	return bSuccess;
}

///////////////////////////////////////////////////////////////////////////
///                   Low-level hook callback                           ///
// Get out of hooks ASAP; no modal dialogs or CPU-intensive processes!  ///
// Sadly, cannot modify contents, not even if hook is in a separate DLL ///
// All messages will be HC_ACTION (DLL version only saw HC_NOREMOVE)    ///
// Note: GetKeyState() will distinguish between left and right shift... ///
///////////////////////////////////////////////////////////////////////////
#pragma data_seg(".HOOKDATA")									//	Shared data (memory) among all instances.
	HHOOK g_hInstalledHook = NULL;							// Handle to low-level keyboard hook
#pragma data_seg()
#pragma comment(linker, "/SECTION:.HOOKDATA,RWS")		// Has it's own data/code segment

// Below: tell the OS that this EXE has an export function so we can use the global hook without a DLL
__declspec(dllexport) LRESULT CALLBACK HookCallback(
   int nCode,      // The hook code
   WPARAM wParam,  // The window message (WM_KEYUP, WM_KEYDOWN, etc.)
   LPARAM lParam   // A pointer to a struct with information about the pressed key
) 
{
	PKBDLLHOOKSTRUCT pkbhData = (PKBDLLHOOKSTRUCT)lParam;	// vkCode, scanCode, flags, time, dwExtraInfo

	// If true, DisableHardwareKeyboard() has been invoked, so don't let anything slip through us.
	// Unfortunately, NEC traps the contrast and brightness keys at the lowest level so we can't prevent that.
	if (!g_bKeyBEnabled) {
		g_bVkCode = g_iMsgSync = 0;
		return -1;
	}

	if (!g_bHookEnabled) {
		g_bVkCode = g_iMsgSync = 0;
		return CallNextHookEx(g_hInstalledHook, nCode, wParam, lParam);
	}

	// When we fire off the keyfake, it immediately comes back to us. Skip it.
	// Added g_iMsgSync because on rare occasion messages came back out of order which caused a keyfake loop.
	if (pkbhData->vkCode == g_bVkCode) {
		g_bVkCode = g_iMsgSync	= 0;
		return CallNextHookEx(g_hInstalledHook, nCode, wParam, lParam);
	}

	if (g_iMsgSync > 0) {
		--g_iMsgSync;
		return CallNextHookEx(g_hInstalledHook, nCode, wParam, lParam);
	}

	// ooooooooooooooooooooooooooooooooooooooooooooooooooooo
	// ooooooooo  Actual keyboard mapping begins. oooooooooo
	// ooooooooooooooooooooooooooooooooooooooooooooooooooooo
	// (wParam) WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP


	//Start Polish diacritics remapping - gwr

	//Character buffer - one unicode character and NULL
	wchar_t plCode[] = {0x0501,0x0000};

	//Quick check if Alt is pressed and we are enabled
	if (g_bAltKey && (wParam == WM_SYSKEYDOWN) && g_bPLEnabled)
	{

		//Now works only with lower case characters...
		//In theory the VK_A, VK_C should be defined by standard inludes... but are not :-)
		switch(pkbhData->vkCode) {
			case 0x41:  //a
				plCode[0] = 0x0105;
				break;
			case 0x43:  //c
				plCode[0] = 0x0107;
				break;
			case 0x45:  //e
				plCode[0] = 0x0119;
				break;
			case 0x4c:  //l
				plCode[0] = 0x0142;
				break;
			case 0x4e:  //n
				plCode[0] = 0x0144;
				break;
			case 0x53:  //s
				plCode[0] = 0x015b;
				break;
			case 0x58:  //x
				plCode[0] = 0x017a;
				break;
			case 0x5a:  //z
				plCode[0] = 0x017c;
				break;
			case 0x4f:  //o
				plCode[0] = 0x00f3;
				break;
			default:
				return CallNextHookEx(g_hInstalledHook, nCode, wParam, lParam);
		}

		//put data on clipboard
		//TODO: we should store current clipboard contents and restore afterwards, now anything that was in clipboard is overwritten

			if (PutTextOnClipboard(g_hWnd, plCode) == TRUE)
			{	
			
				//Temporarily disable us
				g_bHookEnabled = FALSE;
				
				//paste text from clipboard - Ctrl-V
	
				//release ALT
				keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP+KEYEVENTF_SILENT, 0);

			    //press CTRL				
				keybd_event(VK_CONTROL, 0, KEYEVENTF_SILENT, 0);

				//press V				
				keybd_event(0x56, 0, KEYEVENTF_SILENT, 0);

				//release V				
				keybd_event(0x56, 0, KEYEVENTF_KEYUP+KEYEVENTF_SILENT, 0);

				//release Ctrl
				keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP+KEYEVENTF_SILENT, 0);

				//press ALT again
				keybd_event(VK_MENU, 0, KEYEVENTF_SILENT, 0);

				//Enable us again
				g_bHookEnabled = TRUE;

				return -1;								// Non-zero flushes the keystroke out before it gets to dest	
			}
			else
			{
				//This could happen if we try to repeat the key too often perhaps
				//OkBox(_T("Clipboard failure"));
				return -1;
			}

	} //end of Polish remapping

	switch(pkbhData->vkCode) {
		case VK_LEFT:
			if (g_bFnKey)
				g_bVkCode = VK_HOME;
			break;
		case VK_SLASH:
		case VK_DIVIDE:								// Fn+Shift switches keyboard into numblock mode, so scancode changes!
			if (g_bFnKey)
				g_bVkCode = VK_PRIOR;				// pgup
			else
				g_bVkCode = VK_UP;
			break;
		case VK_UP:
			if (g_bFnKey)
				g_bVkCode = VK_NEXT;					// pgdn
			else
				g_bVkCode = VK_DOWN;
			break;
		case  VK_DOWN:
			if (g_bFnKey)
				g_bVkCode = VK_END;
			else
				g_bVkCode = VK_RIGHT;
			break;
		case  VK_RIGHT: 
			g_bVkCode = VK_SLASH;
			break;
		case VK_HOME:
		case VK_PRIOR:									// Flush original [Alt]+[key] because it causes conflicts.
		case VK_NEXT:
		case VK_END:
			return -1;
		case VK_FN:
			g_bFnKey = (wParam == WM_KEYDOWN);	// Save the state of the OEM Fn key
			break;
		case  VK_MENU:
			g_bAltKey = (wParam == WM_SYSKEYDOWN);  //Save the state of Alt key 
			if (g_bPLEnabled) return -1;			//and flush it - gwr
			break;	
	}

	if (g_bVkCode != 0) {
		
		DWORD dwFlags = KEYEVENTF_SILENT;		// Silent: No click (one has already been made)
		if (wParam == WM_KEYUP)
			dwFlags += KEYEVENTF_KEYUP;
		keybd_event(g_bVkCode, 0, dwFlags, 0);

		g_iMsgSync = 10;						// Arbitrary guestimate of max messages before our keyfake comes back

		return -1;										// Non-zero flushes the keystroke out before it gets to dest
	}
	return CallNextHookEx(g_hInstalledHook, nCode, wParam, lParam);
}


BOOL HookActivate(HINSTANCE hInstance)
{
	// Manually load these standard Win32 API calls (Microsoft says "unsupported in CE")
	SetWindowsHookEx		= NULL;
	CallNextHookEx			= NULL;
	UnhookWindowsHookEx	= NULL;

	// Load the core library. If it's not found, you've got CErious issues :-O
	g_hHookApiDLL = LoadLibrary(_T("coredll.dll"));
	if(g_hHookApiDLL == NULL) return false;
	else {
		// Load the SetWindowsHookEx API call (wide-char)
		SetWindowsHookEx = (_SetWindowsHookExW)GetProcAddress(g_hHookApiDLL, _T("SetWindowsHookExW"));
		if(SetWindowsHookEx == NULL) return false;
		else
		{
			// Load the hook.  Save the handle to the hook for later destruction.
			g_hInstalledHook = SetWindowsHookEx(WH_KEYBOARD_LL, HookCallback, hInstance, 0);
			if(g_hInstalledHook == NULL) return false;
		}

		// Get pointer to CallNextHookEx()
		CallNextHookEx = (_CallNextHookEx)GetProcAddress(g_hHookApiDLL, _T("CallNextHookEx"));
		if(CallNextHookEx == NULL) return false;

		// Get pointer to UnhookWindowsHookEx()
		UnhookWindowsHookEx = (_UnhookWindowsHookEx)GetProcAddress(g_hHookApiDLL, _T("UnhookWindowsHookEx"));
		if(UnhookWindowsHookEx == NULL) return false;
	}
	return true;
}

BOOL HookDeactivate()
{
	// mwNote: Hook may not unload immediately because other apps may have me loaded
	if(g_hInstalledHook != NULL) {
		UnhookWindowsHookEx(g_hInstalledHook);		
		g_hInstalledHook = NULL;
	}

	if(g_hHookApiDLL != NULL) {
		FreeLibrary(g_hHookApiDLL);
		g_hHookApiDLL = NULL;
	}
	return true;
}


////////////////////////////////////////////////////////////////////////
/// Wee Helper functions														   ///
////////////////////////////////////////////////////////////////////////
void OkBox(TCHAR* sMsg)
{
   MessageBox(g_hWnd, sMsg, DIALOG_TITLE, MB_OK| MB_SETFOREGROUND| MB_TOPMOST);
}

bool GetTaskbarRect(LPRECT lpRect)
{	
	HWND hWnd = TaskBarHandle();
	if (hWnd == 0) return false;

	GetWindowRect(hWnd, lpRect);
	return true;
}

BOOL CenterWindow(HWND hWnd)
{
	// At least the HPC 2000, if the user changes the taskbar from Auto Hide back to not hidden, the screen height is not updated.
	// Because of this, we'll center the about box ourself, putting the top at the topmost, so it can always be seen fully.
	int iScreenWidth, iScreenHeight;
   RECT Rect;

   iScreenWidth = GetSystemMetrics(SM_CXSCREEN);
   iScreenHeight = GetSystemMetrics(SM_CYSCREEN);
   GetWindowRect(hWnd, &Rect);

   Rect.right = Rect.right - Rect.left;		// This window's width, actually
   Rect.bottom = Rect.bottom - Rect.top;		// This window's height
   Rect.left = (iScreenWidth - Rect.right) / 2;
   //Rect.top = (iScreenHeight - Rect.bottom) / 2;
   SetWindowPos(hWnd, HWND_TOP, Rect.left, 0, 0, 0, SWP_NOSIZE | SWP_SHOWWINDOW);
   return true;
}

HWND TaskBarHandle(void)
{
	return FindWindow(_T("HHTaskBar"), NULL);			// This seems to work consistently
}

// Special version of this routine sends shutdown command to existing app if found
// Prior to v1.10 this was the only way to end the app
HANDLE ThereCanBeOnlyOne(HINSTANCE hInstance, TCHAR* sUniqueID)
{
   HANDLE hMutex;
   hMutex = CreateMutex(NULL, FALSE, sUniqueID);

   if (GetLastError() == ERROR_ALREADY_EXISTS) {
		TCHAR	szWindowClass[MAX_LOADSTRING];		// The window class name
		LoadString(hInstance, IDC_CLASSNAME, szWindowClass, MAX_LOADSTRING);
      HWND hWnd = FindWindow(szWindowClass, NULL);

      if (hWnd != NULL) 
			PostMessage(hWnd, WM_USER_CLOSE, 0, 0);
		else 
			OkBox(_T("Remap is running, but I can't find it...?"));

      ReleaseMutex(hMutex);
      return 0;
   }
   return hMutex;
}


void HouseCleaning(void)
{
	EnableHardwareKeyboard(true);
	TrayIconDelete(g_hWnd, ID_TRAY, LoadIcon(g_hInst, MAKEINTRESOURCE(IDI_ICONFORTRAY)), NULL);
	HookDeactivate();
	ReleaseMutex(g_hMutex);
}

////////////////////////////////////////////////////////////////////////
/// About box message handlers                                       ///
////////////////////////////////////////////////////////////////////////
BOOL CALLBACK AboutDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
   switch(msg) {
      case WM_INITDIALOG:
         SetDlgItemText(hDlg, IDC_ABOUT_EDITBOX, tcAboutBoxText);		// Defined in RemapMP.h
			CenterWindow(hDlg);
         return true;

		case WM_CLOSE:					// User clicked the close "X" button
			EndDialog(hDlg, true);
			break;
   }
   return FALSE;						// Pass off to DefWindowProc
}


////////////////////////////////////////////////////////////////////////
/// WinMain - main entry point - and related								   ///
////////////////////////////////////////////////////////////////////////
int WINAPI WinMain(HINSTANCE	hInstance,
						 HINSTANCE	hPrevInstance,
						 LPTSTR		lpCmdLine,
						 int			nCmdShow)
{
	MSG msg;
	WM_USER_CLOSE = RegisterWindowMessage(&APP_UNIQUEIDENTIFIER);		// Get unique WM_ message ID

	// I always wanted to do this...lvalue is set and tested for in the same line..hehe (-Delphi programmer)
	if ((g_hMutex = ThereCanBeOnlyOne(hInstance, &APP_UNIQUEIDENTIFIER)) == 0)
		return false;

	if (!InitInstance (hInstance, nCmdShow))
		return false;

	if (!HookActivate(hInstance))
		return false;

	// Ye Ol' Message Pump
	while (GetMessage(&msg, NULL, 0, 0))  {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	return msg.wParam;
}

// Save instance handle and create main window
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
	TCHAR	szTitle[MAX_LOADSTRING]				= {0};	// The title bar text 
	TCHAR	szWindowClass[MAX_LOADSTRING]		= {0};	// The window class name

	g_hInst = hInstance;		// Store instance handle in our global variable

	// Initialize global strings
	LoadString(g_hInst, IDC_CLASSNAME, szWindowClass, MAX_LOADSTRING);
	MyRegisterClass(g_hInst, szWindowClass);

	//LoadString(g_hInst, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);	<-- don't want to show up in task list

	// Using the old create out of viewable range trick...
	g_hWnd = CreateWindow(szWindowClass, szTitle, WS_OVERLAPPED, 
		-1000, -1000, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, g_hInst, NULL);

	if (!g_hWnd) return false;

	ShowWindow(g_hWnd, nCmdShow);		// The OS expects us to pass nCmdShow
	ShowWindow(g_hWnd, SW_HIDE);		// KFine, now I hide :) Note: CE defaults to VISIBLE regardless of flags
	UpdateWindow(g_hWnd);

	// Main icon needs both 32x32 and 16x16 icons so CE can use what is appropriate for different views. MS's example uses
	// LoadIcon, which only loads a 16x16 icon IF it can't find a 32x32. The result of using it is you won't see your icon in
	// the tray, though the blank area will respond to taps.  Instead, use LoadImage() which allows you to specify the size.
	TrayIconAdd(g_hWnd, ID_TRAY, (HICON)LoadImage(g_hInst, MAKEINTRESOURCE(IDI_MAIN), IMAGE_ICON, 16, 16, 0), NULL);

	return TRUE;
}


// Call this so the application gets 'well formed' small icons associated with it
ATOM MyRegisterClass(HINSTANCE hInstance, LPTSTR szWindowClass)
{
	WNDCLASS	wc;

	wc.style				= CS_HREDRAW | CS_VREDRAW;
   wc.lpfnWndProc		= (WNDPROC) WndProc;
   wc.cbClsExtra		= 0;
   wc.cbWndExtra		= 0;
   wc.hInstance		= hInstance;
   wc.hIcon				= LoadIcon(hInstance, MAKEINTRESOURCE(IDI_MAIN));
   wc.hCursor			= 0;
   wc.hbrBackground	= (HBRUSH) GetStockObject(WHITE_BRUSH);
   wc.lpszMenuName	= 0;
   wc.lpszClassName	= szWindowClass;

	return RegisterClass(&wc);
}


////////////////////////////////////////////////////////////////////////
/// Main message handler                                             ///
////////////////////////////////////////////////////////////////////////
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	if (message == WM_USER_CLOSE)									// Not a constant so can't go in main switch
		return !(DestroyWindow(g_hWnd) != 0);
	
	switch (message) {
		case WM_COMMAND: {
			WORD wNotifyCode	= HIWORD(wParam);
			WORD wCtrlID		= LOWORD(wParam);
			if (wNotifyCode == 0) {									// Sender is a MENU
				g_bBusy = true;										// Don't respond to any more tray notifications until we're done
				switch (wCtrlID) {
					case IDM_ABOUT:
						DialogBox(g_hInst, MAKEINTRESOURCE(IDD_DIALOG_ABOUT), 0, AboutDlgProc);
						break;
					case IDM_HOOK_ENABLED:
						g_bHookEnabled = !g_bHookEnabled;
						break;
					case IDM_PL_ENABLED:
						g_bPLEnabled = !g_bPLEnabled;
						break;
					case IDM_KEYBOARD_DISABLE:						// Toggle keyboard enabled or disabled
						g_bKeyBEnabled = !g_bKeyBEnabled;
						EnableHardwareKeyboard(g_bKeyBEnabled);
						break;
					case IDM_EXIT:
						PostMessage(g_hWnd, WM_USER_CLOSE, 0, 0);
				}
				g_bBusy = false;
				return 0;
			}
		}
		case TRAY_NOTIFYICON: {
			// After 2 days I give up.  There appears to be no way to get the Point where the icon is located in the tray.
			// We get 3 messages per tap in order: WM_LBUTTONDOWN, WM_MOUSEMOVE, WM_LBUTTONUP, but none of them contain x,y info.
			// GetCursorPos() and GetMessagePos() return invalid info in CE. GetCursorPos() in CE .NET 4.2 appears to work...
			// Refer to Usenet for more examples of folks trying to get this to work and giving up.  Hard to believe...
			if (lParam == WM_LBUTTONDOWN) {
				if ((wParam == ID_TRAY) && (!g_bBusy)) {

					g_bBusy = true;											// Don't respond to tray messages until done with dlg

					HMENU hMenu = LoadMenu(g_hInst, MAKEINTRESOURCE(IDM_POPUPMENU));
					HMENU hMenuTrackPopup = GetSubMenu(hMenu, 0);	// Get first menu item to use MenuBar as a context menu

					// Has the keyboard or hook been disabled?  If so, reflect this with a check mark
					CheckMenuItem(hMenuTrackPopup, IDM_HOOK_ENABLED, g_bHookEnabled ? MF_CHECKED : MF_UNCHECKED);
					CheckMenuItem(hMenuTrackPopup, IDM_PL_ENABLED,	 g_bPLEnabled	? MF_CHECKED : MF_UNCHECKED); //gwr
					CheckMenuItem(hMenuTrackPopup, IDM_KEYB_ENABLED, g_bKeyBEnabled ? MF_CHECKED : MF_UNCHECKED);

					RECT Rect;
					GetTaskbarRect(&Rect);

					// mwNote: add the TPM_RETURNCMD flag and TrackPopupMenu won't return until the user selects a menu item
					TrackPopupMenu(hMenuTrackPopup, TPM_BOTTOMALIGN, 400, Rect.top, 0, hWnd, NULL);
					DestroyMenu(hMenu);

					g_bBusy = false;
				}
			}
			return 0;
		}	
		case WM_DESTROY:
			HouseCleaning();
			PostQuitMessage(0);
			break;
		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
   }
   return 0;
}


///////////////////////////////////////////////////////////////
// System Tray Helper Functions based on eVC++ v3.x samples /// 
///////////////////////////////////////////////////////////////
BOOL TrayArbitrator(HWND hwnd, DWORD dwMessage, UINT uID, HICON hIcon, PTSTR pszTip)
{
  BOOL res = FALSE;
  NOTIFYICONDATA tnd;
  
  tnd.cbSize				= sizeof(NOTIFYICONDATA);
  tnd.hWnd					= hwnd;
  tnd.uID					= uID;
  tnd.uFlags				= NIF_MESSAGE|NIF_ICON; // NIF_TIP ignored in CE
  tnd.uCallbackMessage	= TRAY_NOTIFYICON;		// My user message
  tnd.hIcon					= hIcon;
  tnd.szTip[0]				= '\0';

  res = Shell_NotifyIcon(dwMessage, &tnd);
  return res;
}

void TrayIconAdd(HWND hwnd, UINT uID, HICON hIcon, PTSTR pszTip)
{
  TrayArbitrator(hwnd, NIM_ADD, uID,  hIcon, NULL);
}

void TrayIconModify(HWND hwnd, UINT uID, HICON hIcon, PTSTR pszTip) //animate icons
{
  TrayArbitrator(hwnd, NIM_MODIFY, uID, hIcon, NULL);
}

void TrayIconDelete(HWND hwnd, UINT uID, HICON hIcon, PTSTR pszTip)
{
  TrayArbitrator(hwnd, NIM_DELETE, uID, hIcon, NULL);
}



