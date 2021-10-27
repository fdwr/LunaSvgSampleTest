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
#include "precomp.h"
#ifdef TEXT_ANALYSIS_FONT_SELECTION_IS_SUPPORTED
#include "FontSelection.h"
#endif
//#include "TextAnalysis.h"


TextAnalysis::TextAnalysis(
    const wchar_t* text, // weak ref
    uint32_t textLength,
    const wchar_t* localeName, // weak ref
    IDWriteNumberSubstitution* numberSubstitution, // weak ref
    ReadingDirection readingDirection,
    GlyphOrientationMode glyphOrientationMode,
    FontSelection const* fontSelection, // weak ref
    IDWriteFontCollection* fontCollection, // weak ref
    IDWriteFontFace* fontFace // weak ref
    )
:   text_(text),
    textLength_(textLength),
    localeName_(localeName),
    readingDirection_(readingDirection),
    numberSubstitution_(numberSubstitution),
    glyphOrientationMode_(glyphOrientationMode),
    fontSelection_(fontSelection),
    fontCollection_(fontCollection),
    fontFace_(fontFace),
    currentRunIndex_(0)
{
}


void TextAnalysis::SetText(
    const wchar_t* text, // weak ref
    uint32_t textLength
    ) throw()
{
    text_ = text;
    textLength_ = textLength;
}


STDMETHODIMP TextAnalysis::ResetResults()
{
    try
    {
        ResetResultsInternal();
    }
    catch (...)
    {
        return Application::ExceptionToHResult();
    }

    return S_OK;
}


void TextAnalysis::ResetResultsInternal()
{
    currentRunIndex_ = 0;

    if (runs_.empty())
    {
        runs_.resize(1);
        runs_.front().textLength = textLength_;
    }

    if (textLength_ == 0) // set default paragraph reading direction for empty string
    {
        runs_.back().bidiLevel = (readingDirection_ & ReadingDirectionPrimaryProgression) != 0;
    }

    // Allocate enough room to have one breakpoint per code unit.
    breakpoints_.resize(textLength_);
}


STDMETHODIMP TextAnalysis::GenerateResults(
    IDWriteTextAnalyzer* textAnalyzer,
    IN OUT std::vector<TextAnalysis::LinkedRun>& runs,
    OUT std::vector<DWRITE_LINE_BREAKPOINT>& breakpoints
    )
{
    // Analyzes the text using each of the analyzers and returns
    // their results as a series of runs.

    HRESULT hr = S_OK;

    try
    {
        // Any formatting control codes are already stripped from text, and
        // we have formatting runs if present. If not, we just start out with
        // one result that covers the entire range, and this result will then
        // be subdivided by the analysis process.
        runs_ = runs;

        ResetResultsInternal();

        // Call each of the analyzers in sequence, recording their results.
        if (SUCCEEDED(hr = textAnalyzer->AnalyzeLineBreakpoints(this, 0, textLength_, this))
        &&  SUCCEEDED(hr = textAnalyzer->AnalyzeBidi(this, 0, textLength_, this))
        &&  SUCCEEDED(hr = textAnalyzer->AnalyzeScript(this, 0, textLength_, this))
        &&  SUCCEEDED(hr = textAnalyzer->AnalyzeNumberSubstitution(this, 0, textLength_, this))
        #ifdef GLYPH_ORIENTATION_IS_SUPPORTED
        &&  SUCCEEDED(hr = AnalyzeGlyphOrientation(textAnalyzer, this, 0, textLength_, this))
        #endif
        &&  SUCCEEDED(hr = AnalyzeFonts(0, textLength_))
        )
        {
            // Exchange our results with the caller's.
            breakpoints.swap(breakpoints_);

            // Resequence the resulting runs in order before returning to caller.
            size_t totalRuns = runs_.size();
            runs.resize(totalRuns);

            uint32_t nextRunIndex = 0;
            for (size_t i = 0; i < totalRuns; ++i)
            {
                runs[i]         = runs_[nextRunIndex];
                nextRunIndex    = runs_[nextRunIndex].nextRunIndex;
            }
        }
    }
    catch (...)
    {
        return Application::ExceptionToHResult();
    }

    return hr;
}


