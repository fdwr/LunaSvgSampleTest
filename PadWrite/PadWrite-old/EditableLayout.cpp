//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Extended TextLayout that permits editing.
//
//  Remarks:    Internally, a new DirectWrite layout is recreated when the
//              text is edited, but the caller can safely hold the same
//              reference, since the adapter forwards all the calls onward.
//
//----------------------------------------------------------------------------
#include "precomp.h"


void CopySinglePropertyRange(
    IDWriteTextLayout* oldLayout,
    UINT32 startPosForOld,
    IDWriteTextLayout* newLayout,
    UINT32 startPosForNew,
    UINT32 length,
    __maybenull EditableLayout::CaretFormat* caretFormat = NULL
    )
{
    // Copies a single range of similar properties, from one old layout
    // to a new one.

    DWRITE_TEXT_RANGE range = {startPosForNew,  std::min(length, UINT32_MAX - startPosForNew)};

    // font collection
    ComPtr<IDWriteFontCollection> fontCollection;
    HrException::IfFailed(oldLayout->GetFontCollection(startPosForOld, &fontCollection));
    HrException::IfFailed(newLayout->SetFontCollection(fontCollection, range));

    if (caretFormat != NULL)
    {
        HrException::IfFailed(newLayout->SetFontFamilyName(caretFormat->fontFamilyName.c_str(), range));
        HrException::IfFailed(newLayout->SetLocaleName(caretFormat->localeName.c_str(), range));
        HrException::IfFailed(newLayout->SetFontWeight(caretFormat->fontWeight, range));
        HrException::IfFailed(newLayout->SetFontStyle(caretFormat->fontStyle, range));
        HrException::IfFailed(newLayout->SetFontStretch(caretFormat->fontStretch, range));
        HrException::IfFailed(newLayout->SetFontSize(caretFormat->fontSize, range));
        HrException::IfFailed(newLayout->SetUnderline(caretFormat->hasUnderline, range));
        HrException::IfFailed(newLayout->SetStrikethrough(caretFormat->hasStrikethrough, range));
    }
    else
    {
        // font family
        UINT32 fontFamilyNameLength;
        HrException::IfFailed(oldLayout->GetFontFamilyNameLength(startPosForOld, &fontFamilyNameLength));
        fontFamilyNameLength++;
        std::wstring fontFamilyName(fontFamilyNameLength, '\0');

        HrException::IfFailed(oldLayout->GetFontFamilyName(startPosForOld, &fontFamilyName[0], fontFamilyNameLength));
        HrException::IfFailed(newLayout->SetFontFamilyName(fontFamilyName.c_str(), range));

        // weight/width/slope
        DWRITE_FONT_WEIGHT weight;
        DWRITE_FONT_STYLE style;
        DWRITE_FONT_STRETCH stretch;
        HrException::IfFailed(oldLayout->GetFontWeight(startPosForOld, &weight));
        HrException::IfFailed(oldLayout->GetFontStyle(startPosForOld, &style));
        HrException::IfFailed(oldLayout->GetFontStretch(startPosForOld, &stretch));

        HrException::IfFailed(newLayout->SetFontWeight(weight, range));
        HrException::IfFailed(newLayout->SetFontStyle(style, range));
        HrException::IfFailed(newLayout->SetFontStretch(stretch, range));

        // font size
        FLOAT fontSize;
        HrException::IfFailed(oldLayout->GetFontSize(startPosForOld, &fontSize));
        HrException::IfFailed(newLayout->SetFontSize(fontSize, range));

        // underline and strikethrough
        BOOL value;
        HrException::IfFailed(oldLayout->GetUnderline(startPosForOld,&value));
        HrException::IfFailed(newLayout->SetUnderline(value,range));
        HrException::IfFailed(oldLayout->GetStrikethrough(startPosForOld, &value));
        HrException::IfFailed(newLayout->SetStrikethrough(value, range));

        // locale
        UINT32 localeNameLength;
        HrException::IfFailed(oldLayout->GetLocaleNameLength(startPosForOld, &localeNameLength));
        localeNameLength++;
        std::wstring localeName(localeNameLength, '\0');
        HrException::IfFailed(oldLayout->GetLocaleName(startPosForOld, &localeName[0], localeNameLength));
        HrException::IfFailed(newLayout->SetLocaleName(localeName.c_str(), range));
    }

    // drawing effect
    ComPtr<IUnknown> drawingEffect;
    HrException::IfFailed(oldLayout->GetDrawingEffect(startPosForOld, &drawingEffect));
    HrException::IfFailed(newLayout->SetDrawingEffect(drawingEffect, range));

    // inline object
    ComPtr<IDWriteInlineObject> inlineObject;
    HrException::IfFailed(oldLayout->GetInlineObject(startPosForOld, &inlineObject));
    HrException::IfFailed(newLayout->SetInlineObject(inlineObject, range));

    // typography
    ComPtr<IDWriteTypography> typography;
    HrException::IfFailed(oldLayout->GetTypography(startPosForOld, &typography));
    HrException::IfFailed(newLayout->SetTypography(typography, range));
}


