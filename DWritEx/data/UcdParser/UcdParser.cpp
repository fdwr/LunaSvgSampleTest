////////////////////////////////////////////////////////////////////////////////
//
//  Unicode Data Parser
//
//  Date:   2009-08-22
//
////////////////////////////////////////////////////////////////////////////////

// Oh shut up already. Complain about functions that really ARE dangerous, like
// the evil gets(), not innocuous ones.
#define _CRT_SECURE_NO_WARNINGS

#include <stdlib.h>
#include <string.h>
#include <fstream>
#include <sstream>
#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <assert.h>
#include <vector>
#include <map>
#include <set>
#include <basetsd.h>
#include <stdexcept>
#include <limits.h>
#include "stdintForVC.h"
#include "../UcdData.h"

using std::string;
using std::map;
using std::vector;
using std::set;
using std::pair;
using std::make_pair;
using std::ofstream;
using std::ifstream;
using std::stringstream;
using std::hex;
using std::endl;
using std::runtime_error;
using std::min;
using std::max;

#ifdef _countof
#define countof _countf
#else
#define countof(x) (sizeof(x) / sizeof((x)[0]))
#endif

/* todo:
template<typename T, size_t N>
size_t countof(T a[N])
{
 return sizeof(a) / sizeof(a[0]);
}
*/

// We need to be able to accept the full range of Unicode characters
typedef unsigned int char32_t;

// Type to hold the set of attributes for each file we need to parse
typedef std::map<string, string> Attributes;

// Exception attributes are attributes defined as "Exception".  There can be
// multiples of these so it may seem logical to lump all attributes in a
// single multimap.  However multimaps don't have the highly useful operator[].
// Therefore keep track of exceptions seperately.
typedef vector<string> AttributeExceptions;

// Type to hold the binary property data at the start of the file.  This is
// collected seperately to make writing out the binary data in a single pass
// easier.
typedef vector<UcdPropertyInfo>  PropertyDirectory;


// helper function to make reporting errors from I/O functions that set errno
// easier
runtime_error errno_error(string message)
{
    /*
    char errnoString[256] = {0};

    strerror_s(errnoString, countof(errnoString), errno);
    if (errnoString[0] != '\0')
        message = message + ": " + errnoString;
    */

    return runtime_error(message);
}


// Remove the whitespace from the start and end of a string
void Trim(string& str)
{
    size_t begin = 0;
    while (begin != str.length() && isspace((unsigned char) str[begin]))
        ++begin;

    size_t end = str.length();
    while (end > begin && isspace((unsigned char) str[end - 1]))
        --end;

    if (begin == 0)
        str.resize(end);
    else
        str = str.substr(begin, end - begin);
}


// Helper function to retrieve the Unicode plane of a give character
inline uint16_t Plane(char32_t c)
{
    return (uint16_t) (c / 65536);
}


// Binary data is written out in blocks.  The are four levels of blocks.
// Each level contains references to the next level until the last (level 3)
// contains the actual data for a given character.
struct Block
{
    uint32_t level;
    uint32_t refs;
    uint32_t actualSize;
    uint32_t offset;
    uint32_t data[ChildBlockLevels];

    Block(uint32_t level, uint32_t defaultValue) : level(level), refs(1), actualSize(0), offset(0) {std::fill(data, data + ChildBlockLevels, defaultValue);}

    uint32_t&       operator [] (ptrdiff_t x)       {assert(x < ptrdiff_t(ChildBlockLevels)); return data[x];}
    uint32_t const& operator [] (ptrdiff_t x) const {assert(x < ptrdiff_t(ChildBlockLevels)); return data[x];}

    bool operator== (const Block& o) const
    {
        return (level == o.level)
            && (0 == memcmp(data, o.data, sizeof(data)));
    }
};



// Basic class for each file we need to parse.  It stores the attributes of
// that file and after parsing stores all the property data from the file
class UcdFile
{
public:

    static UcdFile* Create(
                const Attributes&           attributes,
                const AttributeExceptions&  exceptions,
                uint16_t                    propindex);

    void           Parse();
    size_t         CountPlanes();
    string         Property()     {return attributes_["Property"];}
    uint16_t       PropertyIndex()     {return propindex_;}

    virtual void WriteHeader(ofstream& header) = 0;
    virtual void WriteBinary(int file, PropertyDirectory& info) = 0;

protected:

    struct UnicodeRange
    {
        char32_t first;
        char32_t last;

        UnicodeRange(char32_t f = 0, char32_t l = 0) : first(f), last(l) {}
        bool operator < (const UnicodeRange& o) const {return first < o.first;}
    };

    typedef map<UnicodeRange, string> RangeValues;
    //typedef vector<string> Fields;


