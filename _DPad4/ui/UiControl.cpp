//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface base control for others to inherit from.
//
//----------------------------------------------------------------------------
#include "precomp.h"


RefCountPtr<UiTheme> UiControl::gTheme_;
ComPtr<IDWriteFactory> UiControl::gDWriteFactory_;


//////////////////////////////
// Lifetime...

bool UiControl::Create(UiControl* parent)
{
    if (parent != NULL)
        return parent->InsertChild(this);

    return true; // NULL parent is allowed if it's a root window
}


bool UiControl::Destroy()
{
    // Prevent any further interaction of any kind with this object
    SetStyleDirectly(StyleFlag( StyleFlagZombie|StyleFlagDisabled|StyleFlagHidden ),
                     StyleFlag( StyleFlagMouseFocus|StyleFlagKeyFocus ));

    if (parent_ != NULL)
        return parent_->DeleteChild(this);

    // Don't call delete operator here. Instead, let all references be removed.
    // The object should not refer to any of its members after this point,
    // since the DeleteChild likely reduced the ref count to zero.
    return false;
}


//////////////////////////////
// Drawing...

bool UiControl::Draw(RenderTarget& target, const Position& rect)
{
    return false;
}


//////////////////////////////
// Input related...

bool UiControl::MouseEnter(MouseMessage& message)
{
    return false; // unhandled
}


bool UiControl::MouseExit(MouseMessage& message)
{
    return false; // unhandled
}


bool UiControl::MousePress(MouseMessage& message)
{
    return false; // unhandled
}


bool UiControl::MouseRelease(MouseMessage& message)
{
    return false; // unhandled
}


bool UiControl::MouseMove(MouseMessage& message)
{
    return false; // unhandled
}


bool UiControl::MouseScroll(MouseMessage& message)
{
    return false; // unhandled
}


bool UiControl::SetMouseFocus(UiControl* newChild, MouseMessage& message, bool chainParents)
{
    return false; // unhandled
}


bool UiControl::KeyEnter(KeyboardMessage& message)
{
    return false; // unhandled
}


bool UiControl::KeyExit(KeyboardMessage& message)
{
    return false; // unhandled
}


bool UiControl::KeyPress(KeyboardMessage& message)
{
    return false; // unhandled
}


bool UiControl::KeyRelease(KeyboardMessage& message)
{
    return false; // unhandled
}


bool UiControl::KeyCharacter(KeyboardMessage& message)
{
    return false; // unhandled
}


bool UiControl::SetKeyFocus(UiControl* child, bool chainParents)
{
    return false; // unhandled
}


//////////////////////////////
// Management of children...

bool UiControl::InsertChild(UiControl* child)
{
    return false; // unhandled
}


bool UiControl::InsertChild(UiControl* child, size_t index)
{
    return false; // unhandled
}


bool UiControl::DeleteChild(UiControl* child)
{
    return false; // unhandled
}


bool UiControl::DeleteChild(size_t index)
{
    return false; // unhandled
}


bool UiControl::GetChild(const UiControl* child, __out size_t* index)
{
    *index = 0;
    return false; // unhandled
}


bool UiControl::GetChild(size_t index, __out UiControlRefPtr& child)
{
    child.Set(NULL);
    return false; // unhandled
}


bool UiControl::SetPosition(const Position& position)
{
    // Set new position and inform parent of needed reflow.
    position_ = position;
    return true;
}


bool UiControl::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    switch (positionQuery)
    {
    case PositionQueryAbsolute:
        // Want the absolute position of the control
        // within the root of the heirarchy.

        if (parent_ == NULL) // already at top of chain
        {
            *position = position_;
        }
        else // add parent's offset to control
        {
            parent_->GetPosition(positionQuery, position);
            position->x += position_.x;
            position->y += position_.y;
            position->w  = position_.w;
            position->h  = position_.h;
        }
        break;

    case PositionQueryPreferred:
    case PositionQueryRelative:
    default:
        // Just return the current position.
        *position = position_;
        return false;
    };

    return true;
}


bool UiControl::SetStyle(StyleFlag set, StyleFlag clear)
{
    // Just set the new style. Derived controls can override
    // this and do what they need (maybe redraw or reposition
    // themselves).
    SetStyleDirectly(set, clear);
    return true;
}


void UiControl::SetStyleToParents(UiControl* control, StyleFlag set, StyleFlag clear)
{
    // Set the given style flags from the current control upward,
    // until we reach a control where the change would make no
    // difference or until the top of the chain.
    // This is typically used for redrawing or layout reflow.

    while (control != NULL)
    {
        // Stop progressing if no change would occur.
        if (((control->styleFlags_ & ~clear) | set) == control->styleFlags_)
            break;
        control->SetStyle(set, clear);
        control = control->parent_;
    }
}


UiControl* UiControl::GetRoot()
{
    // Finds the root in the heirarchy this control
    // is contained. If the control has no parent
    // (like the main window), the given control
    // is the/ root.

    UiControl* control = this;
    for (;;)
    {
        if (control->parent_ == NULL)
            return control;

        control = control->parent_;
    }
}
