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

/*
// Orientation of the glyph, which will match the reading direction for pure
// rotation of LTR, be opposite but parallel for RTL, and be perpendicular
// for cursive scripts in vertical context.
enum DWRITEX_GLYPH_ORIENTATION
{
    DWRITEX_GLYPH_ORIENTATION_UP,   // Upright
    DWRITEX_GLYPH_ORIENTATION_UH,   // Horizontally mirrored (left <-> right)
    DWRITEX_GLYPH_ORIENTATION_UV,   // Vertically mirrored (top <-> bottom)
    DWRITEX_GLYPH_ORIENTATION_UVH,  // Horizontal and vertically mirrored / rotated 180 upside down
    DWRITEX_GLYPH_ORIENTATION_SW,   // Rotated counterclockwise, or sideways (270)
    DWRITEX_GLYPH_ORIENTATION_SH,   // Counterclockwise, horizontally mirrored (flip along main diagonal)
    DWRITEX_GLYPH_ORIENTATION_SV,   // Counterclockwise, vertically mirrored   (flip along perpendicular diagonal)
    DWRITEX_GLYPH_ORIENTATION_SVH,  // Rotated clockwise (90)

    DWRITEX_GLYPH_ORIENTATION_FLIP_H    = 0x1,
    DWRITEX_GLYPH_ORIENTATION_FLIP_V    = 0x2,
    DWRITEX_GLYPH_ORIENTATION_FLIP_VH   = 0x3,
    DWRITEX_GLYPH_ORIENTATION_SIDEWAYS  = 0x4,

    // Aliases for clockwise and counterclockwise
    DWRITEX_GLYPH_ORIENTATION_CW  = DWRITEX_GLYPH_ORIENTATION_SVH,
    DWRITEX_GLYPH_ORIENTATION_CCW = DWRITEX_GLYPH_ORIENTATION_SW,
};
*/


/// <summary>
/// Direction for how reading progresses.
/// </summary>
enum DWRITEX_READING_DIRECTION
{
    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_READING_DIRECTION_LEFT_TO_RIGHT_TOP_TO_BOTTOM = 0,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_READING_DIRECTION_RIGHT_TO_LEFT_TOP_TO_BOTTOM = 1,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_READING_DIRECTION_LEFT_TO_RIGHT_BOTTOM_TO_TOP = 2,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_READING_DIRECTION_RIGHT_TO_LEFT_BOTTOM_TO_TOP = 3,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_READING_DIRECTION_TOP_TO_BOTTOM_LEFT_TO_RIGHT = 4,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_READING_DIRECTION_BOTTOM_TO_TOP_LEFT_TO_RIGHT = 5,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_READING_DIRECTION_TOP_TO_BOTTOM_RIGHT_TO_LEFT = 6,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_READING_DIRECTION_BOTTOM_TO_TOP_RIGHT_TO_LEFT = 7,

    // Private bits
    DWRITEX_READING_DIRECTION_CHARACTER_PROGRESSION       = 1, // false=LTR/TTB,    true=RTL/BTT
    DWRITEX_READING_DIRECTION_LINE_PROGRESSION            = 2, // false=TTB/LTR,    true=BTT/RTL
    DWRITEX_READING_DIRECTION_CHARACTER_AXIS              = 4, // false=horizontal, true=vertical

    // Internal shorter aliases
    DWRITEX_READING_DIRECTION_ES = DWRITEX_READING_DIRECTION_LEFT_TO_RIGHT_TOP_TO_BOTTOM,
    DWRITEX_READING_DIRECTION_SW = DWRITEX_READING_DIRECTION_TOP_TO_BOTTOM_RIGHT_TO_LEFT,
    DWRITEX_READING_DIRECTION_WN = DWRITEX_READING_DIRECTION_RIGHT_TO_LEFT_BOTTOM_TO_TOP,
    DWRITEX_READING_DIRECTION_NE = DWRITEX_READING_DIRECTION_BOTTOM_TO_TOP_LEFT_TO_RIGHT,

