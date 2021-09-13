//Card Game
//2002-12-06

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commctrl.h>
#include "cardgame.h"
#include "resource.h"

typedef struct {
	int hwnd; //window handle of control
	int id; //control indentifier
	LPCSTR lpClassName; 
	LPCSTR lpWindowName; //control text
	int style; //flags
	int exStyle; //more flags
	union {
		struct {
			int x;
			int y;
			int width;
			int height;
		};
		RECT rect;
	};
} ChildWndType;
typedef struct {
	unsigned int value; //face value
	bool state; //shown top face or back
} CardType;

int __stdcall WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
int __stdcall GameCardProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
void FatalErrorMessage(char* Message);
void CreateChildWindow(ChildWndType* ChildWindow);

////////////////////////////////////////////////////////////////////////////////

////////////////////////////// Window variables

static char ErrMsgBfr[80];

HWND MainHwnd, StatBarHwnd;
HGDIOBJ DefFont;
MSG msg;
WNDCLASS wc = {
	CS_CLASSDC, //style
	(WNDPROC)WndProc, //lpfnWndProc
	0, //cbClsExtra
	DLGWINDOWEXTRA, //cbWndExtra=0;
	ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	COLOR_BTNFACE + 1, //hbrBackground
	1, //lpszMenuName
	ProgClass //lpszClassName
};
WNDCLASS GameCardwc = {
	CS_CLASSDC, //style
	(WNDPROC)GameCardProc, //lpfnWndProc
	0, //cbClsExtra
	4, //cbWndExtra=0;
	ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	COLOR_BTNFACE + 1, //hbrBackground
	0, //lpszMenuName
	CardClass //lpszClassName
};

// hwnd cid	 class  caption				flags ext_flags				x  y	width height
ChildWndType label1 =
{	0,1,	"STATIC","Player bet",		WS_CHILD|WS_VISIBLE|SS_RIGHT,0,	8,8+16*0,	72,16};
ChildWndType txtPlayerBet =
{	0,IDT_PBET,	"EDIT","20",				WS_CHILD|WS_VISIBLE|ES_NUMBER|WS_TABSTOP,WS_EX_CLIENTEDGE, 88,8+16*0,	64,16};
ChildWndType label2 =
{	0,1,	"STATIC","Opponent bet",	WS_CHILD|WS_VISIBLE|SS_RIGHT,0,	8,8+16*1,	72,16};
ChildWndType txtOpposeBet =
{	0,IDT_OBET,	"EDIT","20",				WS_CHILD|WS_VISIBLE|ES_NUMBER|WS_TABSTOP,WS_EX_CLIENTEDGE,88,8+16*1,	64,16};

ChildWndType label3 =
{	0,1,	"STATIC","Player bank",		WS_CHILD|WS_VISIBLE|SS_RIGHT,0,	160,8+16*0,	80,16};
ChildWndType lblPlayerBank =
{	0,1,	"STATIC",EmptyBankStr,		WS_CHILD|WS_VISIBLE,0,			160+88,8+16*0,	64,16};
ChildWndType label4 =
{	0,1,	"STATIC","Opponent bank",	WS_CHILD|WS_VISIBLE|SS_RIGHT,0,	160,8+16*1,	80,16};
ChildWndType lblOpposeBank =
{	0,1,	"STATIC",EmptyBankStr,		WS_CHILD|WS_VISIBLE,0,			160+88,8+16*1,	64,16};

ChildWndType crdTest0 =
{	0,IDC_0,	CardClass,NULL,				WS_CHILD|WS_VISIBLE,0,	8+80*0,48,	71,96};
ChildWndType crdTest1 =
{	0,IDC_1,	CardClass,NULL,				WS_CHILD|WS_VISIBLE,0,	8+80*1,48,	71,96};
ChildWndType crdTest2 =
{	0,IDC_2,	CardClass,NULL,				WS_CHILD|WS_VISIBLE,0,	8+80*2,48,	71,96};
ChildWndType crdTest3 =
{	0,IDC_3,	CardClass,NULL,				WS_CHILD|WS_VISIBLE,0,	8+80*3,48,	71,96};

