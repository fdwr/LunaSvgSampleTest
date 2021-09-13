//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface static label.
//
//----------------------------------------------------------------------------
#pragma once


class Label : public UiControl
{
public:
    typedef UiControl Base;

public:
    Label(UiControl* parent);

    Label(UiControl* parent, __in_z_opt const wchar_t* text, __maybenull InlineImage* image = NULL, int id = 0);

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position) OVERRIDE;
    virtual bool SetPosition(const Position& position) OVERRIDE;

    virtual bool SetLabel(__in_z_opt const wchar_t* text, __maybenull InlineImage* image = NULL);

protected:
    Label()
    {
        Init();
    }

    void Init()
    {
        SetStyleDirectly(StyleFlagDisabledKeyFocus);
    }

    bool GetPositionWithMargin(UiTheme::ThemePartId marginPartId, PositionQuery positionQuery, __inout Position* position);
    bool SetPositionWithMargin(UiTheme::ThemePartId partId, const Position& position);

protected:
    ComPtr<IDWriteTextLayout> textLayout_;
};
