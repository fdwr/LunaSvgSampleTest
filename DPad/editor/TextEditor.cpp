//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   UI formatted text editor.
//
//----------------------------------------------------------------------------
#include "precomp.h"


TextEditor::TextEditor(UiControl* parent, int id, __notnull IDWriteTextEditLayout* textLayout)
{
    Init();
    id_ = id;
    textLayout->SetMaxWidth(contentWidth_);
    textLayout->SetMaxHeight(contentHeight_);
    textLayout_.Set(textLayout);
    UpdateCaretFormatting();

    if (!Create(parent))
        throw std::exception("Could not create TextEditor" FAILURE_LOCATION);
}


bool TextEditor::Destroy()
{
    // Explicitly clear owner to remove references sooner.
    // Otherwise we would hold onto them until the destructor
    // was called.
    owner_.Clear();
    return Base::Destroy();
}


bool TextEditor::Draw(RenderTarget& target, const Position& rect)
{
    struct Helpers
    {
        static inline D2D1::Matrix3x2F& Cast(DWRITE_MATRIX& matrix)
        {
            return *reinterpret_cast<D2D1::Matrix3x2F*>(&matrix);
        }

        static inline DWRITE_MATRIX& Cast(D2D1::Matrix3x2F& matrix)
        {
            return *reinterpret_cast<DWRITE_MATRIX*>(&matrix);
        }
    };

    target.DrawNineGridImage(
        Base::gTheme_->GetImage(),
        Base::gTheme_->GetImageParts(ThemePartIdTextEditorBackground),
        rect
        );

    Position textRect = rect;

    // Calculate actual location in render target based on the
    // current page transform and location of edit control.
    DWRITE_MATRIX pageTransform;
    GetViewMatrix(&pageTransform);
    DWRITE_MATRIX translationTransform = {1,0,0,1,textRect.x,textRect.y};

    D2D1::Matrix3x2F editorTransform;
    editorTransform.SetProduct(Helpers::Cast(pageTransform), Helpers::Cast(translationTransform));

    // Need the layout metrics to know how large the page will be.
    DWRITE_TEXT_METRICS textMetrics;
    textLayout_->GetMetrics(&textMetrics);
    Position pageRect = {
        0,
        0,
        ceil(std::max(textMetrics.left + textMetrics.width,  contentWidth_)),
        ceil(std::max(textMetrics.top  + textMetrics.height, contentHeight_))
        };

    // Manually transform the page rather than using the current transform.
    // Otherwise the nine-grid can show gaps between the edges because of
    // bilinear interpolation of per-primitive anti-aliasing.

    Position marginRect = Base::gTheme_->GetInflatedImagePart(pageRect, ThemePartIdTextEditorMargin);
    D2D1_POINT_2F marginTopLeft     = editorTransform.TransformPoint(D2D1::Point2F(marginRect.l, marginRect.t));
    D2D1_POINT_2F marginBottomRight = editorTransform.TransformPoint(D2D1::Point2F(marginRect.l + marginRect.w, marginRect.t + marginRect.h));

    // Reorder the coordinates if the transform would invert either axis
    // (rotation and mirroring can cause this).
    if (marginTopLeft.x > marginBottomRight.x)
        std::swap(marginTopLeft.x, marginBottomRight.x);
    if (marginTopLeft.y > marginBottomRight.y)
        std::swap(marginTopLeft.y, marginBottomRight.y);

    marginRect.l = floor(marginTopLeft.x);
    marginRect.t = floor(marginTopLeft.y);
    marginRect.w = floor(marginBottomRight.x - marginTopLeft.x);
    marginRect.h = floor(marginBottomRight.y - marginTopLeft.y);

    // Clip text and selection to page
    target.PushClipRect(rect);

    // Draw page
    target.DrawNineGridImage(
        Base::gTheme_->GetImage(),
        Base::gTheme_->GetImageParts(ThemePartIdTextEditor),
        marginRect
        );

    // Scale/Rotate canvas as needed
    DWRITE_MATRIX previousTransform;
    target.GetTransform(previousTransform);
    target.SetTransform(Helpers::Cast(editorTransform));

    DWRITE_TEXT_RANGE caretRange = GetSelectionRange();

    // Determine actual number of hit-test ranges
    UINT32 actualHitTestCount = 0;
    if (caretRange.length > 0)
    {
        textLayout_->HitTestTextRange(
            caretRange.startPosition,
            caretRange.length,
            0, // x
            0, // y
            NULL,
            0, // metrics count
            &actualHitTestCount
            );
    }

    // Allocate enough room to return them all.
    std::vector<DWRITE_HIT_TEST_METRICS> hitTestMetrics(actualHitTestCount);

    if (caretRange.length > 0)
    {
        textLayout_->HitTestTextRange(
            caretRange.startPosition,
            caretRange.length,
            0, // x
            0, // y
            &hitTestMetrics[0],
            static_cast<UINT32>(hitTestMetrics.size()),
            &actualHitTestCount
            );
    }

    // Get caret position.
    DWRITE_HIT_TEST_METRICS caretMetrics;
    float caretX, caretY;
    textLayout_->HitTestTextPosition(
        caretPosition_,
        caretPositionOffset_ > 0, // trailing if nonzero, else leading edge
        &caretX,
        &caretY,
        &caretMetrics
        );

    // Draw selection by drawing all ranges
    __ecount(10) const Position* highlightImageRects =
        Base::gTheme_->GetImageParts(
            HasKeyFocus() ? ThemePartIdTextEditorHighlight : ThemePartIdTextEditorHighlightDim
            );

    for (size_t i = 0; i < actualHitTestCount; ++i)
    {
        // Note that an ideal layout will return fractional values.
        // For drawing selection, it gives a better appearance if the
        // coordinates are rounded to the nearest pixel, to reduce
        // blurriness and overlap.
        //
        // Notice that we floor the right edge and bottom edge,
        // not the width and height. Otherwise you will see an
        // an odd jiggle in the selection as you drag across the
        // text.
        const DWRITE_HIT_TEST_METRICS& htm = hitTestMetrics[i];
        Position highlightRect = {
            floor(htm.left),
            floor(htm.top),
            floor(htm.left + htm.width)  - highlightRect.l,
            floor(htm.top  + htm.height) - highlightRect.t
        };
        
        target.DrawNineGridImage(
            Base::gTheme_->GetImage(),
            highlightImageRects,
            highlightRect
            );
    }

    // Draw caret
    Position caretRect = {floor(caretX), floor(caretY), 1, floor(caretMetrics.height)};
    target.DrawNineGridImage(
        Base::gTheme_->GetImage(),
        Base::gTheme_->GetImageParts(ThemePartIdTextEditorCaret),
        caretRect
        );

    // Draw text
    Position nopRect = {0,0, position_.w,position_.h};
    target.DrawTextLayout(textLayout_, nopRect);

    target.SetTransform(previousTransform);
    target.PopClipRect();

    return true;
}


