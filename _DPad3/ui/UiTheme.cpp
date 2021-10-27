//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Visual style information.
//
//----------------------------------------------------------------------------
#include "precomp.h"


void UiTheme::AddImagePart(
    ThemePartId partId,
    const Position& rect
    )
{
    AddImageParts(partId, &rect, 1);
}


void UiTheme::AddImageParts(
    ThemePartId partId,
    __in_ecount(rectsCount) const Position* rects,
    size_t rectsCount
    )
{
    imagePartsMap_[partId] = static_cast<unsigned int>(imageParts_.size());
    imageParts_.insert(imageParts_.end(), rects, rects + rectsCount);
}


void UiTheme::AddImageParts(
    ThemePartId partId,
    __in_ecount(rectsCount) const SmallPosition* rects,
    size_t rectsCount
    )
{
    imagePartsMap_[partId] = static_cast<unsigned int>(imageParts_.size());
    for (size_t i = 0; i < rectsCount; ++i)
    {
        SmallPosition const& rect = rects[i];
        imageParts_.push_back(MakePosition(rect.x, rect.y, rect.w, rect.h));
    }
}


__ecount(partCount) __maybenull const Position* UiTheme::GetImageParts(
    ThemePartId partId,
    size_t partCount,
    FailureBehavior failureBehavior
    ) const
{
    ImagePartsMap::const_iterator match = imagePartsMap_.find(partId);

    if (match != imagePartsMap_.end())
    {
        size_t partIndex = match->second;
        if (partIndex + partCount <= imageParts_.size()
        &&  partIndex + partCount > partIndex)
        {
            return &imageParts_[partIndex];
        }
    }

    // Image part was not found.

    if (failureBehavior == FailureBehaviorError)
        throw std::exception("UI theme image parts were not found!" FAILURE_LOCATION);
    else
        return NULL;
}


const Position& UiTheme::GetImagePart(
    ThemePartId partId
    ) const
{
    const Position* partRect = GetImageParts(partId, 1, FailureBehaviorNull);

    // Unlike its multipart version above, if the rect is not found,
    // it returns a valid pointer but zero size rect. This avoids
    // lots of if checks in the calling code.
    if (partRect == NULL)
    {
        const static Position empty = {0,0,0,0};
        return empty;
    }
    return *partRect;
}


Position UiTheme::GetDeflatedImagePart(
    const Position& position,
    ThemePartId partId
    ) const
{
    const Position& margin = GetImagePart(partId);
    return MakePosition(
        position.x + margin.x,
        position.y + margin.y,
        std::max(position.w - margin.x - margin.w, 0.0f),
        std::max(position.h - margin.y - margin.h, 0.0f)
        );
}


Position UiTheme::GetInflatedImagePart(
    const Position& position,
    ThemePartId partId
    ) const
{
    const Position& margin = GetImagePart(partId);
    return MakePosition(
        position.x - margin.x,
        position.y - margin.y,
        std::max(position.w + margin.x + margin.w, 0.0f),
        std::max(position.h + margin.y + margin.h, 0.0f)
        );
}


Position UiTheme::GetMinImagePart(
    const Position& position,
    ThemePartId partId
    ) const
{
    const Position& defaultPosition = GetImagePart(partId);
    return MakePosition(
        position.x,
        position.y,
        std::min(position.w, defaultPosition.w),
        std::min(position.h, defaultPosition.h)
        );
}

Position UiTheme::GetMaxImagePart(
    const Position& position,
    ThemePartId partId
    ) const
{
    const Position& defaultPosition = GetImagePart(partId);
    return MakePosition(
        position.x,
        position.y,
        std::max(position.w, defaultPosition.w),
        std::max(position.h, defaultPosition.h)
        );
}


void UiTheme::AddTextFormat(
    ThemePartId formatId,
    IDWriteTextFormat* textFormat
    )
{
    TextFormatsMap::iterator match = textFormatsMap_.find(formatId);

    if (match == textFormatsMap_.end())
    {
        textFormatsMap_[formatId] = static_cast<unsigned int>(textFormats_.size());
        textFormats_.push_back(ComPtr<IDWriteTextFormat>(textFormat));
    }
    else
    {
        textFormats_[match->second].Set(textFormat);
    }
}


IDWriteTextFormat* UiTheme::GetTextFormat(
    ThemePartId formatId,
    FailureBehavior failureBehavior
    )
{
    TextFormatsMap::iterator match = textFormatsMap_.find(formatId);

    size_t formatIndex = 0; // default if specific part does not exist
    if (match != textFormatsMap_.end())
    {
        formatIndex = match->second;
        return textFormats_[formatIndex];
    }

    // Failed to find match. So what response does the caller want?

    if (failureBehavior == FailureBehaviorError)
        throw std::exception("UI theme text format was not found!" FAILURE_LOCATION);

    if (formatIndex >= textFormats_.size())
        throw std::exception("UI theme table is empty!");

    if (failureBehavior == FailureBehaviorNull)
        return NULL;

    // Return the default text format.
    return textFormats_[formatIndex];
}


