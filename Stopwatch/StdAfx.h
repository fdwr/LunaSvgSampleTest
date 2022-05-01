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
#include <windowsx.h>


// TODO: reference additional headers your program requires here
#ifndef T
#ifdef UNICODE
  #define T(string) L##string
#else
  #define T(string) string
#endif
#endif

#ifndef   nullptr // not defined on earlier versions of MSVC
# ifdef __cplusplus
#  define nullptr 0
# else
#  define nullptr ((void *)0)
# endif
#endif

#define elmsof(element) sizeof(element)/sizeof(element[0])

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_STDAFX_H__A9DB83DB_A9FD_11D0_BFD1_444553540000__INCLUDED_)