// Input related...

bool TextEditor::MouseEnter(MouseMessage& message)
{
    return true;
}


bool TextEditor::MouseExit(MouseMessage& message)
{
    currentlySelecting_ = false;
    currentlyPanning_   = false;
    return true;
}


bool TextEditor::MousePress(MouseMessage& message)
{
    SetKeyFocus();

    if (message.button == MouseMessage::ButtonLeft)
    {
        // Start dragging selection.
        SetMouseFocus(message);
        currentlySelecting_ = true;

        bool heldShift = (GetKeyState(VK_SHIFT) & 0x80) != 0;
        SetSelectionFromPoint(message.x, message.y, heldShift);
    }
    else if (message.button == MouseMessage::ButtonMiddle)
    {
        SetMouseFocus(message);
        previousMouseX    = message.x;
        previousMouseY    = message.y;
        currentlyPanning_ = true;
    }
    return true;
}


bool TextEditor::MouseRelease(MouseMessage& message)
{
    if (message.button == MouseMessage::ButtonLeft)
    {
        currentlySelecting_ = false;
    }
    else if (message.button == MouseMessage::ButtonMiddle)
    {
        currentlyPanning_ = false;
    }
    ReleaseMouseFocus(message);
    return true;
}


bool TextEditor::MouseMove(MouseMessage& message)
{
    if (currentlySelecting_)
    {
        // Drag current selection.
        SetSelectionFromPoint(message.x, message.y, true);
    }
    else if (currentlyPanning_)
    {
        DWRITE_MATRIX matrix;
        GetInverseViewMatrix(&matrix);

        float xDif = message.x - previousMouseX;
        float yDif = message.y - previousMouseY;
        previousMouseX = message.x;
        previousMouseY = message.y;

        originX_ -= (xDif * matrix.m11 + yDif * matrix.m21);
        originY_ -= (xDif * matrix.m12 + yDif * matrix.m22);

        SetRedraw();
    }
    return true;
}


