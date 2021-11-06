// <SnippetFlowSinkh>
// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// Copyright (c) Microsoft Corporation. All rights reserved
//
// Contents:    Source interface for where text is allowed to flow.
//
//----------------------------------------------------------------------------
#pragma once

class DECLSPEC_UUID("7712E74A-C7E0-4664-B58E-854394F2ACB4") FlowLayoutSink
    :   public ComBase<
            QiListSelf<FlowLayoutSink,
            QiList<IUnknown
        > > >
{
public:
    FlowLayoutSink(IDWriteFactory* dwriteFactory)
    :   dwriteFactory_(SafeAcquire(dwriteFactory)),
        textAnalyzer_()
    { }

    ~FlowLayoutSink()
    {
        SafeRelease(&dwriteFactory_);
        SafeRelease(&textAnalyzer_);
    }

    STDMETHODIMP Reset();

    STDMETHODIMP Prepare(uint32_t glyphCount);

    STDMETHODIMP SetGlyphRun(
        float x,
        float y,
        uint32_t glyphCount,
        const uint16_t* glyphIndices, // [glyphCount]
        const float* glyphAdvances, // [glyphCount]
        const DWRITE_GLYPH_OFFSET* glyphOffsets, // [glyphCount]
        IDWriteFontFace* fontFace,
        float fontEmSize,
        uint8_t glyphOrientation,
        bool isReversed,
        bool isSideways
        );

    STDMETHODIMP DrawGlyphRuns(
        IDWriteBitmapRenderTarget* renderTarget,
        IDWriteRenderingParams* renderingParams,
        COLORREF textColor
        ) const;

protected:
    // This glyph run is based off DWRITE_GLYPH_RUN
    // and is trivially convertable to it, but stores
    // pointers as relative indices instead instead
    // of raw pointers, which makes it more useful for
    // storing in a vector. Additionally, it stores
    // the x,y coordinate.

    struct CustomGlyphRun
    {
        CustomGlyphRun()
        :   fontFace(),
            fontEmSize(),
            glyphStart(),
            glyphCount(),
            glyphOrientation(),
            isSideways(),
            isReversed(),
            x(),
            y()
        { }

        CustomGlyphRun(const CustomGlyphRun& b)
        {
            memcpy(this, &b, sizeof(*this));
            fontFace = SafeAcquire(b.fontFace);
        }

        CustomGlyphRun& operator=(const CustomGlyphRun& b)
        {
            if (this != &b)
            {
                // Define assignment operator in terms of destructor and
                // placement new constructor, paying heed to self assignment.
                this->~CustomGlyphRun();
                new(this) CustomGlyphRun(b);
            }
            return *this;
        }

        ~CustomGlyphRun()
        {
            SafeRelease(&fontFace);
        }

        IDWriteFontFace* fontFace;
        float fontEmSize;
        float x;
        float y;
        uint32_t glyphStart;
        uint32_t glyphCount;
        uint8_t glyphOrientation;
        bool isSideways;
        bool isReversed;

        void Convert(
            const uint16_t* glyphIndices,               // [glyphCount]
            const float* glyphAdvances,                 // [glyphCount]
            const DWRITE_GLYPH_OFFSET* glyphOffsets,    // [glyphCount]
            OUT DWRITE_GLYPH_RUN* glyphRun
            ) const throw();
    };

    std::vector<CustomGlyphRun>         glyphRuns_;
    std::vector<uint16_t>               glyphIndices_;
    std::vector<float>                  glyphAdvances_;
    std::vector<DWRITE_GLYPH_OFFSET>    glyphOffsets_;

    IDWriteFactory* dwriteFactory_;
    mutable IDWriteTextAnalyzer1* textAnalyzer_; // lazily initialized
};
// </SnippetFlowSinkh>
