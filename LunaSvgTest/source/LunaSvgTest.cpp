// LunaSvgTest.cpp : Defines the entry point for the application.
//

#include "precomp.h"
#include "LunaSvgTest.h"

#include "lunasvg.h"

constexpr size_t MAX_LOADSTRING = 100;
// Global Variables:
HINSTANCE hInst;                                // current instance
WCHAR szTitle[MAX_LOADSTRING];                  // The title bar text
WCHAR szWindowClass[MAX_LOADSTRING];            // the main window class name

lunasvg::Bitmap g_bitmap;

// Forward declarations of functions included in this code module:
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK    About(HWND, UINT, WPARAM, LPARAM);

int APIENTRY wWinMain(
    _In_ HINSTANCE hInstance,
    _In_opt_ HINSTANCE hPrevInstance,
    _In_ LPWSTR lpCmdLine,
    _In_ int nCmdShow
    )
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    // Initialize global strings
    LoadStringW(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
    LoadStringW(hInstance, IDC_LUNASVGTEST, szWindowClass, MAX_LOADSTRING);
    MyRegisterClass(hInstance);

    // Perform application initialization:
    if (!InitInstance (hInstance, nCmdShow))
    {
        return FALSE;
    }

    HACCEL hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_LUNASVGTEST));

    MSG msg;

    // Main message loop:
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return (int) msg.wParam;
}



//
//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASSEXW wcex;

    wcex.cbSize = sizeof(WNDCLASSEX);

    wcex.style          = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc    = WndProc;
    wcex.cbClsExtra     = 0;
    wcex.cbWndExtra     = 0;
    wcex.hInstance      = hInstance;
    wcex.hIcon          = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_LUNASVGTEST));
    wcex.hCursor        = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground  = (HBRUSH)(COLOR_WINDOW+1);
    wcex.lpszMenuName   = MAKEINTRESOURCEW(IDC_LUNASVGTEST);
    wcex.lpszClassName  = szWindowClass;
    wcex.hIconSm        = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

    return RegisterClassExW(&wcex);
}

//
//   FUNCTION: InitInstance(HINSTANCE, int)
//
//   PURPOSE: Saves instance handle and creates main window
//
//   COMMENTS:
//
//        In this function, we save the instance handle in a global variable and
//        create and display the main program window.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   hInst = hInstance; // Store instance handle in our global variable

   HWND hWnd = CreateWindowExW(WS_EX_ACCEPTFILES, szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, nullptr, nullptr, hInstance, nullptr);

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   return TRUE;
}

//
//  FUNCTION: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  PURPOSE: Processes messages for the main window.
//
//  WM_COMMAND  - process the application menu
//  WM_PAINT    - Paint the main window
//  WM_DESTROY  - post a quit message and return
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_COMMAND:
        {
            int wmId = LOWORD(wParam);
            // Parse the menu selections:
            switch (wmId)
            {
            case IDM_ABOUT:
                DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
                break;
            case IDM_EXIT:
                DestroyWindow(hWnd);
                break;

            default:
                return DefWindowProc(hWnd, message, wParam, lParam);
            }
        }
        break;

    case WM_DROPFILES:
        {
            std::array<char, MAX_PATH> fileName;
            fileName[0] = '\0';
            HDROP dropHandle = reinterpret_cast<HDROP>(wParam);
                    
            if (DragQueryFileA(dropHandle, 0, fileName.data(), static_cast<uint32_t>(fileName.size())))
            {
                auto document = lunasvg::Document::loadFromFile(fileName.data()); // "reshot-icon-trojan-G6A3QR2ZSF.svg"
                if (document)
                {
                    g_bitmap = document->renderToBitmap(256, 256, 0x00000000);
                    //g_bitmap = document->renderToBitmap(128, 128, 0xC0C0C0FF);

                    // Premultiply pixels so that edges are antialiased.
                    uint8_t* data = g_bitmap.data();
                    for (uint32_t i = 0, size = g_bitmap.stride() * g_bitmap.height(); i < size; i += 4)
                    {
                        data[i + 0] = data[i + 0] * data[i + 3] / 255;
                        data[i + 1] = data[i + 1] * data[i + 3] / 255;
                        data[i + 2] = data[i + 2] * data[i + 3] / 255;
                    }
                    InvalidateRect(hWnd, nullptr, false);
                }
            }
        }
        break;

    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hWnd, &ps);
            // TODO: Add any drawing code that uses hdc here...
            if (g_bitmap.valid())
            {
                BITMAPINFO bitmapInfo = {};
                bitmapInfo.bmiHeader.biSize = sizeof(bitmapInfo.bmiHeader);
                bitmapInfo.bmiHeader.biWidth = g_bitmap.width();
                bitmapInfo.bmiHeader.biHeight = -LONG(g_bitmap.height());
                bitmapInfo.bmiHeader.biPlanes = 1;
                bitmapInfo.bmiHeader.biBitCount = 32;
                bitmapInfo.bmiHeader.biCompression = BI_RGB;
                bitmapInfo.bmiHeader.biSizeImage = 0;
                bitmapInfo.bmiHeader.biXPelsPerMeter = 1000;
                bitmapInfo.bmiHeader.biYPelsPerMeter = 1000;
                bitmapInfo.bmiHeader.biClrUsed = 0;
                bitmapInfo.bmiHeader.biClrImportant = 0;

                SetDIBitsToDevice(
                    ps.hdc,
                    0,
                    0,
                    g_bitmap.width(),
                    g_bitmap.height(),
                    0,
                    0,
                    0,
                    g_bitmap.height(),
                    g_bitmap.data(),
                    &bitmapInfo,
                    0 // colorUse
                );
            }
            EndPaint(hWnd, &ps);
        }
        break;

    case WM_DESTROY:
        PostQuitMessage(0);
        break;

    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

// Message handler for about box.
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    UNREFERENCED_PARAMETER(lParam);
    switch (message)
    {
    case WM_INITDIALOG:
        return (INT_PTR)TRUE;

    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
        {
            EndDialog(hDlg, LOWORD(wParam));
            return (INT_PTR)TRUE;
        }
        break;
    }
    return (INT_PTR)FALSE;
}
