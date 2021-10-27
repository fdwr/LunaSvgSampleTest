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
#pragma once


/// <summary>
/// Unicode 32-bit encoding form or UTF32. This encoding scheme represents
/// a Unicode character with a single 21-bit value (a subset of 32-bit UCS4),
/// also known as a Unicode scalar.
///
/// There has already been work to add Unicode support to ISO C++, but official
/// adoption of the char32_t type is pending (2007-03-09).
/// </summary>
typedef uint32_t char32_t;

enum UnicodeCodePoint
{
    UnicodeSoftHyphen               = 0x0000AD,
    UnicodeReplacementCharacter     = 0x00FFFD,   // for invalid sequences
    UnicodeMax                      = 0x10FFFF,
};

uint32_t const UnicodeSize = UnicodeMax + 1;


inline bool IsSurrogate(char32_t ch) throw()
{
    return ch >= 0xD800 && ch < 0xE000;
}


inline bool IsHighSurrogate(char32_t ch) throw()
{
    return ch >= 0xD800 && ch < 0xDC00;
}


inline bool IsLowSurrogate(char32_t ch) throw()
{
    return ch >= 0xDC00 && ch < 0xE000;
}


inline char32_t MakeUnicodeScalar(char32_t high, char32_t low) throw()
{
    return ((high & 0x03FF) << 10 | (low & 0x03FF)) + 0x10000;
}


/// <summary>
/// Converts a string of UTF16 characters to UTF32.
/// </summary>
/// <returns>
/// Number of code-units written.
/// The units read is put in sourceCount.
/// </returns>
__out_range(0, destMax)
size_t ConvertUtf16ToUtf32(
    __in_ecount(sourceMax)      const wchar_t*  sourceChars,
    __in                        size_t          sourceMax,
    __in_ecount(destMax)        char32_t*       destChars,
    __out                       size_t          destMax,
    __out_opt                   size_t*         sourceCount = NULL
    ) throw();


/// <summary>
/// Reads a single character from what may be one code point or
/// surrogate pair.
/// </summary>
/// <returns>
/// Number of code-units read.
/// </returns>
__out_range(0,2)
size_t ConvertUtf16ToUtf32(
    __in_ecount(sourceMax)      wchar_t const*  sourceChars,
    __in                        size_t          sourceMax,
    __out                       char32_t*       destChar
    ) throw();


/// <summary>
/// Writes a single character to what may be one code point or
/// surrogate pair.
///
/// These are special cases where creating a whole TextIterator
/// for a single character would be overkill.
/// </summary>
/// <returns>
/// Number of code-units written.
/// </returns>
__out_range(0, charsLength)
size_t ConvertUtf32ToUtf16(
    __in                        char32_t    ch,
    __out_ecount(charsLength)   wchar_t*    chars,
    __in                        size_t      charsLength
    ) throw();


/// <summary>
/// A variant of the above function which rewrites surrogates
/// exactly as-is. This transparency is needed when the conversion
/// is part of a longer process, where surrogate pairs should not
/// be lost (should not be silently converted to the standard
/// replacement char).
/// </summary>
/// <returns>
/// Number of code-units written.
/// </returns>
__out_range(0, charsLength)
size_t ConvertUtf32ToUtf16AllowSurrogates(
    __in                        char32_t    ch,
    __out_ecount(charsLength)   wchar_t*    chars,
    __in                        size_t      charsLength
    ) throw();
