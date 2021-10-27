//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2013. All rights reserved.
//
//  Contents:   Shaded Message Dialog.
//
//  Author:     Dwayne Robinson (dwayner@microsoft.com)
//
//  History:    2013-08-28   dwayner    Created
//
//----------------------------------------------------------------------------

#pragma once


class MessageBoxShaded
{
    typedef MessageBoxShaded Self;

public:
    static int32_t Show(
        HWND ownerHwnd,
        _In_z_ const wchar_t* text,
        _In_z_ const wchar_t* caption,
        uint32_t type
        );

private:
    MessageBoxShaded(HWND hwnd);
    INT_PTR Initialize(const MSGBOXPARAMS& initializationParams);
    static INT_PTR CALLBACK StaticDialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    DialogProcResult CALLBACK DialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    DialogProcResult CALLBACK ProcessCommand(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    DialogProcResult CALLBACK ProcessNotification(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    void Resize();

    HWND hwnd_;
};
