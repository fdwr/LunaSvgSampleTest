#include <windows.h>
#include <windowsx.h>
#include <DWrite_1.h>
#include <limits.h>
#include <conio.h> // wait for keypress
#include <math.h>
#include <exception>
#include <iostream>
#include <iomanip>
#include <vector>
#include <shlwapi.h>
#include <stdint.h>

#include "Common.h"
#include "AutoResource.h"
#include "ByteOrder.h"
#include "ArrayRef.h"
#include "OpenTypeDefs.h"
#include "OpenTypeFaceData.h"
#include "FileHelpers.h"

using namespace std;

////////////////////////////////////////////////////////////////////////////////


// The C++0x keyword is supported in Visual Studio 2010
#if _MSC_VER < 1600
#ifndef nullptr
#define nullptr 0
#endif
#endif


#define IFR(exp) {hr = (exp); if (FAILED(hr)) return hr;}

struct SetAndSaveConsoleColor
{
    CONSOLE_SCREEN_BUFFER_INFO consoleInfo_;
    HANDLE hConsole_;

    SetAndSaveConsoleColor(WORD foregroundColor)
    {
        hConsole_ = GetStdHandle(STD_OUTPUT_HANDLE);
        GetConsoleScreenBufferInfo(hConsole_, &consoleInfo_);
        WORD attributes = consoleInfo_.wAttributes & 0xFFF0;
        attributes |= (foregroundColor & 0x000F);
        SetConsoleTextAttribute(hConsole_, attributes);
    }

    ~SetAndSaveConsoleColor()
    {
        SetConsoleTextAttribute(hConsole_, consoleInfo_.wAttributes);
    }
};


////////////////////////////////////////////////////////////////////////////////

IDWriteFactory* g_dwriteFactory = nullptr;
u16string       g_dwriteDllName = u"dwrite.dll";
u16string       g_fontSearchPath;
u16string       g_fontSearchMask = u"*.ttf;*.ttc;*.otf;*.ttc;*.tte";
uint32_t        g_fontTableTag = 'ESAB';
bool            g_onlyShowMatches = false;

////////////////////////////////////////////////////////////////////////////////

void InitializeDWrite()
{
    HMODULE dwriteModule = LoadLibrary(ToWChar(g_dwriteDllName.c_str()));
    if (dwriteModule == nullptr)
        throw runtime_error(__FUNCTION__ " - Unable to load dwrite.dll");

    // Display the DLL used for profiling.
    char16_t dllFilePath[MAX_PATH];
    dllFilePath[0] = '\0';

    GetModuleFileName(
        dwriteModule,
        ToWChar(dllFilePath),
        ARRAYSIZE(dllFilePath)
        );
    // wcout << "Using DWrite DLL: " << dllFilePath << endl;

    typedef HRESULT (__stdcall DWriteCreateFactory_t)(
        __in DWRITE_FACTORY_TYPE,
        __in REFIID,
        __out IUnknown**
        );

    DWriteCreateFactory_t* factoryFunction = (DWriteCreateFactory_t*) GetProcAddress(dwriteModule, "DWriteCreateFactory");
    if (factoryFunction == nullptr)
        throw runtime_error(__FUNCTION__ " - Unable to lookup DWriteCreateFactory");

    // Use an isolated factory to prevent polluting the global cache.
    if (FAILED(factoryFunction(
            DWRITE_FACTORY_TYPE_ISOLATED,
            __uuidof(IDWriteFactory),
            (IUnknown **) &g_dwriteFactory))
            )
    {
        throw runtime_error(__FUNCTION__ " - Unable to create DWrite factory");
    }
}


void FinalizeDWrite()
{
    if (g_dwriteFactory != nullptr)
        g_dwriteFactory->Release();

    // Note that DWrite may still hold onto a singleton,
    // so we must forcibly unload the DLL itself to *truly*
    // release resources. Calling Release an extra call
    // would result in a crash.
    FreeLibrary(GetModuleHandle(ToWChar(g_dwriteDllName.c_str())));
}


