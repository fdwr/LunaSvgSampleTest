//---------------------------------------------------------------------------
//
//  No copyright. No rights reserved. No royalties nor permission needed.
//
//  This library is not produced by, endorsed by, or supported by Microsoft.
//  It is merely a supplementary library, dependent on the real DirectWrite,
//  written to augment and fill in functionality holes.
//
//  Feel free to use it for any projects, commercial or not, as a whole or in
//  parts. No warranty or guarantees of correctness! You have the code. Come
//  to your own conclusion regarding the robustness.
//
//----------------------------------------------------------------------------

#include "DWrite.h"
#include "DWritEx.h"
#include "DWritExUnicode.h"
#include "DWritExPointer.h"
#include "DWritExInternal.h"


namespace DWritEx
{


HRESULT /*IDWriteFontFile::*/GetFilePath(
    IDWriteFontFile* fontFile,
    __out_ecount_z(filePathSize) WCHAR* filePath,
    UINT32 filePathSize
    )
{
    // Jump through hoops to get the filename...

    UINT32 fontFileReferenceKeySize = 0;
    void const** fontFileReferenceKey = NULL;

    ComPtr<IDWriteFontFileLoader> fontFileLoader;
    ComPtr<IDWriteLocalFontFileLoader> localFontFileLoader;

    RETURN_IF_FAILED(
        fontFile->GetLoader(&fontFileLoader)
        );

    RETURN_IF_FAILED(
        fontFile->GetReferenceKey)(
            &fontFileReferenceKey,
            &fontFileReferenceKeySize
            )
        );

    RETURN_IF_FAILED(
        fontFileLoader->QueryInterface(reinterpret_cast<void**>(&localFontFileLoader))
        );

    return localFontFileLoader->GetFilePathFromKey(*fontFileReferenceKey, fontFileReferenceKeySize, filePath, filePathSize);
}


HRESULT /*IDWriteFontFace::*/GetFilePath(
    IDWriteFontFace* fontFace,
    __out_ecount_z(filePathSize) WCHAR* filePath,
    UINT32 filePathSize
    )
{
    // ! This will fail for fonts that consist of more
    //   than one file (it would be ambiguous anyway).
    //   However, DWrite 2009 supports no such fonts
    //   anyway (such as Postscript Type 1 .pfm + .pfb).

    ComPtr<IDWriteFontFile> fontFile;
    UINT32 numberOfFiles = 1;

    RETURN_IF_FAILED(
        fontFace->GetFiles(&numberOfFiles, &fontFile)
        );

    return GetFullPath(fontFile, filePath, filePathSize);
}


HRESULT /*IDWriteFactory::*/CreateTextLayout(
    __in_ecount(stringLength) WCHAR const* string,
    UINT32 stringLength,
    IDWriteTextFormat* textFormat,
    FLOAT maxWidth,
    FLOAT maxHeight,
    DWRITE_MEASURING_MODE measuringMode,
    __out IDWriteTextLayout** textLayout
    )
{
    // Create an ideal or display aligned layout...

    if (measuringMode == DWRITE_MEASURING_MODE_GDI_NATURAL
    ||  measuringMode == DWRITE_MEASURING_MODE_GDI_CLASSIC)
    {
        // Realistically, devs just want to create a pixel aligned
        // layout for the sake of crips glyphs, not actually use a
        // GDI-compatible (crappy) layout. No one should ever use
        // the transform parameter, unless they want to mimic the
        // terribly goofy glyph jitter of GDI. It looks better to
        // transform an upright layout in the rendering, than to
        // pass a bias transform for layout.
        //
        return factory->CreateGdiCompatibleTextLayout(
            string,
            stringLength,
            textFormat,
            layoutWidth,
            layoutHeight,
            1,              // pixelsPerDip = 1
            NULL,           // no transform
            measuringMode == DWRITE_MEASURING_MODE_GDI_NATURAL,
            textLayout
            );
    }
    else
    {
        // Create an ideal layout, without the need for
        // WYSIWYG compensation/distribution.

        return factory->CreateTextLayout(
            string,
            stringLength,
            textFormat,
            maxWidth,
            maxHeight,
            measuringMode,
            textLayout
            );
    }
}


