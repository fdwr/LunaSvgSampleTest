#include "ttview.h"
#include "FontNode.h"
#include "TextOutStream.h"
#include "UINode.h"
#include "CommonTables.h"

using namespace std;


struct Substitution
{
    BigEndian<USHORT>   Format;
};
C_ASSERT(sizeof(Substitution) == 2);


struct SingleLookup : public Substitution
{
    BigEndian<Offset>   Coverage;
};
C_ASSERT(sizeof(SingleLookup) == 4);


struct SingleLookupFormat1 : public SingleLookup
{
    BigEndian<SHORT>    DeltaGlyphID;
};
C_ASSERT(sizeof(SingleLookupFormat1) == 6);


struct SingleLookupFormat2 : public SingleLookup
{
    BigEndian<USHORT>   GlyphCount;
    BigEndian<USHORT>   Substitute[];
};
C_ASSERT(sizeof(SingleLookupFormat2) == 6);


struct LigatureSubstitution : public Substitution
{
    BigEndian<Offset>   Coverage;
    BigEndian<USHORT>   LigSetCount;
    BigEndian<Offset>   LigatureSet[];
};
C_ASSERT(sizeof(LigatureSubstitution) == 6);


struct LigatureSet
{
    BigEndian<USHORT>   LigatureCount;
    BigEndian<Offset>   Ligature[];
};
C_ASSERT(sizeof(LigatureSet) == 2);


struct Ligature
{
    BigEndian<USHORT>   GlyphID;
    BigEndian<USHORT>   CompCount;
    BigEndian<USHORT>   Components[];   // CompCount-1, in reading direction
};
C_ASSERT(sizeof(Ligature) == 4);


struct ChainingContextSubstitution : public Substitution
{
};


struct ExtensionSubstitution : public Substitution
{
    BigEndian<USHORT>   LookupType;
    BigEndian<ULONG>    ExtensionOffset;
};
C_ASSERT(sizeof(ExtensionSubstitution) == 8);


class Coverage
{
public:

    Coverage(const CoverageFormat & coverage);

    class iterator;
    
    iterator begin();
    iterator end();

private:

    const CoverageFormat & m_coverage;
};


class Coverage::iterator
{
    friend class Coverage;

public:

    iterator(const CoverageFormat & coverage);

    bool operator != (const iterator & o);

    USHORT     operator * ();
    iterator & operator++ ();

private:

    enum end_t {End};
    iterator(end_t);

    class Format;
    class Format1;
    class Format2;

    Format *    m_format;
};


class Coverage::iterator::Format
{
public:

    virtual USHORT operator *  () = 0;
    virtual bool   operator ++ () = 0;
};


class Coverage::iterator::Format1 : public Coverage::iterator::Format
{
public:

    Format1(const CoverageFormat & coverage);

    USHORT operator *  ();
    bool   operator ++ ();

private:

    const CoverageFormat1 & m_coverage;
    USHORT                  m_glyph;
};


class Coverage::iterator::Format2 : public Coverage::iterator::Format
{
public:

    Format2(const CoverageFormat & coverage);

    USHORT operator *  ();
    bool   operator ++ ();

private:

    const CoverageFormat2 & m_coverage;
    USHORT                  m_range;
    USHORT                  m_glyphId;
};


Coverage::Coverage(const CoverageFormat & coverage)
      : m_coverage(coverage)
{
}


Coverage::iterator Coverage::begin()
{
    return iterator(m_coverage);
}


Coverage::iterator Coverage::end()
{
    return iterator(iterator::End);
}


Coverage::iterator::iterator(const CoverageFormat & coverage)
      : m_format(NULL)
{
    if (coverage.Format == 1)
        m_format = new Format1(coverage);
    else if (coverage.Format == 2)
        m_format = new Format2(coverage);
}


Coverage::iterator::iterator(end_t)
      : m_format(NULL)
{
}


bool Coverage::iterator::operator != (const Coverage::iterator & o)
{
    return m_format != o.m_format;  // BUGBUG: only good enough for != end()
}


