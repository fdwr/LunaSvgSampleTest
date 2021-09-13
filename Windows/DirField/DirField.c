// DirField
// 2003-05-06
// Supposed to draw the gradients of direction fields,
// resulting from differential equations.

#define WIN32_LEAN_AND_MEAN
#define NO_STRICT
//#define WINVER 0x0400
#define NOATOM
#define NOCLIPBOARD
#define NOMETAFILE
#define NOSERVICE
#define NOSOUND
#define NOWH
#define NOCOMM
#define NOHELP
#define NOPROFILER
#define NOMCX
#define OEMRESOURCE
#include <windows.h>
#include <commctrl.h>
#include <math.h>
#include "resource.h"
#define true 1
#define false 0

////////////////////////////////////////////////////////////////////////////////
// Program specific constants

typedef struct
{
	HWND hwnd;
	UINT id;
	char *className;
	char *caption;
	int x,y,width,height;
	UINT style;
	UINT styleEx;
} ChildWindowStruct;

#define ProgMemBase (void*)0x400000 //(HINSTANCE)0x400000

#define PI 3.14159265359

////////////////////////////////////////////////////////////////////////////////
// Function headers

int __stdcall WndProc(HWND hwnd, UINT message, long wParam, long lParam);
void __stdcall FatalErrorMessage(char* Message);
void CreateChildWindow(ChildWindowStruct* cws);

void DrawField();
void DrawFieldRow(double src[], long dest[], int height, int width, int row, int rop);


////////////////////////////////////////////////////////////////////////////////
// Very common global variables
int count;
//RECT rect;
//WINDOWPOS wp;
MSG msg;

////////////////////////////////////////////////////////////////////////////////
// Window UI vars

const char ProgTitle[]={"Dirfs 1.0 (Alpha)"};
const char ProgClass[]={"PknDirFields"};
const char TextAbout[]={
	"Displays direction fields derived from a differential equation."
    };

HWND MainHwnd, ParentHwnd;
HACCEL MainKeyAcl;

WNDCLASS wc = {
	CS_CLASSDC, //style
	(WNDPROC)WndProc, //lpfnWndProc
	0, //cbClsExtra
	DLGWINDOWEXTRA, //cbWndExtra=0;
	(HINSTANCE)ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	COLOR_BTNFACE + 1, //hbrBackground
	(char*)1, //lpszMenuName
	ProgClass //lpszClassName
};

INITCOMMONCONTROLSEX icc = {sizeof(INITCOMMONCONTROLSEX), ICC_BAR_CLASSES}; //ICC_LISTVIEW_CLASSES|ICC_DATE_CLASSES|ICC_BAR_CLASSES};

ChildWindowStruct DifEqu =
{ 0,IDC_DIFEQU,	"EDIT","(equ goes here)",			0,0,640-8,20,			WS_CHILD|WS_VISIBLE|WS_TABSTOP, WS_EX_ACCEPTFILES|WS_EX_CLIENTEDGE};
ChildWindowStruct StatBar =
{ 0,IDC_STATUSBAR,	"msctls_statusbar32", "(status bar unfinished)",	0,320-20,640-8,20,		WS_CHILD|WS_VISIBLE, 0};
ChildWindowStruct DirField =
{ 0,IDC_DIRFIELD,	"STATIC",NULL,						0,20,640-8,480-90,	WS_CHILD|WS_VISIBLE, WS_EX_ACCEPTFILES|WS_EX_CLIENTEDGE};
//ChildWindowStruct ToolBar =
//{ 0,IDC_TOOLBAR,	"ToolbarWindow32",NULL,				0,0,300,20,	WS_CHILD|WS_VISIBLE, 0};

////////////////////////////////////////////////////////////////////////////////
// Program specific vars

#define DirfHeight 256
#define DirfWidth 256
#define DirfXLeft 0
#define DirfYTop 0
#define DirfXScale 1
#define DirfYScale 1

BITMAPINFOHEADER DirfBmpHdr = {
	sizeof(BITMAPINFOHEADER),   //.biSize
	DirfWidth,                  //.biWidth
	-DirfHeight,				//.biHeight
	1,                          //.biPlanes
	32,                         //.biBitCount
	0,                          //.biCompression
	256*256,					//.biSizeImage (height*width)
	0,                          //.biXPelsPerMeter
	0,                          //.biYPelsPerMeter
	0,                          //.biClrUsed
	0                           //.biClrImportant
};

long DirfPixels[256*256]; //large array to hold image
long DirfPixelRow[256]; //temporary row to hold pixels
double DirfCalcs[256]; //temporary row to hold calculations
double DirfRotate; //simple radian value to rotate all angles
HDC DirfHdc; //abstract hdc which can be used by smaller functions

////////////////////////////////////////////////////////////////////////////////
// Main code

