//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Main user interface window.
//
//----------------------------------------------------------------------------
#include "precomp.h"


ProfilerWindow::ProfilerWindow(
    UiControl* parent,
    IDWriteTextEditLayout* textLayout,
    IDWriteFactory* dwriteFactory,
    //-ID2D1Factory* d2dFactory,
    HWND hwnd
    )
:   Window()
{
    Init();
    if (!Create(parent))
        throw std::exception("Could not create ProfilerWindow" FAILURE_LOCATION);

    threadHandle_ = GetCurrentThread(); // pseudohandle to currently executing thread

    InitializeControls();

    //-textLayout_.Set(textLayout);
    dwriteFactory_.Set(dwriteFactory);
    //-d2dFactory_.Set(d2dFactory);
    hwnd_ = hwnd; // the parent should outlive the child, so this will remain valid
}


bool ProfilerWindow::Destroy()
{
    // Explicitly clear to remove references sooner.
    // Otherwise we would hold onto them until the destructor
    // was called.
    //-textLayout_.Clear();
    dwriteFactory_.Clear();
    //-d2dFactory_.Clear();

    return Base::Destroy();
}


namespace
{
    const static unsigned int g_iterations[] = {1,10,100,1000,10000,100000,1000000};

    struct NameFunc
    {
        void (ProfilerWindow::*function)();
        const wchar_t* name;
    };

    // These functions measure various performance aspects.
    // Each should call BeginProfile/EndProfile to time the
    // duration and print results.
    const static NameFunc g_PerfTestsTable[] = {
        { nullptr,                                      L"Measure"},
        { &ProfilerWindow::MeasureDWriteLayout,         L"DWrite"},
        { &ProfilerWindow::MeasureUserGdi,              L"GDI/User DrawText calc rect"},
        { &ProfilerWindow::MeasureGdiPlus,              L"GDI+ MeasuringString"},
        { nullptr,                                      L"Redraw text"},
        { &ProfilerWindow::DrawLayoutDWrite,            L"Layout via DWrite DrawGlyphRun"},
        { &ProfilerWindow::DrawLayoutD2dSoft,           L"Layout via D2D software DrawGlyphRun"},
        { &ProfilerWindow::DrawLayoutD2dHard,           L"Layout via D2D hardware DrawGlyphRun"},
        { &ProfilerWindow::DrawLayoutGdi,               L"Layout via GDI ExtTextOut (glyph id's)"},
        { &ProfilerWindow::DrawLayoutGdiPlus,           L"Layout via GDI+ DrawDriverString"},
        { &ProfilerWindow::DrawLayoutNullDraw,          L"Layout via Null draw callback"},
        { &ProfilerWindow::DrawTextUserGdi,             L"GDI/User DrawText"},
        { &ProfilerWindow::DrawTextGdiPlus,             L"GDI+ DrawString"},
        { nullptr,                                      L"Text analysis"},
        { &ProfilerWindow::AnalyzeScript,               L"DWrite AnalyzeScript"},
        { &ProfilerWindow::AnalyzeBidi,                 L"DWrite AnalyzeBidi"},
        { &ProfilerWindow::AnalyzeLineBreakpoints,      L"DWrite AnalyzeLineBreakpoints"},
        { &ProfilerWindow::AnalyzeNumberSubstitution,   L"DWrite AnalyzeNumberSubstitution"},
        { &ProfilerWindow::ScriptItemize,               L"Uniscribe ScriptItemize"},
        { &ProfilerWindow::ScriptBreak,                 L"Uniscribe ScriptBreak"},
        { &ProfilerWindow::ScriptShape,                 L"*Uniscribe ScriptShape"},
        { &ProfilerWindow::ScriptPlace,                 L"*Uniscribe ScriptPlace"},
        { nullptr,                                      L"Glyph analysis"},
        { &ProfilerWindow::Dummy,                       L"*Uniscribe shape"},
        { &ProfilerWindow::Dummy,                       L"*DWrite GetGlyphs"},
        { nullptr,                                      L"Hit testing"},
        { &ProfilerWindow::Dummy,                       L"*DWrite HitTestPoint"},
        { &ProfilerWindow::Dummy,                       L"*Uniscribe ScriptXtoCP"},
        { &ProfilerWindow::Dummy,                       L"*DWrite HitTestTextPosition"},
        { &ProfilerWindow::Dummy,                       L"*Uniscribe ScriptCPtoX"},
        { nullptr,                                      L"Font enumeration"},
        { &ProfilerWindow::Dummy,                       L"*DWrite"},
        { &ProfilerWindow::Dummy,                       L"*GDI"},
        { nullptr,                                      L"Font creation"},
        { &ProfilerWindow::Dummy,                       L"*DirectWrite CreateFontFace"},
        { &ProfilerWindow::Dummy,                       L"*GDI CreateFont"},
    };

