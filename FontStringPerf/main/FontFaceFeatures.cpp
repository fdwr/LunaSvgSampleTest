//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  File:       FontFaceFeatures.cpp
//
//  Contents:   Necessary functionality for checking font face features
//              for complex lookups.
//
//  Author:     Dwayne Robinson (dwayner@microsoft.com)
//
//  History:    2012-09-12  dwayner     Adapted to FontStringPerf tool
//              2008-09-15  dwayner     Created from adapted WPF sources
//              2002-03-23  sergeym     Original WPF shaping source
//
//----------------------------------------------------------------------------
#include "precomp.h"


FontTablePtr::FontTablePtr(
    IDWriteFontFace* fontFace,
    uint32_t openTypeTableTag
    )
    :   tableContext_(nullptr)
{
    if (fontFace == nullptr)
        return;

    const void* tableData;
    uint32_t tableSize;
    BOOL exists = false;

    fontFace->TryGetFontTable(
        openTypeTableTag,
        &tableData,
        OUT &tableSize,
        OUT &tableContext_,
        OUT &exists
        );

    if (exists)
    {
        *static_cast<Base*>(this) = Base(tableData, tableSize);
        fontFace_ = fontFace;
    }
}


FontTablePtr::~FontTablePtr()
{
    if (fontFace_ != nullptr)
    {
        fontFace_->ReleaseFontTable(tableContext_);
    }
}


// These intermediate helpers improve the readability of the parsing code,
// since the tables in GSUB and GPOS are very nested, with many structures
// being defined relative to previous ones. This is an alternative to having
// the calling code keep track of multiple offsets using local variables and
// doing all the calculations itself.
struct FontTableHelper
{
    // Reference to the checked table pointer
    FontCheckedPtr const& table;

    // Offset of this data structure in the font table
    uint32_t const tableOffset;

    // Initializes a helper class from a whole table (like GSUB or GPOS)
    inline FontTableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset = 0) throw()
    :   table(initialTable),
        tableOffset(initialOffset)
    { }
};


struct GxxxHeaderHelper : FontTableHelper
{
    // Since both the GSUB and GPOS tables have the exact same header, and
    // even the exact same script/language/feature structures, this code
    // works for both.
    static_assert(sizeof(GsubHeader) == sizeof(GposHeader), "Both GSUB and GPOS header sizes should be the same");

    GsubHeader const& fontData;

    GxxxHeaderHelper(FontCheckedPtr const& initialTable)
    :   FontTableHelper(initialTable, 0),
        fontData(initialTable.ReadAt<GsubHeader>(0))
    { }
};


struct ScriptListHelper : FontTableHelper
{
    uint32_t const scriptCount;
    _Field_size_(scriptCount) ScriptRecord const* const scripts;

    ScriptListHelper(GxxxHeaderHelper const& parent)
    :   FontTableHelper(parent.table, parent.fontData.scriptListOffset),
        scriptCount(table.ReadAt<ScriptList>(tableOffset).scriptCount),
        scripts(table.ReadArrayAt<ScriptRecord>(tableOffset + sizeof(ScriptList), scriptCount))
    { }

    inline uint32_t GetLanguageListOffset(uint32_t scriptIndex) const throw()
    {
        INPUT_ASSERT_FAIL_MSG(scripts[scriptIndex].offset != 0);
        return tableOffset + scripts[scriptIndex].offset;
    }
};


struct LanguageListHelper : FontTableHelper
{
    LanguageList const& fontData;
    uint32_t const languageCount;
    _Field_size_(languageCount) LanguageRecord const* const languages;

    LanguageListHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<LanguageList>(tableOffset)),
        languageCount(fontData.languageCount),
        languages(table.ReadArrayAt<LanguageRecord>(tableOffset + sizeof(LanguageList), languageCount))
    { }

    inline uint32_t GetLanguageFeatureListOffset(uint32_t languageIndex) const throw()
    {
        uint32_t featureListOffset = languages[languageIndex].offset;
        INPUT_ASSERT_FAIL_MSG(featureListOffset != 0);
        return tableOffset + featureListOffset;
    }
};


struct LanguageFeatureListHelper : FontTableHelper
{
    LanguageFeatureList const& fontData;
    uint32_t const featureCount;
    _Field_size_(featureCount) OpenTypeUShort const* const featureIndices;

    LanguageFeatureListHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<LanguageFeatureList>(tableOffset)),
        featureCount(fontData.featureCount),
        featureIndices(table.ReadArrayAt<OpenTypeUShort>(tableOffset + sizeof(LanguageFeatureList), featureCount))
    { }
};


struct FeatureListHelper : FontTableHelper
{
    uint32_t const featureCount;
    _Field_size_(featureCount) FeatureRecord const* const features;

    FeatureListHelper(GxxxHeaderHelper const& parent)
    :   FontTableHelper(parent.table, parent.fontData.featureListOffset),
        featureCount(table.ReadAt<FeatureList>(tableOffset).featureCount),
        features(table.ReadArrayAt<FeatureRecord>(tableOffset + sizeof(FeatureList), featureCount))
    { }

    inline uint32_t GetFeatureLookupListOffset(uint32_t featureIndex) const throw()
    {
        INPUT_ASSERT_FAIL_MSG(features[featureIndex].offset != 0);
        return tableOffset + features[featureIndex].offset;
    }
};


struct FeatureLookupListHelper : FontTableHelper
{
    uint32_t const lookupCount;
    _Field_size_(lookupCount) OpenTypeUShort const* const lookupIndices;

    FeatureLookupListHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        lookupCount(table.ReadAt<FeatureLookupList>(tableOffset).lookupCount),
        lookupIndices(table.ReadArrayAt<OpenTypeUShort>(tableOffset + sizeof(FeatureLookupList), lookupCount))
    { }
};


struct LookupListHelper : FontTableHelper
{
    uint32_t const lookupCount;
    _Field_size_(lookupCount) OpenTypeUShort const* const lookupOffsets;

    LookupListHelper(GxxxHeaderHelper const& parent)
    :   FontTableHelper(parent.table, parent.fontData.lookupListOffset),
        lookupCount(table.ReadAt<LookupList>(tableOffset).lookupCount),
        lookupOffsets(table.ReadArrayAt<OpenTypeUShort>(tableOffset + sizeof(LookupList), lookupCount))
    { }

    inline uint32_t GetLookupTableListOffset(uint32_t index) const throw()
    {
        INPUT_ASSERT_FAIL_MSG(lookupOffsets[index] != 0);
        return tableOffset + lookupOffsets[index];
    }
};

struct LookupTableListHelper : FontTableHelper
{
    LookupTableList const& fontData;
    uint32_t const subtableCount;
    _Field_size_(subtableCount) OpenTypeUShort const* const subtableOffsets;
    LookupTableList::Type const lookupType; // enumeration of GSUB or GPOS lookup types
    uint16_t const flag;

    LookupTableListHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<LookupTableList>(tableOffset)),
        subtableCount(fontData.subtableCount),
        subtableOffsets(table.ReadArrayAt<OpenTypeUShort>(tableOffset + sizeof(LookupTableList), subtableCount)),
        lookupType(LookupTableList::Type(uint32_t(fontData.lookupType))),
        flag(fontData.lookupFlag)
    { }

    inline uint32_t GetSubtableOffset(uint32_t index) const throw()
    {
        INPUT_ASSERT_FAIL_MSG(subtableOffsets[index] != 0);
        return tableOffset + subtableOffsets[index];
    }
};


struct CoverageTableHelper : FontTableHelper
{
    uint32_t const format;

    CoverageTableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        format(table.ReadAt<CoverageTable>(tableOffset).format)
    { }

    struct Format1Helper
    {
        uint32_t glyphCount;
        _Field_size_(glyphCount) OpenTypeUShort const* glyphs;

        Format1Helper() // overload for lazy reading
        :   glyphCount(),
            glyphs()
        { }

        Format1Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        {
            Initialize(initialTable, initialOffset);
        }

        Format1Helper(uint32_t initialGlyphCount, _In_reads_(initialGlyphCount) OpenTypeUShort const* initialGlyphs)
        {
            Initialize(initialGlyphCount, initialGlyphs);
        }

        void Initialize(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        {
            glyphCount = initialTable.ReadAt<CoverageTableFormat1>(initialOffset).glyphCount;
            glyphs = initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(CoverageTableFormat1), glyphCount);
        }

        void InitializeExcludingLastGlyph(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        {
            // Some lookups keep the first glyph in the coverage table and 
            // store subsequent glyphs of the series from the second glyph
            // onward. However, the count they store includes the first
            // glyph while the actual array contains one less, such as the
            // GlyphChainingSubtable::ChainRule::input array.

            glyphCount = initialTable.ReadAt<CoverageTableFormat1>(initialOffset).glyphCount;

            if (glyphCount == 0)
            {
                INPUT_ASSERT_FAIL_MSG("Coverage table entry contains a zero count.");
            }
            else
            {
                --glyphCount;
            }

            glyphs = initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(CoverageTableFormat1), glyphCount);
        }

        void Initialize(uint32_t initialGlyphCount, _In_reads_(initialGlyphCount) OpenTypeUShort const* initialGlyphs)
        {
            this->glyphCount = initialGlyphCount;
            this->glyphs = initialGlyphs;
        }

        uint32_t GetByteSize() const
        {
            return sizeof(CoverageTableFormat1) + glyphCount * sizeof(glyphs[0]);
        }

        void ReadLookupCoverage( // return the number of ranges
            _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
            ) const
        {
            const size_t oldCoverageRangesSize = coverageRanges.size();
            coverageRanges.resize(oldCoverageRangesSize + this->glyphCount);

            for (uint32_t i = 0; i < this->glyphCount; i++)
            {
                uint16_t glyphId  = this->glyphs[i];
                auto& outputRange = coverageRanges[oldCoverageRangesSize + i];
                outputRange.first = glyphId;
                outputRange.count = 1;
            }
        }
    };

    struct Format2Helper
    {
        uint32_t rangeCount;
        _Field_size_(rangeCount) CoverageRangeRecord const* ranges;

        Format2Helper() // overload for lazy reading
        :   rangeCount(),
            ranges()
        { }

        Format2Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        {
            Initialize(initialTable, initialOffset);
        }

        void Initialize(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        {
            rangeCount = initialTable.ReadAt<CoverageTableFormat2>(initialOffset).rangeCount;
            ranges = initialTable.ReadArrayAt<CoverageRangeRecord>(initialOffset + sizeof(CoverageTableFormat2), rangeCount);
        }
    };

    inline bool IsAnyGlyphCovered(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits
        ) const
    {
        return UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            nullptr
            );        
    }

