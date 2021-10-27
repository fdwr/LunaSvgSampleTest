//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Main user interface window.
//
//----------------------------------------------------------------------------
#include "precomp.h"


ComPtr<IUIFramework> g_pScenicFramework = NULL;

static void FailApplication(__in_z const char* message, int functionResult, __in_z_opt const char* format = NULL);


////////////////////////////////////////
// Main entry.

int APIENTRY wWinMain(
    __in HINSTANCE      hInstance, 
    __in_opt HINSTANCE  hPrevInstance,
    __in LPWSTR         commandLine,
    __in int            nCmdShow
    )
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(commandLine);
    UNREFERENCED_PARAMETER(hInstance);


    HRESULT hr;

    if (FAILED(hr = CoInitialize(NULL)))
    {
        FailApplication("Could not initialize COM! CoInitialize()"  FAILURE_LOCATION, hr);
    }
    else
    {
        MainWindow app;
        app.AddRef(); // an implicit reference to the root window

        try
        {
            app.Initialize();
            app.RunMessageLoop();
        }
        catch (HrException& e)
        {
            // Print system API's HRESULT.
            FailApplication(e.what(), e.GetErrorCode());
        }
        catch (std::exception& e)
        {
            // Print STL exception description.
             FailApplication(e.what(), 0, "%s");
        }
        catch (...)
        {
            FailApplication("An unexpected error occured in the demo. Ending now...", 0, "%s");
        }
    }

    CoUninitialize();
}


void FailApplication(__in_z const char* message, int functionResult, __in_z_opt const char* format)
{
    char buffer[1000];
    buffer[0] = '\0';

    if (format == NULL)
        format = "%s\r\nError code = %X";

    StringCchPrintfA(buffer, ARRAYSIZE(buffer), format, message, functionResult);
    MessageBoxA(NULL, buffer, APPLICATION_TITLE, MB_OK|MB_ICONEXCLAMATION|MB_TASKMODAL);
    ExitProcess(functionResult);
}


MainWindow::MainWindow()
:   renderTargetType_(RenderTargetTypeD2D)
{
    // no heavyweight initialization in the constructor.
}


void MainWindow::Initialize()
{
    //////////////////////////////
    // Create the factories for D2D, DWrite, and WIC.

    HrException::IfFailed(
        DWriteCreateFactory(
            DWRITE_FACTORY_TYPE_SHARED,
            __uuidof(IDWriteFactory),
            reinterpret_cast<IUnknown**>(&dwriteFactory_)
            ),
        "Could not create DirectWrite factory! DWriteCreateFactory()" FAILURE_LOCATION
        );

    // Create D2D factory
    // Failure to create this factory is ok. We can live with GDI alone.
    D2D1CreateFactory(
        D2D1_FACTORY_TYPE_SINGLE_THREADED,
        &d2dFactory_
        );

    // Create WIC factory to load images.
    HrException::IfFailed(
        CoCreateInstance(
            CLSID_WICImagingFactory,
            NULL,
            CLSCTX_INPROC_SERVER,
            IID_IWICImagingFactory,
            reinterpret_cast<void**>(&wicFactory_)
            ),
        "Could not create Windows Imaging Component factory! CoCreateInstance(CLSID_WICImagingFactory, ...)" FAILURE_LOCATION
        );

    // Create instance of Scenic framework.
    HrException::IfFailed(
	    CoCreateInstance(
            CLSID_ScenicIntentUIFramework,
            NULL,
            CLSCTX_INPROC_SERVER,
            IID_PPV_ARGS(&g_pScenicFramework)
            ),
        "Could not create Scenic framework" FAILURE_LOCATION
        );


    //////////////////////////////
    // Create the main window

    MainWindow::RegisterWindowClass();
    TextEditor::RegisterWindowClass();

    // create window (the hwnd is stored in the create event)
    CreateWindowEx(
            WS_EX_CLIENTEDGE, // | WS_EX_LAYOUTRTL,
            L"DirectWritePadDemo",
            TEXT(APPLICATION_TITLE),
            WS_OVERLAPPEDWINDOW|WS_CLIPCHILDREN,
            CW_USEDEFAULT, CW_USEDEFAULT,
            800,
            600,
            NULL,
            NULL,
            HINST_THISCOMPONENT,
            this
            );
    if (hwnd_ == NULL)
        throw HrException(HRESULT_FROM_WIN32(GetLastError()), "Could not create main demo window! CreateWindow()"  FAILURE_LOCATION);

    //////////////////////////////
    // Initialize the controls

    // Create the ribbon.
	g_pScenicFramework->Initialize(hwnd_, this);
	g_pScenicFramework->LoadUI(GetModuleHandle(NULL), L"APPLICATION_RIBBON");

    ShowWindow(hwnd_, SW_SHOWNORMAL);
    UpdateWindow(hwnd_);

    // Create editable layout and text editor.
    CreateInitialSampleLayout(&textEditorLayout_);
    textEditor_.Set(new TextEditor(hwnd_, textEditorLayout_));
    textEditor_->SetOwner(this);

    UpdateRibbonToCaret(false);

    // Create our target on behalf of text editor control
    // and tell it to draw onto it.
    CreateRenderTarget(textEditor_->GetHwnd(), RenderTargetTypeD2D);
    textEditor_->SetRenderTarget(renderTarget_);

    // Size everything initially.
    OnSize();

    // Put focus on editor to begin typing.
    SetFocus(textEditor_->GetHwnd());
}