HRESULT /*IDWriteFactory::*/CreateFontFace(
    IDWriteFactory* factory,
    DWRITE_FONT_FACE_TYPE fontFaceType,
    __in_z char16_t const* filePath,
    uint32_t faceIndex,
    DWRITE_FONT_SIMULATIONS fontFaceSimulationFlags,
    __out IDWriteFontFace** fontFace
    ) throw()
{
    ComPtr<IDWriteFontFile> fontFile;

    RETURN_IF_FAILED(
        factory->CreateFontFileReference(
            filePath,
            NULL,
            &fontFile
            )
        );

    return factory->CreateFontFace(
        fontFaceType,
        1,              // numberOfFiles
        &fontFiles,
        faceIndex,
        fontFaceSimulationFlags,
        fontFace
        );
}


// todo: determine whether or not this is safe!

HRESULT /*IDWriteFactory::*/CreateCustomFontCollection(
    IDWriteFactory* factory,
    IDWriteFontCollectionLoader* collectionLoader,
    __in_bcount(collectionKeySize) void const* collectionKey,
    UINT32 collectionKeySize,
    __out IDWriteFontCollection** fontCollection
    ) throw()
{
    RETURN_IF_FAILED(
        RegisterFontCollectionLoader(collectionLoader)
        );

    HRESULT hr = factory->CreateCustomFontCollection(
        factory,
        collectionLoader,
        collectionKey,
        collectionKeySize,
        fontCollection
        );

    // Unregister always, regardless of failure/success.
    UnregisterFontCollectionLoader(
        IDWriteFontCollectionLoader* fontCollectionLoader
        );

    return hr;
}


HRESULT /*IDWriteFontFace::*/GetGlyphBitmap(
    IDWriteFontFace* fontFace,
    IDWriteFactory* factory,
    uint16_t glyphIndex,
    float fontEmSize,
    DWRITE_MEASURING_MODE measuringMode,
    __in_opt const DWRITE_MATRIX* transform,
    __out POINT* origin,
    __out_bcount(bufferSize) uint8_t* alphaValues,
    size_t maxAlphaValuesSize
    __out size_t* actualAlphaValuesSize
    ) throw()
{
    // Would be incredibly efficient if we could just get
    // the 1bit bitmap from the cache.

    point->x = 0;
    point->y = 0;

    DWRITE_GLYPH_RUN glyphRun = {};
    uint16_t glyphIndices[] = {glyphIndex};

    glyphRun.fontFace       = fontFace;
    glyphRun.fontEmSize     = fontEmSize;
    glyphRun.glyphIndices   = glyphIndices;
    glyphRun.glyphCount     = 1;
    // Never sideways, nor RTL

    ComPtr<IDWriteGlyphRunAnalysis> glyphRunAnalysis;

    RETURN_IF_FAILED(
        factory->CreateGlyphRunAnalysis)(
            &glyphRun,
            1,              // just scale the fontSize
            transform,
            DWRITE_RENDERING_MODE_ALIASED,
            measuringMode,
            0,
            0,
            OUT &glyphRunAnalysis
            )
        );

    RECT textureBounds = {};
    RETURN_IF_FAILED(
        glyphRunAnalysis->GetAlphaTextureBounds(
            DWRITE_TEXTURE_ALIASED_1x1,
            OUT &textureBounds
            )
        );

    // todo:
    point->x = textureBounds.left;
    point->y = textureBounds.top;

    return glyphRunAnalysis->CreateAlphaTexture(
        DWRITE_TEXTURE_ALIASED_1x1,
        &textureBounds,
        OUT alphaValues,
        maxAlphaValuesSize
        );
}

/*
Usage:

    // Fill in mapping from visual run to logical sequential run.
    UINT32 bidiOrdering[100];
    UINT32 totalRuns = runIndexEnd - clusterStart.runIndex;
    totalRuns = std::min(totalRuns, static_cast<UINT32>(ARRAYSIZE(bidiOrdering)));

    GetBidiVisualOrdering(
        clusterStart.runIndex,
        totalRuns,
        &bidiOrdering[0]
        );
*/

