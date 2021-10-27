//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Render target for controls to draw to.
//
//----------------------------------------------------------------------------
#pragma once


struct ID2D1HwndRenderTarget;
struct ID2D1Bitmap;
class InlineImage;
class DrawingEffect;

////////////////////////////////////////////////////////////////////////////////

struct Position
{
    union {float x,l;}; // x/left
    union {float y,t;}; // y/top
    union {float w,r;}; // width/right
    union {float h,b;}; // height/bottom

    bool Contains(float ptX, float ptY) const throw()
    {
        return ptX >= x && ptY >= y && ptX < x + w && ptY < y + h;
    }

    inline bool SizeDiffers(const Position& other) const throw()
    {
        return w != other.w || h != other.h;
    }

    inline void SetZero()
    {
        x = y = w = h = 0;
    }
};

struct MakePosition : public Position
{
    inline MakePosition(float newX, float newY, float newW, float newH)
    {
        x = newX; y = newY; w = newW; h = newH;
    }
};

inline bool operator ==(const Position& a, const Position& b)
{
    return a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h;
}

inline bool operator !=(const Position& a, const Position& b)
{
    return !(a == b);
}


////////////////////////////////////////////////////////////////////////////////

class RenderTarget;

// Intermediate render target for UI to draw to either a D2D or GDI surface.
class DECLSPEC_UUID("4327AC14-3172-4807-BF40-02C7475A2520") RenderTarget : public ComBase<IDWriteTextRenderer>
{
public:
    virtual void DrawText(
        __in_ecount(textLength) const wchar_t* text,
        size_t textLength,
        __maybenull IDWriteTextFormat* textFormat,
        __maybenull DrawingEffect* drawingEffect,
        const Position& rect
        ) = NULL;

    virtual void DrawTextLayout(
        __in IDWriteTextLayout* textLayout,
        const Position& rect
        ) = NULL;

    // Draws a single image, from the given coordinates, to the given coordinates.
    // If the height and width differ, they will be scaled, but mirroring must be
    // done via a matrix transform.
    virtual void DrawImage(
        IWICBitmapSource* image,
        const Position& sourceRect,  // where in source atlas texture
        const Position& destRect     // where on display to draw it
        ) = NULL;

    // Draws the nine sections of an image (for UI controls), consisting of four
    // corners, four midsections, and the center, plus a relative offset.
    virtual void DrawNineGridImage(
        IWICBitmapSource* image,
        const Position sourceRects[3],  // positioning in source atlas texture
        const Position& destRect        // where on display to draw it
        ) = NULL;

    virtual void Resize(UINT width, UINT height) = NULL;
    virtual void BeginDraw() = NULL;
    virtual void EndDraw() = NULL;
    virtual void Clear() = NULL;
    virtual void Flush() = NULL;

    virtual void PushClipRect(const Position& rect) = NULL;
    virtual void PopClipRect() = NULL;
    virtual void SetTransform(DWRITE_MATRIX const& transform) = NULL;
    virtual void GetTransform(DWRITE_MATRIX& transform) = NULL;

    STDMETHOD(QueryInterface)(IID const& iid, __out void** object) OVERRIDE
    {
        COM_BASE_RETURN_INTERFACE(iid, RenderTarget, object);
        COM_BASE_RETURN_INTERFACE(iid, IDWriteTextRenderer, object);
        COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
        COM_BASE_RETURN_NO_INTERFACE(object);
    }

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

class UiRenderTargetD2D : public RenderTarget
{
public:
    enum Mode
    {
        ModeNeutral,
        ModeSoftware,
        ModeHardware,
    };

    UiRenderTargetD2D(ID2D1Factory* d2dFactory, IDWriteFactory* dwriteFactory, HWND hwnd, const RECT& rect, Mode = ModeNeutral);

    virtual void DrawText(
        __in_ecount(textLength) const wchar_t* text,
        size_t textLength,
        __maybenull IDWriteTextFormat* textFormat,
        __maybenull DrawingEffect* drawingEffect,
        const Position& rect
        ) OVERRIDE;

