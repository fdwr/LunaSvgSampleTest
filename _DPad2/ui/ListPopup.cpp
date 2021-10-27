//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Popup holder for a list of items.
//
//----------------------------------------------------------------------------
#include "precomp.h"


ListPopup::ListPopup(UiControl* parent, int id)
{
    Init();
    id_ = id;

    // Hidden by default, until shown.
    SetStyleDirectly(StyleFlagHidden|StyleFlagFloating);

    if (!Create(parent))
        throw std::exception("Could not create ListPopup" FAILURE_LOCATION);
}


bool ListPopup::Destroy()
{
    // Explicitly clear owner to remove references sooner.
    // Otherwise we would hold onto them until the destructor
    // was called.
    owner_.Clear();
    return Base::Destroy();
}


bool ListPopup::KeyPress(KeyboardMessage& message)
{
    bool messageAcknowledged = Base::KeyPress(message);
    if (messageAcknowledged)
        return messageAcknowledged;

    switch (message.button)
    {
    case VK_ESCAPE:
        CancelActivate();
        return true;
    }
    return messageAcknowledged;
}


bool ListPopup::KeyExit(KeyboardMessage& message)
{
    CancelActivate();
    return Base::KeyExit(message);
}


bool ListPopup::InsertChild(UiControl* child)
{
    return Base::InsertChild(child);
}


bool ListPopup::InsertChild(UiControl* child, size_t childIndex)
{
    // If inserting a list, then make the popup the owner.
    ListControl* list = dynamic_cast<ListControl*>(child);
    if (list != NULL)
    {
        list->SetOwner(this, this);
    }

    return Base::InsertChild(child, childIndex);
}


void ListPopup::ShowOnClick(Button* anchor)
{
    if (anchor != NULL)
        anchor->SetOwner(this, this);
}


void ListPopup::SetOwner(RefCountBase* target, Owner* owner)
{
    owner_.Set(target, owner);
}


bool ListPopup::GetOwner(__deref_opt_out RefCountBase** target, __deref_opt_out Owner** owner)
{
    return owner_.Get(target, owner);
}


void ListPopup::Show(__maybenull UiControl* anchor)
{
    Position anchorPosition = {0,0,0,0};
    if (anchor != NULL)
        anchor->GetPosition(PositionQueryAbsolute, &anchorPosition);

    if (parent_ != NULL)
        parent_->InsertChild(this);

    Show(anchorPosition);
}


void ListPopup::Show(Position& anchorPosition)
{
    Position popupPosition  = {0};
    Position parentPosition = {0,0,FLT_MAX,FLT_MAX};

    // Let owner do whatever it needs to do to fill in the list,
    // in case things have changed since the last time it was shown.
    if (owner_.IsSet())
        owner_.callback->Showing(this, id_);

    Base::GetPosition(PositionQueryPreferred, &popupPosition);

    if (parent_ != NULL)
        parentPosition = parent_->position_;

    // Determine the best placement relative to the anchor.

    Position padding = Base::gTheme_->GetDeflatedImagePart(popupPosition, ThemePartIdWindowPadding);

    // Restrict the popup size to the parent.
    popupPosition.w = std::min(popupPosition.w, parentPosition.w);
    popupPosition.h = std::min(popupPosition.h, parentPosition.h);

    // If the popup is thin enough, just center it.
    // Otherwise, align left/right according to reading direction.
    if (padding.w < anchorPosition.w * 3)
    {
        popupPosition.x = anchorPosition.x + floor((anchorPosition.w - popupPosition.w) / 2);
    }
    else
    {
        popupPosition.x = IsReadingRtl()
                        ? (anchorPosition.x + anchorPosition.w - popupPosition.w)
                        : anchorPosition.x;
    }

    // If the popup will fit below, put it there.
    // Otherwise put it above the anchor.
    popupPosition.y = anchorPosition.y + anchorPosition.h;
    if (popupPosition.y + popupPosition.h > parentPosition.h && anchorPosition.y >= popupPosition.h)
    {
        popupPosition.y = anchorPosition.y - popupPosition.h;
    }

    // Don't let the popup go off the screen horizontally.
    if (popupPosition.x + popupPosition.w > parentPosition.w)
        popupPosition.x = parentPosition.w - popupPosition.w;

    if (popupPosition.x < 0)
        popupPosition.x = 0;

    // Don't let the popup go off the screen vertically.
    if (popupPosition.y + popupPosition.h > parentPosition.h)
        popupPosition.y = parentPosition.h - popupPosition.h;

    if (popupPosition.y < 0)
        popupPosition.y = 0;

    ClearStyle(StyleFlagHidden);
    SetRedraw();

    Base::SetPosition(popupPosition);

    // In case the owner needs to do something after the positioning
    // is all settled.
    if (owner_.IsSet())
        owner_.callback->Shown(this, id_);

    UiControl::SetKeyFocus();
}


bool ListPopup::SelectionChanged(ListControl* source, int id, size_t selectedItem)
{
    return false;
}


bool ListPopup::Activated(ListControl* source, int id, size_t selectedItem)
{
    SetStyle(StyleFlagHidden);
    SetRedraw();

    // Forward activation onto the popup's owner.
    if (owner_.IsSet())
        return owner_.callback->Activated(this, id_, selectedItem);

    return false;
}


bool ListPopup::Scrolled(ListControl* source, int id)
{
    return false;
}


bool ListPopup::Activated(Button* source, int id, int value)
{
    Show(source);
    return true;
}


void ListPopup::CancelActivate()
{
    SetStyle(StyleFlagHidden);
    SetRedraw();

    if (owner_.IsSet())
        owner_.callback->Canceled(this, id_);
}
