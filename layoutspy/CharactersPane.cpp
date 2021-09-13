#include "LayoutSpy.h"
#include "Panes.h"
#include "LayoutRecorder.h"
#include "TextFormatter.h"


using std::vector;
using std::wstring;
using std::hex;
using std::dec;
using std::setfill;
using std::setw;
using std::endl;
using std::boolalpha;
using std::swap;


class CharactersPaneImpl : public CharactersPane
{
    struct CharacterInfo;

public:

    void   Update(const StringData & data);
    size_t UnitCount();
    void   DrawUnit(ID2D1RenderTarget * renderTarget, ID2D1Brush * textBrush, const D2D1_RECT_F & glyphRect, size_t i);
    void   GetUnitInfo(TextFormatter & info, size_t i);
    void   SetSelectionInfo();

    void   SetCharSelectionSink(const CharSelectionSink & sink);

private:

    std::vector<CharacterInfo> m_charInfo;
    CharSelectionSink          m_selectionSink;
};



struct CharactersPaneImpl::CharacterInfo
{
    wchar_t             c;
    UINT32              textPosition;
    size_t              runIndex;
    UINT16              cluster;

    std::wstring        fontFamilyName;
    float               fontEmSize;
    DWRITE_FONT_STRETCH fontStretch;
    DWRITE_FONT_STYLE   fontStyle;
    DWRITE_FONT_WEIGHT  fontWeight;
    std::wstring        localeName;
    BOOL                strikethrough;
    BOOL                underline;

    TextAnalysis::AnalysisResults analysisResults;

    IDWriteFontFacePtr  fontFace;
    UINT16              glyphIndex;
    DWRITE_GLYPH_OFFSET glyphDrawOffset;

    CharSelectionSink   m_selectionSink;

    CharacterInfo(const StringData & data, const GlyphRun & glyphRun, size_t i);
};



CharactersPaneImpl::CharacterInfo::CharacterInfo(const StringData & data, const GlyphRun & glyphRun, size_t i)
      : c(glyphRun.text[i]),
        fontFace(glyphRun.fontFace),
        runIndex(glyphRun.runIndex),
        textPosition(glyphRun.textPosition + (UINT32) i),
        cluster(glyphRun.clusterMap[i]),
        analysisResults(data.analysisResults[glyphRun.textPosition + i])
{
    // Pull format attributes from the layout
    UINT32 fontFamilyNameLength;
    TIF( data.layout->GetFontFamilyNameLength(textPosition, &fontFamilyNameLength) );
    fontFamilyName.resize(fontFamilyNameLength + 1); // leave room for a NULL terminator
    TIF( data.layout->GetFontFamilyName(textPosition, &fontFamilyName[0], fontFamilyNameLength + 1) );
    fontFamilyName.resize(fontFamilyName.size() - 1);  // trim the terminator

    UINT32 localeNameLength;
    TIF( data.layout->GetLocaleNameLength(textPosition, &localeNameLength) );
    localeName.resize(localeNameLength + 1); // leave room for a NULL terminator
    TIF( data.layout->GetLocaleName(textPosition, &localeName[0], localeNameLength + 1) );
    localeName.resize(localeName.size() - 1);  // trim the terminator

    TIF( data.layout->GetFontSize(textPosition, &fontEmSize) );
    TIF( data.layout->GetFontStyle(textPosition, &fontStyle) );
    TIF( data.layout->GetFontStretch(textPosition, &fontStretch) );
    TIF( data.layout->GetFontWeight(textPosition, &fontWeight) );
    TIF( data.layout->GetStrikethrough(textPosition, &strikethrough) );
    TIF( data.layout->GetUnderline(textPosition, &underline) );

    // Get the default glyph to display for each character
    UINT32 ucs4 = c;
    TIF( fontFace->GetGlyphIndices(&ucs4, 1, &glyphIndex) );

    DWRITE_FONT_METRICS  fontMetrics;
    DWRITE_GLYPH_METRICS glyphMetrics;

    fontFace->GetMetrics(&fontMetrics);
    TIF( fontFace->GetDesignGlyphMetrics(&glyphIndex, 1, &glyphMetrics, false) );

    float blackWidth = (float) glyphMetrics.advanceWidth + glyphMetrics.rightSideBearing - glyphMetrics.leftSideBearing;
    blackWidth = 36.0f * blackWidth / fontMetrics.designUnitsPerEm;

    glyphDrawOffset.advanceOffset = 36.0f - blackWidth / 2;
    glyphDrawOffset.ascenderOffset = -(3 * 72.0f / 4);
}


