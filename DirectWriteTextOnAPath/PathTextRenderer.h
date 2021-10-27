#pragma once

#include <dwrite.h>
#include <d2d1.h>

struct PATH_TEXT_DRAWING_CONTEXT
{
	ID2D1RenderTarget* pRenderTarget;
	ID2D1Geometry* pGeometry;
	ID2D1Brush* pBrush;
};

class PathTextRenderer : public IDWriteTextRenderer
{
public:
	PathTextRenderer(FLOAT dpiScale);
	~PathTextRenderer();

	// IDWriteTextRenderer methods
    IFACEMETHOD(DrawGlyphRun)(
        void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        DWRITE_GLYPH_RUN const* glyphRun,
        DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
        IUnknown* clientDrawingEffect
        );

    IFACEMETHOD(DrawUnderline)(
        void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        DWRITE_UNDERLINE const* underline,
        IUnknown* clientDrawingEffect
        );

    IFACEMETHOD(DrawStrikethrough)(
        void* clientDrawingContext,
        FLOAT baselineOriginX,
        FLOAT baselineOriginY,
        DWRITE_STRIKETHROUGH const* strikethrough,
        IUnknown* clientDrawingEffect
        );

    IFACEMETHOD(DrawInlineObject)(
        void* clientDrawingContext,
        FLOAT originX,
        FLOAT originY,
        IDWriteInlineObject* inlineObject,
        BOOL isSideways,
        BOOL isRightToLeft,
        IUnknown* clientDrawingEffect
        );

	// IDWritePixelSnapping methods
    IFACEMETHOD(IsPixelSnappingDisabled)(
        void* clientDrawingContext,
        OUT BOOL* isDisabled
        );
    IFACEMETHOD(GetCurrentTransform)(
        void* clientDrawingContext,
        OUT DWRITE_MATRIX* transform
        );
    IFACEMETHOD(GetPixelsPerDip)(
        void* clientDrawingContext,
        OUT FLOAT* pixelsPerDip
        );

	// IUnknown methods
    IFACEMETHOD(QueryInterface)( 
        REFIID riid,
        void** ppvObject
        );
    IFACEMETHOD_(ULONG, AddRef)();
    IFACEMETHOD_(ULONG, Release)();

private:
	FLOAT dpiScale_;
};
