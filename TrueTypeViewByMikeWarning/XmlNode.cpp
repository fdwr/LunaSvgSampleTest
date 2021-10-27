#include "ttview.h"
#include "FontNode.h"
#include "uinode.h"
#include <vector>
#include <stack>
#include <algorithm>
#include <map>
#include <sstream>
#include "xml.h"

using std::vector;
using std::string;
using std::wstring;
using std::wstringstream;
using std::find;
using std::find_if;
using std::runtime_error;
using std::map;
using std::hex;
using std::setfill;
using std::setw;
using std::stack;

#undef GetFirstChild        // windows macro

#pragma comment(linker,"/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' "\
"version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")


wstring Utf8ToWString(const string & s)
{
    wstring result(s.length(), '\0');

    result.resize(MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int) s.size(), &result[0], (int) result.size()));

    return result;
}



/*
inline int isspace(char c)
{
    return isspace(byte(c));
}
*/






wstring XmlElement::operator [](const std::string &attribute) const
{
    map<string, string>::const_iterator p = m_attributes.find(attribute);

    if (p != m_attributes.end())
        return Utf8ToWString(p->second);
    else
        return L"";
}


const string & XmlElement::Name() const
{
    return m_name;
}


XmlElement::child_iterator XmlElement::children_begin() const
{
    return m_children.begin();
}


XmlElement::child_iterator XmlElement::children_end() const
{
    return m_children.end();
}

/*
XmlDocument::XmlDocument(const XmlDocument & o)
      : m_name(o.m_name),
        m_attributes(o.m_attributes),
        m_children(o.m_children)
{
}


XmlDocument & XmlDocument::operator= (const XmlDocument & o)
{
    m_name = o.m_name;
    m_attributes = o.m_attributes;
    m_children = o.m_children;

    m_document = this;

    return *this;
}
*/

XmlElement::XmlElement(const char *& xml, const char * xml_end)
{
    if (xml == xml_end && xml[0] == '<')
        throw runtime_error("missing xml open bracket");

    const char * element = xml;
    const char * element_end = find(element, xml_end, '>');
    if (element_end == xml_end)
        throw runtime_error("missing xml close bracket");

    if (element[1] == '/')
        throw runtime_error("unmatched closing tag");

    ++element_end;
    ParseElement(element, element_end);

    xml = element_end;

    if (element_end[-2] == '/')
        return;

    for (;;)
    {
        while (xml != xml_end && isspace(*xml))
            ++xml;

        if (*xml != '<')
            throw runtime_error("missing xml open bracket");

        if (xml + 1 == xml_end)
            throw runtime_error("missing xml close bracket");

        if (xml[1] == '/')
                break;

        m_children.push_back(XmlElement(xml, xml_end));
    }

    const char * closing_name = &xml[2];
    const char * closing_name_end = closing_name;
    while (closing_name_end != xml_end && !isspace(closing_name_end[0]) && closing_name_end[0] != '>')
        ++closing_name_end;

    if (string(closing_name, closing_name_end) != m_name)
        throw runtime_error("mismatched closing tag");

    xml = closing_name_end + 1;
}


inline bool isnotprint(char c)
{
    return !isprint((byte) c);
}

inline bool isnotspace(char c)
{
    return !isspace((byte) c);
}

void XmlElement::ParseElement(const char * element, const char * element_end)
{
    assert(element[0] == '<' && element_end[-1] == '>');

    ++element;
    --element_end;

    const char * name = element;
    const char * name_end = find_if(name, element_end, isspace);

    m_name = string(name, name_end);

    const char * attribute = name_end;
    while (attribute != element_end)
    {
        attribute = find_if(attribute, element_end, isnotspace);
        if (attribute == element_end)
            break;

        if (attribute[0] == '/' && attribute[1] == '>')
            break;

        const char * attribute_end = find(attribute, element_end, '=');
        if (attribute_end == element_end)
            throw runtime_error("missing xml attribute value");

        const char * value = attribute_end + 1;
        if (value == element_end || (*value != '\"' && *value != '\''))
            throw runtime_error("xml attribute must be quoted");
        
        const char * value_end = find(value + 1, element_end, *value);
        if (value_end == element_end)
            throw runtime_error("missing close quote on xml attribute");

        m_attributes[string(attribute, attribute_end)] = string(value + 1, value_end);

        attribute = value_end + 1;
    }
}