void CharactersPaneImpl::Update(const StringData & data)
{
    m_charInfo.clear();

    for (vector<GlyphRun>::const_iterator glyphRun = data.glyphRuns.begin(); glyphRun != data.glyphRuns.end(); ++glyphRun)
        for (size_t i = 0; i != glyphRun->text.length(); ++i)
            m_charInfo.push_back(CharacterInfo(data, *glyphRun, i));
}


size_t CharactersPaneImpl::UnitCount()
{
    return m_charInfo.size();
}


void CharactersPaneImpl::DrawUnit(ID2D1RenderTarget * renderTarget, ID2D1Brush * textBrush, const D2D1_RECT_F & glyphRect, size_t i)
{
    static const float zero = 0.0f;

    DWRITE_GLYPH_RUN glyphRun;
    glyphRun.fontFace = m_charInfo[i].fontFace;
    glyphRun.fontEmSize = 36.0f;
    glyphRun.glyphCount = 1;
    glyphRun.glyphIndices = &m_charInfo[i].glyphIndex;
    glyphRun.glyphAdvances = &zero;
    glyphRun.glyphOffsets = &m_charInfo[i].glyphDrawOffset;
    glyphRun.isSideways = false;
    glyphRun.bidiLevel = 0;

    renderTarget->DrawRectangle(glyphRect, textBrush);

    renderTarget->PushAxisAlignedClip(glyphRect, D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
    renderTarget->DrawGlyphRun(D2D1::Point2F(glyphRect.left, glyphRect.top), &glyphRun, textBrush);
    renderTarget->PopAxisAlignedClip();
}


void CharactersPaneImpl::SetCharSelectionSink(const CharSelectionSink & sink)
{
    m_selectionSink = sink;
}


#include <sstream>
template <typename T>
wstring ToWstring(const T & val)
{
    std::wstringstream s;
    s << val;
    return s.str();
}


wstring ToWstring(DWRITE_SCRIPT_SHAPES shapes)
{
    switch (shapes)
    {
    case DWRITE_SCRIPT_SHAPES_DEFAULT: return L"Default";
    case DWRITE_SCRIPT_SHAPES_NO_VISUAL: return L"No visual";
    
    default: return ToWstring((unsigned) shapes);
    }
}


wstring ToWstring(DWRITE_BREAK_CONDITION condition)
{
    switch (condition)
    {
    case DWRITE_BREAK_CONDITION_NEUTRAL: return L"Neutral";
    case DWRITE_BREAK_CONDITION_CAN_BREAK: return L"Can break";
    case DWRITE_BREAK_CONDITION_MAY_NOT_BREAK: return L"May not break";
    case DWRITE_BREAK_CONDITION_MUST_BREAK: return L"Must break";

    default: assert(!"Unknown DWRITE_BREAK_CONDITION"); return ToWstring((unsigned) condition);
    }
}


wstring ToWstring(DWRITE_FONT_WEIGHT weight)
{
    switch (weight)
    {
    case DWRITE_FONT_WEIGHT_THIN: return L"Thin";
    case DWRITE_FONT_WEIGHT_EXTRA_LIGHT: return L"Extra Light";
    case DWRITE_FONT_WEIGHT_LIGHT: return L"Light";
    case DWRITE_FONT_WEIGHT_REGULAR: return L"Regular";
    case DWRITE_FONT_WEIGHT_MEDIUM: return L"Medium";
    case DWRITE_FONT_WEIGHT_DEMI_BOLD: return L"Demi-Bold";
    case DWRITE_FONT_WEIGHT_BOLD: return L"Bold";
    case DWRITE_FONT_WEIGHT_EXTRA_BOLD: return L"Extra Bold";
    case DWRITE_FONT_WEIGHT_BLACK: return L"Black";
    case DWRITE_FONT_WEIGHT_EXTRA_BLACK: return L"Extra Black";

    default: return ToWstring((unsigned) weight);
    }
}


wstring ToWstring(DWRITE_FONT_STYLE style)
{
    switch (style)
    {
    case DWRITE_FONT_STYLE_NORMAL: return L"Normal";
    case DWRITE_FONT_STYLE_OBLIQUE: return L"Oblique";
    case DWRITE_FONT_STYLE_ITALIC: return L"Italic";

    default: return ToWstring((unsigned) style);
    }
}


wstring ToWstring(DWRITE_FONT_STRETCH stretch)
{
    switch (stretch)
    {
    case DWRITE_FONT_STRETCH_ULTRA_CONDENSED: return L"Ultra Condensed";
    case DWRITE_FONT_STRETCH_EXTRA_CONDENSED: return L"Extra Condensed";
    case DWRITE_FONT_STRETCH_CONDENSED: return L"Condensed";
    case DWRITE_FONT_STRETCH_SEMI_CONDENSED: return L"Semi Condensed";
    case DWRITE_FONT_STRETCH_NORMAL: return L"Normal";
    case DWRITE_FONT_STRETCH_SEMI_EXPANDED: return L"Semi Expanded";
    case DWRITE_FONT_STRETCH_EXPANDED: return L"Expanded";
    case DWRITE_FONT_STRETCH_EXTRA_EXPANDED: return L"Extra Expanded";
    case DWRITE_FONT_STRETCH_ULTRA_EXPANDED: return L"Ultra Expanded";

    default: return ToWstring((unsigned) stretch);
    }
}


wstring FormatBreakLevel(UINT8 level)
{
    return ToWstring((DWRITE_BREAK_CONDITION) level);
}


void CharactersPaneImpl::GetUnitInfo(TextFormatter & info, size_t i)
{
    info << TextFormat::header << L"Character Properties" << endl
         << L"U+" << hex << setfill(L'0') << setw(4) << (int) m_charInfo[i].c << dec << endl
         << endl
         << L"Text position: " << m_charInfo[i].textPosition << endl
         << L"Run index: " << m_charInfo[i].runIndex << endl
         << L"Cluster: " << m_charInfo[i].cluster << endl;

    info << TextFormat::header << L"Analysis Results" << endl
         << L"Script: " << m_charInfo[i].analysisResults.scriptAnalysis.script << endl
         << L"Script shapes: " << ToWstring(m_charInfo[i].analysisResults.scriptAnalysis.shapes) << endl
         << L"Explicit bidi level: " << m_charInfo[i].analysisResults.explicitBidiLevel << endl
         << L"Resolved bidi level: " << m_charInfo[i].analysisResults.resolvedBidiLevel << endl
         << L"Break before: " << FormatBreakLevel(m_charInfo[i].analysisResults.breakAnalysis.breakConditionBefore) << endl
         << L"Break after: " << FormatBreakLevel(m_charInfo[i].analysisResults.breakAnalysis.breakConditionAfter) << endl
         << L"Is whitespace: " << boolalpha << !!m_charInfo[i].analysisResults.breakAnalysis.isWhitespace << endl
         << L"Is soft hyphen: " << !!m_charInfo[i].analysisResults.breakAnalysis.isSoftHyphen << endl;
         
    info << TextFormat::header << L"Formatting Properties" << endl
         << L"Font: " << m_charInfo[i].fontEmSize << L" dip " << m_charInfo[i].fontFamilyName << endl
         << L"Weight: " << ToWstring(m_charInfo[i].fontWeight) << endl
         << L"Style: " << ToWstring(m_charInfo[i].fontStyle) << endl
         << L"Stretch: " << ToWstring(m_charInfo[i].fontStretch) << endl
         << L"Underline: " << m_charInfo[i].underline << endl
         << L"Strikethrough: " << m_charInfo[i].strikethrough << endl
         << L"Locale: " << m_charInfo[i].localeName << endl;         
}


void CharactersPaneImpl::SetSelectionInfo()
{
    size_t start = m_selectionStart;
    size_t stop = m_selectionStop;
    if (start > stop)
        swap(start, stop);

    m_selectionSink(m_selectionStart, m_selectionStop + 1);

    TextFormatter info;

    info << TextFormat::header << L"Selection Range" << endl
         << L"Start position: " << start << endl
         << L"Length: " << stop - start + 1 << endl;

    info << TextFormat::header << L"Formatting Properties" << endl;

    m_infoSink(info);
}


CharactersPane * CreateCharactersPane()
{
    return new CharactersPaneImpl;
}