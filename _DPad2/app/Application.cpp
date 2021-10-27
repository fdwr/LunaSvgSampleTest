//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Main user interface window.
//
//----------------------------------------------------------------------------
#include "precomp.h"


namespace
{
    const static float g_fontSizes[] = {8,9,10,11,12,14,16,18,20,24,36,48,60,72,84,96,108};
    const static unsigned int g_zoomSizes[] = {10,20,25,35,50,60,75,85,100,125,150,200,250,300,400,500,750,1000};
    const static wchar_t* g_locales[][2] = {
        {L"الْعَرَبيّة Arabic Egypt", L"ar-EG"},
        {L"الْعَرَبيّة Arabic Iraq", L"ar-IQ"},
        {L"中文 Chinese PRC", L"zh-CN"},
        {L"中文 Chinese Taiwan", L"zh-TW"},
        {L"English US", L"en-US"},
        {L"English UK", L"en-GB"},
        {L"한글 Hangul Korea", L"ko-KR"},
        {L"עִבְרִית Hebrew Israel", L"he-IL"},
        {L"हिन्दी Hindi India", L"hi-IN"},
        {L"日本語 Japanese", L"jp-JP"},
        {L"Romania" , L"ro-RO"},
        {L"Русский язык Russian", L"ru-RU"}
        };
    struct NameFunc
    {
        void (MainWindow::*function)(IDWriteTextEditLayout& textLayout);
        const wchar_t* name;
    };
    const static NameFunc g_layoutSamplesTable[] = {
        { &MainWindow::GetLayoutSampleIntroduction,             L"Introduction text"},
        { &MainWindow::GetLayoutSampleMultilingualSample,       L"Multilingual sample"},
        { &MainWindow::GetLayoutSampleBasicLatin,               L"Simple Latin line"},
        { &MainWindow::GetLayoutSampleLatin,                    L"Latin"},
        { &MainWindow::GetLayoutSampleKana,                     L"Kana"},
        { &MainWindow::GetLayoutSampleArabic,                   L"Arabic"},
        { &MainWindow::GetLayoutSampleCyrillic,                 L"Cyrillic"},
        { &MainWindow::GetLayoutSampleGreek,                    L"Greek"},
        { &MainWindow::GetLayoutSampleKorean,                   L"Korean"},
        { &MainWindow::GetLayoutSampleChinese,                  L"Chinese"},
        { &MainWindow::GetLayoutSampleLongString,               L"Long random Latin string"},
        { &MainWindow::GetLayoutSampleVeryLongString,           L"Very long random string"}
    };
    struct FontFeatureTagAndDescription
    {
        UINT32 tag;
        const wchar_t* name;
    };
    const static FontFeatureTagAndDescription g_typographicFeaturesTable[] = {
        {   0,                                          L"None"},
        {   DWRITE_FONT_FEATURE_TAG_FRACTIONS,          L"Fractions"},
        {   DWRITE_FONT_FEATURE_TAG_SMALL_CAPITALS,     L"Small capitals"},
        {   DWRITE_FONT_FEATURE_TAG_UNICASE,            L"Unicase"},
        {   DWRITE_FONT_FEATURE_TAG_OLD_STYLE_FIGURES,  L"Old style figures"},
        {   DWRITE_FONT_FEATURE_TAG_SUBSCRIPT,          L"Subscript"},
        {   DWRITE_FONT_FEATURE_TAG_SUPERSCRIPT,        L"Superscript"},
        {   DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_1,    L"Stylistic set 1"},
        {   DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_2,    L"Stylistic set 2"},
        {   DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_3,    L"Stylistic set 3"},
        {   DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_4,    L"Stylistic set 4"},
        {   DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_5,    L"Stylistic set 5"},
        {   DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_6,    L"Stylistic set 6"},
        {   DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_7,    L"Stylistic set 7"},
        {   DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_8,    L"Stylistic set 8"},
        {   DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_9,    L"Stylistic set 9"},
        {   DWRITE_FONT_FEATURE_TAG_STYLISTIC_SET_10,   L"Stylistic set 10"},
    };
}


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
        FailProgram("Could not initialize COM! CoInitialize()"  FAILURE_LOCATION, hr);
    }
    else
    {
        MainWindow app;
        app.IncrementRef(); // an implicit reference to the root window

        try
        {
            app.Initialize();
            app.RunMessageLoop();
            app.Finalize();
        }
        catch (OsException& e)
        {
            // Print system API's HRESULT.
            FailProgram(e.what(), e.GetErrorCode());
        }
        catch (std::exception& e)
        {
            // Print STL exception description.
             FailProgram(e.what(), 0, "%s");
        }
        catch (...)
        {
            FailProgram("An unexpected error occured in the demo. Ending now...", 0, "%s");
        }
    }

    CoUninitialize();
}


MainWindow::MainWindow()
:   UiContainer(NULL),
    renderTargetType_(RenderTargetTypeD2D)
{
    // no heavyweight initialization in the constructor.
}


void MainWindow::Initialize()
{
    //////////////////////////////
    // Create the needed factories for D2D, DWrite, and WIC.

    OsException::ThrowOnFailure(
        DWriteCreateFactory(
            DWRITE_FACTORY_TYPE_SHARED,
            __uuidof(IDWriteFactory),
            reinterpret_cast<IUnknown**>(&dwriteFactory_)
            ),
        "Could not create DirectWrite factory! DWriteCreateFactory()" FAILURE_LOCATION
        );

    // Allow all UI controls to simply share the same factory.
    UiControl::gDWriteFactory_.Set(dwriteFactory_);

    // Create D2D factory
    // Failure to create this factory is ok. We can live with GDI alone.
    D2D1CreateFactory(
        D2D1_FACTORY_TYPE_SINGLE_THREADED,
        &d2dFactory_
        );

    // Create WIC factory to load images.
    OsException::ThrowOnFailure(
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

    // register window class
    WNDCLASSEX wcex;
    wcex.cbSize        = sizeof(WNDCLASSEX);
    wcex.style         = CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS;
    wcex.lpfnWndProc   = &StaticWindowProc;
    wcex.cbClsExtra    = 0;
    wcex.cbWndExtra    = sizeof(LONG_PTR);
    wcex.hInstance     = HINST_THISCOMPONENT;
    wcex.hIcon         = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(1));
    wcex.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wcex.hbrBackground = NULL;
    wcex.lpszMenuName  = NULL;
    wcex.lpszClassName = TEXT("DirectWritePadDemo");
    wcex.hIconSm       = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(1));

    RegisterClassEx(&wcex);

    // create window (the hwnd is stored in the create event)
    CreateWindowEx(
            WS_EX_CLIENTEDGE, // | WS_EX_LAYOUTRTL,
            L"DirectWritePadDemo",
            TEXT(APPLICATION_TITLE),
            WS_OVERLAPPEDWINDOW,
            CW_USEDEFAULT, CW_USEDEFAULT,
            800,
            600,
            NULL,
            NULL,
            HINST_THISCOMPONENT,
            this
            );
    if (hwnd_ == NULL)
        throw OsException("Could not create main demo window! CreateWindow()"  FAILURE_LOCATION, HRESULT_FROM_WIN32(GetLastError()));

    ShowWindow(hwnd_, SW_SHOWNORMAL);

    // Create our target to draw the UI and text onto.
    CreateRenderTarget(RenderTargetTypeD2D);

    //////////////////////////////
    // Initialize the theme and controls

    // Get the user's reading direction and locale.
    DWRITE_READING_DIRECTION readingDirection = DWRITE_READING_DIRECTION_LEFT_TO_RIGHT;
    if (GetWindowLong(hwnd_, GWL_EXSTYLE) & WS_EX_LAYOUTRTL)
    {
        readingDirection = DWRITE_READING_DIRECTION_RIGHT_TO_LEFT;
        SetStyleDirectly(StyleFlagReadingRtl);
    }

    std::wstring locale(100, L'\0');
    GetLocaleInfoEx(LOCALE_NAME_USER_DEFAULT, LOCALE_SNAME, &locale[0], static_cast<int>(locale.size()));

    UiControl::gTheme_.Set(new UiTheme());

    // Set main atlas texture for all UI controls.
    OsException::ThrowOnFailure(
        Base::gTheme_->LoadImageFromResource(
                    L"MainTheme",
                    L"Image",
                    wicFactory_
                    ),
        "Could not load main UI theme! LoadImageFromResource()" FAILURE_LOCATION
        );

    // Load the atlas image's part coordinates.
    OsException::ThrowOnFailure(
        Base::gTheme_->LoadImagePartsFromResource(
                    L"MainTheme",
                    L"ImageParts"
                    ),
        "Could not load main UI theme part info! LoadImagePartsFromResource()" FAILURE_LOCATION
        );

    // Create text formats...
    OsException::ThrowOnFailure(
        Base::gTheme_->LoadTextFormatsFromResource(
                    L"MainTheme",
                    L"TextFormats",
                    dwriteFactory_,
                    readingDirection,
                    locale.c_str()
                    ),
        "Could not load main UI text format info! LoadTextFormatsFromResource()" FAILURE_LOCATION
        );

    // Initialize the UI itself
    InitializeControls();

    InvalidateRect(hwnd_, NULL, false);
}


