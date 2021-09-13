// ctest.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "resource.h"

#define ctest_cpp
#include "..\pgfx\pgfx.h"
#include "..\pgfx\pgfxlayr.h"

void AnimateFrame();


////////////////////////////////////////////////////////////////////////////////

#define MAX_LOADSTRING 100


// Global Variables:
HINSTANCE hInst;								// current instance
TCHAR szTitle[MAX_LOADSTRING];					// The title bar text
TCHAR szWindowClass[MAX_LOADSTRING];			// The title bar text

HWND MainHwnd = NULL;

HGLOBAL imageBg;
HGLOBAL imageFg;
HGLOBAL imageCg;

extern "C" PgtLayer TestLayer1, W9xBtnNorm, WxpBtnNorm, PcsBtnNorm;

// Foward declarations of functions included in this code module:
ATOM				MyRegisterClass(HINSTANCE hInstance);
BOOL				InitInstance(HINSTANCE, int);
LRESULT CALLBACK	WndProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK	About(HWND, UINT, WPARAM, LPARAM);

void FatalError(LPSTR msg);

int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	MSG msg;
	HACCEL hAccelTable;

	// Initialize global strings
	LoadString(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
	LoadString(hInstance, IDC_CTEST, szWindowClass, MAX_LOADSTRING);
	MyRegisterClass(hInstance);

	imageBg = LoadResource(NULL, FindResource(NULL, (LPCTSTR)IDR_BG, (LPCTSTR)24) );
	imageFg = LoadResource(NULL, FindResource(NULL, (LPCTSTR)IDR_FG, (LPCTSTR)24) );
	imageCg = GlobalAlloc(GMEM_FIXED, 300*300*4);
	//imageBg = LockResource(imageBg);
	if (!imageBg || !imageFg || !imageCg)
		FatalError("One or more of the image resources is missing.");

	PgfxDisplay.pixels = imageCg;

	PgfxInit();
	//PgfxFlags &= ~PgfxFlags_UseMMX; // disable MMX for speed testing

	// Perform application initialization:
	if (!InitInstance (hInstance, nCmdShow)) 
		FatalError("Could not create main window for whatever reason.");

	hAccelTable = LoadAccelerators(hInstance, (LPCTSTR)IDC_CTEST);

	// Main message loop:
	while (GetMessage(&msg, NULL, 0, 0)) 
	{
		if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg)) 
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}

	return msg.wParam;
}



//
//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
//  COMMENTS:
//
//    This function and its usage is only necessary if you want this code
//    to be compatible with Win32 systems prior to the 'RegisterClassEx'
//    function that was added to Windows 95. It is important to call this function
//    so that the application will get 'well formed' small icons associated
//    with it.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
	WNDCLASSEX wcex;

	wcex.cbSize = sizeof(WNDCLASSEX); 

	wcex.style			= CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc	= (WNDPROC)WndProc;
	wcex.cbClsExtra		= 0;
	wcex.cbWndExtra		= 0;
	wcex.hInstance		= hInstance;
	wcex.hIcon			= LoadIcon(hInstance, (LPCTSTR)IDI_CTEST);
	wcex.hCursor		= LoadCursor(NULL, IDC_ARROW);
	wcex.hbrBackground	= (HBRUSH)(COLOR_WINDOW+1);
	wcex.lpszMenuName	= (LPCSTR)IDM_CTEST;
	wcex.lpszClassName	= szWindowClass;
	wcex.hIconSm		= LoadIcon(wcex.hInstance, (LPCTSTR)IDI_CTEST);

	return RegisterClassEx(&wcex);
}

//
//   FUNCTION: InitInstance(HANDLE, int)
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
	HWND hWnd;

	hInst = hInstance; // Store instance handle in our global variable

	InitCommonControls();
	hWnd = CreateWindow(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
	  CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, NULL, NULL, hInstance, NULL);

	if (!hWnd)
	{
		return FALSE;
	}

	ShowWindow(hWnd, nCmdShow);
	UpdateWindow(hWnd);

	return TRUE;
}