    // Just a single direction (ignoring line progression)
    DWRITEX_READING_DIRECTION_E = DWRITEX_READING_DIRECTION_LEFT_TO_RIGHT_TOP_TO_BOTTOM,
    DWRITEX_READING_DIRECTION_S = DWRITEX_READING_DIRECTION_TOP_TO_BOTTOM_LEFT_TO_RIGHT,
    DWRITEX_READING_DIRECTION_W = DWRITEX_READING_DIRECTION_RIGHT_TO_LEFT_TOP_TO_BOTTOM,
    DWRITEX_READING_DIRECTION_N = DWRITEX_READING_DIRECTION_BOTTOM_TO_TOP_LEFT_TO_RIGHT,
};


enum DWRITEX_ORIENTATION_MODE
{
    // Orientation depends solely on reading direction.
    DWRITEX_ORIENTATION_MODE_DEFAULT,

    // Orientation adjusts as needed to match reading direction.
    // Latin in forced RTL is mirrored.
    // Rongo Rongo and Mongolian in forced RTL are rotated 180.
    DWRITEX_ORIENTATION_MODE_READING_DIRECTION,

    // Orientation adjusts as needed to match reading direction.
    DWRITEX_ORIENTATION_MODE_PARAGRAPH_READING_DIRECTION,

    // Stacks those characters which can be stacked (in vertical, nop in horizontal).
    DWRITEX_ORIENTATION_MODE_STACKED,
};


/*
enum DWRITEX_READING_DIRECTION
{
    // Masks
    DWRITEX_READING_DIRECTION_REVERSE   = 0x01, // Reading direction is opposite sign (RTL or BTT)
    DWRITEX_READING_DIRECTION_HORIZONTAL= 0x00, // Reading direction is LTR or RTL
    DWRITEX_READING_DIRECTION_VERTICAL  = 0x02, // Reading direction is TTB or BTT
    DWRITEX_READING_DIRECTION_FLIP_H    = 0x04, // Glyph mirrored horizontally  (left <-> right)
    DWRITEX_READING_DIRECTION_FLIP_V    = 0x08, // Glyph mirrored vertically (top <-> bottom)
    DWRITEX_READING_DIRECTION_UPRIGHT   = 0x00, // Glyph has upright default orientation
    DWRITEX_READING_DIRECTION_SIDEWAYS  = 0x10, // Glyph rotated counterclockwise / sideways (270)

    // Aliases
    DWRITEX_READING_DIRECTION_FLIP_VH   = DWRITEX_READING_DIRECTION_FLIP_H     | DWRITEX_READING_DIRECTION_FLIP_V,
    DWRITEX_READING_DIRECTION_CCW       = DWRITEX_READING_DIRECTION_SIDEWAYS,
    DWRITEX_READING_DIRECTION_CW        = DWRITEX_READING_DIRECTION_SIDEWAYS   | DWRITEX_READING_DIRECTION_FLIP_VH,
    DWRITEX_READING_DIRECTION_LTR       = DWRITEX_READING_DIRECTION_HORIZONTAL,
    DWRITEX_READING_DIRECTION_RTL       = DWRITEX_READING_DIRECTION_HORIZONTAL | DWRITEX_READING_DIRECTION_REVERSE,
    DWRITEX_READING_DIRECTION_TTB       = DWRITEX_READING_DIRECTION_VERTICAL,
    DWRITEX_READING_DIRECTION_BTT       = DWRITEX_READING_DIRECTION_VERTICAL   | DWRITEX_READING_DIRECTION_REVERSE, 

    // Common language reading directions/orientations

    // Latin, Cyrillic, Greek, CJK when horizontal
    DWRITEX_READING_DIRECTION_LTR_UPRIGHT   = DWRITEX_READING_DIRECTION_LTR | DWRITEX_READING_DIRECTION_UPRIGHT,

    // Arabic, Hebrew, Syriac
    DWRITEX_READING_DIRECTION_RTL_UPRIGHT   = DWRITEX_READING_DIRECTION_RTL | DWRITEX_READING_DIRECTION_UPRIGHT,

    // Egyptian hieroglyphics in RTL
    DWRITEX_READING_DIRECTION_RTL_FLIP_H    = DWRITEX_READING_DIRECTION_RTL | DWRITEX_READING_DIRECTION_FLIP_H,

    // Japanese, Chinese, Korean, short Latin acronyms in vertical context
    DWRITEX_READING_DIRECTION_TTB_UPRIGHT   = DWRITEX_READING_DIRECTION_TTB | DWRITEX_READING_DIRECTION_UPRIGHT,

    // Egyptian hieroglyphics in TTB character flow, RTL line flow
    DWRITEX_READING_DIRECTION_TTB_FLIP_H    = DWRITEX_READING_DIRECTION_TTB | DWRITEX_READING_DIRECTION_FLIP_H,

    // Long rotated Latin words in CJK vertical context, traditional Mongolian
    DWRITEX_READING_DIRECTION_TTB_CW        = DWRITEX_READING_DIRECTION_TTB | DWRITEX_READING_DIRECTION_CW,

    // Alternate Arabic orientation in CJK vertical context (such that mixed Latin and Arabic both proceed downward)
    DWRITEX_READING_DIRECTION_TTB_CCW       = DWRITEX_READING_DIRECTION_TTB | DWRITEX_READING_DIRECTION_CCW,

    // Arabic in CJK vertical context
    DWRITEX_READING_DIRECTION_BTT_CW        = DWRITEX_READING_DIRECTION_BTT | DWRITEX_READING_DIRECTION_CW,

    // Oghma, Latin in a ledger entry on left side
    DWRITEX_READING_DIRECTION_BTT_CCW       = DWRITEX_READING_DIRECTION_BTT | DWRITEX_READING_DIRECTION_CCW,

    // Arrows that preserve orientation
    DWRITEX_READING_DIRECTION_BTT_UPRIGHT   = DWRITEX_READING_DIRECTION_BTT | DWRITEX_READING_DIRECTION_UPRIGHT,

    DWRITEX_READING_DIRECTION_FORCE_DWORD = 0xFFFFFFFF
};
*/


