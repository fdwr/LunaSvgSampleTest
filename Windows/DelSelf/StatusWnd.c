// Main program to test uninstaller

#define WIN32_LEAN_AND_MEAN
#define NO_STRICT
#include <windows.h>

#define ProgMemBase (void*)0x400000
const char ProgTitle[] = {"Uninstall"};

void __stdcall SetStatusMessage(LPSTR msg);
void WaitForQuitKey();
void CheckForClose();

////////////////////////////////////////////////////////////////////////////////

HWND MsgHwnd;
MSG msg;

////////////////////////////////////////////////////////////////////////////////

int APIENTRY WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int cmdShow)
{
	GetModuleFileName(ProgMemBase, SelfPath, sizeof(SelfPath));
	//CreateFile((LPSTR)&SelfPath, GENERIC_READ,FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_FLAG_DELETE_ON_CLOSE, NULL);

	MsgHwnd=CreateWindowEx(
		WS_EX_TOPMOST, 
		"STATIC",
		NULL,
		WS_DLGFRAME|WS_VISIBLE|WS_POPUP|WS_SYSMENU
			| SS_NOPREFIX|SS_CENTER|SS_CENTERIMAGE,
		0,0,320,40,
		NULL,NULL,
		ProgMemBase,
		0);
	MsgHwnd=CreateWindowEx(
		WS_EX_TOPMOST, 
		"EDIT",
		"<< Uninstalling " UninstallProgramName " >>",
		WS_DLGFRAME|WS_VISIBLE|WS_POPUP|WS_SYSMENU|WS_VSCROLL
			| ES_AUTOVSCROLL|ES_MULTILINE|ES_READONLY,
		0,0,320,216,
		NULL,NULL,
		ProgMemBase,
		0);
	//DebugWrite("msg hwnd=%d", GetLastError());
	//DebugWrite("msg hwnd=%d", MsgHwnd);
	SendMessage(MsgHwnd, WM_SETFONT, (WPARAM)GetStockObject(DEFAULT_GUI_FONT), FALSE);
	//MessageBox(NULL, "Preparing to delete main program.", "Uninstaller", MB_OK);

	SetStatusMessage("\r\nWaiting for parent process to terminate...\r\n");
	for (;;) {
		if (WaitForSingleObject(PID, 1000) != WAIT_TIMEOUT) break;
		//if (WaitForSingleObject(PID, 1000) == WAIT_OBJECT_0) break;
		CheckForClose();
	}

	SetStatusMessage("Waiting for any additional instances to terminate...\r\n");
	//find any other instances of the parent
	//attempt to kill them
	//wait until dead
	for (;;) {
		long ParentId;
		HANDLE ParentPh;
		HWND ParentHwnd=FindWindow(UninstallClassName, NULL);
		if (ParentHwnd == NULL) break; //no instances found
		GetWindowThreadProcessId(ParentHwnd, &ParentId);
		ParentPh=OpenProcess(SYNCHRONIZE, FALSE, ParentId);

		SendMessage(ParentHwnd, WM_CLOSE, 0,0);
		if (ParentPh==NULL)
			Sleep(1000); //!? could not open process handle, so just sleep
		else {
			WaitForSingleObject(ParentPh, 1000);
			CloseHandle(ParentPh);
		}
		CheckForClose();
	}

	CheckForClose();
	SetStatusMessage("Deleting program files...\r\n");
	
	SetStatusMessage("<< Uninstallation complete >>");
	WaitForQuitKey();
	DestroyWindow(MsgHwnd);
	return 0;
}

void __stdcall SetStatusMessage(LPSTR msg)
{
	//SendMessage(MsgHwnd, WM_SETTEXT, 0, (LPARAM)msg);
	SendMessage(MsgHwnd, EM_SETSEL, 65534, 65534);
	SendMessage(MsgHwnd, EM_REPLACESEL, FALSE, (LPARAM)msg);
	UpdateWindow(MsgHwnd);
}


void CheckForClose()
//dispatch all message and check for escape press
//exit process if window was closed or escape pressed
{
	int quit = 0;
	while (PeekMessage(&msg, NULL, 0,0, PM_REMOVE))
	{
		switch (msg.message) {
		case WM_KEYDOWN:
			if (msg.wParam == VK_ESCAPE) quit = TRUE;
			break;
		//case WM_LBUTTONDOWN:
		//	DefWindowProc(MsgHwnd, WM_NCHITTEST, msg.wParam, msg.lParam);
		//	break;
		//case WM_NCHITTEST:
		//	return HTCAPTION;
		default:
			DispatchMessage(&msg);
		}
	}

	if (!IsWindow(MsgHwnd) || quit) {
		SetStatusMessage("<< Uninstallation terminated by user >>");
		WaitForQuitKey();
		ExitProcess(1);
	}
}


void WaitForQuitKey()
{
	for (;;)
	{
		GetMessage(&msg, NULL, 0,0);
		if ((msg.message == WM_KEYDOWN
			&& (msg.wParam == VK_ESCAPE
			    || msg.wParam == VK_RETURN
			    || msg.wParam == VK_SPACE)
			) || !IsWindow(MsgHwnd)
		   ) break;
		DispatchMessage(&msg);
	}
}