    class TextAnalysisSourceSink : public IDWriteTextAnalysisSource, public IDWriteTextAnalysisSink
    {
        ComPtr<IDWriteTextAnalyzer> textAnalyzer_;
        ComPtr<IDWriteNumberSubstitution> numberSubstitution_;
        __in IDWriteTextEditLayout* textLayout_;
        __ecount(textLength_) const wchar_t* text_;
        UINT32 textLength_;

    public:
        TextAnalysisSourceSink(__notnull IDWriteFactory* factory, __notnull IDWriteTextEditLayout* textLayout)
        :   textLayout_(textLayout),
            text_(textLayout->GetText()),
            textLength_(textLayout->GetTextLength())
        {
            OsException::ThrowOnFailure(
                factory->CreateTextAnalyzer(&textAnalyzer_),
                "Could not create text analyzer! IDWriteFactory::CreateTextAnalyzer(...)" FAILURE_LOCATION
            );
            OsException::ThrowOnFailure(
                factory->CreateNumberSubstitution(DWRITE_NUMBER_SUBSTITUTION_METHOD_TRADITIONAL, L"ar-eg", false, &numberSubstitution_),
                "Could not create number substitution! IDWriteFactory::CreateNumberSubstitution(...)" FAILURE_LOCATION
            );

        }

        IDWriteTextAnalyzer& GetTextAnalyzer()
        {
            return *textAnalyzer_.Reference();
        }

        ////////////////////////////////////////
        // Source interface

        virtual HRESULT STDMETHODCALLTYPE GetTextAtPosition(
            UINT32 textPosition,
            __out wchar_t const** textString,
            __out UINT32* textLength
            )
        {
            if (textPosition >= textLength_)
            {
                *textLength = 0;
                *textString = nullptr;
            }
            else
            {
                *textLength = textLength_ - textPosition;
                *textString = &text_[textPosition];
            }
            return S_OK;
        }

        virtual HRESULT STDMETHODCALLTYPE GetTextBeforePosition(
            UINT32 textPosition,
            __out wchar_t const** textString,
            __out UINT32* textLength
            )
        {
            if (textPosition <= 0)
            {
                *textLength = 0;
                *textString = nullptr;
            }
            else if (textPosition > textLength_)
            {
                *textLength = textPosition - textLength_;
                *textString = nullptr;
            }
            else
            {
                *textLength = textPosition;
                *textString = text_;
            }
            return S_OK;
        }

        virtual DWRITE_READING_DIRECTION STDMETHODCALLTYPE GetParagraphReadingDirection()
        {
            return textLayout_->GetReadingDirection();
        }

        virtual HRESULT STDMETHODCALLTYPE GetLocaleName(
            UINT32 textPosition,
            __out UINT32* textLength,
            __out_z wchar_t const** localeName
            )
        {
            *textLength = textLength_ - textPosition;
            *localeName = L"en-us";
            return S_OK;
        }

        virtual HRESULT STDMETHODCALLTYPE GetNumberSubstitution(
            UINT32 textPosition,
            __out UINT32* textLength,
            __out IDWriteNumberSubstitution** numberSubstitution
            )
        {
            *textLength = textLength_ - textPosition;
            numberSubstitution_->AddRef(); // explicity addref out param
            *numberSubstitution = numberSubstitution_;
            return S_OK;
        }

        ////////////////////////////////////////
        // Text analysis sink interface

        virtual HRESULT STDMETHODCALLTYPE SetScriptAnalysis(
            __in UINT32 textPosition,
            __in UINT32 textLength,
            __in DWRITE_SCRIPT_ANALYSIS const* scriptAnalysis
            )
        {
            return S_OK;
        }

        virtual HRESULT STDMETHODCALLTYPE SetLineBreakpoints(
            __in UINT32 textPosition,
            __in UINT32 textLength,
            __in_ecount(textLength) const DWRITE_LINE_BREAKPOINT*   lineBreakpoints
            )
        {   
            return S_OK;
        }

        virtual HRESULT STDMETHODCALLTYPE SetBidiLevel(
            __in UINT32 textPosition,
            __in UINT32 textLength,
            __in UINT8 explicitBidiLevel,
            __in UINT8 resolvedBidiLevel
            )
        {   
            return S_OK;
        }

        virtual HRESULT STDMETHODCALLTYPE SetNumberSubstitution(
            __in UINT32 textPosition,
            __in UINT32 textLength,
            __in IDWriteNumberSubstitution* numberSubstitution
            )
        {   
            return S_OK;
        }

        ////////////////////////////////////////
        // Static IUnknown interface
        // *It's test code, and there will only be one instance!

        virtual HRESULT STDMETHODCALLTYPE QueryInterface(IID const& iid, __out void** object) throw() OVERRIDE
        {
            *object = nullptr;
            return E_NOINTERFACE;
        }

        virtual unsigned long STDMETHODCALLTYPE AddRef() throw() OVERRIDE
        {
            return 1;
        }

        virtual unsigned long STDMETHODCALLTYPE Release() throw() OVERRIDE
        {
            return 1;
        }
    };


