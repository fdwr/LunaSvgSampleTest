//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Text Layout test app.
//
//  Author:     Dwayne Robinson (dwayner@microsoft.com)
//
//  History:    2008-02-11   dwayner    Created
//
//----------------------------------------------------------------------------
#include "precomp.h"

#include "../resources/resource.h"

////////////////////////////////////////
// UI related

#pragma prefast(disable:__WARNING_HARD_CODED_STRING_TO_UI_FN, "It's an internal test program.")

HRESULT CreateDirectWriteFactory();
HRESULT UnloadDirectWriteFactory();


HINSTANCE Application::g_hModule = nullptr;
ModuleHandle Application::g_DWriteModule;
ComPtr<IDWriteFactory> Application::g_DWriteFactory;
MSG Application::g_msg;
HWND Application::g_mainHwnd;


////////////////////////////////////////

int APIENTRY wWinMain(
    __in HINSTANCE      hInstance, 
    __in_opt HINSTANCE  hPrevInstance,
    __in LPWSTR         commandLine,
    __in int            nCmdShow
    )
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(commandLine);

    Application::g_hModule = hInstance;

    ////////////////////
    // Read command line parameters.

    std::wstring trimmedCommandLine(commandLine);
    TrimSpaces(IN OUT trimmedCommandLine);

    if (!trimmedCommandLine.empty())
    {
        if (_wcsicmp(trimmedCommandLine.c_str(), L"/?"    ) == 0
        ||  _wcsicmp(trimmedCommandLine.c_str(), L"/help" ) == 0
        ||  _wcsicmp(trimmedCommandLine.c_str(), L"-h"    ) == 0
        ||  _wcsicmp(trimmedCommandLine.c_str(), L"--help") == 0
            )
        {
            MessageBox(nullptr, L"FontStringPerf.exe [actions=actionsfile.txt] [moreactions ...]\r\n\r\nSee help page for list of actions.", APPLICATION_TITLE, MB_OK);
            return (int)0;
        }
        else if (trimmedCommandLine[0] == '/')
        {
            Application::Fail(trimmedCommandLine.c_str(), L"Unknown command line option.\r\n\r\n\"%s\"", 0);
        }
        // Else just pass the command line to the main window.
    }

    ////////////////////
    // Create the factory for further testing.

    HRESULT hr;

    hr = CreateDirectWriteFactory();
    if (FAILED(hr))
    {
        Application::Fail(L"Could not create DirectWrite factory", nullptr, hr);
    }

    ////////////////////
    // Create user interface elements.

    MainWindow::RegisterCustomClasses();
    Application::g_mainHwnd = CreateDialog(Application::g_hModule, MAKEINTRESOURCE(IddMainWindow), nullptr, &MainWindow::StaticDialogProc);

    if (Application::g_mainHwnd == nullptr)
    {
        Application::Fail(L"Could not create main window.", L"%s", 0);
    }

    ShowWindow(Application::g_mainHwnd, SW_SHOWNORMAL);

    MainWindow& mainWindow = *GetClassFromWindow<MainWindow>(Application::g_mainHwnd);
    if (mainWindow.Initialize(trimmedCommandLine.c_str()))
    {
        // Always shows the focus rectangle.
        SendMessage(Application::g_mainHwnd, WM_CHANGEUISTATE, UIS_CLEAR | UISF_HIDEACCEL | UISF_HIDEFOCUS, (LPARAM)NULL);

        while (GetMessage(&Application::g_msg, nullptr, 0, 0) > 0)
        {
            Application::Dispatch();
        }
    }

    UnloadDirectWriteFactory();

    return (int)0;
}