    Attributes          attributes_;
    AttributeExceptions exceptions_;
    uint16_t            propindex_;
    RangeValues         rangeValues_;
    size_t              linenum_;

    vector<string> Split(string line);
    UnicodeRange ParseRange(const string& str);
    virtual void ProcessLineValue(const UnicodeRange& range, string value, RangeValues& ranges) = 0;
    void ProcessExceptions();

    void GenerateLookups(int file, UcdPropertyInfo& propinfo);
    void Relayout(vector<Block>& blocks);
    void CompressBlock(vector<Block>& blocks_, uint32_t b);

    virtual uint32_t DefaultValue() = 0;
    virtual uint32_t ValueOf(RangeValues::iterator rvi) = 0;
    virtual void     ReformatBlock(Block& b) = 0;
    virtual uint32_t ActualBlockSize() = 0;
};


// Parse a file.  Mostly this function extracts the Unicode range and
// associated property value then lets the derived class figure out what
// to do with it.
void UcdFile::Parse()
{
    printf("Reading %s\n", attributes_["File"].c_str());

    ifstream file(attributes_["File"].c_str());
    string   line;

    //-todo:delete bool         isFirstRange = true;
    UnicodeRange oldRange;
    string       oldValue;

    while (!getline(file, line).fail())
    {
        ++linenum_;
        vector<string> fields = Split(line);
        if (fields.empty())
            continue;

        UnicodeRange range = ParseRange(fields.at(0));
        string       value = fields.at(1);

        // Input data files often list consecutive characters
        // with the same property value. Try to consolidate them
        // to save space.

        if (range.first == oldRange.last + 1 && value == oldValue)
        {
            oldRange.last = range.last;
            continue;
        }

        if (oldRange.last > 0) // don't process first line
            ProcessLineValue(oldRange, oldValue, rangeValues_);

        oldRange = range;
        oldValue = value;
    }

    ProcessLineValue(oldRange, oldValue, rangeValues_);

    ProcessExceptions();
}


// Handle any exceptions that the control file specifies over the Ucd data
void UcdFile::ProcessExceptions()
{
    return;

#if 0 // todo:read in from a separate file
    RangeValues exceptionRanges;

    // Parse each exception into a seperate Ranges structure
    AttributeExceptions::iterator i;
    for (i = exceptions_.begin(); i != exceptions_.end(); ++i)
    {
        vector<string> fields = Split(*i);
        UnicodeRange   range = ParseRange(fields.at(0));
        string         value = fields.at(1);

        ProcessLineValue(range, value, exceptionRanges);
    }

    if (exceptionRanges.empty())
        return;

    // Merge the real and exception ranges

    RangeValues baseRanges = rangeValues_;
    rangeValues_.clear();

    RangeValues::iterator bi = baseRanges.begin();
    RangeValues::iterator ei = exceptionRanges.begin();
    RangeValues::iterator biend = baseRanges.end();
    RangeValues::iterator eiend = exceptionRanges.end();
    char32_t         highChar = 0;

    while (bi != biend || ei != eiend)
    {
        if (ei != eiend && bi == biend)
        {                                   // Base done, more exception ranges
            rangeValues_.insert(*ei);
            highChar = ei->first.last;
            ++ei;
        }
        else if (ei != eiend && ei->first.first <= bi->first.first)
        {                                   // next exception < next base
            rangeValues_.insert(*ei);
            highChar = ei->first.last;
            ++ei;
        }
        else if (ei != eiend && !rangeValues_.empty() && ei->first.first == highChar + 1)
        {                                   // next exception adjacent last range
            rangeValues_.insert(*ei);
            highChar = ei->first.last;
            ++ei;
        }
        else if (bi != biend && bi->first.last <= highChar)
        {                                   // next base already to low
            ++bi;
        }
        else
        {
            UnicodeRange r = bi->first;
            if (!rangeValues_.empty())           // next base overlaps previous range
                r.first = max(r.first, rangeValues_.begin()->first.last + 1);
            if (ei != eiend)                // next base overlaps next exception
                r.last = min(r.last, ei->first.first - 1);

            rangeValues_[r] = bi->second;
            highChar = r.last;

            if (bi->first.last == highChar)
                ++bi;
        }
    }
#endif
}


// Given a string, ignore anything after the first '#' as a comment, then
// split the rest of the string up assuming semi-colon delimited fields
vector<string> UcdFile::Split(string line)
{
    vector<string> fields;

    size_t comment = line.find('#');
    if (comment != string::npos)
        line.resize(comment);

    size_t begin = 0;
    while (begin != line.length())
    {
        size_t end = line.find(';', begin);
        if (end == string::npos)
            end = line.length();

        string field = line.substr(begin, end - begin);
        Trim(field);
        fields.push_back(field);

        begin = end;
        if (begin != line.length())
            ++begin;
    }

    return fields;
}