    // Translate text layout's properties into something User32/GDI DrawText can understand
    UINT GetDrawTextFlags(__notnull IDWriteTextEditLayout* textLayout)
    {
        if (textLayout == nullptr)
            return 0;

        // Query layout's attributes
        DWRITE_WORD_WRAPPING lineWrapping               = textLayout->GetWordWrapping();
        DWRITE_READING_DIRECTION readingDirection       = textLayout->GetReadingDirection();
        DWRITE_TEXT_ALIGNMENT textAlignment             = textLayout->GetTextAlignment();
        DWRITE_PARAGRAPH_ALIGNMENT paragraphAlignment   = textLayout->GetParagraphAlignment();
        bool containsTabs = (wcschr(textLayout->GetText(), '\t') != nullptr);

        UINT drawTextFlags = 0;
        drawTextFlags = DT_NOCLIP | DT_NOPREFIX;
        drawTextFlags |= (lineWrapping == DWRITE_WORD_WRAPPING_WRAP) ? DT_WORDBREAK : 0;

        // Set horizontal alignment flags
        if (readingDirection == DWRITE_READING_DIRECTION_RIGHT_TO_LEFT)
        {
            drawTextFlags |= DT_RTLREADING;
            drawTextFlags |=
                (textAlignment == DWRITE_TEXT_ALIGNMENT_CENTER)     ? DT_CENTER :
                (textAlignment == DWRITE_TEXT_ALIGNMENT_TRAILING)   ? DT_LEFT   :
                DT_RIGHT;
        }
        else
        {
            drawTextFlags |=
                (textAlignment == DWRITE_TEXT_ALIGNMENT_CENTER)     ? DT_CENTER :
                (textAlignment == DWRITE_TEXT_ALIGNMENT_TRAILING)   ? DT_RIGHT  :
                DT_LEFT;
        }

        // Vertically centering only works in DrawText for single lines
        // Specifying this flag gives DrawText a significant speedup.
        /*
        UINT32 actualLineCount;
        textLayout->GetLineMetrics(nullptr, 0, &actualLineCount);
        if (actualLineCount == 1)
            drawTextFlags |= DT_SINGLELINE;
        */

        drawTextFlags |=
            (paragraphAlignment == DWRITE_PARAGRAPH_ALIGNMENT_CENTER)   ? DT_VCENTER :
            (paragraphAlignment == DWRITE_PARAGRAPH_ALIGNMENT_NEAR)     ? DT_TOP  :
            DT_BOTTOM;

        // Set tab-stops if tabs are contained in text.
        if (containsTabs)
            drawTextFlags |= DT_EXPANDTABS; // | DT_TABSTOP | (4<<8); // bits 8-15 specify characters per tab (but clashes with other bits)

        return drawTextFlags;
    }


    // Convert text layout's properties into equivalent GDI font.
    HFONT GetGdiFont(__notnull IDWriteTextEditLayout* textLayout)
    {
        if (textLayout == nullptr)
            return nullptr;

        DWRITE_FONT_STRETCH fontStretch = DWRITE_FONT_STRETCH_NORMAL;
        DWRITE_FONT_STYLE fontSlope = DWRITE_FONT_STYLE_NORMAL;
        DWRITE_FONT_WEIGHT fontWeight = DWRITE_FONT_WEIGHT_NORMAL;
        FLOAT fontSize = 0;
        BOOL hasStrikethrough = false;
        BOOL hasUnderline = false;

        textLayout->GetFontSize(0, &fontSize);
        textLayout->GetFontStretch(0, &fontStretch);
        textLayout->GetFontWeight(0, &fontWeight);
        textLayout->GetFontStyle(0, &fontSlope);
        textLayout->GetUnderline(0, &hasUnderline);
        textLayout->GetStrikethrough(0, &hasStrikethrough);
        
        float adjustedFontSize = fontSize;

        LOGFONT logFont = {
            -LONG(floor(adjustedFontSize + .5f)),0, // rounded instead of floored
            0,0,
            fontWeight,
            fontSlope != DWRITE_FONT_STYLE_NORMAL,
            BYTE(hasUnderline),
            BYTE(hasStrikethrough),
            ANSI_CHARSET, //DEFAULT_CHARSET,
            OUT_DEFAULT_PRECIS,
            CLIP_DEFAULT_PRECIS,
            DEFAULT_QUALITY,
            FF_DONTCARE,
            L"Arial"
        };
        textLayout->GetFontFamilyName(0, &logFont.lfFaceName[0], ARRAY_SIZE(logFont.lfFaceName));

        return CreateFontIndirect(&logFont);
    }