    // Marks all the glyphs covered by this table as complex, returning true
    // if at least one glyph fell in the range of interest (meaning within
    // [min...max] and having a corresponding bit set in the bits of interest).
    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_opt_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        switch (this->format)
        {
        case 1: // Coverage array
            {
                Format1Helper coverage(this->table, this->tableOffset);
                if (coverage.glyphCount == 0)
                    return false;

                uint16_t firstGlyphId = coverage.glyphs[0];
                uint16_t lastGlyphId  = coverage.glyphs[coverage.glyphCount - 1];

                if (firstGlyphId > maxGlyphId || lastGlyphId < minGlyphId)
                    return false;

                bool isLookupCovered = false;
                for (uint32_t i = 0; i < coverage.glyphCount; i++)
                {
                    uint16_t glyphId = coverage.glyphs[i];

                    if (glyphId >= minGlyphId &&
                        glyphId <= maxGlyphId &&
                        TestBit(interestedGlyphBits, glyphId)
                       )
                    {
                        isLookupCovered = true;
                        if (simpleGlyphBits == nullptr)
                            return true; // early out, since only interested in result

                        ClearBit(simpleGlyphBits, glyphId);
                    }
                }

                return isLookupCovered;
            }

        case 2: // Glyph Ranges
            {
                Format2Helper coverage(this->table, this->tableOffset);
                if (coverage.rangeCount == 0)
                    return false;

                uint16_t firstGlyphId = coverage.ranges[0].firstGlyph;
                uint16_t lastGlyphId  = coverage.ranges[coverage.rangeCount - 1].lastGlyph;

                if (firstGlyphId > maxGlyphId || lastGlyphId < minGlyphId)
                    return false;

                bool isLookupCovered = false;
                for (uint32_t rangeIndex = 0; rangeIndex < coverage.rangeCount; rangeIndex++)
                {
                    uint16_t firstGlyphId = std::max(uint16_t(coverage.ranges[rangeIndex].firstGlyph), minGlyphId);
                    uint16_t lastGlyphId  = std::min(uint16_t(coverage.ranges[rangeIndex].lastGlyph),  maxGlyphId);

                    for (uint16_t glyphId = firstGlyphId; glyphId <= lastGlyphId; glyphId++)
                    {
                        if (TestBit(interestedGlyphBits, glyphId))
                        {
                            isLookupCovered = true;
                            if (simpleGlyphBits == nullptr)
                                return true; // early out, since only interested in result

                            ClearBit(simpleGlyphBits, glyphId);
                        }
                    }
                }

                return isLookupCovered;
            }

        default:
            // unknown format. Play it safe and return true.
            INPUT_ASSERT_FAIL_MSG("This is an unknown coverage format.");
            return true;
        }
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        switch (this->format)
        {
        case 1: // Coverage array
            {
                Format1Helper coverage(this->table, this->tableOffset);
                coverage.ReadLookupCoverage(/*inout*/coverageRanges);
            }
            break;

        case 2: // Glyph Ranges
            {
                Format2Helper coverage(this->table, this->tableOffset);

                const size_t oldCoverageRangesSize = coverageRanges.size();
                coverageRanges.resize(oldCoverageRangesSize + coverage.rangeCount);
                for (uint32_t i = 0; i < coverage.rangeCount; i++)
                {
                    // Copy out the next range and clamp potentially invalid
                    // input, as no font should have an inverted range [9,5].
                    // Also clamp against a range greater than 65535 [0,FFFF].
                    // This is technically legal but practically nonsense as
                    // lookup substitutions and positioning apply to specific
                    // glyphs rather than the entire glyph range, and to have
                    // such a large range, you'd need to include the .notdef
                    // glyph which doesn't belong in any lookup.

                    auto& outputRange   = coverageRanges[oldCoverageRangesSize + i];
                    uint32_t firstGlyph = coverage.ranges[i].firstGlyph;
                    uint32_t lastGlyph  = coverage.ranges[i].lastGlyph;
                    int32_t glyphCount  = lastGlyph + 1 - firstGlyph; // difference of uint16's

                    if (glyphCount <= 0)
                    {
                        glyphCount = 0;
                        INPUT_ASSERT_FAIL_MSG("Coverage record had invalid range (ignoring).");
                    }
                    else if (glyphCount > 0xFFFF)
                    {
                        glyphCount = 0xFFFF;
                        INPUT_ASSERT_FAIL_MSG("Coverage record had excessive range (clamping).");
                    }

                    outputRange.first = static_cast<uint16_t>(firstGlyph);
                    outputRange.count = static_cast<uint16_t>(glyphCount);
                }
            }
            break;

        default:
            // unknown format. Play it safe and return true.
            INPUT_ASSERT_FAIL_MSG("This is an unknown coverage format.");
            break;
        }
    }

    uint16_t GetGlyphAtIndex(uint32_t index) const
    {
        switch (this->format)
        {
        case 1: // Coverage array
            {
                Format1Helper coverage(this->table, this->tableOffset);

                if (index >= coverage.glyphCount)
                    return 0; // return null glyph

                return coverage.glyphs[index];
            }

        case 2: // Glyph Ranges
            {
                Format2Helper coverage(this->table, this->tableOffset);

                for (uint32_t rangeIndex = 0; rangeIndex < coverage.rangeCount; rangeIndex++)
                {
                    uint16_t firstGlyphId   = coverage.ranges[rangeIndex].firstGlyph;
                    uint16_t lastGlyphId    = coverage.ranges[rangeIndex].lastGlyph;
                    uint32_t glyphId        = firstGlyphId + index;
                    if (glyphId <= lastGlyphId)
                        return static_cast<uint16_t>(glyphId);

                    // Get remainder and check next range.
                    // (include extra decrement since the end is inclusive)
                    index -= (lastGlyphId + 1u);
                }
                return 0; // return null glyph
            }

        default:
            // unknown format. Return null glyph.
            INPUT_ASSERT_FAIL_MSG("This is an unknown coverage format.");
            return 0;
        }
    }

    uint32_t GetGlyphCount() const
    {
        uint32_t glyphCount = 0;

        switch (this->format)
        {
        case 1: // Coverage array
            {
                Format1Helper coverage(this->table, this->tableOffset);
                glyphCount = coverage.glyphCount;
            }
            break;

        case 2: // Glyph Ranges
            {
                Format2Helper coverage(this->table, this->tableOffset);

                // Tally all the glyphs of all the ranges.
                for (uint32_t rangeIndex = 0; rangeIndex < coverage.rangeCount; rangeIndex++)
                {
                    uint32_t firstGlyph = coverage.ranges[rangeIndex].firstGlyph;
                    uint32_t lastGlyph  = coverage.ranges[rangeIndex].lastGlyph; // the last, not the one-past like STL

                    if (lastGlyph >= firstGlyph)
                    {
                        glyphCount += (lastGlyph - firstGlyph + 1);
                    }
                    else
                    {
                        INPUT_ASSERT_FAIL_MSG("Coverage record had invalid range (ignoring).");
                    }
                }
            }
            break;

        default:
            // unknown format. Play it safe and return 0 glyphs.
            INPUT_ASSERT_FAIL_MSG("This is an unknown coverage format.");
        }

        return glyphCount;
    }
};


struct CoverageTableIterator : CoverageTableHelper
{
    // Both format instances exist, but only one or the other is lazily used, depending on the format.
    Format1Helper coverage1;
    Format2Helper coverage2;

    // Current range and offset within subrange.
    uint32_t rangeIndex;
    uint32_t rangeSubindex;

    CoverageTableIterator(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   CoverageTableHelper(initialTable, initialOffset),
        rangeIndex(),
        rangeSubindex()
    {
        switch (this->format)
        {
        case 1:
            coverage1.Initialize(initialTable, initialOffset);
            break;

        case 2:
            coverage2.Initialize(initialTable, initialOffset);
            break;

        default:
            INPUT_ASSERT_FAIL_MSG("This is an unknown coverage format.");
            break;
        }
    }

    uint16_t ReadNextGlyph()
    {
        uint16_t glyphId = 0;

        switch (this->format)
        {
        case 1: // Coverage array
            if (this->rangeSubindex < coverage1.glyphCount)
            {
                glyphId = coverage1.glyphs[this->rangeSubindex++];
            }
            break;

        case 2: // Glyph Ranges
            if (rangeIndex < coverage2.rangeCount)
            {
                uint16_t firstGlyphId = coverage2.ranges[rangeIndex].firstGlyph;
                uint16_t lastGlyphId  = coverage2.ranges[rangeIndex].lastGlyph;

                glyphId = static_cast<uint16_t>(firstGlyphId + this->rangeSubindex);

                // Advance to the next glyph in range, or next range if we reached the end.
                this->rangeSubindex++;
                if (glyphId >= lastGlyphId)
                {
                    rangeIndex++;
                    this->rangeSubindex = 0;
                }
            }
            break;
        }

        return glyphId;
    }
};


struct ClassDefinitionTableHelper : FontTableHelper
{
    uint32_t const format;

    ClassDefinitionTableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        format(table.ReadAt<ClassDef>(tableOffset).format)
    { }

    struct Format1Helper
    {
        ClassDefFormat1 const& fontData;
        uint32_t startGlyph; // First GlyphID of the classValues
        uint32_t glyphCount;
        _Field_size_(glyphCount) OpenTypeUShort const* classValues;

        Format1Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   fontData(initialTable.ReadAt<ClassDefFormat1>(initialOffset)),
            startGlyph(fontData.startGlyph),
            glyphCount(fontData.glyphCount),
            classValues(initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(ClassDefFormat1), glyphCount))
        { }
    };

    struct Format2Helper
    {
        ClassDefFormat2 const& fontData;
        uint32_t rangeCount;
        _Field_size_(rangeCount) ClassDefFormat2::RangeRecord const* rangeRecords;

        Format2Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   fontData(initialTable.ReadAt<ClassDefFormat2>(initialOffset)),
            rangeCount(fontData.rangeCount),
            rangeRecords(initialTable.ReadArrayAt<ClassDefFormat2::RangeRecord>(initialOffset + sizeof(ClassDefFormat2), rangeCount))
        { }
    };

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        switch (this->format)
        {
        case 1: // Coverage array
            {
                Format1Helper classDefinition(this->table, this->tableOffset);
                GlyphCoverageRange range = {uint16_t(classDefinition.startGlyph), uint16_t(classDefinition.glyphCount)};
                coverageRanges.push_back(range);
            }
            break;

        case 2: // Glyph Ranges
            {
                Format2Helper classDefinition(this->table, this->tableOffset);

                const size_t oldCoverageRangesSize = coverageRanges.size();
                coverageRanges.resize(oldCoverageRangesSize + classDefinition.rangeCount);
                for (uint32_t i = 0; i < classDefinition.rangeCount; i++)
                {
                    auto& outputRange   = coverageRanges[oldCoverageRangesSize + i];
                    uint32_t firstGlyph = classDefinition.rangeRecords[i].firstGlyphID;
                    uint32_t lastGlyph  = classDefinition.rangeRecords[i].lastGlyphID;
                    int32_t glyphCount  = lastGlyph + 1 - firstGlyph; // difference of uint16's

                    if (glyphCount <= 0)
                    {
                        glyphCount = 0;
                        INPUT_ASSERT_FAIL_MSG("Class definition had invalid range (ignoring).");
                    }
                    else if (glyphCount > 0xFFFF)
                    {
                        glyphCount = 0xFFFF;
                        INPUT_ASSERT_FAIL_MSG("Class definition had excessive range (clamping).");
                    }

                    outputRange.first = static_cast<uint16_t>(firstGlyph);
                    outputRange.count = static_cast<uint16_t>(glyphCount);
                }
            }
            break;

        default:
            // unknown format. Play it safe and return true.
            INPUT_ASSERT_FAIL_MSG("This is an unknown class definition.");
            break;
        }
    }
};


// GSUB lookup type 1.
struct SingleSubstitutionSubtableHelper : FontTableHelper
{
    SingleSubstitutionSubtable const& fontData;

    SingleSubstitutionSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<SingleSubstitutionSubtable>(tableOffset))
    { }

    struct Format1Helper
    {
        uint16_t const deltaGlyphID;

        Format1Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   deltaGlyphID(initialTable.ReadAt<SingleSubstitutionSubtableFormat1>(initialOffset).deltaGlyphID)
        { }
    };

    struct Format2Helper
    {
        uint32_t const glyphCount;
        _Field_size_(glyphCount) OpenTypeUShort const* const glyphs;

        Format2Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   glyphCount(initialTable.ReadAt<SingleSubstitutionSubtableFormat2>(initialOffset).glyphCount),
            glyphs(initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(SingleSubstitutionSubtableFormat2), glyphCount))
        { }
    };

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
    }

#ifdef NOT_USED
    void ReadGlyphs(CmapBuilderSink& sink) const
    {
        CoverageTableIterator coverageTableIterator(this->table, this->tableOffset + this->fontData.coverageOffset);
        uint32_t const glyphCount = coverageTableIterator.GetGlyphCount();

        // Use coverage iterator
        switch (fontData.format)
        {
        case 1:
            {
                Format1Helper substitution(this->table, this->tableOffset);
                for (uint32_t i = 0; i < glyphCount; ++i)
                {
                    uint16_t glyphId = coverageTableIterator.ReadNextGlyph();
                    sink.Insert(glyphId, glyphId + substitution.deltaGlyphID);
                }
            }
            break;

        case 2:
            {
                Format2Helper substitution(this->table, this->tableOffset);
                if (substitution.glyphCount != glyphCount)
                {
                    INPUT_ASSERT_FAIL_MSG("The coverage and substitution counts are supposed to equal each other.");
                    break;
                }
                for (uint32_t i = 0; i < glyphCount; ++i)
                {
                    uint16_t glyphId = coverageTableIterator.ReadNextGlyph();
                    sink.Insert(glyphId, substitution.glyphs[i]);
                }
            }
            break;

        default:
            // Unknown format.
            INPUT_ASSERT_FAIL_MSG("This is an unknown substitution format.");
            break;
        }
    }