XmlTableEntry::XmlTableEntry(const XmlElement & element, const byte * data)
      : name(element["name"]),
        elements(1),
        hex(false),
        data(data)
{
    wstring type = element["type"];
    
    wstring::iterator open_bracket = find(type.begin(), type.end(), '[');
    if (open_bracket != type.end())
    {
        wstring::iterator close_bracket = find(open_bracket, type.end(), ']');
        if (close_bracket == type.end())
            throw runtime_error("unmatched brackets in array specification");

        wstringstream str(wstring(open_bracket + 1, close_bracket));
        str >> elements;

        type.resize(distance(type.begin(), open_bracket));
    }

    if (type == L"CHAR")
        this->type = XmlTableEntry::Char;
    else if (type == L"BYTE")
        this->type = XmlTableEntry::Byte;
    else if (type == L"SHORT")
        this->type = XmlTableEntry::Short;
    else if (type == L"USHORT")
        this->type = XmlTableEntry::UShort;
    else if (type == L"ULONG")
        this->type = XmlTableEntry::ULong;
    else if (type == L"Tag")
        this->type = XmlTableEntry::Tag;
    else if (type == L"Fixed")
        this->type = XmlTableEntry::Fixed;
    else if (type == L"LONGDATETIME")
        this->type = XmlTableEntry::LongDateTime;
    else if (type == L"PANOSE")
        this->type = XmlTableEntry::Panose;
    else if (type == L"FWORD")
        this->type = XmlTableEntry::Short;
    else if (type == L"UFWORD")
        this->type = XmlTableEntry::UShort;
    else
        throw runtime_error("Unknown entry type");

    if (element["semantic"] == L"bitfield")
        hex = true;
}


size_t XmlTableEntry::size() const
{
    switch (type)
    {
    case Char:
    case Byte:
        return 1 * elements;

    case Short:
    case UShort:
        return 2 * elements;

    case ULong:
    case Tag:
    case Fixed:
        return 4 * elements;

    case LongDateTime:
        return 8 * elements;

    case Panose:
        return 10 * elements;
    }

    throw runtime_error("Unknown entry type");
}


XmlTableEntry::operator wstring() const
{
    wstringstream value;

    if (hex)
        value << L"0x" << setw(std::streamsize(size()) * 2) << setfill(L'0') << std::hex;

    switch (type)
    {
    case Char:
      {
          const char * str = reinterpret_cast<const char *>(data);
          value << Utf8ToWString(string(str, str + elements));
          break;
      }

    case Byte: value << * (BYTE *) data; break;
    case Short: value << * (BigEndian<SHORT> *) data; break;
    case UShort: value << * (BigEndian<USHORT> *) data; break;
    case ULong: value << * (BigEndian<ULONG> *) data; break;
    
    case Tag:
      {
        const char * id = reinterpret_cast<const char *>(data);
        value << id[0] << id[1] << id[2] << id[3]; 
        break;
      }

    case Fixed:
      {
        ULONG fixed = * (BigEndian<ULONG> *) data;
        value << HIWORD(fixed) << '.' << LOWORD(fixed);
        break;
      }

    case LongDateTime: FormatAsDateTime(value); break;
    case Panose: FormatAsPanose(value); break;
    }

    return value.str();
}


