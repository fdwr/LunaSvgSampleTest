//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2006. All rights reserved.
//
//  File:       OpenTypeDefs.h
//
//  Contents:   Types that correspond to structures/values in memory-mapped
//              OpenType font files.
//
//  Author:     Niklas Borson (niklasb@microsoft.com)
//
//  History:    08-31-2006   niklasb    Created
//
//----------------------------------------------------------------------------
#pragma once


enum Script;


/// <summary>
/// Convenience typedef for checked pointer to font data.
/// </summary>
//typedef CheckedPtr<uint8_t const, FailAsFileFormatException, size_t> CheckedFontPtr;


/// <summary>
/// 8-bit unsigned integer in memory-mapped OpenType font.
/// <summary>
typedef uint8_t OpenTypeByte;


/// <summary>
/// 8-bit signed integer in memory-mapped OpenType font.
/// <summary>
typedef int8_t OpenTypeChar;

/// <summary>
/// 16-bit unsigned integer in memory-mapped OpenType font.
/// <summary>
typedef BigEndianUShort OpenTypeUShort;

/// <summary>
/// 16-bit signed integer in memory-mapped OpenType font.
/// <summary>
typedef BigEndianShort OpenTypeShort;

/// <summary>
/// 32-bit unsigned integer in memory-mapped OpenType font.
/// <summary>
typedef BigEndianULong OpenTypeULong;

/// <summary>
/// 32-bit signed integer in memory-mapped OpenType font.
/// <summary>
typedef BigEndianLong OpenTypeLong;

/// <summary>
/// 32-bit signed fixed-point number (16.16) in memory-mapped OpenType font.
/// <summary>
struct OpenTypeFixed
{
    /// <summary>
    /// Explicit getter returning native integer type. Converts from file representation,
    /// which is big-endian.
    /// </summary>
    int32_t ToInt() const throw()
    {
        return value_.Get();
    }

    /// <summary>
    /// Convert from fixed point to floating point type.
    /// </summary>
    double ToDouble() const throw()
    {
        int32_t const fixed = value_.Get();
        return fixed * (1.0 / Multiplier);
    }

    static const int32_t Multiplier = 0x10000;

    OpenTypeULong value_;
};


/// <summary>
/// 16-bit signed number in font units.
/// <summary>
struct OpenTypeFWord
{
    /// <summary>
    /// Explicit getter returning native integer type. Converts from file representation,
    /// which is big-endian.
    /// </summary>
    int16_t Get() const throw()
    {
        return value_.Get();
    }

    OpenTypeShort value_;
};


/// <summary>
/// 16-bit unsigned number in font units.
/// <summary>
struct OpenTypeUFWord
{
    /// <summary>
    /// Explicit getter returning native integer type. Converts from file representation,
    /// which is big-endian.
    /// </summary>
    uint16_t Get() const throw()
    {
        return value_.Get();
    }

    OpenTypeUShort value_;
};


/// <summary>
/// OpenType OffsetTable structure.
/// </summary>
struct OffsetTable
{
    OpenTypeFixed  version;
    OpenTypeUShort numTables;
    OpenTypeUShort searchRange;
    OpenTypeUShort entrySelector;
    OpenTypeUShort rangeShift;
};


// Create an OpenType tag in native CPU byte order. Before comparing with a tag in an OpenType font, the
// value in the font must be converted from file byte order to native byte order.
#define MAKE_OPENTYPE_TAG(a,b,c,d) ( \
    (static_cast<uint32_t>(static_cast<uint8_t>(a)) << 24) | \
    (static_cast<uint32_t>(static_cast<uint8_t>(b)) << 16) | \
    (static_cast<uint32_t>(static_cast<uint8_t>(c)) << 8)  | \
     static_cast<uint32_t>(static_cast<uint8_t>(d)))

// Create an OpenType tag in file byte order, i.e., that can be directly compared with a tag in an 
// OpenType font.
#ifdef FSCFG_BIG_ENDIAN
#define MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER MAKE_OPENTYPE_TAG
#else
#define MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER(a,b,c,d) MAKE_OPENTYPE_TAG(d,c,b,a)
#endif


