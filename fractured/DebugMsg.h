/**
File: DebugMsg.h
Since: 2005-12-02
*/

#ifdef _DEBUG
	#ifdef  __cplusplus
	extern "C" {
	#endif

	// BEGIN CUSTOM CODE - remove this for your app
	#define WriteDebugString(text) WriteMessage(text)
	extern void WriteMessage(LPTSTR msg, ...);
	// END CUSTOM CODE

	#include <tchar.h>

	void dbgmsg(TCHAR* msg, ...);

	#ifdef _WINDOWS
		void dbgmsgwin(HWND hwnd, int message, WPARAM wparam, LPARAM lparam);
		TCHAR* dbgmsgwinname(int message);

		#ifndef WriteDebugString
		#define WriteDebugString(text) OutputDebugString(text)
		#endif
	#endif

	#ifndef WriteDebugString
	#define WriteDebugString(text) printf(text)
	#endif

	#ifdef  __cplusplus
	}
	#endif
#else
	#define	dbgmsg //
	#define	dbgmsgwin //
	#define dbgmsgwinname //
#endif
