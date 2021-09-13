//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface container (no visible component).
//
//----------------------------------------------------------------------------
#include "precomp.h"


// Management of children...


UiContainer::UiContainer(UiControl* parent)
{
    Init();
    if (!Create(parent))
        throw std::exception("Could not create UiContainer." FAILURE_LOCATION);
}


bool UiContainer::Destroy()
{
    // Destroy self and all children too.
    // Switch them all so they can't try to
    // delete themselves while looping through them.
    std::vector<UiControlRefPtr> oldChildren;
    std::swap(children_, oldChildren);

    size_t totalChildren = oldChildren.size();
    for (size_t childIndex = 0; childIndex < totalChildren; ++childIndex)
    {
        // Destroy child and explicitly remove self as parent.
        UiControl& child = *oldChildren[childIndex];
        child.Destroy();
        child.parent_.Clear();
    }

    // Explicitly clear these now, rather than leave them
    // hanging around until this object is deleted itself.
    oldChildren.clear();
    keyFocusChild_.Clear();
    mouseFocusChild_.Clear();

    return Base::Destroy();
}


// Drawing...

bool UiContainer::Draw(RenderTarget& target, const Position& rect)
{
    // Draw all children.
    for (size_t childIndex = 0; childIndex < children_.size(); ++childIndex)
    {
        UiControl& child = *children_[childIndex];

        if (child.IsHidden())
            continue;

        Position childRect = {
            rect.x + child.position_.x,
            rect.y + child.position_.y,
            child.position_.w,
            child.position_.h
        };
        child.Draw(target, childRect);
        child.ClearStyleDirectly(StyleFlagRedraw);
    }

    return true;
}


// Child management...

bool UiContainer::InsertChild(UiControl* child)
{
    return InsertChild(child, children_.size());
}


bool UiContainer::InsertChild(UiControl* child, size_t childIndex)
{
    if (child == NULL)
        return false;

    if (childIndex >= children_.size())
        childIndex  = children_.size(); // append child to end

    // Child adopts container's directionality.
    if (child->IsReadingInherited())
        child->SetStyle(styleFlags_ & StyleFlagReadingRtl, StyleFlagReadingRtl);

    // Special case for inserting an existing back into self,
    // since it would otherwise insert a duplicate of the new child,
    // then likely remove the wrong one (unnecessarily unparenting
    // it in the process).

    if (child->parent_ == this)
    {
        size_t oldChildIndex = GetIndexOfChild(child);
        if (oldChildIndex < children_.size())
        {
            // Just move it to its new location in the list
            children_.insert(children_.begin() + childIndex, UiControlRefPtr(child));

            if (childIndex <= oldChildIndex)
                oldChildIndex++; // since we inserted one in front of it
            children_.erase(children_.begin() + oldChildIndex);

            SetReflow();
            return true;
        }
    }

    // Otherwise just insert it.
    children_.insert(children_.begin() + childIndex, UiControlRefPtr(child));

    // If child is already owned by another window, transfer it and set new owner.
    if (child->parent_ != NULL)
    {
        child->parent_->DeleteChild(child);
    }
    child->parent_.Set(this);

    SetReflow();

    return true;
}


size_t UiContainer::GetIndexOfChild(const UiControl* child)
{
    return std::find(children_.begin(), children_.end(), child) - children_.begin();
}


bool UiContainer::DeleteChild(UiControl* child)
{
    if (child == NULL || children_.empty())
        return false;

    return DeleteChild(GetIndexOfChild(child));
}


bool UiContainer::DeleteChild(size_t childIndex)
{
    if (childIndex >= children_.size())
        return false;

    // Unparent the child.
    UiControlRefPtr& parent = children_[childIndex]->parent_;
    if (parent == this)
        parent.Clear();

    children_.erase(children_.begin() + childIndex);

    SetReflow();

    return true;
}


bool UiContainer::GetChild(const UiControl* child, __out size_t* childIndex)
{
    size_t totalChildren = children_.size();
    *childIndex = totalChildren;

    size_t index = GetIndexOfChild(child);
    *childIndex = index;
    if (index >= totalChildren)
        return false;

    return true;
}


bool UiContainer::GetChild(size_t childIndex, __out UiControlRefPtr& child)
{
    child.Set(NULL);

    if (childIndex >= children_.size())
        return false;

    child.Set( children_[childIndex] );
    return true;
}


// Input related...

