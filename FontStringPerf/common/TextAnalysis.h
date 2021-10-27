// <SnippetTextAnalysish>
// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// Copyright (c) Microsoft Corporation. All rights reserved
//
// Contents:    Implementation of text analyzer source and sink.
//
//----------------------------------------------------------------------------
#pragma once


/// <summary>
/// Direction for how reading progresses.
/// </summary>
enum ReadingDirection
{
    //  0 RD    1 LD    2 RU    3 LU    4 DR    5 UR    6 DL    7 UL
    //  ---/    \---    \-->    <--/   |   /|  |\  /\  |\   |  /\  /|
    //    /      \       \        /    |  / |  | \  |  | \  |  |  / |
    //   /        \       \      /     | /  |  |  \ |  |  \ |  | /  |
    //  /-->    <--\    ---\    /---   |/  \/  |   \|  \/  \|  |/   |
    //  Latin  Hebrew    ?        ?  Mongolian Hanunó Japanese   *
    //
    // 0. Latin, Greek, Cyrillic
    // 1. Arabic, Hebrew
    // 2. (no supported scripts)
    // 3. (no supported scripts)
    // 4. Mongolian, Orkhon, Egyptian heiroglyphs, Latin CW90
    // 5. Ogham, Hanunó and Latin CW270
    // 6. Chinese, Japanese, Egyptian heiroglyphs, Latin CW90, Korean
    // 7. RTL scripts in vertical context
    //
    ReadingDirectionLeftToRightTopToBottom = 0,
    ReadingDirectionRightToLeftTopToBottom = 1,
    ReadingDirectionLeftToRightBottomToTop = 2,
    ReadingDirectionRightToLeftBottomToTop = 3,
    ReadingDirectionTopToBottomLeftToRight = 4,
    ReadingDirectionBottomToTopLeftToRight = 5,
    ReadingDirectionTopToBottomRightToLeft = 6,
    ReadingDirectionBottomToTopRightToLeft = 7,

    ReadingDirectionTotal,

    // Shorter Aliases (RD means rightward then down, like Latin)
    ReadingDirectionRD                     = ReadingDirectionLeftToRightTopToBottom,
    ReadingDirectionLD                     = ReadingDirectionRightToLeftTopToBottom,
    ReadingDirectionRU                     = ReadingDirectionLeftToRightBottomToTop,
    ReadingDirectionLU                     = ReadingDirectionRightToLeftBottomToTop,
    ReadingDirectionDR                     = ReadingDirectionTopToBottomLeftToRight,
    ReadingDirectionUR                     = ReadingDirectionBottomToTopLeftToRight,
    ReadingDirectionDL                     = ReadingDirectionTopToBottomRightToLeft,
    ReadingDirectionUL                     = ReadingDirectionBottomToTopRightToLeft,

    // Contributing bits
    ReadingDirectionPrimaryProgression     = 1, // False=Ltr/Ttb,    True=Rtl/Btt
    ReadingDirectionSecondaryProgression   = 2, // False=Ttb/Ltr,    True=Btt/Rtl
    ReadingDirectionPrimaryAxis            = 4, // False=Horizontal, True=Vertical

    ReadingDirectionUndefined              = 0x80,
};


/// <summary>
/// Direction for how reading progresses.
/// </summary>
enum GlyphOrientation
{
    //    0 RD      1 LD      2 RU      3 LU       4 DR        5 UR        6 DL        7 UL
    //  888888      888888  88    88  88    88  8888888888    88    88  8888888888  88    88
    //  88    88  88    88  88   88    88   88  88  88      88  8888        88  88    8888  88
    //  888888      888888  888888      888888  88  8888    88  88        8888  88      88  88
    //  88   88    88   88  88    88  88    88    88    88  8888888888  88    88    8888888888
    //  88    88  88    88  888888      888888
    //
    GlyphOrientationLeftToRightTopToBottom  = 0,
    GlyphOrientationRightToLeftTopToBottom  = 1,
    GlyphOrientationLeftToRightBottomToTop  = 2,
    GlyphOrientationRightToLeftBottomToTop  = 3,
    GlyphOrientationTopToBottomLeftToRight  = 4,
    GlyphOrientationBottomToTopLeftToRight  = 5,
    GlyphOrientationTopToBottomRightToLeft  = 6,
    GlyphOrientationBottomToTopRightToLeft  = 7,

