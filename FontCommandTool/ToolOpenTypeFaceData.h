//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2006. All rights reserved.
//
//  File:       OpenTypeFaceData.h
//
//  Contents:   Definitions OpenType data structures used and declared by OpenTypeFace.
//
//  Author:     Niklas Borson (niklasb@microsoft.com)
//
//  History:    08-31-2006   niklasb    Created
//
//----------------------------------------------------------------------------
#pragma once


// Make sure the compiler does not add any padding to the structures defined below, as
// they must agree exactly with binary representation in font files.
#pragma pack( push, 1 )

/// <summary>
/// TrueType collection header
/// </summary>
struct TtcHeader
{
    OpenTypeTag   tag;
    OpenTypeULong version;
    OpenTypeULong numFonts;
    OpenTypeULong offsetTable[1];
};


/// <summary>
/// OpenType table directory structure. An OpenType font begins with an OffsetTable
/// follows by an array of table records, each of which points to a particular
/// OpenType table and specifies its type.
/// </summary>
struct OpenTypeTableRecord
{
    OpenTypeTag     tag;
    OpenTypeULong   checkSum;
    OpenTypeULong   offset;
    OpenTypeULong   length;
};

typedef OpenTypeTableRecord TableDirectory;


/// <summary>
/// OpenType 'head' (Font header) table.
/// </summary>
struct FontHeader
{
    OpenTypeFixed   tableVersion;
    OpenTypeFixed   fontRevision;
    OpenTypeULong   checkSumAdjustment;
    OpenTypeULong   magicNumber;
    OpenTypeUShort  flags;
    OpenTypeUShort  unitsPerEm;
    OpenTypeULong   createdDateTimeHigh;
    OpenTypeULong   createdDateTimeLow;
    OpenTypeULong   modifiedDateTimeHigh;
    OpenTypeULong   modifiedDateTimeLow;
    OpenTypeShort   xMin;
    OpenTypeShort   yMin;
    OpenTypeShort   xMax;
    OpenTypeShort   yMax;
    OpenTypeUShort  macStyle;
    OpenTypeUShort  lowestRecPPEM;
    OpenTypeShort   fontDirectionHint;
    OpenTypeShort   indexToLocFormat;
    OpenTypeShort   glyphDataFormat;
};

// Compile-time check to make sure the FontHeader structure has the size we would expect from
// adding up the sizes of its members. If the compiler added padding (e.g., rounding 54 up to 56)
// we would incorrectly reject valid fonts because the expected size (from sizeof) would be greater
// than the structure size specified in the font (via TableDirectory::length). The assertion below
// ensures that we'll catch this at compile time.
static_assert(sizeof(FontHeader) == 54, "Structure size different than expected.");

// Compile-time check to validate field offset against corresponding constant from WPF v1 font
// driver source. If the structure definition is incorrect this should yield a compiler error.
// The constant name from WPF v1 is specified by the line comment.
static_assert(offsetof(FontHeader, indexToLocFormat) == 50, "Structure size different than expected."); // OFF_head_indexToLocFormat

enum HeadTableFlags
{
    HeadTableFlagsForceIntegerSizes   = 0x0008 // bit 3
};

// <summary>
// OpenType maxp table version 0.5.
// </summary>
struct MaxpTable
{
    OpenTypeFixed  tableVersion;
    OpenTypeUShort numGlyphs;
};

/// <summary>
/// OpenType panose data used in the OS/2 table.
/// </summary>
union OpenTypePanose
{
    OpenTypeByte values[10];

    OpenTypeByte familyKind; // this is the only field that never changes meaning

    struct
    {
        OpenTypeByte familyKind; // = 2 for text
        OpenTypeByte serifStyle;
        OpenTypeByte weight;
        OpenTypeByte proportion;
        OpenTypeByte contrast;
        OpenTypeByte strokeVariation;
        OpenTypeByte armStyle;
        OpenTypeByte letterform;
        OpenTypeByte midline;
        OpenTypeByte xHeight;
    } text;

    struct
    {
        OpenTypeByte familyKind; // = 3 for script
        OpenTypeByte toolKind;
        OpenTypeByte weight;
        OpenTypeByte spacing;
        OpenTypeByte aspectRatio;
        OpenTypeByte contrast;
        OpenTypeByte scriptTopology;
        OpenTypeByte scriptForm;
        OpenTypeByte finials;
        OpenTypeByte xAscent;
    } script;

    struct
    {
        OpenTypeByte familyKind; // = 4 for decorative
        OpenTypeByte decorativeClass;
        OpenTypeByte weight;
        OpenTypeByte aspect;
        OpenTypeByte contrast;
        OpenTypeByte serifVariant;
        OpenTypeByte fill; // treatment
        OpenTypeByte lining;
        OpenTypeByte decorativeTopology;
        OpenTypeByte characterRange;
    } decorative;

    struct
    {
        OpenTypeByte familyKind; // = 5 for symbol
        OpenTypeByte symbolKind;
        OpenTypeByte weight;
        OpenTypeByte spacing;
        OpenTypeByte aspectRatioAndContrast; // hard coded to no-fit (1)
        OpenTypeByte aspectRatio94;
        OpenTypeByte aspectRatio119;
        OpenTypeByte aspectRatio157;
        OpenTypeByte aspectRatio163;
        OpenTypeByte aspectRatio211;
    } symbol;

    enum
    {
        ProportionNoFit = 1,
        ProportionMonospaced = 9
    };
};
static_assert(sizeof(OpenTypePanose) == 10, "Structure size different than expected.");

/// <summary>
/// OpenType 'OS/2' table version 0 (first revision).
/// </summary>
struct OS2TableV0
{
    OpenTypeUShort  version;
    OpenTypeShort   xAvgCharWidth;
    OpenTypeUShort  usWeightClass;
    OpenTypeUShort  usWidthClass;
    OpenTypeUShort  fsType;
    OpenTypeShort   ySubscriptXSize;
    OpenTypeShort   ySubscriptYSize;
    OpenTypeShort   ySubscriptXOffset;
    OpenTypeShort   ySubscriptYOffset;
    OpenTypeShort   ySuperscriptXSize;
    OpenTypeShort   ySuperscriptYSize;
    OpenTypeShort   ySuperscriptXOffset;
    OpenTypeShort   ySuperscriptYOffset;
    OpenTypeShort   yStrikeoutSize;
    OpenTypeShort   yStrikeoutPosition;
    OpenTypeShort   sFamilyClass;
    OpenTypePanose  panose;
    OpenTypeULong   ulUnicodeRange1;    // Bits 0-31
    OpenTypeULong   ulUnicodeRange2;    // Bits 32-63
    OpenTypeULong   ulUnicodeRange3;    // Bits 64-95
    OpenTypeULong   ulUnicodeRange4;    // Bits 96-127
    OpenTypeChar    achVendID[4];
    OpenTypeUShort  fsSelection;        // OS2SelectionFlags
    OpenTypeUShort  usFirstCharIndex;
    OpenTypeUShort  usLastCharIndex;
    OpenTypeShort   sTypoAscender;
    OpenTypeShort   sTypoDescender;
    OpenTypeShort   sTypoLineGap;
    OpenTypeUShort  usWinAscent;
    OpenTypeShort   sWinDescent;        // The OpenType spec lists member as an unsigned value (usWinDescent). However, some fonts get the sign
};                                      // wrong and specify a negative value. We therefore follow WPF's example, and read it as a signed short 
                                        // but take the absolute value.

/// <summary>
/// OpenType 'OS/2' table version 1 (second revision).
/// </summary>
struct OS2TableV1
{
    OS2TableV0      table;
    OpenTypeULong   ulCodePageRange1; // Bits 0-31
    OpenTypeULong   ulCodePageRange2; // Bits 32-63
};


/// <summary>
/// OpenType 'OS/2' table version 2 (third revision).
/// </summary>
struct OS2TableV2
{
    OS2TableV1      table;
    OpenTypeShort   sxHeight;
    OpenTypeShort   sCapHeight;
    OpenTypeUShort  usDefaultChar;
    OpenTypeUShort  usBreakChar;
    OpenTypeUShort  usMaxContext;
};


// Compile-time check to validate field offset against corresponding constant from WPF v1 font
// driver source. If the structure definition is incorrect this should yield a compiler error.
// The constant name from WPF v1 is specified by the line comment.
static_assert(offsetof(OS2TableV2, sCapHeight) == 88, "Structure size different than expected."); // OFF_OS2_sCapHeight


enum OS2SelectionFlags
{
    Os2SelectionItalic =                0x0001,
    Os2SelectionUnderscore =            0x0002,
    Os2SelectionNegative =              0x0004,
    Os2SelectionOutlined =              0x0008,
    Os2SelectionStrikeout =             0x0010,
    Os2SelectionBold =                  0x0020,
    Os2SelectionRegular =               0x0040,
    Os2SelectionDontUseWinLineMetrics = 0x0080,
    Os2SelectionWeightWidthSlopeOnly =  0x0100,
    Os2SelectionOblique =               0x0200
};



/// <summary>
/// OpenType 'hhea' (Horizontal Header) table.
/// </summary>
struct HorizontalHeader
{
    // Note: The OpenType spec declares ascender, descender, and lineGap to be of type FWORD (fixed-point numbers),
    // but WPF reads them as the types declared below.

