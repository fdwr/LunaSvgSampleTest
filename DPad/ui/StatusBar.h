//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface ribbon chunk.
//
//----------------------------------------------------------------------------
#pragma once


class StatusBar : public UiContainer
{
public:
    typedef UiContainer Base;

public:
    StatusBar(UiControl* parent, int id = 0);

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position) OVERRIDE;
    virtual bool SetPosition(const Position& position) OVERRIDE;

    class Divider : public UiControl
    {
    public:
        typedef UiControl Base;

        Divider(UiControl* parent);

        virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position) OVERRIDE;

        virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;
    };

protected:
    StatusBar()
    {
        Init();
    }

    inline void Init()
    {
        // Ribbon chunks should not wrap down to next line.
        SetStyleDirectly(StyleFlagDisabledKeyFocus);
    }
};
