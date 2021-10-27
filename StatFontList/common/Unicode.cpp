// Include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
#include "precomp.h"


__out_range(0, destMax)
size_t ConvertUtf16ToUtf32(
    __in_ecount(sourceCount) const wchar_t* sourceChars,
    __in size_t sourceCount,
    __out_ecount_part(destMax,0) char32_t* destChars,
    __in size_t destMax
    ) throw()
{
    // Can have more UTF16 code units than UTF32,
    // but never the other way around.

    size_t si = 0, di = 0;
    for ( ; di < destMax; ++di)
    {
        if (si >= sourceCount)
            break;

        char32_t ch = sourceChars[si++];

        // Just use the character if not a surrogate code point.
        // For unpaired surrogates, pass the isolated surrogate
        // through (rather than remap to U+FFFD).
        if (IsLeadingSurrogate(ch) && si < sourceCount)
        {
            char32_t leading  = ch;
            char32_t trailing = sourceChars[si];
            if (IsTrailingSurrogate(trailing))
            {
                ch = MakeUnicodeCodepoint(leading, trailing);
                ++si;
            }
        }
        destChars[di] = ch;
    }

    return di;
}


__out_range(0, destMax)
size_t ConvertUtf32ToUtf16(
    __in_ecount(sourceCount) const char32_t* sourceChars,
    __in size_t sourceCount,
    __out_ecount_part(destMax,0) wchar_t* destChars,
    __in size_t destMax
    ) throw()
{
    if ((signed)destMax <= 0)
        return 0;

    size_t si = 0, di = 0;

    for ( ; si < sourceCount; ++si)
    {
        if (di >= destMax)
            break;

        char32_t ch = sourceChars[si];

        if (ch > 0xFFFF && destMax - di >= 2)
        {
            // Split into leading and trailing surrogatse.
            // From http://unicode.org/faq/utf_bom.html#35
            destChars[di + 0] = GetLeadingSurrogate(ch);
            destChars[di + 1] = GetTrailingSurrogate(ch);
            ++di;
        }
        else
        {
            // A BMP character (or isolated surrogate)
            destChars[di + 0] = wchar_t(ch);
        }
        ++di;
    }

    return di;
}


struct UnicodeCharacterReader
{
    const wchar_t* current;
    const wchar_t* end;

    bool IsAtEnd()
    {
        return current >= end;
    }

    char32_t ReadNext()
    {
        if (current >= end)
            return 0;

        char32_t ch = *current;
        ++current;

        // Just use the character if not a surrogate code point.
        // For unpaired surrogates, pass the isolated surrogate
        // through (rather than remap to U+FFFD).
        if (IsLeadingSurrogate(ch) && current < end)
        {
            char32_t leading  = ch;
            char32_t trailing = *current;
            if (IsTrailingSurrogate(trailing))
            {
                ch = MakeUnicodeCodepoint(leading, trailing);
                ++current;
            }
        }

        return ch;
    }
};


