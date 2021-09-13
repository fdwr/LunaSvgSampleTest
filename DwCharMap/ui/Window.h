//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface window.
//
//----------------------------------------------------------------------------
#pragma once


class Window : public UiContainer
{
public:
    typedef UiContainer Base;

public:
    Window(UiControl* parent);

    Window(UiControl* parent, __in_z_opt const wchar_t* text, __maybenull InlineImage* image = NULL, int id = 0);

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool MousePress(MouseMessage& message) OVERRIDE;
    virtual bool KeyPress(KeyboardMessage& message) OVERRIDE;

    virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position) OVERRIDE;
    virtual bool SetPosition(const Position& position) OVERRIDE;

protected:
    Window()
    {
        Init();
    }

private: // just so the derived class doesn't accidentally call in when it meant to its own
    inline void Init()
    {
        // Windows are not repositioned like other controls.
        SetStyleDirectly(StyleFlagFloating);
    }
};
