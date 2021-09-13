////////////////////////////////////////////////////////////////////////////////
// Include windows header info

#define WIN32_LEAN_AND_MEAN
#define NO_STRICT
#define WINVER 0x0400
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
#undef RtlMoveMemory
#include <commctrl.h>
#include <winnetwk.h>
#include <imm.h>
#define true 1
#define false 0

#define ProgMemBase (void*)0x400000
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

////////////////////////////////////////////////////////////////////////////////
#include "resource.h"

#ifdef _DEBUGWRITE
 void debuginit();
 void debugwrite(char* Message, ...);
 char debugwrite_Buffer[256];
 #ifdef _DEBUGLIST
  HWND debughwnd;
  HFONT debugfont;
 #endif
#else
 #define debugwrite() //
 #define debuginit() //
#endif

int __stdcall WndProc(HWND hwnd, UINT message, long wParam, long lParam);
void __stdcall FatalErrorMessage(char* Message);
void CreateChildWindow(ChildWindowStruct* cws);

////////////////////////////////////////////////////////////////////////////////
// Very common global variables

int count;
RECT rect;
WINDOWPOS wp;
MSG msg;

////////////////////////////////////////////////////////////////////////////////
// Misc text constants

const char ProgTitle[]={"Tile Mole"};
const char ProgClass[]={"SnowBroTileMole"};
const char AboutText[]={"Tile Molester v 0.1a\r\nby SnowBro 2003"};

////////////////////////////////////////////////////////////////////////////////
// Window UI vars

HWND MainHwnd, ParentHwnd, TtHwnd, ToolBarHwnd, ToolBoxHwnd;
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
#define ToolBarBtnsTtl 27
TBBUTTON ToolBarBtns[ToolBarBtnsTtl] = {
	{	27,	ID_FILE_NEW,	TBSTATE_ENABLED, 0,	0,0 },
	{	28,	ID_FILE_OPEN,	TBSTATE_ENABLED, 0,	0,0 },
	{	36,	ID_FILE_SAVE,	TBSTATE_ENABLED, 0, 0,0 },
	{	0,	0,				TBSTATE_ENABLED, TBSTYLE_SEP,	0,0 },
	{	6,	ID_EDIT_CUT,	TBSTATE_ENABLED, 0,	0,0 },
	{	5,	ID_EDIT_COPY,	TBSTATE_ENABLED, 0,	0,0 },
	{	29,	ID_EDIT_PASTE,	TBSTATE_ENABLED, 0,	0,0 },
	{	0,	0,				TBSTATE_ENABLED, TBSTYLE_SEP, 0,0 },
	{	47,	ID_EDIT_UNDO,	TBSTATE_ENABLED, 0,	0,0 },
	{	32,	ID_EDIT_REDO,	TBSTATE_ENABLED, 0,	0,0 },
	{	0,	0,				TBSTATE_ENABLED, TBSTYLE_SEP, 0,0 },
	{	20,	ID_NAVIGATE_GOTO,TBSTATE_ENABLED, 0,	0,0 },
	{	2,	ID_NAVIGATE_ADDBOOKMARK,	TBSTATE_ENABLED, 0,	0,0 },
	{	0,	0,				TBSTATE_ENABLED, TBSTYLE_SEP, 0,0 },
	{	8,	ID_WIDTH_DECREASE,	TBSTATE_ENABLED, 0,	0,0 },
	{	22, ID_WIDTH_INCREASE,	TBSTATE_ENABLED, 0,	0,0 },
	{	7,	ID_HEIGHT_DECREASE,	TBSTATE_ENABLED, 0,	0,0 },
	{	21,	ID_HEIGHT_INCREASE,	TBSTATE_ENABLED, 0,	0,0 },
	{	0,	0,	TBSTATE_ENABLED, TBSTYLE_SEP, 0,0 },
	{	33,	ID_PAGE_BACK,	TBSTATE_ENABLED, 0,	0,0 },
	{	14,	ID_PAGE_FORWARD,	TBSTATE_ENABLED, 0,	0,0 },
	{	44,	ID_ROW_BACK,	TBSTATE_ENABLED, 0,	0,0 },
	{	45,	ID_ROW_FORWARD,	TBSTATE_ENABLED, 0,	0,0 },
	{	1,	ID_TILE_BACK,	TBSTATE_ENABLED, 0,	0,0 },
	{	17,	ID_TILE_FORWARD,	TBSTATE_ENABLED, 0,	0,0 },
	{	24,	ID_BYTE_BACK,	TBSTATE_ENABLED, 0,	0,0 },
	{	31,	ID_BYTE_FORWARD,	TBSTATE_ENABLED, 0,	0,0 }
	};
