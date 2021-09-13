#include "TextAnalysis.h"


struct GlyphRun
{
    size_t                runIndex;
    float                 baselineOriginX;
    float                 baselineOriginY;
    DWRITE_MEASURING_MODE measuringMode;

    UINT32              textPosition;
    float               fontEmSize;
    IDWriteFontFacePtr  fontFace;
    std::wstring        text;
    std::vector<UINT16> clusterMap;
    std::vector<UINT16> glyphIndices;
    std::vector<float>  glyphAdvances;
    std::vector<DWRITE_GLYPH_OFFSET> glyphOffsets;
    bool                isSideways;
    UINT32              bidiLevel;
    std::wstring        localeName;

    GlyphRun(
        size_t runIndex,
        float baselineOriginX,
        float baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        __in const DWRITE_GLYPH_RUN * glyphRun, 
        __in const DWRITE_GLYPH_RUN_DESCRIPTION * glyphRunDescription);
};

class LayoutRecorder : private IDWriteTextRenderer
{
public:

    void UpdateGlyphRuns(IDWriteTextLayout * layout, ID2D1RenderTarget * renderTarget);

    std::vector<GlyphRun> glyphRuns;

protected:

    LayoutRecorder();
    virtual ~LayoutRecorder();

private:

    // IUnknown   
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void ** ppvObject) override;
    ULONG   STDMETHODCALLTYPE AddRef() override;
    ULONG   STDMETHODCALLTYPE Release() override;

    // IDWritePixelSnapping
    HRESULT STDMETHODCALLTYPE IsPixelSnappingDisabled(__maybenull void* clientDrawingContext, __out BOOL* isDisabled) override;
    HRESULT STDMETHODCALLTYPE GetCurrentTransform(__maybenull void* clientDrawingContext, __out DWRITE_MATRIX* transform) override;
    HRESULT STDMETHODCALLTYPE GetPixelsPerDip(__maybenull void* clientDrawingContext, __out FLOAT* pixelsPerDip) override;

    // IDWriteTextRenderer
    HRESULT STDMETHODCALLTYPE DrawGlyphRun(__maybenull void* clientDrawingContext, FLOAT baselineOriginX, FLOAT baselineOriginY, DWRITE_MEASURING_MODE measuringMode, __in DWRITE_GLYPH_RUN const* glyphRun, __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription, __maybenull IUnknown* clientDrawingEffect) override;
    HRESULT STDMETHODCALLTYPE DrawUnderline(__maybenull void* clientDrawingContext, FLOAT baselineOriginX, FLOAT baselineOriginY, __in DWRITE_UNDERLINE const* underline, __maybenull IUnknown* clientDrawingEffect) override;
    HRESULT STDMETHODCALLTYPE DrawStrikethrough(__maybenull void* clientDrawingContext, FLOAT baselineOriginX, FLOAT baselineOriginY, __in DWRITE_STRIKETHROUGH const* strikethrough, __maybenull IUnknown* clientDrawingEffect) override;
    HRESULT STDMETHODCALLTYPE DrawInlineObject(__maybenull void* clientDrawingContext, FLOAT originX, FLOAT originY, IDWriteInlineObject* inlineObject, BOOL isSideways, BOOL isRightToLeft, __maybenull IUnknown* clientDrawingEffect) override;

    volatile LONG m_refs;
};


struct StringData : public LayoutRecorder
{
    enum LayoutFormatting
    {
        FontFamilyFormatting,
        FontSizeFormatting,
        FontWeightFormatting,
        FontStyleFormatting,
        FontStretchFormatting,
        LocaleNameFormatting,
        UnderlineFormatting,
        StrikethroughFormatting,
        TypographyFormatting
    };

    struct LayoutFormat
    {
        LayoutFormatting    formatting;
        std::wstring        value;
        DWRITE_TEXT_RANGE   range;
    };

    std::wstring                text;
    IDWriteTextFormatPtr        format;
    IDWriteTextLayoutPtr        layout;
    float                       maxWidth;
    float                       maxHeight;
    std::wstring                fontFamily;
    IDWriteFontCollectionPtr    fontCollection;
    DWRITE_FONT_WEIGHT          fontWeight;
    DWRITE_FONT_STYLE           fontStyle;
    DWRITE_FONT_STRETCH         fontStretch;
    float                       fontSize;
    std::wstring                localeName;
    DWRITE_READING_DIRECTION    readingDirection;
    DWRITE_PARAGRAPH_ALIGNMENT  paragraphAlignment;
    DWRITE_TEXT_ALIGNMENT       textAlignment;
    DWRITE_FLOW_DIRECTION       flowDirection;
    DWRITE_LINE_SPACING_METHOD  lineSpacing;
    float                       lineHeight;
    float                       baselineDistance;
    DWRITE_WORD_WRAPPING        wordWrap;
    std::vector<LayoutFormat>   layoutFormatting;
    float                       positionX;
    float                       positionY;

    std::vector<TextAnalysis::AnalysisResults> analysisResults;

    StringData();
    
    void ApplyLayoutFormatting(LayoutFormatting formatting, const std::wstring & value, DWRITE_TEXT_RANGE range);

    void UpdateLayout();
    void UpdateAnalysis(ID2D1RenderTarget * renderTarget);

    void ApplyTypographyFormatting(const std::wstring & features, const DWRITE_TEXT_RANGE & range);

    std::wstring GetConsistent(std::wstring (StringData::* prop)(size_t, DWRITE_TEXT_RANGE &), size_t begin, size_t end);
    std::wstring FamilyNameAt(size_t i, DWRITE_TEXT_RANGE & range);
    std::wstring FontSizeAt(size_t i, DWRITE_TEXT_RANGE & range);
    std::wstring FontWeightAt(size_t i, DWRITE_TEXT_RANGE & range);
    std::wstring TypographyAt(size_t i, DWRITE_TEXT_RANGE & range);
};


