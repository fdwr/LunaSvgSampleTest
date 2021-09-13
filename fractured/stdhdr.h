// stdhdr.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#define _WIN32_WINDOWS 0x0401
// Windows Header Files:
#include <windows.h>
#include <windowsx.h>
#include <commctrl.h>

// C RunTime Header Files
#define _CRT_SECURE_NO_DEPRECATE // added for MSVS8
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>
#include <assert.h>

#include "tchar2.h"	// fix stupidity and inconsistency
#include "basictypes.h" // supply basic things the C/C++ standard lacks

typedef void (*MsgDispatcherFunc)(MSG*);

// to show messages during compilation (but not errors)
#define COMPILERMSG2(x)   #x
#define COMPILERMSG1(x)  COMPILERMSG2(x)
#define COMPILERMSG(desc) message(__FILE__ "(" COMPILERMSG1(__LINE__) ") : message : " #desc)