    OpenTypeFixed   Table;                // version number 0x00010000 for version 1.0. 
    OpenTypeUShort  ascender;             // distance from baseline of highest ascender
    OpenTypeShort   descender;            // distance from baseline of lowest descender  
    OpenTypeShort   lineGap;              // typographic line gap; negative values are treated as zero in Windows 3.1, System 6, and System 7.
    OpenTypeUFWord  advanceWidthMax;      // Maximum advance width value in 'hmtx' table. 
    OpenTypeFWord   minLeftSideBearing;   // Minimum left sidebearing value in 'hmtx' table. 
    OpenTypeFWord   minRightSideBearing;  // Minimum right sidebearing value; calculated as Min(aw - lsb - (xMax - xMin)). 
    OpenTypeFWord   xMaxExtent;           // Max(lsb + (xMax - xMin)). 
    OpenTypeShort   caretSlopeRise;       // Used to calculate the slope of the cursor (rise/run); 1 for vertical. 
    OpenTypeShort   caretSlopeRun;        // 0 for vertical. 
    OpenTypeShort   caretOffset;          // The amount by which a slanted highlight on a glyph needs to be shifted to produce the best appearance. Set to 0 for non-slanted fonts 
    OpenTypeShort   reserved[4];          // (reserved) set to 0 
    OpenTypeShort   metricDataFormat;     // 0 for current format. 
    OpenTypeUShort  numberOfHMetrics;     // Number of hMetric entries in 'hmtx' table 
};

// Compile-time check to validate field offset against corresponding constant from WPF v1 font
// driver source. If the structure definition is incorrect this should yield a compiler error.
// The constant name from WPF v1 is specified by the line comment.
static_assert(offsetof(HorizontalHeader, numberOfHMetrics) == 34, "Structure size different than expected."); // OFF_hhea_numberOfHMetrics


/// <summary>
/// Element of array of metrics at the start of the hmtx table. The number of elements
/// is specified by HorizontalHeader::numberOfHMetrics. This is optionally followed by 
/// an array of OpenTypeShort that specifies left side bearings of additional glyphs,
/// which are assumed to have the same advance width as the last HmtxEntry.
/// </summary>
struct HmtxEntry
{
    OpenTypeUShort  advanceWidth;
    OpenTypeShort   leftSideBearing;
};


/// <summary>
/// OpenType 'vhea' (Vertical Header) table.
/// </summary>
struct VerticalHeader
{
    OpenTypeFixed   version;            // 1.0 or 1.1
    OpenTypeShort   vertTypoAscender;   // 'ascender' if version == 1.0
    OpenTypeShort   vertTypoDescender;  // 'descender' if version == 1.0
    OpenTypeShort   vertTypoLineGap;    // 'lineGap' if version == 1.0
    OpenTypeShort   advanceHeightMax;
    OpenTypeShort   minTopSideBearing;
    OpenTypeShort   minBottomSideBearing;
    OpenTypeShort   yMaxExtent;
    OpenTypeShort   caretSlopeRise;
    OpenTypeShort   caretSlopeRun;
    OpenTypeShort   caretOffset;
    OpenTypeShort   reserved[4];
    OpenTypeShort   metricDataFormat;
    OpenTypeUShort  numberOfVMetrics;
};

/// <summary>
/// Element of array of metrics at the start of the hmtx table. The number of elements
/// is specified by VerticalHeader::numberOfVMetrics. This is optionally followed by 
/// an array of OpenTypeShort that specifies top side bearings of additional glyphs,
/// which are assumed to have the same advance height as the last VmtxEntry.
/// </summary>
struct VmtxEntry
{
    OpenTypeUShort  advanceHeight;
    OpenTypeShort   topSideBearing;
};


/// <summary>
/// Header at the start of the vertical origins ('vorg') table.
/// </summary>
struct VorgHeader
{
    OpenTypeUShort  majorVersion;
    OpenTypeUShort  minorVersion;
    OpenTypeShort   defaultVertOriginY;
    OpenTypeUShort  numVertOriginYMetrics;
};

struct VorgEntry
{
    OpenTypeUShort  glyphIndex;
    OpenTypeShort   vertOriginY;
};


/// <summary>
/// OpenType 'post' (PostScript information) table.
/// </summary>
struct PostScript
{
    OpenTypeFixed   Version;            // 0x00010000 for version 1.0 
                                        // 0x00020000 for version 2.0 
                                        // 0x00025000 for version 2.5 (deprecated) 
                                        // 0x00030000 for version 3.0 
    OpenTypeFixed   italicAngle;        // Italic angle in counter-clockwise degrees from the vertical. Zero for upright text, negative for text that leans to the right (forward). 
    OpenTypeShort   underlinePosition;  // This is the suggested distance of the top of the underline from the baseline (negative values indicate below baseline). 
                                        // The PostScript definition of this FontInfo dictionary key (the y coordinate of the center of the stroke) is not used for historical reasons. The value of the PostScript key may be calculated by subtracting half the underlineThickness from the value of this field.  
    OpenTypeUShort  underlineThickness; // Suggested values for the underline thickness. 
    OpenTypeULong   isFixedPitch;       // Set to 0 if the font is proportionally spaced, non-zero if the font is not proportionally spaced (i.e. monospaced). 
    OpenTypeULong   minMemType42;       // Minimum memory usage when an OpenType font is downloaded.
    OpenTypeULong   maxMemType42;       // Maximum memory usage when an OpenType font is downloaded. 
    OpenTypeULong   minMemType1;        // Minimum memory usage when an OpenType font is downloaded as a Type 1 font. 
    OpenTypeULong   maxMemType1;        // Maximum memory usage when an OpenType font is downloaded as a Type 1 font.
};

// Compile-time check to validate field offset against corresponding constant from WPF v1 font
// driver source. If the structure definition is incorrect this should yield a compiler error.
// The constant name from WPF v1 is specified by the line comment.
static_assert(offsetof(PostScript, underlineThickness) == 10, "Structure size different than expected."); // OFF_post_underlineThickness


/// <summary>
/// Header portion of the 'gasp' (grid fitting and scan conversion procedure) table.
/// </summary>
struct GaspHeader
{
    OpenTypeUShort  version;            // Version number (set to 0) 
    OpenTypeUShort  count;				// Number of records to follow 
};


/// <summary>
/// One of the array of entries that follows the header in the 'gasp' table.
/// </summary>
struct GaspRange
{
    OpenTypeUShort  rangeMaxPPEM;       // Upper limit of range, in PPEM 
    OpenTypeUShort  rangeGaspBehavior;  // Flags describing desired rasterizer behavior. 
};


/// <summary>
/// Header portion of the 'EBLC' (Embedded Bitmap Location) table.
/// </summary>
struct EblcHeader
{
    OpenTypeFixed   version;            // initially defined as 0x00020000 
    OpenTypeULong   count;				// Number of bitmapSizeTables 
};

// Compile-time check to validate field offset against corresponding constant from WPF v1 font
// driver source. If the structure definition is incorrect this should yield a compiler error.
// The constant name from WPF v1 is specified by the line comment.
static_assert(sizeof(EblcHeader) == 8, "Structure size different than expected."); // OFF_eblc_bitmapSizeTables

/// <summary>
/// Header portion of the 'GSUB' (glyph substitution) table.
/// </summary>
struct GsubHeader
{
    OpenTypeULong   version;
    OpenTypeUShort  scriptListOffset;
    OpenTypeUShort  featureListOffset;
    OpenTypeUShort  lookupListOffset;
};

/// <summary>
/// Header portion of the 'GPOS' (glyph positioning) table.
/// </summary>
struct GposHeader
{
    OpenTypeULong   version;
    OpenTypeUShort  scriptListOffset;
    OpenTypeUShort  featureListOffset;
    OpenTypeUShort  lookupListOffset;
};

/// <summary>
/// List of scripts.
/// </summary>
struct ScriptList
{
   OpenTypeUShort   scriptCount;                // Number of ScriptRecords in this table
   // ScriptRecord  scriptRecords[scriptCount]  // Array of ScriptRecords - alphabetic by ScriptTag
};

/// <summary>
/// Single script entry.
/// </summary>
struct ScriptRecord
{
    OpenTypeTag     tag;                        // 4-byte script tag identifier
    OpenTypeUShort  offset;                     // Offset to script's LanguageList or BaseScript table - from beginning of ScriptList
};

/// <summary>
/// List of features.
/// </summary>
struct FeatureList
{
   OpenTypeUShort   featureCount;               // Number of FeatureRecords in this table
// FeatureRecord    featureRecords[featureCount]// Array of FeatureRecords - zero-based
};

/// <summary>
/// Single feature entry.
/// </summary>
struct FeatureRecord
{
    OpenTypeTag     tag;                        // 4-byte feature identification tag
    OpenTypeUShort  offset;                     // Offset to Feature Lookup List - from beginning of FeatureList
};

/// <summary>
/// Feature table that defines a feature and a list of its lookup indices.
/// </summary>
struct FeatureLookupList
{
    OpenTypeUShort featureParams;               // = NULL (reserved for offset to FeatureParams)
    OpenTypeUShort lookupCount;                 // Number of LookupList indices for this feature
 // OpenTypeUShort lookupIndices[lookupCount]   // Array of LookupList indices for this feature - zero-based (first lookup is LookupListIndex = 0)
};

/// <summary>
/// List of language/system records, pointed to from the script list.
/// </summary>
struct LanguageList
{
    OpenTypeUShort  defaultOffset;              // Offset to default language feature list - from beginning of LanguageList - may be NULL
    OpenTypeUShort  languageCount;              // Number of LanguageRecords for this script - excluding the default language
 // LanguageRecord languageRecords[languageCount] // Array of LanguageRecords - listed alphabetically by language tag
};

/// <summary>
/// Single language/system entry.
/// </summary>
struct LanguageRecord 
{
    OpenTypeTag     tag;                        // 4-byte language tag identifier
    OpenTypeUShort  offset;                     // Offset to language feature list table - from beginning of Script table
};

