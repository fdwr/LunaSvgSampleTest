//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface base control for others to inherit from.
//
//----------------------------------------------------------------------------
#pragma once


class RenderTarget;
class UiControl;


typedef RefCountPtr<UiControl> UiControlRefPtr;


class UiControl : public RefCountBase
{
public:
    enum StyleFlag
    {
        StyleFlagNone = 0,
        StyleFlagHidden             = 1 << 0,  /// not visible
        StyleFlagDisabled           = 1 << 1,  /// control not useable
        StyleFlagDisabledKeyFocus   = 1 << 2,  /// cannot receive key focus (like a label)
        StyleFlagDisabledMouseFocus = 1 << 3,  /// cannot receive mouse focus (will act is if invisible to mouse)
        StyleFlagKeyFocus           = 1 << 4,  /// has key focus
        StyleFlagMouseFocus         = 1 << 5,  /// has mouse focus (either mouse directly over or captured)
        StyleFlagActive             = 1 << 6,  /// currently active option (like an option group or checkbox)
        StyleFlagRedraw             = 1 << 7,  /// control needs to be redrawn
        StyleFlagReflow             = 1 << 8,  /// control has changed size/position and needs rearrangement by parent
        StyleFlagRigidWidth         = 1 << 9,  /// parent should keep existing width
        StyleFlagRigidHeight        = 1 << 10, /// parent should keep existing height
        StyleFlagWide               = 1 << 11, /// parent should make as wide as possible
        StyleFlagTall               = 1 << 12, /// parent should make as tall as possible
        StyleFlagFloating           = 1 << 13, /// parent should ignore the control in any layout decisions
        StyleFlagNewLine            = 1 << 14, /// parent should place this control on a new line in flow layout
        StyleFlagVertical           = 1 << 15, /// arrange vertically instead of horizontally
        StyleFlagReadingExplicit    = 1 << 16, /// reading direction is explicit, not inherited
        StyleFlagReadingLtr         = 0 << 17, /// reading direction is left-to-right (Latin, Thai, CJK)
        StyleFlagReadingRtl         = 1 << 17, /// reading direction is right-to-left (Arabic, Hebrew, Syriac)
        StyleFlagUnwrapped          = 1 << 18, /// flow does not wrap controls to next line
        StyleFlagZombie             = 1 << 31, /// control has been officially destroyed but not deleted yet

        StyleFlagDefault = StyleFlag(StyleFlagRedraw | StyleFlagReflow)
    };

    enum PositionQuery
    {
        PositionQueryRelative,      /// just returns current position
        PositionQueryAbsolute,      /// absolute position relative to root
        PositionQueryPreferred      /// preferred position, considering content
    };

    typedef bool (UiControl::*MouseMessageDelegate)(MouseMessage& message);
    typedef bool (UiControl::*KeyboardMessageDelegate)(KeyboardMessage& message);

public:
    // These fields are common to all controls and are directly readable.
    // Additionally, they are directly writeable by the immediate parent,
    // however any other code should call the appropriate setters.
    UiControlRefPtr parent_;
    Position position_;
    StyleFlag styleFlags_;
    int id_;

    // All controls share the same visual theme.
    static RefCountPtr<UiTheme> gTheme_;
    static ComPtr<IDWriteFactory> gDWriteFactory_;

public:
    UiControl::UiControl()
    :   styleFlags_(StyleFlagDefault),
        id_(0)
    {
        // Set a reasonable default size.
        position_.x = 0;
        position_.y = 0;
        position_.w = 100;
        position_.h = 100;
    }

    virtual ~UiControl()
    { }

    virtual bool Create(UiControl* parent);
    virtual bool Destroy();

    //////////////////////////////
    // Input related.

    virtual bool MouseEnter(MouseMessage& message);     /// mouse entered the control
    virtual bool MouseExit(MouseMessage& message);      /// mouse exited control rect
    virtual bool MousePress(MouseMessage& message);
    virtual bool MouseRelease(MouseMessage& message);
    virtual bool MouseMove(MouseMessage& message);
    virtual bool MouseScroll(MouseMessage& message);

    virtual bool KeyEnter(KeyboardMessage& message);    /// gained keyboard focus
    virtual bool KeyExit(KeyboardMessage& message);     /// lost keyboard focus
    virtual bool KeyPress(KeyboardMessage& message);
    virtual bool KeyRelease(KeyboardMessage& message);
    virtual bool KeyCharacter(KeyboardMessage& message);

    // Set the key focus to the given control
    virtual bool SetKeyFocus(UiControl* child, bool chainParents);
    virtual bool SetMouseFocus(UiControl* child, MouseMessage& message, bool chainParents);

