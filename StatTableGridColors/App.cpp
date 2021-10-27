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
    SafeRelease(&brush_);
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
            &brush_
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
    SafeRelease(&brush_);
}


/******************************************************************
*                                                                 *
*  DemoApp::DrawText                                           *
*                                                                 *
*  This method will draw text using the IDWriteTextFormat         *
*  via the Direct2D render target                                 *
*                                                                 *
******************************************************************/
float sqr(float f)
{
    return f * f;
}

float mabs(float f)
{
    return float(fabs(f));
}


HRESULT DemoApp::DrawText()
{
    RECT rc;

    GetClientRect(hwnd_, &rc);

    const D2D1_COLOR_F black  = {    0,    0,    0, 1.0f };
    const D2D1_COLOR_F white  = { 1.0f, 1.0f, 1.0f, 1.0f };
    const D2D1_COLOR_F red    = { 1.0f,    0,    0, 1.0f };
    const D2D1_COLOR_F green  = {    0, 1.0f,    0, 1.0f };
    const D2D1_COLOR_F blue   =  {    0,    0, 1.0f, 1.0f };
    const D2D1_COLOR_F cyan   = {    0, 1.0f, 1.0f, 1.0f };

    const D2D1_COLOR_F brightGreen  = { 0.5f, 1.0f, 0.5f, 1.0f };
    const D2D1_COLOR_F brightRed    = { 1.0f, 0.5f, 0.5f, 1.0f };
    const D2D1_COLOR_F brightBlue   = { 0.5f, 0.5f, 1.0f, 1.0f };
    const D2D1_COLOR_F brightYellow = { 1.0f, 1.5f, 0.5f, 1.0f };

    renderTarget_->SetAntialiasMode(D2D1_ANTIALIAS_MODE_ALIASED);

    const long stepsize = 5;
    for (long y = rc.top; y < rc.bottom; y += stepsize)
    {
        for (long x = rc.left; x < rc.right; x += stepsize)
        {
            float distance1 = 0;
            float distance2 = 0;
            float distance3 = 0;
            float distance4 = 0;
            switch (distanceMode_)
            {
            case DistanceModeLinear:
                //distance1 = sqr(point1_.x - float(x)) + sqr(point1_.y - float(y));
                distance2 = sqr(point2_.x - float(x)) + sqr(point2_.y - float(y));
                distance3 = sqr(point3_.x - float(x)) + sqr(point3_.y - float(y));
                distance1 = sqr(point1_.x - float(x));
                distance4 = sqr(point1_.y - float(y));
                break;
            case DistanceModeManhattan:
                //distance1 = abs(point1_.x - float(x)) + abs(point1_.y - float(y));
                distance2 = abs(point2_.x - float(x)) + abs(point2_.y - float(y));
                distance3 = abs(point3_.x - float(x)) + abs(point3_.y - float(y));
                distance1 = abs(point1_.x - float(x));
                distance4 = abs(point1_.y - float(y));
                break;
            case DistanceModeMinComponent:
                //distance1 = std::min(mabs(point1_.x - float(x)), mabs(point1_.y - float(y)));
                distance2 = std::min(mabs(point2_.x - float(x)), mabs(point2_.y - float(y)));
                distance3 = std::min(mabs(point3_.x - float(x)), mabs(point3_.y - float(y)));
                distance1 = mabs(point1_.x - float(x));
                distance4 = mabs(point1_.y - float(y));
                break;
            case DistanceModeTear:
                //distance1 = std::min(mabs(point1_.x - float(x)), mabs(point1_.y - float(y)));
                distance2 = sqrt(sqr(point2_.x - float(x)) + sqr(point2_.y - float(y)));
                distance3 = sqrt(sqr(point3_.x - float(x)) + sqr(point3_.y - float(y)));
                distance1 = mabs(point1_.x - float(x));
                distance4 = mabs(point1_.y - float(y));
                break;
            case DistanceModeTear2:
                //distance1 = sqr(std::min(mabs(point1_.x - float(x)), mabs(point1_.y - float(y))));
                distance2 = sqr(point2_.x - float(x)) + sqr(point2_.y - float(y));
                distance3 = sqr(point3_.x - float(x)) + sqr(point3_.y - float(y));
                distance1 = sqr(mabs(point1_.x - float(x)));
                distance4 = sqr(mabs(point1_.y - float(y)));
                break;
            case DistanceModeTear3:
                //distance1 = std::min(sqr(point1_.x - float(x)), sqr(point1_.y - float(y)));
                distance2 = sqr(point2_.x - float(x)) + sqr(point2_.y - float(y));
                distance3 = sqr(point3_.x - float(x)) + sqr(point3_.y - float(y));
                distance1 = sqr(point1_.x - float(x));
                distance4 = sqr(point1_.y - float(y));
                break;
            }

            D2D1_RECT_F rect = { float(x), float(y), float(x + 1), float(y + 1) };
            brush_->SetColor(
                (distance4 <= distance1 && distance4 <= distance2 && distance4 <= distance3) ? &cyan :
                (distance1 <= distance2 && distance1 <= distance3) ? &green :
                (distance2 < distance3) ? &red : &blue
            );
            renderTarget_->FillRectangle(&rect, brush_);
        }
    }

    // Cross lines
    brush_->SetColor(&brightGreen);
    renderTarget_->FillRectangle(D2D1_RECT_F{ float(rc.left), point1_.y, float(rc.right), point1_.y + 1 }, brush_);
    renderTarget_->FillRectangle(D2D1_RECT_F{ point1_.x, float(rc.top), point1_.x + 1, float(rc.bottom) }, brush_);

    // Points 2 and 3
    brush_->SetColor(&brightRed);
    renderTarget_->FillRectangle(D2D1_RECT_F{ point2_.x - 1, point2_.y - 1, point2_.x + 2, point2_.y + 2 }, brush_);
    brush_->SetColor(&brightBlue);
    renderTarget_->FillRectangle(D2D1_RECT_F{ point3_.x - 1, point3_.y - 1, point3_.x + 2, point3_.y + 2 }, brush_);

    renderTarget_->SetAntialiasMode(D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);

#if 0
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
        brush_          // The brush used to draw the text.
        );

    QueryPerformanceCounter(&end);
    ++time.iterations;
    time.milliseconds = (unsigned) (1000 * (end.QuadPart - start.QuadPart) / frequency.QuadPart);

    // wchar_t buffer[80];
    // swprintf(buffer, std::size_t(buffer), L"Time = %d", time.milliseconds);
    // SetWindowText(hwnd_, buffer);
