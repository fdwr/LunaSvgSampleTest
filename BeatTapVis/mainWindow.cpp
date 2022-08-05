// 2008-11-23

#include <windows.h>

//  Declare Windows procedure
LRESULT CALLBACK WindowProcedure (HWND, UINT, WPARAM, LPARAM);

//  Make the class name into a global variable
char szClassName[] = "WindowsApp";

UINT g_x = 0, g_xMax = 512;


int WINAPI WinMain (HINSTANCE hThisInstance,
                    HINSTANCE hPrevInstance,
                    LPSTR lpszArgument,
                    int nCmdShow
                    )
{
    HWND hwnd;               // This is the handle for our window
    MSG messages;            // Here messages to the application are saved
    WNDCLASSEX wincl;        // Data structure for the windowclass

    // The Window structure
    wincl.hInstance = hThisInstance;
    wincl.lpszClassName = szClassName;
    wincl.lpfnWndProc = &WindowProcedure;      // This function is called by windows
    wincl.style = CS_DBLCLKS;                 // Catch double-clicks
    wincl.cbSize = sizeof(WNDCLASSEX);

    // Use default icon and mouse-pointer
    wincl.hIcon = LoadIcon (NULL, IDI_APPLICATION);
    wincl.hIconSm = LoadIcon (NULL, IDI_APPLICATION);
    wincl.hCursor = LoadCursor (NULL, IDC_ARROW);
    wincl.lpszMenuName = NULL;                 // No menu
    wincl.cbClsExtra = 0;                      // No extra bytes after the window class
    wincl.cbWndExtra = 0;                      // structure or the window instance
    // Use Windows's default color as the background of the window
    wincl.hbrBackground = (HBRUSH) (COLOR_BTNTEXT + 1);

    // Register the window class, and if it fails quit the program
    if (!RegisterClassEx (&wincl))
        return 0;

    // The class is registered, let's create the program*/
    hwnd = CreateWindowEx (
           0,                   // Extended possibilites for variation
           szClassName,         // Classname
           "Windows App",       // Title Text
           WS_OVERLAPPEDWINDOW, // default window
           CW_USEDEFAULT,       // Windows decides the position
           CW_USEDEFAULT,       // where the window ends up on the screen
           544,                 // The programs width
           375,                 // and height in pixels
           HWND_DESKTOP,        // The window is a child-window to desktop
           NULL,                // No menu
           hThisInstance,       // Program Instance handler
           NULL                 // No Window Creation data
           );

    // Make the window visible on the screen
    ShowWindow (hwnd, nCmdShow);
    
    SetTimer(hwnd, 0,30, NULL);

    // Run the message loop. It will run until GetMessage() returns 0
    while (GetMessage(&messages, NULL, 0, 0) > 0)
    {
        // Translate virtual-key messages into character messages
        TranslateMessage(&messages);
        // Send message to WindowProcedure
        DispatchMessage(&messages);
    }

    // The program return-value is 0 - The value that PostQuitMessage() gave
    return messages.wParam;
}


void ResetX(HWND hwnd)
{
    InvalidateRect(hwnd, NULL, TRUE);
    g_x = 0;
}


//  This function is called by the Windows function DispatchMessage()

LRESULT CALLBACK WindowProcedure (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)                  // handle the messages
    {
        case WM_DESTROY:
            PostQuitMessage (0);      // send a WM_QUIT to the message queue
            break;

        case WM_KEYDOWN:
            {
                HDC hdc = GetDC(hwnd);
                DWORD color = 0x00FF0000;
                UINT y = 100;
                switch (wParam)
                {
                case 'H':
                    color = 0x000000FF;
                    y = 110;
                    break;

                case 'N':
                    color = 0x0040FF40;
                    y = 90;
                    break;

                case VK_ESCAPE:
                    PostMessage(hwnd, WM_CLOSE, 0,0);
                    break;
                    
                case VK_BACK:
                    ResetX(hwnd);
                    break;
                }
                SetPixel(hdc, g_x,y, color);
                SetPixel(hdc, g_x+1,y, color);
                SetPixel(hdc, g_x+2,y, color);
                ReleaseDC(hwnd, hdc);
            }
            break;
            
        case WM_TIMER:
            g_x++;
            if (g_x >= g_xMax)
            {
                ResetX(hwnd);
            }
            break;
            
        default:                      // for messages that we don't deal with
            return DefWindowProc (hwnd, message, wParam, lParam);
    }

    return 0;
}