STDMETHODIMP TextAnalysis::GenerateSimpleOrientationResults(
    IDWriteTextAnalyzer* textAnalyzer,
    IN OUT LinkedRun& run
    )
{
    // Analyzes the text using minimal set of analyzers.

    HRESULT hr = S_OK;

    try
    {
        // Any formatting control codes are already stripped from text, and
        // we have formatting runs if present. If not, we just start out with
        // one result that covers the entire range, and this result will then
        // be subdivided by the analysis process.
        currentRunIndex_ = 0;
        runs_.clear();
        runs_.push_back(run);

        if (textLength_ == 0) // set default paragraph reading direction for empty string
        {
            runs_.back().bidiLevel = (readingDirection_ & ReadingDirectionPrimaryProgression) != 0;
        }

        // Call each of the analyzers in sequence, recording their results.
        if (SUCCEEDED(hr = textAnalyzer->AnalyzeBidi(this, 0, textLength_, this))
        #ifdef GLYPH_ORIENTATION_IS_SUPPORTED
        &&  SUCCEEDED(hr = AnalyzeGlyphOrientation(textAnalyzer, this, 0, textLength_, this))
        #endif
        )
        {
            run = runs_.front();
        }
    }
    catch (...)
    {
        return Application::ExceptionToHResult();
    }

    return hr;
}


////////////////////////////////////////////////////////////////////////////////
// IDWriteTextAnalysisSource source implementation

IFACEMETHODIMP TextAnalysis::GetTextAtPosition(
    uint32_t textPosition,
    OUT WCHAR const** textString,
    OUT uint32_t* textLength
    ) throw()
{
    if (textPosition >= textLength_)
    {
        // Return no text if a query comes for a position at the end of
        // the range. Note that is not an error and we should not return
        // a failing HRESULT. Although the application is not expected
        // to return any text that is outside of the given range, the
        // analyzers may probe the ends to see if text exists.
        *textString = nullptr;
        *textLength = 0;
    }
    else
    {
        *textString = &text_[textPosition];
        *textLength = textLength_ - textPosition;
    }
    return S_OK;
}


IFACEMETHODIMP TextAnalysis::GetTextBeforePosition(
    uint32_t textPosition,
    OUT WCHAR const** textString,
    OUT uint32_t* textLength
    ) throw()
{
    if (textPosition == 0 || textPosition > textLength_)
    {
        // Return no text if a query comes for a position at the end of
        // the range. Note that is not an error and we should not return
        // a failing HRESULT. Although the application is not expected
        // to return any text that is outside of the given range, the
        // analyzers may probe the ends to see if text exists.
        *textString = nullptr;
        *textLength = 0;
    }
    else
    {
        *textString = &text_[0];
        *textLength = textPosition - 0; // text length is valid from current position backward
    }
    return S_OK;
}


DWRITE_READING_DIRECTION STDMETHODCALLTYPE TextAnalysis::GetParagraphReadingDirection() throw()
{
    return (readingDirection_ & ReadingDirectionPrimaryProgression) != 0
          ? DWRITE_READING_DIRECTION_RIGHT_TO_LEFT
          : DWRITE_READING_DIRECTION_LEFT_TO_RIGHT;
}


IFACEMETHODIMP TextAnalysis::GetLocaleName(
    uint32_t textPosition,
    OUT uint32_t* textLength,
    OUT WCHAR const** localeName
    ) throw()
{
    // The pointer returned should remain valid until the next call,
    // or until analysis ends. Since only one locale name is supported,
    // the text length is valid from the current position forward to
    // the end of the string.

    *localeName = localeName_;
    *textLength = textLength_ - textPosition;

    return S_OK;
}


IFACEMETHODIMP TextAnalysis::GetNumberSubstitution(
    uint32_t textPosition,
    OUT uint32_t* textLength,
    OUT IDWriteNumberSubstitution** numberSubstitution
    ) throw()
{
    if (numberSubstitution_ != nullptr)
        numberSubstitution_->AddRef();

    *numberSubstitution = numberSubstitution_;
    *textLength = textLength_ - textPosition;

    return S_OK;
}