/// <summary>
/// Direction for how reading progresses.
/// </summary>
enum DWRITEX_GLYPH_ORIENTATION
{
    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_GLYPH_ORIENTATION_LEFT_TO_RIGHT_TOP_TO_BOTTOM = 0,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_GLYPH_ORIENTATION_RIGHT_TO_LEFT_TOP_TO_BOTTOM = 1,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_GLYPH_ORIENTATION_LEFT_TO_RIGHT_BOTTOM_TO_TOP = 2,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_GLYPH_ORIENTATION_RIGHT_TO_LEFT_BOTTOM_TO_TOP = 3,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_GLYPH_ORIENTATION_TOP_TO_BOTTOM_LEFT_TO_RIGHT = 4,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_GLYPH_ORIENTATION_BOTTOM_TO_TOP_LEFT_TO_RIGHT = 5,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_GLYPH_ORIENTATION_TOP_TO_BOTTOM_RIGHT_TO_LEFT = 6,

    /// <summary>
    /// ...
    /// </summary>
    DWRITEX_GLYPH_ORIENTATION_BOTTOM_TO_TOP_RIGHT_TO_LEFT = 7,

    // Rotational aliases.
    DWRITEX_GLYPH_ORIENTATION_0DEGREES   = DWRITEX_GLYPH_ORIENTATION_LEFT_TO_RIGHT_TOP_TO_BOTTOM,
    DWRITEX_GLYPH_ORIENTATION_90DEGREES  = DWRITEX_GLYPH_ORIENTATION_TOP_TO_BOTTOM_RIGHT_TO_LEFT,
    DWRITEX_GLYPH_ORIENTATION_180DEGREES = DWRITEX_GLYPH_ORIENTATION_RIGHT_TO_LEFT_BOTTOM_TO_TOP,
    DWRITEX_GLYPH_ORIENTATION_270DEGREES = DWRITEX_GLYPH_ORIENTATION_BOTTOM_TO_TOP_LEFT_TO_RIGHT,

