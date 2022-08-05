/**
File: main.cpp
Since: 2005-11-30
Brief: Entry point for user interface.
Author: Dwayne Robinson
Website: http://oregonstate.edu/~robinsfr
*/

#include "stdhdr.h"
#include "main.h"
#include "fractured.h"
#include "debugmsg.h"
#include "dockframe.h"
#include "attriblist.h"

#include "PaintComplex.h"
#include "PaintNoise.h"
#include "PaintCyclicAutomata.h"
#include "PaintLife.h"
#include "PaintIfs.h"
#include "PaintConvert.h"

#define _USE_MATH_DEFINES
#include <math.h>
#include <vector>
#include <map>

using namespace std;

////////////////////////////////////////////////////////////////////////////////

#pragma warning(disable:4312) // 'type cast' conversion from 'UINT' to 'HMENU' of greater size
#pragma warning(disable:4800) // 'type cast' conversion from 'UINT' to 'HMENU' of greater size
#pragma warning(disable:4996) // '_snwprintf' was declared deprecated
#pragma comment (lib , "comctl32.lib")

////////////////////////////////////////////////////////////////////////////////
// Global Variables

HINSTANCE hInst;								// current instance

////////////////////////////////////////////////////////////////////////////////
// File Local Variables

typedef struct FracturedProject {
	int id;	/// unique autoincrementing id that never changes
	// Recommend using the simple formula (GetTickCount + layer index)
	// so that each layer will be different.
	vector<FracturedLayer> layers;	/// list of filter layers
	TCHAR* file;	/// full file system path to project
	HWND hwnd;		/// associated MDI window to display (no multiple views of same project though :-/ )
} FracturedProject;

vector<FracturedProject> OpenProjects;



//FracturedCanvas MainCanvas;	// the background which all layers are composited onto

HWND AboutHwnd = nullptr;
HACCEL MainAccelTable;

#ifdef _DEBUG
void WriteMessage(LPTSTR msg, ...);
#else
#define WriteMessage //
#endif

#define DefSpecies(family, species) (((FracturedFamily::family)<<16) | species)

////////////////////////////////////////////////////////////////////////////////
// Function declarations