/// <summary>
/// List of feature indices for a given language/system.
/// </summary>
struct LanguageFeatureList
{
    OpenTypeUShort  lookupOrderOffset;          // NULL (reserved for an offset to a reordering table)
    OpenTypeUShort  requiredFeature;            // Index of a feature required for this language system - if no required features = 0xFFFF
    OpenTypeUShort  featureCount;               // Number of FeatureIndex values for this language system - excludes the required feature
 // OpenTypeUShort  featureIndices[featureCount]// Array of indices into the FeatureList - in arbitrary order (ecount=FeatureCount)
};

/// <summary>
/// List of lookup records.
/// </summary>
struct LookupList
{
    OpenTypeUShort  lookupCount;                // Number of lookups in this table
 // OpenTypeUShort  lookupOffsets[lookupCount]  // Array of offsets to Lookup subtable lists - from beginning of LookupList - zero based (first lookup is Lookup index = 0)
};

/// <summary>
/// Lookup table with list of subtables.
/// </summary>
struct LookupTableList
{
    OpenTypeUShort  lookupType;	                // Different enumerations for GSUB and GPOS
    OpenTypeUShort  lookupFlag;	                // Lookup qualifiers
    OpenTypeUShort  subtableCount;	            // Number of Subtables for this lookup
 // OpenTypeUShort  subtableOffsets[subtableCount] // Array of offsets to SubTables - from beginning of Lookup record

    /// <summary>
    /// The different types of lookups supported in the GSUB/GPOS table.
    /// </summary>
    enum Type
    {
        TypeSingleSub = 1,
        TypeMultipleSub = 2,
        TypeAlternateSub = 3,
        TypeLigatureSub = 4,
        TypeContextualSub = 5,
        TypeChainingSub = 6,
        TypeExtensionLookupSub = 7,
        TypeReverseChainingSub = 8,

        TypeSinglePos = 1,
        TypePairPos = 2,
        TypeCursivePos = 3,
        TypeMarkToBasePos = 4,
        TypeMarkToLigaturePos = 5,
        TypeMarkToMarkPos = 6,
        TypeContextualPos = 7,
        TypeChainingPos = 8,
        TypeExtensionLookupPos = 9
    };
};

/// <summary>
/// A Coverage table identifies the glyphs affected by a lookup.
/// </summary>
struct CoverageTable
{
    OpenTypeUShort	format;                     // Format identifier (1 or 2)
};

/// <summary>
/// A Coverage table with individual glyph IDs.
/// </summary>
struct CoverageTableFormat1 : CoverageTable
{
    OpenTypeUShort  glyphCount;                 // Number of glyphs in the GlyphArray
 // OpenTypeUShort  glyphArray[glyphCount];     // Array of GlyphIDs - in numerical order
};

/// <summary>
/// A Coverage table with ranges of glyph IDs.
/// </summary>
struct CoverageTableFormat2 : CoverageTable
{
    OpenTypeUShort      rangeCount;	             // Number of RangeRecords
 // CoverageRangeRecord rangeRecords[rangeCount];// Array of glyph ranges - ordered by Start GlyphID
};

/// <summary>
/// Range of glyphs.
/// </summary>
struct CoverageRangeRecord 
{
    OpenTypeUShort  firstGlyph;                 // First GlyphID in the range
    OpenTypeUShort  lastGlyph;                  // Last GlyphID in the range (inclusive, not the STL-like one-past end)
    OpenTypeUShort  startCoverageIndex;         // Coverage Index of first GlyphID in range
};

/// <summary>
/// List of offsets to coverage tables.
/// (this type is not specifically listed in the OpenType specification, but
///  it is used for coverage based chaining substitution, lookup 6 format 3)
/// </summary>
struct CoverageOffsetList
{
    OpenTypeUShort  coverageCount;                  // Number of coverage tables
 // OpenTypeUShort  coverageOffsets[coverageCount]; // Offsets to coverage tables
};


/// <summary>
/// GSUB lookup type 1.
/// </summary>
struct SingleSubstitutionSubtable
{
    OpenTypeUShort  format;                     // Format identifier
    OpenTypeUShort  coverageOffset;             // Offset to Coverage table - from beginning of Substitution table
};

struct SingleSubstitutionSubtableFormat1 : SingleSubstitutionSubtable
{
    OpenTypeUShort  deltaGlyphID;               // Add to original GlyphID to get substitute GlyphID
};

struct SingleSubstitutionSubtableFormat2 : SingleSubstitutionSubtable
{
    OpenTypeUShort  glyphCount;                 // Number of GlyphIDs in the Substitute array
 // OpenTypeUShort  substitutes[glyphCount]     // Array of substitute GlyphIDs - ordered by Coverage Index
};

/// <summary>
/// GSUB lookup type 2.
/// </summary>
struct MultipleSubstitutionSubtable
{
    OpenTypeUShort  format;                     // Format identifier
    OpenTypeUShort  coverageOffset;             // Offset to Coverage table - from beginning of Substitution table
};

/// <summary>
/// Multiple output glyphs.
/// </summary>
struct MultipleSubstitutionSubtableFormat1 : MultipleSubstitutionSubtable
{
    OpenTypeUShort  sequenceCount;                  // Number of Sequence table offsets in the Sequence array
 // OpenTypeUShort  sequenceOffsets[sequenceCount]; // Array of offsets to Sequence tables - from beginning of Substitution table - ordered by Coverage Index

    struct Sequence
    {
        OpenTypeUShort  glyphCount;                 // Number of GlyphIDs in the Substitute array. This should always be greater than 0.
     // OpenTypeUShort  glyphSubstitutes[glyphCount];// String of GlyphIDs to substitute
    };
};

/// <summary>
/// GSUB lookup type 3.
/// </summary>
struct AlternateSubstitutionSubtable
{
    OpenTypeUShort  format;                     // Format identifier
    OpenTypeUShort  coverageOffset;             // Offset to Coverage table - from beginning of Substitution table
};

struct AlternateSubstitutionSubtableFormat1 : AlternateSubstitutionSubtable
{
    OpenTypeUShort  alternateSetCount;                      // Number of AlternateSet tables
 // OpenTypeUShort  alternateSetOffsets[alternateSetCount]; // Array of offsets to AlternateSet tables - from beginning of Substitution table - ordered by Coverage Index

    struct AlternateSet
    {
        OpenTypeUShort  glyphCount;                         // Number of GlyphIDs in the Alternate array
     // OpenTypeUShort  glyphAlternates[glyphCount];        // Array of alternate GlyphIDs - in arbitrary order
    };
};

/// <summary>
/// GSUB lookup type 4.
/// </summary>
struct LigatureSubstitutionSubtable
{
    OpenTypeUShort  format;                             // Format identifier
    OpenTypeUShort  coverageOffset;                     // Offset to Coverage table - from beginning of Substitution table

    /// <summary>
    /// All ligatures beginning with the same glyph.
    /// </summary>
    struct LigatureSet
    {
        OpenTypeUShort  ligatureCount;                  // Number of Ligature tables
     // OpenTypeUShort  ligatureOffsets[ligatureCount]; // Array of offsets to Ligature tables - from beginning of LigatureSet table - ordered by preference
    };

    /// <summary>
    /// Glyph components for one ligature.
    /// </summary>
    struct Ligature
    {
        OpenTypeUShort  ligatureGlyph;                  // GlyphID of ligature to substitute
        OpenTypeUShort  componentCount;                 // Number of components in the ligature
     // OpenTypeUShort  components[componentCount - 1]; // Array of component GlyphIDs - start with the second component - ordered in writing direction
    };
};

/// <summary>
/// All ligature substitutions in a script.
/// </summary>
struct LigatureSubstitutionSubtableFormat1 : LigatureSubstitutionSubtable
{
    OpenTypeUShort  ligatureSetCount;                       // Number of LigatureSet tables
 // OpenTypeUShort  ligatureSetOffsets[ligatureSetCount];   // Array of offsets to LigatureSet tables - from beginning of Substitution table - ordered by Coverage Index
};

struct ContextLookupRecord
{        
    OpenTypeUShort  sequenceIndex;              // Index to input glyph sequence - first glyph = 0
    OpenTypeUShort  lookupListIndex;            // Lookup to apply to that position - zero - based
};

typedef ContextLookupRecord PosLookupRecord;
typedef ContextLookupRecord SubstLookupRecord;

/// <summary>
/// GSUB lookup type 5, GPOS lookup type 7.
/// </summary>
struct ContextSubtable
{
    OpenTypeUShort  format;                     // Format identifier
};

/// <summary>
/// GSUB lookup type 5, GPOS lookup type 7 : format 1
/// Simple context glyph substitution / positioning.
/// </summary>
struct GlyphContextSubtable : ContextSubtable
{
    OpenTypeUShort  coverageOffset;                     // Offset to Coverage table - from beginning of Substitution/Positioning table
    OpenTypeUShort  ruleSetCount;                       // Number of RuleSet tables - must equal GlyphCount in Coverage table
 // OpenTypeUShort  ruleSetOffsets[ruleSetCount];       // Array of offsets to SubRuleSet tables - from beginning of Substitution/Positioning table - ordered by Coverage Index

    /// <summary>
    /// All contexts beginning with the same glyph.
    /// </summary>
    struct RuleSet
    {
        OpenTypeUShort  subRuleCount;                   // Number of SubRule tables
     // OpenTypeUShort  subRuleOffsets[subRuleCount];   // Array of offsets to Rule tables - from beginning of RuleSet table - ordered by preference
    };

