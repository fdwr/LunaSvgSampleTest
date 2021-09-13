#include "LayoutSpy.h"
#include "Panes.h"
#include "LayoutRecorder.h"
#include "TextFormatter.h"
#include "LexicalCast.h"


using std::vector;
using std::wstring;
using std::hex;
using std::dec;
using std::setfill;
using std::setw;
using std::endl;
using std::boolalpha;
using std::swap;


class GlyphsPaneImpl : public GlyphsPane
{
    struct GlyphInfo
    {
        UINT16                glyphIndex;
        float                 glyphAdvance;
        DWRITE_GLYPH_OFFSET   glyphOffset;
        bool                  nullGlyphOffset;

        size_t                runIndex;
        IDWriteFontFacePtr    fontFace;
        float                 fontEmSize; 
        bool                  isSideways;
        UINT32                bidiLevel;
        float                 baselineOriginX;
        float                 baselineOriginY;
        DWRITE_MEASURING_MODE measuringMode;

        DWRITE_GLYPH_OFFSET   glyphDrawOffset;

        GlyphInfo(const GlyphRun & glyphRun, size_t i);
    };

public:

    void   Update(const StringData & data);
    size_t UnitCount();
    void   DrawUnit(ID2D1RenderTarget * renderTarget, ID2D1Brush * textBrush, const D2D1_RECT_F & glyphRect, size_t i);
    void   GetUnitInfo(TextFormatter & info, size_t i);

private:

    wstring GetFontFileName(IDWriteFontFace * fontFace);

    vector<GlyphInfo> m_glyphInfo;

    static const DWRITE_GLYPH_OFFSET ZeroGlyphOffset;
};


const DWRITE_GLYPH_OFFSET GlyphsPaneImpl::ZeroGlyphOffset = {0, 0};


GlyphsPaneImpl::GlyphInfo::GlyphInfo(const GlyphRun & glyphRun, size_t i)
      : glyphIndex(glyphRun.glyphIndices[i]),
        glyphAdvance(glyphRun.glyphAdvances[i]),
        glyphOffset((glyphRun.glyphOffsets.size() > i) ? glyphRun.glyphOffsets[i] : ZeroGlyphOffset),
        nullGlyphOffset(glyphRun.glyphOffsets.size() <= i),
        fontFace(glyphRun.fontFace),
        fontEmSize(glyphRun.fontEmSize),
        isSideways(glyphRun.isSideways),
        bidiLevel(glyphRun.bidiLevel),
        runIndex(glyphRun.runIndex),
        baselineOriginX(glyphRun.baselineOriginX),
        baselineOriginY(glyphRun.baselineOriginY),
        measuringMode(glyphRun.measuringMode)
{
    DWRITE_FONT_METRICS  fontMetrics;
    DWRITE_GLYPH_METRICS glyphMetrics;

    fontFace->GetMetrics(&fontMetrics);
    TIF( fontFace->GetDesignGlyphMetrics(&glyphIndex, 1, &glyphMetrics, false) );

    float blackWidth = (float) glyphMetrics.advanceWidth + glyphMetrics.rightSideBearing - glyphMetrics.leftSideBearing;
    blackWidth = 36.0f * blackWidth / fontMetrics.designUnitsPerEm;

    glyphDrawOffset.advanceOffset = 36.0f - blackWidth / 2;
    glyphDrawOffset.ascenderOffset = -(3 * 72.0f / 4);
}


void GlyphsPaneImpl::Update(const StringData & data)
{
    m_glyphInfo.clear();

    for (vector<GlyphRun>::const_iterator glyphRun = data.glyphRuns.begin(); glyphRun != data.glyphRuns.end(); ++glyphRun)
        for (size_t i = 0; i != glyphRun->glyphIndices.size(); ++i)
            m_glyphInfo.push_back(GlyphInfo(*glyphRun, i));
}


size_t GlyphsPaneImpl::UnitCount()
{
    return m_glyphInfo.size();
}


