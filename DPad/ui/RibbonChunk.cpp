//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface ribbon chunk.
//
//----------------------------------------------------------------------------
#include "precomp.h"


RibbonChunk::RibbonChunk(UiControl* parent)
{
    Init();
    if (!Create(parent))
        throw std::exception("Could not create RibbonChunk" FAILURE_LOCATION);
}


RibbonChunk::RibbonChunk(UiControl* parent, __in_z_opt const wchar_t* text, __maybenull InlineImage* image, int id)
{
    Init();
    id_ = id;

    if (!Create(parent))
        throw std::exception("Could not create RibbonChunk" FAILURE_LOCATION);

    SetLabel(text, image);
}


bool RibbonChunk::Draw(RenderTarget& target, const Position& rect)
{
    target.DrawNineGridImage(
        Base::gTheme_->GetImage(),
        Base::gTheme_->GetImageParts(ThemePartIdRibbonChunk),
        rect
        );

    Position textRect = Base::gTheme_->GetDeflatedImagePart(rect, ThemePartIdRibbonChunkMargin);
    target.DrawTextLayout(textLayout_, textRect);

    return Base::Draw(target, rect);
}


bool RibbonChunk::SetKeyFocus(UiControl* newChild, bool chainParents)
{
    bool success = Base::SetKeyFocus(newChild, chainParents);
    if (success && !HasKeyFocus())
    {
        UiControl::SetKeyFocus();
    }
    return success;
}


bool RibbonChunk::SetLabel(__in_z_opt const wchar_t* text, __maybenull InlineImage* image)
{
    // Resize as needed by the text change.
    SetReflow();

    Base::gTheme_->CreateTextLayout(
        Base::gDWriteFactory_,
        text,
        ThemePartIdRibbon,
        position_,
        textLayout_
        );
    Base::gTheme_->ApplyImageOverText(image, text, textLayout_);

    return true;
}


bool RibbonChunk::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    switch (positionQuery)
    {
    case PositionQueryPreferred:
        {
            Position clientRect = {0,0,FLT_MAX,FLT_MAX}; // allow unlimited size
            Position resultRect = ReflowChildrenSequential(children_, clientRect, 4, styleFlags_, ReflowOptionQueryOnly);
            preferredPosition_ = Base::gTheme_->GetInflatedImagePart(resultRect, ThemePartIdRibbonChunkPadding);
        }
        __fallthrough;

    default:
        return Base::GetPosition(positionQuery, position);
    }
}


bool RibbonChunk::SetPosition(const Position& position)
{
    if (position.SizeDiffers(position_))
    {
        if (textLayout_ != NULL)
        {
            // Sync layout to control's new size
            Position textRect = Base::gTheme_->GetDeflatedImagePart(position, ThemePartIdRibbonChunkMargin);
            textLayout_->SetMaxWidth(textRect.w);
            textLayout_->SetMaxHeight(textRect.h);
        }

        Base::SetPosition(position);

        // Reposition all children
        Position clientRect = MakePosition(0,0, position.w, position.h);
        clientRect = Base::gTheme_->GetDeflatedImagePart(clientRect, ThemePartIdRibbonChunkPadding);
        ReflowChildrenSequential(children_, clientRect, 4, styleFlags_, ReflowOptionDefault);
    }

    return true;
}
