//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Render target for controls to draw to.
//
//----------------------------------------------------------------------------
#include "precomp.h"

namespace
{
    // Retrieves the corresponding source and destination rectangles in a
    // 9 cell grid.
    //
    // The parts are arranged as such, with four corners, four edges, and
    // a flexible center.
    //
    //  0 1 2
    //  3 4 5
    //  6 7 8
    //
    void GetNineGridRect(
        __in_range(0,8) int partIndex,
        const Position sourceRects[3],  // positioning in source atlas texture
        const Position& destRect,       // where to draw it
        __out Position& sourceSubrect,  // where to read the part from texture
        __out Position& destSubrect     // where to draw the part
        )
    {
        // The three rectangles passed include the coordinates in the
        // texture, sizes of each edge, and adjustments to the destination
        // rectangle, used for effects like menu shadows or the text
        // selection glow which extends slightly beyond the destination
        // rectangle.

        const Position& texture     = sourceRects[0];
        const Position& edges       = sourceRects[1];
        const Position& adjustment  = sourceRects[2];

        // Add the needed ectangle gives the margin or padding
        Position adjustedDest(destRect);
        adjustedDest.x += adjustment.x;
        adjustedDest.y += adjustment.y;
        adjustedDest.w += adjustment.w;
        adjustedDest.h += adjustment.h;

        switch (partIndex)
        {
        case 0: case 1: case 2: // top row
            sourceSubrect.y = texture.y;
            destSubrect.y   = adjustedDest.y;
            sourceSubrect.h = edges.t;
            destSubrect.h   = edges.t;
            break;
        case 3: case 4: case 5: // mid row
            sourceSubrect.y = texture.y      + edges.t;
            destSubrect.y   = adjustedDest.y + edges.t;
            sourceSubrect.h = texture.h      - edges.t - edges.b;
            destSubrect.h   = adjustedDest.h - edges.t - edges.b;
            break;
        case 6: case 7: case 8: // bottom row
            sourceSubrect.y = texture.y      + texture.h      - edges.b;
            destSubrect.y   = adjustedDest.y + adjustedDest.h - edges.b;
            sourceSubrect.h = edges.b;
            destSubrect.h   = edges.b;
            break;
        }

        switch (partIndex)
        {
        case 0: case 3: case 6: // left col
            sourceSubrect.x = texture.x;
            destSubrect.x   = adjustedDest.x;
            sourceSubrect.w = edges.l;
            destSubrect.w   = edges.l;
            break;
        case 1: case 4: case 7: // mid col
            sourceSubrect.x = texture.x      + edges.l;
            destSubrect.x   = adjustedDest.x + edges.l;
            sourceSubrect.w = texture.w      - edges.l - edges.r;
            destSubrect.w   = adjustedDest.w - edges.l - edges.r;
            break;
        case 2: case 5: case 8: // right col
            sourceSubrect.x = texture.x      + texture.w      - edges.r;
            destSubrect.x   = adjustedDest.x + adjustedDest.w - edges.r;
            sourceSubrect.w = edges.r;
            destSubrect.w   = edges.r;
            break;
        }
    }


    // Picks some defaults for drawing text, so that callers need not always
    // specify them for drawing text.
    void GetTextFormatDefaults(
        IDWriteFactory* dwriteFactory,
        ComPtr<IDWriteTextFormat>& textFormat,
        ComPtr<DrawingEffect>& drawingEffect
        )
    {
        if (drawingEffect == NULL)
        {
            // Just use solid black
            drawingEffect.Set(new DrawingEffect(0xFF000000));
        }

        if (textFormat == NULL)
        {
            // Reasonable defaults for everything.
            HRESULT hr =
                dwriteFactory->CreateTextFormat(
                    L"Arial",
                    NULL,
                    DWRITE_FONT_WEIGHT_NORMAL,
                    DWRITE_FONT_STYLE_NORMAL,
                    DWRITE_FONT_STRETCH_NORMAL,
                    20,
                    L"", //locale
                    &textFormat
                    );

            // This should never fail, since all the hard work is saved
            // for layout creation. If it did fail, a bad parameter was
            // passed, or something much more serious occurred.
            if (FAILED(hr))
                throw OsException("Could not create default TextFormat!" FAILURE_LOCATION, hr);
        }
    }
}