    /// <summary>
    /// One simple context definition.
    /// </summary>
    struct Rule
    {
        OpenTypeUShort  glyphCount;                     // Total number of glyphs in input glyph sequence - includes the first glyph
        OpenTypeUShort  lookupCount;                    // Number of ContextLookupRecords
     // OpenTypeUShort  inputGlyphs[glyphCount - 1];    // Array of input GlyphIDs - start with second glyph
     // ContextLookupRecord lookupRecords[lookupCount]; // Array of ContextLookupRecords - in design order
    };
};

/// <summary>
/// GSUB lookup type 5, GPOS lookup type 7 : format 2
/// Class-based context glyph substitution.
/// </summary>
struct ClassContextSubtable : ContextSubtable
{
    OpenTypeUShort  coverageOffset;                     // Offset to Coverage table - from beginning of Substitution/Positioning table
    OpenTypeUShort  classDefOffset;                     // Offset to glyph ClassDef table - from beginning of Substitution/Positioning table
    OpenTypeUShort  classSetCount;                      // Number of ClassSet tables
 // OpenTypeUShort  classSetOffsets[classSetCount];     // Array of offsets to SubClassSet tables - from beginning of Substitution/Positioning table - ordered by class - may be NULL

    struct ClassSet
    {
        OpenTypeUShort  classRuleCount;                  // Number of SubClassRule tables
     // OpenTypeUShort  classRuleOffsets[classRuleCount];// Array of offsets to SubClassRule tables - from beginning of SubClassSet - ordered by preference
    };

    /// <summary>
    /// Context definition for one class.
    /// </summary>
    struct ClassRule
    {
        OpenTypeUShort      glyphCount;                 // Total number of classes specified for the context in the rule - includes the first class
        OpenTypeUShort      lookupCount;                // Number of ContextLookupRecords
     // OpenTypeUShort      classes[glyphCount - 1];    // Array of classes - beginning with the second class - to be matched to the input glyph class sequence
     // ContextLookupRecord lookupRecords[lookupCount]; // Array of Substitution lookups - in design order
    };
};

/// <summary>
/// GSUB lookup type 5, GPOS lookup type 7 : format 3
/// Coverage-based context glyph substitution.
/// </summary>
struct CoverageContextSubtable : ContextSubtable
{
    OpenTypeUShort      glyphCount;                     // Number of glyphs in the input glyph sequence
    OpenTypeUShort      lookupCount;                    // Number of ContextLookupRecords
 // OpenTypeUShort      coverageOffsets[glyphCount];    // Array of offsets to Coverage table - from beginning of Substitution/Positioning table - in glyph sequence order
 // ContextLookupRecord lookupRecords[lookupCount];     // Array of ContextLookupRecords - in design order
};

/// <summary>
/// GSUB lookup type 6, GPOS lookup type 8
/// </summary>
struct ChainingSubtable
{
    OpenTypeUShort  format;                     // Format identifier
};

/// <summary>
/// GSUB lookup type 6, GPOS lookup type 8 : format 1
/// Simple context glyph substitution.
/// </summary>
struct GlyphChainingSubtable : ChainingSubtable
{
    OpenTypeUShort  coverageOffset;                             // Offset to Coverage table - from beginning of Substitution/Positioning table
    OpenTypeUShort  chainRuleSetCount;                          // Number of ChainRuleSet tables - must equal GlyphCount in Coverage table
 // OpenTypeUShort  chainRuleSetOffsets[ChainRuleSetCount];     // Array of offsets to ChainRuleSet tables - from beginning of Substitution/Positioning table - ordered by Coverage Index

    /// <summary>
    /// All contexts beginning with the same glyph 
    /// </summary>
    struct ChainRuleSet
    {
        OpenTypeUShort  chainRuleCount;                         // Number of ChainRule tables
     // OpenTypeUShort  chainRuleOffsets[chainRuleCount];       // Array of offsets to ChainRule tables - from beginning of ChainRuleSet table - ordered by preference
    };

    struct ChainRule
    {
        OpenTypeUShort  backtrackGlyphCount;                    // Total number of glyphs in the backtrack sequence (number of glyphs to be matched before the first glyph)
        /*** The remainder of this structure is variable size, so the definition below is virtual and here for reference. ***
        OpenTypeUShort  backtrackGlyphs[backtrackGlyphCount];   // Array of backtracking GlyphID's (to be matched before the input sequence)
        OpenTypeUShort  inputGlyphCount;                        // Total number of glyphs in the input sequence (includes the first glyph)
        OpenTypeUShort  inputGlyphs[inputGlyphCount - 1];       // Array of input GlyphIDs (start with second glyph)
        OpenTypeUShort  lookaheadGlyphCount;                    // Total number of glyphs in the look ahead sequence (number of glyphs to be matched after the input sequence)
        OpenTypeUShort  lookAheadGlyphs[lookAheadGlyphCount];   // Array of lookahead GlyphID's (to be matched after the input sequence)
        OpenTypeUShort  lookupCount;                            // Number of ContextLookupRecords
        ContextLookupRecord lookupRecords[lookupCount];         // Array of ContextLookupRecords (in design order)
        */
    };
};

/// <summary>
/// GSUB lookup type 6, GPOS lookup type 8 : format 2
/// Class-based chaining context glyph substitution.
/// </summary>
struct ClassChainingSubtable : ChainingSubtable
{
    OpenTypeUShort  coverageOffset;                             // Offset to Coverage table - from beginning of Substitution/Positioning table
    OpenTypeUShort  backtrackClassDefOffset;                    // Offset to glyph ClassDef table containing backtrack sequence data - from beginning of Substitution/Positioning table
    OpenTypeUShort  inputClassDefOffset;                        // Offset to glyph ClassDef table containing input sequence data - from beginning of Substitution/Positioning table
    OpenTypeUShort  lookaheadClassDefOffset;                    // Offset to glyph ClassDef table containing lookahead sequence data - from beginning of Substitution/Positioning table
    OpenTypeUShort  chainClassSetCount;                         // Number of ChainClassSet tables
 // OpenTypeUShort  chainClassSetOffsets[chainClassSetCount];   // Array of offsets to ChainClassSet tables - from beginning of Substitution/Positioning table - ordered by input class - may be NULL

    struct ChainClassSet
    {
        OpenTypeUShort  chainClassRuleCount;                        // Number of ChainClassRule tables
     // OpenTypeUShort  chainClassRuleOffsets[chainClassRuleCount]; // Array of offsets to ChainClassRule tables - from beginning of ChainClassSet - ordered by preference
    };

    struct ChainClassRule
    {
        OpenTypeUShort  backtrackGlyphCount;                    // Total number of glyphs in the backtrack sequence (number of glyphs to be matched before the first glyph)
        /*** The remainder of this structure is variable size, so the definition below is virtual and here for reference. ***
        OpenTypeUShort  backtrackGlyphs[backtrackGlyphCount];   // Array of backtracking classes(to be matched before the input sequence)
        OpenTypeUShort  inputGlyphCount;                        // Total number of classes in the input sequence (includes the first class)
        OpenTypeUShort  inputGlyphs[inputGlyphCount - 1];       // Array of input classes(start with second class; to be matched with the input glyph sequence)
        OpenTypeUShort  lookaheadGlyphCount;                    // Total number of classes in the look ahead sequence (number of classes to be matched after the input sequence)
        OpenTypeUShort  lookAheadGlyphs[lookAheadGlyphCount]	// Array of lookahead classes(to be matched after the input sequence)
        OpenTypeUShort  lookupCount;                            // Number of ContextLookupRecords
        ContextLookupRecord lookupRecords[lookupCount];         // Array of ContextLookupRecords (in design order)
        */
    };
};

/// <summary>
/// GSUB lookup type 6, GPOS lookup type 8 : format 3
/// Coverage-based chaining context glyph substitution.
/// </summary>
struct CoverageChainingSubtable : ChainingSubtable
{
    OpenTypeUShort  backtrackGlyphCount;                            // Number of glyphs in the backtracking sequence
    /*** The remainder of this structure is variable size, so the definition below is virtual and here for reference. ***
    OpenTypeUShort  backtrackCoverageOffsets[backtrackGlyphCount];  // Array of offsets to coverage tables in backtracking sequence, in glyph sequence order
    OpenTypeUShort  inputGlyphCount;                                // Number of glyphs in input sequence
    OpenTypeUShort  inputCoverageOffsets[inputGlyphCount];          // Array of offsets to coverage tables in input sequence, in glyph sequence order
    OpenTypeUShort  lookaheadGlyphCount;	                        // Number of glyphs in lookahead sequence
    OpenTypeUShort  lookaheadCoverageOffsets[lookaheadGlyphCount];  // Array of offsets to coverage tables in lookahead sequence, in glyph sequence order
    OpenTypeUShort  lookupCount;                                    // Number of ContextLookupRecords
    ContextLookupRecord lookupRecords[lookupCount];                 // Array of ContextLookupRecords, in design order
    */
};

/// <summary>
/// GSUB lookup type 7, GPOS lookup type 9
/// </summary>
struct ExtensionLookupSubtable
{
    OpenTypeUShort  format;                     // Format identifier
};

struct ExtensionLookupSubtableFormat1 : ExtensionLookupSubtable
{
    OpenTypeUShort  extensionLookupType;        // Lookup type of subtable referenced by ExtensionOffset (i.e. the extension subtable).
    OpenTypeULong   extensionOffset;            // Offset to the extension subtable, of lookup type ExtensionLookupType, relative to the start of the ExtensionSubstFormat1 subtable.
};

