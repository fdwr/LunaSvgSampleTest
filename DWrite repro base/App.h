/************************************************************************
 *
 * File: DemoApp.h
 *
 * Description: 
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

/******************************************************************
*                                                                 *
*  DemoApp                                                     *
*                                                                 *
******************************************************************/

class DemoApp
{
public:
    DemoApp();
    ~DemoApp();

    HRESULT Initialize();

private:
    HRESULT CreateDeviceIndependentResources();

    void DiscardDeviceIndependentResources();

    HRESULT CreateDeviceResources();

    void DiscardDeviceResources();

    HRESULT DrawD2DContent();

    HRESULT DrawText();

    void OnResize(
        UINT width,
        UINT height
        );

    static LRESULT CALLBACK WndProc(
        HWND hWnd,
        UINT message,
        WPARAM wParam,
        LPARAM lParam
        );

private:
    HWND hwnd_ = nullptr;

    // how much to scale a design that assumes 96-DPI pixels
    float dpiScaleX_ = 96.0;
    float dpiScaleY_ = 96.0;

    // Direct2D
    ID2D1Factory* d2dFactory_ = nullptr;
    ID2D1HwndRenderTarget* renderTarget_ = nullptr;
    ID2D1SolidColorBrush* blackBrush_ = nullptr;

    // DirectWrite
    IDWriteFactory* dwriteFactory_ = nullptr;
    IDWriteTextFormat* textFormat_ = nullptr;

    const wchar_t* text_ = nullptr;
    UINT32 textLength_ = 0;
};