//
//  FUNCTION: WndProc(HWND, unsigned, WORD, LONG)
//
//  PURPOSE:  Processes messages for the main window.
//
//  WM_COMMAND	- process the application menu
//  WM_PAINT	- Paint the main window
//  WM_DESTROY	- post a quit message and return
//
//
LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	int wmId, wmEvent;
	PAINTSTRUCT ps;
	HDC hdc;
	//static bool redraw = false;

	switch (message) 
	{
	case WM_CREATE:
		MainHwnd = hwnd;
		SetTimer(hwnd, 1234, 50, NULL);
		//SetTimer(hwnd, 1234, 1000, NULL);
		AnimateFrame();
		break;
	case WM_COMMAND:
		wmId    = LOWORD(wParam); 
		wmEvent = HIWORD(wParam); 
		// Parse the menu selections:
		switch (wmId)
		{
			case IDM_ABOUT:
			   DialogBox(hInst, (LPCTSTR)IDD_ABOUTBOX, hwnd, (DLGPROC)About);
			   break;
			case IDM_EXIT:
			   DestroyWindow(hwnd);
			   break;
			default:
			   return DefWindowProc(hwnd, message, wParam, lParam);
		}
		break;
	case WM_PAINT:
		hdc = BeginPaint(hwnd, &ps);
		// TODO: Add any drawing code here...
		//RECT rt;
		//GetClientRect(hwnd, &rt);
		//DrawText(hdc, szHello, strlen(szHello), &rt, DT_CENTER);
		{
			BITMAPINFOHEADER const static bmi = {
				sizeof(BITMAPINFOHEADER),
				imageWidth,
				-imageHeight,
				1,
				32,
				0,
				imageWidth*imageHeight*4,
				1,1,
				0,0
			};
			SetDIBitsToDevice(ps.hdc,
				0,0, imageWidth,imageHeight,
				0,0, 0,imageHeight,
				imageCg, (BITMAPINFO*)&bmi, DIB_RGB_COLORS
			);
		}
		//redraw = false;
		EndPaint(hwnd, &ps);
		break;
	case WM_TIMER:
	{
		//if (redraw) {
		// timer events were too close and a PAINT was lost,
		// force redraw			
		//}
		AnimateFrame();
		RECT rt = {0,0,300,300};
		//redraw = true;
		InvalidateRect(hwnd, &rt, FALSE);
		//UpdateWindow(hwnd);
		break;
	}
	case WM_DESTROY:
		KillTimer(hwnd, 1234);
		PostQuitMessage(0);
		break;
	default:
		return DefWindowProc(hwnd, message, wParam, lParam);
   }
   return 0;
}

static int AnimationFrame=0;
void AnimateFrame() {
	int x = AnimationFrame % imageWidth;
	// draw background
	if (x > 0) {
		BlitOpaque32i32i(
			imageCg, imageWidth*4, 0,0, x,imageHeight,
			imageBg, imageWidth*4, imageWidth-x,0);
	}
	BlitOpaque32i32i(
		imageCg, imageWidth*4, x,0, imageWidth-x,imageHeight,
		imageBg, imageWidth*4, 0,0);

	int time = GetTickCount();
	///*
	for (int i=0; i<1; i++) {
		BlitTrans32i32i(
			imageCg, imageWidth*4, 0,0, imageWidth,imageHeight,
			imageFg, imageWidth*4, 0,0);
		//BlitOpaque32i32i(
		//	imageCg, imageWidth*4, 0,0, imageWidth,imageHeight,
		//	imageFg, imageWidth*4, 0,0);
	}
	//*/
	char text[10];
	wsprintf(text, "fps=%dms", GetTickCount() - time);
	SetWindowText(MainHwnd, text);

	//DrawLayers(&TestLayer1, imageWidth,imageHeight, 8,8, -8,-8, NULL,0);
	//DrawLayers(&TestLayer1, imageWidth,imageHeight, 0,0, imageWidth,imageHeight, NULL,0);

	PgtLayer*
	ButtonLayers = &W9xBtnNorm;

	DrawLayers(ButtonLayers, imageWidth,imageHeight, 12,12, 12+74,12+22, NULL,0);
	DrawLayers(ButtonLayers, imageWidth,imageHeight, 12,42, 12+64,42+40, NULL,0);
	DrawLayers(ButtonLayers, imageWidth,imageHeight, 12,90, 12+220,90+16, NULL,0);

	ButtonLayers = &WxpBtnNorm;

	DrawLayers(ButtonLayers, imageWidth,imageHeight, 12,112, 12+74,112+22, NULL,0);
	DrawLayers(ButtonLayers, imageWidth,imageHeight, 12,142, 12+64,142+40, NULL,0);
	DrawLayers(ButtonLayers, imageWidth,imageHeight, 12,190, 12+220,190+16, NULL,0);

	ButtonLayers = &PcsBtnNorm;

	DrawLayers(ButtonLayers, imageWidth,imageHeight, 12,212, 12+74,212+22, NULL,0);
	DrawLayers(ButtonLayers, imageWidth,imageHeight, 12,242, 12+64,242+40, NULL,0);
	DrawLayers(ButtonLayers, imageWidth,imageHeight, 12,290, 12+220,290+16, NULL,0);

	AnimationFrame++;
	//Pgfx.
	//MessageBeep(MB_OK);
}

// Mesage handler for about box.
LRESULT CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
	{
		case WM_INITDIALOG:
				return TRUE;

		case WM_COMMAND:
			if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) 
			{
				EndDialog(hDlg, LOWORD(wParam));
				return TRUE;
			}
			break;
	}
    return FALSE;
}


void FatalError(LPSTR msg) {
	MessageBox(NULL, msg, ProgramName " Fatal Error", MB_OK|MB_ICONERROR|MB_TASKMODAL);
	ExitProcess(-1);
}
