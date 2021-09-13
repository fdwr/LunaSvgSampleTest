#include "LayoutSpy.h"
#include "TextFormatter.h"
#include <algorithm>

typedef TextFormatterBuffer::int_type int_type;
using std::streamsize;
using std::vector;
using std::find;


TextFormat::Header TextFormat::header;


TextFormatter & operator<< (TextFormatter & formatter, TextFormat::Header)
{
    formatter.SetFormat(TextFormatterBuffer::Header);
    return formatter;
}


TextFormatter::TextFormatter()
      : std::wostream(&m_buffer)
{
}


TextFormatterBuffer::Formats::Formats(TextFormatterBuffer::Format format, size_t startPosition)
      : format(format),
        startPosition(startPosition)
{
}


void TextFormatterBuffer::SetFormat(TextFormatterBuffer::Format format)
{
    // Insert a blank line in front of headers
    if (format == Header && !m_buffer.empty())
        overflow('\n');

    m_formats.push_back(Formats(format, m_buffer.size()));
}


IDWriteTextLayoutPtr TextFormatterBuffer::GetLayout() const
{
    IDWriteTextFormatPtr format;
    TIF( g_dwrite->CreateTextFormat(
                        L"Segoe UI",
                        NULL,
                        DWRITE_FONT_WEIGHT_REGULAR,
                        DWRITE_FONT_STYLE_NORMAL,
                        DWRITE_FONT_STRETCH_NORMAL,
                        10, // BUGBUG: convert to points, need dpi
                        L"",
                        &format) );
    
    IDWriteTextLayoutPtr layout;
    TIF( g_dwrite->CreateTextLayout(
                        m_buffer.c_str(),
                        (UINT32) m_buffer.length(),
                        format,
                        10000.0f,
                        10000.0f,
                        &layout) );

    for (vector<Formats>::const_iterator i = m_formats.begin(); i != m_formats.end(); ++i)
    {
        if (i->startPosition == m_buffer.length())
            continue;

        assert(i->startPosition < m_buffer.length());

        DWRITE_TEXT_RANGE range;
        range.startPosition = (UINT32) i->startPosition;
        range.length = (UINT32) m_buffer.length() - range.startPosition;

        switch (i->format)
        {
        case Header:
            layout->SetFontWeight(DWRITE_FONT_WEIGHT_BOLD, range);
            layout->SetFontSize(12, range);
            break;

        default:
            layout->SetFontWeight(DWRITE_FONT_WEIGHT_NORMAL, range);
            layout->SetFontSize(10, range);
            break;
        }
    }


    return layout;
}


int_type TextFormatterBuffer::overflow(int_type c)
{
    wchar_t wc = (wchar_t) c;
    xsputn(&wc, 1);
    return 0;
}


streamsize TextFormatterBuffer::xsputn(const wchar_t * data, streamsize count)
{
    typedef std::wstring::size_type                   size_type;
    typedef std::make_unsigned<std::streamsize>::type ustreamsize;
    assert(count >= 0);
    assert((ustreamsize) count <= std::numeric_limits<size_type>::max());

    size_t oldSize = m_buffer.size();

    m_buffer.append(data, (size_type) count);
    
    // If we're formatting a header, revert to normal after the first newline
    if (!m_formats.empty() && m_formats.back().format == Header)
    {
        const wchar_t * newline = find(data, data + count, L'\n');
        if (newline != data + count)
        {
            size_t startPosition = oldSize + (newline - data) + 1;
            m_formats.push_back(Formats(Normal, startPosition));
        }
    }

    return count;
}