bool TextEditor::MouseScroll(MouseMessage& message)
{
    bool heldShift   = (GetKeyState(VK_SHIFT)   & 0x80) != 0;
    bool heldControl = (GetKeyState(VK_CONTROL) & 0x80) != 0;

    if (heldControl)
    {
        // Scale
        scaleX_ = scaleX_ * ((message.yDif > 0) ? 1.0625f : 1/1.0625f);
        scaleY_ = scaleY_ * ((message.yDif > 0) ? 1.0625f : 1/1.0625f);
        if (owner_.IsSet())
            owner_.callback->ViewChanged(this, id_);
    }
    else
    {
        // Pan
        DWRITE_MATRIX matrix;
        GetInverseViewMatrix(&matrix);

        float yDif = message.yDif * MouseScrollFactor;
        float xDif = message.xDif * MouseScrollFactor; // for mice that support horizontal panning
        if (heldShift)
            std::swap(xDif, yDif);

        originX_ -= (xDif * matrix.m11 + yDif * matrix.m21);
        originY_ -= (xDif * matrix.m12 + yDif * matrix.m22);
    }

    SetRedraw();
    return true;
}


bool TextEditor::SetSelectionFromPoint(float x, float y, bool extendSelection)
{
    // Return the text position corresponding to the mouse x,y.
    // If hitting the trailing side of a cluster, return the
    // leading edge of the following text position.

    BOOL isTrailingHit;
    BOOL isInside;
    DWRITE_HIT_TEST_METRICS caretMetrics;

    // Remap display coordinates to actual.
    DWRITE_MATRIX matrix;
    GetInverseViewMatrix(&matrix);

    float transformedX = (x * matrix.m11 + y * matrix.m21 + matrix.dx);
    float transformedY = (x * matrix.m12 + y * matrix.m22 + matrix.dy);

    textLayout_->HitTestPoint(
        transformedX,
        transformedY,
        &isTrailingHit,
        &isInside,
        &caretMetrics
        );

    // Update current selection according to click or mouse drag.
    SetSelection(
        isTrailingHit ? SetSelectionModeAbsoluteTrailing : SetSelectionModeAbsoluteLeading,
        caretMetrics.textPosition,
        extendSelection
        );

    return true;
}


DWRITE_TEXT_RANGE TextEditor::GetSelectionRange()
{
    // Return a valid range, regardless of whether the caret or anchor is first.

    UINT32 caretBegin = caretAnchor_;
    UINT32 caretEnd   = caretPosition_ + caretPositionOffset_;
    if (caretBegin > caretEnd)
        std::swap(caretBegin, caretEnd);

    DWRITE_TEXT_RANGE textRange = {caretBegin, caretEnd - caretBegin};
    return textRange;
}


UINT32 TextEditor::GetCaretPosition()
{
    return caretPosition_ + caretPositionOffset_;
}


bool TextEditor::KeyEnter(KeyboardMessage& message)
{
    SetRedraw();
    return true;
}


bool TextEditor::KeyExit(KeyboardMessage& message)
{
    SetRedraw();
    return true;
}