ATOM MainWindow::RegisterWindowClass()
{
    // register window class
    WNDCLASSEX wcex;
    wcex.cbSize        = sizeof(WNDCLASSEX);
    wcex.style         = CS_DBLCLKS;
    wcex.lpfnWndProc   = &WindowProc;
    wcex.cbClsExtra    = 0;
    wcex.cbWndExtra    = sizeof(LONG_PTR);
    wcex.hInstance     = HINST_THISCOMPONENT;
    wcex.hIcon         = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(1));
    wcex.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wcex.hbrBackground = NULL;
    wcex.lpszMenuName  = NULL;
    wcex.lpszClassName = TEXT("DirectWritePadDemo");
    wcex.hIconSm       = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(1));

    return RegisterClassEx(&wcex);
}


void MainWindow::CreateRenderTarget(HWND hwnd, RenderTargetType renderTargetType)
{
    RECT rect = {0,0,0,0};
    GetClientRect(hwnd, &rect);

    // Both D2D and DirectWrite GDI-based render targets are supported.

    switch (renderTargetType)
    {
    case RenderTargetTypeD2D:
        if (d2dFactory_ != NULL)
        {
            renderTarget_.Set(new RenderTargetD2D(d2dFactory_, dwriteFactory_, hwnd, rect));
        }
        break;

    case RenderTargetTypeDW:
        renderTargetType = RenderTargetTypeDW;
        renderTarget_.Set(new RenderTargetDW(GetDC(hwnd), dwriteFactory_, rect));
        break;

    default:
        assert(false);
        break;
    }

    renderTargetType_ = renderTargetType;
}


void MainWindow::CreateInitialSampleLayout(__out IDWriteEditableTextLayout** textLayoutOut)
{
    ComPtr<IDWriteTextFormat> textFormat;
    HrException::IfFailed(
        dwriteFactory_->CreateTextFormat(
            L"Arial",
            NULL,
            DWRITE_FONT_WEIGHT_NORMAL,
            DWRITE_FONT_STYLE_NORMAL,
            DWRITE_FONT_STRETCH_NORMAL,
            16,
            L"",
            &textFormat
            ),
        "Could not create the TextFormat for the editor!" FAILURE_LOCATION
        );

    // Create an ideal layout for the text editor, not a compatible mode
    // one like the other controls, which favor crispness of text over
    // ideal metrics.
    ComPtr<IDWriteEditableTextLayout> textLayout;
    HrException::IfFailed(
        EditableLayout::CreateEditableLayout(
			dwriteFactory_,
            L"",
            0,
            textFormat,
            750,
            410,
            &textLayout
            ),
        "Could not create the TextLayout for the editor!" FAILURE_LOCATION
        );

    // Load images for inline objects.
    InlineImage::LoadImageFromResource(L"InlineObjects", L"Image", wicFactory_, inlineObjects_);

    // Set default color of black on entire range.
    ComPtr<DrawingEffect> drawingEffect(new DrawingEffect(0xFF000000));
    textLayout->SetDrawingEffect(drawingEffect, MakeDWriteTextRange(0));

    GetLayoutSampleIntroduction(textLayout);

    // Set initial trimming sign
    // (but do not enable it)

    ComPtr<IDWriteInlineObject> inlineObject;
    HrException::IfFailed(dwriteFactory_->CreateEllipsisTrimmingSign(
        textLayout,
        &inlineObject
        ), "Could not create ellipsis trimming sign." FAILURE_LOCATION
        );
    const static DWRITE_TRIMMING trimming = { DWRITE_TRIMMING_GRANULARITY_NONE, 0, 0 };
    textLayout->SetTrimming(&trimming, inlineObject);

    *textLayoutOut = textLayout.Detach();
}


void MainWindow::RunMessageLoop()
{
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0) > 0)
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}


// Relays messages for the main window to the internal class.
//
LRESULT CALLBACK MainWindow::WindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    MainWindow* window = reinterpret_cast<MainWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));

    switch (message)
    {
    case WM_NCCREATE:
        {
            // Associate the data structure with this window handle.
            CREATESTRUCT* pcs = reinterpret_cast<CREATESTRUCT*>(lParam);
            window = reinterpret_cast<MainWindow*>(pcs->lpCreateParams);
            SetWindowLongPtr(hwnd, GWLP_USERDATA, PtrToUlong(window));
            window->hwnd_ = hwnd;
            window->AddRef(); // implicit reference via HWND
        }
        return DefWindowProc(hwnd, message, wParam, lParam);

	case WM_PAINT:
    case WM_DISPLAYCHANGE:
        // The main window has nothing to draw,
        // so simply allow the children to draw
        // themselves and validate the dirty rect.
        ValidateRect(hwnd, NULL);
		break;

    case WM_ERASEBKGND: // don't want flicker
        return true;

    case WM_SIZE:
        {
            UINT width  = LOWORD(lParam);
            UINT height = HIWORD(lParam);
            window->OnSize(width, height);
        }
        break;

	case WM_DESTROY:
        PostQuitMessage(0);
        window->OnDestroy();
        break;

    case WM_NCDESTROY:
        // Remove implicit reference via HWND.
        // After this, the window and data structure no longer exist.
        window->Release();
        break;

    case WM_SETFOCUS:
        // Forward focus to the text editor.
        SetFocus(window->textEditor_->GetHwnd());
        break;

    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    return 0;
}