UiRenderTargetD2D::UiRenderTargetD2D(ID2D1Factory* d2dFactory, IDWriteFactory* dwriteFactory, HWND hwnd, const RECT& rect, Mode mode)
{
    d2dFactory_.Set(d2dFactory);
    dwriteFactory_.Set(dwriteFactory);

    D2D1_SIZE_U d2dSize = D2D1::SizeU(rect.right - rect.left, rect.bottom - rect.top);

    // Create a D2D render target.
    HRESULT hr = d2dFactory_->CreateHwndRenderTarget(
                    D2D1::RenderTargetProperties(
                          (mode == ModeSoftware) ? D2D1_RENDER_TARGET_TYPE_SOFTWARE
                        : (mode == ModeHardware) ? D2D1_RENDER_TARGET_TYPE_HARDWARE
                        :                          D2D1_RENDER_TARGET_TYPE_DEFAULT
                    ),
                    D2D1::HwndRenderTargetProperties(hwnd, d2dSize),
                    &target_
                    );

    if (FAILED(hr))
        throw OsException("Could not create D2D render target!" FAILURE_LOCATION, hr);

    // Explicitly set the DPI so that it always has a 1:1 pixel ratio.
    // Scaling is best applied by the application via a matrix. Otherwise
    // images and text are blurry.
    target_->SetDpi(96.0, 96.0);
}


void UiRenderTargetD2D::Resize(UINT width, UINT height)
{
    D2D1_SIZE_U size;
    size.width = width;
    size.height = height;
    target_->Resize(size);
}


void UiRenderTargetD2D::BeginDraw()
{
    target_->BeginDraw();
    target_->SetTransform(D2D1::Matrix3x2F::Identity());
}


void UiRenderTargetD2D::EndDraw()
{
    target_->EndDraw();
}


void UiRenderTargetD2D::Clear()
{
    // No need to clear background if main window completely draws over,
    // but if you explicitly want it...
    target_->Clear(D2D1::ColorF(D2D1::ColorF::White));
}


void UiRenderTargetD2D::Flush()
{
    // D2D render targets have batching, so ensure we actually render
    // (don't need to present, just ensure the rendering occurs for
    //  profiling timing).
    target_->Flush();
}