    // Convert text layout's properties into equivalent GDI+ font.
    Gdiplus::Font* GetGdiPlusFont(__notnull IDWriteTextEditLayout* textLayout)
    {
        if (textLayout == nullptr)
            return nullptr;

        DWRITE_FONT_STRETCH fontStretch = DWRITE_FONT_STRETCH_NORMAL;
        DWRITE_FONT_STYLE fontSlope = DWRITE_FONT_STYLE_NORMAL;
        DWRITE_FONT_WEIGHT fontWeight = DWRITE_FONT_WEIGHT_NORMAL;
        BOOL hasStrikethrough = false;
        BOOL hasUnderline = false;
        FLOAT fontSize = 0;

        textLayout->GetFontSize(0, &fontSize);
        textLayout->GetFontStretch(0, &fontStretch);
        textLayout->GetFontWeight(0, &fontWeight);
        textLayout->GetFontStyle(0, &fontSlope);
        textLayout->GetUnderline(0, &hasUnderline);
        textLayout->GetStrikethrough(0, &hasStrikethrough);

        // Convert WWS to flags (plus bold and italic)
        UINT32 style = 0;
        if (hasUnderline)                           style |= Gdiplus::FontStyleUnderline;
        if (hasStrikethrough)                       style |= Gdiplus::FontStyleStrikeout;
        if (fontWeight > DWRITE_FONT_WEIGHT_NORMAL) style |= Gdiplus::FontStyleBold;
        if (fontSlope > DWRITE_FONT_STYLE_NORMAL)   style |= Gdiplus::FontStyleItalic;

        Gdiplus::REAL adjustedFontSize = fontSize;

        wchar_t fontName[128];
        textLayout->GetFontFamilyName(0, &fontName[0], ARRAY_SIZE(fontName));
        Gdiplus::FontFamily fontFamily(fontName);

        return new Gdiplus::Font(&fontFamily, adjustedFontSize, Gdiplus::FontStyle(style), Gdiplus::UnitPixel);
    }


    // Translate text layout's properties into something GDI+ understands.
    void ModifyGdiPlusStringFormat(__notnull IDWriteTextEditLayout* textLayout, __inout Gdiplus::StringFormat& stringFormat)
    {
        // Query layout's attributes
        DWRITE_WORD_WRAPPING lineWrapping               = textLayout->GetWordWrapping();
        DWRITE_READING_DIRECTION readingDirection       = textLayout->GetReadingDirection();
        DWRITE_TEXT_ALIGNMENT textAlignment             = textLayout->GetTextAlignment();
        DWRITE_PARAGRAPH_ALIGNMENT paragraphAlignment   = textLayout->GetParagraphAlignment();
        bool containsTabs = (wcschr(textLayout->GetText(), '\t') != nullptr);

        UINT32 flags = stringFormat.GetFormatFlags() & ~(Gdiplus::StringFormatFlagsDirectionRightToLeft|Gdiplus::StringFormatFlagsNoWrap);
        if (readingDirection == DWRITE_READING_DIRECTION_RIGHT_TO_LEFT)
        {
            flags |= Gdiplus::StringFormatFlagsDirectionRightToLeft;
        }
        if (lineWrapping == DWRITE_WORD_WRAPPING_NO_WRAP)
        {
            flags |= Gdiplus::StringFormatFlagsNoWrap;
        }
        stringFormat.SetFormatFlags(Gdiplus::StringFormatFlags(flags));

        stringFormat.SetAlignment(
            (textAlignment == DWRITE_TEXT_ALIGNMENT_CENTER)      ? Gdiplus::StringAlignmentCenter :
            (textAlignment == DWRITE_TEXT_ALIGNMENT_LEADING)     ? Gdiplus::StringAlignmentNear :
            Gdiplus::StringAlignmentFar
            );
        stringFormat.SetLineAlignment(
            (paragraphAlignment == DWRITE_PARAGRAPH_ALIGNMENT_CENTER) ? Gdiplus::StringAlignmentCenter :
            (paragraphAlignment == DWRITE_PARAGRAPH_ALIGNMENT_NEAR)   ? Gdiplus::StringAlignmentNear :
            Gdiplus::StringAlignmentFar
            );

        // Set tab-stops if tabs are contained in text.
        if (containsTabs)
        {
            const static Gdiplus::REAL tabs[] = {80};
            stringFormat.SetTabStops(0, 1, tabs);
        }
    }

    SCRIPT_CONTROL g_emptyScriptControl = {0};
    SCRIPT_STATE g_emptyScriptState = {0};

    void GetUniscribeControlState(TextAnalysisSourceSink& sourceSink, SCRIPT_CONTROL& scriptControl, SCRIPT_STATE& scriptState)
    {
        scriptControl = g_emptyScriptControl;
        scriptControl.fMergeNeutralItems = false;   // neutral characters are merged into strong items, when possible

        scriptState = g_emptyScriptState;
        scriptState.fDisplayZWG = false;            // TRUE if control characters are shaped as representational glyphs
        scriptState.fArabicNumContext = 0u;         // TRUE for RTL paragraph in an Arabic language (except Moroccan)

        if (sourceSink.GetParagraphReadingDirection() == DWRITE_READING_DIRECTION_RIGHT_TO_LEFT)
        {
            scriptState.uBidiLevel = 1; // paragraph base embedding level

            const wchar_t* localeName = L"";
            UINT32 localeLength;
            if (sourceSink.GetLocaleName(0 /*textPos*/, &localeLength, &localeName) == S_OK
            &&  wcsstr(localeName, L"ar") == localeName
            &&  wcsstr(localeName, L"ar-ma") != localeName
            )
            {
                scriptState.fArabicNumContext = 1u;
            }
        }
    }
}


