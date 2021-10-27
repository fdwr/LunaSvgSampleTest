#include <string>
#include <map>
#include <vector>
#include <sstream>

std::wstring Utf8ToWString(const std::string & s);

class XmlElement
{
public:

    XmlElement(const char *& xml, const char * xml_end);
//    XmlElement(const XmlElement & o);
//    XmlElement & operator = (const XmlElement & o);

    operator std::string()  {return m_name;}

    std::wstring operator[] (const std::string & attribute) const;
//    operator bool() const {return m_document != NULL;}
    const std::string & Name() const;

    typedef std::vector<XmlElement> Children;
    typedef Children::const_iterator child_iterator;

    child_iterator children_begin() const;
    child_iterator children_end() const;

private:

    typedef std::map<std::string, std::string> Attributes;
    
    std::string m_name;
    Attributes  m_attributes;
    Children    m_children;

    void ParseElement(const char * element, const char * element_end);
};



struct XmlTableEntry
{
    enum Type
    {
        Char,
        Byte,
        Short,
        UShort,
        ULong,
        Tag,
        Fixed,
        LongDateTime,
        Panose
    };

    Type            type;
    size_t          elements;
    std::wstring    name;
    std::wstring    description;
    bool            hex;
    const byte *    data;

    XmlTableEntry(const XmlElement & element, const byte * data);

    size_t size() const;

    operator std::wstring() const;
    void FormatAsDateTime(std::wstringstream & str) const;
    void FormatAsPanose(std::wstringstream & str) const;
};


class XmlNode : public FontNode
{
public:

    XmlNode(UINode & uinode, const XmlElement & xml, const byte * data, size_t length, FontFile & fontfile);

    virtual std::wstring GetTooltip() {return m_description;}
    virtual void         SetupUI(HWND parent_window);
    virtual void         TeardownUI(HWND window);

protected:

    typedef std::vector<XmlTableEntry> Entries;

    UINode &     m_uinode;
    FontFile &   m_fontfile;
    std::wstring m_description;
    Entries      m_entries;
    HWND         m_listview;
    float        m_table_version;

    void GetEntries(const XmlElement & element, const byte *& data, const byte * data_end);
    void ParseBitfieldData(const XmlElement & element, XmlTableEntry & entry);
    void ParseEnumData(const XmlElement & element, XmlTableEntry & entry);

    virtual void OnNotify(int control, const NMHDR * notification);
};