void				RegisterClasses(HINSTANCE hInstance);
BOOL				InitMainInstance(HINSTANCE, int);
void				FreeMainInstance();
LRESULT CALLBACK	WndProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK	AboutProc(HWND, UINT, WPARAM, LPARAM);
LRESULT				DoCommand(HWND hwnd, HWND src, WPARAM code);
LRESULT CALLBACK	MdiWndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK	PaintersFrameProc(HWND hdlg, UINT message, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK	LayersFrameProc(HWND hdlg, UINT message, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK	PropertiesFrameProc(HWND hdlg, UINT message, WPARAM wParam, LPARAM lParam);

void CreateChildWindow(ChildWindowStruct* cws);
void CreateChildWindow(ChildWindowStruct* cws, HWND hwnd);
void ArrangeChildWindows(int mode);
void SizeChildWindow(ChildWindowStruct *cws);
void SizeChildWindow(ChildWindowStruct *cws, HDWP hdwp);
void DetermineMdiClientRect(HWND hwnd, RECT* rect);

void PopulatePaintersTree();
void RenderLayers();
void CreateGivenPainter(int specie);
void GetPainterProperties(int layerIdx);
void CreateSelectedPainter();
void QuickAndDirtyPainterTest();

////////////////////////////////////////////////////////////////////////////////
// UI controls

static ChildWindowStruct
	MainWindow =	{ 0,IdcMainWindow*0,	MainWindowClass,MainWindowTitle,
	CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,		WS_OVERLAPPEDWINDOW|WS_CLIPCHILDREN, WS_EX_ACCEPTFILES|WS_EX_CLIENTEDGE};
static ChildWindowStruct
	MdiClient =		{ 0,0xCAC,				T("MDICLIENT"),nullptr,
	180,0,500,600,		WS_CHILD|WS_VISIBLE|WS_TABSTOP|WS_GROUP|WS_CLIPCHILDREN|WS_VSCROLL|WS_HSCROLL, WS_EX_CLIENTEDGE};

static ChildWindowStruct
	PaintersFrame =	{ 0,IdcPaintersFrame,	DockFrameClass,nullptr,
	0,0,180,200,		0, 0};
static ChildWindowStruct
	PaintersTree =	{ 0,IdcPaintersTree,	WC_TREEVIEW,nullptr,
	0,0,180,200,		WS_MAXIMIZE|WS_CHILD|WS_VISIBLE|WS_TABSTOP|WS_GROUP|WS_CLIPCHILDREN |     TVS_SINGLEEXPAND|TVS_FULLROWSELECT|TVS_TRACKSELECT|TVS_HASBUTTONS|TVS_DISABLEDRAGDROP|TVS_SHOWSELALWAYS, WS_EX_CLIENTEDGE};

static ChildWindowStruct
	LayersFrame =	{ 0,IdcPaintersFrame,	DockFrameClass,nullptr,
	0,500,180,200,		0, 0};

static ChildWindowStruct
	PropertiesFrame =	{ 0,IdcPaintersFrame,	DockFrameClass,nullptr,
	0,200,180,320,		0, 0};

static ChildWindowStruct
	MainPreview =	{ 0,IdcMainPreview,	MdiWindowClass,T("Main Display - All Layers"),
	0,0,CW_USEDEFAULT,CW_USEDEFAULT,		WS_CHILD|WS_VISIBLE|WS_TABSTOP|WS_GROUP|WS_VSCROLL|WS_HSCROLL|WS_MAXIMIZEBOX, WS_EX_MDICHILD|WS_EX_CLIENTEDGE};


////////////////////////////////////////////////////////////////////////////////
// Actual code

int APIENTRY _tWinMain(
	HINSTANCE hInstance,
	HINSTANCE hPrevInstance,
	LPTSTR    lpCmdLine,
	int       nCmdShow)
{
 	// TODO: Place code here.
	MSG msg;
	MsgDispatcherFunc dispatcher; // dispatching function (dialog, main window, mdi...)
	HWND targetHwnd = nullptr; // window to check dispatch
	DWORD dwThreadId;

	WriteMessage(T("Starting"));

	// Initialize global strings
	RegisterClasses(hInstance);

	// Perform application initialization:
	if (!InitMainInstance (hInstance, nCmdShow)) 
	{
		return FALSE;
	}

	MainAccelTable = LoadAccelerators(hInstance, (LPCTSTR)IDC_FRACTURED);
	dwThreadId = GetCurrentThreadId(); // need thread id for mousewheel

	// Main message loop:
	while (GetMessage(&msg, nullptr, 0, 0) > 0)
	{
		//dbgmsgwin(msg.hwnd, msg.message, msg.wParam, msg.lParam);
		/*
		// There may be some global keys to add later, but not now
		if (!TranslateAccelerator(msg.hwnd, MainAccelTable, &msg)) 
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
		*/
		switch (msg.message) {
		case WM_KEYDOWN:
		case WM_KEYUP:
		case WM_SYSKEYDOWN:
		case WM_SYSKEYUP:
			// key tabbing does not work right yet??
			targetHwnd = GetActiveWindow();
			break;
		case WM_MOUSEWHEEL:
			// sending a mousewheel message to a window in another
			// process seems to crash DispatchMessage, so avoid it.
			msg.hwnd = WindowFromPoint(msg.pt);
			if (GetWindowThreadProcessId(msg.hwnd, nullptr) == dwThreadId)
				DispatchMessage(&msg);
			continue;
		default:
			targetHwnd = msg.hwnd;
			break;
		}
		#if 1
		dispatcher = (MsgDispatcherFunc)GetProp(targetHwnd, T("MsgDispatcher"));
		if (dispatcher) {
			dispatcher(&msg);
		} else {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
		#else
		if (!TranslateMDISysAccel(MdiClient.hwnd, &msg) && !TranslateAccelerator(MainWindow.hwnd, MainAccelTable, &msg)) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
		#endif

	}
	FreeMainInstance();

	return (int) msg.wParam;
}


bool TryRegisterClass(WNDCLASSEX* pwc)
{
	if (!RegisterClassEx(pwc)) {
		TCHAR text[1024];
		snprintft(text, elmsof(text), T("Failed to register a necessary window class:\nClass=%s\n\nThe program will now end."), pwc->lpszClassName);
		MessageBox(nullptr, text, MainWindowTitle, MB_OK|MB_TOPMOST|MB_ICONSTOP|MB_TASKMODAL);
		ExitProcess(-1);
	}
	return true;
}


/** Registers the main window class.

Remarks:
	This function and its usage are only necessary if you want this code
	to be compatible with Win32 systems prior to the 'RegisterClassEx'
	function that was added to Windows 95. It is important to call this function
	so that the application will get 'well formed' small icons associated
	with it.
*/
void RegisterClasses(HINSTANCE hInstance)
{
	WNDCLASSEX wcex;

	wcex.cbSize = sizeof(WNDCLASSEX); 

	wcex.style			= 0;//CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc	= (WNDPROC)&WndProc;
	wcex.cbClsExtra		= 0;
	wcex.cbWndExtra		= 0;
	wcex.hInstance		= hInstance;
	wcex.hIcon			= LoadIcon(hInstance, (LPCTSTR)IDI_FRACTURED);
	wcex.hCursor		= LoadCursor(nullptr, IDC_ARROW);
	wcex.hbrBackground	= nullptr; //(HBRUSH)(COLOR_WINDOW+1);
	wcex.lpszMenuName	= (LPCTSTR)IDC_FRACTURED;
	wcex.lpszClassName	= MainWindowClass;
	wcex.hIconSm		= wcex.hIcon; //LoadIcon(wcex.hInstance, (LPCTSTR)IDI_SMALL);

	TryRegisterClass(&wcex);

	wcex.style			= 0;//CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc	= (WNDPROC)&MdiWndProc;
	wcex.cbClsExtra		= 0;
	wcex.cbWndExtra		= 0;
	wcex.hInstance		= hInstance;
	//wcex.hIcon			= LoadIcon(hInstance, (LPCTSTR)IDI_FRACTURED);
	wcex.hCursor		= LoadCursor(nullptr, IDC_SIZEALL);
	wcex.hbrBackground	= (HBRUSH)(COLOR_WINDOW+1);
	wcex.lpszMenuName	= (LPCTSTR)nullptr;
	wcex.lpszClassName	= MdiWindowClass;
	//wcex.hIconSm		= wcex.hIcon; //LoadIcon(wcex.hInstance, (LPCTSTR)IDI_SMALL);

	TryRegisterClass(&wcex);

	TryRegisterClass(DockFrame_GetWndClass());

	TryRegisterClass(&wcAttribList);

	INITCOMMONCONTROLSEX icce = {
		sizeof(INITCOMMONCONTROLSEX),
		ICC_LISTVIEW_CLASSES|ICC_TREEVIEW_CLASSES|ICC_BAR_CLASSES|ICC_PROGRESS_CLASS
	};
	InitCommonControlsEx(&icce);
}


/** Saves instance handle and creates main window

Remarks:
	In this function, we save the instance handle in a global variable and
	create and display the main program window.
*/
BOOL InitMainInstance(HINSTANCE hInstance, int nCmdShow)
{
	hInst = hInstance; // Store instance handle in our global variable

	// main window creation
	CreateChildWindow(&MainWindow, nullptr);
	if (!MainWindow.hwnd) {
		return FALSE;
	}

	ArrangeChildWindows(0);

	// create MDI client
	CLIENTCREATESTRUCT ccs;
	ccs.hWindowMenu = GetSubMenu (GetMenu(MainWindow.hwnd),2); // menu where children will be listed
	ccs.idFirstChild = IDM_MDIBASE;

	MdiClient.hwnd = CreateWindowEx (0, //WS_EX_CLIENTEDGE,
		T("MDICLIENT"),
		nullptr,
		WS_CHILD | WS_CLIPCHILDREN | WS_VSCROLL | WS_HSCROLL,
		MdiClient.x, MdiClient.y, MdiClient.width, MdiClient.height,
		MainWindow.hwnd, (HMENU)0xCAC, hInst, (LPVOID)&ccs);
	ShowWindow (MdiClient.hwnd,SW_SHOW);
	WriteMessage(T("mdi=%X"), MdiClient.hwnd);

	// create tool windows
	DockFrame_Create(MdiClient.hwnd, T("Painters list"), WS_VISIBLE, WS_EX_TOOLWINDOW|WS_EX_MDICHILD|WS_EX_TOPMOST, PaintersFrame.x,PaintersFrame.y, PaintersFrame.width,PaintersFrame.height, 0, &PaintersFrameProc);
	DockFrame_Create(MdiClient.hwnd, T("Layer list"),  WS_VISIBLE, WS_EX_TOOLWINDOW|WS_EX_MDICHILD|WS_EX_TOPMOST, LayersFrame.x,LayersFrame.y, LayersFrame.width,LayersFrame.height, 0, &LayersFrameProc);
	DockFrame_Create(MdiClient.hwnd, T("Properties"),  WS_VISIBLE, WS_EX_TOOLWINDOW|WS_EX_MDICHILD|WS_EX_TOPMOST, PropertiesFrame.x,PropertiesFrame.y, PropertiesFrame.width,PropertiesFrame.height, 0, &PropertiesFrameProc);

	// create main display window
	//HWND MainPreview.hwnd = CreateMDIWindow(MdiWindowClass, T("Main Display - All Layers"), WS_VISIBLE|WS_VSCROLL|WS_HSCROLL, 0,0, CW_USEDEFAULT,CW_USEDEFAULT, MdiClient.hwnd, hInst, nullptr);
	CreateChildWindow(&MainPreview, MdiClient.hwnd);
	SendMessage(MdiClient.hwnd, WM_MDIACTIVATE, (WPARAM)(HWND)MainPreview.hwnd, 0);

	// painters tree view
	// http://win32assembly.online.fr/tut19.html
	CreateChildWindow(&PaintersTree, PaintersFrame.hwnd);

	// tile windows so they don't overlap
	{
		RECT rect;
		DetermineMdiClientRect(MdiClient.hwnd, &rect);
		TileWindows(MdiClient.hwnd, 0, &rect, 0, nullptr);
	}

	ShowWindow(MainWindow.hwnd, nCmdShow);
	UpdateWindow(MainWindow.hwnd);

	PopulatePaintersTree();

	OpenProjects.resize(1); // start with one empty project automatically
	//MainCanvas.init(1,1, FracturedCanvas::Formats::u8);

	return TRUE;
}


void FreeMainInstance()
{
	int size = (int)OpenProjects.size();
	for (int i = 0; i < size; i++) {	// todo: should just use STL iterator, but they are foreign to me yet
		// uhm, fix this
		OpenProjects[i].layers.clear();
	}
	OpenProjects.clear();

}


/** Dispatches messages for the main window.
*/
void WndProcDispatch(MSG* pmsg)
{
	// later need to add check for focus being on a different window like list
	if (!TranslateMDISysAccel(MdiClient.hwnd, pmsg)
	&&	!TranslateAccelerator(MainWindow.hwnd, MainAccelTable, pmsg)) {
		TranslateMessage(pmsg);
		DispatchMessage(pmsg);
	}
}


/** Processes messages for the main window.

	WM_COMMAND	- process the application menu
	WM_PAINT	- Paint the main window
	WM_DESTROY	- post a quit message and return
*/
LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message) 
	{
	case WM_CREATE:
		{
			MainWindow.hwnd = hwnd;
			SetProp(hwnd, T("MsgDispatcher"), &WndProcDispatch);
		}
		break;
	case WM_COMMAND:
		{
			if (HIWORD(wParam) == 1) wParam = LOWORD(wParam); // mask off accelerator key code
			if (DoCommand(hwnd, (HWND)lParam, wParam))
				return 0;

			return DefFrameProc(hwnd, MdiClient.hwnd, message, wParam, lParam);
		}
	case WM_NOTIFY:
		{
			NMHDR* pnmh = (NMHDR*)lParam;
			assert(wParam <= 65535);
			return DoCommand(hwnd, pnmh->hwndFrom, (pnmh->code<<16) | wParam);
		}
	case WM_PRINTCLIENT:
	case WM_PAINT:
		{
			PAINTSTRUCT ps;
			HDC hdc = (message == WM_PRINTCLIENT) ? (HDC)wParam : BeginPaint(hwnd, &ps);
			// TODO: Add any drawing code here...
			if (message != WM_PRINTCLIENT) EndPaint(hwnd, &ps);
		}
		break;
	case WM_TIMER:
		if (OpenProjects.size() > 0 && OpenProjects[0].layers.size() > 0) {
			RenderLayers();
			InvalidateRect( MainPreview.hwnd, nullptr, false );
		}
		break;
	case WM_ERASEBKGND:
		return TRUE;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	case WM_WINDOWPOSCHANGED:
		{
			WINDOWPOS* lpwp = (WINDOWPOS*) lParam;
			if (lpwp->flags & SWP_NOSIZE) break;
		}
	case WM_SIZE: // do not pass to MDI
		ArrangeChildWindows(1);
		break;
	default:
		return DefFrameProc(hwnd, MdiClient.hwnd, message, wParam, lParam);
		//return DefWindowProc(hwnd, message, wParam, lParam);
	}
	return 0;
}


/** Respond to the WM_COMMAND or WM_NOTIFY message.
*/
LRESULT DoCommand(HWND hwnd, HWND src, WPARAM code)
{
	#define idcode(item,msg) ((msg<<16)|(item & 65535))

	dbgmsg(T("command code=%X"), code);
	// Parse the menu selections:
	switch (code)
	{
	case idcode(IdmAbout, BN_CLICKED):
		if (AboutHwnd == nullptr)
			CreateDialog(hInst, (LPCTSTR)IddAbout, hwnd, (DLGPROC)AboutProc);
		else
			SetActiveWindow(AboutHwnd);
		break;
	case idcode(IdmExit, BN_CLICKED):
		DestroyWindow(hwnd);
		break;

	case IDM_WINDOWTILE:
		// Tile MDI windows
		//SendMessage (MdiClient.hwnd, WM_MDITILE, 0, 0L);
		{
			RECT rect;
			DetermineMdiClientRect(MdiClient.hwnd, &rect);
			TileWindows(MdiClient.hwnd, 0, &rect, 0, nullptr);
		}
		break;
	case IDM_WINDOWCASCADE:
		// Cascade MDI windows
		//SendMessage (MdiClient.hwnd, WM_MDICASCADE, 0, 0L);
		{
			RECT rect;
			DetermineMdiClientRect(MdiClient.hwnd, &rect);
			CascadeWindows(MdiClient.hwnd, 0, &rect, 0, nullptr);
		}
		break;
	case IDM_WINDOWICONS:
		// Auto - arrange MDI icons
		SendMessage (MdiClient.hwnd, WM_MDIICONARRANGE, 0, 0L);
		break;
	case IDM_WINDOWCLOSEALL:
		// Abort operation if something is not saved
		//if (!QueryCloseAllChildren())
		//	break;
		//CloseAllChildren();
		// Show the window since CloseAllChilren() hides the window
		// for fewer repaints.
		ShowWindow(MdiClient.hwnd, SW_SHOW);
		break;

	case IdmTestFractal:
		QuickAndDirtyPainterTest();
		break;

	case idcode(IdcPaintersTree, NM_RETURN):
	case idcode(IdcPaintersTree, NM_DBLCLK):
		CreateSelectedPainter();
		break;

	default:
		return false;
	}
	return true;
	#undef idcode
}


// creates a child window in the main window.
static void CreateChildWindow(ChildWindowStruct* cws)
{
	CreateChildWindow(cws, MainWindow.hwnd);
}

// creates a child window based on a child window structure
static void CreateChildWindow(ChildWindowStruct* cws, HWND hwnd)
{
	cws->hwnd=CreateWindowEx(
		cws->styleEx,
		cws->className,
		cws->caption,
		cws->style,
		cws->x,
		cws->y,
		cws->width,
		cws->height,
		hwnd,
		(HMENU)cws->id,
		hInst, //GetModuleHandle(nullptr),
		cws->param);

	if (!cws->hwnd) {
		TCHAR text[256];
		wsprintf(text, T("Failed to create window:\nClass=%s\nId=%d\n\nThe program will probably not work right :(."), cws->className,cws->id);
		//-MessageBox(nullptr, text, MainWindowTitle, MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
		//if (MessageBox (0, text, ProgTitle, MB_OKCANCEL|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL) != IDOK)
			//ExitProcess (-1);
	}
}



/** Calculates/sets child control positions.
*/
static void ArrangeChildWindows(int mode)
{
	RECT rect;
	GetClientRect(MainWindow.hwnd, &rect);

	MdiClient.x = 0;
	MdiClient.y = 0;
	MdiClient.width  = rect.right;
	MdiClient.height = rect.bottom;

	/*
	PaintersFrame.width = 180;
	LayersFrame.width = 180;
	PaintersFrame.height = rect.bottom*2 / 3;
	LayersFrame.height = rect.bottom - PaintersFrame.height;
	LayersFrame.y = PaintersFrame.height;
	*/

	if (mode) {
		SizeChildWindow(&MdiClient);
		//HDWP hdwp = BeginDeferWindowPos(10);
		//SizeChildWindow(&MdiClient, hdwp);
		//SizeChildWindow(&PaintersFrame, hdwp);
		//SizeChildWindow(&LayersFrame, hdwp);
		//EndDeferWindowPos(hdwp);
	}

}

static void SizeChildWindow(ChildWindowStruct *cws) {
	SetWindowPos(cws->hwnd,nullptr, cws->x,cws->y, cws->width,cws->height, SWP_NOZORDER|SWP_NOACTIVATE);
}


static void SizeChildWindow(ChildWindowStruct *cws, HDWP hdwp)
{
	if (IsWindow(cws->hwnd)) // detect possible errors where window was closed
		DeferWindowPos(hdwp, cws->hwnd,nullptr, cws->x,cws->y, cws->width,cws->height, SWP_NOZORDER|SWP_NOACTIVATE);
}


// determines the maximal area for the display windows after excluding tool windows
// ** only correctly determines area if tool windows are stacked
// ** on the left or right sides (not top and bottom).
void DetermineMdiClientRect(HWND hwnd, RECT* prect)
{
	RECT rect;
	GetClientRect(hwnd, &rect);
	POINT halfSize;
	halfSize.x = rect.right/2;
	halfSize.y = rect.bottom/2;
	HWND nextWindow = GetTopWindow(hwnd);
	while (nextWindow) {
		//-TCHAR title[256];
		//GetWindowText(hwnd, title, elmsof(title));
		//dbgmsg(T("window=%X '%s'"), hwnd, title);

		LONG styleEx = GetWindowLong(nextWindow, GWL_EXSTYLE);
		if (styleEx & WS_EX_TOOLWINDOW) {
			RECT toolRect;
			GetWindowRect(nextWindow, &toolRect);
			toolRect.right -= toolRect.left;
			toolRect.bottom -= toolRect.top;
			ScreenToClient(hwnd, (POINT*)&toolRect);
			if (toolRect.left < rect.right  && toolRect.left > halfSize.x)
				rect.right = toolRect.left;
			//if (toolRect.top  < rect.bottom && toolRect.top  > halfSize.x)
			//	rect.bottom = toolRect.top;
			if (toolRect.left+toolRect.right > rect.left && toolRect.left+toolRect.right < halfSize.x)
				rect.left = toolRect.left+toolRect.right;
			//if (toolRect.top+toolRect.bottom > rect.top  && toolRect.top+toolRect.bottom < halfSize.y)
			//	rect.top = toolRect.top+toolRect.bottom;
		}
		nextWindow = GetWindow(nextWindow, GW_HWNDNEXT);
	}
	*prect = rect;
}


/** Processes messages for the layer window.
*/
LRESULT CALLBACK MdiWndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{

	switch (message) 
	{
	case WM_CREATE:
		{
			SetWindowLongPtr(hwnd, GWL_USERDATA, (LONG)(LONG_PTR)lParam);
			WriteMessage(T("mdi child created"));
		}
		break;
	/*
	case WM_COMMAND:
		{
			if (HIWORD(wParam) == 1) wParam = LOWORD(wParam); // mask off accelerator key code
			return DoCommand(hwnd, message, wParam, lParam, (HWND)lParam, wParam);
		}
	case WM_NOTIFY:
		{
			NMHDR* pnmh = (NMHDR*)lParam;
			return DoCommand(hwnd, message, wParam, lParam, pnmh->hwndFrom, (wParam<<16) | pnmh->code);
		}
	*/
	case WM_PAINT:
		{
			PAINTSTRUCT ps;

			HDC hdc = BeginPaint(hwnd, &ps);

			if (!OpenProjects.empty() && !OpenProjects[0].layers.empty()) {

				FracturedLayer* layers = &OpenProjects[0].layers[0];
				FracturedCanvas* canvasSrc = &layers[0].canvas;
				FracturedCanvas* canvasPal = &layers[1].canvas;

				//HDC hdc = GetDC(MainPreview.hwnd);
				struct {
					BITMAPINFOHEADER hdr;
					//RGBQUAD colors[256];
					int32 colors[256];
				} bmi;
				bmi.hdr.biSize = sizeof(BITMAPINFOHEADER);
				bmi.hdr.biWidth = canvasPal->width;
				bmi.hdr.biHeight = -canvasPal->height;
				bmi.hdr.biPlanes = 1;
				bmi.hdr.biBitCount = canvasPal->bipp;
				bmi.hdr.biCompression = BI_RGB;
				bmi.hdr.biSizeImage = 0;
				bmi.hdr.biXPelsPerMeter = 1;
				bmi.hdr.biYPelsPerMeter = 1;
				bmi.hdr.biClrUsed = 256;
				bmi.hdr.biClrImportant = 240;
				//palette.init( PaintPalette::SpecieHsva, 360*4, 0, .8,.8, 1,1, 0,255, 0 ); // pretty blue electricity
				//palette.init( PaintPalette::SpecieHsva, 240,-100,  2,-10, 2,-10, 0,255, 0 ); // for day&night faded
				//layers[0].painter->draw(canvasSrc, canvasSrc, &FracturedPainter::dummyProgress);
				//layers[1].painter->draw(canvasPal, canvasSrc, &FracturedPainter::dummyProgress);
				//palette.init( PaintPalette::SpecieHsva, 0,360,  .2,1, .1,.8, 0,255, 0 ); // for life faded
				//palette.init( PaintPalette::SpecieHsva, 360*2-60, 0, 1,-5, 1,.0, 0,255, 0 ); // pretty blue electricity
				//memcpy( bmi.colors, palette.palette, sizeof(bmi.colors) );
				//for (uint c = 0; c < bmi.hdr.biClrUsed; c++) {
				//	#define BLUE	(0x00000001)
				//	#define GREEN	(0x00000100)
				//	#define RED		(0x00010000)
				//	#define ALPHA	(0x01000000)
				//	bmi.colors[c] =
				//		ALPHA * c
				//		+ BLUE  * int(log(c+1.0) * 46)
				//		+ RED   * (255-int(sqrt(c+1.0) * 32))
				//		+ GREEN * int(sin(c*M_PI/32 + M_PI/4)*127+128);
				//		;
				//	#undef BLUE
				//	#undef GREEN
				//	#undef RED
				//	#undef ALPHA
				//}
				SetDIBitsToDevice(ps.hdc, 0,0, canvasPal->width,canvasPal->height, 0,0, 0,canvasPal->height, canvasPal->pixels, (BITMAPINFO*)&bmi, DIB_RGB_COLORS);
			}
			EndPaint(hwnd, &ps);
		}
		break;
	//case WM_ERASEBKGND:
	//	return TRUE;
	default:
		return DefMDIChildProc(hwnd, message, wParam, lParam);
	}
	return 0;
}


/** Dispatches messages for modeless dialog boxes.
*/
void DlgProcDispatch(MSG* pmsg)
{
	//if (!IsDialogMessage(AboutHwnd, pmsg)) {
	if (!IsDialogMessage(GetParent(pmsg->hwnd), pmsg)) {
		TranslateMessage(pmsg);
		DispatchMessage(pmsg);
	}
}


/** Message handler for about box.
*/
LRESULT CALLBACK AboutProc(HWND hdlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	WriteMessage(T("msg=%X hwnd=%X"), message, hdlg);
	switch (message)
	{
	case WM_INITDIALOG:
		AboutHwnd = hdlg;
		SetProp(hdlg, T("MsgDispatcher"), &DlgProcDispatch);
		SetDlgItemText(hdlg, IdcAboutText,
			T("Fractured v1.0\r\n")
			T("Copyright (c) 2005-11-30\r\n")
			T("Dwayne Robinson\r\n")
			T("http://oregonstate.edu/~robinsfr\r\n\r\n")
			T("Multiple layers of fractal images\r\n")
			T("to make pretty pictures for my\r\n")
			T("term project in CS535.")
			);
		return TRUE;

	case WM_ACTIVATE:
		if (LOWORD(wParam) == WA_INACTIVE) {
			//PostMessage(hdlg, WM_CLOSE, 0,0);
		}
		break;
	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) 
		{
			PostMessage(hdlg, WM_CLOSE, 0,0);
			return TRUE;
		}
		break;
	case WM_CLOSE:
		DestroyWindow(hdlg);
		break;
	case WM_DESTROY:
		AboutHwnd = nullptr;
		break;
	}

	return FALSE;
}