bool TextEditor::KeyPress(KeyboardMessage& message)
{
    bool heldShift   = (GetKeyState(VK_SHIFT)   & 0x80) != 0;
    bool heldControl = (GetKeyState(VK_CONTROL) & 0x80) != 0;

    UINT32 absolutePosition = caretPosition_ + caretPositionOffset_;

    switch (message.button)
    {
    case VK_RETURN:
        // Insert CR/LF pair
        textLayout_->InsertTextAt(absolutePosition, L"\r\n", 2, &caretFormat_);
        SetSelection(SetSelectionModeAbsoluteLeading, absolutePosition + 2, false, false);
        return true;

    case VK_BACK:
        // Erase back one character (surrogate pair, but not cluster).
        // Since layout's hit-testing always returns a whole cluster,
        // we do the surrogate pair detection here directly.

        if (absolutePosition != caretAnchor_)
        {
            // delete the selected text
            DeleteSelection();
        }
        else if (absolutePosition > 0)
        {
            UINT32 count = 1;
            if (absolutePosition > 1
			&&  IsLowSurrogate(textLayout_->GetCharacterAt(absolutePosition - 1))
            &&  IsHighSurrogate(textLayout_->GetCharacterAt(absolutePosition - 2)))
            {
                count = 2;
            }
            SetSelection(SetSelectionModeLeftChar, count, false);
            textLayout_->RemoveTextAt(caretPosition_, count);
        }
        return true;

    case VK_DELETE:
        // Delete following cluster.

        if (absolutePosition != caretAnchor_)
        {
            // Delete all the selected text.
            DeleteSelection();
        }
        else
        {
            DWRITE_HIT_TEST_METRICS hitTestMetrics;
            float caretX, caretY;

            // Get the size of the following cluster.
            textLayout_->HitTestTextPosition(
                absolutePosition,
                false,
                &caretX,
                &caretY,
                &hitTestMetrics
                );

            textLayout_->RemoveTextAt(hitTestMetrics.textPosition, hitTestMetrics.length);
            SetSelection(SetSelectionModeAbsoluteLeading, hitTestMetrics.textPosition, false);
            SetRedraw();  // manually indicate that the text needs to be redrawn
        }
        return true;

    case VK_TAB:
        return true; // want tabs

    case VK_LEFT: // seek left one cluster
        SetSelection(heldControl ? SetSelectionModeLeftWord : SetSelectionModeLeft, 1, heldShift);
        return true;

    case VK_RIGHT: // seek right one cluster
        SetSelection(heldControl ? SetSelectionModeRightWord : SetSelectionModeRight, 1, heldShift);
        return true;

    case VK_UP: // up a line
        SetSelection(SetSelectionModeUp, 1, heldShift);
        return true;

    case VK_DOWN: // down a line
        SetSelection(SetSelectionModeDown, 1, heldShift);
        return true;

    case VK_HOME: // beginning of line
        SetSelection(heldControl ? SetSelectionModeFirst : SetSelectionModeHome, 0, heldShift);
        return true;

    case VK_END: // end of line
        SetSelection(heldControl ? SetSelectionModeLast : SetSelectionModeEnd, 0, heldShift);
        return true;
    }

    if (heldControl)
    {
        switch (message.button)
        {
        case 'C':
            CopyToClipboard();
            return true;

        case 'V':
            PasteFromClipboard();
            return true;

        case 'X':
            CopyToClipboard();
            DeleteSelection();
            return true;

        case 'A':
            SetSelection(SetSelectionModeAll, 0, true);
            return true;
        }
    }

    return false;
}


bool TextEditor::KeyRelease(KeyboardMessage& message)
{
    return false;
}


bool TextEditor::KeyCharacter(KeyboardMessage& message)
{
    // Allow normal characters and tabs
    if (message.character >= 0x20 || message.character == 9)
    {
        // 1. Convert UTF32 to UTF16
        // 2. Insert character code units (1-2)
        // 3. Advance caret position by how many code units were inserted
        DeleteSelection();

        UINT32 charsLength = 1;
        wchar_t chars[2] = {static_cast<wchar_t>(message.character), 0};
        if (message.character > 0xFFFF)
        {
            // Split into leading and trailing surrogatse.
            // From http://unicode.org/faq/utf_bom.html#35
            chars[0] = wchar_t(0xD800 + (message.character >> 10)  - (0x10000 >> 10));
            chars[1] = wchar_t(0xDC00 + (message.character & 0x3FF));
            charsLength++;
        }
        textLayout_->InsertTextAt(caretPosition_ + caretPositionOffset_, chars, charsLength, &caretFormat_);
        SetSelection(SetSelectionModeRight, charsLength, false, false);

        if (owner_.IsSet())
            owner_.callback->TextEdited(this, id_);
    }

    SetRedraw();
    return false;
}


void TextEditor::SetTextLayout(IDWriteTextEditLayout* layout)
{
    textLayout_.Set(layout);
    layout->SetMaxWidth(contentWidth_);
    layout->SetMaxHeight(contentHeight_);
    SetRedraw();
}


void TextEditor::SetOwner(
    RefCountBase* target,
    Owner* owner
    )
{
    owner_.Set(target, owner);
}


void TextEditor::GetLineMetrics(
    __out std::vector<DWRITE_LINE_METRICS>& lineMetrics
    )
{
    // Retrieve the line metrics to know first and last position.
    DWRITE_TEXT_METRICS textMetrics;
    textLayout_->GetMetrics(&textMetrics);

    lineMetrics.resize(textMetrics.lineCount);
    textLayout_->GetLineMetrics(&lineMetrics.front(), textMetrics.lineCount, &textMetrics.lineCount);
}


