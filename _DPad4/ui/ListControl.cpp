//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Scrollable list of items.
//
//----------------------------------------------------------------------------
#include "precomp.h"


ListControl::ListControl(UiControl* parent, int id, Behavior behavior)
{
    Init();
    id_ = id;
    behavior_ = behavior;

    if (!Create(parent))
        throw std::exception("Could not create ListControl" FAILURE_LOCATION);
}


bool ListControl::Destroy()
{
    // Explicitly clear owner to remove references sooner.
    // Otherwise we would hold onto them until the destructor
    // was called.
    owner_.Clear();
    return Base::Destroy();
}


bool ListControl::Draw(RenderTarget& target, const Position& rect)
{
    target.DrawNineGridImage(
        Base::gTheme_->GetImage(),
        Base::gTheme_->GetImageParts(ThemePartIdListControl),
        rect
        );

    // Item drawing is done by the derived class.

    return true;
}


// Input related...

bool ListControl::MouseEnter(MouseMessage& message)
{
    return true;
}


bool ListControl::MouseExit(MouseMessage& message)
{
    currentlySelecting_ = false;
    return true;
}


bool ListControl::MousePress(MouseMessage& message)
{
    SetKeyFocus();

    if (message.button == MouseMessage::ButtonLeft)
    {
        SetMouseFocus(message);
        currentlySelecting_ = true;

        size_t item;
        if (GetItemFromPosition(message.x + scrollPosition_.x, message.y + scrollPosition_.y, &item))
        {
            SetSelection(SelectionSetModeAbsolute, item);
            if (owner_.IsSet())
            {
                if (IsActiveOnPress() || (IsActiveOnDoubleClick() && message.repeatCount > 1))
                    owner_.callback->Activated(this, id_, selectedItem_);
            }
        }
    }
    return true;
}


bool ListControl::MouseRelease(MouseMessage& message)
{
    bool wasSelecting = currentlySelecting_;
    currentlySelecting_ = false;

    if (wasSelecting)
    {
        // Ensure that the release was actually over the choice,
        // instead of outside.
        size_t item;
        if (IsActiveOnRelease() && GetItemFromPosition(message.x + scrollPosition_.x, message.y + scrollPosition_.y, &item))
        {
            if (owner_.IsSet())
                owner_.callback->Activated(this, id_, selectedItem_);
        }
    }
    ReleaseMouseFocus(message);
    return true;
}


bool ListControl::MouseMove(MouseMessage& message)
{
    if (currentlySelecting_)
    {
        size_t item;
        GetItemFromPosition(message.x + scrollPosition_.x, message.y + scrollPosition_.y, &item);
        SetSelection(SelectionSetModeAbsolute, item);
    }

    return true;
}


bool ListControl::MouseScroll(MouseMessage& message)
{
    scrollPosition_.x -= message.xDif * 20;
    scrollPosition_.y -= message.yDif * 20;

    // Don't scroll past right or bottom edge
    if (scrollPosition_.x + position_.w > scrollPosition_.w)
        scrollPosition_.x = scrollPosition_.w - position_.w;

    if (scrollPosition_.y + position_.h > scrollPosition_.h)
        scrollPosition_.y = scrollPosition_.h - position_.h;

    // Don't scroll past left or top edge
    if (scrollPosition_.x < 0)
        scrollPosition_.x = 0;

    if (scrollPosition_.y < 0)
        scrollPosition_.y = 0;

    SetRedraw();
    return true;
}


bool ListControl::KeyEnter(KeyboardMessage& message)
{
    SetRedraw();
    return true;
}


bool ListControl::KeyExit(KeyboardMessage& message)
{
    SetRedraw();
    return true;
}


bool ListControl::KeyPress(KeyboardMessage& message)
{
    switch (message.button)
    {
    case VK_RETURN:
        if (owner_.IsSet())
            owner_.callback->Activated(this, id_, selectedItem_);
        break;

    case VK_UP:
        SetSelection(SelectionSetModeUp, 1);
        break;

    case VK_DOWN:
        SetSelection(SelectionSetModeDown, 1);
        break;

    case VK_HOME:
        SetSelection(SelectionSetModeFirst, 0);
        break;

    case VK_END:
        SetSelection(SelectionSetModeLast, 0);
        break;

    default:
        return false;
    }

    return true;
}