enum OpenTypeTable
{
    OpenTypeTableBase = MAKE_OPENTYPE_TAG('B', 'A', 'S', 'E'), // baseline table ('BASE')
    OpenTypeTableCmap = MAKE_OPENTYPE_TAG('c', 'm', 'a', 'p'), // character to index map ('cmap')
    OpenTypeTableEblc = MAKE_OPENTYPE_TAG('E', 'B', 'L', 'C'), // embedded bitmap location ('EBLC')
    OpenTypeTableGasp = MAKE_OPENTYPE_TAG('g', 'a', 's', 'p'), // grid fitting and scan conversion procedure ('gasp')
    OpenTypeTableGdef = MAKE_OPENTYPE_TAG('G', 'D', 'E', 'F'), // glyph definition data ('GDEF')
    OpenTypeTableGlyf = MAKE_OPENTYPE_TAG('g', 'l', 'y', 'f'), // glyf data ('glyf')
    OpenTypeTableGpos = MAKE_OPENTYPE_TAG('G', 'P', 'O', 'S'), // glyph positioning data ('GPOS')
    OpenTypeTableGsub = MAKE_OPENTYPE_TAG('G', 'S', 'U', 'B'), // glyph substitution data ('GSUB')
    OpenTypeTableHead = MAKE_OPENTYPE_TAG('h', 'e', 'a', 'd'), // font header ('head')
    OpenTypeTableHdmx = MAKE_OPENTYPE_TAG('h', 'd', 'm', 'x'), // horizontal device metrics ('hdmx')
    OpenTypeTableHhea = MAKE_OPENTYPE_TAG('h', 'h', 'e', 'a'), // horizontal header ('hhea')
    OpenTypeTableHmtx = MAKE_OPENTYPE_TAG('h', 'm', 't', 'x'), // horizontal metrics ('hmtx')
    OpenTypeTableJstf = MAKE_OPENTYPE_TAG('J', 'S', 'T', 'F'), // justification data ('JSTF')
    OpenTypeTableKern = MAKE_OPENTYPE_TAG('k', 'e', 'r', 'n'), // kerning ('kern')
    OpenTypeTableLtsh = MAKE_OPENTYPE_TAG('L', 'T', 'S', 'H'), // Linear threshold ('LTSH')
    OpenTypeTableLoca = MAKE_OPENTYPE_TAG('l', 'o', 'c', 'a'), // index to location ('loca')
    OpenTypeTableMaxp = MAKE_OPENTYPE_TAG('m', 'a', 'x', 'p'), // maximum profile table ('maxp')
    OpenTypeTableName = MAKE_OPENTYPE_TAG('n', 'a', 'm', 'e'), // naming table ('name')
    OpenTypeTableOS2  = MAKE_OPENTYPE_TAG('O', 'S', '/', '2'), // OS/2 and Windows specific metrics ('OS/2')
    OpenTypeTablePclt = MAKE_OPENTYPE_TAG('P', 'C', 'L', 'T'), // PCL 5 data ('PCLT')
    OpenTypeTablePost = MAKE_OPENTYPE_TAG('p', 'o', 's', 't'), // PostScript information ('post')
    OpenTypeTableVhea = MAKE_OPENTYPE_TAG('v', 'h', 'e', 'a'), // vertical metrics header ('vhea')
    OpenTypeTableVmtx = MAKE_OPENTYPE_TAG('v', 'm', 't', 'x'), // vertical metrics ('vmtx')
    OpenTypeTableVorg = MAKE_OPENTYPE_TAG('V', 'O', 'R', 'G'), // vertical origins ('VORG')
    OpenTypeTableVdmx = MAKE_OPENTYPE_TAG('V', 'D', 'M', 'X'), // vertical device metrics ('VDMX')
};


#ifdef NOT_USED
// Returns the equivalent OpenType tag for a Unicode script.
uint32_t OpenTypeTagFromScript(Script script);


/// <summary>
/// Convenience method for constructing a SafeInt from a value in a font file; integer overflows are
/// reported as FileFormatException instead of the default IntegerOverflowException.
/// </summary>
template<class T>
inline SafeInt<T, FailAsFileFormatException> SafeFontFileInt(T value)
{
    return value;
}
#endif
