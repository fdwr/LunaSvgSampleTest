//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Scrollable list of items.
//
//----------------------------------------------------------------------------
#pragma once


class ListControl : public UiControl
{
public:
    typedef UiControl Base;

    enum SelectionSetMode
    {
        SelectionSetModeUp,         // line up
        SelectionSetModeDown,       // line down
        SelectionSetModeFirst,      // first item
        SelectionSetModeLast,       // last item
        SelectionSetModeAbsolute    // explicit position (for mouse click)
    };

    enum Behavior
    {
        BehaviorActiveOnRelease     = 1, // activates on release
        BehaviorActiveOnPress       = 2, // activates on push
        BehaviorActiveOnDoubleClick = 4, // activates on double click
        BehaviorDefault             = BehaviorActiveOnDoubleClick,
    };

    interface Owner
    {
        virtual bool SelectionChanged(ListControl* source, int id, size_t selectedItem) = NULL;
        virtual bool Activated(ListControl* source, int id, size_t selectedItem) = NULL;
        virtual bool Scrolled(ListControl* source, int id) = NULL;
    };

public:
    ListControl(UiControl* parent, int id, Behavior behavior = BehaviorDefault);

    virtual bool Destroy() OVERRIDE;

    // Input dispatch
    virtual bool MouseEnter(MouseMessage& message) OVERRIDE;
    virtual bool MouseExit(MouseMessage& message) OVERRIDE;
    virtual bool MousePress(MouseMessage& message) OVERRIDE;
    virtual bool MouseRelease(MouseMessage& message) OVERRIDE;
    virtual bool MouseMove(MouseMessage& message) OVERRIDE;
    virtual bool MouseScroll(MouseMessage& message) OVERRIDE;

    virtual bool KeyEnter(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyExit(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyPress(KeyboardMessage& message) OVERRIDE;

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position) OVERRIDE;

    // List specific...

    void SetOwner(RefCountBase* target, Owner* listener);
    bool GetOwner(__deref_opt_out RefCountBase** target, __deref_opt_out Owner** listener);

    bool SetBehavior(Behavior behavior) { behavior_ = Behavior(behavior_ | behavior); return true; }
    bool ClearBehavior(Behavior behavior) { behavior_ = Behavior(behavior_ & ~behavior); return true; }
    inline Behavior GetBehavior() {return behavior_;}
    inline bool IsActiveOnRelease() {return (behavior_ & BehaviorActiveOnRelease) != 0;}
    inline bool IsActiveOnPress() {return (behavior_ & BehaviorActiveOnPress) != 0;}
    inline bool IsActiveOnDoubleClick() {return (behavior_ & BehaviorActiveOnDoubleClick) != 0;}

    bool SetSelection(SelectionSetMode moveMode, size_t advance);

    // Currently selected item.
    size_t GetSelection();

    // Total items in list.
    // *The derived class returns this, depending on what kind of items it stores.
    virtual size_t GetItemCount();

    // Retrieves item specific data associated with the item.
    virtual void* GetItemData(size_t item);

    // Retrieves the scrollable region (typically larger than the list itself)
    bool GetScrollPosition(__out Position* position);

    // Scrolls if needed.
    bool EnsureItemIsVisible(size_t item);

    // Returns the index of the item at the given position,
    // returning false if outside the list.
    virtual bool GetItemFromPosition(float x, float y, __out size_t* item);

    // Gets the position (relative to the list, not caller)
    // of the given item.
    virtual bool GetPositionFromItem(size_t item, __out Position* position);

protected:
    ListControl()
    {
        Init();
    }

    inline void Init()
    {
        behavior_           = BehaviorDefault;
        selectedItem_       = 0;
        scrollPosition_     = MakePosition(0,0,0,0);
        currentlySelecting_ = 0;
    }

protected:
    Behavior behavior_;
    UiDelegate<Owner> owner_;
    size_t selectedItem_;

    // Width and height are size of the list area (uncropped by control size).
    // X and Y are the offset with that scrollable area.
    Position scrollPosition_;

    bool currentlySelecting_ : 1;
};

DEFINE_ENUM_FLAG_OPERATORS(ListControl::Behavior);