    virtual void DrawTextLayout(
        __in IDWriteTextLayout* textLayout,
        const Position& rect
        ) OVERRIDE;

    virtual void DrawImage(
        IWICBitmapSource* image,
        const Position& sourceRect,  // where in source atlas texture
        const Position& destRect     // where on display to draw it
        ) OVERRIDE;

    virtual void DrawNineGridImage(
        IWICBitmapSource* image,
        const Position sourceRects[3],  // positioning in source atlas texture
        const Position& destRect        // where on display to draw it
        ) OVERRIDE;

    virtual void Resize(UINT width, UINT height) OVERRIDE;
    virtual void BeginDraw() OVERRIDE;
    virtual void EndDraw() OVERRIDE;
    virtual void Clear() OVERRIDE;
    virtual void Flush() OVERRIDE;

    virtual void PushClipRect(const Position& rect) OVERRIDE;
    virtual void PopClipRect() OVERRIDE;
    virtual void SetTransform(DWRITE_MATRIX const& transform) OVERRIDE;
    virtual void GetTransform(DWRITE_MATRIX& transform) OVERRIDE;

    // IDWriteTextRenderer implementation

    STDMETHOD(DrawGlyphRun)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        __in DWRITE_GLYPH_RUN const* glyphRun,
        __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawUnderline)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        __in DWRITE_UNDERLINE const* underline,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawStrikethrough)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        __in DWRITE_STRIKETHROUGH const* strikethrough,
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
    ID2D1Brush*  GetCachedBrush(DrawingEffect* effect);

protected:
    ComPtr<IDWriteFactory> dwriteFactory_;
    ComPtr<ID2D1Factory> d2dFactory_;
    ComPtr<ID2D1HwndRenderTarget> target_;

    ComPtr<IDWriteTextFormat> defaultTextFormat_;
    ComPtr<DrawingEffect> defaultDrawingEffect_;

    std::vector<ImageCacheEntry> imageCache_;
    std::vector<BrushCacheEntry> brushCache_;
};


inline bool operator== (const UiRenderTargetD2D::ImageCacheEntry& entry, const IWICBitmapSource* original)
{
    return entry.original == const_cast<IWICBitmapSource*>(original);
}

inline bool operator== (const UiRenderTargetD2D::BrushCacheEntry& entry, const DrawingEffect* effect)
{
    return entry.color == effect->GetColor();
}


////////////////////////////////////////////////////////////////////////////////

class UiRenderTargetDW : public RenderTarget
{
public:
    UiRenderTargetDW(HDC hdc, IDWriteFactory* dwriteFactory, const RECT& rect);

    ~UiRenderTargetDW();

    virtual void DrawText(
        __in_ecount(textLength) const wchar_t* text,
        size_t textLength,
        __maybenull IDWriteTextFormat* textFormat,
        __maybenull DrawingEffect* drawingEffect,
        const Position& rect
        ) OVERRIDE;

    virtual void DrawTextLayout(
        __in IDWriteTextLayout* textLayout,
        const Position& rect
        ) OVERRIDE;

    virtual void DrawImage(
        IWICBitmapSource* image,
        const Position& sourceRect,  // where in source atlas texture
        const Position& destRect     // where on display to draw it
        ) OVERRIDE;

    virtual void DrawNineGridImage(
        IWICBitmapSource* image,
        const Position sourceRects[3],  // positioning in source atlas texture
        const Position& destRect        // where on display to draw it
        ) OVERRIDE;

    virtual void Resize(UINT width, UINT height) OVERRIDE;
    virtual void BeginDraw() OVERRIDE;
    virtual void EndDraw() OVERRIDE;
    virtual void Clear() OVERRIDE;
    virtual void Flush() OVERRIDE;

    virtual void PushClipRect(const Position& rect) OVERRIDE;
    virtual void PopClipRect() OVERRIDE;
    virtual void SetTransform(DWRITE_MATRIX const& transform) OVERRIDE;
    virtual void GetTransform(DWRITE_MATRIX& transform) OVERRIDE;

    // IDWriteTextRenderer implementation

