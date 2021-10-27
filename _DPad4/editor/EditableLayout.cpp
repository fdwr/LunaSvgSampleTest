//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Extended TextLayout that permits editing.
//
//  Remarks:    Internally, a new layout is recreated when the text is edited,
//              but the caller can safely hold the same reference.
//
//----------------------------------------------------------------------------

#include "precomp.h"

using namespace DWritePad;
using namespace DWritePad::Implementation;


void ErrorCheck::ThrowIfFailedHR(HRESULT hr)
{
    if (FAILED(hr))
    {
        throw Exception::BadHResultException(hr);
    }
}

void CopyRangePropertiesHelper(
    IDWriteTextLayout* oldLayout,
    UINT32 startPosForOld,
    IDWriteTextLayout* newLayout,
    UINT32 startPosForNew,
    UINT32 length,
    __maybenull CaretFormattingAttributes* caretAttributes = NULL
    )
{
    DWRITE_TEXT_RANGE range = {startPosForNew,
                               std::min(length, UINT32_MAX-startPosForNew)};

    //font collection
    IDWriteFontCollectionPtr fontCollection;
    ErrorCheck::ThrowIfFailedHR(oldLayout->GetFontCollection(
        startPosForOld,
        &fontCollection
        ));
    ErrorCheck::ThrowIfFailedHR(newLayout->SetFontCollection(
        fontCollection,
        range
        ));

    if (caretAttributes != NULL)
    {
        //font family
        ErrorCheck::ThrowIfFailedHR(newLayout->SetFontFamilyName(
            caretAttributes->fontFamilyName.c_str(),
            range
            ));

        //locale
        ErrorCheck::ThrowIfFailedHR(newLayout->SetLocaleName(
            caretAttributes->localeName.c_str(),
            range
            ));

        //WSS
        ErrorCheck::ThrowIfFailedHR(newLayout->SetFontWeight(
            caretAttributes->fontWeight,
            range
            ));
        ErrorCheck::ThrowIfFailedHR(newLayout->SetFontStyle(
            caretAttributes->fontStyle,
            range
            ));
        ErrorCheck::ThrowIfFailedHR(newLayout->SetFontStretch(
            caretAttributes->fontStretch,
            range
            ));

        //font size
        ErrorCheck::ThrowIfFailedHR(newLayout->SetFontSize(
            caretAttributes->fontSize,
            range
            ));

        //underline and strikethrough
        BOOL value;
        value = static_cast<BOOL>(caretAttributes->hasUnderline);
        ErrorCheck::ThrowIfFailedHR(newLayout->SetUnderline(
            value,
            range
            ));
        value = static_cast<BOOL>(caretAttributes->hasStrikethrough);
        ErrorCheck::ThrowIfFailedHR(newLayout->SetStrikethrough(
            value,
            range
            ));
    }
    else
    {
        //font family
        UINT32 fontFamilyNameLength;
        ErrorCheck::ThrowIfFailedHR(oldLayout->GetFontFamilyNameLength(
            startPosForOld,
            &fontFamilyNameLength
            ));
        fontFamilyNameLength++;
        assert(0 != fontFamilyNameLength);
        std::wstring fontFamilyName;
        fontFamilyName.resize(fontFamilyNameLength);
        ErrorCheck::ThrowIfFailedHR(oldLayout->GetFontFamilyName(
            startPosForOld,
            &fontFamilyName[0],
            fontFamilyNameLength
            ));
        ErrorCheck::ThrowIfFailedHR(newLayout->SetFontFamilyName(
            fontFamilyName.c_str(),
            range
            ));

        //WSS
        DWRITE_FONT_WEIGHT weight;
        DWRITE_FONT_STYLE style;
        DWRITE_FONT_STRETCH stretch;
        ErrorCheck::ThrowIfFailedHR(oldLayout->GetFontWeight(
            startPosForOld,
            &weight
            ));
        ErrorCheck::ThrowIfFailedHR(oldLayout->GetFontStyle(
            startPosForOld,
            &style
            ));
        ErrorCheck::ThrowIfFailedHR(oldLayout->GetFontStretch(
            startPosForOld,
            &stretch
            ));
        ErrorCheck::ThrowIfFailedHR(newLayout->SetFontWeight(
            weight,
            range
            ));
        ErrorCheck::ThrowIfFailedHR(newLayout->SetFontStyle(
            style,
            range
            ));
        ErrorCheck::ThrowIfFailedHR(newLayout->SetFontStretch(
            stretch,
            range
            ));

        //font size
        FLOAT fontSize;
        ErrorCheck::ThrowIfFailedHR(oldLayout->GetFontSize(
            startPosForOld,
            &fontSize
            ));
        ErrorCheck::ThrowIfFailedHR(newLayout->SetFontSize(
            fontSize,
            range
            ));

        //underline and strikethrough
        BOOL value;
        ErrorCheck::ThrowIfFailedHR(oldLayout->GetUnderline(
            startPosForOld,
            &value
            ));
        ErrorCheck::ThrowIfFailedHR(newLayout->SetUnderline(
            value,
            range
            ));
        ErrorCheck::ThrowIfFailedHR(oldLayout->GetStrikethrough(
            startPosForOld,
            &value
            ));
        ErrorCheck::ThrowIfFailedHR(newLayout->SetStrikethrough(
            value,
            range
            ));

        //locale
        UINT32 localeNameLength;
        ErrorCheck::ThrowIfFailedHR(oldLayout->GetLocaleNameLength(
            startPosForOld,
            &localeNameLength
            ));
        localeNameLength++;
        assert(0 != localeNameLength);
        std::wstring localeName;
        localeName.resize(localeNameLength);
        ErrorCheck::ThrowIfFailedHR(oldLayout->GetLocaleName(
            startPosForOld,
            &localeName[0],
            localeNameLength
            ));
        ErrorCheck::ThrowIfFailedHR(newLayout->SetLocaleName(
            localeName.c_str(),
            range
            ));
    }

    //drawing effect
    IUnknownPtr drawingEffect;
    ErrorCheck::ThrowIfFailedHR(oldLayout->GetDrawingEffect(
        startPosForOld,
        &drawingEffect
        ));
    ErrorCheck::ThrowIfFailedHR(newLayout->SetDrawingEffect(
        drawingEffect,
        range
        ));

    //inline object
    IDWriteInlineObjectPtr inlineObject;
    ErrorCheck::ThrowIfFailedHR(oldLayout->GetInlineObject(
        startPosForOld,
        &inlineObject
        ));
    ErrorCheck::ThrowIfFailedHR(newLayout->SetInlineObject(
        inlineObject,
        range
        ));

    //typography
    IDWriteTypographyPtr typography;
    ErrorCheck::ThrowIfFailedHR(oldLayout->GetTypography(
        startPosForOld,
        &typography
        ));
    ErrorCheck::ThrowIfFailedHR(newLayout->SetTypography(
        typography,
        range
        ));
}