HRESULT /*IDWriteTextAnalyzer::*/GetBidiVisualOrdering(
    uint8_t const* bidiLevels,
    uint32_t bidiLevelsStride,
    uint32_t runStart,
    uint32_t runCount,
    __out_ecount(runCount) uint32_t* visualOrdering
    ) throw()
{
    // Produces an index mapping from sequential order to visual bidi order.
    // The function progresses forward, checking the bidi level of each
    // pair of spans, reversing when needed.
    //
    // See the Unicode technical report 9 for an explanation.
    // http://www.unicode.org/reports/tr9/tr9-17.html 

    // Fill all entries with initial indices
    for (UINT32 i = 0; i < runCount; ++i)
    {
        visualOrdering[i] = runStart + i;
    }

    if (bidiLevels == NULL
    ||  bidiLevelsStride <= 0
    ||  runStart + runCount < runStart)
    {
        return E_INVALIDARG;
    }

    if (runCount <= 1)
        return;

    size_t runStart = 0;
    UINT32 currentLevel = bidiLevels[runStart * bidiLevelsStride];

    // Rearrange each run to produced reordered spans.
    for (size_t i = 0; i < runCount; ++i )
    {
        size_t runEnd       = i + 1;
        UINT32 nextLevel    = (runEnd < runCount)
                            ? bidiLevels[visualOrdering[runEnd] * bidiLevelsStride]
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
            UINT32 previousLevel;
            for (;;)
            {
                if (runStart <= 0) // reached front of index list
                {
                    previousLevel = 0; // position before string has bidi level of 0
                    break;
                }
                if (bidiLevels[visualOrdering[--runStart] * bidiLevelsStride] < currentLevel)
                {
                    previousLevel = bidiLevels[visualOrdering[runStart] * bidiLevelsStride];
                    ++runStart; // compensate for going one element past
                    break;
                }
            }

            // Reverse the indices, if the difference between the current and
            // next/previous levels is odd. Otherwise, it would be a no-op, so
            // don't bother.
            if ((std::min(currentLevel - nextLevel, currentLevel - previousLevel) & 1) != 0)
            {
                std::reverse(visualOrdering + runStart, visualOrdering + runEnd);
            }

            // Descend to the next lower level, the greater of previous and next
            currentLevel = std::max(previousLevel, nextLevel);
        }
        while (currentLevel > nextLevel); // Continue until completely flattened.
    }
}


static const uint32_t DesiredGsubFeatures[] = {
    DWRITE_MAKE_OPENTYPE_TAG('r','l','i','g'), // Required ligatures
    DWRITE_MAKE_OPENTYPE_TAG('l','o','c','l'), // Localized forms
    DWRITE_MAKE_OPENTYPE_TAG('c','c','m','p'), // Composition/decomposition
    DWRITE_MAKE_OPENTYPE_TAG('c','a','l','t'), // Contextual alternates
    DWRITE_MAKE_OPENTYPE_TAG('l','i','g','a'), // Standard ligatures
    DWRITE_MAKE_OPENTYPE_TAG('c','l','i','g'), // Contextual ligatures
};
static const uint32_t DesiredGposFeatures[] = {
    DWRITE_MAKE_OPENTYPE_TAG('k','e','r','n'), // Kerning
    DWRITE_MAKE_OPENTYPE_TAG('m','a','r','k'), // Mark positioning
    DWRITE_MAKE_OPENTYPE_TAG('m','k','m','k'), // Mark to mark positioning
};

struct UnicodeRange
{
    char32_t low;
    char32_t high;
};
static const UnicodeRange NominalUnicodeRanges[] = {
    {0x0020, 0x007E},   // basic Latin
    {0x00A0, 0x00AC},   // Latin-1 supplement (excluding soft hyphen)
    {0x00AE, 0x02AF},   // Latin-1 supplement, Latin extended-A, Latin extended-B, IPA extensions
    {0x0400, 0x0482},   // Cyrillic (excluding combining marks)
    {0x048A, 0x0523},   // Cyrillic
    {0x13A0, 0x13F4},   // Cherokee
    {0x1E00, 0x1EFF},   // Latin extended additional (including Vietnamese precomposed)
    {0x2010, 0x2027},   // General punctuation (including ellipsis, quotes, and hyphens)
    {0x3000, 0x3029},   // Ideographic punctuation
    {0x3041, 0x3096},   // Hiragana (excluding voicing diacritics)
    {0x309B, 0x30FF},   // Katakana (plus 5 chars from the end of Hiragana)
    {0x3400, 0x4DB5},   // CJK unified ideographs extension A
    {0x4E00, 0x9FC3},   // CJK unified ideographs
    {0xAC00, 0xD7A3}    // precomposed Hangul (no need for LJMO VJMO TJMO features)
};