ChildWndType StatBar =
{	0,1,	"msctls_statusbar32","<status bar>",	WS_CHILD|WS_VISIBLE,0,	0,300,	300,40};

////////////////////////////// Game variables
unsigned int PlayerScore, OpponentScore, RandomSeed;
int Deck[52];
int DeckSize;				//number of cards remaining in deck
int PlayCards[4];			//value of cards in play
bool PlayedCards[4];		//played cards, flipped
HBITMAP CardBitmaps[52];	//all are 71x96, 2/16 color

////////////////////////////////////////////////////////////////////////////////

int APIENTRY WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int cmdShow) {
	int card;

	//wc.hInstance=hinstance;
	wc.hIcon=LoadIcon(ProgMemBase,1);
    wc.hCursor=LoadCursor(0,IDC_ARROW);
    GameCardwc.hCursor=LoadCursor(ProgMemBase,IDC_CURSORHAND);

    if (!RegisterClass(&wc)) FatalErrorMessage("Failed to register window class");
    if (!RegisterClass(&GameCardwc)) FatalErrorMessage("Failed to register card class");

	DefFont = GetStockObject(DEFAULT_GUI_FONT);
	InitCommonControls();

	CreateWindowEx(WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT,
        ProgClass,
        ProgTitle,
        WS_MINIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME,
        0,0, 340,212,
        NULL,
        NULL,
        ProgMemBase,
        NULL);
	if (!MainHwnd) FatalErrorMessage("Failed to create main window");

////////////////////////////// Initialize game

	RandomSeed = GetTickCount();
	for(card=0; card<52; card++)
		CardBitmaps[card]=LoadBitmap(ProgMemBase, card+1);
	//SendMessage(crdTest0.hwnd, STM_SETIMAGE, IMAGE_BITMAP, CardBitmaps[0]);
	//SendMessage(crdTest1.hwnd, STM_SETIMAGE, IMAGE_BITMAP, CardBitmaps[1]);
	//SendMessage(crdTest2.hwnd, STM_SETIMAGE, IMAGE_BITMAP, CardBitmaps[2]);
	//SendMessage(crdTest3.hwnd, STM_SETIMAGE, IMAGE_BITMAP, CardBitmaps[3]);
	SetWindowLong(crdTest0.hwnd, 0, CardBitmaps[0]);
	SetWindowLong(crdTest1.hwnd, 0, CardBitmaps[1]);
	SetWindowLong(crdTest2.hwnd, 0, CardBitmaps[2]);
	SetWindowLong(crdTest3.hwnd, 0, CardBitmaps[3]);

////////////////////////////// Main Loop

	while(GetMessage(&msg, 0, 0,0)>0)
		IsDialogMessage(MainHwnd, &msg);
		//DispatchMessage(&msg);

////////////////////////////// End game

	for(card=0; card<52; card++)
		DeleteObject(CardBitmaps[card]);

	DestroyWindow(MainHwnd);
	return 0;
}


