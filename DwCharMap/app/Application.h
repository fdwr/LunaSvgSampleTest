//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Main user interface window.
//
//----------------------------------------------------------------------------
#include "precomp.h"


class MainWindow : public UiContainer, public Button::Owner, public TextEditor::Owner, public ListPopup::Owner
{
public:
    typedef UiContainer Base;

    MainWindow();

    void Initialize();
    void InitializeControls();
    void Finalize();
    void RunMessageLoop();

public:
    static LRESULT CALLBACK StaticWindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    LRESULT CALLBACK WindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

    // Control implementation

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool SetStyle(StyleFlag set, StyleFlag clear) OVERRIDE;

    virtual bool KeyEnter(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyExit(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyPress(KeyboardMessage& message) OVERRIDE;

    virtual bool Destroy() OVERRIDE;

    virtual bool SetPosition(const Position& position) OVERRIDE;

    void ShowProfileDialog();

    // Callbacks

    virtual bool Activated(Button* source, int id, int value);

    virtual bool TextEdited(TextEditor* source, int id);
    virtual bool FormatEdited(TextEditor* source, int id);
    virtual bool CaretMoved(TextEditor* source, int id);
    virtual bool ViewChanged(TextEditor* source, int id);

    virtual bool Showing(ListPopup* source, int id);
    virtual bool Shown(ListPopup* source, int id);
    virtual bool Activated(ListPopup* source, int id, size_t selectedItem);
    virtual bool Canceled(ListPopup* source, int id);

public:
    void GetLayoutSampleIntroduction(IDWriteTextEditLayout& textLayout);
    void GetLayoutSampleBasicLatin(IDWriteTextEditLayout& textLayout);
    void GetLayoutSampleLatin(IDWriteTextEditLayout& textLayout);
    void GetLayoutSampleKana(IDWriteTextEditLayout& textLayout);
    void GetLayoutSampleLongString(IDWriteTextEditLayout& textLayout);
    void GetLayoutSampleVeryLongString(IDWriteTextEditLayout& textLayout);
    void GetLayoutSampleMultilingualSample(IDWriteTextEditLayout& textLayout);
    void GetLayoutSampleArabic(IDWriteTextEditLayout& textLayout);
    void GetLayoutSampleGreek(IDWriteTextEditLayout& textLayout);
    void GetLayoutSampleKorean(IDWriteTextEditLayout& textLayout);
    void GetLayoutSampleChinese(IDWriteTextEditLayout& textLayout);
    void GetLayoutSampleCyrillic(IDWriteTextEditLayout& textLayout);

protected:
    enum ControlId
    {
        ControlIdEditPaste,
        ControlIdEditCut,
        ControlIdEditCopy,
        ControlIdEditDelete,
        ControlIdFormatBold,
        ControlIdFormatItalic,
        ControlIdFormatUnderline,
        ControlIdFormatStrikethrough,
        ControlIdZoomIn,
        ControlIdZoomOut,
        ControlIdAlignLeft,
        ControlIdAlignHCenter,
        ControlIdAlignRight,
        ControlIdAlignTop,
        ControlIdAlignVCenter,
        ControlIdAlignBottom,
        ControlIdLtr,
        ControlIdRtl,
        ControlIdWrap,
        ControlIdTrim,
        ControlIdLogo,
        ControlIdGoto,
        ControlIdLocale,
        ControlIdTextEditor,
        ControlIdRibbon,
        ControlIdFont,
        ControlIdFontSize,
        ControlIdRenderFirst,
        ControlIdRenderD2D=ControlIdRenderFirst,
        ControlIdRenderDW,
        ControlIdRenderGDI,
        ControlIdRenderGDIPlus,
        ControlIdLayoutSample,
        ControlIdTypographicFeature,
        ControlIdZoom,
        ControlIdRotateRectus,
        ControlIdRotateSinister,
        ControlIdFlipHorizontal,
        ControlIdFlipVertical,
        ControlIdResetView,
        ControlIdShowProfileDialog,
    };

    enum RenderTargetType
    {
        RenderTargetTypeD2D,
        RenderTargetTypeDW,
        RenderTargetTypeGDI,
        RenderTargetTypeGDIPlus,
        RenderTargetTypeTotal
    };

    HWND hwnd_;
    ComPtr<IDWriteFactory> dwriteFactory_;
    ComPtr<IWICImagingFactory> wicFactory_;
    //__maybenull ComPtr<ID2D1Factory> d2dFactory_;

    RefCountPtr<RenderTarget> renderTarget_;
    RenderTargetType renderTargetType_;

    RefCountPtr<Ribbon> ribbon_;
    RefCountPtr<TextEditor> textEditor_;
    RefCountPtr<StatusBar> statusBar_;
    RefCountPtr<Label> caretPositionLabel_;
    RefCountPtr<Label> editorZoomLabel_;
    RefCountPtr<TextList> fontFamilyList_;
    RefCountPtr<TextList> typographicFeaturesList_;
    RefCountPtr<ProfilerWindow> profilerWindow_;

    //-ComPtr<IDWriteTextEditLayout> textEditorLayout_;

    ComPtr<IWICBitmapSource> toolbarImagesLarge_;
    ComPtr<IWICBitmapSource> toolbarImagesSmall_;

    typedef std::map<unsigned int, RefCountPtr<Button> > ButtonIdMap;
    ButtonIdMap buttonIdMap_;

protected:
    void CreateRenderTarget(RenderTargetType renderTargetType);

    void CreateInitialSampleLayout();

    void OwnAllButtons(UiControl* container);

    void UpdateRibbonControlsToCaret(TextEditor* source);
};
