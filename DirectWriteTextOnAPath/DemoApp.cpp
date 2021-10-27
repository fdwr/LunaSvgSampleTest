
/************************************************************************
 *
 * File: DemoApp.cpp
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

#include <assert.h>

#include "TextOnAPath.h"

/******************************************************************
*                                                                 *
*  DemoApp::DemoApp constructor                             *
*                                                                 *
*  Initialize member data                                         *
*                                                                 *
******************************************************************/

DemoApp::DemoApp() :
    hwnd_(NULL),
    pD2DFactory_(NULL),
	pGeometry_(NULL),
    pRT_(NULL),
    pBlackBrush_(NULL),
    pDWriteFactory_(NULL),
	pTextRenderer_(NULL),
	pTextLayout_(NULL),
    pTextFormat_(NULL),
	animating_(FALSE),
	ticks_(1000)
{
}

/******************************************************************
*                                                                 *
*  DemoApp::~DemoApp destructor                             *
*                                                                 *
*  Tear down resources                                            *
*                                                                 *
******************************************************************/

DemoApp::~DemoApp()
{
    SafeRelease(&pD2DFactory_);
    SafeRelease(&pRT_);
    SafeRelease(&pBlackBrush_);
    SafeRelease(&pDWriteFactory_);
    SafeRelease(&pTextFormat_);

	DiscardTextRenderer();
}

/******************************************************************
*                                                                 *
*  DemoApp::Initialize                                         *
*                                                                 *
*  Create application window and device-independent resources     *
*                                                                 *
******************************************************************/

HRESULT DemoApp::Initialize()
{
    HRESULT hr = S_OK;

	if (SUCCEEDED(hr))
	{
		WNDCLASSEX wcex;

		// Get DPI information.
		HDC screen = GetDC(0);
		dpiScaleX_ = GetDeviceCaps(screen, LOGPIXELSX) / 96.0f;
		dpiScaleY_ = GetDeviceCaps(screen, LOGPIXELSY) / 96.0f;
		ReleaseDC(0, screen);

		ATOM atom;

		// Register window class.
		wcex.cbSize        = sizeof(WNDCLASSEX);
		wcex.style         = CS_HREDRAW | CS_VREDRAW;
		wcex.lpfnWndProc   = DemoApp::WndProc;
		wcex.cbClsExtra    = 0;
		wcex.cbWndExtra    = sizeof(LONG_PTR);
		wcex.hInstance     = HINST_THISCOMPONENT;
		wcex.hbrBackground = NULL;
		wcex.lpszMenuName  = NULL;
		wcex.hIcon         = LoadIcon(
								NULL,
								IDI_APPLICATION);
		wcex.hCursor       = LoadCursor(
								NULL,
								IDC_ARROW);
		wcex.lpszClassName = TEXT("DemoApp");
		wcex.hIconSm       = LoadIcon(
								NULL,
								IDI_APPLICATION
								);

		atom = RegisterClassEx(&wcex);

		hr = atom ? S_OK : E_FAIL;
	}

    if (SUCCEEDED(hr))
    {
        // Create window.
        hwnd_ = CreateWindow(
            TEXT("DemoApp"),
            TEXT("DirectWrite Text on a Path"),
            WS_OVERLAPPEDWINDOW,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            static_cast<int>(640.0f / dpiScaleX_),
            static_cast<int>(480.0f / dpiScaleY_),
            NULL,
            NULL,
            HINST_THISCOMPONENT,
            this
            );

		hr = hwnd_ ? S_OK : E_FAIL;
    }

	if (SUCCEEDED(hr))
    {
        hr = CreateDeviceIndependentResources();
    }

	if (SUCCEEDED(hr))
	{
		// Create a timer and receive WM_TIMER messages at a rough
        // granularity of 33msecs. If you need a more precise timer,
        // consider modifying the message loop and calling more precise
        // timing functions.
        SetTimer(
            hwnd_,
            0, //timerId
            33, //msecs
            NULL //lpTimerProc
            );
	}

    if (SUCCEEDED(hr))
    {
        ShowWindow(
            hwnd_,
            SW_SHOWNORMAL
            );

        UpdateWindow(hwnd_);
    }

    return hr;
}