#endif

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

        renderTarget_->Clear(D2D1::ColorF(D2D1::ColorF::Black));

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
*  DemoApp::OnResize                                              *
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

        case WM_LBUTTONDOWN:
        case WM_RBUTTONDOWN:
        case WM_MBUTTONDOWN:
        case WM_MOUSEMOVE:
            if (wParam & (MK_LBUTTON|MK_RBUTTON|MK_MBUTTON))
            {
                auto xPos = GET_X_LPARAM(lParam);
                auto yPos = GET_Y_LPARAM(lParam);
                if (wParam & MK_LBUTTON)
                {
                    demoApp->point1_ = { float(xPos), float(yPos) };
                }
                if (wParam & MK_RBUTTON)
                {
                    demoApp->point2_ = { float(xPos), float(yPos) };
                }
                if (wParam & MK_MBUTTON)
                {
                    demoApp->point3_ = { float(xPos), float(yPos) };
                }
                InvalidateRect(hwnd, nullptr, false);
            }
            return 0;

        case WM_KEYDOWN:
            switch (wParam)
            {
            case VK_ESCAPE:
                DestroyWindow(hwnd);
                break;

            case VK_SPACE:
                demoApp->distanceMode_ = DistanceMode((demoApp->distanceMode_ + 1) % DistanceModeTotal);
                InvalidateRect(hwnd, nullptr, false);
                break;
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
