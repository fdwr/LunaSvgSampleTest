#include "LayoutSpy.h"
#include "LayoutRecorder.h"

using std::wstring;
using std::vector;


GlyphRun::GlyphRun(
        size_t runIndex,
        float baselineOriginX,
        float baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        __in const DWRITE_GLYPH_RUN * glyphRun,
        __in const DWRITE_GLYPH_RUN_DESCRIPTION * glyphRunDescription)
      : runIndex(runIndex),
        baselineOriginX(baselineOriginX),
        baselineOriginY(baselineOriginY),
        measuringMode(measuringMode),
        text(glyphRunDescription->string, glyphRunDescription->string + glyphRunDescription->stringLength),
        textPosition(glyphRunDescription->textPosition),
        fontEmSize(glyphRun->fontEmSize),
        fontFace(glyphRun->fontFace),
        clusterMap(glyphRunDescription->clusterMap, glyphRunDescription->clusterMap + glyphRunDescription->stringLength),
        glyphIndices(glyphRun->glyphIndices, glyphRun->glyphIndices + glyphRun->glyphCount),
        glyphAdvances(glyphRun->glyphAdvances, glyphRun->glyphAdvances + glyphRun->glyphCount),
        glyphOffsets(glyphRun->glyphOffsets, glyphRun->glyphOffsets + (glyphRun->glyphOffsets ? glyphRun->glyphCount : 0)),
        isSideways(!!glyphRun->isSideways),
        bidiLevel(glyphRun->bidiLevel),
        localeName(glyphRunDescription->localeName)
{
}


void LayoutRecorder::UpdateGlyphRuns(
        IDWriteTextLayout * layout, 
        ID2D1RenderTarget * renderTarget)
{
    glyphRuns.clear();

    TIF( layout->Draw(renderTarget, this, 0, 0) );
}


LayoutRecorder::LayoutRecorder()
      : m_refs(1)
{
}


LayoutRecorder::~LayoutRecorder()
{
}


HRESULT STDMETHODCALLTYPE LayoutRecorder::QueryInterface(REFIID iid, void ** ppvObject)
{
    *ppvObject = NULL;

    if (   iid == __uuidof(IUnknown)
        || iid == __uuidof(IDWritePixelSnapping)
        || iid == __uuidof(IDWriteTextRenderer))
    {
        *ppvObject = this;
        AddRef();
        return S_OK;
    }

    return E_NOINTERFACE;
}


ULONG STDMETHODCALLTYPE LayoutRecorder::AddRef()
{
    return InterlockedIncrement(&m_refs);
}


ULONG STDMETHODCALLTYPE LayoutRecorder::Release()
{
    ULONG refs = InterlockedDecrement(&m_refs);

//    if (!refs)
//        delete this;

    return refs;
}


HRESULT STDMETHODCALLTYPE LayoutRecorder::IsPixelSnappingDisabled(
        __maybenull void* /* clientDrawingContext */, 
        __out BOOL* isDisabled)
{
    *isDisabled = false;
    return S_OK;
}


HRESULT STDMETHODCALLTYPE LayoutRecorder::GetCurrentTransform(
        __maybenull void* /* clientDrawingContext */, 
        __out DWRITE_MATRIX* transform)
{
    static const DWRITE_MATRIX identity = {1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f};

    *transform = identity;
    return S_OK;
}


HRESULT STDMETHODCALLTYPE LayoutRecorder::GetPixelsPerDip(
        __maybenull void* clientDrawingContext, 
        __out FLOAT* pixelsPerDip)
{
    assert(clientDrawingContext);
    ID2D1RenderTarget * renderTarget = reinterpret_cast<ID2D1RenderTarget *>(clientDrawingContext);

    float dpiX, dpiY;
    renderTarget->GetDpi(&dpiX, &dpiY);
    assert(dpiX == dpiY);

    *pixelsPerDip = dpiY / 96.0f;
    return S_OK;
}


HRESULT STDMETHODCALLTYPE LayoutRecorder::DrawGlyphRun(
        __maybenull void* /* clientDrawingContext */, 
        FLOAT baselineOriginX, 
        FLOAT baselineOriginY, 
        DWRITE_MEASURING_MODE measuringMode, 
        __in DWRITE_GLYPH_RUN const* glyphRun, 
        __in DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription, 
        __maybenull IUnknown* /* clientDrawingEffect */)
{
    glyphRuns.push_back(
                    GlyphRun(
                            glyphRuns.size(), 
                            baselineOriginX, 
                            baselineOriginY, 
                            measuringMode, 
                            glyphRun, 
                            glyphRunDescription));
    return S_OK;
}


HRESULT STDMETHODCALLTYPE LayoutRecorder::DrawUnderline(
        __maybenull void* /* clientDrawingContext */, 
        FLOAT /* baselineOriginX */, 
        FLOAT /* baselineOriginY */, 
        __in DWRITE_UNDERLINE const* /* underline */, 
        __maybenull IUnknown* /* clientDrawingEffect */)
{
    return S_OK;
}


HRESULT STDMETHODCALLTYPE LayoutRecorder::DrawStrikethrough(
        __maybenull void* /* clientDrawingContext */, 
        FLOAT /* baselineOriginX */, 
        FLOAT /* baselineOriginY */, 
        __in DWRITE_STRIKETHROUGH const* /* strikethrough */, 
        __maybenull IUnknown* /* clientDrawingEffect */)
{
    return S_OK;
}


HRESULT STDMETHODCALLTYPE LayoutRecorder::DrawInlineObject(
        __maybenull void* /* clientDrawingContext */, 
        FLOAT /* originX */, 
        FLOAT /* originY */, 
        IDWriteInlineObject* /* inlineObject */, 
        BOOL /* isSideways */, 
        BOOL /* isRightToLeft */, 
        __maybenull IUnknown* /* clientDrawingEffect */)
{
    return S_OK;
}