/******************************************************************
*                                                                 *
*  DemoApp::CreateDeviceIndependentResources                   *
*                                                                 *
*  This method is used to create resources which are not bound    *
*  to any device. Their lifetime effectively extends for the      *
*  duration of the app. These resources include the Direct2D and  *
*  DirectWrite factories; and a DirectWrite Text Format object    *
*  (used for identifying particular font characteristics) and     *
*  a Direct2D geometry.                                           *
*                                                                 *
******************************************************************/

HRESULT DemoApp::CreateDeviceIndependentResources()
{
    HRESULT hr;

    // Create Direct2D factory.
    hr = D2D1CreateFactory(
        D2D1_FACTORY_TYPE_SINGLE_THREADED,
        &pD2DFactory_
        );

    // Create a shared DirectWrite factory.
    if (SUCCEEDED(hr))
    {
        hr = DWriteCreateFactory(
            DWRITE_FACTORY_TYPE_SHARED,
            __uuidof(IDWriteFactory),
            reinterpret_cast<IUnknown**>(&pDWriteFactory_)
            );
    }

    // The string to display.
	//displayString_.append(L"       कोरको"); // String used to test glyph clusters on the slope.
	// TODO Make sure these translations of "Hello, world!" aren't profane or anything.
	displayString_.append(L"Hüllo, world! مرحبا ، العالم! Здравствуй, мир!");

    // Create a text format using Gabriola with a font size of 48.
    // This sets the default font, weight, stretch, style, and locale.
    if (SUCCEEDED(hr))
    {
        hr = pDWriteFactory_->CreateTextFormat(
            L"Gabriola",                // Font family name.
            NULL,                       // Font collection (NULL sets it to use the system font collection).
            DWRITE_FONT_WEIGHT_REGULAR,
            DWRITE_FONT_STYLE_NORMAL,
            DWRITE_FONT_STRETCH_NORMAL,
            48.0f,
            L"en-us", // TODO Is this appropriate? Or is there a way to get the default?
            &pTextFormat_
            );
    }

    return hr;
}

HRESULT DemoApp::CreateTextRenderer()
{
	if (!pTextRenderer_)
	{
		pTextRenderer_ = new PathTextRenderer(dpiScaleY_);
	}

	return S_OK;
}

void DemoApp::DiscardTextRenderer()
{
	if (pTextRenderer_)
	{
		delete pTextRenderer_; pTextRenderer_ = NULL;
	}
}

HRESULT DemoApp::CreateGeometry()
{
	HRESULT hr = S_OK;

	if (!pGeometry_)
	{
		FLOAT t = sin((ticks_) / 1000.0f);

		hr = pD2DFactory_->CreatePathGeometry(&pGeometry_);

		ID2D1GeometrySink *pSink = NULL;

		if (SUCCEEDED(hr))
		{
			hr = pGeometry_->Open(&pSink);
		}

		if (SUCCEEDED(hr))
		{
			// Create a Bezier curve with two endpoints and two control points,
			// centered in the window.
			D2D1_SIZE_F size = pRT_->GetSize();
			FLOAT incrementX = 180;
			FLOAT maxAmplitude = 600; // TODO rename better
			FLOAT leftX = (size.width - 3*incrementX) / 2;
			FLOAT centerY = (size.height / 2);

			pSink->SetFillMode(D2D1_FILL_MODE_WINDING);

			pSink->BeginFigure(
				D2D1::Point2F(leftX, centerY),
				D2D1_FIGURE_BEGIN_FILLED
				);

			pSink->AddBezier(
				D2D1::BezierSegment(
					D2D1::Point2F(leftX+1*incrementX, centerY - (maxAmplitude*t)),
					D2D1::Point2F(leftX+2*incrementX, centerY + (maxAmplitude*t)),
					D2D1::Point2F(leftX+3*incrementX, centerY)
					));

			pSink->EndFigure(D2D1_FIGURE_END_OPEN);
	
			hr = pSink->Close();
		}

		SafeRelease(&pSink);
	}

	return hr;
}