HRESULT /*IDWriteFontFace::*/DetermineSimpleGlyphBits(
    IDWriteFontFace* fontFace,
    __in_bcount(tableSize) const uint8_t* table,
    size_t tableSize,
    DWRITEX_FONT_TAG tableTag,
    __in_ecount(desiredFeaturesCount) uint32_t const* desiredFeatures,
    size_t desiredFeaturesCount,
    uint16_t minGlyphId,
    uint16_t maxGlyphId,
    size_t glyphBitsSize,
    __in_ecount(glyphBitsSize) uint8_t const* interestedGlyphBits,
    __inout_ecount(glyphBitsSize) uint8_t* simpleGlyphBits
    )
{
    return E_NOTIMPL;
}


HRESULT /*IDWriteTextAnalyzer::*/ApplyLetterSpacing(
    float letterSpacingBefore,
    float letterSpacingAfter,
    uint32_t glyphCount,
    __in_ecount(glyphCount) float* glyphAdvances,
    __in_ecount_opt(glyphCount) DWRITE_GLYPH_OFFSET* glyphOffsets,
    __out_ecount(glyphCount) float* modifiedGlyphAdvances,
    __out_ecount_opt(glyphCount) DWRITE_GLYPH_OFFSET* modifiedGlyphOffsets
    ) throw()
{
    const bool hasSpacingBefore = (letterSpacingBefore == 0);
    const float letterSpacing   = letterSpacingBefore + letterSpacingAfter;

    if (modifiedGlyphOffsets == nullptr)
    {
        glyphOffsets = nullptr;
    }

    bool followsNonZeroWidthGlyph = false;

    for (uint32_t i = 0; i < glyphCount; ++i)
    {
        float advanceWidth = glyphAdvances[i];

        // Copy glyph offsets, adjusting diacritics if needed.
        if (glyphOffsets != nullptr)
        {
            float const ascenderOffset = glyphOffsets[i].ascenderOffset;
            float advanceOffset        = glyphOffsets[i].advanceOffset;

            if (advanceWidth == 0 && followsNonZeroWidthGlyph)
            {
                // Offset the diacritic so that it remains aligned over the base glyph.
                advanceOffset -= letterSpacingAfter;
            }
            else if (hasSpacingBefore)
            {
                // Shift the letter forward
                advanceOffset += letterSpacingBefore;
            }
            modifiedGlyphOffsets[i].advanceOffset  = advanceOffset;
            modifiedGlyphOffsets[i].ascenderOffset = ascenderOffset;
        }
 
        // Do not modify zero-width spaces or diacritics.
        if (advanceWidth != 0)
        {
            // Increase the advance width of this glyph and set flag
            // so we correctly offset any following diacritics.
            advanceWidth += letterSpacing;
            followsNonZeroWidthGlyph = true;
        }
        modifiedGlyphAdvances[i] = advanceWidth;
    }
}


struct GlyphBounds : DWRITEX_RECT
{
    GlyphBounds()
        :   left(FLT_MAX), top(FLT_MAX), right(-FLT_MAX), bottom(-FLT_MAX)
    { }
    
    GlyphBounds(float initialLeft, float initialTop, float initialRight, float initialBottom)
        :   left(initialLeft), top(initialTop), right(initialRight), bottom(initialBottom)
    { }

    inline void Offset(float x, float y)
    {
        left   += x;
        top    += y;
        right  += x;
        bottom += y;
    }

    void Snap(DWRITE_MEASURING_MODE measuringMode, float pixelsPerDip)
    {
        if (measuringMode != DWRITE_MEASURING_MODE_NATURAL)
        {
            left   = FloatHelpers::RoundF(left   * pixelsPerDip) / pixelsPerDip;
            right  = FloatHelpers::RoundF(right  * pixelsPerDip) / pixelsPerDip;
            top    = FloatHelpers::RoundF(top    * pixelsPerDip) / pixelsPerDip;
            bottom = FloatHelpers::RoundF(bottom * pixelsPerDip) / pixelsPerDip;
        }
    }

