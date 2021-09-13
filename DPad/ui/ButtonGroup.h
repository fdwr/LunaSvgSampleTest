//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface button group.
//              Clusters several buttons tightly, either push buttons or
//              option buttons.
//
//----------------------------------------------------------------------------
#pragma once


class ButtonGroup : public UiControl, public Button::Owner
{
public:
    typedef UiControl Base;
    typedef Button::Owner Owner;

public:
    ButtonGroup(UiControl* parent);

    ButtonGroup(UiControl* parent, int id, bool hasBorder = false);

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool InsertChild(UiControl* child) OVERRIDE;
    virtual bool InsertChild(UiControl* child, size_t index) OVERRIDE;
    virtual bool DeleteChild(UiControl* child) OVERRIDE;

    // The indexed DeleteChild and GetChild don't really make sense here, since
    // the children are truly contained by the button group's parent. So they are
    // left unimplemented and return false.

    virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position) OVERRIDE;
    virtual bool SetPosition(const Position& position) OVERRIDE;

    void SetOwner(RefCountBase* target, Owner* listener);
    bool GetOwner(__deref_opt_out RefCountBase** target, __deref_opt_out Owner** listener);

    bool SetActiveMember(int id);
    bool SetActiveMember(UiControl* newActiveMember);

    // Callbacks...
    bool Activated(Button* source, int id, int value);

protected:
    ButtonGroup()
    {
        Init();
    }

    void Init()
    {
        hasBorder_ = false;
        preferredPosition_.SetZero();
        SetStyleDirectly(StyleFlagDisabledKeyFocus);
    }

protected:
    std::vector<UiControlRefPtr> members_; // not children, but members
    UiDelegate<Owner> owner_;
    Position preferredPosition_;
    bool hasBorder_;
};