////////////////////////////////////////
// Main entry.


void ProfilerWindow::InitializeControls()
{
    //////////////////////////////
    // Main ribbon

    RibbonChunk* ribbonChunk;
    ButtonGroup* buttonGroup;
    TextList* list;
    Button* button;

    buttonGroup = new ButtonGroup(this, 0, false);

    ribbonChunk = new RibbonChunk(buttonGroup, L"Select test");

        list = new TextList(ribbonChunk, ControlIdTests);
        list->SetPosition(MakePosition(0,0,280,300));
        list->SetStyle(StyleFlagRigidHeight);
        for (size_t i = 0; i < ARRAY_SIZE(g_PerfTestsTable); ++i)
        {
            wchar_t buffer[1024];
            StringCchPrintf(
                buffer,
                ARRAY_SIZE(buffer),
                (g_PerfTestsTable[i].function != nullptr) ? L"    %s" : L"%s",
                g_PerfTestsTable[i].name
                );
            list->AddItem(buffer);
        }
        list->SetOwner(this, this);
        list->SetKeyFocus();

    ribbonChunk = new RibbonChunk(buttonGroup, L"Iterations");

        list = new TextList(ribbonChunk, ControlIdIterations);
        list->SetPosition(MakePosition(0,0,100,100));
        for (size_t i = 0; i < ARRAY_SIZE(g_iterations); ++i)
        {
            wchar_t buffer[1024];
            StringCchPrintf(buffer, ARRAY_SIZE(buffer), L"%d", g_iterations[i]);
            list->AddItem(buffer);
            if (g_iterations[i] == iterations_)
                list->SetSelection(ListControl::SelectionSetModeAbsolute, i);
        }
        list->SetOwner(this, this);

    timerLabel_.Set( new Label(this, L"Cycles elapsed: (not run)") );
    timerLabel_->SetStyle(StyleFlagNewLine|StyleFlagWide);

    button = new Button(this, L"Run", nullptr, ControlIdRun);
    button->SetOwner(this, this);
    button->SetStyle(StyleFlagNewLine);
    button = new Button(this, L"Close", nullptr, ControlIdClose);
    button->SetOwner(this, this);
}


bool ProfilerWindow::Activated(Button* source, int id, int value)
{
    switch (id)
    {
    case ControlIdClose:
        if (parent_ != nullptr)
            parent_->DeleteChild(this);
        break;

    case ControlIdRun:
        RunTest();
        break;

    default:
        // No action defined
        return false;
    }

    return true;
}


bool ProfilerWindow::Activated(ListPopup* source, int id, size_t selectedItem)
{
    return false;
}


bool ProfilerWindow::Showing(ListPopup* source, int id)
{
    return false;
}


bool ProfilerWindow::Shown(ListPopup* source, int id)
{
    return false;
}


bool ProfilerWindow::SelectionChanged(ListControl* source, int id, size_t selectedItem)
{
    switch (id)
    {
    case ControlIdIterations:
        if (selectedItem < ARRAY_SIZE(g_iterations))
        {
            iterations_ = g_iterations[selectedItem];
        }
        return true;

    case ControlIdTests:
        if (selectedItem < ARRAY_SIZE(g_PerfTestsTable))
        {
            selectedTest_ = selectedItem;
        }
        return true;
    }

    return false;
}


bool ProfilerWindow::Activated(ListControl* source, int id, size_t selectedItem)
{
    switch (id)
    {
    case ControlIdIterations:
        if (selectedItem < ARRAY_SIZE(g_iterations))
        {
            iterations_ = g_iterations[selectedItem];
            RunTest();
        }
        return true;

    case ControlIdTests:
        if (selectedItem < ARRAY_SIZE(g_PerfTestsTable))
        {
            selectedTest_ = selectedItem;
            RunTest();
        }
        return true;
    }

    return false;
}


bool ProfilerWindow::Canceled(ListPopup* source, int id)
{
    return false;
}


bool ProfilerWindow::Draw(RenderTarget& target, const Position& rect)
{
    Base::Draw(target, rect);

    return true;
}


bool ProfilerWindow::KeyPress(KeyboardMessage& message)
{
    bool messageAcknowledged = Base::KeyPress(message);
    if (messageAcknowledged)
        return messageAcknowledged;

    switch (message.button)
    {
    case VK_ESCAPE:
        UiControlRefPtr keepAlive(this);
        if (parent_ != nullptr)
            parent_->DeleteChild(this);
        return true;
    }
    return messageAcknowledged;
}


