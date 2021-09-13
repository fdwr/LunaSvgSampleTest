// stdafx.h : include file for standard system include files,
//  or project specific include files that are used frequently, but
//      are changed infrequently
//

#if !defined(STDAFX_H_20051018_FDR)
#define STDAFX_H_20051018_FDR

#pragma once

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers

#include <windows.h>
#include <windowsx.h>
#include <shellapi.h>
#include <commctrl.h>
#include <shlobj.h>

#define ProgressBar_SetRange(hwndCtl, posMin, posMax) ((int)(DWORD)SNDMSG((hwndCtl), PBM_SETRANGE32, (WPARAM)(int)(posMin), (LPARAM)(posMax)))
#define ProgressBar_SetPos(hwndCtl, pos)              ((int)(DWORD)SNDMSG((hwndCtl), PBM_SETPOS, (WPARAM)(int)pos, 0L))


#undef try		// restore what the stupid header file broke,
#undef catch	// redefining 'try' and causing unnecessary grief. 20051018

#include <tchar.h>

#include "basictypes.h"


// TODO: reference additional headers your program requires here

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(STDAFX_H_20051018_FDR)