void TextEditor::GetLineFromPosition(
    __in_ecount(lineCount) DWRITE_LINE_METRICS* lineMetrics,
    UINT32 lineCount,
    UINT32 textPosition,
    __out UINT32* lineOut,
    __out UINT32* linePositionOut
    )
{
    // Given the line metrics, determine the current line and starting text
    // position of that line by summing up the lengths. When the starting
    // line position is beyond the given text position, we have our line.
    UINT32 line = 0;
    UINT32 linePosition = 0;
    UINT32 nextLinePosition = 0;
    for ( ; line < lineCount; ++line)
    {
        linePosition = nextLinePosition;
        nextLinePosition = linePosition + lineMetrics[line].length;
        if (nextLinePosition > textPosition)
        {
            // The next line is beyond the desired text position,
            // so it must be in the current line.
            break;
        }
    }
    *linePositionOut = linePosition;
    *lineOut = std::min(line, lineCount - 1);
    return;
}


void TextEditor::AlignCaretToNearestCluster(bool isTrailingHit, bool skipZeroWidth)
{
    DWRITE_HIT_TEST_METRICS hitTestMetrics;
    float caretX, caretY;

    // Align the caret to the nearest whole cluster.
    textLayout_->HitTestTextPosition(
        caretPosition_,
        false,
        &caretX,
        &caretY,
        &hitTestMetrics
        );

    // The caret position itself is always the leading edge.
    // An additional offset indicates a trailing edge when non-zero.
    // This offset comes from the number of code-units in the
    // selected cluster or surrogate pair.
    caretPosition_        = hitTestMetrics.textPosition;
    caretPositionOffset_  = (isTrailingHit) ? hitTestMetrics.length : 0;

    // For invisible, zero-width characters (like line breaks
    // and formatting characters), force leading edge of the
    // next position.
    if (skipZeroWidth && hitTestMetrics.width == 0)
    {
        caretPosition_      += caretPositionOffset_;
        caretPositionOffset_ = 0;
    }
}


