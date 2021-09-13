//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Scrollable list of text items.
//
//----------------------------------------------------------------------------
#pragma once


class TextList : public ListControl
{
public:
    typedef ListControl Base;

public:
    TextList(UiControl* parent, int id, Base::Behavior behavior = BehaviorDefault);

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool KeyPress(KeyboardMessage& message) OVERRIDE;

    // List specific...

    size_t virtual GetItemCount();

    bool AddItem(const wchar_t* text, void* itemData = NULL);

    bool ClearItems();

    bool SortItems();

    // Returns the index of the item at the given position,
    // returning false if outside the list.
    virtual bool GetItemFromPosition(float x, float y, __out size_t* item) OVERRIDE;

    // Gets the position (relative to the list, not caller)
    // of the given item.
    virtual bool GetPositionFromItem(size_t item, __out Position* position) OVERRIDE;

    // Retrieves a temporary reference to the text.
    const wchar_t* GetItemText(size_t item);

    // Retrieves item specific data associated with the item.
    virtual void* GetItemData(size_t item) OVERRIDE;

protected:
    TextList()
    {
        Init();
    }

    inline void Init()
    {
        itemHeight_ = 20; // set to real value in constructor.
        SetStyleDirectly(StyleFlagRigidWidth);
    }

    // Calculates the height of a single item.
    float virtual DetermineItemHeight();

    struct Item
    {
        std::wstring text;
        void* data;

        Item(const wchar_t* initialText, void* initialData)
        :   text(initialText),
            data(initialData)
        { }

        bool operator < (const Item& other)
        {
            return text < other.text;
        }
    };

protected:
    float itemHeight_;
    std::vector<Item> items_;
};
