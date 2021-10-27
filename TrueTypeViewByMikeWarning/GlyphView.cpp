#include "ttview.h"
#include "FontNode.h"
#include "GlyphView.h"
#include "TextOutStream.h"

using std::vector;
using std::wstring;
using std::endl;


void DrawGlyph(const FontFile & fontfile, HDC dc, int x, int y, USHORT glyph, char32_t c = 0xFFFFFFFF);


class GlyphView : public Renderer
{
public:

    GlyphView(const GlyphViewStrings * source, const FontFile & fontfile);

    virtual void    Render(HDC dc);
    virtual size_t  GetTotalHeight(HDC dc);

private:

    const GlyphViewStrings * m_source;
    const FontFile &         m_fontfile;
};


GlyphView::GlyphView(const GlyphViewStrings * source, const FontFile & fontfile)
      : m_source(source),
        m_fontfile(fontfile)
{
}


void GlyphView::Render(HDC dc)
{
    RECT update;
    GetClipBox(dc, &update);

    HFONT oldfont = SelectFont(dc, m_fontfile.LabelFont());
    SIZE  extent;
    GetTextExtentPoint32(dc, L"WW", 1, &extent);

    SIZE cell = m_fontfile.GetGlyphCellSize();

    USHORT first_glyph = (USHORT) ((m_scroll_pos + update.top) / cell.cy);
    SHORT  glyph = first_glyph;
    int    y = first_glyph * cell.cy - (int) m_scroll_pos;

    while (y < update.bottom)
    {
        vector<wstring> strings(m_source->GetStrings(glyph));

        DrawGlyph(m_fontfile, dc, 0, y, glyph);
    
        TextOutStream textout(dc, y, cell.cx + extent.cx);
        for (size_t s = 0; s != strings.size(); ++s)
            textout << strings[s] << endl;

        y += cell.cy;
        ++glyph;
    }

    SelectFont(dc, oldfont);
}


size_t GlyphView::GetTotalHeight(HDC /* dc */)
{
    return m_fontfile.GetGlyphCellSize().cy * m_fontfile.GlyphCount() + 1;
}


Renderer * CreateGlyphViewRenderer(const GlyphViewStrings * source, const FontFile & fontfile)
{
    return new GlyphView(source, fontfile);
}