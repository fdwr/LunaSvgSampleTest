// <SnippetCustomLayoutcpp>
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
#include "common.h"
#include "resource.h"
#include "FlowLayout.h"
#include "CustomLayout.h"

////////////////////////////////////////
// Main entry.

const wchar_t* MainWindow::g_windowClassName = L"DirectWriteCustomLayoutDemo";

// Shows an error message if the function returned a failing HRESULT,
// then returning that same error code.
HRESULT ShowMessageIfFailed(HRESULT functionResult, const wchar_t* message);

HRESULT CopyImageToClipboard(HWND hwnd, HDC hdc, bool isUpsideDown = false);


int APIENTRY wWinMain(
    HINSTANCE   hInstance, 
    HINSTANCE   hPrevInstance,
    LPWSTR      commandLine,
    int         nCmdShow
    )
{
    // The Microsoft Security Development Lifecycle recommends that all
    // applications include the following call to ensure that heap corruptions
    // do not go unnoticed and therefore do not introduce opportunities
    // for security exploits.
    HeapSetInformation(nullptr, HeapEnableTerminationOnCorruption, nullptr, 0);

    MainWindow app;

    HRESULT hr = S_OK;
    hr = app.Initialize();

    if (SUCCEEDED(hr))
        hr = static_cast<HRESULT>(app.RunMessageLoop());

    return 0;
}


HRESULT MainWindow::Initialize()
{
    HRESULT hr = S_OK;

    INITCOMMONCONTROLSEX icex;
    icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    icex.dwICC  = ICC_STANDARD_CLASSES|ICC_LINK_CLASS;
    InitCommonControlsEx(&icex); 

    //////////////////////////////
    // Create the DWrite factory.

    hr = ShowMessageIfFailed(
            DWriteCreateFactory(
                DWRITE_FACTORY_TYPE_SHARED,
                __uuidof(IDWriteFactory),
                reinterpret_cast<IUnknown**>(&dwriteFactory_)
                ),
            L"Could not create DirectWrite factory! DWriteCreateFactory()" FAILURE_LOCATION
        );

    //////////////////////////////
    // Create the main window

    if (SUCCEEDED(hr))
    {
        MainWindow::RegisterWindowClass();

        CreateWindow(
                g_windowClassName,
                TEXT(APPLICATION_TITLE),
                WS_OVERLAPPEDWINDOW|WS_CLIPCHILDREN,
                CW_USEDEFAULT, CW_USEDEFAULT,
                800,
                600,
                nullptr,
                nullptr,
                HINST_THISCOMPONENT,
                this
                );

        if (hwnd_ == nullptr)
        {
            hr = ShowMessageIfFailed(
                    HRESULT_FROM_WIN32(GetLastError()),
                    L"Could not create main demo window! CreateWindow()"  FAILURE_LOCATION
                );
        }
        else
        {
            ShowWindow(hwnd_, SW_SHOWNORMAL);
            UpdateWindow(hwnd_);
        }
    }

    //////////////////////////////
    // Initialize the render target.

    if (SUCCEEDED(hr))
    {
        IDWriteGdiInterop* gdiInterop = nullptr;

        hr = dwriteFactory_->GetGdiInterop(&gdiInterop);

        if (SUCCEEDED(hr))
        {
            RECT clientRect;
            GetClientRect(hwnd_, &clientRect);

            HDC hdc = GetDC(hwnd_);

            hr = ShowMessageIfFailed(
                    gdiInterop->CreateBitmapRenderTarget(hdc, clientRect.right, clientRect.bottom, &renderTarget_),
                    L"Could not create render target! CreateBitmapRenderTarget()" FAILURE_LOCATION
                    );

            ReleaseDC(hwnd_, hdc);
        }
        SafeRelease(&gdiInterop);
    }

    //////////////////////////////
    // Create our custom layout, source, and sink.

    if (SUCCEEDED(hr))
    {
        SafeSet(&flowLayoutSource_, new(std::nothrow) FlowLayoutSource);
        SafeSet(&flowLayoutSink_,   new(std::nothrow) FlowLayoutSink(dwriteFactory_));
        SafeSet(&flowLayout_,       new(std::nothrow) FlowLayout(dwriteFactory_));

        if (flowLayoutSource_ == nullptr
        ||  flowLayoutSink_   == nullptr
        ||  flowLayout_       == nullptr)
        {
            hr = E_OUTOFMEMORY;
        }
    }

    if (SUCCEEDED(hr))
    {
        SetLayoutSampleText(CommandIdTextJapanese);
        SetLayoutShape(CommandIdShapeRectangle);

        OnMove();
        OnSize(); // update size and reflow

        InvalidateRect(hwnd_, nullptr, FALSE);
    }

    return hr;
}


ATOM MainWindow::RegisterWindowClass()
{
    // Registers the main window class.

    WNDCLASSEX wcex;
    wcex.cbSize        = sizeof(WNDCLASSEX);
    wcex.style         = CS_DBLCLKS | CS_VREDRAW | CS_HREDRAW;
    wcex.lpfnWndProc   = &WindowProc;
    wcex.cbClsExtra    = 0;
    wcex.cbWndExtra    = sizeof(LONG_PTR);
    wcex.hInstance     = HINST_THISCOMPONENT;
    wcex.hIcon         = nullptr;
    wcex.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wcex.lpszMenuName  = MAKEINTRESOURCE(1);
    wcex.lpszClassName = g_windowClassName;
    wcex.hIconSm       = nullptr;

    return RegisterClassEx(&wcex);
}


WPARAM MainWindow::RunMessageLoop()
{
    MSG msg;
    while (GetMessage(&msg, nullptr, 0, 0) > 0)
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
            SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(window));
        }
        return DefWindowProc(hwnd, message, wParam, lParam);

    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            BeginPaint(hwnd, &ps);
            window->OnPaint(ps);
            EndPaint(hwnd, &ps);
        }
        break;

    case WM_PRINTCLIENT:
        {
            PAINTSTRUCT ps = {};
            ps.hdc = (HDC)wParam;
            GetClientRect(hwnd, &ps.rcPaint);
            window->OnPaint(ps);
        }
        break;

    case WM_ERASEBKGND: // don't want flicker
        return true;

    case WM_COMMAND:
        window->OnCommand(static_cast<UINT>(wParam));
        break;

    case WM_KEYDOWN:
        window->OnKeyDown(static_cast<UINT>(wParam));
        break;

    case WM_SIZE:
        window->OnSize();
        break;

    case WM_MOVE:
        window->OnMove();
        break;

    case WM_DESTROY:
        PostQuitMessage(0);
        break;

    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    return 0;
}


namespace
{
    UINT SelectNextOrPreviousValue(
        UINT commandId,
        UINT value,
        UINT total
        )
    {
        if (commandId & 1) // if odd, next
        {
            value += 1;
        }
        else // if even, previous
        {
            value += total - 1;
        }

        return value % total;
    }
}

