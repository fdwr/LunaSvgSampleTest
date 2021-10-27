#include "ttview.h"
#include "FontNode.h"
#include "TextOutStream.h"


namespace
{
    bool IsPrintableHexCharacter(char32_t c)
    {
        return c >= 0x20 && (c < 0x7F || c > 0x9F);
    }
}


using namespace std;


class HexDumpRenderer : public Renderer
{
public:

    HexDumpRenderer(const void * bytes, size_t count);

    virtual void    Render(HDC dc);
    virtual size_t  GetTotalHeight(HDC dc);

private:

    const byte *  m_bytes;
    size_t  m_count;

    HFONT GetFont();
    size_t LineHeight();
};


HexDumpRenderer::HexDumpRenderer(const void * bytes, size_t count)
      : m_bytes((const byte *) bytes),
        m_count(count)
{
}


void HexDumpRenderer::Render(HDC dc)
{
    RECT update;
    GetClipBox(dc, &update);

    size_t lineheight = LineHeight();
    size_t first_line = (m_scroll_pos + update.top) / lineheight;
    size_t   i = 16 * first_line;

    if (i > m_count)
        return;

    // Adjust the top of the update rect to account for the fact that the
    // first line drawn may start above the update rect (and extend down into
    // it).
    update.top = (LONG) (first_line * lineheight - m_scroll_pos);

    SelectFont(dc, GetFont());
    TextOutStream textout(dc, update.top);

    textout << hex << setfill(L'0');

    do
    {
        textout << setw(8) << i << L": ";

        size_t b;

        for (b = 0; b < 16 && i < m_count; ++b)
        {
            textout << setw(2) << m_bytes[i] << L" ";
            ++i;
        }

        size_t b2 = b;
        i -= b;

        for ( ; b < 16; ++b)
            textout << L"   ";

        textout << L"   ";

        for ( ; b2 > 0; --b2)
        {
            WCHAR c = IsPrintableHexCharacter(m_bytes[i]) ? (WCHAR) m_bytes[i] : L'.';
            textout << c;
            ++i;
        }

        textout << endl;

        update.top += (LONG) lineheight;
    }
    while (update.top < update.bottom && i < m_count);
}

size_t HexDumpRenderer::GetTotalHeight(HDC /* UNREF dc */)
{
    size_t lines = (m_count + 15) / 16;
    
    lines = max(lines, (size_t) 1);      // show one line even if 0 bytes

    return lines * LineHeight();
}

HFONT HexDumpRenderer::GetFont()
{
    return GetStockFont(SYSTEM_FIXED_FONT);
}

size_t HexDumpRenderer::LineHeight()
{
    HDC dc = GetDC(NULL);
    HFONT oldfont = SelectFont(dc, GetFont());
    TEXTMETRIC tm;

    GetTextMetrics(dc, &tm);

    SelectFont(dc, oldfont);

    return tm.tmHeight + tm.tmExternalLeading;
}


Renderer * CreateHexDumpRenderer(const void * data, size_t length)
{
    return new HexDumpRenderer(data, length);
}