ID2D1Bitmap* UiRenderTargetD2D::GetCachedImage(
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


void UiRenderTargetD2D::DrawImage(
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


void UiRenderTargetD2D::DrawNineGridImage(
    IWICBitmapSource* image,
    const Position sourceRects[3],  // positioning in source atlas texture
    const Position& destRect        // where on display to draw it
    )
{
    ID2D1Bitmap* bitmap = GetCachedImage(image);
    if (bitmap == NULL || sourceRects == NULL)
        return;

    // Draw nothing if the destination is zero size.
    if (destRect.w <= 0 || destRect.h <= 0)
        return;

    for (int i = 0; i < 9; ++i)
    {
        Position sourceSubrect, destSubrect;
        GetNineGridRect(i, sourceRects, destRect, sourceSubrect, destSubrect);

        // Don't draw anything that has no size. For one, it's less efficient. For another,
        // if you pass a negative size to DrawBitmap(), the EndDraw will fail later.
        if (sourceSubrect.w <= 0 || sourceSubrect.h <= 0 || destSubrect.w <= 0 || destSubrect.h <= 0)
            continue;

        target_->DrawBitmap(
                bitmap,
                D2D1::Rect(destSubrect.x, destSubrect.y, destSubrect.x + destSubrect.w, destSubrect.y + destSubrect.h),
                1.0, // opacity
                D2D1_BITMAP_INTERPOLATION_MODE_LINEAR,
                D2D1::Rect(sourceSubrect.x, sourceSubrect.y, sourceSubrect.x + sourceSubrect.w, sourceSubrect.y + sourceSubrect.h)
                );
    }
}


void UiRenderTargetD2D::DrawText(
    __in_ecount(textLength) const wchar_t* text,
    size_t textLength,
    __maybenull IDWriteTextFormat* textFormat,
    __maybenull DrawingEffect* drawingEffect,
    const Position& rect
    )
{
    // Get defaults if these are not passed.
    if (drawingEffect == NULL || textFormat == NULL)
    {
        GetTextFormatDefaults(dwriteFactory_, defaultTextFormat_, defaultDrawingEffect_);

        if (textFormat == NULL)
            textFormat = defaultTextFormat_;
        if (drawingEffect == NULL)
            drawingEffect = defaultDrawingEffect_;
    }

    ComPtr<IDWriteTextLayout> textLayout;
    HRESULT hr =
        dwriteFactory_->CreateGdiCompatibleTextLayout(
            text,
            UINT32(textLength),
            textFormat,
            std::max(rect.w, 0.f), // don't want layout creation to fail just
            std::max(rect.h, 0.f), // because the control was sized too small
            1, // use 1:1 pixels per DIP ratio
            NULL, // no transform
            false, // want measuring method compatible for crisp UI text
            &textLayout
            );

    if (FAILED(hr))
        throw OsException("Could not create TextLayout to draw!" FAILURE_LOCATION, hr);

    Context context(this, drawingEffect);
    textLayout->Draw(
        &context,
        this,
        rect.x,
        rect.y
        );
}


void UiRenderTargetD2D::DrawTextLayout(
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


ID2D1Brush* UiRenderTargetD2D::GetCachedBrush(
    DrawingEffect* effect
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


void UiRenderTargetD2D::PushClipRect(const Position& rect)
{
    target_->PushAxisAlignedClip(
        D2D1::RectF(rect.x, rect.y, rect.x + rect.w, rect.y + rect.h),
        D2D1_ANTIALIAS_MODE_ALIASED
        );
}


void UiRenderTargetD2D::PopClipRect()
{
    target_->PopAxisAlignedClip();
}


void UiRenderTargetD2D::SetTransform(DWRITE_MATRIX const& transform)
{
    target_->SetTransform(reinterpret_cast<D2D1_MATRIX_3X2_F const*>(&transform));
}


void UiRenderTargetD2D::GetTransform(DWRITE_MATRIX& transform)
{
    target_->GetTransform(reinterpret_cast<D2D1_MATRIX_3X2_F*>(&transform));
}


HRESULT STDMETHODCALLTYPE UiRenderTargetD2D::DrawGlyphRun(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    DWRITE_MEASURING_MODE measuringMode,
    __in DWRITE_GLYPH_RUN const* glyphRun,
    __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
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


HRESULT STDMETHODCALLTYPE UiRenderTargetD2D:: DrawUnderline(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    __in DWRITE_UNDERLINE const* underline,
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


HRESULT STDMETHODCALLTYPE UiRenderTargetD2D::DrawStrikethrough(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    __in DWRITE_STRIKETHROUGH const* strikethrough,
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


HRESULT STDMETHODCALLTYPE UiRenderTargetD2D::DrawInlineObject(
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


HRESULT STDMETHODCALLTYPE UiRenderTargetD2D::IsPixelSnappingDisabled(
    __maybenull void* clientDrawingContext,
    __out BOOL* isDisabled
    )
{
    // Don't want blurry text.
    *isDisabled = FALSE;
    return S_OK;
}


HRESULT STDMETHODCALLTYPE UiRenderTargetD2D::GetCurrentTransform(
    __maybenull void* clientDrawingContext,
    __out DWRITE_MATRIX* transform
    )
{
    // Simply forward what the real renderer holds onto.
    target_->GetTransform(reinterpret_cast<D2D1_MATRIX_3X2_F*>(transform));
    return S_OK;
}


HRESULT STDMETHODCALLTYPE UiRenderTargetD2D::GetPixelsPerDip(
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


UiRenderTargetDW::UiRenderTargetDW(HDC hdc, IDWriteFactory* dwriteFactory, const RECT& rect)
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


UiRenderTargetDW::~UiRenderTargetDW()
{
    for (size_t i = 0, ci = imageCache_.size(); i < ci; ++i)
    {
        DeleteObject(imageCache_[i].converted);
    }
    SelectClipRgn(memoryHdc_, NULL);
}

void UiRenderTargetDW::Resize(UINT width, UINT height)
{
    target_->Resize(width, height);
}


void UiRenderTargetDW::BeginDraw()
{
    memoryHdc_ = target_->GetMemoryDC();

    // Explicitly disable mirroring of bitmaps, otherwise the text
    // is literally drawn backwards, and ClearType is incorrect.
    SetLayout(memoryHdc_, LAYOUT_BITMAPORIENTATIONPRESERVED);
    SetLayout(hdc_,       LAYOUT_BITMAPORIENTATIONPRESERVED);
    SetGraphicsMode(memoryHdc_, GM_ADVANCED);

    SetBoundsRect(memoryHdc_, NULL, DCB_ENABLE|DCB_RESET);
}


void UiRenderTargetDW::Clear()
{
    // No need to clear background if main window completely draws over,
    // but if the caller explicitly wants it...
    SIZE size;
    target_->GetSize(&size);

    SetDCBrushColor(memoryHdc_, 0xFFFFFF);
    SelectObject(memoryHdc_, GetStockObject(NULL_PEN));
    SelectObject(memoryHdc_, GetStockObject(DC_BRUSH));
    Rectangle(memoryHdc_, 0,0, size.cx + 1, size.cy + 1);
}


void UiRenderTargetDW::Flush()
{
    // DirectWrite software render targets have no batching
}


void UiRenderTargetDW::EndDraw()
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


HBITMAP UiRenderTargetDW::GetCachedImage(
    IWICBitmapSource* image
    )
{
    if (image == NULL)
        return NULL;

    // Find an existing match
    std::vector<ImageCacheEntry>::iterator match = std::find(imageCache_.begin(), imageCache_.end(), image);
    if (match != imageCache_.end())
        return match->converted; // already cached

    // Convert the WIC image to a ready-to-use device-dependent GDI bitmap.
    // This avoids needing to recreate a new bitmap every draw call.
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


void UiRenderTargetDW::DrawImage(
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


void UiRenderTargetDW::DrawNineGridImage(
    IWICBitmapSource* image,
    const Position sourceRects[3],  // positioning in source atlas texture
    const Position& destRect        // where on display to draw it
    )
{
    HBITMAP bitmap = GetCachedImage(image);
    if (bitmap == NULL || sourceRects == NULL)
        return;

    // Draw nothing if the destination is zero size.
    if (destRect.w <= 0 || destRect.h <= 0)
        return;

    HDC tempHdc = CreateCompatibleDC(memoryHdc_);
    HBITMAP oldBitmap = (HBITMAP)SelectObject(tempHdc, bitmap);

    const static BLENDFUNCTION blend = {
        AC_SRC_OVER, // blend-op
        0, // flags
        255, // alpha
        AC_SRC_ALPHA
    };

    for (int i = 0; i < 9; ++i)
    {
        Position sourceSubrect, destSubrect;
        GetNineGridRect(i, sourceRects, destRect, sourceSubrect, destSubrect);

        // Don't draw anything if there is nothing to draw.
        if (sourceSubrect.w <= 0 || sourceSubrect.h <= 0 || destSubrect.w <= 0 || destSubrect.h <= 0)
            continue;

        AlphaBlend(
            memoryHdc_,
            int(destSubrect.x), int(destSubrect.y),
            int(destSubrect.w), int(destSubrect.h),
            tempHdc,
            int(sourceSubrect.x), int(sourceSubrect.y),
            int(sourceSubrect.w), int(sourceSubrect.h),
            blend
            );
    }

    SelectObject(tempHdc, oldBitmap);
    DeleteDC(tempHdc);
}


void UiRenderTargetDW::DrawText(
    __in_ecount(textLength) const wchar_t* text,
    size_t textLength,
    __maybenull IDWriteTextFormat* textFormat,
    __maybenull DrawingEffect* drawingEffect,
    const Position& rect
    )
{
    // Get defaults if these are not passed.
    if (drawingEffect == NULL || textFormat == NULL)
    {
        GetTextFormatDefaults(dwriteFactory_, defaultTextFormat_, defaultDrawingEffect_);

        if (textFormat == NULL)
            textFormat = defaultTextFormat_;
        if (drawingEffect == NULL)
            drawingEffect = defaultDrawingEffect_;
    }

    ComPtr<IDWriteTextLayout> textLayout;
    HRESULT hr =
        dwriteFactory_->CreateGdiCompatibleTextLayout(
            text,
            UINT32(textLength),
            textFormat,
            std::max(rect.w, 0.f), // don't want layout creation to fail just
            std::max(rect.h, 0.f), // because the control was sized too small
            1, // use 1:1 pixels per DIP ratio
            NULL, // no transform
            false, // want measuring method compatible for crisp UI text
            &textLayout
            );
    if (FAILED(hr))
        throw OsException("Could not create TextLayout!" FAILURE_LOCATION, hr);

    Context context(this, drawingEffect);
    textLayout->Draw(
        &context,
        this,
        rect.x,
        rect.y
        );
}


void UiRenderTargetDW::DrawTextLayout(
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


void UiRenderTargetDW::PushClipRect(const Position& rect)
{
    HRGN clippingRegion = CreateRectRgn(int(rect.x), int(rect.y), int(rect.x + rect.w), int(rect.y + rect.h));
    SelectClipRgn(memoryHdc_, clippingRegion);
    DeleteObject(clippingRegion);
    clipRects_.push_back(rect);
}


void UiRenderTargetDW::PopClipRect()
{
    clipRects_.pop_back();

    // Either pop previous clip or set entire surface as the clip
    if (clipRects_.empty())
    {
        SelectClipRgn(memoryHdc_, NULL);
    }
    else
    {
        Position rect = clipRects_.back();
        HRGN clippingRegion = CreateRectRgn(int(rect.x), int(rect.y), int(rect.x + rect.w), int(rect.y + rect.h));
        SelectClipRgn(memoryHdc_, clippingRegion);
        DeleteObject(clippingRegion);
    }
}


void UiRenderTargetDW::SetTransform(DWRITE_MATRIX const& transform)
{
    target_->SetCurrentTransform(&transform);
    SetWorldTransform(memoryHdc_, (XFORM*)&transform);
}


void UiRenderTargetDW::GetTransform(DWRITE_MATRIX& transform)
{
    target_->GetCurrentTransform(&transform);
}


HRESULT STDMETHODCALLTYPE UiRenderTargetDW::DrawGlyphRun(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    DWRITE_MEASURING_MODE measuringMode,
    __in DWRITE_GLYPH_RUN const* glyphRun,
    __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
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
        RGB(GetBValue(bgra), GetGValue(bgra), GetRValue(bgra)), // GDI expects RGB, not BGRA like D2D
        &dirtyRect
        );

    SetBoundsRect(memoryHdc_, &dirtyRect, DCB_ACCUMULATE);

    return S_OK;
}


HRESULT STDMETHODCALLTYPE UiRenderTargetDW::DrawUnderline(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    __in DWRITE_UNDERLINE const* underline,
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


HRESULT STDMETHODCALLTYPE UiRenderTargetDW::DrawStrikethrough(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    __in DWRITE_STRIKETHROUGH const* strikethrough,
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


HRESULT UiRenderTargetDW::DrawLine(
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
    SetBkColor(hdc, RGB(GetBValue(bgra), GetGValue(bgra), GetRValue(bgra)));
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


HRESULT STDMETHODCALLTYPE UiRenderTargetDW::DrawInlineObject(
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


HRESULT STDMETHODCALLTYPE UiRenderTargetDW::IsPixelSnappingDisabled(
    __maybenull void* clientDrawingContext,
    __out BOOL* isDisabled
    )
{
    // Don't want blurry text.
    *isDisabled = FALSE;
    return S_OK;
}


HRESULT STDMETHODCALLTYPE UiRenderTargetDW::GetCurrentTransform(
    __maybenull void* clientDrawingContext,
    __out DWRITE_MATRIX* transform
    )
{
    // Simply forward what the real renderer holds onto.
    target_->GetCurrentTransform(transform);
    return S_OK;
}


HRESULT STDMETHODCALLTYPE UiRenderTargetDW::GetPixelsPerDip(
    __maybenull void* clientDrawingContext,
    __out FLOAT* pixelsPerDip
    )
{
    *pixelsPerDip = target_->GetPixelsPerDip();
    return S_OK;
}


////////////////////////////////////////////////////////////////////////////////


UiRenderTargetGDI::UiRenderTargetGDI(HDC hdc, IDWriteFactory* dwriteFactory, const RECT& rect)
:   Base(hdc, dwriteFactory, rect),
    cachedGdiFont_(NULL)
{
}


UiRenderTargetGDI::~UiRenderTargetGDI()
{
    ClearCachedFont();
}


void UiRenderTargetGDI::DrawText(
    __in_ecount(textLength) const wchar_t* text,
    size_t textLength,
    __maybenull IDWriteTextFormat* textFormat,
    __maybenull DrawingEffect* drawingEffect,
    const Position& rect
    )
{
    SetTextAlign(memoryHdc_, TA_LEFT|TA_BASELINE);
    SetBkMode(memoryHdc_, TRANSPARENT);

    Base::DrawText(text, textLength, textFormat, drawingEffect, rect);
    ClearCachedFont();
}


void UiRenderTargetGDI::DrawTextLayout(
    __in IDWriteTextLayout* textLayout,
    const Position& rect
    )
{
    SetTextAlign(memoryHdc_, TA_LEFT|TA_BASELINE);
    SetBkMode(memoryHdc_, TRANSPARENT);

    Base::DrawTextLayout(textLayout, rect);
    ClearCachedFont();
}


HRESULT STDMETHODCALLTYPE UiRenderTargetGDI::DrawGlyphRun(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    DWRITE_MEASURING_MODE measuringMode,
    __in DWRITE_GLYPH_RUN const* glyphRun,
    __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
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

    // Massage the glyph run info into something TextOut can process.
    UINT32 bgra = effect->GetColor();
    SetTextColor(memoryHdc_, RGB(GetBValue(bgra), GetGValue(bgra), GetRValue(bgra)));

    std::vector<INT> advances(std::max(glyphRun->glyphCount * 2, 1u));
    bool isRtl = (glyphRun->bidiLevel & 1) != 0;
    float x = baselineOriginX;
    INT xiPrev = INT(floor(x + .5)), yi = 0, ydiPrev = 0;

    for (size_t i = 0, ci = glyphRun->glyphCount; i < ci; ++i)
    {
        // Turn vertical offsets into vertical advances
        if (i == 0)
        {
            // Pre-adjust first glyph's position
            if (glyphRun->glyphOffsets != NULL)
                baselineOriginY += glyphRun->glyphOffsets[i].ascenderOffset;
            yi = INT(floor(baselineOriginY + .5));
        }
        INT ydi = 0;
        if (i + 1 < ci)
        {
            // The advance of the current glyph is actually the offset of the
            // following one.
            float y = baselineOriginY;
            if (glyphRun->glyphOffsets != NULL)
                y += glyphRun->glyphOffsets[i+1].ascenderOffset;
            ydi = INT(floor(y + .5)) - yi;
        }
        advances[i*2+1] = ydi - ydiPrev;
        ydiPrev = ydi;

        // Turn horizontal advances into int's and convert post-advances into pre-advances for RTL.
        // XPS, DW, and D2D draw right-to-left text actually in right-to-left order.
        // GDI always draws left-to-right, so we 
        if (isRtl)
        {
            if (i == 0)
            {
                // Pre-adjust first glyph's position
                x -= glyphRun->glyphAdvances[0];
                baselineOriginX = x;
                xiPrev = INT(floor(x + .5));
            }
            if (i + 1 < ci)
            {
                // The advance of the current glyph is actually that of the
                // following one.
                x -= glyphRun->glyphAdvances[i+1];
            }
            INT xi = INT(floor(x + .5));
            advances[i*2] = xi - xiPrev;
            xiPrev = xi;
        }
        else
        {
            // Much simpler left-to-right case.
            x += glyphRun->glyphAdvances[i];
            INT xi = INT(floor(x + .5));
            advances[i*2] = xi - xiPrev;
            xiPrev = xi;
        }
    }

    // Create equivalent GDI font from DWrite font face.
    HFONT gdiFont = cachedGdiFont_;
    if (glyphRun->fontFace != lastUsedFont_)
    {
        lastUsedFont_.Set(glyphRun->fontFace);

        // Create a matching logical font
        LOGFONT logFont = {
            12,0,
            0,0,
            400,
            0,
            FALSE,
            FALSE,
            DEFAULT_CHARSET,
            OUT_DEFAULT_PRECIS,
            CLIP_DEFAULT_PRECIS,
            DEFAULT_QUALITY,
            FF_DONTCARE,
            L"Arial"
        };
        gdiInterop_->ConvertFontFaceToLOGFONT(glyphRun->fontFace, &logFont);
        logFont.lfHeight = -LONG(floor(glyphRun->fontEmSize + .5f)); // rounded

        gdiFont = CreateFontIndirect(&logFont);
    }
    SelectObject(memoryHdc_, gdiFont);
    if (gdiFont != cachedGdiFont_)
    {
        DeleteObject(cachedGdiFont_);
        cachedGdiFont_ = gdiFont;
    }

    // Pass on the drawing call to GDI to do the real work.

    ExtTextOut(
        memoryHdc_,
        INT(floor(baselineOriginX + .5)),
        INT(floor(baselineOriginY + .5)),
        ETO_GLYPH_INDEX|ETO_PDY,
        NULL, // no clip rect
        (LPCWSTR)glyphRun->glyphIndices,
        glyphRun->glyphCount,
        &advances[0]
        );

    return S_OK;
}


////////////////////////////////////////////////////////////////////////////////


UiRenderTargetGDIPlus::UiRenderTargetGDIPlus(HDC hdc, IDWriteFactory* dwriteFactory, const RECT& rect)
:   Base(hdc, dwriteFactory, rect),
    gdiplusToken_(NULL),
    graphics_(NULL)
{
    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    Gdiplus::GdiplusStartup(&gdiplusToken_, &gdiplusStartupInput, NULL);
    assert(gdiplusToken_ != NULL);
}


UiRenderTargetGDIPlus::~UiRenderTargetGDIPlus()
{
    delete graphics_;
    graphics_ = NULL;
    Gdiplus::GdiplusShutdown(gdiplusToken_);
}


void UiRenderTargetGDIPlus::BeginDraw()
{
    Base::BeginDraw();
    graphics_ = new Gdiplus::Graphics(memoryHdc_);
}


void UiRenderTargetGDIPlus::EndDraw()
{
    delete graphics_;
    graphics_ = NULL;
    Base::EndDraw();
}


void UiRenderTargetGDIPlus::PushClipRect(const Position& rect)
{
    Base::PushClipRect(rect);
    Gdiplus::RectF gdiPlusRect(rect.x, rect.y, rect.w, rect.h);
    graphics_->SetClip(gdiPlusRect);
}


void UiRenderTargetGDIPlus::PopClipRect()
{
    Base::PopClipRect();

    // Either pop previous clip or set entire surface as the clip
    Position rect;
    if (clipRects_.empty())
    {
        SIZE size;
        target_->GetSize(&size);
        rect.x = 0;
        rect.y = 0;
        rect.w = float(size.cx);
        rect.h = float(size.cy);
    }
    else
    {
        rect = clipRects_.back();
    }
    Gdiplus::RectF gdiPlusRect(rect.x, rect.y, rect.w, rect.h);
    graphics_->SetClip(gdiPlusRect);
}


void UiRenderTargetGDIPlus::SetTransform(DWRITE_MATRIX const& transform)
{
    Base::SetTransform(transform);
    Gdiplus::Matrix gdiPlusTransform(transform.m11, transform.m12, transform.m21, transform.m22, transform.dx, transform.dy);
    graphics_->SetTransform(&gdiPlusTransform);
}


void UiRenderTargetGDIPlus::DrawText(
    __in_ecount(textLength) const wchar_t* text,
    size_t textLength,
    __maybenull IDWriteTextFormat* textFormat,
    __maybenull DrawingEffect* drawingEffect,
    const Position& rect
    )
{
    Base::DrawText(text, textLength, textFormat, drawingEffect, rect);
}


void UiRenderTargetGDIPlus::DrawTextLayout(
    __in IDWriteTextLayout* textLayout,
    const Position& rect
    )
{
    Base::DrawTextLayout(textLayout, rect);
}


HRESULT STDMETHODCALLTYPE UiRenderTargetGDIPlus::DrawGlyphRun(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    DWRITE_MEASURING_MODE measuringMode,
    __in DWRITE_GLYPH_RUN const* glyphRun,
    __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
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

    // Massage the glyph run info into something DrawDriverString can process.
    UINT32 bgra = effect->GetColor();
    Gdiplus::Color gdiplusColor = 0;
    gdiplusColor = Gdiplus::Color(Gdiplus::ARGB(bgra));//255, bgra & 255, (bgra>>8) & 255, (bgra>>16) & 255);

    // Create a matching logical font
    LOGFONT logFont = {
        12,0,
        0,0,
        400,
        0,
        FALSE,
        FALSE,
        DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS,
        CLIP_DEFAULT_PRECIS,
        DEFAULT_QUALITY,
        FF_DONTCARE,
        L"Arial"
    };
    gdiInterop_->ConvertFontFaceToLOGFONT(glyphRun->fontFace, &logFont);
    logFont.lfHeight = -LONG(floor(glyphRun->fontEmSize + .5f)); // rounded instead of floored

    UINT32 flags = 0;
    UINT32 style = 0;
    if (logFont.lfWeight >= 600) style |= Gdiplus::FontStyleBold;
    if (logFont.lfItalic != 0)   style |= Gdiplus::FontStyleItalic;

    Gdiplus::FontFamily  fontFamily(logFont.lfFaceName);
    Gdiplus::Font        font(&fontFamily, Gdiplus::REAL(-logFont.lfHeight), Gdiplus::FontStyle(style), Gdiplus::UnitPixel);
    Gdiplus::SolidBrush  solidBrush(gdiplusColor);

    std::vector<Gdiplus::PointF> positions(std::max(glyphRun->glyphCount, 1u));
    bool isRtl = (glyphRun->bidiLevel & 1) != 0;
    float x = baselineOriginX, y = baselineOriginY;

    for (size_t i = 0, ci = glyphRun->glyphCount; i < ci; ++i)
    {
        // Turn advances and offsets into pure positions.
        float xOffset = (glyphRun->glyphOffsets != NULL) ? glyphRun->glyphOffsets[i].advanceOffset  : 0;
        float yOffset = (glyphRun->glyphOffsets != NULL) ? glyphRun->glyphOffsets[i].ascenderOffset : 0;
        if (isRtl)
        {
            // Pre-adjust glyph's position
            x -= glyphRun->glyphAdvances[i];
            positions[i].X = x - xOffset;
            positions[i].Y = y - yOffset;
        }
        else
        {
            // Post-adjust glyph's position
            positions[i].X = x + xOffset;
            positions[i].Y = y - yOffset;
            x += glyphRun->glyphAdvances[i];
        }
    }

    // Pass on the drawing call to GDI+ to do the real work.

    graphics_->DrawDriverString(      
        glyphRun->glyphIndices,
        glyphRun->glyphCount,
        &font,
        &solidBrush,
        &positions[0],
        flags,
        NULL
        );

    return S_OK;
}


////////////////////////////////////////////////////////////////////////////////


UiRenderTargetNullDraw::UiRenderTargetNullDraw(HDC hdc, IDWriteFactory* dwriteFactory, const RECT& rect)
:   Base(hdc, dwriteFactory, rect)
{
}


HRESULT STDMETHODCALLTYPE UiRenderTargetNullDraw::DrawGlyphRun(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    DWRITE_MEASURING_MODE measuringMode,
    __in DWRITE_GLYPH_RUN const* glyphRun,
    __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
    IUnknown* clientDrawingEffect
    )
{
    return S_OK;
}


HRESULT STDMETHODCALLTYPE UiRenderTargetNullDraw::DrawUnderline(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    __in DWRITE_UNDERLINE const* underline,
    IUnknown* clientDrawingEffect
    )
{
    return S_OK;
}


HRESULT STDMETHODCALLTYPE UiRenderTargetNullDraw::DrawStrikethrough(
    __maybenull void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    __in DWRITE_STRIKETHROUGH const* strikethrough,
    IUnknown* clientDrawingEffect
    )
{
    return S_OK;
}


HRESULT STDMETHODCALLTYPE UiRenderTargetNullDraw::DrawInlineObject(
    __maybenull void* clientDrawingContext,
    FLOAT originX,
    FLOAT originY,
    IDWriteInlineObject* inlineObject,
    BOOL isSideways,
    BOOL isRightToLeft,
    IUnknown* clientDrawingEffect
    )
{
    return S_OK;
}
