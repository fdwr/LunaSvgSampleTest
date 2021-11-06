// <SnippetFlowLayoutcpp>
// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// Copyright (c) Microsoft Corporation. All rights reserved
//
// Contents:    Custom layout, demonstrating usage of shaping and glyph
//              results.
//
//----------------------------------------------------------------------------
#include "common.h"
#include "TextAnalysis.h"
#include "FlowSource.h"
#include "FlowSink.h"
#include "FlowLayout.h"


namespace
{
    // Estimates the maximum number of glyph indices needed to hold a string of 
    // a given length.  This is the formula given in the Uniscribe SDK and should
    // cover most cases. Degenerate cases will require a reallocation.
    uint32_t EstimateGlyphCount(uint32_t textLength)
    {
        return 3 * textLength / 2 + 16;
    }

    HRESULT GetGlyphMetrics(
        IDWriteFontFace* fontFace,
        DWRITE_MEASURING_MODE measuringMode,
        float fontEmSize,
        bool isSideways,
        uint32_t glyphCount,
        __in_ecount(glyphCount) uint16_t* glyphIds,
        __out_ecount(glyphCount) DWRITE_GLYPH_METRICS* glyphRunMetrics
        )
    {
        // Call the right function depending on the measuring mode.
        switch (measuringMode)
        {
        case DWRITE_MEASURING_MODE_GDI_CLASSIC:
        case DWRITE_MEASURING_MODE_GDI_NATURAL:
            return fontFace->GetGdiCompatibleGlyphMetrics(
                fontEmSize,
                1.0, // pixelsPerDip
                nullptr, // transform
                measuringMode == DWRITE_MEASURING_MODE_GDI_NATURAL,
                glyphIds,
                glyphCount,
                glyphRunMetrics,
                isSideways
                );

        case DWRITE_MEASURING_MODE_NATURAL:
        default:
            return fontFace->GetDesignGlyphMetrics(glyphIds, glyphCount, glyphRunMetrics, isSideways);
        }
    }
}


STDMETHODIMP FlowLayout::SetTextFormat(IDWriteTextFormat* textFormat)
{
    // Initializes properties using a text format, like font family, font size,
    // and reading direction. For simplicity, this custom layout supports
    // minimal formatting. No mixed formatting or alignment modes are supported.

    HRESULT hr = S_OK;

    wchar_t fontFamilyName[100];

    // note the reading direction from the format is ignored

    hr = textFormat->GetLocaleName(localeName_, ARRAYSIZE(localeName_));

    // Find matching family name in collection.
    if (SUCCEEDED(hr))
    {
        hr = textFormat->GetFontFamilyName(fontFamilyName, ARRAYSIZE(fontFamilyName));
    }

    if (SUCCEEDED(hr))
    {
        hr = SetFont(
                fontFamilyName,
                textFormat->GetFontWeight(),
                textFormat->GetFontStretch(),
                textFormat->GetFontStyle(),
                textFormat->GetFontSize()
                );
    }

    return S_OK;
}


STDMETHODIMP FlowLayout::SetFont(
    const wchar_t* fontFamilyName,
    DWRITE_FONT_WEIGHT fontWeight,
    DWRITE_FONT_STRETCH fontStretch,
    DWRITE_FONT_STYLE fontSlope,
    float fontEmSize
    )
{
    HRESULT hr = S_OK;

    IDWriteFontCollection*  fontCollection  = nullptr;
    IDWriteFontFamily*      fontFamily      = nullptr;
    IDWriteFont*            font            = nullptr;

    if (fontEmSize > 0)
        fontEmSize_ = fontEmSize;

    ////////////////////
    // Map font and style to fontFace.

    if (SUCCEEDED(hr))
    {
        // Need the font collection to map from font name to actual font.
        if (fontCollection == nullptr)
        {
            // No font collection was set in the format, so use the system default.
            hr = dwriteFactory_->GetSystemFontCollection(&fontCollection);
        }
    }

    uint32_t fontIndex  = 0;
    if (SUCCEEDED(hr))
    {
        BOOL fontExists = false;
        hr = fontCollection->FindFamilyName(fontFamilyName, &fontIndex, &fontExists);
        if (!fontExists)
        {
            // If the given font does not exist, take what we can get
            // (displaying something instead nothing), choosing the foremost
            // font in the collection.
            fontIndex = 0;
        }
    }

    if (SUCCEEDED(hr))
    {
        hr = fontCollection->GetFontFamily(fontIndex, &fontFamily);
    }

    if (SUCCEEDED(hr))
    {
        hr = fontFamily->GetFirstMatchingFont(
                fontWeight,
                fontStretch,
                fontSlope,
                &font
                );
    }

    if (SUCCEEDED(hr))
    {
        SafeRelease(&fontFace_);
        hr = font->CreateFontFace(&fontFace_);
    }

    SafeRelease(&font);
    SafeRelease(&fontFamily);
    SafeRelease(&fontCollection);

    return hr;
}


STDMETHODIMP FlowLayout::SetNumberSubstitution(IDWriteNumberSubstitution* numberSubstitution)
{
    SafeSet(&numberSubstitution_, numberSubstitution);

    return S_OK;
}


STDMETHODIMP FlowLayout::SetReadingDirection(ReadingDirection readingDirection)
{
    readingDirection_ = readingDirection;
    return S_OK;
}


ReadingDirection FlowLayout::GetReadingDirection()
{
    return readingDirection_;
}


STDMETHODIMP FlowLayout::SetGlyphOrientationMode(GlyphOrientationMode glyphOrientationMode)
{
    glyphOrientationMode_ = glyphOrientationMode;
    return S_OK;
}


GlyphOrientationMode FlowLayout::GetGlyphOrientationMode()
{
    return glyphOrientationMode_;
}


STDMETHODIMP FlowLayout::SetJustificationMode(JustificationMode justificationMode)
{
    justificationMode_ = justificationMode;
    return S_OK;
}


STDMETHODIMP FlowLayout::SetTreatAsIsolatedCharacters(bool treatAsIsolatedCharacters)
{
    treatAsIsolatedCharacters_ = treatAsIsolatedCharacters;
    return S_OK;
}


STDMETHODIMP FlowLayout::SetText(
    const wchar_t* text, // [textLength]
    uint32_t textLength
    ) throw()
{
    // Analyzes the given text and keeps the results for later reflow.

    isTextAnalysisComplete_ = false;

    try
    {
        formattedText_.assign(text, textLength);
    }
    catch (...)
    {
        return ExceptionToHResult();
    }

    return S_OK;
}


STDMETHODIMP FlowLayout::GetText(
    OUT const wchar_t** text, // [textLength]
    OUT uint32_t* textLength
    ) throw()
{
    *text = &formattedText_[0];
    *textLength = static_cast<uint32_t>(formattedText_.size());

    return S_OK;
}


