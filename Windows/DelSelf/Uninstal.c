// This file is NOT used anymore. One of my earlier ideas
// was to have a DLL delete the main program, but that still
// didn't take care of the problem. Ultimately, some 
// executable would be left over, albeit only a small DLL 
// instead of a larger EXE.

#define WIN32_LEAN_AND_MEAN
#define NO_STRICT
#include <windows.h>
//#include "uninstal.h"

#define ProgMemBase (void*)0x400000
const char ProgTitle[] = {"Uninstall"};

void debugwrite(char* Message, ...);

char ParentPath[MAX_PATH];

////////////////////////////////////////////////////////////////////////////////

char ParentPath[MAX_PATH];

////////////////////////////////////////////////////////////////////////////////

BOOL APIENTRY DllMain(HANDLE hModule, DWORD  ulReason, LPVOID lpReserved)
{
    switch (ulReason)
	{
		case DLL_PROCESS_ATTACH:
			DisableThreadLibraryCalls(hModule);
			debugwrite("DllProcessAttach %X", hModule);
			//MessageBox(NULL, "attaching", "Uninstal.dll", MB_OK);
			break;
		case DLL_PROCESS_DETACH:
			debugwrite("DllProcessDetach %X", hModule);
			break;
		case DLL_THREAD_ATTACH:
		case DLL_THREAD_DETACH:
			break;
    }
    return TRUE;
}

__declspec(dllexport) void DeleteParent() {

	MessageBox(NULL, "Delete Parent - enter", ProgTitle, MB_OK|MB_TOPMOST);

	GetModuleFileName(NULL, (LPSTR)ParentPath, MAX_PATH);
	debugwrite("module filename=%s", ParentPath);

	SetLastError(0);
	FreeLibrary(GetModuleHandle(NULL));
	debugwrite("free result=%d", GetLastError());

	Sleep(1000);

	debugwrite("deleting parent...");
	DeleteFile((LPSTR)ParentPath);
	SetLastError(0);
	debugwrite("delete result=%d", GetLastError());
	ExitProcess(0);
}

void debugwrite(char* Message, ...)
{
	char Buffer[256];
	//wvsprintf((LPSTR)Buffer, Message, (va_list)(&Message)+4);
	wvsprintf((LPSTR)Buffer, (LPSTR)Message, (char*)((&Message)+1));
	OutputDebugString((LPSTR)Buffer);
}
