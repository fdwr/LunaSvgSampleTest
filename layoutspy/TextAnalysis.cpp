#include "LayoutSpy.h"
#include "TextAnalysis.h"


using std::wstring;


TextAnalysis::TextAnalysis(const wstring & text, const wstring & localeName, DWRITE_READING_DIRECTION readingDirection)
      : m_text(text),
        m_localeName(localeName),
        m_readingDirection(readingDirection),
        m_analysisResults(text.size())
{
    // Make sure the locale name is NULL terminated
    m_localeName += L"\0";

    IDWriteTextAnalyzerPtr analyzer;
    TIF( g_dwrite->CreateTextAnalyzer(&analyzer) );

    TIF( analyzer->AnalyzeScript(this, 0, (UINT32) text.length(), this) );
    TIF( analyzer->AnalyzeBidi(this, 0, (UINT32) text.length(), this) );
    TIF( analyzer->AnalyzeLineBreakpoints(this, 0, (UINT32) text.length(), this) );
    // We don't do number substitution because there is no publically accessable data
}


const TextAnalysis::AnalysisResults & TextAnalysis::operator[] (size_t i) const
{
    return m_analysisResults.at(i);
}


HRESULT STDMETHODCALLTYPE TextAnalysis::QueryInterface(REFIID iid, void ** ppvObject)
{
    *ppvObject = NULL;

    if (iid == __uuidof(IUnknown))
        *ppvObject = static_cast<IUnknown *>(static_cast<IDWriteTextAnalysisSource *>(this));
    else if (iid == __uuidof(IDWriteTextAnalysisSource))
        *ppvObject = static_cast<IDWriteTextAnalysisSource *>(this);
    else if (iid == __uuidof(IDWriteTextAnalysisSink))
        *ppvObject = static_cast<IDWriteTextAnalysisSink *>(this);

    if (*ppvObject)
    {
        AddRef();
        return S_OK;
    }

    return E_NOINTERFACE;
}


ULONG STDMETHODCALLTYPE TextAnalysis::AddRef()
{
    return InterlockedIncrement(&m_refs);
}


ULONG STDMETHODCALLTYPE TextAnalysis::Release()
{
    ULONG refs = InterlockedDecrement(&m_refs);

//    if (!refs)
//        delete this;

    return refs;
}


HRESULT STDMETHODCALLTYPE TextAnalysis::GetTextAtPosition(
        UINT32 textPosition, 
        __out WCHAR const** textString, 
        __out UINT32* textLength)
{
    // AnalyseLineBreakpoints reads past the end of the buffer
    //assert(textPosition < m_text.length());

    if (textPosition >= m_text.length())
    {
        *textString = NULL;
        *textLength = 0;
        return S_OK;
    }

    *textString = &m_text[textPosition];
    *textLength = (UINT32) m_text.length() - textPosition;

    return S_OK;
}


HRESULT STDMETHODCALLTYPE TextAnalysis::GetTextBeforePosition(
        UINT32 textPosition, 
        __out WCHAR const** textString, 
        __out UINT32* textLength)
{
    assert(textPosition < m_text.length());

    *textString = &m_text[0];
    *textLength = textPosition;

    return S_OK;
}


DWRITE_READING_DIRECTION STDMETHODCALLTYPE TextAnalysis::GetParagraphReadingDirection()
{
    return m_readingDirection;
}


HRESULT STDMETHODCALLTYPE TextAnalysis::GetLocaleName(
        UINT32 textPosition, 
        __out UINT32* textLength, 
        __out_z WCHAR const** localeName)
{
    assert(textPosition < m_text.length());

    // Point directly into the buffer instead of using c_str() to ensure there
    // is no funny business with temporaries
    *localeName = m_localeName.data();
    *textLength = (UINT32) m_text.length() - textPosition;

    return S_OK;
}


HRESULT STDMETHODCALLTYPE TextAnalysis::GetNumberSubstitution(
        UINT32 textPosition, 
        __out UINT32* textLength, 
        __out IDWriteNumberSubstitution** numberSubstitution)
{
    assert(textPosition < m_text.length());
    UNREFERENCED_PARAMETER(textPosition);       // referenced in debug only

    *numberSubstitution = NULL;
    *textLength = 0;
    return E_NOTIMPL;
}


HRESULT STDMETHODCALLTYPE TextAnalysis::SetScriptAnalysis(
        UINT32 textPosition, 
        UINT32 textLength, 
        __in DWRITE_SCRIPT_ANALYSIS const* scriptAnalysis)
{
    assert(textPosition < m_analysisResults.size() && textLength <= m_analysisResults.size() - textPosition);

    for (UINT32 i = 0; i != textLength; ++i)
        m_analysisResults[textPosition + i].scriptAnalysis =  *scriptAnalysis;

    return S_OK;
}


HRESULT STDMETHODCALLTYPE TextAnalysis::SetLineBreakpoints(
        UINT32 textPosition, 
        UINT32 textLength, 
        __in_ecount(textLength) DWRITE_LINE_BREAKPOINT const* lineBreakpoints)
{
    assert(textPosition < m_analysisResults.size() && textLength <= m_analysisResults.size() - textPosition);

    for (UINT32 i = 0; i != textLength; ++i)
        m_analysisResults[textPosition + i].breakAnalysis = lineBreakpoints[i];

    return S_OK;
}


HRESULT STDMETHODCALLTYPE TextAnalysis::SetBidiLevel(
        UINT32 textPosition, 
        UINT32 textLength, 
        UINT8 explicitLevel, 
        UINT8 resolvedLevel)
{
    assert(textPosition < m_analysisResults.size() && textLength <= m_analysisResults.size() - textPosition);

    for (UINT32 i = 0; i != textLength; ++i)
    {
        m_analysisResults[textPosition + i].explicitBidiLevel = explicitLevel;
        m_analysisResults[textPosition + i].resolvedBidiLevel = resolvedLevel;
    }

    return S_OK;
}


HRESULT STDMETHODCALLTYPE TextAnalysis::SetNumberSubstitution(
        UINT32 /* textPosition */, 
        UINT32 /* textLength */, 
        __notnull IDWriteNumberSubstitution* /* numberSubstitution */)
{
    return E_NOTIMPL;
}