void ProfilerWindow::RunTest()
{
    // Ignore selection on list groups.
    if (selectedTest_ >= ARRAY_SIZE(g_PerfTestsTable)
    || textLayout_ == nullptr
    ||  g_PerfTestsTable[selectedTest_].function == nullptr
        )
        return;

    // Reflect any UI state changes before beginning the profile
    UpdateWindow(hwnd_);

    // Reset time elapsed
    accumulatedCycleCount_ = 0;
    //SetThreadAffinityMask(GetCurrentProcess(), 1);

    timerLabel_->SetLabel(L"Profiling...");
    UpdateWindow(hwnd_);
    GdiFlush();

    (this->*g_PerfTestsTable[selectedTest_].function)();

    // Print new count.
    wchar_t buffer[1024];
    buffer[0] = 0;
    StringCchPrintf(
        buffer,
        ARRAY_SIZE(buffer),
        L"Cycles elapsed: %d million cycles (%s)",
        (UINT32)(accumulatedCycleCount_ / 1000000), // show megacycles
        g_PerfTestsTable[selectedTest_].name
        );
    timerLabel_->SetLabel(buffer);
    SetReflow();

    // Force redraw in case profiling overdrew the UI
    InvalidateRect(hwnd_, nullptr, FALSE);
}


// Start the timer
void ProfilerWindow::BeginProfile()
{
#if 0
    Sleep(0);
    QueryThreadCycleTime(threadHandle_, &lastCycleCount_);
#endif
}


// End the timer and print results
void ProfilerWindow::EndProfile()
{
#if 0
    ULONG64 cycleCount;
    QueryThreadCycleTime(threadHandle_, &cycleCount);
    accumulatedCycleCount_ += cycleCount - lastCycleCount_;
    lastCycleCount_ = cycleCount;
#endif
}


void ProfilerWindow::Dummy()
{

}


void ProfilerWindow::DrawLayoutDWrite()
{
    RECT clientRect = {0};
    GetClientRect(hwnd_, &clientRect);

    ComPtr<RenderTarget> renderTarget(new UiRenderTargetDW(GetDC(hwnd_), dwriteFactory_, clientRect));
    DrawLayoutToRenderTarget(*renderTarget);
}


void ProfilerWindow::DrawLayoutD2dHard()
{
#if 0
    if (d2dFactory_ == nullptr)
        return;

    RECT clientRect = {0};
    GetClientRect(hwnd_, &clientRect);

    ComPtr<RenderTarget> renderTarget(new UiRenderTargetD2D(d2dFactory_, dwriteFactory_, hwnd_, clientRect, UiRenderTargetD2D::ModeHardware));
    DrawLayoutToRenderTarget(*renderTarget);
#endif
}


void ProfilerWindow::DrawLayoutD2dSoft()
{                                 
#if 0
    if (d2dFactory_ == nullptr)
        return;

    RECT clientRect = {0};
    GetClientRect(hwnd_, &clientRect);

    ComPtr<RenderTarget> renderTarget(new UiRenderTargetD2D(d2dFactory_, dwriteFactory_, hwnd_, clientRect, UiRenderTargetD2D::ModeSoftware));
    DrawLayoutToRenderTarget(*renderTarget);
#endif
}


void ProfilerWindow::DrawLayoutGdi()
{
    RECT clientRect = {0};
    GetClientRect(hwnd_, &clientRect);

    ComPtr<RenderTarget> renderTarget(new UiRenderTargetGDI(GetDC(hwnd_), dwriteFactory_, clientRect));
    DrawLayoutToRenderTarget(*renderTarget);
}


void ProfilerWindow::DrawLayoutGdiPlus()
{
    RECT clientRect = {0};
    GetClientRect(hwnd_, &clientRect);

    ComPtr<RenderTarget> renderTarget(new UiRenderTargetGDIPlus(GetDC(hwnd_), dwriteFactory_, clientRect));
    DrawLayoutToRenderTarget(*renderTarget);
}


void ProfilerWindow::DrawLayoutNullDraw()
{
    RECT clientRect = {0};
    GetClientRect(hwnd_, &clientRect);

    ComPtr<RenderTarget> renderTarget(new UiRenderTargetNullDraw(GetDC(hwnd_), dwriteFactory_, clientRect));
    DrawLayoutToRenderTarget(*renderTarget);
}


void ProfilerWindow::DrawLayoutToRenderTarget(RenderTarget& renderTarget)
{
    DWRITE_TEXT_METRICS metrics;
    textLayout_->GetMetrics(&metrics);

    Position position = {0,0,textLayout_->GetMaxWidth(), textLayout_->GetMaxHeight()};

    // Initial render just to see something
    renderTarget.BeginDraw();
    renderTarget.Clear();
    renderTarget.DrawTextLayout(textLayout_, position);
    renderTarget.EndDraw();

    // Prepare to actually draw
    renderTarget.BeginDraw();
    renderTarget.Clear();

    // Only interested in rendering speed here, not the actual 'Present'ation.
    BeginProfile();
    for (unsigned int i = 0; i < iterations_; ++i)
    {
        renderTarget.DrawTextLayout(textLayout_, position);
    }
    renderTarget.Flush(); // ensure no queued batching (especially for hardware targets)
    EndProfile();

    renderTarget.EndDraw();
}