USHORT Coverage::iterator::operator * ()
{
    return *(*m_format);
}


Coverage::iterator & Coverage::iterator::operator ++ ()
{
    if (++(*m_format))
    {
        delete m_format;
        m_format = NULL;
    }

    return *this;
}


Coverage::iterator::Format1::Format1(const CoverageFormat & coverage)
      : m_coverage(static_cast<const CoverageFormat1 &>(coverage)),
        m_glyph(0)      // BUGBUG: empty glyph set
{
}


USHORT Coverage::iterator::Format1::operator * ()
{
    assert(m_glyph < m_coverage.GlyphCount);

    return m_coverage.GlyphID[m_glyph];
}


bool Coverage::iterator::Format1::operator ++ ()
{
    if (m_glyph == m_coverage.GlyphCount)
        throw runtime_error("Coverage iterator went past the end");

    ++m_glyph;

    return (m_glyph == m_coverage.GlyphCount);
}


Coverage::iterator::Format2::Format2(const CoverageFormat & coverage)
      : m_coverage(static_cast<const CoverageFormat2 &>(coverage)),
        m_range(0),
        m_glyphId(m_coverage.Ranges[0].Start)   // BUGBUG: empty range list
{
}


USHORT Coverage::iterator::Format2::operator * ()
{
    return m_glyphId;
}


bool Coverage::iterator::Format2::operator ++ ()
{
    if (m_range == m_coverage.RangeCount)
        throw runtime_error("Coverage iterator went past the end");

    if (m_glyphId != m_coverage.Ranges[m_range].End)
    {
        ++m_glyphId;
    }
    else
    {
        ++m_range;
        if (m_range != m_coverage.RangeCount)
            m_glyphId = m_coverage.Ranges[m_range].Start;
    }

    return (m_range == m_coverage.RangeCount);
}





class GSUBLookup : public FontNode
{
public:

    GSUBLookup(UINode & uinode, const Lookup & lookup, USHORT lookupType, const FontFile & fontfile);

    virtual std::wstring GetTooltip();
    virtual void         Render(HDC dc);

private:

    virtual void RenderSubstitution(HDC dc, USHORT lookupType, const Substitution & sub);

    const Lookup &      m_lookup;
    USHORT              m_lookupType;
    const FontFile &    m_fontfile;
};


GSUBLookup::GSUBLookup(UINode & uinode, const Lookup & lookup, USHORT lookupType, const FontFile & fontfile)
      : FontNode(NULL, 0),
        m_lookup(lookup),
        m_lookupType(lookupType),
        m_fontfile(fontfile)
{
    if (lookupType == 7)
    {
        for (USHORT i = 0; i != lookup.SubTableCount; ++i)
        {
            const ExtensionSubstitution & extension = OffsetTo<ExtensionSubstitution>(m_lookup, m_lookup.SubTables[i]);
            wstring type_name;

            switch (extension.LookupType)
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

            UINode node = uinode.AddChild(type_name);
            node.SetFontNode(new GSUBLookup(node, OffsetTo<Lookup>(extension, extension.ExtensionOffset), extension.LookupType, fontfile));
        }
    }
}


wstring GSUBLookup::GetTooltip()
{
    switch (m_lookup.LookupType)
    {
    case 1: return L"Replace one glyph with one glyph";
    case 2: return L"Replace one glyph with more than one glyph";
    case 3: return L"Replace one glyph with one of many glyphs";
    case 4: return L"Replace multiple glyphs with one glyph";
    case 5: return L"Replace one or more glyphs in context";
    case 6: return L"Replace one or more glyphs in chained context";
    case 7: return L"Extension mechanism for other substitutions";
    case 8: return L"Applied in reverse order, replace single glyph in chaining context";

    default: return L"";
    }
}