/// <summary>
/// GSUB lookup type 8
/// </summary>
struct ReverseChainingSubtable
{
    OpenTypeUShort  format;                     // Format identifier
    OpenTypeUShort  coverageOffset;             // Offset to Coverage table - from beginning of Substitution/Positioning table
};

/// <summary>
/// Coverage-based Reverse Chaining Contextual Single Glyph substitution.
/// </summary>
struct ReverseChainingSubtableFormat1 : ReverseChainingSubtable
{
    OpenTypeUShort  backtrackGlyphCount;                            // Number of glyphs in the backtracking sequence
    /*** The remainder of this structure is variable size, so the definition below is virtual and here for reference. ***
    OpenTypeUShort  backtrackCoverageOffsets[backtrackGlyphCount]	// Array of offsets to coverage tables in backtracking sequence, in glyph sequence order
    OpenTypeUShort  lookaheadGlyphCount;                            // Number of glyphs in lookahead sequence
    OpenTypeUShort  lookaheadCoverageOffsets[lookaheadGlyphCount];  // Array of offsets to coverage tables in lookahead sequence, in glyph sequence order
    OpenTypeUShort  glyphCount;                                     // Number of GlyphIDs in the Substitute array
    OpenTypeUShort  substituteGlyphs[glyphCount];                   // Array of substitute GlyphIDs - ordered by Coverage Index
    */
};

/// <summary>
/// GPOS lookup type 1.
/// </summary>
struct SinglePositioningSubtable
{
    OpenTypeUShort  format;                     // Format identifier
    OpenTypeUShort  coverageOffset;             // Offset to Coverage table - from beginning of SinglePos table
    OpenTypeUShort  valueFormat;                // Defines the types of data in the ValueRecord
};

/// <summary>
/// Single positioning value.
/// </summary>
struct SinglePositioningSubtableFormat1 : SinglePositioningSubtable
{
    // ValueRecord  value;                      // (variable size record) Defines positioning value(s) - applied to all glyphs in the Coverage table
};

/// <summary>
/// Array of positioning values.
/// </summary>
struct SinglePositioningSubtableFormat2 : SinglePositioningSubtable
{
    OpenTypeUShort  valueCount;                 // Number of ValueRecords
 // ValueRecord     valueRecords[ValueCount];   // (variable size records) Array of ValueRecords - positioning values applied to glyphs
};

/// <summary>
/// GPOS lookup type 2.
/// </summary>
struct PairPositioningSubtable 
{
    OpenTypeUShort  format;                     // Format identifier
    OpenTypeUShort  coverageOffset;             // Offset to Coverage table - from beginning of PairPos subtable - for the first glyph in each pair
};

/// <summary>
/// Adjustments for glyph pairs.
/// </summary>
struct PairPositioningSubtableFormat1 : PairPositioningSubtable
{
    OpenTypeUShort  valueFormat1;                   // Defines the types of data in ValueRecord1 - for the first glyph in the pair - may be zero (0)
    OpenTypeUShort  valueFormat2;                   // Defines the types of data in ValueRecord2 - for the second glyph in the pair - may be zero (0)
    OpenTypeUShort  pairSetCount;                   // Number of PairSet tables
 // OpenTypeUShort  pairSetOffsets[pairSetCount];   // Array of offsets to PairSet tables - from beginning of PairPos subtable - ordered by Coverage Index

    struct PairSet
    {
        OpenTypeUShort  pairValueCount;             // Number of PairValueRecords
     // PairValueRecord pairValueRecords[pairValueCount]; // Array of PairValueRecords - ordered by GlyphID of the second glyph
    };

    struct PairValueRecord
    {
        OpenTypeUShort  secondGlyph;                // GlyphID of second glyph in the pair - first glyph is listed in the Coverage table
        /*** These structures are variable size, so the definition below is virtual and here for reference. ***
        ValueRecord     value1;                     // Positioning data for the first glyph in the pair
        ValueRecord     value2;                     // Positioning data for the second glyph in the pair
        */
    };
};

/// <summary>
/// Class pair adjustment.
/// </summary>
struct PairPositioningSubtableFormat2 : PairPositioningSubtable
{
    OpenTypeUShort  valueFormat1;               // ValueRecord definition - for the first glyph of the pair - may be zero (0)
    OpenTypeUShort  valueFormat2;               // ValueRecord definition - for the second glyph of the pair - may be zero (0)
    OpenTypeUShort  classDef1Offset;            // Offset to ClassDef table - from beginning of PairPos subtable - for the first glyph of the pair
    OpenTypeUShort  classDef2Offset;            // Offset to ClassDef table - from beginning of PairPos subtable - for the second glyph of the pair
    OpenTypeUShort  class1Count;                // Number of classes in ClassDef1 table - includes Class0
    OpenTypeUShort  class2Count;                // Number of classes in ClassDef2 table - includes Class0
 // Class1Record    class1Records[class1Count]; // Array of Class1 records - ordered by Class1

    /*** These structures are variable size, so the definitions below are virtual and here for reference. ***
         It's essentially a 2D array (class1Count * class2Count) of ValueRecord pairs.
    struct Class1Record 
    {
        Class2Record    class2Records[class2Count]; // Array of Class2 records - ordered by Class2
    };

    struct Class2Record
    {
        ValueRecord     value1;                 // Positioning for first glyph - empty if ValueFormat1 = 0
        ValueRecord     value2;                 // Positioning for second glyph - empty if ValueFormat2 = 0
    };
    */
};

/// <summary>
/// GPOS lookup type 3.
/// </summary>
struct CursivePositioningSubtable
{
    OpenTypeUShort  format;                     // Format identifier
    OpenTypeUShort  coverageOffset;             // Offset to Coverage table - from beginning of CursivePos subtable
};

/// <summary>
/// Cursive attachment.
/// </summary>
struct CursivePositioningSubtableFormat1 : CursivePositioningSubtable
{
    OpenTypeUShort  entryExitCount;                     // Number of EntryExit records
 // EntryExitRecord entryExitRecords[entryExitCount];   // Array of EntryExit records - in Coverage Index order

    struct EntryExitRecord 
    {
        OpenTypeUShort  entryAnchorOffset;              // Offset to EntryAnchor table - from beginning of CursivePos subtable - may be NULL
        OpenTypeUShort  exitAnchorOffset;               // Offset to ExitAnchor table - from beginning of CursivePos subtable - may be NULL
    };
};

/// <summary>
/// GPOS lookup type 4.
/// </summary>
struct MarkToBasePositioningSubtable
{
    OpenTypeUShort  format;                     // Format identifier
};

/// <summary>
/// MarkToBase attachment point.
/// </summary>
struct MarkToBasePositioningSubtableFormat1 : MarkToBasePositioningSubtable
{
    OpenTypeUShort  markCoverageOffset;         // Offset to MarkCoverage table - from beginning of MarkBasePos subtable
    OpenTypeUShort  baseCoverageOffset;         // Offset to BaseCoverage table - from beginning of MarkBasePos subtable
    OpenTypeUShort  classCount;                 // Number of classes defined for marks
    OpenTypeUShort  markArrayOffset;            // Offset to MarkArray table - from beginning of MarkBasePos subtable
    OpenTypeUShort  baseArrayOffset;            // Offset to BaseArray table - from beginning of MarkBasePos subtable

    struct BaseArray
    {
        OpenTypeUShort  baseCount;              // Number of BaseRecords
     // BaseRecord      baseRecords[baseCount]; // Array of BaseRecords - in order of BaseCoverage Index
    };

    /*** This structure is variable size, so the definition below is virtual and here for reference. ***
    struct BaseRecord 
    {
        // Array of offsets (one per class) to Anchor tables - from beginning of BaseArray table - ordered by class-zero-based
        OpenTypeUShort  baseAnchorOffsets[classCount];
    };
    */
};

/// <summary>
/// GPOS lookup type 5.
/// </summary>
struct MarkToLigaturePositioningSubtable
{
    OpenTypeUShort  format;                     // Format identifier
};

/// <summary>
/// MarkToLigature attachment.
/// </summary>
struct MarkToLigaturePositioningSubtableFormat1 : MarkToLigaturePositioningSubtable
{
    OpenTypeUShort  markCoverageOffset;	        // Offset to Mark Coverage table - from beginning of MarkLigPos subtable
    OpenTypeUShort  ligatureCoverageOffset;     // Offset to Ligature Coverage table - from beginning of MarkLigPos subtable
    OpenTypeUShort  classCount;                 // Number of defined mark classes
    OpenTypeUShort  markArrayOffset;            // Offset to MarkArray table - from beginning of MarkLigPos subtable
    OpenTypeUShort  ligatureArrayOffset;        // Offset to LigatureArray table - from beginning of MarkLigPos subtable

    struct LigatureArray
    {
        OpenTypeUShort  ligatureCount;          // Number of LigatureAttach table offsets
     // OpenTypeUShort  ligatureAttachOffsets[ligatureCount]; // Array of offsets to LigatureAttach tables - from beginning of LigatureArray table - ordered by LigatureCoverage Index
    };

    struct LigatureAttach
    {
        OpenTypeUShort  componentCount;         // Number of ComponentRecords in this ligature
     // ComponentRecord componentRecords[componentCount]; // Array of Component records - ordered in writing direction
    };

    /*** This structure is variable size, so the definition below is virtual and here for reference. ***
    struct ComponentRecord 
    {
        OpenTypeUShort  ligatureAnchorOffsets[classCount];  // Array of offsets (one per class) to Anchor tables - from beginning of LigatureAttach table - ordered by class - NULL if a component does not have an attachment for a class-zero-based array
    };
    */
};

/// <summary>
/// GPOS lookup type 6.
/// </summary>
struct MarkToMarkPositioningSubtable
{
    OpenTypeUShort  format;                     // Format identifier
};