    // Internal shorter aliases
    DWRITEX_GLYPH_ORIENTATION_ES    = DWRITEX_GLYPH_ORIENTATION_LEFT_TO_RIGHT_TOP_TO_BOTTOM,
    DWRITEX_GLYPH_ORIENTATION_SW    = DWRITEX_GLYPH_ORIENTATION_TOP_TO_BOTTOM_RIGHT_TO_LEFT,
    DWRITEX_GLYPH_ORIENTATION_WN    = DWRITEX_GLYPH_ORIENTATION_RIGHT_TO_LEFT_BOTTOM_TO_TOP,
    DWRITEX_GLYPH_ORIENTATION_NE    = DWRITEX_GLYPH_ORIENTATION_BOTTOM_TO_TOP_LEFT_TO_RIGHT,
    DWRITEX_GLYPH_ORIENTATION_CW0   = DWRITEX_GLYPH_ORIENTATION_LEFT_TO_RIGHT_TOP_TO_BOTTOM,
    DWRITEX_GLYPH_ORIENTATION_CW90  = DWRITEX_GLYPH_ORIENTATION_TOP_TO_BOTTOM_RIGHT_TO_LEFT,
    DWRITEX_GLYPH_ORIENTATION_CW180 = DWRITEX_GLYPH_ORIENTATION_RIGHT_TO_LEFT_BOTTOM_TO_TOP,
    DWRITEX_GLYPH_ORIENTATION_CW270 = DWRITEX_GLYPH_ORIENTATION_BOTTOM_TO_TOP_LEFT_TO_RIGHT,
    DWRITEX_GLYPH_ORIENTATION_FH    = DWRITEX_GLYPH_ORIENTATION_RIGHT_TO_LEFT_TOP_TO_BOTTOM,
    DWRITEX_GLYPH_ORIENTATION_FV    = DWRITEX_GLYPH_ORIENTATION_LEFT_TO_RIGHT_BOTTOM_TO_TOP,

    // Internal private bits
    DWRITEX_GLYPH_ORIENTATION_FLIP_HORIZONTAL = 1,  // Glyph mirrored horizontally  (left <-> right)
    DWRITEX_GLYPH_ORIENTATION_FLIP_VERTICAL   = 2,  // Glyph mirrored vertically (top <-> bottom)
    DWRITEX_GLYPH_ORIENTATION_FLIP_DIAGONAL   = 4,  // Glyph transposed around diagonal

    //  ---/    \---    \-->    <--/   |   /|  |\  /\  /\  /|  |\  /\
    //    /      \       \        /    |  / |  | \  |  |  / |  | \  |
    //   /        \       \      /     | /  |  |  \ |  | /  |  |  \ |
    //  /-->    <--\    ---\    /---   |/  \/  |   \|  |/   |  |   \|
    //
    //
    //  XXXX     XXXX   X   X   X   X  XXXXXX   XX  X  X  XX    XX  X
    //  X   X   X   X   X   X   X   X  X  X    X  XX    XX  X  X  XX
    //  XXXX     XXXX   XXXX     XXXX  X  XX   X  X      X  X  X  X
    //  X   X   X   X   X   X   X   X   XX  X  XXXXXX  XXXXXX  XXXXXX
    //  X   X   X   X   XXXX     XXXX        
};


// Helper source/sink class for text analysis.
class TextAnalysis
    :   public ComBase<
            QiList<IDWriteTextAnalysisSource,
            QiList<IDWriteTextAnalysisSink,
            QiList<IUnknown
        > > > >
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
            isNumberSubstituted(),
            isSideways()
        { }

        UINT32 textStart;   // starting text position of this run
        UINT32 textLength;  // number of contiguous code units covered
        UINT32 glyphStart;  // starting glyph in the glyphs array
        UINT32 glyphCount;  // number of glyphs associated with this run of text
        DWRITE_SCRIPT_ANALYSIS script;
        UINT8 bidiLevel;
        UINT8 direction;
        UINT8 orientation;
        bool isNumberSubstituted;
        bool isSideways;

        enum
        {
            ReadingDirectionMask  = 3,
            GlyphOrientationShift = 2,
        };

        inline bool ContainsTextPosition(UINT32 desiredTextPosition) const throw()
        {
            return desiredTextPosition >= textStart
                && desiredTextPosition <  textStart + textLength;
        }

        inline bool operator==(UINT32 desiredTextPosition) const throw()
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

        UINT32 nextRunIndex;  // index of next run
    };

    struct CompleteOrientation
    {
        const DWRITE_MATRIX* transform;
        bool isReversed;
        bool isSideways;
    };

