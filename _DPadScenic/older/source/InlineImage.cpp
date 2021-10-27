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

    float size = float(imageHeight);
    float offset = index * size;
    rect_.x = offset;
    rect_.y = 0;
    rect_.w = size;
    rect_.h = size;

    baseline_ = rect_.h;
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

    Position destRect = {originX, originY, rect_.w, rect_.h};
    renderTarget->DrawImage(image_, rect_, destRect);

    return S_OK;
}


HRESULT STDMETHODCALLTYPE InlineImage::GetMetrics(
    __out DWRITE_INLINE_OBJECT_METRICS* metrics
    )
{
    DWRITE_INLINE_OBJECT_METRICS inlineMetrics = {};
    inlineMetrics.width = rect_.w;
    inlineMetrics.height = rect_.h;
    inlineMetrics.baseline = baseline_;
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

        // locate the resource handle in our dll
        resourceHandle = FindResourceW(
            HINST_THISCOMPONENT,
            resourceName,
            resourceType
            );
        IZR(resourceHandle, E_FAIL);

        // load the resource
        resourceDataHandle = LoadResource(
            HINST_THISCOMPONENT,
            resourceHandle);
        IZR(resourceDataHandle, E_FAIL);

        // lock it to get a system memory pointer
        *fileData = (BYTE*)LockResource(resourceDataHandle);
        IZR(*fileData, E_FAIL);

        // calculate the size
        *fileSize = SizeofResource(HINST_THISCOMPONENT, resourceHandle);
        IZR(*fileSize, E_FAIL);

        return S_OK;
    }
}


HRESULT InlineImage::LoadImageFromResource(
    const wchar_t* resourceName,
    const wchar_t* resourceType,
    IWICImagingFactory* wicFactory,
    __out ComPtr<IWICBitmapSource>& bitmap
    )
{
    // Load an image into the given bitmap.

    __ecount(fileSize) UINT8* fileData;
    DWORD fileSize;
    IFR(LoadAndLockResource(resourceName, resourceType, &fileData, &fileSize));

    // create a WIC stream to map onto the memory
    ComPtr<IWICStream> stream;
    IFR(wicFactory->CreateStream(&stream));

    // initialize the stream with the memory pointer and size
    IFR(stream->InitializeFromMemory(reinterpret_cast<BYTE*>(fileData), fileSize));

    // create a decoder for the stream
    ComPtr<IWICBitmapDecoder> decoder;
    IFR(wicFactory->CreateDecoderFromStream(
            stream,
            NULL,
            WICDecodeMetadataCacheOnLoad,
            &decoder
            ));

    // create the initial frame
    ComPtr<IWICBitmapFrameDecode> source;
    IFR(decoder->GetFrame(0, &source));

    // format convert to 32bppPBGRA -- which D2D expects
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

    bitmap.Set(converter);

    return S_OK;
}