HRESULT CreateFontFaceFromFile(
    __in_z char16_t const* filePath,
    __out IDWriteFontFace** fontFace,
    DWRITE_FONT_SIMULATIONS fontSimulations
    )
{
    // Creates a font face with the typical defaults (1 file).
    HRESULT hr = S_OK;

    ComPtr<IDWriteFontFile> fontFile;
    IFR(g_dwriteFactory->CreateFontFileReference(
        ToWChar(filePath),
        NULL,
        &fontFile
        ));

    IDWriteFontFile* fontFileArray[] = {fontFile};

    BOOL isSupportedFontType;
    DWRITE_FONT_FILE_TYPE fontFileType;
    DWRITE_FONT_FACE_TYPE fontFaceType;
    uint32_t numberOfFaces;
    IFR(fontFile->Analyze(
        &isSupportedFontType,
        &fontFileType,
        &fontFaceType,
        &numberOfFaces
        ));

    ComPtr<IDWriteFontFace> fontFace0;
    IFR(g_dwriteFactory->CreateFontFace(
        fontFaceType,
        1, // file count
        fontFileArray,
        0, // file's face index
        fontSimulations,
        &fontFace0
        ));

    *fontFace = fontFace0.Detach();

    return hr;
}


HRESULT EnumerateFonts()
{
    HRESULT hr = S_OK;

    std::u16string fileNames;
    IFR(EnumerateMatchingFiles(
        g_fontSearchPath.data(),
        g_fontSearchMask.data(),
        OUT fileNames
        ));

    char16_t const* fileName = fileNames.data();
    char16_t const* fileNameEnd = fileName + fileNames.size();

    for (; fileName < fileNameEnd && fileName[0] != '\0'; fileName += wcslen(ToWChar(fileName)) + 1)
    {
        ComPtr<IDWriteFontFace> fontFace;
        CreateFontFaceFromFile(
            fileName,
            OUT &fontFace,
            DWRITE_FONT_SIMULATIONS_NONE
            );

        bool fontMatched = false;
        uint32_t tableSize = 0;
        if (fontFace == nullptr)
        {
            if (!g_onlyShowMatches)
            {
                SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_INTENSITY);
                wprintf(L"** failed to load ** ");
            }
        }
        else
        {
            {
                __bcount(*tableSize) const void* tableData = nullptr;
                void* tableContext = nullptr;
                BOOL dummy = false;

                fontFace->TryGetFontTable(g_fontTableTag, &tableData, &tableSize, &tableContext, &dummy);
                if (tableData != nullptr)
                {
                    fontMatched = true;
                }

                fontFace->ReleaseFontTable(tableContext);
            }
        }

        if (fontMatched || !g_onlyShowMatches)
        {
            wprintf(L"%s", ToWChar(fileName));

            if (fontMatched)
            {
                SetAndSaveConsoleColor cc(FOREGROUND_GREEN | FOREGROUND_INTENSITY);

                char16_t tag[5] = {((g_fontTableTag >>  0) & 255),
                    ((g_fontTableTag >>  8) & 255),
                    ((g_fontTableTag >> 16) & 255),
                    ((g_fontTableTag >> 24) & 255),
                    0
                };

                wprintf(L" %s, %d bytes", ToWChar(tag), tableSize);
            }
            wprintf(L"\n");
        }
    } // for

    return hr;
}


u16string UnescapeString(u16string str)
{
    u16string replacement;

    for (size_t i = 0; i < str.size(); ++i)
    {
        if (str[i] == '\\')
        {
            char16_t* text = const_cast<char16_t*>(str.c_str());
            char16_t* escapeStart = text + i;
            char16_t* escapeEnd = escapeStart + 1;
            replacement.assign(u"\\", 1);

            switch (*escapeEnd)
            {
            case u'r':
                replacement = u'\r';
                ++escapeEnd;
                break;

            case u'n':
                replacement = u'\n';
                ++escapeEnd;
                break;

            case u't':
                replacement = u'\t';
                ++escapeEnd;
                break;

            case u'x':
            case u'u':
            case u'U':
                replacement = static_cast<char16_t>(wcstoul(ToWChar(escapeStart + 2), ToWChar(&escapeEnd), 16));
                break;

            case u'0': case u'1': case u'2': case u'3': case u'4':
            case u'5': case u'6': case u'7': case u'8': case u'9':
                // Support decimal here (octal is not supported)
                replacement = static_cast<char16_t>(wcstoul(ToWChar(escapeStart + 1), ToWChar(&escapeEnd), 10));
                break;
            }

            str.replace(escapeStart - text, escapeEnd - escapeStart, replacement);
            i += replacement.size() - 1;
        }
    }

    return str;
}


