// EnumWinFonts.cpp : Defines the entry point for the console application.
//

#include "precomp.h"

template <typename T>
class ComPtr : public Microsoft::WRL::ComPtr<T>
{
public:
    operator T*() throw() { return Get(); }
};


#define IFR(hr) {HRESULT hrTemp = (hr); if (FAILED(hr)) return hr; }


std::wstring GetStringValue(IDWriteFontSet* fontSet, DWRITE_FONT_PROPERTY_ID fontPropertyId, uint32_t listIndex)
{
    std::wstring value;

    BOOL exists;
    Microsoft::WRL::ComPtr<IDWriteLocalizedStrings> stringList;
    fontSet->GetPropertyValues(listIndex, fontPropertyId, OUT &exists, OUT &stringList);
    if (stringList != nullptr && stringList->GetCount() > 0)
    {
        uint32_t stringLength = 0, localeIndex = 0;
        stringList->FindLocaleName(L"en-us", OUT &localeIndex, OUT &exists);
        localeIndex = exists ? localeIndex : 0;
        stringList->GetStringLength(localeIndex, OUT &stringLength);
        value.resize(stringLength);
        stringList->GetString(localeIndex, &value[0], stringLength + 1);
    }

    return value;
}


HRESULT GetFontFilePath(IDWriteFontFaceReference* fontFaceReference, std::wstring& filePath, uint32_t& fontFaceIndex)
try
{
    filePath.clear();
    fontFaceIndex = 0;

    ComPtr<IDWriteFontFileLoader> fontFileLoader;
    ComPtr<IDWriteFontFile> fontFile;
    ComPtr<IDWriteLocalFontFileLoader> localFontFileLoader;
    void const* fontFileReferenceKey;
    uint32_t fontFileReferenceKeySize = 0;

    fontFaceIndex = fontFaceReference->GetFontFaceIndex();

    IFR(fontFaceReference->GetFontFile(OUT &fontFile));
    IFR(fontFile->GetLoader(OUT &fontFileLoader));
    IFR(fontFileLoader.Get()->QueryInterface(__uuidof(IDWriteLocalFontFileLoader), OUT &localFontFileLoader));
    IFR(fontFile->GetReferenceKey(OUT &fontFileReferenceKey, OUT &fontFileReferenceKeySize));

    filePath.resize(1024);
    localFontFileLoader->GetFilePathFromKey(
        fontFileReferenceKey,
        fontFileReferenceKeySize,
        &filePath[0],
        uint32_t(filePath.size())
    );
    filePath.resize(wcslen(filePath.data()));

    return S_OK;
}
catch (...)
{
    return E_FAIL;
}


void PrintUsage()
{
    wprintf(
        L"Enumerates Windows fonts:\n"
        L"    EnumWinFonts [-gdi] [-dw [-typographic] [-wws]] [-minimaldisplay] [familyName]\n"
        L"\n"
        L"If family name is omitted, enumerate all families.\n"
        L"If family name is given, enumerate all faces in the family.\n"
    );
}


bool WasLaunchedFromShellOrDebugger()
{
    // Pause if launched outside a command line, such as directly from Explorer.
    // Otherwise the console window just flashes by without a chance to see the
    // error or help message.

    STARTUPINFO startupInfo = {};
    GetStartupInfo(&startupInfo);
    if (startupInfo.dwFlags & STARTF_USESHOWWINDOW)
    {
        return true;
    }

    if (IsDebuggerPresent())
    {
        return true;
    }

    return false;
}


int Main(int argc, wchar_t** argv);


int wmain(int argc, wchar_t** argv)
{
    int returnValue = Main(argc, argv);

    if (WasLaunchedFromShellOrDebugger())
    {
        wprintf(L"Press any key to end\n");
        #pragma prefast(suppress:__WARNING_RETVAL_IGNORED_FUNC_COULD_FAIL, "Q: And just what key is the 'any' key exactly? A: It doesn't matter.")
        _getch();
    }

    return returnValue;
}