    STDMETHOD(DrawGlyphRun)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        __in DWRITE_GLYPH_RUN const* glyphRun,
        __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawUnderline)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        __in DWRITE_UNDERLINE const* underline,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawStrikethrough)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        __in DWRITE_STRIKETHROUGH const* strikethrough,
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

    HDC GetMemoryDC()
    {
        // Used by profiling code to render to DIB (without displaying to screen)
        return target_->GetMemoryDC();
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
    HDC hdc_, memoryHdc_;

    ComPtr<IDWriteTextFormat> defaultTextFormat_;
    ComPtr<DrawingEffect> defaultDrawingEffect_;

    std::vector<ImageCacheEntry> imageCache_;
    std::vector<Position> clipRects_;
};

inline bool operator== (const UiRenderTargetDW::ImageCacheEntry& entry, const IWICBitmapSource* original)
{
    return entry.original == const_cast<IWICBitmapSource*>(original);
}


////////////////////////////////////////////////////////////////////////////////

class UiRenderTargetGDI : public UiRenderTargetDW
{
public:
    typedef UiRenderTargetDW Base;

    UiRenderTargetGDI(HDC hdc, IDWriteFactory* dwriteFactory, const RECT& rect);
    ~UiRenderTargetGDI();

    virtual void DrawText(
        __in_ecount(textLength) const wchar_t* text,
        size_t textLength,
        __maybenull IDWriteTextFormat* textFormat,
        __maybenull DrawingEffect* drawingEffect,
        const Position& rect
        ) OVERRIDE;

    virtual void DrawTextLayout(
        __in IDWriteTextLayout* textLayout,
        const Position& rect
        ) OVERRIDE;


    // IDWriteTextRenderer implementation

    STDMETHOD(DrawGlyphRun)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        __in DWRITE_GLYPH_RUN const* glyphRun,
        __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

private:
    ComPtr<IDWriteFontFace> lastUsedFont_;
    HFONT cachedGdiFont_;

    void ClearCachedFont()
    {
        lastUsedFont_.Clear();
        if (cachedGdiFont_ != NULL)
        {
            DeleteObject(cachedGdiFont_);
            cachedGdiFont_ = NULL;
        }
    }
};


////////////////////////////////////////////////////////////////////////////////

class UiRenderTargetGDIPlus : public UiRenderTargetDW
{
public:
    typedef UiRenderTargetDW Base;

    UiRenderTargetGDIPlus(HDC hdc, IDWriteFactory* dwriteFactory, const RECT& rect);

    ~UiRenderTargetGDIPlus();

    virtual void BeginDraw() OVERRIDE;
    virtual void EndDraw() OVERRIDE;
    virtual void SetTransform(DWRITE_MATRIX const& transform) OVERRIDE;
    virtual void PushClipRect(const Position& rect) OVERRIDE;
    virtual void PopClipRect() OVERRIDE;

    virtual void DrawText(
        __in_ecount(textLength) const wchar_t* text,
        size_t textLength,
        __maybenull IDWriteTextFormat* textFormat,
        __maybenull DrawingEffect* drawingEffect,
        const Position& rect
        ) OVERRIDE;

    virtual void DrawTextLayout(
        __in IDWriteTextLayout* textLayout,
        const Position& rect
        ) OVERRIDE;


    // IDWriteTextRenderer implementation

    STDMETHOD(DrawGlyphRun)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        __in DWRITE_GLYPH_RUN const* glyphRun,
        __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

private:
    ULONG_PTR gdiplusToken_;
    Gdiplus::Graphics* graphics_;
};


////////////////////////////////////////////////////////////////////////////////

class UiRenderTargetNullDraw : public UiRenderTargetDW
{
public:
    typedef UiRenderTargetDW Base;

    UiRenderTargetNullDraw(HDC hdc, IDWriteFactory* dwriteFactory, const RECT& rect);

    // IDWriteTextRenderer implementation

    STDMETHOD(DrawGlyphRun)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        __in DWRITE_GLYPH_RUN const* glyphRun,
        __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawUnderline)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        __in DWRITE_UNDERLINE const* underline,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(DrawStrikethrough)(
        __maybenull void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        __in DWRITE_STRIKETHROUGH const* strikethrough,
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
};
