//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Adapter render target that allows drawing using D2D,
//              DirectWrite, or GDI+.
//
//----------------------------------------------------------------------------
#include "precomp.h"


RenderTargetD2D::RenderTargetD2D(ID2D1Factory* d2dFactory, IDWriteFactory* dwriteFactory, HWND hwnd, const RECT& rect)
{
    d2dFactory_.Set(d2dFactory);
    dwriteFactory_.Set(dwriteFactory);

    D2D1_SIZE_U d2dSize = D2D1::SizeU(rect.right - rect.left, rect.bottom - rect.top);

    // Create a D2D render target.
    HRESULT hr = d2dFactory_->CreateHwndRenderTarget(
                    D2D1::RenderTargetProperties(),
                    D2D1::HwndRenderTargetProperties(hwnd, d2dSize),
                    &target_
                    );

    if (FAILED(hr))
        throw HrException(hr, "Could not create D2D render target!" FAILURE_LOCATION);

    // Explicitly set the DPI so that it always has a 1:1 pixel ratio.
    // Scaling is best applied by the application via a matrix. Otherwise
    // images and text are blurry.
    target_->SetDpi(96.0, 96.0);
}


void RenderTargetD2D::Resize(UINT width, UINT height)
{
    D2D1_SIZE_U size;
    size.width = width;
    size.height = height;
    target_->Resize(size);
}


void RenderTargetD2D::BeginDraw()
{
    target_->BeginDraw();
    target_->SetTransform(D2D1::Matrix3x2F::Identity());
}


void RenderTargetD2D::EndDraw()
{
    target_->EndDraw();
}


void RenderTargetD2D::Clear(UINT32 color)
{
    target_->Clear(D2D1::ColorF(color));
}


ID2D1Bitmap* RenderTargetD2D::GetCachedImage(
    IWICBitmapSource* image
    )
{
    if (image == NULL)
        return NULL;

    // Find an existing match
    std::vector<ImageCacheEntry>::iterator match = std::find(imageCache_.begin(), imageCache_.end(), image);
    if (match != imageCache_.end())
        return match->converted; // already cached

    // Convert the WIC image to a ready-to-use device-dependent D2D bitmap.
    // This avoids needing to recreate a new texture every draw call, but
    // allows easy reconstruction of textures if the device changes and
    // resources need recreation (also lets callers be D2D agnostic).

    ComPtr<ID2D1Bitmap> bitmap;
    target_->CreateBitmapFromWicBitmap(image, NULL, &bitmap);
    if (bitmap == NULL)
        return NULL;

    // Save for later calls.
    imageCache_.push_back(ImageCacheEntry(image, bitmap));

    return bitmap;
}


void RenderTargetD2D::FillRectangle(
    const Position& destRect,
    const DrawingEffect& drawingEffect
    )
{
    ID2D1Brush* brush = GetCachedBrush(&drawingEffect);
    if (brush == NULL)
        return;

    // We will always get a strikethrough as a LTR rectangle
    // with the baseline origin snapped.
    D2D1_RECT_F rectangle =
    {
        destRect.l,
        destRect.t,
        destRect.l + destRect.w,
        destRect.t + destRect.h
    };
    target_->FillRectangle(rectangle, brush);
}


void RenderTargetD2D::DrawImage(
    IWICBitmapSource* image,
    const Position& sourceRect,  // where in source atlas texture
    const Position& destRect     // where on display to draw it
    )
{
    // Ignore zero size source rect, which can be received when
    // a control has no theme specified.
    if (&sourceRect == NULL || sourceRect.w <= 0 || sourceRect.h <= 0)
        return;

    // Draw nothing if the destination is zero size.
    if (destRect.w <= 0 || destRect.h <= 0)
        return;

    ID2D1Bitmap* bitmap = GetCachedImage(image);
    if (bitmap == NULL)
        return;

    target_->DrawBitmap(
            bitmap,
            D2D1::Rect(destRect.x, destRect.y, destRect.x + destRect.w, destRect.y + destRect.h),
            1.0, // opacity
            D2D1_BITMAP_INTERPOLATION_MODE_LINEAR,
            D2D1::Rect(sourceRect.x, sourceRect.y, sourceRect.x + sourceRect.w, sourceRect.y + sourceRect.h)
            );
}


