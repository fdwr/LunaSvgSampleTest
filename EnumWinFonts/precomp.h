// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#include <SDKDDKVer.h>

#include <stdio.h>
#include <conio.h> // wait for keypress
#include <tchar.h>
#include <stdint.h>
#include <string>

#include <windows.h>
#include <wrl.h>

#ifndef NTDDI_WIN10_RS3
#define NTDDI_WIN10_RS3                     0x0A000004  /* ABRACADABRA_WIN10_RS3 */
#endif

#undef NTDDI_VERSION
#define NTDDI_VERSION NTDDI_WIN10_RS3

#include "dwrite_3.h"