void Application::Dispatch()
{
    // Fixup any messages.
    switch (Application::g_msg.message)
    {
    case WM_MOUSEWHEEL:
        // Mouse wheel messages inconsistently go to the control with
        // keyboard focus instead of mouse focus, unlike every other
        // mouse message. So fix it to behave more sensibly like IE.
        POINT pt = {GET_X_LPARAM(Application::g_msg.lParam), GET_Y_LPARAM(Application::g_msg.lParam)};
        HWND mouseHwnd = WindowFromPoint(pt);
        if (mouseHwnd != nullptr)
        {
            // Don't send to a different process by mistake.
            DWORD pid = 0;
            if (GetWindowThreadProcessId(mouseHwnd, &pid) == GetCurrentThreadId())
            {
                Application::g_msg.hwnd = mouseHwnd;
            }
        }
        break;
    }

    // Get the actual dialog window handle.
    // If it's a child, get the root window.

    DWORD style = GetWindowStyle(Application::g_msg.hwnd);
    HWND dialog = Application::g_msg.hwnd;

    if (style & WS_CHILD)
        dialog = GetAncestor(Application::g_msg.hwnd, GA_ROOT);

    // Dispatch the message, trying the child and parent.

    bool messageHandled = false;
    if (Application::g_msg.message == WM_SYSCHAR)
    {
        // If Alt+Key is pressed, give the control priority, sending the
        // message to it first, then handling it as a menu accelerator
        // if it does not.
        TranslateMessage(&Application::g_msg);
        messageHandled = !DispatchMessage(&Application::g_msg);
    }
    if (!messageHandled && Application::g_msg.message == WM_KEYDOWN)
    {
        // Ask the dialog first to check for accelerators.
        messageHandled = !!SendMessage(dialog, Application::g_msg.message, Application::g_msg.wParam, Application::g_msg.lParam);
    }
    if (!messageHandled)
    {
        // Let the default dialog processing check it.
        messageHandled = !!IsDialogMessage(dialog, &Application::g_msg);
    }
    if (!messageHandled)
    {
        // Not any of the above, so just handle it.
        TranslateMessage(&Application::g_msg);
        DispatchMessage(&Application::g_msg);
    }
}


HRESULT CreateDirectWriteFactory()
{
    Application::g_DWriteFactory.Clear();
    HRESULT hr = DWriteCreateFactory(
            DWRITE_FACTORY_TYPE_SHARED,
            __uuidof(IDWriteFactory),
            reinterpret_cast<IUnknown**>(&Application::g_DWriteFactory)
            );
    if (FAILED(hr))
    {
        return Application::DisplayError(L"Could not create DirectWrite factory??", L"CreateFactory()", hr);
    }

    return S_OK;
}


HRESULT UnloadDirectWriteFactory()
{
    // This is a dangerous operation, since we must be sure to free all active
    // references before unloading the DLL. Otherwise we'll crash upon calling
    // the Release on the outstanding objects.

    Application::g_DWriteFactory.Clear();

    return S_OK;
}


void Application::Fail(__in_z const wchar_t* message, __in_z_opt const wchar_t* formatString, int functionResult)
{
    Application::DisplayError(message, formatString, functionResult);
    ExitProcess(functionResult);
}


int Application::DisplayError(__in_z const wchar_t* message, __in_z_opt const wchar_t* formatString, int functionResult)
{
    wchar_t buffer[1000];
    buffer[0] = 0;

    if (formatString == nullptr)
        formatString = L"%s\r\nError code = %X";

    StringCchPrintf(
        buffer,
        ARRAY_SIZE(buffer),
        formatString,
        message,
        functionResult
        );

    MessageBox(
        nullptr, 
        buffer,
        APPLICATION_TITLE,
        MB_OK|MB_ICONEXCLAMATION
        );

    return -1;
}


void Application::DebugLog(const wchar_t* logMessage, ...)
{
    va_list argList;
    va_start(argList, logMessage);

    wchar_t buffer[1000];
    buffer[0] = 0;
    StringCchVPrintf(
        buffer,
        ARRAY_SIZE(buffer),
        logMessage,
        argList
        );

    OutputDebugString(buffer);
}


// Maps exceptions to equivalent HRESULTs,
HRESULT Application::ExceptionToHResult() throw()
{
    try
    {
        throw;  // Rethrow previous exception.
    }
    catch(std::bad_alloc&)
    {
        return E_OUTOFMEMORY;
    }
    catch (...)
    {
        return E_FAIL;
    }
}
