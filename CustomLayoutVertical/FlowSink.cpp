// <SnippetFlowSinkcpp>
// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// Copyright (c) Microsoft Corporation. All rights reserved
//
// Contents:    Sink interface for where text is placed.
//
//----------------------------------------------------------------------------
#include "common.h"
#include "FlowSink.h"
#include "TextAnalysis.h"


namespace
{
    void GetGlyphOrientationTransform(
        __in  GlyphOrientation glyphOrientation,
        __in  bool isSideways,
        __out DWRITE_MATRIX* transform
        )
    {
        if (isSideways)
        {
            // The world transform is an additional 90 degrees clockwise from the
            // glyph orientation when the sideways flag is set. So choose a
            // transform that compensates for that.
            glyphOrientation = TextAnalysis::UndoSidewaysOrientation(glyphOrientation);
        }

        const static DWRITE_MATRIX octantMatrices[8] = {
            //    0 RD      1 LD      2 RU      3 LU       4 DR        5 UR        6 DL        7 UL
            //  888888      888888  88    88  88    88  8888888888    88    88  8888888888  88    88
            //  88    88  88    88  88   88    88   88  88  88      88  8888        88  88    8888  88
            //  888888      888888  888888      888888  88  8888    88  88        8888  88      88  88
            //  88   88    88   88  88    88  88    88    88    88  8888888888  88    88    8888888888
            //  88    88  88    88  888888      888888
            //
            /* 0 RD CW0   */  { 1, 0, 0, 1, 0, 0}, // translation is always zero
            /* 1 LD FH    */  {-1, 0, 0, 1, 0, 0},
            /* 2 RU FV    */  { 1, 0, 0,-1, 0, 0},
            /* 3 LU CW180 */  {-1, 0, 0,-1, 0, 0},
            /* 4 DR       */  { 0, 1, 1, 0, 0, 0},
            /* 5 UR CW270 */  { 0,-1, 1, 0, 0, 0},
            /* 6 DL CW90  */  { 0, 1,-1, 0, 0, 0},
            /* 7 UL       */  { 0,-1,-1, 0, 0, 0},
        };

        *transform = octantMatrices[glyphOrientation & 7];
    }
}


STDMETHODIMP FlowLayoutSink::Reset()
{
    glyphRuns_.clear();
    glyphIndices_.clear();
    glyphAdvances_.clear();
    glyphOffsets_.clear();

    return S_OK;
}


STDMETHODIMP FlowLayoutSink::Prepare(uint32_t glyphCount)
{
    try
    {
        // Reserve a known glyph count up front.
        glyphIndices_.reserve (glyphCount);
        glyphAdvances_.reserve(glyphCount);
        glyphOffsets_.reserve (glyphCount);
    }
    catch (...)
    {
        return ExceptionToHResult();
    }

    return S_OK;
}


STDMETHODIMP FlowLayoutSink::SetGlyphRun(
    float x,
    float y,
    uint32_t glyphCount,
    const uint16_t* glyphIndices,               // [glyphCount]
    const float* glyphAdvances,                 // [glyphCount]
    const DWRITE_GLYPH_OFFSET* glyphOffsets,    // [glyphCount]
    IDWriteFontFace* fontFace,
    float fontEmSize,
    UINT8 glyphOrientation,
    bool isReversed,
    bool isSideways
    )
{
    // Append this glyph run to the list.

    try
    {
        glyphRuns_.resize(glyphRuns_.size() + 1);
        CustomGlyphRun& glyphRun = glyphRuns_.back();
        uint32_t glyphStart = static_cast<uint32_t>(glyphAdvances_.size());

        glyphIndices_.insert (glyphIndices_.end(),  glyphIndices,  glyphIndices  + glyphCount);
        glyphAdvances_.insert(glyphAdvances_.end(), glyphAdvances, glyphAdvances + glyphCount);
        glyphOffsets_.insert (glyphOffsets_.end(),  glyphOffsets,  glyphOffsets  + glyphCount);

        glyphRun.x                  = x;
        glyphRun.y                  = y;
        glyphRun.glyphOrientation   = glyphOrientation;
        glyphRun.glyphStart         = glyphStart;
        glyphRun.isSideways         = isSideways;
        glyphRun.isReversed         = isReversed;
        glyphRun.glyphCount         = glyphCount;
        glyphRun.fontEmSize         = fontEmSize;
        SafeSet(&glyphRun.fontFace, fontFace);
    }
    catch (...)
    {
        return ExceptionToHResult();
    }

    return S_OK;
}