void RenderTargetD2D::DrawTextLayout(
    __in IDWriteTextLayout* textLayout,
    const Position& rect
    )
{
    if (textLayout == NULL)
        return; // called by a control that didn't have text set yet

    Context context(this, NULL);
    textLayout->Draw(
        &context,
        this,
        rect.x,
        rect.y
        );
}


ID2D1Brush* RenderTargetD2D::GetCachedBrush(
    const DrawingEffect* effect
    )
{
    if (effect == NULL)
        return NULL;

    // Find an existing brush for the given color.

    std::vector<BrushCacheEntry>::iterator match = std::find(brushCache_.begin(), brushCache_.end(), effect);
    if (match != brushCache_.end())
        return match->brush; // already cached

    // No brush yet, so create one. Need to pull the alpha from the color,
    // since D2D does not use the top byte.

    UINT32 bgra = effect->GetColor();
    float alpha  = (bgra >> 24) / 255.0f;
    ComPtr<ID2D1SolidColorBrush> brush;
    target_->CreateSolidColorBrush(D2D1::ColorF(bgra, alpha), &brush);

    // Save for later calls.
    if (brush != NULL)
        brushCache_.push_back(BrushCacheEntry(bgra, brush));

    return brush;
}


void RenderTargetD2D::SetTransform(DWRITE_MATRIX const& transform)
{
    target_->SetTransform(reinterpret_cast<const D2D1_MATRIX_3X2_F*>(&transform));
}


void RenderTargetD2D::GetTransform(DWRITE_MATRIX& transform)
{
    target_->GetTransform(reinterpret_cast<D2D1_MATRIX_3X2_F*>(&transform));
}


void RenderTargetD2D::SetAntialiasing(bool isEnabled)
{
    target_->SetAntialiasMode(isEnabled ? D2D1_ANTIALIAS_MODE_PER_PRIMITIVE : D2D1_ANTIALIAS_MODE_ALIASED);
}


HRESULT STDMETHODCALLTYPE RenderTargetD2D::DrawGlyphRun(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    DWRITE_MEASURING_MODE measuringMode,
    const DWRITE_GLYPH_RUN* glyphRun,
    const DWRITE_GLYPH_RUN_DESCRIPTION* glyphRunDescription,
    IUnknown* clientDrawingEffect
    )
{
    // If no drawing effect is applied to run, but a clientDrawingContext
    // is passed, use the one from that instead.
    // This is useful for trimming signs, where they don't have a color
    // of their own.
    clientDrawingEffect = GetDrawingEffect(clientDrawingContext, clientDrawingEffect);

    // Since we use our custom renderer and explicitly set the effect
    // on the layout, we know exactly what the parameter is and can
    // safely cast it directly.
    DrawingEffect* effect = static_cast<DrawingEffect*>(clientDrawingEffect);
    ID2D1Brush* brush = GetCachedBrush(effect);
    if (brush == NULL)
        return E_FAIL;

    target_->DrawGlyphRun(
        D2D1::Point2(baselineOriginX, baselineOriginY),
        glyphRun,
        brush,
        measuringMode
    );

    return S_OK;
}


HRESULT STDMETHODCALLTYPE RenderTargetD2D:: DrawUnderline(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    const DWRITE_UNDERLINE* underline,
    IUnknown* clientDrawingEffect
    )
{
    clientDrawingEffect = GetDrawingEffect(clientDrawingContext, clientDrawingEffect);

    DrawingEffect* effect = static_cast<DrawingEffect*>(clientDrawingEffect);
    ID2D1Brush* brush = GetCachedBrush(effect);
    if (brush == NULL)
        return E_FAIL;

    // We will always get a strikethrough as a LTR rectangle
    // with the baseline origin snapped.
    D2D1_RECT_F rectangle =
    {
        baselineOriginX,
        baselineOriginY + underline->offset,
        baselineOriginX + underline->width,
        baselineOriginY + underline->offset + underline->thickness
   };

    // Draw this as a rectangle, rather than a line.
    target_->FillRectangle(&rectangle, brush);

    return S_OK;
}


