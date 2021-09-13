//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface ribbon.
//
//----------------------------------------------------------------------------
#pragma once


class Ribbon : public UiContainer
{
public:
    typedef UiContainer Base;

public:
    Ribbon(UiControl* parent);

    Ribbon(UiControl* parent, int id = 0);

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position) OVERRIDE;
    virtual bool SetPosition(const Position& position) OVERRIDE;

protected:
    Ribbon()
    {
        Init();
    }

    inline void Init()
    {
        // Ribbon chunks should not wrap down to next line.
        SetStyleDirectly(StyleFlagUnwrapped|StyleFlagDisabledKeyFocus);
    }
};
