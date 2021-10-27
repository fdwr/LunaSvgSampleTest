#include <SDKDDKVer.h>
#include <stdint.h>
#include <stdio.h>
#include <conio.h>
#include <tchar.h>
#include <shlobj.h>
#include <stdio.h>
#include <shobjidl.h>
#include <objbase.h>
#include <atlbase.h>
#include <string>

/*
  This function launches your app using IApplicationActivationManager.

  Parameters:
    appUserModelId - appUserModelId of the app to launch.
    processId - Output argument that receives the process id of the launched app.

  Returns:
    HRESULT indicating success/failure
*/
HRESULT LaunchApp(std::wstring const& appUserModelId, _Out_ DWORD* processId)
{
    CComPtr<IApplicationActivationManager> spAppActivationManager;
    HRESULT hrResult = E_INVALIDARG;
    if (!appUserModelId.empty())
    {
        // Instantiate IApplicationActivationManager
        hrResult = CoCreateInstance(CLSID_ApplicationActivationManager,
            nullptr,
            CLSCTX_LOCAL_SERVER,
            IID_IApplicationActivationManager,
            (LPVOID*)&spAppActivationManager
        );

        wprintf(L"CoCreateInstance CLSID_ApplicationActivationManager = 0x%08X\r\n", hrResult);

        if (SUCCEEDED(hrResult))
        {
            // This call ensures that the app is launched as the foreground window
            hrResult = CoAllowSetForegroundWindow(spAppActivationManager, nullptr);
            wprintf(L"CoAllowSetForegroundWindow = 0x%08X\r\n", hrResult);
            
            // Launch the app
            if (SUCCEEDED(hrResult))
            {
                hrResult = spAppActivationManager->ActivateApplication(appUserModelId.c_str(),
                    nullptr,
                    AO_NONE,
                    processId
                    );
                wprintf(L"IApplicationActivationManager::ActivateApplication = 0x%08X\r\n", hrResult);
            }
        }
    }

    return hrResult;
}

int _tmain(int argc, _TCHAR* argv[])
{
    HRESULT hrResult = S_OK;
    if (SUCCEEDED(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED)))
    {
        std::wstring appUserModelId;
        for (int i = 1; i < argc; ++i)
        {
            auto* param = argv[i];
            if (param[0] == '/' || param[0] == '-')
            {
                if (wcscmp(param, L"/wait") == 0)
                {
                    wprintf(L"Press a key to continue.");
                    _getch();
                }
                else
                {
                    hrResult = E_INVALIDARG;
                }
            }
            else
            {
                appUserModelId = param;
                DWORD processId = 0;
                hrResult = LaunchApp(appUserModelId, OUT &processId);
                wprintf(L"Result = 0x%08X\r\n", hrResult);
            }
        }

        if (appUserModelId.empty())
        {
            hrResult = E_INVALIDARG;
            wprintf(
                L"Launches a Metro app by Ashwin Needamangala, Principal Test Lead, Windows.\r\n"
                L"Uses IApplicationActivationManager::ActivateApplication and CoAllowSetForegroundWindow.\r\n"
                L"http://blogs.msdn.com/b/windowsappdev/archive/2012/09/04/automating-the-testing-of-windows-8-apps.aspx\r\n"
                L"\r\n"
                L"Example usage:\r\n"
                L"  LaunchMetroApp.exe Microsoft.BingNews_8wekyb3d8bbwe!AppexNews\r\n"
                L"  LaunchMetroApp.exe Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe!App\r\n"
                L"  LaunchMetroApp.exe FileManager_cw5n1h2txyewy!Microsoft.Windows.FileManager\r\n"
                L"  LaunchMetroApp.exe /wait Facebook.Facebook_8xx8rvfyw5nnt!App /wait Microsof...\r\n"
                L"  LaunchMetroApp.exe Microsoft.Office.Word_8wekyb3d8bbwe!microsoft.word\r\n"
                );
        }

        CoUninitialize();
    }

    return hrResult;
}