HRESULT STDMETHODCALLTYPE RenderTargetD2D::DrawStrikethrough(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    const DWRITE_STRIKETHROUGH* strikethrough,
    IUnknown* clientDrawingEffect
    )
{
    clientDrawingEffect = GetDrawingEffect(clientDrawingContext, clientDrawingEffect);

    DrawingEffect* effect = static_cast<DrawingEffect*>(clientDrawingEffect);
    ID2D1Brush* brush = GetCachedBrush(effect);
    if (brush == NULL)
        return E_FAIL;

    // We will always get an underline as a LTR rectangle
    // with the baseline origin snapped.
    D2D1_RECT_F rectangle =
    {
        baselineOriginX,
        baselineOriginY + strikethrough->offset,
        baselineOriginX + strikethrough->width,
        baselineOriginY + strikethrough->offset + strikethrough->thickness
   };

    // Draw this as a rectangle, rather than a line.
    target_->FillRectangle(&rectangle, brush);

    return S_OK;
}


HRESULT STDMETHODCALLTYPE RenderTargetD2D::DrawInlineObject(
    __maybenull void* clientDrawingContext,
    FLOAT originX,
    FLOAT originY,
    IDWriteInlineObject* inlineObject,
    BOOL isSideways,
    BOOL isRightToLeft,
    IUnknown* clientDrawingEffect
    )
{
    // Inline objects inherit the drawing effect of the text
    // they are in, so we should pass it down (if none is set
    // on this range, use the drawing context's effect instead).
    Context subContext(*reinterpret_cast<RenderTarget::Context*>(clientDrawingContext));

    if (clientDrawingEffect != NULL)
        subContext.drawingEffect = clientDrawingEffect;

    inlineObject->Draw(
        &subContext,
        this,
        floor(originX), // D2D does subpixel, which leads to blurry images
        floor(originY), // so manually force whole pixel alignment.
        false,
        false,
        subContext.drawingEffect
        );

    return S_OK;
}


HRESULT STDMETHODCALLTYPE RenderTargetD2D::IsPixelSnappingDisabled(
    __maybenull void* clientDrawingContext,
    __out BOOL* isDisabled
    )
{
    // Don't want blurry text.
    *isDisabled = FALSE;
    return S_OK;
}


HRESULT STDMETHODCALLTYPE RenderTargetD2D::GetCurrentTransform(
    __maybenull void* clientDrawingContext,
    __out DWRITE_MATRIX* transform
    )
{
    // Simply forward what the real renderer holds onto.
    target_->GetTransform(reinterpret_cast<D2D1_MATRIX_3X2_F*>(transform));
    return S_OK;
}


HRESULT STDMETHODCALLTYPE RenderTargetD2D::GetPixelsPerDip(
    __maybenull void* clientDrawingContext,
    __out FLOAT* pixelsPerDip
    )
{
    // Any scaling will occur using matrix transforms rather than DPI.
    // This simplifies the logic when combining other effects that also
    // affect the transform.
    *pixelsPerDip = 1;
    return S_OK;
}


////////////////////////////////////////////////////////////////////////////////


RenderTargetDW::RenderTargetDW(HDC hdc, IDWriteFactory* dwriteFactory, const RECT& rect)
{
    hdc_ = hdc;

    dwriteFactory_.Set(dwriteFactory);

    dwriteFactory->GetGdiInterop(&gdiInterop_);
    if (gdiInterop_ == NULL)
        throw std::exception("Could not create GDI interrop interface render target!" FAILURE_LOCATION);

    gdiInterop_->CreateBitmapRenderTarget(hdc, rect.right, rect.bottom, &target_);
    if (target_ == NULL)
        throw std::exception("Could not create GDI BitmapRenderTarget!" FAILURE_LOCATION);

    target_->SetPixelsPerDip(1);

    // Just use the defaults of gamma=1.8, contrast=.5, and clearTypeLevel=.5
    dwriteFactory_->CreateRenderingParams(&renderingParams_);
    if (renderingParams_ == NULL)
        throw std::exception("Could not create IDWriteRenderingParams for GDI render target!" FAILURE_LOCATION);
}