LRESULT CALLBACK PaintersFrameProc(HWND hdlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	//WriteMessage(T("msg=%X hwnd=%X"), message, hdlg);
	switch (message)
	{
	case WM_INITDIALOG:
		WriteMessage(T("PaintersFrameProc"));
		SetProp(hdlg, T("MsgDispatcher"), &DlgProcDispatch);
		PaintersFrame.hwnd = hdlg;
		return TRUE;

	case WM_NCACTIVATE:
		WriteMessage(T("PaintersFrame WM_NCACTIVATE"));
		break;
	case WM_MOUSEACTIVATE:
		WriteMessage(T("PaintersFrame WM_MOUSEACTIVATE"));
		break;
	case WM_ACTIVATE:
		WriteMessage(T("PaintersFrame WM_ACTIVATE"));
		if (LOWORD(wParam) == WA_INACTIVE) {
			PostMessage(hdlg, WM_CLOSE, 0,0);
		}
		break;
	case WM_COMMAND:
		{
			if (DoCommand(hdlg, (HWND)lParam, wParam))
				return 0;

			return DefFrameProc(hdlg, MdiClient.hwnd, message, wParam, lParam);
		}
		/*
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) 
		{
			PostMessage(hdlg, WM_CLOSE, 0,0);
			return TRUE;
		}
		*/
	case WM_NOTIFY:
		{
			NMHDR* pnmh = (NMHDR*)lParam;
			assert(wParam <= 65535);
			return DoCommand(hdlg, pnmh->hwndFrom, (pnmh->code<<16) | wParam);
		}
		break;
	case WM_SIZE:
		{
			RECT rect;
			GetClientRect(hdlg, &rect);
			PaintersTree.height = rect.bottom;
			PaintersTree.width = rect.right;
			SizeChildWindow(&PaintersTree);
		}
		break;
	case WM_CLOSE:
		ShowWindow(hdlg, SW_MINIMIZE);
		break;
	case WM_DESTROY:
		break;
	default:
		break;
	}

	return FALSE;
}


