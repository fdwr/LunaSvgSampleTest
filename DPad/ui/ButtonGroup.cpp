//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   User interface button.
//
//----------------------------------------------------------------------------
#include "precomp.h"


ButtonGroup::ButtonGroup(UiControl* parent)
{
    Init();
    if (!Create(parent))
        throw std::exception("Could not create ButtonGroup" FAILURE_LOCATION);
}


ButtonGroup::ButtonGroup(UiControl* parent, int id, bool hasBorder)
{
    Init();
    id_ = id;
    hasBorder_ = hasBorder;

    if (!Create(parent))
        throw std::exception("Could not create ButtonGroup" FAILURE_LOCATION);
}


bool ButtonGroup::Draw(RenderTarget& target, const Position& rect)
{
    if (hasBorder_)
    {
        target.DrawNineGridImage(
            Base::gTheme_->GetImage(),
            Base::gTheme_->GetImageParts(ThemePartIdButtonGroup),
            rect
            );
    }
    return true;
}


bool ButtonGroup::InsertChild(UiControl* child)
{
    // If inserting a button, then make the group the owner
    // for any switches.
    Button* button = dynamic_cast<Button*>(child);
    if (button != NULL && button->IsSwitch())
    {
        button->SetOwner(this, this);
    }

    // Technically we are inserting a member of the group, not a child,
    // since the child actually lives in the parent.
    // Button groups do not 'own' their members; they are just in charge
    // of clustering them beside each other during reflow.
    if (parent_ != NULL)
    {
        // Force child's flags to be floating, since the group handles
        // all positioning, not the parent.
        child->SetStyle(StyleFlagFloating);
        if (parent_->InsertChild(child))
        {
            members_.insert(members_.end(), UiControlRefPtr(child));
            return true;
        }
    }
    return false;
}


bool ButtonGroup::InsertChild(UiControl* child, size_t childIndex)
{
    // Ignore index
    return InsertChild(child);
}


bool ButtonGroup::DeleteChild(UiControl* child)
{
    // Delete the given member from both the group and the containing parent.
    // You shouldn't delete the control directly from the parent, because
    // then the control will still be a part of the group but will be invisible.

    size_t memberIndex = std::find(members_.begin(), members_.end(), child) - members_.begin();
    if (memberIndex >= members_.size())
        return false;

    members_.erase(members_.begin() + memberIndex);
    if (parent_ != NULL)
        parent_->DeleteChild(child);

    return true;
}


bool ButtonGroup::GetPosition(PositionQuery positionQuery, __inout Position* position)
{
    switch (positionQuery)
    {
    case PositionQueryPreferred:
        if (NeedsReflow())
        {
            Position clientRect = {0,0,FLT_MAX,FLT_MAX}; // allow unlimited size
            preferredPosition_ =
                UiContainer::ReflowChildrenSequential(
                    members_,
                    clientRect,
                    0,
                    styleFlags_,
                    UiContainer::ReflowOptionQueryOnly|UiContainer::ReflowOptionMoveFloating
                    );
            if (hasBorder_)
                preferredPosition_ = Base::gTheme_->GetInflatedImagePart(preferredPosition_, ThemePartIdButtonGroupPadding);
            ClearStyleDirectly(StyleFlagReflow);
        }
        *position = preferredPosition_;
        return true;

    default:
        return Base::GetPosition(positionQuery, position);
    }
}


bool ButtonGroup::SetPosition(const Position& position)
{
    if (position.SizeDiffers(position_))
    {
        // Reposition all members

        Position clientRect = position;
        if (hasBorder_)
            clientRect = Base::gTheme_->GetDeflatedImagePart(clientRect, ThemePartIdButtonGroupPadding);
        UiContainer::ReflowChildrenSequential(members_, clientRect, 0, styleFlags_, UiContainer::ReflowOptionMoveFloating);
    }

    return Base::SetPosition(position);
}


void ButtonGroup::SetOwner(
    RefCountBase* target,
    Owner* owner
    )
{
    owner_.Set(target, owner);
}


bool ButtonGroup::GetOwner(__deref_opt_out RefCountBase** target, __deref_opt_out Owner** owner)
{
    return owner_.Get(target, owner);
}


bool ButtonGroup::Activated(Button* source, int id, int value)
{
    // A button was clicked in the group, so if it was a switch,
    // then deactivate any others.

    SetActiveMember(source);

    // Forward event to the group's owner, so it can listen to the events.
    if (owner_.IsSet())
    {
        return owner_.callback->Activated(source, id, value);
    }
    return false;
}


bool ButtonGroup::SetActiveMember(int id)
{
    // A button was clicked in the group, so if it was a switch,
    // then deactivate any others.

    size_t memberIndex = 0;
    size_t membersTotal = members_.size();
    UiControl* member = members_[memberIndex];

    for ( ; memberIndex < membersTotal; ++memberIndex)
    {
        member = members_[memberIndex];
        if (member->id_ == id)
            break;
    }
    if (memberIndex >= membersTotal)
        return false;

    return SetActiveMember(member);
}


bool ButtonGroup::SetActiveMember(UiControl* newActiveMember)
{
    size_t membersTotal = members_.size();

    for (size_t memberIndex = 0; memberIndex < membersTotal; ++memberIndex)
    {
        UiControl* member = members_[memberIndex];

        // Don't deactive the one that triggered the message.
        if (member == newActiveMember)
        {
            // Set the given one active (if not already)
            if (!member->IsActive())
                member->SetStyle(StyleFlagActive);
        }
        else if (member->IsActive())
        {
            // But clear any other buttons
            Button* button = dynamic_cast<Button*>(member);
            if (button != NULL && button->IsSwitch())
                button->ClearStyle(StyleFlagActive);
        }
    }

    return true;
}
