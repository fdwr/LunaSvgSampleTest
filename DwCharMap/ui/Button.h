//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface button.
//
//----------------------------------------------------------------------------
#pragma once


class Button : public Label
{
public:
    typedef Label Base;

    interface Owner
    {
        virtual bool Activated(Button* source, int id, int value) = NULL;
    };

    enum Behavior
    {
        BehaviorDefault       = 0, // typical push-button, activate on press+release
        BehaviorPushed        = 1, // is pushed in
        BehaviorActiveOnPress = 2, // activates on push, rather than press+release
        BehaviorToggle        = 4, // toggles between active and inactive
        BehaviorSwitch        = 8  // is one of many choices, each mutually exclusive
    };

public:
    Button(UiControl* parent);

    Button(UiControl* parent, __in_z_opt const wchar_t* text, __maybenull InlineImage* image = NULL, int id = 0, Behavior behavior = BehaviorDefault);

    virtual bool Destroy() OVERRIDE;

    // Input dispatch
    virtual bool MouseEnter(MouseMessage& message) OVERRIDE;
    virtual bool MouseExit(MouseMessage& message) OVERRIDE;
    virtual bool MousePress(MouseMessage& message) OVERRIDE;
    virtual bool MouseRelease(MouseMessage& message) OVERRIDE;
    virtual bool KeyEnter(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyExit(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyPress(KeyboardMessage& message) OVERRIDE;
    virtual bool KeyRelease(KeyboardMessage& message) OVERRIDE;

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position) OVERRIDE;
    virtual bool SetPosition(const Position& position) OVERRIDE;

    void SetOwner(RefCountBase* target, Owner* listener);
    bool GetOwner(__deref_opt_out RefCountBase** target, __deref_opt_out Owner** listener);

    virtual bool SetLabel(__in_z_opt const wchar_t* text, __maybenull InlineImage* image = NULL);

    bool SetBehavior(Behavior behavior);
    bool ClearBehavior(Behavior behavior);
    inline Behavior GetBehavior() {return behavior_;}
    inline bool IsSwitch()        {return (behavior_ & BehaviorSwitch) != 0;}
    inline bool IsToggle()        {return (behavior_ & BehaviorToggle) != 0;}
    inline bool IsPushed()        {return (behavior_ & BehaviorPushed) != 0;}
    inline bool IsActiveOnPress() {return (behavior_ & BehaviorActiveOnPress) != 0;}

protected:
    enum ActivateMode
    {
        ActivateModePress,
        ActivateModeRelease,
        ActivateModeDirect
    };

    Button()
    {
        Init();
    }

    void Activate(ActivateMode activateMode);
    void CancelActivate();

protected:
    Behavior behavior_;
    UiDelegate<Owner> owner_;

private:
    inline void Init()
    {
        behavior_ = BehaviorDefault;
        ClearStyleDirectly(StyleFlagDisabledKeyFocus);
    }
};

DEFINE_ENUM_FLAG_OPERATORS(Button::Behavior);