STDMETHODIMP FlowLayout::AnalyzeText() throw()
{
    // Analyzes the given text and keeps the results for later reflow.

    HRESULT hr = S_OK;

    isTextAnalysisComplete_ = false;

    if (fontFace_ == nullptr)
        return E_FAIL; // Need a font face to determine metrics.

    // Query for the text analyzer's interface.
    IDWriteTextAnalyzer*  textAnalyzer0 = nullptr;
    IDWriteTextAnalyzer1* textAnalyzer  = nullptr;
    if (SUCCEEDED(hr))
    {
        hr = dwriteFactory_->CreateTextAnalyzer(&textAnalyzer0);
    }
    if (SUCCEEDED(hr))
    {
        hr = textAnalyzer0->QueryInterface(__uuidof(*textAnalyzer), reinterpret_cast<void**>(&textAnalyzer));
    }

    if (SUCCEEDED(hr))
    {
        hr = CreateFormattedRuns();
    }

    // Record the analyzer's results.
    if (SUCCEEDED(hr))
    {
        TextAnalysis textAnalysis(
            text_.c_str(),
            static_cast<uint32_t>(text_.size()),
            localeName_,
            numberSubstitution_,
            readingDirection_,
            glyphOrientationMode_,
            treatAsIsolatedCharacters_
            );

        hr = textAnalysis.GenerateResults(textAnalyzer, runs_, breakpoints_);
    }

    // Convert the entire text to glyphs.
    if (SUCCEEDED(hr))
    {
        hr = ShapeGlyphRuns(textAnalyzer);
    }

    if (SUCCEEDED(hr))
    {
        isTextAnalysisComplete_ = true;
    }

    SafeRelease(&textAnalyzer0);
    SafeRelease(&textAnalyzer);

    return hr;
}


namespace
{
    // For embedded formatting markup in the input string
    struct FormattingCode
    {
        wchar_t* name;
        int32_t  code;

        enum {
            NoMatch=-1,
            ReadingDirection,
            GlyphOrientation,
            LineGap,
            OpeningBrace,
            ClosingBrace,
            LeftToRightEmbedding,
            RightToLeftEmbedding,
            PopEmbedding,
        };
    };

    const FormattingCode g_FormattingCodes[] =
    {
        {L"dir" ,       FormattingCode::ReadingDirection},
        {L"or" ,        FormattingCode::GlyphOrientation},
        {L"linegap" ,   FormattingCode::LineGap},
        {L"op" ,        FormattingCode::OpeningBrace},
        {L"lre" ,       FormattingCode::LeftToRightEmbedding},
        {L"rle" ,       FormattingCode::RightToLeftEmbedding},
        {L"pdf" ,       FormattingCode::PopEmbedding},
    };

    const FormattingCode g_ReadingDirectionCodes[] =
    {
        {L"rd",         ReadingDirectionLeftToRightTopToBottom},
        {L"ld",         ReadingDirectionRightToLeftTopToBottom},
        {L"ru",         ReadingDirectionLeftToRightBottomToTop},
        {L"lu",         ReadingDirectionRightToLeftBottomToTop},
        {L"dr",         ReadingDirectionTopToBottomLeftToRight},
        {L"ur",         ReadingDirectionBottomToTopLeftToRight},
        {L"dl",         ReadingDirectionTopToBottomRightToLeft},
        {L"ul",         ReadingDirectionBottomToTopRightToLeft},
        {L"lr-tb",      ReadingDirectionLeftToRightTopToBottom},
        {L"rl-tb",      ReadingDirectionRightToLeftTopToBottom},
        {L"lr-bt",      ReadingDirectionLeftToRightBottomToTop},
        {L"rl-bt",      ReadingDirectionRightToLeftBottomToTop},
        {L"tb-lr",      ReadingDirectionTopToBottomLeftToRight},
        {L"bt-lr",      ReadingDirectionBottomToTopLeftToRight},
        {L"tb-rl",      ReadingDirectionTopToBottomRightToLeft},
        {L"bt-rl",      ReadingDirectionBottomToTopRightToLeft},
        {L"undefined",  ReadingDirectionUndefined},
    };

    const FormattingCode g_GlyphOrientationModeCodes[] =
    {
        {L"default",    GlyphOrientationModeDefault},
        {L"stacked",    GlyphOrientationModeStacked},
        {L"upright",    GlyphOrientationModeUpright},
        {L"rotated",    GlyphOrientationModeRotated},
        {L"cw0",        GlyphOrientationModeLeftToRightTopToBottom},
        {L"cw90",       GlyphOrientationModeTopToBottomRightToLeft},
        {L"cw180",      GlyphOrientationModeRightToLeftBottomToTop},
        {L"cw270",      GlyphOrientationModeBottomToTopLeftToRight},
        {L"rd",         GlyphOrientationModeLeftToRightTopToBottom},
        {L"ld",         GlyphOrientationModeRightToLeftTopToBottom},
        {L"ru",         GlyphOrientationModeLeftToRightBottomToTop},
        {L"lu",         GlyphOrientationModeRightToLeftBottomToTop},
        {L"dr",         GlyphOrientationModeTopToBottomLeftToRight},
        {L"ur",         GlyphOrientationModeBottomToTopLeftToRight},
        {L"dl",         GlyphOrientationModeTopToBottomRightToLeft},
        {L"ul",         GlyphOrientationModeBottomToTopRightToLeft},
        {L"undefined",  GlyphOrientationModeUndefined},
    };

    const FormattingCode g_BooleanCodes[] =
    {
        {L"false",      false},
        {L"true",       true},
        {L"f",          false},
        {L"t",          true},
        {L"0",          false},
        {L"1",          true},
        {L"yes",        false},
        {L"no",         true},
    };

    int32_t GetFormattingCode(
        const FormattingCode* formattingCodes,
        size_t formattingCodesCount,
        const wchar_t* name
        )
    {
        // Linear search for matching name.
        for (uint32_t i = 0; i < formattingCodesCount; ++i)
        {
            if (wcscmp(formattingCodes[i].name, name) == 0)
            {
                return formattingCodes[i].code;
            }
        }

        return FormattingCode::NoMatch;
    }

    void PushFormattedRun(
        uint32_t textPositionEnd,
        IN OUT std::vector<TextAnalysis::LinkedRun>& runs,
        IN OUT TextAnalysis::LinkedRun& run
        )
    {
        if (textPositionEnd > run.textStart)
        {
            runs.push_back(run);
            TextAnalysis::LinkedRun& lastRun = runs.back();
            lastRun.nextRunIndex             = static_cast<uint32_t>(runs.size());
            lastRun.textLength               = textPositionEnd - run.textStart;
            run.textStart                    = textPositionEnd;
        }
    }
}