#ifdef GLYPH_ORIENTATION_IS_SUPPORTED
STDMETHODIMP TextAnalysis::GetVerticalGlyphOrientation(
    uint32_t textPosition,
    OUT uint32_t* textLength,
    OUT DWRITE_VERTICAL_GLYPH_ORIENTATION* glyphOrientation,
    OUT uint8_t* bidiLevel
    )
{
    SetCurrentRun(textPosition);
    const LinkedRun& run    = runs_[currentRunIndex_];
    *bidiLevel              = run.bidiLevel;

    GlyphOrientationMode glyphOrientationMode = run.glyphOrientationMode;
    if (glyphOrientationMode == GlyphOrientationModeUndefined)
        glyphOrientationMode = glyphOrientationMode_;

    switch (glyphOrientationMode)
    {
    case GlyphOrientationModeDefault:
    case GlyphOrientationModeRotated:
        *glyphOrientation = DWRITE_VERTICAL_GLYPH_ORIENTATION_DEFAULT;
        break;

    case GlyphOrientationModeStacked:
    case GlyphOrientationModeUpright: // no vertical forms
        *glyphOrientation = DWRITE_VERTICAL_GLYPH_ORIENTATION_STACKED;
        break;
    }

    // Find the next range where a bidi level changes.

    const size_t totalRuns = runs_.size();
    uint32_t lastRunPosition = textPosition;
    uint32_t nextRunIndex = currentRunIndex_;

    do
    {
        const LinkedRun& nextRun = runs_[nextRunIndex];
        if (nextRun.bidiLevel != run.bidiLevel)
        {
            break;
        }
        lastRunPosition = nextRun.textStart + nextRun.textLength;
        nextRunIndex = nextRun.nextRunIndex;
    }
    while (nextRunIndex < totalRuns && nextRunIndex != 0);

    *textLength = lastRunPosition - textPosition;

    return S_OK;
}
#endif


////////////////////////////////////////////////////////////////////////////////
// IDWriteTextAnalysisSink implementation

IFACEMETHODIMP TextAnalysis::SetLineBreakpoints(
    uint32_t textPosition,
    uint32_t textLength,
    DWRITE_LINE_BREAKPOINT const* lineBreakpoints   // [textLength]
    ) throw()
{
    if (textLength > 0)
    {
        memcpy(&breakpoints_[textPosition], lineBreakpoints, textLength * sizeof(lineBreakpoints[0]));
    }
    return S_OK;
}


IFACEMETHODIMP TextAnalysis::SetScriptAnalysis(
    uint32_t textPosition,
    uint32_t textLength,
    DWRITE_SCRIPT_ANALYSIS const* scriptAnalysis
    ) throw()
{
    try
    {
        SetCurrentRun(textPosition);
        SplitCurrentRun(textPosition);
        while (textLength > 0)
        {
            LinkedRun& run  = FetchNextRun(IN OUT &textLength);
            run.script      = *scriptAnalysis;
        }
    }
    catch (...)
    {
        return Application::ExceptionToHResult(); // Unknown error, probably out of memory.
    }

    return S_OK;
}


IFACEMETHODIMP TextAnalysis::SetBidiLevel(
    uint32_t textPosition,
    uint32_t textLength,
    uint8_t explicitLevel,
    uint8_t resolvedLevel
    ) throw()
{
    try
    {
        SetCurrentRun(textPosition);
        SplitCurrentRun(textPosition);
        while (textLength > 0)
        {
            uint8_t highestLevel = std::max(explicitLevel, resolvedLevel);
            LinkedRun& run  = FetchNextRun(IN OUT &textLength);
            run.bidiLevel   = highestLevel;
            run.isReversed  = !!(highestLevel & 1);
        }
    }
    catch (...)
    {
        return E_FAIL; // Unknown error, probably out of memory.
    }

    return S_OK;
}


IFACEMETHODIMP TextAnalysis::SetNumberSubstitution(
    uint32_t textPosition,
    uint32_t textLength,
    IDWriteNumberSubstitution* numberSubstitution
    ) throw()
{
    try
    {
        SetCurrentRun(textPosition);
        SplitCurrentRun(textPosition);
        while (textLength > 0)
        {
            LinkedRun& run          = FetchNextRun(IN OUT &textLength);
            run.isNumberSubstituted = (numberSubstitution != nullptr);
        }
    }
    catch (...)
    {
        return E_FAIL; // Unknown error, probably out of memory.
    }

    return S_OK;
}


#ifdef GLYPH_ORIENTATION_IS_SUPPORTED
IFACEMETHODIMP TextAnalysis::SetGlyphOrientation(
    uint32_t textPosition,
    uint32_t textLength,
    DWRITE_GLYPH_ORIENTATION_ANGLE glyphOrientationAngle,
    uint8_t adjustedBidiLevel,
    BOOL isSideways,
    BOOL isRightToLeft
    ) throw()
{
    try
    {
        // Mapping from angle down to small orientation.
        const static uint8_t glyphOrientations[] = {
            GlyphOrientationCW0,
            GlyphOrientationCW90,
            GlyphOrientationCW180,
            GlyphOrientationCW270,
        };

        SetCurrentRun(textPosition);
        SplitCurrentRun(textPosition);
        while (textLength > 0)
        {
            LinkedRun& run          = FetchNextRun(IN OUT &textLength);
            run.glyphOrientation    = glyphOrientations[glyphOrientationAngle & 3];
            run.isSideways          = !!isSideways;
            run.isReversed          = !!isRightToLeft;
            run.bidiLevel           = adjustedBidiLevel;
        }
    }
    catch (...)
    {
        return E_FAIL; // Unknown error, probably out of memory.
    }

    return S_OK;
}
#endif