#endif
};

// GSUB lookup type 2.
struct MultipleSubstitutionSubtableHelper : FontTableHelper
{
    MultipleSubstitutionSubtable const& fontData;

    MultipleSubstitutionSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<MultipleSubstitutionSubtable>(tableOffset))
    { }

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
    }
};

// GSUB lookup type 3.
struct AlternateSubstitutionSubtableHelper : FontTableHelper
{
    AlternateSubstitutionSubtable const& fontData;

    AlternateSubstitutionSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<AlternateSubstitutionSubtable>(tableOffset))
    { }

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
    }
};

// GSUB lookup type 4.
struct LigatureSubstitutionSubtableHelper : FontTableHelper
{
    LigatureSubstitutionSubtable const& fontData;

    LigatureSubstitutionSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<LigatureSubstitutionSubtable>(tableOffset))
    { }

    struct LigatureHelper
    {
        LigatureSubstitutionSubtable::Ligature const& fontData;

        uint32_t const componentCount;
        _Field_size_(componentCount) OpenTypeUShort const* const components;

        LigatureHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   fontData(initialTable.ReadAt<LigatureSubstitutionSubtable::Ligature>(initialOffset)),
            componentCount(fontData.componentCount),
            components(initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(LigatureSubstitutionSubtable::Ligature), componentCount))
        { }

        inline uint16_t GetComponent(_In_range_(1, this->componentCount) uint16_t index) const throw()
        {
            // LigaTable includes components from 1 to N. So, return glyph at (index-1)
            return components[index - 1];
        }
    };

    struct LigatureSetHelper : FontTableHelper
    {
        uint32_t const ligatureCount;
        _Field_size_(ligatureCount) OpenTypeUShort const* const ligatureOffsets;

        LigatureSetHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   FontTableHelper(initialTable, initialOffset),
            ligatureCount(initialTable.ReadAt<LigatureSubstitutionSubtable::LigatureSet>(initialOffset).ligatureCount),
            ligatureOffsets(initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(LigatureSubstitutionSubtable::LigatureSet), ligatureCount))
        { }

        inline LigatureHelper GetLigature(uint32_t index) const
        {
            INPUT_ASSERT_FAIL_MSG(ligatureOffsets[index] != 0);
            return LigatureHelper(table, tableOffset + ligatureOffsets[index]);
        }
    };

    struct Format1Helper : FontTableHelper
    {
        uint32_t const ligatureSetCount;
        _Field_size_(ligatureSetCount) OpenTypeUShort const* const ligatureSetOffsets;

        Format1Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   FontTableHelper(initialTable, initialOffset),
            ligatureSetCount(table.ReadAt<LigatureSubstitutionSubtableFormat1>(tableOffset).ligatureSetCount),
            ligatureSetOffsets(table.ReadArrayAt<OpenTypeUShort>(tableOffset + sizeof(LigatureSubstitutionSubtableFormat1), ligatureSetCount))
        { }

        inline LigatureSetHelper GetLigatureSet(uint32_t setIndex) const
        {
            INPUT_ASSERT_FAIL_MSG(ligatureSetOffsets[setIndex] != 0);
            return LigatureSubstitutionSubtableHelper::LigatureSetHelper(
                table,
                tableOffset + ligatureSetOffsets[setIndex]
                );
        }
    };

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);

        if (!coverageTable.IsAnyGlyphCovered(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits))
        {
            // If none of the starting glyphs match, then there's no point in
            // continuing. For example, say the lookup contains a ligature for
            // Hebrew Alef + Lamed, but the bit for the Alef glyph is not set.
            return false;
        }

        if (fontData.format != 1)
        {
            // Unknown format, so play it safe, mark all coverage, and return.
            INPUT_ASSERT_FAIL_MSG("This is an unknown ligature substitution format.");
            return coverageTable.UpdateGlyphCoverage(
                minGlyphId,
                maxGlyphId,
                glyphBitsSize,
                interestedGlyphBits,
                /*inout*/simpleGlyphBits
                );        
        }

        Format1Helper ligatureSubtable(this->table, this->tableOffset);
        bool isLookupCovered = false;
                    
        for (uint32_t setIndex = 0; setIndex < ligatureSubtable.ligatureSetCount; setIndex++)
        {
            // Skip this entire ligature set if the starting glyph is not of interest.
            // (e.g. if a ligature exists for 'etc', check 'e')
            uint16_t firstGlyphId = coverageTable.GetGlyphAtIndex(setIndex);
            if (firstGlyphId > maxGlyphId || firstGlyphId < minGlyphId || !TestBit(interestedGlyphBits, firstGlyphId))
                continue;

            LigatureSetHelper ligatureSet(ligatureSubtable.GetLigatureSet(setIndex));
            bool ligatureApplies = false;
            
            for (uint32_t liga = 0; liga < ligatureSet.ligatureCount; liga++)
            {
                LigatureHelper ligature(ligatureSet.GetLigature(liga));

                // Check the remaining glyph components of the ligature
                // (e.g. if a ligature exists for 'etc', now check 't','c')
                // and mark the lookup as complex if any after the first glyph
                // fall in the range of interest. For example, if a ligature
                // existed for 'i' + diacritic, and the initial i was covered
                // while the diacritic was not, the lookup as a whole does not
                // apply. This avoids unnecessary underperformance where the
                // presence of any 'i' character in the text would make it
                // complex, instead only taking the hit if a later diacritic
                // is read. However, for the 'fi' ligature, both 'f' and 'i'
                // would be marked as complex.

                for (uint16_t compIndex = 1; compIndex < ligature.componentCount; compIndex++)
                {
                    #pragma prefast (suppress: __WARNING_INCORRECT_VALIDATION, "Bug Esp:659 - false positive with doubly nested loop")
                    uint16_t glyphId = ligature.GetComponent(compIndex);

                    if (glyphId <= maxGlyphId && glyphId >= minGlyphId && TestBit(interestedGlyphBits, glyphId))
                    {
                        if (simpleGlyphBits == nullptr)
                            return true; // early out, since only interested in result

                        ligatureApplies = true;
                        ClearBit(simpleGlyphBits, glyphId);
                    }
                }
            }

            if (ligatureApplies)
            {
                if (simpleGlyphBits == nullptr)
                    return true; // early out, since only interested in result

                // Ligature was covered, so mark initial glyph as complex.
                isLookupCovered = true;
                ClearBit(simpleGlyphBits, firstGlyphId);
            }
        }

        return isLookupCovered;
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);

        coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);

        if (fontData.format != 1)
        {
            INPUT_ASSERT_FAIL_MSG("This is an unknown ligature substitution format.");
            return;
        }

        Format1Helper ligatureSubtable(this->table, this->tableOffset);
                    
        for (uint32_t setIndex = 0; setIndex < ligatureSubtable.ligatureSetCount; setIndex++)
        {
            // A ligature set such as {'fi','ffi','ffl'} all starting with the same glyph 'f'.
            LigatureSetHelper ligatureSet(ligatureSubtable.GetLigatureSet(setIndex));
            
            for (uint32_t liga = 0; liga < ligatureSet.ligatureCount; liga++)
            {
                // A single ligature such as 'ffi' or 'etc'.
                LigatureHelper ligature(ligatureSet.GetLigature(liga));

                // Add all the remaining glyph components of the ligature to 
                // the coverage ranges.

                for (uint16_t compIndex = 1; compIndex < ligature.componentCount; compIndex++)
                {
                    // The component glyph in a ligature such as the 't' or 'c' in 'etc'.
                    #pragma prefast (suppress: __WARNING_INCORRECT_VALIDATION, "Bug Esp:659 - false positive with doubly nested loop")
                    uint16_t glyphId = ligature.GetComponent(compIndex);
                    GlyphCoverageRange range = {glyphId, 1};
                    coverageRanges.push_back(range);
                }
            }
        }
    }
};

// GPOS lookup type 1.
struct SinglePositioningSubtableHelper : FontTableHelper
{
    SinglePositioningSubtable const& fontData;

    SinglePositioningSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<SinglePositioningSubtable>(tableOffset))
    { }

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
    }
};

// GPOS lookup type 2.
struct PairPositioningSubtableHelper : FontTableHelper
{
    PairPositioningSubtable const& fontData;

    PairPositioningSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<PairPositioningSubtable>(tableOffset))
    { }

    struct Format1Helper
    {
        PairPositioningSubtableFormat1 const& fontData;
        uint32_t pairSetCount;
        _Field_size_(pairSetCount) OpenTypeUShort const* pairSetOffsets;

        Format1Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   fontData(initialTable.ReadAt<PairPositioningSubtableFormat1>(initialOffset)),
            pairSetCount(fontData.pairSetCount),
            pairSetOffsets(initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(PairPositioningSubtableFormat1), pairSetCount))
        { }
    };

    struct Format2Helper
    {
        PairPositioningSubtableFormat2 const& fontData;
        uint32_t class1Count;   // Number of classes in ClassDef1 table - includes Class0
        uint32_t class2Count;   // Number of classes in ClassDef2 table - includes Class0

        Format2Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   fontData(initialTable.ReadAt<PairPositioningSubtableFormat2>(initialOffset)),
            class1Count(fontData.class1Count),
            class2Count(fontData.class2Count)
        { }
    };

    inline static uint32_t GetValueFormatBitCount(uint32_t bits) throw()
    {
        // Favor a simpler sparse-ones approach rather than a large table
        // lookup since value formats in pair positioning usually have zero
        // or one fields set, sometimes two for kerning.

        uint32_t count = 0;
        while (bits)
        {
            count++;
            bits &= (bits - 1);
        }
        return count;
    }

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);

        // To improve perf, we could also check the second glyph of the PairValueRecord.
        // That way we don't mark all occurrences of the first half's glyph as complex.
        // This probably isn't worth the effort though, since realistically, the pair
        // set is part of kerning, for which both characters would be the same script.
        // So, since a very high percentage of the time, we would gain nothing from
        // additional checks, just check the first glyph.

        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);

        switch (fontData.format)
        {
        case 1:
            {
                typedef PairPositioningSubtableFormat1::PairSet PairSet;
                typedef PairPositioningSubtableFormat1::PairValueRecord PairValueRecord;

                //  Pair positioning lookup format 1 contains the first glyph
                //  (such as the 'A' in "AVATAR") in the coverage table, and
                //  the right glyphs ('V' or 'T') in the pair sets, with one
                //  pair set per each first glyph.
                //
                //  Example pair positioning lookup:
                //      Coverage table {'A','V','T'}
                //      Pair set[0] 'A'
                //          Pair values[0] 'V'
                //          Pair values[1] 'T'
                //      Pair set[1] 'V'
                //          Pair values[0] 'A'
                //      Pair set[2] 'T'
                //          Pair values[0] 'A'
                //
                //  Each pair value record is a variable size structure that
                //  contains int16 adjustments for the advance and offset
                //  (horizontal or vertical), with field presence depending
                //  on which bits are set in the format fields.

                const Format1Helper positioning(this->table, this->tableOffset);
                const uint32_t format1Count = GetValueFormatBitCount(positioning.fontData.valueFormat1);
                const uint32_t format2Count = GetValueFormatBitCount(positioning.fontData.valueFormat2);

                coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);

                const uint32_t pairValueRecordByteSize = sizeof(PairValueRecord)
                                                       + (format1Count + format2Count) * sizeof(OpenTypeUShort);

                // For each pair set
                for (uint32_t i = 0; i < positioning.pairSetCount; ++i)
                {
                    INPUT_ASSERT_FAIL_MSG(positioning.pairSetOffsets[i] != 0);
                    const uint32_t pairSetOffset = this->tableOffset + positioning.pairSetOffsets[i];
                    const PairSet& pairSet = this->table.ReadAt<PairSet>(pairSetOffset);
                    // Compute the size of the pair value records. Typically
                    // only one field will be set, maybe two. So if both the
                    // x-advance and x-placement were affected (format2
                    // equals 0x0005), then the record would just be 4 bytes.
                    //
                    //      Format  Name
                    //  ->  0x0001  XPlacement  Includes horizontal adjustment for placement
                    //      0x0002  YPlacement  Includes vertical adjustment for placement
                    //  ->  0x0004  XAdvance    Includes horizontal adjustment for advance
                    //      0x0008  YAdvance    Includes vertical adjustment for advance
                    //      0x0010  XPlaDevice  Includes horizontal Device table for placement
                    //      0x0020  YPlaDevice  Includes vertical Device table for placement
                    //      0x0040  XAdvDevice  Includes horizontal Device table for advance
                    //      0x0080  YAdvDevice  Includes vertical Device table for advance
                    //      0xF000  Reserved    For future use (set to zero)

                    const uint32_t pairValueCount = pairSet.pairValueCount;
                    const uint32_t pairValueRecordsTotalSize = pairValueCount * pairValueRecordByteSize;
                    // * Note no overflow occurs above because the 16-bit masks
                    //   (format1 and format2) will yield at most 16 bits each
                    //   from GetValueFormatBitCount(). So the max value would
                    //   be byteSize = (16+16) * sizeof(uint16) * 0xFFFF.

                    // Validate the data range of all the records and get
                    // the pointer to the first record.
                    _Field_size_bytes_(pairValueRecordsTotalSize)
                    const PairValueRecord* currentPairValueRecord = 
                        &this->table.ReadAt<PairValueRecord>(
                            pairSetOffset + sizeof(PairSet),
                            pairValueRecordsTotalSize
                            );

                    const size_t oldCoverageRangesSize = coverageRanges.size();
                    coverageRanges.resize(oldCoverageRangesSize + pairValueCount);

                    // Read all the second glyphs of each pair into the coverage.
                    for (uint32_t j = 0; j < pairValueCount; ++j)
                    {
                        auto& outputRange = coverageRanges[oldCoverageRangesSize + j];
                        outputRange.first = currentPairValueRecord->secondGlyph;
                        outputRange.count = 1;

                        // Advance to next record by variable size.
                        currentPairValueRecord = PtrAddByteOffset(currentPairValueRecord, pairValueRecordByteSize);
                    }
                }
            }
            break;

        case 2:
            {
                const Format2Helper positioning(this->table, this->tableOffset);
                INPUT_ASSERT_FAIL_MSG(positioning.fontData.classDef1Offset != 0);
                INPUT_ASSERT_FAIL_MSG(positioning.fontData.classDef2Offset != 0);
                const ClassDefinitionTableHelper classDefinition1(this->table, this->tableOffset + positioning.fontData.classDef1Offset);
                const ClassDefinitionTableHelper classDefinition2(this->table, this->tableOffset + positioning.fontData.classDef2Offset);

                classDefinition1.ReadLookupCoverage(/*inout*/coverageRanges);
                classDefinition2.ReadLookupCoverage(/*inout*/coverageRanges);
            }
            break;

        default:
            INPUT_ASSERT_FAIL_MSG("This is an unknown pair positioning format.");
            break;
        }
    }
};