STDMETHODIMP MainWindow::OnViewChanged(UINT32 nViewID, __in UI_VIEWTYPE typeID, __in IUnknown* pView, UI_VIEWVERB verb, INT32 uReasonCode)  
{ 
    if (verb == UI_VIEWVERB_SIZE)
    {
        // Resize the editor if the ribbon toggles between normal and minimized view.
        OnSize();
        return S_OK;
    }
	return E_NOTIMPL; 
}


STDMETHODIMP MainWindow::OnCreateUICommand(UINT32 nCmdID, __in UI_COMMANDTYPE typeID, __deref_out IUICommandHandler** ppCommandHandler) 
{ 
	return QueryInterface(IID_PPV_ARGS(ppCommandHandler));
}


STDMETHODIMP MainWindow::OnDestroyUICommand(
    UINT32 commandId,
    __in UI_COMMANDTYPE typeID,
    __in_opt IUICommandHandler* pCommandHandler
    )
{ 
	return E_NOTIMPL; 
}


STDMETHODIMP MainWindow::Execute(
    UINT commandId,
	UI_EXECUTIONVERB verb, 
	__in_opt const PROPERTYKEY* key,
	__in_opt const PROPVARIANT* ppropvarValue,
	__in_opt IUISimplePropertySet* pCommandExecutionProperties
    )
{
	HRESULT hr = S_OK;

    if (verb != UI_EXECUTIONVERB_EXECUTE)
        return E_NOTIMPL; // not worried about preview on mouse hover, just actual clicks.

    DWRITE_TEXT_RANGE textRange = textEditor_->GetSelectionRange();
    EditableLayout::CaretFormat& caretFormat = textEditor_->GetCaretFormat();

	switch (commandId)
	{
    case CommandIdPaste:
        textEditor_->PasteFromClipboard();
        break;

    case CommandIdCut:
        textEditor_->CopyToClipboard();
        textEditor_->DeleteSelection();
        break;

    case CommandIdCopy:
        textEditor_->CopyToClipboard();
        break;

    case CommandIdDelete:
        textEditor_->DeleteSelection();
        break;

    case CommandIdRenderD2D:
        CreateRenderTarget(textEditor_->GetHwnd(), RenderTargetTypeD2D);
        textEditor_->SetRenderTarget(renderTarget_);
        UpdateRibbonToCaret();
        break;

    case CommandIdRenderDW:
        CreateRenderTarget(textEditor_->GetHwnd(), RenderTargetTypeDW);
        textEditor_->SetRenderTarget(renderTarget_);
        UpdateRibbonToCaret();
        break;

    case CommandIdAlignLeft:
        textEditorLayout_->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_LEADING);
        UpdateRibbonToCaret();
        break;

    case CommandIdAlignHCenter:
        textEditorLayout_->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
        UpdateRibbonToCaret();
        break;

    case CommandIdAlignRight:
        textEditorLayout_->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_TRAILING);
        UpdateRibbonToCaret();
        break;

    case CommandIdAlignTop:
        textEditorLayout_->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_NEAR);
        UpdateRibbonToCaret();
        break;

    case CommandIdAlignVCenter:
        textEditorLayout_->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
        UpdateRibbonToCaret();
        break;

    case CommandIdAlignBottom:
        textEditorLayout_->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_FAR);
        UpdateRibbonToCaret();
        break;

    case CommandIdLeftToRight:
        textEditorLayout_->SetReadingDirection(DWRITE_READING_DIRECTION_LEFT_TO_RIGHT);
        UpdateRibbonToCaret();
        break;

    case CommandIdRightToLeft:
        textEditorLayout_->SetReadingDirection(DWRITE_READING_DIRECTION_RIGHT_TO_LEFT);
        UpdateRibbonToCaret();
        break;

    case CommandIdWrap:
        {
            BOOL isWrapped = TRUE;
	        IFR(PropVariantToBoolean(*ppropvarValue, &isWrapped));
            textEditorLayout_->SetWordWrapping(isWrapped ? DWRITE_WORD_WRAPPING_WRAP : DWRITE_WORD_WRAPPING_NO_WRAP);
            textEditor_->RefreshView();
            UpdateRibbonToCaret(false);
        }
        break;

    case CommandIdTrim:
        {
            BOOL isTrimmed = FALSE;
	        IFR(PropVariantToBoolean(*ppropvarValue, &isTrimmed));

            // Retrieve existing trimming sign and settings
            // and modify them according to button state.
            ComPtr<IDWriteInlineObject> inlineObject;
            DWRITE_TRIMMING trimming = { DWRITE_TRIMMING_GRANULARITY_NONE, 0, 0 };

            textEditorLayout_->GetTrimming(&trimming, &inlineObject);
            trimming.granularity = isTrimmed ? DWRITE_TRIMMING_GRANULARITY_CHARACTER : DWRITE_TRIMMING_GRANULARITY_NONE;
            textEditorLayout_->SetTrimming(&trimming, inlineObject);

            textEditor_->RefreshView();
            UpdateRibbonToCaret(false);
        }
        break;

    case CommandIdFont:
        UpdateCaretToRibbon(pCommandExecutionProperties);
        break;

    case CommandIdZoomIn:
        {
            textEditor_->SetScale(1.25f, 1.25f, true);
            OnViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case CommandIdZoomOut:
        {
            textEditor_->SetScale(1 / 1.25f, 1 / 1.25f, true);
            OnViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case CommandIdRotateCW:
        {
            textEditor_->SetAngle(90, true);
            OnViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case CommandIdRotateACW:
        {
            textEditor_->SetAngle(-90, true);
            OnViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case CommandIdFlipHorizontal:
        {
            float scaleX, scaleY;
            textEditor_->GetScale(&scaleX, &scaleY);
            textEditor_->SetScale(scaleX * -1, scaleY, false);
            OnViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case CommandIdFlipVertical:
        {
            float scaleX, scaleY;
            textEditor_->GetScale(&scaleX, &scaleY);
            textEditor_->SetScale(scaleX, scaleY * -1, false);
            OnViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case CommandIdResetView:
        {
            textEditor_->ResetView();
            OnViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case CommandIdLoadSample0:
    case CommandIdLoadSample1:
    case CommandIdLoadSample2:
    case CommandIdLoadSample3:
        OnLoadSample(commandId - CommandIdLoadSample0);
        break;

    case CommandIdExit:
        PostMessage(hwnd_, WM_CLOSE, 0, 0);
        break;

    default:
        // No action defined
        return E_NOTIMPL;
    }

	return hr;
}


#if 0 // broken!
//todo:
class ComboList
    :   public ComBase<
            QiList<IUISimplePropertySet,
            QiList<IUnknown
        > > >
{
    // IUnknown interface
    STDMETHOD(QueryInterface)(IID const& iid, __out void** ppObject) OVERRIDE
    {
        *ppObject = NULL;
        return E_NOINTERFACE;
    }

    STDMETHOD(GetValue)(      
        REFPROPERTYKEY key,
        __out PROPVARIANT *value
        ) OVERRIDE
    {
        PropVariantInit(value);
        return S_OK;
    }
};

#endif

STDMETHODIMP MainWindow::UpdateProperty(
    UINT commandId,
	__in REFPROPERTYKEY key,
	__in_opt const PROPVARIANT* ppropvarCurrentValue,
	__out PROPVARIANT* ppropvarNewValue
    )
{
	UNREFERENCED_PARAMETER(ppropvarCurrentValue);

    /*
    if (commandId == cmdTestComboBox && key == UI_PKEY_ItemsSource)
    {
        PropVariantInit(ppropvarNewValue);
        ComPtr<IUISimplePropertySet> comboList(new ComboList());
        ppropvarNewValue->vt = VT_UNKNOWN;
        ppropvarNewValue->punkVal = comboList.Detach();
    }
    */

	return E_NOTIMPL;
}


void MainWindow::OnSize()
{
    RECT rect;
    GetClientRect(hwnd_, &rect);
    OnSize(rect.right, rect.bottom);
}


void MainWindow::OnSize(UINT width, UINT height)
{
    // Update child edit control's size to fill the whole window,
    // minus what area the ribbon uses.

    // Get ribbon height.
    UINT ribbonHeight = 100;
    ComPtr<IUIRibbon> pRibbon;
    IFRV(g_pScenicFramework->GetView(0, __uuidof(IUIRibbon), reinterpret_cast<void**>(&pRibbon)));
    IFRV(pRibbon->GetHeight(&ribbonHeight));

    // Size edit accordingly
    RECT clientRect = {0, 0, width, height};
    clientRect.top = ribbonHeight;

    SetWindowPos(
        textEditor_->GetHwnd(),
        NULL,
        clientRect.left,
        clientRect.top,
        clientRect.right  - clientRect.left,
        clientRect.bottom - clientRect.top,
        SWP_NOACTIVATE|SWP_NOZORDER
        );
}


void MainWindow::OnDestroy()
{
    textEditor_.Clear();
	g_pScenicFramework.Clear();
}


bool MainWindow::OnTextEdited(TextEditor* source, int id)
{
    return true;
}


bool MainWindow::OnContextMenu(TextEditor* source, int id)
{
    // Show context menu on right click, getting the view from Scenic.
    ComPtr<IUIContextualUI> pContextualUI;
    HRESULT hr = g_pScenicFramework->GetView(CommandIdContextMenuOnly, __uuidof(IUIContextualUI), reinterpret_cast<void**>(&pContextualUI));

    if (pContextualUI != NULL)
    {
        // Get last position of mouse and display menu there.
        LPARAM lParam = GetMessagePos();
        POINT pt = {GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam)};

        pContextualUI->ShowAtLocation(pt.x, pt.y);
    }
    return true;
}


bool MainWindow::OnFormatEdited(TextEditor* source, int id)
{
    UpdateRibbonToCaret();
    return true;
}


bool MainWindow::OnCaretMoved(TextEditor* source, int id)
{
    // Update position in status bar.

    DWRITE_TEXT_RANGE range = textEditor_->GetSelectionRange();

    wchar_t buffer[100];
    buffer[0] = 0;
    StringCchPrintf(
        buffer,
        ARRAYSIZE(buffer),
        L"Caret: %dx%d",
        range.startPosition,
        range.length
        );

    #if 0 // todo:update status bar or delete?
    SetLabel(buffer, NULL);
    #endif

    UpdateRibbonToCaret(false);
    return true;
}


bool MainWindow::OnViewChanged(TextEditor* source, int id)
{
    // Update position in status bar.

    float scaleX, scaleY;
    textEditor_->GetScale(&scaleX, &scaleY);
    float scale = std::max(abs(scaleX), abs(scaleY));

    wchar_t buffer[100];
    buffer[0] = 0;
    StringCchPrintf(
        buffer,
        ARRAYSIZE(buffer),
        L"%d%%",
        int(scale * 100)
        );

    #if 0 // todo:update status bar label or delete?
    editorZoomLabel_->SetLabel(buffer, NULL);
    #endif

    return true;
}


void MainWindow::UpdateRibbonToCaret(bool redrawTextEditor)
{
    // Update buttons in the ribbon accordingly to the formatting
    // at the new caret position.

    const EditableLayout::CaretFormat& caretFormat = textEditor_->GetCaretFormat();

    // Read attributes from the layout
    DWRITE_TEXT_ALIGNMENT       textAlignment       = textEditorLayout_->GetTextAlignment();
    DWRITE_PARAGRAPH_ALIGNMENT  paragraphAlignment  = textEditorLayout_->GetParagraphAlignment();
    DWRITE_WORD_WRAPPING        wordWrapping        = textEditorLayout_->GetWordWrapping();
    DWRITE_READING_DIRECTION    readingDirection    = textEditorLayout_->GetReadingDirection();
    DWRITE_FLOW_DIRECTION       flowDirection       = textEditorLayout_->GetFlowDirection();
    DWRITE_TRIMMING             trimming            = { DWRITE_TRIMMING_GRANULARITY_NONE, 0, 0 };
    ComPtr<IDWriteInlineObject> inlineObject;

    textEditorLayout_->GetTrimming(&trimming, &inlineObject);

    // Translate them to ribbon acceptable form.
	PROPVARIANT varTrue, varFalse;

	IFRV(InitPropVariantFromBoolean(TRUE,  &varTrue));
	IFRV(InitPropVariantFromBoolean(FALSE, &varFalse));

    // Update the ribbon accordingly.
    g_pScenicFramework->SetUICommandProperty(CommandIdAlignLeft,    UI_PKEY_BooleanValue, (textAlignment == DWRITE_TEXT_ALIGNMENT_LEADING)              ? varTrue : varFalse);
    g_pScenicFramework->SetUICommandProperty(CommandIdAlignHCenter, UI_PKEY_BooleanValue, (textAlignment == DWRITE_TEXT_ALIGNMENT_CENTER)               ? varTrue : varFalse);
    g_pScenicFramework->SetUICommandProperty(CommandIdAlignRight,   UI_PKEY_BooleanValue, (textAlignment == DWRITE_TEXT_ALIGNMENT_TRAILING)             ? varTrue : varFalse);
    g_pScenicFramework->SetUICommandProperty(CommandIdAlignTop,     UI_PKEY_BooleanValue, (paragraphAlignment == DWRITE_PARAGRAPH_ALIGNMENT_NEAR)       ? varTrue : varFalse);
    g_pScenicFramework->SetUICommandProperty(CommandIdAlignVCenter, UI_PKEY_BooleanValue, (paragraphAlignment == DWRITE_PARAGRAPH_ALIGNMENT_CENTER)     ? varTrue : varFalse);
    g_pScenicFramework->SetUICommandProperty(CommandIdAlignBottom,  UI_PKEY_BooleanValue, (paragraphAlignment == DWRITE_PARAGRAPH_ALIGNMENT_FAR)        ? varTrue : varFalse);
    g_pScenicFramework->SetUICommandProperty(CommandIdLeftToRight,  UI_PKEY_BooleanValue, (readingDirection == DWRITE_READING_DIRECTION_LEFT_TO_RIGHT)  ? varTrue : varFalse);
    g_pScenicFramework->SetUICommandProperty(CommandIdRightToLeft,  UI_PKEY_BooleanValue, (readingDirection == DWRITE_READING_DIRECTION_RIGHT_TO_LEFT)  ? varTrue : varFalse);
    g_pScenicFramework->SetUICommandProperty(CommandIdWrap,         UI_PKEY_BooleanValue, (wordWrapping != DWRITE_WORD_WRAPPING_NO_WRAP)                ? varTrue : varFalse);
    g_pScenicFramework->SetUICommandProperty(CommandIdTrim,         UI_PKEY_BooleanValue, (trimming.granularity != DWRITE_TRIMMING_GRANULARITY_NONE)    ? varTrue : varFalse);
    g_pScenicFramework->SetUICommandProperty(CommandIdRenderD2D,    UI_PKEY_BooleanValue, (renderTargetType_ == RenderTargetTypeD2D)                    ? varTrue : varFalse);
    g_pScenicFramework->SetUICommandProperty(CommandIdRenderDW,     UI_PKEY_BooleanValue, (renderTargetType_ == RenderTargetTypeDW)                     ? varTrue : varFalse);

    // Update the font control part of the ribbon,
    // querying the font control for a property set.
    ComPtr<IPropertyStore> fontProperties;
    {
        PROPVARIANT varFontProperties;
        PropVariantInit(&varFontProperties);

        if (SUCCEEDED(g_pScenicFramework->GetUICommandProperty(CommandIdFont, UI_PKEY_FontProperties, &varFontProperties)))
        {
            varFontProperties.punkVal->QueryInterface(__uuidof(IPropertyStore), reinterpret_cast<void**>(&fontProperties));
        }
        PropVariantClear(&varFontProperties);
    }

    if (fontProperties != NULL)
    {
        PROPVARIANT varSet, varUnset, fontColor, fontFamilyName, fontSize;
        DECIMAL decimalFontSize;

        IFRV(InitPropVariantFromUInt32(UI_FONTPROPERTIES_SET, &varSet));
        IFRV(InitPropVariantFromUInt32(UI_FONTPROPERTIES_NOTSET, &varUnset));
        IFRV(VarDecFromR4(caretFormat.fontSize, &decimalFontSize));
        IFRV(UIInitPropertyFromDecimal(UI_PKEY_FontProperties_Size, decimalFontSize, &fontSize));
	    IFRV(InitPropVariantFromString(caretFormat.fontFamilyName.c_str(), &fontFamilyName));
        IFRV(InitPropVariantFromUInt32(DrawingEffect::SwapRgb(caretFormat.color), &fontColor));

        fontProperties->SetValue(UI_PKEY_FontProperties_Family,         fontFamilyName);
        fontProperties->SetValue(UI_PKEY_FontProperties_Size,           fontSize);
        fontProperties->SetValue(UI_PKEY_FontProperties_Bold,           (caretFormat.fontWeight > DWRITE_FONT_WEIGHT_MEDIUM) ? varSet : varUnset);
        fontProperties->SetValue(UI_PKEY_FontProperties_Italic,         (caretFormat.fontStyle  > DWRITE_FONT_STYLE_NORMAL)  ? varSet : varUnset);
        fontProperties->SetValue(UI_PKEY_FontProperties_Underline,      (caretFormat.hasUnderline != 0)                      ? varSet : varUnset);
        fontProperties->SetValue(UI_PKEY_FontProperties_Strikethrough,  (caretFormat.hasStrikethrough != 0)                  ? varSet : varUnset);
        fontProperties->SetValue(UI_PKEY_FontProperties_ForegroundColor,fontColor);
        fontProperties->Commit();

        PropVariantClear(&fontFamilyName);
    }

    if (redrawTextEditor)
        textEditor_->SetRedraw();
}


void MainWindow::UpdateCaretToRibbon(IUISimplePropertySet* pCommandExecutionProperties)
{
    // Update the caret formatting according to the ribbon.

    const DWRITE_TEXT_RANGE textRange = textEditor_->GetSelectionRange();
    EditableLayout::CaretFormat& caretFormat = textEditor_->GetCaretFormat();

    // The ribbon stores all the properties of the font chunk in a separate
    // property store (they cannot be accessed directly via the framework).
    // So acquire that property interface so we can figure out what changed.

    ComPtr<IPropertyStore> fontProperties;
    {
        PROPVARIANT varFontProperties;
        PropVariantInit(&varFontProperties);

        if (SUCCEEDED(pCommandExecutionProperties->GetValue(UI_PKEY_FontProperties_ChangedProperties, &varFontProperties)))
        {
            varFontProperties.punkVal->QueryInterface(__uuidof(IPropertyStore), reinterpret_cast<void**>(&fontProperties));
        }
        PropVariantClear(&varFontProperties);
    }
    if (fontProperties == NULL)
        return;

    DWORD fontPropertyCount;
    IFRV(fontProperties->GetCount(&fontPropertyCount));

    for (UINT i = 0; i < fontPropertyCount; i++)
    {
        // Query each changed property and update the layout accordingly.
        // Usually only a single property will have changed since the last
        // update (like someone clicking the Bold button), but it is
        // possible for more than one to be modified.
        PROPERTYKEY key;
        PROPVARIANT var;

        if (FAILED(fontProperties->GetAt(i, &key)))
        {
            continue;
        }

        fontProperties->GetValue(key, &var);

        if (key == UI_PKEY_FontProperties_Family)
        {
            textEditorLayout_->SetFontFamilyName(var.pwszVal, textRange);
            caretFormat.fontFamilyName = var.pwszVal;
        }
        else if (key == UI_PKEY_FontProperties_Size)
        {
            if (SUCCEEDED(VarR4FromDec(&var.decVal, &caretFormat.fontSize)))
            {
                textEditorLayout_->SetFontSize(caretFormat.fontSize, textRange);
            }
        }
        else if (key == UI_PKEY_FontProperties_Bold)
        {
            DWRITE_FONT_WEIGHT weight = (var.uintVal == UI_FONTPROPERTIES_SET) ? DWRITE_FONT_WEIGHT_BOLD : DWRITE_FONT_WEIGHT_NORMAL;
            textEditorLayout_->SetFontWeight(weight, textRange);
            caretFormat.fontWeight = weight;
        }
        else if (key == UI_PKEY_FontProperties_Italic)
        {
            DWRITE_FONT_STYLE style = (var.uintVal == UI_FONTPROPERTIES_SET) ? DWRITE_FONT_STYLE_ITALIC : DWRITE_FONT_STYLE_NORMAL;
            textEditorLayout_->SetFontStyle(style, textRange);
            caretFormat.fontStyle = style;
        }
        else if (key == UI_PKEY_FontProperties_Underline)
        {
            BOOL hasUnderline = (var.uintVal == UI_FONTPROPERTIES_SET);
            textEditorLayout_->SetUnderline(hasUnderline, textRange);
            caretFormat.hasUnderline = hasUnderline;
        }
        else if (key == UI_PKEY_FontProperties_Strikethrough)
        {
            BOOL hasStrikethrough = (var.uintVal == UI_FONTPROPERTIES_SET);
            textEditorLayout_->SetStrikethrough(hasStrikethrough, textRange);
            caretFormat.hasStrikethrough = hasStrikethrough;
        }
        else if (key == UI_PKEY_FontProperties_ForegroundColor)
        {
            // Set default color of black on entire range.
            UINT32 bgra = DrawingEffect::SwapRgb(var.uintVal) | 0xFF000000;
            ComPtr<DrawingEffect> drawingEffect(new DrawingEffect(bgra));
            textEditorLayout_->SetDrawingEffect(drawingEffect, textRange);
            caretFormat.color = bgra;
        }
        PropVariantClear(&var);
    }

    textEditor_->SetRedraw();
}


////////////////////////////////////////
// Layout samples


void MainWindow::OnLoadSample(UINT sampleId)
{
    struct SampleLoaderFunction
    {
        void (MainWindow::*function)(IDWriteEditableTextLayout& textLayout);
    };
    const static SampleLoaderFunction g_layoutSamplesTable[] = {
        { &MainWindow::GetLayoutSampleIntroduction },
        { &MainWindow::GetLayoutSampleMultilingualSample },
        { &MainWindow::GetLayoutSampleArabic },
        { &MainWindow::GetLayoutSampleChinese },
    };

    if (sampleId >= ARRAYSIZE(g_layoutSamplesTable))
        return;

    // Remove previous text
    textEditorLayout_->RemoveTextAt(0, UINT_MAX);
    ComPtr<DrawingEffect> drawingEffect(new DrawingEffect(0xFF000000));
    textEditorLayout_->SetDrawingEffect(drawingEffect, MakeDWriteTextRange(0));

    // Fill in new text and formatting
    (this->*g_layoutSamplesTable[sampleId].function)(textEditorLayout_);

    // Refresh ribbon and text editor.
    UpdateRibbonToCaret();

    textEditor_->SetSelection(TextEditor::SetSelectionModeAbsoluteLeading, 0, false, true);
    textEditor_->RefreshView();
}


void MainWindow::GetLayoutSampleIntroduction(IDWriteEditableTextLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"\tDirectWrite demo app\r\n"
        L"\n"
        L"Feel free to play around with the formatting options to see just some of what DWrite is capable of:\n\n"
        L"Glyph rendering, Complex script shaping, Script analysis, Bidi ordering (\x202E" L"abc" L"\x202C), Line breaking, Font fallback, "
        L"Font enumeration, ClearType rendering, Bold/Italic/Underline/Strikethrough, OpenType styles, Inline objects \xFFFC\xFFFC, "
        L"Trimming, Selection hit-testing...\r\n"
        L"\r\n"
        L"Mixed scripts: 한글 الْعَرَبيّة 中文 日本語 ภาษาไทย\r\n"
        L"CJK characters beyond BMP - 𠂢𠂤𠌫\r\n"
        L"Localized forms - Ş Ș vs Ş Ș; 与 vs 与\r\n"
        L"Incremental tabs - 1	2	3"
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAYSIZE(sampleText)-1, NULL);
    textLayout.SetReadingDirection(DWRITE_READING_DIRECTION_LEFT_TO_RIGHT);

    textLayout.SetFontFamilyName(L"Segoe UI", MakeDWriteTextRange(0));
    textLayout.SetFontSize(18, MakeDWriteTextRange(0));

    // Apply a color to the title words.
    ComPtr<DrawingEffect> drawingEffect1(new DrawingEffect(0xFF1010D0));
    ComPtr<DrawingEffect> drawingEffect2(new DrawingEffect(0xFF10D010));
    textLayout.SetDrawingEffect(drawingEffect1, MakeDWriteTextRange(0, 7));
    textLayout.SetDrawingEffect(drawingEffect2, MakeDWriteTextRange (7, 5));

    // Set title font style
    textLayout.SetFontSize(30, MakeDWriteTextRange(0, 21));
    textLayout.SetFontSize(60, MakeDWriteTextRange(1, 11));
    textLayout.SetFontStyle(DWRITE_FONT_STYLE_ITALIC, MakeDWriteTextRange(1, 20) );
    textLayout.SetFontFamilyName(L"Gabriola", MakeDWriteTextRange(1, 11));

    // Add fancy swashes
    ComPtr<IDWriteTypography> typoFeature;
    dwriteFactory_->CreateTypography(&typoFeature);
    DWRITE_FONT_FEATURE feature = {DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_7, 1};
    typoFeature->AddFontFeature(feature);
    textLayout.SetTypography(typoFeature, MakeDWriteTextRange(1,11));

    // Apply decorations on features
    textLayout.SetFontWeight(DWRITE_FONT_WEIGHT_BOLD, MakeDWriteTextRange(275, 4));
    textLayout.SetFontStyle(DWRITE_FONT_STYLE_ITALIC, MakeDWriteTextRange(280, 6) );
    textLayout.SetUnderline(TRUE, MakeDWriteTextRange(287, 9));
    textLayout.SetStrikethrough(TRUE, MakeDWriteTextRange(297, 13));
    textLayout.SetInlineObject(new InlineImage(inlineObjects_, 0), MakeDWriteTextRange(344, 1));
    textLayout.SetInlineObject(new InlineImage(inlineObjects_, 1), MakeDWriteTextRange(345, 1));

    // localized S with comma below
    textLayout.SetFontFamilyName(L"Tahoma", MakeDWriteTextRange(486, 3));
    textLayout.SetFontSize(16, MakeDWriteTextRange(486, 3));
    textLayout.SetFontFamilyName(L"Tahoma", MakeDWriteTextRange(493, 3));
    textLayout.SetFontSize(16, MakeDWriteTextRange(493, 3));
    textLayout.SetLocaleName(L"ro-ro", MakeDWriteTextRange(493, 3));

    // localized CJK
    textLayout.SetFontFamilyName(L"Arial Unicode MS", MakeDWriteTextRange(498, 1));
    textLayout.SetFontFamilyName(L"Arial Unicode MS", MakeDWriteTextRange(503, 1));
    textLayout.SetLocaleName(L"jp-JP", MakeDWriteTextRange(498, 1));
    textLayout.SetLocaleName(L"zh-CN", MakeDWriteTextRange(503, 1));
}


void MainWindow::GetLayoutSampleMultilingualSample(IDWriteEditableTextLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"English: Hello\r\n"
        L"Arabic: سلام\r\n"
        L"Thai: สวัสดีเช้านี้\r\n"
        L"Hebrew: עֲלֵיכֶם\r\n"
        L"Greek: ΣΦΧΨΩ"
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAYSIZE(sampleText)-1, NULL);
    textLayout.SetReadingDirection(DWRITE_READING_DIRECTION_LEFT_TO_RIGHT);
    textLayout.SetFontFamilyName(L"Segoe UI", MakeDWriteTextRange(0));
    textLayout.SetFontSize(20, MakeDWriteTextRange(0));
}


void MainWindow::GetLayoutSampleArabic(IDWriteEditableTextLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"لمّا كان الاعتراف بالكرامة المتأصلة في جميع أعضاء الأسرة البشرية وبحقوقهم المتساوية الثابتة هو أساس الحرية والعدل والسلام في العالم.\x2029\n"
        L"ولما كان تناسي حقوق الإنسان وازدراؤها قد أفضيا إلى أعمال همجية آذت الضمير الإنساني. وكان غاية ما يرنو إليه عامة البشر انبثاق عالم يتمتع فيه الفرد بحرية القول والعقيدة ويتحرر من الفزع والفاقة.\x2029\n"
        L"ولما كان من الضروري أن يتولى القانون حماية حقوق الإنسان لكيلا يضطر المرء آخر الأمر إلى التمرد على الاستبداد والظلم.\x2029\n"
        L"ولما كانت شعوب الأمم المتحدة قد أكدت في الميثاق من جديد إيمانها بحقوق الإنسان الأساسية وبكرامة الفرد وقدره وبما للرجال والنساء من حقوق متساوية وحزمت أمرها على أن تدفع بالرقي الاجتماعي قدمًا وأن ترفع مستوى الحياة في جو من الحرية أفسح.\x2029\n"
        L"ولما كانت الدول الأعضاء قد تعهدت بالتعاون مع الأمم المتحدة على ضمان إطراد مراعاة حقوق الإنسان والحريات الأساسية واحترامها.\x2029\n"
        L"ولما كان للإدراك العام لهذه الحقوق والحريات الأهمية الكبرى للوفاء التام بهذا التعهد.\x2029\n"
        L"فإن الجمعية العامة"
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAYSIZE(sampleText)-1, NULL);
    textLayout.SetReadingDirection(DWRITE_READING_DIRECTION_RIGHT_TO_LEFT);
    textLayout.SetFontFamilyName(L"Times New Roman", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}


void MainWindow::GetLayoutSampleChinese(IDWriteEditableTextLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"鉴 于 对 人 类 家 庭 所 有 成 员 的 固 有 尊 严 及 其 平 等 的 和 不 移 的 权 利 的 承 认, 乃 是 世 界 自 由、 正 义 与 和 平 的 基 础,\n\n"
        L"鉴 于 对 人 权 的 无 视 和 侮 蔑 已 发 展 为 野 蛮 暴 行, 这 些 暴 行 玷 污 了 人 类 的 良 心, 而 一 个 人 人 享 有 言 论 和 信 仰 自 由 并 免 予 恐 惧 和 匮 乏 的 世 界 的 来 临, 已 被 宣 布 为 普 通 人 民 的 最 高 愿 望,\n\n"
        L"鉴 于 为 使 人 类 不 致 迫 不 得 已 铤 而 走 险 对 暴 政 和 压 迫 进 行 反 叛, 有 必 要 使 人 权 受 法 治 的 保 护,\n\n"
        L"鉴 于 有 必 要 促 进 各 国 间 友 好 关 系 的 发 展,"
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAYSIZE(sampleText)-1, NULL);
    textLayout.SetReadingDirection(DWRITE_READING_DIRECTION_LEFT_TO_RIGHT);
    textLayout.SetFontFamilyName(L"Arial", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}
