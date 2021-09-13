#include <streambuf>



namespace TextFormat
{
    class Header {};

    extern Header header;
}

    
class TextFormatterBuffer : public std::wstreambuf
{
public:

    enum Format
    {
        Normal,
        Header
    };

    void SetFormat(Format format);

    IDWriteTextLayoutPtr GetLayout() const;

    std::streamsize xsputn(const wchar_t * data, std::streamsize count);
    int_type overflow(int_type);

private:

    struct Formats
    {
        Format  format;
        size_t  startPosition;

        Formats(Format format, size_t startPosition);
    };

    std::wstring            m_buffer;
    std::vector<Formats>    m_formats;
};


class TextFormatter : public std::wostream
{
public:

    TextFormatter();

    void SetFormat(TextFormatterBuffer::Format format) {m_buffer.SetFormat(format);}

    IDWriteTextLayoutPtr GetLayout() const {return m_buffer.GetLayout();}

private:

    TextFormatterBuffer m_buffer;
};


TextFormatter & operator<< (TextFormatter & formatter, TextFormat::Header);