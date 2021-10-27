// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// Copyright (c) Microsoft Corporation. All rights reserved
//
// Contents:    Main user interface window.
//
//----------------------------------------------------------------------------
#pragma once


class MainWindow
{
public:
    MainWindow(HWND hwnd);
    HRESULT Initialize();
    static WPARAM RunMessageLoop();

    static ATOM RegisterWindowClass();
    static INT_PTR CALLBACK StaticDialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    DialogProcResult CALLBACK DialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

    STDMETHODIMP ApplyLogFontFilter(const LOGFONT& logFont);

public:
    const static wchar_t* g_windowClassName;

    enum class FontCollectionFilterMode
    {
        None, // Display all font face references without any grouping.

        // Modes that have a 1:1 correspondence with DWRITE_FONT_PROPERTY_ID.
        FamilyName,
        PreferredFamilyName,
        FaceName,
        FullName,
        Win32FamilyName,
        PostscriptName,
        DesignedScriptTag,
        SupportedScriptTag,
        SemanticTag,
        Weight,
        Stretch,
        Style,

        Total,

        // Future property.
        OpticalRange,
    };

    enum class FontFamilyModel
    {
        Preferred,
        WWS,
        Win32,
        Flat,
        Total,
    };

    struct AxisValue
    {
        uint32_t axisTag;
        float value;
        std::wstring name;
    };

protected:
    struct FontEntry
    {
        std::wstring preferredFamilyName;
        std::vector<AxisValue> axisValues;

        // Cached values just for simplicity of creating a text layout.
        std::wstring wwsFamilyName;
        DWRITE_FONT_WEIGHT fontWeight;  // = DWRITE_FONT_WEIGHT_NORMAL;
        DWRITE_FONT_STRETCH fontStretch;// = DWRITE_FONT_STRETCH_NORMAL;
        DWRITE_FONT_STYLE fontStyle;    // = DWRITE_FONT_STYLE_NORMAL;
    };

    struct FontListItem
    {
        std::wstring name;              // Name of the entry, depending on the property type (current filter mode).
        uint32_t firstFontIndex;        // Index of the first font for this entry.

        int CompareStrings(const std::wstring& a, const std::wstring& b) const
        {
            return ::CompareStringW(
                LOCALE_INVARIANT,
                NORM_IGNORECASE,
                a.c_str(),
                static_cast<int32_t>(a.length()),
                b.c_str(),
                static_cast<int32_t>(b.length())
                );
        }

        bool operator < (const FontListItem& other)
        {
            int comparison;
            comparison = CompareStrings(name, other.name);
            if (comparison  != CSTR_EQUAL) return comparison == CSTR_LESS_THAN;

            return firstFontIndex < other.firstFontIndex;
        }
    };

    struct FontCollectionFilter
    {
        FontCollectionFilterMode mode;
        uint32_t selectedFontIndex; // Previous font collection index used when applying this filter.
        std::wstring parameter;
    };

protected:
    void OnSize();
    void OnMove();
    DialogProcResult CALLBACK OnCommand(HWND hwnd, WPARAM wParam, LPARAM lParam);
    DialogProcResult CALLBACK OnNotification(HWND hwnd, WPARAM wParam, LPARAM lParam);
    void OnKeyDown(UINT keyCode);
    void OnMenuPopup(HMENU menu, UINT position, BOOL isSystemWindowMenu);
    void MarkNeedsRepaint();
    bool ProcessCommandLine(_In_z_ const wchar_t* commandLine);
    static void ShowHelp();
    STDMETHODIMP ParseCommandLine(_In_z_ const wchar_t* commandLine);

    STDMETHODIMP OnChooseFont();
    STDMETHODIMP ChooseColor(IN OUT uint32_t& color);
    STDMETHODIMP CopyToClipboard(bool copyPlainText = false);
    STDMETHODIMP CopyImageToClipboard();
    STDMETHODIMP PasteFromClipboard();
    STDMETHODIMP InitializeLanguageMenu();
    STDMETHODIMP InitializeFontFacesListUI();
    STDMETHODIMP InitializeFontFamiliesListUI();
    STDMETHODIMP UpdateFontFacesListUI(uint32_t newSelectedItem = 0);
    STDMETHODIMP UpdateFontFamiliesListUI();
    STDMETHODIMP RebuildFontFacesList();
    STDMETHODIMP DrawFontCollectionIconPreview(const NMLVCUSTOMDRAW* customDraw);

