//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface ribbon chunk.
//
//----------------------------------------------------------------------------
#pragma once


class RibbonChunk : public UiContainer
{
public:
    typedef UiContainer Base;

public:
    RibbonChunk(UiControl* parent);

    RibbonChunk(UiControl* parent, __in_z_opt const wchar_t* text, __maybenull InlineImage* image = NULL, int id = 0);

    virtual bool Draw(RenderTarget& target, const Position& rect) OVERRIDE;

    virtual bool GetPosition(PositionQuery positionQuery, __inout Position* position) OVERRIDE;
    virtual bool SetPosition(const Position& position) OVERRIDE;

    virtual bool SetLabel(__in_z_opt const wchar_t* text, __maybenull InlineImage* image = NULL);

    bool SetKeyFocus(UiControl* newChild, bool chainParents);

protected:
    RibbonChunk()
    { }

    inline void Init()
    {
        // Chunks should be as tall as the ribbon they are contained in.
        SetStyleDirectly(StyleFlagTall);
    }

protected:
    ComPtr<IDWriteTextLayout> textLayout_;
};