// Parse a string containing a Unicode range.  The string is expected to be
// of the form hexnum[..hexnum]
UcdFile::UnicodeRange UcdFile::ParseRange(const string& str)
{
    stringstream stream(str);
    char32_t  startval;
    char32_t  endval;

    stream >> hex >> startval;
    endval = startval;

    if (!stream.eof())
    {
        char dot;
        stream >> dot;
        if (dot != '.')
            throw runtime_error(string("invalid codepoint or codepoint range '") + str + "'");

        if (stream.eof())
            throw runtime_error(string("invalid codepoint or codepoint range '") + str + "'");

        stream >> dot;
        if (dot != '.')
            throw runtime_error(string("invalid codepoint or codepoint range '") + str + "'");

        if (stream.eof())
            throw runtime_error(string("invalid codepoint or codepoint range '") + str + "'");

        stream >> hex >> endval;

        if (!stream.eof())
            throw runtime_error(string("invalid codepoint or codepoint range '") + str + "'");
    }

    return UnicodeRange(startval, endval);
}


// Count the number of planes all the ranges are involved in
size_t UcdFile::CountPlanes()
{
    size_t count = 0;

    uint16_t last_plane = 0;
    bool first_plane = true;

    for (RangeValues::iterator rv = rangeValues_.begin(); rv != rangeValues_.end(); ++rv)
    {
        const UnicodeRange& range = rv->first;

        if (first_plane || Plane(range.first) != last_plane)
            ++count;

        assert(Plane(range.last) == Plane(range.first));

        last_plane = Plane(range.last);
        first_plane = false;
    }

    return count;
}


void UcdFile::GenerateLookups(int file, UcdPropertyInfo& propinfo)
{
    RangeValues::iterator rvi;

    // Initialize the initial lookup table - all code points map to the
    // default value
    vector<Block> blocks_;
    blocks_.push_back(Block(0, 1));                 // level 0 points to level 1
    blocks_.push_back(Block(1, 2));                 // level 1 points to level 2
    blocks_.push_back(Block(2, 3));                 // level 2 points to level 3
    blocks_.push_back(Block(3, DefaultValue()));    // level 3 is all defaults

    blocks_[0].refs = 0x1;
    blocks_[1].refs = 0x100;
    blocks_[2].refs = 0x10000;
    blocks_[3].refs = 0x1000000;

    // Construct the full lookup table.  For each character we have data for,
    // punch down through the lookups and set the value of that character in it's
    // level 3 block.  If we need to write to a block that already has multiple
    // references than create a path.
    for (rvi = rangeValues_.begin(); rvi != rangeValues_.end(); ++rvi)
    {
        char32_t c = rvi->first.first;

        do
        {
            uint8_t b0 = (c >> (ChildBlockBits * 3)) & (ChildBlockLevels - 1);
            uint8_t b1 = (c >> (ChildBlockBits * 2)) & (ChildBlockLevels - 1);
            uint8_t b2 = (c >> (ChildBlockBits * 1)) & (ChildBlockLevels - 1);
            uint8_t b3 = (c >> (ChildBlockBits * 0)) & (ChildBlockLevels - 1);
            uint32_t v = ValueOf(rvi);

            uint32_t level0 = 0;
            uint32_t level1 = blocks_[level0][b0];
            uint32_t level2 = blocks_[level1][b1];
            uint32_t level3 = blocks_[level2][b2];

            if (blocks_[level3].refs != 1)
            {
                --blocks_[level3].refs;
                level3 = (uint32_t) blocks_.size();
                blocks_.push_back(Block(3, DefaultValue()));
                if (blocks_[level2].refs != 1)
                {
                    --blocks_[level2].refs;
                    level2 = (uint32_t) blocks_.size();
                    blocks_.push_back(Block(2, 3));
                    if (blocks_[level1].refs != 1)
                    {
                        --blocks_[level1].refs;
                        level1 = (uint32_t) blocks_.size();
                        blocks_.push_back(Block(1, 2));
                        blocks_[level0][b0] = level1;
                    }
                    blocks_[level1][b1] = level2;
                }
                blocks_[level2][b2] = level3;
            }

            blocks_[level3][b3] = v;

        }
        while (c++ != rvi->first.last);
    }

    if (blocks_.size() > INT16_MAX)
        throw runtime_error("to many blocks");

    // Coalesce identical blocks, starting from level 3 and working up
    for (uint32_t level = 3; level != 0; --level)
    {
        for (uint32_t i = (uint32_t) blocks_.size() - 1; i != 0; --i)
        {
            if (blocks_[i].level != level)
                continue;

            for (uint32_t match = 0; match < i; ++match)
            {
                if (blocks_[match].level != level)
                    continue;

                if (blocks_[i] == blocks_[match])
                {
                    blocks_[match].refs += blocks_[i].refs;
                    blocks_[i].refs = 0;

                    // we found a match, repoint everybody that pointed to the
                    // original block
                    for (uint32_t j = 0; j != blocks_.size(); ++j)
                        for (uint32_t child = 0; child != ChildBlockLevels; ++child)
                            if (blocks_[j].level == (level - 1) && blocks_[j][child] == i)
                                blocks_[j][child] = match;

                    break;
                }
            }
        }
    }

    Relayout(blocks_);

    // Calculate the offset of each block
    uint32_t offset = 0;
    for (size_t i = 0; i != blocks_.size(); ++i)
    {
        if (blocks_[i].refs == 0)
            continue;

        blocks_[i].offset = offset;
        offset += blocks_[i].actualSize;
    }

    // Compress each block
    for (uint32_t i = 0; i != blocks_.size(); ++i)
    {
        if (blocks_[i].refs == 0)
            continue;

        CompressBlock(blocks_, i);
    }

    // Write the blocks
    propinfo.offset = _lseek(file, 0, SEEK_CUR);

    for (size_t b = 0; b != blocks_.size(); ++b)
    {
        if (blocks_[b].refs == 0)
            continue;

        assert(b == 0 || blocks_[b].offset != 0);

        if (-1 == _write(file, &blocks_[b][0], blocks_[b].actualSize))
            throw errno_error("write failure");
    }

    blocks_.size();
}


