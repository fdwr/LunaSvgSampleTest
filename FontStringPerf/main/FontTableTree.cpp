#include "precomp.h"


void FontTableTree::Clear()
{
    items_.clear();
}


uint32_t FontTableTree::AppendTerminalItem()
{
    items_.resize(GetSize() + 1);
    items_.back().flags |= Item::FlagTerminal;
    return GetSize();
}


uint32_t FontTableTree::AllocateItems(uint32_t itemCount, bool shouldTerminateList, bool shouldAllocateIndividually)
{
    const uint32_t previousSize = GetSize();
    if (previousSize + itemCount < previousSize)
        throw std::bad_array_new_length();

    // Allocate more items at the end.
    items_.resize(previousSize + itemCount);

    // Mark the last one as terminal if desired; otherwise the caller might
    // allocate more consecutive items.
    if (shouldTerminateList | shouldAllocateIndividually)
    {
        if (!items_.empty())
        {
            items_.back().flags |= Item::FlagTerminal;
        }
        else
        {
            AppendTerminalItem();
        }
    }

    // Mark each individual item as terminal. This would be used for items
    // that are not part of a list themselves, but they are referenced by
    // other nodes.
    if (shouldAllocateIndividually)
    {
        std::for_each(
            items_.begin() + previousSize,
            items_.end(),
            [](Item& item)
            {
                item.flags |= FontTableTree::Item::FlagTerminal;
            }
            );
    }

    return (itemCount == 0) ? 0 : previousSize;
}


uint32_t FontTableTree::GetNextAllocatedItemIndex()
{
    return GetSize();
}


const wchar_t* FontTableTree::GetItemTypeName(Item::Type type)
{
    const static wchar_t* names[] = {
        L"node",
        L"font",
        L"table",
        L"script",
        L"language",
        L"feature",
        L"lookup"
    };
    static_assert(ARRAYSIZE(names) == Item::TypeTotal, "The total number of enums doesn't match the names array.");
    if (type >= ARRAYSIZE(names))
        return L"(unknown)";

    return names[type];
}


void FontTableTree::ForEachSerial(
    ForEachFunction callback
    )
{
    const uint32_t itemCount = GetSize();

    // Call back for each item and for each entry/exit.
    for (uint32_t i = 0; i < itemCount; ++i)
    {
        Item& item = items_[i];
        callback(item, i, ForEachModeNode);
    }
}


void FontTableTree::ForEach(
    uint32_t rootIndex,
    bool shouldSkipRoot,
    ForEachFunction callback
    )
{
    uint32_t stack[MaximumStackSize];
    uint32_t stackDepth = 0;
    uint32_t i = rootIndex;
    const uint32_t itemCount = GetSize();

    // Check to start at first child index (which will not print the root node).
    if (shouldSkipRoot)
    {
        i = items_[i].childIndex;
        if (i == 0)
        {
            return; // No children.
        }
    }
    if (i >= itemCount)
    {
        return; // Starting node invalid.
    }

    // Call back for each item and for each entry/exit.
    do
    {
        Item& item = items_[i];

        callback(item, i, ForEachModeNode);

        assert(item.childIndex < itemCount);
        if (item.childIndex != 0 && item.childIndex < itemCount && stackDepth < ARRAYSIZE(stack))
        {
            // Entering to children of the item. Push current node.
            stack[stackDepth++] = i;
            callback(item, i, ForEachModeEnter);
            i = item.childIndex;
        }
        else
        {
            if (item.flags & item.FlagTerminal)
            {
                // Exiting from children of the item. Pop nodes until we can move forward again.
                for (;;)
                {
                    if (stackDepth == 0)
                        return;

                    assert(i >= items_[stack[stackDepth - 1]].childIndex);
                    i = stack[--stackDepth];
                    Item& parentItem = items_[i];
                    callback(parentItem, i, ForEachModeExit);

                    // Loop so long as the parents are the last node.
                    if (!(parentItem.flags & parentItem.FlagTerminal))
                    {
                        break; // There are more items after this one.
                    }
                }
            }
            ++i; // Next item.
        }

        assert(itemCount == items_.size()); // caller should not mess with the array while being iterated.

    } while (i > 0 && i < itemCount);
}