public:
    TextAnalysis(
        const wchar_t* text,
        UINT32 textLength,
        const wchar_t* localeName,
        IDWriteNumberSubstitution* numberSubstitution,
        DWRITE_READING_DIRECTION readingDirection
        );

    STDMETHODIMP GenerateResults(
        IDWriteTextAnalyzer* textAnalyzer,
        OUT std::vector<Run>& runs,
        OUT std::vector<DWRITE_LINE_BREAKPOINT>& breakpoints_
        ) throw();

    STDMETHODIMP AnalyzeOrientation(
        IDWriteTextAnalysisSource* analysisSource,
        UINT32 textPosition,
        UINT32 textLength,
        IDWriteTextAnalysisSink* analysisSink
        ) throw();

    // IDWriteTextAnalysisSource implementation

    IFACEMETHODIMP GetTextAtPosition(
        UINT32 textPosition,
        OUT WCHAR const** textString,
        OUT UINT32* textLength
        ) throw();

    IFACEMETHODIMP GetTextBeforePosition(
        UINT32 textPosition,
        OUT WCHAR const** textString,
        OUT UINT32* textLength
        ) throw();

    IFACEMETHODIMP_(DWRITE_READING_DIRECTION) GetParagraphReadingDirection() throw();

    IFACEMETHODIMP GetLocaleName(
        UINT32 textPosition,
        OUT UINT32* textLength,
        OUT WCHAR const** localeName
        ) throw();

    IFACEMETHODIMP GetNumberSubstitution(
        UINT32 textPosition,
        OUT UINT32* textLength,
        OUT IDWriteNumberSubstitution** numberSubstitution
        ) throw();

    STDMETHODIMP GetBidiLevel(
        UINT32 textPosition,
        OUT UINT32* textLength,
        OUT UINT8* resolvedLevel
        ) throw();

    // IDWriteTextAnalysisSink implementation

    IFACEMETHODIMP SetScriptAnalysis(
        UINT32 textPosition,
        UINT32 textLength,
        DWRITE_SCRIPT_ANALYSIS const* scriptAnalysis
        ) throw();

    IFACEMETHODIMP SetLineBreakpoints(
        UINT32 textPosition,
        UINT32 textLength,
        const DWRITE_LINE_BREAKPOINT* lineBreakpoints // [textLength]
        ) throw();

    IFACEMETHODIMP SetBidiLevel(
        UINT32 textPosition,
        UINT32 textLength,
        UINT8 explicitLevel,
        UINT8 resolvedLevel
        ) throw();

    IFACEMETHODIMP SetNumberSubstitution(
        UINT32 textPosition,
        UINT32 textLength,
        IDWriteNumberSubstitution* numberSubstitution
        ) throw();

    IFACEMETHODIMP SetOrientation(
        UINT32 textPosition,
        UINT32 textLength,
        DWRITEX_READING_DIRECTION readingDirection,
        DWRITEX_GLYPH_ORIENTATION glyphOrientation,
        const DWRITE_MATRIX* transform,
        bool isSideways,
        bool isReversed,
        UINT8 adjustedBidiLevel
        ) throw();

    // Helpers
    static void MapReadingDirectionToOrientation(
        DWRITEX_READING_DIRECTION readingDirection,
        DWRITEX_GLYPH_ORIENTATION glyphOrientation,
        __out CompleteOrientation& orientation
        ) throw();

protected:
    LinkedRun& FetchNextRun(IN OUT UINT32* textLength);

    void SetCurrentRun(UINT32 textPosition);

    void SplitCurrentRun(UINT32 splitPosition);

protected:
    // Input
    // (weak references are fine here, since this class is a transient
    //  stack-based helper that doesn't need to copy data)
    UINT32 textLength_;
    const wchar_t* text_; // [textLength_]
    const wchar_t* localeName_;
    IDWriteNumberSubstitution* numberSubstitution_;
    DWRITE_READING_DIRECTION readingDirection_;

    // Current processing state
    UINT32 currentPosition_;
    UINT32 currentRunIndex_;

    // Output
    std::vector<LinkedRun> runs_;
    std::vector<DWRITE_LINE_BREAKPOINT> breakpoints_;
};
// </SnippetTextAnalysish>