// By the time we get here we've generated a four-level lookup table
// that handles every character in the entire Unicode range.  This table
// had been optimized so that identical blocks get coalesced to save
// (loads of) space.
//
// We will now undo the optimization for level 3 and make it so that no
// level 2 block will refer to a level 3 block that is also referred to
// by another level 2 block.  This allows us to layout level 2/3 such that
// level 2 can be guaranteed to refer to level 3 using an 8-bit index.
//
// Once that's done we go back and re-optimize level 2/3 such that if two
// level 3 blocks are identical and the second one is reachable using the
// 8-bit index of the parent of the first one, we can throw out the first
// one.
void UcdFile::Relayout(vector<Block>& blocks)
{
    vector<Block> newBlocks;
    map<uint32_t, uint32_t> blockMap;

    // Copy level 0 and 1 blocks
    for (uint32_t i = 0; i != blocks.size(); ++i)
    {
        if (blocks[i].refs == 0)
            continue;

        if (blocks[i].level == 0 || blocks[i].level == 1)
        {
            blockMap[i] = (uint32_t) newBlocks.size();
            newBlocks.push_back(blocks[i]);
            newBlocks.back().actualSize = ChildBlockLevels * sizeof(uint16_t);
        }
    }

    // Copy level 2 and 3 blocks, uncoalescing level 3 blocks that have
    // different parents
    for (uint32_t i = 0; i != blocks.size(); ++i)
    {
        if (blocks[i].refs == 0)
            continue;

        if (blocks[i].level == 2)
        {
            uint32_t parentIndex = (uint32_t) newBlocks.size();
            blockMap[i] = parentIndex;
            newBlocks.push_back(blocks[i]);
            newBlocks.back().actualSize = ChildBlockLevels * sizeof(uint8_t);

            map<uint32_t,uint32_t> childMap;
            for (size_t j = 0; j != ChildBlockLevels; ++j)
            {
                uint32_t oldChildIndex = blocks[i][j];
                uint32_t newChildIndex;

                if (childMap.find(oldChildIndex) == childMap.end())
                {
                    newChildIndex = (uint32_t) newBlocks.size();
                    childMap[oldChildIndex] = newChildIndex;
                    newBlocks.push_back(blocks[oldChildIndex]);
                    ReformatBlock(newBlocks.back());
                    newBlocks[newChildIndex].refs = 0;
                }
                else
                {
                    newChildIndex = childMap[oldChildIndex];
                }

                newBlocks[parentIndex][j] = newChildIndex;
                newBlocks[newChildIndex].refs += 1;
            }
        }
    }

    // Repoint the level 0 and 1 blocks to thier new child locations
    for (uint32_t i = 0; i != newBlocks.size(); ++i)
    {
        if (newBlocks[i].level == 0 || newBlocks[i].level == 1)
        {
            for (uint32_t j = 0; j != ChildBlockLevels; ++j)
                newBlocks[i][j] = blockMap[newBlocks[i][j]];
        }
    }

    // Re-coalesce level 3 blocks that match other level 3 blocks that are
    // within range of the first block's parent
    for (uint32_t parentIndex = (uint32_t) newBlocks.size(); parentIndex != 0; )
    {
        --parentIndex;

        if (newBlocks[parentIndex].level == 2)
        {
            uint32_t childIndex = parentIndex + 1;
            uint32_t childOffset = 0;
            uint32_t increment = min(ActualBlockSize(), (uint32_t) ChildBlockLevels);
            uint32_t maxOffset = 256 * increment;

            for ( ; childIndex != newBlocks.size() && newBlocks[childIndex].level == 3; ++childIndex)
            {
                uint32_t matchIndex = childIndex + 1;
                uint32_t matchOffset = childOffset;
                for ( ; matchIndex != newBlocks.size(); ++matchIndex)
                {
                    if (newBlocks[matchIndex].refs == 0)
                        continue;

                    matchOffset += newBlocks[matchIndex - 1].actualSize;
                    if (matchOffset > maxOffset)
                        break;

                    if (newBlocks[matchIndex] == newBlocks[childIndex])
                    {
                        newBlocks[matchIndex].refs += newBlocks[childIndex].refs;
                        newBlocks[childIndex].refs = 0;

                        for (unsigned int c = 0; c != ChildBlockLevels; ++c)
                            if (newBlocks[parentIndex][c] == childIndex)
                                newBlocks[parentIndex][c] = matchIndex;

                        break;
                    }
                }

                childOffset += newBlocks[childIndex].actualSize;;
            }
        }
    }

    using std::swap;
    swap(blocks, newBlocks);
}


