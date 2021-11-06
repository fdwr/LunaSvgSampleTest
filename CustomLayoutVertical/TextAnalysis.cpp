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
#include "common.h"
#include "TextAnalysis.h"


TextAnalysis::TextAnalysis(
    const wchar_t* text,
    uint32_t textLength,
    const wchar_t* localeName,
    IDWriteNumberSubstitution* numberSubstitution,
    ReadingDirection readingDirection,
    GlyphOrientationMode glyphOrientationMode,
    bool treatAsIsolatedCharacters
    )
:   text_(text),
    textLength_(textLength),
    localeName_(localeName),
    readingDirection_(readingDirection),
    numberSubstitution_(numberSubstitution),
    glyphOrientationMode_(glyphOrientationMode),
    treatAsIsolatedCharacters_(treatAsIsolatedCharacters),
    currentPosition_(0),
    currentRunIndex_(0)
{
}


STDMETHODIMP TextAnalysis::GenerateResults(
    IDWriteTextAnalyzer1* textAnalyzer,
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

        if (runs_.empty())
        {
            runs_.resize(1);
        }

        if (textLength_ == 0) // set default paragraph reading direction for empty string
        {
            runs_.back().bidiLevel = (readingDirection_ & ReadingDirectionPrimaryProgression) != 0;
        }

        // Allocate enough room to have one breakpoint per code unit.
        breakpoints_.resize(textLength_);

        // Call each of the analyzers in sequence, recording their results.
        if (SUCCEEDED(hr = textAnalyzer->AnalyzeLineBreakpoints(this, 0, textLength_, this))
        &&  SUCCEEDED(hr = AnalyzeBidi(textAnalyzer, this, 0, textLength_, this))
        &&  SUCCEEDED(hr = textAnalyzer->AnalyzeScript(this, 0, textLength_, this))
        &&  SUCCEEDED(hr = textAnalyzer->AnalyzeNumberSubstitution(this, 0, textLength_, this))
        &&  SUCCEEDED(hr = AnalyzeGlyphOrientation(textAnalyzer, this, 0, textLength_, this))
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
        return ExceptionToHResult();
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
        return E_FAIL; // Unknown error, probably out of memory.
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


STDMETHODIMP TextAnalysis::AnalyzeGlyphOrientation(
    IDWriteTextAnalyzer1* textAnalyzer,
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
    const bool isReversedReadingDirection = (readingDirection_ & ReadingDirectionPrimaryProgression) != 0; // if reversed direction

    // Declare the comparer that checks for runs of contiguous orientation mode.
    class Comparer : public RunEqualityComparer
    {
    public:
        Comparer(GlyphOrientationMode glyphOrientationMode)
        :   glyphOrientationMode_(glyphOrientationMode)
        { }

        virtual bool Equals(const LinkedRun& firstRun, const LinkedRun& secondRun) override
        {
            return TextAnalysis::Resolve(firstRun.glyphOrientationMode,  glyphOrientationMode_)
                == TextAnalysis::Resolve(secondRun.glyphOrientationMode, glyphOrientationMode_);
        }

        GlyphOrientationMode glyphOrientationMode_;

    } comparer(this->glyphOrientationMode_);

    // Apply the orientation to all runs.

    SetCurrentRun(firstPosition);
    SplitCurrentRun(firstPosition);

    for (uint32_t remainingTextLength = textLength, textPosition = firstPosition;
         remainingTextLength > 0;
         )
    {
        uint32_t contiguousRunLength = GetContiguousRunLength(remainingTextLength, comparer);
        uint32_t nextPosition = textPosition + contiguousRunLength;
        remainingTextLength -= contiguousRunLength;
        
        const LinkedRun& firstRun = runs_[currentRunIndex_];
        const GlyphOrientationMode glyphOrientationMode = Resolve(firstRun.glyphOrientationMode, glyphOrientationMode_);
        
        switch (glyphOrientationMode)
        {
        case GlyphOrientationModeDefault:
        case GlyphOrientationModeStacked:
        default:
            // The orientation is not explicit, so leave the work up to DWrite
            // to use its database of character defaults.
            if (isVerticalReadingDirection)
            {
                textAnalyzer->AnalyzeVerticalGlyphOrientation(analysisSource, textPosition, contiguousRunLength, analysisSink);
            }
            else while (contiguousRunLength > 0)
            {
                // DWrite only supports vertical, so for horizontal orientation,
                // just fill in identity.
                LinkedRun& run          = FetchNextRun(IN OUT &contiguousRunLength);
                run.glyphOrientation    = GlyphOrientationCW0;
            }
            break;

        case GlyphOrientationModeRotated: // DWrite does not support this one, so we do it directly.
            while (contiguousRunLength > 0)
            {
                LinkedRun& run          = FetchNextRun(IN OUT &contiguousRunLength);
                run.glyphOrientation    = uint8_t(isVerticalReadingDirection ? GlyphOrientationCW90 : GlyphOrientationCW0);
                run.isSideways          = false;
                // run.isReversed       - leave as-is
                // run.bidiLevel        - leave as-is
            }
            break;

        case GlyphOrientationModeUpright: // DWrite does not support this one, so we do it directly.
            while (contiguousRunLength > 0)
            {
                LinkedRun& run          = FetchNextRun(IN OUT &contiguousRunLength);
                run.glyphOrientation    = GlyphOrientationCW0;
                run.isSideways          = isVerticalReadingDirection;
                run.isReversed          = isReversedReadingDirection;
                run.bidiLevel          += ((run.bidiLevel & 1) != isReversedReadingDirection) ? 1 : 0;
            }
            break;

        case GlyphOrientationModeLeftToRightTopToBottom:
        case GlyphOrientationModeRightToLeftTopToBottom:
        case GlyphOrientationModeLeftToRightBottomToTop:
        case GlyphOrientationModeRightToLeftBottomToTop:
        case GlyphOrientationModeTopToBottomLeftToRight:
        case GlyphOrientationModeBottomToTopLeftToRight:
        case GlyphOrientationModeTopToBottomRightToLeft:
        case GlyphOrientationModeBottomToTopRightToLeft:
            {
                bool isSideways = false;
                bool isReversed = false;
                ReadingDirection previousReadingDirection = ReadingDirectionUndefined;
                GlyphOrientation glyphOrientation = GlyphOrientation(glyphOrientationMode - GlyphOrientationModeExplicitFirst);

                while (contiguousRunLength > 0)
                {
                    LinkedRun& run = FetchNextRun(IN OUT &contiguousRunLength);

                    // Synthesize complete reading direction from paragraph
                    // reading direction and resolved bidi level.
                    ReadingDirection readingDirection = ReadingDirection((readingDirection_ & ~ReadingDirectionPrimaryProgression)
                                                                       | (run.bidiLevel & 1));
                    if (readingDirection != previousReadingDirection)
                    {
                        GetGlyphOrientationFlags(
                            readingDirection,
                            glyphOrientation,
                            &isSideways,
                            &isReversed
                            );
                        previousReadingDirection = readingDirection;
                    }

                    run.glyphOrientation    = uint8_t(glyphOrientation);
                    run.isSideways          = isSideways;
                    run.isReversed          = isReversed;
                    // run.bidiLevel        - leave as-is
                }
            }
            break;
        }

        textPosition = nextPosition;
    }

    return S_OK;
}


STDMETHODIMP TextAnalysis::AnalyzeBidi(
    IDWriteTextAnalyzer1* textAnalyzer,
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


    // Declare the comparer that checks for runs of contiguous reading direction.
    class Comparer : public RunEqualityComparer
    {
    public:
        Comparer() { }

        virtual bool Equals(const LinkedRun& firstRun, const LinkedRun& secondRun) override
        {
            return firstRun.readingDirection == secondRun.readingDirection;
        }

    } comparer;

    // Apply the reading direction to all runs.

    SetCurrentRun(firstPosition);
    SplitCurrentRun(firstPosition);

    for (uint32_t remainingTextLength = textLength, textPosition = firstPosition;
         remainingTextLength > 0;
         )
    {
        uint32_t contiguousRunLength = GetContiguousRunLength(remainingTextLength, comparer);
        uint32_t nextPosition = textPosition + contiguousRunLength;
        remainingTextLength -= contiguousRunLength;
        
        const ReadingDirection readingDirection = runs_[currentRunIndex_].readingDirection;

        switch (readingDirection)
        {
        case ReadingDirectionUndefined:
            if (treatAsIsolatedCharacters_)
            {
                uint32_t textPosition = firstPosition;
                uint32_t lastPosition = firstPosition + contiguousRunLength;

                // Analyze each character individually (avoids weak resolution).
                while (textPosition < lastPosition)
                {
                    uint32_t characterLength = 1;
                    if (IsLeadingSurrogate(text_[textPosition])
                    &&  textPosition + 1 < contiguousRunLength
                    &&  IsTrailingSurrogate(text_[textPosition + 1]))
                    {
                        ++characterLength;
                    }
                    textAnalyzer->AnalyzeBidi(analysisSource, textPosition, characterLength, analysisSink);
                    textPosition += characterLength;
                }
            }
            else
            {
                textAnalyzer->AnalyzeBidi(analysisSource, textPosition, contiguousRunLength, analysisSink);
            }
            break;

        default:
            {
                // If the paragraph reading direction is opposite the
                // resolved direction of the run, then increment the bidi
                // level once more, such that LTR in an RTL paragraph has
                // less priority (bidi level = 2).

                const uint8_t bidiLevel = (readingDirection & ReadingDirectionPrimaryProgression)
                                        ? 1  // RTL/BTT
                                        : (readingDirection_ & ReadingDirectionPrimaryProgression)
                                        ? 2  // LTR/TTB in RTL/BTT paragraph
                                        : 0; // LTR/TTB in LTR/TTB paragraph

                while (contiguousRunLength > 0)
                {
                    LinkedRun& run = FetchNextRun(IN OUT &contiguousRunLength);
                    run.bidiLevel  = bidiLevel;
                    run.isReversed = bidiLevel & 1;
                }
            }
            break;
        }

        textPosition = nextPosition;
    }

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


GlyphOrientationMode TextAnalysis::Resolve(
    GlyphOrientationMode glyphOrientationMode,
    GlyphOrientationMode defaultGlyphOrientationMode
    )
{
    return (glyphOrientationMode == GlyphOrientationModeUndefined)
            ? defaultGlyphOrientationMode
            : glyphOrientationMode;
}