void UiTheme::SetImage(
    IWICBitmapSource* image
    )
{
    // Changing the image should be accompanied by changing the part
    // coordinates too, unless the two images are the same, with maybe
    // just different colors.

    image_.Set(image);
}


namespace
{
    HRESULT LoadAndLockResource(
        const wchar_t* resourceName,
        const wchar_t* resourceType,
        __out UINT8** fileData,
        __out DWORD* fileSize
        )
    {
        HRSRC resourceHandle = NULL;
        HGLOBAL resourceDataHandle = NULL;
        *fileData = NULL;
        *fileSize = 0;

        // locate the resource handle in our dll
        resourceHandle = FindResourceW(
            HINST_THISCOMPONENT,
            resourceName,
            resourceType
            );
        RETURN_ON_ZERO(resourceHandle, E_FAIL);

        // load the resource
        resourceDataHandle = LoadResource(
            HINST_THISCOMPONENT,
            resourceHandle);
        RETURN_ON_ZERO(resourceDataHandle, E_FAIL);

        // lock it to get a system memory pointer
        *fileData = (BYTE*)LockResource(resourceDataHandle);
        RETURN_ON_ZERO(*fileData, E_FAIL);

        // calculate the size
        *fileSize = SizeofResource(HINST_THISCOMPONENT, resourceHandle);
        RETURN_ON_ZERO(*fileSize, E_FAIL);

        return S_OK;
    }
}


HRESULT UiTheme::LoadImageFromResource(
    const wchar_t* resourceName,
    const wchar_t* resourceType,
    IWICImagingFactory* wicFactory
    )
{
    // Load image into this theme's atlas image.
    return LoadImageFromResource(
            resourceName,
            resourceType,
            wicFactory,
            image_.Clear()
            );
}


HRESULT UiTheme::LoadImageFromResource(
    const wchar_t* resourceName,
    const wchar_t* resourceType,
    IWICImagingFactory* wicFactory,
    __out ComPtr<IWICBitmapSource>& bitmap
    )
{
    // Load an image into the given bitmap.

    __ecount(fileSize) UINT8* fileData;
    DWORD fileSize;
    RETURN_ON_FAIL(LoadAndLockResource(resourceName, resourceType, &fileData, &fileSize), hr);

    // create a WIC stream to map onto the memory
    ComPtr<IWICStream> stream;
    RETURN_ON_FAIL(wicFactory->CreateStream(&stream), hr);

    // initialize the stream with the memory pointer and size
    RETURN_ON_FAIL(stream->InitializeFromMemory(
            reinterpret_cast<BYTE*>(fileData),
            fileSize
            ), hr);

    // create a decoder for the stream
    ComPtr<IWICBitmapDecoder> decoder;
    RETURN_ON_FAIL(wicFactory->CreateDecoderFromStream(
            stream,
            NULL,
            WICDecodeMetadataCacheOnLoad,
            &decoder
            ), hr);

    // create the initial frame
    ComPtr<IWICBitmapFrameDecode> source;
    RETURN_ON_FAIL(decoder->GetFrame(0, &source), hr);

    // format convert to 32bppPBGRA -- which D2D expects
    ComPtr<IWICFormatConverter> converter;
    RETURN_ON_FAIL(wicFactory->CreateFormatConverter(&converter), hr);

    RETURN_ON_FAIL(converter->Initialize(
        source,
        GUID_WICPixelFormat32bppPBGRA,
        WICBitmapDitherTypeNone,
        NULL,
        0.f,
        WICBitmapPaletteTypeMedianCut
        ), hr);

    bitmap.Set(converter);

    return S_OK;
}


HRESULT UiTheme::LoadImagePartsFromResource(
    const wchar_t* resourceName,
    const wchar_t* resourceType
    )
{
    __ecount(fileSize) UINT8* fileData;
    DWORD fileSize;
    RETURN_ON_FAIL(LoadAndLockResource(resourceName, resourceType, &fileData, &fileSize), hr);

    // Following is a series of uniquely identified positions
    // in the resource. Each part consists of an ID, number of following
    // positions, and the position information.

    const UINT8* const fileDataEnd = fileData + fileSize;
    while (fileData < fileDataEnd)
    {
        // Read next part...
        PartIdCount const& part = *reinterpret_cast<PartIdCount const*>(fileData);
        fileData += sizeof(PartIdCount);
        if (fileData >= fileDataEnd)
            break;

        // Read the parts position list...
        __ecount(part.count) SmallPosition const* rects = reinterpret_cast<SmallPosition const*>(fileData);
        fileData += part.count * sizeof(SmallPosition);
        if (fileData > fileDataEnd)
            break;

        AddImageParts(part.id, rects, part.count);
    }

    return S_OK;
}


