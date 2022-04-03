﻿//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Main user interface window.
//
//----------------------------------------------------------------------------
#include "precomp.h"


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
    WPARAM returnCode = 0;

    if (FAILED(hr = CoInitialize(NULL)))
    {
        // Need COM initialization for WIC.
        FailApplication("Could not initialize COM! CoInitialize()"  FAILURE_LOCATION, hr);
    }
    else
    {
        MainWindow app;
        app.AddRef(); // an implicit reference to the root window

        try
        {
            app.Initialize();
            returnCode = app.RunMessageLoop();
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

    return returnCode;
}


MainWindow::MainWindow()
:   renderTargetType_(RenderTargetTypeD2D),
    hwnd_(NULL)
{
    // no heavyweight initialization in the constructor.
}


void MainWindow::Initialize()
{
    // Initializes the factories and creates the main window,
    // render target, and text editor.

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


    //////////////////////////////
    // Create the main window

    MainWindow::RegisterWindowClass();
    TextEditor::RegisterWindowClass();

    // create window (the hwnd is stored in the create event)
    CreateWindow(
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

    ShowWindow(hwnd_, SW_SHOWNORMAL);
    UpdateWindow(hwnd_);

    // Create editable layout and text editor.
    CreateWelcomeLayout(&textEditorLayout_);
    SetWelcomeText(textEditorLayout_);

    textEditor_.Attach(new TextEditor(hwnd_, textEditorLayout_), true);

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
    // Registers window class.
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
    wcex.lpszMenuName  = MAKEINTRESOURCE(1);
    wcex.lpszClassName = TEXT("DirectWritePadDemo");
    wcex.hIconSm       = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(1));

    return RegisterClassEx(&wcex);
}


void MainWindow::CreateRenderTarget(HWND hwnd, RenderTargetType renderTargetType)
{
    // Creates a render target, either a D2D surface or DirectWrite GDI DIB.
    RECT rect = {};
    GetClientRect(hwnd, &rect);

    renderTarget_.Attach(NULL);

    switch (renderTargetType)
    {
    case RenderTargetTypeD2D:
        if (d2dFactory_ != NULL)
        {
            renderTarget_.Attach(new RenderTargetD2D(d2dFactory_, dwriteFactory_, hwnd, rect), true);
            break;
        }
        __fallthrough;

    case RenderTargetTypeDW:
    default:
        renderTargetType = RenderTargetTypeDW;
        renderTarget_.Attach(new RenderTargetDW(dwriteFactory_, hwnd, rect), true);
        break;
    }

    renderTargetType_ = renderTargetType;
}


WPARAM MainWindow::RunMessageLoop()
{
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0) > 0)
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return msg.wParam;
}


LRESULT CALLBACK MainWindow::WindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    // Relays messages for the main window to the internal class.

    MainWindow* window = reinterpret_cast<MainWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));

    switch (message)
    {
    case WM_NCCREATE:
        {
            // Associate the data structure with this window handle.
            CREATESTRUCT* pcs = reinterpret_cast<CREATESTRUCT*>(lParam);
            window = reinterpret_cast<MainWindow*>(pcs->lpCreateParams);
            window->hwnd_ = hwnd;
            window->AddRef(); // implicit reference via HWND
            SetWindowLongPtr(hwnd, GWLP_USERDATA, PtrToUlong(window));
        }
        return DefWindowProc(hwnd, message, wParam, lParam);

    case WM_COMMAND:
        window->OnCommand(wParam);
        break;

    case WM_SIZE:
        window->OnSize();
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
        if (window->textEditor_ != NULL)
            SetFocus(window->textEditor_->GetHwnd());
        break;

    case WM_INITMENU:
        // Menu about to be shown. Set check marks accordingly.
        window->UpdateMenuToCaret();
        break;

    case WM_WINDOWPOSCHANGED:
        // Window moved. Update ClearType settings if changed monitor.
        if (window->renderTarget_ != NULL)
            window->renderTarget_->UpdateMonitor();

        return DefWindowProc(hwnd, message, wParam, lParam);

    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    return 0;
}


