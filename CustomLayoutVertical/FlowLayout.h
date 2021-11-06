// <SnippetFlowLayouth>
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
#pragma once

#include "FlowSource.h"
#include "FlowSink.h"
#include "TextAnalysis.h"


class DECLSPEC_UUID("E304E995-6157-48ec-8D44-ACB308A210D0") FlowLayout
    :   public ComBase<
            QiListSelf<FlowLayout,
            QiList<IUnknown
        > > >
{
    // This custom layout processes layout in two stages.
    //
    // 1. Analyze the text, given the current font and size
    //      a. Bidirectional analysis
    //      b. Script analysis
    //      c. Number substitution analysis
    //      d. Shape glyphs
    //      e. Intersect run results
    //
    // 2. Fill the text to the given shape
    //      a. Pull next rect from flow source
    //      b. Fit as much text as will go in
    //      c. Push text to flow sink

public:
    struct ClusterPosition
    {
        ClusterPosition()
        :   textPosition(),
            runIndex(),
            runEndPosition()
        { }

        uint32_t textPosition;    // Current text position
        uint32_t runIndex;        // Associated analysis run covering this position
        uint32_t runEndPosition;  // Text position where this run ends
    };

    enum JustificationMode
    {
        JustificationModeNone,
        JustificationModeInterword,
    };

public:
    FlowLayout(IDWriteFactory* dwriteFactory)
    :   dwriteFactory_(SafeAcquire(dwriteFactory)),
        fontFace_(),
        numberSubstitution_(),
        readingDirection_(ReadingDirectionLeftToRightTopToBottom),
        glyphOrientationMode_(GlyphOrientationModeDefault),
        justificationMode_(JustificationModeInterword),
        fontEmSize_(12),
        maxSpaceWidth_(8),
        isTextAnalysisComplete_(false),
        treatAsIsolatedCharacters_(false)
    {
    }

    ~FlowLayout()
    {
        SafeRelease(&dwriteFactory_);
        SafeRelease(&fontFace_);
        SafeRelease(&numberSubstitution_);
    }

    STDMETHODIMP SetTextFormat(IDWriteTextFormat* textFormat);
    STDMETHODIMP SetNumberSubstitution(IDWriteNumberSubstitution* numberSubstitution);
    STDMETHODIMP SetReadingDirection(ReadingDirection readingDirection);
    STDMETHODIMP SetGlyphOrientationMode(GlyphOrientationMode glyphOrientationMode);
    STDMETHODIMP SetJustificationMode(JustificationMode justificationMode);
    STDMETHODIMP SetTreatAsIsolatedCharacters(bool treatAsIsolatedCharacters);
    STDMETHODIMP SetFont(
        const wchar_t* fontFamilyName,
        DWRITE_FONT_WEIGHT fontWeight = DWRITE_FONT_WEIGHT_NORMAL,
        DWRITE_FONT_STRETCH fontStretch = DWRITE_FONT_STRETCH_NORMAL,
        DWRITE_FONT_STYLE fontSlope = DWRITE_FONT_STYLE_NORMAL,
        float fontEmSize = 0
        );

    GlyphOrientationMode GetGlyphOrientationMode();
    ReadingDirection GetReadingDirection();

    STDMETHODIMP CopyToClipboard();
    STDMETHODIMP PasteFromClipboard();

    STDMETHODIMP SetText(
        const wchar_t* text, // [textLength]
        uint32_t textLength
        );

    STDMETHODIMP GetText(
        OUT const wchar_t** text, // [textLength]
        OUT uint32_t* textLength
        );

    // Perform analysis on the current text, converting text to glyphs.
    STDMETHODIMP AnalyzeText();

    // Reflow the text analysis into 
    STDMETHODIMP FlowText(
        FlowLayoutSource* flowSource,
        FlowLayoutSink* flowSink
        );

protected:
    STDMETHODIMP CreateFormattedRuns() throw();

    STDMETHODIMP ShapeGlyphRuns(IDWriteTextAnalyzer* textAnalyzer) throw();

    STDMETHODIMP ShapeGlyphRun(
        IDWriteTextAnalyzer* textAnalyzer,
        uint32_t runIndex,
        IN OUT uint32_t& glyphStart
        ) throw();

    STDMETHODIMP ShapeSimpleGlyphRun(
        uint32_t runIndex,
        IN OUT uint32_t& glyphStart
        ) throw();

    STDMETHODIMP FitText(
        const ClusterPosition& clusterStart,
        uint32_t textEnd,
        float maxWidth,
        OUT ClusterPosition* clusterEnd
        ) throw();

    STDMETHODIMP ProduceGlyphRuns(
        FlowLayoutSink* flowSink,
        const FlowLayoutSource::RectF& rect,
        const ClusterPosition& clusterStart,
        const ClusterPosition& clusterEnd
        ) const throw();

    STDMETHODIMP ProduceJustifiedAdvances(
        float maxWidth,
        const ClusterPosition& clusterStart,
        const ClusterPosition& clusterEnd,
        OUT std::vector<float>& justifiedAdvances
        ) const throw();

    void ProduceBidiOrdering(
        uint32_t spanStart,
        uint32_t spanCount,
        OUT uint32_t* spanIndices         // [spanCount]
        ) const throw();

    void SetClusterPosition(
        IN OUT ClusterPosition& cluster,
        uint32_t textPosition
        ) const throw();

    void AdvanceClusterPosition(
        IN OUT ClusterPosition& cluster
        ) const throw();

    uint32_t GetClusterGlyphStart(
        const ClusterPosition& cluster
        ) const throw();

    float GetClusterRangeWidth(
        const ClusterPosition& clusterStart,
        const ClusterPosition& clusterEnd
        ) const throw();

    float GetClusterRangeWidth(
        uint32_t glyphStart,
        uint32_t glyphEnd,
        const float* glyphAdvances      // [glyphEnd]
        ) const throw();

protected:
    IDWriteFactory* dwriteFactory_;

    // Input information.
    std::wstring formattedText_;
    std::wstring text_;
    wchar_t localeName_[LOCALE_NAME_MAX_LENGTH];
    ReadingDirection readingDirection_;
    GlyphOrientationMode glyphOrientationMode_;
    JustificationMode justificationMode_;
    IDWriteFontFace* fontFace_;
    IDWriteNumberSubstitution* numberSubstitution_;
    float fontEmSize_;

    // Output text analysis results
    std::vector<TextAnalysis::LinkedRun> runs_;
    std::vector<DWRITE_LINE_BREAKPOINT> breakpoints_;
    std::vector<DWRITE_GLYPH_OFFSET> glyphOffsets_;
    std::vector<uint16_t> glyphClusters_;
    std::vector<uint16_t> glyphIndices_;
    std::vector<float>  glyphAdvances_;

    float maxSpaceWidth_;           // maximum stretch of space allowed for justification
    bool isTextAnalysisComplete_;   // text analysis was done.
    bool treatAsIsolatedCharacters_;// ignore most text analysis
};
// </SnippetFlowLayouth>