STDMETHODIMP FlowLayout::CreateFormattedRuns() throw()
{
    HRESULT hr = S_OK;

    try
    {
        text_.reserve(formattedText_.size());
        text_.clear();
        runs_.clear();

        TextAnalysis::LinkedRun run;
        run.textStart = 0;
        run.readingDirection = ReadingDirectionUndefined;
        run.glyphOrientationMode = GlyphOrientationModeUndefined;
        run.useLineGap = true;
        uint32_t textPositionEnd = 0;

        const wchar_t openingEscapeCharacter = '{';
        const wchar_t closingEscapeCharacter = '}';

        const uint32_t formattedTextLength = static_cast<uint32_t>(formattedText_.size());
        const wchar_t* formattedTextStart = formattedText_.c_str();
        const wchar_t* formattedTextEnd = formattedTextStart + formattedTextLength;

        // Read the formatted string in segments.
        for (uint32_t segmentStartPosition = 0, segmentEndPosition = 0;
             segmentStartPosition < formattedTextLength;
             segmentStartPosition = segmentEndPosition
             )
        {
            // Find the start and end of the next segment of text (either plain text or formatting code).
            const bool isPlainText      = (formattedTextStart[segmentStartPosition] != openingEscapeCharacter);
            const wchar_t* segmentStart = &formattedTextStart[segmentStartPosition];
            const wchar_t* segmentEnd   = std::find(segmentStart,
                                                    formattedTextEnd,
                                                    isPlainText ? openingEscapeCharacter : closingEscapeCharacter
                                                    );
            segmentEndPosition = static_cast<uint32_t>(segmentEnd - formattedTextStart);

            if (isPlainText) // copy span of text verbatim
            {
                // Just insert text. We'll update the run later.
                text_.insert(text_.end(), segmentStart, segmentEnd);
            }
            else if (segmentEnd >= formattedTextEnd) // Skip to end of text if no closing character.
            {
                break;
            }
            else // act on embedded code
            {
                ++segmentStart;       // skip '{'
                ++segmentEndPosition; // skip '}'

                // Match formatting code name.
                const wchar_t* nameEnd = std::find(segmentStart, segmentEnd, '=');
                std::wstring nameString(segmentStart, nameEnd);
                std::wstring valueString(nameEnd + (nameEnd < segmentEnd ? 1 : 0), segmentEnd);

                int32_t nameCode = GetFormattingCode(g_FormattingCodes, ARRAYSIZE(g_FormattingCodes), nameString.c_str());

                // Set state according to formatting code.
                switch (nameCode)
                {
                case FormattingCode::ReadingDirection:
                    PushFormattedRun(textPositionEnd, IN OUT runs_, IN OUT run);
                    if (valueString.empty())
                    {
                        run.readingDirection = ReadingDirectionUndefined;
                    }
                    else
                    {
                        int32_t nameCode = GetFormattingCode(
                            g_ReadingDirectionCodes,
                            ARRAYSIZE(g_ReadingDirectionCodes),
                            valueString.c_str()
                            );

                        if (nameCode != FormattingCode::NoMatch)
                            run.readingDirection = ReadingDirection(nameCode);
                    }
                    
                    break;

                case FormattingCode::GlyphOrientation:
                    PushFormattedRun(textPositionEnd, IN OUT runs_, IN OUT run);
                    if (valueString.empty())
                    {
                        run.glyphOrientationMode = GlyphOrientationModeUndefined;
                    }
                    else
                    {
                        int32_t nameCode = GetFormattingCode(
                            g_GlyphOrientationModeCodes,
                            ARRAYSIZE(g_GlyphOrientationModeCodes),
                            valueString.c_str()
                            );

                        if (nameCode != FormattingCode::NoMatch)
                            run.glyphOrientationMode = GlyphOrientationMode(nameCode);
                    }
                    break;

                case FormattingCode::LineGap:
                    PushFormattedRun(textPositionEnd, IN OUT runs_, IN OUT run);
                    if (valueString.empty())
                    {
                        run.useLineGap = true; // default
                    }
                    else
                    {
                        int32_t nameCode = GetFormattingCode(
                            g_BooleanCodes,
                            ARRAYSIZE(g_BooleanCodes),
                            valueString.c_str()
                            );
                        if (nameCode != FormattingCode::NoMatch)
                        {
                            run.useLineGap = !!nameCode;
                        }
                    }
                    break;

                case FormattingCode::OpeningBrace:
                    text_.push_back('{');
                    break;

                case FormattingCode::ClosingBrace:
                    text_.push_back('}');
                    break;

                case FormattingCode::LeftToRightEmbedding:
                    text_.push_back(L'\x202A');
                    break;

                case FormattingCode::RightToLeftEmbedding:
                    text_.push_back(L'\x202B');
                    break;

                case FormattingCode::PopEmbedding:
                    text_.push_back(L'\x202C');
                    break;

                default: // error
                    text_.push_back('?');
                    text_.insert(text_.end(), segmentStart, segmentEnd);
                    text_.push_back('?');
                    break;
                }
            }

            textPositionEnd = static_cast<uint32_t>(text_.size());
        }

        PushFormattedRun(textPositionEnd, IN OUT runs_, IN OUT run);

        // Loop runs back onto themselves.
        runs_.back().nextRunIndex = 0;
    }
    catch (...)
    {
        hr = ExceptionToHResult();
    }

    return hr;
}


STDMETHODIMP FlowLayout::ShapeGlyphRuns(IDWriteTextAnalyzer* textAnalyzer)
{
    // Shapes all the glyph runs in the layout.

    HRESULT hr = S_OK;

    uint32_t textLength = static_cast<uint32_t>(text_.size());

    // Estimate the maximum number of glyph indices needed to hold a string.
    uint32_t estimatedGlyphCount = EstimateGlyphCount(textLength);

    try
    {
        glyphIndices_.resize(estimatedGlyphCount);
        glyphOffsets_.resize(estimatedGlyphCount);
        glyphAdvances_.resize(estimatedGlyphCount);
        glyphClusters_.resize(textLength);

        uint32_t glyphStart = 0;

        // Shape each run separately. This is needed whenever script, locale,
        // or reading direction changes.
        for (uint32_t runIndex = 0; runIndex < runs_.size(); ++runIndex)
        {
            if (treatAsIsolatedCharacters_)
            {
                hr = ShapeSimpleGlyphRun(runIndex, glyphStart);
            }
            else
            {
                hr = ShapeGlyphRun(textAnalyzer, runIndex, glyphStart);
            }

            if (FAILED(hr))
            {
                break;
            }
        }

        glyphIndices_.resize(glyphStart);
        glyphOffsets_.resize(glyphStart);
        glyphAdvances_.resize(glyphStart);
    }
    catch (...)
    {
        hr = ExceptionToHResult();
    }

    return hr;
}


