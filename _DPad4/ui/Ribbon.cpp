//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface ribbon.
//
//----------------------------------------------------------------------------
#include "precomp.h"


Ribbon::Ribbon(UiControl* parent)
{
    Init();
    if (!Create(parent))
        throw std::exception("Could not create Ribbon" FAILURE_LOCATION);
}


Ribbon::Ribbon(UiControl* parent, int id)
{
    Init();
    id_ = id;

    if (!Create(parent))
        throw std::exception("Could not create Ribbon" FAILURE_LOCATION);
}


bool Ribbon::Draw(RenderTarget& target, const Position& rect)
{
    target.DrawNineGridImage(
        Base::gTheme_->GetImage(),
        Base::gTheme_->GetImageParts(ThemePartIdRibbon),
        rect
        );
    return Base::Draw(target, rect);
}


bool Ribbon::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    switch (positionQuery)
    {
    case PositionQueryPreferred:
        if (NeedsReflow())
        {
            Position clientRect = {0,0,FLT_MAX,FLT_MAX}; // allow unlimited size
            Position resultRect = ReflowChildrenSequential(children_, clientRect, 0, styleFlags_, ReflowOptionQueryOnly);
            resultRect = Base::gTheme_->GetInflatedImagePart(resultRect, ThemePartIdRibbonPadding);
            preferredPosition_ = Base::gTheme_->GetMaxImagePart(resultRect, ThemePartIdRibbonDefaultSize);
        }
        // don't return it directly - just let the base class do that
        __fallthrough;

    default:
        return Base::GetPosition(positionQuery, position);
    }
}


bool Ribbon::SetPosition(const Position& position)
{
    // Reposition all children
    Base::SetPosition(position);
    Position clientRect = MakePosition(0,0, position.w, position.h);
    clientRect = Base::gTheme_->GetDeflatedImagePart(clientRect, ThemePartIdRibbonPadding);
    ReflowChildrenSequential(children_, clientRect, 0, styleFlags_, ReflowOptionDefault);
    return true;
}
