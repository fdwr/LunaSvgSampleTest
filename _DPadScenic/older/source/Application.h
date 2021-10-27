//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Main user interface window.
//
//----------------------------------------------------------------------------
#include "precomp.h"


class MainWindow
    :   public ComBase<
            QiList<IUIApplication,
            QiList<IUICommandHandler,
            QiList<TextEditor::IOwner,
            QiList<IUnknown
        > > > > >
{
public:
    MainWindow();

    static ATOM RegisterWindowClass();
    static LRESULT CALLBACK WindowProc(HWND parentHwnd, UINT message, WPARAM wParam, LPARAM lParam);

    void Initialize();
    void InitializeControls();
    void Finalize();
    void RunMessageLoop();

public:
    ////////////////////
    // Scenic IUIApplication callbacks
    STDMETHOD(OnViewChanged)(UINT32 nViewID, __in UI_VIEWTYPE typeID, __in IUnknown* pView, UI_VIEWVERB verb, INT32 uReasonCode) OVERRIDE;
    STDMETHOD(OnCreateUICommand)(UINT32 nCmdID, __in UI_COMMANDTYPE typeID, __deref_out IUICommandHandler** ppCommandHandler) OVERRIDE;
    STDMETHOD(OnDestroyUICommand)(UINT32 commandId, __in UI_COMMANDTYPE typeID, __in_opt IUICommandHandler* pCommandHandler) OVERRIDE;

    ////////////////////
    // Scenic IUICommandHandler callbacks
    STDMETHOD(Execute)(
        UINT commandId,
    	UI_EXECUTIONVERB verb, 
    	__in_opt const PROPERTYKEY* key,
    	__in_opt const PROPVARIANT* ppropvarValue,
    	__in_opt IUISimplePropertySet* pCommandExecutionProperties
        ) OVERRIDE;
    STDMETHOD(UpdateProperty)(
        UINT commandId,
	    __in REFPROPERTYKEY key,
	    __in_opt const PROPVARIANT* ppropvarCurrentValue,
	    __out PROPVARIANT* ppropvarNewValue
        ) OVERRIDE;

    ////////////////////
    // Text editor callbacks
    virtual bool OnTextEdited(TextEditor* source,   int id) OVERRIDE;
    virtual bool OnFormatEdited(TextEditor* source, int id) OVERRIDE;
    virtual bool OnCaretMoved(TextEditor* source,   int id) OVERRIDE;
    virtual bool OnViewChanged(TextEditor* source,  int id) OVERRIDE;
    virtual bool OnContextMenu(TextEditor* source,  int id) OVERRIDE;

public:
    void GetLayoutSampleIntroduction(IDWriteEditableTextLayout& textLayout);
    void GetLayoutSampleMultilingualSample(IDWriteEditableTextLayout& textLayout);
    void GetLayoutSampleArabic(IDWriteEditableTextLayout& textLayout);
    void GetLayoutSampleChinese(IDWriteEditableTextLayout& textLayout);

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
    ComPtr<IWICBitmapSource>            inlineObjects_;

protected:
    void CreateRenderTarget(HWND hwnd, RenderTargetType renderTargetType);
    void CreateInitialSampleLayout(__out IDWriteEditableTextLayout** textLayoutOut);

    void OnSize();
    void OnSize(UINT width, UINT height);
    void OnDestroy();

    void UpdateUiToCaret(bool redrawTextEditor = true);
    void UpdateCaretToUi(IUISimplePropertySet* pCommandExecutionProperties);

    void OnLoadSample(UINT sampleId);
};
