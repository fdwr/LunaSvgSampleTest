// InstallFontFile.cpp : Defines the entry point for the console application.
//

#include "precomp.h"


HRESULT InstallFontFile(
    HWND hwndParent,
    LPCWSTR pszPath,
    BOOL fCopyFiles
);


using PFNINSTALLFONTFILES = HRESULT(*)(HWND, PCWSTR, BOOL);
PFNINSTALLFONTFILES g_pfnInstallFontFile = nullptr; // pointer to the install method in fontext.dll
HMODULE g_hFontextDll; // Don't mind if leaked in tiny console app.


HRESULT InitializeFontextDll()
{
    HRESULT hr = E_FAIL;
    if (!g_hFontextDll)
    {
        g_hFontextDll = LoadLibraryW(L"fontext.dll");
        if (g_hFontextDll != nullptr)
        {
            // Initalize the InstallFontFile function exported from fontext.dll  
            g_pfnInstallFontFile = (PFNINSTALLFONTFILES)GetProcAddress(g_hFontextDll, "InstallFontFile");

            if (g_pfnInstallFontFile)
            {
                hr = S_OK;
            }
        }
    }
    return hr;
}


int main()
{
    __debugbreak();
    InitializeFontextDll();
    g_pfnInstallFontFile(/*hwnd*/ nullptr, L"D:\\fonts\\Aegyptus.otf", /*shouldCopyFile*/ false);

    return 0;
}