void ProfilerWindow::MeasureDWriteLayout()
{
    // Force any lazy evalution
    DWRITE_TEXT_METRICS metrics;
    textLayout_->GetMetrics(&metrics);
    float originalMaxWidth = textLayout_->GetMaxWidth();

    BeginProfile();
    for (unsigned int i = 0; i < iterations_; ++i)
    {
        // Invalidate the layout
        textLayout_->SetMaxWidth(originalMaxWidth+1);
        textLayout_->SetMaxWidth(originalMaxWidth);

        // Force relayout
        textLayout_->GetMetrics(&metrics);
    }
    EndProfile();

    textLayout_->SetMaxWidth(originalMaxWidth);
}


void ProfilerWindow::MeasureUserGdi()
{
    DrawTextUserGdi(true);
}


void ProfilerWindow::DrawTextUserGdi()
{
    DrawTextUserGdi(false);
}


void ProfilerWindow::DrawTextUserGdi(bool measureOnly)
{
    float size[4] = {0,0,textLayout_->GetMaxWidth(), textLayout_->GetMaxHeight()};
    RECT rect = {LONG(size[0]), LONG(size[1]), LONG(size[2]), LONG(size[3])};
    RECT clientRect = {0};
    GetClientRect(hwnd_, &clientRect);

    // Query layout and translate layout state into equivalent DrawText flags
    const wchar_t* text = textLayout_->GetText();
    int textLength      = textLayout_->GetTextLength();
    UINT drawTextFlags  = GetDrawTextFlags(textLayout_);
    drawTextFlags      |= (measureOnly) ? DT_CALCRECT : 0;

    // Setup DIB and device context
    UiRenderTargetGDI* renderTargetGdi = new UiRenderTargetGDI(GetDC(hwnd_), dwriteFactory_, clientRect);
    ComPtr<RenderTarget> renderTarget(renderTargetGdi);
    HDC hdc = renderTargetGdi->GetMemoryDC();
    SetBkMode(hdc, TRANSPARENT);
    HFONT originalFont = (HFONT)SelectObject(hdc, GetGdiFont(textLayout_));

    // Draw something initially so we see something
    renderTarget->BeginDraw();
    renderTarget->Clear();
    DrawText(hdc, text, textLength, &rect, drawTextFlags & ~DT_CALCRECT);
    renderTarget->EndDraw();
    GdiFlush();

    // Prepare to actually draw
    renderTarget->BeginDraw();
    renderTarget->Clear();

    BeginProfile();
    for (unsigned int i = 0; i < iterations_; ++i)
    {
        RECT rectOut(rect);
        DrawText(hdc, text, textLength, &rectOut, drawTextFlags);
    }
    EndProfile();

    DeleteObject(SelectObject(hdc, originalFont));

    renderTarget->EndDraw();
}


void ProfilerWindow::DrawTextGdiPlus()
{
    DrawTextGdiPlus(false);
}


void ProfilerWindow::MeasureGdiPlus()
{
    DrawTextGdiPlus(true);
}


void ProfilerWindow::DrawTextGdiPlus(bool measureOnly)
{
    HDC hdc = GetDC(hwnd_);

    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    ULONG_PTR gdiplusToken;
    Gdiplus::GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, nullptr);

    {
        Gdiplus::Graphics       graphics(hdc);
        Gdiplus::Color          gdiplusColor = Gdiplus::Color(Gdiplus::ARGB(0xFF000000));
        Gdiplus::SolidBrush     solidBrush(gdiplusColor);
        Gdiplus::StringFormat   stringFormat(Gdiplus::StringFormat::GenericTypographic());
        ModifyGdiPlusStringFormat(textLayout_, stringFormat);

        Gdiplus::RectF rectF = Gdiplus::RectF(0,0,textLayout_->GetMaxWidth(), textLayout_->GetMaxHeight());

        const wchar_t* text = textLayout_->GetText();
        int textLength = textLayout_->GetTextLength();

        Gdiplus::Font* font = GetGdiPlusFont(textLayout_);

        BeginProfile();
        if (measureOnly)
        {
            for (unsigned int i = 0; i < iterations_; ++i)
            {
                Gdiplus::RectF rectOut(rectF);

                graphics.MeasureString(text, textLength, font, rectF, &stringFormat, &rectOut);
            }
        }
        else
        {
            for (unsigned int i = 0; i < iterations_; ++i)
            {
                graphics.DrawString(text, textLength, font, rectF, &stringFormat, &solidBrush);
            }
        }
        EndProfile();

        delete font;
    }

    Gdiplus::GdiplusShutdown(gdiplusToken);

    ReleaseDC(hwnd_, hdc);
}