bool TextEditor::SetSelection(SetSelectionMode moveMode, UINT32 advance, bool extendSelection, bool updateCaretFormat)
{
    // Moves the caret relatively or absolutely, optionally extending the
    // selection range (for example, when shift is held).

    UINT32 line = UINT32_MAX; // current line number, needed by a few modes
    UINT32 absolutePosition    = caretPosition_ + caretPositionOffset_;
    UINT32 oldAbsolutePosition = absolutePosition;
    UINT32 oldCaretAnchor      = caretAnchor_;

    switch (moveMode)
    {
    case SetSelectionModeLeft:
        caretPosition_ += caretPositionOffset_;
        if (caretPosition_ > 0)
        {
            --caretPosition_;
            AlignCaretToNearestCluster(false, true);

            // special check for CR/LF pair
            absolutePosition = caretPosition_ + caretPositionOffset_;
            if (absolutePosition > 1
			&&  textLayout_->GetCharacterAt(absolutePosition) == '\n'
			&&  textLayout_->GetCharacterAt(absolutePosition - 1) == '\r')
            {
                caretPosition_ = absolutePosition - 1;
                AlignCaretToNearestCluster(false, true);
            }
        }
        break;

    case SetSelectionModeRight:
        caretPosition_ = absolutePosition;
        AlignCaretToNearestCluster(true, true);

        // special check for CR/LF pair
        absolutePosition = caretPosition_ + caretPositionOffset_;
        if (absolutePosition > 1
		&&  textLayout_->GetCharacterAt(absolutePosition - 1) == '\r'
		&&  textLayout_->GetCharacterAt(caretPosition_)       == '\n')
        {
            caretPosition_ = absolutePosition + 1;
            AlignCaretToNearestCluster(false, true);
        }
        break;

    case SetSelectionModeLeftChar:
        caretPosition_       = absolutePosition;
        caretPosition_      -= std::min(advance, absolutePosition);
        caretPositionOffset_ = 0;
        break;

    case SetSelectionModeRightChar:
        caretPosition_       = absolutePosition + advance;
        caretPositionOffset_ = 0;
        {
            // Use hit-testing to limit text position.
            DWRITE_HIT_TEST_METRICS hitTestMetrics;
            float caretX, caretY;

            textLayout_->HitTestTextPosition(
                caretPosition_,
                false,
                &caretX,
                &caretY,
                &hitTestMetrics
                );
            caretPosition_ = std::min(caretPosition_, hitTestMetrics.textPosition + hitTestMetrics.length);
        }
        break;

    case SetSelectionModeUp:
    case SetSelectionModeDown:
        {
            // Retrieve the line metrics to figure out what line we are on.
            std::vector<DWRITE_LINE_METRICS> lineMetrics;
            GetLineMetrics(lineMetrics);

            UINT32 linePosition;
            GetLineFromPosition(
                &lineMetrics.front(),
                static_cast<UINT32>(lineMetrics.size()),
                caretPosition_,
                &line,
                &linePosition
                );

            // Move up a line or down
            if (moveMode == SetSelectionModeUp)
            {
                if (line <= 0)
                    break; // already top line
                line--;
                linePosition -= lineMetrics[line].length;
            }
            else
            {
                linePosition += lineMetrics[line].length;
                line++;
                if (line >= lineMetrics.size())
                    break; // already bottom line
            }

            // To move up or down, we need three hit-testing calls to determine:
            // 1. The x of where we currently are.
            // 2. The y of the new line.
            // 3. New text position from the determined x and y.

            DWRITE_HIT_TEST_METRICS hitTestMetrics;
            float caretX, caretY, dummyX;

            // Get x of current text position
            textLayout_->HitTestTextPosition(
                caretPosition_,
                caretPositionOffset_ > 0, // trailing if nonzero, else leading edge
                &caretX,
                &caretY,
                &hitTestMetrics
                );

            // Get y of new position
            textLayout_->HitTestTextPosition(
                linePosition,
                false, // leading edge
                &dummyX,
                &caretY,
                &hitTestMetrics
                );

            // Now get text position of new x,y.
            BOOL isInside, isTrailingHit;
            textLayout_->HitTestPoint(
                caretX,
                caretY,
                &isTrailingHit,
                &isInside,
                &hitTestMetrics
                );

            caretPosition_       = hitTestMetrics.textPosition;
            caretPositionOffset_ = isTrailingHit ? (hitTestMetrics.length > 0) : 0;
        }
        break;

    case SetSelectionModeLeftWord:
    case SetSelectionModeRightWord:
        {
            // To navigate by whole words, we look for the canWrapLineAfter
            // flag in the cluster metrics.

            // First need to know how many clusters there are.
            std::vector<DWRITE_CLUSTER_METRICS> clusterMetrics;
            UINT32 clusterCount;
            textLayout_->GetClusterMetrics(NULL, 0, &clusterCount);

            if (clusterCount == 0)
                break;

            // Now we actually read them.
            clusterMetrics.resize(clusterCount);
            textLayout_->GetClusterMetrics(&clusterMetrics.front(), clusterCount, &clusterCount);

            caretPosition_ = absolutePosition;

            UINT32 clusterPosition  = 0;
            UINT32 oldCaretPosition = caretPosition_;

            if (moveMode == SetSelectionModeLeftWord)
            {
                // Read through the clusters, keeping track of the farthest valid
                // stopping point just before the old position.
                caretPosition_       = 0;
                caretPositionOffset_ = 0; // leading edge
                for (UINT32 cluster  = 0; cluster < clusterCount; ++cluster)
                {
                    clusterPosition += clusterMetrics[cluster].length;
                    if (clusterMetrics[cluster].canWrapLineAfter)
                    {
                        if (clusterPosition >= oldCaretPosition)
                            break;

                        // Update in case we pass this point next loop.
                        caretPosition_ = clusterPosition;
                    }
                }
            }
            else // SetSelectionModeRightWord
            {
                // Read through the clusters, looking for the first stopping point
                // after the old position.
                for (UINT32 cluster = 0; cluster < clusterCount; ++cluster)
                {
                    UINT32 clusterLength = clusterMetrics[cluster].length;
                    caretPosition_       = clusterPosition;
                    caretPositionOffset_ = clusterLength; // trailing edge
                    if (clusterPosition >= oldCaretPosition && clusterMetrics[cluster].canWrapLineAfter)
                        break; // first stopping point after old position.

                    clusterPosition += clusterLength;
                }
            }
        }
        break;

    case SetSelectionModeHome:
    case SetSelectionModeEnd:
        {
            // Retrieve the line metrics to know first and last position.
            std::vector<DWRITE_LINE_METRICS> lineMetrics;
            GetLineMetrics(lineMetrics);

            GetLineFromPosition(
                &lineMetrics.front(),
                static_cast<UINT32>(lineMetrics.size()),
                caretPosition_,
                &line,
                &caretPosition_
                );

            caretPositionOffset_ = 0;
            if (moveMode == SetSelectionModeEnd)
            {
                UINT32 lineLength    = lineMetrics[line].length - lineMetrics[line].newlineLength;
                caretPositionOffset_ = std::min(lineLength, 1u);
                caretPosition_      += lineLength - caretPositionOffset_;
                AlignCaretToNearestCluster(true);
            }
        }
        break;

    case SetSelectionModeFirst:
        caretPosition_       = 0;
        caretPositionOffset_ = 0;
        break;

    case SetSelectionModeAll:
        caretAnchor_ = 0;
        extendSelection = true;
        __fallthrough;

    case SetSelectionModeLast:
        caretPosition_       = UINT32_MAX;
        caretPositionOffset_ = 0;
        AlignCaretToNearestCluster(true);
        break;

    case SetSelectionModeAbsoluteLeading:
        caretPosition_       = advance;
        caretPositionOffset_ = 0;
        break;

    case SetSelectionModeAbsoluteTrailing:
        caretPosition_       = advance;
        AlignCaretToNearestCluster(true);
        break;
    }

    absolutePosition = caretPosition_ + caretPositionOffset_;

    if (!extendSelection)
        caretAnchor_ = absolutePosition;

    bool caretMoved = (absolutePosition != oldAbsolutePosition)
                   || (caretAnchor_     != oldCaretAnchor);

    if (caretMoved)
    {
        // update the caret formatting attributes
        if (updateCaretFormat)
            UpdateCaretFormatting();

        SetRedraw();
        if (owner_.IsSet())
            owner_.callback->CaretMoved(this, id_);
    }

    return caretMoved;
}


