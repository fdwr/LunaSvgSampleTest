//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Event dispatcher for Win32 WindowProc events.
//              Cracks message and forwards onto appropriate methods.
//
//----------------------------------------------------------------------------
#pragma once


// Dispatches Win32 WM_* events to the appriate methods, which can then
// propagate them down to their control's methods.

struct UiDispatcher
{
    static float GetMouseWheelFactor(UINT action, WPARAM wParam, UINT defaultSetting);

    static bool DispatchMouse(UiControl* rootControl, HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

    static bool DispatchKeyboard(UiControl* rootControl, UINT message, WPARAM wParam, LPARAM lParam);
};