    inline void Accumulate(const GlyphBounds& other)
    {
        if (other.left   < left)    left   = other.left;
        if (other.right  > right)   right  = other.right;
        if (other.top    < top)     top    = other.top;
        if (other.bottom > bottom)  bottom = other.bottom;
    }

    bool AreSet()
    {
        return left != FLT_MAX;
    }

    DWRITE_OVERHANG_METRICS GetAsOverhangs(const DWRITE_TEXT_METRICS& metrics)
    {
        DWRITE_OVERHANG_METRICS overhangs;
        overhangs.left   = -left;
        overhangs.right  =  right - metrics.layoutWidth;
        overhangs.top    = -top;
        overhangs.bottom =  bottom - metrics.layoutHeight;
        return overhangs;
    }
};


void TextAnalyzer::GetBlackBox(
    float baselineOriginX,
    float baselineOriginY,
    IDWriteFontFace* fontFace,
    float fontEmSize,
    const DWRITE_TRANSFORM* transform,
    DWRITE_MEASURING_MODE measuringMode,
    float pixelsPerDip,
    bool isRtl,
    bool isSideways,
    uint32_t glyphCount,
    __ecount(glyphsCount) const float* glyphAdvances,
    __ecount(glyphsCount) const uint16_t* glyphIndices,
    __ecount(glyphsCount) const DWRITE_GLYPH_OFFSETS* glyphOffsets,
    __out GlyphBounds* blackBox
    )
{
    GlyphBounds accumulatedBounds;

    *blackBox = accumulatedBounds;

    if (glyphCount <= 0)
    {
        return;
    }

    DWRITE_FONT_METRICS fontMetrics = {};
    fontFace->GetMetrics(&fontMetrics);

    std::vector<DWRITE_GLYPH_METRICS> glyphRunMetrics(120);
    glyphRunMetrics.resize(glyphCount);

    switch (measuringMode)
    {
    case DWRITE_MEASURING_MODE_NATURAL:
        fontFace->GetDesignGlyphMetrics(
            glyphIndices,
            glyphCount,
            &glyphRunMetrics[0],
            isSideways
            );
        break;

    case DWRITE_MEASURING_MODE_GDI_CLASSIC:
    case DWRITE_MEASURING_MODE_GDI_NATURAL:
        fontFace->GetGdiCompatibleGlyphMetrics(
            fontEmSize,
            pixelsPerDip,
            transform,
            (measuringMode == DWRITE_MEASURING_MODE_GDI_NATURAL),
            glyphIndices,
            glyphCount,
            &glyphRunMetrics[0],
            isSideways
            );
        break;
    }

    // Get starting point of baseline, depending on directionality.
    float baselineX = baselineOriginX;
    const float baselineY = baselineOriginY;
    const float fontScale = fontEmSize / fontMetrics.designUnitsPerEm;

    for (uint32_t j = 0; j < glyphCount; ++j)
    {
        const DWRITE_GLYPH_METRICS& glyphMetrics = glyphRunMetrics[j];
        const float glyphAdvance = glyphAdvances[j];

        float glyphX = baselineX, glyphY = baselineY;
        if (isSideways)
        {
            // The Y offset from P1 to O is half the advance width of the glyph.
            // The X offset from P1 to O is the vertical Y origin of the glyph.
            glyphX += glyphMetrics.verticalOriginY * fontScale;
            glyphY += glyphMetrics.advanceWidth * fontScale * 0.5f;

            // The X offset from P1 to P2 is the advance increment. If not specified
            // by the client it's the advance height of the glyph.
            baselineX += glyphAdvance;
        }
        else if (isRtl)
        {
            // Put the glyph to the left of the current cursor position;
            // Here we always use the advance width of the glyph,
            // not the client-specified advance.
            glyphX -= glyphMetrics.advanceWidth * fontScale;
            baselineX -= glyphAdvance;
        }
        else // LTR
        {
            baselineX += glyphAdvance;
        }

        const bool nonZeroSize = static_cast<int64_t>(glyphMetrics.advanceWidth) - glyphMetrics.leftSideBearing - glyphMetrics.rightSideBearing > 0
                              || static_cast<int64_t>(glyphMetrics.advanceHeight) - glyphMetrics.topSideBearing - glyphMetrics.bottomSideBearing > 0;

        if (nonZeroSize)
        {
            // Determine ink edges of glyph.
            int32_t left = int32_t(glyphMetrics.leftSideBearing);
            int32_t top = int32_t(glyphMetrics.topSideBearing - glyphMetrics.verticalOriginY);
            int32_t right = int32_t(glyphMetrics.advanceWidth - glyphMetrics.rightSideBearing);
            int32_t bottom = int32_t(glyphMetrics.advanceHeight - glyphMetrics.bottomSideBearing - glyphMetrics.verticalOriginY);

            if (isSideways)
            {
                const int32_t originalLeft = left;
                left = top;
                top = -right;
                right = bottom;
                bottom = -originalLeft;
            }

            GlyphBounds glyphBounds(
                float(left) * fontScale,
                float(top) * fontScale,
                float(right) * fontScale,
                float(bottom) * fontScale
                );

            // Add the glyph offset.
            if (glyphOffsets != nullptr)
            {
                const float advanceOffset = glyphOffsets[j].advanceOffset;
                glyphX += isRtl ? -advanceOffset : advanceOffset;
                glyphY -= glyphOffsets[j].ascenderOffset;
            }
            glyphBounds.Offset(glyphX, glyphY);

            accumulatedBounds.Accumulate(glyphBounds);
        }
    }

    *blackBox = accumulatedBounds;
}