bool UiContainer::MouseEnter(MouseMessage& message)
{
    if (SelectMouseFocusChild(message)
    && !mouseFocusChild_->HasMouseFocus())
    {
        SetMouseFocus(mouseFocusChild_, message);
    }
    return true;
}


bool UiContainer::MouseExit(MouseMessage& message)
{
    mouseCaptured_ = false;
    if (mouseFocusChild_ != NULL)
        SetMouseFocus(NULL, message);

    return true;
}


bool UiContainer::MousePress(MouseMessage& message)
{
    return SelectMouseFocusChild(message)
        && RelayMouseMessage(mouseFocusChild_, message, &UiControl::MousePress);
}


bool UiContainer::MouseRelease(MouseMessage& message)
{
    return SelectMouseFocusChild(message)
        && RelayMouseMessage(mouseFocusChild_, message, &UiControl::MouseRelease);
}


bool UiContainer::MouseMove(MouseMessage& message)
{
    return SelectMouseFocusChild(message)
        && RelayMouseMessage(mouseFocusChild_, message, &UiControl::MouseMove);
}


bool UiContainer::MouseScroll(MouseMessage& message)
{
    return SelectMouseFocusChild(message)
        && RelayMouseMessage(mouseFocusChild_, message, &UiControl::MouseScroll);
}


bool UiContainer::RelayMouseMessage(UiControl* child, MouseMessage& message, MouseMessageDelegate mmd)
{
    assert(child != NULL);

    float originalX = message.x;
    float originalY = message.y;
    message.x -= child->position_.x; // adjust relative to child
    message.y -= child->position_.y;
    bool returnValue = (child->*mmd)(message);
    message.x = originalX; // restore original click coordinate
    message.y = originalY;

    return returnValue;
}


bool UiContainer::SelectMouseFocusChild(MouseMessage& message)
{
    UiControl* newChild = NULL;

    // ensure previous control still valid
    if (mouseCaptured_ && mouseFocusChild_->CanGetMouseFocus())
    {
        newChild = mouseFocusChild_;
    }
    else 
    {
        // find the currently hovered one
        size_t totalChildren = children_.size();
        for (size_t childIndex = totalChildren; childIndex > 0; --childIndex)
        {
            UiControl& child = *children_[childIndex - 1];
            if (child.CanGetMouseFocus()
            &&  child.position_.Contains(message.x, message.y))
            {
                newChild = &child;
                break;
            }
        }
    }

    // if different, send exit and enter messages
    if (newChild != mouseFocusChild_)
        SetMouseFocus(newChild, message);

    return mouseFocusChild_ != NULL;
}


void UiContainer::SetMouseFocus(UiControl* newChild, MouseMessage& baseMessage)
{
    // inform previous control of loss ...
    UiControlRefPtr previousChild = mouseFocusChild_;
    mouseFocusChild_.Set(newChild);

    MouseMessage message(baseMessage);

    // Inform old control of loss
    if (previousChild != NULL && previousChild->HasMouseFocus())
    {
        previousChild->ClearStyle(StyleFlagMouseFocus);
        message.message = MouseMessage::MessageExit;
        RelayMouseMessage(previousChild, message, &UiControl::MouseExit);
    }

    // Inform new control of gain
    if (mouseFocusChild_ != NULL && !mouseFocusChild_->HasMouseFocus())
    {
        mouseFocusChild_->SetStyle(StyleFlagMouseFocus);
        message.message = MouseMessage::MessageEnter;
        RelayMouseMessage(mouseFocusChild_, message, &UiControl::MouseEnter);
    }
}


bool UiContainer::SetMouseFocus(UiControl* newChild, MouseMessage& message, bool chainParents)
{
    if (newChild == NULL || newChild->parent_ != this || !newChild->CanGetMouseFocus())
    {
        // The given child cannot receive focus,
        // or the caller is releasing mouse focus,
        // so select an appropriate control based
        // on the mouse message.
        mouseCaptured_ = false;
        SelectMouseFocusChild(message);

        if (HasMouseFocus())
            ReleaseMouseFocus(message);

        // Return success only if null was passed.
        // Otherwise the control tried to take focus when it wasn't allowed to.
        return (newChild == NULL);
    }

    if (newChild != mouseFocusChild_ || !newChild->HasMouseFocus() || !mouseCaptured_)
    {
        // The control can receive focus.
        mouseCaptured_ = true;
        if (!newChild->HasMouseFocus())
            SetMouseFocus(newChild, message);
    }

    // Chain the request up
    if (chainParents && parent_ != NULL)
        return parent_->SetMouseFocus(this, message, true);

    return mouseFocusChild_ == newChild;
}