LRESULT CALLBACK LayersFrameProc(HWND hdlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	//WriteMessage(T("msg=%X hwnd=%X"), message, hdlg);
	switch (message)
	{
	case WM_INITDIALOG:
		SetProp(hdlg, T("MsgDispatcher"), &DlgProcDispatch);
		LayersFrame.hwnd = hdlg;
		return TRUE;

	/*
	case WM_ACTIVATE:
		if (LOWORD(wParam) == WA_INACTIVE) {
			PostMessage(hdlg, WM_CLOSE, 0,0);
		}
		break;
		*/
	/*
	case WM_NCPAINT:
		{
			LRESULT ret = DefWindowProc(hdlg, message, wParam, lParam);
			HDC hdc = GetDCEx(hdlg, (HRGN)wParam, DCX_WINDOW | DCX_INTERSECTRGN | 0x10000);
			RECT rect = {0,0,100,30};
			DrawCaption(hdlg, hdc, &rect, DC_ACTIVE|DC_SMALLCAP|DC_TEXT);
			ReleaseDC(hdlg, hdc);
			return ret;
		}
		*/
	case WM_COMMAND:
		/*
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) 
		{
			PostMessage(hdlg, WM_CLOSE, 0,0);
			return TRUE;
		}
		*/
		break;
	case WM_CLOSE:
		//DestroyWindow(hdlg);
		ShowWindow(hdlg, SW_MINIMIZE);
		break;
	case WM_DESTROY:
		break;
	default:
		//DefDockableProc(hdlg, message, wParam, lParam);
		break;
	}

	return FALSE;
}


////////////////////////////////////////

static HWND hAttribList;

/* todo: delete */
void AppendPropertiesAttribItem (AttribListItem* alis, AttribListItem::FloatInt value, AttribListItem* alid, int& index)
{
	alid[index] = *alis;
	alid[index].value = value;
}


enum {
	IdcScaleX=256, IdcScaleY, IdcScaleZ,
	IdcOriginX, IdcOriginY, IdcOriginZ,
	IdcAngle, IdcShearX, IdcShearY,
	IdcFormat,
	IdcApplyCanvas, IdcApplyCanvasLive,
	IdcApplyPainter, IdcApplyPainterLive,
	IdcPainterDefaults,
};

void CopyPropertyToAttribItem(AttribListItem& ali, FracturedPainter::VarInfo& vi)
{
	switch (vi.type & vi.TypeMask) {
	case vi.TypeEol: /// indicates end of list
		break;
	case vi.TypeBool: /// true,false; yes,no
		ali.low.i = 0;
		ali.high.i = 1;
		ali.def.i = 0;
		ali.flags = AttribList::TypeButton;
		break;
	case vi.TypeInt: /// integer signed
		ali.low.i = vi.low.i;
		ali.high.i = vi.high.i;
		ali.def.i = vi.def.i;
		ali.flags = AttribList::TypeNumeric;
		break;
	case vi.TypeFloat: /// floating point
		ali.low.f = vi.low.f;
		ali.high.f = vi.high.f;
		ali.def.f = vi.def.f;
		ali.flags = AttribList::TypeNumeric|AttribList::FlagDecimal;
		break;
	case vi.TypeDouble: /// double precision
		ali.low.f = vi.low.f;
		ali.high.f = vi.high.f;
		ali.def.f = vi.def.f;
		ali.flags = AttribList::TypeNumeric|AttribList::FlagDecimal;
		break;
	case vi.TypeList: /// list of choices (like palette type RGB, HSL, Grey...)
		ali.low.i = 0;
		ali.high.i = 0;
		ali.def.i = 0;
		ali.flags = AttribList::TypeMenu;
		break;
	case vi.TypeString: /// editable array of characters
		ali.low.i = 0;
		ali.high.i = vi.high.i;
		ali.def.i = 0;
		ali.flags = AttribList::TypeEdit;
		break;
	case vi.TypeLabel: /// informational string, not editable
		ali.low.i = 0;
		ali.high.i = 0;
		ali.def.i = 0;
		ali.flags = ((signed)vi.id <= 0) ? AttribList::TypeTitle : AttribList::TypeLabel;
		ali.text = vi.def.sw;
		break;
	case vi.TypeAction: /// an action specific to the filter (like Reset)
		ali.low.i = 0;
		ali.high.i = 0;
		ali.def.i = 0;
		ali.flags = AttribList::TypeButton;
		break;
	}
	ali.flags |= ((vi.id+1) & AttribList::FlagIdMask);
}

// gets properties of painter and shows them in window
// this function seems way to complicated :-/
void GetPainterProperties(int layerIdx)
{
	if (OpenProjects.empty()) return;

	// allocate attriblist structure of size  #props + #buttons + #canvas elements
	vector<FracturedLayer>& layers = OpenProjects[0].layers;
	FracturedPainter::VarInfo* varInfo =
		(FracturedPainter::VarInfo*) layers[layerIdx].painter->supports( FracturedPainter::SupportsVars );

	int numElms = 0;

	const static AttribListItem painterAlis[] = {
		{AttribList::TypeSeparator, nullptr, nullptr,nullptr, 0,  0,0, 0,0},
		{AttribList::TypeButton | IdcApplyPainter, T("Apply"), nullptr,nullptr, 0,  0,0, 0,0},
		{AttribList::TypeButton|AttribList::FlagHidden | IdcApplyPainterLive, T("Apply live"), nullptr,nullptr, 0,  0,0, 0,1},
		{AttribList::TypeButton | IdcPainterDefaults, T("Defaults"), nullptr,nullptr, 0,  0,0, 0,0},
		{AttribList::TypeSeparator, nullptr, nullptr,nullptr, 0,  0,0, 0,0},
	};
	FracturedCanvas& canvas = layers[layerIdx].canvas;
	// common canvas properties
	const static AttribListItem canvasAlis[] = {
		{AttribList::TypeTitle, T("Canvas options"), nullptr,nullptr, 0,  0,0, 0,0},
		{AttribList::TypeNumeric | AttribList::FlagDecimal | IdcScaleX, T("Scale X"), nullptr,nullptr, 0,  (float)canvas.scalex,1.f, 0,0},
		{AttribList::TypeNumeric | AttribList::FlagDecimal | IdcScaleY, T("Scale Y"), nullptr,nullptr, 0,  (float)canvas.scaley,1.f, 0,0},
		{AttribList::TypeNumeric | AttribList::FlagDecimal | IdcScaleZ, T("Scale Z"), nullptr,nullptr, 0,  (float)canvas.scalez,1.f, 0,0},
		{AttribList::TypeNumeric | AttribList::FlagDecimal | IdcOriginX, T("Origin X"), nullptr,nullptr, 0,  (float)canvas.origx,0, 0,0},
		{AttribList::TypeNumeric | AttribList::FlagDecimal | IdcOriginY, T("Origin Y"), nullptr,nullptr, 0,  (float)canvas.origy,0, 0,0},
		{AttribList::TypeNumeric | AttribList::FlagDecimal | IdcOriginZ, T("Origin Z"), nullptr,nullptr, 0,  (float)canvas.origz,0, 0,0},
		{AttribList::TypeNumeric | AttribList::FlagDecimal | IdcAngle, T("Angle"), nullptr,nullptr, 0,  (float)canvas.angle,0, 0,0},
		{AttribList::TypeNumeric | AttribList::FlagDecimal | IdcShearX, T("Shear X"), nullptr,nullptr, 0, (float)canvas.shearx,0, 0,0},
		{AttribList::TypeNumeric | AttribList::FlagDecimal | IdcShearY, T("Shear Y"), nullptr,nullptr, 0, (float)canvas.sheary,0, 0,0},
		//{AttribList::FlagMenu | IdcFormat, T("Format"), T("8bit\016 bit\032 bit\0\0"),nullptr, 0,  0,0, 0,0},
		{AttribList::TypeSeparator, nullptr, nullptr,nullptr, 0,  0,0, 0,0},
		{AttribList::TypeButton | IdcApplyCanvas, T("Apply"), nullptr,nullptr, 0,  0,0, 0,0},
		{AttribList::TypeButton|AttribList::FlagHidden | IdcApplyCanvasLive, T("Apply live"), nullptr,nullptr, 0,  0,0, 0,1},
		{0}
	};

	// count number of variables painter supports
	if (varInfo != nullptr) {
		for (int i=0; varInfo[i].type != 0; i++) numElms++;
	}
	numElms += elmsof(painterAlis); // common buttons
	numElms += elmsof(canvasAlis);

	// alloc temp list
	// and construct by appending chunks
	AttribListItem* alis = new AttribListItem[numElms];
	int index = 0;

	// get variable values from painter
	FracturedPainter::Var* vars = nullptr;
	layers[layerIdx].painter->store( &vars );

	// append all painter variables
	std::map<int, int> indexMap;
	if (varInfo != nullptr) {
		for (int i=0; varInfo[i].type != 0; i++) {
			AttribListItem& ali = alis[index];
			FracturedPainter::VarInfo& vi = varInfo[i];

			// append property
			ali.label = vi.label;
			ali.text = nullptr;
			ali.description = vi.description;
			ali.icon = 0;
			ali.value.i = 0;
			indexMap[vi.id] = index;
			CopyPropertyToAttribItem(ali, vi);

			// set current value
			if (vi.id >= 0 && vars != nullptr && vars[vi.id].id == vi.id) {
				switch (vi.type & FracturedPainter::VarInfo::TypeMask) {
				case FracturedPainter::VarInfo::TypeBool: /// true,false; yes,no
				case FracturedPainter::VarInfo::TypeInt: /// integer signed
					ali.value.i = vars[vi.id].value.i;
					break;
				case FracturedPainter::VarInfo::TypeFloat: /// floating point
				case FracturedPainter::VarInfo::TypeDouble: /// double precision
					ali.value.f = vars[vi.id].value.f;
					break;
				}
			}
			index++;
		}
	}

	delete vars;

	// overlay specie specific variables onto list
	// if they are different
	FracturedPainter::VarInfo* varSpecieInfo =
		(FracturedPainter::VarInfo*) layers[layerIdx].painter->supports( FracturedPainter::SupportsVarsSpecie );
	if (varSpecieInfo != nullptr) {
		for (int i=0; varSpecieInfo[i].type != 0; i++) {
			FracturedPainter::VarInfo& vi = varSpecieInfo[i];
			std::map<int,int>::iterator match = indexMap.find(vi.id);
			if (match == indexMap.end()) continue; // should not happen, but in case
			AttribListItem& ali = alis[match->second];

			if (vi.label != nullptr) ali.label = vi.label;
			//ali.text = nullptr;
			if (vi.description != nullptr) ali.description = vi.description;
			CopyPropertyToAttribItem(ali, vi);
		}
	}

	smemcpy( &alis[index], painterAlis, elmsof(painterAlis));   index += elmsof(painterAlis);
	smemcpy( &alis[index], canvasAlis, elmsof(canvasAlis));   //index += elmsof(canvasAlis);

	// send template to attribute list
	SendMessage(hAttribList, AttribList::WmSetItems, 0, (LPARAM)alis);
	ListBox_SetCurSel(hAttribList, 1 | AttribList::SelectByPos);

	delete alis;
}


