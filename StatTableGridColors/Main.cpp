/************************************************************************
2021-10-27
************************************************************************/

#include "Main.h"
#include "App.h"

/******************************************************************
*                                                                 *
*  WinMain                                                        *
*                                                                 *
*  Application entrypoint                                         *
*                                                                 *
******************************************************************/

int WINAPI wWinMain(
    HINSTANCE hInstance,
    HINSTANCE hPrevInstance,
    LPWSTR lpCmdLine,
    int nCmdShow
    )
{
    HRESULT hr;

    hr = CoInitialize(nullptr);

    // Higher priority gives less variance due to other processes
    // interfering with timings.
    if (GetPriorityClass(GetCurrentProcess()) == NORMAL_PRIORITY_CLASS)
        SetPriorityClass(GetCurrentProcess(), ABOVE_NORMAL_PRIORITY_CLASS);

    if (SUCCEEDED(hr))
    {
        {
            DemoApp demoApp;

            hr = demoApp.Initialize();

            if (SUCCEEDED(hr))
            {
                MSG msg;

                while (GetMessage(&msg, nullptr, 0, 0) > 0)
                {
                    TranslateMessage(&msg);
                    DispatchMessage(&msg);
                }
            }
        }
        CoUninitialize();
    }

    return SUCCEEDED(hr) ? EXIT_SUCCESS : EXIT_FAILURE;
}
