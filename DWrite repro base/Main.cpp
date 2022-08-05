/************************************************************************
 *
 * File: winmain.cpp
 *
 * Description: 
 * 
 * 
 *  This file is part of the Microsoft Windows SDK Code Samples.
 * 
 *  Copyright (C) Microsoft Corporation.  All rights reserved.
 * 
 * This source code is intended only as a supplement to Microsoft
 * Development Tools and/or on-line documentation.  See these other
 * materials for detailed information regarding Microsoft code samples.
 * 
 * THIS CODE AND INFORMATION ARE PROVIDED AS IS WITHOUT WARRANTY OF ANY
 * KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
 * PARTICULAR PURPOSE.
 * 
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