UnicodeRange SimpleCharacters[] = {
    0x0020,0x007E, // Basic Latin
    0x00A0,0x00AC, // Latin-1 supplement (excluding soft hyphen)
    0x00AE,0x02AF, // Latin-1 supplement, Latin extended-A, Latin extended-B, IPA extensions
    0x0370,0x0377, // Greek and Coptic
    0x037A,0x037E, // Greek and Coptic
    0x0384,0x038A, // Greek and Coptic
    0x038C,0x038C, // Greek and Coptic
    0x038E,0x03A1, // Greek and Coptic
    0x03A3,0x03FF, // Greek and Coptic
    0x0400,0x0482, // Cyrillic (excluding combining marks)
    0x048A,0x04FF, // Cyrillic
    0x0500,0x0527, // Cyrillic Supplement
    0x0531,0x0556, // Armenian
    0x0561,0x0587, // Armenian
    0x0589,0x0589, // Armenian
    0x10A0,0x10C5, // Georgian (excluding reserved spots)
    0x10D0,0x10FC, // Georgian
    0x13A0,0x13F4, // Cherokee
    0x1400,0x167F, // Unified Canadian Aboriginal Syllabics
    0x1680,0x169C, // Ogham
    0x16A0,0x16F0, // Runic
    0x18B0,0x18F5, // Unified Canadian Aboriginal Syllabics Extended
    0x1D00,0x1D7F, // Phonetic Extensions
    0x1D80,0x1DBF, // Phonetic Extensions Supplement
    0x1E00,0x1EFF, // Latin extended additional (including Vietnamese precomposed)
    0x1F00,0x1F15, // Greek extended
    0x1F18,0x1F1D, // Greek extended
    0x1F20,0x1F45, // Greek extended
    0x1F48,0x1F4D, // Greek extended
    0x1F50,0x1F57, // Greek extended
    0x1F59,0x1F59, // Greek extended
    0x1F5B,0x1F5B, // Greek extended
    0x1F5D,0x1F5D, // Greek extended
    0x1F5F,0x1F7D, // Greek extended
    0x1F80,0x1FB4, // Greek extended
    0x1FB6,0x1FC4, // Greek extended
    0x1FC6,0x1FD3, // Greek extended
    0x1FD6,0x1FDB, // Greek extended
    0x1FDD,0x1FEF, // Greek extended
    0x1FF2,0x1FF4, // Greek extended
    0x1FF6,0x1FFE, // Greek extended
    0x2000,0x200A, // General punctuation (various spaces)
    0x2010,0x2027, // General punctuation (including ellipsis, quotes, and hyphens)
    0x202F,0x205F, // General punctuation (misc)
    0x2070,0x2071, // Superscripts and Subscripts
    0x2074,0x208E, // Superscripts and Subscripts
    0x2090,0x209C, // Superscripts and Subscripts
    0x20A0,0x20BA, // Currency Symbols (up to Turkish Lira sign)
    0x2100,0x214F, // Letterlike Symbols
    0x2150,0x2189, // Number Forms
    0x2190,0x21FF, // Arrows
    0x2200,0x22FF, // Mathematical Operators
    0x2300,0x23F3, // Miscellaneous Technical
    0x2400,0x2426, // Control Pictures
    0x2440,0x244A, // Optical Character Recognition
    0x2460,0x24FF, // Enclosed Alphanumerics
    0x2500,0x257F, // Box Drawing
    0x2580,0x259F, // Block Elements
    0x25A0,0x25FF, // Geometric Shapes
    0x2600,0x26FF, // Miscellaneous Symbols
    0x2701,0x27BF, // Dingbats (1 reserved at 2700)
    0x27C0,0x27CA, // Miscellaneous Mathematical Symbols-A
    0x27CC,0x27CC, // Miscellaneous Mathematical Symbols-A
    0x27CE,0x27EF, // Miscellaneous Mathematical Symbols-A
    0x27F0,0x27FF, // Supplemental Arrows-A
    0x2800,0x28FF, // Braille Patterns
    0x2900,0x297F, // Supplemental Arrows-B
    0x2980,0x29FF, // Miscellaneous Mathematical Symbols-B
    0x2A00,0x2AFF, // Supplemental Mathematical Operators
    0x2B00,0x2B4C, // Miscellaneous Symbols and Arrows (exclude reserved)
    0x2B50,0x2B59, // Miscellaneous Symbols and Arrows
    0x2C60,0x2C7F, // Latin Extended-C
    0x2C80,0x2CEE, // Coptic
    0x2CF9,0x2CFF, // Coptic
    0x2E00,0x2E31, // Supplemental Punctuation
    0x2E80,0x2E99, // CJK Radicals Supplement (minus reserved character)
    0x2E9B,0x2EF3, // CJK Radicals Supplement
    0x2F00,0x2FD5, // Kangxi Radicals
    0x2FF0,0x2FFB, // Ideographic Description Characters
    0x3000,0x3029, // CJK Symbols and Punctuation (excluding level tone marks)
    0x3030,0x303F, // CJK Symbols and Punctuation
    0x3041,0x3096, // Hiragana (excluding voicing diacritics)
    0x309B,0x309F, // Hiragana
    0x30A0,0x30FF, // Katakana
    0x3105,0x312D, // Bopomofo
    0x3131,0x318E, // Hangul Compatibility Jamo
    0x3190,0x319F, // Kanbun
    0x31A0,0x31BA, // Bopomofo Extended
    0x31C0,0x31E3, // CJK Strokes
    0x31F0,0x31FF, // Katakana Phonetic Extensions
    0x3200,0x321E, // Enclosed CJK Letters and Months
    0x3220,0x32FE, // Enclosed CJK Letters and Months
    0x3300,0x33FF, // CJK Compatibility
    0x3400,0x4DB5, // CJK Unified Ideographs Extension A
    0x4DC0,0x4DFF, // Yijing Hexagram Symbols
    0x4E00,0x9FCB, // CJK Unified Ideographs
    0xA000,0xA48C, // Yi Syllables
    0xA490,0xA4C6, // Yi Radicals
    0xA4D0,0xA4FF, // Lisu
    0xA500,0xA62B, // Vai
    0xA640,0xA66E, // Cyrillic Extended-B (excluding diacritics and reserved)
    0xA673,0xA673, // Cyrillic Extended-B
    0xA67E,0xA67E, // Cyrillic Extended-B
    0xA680,0xA697, // Cyrillic Extended-B
    0xA720,0xA78E, // Latin Extended-D
    0xA790,0xA791, // Latin Extended-D
    0xA7A0,0xA7A9, // Latin Extended-D
    0xA7FA,0xA7FF, // Latin Extended-D
    0xAC00,0xD7A3, // Hangul Syllables, precomposed (no need for LJMO VJMO TJMO features)
    0xF900,0xFA2D, // CJK Compatibility Ideographs
    0xFA30,0xFA6D, // CJK Compatibility Ideographs
    0xFA70,0xFAD9, // CJK Compatibility Ideographs
    0xFB00,0xFB06, // Alphabetic Presentation Forms
    0xFB13,0xFB17, // Alphabetic Presentation Forms
    0xFE10,0xFE19, // Vertical Forms
    0xFE30,0xFE4F, // CJK Compatibility Forms
    0xFE50,0xFE52, // Small Form Variants
    0xFE54,0xFE66, // Small Form Variants
    0xFE68,0xFE6B, // Small Form Variants
    0xFF01,0xFFBE, // Halfwidth and Fullwidth Forms
    0xFFC2,0xFFC7, // Halfwidth and Fullwidth Forms
    0xFFCA,0xFFCF, // Halfwidth and Fullwidth Forms
    0xFFD2,0xFFD7, // Halfwidth and Fullwidth Forms
    0xFFDA,0xFFDC, // Halfwidth and Fullwidth Forms
    0xFFE0,0xFFE6, // Halfwidth and Fullwidth Forms
    0xFFE8,0xFFEE, // Halfwidth and Fullwidth Forms
};