void ListControl::SetOwner(RefCountBase* target, Owner* owner)
{
    owner_.Set(target, owner);
}


bool ListControl::GetOwner(__deref_opt_out RefCountBase** target, __deref_opt_out Owner** owner)
{
    return owner_.Get(target, owner);
}


bool ListControl::SetSelection(SelectionSetMode moveMode, size_t advance)
{
    // Moves the caret relatively or absolutely, optionally extending the
    // selection range (for example, when shift is held).

    size_t oldSelectedItem = selectedItem_;
    size_t totalItems = GetItemCount();

    switch (moveMode)
    {
    case SelectionSetModeUp:
        selectedItem_ -= advance;
        if (selectedItem_ > totalItems)
            selectedItem_ = 0;
        break;

    case SelectionSetModeDown:
        selectedItem_ += advance;
        if (selectedItem_ < advance)
            selectedItem_ = totalItems - 1;
        break;

    case SelectionSetModeFirst:
        selectedItem_ = 0;
        break;

    case SelectionSetModeLast:
        selectedItem_ = totalItems - 1;
        break;

    case SelectionSetModeAbsolute:
        selectedItem_ = advance;
        break;
    }

    if (selectedItem_ >= totalItems)
        selectedItem_ = std::min(totalItems - 1, totalItems);

    EnsureItemIsVisible(selectedItem_);

    if (selectedItem_ != oldSelectedItem)
    {
        SetRedraw();
        if (owner_.IsSet())
            owner_.callback->SelectionChanged(this, id_, selectedItem_);
    }

    return selectedItem_ != oldSelectedItem;
}


bool ListControl::EnsureItemIsVisible(size_t item)
{
    Position itemPosition;
    if (!GetPositionFromItem(item, &itemPosition))
        return false;

    float newScrollX = scrollPosition_.x;
    float newScrollY = scrollPosition_.y;

    float itemRightEdge = itemPosition.x + itemPosition.w;
    if (itemRightEdge > newScrollX + position_.w)
        newScrollX = itemRightEdge - position_.w;

    if (itemPosition.x < newScrollX)
        newScrollX = itemPosition.x;

    float itemBottomEdge = itemPosition.y + itemPosition.h;
    if (itemBottomEdge > newScrollY + position_.h)
        newScrollY = itemBottomEdge - position_.h;

    if (itemPosition.y < newScrollY)
        newScrollY = itemPosition.y;

    if (newScrollX != scrollPosition_.x || newScrollY != scrollPosition_.y)
    {
        SetRedraw();
        scrollPosition_.x = newScrollX;
        scrollPosition_.y = newScrollY;

        if (owner_.IsSet())
            owner_.callback->Scrolled(this, id_);
    }
    return true;
}


size_t ListControl::GetItemCount()
{
    return 0;
}


void* ListControl::GetItemData(size_t item)
{
    return NULL;
}


bool ListControl::GetPositionFromItem(size_t item, __out Position* itemPosition)
{
    // Returns the position of an item (relative to <0,0>, not scroll adjusted)
    const static Position empty = {0};
    *itemPosition = empty;
    return false;
}


bool ListControl::GetItemFromPosition(float x, float y, __out size_t* item)
{
    *item = 0;
    return false;
}


bool ListControl::GetScrollPosition(__out Position* position)
{
    *position = scrollPosition_;
    return true;
}


bool ListControl::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    switch (positionQuery)
    {
    case PositionQueryPreferred:
        // The scroll area size is the preferred size. If either height or width
        // is zero, just return the current size (instead of an empty rect).
        *position = MakePosition(
                        0,
                        0,
                        std::min((scrollPosition_.w > 0) ? scrollPosition_.w : position_.w, position->w),
                        std::min((scrollPosition_.h > 0) ? scrollPosition_.h : position_.h, position->h)
                        );
        return true;

    default:
        return Base::GetPosition(positionQuery, position);
    }
}
