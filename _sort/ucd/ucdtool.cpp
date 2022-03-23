//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Parser for Unicode property files
//
//  Author:     Michael Warning (mikew@microsoft.com)
//
//  History:    10-05-2007  mikew  Created
//
//----------------------------------------------------------------------------

#include <std.h>
#include <fstream>
#include <sstream>
#include <io.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <assert.h>
#include "UcdData.h"

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

// We need to be able to accept the full range of Unicode characters
typedef unsigned int char32_t;

// Type to hold the set of attributes for each file we need to parse
typedef std::map<string, string> Attributes;

// Exception attributes are attributes defined as "Exception", which allow
// overriding the value assigned to a given codepoint. There can be multiples
// of these so it may seem logical to lump all attributes in a single multimap.
// However multimaps don't have the highly useful operator[]. Therefore, keep
// track of exceptions seperately.
typedef vector<string> ExceptionAttributes;

// Enum value attributes are attributes defined as "Enum", which allow custom
// assignment of values.
typedef vector<string> EnumAttributes;

// Rules allow production of properties from other properties.
typedef vector<string> RuleStrings;

// Type to hold the binary property data at the start of the file.  This is
// collected seperately to make writing out the binary data in a single pass
// easier.
typedef vector<UcdPropertyInfo> PropertyDirectory;

// The set of all files we need to parse
class UcdFile;

typedef vector<UcdFile *> Files;
typedef map<string, string> ControlAttributes;

ControlAttributes g_control;


#pragma warning(disable:4100) // unreferenced parameter (perfectly valid..)
#pragma warning(disable:4481) // 'override' is offically standard C++, not an extension


const char32_t UnicodeCodePointTotal = 0x110000;