void UcdFile::CompressBlock(vector<Block>& blocks_, uint32_t b)
{
    // Level 3 blocks were already compressed in Relayout
    if (blocks_[b].level == 3)
        return;

    // Level 2 blocks are 1 byte per entry, the value of each entry is the
    // offset from the start of the block to the start of the level 3 block.
    // The offset is in units of 32 bytes (for binary properties) or 256 bytes
    // (for other properties).
    if (blocks_[b].level == 2)
    {
        uint8_t* p = (uint8_t *) &blocks_[b][0];

        for (uint32_t i = 0; i != ChildBlockLevels; ++i)
        {
            uint32_t offset = blocks_[blocks_[b][i]].offset - blocks_[b].offset;
            uint32_t increment = min(ActualBlockSize(), ChildBlockLevels);
            uint32_t compressedOffset = offset / increment;
            assert(compressedOffset < 256 && compressedOffset * increment == offset);

            p[i] = (uint8_t) compressedOffset;
        }

        return;
    }

    // level 0 and 1 have 16-bit entries that specify the offset (in bytes)
    // to each child block.
    uint16_t* p = (uint16_t *) &blocks_[b][0];

    for (uint32_t i = 0; i != ChildBlockLevels; ++i)
    {
        uint32_t offset = blocks_[blocks_[b][i]].offset - blocks_[b].offset;
        if (offset > UINT16_MAX)
            throw runtime_error("offset out of range");

        p[i] = (uint16_t) offset;
    }
}


// Specialization for boolean properties.
class BooleanUcdFile : public UcdFile
{
public:

    virtual void WriteHeader(ofstream& header);
    virtual void WriteBinary(int file, PropertyDirectory& info);

private:

    virtual void ProcessLineValue(const UnicodeRange& range, string value, RangeValues& ranges);

    uint32_t DefaultValue() {return false;};
    uint32_t ValueOf(RangeValues::iterator /* rvi */) {return true;};
    void     ReformatBlock(Block & b);
    uint32_t ActualBlockSize() {return ChildBlockLevels / 8;}
};


// Process lines in a boolean file.
void BooleanUcdFile::ProcessLineValue(const UnicodeRange& range, string value, RangeValues& ranges)
{
    // Boolean files can contain several different categories of boolean
    // properties (e.g. proplist.txt has "WhiteSpace", "Bidi_Control", etc).
    // Each individual category is treated seperately, reject ones that don't
    // apply to this instance.
    if (value != attributes_["Category"])
        return;

    ranges[range] = "";

#if 0 // todo:delete
    // If a property spans multiple planes, break it up to make life easier for
    // the binary writer which wants to only deal with one plane at a time.
    UnicodeRange r;
    r.first = range.first;

    do
    {
        r.last = min(range.last, ((r.first + 0x10000) & ~0xffff) - 1);
        ranges[r] = "";
        r.first = r.last + 1;
    }
    while (r.first < range.last);
#endif
}


// Header output for boolean properties is simple - just create a
// "UcdIsProperty" function that calls into the generic function.
void BooleanUcdFile::WriteHeader(ofstream& header)
{
    string name = attributes_["Property"];

    header << "enum " << name << " {};" << endl
           << endl
           << "inline bool UcdIs" << name << "(char32_t inputChar) "
           << "{return UcdLookupBooleanProperty(UcdProp" << name << ", inputChar);}" << endl
           << endl;
}


