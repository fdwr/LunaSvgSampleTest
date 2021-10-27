//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Font String Perf test app.
//
//  Author:     Dwayne Robinson (dwayner@microsoft.com)
//
//  History:    2012-09-12   dwayner    Created
//
//----------------------------------------------------------------------------
#pragma once


class MainWindow
{
public:
    enum PerfGrouping
    {
        PerfGroupingNone   = 0x0000,
        PerfGroupingFont   = 0x0001,
        PerfGroupingFile   = 0x0002,
        PerfGroupingString = 0x0004,
    };

    enum PerfMeasurementType
    {
        PerfMeasurementTypeLayout  = 0x0001,
        PerfMeasurementTypeShaping = 0x0002,
        PerfMeasurementTypeDefault = PerfMeasurementTypeLayout|PerfMeasurementTypeShaping,
    };

protected:
    HWND hwnd_;
    int currentPaneId_;
    HACCEL accelTable_;
    std::wstring cachedLog_;
    uint32_t newestFontInfoId_;
    HANDLE profilingThread_;
    CRITICAL_SECTION profilingThreadLock_;
    bool preventListViewRecursion_;     // is there really no way to disable the listview from calling back to you with state changes?
    bool skipPartialCoverageFonts_;  // don't profile a font that doesn't fully support the current string
    bool insideAutomatedAction_;
    uint32_t automatedActionIndex_;
    uint32_t perfGrouping_;
    PerfMeasurementType perfMeasurementType_;

public:
    struct FontInfo
    {
        std::wstring familyName;
        std::wstring styleName;
        std::wstring filePath;
        uint32_t faceIndex;
        DWRITE_FONT_WEIGHT weight;
        DWRITE_FONT_STRETCH stretch;
        DWRITE_FONT_STYLE style;
        bool isSelected;
        uint32_t id;

        FontInfo()
        :   faceIndex(),
            weight(),
            stretch(),
            style(),
            isSelected(),
            id()
        { }

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

        bool operator < (const FontInfo& other) const
        {
            int comparison = CompareStrings(familyName, other.familyName);
            if (comparison  != CSTR_EQUAL       )   return comparison == CSTR_LESS_THAN;

            comparison = CompareStrings(styleName, other.styleName);
            if (comparison  != CSTR_EQUAL       )   return comparison == CSTR_LESS_THAN;

            // We'll allow the files to remain in addition order.
            // comparison = CompareStrings(filePath, other.filePath);
            // if (comparison  != CSTR_EQUAL       )   return comparison == CSTR_LESS_THAN;

            if (faceIndex   != other.faceIndex  )   return faceIndex  < other.faceIndex;
            if (weight      != other.weight     )   return weight     < other.weight;
            if (stretch     != other.stretch    )   return stretch    < other.stretch;
            if (style       != other.style      )   return style      < other.style;
            if (isSelected  != other.isSelected )   return isSelected > other.isSelected; // favor selected items
            return id < other.id;
        }

        bool operator == (const FontInfo& other) const
        {
            return familyName == other.familyName
                && styleName  == other.styleName
                && faceIndex  == other.faceIndex
                && weight     == other.weight
                && stretch    == other.stretch
                && style      == other.style
                && CompareStrings(filePath, other.filePath) == CSTR_EQUAL;
            // do not compare isSelected or id
        }

        bool IsSameFont(const FontInfo& other) const
        {
            // Checks not for exact equality, but whether or not it's another
            // instance of the same font (possibly a different file version though).
            return familyName == other.familyName
                && styleName  == other.styleName;
        }
    };

    struct StringInfo
    {
        std::wstring description;
        std::wstring sample;
        uint32_t coverageCount;
        uint32_t maxCoverageCount;
        bool isSelected;
        bool isSimple;

        StringInfo()
        :   isSelected(false),
            isSimple(false),
            coverageCount(-1),
            maxCoverageCount()
        { }
    };

    struct PerfTime
    {
        unsigned int iterations;
        unsigned int milliseconds;

        PerfTime() : iterations(0), milliseconds(0)
        {}

        PerfTime(unsigned initialIterations, unsigned initialMilliseconds)
        :   iterations(initialIterations),
            milliseconds(initialMilliseconds)
        {}

        static PerfTime Min()
        {
            return PerfTime(0, 0);
        }

        static PerfTime Max()
        {
            return PerfTime(UINT32_MAX, UINT32_MAX);
        }

        void Clear()
        {
            iterations   = 0;
            milliseconds = 0;
        }

        void PreventDivisionByZero()
        {
            if (iterations   <= 0) iterations   = 1;
            if (milliseconds <= 0) milliseconds = 1;
        }

        float Seconds() const throw()
        {
            return float(milliseconds) / 1000;

        }

        float SecondsPerIteration() const throw()
        {
            return float(milliseconds) / float(iterations) / 1000;
        }

