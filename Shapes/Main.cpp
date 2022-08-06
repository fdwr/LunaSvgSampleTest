// 2017-02-19
// Shapes.cpp : Defines the entry point for the application.
//

#include "precomp.h"
#include "resource.h"
#include "DrawingCanvas.h"
#include "ShapeList.h"
#include "ShapeUtility.h"
#include "ShapeRenderer.h"
#include "Common.h"


#define MAX_LOADSTRING 100

// Global Variables:
HINSTANCE hInst;                                // current instance
WCHAR szTitle[MAX_LOADSTRING];                  // The title bar text
WCHAR szWindowClass[MAX_LOADSTRING];            // the main window class name
ShapeList g_shapeList;
DrawingCanvas g_drawingCanvas;

// Forward declarations of functions included in this code module:
ATOM MyRegisterClass(HINSTANCE hInstance);
BOOL InitInstance(HINSTANCE, int);
LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK About(HWND, UINT, WPARAM, LPARAM);
void Paint(HWND hwnd, HDC displayHdc, RECT const& rect);

int APIENTRY wWinMain(_In_ HINSTANCE instance,
                     _In_opt_ HINSTANCE previousInstance,
                     _In_ LPWSTR    commandLine,
                     _In_ int       showCommand
                     )
{
    // TODO: Place code here.

    // Initialize global strings
    LoadStringW(instance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
    LoadStringW(instance, IDC_SHAPES, szWindowClass, MAX_LOADSTRING);
    MyRegisterClass(instance);

    // Perform application initialization:
    if (!InitInstance(instance, showCommand))
    {
        return FALSE;
    }

    HACCEL hAccelTable = LoadAccelerators(instance, MAKEINTRESOURCE(IDC_SHAPES));

    MSG msg;

    // Main message loop:
    while (GetMessage(&msg, nullptr, 0, 0) > 0)
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
    wcex.hIcon          = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_SHAPES));
    wcex.hCursor        = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground  = (HBRUSH)(COLOR_WINDOW+1);
    wcex.lpszMenuName   = MAKEINTRESOURCEW(IDC_SHAPES);
    wcex.lpszClassName  = szWindowClass;
    wcex.hIconSm        = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

    return RegisterClassExW(&wcex);
}


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

   HWND hWnd = CreateWindowW(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, nullptr, nullptr, hInstance, nullptr);

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   return TRUE;
}


//  FUNCTION: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  PURPOSE:  Processes messages for the main window.
//
//  WM_COMMAND  - process the application menu
//  WM_PAINT    - Paint the main window
//  WM_DESTROY  - post a quit message and return
//
//
LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_CREATE:
        {
            g_shapeList.AddShape(ShapeList::Shape::Type::Curve, std::initializer_list<Vertex2f>{ { 0, 0 }, { 0,70 }, {30,100}, {100,100} });
        }
        break;

    case WM_COMMAND:
        {
            int wmId = LOWORD(wParam);
            // Parse the menu selections:
            switch (wmId)
            {
            case IDM_ABOUT:
                DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hwnd, About);
                break;
            case IDM_EXIT:
                DestroyWindow(hwnd);
                break;
            default:
                return DefWindowProc(hwnd, message, wParam, lParam);
            }
        }
        break;
    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);
            Paint(hwnd, ps.hdc, ps.rcPaint);
            EndPaint(hwnd, &ps);
        }
        break;

    case WM_ERASEBKGND: // return true here, but user32 still sometimes ignores it, causing flicker :/
        return true;

    case WM_SIZE: // Resize the target bitmap to the window size.
        RECT rect;
        GetClientRect(hwnd, &rect);
        g_drawingCanvas.ResizeRenderTargets({ std::max<int>(rect.right, 1), std::max<int>(rect.bottom, 1) });
        break;

    case WM_DESTROY:
        g_drawingCanvas.UninitializeForRendering();
        PostQuitMessage(0);
        break;

    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }
    return 0;
}


void Paint(HWND hwnd, HDC displayHdc, RECT const& rect)
{
    RECT clientRect = {};
    GetClientRect(hwnd, OUT &clientRect);
    if (g_drawingCanvas.PaintPrepare(displayHdc, clientRect))
    {
        g_drawingCanvas.ClearBackground(0x00FF88FF);

        auto* renderTarget = g_drawingCanvas.GetD2DRenderTargetWeakRef();

        g_drawingCanvas.SwitchRenderingAPI(DrawingCanvas::CurrentRenderingApiD2D);
        //ComPtr<ID2D1SolidColorBrush> brush;

        //HDC memoryHdc = g_drawingCanvas.GetDWriteBitmapRenderTargetWeakRef()->GetMemoryDC();
        //RECT bindRect = { 0,0,1000, 1000};
        //renderTarget->BindDC(memoryHdc, &bindRect);

        //renderTarget->BeginDraw();
        //renderTarget->CreateSolidColorBrush(D2D1_COLOR_F{ 0.2f, 0.6f, 0.3f, 1.0f }, OUT &brush);
        //renderTarget->FillRectangle({ 10,10, 90,90 }, brush);
        //IFRV(renderTarget->EndDraw());

        if (renderTarget != nullptr)
        {
            for (auto& shape : g_shapeList.shapes)
            {
                DrawShape(*renderTarget, g_shapeList, shape);
            }
        }

        g_drawingCanvas.SwitchRenderingAPI(DrawingCanvas::CurrentRenderingApiAny);

        g_drawingCanvas.PaintFinish(displayHdc, rect);
    }
}


// Message handler for about box.
INT_PTR CALLBACK About(HWND hdialog, UINT message, WPARAM wParam, LPARAM lParam)
{
    UNREFERENCED_PARAMETER(lParam);
    switch (message)
    {
    case WM_INITDIALOG:
        return (INT_PTR)TRUE;

    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
        {
            EndDialog(hdialog, LOWORD(wParam));
            return (INT_PTR)TRUE;
        }
        break;
    }
    return (INT_PTR)FALSE;
}