// helper function to make reporting errors from I/O functions that set errno
// easier
runtime_error errno_error(string message)
{
    char errnoString[256] = {0};

    strerror_s(errnoString, ARRAY_SIZE(errnoString), errno);
    if (errnoString[0] != '\0')
        message = message + ": " + errnoString;

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
inline uint32_t Plane(char32_t c)
{
    return uint32_t(c / 65536);
}

inline uint32_t RoundUpPlane(char32_t c)
{
    return uint32_t((c + 65536) & ~65535);
}

bool TestAndSet(uint8_t* bits, size_t bitIndex)
{
    // Test the bit and set it.
    const uint8_t mask = 1 << (bitIndex & 7);
    const uint8_t existingBit = bits[bitIndex >> 3] & mask;
    bits[bitIndex >> 3] |= mask;
    return !!existingBit;
}


void SkipFileBom(ifstream& file)
{
    char bom[4]; // EF BB BF
    if (file.peek() == 0xEF)
    {
        file.get(bom, ARRAY_SIZE(bom)); // Just skip it
    }
}


void Format(string& returnString, const char* formatString, ...) 
{
    // Appends to a std::string rather than raw character buffer or ios stream.

    if (formatString != nullptr)
    {
        va_list vargs = nullptr;
        va_start(vargs, formatString); // initialize variable arguments

        const size_t increasedLen = _vscprintf(formatString, vargs) + 1; // Get string length, plus one for NUL
        const size_t oldLen = returnString.size();
        const size_t newLen = oldLen + increasedLen;
        returnString.resize(newLen);
        _vsnprintf_s(&returnString[oldLen], increasedLen, increasedLen, formatString, vargs);   
        returnString.resize(newLen - 1); // trim off the NUL

        va_end(vargs); // Reset variable arguments
    }
}


void UnderscoreString(string& name)
{
    // Some enumerations have spaces or dashes in them, which will cause
    // compilation errors when used as identifier names.

    std::transform(
        name.begin(),
        name.end(),
        name.begin(),
        [](char c) { return (c == ' ' || c == '-') ?  '_' : c; }
        );
}


// Binary data is written out in blocks.  The are four levels of blocks.
// Each level contains references to the next level until the last (level 3)
// contains the actual data for a given character.
struct Block
{
    uint32_t level;
    uint32_t refs;
    uint32_t actualByteSize;
    uint32_t offset;
    uint32_t match; // index of identical block
    uint32_t data[ChildBlockLevels];

    Block(uint32_t level, uint32_t defaultValue) : level(level), refs(1), actualByteSize(0), offset(0), match(~0u) {std::fill(data, data + ChildBlockLevels, defaultValue);}

    uint32_t&       operator [] (ptrdiff_t x)       {assert(x < ChildBlockLevels); return data[x];}
    uint32_t const& operator [] (ptrdiff_t x) const {assert(x < ChildBlockLevels); return data[x];}

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
    typedef vector<string> Fields;    

    static UcdFile* Create(
        const Attributes&           attributes,
        const ExceptionAttributes&  exceptions,
        const EnumAttributes&       enums,
        const RuleStrings&          ruleStrings
        );

    void            ParseText();
    void            ApplyExceptions();
    void            GenerateText(const Files& files);
    void            ProcessRules(const Files& files);
    void            PreparseRules(const Files& files);
    string          Property() {return attributes_["Property"];}
    size_t          CountPlanes() const;

    virtual bool    IsStoredProperty() {return GetBoolean(attributes_["IsStoredProperty"], true);}
    virtual void    WriteCodeHeader(ofstream& header) = 0;
    virtual void    WriteBinary(int file) = 0;

    static Fields   Split(string line, char delimiter = ';');
    static bool     GetBoolean(const string& value, bool defaultValue = false);

    struct UnicodeRange 
    {
        char32_t first; 
        char32_t last;

        UnicodeRange(char32_t f = 0, char32_t l = 0) : first(f), last(l) {}
        bool operator < (const UnicodeRange& o) const
        {
            return last < o.first;
        }
        bool operator < (const char32_t c) const
        {
            return first < c;
        }
    };

    struct Rule
    {
        enum Action
        {
            ActionFirst = 0,
            ActionNop = ActionFirst,
            ActionCase,     // select case and use the given name if all conditions true
            ActionSelect,   // select property and use existing value if all conditions true
            ActionAssert,   // satisfied only when all the conditions are true (assert and)
            ActionAssertAny,// satisfied if any of the conditions are true (assert or)
            ActionAssertNot,// satisfied only when none the conditions are true
            ActionIn,       // in the given set of property values; ch ∈ A
            ActionOut,      // not in the given set; ch ∉ A
            ActionAnd,      // all the conditions are true; A ∩ B
            ActionOr,       // any of the conditions are true; A ∪ B
            ActionNot,      // none of the conditions are true; U - (A ∪ B)
            ActionRange,    // within a given range
            ActionTotal,
            ActionInvalid = ActionTotal
        };

        string name;                        // identifier other rules can use to refer to this one
        string propertyName;                // the property name used (if present), used by In/Out/Select
        RuleStrings parameters;             // list of variables 0..n

        Action action;                      // type of action
        uint32_t propIndex;                 // property index for informational properties, used by In/Out/Select
        UnicodeRange valueCharacterRange;   // last character the cached value was evaluated for
        bool value;                         // cached value for rule evaluation
        string valueString;                 // cached value for rule evaluation

        Rule()
        :   action(),
            valueCharacterRange(UnicodeRange(UnicodeCodePointTotal, UnicodeCodePointTotal)),
            propIndex(),
            value()
        { }
    };

protected:
    typedef map<UnicodeRange, string> Ranges;
    typedef std::vector<Rule> Rules;
    typedef map<const string, uint32_t> RuleIndexLookups;

    Attributes          attributes_;
    ExceptionAttributes exceptions_;
    EnumAttributes      enums_;
    Ranges              ranges_;
    RuleStrings         ruleStrings_;
    Rules               rules_;
    RuleIndexLookups    ruleIndexLookups_;

    UnicodeRange ParseRange(const string& str);
    virtual bool ShouldProcessLineValue(const string& value);
    virtual void ProcessLineValue(const UnicodeRange& range, const string& value, Ranges& ranges);
    bool GetRuleValue(const Files& files, Rule& rule, char32_t ch);
    uint32_t GetRuleIndex(const string& name) const;
    static const char* GetCharacterName(char32_t ch, const Ranges* characterNameRanges, const Ranges* blockNameRanges);
    void RuleAssertionFailure(const Rule& rule, char32_t ch) const;
    void BuildPrintableRuleStrings(string& str, string linePrefix, bool showValues) const;

    void GenerateLookups(int file);
    void Relayout(vector<Block>& blocks);
    void CompressBlock(vector<Block>& blocks_, uint32_t b);

    virtual uint32_t DefaultValue() = 0;
    virtual uint32_t ValueOf(Ranges::iterator rvi) = 0;
    virtual void     ReformatBlock(Block& b) = 0;
    virtual uint32_t ActualBlockByteSize() = 0;
};


// Parse a file.  Mostly this function extracts the Unicode range and 
// associated property value then lets the derived class figure out what
// to do with it.
void UcdFile::ParseText()
{
    const string& fileName = attributes_["FileIn"];
    if (fileName.empty())
    {
        return;
    }

    printf("Reading %s from %s\n", Property().c_str(), fileName.c_str());

    ifstream file(fileName.c_str());
    string   line;
    uint32_t lineNumber = 0;
    std::vector<uint8_t> usedCodepoints(UnicodeCodePointTotal / 8);

    SkipFileBom(file);

    bool         firstrange = true;
    UnicodeRange oldrange;
    string       oldvalue;

    // Pick the second column after the range if not specified.
    const size_t column = attributes_["Column"].empty() ? 1 : atoi(attributes_["Column"].c_str());

    while (!getline(file, line).fail())
    {
        ++lineNumber;
        const Fields fields = Split(line);
        if (fields.empty())
            continue;

        UnicodeRange range = ParseRange(fields.at(0));
        if (fields.size() <= column)
        {
            stringstream str;
            str << "Data line is missing column " << column << "field: " << fields.at(0) << " in " << fileName.c_str() << ":" << lineNumber;
            throw runtime_error(str.str());
        }

        const string& value = fields.at(column);

        if (range.last < range.first)
        {
            stringstream str;
            str << "Inverted range: " << fields.at(0) << " in " << fileName.c_str() << ":" << lineNumber;
            throw runtime_error(str.str());
        }

        if (!ShouldProcessLineValue(value))
        {
            continue;
        }

        // Check for range overlap.
        for (char32_t i = range.first; i <= range.last; ++i)
        {
            if (TestAndSet(&usedCodepoints.front(), i))
            {
                stringstream str;
                str << "Overlapping ranges: " << fields.at(0) << " in " << fileName.c_str() << ":" << lineNumber;
                throw runtime_error(str.str());
            }
        }

        // It common for the input data files to list consecutive
        // characters with the same property value, so consolidate them
        // to save space.

        if (!firstrange)
        {
            if (range.first == oldrange.last + 1 && value == oldvalue)
            {
                oldrange.last = range.last;
                continue;
            }

            ProcessLineValue(oldrange, oldvalue, ranges_);
        }

        oldrange = range;
        oldvalue = value;
        firstrange = false;
    }

    if (!firstrange)
    {
        ProcessLineValue(oldrange, oldvalue, ranges_);
    }
}


// Handle any exceptions that the control file specifies over the UCD data
void UcdFile::ApplyExceptions()
{
    Ranges exceptionRanges;

    if (exceptions_.empty())
        return;

    printf("Applying exceptions %s\n", Property().c_str());

    // Parse each exception into a separate Ranges structure
    ExceptionAttributes::iterator i;
    for (i = exceptions_.begin(); i != exceptions_.end(); ++i)
    {
        Fields       fields = Split(*i);
        UnicodeRange range = ParseRange(fields.at(0));
        string       value = fields.at(1);

        if (ShouldProcessLineValue(value))
        {
            ProcessLineValue(range, value, exceptionRanges);
        }
    }

    if (exceptionRanges.empty())
        return;

    // Merge the real and exception ranges

    Ranges baseRanges;
    std::swap(ranges_, baseRanges); // clears the ranges

    Ranges::iterator bi = baseRanges.begin();
    Ranges::iterator ei = exceptionRanges.begin();
    Ranges::iterator biend = baseRanges.end();
    Ranges::iterator eiend = exceptionRanges.end();
    char32_t         highChar = 0;

    while (bi != biend || ei != eiend)
    {
        if (ei != eiend && bi == biend)
        {                                   // Base done, more exception ranges
            ranges_.insert(*ei);                
            highChar = ei->first.last;
            ++ei;
        }
        else if (ei != eiend && ei->first.first <= bi->first.first)
        {                                   // next exception < next base
            ranges_.insert(*ei);
            highChar = ei->first.last;
            ++ei;
        }
        else if (ei != eiend && !ranges_.empty() && ei->first.first == highChar + 1)
        {                                   // next exception adjacent last range
            ranges_.insert(*ei);
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
            if (!ranges_.empty())           // next base overlaps previous range
                r.first = max(r.first, ranges_.begin()->first.last + 1);
            if (ei != eiend)                // next base overlaps next exception
                r.last = min(r.last, ei->first.first - 1);

            ranges_[r] = bi->second;
            highChar = r.last;

            if (bi->first.last == highChar)
                ++bi;
        }
    }    
}


// Given a string, ignore anything after the first '#' as a comment, then
// split the rest of the string up assuming semi-colon deliminated fields
UcdFile::Fields UcdFile::Split(string line, char delimiter)
{
    Fields fields;

    size_t comment = line.find('#');
    if (comment != string::npos)
        line.resize(comment);
    
    size_t begin = 0;
    while (begin != line.length())
    {
        size_t end = line.find(delimiter, begin);
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



bool UcdFile::GetBoolean(const string& value, bool defaultValue)
{
    if (value.empty())
        return defaultValue;

    if (value == "true")
        return true;

    return false;
}


// Parse a string containing a Unicode range.  The string is expected to be
// of the form hexnum[..hexnum]
UcdFile::UnicodeRange UcdFile::ParseRange(const string& str)
{
    stringstream stream(str);
    char32_t  first;
    char32_t  last;

    stream >> hex >> first;
    last = first;

    if (!stream.eof())
    {
        char dot;
        stream >> dot;
        if (dot != '.' || stream.eof())
            throw runtime_error(string("Invalid codepoint or codepoint range '") + str + "'");
    
        stream >> dot;
        if (dot != '.' || stream.eof())
            throw runtime_error(string("Invalid codepoint or codepoint range '") + str + "'");

        stream >> hex >> last;

        if (!stream.eof())
            throw runtime_error(string("Invalid codepoint or codepoint range '") + str + "'");
    }

    return UnicodeRange(first, last);
}


bool UcdFile::ShouldProcessLineValue(const string& value)
{
    return true; // subclasses may override depending on value
}


void UcdFile::ProcessLineValue(const UnicodeRange& range, const string& value, Ranges& ranges)
{
    ranges[range] = value;
}


namespace
{
    struct
    {
        uint8_t minimumFieldCount;
        char* name;
        char* example;
    } 
    const static g_ruleActions[/*Rule::ActionTotal*/] = {
        /* ActionNop       */ 1, "Nop",       "DoNothingRule: Nop",
        /* ActionCase      */ 2, "Case",      "Case U IsUpright IsIdeographic",
        /* ActionSelect    */ 2, "Select",    "Select GeneralCategory",
        /* ActionAssert    */ 2, "Assert",    "Assert IsValidOrientation",
        /* ActionAssertAny */ 2, "AssertAny", "AssertAny IsMarkedComplex IsActuallySimple",
        /* ActionAssertNot */ 2, "AssertNot", "AssertNot IsInconsistent IsBogus",
        /* ActionIn        */ 2, "In",        "IsStrongBidi: In Bidi L R AL",
        /* ActionOut       */ 2, "Out",       "IsNotControl: Out GeneralCategory Cf Cc",
        /* ActionAnd       */ 3, "And",       "IsBidiPair: And IsGenCatPePs IsMirrored",
        /* ActionOr        */ 3, "Or",        "IsIdeographic: Or IsIdeographicBlock IsIdeographicLineBreak",
        /* ActionNot       */ 2, "Not",       "CanRotate: Not IsIdeographic IsUpright",
        /* ActionRange     */ 2, "Range",     "Range: Range E000..F8FF",
    };
    static_assert(ARRAY_SIZE(g_ruleActions) == UcdFile::Rule::ActionTotal, "Update array to new Rule::ActionTotal");
}


void UcdFile::PreparseRules(const Files& files)
{
    // Parse each rule string into an easier to process rule structure.

    uint32_t ruleIndex = 0;

    for (RuleStrings::iterator it = ruleStrings_.begin(); it != ruleStrings_.end(); ++it, ++ruleIndex)
    {
        // Rules consist of a name (optional), action, and parameters.

        Rule& rule = rules_[ruleIndex];

        // Split name, rule, and parameters
        Fields fields = Split(*it, ' ');
        if (fields.size() < 1)
        {
            throw runtime_error(string("Rule needs an action '") + *it + "' (example: IsStrongBidi: In Bidi L R AL)");
        }

        // Look for rule name, and if present, remove the colon,
        // assign the name, and shift fields forward.
        const size_t ruleNameSize = fields[0].find(':');
        if (ruleNameSize != string::npos)
        {
            fields[0].resize(ruleNameSize);
            rule.name = fields[0];
            fields.erase(fields.begin());
        }

        if (fields.size() < 1)
        {
            throw runtime_error(string("Rule needs an action '") + *it + "' (example: IsStrongBidi: In Bidi L R AL)");
        }

        // Map action to enum
        const string& actionString = fields[0];
        rule.action = Rule::ActionInvalid;
        for (uint32_t i = Rule::ActionFirst; i < rule.ActionTotal; ++i)
        {
            if (actionString.compare(g_ruleActions[i].name) == 0)
            {
                rule.action = Rule::Action(i);
                break;
            }
        }

        if (rule.action == Rule::ActionInvalid)
        {
            throw runtime_error(string("Unknown rule action '") + actionString + "' from '" + *it + "' (case-sensitive)");
        }

        if (fields.size() < g_ruleActions[rule.action].minimumFieldCount)
        {
            throw runtime_error(string("Rule missing parameters '")
                                + *it
                                + "' (example: " + g_ruleActions[rule.action].example + ")"
                                );
        }

        // Add the rule's name to the lookup.
        if (ruleIndexLookups_.find(rule.name) != ruleIndexLookups_.end())
        {
            throw runtime_error(string("Duplicate rule name in '") + *it + "'");
        }
        ruleIndexLookups_[rule.name] = ruleIndex;

        // Do rule specific string processing here, and store the delimited fields
        // in the rule strings.
        switch (rule.action)
        {
        case Rule::ActionIn:
        case Rule::ActionOut:
        case Rule::ActionSelect:
            {
                // Determine property index from name.

                const string& propertyName = fields.at(1);
                const uint32_t invalidPropIndex = ~0u;
                rule.propIndex = invalidPropIndex; // assign an invalid value

                uint32_t propIndex = 0;
                for (Files::const_iterator fileIt = files.begin(); fileIt != files.end(); ++fileIt, ++propIndex)
                {
                    UcdFile& file = **fileIt;
                    if (file.Property() == propertyName)
                    {
                        rule.propertyName = propertyName;
                        rule.propIndex = propIndex;
                        break;
                    }
                }

                if (rule.propIndex == invalidPropIndex)
                {
                    throw runtime_error(string("Non-existant property used '") + propertyName + "' from '" + *it + "' (case-sensitive)");
                }

                // Remainder parameters are rule conditions/property names.
                rule.parameters.assign(fields.begin() + 2, fields.end());
            }
            break;

        case Rule::ActionAnd:
        case Rule::ActionOr:
        case Rule::ActionNot:
        case Rule::ActionRange:
            // Remainder parameters are subrules or ranges.
            rule.parameters.assign(fields.begin() + 1, fields.end());
            break;

        case Rule::ActionCase:
            // Remainder parameters are rule conditions.
            rule.valueString = fields.at(1);
            rule.parameters.assign(fields.begin() + 2, fields.end());
            break;

        case Rule::ActionNop:
            break;

        case Rule::ActionAssert:
        case Rule::ActionAssertAny:
        case Rule::ActionAssertNot:
            rule.valueString = *it;
            rule.parameters.assign(fields.begin() + 1, fields.end());
            break;
        }
    }
}


void UcdFile::ProcessRules(const Files& files)
{
    // Process rules for any characters without an existing value,
    // lazily and recursively checking rules.

    if (ruleStrings_.empty())
        return;

    printf("Processing rules %s ", Property().c_str());

    rules_.resize(ruleStrings_.size());

    // Parse the strings into actions and parameters.
    PreparseRules(files);

    // Can take a while, so draw little progress bar.
    printf("_________________\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");

    // Determine the truth of each rule, and select an appropriate value.
    for (char32_t ch = 0; ch < UnicodeCodePointTotal; ++ch)
    {
        UnicodeRange r(ch, ch);

        if (ranges_.find(r) == ranges_.end())
        {
            // No existing value for this character, so derive one using rules.

            bool doesRuleMatch = false;
            for (uint32_t ruleIndex = 0, ruleCount = static_cast<uint32_t>(rules_.size());
                 ruleIndex < ruleCount && !doesRuleMatch;
                 ++ruleIndex
                 )
            {
                // Look for Case/Select matches, picking the first one in the
                // defined order that satisfies all conditions, lazily
                // evaluating subconditions.

                Rule& rule = rules_[ruleIndex];
                switch (rule.action)
                {
                case Rule::ActionCase: // match to a given case
                case Rule::ActionSelect: // select a value directly from another property
                    doesRuleMatch = GetRuleValue(files, rule, ch);
                    if (doesRuleMatch && rule.valueString != "DefaultValue")
                    {
                        // Assign the property value. For DefaultValue, we leave
                        // it empty but satisfy the match.
                        ranges_[r] = rule.valueString;
                    }
                    break;

                case Rule::ActionAssert:
                case Rule::ActionAssertAny:
                case Rule::ActionAssertNot:
                    GetRuleValue(files, rule, ch);
                    break;

                default:
                    // Else skip any other rule, only evaluating if needed inside
                    // the recursive test.
                    break;
                }
            }
        }
        else
        {
            // We already have a property value, so just verify it.

            for (uint32_t ruleIndex = 0, ruleCount = static_cast<uint32_t>(rules_.size());
                 ruleIndex < ruleCount;
                 ++ruleIndex
                 )
            {
                Rule& rule = rules_[ruleIndex];
                switch (rule.action)
                {
                case Rule::ActionAssert:
                case Rule::ActionAssertAny:
                case Rule::ActionAssertNot:
                    GetRuleValue(files, rule, ch);
                    break;
                }
            }
        }

        if ((ch & 0xFFFF) == 0)
        {
            printf(".");
        }
    }
    printf("\r\n");
}


uint32_t UcdFile::GetRuleIndex(const string& name) const
{
    const RuleIndexLookups::const_iterator ril = ruleIndexLookups_.find(name);
    if (ril == ruleIndexLookups_.end())
    {
        throw runtime_error(string("Non-existant rule used '") + name + "'");
    }

    return ril->second;
}


void UcdFile::RuleAssertionFailure(const Rule& exceptionRule, char32_t ch) const
{
    string str;
    Format(str, "%s, U+%04X\r\n", exceptionRule.valueString.c_str(), ch);
    BuildPrintableRuleStrings(str, "", true);
    throw runtime_error(str);
}


void UcdFile::BuildPrintableRuleStrings(string& str, string linePrefix, bool showValues) const
{
    // Print out all the rules and their values to make sense of why it failed.
    for (uint32_t ruleIndex = 0, ruleCount = static_cast<uint32_t>(rules_.size());
        ruleIndex < ruleCount;
        ++ruleIndex
        )
    {
        const Rule& rule = rules_[ruleIndex];

        str += linePrefix;

        Format(str, "%d", ruleIndex);
        if (!rule.name.empty())
        {
            Format(str, " %s:", rule.name.c_str());
        }

        Format(str, " %s", g_ruleActions[rule.action].name);
        if (!rule.valueString.empty())
        {
            Format(str, " '%s'", rule.valueString.c_str());
        }

        if (!rule.propertyName.empty())
        {
            Format(str, " %s", rule.propertyName.c_str());
        }

        for (RuleStrings::const_iterator parameter = rule.parameters.begin(); parameter != rule.parameters.end(); ++parameter)
        {
            str += " ";
            str += *parameter;
        }

        if (showValues)
        {
            Format(str, " value=%d", uint32_t(rule.value));
        }
        str += '\n';
    }
}


bool UcdFile::GetRuleValue(const Files& files, Rule& rule, char32_t ch)
{
    if (ch >= rule.valueCharacterRange.first && ch <= rule.valueCharacterRange.last)
    {
        return rule.value; // return cached value
    }

    rule.value = false;
    rule.valueCharacterRange = UnicodeRange(ch, ch); // cache for next time

    bool value = false;

    switch (rule.action)
    {
    case Rule::ActionNop:
        break;

    case Rule::ActionIn:
    case Rule::ActionOut:
        {
            // value = false;

            // Find whether the character matches any property values in the list.
            const Ranges& ranges = files[rule.propIndex]->ranges_;
            const Ranges::const_iterator rviEnd = ranges.end();
            const Ranges::const_iterator rvi = ranges.find(UnicodeRange(ch, ch));

            if (rvi != rviEnd)
            {
                rule.valueCharacterRange = rvi->first;

                if (rule.parameters.empty())
                {
                    // If no parameters are specified, simply check whether or not the
                    // character has a defined property, regardless of value. For most
                    // properties, In would only return false for reserved code points.
                    // This is also useful for checking binary properties, which don't
                    // have a specific named value, just set membership or not.
                    //
                    // Ex: In Whitespace
                    // Ex: In Script
                    //
                    value = !rvi->second.empty();
                }
                else
                {
                    // Match against each property to find any that match.
                    //
                    // Ex: In Ps Pe
                    //
                    for (RuleStrings::const_iterator parameter = rule.parameters.begin(); parameter != rule.parameters.end(); ++parameter)
                    {
                        if (rvi->second == *parameter)
                        {
                            value = true;
                            break; // early out for logical OR
                        }
                    }
                }
            }

            switch (rule.action)
            {
            case Rule::ActionOut:
                // Negate result for not-in rule.
                value = !value;
                break;
            }
        }
        break;

    case Rule::ActionCase:
    case Rule::ActionAnd:
    case Rule::ActionAssert:
        {
            value = true;

            // Determine whether all conditions are true.
            for (RuleStrings::const_iterator parameter = rule.parameters.begin(); parameter != rule.parameters.end(); ++parameter)
            {
                uint32_t ruleIndex = GetRuleIndex(*parameter);
                value = GetRuleValue(files, rules_[ruleIndex], ch);
                if (!value)
                    break; // early out for logical AND
            }

            switch (rule.action)
            {
            case Rule::ActionAssert:
                if (!value || rule.parameters.empty())
                {
                    RuleAssertionFailure(rule, ch);
                }
                break;
            }
            // rule.valueString for ActionCase was permanently set during preparsing - do not mess with it.
        }
        break;

    case Rule::ActionNot: // Not to all the conditions (equivalent to Nor)
    case Rule::ActionOr:
    case Rule::ActionAssertAny:
    case Rule::ActionAssertNot:
        {
            // value = false;

            // Determine whether any conditions are true.
            for (RuleStrings::const_iterator parameter = rule.parameters.begin(); parameter != rule.parameters.end(); ++parameter)
            {
                uint32_t ruleIndex = GetRuleIndex(*parameter);
                value = GetRuleValue(files, rules_[ruleIndex], ch);
                if (value)
                    break; // early out for logical OR
            }

            switch (rule.action)
            {
            case Rule::ActionNot:
                value = !value;
                break;

            case Rule::ActionAssertNot:
                value = !value;
                // fallthrough

            case Rule::ActionAssertAny:
                if (!value)
                {
                    RuleAssertionFailure(rule, ch);
                }
                break;
            }
        }
        break;

    case Rule::ActionSelect:
        {
            // Find whether the character matches any property values in the list.
            const Ranges& ranges = files[rule.propIndex]->ranges_;
            const Ranges::const_iterator rviEnd = ranges.end();
            const Ranges::const_iterator rvi = ranges.find(UnicodeRange(ch, ch));
            if (rvi == rviEnd)
            {
                break; // character's property undefined, so no point in continuing - value = false
            }

            value = true;
            rule.valueString = rvi->second; // update each call depending on found value

            // Determine whether all conditions are true.
            for (RuleStrings::const_iterator parameter = rule.parameters.begin(); parameter != rule.parameters.end(); ++parameter)
            {
                uint32_t ruleIndex = GetRuleIndex(*parameter);
                value = GetRuleValue(files, rules_[ruleIndex], ch);
                if (!value)
                    break; // early out for logical AND
            }
        }
        break;

    case Rule::ActionRange:
        // Check whether ch falls in any ranges.
        for (RuleStrings::const_iterator parameter = rule.parameters.begin(); parameter != rule.parameters.end(); ++parameter)
        {
            const UnicodeRange range = ParseRange(*parameter);
            if (ch >= range.first && ch <= range.last)
            {
                rule.valueCharacterRange = range;
                value = true;
                break; // early out for logical OR
            }
        }
        break;
    }

    rule.value = value;
    return value;
}


const char* UcdFile::GetCharacterName(
    char32_t ch,
    const Ranges* characterNameRanges, // optional
    const Ranges* blockNameRanges // optional
    )
{
    // Get the specific character name or at least the block range name.
    Ranges::const_iterator rni;
    UnicodeRange r(ch, ch);

    if (characterNameRanges != nullptr)
    {
        rni = characterNameRanges->find(r);
        if (rni != characterNameRanges->end())
        {
            return rni->second.c_str();
        }
    }

    if (blockNameRanges != nullptr)
    {
        rni = blockNameRanges->find(r);
        if (rni != blockNameRanges->end())
        {
            return rni->second.c_str();
        }
    }

    return "?";
}


// Generates a UCD compatible text file, writing the values back out.
void UcdFile::GenerateText(const Files& files)
{
    const string& fileName = attributes_["FileOut"];
    if (fileName.empty())
    {
        return;
    }

    printf("Writing %s to %s\n", Property().c_str(), fileName.c_str());

    ofstream file(fileName.c_str());

    // Write header

    size_t startPosOfFileName = fileName.find_last_of("/\\");
    startPosOfFileName = (startPosOfFileName == string::npos) ? 0 : startPosOfFileName+1;
    string pureFileName = fileName.substr(startPosOfFileName);

    file << "# This file was generated by ucdtool.exe." << endl
         << "# DO NOT HAND MODIFY" << endl
         << "#" << endl
         << "# " << Property() << " Property" << endl
         << "#"  << endl
         << "# Output file: " << pureFileName << endl
         << "#"  << endl;

    if (!attributes_["FileIn"].empty())
    {
        file << "# Input merged from: " << attributes_["FileIn"] << endl
             << "#" << endl;
    }
    if (!rules_.empty())
    {
        file << "# Rules:" << endl;
        string str;
        BuildPrintableRuleStrings(str, "# ", false);
        file << str
             << "#" << endl;
    }

    if (!attributes_["DefaultValue"].empty())
    {
        file << "# Default value: " << attributes_["DefaultValue"] << endl
             << "#" << endl;
    }

    file << "##############################################################" << endl
         << endl;

    // Look for character names if present among the loaded properties.
    // These will be used in the comments when writing the characters out.

    const Ranges* characterNameRanges = nullptr;
    const Ranges* blockNameRanges     = nullptr;

    for (Files::const_iterator fileIt = files.begin(); fileIt != files.end(); ++fileIt)
    {
        UcdFile& ucdFile = **fileIt;

        // Specially recognized property names.
        if (ucdFile.Property() == "CharacterName")
        {
            characterNameRanges = &ucdFile.ranges_;
        }
        // One specially recognized property name.
        if (ucdFile.Property() == "Block")
        {
            blockNameRanges = &ucdFile.ranges_;
        }
    }

    // Remap the values if enum mappings exist

    if (!enums_.empty())
    {
        typedef std::map<string, string> ValueRemapping;
        ValueRemapping valueRemapping;

        // Add all the enums to another set for comparsion.
        for (EnumAttributes::iterator i = enums_.begin(); i != enums_.end(); ++i)
        {
            Fields fields = Split(*i); // enum, value
            if (fields.size() >= 3)
            {
                valueRemapping.insert(
                    std::pair<string, string>(
                        fields.at(0),
                        fields.at(2)
                        )
                    );
            }
        }

        if (!valueRemapping.empty())
        {
            for (Ranges::iterator rvi = ranges_.begin(); rvi != ranges_.end(); ++rvi)
            {
                ValueRemapping::iterator it = valueRemapping.find(rvi->second);
                if (it != valueRemapping.end())
                {
                    rvi->second = it->second;
                }
            }
        }
    }

    // Find the longest value string to align column widths.

    size_t widthOfLargestValue = 0;
    for (Ranges::const_iterator rvi = ranges_.begin(); rvi != ranges_.end(); ++rvi)
    {
        widthOfLargestValue = max(widthOfLargestValue, rvi->second.length());
    }

    // Write each range and value, and optionally character name.

    string str;

    for (Ranges::const_iterator rvi = ranges_.begin(); rvi != ranges_.end(); ++rvi)
    {
        str.clear();

        // Write range, either single character or dual range.
        const UnicodeRange range = rvi->first;

        if (range.last > range.first)
        {
            Format(str, "%04X..%04X", range.first, range.last);
        }
        else
        {
            Format(str, "%04X", range.first);
        }

        // Write value
        const size_t widthOfLargestRange = 6+2+6; // 123456..123456
        if (str.size() < widthOfLargestRange)
        {
            str.resize(widthOfLargestRange, ' '); // pad for better alignment
        }

        str += "; ";
        str += rvi->second;

        // Write the character names in comments.
        if (characterNameRanges != nullptr || blockNameRanges != nullptr)
        {
            const size_t widthUpToRightColumn = widthOfLargestRange + 2 + widthOfLargestValue;
            if (str.size() < widthUpToRightColumn)
            {
                str.resize(widthUpToRightColumn, ' '); // pad for better alignment
            }

            const char* characterName = GetCharacterName(range.first, characterNameRanges, blockNameRanges);
            Format(str, " # %s", characterName);
            if (range.last > range.first)
            {
                characterName = GetCharacterName(range.last, characterNameRanges, blockNameRanges);
                Format(str, "..%s", characterName);
            }
        }

        file << str << endl;
    }

    file << endl
         << "#EOF" << endl;
}


// Count the number of planes all the ranges are involved in
size_t UcdFile::CountPlanes() const
{
    size_t count = 0;
    bool presentPlanes[17] = {};

    for (Ranges::const_iterator rv = ranges_.begin(); rv != ranges_.end(); ++rv)
    {
        UnicodeRange range = rv->first;
        range.last = std::min(range.last, UnicodeCodePointTotal-1);
        for ( ; range.first <= range.last; range.first = RoundUpPlane(range.first))
        {
            uint32_t plane = Plane(range.first);
            if (!presentPlanes[plane])
            {
                presentPlanes[plane] = true;
                ++count;
            }
        }
    }           

    return count;
}


void UcdFile::GenerateLookups(int file)
{
    Ranges::iterator rvi;

    const uint32_t defaultValue = DefaultValue();

    // Initialize the initial lookup table - all code points map to the
    // default value. Note level 0 is considered the highest, and level 3
    // is the lowest (and actually holds the data).
    vector<Block> blocks_;
    blocks_.push_back(Block(0, 1));                 // level 0 points to level 1
    blocks_.push_back(Block(1, 2));                 // level 1 points to level 2
    blocks_.push_back(Block(2, 3));                 // level 2 points to level 3
    blocks_.push_back(Block(3, defaultValue));      // level 3 is all defaults

    blocks_[0].refs = 0x1;
    blocks_[1].refs = 0x100;
    blocks_[2].refs = 0x10000;
    blocks_[3].refs = 0x1000000;

    printf("%d ranges, ", ranges_.size());

    // Construct the full lookup table.  For each character we have data for,
    // punch down through the lookups and set the value of that character in it's
    // level 3 block.  If we need to write to a block that already has multiple
    // references, then create a path.
    for (rvi = ranges_.begin(); rvi != ranges_.end(); ++rvi)
    {
        char32_t c = rvi->first.first;
        uint32_t const v = ValueOf(rvi); 

        do
        {
            uint8_t b0 = (c >> (ChildBlockBits * 3)) & (ChildBlockLevels - 1);
            uint8_t b1 = (c >> (ChildBlockBits * 2)) & (ChildBlockLevels - 1);
            uint8_t b2 = (c >> (ChildBlockBits * 1)) & (ChildBlockLevels - 1);
            uint8_t b3 = (c >> (ChildBlockBits * 0)) & (ChildBlockLevels - 1);

            uint32_t level0 = 0;
            uint32_t level1 = blocks_[level0][b0];
            uint32_t level2 = blocks_[level1][b1];
            uint32_t level3 = blocks_[level2][b2];
        
            if (blocks_[level3].refs != 1)
            {
                --blocks_[level3].refs;
                level3 = (uint32_t) blocks_.size();
                blocks_.push_back(Block(3, defaultValue));
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

    const uint32_t rawBlocks = static_cast<uint32_t>(blocks_.size());

    if (blocks_.size() > INT16_MAX)
        throw runtime_error("too many blocks");

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
                    // We found a match, so contribute all the ref count
                    // toward the new one, and set this block as having
                    // an identical match.
                    blocks_[match].refs += blocks_[i].refs;
                    blocks_[i].refs = 0;
                    blocks_[i].match = match;

                    break;
                }
            }
        }

        // Lest we found matches above, update every block in the immediately
        // higher layer to point from the old blocks to the new ones.
        uint32_t nextHigherLevel = level - 1;
        for (uint32_t i = 0, ci = (uint32_t) blocks_.size() - 1; i != ci; i++)
        {
            if (blocks_[i].level != nextHigherLevel)
                continue;

            // For each block that had a match, repoint every index in this
            // block to the match.
            for (uint32_t child = 0; child != ChildBlockLevels; ++child)
            {
                uint32_t const match = blocks_[ blocks_[i][child] ].match;
                if (match != ~0)
                {
                    blocks_[i][child] = match;
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
        offset += blocks_[i].actualByteSize;
    }

    // Compress each block
    for (uint32_t i = 0; i != blocks_.size(); ++i)
    {
        if (blocks_[i].refs == 0)
            continue;

        CompressBlock(blocks_, i);
    }

    uint32_t byteSize = 0;
    uint32_t totalBlocksWritten = 0;

    for (size_t b = 0; b != blocks_.size(); ++b)
    {
        if (blocks_[b].refs == 0)
            continue;

        assert(b == 0 || blocks_[b].offset != 0);


        if (-1 == _write(file, &blocks_[b][0], blocks_[b].actualByteSize))
            throw errno_error("write failure");

        byteSize += blocks_[b].actualByteSize;
        ++totalBlocksWritten;
    }

    printf("coalesced %d->%d blocks, %d bytes\n", rawBlocks, totalBlocksWritten, byteSize);
}


// By the time we get here, we've generated a four-level lookup table
// that handles every character in the entire Unicode range.  This table
// had been optimized so that identical blocks get coalesced to save
// (loads of) space.  
// 
// We will now undo the optimization for level 3 and make it so that no
// level 2 block will refer to a level 3 block that is also referred to 
// by another level 2 block.  This allows us to layout level 2&3 such that
// level 2 can be guaranteed to refer to level 3 using an 8-bit index.
//
// Once that's done we go back and re-optimize level 2&3 such that if two
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
            newBlocks.back().actualByteSize = ChildBlockLevels * sizeof(uint16_t);
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
            newBlocks.back().actualByteSize = ChildBlockLevels * sizeof(uint8_t);

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

    // Repoint the level 0 and 1 blocks to their new child locations
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
            uint32_t increment = min(ActualBlockByteSize(), (uint32_t) ChildBlockLevels);
            uint32_t maxOffset = 256 * increment;

            for ( ; childIndex != newBlocks.size() && newBlocks[childIndex].level == 3; ++childIndex)
            {
                uint32_t matchIndex = childIndex + 1;
                uint32_t matchOffset = childOffset;
                for ( ; matchIndex != newBlocks.size(); ++matchIndex)
                {
                    if (newBlocks[matchIndex].refs == 0)
                        continue;

                    matchOffset += newBlocks[matchIndex - 1].actualByteSize;
                    if (matchOffset > maxOffset)
                        break;

                    if (newBlocks[matchIndex] == newBlocks[childIndex])
                    {
                        newBlocks[matchIndex].refs += newBlocks[childIndex].refs;
                        newBlocks[childIndex].refs = 0;

                        for (int c = 0; c != ChildBlockLevels; ++c)
                            if (newBlocks[parentIndex][c] == childIndex)
                                newBlocks[parentIndex][c] = matchIndex;

                        break;
                    }
                }
                
                childOffset += newBlocks[childIndex].actualByteSize;
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
        uint8_t * p = (uint8_t *) &blocks_[b][0];

        for (uint32_t i = 0; i != ChildBlockLevels; ++i)
        {
            uint32_t offset = blocks_[blocks_[b][i]].offset - blocks_[b].offset;
            uint32_t increment = min(ActualBlockByteSize(), ChildBlockLevels);
            uint32_t compressedOffset = offset / increment;
            assert(compressedOffset < 256 && compressedOffset * increment == offset);

            p[i] = (uint8_t) compressedOffset;
        }

        return;
    }

    // level 0 and 1 have 16-bit entries that specify the offset (in bytes)
    // to each child block.
    uint16_t * p = (uint16_t *) &blocks_[b][0];

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

    void WriteCodeHeader(ofstream& header) override;
    void WriteBinary(int file) override;

private:
    bool ShouldProcessLineValue(const string& value) override;
    // inherit ProcessLineValue

    uint32_t DefaultValue() {return false;};
    void     ReformatBlock(Block& b);
    uint32_t ActualBlockByteSize() {return ChildBlockLevels / 8;}

    uint32_t ValueOf(Ranges::iterator rangeValue)
    {
        // Return true if the value is anything but empty string.
        return !rangeValue->second.empty();
    }
};


bool BooleanUcdFile::ShouldProcessLineValue(const string& value)
{
    // Boolean files can contain several different categories of boolean
    // properties (e.g. proplist.txt has "WhiteSpace", "Bidi_Control", etc).
    // Each individual category is treated seperately, so skip ones that
    // don't apply.

    return value == attributes_["Category"];
}


// Header output for boolean properties is simple - just create a 
// "UcdIsProperty" function that calls into the generic function.
void BooleanUcdFile::WriteCodeHeader(ofstream& header)
{
    string name = attributes_["Property"];

    header << "inline bool UcdIs" << name << "(char32_t inputChar) "
           << "{return UcdLookupBooleanProperty(UcdProp" << name << ", inputChar);}" << endl
           << endl;
}


// Write binary range data for a boolean property.
void BooleanUcdFile::WriteBinary(int file)
{
    GenerateLookups(file);
}


void BooleanUcdFile::ReformatBlock(Block& b)
{
    assert(b.level == 3);

    for (int i = 0; i != ChildBlockLevels; ++i)
    {
        uint32_t v = b[i];
        b[i] = 0;

        if (v)
            b[i / 32] |= 1 << (i % 32);
    }

    b.actualByteSize = ActualBlockByteSize();
}




// Specialization for enumerated properties.
class EnumeratedUcdFile : public UcdFile
{
public:

    void WriteCodeHeader(ofstream& header) override;
    void WriteBinary(int file) override;

private:

    // Type to hold the set of attributes for each file we need to parse
    typedef std::map<string, uint32_t> Categories;

    Categories categories_;

    void ProcessLineValue(const UnicodeRange& range, const string& value, Ranges& ranges) override;

    uint32_t DefaultValue()
    {
        Categories::iterator cat = categories_.find(attributes_["DefaultValue"]);

        return (cat == categories_.end()) ? 0 : (uint32_t) cat->second;
    }

    uint32_t ValueOf(Ranges::iterator rangeValue)
    {
        // The value returned is the ordinal location in the list.

        Categories::iterator cat = categories_.find(rangeValue->second);
        return (cat == categories_.end()) ? 0 : (uint32_t) cat->second;
    }

    void     ReformatBlock(Block& b);
    uint32_t ActualBlockByteSize() {return ChildBlockLevels * sizeof(uint8_t);}

};


// Process lines in an enumerated file.
void EnumeratedUcdFile::ProcessLineValue(const UnicodeRange& range, const string& value, Ranges& ranges)
{
    // Turn spaces to compiler-compatible underscores.
    string underscoredValue = value;
    UnderscoreString(underscoredValue);
    ranges[range] = underscoredValue;

    // Keep track of each category so we can output an enum later.
    Categories::iterator cat = categories_.find(underscoredValue);
    if (cat == categories_.end())
    {
        // Just set the value to 0 for now. We don't know the proper value
        // anyway yet until we've read all the enumeration names.
        categories_.insert(cat, std::pair<string, uint32_t>(underscoredValue, 0));
    }
}


// Write binary range data for an enumerated property.
//
// Note that the value of any give range is equal to the index of that range's
// category within the set of categories.
void EnumeratedUcdFile::WriteBinary(int file)
{
    GenerateLookups(file);
}


void EnumeratedUcdFile::ReformatBlock(Block& b)
{
    assert(b.level == 3);
    
    if (categories_.size() > UINT8_MAX)
        throw runtime_error("Too many categories.");

    uint8_t * p = (uint8_t *) &b[0];

    for (int i = 0; i != ChildBlockLevels; ++i)
        p[i] = (uint8_t) b[i];

    b.actualByteSize = ActualBlockByteSize();
}


// Header output for enumerated properties consists of an enum containing all
// the categories for this property and a "UcdGetProperty" function.
void EnumeratedUcdFile::WriteCodeHeader(ofstream& header)
{
    // Make sure that the default value is in the set of categories.
    categories_.insert(std::pair<string, uint32_t>(attributes_["DefaultValue"], 0));

    string& prefix = attributes_["SymbolPrefix"];
    string& type = attributes_["Property"];

    // If no enumerations are specified in the control file, we just assign
    // them all in increasing values by alphabetic order from 0. If explicit 
    // enums are given, we continue from the last enum.
    uint32_t currentValue = 0;
    Categories explicitCategories;

    if (!enums_.empty())
    {
        // Add all the enums to another set for comparsion.
        for (EnumAttributes::iterator i = enums_.begin(); i != enums_.end(); ++i)
        {
            Fields fields = Split(*i); // enum, value
            if (fields.at(1).empty())
                continue; // no value specified (but maybe a name remapping), so skip

            uint32_t explicitEnumValue = strtol(fields.at(1).c_str(), nullptr, 0);

            explicitCategories.insert(
                std::pair<string, uint32_t>(
                    fields.at(0),
                    explicitEnumValue
                    )
                );

            currentValue = std::max(currentValue, explicitEnumValue + 1);
        }

        // Assign all explicit enums from the control file.
        categories_.insert(explicitCategories.begin(), explicitCategories.end());
    }

    // Assign all the enumeration values.
    for (Categories::iterator cat = categories_.begin(); cat != categories_.end(); ++cat)
    {
        Categories::iterator knownCat = explicitCategories.find(cat->first);
        if (knownCat == explicitCategories.end())
        {
            // No matching enum value. Assign ascending.
            cat->second = currentValue++;
        }
        else
        {
            // Assign given value from control file.
            cat->second = knownCat->second;
        }
    }

    // Figure out the maximum length of all the categories so we can make
    // everything line up neatly.
    size_t width = 0;
    for (Categories::iterator cat = categories_.begin(); cat != categories_.end(); ++cat)
    {
        width = max(width, prefix.length() + cat->first.length());
    }
    width = max(width, type.length() + strlen("Total"));

    // Output the enum
    header << "enum " << type << endl
           << "{" << endl;

    typedef std::pair<string, uint32_t> CategoryPair;

    struct OrderByIncreasingValueThenName : public std::binary_function<CategoryPair, CategoryPair, bool>
    {
        bool operator()(const CategoryPair& left, const CategoryPair& right) const // lesser
        {
            return (left.second < right.second
                || (left.second == right.second && left.first < right.first));
        }
    };

    std::vector<CategoryPair> orderedCategories(categories_.begin(), categories_.end());
    std::sort(orderedCategories.begin(), orderedCategories.end(), OrderByIncreasingValueThenName());

    for (std::vector<CategoryPair>::iterator cat = orderedCategories.begin(); cat != orderedCategories.end(); ++cat)
    {
        string name = prefix + cat->first;
        if (name.length() < width)
            name += string(width - name.length(), ' ');

        header << "    " << name << " = " << cat->second << "," << endl;
    }

    // Finish off the enum with a sentinal value that effectively gives the
    // total number of categories.  And spit out the Get function.
    {
        string name = "Total" + type;
        if (name.length() < width)
            name += string(width - name.length(), ' ');

        header << "    " << name << " = " << categories_.size() << endl;
    }

    header << "};" << endl
           << endl
           << "inline " << type << " UcdGet" << type << "(char32_t inputChar) {"
           << "return (" << type << ") UcdLookupEnumeratedProperty(UcdProp" << type << ", inputChar);}" << endl
           << endl;
}


// Specialization for value properties.
class ValueUcdFile : public UcdFile
{
public:
    ValueUcdFile(int32_t radix) : radix_(radix) {};

    void WriteCodeHeader(ofstream& header) override;
    void WriteBinary(int file) override;

private:

    int32_t radix_;

    // inherit ProcessLineValue

    uint32_t DefaultValue();
    uint32_t ValueOf(Ranges::iterator rvi);
    void     ReformatBlock(Block& b);
    uint32_t ActualBlockByteSize();
};


// Write binary range data for a hex property (like bidi mirroring
// character pairs).
void ValueUcdFile::WriteBinary(int file)
{
    GenerateLookups(file);
}


uint32_t ValueUcdFile::DefaultValue() 
{
    return 0;
}


uint32_t ValueUcdFile::ValueOf(Ranges::iterator rvi) 
{
    // Can service decimal or hexadecimal.
    return strtol(rvi->second.c_str(), nullptr, radix_);
}


void ValueUcdFile::ReformatBlock(Block& b)
{
    b.actualByteSize = ActualBlockByteSize();
}


uint32_t ValueUcdFile::ActualBlockByteSize()
{
    return ChildBlockLevels * sizeof(uint32_t);
}


// Header output for hex-value properties consists of just a "UcdGetProperty"
// that calls into the generic function, exactly like enumerated properties,
// except that the numeric value is explicitly given.
void ValueUcdFile::WriteCodeHeader(ofstream& header)
{
    string& name = attributes_["Property"];
    string& def = attributes_["DefaultValue"];

    header << "inline uint32_t UcdGet" << name << "(char32_t inputChar) "
           << "{return UcdLookupValueProperty(UcdProp" << name << ", inputChar, " << def << ");}" << endl
           << endl;
}



// Specialization for string properties, which are only informative and cannot be written out.
class StringUcdFile : public UcdFile
{
public:
    // Strings are only supported for input sake. The property cannot be stored
    // in the UCD binary information.
    bool IsStoredProperty() override {return false;}
    void WriteCodeHeader(ofstream& header) override { return; }
    void WriteBinary(int file) override { return; }

private:

    // inherit ProcessLineValue

    uint32_t DefaultValue() override { return 0; }

    uint32_t ValueOf(Ranges::iterator rangeValue) override { return 0; }

    void ReformatBlock(Block& b) override { return; }

    uint32_t ActualBlockByteSize() override { return 0; }
};




// Given a set of attributes describing the type we need to parse and it's
// file, create the appropriate derived file parser.
UcdFile* UcdFile::Create(
    const Attributes&           attributes,
    const ExceptionAttributes&  exceptions,
    const EnumAttributes&       enums,
    const RuleStrings&          ruleStrings
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
    else if (dataType == "String")
        file = new StringUcdFile;
    else
        throw runtime_error(string("Unknown type in control file '") + dataType + "' (case-sensitive)");

    if (!enums.empty() && dataType != "Enumeration")
    {
        throw runtime_error("Enumeration values are only valid for enumeration data types.");
    }

    file->attributes_          = attributes;
    file->exceptions_          = exceptions;
    file->enums_               = enums;
    file->ruleStrings_         = ruleStrings;

    // If no symbol prefix was specified create one that is the same as the
    // generated type.
    if (file->attributes_["SymbolPrefix"].empty())
    {
        file->attributes_["SymbolPrefix"] = file->attributes_["Property"];
    }

    return file;
}


// Parse the control file, extract each property, associated file, and other
// attributes, and create the right parser for that file.
void ParseControlFile(const string& filename, Files& files)
{
    ifstream controlFile(filename.c_str());
    if (controlFile.fail())
    {
        throw errno_error(string("Unable to open control file '") + filename + "'");
    }
    
    string              line;
    string              nextLine;
    Attributes          attributes;
    ExceptionAttributes exceptions;
    EnumAttributes      enums;
    RuleStrings         ruleStrings;
    int16_t             propindex = -1;

    SkipFileBom(controlFile);

    // Process each statement in the control file.
    for (bool atFileEnd = false; !atFileEnd; )
    {
        // Read next statement, which may consist of multiple concatenated lines.
        //
        // Example:
        //      Rule=IsSimpleScript: In Script
        //          # These have no complex behaviors
        //          Latin
        //          Cyrillic
        //          Greek
        //          ...
        //
        // Becomes:
        //      Rule=IsSimpleScript: In Script Latin Cyrillic Greek ...
        //
        std::swap(line, nextLine); // use line that was read ahead from the previous loop.

        for (bool atLineEnd = false; !atLineEnd; )
        {
            if (getline(controlFile, nextLine).fail())
            {
                atFileEnd = true;
                break;
            }

            // Check whether line is indented, continuing the previous line.
            atLineEnd = nextLine.empty() || !isspace(nextLine[0]);

            // Strip comments and whitespace
            const size_t commentPos = nextLine.find('#');
            if (commentPos != string::npos)
                nextLine.resize(commentPos);

            Trim(nextLine);

            // Definite end of statement if line was just empty whitespace
            if (nextLine.empty() && commentPos == string::npos)
                break;

            // Concatenate the next line to the current line
            if (line.empty())
            {
                std::swap(line, nextLine);  // swap instead of concatenate, since empty.
                atLineEnd = false;          // explicitly continue anyway
            }
            else if (!atLineEnd && !nextLine.empty())
            {
                line += " ";
                line += nextLine;
                nextLine.clear();
            }
        }

        // skip comments or empty lines
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
            if (propindex == -1)
                g_control = attributes;
            else
                files.push_back(UcdFile::Create(attributes, exceptions, enums, ruleStrings));

            attributes.clear();
            exceptions.clear();
            enums.clear();
            ruleStrings.clear();
            ++propindex;
        }

        if (attribute == "Exception")
        {
            exceptions.push_back(value);
        }
        else if (attribute == "Enum")
        {
            UcdFile::Fields fields = UcdFile::Split(value);
            if (fields.size() < 2)
            {
                throw runtime_error("Enumeration values require both name and value (e.g. \"Braille;5\").");
            }
            enums.push_back(value);
        }
        else if (attribute == "Rule")
        {
            ruleStrings.push_back(value);
        }
        else
        {
            attributes[attribute] = value;
        }
    }

    files.push_back(UcdFile::Create(attributes, exceptions, enums, ruleStrings));

    // Default values for control attributes
    
    if (g_control.find("GeneratedHeader") == g_control.end())
        g_control["GeneratedHeader"] = "UcdProperties.h";

    if (g_control.find("GeneratedBinary") == g_control.end())
        g_control["GeneratedBinary"] = "UcdData.bin";
}


// Write global header data.  This consists of the standard file header and
// global list of all properties.
void WriteCodeHeaderMetaData(ofstream& header, Files& files)
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
           << "bool    UcdLookupBooleanProperty(UcdProperty prop, __in_range(0, UnicodeMax) char32_t inputChar);" << endl
           << "int32_t UcdLookupEnumeratedProperty(UcdProperty prop, __in_range(0, UnicodeMax) char32_t inputChar);" << endl
           << "int32_t UcdLookupValueProperty(UcdProperty prop, __in_range(0, UnicodeMax) char32_t inputChar, int32_t defaultValue);" << endl
           << endl
           << "enum UcdProperty" << endl
           << "{" << endl;

    uint16_t propIndex = 0;

    for (Files::iterator fileIt = files.begin(); fileIt != files.end(); ++fileIt)
    {
        UcdFile& file = **fileIt;

        if (file.IsStoredProperty())
        {
            header << "    UcdProp" << file.Property() << " = " << propIndex << "," << endl;
            ++propIndex;
        }
    }
   
    header << "    TotalUcdProps = " << propIndex << endl
           << "};" << endl
           << endl;
}


// Central point for all logic
void ParseAndGenerate()
{
    Files files;
    Files::iterator fileIt;

    // Read the set of properties we care about and go parse each one
    ParseControlFile("Tables.txt", files);

    // Parse each property from the file list.
    for (fileIt = files.begin(); fileIt != files.end(); ++fileIt)
    {
        UcdFile& file = **fileIt;
        file.ParseText();
        file.ApplyExceptions();
    }

    // And apply each rule to generate or fill in missing data.
    for (fileIt = files.begin(); fileIt != files.end(); ++fileIt)
    {
        UcdFile& file = **fileIt;
        file.ProcessRules(files);
    }

    string headerName = g_control["GeneratedHeader"];
    string binaryName = g_control["GeneratedBinary"];

    // Create the header
    ofstream codeHeaderFile(headerName.c_str());
    if (codeHeaderFile.fail())
        throw errno_error(string("Unable to open '") + headerName + "'");

    codeHeaderFile.exceptions(ofstream::failbit);
    WriteCodeHeaderMetaData(codeHeaderFile, files);

    // Figure out how many property directory entries we're going to need.
    size_t propertyDirectoryCount = 0;
    for (fileIt = files.begin(); fileIt != files.end(); ++fileIt)
    {
        UcdFile& file = **fileIt;
        if (file.IsStoredProperty())
        {
            ++propertyDirectoryCount;
        }
    }

    PropertyDirectory propertyDirectory;
    propertyDirectory.reserve(propertyDirectoryCount);

    // Create the binary file and seek to the point where property range data
    // will start being written.
    int binfile = _open(
                        binaryName.c_str(), 
                        _O_CREAT | _O_TRUNC | _O_BINARY | _O_WRONLY | _O_SEQUENTIAL, _S_IWRITE);

    if (-1 == binfile)
        throw errno_error(string("Unable to create '") + binaryName + "'"); 

    if (-1 == _lseek(binfile, (long) (sizeof(UcdFileHeader) + propertyDirectoryCount * sizeof(propertyDirectory[0])), SEEK_SET))
        throw errno_error("_lseek failure");

    // Write header and binary info for each property that is meaningful to
    // record, and not just for the sake of input.

    uint16_t propIndex = 0;

    for (fileIt = files.begin(); fileIt != files.end(); ++fileIt)
    {
        UcdFile& file = **fileIt;

        // Store the regenerated text file if given, and UCD property
        // if not purely informational.
        file.GenerateText(files);

        if (file.IsStoredProperty())
        {
            // Record the property directory entry.
            UcdPropertyInfo propInfo = {};
            propInfo.prop = propIndex;
            propInfo.offset = _lseek(binfile, 0, SEEK_CUR);
            propertyDirectory.push_back(propInfo);

            printf("%s: ", file.Property().c_str());

            file.WriteCodeHeader(codeHeaderFile);    
            file.WriteBinary(binfile);

            ++propIndex;
        }
        else
        {
            printf("%s: Property not stored in data\n", file.Property().c_str());
        }
    }

    // Now that we know the offsets for each property directory entry, seek 
    // back to the start of the binary file and write them out.

#pragma warning(push)
#pragma warning(disable:4815)   // zero-sized array on stack will have no elements
    UcdFileHeader fileheader;
#pragma warning(pop)

    fileheader.properties_count = (unsigned int) propertyDirectory.size();

    if (-1 == _lseek(binfile, 0, SEEK_SET))
        throw errno_error("_lseek failure");

    if (-1 == _write(binfile, &fileheader, sizeof(fileheader)))
        throw errno_error("_write failure");

    if (-1 == _write(binfile, &propertyDirectory[0], (unsigned) (propertyDirectory.size() * sizeof(propertyDirectory[0]))))
        throw errno_error("_write failure");

    _close(binfile);

    printf("%s and %s created successfully\n", headerName.c_str(), binaryName.c_str());
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
        return 1;
    }

    return 0;
}
