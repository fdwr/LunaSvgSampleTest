
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

// TODO Copy this code into a fresh solution instead of using another sample as
// a base. What are the minimum number of files that need to be shipped? What
// does DeclareDPIAware do?

#pragma once

#include <string>
#include "PathTextRenderer.h"

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

	// TODO Should I use STDMETHODCALL or anything like that with these methods?
	// What about SAL annotations on the parameters?
    HRESULT Initialize();
	
private:
    HRESULT CreateDeviceIndependentResources();
    void DiscardDeviceIndependentResources();

	HRESULT CreateTextLayout();
	void DiscardTextLayout();

    HRESULT CreateDeviceResources();
    void DiscardDeviceResources();

	HRESULT CreateTextRenderer();
	void DiscardTextRenderer();

	HRESULT CreateGeometry();
	void DiscardGeometry();

	HRESULT DrawD2DContent();

    HRESULT DrawText();
	void DrawGeometry();

    void OnResize(
        UINT width,
        UINT height
        );

	void OnTimer();
	void OnChar(
		SHORT key
		);

    static LRESULT CALLBACK WndProc(
        HWND hWnd,
        UINT message,
        WPARAM wParam,
        LPARAM lParam
        );

private:
    HWND hwnd_;

    // How much to scale a design that assumes 96-DPI pixels
    FLOAT dpiScaleX_;
    FLOAT dpiScaleY_;

    // Direct2D members
    ID2D1Factory* pD2DFactory_;
	ID2D1PathGeometry* pGeometry_;
    ID2D1HwndRenderTarget* pRT_;
    ID2D1SolidColorBrush* pBlackBrush_;

    // DirectWrite members
    IDWriteFactory* pDWriteFactory_;
    IDWriteTextFormat* pTextFormat_;
	IDWriteTextLayout* pTextLayout_;
	IDWriteTextRenderer* pTextRenderer_;

	std::wstring displayString_;
	BOOL animating_;
	DWORD ticks_;
};


