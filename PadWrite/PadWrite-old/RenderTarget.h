//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Adapter render target draws using D2D or DirectWrite.
//              This demonstrates how to implement your own render target
//              for layout drawing callbacks.
//
//----------------------------------------------------------------------------
#pragma once


struct ID2D1HwndRenderTarget;
struct ID2D1Bitmap;
class InlineImage;
class DrawingEffect;
typedef D2D1_RECT_F RectF;


////////////////////////////////////////////////////////////////////////////////

class RenderTarget;

// Intermediate render target for UI to draw to either a D2D or GDI surface.
class DECLSPEC_UUID("4327AC14-3172-4807-BF40-02C7475A2520") RenderTarget
    :   public ComBase<
            QiListSelf<RenderTarget,
            QiList<IDWriteTextRenderer>
        > >
{
public:
    virtual void BeginDraw() = NULL;
    virtual void EndDraw() = NULL;
    virtual void Clear(UINT32 color) = NULL;
    virtual void Resize(UINT width, UINT height) = NULL;
    virtual void UpdateMonitor() = NULL;

    virtual void SetTransform(DWRITE_MATRIX const& transform) = NULL;
    virtual void GetTransform(DWRITE_MATRIX& transform) = NULL;
    virtual void SetAntialiasing(bool isEnabled) = NULL;


    virtual void DrawTextLayout(
        IDWriteTextLayout* textLayout,
        const RectF& rect
        ) = NULL;

    // Draws a single image, from the given coordinates, to the given coordinates.
    // If the height and width differ, they will be scaled, but mirroring must be
    // done via a matrix transform.
    virtual void DrawImage(
        IWICBitmapSource* image,
        const RectF& sourceRect,  // where in source atlas texture
        const RectF& destRect     // where on display to draw it
        ) = NULL;

    virtual void FillRectangle(
        const RectF& destRect,
        const DrawingEffect& drawingEffect
        ) = NULL;

protected:
    // This context is not persisted, only existing on the stack as it
    // is passed down through. This is mainly needed to handle cases
    // where runs where no drawing effect set, like those of an inline
    // object or trimming sign.
    struct Context
    {
        Context(RenderTarget* initialTarget, IUnknown* initialDrawingEffect)
        :   target(initialTarget),
            drawingEffect(initialDrawingEffect)
        { }

        // short lived weak pointers
        RenderTarget* target;
        IUnknown* drawingEffect;
    };

    IUnknown* GetDrawingEffect(void* clientDrawingContext, IUnknown* drawingEffect)
    {
        // Callbacks use this to use a drawing effect from the client context
        // if none was passed into the callback.
        if (drawingEffect != NULL)
            return drawingEffect;

        return (reinterpret_cast<Context*>(clientDrawingContext))->drawingEffect;
    }
};


////////////////////////////////////////////////////////////////////////////////

class RenderTargetD2D : public RenderTarget
{
public:
    RenderTargetD2D(ID2D1Factory* d2dFactory, IDWriteFactory* dwriteFactory, HWND hwnd, const RECT& rect);

    virtual void BeginDraw() OVERRIDE;
    virtual void EndDraw() OVERRIDE;
    virtual void Clear(UINT32 color) OVERRIDE;
    virtual void Resize(UINT width, UINT height) OVERRIDE;
    virtual void UpdateMonitor() OVERRIDE;

    virtual void SetTransform(DWRITE_MATRIX const& transform) OVERRIDE;
    virtual void GetTransform(DWRITE_MATRIX& transform) OVERRIDE;
    virtual void SetAntialiasing(bool isEnabled) OVERRIDE;

    virtual void DrawTextLayout(
        IDWriteTextLayout* textLayout,
        const RectF& rect
        ) OVERRIDE;

    virtual void DrawImage(
        IWICBitmapSource* image,
        const RectF& sourceRect,  // where in source atlas texture
        const RectF& destRect     // where on display to draw it
        ) OVERRIDE;

    void FillRectangle(
        const RectF& destRect,
        const DrawingEffect& drawingEffect
        ) OVERRIDE;

    // IDWriteTextRenderer implementation

