/************************************************************************
 *
 * File: SimpleHelloWorld.h
 *
 * Description: Include file for standard system include files,
 * or project pecific include files that are used frequently, but
 * are changed infrequently.
 * 
 * 
 *  This file is part of the Microsoft Windows SDK Code Samples.
 * 
 *  Copyright (C) Microsoft Corporation.  All rights reserved.
 * 
 * This source code is intended only as a supplement to Microsoft
 * Development Tools and/or on-line documentation.  See these other
 * materials for detailed information regarding Microsoft code samples.
 * 
 * THIS CODE AND INFORMATION ARE PROVIDED AS IS WITHOUT WARRANTY OF ANY
 * KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
 * PARTICULAR PURPOSE.
 * 
 ************************************************************************/

#pragma once

// Ignore unreferenced parameters, since they are very common
// when implementing callbacks.
#pragma warning(disable : 4100)

// Modify the following defines if you have to target a platform prior to the ones pecified below.
// Refer to MSDN for the latest info on corresponding values for different platforms.

#ifndef WINVER                  // Minimum platform is Windows 7
#define WINVER 0x0601
#endif

#ifndef _WIN32_WINNT            // Minimum platform is Windows 7
#define _WIN32_WINNT 0x0601
#endif

#ifndef _WIN32_WINDOWS          // Minimum platform is Windows 7
#define _WIN32_WINDOWS 0x0601
#endif


#define WIN32_LEAN_AND_MEAN     // Exclude rarely-used stuff from Windows headers
#define NOMINMAX

// Windows Header Files:
#include <windows.h>
#include <intsafe.h>

// C RunTime Header Files
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <math.h>
#include <algorithm>

#include <d2d1.h>
#include <d2d1helper.h>
#include <dwrite.h>
#include <string.h>

// SafeRelease inline function.
template <typename Type> inline void SafeRelease(Type** ppComObject)
{
    if (*ppComObject != NULL)
    {
        (*ppComObject)->Release();
        *ppComObject = NULL;
    }
}

// Macros

#ifndef HINST_THISCOMPONENT
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define HINST_THISCOMPONENT ((HINSTANCE)&__ImageBase)
#endif
