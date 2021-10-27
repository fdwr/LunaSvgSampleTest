//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Extended TextLayout definitions.
//
//----------------------------------------------------------------------------

#pragma once

struct CaretFormattingAttributes
{
    std::wstring fontFamilyName;
    std::wstring localeName;
    FLOAT fontSize;
    DWRITE_FONT_WEIGHT fontWeight;
    DWRITE_FONT_STRETCH fontStretch;
    DWRITE_FONT_STYLE fontStyle;
    BOOL hasUnderline;
    BOOL hasStrikethrough;
};

interface DWRITE_DECLARE_INTERFACE("3C5138C7-7428-4155-94EC-F310F3ECDE9E") IDWriteTextEditLayout : public IDWriteTextLayout
{
    /// <summary>
    /// Inserts a given string in the text layout's stored string at a certain text postion;
    /// </summary>
    /// <param name="string">The string to insert.</param>
    /// <param name="stringLength">The length of the string.</param>
    /// <param name="position">The position in the layout's curret string to insert the given string at.</param>
    /// <returns>
    /// Standard HRESULT error code.
    /// </returns>
    STDMETHOD(InsertTextAt)(
        UINT32 position,
        __in_ecount(stringLength) WCHAR const* string,
        UINT32 stringLength,
        __maybenull CaretFormattingAttributes* caretAttributes = NULL
        ) PURE;

    /// <summary>
    /// Deletes a specified amount characters from the layout's stored string.
    /// </summary>
    /// <param name="position">The position in the layout's curret string to start deleteing characters from.</param>
    /// <param name="numCharactersToRemove">The number of characters to delete.</param>
    /// <returns>
    /// Standard HRESULT error code.
    /// </returns>
    STDMETHOD(RemoveTextAt)(
        UINT32 position,
        UINT32 numCharactersToRemove
        ) PURE;

    STDMETHOD(Clear)() PURE;

    STDMETHOD(CopyTextToClipboard)(
        DWRITE_TEXT_RANGE textRange
        ) PURE;

    STDMETHOD(CutTextToClipboard)(
        DWRITE_TEXT_RANGE textRange
        ) PURE;

    STDMETHOD(PasteTextFromClipboard)(
        UINT32 position,
        __out UINT32* numCharacters
        ) PURE;

    STDMETHOD_(const wchar_t*, GetText)(
        ) PURE;

    STDMETHOD_(UINT32, GetTextLength)(
        ) PURE;

    STDMETHOD_(wchar_t, GetCharacterAt)(
        UINT32 position
        ) PURE;
};