// GPOS lookup type 3.
struct CursivePositioningSubtableHelper : FontTableHelper
{
    CursivePositioningSubtable const& fontData;

    CursivePositioningSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<CursivePositioningSubtable>(tableOffset))
    { }

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        // Chances are quite high that if the cursive feature is applied,
        // then it's likely applied often and to most of the glyphs in a
        // script. So there's little point in checking all the entry and
        // exit records.

        INPUT_ASSERT_FAIL_MSG(fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + fontData.coverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
    }
};

// GPOS lookup type 4.
struct MarkToBasePositioningSubtableHelper : FontTableHelper
{
    MarkToBasePositioningSubtable const& fontData;

    MarkToBasePositioningSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<MarkToBasePositioningSubtable>(tableOffset))
    { }

    struct Format1Helper
    {
        MarkToBasePositioningSubtableFormat1 const& fontData;

        Format1Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :    fontData(initialTable.ReadAt<MarkToBasePositioningSubtableFormat1>(initialOffset))
        { }
    };

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        if (fontData.format != 1)
        {
            INPUT_ASSERT_FAIL_MSG("This is an unknown mark to base positioning format.");
            return true;
        }

        // It's more useful to check the mark coverage than the base coverage,
        // since the marks are typically diacritics (which are usually
        // complex anyway), while the base characters are usually simple
        // characters (for which we want to be able to use nominal glyphs).

        Format1Helper markToBase(this->table, this->tableOffset);
        INPUT_ASSERT_FAIL_MSG(markToBase.fontData.markCoverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + markToBase.fontData.markCoverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        if (fontData.format != 1)
        {
            INPUT_ASSERT_FAIL_MSG("This is an unknown mark to base positioning format.");
            return;
        }

        Format1Helper markToBase(this->table, this->tableOffset);
        INPUT_ASSERT_FAIL_MSG(markToBase.fontData.baseCoverageOffset != 0);
        INPUT_ASSERT_FAIL_MSG(markToBase.fontData.markCoverageOffset != 0);
        CoverageTableHelper baseCoverageTable(this->table, this->tableOffset + markToBase.fontData.baseCoverageOffset);
        CoverageTableHelper markCoverageTable(this->table, this->tableOffset + markToBase.fontData.markCoverageOffset);

        baseCoverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
        markCoverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
    }
};

// GPOS lookup type 5.
struct MarkToLigaturePositioningSubtableHelper : FontTableHelper
{
    MarkToLigaturePositioningSubtable const& fontData;

    MarkToLigaturePositioningSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<MarkToLigaturePositioningSubtable>(tableOffset))
    { }

    struct Format1Helper
    {
        MarkToLigaturePositioningSubtableFormat1 const& fontData;

        Format1Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :    fontData(initialTable.ReadAt<MarkToLigaturePositioningSubtableFormat1>(initialOffset))
        { }
    };

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        if (fontData.format != 1)
        {
            INPUT_ASSERT_FAIL_MSG("This is an unknown mark to ligature positioning format.");
            return true;
        }

        // It's more useful to check the mark coverage than the ligature coverage,
        // just like for MarkToBase tables.

        Format1Helper markToLigature(this->table, this->tableOffset);
        INPUT_ASSERT_FAIL_MSG(markToLigature.fontData.markCoverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + markToLigature.fontData.markCoverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        if (fontData.format != 1)
        {
            INPUT_ASSERT_FAIL_MSG("This is an unknown mark to ligature positioning format.");
            return;
        }

        Format1Helper markToLigature(this->table, this->tableOffset);
        INPUT_ASSERT_FAIL_MSG(markToLigature.fontData.ligatureCoverageOffset != 0);
        INPUT_ASSERT_FAIL_MSG(markToLigature.fontData.markCoverageOffset != 0);
        CoverageTableHelper ligatureCoverageTable(this->table, this->tableOffset + markToLigature.fontData.ligatureCoverageOffset);
        CoverageTableHelper markCoverageTable(this->table, this->tableOffset + markToLigature.fontData.markCoverageOffset);

        ligatureCoverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
        markCoverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
    }
};

// GPOS lookup type 6.
struct MarkToMarkPositioningSubtableHelper : FontTableHelper
{
    MarkToMarkPositioningSubtable const& fontData;

    MarkToMarkPositioningSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<MarkToMarkPositioningSubtable>(tableOffset))
    { }

    struct Format1Helper
    {
        MarkToMarkPositioningSubtableFormat1 const& fontData;

        Format1Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :    fontData(initialTable.ReadAt<MarkToMarkPositioningSubtableFormat1>(initialOffset))
        { }
    };

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        if (fontData.format != 1)
        {
            INPUT_ASSERT_FAIL_MSG("This is an unknown mark to mark positioning format.");
            return true;
        }

        // There are actually two mark tables, but we only need to mark the
        // initial one in each pair.

        Format1Helper markToMark(this->table, this->tableOffset);
        INPUT_ASSERT_FAIL_MSG(markToMark.fontData.mark1CoverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + markToMark.fontData.mark1CoverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        if (fontData.format != 1)
        {
            INPUT_ASSERT_FAIL_MSG("This is an unknown mark to mark positioning format.");
            return;
        }

        // Mark1 covers the attached glyphs being positioned.
        // Mark2 covers the base mark glyphs.
        Format1Helper markToMark(this->table, this->tableOffset);
        INPUT_ASSERT_FAIL_MSG(markToMark.fontData.mark1CoverageOffset != 0);
        INPUT_ASSERT_FAIL_MSG(markToMark.fontData.mark2CoverageOffset != 0);
        CoverageTableHelper coverageTable1(this->table, this->tableOffset + markToMark.fontData.mark1CoverageOffset);
        CoverageTableHelper coverageTable2(this->table, this->tableOffset + markToMark.fontData.mark2CoverageOffset);

        coverageTable1.ReadLookupCoverage(/*inout*/coverageRanges);
        coverageTable2.ReadLookupCoverage(/*inout*/coverageRanges);
    }
};

// GSUB lookup type 5, GPOS lookup type 7 : format 1
struct GlyphContextSubtableHelper : FontTableHelper
{
    GlyphContextSubtable const& fontData;
    uint32_t ruleSetCount;
    _Field_size_(ruleSetCount) OpenTypeUShort const* ruleSetOffsets;

    GlyphContextSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<GlyphContextSubtable>(tableOffset)),
        ruleSetCount(fontData.ruleSetCount),
        ruleSetOffsets(initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(GlyphContextSubtable), ruleSetCount))
    { }

    struct RuleHelper
    {
        GlyphContextSubtable::Rule const& fontData;
        uint32_t glyphCount;
        _Field_size_(glyphCount) OpenTypeUShort const* glyphs;

        RuleHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   fontData(initialTable.ReadAt<GlyphContextSubtable::Rule>(initialOffset)),
            glyphCount(fontData.glyphCount),
            glyphs(initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(GlyphContextSubtable::Rule), glyphCount))
        {
            if (glyphCount == 0)
            {
                INPUT_ASSERT_FAIL_MSG("This contextual substitution/positioning lookup has an invalid rule glyph count of zero.");
            }
            else
            {
                // Note the rule's glyphCount includes the first glyph, but the
                // glyph input is actually count - 1 because it starts from the
                // second glyph. So adjust it for the benefit of counted loops.
                --glyphCount;
            }
        }
    };

    struct RuleSetHelper : FontTableHelper
    {
        GlyphContextSubtable::RuleSet const& fontData;
        uint32_t subRuleCount;
        _Field_size_(subRuleCount) OpenTypeUShort const* subRuleOffsets;

        RuleSetHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   FontTableHelper(initialTable, initialOffset),
            fontData(initialTable.ReadAt<GlyphContextSubtable::RuleSet>(initialOffset)),
            subRuleCount(fontData.subRuleCount),
            subRuleOffsets(initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(GlyphContextSubtable::RuleSet), subRuleCount))
        { }

        inline RuleHelper GetRule(uint32_t index) const
        {
            INPUT_ASSERT_FAIL_MSG(subRuleOffsets[index] != 0);
            return RuleHelper(table, tableOffset + subRuleOffsets[index]);
        }
    };

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + fontData.coverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);

        for (uint32_t i = 0; i < this->ruleSetCount; ++i)
        {
            INPUT_ASSERT_FAIL_MSG(this->ruleSetOffsets[i] != 0);
            RuleSetHelper ruleSet(this->table, this->tableOffset + this->ruleSetOffsets[i]);

            for (uint32_t j = 0; j < ruleSet.subRuleCount; ++j)
            {
                // Read the rule and treat the rest of it like a coverage
                // table, as it is just a list of glyphs.

                RuleHelper rule(ruleSet.GetRule(j));
                CoverageTableHelper::Format1Helper coverage(rule.glyphCount, rule.glyphs);
                coverage.ReadLookupCoverage(/*inout*/coverageRanges);
            }
        }
    }
};

// GSUB lookup type 5, GPOS lookup type 7 : format 2
struct ClassContextSubtableHelper : FontTableHelper
{
    ClassContextSubtable const& fontData;

    ClassContextSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<ClassContextSubtable>(tableOffset))
    { }

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + fontData.coverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        INPUT_ASSERT_FAIL_MSG(this->fontData.classDefOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        ClassDefinitionTableHelper classDefinition(this->table, this->tableOffset + this->fontData.classDefOffset);
        coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
        classDefinition.ReadLookupCoverage(/*inout*/coverageRanges);
    }
};

// GSUB lookup type 5, GPOS lookup type 7 : format 3
struct CoverageContextSubtableHelper : FontTableHelper
{
    uint32_t const coverageCount;
    _Field_size_(coverageCount) OpenTypeUShort const* const coverageOffsets;

    CoverageContextSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        coverageCount(initialTable.ReadAt<CoverageContextSubtable>(initialOffset).glyphCount),
        coverageOffsets(initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(CoverageContextSubtable), coverageCount))
    { }

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        for (uint32_t index = 0; index < this->coverageCount; index++)
        {
            INPUT_ASSERT_FAIL_MSG(coverageOffsets[index] != 0);
            CoverageTableHelper coverageTable(this->table, this->tableOffset + coverageOffsets[index]);
            if (!coverageTable.IsAnyGlyphCovered(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits))
                return false;
        }

        // The entire glyph sequence was covered, so mark the input glyphs as complex.
        for (uint32_t index = 0; index < this->coverageCount; index++)
        {
            INPUT_ASSERT_FAIL_MSG(coverageOffsets[index] != 0);
            CoverageTableHelper coverageTable(this->table, this->tableOffset + coverageOffsets[index]);
            coverageTable.UpdateGlyphCoverage(
                minGlyphId,
                maxGlyphId,
                glyphBitsSize,
                interestedGlyphBits,
                /*inout*/simpleGlyphBits
                );        
        }

        return true;
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        for (uint32_t index = 0; index < this->coverageCount; index++)
        {
            INPUT_ASSERT_FAIL_MSG(coverageOffsets[index] != 0);
            CoverageTableHelper coverageTable(this->table, this->tableOffset + coverageOffsets[index]);
            coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);        
        }
    }
};

// GSUB lookup type 5, GPOS lookup type 7.
struct ContextSubtableHelper : FontTableHelper
{
    uint32_t const format;

    ContextSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        format(table.ReadAt<ContextSubtable>(tableOffset).format)
    { }

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        switch (this->format)
        {
        case 1:
            {
                GlyphContextSubtableHelper glyphContextSubtable(this->table, this->tableOffset);
                return glyphContextSubtable.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
            }
        case 2: 
            {
                ClassContextSubtableHelper classContextSubtable(this->table, this->tableOffset);
                return classContextSubtable.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
            }
        case 3:
            {
                CoverageContextSubtableHelper coverageContextSubtable(this->table, this->tableOffset);
                return coverageContextSubtable.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
            }
        default:
            INPUT_ASSERT_FAIL_MSG("This is an unknown contextual substitution/positioning format.");
            return true;
        }
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        switch (this->format)
        {
        case 1:
            {
                GlyphContextSubtableHelper glyphContextSubtable(this->table, this->tableOffset);
                return glyphContextSubtable.ReadLookupCoverage(/*inout*/coverageRanges);
            }
        case 2: 
            {
                ClassContextSubtableHelper classContextSubtable(this->table, this->tableOffset);
                return classContextSubtable.ReadLookupCoverage(/*inout*/coverageRanges);
            }
        case 3:
            {
                CoverageContextSubtableHelper coverageContextSubtable(this->table, this->tableOffset);
                return coverageContextSubtable.ReadLookupCoverage(/*inout*/coverageRanges);
            }
        default:
            INPUT_ASSERT_FAIL_MSG("This is an unknown contextual substitution/positioning format.");
            return;
        }
    }
};

// GSUB lookup type 6, GPOS lookup type 8 : format 1
struct GlyphChainingSubtableHelper : FontTableHelper
{
    GlyphChainingSubtable const& fontData;
    uint32_t chainRuleSetCount;
    _Field_size_(chainRuleSetCount) OpenTypeUShort const* chainRuleSetOffsets;

    GlyphChainingSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<GlyphChainingSubtable>(tableOffset)),
        chainRuleSetCount(fontData.chainRuleSetCount),
        chainRuleSetOffsets(initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(GlyphChainingSubtable), chainRuleSetCount))
    { }

    struct ChainRuleHelper
    {
        CoverageTableHelper::Format1Helper backtrackCoverage;
        CoverageTableHelper::Format1Helper inputCoverage;
        CoverageTableHelper::Format1Helper lookaheadCoverage;

        ChainRuleHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        {
            // Since the array offsets are variable size, setup the offsets now.
            // Although the OpenType definition for ChainSubRule defines them
            // as loose fields of glyph count followed by glyph id's, they are
            // essentially coverage tables, identical in format.

            const uint32_t backtrackCoverageListOffset = offsetof(GlyphChainingSubtable::ChainRule, backtrackGlyphCount); // actually is 0
            backtrackCoverage.Initialize(initialTable, initialOffset + backtrackCoverageListOffset);

            // Read the input coverage specially since it contains one less than the count.
            const uint32_t inputCoverageListOffset = backtrackCoverageListOffset + backtrackCoverage.GetByteSize();
            inputCoverage.InitializeExcludingLastGlyph(initialTable, initialOffset + inputCoverageListOffset);

            const uint32_t lookaheadCoverageListOffset = inputCoverageListOffset + inputCoverage.GetByteSize();
            lookaheadCoverage.Initialize(initialTable, initialOffset + lookaheadCoverageListOffset);
        }

        uint32_t GetTotalGlyphCount() const
        {
            return backtrackCoverage.glyphCount + inputCoverage.glyphCount + lookaheadCoverage.glyphCount;
        }
    };

    struct ChainRuleSetHelper : FontTableHelper
    {
        GlyphChainingSubtable::ChainRuleSet const& fontData;
        uint32_t chainRuleCount;
        _Field_size_(chainRuleCount) OpenTypeUShort const* chainRuleOffsets;

        ChainRuleSetHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        :   FontTableHelper(initialTable, initialOffset),
            fontData(initialTable.ReadAt<GlyphChainingSubtable::ChainRuleSet>(initialOffset)),
            chainRuleCount(fontData.chainRuleCount),
            chainRuleOffsets(initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(GlyphChainingSubtable::ChainRuleSet), chainRuleCount))
        { }

        inline ChainRuleHelper GetRule(uint32_t index) const
        {
            INPUT_ASSERT_FAIL_MSG(chainRuleOffsets[index] != 0);
            return ChainRuleHelper(table, tableOffset + chainRuleOffsets[index]);
        }
    };

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + fontData.coverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);

        // For each set
        for (uint32_t i = 0; i < this->chainRuleSetCount; ++i)
        {
            INPUT_ASSERT_FAIL_MSG(this->chainRuleSetOffsets[i] != 0);
            ChainRuleSetHelper chainRuleSet(this->table, this->tableOffset + this->chainRuleSetOffsets[i]);
            // For each rule in the current set
            for (uint32_t j = 0; j < chainRuleSet.chainRuleCount; ++j)
            {
                ChainRuleHelper chainRule(chainRuleSet.GetRule(j));

                // For each coverage in the rule (backtrack, input, and lookahead),
                // copy out the glyphs.
                for (uint32_t k = 0; k < 3; ++k)
                {
                    CoverageTableHelper::Format1Helper coverage;
                    switch (k)
                    {
                    case 0: coverage = chainRule.backtrackCoverage;  break;
                    case 1: coverage = chainRule.inputCoverage;      break;
                    case 2: coverage = chainRule.lookaheadCoverage;  break;
                    }

                    coverage.ReadLookupCoverage(/*inout*/coverageRanges);
                }
            }
        }
    }
};

// GSUB lookup type 6, GPOS lookup type 8 : format 2
struct ClassChainingSubtableHelper : FontTableHelper
{
    ClassChainingSubtable const& fontData;

    ClassChainingSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<ClassChainingSubtable>(tableOffset))
    { }

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        INPUT_ASSERT_FAIL_MSG(this->fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + fontData.coverageOffset);
        return coverageTable.UpdateGlyphCoverage(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );        
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        if (fontData.backtrackClassDefOffset != 0)
        {
            const ClassDefinitionTableHelper backtrackClassDefinition(this->table, this->tableOffset + fontData.backtrackClassDefOffset);
            backtrackClassDefinition.ReadLookupCoverage(/*inout*/coverageRanges);
        }
        if (fontData.inputClassDefOffset != 0)
        {
            const ClassDefinitionTableHelper inputClassDefinition(this->table, this->tableOffset + fontData.inputClassDefOffset);
            inputClassDefinition.ReadLookupCoverage(/*inout*/coverageRanges);
        }
        if (fontData.lookaheadClassDefOffset != 0)
        {
            const ClassDefinitionTableHelper lookaheadClassDefinition(this->table, this->tableOffset + fontData.lookaheadClassDefOffset);
            lookaheadClassDefinition.ReadLookupCoverage(/*inout*/coverageRanges);
        }
    }
};


struct CoverageOffsetListHelper
{
    uint32_t coverageCount;
    _Field_size_(coverageCount) OpenTypeUShort const* coverageOffsets;

    CoverageOffsetListHelper()
    :   coverageCount(),
        coverageOffsets()
    { }

    inline CoverageOffsetListHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    {
        Initialize(initialTable, initialOffset);
    }

    void Initialize(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    {
        coverageCount = initialTable.ReadAt<CoverageOffsetList>(initialOffset).coverageCount;
        coverageOffsets = initialTable.ReadArrayAt<OpenTypeUShort>(initialOffset + sizeof(CoverageOffsetList), coverageCount);
    }

    uint32_t GetByteSize() const
    {
        return sizeof(CoverageOffsetList) + coverageCount * sizeof(coverageOffsets[0]);
    }
};


// GSUB lookup type 6, GPOS lookup type 8 : format 3
struct CoverageChainingSubtableHelper : FontTableHelper
{
    CoverageOffsetListHelper backtrackCoverages;
    CoverageOffsetListHelper inputCoverages;
    CoverageOffsetListHelper lookaheadCoverages;

    CoverageChainingSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset)
    {
        // Since the coverage offset arrays are variable size, setup the offsets now.
        const uint32_t backtrackCoverageListOffset = offsetof(CoverageChainingSubtable, backtrackGlyphCount);
        backtrackCoverages.Initialize(table, tableOffset + backtrackCoverageListOffset);

        const uint32_t inputCoverageListOffset = backtrackCoverageListOffset + backtrackCoverages.GetByteSize();
        inputCoverages.Initialize(table, tableOffset + inputCoverageListOffset);

        const uint32_t lookaheadCoverageListOffset = inputCoverageListOffset + inputCoverages.GetByteSize();
        lookaheadCoverages.Initialize(table, tableOffset + lookaheadCoverageListOffset);
    }

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        // Read the three coverage offset lists (we'll need to check all three)
        //
        // There is one coverage table for each glyph position:
        //
        // Logical order      - a b c d e f g h i j 
        // Input sequence     -         0 1      
        // Backtrack sequence - 3 2 1 0         
        // Lookahead sequence -             0 1 2 3

        // Bail if any glyph in the sequence cannot be covered.
        for (uint32_t index = 0; index < backtrackCoverages.coverageCount; index++)
        {
            INPUT_ASSERT_FAIL_MSG(backtrackCoverages.coverageOffsets[index] != 0);
            CoverageTableHelper coverageTable(this->table, this->tableOffset + backtrackCoverages.coverageOffsets[index]);
            if (!coverageTable.IsAnyGlyphCovered(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits))
                return false;
        }

        for (uint32_t index = 0; index < inputCoverages.coverageCount; index++)
        {
            INPUT_ASSERT_FAIL_MSG(inputCoverages.coverageOffsets[index] != 0);
            CoverageTableHelper coverageTable(this->table, this->tableOffset + inputCoverages.coverageOffsets[index]);
            if (!coverageTable.IsAnyGlyphCovered(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits))
                return false;
        }

        for (uint32_t index = 0; index < lookaheadCoverages.coverageCount; index++)
        {
            INPUT_ASSERT_FAIL_MSG(lookaheadCoverages.coverageOffsets[index] != 0);
            CoverageTableHelper coverageTable(this->table, this->tableOffset + lookaheadCoverages.coverageOffsets[index]);
            if (!coverageTable.IsAnyGlyphCovered(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits))
                return false;
        }

        // The entire glyph sequence was covered, so mark the input glyphs as complex.
        for (uint32_t index = 0; index < inputCoverages.coverageCount; index++)
        {
            INPUT_ASSERT_FAIL_MSG(inputCoverages.coverageOffsets[index] != 0);
            CoverageTableHelper coverageTable(this->table, this->tableOffset + inputCoverages.coverageOffsets[index]);
            coverageTable.UpdateGlyphCoverage(
                minGlyphId,
                maxGlyphId,
                glyphBitsSize,
                interestedGlyphBits,
                /*inout*/simpleGlyphBits
                );        
        }