void DemoApp::DiscardGeometry()
{
	SafeRelease(&pGeometry_);
}

/******************************************************************
*                                                                 *
*  DemoApp::CreateDeviceResources                              *
*                                                                 *
*  This method creates resources which are bound to a particular  *
*  D3D device. It's all centralized here, in case the resources   *
*  need to be recreated in case of D3D device loss (eg. display   *
*  change, remoting, removal of video card, etc).                 *
*                                                                 *
******************************************************************/

HRESULT DemoApp::CreateDeviceResources()
{
    HRESULT hr = S_OK;

    if (!pRT_)
    {
	    RECT rc;
		GetClientRect(hwnd_, &rc);

		D2D1_SIZE_U size = D2D1::SizeU(rc.right - rc.left, rc.bottom - rc.top);

        // Create a Direct2D render target.
        hr = pD2DFactory_->CreateHwndRenderTarget(
			D2D1::RenderTargetProperties(D2D1_RENDER_TARGET_TYPE_SOFTWARE),
                D2D1::HwndRenderTargetProperties(
                    hwnd_,
                    size
                    ),
                &pRT_
                );

        // Create a black brush.
        if (SUCCEEDED(hr))
        {
            hr = pRT_->CreateSolidColorBrush(
                D2D1::ColorF(D2D1::ColorF::Black),
                &pBlackBrush_
                );
        }
    }

    return hr;
}

/******************************************************************
*                                                                 *
*  DemoApp::DiscardDeviceResources                             *
*                                                                 *
*  Discard device-specific resources which need to be recreated   *
*  when a D3D device is lost                                      *
*                                                                 *
******************************************************************/

void DemoApp::DiscardDeviceResources()
{
    SafeRelease(&pRT_);
    SafeRelease(&pBlackBrush_);
}

void DemoApp::DrawGeometry()
{
	// First create the geometry if it doesn't exist.
	CreateGeometry();

	pRT_->DrawGeometry(
		pGeometry_,
		pBlackBrush_
		);
}

/******************************************************************
*                                                                 *
*  DemoApp::DrawText                                           *
*                                                                 *
*  This method will draw text using the IDWriteTextFormat         *
*  via the Direct2D render target                                 *
*                                                                 *
******************************************************************/

HRESULT DemoApp::DrawText()
{
	HRESULT hr = S_OK;

	if (displayString_.size() > 0)
	{
		if (SUCCEEDED(hr))
		{
			// Recreate the text layout if necessary.
			hr = CreateTextLayout();
		}

		if (SUCCEEDED(hr))
		{
			// Recreate the text renderer if necessary.
			hr = CreateTextRenderer();
		}

		if (SUCCEEDED(hr))
		{
			// Render the text.
			PATH_TEXT_DRAWING_CONTEXT dc;

			// TODO Since we're adding references to these COM objects,
			// should we call AddRef on them? Or is there a better way to
			// manage all of this? 
			dc.pBrush = pBlackBrush_;
			dc.pGeometry = pGeometry_;
			dc.pRenderTarget = pRT_;

			hr = pTextLayout_->Draw(
				&dc,
				pTextRenderer_,
				0,
				0
				);
		}
	}

    return hr;
}

HRESULT DemoApp::CreateTextLayout()
{
	HRESULT hr = S_OK;

	if (!pTextLayout_)
	{
		// TODO Set appropriate size for layout box
		RECT rc;

		GetClientRect(hwnd_, &rc);

		hr = pDWriteFactory_->CreateTextLayout(
			&(displayString_.front()), // The string to be laid out and formatted
			displayString_.size(), // The length of the string
			pTextFormat_, // The text format to apply to the string
			10000, // The width of the layout box
			static_cast<FLOAT>(rc.bottom - rc.top) / dpiScaleY_, // The height of the layout box
			&pTextLayout_ // The IDWriteTextLayout interface pointer
			);
	}
	return hr;
}