HRESULT CEditableLayout::CreateEditableLayout(
    IDWriteFactory* factory,
    __in_ecount(stringLength) WCHAR const* string,
    UINT32 stringLength,
    IDWriteTextFormat* textFormat,
    FLOAT maxWidth,
    FLOAT maxHeight,
    __out IDWriteTextEditLayout** textLayout
    )
{
    try
    {
        IDWriteTextLayoutPtr innerTextLayout;
        ErrorCheck::ThrowIfFailedHR(factory->CreateTextLayout(
            string,
            stringLength,
            textFormat,
            maxWidth,
            maxHeight,
            &innerTextLayout
            ));

        IDWriteTextEditLayoutPtr textEditLayout = new CEditableLayout(
            innerTextLayout,
            factory,
            string
            );
        *textLayout = textEditLayout.Detach();
    }
    catch (Exception::ExceptionBase& e)
    {
        return e.GetHResult();
    }

    return S_OK;
}

UINT32 CalculateRangeLengthAt(
    IDWriteTextLayout* layout,
    UINT32 pos
    )
{
    //use the first getter to get the range to increment the current position
    DWRITE_TEXT_RANGE incrementAmount;
    DWRITE_FONT_WEIGHT weight;
    ErrorCheck::ThrowIfFailedHR(layout->GetFontWeight(
        pos,
        &weight,
        &incrementAmount
        ));
    //ensure that we are not going to be stuck in an infinite loop
    assert(incrementAmount.length > 0);

    UINT32 length = incrementAmount.length - (pos - incrementAmount.startPosition);
    return length;
}

