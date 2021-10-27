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
/// 32-bit character sequence tag.
/// <summary>
typedef BigEndianTag OpenTypeTag;

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

    // Gets the raw integer exactly as-is, no concept of endianess.
    // This is important for table tag comparisons, where the tag
    // is a character sequence instead of a number.
    uint32_t GetRawInt() const throw()
    {
        return value_.GetRawInt();
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
/// OpenType OffsetTable structure - the TTF file header.
/// </summary>
struct TtfHeader
{
    OpenTypeFixed  version;
    OpenTypeUShort numTables;
    OpenTypeUShort searchRange;
    OpenTypeUShort entrySelector;
    OpenTypeUShort rangeShift;
};

typedef TtfHeader OffsetTable;


// Create an OpenType tag in little-endian CPU byte order.
// There is no conversion necessary before comparing with a raw tag in an OpenType font.
#define MAKE_OPENTYPE_TAG_LITTLE_ENDIAN(a,b,c,d) ( \
    (static_cast<uint32_t>(static_cast<uint8_t>(a)) <<  0) | \
    (static_cast<uint32_t>(static_cast<uint8_t>(b)) <<  8) | \
    (static_cast<uint32_t>(static_cast<uint8_t>(c)) << 16) | \
    (static_cast<uint32_t>(static_cast<uint8_t>(d)) << 24)   \
    )

// Create an OpenType tag in file byte order, i.e., that can be directly compared with a tag in an 
// OpenType font.
#ifdef FSCFG_BIG_ENDIAN
#define MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER(a,b,c,d) MAKE_OPENTYPE_TAG_LITTLE_ENDIAN(d,c,b,a)
#else
#define MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER MAKE_OPENTYPE_TAG_LITTLE_ENDIAN
#endif


enum OpenTypeTableTag : uint32_t
{
    OpenTypeTableBase = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('B', 'A', 'S', 'E'), // baseline table ('BASE')
    OpenTypeTableCmap = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('c', 'm', 'a', 'p'), // character to index map ('cmap')
    OpenTypeTableCvt  = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('c', 'v', 't', ' '), // control value table ('cvt ')
    OpenTypeTableColr = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('C', 'O', 'L', 'R'), // color glyph table ('COLR')
    OpenTypeTableCpal = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('C', 'P', 'A', 'L'), // color palette ('CPAL')
    OpenTypeTableEblc = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('E', 'B', 'L', 'C'), // embedded bitmap location ('EBLC')
    OpenTypeTableEbdt = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('E', 'B', 'D', 'T'), // embedded bitmap data ('EBDT')
    OpenTypeTableEbsc = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('E', 'B', 'S', 'C'), // embedded bitmap scaing ('EBSC')
    OpenTypeTableFpgm = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('f', 'p', 'g', 'm'), // font program ('fpgm')
    OpenTypeTableGasp = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('g', 'a', 's', 'p'), // grid fitting and scan conversion procedure ('gasp')
    OpenTypeTableGdef = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('G', 'D', 'E', 'F'), // glyph definition data ('GDEF')
    OpenTypeTableGlyf = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('g', 'l', 'y', 'f'), // glyf data ('glyf')
    OpenTypeTableGpos = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('G', 'P', 'O', 'S'), // glyph positioning data ('GPOS')
    OpenTypeTableGsub = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('G', 'S', 'U', 'B'), // glyph substitution data ('GSUB')
    OpenTypeTableHead = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('h', 'e', 'a', 'd'), // font header ('head')
    OpenTypeTableHdmx = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('h', 'd', 'm', 'x'), // horizontal device metrics ('hdmx')
    OpenTypeTableHhea = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('h', 'h', 'e', 'a'), // horizontal header ('hhea')
    OpenTypeTableHmtx = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('h', 'm', 't', 'x'), // horizontal metrics ('hmtx')
    OpenTypeTableJstf = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('J', 'S', 'T', 'F'), // justification data ('JSTF')
    OpenTypeTableKern = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('k', 'e', 'r', 'n'), // kerning ('kern')
    OpenTypeTableLtsh = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('L', 'T', 'S', 'H'), // Linear threshold ('LTSH')
    OpenTypeTableLoca = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('l', 'o', 'c', 'a'), // index to location ('loca')
    OpenTypeTableMaxp = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('m', 'a', 'x', 'p'), // maximum profile table ('maxp')
    OpenTypeTableMerg = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('M', 'E', 'R', 'G'), // glyph merging table ('MERG')
    OpenTypeTableName = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('n', 'a', 'm', 'e'), // naming table ('name')
    OpenTypeTableOS2  = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('O', 'S', '/', '2'), // OS/2 and Windows specific metrics ('OS/2')
    OpenTypeTablePclt = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('P', 'C', 'L', 'T'), // PCL 5 data ('PCLT')
    OpenTypeTablePost = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('p', 'o', 's', 't'), // PostScript information ('post')
    OpenTypeTablePrep = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('p', 'r', 'e', 'p'), // control value program ('prep')
    OpenTypeTableVhea = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('v', 'h', 'e', 'a'), // vertical metrics header ('vhea')
    OpenTypeTableVmtx = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('v', 'm', 't', 'x'), // vertical metrics ('vmtx')
    OpenTypeTableVorg = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('V', 'O', 'R', 'G'), // vertical origins ('VORG')
    OpenTypeTableVdmx = MAKE_OPENTYPE_TAG_FILE_BYTE_ORDER('V', 'D', 'M', 'X'), // vertical device metrics ('VDMX')
};


#if 0//delete
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