// applies current properties to painter
// this functions seems way to complicated :-/
void ApplyPainterProperties(int layerIdx)
{
	if (OpenProjects.empty()) return;

	// allocate attriblist structure of size  #props + #buttons + #canvas elements
	FracturedLayer* layers = &OpenProjects[0].layers[0];
	FracturedPainter::VarInfo* varInfo =
		(FracturedPainter::VarInfo*) layers[layerIdx].painter->supports( FracturedPainter::SupportsVars );

	// count number of variables painter supports
	if (varInfo == nullptr) return;

	// count # variables supported
	int numVars = 0;
	for (int i=0; varInfo[i].type != 0; i++) numVars++;
	FracturedPainter::Var* vars = new FracturedPainter::Var[numVars+1];

	// count and access attribute list
	AttribListItem* alis = (AttribListItem*) SendMessage( hAttribList, AttribList::WmGetItems, 0,0);
	int numItems = ListBox_GetCount( hAttribList );

	// map variable locations to item positions
	std::map<int, int> indexMap;
	for (int i = 0; i < numItems; i++) {
		int id =(alis[i].flags & AttribList::FlagIdMask) - 1;
		if ((unsigned)id < 256) indexMap[id] = i;
	}

	// copy variables into variable structure
	int i = -1;
	for (i = 0; i < numVars; i++) {
		FracturedPainter::VarInfo& vi = varInfo[i];

		std::map<int,int>::iterator match = indexMap.find(vi.id);
		if (match == indexMap.end()) {
			vars[i].id = (unsigned)-1 >> 1; // supply invalid id so painter will ignore it
			continue; // should not happen, but in case
		}
		vars[i].id = vi.id;
		AttribListItem& ali = alis[match->second];

		switch (vi.type & vi.TypeMask) {
		case FracturedPainter::VarInfo::TypeBool: /// true,false; yes,no
		case FracturedPainter::VarInfo::TypeInt: /// integer signed
		case FracturedPainter::VarInfo::TypeList: /// list of choices (like palette type RGB, HSL, Grey...)
			vars[i].value.i = ali.value.i;
			break;
		case FracturedPainter::VarInfo::TypeFloat: /// floating point
		case FracturedPainter::VarInfo::TypeDouble: /// double precision
			vars[i].value.f = ali.value.f;
			break;
		case FracturedPainter::VarInfo::TypeString: /// editable array of characters
			//...
			break;
		case FracturedPainter::VarInfo::TypeLabel: /// informational string, not editable
			break;
		case FracturedPainter::VarInfo::TypeAction: /// an action specific to the filter (like Reset)
			break;
		}
	}
	vars[i].id = -1; // end of list

	// pass to painter
	layers[layerIdx].painter->load( vars );

	// update, redraw
	RenderLayers();
	InvalidateRect( MainPreview.hwnd, nullptr, false );

	delete vars;
}


void ApplyCanvasProperties(int layerIdx)
{
	if (OpenProjects.empty()) return;

	// allocate attriblist structure of size  #props + #buttons + #canvas elements
	FracturedLayer* layers = &OpenProjects[0].layers[0];
	FracturedCanvas& canvas = layers[layerIdx].canvas;
	//FracturedPainter::VarInfo* varInfo =
	//	(FracturedPainter::VarInfo*) layers[layerIdx].painter->supports( FracturedPainter::SupportsVars );

	// count and access attribute list
	AttribListItem* alis = (AttribListItem*) SendMessage( hAttribList, AttribList::WmGetItems, 0,0);
	int numItems = ListBox_GetCount( hAttribList );

	// map variable locations to item positions
	std::map<int, int> indexMap;
	for (int i = 0; i < numItems; i++) {
		int id =(alis[i].flags & AttribList::FlagIdMask);
		if ((unsigned)id >= 256) indexMap[id] = i;
	}

	canvas.origx = alis[indexMap[IdcOriginX]].value.f;
	canvas.origy = alis[indexMap[IdcOriginY]].value.f;
	canvas.origz = alis[indexMap[IdcOriginZ]].value.f;

	canvas.scalex = alis[indexMap[IdcScaleX]].value.f;
	canvas.scaley = alis[indexMap[IdcScaleY]].value.f;
	canvas.scalez = alis[indexMap[IdcScaleZ]].value.f;

	canvas.angle = alis[indexMap[IdcAngle]].value.f;
	canvas.shearx = alis[indexMap[IdcShearX]].value.f;
	canvas.sheary = alis[indexMap[IdcShearY]].value.f;

	canvas.matrixCalc();

	// update, redraw
	RenderLayers();
	InvalidateRect( MainPreview.hwnd, nullptr, false );
}


void PropertiesFrameResize(HWND hwnd)
{
	RECT rect;
	GetClientRect( hwnd, &rect);
	MoveWindow( hAttribList, 0,0, rect.right, rect.bottom, true);
}


LRESULT CALLBACK PropertiesFrameProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	//WriteMessage(T("msg=%X hwnd=%X"), message, hwnd);
	switch (message)
	{
	case WM_INITDIALOG:
		SetProp(hwnd, T("MsgDispatcher"), &DlgProcDispatch);
		PropertiesFrame.hwnd = hwnd;
		{
			static TCHAR textBuffer[256];
			const static AttribListItem items[] = {
				/* // ignore this test data
				{AttribList::FlagPushable, T("Defaults"), nullptr, 0,  0,0, 0,0},
				{AttribList::FlagPushable, T("Apply"), nullptr, 0,  0,0, 0,0},
				{AttribList::FlagPushable, T("Immediate apply"), nullptr, 0,  0,0, 0,1},
				{AttribList::FlagPushable, T("High quality"), T("Slow\0Fast"), 0,  0,0, 0,1},
				{AttribList::FlagPushable, T("Go fast"), nullptr, 0,  0,0, 0,1},
				{AttribList::FlagNumeric, T("Bail-out"), T("Label"), 0,  0,0, 0,100},
				{AttribList::FlagEditable, T("Name"), textBuffer, 0,  0,0, 0,(int)elmsof(textBuffer)},
				{AttribList::FlagTitle|AttribList::FlagDisabled, T("Hello world"), T("Works"), 0,  0,0, 0,0},
				{AttribList::FlagMenu, T("Model"), T("Mandelbrot 2\0Mandelbrot 3\0Julia 2\0Julia 3\0\0"), 0,  0,0, 0,0},
				{AttribList::FlagMenu, T("Color by"), T("Escape count\0Orbits\0Final vector\0\0"), 0,  0,0, 0,0},
				*/
				{AttribList::FlagDisabled, T("No properties"), nullptr, nullptr, 0,  0,0, 0,0},
				{0}
			};
			hAttribList = CreateWindowEx (0, //WS_EX_CLIENTEDGE,
				AttribListClass,
				nullptr,
				WS_CHILD | WS_VSCROLL | WS_VISIBLE,
				0,0, 100, 200,
				hwnd, (HMENU)0, hInst, (LPVOID)0);
			SendMessage(hAttribList, AttribList::WmSetItems, 0, (LPARAM)&items);
			PropertiesFrameResize(hwnd);
		}
		return TRUE;

	case WM_SIZE:
		PropertiesFrameResize(hwnd);
		return TRUE;
	/*
	case WM_ACTIVATE:
		if (LOWORD(wParam) == WA_INACTIVE) {
			PostMessage(hwnd, WM_CLOSE, 0,0);
		}
		break;
		*/
	/*
	case WM_NCPAINT:
		{
			LRESULT ret = DefWindowProc(hwnd, message, wParam, lParam);
			HDC hdc = GetDCEx(hwnd, (HRGN)wParam, DCX_WINDOW | DCX_INTERSECTRGN | 0x10000);
			RECT rect = {0,0,100,30};
			DrawCaption(hwnd, hdc, &rect, DC_ACTIVE|DC_SMALLCAP|DC_TEXT);
			ReleaseDC(hwnd, hdc);
			return ret;
		}
		*/
	case WM_COMMAND:
		switch (LOWORD(wParam)) {
		case IdcApplyPainter:
		case IDOK:
			ApplyPainterProperties(0);
			break;
		case IdcApplyCanvas:
			ApplyCanvasProperties(0);
			break;
		case IdcPainterDefaults:
			if (OpenProjects.empty()) break;
			OpenProjects[0].layers[0].painter->init();
			GetPainterProperties(0);
			break;
		}
		break;
		/*
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) 
		{
			PostMessage(hwnd, WM_CLOSE, 0,0);
			return TRUE;
		}
		*/
		break;
	case WM_CLOSE:
		//DestroyWindow(hwnd);
		ShowWindow(hwnd, SW_MINIMIZE);
		break;
	case WM_DESTROY:
		hAttribList = nullptr;
		break;
	default:
		//DefDockableProc(hwnd, message, wParam, lParam);
		break;
	}

	return FALSE;
}


////////////////////////////////////////////////////////////////////////////////

struct PainterSpecieName {
	TCHAR* name;
	int specie;
};

void __stdcall AddPaintersTreeItem(const PainterSpecieName* species, HTREEITEM branch)
{
	static TV_INSERTSTRUCT tvis = {TVI_ROOT, TVI_LAST,
		{
			TVIF_CHILDREN|TVIF_PARAM|TVIF_TEXT, //mask
			nullptr, //hItem
			0, //state
			0, //stateMask
			nullptr, //pszText
			0, //cchTextMax
			0, //iImage
			0, //iSelectedImage
			0, //cChildren
			0, //lParam
		}
	};

	tvis.hParent = branch;

	// enumerate all species
	for (;species->name != nullptr; species++) {
		tvis.item.pszText = species->name;
		tvis.item.lParam = species->specie;
		TreeView_InsertItem(PaintersTree.hwnd, &tvis);
	}
}


