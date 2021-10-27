//---------------------------------------------------------------------------
//  File:     TextOutStream.h
//
//  Synopsis: Provide a C++ stream-style interface to text output on HDC's
//
//  Usage:
//
//      TextOutStream s(dc);
//      s << L"Hello World!" << endl;
//      s << L"2 + 3 = " << 5 << endl;
//---------------------------------------------------------------------------

#pragma once
#include <ostream>
#include <ios>
#include <string>
#include <limits>

template <typename CharT, typename TraitsT = std::char_traits<CharT> >
class TextOutStreamBuf : public std::basic_streambuf<CharT, TraitsT>
{
    typedef typename std::basic_streambuf<CharT, TraitsT>::int_type int_type;

public:

    TextOutStreamBuf(HDC dc, int y, int x)
          : m_dc(dc),
            m_y(y),
            m_x(x)
    {
    }

   ~TextOutStreamBuf()
    {
        sync();
    }    

    virtual int_type overflow(int_type c)
    {
        if (!TraitsT::eq_int_type(c, TraitsT::eof()))
        {
            m_buffer += c;
        }

        return TraitsT::not_eof(c);
    }


   virtual std::streamsize xsputn(const CharT * s, std::streamsize length)
    {
        typedef std::basic_string<CharT>::size_type       size_type;
        typedef std::make_unsigned<std::streamsize>::type ustreamsize;
        assert(length >= 0);
        assert((ustreamsize) length <= std::numeric_limits<size_type>::max());

        m_buffer.append(s, (size_type) length);
        return length;
    }

    virtual int sync()
    {
        if (!m_buffer.empty())
        {
            TextOut(m_dc, m_x, m_y, m_buffer.c_str(), (int) m_buffer.length());

            SIZE extents;
            GetTextExtentPoint32(m_dc, m_buffer.c_str(), (int) m_buffer.length(), &extents);
            m_y += extents.cy;

            m_buffer.clear();
        }

        return 0;
    }

    POINT GetPosition() const
    {
        POINT pos;
        pos.x = m_x;
        pos.y = m_y;
        return pos;
    }

private:

    HDC m_dc;
    int m_y;
    int m_x;
    std::basic_string<CharT> m_buffer;
};



class TextOutStream : public std::basic_ostream<wchar_t>
{
public:

    TextOutStream(HDC dc, int y = 0, int x = 0)
        : std::basic_ostream<wchar_t>(NULL),
          m_buf(dc, y, x)
    {
        init(&m_buf);
    }

    POINT GetPosition() const;

private:

    TextOutStreamBuf<wchar_t> m_buf;
};


inline POINT TextOutStream::GetPosition() const
{
    return m_buf.GetPosition();
}