#include "ttview.h"
#include "FontNode.h"
#include "GlyphView.h"


using std::wstring;
using std::vector;
using std::min;


struct Metrics
{
    BigEndian<USHORT>   advance_width;
    BigEndian<SHORT>    left_side_bearing;
};
C_ASSERT(sizeof(Metrics) == 4);


class hmtx : public FontNode, public GlyphViewStrings
{
public:

    static FontNode * Create(UINode &uinode, const byte * data, size_t length, FontFile & fontfile);

    hmtx(UINode & uinode, const byte * data, size_t length, FontFile & fontfile);

    virtual wstring GetTooltip();

    virtual vector<wstring> GetStrings(USHORT glyph) const;

private:

    FontFile & m_fontfile;
};


FontNode * hmtx::Create(UINode &uinode, const byte * data, size_t length, FontFile & fontfile)
{
    return new hmtx(uinode, data, length, fontfile);
}


hmtx::hmtx(UINode & /* UNREF uinode */, const byte * data, size_t length, FontFile & fontfile)
      : FontNode(data, length),
        m_fontfile(fontfile)
{
    m_renderer.reset(CreateGlyphViewRenderer(this, fontfile));
}


wstring hmtx::GetTooltip()
{
    return L"Horizontal Metrics";
}


template <typename From>
wstring itoa(const From & x)
{
    std::wstringstream str;
    str << x;
    return str.str();
}


vector<wstring> hmtx::GetStrings(USHORT glyph) const
{
    vector<wstring> strings;
    USHORT          hmetrics = m_fontfile.GetHorizontalMetricCount();

    if (hmetrics == 0)
    {
        strings.push_back(L"Invalid horizontal metric count in hhea table");
        return strings;
    }

    const Metrics * metrics = reinterpret_cast<const Metrics *>(m_data);
    size_t metric = min(glyph, USHORT(hmetrics - 1));
    size_t max_metric = m_length / sizeof(*metrics);

    if (metric > max_metric)
    {
        strings.push_back(L"(table to short)");
        return strings;
    }

    wstring advance_width = itoa(metrics[metric].advance_width);
    wstring left_side_bearing = itoa(metrics[metric].left_side_bearing);

    if (glyph != metric)
    {
        const BigEndian<SHORT> * lbearings = reinterpret_cast<const BigEndian<SHORT> *>(metrics + hmetrics);
        const BigEndian<SHORT> * lsb = &lbearings[glyph - metric];

        if (m_fontfile.IsInFile(lsb, sizeof(USHORT)))
            left_side_bearing = itoa(*lsb);
        else
            left_side_bearing = L"(table to short)";
    }

    strings.push_back(wstring(L"advance width = ") + advance_width);
    strings.push_back(wstring(L"left side bearing = ") + left_side_bearing);

    return strings;
}


RegisteredFontNode hmtx_registration('hmtx', &hmtx::Create);