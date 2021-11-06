// <SnippetFlowSourcecpp>
// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// Copyright (c) Microsoft Corporation. All rights reserved
//
// Contents:    Tells a flow layout where text is allowed to flow.
//
//----------------------------------------------------------------------------
#include "common.h"
#include "TextAnalysis.h"
#include "FlowSource.h"


STDMETHODIMP FlowLayoutSource::Reset()
{
    currentV_ = 0;
    currentU_ = 0;
    return S_OK;
}


STDMETHODIMP FlowLayoutSource::SetSize(
    float width,
    float height
    )                     
{
    width_  = width;
    height_ = height;
    return S_OK;
}


STDMETHODIMP FlowLayoutSource::SetShape(FlowShape flowShape)
{
    flowShape_ = flowShape;
    return Reset();
}


STDMETHODIMP FlowLayoutSource::GetNextRect(
    float fontHeight,
    ReadingDirection readingDirection,
    OUT RectF* nextRect
    )
{
    RectF& rect = *nextRect;

    // Set defaults.
    RectF zeroRect = {};
    rect = zeroRect;

    if (height_ <= 0 || width_ <= 0)
    {
        return S_OK; // Do nothing if empty.
    }

    bool const isVertical           = (readingDirection & ReadingDirectionPrimaryAxis) != 0;
    bool const isReversedPrimary    = (readingDirection & ReadingDirectionPrimaryProgression) != 0;
    bool const isReversedSecondary  = (readingDirection & ReadingDirectionSecondaryProgression) != 0;

    float const uSize     = isVertical ? height_ : width_;
    float const vSize     = isVertical ? width_  : height_;
    float const uSizeHalf = uSize / 2;
    float const vSizeHalf = vSize / 2;

    if (currentV_ >= vSize)
    {
        return S_OK; // Crop any further lines.
    }

    // Initially set to entire size.
    rect.left   = 0;
    rect.top    = 0;
    rect.right  = uSize;
    rect.bottom = vSize;

    // Advance to the next row/column.
    float u = currentU_;
    float v = currentV_;

    switch (flowShape_)
    {
    case FlowShapeFunnel:
    case FlowShapeCircle:
    case FlowShapeRectangle:
    default:
        currentV_ += fontHeight;
        break;
    case FlowShapeGrid:
        currentU_ += fontHeight;
        if (currentU_ >= uSize)
        {
            currentV_ += fontHeight;
            currentU_ = 0;
            v = currentV_;
            u = currentU_;
            currentU_ += fontHeight;
        }
        break;
    }

    // Simple, hard-coded shape formulas.
    // You can add more shapes by adding a new enum in the header and extending
    // the switch statement.

    switch (flowShape_)
    {
    case FlowShapeFunnel:
        {
            float uShift = float(sin(v / vSize * M_PI * 3)) * 30;

            // Calculate slope to determine edges.
            rect.top    = v;
            rect.bottom = v + fontHeight;
            rect.left   = uShift + (v / vSize) * uSize / 2;
            rect.right  = uSize - rect.left;
        }
        break;

    case FlowShapeCircle:
        {
            float minSizeHalf = std::min(uSizeHalf, vSizeHalf);
            float adjustedV = (v + fontHeight/2) - vSizeHalf;

            // Determine x from y using circle formula d^2 = (x^2 + y^2).
            float d2    = (minSizeHalf * minSizeHalf) - (adjustedV * adjustedV);
            float u     = (d2 > 0) ? sqrt(d2) : -1;
            rect.top    = v;
            rect.bottom = v + fontHeight;
            rect.left   = uSizeHalf - u;
            rect.right  = uSizeHalf + u;
        }
        break;

    case FlowShapeRectangle:
        rect.top    = v;
        rect.bottom = v + fontHeight;
        // rect.left   = 0;
        // rect.right  = width_;
        break;

    case FlowShapeGrid:
        rect.top    = v;
        rect.bottom = v + fontHeight;
        rect.left   = u;
        rect.right  = u;
        break;
    }

    // Reorient rect according to reading direction.
    if (isReversedPrimary)
    {
        std::swap(rect.left, rect.right);
        rect.left  = uSize - rect.left;
        rect.right = uSize - rect.right;
    }
    if (isReversedSecondary)
    {
        std::swap(rect.top, rect.bottom);
        rect.top    = vSize - rect.top;
        rect.bottom = vSize - rect.bottom;
    }
    if (isVertical)
    {
        std::swap(rect.left,  rect.top);
        std::swap(rect.right, rect.bottom);
    }

    return S_OK;
}
// </SnippetFlowSourcecpp>
