//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface button.
//
//----------------------------------------------------------------------------
#include "precomp.h"


FlatButton::FlatButton(UiControl* parent)
{
    if (!Create(parent))
        throw std::exception("Could not create FlatButton" FAILURE_LOCATION);
}


FlatButton::FlatButton(UiControl* parent, __in_z_opt const wchar_t* text, __maybenull InlineImage* image, int id, Behavior behavior)
{
    SetBehavior(behavior);
    id_ = id;

    if (!Create(parent))
        throw std::exception("Could not create FlatButton" FAILURE_LOCATION);

    SetLabel(text, image);
}


bool FlatButton::Draw(RenderTarget& target, const Position& rect)
{
    if (IsPushed())
    {
        target.DrawNineGridImage(
            Base::gTheme_->GetImage(),
            Base::gTheme_->GetImageParts(ThemePartIdFlatButtonPushed),
            rect
            );
    }
    else if (HasKeyFocus() || HasMouseFocus() || IsActive())
    {
        target.DrawNineGridImage(
            Base::gTheme_->GetImage(),
            Base::gTheme_->GetImageParts(ThemePartIdFlatButtonActive),
            rect
            );
    }
    else
    {                                                                                               
        target.DrawNineGridImage(
            Base::gTheme_->GetImage(),
            Base::gTheme_->GetImageParts(ThemePartIdFlatButton),
            rect
            );
    }

    Position textRect = Base::gTheme_->GetDeflatedImagePart(rect, ThemePartIdFlatButtonMargin);
    target.DrawTextLayout(textLayout_, textRect);

    return true;
}


bool FlatButton::SetLabel(__in_z_opt const wchar_t* text, __maybenull InlineImage* image)
{
    SetRedraw();
    if (!HasRigidWidth())
        SetReflow();

    Base::gTheme_->CreateTextLayout(
        Base::gDWriteFactory_,
        text,
        ThemePartIdFlatButton,
        position_,
        textLayout_
        );
    Base::gTheme_->ApplyImageOverText(image, text, textLayout_);

    // Set default attributes.
    const static DWRITE_TRIMMING trimming = { DWRITE_TRIMMING_GRANULARITY_CHARACTER, 0, 0 };
    textLayout_->SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
    textLayout_->SetTrimming(&trimming, NULL);

    return true;
}


bool FlatButton::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    return GetPositionWithMargin(ThemePartIdFlatButtonMargin, positionQuery, position);
}


bool FlatButton::SetPosition(const Position& position)
{
    return SetPositionWithMargin(ThemePartIdFlatButtonMargin, position);
}