void MainWindow::CreateRenderTarget(RenderTargetType renderTargetType)
{
    RECT rect = {0,0,0,0};
    GetClientRect(hwnd_, &rect);

    // Both D2D and GDI-based render targets are supported.

    switch (renderTargetType)
    {
    case RenderTargetTypeD2D:
        if (d2dFactory_ != NULL)
        {
            try
            {
                renderTarget_.Set(new UiRenderTargetD2D(d2dFactory_, dwriteFactory_, hwnd_, rect));
            }
            catch (OsException& e)
            {
                // When running on Vista without the needed DXGI & WIC updates,
                // certain exports are not found by D2D, so we fallback to GDI interrop
                // rendering and continue on. Any other error though is considered
                // serious enough to rethrow and end the program.
                if (e.GetErrorCode() != HRESULT_FROM_WIN32(ERROR_PROC_NOT_FOUND))
                    throw;
            }
            catch (...)
            {
                throw; // Bail on any other error.
            }

            // Resort to a GDI target if failed.
            if (renderTarget_ != NULL)
                break;
        }

        __fallthrough;

    case RenderTargetTypeDW:
        renderTargetType = RenderTargetTypeDW;
        renderTarget_.Set(new UiRenderTargetDW(GetDC(hwnd_), dwriteFactory_, rect));
        break;

    case RenderTargetTypeGDI:
        renderTargetType = RenderTargetTypeGDI;
        renderTarget_.Set(new UiRenderTargetGDI(GetDC(hwnd_), dwriteFactory_, rect));
        break;

    case RenderTargetTypeGDIPlus:
        renderTargetType = RenderTargetTypeGDIPlus;
        renderTarget_.Set(new UiRenderTargetGDIPlus(GetDC(hwnd_), dwriteFactory_, rect));
        break;

    default:
        assert(false);
        break;
    }

    renderTargetType_ = renderTargetType;
}


void MainWindow::Finalize()
{
    // Explicitly release resources before calling CoUnitialize.
    // Otherwise destructors may be called on static members for
    // objects that can't actually be freed (don't exist anymore).
    // This does not matter for DWrite or D2D, but it's essential
    // for any references from WIC.

    UiControl::gTheme_.Clear();
}


