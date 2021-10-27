// cl /EHsc /O2 EnumSystemLocalesEx.cpp
// chcp 1252
#include <windows.h>
#include <iostream>
#include <vector>
#include <algorithm>
#include <iomanip>

using namespace std;


struct LocaleEntry
{
    DWORD flags;    // LOCALE_WINDOWS, LOCALE_SUPPLEMENTAL, etc.
    wstring localeName;    // "af-ZA", etc.
    wstring displayName;    // "Afrikaans (South Africa)", etc.
    wstring languageName;    // "Afrikaans", etc.
    wstring countryName;    // "South Africa", etc.
    LocaleEntry(DWORD dwFlags, LPWSTR lpLocaleString, LPWSTR display, LPWSTR language, LPWSTR country)
    {
        flags = dwFlags;
        localeName.assign(lpLocaleString);
        displayName.assign(display);
        languageName.assign(language);
        countryName.assign(country);
    }
};
vector<LocaleEntry> locales;

bool LocaleEntryPredicate(LocaleEntry entry1, LocaleEntry entry2)
{
    return entry1.localeName.compare(entry2.localeName) <= 0;
}

BOOL CALLBACK EnumLocalesProcEx(LPWSTR lpLocaleString, DWORD dwFlags, LPARAM lParam)
{
    ////wcout << "In EnumLocalesProcEx() callback: " << lpLocaleString << endl;
    const int bufferSize = 128;
    wchar_t display[bufferSize], language[bufferSize], country[bufferSize];
    int success;
    // LCTYPE constants from \\shindex\fbl_dgt_dev2\sdpublic\sdk\inc\winnls.h
    ////success = GetLocaleInfoEx(lpLocaleString, 0x00000072 /*LOCALE_SENGLISHDISPLAYNAME*/, display, bufferSize);
    ////if (success == 0)
    ////{
    ////    wcout << L"Error calling GetLocaleInfoEx()!" << endl;
    ////    exit(-2);
    ////}
    success = GetLocaleInfoEx(lpLocaleString, 0x00001001 /*LOCALE_SENGLISHLANGUAGENAME*/, language, bufferSize);
    if (success == 0)
    {
        wcout << L"Error calling GetLocaleInfoEx()!" << endl;
        exit(-2);
    }
    success = GetLocaleInfoEx(lpLocaleString, 0x00001002 /*LOCALE_SENGLISHCOUNTRYNAME*/, country, bufferSize);
    if (success == 0)
    {
        wcout << L"Error calling GetLocaleInfoEx()!" << endl;
        exit(-2);
    }
    // Normally, we'd pass dwFlags, but for some reason, dwFlags == 33 on Windows 7; pass lParam instead:
    locales.push_back(LocaleEntry(static_cast<DWORD>(lParam), lpLocaleString, L"", language, country));
    return TRUE;    // continue enumeration when called from EnumSystemLocalesEx()
}

wstring FlagsString(DWORD dwFlags)
{
    switch (dwFlags)
    {
    case LOCALE_WINDOWS:
        return L"Win";
    case LOCALE_SUPPLEMENTAL:
        return L"Sup";
    case LOCALE_ALTERNATE_SORTS:
        return L"Alt";
    }
    return L"Unknown";
}

void CheckReturnCode(BOOL success, DWORD dwFlags)
{
    if (success == FALSE)
    {
        wcout << L"EnumSystemLocalesEx(" << FlagsString(dwFlags).c_str() << L") ";
        switch (GetLastError())
        {
        case ERROR_INVALID_PARAMETER:
            wcout << L"returned ERROR_INVALID_PARAMETER." << endl << endl;
            break;
        case ERROR_BADDB :
            wcout << L"returned ERROR_BADDB." << endl << endl;
            break;
        case ERROR_INVALID_FLAGS:
            wcout << L"returned ERROR_INVALID_FLAGS." << endl << endl;
            break;
        default:
            wcout << L"returned an unknown error code." << endl << endl;
        }
        exit(-1);
    }
    else
    {
        ////wcout << L"EnumSystemLocalesEx(" << FlagsString(dwFlags).c_str() << L") completed successfully." << endl << endl;
    }
}

int wmain()
{
    // Enumerate all locales
    BOOL success;
    success = EnumSystemLocalesEx(EnumLocalesProcEx, LOCALE_WINDOWS, static_cast<LPARAM>(LOCALE_WINDOWS), NULL);
    CheckReturnCode(success, LOCALE_WINDOWS);
    success = EnumSystemLocalesEx(EnumLocalesProcEx, LOCALE_SUPPLEMENTAL, static_cast<LPARAM>(LOCALE_SUPPLEMENTAL), NULL);
    CheckReturnCode(success, LOCALE_SUPPLEMENTAL);
    success = EnumSystemLocalesEx(EnumLocalesProcEx, LOCALE_ALTERNATE_SORTS, static_cast<LPARAM>(LOCALE_ALTERNATE_SORTS), NULL);
    CheckReturnCode(success, LOCALE_ALTERNATE_SORTS);

    sort(locales.begin(), locales.end(), LocaleEntryPredicate);

    for (vector<LocaleEntry>::const_iterator cit = locales.begin(); cit != locales.end(); ++cit)
    {
        wcout << left << FlagsString(cit->flags).c_str() << L"\t"
            << setw(13) << cit->localeName.c_str() << L"\t"
            << setw(34) << cit->languageName.c_str() << L"\t"
            << cit->countryName.c_str() << endl;
    }

    return 0;
}
