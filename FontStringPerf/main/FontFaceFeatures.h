//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  File:       FontFaceFeatures.h
//
//  Contents:   Necessary functionality for checking font face features
//              for complex lookups.
//
//  Author:     Dwayne Robinson (dwayner@microsoft.com)
//
//  History:    2008-09-15   dwayner    Created
//              2002-03-23   sergeym    Original WPF source
//
//----------------------------------------------------------------------------
#pragma once


class FontCheckedPtr : public CheckedPtr<uint8_t const, CheckedPtrException, uint32_t>
{
public:
    typedef CheckedPtr<uint8_t const, CheckedPtrException, uint32_t> Base;

    explicit FontCheckedPtr()
    { }

    explicit FontCheckedPtr(const void* tableData, uint32_t tableSize)
        :   Base(reinterpret_cast<const uint8_t*>(tableData), tableSize)
    { }
};


class FontTablePtr : public FontCheckedPtr
{
public:
    typedef FontCheckedPtr Base;
    typedef FontTablePtr Self;

    explicit FontTablePtr(
        IDWriteFontFace* fontFace,
        uint32_t openTypeTableTag
        );
        
    ~FontTablePtr();

protected:
    ComPtr<IDWriteFontFace> fontFace_;
    void* tableContext_;

private:
    Self(Self const&);
    Self& operator=(Self const&);
};


struct GlyphCoverageRange
{
    uint16_t first;
    uint16_t count;

    bool operator < (const GlyphCoverageRange& other) const
    {
        return first < other.first || (first == other.first && count < other.count);
    }
    bool operator == (const GlyphCoverageRange& other) const
    {
        return first == other.first && count == other.count;
    }
};


struct FontTableTree;


enum ReadFontTableOptions
{
    ReadFontTableOptionsDefault         = 0x00000000,
    ReadFontTableOptionsLookupCoverage  = 0x00000001,
};


void DetermineSimpleGlyphsFromTable(
    FontCheckedPtr const& table,
    uint32_t tableTag,
    __in_ecount(desiredFeaturesCount) uint32_t const* desiredFeatures,
    size_t desiredFeaturesCount,
    uint16_t minGlyphId,
    uint16_t maxGlyphId,
    size_t glyphBitsSize,
    __in_ecount(glyphBitsSize) uint32_t const* interestedGlyphBits,
    __inout_ecount(glyphBitsSize) uint32_t* simpleGlyphBits
    );

bool ReadFontTable(
    FontCheckedPtr const& table,
    uint32_t tableTag,
    __inout FontTableTree& tree,
    uint32_t tableRootIndex,
    ReadFontTableOptions options = ReadFontTableOptionsDefault
    );

void ReadFontFile(
    IDWriteFontFace* fontFace,
    __inout FontTableTree& tree,
    uint32_t fontRootIndex
    );

void MarkMatchingFontFeaturesAsApplicable(
    __in_ecount(desiredFeaturesCount) uint32_t const* desiredFeatures,
    size_t desiredFeaturesCount,
    __inout FontTableTree& tree
    );

void MarkCoveredFontLookups(
    FontTableTree& tree,
    uint32_t treeRootIndex,
    FontCheckedPtr const& table,
    uint32_t tableTag,
    uint16_t minGlyphId,
    uint16_t maxGlyphId,
    size_t glyphBitsSize,
    __in_ecount(glyphBitsSize) uint32_t const* interestedGlyphBits,
    __inout_ecount(glyphBitsSize) uint32_t* simpleGlyphBits
    );

bool ReadGlyphCoverage(
    IDWriteFontFace* fontFace,
    __out std::vector<uint32_t>& interestedGlyphBits,
    __out std::vector<uint32_t>& unaffectedGlyphBits,
    __in_ecount(utf32textLength) char32_t const* utf32text,
    __in uint32_t utf32textLength
    );
