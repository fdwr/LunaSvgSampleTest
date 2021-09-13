#define WINVER 0x0501
#define _WIN32_WINNT 0x0501

#include <windows.h>
#include <wingdi.h>

//  Declare Windows procedure
LRESULT CALLBACK WindowProcedure (HWND, UINT, WPARAM, LPARAM);

void ToggleWindowSize(HWND hwnd);

void DrawTestImage(
    __in const HDC hdc,
    __in const RECT& displayRect
    );


//  Make the class name into a global variable
char szClassName[] = "WindowsApp";

UINT g_x = 0, g_xMax = 512;


int WINAPI WinMain (
    HINSTANCE hThisInstance,
    HINSTANCE hPrevInstance,
    LPSTR lpszArgument,
    int nCmdShow
    )
{
    HWND hwnd;                          // This is the handle for our window
    MSG messages;                       // Here messages to the application are saved
    WNDCLASSEX wincl;                   // Data structure for the windowclass

    // The Window structure
    wincl.hInstance = hThisInstance;
    wincl.lpszClassName = szClassName;
    wincl.lpfnWndProc = &WindowProcedure;
    wincl.style = CS_DBLCLKS | CS_VREDRAW | CS_HREDRAW;
    wincl.cbSize = sizeof(WNDCLASSEX);

    // Use default icon and mouse-pointer
    wincl.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wincl.hIconSm       = LoadIcon(NULL, IDI_APPLICATION);
    wincl.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wincl.lpszMenuName  = NULL;         // No menu
    wincl.cbClsExtra    = 0;            // No extra bytes after the window class
    wincl.cbWndExtra    = 0;            // structure or the window instance
    // Use Windows's default color as the background of the window
    wincl.hbrBackground = (HBRUSH) (COLOR_BTNTEXT + 1);

    // Register the window class, and if it fails quit the program
    if (!RegisterClassEx (&wincl))
        return 0;

    // The class is registered, let's create the program*/
    hwnd = CreateWindowEx (
           0,                   // Extended possibilites for variation
           szClassName,         // Classname
           "Display Test Image",// Title Text
           WS_OVERLAPPEDWINDOW, // default window
           CW_USEDEFAULT,       // Windows decides the position
           CW_USEDEFAULT,       // where the window ends up on the screen
           800,                 // The programs width
           570,                 // and height in pixels
           HWND_DESKTOP,        // The window is a child-window to desktop
           NULL,                // No menu
           hThisInstance,       // Program Instance handler
           NULL                 // No Window Creation data
           );

    // Make the window visible on the screen
    ShowWindow(hwnd, nCmdShow);
    
    // Run the message loop. It will run until GetMessage() returns 0
    while (GetMessage(&messages, NULL, 0, 0))
    {
        // Translate virtual-key messages into character messages
        TranslateMessage(&messages);

        // Send message to WindowProcedure
        DispatchMessage(&messages);
    }

    // The program return-value is 0 - The value that PostQuitMessage() gave
    return int(messages.wParam);
}


//  This function is called by the Windows function DispatchMessage()

LRESULT CALLBACK WindowProcedure (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)                  // handle the messages
    {
        case WM_DESTROY:
            PostQuitMessage (0);      // send a WM_QUIT to the message queue
            break;

        case WM_PAINT:
            {
                PAINTSTRUCT ps;
                RECT displayRect;

                BeginPaint(hwnd, &ps);
                GetClientRect(hwnd, &displayRect);
                DrawTestImage(ps.hdc, displayRect);
                EndPaint(hwnd, &ps);
            }
            break;

        case WM_LBUTTONDBLCLK:
            ToggleWindowSize(hwnd);
            break;

        case WM_ERASEBKGND:
            return true;

        case WM_KEYDOWN:
            {
                switch (wParam)
                {
                case ' ':
                case VK_RETURN:
                    ToggleWindowSize(hwnd);
                    break;

                case VK_ESCAPE:
                    if (IsZoomed(hwnd))
                    {
                        ToggleWindowSize(hwnd);
                    }
                    else
                    {
                        PostMessage(hwnd, WM_CLOSE, 0,0);
                    }
                    break;
                }
            }
            break;
            
        default:                      // for messages that we don't deal with
            return DefWindowProc (hwnd, message, wParam, lParam);
    }

    return 0;
}


void ToggleWindowSize(HWND hwnd)
{
    if (IsZoomed(hwnd))
    {
        SetWindowLong(hwnd, GWL_STYLE, GetWindowLong(hwnd, GWL_STYLE) | WS_CAPTION);
        SetWindowPos(hwnd, NULL, 0,0, 0,0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOOWNERZORDER | SWP_NOSIZE | SWP_NOZORDER);
        ShowWindow(hwnd, SW_RESTORE);
    }
    else
    {
        SetWindowLong(hwnd, GWL_STYLE, GetWindowLong(hwnd, GWL_STYLE) & ~WS_CAPTION);
        SetWindowPos(hwnd, NULL, 0,0, 0,0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOOWNERZORDER | SWP_NOSIZE | SWP_NOZORDER);
        ShowWindow(hwnd, SW_MAXIMIZE);
    }
}


void DrawTestImage(
    __in const HDC hdc,
    __in const RECT& displayRect
    )
{
    int width  = int(displayRect.right  - displayRect.left);
    int height = int(displayRect.bottom - displayRect.top );

    SelectObject(hdc, GetStockObject(DC_PEN));
    SelectObject(hdc, GetStockObject(NULL_BRUSH));

    // Draw vertical lines
    for (int x = 0; x < width; x++)
    {
        UINT32 color = (x & 1) ? 0x00FFFFFF : 0x00000000;
        SetDCPenColor(hdc, color);

        MoveToEx(hdc, x,0, NULL);
        LineTo(hdc, x,height);
    }

    int y1 = height * 3/8;
    int y2 = height * 5/8;

    // Draw horizontal lines
    for (int y = y1; y < y2; y++)
    {
        UINT32 color = (y & 1) ? 0x00FFFFFF : 0x00000000;
        SetDCPenColor(hdc, color);

        MoveToEx(hdc, 0,y, NULL);
        LineTo(hdc, width,y);
    }

    // Draw four corners
    MoveToEx(hdc, 0,0, NULL);

    SetDCPenColor(hdc, 0x000000FF);
    LineTo(hdc, width-1,0       );

    SetDCPenColor(hdc, 0x000000FF);
    LineTo(hdc, width-1,height-1);

    SetDCPenColor(hdc, 0x0000FF00);
    LineTo(hdc, 0      ,height-1);

    SetDCPenColor(hdc, 0x0000FF00);
    LineTo(hdc, 0      ,0       );
}