HRESULT EditableLayout::CreateEditableLayout(
    IDWriteFactory* factory,
    __in_ecount(textLength) WCHAR const* text,
    UINT32 textLength,
    IDWriteTextFormat* textFormat,
    FLOAT maxWidth,
    FLOAT maxHeight,
    __out IDWriteEditableTextLayout** textLayout
    )
{
    // Creates the adapter layout that internally holds a DWrite layout.

    *textLayout = NULL;

    try
    {
        ComPtr<IDWriteTextLayout> innerTextLayout;
        HrException::IfFailed(factory->CreateTextLayout(
            text,
            textLength,
            textFormat,
            maxWidth,
            maxHeight,
            &innerTextLayout
            ));

        ComPtr<IDWriteEditableTextLayout> textEditLayout = new EditableLayout(
            innerTextLayout,
            factory,
            text
            );

        *textLayout = textEditLayout.Detach();
    }
    catch (HrException& e)
    {
        return e.GetErrorCode();
    }

    return S_OK;
}


void EditableLayout::RecreateInnerLayout(IDWriteTextLayout* oldLayout)
{
    // Recreates the internally held layout.

    innerLayout_.Attach(NULL);

    HrException::IfFailed(
        factory_->CreateTextLayout(
            text_.c_str(),
            static_cast<UINT32>(text_.length()),
            oldLayout,
            oldLayout->GetMaxWidth(),
            oldLayout->GetMaxHeight(),
            &innerLayout_
            ));
}


UINT32 CalculateRangeLengthAt(
    IDWriteTextLayout* layout,
    UINT32 pos
    )
{
    // Determines the length of a block of similarly formatted properties.

    // Use the first getter to get the range to increment the current position.
    DWRITE_TEXT_RANGE incrementAmount = {pos, 1};
    DWRITE_FONT_WEIGHT weight;

    HrException::IfFailed(layout->GetFontWeight(
        pos,
        &weight,
        &incrementAmount
        ));

    UINT32 rangeLength = incrementAmount.length - (pos - incrementAmount.startPosition);
    return rangeLength;
}


void EditableLayout::CopyRangedProperties(
    IDWriteTextLayout* oldLayout,
    UINT32 startPos,
    UINT32 endPos, // an STL-like one-past position.
    UINT32 newLayoutTextOffset,
    IDWriteTextLayout* newLayout,
    bool isOffsetNegative
    )
{
    // Copies properties that set on ranges.

    UINT32 currentPos = startPos;
    while (currentPos < endPos)
    {
        UINT32 rangeLength = CalculateRangeLengthAt(oldLayout, currentPos);
        rangeLength = std::min(rangeLength, endPos - currentPos);
        if (isOffsetNegative)
        {
            CopySinglePropertyRange(
                oldLayout,
                currentPos,
                newLayout,
                currentPos - newLayoutTextOffset,
                rangeLength
                );
        }
        else
        {
            CopySinglePropertyRange(
                oldLayout,
                currentPos,
                newLayout,
                currentPos + newLayoutTextOffset,
                rangeLength
                );
        }
        currentPos += rangeLength;
    }
}