void MainWindow::InitializeControls()
{
    //////////////////////////////
    // Load the ribbon/toolbar images

    OsException::ThrowOnFailure(
        UiTheme::LoadImageFromResource(L"ToolbarSmall", L"Image", wicFactory_, toolbarImagesSmall_),
        "Could not load main toolbar small images! LoadImageFromResource()" FAILURE_LOCATION
        );

    OsException::ThrowOnFailure(
        UiTheme::LoadImageFromResource(L"ToolbarLarge", L"Image", wicFactory_, toolbarImagesLarge_),
        "Could not load main toolbar large images! LoadImageFromResource()" FAILURE_LOCATION
        );

    //////////////////////////////
    // Main ribbon

    ribbon_.Set(new Ribbon(this, ControlIdRibbon));

    RibbonChunk* ribbonChunk;
    ButtonGroup* buttonGroup;
    Button* button;

    ribbonChunk = new RibbonChunk(ribbon_, L"Edit");

        buttonGroup = new ButtonGroup(ribbonChunk);
        buttonGroup->SetStyle(StyleFlagVertical);

            new FlatButton(buttonGroup, L"\xFFFC\r\nPaste", new InlineImage(toolbarImagesLarge_, ControlIdEditPaste), ControlIdEditPaste);
            button = new FlatButton(buttonGroup, L"\xFFFC Cut", new InlineImage(toolbarImagesSmall_, ControlIdEditCut), ControlIdEditCut);
            button->SetStyle(StyleFlagNewLine);
            new FlatButton(buttonGroup, L"\xFFFC Copy", new InlineImage(toolbarImagesSmall_, ControlIdEditCopy), ControlIdEditCopy);
            new FlatButton(buttonGroup, L"\xFFFC Delete", new InlineImage(toolbarImagesSmall_, ControlIdEditDelete), ControlIdEditDelete);

    ribbonChunk = new RibbonChunk(ribbon_, L"Font");

        buttonGroup = new ButtonGroup(ribbonChunk, 0, true);
            button = new FlatButton(buttonGroup, L"[font family]", NULL, ControlIdFont, Button::BehaviorActiveOnPress);
            button->SetOwner(this, this);
            button->SetPosition(MakePosition(0,0,90,0));
            button->SetStyle(StyleFlagRigidWidth);

        buttonGroup = new ButtonGroup(ribbonChunk, 0, true);
            button = new FlatButton(buttonGroup, L"[font size]", NULL, ControlIdFontSize, Button::BehaviorActiveOnPress);
            button->SetOwner(this, this);
            button->SetPosition(MakePosition(0,0,30,0));
            button->SetStyle(StyleFlagRigidWidth);

        buttonGroup = new ButtonGroup(ribbonChunk, 0, false);
        buttonGroup->SetStyle(StyleFlagNewLine);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdFormatBold), ControlIdFormatBold, Button::BehaviorToggle);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdFormatItalic), ControlIdFormatItalic, Button::BehaviorToggle);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdFormatUnderline), ControlIdFormatUnderline, Button::BehaviorToggle);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdFormatStrikethrough), ControlIdFormatStrikethrough, Button::BehaviorToggle);

        buttonGroup = new ButtonGroup(ribbonChunk, 0, true);
            button = new FlatButton(buttonGroup, L"Style", NULL, ControlIdTypographicFeature, Button::BehaviorActiveOnPress);
            button->SetOwner(this, this);

    ribbonChunk = new RibbonChunk(ribbon_, L"Paragraph");

        buttonGroup = new ButtonGroup(ribbonChunk, 0, true);
        buttonGroup->SetStyle(StyleFlagReadingLtr|StyleFlagReadingExplicit, StyleFlagReadingRtl);
        buttonGroup->SetOwner(this, this);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdAlignLeft),     ControlIdAlignLeft, Button::BehaviorSwitch);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdAlignHCenter),  ControlIdAlignHCenter, Button::BehaviorSwitch);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdAlignRight),    ControlIdAlignRight, Button::BehaviorSwitch);
            buttonGroup->SetActiveMember(IsReadingRtl() ? ControlIdAlignRight : ControlIdAlignLeft);

        buttonGroup = new ButtonGroup(ribbonChunk, 0, true);
        buttonGroup->SetStyle(StyleFlagReadingLtr|StyleFlagReadingExplicit, StyleFlagReadingRtl);
        buttonGroup->SetOwner(this, this);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdLtr),    ControlIdLtr, Button::BehaviorSwitch);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdRtl),    ControlIdRtl, Button::BehaviorSwitch);
            buttonGroup->SetActiveMember(IsReadingRtl() ? ControlIdRtl : ControlIdLtr);

        buttonGroup = new ButtonGroup(ribbonChunk, 0, true);
        buttonGroup->SetStyle(StyleFlagNewLine);
        buttonGroup->SetOwner(this, this);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdAlignTop),     ControlIdAlignTop, Button::BehaviorSwitch);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdAlignVCenter), ControlIdAlignVCenter, Button::BehaviorSwitch);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdAlignBottom),  ControlIdAlignBottom, Button::BehaviorSwitch);
            buttonGroup->SetActiveMember(ControlIdAlignTop);

        buttonGroup = new ButtonGroup(ribbonChunk, 0, true);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdWrap),  ControlIdWrap, Button::BehaviorToggle);
            new FlatButton(buttonGroup, NULL, new InlineImage(toolbarImagesSmall_, ControlIdTrim),  ControlIdTrim, Button::BehaviorToggle);
            buttonGroup->SetActiveMember(ControlIdWrap);

    ribbonChunk = new RibbonChunk(ribbon_, L"View");

        buttonGroup = new ButtonGroup(ribbonChunk, 0, true);
        buttonGroup->SetOwner(this, this);
            button = new FlatButton(buttonGroup, L"D2D DrawGlyphRun",NULL,    ControlIdRenderD2D, Button::BehaviorSwitch);
            button->SetStyle(StyleFlagNewLine| (d2dFactory_ == NULL ? StyleFlagDisabled : StyleFlagNone));
            button = new FlatButton(buttonGroup, L"DW DrawGlyphRun", NULL,    ControlIdRenderDW,  Button::BehaviorSwitch);
            button->SetStyle(StyleFlagNewLine);
            button = new FlatButton(buttonGroup, L"GDI ExtTextOut",  NULL,    ControlIdRenderGDI, Button::BehaviorSwitch);
            button->SetStyle(StyleFlagNewLine);
            new Label(buttonGroup, L"/");
            new FlatButton(         buttonGroup, L"GDI+",           NULL,    ControlIdRenderGDIPlus, Button::BehaviorSwitch);
            buttonGroup->SetActiveMember(ControlIdRenderD2D + renderTargetType_);

    ribbonChunk = new RibbonChunk(ribbon_, L"Samples");

        buttonGroup = new ButtonGroup(ribbonChunk);
        buttonGroup->SetStyle(StyleFlagVertical);

        buttonGroup->SetOwner(this, this);
            new FlatButton(buttonGroup, L"Sample layout ˃", NULL, ControlIdLayoutSample, Button::BehaviorActiveOnPress);
            new FlatButton(buttonGroup, L"Profile… (F2)", NULL, ControlIdShowProfileDialog);


    //////////////////////////////
    // Text editor

    // Create the initial sample for the text editor.
    CreateInitialSampleLayout();
    textEditor_.Set(new TextEditor(this, ControlIdTextEditor, textEditorLayout_));
    textEditor_->SetOwner(this, this);            

    //////////////////////////////
    // Status bar

    statusBar_.Set(new StatusBar(this, 3));

        caretPositionLabel_.Set(new FlatButton(statusBar_, L"Caret: 0x0", NULL, ControlIdGoto));
        caretPositionLabel_->SetStyle(UiControl::StyleFlagDisabledMouseFocus);

        new StatusBar::Divider(statusBar_);
        new FlatButton(statusBar_, L"English \x202A(en-us)\x202C", NULL, ControlIdLocale, Button::BehaviorActiveOnPress);
        new StatusBar::Divider(statusBar_);

        editorZoomLabel_.Set(new FlatButton(statusBar_, L"100%", NULL, ControlIdZoom, Button::BehaviorActiveOnPress));
        new FlatButton(statusBar_, NULL, new InlineImage(toolbarImagesSmall_, ControlIdZoomIn), ControlIdZoomIn);
        new FlatButton(statusBar_, NULL, new InlineImage(toolbarImagesSmall_, ControlIdZoomOut), ControlIdZoomOut);
        new FlatButton(statusBar_, L" ↻", NULL, ControlIdRotateRectus);
        new FlatButton(statusBar_, L" ↺", NULL, ControlIdRotateSinister);
        new FlatButton(statusBar_, L" ↔", NULL, ControlIdFlipHorizontal);
        new FlatButton(statusBar_, L" ↕", NULL, ControlIdFlipVertical);
        new FlatButton(statusBar_, L" ⊡ ", NULL, ControlIdResetView);

    //////////////////////////////
    // Hook up all created buttons with this main window
    // as their owner.

    OwnAllButtons(ribbon_);
    OwnAllButtons(statusBar_);


    //////////////////////////////
    // Popup lists

    ListPopup* popup;
    TextList* list;

    // Font list
    popup = new ListPopup(this, ControlIdFont);
        list = new TextList(popup, 0, ListControl::BehaviorActiveOnRelease);
        list->SetPosition(MakePosition(0,0,160,100));
    fontFamilyList_.Set(list);
    popup->ShowOnClick(buttonIdMap_[ControlIdFont]);
    popup->SetOwner(this, this);

    // Font size list
    popup = new ListPopup(this, ControlIdFontSize);
        list = new TextList(popup, 0, ListControl::BehaviorActiveOnRelease);
        list->SetPosition(MakePosition(0,0,46,0));
        for (size_t i = 0; i < ARRAY_SIZE(g_fontSizes); ++i)
        {
            wchar_t buffer[1024];
            StringCchPrintf(buffer, ARRAY_SIZE(buffer), L"%0.0f em", g_fontSizes[i]);
            list->AddItem(buffer);
        }
    popup->ShowOnClick(buttonIdMap_[ControlIdFontSize]);
    popup->SetOwner(this, this);

    // Locale list
    popup = new ListPopup(this, ControlIdLocale);
        list = new TextList(popup, 0, ListControl::BehaviorActiveOnRelease);
        list->SetPosition(MakePosition(0,0,170,100));
        for (size_t i = 0; i < ARRAY_SIZE(g_locales); ++i)
        {
            wchar_t buffer[1024];
            StringCchPrintf(buffer, ARRAY_SIZE(buffer), L"%s \x202A(%s)", g_locales[i][0], g_locales[i][1]);
            list->AddItem(buffer);
        }
    popup->ShowOnClick(buttonIdMap_[ControlIdLocale]);
    popup->SetOwner(this, this);

    // Sample layouts
    popup = new ListPopup(this, ControlIdLayoutSample);
        list = new TextList(popup, 0, ListControl::BehaviorActiveOnRelease);
        list->SetPosition(MakePosition(0,0,160,100));
        for (size_t i = 0; i < ARRAY_SIZE(g_layoutSamplesTable); ++i)
        {
            wchar_t buffer[1024];
            StringCchPrintf(buffer, ARRAY_SIZE(buffer), L"%s", g_layoutSamplesTable[i].name);
            list->AddItem(buffer);
        }
    popup->ShowOnClick(buttonIdMap_[ControlIdLayoutSample]);
    popup->SetOwner(this, this);

    // Stylistic sets
    popup = new ListPopup(this, ControlIdTypographicFeature);
        list = new TextList(popup, 0, ListControl::BehaviorActiveOnRelease);
        list->SetPosition(MakePosition(0,0,160,100));
        for (size_t i = 0; i < ARRAY_SIZE(g_typographicFeaturesTable); ++i)
        {
            wchar_t buffer[1024];
            char tag[5] = {};
            *( reinterpret_cast<UINT32*>(&tag[0]) ) = g_typographicFeaturesTable[i].tag;
            StringCchPrintf(buffer, ARRAY_SIZE(buffer), L"%s (%S)", g_typographicFeaturesTable[i].name, tag);
            list->AddItem(buffer);
        }
    typographicFeaturesList_.Set(list);
    popup->ShowOnClick(buttonIdMap_[ControlIdTypographicFeature]);
    popup->SetOwner(this, this);

    // Zoom sizes
    popup = new ListPopup(this, ControlIdZoom);
        list = new TextList(popup, 0, ListControl::BehaviorActiveOnRelease);
        list->SetPosition(MakePosition(0,0,46,0));
        for (size_t i = 0; i < ARRAY_SIZE(g_zoomSizes); ++i)
        {
            wchar_t buffer[1024];
            StringCchPrintf(buffer, ARRAY_SIZE(buffer), L"%d%%", g_zoomSizes[i]);
            list->AddItem(buffer);
        }
    popup->ShowOnClick(buttonIdMap_[ControlIdZoom]);
    popup->SetOwner(this, this);


    //////////////////////////////
    // All done. Set focus to start typing...

    UpdateRibbonControlsToCaret(textEditor_);

    textEditor_->SetKeyFocus();
}