#define ToolBoxBtnsTtl 16
TBBUTTON ToolBoxBtns[ToolBarBtnsTtl] = {
	{	0, 0,	TBSTATE_ENABLED, 0,	0,0 },
	{	1, 0,	TBSTATE_ENABLED, 0,	0,0 },
	{	2, 0,	TBSTATE_ENABLED, 0, 0,0 },
	{	0, 0,	TBSTATE_ENABLED, 0,	0,0 },
	{	3, 0,	TBSTATE_ENABLED, 0,	0,0 },
	{	4, 0,	TBSTATE_ENABLED, 0,	0,0 },
	{	5, 0,	TBSTATE_ENABLED, 0,	0,0 },
	{	0, 0,	TBSTATE_ENABLED, 0, 0,0 },
	{	7, 0,	TBSTATE_ENABLED, 0,	0,0 },
	{	8, 0,	TBSTATE_ENABLED, 0,	0,0 },
	{	0, 0,	TBSTATE_ENABLED, 0, 0,0 },
	{	7, 0,	TBSTATE_ENABLED, 0,	0,0 },
	{	8, 0,	TBSTATE_ENABLED, 0,	0,0 },
	{	0, 0,	TBSTATE_ENABLED, 0, 0,0 },
	{	7, 0,	TBSTATE_ENABLED, 0,	0,0 },
	{	8, 0,	TBSTATE_ENABLED, 0,	0,0 },
	};
TBADDBITMAP tbab = {NULL, 0};
ChildWindowStruct StatBar =
	{ 0,IDC_STATUSBAR,	"msctls_statusbar32", "(status bar unfinished)",	0,300,0,40,		WS_CHILD|WS_VISIBLE, 0};

////////////////////////////////////////////////////////////////////////////////
// Main code

int APIENTRY WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int cmdShow)
{
	debuginit();

	//wc.hInstance=hinstance;
	wc.hIcon = LoadIcon(ProgMemBase,(LPSTR)1);
    wc.hCursor = LoadCursor(0,IDC_ARROW);
	MainKeyAcl = LoadAccelerators(ProgMemBase, (LPSTR)1);

    // register main window, lan list, and dialog panel
    if (!RegisterClass(&wc))         FatalErrorMessage("Failed to register window class");

	//RegisterClass(&wcPknTextLabel);

	// initialize common controls, otherwise status bar, date picker, and
	// list view do not appear (CreateWindow fails)
	{
		static INITCOMMONCONTROLSEX icc = {sizeof(INITCOMMONCONTROLSEX), ICC_BAR_CLASSES};
		InitCommonControlsEx(&icc);
	}	//ICC_LISTVIEW_CLASSES|ICC_DATE_CLASSES|

    // main window
	CreateWindowEx(WS_EX_ACCEPTFILES,
        ProgClass,
        ProgTitle,
        WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME|WS_SIZEBOX|WS_CLIPCHILDREN,
        0,0, 640,572,
        NULL,
        NULL,
        ProgMemBase,
        NULL);
	if (!MainHwnd) FatalErrorMessage("Failed to create main window");


////////////////////////////// Main Loop

	// dispatch message to main window or dialog boxes
	while(GetMessage(&msg, 0, 0,0)>0)
	{
		if(!IsDialogMessage(GetActiveWindow(), &msg))
			DispatchMessage(&msg);
		if ((msg.message == WM_KEYDOWN || msg.message == WM_SYSKEYDOWN)
			&& !(msg.lParam & (1<<30)))
			TranslateAccelerator(MainHwnd, MainKeyAcl, &msg);
	}

	// just in case program ending for different reason
	DestroyWindow(MainHwnd);
	return 0;
}