STDMETHODIMP EditableLayout::InsertTextAt(
    UINT32 position,
    __in_ecount(lengthToInsert) WCHAR const* text,
    UINT32 lengthToInsert,
    __maybenull EditableLayout::CaretFormat* caretFormat
    )
{
    // Inserts text and shifts all formatting.

    try
    {
        // The inserted string gets all the properties of the character right before position.
        // If there is no text right before position, so use the properties of the character right after position.

        // Copy all the old formatting.
        ComPtr<IDWriteTextLayout> oldLayout = innerLayout_;
        UINT32 oldTextLength = static_cast<UINT32>(text_.length());
        position = std::min(position, static_cast<UINT32>(text_.size()));

        // Insert the new text and recreate the new text layout.
        text_.insert(position, text, lengthToInsert);

        RecreateInnerLayout(oldLayout);
        CopyNonRangeProperties(oldLayout);

        // For each property, get the position range and apply it to the old text.
        if (position == 0)
        {
            // Inserted text
            CopySinglePropertyRange(oldLayout, 0, innerLayout_, 0, lengthToInsert);

            // The rest of the text
            CopyRangedProperties(oldLayout, 0, oldTextLength, lengthToInsert, innerLayout_);
        }
        else
        {
            // 1st block
            CopyRangedProperties(oldLayout, 0, position, 0, innerLayout_);

            // Inserted text
            CopySinglePropertyRange(oldLayout, position - 1, innerLayout_, position, lengthToInsert, caretFormat);

            // Last block (if it exists)
            CopyRangedProperties(oldLayout, position, oldTextLength, lengthToInsert, innerLayout_);
        }

        // Copy trailing end.
        CopySinglePropertyRange(oldLayout, oldTextLength, innerLayout_, static_cast<UINT32>(text_.length()), UINT32_MAX);
    }
    catch (HrException& e)
    {
        return e.GetErrorCode();
    }

    return S_OK;
}


STDMETHODIMP EditableLayout::RemoveTextAt(
    UINT32 position,
    UINT32 lengthToRemove
    )
{
    // Removes text and shifts all formatting.

    try
    {
        // copy all the old formatting.
        ComPtr<IDWriteTextLayout> oldLayout = innerLayout_;
        UINT32 oldTextLength = static_cast<UINT32>(text_.length());

        // Remove the old text and recreate the new text layout.
        text_.erase(position, lengthToRemove);

        RecreateInnerLayout(oldLayout);
        CopyNonRangeProperties(oldLayout);

        if (position == 0)
        {
            // The rest of the text
            CopyRangedProperties(oldLayout, lengthToRemove, oldTextLength, lengthToRemove, innerLayout_, true); 
        }
        else
        {
            // 1st block
            CopyRangedProperties(oldLayout, 0, position, 0, innerLayout_, true );

            // Last block (if it exists, we increment past the deleted text)
            CopyRangedProperties(oldLayout, position + lengthToRemove, oldTextLength, lengthToRemove, innerLayout_, true);
        }
        CopySinglePropertyRange(oldLayout, oldTextLength, innerLayout_, static_cast<UINT32>(text_.length()), UINT32_MAX);
    }
    catch (HrException& e)
    {
        return e.GetErrorCode();
    }

    return S_OK;
}


STDMETHODIMP EditableLayout::Clear()
{
    ComPtr<IDWriteTextLayout> oldLayout = innerLayout_;

    text_.resize(0);
    RecreateInnerLayout(oldLayout);

    return S_OK;
}


void EditableLayout::CopyNonRangeProperties(IDWriteTextLayout* oldLayout)
{
    // Copies global properties that are not range based.

    HrException::IfFailed(innerLayout_->SetTextAlignment(oldLayout->GetTextAlignment()));
    HrException::IfFailed(innerLayout_->SetParagraphAlignment(oldLayout->GetParagraphAlignment()));
    HrException::IfFailed(innerLayout_->SetWordWrapping(oldLayout->GetWordWrapping()));
    HrException::IfFailed(innerLayout_->SetReadingDirection(oldLayout->GetReadingDirection()));
    HrException::IfFailed(innerLayout_->SetFlowDirection(oldLayout->GetFlowDirection()));
    HrException::IfFailed(innerLayout_->SetIncrementalTabStop(oldLayout->GetIncrementalTabStop()));

    DWRITE_TRIMMING trimmingOptions;
    ComPtr<IDWriteInlineObject> inlineObject;
    HrException::IfFailed(oldLayout->GetTrimming(&trimmingOptions, &inlineObject));
    HrException::IfFailed(innerLayout_->SetTrimming(&trimmingOptions, inlineObject));

    DWRITE_LINE_SPACING_METHOD lineSpacingMethod;
    FLOAT lineSpacing;
    FLOAT baseline;
    HrException::IfFailed(oldLayout->GetLineSpacing(&lineSpacingMethod, &lineSpacing, &baseline));
    HrException::IfFailed(innerLayout_->SetLineSpacing(lineSpacingMethod, lineSpacing, baseline));
}


STDMETHODIMP_(wchar_t) EditableLayout::GetCharacterAt(
    UINT32 position
    )
{
    if (position >= static_cast<UINT32>(text_.length()))
    {
        return 0;
    }

    return text_[position];
}


STDMETHODIMP_(const wchar_t*) EditableLayout::GetText()
{
    return text_.c_str();
}


STDMETHODIMP_(UINT32) EditableLayout::GetTextLength()
{
    return static_cast<UINT32>(text_.length());
}
