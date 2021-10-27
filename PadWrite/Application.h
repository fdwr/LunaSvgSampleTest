//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Main user interface window.
//
//----------------------------------------------------------------------------
#include "precomp.h"


class MainWindow
:   public ComBase<QiList<IUnknown> >
{
public:
    MainWindow();

    static ATOM RegisterWindowClass();
    static LRESULT CALLBACK WindowProc(HWND parentHwnd, UINT message, WPARAM wParam, LPARAM lParam);

    void Initialize();
    WPARAM RunMessageLoop();

public:
    STDMETHODIMP CreateFontFromLOGFONT(
        const LOGFONT& logFont,
        __out IDWriteFont** font
        );

    STDMETHODIMP MainWindow::GetFontFamilyName(
        IDWriteFont* font,
        __out std::wstring& fontFamilyName
        );

protected:
    enum RenderTargetType
    {
        RenderTargetTypeD2D,
        RenderTargetTypeDW,
        RenderTargetTypeTotal
    };

    HWND hwnd_;
    ComPtr<IDWriteFactory>              dwriteFactory_;
    ComPtr<IWICImagingFactory>          wicFactory_;
    __maybenull ComPtr<ID2D1Factory>    d2dFactory_;

    ComPtr<RenderTarget>                renderTarget_;
    RenderTargetType                    renderTargetType_;

    ComPtr<TextEditor>                  textEditor_;
    ComPtr<IDWriteEditableTextLayout>   textEditorLayout_;
    ComPtr<IWICBitmapSource>            inlineObjectImages_;

protected:
    void CreateRenderTarget(HWND hwnd, RenderTargetType renderTargetType);
    void CreateWelcomeLayout(__out IDWriteEditableTextLayout** textLayoutOut);
    void SetWelcomeText(IDWriteEditableTextLayout& textLayout);

    void OnSize();
    void OnCommand(UINT commandId);
    void OnChooseFont();
    void OnSetInlineImage();
    void OnDestroy();

    void UpdateMenuToCaret();
    void RedrawTextEditor();
};