void MainWindow::OnCommand(UINT commandId)
{
    // Handles menu commands.

    DWRITE_TEXT_RANGE textRange = textEditor_->GetSelectionRange();
    EditableLayout::CaretFormat& caretFormat = textEditor_->GetCaretFormat();

	switch (commandId)
	{
    case CommandIdPaste:
        textEditor_->PasteFromClipboard();
        break;

    case CommandIdCopy:
        textEditor_->CopyToClipboard();
        break;

    case CommandIdDelete:
        textEditor_->DeleteSelection();
        break;

    case CommandIdRenderD2D:
    case CommandIdRenderDW:
        CreateRenderTarget(textEditor_->GetHwnd(), RenderTargetType(commandId - CommandIdRenderFirst));
        textEditor_->SetRenderTarget(renderTarget_);
        break;

    case CommandIdUnderline:
        caretFormat.hasUnderline = !caretFormat.hasUnderline;
        textEditorLayout_->SetUnderline(caretFormat.hasUnderline, textRange);
        RedrawTextEditor();
        break;

    case CommandIdStrikethrough:
        caretFormat.hasStrikethrough = !caretFormat.hasStrikethrough;
        textEditorLayout_->SetStrikethrough(caretFormat.hasStrikethrough, textRange);
        RedrawTextEditor();
        break;

    case CommandIdWeightLight:
    case CommandIdWeightRegular:
    case CommandIdWeightHeavy:
        caretFormat.fontWeight = DWRITE_FONT_WEIGHT((commandId - CommandIdWeightFirst) * 100);
        textEditorLayout_->SetFontWeight(caretFormat.fontWeight, textRange);
        RedrawTextEditor();
        break;

    case CommandIdStretchNarrow:
    case CommandIdStretchRegular:
    case CommandIdStretchWide:
        caretFormat.fontStretch = DWRITE_FONT_STRETCH(commandId - CommandIdStretchFirst);
        textEditorLayout_->SetFontStretch(caretFormat.fontStretch, textRange);
        RedrawTextEditor();
        break;

    case CommandIdSlantRegular:
    case CommandIdSlantItalic:
        caretFormat.fontStyle = DWRITE_FONT_STYLE(commandId - CommandIdSlantFirst);
        textEditorLayout_->SetFontStyle(caretFormat.fontStyle, textRange);
        RedrawTextEditor();
        break;

    case CommandIdFontSize8:
    case CommandIdFontSize10:
    case CommandIdFontSize12:
    case CommandIdFontSize14:
    case CommandIdFontSize16:
    case CommandIdFontSize18:
    case CommandIdFontSize20:
    case CommandIdFontSize30:
    case CommandIdFontSize60:
        caretFormat.fontSize = float(commandId - CommandIdFontSizeFirst);
        textEditorLayout_->SetFontSize(caretFormat.fontSize, textRange);
        RedrawTextEditor();
        break;

    case CommandIdFontArial:
    case CommandIdFontSegoeUI:
    case CommandIdFontGabriola:
        {
            const static wchar_t* fontNames[3] = {L"Arial", L"Segoe UI", L"Gabriola"};
            caretFormat.fontFamilyName = fontNames[commandId - CommandIdFontFirst];
            textEditorLayout_->SetFontFamilyName(caretFormat.fontFamilyName.c_str(), textRange);
            RedrawTextEditor();
        }
        break;

    case CommandIdColorRed:
    case CommandIdColorGreen:
    case CommandIdColorBlue:
    case CommandIdColorBlack:
        {
            const static UINT32 colors[4] = {0xFFD01010, 0xFF10D010, 0xFF1010D0, 0xFF000000};
            caretFormat.color = colors[commandId - CommandIdColorFirst];

            ComPtr<DrawingEffect> drawingEffect(new DrawingEffect(caretFormat.color));
            textEditorLayout_->SetDrawingEffect(drawingEffect, textRange);

            RedrawTextEditor();
        }
        break;

    case CommandIdAlignLeading:
    case CommandIdAlignHCenter:
    case CommandIdAlignTrailing:
        textEditorLayout_->SetTextAlignment(DWRITE_TEXT_ALIGNMENT(commandId - CommandIdAlignHFirst));
        RedrawTextEditor();
        break;

    case CommandIdAlignTop:
    case CommandIdAlignVCenter:
    case CommandIdAlignBottom:
        textEditorLayout_->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT(commandId - CommandIdAlignVFirst));
        RedrawTextEditor();
        break;

    case CommandIdLeftToRight:
        textEditorLayout_->SetReadingDirection(DWRITE_READING_DIRECTION_LEFT_TO_RIGHT);
        RedrawTextEditor();
        break;

    case CommandIdRightToLeft:
        textEditorLayout_->SetReadingDirection(DWRITE_READING_DIRECTION_RIGHT_TO_LEFT);
        RedrawTextEditor();
        break;

    case CommandIdWrap:
        {
            DWRITE_WORD_WRAPPING wordWrapping = textEditorLayout_->GetWordWrapping();
            textEditorLayout_->SetWordWrapping((wordWrapping == DWRITE_WORD_WRAPPING_NO_WRAP)
                                              ? DWRITE_WORD_WRAPPING_WRAP
                                              : DWRITE_WORD_WRAPPING_NO_WRAP
                                              );
            RedrawTextEditor();
        }
        break;

    case CommandIdTrim:
        {
            // Retrieve existing trimming sign and settings
            // and modify them according to button state.
            ComPtr<IDWriteInlineObject> inlineObject;
            DWRITE_TRIMMING trimming = { DWRITE_TRIMMING_GRANULARITY_NONE, 0, 0 };

            textEditorLayout_->GetTrimming(&trimming, &inlineObject);
            trimming.granularity = (trimming.granularity == DWRITE_TRIMMING_GRANULARITY_NONE)
                                 ? DWRITE_TRIMMING_GRANULARITY_CHARACTER
                                 : DWRITE_TRIMMING_GRANULARITY_NONE;
            textEditorLayout_->SetTrimming(&trimming, inlineObject);

            RedrawTextEditor();
        }
        break;

    case CommandIdZoomIn:
        textEditor_->SetScale(1.25f, 1.25f, true);
        break;

    case CommandIdZoomOut:
        textEditor_->SetScale(1 / 1.25f, 1 / 1.25f, true);
        break;

    case CommandIdRotateCW:
        textEditor_->SetAngle(90, true);
        break;

    case CommandIdRotateACW:
        textEditor_->SetAngle(-90, true);
        break;

    case CommandIdResetView:
        textEditor_->ResetView();
        break;

    case CommandIdExit:
        PostMessage(hwnd_, WM_CLOSE, 0, 0);
        break;
    }

	return;
}