void ProfilerWindow::AnalyzeScript()
{
    TextAnalysisSourceSink sourceSink(dwriteFactory_, textLayout_);

    BeginProfile();
    for (unsigned int i = 0; i < iterations_; ++i)
    {
        sourceSink.GetTextAnalyzer().AnalyzeScript(&sourceSink, 0, textLayout_->GetTextLength(), &sourceSink);
    }
    EndProfile();
}


void ProfilerWindow::AnalyzeBidi()
{
    TextAnalysisSourceSink sourceSink(dwriteFactory_, textLayout_);

    BeginProfile();
    for (unsigned int i = 0; i < iterations_; ++i)
    {
        sourceSink.GetTextAnalyzer().AnalyzeBidi(&sourceSink, 0, textLayout_->GetTextLength(), &sourceSink);
    }
    EndProfile();
}


void ProfilerWindow::AnalyzeLineBreakpoints()
{
    TextAnalysisSourceSink sourceSink(dwriteFactory_, textLayout_);

    BeginProfile();
    for (unsigned int i = 0; i < iterations_; ++i)
    {
        sourceSink.GetTextAnalyzer().AnalyzeLineBreakpoints(&sourceSink, 0, textLayout_->GetTextLength(), &sourceSink);
    }
    EndProfile();
}


void ProfilerWindow::AnalyzeNumberSubstitution()
{
    TextAnalysisSourceSink sourceSink(dwriteFactory_, textLayout_);

    BeginProfile();
    for (unsigned int i = 0; i < iterations_; ++i)
    {
        sourceSink.GetTextAnalyzer().AnalyzeNumberSubstitution(&sourceSink, 0, textLayout_->GetTextLength(), &sourceSink);
    }
    EndProfile();
}


void ProfilerWindow::ScriptItemize()
{
    TextAnalysisSourceSink sourceSink(dwriteFactory_, textLayout_);

    SCRIPT_CONTROL scriptControl;
    SCRIPT_STATE scriptState;
    GetUniscribeControlState(sourceSink, scriptControl, scriptState);

    const wchar_t* text = textLayout_->GetText();
    int textLength      = textLayout_->GetTextLength();
    UINT32 maxItems     = textLength + 2;

    // Uniscribe recommendation: # items should be at least [maxItems * sizeof(SCRIPT_ITEM) + 1] bytes
    // and ScriptItemizeOpenType() must be called with a buffer of at least 2 items, i.e., maxItems >= 2
    std::vector<SCRIPT_ITEM> scriptItems(maxItems + 1);
    int actualScriptItems = 0;

    BeginProfile();
    for (unsigned int i = 0; i < iterations_; ++i)
    {
        HRESULT hr = ::ScriptItemize(
                        text,               // const WCHAR*
                        textLength,         // int
                        maxItems,           // int
                        &scriptControl,     // const SCRIPT_CONTROL*
                        &scriptState,       // const SCRIPT_STATE*
                        &scriptItems[0],    // SCRIPT_ITEM*
                        //&scriptTags[0],   // OPENTYPE_TAG*
                        &actualScriptItems  // int*
                        );
        if (FAILED(hr))
            break;
    }
    EndProfile();
}

void ProfilerWindow::ScriptBreak()
{
    TextAnalysisSourceSink sourceSink(dwriteFactory_, textLayout_);

    SCRIPT_CONTROL scriptControl;
    SCRIPT_STATE scriptState;
    GetUniscribeControlState(sourceSink, scriptControl, scriptState);

    const wchar_t* text = textLayout_->GetText();
    int textLength      = textLayout_->GetTextLength();
    UINT32 maxItems     = textLength + 2;       // Uniscribe recommendation

    std::vector<SCRIPT_ITEM> scriptItems(maxItems + 1);
    int actualScriptItems = 0;

    HRESULT hr = ::ScriptItemize(
                    text,               // const WCHAR*
                    textLength,         // int
                    maxItems,           // int
                    &scriptControl,     // const SCRIPT_CONTROL*
                    &scriptState,       // const SCRIPT_STATE*
                    &scriptItems[0],    // SCRIPT_ITEM*
                    //&scriptTags[0],   // OPENTYPE_TAG*
                    &actualScriptItems  // int*
                    );
    if (hr != S_OK || actualScriptItems < 1)
        return;

    std::vector<SCRIPT_LOGATTR> scriptBreaks(textLength + 1);

    BeginProfile();
    for (unsigned int i = 0; i < iterations_; ++i)
    {
        hr = ::ScriptBreak(
                text,               // const WCHAR*
                textLength,         // int
                &scriptItems[0].a,
                &scriptBreaks[0]
                );
        if (FAILED(hr))
            break;
    }
    EndProfile();
}

void ProfilerWindow::ScriptShape()
{
}

void ProfilerWindow::ScriptPlace()
{
}
