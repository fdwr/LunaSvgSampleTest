//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface ribbon chunk.
//
//----------------------------------------------------------------------------
#include "precomp.h"


StatusBar::StatusBar(UiControl* parent, int id)
{
    Init();
    id_ = id;

    if (!Create(parent))
        throw std::exception("Could not create StatusBar" FAILURE_LOCATION);
}


bool StatusBar::Draw(RenderTarget& target, const Position& rect)
{
    target.DrawNineGridImage(
        Base::gTheme_->GetImage(),
        Base::gTheme_->GetImageParts(ThemePartIdStatusBar),
        rect
        );

    return Base::Draw(target, rect);
}


bool StatusBar::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    switch (positionQuery)
    {
    case PositionQueryPreferred:
        {
            Position clientRect = {0,0,FLT_MAX,FLT_MAX}; // allow unlimited size
            Position resultRect = ReflowChildrenSequential(children_, clientRect, 0, styleFlags_, ReflowOptionQueryOnly);
            preferredPosition_ = Base::gTheme_->GetInflatedImagePart(resultRect, ThemePartIdStatusBarPadding);
        }
        // don't return it directly - just let the base class do that
        __fallthrough;

    default:
        return Base::GetPosition(positionQuery, position);
    }
}


bool StatusBar::SetPosition(const Position& position)
{
    // Reposition all children
    Base::SetPosition(position);
    Position clientRect = MakePosition(0,0, position.w, position.h);
    clientRect = Base::gTheme_->GetDeflatedImagePart(clientRect, ThemePartIdStatusBarPadding);
    ReflowChildrenSequential(children_, clientRect, 0, styleFlags_, ReflowOptionDefault);
    return true;
}


StatusBar::Divider::Divider(UiControl* parent)
{
    id_ = 0;

    // Dividers should be as tall as their containing parent
    // (the parent is generally a status bar, but could be
    //  another container type like a ribbon chunk).
    SetStyleDirectly(StyleFlagTall);

    if (!Create(parent))
        throw std::exception("Could not create StatusBar Divider" FAILURE_LOCATION);
};


bool StatusBar::Divider::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    switch (positionQuery)
    {
    case PositionQueryPreferred:
        *position = Base::gTheme_->GetImagePart(ThemePartIdStatusBarDividerSize);
        return true;

    default:
        return Base::GetPosition(positionQuery, position);
    }
}


bool StatusBar::Divider::Draw(RenderTarget& target, const Position& rect)
{
    target.DrawNineGridImage(
        Base::gTheme_->GetImage(),
        Base::gTheme_->GetImageParts(ThemePartIdStatusBarDivider),
        rect
        );

    return Base::Draw(target, rect);
};
