#define _WIN32_WINNT 0x0600
#define NOMINMAX
#include <windows.h>
#include <windowsx.h>
#include <commctrl.h>
#include <string>
#include <sstream>
#include <iomanip>

#include <assert.h>
#include "cpp0xskeleton.h"

#pragma warning(disable: 4200)  // zero-sized array in struct/union
#pragma warning(disable: 4512)  // assignment operator could not be generated

namespace Globals
{
    extern HINSTANCE   Instance;
}

typedef unsigned __int32 char32_t;
