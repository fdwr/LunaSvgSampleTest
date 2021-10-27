//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface button.
//
//----------------------------------------------------------------------------
#include "precomp.h"


Button::Button(UiControl* parent)
{
    Init();
    if (!Create(parent))
        throw std::exception("Could not create Button" FAILURE_LOCATION);
}


Button::Button(UiControl* parent, __in_z_opt const wchar_t* text, __maybenull InlineImage* image, int id, Behavior behavior)
{
    Init();
    SetBehavior(behavior);
    id_ = id;

    if (!Create(parent))
        throw std::exception("Could not create Button" FAILURE_LOCATION);

    SetLabel(text, image);
}


bool Button::Destroy()
{
    // Explicitly clear owner to remove references sooner.
    // Otherwise we would hold onto them until the destructor
    // was called.
    owner_.Clear();
    return Base::Destroy();
}


bool Button::Draw(RenderTarget& target, const Position& rect)
{
    if (IsPushed())
    {
        target.DrawNineGridImage(
            Base::gTheme_->GetImage(),
            Base::gTheme_->GetImageParts(ThemePartIdButtonPushed),
            rect
            );
    }
    else if (HasKeyFocus() || HasMouseFocus())
    {
        target.DrawNineGridImage(
            Base::gTheme_->GetImage(),
            Base::gTheme_->GetImageParts(ThemePartIdButtonMouseFocus),
            rect
            );
    }
    else
    {
        target.DrawNineGridImage(
            Base::gTheme_->GetImage(),
            Base::gTheme_->GetImageParts(ThemePartIdButton),
            rect
            );
    }

    Position textRect = Base::gTheme_->GetDeflatedImagePart(rect, ThemePartIdButtonMargin);
    target.DrawTextLayout(textLayout_, textRect);

    return true;
}


// Input related...

bool Button::MouseEnter(MouseMessage& message)
{
    SetRedraw();
    return true;
}


bool Button::MouseExit(MouseMessage& message)
{
    CancelActivate();
    SetRedraw();
    return true;
}


bool Button::MousePress(MouseMessage& message)
{
    if (message.button == MouseMessage::ButtonLeft)
        Activate(ActivateModePress);
    return true;
}


bool Button::MouseRelease(MouseMessage& message)
{
    Activate(ActivateModeRelease);
    return true;
}


bool Button::KeyEnter(KeyboardMessage& message)
{
    SetRedraw();
    return true;
}


bool Button::KeyExit(KeyboardMessage& message)
{
    CancelActivate();
    SetRedraw();
    return true;
}


bool Button::KeyPress(KeyboardMessage& message)
{
    if (message.button == VK_SPACE && message.repeatCount <= 1)
    {
        Activate(ActivateModePress);
        return true;
    }
    else if (message.button == VK_RETURN)
    {
        Activate(ActivateModeDirect);
        return true;
    }
    return false;
}


bool Button::KeyRelease(KeyboardMessage& message)
{
    if (message.button == VK_SPACE)
    {
        Activate(ActivateModeRelease);
        return true;
    }
    return false;
}


void Button::Activate(ActivateMode activateMode)
{
    bool activated;

    switch (activateMode)
    {
    case ActivateModePress:
        activated  = IsActiveOnPress(); // activate on press
        SetBehavior(BehaviorPushed);
        break;

    case ActivateModeRelease:
        activated  = !IsActiveOnPress() && IsPushed(); // activate on push+release
        ClearBehavior(BehaviorPushed);
        break;
    
    default: // direct activate like Enter keypress
        activated  = true;
        ClearBehavior(BehaviorPushed);
        break;
    }

    if (activated)
    {
        // Update the active state based on the type of button...

        if (IsToggle())
        {
            // toggle the state (like a checkbox)
            StyleFlag activeFlag = (styleFlags_ & StyleFlagActive) ^ StyleFlagActive;
            SetStyle(activeFlag, StyleFlagActive);
        }
        else if (IsSwitch())
        {
            if (!IsActive()) // activate, but only if not already so
                SetStyle(StyleFlagActive);
        }
        else // normal pushbutton
        {
            // pushbuttons don't change active state on click
        }

        // If any significant change occurred, inform owner
        UiControlRefPtr keepAlive(this);
        if (owner_.IsSet())
        {
            owner_.callback->Activated(this, id_, IsActive());
        }
    }
}


void Button::CancelActivate()
{
    if (IsPushed())
    {
        ClearBehavior(BehaviorPushed);
    	SetRedraw();
    }
}


bool Button::SetLabel(__in_z_opt const wchar_t* text, __maybenull InlineImage* image)
{
    // Resize as needed by the text change,
    // allowing for expected margin.
    SetReflow();
    Base::gTheme_->CreateTextLayout(
        Base::gDWriteFactory_,
        text,
        ThemePartIdButton,
        position_,
        textLayout_
        );
    Base::gTheme_->ApplyImageOverText(image, text, textLayout_);

    return true;
}


bool Button::SetBehavior(Behavior behavior)
{
    behavior_ |= behavior;
    SetRedraw();
    return true;
}


bool Button::ClearBehavior(Behavior behavior)
{
    behavior_ &= ~behavior;
    SetRedraw();
    return true;
}


void Button::SetOwner(RefCountBase* target, Owner* owner)
{
    owner_.Set(target, owner);
}


bool Button::GetOwner(__deref_opt_out RefCountBase** target, __deref_opt_out Owner** owner)
{
    return owner_.Get(target, owner);
}


bool Button::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    return GetPositionWithMargin(ThemePartIdButtonMargin, positionQuery, position);
}


bool Button::SetPosition(const Position& position)
{
    return SetPositionWithMargin(ThemePartIdButtonMargin, position);
}
