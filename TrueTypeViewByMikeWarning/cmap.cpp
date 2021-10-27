#include "ttview.h"
#include "FontNode.h"
#include "TextOutStream.h"
#include "UINode.h"
#include <vector>

using namespace std;


struct cmapSubtable
{
    BigEndian<USHORT>   format;
};
C_ASSERT(sizeof(cmapSubtable) == 2);


struct Format4Subtable : public cmapSubtable
{
    BigEndian<USHORT>   length;
    BigEndian<USHORT>   language;
    BigEndian<USHORT>   segCountX2;
    BigEndian<USHORT>   searchRange;
    BigEndian<USHORT>   entrySelector;
    BigEndian<USHORT>   rangeShift;

    // variable length data included in the table
//    BigEndian<USHORT>   endCount[segCount];
//    BigEndian<USHORT>   pad;
//    BigEndian<USHORT>   startCount[segCount];
//    BigEndian<USHORT>   idDelta[segCount];
//    BigEndian<USHORT>   idRangeOffset[segCount];
//    BigEndian<USHORT>   glyphIdArray[];
};
C_ASSERT(sizeof(Format4Subtable) == 14);




class Format4Renderer : public Renderer
{
public:

    Format4Renderer(const cmapSubtable & table, const FontFile & fontfile);

    virtual void    Render(HDC dc);
    virtual size_t  GetTotalHeight(HDC dc);

//    virtual void    SetupRenderInfo(HWND target);

protected:

    size_t HeaderHeight(HDC dc);
    void   RenderHeader(HDC dc);
    size_t FragmentHeights(HDC dc);
    void   RenderFragments(HDC dc, size_t top, size_t bottom);
    size_t FragmentHeight(HDC dc, USHORT i);
    void   RenderFragment(HDC dc, USHORT i, size_t top, size_t bottom);

    const Format4Subtable &     m_header;
    const BigEndian<USHORT> *   m_startCount;
    const BigEndian<USHORT> *   m_endCount;
    const BigEndian<USHORT> *   m_idDelta;
    const BigEndian<USHORT> *   m_idRangeOffset;

    const FontFile &            m_fontfile;
};


Format4Renderer::Format4Renderer(const cmapSubtable & table, const FontFile & fontfile)
      : m_header(static_cast<const Format4Subtable &>(table)),
        m_fontfile(fontfile)
{
    const byte * header = (const byte *) &m_header;
    USHORT segments = m_header.segCountX2 / 2;

    m_endCount = (const BigEndian<USHORT> *) (header + sizeof(m_header));
    m_startCount = m_endCount + segments + 1;
    m_idDelta = m_startCount + segments;
    m_idRangeOffset = m_idDelta + segments;
}


size_t Format4Renderer::GetTotalHeight(HDC dc)
{
    SelectFont(dc, m_fontfile.TextFont());
    return HeaderHeight(dc) + FragmentHeights(dc);
}


void Format4Renderer::Render(HDC dc)
{
    SelectFont(dc, m_fontfile.TextFont());

    RECT update;
//    GetUpdateRect(WindowFromDC(dc), &update, false);
    GetClipBox(dc, &update);

    OffsetRect(&update, 0, (int) m_scroll_pos);
    OffsetWindowOrgEx(dc, 0, (int) m_scroll_pos, NULL);

    size_t header_height = HeaderHeight(dc);

    if ((size_t) update.top < header_height)
    {
        RenderHeader(dc);
        update.top += (int) header_height;

        if ((size_t) update.bottom < header_height)
            return;
    }

    OffsetRect(&update, 0, - (int) header_height);
    OffsetViewportOrgEx(dc, 0, (int) header_height, NULL);    
    

    RenderFragments(dc, update.top, update.bottom);
}


size_t Format4Renderer::HeaderHeight(HDC dc)
{
    TEXTMETRIC tm;
    GetTextMetrics(dc, &tm);

    return 3 * tm.tmHeight;
}


void Format4Renderer::RenderHeader(HDC dc)
{
    TextOutStream textout(dc);

    textout << L"cmap format 4 subtable" << endl
            << L"Segments: " << m_header.segCountX2 / 2 << endl
            << endl;
}