STDMETHODIMP FlowLayout::ShapeGlyphRun(
    IDWriteTextAnalyzer* textAnalyzer,
    uint32_t runIndex,
    IN OUT uint32_t& glyphStart
    )
{
    // Shapes a single run of text into glyphs.
    // Alternately, you could iteratively interleave shaping and line
    // breaking to reduce the number glyphs held onto at once. It's simpler
    // for this demostration to just do shaping and line breaking as two
    // separate processes, but realize that this does have the consequence that
    // certain advanced fonts containing line specific features (like Gabriola)
    // will shape as if the line is not broken.

    HRESULT hr = S_OK;

    try
    {
        TextAnalysis::LinkedRun& run = runs_[runIndex];
        uint32_t textStart           = run.textStart;
        uint32_t textLength          = run.textLength;
        uint32_t maxGlyphCount       = static_cast<uint32_t>(glyphIndices_.size() - glyphStart);
        uint32_t actualGlyphCount    = 0;

        run.glyphStart               = glyphStart;
        run.glyphCount               = 0;

        if (textLength == 0)
            return S_OK; // Nothing to do..

        HRESULT hr = S_OK;

        ////////////////////
        // Allocate space for shaping to fill with glyphs and other information,
        // with about as many glyphs as there are text characters. We'll actually
        // need more glyphs than codepoints if they are decomposed into separate
        // glyphs, or fewer glyphs than codepoints if multiple are substituted
        // into a single glyph. In any case, the shaping process will need some
        // room to apply those rules to even make that determintation.

        if (textLength > maxGlyphCount)
        {
            maxGlyphCount = EstimateGlyphCount(textLength);
            uint32_t totalGlyphsArrayCount = glyphStart + maxGlyphCount;
            glyphIndices_.resize(totalGlyphsArrayCount);
        }

        std::vector<DWRITE_SHAPING_TEXT_PROPERTIES>  textProps(textLength);
        std::vector<DWRITE_SHAPING_GLYPH_PROPERTIES> glyphProps(maxGlyphCount);

        ////////////////////
        // Get the glyphs from the text, retrying if needed.

        DWRITE_FONT_FEATURE verticalFontFeatures[] = {DWRITE_FONT_FEATURE_TAG_VERTICAL_WRITING, 1};
        DWRITE_TYPOGRAPHIC_FEATURES verticalFontFeatureList = {&verticalFontFeatures[0], 1};
        DWRITE_TYPOGRAPHIC_FEATURES emptyFontFeatureList = {nullptr, 0};
        DWRITE_TYPOGRAPHIC_FEATURES const* fontFeatureListPointer = nullptr;
        const uint32_t fontFeatureLengths[1] = {textLength};

        bool useFontFeatures = false;

        GlyphOrientationMode glyphOrientationMode = TextAnalysis::Resolve(run.glyphOrientationMode, glyphOrientationMode_);

        if (TextAnalysis::RequiresVerticalGlyphVariants(glyphOrientationMode, run.isSideways))
        {
            // The mode requires variants, but it's not a sideways run.
            // So explicitly request vertical subtitution.
            if (!run.isSideways)
            {
                fontFeatureListPointer = &verticalFontFeatureList;
                useFontFeatures = true;
            }
        }
        else
        {
            // The mode does not require variants, but it's a sideways run.
            // So explicitly disable vertical subtitution.
            if (run.isSideways)
            {
                fontFeatureListPointer = &emptyFontFeatureList;
                useFontFeatures = true;
            }
        }
        // Otherwise just allow shaping to choose appropriate features respective
        // to the sideways flag.

        int tries = 0;
        do
        {
            hr = textAnalyzer->GetGlyphs(
                &text_[textStart],
                textLength,
                fontFace_,
                run.isSideways,         // isSideways,
                run.isReversed,         // RTL for horizontal, BTT for vertical
                &run.script,
                localeName_,
                (run.isNumberSubstituted) ? numberSubstitution_ : nullptr,
                useFontFeatures ? &fontFeatureListPointer : nullptr, // DWRITE_TYPOGRAPHIC_FEATURES const* features,
                useFontFeatures ? fontFeatureLengths : nullptr, // uint32_t const* featureLengths,
                useFontFeatures ? ARRAYSIZE(fontFeatureLengths) : 0, // featureCount,
                maxGlyphCount,          // maxGlyphCount
                &glyphClusters_[textStart],
                &textProps[0],
                &glyphIndices_[glyphStart],
                &glyphProps[0],
                &actualGlyphCount
                );
            tries++;

            if (hr == E_NOT_SUFFICIENT_BUFFER)
            {
                // Try again using a larger buffer.
                maxGlyphCount                  = EstimateGlyphCount(maxGlyphCount);
                uint32_t totalGlyphsArrayCount = glyphStart + maxGlyphCount;

                glyphProps.resize(maxGlyphCount);
                glyphIndices_.resize(totalGlyphsArrayCount);
            }
            else
            {
                break;
            }
        } while (tries < 2); // We'll give it two chances.

        if (FAILED(hr))
            return hr;

        ////////////////////
        // Get the placement of the all the glyphs.

        glyphAdvances_.resize(std::max(static_cast<size_t>(glyphStart + actualGlyphCount), glyphAdvances_.size()));
        glyphOffsets_.resize( std::max(static_cast<size_t>(glyphStart + actualGlyphCount), glyphOffsets_.size()));

        hr = textAnalyzer->GetGlyphPlacements(
            &text_[textStart],
            &glyphClusters_[textStart],
            &textProps[0],
            textLength,
            &glyphIndices_[glyphStart],
            &glyphProps[0],
            actualGlyphCount,
            fontFace_,
            fontEmSize_,
            run.isSideways,
            run.isReversed,         // RTL for horizontal, BTT for vertical
            &run.script,
            localeName_,
            nullptr,                // features
            nullptr,                // featureRangeLengths
            0,                      // featureRanges
            &glyphAdvances_[glyphStart],
            &glyphOffsets_[glyphStart]
            );

        if (FAILED(hr))
            return hr;

        ////////////////////
        // Certain fonts, like Batang, contain glyphs for hidden control
        // and formatting characters. So we'll want to explicitly force their
        // advance to zero.
        if (run.script.shapes & DWRITE_SCRIPT_SHAPES_NO_VISUAL)
        {
            std::fill(glyphAdvances_.begin() + glyphStart,
                      glyphAdvances_.begin() + glyphStart + actualGlyphCount,
                      0.0f
                      );
        }

        ////////////////////
        // Set the final glyph count of this run and advance the starting glyph.
        run.glyphCount = actualGlyphCount;
        glyphStart    += actualGlyphCount;
    }
    catch (...)
    {
        hr = ExceptionToHResult();
    }

    return hr;
}


