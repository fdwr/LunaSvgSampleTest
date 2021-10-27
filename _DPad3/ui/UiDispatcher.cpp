//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Event dispatcher for Win32 WindowProc events.
//              Cracks message and forwards onto appropriate methods.
//
//----------------------------------------------------------------------------
#include "precomp.h"


// Dispatches Win32 WM_* events to the appriate methods, which may then
// propagate them down to their controls.

float UiDispatcher::GetMouseWheelFactor(UINT action, WPARAM wParam, UINT defaultSetting)
{
    float zDelta = GET_WHEEL_DELTA_WPARAM(wParam);
    UINT userSetting;
 
    // Retrieve the lines-to-scroll or characters-to-scroll user setting. 
    BOOL success = SystemParametersInfo(
                        SPI_GETWHEELSCROLLLINES,
                        0, 
                        &userSetting, 
                        0 );

    // Use a default value if the API failed.
    if (success == FALSE)
        userSetting = defaultSetting;

    return (zDelta / WHEEL_DELTA) * userSetting;
}


bool UiDispatcher::DispatchMouse(UiControl* rootControl, HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    MouseMessage mouse;
    memset(&mouse, 0, sizeof(mouse));

    switch (message)
    {
    case WM_LBUTTONDOWN:
    case WM_LBUTTONUP:
    case WM_LBUTTONDBLCLK:
        mouse.button = MouseMessage::ButtonLeft;
        break;

    case WM_RBUTTONDOWN:
    case WM_RBUTTONUP:
    case WM_RBUTTONDBLCLK:
        mouse.button = MouseMessage::ButtonRight;
        break;

    case WM_MBUTTONDOWN:
    case WM_MBUTTONUP:
    case WM_MBUTTONDBLCLK:
        mouse.button = MouseMessage::ButtonMiddle;
        break;

    case WM_XBUTTONDOWN:
    case WM_XBUTTONUP:
    case WM_XBUTTONDBLCLK:
        mouse.button = MouseMessage::ButtonX;
        break;

    case WM_MOUSEWHEEL:
    case WM_MOUSEHWHEEL:
    case WM_MOUSEMOVE:
    //case WM_MOUSELEAVE:
        mouse.button = MouseMessage::ButtonNone;
        break;

    default:
        return false;
    }

    // Get mouse coordinates.
    // Note that the mouse wheel is unusual in that the position
    // is relative rather than client relative like the others.
    POINT mousePt = {GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};
    if (message == WM_MOUSEWHEEL || message == WM_MOUSEHWHEEL)
    {
        ScreenToClient(hwnd, &mousePt);
    }
    mouse.x     = float(mousePt.x);
    mouse.y     = float(mousePt.y);
    mouse.xDif  = 0;
    mouse.yDif  = 0;
    float previousX = mouse.x;
    float previousY = mouse.y;

    if (GetWindowLong(hwnd, GWL_EXSTYLE) & WS_EX_LAYOUTRTL)
    {
        // Since DirectWrite implicitly understands RTL layout,
        // the reversal of mouse coordinates complicates things,
        // especially for mixed direction text. So, restore them
        // to the coordinate system where x increases to the
        // right, for both LTR and RTL. It's simpler to handle
        // just one system when mixing both GDI and D2D.

        RECT rect;
        GetClientRect(hwnd, &rect);
        mouse.x = rect.right - mouse.x;
    }

    mouse.repeatCount = 0;

    switch (message)
    {
    case WM_LBUTTONDBLCLK:
    case WM_MBUTTONDBLCLK:
    case WM_RBUTTONDBLCLK:
    case WM_XBUTTONDBLCLK:
        mouse.repeatCount++;
        __fallthrough;

    case WM_LBUTTONDOWN:
    case WM_RBUTTONDOWN:
    case WM_MBUTTONDOWN:
    case WM_XBUTTONDOWN:
        mouse.repeatCount++;
        mouse.message = MouseMessage::MessagePress;
        return rootControl->MousePress(mouse);

    case WM_LBUTTONUP:
    case WM_RBUTTONUP:
    case WM_MBUTTONUP:
    case WM_XBUTTONUP:
        mouse.message = MouseMessage::MessageRelease;
        return rootControl->MouseRelease(mouse);

    case WM_MOUSEWHEEL:
        mouse.message = MouseMessage::MessageScroll;
        mouse.yDif = GetMouseWheelFactor(SPI_GETWHEELSCROLLLINES, wParam, 1);
        return rootControl->MouseScroll(mouse);

    case WM_MOUSEHWHEEL:
        mouse.message = MouseMessage::MessageScroll;
        mouse.xDif = GetMouseWheelFactor(SPI_GETWHEELSCROLLCHARS, wParam, 1);
        return rootControl->MouseScroll(mouse);

    case WM_MOUSEMOVE:
        mouse.message = MouseMessage::MessageMove;
        mouse.xDif = mouse.x - previousX;
        mouse.yDif = mouse.y - previousY;
        return rootControl->MouseMove(mouse);

    case WM_MOUSELEAVE:
        mouse.message = MouseMessage::MessageExit;
        return rootControl->MouseExit(mouse);

    default:
        return false;
    }
}


bool UiDispatcher::DispatchKeyboard(UiControl* rootControl, UINT message, WPARAM wParam, LPARAM lParam)
{
    KeyboardMessage keyboard;
    memset(&keyboard, 0, sizeof(keyboard));

    switch (message)
    {
    case WM_SYSKEYDOWN:
    case WM_KEYDOWN:
        keyboard.message = KeyboardMessage::MessagePress;
        keyboard.button = static_cast<UINT32>(wParam);
        keyboard.repeatCount = 1;
        if ((lParam & (1 << 30)))
            ++keyboard.repeatCount; // already held down
        return rootControl->KeyPress(keyboard);

    case WM_KEYUP:
    case WM_SYSKEYUP:
        keyboard.message = KeyboardMessage::MessageRelease;
        keyboard.button = static_cast<UINT32>(wParam);
        return rootControl->KeyRelease(keyboard);

    case WM_CHAR:
        keyboard.message = KeyboardMessage::MessageCharacter;
        keyboard.character = static_cast<UINT32>(wParam);
        return rootControl->KeyCharacter(keyboard);

    case WM_SETFOCUS:
        keyboard.message = KeyboardMessage::MessageEnter;
        rootControl->SetStyle(UiControl::StyleFlagKeyFocus);
        return rootControl->KeyEnter(keyboard);

    case WM_KILLFOCUS:
        keyboard.message = KeyboardMessage::MessageExit;
        rootControl->ClearStyle(UiControl::StyleFlagKeyFocus);
        return rootControl->KeyExit(keyboard);

    default:
        return false;
    }
}