#ifdef GLYPH_ORIENTATION_IS_SUPPORTED
STDMETHODIMP TextAnalysis::AnalyzeGlyphOrientation(
    IDWriteTextAnalyzer* textAnalyzer,
    IDWriteTextAnalysisSource1* analysisSource,
    uint32_t firstPosition,
    uint32_t textLength,
    IDWriteTextAnalysisSink1* analysisSink
    ) throw()
{
    if (firstPosition + textLength < firstPosition)
        return E_INVALIDARG;

    if (textLength == 0)
        return S_OK;

    const bool isVerticalReadingDirection = (readingDirection_ & ReadingDirectionPrimaryAxis) != 0; // if vertical direction

    // Apply the orientation to all runs.

    SetCurrentRun(firstPosition);
    SplitCurrentRun(firstPosition);

    switch (glyphOrientationMode_)
    {
    case GlyphOrientationModeDefault:
    case GlyphOrientationModeStacked:
        // The orientation is not explicit, so leave the work up to DWrite
        // to use its database of character defaults.
        if (isVerticalReadingDirection)
        {
            textAnalyzer->AnalyzeVerticalGlyphOrientation(analysisSource, textPosition, textLength, analysisSink);
        }
    }

    return S_OK;
}
#endif


STDMETHODIMP TextAnalysis::AnalyzeFonts(
    uint32_t firstPosition,
    uint32_t textLength
    )
{
    if (firstPosition + textLength < firstPosition)
        return E_INVALIDARG;

    if (textLength == 0)
        return S_OK;

    SetCurrentRun(firstPosition);
    SplitCurrentRun(firstPosition);

    // If no font fallback is set, then set all runs to the default font face.
    if (fontSelection_ == nullptr || fontCollection_ == nullptr)
    {
        for (uint32_t remainingTextLength = textLength;
             remainingTextLength > 0;
             )
        {
            LinkedRun& run = FetchNextRun(IN OUT &remainingTextLength);
            run.fontFace = fontFace_;
        }
        return S_OK;
    }

#ifdef TEXT_ANALYSIS_FONT_SELECTION_IS_SUPPORTED
    ComPtr<IDWriteFont> font;
    ComPtr<IDWriteFontFace> fontFace;

    uint32_t previousFontIndex = ~0u;

    // Select a font for each run.
    for (uint32_t remainingTextLength = textLength, textPosition = firstPosition;
         remainingTextLength > 0;
         )
    {
        const LinkedRun& currentRun = runs_[currentRunIndex_];

        // Match to base font first.
        bool fontSupportedGlyphs = true;
        uint32_t fontIndex, matchLength;

        uint32_t maximumRunLength = std::min(currentRun.textLength, remainingTextLength);
        if (currentRun.script.shapes & DWRITE_SCRIPT_SHAPES_NO_VISUAL)
        {
            // For invisible characters, just use the base font.
            matchLength = maximumRunLength;
        }
        else
        {
            RETURN_ON_FAILURE(
                fontSelection_->MatchText(
                    &text_[textPosition],
                    maximumRunLength,
                    fontFace_,
                    OUT matchLength,
                    OUT fontSupportedGlyphs
                    ));
            maximumRunLength = matchLength; // Constrain fallback limit to base font.
        }

        if (fontSupportedGlyphs)
        {
            // Just use base font.
            previousFontIndex = ~0u;
            fontFace.Set(fontFace_);
        }
        else
        {
            // Look for a fallback font.
            RETURN_ON_FAILURE(
                fontSelection_->MatchText(
                    &text_[textPosition],
                    maximumRunLength,
                    OUT fontIndex,
                    OUT matchLength
                    ));

            // Create the font. Reuse the previous one if it's the same.
            if (fontIndex != previousFontIndex)
            {
                previousFontIndex = fontIndex;

                font.Clear();
                RETURN_ON_FAILURE(
                    fontSelection_->GetFont(
                        fontCollection_,
                        fontIndex,
                        OUT &font
                        ));

                fontFace.Clear();
                RETURN_ON_FAILURE(font->CreateFontFace(OUT &fontFace));
            }
        }

        textPosition += matchLength;
        remainingTextLength -= matchLength;
        LinkedRun& run = FetchNextRun(IN OUT &matchLength);
        run.fontFace = fontFace;
    }
#endif

    return S_OK;
}


