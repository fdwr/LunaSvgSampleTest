//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface static label.
//
//----------------------------------------------------------------------------
#include "precomp.h"


Label::Label(UiControl* parent)
{
    Init();

    if (!Create(parent))
        throw std::exception("Could not create Label" FAILURE_LOCATION);
}


Label::Label(UiControl* parent, __in_z_opt const wchar_t* text, __maybenull InlineImage* image, int id)
{
    Init();
    id_ = id;

    if (!Create(parent))
        throw std::exception("Could not create Label" FAILURE_LOCATION);

    SetLabel(text, image);
}


bool Label::Draw(RenderTarget& target, const Position& rect)
{
    // Labels have no background or border, just text and/or images.

    target.DrawTextLayout(textLayout_, rect);
    return true;
}


bool Label::SetLabel(__in_z_opt const wchar_t* text, __maybenull InlineImage* image)
{
    // Resize as needed by the text change.
    // (there is no margin to adjust on labels)
    SetReflow();
    SetRedraw();
    Base::gTheme_->CreateTextLayout(
        Base::gDWriteFactory_,
        text,
        ThemePartIdLabel,
        position_,
        textLayout_
        );
    return true;
}


bool Label::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    return GetPositionWithMargin(ThemePartIdLabelMargin, positionQuery, position);
}


bool Label::GetPositionWithMargin(
    UiTheme::ThemePartId marginPartId,
    PositionQuery positionQuery,
    __inout Position* position
    )
{
    switch (positionQuery)
    {
    case PositionQueryPreferred:
        if (textLayout_ != NULL)
        {
            // Recalculate the minimum reasonable size.
            // (temporarily disable wrapping)
            DWRITE_TEXT_METRICS textMetrics;
            DWRITE_WORD_WRAPPING wrapping = textLayout_->GetWordWrapping();
            float maxWidth = textLayout_->GetMaxWidth();
            if (!HasRigidWidth())
            {
                textLayout_->SetMaxWidth(FLT_MAX);
                textLayout_->SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
            }
            textLayout_->GetMetrics(&textMetrics);
            if (!HasRigidWidth())
            {
                textLayout_->SetMaxWidth(maxWidth);
                textLayout_->SetWordWrapping(wrapping);
            }

            position->x = 0;
            position->y = 0;
            position->w = ceil(textMetrics.width );
            position->h = ceil(textMetrics.height);

            *position = Base::gTheme_->GetInflatedImagePart(*position, marginPartId);
            return true;
        }
        __fallthrough;

    default:
        return Base::GetPosition(positionQuery, position);
    }
}



bool Label::SetPosition(const Position& position)
{
    return SetPositionWithMargin(ThemePartIdLabelMargin, position);
}


bool Label::SetPositionWithMargin(UiTheme::ThemePartId marginPartId, const Position& position)
{
    if (textLayout_ != NULL)
    {
        // Sync layout to control's new size
        Position textRect = Base::gTheme_->GetDeflatedImagePart(position, marginPartId);
        textLayout_->SetMaxWidth(textRect.w);
        textLayout_->SetMaxHeight(textRect.h);
    }
    return Base::SetPosition(position);
}
