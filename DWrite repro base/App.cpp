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

#include "Main.h"
#include "App.h"

#ifndef IFR
#define IFR(hr) {HRESULT tempHr = (hr); if (FAILED(tempHr)) return tempHr;}
#endif


struct PerfTime
{
    PerfTime() : iterations(0), milliseconds(0)
    {}

    PerfTime(unsigned initialIterations, unsigned initialMilliseconds)
        :   iterations(initialIterations),
        milliseconds(initialMilliseconds)
    {}

    void PreventDivisionByZero()
    {
        if (iterations   <= 0) iterations = 1;
        if (milliseconds <= 0) milliseconds = 1;
    }

    float IterationsPerSecond()
    {
        return float(iterations) * 1000 / float(milliseconds);
    }

    float IsEmpty()
    {
        return iterations == 0 && milliseconds == 0;
    }

    unsigned int iterations;
    unsigned int milliseconds;
};


/******************************************************************
*                                                                 *
*  DemoApp::DemoApp constructor                             *
*                                                                 *
*  Initialize member data                                         *
*                                                                 *
******************************************************************/

DemoApp::DemoApp()
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
    SafeRelease(&d2dFactory_);
    SafeRelease(&renderTarget_);
    SafeRelease(&blackBrush_);
    SafeRelease(&dwriteFactory_);
    SafeRelease(&textFormat_);
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
    WNDCLASSEX wcex;

    //get the dpi information
    HDC screen = GetDC(0);
    dpiScaleX_ = GetDeviceCaps(screen, LOGPIXELSX) / 96.0f;
    dpiScaleY_ = GetDeviceCaps(screen, LOGPIXELSY) / 96.0f;
    ReleaseDC(0, screen);
    
    // Return failure unless CreateDeviceIndependentResources returns SUCCEEDED.
    ATOM atom;

    // Register window class.
    wcex.cbSize        = sizeof(WNDCLASSEX);
    wcex.style         = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc   = DemoApp::WndProc;
    wcex.cbClsExtra    = 0;
    wcex.cbWndExtra    = sizeof(LONG_PTR);
    wcex.hInstance     = HINST_THISCOMPONENT;
    wcex.hbrBackground = nullptr;
    wcex.lpszMenuName  = nullptr;
    wcex.hIcon         = LoadIcon(nullptr, IDI_APPLICATION);
    wcex.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    wcex.lpszClassName = TEXT("DemoApp");
    wcex.hIconSm       = LoadIcon(nullptr, IDI_APPLICATION);

    atom = RegisterClassEx(&wcex);

    IFR(atom ? S_OK : E_FAIL);

    // Create window.
    hwnd_ = CreateWindow(
        TEXT("DemoApp"),
        TEXT("Simple DirectWrite Hello World"),
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        static_cast<int>(640.0f / dpiScaleX_),
        static_cast<int>(480.0f / dpiScaleY_),
        nullptr,
        nullptr,
        HINST_THISCOMPONENT,
        this
        );
   
    IFR(hwnd_ ? S_OK : E_FAIL);
    
    IFR(CreateDeviceIndependentResources());

    ShowWindow(hwnd_, SW_SHOWNORMAL);
    UpdateWindow(hwnd_);

    IFR(DrawD2DContent());

    return S_OK;
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
    // The string to display.
    text_ = L"Hello World using DirectWrite!";
    textLength_ = (UINT32)wcslen(text_);

    // Create Direct2D factory.
    IFR(D2D1CreateFactory(
        D2D1_FACTORY_TYPE_SINGLE_THREADED,
        &d2dFactory_
        ));

    // Create a shared DirectWrite factory.
    IFR(DWriteCreateFactory(
        DWRITE_FACTORY_TYPE_SHARED,
        __uuidof(IDWriteFactory),
        reinterpret_cast<IUnknown**>(&dwriteFactory_)
        ));

    // Create a text format using Gabriola with a font size of 72.
    // This sets the default font, weight, stretch, style, and locale.
    IFR(dwriteFactory_->CreateTextFormat(
        L"Gabriola",                // Font family name.
        nullptr,                    // Font collection (NULL sets it to use the system font collection).
        DWRITE_FONT_WEIGHT_REGULAR,
        DWRITE_FONT_STYLE_NORMAL,
        DWRITE_FONT_STRETCH_NORMAL,
        72.0f,
        L"en-us",
        &textFormat_
        ));

    // Center align (horizontally) the text.
    textFormat_->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
    textFormat_->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);

    return S_OK;
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
    RECT rc;
    GetClientRect(hwnd_, &rc);

    D2D1_SIZE_U size = D2D1::SizeU(rc.right - rc.left, rc.bottom - rc.top);

    if (!renderTarget_)
    {
        // Create a Direct2D render target.
        IFR(d2dFactory_->CreateHwndRenderTarget(
                D2D1::RenderTargetProperties(),
                D2D1::HwndRenderTargetProperties(
                    hwnd_,
                    size
                    ),
                &renderTarget_
                ));

        // Create a black brush.
        IFR(renderTarget_->CreateSolidColorBrush(
            D2D1::ColorF(D2D1::ColorF::Black),
            &blackBrush_
            ));
    }

    return S_OK;
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
    SafeRelease(&renderTarget_);
    SafeRelease(&blackBrush_);
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
    RECT rc;

    GetClientRect(hwnd_, &rc);

    // Create a D2D rect that is the same size as the window.
    D2D1_RECT_F layoutRect = D2D1::RectF(
        static_cast<FLOAT>(rc.top)             / dpiScaleX_,
        static_cast<FLOAT>(rc.left)            / dpiScaleY_,
        static_cast<FLOAT>(rc.right - rc.left) / dpiScaleX_,
        static_cast<FLOAT>(rc.bottom - rc.top) / dpiScaleY_
        );


    LARGE_INTEGER frequency, start, end;
    PerfTime time;  // initially 0 iterations, 0 time
    QueryPerformanceFrequency(&frequency);
    QueryPerformanceCounter(&start);

    // Use the DrawText method of the D2D render target interface to draw.
    renderTarget_->DrawText(
        text_,          // The string to render.
        textLength_,    // The string's length.
        textFormat_,    // The text format.
        layoutRect,     // The region of the window where the text will be rendered.
        blackBrush_     // The brush used to draw the text.
        );

    QueryPerformanceCounter(&end);
    ++time.iterations;
    time.milliseconds = (unsigned) (1000 * (end.QuadPart - start.QuadPart) / frequency.QuadPart);

    // wchar_t buffer[80];
    // swprintf(buffer, std::size_t(buffer), L"Time = %d", time.milliseconds);
    // SetWindowText(hwnd_, buffer);

    return S_OK;
}

