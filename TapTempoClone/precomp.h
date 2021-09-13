// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
//#include <tchar.h>
#include <windows.h>
#include <algorithm>

// Fix Window's poor naming that causes countless minutes
// of grief because of mispelling, thanks to all-caps,
// crammed words, and shaved letters.
#define nullptr             NULL
#define ApiEntry            APIENTRY
#define WinApi              WINAPI
#define InstanceHandle      HINSTANCE
#define ZString             LPWSTR
#define MakeIntResource     MAKEINTRESOURCE
#define WindowHandle        HWND
#define FontHandle          HFONT
#define Message             MSG
#define LongParam           LPARAM
#define WordParam           WPARAM

#define GetDialogItem       GetDlgItem
#define SetDialogItemText   SetDlgItemText
#define SendDialogItemMessage SendDlgItemMessage

namespace WindowMessage {
    enum Type {
        Activate            = WM_ACTIVATE,
        Command             = WM_COMMAND,
        Close               = WM_CLOSE,
        KeyDown             = WM_KEYDOWN,
        Destroy             = WM_DESTROY,
        InitializeDialog    = WM_INITDIALOG,
        SetIcon             = WM_SETICON,
    };
}

namespace KeyCode {
    enum Type {
        Enter     = VK_RETURN,
        BackSpace = VK_BACK,
    };
}

namespace ShowWindowCommand {
    enum Type {
        Show = SW_SHOW,
    };
}

namespace DialogId {
    enum Type {
        Ok = IDOK,
        Cancel = IDCANCEL,
        Abort = IDABORT,
        Retry = IDRETRY,
        Ignore = IDIGNORE,
        Yes = IDYES,
        No = IDNO,
        Close = IDCLOSE,
        Help = IDHELP,
        TryAgain = IDTRYAGAIN,
        Continue = IDCONTINUE,
        Timeout = IDTIMEOUT,
    };
}

// essential types

#define elemsof(theArray) (sizeof(theArray)/sizeof(*theArray))

typedef unsigned int    uint;