        float IterationsPerSecond() const throw()
        {
            return float(iterations) * 1000 / float(milliseconds);
        }

        float IsEmpty() const throw()
        {
            return iterations == 0 && milliseconds == 0;
        }

        bool IsDone(const PerfTime& limit) const throw()
        {
            // Either reached desired number of iterations
            // or number of milliseconds to profile.
            return this->iterations   >= limit.iterations
                || this->milliseconds >= limit.milliseconds;
        }

        // Advance the next update time if we passed it, using the updateFrequency (in milliseconds).
        bool AdvanceIfNeeded(const PerfTime& time, unsigned int updateFrequency)
        {
            if (time.milliseconds >= this->milliseconds)
            {
                this->milliseconds = std::max(this->milliseconds + updateFrequency, time.milliseconds);
                return true;
            }
            return false;
        }

        PerfTime& operator +=(const PerfTime& time)
        {
            this->milliseconds += time.milliseconds;
            this->iterations   += time.iterations;
            return *this;
        }

        void TakeMax(const PerfTime& time)
        {
            if (time.milliseconds > this->milliseconds) this->milliseconds = time.milliseconds;
            if (time.iterations   > this->iterations)   this->iterations   = time.iterations;
        }

        void TakeMin(const PerfTime& time)
        {
            if (time.milliseconds < this->milliseconds) this->milliseconds = time.milliseconds;
            if (time.iterations   < this->iterations)   this->iterations   = time.iterations;
        }
    };

    struct ProfileResult
    {
        uint32_t stringIndex;
        uint32_t fontIndex;
        PerfTime layout;
        PerfTime shaping;
    };

    struct ProfileAggregateResult
    {
        PerfTime layoutSlowest;
        PerfTime layoutFastest;
        PerfTime shapingSlowest;
        PerfTime shapingFastest;
    };

    struct GlyphShapingRunCache
    {
        std::wstring recordedText;
        std::vector<uint16_t> clusterMap;
        std::vector<uint16_t> glyphIds;
        std::vector<float> glyphAdvances;
        std::vector<DWRITE_GLYPH_OFFSET> glyphOffsets;
        std::vector<DWRITE_SHAPING_GLYPH_PROPERTIES> glyphProperties;
        std::vector<DWRITE_SHAPING_TEXT_PROPERTIES> textProperties;
        std::vector<DWRITE_TYPOGRAPHIC_FEATURES> features;
        std::vector<DWRITE_FONT_FEATURE> featureSet;
        std::vector<uint32_t> featureLengths;
        std::vector<DWRITE_TYPOGRAPHIC_FEATURES const*> pointersToFeatures;
    };

    interface IFontLookupPrinter;

    struct KeyValuePair
    {
        std::wstring key;
        std::wstring value;
        uint32_t level;

        KeyValuePair()
        :   level()
        { }

        void Clear()
        {
            key.clear();
            value.clear();
            level = 0;
        }
    };

    enum IdentifyLookupsOption
    {
        IdentifyLookupsOptionAll,       // All lookups found in the font.
        IdentifyLookupsOptionSimple,    // Only lookups that interact with simple characters.
        IdentifyLookupsOptionStrings,   // Lookups that interact with the selected strings.
        IdentifyLookupsOptionFeatures,  // Lookups that are part of the selected features.
    };


public:
    std::vector<FontInfo> fontsList_;
    std::vector<StringInfo> stringsList_;
    std::vector<uint32_t> fontFeatures_;
    std::vector<KeyValuePair> automatedActions_;

////////////////////////////////////////
// Windowing related.

public:
    MainWindow(HWND hwnd);

    ~MainWindow();

    static void RegisterCustomClasses();

    static INT_PTR CALLBACK StaticDialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    static INT_PTR CALLBACK StaticSubDialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

private:
    DialogProcResult CALLBACK DialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    DialogProcResult CALLBACK SubDialogProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

    void Resize(int id);
    void SelectCurrentPane(int newCurrentPane, bool shouldSetKeyFocus = false);
    HWND GetSubdialogItem(int dialogId, int childId);
    HWND GetPaneList(int paneId);
    HWND GetCurrentPaneList();
    int GetCurrentPaneDefaultId();
    int GetCommandPaneId(int commandId);

////////////////////////////////////////
// Public.

public:
    bool Initialize(__in_z const wchar_t* options);
    bool ParseAutomatedActions(
        __in_z const wchar_t* options,
        OUT std::vector<KeyValuePair>& keyValues
        );
    bool ProcessNextAutomatedAction();
    void LogUnexpectedAutomatedAction(const KeyValuePair& action);
    HRESULT ExecuteSelectedAutomatedAction();
    HRESULT StartAutomatedActions();
    HRESULT PauseAutomatedActions();
    HRESULT StopAutomatedActions();
    HRESULT LoadAutomatedActionsFile();
    void UpdateActionsListUi();

