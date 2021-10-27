#pragma once

interface DWRITE_DECLARE_INTERFACE("28D5197F-3940-4535-B315-E327E13D845B") IDWriteTextFormatDebug : public IUnknown
{
    STDMETHOD(SetForceSlowPath)(BOOL force = true) PURE;
    STDMETHOD_(BOOL, GetForceSlowPath)() PURE;
    STDMETHOD(SetForceReshape)(BOOL force = true) PURE;
    STDMETHOD_(BOOL, GetForceReshape)() PURE;
    STDMETHOD(SetDisableFontFallback)(BOOL disableFontFallback = true) PURE;
    STDMETHOD_(BOOL, GetDisableFontFallback)() PURE;
};

inline void ForceSlowLayout(IDWriteTextFormat* textFormat)
{
    // Force full text analysis (no faster shortcuts).
    ComPtr<IDWriteTextFormatDebug> debugFormat;
    textFormat->QueryInterface(__uuidof(IDWriteTextFormatDebug), (void**)&debugFormat);
    if (debugFormat != nullptr)
    {
        debugFormat->SetForceSlowPath(true);
    }
}