int __stdcall WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
	case WM_HELP:
		goto ShowHelp;
	case WM_COMMAND:
		if (!(wParam & 0xFFFF0000))
		switch (wParam)
		{
		case IDOK:
			//DialogBox(ProgMemBase,IDD_DIALOG2, MainHwnd,DlgDoNada);
			//CreateChildWindow(&txtBet);
			MessageBox(hwnd, "Enter", ProgTitle, MB_ICONINFORMATION);
			break;
		case IDRETRY:
			MessageBox(hwnd, "Retry", ProgTitle, MB_ICONINFORMATION);
			/*
			reset deck
			clear cards
			clear scores
			*/
			break;
		case IDCLOSE:
		case IDCANCEL:
			//quit scanning if active
			PostQuitMessage(0);
			break;
		case IDHELP:
ShowHelp:
			MessageBox(hwnd, TextAbout, ProgTitle, MB_ICONINFORMATION);
			break;
		default:
			wsprintf(ErrMsgBfr, "wParam=%d", wParam);
			MessageBox(hwnd, ErrMsgBfr, ProgTitle, MB_ICONEXCLAMATION);
		}
		return 0;
    case WM_CREATE:
		//Recalculate the size of all variables
		//and fill with x,y,height,width values
		//Then create each window
		//HWND txtFilePath = 
		MainHwnd=hwnd;

		CreateChildWindow(&label1);
		CreateChildWindow(&txtPlayerBet);
		CreateChildWindow(&label2);
		CreateChildWindow(&lblPlayerBank);
		CreateChildWindow(&label3);
		CreateChildWindow(&txtOpposeBet);
		CreateChildWindow(&label4);
		CreateChildWindow(&lblOpposeBank);

		CreateChildWindow(&crdTest0);
		CreateChildWindow(&crdTest1);
		CreateChildWindow(&crdTest2);
		CreateChildWindow(&crdTest3);

		CreateChildWindow(&StatBar);
		return 0;
	case WM_WINDOWPOSCHANGED:
		{
		//HDWP WinPosList = BeginDeferWindowPos(20);
		//Recalculate the size of all variables
		//and fill with x,y,height,width values
		//Then BeginDeferWindowPos
		//for DeferWindowPos * n
		//EndDeferWindowPos
		//EndDeferWindowPos(WinPosList);
		return 0;
		}
    case WM_DESTROY:
        PostQuitMessage(0);
	case WM_WINDOWPOSCHANGING:
        return 0;
    default:
		//__asm {
		//	mov eax,DefWindowProc
		//	mov [dummy],eax
		//};
        //return DefWindowProc(hwnd, message, wParam, lParam);
		return DefDlgProc(hwnd, message, wParam, lParam);
    }
}


////////////////////////////////////////////////////////////////////////////////
int __stdcall GameCardProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
	switch (message)
	{
	case WM_PAINT:
		{
			PAINTSTRUCT ps;
			HDC DestHdc = BeginPaint(hwnd, &ps);
			HDC SrcHdc  = CreateCompatibleDC(DestHdc);
			SelectObject(SrcHdc, (HBITMAP)GetWindowLong(hwnd, 0));
			//SelectObject(SrcHdc, CardBitmaps[0]);
			BitBlt(DestHdc,0,0,CardWidth,CardHeight,SrcHdc,0,0,SRCCOPY);
			DeleteDC(SrcHdc);
			EndPaint(hwnd, &ps);
		}
		return 0;
	default:
		return DefWindowProc(hwnd, message, wParam, lParam);
	}
}

int ResetDeck() {
	unsigned int card=0;
	for (; card<52; card++) {
		Deck[card].value=card
		Deck[card].state=false;
	}
	DeckSize = 52;
}

int GetRandomDeckCard() {
	//RandomSeed
}
	
////////////////////////////////////////////////////////////////////////////////
void FatalErrorMessage(char* Message) {
	MessageBox (0, Message, ProgTitle, MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
	ExitProcess (-1);
}


////////////////////////////////////////////////////////////////////////////////
void CreateChildWindow(ChildWndType* ChildWindow) {
	ChildWindow->hwnd=CreateWindowEx(
		ChildWindow->exStyle,
		ChildWindow->lpClassName,
		ChildWindow->lpWindowName,
		ChildWindow->style,
		ChildWindow->x,ChildWindow->y,
		ChildWindow->width,ChildWindow->height,
		MainHwnd,
		ChildWindow->id,
		ProgMemBase,
		NULL);
	SendMessage(ChildWindow->hwnd, WM_SETFONT, DefFont, 0);

	//wsprintf(ErrMsgBfr, "wParam=%d", ChildWindow->hwnd);
	//MessageBox(MainHwnd, ErrMsgBfr, ProgTitle, MB_ICONEXCLAMATION);
}