void TextEditor::UpdateCaretFormatting()
{
    UINT32 currentPos = caretPosition_ + caretPositionOffset_;

    if (currentPos > 0)
    {
        --currentPos;
    }

    // get the family name
    UINT32 fontFamilyNameLength;
    OsException::ThrowOnFailure(textLayout_->GetFontFamilyNameLength(
        currentPos,
        &fontFamilyNameLength),
        "Could not query family name length." FAILURE_LOCATION);
    fontFamilyNameLength++;
    assert(0 != fontFamilyNameLength);
    caretFormat_.fontFamilyName.resize(fontFamilyNameLength);
    OsException::ThrowOnFailure(textLayout_->GetFontFamilyName(
        currentPos,
        &caretFormat_.fontFamilyName[0],
        fontFamilyNameLength
        ),
        FAILURE_LOCATION);

    // get the locale
    UINT32 localeNameLength;
    OsException::ThrowOnFailure(textLayout_->GetLocaleNameLength(
        currentPos,
        &localeNameLength),
        FAILURE_LOCATION);
    localeNameLength++;
    assert(0 != localeNameLength);
    caretFormat_.localeName.resize(localeNameLength);
    OsException::ThrowOnFailure(textLayout_->GetLocaleName(
        currentPos,
        &caretFormat_.localeName[0],
        localeNameLength
        ),
        FAILURE_LOCATION);

    // weight/width/slope
    OsException::ThrowOnFailure(textLayout_->GetFontWeight(
        currentPos,
        &caretFormat_.fontWeight),
        FAILURE_LOCATION);
    OsException::ThrowOnFailure(textLayout_->GetFontStyle(
        currentPos,
        &caretFormat_.fontStyle),
        FAILURE_LOCATION);
    OsException::ThrowOnFailure(textLayout_->GetFontStretch(
        currentPos,
        &caretFormat_.fontStretch),
        FAILURE_LOCATION);

    // font size
    OsException::ThrowOnFailure(textLayout_->GetFontSize(
        currentPos,
        &caretFormat_.fontSize),
        FAILURE_LOCATION);

    // underline and strikethrough
    OsException::ThrowOnFailure(textLayout_->GetUnderline(
        currentPos,
        &caretFormat_.hasUnderline
        ),
        FAILURE_LOCATION);
    OsException::ThrowOnFailure(textLayout_->GetStrikethrough(
        currentPos,
        &caretFormat_.hasStrikethrough
        ),
        FAILURE_LOCATION);
}


void TextEditor::CopyToClipboard()
{
    DWRITE_TEXT_RANGE selectionRange = GetSelectionRange();
    if (selectionRange.length == 0)
        return;

    OsException::ThrowOnFailure(
        textLayout_->CopyTextToClipboard(selectionRange),
        "Cannot copy the text." FAILURE_LOCATION
        );
}


void TextEditor::DeleteSelection()
{
    DWRITE_TEXT_RANGE selectionRange = GetSelectionRange();
    if (selectionRange.length == 0)
        return;

    OsException::ThrowOnFailure(
        textLayout_->RemoveTextAt(selectionRange.startPosition, selectionRange.length),
        "Cannot delete the text." FAILURE_LOCATION
        );
    SetSelection(SetSelectionModeAbsoluteLeading, selectionRange.startPosition, false);
    SetRedraw();
}