void MainWindow::OnSize()
{
    // Updates the child edit control's size to fill the whole window.

    if (textEditor_ == NULL)
        return;

    RECT clientRect = {};
    GetClientRect(hwnd_, &clientRect);

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
    textEditor_.Attach(NULL);
}


void MainWindow::RedrawTextEditor()
{
    // Flags text editor to redraw itself after significant changes.

    textEditor_->RefreshView();
}


void MainWindow::UpdateMenuToCaret()
{
    // Updates the menu state according to the formatting
    // at the current caret position.

    // Read layout-wide attributes from the layout.
    DWRITE_TEXT_ALIGNMENT       textAlignment       = textEditorLayout_->GetTextAlignment();
    DWRITE_PARAGRAPH_ALIGNMENT  paragraphAlignment  = textEditorLayout_->GetParagraphAlignment();
    DWRITE_WORD_WRAPPING        wordWrapping        = textEditorLayout_->GetWordWrapping();
    DWRITE_READING_DIRECTION    readingDirection    = textEditorLayout_->GetReadingDirection();
    DWRITE_FLOW_DIRECTION       flowDirection       = textEditorLayout_->GetFlowDirection();
    DWRITE_TRIMMING             trimming            = { DWRITE_TRIMMING_GRANULARITY_NONE, 0, 0 };
    ComPtr<IDWriteInlineObject> inlineObject;
    textEditorLayout_->GetTrimming(&trimming, &inlineObject);

    // Read range specific attributes that are part of the caret.
    const EditableLayout::CaretFormat& caretFormat = textEditor_->GetCaretFormat();

    HMENU hmenu = GetMenu(hwnd_);
    CheckMenuItem(hmenu, CommandIdUnderline,        MF_BYCOMMAND | (caretFormat.hasUnderline     != 0 ? MF_CHECKED : MF_UNCHECKED));
    CheckMenuItem(hmenu, CommandIdStrikethrough,    MF_BYCOMMAND | (caretFormat.hasStrikethrough != 0 ? MF_CHECKED : MF_UNCHECKED));
    CheckMenuItem(hmenu, CommandIdWrap,             MF_BYCOMMAND | (wordWrapping != DWRITE_WORD_WRAPPING_NO_WRAP ? MF_CHECKED : MF_UNCHECKED));
    CheckMenuItem(hmenu, CommandIdTrim,             MF_BYCOMMAND | (trimming.granularity != DWRITE_TRIMMING_GRANULARITY_NONE ? MF_CHECKED : MF_UNCHECKED));

    CheckMenuRadioItem(hmenu, CommandIdAlignHFirst,     CommandIdAlignHLast,    CommandIdAlignHFirst + textAlignment,                   MF_BYCOMMAND);
    CheckMenuRadioItem(hmenu, CommandIdLeftToRight,     CommandIdRightToLeft,   CommandIdLeftToRight + readingDirection,                MF_BYCOMMAND);
    CheckMenuRadioItem(hmenu, CommandIdWeightLight,     CommandIdWeightHeavy,   CommandIdWeightFirst + caretFormat.fontWeight / 100,    MF_BYCOMMAND);
    CheckMenuRadioItem(hmenu, CommandIdStretchNarrow,   CommandIdStretchWide,   CommandIdStretchFirst + caretFormat.fontStretch,        MF_BYCOMMAND);
    CheckMenuRadioItem(hmenu, CommandIdSlantRegular,    CommandIdSlantItalic,   CommandIdSlantFirst + caretFormat.fontStyle,            MF_BYCOMMAND);
    CheckMenuRadioItem(hmenu, CommandIdRenderFirst,     CommandIdRenderLast,    CommandIdRenderFirst + renderTargetType_,               MF_BYCOMMAND);
    CheckMenuRadioItem(hmenu, CommandIdFontSizeFirst,   CommandIdFontSizeLast,  CommandIdFontSizeFirst + UINT(caretFormat.fontSize),    MF_BYCOMMAND);
}