void MainWindow::OnCommand(UINT commandId)
{
    // Handles menu commands.

    switch (commandId)
    {
    case CommandIdShapeFunnel:
    case CommandIdShapeCircle:
    case CommandIdShapeRectangle:
    case CommandIdShapeGrid:
        SetLayoutShape(commandId);
        ReflowLayout();
        break;

    case CommandIdNumbersNominal:
    case CommandIdNumbersArabic:
        SetLayoutNumbers(commandId);
        ReflowLayout();
        break;

    case CommandIdTextLatin:
    case CommandIdTextArabic: 
    case CommandIdTextJapanese:
    case CommandIdTextMongolian:
    case CommandIdTextHebrew:
    case CommandIdTextMixed:
    case CommandIdTextOpeningClosing:
    case CommandIdTextBasicAscii:
    case CommandIdTextSymbols:
    case CommandIdTextCoercedRtl:
    case CommandIdTextArrows:
    case CommandIdTextPhagsPa:
    case CommandIdTextBoustrophedon:
    case CommandIdTextMixedRotation:
    case CommandIdTextEgyptian:
    case CommandIdTextRongoRongo:
    case CommandIdTextCjkContraryBidi:
    case CommandIdTextOghamFuthark:
    case CommandIdTextBoxDrawing:
    case CommandIdTextCharacterMap:
        SetLayoutSampleText(commandId);
        ReflowLayout();
        break;

    case CommandIdJustifyNone:
    case CommandIdJustifyWords:
        SetJustification(commandId);
        ReflowLayout();
        break;

    case CommandIdLtrTtb:
    case CommandIdRtlTtb:
    case CommandIdLtrBtt:
    case CommandIdRtlBtt:
    case CommandIdTtbLtr:
    case CommandIdBttLtr:
    case CommandIdTtbRtl:
    case CommandIdBttRtl:
        SetReadingDirection(commandId);
        ReflowLayout();
        break;

    case CommandIdOrientDefault:
    case CommandIdOrientStacked:
    case CommandIdOrientUpright:
    case CommandIdOrientRotated:
    case CommandIdOrientLtrTtb:
    case CommandIdOrientRtlTtb:
    case CommandIdOrientLtrBtt:
    case CommandIdOrientRtlBtt:
    case CommandIdOrientTtbLtr:
    case CommandIdOrientBttLtr:
    case CommandIdOrientTtbRtl:
    case CommandIdOrientBttRtl:
        SetGlyphOrientationMode(commandId);
        ReflowLayout();
        break;

    case CommandIdEditCopy:
        CopyToClipboard();
        break;

    case CommandIdEditPaste:
        PasteFromClipboard();
        break;

    case CommandIdEditCopyImage:
        CopyImageToClipboard();
        break;

    case CommandIdNextDirection:
    case CommandIdPreviousDirection:
        SetReadingDirection(SelectNextOrPreviousValue(commandId, flowLayout_->GetReadingDirection(), 8) + CommandIdReadingDirectionFirstId);
        ReflowLayout();
        break;

    case CommandIdNextOrientation:
    case CommandIdPreviousOrientation:
        SetGlyphOrientationMode(SelectNextOrPreviousValue(commandId, flowLayout_->GetGlyphOrientationMode(), GlyphOrientationModeTotal) + CommandIdOrientFirstId);
        ReflowLayout();
        break;

    case CommandIdNextTextSample:
    case CommandIdPreviousTextSample:
        SetLayoutSampleText(SelectNextOrPreviousValue(commandId, textSample_ - CommandIdTextFirstId, CommandIdTextTotal) + CommandIdTextFirstId);
        ReflowLayout();
        break;

    case CommandIdFont:
        OnChooseFont();
        break;

    case IDCLOSE:
        PostMessage(hwnd_, WM_CLOSE, 0,0);
        break;
    }
}


void MainWindow::OnKeyDown(UINT keyCode)
{
    // Handles menu commands.

    bool const heldShift   = (GetKeyState(VK_SHIFT)   & 0x80) != 0;
    bool const heldControl = (GetKeyState(VK_CONTROL) & 0x80) != 0;

    if (textSample_ == CommandIdTextCharacterMap)
    {
        struct KeyHelper
        {
            static GetIncrement(bool heldShift, bool heldControl)
            {
                return heldShift ? 16 : heldControl ? 4096 : 256;
            }
        };

        if (!heldShift && !heldControl)
        {
            switch (keyCode)
            {
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                SetCharacterMapBase(characterMapBase_ * 16 + (keyCode - '0'));
                break;

            case 'A':
            case 'B':
            case 'C':
            case 'D':
            case 'E':
            case 'F':
                SetCharacterMapBase(characterMapBase_ * 16 + (keyCode - 'A' + 10));
                break;
            }
        }

        switch (keyCode)
        {
        case VK_BACK:
            SetCharacterMapBase(characterMapBase_ / 16);
            break;

        case VK_HOME:
            SetCharacterMapBase(0);
            break;

        case VK_PRIOR:
            SetCharacterMapBase(characterMapBase_ - KeyHelper::GetIncrement(heldShift, heldControl));
            break;

        case VK_NEXT:
            SetCharacterMapBase(characterMapBase_ + KeyHelper::GetIncrement(heldShift, heldControl));
            break;
        }
    }

    switch (keyCode)
    {
    case 'R':
        OnCommand(heldShift ? CommandIdPreviousDirection : CommandIdNextDirection);
        break;

    case 'O':
        OnCommand(heldShift ? CommandIdPreviousOrientation : CommandIdNextOrientation);
        break;

    case 'T':
        OnCommand(heldShift ? CommandIdPreviousTextSample : CommandIdNextTextSample);
        break;

    case 'C':
        if (heldControl)
            if (heldShift)
                CopyImageToClipboard();
            else
                CopyToClipboard();
        break;

    case VK_INSERT:
        if (heldControl)
            CopyToClipboard();
        else if (heldShift)
            PasteFromClipboard();
        break;

    case 'V':
        if (heldControl)
            PasteFromClipboard();
        break;
    }
}


namespace
{
    const static DWRITE_MATRIX identityTransform = {1,0,0,1,0,0};

    class TextRenderer : public IDWriteTextRenderer
    {
    public:

        TextRenderer(
            IDWriteBitmapRenderTarget* renderTarget,
            IDWriteRenderingParams* renderingParams
            )
        :   renderTarget_(SafeAcquire(renderTarget)),
            renderingParams_(SafeAcquire(renderingParams))
        { }

        ~TextRenderer()
        {
            SafeRelease(&renderTarget_);
            SafeRelease(&renderingParams_);
        }