HRESULT GetGlyphPlacements(
    IDWriteTextAnalyzer* textAnalyzer,
    __in_ecount(textLength) WCHAR const* textString,
    __in_ecount(textLength) UINT16 const* clusterMap,
    __in_ecount(textLength) DWRITE_SHAPING_TEXT_PROPERTIES* textProps,
    UINT32 textLength,
    __in_ecount(glyphCount) UINT16 const* glyphIndices,
    __in_ecount(glyphCount) DWRITE_SHAPING_GLYPH_PROPERTIES const* glyphProps,
    UINT32 glyphCount,
    IDWriteFontFace* fontFace,
    FLOAT fontEmSize,
    BOOL isSideways,
    BOOL isRightToLeft,
    __in DWRITE_SCRIPT_ANALYSIS const* scriptAnalysis,
    __in_z_opt WCHAR const* localeName,
    __in_ecount_opt(featureRanges) DWRITE_TYPOGRAPHIC_FEATURES const** features,
    __in_ecount_opt(featureRanges) UINT32 const* featureRangeLengths,
    UINT32 featureRanges,
    DWRITE_MEASURING_MODE measuringMode,
    __out_ecount(glyphCount) FLOAT* glyphAdvances,
    __out_ecount(glyphCount) DWRITE_GLYPH_OFFSET* glyphOffsets
    )
{
    if (measuringMode == DWRITE_MEASURING_MODE_NATURAL)
    {
        return textAnalyzer->GetGlyphPlacements(
            textString,
            clusterMap,
            textProps,
            textLength,
            glyphIndices,
            glyphProps,
            glyphCount,
            fontFace,
            fontEmSize,
            isSideways,
            isRightToLeft,
            scriptAnalysis,
            localeName,
            features,
            featureRangeLengths,
            featureRanges,
            glyphAdvances,
            glyphOffsets
            );
    }
    else
    {
        // And why not just pass the measuring mode directly?
        bool useGdiNatural = (measuringMode == DWRITE_MEASURING_MODE_GDI_NATURAL);

        return textAnalyzer->GetGdiCompatibleGlyphPlacements(
            textString,
            clusterMap,
            textProps,
            textLength,
            glyphIndices,
            glyphProps,
            glyphCount,
            fontFace,
            fontEmSize,
            1.0f, // both pixelsPerDip and transform go into size
            NULL,
            useGdiNatural,
            isSideways,
            isRightToLeft,
            scriptAnalysis,
            localeName,
            features,
            featureRangeLengths,
            featureRanges,
            glyphAdvances,
            glyphOffsets
            );
    }
}