    STDMETHODIMP GetFontProperty(
        IDWriteFont* font,
        FontCollectionFilterMode filterMode,
        wchar_t const* languageName,
        _Out_ std::wstring& fontPropertyValue,
        _Out_ std::vector<std::pair<uint32_t,uint32_t> >& fontPropertyValueTokens
        );

    STDMETHODIMP AddFontToFontCollectionList(
        IDWriteFont* font,
        uint32_t firstFontIndex,
        _In_z_ wchar_t const* languageName,
        const std::wstring& name
        );

    bool DoesFontFilterApply(
        FontCollectionFilterMode filterMode,
        const std::wstring& filterParameter,
        const std::wstring& fontPropertyValue,
        const std::vector<std::pair<uint32_t, uint32_t> > fontPropertyValueTokens
        );

    bool SplitFontProperty(
        FontCollectionFilterMode filterMode,
        const std::wstring& fontPropertyValue,
        OUT std::vector<std::wstring>& fontPropertyValueArray
        );

    HRESULT SetCurrentFilter(
        FontCollectionFilterMode filterMode_ = FontCollectionFilterMode::None
        );

    HRESULT SetFontFamilyModel(
        FontFamilyModel newFontFamilyModel
        );

    HRESULT SetSelectedFamily(
        _In_z_ wchar_t const* familyName
        );

    HRESULT PushFilter(
        uint32_t selectedFontIndex // Must be < fontCollectionList_.size()
        );

    HRESULT PopFilter(
        uint32_t newFilterLevel
        );

    HRESULT CreateDefaultFontSet();

    void AppendLogCached(const wchar_t* logMessage, ...);
    void AppendLog(const wchar_t* logMessage, ...);

protected:
    HWND hwnd_ = nullptr;
    HMONITOR hmonitor_ = nullptr;
    HMODULE dwriteModule_ = nullptr;
    HIMAGELIST fontCollectionImageList_ = nullptr;

    ComPtr<IDWriteFactory>              dwriteFactory_;
    ComPtr<IDWriteRenderingParams>      renderingParams_;
    ComPtr<IDWriteBitmapRenderTarget>   renderTarget_;
    ComPtr<IDWriteFontCollection>       fontCollection_;
    ComPtr<IDWriteTextFormat>           textFormat_;
    ComPtr<IDWriteFontSet>              fontSet_;
    ComPtr<ID2D1Factory>                d2dFactory_;
    ComPtr<ID2D1DCRenderTarget>         renderTargetD2D_;
    ComPtr<ID2D1SolidColorBrush>        brushD2D_;
    IDWriteFontCollection*              previousFontCollection_ = nullptr; // weak pointer - no strong ref

    uint32_t fontColor_ = 0xFF000000;
    uint32_t backgroundColor_ = 0xFFFFFFFF;
    uint32_t highlightColor_ = 0xFFFFFFFF;
    uint32_t highlightBackgroundColor_ = 0xFFFF0000;
    uint32_t faintSelectionColor_ = 0xFF808080;
    uint32_t currentLanguageIndex_ = 0; // English US
    bool includeRemoteFonts_ = true;

    std::vector<FontEntry> fontEntries_;
    std::vector<FontListItem> fontFacesList_;
    std::vector<FontListItem> fontFamiliesList_;
    std::wstring cachedLog_;
    std::wstring selectedFontFamilyName_;
    FontFamilyModel fontFamilyModel_ = FontFamilyModel::Preferred;
    //--std::map<std::wstring, uint32_t> fontCollectionListStringMap_;
    //--FontCollectionFilterMode filterMode_ = FontCollectionFilterMode::None;

private:
    // No copy construction allowed.
    MainWindow(const MainWindow& b);
    MainWindow& operator=(const MainWindow&);
public:
    ~MainWindow();
};