RenderTargetDW::~RenderTargetDW()
{
    for (size_t i = 0, ci = imageCache_.size(); i < ci; ++i)
    {
        DeleteObject(imageCache_[i].converted);
    }
}

void RenderTargetDW::Resize(UINT width, UINT height)
{
    target_->Resize(width, height);
}


void RenderTargetDW::BeginDraw()
{
    memoryHdc_ = target_->GetMemoryDC();

    // Explicitly disable mirroring of bitmaps, otherwise the text
    // is literally drawn backwards, and ClearType is incorrect.
    SetLayout(memoryHdc_, LAYOUT_BITMAPORIENTATIONPRESERVED);
    SetLayout(hdc_,       LAYOUT_BITMAPORIENTATIONPRESERVED);
    SetGraphicsMode(memoryHdc_, GM_ADVANCED);

    SetBoundsRect(memoryHdc_, NULL, DCB_ENABLE|DCB_RESET);
}


void RenderTargetDW::Clear(UINT32 color)
{
    SIZE size;
    target_->GetSize(&size);

    SetDCBrushColor(memoryHdc_, color);
    SelectObject(memoryHdc_, GetStockObject(NULL_PEN));
    SelectObject(memoryHdc_, GetStockObject(DC_BRUSH));
    Rectangle(memoryHdc_, 0,0, size.cx + 1, size.cy + 1);
}


void RenderTargetDW::EndDraw()
{
    SIZE size;
    target_->GetSize(&size);

    RECT dirtyRect;
    GetBoundsRect(memoryHdc_, &dirtyRect, DCB_RESET);

    // Transfer from DWrite's rendering target to the actual display
    BitBlt(
        hdc_,
        0, 0,
        size.cx, size.cy,
        memoryHdc_,
        0, 0,
        SRCCOPY
        );
}


HBITMAP RenderTargetDW::GetCachedImage(
    IWICBitmapSource* image
    )
{
    if (image == NULL)
        return NULL;

    // Find an existing cached match for this image.
    std::vector<ImageCacheEntry>::iterator match = std::find(imageCache_.begin(), imageCache_.end(), image);
    if (match != imageCache_.end())
        return match->converted; // already cached

    // Convert the WIC image to a ready-to-use device-dependent GDI bitmap.
    // so that we don't recreate a new bitmap every draw call.
    //
    // * Note this expects BGRA pixel format.

    UINT width, height;
    if (FAILED(image->GetSize(&width, &height)))
        return NULL;

    UINT stride = width * 4;
    UINT pixelBufferSize = stride * height;
    std::vector<UINT8> pixelBuffer(pixelBufferSize);

    if (FAILED(image->CopyPixels(NULL, stride, pixelBufferSize, &pixelBuffer[0])))
        return NULL;

    BITMAPINFO bmi = {
        sizeof(BITMAPINFOHEADER), // biSize
        width, // biWidth
        -int(height), // biHeight
        1, // biPlanes
        32, // biBitCount
        BI_RGB, // biCompression
        pixelBufferSize, // biSizeImage
        1, // biXPelsPerMeter
        1, // biYPelsPerMeter
        0, // biClrUsed
        0, // biClrImportant
        0 // RGB QUAD
    };

    HBITMAP bitmap = CreateCompatibleBitmap(memoryHdc_, width, height);
    if (bitmap == NULL)
        return NULL;

    SetDIBits(
        memoryHdc_,
        bitmap,
        0,              // starting line
        height,         // total scanlines
        &pixelBuffer[0],
        &bmi,
        DIB_RGB_COLORS
        );

    // Save for later calls.
    imageCache_.push_back(ImageCacheEntry(image, bitmap));

    return bitmap;
}