// Write binary range data for a boolean property.
void BooleanUcdFile::WriteBinary(int file, PropertyDirectory& info)
{
    UcdPropertyInfo propinfo;
    propinfo.prop = propindex_;

    GenerateLookups(file, propinfo);
    info.push_back(propinfo);
}



void BooleanUcdFile::ReformatBlock(Block& b)
{
    assert(b.level == 3);

    for (unsigned int i = 0; i != ChildBlockLevels; ++i)
    {
        uint32_t v = b[i];
        b[i] = 0;

        if (v)
            b[i / 32] |= 1 << (i % 32);
    }

    b.actualSize = ChildBlockLevels / 8;
}




// Specialization for enumerated properties.
class EnumeratedUcdFile : public UcdFile
{
public:

    virtual void WriteHeader(ofstream& header);
    virtual void WriteBinary(int file, PropertyDirectory& info);

private:

    typedef set<string> Categories;

    Categories categories_;

    virtual void ProcessLineValue(const UnicodeRange& range, string value, RangeValues& ranges);

    uint32_t DefaultValue() {return (uint32_t) std::distance(categories_.begin(), categories_.find(attributes_["DefaultValue"]));}
    uint32_t ValueOf(RangeValues::iterator rvi) {return (uint32_t) std::distance(categories_.begin(), categories_.find(rvi->second));}
    void     ReformatBlock(Block& b);
    uint32_t ActualBlockSize() {return ChildBlockLevels * sizeof(uint8_t);}

};


// Process lines in an enumerated file.
void EnumeratedUcdFile::ProcessLineValue(const UnicodeRange& range, string value, RangeValues& ranges)
{
    ranges[range] = value;

#if 0 // todo:delete
    // If a property spans multiple planes break it up to make life easier for
    // the binary writer which wants to only deal with one plane at a time.
    UnicodeRange r;
    r.first = range.first;

    do
    {
        r.last= min(range.last, ((r.first + 0x10000) & ~0xffff) - 1);
        ranges[r] = value;
        r.first = r.last + 1;
    }
    while (r.first < range.last);
#endif

    // Keep track of each category so we can output an enum later.
    categories_.insert(value);
}


// Write binary range data for an enumerated property.
//
// Note that the value of any give range is equal to the index of that range's
// category within the set of categories.
void EnumeratedUcdFile::WriteBinary(int file, PropertyDirectory& info)
{
    UcdPropertyInfo propinfo;
    propinfo.prop = propindex_;

    GenerateLookups(file, propinfo);
    info.push_back(propinfo);
}




void EnumeratedUcdFile::ReformatBlock(Block& b)
{
    assert(b.level == 3);

    if (categories_.size() > UINT8_MAX)
        throw runtime_error("to many categories");

    uint8_t* p = (uint8_t *) &b[0];

    for (unsigned int i = 0; i != ChildBlockLevels; ++i)
        p[i] = (uint8_t) b[i];

    b.actualSize = ChildBlockLevels * sizeof(uint8_t);
}



// Header output for enumerated properties consists of an enum containing all
// the categories for this property and a "UcdGetProperty" function.
void EnumeratedUcdFile::WriteHeader(ofstream& header)
{
    // Make sure that the default value is in the set of categories.
    categories_.insert(attributes_["DefaultValue"]);

    string& prefix = attributes_["SymbolPrefix"];
    string& type = attributes_["Property"];

    // Figure out the maximum length of all the categories so we can make
    // everything line up neatly.
    size_t width = 0;
    for (Categories::iterator i = categories_.begin(); i != categories_.end(); ++i)
        width = max(width, prefix.length() + i->length());

    // Output the enum
    header << "enum " << type << endl
           << "{" << endl;

    for (Categories::iterator cat = categories_.begin(); cat != categories_.end(); ++cat)
    {
        string name = prefix + *cat;
        if (name.length() < width)
            name += string(width - name.length(), ' ');

        header << "    " << name << " = " << std::distance(categories_.begin(), cat) << "," << endl;
    }

    // Finish off the enum with a sentinal value that effectively gives the
    // total number of categories.  And spit out the Get function.
    header << "    Total" << type << endl
           << "};" << endl
           << endl
           << "inline " << type << " UcdGet" << type << "(char32_t inputChar) {"
           << "return (" << type << ") UcdLookupEnumeratedProperty(UcdProp" << type << ", inputChar);}" << endl
           << endl;
}


// Specialization for value properties.
class ValueUcdFile : public UcdFile
{
public:

    virtual void WriteHeader(ofstream& header);
    virtual void WriteBinary(int file, PropertyDirectory& info);

    ValueUcdFile(int32_t radix) : radix_(radix) {};

private:

    int32_t radix_;