void MainWindow::OwnAllButtons(UiControl* container)
{
    // Iterate through all the controls, looking for buttons and recursing as needed.
    size_t childrenTotal = 0;
    container->GetChild(NULL, &childrenTotal);

    for (size_t childIndex = 0; childIndex < childrenTotal; ++childIndex)
    {
        UiControlRefPtr child;
        if (container->GetChild(childIndex, child) && child != NULL)
        {
            // Look for any buttons and set their owner.
            // Otherwise it's probably a container, so recurse.
            Button* button = dynamic_cast<Button*>(child.Get());

            if (button != NULL)
            {
                // If no owner is set, then assign the main window as one.
                // This is important in case one control is listening to another,
                // like a drop-down list listening for clicks.
                if (!button->GetOwner(NULL,NULL))
                    button->SetOwner(this, this);

                buttonIdMap_[button->id_] = RefCountPtr<Button>(button);
            }
            else
            {
                OwnAllButtons(child);
            }
        }
    }
}


void MainWindow::CreateInitialSampleLayout()
{
    // Create an ideal layout for the text editor, not a compatible mode
    // one like the other controls, which favor crispness of text over
    // ideal metrics.
    OsException::ThrowOnFailure(
        DWritePad::Implementation::CEditableLayout::CreateEditableLayout(
			dwriteFactory_,
            L"",
            0,
            Base::gTheme_->GetTextFormat(ThemePartIdDefault),
            100, // actual size will be adjusted later by text editor
            100,
            &textEditorLayout_.Clear()
            ),
        "Could not create the TextLayout for the UI!" FAILURE_LOCATION
        );

    ComPtr<DrawingEffect> drawingEffect(new DrawingEffect(0xFF000000));
    textEditorLayout_->SetDrawingEffect(drawingEffect, MakeDWriteTextRange(0));

    GetLayoutSampleIntroduction(textEditorLayout_);

    // Set initial trimming sign
    // (but do not enable it)
    ComPtr<IDWriteInlineObject> inlineObject;
    OsException::ThrowOnFailure(dwriteFactory_->CreateEllipsisTrimmingSign(
        textEditorLayout_,
        &inlineObject
        ), "Could not create ellipsis trimming sign." FAILURE_LOCATION
        );
    const static DWRITE_TRIMMING trimming = { DWRITE_TRIMMING_GRANULARITY_NONE, 0, 0 };
    textEditorLayout_->SetTrimming(&trimming, inlineObject);
}



void MainWindow::RunMessageLoop()
{
    MSG msg;
    ShowWindow(hwnd_, SW_SHOWNORMAL);

    while (GetMessage(&msg, NULL, 0, 0) > 0)
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}


// Relays messages for the main window to the internal class
// and stores the class pointer upon creation.
//
LRESULT CALLBACK MainWindow::StaticWindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    MainWindow* window = reinterpret_cast<MainWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
    return window->WindowProc(hwnd, message, wParam, lParam);
}


// Processes messages for the main window.
//
LRESULT CALLBACK MainWindow::WindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_NCCREATE:
        {
            // Create the main window associated with this window handle.
            CREATESTRUCT* pcs = reinterpret_cast<CREATESTRUCT*>(lParam);
            MainWindow* window = reinterpret_cast<MainWindow*>(pcs->lpCreateParams);
            SetWindowLongPtr(hwnd, GWLP_USERDATA, PtrToUlong(window));
            window->hwnd_ = hwnd;

            return DefWindowProc(hwnd, message, wParam, lParam);
        }

	case WM_PAINT:
    case WM_DISPLAYCHANGE:
        {
            PAINTSTRUCT ps;
    	    BeginPaint(hwnd, &ps);

            if (NeedsReflow())
                SetPosition(position_);

            if (renderTarget_ != NULL) // in case event received before we have a target
            {
                renderTarget_->BeginDraw();
                RECT rect;
                GetClientRect(hwnd, &rect);
                Position uiRect = {float(rect.left),
                                   float(rect.top),
                                   float(rect.right),
                                   float(rect.bottom)
                                  };
                Draw(*renderTarget_, uiRect);
                renderTarget_->EndDraw();

                ClearStyleDirectly(StyleFlagRedraw);
            }

            EndPaint(hwnd, &ps);
        }
		break;

    case WM_ERASEBKGND: // don't want flicker
        return true;

    case WM_SIZE:
        {
            UINT width = LOWORD(lParam);
            UINT height = HIWORD(lParam);

            if (renderTarget_ != NULL)
                renderTarget_->Resize(width, height);

            // Adjust the main window's internal size to match that of the
            // top level window's client rect.
            Position position = {0,0,float(width),float(height)};
            SetPosition(position);
        }
        break;

	case WM_DESTROY:
        PostQuitMessage(-1);
        Destroy();
        break;

    case WM_SYSKEYDOWN:
    case WM_KEYDOWN:
    case WM_KEYUP:
    case WM_CHAR:
    case WM_SETFOCUS:
    case WM_KILLFOCUS:
        UiDispatcher::DispatchKeyboard(this, message, wParam, lParam);
        if (message == WM_SYSKEYDOWN) // for Alt+F4 and similar
            return DefWindowProc(hwnd, message, wParam, lParam);
        break;

    case WM_LBUTTONDOWN:
    case WM_RBUTTONDOWN:
    case WM_MBUTTONDOWN:
    case WM_XBUTTONDOWN:
    case WM_LBUTTONDBLCLK:
    case WM_MBUTTONDBLCLK:
    case WM_RBUTTONDBLCLK:
        SetFocus(hwnd);
        SetCapture(hwnd);

        UiDispatcher::DispatchMouse(this, hwnd, message, wParam, lParam);
        break;

    case WM_LBUTTONUP:
    case WM_RBUTTONUP:
    case WM_MBUTTONUP:
    case WM_XBUTTONUP:
        ReleaseCapture();
        UiDispatcher::DispatchMouse(this, hwnd, message, wParam, lParam);
        break;

    case WM_MOUSEMOVE:
    case WM_MOUSEWHEEL:
    case WM_MOUSEHWHEEL:
        UiDispatcher::DispatchMouse(this, hwnd, message, wParam, lParam);
        break;

    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    return 0;
}