void ShowHelp()
{
    //       [---0----][---1----][---2----][---3----][---4----][---5----][---6----][---7----]
    cout << "fonttablesearch [tag] [options]" << endl
         << endl
         << "where [tag] is the tag of the OpenType table to search for." << endl
         << endl
         << "Options:" << endl
         << "    -help            - display this message" << endl
         << "    -path:...        - absolute or relative path to search (** to recurse)" << endl
         << "    -mask:...        - filename mask to search (; to separate)" << endl
         << "    -onlyshowmatches - show only matching filenames" << endl
         << endl
         << "Example usage:" << endl
         << "    fonttablesearch BASE" << endl
         << "    fonttablesearch EBLC -mask:*.ttc;*.otc" << endl
         << "    fonttablesearch OS/2 -mask:Arial*;*Roman.?t?" << endl
         << "    fonttablesearch SVG -path:d:\\fonts\\**\\color\\**\\ -onlyshowmatches" << endl
         << endl;
}


bool ProcessCommandLine(int argCount, __ecount(argCount) LPWSTR argv[])
{
    if (argCount <= 1 || argv[1] == nullptr)
    {
        {
            SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY);
            cout << "Specify a table name..." << endl
                 << endl;
        }
        ShowHelp();
        return false;
    }

    for (int i = 1; i < argCount; ++i)
    {
        if (argv[i][0] != '-' && argv[i][0] != '/')
        {
            u16string text = UnescapeString(ToChar16(argv[i]));
            if (text.length() < 1)
            {
                wcout << "The table tag must be at least one character: " << argv[i] << endl;
                return false;
            }
            // Some tags are only three characters, like 'CFF', so add extra spaces if needed.
            text.resize(4, ' ');
            g_fontTableTag = (text[0] << 0) | (text[1] << 8) | (text[2] << 16) | (text[3] << 24);
            continue;
        }

        if (wcsncmp(&argv[i][1], L"path:", 5) == 0)
        {
            g_fontSearchPath = ToChar16(&argv[i][1] + 5);
        }
        else if (wcsncmp(&argv[i][1], L"mask:", 5) == 0)
        {
            g_fontSearchMask = ToChar16(&argv[i][1] + 5);
        }
        else if (wcscmp(&argv[i][1], L"onlyshowmatches") == 0)
        {
            g_onlyShowMatches = true;
        }
        else if (wcscmp(&argv[i][1], L"help") == 0 || wcscmp(&argv[i][1], L"?") == 0)
        {
            ShowHelp();
            return false;
        }
        else
        {
            ShowHelp();

            SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_INTENSITY);
            wcout << "Unrecognized parameter: " << argv[i] << endl;
            return false;
        }
    }
    return true;
}


bool WasLaunchedFromShell()
{
    // Pause if launched outside a command line,
    // including directly from Explorer or Visual Studio.
    // Otherwise the console window just flashes by
    // without a chance to see the error or help message.

    STARTUPINFO startupInfo = {};
    GetStartupInfo(&startupInfo);
    if (startupInfo.dwFlags & STARTF_USESHOWWINDOW)
    {
        return true;
    }
    return false;
}


int __cdecl wmain(int argCount, __ecount(argCount) LPWSTR argv[])
{
    if (!ProcessCommandLine(argCount, argv))
    {
        if (WasLaunchedFromShell())
        {
            #pragma prefast(disable:__WARNING_RETVAL_IGNORED_FUNC_COULD_FAIL, "Q: And, um, just what key is the 'any' key exactly? A: It doesn't matter.")
            _getch();
        }

        exit(0);
    }

    try
    {
        InitializeDWrite();
        EnumerateFonts();
    }
    catch (exception const& e)
    {
        SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_INTENSITY);
        cerr << "Error: " << e.what() << endl;
    }

    if (WasLaunchedFromShell())
    {
        cout << "Press any key to end" << endl;
        #pragma prefast(suppress: __WARNING_RETVAL_IGNORED_FUNC_COULD_FAIL);
        _getch();
    }

    FinalizeDWrite();
}