void CEditableLayout::CopyRangedProperties(
    IDWriteTextLayout* oldLayout,
    UINT32 startPos,
    UINT32 endPosPlusOne,
    UINT32 newLayoutTextOffset,
    IDWriteTextLayout* newLayout,
    bool isOffsetNegative
    )
{
    UINT32 currentPos = startPos;
    while (currentPos < endPosPlusOne)
    {
        UINT32 rangeLength = CalculateRangeLengthAt(oldLayout, currentPos);
        rangeLength = std::min(rangeLength, endPosPlusOne-currentPos);
        if (isOffsetNegative)
        {
            CopyRangePropertiesHelper(
                oldLayout,
                currentPos,
                newLayout,
                currentPos - newLayoutTextOffset,
                rangeLength
                );
        }
        else
        {
            CopyRangePropertiesHelper(
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

STDMETHODIMP CEditableLayout::InsertTextAt(
    UINT32 position,
    __in_ecount(stringLength) WCHAR const* string,
    UINT32 stringLength,
    __maybenull CaretFormattingAttributes* caretAttributes
    )
{
    try
    {
        // The inserted string gets all the properties of the character right before position.
        // If there is no text right before position, use the properties of the character right after position.

        //copy all the old stuff
        IDWriteTextLayoutPtr oldInnerTextLayout = innerLayout_;
        UINT32 oldTextLength = static_cast<UINT32>(text_.length());
        position = std::min(position, static_cast<UINT32>(text_.size()));

        //release and create the new text layout
        innerLayout_.Release();
        text_.insert(position, string, stringLength);
        ErrorCheck::ThrowIfFailedHR(factory_->CreateTextLayout(
            text_.c_str(),
            static_cast<UINT32>(text_.length()),
            oldInnerTextLayout,
            oldInnerTextLayout->GetMaxWidth(),
            oldInnerTextLayout->GetMaxHeight(),
            &innerLayout_
            ));

        CopyNonRangeProperties(oldInnerTextLayout);

        //for each property, get the position range and apply it to the old text
        if (0 == position)
        {
            //inserted text
            CopyRangePropertiesHelper(
                oldInnerTextLayout,
                0,
                innerLayout_,
                0,
                stringLength
                );

            //the rest of the text
            CopyRangedProperties(
                oldInnerTextLayout,
                0,
                oldTextLength,
                stringLength,
                innerLayout_
                );
        }
        else
        {
            //1st block
            CopyRangedProperties(
                oldInnerTextLayout,
                0,
                position,
                0,
                innerLayout_
                );

            //inserted text
            CopyRangePropertiesHelper(
                oldInnerTextLayout,
                position - 1,
                innerLayout_,
                position,
                stringLength,
                caretAttributes
                );

            //last block (if it exists)
            CopyRangedProperties(
                oldInnerTextLayout,
                position,
                oldTextLength,
                stringLength,
                innerLayout_
                );
        }
        CopyRangePropertiesHelper(
            oldInnerTextLayout,
            oldTextLength,
            innerLayout_,
            static_cast<UINT32>(text_.length()),
            UINT32_MAX
            );
    }
    catch (Exception::ExceptionBase& e)
    {
        return e.GetHResult();
    }

    return S_OK;
}

STDMETHODIMP CEditableLayout::RemoveTextAt(
    UINT32 position,
    UINT32 numCharactersToRemove
    )
{
    try
    {
        //copy all the old stuff
        IDWriteTextLayoutPtr oldInnerTextLayout = innerLayout_;
        UINT32 oldTextLength = static_cast<UINT32>(text_.length());

        //release and create the new text layout
        innerLayout_.Release();
        text_.erase(position, numCharactersToRemove);
        ErrorCheck::ThrowIfFailedHR(factory_->CreateTextLayout(
            text_.c_str(),
            static_cast<UINT32>(text_.length()),
            oldInnerTextLayout,
            oldInnerTextLayout->GetMaxWidth(),
            oldInnerTextLayout->GetMaxHeight(),
            &innerLayout_
            ));

        CopyNonRangeProperties(oldInnerTextLayout);

        if (0 == position)
        {
            //the rest of the text
            CopyRangedProperties(
                oldInnerTextLayout,
                numCharactersToRemove,
                oldTextLength,
                numCharactersToRemove,
                innerLayout_,
                true
                );
        }
        else
        {
            //1st block
            CopyRangedProperties(
                oldInnerTextLayout,
                0,
                position,
                0,
                innerLayout_,
                true
                );

            //last block (if it exists, we increment past the deleted text)
            CopyRangedProperties(
                oldInnerTextLayout,
                position + numCharactersToRemove,
                oldTextLength,
                numCharactersToRemove,
                innerLayout_,
                true
                );
        }
        CopyRangePropertiesHelper(
            oldInnerTextLayout,
            oldTextLength,
            innerLayout_,
            static_cast<UINT32>(text_.length()),
            UINT32_MAX
            );
    }
    catch (Exception::ExceptionBase& e)
    {
        return e.GetHResult();
    }

    return S_OK;
}

STDMETHODIMP CEditableLayout::Clear()
{
    IDWriteTextLayoutPtr oldInnerTextLayout = innerLayout_;

    innerLayout_.Release();
    text_.resize(0);
    ErrorCheck::ThrowIfFailedHR(factory_->CreateTextLayout(
        text_.c_str(),
        static_cast<UINT32>(text_.length()),
        oldInnerTextLayout,
        oldInnerTextLayout->GetMaxWidth(),
        oldInnerTextLayout->GetMaxHeight(),
        &innerLayout_
        ));

    return S_OK;
}


void CEditableLayout::CopyNonRangeProperties(IDWriteTextLayout* oldLayout)
{
    ErrorCheck::ThrowIfFailedHR(innerLayout_->SetTextAlignment(oldLayout->GetTextAlignment()));
    ErrorCheck::ThrowIfFailedHR(innerLayout_->SetParagraphAlignment(oldLayout->GetParagraphAlignment()));
    ErrorCheck::ThrowIfFailedHR(innerLayout_->SetWordWrapping(oldLayout->GetWordWrapping()));
    ErrorCheck::ThrowIfFailedHR(innerLayout_->SetReadingDirection(oldLayout->GetReadingDirection()));
    ErrorCheck::ThrowIfFailedHR(innerLayout_->SetFlowDirection(oldLayout->GetFlowDirection()));
    ErrorCheck::ThrowIfFailedHR(innerLayout_->SetIncrementalTabStop(oldLayout->GetIncrementalTabStop()));

    DWRITE_TRIMMING trimmingOptions;
    IDWriteInlineObjectPtr inlineObject;
    ErrorCheck::ThrowIfFailedHR(oldLayout->GetTrimming(
        &trimmingOptions,
        &inlineObject
        ));
    ErrorCheck::ThrowIfFailedHR(innerLayout_->SetTrimming(
        &trimmingOptions,
        inlineObject
        ));

    DWRITE_LINE_SPACING_METHOD lineSpacingMethod;
    FLOAT lineSpacing;
    FLOAT baseline;
    ErrorCheck::ThrowIfFailedHR(oldLayout->GetLineSpacing(
        &lineSpacingMethod,
        &lineSpacing,
        &baseline
    ));
    ErrorCheck::ThrowIfFailedHR(innerLayout_->SetLineSpacing(
        lineSpacingMethod,
        lineSpacing,
        baseline
    ));
}

STDMETHODIMP CEditableLayout::CopyTextToClipboard(DWRITE_TEXT_RANGE textRange)
{
    try
    {
        std::auto_ptr<Clipboard> clipboard(Clipboard::Open(true));
        clipboard->CopyText(text_.substr(
            textRange.startPosition,
            textRange.length
            ));
    }
    catch (Exception::ExceptionBase& e)
    {
        return e.GetHResult();
    }

    return S_OK;
}

STDMETHODIMP CEditableLayout::CutTextToClipboard(DWRITE_TEXT_RANGE textRange)
{
    try
    {
        ErrorCheck::ThrowIfFailedHR(CopyTextToClipboard(textRange));
        ErrorCheck::ThrowIfFailedHR(RemoveTextAt(
            textRange.startPosition,
            textRange.length
            ));
    }
    catch (Exception::ExceptionBase& e)
    {
        return e.GetHResult();
    }

    return S_OK;
}

STDMETHODIMP CEditableLayout::PasteTextFromClipboard(
    UINT32 position,
    __out UINT32* numCharacters
    )
{
    try
    {
        std::auto_ptr<Clipboard> clipboard(Clipboard::Open(false));
        std::wstring string = clipboard->GetText();
        ErrorCheck::ThrowIfFailedHR(InsertTextAt(
            position,
            string.c_str(),
            static_cast<UINT32>(string.length())
            ));

        *numCharacters = static_cast<UINT32>(string.length());
    }
    catch (Exception::ExceptionBase& e)
    {
        return e.GetHResult();
    }

    return S_OK;
}

STDMETHODIMP_(wchar_t) CEditableLayout::GetCharacterAt(
    UINT32 position
    )
{
    if (position >= static_cast<UINT32>(text_.length()))
    {
        return 0;
    }

    return text_[position];
}


STDMETHODIMP_(const wchar_t*) CEditableLayout::GetText()
{
    return text_.c_str();
}


STDMETHODIMP_(UINT32) CEditableLayout::GetTextLength()
{
    return static_cast<UINT32>(text_.length());
}