void PopulatePaintersTree()
{
	static TV_INSERTSTRUCT tvis = {TVI_ROOT, TVI_LAST,
		{
			TVIF_CHILDREN|TVIF_PARAM|TVIF_TEXT, //mask
			nullptr, //hItem
			0, //state
			0, //stateMask
			T("Branch"), //pszText
			0, //cchTextMax
			0, //iImage
			0, //iSelectedImage
			1, //cChildren
			0, //lParam
		}
	};
	HTREEITEM branch;

	/*
	enum workyoudummy {
		nop,		// uhm, nothing
		complex,	// complex numbers like Mandelbrot and Julia
		perlin,		// Perlin noise
		plasma,		// recursive plasma
		ifs,		// iterated function system
		flame,		// flame algorithm (maybe should be merged with above)
		diffusion,	// reaction diffusion
		lsystem,	// simple repetitive Lindenmeyer systems
		automata,	// cellular automata (like life)
	};
	*/

	////////////////////
	tvis.item.pszText = T("Complex");
		branch = TreeView_InsertItem(PaintersTree.hwnd, &tvis);

		const static PainterSpecieName complexSpecies[] = 
		{
			T("Mandelbrot^2"), DefSpecies(complex, PaintComplex::SpecieMandelbrot2),
			T("Mandelbrot^3"), DefSpecies(complex, PaintComplex::SpecieMandelbrot3),
			T("Mandelbrot^4"), DefSpecies(complex, PaintComplex::SpecieMandelbrot4),
			T("Julia^2"), DefSpecies(complex, PaintComplex::SpecieJulia2),
			T("Julia^3"), DefSpecies(complex, PaintComplex::SpecieJulia3),
			T("Julia^4"), DefSpecies(complex, PaintComplex::SpecieJulia4),
			0, 0
		};
		AddPaintersTreeItem(complexSpecies, branch);

	////////////////////
	tvis.item.pszText = T("Noise");
		branch = TreeView_InsertItem(PaintersTree.hwnd, &tvis);

		const static PainterSpecieName noiseSpecies[] = 
		{
			T("Perlin"), DefSpecies(perlin, 0),
			T("Plasma"), DefSpecies(plasma, 0),
			0, 0
		};
		AddPaintersTreeItem(noiseSpecies, branch);

	/*
	////////////////////
	tvis.item.pszText = T("IFS");
		branch = TreeView_InsertItem(PaintersTree.hwnd, &tvis);

	////////////////////
	tvis.item.pszText = T("Flame");
		branch = TreeView_InsertItem(PaintersTree.hwnd, &tvis);

	////////////////////
	tvis.item.pszText = T("Diffusion");
		branch = TreeView_InsertItem(PaintersTree.hwnd, &tvis);
		*/

	////////////////////
	tvis.item.pszText = T("Cyclic Automata");
		branch = TreeView_InsertItem(PaintersTree.hwnd, &tvis);

		const static PainterSpecieName cyclicAutomataSpecies[] = 
		{
			T("Macaroni"), DefSpecies(automata, 0),
			T("Lavalamp"), DefSpecies(automata, 1),
			T("Multistrands"), DefSpecies(automata, 2),
			T("Cyclic spirals"), DefSpecies(automata, 3),
			0, 0
		};
		AddPaintersTreeItem(cyclicAutomataSpecies, branch);

	////////////////////
	tvis.item.pszText = T("Life");
		branch = TreeView_InsertItem(PaintersTree.hwnd, &tvis);

		const static PainterSpecieName lifeSpecies[] = 
		{
			T("Life"), DefSpecies(life, 0),
			T("Day & Night"), DefSpecies(life, 1),
			0, 0
		};
		AddPaintersTreeItem(lifeSpecies, branch);

		/*
	////////////////////
	tvis.item.pszText = T("Conversion");
		branch = TreeView_InsertItem(PaintersTree.hwnd, &tvis);

		const static PainterSpecieName conversionSpecies[] = 
		{
			T("Magnitude"), DefSpecies(automata, 0),
			T("Angle"), DefSpecies(automata, 1),
			0, 0
		};
		AddPaintersTreeItem(conversionSpecies, branch);

	////////////////////
	tvis.item.pszText = T("Transformation");
		branch = TreeView_InsertItem(PaintersTree.hwnd, &tvis);

		const static PainterSpecieName transformationSpecies[] = 
		{
			T("Flip horizontal"), DefSpecies(automata, 0),
			T("Flip vertical"), DefSpecies(automata, 1),
			0, 0
		};
		AddPaintersTreeItem(transformationSpecies, branch);

	////////////////////
	tvis.item.pszText = T("Palette");
		branch = TreeView_InsertItem(PaintersTree.hwnd, &tvis);

		const static PainterSpecieName paletteSpecies[] = 
		{
			T("Rainbow"), DefSpecies(automata, 0),
			T("Monochrome"), DefSpecies(automata, 1),
			T("Logarithmic"), DefSpecies(automata, 1),
			0, 0
		};
		AddPaintersTreeItem(paletteSpecies, branch);
	*/

/* // copied from fractured.h for convenient reference
enum FracturedFamily {
	nop,		// uhm, nothing
	complex,	// complex numbers like Mandelbrot and Julia
	perlin,		// Perlin noise
	plasma,		// recursive plasma
	ifs,		// iterated function system
	flame,		// flame algorithm (maybe should be merged with above)
	diffusion,	// reaction diffusion
	lsystem,	// simple repetitive Lindenmeyer systems
	automata,	// cellular automata (like life)
};
*/

	/*tvis.item.pszText = T("Child item 1");
	TreeView_InsertItem(PaintersTree.hwnd, &tvis);
	tvis.item.pszText = T("Child item 2");
	TreeView_InsertItem(PaintersTree.hwnd, &tvis);
	*/

}


void CreateGivenPainter(int painterSpecie)
{
	if (OpenProjects.empty()) {
		OpenProjects.resize(1);
	}
	vector<FracturedLayer>& layers = OpenProjects[0].layers;
	FracturedLayer* layer;
	//OpenProjects[i].layers.clear();

	KillTimer( MainWindow.hwnd, 0 );

	if (layers.size() < 2) {	// allocate one (plus palette)
		layers.resize(2);
		layer = &layers[0];
	} else {	// free the old one
		for (unsigned int i = 0; i < layers.size(); i++) {
			layer = &layers[i];
			layer->canvas.free();
			delete(layer->painter);
			layer->painter = nullptr;
		}
	}
	layer = &layers[0];

	FracturedPainter* painter = nullptr;	// no painter assigned yet
	bool shouldInitPainter = true;

	switch (painterSpecie) {
	case 0:
		return;
	case DefSpecies(complex, PaintComplex::SpecieMandelbrot2):
		painter = new PaintComplex(PaintComplex::SpecieMandelbrot2);
		break;
	case DefSpecies(complex, PaintComplex::SpecieJulia2):
		painter = new PaintComplex(PaintComplex::SpecieJulia2);
		break;
	case DefSpecies(complex, PaintComplex::SpecieMandelbrot3):
		painter = new PaintComplex(PaintComplex::SpecieMandelbrot3);
		break;
	case DefSpecies(complex, PaintComplex::SpecieJulia3):
		painter = new PaintComplex(PaintComplex::SpecieJulia3);
		break;
	case DefSpecies(complex, PaintComplex::SpecieMandelbrot4):
		painter = new PaintComplex(PaintComplex::SpecieMandelbrot4);
		break;
	case DefSpecies(complex, PaintComplex::SpecieJulia4):
		painter = new PaintComplex(PaintComplex::SpecieJulia4);
		break;
	case DefSpecies(perlin, 0):
		painter = new PaintPerlin;
		break;
	case DefSpecies(plasma, 0):
		painter = new PaintPlasma;
		break;
	case DefSpecies(life, 0):
		#define MAKE_LIFE_BITS(a,b,c,d, e,f,g,h, i) ((a<<0)|(b<<1)|(c<<2)|(d<<3)|(e<<4)|(f<<5)|(g<<6)|(h<<7)|(i<<8))
		{
		PaintLife* filter = new PaintLife;
		painter = filter;
		filter->init( MAKE_LIFE_BITS(0,0,1,1,0,0,0,0,0), MAKE_LIFE_BITS(0,0,0,1,0,0,0,0,0) ); // classic conway
		shouldInitPainter = false;
		}
		break;
	case DefSpecies(life, 1):
		{
		PaintLife* filter = new PaintLife;
		painter = filter;
		filter->init( MAKE_LIFE_BITS(0,0,0,1,1,0,1,1,1), MAKE_LIFE_BITS(0,0,0,1,0,0,1,1,1) ); // day & night
		shouldInitPainter = false;
		#undef MAKE_LIFE_BITS
		}
		break;
	case DefSpecies(automata, 0):
		{
		PaintCyclicAutomata* filter = new PaintCyclicAutomata;
		painter = filter;
		filter->init(2, 4, 5, filter->NeighborhoodMoore, filter->ModelGreenbergHastings, filter->WrappingTile); // macaroni
		shouldInitPainter = false;
		}
		break;
	case DefSpecies(automata, 1):
		{
		PaintCyclicAutomata* filter = new PaintCyclicAutomata;
		painter = filter;
		filter->init(2, 10, 3, filter->NeighborhoodMoore, filter->ModelNormal, filter->WrappingTile); // lavalamp
		shouldInitPainter = false;
		}
		break;
	case DefSpecies(automata, 2):
		{
		PaintCyclicAutomata* filter = new PaintCyclicAutomata;
		painter = filter;
		filter->init(5, 15, 6, filter->NeighborhoodMoore, filter->ModelGreenbergHastings, filter->WrappingTile); // multistrands
		shouldInitPainter = false;
		}
		break;
	case DefSpecies(automata, 3):
		{
		PaintCyclicAutomata* filter = new PaintCyclicAutomata;
		painter = filter;
		filter->init(3, 5, 8, filter->NeighborhoodMoore, filter->ModelGreenbergHastings, filter->WrappingTile); // cyclic spirals
		shouldInitPainter = false;
		}
		break;
	default:
		MessageBox(MainWindow.hwnd, T("Somehow you found a filter that is in the list but not actually implemented. Sorry :("), MainWindowTitle, MB_OK|MB_ICONWARNING);
		return;
	}

	// initialize painter
	layer->painter = painter;
	layer->flags = *(int*)painter->supports( painter->SupportsLayerFlags );
	assert( painter->supports(painter->SupportsCanvas) != nullptr );
	layer->canvas.init( 640,480,
		((FracturedPainter::CanvasInfo*) painter->supports(painter->SupportsCanvas))->format );
	layer->canvas.scalex = 120;
	layer->canvas.scaley = 120;
	layer->canvas.scalez = 1;
	layer->canvas.origx = 0;
	layer->canvas.origy = 0;
	layer->canvas.origz = 0;
	layer->canvas.matrixCalc();

	// set timer if animated
	if (layer->flags & layer->FlagAnimated)
		SetTimer( MainWindow.hwnd, 0, 100, nullptr );

	switch (painterSpecie & 0xFFFF0000) {
	case DefSpecies(life, 0):
		{
			// set initial seed values
			unsigned int R1=0x082775212,R2=0x03914AC5F,R3=0x0B460D9C3,R4;
			uint8* p = (uint8*)layer->canvas.pixels;
			int size = layer->canvas.height * layer->canvas.width;
			((PaintLife*)painter)->states = 255;
			int states = ((PaintLife*)painter)->states;
			for (int i = 0; i < size; i++) {
				//p[i] = R1 & 128;
				p[i] = (R1 & 128) ? states : 0;
				R4=R3; R3=R2; R2=R1;
				if(R2>R3)	R1=R3+R4;
				else			R1=R2+R4;
			}
			break;
		}
	case DefSpecies(automata, 0):
		{
			// set initial seed values
			unsigned int R1=0x082775212,R2=0x03914AC5F,R3=0x0B460D9C3,R4;
			//R1 ^= GetTickCount();
			int states = ((PaintCyclicAutomata*)painter)->states;
			uint8* p = (uint8*)layer->canvas.pixels;
			int size = layer->canvas.height * layer->canvas.width;
			for (int i = 0; i < size; i++) {
				p[i] = (R1 & 0x7FFFFFFF) % states;
				R4=R3; R3=R2; R2=R1;
				if(R2>R3)	R1=R3+R4;
				else			R1=R2+R4;
			}
			break;
		}
	case DefSpecies(complex, 0):
		{
			PaintComplex* filter = (PaintComplex*)painter;
			filter->bailOut = 30;
			filter->iterationsMax = 100;
			shouldInitPainter = false;
		}
	}

	if (shouldInitPainter) layer->painter->init();

	// create default palette
	{
		PaintPalette* palette = new PaintPalette;
		if (layer->canvas.bipp > 8) {
			palette->init( PaintPalette::SpecieRgba, 0,255, 64,255, 0,0, 0,255, palette->WrappingNone ); // fire :)
		} else {
			if (layer->flags & layer->FlagLowColor) {
				palette->init( PaintPalette::SpecieHsla, 0,360*16, .5,.5, .5,.5, 0,255, palette->WrappingMirror );
			}
			else {
				palette->init( PaintPalette::SpecieHsva, 0,360,  .4f,1.6f, .0,2, 0,255, palette->WrappingMirror ); // for day&night faded
				palette->palette[0].u32 = 0x00ffff88;
			}

			//palette->init( PaintPalette::SpecieHsva, 0,360,  .2f,1, .1f,.8f, 0,255, palette->WrappingNone ); // for life faded
			//palette->init( PaintPalette::SpecieHsva, 360*2-60, 0, 1,-5, 1,.0, 0,255, palette->WrappingMirror );
			//palette->init( PaintPalette::SpecieHsva, 0,360*2-60, -5,1, .0,1, 0,255, palette->WrappingMirror ); // pretty blue electricity
			//palette->init( PaintPalette::SpecieHsva, 0,360*20, .3,1, 0,20, 0,255, palette->WrappingMirror ); // high freq pastel
			//palette->init( PaintPalette::SpecieHsla, 0,360*20,  .4,.3, .4,.7, 0,255 ); // blue and brown
			//palette->init( PaintPalette::SpecieHsla, 0,360*40,  .3,.0, .0,20, 0,255 ); // gray
			//palette->init( PaintPalette::SpecieHsva, 0,360,  .2,1, .1,.8, 0,255 ); // for life faded
			//palette->init( PaintPalette::SpecieHsva, 0,360,  .4,1.6, .0,2, 0,255, palette->WrappingMirror ); // for day&night faded
			//palette->palette[0].u32 = 127;
			//palette->palette[0].u32 = 0x00000000;
			//palette->init( PaintPalette::SpecieHsva, 0,360*2, .3,1, 0,20, 0,255 ); // lower freq pastel
			//palette->init( PaintPalette::SpecieHsva, 120, 240, 1.5,3.5, 1,3, 0,255 ); // blue marble
			//palette->init( PaintPalette::SpecieRgba, 0,255, 64,255, 0,0, 0,255, palette->WrappingNone ); // fire :)
		}

		// initialize palette
		layer = &layers[1];
		layer->painter = palette;
		layer->flags = *(int*)palette->supports( palette->SupportsLayerFlags );
		assert( palette->supports(palette->SupportsCanvas) != nullptr );
		layer->canvas.init( 640,480,
			((FracturedPainter::CanvasInfo*) palette->supports(palette->SupportsCanvas))->format );
		layer->canvas.scalex = 1;
		layer->canvas.scaley = 1;
		layer->canvas.origx = 0;
		layer->canvas.origy = 0;
		layer->canvas.matrixCalc();
	}
	// map to palette

	GetPainterProperties(0);

	RenderLayers();
	InvalidateRect(MainPreview.hwnd, nullptr, true);

	//pfl->flags |= fl.Flags::modified;
}


