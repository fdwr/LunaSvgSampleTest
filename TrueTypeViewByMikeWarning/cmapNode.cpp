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


void DrawGlyph(const FontFile & fontfile, HDC dc, int x, int y, USHORT glyph, char32_t c)
{
    HFONT    oldfont = SelectFont(dc, fontfile.GlyphFont());
    COLORREF oldbkcolor = SetBkColor(dc, GetSysColor(COLOR_WINDOW));
    UINT     oldalign = SetTextAlign(dc, TA_CENTER | TA_BOTTOM);
    HPEN     oldpen = SelectPen(dc, CreatePen(PS_SOLID, 0, GetSysColor(COLOR_HIGHLIGHT)));

    SIZE cellsize = fontfile.GetGlyphCellSize();

    RECT cell;
    cell.left = x;
    cell.right = x + cellsize.cx;
    cell.top = y;
    cell.bottom = y + cellsize.cy;

    x = (cell.right + cell.left) / 2;
    y = cell.bottom;
    ExtTextOut(dc, x, y, ETO_GLYPH_INDEX | ETO_OPAQUE, &cell, (LPCWSTR) &glyph, 1, NULL);

    {
        wstringstream atoi;
        atoi << glyph;

        SelectFont(dc, fontfile.LabelFont());
        SetTextAlign(dc, TA_RIGHT | TA_TOP);
        x = cell.right - 1;
        y = cell.top;
        ExtTextOut(dc, x, y, 0, NULL, atoi.str().c_str(), UINT(atoi.str().length()), NULL);
    }

    if (c != 0xFFFFFFFF)
    {
        wstringstream atoi;
        atoi << hex << L"U+" << c;

        SetTextAlign(dc, TA_LEFT | TA_TOP);
        x = cell.left + 1;
        y = cell.top;
        ExtTextOut(dc, x, y, 0, NULL, atoi.str().c_str(), UINT(atoi.str().length()), NULL);
    }

    MoveToEx(dc, cell.left, cell.top, NULL);
    LineTo(dc, cell.right, cell.top);
    LineTo(dc, cell.right, cell.bottom);
    LineTo(dc, cell.left, cell.bottom);
    LineTo(dc, cell.left, cell.top);
GdiFlush();

    DeletePen(SelectPen(dc, oldpen));
    SetBkColor(dc, oldbkcolor);
    SetTextAlign(dc, oldalign);
    SelectFont(dc, oldfont);
}