    virtual void ProcessLineValue(const UnicodeRange& range, string value, RangeValues& ranges);
    uint32_t DefaultValue();
    uint32_t ValueOf(RangeValues::iterator rvi);
    void     ReformatBlock(Block& b);
    uint32_t ActualBlockSize();
};


// Process lines in an enumerated file.
void ValueUcdFile::ProcessLineValue(const UnicodeRange& range, string value, RangeValues& ranges)
{
    ranges[range] = value;

#if 0 // todo:delete
    // If a property spans multiple planes break it up to make life easier for
    // the binary writer which wants to only deal with one plane at a time.
    UnicodeRange r;
    r.first = range.first;

    do
    {
        r.last= min(range.last, ((r.first + 0x10000) & ~0xffff) - 1);
        ranges[r] = value;
        r.first = r.last + 1;
    }
    while (r.first < range.last);
#endif
}


// Write binary range data for a hex property (like bidi mirroring
// character pairs).
void ValueUcdFile::WriteBinary(int file, PropertyDirectory& info)
{
    UcdPropertyInfo propinfo;
    propinfo.prop = propindex_;

    GenerateLookups(file, propinfo);
    info.push_back(propinfo);
}


uint32_t ValueUcdFile::DefaultValue()
{
    return 0;
}


uint32_t ValueUcdFile::ValueOf(RangeValues::iterator rvi)
{
    return strtol(rvi->second.c_str(), NULL, radix_);
}


void ValueUcdFile::ReformatBlock(Block& b)
{
    b.actualSize = ChildBlockLevels * sizeof(uint32_t);
}


uint32_t ValueUcdFile::ActualBlockSize()
{
    return ChildBlockLevels * sizeof(uint32_t);
}


// Header output for hex-value properties consists of just a "UcdGetProperty"
// that calls into the generic function, exactly like enumerated properties,
// except that the numeric value is explicitly given.
void ValueUcdFile::WriteHeader(ofstream& header)
{
    string& name = attributes_["Property"];
    string& def = attributes_["DefaultValue"];

    header << "inline int32_t UcdGet" << name << "(char32_t inputChar) "
           << "{return UcdLookupValueProperty(UcdProp" << name << ", inputChar, " << def << ");}" << endl
           << endl;
}


// Given a set of attributes describing the type we need to parse and it's
// file, create the appropriate derived file parser.
UcdFile* UcdFile::Create(
    const Attributes&          attributes,
    const AttributeExceptions& exceptions,
    uint16_t                   propindex
    )
{
    UcdFile* file;

    if (attributes.find("Type") == attributes.end())
        throw runtime_error("Missing required 'Type' attribute");

    const string& dataType = attributes.find("Type")->second;
    if (dataType == "Boolean")
        file = new BooleanUcdFile;
    else if (dataType == "Enumeration")
        file = new EnumeratedUcdFile;
    else if (dataType == "DecimalValue")
        file = new ValueUcdFile(10);
    else if (dataType == "HexValue")
        file = new ValueUcdFile(16);
    else
        throw runtime_error(string("Unknown type in control file '") + dataType + "'");

    file->attributes_ = attributes;
    file->exceptions_ = exceptions;
    file->propindex_ = propindex;

    // If no symbol prefix was specified create one that is the same as the
    // generated type.
    if (file->attributes_["SymbolPrefix"].empty())
    {
        file->attributes_["SymbolPrefix"] = file->attributes_["Property"];
    }

    return file;
}



// The set of all files we need to parse
typedef vector<UcdFile *> Files;
typedef map<string, string> ControlAttributes;
ControlAttributes g_control;


// Parse the control file, extract each property, associated file, and other
// attributes, and create the right parser for that file.
void ParseControlFile(const string& filename, Files& files)
{
    ifstream control(filename.c_str());
    if (control.fail())
        throw errno_error(string("Unable to open control file '") + filename + "'");

    string              line;
    Attributes          attributes;
    AttributeExceptions exceptions;
    uint16_t            propindex = 0;

    while (!getline(control, line).fail())
    {
        // skip comments or empty lines
        size_t comment = line.find('#');
        if (comment != string::npos)
            line.resize(comment);

        if (line.empty())
            continue;

        // each line is expected to be of the form attribute=value
        size_t delim = line.find('=');
        if (delim == string::npos || delim == 0)
            throw runtime_error(string("Malformed attribute=value element '") + line + "'");

        string attribute = line.substr(0, delim);
        string value     = line.substr(delim + (delim != line.length()));
        Trim(value);

        // When a File attribute is hit, create the parser for the previous
        // set of attributes and start accumulating the new set.
        if (attribute == "Property")
        {
            if (propindex == 0)
                g_control = attributes;
            else
                files.push_back(UcdFile::Create(attributes, exceptions, propindex));

            attributes.clear();
            exceptions.clear();
            ++propindex;
        }

        if (attribute == "Exception")
            exceptions.push_back(value);
        else
            attributes[attribute] = value;
    }

    files.push_back(UcdFile::Create(attributes, exceptions, propindex));

    // Default values for control attributes

    if (g_control.find("GeneratedHeader") == g_control.end())
        g_control["GeneratedHeader"] = "UcdProperties.h";

    if (g_control.find("GeneratedBinary") == g_control.end())
        g_control["GeneratedBinary"] = "UcdData.bin";
}