STDMETHODIMP FlowLayout::ShapeSimpleGlyphRun(
    uint32_t runIndex,
    IN OUT uint32_t& glyphStart
    )
{
    // Just use direct CMAP.

    HRESULT hr = S_OK;

    try
    {
        TextAnalysis::LinkedRun& run = runs_[runIndex];
        uint32_t textStart           = run.textStart;
        uint32_t textLength          = run.textLength;

        run.glyphStart               = glyphStart;
        run.glyphCount               = 0;
        run.script.script            = 0xFFFF;
        run.script.shapes            = DWRITE_SCRIPT_SHAPES_DEFAULT;

        if (textLength == 0)
            return S_OK; // Nothing to do..

        ////////////////////
        // Convert UTF16 to UTF32/UCS4

        std::vector<uint32_t> codePoints(textLength);
        uint32_t codepointCount = 0;
        wchar_t const* text = &text_[textStart];

        for (uint32_t i = 0; i < textLength; ++i)
        {
            uint32_t trailing, leading = text[i];

            glyphClusters_[textStart + i] = static_cast<uint16_t>(codepointCount);

            if (IsLeadingSurrogate(leading)
            &&  i + 1 < textLength
            &&  IsTrailingSurrogate(trailing = text[i + 1])
            )
            {
                i++;
                glyphClusters_[textStart + i] = static_cast<uint16_t>(codepointCount);
                codePoints[codepointCount++] = MakeUnicodeCodepoint(leading, trailing);
            }
            else
            {
                codePoints[codepointCount++] = leading;
            }
        }

        ////////////////////
        // Get default glyphs.

        uint32_t const glyphCount = codepointCount;
        uint32_t const totalGlyphsArrayCount = glyphStart + glyphCount;
        glyphIndices_.resize(totalGlyphsArrayCount);

        hr = fontFace_->GetGlyphIndices(&codePoints[0], glyphCount, &glyphIndices_[glyphStart]);

        if (FAILED(hr))
            return hr;

        ////////////////////
        // Get the glyph metrics for glyph placement.

        DWRITE_FONT_METRICS fontMetrics;
        fontFace_->GetMetrics(&fontMetrics);

        std::vector<DWRITE_GLYPH_METRICS> glyphRunMetrics(glyphCount);
        hr = GetGlyphMetrics(
            fontFace_,
            DWRITE_MEASURING_MODE_NATURAL,
            fontEmSize_,
            run.isSideways,
            glyphCount,
            &glyphIndices_[glyphStart],
            OUT &glyphRunMetrics[0]
            );

        if (FAILED(hr))
            return hr;

        glyphAdvances_.resize(std::max(static_cast<size_t>(totalGlyphsArrayCount), glyphAdvances_.size()));
        glyphOffsets_.resize( std::max(static_cast<size_t>(totalGlyphsArrayCount), glyphOffsets_.size()));

        for (uint32_t i = 0; i < glyphCount; ++i)
        {
            INT32 advanceDesignUnits = run.isSideways ? glyphRunMetrics[i].advanceHeight : glyphRunMetrics[i].advanceWidth;
            float advanceFloat = advanceDesignUnits * fontEmSize_ / fontMetrics.designUnitsPerEm;
            glyphAdvances_[glyphStart + i] = advanceFloat;
        }

        ////////////////////
        // Get the vertical glyph variants

        GlyphOrientationMode glyphOrientationMode = TextAnalysis::Resolve(run.glyphOrientationMode, glyphOrientationMode_);

        if (TextAnalysis::RequiresVerticalGlyphVariants(glyphOrientationMode, run.isSideways))
        {
            IDWriteFontFace1* fontFace1 = nullptr;
            hr = SafeQueryInterface(fontFace_, &fontFace1);

            if (SUCCEEDED(hr))
            {
                hr = fontFace1->GetVerticalGlyphVariants(glyphCount, &glyphIndices_[glyphStart], &glyphIndices_[glyphStart]);
            }
            SafeRelease(&fontFace1);
            
            if (FAILED(hr))
                return hr;
        }

        ////////////////////
        // Set the final glyph count of this run and advance the starting glyph.
        run.glyphCount = glyphCount;
        glyphStart    += glyphCount;

    }
    catch (...)
    {
        hr = ExceptionToHResult();
    }

    return hr;
}


STDMETHODIMP FlowLayout::FlowText(
    FlowLayoutSource* flowSource,
    FlowLayoutSink* flowSink
    )
{
    // Reflow all the text, from source to sink.

    if (!isTextAnalysisComplete_)
        return E_FAIL;

    HRESULT hr = S_OK;

    // Set initial cluster position to beginning of text.
    ClusterPosition cluster, nextCluster;
    SetClusterPosition(cluster, 0);

    const TextAnalysis::LinkedRun& firstRun = runs_[cluster.runIndex];
    const bool useLineGap = firstRun.useLineGap;

    // Determine the font line height, needed by the flow source.
    DWRITE_FONT_METRICS fontMetrics = {};
    fontFace_->GetMetrics(&fontMetrics);

    int32_t designFontHeight = (fontMetrics.ascent + fontMetrics.descent)
                             + (useLineGap ? fontMetrics.lineGap : 0);

    float fontHeight = designFontHeight * fontEmSize_ / fontMetrics.designUnitsPerEm;

    // Get ready for series of glyph runs.
    hr = flowSink->Prepare(static_cast<uint32_t>(glyphIndices_.size()));

    if (SUCCEEDED(hr))
    {
        FlowLayoutSource::RectF rect;
        uint32_t textLength = static_cast<uint32_t>(text_.size());

        // Iteratively pull rect's from the source,
        // and push as much text will fit to the sink.
        while (cluster.textPosition < textLength)
        {
            // Pull the next rect from the source.
            if (FAILED(flowSource->GetNextRect(fontHeight, readingDirection_, &rect)))
                break;

            if (rect.right <= rect.left && rect.bottom <= rect.top)
                break; // Stop upon reaching zero sized rects.

            // Determine length of line.
            float uSize = (readingDirection_ & ReadingDirectionPrimaryAxis)
                        ? rect.bottom - rect.top
                        : rect.right  - rect.left;

            if (uSize >= 0)
            {
                // Fit as many clusters between breakpoints that will go in.
                if (FAILED(FitText(cluster, textLength, uSize, &nextCluster)))
                    break;

                // Push the glyph runs to the sink.
                if (FAILED(ProduceGlyphRuns(flowSink, rect, cluster, nextCluster)))
                    break;

                cluster = nextCluster;
            }
        }
    }

    return hr;
}