HRESULT UiTheme::LoadTextFormatsFromResource(
    const wchar_t* resourceName,
    const wchar_t* resourceType,
    IDWriteFactory* dwriteFactory,
    DWRITE_READING_DIRECTION readingDirection,
    wchar_t const* locale
    )
{
    __ecount(fileSize) UINT8* fileData;
    DWORD fileSize;
    RETURN_ON_FAIL(LoadAndLockResource(resourceName, resourceType, &fileData, &fileSize), hr);

    // Following is a series of uniquely identified contiguous text formats
    // in the resource. Each format consists of an ID, various attributes
    // like size and weight, and a font family name.

    const UINT8* const fileDataEnd = fileData + fileSize;
    while (fileData < fileDataEnd)
    {
        // Read next text format's info and font family name.
        TextFormatInfo const& info = *reinterpret_cast<TextFormatInfo const*>(fileData);
        const wchar_t* fontFamilyName = info.fontFamilyName;
        fileData += sizeof(TextFormatInfo) + sizeof(fontFamilyName[0]) * wcslen(fontFamilyName);
        if (fileData > fileDataEnd)
            break;

        // Create text format, given info.
        ComPtr<IDWriteTextFormat> textFormat;
        RETURN_ON_FAIL(
            dwriteFactory->CreateTextFormat(
                fontFamilyName,
                NULL,
                info.weight,
                info.slope,
                info.stretch,
                info.size,
                locale,
                &textFormat
                ), hr);

        textFormat->SetTextAlignment(info.textAlignment);
        textFormat->SetParagraphAlignment(info.paragraphAlignment);
        textFormat->SetReadingDirection(readingDirection);
        textFormat->SetWordWrapping(info.lineWrapping);

        AddTextFormat(info.id, textFormat);
    }

    return S_OK;
}


void UiTheme::CreateTextLayout(
    IDWriteFactory* dwriteFactory,
    __in_z_opt const wchar_t* text,
    ThemePartId formatId,
    const Position& rect,
    __out ComPtr<IDWriteTextLayout>& textLayout
    )
{
    // Substitute null for zero-width space. This makes it possible
    // to set inline objects onto the text while conveniently passing
    // null to constructors..
    if (text == NULL)
        text = L"\x200B";

    // Use the given part, or fallbackto the default.
    IDWriteTextFormat* textFormat = GetTextFormat(formatId, FailureBehaviorNull);
    if (textFormat == NULL)
        textFormat = GetTextFormat(ThemePartIdDefault);
    if (textFormat == NULL)
        throw std::exception("No TextFormats exist in the current UI theme!" FAILURE_LOCATION);

    // Create the layout based on the format.
    HRESULT hr =
        dwriteFactory->CreateGdiCompatibleTextLayout(
            text,
            static_cast<UINT32>(wcslen(text)),
            textFormat,
            std::max(rect.w, 0.f), // don't want layout creation to fail just
            std::max(rect.h, 0.f), // because the control was sized too small
            1, // use 1:1 pixels per DIP ratio
            NULL, // no transform
            false, // want measuring method compatible for crisp UI text
            &textLayout.Clear()
            );
    if (FAILED(hr))
        throw OsException("Could not create the TextLayout for the UI!" FAILURE_LOCATION, hr);

    // Apply the color to the whole range.
    ComPtr<DrawingEffect> drawingEffect(new DrawingEffect(0xFF000000));
    DWRITE_TEXT_RANGE drawingEffectRange = {0, UINT_MAX};
    textLayout->SetDrawingEffect(drawingEffect, drawingEffectRange);
}


void UiTheme::ApplyImageOverText(
    __maybenull InlineImage* image,
    __in_z_opt const wchar_t* text,
    __notnull IDWriteTextLayout* textLayout
    )
{
    if (textLayout == NULL)
        throw std::exception("The TextLayout passed was NULL!" FAILURE_LOCATION);

    if (image == NULL)
        return; // no point in setting nothing

    UINT32 textPosition = 0;

    if (text != NULL)
    {
        // Inline object's require text to anchor onto, so search
        // for the Unicode object replacement character (U+FFFC).

        size_t textLength = wcslen(text);
        const wchar_t* textBegin = text;
        const wchar_t* textEnd   = text + textLength;
        const wchar_t* match     = std::find(textBegin, textEnd, L'\xFFFC');
        if (match == textEnd)
            return; // string didn't include a place to put the sign

        textPosition = UINT32(match - textBegin);
    }

    // Set the inline object in place of the character.
    image->CenterBaselineIfNeeded(textLayout, textPosition);

    DWRITE_TEXT_RANGE inlineObjectRange = {textPosition, 1};
    textLayout->SetInlineObject(image, inlineObjectRange);
}
