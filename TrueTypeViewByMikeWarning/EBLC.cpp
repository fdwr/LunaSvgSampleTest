#include "ttview.h"
#include "FontNode.h"
#include "TextOutStream.h"
#include "UINode.h"
#include <vector>

using namespace std;


struct sbitLineMetrics
{
    CHAR    ascender;
    CHAR    descender;
    BYTE    widthMax;
    CHAR    caretSlopeNumerator;
    CHAR    caretSlipDenominator;
    CHAR    caretOffset;
    CHAR    minOriginSB;
    CHAR    minAdvanceSB;
    CHAR    maxBeforeBL;
    CHAR    minAfterBL;
    CHAR    pad1;
    CHAR    pad2;
};
C_ASSERT(sizeof(sbitLineMetrics) == 12);


struct bitmapSizeTable
{
    BigEndian<ULONG>    indexSubTableArrayOffset;
    BigEndian<ULONG>    indexTablesSize;
    BigEndian<ULONG>    numberOfIndexSubTables;
    BigEndian<ULONG>    colorRef;
    sbitLineMetrics     hori;
    sbitLineMetrics     vert;
    BigEndian<USHORT>   startGlyphIndex;
    BigEndian<USHORT>   endGlyphIndex;
    BYTE                ppemX;
    BYTE                ppemY;
    BYTE                bitDepth;
    CHAR                flags;
};
C_ASSERT(sizeof(bitmapSizeTable) == 48);


struct eblcHeader
{
    BigEndian<Fixed> version;
    BigEndian<ULONG> numSizes;
    bitmapSizeTable  tables[];
};
C_ASSERT(sizeof(eblcHeader) == 8);



class EBLC : public FontNode
{
public:

    static FontNode * Create(UINode &uinode, const byte * data, size_t length, FontFile & fontfile);

    EBLC(UINode &uinode, const byte * data, size_t length, FontFile & fontfile);

    wstring GetTooltip();
    void Render(HDC dc);
};

RegisteredFontNode EBLC_node('EBLC', &EBLC::Create);


FontNode * EBLC::Create(UINode &uinode, const byte * data, size_t length, FontFile & fontfile)
{
    return new EBLC(uinode, data, length, fontfile);
}


EBLC::EBLC(UINode & /* UNREF uinode */, const byte * data, size_t length, FontFile & /* UNREF fontfile */)
      : FontNode(data, length)
{
}


wstring EBLC::GetTooltip()
{
    return L"Meta information about embedded bitmap data";
}


void EBLC::Render(HDC dc)
{
    const eblcHeader * header = (const eblcHeader *) m_data;

    TextOutStream textout(dc);

    for (ULONG i = 0; i < header->numSizes; ++i)
    {
        textout << header->tables[i].ppemX << ", " 
                << header->tables[i].ppemY << ", " 
                << header->tables[i].bitDepth << ", "
                << header->tables[i].startGlyphIndex << ", "
                << header->tables[i].endGlyphIndex << ", "
                << endl;
    }
}