#include "ttview.h"
#include "FontNode.h"
#include "TextOutStream.h"
#include "UINode.h"
#include "CommonTables.h"
#include <map>

using namespace std;


FontNode * CreateGSUBLookupNode(UINode & uinode, const Lookup & lookup, USHORT lookupType, const FontFile & fontfile);


struct Header
{
    Fixed               Version;
    BigEndian<Offset>   ScriptList;
    BigEndian<Offset>   FeatureList;
    BigEndian<Offset>   LookupList;
};



class GSUB : public FontNode
{
public:

    GSUB(UINode & uinode, const byte * data, size_t length, FontFile & fontfile);

    virtual std::wstring GetTooltip();
    virtual void         Render(HDC dc);

private:

    void ReadScriptTable(const ScriptTable & table, UINode & uinode, FontFile & fontfile);
    void ReadLangSysTable(const LangSysTable & table, UINode & uinode, FontFile & fontfile);
    void ReadFeature(const Feature & feature, UINode & uinode, FontFile & fontfile);
    void PrintScriptList();

    const Header & m_header;
    const FeatureList * m_features;
};






Tag::operator wstring () const
{
    wstring str(4, L' ');

    for (int i = 0; i < 4; ++i)
        str[i] = data[i];

    return str;
}



GSUB::GSUB(UINode & uinode, const byte * data, size_t length, FontFile & fontfile)
      : FontNode(data, length),
        m_header( *reinterpret_cast<const Header *>(data) )
{
    if (!fontfile.IsInFile(data, length))
    {
        m_invalid = L"The data for this table is invalid and lies outside the bounds of the file.";
        return;
    }

    if (length < sizeof(Header))
    {
        m_invalid = L"The table data is not big enough for the GSUB header.";
        return;
    }

    const Header * header = (const Header *) data;

    if (header->ScriptList >= length)
    {
        m_invalid = L"The script list offset lies outside the table.";
        return;
    }

    if (header->Version != 1.0)
    {
        m_invalid = L"Unknown GSUB table version number.";
        return;
    }

    if (header->FeatureList >= length)
    {
        m_invalid = L"The feature list offset lies outside the table.";
        return;
    }

    if (header->LookupList >= length)
    {
        m_invalid = L"The lookup list offset lies outside the table.";
        return;
    }
            
    m_features = &OffsetTo<FeatureList>(*header, header->FeatureList);

    const ScriptList & scripts = OffsetTo<ScriptList>(*header, header->ScriptList);
    for (USHORT i = 0; i != scripts.ScriptCount; ++i)
    {
        const ScriptRecord & record = scripts.ScriptRecords[i];

        UINode node = uinode.AddChild(record.Tag);
        node.SetFontNode(new UnknownNode(NULL, 0, fontfile));

        ReadScriptTable(OffsetTo<ScriptTable>(scripts, record.ScriptTable), node, fontfile);
    }
}


void GSUB::ReadScriptTable(const ScriptTable & table, UINode & uinode, FontFile & fontfile)
{
    if (table.DefaultLangSys)
    {
        UINode node = uinode.AddChild(L"(default)");
        node.SetFontNode(new UnknownNode(NULL, 0, fontfile));
        ReadLangSysTable(OffsetTo<LangSysTable>(table, table.DefaultLangSys), node, fontfile);
    }

    for (USHORT i = 0; i != table.LangSysCount; ++i)
    {
        const LangSysRecord & record = table.LangSysRecords[i];

        UINode node = uinode.AddChild(record.Tag);
        node.SetFontNode(new UnknownNode(NULL, 0, fontfile));
        ReadLangSysTable(OffsetTo<LangSysTable>(table, record.LangSys), node, fontfile);
    }
}


void GSUB::ReadLangSysTable(const LangSysTable & table, UINode & uinode, FontFile & fontfile)
{
    for (USHORT i = 0; i != table.FeatureCount; ++i)
    {
        USHORT feature = table.FeatureIndex[i];
        const FeatureRecord & record = m_features->FeatureRecords[feature];

        UINode node = uinode.AddChild(record.Tag);
        node.SetFontNode(new UnknownNode(NULL, 0, fontfile));
        ReadFeature(OffsetTo<Feature>(*m_features, record.Feature), node, fontfile);
    }
}


void GSUB::ReadFeature(const Feature & feature, UINode & uinode, FontFile & fontfile)
{
    const LookupList & lookups = OffsetTo<LookupList>(m_header, m_header.LookupList);

    for (USHORT i = 0; i != feature.LookupCount; ++i)
    {
        const Lookup & lookup = OffsetTo<Lookup>(lookups, lookups.Lookups[i]);
        wstring type_name;
        
        switch (lookup.LookupType)
        {
        case 1: type_name = L"Single"; break;
        case 2: type_name = L"Multiple"; break;
        case 3: type_name = L"Alternate"; break;
        case 4: type_name = L"Ligature"; break;
        case 5: type_name = L"Context"; break;
        case 6: type_name = L"Chaining Context"; break;
        case 7: type_name = L"Extension Substitution"; break;
        case 8: type_name = L"Reverse Chaining Context Single"; break;

        default: type_name = L"Unknown"; break;
        }

        UINode lookup_node = uinode.AddChild(type_name);
        lookup_node.SetFontNode(CreateGSUBLookupNode(lookup_node, lookup, lookup.LookupType, fontfile));
    }
}


wstring GSUB::GetTooltip()
{
    return L"Provides information for glyph substitution";
}


void GSUB::Render(HDC dc)
{
    const Header * header = (const Header *) m_data;

    TextOutStream   textout(dc);

    textout << L"Header" << endl
            << L"Version: " << header->Version << endl
            << L"ScriptList offset: " << header->ScriptList << endl
            << L"FeatureList offset: " << header->FeatureList << endl
            << L"LookupList offset: " << header->LookupList << endl;

    const FeatureList * feature_list = (const FeatureList *) (m_data + header->FeatureList);
    map<USHORT, USHORT> feature_map;

    for (USHORT i = 0; i < feature_list->FeatureCount; ++i)
    {        
        const FeatureRecord & record = feature_list->FeatureRecords[i];
        const Feature * feature = (const Feature *) ((const byte *) feature_list + record.Feature);
        
        textout << endl
                << L"Feature #" << i << L" (" << record.Tag << L")" << endl
                << L"Params: " << feature->FeatureParams << endl
                << L"Lookups: ";

        for (UINT l = 0; l < feature->LookupCount; ++l)
        {
            if (l > 0)
                textout << L", ";

            textout << L" " << feature->LookupListIndex[l];
        }
        textout << endl;

        feature_map[record.Feature] = i;
    }
}


FontNode * CreateGSUBNode(UINode &uinode, const byte * data, size_t length, FontFile & fontfile)
{
    return new GSUB(uinode, data, length, fontfile);
}


RegisteredFontNode GSUB('GSUB', &CreateGSUBNode);