void TextEditor::PasteFromClipboard()
{
    DeleteSelection();
    UINT32 numCharacters = 0;
    OsException::ThrowOnFailure(
        textLayout_->PasteTextFromClipboard(caretPosition_ + caretPositionOffset_, &numCharacters),
        "Could not paste text from the clipboard." FAILURE_LOCATION
        );
    if (numCharacters <= 0)
        return;

    SetSelection(SetSelectionModeRightChar, numCharacters, true);
    SetRedraw();
}


float TextEditor::SetAngle(float angle, bool relativeAdjustement)
{
    if (relativeAdjustement)
        angle_ += angle;
    else
        angle_ = angle;

    SetRedraw();

    return angle_;
}


void TextEditor::SetScale(float scaleX, float scaleY, bool relativeAdjustement)
{
    if (relativeAdjustement)
    {
        scaleX_ *= scaleX;
        scaleY_ *= scaleY;
    }
    else
    {
        scaleX_ = scaleX;
        scaleY_ = scaleY;
    }
    SetRedraw();
}


void TextEditor::GetScale(__out float* scaleX, __out float* scaleY)
{
    *scaleX = scaleX_;
    *scaleY = scaleY_;
}


void TextEditor::GetViewMatrix(__out DWRITE_MATRIX* matrix) const
{
    struct Helpers
    {
        static inline double DegreesToRadians(float degrees)
        {
            return degrees * M_PI * 2.0f / 360.0f;
        }

        static inline D2D1::Matrix3x2F& Cast(DWRITE_MATRIX& matrix)
        {
            return *reinterpret_cast<D2D1::Matrix3x2F*>(&matrix);
        }
    };

    // Translate origin to 0,0
    DWRITE_MATRIX translationMatrix = {
        1, 0,
        0, 1,
        -originX_, -originY_
    };
    DWRITE_MATRIX shearMatrix = {
        1,          shearY_,
        shearX_,    1,
        0,          0
    };

    // Scale and rotate
    double radians = Helpers::DegreesToRadians(fmod(angle_, 360.0f));
    double cosValue = cos(radians);
    double sinValue = sin(radians);

    // If rotation is a quarter multiple, ensure sin and cos are exactly one of {-1,0,1}
    if (fmod(angle_, 90.0f) == 0)
    {
        cosValue = floor(cosValue + .5);
        sinValue = floor(sinValue + .5);
    }

    DWRITE_MATRIX rotationMatrix = {
        float( cosValue * scaleX_), float(sinValue * scaleX_),
        float(-sinValue * scaleY_), float(cosValue * scaleY_),
        0, 0
    };

    // Set the origin in the center of the window
    float centeringFactor = .5f;
    DWRITE_MATRIX centerMatrix = {
        1, 0,
        0, 1,
        floor(float(position_.w * centeringFactor)), floor(float(position_.h * centeringFactor))
    };

    D2D1::Matrix3x2F resultA, resultB;

    resultA.SetProduct(Helpers::Cast(shearMatrix),       Helpers::Cast(rotationMatrix)   );
    resultB.SetProduct(Helpers::Cast(translationMatrix), resultA                         );
    resultA.SetProduct(resultB,                          Helpers::Cast(centerMatrix)     );

    // For better pixel alignment (less blurry text)
    resultA._31 = floor(resultA._31);
    resultA._32 = floor(resultA._32);

    *matrix = *reinterpret_cast<DWRITE_MATRIX*>(&resultA);
}


void TextEditor::GetInverseViewMatrix(__out DWRITE_MATRIX* matrix) const
{
    struct Helpers
    {
        inline static float GetDeterminant(__in DWRITE_MATRIX const& matrix)
        {
            return matrix.m11 * matrix.m22 - matrix.m12 * matrix.m21;
        }

        static void ComputeInverseMatrix(
            __in  DWRITE_MATRIX const& matrix,
            __out DWRITE_MATRIX& result
            )
        {
            float invdet = 1.f / GetDeterminant(matrix);
            result.m11 =  matrix.m22 * invdet;
            result.m12 = -matrix.m12 * invdet;
            result.m21 = -matrix.m21 * invdet;
            result.m22 =  matrix.m11 * invdet;
            result.dx  = (matrix.m21 * matrix.dy  - matrix.dx  * matrix.m22) * invdet;
            result.dy  = (matrix.dx  * matrix.m12 - matrix.m11 * matrix.dy)  * invdet;
        }
    };

    DWRITE_MATRIX viewMatrix;
    GetViewMatrix(&viewMatrix);
    Helpers::ComputeInverseMatrix(viewMatrix, *matrix);
}
