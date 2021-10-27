#include "ttview.h"
#include "FontNode.h"
#include "UINode.h"

using namespace std;


struct Header
{
    Tag                 Tag;
    BigEndian<ULONG>    Version;
    BigEndian<ULONG>    FontCount;
    BigEndian<ULONG>    FontOffsets[];
};



class TTC : public FontNode
{
public:

    TTC(UINode & uinode, const byte * data, unsigned length, FontFile & fontfile);

    virtual std::wstring GetTooltip();
//    virtual void         Render(HWND window, HDC dc, const RECT & client_rect);
};


TTC::TTC(UINode & uinode, const byte * data, unsigned length, FontFile & fontfile)
      : FontNode(data, length)
{
    const Header & header = (const Header &) *data;

    for (ULONG i = 0; i < header.FontCount; ++i)
    {
        ULONG start = header.FontOffsets[i];
        ULONG end = 0xffffffff;   // BUGBUG

        UINode node = uinode.AddChild(L"F");    // BUGBUG
        FontNode * sfnt = new sfntNode(node, data + start, end - start, fontfile);
        node.SetFontNode(sfnt);
        node.SetName(fontfile.GetFaceName());
    }
}


wstring TTC::GetTooltip()
{
    return L"";
}


bool IsTTC(const byte * font)
{
    const Header & header = (const Header &) *font;

    return ((wstring) header.Tag == wstring(L"ttcf")) &&
           (header.Version == 0x00010000 || header.Version == 0x00020000);
}


FontNode * CreateTTCNode(UINode &uinode, const byte * data, unsigned length, FontFile & fontfile)
{
    return new TTC(uinode, data, length, fontfile);
}