bool UiContainer::KeyEnter(KeyboardMessage& message)
{
    if (SelectKeyFocusChild(message)
    &&  !keyFocusChild_->HasKeyFocus())
    {
        SetKeyFocus(keyFocusChild_, message);
    }
    return true;
}


bool UiContainer::KeyExit(KeyboardMessage& message)
{
    if (keyFocusChild_ != NULL)
        SetKeyFocus(keyFocusChild_, message);

    return true;
}


bool UiContainer::KeyPress(KeyboardMessage& message)
{
    return SelectKeyFocusChild(message)
        && keyFocusChild_->KeyPress(message);
}


bool UiContainer::KeyRelease(KeyboardMessage& message)
{
    return SelectKeyFocusChild(message)
        && keyFocusChild_->KeyRelease(message);
}


bool UiContainer::KeyCharacter(KeyboardMessage& message)
{
    return SelectKeyFocusChild(message)
        && keyFocusChild_->KeyCharacter(message);
}


bool UiContainer::SetKeyFocus(UiControl* newChild, bool chainParents)
{
    if (newChild == NULL || newChild->parent_ != this || !newChild->CanGetKeyFocus())
    {
        // The given child cannot receive focus, but check
        // whether any child is currently focused now.
        if (keyFocusChild_ == NULL)
        {
            // If not, select the any available one.
            // The keypress code is not applicable, so just zero it
            KeyboardMessage message;
            memset(&message, 0, sizeof(message));
            SelectKeyFocusChild(message);
        }
        return false;
    }

    // only if different than what is already set
    if (newChild != keyFocusChild_ || !newChild->HasKeyFocus())
    {
        // The keypress code is not applicable, so just zero it
        KeyboardMessage message;
        memset(&message, 0, sizeof(message));
        SetKeyFocus(newChild, message);
    }

    // if the main window does not have key focus, chain the request up
    if (chainParents && !HasKeyFocus() && parent_ != NULL)
        return parent_->SetKeyFocus(this, true);

    return keyFocusChild_ == newChild;
}


void UiContainer::SetKeyFocus(UiControl* newChild, __inout KeyboardMessage& baseMessage)
{
    UiControlRefPtr previousChild = keyFocusChild_;
    keyFocusChild_.Set(newChild);

    KeyboardMessage message(baseMessage);

    // inform previous control of loss
    if (previousChild != NULL && previousChild->HasKeyFocus())
    {
        message.message = KeyboardMessage::MessageExit;
        previousChild->ClearStyle(StyleFlagKeyFocus);
        previousChild->KeyExit(message);
    }

    // inform new control of gain (assuming the parent does, *this)
    if (HasKeyFocus() && keyFocusChild_ != NULL && !keyFocusChild_->HasKeyFocus())
    {
        message.message = KeyboardMessage::MessageEnter;
        keyFocusChild_->SetStyle(StyleFlagKeyFocus);
        keyFocusChild_->KeyEnter(message);
    }
}


bool UiContainer::SelectKeyFocusChild(KeyboardMessage& message)
{
    // check whether previous control is still valid
    if (keyFocusChild_ != NULL)
    {
        UiControl& child = *keyFocusChild_;
        if (child.parent_ == this && child.CanGetKeyFocus())
            return true; // already have our focus item
        else
            SetKeyFocus(NULL, message);
    }

    // find another one to get focus
    for (size_t childIndex = 0; childIndex < children_.size(); ++childIndex)
    {
        UiControl* child = children_[childIndex];
        if (child->CanGetKeyFocus())
        {
            SetKeyFocus(child, message);
            break;
        }
    }

    return keyFocusChild_ != NULL;
}


bool UiContainer::SelectNextKeyFocusChild(bool reverse)
{
    size_t totalChildren = children_.size();
    if (totalChildren <= 0)
        return false;

    size_t childIndex = GetIndexOfChild(keyFocusChild_);

    if (childIndex >= totalChildren && !reverse)
        childIndex = totalChildren - 1;

    // find another one to get focus
    for (size_t childCount = 0; childCount < totalChildren; ++childCount)
    {
        if (reverse)
        {
            if (childIndex <= 0) // wrap
                childIndex = totalChildren;
            --childIndex;
        }
        else
        {
            ++childIndex;
            if (childIndex >= totalChildren) // wrap
                childIndex = 0;
        }

        UiControl* child = children_[childIndex];
        if (child->CanGetKeyFocus() && child != keyFocusChild_)
        {
            SetKeyFocus(child, false);
            return true;
        }
    }

    return false;
}