        return true;
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        for (uint32_t i = 0; i < 3; ++i)
        {
            CoverageOffsetListHelper coverageList;
            switch (i)
            {
            case 0: coverageList = backtrackCoverages; break;
            case 1: coverageList = inputCoverages;     break;
            case 2: coverageList = lookaheadCoverages; break;
            }

            for (uint32_t j = 0; j < coverageList.coverageCount; ++j)
            {
                INPUT_ASSERT_FAIL_MSG(coverageList.coverageOffsets[j] != 0);
                CoverageTableHelper coverageTable(this->table, this->tableOffset + coverageList.coverageOffsets[j]);
                coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
            }
        }
    }
};

// GSUB lookup type 6, GPOS lookup type 8
struct ChainingSubtableHelper : FontTableHelper
{
    uint32_t const format;

    ChainingSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        format(table.ReadAt<ChainingSubtable>(tableOffset).format)
    { }

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        switch (this->format)
        {
        case 1:
            {
                GlyphChainingSubtableHelper glyphChainingSubtable(this->table, this->tableOffset);
                return glyphChainingSubtable.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
            }
        case 2: 
            {
                ClassChainingSubtableHelper classChainingSubtable(this->table, this->tableOffset);
                return classChainingSubtable.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
            }
        case 3:
            {
                CoverageChainingSubtableHelper coverageChainingSubtable(this->table, this->tableOffset);
                return coverageChainingSubtable.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
            }
        default:
            INPUT_ASSERT_FAIL_MSG("This is an unknown chaining contextual substitution/positioning format.");
            return true;    
        }
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        switch (this->format)
        {
        case 1:
            {
                GlyphChainingSubtableHelper glyphChainingSubtable(this->table, this->tableOffset);
                return glyphChainingSubtable.ReadLookupCoverage(/*inout*/coverageRanges);
            }
        case 2: 
            {
                ClassChainingSubtableHelper classChainingSubtable(this->table, this->tableOffset);
                return classChainingSubtable.ReadLookupCoverage(/*inout*/coverageRanges);
            }
        case 3:
            {
                CoverageChainingSubtableHelper coverageChainingSubtable(this->table, this->tableOffset);
                return coverageChainingSubtable.ReadLookupCoverage(/*inout*/coverageRanges);
            }
        default:
            INPUT_ASSERT_FAIL_MSG("This is an unknown chaining contextual substitution/positioning format.");
            return;
        }
    }
};


// GSUB lookup type 8
struct ReverseChainingSubtableHelper : FontTableHelper
{
    ReverseChainingSubtable const& fontData;
    uint32_t const format;

    ReverseChainingSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        fontData(table.ReadAt<ReverseChainingSubtable>(initialOffset)),
        format(fontData.format)
    { }

    // GSUB lookup type 8 : format 1
    struct Format1Helper
    {
        CoverageOffsetListHelper backtrackCoverages;
        CoverageOffsetListHelper lookaheadCoverages;

        Format1Helper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
        {
            // Since the coverage offset arrays are variable size, setup the offsets now.
            const uint32_t backtrackCoverageListOffset = offsetof(ReverseChainingSubtableFormat1, backtrackGlyphCount);
            backtrackCoverages.Initialize(initialTable, initialOffset + backtrackCoverageListOffset);

            const uint32_t lookaheadCoverageListOffset = backtrackCoverageListOffset + backtrackCoverages.GetByteSize();
            lookaheadCoverages.Initialize(initialTable, initialOffset + lookaheadCoverageListOffset);
        }
    };

    bool UpdateGlyphCoverage(
        uint16_t minGlyphId,
        uint16_t maxGlyphId,
        size_t glyphBitsSize,
        _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
        _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
        ) const
    {
        // Reverse chaining is rare, and specifically designed for Arabic
        // text like Nastaliq (which wouldn't use nominal glyphs anyway),
        // so no special handling. Otherwise, you could do a check similar
        // to that of a coverage based chaining subtable (except that only
        // one input coverage table exists instead of a variable number).

        INPUT_ASSERT_FAIL_MSG(fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + fontData.coverageOffset);
        return coverageTable.IsAnyGlyphCovered(
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits
            );
    }

    void ReadLookupCoverage( // return the number of ranges
        _Inout_ std::vector<GlyphCoverageRange>& coverageRanges
        ) const
    {
        if (fontData.format != 1)
        {
            INPUT_ASSERT_FAIL_MSG("This is an unknown reverse chaining format.");
            return;
        }

        INPUT_ASSERT_FAIL_MSG(fontData.coverageOffset != 0);
        CoverageTableHelper coverageTable(this->table, this->tableOffset + this->fontData.coverageOffset);
        coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);

        Format1Helper substitution(this->table, this->tableOffset);

        // For each coverage (backtrack and lookahead).
        for (uint32_t i = 0; i < 2; ++i)
        {
            CoverageOffsetListHelper coverageList;
            switch (i)
            {
            case 0: coverageList = substitution.backtrackCoverages; break;
            case 1: coverageList = substitution.lookaheadCoverages; break;
            }

            for (uint32_t j = 0; j < coverageList.coverageCount; ++j)
            {
                INPUT_ASSERT_FAIL_MSG(coverageList.coverageOffsets[j] != 0);
                CoverageTableHelper coverageTable(this->table, this->tableOffset + coverageList.coverageOffsets[j]);
                coverageTable.ReadLookupCoverage(/*inout*/coverageRanges);
            }
        }
    }
};


// GSUB lookup type 7, GPOS lookup type 9
struct ExtensionLookupSubtableHelper : FontTableHelper
{
    LookupTableList::Type lookupType;
    uint32_t extensionOffset;

    ExtensionLookupSubtableHelper(FontCheckedPtr const& initialTable, uint32_t initialOffset)
    :   FontTableHelper(initialTable, initialOffset),
        lookupType(LookupTableList::TypeExtensionLookupSub),
        extensionOffset(0)
    {
        if (table.ReadAt<ExtensionLookupSubtable>(tableOffset).format == 1)
        {
            ExtensionLookupSubtableFormat1 const& fontData = table.ReadAt<ExtensionLookupSubtableFormat1>(tableOffset);
            INPUT_ASSERT_FAIL_MSG(fontData.extensionOffset != 0);
            this->lookupType = LookupTableList::Type(uint32_t(fontData.extensionLookupType));
            this->extensionOffset = tableOffset + fontData.extensionOffset;
        }
        else
        {
            INPUT_ASSERT_FAIL_MSG("This is an unknown subtable extension type.");
            // At this point, lookupType will be lookSub, and offset will be 0,
            // so the calling code will not do anything bogus.
        }
    }

    // Extension lookups have no UpdateGlyphCoverage or ReadLookupCoverage
    // because they just point to other lookups and have no coverage themselves.
};


typedef FontTableTree::Item Item;

namespace
{
    uint32_t GetLookupTagFromType(
        LookupTableList::Type lookupType,
        uint32_t tableTag
        )
    {
        switch (tableTag)
        {
        case DWRITE_MAKE_OPENTYPE_TAG('G','S','U','B'):
            switch (lookupType)
            {
            case LookupTableList::TypeSingleSub:            return DWRITE_MAKE_OPENTYPE_TAG('S','N','G','S');
            case LookupTableList::TypeMultipleSub:          return DWRITE_MAKE_OPENTYPE_TAG('M','L','T','S');
            case LookupTableList::TypeAlternateSub:         return DWRITE_MAKE_OPENTYPE_TAG('A','L','T','S');
            case LookupTableList::TypeLigatureSub:          return DWRITE_MAKE_OPENTYPE_TAG('L','I','G','S');
            case LookupTableList::TypeContextualSub:        return DWRITE_MAKE_OPENTYPE_TAG('C','T','X','S');
            case LookupTableList::TypeChainingSub:          return DWRITE_MAKE_OPENTYPE_TAG('C','H','N','S');
            case LookupTableList::TypeExtensionLookupSub:   return DWRITE_MAKE_OPENTYPE_TAG('E','X','T','S');
            case LookupTableList::TypeReverseChainingSub:   return DWRITE_MAKE_OPENTYPE_TAG('R','C','H','S');
            default:                                        return DWRITE_MAKE_OPENTYPE_TAG('?','S','U','B');
            }

        case DWRITE_MAKE_OPENTYPE_TAG('G','P','O','S'):
            switch (lookupType)
            {
            case LookupTableList::TypeSinglePos:            return DWRITE_MAKE_OPENTYPE_TAG('S','N','G','P');
            case LookupTableList::TypePairPos:              return DWRITE_MAKE_OPENTYPE_TAG('P','A','R','P');
            case LookupTableList::TypeCursivePos:           return DWRITE_MAKE_OPENTYPE_TAG('C','R','S','P');
            case LookupTableList::TypeMarkToBasePos:        return DWRITE_MAKE_OPENTYPE_TAG('M','T','B','P');
            case LookupTableList::TypeMarkToLigaturePos:    return DWRITE_MAKE_OPENTYPE_TAG('M','T','L','P');
            case LookupTableList::TypeMarkToMarkPos:        return DWRITE_MAKE_OPENTYPE_TAG('M','T','M','P');
            case LookupTableList::TypeContextualPos:        return DWRITE_MAKE_OPENTYPE_TAG('C','T','X','P');
            case LookupTableList::TypeChainingPos:          return DWRITE_MAKE_OPENTYPE_TAG('C','H','N','P');
            case LookupTableList::TypeExtensionLookupPos:   return DWRITE_MAKE_OPENTYPE_TAG('E','X','T','P');
            default:                                        return DWRITE_MAKE_OPENTYPE_TAG('?','P','O','S');
            }

        default:
            DEBUG_ASSERT_FAIL_MSG("Unknown OpenType table!");
            return DWRITE_MAKE_OPENTYPE_TAG('?','?','?','?');
        }
    }

    uint32_t CompressGlyphCoverageRanges(
        _Inout_updates_(coverageRangesCount) GlyphCoverageRange* coverageRanges,
        uint32_t coverageRangesCount
        )
    {
        std::sort(coverageRanges, coverageRanges + coverageRangesCount);

        uint32_t sourceIndex = 0, destIndex = 0;
        for ( ; sourceIndex < coverageRangesCount; ++sourceIndex)
        {
            GlyphCoverageRange range = coverageRanges[sourceIndex];
            GlyphCoverageRange& destRange = coverageRanges[destIndex - 1];

            if (destIndex > 0 && range.first <= destRange.first + destRange.count)
            {
                // Merge with previous range.
                uint32_t end = std::max(range.first + range.count, destRange.first + destRange.count);
                coverageRanges[destIndex - 1].count = end - destRange.first;
            }
            else
            {
                // Copy distinct range over.
                coverageRanges[destIndex++] = range;
            }
        }

        return destIndex;
    }
}


void ReadFontFile(
    IDWriteFontFace* fontFace,
    _Inout_ FontTableTree& tree,
    uint32_t fontRootIndex
    )
{
    // Read both GSUB and GPOS tables.
    FontTablePtr gsubTable(fontFace, DWRITE_MAKE_OPENTYPE_TAG('G','S','U','B'));
    FontTablePtr gposTable(fontFace, DWRITE_MAKE_OPENTYPE_TAG('G','P','O','S'));

    uint32_t tableCount = (gsubTable.IsNull() ? 0 : 1) + (gposTable.IsNull() ? 0 : 1);
    uint32_t tableRootIndex = tree.AllocateItems(tableCount, true);

    {
        FontTableTree::Item& item   = tree.GetItem(fontRootIndex);
        item.type                   = item.TypeFont;
        item.childIndex             = tableRootIndex;
        item.tag4CC                 = DWRITE_MAKE_OPENTYPE_TAG('s','f','n','t');
    }

    if (!gsubTable.IsNull())
    {
        ReadFontTable(
            gsubTable,
            DWRITE_MAKE_OPENTYPE_TAG('G','S','U','B'),
            tree,
            tableRootIndex
            );
        ++tableRootIndex;
    }
    if (!gposTable.IsNull())
    {
        ReadFontTable(
            gposTable,
            DWRITE_MAKE_OPENTYPE_TAG('G','P','O','S'),
            tree,
            tableRootIndex
            );
    }
}


