//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface button.
//
//----------------------------------------------------------------------------
#pragma once


class FlatButton : public Button
{
public:
    typedef Button Base;

public:
    FlatButton(UiControl* parent);

    FlatButton(UiControl* parent, __in_z_opt const wchar_t* text, __maybenull InlineImage* image = NULL, int id = 0, Behavior behavior = BehaviorDefault);

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position) OVERRIDE;
    virtual bool SetPosition(const Position& position) OVERRIDE;

    virtual bool SetLabel(__in_z_opt const wchar_t* text, __maybenull InlineImage* image = NULL);

protected:
    FlatButton()
    { }
};