/// <summary>
/// MarkToMark attachment.
/// </summary>
struct MarkToMarkPositioningSubtableFormat1 : MarkToMarkPositioningSubtable
{
    OpenTypeUShort  mark1CoverageOffset;        // Offset to Combining Mark Coverage table - from beginning of MarkMarkPos subtable
    OpenTypeUShort  mark2CoverageOffset;        // Offset to Base Mark Coverage table - from beginning of MarkMarkPos subtable
    OpenTypeUShort  classCount;	                // Number of Combining Mark classes defined
    OpenTypeUShort  mark1ArrayOffset;	        // Offset to MarkArray table for Mark1 - from beginning of MarkMarkPos subtable
    OpenTypeUShort  mark2ArrayOffset;	        // Offset to Mark2Array table for Mark2 - from beginning of MarkMarkPos subtable

    struct Mark2Array
    {
        OpenTypeUShort  mark2Count;             // Number of Mark2 records
     // Mark2Record     mark2Records[mark2Count]; // Array of Mark2 records - in Coverage order
    };

    /*** This structure is variable size, so the definition below is virtual and here for reference. ***
    struct Mark2Record 
    {
        OpenTypeUShort  mark2AnchorOffsets[classCount]; // Array of offsets (one per class) to Anchor tables - from beginning of Mark2Array table-zero-based array
    };
    */
};

/// <summary>
/// One of an array of entries that follows the header of the 'EBLC' (Embedded Bitmap Location) 
/// table. This structure is referred to as bitmapSizeTable in the OpenType spec.
/// </summary>
struct EblcEntry
{
    OpenTypeULong   indexSubTableArrayOffset;   // offset to index subTable from beginning of EBLC. 
    OpenTypeULong   indexTablesSize;            // number of bytes in corresponding index subtables and array 
    OpenTypeULong   numberOfIndexSubTables;     // an index subTable for each range or format change 
    OpenTypeULong   colorRef;                   // not used; set to 0.

    struct LineMetrics
    {
        OpenTypeChar ascender;
        OpenTypeChar descender; 
        OpenTypeByte widthMax;
        OpenTypeChar caretSlopeNumerator;
        OpenTypeChar caretSlopeDenominator;
        OpenTypeChar caretOffset;
        OpenTypeChar minOriginSB;
        OpenTypeChar minAdvanceSB;
        OpenTypeChar maxBeforeBL;
        OpenTypeChar minAfterBL;
        OpenTypeChar pad1;
        OpenTypeChar pad2;
    };
    LineMetrics     horizontalMetrics;          // line metrics for text rendered horizontally 
    LineMetrics     verticalMetrics;            // line metrics for text rendered vertically 

    OpenTypeUShort  firstGlyphIndex;            // lowest glyph index for this size 
    OpenTypeUShort  lastGlyphIndex;             // highest glyph index for this size 
    OpenTypeByte    ppemX;                      // horizontal pixels per Em 
    OpenTypeByte    ppemY;                      // vertical pixels per Em 
    OpenTypeByte    bitDepth;                   // the Microsoft rasterizer v.1.7 or greater supports the following bitDepth values, as described below: 1, 2, 4, and 8. 
    OpenTypeChar    flags;                      // vertical or horizontal (see bitmapFlags) 
};

// Compile-time check to validate field offset against corresponding constant from WPF v1 font
// driver source. If the structure definition is incorrect this should yield a compiler error.
// The constant name from WPF v1 is specified by the line comment.
static_assert(sizeof(EblcEntry) == 48, "Structure size different than expected."); // EblcSizeOfBitmapSizeTable

// An element of the indexSubTableArray described in the 'EBLC' topic of the OpenType specification.
struct EblcIndexSubtableEntry
{
    OpenTypeUShort  firstGlyphIndex;            // first glyph index for this range
    OpenTypeUShort  lastGlyphIndex;             // last glyph index for this range (inclusive)
    OpenTypeULong   additionalOffsetToIndexSubtable; // add to indexSubTableArrayOffset to get offset from beginning of 'EBLC' 
};

// Compile-time check to validate field offset against corresponding constant from WPF v1 font
// driver source. If the structure definition is incorrect this should yield a compiler error.
// The constant name from WPF v1 is specified by the line comment.
static_assert(sizeof(EblcIndexSubtableEntry) == 8, "Structure size different than expected."); // EblcSizeOfIndexSubTable

struct EblcIndexSubtable
{
    OpenTypeUShort indexFormat;     // format of this indexSubTable 
    OpenTypeUShort imageFormat;     // format of 'EBDT' image data 
    OpenTypeULong  imageDataOffset; // offset to image data in 'EBDT' table 

    struct BigGlyphMetrics
    {
        OpenTypeByte height;
        OpenTypeByte width;
        OpenTypeChar horiBearingX;
        OpenTypeChar horiBearingY;
        OpenTypeByte horiAdvance;
        OpenTypeChar vertBearingX;
        OpenTypeChar vertBearingY;
        OpenTypeByte vertAdvance;
    };

    struct SmallGlyphMetrics
    {
        OpenTypeByte height;
        OpenTypeByte width;
        OpenTypeChar bearingX;
        OpenTypeChar bearingY;
        OpenTypeByte advance;
    };
};

/// <summary>
/// Variable metrics glyphs with 4 byte offsets.
/// </summary>
struct EblcIndexSubtable1 : EblcIndexSubtable
{
    // OpenTypeULong offsetArray[(lastGlyph-firstGlyph+1)+1+1];
};

/// <summary>
/// All glyphs have identical metrics.
/// </summary>
struct EblcIndexSubtable2 : EblcIndexSubtable
{
    OpenTypeULong   imageSize;      // all the glyphs are of the same size 
    BigGlyphMetrics bigMetrics;     // all glyphs have the same metrics; glyph data may be compressed, byte-aligned, or bit-aligned 
};

/// <summary>
/// Variable metrics glyphs with 2 byte offsets.
/// </summary>
struct EblcIndexSubtable3 : EblcIndexSubtable
{
    // OpenTypeUShort offsetArray[(lastGlyph-firstGlyph+1)+1+1];
};

/// <summary>
/// Variable metrics glyphs with sparse glyph codes.
/// </summary>
struct EblcIndexSubtable4 : EblcIndexSubtable
{
    OpenTypeULong glyphCount;       // array length

    struct CodeOffsetPair
    {
        OpenTypeUShort glyphCode;   // code of glyph present
        OpenTypeUShort offset;      // location in EBDT
    };

    // CodeOffsetPair glyphArray[glyphCount+1]; // one per glyph
};

/// <summary>
/// Constant metrics glyphs with sparse glyph codes.
/// </summary>
struct EblcIndexSubtable5 : EblcIndexSubtable
{
    OpenTypeULong   imageSize;      // all glyphs have the same data size 
    BigGlyphMetrics bigMetrics;     // all glyphs have the same metrics 
    OpenTypeULong   glyphCount;     // array length 
    // OpenTypeUShort glyphCodeArray[glyphCount] // one per glyph, sorted by glyph code
};

/// <summary>
/// Header portion of the OpenType 'name' table (Naming Table).
/// </summary>
struct NamingTable
{
    OpenTypeUShort  format;         // format selector (=0)
    OpenTypeUShort  count;          // number of name records (NameRecord structures)
    OpenTypeUShort  stringOffset;   // offset to start of string storage (from start of table)
};


/// <summary>
/// One of an array of entries that follows the NamingTable structure; each NameRecord
/// describes a string in the OpenType 'name' table (Naming Table).
/// </summary>
struct NameRecord
{
    OpenTypeUShort  platformID;     // platform ID
    OpenTypeUShort  encodingID;     // platform-specific encoding ID
    OpenTypeUShort  languageID;     // language ID
    OpenTypeUShort  nameID;         // name ID
    OpenTypeUShort  length;         // string length (in bytes)
    OpenTypeUShort  offset;         // string offset from start of storage area (in bytes)
};


/// <summary>
/// Structure at start of CMAP table.
/// </summary>
struct CmapHeader
{
    OpenTypeUShort  version;
    OpenTypeUShort  numTables;
};


/// <summary>
/// Element of array that immediately follows the CmapHeader.
/// </summary>
struct CmapEncodingRecord
{
    OpenTypeUShort  platformID;
    OpenTypeUShort  encodingID;
    OpenTypeULong   offset;
};

struct CmapFormat0Subtable
{
    OpenTypeUShort  format;             // format number; set to 0
    OpenTypeUShort  length;             // length of the subtable
    OpenTypeUShort  language;
    uint8_t         glyphIdArray[256];
};

/// <summary>
/// Header at the beginning of the CMAP format 2 subtable.
/// </summary>
struct CmapFormat2Header
{
    OpenTypeUShort  format;             // format number; set to 2
    OpenTypeUShort  length;             // length of the subtable
    OpenTypeUShort  language;
    OpenTypeUShort  subHeaderKeys[256]; // array that maps high bytes to subheaders
};


/// <summary>
/// Element of a variable length array that immediately follows the CmapFormat2Header.
/// </summary>
struct CmapFormat2SubHeader
{
    OpenTypeUShort  firstCode;          // first valid low byte for this subheader
    OpenTypeUShort  entryCount;         // number of code points mapped
    OpenTypeShort   idDelta;            // value added to each glyph index
    OpenTypeUShort  idRangeOffset;      // offset of glyph index sub-array
};