int Main(int argc, wchar_t** argv)
{
    // enum all families
    wchar_t* familyName = nullptr;

    enum EnumerationApi
    {
        EnumerationApiUnspecified,
        EnumerationApiGdi,
        EnumerationApiDirectWrite,
    };
    EnumerationApi enumerationApi = EnumerationApiUnspecified;
    DWRITE_FONT_PROPERTY_ID familyFontPropertyId = DWRITE_FONT_PROPERTY_ID_WEIGHT_STRETCH_STYLE_FAMILY_NAME;
    bool showMinimalDisplay = false;

    if (argc > 1)
    {
        for (int argi = 1; argi < argc; ++argi)
        {
            auto* parameter = argv[argi];
            if (parameter[0] == L'-' || parameter[0] == L'/')
            {
                ++parameter;
                if (_wcsicmp(parameter, L"gdi") == 0)
                {
                    enumerationApi = EnumerationApiGdi;
                }
                else if (_wcsicmp(parameter, L"dw") == 0)
                {
                    enumerationApi = EnumerationApiDirectWrite;
                }
                else if (_wcsicmp(parameter, L"preferred") == 0)
                {
                    familyFontPropertyId = DWRITE_FONT_PROPERTY_ID_TYPOGRAPHIC_FAMILY_NAME;
                }
                else if (_wcsicmp(parameter, L"typographic") == 0)
                {
                    familyFontPropertyId = DWRITE_FONT_PROPERTY_ID_TYPOGRAPHIC_FAMILY_NAME;
                }
                else if (_wcsicmp(parameter, L"wws") == 0)
                {
                    familyFontPropertyId = DWRITE_FONT_PROPERTY_ID_WEIGHT_STRETCH_STYLE_FAMILY_NAME;
                }
                else if (_wcsicmp(parameter, L"win32") == 0)
                {
                    familyFontPropertyId = DWRITE_FONT_PROPERTY_ID_WIN32_FAMILY_NAME;
                }
                else if (_wcsicmp(parameter, L"fullname") == 0)
                {
                    familyFontPropertyId = DWRITE_FONT_PROPERTY_ID_FULL_NAME;
                }
                else if (_wcsicmp(parameter, L"postscript") == 0)
                {
                    familyFontPropertyId = DWRITE_FONT_PROPERTY_ID_POSTSCRIPT_NAME;
                }
                else if (_wcsicmp(parameter, L"minimaldisplay") == 0)
                {
                    showMinimalDisplay = true;
                }
                else
                {
                    PrintUsage();
                    return 1;
                }
            }
            else
            {
                familyName = parameter;
            }
        }
    }

    if (enumerationApi == EnumerationApiUnspecified)
    {
        PrintUsage();
        return 1;
    }

    uint32_t totalFonts = 0;

    if (enumerationApi == EnumerationApiGdi)
    {
        LOGFONTW logFont = {};
        logFont.lfCharSet = ANSI_CHARSET;

        if (familyName != nullptr)
        {
            wcscpy_s(logFont.lfFaceName, ARRAYSIZE(logFont.lfFaceName), familyName);
        }

        wprintf(L"GDI ----------------------------------------\n");

        struct EnumFontFamiliesParameter
        {
            uint32_t totalFonts;
            bool showMinimalDisplay;
        };
        EnumFontFamiliesParameter enumFontFamiliesParameter = {};
        enumFontFamiliesParameter.showMinimalDisplay = showMinimalDisplay;

        EnumFontFamiliesEx(
            GetDC(nullptr),
            &logFont,
            [](const LOGFONTW* logfont, const TEXTMETRIC*, DWORD, LPARAM lparam) -> int
            {
                const ENUMLOGFONTEXW *logfontEx = reinterpret_cast<const ENUMLOGFONTEXW *>(logfont);
                wprintf(L"%s\n", logfontEx->elfLogFont.lfFaceName);

                EnumFontFamiliesParameter& enumFontFamiliesParameter = *reinterpret_cast<EnumFontFamiliesParameter*>(lparam);
                if (!enumFontFamiliesParameter.showMinimalDisplay)
                {
                    wprintf(L"    FullName - %s\n", logfontEx->elfFullName);
                    wprintf(L"    Script --- %s\n", logfontEx->elfScript);
                    wprintf(L"    Style ---- %s\n", logfontEx->elfStyle);
                }

                enumFontFamiliesParameter.totalFonts++;

                return 1;
            },
            reinterpret_cast<LPARAM>(&enumFontFamiliesParameter),
            0
            );

        totalFonts = enumFontFamiliesParameter.totalFonts;
    }

    if (enumerationApi == EnumerationApiDirectWrite)
    {
        ComPtr<IDWriteFactory3> factory;
        ComPtr<IDWriteFontSet> systemFontSet;
        ComPtr<IDWriteFontSet> fontSet;
        IFR(DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(&factory), (IUnknown**)&factory));

        wprintf(L"DW -----------------------------------------\n");

        ComPtr<IDWriteFactory6> factory6;
        factory.As(OUT &factory6);
        if (factory6 == nullptr)
        {
            wprintf(L"Cannot use typographic name - need Windows 10 RS3 (IDWriteFactory6)\n");
            familyFontPropertyId = DWRITE_FONT_PROPERTY_ID_WEIGHT_STRETCH_STYLE_FAMILY_NAME;
        }

        DWRITE_FONT_PROPERTY_ID faceFontPropertyId = DWRITE_FONT_PROPERTY_ID_WEIGHT_STRETCH_STYLE_FACE_NAME;
        switch (familyFontPropertyId)
        {
        case DWRITE_FONT_PROPERTY_ID_TYPOGRAPHIC_FAMILY_NAME:
        case DWRITE_FONT_PROPERTY_ID_FULL_NAME:
        case DWRITE_FONT_PROPERTY_ID_WIN32_FAMILY_NAME:
        case DWRITE_FONT_PROPERTY_ID_POSTSCRIPT_NAME:
            faceFontPropertyId = DWRITE_FONT_PROPERTY_ID_TYPOGRAPHIC_FACE_NAME;
            break;
        case DWRITE_FONT_PROPERTY_ID_WEIGHT_STRETCH_STYLE_FAMILY_NAME:
        default:
            faceFontPropertyId = DWRITE_FONT_PROPERTY_ID_WEIGHT_STRETCH_STYLE_FACE_NAME;
        }

        IFR(factory->GetSystemFontSet(OUT &systemFontSet));
        if (familyName != nullptr)
        {
            DWRITE_FONT_PROPERTY fontProperty = { familyFontPropertyId, familyName, L"" };
            IFR(systemFontSet->GetMatchingFonts(&fontProperty, 1, OUT &fontSet));
        }
        else
        {
            fontSet = systemFontSet;
        }

        std::wstring filePath;
        totalFonts = fontSet->GetFontCount();
        for (uint32_t i = 0; i < totalFonts; ++i)
        {
            wprintf(L"%s\n", GetStringValue(fontSet, familyFontPropertyId, i).c_str());
            if (!showMinimalDisplay)
            {
                wprintf(L"    FullName --- %s\n", GetStringValue(fontSet, DWRITE_FONT_PROPERTY_ID_FULL_NAME, i).c_str());
                wprintf(L"    Face ------- %s\n", GetStringValue(fontSet, faceFontPropertyId, i).c_str());
                wprintf(L"    Postscript - %s\n", GetStringValue(fontSet, DWRITE_FONT_PROPERTY_ID_POSTSCRIPT_NAME, i).c_str());

                // Print the file and index.
                ComPtr<IDWriteFontFaceReference> fontFaceReference;
                fontSet->GetFontFaceReference(i, OUT &fontFaceReference);
                if (fontFaceReference != nullptr)
                {
                    std::wstring filePath;
                    uint32_t fontFaceIndex;
                    GetFontFilePath(fontFaceReference, OUT filePath, OUT fontFaceIndex);
                    wprintf(L"    File/Index - %s #%d\n", filePath.c_str(), fontFaceIndex);
                }
            }
        }
    }

    wprintf(L"Total fonts: %d\n", totalFonts);

    return 0;
}
