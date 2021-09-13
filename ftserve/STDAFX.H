// stdafx.h : include file for standard system include files,
//  or project specific include files that are used frequently, but
//      are changed infrequently
//

#if !defined(AFX_STDAFX_H__A9DB83DB_A9FD_11D0_BFD1_444553540000__INCLUDED_)
#define AFX_STDAFX_H__A9DB83DB_A9FD_11D0_BFD1_444553540000__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers

#include <windows.h>
#include "resource.h"
#include "commctrl.h"
#include "commdlg.h"
#include "richedit.h"
#include "shellapi.h"

////////////////////////////////////////////////////////////////////////////////

#define ProgMemBase (HINSTANCE)0x400000

////////////////////////////////////////////////////////////////////////////////

BOOL CALLBACK IddMainProc(HWND hwnd, UINT message, long wParam, long lParam);
BOOL CALLBACK IddAboutProc(HWND hwnd, UINT message, long wParam, long lParam);
BOOL CALLBACK IddFilesProc(HWND hwnd, UINT message, long wParam, long lParam);
void StatusLogClear();
void StatusLogAppend(char* text);
void FillFileList();


//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_STDAFX_H__A9DB83DB_A9FD_11D0_BFD1_444553540000__INCLUDED_)
