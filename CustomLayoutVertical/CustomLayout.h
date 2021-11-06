// <SnippetCustomLayouth>
// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// Copyright (c) Microsoft Corporation. All rights reserved
//
// Contents:    Main user interface window.
//
//----------------------------------------------------------------------------
#pragma once


class MainWindow
{
public:
    MainWindow()
    :   hwnd_(nullptr),
        hmonitor_(nullptr),
        textSample_(CommandIdTextLatin),
        dwriteFactory_(),
        renderingParams_(),
        renderTarget_(),
        flowLayoutSource_(),
        flowLayoutSink_(),
        flowLayout_(),
        characterMapBase_(0)
    { }

    ~MainWindow()
    {
        SafeRelease(&dwriteFactory_);
        SafeRelease(&renderingParams_);
        SafeRelease(&renderTarget_);
        SafeRelease(&flowLayoutSource_);
        SafeRelease(&flowLayoutSink_);
        SafeRelease(&flowLayout_);
    }

    HRESULT Initialize();
    WPARAM RunMessageLoop();

    static ATOM RegisterWindowClass();
    static LRESULT CALLBACK WindowProc(HWND parentHwnd, UINT message, WPARAM wParam, LPARAM lParam);

    STDMETHODIMP ReflowLayout();
    STDMETHODIMP SetCustomLayoutFontFromLogFont(const LOGFONT& logFont);

public:
    const static wchar_t* g_windowClassName;

protected:
    void OnPaint(const PAINTSTRUCT& ps);
    void OnSize();
    void OnMove();
    void OnCommand(UINT commandId);
    void OnKeyDown(UINT keyCode);

    STDMETHODIMP SetLayoutSampleText(UINT commandId);
    STDMETHODIMP SetLayoutShape(UINT commandId);
    STDMETHODIMP SetLayoutNumbers(UINT commandId);
    STDMETHODIMP SetReadingDirection(UINT commandId);
    STDMETHODIMP SetGlyphOrientationMode(UINT commandId);
    STDMETHODIMP SetJustification(UINT commandId);
    STDMETHODIMP SetCharacterMapBase(uint32_t characterMapBase);
    STDMETHODIMP OnChooseFont();
    STDMETHODIMP CopyToClipboard();
    STDMETHODIMP CopyImageToClipboard();
    STDMETHODIMP PasteFromClipboard();

    HWND hwnd_;
    HMONITOR hmonitor_;

    IDWriteFactory*             dwriteFactory_;
    IDWriteRenderingParams*     renderingParams_;
    IDWriteBitmapRenderTarget*  renderTarget_;

    FlowLayoutSource*           flowLayoutSource_;
    FlowLayoutSink*             flowLayoutSink_;
    FlowLayout*                 flowLayout_;

    int textSample_;
    uint32_t characterMapBase_;

private:
    // No copy construction allowed.
    MainWindow(const MainWindow& b);
    MainWindow& operator=(const MainWindow&);
};
// </SnippetCustomLayouth>
