#include "ttview.h"
#include "FontNode.h"
#include "TextOutStream.h"
#include "UINode.h"

using namespace std;


class glyfRenderer : public Renderer
{
public:

    glyfRenderer(const FontFile & fontfile);

    size_t  GetTotalHeight(HDC dc);
    void    Render(HDC dc);

private:

    const FontFile & m_fontfile;
};


glyfRenderer::glyfRenderer(const FontFile & fontfile)
      : m_fontfile(fontfile)
{
}


size_t glyfRenderer::GetTotalHeight(HDC dc)
{
    RECT area;
    GetClientRect(WindowFromDC(dc), &area);

    int columns = (area.right - area.left) / m_fontfile.GetGlyphCellSize().cx;
    int rows = 1 + (m_fontfile.GlyphCount() - 1) / columns;
    
    return rows * m_fontfile.GetGlyphCellSize().cy + 1;
}


void DrawGlyph(const FontFile & fontfile, HDC dc, int x, int y, USHORT glyph, char32_t c = 0xFFFFFFFF);

void glyfRenderer::Render(HDC dc)
{
    RECT update;
    GetClipBox(dc, &update);
    OffsetRect(&update, 0, (int) m_scroll_pos);
    OffsetViewportOrgEx(dc, 0, -(int)m_scroll_pos, NULL);

    RECT client;
    GetClientRect(WindowFromDC(dc), &client);
    
    int columns = (client.right - client.left) / m_fontfile.GetGlyphCellSize().cx;
    int row = update.top / m_fontfile.GetGlyphCellSize().cy;
    int glyph = row * columns;
    int y = row * m_fontfile.GetGlyphCellSize().cy;
    int column = 0;

    while (glyph < m_fontfile.GlyphCount() && y < update.bottom)
    {
        int x = column * m_fontfile.GetGlyphCellSize().cx;

        DrawGlyph(m_fontfile, dc, x, y, (USHORT) glyph);

        ++glyph;
        ++column;
        if (column == columns)
        {
            column = 0;
            y += m_fontfile.GetGlyphCellSize().cy;
        }
    }
}



class glyf : public FontNode
{
public:

    static FontNode * Create(UINode &uinode, const byte * data, size_t length, FontFile & fontfile);

    glyf(UINode &uinode, const byte * data, size_t length, FontFile & fontfile);

    wstring GetTooltip();
};

RegisteredFontNode glyf_registration('glyf', &glyf::Create);


FontNode * glyf::Create(UINode &uinode, const byte * data, size_t length, FontFile & fontfile)
{
    return new glyf(uinode, data, length, fontfile);
}


glyf::glyf(UINode & /* UNREF uinode */, const byte * data, size_t length, FontFile & fontfile)    
      : FontNode(data, length)
{
    this->m_renderer.reset(new glyfRenderer(fontfile));
}


wstring glyf::GetTooltip()
{
    return L"Glyph data";
}