    GlyphOrientationTotal,

    // Shorter aliases (RD means x coordinate points rightward, y gravity down)
    GlyphOrientationCW0                     = GlyphOrientationLeftToRightTopToBottom,
    GlyphOrientationCW90                    = GlyphOrientationTopToBottomRightToLeft,
    GlyphOrientationCW180                   = GlyphOrientationRightToLeftBottomToTop,
    GlyphOrientationCW270                   = GlyphOrientationBottomToTopLeftToRight,
    GlyphOrientationRD                      = GlyphOrientationLeftToRightTopToBottom,
    GlyphOrientationLD                      = GlyphOrientationRightToLeftTopToBottom,
    GlyphOrientationRU                      = GlyphOrientationLeftToRightBottomToTop,
    GlyphOrientationLU                      = GlyphOrientationRightToLeftBottomToTop,
    GlyphOrientationDR                      = GlyphOrientationTopToBottomLeftToRight,
    GlyphOrientationUR                      = GlyphOrientationBottomToTopLeftToRight,
    GlyphOrientationDL                      = GlyphOrientationTopToBottomRightToLeft,
    GlyphOrientationUL                      = GlyphOrientationBottomToTopRightToLeft,

    // Individual bits
    GlyphOrientationFlipHorizontal          = 1,  // Glyph Mirrored Horizontally  (Left <-> Right)
    GlyphOrientationFlipVertical            = 2,  // Glyph Mirrored Vertically (Top <-> Bottom)
    GlyphOrientationFlipDiagonal            = 4,  // Glyph Transposed Around Diagonal

    GlyphOrientationUndefined               = 0x80,
};


enum GlyphOrientationMode
{
    GlyphOrientationModeDefault,    // rotated or upright according to script default
    GlyphOrientationModeStacked,    // stacked if script allows it
    GlyphOrientationModeRotated,    // all glyphs are rotated regardless
    GlyphOrientationModeUpright,    // all glyphs are upright regardless

    // Explicit orientations
    GlyphOrientationModeLeftToRightTopToBottom,
    GlyphOrientationModeRightToLeftTopToBottom,
    GlyphOrientationModeLeftToRightBottomToTop,
    GlyphOrientationModeRightToLeftBottomToTop,
    GlyphOrientationModeTopToBottomLeftToRight,
    GlyphOrientationModeBottomToTopLeftToRight,
    GlyphOrientationModeTopToBottomRightToLeft,
    GlyphOrientationModeBottomToTopRightToLeft,

    GlyphOrientationModeTotal,

    GlyphOrientationModeCW0                    = GlyphOrientationModeLeftToRightTopToBottom,
    GlyphOrientationModeCW90                   = GlyphOrientationModeTopToBottomRightToLeft,
    GlyphOrientationModeCW180                  = GlyphOrientationModeRightToLeftBottomToTop,
    GlyphOrientationModeCW270                  = GlyphOrientationModeBottomToTopLeftToRight,
    GlyphOrientationModeExplicitFirst          = GlyphOrientationModeLeftToRightTopToBottom,
    GlyphOrientationModeExplicitLast           = GlyphOrientationModeBottomToTopRightToLeft,

    GlyphOrientationModeUndefined              = 0x80,
};


class TextAnalysisBase :
    #ifdef GLYPH_ORIENTATION_IS_SUPPORTED
        public IDWriteTextAnalysisSource1, public IDWriteTextAnalysisSink1
    #else
        public IDWriteTextAnalysisSource, public IDWriteTextAnalysisSink
    #endif
{ };


class FontSelection;