/******************************************************************
*                                                                 *
*  DemoApp::DrawD2DContent                                     *
*                                                                 *
*  This method writes "Hello World"                               *
*                                                                 *
*  Note that this function will not render anything if the window *
*  is occluded (eg. obscured by other windows or off monitor).    *
*  Also, this function will automatically discard device-specific *
*  resources if the D3D device disappears during execution, and   *
*  will recreate the resources the next time it's invoked.        *
*                                                                 *
******************************************************************/

HRESULT DemoApp::DrawD2DContent()
{
    HRESULT hr;

    hr = CreateDeviceResources();

    if (!(renderTarget_->CheckWindowState() & D2D1_WINDOW_STATE_OCCLUDED))
    {
        renderTarget_->BeginDraw();

        renderTarget_->SetTransform(D2D1::IdentityMatrix());

        renderTarget_->Clear(D2D1::ColorF(D2D1::ColorF::White));

        if (SUCCEEDED(hr))
        {
            // Call the DrawText method of this class.
            DrawText();
        }

        if (SUCCEEDED(hr))
        {
            hr = renderTarget_->EndDraw();
        }
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
    if (renderTarget_)
    {
        D2D1_SIZE_U size = {width, height};
        renderTarget_->Resize(size);
    }
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
        DemoApp* demoApp = (DemoApp*)pcs->lpCreateParams;

        ::SetWindowLongPtrW(
            hwnd,
            GWLP_USERDATA,
            PtrToUlong(demoApp)
            );

        return 1;
    }

    DemoApp* demoApp = reinterpret_cast<DemoApp*>(static_cast<LONG_PTR>(
                ::GetWindowLongPtrW(hwnd, GWLP_USERDATA)));

    if (demoApp != nullptr)
    {
        switch(message)
        {
        case WM_SIZE:
            {
                UINT width  = LOWORD(lParam);
                UINT height = HIWORD(lParam);
                demoApp->OnResize(width, height);
            }
            return 0;

        case WM_PAINT:
        case WM_DISPLAYCHANGE:
            {
                ValidateRect(hwnd, nullptr);
                demoApp->DrawD2DContent();
            }
            return 0;

        case WM_DESTROY:
            {
                PostQuitMessage(0);
            }
            return 1;

        case WM_KEYDOWN:
            if (wParam == VK_ESCAPE)
            {
                DestroyWindow(hwnd);
            }
            return 0;
        }
    }
    return DefWindowProc(
        hwnd,
        message,
        wParam,
        lParam
        );
}