STDMETHODIMP FlowLayoutSink::DrawGlyphRuns(
    IDWriteBitmapRenderTarget* renderTarget,
    IDWriteRenderingParams* renderingParams,
    COLORREF textColor
    ) const
{
    // Just iterate through all the saved glyph runs
    // and have DWrite to draw each one.

    HRESULT hr = S_OK;

    if (dwriteFactory_ == nullptr)
    {
        return E_FAIL;
    }

    if (textAnalyzer_ == nullptr)
    {
        IDWriteTextAnalyzer* textAnalyzer0 = nullptr;
        hr = dwriteFactory_->CreateTextAnalyzer(&textAnalyzer0);

        if (SUCCEEDED(hr))
        {
            hr = textAnalyzer0->QueryInterface(__uuidof(*textAnalyzer_), reinterpret_cast<void**>(&textAnalyzer_));
        }

        SafeRelease(&textAnalyzer0);
    }

    if (SUCCEEDED(hr))
    {
        DWRITE_MATRIX transform = { 0, 1,-1, 0, 0, 0};

        for (size_t i = 0; i < glyphRuns_.size(); ++i)
        {
            DWRITE_GLYPH_RUN glyphRun;
            const CustomGlyphRun& customGlyphRun = glyphRuns_[i];

            if (customGlyphRun.glyphCount == 0)
                continue;

            // Massage the custom glyph run to something directly
            // digestable by DrawGlyphRun.
            customGlyphRun.Convert(
                &glyphIndices_ [0],
                &glyphAdvances_[0],
                &glyphOffsets_ [0],
                &glyphRun
                );

            #ifdef USE_DWRITE_GLYPH_ORIENTATIONS // DWrite has only four orientation enums.

            // Mapping from small orientation back to DWrite compatible angle (0..3).
            const static DWRITE_GLYPH_ORIENTATION_ANGLE glyphOrientationAngle[] = {
                DWRITE_GLYPH_ORIENTATION_ANGLE_0_DEGREES,   // LTR TTB
                DWRITE_GLYPH_ORIENTATION_ANGLE_0_DEGREES,   // RTL TTB * no mapping, so just zero
                DWRITE_GLYPH_ORIENTATION_ANGLE_0_DEGREES,   // LTR BTT * no mapping, so just zero
                DWRITE_GLYPH_ORIENTATION_ANGLE_180_DEGREES, // RTL BTT
                DWRITE_GLYPH_ORIENTATION_ANGLE_0_DEGREES,   // TTB LTR * no mapping, so just zero
                DWRITE_GLYPH_ORIENTATION_ANGLE_270_DEGREES, // BTT LTR
                DWRITE_GLYPH_ORIENTATION_ANGLE_90_DEGREES,  // TTB RTL
                DWRITE_GLYPH_ORIENTATION_ANGLE_0_DEGREES,   // BTT RTL * no mapping, so just zero
            };

            // This call is valid for both horizontal and vertical
            // (though it's a nop for horizontal, returning identity).
            textAnalyzer_->GetGlyphOrientationTransform(
                glyphOrientationAngle[customGlyphRun.glyphOrientation],
                customGlyphRun.isSideways,
                &transform
                );

            #else // Support all possible orientations

            // Full orientation support 0..7, including mirrored orientations.
            GetGlyphOrientationTransform(
                GlyphOrientation(customGlyphRun.glyphOrientation),
                customGlyphRun.isSideways,
                &transform
                );

            #endif

            transform.dx = customGlyphRun.x;
            transform.dy = customGlyphRun.y;

            // Align the baseline to nearest pixel for glyph clarity.
            // Otherwise the glyph is blurry on fractional pixels, which is
            // fine for animation or really small text, but not so good for
            // reading-sized static text.
            if (!customGlyphRun.isSideways)
            {
                if (customGlyphRun.glyphOrientation & GlyphOrientationFlipDiagonal)
                {
                    transform.dx = floor(transform.dx + 0.5f); // vertical baseline
                }
                else
                {
                    transform.dy = floor(transform.dy + 0.5f); // horizontal baseline
                }
            }
            renderTarget->SetCurrentTransform(&transform);

            hr = renderTarget->DrawGlyphRun(
                    0, // x, use transform dx instead
                    0, // y, use transform dy instead
                    DWRITE_MEASURING_MODE_NATURAL,
                    &glyphRun,
                    renderingParams,
                    textColor,
                    nullptr // don't need blackBoxRect
                    );
            if (FAILED(hr))
                break;
        }
    }

    return hr;
}


void FlowLayoutSink::CustomGlyphRun::Convert(
    const uint16_t* glyphIndices,               // [this->glyphCount]
    const float* glyphAdvances,                 // [this->glyphCount]
    const DWRITE_GLYPH_OFFSET* glyphOffsets,    // [this->glyphCount]
    OUT DWRITE_GLYPH_RUN* glyphRun
    ) const throw()
{
    // Populate the DWrite glyph run.

    glyphRun->glyphIndices  = &glyphIndices [glyphStart];
    glyphRun->glyphAdvances = &glyphAdvances[glyphStart];
    glyphRun->glyphOffsets  = &glyphOffsets [glyphStart];
    glyphRun->glyphCount    = glyphCount;
    glyphRun->fontEmSize    = fontEmSize;
    glyphRun->fontFace      = fontFace;
    glyphRun->bidiLevel     = isReversed;
    glyphRun->isSideways    = isSideways;
}
// </SnippetFlowSinkcpp>
