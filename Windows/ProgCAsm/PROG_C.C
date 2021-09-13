//#include <iostream.h>
//DECLSPEC_IMPORT
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

HWND hwnd;
HINSTANCE hinst;

LRESULT APIENTRY MsgProc(HWND hwnd, int uMsg, int wParam, int lParam)
{
    switch (uMsg) {
    //case WM_CREATE:
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    default:
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
}

int APIENTRY WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int cmdShow)
{
    MSG msg;
    WNDCLASS wc;

    hinst = GetModuleHandle(NULL);

    wc.style=CS_CLASSDC;
    wc.lpfnWndProc=(WNDPROC)MsgProc;
    wc.cbClsExtra=0;
    wc.cbWndExtra=0;
    wc.hInstance=hinst;
    wc.hIcon=LoadIcon(hinst,1);
    wc.hCursor=LoadCursor(0,IDC_ARROW);
    wc.hbrBackground=COLOR_BTNFACE + 1;
    wc.lpszMenuName=1;
    wc.lpszClassName="MediaFileLister";

    if (!RegisterClass(&wc))
		MessageBox (0, "Failed to register class", "Media File Lister 1.0", MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
		

    hwnd=CreateWindowEx(WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT,
        "MediaFileLister",
        "Media File Lister 1.0 (Beta)",
        WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME|WS_SIZEBOX,
        0,0, 400,572,
        NULL,
        NULL,
        hinst,
        NULL);

    if (hwnd)
        while (GetMessage(&msg, 0, 0,0)>0)
            DispatchMessage(&msg);
    else
	{
		int a = GetLastError();
		char test[80];
		int ints[1] = {&a};
		wvsprintf(test,"error = %d",ints);
        MessageBox (0, "Failed to create window", "Media File Lister 1.0", MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
		MessageBox (0, test, test, MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
	}



    return 0;
}

#define _main WinMain