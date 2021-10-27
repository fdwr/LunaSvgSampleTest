#include <vector>
#include <string>


class GlyphViewStrings
{
public:

    virtual std::vector<std::wstring> GetStrings(USHORT glyph) const = 0;
};


Renderer * CreateGlyphViewRenderer(const GlyphViewStrings *, const FontFile &);