bool UiContainer::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    switch (positionQuery)
    {
    case PositionQueryPreferred:
        ClearStyleDirectly(StyleFlagReflow);
        *position = preferredPosition_;
        return true;

    default:
        return Base::GetPosition(positionQuery, position);
    }
}


Position UiContainer::ReflowChildrenSequential(
    std::vector<UiControlRefPtr>& children,
    const Position& clientRect,
    float spacing,
    StyleFlag styleFlags,
    ReflowOptions reflowOptions
    )
{
    size_t childrenTotal = children.size();

    std::vector<Position> childPositions(childrenTotal);

    // Arrange all the children, flowing left-to-right for horizontal,
    // top-to-bottom for vertical (flipping at the end if RTL). Note
    // that all the coordinates are rotated 90 degrees when vertical
    // (so x is really y).

    unsigned int col = 0, row = 0;

    bool isVertical = (styleFlags & StyleFlagVertical)   != 0;
    bool isRtl      = (styleFlags & StyleFlagReadingRtl) != 0;
    bool isWrapped  = (styleFlags & StyleFlagUnwrapped)  == 0;

    float x = 0, y = 0;
    float w = 0, h = 0;
    float maxWidth = (isVertical) ? clientRect.h : clientRect.w;

    for (size_t childIndex = 0; childIndex < childrenTotal; ++childIndex)
    {
        UiControl& child = *children[childIndex];

        // Get preferred size from control, skipping if non-influential.
        if (child.IsHidden()
        ||  (child.IsFloating() && !(reflowOptions & ReflowOptionMoveFloating)))
        {
            // Child should not be moved (or is hidden and makes no difference),
            // so just keep same position.
            childPositions[childIndex] = child.position_;
            continue;
        }

        Position childRect = clientRect;
        child.GetPosition(PositionQueryPreferred, &childRect);

        // If the child has a rigid size, then keep what is already set.
        if (child.HasRigidWidth())
            childRect.w = child.position_.w;

        if (child.HasRigidHeight())
            childRect.h = child.position_.h;

        // Note size and coordinates are interpreted 90 degrees if vertical.
        float childWidth  = childRect.w;
        float childHeight = childRect.h;
        if (isVertical)
            std::swap(childWidth, childHeight);

        // Flow down to a new line if wider than maximum (and not the
        // first column), or if child hints that it should be on a new line.
        if (col > 0)
        {
            if ((isWrapped && x + childWidth > maxWidth)
            || child.WantsNewLine())
            {
                row++;
                col = 0;
                x = 0;
                y = h + spacing;
            }
        }

        // Accumulate the total size
        h = std::max(h, y + childHeight);
        w = std::max(w, x + childWidth);

        // Store new position of child
        childRect.x = x;
        childRect.y = y;
        if (isVertical)
            std::swap(childRect.x, childRect.y);

        childPositions[childIndex] = childRect;

        // Advance by child size, adding spacing for nonzero width controls.
        col++;
        x += childWidth;
        if (childWidth > 0)
            x += spacing;
    }

    if (isVertical)
        std::swap(h, w);

    // Store the computed bounding rectangle,
    // and return it if that was all that was wanted.

    Position resultRect = {0,0,w,h};
    if (reflowOptions & ReflowOptionQueryOnly)
        return resultRect;

    if (isRtl)
    {
        for (size_t childIndex = 0; childIndex < childrenTotal; ++childIndex)
        {
            // Calculate child rect.
            Position& childRect = childPositions[childIndex];
            childRect.x = clientRect.w - childRect.x - childRect.w;
        }
    }

    // Actually update children with the new positions...

    for (size_t childIndex = 0; childIndex < childrenTotal; ++childIndex)
    {
        // Calculate child rect.

        UiControl& child = *children[childIndex];
        if (child.IsHidden() || (child.IsFloating() && !(reflowOptions & ReflowOptionMoveFloating)))
            continue;

        Position& newPosition = childPositions[childIndex];
            
        newPosition.x += clientRect.x;
        newPosition.y += clientRect.y;

        if (child.styleFlags_ & StyleFlagTall)
            newPosition.h = clientRect.h;

        if (child.styleFlags_ & StyleFlagWide)
            newPosition.w = clientRect.w;

        if (newPosition != child.position_)
            child.SetPosition(newPosition);

        child.ClearStyleDirectly(StyleFlagReflow);
    }

    return resultRect;
}
