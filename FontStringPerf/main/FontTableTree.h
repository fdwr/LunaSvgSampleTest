#pragma once

struct GlyphCoverageRange;

// Representation of a font table (particularly GSUB/GPOS) with 4CC tags.
// This tree is just the data - it has no font parsing logic and is used
// as input/output for other functions.
struct FontTableTree
{
public:
    struct Item
    {
        enum Type
        {
            TypeNode, // a node just takes up space as an intermediate link - it may not have any useful type or table offset info
            TypeFont,
            TypeTable,
            TypeScript,
            TypeLanguage,
            TypeFeature,
            TypeLookup,
            TypeTotal,
        };

        enum Flag
        {
            // Some of these flags make apply to a certain type of item, like 'Required'
            // applying to a font feature, but flags can be propagated to other items.
            FlagNone            = 0x00000000,
            FlagRequired        = 0x00000001, // feature is required
            FlagApplicable      = 0x00000002, // given node is applicable (meaning depends on client)
            FlagAccessible      = 0x00000004, // node is accessible (not orphaned)
            FlagCovered         = 0x00000008, // lookup is covered
            FlagAll             = 0x7FFFFFFF, // all flags except terminal
            FlagConstantCounter = 0x00000010, // the counter value is constant, not the sum of children
            FlagAllBits         = 0xFFFFFFFF, // all flags
            FlagTerminal        = 0x80000000, // last item in child list
        };

        union
        {
            char tag[4];            // character tag (GSUB, latn, TRK, ccmp, kern)
            uint32_t tag4CC;
        };
        Type type;                  // type of node
        Flag flags;
        uint32_t tableOffset;       // file byte offset from beginning of font table
        uint32_t tableIndex;        // array index in font
        uint32_t childIndex;        // node index of child
        uint32_t extraIndex;        // additional array index with interpretation depending on type
        uint32_t extraCounter;      // miscellaneous counter

        Item()
            :   type(),
                flags(),
                tag4CC(),
                tableOffset(),
                tableIndex(),
                childIndex(),
                extraIndex(),
                extraCounter()
        { }
    };

    enum ForEachMode
    {
        ForEachModeNode,
        ForEachModeEnter,
        ForEachModeExit,
    };

protected:
    std::vector<Item> items_;
public:
    std::vector<GlyphCoverageRange> coverageRanges_;

    const static uint32_t MaximumStackSize = 20;

public:
    struct IPrintSink
    {
        void Print(uint32_t indent, const wchar_t* text);
    };

    enum PropagateFlagsDirection
    {
        PropagateFlagsDirectionUp       = 0x00000001,
        PropagateFlagsDirectionDown     = 0x00000002,
        PropagateFlagsDirectionDownUp   = PropagateFlagsDirectionDown|PropagateFlagsDirectionUp,
    };

public:
    Item& GetItem(uint32_t index) { return items_[index]; }
    const Item& GetItem(uint32_t index) const { return items_[index]; }
    uint32_t AllocateItems(uint32_t itemCount, bool shouldTerminateList = true, bool shouldAllocateIndividually = false);
    uint32_t AppendItem(uint32_t tag, Item::Type type, Item::Flag flags, uint32_t tableOffset, uint32_t tableIndex, uint32_t childIndex);
    uint32_t AppendTerminalItem();
    uint32_t GetNextAllocatedItemIndex();
    uint32_t GetSize() const { return static_cast<uint32_t>(items_.size()); };
    void Clear();

    static const wchar_t* GetItemTypeName(Item::Type type);

    void PropagateFlags(
        uint32_t rootIndex,
        Item::Flag andMask,
        Item::Flag orMask,
        PropagateFlagsDirection direction
        );

    typedef std::function<void (const Item& item, uint32_t indent, const wchar_t* text)> PrintFunction;

    void Print(
        uint32_t rootIndex,
        bool shouldSkipRoot,
        uint32_t indent,
        Item::Flag requiredMask,
        Item::Flag excludedMask,
        PrintFunction printFunction
        ) const;

    typedef std::function<void (Item& item, uint32_t itemIndex, ForEachMode mode)> ForEachFunction;

    void ForEachSerial(
        ForEachFunction callback
        );

    void ForEach(
        uint32_t rootIndex,
        bool shouldSkipRoot,
        ForEachFunction callback
        );

    inline void ForEach(
        uint32_t rootIndex,
        bool shouldSkipRoot,
        ForEachFunction callback
        ) const
    { const_cast<FontTableTree*>(this)->ForEach(rootIndex, shouldSkipRoot, callback); }
};

DEFINE_ENUM_FLAG_OPERATORS(FontTableTree::Item::Flag);