size_t Format4Renderer::FragmentHeights(HDC dc)
{
    size_t height = 0;

    for (USHORT i = 0; i < m_header.segCountX2 / 2; ++i)
        height += FragmentHeight(dc, i);

    // The last fragment does not have a footer.
    TEXTMETRIC tm;
    GetTextMetrics(dc, &tm);

    return height - tm.tmHeight;
}


void Format4Renderer::RenderFragments(HDC dc, size_t update_top, size_t update_bottom)
{
    size_t frag_top;
    size_t frag_bottom = 0;

    for (USHORT i = 0; i < m_header.segCountX2 / 2; ++i)
    {
        // Determine if this segment is in the update area
        frag_top = frag_bottom;
        frag_bottom = frag_top + FragmentHeight(dc, i);

        if (frag_top > update_bottom)
            break;

        if (frag_bottom < update_top)
            continue;

        // Adjust the origin to the beginning of this segment
        POINT old_org;
        OffsetViewportOrgEx(dc, 0, (int) frag_top, &old_org);

        // Render the intersection of this segment with the update area
        size_t render_top = max(update_top, frag_top) - frag_top;
        size_t render_bottom = min(update_bottom, frag_bottom) - frag_top;
        RenderFragment(dc, i, render_top, render_bottom);

        SetViewportOrgEx(dc, old_org.x, old_org.y, NULL);
    }
}


size_t Format4Renderer::FragmentHeight(HDC dc, USHORT i)
{
    RECT rect;
    GetClientRect(WindowFromDC(dc), &rect);

    USHORT start = m_startCount[i];
    USHORT end = m_endCount[i];

    SIZE   cell = m_fontfile.GetGlyphCellSize();
    size_t columns = max(1L, (rect.right - rect.left) / cell.cx);
    size_t rows = max(size_t(1), (end - start + 1 + columns - 1) / columns);

    TEXTMETRIC tm;
    GetTextMetrics(dc, &tm);

    return 2 * tm.tmHeight + rows * cell.cy + 1;
}

void DrawGlyph(const FontFile & fontfile, HDC dc, int x, int y, USHORT glyph, char32_t c);

void Format4Renderer::RenderFragment(HDC dc, USHORT i, size_t top, size_t bottom)
{
    TextOutStream textout(dc);

    textout << L"Segment " << i
            << hex
            << L" - Start: U+" << m_startCount[i]
            << L", End: U+" << m_endCount[i]
            << L", Delta: " << m_idDelta[i]
            << L", Offset: " << m_idRangeOffset[i]
            << endl;

    if (bottom < (size_t) textout.GetPosition().y)
        return;

    top = max(top, (size_t) textout.GetPosition().y);
    
    // Make the math a bit easier below
    OffsetViewportOrgEx(dc, 0, textout.GetPosition().y, NULL);
    top -= textout.GetPosition().y;
    bottom -= textout.GetPosition().y;

    // Get the width of the client area
    RECT rect;
    GetClientRect(WindowFromDC(dc), &rect);

    // Parameters for this segment
    USHORT start = m_startCount[i];
    USHORT end = m_endCount[i];
    USHORT delta = m_idDelta[i];
    USHORT offset = m_idRangeOffset[i];

    const BigEndian<USHORT> * glyph_ids = &m_idRangeOffset[i] + offset / 2;

    SIZE   cell = m_fontfile.GetGlyphCellSize();
    int    columns = max(1L, (rect.right - rect.left) / cell.cx);
    int    column = 0;
    int    y = ((int) top / cell.cy) * cell.cy;

    USHORT c = (USHORT) (start + columns * (y / cell.cy));

    // If we're drawing the bottom line of the last row it will appear as if
    // we're drawing the first line of the (non-existant) next row, compensate
    if (c > end)
    {
        c -= (USHORT) columns;
        y -= cell.cy;
    }

    // Compensate for the ++c at the start of the loop below
    --c;

    // Draw
    do
    {
        ++c;

        USHORT glyph = c;

        if (offset != 0)
            glyph = glyph_ids[c - start];

        if (offset == 0 || glyph != 0)
            glyph = glyph + delta;

        int x = column * cell.cx;

        DrawGlyph(m_fontfile, dc, x, y, glyph, c);

        ++column;
        if (column == columns)
        {
            column = 0;
            y += cell.cy;
        }
    }
    while (c != end && (size_t) y < bottom);

    SelectFont(dc, m_fontfile.TextFont());
}