STDMETHODIMP FlowLayout::FitText(
    const ClusterPosition& clusterStart,
    uint32_t textEnd,
    float maxWidth,
    OUT ClusterPosition* clusterEnd
    )
{
    // Fits as much text as possible into the given width,
    // using the clusters and advances returned by DWrite.

    ////////////////////////////////////////
    // Set the starting cluster to the starting text position,
    // and continue until we exceed the maximum width or hit
    // a hard break.
    ClusterPosition cluster(clusterStart);
    ClusterPosition nextCluster(clusterStart);
    uint32_t validBreakPosition = cluster.textPosition;
    uint32_t bestBreakPosition  = cluster.textPosition;
    float textWidth             = 0;

    while (cluster.textPosition < textEnd)
    {
        // Use breakpoint information to find where we can safely break words.
        AdvanceClusterPosition(nextCluster);
        const DWRITE_LINE_BREAKPOINT breakpoint = breakpoints_[nextCluster.textPosition - 1];

        // Check whether we exceeded the amount of text that can fit,
        // unless it's whitespace, which we allow to flow beyond the end.

        textWidth += GetClusterRangeWidth(cluster, nextCluster);
        if (textWidth > maxWidth && !breakpoint.isWhitespace)
        {
            // Want a minimum of one cluster.
            if (validBreakPosition > clusterStart.textPosition)
                break;
        }

        validBreakPosition = nextCluster.textPosition;

        if (treatAsIsolatedCharacters_ && textWidth >= maxWidth)
        {
            break;
        }

        // See if we can break after this character cluster, and if so,
        // mark it as the new potential break point.
        if (breakpoint.breakConditionAfter != DWRITE_BREAK_CONDITION_MAY_NOT_BREAK)
        {
            bestBreakPosition = validBreakPosition;
            if (breakpoint.breakConditionAfter == DWRITE_BREAK_CONDITION_MUST_BREAK)
                break; // we have a hard return, so we've fit all we can.
        }
        cluster = nextCluster;
    }

    ////////////////////////////////////////
    // Want last best position that didn't break a word, but if that's not available,
    // fit at least one cluster (emergency line breaking).
    if (bestBreakPosition == clusterStart.textPosition)
        bestBreakPosition =  validBreakPosition;

    SetClusterPosition(cluster, bestBreakPosition);

    *clusterEnd = cluster;

    return S_OK;
}


STDMETHODIMP FlowLayout::ProduceGlyphRuns(
    FlowLayoutSink* flowSink,
    const FlowLayoutSource::RectF& rect,
    const ClusterPosition& clusterStart,
    const ClusterPosition& clusterEnd
    ) const throw()
{
    // Produce a series of glyph runs from the given range
    // and send them to the sink. If the entire text fit
    // into the rect, then we'll only pass on a single glyph
    // run.

    HRESULT hr = S_OK;

    const bool isVertical = (readingDirection_ & ReadingDirectionPrimaryAxis) != 0;
    const bool isReversedPrimaryDirection = (readingDirection_ & ReadingDirectionPrimaryProgression) != 0;

    // Determine length of line.
    const float uSize = (readingDirection_ & ReadingDirectionPrimaryAxis)
                      ? rect.bottom - rect.top
                      : rect.right  - rect.left;

    ////////////////////////////////////////
    // Figure out how many runs we cross, because this is the number
    // of distinct glyph runs we'll need to reorder visually.

    uint32_t runIndexEnd = clusterEnd.runIndex;
    if (clusterEnd.textPosition > runs_[runIndexEnd].textStart)
        ++runIndexEnd; // Only partially cover the run, so round up.

    // Fill in mapping from visual run to logical sequential run.
    uint32_t bidiOrdering[100];
    uint32_t totalRuns = runIndexEnd - clusterStart.runIndex;
    totalRuns = std::min(totalRuns, static_cast<uint32_t>(ARRAYSIZE(bidiOrdering)));

    ProduceBidiOrdering(
        clusterStart.runIndex,
        totalRuns,
        &bidiOrdering[0]
        );

    ////////////////////////////////////////
    // Ignore any trailing whitespace

    // Look backward from end until we find non-space.
    uint32_t trailingWsPosition = clusterEnd.textPosition;
    for ( ; trailingWsPosition > clusterStart.textPosition; --trailingWsPosition)
    {
        if (!breakpoints_[trailingWsPosition-1].isWhitespace)
            break; // Encountered last significant character.
    }
    // Set the glyph run's ending cluster to the last whitespace.
    ClusterPosition clusterWsEnd(clusterStart);
    SetClusterPosition(clusterWsEnd, trailingWsPosition);

    ////////////////////////////////////////
    // Produce justified advances to reduce the jagged edge.

    std::vector<float> justifiedAdvances;
    hr = ProduceJustifiedAdvances(uSize, clusterStart, clusterWsEnd, justifiedAdvances);
    uint32_t justificationGlyphStart = GetClusterGlyphStart(clusterStart);


    ////////////////////////////////////////
    // Determine starting point for alignment.

    float u         = (isVertical) ? rect.top  : rect.left;
    float v         = (isVertical) ? rect.left : rect.top;
    float ascent    = 0;
    float descent   = 0;
    float central   = 0;

    if (SUCCEEDED(hr))
    {
        DWRITE_FONT_METRICS fontMetrics;
        fontFace_->GetMetrics(&fontMetrics);

        ascent  = (fontMetrics.ascent  * fontEmSize_ / fontMetrics.designUnitsPerEm);
        descent = (fontMetrics.descent * fontEmSize_ / fontMetrics.designUnitsPerEm);
        central = (((fontMetrics.descent + fontMetrics.ascent) / 2) * fontEmSize_ / fontMetrics.designUnitsPerEm);

        if (isReversedPrimaryDirection)
        {
            // For RTL, we neeed the run width to adjust the origin
            // so it starts on the right side.
            uint32_t glyphStart = GetClusterGlyphStart(clusterStart);
            uint32_t glyphEnd   = GetClusterGlyphStart(clusterWsEnd);

            if (glyphStart < glyphEnd)
            {
                float lineWidth = GetClusterRangeWidth(
                    glyphStart - justificationGlyphStart,
                    glyphEnd   - justificationGlyphStart,
                    &justifiedAdvances.front()
                    );
                u += uSize - lineWidth;
            }
        }
    }

    ////////////////////////////////////////
    // Send each glyph run to the sink.

    if (SUCCEEDED(hr))
    {
        for (size_t i = 0; i < totalRuns; ++i)
        {
            const TextAnalysis::Run& run    = runs_[bidiOrdering[i]];
            uint32_t glyphStart             = run.glyphStart;
            uint32_t glyphEnd               = glyphStart + run.glyphCount;

            // If the run is only partially covered, we'll need to find
            // the subsection of glyphs that were fit.
            if (clusterStart.textPosition > run.textStart)
            {
                glyphStart = GetClusterGlyphStart(clusterStart);
            }
            if (clusterWsEnd.textPosition < run.textStart + run.textLength)
            {
                glyphEnd = GetClusterGlyphStart(clusterWsEnd);
            }
            if ((glyphStart >= glyphEnd)
            || (run.script.shapes & DWRITE_SCRIPT_SHAPES_NO_VISUAL))
            {
                // The itemizer told us not to draw this character,
                // either because it was a formatting, control, or other hidden character.
                continue;
            }

            // The run width is needed to know how far to move forward,
            // and to flip the origin for right-to-left text.
            float runWidth = GetClusterRangeWidth(
                                glyphStart - justificationGlyphStart,
                                glyphEnd   - justificationGlyphStart,
                                &justifiedAdvances.front()
                                );

            // Adjust glyph run to the appropriate baseline.

            float vAdjustment;
            if (run.isSideways)
            {
                vAdjustment = central;
            }
            else
            {
                if ((run.glyphOrientation & GlyphOrientationFlipVertical) != 0)
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
                    vAdjustment = descent;
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
                    vAdjustment = ascent;
                }
            }
            float adjustedV = v + vAdjustment;
            float adjustedU = u + ((run.bidiLevel & 1) ? runWidth : 0); // origin starts from right if RTL

            // Flush this glyph run.
            hr = flowSink->SetGlyphRun(
                isVertical ? adjustedV : adjustedU,
                isVertical ? adjustedU : adjustedV,
                glyphEnd - glyphStart,
                &glyphIndices_[glyphStart],
                &justifiedAdvances[glyphStart - justificationGlyphStart],
                &glyphOffsets_[glyphStart],
                fontFace_,
                fontEmSize_,
                run.glyphOrientation,
                run.isReversed,
                run.isSideways
                ); 
            if (FAILED(hr))
                break;

            u += runWidth;
        }
    }

    return hr;
}