// Write global header data.  This consists of the standard file header and
// global list of all properties.
void WriteHeaderMetaData(ofstream& header, Files& files)
{
    header << "//+----------------------------------------------------------------------------" << endl
           << "//" << endl
           << "//  This file was generated by ucdtool.exe." << endl
           << "//  DO NOT HAND MODIFY" << endl
           << "//" << endl
           << "//  Contents: Generated Unicode data classification functions and enumerations" << endl
           << "//" << endl
           << "//-----------------------------------------------------------------------------" << endl
           << endl
           << "#pragma once" << endl
           << endl
           << "enum UcdProperty;" << endl
           << endl
           << "bool    UcdLookupBooleanProperty(UcdProperty prop, char32_t inputChar);" << endl
           << "int32_t UcdLookupEnumeratedProperty(UcdProperty prop, char32_t inputChar);" << endl
           << "int32_t UcdLookupValueProperty(UcdProperty prop, char32_t inputChar, int32_t defaultValue);" << endl
           << endl
           << "enum UcdProperty" << endl
           << "{" << endl;

    Files::iterator file;
    for (file = files.begin(); file != files.end(); ++file)
        header << "    UcdProp" << (*file)->Property() << " = " << (*file)->PropertyIndex() << "," << endl;

    header << "    TotalUcdProps = " << files.back()->PropertyIndex() + 1 << endl
           << "};" << endl
           << endl;
}


// Central point for all logic
void ParseAndGenerate()
{
    Files files;
    Files::iterator file;

    // Read the set of properties we care about and go parse each one
    ParseControlFile("Tables.txt", files);

    for (file = files.begin(); file != files.end(); ++file)
        (*file)->Parse();

    string headerName = g_control["GeneratedHeader"];
    string binaryName = g_control["GeneratedBinary"];

#if 0 // todo:don't actually write any output file

    // Create the header
    ofstream header(headerName.c_str());
    if (header.fail())
        throw errno_error(string("Unable to open '") + headerName + "'");

    //header.exceptions(ofstream.failbit);
    WriteHeaderMetaData(header, files);

    // Figure out how many property directory entries we're going to need.
    size_t propranges = 0;
    for (file = files.begin(); file != files.end(); ++file)
        propranges += (*file)->CountPlanes();

    PropertyDirectory binaryinfo;
    binaryinfo.reserve(propranges);

    // Create the binary file and seek to the point where property range data
    // will start being written.
    int binfile = _open(
                        binaryName.c_str(),
                        _O_CREAT | _O_TRUNC | _O_BINARY | _O_WRONLY | _O_SEQUENTIAL, _S_IWRITE);

    if (-1 == binfile)
        throw errno_error(string("Unable to create '") + binaryName + "'");

    if (-1 == _lseek(binfile, (long) (sizeof(UcdFileHeader) + propranges * sizeof(UcdPropertyInfo)), SEEK_SET))
        throw errno_error("_lseek failure");

    // Write header and binary info for each file
    for (file = files.begin(); file != files.end(); ++file)
    {
        (*file)->WriteHeader(header);
        (*file)->WriteBinary(binfile, binaryinfo);
    }

    // Now that we know the offsets for each property directory entry, seek
    // back to the start of the binary file and write them out.

#pragma warning(push)
#pragma warning(disable:4815)   // zero-sized array on stack will have no elements
    UcdFileHeader fileheader;
#pragma warning(pop)

    fileheader.properties_count = (unsigned int) binaryinfo.size();

    if (-1 == _lseek(binfile, 0, SEEK_SET))
        throw errno_error("_lseek failure");

    if (-1 == _write(binfile, &fileheader, sizeof(fileheader)))
        throw errno_error("_write failure");

    if (-1 == _write(binfile, &binaryinfo[0], (unsigned) (binaryinfo.size() * sizeof(UcdPropertyInfo))))
        throw errno_error("_write failure");

    _close(binfile);

    printf("%s and %s created successfully\n", headerName.c_str(), binaryName.c_str());
#endif
}


// Mostly just collect and report any errors
int __cdecl main()
{
    try
    {
        ParseAndGenerate();
    }
    catch (const std::exception& e)
    {
        printf("ucdtool error: %s\n", e.what());
    }
    printf("Done.\n");
    getchar();

    return EXIT_SUCCESS;
}