class MicrosoftUnicode : public FontNode
{
public:

    MicrosoftUnicode(const cmapSubtable & table, const FontFile & fontfile);

    virtual wstring GetTooltip();
};


MicrosoftUnicode::MicrosoftUnicode(const cmapSubtable & table, const FontFile & fontfile)
      : FontNode(NULL, 0)
{    
    if (table.format == 4)
        m_renderer.reset(new Format4Renderer(table, fontfile));
/*    else if (table.format == 12)
        m_renderer.reset(new Format12(table, fontfile));
        */
}


wstring MicrosoftUnicode::GetTooltip()
{
    return L"";
}



class cmap : public FontNode
{
    friend class cmapMicrosoftUnicode4;

    struct EncodingRecord
    {
        BigEndian<USHORT>   platformID;
        BigEndian<USHORT>   encodingID;
        BigEndian<ULONG>    offset;

        enum
        {
            MicrosoftPlatform = 3
        };

        std::wstring EncodingName() const;
    };

    struct Header
    {
        BigEndian<USHORT>   version;
        BigEndian<USHORT>   numTables;
        EncodingRecord      records[];
    };

public:

    cmap(UINode & uinode, const byte * data, size_t length, FontFile & fontfile);

    virtual wstring GetTooltip();
};


cmap::cmap(UINode &uinode, const byte * data, size_t length, FontFile & fontfile)
      : FontNode(data, length)
{
    const Header & header = (const Header &) *data;

    assert(header.version == 0);

    for (USHORT i = 0; i < header.numTables; i++)
    {
        const EncodingRecord & record = header.records[i];
        const cmapSubtable & subtable = OffsetTo<cmapSubtable>(header, record.offset);

        UINode child = uinode.AddChild(record.EncodingName());

        if (record.platformID == EncodingRecord::MicrosoftPlatform
            && (record.encodingID == 1 || record.encodingID == 10))
        {
            child.SetFontNode(new MicrosoftUnicode(subtable, fontfile));
        }
        else
        {
            child.SetFontNode(new UnknownNode(data, length, fontfile));
        }
    }
}


wstring cmap::GetTooltip()
{
    return L"Defines the mapping of character codes to glyph index values.";
}


static const WCHAR * Platforms[] = 
{
    L"Unicode",
    L"Macintosh",
    NULL,
    L"Microsoft"
};

static const WCHAR * MacintoshEncodings[] =
{
    L"Roman",
    L"Japanese",
};

static const WCHAR * UnicodeEncodings[] = 
{
    L"(default)",
    L"1.1",
    L"ISO 10646 1993",
    L"2.0"
};

static const WCHAR * MicrosoftEncodings[] = 
{
    L"Symbol",
    L"Unicode",
    L"ShiftJIS",
    L"PRC",
    L"Big5",
    L"Wansung",
    L"Johab",
    NULL,
    NULL,
    NULL,
    L"UCS-4"
};


wstring cmap::EncodingRecord::EncodingName() const
{
    const WCHAR * platform = NULL;
    const WCHAR * encoding = NULL;

    if (platformID < ARRAYSIZE(Platforms))
        platform = Platforms[platformID];

    if (platform)
    {
        if (platformID == 0 && encodingID < ARRAYSIZE(UnicodeEncodings))
            encoding = UnicodeEncodings[encodingID];
        else if (platformID == 1 && encodingID < ARRAYSIZE(MacintoshEncodings))
            encoding = MacintoshEncodings[encodingID];
        else if (platformID == 3 && encodingID < ARRAYSIZE(MicrosoftEncodings))
            encoding = MicrosoftEncodings[encodingID];
    }

    wstring name;
    
    if (platform)
    {
        name = wstring(platform) + L"/";
    }
    else
    {
        wstringstream s;
        s << L"(unknown:" << platformID << ")/";
        name = s.str();
    }

    if (encoding)
    {
        name += wstring(encoding);
    }
    else
    {
        wstringstream s;
        s << L"(unknown:" << encodingID << ")";
        name += s.str();
    }

    return name;
}




FontNode * CreatecmapNode(UINode &uinode, const byte * data, size_t length, FontFile & fontfile)
{
    return new cmap(uinode, data, length, fontfile);
}

RegisteredFontNode cmap('cmap', &CreatecmapNode);