std::pair<uint32_t, uint32_t> ReadFontTableLookupCoverage(
    FontCheckedPtr const& table,
    uint32_t tableTag,
    _Inout_ std::vector<GlyphCoverageRange>& coverageRanges,
    const LookupTableListHelper& lookup
    )
{
    const uint32_t lookupCoverageRangeBegin = static_cast<uint32_t>(coverageRanges.size());

    for (uint32_t subtableIndex = 0, subtableCount = lookup.subtableCount; subtableIndex < subtableCount; subtableIndex++)
    {
        LookupTableList::Type lookupType = lookup.lookupType;
        uint32_t subtableOffset          = lookup.GetSubtableOffset(subtableIndex);

        switch (tableTag)
        {
        case DWRITE_MAKE_OPENTYPE_TAG('G','S','U','B'):

            if (lookupType == LookupTableList::TypeExtensionLookupSub)
            {
                ExtensionLookupSubtableHelper extension(table, subtableOffset);

                lookupType     = extension.lookupType;
                subtableOffset = extension.extensionOffset;
            }

            switch (lookupType)
            {
            case LookupTableList::TypeSingleSub:
                {
                    SingleSubstitutionSubtableHelper singleSub(table, subtableOffset);
                    singleSub.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeMultipleSub:
                {
                    MultipleSubstitutionSubtableHelper multipleSub(table, subtableOffset);
                    multipleSub.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeAlternateSub:
                {
                    AlternateSubstitutionSubtableHelper alternateSub(table, subtableOffset);
                    alternateSub.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeLigatureSub:
                {
                    LigatureSubstitutionSubtableHelper ligaSub(table, subtableOffset);
                    ligaSub.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeContextualSub:
                {
                    ContextSubtableHelper contextSub(table, subtableOffset);
                    contextSub.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeChainingSub:
                {
                    ChainingSubtableHelper chainingSub(table, subtableOffset);
                    chainingSub.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeExtensionLookupSub:
                // If this was entered, it means the extension type was unknown and not processed.
                break;

            case LookupTableList::TypeReverseChainingSub:
                {
                    ReverseChainingSubtableHelper reverseChainingSub(table, subtableOffset);
                    reverseChainingSub.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            default:
                INPUT_ASSERT_FAIL_MSG("This is an unknown lookup type.");
                break;
            }

            break;

        case DWRITE_MAKE_OPENTYPE_TAG('G','P','O','S'):

            if (lookupType == LookupTableList::TypeExtensionLookupPos)
            {
                ExtensionLookupSubtableHelper extension(table, subtableOffset);

                lookupType      = extension.lookupType;
                subtableOffset  = extension.extensionOffset;
            }

            switch (lookupType)
            {
            case LookupTableList::TypeSinglePos:
                {
                    SinglePositioningSubtableHelper singlePos(table, subtableOffset);
                    singlePos.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypePairPos:
                {
                    PairPositioningSubtableHelper pairPos(table, subtableOffset);
                    pairPos.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeCursivePos:
                {
                    CursivePositioningSubtableHelper cursivePositioningSubtable(table, subtableOffset);
                    cursivePositioningSubtable.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeMarkToBasePos:
                {
                    MarkToBasePositioningSubtableHelper markToBasePos(table, subtableOffset);
                    markToBasePos.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeMarkToLigaturePos:
                {
                    MarkToLigaturePositioningSubtableHelper markToLigaPos(table, subtableOffset);
                    markToLigaPos.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeMarkToMarkPos:
                {
                    MarkToMarkPositioningSubtableHelper markToMarkPos(table, subtableOffset);
                    markToMarkPos.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeContextualPos:
                {
                    ContextSubtableHelper contextSub(table, subtableOffset);
                    contextSub.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeChainingPos:
                {
                    ChainingSubtableHelper chainingSub(table, subtableOffset);
                    chainingSub.ReadLookupCoverage(/*inout*/coverageRanges);
                }
                break;

            case LookupTableList::TypeExtensionLookupPos:
                // If this was entered, it means the extension type was unknown and not processed.
            
                break;

            default:
                INPUT_ASSERT_FAIL_MSG("This is an unknown lookup type.");
                break;
            }

            break;

        default:
            DEBUG_ASSERT_FAIL_MSG("Unknown OpenType table!");
            break;
        }
    }

    uint32_t lookupCoverageRangeEnd = static_cast<uint32_t>(coverageRanges.size());

    // Compress ranges.
    uint32_t compressedCount = CompressGlyphCoverageRanges(coverageRanges.data() + lookupCoverageRangeBegin, lookupCoverageRangeEnd - lookupCoverageRangeBegin);
    lookupCoverageRangeEnd = lookupCoverageRangeBegin + compressedCount;
    coverageRanges.resize(lookupCoverageRangeEnd);

    return std::pair<uint32_t, uint32_t>(lookupCoverageRangeBegin, lookupCoverageRangeEnd - lookupCoverageRangeBegin);
}


void ReadFontTableInternal(
    FontCheckedPtr const& table,
    uint32_t tableTag,
    _Inout_ FontTableTree& tree,
    uint32_t tableRootIndex,
    ReadFontTableOptions options
    )
{
    if (table.IsNull())
        return;

    GxxxHeaderHelper  header(table);
    ScriptListHelper  scriptList (header);
    FeatureListHelper featureList(header);
    LookupListHelper  lookupList (header);

    const uint32_t scriptListRootIndex  = tree.AllocateItems(scriptList.scriptCount,   true, false);
    const uint32_t featureListRootIndex = tree.AllocateItems(featureList.featureCount, true, true);
    const uint32_t lookupListRootIndex  = tree.AllocateItems(lookupList.lookupCount,   true, true);

    {
        FontTableTree::Item& item   = tree.GetItem(tableRootIndex);
        item.type                   = item.TypeTable;
        item.childIndex             = scriptListRootIndex;
        item.tag4CC                 = tableTag;
        item.tableIndex             = -1;
    }

    // Read all the font features.
    for (uint32_t featureIndex = 0; featureIndex < featureList.featureCount; featureIndex++)
    {
        const uint32_t featureLookupListOffset = featureList.GetFeatureLookupListOffset(featureIndex);
        FeatureLookupListHelper featureLookupList(table, featureLookupListOffset);

        const uint32_t featureLookupListRootIndex = tree.AllocateItems(featureLookupList.lookupCount, true);

        {
            FontTableTree::Item& item   = tree.GetItem(featureListRootIndex + featureIndex);
            item.type                   = item.TypeFeature;
            item.tag4CC                 = featureList.features[featureIndex].tag.GetRawInt();
            item.tableIndex             = featureIndex;
            item.tableOffset            = featureLookupListOffset;
            item.childIndex             = featureLookupListRootIndex;
        }

        for (uint32_t j = 0; j < featureLookupList.lookupCount; j++)
        {
            uint16_t lookupIndex = featureLookupList.lookupIndices[j];

            FontTableTree::Item& item   = tree.GetItem(featureLookupListRootIndex + j);
            item.type                   = item.TypeNode;
            item.tableIndex             = j;
               
            if (lookupIndex >= lookupList.lookupCount)
            {
                INPUT_ASSERT_FAIL_MSG("The feature table specifies a lookup index beyond the actual lookup table size.");
                continue;
            }
            item.childIndex = lookupListRootIndex + lookupIndex;
        }
    }

    std::function<void (LanguageFeatureListHelper&, FontTableTree&)> addFeatures =
    [&](LanguageFeatureListHelper& languageFeatureList, FontTableTree& tree) -> void
    {
        // Check whether the default language mandates its own required feature.
        // One occurence of this is in Arial Unicode MS for script Kannada, to
        // reposition the exclamation mark.
        uint32_t featureIndex = languageFeatureList.fontData.requiredFeature;
        if (featureIndex != 0xFFFF && featureIndex < featureList.featureCount)
        {
            const uint32_t languageFeatureListRootIndex = tree.AllocateItems(1, false);
            FontTableTree::Item& item   = tree.GetItem(languageFeatureListRootIndex);
            item.type                   = item.TypeNode;
            item.childIndex             = featureListRootIndex + featureIndex;
            item.flags                 |= item.FlagRequired;
            item.tableIndex             = -1;
        }

        const uint32_t languageFeatureListRootIndex = tree.AllocateItems(languageFeatureList.featureCount, true);
        for (uint32_t featureListIndex = 0; featureListIndex < languageFeatureList.featureCount; ++featureListIndex)
        {
            featureIndex                = languageFeatureList.featureIndices[featureListIndex];
            FontTableTree::Item& item   = tree.GetItem(languageFeatureListRootIndex + featureListIndex);
            item.type                   = item.TypeNode;
            item.childIndex             = (featureIndex < featureList.featureCount) ? featureListRootIndex + featureIndex : 0;
            item.tableIndex             = featureListIndex;
        }
    };

    // Read all the scripts and languages.
    for (uint32_t scriptIndex = 0; scriptIndex < scriptList.scriptCount; ++scriptIndex)
    {
        const uint32_t languageListOffset = scriptList.GetLanguageListOffset(scriptIndex);
        LanguageListHelper languageList(table, languageListOffset);
        const uint32_t defaultLanguageOffset = languageList.fontData.defaultOffset;
        uint32_t languageListRootIndex = tree.AllocateItems(languageList.languageCount + (defaultLanguageOffset != 0 ? 1 : 0), true);

        {
            FontTableTree::Item& item   = tree.GetItem(scriptListRootIndex + scriptIndex);
            item.type                   = item.TypeScript;
            item.tag4CC                 = scriptList.scripts[scriptIndex].tag.GetRawInt();
            item.tableIndex             = scriptIndex;
            item.tableOffset            = languageListOffset;
            item.childIndex             = languageListRootIndex;
        }

        // Check the default language, if there is one.
        if (defaultLanguageOffset != 0)
        {
            const uint32_t languageFeatureListOffset = languageList.tableOffset + defaultLanguageOffset;
            LanguageFeatureListHelper languageFeatureList(table, languageFeatureListOffset);

            {
                FontTableTree::Item& item   = tree.GetItem(languageListRootIndex);
                item.type                   = item.TypeLanguage;
                item.tag4CC                 = 'tlfd';
                item.tableIndex             = -1;
                item.tableOffset            = languageFeatureListOffset;
                item.childIndex             = tree.GetNextAllocatedItemIndex();
            }

            addFeatures(languageFeatureList, tree);
            tree.AppendTerminalItem(); // just in case the feature list is empty (such as in Win8 Segoe UI Symbol GPOS/latn/dflt)
            ++languageListRootIndex;
        }

        // For each language under this script, check for a required feature.
        for (uint32_t languageIndex = 0; languageIndex < languageList.languageCount; ++languageIndex)
        {
            const uint32_t languageFeatureListOffset = languageList.GetLanguageFeatureListOffset(languageIndex);
            LanguageFeatureListHelper languageFeatureList(table, languageFeatureListOffset);

            FontTableTree::Item& item   = tree.GetItem(languageListRootIndex + languageIndex);
            item.type                   = item.TypeLanguage;
            item.tag4CC                 = languageList.languages[languageIndex].tag.GetRawInt();
            item.tableIndex             = languageIndex;
            item.tableOffset            = languageFeatureListOffset;
            item.childIndex             = tree.GetNextAllocatedItemIndex();

            addFeatures(languageFeatureList, tree);
            tree.AppendTerminalItem(); // just in case the feature list is empty
        }
    }

    // Read all the lookups.
    for (uint32_t lookupIndex = 0; lookupIndex < lookupList.lookupCount; lookupIndex++)
    {
        uint32_t tableListOffset = lookupList.GetLookupTableListOffset(lookupIndex);
        std::pair<uint32_t, uint32_t> coverageIndexRange; // (0,0)
        LookupTableListHelper lookup(table, tableListOffset);

        LookupTableList::Type lookupType = lookup.lookupType;
        if (lookup.subtableCount > 0)
        {
            // For extension types, we want to get the actual type.
            // So just pick the first subtable.
            uint32_t subtableOffset = lookup.GetSubtableOffset(0);

            switch (tableTag)
            {
            case DWRITE_MAKE_OPENTYPE_TAG('G','S','U','B'):
                if (lookupType == LookupTableList::TypeExtensionLookupSub)
                {
                    ExtensionLookupSubtableHelper extension(table, subtableOffset);
                    lookupType = extension.lookupType;
                }
                break;

            case DWRITE_MAKE_OPENTYPE_TAG('G','P','O','S'):

                if (lookupType == LookupTableList::TypeExtensionLookupPos)
                {
                    ExtensionLookupSubtableHelper extension(table, subtableOffset);
                    lookupType = extension.lookupType;
                }
                break;
            }
        }

        if (options & ReadFontTableOptionsLookupCoverage)
        {
            coverageIndexRange = ReadFontTableLookupCoverage(
                table,
                tableTag,
                /*inout*/tree.coverageRanges_,
                lookup
                );
        }

        {
            FontTableTree::Item& item   = tree.GetItem(lookupListRootIndex + lookupIndex);
            item.type                   = item.TypeLookup;
            item.tag4CC                 = GetLookupTagFromType(lookupType, tableTag);
            item.tableIndex             = lookupIndex;
            item.tableOffset            = tableListOffset;
            item.extraIndex             = coverageIndexRange.first;
            item.extraCounter           = coverageIndexRange.second;
        }
    } // end for lookupIndex
}


bool ReadFontTable(
    FontCheckedPtr const& table,
    uint32_t tableTag,
    _Inout_ FontTableTree& tree,
    uint32_t tableRootIndex,
    ReadFontTableOptions options
    )
{
    try
    {
        ReadFontTableInternal(
            table,
            tableTag,
            tree,
            tableRootIndex,
            options
            );

        return true;
    }
    catch (const CheckedPtrException&)
    {
        // The font file's table was corrupt, so just keep
        // what we have read of the table so far.
        return false;
    }
}


void MarkMatchingFontFeaturesAsApplicable(
    _In_reads_(desiredFeaturesCount) uint32_t const* desiredFeatures,
    size_t desiredFeaturesCount, // passing zero matches all
    _Inout_ FontTableTree& tree
    )
{
    for (uint32_t i = 0, ci = tree.GetSize(); i < ci; ++i)
    {
        // If the feature wasn't already marked as required by one of the
        // script/language pairs, then check the feature tag to see
        // if it interests us.

        Item& item = tree.GetItem(i);

        if (item.type != item.TypeFeature || (item.flags & item.FlagApplicable))
        {
            continue;
        }

        // The feature was already marked by one of the script/languages.
        if (item.flags & item.FlagRequired)
        {
            item.flags |= item.FlagApplicable;
            continue;
        }

        // Check for matching feature tag to see if applicable.
        uint32_t featureTag = item.tag4CC;
        size_t match = std::find(desiredFeatures, desiredFeatures + desiredFeaturesCount, featureTag) - desiredFeatures;
        if (match == desiredFeaturesCount && desiredFeaturesCount > 0)
        {
            continue; // skip feature since it didn't match any desired
        }

        item.flags |= item.FlagApplicable;
    }
}


bool ReadGlyphCoverage(
    IDWriteFontFace* fontFace,
    _Inout_ std::vector<uint32_t>& interestedGlyphBits,
    _Inout_ std::vector<uint32_t>& simpleGlyphBits,
    _In_reads_(utf32textLength) char32_t const* utf32text,
    _In_ uint32_t utf32textLength
    )
{
    // At the end of this process, we'll have a bit array that tells us for each
    // glyph index, whether it is safe to use the nominal form of (meaning it
    // does not participate in any required complex features).

    std::vector<uint16_t> glyphs(utf32textLength);
    fontFace->GetGlyphIndices(reinterpret_cast<uint32_t const*>(utf32text), utf32textLength, glyphs.data());

    uint16_t minGlyphId = 65535;
    uint16_t maxGlyphId = 0;
    const uint32_t glyphCount = fontFace->GetGlyphCount();

    simpleGlyphBits.resize((glyphCount + 31) / 32);
    //const size_t glyphBitsCount = simpleGlyphBits.size();
    uint32_t* simpleBits = simpleGlyphBits.data();

    // Initialize all the simple bits using the given string, which may be an
    // arbitrary test string or list of all the known simple characters.
    for (char32_t i = 0; i < utf32textLength; ++i)
    {
        // Get the glyph index for this codepoint, and if there is none,
        // jump ahead to the next code point in the font.
        uint16_t glyphId = glyphs[i];
        if (glyphId == 0)
        {
            continue;
        }

        if (glyphId < glyphCount)
        {
            // The glyph is worth checking, so mark it initially as
            // potentially simple.
            SetBit(simpleBits, glyphId);
            if (glyphId < minGlyphId) minGlyphId = glyphId;
            if (glyphId > maxGlyphId) maxGlyphId = glyphId;
        }
    }

    // The bits we're interested in checking further are the same bits
    // we marked as potentially simple. The reason why two separate bitsets
    // are used instead of one is so that logic does not step over itself,
    // mixing input and output (which would make the final bits returned
    // unpredictably dependent or the order of the lookups in the font).

    interestedGlyphBits = simpleGlyphBits;

    return minGlyphId < 65535 && maxGlyphId > 0;
}


void MarkCoveredFontLookupsInternal(
    FontTableTree& tree,
    uint32_t treeRootIndex,
    FontCheckedPtr const& table,
    uint32_t tableTag,
    uint16_t minGlyphId,
    uint16_t maxGlyphId,
    size_t glyphBitsSize,
    _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
    _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
    )
{
    if (table.IsNull())
        return;

    // Clamp the maximum glyph id to the size of the bit array.
    const size_t glyphIdLimit = glyphBitsSize * sizeof(*simpleGlyphBits) * CHAR_BIT;
    maxGlyphId = uint16_t(std::min(size_t(maxGlyphId), glyphIdLimit - 1));

    // Mark the applicable lookups under the given GSUB/GPOS node.
    const uint32_t treeSize = tree.GetSize();
    std::vector<bool> applicableItems(treeSize);

    FontTableTree::ForEachFunction callback =
    [&applicableItems](FontTableTree::Item& item, uint32_t itemIndex, FontTableTree::ForEachMode mode) -> void
    {
        if (mode == FontTableTree::ForEachModeNode
        &&  item.type == item.TypeLookup
        && (item.flags & item.FlagApplicable))
        {
            applicableItems[itemIndex] = true;
        }
    };
    tree.ForEach(treeRootIndex, true, callback);

    GxxxHeaderHelper  header(table);
    LookupListHelper  lookupList(header);

    for (uint32_t i = 0; i < treeSize; ++i)
    {
        if (!applicableItems[i]) // skip lookups under a different node other than the passed root
            continue;

        Item& item = tree.GetItem(i);

        // Test all sublookups.
        LookupTableListHelper lookup(table, lookupList.GetLookupTableListOffset(item.tableIndex));

        bool isAnyGlyphCovered = false;

        for (uint32_t subtableIndex = 0; subtableIndex < lookup.subtableCount; subtableIndex++)
        {
            LookupTableList::Type lookupType = lookup.lookupType;
            uint32_t subtableOffset          = lookup.GetSubtableOffset(subtableIndex);

            switch (tableTag)
            {
            case DWRITE_MAKE_OPENTYPE_TAG('G','S','U','B'):

                if (lookupType == LookupTableList::TypeExtensionLookupSub)
                {
                    ExtensionLookupSubtableHelper extension(table, subtableOffset);

                    lookupType      = extension.lookupType;
                    subtableOffset  = extension.extensionOffset;
                }

                switch (lookupType)
                {
                case LookupTableList::TypeSingleSub:
                    {
                        SingleSubstitutionSubtableHelper singleSub(table, subtableOffset);
                        isAnyGlyphCovered |= singleSub.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeMultipleSub:
                    {
                        MultipleSubstitutionSubtableHelper multipleSub(table, subtableOffset);
                        isAnyGlyphCovered |= multipleSub.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeAlternateSub:
                    {
                        AlternateSubstitutionSubtableHelper alternateSub(table, subtableOffset);
                        isAnyGlyphCovered |= alternateSub.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeLigatureSub:
                    {
                        LigatureSubstitutionSubtableHelper ligaSub(table, subtableOffset);
                        isAnyGlyphCovered |= ligaSub.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeContextualSub:
                    {
                        ContextSubtableHelper contextSub(table, subtableOffset);
                        isAnyGlyphCovered |= contextSub.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeChainingSub:
                    {
                        ChainingSubtableHelper chainingSub(table, subtableOffset);
                        isAnyGlyphCovered |= chainingSub.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeExtensionLookupSub:
                    // If this was entered, it means the extension type was unknown and not processed.
                    break;

                case LookupTableList::TypeReverseChainingSub:
                    {
                        ReverseChainingSubtableHelper reverseChainingSub(table, subtableOffset);
                        isAnyGlyphCovered |= reverseChainingSub.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                default:
                    INPUT_ASSERT_FAIL_MSG("This is an unknown lookup type.");
                    break;
                }

                break;

            case DWRITE_MAKE_OPENTYPE_TAG('G','P','O','S'):

                if (lookupType == LookupTableList::TypeExtensionLookupPos)
                {
                    ExtensionLookupSubtableHelper extension(table, subtableOffset);

                    lookupType      = extension.lookupType;
                    subtableOffset  = extension.extensionOffset;
                }

                switch (lookupType)
                {
                case LookupTableList::TypeSinglePos:
                    {
                        SinglePositioningSubtableHelper singlePos(table, subtableOffset);
                        isAnyGlyphCovered |= singlePos.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypePairPos:
                    {
                        PairPositioningSubtableHelper pairPos(table, subtableOffset);
                        isAnyGlyphCovered |= pairPos.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeCursivePos:
                    {
                        CursivePositioningSubtableHelper cursivePositioningSubtable(table, subtableOffset);
                        isAnyGlyphCovered |= cursivePositioningSubtable.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeMarkToBasePos:
                    {
                        MarkToBasePositioningSubtableHelper markToBasePos(table, subtableOffset);
                        isAnyGlyphCovered |= markToBasePos.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeMarkToLigaturePos:
                    {
                        MarkToLigaturePositioningSubtableHelper markToLigaPos(table, subtableOffset);
                        isAnyGlyphCovered |= markToLigaPos.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeMarkToMarkPos:
                    {
                        MarkToMarkPositioningSubtableHelper markToMarkPos(table, subtableOffset);
                        isAnyGlyphCovered |= markToMarkPos.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeContextualPos:
                    {
                        ContextSubtableHelper contextSub(table, subtableOffset);
                        isAnyGlyphCovered |= contextSub.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeChainingPos:
                    {
                        ChainingSubtableHelper chainingSub(table, subtableOffset);
                        isAnyGlyphCovered |= chainingSub.UpdateGlyphCoverage(minGlyphId, maxGlyphId, glyphBitsSize, interestedGlyphBits, /*inout*/simpleGlyphBits);
                    }
                    break;

                case LookupTableList::TypeExtensionLookupPos:
                    // If this was entered, it means the extension type was unknown and not processed.
                    break;

                default:
                    INPUT_ASSERT_FAIL_MSG("This is an unknown lookup type.");
                    break;
                }

                break;

            default:
                DEBUG_ASSERT_FAIL_MSG("Unknown OpenType table!");
                break;
            }

        } // end for subtableIndex

        if (isAnyGlyphCovered)
            item.flags |= item.FlagCovered;
    }
}


void MarkCoveredFontLookups(
    FontTableTree& tree,
    uint32_t treeRootIndex,
    FontCheckedPtr const& table,
    uint32_t tableTag,
    uint16_t minGlyphId,
    uint16_t maxGlyphId,
    size_t glyphBitsSize,
    _In_reads_(glyphBitsSize) uint32_t const* interestedGlyphBits,
    _Inout_updates_(glyphBitsSize) uint32_t* simpleGlyphBits
    )
{
    // Catch any corrupt GSUB/GPOS tables to avoid outright rejecting an
    // entire font because of bad lookups.
    try
    {
        MarkCoveredFontLookupsInternal(
            tree,
            treeRootIndex,
            table,
            tableTag,
            minGlyphId,
            maxGlyphId,
            glyphBitsSize,
            interestedGlyphBits,
            /*inout*/simpleGlyphBits
            );
    }
    catch (CheckedPtrException const&)
    {
        // The table was corrupt, so mark each glyph as complex. We're not
        // interested in trying to optimize bad fonts.

        for (uint32_t glyphId = minGlyphId; glyphId <= maxGlyphId; ++glyphId)
        {
            if (TestBit(interestedGlyphBits, glyphId))
            {
                ClearBit(simpleGlyphBits, glyphId);
            }
        }
    }
}