// Helper source/sink class for text analysis.
class TextAnalysis
:   public ComBase<TextAnalysisBase>
{
public:
    // A single contiguous run of characters containing the same analysis results.
    struct Run
    {
        Run() throw()
        :   textStart(),
            textLength(),
            glyphStart(),
            glyphCount(),
            bidiLevel(),
            script(),
            glyphOrientation(),
            isNumberSubstituted(),
            isSideways(),
            isReversed()
        { }

        uint32_t textStart;             // starting text position of this run
        uint32_t textLength;            // number of contiguous code units covered
        uint32_t glyphStart;            // starting glyph in the glyphs array
        uint32_t glyphCount;            // number of glyphs associated with this run of text
        DWRITE_SCRIPT_ANALYSIS script;
        uint8_t bidiLevel;
        uint8_t glyphOrientation;
        bool isNumberSubstituted;
        bool isSideways;
        bool isReversed;                // reversed along primary axis (LTR->RTL, TTB->BTT)
        ComPtr<IDWriteFontFace> fontFace;

        inline bool ContainsTextPosition(uint32_t desiredTextPosition) const throw()
        {
            return (desiredTextPosition == textStart)
                || (desiredTextPosition >= textStart && desiredTextPosition < textStart + textLength);
        }

        inline bool operator==(uint32_t desiredTextPosition) const throw()
        {
            // Allows search by text position using std::find
            return ContainsTextPosition(desiredTextPosition);
        }
    };

    // Single text analysis run, which points to the next run.
    struct LinkedRun : Run
    {
        LinkedRun() throw()
        :   nextRunIndex(0)
        { }

        uint32_t nextRunIndex;  // index of next run
    };

    struct PointF
    {
        float x;
        float y;
    };

public:
    TextAnalysis(
        const wchar_t* text, // weak ref
        uint32_t textLength,
        const wchar_t* localeName, // weak ref
        IDWriteNumberSubstitution* numberSubstitution, // weak ref
        ReadingDirection readingDirection,
        GlyphOrientationMode glyphOrientationMode,
        FontSelection const* fontSelection, // weak ref
        IDWriteFontCollection* fontCollection, // weak ref
        IDWriteFontFace* fontFace // weak ref
        );

    void SetText(
        const wchar_t* text, // weak ref
        uint32_t textLength
        ) throw();

    void ResetResultsInternal();

    STDMETHODIMP ResetResults();

    STDMETHODIMP GenerateResults(
        IDWriteTextAnalyzer* textAnalyzer,
        IN OUT std::vector<LinkedRun>& runs,
        OUT std::vector<DWRITE_LINE_BREAKPOINT>& breakpoints_
        ) throw();

    STDMETHODIMP GenerateSimpleOrientationResults(
        IDWriteTextAnalyzer* textAnalyzer,
        IN OUT LinkedRun& run
        ) throw();

    #ifdef GLYPH_ORIENTATION_IS_SUPPORTED
    STDMETHODIMP AnalyzeGlyphOrientation(
        IDWriteTextAnalyzer1* textAnalyzer,
        IDWriteTextAnalysisSource1* analysisSource,
        uint32_t textPosition,
        uint32_t textLength,
        IDWriteTextAnalysisSink1* analysisSink
        ) throw();
    #endif

    STDMETHODIMP AnalyzeFonts(
        uint32_t firstPosition,
        uint32_t textLength
        ) throw();

    // IDWriteTextAnalysisSource implementation

    IFACEMETHODIMP GetTextAtPosition(
        uint32_t textPosition,
        OUT WCHAR const** textString,
        OUT uint32_t* textLength
        ) throw();

    IFACEMETHODIMP GetTextBeforePosition(
        uint32_t textPosition,
        OUT WCHAR const** textString,
        OUT uint32_t* textLength
        ) throw();

    IFACEMETHODIMP_(DWRITE_READING_DIRECTION) GetParagraphReadingDirection() throw();

    IFACEMETHODIMP GetLocaleName(
        uint32_t textPosition,
        OUT uint32_t* textLength,
        OUT WCHAR const** localeName
        ) throw();

    IFACEMETHODIMP GetNumberSubstitution(
        uint32_t textPosition,
        OUT uint32_t* textLength,
        OUT IDWriteNumberSubstitution** numberSubstitution
        ) throw();

    #ifdef GLYPH_ORIENTATION_IS_SUPPORTED
    IFACEMETHODIMP GetVerticalGlyphOrientation(
        uint32_t textPosition,
        OUT uint32_t* textLength,
        OUT DWRITE_VERTICAL_GLYPH_ORIENTATION* glyphOrientation,
        OUT uint8_t* bidiLevel
        ) throw();
    #endif

    // IDWriteTextAnalysisSink implementation

    IFACEMETHODIMP SetScriptAnalysis(
        uint32_t textPosition,
        uint32_t textLength,
        const DWRITE_SCRIPT_ANALYSIS* scriptAnalysis
        ) throw();

    IFACEMETHODIMP SetLineBreakpoints(
        uint32_t textPosition,
        uint32_t textLength,
        const DWRITE_LINE_BREAKPOINT* lineBreakpoints // [textLength]
        ) throw();

    IFACEMETHODIMP SetBidiLevel(
        uint32_t textPosition,
        uint32_t textLength,
        uint8_t explicitLevel,
        uint8_t resolvedLevel
        ) throw();

    IFACEMETHODIMP SetNumberSubstitution(
        uint32_t textPosition,
        uint32_t textLength,
        IDWriteNumberSubstitution* numberSubstitution
        ) throw();

    #ifdef GLYPH_ORIENTATION_IS_SUPPORTED
    IFACEMETHODIMP SetGlyphOrientation(
        uint32_t textPosition,
        uint32_t textLength,
        DWRITE_GLYPH_ORIENTATION_ANGLE glyphOrientationAngle,
        uint8_t adjustedBidiLevel,
        BOOL isSideways,
        BOOL isRightToLeft
        ) throw();
    #endif

public:
    // Helpers
    static GlyphOrientation UndoSidewaysOrientation(GlyphOrientation glyphOrientation);

    static void GetGlyphOrientationFlags(
        ReadingDirection readingDirection,
        GlyphOrientation glyphOrientation,
        OUT bool* isSideways,
        OUT bool* isReversed
        );

    static bool RequiresVerticalGlyphVariants(
        GlyphOrientationMode glyphOrientationMode,
        bool isSideways
        );

    static bool HasVerticalBaseline(
        GlyphOrientation glyphOrientation,
        bool isSideways
        );

    static GlyphOrientationMode Resolve(
        GlyphOrientationMode glyphOrientationMode,
        GlyphOrientationMode defaultGlyphOrientationMode
        );

    static PointF GetGlyphOrigin(
        const Run& run,
        float midline,
        float ascent,
        float descent,
        float runWidth
        );

protected:
    IFACEMETHODIMP QueryInterface(IID const& iid, __out void** object) OVERRIDE;

    //IFACEMETHODIMP_(unsigned long) AddRef();
    //
    //IFACEMETHODIMP_(unsigned long) Release();


protected:
    class RunEqualityComparer
    {
    public:
        virtual bool Equals(const LinkedRun& firstRun, const LinkedRun& secondRun) = 0;
    };

    // Internal helpers
protected:
    LinkedRun& FetchNextRun(IN OUT uint32_t* textLength);

    void SetCurrentRun(uint32_t textPosition);

    void SplitCurrentRun(uint32_t splitPosition);

    uint32_t GetContiguousRunLength(
        uint32_t textLength,
        RunEqualityComparer& equalityComparer
        );

public: // public for read-only
    // Input
    // (weak references are fine here, since this class is a transient
    //  stack-based helper)
    const wchar_t* text_; // [textLength_]
    const wchar_t* localeName_;
    uint32_t textLength_;
    IDWriteNumberSubstitution* numberSubstitution_;
    ReadingDirection readingDirection_;
    GlyphOrientationMode glyphOrientationMode_;
    FontSelection const* fontSelection_;
    IDWriteFontCollection* fontCollection_;
    IDWriteFontFace* fontFace_;

    // Current processing state
    uint32_t currentRunIndex_;

    // Output
    std::vector<LinkedRun> runs_;
    std::vector<DWRITE_LINE_BREAKPOINT> breakpoints_;
};
// </SnippetTextAnalysish>
