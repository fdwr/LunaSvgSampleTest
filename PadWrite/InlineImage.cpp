//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Inline image for text layouts.
//
//----------------------------------------------------------------------------
#include "precomp.h"


InlineImage::InlineImage(
    IWICBitmapSource* image,
    unsigned int index
    )
    :   image_(image)
{
    // Pass the index of the image in the sequence of concatenated sequence
    // (just like toolbar images).
    UINT imageWidth = 0, imageHeight = 0;

    if (image != NULL)
        image->GetSize(&imageWidth, &imageHeight);

    if (index == ~0)
    {
        // No index. Use entire image.
        rect_.left      = 0;
        rect_.top       = 0;
        rect_.right     = float(imageWidth);
        rect_.bottom    = float(imageHeight);
    }
    else
    {
        // Use index.
        float size = float(imageHeight);
        float offset    = index * size;
        rect_.left      = offset;
        rect_.top       = 0;
        rect_.right     = offset + size;
        rect_.bottom    = size;
    }

    baseline_ = float(imageHeight);
}


HRESULT STDMETHODCALLTYPE InlineImage::Draw(
    __maybenull void* clientDrawingContext,
    IDWriteTextRenderer* renderer,
    FLOAT originX,
    FLOAT originY,
    BOOL isSideways,
    BOOL isRightToLeft,
    IUnknown* clientDrawingEffect
    )
{
    // Go from the text renderer interface back to the actual render target.
    ComPtr<RenderTarget> renderTarget;
    renderer->QueryInterface(__uuidof(RenderTarget), reinterpret_cast<void**>(&renderTarget));

    float height    = rect_.bottom - rect_.top;
    float width     = rect_.right  - rect_.left;
    RectF destRect  = {originX, originY, originX + width, originY + height};

    renderTarget->DrawImage(image_, rect_, destRect);

    return S_OK;
}


HRESULT STDMETHODCALLTYPE InlineImage::GetMetrics(
    __out DWRITE_INLINE_OBJECT_METRICS* metrics
    )
{
    DWRITE_INLINE_OBJECT_METRICS inlineMetrics = {};
    inlineMetrics.width     = rect_.right  - rect_.left;
    inlineMetrics.height    = rect_.bottom - rect_.top;
    inlineMetrics.baseline  = baseline_;
    *metrics = inlineMetrics;
    return S_OK;
}


HRESULT STDMETHODCALLTYPE InlineImage::GetOverhangMetrics(
    __out DWRITE_OVERHANG_METRICS* overhangs
    )
{
    overhangs->left      = 0;
    overhangs->top       = 0;
    overhangs->right     = 0;
    overhangs->bottom    = 0;
    return S_OK;
}


HRESULT STDMETHODCALLTYPE InlineImage::GetBreakConditions(
    __out DWRITE_BREAK_CONDITION* breakConditionBefore,
    __out DWRITE_BREAK_CONDITION* breakConditionAfter
    )
{
    *breakConditionBefore = DWRITE_BREAK_CONDITION_NEUTRAL;
    *breakConditionAfter  = DWRITE_BREAK_CONDITION_NEUTRAL;
    return S_OK;
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

        // Locate the resource handle in our DLL.
        resourceHandle = FindResourceW(
            HINST_THISCOMPONENT,
            resourceName,
            resourceType
            );
        IZR(resourceHandle, E_FAIL);

        // Load the resource.
        resourceDataHandle = LoadResource(
            HINST_THISCOMPONENT,
            resourceHandle);
        IZR(resourceDataHandle, E_FAIL);

        // Lock it to get a system memory pointer.
        *fileData = (BYTE*)LockResource(resourceDataHandle);
        IZR(*fileData, E_FAIL);

        // Calculate the size.
        *fileSize = SizeofResource(HINST_THISCOMPONENT, resourceHandle);
        IZR(*fileSize, E_FAIL);

        return S_OK;
    }
}


HRESULT InlineImage::LoadImageFromResource(
    const wchar_t* resourceName,
    const wchar_t* resourceType,
    IWICImagingFactory* wicFactory,
    __out IWICBitmapSource** bitmap
    )
{
    // Loads an image from a resource into the given bitmap.

    DWORD fileSize;
    __ecount(fileSize) UINT8* fileData;
    IFR(LoadAndLockResource(resourceName, resourceType, &fileData, &fileSize));

    // Create a WIC stream to map onto the memory.
    ComPtr<IWICStream> stream;
    IFR(wicFactory->CreateStream(&stream));

    // Initialize the stream with the memory pointer and size.
    IFR(stream->InitializeFromMemory(reinterpret_cast<BYTE*>(fileData), fileSize));

    // Create a decoder for the stream.
    ComPtr<IWICBitmapDecoder> decoder;
    IFR(wicFactory->CreateDecoderFromStream(
            stream,
            NULL,
            WICDecodeMetadataCacheOnLoad,
            &decoder
            ));

    // Create the initial frame.
    ComPtr<IWICBitmapFrameDecode> source;
    IFR(decoder->GetFrame(0, &source));

    // Convert format to 32bppPBGRA - which D2D expects.
    ComPtr<IWICFormatConverter> converter;
    IFR(wicFactory->CreateFormatConverter(&converter));

    IFR(converter->Initialize(
        source,
        GUID_WICPixelFormat32bppPBGRA,
        WICBitmapDitherTypeNone,
        NULL,
        0.f,
        WICBitmapPaletteTypeMedianCut
        ));

    *bitmap = converter.Detach();

    return S_OK;
}


HRESULT InlineImage::LoadImageFromFile(
    const wchar_t* fileName,
    IWICImagingFactory* wicFactory,
    __out IWICBitmapSource** bitmap
    )
{
    // Loads an image from a file into the given bitmap.

    // create a decoder for the stream
    ComPtr<IWICBitmapDecoder> decoder;
    IFR(wicFactory->CreateDecoderFromFilename(
            fileName,
            NULL,
            GENERIC_READ,
            WICDecodeMetadataCacheOnLoad,
            &decoder
            ));

    // Create the initial frame.
    ComPtr<IWICBitmapFrameDecode> source;
    IFR(decoder->GetFrame(0, &source));

    // Convert format to 32bppPBGRA - which D2D expects.
    ComPtr<IWICFormatConverter> converter;
    IFR(wicFactory->CreateFormatConverter(&converter));

    IFR(converter->Initialize(
        source,
        GUID_WICPixelFormat32bppPBGRA,
        WICBitmapDitherTypeNone,
        NULL,
        0.f,
        WICBitmapPaletteTypeMedianCut
        ));

    *bitmap = converter.Detach();

    return S_OK;
}
