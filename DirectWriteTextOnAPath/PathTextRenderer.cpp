#include "PathTextRenderer.h"
#include "TextOnAPath.h"

DWRITE_MATRIX const g_identityTransform =
    {
        1, 0,
        0, 1,
        0, 0
    };

PathTextRenderer::PathTextRenderer(FLOAT dpiScale) : 
	dpiScale_(dpiScale)
{
}

PathTextRenderer::~PathTextRenderer()
{
}

HRESULT STDMETHODCALLTYPE PathTextRenderer::DrawGlyphRun(
    void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    DWRITE_MEASURING_MODE measuringMode,
    DWRITE_GLYPH_RUN const* glyphRun,
    DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
    IUnknown* clientDrawingEffect
    )
{
    // Since we use our own custom renderer and explicitly set the effect
    // on the layout, we know exactly what the parameter is and can
    // safely cast it directly.
	PATH_TEXT_DRAWING_CONTEXT* dc = (PATH_TEXT_DRAWING_CONTEXT*) clientDrawingContext;

	// Compute the length of the geometry.
	FLOAT maxLength;
	dc->pGeometry->ComputeLength(D2D1::IdentityMatrix(), &maxLength);

	// Set up a partial glyph run that we can modify.
	DWRITE_GLYPH_RUN partialGlyphRun = *glyphRun;

	// Determine whether the text is LTR or RTL.
	BOOL leftToRight = (glyphRun->bidiLevel % 2 == 0);
	
	// Set the initial length along the path.
	FLOAT length = baselineOriginX;

	// Set the index of the first glyph in the current glyph cluster.
	UINT firstGlyphIdx = 0;
	
	while (firstGlyphIdx < glyphRun->glyphCount)
	{
		// Compute the number of glyphs in this cluster and the total cluster width.
		UINT numGlyphsInCluster = 0;
		UINT i = firstGlyphIdx;
		FLOAT clusterWidth = 0;
		while (glyphRunDescription->clusterMap[i] == glyphRunDescription->clusterMap[firstGlyphIdx] &&
			i < glyphRun->glyphCount)
		{
			clusterWidth += glyphRun->glyphAdvances[i];
			i++;
			numGlyphsInCluster++;
		}

		// Compute the cluster's midpoint along the path.
		// TODO What's preferred style for trinary operations like this?
		FLOAT midpoint = leftToRight ?
			(length + (clusterWidth / 2)) :
			(length - (clusterWidth / 2));

		// Only render this cluster if it's within the path.
		if (midpoint < maxLength)
		{
			// Compute the offset and tangent at the cluster's midpoint.
			D2D1_POINT_2F offset;
			D2D1_POINT_2F tangent;
			dc->pGeometry->ComputePointAtLength(midpoint, D2D1::IdentityMatrix(), &offset, &tangent);

			// Create a rotation matrix to align the cluster to the path.
			// TODO Since we have cos(x) and sin(x) in tangent.x and tangent.y, we should be able to create
			// the rotation matrix directly, instead of relying on atan and the Rotation helper. What is the
			// preferred approach here?
			FLOAT angle = atan(tangent.y / tangent.x) * (FLOAT) (180.0 / 3.141592653589793238); // TODO Fix divide-by-zero problem.
			D2D1_MATRIX_3X2_F rotation = D2D1::Matrix3x2F::Rotation(angle, offset);

			// Create a translation matrix to center the cluster on the tangent point.
			D2D1_MATRIX_3X2_F translation = leftToRight ?
				D2D1::Matrix3x2F::Translation(-clusterWidth/2, 0) : // LTR --> nudge it left
				D2D1::Matrix3x2F::Translation(clusterWidth/2, 0); // RTL --> nudge it right

			// Apply the transformations (in the proper order).
			dc->pRenderTarget->SetTransform(translation * rotation);

			// Draw the transformed glyph cluster.
			partialGlyphRun.glyphCount = numGlyphsInCluster;
			dc->pRenderTarget->DrawGlyphRun(
				D2D1::Point2F(offset.x, offset.y),
				&partialGlyphRun,
				dc->pBrush
				);
		}

		// Advance to the next cluster.
		length = leftToRight ? (length + clusterWidth) : (length - clusterWidth);
		partialGlyphRun.glyphIndices += numGlyphsInCluster;
		partialGlyphRun.glyphAdvances += numGlyphsInCluster;

		if (partialGlyphRun.glyphOffsets != nullptr)
		{
			partialGlyphRun.glyphOffsets += numGlyphsInCluster;
		}

		firstGlyphIdx += numGlyphsInCluster;
	}

	return S_OK;
}

HRESULT STDMETHODCALLTYPE PathTextRenderer::DrawUnderline(
    void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    DWRITE_UNDERLINE const* underline,
    IUnknown* clientDrawingEffect
    )
{
    // We don't use underline in this application.
    return E_NOTIMPL;
}

HRESULT STDMETHODCALLTYPE PathTextRenderer::DrawStrikethrough(
    void* clientDrawingContext,
    FLOAT baselineOriginX,
    FLOAT baselineOriginY,
    DWRITE_STRIKETHROUGH const* strikethrough,
    IUnknown* clientDrawingEffect
    )
{
    // We don't use strikethrough in this application.
    return E_NOTIMPL;
}

HRESULT STDMETHODCALLTYPE PathTextRenderer::DrawInlineObject(
    void* clientDrawingContext,
    FLOAT originX,
    FLOAT originY,
    IDWriteInlineObject* inlineObject,
    BOOL isSideways,
    BOOL isRightToLeft,
    IUnknown* clientDrawingEffect
    )
{
    // We don't use inline objects in this application.
    return E_NOTIMPL;
}

//
// IUnknown methods
//
//      These methods are never called in this scenario so we just use stub
//      implementations.
//
HRESULT STDMETHODCALLTYPE PathTextRenderer::QueryInterface( 
    REFIID riid,
    void** ppvObject
    )
{
    *ppvObject = NULL;
    return E_NOTIMPL;
}

ULONG STDMETHODCALLTYPE PathTextRenderer::AddRef()
{
    return 0;
}

ULONG STDMETHODCALLTYPE PathTextRenderer::Release()
{
    return 0;
}

//
// IDWritePixelSnapping::IsPixelSnappingDisabled
//
HRESULT STDMETHODCALLTYPE PathTextRenderer::IsPixelSnappingDisabled(
    void* clientDrawingContext,
    OUT BOOL* isDisabled
    )
{
    *isDisabled = FALSE;
    return S_OK;
}

//
// IDWritePixelSnapping::GetCurrentTransform
//
HRESULT STDMETHODCALLTYPE PathTextRenderer::GetCurrentTransform(
    void* clientDrawingContext,
    OUT DWRITE_MATRIX* transform
    )
{
    *transform = g_identityTransform; // TODO Not sure what to do here.
    return S_OK;
}

//
// IDWritePixelSnapping::GetPixelsPerDip
//
HRESULT STDMETHODCALLTYPE PathTextRenderer::GetPixelsPerDip(
    void* clientDrawingContext,
    OUT FLOAT* pixelsPerDip
    )
{
    *pixelsPerDip = dpiScale_ / 96.0f; // TODO Is this correct?
    return S_OK;
}