int APIENTRY WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int cmdShow)
{
	wc.hIcon = LoadIcon(ProgMemBase,(LPSTR)1);
    wc.hCursor = LoadCursor(0,IDC_ARROW);
	MainKeyAcl = LoadAccelerators(ProgMemBase, (LPSTR)1);

	// initialize common controls for status bar
	InitCommonControlsEx(&icc);

    // main window
    if (!RegisterClass(&wc)) FatalErrorMessage("Failed to register window class");
	CreateWindowEx(WS_EX_ACCEPTFILES,
        ProgClass,
        ProgTitle,
        WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME|WS_SIZEBOX|WS_CLIPCHILDREN,
        CW_USEDEFAULT,CW_USEDEFAULT, 640,480,
        NULL,
        NULL,
        ProgMemBase,
        NULL);
	if (!MainHwnd) FatalErrorMessage("Failed to create main window");


////////////////////////////// Main Loop

	while(GetMessage(&msg, 0, 0,0)>0)
	{
		//debugwrite("o hwnd=%X msg=%X wp=%d lp=%d", msg.hwnd, (int)msg.message, msg.wParam, msg.lParam);
		//TranslateMessage(&msg);
		//DispatchMessage(&msg);

		// dispatch message to main window or dialog boxes
		if(!IsDialogMessage(GetActiveWindow(), &msg))
			DispatchMessage(&msg);
		if ((msg.message == WM_KEYDOWN || msg.message == WM_SYSKEYDOWN)
			&& !(msg.lParam & (1<<30)))
			TranslateAccelerator(MainHwnd, MainKeyAcl, &msg);
	}

	DestroyWindow(MainHwnd);
	return 0;
}

int __stdcall WndProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	//debugwrite("wndproc msg=%X wParam=%X lparam=%X", message, wParam, lParam);
    switch (message) {
	case WM_COMMAND:
		wParam &= 0x0000FFFF;
		//MessageBeep(MB_OK);
		switch (wParam)
		{
		case IDCANCEL:
		case IDCLOSE:
			//quit scanning if active
			DestroyWindow(hwnd);
			break;
		case IDHELP:
			//DialogBoxParam(ProgMemBase, (LPSTR)IDD_ABOUT, MainHwnd, (DLGPROC)AboutDlgProc, NULL);
			break;
		case ID_VIEW_REDRAW:
			DrawField();
			break;
		}
		return 0;
    case WM_CREATE:
		MainHwnd = ParentHwnd = hwnd;
		CreateChildWindow(&DifEqu);
		CreateChildWindow(&StatBar);
		CreateChildWindow(&DirField);
		return 0;
	case WM_CLOSE:
		DestroyWindow(hwnd);
		return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
		return 0;
    default:
        return DefDlgProc(hwnd, message, wParam, lParam);
		//return DefWindowProc(hwnd, message, wParam, lParam);
    }
}


// display message box before ending program
void __stdcall FatalErrorMessage(char* Message)
{
	MessageBox (0, Message, ProgTitle, MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
	ExitProcess (-1);
}

// creates a child window based on a child window structure
void CreateChildWindow(ChildWindowStruct* cws) {
	cws->hwnd=CreateWindowEx(
		cws->styleEx,
		cws->className,
		cws->caption,
		cws->style,
		cws->x,
		cws->y,
		cws->width,
		cws->height,
		ParentHwnd,
		(HMENU)cws->id,
		ProgMemBase,
		0);
}

// draws entire field, one layer at a time, each row at a time
void DrawField()
{
	double x,y;
	int row,col;
	// fills an entire row with a calculation
	//DrawFieldRow(

	DirfHdc = GetDC(DirField.hwnd);

	y = DirfYTop;
	for (row=0; row<DirfHeight; row++) {
		x = DirfXLeft;
		for (col=0; col<DirfWidth; col++) {
			DirfCalcs[col]=1/((128-x)*(128-y));
			x += DirfXScale;
			//SetPixelV(DirfHdc, col, row, (long)DirfCalcs[col] & 0xFFFFFF);
		}
		DrawFieldRow(DirfCalcs, DirfPixels, DirfHeight, DirfWidth, row, 0);
		y += DirfYScale;
	}
	SetDIBitsToDevice(DirfHdc, 0,0, DirfWidth,DirfHeight, 0,0, 0,DirfHeight, DirfPixels,(BITMAPINFO*)&DirfBmpHdr, DIB_RGB_COLORS);

	ReleaseDC(DirField.hwnd, DirfHdc);
}

// Combines a row of slope values into the image
// Does it in two passes, the first converting all the floating
// point values into pixel values using arctan. Then it combines
// the pixel values of the new row to any existing in the image
// using the raster operation.
void DrawFieldRow(double src[], long dest[], int height, int width, int row, int rop)
{
	int x;
	double *srcptr;
	double srcval;
	long *destptr;

	if (row >= height) return;

	//SetPixelV(DirfHdc, 0, row, 0xFFFFFF);

	srcptr=src;
	for (x=0; x<width; x++) {
		//SetPixelV(DirfHdc, x, row, (long)src[x] & 0xFFFFFF);
		srcval = atan(*srcptr++)+DirfRotate;
		//if (srcval > PI*2) srcval -= PI*2;
		//DirfPixelRow[x]= (long)(srcval * 0xFFFFFF / (PI*2));
		//DirfPixelRow[x]= (long)(srcval *20000);
		DirfPixelRow[x]= (long)(srcval * 0xFFFFFF);
		//SetPixelV(DirfHdc, x, row, DirfPixelRow[x]);
	}
	
	destptr=&DirfPixels[row*width];
	switch (rop) {
	case 0: // direct set
		for (x=0; x<width; x++)
			*destptr++=DirfPixelRow[x];
	case 1: // addition
		for (x=0; x<width; x++)
			;
	case 2: // subtraction
		for (x=0; x<width; x++)
			;
	case 3: // multiply
		for (x=0; x<width; x++)
			;
	}
}