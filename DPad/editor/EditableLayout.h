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

#pragma once


// Helper to construct text ranges when calling setters.
//
// Example: textLayout_->SetFontWeight(DWRITE_FONT_WEIGHT_BOLD, MakeDWriteTextRange(20, 10));

struct MakeDWriteTextRange : public DWRITE_TEXT_RANGE
{
    inline MakeDWriteTextRange(UINT32 startPosition, UINT32 length)
    {
        this->startPosition = startPosition;
        this->length = length;
    }

    // Overload to extend to end of text.
    inline MakeDWriteTextRange(UINT32 startPosition)
    {
        this->startPosition = startPosition;
        this->length = UINT32_MAX - startPosition;
    }
};


namespace DWritePad { namespace Implementation { 

    //implementing the CEditableLayout via containment
    class CEditableLayout : public COMHelpers::CNanoComObjectRoot<IDWriteTextEditLayout, COMHelpers::CNanoComObjectRoot<IDWriteTextLayout, 
                                        COMHelpers::CNanoComObjectRoot<IDWriteTextFormat> > >
    {
    private:
        IDWriteTextLayoutPtr innerLayout_;
        IDWriteTextFormatPtr textFormat_;
        IDWriteFactoryPtr factory_;
        std::wstring text_;

    private:
        void CopyNonRangeProperties(IDWriteTextLayout* oldLayout);
        void CopyRangedProperties(
            IDWriteTextLayout* oldLayout,
            UINT32 startPos,
            UINT32 endPosPlusOne,
            UINT32 newLayoutTextOffset,
            IDWriteTextLayout* newLayout,
            bool isOffsetNegative = false
            );

    public:
        CEditableLayout(IDWriteTextLayout* textEditLayout, IDWriteFactory* factory, std::wstring text)
        {
            assert(textEditLayout != NULL);
            innerLayout_ = textEditLayout;
            factory_ = factory;
            text_ = text;
            ErrorCheck::ThrowIfFailedHR(innerLayout_->QueryInterface(
                __uuidof(IDWriteTextFormat),
                reinterpret_cast<void**>(&textFormat_)
                ));
        }

        static HRESULT CreateEditableLayout(
            IDWriteFactory* factory,
            __in_ecount(stringLength) WCHAR const* string,
            UINT32 stringLength,
            IDWriteTextFormat* textFormat,
            FLOAT maxWidth,
            FLOAT maxHeight,
            __out IDWriteTextEditLayout** textLayout
            );

    public:
        /* the wrappers for the IDWriteTextFromat functions*/
        STDMETHOD(SetTextAlignment)(
            DWRITE_TEXT_ALIGNMENT textAlignment
            )
        {
            return innerLayout_->SetTextAlignment(
                textAlignment
                );
        }

        STDMETHOD(SetParagraphAlignment)(
            DWRITE_PARAGRAPH_ALIGNMENT paragraphAlignment
            )
        {
            return innerLayout_->SetParagraphAlignment(
                paragraphAlignment
                );
        }

        STDMETHOD(SetWordWrapping)(
            DWRITE_WORD_WRAPPING wordWrapping
            )
        {
            return innerLayout_->SetWordWrapping(
                wordWrapping
                );
        }

        STDMETHOD(SetReadingDirection)(
            DWRITE_READING_DIRECTION readingDirection
            )
        {
            return innerLayout_->SetReadingDirection(
                readingDirection
                );
        }

        STDMETHOD(SetFlowDirection)(
            DWRITE_FLOW_DIRECTION flowDirection
            )
        {
            return innerLayout_->SetFlowDirection(
                flowDirection
                );
        }

        STDMETHOD(SetIncrementalTabStop)(
            FLOAT incrementalTabStop
            )
        {
            return innerLayout_->SetIncrementalTabStop(
                incrementalTabStop
                );
        }

        STDMETHOD(SetTrimming)(
            __in DWRITE_TRIMMING const* trimmingOptions,
            IDWriteInlineObject* trimmingSign
            )
        {
            return innerLayout_->SetTrimming(
                trimmingOptions,
                trimmingSign
                );
        }

        STDMETHOD(SetLineSpacing)(
            DWRITE_LINE_SPACING_METHOD lineSpacingMethod,
            FLOAT lineSpacing,
            FLOAT baseline
            )
        {
            return innerLayout_->SetLineSpacing(
                lineSpacingMethod,
                lineSpacing,
                baseline
                );
        }

        STDMETHOD_(DWRITE_TEXT_ALIGNMENT, GetTextAlignment)()
        {
            return innerLayout_->GetTextAlignment();
        }

        STDMETHOD_(DWRITE_PARAGRAPH_ALIGNMENT, GetParagraphAlignment)()
        {
            return innerLayout_->GetParagraphAlignment();
        }

        STDMETHOD_(DWRITE_WORD_WRAPPING, GetWordWrapping)()
        {
            return innerLayout_->GetWordWrapping();
        }

        STDMETHOD_(DWRITE_READING_DIRECTION, GetReadingDirection)()
        {
            return innerLayout_->GetReadingDirection();
        }

        STDMETHOD_(DWRITE_FLOW_DIRECTION, GetFlowDirection)()
        {
            return innerLayout_->GetFlowDirection();
        }

        STDMETHOD_(FLOAT, GetIncrementalTabStop)()
        {
            return innerLayout_->GetIncrementalTabStop();
        }

        STDMETHOD(GetTrimming)(
            __out DWRITE_TRIMMING* trimmingOptions,
            __out IDWriteInlineObject** trimmingSign
            )
        {
            return innerLayout_->GetTrimming(
                trimmingOptions,
                trimmingSign
                );
        }

        STDMETHOD(GetLineSpacing)(
            __out DWRITE_LINE_SPACING_METHOD* lineSpacingMethod,
            __out FLOAT* lineSpacing,
            __out FLOAT* baseline
            )
        {
            return innerLayout_->GetLineSpacing(
                lineSpacingMethod,
                lineSpacing,
                baseline
                );
        }

        STDMETHOD(GetFontCollection)(
            __out IDWriteFontCollection** fontCollection
            )
        {
            return static_cast<IDWriteTextFormat*>(innerLayout_)->GetFontCollection(fontCollection);
        }

        STDMETHOD_(UINT32, GetFontFamilyNameLength)()
        {
            return static_cast<IDWriteTextFormat*>(innerLayout_)->GetFontFamilyNameLength();
        }

        STDMETHOD(GetFontFamilyName)(
            __out_ecount_z(nameSize) WCHAR* fontFamilyName,
            UINT32 nameSize
            )
        {
            return static_cast<IDWriteTextFormat*>(innerLayout_)->GetFontFamilyName(
                fontFamilyName,
                nameSize
                );
        }

        STDMETHOD_(DWRITE_FONT_WEIGHT, GetFontWeight)()
        {
            return static_cast<IDWriteTextFormat*>(innerLayout_)->GetFontWeight();
        }

        STDMETHOD_(DWRITE_FONT_STYLE, GetFontStyle)()
        {
            return static_cast<IDWriteTextFormat*>(innerLayout_)->GetFontStyle();
        }

        STDMETHOD_(DWRITE_FONT_STRETCH, GetFontStretch)()
        {
            return static_cast<IDWriteTextFormat*>(innerLayout_)->GetFontStretch();
        }

        STDMETHOD_(FLOAT, GetFontSize)()
        {
            return static_cast<IDWriteTextFormat*>(innerLayout_)->GetFontSize();
        }

        STDMETHOD_(UINT32, GetLocaleNameLength)()
        {
            return static_cast<IDWriteTextFormat*>(innerLayout_)->GetLocaleNameLength();
        }

        STDMETHOD(GetLocaleName)(
            __out_ecount_z(nameSize) WCHAR* localeName,
            UINT32 nameSize
            )
        {
            return static_cast<IDWriteTextFormat*>(innerLayout_)->GetLocaleName(
                localeName,
                nameSize
                );
        }

    public:
        /* the wrappers for the IDWriteTextLayout functions*/
        STDMETHOD(SetMaxWidth)(
            FLOAT maxWidth
            )
        {
            return innerLayout_->SetMaxWidth(maxWidth);
        }

        STDMETHOD(SetMaxHeight)(
            FLOAT maxHeight
            )
        {
            return innerLayout_->SetMaxHeight(maxHeight);
        }

        STDMETHOD(SetFontCollection)(
            IDWriteFontCollection* fontCollection,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetFontCollection(
                fontCollection,
                textRange
                );
        }

        STDMETHOD(SetFontFamilyName)(
            __in_z WCHAR const* fontFamilyName,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetFontFamilyName(
                fontFamilyName,
                textRange
                );
        }

        STDMETHOD(SetFontWeight)(
            DWRITE_FONT_WEIGHT fontWeight,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetFontWeight(
                fontWeight,
                textRange
                );
        }

        STDMETHOD(SetFontStyle)(
            DWRITE_FONT_STYLE fontStyle,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetFontStyle(
                fontStyle,
                textRange
                );
        }

        STDMETHOD(SetFontStretch)(
            DWRITE_FONT_STRETCH fontStretch,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetFontStretch(
                fontStretch,
                textRange
                );
        }

        STDMETHOD(SetFontSize)(
            FLOAT fontSize,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetFontSize(
                fontSize,
                textRange
                );
        }

        STDMETHOD(SetUnderline)(
            BOOL hasUnderline,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetUnderline(
                hasUnderline,
                textRange
                );
        }

        STDMETHOD(SetStrikethrough)(
            BOOL hasStrikethrough,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetStrikethrough(
                hasStrikethrough,
                textRange
                );
        }

        STDMETHOD(SetDrawingEffect)(
            IUnknown* drawingEffect,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetDrawingEffect(
                drawingEffect,
                textRange
                );
        }

        STDMETHOD(SetInlineObject)(
            IDWriteInlineObject* inlineObject,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetInlineObject(
                inlineObject,
                textRange
                );
        }

        STDMETHOD(SetTypography)(
            IDWriteTypography* typography,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetTypography(
                typography,
                textRange
                );
        }

        STDMETHOD(SetLocaleName)(
            __in_z WCHAR const* localeName,
            DWRITE_TEXT_RANGE textRange
            )
        {
            return innerLayout_->SetLocaleName(
                localeName,
                textRange
                );
        }

        STDMETHOD_(FLOAT, GetMaxWidth)()
        {
            return innerLayout_->GetMaxWidth();
        }

        STDMETHOD_(FLOAT, GetMaxHeight)()
        {
            return innerLayout_->GetMaxHeight();
        }

        STDMETHOD(GetFontCollection)(
            UINT32 currentPosition,
            __out IDWriteFontCollection** fontCollection,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetFontCollection(
                currentPosition,
                fontCollection,
                textRange
                );
        }

        STDMETHOD(GetFontFamilyNameLength)(
            UINT32 currentPosition,
            __out UINT32* nameLength,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetFontFamilyNameLength(
                currentPosition,
                nameLength,
                textRange
                );
        }

        STDMETHOD(GetFontFamilyName)(
            UINT32 currentPosition,
            __out_ecount_z(nameSize) WCHAR* fontFamilyName,
            UINT32 nameSize,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetFontFamilyName(
                currentPosition,
                fontFamilyName,
                nameSize,
                textRange
                );
        }

        STDMETHOD(GetFontWeight)(
            UINT32 currentPosition,
            __out DWRITE_FONT_WEIGHT* fontWeight,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetFontWeight(
                currentPosition,
                fontWeight,
                textRange
                );
        }

        STDMETHOD(GetFontStyle)(
            UINT32 currentPosition,
            __out DWRITE_FONT_STYLE* fontStyle,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetFontStyle(
                currentPosition,
                fontStyle,
                textRange
                );
        }

        STDMETHOD(GetFontStretch)(
            UINT32 currentPosition,
            __out DWRITE_FONT_STRETCH* fontStretch,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetFontStretch(
                currentPosition,
                fontStretch,
                textRange
                );
        }

        STDMETHOD(GetFontSize)(
            UINT32 currentPosition,
            __out FLOAT* fontSize,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetFontSize(
                currentPosition,
                fontSize,
                textRange
                );
        }

        STDMETHOD(GetUnderline)(
            UINT32 currentPosition,
            __out BOOL* hasUnderline,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetUnderline(
                currentPosition,
                hasUnderline,
                textRange
                );
        }

        STDMETHOD(GetStrikethrough)(
            UINT32 currentPosition,
            __out BOOL* hasStrikethrough,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetStrikethrough(
                currentPosition,
                hasStrikethrough,
                textRange
                );
        }

        STDMETHOD(GetDrawingEffect)(
            UINT32 currentPosition,
            __out IUnknown** drawingEffect,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetDrawingEffect(
                currentPosition,
                drawingEffect,
                textRange
                );
        }

        STDMETHOD(GetInlineObject)(
            UINT32 currentPosition,
            __out IDWriteInlineObject** inlineObject,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetInlineObject(
                currentPosition,
                inlineObject,
                textRange
                );
        }

        STDMETHOD(GetTypography)(
            UINT32 currentPosition,
            __out IDWriteTypography** typography,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetTypography(
                currentPosition,
                typography,
                textRange
                );
        }

        STDMETHOD(GetLocaleNameLength)(
            UINT32 currentPosition,
            __out UINT32* nameLength,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetLocaleNameLength(
                currentPosition,
                nameLength,
                textRange
                );
        }

        STDMETHOD(GetLocaleName)(
            UINT32 currentPosition,
            __out_ecount_z(nameSize) WCHAR* localeName,
            UINT32 nameSize,
            __out_opt DWRITE_TEXT_RANGE* textRange = NULL
            )
        {
            return innerLayout_->GetLocaleName(
                currentPosition,
                localeName,
                nameSize,
                textRange
                );
        }

        STDMETHOD(Draw)(
            __maybenull void* clientDrawingContext,
            IDWriteTextRenderer* renderer,
            FLOAT originX,
            FLOAT originY
            )
        {
            return innerLayout_->Draw(
                clientDrawingContext,
                renderer,
                originX,
                originY
                );
        }

        STDMETHOD(GetLineMetrics)(
            __out_ecount_opt(maxLineCount) DWRITE_LINE_METRICS* lineMetrics,
            UINT32 maxLineCount,
            __out UINT32* actualLineCount
            )
        {
            return innerLayout_->GetLineMetrics(
                lineMetrics,
                maxLineCount,
                actualLineCount
                );
        }

        STDMETHOD(GetMetrics)(
            __out DWRITE_TEXT_METRICS* textMetrics
            )
        {
            return innerLayout_->GetMetrics(
                textMetrics
                );
        }

        STDMETHOD(GetOverhangMetrics)(
            __out DWRITE_OVERHANG_METRICS* overhangs
            )
        {
            return innerLayout_->GetOverhangMetrics(
                overhangs
                );
        }

        STDMETHOD(GetClusterMetrics)(
            __out_ecount_opt(maxClusterCount) DWRITE_CLUSTER_METRICS* clusterMetrics,
            UINT32 maxClusterCount,
            __out UINT32* actualClusterCount
            )
        {
            return innerLayout_->GetClusterMetrics(
                clusterMetrics,
                maxClusterCount,
                actualClusterCount
                );
        }

        STDMETHOD(DetermineMinWidth)(
            __out FLOAT* minWidth
            )
        {
            return innerLayout_->DetermineMinWidth(
                minWidth
                );
        }

        STDMETHOD(HitTestPoint)(
            FLOAT pointX,
            FLOAT pointY,
            __out BOOL* isTrailingHit,
            __out BOOL* isInside,
            __out DWRITE_HIT_TEST_METRICS* hitTestMetrics
            )
        {
            return innerLayout_->HitTestPoint(
                pointX,
                pointY,
                isTrailingHit,
                isInside,
                hitTestMetrics
                );
        }

        STDMETHOD(HitTestTextPosition)(
            UINT32 textPosition,
            BOOL isTrailingHit,
            __out FLOAT* pointX,
            __out FLOAT* pointY,
            __out DWRITE_HIT_TEST_METRICS* hitTestMetrics
            )
        {
            return innerLayout_->HitTestTextPosition(
                textPosition,
                isTrailingHit,
                pointX,
                pointY,
                hitTestMetrics
                );
        }

        STDMETHOD(HitTestTextRange)(
            UINT32 textPosition,
            UINT32 textLength,
            FLOAT originX,
            FLOAT originY,
            __out_ecount_opt(maxHitTestMetricsCount) DWRITE_HIT_TEST_METRICS* hitTestMetrics,
            UINT32 maxHitTestMetricsCount,
            __out UINT32* actualHitTestMetricsCount
            )
        {
            return innerLayout_->HitTestTextRange(
                textPosition,
                textLength,
                originX,
                originY,
                hitTestMetrics,
                maxHitTestMetricsCount,
                actualHitTestMetricsCount
                );
        }

     public:
        /* the insertion, removal, and clipboard functions */
        STDMETHOD(InsertTextAt)(
            UINT32 position,
            __in_ecount(stringLength) WCHAR const* string,
            UINT32 stringLength,
            __maybenull CaretFormattingAttributes* caretAttributes = NULL
            );

        STDMETHOD(RemoveTextAt)(
            UINT32 position,
            UINT32 numCharactersToRemove
            );

        STDMETHOD(Clear)();

        STDMETHOD(CopyTextToClipboard)(
            DWRITE_TEXT_RANGE textRange
            );

        STDMETHOD(CutTextToClipboard)(
            DWRITE_TEXT_RANGE textRange
            );

        STDMETHOD(PasteTextFromClipboard)(
            UINT32 position,
            __out UINT32* numCharacters
            );

        STDMETHOD_(const wchar_t*, GetText)();

        STDMETHOD_(UINT32, GetTextLength)();

        STDMETHOD_(wchar_t, GetCharacterAt)(
            UINT32 position
            );
    };

} }