/// <summary>
/// Header at the beginning of the CMAP format 4 subtable.
/// </summary>
struct CmapFormat4Header
{
    OpenTypeUShort  format;             // format number; set to 4
    OpenTypeUShort  length;             // length of the subtable
    OpenTypeUShort  language;
    OpenTypeUShort  segCountX2;         // 2 x segCount
    OpenTypeUShort  searchRange;        // 2 x (2**floor(log2(segCount)))
    OpenTypeUShort  entrySelector;      // log2(searchRange/2)
    OpenTypeUShort  rangeShift;         // 2 x segCount - searchRange
    //
    // The following variable-length arrays follow the header:
    //
    //   OpenTypeUShort  endCount[segCount];
    //   OpenTypeHShort  reservedPad;
    //   OpenTypeUShort  startCount[segCount];
    //   OpenTypeShort   idDelta[segCount];
    //   OpenTypeUShort  glyphIndexArray[];   
};


/// <summary>
/// Header at the beginning of the CMAP format 6 subtable.
/// </summary>
struct CmapFormat6Header
{
    OpenTypeUShort  format;             // format number; set to 4
    OpenTypeUShort  length;             // length of the subtable
    OpenTypeUShort  language;
    OpenTypeUShort  firstCode;          // first character code of the subrange
    OpenTypeUShort  entryCount;         // number of character codes in the subrange
    //
    // The following variable-length array follows the header:
    //
    //   OpenTypeUShort glyphIdArray[entryCount];
};


/// <summary>
/// Header at the beginning of the CMAP format 12 subtable.
/// </summary>
struct CmapFormat12Header
{
    OpenTypeUShort  format;             // format number; set to 4
    OpenTypeUShort  reserved;
    OpenTypeULong   length;             // length of the subtable
    OpenTypeULong   language;
    OpenTypeULong   nGroups;            // number of groups which follow
};

struct CmapFormat12Group
{
    OpenTypeULong   startCharCode;
    OpenTypeULong   endCharCode;
    OpenTypeULong   startGlyphID;
};


/// <summary>
/// CMAP format 14 data types
///
struct CmapFormat14Header
{
    OpenTypeUShort  format;
    OpenTypeULong   length;
    OpenTypeULong   numVarSelectorRecords;
};

struct CmapFormat14VariationSelectorRecord
{
    OpenTypeByte    selector[3];
    OpenTypeULong   defaultUVSOffset;
    OpenTypeULong   nonDefaultUVSOffset;
};

struct CmapFormat14NonDefaultUvsHeader
{
    OpenTypeULong   numUvsMappings;
};

struct CmapFormat14UvsMapping
{
    OpenTypeByte    unicodeValue[3];
    OpenTypeUShort  glyphIndex;
};


/// <summary>
/// Header for a glyph in the glyf table. The offset of each glyph's header is
/// specified by the loca table. The bounding box coordinates are in design units 
/// where the positive Y direction is up and the baseline is at Y=0.
/// </summary>
struct GlyphHeader
{
    OpenTypeShort   numberOfContours;
    OpenTypeShort   xMin;   // left of black box
    OpenTypeShort   yMin;   // bottom of black box (positive Y is up)
    OpenTypeShort   xMax;   // right of black box
    OpenTypeShort   yMax;   // top of black box (positive Y is up)

    //  If numberOfContours >= 0
    //      uint16be    endPointsOfContours[numberOfContours];
    //      uint16be    instructionLength;
    //      uint8       instructions[instructionLength];
    //      uint8       flags[<=pointCount];    // where pointCount = endPointsOfContours[numberOfContours-1] + 1
    //      variable    xCoordinates[];         // depends on flags which sets 1 or 2 bytes and may repeat coordinates
    //      variable    yCoordinates[];         // depends on flags which sets 1 or 2 bytes and may repeat coordinates
    //  Elif numberOfContours == -1
    //      Do
    //          uint16be    flags;
    //          uint16be    glyphId;
    //          variable    arguments;  // length depends on flags
    //          variable    transforms; // length depends on flags
    //      While flags say more components
    //      If flags say instructions
    //          uint16be    instructionLength;
    //          uint8       instructions[instructionLength];
    //      Endif
    //  Endif
    //
    // http://www.microsoft.com/typography/otspec/glyf.htm

    struct CompositeGlyph
    {
        OpenTypeUShort flags;
        OpenTypeUShort glyphId;

        // Present if flags and CompositeFlagsHasScale
        struct Scale
        {
            OpenTypeShort scale; // Fixed precision format 2.14
        };

        // Present if flags and CompositeFlagsHasXYScale
        struct ScaleXY
        {
            OpenTypeShort x; // Fixed precision format 2.14
            OpenTypeShort y; // Fixed precision format 2.14
        };

        // Present if flags and FlagsHas2x2
        struct Scale2x2
        {
            OpenTypeShort xx; // x affects x (horizontal scaling / cosine of rotation)          Fixed precision format 2.14
            OpenTypeShort xy; // x affects y (vertical shear     / sine of rotation)            Fixed precision format 2.14
            OpenTypeShort yx; // y affects x (horizontal shear   / negative sine of rotation)   Fixed precision format 2.14
            OpenTypeShort yy; // y affects y (vertical scaling   / cosine of rotation)          Fixed precision format 2.14
        };

        enum Flags
        {
            FlagsArgumentsAreWords          = 1 << 0,  // If this is set, the arguments are words; otherwise, they are bytes.
            FlagsArgumentsAreXYValues       = 1 << 1,  // If this is set, the arguments are xy values; otherwise, they are points.
            FlagsRoundXYToGrid              = 1 << 2,  // For the xy values if the preceding is true.
            FlagsHasScale                   = 1 << 3,  // This indicates that there is a simple scale for the component. Otherwise, scale = 1.0.
            FlagsReserved                   = 1 << 4,  // This bit is reserved. Set it to 0.
            FlagsHasMoreComponents          = 1 << 5,  // Indicates at least one more glyph after this one.
            FlagsHasXYScale                 = 1 << 6,  // The x direction will use a different scale from the y direction.
            FlagsHas2x2                     = 1 << 7,  // There is a 2 by 2 transformation that will be used to scale the component.
            FlagsHasInstructions            = 1 << 8,  // Following the last component are instructions for the composite character.
            FlagsUseMetrics                 = 1 << 9,  // If set, this forces the aw and lsb (and rsb) for the composite to be equal to those from this original glyph. This works for hinted and unhinted characters.
            FlagsOverlapCompound            = 1 << 10, // Used by Apple in GX fonts.
            FlagsScaledComponentOffset      = 1 << 11, // Composite designed to have the component offset scaled (designed for Apple rasterizer).
            FlagsUnscaledComponentOffsets   = 1 << 12, // Composite designed not to have the component offset scaled (designed for the Microsoft TrueType rasterizer).
        };
    };
};


/// <summary>
/// PCLT (PCL 5) table.
/// </summary>
struct PcltTable
{
    OpenTypeFixed   version;
    OpenTypeULong   fontNumber;
    OpenTypeUShort  pitch;
    OpenTypeUShort  xHeight;
    OpenTypeUShort  style;
    OpenTypeUShort  typeFamily;
    OpenTypeUShort  capHeight;
    // additional unused fields omitted
};


/// <summary>
/// Header for the hdmx (horizontal device metrics) table.
/// </summary>
struct HdmxHeader
{
    OpenTypeUShort  version;
    OpenTypeShort   numRecords;
    OpenTypeLong    sizeDeviceRecord;
    // HdmxEntry[numRecords]
};
static_assert(sizeof(HdmxHeader) == 8, "Structure size different than expected.");

struct HdmxEntry
{
    OpenTypeByte    pixelSize;
    OpenTypeByte    maxWidth;
    // OpenTypeByte    widths[numGlyphs];
};
static_assert(sizeof(HdmxEntry) == 2, "Structure size different than expected.");


/// <summary>
/// Linear threshold (LTSH) table
/// </summary>
struct LtshTable
{
    OpenTypeUShort  version;
    OpenTypeUShort  numGlyphs;  // should match maxp::numGlyphs
 // OpenTypeByte    yPels[numGlyphs];
};
static_assert(sizeof(LtshTable) == 4, "Structure size different than expected.");


/// <summary>
/// Header for the VDMX (vertical device metrics) table.
/// </summary>
struct VdmxHeader
{
    OpenTypeUShort  version;
    OpenTypeUShort  numRecs;
    OpenTypeUShort  numRatios;
    //
    // The following variable-length arrays follow the header:
    //
    //      VmdxRatio       ratRange[numRatios];
    //      OpenTypeUShort  offset[numRatios];
    //
    // Each offset is the byte offset from the start of the table to a VdmxGroup structure.
};

struct VdmxRatio
{
    OpenTypeByte    bCharSet;
    OpenTypeByte    xRatio;
    OpenTypeByte    yStartRatio;
    OpenTypeByte    yEndRatio;
};

struct VdmxGroup
{
    OpenTypeUShort  recs;       // number of height records in this group
    OpenTypeByte    startsz;    // starting yPelHeight
    OpenTypeByte    endsz;      // ending yPelHeight
    //
    // The following variable-length array follows the header:
    //
    //      VdmxTableRecord entry[recs];
};

struct VdmxTableRecord
{
    OpenTypeUShort  yPelHeight;
    OpenTypeShort   yMax;
    OpenTypeShort   yMin;
};

struct KernHeader
{
    OpenTypeUShort  version;
    OpenTypeUShort  tableCount;

    /*** The remainder of this structure is variable size, so the definition below is virtual and here for reference. ***/
    // KernSubtable  kernSubtables[tableCount]
};

struct KernSubtable
{
    OpenTypeUShort  version;
    OpenTypeUShort  byteLength;                 // including this header
    OpenTypeByte    format;                     // format of the subtable
    OpenTypeByte    coverage;                   // what type of information is in this header

