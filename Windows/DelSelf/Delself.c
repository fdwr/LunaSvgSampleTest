////////////////////////////////////////////////////////////////////////////////
// This program deletes itself by creating code in global memory			  //
// that first frees the primary module then deletes its EXE file.			  //
// To use as little space as possible (and because I don't know				  //
// any other language that can achieve this) the uninstaller is				  //
// written in assembler.													  //
////////////////////////////////////////////////////////////////////////////////

#define WIN32_LEAN_AND_MEAN
#define NO_STRICT
#include <windows.h>
#define true 1
#define false 0

const char ProgTitle[] = {"Delete Self"};
#define ProgMemBase (void*)0x400000

void debugwrite(char* Message, ...);
void FatalErrorMsg(LPSTR Msg);

char debugwrite_Buffer[256];

////////////////////////////////////////////////////////////////////////////////

#if 1
////////////////////////////////////////////////////////////////////////////////

extern char UnsCodeStart, UnsCodeEnd, *UnsCodePtr;
extern int UnsCodeSize, UnsKernelModule, UnsGetProcAddress;
int UnsErrorCode, UnsErrorString;

MSG msg;
HWND MainHwnd;

int APIENTRY WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int cmdShow)
{
	MainHwnd=CreateWindowEx(
		WS_EX_TOPMOST, 
		"BUTTON",
		"Click on button for program to delete itself.",
		WS_DLGFRAME|WS_VISIBLE|WS_POPUP|WS_SYSMENU|WS_CAPTION,
		0,0,320,60,
		NULL,NULL,
		ProgMemBase,
		0);

	for (;;)
	{
		GetMessage(&msg, NULL, 0,0);
		DispatchMessage(&msg);
		if ((msg.message == WM_KEYDOWN && msg.wParam == VK_ESCAPE)
			 || msg.message == WM_LBUTTONUP ||!IsWindow(MainHwnd)
		   ) break;
	}

	if (msg.message != WM_LBUTTONUP) return 0;


	UnsKernelModule = (int)GetModuleHandle("KERNEL32.DLL");
	UnsGetProcAddress = GetProcAddress(UnsKernelModule, "GetProcAddress");

	//create self deleting code
	//allocate enough memory for code plus a little padding at end
	UnsCodePtr=GlobalAlloc(GMEM_FIXED, UnsCodeSize+4096);
	if (!UnsCodePtr)
		FatalErrorMsg("Could not allocate memory for uninstallation code.");

	SetLastError(27);
	__asm {
		mov ecx,[UnsCodeSize]	//inline assembler won't directly allow UnsCodeEnd-UnsCodeStart
		mov edi,[UnsCodePtr]
		mov esi,offset UnsCodeStart
		shr ecx,2				// divide by 4 because of dwords
		;cld
		rep movsd
		call dword ptr [UnsCodePtr]
		mov [UnsErrorCode],ecx
		mov [UnsErrorString],edx
	}

	debugwrite("error routine = %s\nerror code = %d", UnsErrorString, UnsErrorCode);
	//debugwrite("error routine = %s\nerror code = %d", "test", UnsKernelModule);
	MessageBox(MainHwnd, (LPSTR)&debugwrite_Buffer, ProgTitle, MB_OK);
	DestroyWindow(MainHwnd);

	return 0;
}

////////////////////////////////////////////////////////////////////////////////
#elif 0

int Dummy;
HINSTANCE UninstallDll;
FARPROC UninstallProc;
int UninstallTID;


int APIENTRY WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int cmdShow)
{

	MessageBox(NULL, "starting", ProgTitle, MB_OK|MB_TOPMOST);

	if (!(UninstallDll=LoadLibrary("uninstal.dll")))
		FatalErrorMsg("Could not load uninstallation DLL 'uninstal.dll'");
	if (!(UninstallProc=GetProcAddress(UninstallDll, "DeleteParent")))
		FatalErrorMsg("Could not get procedure address 'DeleteParent'");
	UninstallProc();

	//it never reaches this messagebox
	MessageBox(NULL, "ending", ProgTitle, MB_OK|MB_TOPMOST);
	return 0;
}
#endif

void debugwrite(char* Message, ...)
{
	//wvsprintf((LPSTR)Buffer, Message, (va_list)(&Message)+4);
	wvsprintf((LPSTR)debugwrite_Buffer, (LPSTR)Message, (char*)((&Message)+1));
	OutputDebugString((LPSTR)debugwrite_Buffer);
}

void FatalErrorMsg(LPSTR Msg) {
	MessageBox(NULL, Msg, ProgTitle, MB_OK|MB_TOPMOST);
	ExitProcess(1);
}