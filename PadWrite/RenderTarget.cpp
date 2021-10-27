//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Adapter render target draws using D2D or DirectWrite.
//              This demonstrates how to implement your own render target
//              for layout drawing callbacks.
//
//----------------------------------------------------------------------------
#include "precomp.h"


////////////////////////////////////////////////////////////////////////////////
// Direct2D render target.

RenderTargetD2D::RenderTargetD2D(ID2D1Factory* d2dFactory, IDWriteFactory* dwriteFactory, HWND hwnd)
:   hwnd_(hwnd),
    hmonitor_(NULL),
    d2dFactory_(d2dFactory),
    dwriteFactory_(dwriteFactory)
{
    HrException::IfFailed(CreateTarget(), "Could not create D2D render target!" FAILURE_LOCATION);
}


HRESULT RenderTargetD2D::CreateTarget()
{
    // Creates a D2D render target set on the HWND.

    // Get the window's pixel size.
    RECT rect = {};
    GetClientRect(hwnd_, &rect);
    D2D1_SIZE_U d2dSize = D2D1::SizeU(rect.right, rect.bottom);

    // Create a D2D render target.
    // Note this uses software mode so that D2D and the system caret cooperate.
    // Otherwise, the caret (drawn using GDI) will not be visible while running
    // DWM with a D2D surface (D3D content).
    ComPtr<ID2D1HwndRenderTarget> target;
    IFR(d2dFactory_->CreateHwndRenderTarget(
                    D2D1::RenderTargetProperties(D2D1_RENDER_TARGET_TYPE_SOFTWARE),
                    D2D1::HwndRenderTargetProperties(hwnd_, d2dSize),
                    &target
                    ));

    target_ = target;

    // Any scaling will be combined into matrix transforms rather than an
    // additional DPI scaling. This simplifies the logic for rendering
    // and hit-testing. If an application does not use matrices, then
    // using the scaling factor directly is simpler.
    target_->SetDpi(96.0, 96.0);

    // Update the initial monitor rendering parameters.
    UpdateMonitor();

    return S_OK;
}


void RenderTargetD2D::Resize(UINT width, UINT height)
{
    D2D1_SIZE_U size;
    size.width = width;
    size.height = height;
    target_->Resize(size);
}


void RenderTargetD2D::UpdateMonitor()
{
    // Updates rendering parameters according to current monitor.

    HMONITOR monitor = MonitorFromWindow(hwnd_, MONITOR_DEFAULTTONEAREST);
    if (monitor != hmonitor_)
    {
        // Create based on monitor settings, rather than the defaults of
        // gamma=1.8, contrast=.5, and clearTypeLevel=.5

        ComPtr<IDWriteRenderingParams> renderingParams;

        dwriteFactory_->CreateMonitorRenderingParams(
                            monitor,
                            &renderingParams
                            );
        target_->SetTextRenderingParams(renderingParams);

        hmonitor_ = monitor;
        InvalidateRect(hwnd_, NULL, FALSE);
    }
}


void RenderTargetD2D::BeginDraw()
{
    target_->BeginDraw();
    target_->SetTransform(D2D1::Matrix3x2F::Identity());
}


void RenderTargetD2D::EndDraw()
{
    HRESULT hr = target_->EndDraw();
    if (hr == D2DERR_RECREATE_TARGET)
    {
        // Flush resources and recreate them.
        // This is very rare for a device to be lost,
        // but it can occur when connecting via Remote Desktop.
        imageCache_.clear();
        brushCache_.clear();
        hmonitor_ = NULL;

        CreateTarget();
    }
}


void RenderTargetD2D::Clear(UINT32 color)
{
    target_->Clear(D2D1::ColorF(color));
}


ID2D1Bitmap* RenderTargetD2D::GetCachedImage(IWICBitmapSource* image)
{
    // Maps a WIC image source to an aready cached D2D bitmap.
    // If not already cached, it creates the D2D bitmap from WIC.

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
    const RectF& destRect,
    const DrawingEffect& drawingEffect
    )
{
    ID2D1Brush* brush = GetCachedBrush(&drawingEffect);
    if (brush == NULL)
        return;

    // We will always get a strikethrough as a LTR rectangle
    // with the baseline origin snapped.
    target_->FillRectangle(destRect, brush);
}