void RenderTargetDW::FillRectangle(
    const Position& destRect,
    const DrawingEffect& drawingEffect
    )
{
    // Convert D2D/GDI+ color order to GDI's COLORREF,
    // which expects the lowest byte to be red.
    // The alpha channel must also be cleared.

    UINT32 bgra = drawingEffect.GetColor();
    COLORREF gdiColor = DrawingEffect::SwapRgb(bgra) & 0x00FFFFFF;
    SetDCBrushColor(memoryHdc_, gdiColor);

    SelectObject(memoryHdc_, GetStockObject(NULL_PEN));
    SelectObject(memoryHdc_, GetStockObject(DC_BRUSH));
    Rectangle(memoryHdc_, int(destRect.l),int(destRect.t), int(destRect.l + destRect.w), int(destRect.t + destRect.h));
}


void RenderTargetDW::DrawImage(
    IWICBitmapSource* image,
    const Position& sourceRect,  // where in source atlas texture
    const Position& destRect     // where on display to draw it
    )
{
    // Ignore zero size source rect, which can be validly received when
    // a control has no theme specified.
    if (&sourceRect == NULL || sourceRect.w <= 0 || sourceRect.h <= 0)
        return;

    // Draw nothing if the destination is zero size.
    if (destRect.w <= 0 || destRect.h <= 0)
        return;

    HBITMAP bitmap = GetCachedImage(image);
    if (bitmap == NULL)
        return;

    HDC tempHdc = CreateCompatibleDC(memoryHdc_);
    HBITMAP oldBitmap = (HBITMAP)SelectObject(tempHdc, bitmap);

    const static BLENDFUNCTION blend = {
        AC_SRC_OVER, // blend-op
        0, // flags
        255, // alpha
        AC_SRC_ALPHA
    };
    AlphaBlend(
        memoryHdc_,
        int(destRect.x), int(destRect.y),
        int(destRect.w), int(destRect.h),
        tempHdc,
        int(sourceRect.x), int(sourceRect.y),
        int(sourceRect.w), int(sourceRect.h),
        blend
        );

    SelectObject(tempHdc, oldBitmap);
    DeleteDC(tempHdc);

}


void RenderTargetDW::DrawTextLayout(
    __in IDWriteTextLayout* textLayout,
    const Position& rect
    )
{
    if (textLayout == NULL)
        return; // called by a control that didn't have text set yet

    Context context(this, NULL);
    textLayout->Draw(
        &context,
        this,
        rect.x,
        rect.y
        );
}


void RenderTargetDW::SetTransform(DWRITE_MATRIX const& transform)
{
    target_->SetCurrentTransform(&transform);
    SetWorldTransform(memoryHdc_, (XFORM*)&transform);
}


void RenderTargetDW::GetTransform(DWRITE_MATRIX& transform)
{
    target_->GetCurrentTransform(&transform);
}


HRESULT STDMETHODCALLTYPE RenderTargetDW::DrawGlyphRun(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    DWRITE_MEASURING_MODE measuringMode,
    const DWRITE_GLYPH_RUN* glyphRun,
    const DWRITE_GLYPH_RUN_DESCRIPTION* glyphRunDescription,
    IUnknown* clientDrawingEffect
    )
{
    // If no drawing effect is applied to run, but a clientDrawingContext
    // is passed, use the one from that instead.
    // This is useful for trimming signs, where they don't have a color
    // of their own.
    clientDrawingEffect = GetDrawingEffect(clientDrawingContext, clientDrawingEffect);
    
    // Since we use our custom renderer and explicitly set the effect
    // on the layout, we know exactly what the parameter is and can
    // safely cast it directly.
    DrawingEffect* effect = static_cast<DrawingEffect*>(clientDrawingEffect);
    if (effect == NULL)
        return E_FAIL;

    // Pass on the drawing call to the render target to do the real work.
    RECT dirtyRect = {0};
    UINT32 bgra = effect->GetColor();
    target_->DrawGlyphRun(
        baselineOriginX,
        baselineOriginY,
        measuringMode,
        glyphRun,
        renderingParams_,
        DrawingEffect::SwapRgb(bgra), // GDI expects RGB, not D2D's BGRA
        &dirtyRect
        );

    SetBoundsRect(memoryHdc_, &dirtyRect, DCB_ACCUMULATE);

    return S_OK;
}