void DemoApp::DiscardTextLayout()
{
	SafeRelease(&pTextLayout_);
}

/******************************************************************
*                                                                 *
*  DemoApp::DrawD2DContent                                     *
*                                                                 *
*  This method writes "Hello World"                               *
*                                                                 *
*  Note that this function will automatically discard device-     *
*  specific resources if the D3D device disappears during         *
*  function invocation, and will recreate the resources the next  *
*  time it's invoked.                                             *
*                                                                 *
******************************************************************/

HRESULT DemoApp::DrawD2DContent()
{
    HRESULT hr;

    hr = CreateDeviceResources();

    if (SUCCEEDED(hr))
    {
        pRT_->BeginDraw();

		pRT_->SetTransform(D2D1::IdentityMatrix());

        pRT_->Clear(D2D1::ColorF(D2D1::ColorF::White));

		DrawGeometry();
		DrawText();
		
		hr = pRT_->EndDraw();
    }

    if (FAILED(hr))
    {
        DiscardDeviceResources();
    }
    
	return hr;
}


/******************************************************************
*                                                                 *
*  DemoApp::OnResize                                           *
*                                                                 *
*  If the application receives a WM_SIZE message, this method     *
*  resize the render target appropriately.                        *
*                                                                 *
******************************************************************/

void DemoApp::OnResize(UINT width, UINT height)
{
    if (pRT_)
    {
        D2D1_SIZE_U size;
        size.width = width;
        size.height = height;
        pRT_->Resize(size);
    }
}

/******************************************************************
*                                                                 *
*  Interactive3dTextSampleApp::OnChar                             *
*                                                                 *
******************************************************************/
void DemoApp::OnChar(SHORT key)
{
    if (key == '\r')
    {
		// Toggle animation
        animating_ = !animating_;
    }
    else
	{
		if (key == '\b')
		{
			// Remove a character if there are any left
			if (displayString_.size() > 0)
			{
				displayString_.pop_back();
			}
		}
		else
		{
			displayString_.push_back(key);
		}

		// Redraw the modified string
		DiscardTextLayout();
		DrawD2DContent();
	}
}

void DemoApp::OnTimer()
{
	if (!animating_)
		return;

	ticks_ += 33;

	// Discard the geometry so it will be recreated in changed form.
	DiscardGeometry();

	// Force a repaint of the window.
	InvalidateRect(hwnd_, NULL, FALSE);
}

/******************************************************************
*                                                                 *
*  DemoApp::WndProc                                            *
*                                                                 *
*  Window message handler                                         *
*                                                                 *
******************************************************************/

LRESULT CALLBACK DemoApp::WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    if (message == WM_CREATE)
    {
        LPCREATESTRUCT pcs = (LPCREATESTRUCT)lParam;
        DemoApp *pDemoApp = (DemoApp *)pcs->lpCreateParams;

        ::SetWindowLongPtrW(
            hwnd,
            GWLP_USERDATA,
            PtrToUlong(pDemoApp));

        return 1;
    }

    DemoApp *pDemoApp = reinterpret_cast<DemoApp *>(static_cast<LONG_PTR>(
                ::GetWindowLongPtrW(hwnd, GWLP_USERDATA)));

    if (pDemoApp)
    {
        switch(message)
        {
		case WM_CHAR:
			{
				pDemoApp->OnChar(static_cast<SHORT>(wParam));
			}
			return 0;

        case WM_SIZE:
            {
                UINT width = LOWORD(lParam);
                UINT height = HIWORD(lParam);
                pDemoApp->OnResize(width, height);
            }
            return 0;

        case WM_PAINT:
        case WM_DISPLAYCHANGE:
            {
                ValidateRect(hwnd, NULL);
                pDemoApp->DrawD2DContent();
            }
            return 0;

		case WM_TIMER:
			{
				pDemoApp->OnTimer();
			}
			return 0;

        case WM_DESTROY:
            {
                PostQuitMessage(0);
            }
            return 1;
        }
    }
    return DefWindowProc(
        hwnd,
        message,
        wParam,
        lParam
        );
}