void XmlTableEntry::FormatAsDateTime(wstringstream & str) const
{
    // the reference time is Midnight, January 1, 1904
    SYSTEMTIME sys = {0};
    sys.wYear = 1904;
    sys.wMonth = 1;
    sys.wDay = 1;

    FILETIME ref;
    SystemTimeToFileTime(&sys, &ref);

    ULARGE_INTEGER newtime;
    newtime.HighPart = ref.dwHighDateTime;
    newtime.LowPart = ref.dwLowDateTime;

    unsigned __int64 offset = * (BigEndian<__int64> *) data;
    newtime.QuadPart += offset * 10000000;
    ref.dwHighDateTime = newtime.HighPart;
    ref.dwLowDateTime = newtime.LowPart;

    WCHAR date[256];
    WCHAR time[256];

    BOOL ok = FileTimeToSystemTime(&ref, &sys);                
    ok = ok && GetDateFormat(LOCALE_USER_DEFAULT, DATE_LONGDATE, &sys, NULL, date, ARRAYSIZE(date));
    ok = ok && GetTimeFormat(LOCALE_USER_DEFAULT, 0, &sys, NULL, time, ARRAYSIZE(time));
      
    if (ok)
        str << date << ", " << time;
    else
        str << offset;
}


void XmlTableEntry::FormatAsPanose(wstringstream & str) const
{
    const wchar_t * space = L"";

    str << std::hex << setfill(L'0');

    for (int i = 0; i < 10; ++i, space = L" ")
        str << space << setw(2) << data[i];
}




XmlNode::XmlNode(UINode & uinode, const XmlElement & xml, const byte * data, size_t length, FontFile & fontfile)
      : FontNode(data, length),
        m_uinode(uinode),
        m_fontfile(fontfile),
        m_table_version(0)
{
    m_description = xml["description"];

    GetEntries(xml, data, data + length);
}

void XmlNode::GetEntries(const XmlElement & element, const byte *& data, const byte * data_end)
{
    XmlElement::child_iterator child = element.children_begin();
    XmlElement::child_iterator end = element.children_end();

    for ( ; child != end; ++child)
    {
        const XmlElement & child_element(*child);

        if (child->Name() == "entry")
        {
            XmlTableEntry entry(*child, data);

//            if (size_t(data_end - data) < entry.size())
//                throw runtime_error("short table");

            if (child_element["semantic"] == L"version")
            {
                wstringstream wtof(entry);
                wtof >> m_table_version;
            }
            else if (child_element["semantic"] == L"bitfield")
            {
                ParseBitfieldData(child_element, entry);
            }
            else if (child_element["semantic"] == L"enum")
            {
                ParseEnumData(child_element, entry);
            }

            if (child_element["global_property"] == L"glyph_count")
            {
                USHORT glyph_count;
                wstringstream atoi(entry);
                atoi >> glyph_count;
                m_fontfile.SetGlyphCount(glyph_count);
            }
            else if (child_element["global_property"] == L"numberofHMetrics")
            {
                USHORT hmetrics;
                wstringstream atoi(entry);
                atoi >> hmetrics;
                m_fontfile.SetHorizontalMetricCount(hmetrics);
            }

            m_entries.push_back(entry);
            data += entry.size();

        }
        else if (child->Name() == "extension")
        {
            float child_version;
            wstringstream wtof(child_element["version"]);
            wtof >> child_version;

            if (m_table_version >= child_version)
                GetEntries(child_element, data, data_end);
        }
        else if (child->Name() == "subtable")
        {
            UINode subnode = m_uinode.AddChild(L"Signature");
            subnode.SetFontNode(new XmlNode(m_uinode, child_element, data, data_end-data, m_fontfile));
        }
    }
}


void XmlNode::ParseBitfieldData(const XmlElement & element, XmlTableEntry & entry)
{
    XmlElement::child_iterator child = element.children_begin();
    XmlElement::child_iterator end = element.children_end();

    ULONG value;
    wstringstream str(entry);
    value = wcstoul(((wstring)entry).c_str(), NULL, 0);
    const WCHAR * seperator = L"";

    for ( ; child != end; ++child)
    {
        if (child->Name() != "bitfield")
            throw runtime_error("invalid child element in bitfield data");
        
        XmlElement bitfield(*child);

        long bit;
        wstringstream bit_str(bitfield["bit"]);
        bit_str >> bit;

        bit = 1 << bit;

        if (value & bit)
        {
            entry.description += seperator + bitfield["description"];
            seperator = L"\r\n";
            value = value & ~bit;
        }
    }

    if (value)
    {
        wstringstream atoi;
        atoi << L"Unknown bits: 0x" << hex << value;
        entry.description += seperator + atoi.str();
    }
}


