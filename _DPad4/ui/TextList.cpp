//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Scrollable list of text items.
//
//----------------------------------------------------------------------------
#include "precomp.h"


TextList::TextList(UiControl* parent, int id, Base::Behavior behavior)
{
    Init();
    id_ = id;
    behavior_ = behavior;

    itemHeight_ = DetermineItemHeight();

    if (!Create(parent))
        throw std::exception("Could not create TextList" FAILURE_LOCATION);
}


bool TextList::Draw(RenderTarget& target, const Position& rect)
{
    Base::Draw(target, rect);

    target.PushClipRect(rect);

    IDWriteTextFormat* textFormat = Base::gTheme_->GetTextFormat(ThemePartIdListControl);
    const Position itemMargin     = Base::gTheme_->GetImagePart(ThemePartIdListControlMargin);

    size_t totalItems = items_.size();
    for (size_t item = static_cast<size_t>(scrollPosition_.y / itemHeight_); item < totalItems; ++item)
    {
        Position itemPosition;
        if (GetPositionFromItem(item, &itemPosition))
        {
            // Adjust absolute position to scroll relative one.
            itemPosition.x -= scrollPosition_.x;
            itemPosition.y -= scrollPosition_.y;

            // End if bottom item was drawn.
            if (itemPosition.y >= position_.h)
                break;

            // Adjust list relative to display relative
            itemPosition.x += rect.x;
            itemPosition.y += rect.y;

            if (item == selectedItem_)
            {
                target.DrawNineGridImage(
                    Base::gTheme_->GetImage(),
                    Base::gTheme_->GetImageParts(HasKeyFocus() ? ThemePartIdListControlSelection : ThemePartIdListControlSelectionDim),
                    itemPosition
                    );
            }

            // Add margin before drawing text, so text is not immediately adjacent to edge.
            itemPosition.x += itemMargin.l;
            itemPosition.y += itemMargin.t;
            itemPosition.w -= itemMargin.l + itemMargin.r;
            itemPosition.h -= itemMargin.t + itemMargin.b;

            const std::wstring& itemText = items_[item].text;
            target.DrawText(itemText.c_str(), itemText.size(), textFormat, NULL, itemPosition);
        }
    }

    target.PopClipRect();

    return true;
}


bool TextList::KeyPress(KeyboardMessage& message)
{
    switch (message.button)
    {
    case VK_PRIOR:
        SetSelection(SelectionSetModeUp, static_cast<size_t>(position_.h / itemHeight_));
        break;

    case VK_NEXT:
        SetSelection(SelectionSetModeDown, static_cast<size_t>(position_.h / itemHeight_));
        break;

    default:
        return Base::KeyPress(message);
    }

    return true;
}


size_t TextList::GetItemCount()
{
    return items_.size();
}


const wchar_t* TextList::GetItemText(size_t item)
{
    if (item >= items_.size())
        return L"";

    return items_[item].text.c_str();
}


void* TextList::GetItemData(size_t item)
{
    if (item >= items_.size())
        return NULL;

    return items_[item].data;
}


bool TextList::GetPositionFromItem(size_t item, __out Position* itemPosition)
{
    // Returns the position of an item (relative to <0,0>, not scroll adjusted)
    if (item >= items_.size())
        return false;

    *itemPosition = MakePosition(0, item * itemHeight_, position_.w, itemHeight_);
    return true;
}


bool TextList::GetItemFromPosition(float x, float y, __out size_t* item)
{
    if (y < 0)
    {
        // Return the first item, but indicate it's out of bounds.
        *item = 0;
        return false;
    }

    size_t hoveredItem = static_cast<size_t>(y / itemHeight_);
    size_t totalItems = items_.size();
    if (hoveredItem >= totalItems)
    {
        // Return last item, but indicate it's out of bounds.
        *item = std::min(totalItems - 1, totalItems);
        return false;
    }

    *item = hoveredItem;

    // Returned the hovered item, but note that hit-test was outside of position.
    if (x < 0 || x >= position_.w)
        return false;

    return true;
}


float TextList::DetermineItemHeight()
{
    // Create an empty layout to get the default height of a line.

    // An alternate approach would be to get the system font collection,
    // find the matching font family specified in the text format, retrieve
    // the best match given font style attributes, and then get the font
    // metrics. Then you could use the ascent + descent to determine line
    // height. However, this is more complicated, and more importantly,
    // does not consider font fallback nor does it round line height to
    // the nearest size when using compatible metrics.

    ComPtr<IDWriteTextLayout> layout;
    Base::gTheme_->CreateTextLayout(
        Base::gDWriteFactory_,
        L"",
        ThemePartIdListControl,
        MakePosition(0,0,1000,1000),
        layout
        );

    DWRITE_TEXT_METRICS textMetrics;
    HRESULT hr = layout->GetMetrics(&textMetrics);
    if (FAILED(hr))
        throw OsException("Could not determine the line height for a text list!" FAILURE_LOCATION, hr);

    // Add margin around items.
    Position itemMargin = {0,0, ceil(textMetrics.width), ceil(textMetrics.height)};
    itemMargin = Base::gTheme_->GetInflatedImagePart(itemMargin, ThemePartIdListControlMargin);

    return itemMargin.h;
}


bool TextList::AddItem(const wchar_t* text, void* itemData)
{
    items_.push_back(Item(text, itemData));
    scrollPosition_.h = itemHeight_ * items_.size();
    return true;
}


bool TextList::ClearItems()
{
    items_.clear();
    return true;
}


bool TextList::SortItems()
{
    std::sort(items_.begin(), items_.end());
    return true;
}
