#pragma once

#include <string>
#include <memory>
#include "BigEndian.h"


class FontFile
{
public:

    FontFile(const byte * base, size_t length);

    const byte * FileBase() const;
    const std::wstring & GetFaceName() const;

    bool IsInFile(const void * address, size_t length) const;

    void  SetFaceName(const std::wstring & facename);
    HFONT GlyphFont() const;
    SIZE  GetGlyphCellSize() const;
    HFONT LabelFont() const;

    // Make this cleaner
    void  SetTextFont(HFONT);
    HFONT TextFont() const;

    void   SetGlyphCount(USHORT glyphs);
    USHORT GlyphCount() const;

    void   SetHorizontalMetricCount(USHORT hmetrics);
    USHORT GetHorizontalMetricCount() const;

private:

    const byte *    m_base;
    const byte *    m_end;
    std::wstring    m_facename;
    HFONT           m_glyph_font;
    SIZE            m_glyph_cell_size;
    HFONT           m_label_font;
    HFONT           m_text_font;
    USHORT          m_glyph_count;
    USHORT          m_horizontal_metric_count;
};


inline FontFile::FontFile(const byte * base, size_t length)
      : m_base(base),
        m_end(base + length),
        m_glyph_font(NULL),
        m_label_font(NULL)
{
    assert(m_end >= m_base);
}


inline const byte * FontFile::FileBase() const
{
    return m_base;
}


inline const std::wstring & FontFile::GetFaceName() const
{
    return m_facename;
}


inline bool FontFile::IsInFile(const void * address, size_t length) const
{
    const byte * byte_address = (const byte *) address;
    
    return     (m_base <= byte_address) && (byte_address < m_end) 
            && (length < size_t(m_end - byte_address));
}


inline HFONT FontFile::GlyphFont() const
{
    return m_glyph_font;
}


inline SIZE FontFile::GetGlyphCellSize() const
{
    return m_glyph_cell_size;
}


inline HFONT FontFile::LabelFont() const
{
    return m_label_font;
}


inline void FontFile::SetTextFont(HFONT font)
{
    m_text_font = font;
}


inline HFONT FontFile::TextFont() const
{
    return m_text_font;
}


inline void FontFile::SetGlyphCount(USHORT glyphs)
{
    m_glyph_count = glyphs;
}


inline USHORT FontFile::GlyphCount() const
{
    return m_glyph_count;
}


inline void FontFile::SetHorizontalMetricCount(USHORT glyphs)
{
    m_horizontal_metric_count = glyphs;
}


inline USHORT FontFile::GetHorizontalMetricCount() const
{
    return m_horizontal_metric_count;
}



class UINode;


struct Fixed
{
    BigEndian<uint16_t> integer;
    BigEndian<uint16_t> fraction;

    operator double () const {return integer + ((double) fraction) / 0xFFFF;}
    operator std::wstring () const;
};
C_ASSERT(sizeof(Fixed) == 4);


typedef USHORT Offset;

typedef int64_t  LONGDATETIME;

struct Tag
{
    char    data[4];

    operator std::wstring () const;

    operator int () const {return (int) _byteswap_ulong(* (ULONG *) data);}
};
C_ASSERT(sizeof(Tag) == 4);


template <typename T>
std::basic_ostream<T> & operator << (std::basic_ostream<T> & stream, const Tag & tag)
{
    stream << tag.data[0] << tag.data[1] << tag.data[2] << tag.data[3];
    return stream;
}


template <typename To, typename From>
const To & OffsetTo(const From & from, ULONG offset)
{
    return * (const To *) (((const byte *) &from) + offset);
};


class Renderer
{
public:

    Renderer() : m_scroll_pos(0) {}

    virtual void   Render(HDC dc) = 0;
    virtual size_t GetTotalHeight(HDC dc) = 0;
    virtual void   SetScrollPos(size_t pos) {m_scroll_pos = pos;}

protected:

    size_t  m_scroll_pos;
};




class FontNode : Renderer
{
public:

    FontNode(const byte * data, size_t length);
    virtual ~FontNode();

    virtual std::wstring GetTooltip() = 0;

    virtual void         SetupUI(HWND window);
    virtual void         TeardownUI(HWND window);

    virtual void         Render(HDC dc);
    virtual size_t       GetTotalHeight(HDC dc);
    virtual void         SetScrollPos(unsigned pos);

    virtual void         OnNotify(int control, const NMHDR * notification);

protected:

    const byte *            m_data;
    size_t                  m_length;
    std::wstring            m_invalid;
    std::auto_ptr<Renderer> m_renderer;
};


class RegisteredFontNode
{
public:

    typedef FontNode * (*Creater)(UINode &uinode, const byte * data, size_t length, FontFile & fontfile);

    RegisteredFontNode(int tag, Creater creater);

    static Creater GetCreater(Tag tag);

private:

    int                  tag;
    Creater              creater;
    RegisteredFontNode * next;

    static RegisteredFontNode * m_tag_list;
};


inline
RegisteredFontNode::RegisteredFontNode(int tag, RegisteredFontNode::Creater creater)
      : tag(tag),
        creater(creater),
        next(m_tag_list)
{
    m_tag_list = this;
}

        

class UnknownNode : public FontNode
{
public:

    UnknownNode(const byte * data, size_t length, FontFile & fontfile);

    virtual std::wstring GetTooltip();

private:

    size_t m_offset;
};


class sfntNode : public FontNode
{
public:

    sfntNode(UINode & uinode, const byte * data, unsigned length, FontFile & fontfile);

    virtual std::wstring GetTooltip();
    virtual void         Render(HDC dc);
};


FontNode * CreateGSUBNode(UINode & uinode, const byte * data, unsigned length, FontFile & fontfile);


class hexstring
{
public:

    template <typename T>
    hexstring(const T & x) {std::wstringstream s; s << std::hex << L"0x" << x; m_str = s.str();}

    operator const std::wstring & () const {return m_str;}

private:

    std::wstring m_str;
};

template <typename A>
std::basic_ostream<A> & operator << (std::basic_ostream<A> & s, const hexstring & str)
{
    return s << (const std::wstring &) str;
}

class anystring
{
public:

    template <typename T>
    anystring(const T & x) {std::wstringstream s; s << x; m_str = s.str();}

    anystring(const Fixed & x) {m_str = x;}

    const WCHAR * c_str() const {return m_str.c_str();}

private:

    std::wstring m_str;
};
