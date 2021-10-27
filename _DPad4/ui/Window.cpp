//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface window.
//
//----------------------------------------------------------------------------
#include "precomp.h"


Window::Window(UiControl* parent)
{
    Init();
    if (!Create(parent))
        throw std::exception("Could not create Window" FAILURE_LOCATION);
}


Window::Window(UiControl* parent, __in_z_opt const wchar_t* text, __maybenull InlineImage* image, int id)
{
    Init();
    id_ = id;

    if (!Create(parent))
        throw std::exception("Could not create Window" FAILURE_LOCATION);
}


bool Window::Draw(RenderTarget& target, const Position& rect)
{
    target.DrawNineGridImage(
        Base::gTheme_->GetImage(),
        Base::gTheme_->GetImageParts(ThemePartIdWindow),
        rect
        );
    return Base::Draw(target, rect);
}


bool Window::MousePress(MouseMessage& message)
{
    bool messageAcknowledged = Base::MousePress(message);
    if (!HasKeyFocus())
        UiControl::SetKeyFocus();

    return messageAcknowledged;
}


bool Window::KeyPress(KeyboardMessage& message)
{
    bool messageAcknowledged = Base::KeyPress(message);
    if (messageAcknowledged)
        return messageAcknowledged;

    bool heldShift = (GetKeyState(VK_SHIFT) & 0x80) != 0;

    switch (message.button)
    {
    case VK_TAB:
        SelectNextKeyFocusChild(heldShift);
        return true;
    }
    return messageAcknowledged;
}


bool Window::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    switch (positionQuery)
    {
    case PositionQueryPreferred:
        if (NeedsReflow())
        {
            Position clientRect = {0,0,FLT_MAX,FLT_MAX}; // allow unlimited size
            Position resultRect = ReflowChildrenSequential(children_, clientRect, 8, styleFlags_, ReflowOptionQueryOnly);
            preferredPosition_ = Base::gTheme_->GetInflatedImagePart(resultRect, ThemePartIdWindowPadding);
        }
        // don't return it directly - just let the base class do that
        __fallthrough;

    default:
        return Base::GetPosition(positionQuery, position);
    }
}


bool Window::SetPosition(const Position& position)
{
    // Reposition all children
    Base::SetPosition(position);
    Position clientRect = MakePosition(0,0, position.w, position.h);
    clientRect = Base::gTheme_->GetDeflatedImagePart(clientRect, ThemePartIdWindowPadding);
    ReflowChildrenSequential(children_, clientRect, 8, styleFlags_, ReflowOptionDefault);
    return true;
}