    std::vector<ComPtr<IDWriteFontFace> > GetSelectedFontFaces();
    bool HandleListViewSelectionChange(
        UINT code,
        LPARAM lParam,
        std::function<void(uint32_t start, uint32_t end, bool state)> f
        );
    HRESULT LoadSystemFont();
    HRESULT LoadAllSystemFonts();
    HRESULT LoadFontFiles();
    HRESULT LoadFontFiles(
        __in_z const wchar_t* fileDirectory,
        __in __nullnullterminated const wchar_t* fileNames
        );
    uint32_t AppendCollectionToFontsList(
        IDWriteFontCollection* fontCollection,
        __in_z const wchar_t* filePath,
        bool shouldSelectFiles,
        bool shouldIncludeSimulations = false
        );
    uint32_t AppendFontToFontsList(
        IDWriteFont* font,
        __in_z const wchar_t* filePath,
        bool shouldSelectFiles,
        uint32_t familyIndex
        );
    uint32_t AppendFontToFontsList(
        IDWriteFont* font,
        __in_z const wchar_t* filePath,
        bool shouldSelectFiles,
        const std::wstring& familyNames,
        uint32_t familyIndex,
        uint32_t fontIndex
        );
    HRESULT LoadSystemFileFromLogFont(LOGFONT const& logFont);
    void RemoveDuplicateInFontsList();
    void UpdateFontsListUi(uint32_t idToScrollTo = -1);
    uint32_t GetFontsListSelectionCount();
    uint32_t GetStringsListSelectionCount();
    bool EnsureUiConditionTrue(
        bool condition,
        const wchar_t* message,
        uint32_t paneId = -1
        );
    void ResetDefaultStringsList();
    void UpdateStringsListUi(uint32_t indexToScrollTo = -1);
    std::wstring GetSelectedStringsText(const wchar_t* separator);
    void UpdateTextFromSelectedStrings();
    void CopyAllFontCharacters();
    HRESULT ProfileStart();
    HRESULT ProfileStop(bool shouldTerminateIfNeeded = false);
    bool ProfileIsDone();
    static DWORD WINAPI StaticProfilingThreadEntry(void* threadParameter);
    DWORD WINAPI ProfilingThread();
    bool SendMessageFromProfilingThread(UINT message, const void* data);
    static HRESULT ProfileLayout(
        const wchar_t* text,
        uint32_t textLength,
        IDWriteTextFormat* textFormat,
        __in_opt IDWriteTypography* typography
        );
    static HRESULT ProfileShaping(
        IDWriteTextAnalyzer* textAnalyzer,
        TextAnalysis& textAnalysis,
        float fontEmSize,
        const std::vector<uint32_t>& fontFeatures,
        __inout GlyphShapingRunCache& shapingRunCache
        );
    HRESULT IdentifyLookups(
        IdentifyLookupsOption option
        );
    HRESULT SelectFontsSupportingCharacters();
    HRESULT SelectFontsSupportingCharacters(
        __in_ecount(utf32textLength) char32_t const* utf32text,
        __in uint32_t utf32textLength
        );
    HRESULT SelectDuplicateFonts(
        bool selection, // select or deselect
        bool selectAllDuplicatesOfAGroup
        );

////////////////////////////////////////
// Generic public.

public:
    void AppendLogCached(const wchar_t* logMessage, ...);
    void AppendLog(const wchar_t* logMessage, ...);
    void ClearLog();
    void SetProgress(uint32_t value, uint32_t total);

    static void Format(__out std::wstring& returnString, const wchar_t* formatString, ...);
    static void Append(__inout std::wstring& returnString, const wchar_t* formatString, ...);
    static void Format(__inout std::wstring& returnString, bool shouldConcatenate, const wchar_t* formatString, va_list vargs);

////////////////////////////////////////
// Internal functions.

private:
    INT_PTR CALLBACK InitializeMainDialog(HWND hwnd);
    INT_PTR CALLBACK InitializeFontsListDialog(HWND hwnd);
    INT_PTR CALLBACK InitializeStringsListDialog(HWND hwnd);
    INT_PTR CALLBACK InitializePerfScoreDialog(HWND hwnd);
    INT_PTR CALLBACK InitializeLookupsListDialog(HWND hwnd);
    INT_PTR CALLBACK InitializeActionsListDialog(HWND hwnd);
    INT_PTR CALLBACK InitializeHelpDialog(HWND hwnd);
    INT_PTR CALLBACK InitializeMessageDialog(HWND hwnd);
    DialogProcResult CALLBACK ProcessCommand(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    DialogProcResult CALLBACK ProcessNotification(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
    DialogProcResult CALLBACK ProcessDragAndDrop(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
};
