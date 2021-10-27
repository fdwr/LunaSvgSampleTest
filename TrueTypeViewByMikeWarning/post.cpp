#include "ttview.h"
#include "FontNode.h"
#include "Xml.h"

using std::wstring;
using std::string;
using std::wstringstream;
using std::vector;
using std::runtime_error;
using std::distance;

typedef USHORT FWORD;

#pragma pack(push, 1)

struct V1Header
{
    Fixed               version;
    Fixed               italicAngle;
    BigEndian<FWORD>    underlinePosition;
    BigEndian<FWORD>    underlineThickness;
    BigEndian<ULONG>    isFixedPitch;
    BigEndian<ULONG>    minMemType42;
    BigEndian<ULONG>    maxMemType42;
    BigEndian<ULONG>    minMemType1;
    BigEndian<ULONG>    maxMemType1;
};
C_ASSERT(sizeof(V1Header) == 32);

struct V2Header : public V1Header
{
    BigEndian<USHORT>   numOfGlyphs;
    BigEndian<USHORT>   glyphNameIndex[];
//  char                names;
};
C_ASSERT(sizeof(V2Header) == 34);

#pragma pack(pop)

class postNode : public XmlNode
{
public:

    static FontNode * Create(UINode &uinode, const byte * data, size_t length, FontFile & fontfile);
    postNode(const char * xml, const char * xml_end, UINode & uinode, const byte * data, size_t length, FontFile & fontfile);

    virtual wstring GetTooltip();
    virtual void    SetupUI(HWND parent_window);
    virtual void    TeardownUI(HWND parent_window);

private:

    typedef vector<USHORT>       GlyphNameIndices;
    typedef vector<const char *> Names;

    GlyphNameIndices m_glyph_name_indices;
    Names            m_names;
    HWND             m_glyph_view;
};


postNode::postNode(const char * xml, const char * xml_end, UINode & uinode, const byte * data, size_t length, FontFile & fontfile)
      : XmlNode(uinode, XmlElement(xml, xml_end), data, length, fontfile)
{
    if (m_table_version != 2.0f)
        return;

    const BigEndian<USHORT> * index_entries = reinterpret_cast<const BigEndian<USHORT> *>(m_entries.rbegin()[0].data);
    USHORT numberOfGlyphs = * reinterpret_cast<const BigEndian<USHORT> *>(m_entries.rbegin()[1].data);

    m_glyph_name_indices.reserve(numberOfGlyphs);
    m_glyph_name_indices.resize(258);
    m_names.reserve(numberOfGlyphs);
    m_names.resize(258);

    for (USHORT i = 258; i < numberOfGlyphs; ++i)
    {
        const byte * current = reinterpret_cast<const byte *>(&index_entries[i]);
        if ((size_t) (current - data) > length)
            throw runtime_error("post table to short for glyph indices");

        m_glyph_name_indices.push_back(index_entries[i]);
    }

    const char * names = reinterpret_cast<const char *>(&index_entries[numberOfGlyphs]);
    for (USHORT i = 258; i < numberOfGlyphs; ++i)
    {
        const byte * current = reinterpret_cast<const byte *>(names);
        if ((size_t) (current - data) > length)
            throw runtime_error("post table to short for glyph names");

        m_names.push_back(names);
        names += names[0] + 1;
    }
}


wstring postNode::GetTooltip()
{
    return L"PostScript information";
}


void postNode::SetupUI(HWND parent_window)
{
    XmlNode::SetupUI(parent_window);

    RECT client_area;

    GetClientRect(parent_window, &client_area);

    MoveWindow(
            m_listview, 
            client_area.left, 
            client_area.top, 
            client_area.right - client_area.left, 
            (client_area.bottom - client_area.top) / 2, 
            true);

    m_glyph_view = CreateWindowEx(
                        LVS_EX_FULLROWSELECT,
                        WC_LISTVIEW,
                        L"",
                        WS_CHILD | WS_VISIBLE | LVS_REPORT,
                        client_area.left,
                        (client_area.bottom - client_area.top) / 2,
                        client_area.right - client_area.left,
                        (client_area.bottom - client_area.top) / 2,
                        parent_window,
                        (HMENU) 0,
                        Globals::Instance,
                        NULL);              

    if (!m_listview)
        return;

    LVCOLUMN column;
    column.mask = LVCF_TEXT;
    column.pszText = L"Glyph";
    ListView_InsertColumn(m_glyph_view, 0, &column);
    column.pszText = L"Name Index";
    ListView_InsertColumn(m_glyph_view, 1, &column);
    column.pszText = L"Name";
    ListView_InsertColumn(m_glyph_view, 2, &column);

    for (GlyphNameIndices::iterator i = m_glyph_name_indices.begin(); i != m_glyph_name_indices.end(); ++i)
    {
        size_t glyph_index = distance(m_glyph_name_indices.begin(), i);

        wstringstream glyph_str;
        glyph_str << glyph_index;
        wstring glyph = glyph_str.str();

        LVITEM newitem;
        newitem.mask = LVIF_TEXT;
        newitem.pszText = const_cast<LPWSTR>(glyph.c_str());
        newitem.iItem = INT_MAX;
        newitem.iSubItem = 0;
        int item_index = ListView_InsertItem(m_glyph_view, &newitem);

        if (m_names[glyph_index])
        {
            wstringstream index_str;
            index_str << m_glyph_name_indices[glyph_index];
            wstring index = index_str.str();
            ListView_SetItemText(m_glyph_view, item_index, 1, const_cast<LPWSTR>(index.c_str()));

            string namea = string(m_names[glyph_index] + 1, m_names[glyph_index][0]);
            wstring name(Utf8ToWString(namea));
            ListView_SetItemText(m_glyph_view, item_index, 2, const_cast<LPWSTR>(name.c_str()));
        }
    }

    ListView_SetColumnWidth(m_glyph_view, 0, LVSCW_AUTOSIZE);
    ListView_SetColumnWidth(m_glyph_view, 1, LVSCW_AUTOSIZE);
    ListView_SetColumnWidth(m_glyph_view, 2, LVSCW_AUTOSIZE);
}


void postNode::TeardownUI(HWND parent_window)
{
    if (m_glyph_view)
        DestroyWindow(m_glyph_view);

    XmlNode::TeardownUI(parent_window);
}



FontNode * postNode::Create(UINode &uinode, const byte * data, size_t length, FontFile & fontfile)
{
    HRSRC resource = FindResource(Globals::Instance, L"post", L"XMLTABLE");
    if (!resource)
        return NULL;

    HGLOBAL hg = LoadResource(Globals::Instance, resource);
    if (!hg)
        return NULL;

    const char * xml = (const char *) LockResource(hg);
    if (!xml)
        return NULL;

    DWORD xml_size = SizeofResource(Globals::Instance, resource);

    return new postNode(xml, xml + xml_size, uinode, data, length, fontfile);
}

    
RegisteredFontNode post_registration('post', &postNode::Create);