bool IsCharacterSimple(char32_t ch)
{
    const UnicodeRange v = {ch,ch};
    bool isSimple = std::binary_search(
        SimpleCharacters,
        SimpleCharacters + ARRAYSIZE(SimpleCharacters),
        v,
        [](const UnicodeRange& r, const UnicodeRange& v) -> bool
        {
            return r.last < v.first;
        }
    );
    return isSimple;
}


namespace
{
    struct IntSequence
    {
        IntSequence (int initialValue = 0) : value(initialValue) { }
        int operator() () { return value++; }
        int value;
    };
}


void GetSimpleCharacters(__out std::vector<char32_t>& characters)
{
    uint32_t simpleCharacterCount = 0;
    for (uint32_t i = 0; i < ARRAYSIZE(SimpleCharacters); ++i)
    {
        uint32_t characterRangeCount = SimpleCharacters[i].last - SimpleCharacters[i].first + 1;
        simpleCharacterCount += characterRangeCount;
    }

    characters.resize(simpleCharacterCount);
    auto* currentRangeData = characters.data();

    for (uint32_t i = 0, j = 0; i < ARRAYSIZE(SimpleCharacters); ++i)
    {
        const auto& range = SimpleCharacters[i];
        auto characterRangeCount = range.last - range.first + 1;
        std::generate(currentRangeData, currentRangeData + characterRangeCount, IntSequence(range.first));
        currentRangeData += characterRangeCount;
    }
}


bool IsStringSimple(
    __in_ecount(textLength) const wchar_t* text,
    __in size_t textLength
    )
{
    UnicodeCharacterReader reader = {text, text + textLength};
    while (!reader.IsAtEnd())
    {
        char32_t ch = reader.ReadNext();
        if (!IsCharacterSimple(ch))
        {
            return false;
        }
    }

    return true;
}