    STDMETHOD(DrawGlyphRun)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        const DWRITE_GLYPH_RUN* glyphRun,
        const DWRITE_GLYPH_RUN_DESCRIPTION* glyphRunDescription,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawUnderline)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        const DWRITE_UNDERLINE* underline,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawStrikethrough)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        const DWRITE_STRIKETHROUGH* strikethrough,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawInlineObject)(
        __maybenull void* clientDrawingContext,
        FLOAT originX,
        FLOAT originY,
        IDWriteInlineObject* inlineObject,
        BOOL isSideways,
        BOOL isRightToLeft,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(IsPixelSnappingDisabled)(
        __maybenull void* clientDrawingContext,
        __out BOOL* isDisabled
        ) OVERRIDE;

    STDMETHOD(GetCurrentTransform)(
        __maybenull void* clientDrawingContext,
        __out DWRITE_MATRIX* transform
        ) OVERRIDE;

    STDMETHOD(GetPixelsPerDip)(
        __maybenull void* clientDrawingContext,
        __out FLOAT* pixelsPerDip
        ) OVERRIDE;

public:
    // For cached images, to avoid needing to recreate the textures each draw call.
    struct ImageCacheEntry
    {
        ImageCacheEntry(IWICBitmapSource* initialOriginal, ID2D1Bitmap* initialConverted)
        :   original(initialOriginal),
            converted(initialConverted)
        { }

        ComPtr<IWICBitmapSource> original;
        ComPtr<ID2D1Bitmap> converted;
    };

    // Just use the same brush for the same color
    struct BrushCacheEntry
    {
        BrushCacheEntry(UINT32 initialColor, ID2D1Brush* initialBrush)
        :   color(initialColor),
            brush(initialBrush)
        { }

        UINT32 color;
        ComPtr<ID2D1Brush> brush;
    };

protected:
    ID2D1Bitmap* GetCachedImage(IWICBitmapSource* image);
    ID2D1Brush*  GetCachedBrush(const DrawingEffect* effect);

protected:
    ComPtr<IDWriteFactory> dwriteFactory_;
    ComPtr<ID2D1Factory> d2dFactory_;
    ComPtr<ID2D1HwndRenderTarget> target_;

    std::vector<ImageCacheEntry> imageCache_;
    std::vector<BrushCacheEntry> brushCache_;

    HWND hwnd_;
    HMONITOR hmonitor_;
};


inline bool operator== (const RenderTargetD2D::ImageCacheEntry& entry, const IWICBitmapSource* original)
{
    return entry.original == original;
}

inline bool operator== (const RenderTargetD2D::BrushCacheEntry& entry, const DrawingEffect* effect)
{
    return entry.color == effect->GetColor();
}


////////////////////////////////////////////////////////////////////////////////

class RenderTargetDW : public RenderTarget
{
public:
    RenderTargetDW(IDWriteFactory* dwriteFactory, HWND hwnd, const RECT& rect);

    ~RenderTargetDW();

    virtual void BeginDraw() OVERRIDE;
    virtual void EndDraw() OVERRIDE;
    virtual void Clear(UINT32 color) OVERRIDE;
    virtual void Resize(UINT width, UINT height) OVERRIDE;
    virtual void UpdateMonitor() OVERRIDE;

    virtual void SetTransform(DWRITE_MATRIX const& transform) OVERRIDE;
    virtual void GetTransform(DWRITE_MATRIX& transform) OVERRIDE;
    virtual void SetAntialiasing(bool isEnabled) OVERRIDE {}

    virtual void DrawTextLayout(
        IDWriteTextLayout* textLayout,
        const RectF& rect
        ) OVERRIDE;

    virtual void DrawImage(
        IWICBitmapSource* image,
        const RectF& sourceRect,  // where in source atlas texture
        const RectF& destRect     // where on display to draw it
        ) OVERRIDE;

    void FillRectangle(
        const RectF& destRect,
        const DrawingEffect& drawingEffect
        ) OVERRIDE;

    // IDWriteTextRenderer implementation

    STDMETHOD(DrawGlyphRun)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        const DWRITE_GLYPH_RUN* glyphRun,
        const DWRITE_GLYPH_RUN_DESCRIPTION* glyphRunDescription,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawUnderline)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        const DWRITE_UNDERLINE* underline,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawStrikethrough)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        const DWRITE_STRIKETHROUGH* strikethrough,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawInlineObject)(
        __maybenull void* clientDrawingContext,
        FLOAT originX,
        FLOAT originY,
        IDWriteInlineObject* inlineObject,
        BOOL isSideways,
        BOOL isRightToLeft,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(IsPixelSnappingDisabled)(
        __maybenull void* clientDrawingContext,
        __out BOOL* isDisabled
        ) OVERRIDE;

    STDMETHOD(GetCurrentTransform)(
        __maybenull void* clientDrawingContext,
        __out DWRITE_MATRIX* transform
        ) OVERRIDE;

    STDMETHOD(GetPixelsPerDip)(
        __maybenull void* clientDrawingContext,
        __out FLOAT* pixelsPerDip
        ) OVERRIDE;

public:
    // For cached images, to avoid creating device dependent bitmaps each time.
    struct ImageCacheEntry
    {
        ImageCacheEntry(IWICBitmapSource* initialOriginal, HBITMAP initialConverted)
        :   original(initialOriginal),
            converted(initialConverted)
        { }

        ComPtr<IWICBitmapSource> original;
        HBITMAP converted;
    };

protected:
    HBITMAP GetCachedImage(IWICBitmapSource* image);

    HRESULT DrawLine(
        float baselineOriginX,
        float baselineOriginY,
        float width,
        float offset,
        float thickness,
        IUnknown* clientDrawingEffect
        );

protected:
    ComPtr<IDWriteFactory> dwriteFactory_;
    ComPtr<IDWriteGdiInterop> gdiInterop_;
    ComPtr<IDWriteBitmapRenderTarget> target_;
    ComPtr<IDWriteRenderingParams> renderingParams_;

    std::vector<ImageCacheEntry> imageCache_;

    HWND hwnd_;
    HDC memoryHdc_;
    HMONITOR hmonitor_;
};

inline bool operator== (const RenderTargetDW::ImageCacheEntry& entry, const IWICBitmapSource* original)
{
    return entry.original == original;
}