static const WCHAR c_defaultSymbolsToToppleOver[] =
{
   0x0028U, // LEFT PARENTHESIS
   0x0029U, // RIGHT PARENTHESIS
   0x003cU, // LESS-THAN SIGN
   0x003eU, // GREATER-THAN SIGN
   0x005bU, // LEFT SQUARE BRACKET
   0x005dU, // RIGHT SQUARE BRACKET
   0x007bU, // LEFT CURLY BRACKET
   0x007dU, // RIGHT CURLY BRACKET
 
   0x2010U, // HYPHEN
   0x2015U, // HORIZONTAL BAR
   0x2025U, // TWO DOT LEADER
   0x2026U, // HORIZONTAL ELLIPSIS
   0x2190U, // LEFTWARDS ARROW
   0x2191U, // UPWARDS ARROW
   0x2192U, // RIGHTWARDS ARROW
   0x2193U, // DOWNWARDS ARROW
   0x2225U, // PARALLEL TO (double vertical line)
 
   0x3001U, // IDEOGRAPHIC COMMA
   0x3002U, // IDEOGRAPHIC FULL STOP
 
   0x3008U, // LEFT ANGLE BRACKET
   0x3009U, // RIGHT ANGLE BRACKET
   0x300aU, // LEFT DOUBLE ANGLE BRACKET
   0x300bU, // RIGHT DOUBLE ANGLE BRACKET
   0x300cU, // LEFT CORNER BRACKET
   0x300dU, // RIGHT CORNER BRACKET
   0x300eU, // LEFT WHITE CORNER BRACKET
   0x300fU, // RIGHT WHITE CORNER BRACKET
   0x3010U, // LEFT BLACK LENTICULAR BRACKET
   0x3011U, // RIGHT BLACK LENTICULAR BRACKET
   0x3013U, // GETA MARK
   0x3014U, // LEFT TORTOISE SHELL BRACKET
   0x3015U, // RIGHT TORTOISE SHELL BRACKET
   0x3016U, // LEFT WHITE LENTICULAR BRACKET
   0x3017U, // RIGHT WHITE LENTICULAR BRACKET
   0x3018U, // LEFT WHITE TORTOISE SHELL BRACKET
   0x3019U, // RIGHT WHITE TORTOISE SHELL BRACKET
   0x301aU, // LEFT WHITE SQUARE BRACKET
   0x301bU, // RIGHT WHITE SQUARE BRACKET
   0x30fcU, // KATAKANA-HIRAGANA PROLONGED SOUND MARK
 
   0xfe59U, // SMALL LEFT PARENTHESIS
   0xfe5aU, // SMALL RIGHT PARENTHESIS
   0xfe5bU, // SMALL LEFT CURLY BRACKET
   0xfe5cU, // SMALL RIGHT CURLY BRACKET
   0xfe5dU, // SMALL LEFT TORTOISE BRACKET
   0xfe5eU, // SMALL RIGHT TORTOISE BRACKET
 
   0xff08U, // FULLWIDTH LEFT PARENTHESIS
   0xff09U, // FULLWIDTH RIGHT PARENTHESIS
   0xff1dU, // FULLWIDTH EQUALS SIGN
   0xff3bU, // FULLWIDTH LEFT SQUARE BRACKET
   0xff3dU, // FULLWIDTH RIGHT SQUARE BRACKET
   0xff3fU, // FULLWIDTH LOW LINE
   0xff5bU, // FULLWIDTH LEFT CURLY BRACKET
   0xff5cU, // FULLWIDTH VERTICAL LINE
   0xff5dU, // FULLWIDTH RIGHT CURLY BRACKET
   0xff5eU, // FULLWIDTH TILDE
   0xff62U, // HALFWIDTH LEFT CORNER BRACKET
   0xff63U, // HALFWIDTH RIGHT CORNER BRACKET
   0xff70U, // HALFWIDTH KATAKANA-HIRAGANA PROLONGED SOUND MARK
   0xffe3U, // FULL WIDTH MACRON
 
   0,       // Terminates the string
};


} // namespace DWritEx