void GSUBLookup::Render(HDC dc)
{
    for (USHORT i = 0; i != m_lookup.SubTableCount; ++i)
    {
        if (m_lookup.LookupType == 7)
        {
            const ExtensionSubstitution & extension = OffsetTo<ExtensionSubstitution>(m_lookup, m_lookup.SubTables[i]);
            RenderSubstitution(dc, extension.LookupType, OffsetTo<Substitution>(extension, extension.ExtensionOffset));          
        }
        else
        {
            RenderSubstitution(dc, m_lookup.LookupType, OffsetTo<Substitution>(m_lookup, m_lookup.SubTables[i]));
        }
    }
}


void GSUBLookup::RenderSubstitution(HDC dc, USHORT lookupType, const Substitution & sub)
{
    HFONT oldfont = SelectFont(dc, m_fontfile.GlyphFont());

    int y = 0;

    if (lookupType == 1)  // Single substitution
    {
        const SingleLookup & single = static_cast<const SingleLookup &>(sub);
        Coverage coverage = OffsetTo<CoverageFormat>(single, single.Coverage);

        if (single.Format == 1)
        {
            const SingleLookupFormat1 & format = static_cast<const SingleLookupFormat1 &>(single);

            for (Coverage::iterator i = coverage.begin(); i != coverage.end(); ++i, ++y)
            {
                WCHAR from = *i;
                WCHAR to = *i + format.DeltaGlyphID;

                ExtTextOut(dc, 0, y*30, ETO_GLYPH_INDEX, NULL, &from, 1, NULL);
                ExtTextOut(dc, 50, y*30, ETO_GLYPH_INDEX, NULL, &to, 1, NULL);
            }
        }
        else if (single.Format == 2)
        {
            const SingleLookupFormat2 & format = static_cast<const SingleLookupFormat2 &>(single);

            USHORT index = 0;
            for (Coverage::iterator i = coverage.begin(); i != coverage.end(); ++i, ++index, ++y)
            {
                WCHAR from = *i;
                WCHAR to = format.Substitute[index];

                ExtTextOut(dc, 0, y*30, ETO_GLYPH_INDEX, NULL, &from, 1, NULL);
                ExtTextOut(dc, 50, y*30, ETO_GLYPH_INDEX, NULL, &to, 1, NULL);
            }
        }
    }



    else if (lookupType == 4)  // Ligature substitution
    {
        const LigatureSubstitution & table = static_cast<const LigatureSubstitution &>(sub);
        Coverage coverage = OffsetTo<CoverageFormat>(table, table.Coverage);

        if (table.Format == 1)
        {
            for (USHORT setnum = 0; setnum != table.LigSetCount; ++setnum)
            {
                const LigatureSet & ligset = OffsetTo<LigatureSet>(table, table.LigatureSet[setnum]);

                for (USHORT lignum = 0; lignum != ligset.LigatureCount; ++lignum)
                {
                    const Ligature & ligature = OffsetTo<Ligature>(ligset, ligset.Ligature[lignum]);
                    assert(ligature.CompCount > 0);     // BUGBUG: shouldn't be an assert

                    for (Coverage::iterator i = coverage.begin(); i != coverage.end(); ++i, ++y)
                    {
                        int x = 0;

                        WCHAR base = *i;
                        ExtTextOut(dc, 0, y*30, ETO_GLYPH_INDEX, NULL, &base, 1, NULL);
                        ++x;

                        for (USHORT k = 0; k != ligature.CompCount - 1; ++k, ++x)
                        {
                            WCHAR component = ligature.Components[k];
                            ExtTextOut(dc, x * 50, y*30, ETO_GLYPH_INDEX, NULL, &component, 1, NULL);
                        }

                        WCHAR target = ligature.GlyphID;
                        ExtTextOut(dc, x * 50, y*30, ETO_GLYPH_INDEX, NULL, &target, 1, NULL);
                    }
                }
            }
        }
    }



    else if (lookupType == 6)  // Chaining context substitution
    {
        ChainingContextSubstitution ccs = static_cast<const ChainingContextSubstitution &>(sub);
    }



    SelectFont(dc, oldfont);

    return;
}




FontNode * CreateGSUBLookupNode(UINode & uinode, const Lookup & lookup, USHORT lookupType, const FontFile & fontfile)
{
    return new GSUBLookup(uinode, lookup, lookupType, fontfile);
}