void MainWindow::CreateWelcomeLayout(__out IDWriteEditableTextLayout** textLayoutOut)
{
    // Creates the welcome text.

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
            580,
            400,
            &textLayout
            ),
        "Could not create the TextLayout for the editor!" FAILURE_LOCATION
        );

    // Load images for inline objects.
    InlineImage::LoadImageFromResource(L"InlineObjects", L"Image", wicFactory_, &inlineObjects_);

    // Set default color of black on entire range.
    ComPtr<DrawingEffect> drawingEffect(new DrawingEffect(0xFF000000));
    textLayout->SetDrawingEffect(drawingEffect, MakeDWriteTextRange(0));

    // Set initial trimming sign, but leave it disabled (granularity is none).

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


void MainWindow::SetWelcomeText(IDWriteEditableTextLayout& textLayout)
{
    // Sets the initial sampmle text in the text editor.

    const static wchar_t sampleText[] =
        L"\tDirectWrite SDK sample\r\n"
        L"\n"
        L"Feel free to play around with the formatting options to see just some of what DWrite is capable of:\n\n"
        L"Glyph rendering, Complex script shaping, Script analysis, Bidi ordering (\x202E" L"abc" L"\x202C), Line breaking, Font fallback, "
        L"Font enumeration, ClearType rendering, Bold/Italic/Underline/Strikethrough/Narrow/Light, OpenType styles, Inline objects \xFFFC\xFFFC, "
        L"Trimming, Selection hit-testing...\r\n"
        L"\r\n"
        L"Mixed scripts: 한글 الْعَرَبيّة 中文 日本語 ภาษาไทย\r\n"
        L"CJK characters beyond BMP - 𠂢𠂤𠌫𝟙𝟚𝟛\r\n"
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

    // Set title font style.
    textLayout.SetFontSize(30, MakeDWriteTextRange(0, 25)); // first line of text
    textLayout.SetFontSize(60, MakeDWriteTextRange(1, 11)); // DirectWrite
    textLayout.SetFontStyle(DWRITE_FONT_STYLE_ITALIC, MakeDWriteTextRange(0, 25) );
    textLayout.SetFontFamilyName(L"Gabriola", MakeDWriteTextRange(1, 11));

    // Add fancy swashes.
    ComPtr<IDWriteTypography> typoFeature;
    dwriteFactory_->CreateTypography(&typoFeature);
    DWRITE_FONT_FEATURE feature = {DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_7, 1};
    typoFeature->AddFontFeature(feature);
    textLayout.SetTypography(typoFeature, MakeDWriteTextRange(1,11));

    // Apply decorations on demonstrated features.
    textLayout.SetFontWeight(DWRITE_FONT_WEIGHT_BOLD, MakeDWriteTextRange(277, 4));
    textLayout.SetFontStyle(DWRITE_FONT_STYLE_ITALIC, MakeDWriteTextRange(282, 6) );
    textLayout.SetUnderline(TRUE, MakeDWriteTextRange(289, 9));
    textLayout.SetStrikethrough(TRUE, MakeDWriteTextRange(299, 13));
    textLayout.SetFontFamilyName(L"Arial", MakeDWriteTextRange(313, 6));
    textLayout.SetFontStretch(DWRITE_FONT_STRETCH_CONDENSED, MakeDWriteTextRange(313, 6));
    textLayout.SetFontWeight(DWRITE_FONT_WEIGHT_LIGHT, MakeDWriteTextRange(320, 5));
    textLayout.SetInlineObject(new InlineImage(inlineObjects_, 0), MakeDWriteTextRange(359, 1));
    textLayout.SetInlineObject(new InlineImage(inlineObjects_, 1), MakeDWriteTextRange(360, 1));

    // Localized S with comma below.
    textLayout.SetFontFamilyName(L"Tahoma", MakeDWriteTextRange(507, 3));
    textLayout.SetFontSize(16, MakeDWriteTextRange(507, 3));
    textLayout.SetFontFamilyName(L"Tahoma", MakeDWriteTextRange(514, 3));
    textLayout.SetFontSize(16, MakeDWriteTextRange(514, 3));
    textLayout.SetLocaleName(L"ro-ro", MakeDWriteTextRange(514, 3));

    // Localized CJK, Japanese vs Han form of yú (ideograph U+4E04).
    textLayout.SetFontFamilyName(L"Arial Unicode MS", MakeDWriteTextRange(519, 1));
    textLayout.SetFontFamilyName(L"Arial Unicode MS", MakeDWriteTextRange(524, 1));
    textLayout.SetLocaleName(L"jp-JP", MakeDWriteTextRange(519, 1));
    textLayout.SetLocaleName(L"zh-CN", MakeDWriteTextRange(524, 1));
}


void FailApplication(__in_z const char* message, int functionResult, __in_z_opt const char* format)
{
    // Displays an error message and quits the program.

    char buffer[1000];
    buffer[0] = '\0';

    if (format == NULL)
        format = "%s\r\nError code = %X";

    StringCchPrintfA(buffer, ARRAYSIZE(buffer), format, message, functionResult);
    MessageBoxA(NULL, buffer, APPLICATION_TITLE, MB_OK|MB_ICONEXCLAMATION|MB_TASKMODAL);
    ExitProcess(functionResult);
}