////////////////////////////////////////////////////////////////////////////////
// Run modification.

TextAnalysis::LinkedRun& TextAnalysis::FetchNextRun(
    IN OUT uint32_t* textLength
    )
{
    // Used by the sink setters, this returns a reference to the next run.
    // Position and length are adjusted to now point after the current run
    // being returned.

    uint32_t runIndex      = currentRunIndex_;
    uint32_t runTextLength = runs_[currentRunIndex_].textLength;

    // Split the tail if needed (the length remaining is less than the
    // current run's size).
    if (*textLength < runTextLength)
    {
        runTextLength         = *textLength; // Limit to what's actually left.
        uint32_t runTextStart = runs_[currentRunIndex_].textStart;

        SplitCurrentRun(runTextStart + runTextLength);
    }
    else
    {
        // Just advance the current run.
        currentRunIndex_ = runs_[currentRunIndex_].nextRunIndex;
    }
    *textLength -= runTextLength;


    // Return a reference to the run that was just current.
    return runs_[runIndex];
}


void TextAnalysis::SetCurrentRun(uint32_t textPosition)
{
    // Move the current run to the given position.
    // Since the analyzers generally return results in a forward manner,
    // this will usually just return early. If not, find the
    // corresponding run for the text position.

    if (currentRunIndex_ < runs_.size()
    &&  runs_[currentRunIndex_].ContainsTextPosition(textPosition))
    {
        // currentRunIndex_ remains the same.
        return;
    }

    currentRunIndex_ = static_cast<uint32_t>(
                            std::find(runs_.begin(), runs_.end(), textPosition)
                            - runs_.begin()
                            );
}


void TextAnalysis::SplitCurrentRun(uint32_t splitPosition)
{
    // Splits the current run and adjusts the run values accordingly.
    // The current run index points to run containing the character
    // at the split.

    const uint32_t runTextStart = runs_[currentRunIndex_].textStart;

    if (splitPosition <= runTextStart)
        return; // no change

    // Grow runs by one.
    const size_t totalRuns = runs_.size();
    try
    {
        runs_.resize(totalRuns + 1);
    }
    catch (...)
    {
        return; // Can't increase size. Return same run.
    }

    // Copy the old run to the end.
    LinkedRun& frontHalf = runs_[currentRunIndex_];
    LinkedRun& backHalf  = runs_.back();
    backHalf             = frontHalf;

    // Adjust runs' text positions and lengths.
    uint32_t splitPoint     = splitPosition - runTextStart;
    backHalf.textStart     += splitPoint;
    backHalf.textLength    -= splitPoint;
    frontHalf.textLength    = splitPoint;
    frontHalf.nextRunIndex  = static_cast<uint32_t>(totalRuns);
    currentRunIndex_        = static_cast<uint32_t>(totalRuns);
}


uint32_t TextAnalysis::GetContiguousRunLength(
    uint32_t textLength,
    RunEqualityComparer& comparer
    )
{
    // textPosition is implicit by the current run index.

    LinkedRun& firstRun = runs_[currentRunIndex_];
    uint32_t runIndex = currentRunIndex_;
    uint32_t remainingTextLength = textLength;

    while (remainingTextLength > 0)
    {
        const LinkedRun& run = runs_[runIndex];

        if (!comparer.Equals(firstRun, run))
        {
            break; // return length up to the point where the runs don't match.
        }
        uint32_t runTextLength = std::min(run.textLength, remainingTextLength);
        remainingTextLength -= runTextLength;
        runIndex = run.nextRunIndex;
    }

    return textLength - remainingTextLength;
}


////////////////////////////////////////////////////////////////////////////////
// Helpers

GlyphOrientation TextAnalysis::UndoSidewaysOrientation(GlyphOrientation glyphOrientation)
{
    // This undoes the sideways transform, remapping to an equivalent glyph
    // orientation that is clockwise 90.
    //                                                 0 1 2 3 4 5 6 7
    const static uint8_t undoSidewaysTransform[8]   = {6,4,7,5,2,0,3,1};

    return static_cast<GlyphOrientation>(undoSidewaysTransform[glyphOrientation & 7]);
}