// creates a filter based on the selected tree view item
void CreateSelectedPainter()
{
	static TV_ITEM tvi = {
		TVIF_PARAM|TVIF_HANDLE, //mask
		nullptr, //hItem
		0, //state
		0, //stateMask
		0, //pszText
		0, //cchTextMax
		0, //iImage
		0, //iSelectedImage
		0, //cChildren
		0, //lParam
	};
	tvi.hItem = TreeView_GetSelection(PaintersTree.hwnd);
	TreeView_GetItem(PaintersTree.hwnd, &tvi);
	TreeView_GetItem(PaintersTree.hwnd, &tvi);
	CreateGivenPainter( (int)tvi.lParam );
}


void RenderLayers()
{
	FracturedLayer* layers = &OpenProjects[0].layers[0];
	FracturedCanvas* canvasSrc = &layers[0].canvas;
	FracturedCanvas* canvasPal = &layers[1].canvas;
	layers[0].painter->next( canvasSrc );
	layers[0].painter->draw(canvasSrc, canvasSrc, &FracturedPainter::dummyProgress);
	layers[1].painter->draw(canvasPal, canvasSrc, &FracturedPainter::dummyProgress);
}


// for testing new filters
// not really necessary now that the UI properties are nearly finished.
void QuickAndDirtyPainterTest()
{
	FracturedCanvas fs, fs2;
#if 0
	fs.init(640,480, FracturedCanvas::Formats::u8);
#elif 1
	fs.init(640,480, FracturedCanvas::Formats::f32);
	fs2.init(640,480, FracturedCanvas::Formats::u8x4);
#elif 0
	fs.init(640,480, FracturedCanvas::Formats::u8);
	fs2.init(640,480, FracturedCanvas::Formats::u8x4);
#endif
	//fs.init(128,128, FracturedCanvas::Formats::u8);

	int animationDelayMs = 100; // 10x per sec

	#if 0
	PaintPerlin filter;
	filter.init();
	fs.scalex = 100;//1/.043;
	fs.scaley = 100;//1/.043;
	#elif 0
	PaintLife filter;
	filter.init();
	fs.scalex = 1;
	fs.scaley = 1;
	fs.origx = 0;
	fs.origy = 0;
	{
		// set initial seed values
		unsigned int R1=0x082775212,R2=0x03914AC5F,R3=0x0B460D9C3,R4;
		uint8* p = (uint8*)fs.pixels;
		for (int i = 0; i < fs.height*fs.width; i++) {
			//p[i] = R1 & 128;
			p[i] = (R1 & 128) ? 255 : 0;
			R4=R3; R3=R2; R2=R1;
			if(R2>R3)	R1=R3+R4;
			else			R1=R2+R4;
		}
	}
	animationDelayMs = 0;
	#elif 0
	PaintLife filter;
	#define MAKE_LIFE_BITS(a,b,c,d, e,f,g,h, i) ((a<<0)|(b<<1)|(c<<2)|(d<<3)|(e<<4)|(f<<5)|(g<<6)|(h<<7)|(i<<8))
	filter.init( MAKE_LIFE_BITS(0,0,0,1,1,0,1,1,1), MAKE_LIFE_BITS(0,0,0,1,0,0,1,1,1) ); // day & night
	//filter.init( MAKE_LIFE_BITS(0,0,1,1,0,0,0,0,0), MAKE_LIFE_BITS(0,0,0,1,0,0,0,0,0) ); // classic conway
	#undef MAKE_LIFE_BITS
	filter.states = 255;
	fs.scalex = 1;
	fs.scaley = 1;
	fs.origx = 0;
	fs.origy = 0;
	{
		// set initial seed values
		unsigned int R1=0x082775212,R2=0x03914AC5F,R3=0x0B460D9C3,R4;
		uint8* p = (uint8*)fs.pixels;
		for (int i = 0; i < fs.height*fs.width; i++) {
			//p[i] = R1 & 128;
			p[i] = (R1 & 128) ? filter.states : 0;
			R4=R3; R3=R2; R2=R1;
			if(R2>R3)	R1=R3+R4;
			else			R1=R2+R4;
		}
	}
	animationDelayMs = 0;
	#elif 0
	PaintCyclicAutomata filter;
	//filter.init(2, 4, 5, filter.NeighborhoodMoore, filter.ModelGreenbergHastings, filter.WrappingTile); // macaroni
	//filter.init(2, 10, 3, filter.NeighborhoodMoore, filter.ModelNormal, filter.WrappingTile); // lavalamp?? broken
	//filter.init(5, 15, 6, filter.NeighborhoodMoore, filter.ModelGreenbergHastings, filter.WrappingTile); // multistrands
	//filter.init(3, 5, 8, filter.NeighborhoodMoore, filter.ModelGreenbergHastings, filter.WrappingTile); // cyclic spirals
	fs.scalex = 1;
	fs.scaley = 1;
	fs.origx = 0;
	fs.origy = 0;
	{
		// set initial seed values
		unsigned int R1=0x082775212,R2=0x03914AC5F,R3=0x0B460D9C3,R4;
		//R1 ^= GetTickCount();
		int states = filter.states;
		uint8* p = (uint8*)fs.pixels;
		for (int i = 0; i < fs.height*fs.width; i++) {
			p[i] = (R1 & 0x7FFFFFFF) % states;
			R4=R3; R3=R2; R2=R1;
			if(R2>R3)	R1=R3+R4;
			else			R1=R2+R4;
		}
	}
	animationDelayMs = 0;
	#elif 1
	PaintComplex filter(PaintComplex::SpecieMandelbrot2);
	filter.init();
		#if 0
		filter.bailOut = 30;
		filter.iterationsMax = 100;
		fs.scalex = 240; // good with electricity
		fs.scaley = 240;
		fs.origx = -.5;
		fs.origy = 0;
		#elif 0
		filter.bailOut = 30;
		filter.iterationsMax = 100;
		fs.scalex = 5*240; // good with electricity
		fs.scaley = 5*240;
		fs.origx = -.10;//-.5;
		fs.origy = .80;//0;
		#elif 0
		filter.bailOut = 30;
		filter.iterationsMax = 160;
		fs.scalex = 16*240;
		fs.scaley = 16*240;
		fs.origx = -.55;//-.5;
		fs.origy = .65;//0;
		#elif 1
		filter.bailOut = 30;
		filter.iterationsMax = 100;
		fs.scalex = 3000; // good with fire
		fs.scaley = 3000;
		fs.origx = -.15;//-.5;
		fs.origy = 1.05;//0;
		#endif
		WriteMessage(T("mandel2_s%1.0f_x%.2f_y%.2f_"), fs.scalex, fs.origx, fs.origy);
	#elif 0
	PaintComplex filter(PaintComplex::SpecieJulia3);
	filter.init();
	fs.scalex = 150;
	fs.scaley = 150;
	fs.origx = 0;
	fs.origy = 0;
	WriteMessage(T("julia3_s%1.0f_x%.2f_y%.2f_"), fs.scalex, fs.origx, fs.origy);
	#elif 0
	PaintComplex filter(PaintComplex::SpecieJulia2);
	filter.init();
	filter.bailOut = 30;
	filter.iterationsMax = 100;
	fs.scalex = 200;
	fs.scaley = 200;
	fs.origx = 0;
	fs.origy = 0;
	WriteMessage(T("julia2_s%1.0f_x%.2f_y%.2f_"), fs.scalex, fs.origx, fs.origy);
	#elif 1
	PaintComplex filter(PaintComplex::SpecieMandelbrot4);
	filter.init();
	filter.bailOut = 30;
	filter.iterationsMax = 50;
	fs.scalex = 200;
	fs.scaley = 200;
	fs.origx = 0;
	fs.origy = 0;
	WriteMessage(T("mandel4_s%1.0f_x%.2f_y%.2f_"), fs.scalex, fs.origx, fs.origy);
	#endif

	fs.matrixCalc();
	//filter.init();
	filter.draw(&fs, &fs, &FracturedPainter::dummyProgress);

	// palette filter
	PaintPalette palette(PaintPalette::SpecieHsla);
	//palette.init( PaintPalette::SpecieHsla, 0,360*3, .5,.5, .5,.5, 0,255 );
	//palette.init( PaintPalette::SpecieHsva, 360*2-60, 0, 1,-5, 1,.0, 0,255 ); // pretty blue electricity
	//palette.init( PaintPalette::SpecieHsva, 0,360*20, .3,1, 0,20, 0,255 ); // high freq pastel
	palette.wrapping = palette.WrappingNone;
	palette.init( PaintPalette::SpecieRgba, 0,255, 64,255, 0,0, 0,255, 0 ); // fire :)
	//palette.init( PaintPalette::SpecieHsla, 0,360*20,  .4,.3, .4,.7, 0,255 ); // blue and brown
	//palette.init( PaintPalette::SpecieHsla, 0,360*40,  .3,.0, .0,20, 0,255 ); // gray
	//palette.init( PaintPalette::SpecieHsva, 0,360,  .2,1, .1,.8, 0,255 ); // for life faded
	//palette.init( PaintPalette::SpecieHsva, 0,360,  .4,1.6, .0,2, 0,255 ); // for day&night faded
	//palette.palette[0].u32 = 0x00000000;
	//palette.init( PaintPalette::SpecieHsva, 0,360*2, .3,1, 0,20, 0,255 ); // lower freq pastel
	//palette.init( PaintPalette::SpecieHsva, 120, 240, 1.5,3.5, 1,3, 0,255 ); // blue marble
	WriteMessage(T("pH%1.0f,%1.0fS%.1f,%.1fV%.1f,%.1f"), palette.ranges.c1.low, palette.ranges.c1.high, palette.ranges.c2.low, palette.ranges.c2.high, palette.ranges.c3.low, palette.ranges.c3.high);
	if (fs2.pixels != nullptr) {
		palette.draw(&fs2, &fs, &FracturedPainter::dummyProgress);
	}

	// Draw directly to display at top left.
	//HDC hdc = GetDC(MainWindow.hwnd);
	HDC hdc = GetDCEx(GetDesktopWindow(), nullptr, DCX_WINDOW | DCX_CACHE | 0x10000);
	//HDC hdc = GetDC(MainPreview.hwnd);
	struct {
		BITMAPINFOHEADER hdr;
		//RGBQUAD colors[256];
		int32 colors[256];
	} bmi;
	bmi.hdr.biSize = sizeof(BITMAPINFOHEADER);
	bmi.hdr.biWidth = fs.width;
	bmi.hdr.biHeight = -fs.height;
	bmi.hdr.biPlanes = 1;
	bmi.hdr.biBitCount = (fs2.bipp > 0) ? fs2.bipp : fs.bipp;
	bmi.hdr.biCompression = BI_RGB;
	bmi.hdr.biSizeImage = 0;
	bmi.hdr.biXPelsPerMeter = 1;
	bmi.hdr.biYPelsPerMeter = 1;
	bmi.hdr.biClrUsed = 256;
	bmi.hdr.biClrImportant = 240;
	memcpy( bmi.colors, palette.palette, sizeof(bmi.colors) );

	//for (uint c = 0; c < bmi.hdr.biClrUsed; c++) {
	//	#define BLUE	(0x00000001)
	//	#define GREEN	(0x00000100)
	//	#define RED		(0x00010000)
	//	#define ALPHA	(0x01000000)
	//	bmi.colors[c] =
	//		  ALPHA * c
	//		+ BLUE  * int(log(c+1.0) * 46)
	//		+ RED   * (255-int(sqrt(c+1.0) * 31))
	//		+ GREEN * int(sin(c*M_PI/32 + M_PI/4)*127+128);
	//		;
	//	//const static int defaults[5] = {0xFF000000,0xFF0000FF,0xFF00FF00,0xFF00FFFF,0xFFFF0000};
	//	//bmi.colors[c] = defaults[c%5];
	//	#undef BLUE
	//	#undef GREEN
	//	#undef RED
	//	#undef ALPHA
	//}

	MSG msg;
	while (true) {
		void* pixels = (fs2.pixels != nullptr) ? fs2.pixels : fs.pixels;
		SetDIBitsToDevice(hdc, 0,0, fs.width,fs.height, 0,0, 0,fs.height, pixels, (BITMAPINFO*)&bmi, DIB_RGB_COLORS);
		msg.message = WM_QUIT;
		if (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE)) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
			if (msg.message == WM_KEYDOWN || msg.message == WM_LBUTTONDOWN
				|| msg.message == WM_NCLBUTTONDOWN || msg.message == WM_QUIT) break;
		} else {
			Sleep(animationDelayMs);
		}
		filter.next(&fs);
		if (fs2.pixels != nullptr) {
			palette.draw(&fs2, &fs, &FracturedPainter::dummyProgress);
		}
	}
	if (msg.message == WM_QUIT) PostQuitMessage((int)msg.wParam);

	ReleaseDC(GetDesktopWindow(), hdc);
	//InvalidateRect( GetDesktopWindow(), nullptr, false );
	//InvalidateRect( MainWindow.hwnd, nullptr, true );
	RedrawWindow( MainWindow.hwnd, nullptr, nullptr, RDW_ERASE|RDW_INVALIDATE|RDW_FRAME|RDW_ALLCHILDREN );
	//UpdateWindow( MainWindow.hwnd );

	fs.free();
	fs2.free();
}