void FontTableTree::Print(
    uint32_t rootIndex,
    bool shouldSkipRoot,
    uint32_t indent,
    Item::Flag requiredMask,
    Item::Flag excludedMask,
    PrintFunction printFunction
    ) const
{
    FontTableTree::ForEachFunction callback = [&](Item& item, uint32_t itemIndex, ForEachMode mode) -> void
    {
        // Print items that match the mask.
        // Silently ignore intermediate nodes.
        switch (mode)
        {
        case ::FontTableTree::ForEachModeNode:
            if (item.type != item.TypeNode
            &&  !(item.flags & excludedMask)
            &&   (item.flags & requiredMask) == requiredMask)
            {
                wchar_t text[5] = {}; // text[4] is terminating nul
                text[0] = item.tag[0];
                text[1] = item.tag[1];
                text[2] = item.tag[2];
                text[3] = item.tag[3];
                printFunction(item, indent, text);
            }
            break;

        case ::FontTableTree::ForEachModeEnter:
            if (item.type != item.TypeNode)
            {
                ++indent;
            }
            break;

        case ::FontTableTree::ForEachModeExit:
            if (item.type != item.TypeNode)
            {
                --indent;
            }
            break;
        }
    };

    ForEach(rootIndex, shouldSkipRoot, callback);
}

struct PropagateFlags_AndOr
{
    FontTableTree::Item::Flag andFlags;
    FontTableTree::Item::Flag orFlags;

    void Reset()
    {
        andFlags = ::FontTableTree::Item::FlagAllBits;
        orFlags  = ::FontTableTree::Item::FlagNone;
    }

    void Reset(FontTableTree::Item::Flag andMask, FontTableTree::Item::Flag orMask)
    {
        andFlags = andMask & ::FontTableTree::Item::FlagAllBits;
        orFlags  = ::FontTableTree::Item::FlagNone;
    }

    void Combine(FontTableTree::Item::Flag flags)
    {
        andFlags &= flags;
        orFlags  |= flags;
    }

    void Combine(PropagateFlags_AndOr const& andOr)
    {
        andFlags &= andOr.andFlags;
        orFlags  |= andOr.orFlags;
    }

    void Mask(FontTableTree::Item::Flag andMask, FontTableTree::Item::Flag orMask)
    {
        andFlags &= andMask;
        orFlags  &= orMask;
    }

    ::FontTableTree::Item::Flag GetApplied(FontTableTree::Item::Flag flags)
    {
        return flags & ~andFlags | orFlags;
    }
};


void FontTableTree::PropagateFlags(
    uint32_t rootIndex,
    Item::Flag orMask,
    Item::Flag andMask,
    PropagateFlagsDirection direction
    )
{
    orMask  &= ~Item::FlagTerminal;    // just in case all bits are passed (propagating this flag would screw up things)
    andMask &= ~Item::FlagTerminal;

    PropagateFlags_AndOr flagsStack[MaximumStackSize];
    PropagateFlags_AndOr currentFlags;
    uint32_t stackDepth;

    if (direction & PropagateFlagsDirectionDown)
    {
        currentFlags.Reset(andMask, orMask);
        stackDepth = 0;

        // For every node, propagate masked flags from parents to children nodes.

        FontTableTree::ForEachFunction callback = [&](Item& item, uint32_t itemIndex, ForEachMode mode) -> void
        {
            switch (mode)
            {
            case ::FontTableTree::ForEachModeNode:
                // Apply parent flags to child.
                item.flags = currentFlags.GetApplied(item.flags);
                break;

            case ::FontTableTree::ForEachModeEnter:
                // Save flags at this level and combine parent flags for children.
                assert(stackDepth < MaximumStackSize);
                flagsStack[stackDepth++] = currentFlags;
                currentFlags.Combine(item.flags);
                currentFlags.Mask(andMask, orMask);
                break;

            case ::FontTableTree::ForEachModeExit:
                // Restore item's parent flags.
                assert(stackDepth > 0);
                currentFlags = flagsStack[--stackDepth];
                break;
            }
        };

        ForEach(rootIndex, false, callback);
        assert(stackDepth == 0);
    }

    if (direction & PropagateFlagsDirectionUp)
    {
        currentFlags.Reset(andMask, orMask);
        stackDepth = 0;

        // For every node, propagate masked flags from children nodes upward to parents.

        FontTableTree::ForEachFunction callback = [&](Item& item, uint32_t itemIndex, ForEachMode mode) -> void
        {
            switch (mode)
            {
            case ::FontTableTree::ForEachModeNode:
                // Accumulate child flags for parent node.
                currentFlags.Combine(item.flags);
                break;

            case ::FontTableTree::ForEachModeEnter:
                // Save accumulated flags at this level, and reset for the lower level of children.
                assert(stackDepth < MaximumStackSize);
                flagsStack[stackDepth++] = currentFlags;
                currentFlags.Reset(andMask, orMask);
                break;

            case ::FontTableTree::ForEachModeExit:
                // Apply accumulated flags of children, and resume accumulated flags at this level.
                assert(stackDepth > 0);
                currentFlags.Mask(andMask, orMask);
                item.flags = currentFlags.GetApplied(item.flags);
                currentFlags.Combine(flagsStack[--stackDepth]);
                break;
            }
        };

        ForEach(rootIndex, false, callback);
        assert(stackDepth == 0);
    }
}