void TextAnalysis::GetGlyphOrientationFlags(
    ReadingDirection readingDirection,
    GlyphOrientation glyphOrientation,
    OUT bool* isSideways,
    OUT bool* isReversed
    )
{
    *isSideways = ((readingDirection ^ glyphOrientation) & ReadingDirectionPrimaryAxis) != 0;

    if (*isSideways)
    {
        // The world transform is an additional 90 degrees clockwise from the
        // glyph orientation when the sideways flag is set. So choose a
        // transform that compensates for that.
        glyphOrientation = UndoSidewaysOrientation(glyphOrientation);
    }

    *isReversed = ((readingDirection ^ glyphOrientation) & ReadingDirectionPrimaryProgression) != 0;
}


bool TextAnalysis::RequiresVerticalGlyphVariants(
    GlyphOrientationMode glyphOrientationMode,
    bool isSideways
    )
{
    switch (glyphOrientationMode)
    {
    case GlyphOrientationModeRotated:
    case GlyphOrientationModeUndefined:
    case GlyphOrientationModeDefault:
    case GlyphOrientationModeStacked:
    default:
        return isSideways;

    case GlyphOrientationModeUpright:
    case GlyphOrientationModeLeftToRightTopToBottom:
    case GlyphOrientationModeRightToLeftTopToBottom:
    case GlyphOrientationModeLeftToRightBottomToTop:
    case GlyphOrientationModeRightToLeftBottomToTop:
    case GlyphOrientationModeTopToBottomLeftToRight:
    case GlyphOrientationModeBottomToTopLeftToRight:
    case GlyphOrientationModeTopToBottomRightToLeft:
    case GlyphOrientationModeBottomToTopRightToLeft:
        return false;
    }
}


bool TextAnalysis::HasVerticalBaseline(
    GlyphOrientation glyphOrientation,
    bool isSideways
    )
{
    // Returns true for sideways glyphs in a horizontal line,
    // or upright glyphs in a vertical line.
    return isSideways ^ !!(glyphOrientation & GlyphOrientationFlipDiagonal);
}


GlyphOrientationMode TextAnalysis::Resolve(
    GlyphOrientationMode glyphOrientationMode,
    GlyphOrientationMode defaultGlyphOrientationMode
    )
{
    return (glyphOrientationMode == GlyphOrientationModeUndefined)
            ? defaultGlyphOrientationMode
            : glyphOrientationMode;
}


TextAnalysis::PointF TextAnalysis::GetGlyphOrigin(
    const Run& run,
    float midline,
    float ascent,
    float descent,
    float runWidth
    )
{
    // Adjust glyph run to the appropriate baseline.
    // Note this function works in u v space which is relative to whichever
    // way the line's reading direction happens to be progressing, whether
    // vertical, horizontal, or (theoretically) diagonal.

    PointF origin; // x=u y=v
    if (run.isSideways)
    {
        origin.y = midline;
    }
    else
    {
        if (run.glyphOrientation & GlyphOrientationFlipVertical)
        {
            // Common case in vertical. Uncommon in horizontal, but
            // could occur for RTL Ogham or Mongolian.
            //
            //     2         3          6           7
            //  88    88  88    88  8888888888  88    88
            //  88   88    88   88      88  88    8888  88
            //  888888      888888    8888  88      88  88
            //  88    88  88    88  88    88    8888888888
            //  888888      888888
            //
            origin.y = descent;
        }
        else
        {
            // Common case in horizontal. Uncommon case in vertical,
            // but occurs for Arabic in TTB stacked vertical or BTT
            // Latin.
            //
            //     0         1          4           5     
            //  888888      888888  8888888888    88    88
            //  88    88  88    88  88  88      88  8888  
            //  888888      888888  88  8888    88  88    
            //  88   88    88   88    88    88  8888888888
            //  88    88  88    88  
            //
            origin.y = ascent;
        }
    }

    origin.x = (run.bidiLevel & 1) ? runWidth : 0; // origin starts from right if RTL

    return origin;
}


IFACEMETHODIMP TextAnalysis::QueryInterface(IID const& iid, __out void** object)
{
    COM_BASE_RETURN_INTERFACE(iid, IDWriteTextAnalysisSource, object);
    COM_BASE_RETURN_INTERFACE(iid, IDWriteTextAnalysisSink, object);
    COM_BASE_RETURN_INTERFACE_AMBIGUOUS(iid, IUnknown, object, static_cast<IDWriteTextAnalysisSource*>(this));
    COM_BASE_RETURN_NO_INTERFACE(object);
}