        HRESULT STDMETHODCALLTYPE DrawGlyphRun(
            __in void* clientDrawingContext,
            __in float baselineOriginX,
            __in float baselineOriginY,
            DWRITE_MEASURING_MODE measuringMode,
            __in DWRITE_GLYPH_RUN const* glyphRun,
            __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
            __in IUnknown* clientDrawingEffects
            ) throw()
        {
            if (glyphRun->glyphCount <= 0)
                return S_OK;

            uint32_t textColor = 0x000000;
            renderTarget_->DrawGlyphRun(
                    baselineOriginX,
                    baselineOriginY,
                    DWRITE_MEASURING_MODE_NATURAL,
                    glyphRun,
                    renderingParams_,
                    textColor,
                    nullptr // don't need blackBoxRect
                    );

            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE DrawUnderline(
            __in void* clientDrawingContext,
            __in float baselineOriginX,
            __in float baselineOriginY,
            __in DWRITE_UNDERLINE const* underline,
            __in IUnknown* clientDrawingEffects
            ) throw()
        {
            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE DrawStrikethrough(
            __in void* clientDrawingContext,
            __in float baselineOriginX,
            __in float baselineOriginY,
            __in DWRITE_STRIKETHROUGH const* strikethrough,
            __in IUnknown* clientDrawingEffects
            ) throw()
        {
            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE DrawInlineObject(
            __in void* clientDrawingContext,
            __in float originX,
            __in float originY,
            __in IDWriteInlineObject* inlineObject,
            __in BOOL isSideways,
            __in BOOL isRightToLeft,
            __in IUnknown* clientDrawingEffects
            ) throw()
        {
            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE IsPixelSnappingDisabled(
            __maybenull void* clientDrawingContext,
            __out BOOL* isDisabled
            ) throw()
        {
            *isDisabled = false;
            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE GetCurrentTransform(
            __maybenull void* clientDrawingContext,
            __out DWRITE_MATRIX* transform
            ) throw()
        {
            *transform = identityTransform;
            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE GetPixelsPerDip(
            __maybenull void* clientDrawingContext,
            __out float* pixelsPerDip
            ) throw()
        {
            *pixelsPerDip = 1.0;
            return S_OK;
        }

        HRESULT STDMETHODCALLTYPE QueryInterface(IID const& iid, __out void** object) throw()
        {
            *object = nullptr;
            return E_NOINTERFACE;
        }

        unsigned long STDMETHODCALLTYPE AddRef() throw()
        {
            return 1; // Static stack class
        }

        unsigned long STDMETHODCALLTYPE Release() throw()
        {
            return 1; // Static stack class
        }

        IDWriteBitmapRenderTarget* renderTarget_;
        IDWriteRenderingParams* renderingParams_;
    };
}


void MainWindow::OnPaint(const PAINTSTRUCT& ps)
{
    // Redraws the glyph runs.

    if (renderTarget_ == nullptr)
        return;

    HDC memoryHdc = renderTarget_->GetMemoryDC();

    // Clear background.
    SetDCBrushColor(memoryHdc, GetSysColor(COLOR_WINDOW));
    SelectObject(memoryHdc, GetStockObject(NULL_PEN));
    SelectObject(memoryHdc, GetStockObject(DC_BRUSH));
    Rectangle(memoryHdc, ps.rcPaint.left,ps.rcPaint.top, ps.rcPaint.right, ps.rcPaint.bottom);

    // Draw all of the produced glyph runs.
    flowLayoutSink_->DrawGlyphRuns(renderTarget_, renderingParams_, GetSysColor(COLOR_WINDOWTEXT));

    // Transfer drawn image to display.
    BitBlt(
        ps.hdc,
        ps.rcPaint.left,
        ps.rcPaint.top,
        ps.rcPaint.right  - ps.rcPaint.left,
        ps.rcPaint.bottom - ps.rcPaint.top,
        memoryHdc,
        ps.rcPaint.left,
        ps.rcPaint.top,
        SRCCOPY | NOMIRRORBITMAP
        );
}


void MainWindow::OnSize()
{
    // Resizes the render target and flow source.

    RECT rect;
    GetClientRect(hwnd_, &rect);

    if (renderTarget_ == nullptr)
        return;

    renderTarget_->Resize(rect.right, rect.bottom);

    if (flowLayoutSource_ == nullptr)
        return;

    float pixelsPerDip = renderTarget_->GetPixelsPerDip();
    flowLayoutSource_->SetSize(float(rect.right) / pixelsPerDip, float(rect.bottom) / pixelsPerDip);
    ReflowLayout();
}


void MainWindow::OnMove()
{
    // Updates rendering parameters according to current monitor.

    if (dwriteFactory_ == nullptr)
        return; // Not initialized yet.

    HMONITOR monitor = MonitorFromWindow(hwnd_, MONITOR_DEFAULTTONEAREST);
    if (monitor == hmonitor_)
        return; // Still on previous monitor.

    // Create rendering params to get the defaults for the various parameters.
    IDWriteRenderingParams* renderingParams = nullptr;
    dwriteFactory_->CreateMonitorRenderingParams(
                    MonitorFromWindow(hwnd_, MONITOR_DEFAULTTONEAREST),
                    &renderingParams
                    );

    // Now create our own with the desired rendering mode.
    if (renderingParams != nullptr)
    {
        SafeRelease(&renderingParams_);
        dwriteFactory_->CreateCustomRenderingParams(
            renderingParams->GetGamma(),
            renderingParams->GetEnhancedContrast(),
            renderingParams->GetClearTypeLevel(),
            renderingParams->GetPixelGeometry(),
            DWRITE_RENDERING_MODE_DEFAULT,
            &renderingParams_
            );
    }
    SafeRelease(&renderingParams);

    if (renderingParams_ == nullptr)
        return;

    hmonitor_ = monitor;
    InvalidateRect(hwnd_, nullptr, FALSE);
}


STDMETHODIMP MainWindow::ReflowLayout()
{
    // Reflows the layout after a resize or text change.

    HRESULT hr = S_OK;

    if (FAILED(hr = flowLayoutSource_->Reset()))
        return hr;

    if (FAILED(hr = flowLayoutSink_->Reset()))
        return hr;
    
    if (FAILED(hr = flowLayout_->FlowText(flowLayoutSource_, flowLayoutSink_)))
        return hr;

    InvalidateRect(hwnd_, nullptr, false);
    return hr;
}


STDMETHODIMP MainWindow::SetLayoutSampleText(UINT commandId)
{
    // Selects a different text sample.

    HRESULT hr = S_OK;

    ReadingDirection readingDirection = ReadingDirectionLeftToRightTopToBottom;
    const wchar_t* text             = L"";
    const wchar_t* fontName         = L"";
    const wchar_t* localeName       = L"";
    uint32_t textLength             = 0;
    float fontSize                  = 14;
    bool treatAsIsolatedCharacters  = false;

    const uint32_t characterMapWidth  = 16;
    const uint32_t characterMapHeight = 16;
    wchar_t characterMapText[(characterMapWidth * characterMapHeight) * 2 + 1];

    switch (commandId)
    {
    case CommandIdTextLatin:
        fontName = L"Segoe UI";
        localeName = L"en-us";
        readingDirection = ReadingDirectionLeftToRightTopToBottom;
        text =
            L"DirectWrite provides factored layers of functionality, with each layer interacting seamlessly with the next. "
            L"The API design gives an application the freedom and flexibility to adopt individual layers depending on their needs and schedule.\r\n"
            L"\r\n"
            L"The text layout API provides the highest level functionality available from DirectWrite. "
            L"It provides services for the application to measure, display, and interact with richly formatted text strings. "
            L"This text API can be used in applications that currently use Win32’s DrawText to build a modern UI with richly formatted text.\r\n"
            L"\r\n"
            L"* Text-intensive applications that implement their own layout engine may use the next layer down: the script processor. "
            L"The script processor segments text into runs of similar properties and handles the mapping from Unicode codepoints "
            L"to the appropriate glyph in the font. "
            L"DirectWrite's own layout is built upon this same font and script processing system. "
            L"This sample demonstrates how a custom layout can utilize the information from script itemization, bidi analysis, line breaking analysis, and shaping, "
            L"to accomplish text measurement/fitting, line breaking, basic justification, and drawing.\r\n"
            L"\r\n"
            L"The glyph-rendering layer is the lowest layer and provides glyph-rendering functionality for applications "
            L"that implement their own complete text layout engine. The glyph rendering layer is also useful for applications that implement a custom "
            L"renderer to modify the glyph-drawing behavior through the callback function in the DirectWrite text-formatting API.\r\n"
            L"\r\n"
            L"The DirectWrite font system is available to all the functional layers, and enables an application to access font and glyph information. "
            L"It is designed to handle common font technologies and data formats. The DirectWrite font model follows the common typographic practice of "
            L"supporting any number of weights, styles, and stretches in the same font family. This model, the same model followed by WPF and CSS, "
            L"specifies that fonts differing only in weight (bold, light, etc.), style (upright, italic, or oblique) or stretch (narrow, condensed, wide, etc.) "
            L"are considered to be members of a single font family.\r\n"
            L"\r\n"
            L"Text in DirectWrite is rendered using Microsoft® ClearType®, which enhances the clarity and readability of text. "
            L"ClearType takes advantage of the fact that modern LCD displays have RGB stripes for each pixel that can be controlled individually. "
            L"DirectWrite uses the latest enhancements to ClearType, first included with Windows Vista® with Windows Presentation Foundation, "
            L"that enables it to evaluate not just the individual letters but also the spacing between letters. "
            L"Before these ClearType enhancements, text with a “reading” size of 10 or 12 points was difficult to display: "
            L"we could place either 1 pixel in between letters, which was often too little, or 2 pixels, which was often too much. "
            L"Using the extra resolution in the subpixels provides us with fractional spacing, which improves the evenness and symmetry of the entire page.\r\n"
            L"\r\n"
            L"The subpixel ClearType positioning offers the most accurate spacing of characters on screen, "
            L"especially at small sizes where the difference between a sub-pixel and a whole pixel represents a significant proportion of glyph width. "
            L"It allows text to be measured in ideal resolution space and rendered at its natural position at the LCD color stripe, subpixel granularity. "
            L"Text measured and rendered using this technology is, by definition, "
            L"resolution-independent—meaning the exact same layout of text is achieved across the range of various display resolutions.\r\n"
            L"\r\n"
            L"Unlike either flavor of GDI's ClearType rendering, sub-pixel ClearType offers the most accurate width of characters. "
            L"The Text String API adopts sub-pixel text rendering by default, which means it measures text at its ideal resolution independent "
            L"to the current display resolution, and produces the glyph positioning result based on the truly scaled glyph advance widths and positioning offsets."
            ;
        break;

    case CommandIdTextArabic:
        fontName = L"Arabic Typesetting";
        fontSize = 24;
        localeName = L"ar-eg";
        readingDirection = ReadingDirectionRightToLeftTopToBottom;
        text =
            L"الديباجة\r\n"
            L"لمّا كان الاعتراف بالكرامة المتأصلة في جميع أعضاء الأسرة البشرية وبحقوقهم المتساوية الثابتة هو أساس الحرية والعدل والسلام في العالم.\r\n"
            L"\r\n"
            L"ولما كان تناسي حقوق الإنسان وازدراؤها قد أفضيا إلى أعمال همجية آذت الضمير الإنساني. وكان غاية ما يرنو إليه عامة البشر انبثاق عالم يتمتع فيه الفرد بحرية القول والعقيدة ويتحرر من الفزع والفاقة.\r\n"
            L"\r\n"
            L"ولما كان من الضروري أن يتولى القانون حماية حقوق الإنسان لكيلا يضطر المرء آخر الأمر إلى التمرد على الاستبداد والظلم.\r\n"
            L"\r\n"
            L"ولما كانت شعوب الأمم المتحدة قد أكدت في الميثاق من جديد إيمانها بحقوق الإنسان الأساسية وبكرامة الفرد وقدره وبما للرجال والنساء من حقوق متساوية وحزمت أمرها على أن تدفع بالرقي الاجتماعي قدمًا وأن ترفع مستوى الحياة في جو من الحرية أفسح.\r\n"
            L"\r\n"
            L"ولما كانت الدول الأعضاء قد تعهدت بالتعاون مع الأمم المتحدة على ضمان إطراد مراعاة حقوق الإنسان والحريات الأساسية واحترامها.\r\n"
            L"\r\n"
            L"ولما كان للإدراك العام لهذه الحقوق والحريات الأهمية الكبرى للوفاء التام بهذا التعهد.\r\n"
            L"\r\n"
            L"فإن الجمعية العامة\r\n"
            L"\r\n"
            L"تنادي بهذا الإعلان العالمي لحقوق الإنسان\r\n"
            L"\r\n"
            L"على أنه المستوى المشترك الذي ينبغي أن تستهدفه كافة الشعوب والأمم حتى يسعى كل فرد وهيئة في المجتمع، واضعين على الدوام هذا الإعلان نصب أعينهم، إلى توطيد احترام هذه الحقوق والحريات عن طريق التعليم والتربية واتخاذ إجراءات مطردة، قومية وعالمية، لضمان الإعتراف بها ومراعاتها بصورة عالمية فعالة بين الدول الأعضاء ذاتها وشعوب البقاع الخاضعة لسلطانها.\r\n"
            L"\r\n"
            L"المادة 1\r\n"
            L"\r\n"
            L"يولد جميع الناس أحرارًا متساوين في الكرامة والحقوق. وقد وهبوا عقلاً وضميرًا وعليهم أن يعامل بعضهم بعضًا بروح الإخاء.\r\n"
            L"\r\n"
            L"المادة 2\r\n"
            L"\r\n"
            L"لكل إنسان حق التمتع بكافة الحقوق والحريات الواردة في هذا الإعلان، دون أي تمييز، كالتمييز بسبب العنصر أو اللون أو الجنس أو اللغة أو الدين أو الرأي السياسي أو أي رأي آخر، أو الأصل الوطني أو الإجتماعي أو الثروة أو الميلاد أو أي وضع آخر، دون أية تفرقة بين الرجال والنساء.\r\n"
            L"\r\n"
            L"وفضلاً عما تقدم فلن يكون هناك أي تمييز أساسه الوضع السياسي أو القانوني أو الدولي لبلد أو البقعة التي ينتمي إليها الفرد سواء كان هذا البلد أو تلك البقعة مستقلاً أو تحت الوصاية أو غير متمتع بالحكم الذاتي أو كانت سيادته خاضعة لأي قيد من القيود.\r\n"
            ;
        break;

    case CommandIdTextJapanese:
        fontName = L"Meiryo UI";
        localeName = L"ja-jp";
        readingDirection = ReadingDirectionTopToBottomRightToLeft;
        text =
            L"『世界人権宣言』\r\n"
            L"（1948.12.10 第３回国連総会採択）〈前文〉\r\n"
            L"\r\n"
            L"人類社会のすべての構成員の固有の尊厳と平等で譲ることのできない権利とを承認することは、世界における自由、正義及び平和の基礎であるので、\r\n"
            L"\r\n"
            L"人権の無視及び軽侮が、人類の良心を踏みにじった野蛮行為をもたらし、言論及び信仰の自由が受けられ、恐怖及び欠乏のない世界の到来が、一般の人々の最高の願望として宣言されたので、\r\n"
            L"\r\n"
            L"人間が専制と圧迫とに対する最後の手段として反逆に訴えることがないようにするためには、法の支配によって人権を保護することが肝要であるので、\r\n"
            L"\r\n"
            L"諸国間の友好関係の発展を促進することが肝要であるので、\r\n"
            L"\r\n"
            L"国際連合の諸国民は、国連憲章において、基本的人権、人間の尊厳及び価値並びに男女の同権についての信念を再確認し、かつ、一層大きな自由のうちで社会的進歩と生活水準の向上とを促進することを決意したので、\r\n"
            L"\r\n"
            L"加盟国は、国際連合と協力して、人権及び基本的自由の普遍的な尊重及び遵守の促進を達成することを誓約したので、\r\n"
            L"\r\n"
            L"これらの権利及び自由に対する共通の理解は、この誓約を完全にするためにもっとも重要であるので、\r\n"
            L"\r\n"
            L"よって、ここに、国連総会は、\r\n"
            L"\r\n"
            L"\r\n"
            L"社会の各個人及び各機関が、この世界人権宣言を常に念頭に置きながら、加盟国自身の人民の間にも、また、加盟国の管轄下にある地域の人民の間にも、これらの権利と自由との尊重を指導及び教育によって促進すること並びにそれらの普遍的措置によって確保することに努力するように、すべての人民とすべての国とが達成すべき共通の基準として、この人権宣言を公布する。\r\n"
            L"\r\n"
            L"第１条\r\n"
            L"すべての人間は、生まれながらにして自由であり、かつ、尊厳と権利と について平等である。人間は、理性と良心とを授けられており、互いに同 胞の精神をもって行動しなければならない。\r\n"
            L"\r\n"
            L"第２条"
            L"すべて人は、人種、皮膚の色、性、言語、宗教、政治上その他の意見、\r\n"
            L"\r\n"
            L"国民的もしくは社会的出身、財産、門地その他の地位又はこれに類するい\r\n"
            L"\r\n"
            L"かなる自由による差別をも受けることなく、この宣言に掲げるすべての権\r\n"
            L"\r\n"
            L"利と自由とを享有することができる。\r\n"
            L"\r\n"
            L"さらに、個人の属する国又は地域が独立国であると、信託統治地域で\r\n"
            L"\r\n"
            L"あると、非自治地域であると、又は他のなんらかの主権制限の下にあると\r\n"
            L"\r\n"
            L"を問わず、その国又は地域の政治上、管轄上又は国際上の地位に基ずくい\r\n"
            L"\r\n"
            L"かなる差別もしてはならない。\r\n"
            L"\r\n"
            L"第３条\r\n"
            L"すべての人は、生命、自由及び身体の安全に対する権利を有する。\r\n"
            L"\r\n"
            L"第４条\r\n"
            L"何人も、奴隷にされ、又は苦役に服することはない。奴隷制度及び奴隷\r\n"
            L"\r\n"
            L"売買は、いかなる形においても禁止する。\r\n"
            L"\r\n"
            L"第５条\r\n"
            L"何人も、拷問又は残虐な、非人道的なもしくは屈辱的な取扱もしくは刑\r\n"
            L"\r\n"
            L"罰を受けることはない。\r\n"
            ;
        break;

    case CommandIdTextMongolian:
        fontName = L"Mongolian Baiti";
        fontSize = 20;
        localeName = L"mn-mong";
        readingDirection = ReadingDirectionTopToBottomLeftToRight;
        text =
            L"ᠬᠦᠮᠦᠨ ᠪᠦᠷ ᠲᠥᠷᠥᠵᠦ ᠮᠡᠨᠳᠡᠯᠡᠬᠦ ᠡᠷᠬᠡ ᠴᠢᠯᠥᠭᠡ ᠲᠡᠢ᠂ ᠠᠳᠠᠯᠢᠬᠠᠨ ᠨᠡᠷ᠎ᠡ ᠲᠥᠷᠥ ᠲᠡᠢ᠂ ᠢᠵᠢᠯ ᠡᠷᠬᠡ ᠲᠡᠢ ᠪᠠᠢᠠᠭ᠃ ᠣᠶᠤᠨ ᠤᠬᠠᠭᠠᠨ᠂ ᠨᠠᠨᠳᠢᠨ ᠴᠢᠨᠠᠷ ᠵᠠᠶᠠᠭᠠᠰᠠᠨ ᠬᠦᠮᠦᠨ ᠬᠡᠭᠴᠢ ᠥᠭᠡᠷ᠎ᠡ ᠬᠣᠭᠣᠷᠣᠨᠳᠣ᠎ᠨ ᠠᠬᠠᠨ ᠳᠡᠭᠦᠦ ᠢᠨ ᠦᠵᠢᠯ ᠰᠠᠨᠠᠭᠠ ᠥᠠᠷ ᠬᠠᠷᠢᠴᠠᠬᠥ ᠤᠴᠢᠷ ᠲᠠᠢ᠃"
            ;
        break;

    case CommandIdTextHebrew:
        fontName = L"Times New Roman";
        fontSize = 20;
        localeName = L"";
        readingDirection = ReadingDirectionTopToBottomLeftToRight;
        text =
            L"אָלֶף-בֵּית עִבְרִי\r\n"
            L"\r\n"
            L"הכרזה לכל באי עולם בדבר זכויות האדםהואיל והכרה בכבוד הטבעי אשר לכל בני משפהת האדם ובזכויותיהם השוות והבלתי נפקעות הוא יסוד החופש, הצדק והשלום בעולם.\r\n"
            L"הואיל והזלזול בזכויות האדם וביזוין הבשילו מעשים פראיים שפגעו קשה במצפונה של האנושות; ובנין עולם, שבו ייהנו כל יצורי אנוש מחירות הדיבור והאמונה ומן החירות מפחד וממחסור, הוכרז כראש שאיפותיו של כל אדם.\r\n"
            L"הואיל והכרח חיוני הוא שזכויות האדם תהיינה מוגנות בכוח שלטונו של החוק, שלא יהא האדם אנוס, כמפלט אחרון, להשליך את יהבו על מרידה בעריצות ובדיכזי.\r\n"
            L"הואיל והכרח חיוני הוא לקדם את התפתחותם של יחסי ידידות בין האומות.\r\n"
            L"הואיל והעמים המאוגדים בארגון האומות המאוחדות חזרו ואישרו במגילה את אמונתם בזכויות היסוד של האדם, בכבודה ובערכה של אישיותו ובזכות שווה לגבר ולאשה; ומנוי וגמור אתם לסייע לקדמה חברתית ולהעלאת רמת החיים בתוך יתר חירות.\r\n"
            L"הואיל והמדינות החברות התחייבו לפעול, בשיתוף עם ארגון האומות המאוחדות, לטיפול יחס כבוד כללי אל זכויות האדם ואל חירויות היסוד והקפדה על קיומן.\r\n"
            L"הואיל והבנה משותפת במהותן של זכויות וחירויות אלה הוא תנאי חשוב לקיומה השלם של התחייבות זו.\r\n"
            L"לפיכך מכריזש העצרת באזני כל באי העולם את ההכרזש הזאת בדבר זכויות האדם כרמת הישגים כללית לכל העמים והאומות, כדי שכל יחיד וכל גוף חברתי ישווה תמיד לנגד עיניו וישאף לטפח, דרך לימוד וחינוך, יחס של כבוד אל הזכויות ואל החירויות הללו, ולהבטיח באמצעים הדרגתיים, לאומיים ובינלאומיים, שההכרה בעקרונות אלה וההקפדה עליהם תהא כללית ויעילה בקרב אוכלוסי המדינות החברות ובקרב האוכלוסים שבארצות שיפוטם.\r\n"
            ;
        break;

    case CommandIdTextMixed:
        fontName = L"Arial Unicode MS";
        fontSize = 20;
        localeName = L"";
        readingDirection = ReadingDirectionTopToBottomLeftToRight;
        text =
            L"Latin\r\n"
            L"ελληνική γλώσσα\r\n"
            L"देवनागरी\r\n"
            L"אלף-בית עברי\r\n"
            L"أبجدية عربية\r\n"
            L"‎日本語\r\n"
            L"①②③☀☁☂\r\n"
            L"ภาษาไทย\r\n"
            L"ಕನ್ನಡ\r\n"
            ;
        break;

    case CommandIdTextOpeningClosing:
        fontName = L"Meiryo UI";
        fontSize = 20;
        localeName = L"";
        readingDirection = ReadingDirectionTopToBottomLeftToRight;
        text =
            L"()<>[]{op}{cl}‐―‥…∥、。〈〉《》「」『』【】〓〔〕〖〗〘〙〚〛ー（）＝［］＿｛｜｝～｢｣ｰ￣"
            // these require Microsoft Jhenghei instead: ﹙﹚﹛﹜﹝﹞"
            ;
        break;

    case CommandIdTextBasicAscii:
        fontName = L"Segoe UI";
        localeName = L"";
        readingDirection = ReadingDirectionTopToBottomLeftToRight;
        text =
            L" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{op}|{cl}~"
            ;
        break;

    case CommandIdTextSymbols:
        fontName = L"Segoe UI Symbol";
        fontSize = 20;
        localeName = L"";
        readingDirection = ReadingDirectionTopToBottomLeftToRight;
        text =
            L"☀☁☂☃☄★☆☇☈☉☊☋☌☍☎☏\r\n"
            L"☐☑☒☓☔☕☖☗☘☙☚☛☜☝☞☟\r\n"
            L"☠☡☢☣☤☥☦☧☨☩☪☫☬☭☮☯\r\n"
            L"☰☱☲☳☴☵☶☷☸☹☺☻☼☽☾☿\r\n"
            L"♀♁♂♃♄♅♆♇♈♉♊♋♌♍♎♏\r\n"
            L"♐♑♒♓♔♕♖♗♘♙♚♛♜♝♞♟\r\n"
            L"♠♡♢♣♤♥♦♧♨♩♪♫♬♭♮♯\r\n"
            L"♰♱♲♳♴♵♶♷♸♹♺♻♼♽♾♿\r\n"
            L"⚀⚁⚂⚃⚄⚅⚆⚇⚈⚉⚊⚋⚌⚍⚎⚏\r\n"
            L"⚐⚑⚒⚓⚔⚕⚖⚗⚘⚙⚚⚛⚜⚝⚞⚟\r\n"
            L"⚠⚡⚢⚣⚤⚥⚦⚧⚨⚩⚪⚫⚬⚭⚮⚯\r\n"
            ;
        break;

    case CommandIdTextBoustrophedon:
        fontName = L"Segoe UI";
        fontSize = 24;
        text =
            L"{dir}{or}❶ Can you read text written\r\n"
            L"{dir}{or}❷ {dir=ld}{or=ld}in boustrophedon flow?\r\n"
            L"{dir}{or}❸ {dir=ld}{or=cw180}It's not too hard to read."
            ;
        break;

    case CommandIdTextCoercedRtl:
        fontName = L"Microsoft JhengHei UI";
        readingDirection = ReadingDirectionLeftToRightTopToBottom;
        fontSize = 20;
        text =
            L"Latin ΔΣΩ part - LTR natural flow\r\n"
            L"{dir=ld}{or=rd}Latin ΔΣΩ part{dir}{or} - RTL ambiguous if rearranged\r\n"
            L"{dir=ld}{or=ld}Latin ΔΣΩ part{dir}{or} - RTL clearer if mirrored\r\n"
            L"\r\n"
            L"日本語/汉语 - LTR natural flow\r\n"
            L"{dir=ld}{or=ld}日本語{dir}{or}/{dir=ld}{or=ld}汉语{dir}{or} - RTL confusing if mirrored\r\n"
            L"{dir=ld}日本語{dir}/{dir=ld}汉语{dir} - RTL better if rearranged"
            ;
        break;

    case CommandIdTextPhagsPa:
        fontName = L"Microsoft PhagsPa";
        fontSize = 24;
        text = 
            L"{dir=rd}ꡁꡯꡧ{dir} - LTR rational flow for TTB script\r\n"
            L"{dir=ld}{or=cw180}ꡁꡯꡧ{dir}{or} - RTL rational flow for TTB script\r\n"
            L"{dir=ld}{or=cw0}ꡁꡯꡧ{dir}{or} - RTL broken flow"
            ;
        break;

    case CommandIdTextMixedRotation:
        fontName = L"Segoe UI";
        fontSize = 24;
        readingDirection = ReadingDirectionTopToBottomLeftToRight;
        text =
            L"Begin سلام אבג End - same baseline\r\n"
            L"{or=cw90}Begin {dir=dl}{or=cw270}سلام אבג{or=cw90} {dir}End{or} - same flow"
            ;
        break;

    case CommandIdTextOghamFuthark:
        fontName = L"Segoe UI Symbol";
        fontSize = 24;
        readingDirection = ReadingDirectionTopToBottomLeftToRight;
        text = 
            L"{dir=dr}{or=dl}❶ᚠᚢᚦᚨᚱᚲ ❷Latin ❸ᚁᚌᚈᚕᚗ{or}{dir}! - TTB\r\n"
            L"{dir=ur}{or=dl}❶{or=ul}ᚠᚢᚦᚨᚱᚲ {or=dl}❷{or}{dir}{lre}Latin{pdf}{dir=ur} {or=dl}❸{or=cw270}ᚁᚌᚈᚕᚗ{or}{dir}{lre}!{pdf} - BTT"
            ;
        break;

    case CommandIdTextCjkContraryBidi:
        fontName = L"Meiryo UI";
        fontSize = 20;
        readingDirection = ReadingDirectionBottomToTopLeftToRight;
        text = 
            L"{dir=ur}{or=cw270}Latin 《日本国》 More. - nope{or}\r\n"
            L"{dir=ur}{or=cw270}Latin 《{or=cw0}日本国{or=cw270}》 More! - nope{or}\r\n"
            L"{dir=ur}{or=cw270}Latin 《{dir=dr}{or=cw0}日本国{dir=ur}{or=cw270}》 More! - good{or}";
        break;

    case CommandIdTextEgyptian:
        fontName = L"Aegyptus";
        fontSize = 40;
        readingDirection = ReadingDirectionTopToBottomLeftToRight;
        text = 
            L"𓀀{or=cw90}Latin{or}𓂀\r\n"
            L"𓃲𓆈𓄿𓇋\r\n"
            ;
            // *requires 'Aegyptus' font
        break;

    case CommandIdTextRongoRongo:
        fontName = L"RongoRongo glyphs";
        fontSize = 40;
        text = 
            L"{dir=rd}{or=cw0}FON\r\n"
            L"{dir=ld}{or=cw180}FON\r\n"
            ;
            // *requires 'RongoRongo glyphs' font
        break;

    case CommandIdTextArrows:
        fontName = L"Meiryo UI";
        fontSize = 20;
        text =
            L"⇧Park\r\n"
            L"⇨Volcano\r\n"
            L"⇦Doctor\r\n"
            L"\r\n"
            L"{or=rotated}CH₄ + 2 O₂ → CO₂ + 2 H₂O{or}\r\n"
            L"{or=upright}か{or} {or=upright}+{or} {or=upright}゛{or} → {or=upright}が{or}  "
            L"{or=upright}○{or} {or=upright}+{or} {or=upright}〒{or} → {or=upright}〶{or}"
            ;
        break;

    case CommandIdTextBoxDrawing:
        fontName = L"MingLiu";
        fontSize = 30;
        readingDirection = ReadingDirectionLeftToRightTopToBottom;
        text = 
            L"{linegap=false}╓─┬─╥╖\r\n"
            L"║{dir=rd}{or=default}丂{or}{dir}│{dir=rd}{or=default}七{or}{dir}║║\r\n"
            L"╟─┴─╢║\r\n"
            L"╚═══╩╝"
            ;
        break;

    case CommandIdTextCharacterMap:
        fontName = L"Meiryo UI";
        localeName = L"";
        readingDirection = ReadingDirectionTopToBottomLeftToRight;
        fontSize = 20;
        text = characterMapText;
        textLength = 0;
        treatAsIsolatedCharacters = true;

        for (uint32_t i = 0;
            i < characterMapWidth * characterMapHeight && textLength < ARRAYSIZE(characterMapText);
            i++ /* increment textLength inside */
            )
        {
            uint32_t codeUnitCount;
            uint32_t charValue = characterMapBase_ + i;

            // don't add certain control characters
            switch (charValue)
            {
            case '\x0000':
                charValue = 0xFFFF;
                break;
            }

            if (charValue <= 65535)
            {
                wchar_t leadingValue = wchar_t(charValue);
                characterMapText[textLength]  = leadingValue;
                codeUnitCount = 1;
            }
            else
            {
                // Split into leading and trailing surrogates.
                // From http://unicode.org/faq/utf_bom.html#35
                wchar_t leadingValue    = wchar_t(0xD800 + (charValue >> 10)  - (0x10000 >> 10));
                wchar_t trailingValue   = wchar_t(0xDC00 + (charValue & 0x3FF));
                characterMapText[textLength + 0] = leadingValue;
                characterMapText[textLength + 1] = trailingValue;
                codeUnitCount = 2;
            }
            textLength += codeUnitCount;
        }

        SetLayoutShape(CommandIdShapeGrid);

        break;

    default:
        return E_FAIL;
    }
    textSample_ = commandId;

    IDWriteTextFormat* textFormat = nullptr;
    hr = ShowMessageIfFailed(
            dwriteFactory_->CreateTextFormat(
                fontName,
                nullptr,
                DWRITE_FONT_WEIGHT_NORMAL,
                DWRITE_FONT_STYLE_NORMAL,
                DWRITE_FONT_STRETCH_NORMAL,
                fontSize,
                localeName,
                &textFormat
                ),
            L"Could not create text format for custom layout! CreateTextFormat()"  FAILURE_LOCATION
            );

    if (SUCCEEDED(hr))
    {
        hr = ShowMessageIfFailed(
                flowLayout_->SetTextFormat(textFormat),
                L"Could not set text format on custom layout! SetTextFormat()"  FAILURE_LOCATION
                );
        flowLayout_->SetReadingDirection(readingDirection);
        flowLayout_->SetTreatAsIsolatedCharacters(treatAsIsolatedCharacters);
    }

    if (SUCCEEDED(hr))
    {
        hr = ShowMessageIfFailed(
                flowLayout_->SetReadingDirection(readingDirection),
                L"Could not set text format on custom layout! SetTextFormat()"  FAILURE_LOCATION
                );
    }

    if (SUCCEEDED(hr))
    {
        if (textLength == 0)
        {
            textLength = static_cast<uint32_t>(wcsnlen(text, UINT32_MAX));
        }

        hr = ShowMessageIfFailed(
                flowLayout_->SetText(text, textLength),
                L"Text analysis failed! FlowLayout::AnalyzeText()"  FAILURE_LOCATION
                );
    }

    if (SUCCEEDED(hr))
    {
        hr = ShowMessageIfFailed(
                flowLayout_->AnalyzeText(),
                L"Text analysis failed! FlowLayout::AnalyzeText()"  FAILURE_LOCATION
                );
    }

    SafeRelease(&textFormat);

    return hr;
}


STDMETHODIMP MainWindow::SetLayoutShape(UINT commandId)
{
    return flowLayoutSource_->SetShape(FlowLayoutSource::FlowShape(commandId - CommandIdShapeFirstId));
}


STDMETHODIMP MainWindow::SetLayoutNumbers(UINT commandId)
{
    // Creates a number substitution to select which digits are displayed.

    HRESULT hr = S_OK;

    const wchar_t* localeName;
    switch (commandId)
    {
    case CommandIdNumbersNominal:
        localeName = L"en-us";
        break;

    case CommandIdNumbersArabic:
        localeName = L"ar-eg";
        break;

    default:
        return E_FAIL;
    }

    // Create and set the new digits.
    IDWriteNumberSubstitution* numberSubstitution = nullptr;
    if (SUCCEEDED(hr))
    {
        hr = ShowMessageIfFailed(
                dwriteFactory_->CreateNumberSubstitution(DWRITE_NUMBER_SUBSTITUTION_METHOD_CONTEXTUAL, localeName, TRUE, &numberSubstitution),
                L"CreateNumberSubstitution failed!"  FAILURE_LOCATION
                );
        flowLayout_->SetNumberSubstitution(numberSubstitution);
    }

    if (SUCCEEDED(hr))
    {
        hr = ShowMessageIfFailed(
                flowLayout_->AnalyzeText(),
                L"Text analysis failed! FlowLayout::AnalyzeText()"  FAILURE_LOCATION
                );
    }

    SafeRelease(&numberSubstitution);

    return hr;
}


STDMETHODIMP MainWindow::SetReadingDirection(UINT commandId)
{
    HRESULT hr = S_OK;

    if (SUCCEEDED(hr))
    {
        hr = ShowMessageIfFailed(
                flowLayout_->SetReadingDirection(ReadingDirection(commandId - CommandIdReadingDirectionFirstId)),
                L"FlowLayout::SetReadingDirection() failed!"  FAILURE_LOCATION
                );
    }

    if (SUCCEEDED(hr))
    {
        hr = ShowMessageIfFailed(
                flowLayout_->AnalyzeText(),
                L"Text analysis failed! FlowLayout::AnalyzeText()"  FAILURE_LOCATION
                );
    }

    return hr;
}


STDMETHODIMP MainWindow::SetJustification(UINT commandId)
{
    return flowLayout_->SetJustificationMode(FlowLayout::JustificationMode(commandId - CommandIdJustifyFirstId));
}


STDMETHODIMP MainWindow::SetGlyphOrientationMode(UINT commandId)
{
    HRESULT hr = S_OK;

    if (SUCCEEDED(hr))
    {
        hr = ShowMessageIfFailed(
                flowLayout_->SetGlyphOrientationMode(GlyphOrientationMode(commandId - CommandIdOrientFirstId)),
                L"FlowLayout::SetReadingDirection() failed!"  FAILURE_LOCATION
                );
    }

    if (SUCCEEDED(hr))
    {
        hr = ShowMessageIfFailed(
                flowLayout_->AnalyzeText(),
                L"Text analysis failed! FlowLayout::AnalyzeText()"  FAILURE_LOCATION
                );
    }

    return hr;
}


namespace
{
    float const g_defaultFontSize = 20;
    bool const g_defaultHasUnderline = false;
    bool const g_defaultHasStrikethrough = false;
    DWRITE_FONT_WEIGHT const g_defaultFontWeight = DWRITE_FONT_WEIGHT_NORMAL;
    DWRITE_FONT_STRETCH const g_defaultFontStretch = DWRITE_FONT_STRETCH_NORMAL;
    DWRITE_FONT_STYLE const g_defaultFontSlope = DWRITE_FONT_STYLE_NORMAL;
    wchar_t g_ActualFaceName[LF_FACESIZE];
    float g_ActualFontSize = 0;
    HWND g_chooseFontParent = nullptr;
}


UINT_PTR CALLBACK ChooseFontHookProc(
    HWND dialogHandle,
    UINT message,
    WPARAM wParam,
    LPARAM lParam
    )
{
    // This callback retrieves the actual parameters from the user.

    enum {
        FontNameComboBoxId = 0x0470,
        FontSizeComboBoxId = 0x0472,
    };

    wchar_t fontSizeStringBuffer[100];

    if (message == WM_INITDIALOG)
    {
        CHOOSEFONT* chooseFont = reinterpret_cast<CHOOSEFONT*>(lParam);

        g_chooseFontParent = chooseFont->hwndOwner;

        // Correct the font size.
        HWND editHandle = GetDlgItem(dialogHandle, FontSizeComboBoxId);
        swprintf_s(fontSizeStringBuffer, ARRAYSIZE(fontSizeStringBuffer), L"%0.1f", float(chooseFont->iPointSize) / 10.0f);
        Edit_SetText(editHandle, fontSizeStringBuffer);

        return true;
    }

    if (message == WM_COMMAND && HIWORD(wParam) == BN_CLICKED)
    {
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == WM_CHOOSEFONT_GETLOGFONT + 1)
        {
            // Get the font name which the user actually typed, not a reprocessed
            // or substituted one. This is needed for typing font names that either
            // are unlisted (user hid them), don't match DWrite's naming model,
            // or have localized names (which do not appear in the box).
            HWND editHandle = GetDlgItem(dialogHandle, FontNameComboBoxId);
            if (editHandle != nullptr)
            {
                // Ignore the result from ChooseFont() and keep track of
                // the actual font name typed into the family name combo.
                Edit_GetText(editHandle, g_ActualFaceName, ARRAYSIZE(g_ActualFaceName));
            }

            // Get the true font size, since we want the original value rather than
            // a premultiplied and truncated value.
            editHandle = GetDlgItem(dialogHandle, FontSizeComboBoxId);
            if (editHandle != nullptr)
            {
                Edit_GetText(editHandle, fontSizeStringBuffer, ARRAYSIZE(fontSizeStringBuffer));
                g_ActualFontSize = float(_wtof(fontSizeStringBuffer));

                // Set a whole integer before returning, since the dialog otherwise
                // complains about decimal values.
                swprintf_s(fontSizeStringBuffer, ARRAYSIZE(fontSizeStringBuffer), L"%d", int(g_ActualFontSize));
                Edit_SetText(editHandle, fontSizeStringBuffer);
            }

            LOGFONT logFont = {};
            SendMessage(dialogHandle, WM_CHOOSEFONT_GETLOGFONT, 0, (LPARAM)&logFont);
            MainWindow* window = reinterpret_cast<MainWindow*>(GetWindowLongPtr(g_chooseFontParent, GWLP_USERDATA));
            if (window != nullptr)
            {
                window->SetCustomLayoutFontFromLogFont(logFont);
                window->ReflowLayout();
            }
        }
    }

    return 0;
}


STDMETHODIMP MainWindow::OnChooseFont()
{
    LOGFONT logFont = {};
    logFont.lfHeight            = -static_cast<LONG>(floor(g_defaultFontSize));
    logFont.lfWidth             = 0;
    logFont.lfEscapement        = 0;
    logFont.lfOrientation       = 0;
    logFont.lfWeight            = g_defaultFontWeight;
    logFont.lfItalic            = (g_defaultFontSlope > DWRITE_FONT_STYLE_NORMAL);
    logFont.lfUnderline         = static_cast<BYTE>(g_defaultHasUnderline);
    logFont.lfStrikeOut         = static_cast<BYTE>(g_defaultHasStrikethrough);
    logFont.lfCharSet           = DEFAULT_CHARSET;
    logFont.lfOutPrecision      = OUT_DEFAULT_PRECIS;
    logFont.lfClipPrecision     = CLIP_DEFAULT_PRECIS;
    logFont.lfQuality           = DEFAULT_QUALITY;
    logFont.lfPitchAndFamily    = DEFAULT_PITCH;
    wcsncpy_s(logFont.lfFaceName, L"Segoe UI", ARRAYSIZE(logFont.lfFaceName));
    wcsncpy_s(g_ActualFaceName, L"Segoe UI", ARRAYSIZE(g_ActualFaceName));

    //////////////////////////////
    // Initialize CHOOSEFONT for the dialog.

    #ifndef CF_INACTIVEFONTS
    #define CF_INACTIVEFONTS 0x02000000L
    #endif
    CHOOSEFONT chooseFont   = {};
    chooseFont.lpfnHook     = &ChooseFontHookProc;
    chooseFont.lStructSize  = sizeof(chooseFont);
    chooseFont.hwndOwner    = hwnd_;
    chooseFont.lpLogFont    = &logFont;
    chooseFont.iPointSize   = INT(g_defaultFontSize * 10 + .5f);
    chooseFont.rgbColors    = 0;
    chooseFont.Flags        = CF_SCREENFONTS
                            | CF_PRINTERFONTS
                            | CF_INACTIVEFONTS  // Don't hide fonts
                            | CF_NOVERTFONTS
                            | CF_NOSCRIPTSEL
                            | CF_INITTOLOGFONTSTRUCT
                            | CF_ENABLEHOOK
                            | CF_APPLY
                            ;

    // We don't show vertical fonts because we don't do vertical layout,
    // and don't show bitmap fonts because DirectWrite doesn't support them.

    // Show the common font dialog box.
    if (!ChooseFont(&chooseFont))
    {
        return S_FALSE; // user canceled.
    }

    return SetCustomLayoutFontFromLogFont(logFont);
}


STDMETHODIMP MainWindow::SetCustomLayoutFontFromLogFont(const LOGFONT& logFont)
{
    HRESULT hr = S_OK;

    float fontSize = g_ActualFontSize;
    DWRITE_FONT_WEIGHT fontWeight = g_defaultFontWeight;
    DWRITE_FONT_STRETCH fontStretch = g_defaultFontStretch;
    DWRITE_FONT_STYLE fontSlope = g_defaultFontSlope;

    // Abort if the user didn't select a face name.
    if (g_ActualFaceName[0] == L'\0')
    {
        return S_FALSE;
    }

    // Get the actual family name and stretch.
    {
        IDWriteGdiInterop* gdiInterop = nullptr;
        IDWriteFont* tempFont = nullptr;

        dwriteFactory_->GetGdiInterop(&gdiInterop);
        if (gdiInterop != nullptr)
        {
            gdiInterop->CreateFontFromLOGFONT(&logFont, &tempFont);
            if (tempFont != nullptr)
            {
                fontStretch = tempFont->GetStretch();
            }
        }

        SafeRelease(&gdiInterop);
        SafeRelease(&tempFont);
    }

    if (SUCCEEDED(hr))
    {
        fontWeight = static_cast<DWRITE_FONT_WEIGHT>(logFont.lfWeight);
        fontSlope = logFont.lfItalic ? DWRITE_FONT_STYLE_ITALIC : DWRITE_FONT_STYLE_NORMAL;

        hr = ShowMessageIfFailed(
                flowLayout_->SetFont(
                    logFont.lfFaceName,
                    fontWeight,
                    fontStretch,
                    fontSlope,
                    fontSize
                    ),
                L"Could not set text format on custom layout! SetTextFormat()"  FAILURE_LOCATION
                );
    }

    if (SUCCEEDED(hr))
    {
        hr = ShowMessageIfFailed(
                flowLayout_->AnalyzeText(),
                L"Text analysis failed! FlowLayout::AnalyzeText()"  FAILURE_LOCATION
                );
    }

    return hr;
}


STDMETHODIMP MainWindow::SetCharacterMapBase(uint32_t characterMapBase)
{
    // Set the new base and invalidate the old layout.

    if (characterMapBase > UnicodeMax)
    {
        return S_OK; // silently ignore any wrap-around.
    }

    characterMapBase_ = characterMapBase;

    SetLayoutSampleText(CommandIdTextCharacterMap);
    ReflowLayout();

    return S_OK;
}


HRESULT MainWindow::CopyToClipboard()
{
    return flowLayout_->CopyToClipboard();
}


HRESULT MainWindow::CopyImageToClipboard()
{
    if (renderTarget_ != nullptr)
    {
        return ::CopyImageToClipboard(hwnd_, renderTarget_->GetMemoryDC());
    }
    return E_FAIL;
}


HRESULT MainWindow::PasteFromClipboard()
{
    flowLayout_->PasteFromClipboard();
    flowLayout_->AnalyzeText();
    ReflowLayout();

    return S_OK;
}


HRESULT ShowMessageIfFailed(HRESULT functionResult, const wchar_t* message)
{
    // Displays an error message for API failures,
    // returning the very same error code that came in.

    if (FAILED(functionResult))
    {
        const wchar_t* format = L"%s\r\nError code = %X";

        wchar_t buffer[1000];
        buffer[0] = '\0';

        StringCchPrintf(buffer, ARRAYSIZE(buffer), format, message, functionResult);
        MessageBox(nullptr, buffer, TEXT(APPLICATION_TITLE), MB_OK|MB_ICONEXCLAMATION|MB_TASKMODAL);
    }
    return functionResult;
}


namespace
{
    template <typename T>
    static inline T* AddBitmapByteOffset(T* p, size_t offset)
    {
        return reinterpret_cast<T*>(reinterpret_cast<uint8_t*>(p) + offset);
    }

    template <typename T>
    static inline T const* AddBitmapByteOffset(T const* p, size_t offset)
    {
        return reinterpret_cast<T const*>(reinterpret_cast<uint8_t const*>(p) + offset);
    }

    struct ErrorChecker
    {
        ErrorChecker()
        {
            hr = S_OK;
            SetLastError(NOERROR);
        }

        void Check()
        {
            if (SUCCEEDED(hr))
            {
                DWORD lastError = GetLastError();
                if (lastError != NOERROR)
                {
                    hr = HRESULT_FROM_WIN32(GetLastError());
                }
            }
        }

        HRESULT hr;
    };
}


HRESULT CopyImageToClipboard(
    HWND hwnd,
    HDC hdc,
    bool isUpsideDown
    )
{
    DIBSECTION sourceBitmapInfo = {};
    HBITMAP sourceBitmap = (HBITMAP)GetCurrentObject(hdc, OBJ_BITMAP);
    GetObject(sourceBitmap, sizeof(sourceBitmapInfo), &sourceBitmapInfo);

    ErrorChecker errorChecker;

    if (sourceBitmapInfo.dsBm.bmBitsPixel <= 8
    ||  sourceBitmapInfo.dsBm.bmBits == nullptr
    ||  sourceBitmapInfo.dsBm.bmWidth <= 0
    ||  sourceBitmapInfo.dsBm.bmHeight <= 0)
    {
        // Don't support paletted images, only true color.
        // Only support bitmaps where the pixels are accessible.
        return E_NOTIMPL;
    }

    if (OpenClipboard(hwnd))
    {
        if (EmptyClipboard())
        {
            const size_t pixelsByteSize = sourceBitmapInfo.dsBmih.biSizeImage;
            const size_t bufferLength = sizeof(sourceBitmapInfo.dsBmih) + pixelsByteSize;
            HGLOBAL bufferHandle = GlobalAlloc(GMEM_MOVEABLE, bufferLength);
            uint8_t* buffer = reinterpret_cast<uint8_t*>(GlobalLock(bufferHandle));

            // Copy the header.
            memcpy(buffer, &sourceBitmapInfo.dsBmih, sizeof(sourceBitmapInfo.dsBmih));

            if (isUpsideDown)
            {
                // The image is a bottom-up orientation. Though, since
                // Windows legacy bitmaps are upside down too, the two
                // upside-downs cancel out.
                memcpy(buffer + sizeof(sourceBitmapInfo.dsBmih), sourceBitmapInfo.dsBm.bmBits, pixelsByteSize);
            }
            else
            {
                // We have a standard top-down image, but DIBs when shared
                // on the clipboard are actually upside down. Simply flipping
                // the height to negative works for a few applications, but
                // it confuses most.

                const size_t bytesPerRow = sourceBitmapInfo.dsBm.bmWidthBytes;
                uint8_t* destRow         = buffer + sizeof(sourceBitmapInfo.dsBmih);
                uint8_t* sourceRow       = reinterpret_cast<uint8_t*>(sourceBitmapInfo.dsBm.bmBits)
                                            + (sourceBitmapInfo.dsBm.bmHeight - 1) * bytesPerRow;

                // Copy each scanline in backwards order.
                for (long y = 0; y < sourceBitmapInfo.dsBm.bmHeight; ++y)
                {
                    memcpy(destRow, sourceRow, bytesPerRow);
                    sourceRow = AddBitmapByteOffset(sourceRow, -ptrdiff_t(bytesPerRow));
                    destRow   = AddBitmapByteOffset(destRow,    bytesPerRow);
                }
            }

            GlobalUnlock(bufferHandle);

            if (SetClipboardData(CF_DIB, bufferHandle) == nullptr)
            {
                errorChecker.Check();
                GlobalFree(bufferHandle);
            }
        }
        errorChecker.Check();

        CloseClipboard();
    }
    errorChecker.Check();

    return errorChecker.hr;
}


// </SnippetCustomLayoutcpp>