void RenderTargetD2D::DrawImage(
    IWICBitmapSource* image,
    const RectF& sourceRect,  // where in source atlas texture
    const RectF& destRect     // where on display to draw it
    )
{
    // Ignore zero size source rects.
    // Draw nothing if the destination is zero size.
    if (&sourceRect == NULL
    || sourceRect.left >= sourceRect.right
    || sourceRect.top  >= sourceRect.bottom
    || destRect.left   >= destRect.right
    || destRect.top    >= destRect.bottom)
    {
        return;
    }

    ID2D1Bitmap* bitmap = GetCachedImage(image);
    if (bitmap == NULL)
        return;

    target_->DrawBitmap(
            bitmap,
            destRect,
            1.0, // opacity
            D2D1_BITMAP_INTERPOLATION_MODE_LINEAR,
            sourceRect
            );
}


void RenderTargetD2D::DrawTextLayout(
    __in IDWriteTextLayout* textLayout,
    const RectF& rect
    )
{
    if (textLayout == NULL)
        return;

    Context context(this, NULL);
    textLayout->Draw(
        &context,
        this,
        rect.left,
        rect.top
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
    // is passed, use the one from that instead. This is useful for trimming
    // signs, where they don't have a color of their own.
    clientDrawingEffect = GetDrawingEffect(clientDrawingContext, clientDrawingEffect);

    // Since we use our own custom renderer and explicitly set the effect
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
    // Enable pixel snapping, since we're not animating and
    // don't want blurry baseline text.
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
    // Any scaling will be combined into matrix transforms rather than an
    // additional DPI scaling. This simplifies the logic for rendering
    // and hit-testing. If an application does not use matrices, then
    // using the scaling factor directly is simpler.
    *pixelsPerDip = 1;
    return S_OK;
}


////////////////////////////////////////////////////////////////////////////////
// DirectWrite render target.


RenderTargetDW::RenderTargetDW(IDWriteFactory* dwriteFactory, HWND hwnd)
:   hwnd_(hwnd),
    hmonitor_(NULL),
    dwriteFactory_(dwriteFactory)
{
    // Creates a DirectWrite bitmap render target.

    dwriteFactory->GetGdiInterop(&gdiInterop_);
    if (gdiInterop_ == NULL)
        throw std::exception("Could not create GDI-interrop interface render target!" FAILURE_LOCATION);

    RECT rect = {};
    HDC hdc = GetDC(hwnd);
    GetClientRect(hwnd, &rect);
    gdiInterop_->CreateBitmapRenderTarget(hdc, rect.right, rect.bottom, &target_);
    ReleaseDC(hwnd, hdc);

    if (target_ == NULL)
        throw std::exception("Could not create GDI BitmapRenderTarget!" FAILURE_LOCATION);

    // Any scaling will be combined into matrix transforms rather than an
    // additional DPI scaling. This simplifies the logic for rendering
    // and hit-testing. If an application does not use matrices, then
    // using the scaling factor directly is simpler.
    target_->SetPixelsPerDip(1);

    // Update the initial monitor rendering parameters.
    UpdateMonitor();

    if (renderingParams_ == NULL)
        throw std::exception("Could not create IDWriteRenderingParams for DirectWrite render target!" FAILURE_LOCATION);
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


void RenderTargetDW::UpdateMonitor()
{
    // Updates rendering parameters according to current monitor.

    HMONITOR monitor = MonitorFromWindow(hwnd_, MONITOR_DEFAULTTONEAREST);
    if (monitor != hmonitor_)
    {
        // Create based on monitor settings, rather than the defaults of
        // gamma=1.8, contrast=.5, and clearTypeLevel=.5

        renderingParams_.Attach(NULL);
        dwriteFactory_->CreateMonitorRenderingParams(
                            monitor,
                            &renderingParams_
                            );
        hmonitor_ = monitor;
        InvalidateRect(hwnd_, NULL, FALSE);
    }
}


void RenderTargetDW::BeginDraw()
{
    memoryHdc_ = target_->GetMemoryDC();

    // Explicitly disable mirroring of bitmaps, otherwise the text
    // is literally drawn backwards, and ClearType is incorrect.
    SetLayout(memoryHdc_, LAYOUT_BITMAPORIENTATIONPRESERVED);
    SetGraphicsMode(memoryHdc_, GM_ADVANCED);
}


void RenderTargetDW::EndDraw()
{
    SIZE size;
    target_->GetSize(&size);

    HDC hdc = GetDC(hwnd_);

    // Explicitly disable mirroring of bitmaps, otherwise the text
    // is literally drawn backwards, and ClearType is incorrect.
    SetLayout(hdc, LAYOUT_BITMAPORIENTATIONPRESERVED);
    SetGraphicsMode(memoryHdc_, GM_COMPATIBLE);

    // Transfer from DWrite's rendering target to the actual display
    BitBlt(
        hdc,
        0, 0,
        size.cx, size.cy,
        memoryHdc_,
        0, 0,
        SRCCOPY
        );

    ReleaseDC(hwnd_, hdc);
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


HBITMAP RenderTargetDW::GetCachedImage(IWICBitmapSource* image)
{
    // Maps a WIC image source to an aready cached HBITMAP.
    // If not already cached, it creates the HBITMAP from WIC.

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

    // Initialize bitmap information.
    BITMAPINFO bmi = {
        sizeof(BITMAPINFOHEADER),   // biSize
        width,                      // biWidth
        -int(height),               // biHeight
        1,                          // biPlanes
        32,                         // biBitCount
        BI_RGB,                     // biCompression
        pixelBufferSize,            // biSizeImage
        1,                          // biXPelsPerMeter
        1,                          // biYPelsPerMeter
        0,                          // biClrUsed
        0,                          // biClrImportant
        0                           // RGB QUAD
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
    const RectF& destRect,
    const DrawingEffect& drawingEffect
    )
{
    // Convert D2D/GDI+ color order to GDI's COLORREF,
    // which expects the lowest byte to be red.
    // The alpha channel must also be cleared.

    COLORREF gdiColor = drawingEffect.GetColorRef();
    SetDCBrushColor(memoryHdc_, gdiColor);

    SelectObject(memoryHdc_, GetStockObject(NULL_PEN));
    SelectObject(memoryHdc_, GetStockObject(DC_BRUSH));
    Rectangle(memoryHdc_, int(destRect.left),int(destRect.top), int(destRect.right), int(destRect.bottom));
}


void RenderTargetDW::DrawImage(
    IWICBitmapSource* image,
    const RectF& sourceRect,  // where in source atlas texture
    const RectF& destRect     // where on display to draw it
    )
{
    // Ignore zero size source rects.
    // Draw nothing if the destination is zero size.
    if (&sourceRect == NULL
    || sourceRect.left >= sourceRect.right
    || sourceRect.top  >= sourceRect.bottom
    || destRect.left   >= destRect.right
    || destRect.top    >= destRect.bottom)
    {
        return;
    }

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
        int(destRect.left),
        int(destRect.top),
        int(destRect.right - destRect.left),
        int(destRect.bottom - destRect.top),
        tempHdc,
        int(sourceRect.left),
        int(sourceRect.top),
        int(sourceRect.right - sourceRect.left),
        int(sourceRect.bottom - sourceRect.top),
        blend
        );

    SelectObject(tempHdc, oldBitmap);
    DeleteDC(tempHdc);
}


void RenderTargetDW::DrawTextLayout(
    __in IDWriteTextLayout* textLayout,
    const RectF& rect
    )
{
    if (textLayout == NULL)
        return;

    Context context(this, NULL);
    textLayout->Draw(
        &context,
        this,
        rect.left,
        rect.top
        );
}


void RenderTargetDW::SetTransform(DWRITE_MATRIX const& transform)
{
    target_->SetCurrentTransform(&transform);
    SetGraphicsMode(memoryHdc_, GM_ADVANCED);
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
    // is passed, use the one from that instead. This is useful for trimming
    // signs, where they don't have a color of their own.
    clientDrawingEffect = GetDrawingEffect(clientDrawingContext, clientDrawingEffect);
    
    // Since we use our own custom renderer and explicitly set the effect
    // on the layout, we know exactly what the parameter is and can
    // safely cast it directly.
    DrawingEffect* effect = static_cast<DrawingEffect*>(clientDrawingEffect);
    if (effect == NULL)
        return E_FAIL;

    // Pass on the drawing call to the render target to do the real work.
    IFR(target_->DrawGlyphRun(
        baselineOriginX,
        baselineOriginY,
        measuringMode,
        glyphRun,
        renderingParams_,
        effect->GetColorRef(),
        NULL
        ));

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
    SetBkColor(hdc, effect->GetColorRef());
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
    // Enable pixel snapping, since we're not animating and
    // don't want blurry baseline text.
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
    // Simply forward what the real renderer holds onto.
    *pixelsPerDip = target_->GetPixelsPerDip();
    return S_OK;
}
