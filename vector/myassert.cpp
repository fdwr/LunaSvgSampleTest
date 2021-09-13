/*
Replacement for irritating runtime assert statement.
Breaks at the assert point.
*/

#include "myassert.h"

#ifdef _WINDOWS
#define WIN32_LEAN_AND_MEAN
#include "windows.h"
#endif

void __cdecl myassert(const wchar_t* _Message, const wchar_t* _File, unsigned int _Line, const wchar_t* _Function)
{
	#ifdef _WINDOWS
	{
		WCHAR Buffer[2048];
		wsprintfW((LPTSTR)Buffer, L"%s @%s(%d), %s\n", _Message, _File, _Line, _Function);
		OutputDebugStringW((LPCWSTR)Buffer);
		wsprintfW((LPTSTR)Buffer, L"The following test should have been true, but failed. Not sure where to go from here, so... bye.\n\nTest: %s\nFile: %s\nLine: %d\nFunction: %s", _Message, _File, _Line, _Function);
		int button = MessageBoxW(NULL,Buffer, L"Test unexpectedly failed", MB_ABORTRETRYIGNORE|MB_ICONEXCLAMATION|MB_TASKMODAL);
		if (button != IDRETRY && button != IDIGNORE) {
			ExitProcess(ERROR_INVALID_DATA);
		}
	}
	#endif
	/*
	#if defined(_MSC_VER)
			__debugbreak();
	#else
		__asm { int 3 };
	#endif
	*/
}