void FlowLayout::ProduceBidiOrdering(
    uint32_t spanStart,
    uint32_t spanCount,
    OUT uint32_t* spanIndices     // [spanCount]
    ) const throw()
{
    // Produces an index mapping from sequential order to visual bidi order.
    // The function progresses forward, checking the bidi level of each
    // pair of spans, reversing when needed.
    //
    // See the Unicode technical report 9 for an explanation.
    // http://www.unicode.org/reports/tr9/tr9-17.html 

    // Fill all entries with initial indices
    for (uint32_t i = 0; i < spanCount; ++i)
    {
        spanIndices[i] = spanStart + i;
    }

    if (spanCount <= 1)
        return;

    size_t runStart = 0;
    uint32_t currentLevel = runs_[spanStart].bidiLevel;

    // Rearrange each run to produced reordered spans.
    for (size_t i = 0; i < spanCount; ++i )
    {
        size_t runEnd       = i + 1;
        uint32_t nextLevel  = (runEnd < spanCount)
                            ? runs_[spanIndices[runEnd]].bidiLevel
                            : 0; // past last element

        // We only care about transitions, particularly high to low,
        // because that means we have a run behind us where we can
        // do something.

        if (currentLevel <= nextLevel) // This is now the beginning of the next run.
        {
            if (currentLevel < nextLevel)
            {
                currentLevel = nextLevel;
                runStart     = i + 1;
            }
            continue; // Skip past equal levels, or increasing stairsteps.
        }

        do // currentLevel > nextLevel
        {
            // Recede to find start of the run and previous level.
            uint32_t previousLevel;
            for (;;)
            {
                if (runStart <= 0) // reached front of index list
                {
                    previousLevel = 0; // position before string has bidi level of 0
                    break;
                }
                if (runs_[spanIndices[--runStart]].bidiLevel < currentLevel)
                {
                    previousLevel = runs_[spanIndices[runStart]].bidiLevel;
                    ++runStart; // compensate for going one element past
                    break;
                }
            }

            // Reverse the indices, if the difference between the current and
            // next/previous levels is odd. Otherwise, it would be a no-op, so
            // don't bother.
            if ((std::min(currentLevel - nextLevel, currentLevel - previousLevel) & 1) != 0)
            {
                std::reverse(spanIndices + runStart, spanIndices + runEnd);
            }

            // Descend to the next lower level, the greater of previous and next
            currentLevel = std::max(previousLevel, nextLevel);
        }
        while (currentLevel > nextLevel); // Continue until completely flattened.
    }
}


STDMETHODIMP FlowLayout::ProduceJustifiedAdvances(
    float maxWidth,
    const ClusterPosition& clusterStart,
    const ClusterPosition& clusterEnd,
    OUT std::vector<float>& justifiedAdvances
    ) const throw()
{
    // Performs simple inter-word justification
    // using the breakpoint analysis whitespace property.

    // Copy out default, unjustified advances.
    uint32_t glyphStart = GetClusterGlyphStart(clusterStart);
    uint32_t glyphEnd   = GetClusterGlyphStart(clusterEnd);

    try
    {
        justifiedAdvances.assign(glyphAdvances_.begin() + glyphStart, glyphAdvances_.begin() + glyphEnd);
    }
    catch (...)
    {
        return ExceptionToHResult();
    }

    if (justificationMode_ == JustificationModeNone)
        return S_OK; // Nothing to justify.

    if (glyphEnd - glyphStart == 0)
        return S_OK; // No glyphs to modify.

    if (maxWidth <= 0)
        return S_OK; // Text can't fit anyway.


    ////////////////////////////////////////
    // First, count how many spaces there are in the text range.

    ClusterPosition cluster(clusterStart);
    uint32_t whitespaceCount = 0;

    while (cluster.textPosition < clusterEnd.textPosition)
    {
        if (breakpoints_[cluster.textPosition].isWhitespace)
            ++whitespaceCount;
        AdvanceClusterPosition(cluster);
    }
    if (whitespaceCount <= 0)
        return S_OK; // Can't justify using spaces, since none exist.


    ////////////////////////////////////////
    // Second, determine the needed contribution to each space.

    float lineWidth             = GetClusterRangeWidth(glyphStart, glyphEnd, &glyphAdvances_.front());
    float justificationPerSpace = (maxWidth - lineWidth) / whitespaceCount;

    if (justificationPerSpace  <= 0)
        return S_OK; // Either already justified or would be negative justification.

    if (justificationPerSpace > maxSpaceWidth_)
        return S_OK; // Avoid justification if it would space the line out awkwardly far.


    ////////////////////////////////////////
    // Lastly, adjust the advance widths, adding the difference to each space character.

    cluster = clusterStart;
    while (cluster.textPosition < clusterEnd.textPosition)
    {
        if (breakpoints_[cluster.textPosition].isWhitespace)
            justifiedAdvances[GetClusterGlyphStart(cluster) - glyphStart] += justificationPerSpace;

        AdvanceClusterPosition(cluster);
    }

    return S_OK;
}


////////////////////////////////////////////////////////////////////////////////
// Helpers