void XmlNode::ParseEnumData(const XmlElement & element, XmlTableEntry & entry)
{
    XmlElement::child_iterator child = element.children_begin();
    XmlElement::child_iterator end = element.children_end();

    long value;
    wstringstream str(entry);
    value = wcstol(((wstring)entry).c_str(), NULL, 0);

    entry.description = L"(unknown enum value)";

    for ( ; child != end; ++child)
    {
        if (child->Name() != "enum")
            throw runtime_error("invalid child element in enum data");
        
        XmlElement enum_element(*child);
        
        long enum_value = wcstol(enum_element["value"].c_str(), NULL, 0);
        if (enum_value == value)
        {
            entry.description = enum_element["description"];
            break;
        }
    }
}


void XmlNode::SetupUI(HWND parent_window)
{
    RECT client_area;

    GetClientRect(parent_window, &client_area);

    m_listview = CreateWindow(
                        WC_LISTVIEW,
                        L"",
                        WS_CHILD | WS_VISIBLE | LVS_REPORT,
                        client_area.left,
                        client_area.top,
                        client_area.right - client_area.left,
                        client_area.bottom - client_area.top,
                        parent_window,
                        (HMENU) 0,
                        Globals::Instance,
                        NULL);              

    if (!m_listview)
        return;

    ListView_SetExtendedListViewStyleEx(
            m_listview, 
            LVS_EX_FULLROWSELECT | LVS_EX_LABELTIP, 
            LVS_EX_FULLROWSELECT | LVS_EX_LABELTIP);

    LVCOLUMN column;
    column.mask = LVCF_TEXT;
    column.pszText = L"Field";
    ListView_InsertColumn(m_listview, 0, &column);
    column.pszText = L"Value";
    ListView_InsertColumn(m_listview, 1, &column);

    bool has_descriptions = false;

    for (Entries::iterator i = m_entries.begin(); i != m_entries.end(); ++i)
    {
        LVITEM newitem;
        newitem.mask = LVIF_TEXT;
        newitem.pszText = const_cast<LPWSTR>(i->name.c_str());
        newitem.iItem = INT_MAX;
        newitem.iSubItem = 0;
        int item_index = ListView_InsertItem(m_listview, &newitem);

        wstring value = *i;
        ListView_SetItemText(m_listview, item_index, 1, const_cast<LPWSTR>(value.c_str()));

        if (!i->description.empty())
        {
            if (!has_descriptions)
            {
                column.pszText = L"Description";
                ListView_InsertColumn(m_listview, 2, &column);
                has_descriptions = true;
            }

            wstring description = i->description;
            std::replace(description.begin(), description.end(), L'\r', L',');
            std::replace(description.begin(), description.end(), L'\n', L' ');

            ListView_SetItemText(m_listview, item_index, 2, const_cast<LPWSTR>(description.c_str()));

        }
    }

    ListView_SetColumnWidth(m_listview, 0, LVSCW_AUTOSIZE);
    ListView_SetColumnWidth(m_listview, 1, LVSCW_AUTOSIZE);

    if (has_descriptions)
        ListView_SetColumnWidth(m_listview, 2, LVSCW_AUTOSIZE_USEHEADER);
}


void XmlNode::TeardownUI(HWND /* UNREF parent_window */)
{
    if (m_listview)
        DestroyWindow(m_listview);
}


void XmlNode::OnNotify(int /* UNREF control */, const NMHDR * notification)
{
    if (notification->code == LVN_GETDISPINFOW)
        return;

    std::stringstream str;
    str << -(int)notification->code << " (" << notification->hwndFrom << ")\r\n";
    OutputDebugStringA(str.str().c_str());
}


FontNode * CreateXmlNode(const char * xml, const char * xmlend, UINode & uinode, const byte * data, unsigned length, FontFile & fontfile)
{
    XmlElement doc(xml, xmlend);
    return new XmlNode(uinode, doc, data, length, fontfile);
}