int __stdcall WndProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	//debugwrite("wndproc msg=%X wParam=%X lparam=%X", message, wParam, lParam);
    switch (message) {
	case WM_COMMAND:
		wParam &= 0x0000FFFF;
		switch (wParam)
		{
		//case IDM_GOTO:
		case IDCLOSE:
			PostQuitMessage(0);
			break;
		case IDHELP:
			MessageBox(hwnd, AboutText, ProgTitle, MB_ICONINFORMATION);
			break;
		default:
			MessageBeep(MB_OK);
			MessageBox(hwnd, "Only the About and Exit options work - Dwayne", ProgTitle, MB_OK);
		}
		return 0;
    case WM_CREATE:
	{
		MainHwnd=ParentHwnd=hwnd;

		// Create toolbar, loading bitmap separately because it messes with the colors
		ToolBarHwnd=CreateToolbarEx(
			MainHwnd, WS_VISIBLE|WS_CHILD|TBSTYLE_FLAT, IDC_TOOLBAR, 1, //|TBSTYLE_WRAPABLE
			NULL, 0,
			&ToolBarBtns[0], ToolBarBtnsTtl,
			24,24, 24,24, //!MS bug, button size does not work
			sizeof(TBBUTTON)
			);
		SendMessage(ToolBarHwnd, TB_AUTOSIZE, 0,0);

		ToolBoxHwnd=CreateToolbarEx(
			MainHwnd, WS_CHILD|TBSTYLE_FLAT|TBSTYLE_WRAPABLE, IDC_TOOLBOX, 1,
			NULL, 0,
			&ToolBoxBtns[0], ToolBoxBtnsTtl,
			24,24, 24,24,
			sizeof(TBBUTTON)
			);

		tbab.hInst=NULL;
		tbab.nID=(int)LoadImage(ProgMemBase, (LPSTR)IDB_TOOLBAR, IMAGE_BITMAP, 0,0, LR_LOADTRANSPARENT|LR_LOADMAP3DCOLORS|LR_SHARED);
		SendMessage(ToolBarHwnd, TB_ADDBITMAP, ToolBarBtnsTtl, (long)&tbab);
		SendMessage(ToolBoxHwnd, TB_ADDBITMAP, ToolBarBtnsTtl, (long)&tbab);

		CreateChildWindow(&StatBar);
		return 0;
	}
	case WM_WINDOWPOSCHANGED:
		if (!(((LPWINDOWPOS)lParam)->flags & SWP_NOSIZE)) {
			//let toolbar and status bar resize themselves
			SendMessage(ToolBarHwnd, WM_SIZE, SIZE_RESTORED, 0);
			SendMessage(StatBar.hwnd, WM_SIZE, SIZE_RESTORED, 0);
			//CalcMainWndChildren();
			//SizeMainWndChildren();
		}
		return 0;
	case WM_CLOSE:
    case WM_DESTROY:
        PostQuitMessage(0);
	case WM_WINDOWPOSCHANGING:
        return 0;
    default:
        return DefDlgProc(hwnd, message, wParam, lParam);
		//return DefWindowProc(hwnd, message, wParam, lParam);
    }
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


// display message box before ending program
void __stdcall FatalErrorMessage(char* Message)
{
	MessageBox (0, Message, ProgTitle, MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
	ExitProcess (-1);
}


#ifdef _DEBUGWRITE
// create debug window
void debuginit() {
	#ifdef _DEBUGLIST
	static LOGFONT lf = {6,0, 0,0, FW_DONTCARE, false,false,false, DEFAULT_CHARSET, OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,PROOF_QUALITY, VARIABLE_PITCH, "Small Fonts");

	debugfont = CreateFontIndirect(&lf);
	debughwnd=CreateWindowEx(WS_EX_TOPMOST|WS_EX_NOPARENTNOTIFY|WS_EX_CLIENTEDGE,
        "LISTBOX",
        "Debug window",
		WS_VISIBLE|WS_SIZEBOX|WS_CAPTION|WS_MINIMIZEBOX|WS_VSCROLL|LBS_HASSTRINGS,
        640,0, 160,400,
        NULL,
        NULL,
        ProgMemBase,
        NULL);
	//SendMessage(debughwnd, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), false);
	SendMessage(debughwnd, WM_SETFONT, debugfont, false);	
	#endif
}

void debugwrite(char* Message, ...)
{
	int strlen;
	//wvsprintf((LPSTR)Buffer, Message, (va_list)(&Message)+4);
	wvsprintf((LPSTR)debugwrite_Buffer, (LPSTR)Message, (char*)((&Message)+1));
	strlen=lstrlen((LPSTR)debugwrite_Buffer);
	debugwrite_Buffer[strlen]='\n';
	debugwrite_Buffer[strlen+1]='\0';
	OutputDebugString((LPSTR)debugwrite_Buffer);

	#ifdef _DEBUGLIST
	debugwrite_Buffer[strlen]='\0';
	if (DbgHwnd)
		if ( SendMessage(debughwnd, LB_INSERTSTRING, 0, debugwrite_Buffer) == LB_ERRSPACE)
			 SendMessage(debughwnd, LB_RESETCONTENT, 0,0);
	#endif
}
#endif