bool MainWindow::Activated(Button* source, int id, int value)
{
    DWRITE_TEXT_RANGE textRange = textEditor_->GetSelectionRange();
    CaretFormattingAttributes& caretFormat = textEditor_->GetCaretFormat();

    switch (id)
    {
    case ControlIdEditPaste:
        textEditor_->PasteFromClipboard();
        break;

    case ControlIdEditCut:
        textEditor_->CopyToClipboard();
        textEditor_->DeleteSelection();
        break;

    case ControlIdEditCopy:
        textEditor_->CopyToClipboard();
        break;

    case ControlIdEditDelete:
        textEditor_->DeleteSelection();
        break;

    case ControlIdRenderD2D:
        CreateRenderTarget(RenderTargetTypeD2D);
        SetRedraw();
        break;

    case ControlIdRenderDW:
        CreateRenderTarget(RenderTargetTypeDW);
        SetRedraw();
        break;

    case ControlIdRenderGDI:
        CreateRenderTarget(RenderTargetTypeGDI);
        SetRedraw();
        break;

    case ControlIdRenderGDIPlus:
        CreateRenderTarget(RenderTargetTypeGDIPlus);
        SetRedraw();
        break;

    case ControlIdFormatBold:
        {
            DWRITE_FONT_WEIGHT weight = source->IsActive() ? DWRITE_FONT_WEIGHT_BOLD : DWRITE_FONT_WEIGHT_NORMAL;
            textEditorLayout_->SetFontWeight(weight, textRange);
            caretFormat.fontWeight = weight;
        }
        break;

    case ControlIdFormatItalic:
        {
            DWRITE_FONT_STYLE style = source->IsActive() ? DWRITE_FONT_STYLE_ITALIC : DWRITE_FONT_STYLE_NORMAL;
            textEditorLayout_->SetFontStyle(style, textRange);
            caretFormat.fontStyle = style;
        }
        break;

    case ControlIdFormatUnderline:
        {
            BOOL hasUnderline = static_cast<BOOL>(source->IsActive());
            textEditorLayout_->SetUnderline(hasUnderline, textRange);
            caretFormat.hasUnderline = hasUnderline;
        }
        break;

    case ControlIdFormatStrikethrough:
        {
            BOOL hasStrikethrough = source->IsActive();
            textEditorLayout_->SetStrikethrough(hasStrikethrough, textRange);
            caretFormat.hasStrikethrough = hasStrikethrough;
        }
        break;

    case ControlIdAlignLeft:
        textEditorLayout_->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_LEADING);
        textEditor_->SetRedraw();
        break;

    case ControlIdAlignHCenter:
        textEditorLayout_->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
        textEditor_->SetRedraw();
        break;

    case ControlIdAlignRight:
        textEditorLayout_->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_TRAILING);
        textEditor_->SetRedraw();
        break;

    case ControlIdAlignTop:
        textEditorLayout_->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_NEAR);
        break;

    case ControlIdAlignVCenter:
        textEditorLayout_->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
        break;

    case ControlIdAlignBottom:
        textEditorLayout_->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_FAR);
        break;

    case ControlIdLtr:
        textEditorLayout_->SetReadingDirection(DWRITE_READING_DIRECTION_LEFT_TO_RIGHT);
        break;

    case ControlIdRtl:
        textEditorLayout_->SetReadingDirection(DWRITE_READING_DIRECTION_RIGHT_TO_LEFT);
        break;

    case ControlIdWrap:
        textEditorLayout_->SetWordWrapping(source->IsActive() ? DWRITE_WORD_WRAPPING_WRAP : DWRITE_WORD_WRAPPING_NO_WRAP);
        break;

    case ControlIdTrim:
        {
            // Retrieve existing trimming sign and settings
            // and toggle them.
            ComPtr<IDWriteInlineObject> inlineObject;
            DWRITE_TRIMMING trimming = { DWRITE_TRIMMING_GRANULARITY_NONE, 0, 0 };
            textEditorLayout_->GetTrimming(&trimming, &inlineObject);
            trimming.granularity = source->IsActive() ? DWRITE_TRIMMING_GRANULARITY_CHARACTER : DWRITE_TRIMMING_GRANULARITY_NONE;
            textEditorLayout_->SetTrimming(&trimming, inlineObject);
        }
        break;

    case ControlIdShowProfileDialog:
        ShowProfileDialog();
        break;

    case ControlIdZoomIn:
        {
            float scaleX, scaleY;
            textEditor_->GetScale(&scaleX, &scaleY);
            textEditor_->SetScale(scaleX * 1.125f, scaleY * 1.125f, false);
            ViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case ControlIdZoomOut:
        {
            float scaleX, scaleY;
            textEditor_->GetScale(&scaleX, &scaleY);
            textEditor_->SetScale(scaleX / 1.125f, scaleY / 1.125f, false);
            ViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case ControlIdRotateRectus:
        {
            textEditor_->SetAngle(90, true);
            ViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case ControlIdRotateSinister:
        {
            textEditor_->SetAngle(-90, true);
            ViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case ControlIdFlipHorizontal:
        {
            float scaleX, scaleY;
            textEditor_->GetScale(&scaleX, &scaleY);
            textEditor_->SetScale(scaleX * -1, scaleY, false);
            ViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case ControlIdFlipVertical:
        {
            float scaleX, scaleY;
            textEditor_->GetScale(&scaleX, &scaleY);
            textEditor_->SetScale(scaleX, scaleY * -1, false);
            ViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    case ControlIdResetView:
        {
            textEditor_->ResetView();
            ViewChanged(textEditor_, textEditor_->id_);
        }
        break;

    default:
        // No action defined
        return false;
    }

    return true;
}


void MainWindow::ShowProfileDialog()
{
    ProfilerWindow* window = profilerWindow_;
    if (window != NULL)
    {
        // reinsert the child, essentially moving it to the top
        InsertChild(window);
    }
    else
    {
        window =
            new ProfilerWindow(
                this,
                textEditorLayout_,
                dwriteFactory_,
                d2dFactory_,
                hwnd_
                );
        profilerWindow_.Set(window);
    }
    Position dialogPosition = {0,0,FLT_MAX,FLT_MAX};
    window->GetPosition(PositionQueryPreferred, &dialogPosition);
    dialogPosition.x = floor((position_.w - dialogPosition.w) / 2);
    dialogPosition.y = floor((position_.h - dialogPosition.h) / 2);
    window->SetPosition(dialogPosition);

    SetKeyFocus(window, true);
}


bool MainWindow::TextEdited(TextEditor* source, int id)
{
    return false;
}


bool MainWindow::FormatEdited(TextEditor* source, int id)
{
    UpdateRibbonControlsToCaret(source);
    return true;
}


bool MainWindow::CaretMoved(TextEditor* source, int id)
{
    // Update position in status bar.

    DWRITE_TEXT_RANGE range = textEditor_->GetSelectionRange();

    wchar_t buffer[100];
    buffer[0] = 0;
    StringCchPrintf(
        buffer,
        ARRAY_SIZE(buffer),
        L"Caret: %dx%d",
        range.startPosition,
        range.length
        );
    caretPositionLabel_->SetLabel(buffer, NULL);

    UpdateRibbonControlsToCaret(source);

    return true;
}


bool MainWindow::ViewChanged(TextEditor* source, int id)
{
    // Update position in status bar.

    float scaleX, scaleY;
    textEditor_->GetScale(&scaleX, &scaleY);
    float scale = std::max(abs(scaleX), abs(scaleY));

    wchar_t buffer[100];
    buffer[0] = 0;
    StringCchPrintf(
        buffer,
        ARRAY_SIZE(buffer),
        L"%d%%",
        int(scale * 100)
        );
    editorZoomLabel_->SetLabel(buffer, NULL);

    return true;
}


void MainWindow::UpdateRibbonControlsToCaret(TextEditor* source)
{
    // Update buttons in the ribbon accordingly to the formatting
    // at the new caret position.

    struct Helpers
    {
        static void SetActiveState(ButtonIdMap& buttonIdMap, int buttonId, bool state)
        {
            ButtonIdMap::iterator button = buttonIdMap.find(buttonId);
            if (button == buttonIdMap.end())
                return;

            button->second->SetStyle(state ? StyleFlagActive : StyleFlagNone, StyleFlagActive);
        }
    };

    const CaretFormattingAttributes& caretFormat = textEditor_->GetCaretFormat();

    Helpers::SetActiveState(buttonIdMap_, ControlIdFormatBold, (caretFormat.fontWeight > DWRITE_FONT_WEIGHT_MEDIUM));
    Helpers::SetActiveState(buttonIdMap_, ControlIdFormatItalic, (caretFormat.fontStyle > DWRITE_FONT_STYLE_NORMAL));
    Helpers::SetActiveState(buttonIdMap_, ControlIdFormatStrikethrough, (caretFormat.hasStrikethrough != 0));
    Helpers::SetActiveState(buttonIdMap_, ControlIdFormatUnderline, (caretFormat.hasUnderline != 0));
    buttonIdMap_[ControlIdFont]->SetLabel(caretFormat.fontFamilyName.c_str());

    __nullterminated wchar_t buffer[1024];
    buffer[0] = 0;
    StringCchPrintf(buffer, ARRAY_SIZE(buffer), L"%0.0f", caretFormat.fontSize);
    buttonIdMap_[ControlIdFontSize]->SetLabel(buffer);

    buttonIdMap_[ControlIdLocale]->SetLabel(caretFormat.localeName.c_str());
    buttonIdMap_[ControlIdLocale]->SetReflow();
}


bool MainWindow::Showing(ListPopup* source, int id)
{
    switch (id)
    {
    case ControlIdFont:
        {
            // Refresh SystemFontCollection and rebuild list.

            fontFamilyList_->ClearItems();

            ComPtr<IDWriteFontCollection> fontCollection;
            OsException::ThrowOnFailure(
                dwriteFactory_->GetSystemFontCollection(&fontCollection.Clear()),
                "Could not obtain system font collection! GetSystemFontCollection()" FAILURE_LOCATION
                );

            UINT32 familyTotal = fontCollection->GetFontFamilyCount();

            for (UINT32 familyIndex = 0; familyIndex < familyTotal; ++familyIndex)
            {
                ComPtr<IDWriteFontFamily> fontFamily;
                OsException::ThrowOnFailure(
                    fontCollection->GetFontFamily(familyIndex, &fontFamily),
                    "Could not read font family!" FAILURE_LOCATION
                    );

                // Read the font family name
                wchar_t familyName[1024];

                ComPtr<IDWriteLocalizedStrings> familyNames;
                OsException::ThrowOnFailure(
                    fontFamily->GetFamilyNames(&familyNames),
                    "Could not get font family names!" FAILURE_LOCATION
                    );
                OsException::ThrowOnFailure(
                    familyNames->GetString(0, familyName, ARRAY_SIZE(familyName)),
                    "Could not read font family name!" FAILURE_LOCATION
                );

                fontFamilyList_->AddItem(familyName);
            }
            fontFamilyList_->SortItems();
        }
        break;

    default:
        // No action defined
        return false;
    }
    return true;
}


bool MainWindow::Shown(ListPopup* source, int id)
{
    switch (id)
    {
    case ControlIdTypographicFeature:
        {
            // Match list's currently selected feature tag to text's selection.
            DWRITE_FONT_FEATURE_TAG tag = DWRITE_FONT_FEATURE_TAG(0);
            DWRITE_TEXT_RANGE textRange = textEditor_->GetSelectionRange();

            ComPtr<IDWriteTypography> typoFeature;
            textEditorLayout_->GetTypography(textRange.startPosition, &typoFeature);
            if (typoFeature != NULL && typoFeature->GetFontFeatureCount() == 1)
            {
                DWRITE_FONT_FEATURE fontFeature;
                typoFeature->GetFontFeature(0 /* first index */, &fontFeature);
                tag = fontFeature.nameTag;
            }

            // Find match of current font feature in list, and
            // select item in list if found.
            for (size_t i = 0; i < ARRAY_SIZE(g_typographicFeaturesTable); ++i)
            {
                if (g_typographicFeaturesTable[i].tag == unsigned(tag))
                {
                    typographicFeaturesList_->SetSelection(ListControl::SelectionSetModeAbsolute, i);
                    break;
                }
            }
        }
        break;

    default:
        // No action defined
        return false;
    }
    return true;
}


bool MainWindow::Activated(ListPopup* source, int id, size_t selectedItem)
{
    DWRITE_TEXT_RANGE textRange = textEditor_->GetSelectionRange();
    CaretFormattingAttributes& caretFormat = textEditor_->GetCaretFormat();

    switch (id)
    {
    case ControlIdFont:
        {
            const wchar_t* familyName = fontFamilyList_->GetItemText(selectedItem);
            textEditorLayout_->SetFontFamilyName(familyName, textRange);
            caretFormat.fontFamilyName = familyName;
        }
        UpdateRibbonControlsToCaret(textEditor_);
        break;

    case ControlIdFontSize:
        if (selectedItem >= ARRAY_SIZE(g_fontSizes))
            return false;

        textEditorLayout_->SetFontSize(g_fontSizes[selectedItem], textRange);
        caretFormat.fontSize = g_fontSizes[selectedItem];
        UpdateRibbonControlsToCaret(textEditor_);
        break;

    case ControlIdLocale:
        if (selectedItem >= ARRAY_SIZE(g_locales))
            return false;

        textEditorLayout_->SetLocaleName(g_locales[selectedItem][1], textRange);
        caretFormat.localeName = g_locales[selectedItem][1];
        UpdateRibbonControlsToCaret(textEditor_);
        break;

    case ControlIdLayoutSample:
        if (selectedItem >= ARRAY_SIZE(g_layoutSamplesTable))
            return false;

        {
            textEditorLayout_->RemoveTextAt(0, UINT_MAX);
            ComPtr<DrawingEffect> drawingEffect(new DrawingEffect(0xFF000000));
            textEditorLayout_->SetDrawingEffect(drawingEffect, MakeDWriteTextRange(0));
            (this->*g_layoutSamplesTable[selectedItem].function)(textEditorLayout_);
            textEditor_->SetSelection(TextEditor::SetSelectionModeAbsoluteLeading, 0, false, true);
        }
        break;

    case ControlIdTypographicFeature:
        if (selectedItem >= ARRAY_SIZE(g_typographicFeaturesTable))
            return false;

        {
            DWRITE_FONT_FEATURE_TAG tag = DWRITE_FONT_FEATURE_TAG(g_typographicFeaturesTable[selectedItem].tag);

            // Before setting a new typographic feature,
            // check whether the currently selected one will suffice.
            // If so, just reuse it.

            ComPtr<IDWriteTypography> typoFeature;
            textEditorLayout_->GetTypography(textRange.startPosition, &typoFeature);

            bool needNewTypoFeature = true;
            if (typoFeature != NULL && typoFeature->GetFontFeatureCount() == 1)
            {
                DWRITE_FONT_FEATURE fontFeature;
                typoFeature->GetFontFeature(0 /* first index */, &fontFeature);
                if (fontFeature.nameTag == tag)
                {
                    needNewTypoFeature = false;
                }
            }

            // Either no existing feature is set, or it does not match what
            // the user just set it to.
            if (needNewTypoFeature)
            {
                typoFeature.Clear();
                if (tag != 0) // don't create anything for 'None'
                {
                    dwriteFactory_->CreateTypography(&typoFeature);
                    if (typoFeature != NULL)
                    {
                        DWRITE_FONT_FEATURE feature = {tag, 1};
                        typoFeature->AddFontFeature(feature);
                    }
                }
            }
            textEditorLayout_->SetTypography(typoFeature, textRange);

            UpdateRibbonControlsToCaret(textEditor_);
        }
        break;

    case ControlIdZoom:
        if (selectedItem >= ARRAY_SIZE(g_zoomSizes))
            return false;

        {
            float zoom = float(g_zoomSizes[selectedItem]);
            textEditor_->SetScale(zoom / 100.0f, zoom / 100.0f, false);
        }
        break;

    default:
        // No action defined
        return false;
    }
    return true;
}


bool MainWindow::Canceled(ListPopup* source, int id)
{
    return false;
}


bool MainWindow::Draw(RenderTarget& target, const Position& rect)
{
    Base::Draw(target, rect);

    return true;
}


bool MainWindow::SetStyle(StyleFlag set, StyleFlag clear)
{
    Base::SetStyle(set, clear);

    if (NeedsRedraw() || NeedsReflow())
    {
        InvalidateRect(hwnd_, NULL, false);
    }

    return true;
}


bool MainWindow::KeyPress(KeyboardMessage& message)
{
    bool messageAcknowledged = Base::KeyPress(message);
    if (messageAcknowledged)
        return messageAcknowledged;

    bool heldControl = (GetKeyState(VK_CONTROL) & 0x80) != 0;

    switch (message.button)
    {
    case VK_ESCAPE:
        PostMessage(hwnd_, WM_CLOSE, 0, 0);
        return true;

    case 'R':
        if (heldControl)
        {
            CreateRenderTarget(RenderTargetType((renderTargetType_ + 1) % RenderTargetTypeTotal));
            SetRedraw();
        }
        return true;

    case VK_F2:
        ShowProfileDialog();
        SetRedraw();
        return true;
    }
    return messageAcknowledged;
}


bool MainWindow::KeyEnter(KeyboardMessage& message)
{
    // Main window got focus, so activate children.
    // Normally the parent would be responsible for
    // setting this flag, but the root has no parent.
    SetStyleDirectly(StyleFlagKeyFocus);
    return Base::KeyEnter(message);
}


bool MainWindow::KeyExit(KeyboardMessage& message)
{
    // Main window got focus, so deactivate children.
    // Normally the parent would be responsible for
    // setting this flag, but the root has no parent.
    ClearStyleDirectly(StyleFlagKeyFocus);
    return Base::KeyExit(message);
}


bool MainWindow::Destroy()
{
    PostMessage(hwnd_, WM_CLOSE, 0, 0);
    Base::Destroy();
    return true;
}


bool MainWindow::SetPosition(const Position& position)
{
    // The preferred position for the main window is simply
    // whatever the user sized it to.
    preferredPosition_ = position;

    // Reposition all children
    if (!children_.empty())
    {
        Position ribbonPosition     = position_;
        Position statusBarPosition  = position_;
        Position textEditorPosition;

        ribbon_->GetPosition(PositionQueryPreferred, &ribbonPosition);
        statusBar_->GetPosition(PositionQueryPreferred, &statusBarPosition);

        // Both ribbon and status bar adopt the width of the main window.
        ribbonPosition     = MakePosition(0, 0, position.w, ribbonPosition.h);
        statusBarPosition  = MakePosition(0, position.h - statusBarPosition.h, position.w, statusBarPosition.h);
        textEditorPosition = MakePosition(
                                0,
                                ribbonPosition.h,
                                position.w,
                                position.h - ribbonPosition.h - statusBarPosition.h
                                );

        ribbon_->SetPosition(ribbonPosition);
        statusBar_->SetPosition(statusBarPosition);
        textEditor_->SetPosition(textEditorPosition);
    }
    Base::SetPosition(position);

    ClearStyleDirectly(StyleFlagReflow);
    return true;
}


////////////////////////////////////////
// Layout samples


void MainWindow::GetLayoutSampleIntroduction(IDWriteTextEditLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"\tDirectWrite demo app\r\n"
        L"\n"
        L"Feel free to play around with the formatting options to see just some of what DWrite is capable of:\n\n"
        L"Glyph rendering, Complex script shaping, Script analysis, Bidi ordering (\x202E" L"abc" L"\x202C), Line breaking, Font fallback, "
        L"Font enumeration, ClearType rendering, Bold/Italic/Underline/Strikethrough, OpenType styles, Inline objects \xFFFC, "
        L"Trimming, Selection hit-testing...\r\n"
        L"\r\n"
        L"Mixed scripts: 한글 الْعَرَبيّة 中文 日本語 ภาษาไทย\r\n"
        L"CJK characters beyond BMP - 𠂢𠂤𠌫\r\n"
        L"Localized forms - Ş Ș vs Ş Ș; 与 vs 与\r\n"
        L"Incremental tabs - 1	2	3"
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAY_SIZE(sampleText)-1, NULL);

    textLayout.SetFontFamilyName(L"Segoe UI", MakeDWriteTextRange(0));
    textLayout.SetFontSize(18, MakeDWriteTextRange(0));

    // Apply a color to the title words.
    ComPtr<DrawingEffect> drawingEffect1(new DrawingEffect(0xFF1010D0));
    ComPtr<DrawingEffect> drawingEffect2(new DrawingEffect(0xFF10D010));
    textLayout.SetDrawingEffect(drawingEffect1, MakeDWriteTextRange(0, 7));
    textLayout.SetDrawingEffect(drawingEffect2, MakeDWriteTextRange (7, 5));

    // Set title font style
    textLayout.SetFontSize(60, MakeDWriteTextRange(0, 12));
    textLayout.SetFontSize(30, MakeDWriteTextRange(12, 9));
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
    textLayout.SetInlineObject(new InlineImage(toolbarImagesSmall_, ControlIdLogo), MakeDWriteTextRange(344, 1));

    // localized S with comma below
    textLayout.SetFontFamilyName(L"Tahoma", MakeDWriteTextRange(485, 3));
    textLayout.SetFontSize(16, MakeDWriteTextRange(485, 3));
    textLayout.SetFontFamilyName(L"Tahoma", MakeDWriteTextRange(492, 3));
    textLayout.SetFontSize(16, MakeDWriteTextRange(492, 3));
    textLayout.SetLocaleName(L"ro-ro", MakeDWriteTextRange(492, 3));

    // localized CJK
    textLayout.SetFontFamilyName(L"Arial Unicode MS", MakeDWriteTextRange(497, 1));
    textLayout.SetFontFamilyName(L"Arial Unicode MS", MakeDWriteTextRange(502, 1));
    textLayout.SetLocaleName(L"jp-JP", MakeDWriteTextRange(497, 1));
    textLayout.SetLocaleName(L"zh-CN", MakeDWriteTextRange(502, 1));
}


void MainWindow::GetLayoutSampleBasicLatin(IDWriteTextEditLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"Single line of basic Latin text"
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAY_SIZE(sampleText)-1, NULL);
    textLayout.SetFontFamilyName(L"Arial", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}


void MainWindow::GetLayoutSampleLatin(IDWriteTextEditLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"Omnium humanae gentis partium perspecto et cognito consensum fidemque propriae dignitatis atque iurium, quae omni tempore aequa et paria esse debent nec alienari possunt, totius terrae libertatis iustitiae pacis esse initium;\n\n"
        L"hominis iurium perspecto et cognito contemptum et neglegentiam ea facinora atrocia tulisse ut morum humanorum conscientiam religionemque minuerint, atque etiam aetatis initium, qua omnes homines loquendi libertate et credendi utantur, nihil terroris indigentiaeque timentes, maximum, quod homo expetiverit, renuntiatum;\n\n"
        L"hominis iura perspecto et cognito legum regimine defendi necesse, si cupiunt hominem, ultima ratione, ad nimiae vexationi ac crudeli dominationi reclamitandum non sollicitari;\n\n"
        L"Gentium coniunctionibus perspecto et cognito magis magisque in dies faveri necesse;"
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAY_SIZE(sampleText)-1, NULL);
    textLayout.SetFontFamilyName(L"Arial", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}


void MainWindow::GetLayoutSampleKana(IDWriteTextEditLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"あいうえおかきくけこさしすせそ"
        ;

    textLayout.SetFontFamilyName(L"MS Gothic", MakeDWriteTextRange(0));
    textLayout.InsertTextAt(0, sampleText, ARRAY_SIZE(sampleText)-1, NULL);
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}


void MainWindow::GetLayoutSampleMultilingualSample(IDWriteTextEditLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"English: Hello\r\n"
        L"Arabic: سلام\r\n"
        L"Thai: สวัสดีเช้านี้\r\n"
        L"Hebrew: עֲלֵיכֶם\r\n"
        L"Greek: ΣΦΧΨΩ"
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAY_SIZE(sampleText)-1, NULL);
    textLayout.SetFontFamilyName(L"Segoe UI", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}


void FillRandomLatinString(__out_ecount(textLength) wchar_t* text, size_t textLength)
{
    // Fills a string with random letters, separated by spaces.

    unsigned char r1 = 73, r2 = 137, r3 = 13, r4 = 99;
    //unsigned char r1 = 137, r2 = 73, r3 = 13, r4 = 99;

    UINT32 a = 13;
    wchar_t previousChar = 0;
    for (size_t i = 0; i < textLength; ++i)
    {
        if (r1 + r2 < r3)
        {
            r4 = r2 + r3; r1 = r2; r2 = r3; r3 = r4;
        }
        else
        {
            r4 = r1 + r3; r1 = r2; r2 = r3; r3 = r4;
        }
        r4 %= 26;
        //a = UINT32( (UINT64(a) * 279470273) % 4294967291);
        a = (a * 1664525 + 1013904223);

        previousChar = (previousChar != ' ') && ((r4 & 7) == 0)
                     ? ' '
                     : ((a % 26) + 'a');
        text[i] = previousChar;
    }
}


void MainWindow::GetLayoutSampleLongString(IDWriteTextEditLayout& textLayout)
{
    const size_t sampleTextSize = 65500;
    wchar_t* sampleText = new wchar_t[sampleTextSize];

    FillRandomLatinString(sampleText, sampleTextSize);
    textLayout.InsertTextAt(0, sampleText, sampleTextSize, NULL);
    textLayout.SetFontFamilyName(L"Arial", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}


void MainWindow::GetLayoutSampleVeryLongString(IDWriteTextEditLayout& textLayout)
{
    const size_t sampleTextSize = 1048576;
    wchar_t* sampleText = new wchar_t[sampleTextSize];

    FillRandomLatinString(sampleText, sampleTextSize);
    textLayout.InsertTextAt(0, sampleText, sampleTextSize, NULL);
    textLayout.SetFontFamilyName(L"Arial", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}


void MainWindow::GetLayoutSampleArabic(IDWriteTextEditLayout& textLayout)
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

    textLayout.InsertTextAt(0, sampleText, ARRAY_SIZE(sampleText)-1, NULL);
    textLayout.SetFontFamilyName(L"Times New Roman", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}


void MainWindow::GetLayoutSampleCyrillic(IDWriteTextEditLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"Принимая во внимание, что признание достоинства, присущего всем членам человеческой семьи, и равных и неотъемлемых прав их является основой свободы, справедливости и всеобщего мира; и\n\n"
        L"принимая во внимание, что пренебрежение и презрение к правам человека привели к варварским актам, которые возмущают совесть человечества, и что создание такого мира, в котором люди будут иметь свободу слова и убеждений и будут свободны от страха и нужды, провозглашено как высокое стремление людей; и\n\n"
        L"принимая во внимание, что необходимо, чтобы права человека охранялись властью закона в целях обеспечения того, чтобы человек не был вынужден прибегать, в качестве последнего средства, к восстанию против тирании и угнетения; и\n\n"
        L"принимая во внимание, что необходимо содействовать развитию дружественных отношений между народами; и"
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAY_SIZE(sampleText)-1, NULL);
    textLayout.SetFontFamilyName(L"Arial", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}


void MainWindow::GetLayoutSampleGreek(IDWriteTextEditLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"Επειδή η αναγνώριση της αξιοπρέπειας, που είναι σύμφυτη σε όλα τα μέλη της ανθρώπινης οικογένειας, καθώς και των ίσων και αναπαλλοτρίωτων δικαιωμάτων τους αποτελεί το θεμέλιο της ελευθερίας, της δικαιοσύνης και της ειρήνης στον κόσμο.\n\n"
        L"Επειδή η παραγνώριση και η περιφρόνηση των δικαιωμάτων του ανθρώπου οδήγησαν σε πράξεις βαρβαρότητας, που εξεγείρουν την ανθρώπινη συνείδηση, και η προοπτική ενός κόσμου όπου οι άνθρωποι θα είναι ελεύθεροι να μιλούν και να πιστεύουν, λυτρωμένοι από τον τρόμο και την αθλιότητα, έχει διακηρυχθεί ως η πιο υψηλή επιδίωξη του ανθρώπου.\n\n"
        L"Επειδή έχει ουσιαστική σημασία να προστατεύονται τα ανθρώπινα δικαιώματα από ένα καθεστώς δικαίου, ώστε ο άνθρωπος να μην αναγκάζεται να προσφεύγει, ως έσχατο καταφύγιο, στην εξέγερση κατά της τυραννίας και της καταπίεσης.\n\n"
        L"Επειδή έχει ουσιαστική σημασία να ενθαρρύνεται η ανάπτυξη φιλικών σχέσεων ανάμεσα στα έθνη."
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAY_SIZE(sampleText)-1, NULL);
    textLayout.SetFontFamilyName(L"Arial", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}


void MainWindow::GetLayoutSampleKorean(IDWriteTextEditLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"모든 인류 구성원의 천부의 존엄성과 동등하고 양도할 수 없는 권리를 인정하는 것이 세계의 자유 , 정의 및 평화의 기초이며,\n\n"
        L"인권에 대한 무시와 경멸이 인류의 양심을 격분시키는 만행을 초래하였으며 , 인간이 언론과 신앙의 자유, 그리고 공포와 결핍으로부터의 자유를 누릴 수 있는 세계의 도래가 모든 사람들의 지고한 열망으로서 천명되어 왔으며,\n\n"
        L"인간이 폭정과 억압에 대항하는 마지막 수단으로서 반란을 일으키도록 강요받지 않으려면, 법에 의한 통치에 의하여 인권이 보호되어야 하는 것이 필수적이며,\n\n"
        L"국가간에 우호관계의 발전을 증진하는 것이 필수적이며,"
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAY_SIZE(sampleText)-1, NULL);
    textLayout.SetFontFamilyName(L"Arial", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}


void MainWindow::GetLayoutSampleChinese(IDWriteTextEditLayout& textLayout)
{
    const static wchar_t sampleText[] =
        L"鉴 于 对 人 类 家 庭 所 有 成 员 的 固 有 尊 严 及 其 平 等 的 和 不 移 的 权 利 的 承 认, 乃 是 世 界 自 由、 正 义 与 和 平 的 基 础,\n\n"
        L"鉴 于 对 人 权 的 无 视 和 侮 蔑 已 发 展 为 野 蛮 暴 行, 这 些 暴 行 玷 污 了 人 类 的 良 心, 而 一 个 人 人 享 有 言 论 和 信 仰 自 由 并 免 予 恐 惧 和 匮 乏 的 世 界 的 来 临, 已 被 宣 布 为 普 通 人 民 的 最 高 愿 望,\n\n"
        L"鉴 于 为 使 人 类 不 致 迫 不 得 已 铤 而 走 险 对 暴 政 和 压 迫 进 行 反 叛, 有 必 要 使 人 权 受 法 治 的 保 护,\n\n"
        L"鉴 于 有 必 要 促 进 各 国 间 友 好 关 系 的 发 展,"
        ;

    textLayout.InsertTextAt(0, sampleText, ARRAY_SIZE(sampleText)-1, NULL);
    textLayout.SetFontFamilyName(L"Arial", MakeDWriteTextRange(0));
    textLayout.SetFontSize(16, MakeDWriteTextRange(0));
}
