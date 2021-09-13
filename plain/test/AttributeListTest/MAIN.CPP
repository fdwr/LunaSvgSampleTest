/*
File: main.cpp
Project: test_atrblist
Date: 2005-06-25

Main program. Relies heavily on GUI and graphics libraries.

For compiling C code, you will get a few pointer truncation errors if
64bit compatibility checking is on.

For compiling the assembly source code in MSVC7:
	nasmw.exe "$(InputPath)" -o "$(IntDir)\$(InputName).obj" -fwin32 -w+orphan-labels -icommon\ -i..\pgfx\ -i..\plain\ -d_MSLINK -d_WINDOWS
*/

#define main_cpp
#include "main.h"
//#include "dynamicarray.h"
//#include "atrblist.h"
//#include "commdlg.h"


///////////////////////////////////////////////////////////////////////////////

void FatalError(LPTSTR message);
extern "C" void WriteMessage(LPTSTR msg, ...);

// user control event handlers
extc void MainTitleBarOwner(GuiObj* obj, int msg, GuiMsgParams gmp, ...);
extc void ButtonDummyOwner(GuiObj* obj, int msg, GuiMsgParams gmp, ...);

///////////////////////////////////////////////////////////////////////////////
// global and file local vars
static HWND MainHwnd;
extc GuiObj MainRoot;

///////////////////////////////////////////////////////////////////////////////
/*
static wchar_t szOpacity[8] = L"144";
static wchar_t szMinStrokeLength[8] = L"2";
static wchar_t szMaxStrokeLength[8] = L"10";
static wchar_t szAreaTolerance[8] = L"10";
static wchar_t szGridDensity[8] = L"1";
static wchar_t szCurvature[8] = L".8";
*/

/*
AttribList GfxOptionsAl = {
	8, 2, 0, NULL,
	AlfTitleType,				0, L"   Painterly Parameters", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfEdit|AlfNumeric|7<<AlfLengthRs,0, L"Opacity (0-255): ", szOpacity,
	AlfEdit|AlfNumeric|7<<AlfLengthRs,0, L"Min stroke length: ", szMinStrokeLength,
	AlfEdit|AlfNumeric|7<<AlfLengthRs,0, L"Max stroke length: ", szMaxStrokeLength,
	AlfEdit|AlfNumeric|7<<AlfLengthRs,0, L"Area tolerance: ", szAreaTolerance,
	AlfEdit|AlfNumeric|7<<AlfLengthRs,0, L"Grid density: ", szGridDensity,
	AlfEdit|AlfNumeric|7<<AlfLengthRs,0, L"Curvature: ", szCurvature,
	//AlfMenu|IdDecomposeBinary,0, L"Decomposition: ", L"binary\0k-way\0\0",
	AlfSeparatorType,			0, NULL, NULL,
};
*/

///////////////////////////////////////////////////////////////////////////////
int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	PgfxInit();
	//PgfxFlags &= ~PgfxFlags_UseMMX; // disable MMX for compatibility testing

	PlainInit(&MainRoot);
	MainHwnd = PlainCreateWin(&MainRoot, T("Test Attribute List"), CW_USEDEFAULT+1, CW_USEDEFAULT+1, MainRoot.width, MainRoot.height);
	if (!MainHwnd) FatalError(T("Could not create main window"));

	// embed into Window, until real one is written at least
	/*
	RegisterClass(&wcAtrList); // else FatalErrorMessage("Failed to register attribute list class");
	CreateChildWindow(&GfxOptions);
	SendMessage(GfxOptions.hwnd, LB_INITSTORAGE, 0,(LPARAM)&GfxOptionsAl);
	SetFocus(GfxOptions.hwnd);
	*/

    ShowWindow(MainHwnd, SW_SHOWDEFAULT);

	while (PlainThreadMsg.message != WM_QUIT) {
		if (PeekMessage(&PlainThreadMsg, NULL, 0,0, PM_REMOVE)) {
			if (PlainThreadMsg.message == WM_DESTROY && (HWND)PlainThreadMsg.wParam == MainHwnd
			 || PlainThreadMsg.message == WM_KEYDOWN && PlainThreadMsg.wParam == VK_ESCAPE)
				PostQuitMessage(0); // don't break immediately in case more msgs in thread
			else {
				TranslateMessage(&PlainThreadMsg);
				DispatchMessage(&PlainThreadMsg);
			}
		}
		else if (PgfxFlags & (PgfxFlags_redraw|PgfxFlags_cursorMove|PgfxFlags_cursorSet)) {
			RedrawWindow(MainHwnd, NULL, NULL, RDW_INTERNALPAINT|RDW_NOERASE|RDW_NOCHILDREN);
			//InvalidateRect(hwnd, NULL, FALSE);
		}
		else {
			WaitMessage();
		}
	}

	PlainDestroyWin(MainHwnd);
	PlainDeinit(&MainRoot);

	return (int)PlainThreadMsg.wParam;
}

void FatalError(LPTSTR message)
{
	MessageBox(NULL, message, "CS419HW1 Fatal Error", MB_OK|MB_ICONSTOP|MB_TASKMODAL);
	ExitProcess(-1);
}

////////////////////////////////////////////////////////////////////////////////


extc void ButtonDummyOwner(GuiObj* obj, int msg, GuiMsgParams gmp, ...)
{
	MessageBox(MainHwnd, "Clicked", "Clicked", MB_OK);
}

extc void MainTitleBarOwner(GuiObj* obj, int msg, GuiMsgParams gmp, ...)
{
	PostQuitMessage(0);
}
