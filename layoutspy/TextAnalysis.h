class TextAnalysis : private IDWriteTextAnalysisSource, private IDWriteTextAnalysisSink
{
public:

    TextAnalysis(const std::wstring & text, const std::wstring & localeName, DWRITE_READING_DIRECTION readingDirection);

    struct AnalysisResults
    {
        DWRITE_SCRIPT_ANALYSIS  scriptAnalysis;
        UINT8                   explicitBidiLevel;
        UINT8                   resolvedBidiLevel;
        DWRITE_LINE_BREAKPOINT  breakAnalysis;
    };

    const AnalysisResults & operator[] (size_t i) const;

private:

    // IUnknown   
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void ** ppvObject) override;
    ULONG   STDMETHODCALLTYPE AddRef() override;
    ULONG   STDMETHODCALLTYPE Release() override;

    // IDWriteTextAnalysisSource
    HRESULT STDMETHODCALLTYPE GetTextAtPosition(UINT32 textPosition, __out WCHAR const** textString, __out UINT32* textLength) override;
    HRESULT STDMETHODCALLTYPE GetTextBeforePosition(UINT32 textPosition, __out WCHAR const** textString, __out UINT32* textLength) override;
    DWRITE_READING_DIRECTION STDMETHODCALLTYPE GetParagraphReadingDirection() override;
    HRESULT STDMETHODCALLTYPE GetLocaleName(UINT32 textPosition, __out UINT32* textLength, __out_z WCHAR const** localeName) override;
    HRESULT STDMETHODCALLTYPE GetNumberSubstitution(UINT32 textPosition, __out UINT32* textLength, __out IDWriteNumberSubstitution** numberSubstitution) override;

    // IDWriteTextAnalysisSink
    HRESULT STDMETHODCALLTYPE SetScriptAnalysis(UINT32 textPosition, UINT32 textLength, __in DWRITE_SCRIPT_ANALYSIS const* scriptAnalysis) override;
    HRESULT STDMETHODCALLTYPE SetLineBreakpoints(UINT32 textPosition, UINT32 textLength, __in_ecount(textLength) DWRITE_LINE_BREAKPOINT const* lineBreakpoints) override;
    HRESULT STDMETHODCALLTYPE SetBidiLevel(UINT32 textPosition, UINT32 textLength, UINT8 explicitLevel, UINT8 resolvedLevel) override;
    HRESULT STDMETHODCALLTYPE SetNumberSubstitution(UINT32 textPosition, UINT32 textLength, __notnull IDWriteNumberSubstitution* numberSubstitution) override;

    volatile LONG                m_refs;             
    std::wstring                 m_text;
    std::wstring                 m_localeName;
    DWRITE_READING_DIRECTION     m_readingDirection;
    std::vector<AnalysisResults> m_analysisResults;
};