////////////////////////////////////////////////////////////////////////////////

#ifdef _DEBUG
/** Global text message logger.

param:	msg		Text message.
param:	...		Variable number of parameters (anything printf can handle)
*/
void WriteMessage(LPTSTR msg, ...)
{
	TCHAR text[1024];
	va_list args;
	va_start(args, msg);
	vsnprintft(text, sizeof(text)/sizeof(TCHAR), msg, args);
	strcatt(text, T("\r\n"));
	text[1023] = '\0';

	// create window if first call
	static HWND WriteMessageHwnd = nullptr;
	if (WriteMessageHwnd == nullptr) {
		RECT rect;
		SystemParametersInfo(SPI_GETWORKAREA, 0, &rect, false);
		WriteMessageHwnd = CreateWindowEx(WS_EX_TOOLWINDOW,
			T("EDIT"), nullptr, WS_POPUPWINDOW|WS_THICKFRAME|ES_MULTILINE|ES_AUTOVSCROLL|WS_VSCROLL,
			rect.right-300,rect.top, 300,rect.bottom-rect.top,
			nullptr, nullptr, hInst, nullptr);
		if (WriteMessageHwnd == nullptr) return; // !?
		SetWindowFont(
			WriteMessageHwnd, 
			(WPARAM)CreateFont(12, 0, 0, 0, FW_REGULAR,
				false, false, false,
				ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, DEFAULT_PITCH,
				T("Small fonts")),
			false
		);
		ShowWindow(WriteMessageHwnd, SW_SHOWNOACTIVATE);
	}

	// delete old lines if too long
	#ifdef _DEBUG
	OutputDebugString(text);
	#endif
	int lines = (int) Edit_GetLineCount(WriteMessageHwnd) - 100;
	//int chars = SendMessage(WriteMessageHwnd, WM_GETTEXTLENGTH, 0, 0);
	if (lines > 0) {
		//LONG editStyle = GetWindowLong(WriteMessageHwnd, GWL_STYLE);
		//SetWindowLong(WriteMessageHwnd, GWL_STYLE, editStyle & ~WS_VISIBLE);
		//LockWindowUpdate(WriteMessageHwnd);
		//SendMessage(WriteMessageHwnd, EM_SETSEL, 0, SendMessage(WriteMessageHwnd, EM_LINEINDEX, lines, 0));
		Edit_SetSel(WriteMessageHwnd, 0, 32767);
		Edit_ReplaceSel(WriteMessageHwnd, T(""));
		Edit_SetSel(WriteMessageHwnd, 32767, 32767);
		//LockWindowUpdate(nullptr);
		//SetWindowLong(WriteMessageHwnd, GWL_STYLE, editStyle);
	}
	else {
		Edit_SetSel(WriteMessageHwnd, 32767, 32767);
	}

	// append new lines
	Edit_ReplaceSel(WriteMessageHwnd, text);
}
#endif

////////////////////////////////////////////////////////////////////////////////