    //////////////////////////////
    // Management of children

    virtual bool InsertChild(UiControl* child);
    virtual bool InsertChild(UiControl* child, size_t index);
    virtual bool DeleteChild(UiControl* child);
    virtual bool DeleteChild(size_t index);
    virtual bool GetChild(const UiControl* child, __out size_t* index);
    virtual bool GetChild(size_t index, __out UiControlRefPtr& child);

    virtual bool SetPosition(const Position& position);
    virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position);

    //////////////////////////////
    // Drawing

    virtual bool Draw(RenderTarget& target, const Position& rect);

    //////////////////////////////
    // Style changes

    // Set a new style, enabling new flags and clearing old ones.
    // Controls should not attempt to delete themselves or take focus during
    // this call. This is more of a notification of how they should be set
    // rather than a command to act accordingly.
    virtual bool SetStyle(StyleFlag set, StyleFlag clear = StyleFlagNone);

    inline bool ClearStyle(StyleFlag clear)
    {
        return SetStyle(StyleFlagNone, clear);
    }

public:
    // Little helpers
    inline bool IsHidden()          {   return (styleFlags_ & StyleFlagHidden)          != 0;   }
    inline bool NeedsRedraw()       {   return (styleFlags_ & StyleFlagRedraw)          != 0;   }
    inline bool NeedsReflow()       {   return (styleFlags_ & StyleFlagReflow)          != 0;   }
    inline bool IsFloating()        {   return (styleFlags_ & StyleFlagFloating)        != 0;   }
    inline bool IsVertical()        {   return (styleFlags_ & StyleFlagVertical)        != 0;   }
    inline bool HasRigidWidth()     {   return (styleFlags_ & StyleFlagRigidWidth)      != 0;   }
    inline bool HasRigidHeight()    {   return (styleFlags_ & StyleFlagRigidHeight)     != 0;   }
    inline bool IsActive()          {   return (styleFlags_ & StyleFlagActive)          != 0;   }
    inline bool WantsNewLine()      {   return (styleFlags_ & StyleFlagNewLine)         != 0;   }
    inline bool IsReadingInherited(){   return (styleFlags_ & StyleFlagReadingExplicit) == 0;   }
    inline bool IsReadingRtl()      {   return (styleFlags_ & StyleFlagReadingRtl)      != 0;   }
    inline bool HasKeyFocus()       {   return (styleFlags_ & StyleFlagKeyFocus)        != 0;   }
    inline bool HasMouseFocus()     {   return (styleFlags_ & StyleFlagMouseFocus)      != 0;   }
    inline bool CanGetKeyFocus()    {   return (styleFlags_ & (StyleFlagDisabled | StyleFlagHidden | StyleFlagDisabledKeyFocus | StyleFlagZombie)) == 0;   }
    inline bool CanGetMouseFocus()  {   return (styleFlags_ & (StyleFlagDisabled | StyleFlagHidden | StyleFlagDisabledMouseFocus | StyleFlagZombie)) == 0; }

    inline void SetRedraw()         {   SetStyleToParents(this, StyleFlagRedraw);       }
    inline void SetReflow()         {   SetStyleToParents(this, StyleFlagReflow);       }
    inline void SetReflowParent()   {   SetStyleToParents(parent_, StyleFlagReflow);    }

    void SetStyleToParents(UiControl* control, StyleFlag set, StyleFlag clear = StyleFlagNone);
    UiControl* GetRoot();

    inline void SetStyleDirectly(StyleFlag set);
    inline void ClearStyleDirectly(StyleFlag clear);
    inline void SetStyleDirectly(StyleFlag set, StyleFlag clear);

    inline bool SetKeyFocus(bool chainParents = true)
    {
        return (parent_ != NULL) ? parent_->SetKeyFocus(this,chainParents) : false;
    }

    inline bool SetMouseFocus(MouseMessage& message)
    {
        return (parent_ != NULL) ? parent_->SetMouseFocus(this,message,true) : false;
    }

    inline bool ReleaseMouseFocus(MouseMessage& message)
    {
        return (parent_ != NULL) ? parent_->SetMouseFocus(NULL,message,true) : false;
    }
};


// These global operators can't be declared inside the class.

DEFINE_ENUM_FLAG_OPERATORS(UiControl::StyleFlag);

inline void UiControl::SetStyleDirectly(StyleFlag set)
{
    styleFlags_ |= set;
}

inline void UiControl::ClearStyleDirectly(StyleFlag clear)
{
    styleFlags_ &= ~clear;
}

inline void UiControl::SetStyleDirectly(StyleFlag set, StyleFlag clear)
{
    (styleFlags_ &= ~clear) |= set;
}