HRESULT FlowLayout::CopyToClipboard()
{
    // Copies selected text to clipboard.

    HRESULT hr = E_FAIL;

    DWRITE_TEXT_RANGE selectionRange = {0, static_cast<uint32_t>(formattedText_.size())};
    if (selectionRange.length <= 0)
    {
        return S_OK;
    }

    // Open and empty existing contents.
    if (!OpenClipboard(nullptr))
    {
        hr = HRESULT_FROM_WIN32(GetLastError());
    }
    else
    {
        if (!EmptyClipboard())
        {
            hr = HRESULT_FROM_WIN32(GetLastError());
        }
        else
        {
            // Allocate room for the text
            size_t byteSize         = sizeof(wchar_t) * (selectionRange.length + 1);
            HGLOBAL hClipboardData  = GlobalAlloc(GMEM_DDESHARE | GMEM_ZEROINIT, byteSize);

            if (hClipboardData != nullptr)
            {
                void* memory = GlobalLock(hClipboardData);  // [byteSize] in bytes

                if (memory == nullptr)
                {
                    hr = HRESULT_FROM_WIN32(GetLastError());
                }
                else
                {
                    // Copy text to memory block.
                    const wchar_t* text = formattedText_.c_str();
                    memcpy(memory, &text[selectionRange.startPosition], byteSize);
                    GlobalUnlock(hClipboardData);

                    if (SetClipboardData(CF_UNICODETEXT, hClipboardData) != nullptr)
                    {
                        hClipboardData = nullptr; // system now owns the clipboard, so don't touch it.
                        hr = S_OK;
                    }
                }
                GlobalFree(hClipboardData); // free if failed (still non-null)
            }
            CloseClipboard();
        }
    }

    return hr;
}


HRESULT FlowLayout::PasteFromClipboard()
{
    // Copy Unicode text from clipboard.

    HRESULT hr = E_FAIL;

    if (!OpenClipboard(nullptr))
    {
        hr = HRESULT_FROM_WIN32(GetLastError());
    }
    else
    {
        HGLOBAL hClipboardData = GetClipboardData(CF_UNICODETEXT);

        if (hClipboardData == nullptr)
        {
            hr = HRESULT_FROM_WIN32(GetLastError());
        }
        else
        {
            // Get text and size of text.
            size_t byteSize                 = GlobalSize(hClipboardData);
            void* memory                    = GlobalLock(hClipboardData); // [byteSize] in bytes
            const wchar_t* text             = reinterpret_cast<const wchar_t*>(memory);
            uint32_t textLength             = static_cast<uint32_t>(wcsnlen(text, byteSize / sizeof(wchar_t)));

            if (memory == nullptr)
            {
                hr = HRESULT_FROM_WIN32(GetLastError());
            }
            else
            {
                try
                {
                    formattedText_.assign(text, textLength);
                    hr = S_OK;
                }
                catch (...)
                {
                    hr = ExceptionToHResult();
                }

                GlobalUnlock(hClipboardData);
            }
        }
        CloseClipboard();
    }

    return hr;
}


////////////////////////////////////////////////////////////////////////////////
// Text/cluster navigation.
//
// Since layout should never split text clusters, we want to move ahead whole
// clusters at a time.

void FlowLayout::SetClusterPosition(
    IN OUT ClusterPosition& cluster,
    uint32_t textPosition
    ) const throw()
{
    // Updates the current position and seeks its matching text analysis run.

    cluster.textPosition = textPosition;

    // If the new text position is outside the previous analysis run,
    // find the right one.

    if (textPosition >= cluster.runEndPosition
    ||  !runs_[cluster.runIndex].ContainsTextPosition(textPosition))
    {
        // If we can resume the search from the previous run index,
        // (meaning the new text position comes after the previously
        // seeked one), we can save some time. Otherwise restart from
        // the beginning.

        uint32_t newRunIndex = 0;
        if (textPosition >= runs_[cluster.runIndex].textStart)
        {
            newRunIndex = cluster.runIndex;
        }

        // Find new run that contains the text position.
        newRunIndex = static_cast<uint32_t>(
                            std::find(runs_.begin() + newRunIndex, runs_.end(), textPosition)
                            - runs_.begin()
                            );

        // Keep run index within the list, rather than pointing off the end.
        if (newRunIndex >= runs_.size())
        {
            newRunIndex  = static_cast<uint32_t>(runs_.size() - 1);
        }

        // Cache the position of the next analysis run to efficiently
        // move forward in the clustermap.
        const TextAnalysis::Run& matchingRun    = runs_[newRunIndex];
        cluster.runIndex                        = newRunIndex;
        cluster.runEndPosition                  = matchingRun.textStart + matchingRun.textLength;
    }
}


void FlowLayout::AdvanceClusterPosition(
    IN OUT ClusterPosition& cluster
    ) const throw()
{
    // Looks forward in the cluster map until finding a new cluster,
    // or until we reach the end of a cluster run returned by shaping.
    //
    // Glyph shaping can produce a clustermap where a:
    //  - A single codepoint maps to a single glyph (simple Latin and precomposed CJK)
    //  - A single codepoint to several glyphs (diacritics decomposed into distinct glyphs)
    //  - Multiple codepoints are coalesced into a single glyph.
    //
    uint32_t textPosition = cluster.textPosition;
    uint32_t clusterId    = glyphClusters_[textPosition];

    for (++textPosition; textPosition < cluster.runEndPosition; ++textPosition)
    {
        if (glyphClusters_[textPosition] != clusterId)
        {
            // Now pointing to the next cluster.
            cluster.textPosition = textPosition;
            return;
        }
    }
    if (textPosition == cluster.runEndPosition)
    {
        // We crossed a text analysis run.
        SetClusterPosition(cluster, textPosition);
    }
}


uint32_t FlowLayout::GetClusterGlyphStart(const ClusterPosition& cluster) const throw()
{
    // Maps from text position to corresponding starting index in the glyph array.
    // This is needed because there isn't a 1:1 correspondence between text and
    // glyphs produced.

    uint32_t glyphStart = runs_[cluster.runIndex].glyphStart;

    return (cluster.textPosition < glyphClusters_.size())
        ? glyphStart + glyphClusters_[cluster.textPosition]
        : glyphStart + runs_[cluster.runIndex].glyphCount;
}


float FlowLayout::GetClusterRangeWidth(
    const ClusterPosition& clusterStart,
    const ClusterPosition& clusterEnd
    ) const throw()
{
    // Sums the glyph advances between two cluster positions,
    // useful for determining how long a line or word is.
    return GetClusterRangeWidth(
                GetClusterGlyphStart(clusterStart),
                GetClusterGlyphStart(clusterEnd),
                &glyphAdvances_.front()
                );
}


float FlowLayout::GetClusterRangeWidth(
    uint32_t glyphStart,
    uint32_t glyphEnd,
    const float* glyphAdvances          // [glyphEnd]
    ) const throw()
{
    // Sums the glyph advances between two glyph offsets, given an explicit
    // advances array - useful for determining how long a line or word is.
    return std::accumulate(glyphAdvances + glyphStart, glyphAdvances + glyphEnd, 0.0f);
}
// </SnippetFlowLayoutcpp>