HRESULT STDMETHODCALLTYPE RenderTargetDW::DrawUnderline(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    const DWRITE_UNDERLINE* underline,
    IUnknown* clientDrawingEffect
    )
{
    clientDrawingEffect = GetDrawingEffect(clientDrawingContext, clientDrawingEffect);

    return DrawLine(
        baselineOriginX,
        baselineOriginY,
        underline->width,
        underline->offset,
        underline->thickness,
        clientDrawingEffect
        );
}


HRESULT STDMETHODCALLTYPE RenderTargetDW::DrawStrikethrough(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    const DWRITE_STRIKETHROUGH* strikethrough,
    IUnknown* clientDrawingEffect
    )
{
    clientDrawingEffect = GetDrawingEffect(clientDrawingContext, clientDrawingEffect);

    return DrawLine(
        baselineOriginX,
        baselineOriginY,
        strikethrough->width,
        strikethrough->offset,
        strikethrough->thickness,
        clientDrawingEffect
        );
}


HRESULT RenderTargetDW::DrawLine(
    float baselineOriginX,
    float baselineOriginY,
    float width,
    float offset,
    float thickness,
    IUnknown* clientDrawingEffect
    )
{
    // Get solid color from drawing effect.
    DrawingEffect* effect = static_cast<DrawingEffect*>(clientDrawingEffect);
    if (effect == NULL)
        return E_FAIL;

    UINT32 bgra = effect->GetColor();
    HDC hdc = target_->GetMemoryDC();
    RECT rect = {
        LONG(baselineOriginX),
        LONG(baselineOriginY + offset),
        LONG(baselineOriginX + width),
        LONG(baselineOriginY + offset + thickness),
        };

    // Account for the possibility that the line became zero height,
    // which can occur at small font sizes.
    if (rect.bottom == rect.top)
        rect.bottom++;

    // Draw the line
    // Note that GDI wants RGB, not BGRA like D2D.

    #pragma prefast(suppress:__WARNING_ACCESSIBILITY_COLORAPI, "The color is a parameter is not supposed to come from GetSysColors.")
    SetBkColor(hdc, DrawingEffect::SwapRgb(bgra));
    ExtTextOut(
        hdc,
        0, 0,
        ETO_OPAQUE,
        &rect,
        L"",
        0,
        NULL
        );

    return S_OK;
}


HRESULT STDMETHODCALLTYPE RenderTargetDW::DrawInlineObject(
    __maybenull void* clientDrawingContext,
    FLOAT originX,
    FLOAT originY,
    IDWriteInlineObject* inlineObject,
    BOOL isSideways,
    BOOL isRightToLeft,
    IUnknown* clientDrawingEffect
    )
{
    // Inline objects inherit the drawing effect of the text
    // they are in, so we should pass it down (if none is set
    // on this range, use the drawing context's effect instead).
    Context subContext(*reinterpret_cast<RenderTarget::Context*>(clientDrawingContext));

    if (clientDrawingEffect != NULL)
        subContext.drawingEffect = clientDrawingEffect;

    inlineObject->Draw(
        &subContext,
        this,
        originX,
        originY,
        false,
        false,
        subContext.drawingEffect
        );

    return S_OK;
}


HRESULT STDMETHODCALLTYPE RenderTargetDW::IsPixelSnappingDisabled(
    __maybenull void* clientDrawingContext,
    __out BOOL* isDisabled
    )
{
    // Don't want blurry text.
    *isDisabled = FALSE;
    return S_OK;
}


HRESULT STDMETHODCALLTYPE RenderTargetDW::GetCurrentTransform(
    __maybenull void* clientDrawingContext,
    __out DWRITE_MATRIX* transform
    )
{
    // Simply forward what the real renderer holds onto.
    target_->GetCurrentTransform(transform);
    return S_OK;
}


HRESULT STDMETHODCALLTYPE RenderTargetDW::GetPixelsPerDip(
    __maybenull void* clientDrawingContext,
    __out FLOAT* pixelsPerDip
    )
{
    *pixelsPerDip = target_->GetPixelsPerDip();
    return S_OK;
}
