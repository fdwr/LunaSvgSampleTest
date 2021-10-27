//////////////////////////////////////////////////////////////////////////////
//
//  Contents:   Definitions and helper functions related to Unicode character
//              processing.
//
//  Author:     Dwayne Robinson
//
//  History:    2007-11-01 Created
//
//////////////////////////////////////////////////////////////////////////////
#include "precomp.h"


__out_range(0, destMax)
size_t ConvertUtf16ToUtf32(
    __in_ecount(sourceMax)      const wchar_t*  sourceChars,
    __in                        size_t          sourceMax,
    __in_ecount(destMax)        char32_t*       destChars,
    __out                       size_t          destMax,
    __out_opt                   size_t*         sourceCount
    ) throw()
{
    // Can have more UTF16 characters than UTF32,
    // but never the other way around.

    size_t si = 0, di = 0;
    for ( ; di < destMax; ++di)
    {
        if (si >= sourceMax)
            break;

        char32_t leading = sourceChars[si++];

        // if not a surrogate code point, just return char
        if (!IsSurrogate(leading))
        {
            destChars[di] = leading;
        }
        else if (si >= sourceMax)
        {
            // Illegal unpaired surrogate.
            // Appropriate substitute is replacement char.
            destChars[di] = UnicodeReplacementCharacter;
        }
        else
        {
            char32_t trailing = sourceChars[si++];

            if (IsHighSurrogate(leading) && IsLowSurrogate(trailing))
            {
                destChars[di] = MakeUnicodeScalar(leading, trailing);
            }
            else
            {
                // Invalid pair, so replacement char is appropriate substitute
                destChars[di] = UnicodeReplacementCharacter;
            }
        }
    }

    if (sourceCount != NULL)
        *sourceCount = si;

    return di;
}


__out_range(0,2)
size_t ConvertUtf16ToUtf32(
    __in_ecount(sourceMax)      wchar_t const*  sourceChars,
    __in                        size_t          sourceMax,
    __out                       char32_t*       destChar
    ) throw()
{
    if (sourceMax <= 0)
        return 0;

    char32_t leading = sourceChars[0];

    // If not a surrogate code point, just return char
    if (!IsSurrogate(leading))
    {
        *destChar = leading;
        return 1;
    }

    // If only a single surrogate, substitute with replacement character.
    if (sourceMax == 1)
    {
        *destChar = UnicodeReplacementCharacter;
        return 1;
    }

    char32_t trailing = sourceChars[1];

    // If invalid pair, substitute with replacement character.
    if (!IsHighSurrogate(leading) || !IsLowSurrogate(trailing))
    {
        *destChar = UnicodeReplacementCharacter;
        return 1;
    }

    // Else both leading and trailing present
    *destChar = MakeUnicodeScalar(leading, trailing);
    return 2;
}


__out_range(0, charsLength)
size_t ConvertUtf32ToUtf16(
    __in                        char32_t    ch,
    __out_ecount(charsLength)   wchar_t*    chars,
    __in                        size_t      charsLength
    ) throw()
{
    if ((signed)charsLength <= 0)
        return 0;

    if (ch > 0xFFFF && charsLength >= 2)
    {
        // Split into leading and trailing surrogatse.
        // From http://unicode.org/faq/utf_bom.html#35
        wchar_t leading  = wchar_t(0xD800 + (ch >> 10)  - (0x10000 >> 10));
        wchar_t trailing = wchar_t(0xDC00 + (ch & 0x3FF));
        chars[0] = leading;
        chars[1] = trailing;
        return 2;
    }
    else if (IsSurrogate(ch))
    {
        // Isolated surrogates somehow appeared in a UCS4 stream;
        // best replacement is the standard replacement character.
        chars[0] = UnicodeReplacementCharacter;
        return 1;
    }
    else
    {
        // Just a BMP character
        chars[0] = wchar_t(ch);
        return 1;
    }
}


__out_range(0, destMax)
size_t ConvertUtf32ToUtf16AllowSurrogates(
    __in                        char32_t    sourceChar,
    __out_ecount(destMax)       wchar_t*    destChars,
    __in                        size_t      destMax
    ) throw()
{
    if ((signed)destMax <= 0)
        return 0;

    if (sourceChar > 0xFFFF && destMax >= 2)
    {
        // Split into leading and trailing surrogatse.
        // From http://unicode.org/faq/utf_bom.html#35
        wchar_t leading  = wchar_t(0xD800 + (sourceChar >> 10)  - (0x10000 >> 10));
        wchar_t trailing = wchar_t(0xDC00 + (sourceChar & 0x3FF));
        destChars[0] = leading;
        destChars[1] = trailing;
        return 2;
    }
    else
    {
        // Just a BMP character (allowing potential single surrogates)
        destChars[0] = wchar_t(sourceChar);
        return 1;
    }
}