    enum CoverageFlags
    {
        CoverageFlagsHorizontal     = 0x01,     // Contains horizontal data, 0 if vertical
        CoverageFlagsMinimum        = 0x02,     // The table has minimum values, 0 if kerning values
        CoverageFlagsCrossStream    = 0x04,     // Kerning is perpendicular to the flow of the text
        CoverageFlagsOverride       = 0x08,     // Replaces value currently being accumulated
        CoverageFlagsReserved1      = 0xF0,     // Zeroed
        // Notice bits 8-15 in the OT spec are actually the format,
        // which is defined as a separate field here for clarity.
    };
};

/// <summary>
/// Adjustments for glyph pairs.
/// </summary>
struct KernSubtable0 : KernSubtable
{
    OpenTypeUShort  pairCount;
    OpenTypeUShort  searchRange;
    OpenTypeUShort  entrySelector;
    OpenTypeUShort  rangeShift;

    struct KerningPair
    {
        OpenTypeUShort  firstGlyph;             // The left one in LTR
        OpenTypeUShort  secondGlyph;            // The right one in LTR
        OpenTypeShort   value;                  // Adjustment between them (> 0 further, < 0 closer)
    };

 // KerningPair kerningPairs[pairCount];        // Array of kerning pairs
};

/// <summary>
/// Header portion of the 'BASE' table.
/// </summary>
struct BaseHeader
{
    OpenTypeULong   version;                    // Version of the BASE table - initially 0x00010000
    OpenTypeUShort  horizontalAxisOffset;       // Offset to horizontal Axis table from beginning of BASE table - may be NULL
    OpenTypeUShort  verticalAxisOffset;         // Offset to vertical Axis table from beginning of BASE table - may be NULL
};

struct BaseAxisTable
{
    OpenTypeUShort  baseTagListOffset;          // Offset to BaseTagList table from beginning of Axis table - may be NULL
    OpenTypeUShort  scriptListOffset;           // Offset to ScriptList table from beginning of Axis table
};

struct BaseTagList
{
    OpenTypeUShort  baseTagCount;               // Number of baseline identification tags in this text direction - may be zero (0) 
 // OpenTypeTag     tags[baseTagCount]         // Array of 4-byte baseline identification tags-must be in alphabetical order 
};

struct BaseScript
{
    OpenTypeUShort  baseValuesOffset;           // Offset to BaseValues table from beginning of BaseScript table - may be NULL 
    OpenTypeUShort  defaultMinMaxOffset;        // Offset to MinMax table from beginning of BaseScript table - may be NULL 
    OpenTypeUShort  languageCount;              // Number of language records defined - may be zero (0) 
 // LanguageRecord  languageRecords[languageCount]; // Array of language records - in alphabetical order by tag. The offset in the language record points to a MinMax
};

struct BaseValues
{
    OpenTypeUShort  defaultIndex;               // Index number of default baseline for this script - equals index position of baseline tag in BaselineArray of the BaseTagList 
    OpenTypeUShort  baseCoordinateCount;        // Number of base coordinate tables defined - should equal BaseTagCount in the BaseTagList 
 // OpenTypeUShort  baseCoordinateOffsets[BaseCoordCount]; // Array of offsets to BaseCoord from beginning of BaseValues table - order matches BaselineTag array in the BaseTagList 
};

struct BaseMinMax
{
    OpenTypeUShort minCoordinateOffset;         // Offset to BaseCoord table - defines minimum extent value from the beginning of MinMax table - may be NULL
    OpenTypeUShort maxCoordinateOffset;         // Offset to BaseCoord table - defines maximum extent value from the beginning of MinMax table - may be NULL 
    OpenTypeUShort featureMinMaxCount;          // Number of FeatMinMaxRecords - may be zero (0) 
 // FeatureMinMaxRecord featureMinMaxRecords[featureMinMaxCount] // Array of FeatMinMaxRecords in alphabetical order, by FeatureTableTag 
};

struct FeatMinMaxRecord
{
    OpenTypeTag    tag;                         // 4-byte feature identification tag - must match FeatureTag in FeatureList 
    OpenTypeUShort minCoordinateOffset;         // Offset to BaseCoord table - defines minimum extent value from beginning of MinMax table - may be NULL 
    OpenTypeUShort maxCoordinateOffset;         // Offset to BaseCoord table - defines maximum extent value from beginning of MinMax table - may be NULL 
};

struct BaseCoordinate
{
    OpenTypeUShort format;
};

struct BaseCoordinateFormat1 : BaseCoordinate
{
    OpenTypeShort  coordinate;                  // X or Y value, in design units 
};

struct BaseCoordinateFormat2 : BaseCoordinate
{
    OpenTypeShort  coordinate;                  // X or Y value, in design units 
    OpenTypeUShort referenceGlyphId;            // Glyph ID of control glyph 
    OpenTypeUShort baseCoordinatePoint;         // Index of contour point on the reference glyph
};

struct BaseCoordinateFormat3 : BaseCoordinate
{
    OpenTypeShort coordinate;                   // X or Y value, in design units 
    OpenTypeUShort deviceTableOffset;           // Offset to Device table for X or Y value 
};

struct ClassDef
{
    OpenTypeUShort  format;                     // Format identifier
};

struct ClassDefFormat1 : ClassDef
{
    OpenTypeUShort startGlyph;                  // First GlyphID of the classValues
    OpenTypeUShort glyphCount;                  // Size of the classValues
 // OpenTypeUShort classValueArray[glyphCount];  // Array of Class Values-one per GlyphID
};

struct ClassDefFormat2 : ClassDef
{
    struct RangeRecord
    {
        OpenTypeUShort firstGlyphID;            // first glyph ID in range
        OpenTypeUShort lastGlyphID;             // last glyph ID in range (inclusive)
        OpenTypeUShort classID;                 // class assigned to all glyphs in range
    };

    OpenTypeUShort rangeCount;                  // Number of rangeRecords
 // RangeRecord rangeRecords[rangeCount];    // Array of ClassRangeRecords-ordered by Start GlyphID
};

struct MergHeader
{
    OpenTypeUShort version;                     // version number of the MERG table (initially zero)
    OpenTypeUShort mergeClassCount;
    OpenTypeUShort mergeTableOffset;            // offset to 2D array of MergEntry of size mergeClassCount^2
    OpenTypeUShort classDefCount;
    OpenTypeUShort classDefTableOffsets;        // offset to an array of offsets to class definition records 
};                                              // (ClassDefFormat1 and/or ClassDefFormat2)

struct MergEntry
{
    uint8_t value;

    static uint8_t const FlagMergeLTR       = 0x01;
    static uint8_t const FlagGroupLTR       = 0x02;
    static uint8_t const FlagSubordinateLTR = 0x04;

    static uint8_t const FlagMergeRTL       = 0x10;
    static uint8_t const FlagGroupRTL       = 0x20;
    static uint8_t const FlagSubordinateRTL = 0x40;

    static uint8_t const MaskMerge          = FlagMergeLTR | FlagMergeRTL;
    static uint8_t const MaskGroup          = FlagGroupLTR | FlagGroupRTL;
    static uint8_t const MaskMergeOrGroup   = MaskMerge | MaskGroup;
    static uint8_t const MaskSubordinate    = FlagSubordinateLTR | FlagSubordinateRTL;

    static uint8_t const MaskLTR = FlagMergeLTR | FlagGroupLTR | FlagSubordinateLTR;
    static uint8_t const MaskRTL = FlagMergeRTL | FlagGroupRTL | FlagSubordinateRTL;
};

static_assert(sizeof(MergEntry) == 1, "Entry size must be uint8.");

struct ColrHeader
{
    OpenTypeUShort version;
    OpenTypeUShort numBaseGlyphRecords;
    OpenTypeULong  offsetBaseGlyphRecord;
    OpenTypeULong  offsetLayerRecord;
    OpenTypeUShort numLayerRecords;
};

struct ColrBaseGlyphRecord
{
    OpenTypeUShort baseGlyphID;
    OpenTypeUShort firstLayerIndex;
    OpenTypeUShort layerCount;
};

struct ColrLayerRecord
{
    OpenTypeUShort replacementGlyphID;
    OpenTypeUShort paletteIndex;
};

struct CpalHeader
{
    struct ColorRecord
    {
        OpenTypeByte b, g, r, a;
    };

    OpenTypeUShort version;
    OpenTypeUShort paletteEntryCount;           // number of palette entries in each palette
    OpenTypeUShort paletteCount;                // number of palettes in the table
    OpenTypeUShort colorRecordCount;            // total size of the combined array of ColorRecord
    OpenTypeULong  colorRecordsOffset;          // offset of the combined array of ColorRecord
    OpenTypeUShort colorRecordStartIndices[1];  // index of each palette's first ColorRecord
};

// todo: move into ToolOpenType
struct MetaTableHeader
{
    OpenTypeULong version;          // The version of the table format, currently 1
    OpenTypeULong flags;            // Flags, currently unused and set to 0
    OpenTypeULong dataOffset;       // Offset from the beginning of the table to the data
    OpenTypeULong dataMapsCount;    // The number of data maps in the table

    // MetaTableRecord dataMaps[numDataMaps]
    // OpenTypeByte tableData @dataOffset;
};

struct MetaTableRecord
{
    OpenTypeTag   tag;              // A tag indicating the type of metadata
    OpenTypeULong dataOffset;       // Offset from the beginning of the data section to the data for this tag
    OpenTypeULong dataLength;       // Length of the data. The data is not required to be padded to any byte boundary
};

#pragma pack( pop )