void GlyphsPaneImpl::DrawUnit(ID2D1RenderTarget * renderTarget, ID2D1Brush * textBrush, const D2D1_RECT_F & glyphRect, size_t i)
{
    static const float zero = 0.0f;

    DWRITE_GLYPH_RUN glyphRun;
    glyphRun.fontFace = m_glyphInfo[i].fontFace;
    glyphRun.fontEmSize = 36.0f;
    glyphRun.glyphCount = 1;
    glyphRun.glyphIndices = &m_glyphInfo[i].glyphIndex;
    glyphRun.glyphAdvances = &zero;
    glyphRun.glyphOffsets = &m_glyphInfo[i].glyphDrawOffset;
    glyphRun.isSideways = false;
    glyphRun.bidiLevel = 0;

    renderTarget->DrawRectangle(glyphRect, textBrush);
    renderTarget->PushAxisAlignedClip(glyphRect, D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
    renderTarget->DrawGlyphRun(D2D1::Point2F(glyphRect.left, glyphRect.top), &glyphRun, textBrush);
    renderTarget->PopAxisAlignedClip();
}


void GlyphsPaneImpl::GetUnitInfo(TextFormatter & info, size_t i)
{
    info << TextFormat::header << L"Glyph Properties" << endl
         << L"Glyph ID: " << m_glyphInfo[i].glyphIndex << L" (0x" << hex << m_glyphInfo[i].glyphIndex << L")" << endl
         << L"Advance width: " << m_glyphInfo[i].glyphAdvance << L" dips" << endl
         << L"Offset: ";

    if (m_glyphInfo[i].nullGlyphOffset)
        info << L"(null)";
    else
        info << m_glyphInfo[i].glyphOffset.advanceOffset << "," << m_glyphInfo[i].glyphOffset.ascenderOffset;

    info << endl;


    info << TextFormat::header << L"Glyph Run Properties" << endl
         << L"Run index: " << m_glyphInfo[i].runIndex << endl
         << L"Font: face " << m_glyphInfo[i].fontFace->GetIndex() << " of " << GetFontFileName(m_glyphInfo[i].fontFace) << endl
         << L"Simulations: " << lexical_cast<wstring>(m_glyphInfo[i].fontFace->GetSimulations()) << endl
         << L"Em Size: " << m_glyphInfo[i].fontEmSize << " dip" << endl
         << L"Sideways: " << boolalpha << m_glyphInfo[i].isSideways << endl
         << L"Bidi level: " << m_glyphInfo[i].bidiLevel << endl
         << L"Baseline origin: " << m_glyphInfo[i].baselineOriginX << L"," << m_glyphInfo[i].baselineOriginY << endl
         << L"Measuring mode: " << lexical_cast<wstring>(m_glyphInfo[i].measuringMode) << endl;
}


wstring GlyphsPaneImpl::GetFontFileName(IDWriteFontFace * fontFace)
{
    UINT32             fileCount = 1;
    IDWriteFontFilePtr fontFile;
    TIF( fontFace->GetFiles(&fileCount, &fontFile) );

    UINT32 fontKeySize;
    const void * fontKey;
    TIF( fontFile->GetReferenceKey(&fontKey, &fontKeySize) );

    IDWriteFontFileLoaderPtr fontLoader;
    TIF( fontFile->GetLoader(&fontLoader) );

    IDWriteLocalFontFileLoaderPtr localFont;
    TIF( fontLoader.QueryInterface(__uuidof(IDWriteLocalFontFileLoader), &localFont) );

    UINT32 fontPathLength;
    TIF( localFont->GetFilePathLengthFromKey(fontKey, fontKeySize, &fontPathLength) );

    wstring fontPath(fontPathLength + 1, L'\0');
    TIF( localFont->GetFilePathFromKey(fontKey, fontKeySize, &fontPath[0], (UINT32) fontPath.size()) );

    // If the file lives in the font folder then strip out the folder info
    LPWSTR fontFolderPath;
    TIF( SHGetKnownFolderPath(FOLDERID_Fonts, 0, NULL, &fontFolderPath) );
    size_t fontFolderPathLength = wcslen(fontFolderPath);
    
    bool inFontsFolder = (_wcsnicmp(fontFolderPath, fontPath.c_str(), fontFolderPathLength) == 0);
    if (inFontsFolder && fontFolderPath[fontFolderPathLength - 1] != L'\\')
        if (fontPath.length() > fontFolderPathLength && fontPath[fontFolderPathLength] == L'\\')
            ++fontFolderPathLength;
            
    CoTaskMemFree(fontFolderPath);

    if (inFontsFolder)
        fontPath = fontPath.substr(fontFolderPathLength);

    return fontPath;
}


GlyphsPane * CreateGlyphsPane()
{
    return new GlyphsPaneImpl;
}