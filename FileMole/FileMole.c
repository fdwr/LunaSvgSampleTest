/*
  copy options:
   always overwrite duplicates
   overwrite only older
   always resume
   never overwrite, skip
   delete incomplete
   leave incomplete for resume

  filtering options:
   inclusion filename masks
		(*.mpg;*.mp3;*.ogg;*.avi;*.ogm;*.divx) defaults to media types
   exclusion filename masks
	(*.bat;*.com;*.eml;*.tmp;...news,eml,bak,fts
		Temporary Internet Files;thumbs.db;WINDOWS;WINNT;.ds_store)
   ignore machines with no shares
   discard folders with no important files
   ignore printer objects

  export options:
   text - pure full paths/tree
   html - links to full paths

  file store/load:
   pure text file: level, type, size, date, name
   each attribite separated by commas
    level - integer
	type - bit flags and attributes
	size - 32bit unsigned integer
	date - 64bit system date/time value
	name - variable sized string
*/

#include "resource.h"
#include "version.h"
#include "filemole.h"

#ifdef MYDEBUG
 extern void debuginit();
 extern void debugwrite(char* Message, ...);
 extern void debugflush();
 extern void debugfinish();
 extern char debugwrite_Buffer[256];
 extern void debugerror();
#else
 #define debuginit() //
 #define debugwrite() //
 #define debugflush() //
 #define debugfinish() //
 #define debugerror() //
#endif

int APIENTRY WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int cmdShow);
//extern void WinMainCRTStartup();

 //extern _WinMainCRTStartup() WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int cmdShow);
//#define _WinMainCRTStartup WinMain
//#define WinMainCRTStartup WinMain

void RegisterClassTry(WNDCLASSW *wc);
void CreateChildWindow(ChildWindowStruct* cws);
int __stdcall WndProc(HWND hwnd, UINT message, long wParam, long lParam);
void __stdcall FatalErrorMessage(LPTSTR Message);

void InitDummyList();
void ScanNetOpenEnum(NETRESOURCEW *EnumNr);
void ScanNetResource();
void ScanFirstFile(LPWSTR Filter);
void ScanNextFile();
void ScanVolumeInfo(LPWSTR PathW);
unsigned int ScanAddItem(short* Name, int Unicode);
void AppendLog(LPWSTR text, ...);
short* __stdcall GetLanListOsPath(unsigned int item, int unicode);
int __stdcall LanList_GetIndexItem(unsigned int index, unsigned int defitem);

unsigned int GenerateStrChecksum(short* text);
void LowerText (short *text);
int CompareTextNoCase (short* text1, short* text2);
short* StringCopy(short* src, short* dest, int count);
int MenuIdToPos(HMENU menu, unsigned int id);
void DisplayHelpTip (int id, int type, HANDLE handle, HANDLE handle2, int x, int y);
void EnterHelpTipMode ();
void HideHelpTip();
//void ShowHelpTip();

void ToggleSidePanel(AttribList *al);
void DialogPanelClosed();
void CalcMainWndChildren();
void SizeMainWndChildren();
//void SizeWndChild(ChildWindowStruct *cws);
void ChildMoveStart();
void ChildMoveEnd();
void ChildMoveDefer(ChildWindowStruct *cwsp);
BOOL CALLBACK GenericDlgProc(HWND hwnd, UINT message, long wParam, long lParam);
BOOL CALLBACK AboutDlgProc(HWND hwnd, UINT message, long wParam, long lParam);
//int __stdcall IgnoreEditHighlight(HWND hwnd, UINT message, long wParam, long lParam);
PTHREAD_START_ROUTINE ScanThread(LPVOID lpThreadParameter);

static int __stdcall TempRefreshList(unsigned int item); //*** hack


////////////////////////////////////////////////////////////////////////////////
// Very common global variables
int count;
//--BOOL unicode;					// OS supports unicode
RECT rect;
WINDOWPOS wp;
MSG msg;
DWORD dummy;					// dummy variable to appease dumb WriteFile
HFONT GuiFont, GuiFontTitle;

////////////////////////////////////////////////////////////////////////////////
// Misc text constants

//--const short ProgClassW[]={L"PknLanFileScanner"};
//--const char  ProgClass[] ={ "PknLanFileScanner"};
//--const char  ProgTitle[] ={ "FileMole " ProgVersion " (Alpha/ßeta)"};

////////////////////////////////////////////////////////////////////////////////
// Window UI vars

HWND MainHwnd, TtHwnd, ParentHwnd;
HACCEL MainKeyAcl;
int TtMsgId=0;  // keeps track of currently displayed tooltip msg id
HMENU ActiveHmenu;

WNDCLASSW wc = {
	CS_CLASSDC, //style
	(WNDPROC)WndProc, //lpfnWndProc
	0, //cbClsExtra
	DLGWINDOWEXTRA, //cbWndExtra=0;
	(HINSTANCE)ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	(HBRUSH)(COLOR_BTNFACE + 1), //hbrBackground
	(short*)1, //lpszMenuName
	ProgClass //lpszClassName
};
///extern WNDCLASSW wcDlgPanel;
extern WNDCLASSW wcLanList;
extern WNDCLASSW wcAtrList;
extern WNDCLASSW wcAtrOverlay;
extern WNDCLASSW wcResizeBar;

#if 0
WNDCLASSW wcPknTextLabel = {
	CS_PARENTDC, //style
	(WNDPROC)PknTextLabelProc, //lpfnWndProc
	0, //cbClsExtra
	0, //cbWndExtra=0;
	ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	0, //hbrBackground
	(char*)1, //lpszMenuName
	L"PknTextLabel" //lpszClassName
};
#endif

RSZN_ITEM SizePanelRi = {100,400,0};
RSZN_ITEM SizeLogRi = {0,400,0};

ChildWindowStruct LanList =
{ 0,IDC_LANLIST,	L"LanItemList",L"(List is empty. Choose scan to start.)",	0,50,392,506-50,	WS_CHILD|WS_VISIBLE|WS_VSCROLL|WS_HSCROLL|WS_TABSTOP|WS_GROUP|WS_CLIPCHILDREN, WS_EX_CLIENTEDGE};
ChildWindowStruct ToolBar =
{ 0,IDC_TOOLBAR,	L"ToolbarWindow32",NULL,				0,0,4096,20,		WS_CHILD|WS_VISIBLE|TBSTYLE_FLAT|CCS_NOPARENTALIGN|CCS_TOP, 0};
ChildWindowStruct txtPath =
{ 0,IDC_PATH,		L"EDIT",L"Type path here",			0,26,392,20,		WS_CHILD|WS_VISIBLE|WS_TABSTOP|ES_AUTOHSCROLL, WS_EX_CLIENTEDGE};
ChildWindowStruct StatBar =
{ 0,IDC_STATUSBAR,	L"msctls_statusbar32", L"(status bar unfinished)",	0,300,400,20,		WS_CHILD, 0}; //WS_VISIBLE
ChildWindowStruct SidePanel =
{ 0,IDC_ATRLIST,	L"AttributeList",NULL,				0,0,180,506-44,		WS_CHILD|WS_VISIBLE|WS_TABSTOP|WS_GROUP|WS_CLIPCHILDREN, WS_EX_CLIENTEDGE};
ChildWindowStruct txtLog =
{ 0,IDC_LOG,		L"EDIT",L"FileMole " ProgVersion L"  " ProgDate,	0,300,392,50,		WS_CHILD|WS_VISIBLE|WS_VSCROLL|ES_AUTOVSCROLL|ES_MULTILINE|ES_READONLY, WS_EX_CLIENTEDGE|WS_EX_NOPARENTNOTIFY};
ChildWindowStruct SizePanel =
{ 0,IDC_SIZEPANEL,	L"ResizeBar",L"SizeBarPanel",			0,0,4,200,			WS_CHILD|WS_VISIBLE|SBS_VERT, 0, &SizePanelRi};
ChildWindowStruct SizeLog =
{ 0,IDC_SIZELOG,	L"ResizeBar",L"SizeBarLog",			0,300,200,4,		WS_CHILD|WS_VISIBLE|SBS_HORZ, 0, &SizeLogRi};


#define ToolBarBtnsTtl 30
TBBUTTON ToolBarBtns[ToolBarBtnsTtl] = {
	{	TbiGotoBackward,IdGotoBackward,	TBSTATE_ENABLED, 0,	0,0 },
	{	TbiGotoForward,	IdGotoForward,	TBSTATE_ENABLED, 0,	0,0 },
	{	TbiGotoOut,		IdGotoOut,		TBSTATE_ENABLED, TBSTYLE_CHECK, 0,0 },
	{	TbiGotoIn,		IdGotoIn,		TBSTATE_ENABLED, 0,	0,0 },
	{	TbiGotoPrevious,IdGotoPrevious,	TBSTATE_ENABLED, 0,	0,0 },
	{	TbiGotoNext,	IdGotoNext,		TBSTATE_ENABLED, 0,	0,0 },
	{	TbiGotoRoot,	IdGotoRoot,		TBSTATE_ENABLED, 0,	0,0 },
	{	0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0 },

	{	TbiStart,		IdFileStart,	TBSTATE_ENABLED, 0, 0,0 },
	{	TbiRefresh,		IdFileRefresh,	TBSTATE_ENABLED, 0,	0,0 },
	{	TbiStop,		IDCANCEL,		TBSTATE_ENABLED, 0,	0,0 },
	{	TbiClear,		IdClearAll,		TBSTATE_ENABLED, 0,	0,0 },
	{	0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0 },

	{	TbiFileCopy,	IdFileCopy,		TBSTATE_ENABLED, 0,	0,0 },
	{	TbiFileQueue,	IdFileQueue,	TBSTATE_ENABLED, 0,	0,0 },
	{	TbiFileAddFav,	IdFileAddFav,	TBSTATE_ENABLED, 0,	0,0 },
	{	TbiEditRemove,	IdClearSelected,TBSTATE_ENABLED, 0,	0,0 },
	{	TbiEditCopy,	IdEditCopy,		TBSTATE_ENABLED, 0,	0,0 },
	{	TbiEditPaste,	IdEditPaste,	TBSTATE_ENABLED, 0,	0,0 },
	//{	TbiFileDelete,	IdFileDelete,	TBSTATE_ENABLED, 0,	0,0 },
	{	0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0 },

	{	TbiViewHistory,	IdViewHistory,	TBSTATE_ENABLED, 0,	0,0 },
	{	TbiViewFinds,	IdViewFinds,	TBSTATE_ENABLED, 0,	0,0 },
	{	TbiViewFavs,	IdViewFavs,		TBSTATE_ENABLED, 0,	0,0 },
	{	TbiViewScan,	IdViewScan,		TBSTATE_ENABLED, 0,	0,0 },
	{	TbiViewFilters,	IdViewFilters,	TBSTATE_ENABLED, 0, 0,0 },
	{	TbiViewOptions,	IdViewOptions,	TBSTATE_ENABLED, 0, 0,0 },
	{	TbiViewQueue,	IdViewQueue,	TBSTATE_ENABLED, 0,	0,0 },
	{	TbiViewProps,	IdViewProps,	TBSTATE_ENABLED, 0,	0,0 },
	{	0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0 },

	{	TbiTipPointer,IdHelpTipPointer,	TBSTATE_ENABLED, 0,	0,0 },

	//{	6, ID_FILE_DEQUEUE,TBSTATE_ENABLED, TBSTYLE_CHECK, 0,6 },
	};
TOOLINFO tti = {
	sizeof(TOOLINFO),
	TTF_IDISHWND|TTF_TRACK|TTF_TRANSPARENT|TTF_ABSOLUTE,//|TTF_CENTERTIP,
	NULL, //containing hwnd
	0, //tool id/handle
	{0,0,4096,4096},
	ProgMemBase,
	L"Test message" //text
};
HIMAGELIST ToolBarHiml=0;

////////////////////////////////////////////////////////////////////////////////
// Side panel attribute lists

AttribList FiltersAl = {
	25, 3, 0, NULL,
	AlfTitleType,				TbiViewFilters, L"list filters", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfMenu,					0, L"presets: ", L"all files\0images\0audio\0video\0executables\0documents\0",
	AlfEdit|8<<AlfLengthRs|IdFilterInclude,	0, L"include: ", L"*Tenchi*",
	AlfEdit|10<<AlfLengthRs|IdFilterExclude,0, L"exclude: ", L"*Universe*",
	AlfEdit|AlfNumeric|4<<AlfLengthRs,0, L"size >= ", L"1024",
	AlfEdit|AlfNumeric,			0, L"size <= ", L"2048",
	AlfEdit,					0, L"date >= ", L"1990-03-01",
	AlfEdit,					0, L"date <= ", L"2003-03-01",
	AlfSeparatorType,			0, NULL, NULL,
	AlfMenu|AlfMenuValue(2),	0, L"new files: ",L"exclude new\0include new only\0include all\0",
	AlfMenu|AlfMenuValue(2),	0, L"deleted/error files: ",L"exclude deleted\0include deleted only\0include all\0",
	AlfMenu|AlfMenuValue(2),	0, L"hidden files: ",L"exclude hidden\0include hidden only\0include all\0",
	AlfMenu|AlfMenuValue(2),	0, L"system files: ",L"exclude system\0include system only\0include all\0",
	AlfMenu|AlfMenuValue(2),	0, L"temp/offline files: ",L"exclude temp\0include temp only\0include all\0",
	AlfMenu|AlfMenuValue(2),	0, L"passworded files: ",L"exclude passworded\0include passworded only\0include all\0",
	AlfSeparatorType,			0, NULL, NULL,
	AlfToggle|AlfMenu,			0, L"filter containers: ", L"files only\0folders only\0files and folders\0",
	AlfToggle,					0, L"show empty containers: ", L"hide\0show",
	AlfToggle|AlfDisabled,		0, L"name case: ",L"true case (allow all upper case)\0mixed upper and lower case like Explorer",
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton|IdFileStart,		TbiStart, L"apply new filter", NULL,
	AlfButton,					TbiEditUndo, L"default settings", NULL,
	AlfButton|IdFileQueue,		TbiFileQueue, L"queue file", NULL,
	AlfButton|IdFileCopy,		TbiFileCopy, L"copy file", NULL,
};

AttribList ScanAl = {
	27, 3, 0, NULL,
	AlfTitleType,				TbiViewScan, L"scanning options", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfMenu|IDIGNORE,			0, L"presets: ", L"local area network topology\0create multivolume data CD index\0complete computer file index\0detect virus changes to executables\0",
	AlfMenu|IDIGNORE,			0, L"heirarchy root: ", L"networks\0local computer\0single drive\0specified folder\0network server\0ftp server\0http server\0",
	AlfEdit|IdHeirarchyPath,	0, L"heirarchy path: ", L"D:\\",
	AlfSeparatorType,			0, NULL, NULL,
	AlfEdit|IdFilterExclude,	0, L"exclude types: ", L"*.nws;*.eml;*.bat;*.com;*.tmp;*.bak;desktop.ini;thumbs.db;.ds_store",
	AlfToggle|AlfChecked,		0, L"hidden files: ",L"exclude\0include\0",
	AlfToggle,					0, L"system files: ",L"exclude\0include\0",
	AlfToggle,					0, L"temp/offline files: ",L"exclude\0include\0",
	AlfToggle,					0, L"floppy drives: ",L"exclude\0include",
	AlfToggle|AlfChecked,		0, L"fixed drives: ",L"exclude\0include",
	AlfToggle,					0, L"compact disc drives: ",L"exclude\0include",
	AlfToggle,					0, L"network drives: ",L"exclude\0include",
	AlfToggle,					0, L"printers: ",L"exclude\0include",
	AlfToggle,					0, L"self as server: ",L"exclude\0include",
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton|IdFileStart,		TbiStart, L"apply and start scan", NULL,
	AlfButton|IDAPPLY,			TbiStart, L"apply options", NULL,
	AlfButton|IdFileRefresh,	TbiRefresh, L"refresh", NULL,
	AlfButton|IDIGNORE,			TbiRefresh, L"clear new flag", NULL,
	AlfButton|IdFileStop,		TbiStop, L"stop scan", NULL,
	//AlfButton,					TbiClear, L"clear scan list", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton|IDIGNORE,			TbiStart, L"select new files", NULL,
	AlfButton|IdFileQueue,		TbiFileQueue, L"queue file", NULL,
	AlfButton|IdFileCopy,		TbiFileCopy, L"copy file", NULL,
	AlfButton|IdFileAddFav,		TbiFileAddFav, L"add favorite", NULL,
};

AttribList OptionsAl = {
	12, 2, 0, NULL,
	AlfTitleType,				TbiViewOptions, L"main options", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfEdit|IdListDefaultFile,	0, L"automatically open list: ", L"c:\\docs\\anime\\collection.txt",
	AlfToggle,					0, L"remember last opened: ",L"no\0yes",
	AlfMenu|AlfMenuValue(2),	0, L"store list as: ",L"ANSI (old problematic format)\0Unicode (internationally compatible )\0Unicode only if needed\0",
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton|IDAPPLY,			TbiStart, L"apply options", NULL,
	AlfButton|IDIGNORE,			TbiEditUndo, L"default settings", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfTitleType,				TbiViewOptions, L"another section divider", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfTitleType,				TbiViewOptions, L"more stuff down here", NULL,
};

//static short ExcludeBuffer[128];
AttribList FindAl = {
	23, 2, 0, NULL,
	AlfTitleType,				TbiViewFinds, L"find", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfMenu,					0, L"presets: ", L"all files\0images\0audio\0video\0executables\0documents\0",
	AlfEdit|41<<AlfLengthRs|IdFilterInclude,	0, L"include: ", L"\xFE8E\xFE8F\xFE90\xFE91\xFE92\x30D4\x30A4\x30AF\x30F3 *Tenchi*;*.mpg;*.avi;*Tenchi*;*.mpg;*.avi",
	//AlfEdit|127<<AlfLengthRs|IdFilterExclude,	0, L"exclude: ", &ExcludeBuffer[0],
	AlfEdit|10<<AlfLengthRs|IdFilterExclude,	0, L"exclude: ", L"*Universe*",
	AlfEdit|AlfNumeric|10<<AlfLengthRs,			0, L"size >= ", L"1024 \x30D4\x30A4\x30AF\x30F3\x9221.avi",
	AlfEdit|AlfNumeric|10<<AlfLengthRs,			0, L"size <= ", L"2048 \xFE8E\xFE8F\xFE90\xFE91\xFE92",
	AlfEdit,					0, L"date >= ", L"1990-03-01",
	AlfEdit,					0, L"date <= ", L"2003-03-01",
	AlfSeparatorType,			0, NULL, NULL,
	AlfToggle,					0, L"match case: ",L"no\0yes",
	AlfToggle|AlfChecked,		0, L"recurse containers: ",L"no\0yes",
	AlfToggle,					0, L"expand branches: ", L"no\0yes",
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton,					TbiStart,	L"start search", NULL,
	AlfButton,					TbiStart,	L"find & select", NULL,
	AlfButton,					TbiStop,	L"stop search", NULL,
	AlfButton,					TbiClear,	L"clear search list", NULL,
	AlfButton,					TbiEditUndo,L"default settings", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton|ID_FILE_QUEUE,	TbiFileQueue,L"queue file", NULL,
	AlfButton|ID_FILE_COPY,		TbiFileCopy,L"copy file", NULL,
	AlfButton|IdFileAddFav,		TbiFileAddFav, L"add favorite", NULL,
};

AttribList HistoryAl = {
	8, 2, 0, NULL,
	AlfTitleType,				TbiViewHistory, L"history", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton|IdGotoIn,			TbiGotoBackward,L"go backward", NULL,
	AlfButton|IdGotoIn,			TbiGotoForward,	L"go forward", NULL,
	AlfButton|IdGotoIn,			TbiGotoRoot,	L"goto root", NULL,
	AlfButton|IdGotoIn,			TbiGotoIn,		L"goto selected", NULL,
	AlfButton|IdEditCopy,		TbiEditCopy,	L"copy path", NULL,
	AlfButton,					TbiClear,	L"clear list", NULL,
};

AttribList FavsAl = {
	14, 2, 0, NULL,
	AlfTitleType,				TbiViewFavs, L"favorites", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton,					TbiRefresh,	L"refresh", NULL,
	AlfButton,					TbiStop,	L"stop refresh", NULL,
	AlfButton,					TbiEditRemove,L"remove selected", NULL,
	AlfButton,					TbiGotoIn,	L"goto selected", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton,					TbiGotoPrevious,L"move top", NULL,
	AlfButton,					TbiGotoPrevious,L"move up", NULL,
	AlfButton,					TbiGotoNext,L"move down", NULL,
	AlfButton,					TbiGotoNext,L"move bottom", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton|IdFileQueue,		TbiFileQueue,L"queue file", NULL,
	AlfButton|IdFileCopy,		TbiFileCopy,L"copy file", NULL,
};

AttribList QueueAl = {
	17, 6, 0, NULL,
	AlfTitleType,				TbiViewQueue, L"copy queue", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfLabel,					TbiViewScan,L"file: ", L"\\\\piken-pc\\anime\\test.avi",
	AlfLabel,					TbiFileCopy,L"copied: ", L"245,246/1,048,576",
	AlfLabel,					TbiViewQueue,L"rate: ", L"30KBps, 2:23/30:45",
	AlfSeparatorType,			0,			NULL, NULL,
	AlfEdit|IdQueuePath,		TbiGotoIn,	L"destination: ", L"c:\\media",
	AlfButton|IdFileStart,		TbiStart,	L"start copy", NULL,
	AlfButton|IdFileStop,		TbiStop,	L"stop copy", NULL,
	AlfButton,					TbiRefresh,	L"clear finished", NULL,
	AlfButton,					TbiEditRemove,L"remove selected", NULL,
	AlfButton,					TbiClear,	L"clear whole queue", NULL,
	AlfSeparatorType,			0,			NULL, NULL,
	AlfButton,					TbiGotoPrevious,L"move top", NULL,
	AlfButton,					TbiGotoPrevious,L"move up", NULL,
	AlfButton,					TbiGotoNext,L"move down", NULL,
	AlfButton,					TbiGotoNext,L"move bottom", NULL,
};

AttribList PropsAl = {
	17, 10, 0, NULL,
	AlfTitleType,				TbiViewProps, L"properties", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfLabel,					0, L"name: ", L"piken-pc needs to be a longer name so that I can see it spill off",
	AlfLabel,					0, L"path: ", L"\\\\piken-pc",
	AlfLabel,					0, L"tree: ", L"Microsoft Network\\piken-pc",
	AlfLabel,					0, L"size: ", L"1423MBs",
	AlfLabel,					0, L"date: ", L"2003-05-28",
	AlfLabel,					0, L"time: ", L"23:20",
	AlfLabel,					0, L"ip: ", L"128.192.0.48",
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton,					TbiEditCopy,	L"copy properties", NULL,
	AlfSeparatorType,			0, NULL, NULL,
	AlfButton|IdFileQueue,		TbiFileQueue,L"queue file", NULL,
	AlfButton|IdFileCopy,		TbiFileCopy,	L"copy file", NULL,
	AlfButton|IdGotoIn,			TbiGotoIn,	L"goto selected", NULL,
	AlfButton|IdFileAddFav,		TbiFileAddFav, L"add favorite", NULL,
	AlfButton|IdFileRefresh,	TbiRefresh,	L"refresh", NULL,
};


////////////////////////////////////////////////////////////////////////////////
// Lan list vars

unsigned int LanListTotal=1; //total items in complete list (permanent root counts as one)
unsigned int LanNamesSize=0; //number of characters in buffer
unsigned int LanListSize=0; //viewable items in list (<total if filtered)
unsigned int LanListSelect=0; //selected item in current subset list
unsigned int LanListTop=0; //item at top of list
unsigned int LanListParent=0; //current parent container in list view
unsigned int LanListView=2;
HIMAGELIST LanListHiml=0;

//the main file list structure
LanListEl LanAtrs[LanAtrsMax];
short LanNames[LanNamesMax];

//indexes pointing into main structure
unsigned int LanTree[LanAtrsMax];
unsigned int LanFinds[LanFindsMax];
unsigned int LanQueue[LanQueueMax];
unsigned int LanFavs[LanFavsMax];
unsigned int *LanListPtr = &LanTree[0];

//HICON LanListIcons[15];

#define FilterMasksLen 1024
char IncludeMasks[FilterMasksLen];
char ExcludesMasks[FilterMasksLen];

////////////////////////////////////////////////////////////////////////////////
// Scanning thread vars

enum { ScanModeActive=0, ScanModePaused=1, ScanModeAck=2, ScanModeDie=4};
unsigned int ScanMode=ScanModePaused;
HANDLE		 ScanTh; //thread handle
HANDLE		 ScanHandle; //folder or network enumeration handle
unsigned int ScanTid; //scanning thread id
signed   int ScanCount; //number of items enumerated
signed   int ScanSize; //size of enumerated data chunk
unsigned int ScanError; //used for status return values in enumeration functions
SOCKET		 ScanSocket;
unsigned int ScanIp;
//--BOOL ScanNetUnicode=true;  //assume TRUE until proven false, when network function fails
//--BOOL ScanFileUnicode=true; //assume TRUE until proven false, when file system function fails

// tree pointers and path to current recursion point
unsigned int ScanParent; //index of current scanned container
unsigned int ScanChild; //index of current child in scanned container
unsigned int ScanFirstChild; //index of current scanned container
unsigned int ScanType; //type of container being scanned
LanListPath ScanPath;

// data buffers used by enumeration functions
NETRESOURCEW ScanBuffer[512]; //net resource for children, 16k should be sufficient
WIN32_FIND_DATAW ScanFd;
FILETIME ScanTime; //real time in pure chronological dating
SYSTEMTIME ScanYmdTime; //contrived year/month/day system time
unsigned int ScanVolumeSerial;
short ScanDrive[4] = {65,58,92,0}; //colon and null Unicode
NETRESOURCEW ScanNr = { //net resource for parent
	RESOURCE_GLOBALNET,
	RESOURCETYPE_DISK,
	RESOURCEDISPLAYTYPE_GENERIC,
	RESOURCEUSAGE_ALL,
	NULL, //local name
	NULL, //remote name
	NULL, //comment
	NULL  //network provider (will typically be 'Microsoft Network')
};

unsigned int ScanFnId[LanListFolderLimit]; //comparable list items in current path
unsigned int ScanFnCs[LanListFolderLimit]; //filename checksums
unsigned int ScanFnCsTotal=0; //total comparable items in current path
unsigned int ScanFnCsIdx=0; //circular pointer within scan list

unsigned int ScanFileAtrFilters = FILE_ATTRIBUTE_TEMPORARY|FILE_ATTRIBUTE_OFFLINE|FILE_ATTRIBUTE_SYSTEM;
unsigned int ScanDriveTypeFilters = (1<<DRIVE_UNKNOWN)|(1<<DRIVE_REMOVABLE)|(1<<DRIVE_RAMDISK)|(1<<DRIVE_REMOTE)|(0<<DRIVE_FIXED)|(1<<DRIVE_CDROM);


////////////////////////////////////////////////////////////////////////////////
// Program code

//void WinMainCRTStartup() {
//	WinMain(0x400000,0,NULL,0);
//}

int APIENTRY WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int cmdShow)
{
	debuginit();

	//SetErrorMode(SEM_FAILCRITICALERRORS|SEM_NOOPENFILEERRORBOX); (for XP pro)
	//unicode = IsWindowUnicode(GetDesktopWindow());
	//--#ifdef MYDEBUG
	//if (unicode) debugwrite("desktop is unicode"); else debugwrite("desktop is ANSI") ;
	//#endif

	//wc.hInstance=hinstance;
	wc.hIcon= LoadIcon(ProgMemBase,(LPTSTR)1);
    wc.hCursor=	wcLanList.hCursor= LoadCursor(0,IDC_ARROW);
	MainKeyAcl=LoadAccelerators(ProgMemBase, (LPTSTR)1);
    // register main window, lan list, and dialog panel
    /*
	if (!RegisterClassTry(&wc))         FatalErrorMessage("Failed to register window class");
    if (!RegisterClassTry(&wcLanList))  FatalErrorMessage("Failed to register LAN list class");
	//wcAtrList.lpszClassName=(LPTSTR)L"AtrListClass";///
    if (!RegisterClassTry(&wcAtrList))  FatalErrorMessage("Failed to register attribute list class");
	*/
	RegisterClassTry(&wc);
    RegisterClassTry(&wcLanList);
    ///RegisterClassTry(&wcDlgPanel);
    RegisterClassTry(&wcAtrList);
    RegisterClassTry(&wcAtrOverlay);
    RegisterClassTry(&wcResizeBar);

	//RegisterClassTry(&wcPknTextLabel);

	//***hack
	//
	//
	LanAtrs[0].flags=LlfDrive |LlfContainer;
       LanAtrs[0].name=L"c:";
	LanAtrs[0].flags=LlfServer |LlfContainer;
	  LanAtrs[0].name=L"piken-pc";
	LanAtrs[0].flags=LlfFolder |LlfContainer;
	  LanAtrs[0].name=L"d:\\Desktop";
    LanAtrs[0].flags=LlfRoot |LlfContainer;
      LanAtrs[0].name=L"(root)";
    LanAtrs[0].name=L"DIXON";
        LanAtrs[0].flags=LlfDomain |LlfContainer;
    LanAtrs[0].flags=LlfComputer |LlfContainer;
       LanAtrs[0].name=L"honbeck-eve.";
	LanAtrs[0].child=0;
	LanAtrs[0].parent=0;
	//
	//
	//
	//InitDummyList();

	{
	/*static LOGFONT lf = {12,0, 0,0,
		FW_NORMAL, 0,0,0,
		DEFAULT_CHARSET, OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,PROOF_QUALITY,
		FF_DONTCARE, "MS Gothic"};//"Small Fonts"};*/
	/*static LOGFONT lf = {16,0, 0,0, //31
		FW_BOLD, 0,0,0,
		ARABIC_CHARSET, OUT_RASTER_PRECIS,CLIP_DEFAULT_PRECIS,PROOF_QUALITY,
		FF_DONTCARE, "Tahoma"};//"Small Fonts"};*/
	//lf.lfHeight=16;
	/*lf.lfCharSet=SHIFTJIS_CHARSET; //ANSI_CHARSET
	lf.lfFaceName[0]=0;
	GuiFontTitle=GuiFont=CreateFontIndirect(&lf);*/
	//GuiFont=GetStockObject(DEFAULT_GUI_FONT);
	}

	// initialize common controls, otherwise status bar, date picker, and
	// list view do not appear (CreateWindow fails)
	{
	static INITCOMMONCONTROLSEX icc = {sizeof(INITCOMMONCONTROLSEX), ICC_BAR_CLASSES};//ICC_LISTVIEW_CLASSES|ICC_DATE_CLASSES|ICC_BAR_CLASSES};
	InitCommonControlsEx(&icc);
	}

    // find our local tooltip window
	//TtHwnd=FindWindow(TOOLTIPS_CLASS, NULL); //tooltips_class32
	//debugwrite("ToolTipHwnd=%d", TtHwnd);
	//if (TtHwnd==NULL)
	TtHwnd=CreateWindowEx(0,
		TOOLTIPS_CLASS,
		NULL,
		WS_POPUP,//|TTS_BALLOON,//|TTS_ALWAYSTIP
		CW_USEDEFAULT,CW_USEDEFAULT,
		CW_USEDEFAULT,CW_USEDEFAULT,
		NULL,
		NULL,
		ProgMemBase,
		0);

	debugwrite("tthwnd=%X", TtHwnd);
	SetWindowPos(TtHwnd, HWND_TOPMOST, 0,0,0,0, SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE|SWP_NOREDRAW);
	//SendMessage(TtHwnd, TTM_SETMAXTIPWIDTH, 0,200);
	SendMessage(TtHwnd, TTM_ADDTOOL, 0, (LPARAM) &tti);
	//SendMessage(TtHwnd,TTM_TRACKPOSITION, 0,(LPARAM)(20|20<<16));
	//SendMessage(TtHwnd,TTM_TRACKACTIVATE, (WPARAM)true,(LPARAM)&tti);
	//SendMessage(TtHwnd,TTM_SETTIPBKCOLOR, 0xFF0000,0);//TTM_SETTIPTEXTCOLOR

	// load images for LAN list, toolbar, and attribute lists
	{
	//unsigned int bpp = GetDeviceCaps( GetWindowDC(MainHwnd), BITSPIXEL);
	HBITMAP hbmp = LoadBitmap(ProgMemBase,(LPTSTR)IDB_LANLIST);
	  LanListHiml = ImageList_Create(16,16, ILC_COLORDDB|ILC_MASK, LliTotal, 0);
	  ImageList_AddMasked(LanListHiml, hbmp, 0xFF00FF);
	  DeleteObject(hbmp);
	hbmp = LoadBitmap(ProgMemBase,(LPTSTR)IDB_TOOLBAR);
	  ToolBarHiml = ImageList_Create(16,16, ILC_COLORDDB|ILC_MASK, 48, 0);
	  ImageList_AddMasked(ToolBarHiml, hbmp, 0x0);
	  DeleteObject(hbmp);
	}

    // main window
	CreateWindowEx(WS_EX_ACCEPTFILES,
		ProgClass,
		ProgTitle,
		WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_CAPTION|WS_SIZEBOX| WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
		//WS_MINIMIZEBOX|WS_POPUP|WS_MAXIMIZEBOX|WS_MAXIMIZE|WS_VISIBLE|WS_SYSMENU|WS_SIZEBOX| WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
		//WS_MINIMIZEBOX|WS_POPUP|WS_MAXIMIZEBOX|WS_MAXIMIZE|WS_VISIBLE|WS_SYSMENU| WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
		0,0, 640,572,
		NULL,
		NULL,
		ProgMemBase,
		NULL);
	if (!MainHwnd) FatalErrorMessage(L"Failed to create main window");

	///SendMessage(MainHwnd, WM_SETFONT, GuiFont, 0);
	///DragAcceptFiles(MainHwnd, true);

/*	SidePanel.hwnd=CreateWindowExW(WS_EX_STATICEDGE,
		L"LanListClass",
		L"lan list",
		WS_VISIBLE|WS_VSCROLL,//|TTS_BALLOON,//|TTS_ALWAYSTIP
		50,50,
		300,400,
		NULL,
		NULL,
		ProgMemBase,
		0);
*/

//!!!!
//	SidePanel.hwnd=CreateWindowEx(WS_EX_CLIENTEDGE,"AtrListClass","test", WS_CHILD|WS_VISIBLE|WS_GROUP|WS_TABSTOP, 0,0, 200,300, MainHwnd, , ProgMemBase, 0);
//					DefWindowProc(hwnd, WM_SETICON, true, (LPARAM)LoadIcon(ProgMemBase, (LPTSTR)IDI_VIEW));
	ScanAl.himl = ToolBarHiml;
	SendMessage(SidePanel.hwnd, LB_INITSTORAGE, 0,(LPARAM)&ScanAl);

	/*tti.hwnd = MainHwnd;
	  tti.hinst = ProgMemBase;
	  tti.uFlags = TTF_IDISHWND;//|TTF_TRANSPARENT | TTF_CENTERTIP;
	tti.uId = (int)LanList.hwnd;
	  tti.lpszText = "";
	  SendMessage(TtHwnd, TTM_ADDTOOL, 0, (LPARAM) &tti);
	//debugwrite ("ttm_addtool=%d", t);
	tti.uId = (int)txtPath.hwnd;
	  tti.lpszText = "Current path\nType in a new path to navigate to. You can include a wildcard for file masking.";
	  SendMessage(TtHwnd, TTM_ADDTOOL, 0, (LPARAM) &tti);
	//debugwrite ("ttm_addtool=%d", t);
	//debugwrite("ToolTipHwnd=%d", TtHwnd);
	*/

	/*{
		short src[]=L"Texas", dest[10];
		
		debugwrite("lstrcpy=%d",
			lstrcpyW(dest, src)
			);
		debugwrite("gle=%d",
			GetLastError()
			);
	}
	MessageBox(MainHwnd, "Temp pause", ProgTitle, MB_OK);
	return;*/


	{
		WSADATA WsaInit;
		if (WsInitialize(0x101, &WsaInit)) { // bool logic reversed
			AppendLog(L"\r\nWindows Socket was not initialized!?");
		} else {
			AppendLog(L"\r\nInitialized Windows Socket\r\n  Description: %hs\r\n  Status: %hs", &WsaInit.szDescription, &WsaInit.szSystemStatus);
		}
	}
	{
		TCHAR name[256];
		int size = 256;//sizeof(user);
		GetUserName(name, &size);
		AppendLog(L"\r\nUser name: %s", name);
		GetComputerName(name, &size);
		AppendLog(L"\r\nComputer name: %s", name);
	}

	ScanTh=CreateThread(NULL, 0, (PTHREAD_START_ROUTINE)&ScanThread, 0, 0, &ScanTid);


	//SetMenuItemBitmaps(GetSubMenu(GetMenu(MainHwnd),0), IDM_FILE_COPY, MF_BYCOMMAND, LanListIcons[0], NULL);
	//GetSubMenu(GetMenu(MainHwnd),0)

	//debugwrite("gsm = %d", SetMenuItemBitmaps(GetSubMenu(GetMenu(MainHwnd),0), IDM_FILE_COPY, MF_BYCOMMAND, LoadImage(ProgMemBase, IDB_TOOLBAR,IMAGE_BITMAP, 0,0,LR_LOADTRANSPARENT), NULL));
	/*{
		HWND DeskHwnd;
		HDC DeskDc;
		HICON Hicon;
		HICON himage = LoadImage(ProgMemBase, IDI_FILE, IMAGE_ICON, 0,0, 0);
		HDC DumbUnecessaryStupidExtraDc;
		ICONINFO pico;

		GetIconInfo(himage, &pico);
		//DeleteObject(himage);
		//DeleteObject(pico.hbmMask);
		himage = pico.hbmColor;
		//DeleteObject(pico.hbmColor);
		//himage = pico.hbmMask;
		//himage=CopyImage(himage, IMAGE_BITMAP, 0,0, LR_COPYDELETEORG);

	debugwrite("gsm1 = %d",
		SetMenuItemBitmaps(GetSubMenu(GetMenu(MainHwnd),0), IDM_FILE_COPY, MF_BYCOMMAND, 
			//LoadImage(ProgMemBase, IDB_TOOLBAR, IMAGE_BITMAP, 0,0, LR_CREATEDIBSECTION),
			//himage,
			//himage
			LoadImage(ProgMemBase, IDI_FILE, IMAGE_ICON, 0,0, 0),
			LoadImage(ProgMemBase, IDI_FILE, IMAGE_ICON, 0,0, 0)
		));
	debugwrite("gsm2 = %d",
		SetMenuItemBitmaps(GetSubMenu(GetMenu(MainHwnd),0), IDM_FILE_QUEUE, MF_BYCOMMAND, 
			LoadImage(ProgMemBase, IDB_TOOLBAR, IMAGE_BITMAP, 0,0, 0),
			NULL
		));

		//debugwrite("smib = %d", GetLastError());


		DeskHwnd = GetDesktopWindow();
		//DeskHwnd = MainHwnd;
		//DeskDc = GetDC(DeskHwnd);
		DeskDc = GetDCEx(DeskHwnd, NULL, DCX_WINDOW|DCX_PARENTCLIP|DCX_LOCKWINDOWUPDATE);
		debugwrite("desk dc=%d", DeskDc);

		//himage=LoadImage(ProgMemBase, IDB_TOOLBAR, IMAGE_BITMAP, 0,0, 0),

		DumbUnecessaryStupidExtraDc = CreateCompatibleDC(NULL);
		SelectObject(DumbUnecessaryStupidExtraDc, himage);
		//Hicon = LoadIcon(ProgMemBase, IDI_COPYFILES);
		//Hicon = LoadImage(ProgMemBase, IDI_COPYFILES, IMAGE_ICON, 0,0, LR_CREATEDIBSECTION);
		//Hicon = LoadImage(ProgMemBase, IDB_TOOLBAR, IMAGE_BITMAP, 0,0, 0);
		//Hicon = CopyImage(
		//	LoadIcon(ProgMemBase, IDI_COPYFILES),
		//		IMAGE_BITMAP, 0,0,0);
		//debugwrite("hicon=%d", Hicon);
		//DrawIcon(DeskDc, 700,500, Hicon);
		//DrawIconEx(DeskDc, 100,100, Hicon, 32,32, 0, NULL, DI_NORMAL);
		BitBlt(DeskDc, 660,500, 100,100, DumbUnecessaryStupidExtraDc, 0,0, SRCINVERT);
		DeleteDC(DumbUnecessaryStupidExtraDc);
		//DeleteObject(himage);
		ReleaseDC(DeskHwnd, DeskDc);
	}*/


	/*{
		HMENU MainMenu, FileMenu;
		MENUITEMINFO mii;

		FileMenu = GetSubMenu( MainMenu=GetMenu(MainHwnd), 0);
		debugwrite("file menu=%d", FileMenu);

		mii.cbSize = sizeof(MENUITEMINFO);
		//mii.fMask = MIIM_TYPE|MIIM_DATA; //|MIIM_STATE;

		//debugwrite ("gmc=%d", GetMenuItemCount(FileMenu));
		//debugwrite ("gmii=%X", 
		//GetMenuItemInfo(GetMenu(MainHwnd), IDM_FILE_COPY, false, &mii)
		//	);

		mii.fMask = MIIM_TYPE|MIIM_DATA|MIIM_CHECKMARKS; //|MIIM_STATE;
		//mii.fType = MFT_OWNERDRAW|MFT_STRING;
		mii.fType = MFT_OWNERDRAW;
		mii.dwItemData = FileMenu;
		mii.dwTypeData = "File....................";
		mii.cch=10;
		mii.hbmpChecked=LoadImage(ProgMemBase, IDB_TOOLBAR,IMAGE_BITMAP, 0,0,LR_LOADTRANSPARENT);
		mii.hbmpUnchecked=NULL;
		//mii.fState = MFS_GRAYED;
		//debugwrite ("filemenu=%X", FileMenu);
		debugwrite ("miitd1=%X", mii.dwTypeData);
		debugwrite("smii=%d", 
		SetMenuItemInfo(FileMenu, IDM_FILE_COPY, false, &mii)
			);
		debugwrite ("miitd2=%X", mii.dwTypeData);

		debugwrite ("miitd1=%X %ls", mii.dwTypeData,mii.dwTypeData);
		GetMenuItemInfo(FileMenu, IDM_FILE_COPY, false, &mii);
		debugwrite ("miitd2=%X %ls", mii.dwTypeData,mii.dwTypeData);
		debugwrite ("miitd2 above");
	}*/


////////////////////////////// Main Loop

	while(GetMessage(&msg, 0, 0,0)>0)
	{
		switch (msg.message) {
		case WM_KEYDOWN:
		case WM_LBUTTONDOWN:
		case WM_RBUTTONDOWN:
			HideHelpTip();
		}

		//debugwrite("o hwnd=%X msg=%X wp=%d lp=%d", msg.hwnd, (int)msg.message, msg.wParam, msg.lParam);
		//TranslateMessage(&msg);
		//DispatchMessage(&msg);

		// relay message to tooltip
		/*switch (msg.message)
		{
		case WM_KEYDOWN:
			// fake left button press, then restore message
			msg.message=WM_LBUTTONDOWN;
			SendMessage(TtHwnd, TTM_RELAYEVENT, 0, (LPARAM) &msg);
			msg.message=WM_KEYDOWN;
			//if (msg.wParam==VK_TAB) {
			//	if (GetKeyState(VK_SHIFT) & 0x80)
			//		SetFocus(GetNextDlgTabItem(MainHwnd, GetFocus(),true));
			//	else
			//		SetFocus(GetNextDlgTabItem(MainHwnd, GetFocus(),false));
			//	continue;
			//}
			break;
		case WM_MOUSEMOVE:
		case WM_LBUTTONDOWN:
		case WM_LBUTTONUP:
		case WM_RBUTTONDOWN:
		case WM_RBUTTONUP:
			msg.hwnd=GetDesktopWindow();
			SendMessage(TtHwnd, TTM_RELAYEVENT, 0, (LPARAM) &msg);
		}*/

		//TranslateMessage(&msg);
		//DispatchMessage(&msg);

		// dispatch message to main window or dialog boxes
		if(!IsDialogMessage(GetActiveWindow(), &msg)) {
			//TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
		if ((msg.message == WM_KEYDOWN || msg.message == WM_SYSKEYDOWN)
			&& !(msg.lParam & (1<<30)))
			TranslateAccelerator(MainHwnd, MainKeyAcl, &msg);
	}

	ScanMode|=(ScanModeDie|ScanModePaused);
	ResumeThread(ScanTh);
	debugflush();
	WaitForSingleObject(ScanTh, 5000); //allow up to 5 seconds for it to die
	TerminateThread(ScanTh,-1);
	WSACleanup();

	DestroyWindow(MainHwnd);

	ImageList_Destroy(LanListHiml);

	debugfinish();
	ExitProcess(0); // force process exit, otherwise buggy SHELL32 functions
	// sometimes leave behind zombie process. Don't know why. Don't care why.
	// Only know that when it comes to MS code, don't try to understand it,
	// just do your best to get around its shortcomings. (have I formed a bias?) @20030831
	return 0;
}


int __stdcall WndProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	//debugwrite("wndproc msg=%X wParam=%X lparam=%X", message, wParam, lParam);
    switch (message) {
	case WM_COMMAND:
		if (lParam==0) wParam &= 0x0000FFFF; //lParam null so msg from menu or accelerator, so ignore notification code
		switch (wParam)
		{
		case IdViewStatBar:
			StatBar.style ^= WS_VISIBLE;
			SizeMainWndChildren();
			break;
		case IdViewToolBar:
			ToolBar.style ^= WS_VISIBLE;
			SizeMainWndChildren();
			break;
		case ID_TEST:
			/*LanListSelect=0;
			LanListTop=0;
			if (LanListIndented) {
				for (count=0, LanListSize=0; (unsigned)count<LanListTotal; count++) {
					//debugwrite("testset mask=%X server=%X flags=%X", LlfTypeMask, LlfServer, LanAtrs[count].flags & LlfTypeMask);
					if ((LanAtrs[count].flags & LlfTypeMask) == LlfServer) {
						LanFinds[LanListSize]=count;
						LanListSize++;
					}
				}
				LanListIndented=false;
				LanListPtr=&LanFinds[0];
			} else {
				LanListIndented=true;
				LanListPtr=&LanTree[0];
				LanListSize=LanListTotal;
			}
			//RedrawWindow
			InvalidateRect(LanList.hwnd, NULL,false);
			SendMessage(LanList.hwnd, WM_SIZE,0,0);
			*/
			/*
			ShowWindow( CreateDialog(ProgMemBase, (LPTSTR)IDD_SCAN_FILTERS, NULL, GenericDlgProc), SW_SHOW );
			ShowWindow( CreateDialog(ProgMemBase, (LPTSTR)IDD_FILTERS, NULL, GenericDlgProc), SW_SHOW );
			ShowWindow( CreateDialog(ProgMemBase, (LPTSTR)IDD_ABOUT, NULL, GenericDlgProc), SW_SHOW );
			ShowWindow( CreateDialog(ProgMemBase, (LPTSTR)IDD_INFO, NULL, GenericDlgProc), SW_SHOW );
			ShowWindow( CreateDialog(ProgMemBase, (LPTSTR)IDD_DELETE_WARN, NULL, GenericDlgProc), SW_SHOW );
			*/
			/*{ //test character
			static int keychar=1569;
			//SendMessage(GetFocus(),WM_CHAR,keychar++,0);
			//SendMessage(GetFocus(),WM_CHAR,1569,0);
			extern int __stdcall AtrListProc(HWND hwnd, UINT message, long wParam, long lParam);
			AtrListProc(SidePanel.hwnd,WM_CHAR,keychar++,0);
			//SendMessage(GetFocus(),WM_CHAR,65,0);
			//keybd_event(65,65,0,0);
			MessageBeep(MB_OK); //***
			}*/
			/*
			{
			int serial=0;
			char volname[256]={0},sysname[256]={0};
			//GetVolumeInformation("E:\\",volname,sizeof(volname),&i4,&i5,&i6,sysname,sizeof(sysname));
			GetVolumeInformation("D:\\",volname,sizeof(volname),&serial,NULL,NULL,sysname,sizeof(sysname));
			//debugwrite("vol ser=%d =%Xh", i4,i4);
			debugwrite("ser=%08X vol=%ls sys=%ls", serial,volname,sysname);
			}
			*/
			{
			char textA[256];
			static char crlf[]="\r\n";
			int children[LanListMaxDepth];
			int depth=0;
			unsigned int child=0;
			HANDLE file=CreateFile(L"C:\\FILES.TXT", GENERIC_WRITE, FILE_SHARE_READ, NULL,
				CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL|FILE_FLAG_SEQUENTIAL_SCAN, NULL);

			goto IdTestInsideLoop;
			while (true) {
				if (!child) {
					if (depth<=1) break;
					child=LanAtrs[ children[--depth] ].next;
				} else {
				IdTestInsideLoop:
					if (child >= LanListTotal) {
						MessageBox(hwnd, L"LanList child out of bounds", L"Ack!", MB_OK);
						break;
					}
					WideCharToMultiByte(CP_ACP, 0, LanAtrs[child].name,-1, textA+depth, sizeof(textA), NULL,NULL);
					WriteFile(file, textA,lstrlenA(textA), &dummy,NULL);
					WriteFile(file, crlf, 2, &dummy, NULL);

					if (LanAtrs[child].flags & LlfContainer && LanAtrs[child].child) {
						textA[depth]=' ';
						children[depth++]=child;
						child=LanAtrs[child].child;
					} else {
						child=LanAtrs[child].next;
					}
				}
			}
			CloseHandle(file);
			}
			break;
		case IdFileFind:
		case IdViewFinds:
			ToggleSidePanel(&FindAl);
			break;
		case IdViewFavs:
			ToggleSidePanel(&FavsAl);
			break;
		case IdViewHistory:
			ToggleSidePanel(&HistoryAl);
			break;
		case IdViewScan:
			ToggleSidePanel(&ScanAl);
			break;
		case IdViewFilters:
			ToggleSidePanel(&FiltersAl);
			break;
		case IdViewOptions:
			ToggleSidePanel(&OptionsAl);
			break;
		case IdViewQueue:
			ToggleSidePanel(&QueueAl);
			break;
		case IdViewProps:
			ToggleSidePanel(&PropsAl);
			break;
		/**case ID_LOGON:
		case ID_LOGOFF:
		{
			FARPROC LogonAdr;
			//MessageBox(MainHwnd, "Log on/off", ProgTitle, MB_OK);
			//DWORD WINAPI WNetLogonA( LPCSTR lpProvider, HWND hwndOwner );
			debugwrite("MPR& %X", GetModuleHandle("MPR"));
			debugwrite("WNetLogon& %X", GetProcAddress(GetModuleHandle("MPR"), "WNetLogonA"));
			if (LogonAdr=GetProcAddress(GetModuleHandle("MPR"), "WNetLogonA"))
				LogonAdr(NULL, NULL);
			
			//WNetLogonA(NULL, MainHwnd);
			//MessageBox(MainHwnd, &Name, &UserName, MB_OK);
			break;
		}*/
		case IdHelpTipPointer:
			EnterHelpTipMode();
			break;
		case IdHelpReadme:
			ShellExecute(hwnd,NULL, ProgHelpFile, NULL,NULL,SW_SHOWMAXIMIZED);
			break;
		case IdHelpAbout:
			DialogBoxParam(ProgMemBase, (LPTSTR)IDD_ABOUT, MainHwnd, (DLGPROC)AboutDlgProc, 0);
			break;
		case IdFileStart:
			ScanMode=ScanModeActive;
			ResumeThread(ScanTh);
			break;
		case IdListDefaultFile|ALN_CONTEXT:
			InsertMenu((HMENU)lParam,0,MF_BYPOSITION|MF_STRING, IdListDefaultFile,L"&Browse file");
			SetMenuDefaultItem((HMENU)lParam,0,TRUE);
			break;
		case IdListDefaultFile:	// show open dialog
		{
			TCHAR name[MAX_PATH];
			OPENFILENAME ofn = {
				sizeof(OPENFILENAME),
				NULL, ProgMemBase,
				L"file topology lists (*.ftl;*.txt)\0*.ftl;*.txt\0" L"all files\0*\0", NULL,0,1,
				&name[0],sizeof(name),
				NULL,0, 
				NULL,
				L"Choose default file list",
				OFN_HIDEREADONLY|OFN_FILEMUSTEXIST|OFN_PATHMUSTEXIST|OFN_EXPLORER|OFN_ENABLESIZING,
				0,0, L"ftl",
				0,NULL,NULL
			};
			name[0]=0;
			ofn.hwndOwner=hwnd;
			SetLastError(13);
			GetOpenFileName(&ofn);
			debugwrite("ofn=%d",GetLastError());
			break;
		}
		case IdHeirarchyPath|ALN_CONTEXT:
			InsertMenu((HMENU)lParam,0,MF_BYPOSITION|MF_STRING, IdHeirarchyPath,L"&Browse folder");
			SetMenuDefaultItem((HMENU)lParam,0,TRUE);
			break;
		case IdHeirarchyPath:
			// show folder dialog
			MessageBox(hwnd, L"browse heirarchy root folder", L"<Unfinished>", MB_OK);
			break;
		case IdQueuePath|ALN_CONTEXT:
			InsertMenu((HMENU)lParam,0,MF_BYPOSITION|MF_STRING, IdQueuePath,L"&Browse folder");
			InsertMenu((HMENU)lParam,1,MF_BYPOSITION|MF_STRING, IdQueuePathDesktop,L"To &desktop");
			InsertMenu((HMENU)lParam,2,MF_BYPOSITION|MF_SEPARATOR, 0,NULL);
			SetMenuDefaultItem((HMENU)lParam,0,TRUE);
			break;
 		case IdQueuePath:
			MessageBox(hwnd, L"browse queue folder", L"<Unfinished>", MB_OK);
			break;
 		case IdQueuePathDesktop:
			MessageBox(hwnd, L"set queue folder to desktop", L"<Unfinished>", MB_OK);
			break;
		case IDC_SIZEPANEL|RSZN_START:
			debugwrite("grabbed panel sizer");
			//SizePanelRi.min=0;
			SizePanelRi.max = LanList.x+LanList.width-SizePanel.width; //StatBar.width-SizePanel.width;
			break;
		case IDC_SIZEPANEL|RSZN_CLICK:
			debugwrite("clicked panel sizer");
			SidePanel.style ^= WS_VISIBLE;
			SizeMainWndChildren();
			break;
		case IDC_SIZEPANEL|RSZN_SIZE:
			SidePanel.width = SizePanelRi.track;
			SizeMainWndChildren();
			break;
		case IDC_SIZELOG|RSZN_START:
			debugwrite("grabbed log sizer");
			SizeLogRi.min = LanList.y+54;
			SizeLogRi.max = (SizePanel.y+SizePanel.height)-SizeLog.height;
			break;
		case IDC_SIZELOG|RSZN_CLICK:
			debugwrite("clicked log sizer");
			txtLog.style ^= WS_VISIBLE;
			SizeMainWndChildren();
			break;
		case IDC_SIZELOG|RSZN_SIZE:
			//SidePanel.width = SizePanelRi.track;
			debugwrite("moved log sizer");
			txtLog.height=(SizePanel.y+SizePanel.height)-(SizeLogRi.track+SizeLog.height);
			SizeMainWndChildren();
			break;
		/*case IdFileProps:
		{
			SHELLEXECUTEINFO sei = {0};
			short *path = GetLanListOsPath(LanTree[LanListSelect], unicode);

			__asm {
			push edi
			lea edi,[dword ptr sei]
			xor eax,eax
			//cld
			mov ecx,15 //sizeof(sei)/4
			rep stosd
			pop edi
			}
			//ZeroMemory(&sei,sizeof(sei));***
			sei.cbSize = sizeof(sei);
			sei.lpFile = (LPTSTR)path;
			sei.fMask  = SEE_MASK_INVOKEIDLIST;
			if (unicode) {
				sei.lpVerb = (char*)L"properties";
				ShellExecuteExW((SHELLEXECUTEINFOW*)&sei);
			} else {
				sei.lpVerb = "properties";
				ShellExecuteExA(&sei);
			}
			break;
		} */
		case IDC_LANLIST|LLN_OPEN:
			TempRefreshList(LanTree[LanListSelect]);
			LanListSelect=0;
			break;			
		case IDC_LANLIST|LLN_ENTER:
		{
			// actions depends on which list is currently displayed
			//		and whether the item is a container or file
			// finds
			// history
			// scan
			// if file
			//if (file) ShellExecute(hwnd,NULL, file, NULL,NULL,SW_SHOWMAXIMIZED);
			short *path = GetLanListOsPath(LanTree[LanListSelect], 1);
			//--if (unicode)
			//	ShellExecuteW(hwnd,NULL, path, NULL,NULL,SW_SHOW);
			//else
			ShellExecute(hwnd,NULL, (LPTSTR)path, NULL,NULL,SW_SHOW);
			break;
		}
		case IDC_LANLIST|LLN_CLOSE:
		case IDC_LANLIST|LLN_EXIT:
		{
			// actions depends on which list is currently displayed
			//		and whether the item is a container or file
			// finds
			// history
			// scan
			if (LanListParent>0) {
				int parent=LanListParent;
				TempRefreshList(LanAtrs[LanListParent].parent);
				LanListSelect=LanList_GetIndexItem(parent,0);
			}
			break;
		}
		case IDCANCEL:
			//quit scanning if active
			ScanMode=ScanModePaused;
			break;
		case IDCLOSE:
			//quit scanning if active
			DestroyWindow(hwnd);
			break;
		default:
			debugwrite("CmdMsg=%d",wParam);
		}
		return 0;
    case WM_CREATE:
	{
		MainHwnd=ParentHwnd=hwnd;

		// Create toolbar
		// Must load bitmap separately rather than in the CreateTb
		// because the toolbar badly messes with my colors
		/*ToolBar.hwnd=CreateToolbarEx( ///TBSTYLE_WRAPABLE|TBSTYLE_TOOLTIPS
			MainHwnd, WS_VISIBLE|WS_CHILD|TBSTYLE_FLAT|CCS_NOPARENTALIGN|CCS_TOP,
			IDC_TOOLBAR, 1,
			NULL, 0,
			//ProgMemBase, IDB_TOOLBAR,
			&ToolBarBtns[0], ToolBarBtnsTtl,
			16,16, 16,16,
			sizeof(TBBUTTON)
			);*/
		//static TBADDBITMAP tbab = {NULL, 0};
		//tbab.hInst=NULL;
		//tbab.nID=(int)LoadImage(ProgMemBase, (LPTSTR)IDB_TOOLBAR, IMAGE_BITMAP, 0,0, LR_LOADTRANSPARENT|LR_LOADMAP3DCOLORS);
		//SendMessage(ToolBar.hwnd, TB_ADDBITMAP, ToolBarBtnsTtl, (LPARAM)&tbab);
		// Grr, just make controls that work right, and my code won't have to 
		// look like this!
		CreateChildWindow(&ToolBar);
		SendMessage(ToolBar.hwnd, TB_SETIMAGELIST, 0,(LPARAM)ToolBarHiml);
		SendMessage(ToolBar.hwnd, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0);
		SendMessage(ToolBar.hwnd, TB_ADDBUTTONS, ToolBarBtnsTtl,(LPARAM)ToolBarBtns);
		GetWindowRect(ToolBar.hwnd, (RECT*)&ToolBar.x);
		ToolBar.height-=ToolBar.y;
		ToolBar.width=4096;
		ToolBar.x = ToolBar.y = 0; // zero stupid non-client relative coordinates
		SetWindowLong(ToolBar.hwnd, GWL_STYLE, GetWindowLong(ToolBar.hwnd, GWL_STYLE)|CCS_NORESIZE);

		//SetWindowPos(ToolBar.hwnd, NULL, 0,0, 4096,28, SWP_NOACTIVATE|SWP_NOZORDER);
		//GetWindowRect(ToolBar.hwnd, (RECT*)&ToolBar.x);
		//ToolBar.height-=ToolBar.y;
		//debugwrite("tbh=%d tby=%d", ToolBar.height, ToolBar.y);

		//GetWindowRect(ToolBar.hwnd, (RECT*)&ToolBar.x);
		//ToolBar.height-=ToolBar.y;
		//debugwrite("tbh=%d tby=%d", ToolBar.height, ToolBar.y);
		//SetWindowPos(ToolBar.hwnd, NULL, 0,0, 4096,ToolBar.height, SWP_NOACTIVATE|SWP_NOZORDER);
		//debugwrite("tbh=%d", ToolBar.height);
		//SetWindowPos(ToolBar.hwnd, NULL, 0,0, 4096,28, SWP_NOACTIVATE|SWP_NOZORDER);

		// Create status bar, path edit, and lan list
		// Then recalculate the size of all variables
		// and fill with x,y,height,width values
		CreateChildWindow(&StatBar);
		//...
		SetWindowLong(StatBar.hwnd, GWL_STYLE, GetWindowLong(StatBar.hwnd, GWL_STYLE)|CCS_NORESIZE);

		CalcMainWndChildren();
		CreateChildWindow(&LanList);
		CreateChildWindow(&txtLog);
		CreateChildWindow(&SidePanel);
		CreateChildWindow(&txtPath);
		CreateChildWindow(&SizePanel);
		CreateChildWindow(&SizeLog);

		SendMessage(txtPath.hwnd, WM_SETFONT, (WPARAM)GuiFont, FALSE);
		SendMessage(txtLog.hwnd, WM_SETFONT, (WPARAM)GuiFont, FALSE);

		//InitializeFlatSB(LanList.hwnd); //just for fun
	    //FlatSB_SetScrollProp(LanList.hwnd, WSB_PROP_VSTYLE, FSB_FLAT_MODE, FALSE);
		//FlatSB_ShowScrollBar(LanList.hwnd, SB_HORZ, FALSE);

		//SetFocus(LanList.hwnd);
		SetFocus(SidePanel.hwnd);
		return 0;
	}
	case WM_WINDOWPOSCHANGED:
	{
		//Then BeginDeferWindowPos
		//for DeferWindowPos * n
		//EndDeferWindowPos
		if (!(((LPWINDOWPOS)lParam)->flags & SWP_NOSIZE || IsIconic(hwnd))) {
			//debugwrite("windowposchanged");
			//let toolbar and status bar resize themselves
			//then recalculate the size of other children windows
			//and fill with x,y,height,width values
			//SendMessage(ToolBar.hwnd, WM_SIZE, SIZE_RESTORED, 0);
			//SendMessage(StatBar.hwnd, WM_SIZE, SIZE_RESTORED, 0);
			SizeMainWndChildren();
		}
		 //let attribute list know of move so its overlay isn't abandoned
		SendMessage(SidePanel.hwnd, WM_MOVE, 0,0);
		return 0;
	}
	case WM_SIZE:
		SizeMainWndChildren();
		LockWindowUpdate(NULL);
		if (!GetFocus()) SetFocus(LanList.hwnd);//SetFocus(GetNextDlgTabItem(MainHwnd, NULL,FALSE));
		return 0;
	/*case WM_SETFONT:
	{
		HDC hdc;
		TEXTMETRIC tm;
		hdc=GetDC(hwnd);
		SelectObject(hdc, wParam);
		GetTextMetrics(hdc, &tm);
		txtPath.height=tm.tmHeight+6;
		ReleaseDC(hwnd, hdc);
		goto DoDefDlgProc;
	}*/
	//case WM_ERASEBKGND:
	//	return true;
	//case WM_SYSKEYDOWN:
	//case WM_SYSKEYUP:
	//	if (wParam==VK_F10) return 0;
	case WM_TIMER:
		switch (wParam) {
		case WM_MENUSELECT:
			KillTimer(MainHwnd, WM_MENUSELECT);
			DisplayHelpTip(TtMsgId, HELPINFO_MENUITEM, ActiveHmenu, hwnd, 0,0);
			break;
		case WM_HELP:
			HideHelpTip();
			break;
		//case ...
		}
		return 0;
	case WM_MENUSELECT:
		debugwrite("menusel w=%8X l=%8X",wParam,lParam);
		if (wParam & MF_POPUP<<16) { // also catches the menu close
			HideHelpTip();
		} else {			
			if (wParam & 0xFFFF) {
				TtMsgId = wParam & 0xFFFF;
				ActiveHmenu=(HMENU)lParam;
				SetTimer(MainHwnd, WM_MENUSELECT, 200, NULL);
				// show help tip after short delay
			}
		}
		return 0;
	case WM_HELP:
		if (((LPHELPINFO)lParam)->iCtrlId != TtMsgId)
			DisplayHelpTip( ((LPHELPINFO)lParam)->iCtrlId,
						    ((LPHELPINFO)lParam)->iContextType,
						    ((LPHELPINFO)lParam)->hItemHandle,
						    (HANDLE)((LPHELPINFO)lParam)->dwContextId, //might be second handle
							((LPHELPINFO)lParam)->MousePos.x,
							((LPHELPINFO)lParam)->MousePos.y);
		return true;
	/*case WM_DROPFILES:
	// works but simply displays the dropped files
	{
		LPDROPFILES lpdf = GlobalLock((HGLOBAL)wParam);

		if (lpdf) {
			short *name=(short*)((char*)lpdf + lpdf->pFiles);

			MessageBeep(-1);
			debugwrite("hdrop=%Xh wParam=%d", lpdf, wParam);
			debugwrite("hdrop files=+%d @%d", lpdf->pFiles, (char*)lpdf+lpdf->pFiles);
			debugwrite("hdrop x=%d y=%d", lpdf->pt.x,lpdf->pt.y);
			debugwrite("hdrop fwide=%d", lpdf->fWide);
			if (lpdf->fWide)
				for (; *name; name+=lstrlenW(name)+1)
					debugwrite("hdrop names=%ls", name);
			else
				for (; *(char*)name; (char*)name+=lstrlenA((char*)name)+1)
					debugwrite("hdrop names=%ls", name);
			//GlobalUnlock((HGLOBAL)wParam);
			GlobalFree((HGLOBAL)wParam);
		}
		return 0;
	}*/
	case WM_CLOSE:
		DestroyWindow(hwnd);
		return 0;
    /*case WM_MEASUREITEM:
		//return DefWindowProc(hwnd, message, wParam,lParam);
	{
		MENUITEMINFO mii;
		HMENU hm;
		//RECT MenuRect;
		//debugwrite("wparam  idctl %d", wParam);
		//debugwrite("itemid %d", ((PMEASUREITEMSTRUCT)lParam)->itemID);
		//debugwrite("ctlid  %d ", ((PMEASUREITEMSTRUCT)lParam)->CtlID);
		hm = ((PMEASUREITEMSTRUCT)lParam)->itemData;
		debugwrite("itemdata %d ", hm);

		mii.cbSize = sizeof(MENUITEMINFO);
		mii.fMask = MIIM_TYPE;
		mii.dwTypeData = "this is a test of the emergency broadcast system";
		debugwrite("sptrb=%X", mii.dwTypeData);
		GetMenuItemInfo(hm, IDM_FILE_COPY, false, &mii);
		debugwrite("sptra=%X", mii.dwTypeData);

		//GetMenuItemRect(MainHwnd, 
		//return DefWindowProc(hwnd, message, wParam, lParam);
		((PMEASUREITEMSTRUCT)lParam)->itemWidth = 100;
		//((PMEASUREITEMSTRUCT)lParam)->itemHeight = 10;

		return false;
		break;
	}*/
    case WM_DESTROY:
        PostQuitMessage(0);
	case WM_WINDOWPOSCHANGING:
		//debugwrite("windowposchanging");
        return 0;
	///case WM_ACTIVATE: //notify dialog panel of focus change
	///	if (SidePanel.hwnd) PostMessage(SidePanel.hwnd, WM_NCACTIVATE,0,0);
		//return 0;
    default:
		return DefDlgProc(hwnd, message, wParam, lParam);
    }
}

// does not actually resize them. just does the calculations of
// correct sizes. Called upon the initial creation of the window
// and upon any resizing of it later. note that the toolbar and
// status bar have already automatically positioned themselves.
void CalcMainWndChildren()
{
	int bottom, left, width;

	GetClientRect(MainHwnd, &rect);

	// left of several
	left=0; //default if no side panel displayed
	if (SidePanel.style & WS_VISIBLE) {
		//GetWindowRect(SidePanel.hwnd, (LPRECT)&SidePanel.x);
		//SidePanel.width-=SidePanel.x;
		if (SidePanel.width+SizePanel.width > rect.right) {
			SidePanel.width = rect.right - SizePanel.width;
		}
		left = SidePanel.width;
		//SidePanel.x=0;
	}
	//SidePanel.x=-2;
	SizePanel.x=left;
	left+=SizePanel.width;
	txtPath.x=left;
	LanList.x=left;
	SizeLog.x=left;
	txtLog.x =left;

	// widths of several
	width = rect.right-left;
	txtPath.width=width;
	LanList.width=width;//+2;
	SizeLog.width=width;
	txtLog.width =width;

	// if toolbar visible. calc tops...
	txtPath.y=0;
	if (ToolBar.style & WS_VISIBLE) {
		//GetClientRect(ToolBar.hwnd, (LPRECT)&ToolBar.x);
		txtPath.y=ToolBar.height;
	}
	SidePanel.y = txtPath.y;
	SizePanel.y = txtPath.y;

	// if status bar visible, calc bottoms...
	bottom=rect.bottom;
	if (StatBar.style & WS_VISIBLE) {
		//GetWindowRect(StatBar.hwnd, (LPRECT)&StatBar.x);
		//StatBar.height-=StatBar.y;	// subtract of silly screen relative positioning
		bottom-=StatBar.height+1;	// move bottom up by status bar height (+2)
	}
	SidePanel.height =
	SizePanel.height = bottom-txtPath.y;
	if (txtLog.style & WS_VISIBLE) {
		bottom-=txtLog.height;	// move bottom up by log window height
	}
	txtLog.y=bottom;
	SizeLog.y=bottom-SizeLog.height;

	// lan list top and size
	LanList.y=txtPath.y + txtPath.height + 2;
	LanList.height=SizeLog.y - LanList.y;

	//debugwrite("stabar crect top=%d bottom=%d left=%d right=%d", StatBar.x, StatBar.y, StatBar.width, StatBar.height);
	debugwrite("toolbar wrect x,y,w,h=%d %d %d %d", ToolBar.x, ToolBar.y, ToolBar.width, ToolBar.height);
}

// actually resizes them based on the calculations of Calc.
// it is not necessary to call the calc first, since this already does.
void SizeMainWndChildren()
{
	CalcMainWndChildren();

	///HDWP dwp = BeginDeferWindowPos(8);	
	/*SizeWndChild(&SizePanel);
	SizeWndChild(&SizeLog);
	SizeWndChild(&txtPath);
	SizeWndChild(&txtLog);
	SizeWndChild(&LanList);
	if (SidePanel.style & WS_VISIBLE) 
	SizeWndChild(&SidePanel);*/
	///EndDeferWindowPos(dwp);

	ChildMoveStart();
	ChildMoveDefer(&SizePanel);
	ChildMoveDefer(&txtPath);
	ChildMoveDefer(&LanList);
	ChildMoveDefer(&txtLog);
	ChildMoveDefer(&SizeLog);
	ChildMoveDefer(&SidePanel);
	ChildMoveDefer(&ToolBar);
	ChildMoveDefer(&StatBar);
	ChildMoveEnd();
}

/*void SizeWndChild(HDWP *dwpp, ChildWindowStruct *cws) {
	*dwpp=DeferWindowPos(*dwpp,cws->hwnd, NULL,
		cws->x, cws->y, cws->width, cws->height,
		SWP_NOACTIVATE|SWP_NOOWNERZORDER|SWP_NOZORDER);
		//SWP_NOSENDCHANGING; // breaks XP completely
}*/

/*void SizeWndChild(ChildWindowStruct *cws) {
	SetWindowPos(cws->hwnd,NULL, cws->x,cws->y, cws->width,cws->height, SWP_NOZORDER|SWP_NOACTIVATE);
} */

#define ChildMoveMax 10
static int ChildMoveTotal;
static struct {
	ChildWindowStruct *cwsp;
	int order;
	} ChildMoveArray[ChildMoveMax];

void ChildMoveStart()
{
	ChildMoveTotal=0;
}

void ChildMoveDefer(ChildWindowStruct *cwsp) {
	int style, order;
	RECT wrect;
	///if (cwsp == &ToolBar) return;
	///debugwrite("tbh=%d tby=%d", ToolBar.height, ToolBar.y);
	if (ChildMoveTotal < ChildMoveMax) {
		style=GetWindowLong(cwsp->hwnd, GWL_STYLE);
		// does local visible == actual visible
		if ((style ^ cwsp->style) & WS_VISIBLE) {
			if (style & WS_VISIBLE)	order=0; // hide old item first
			else					order=4; // show new item last
		} else {
			GetWindowRect(cwsp->hwnd, &wrect);
			wrect.right-= wrect.left; // compensate for top/left offset
			wrect.bottom-=wrect.top;
			if (cwsp->height > wrect.bottom || cwsp->width > wrect.right)
				order=3; // item is being resized larger
			else if (cwsp->height < wrect.bottom || cwsp->width < wrect.right)
				order=1; // item is being resized smaller
			else if (wrect.left != cwsp->x || wrect.top != cwsp->y)
				order=2; //rect is same size, but different position
			else
				return; // rect is exactly the same, so no change
		}
		ChildMoveArray[ChildMoveTotal].order = order;
		ChildMoveArray[ChildMoveTotal].cwsp = cwsp;
		ChildMoveTotal++; // count one more to move
	}
}

void ChildMoveEnd()
{
	int order, idx;
	HWND hwnd;
	ChildWindowStruct *cwsp;
	// do five passes, moving each by its order of precedence
	for (order=0; order<=4; order++) {
		// iterate all the children to be moved
		for (idx=0; idx<ChildMoveTotal; ) {
			// only move child if ready
			cwsp = ChildMoveArray[idx].cwsp;
			if (ChildMoveArray[idx].order <= order) {
				hwnd = cwsp->hwnd;
				switch (order) {
				case 0: ShowWindow(hwnd, SW_HIDE); break;
				case 1:
				case 2:
				case 3: SetWindowPos(hwnd, NULL, cwsp->x,cwsp->y, cwsp->width,cwsp->height, SWP_NOZORDER|SWP_NOACTIVATE); break;
				case 4: ShowWindow(hwnd, SW_SHOW); break;
				}
				ChildMoveTotal--; // count one less to move
				ChildMoveArray[idx]=ChildMoveArray[ChildMoveTotal];
			} else {
				idx++; // skip entry because not ready yet
			}
		}
	}
	ChildMoveTotal=0;
}

BOOL CALLBACK GenericDlgProc(HWND hwnd, UINT message, long wParam, long lParam) 
{
	switch (message)
	{
	case WM_INITDIALOG:
		DefWindowProc(hwnd, WM_SETICON, true, (LPARAM)LoadIcon(ProgMemBase, (LPTSTR)1));
		return true;
	case WM_COMMAND:
		switch (wParam)
		{
		case IDOK:
		case IDCANCEL:
		case IDCLOSE:
			DestroyWindow(hwnd);
			break;
		default:
			SendMessage(GetParent(hwnd), message, wParam, lParam);
		}
		break;
	//case WM_DESTROY:
	}
	return false;
}


/*
// This stupid little function was simply written to prevent the bug
// of multiline edits stealing key focus in dialogs. Also prevents
// the full selection of all the text in it.
int __stdcall IgnoreEditHighlight(HWND hwnd, UINT message, long wParam, long lParam)
{
    if (message==WM_GETDLGCODE) return DLGC_WANTARROWS;
	return CallWindowProc(EditProcPtr, hwnd, message, wParam, lParam);
}
*/


/*BOOL CALLBACK InfoDlgProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	static char SomeText[]={
	"FILE_ATTRIBUTE_READONLY             0x00000001\r\n"
	"FILE_ATTRIBUTE_HIDDEN               0x00000002\r\n"
	"FILE_ATTRIBUTE_SYSTEM               0x00000004\r\n"
	"FILE_ATTRIBUTE_DIRECTORY            0x00000010\r\n"
	"FILE_ATTRIBUTE_ARCHIVE              0x00000020\r\n"
	"FILE_ATTRIBUTE_ENCRYPTED            0x00000040\r\n"
	"FILE_ATTRIBUTE_NORMAL               0x00000080\r\n"
	"FILE_ATTRIBUTE_TEMPORARY            0x00000100\r\n"
	"FILE_ATTRIBUTE_SPARSE_FILE          0x00000200\r\n"
	"FILE_ATTRIBUTE_REPARSE_POINT        0x00000400\r\n"
	"FILE_ATTRIBUTE_COMPRESSED           0x00000800\r\n"
	"FILE_ATTRIBUTE_OFFLINE              0x00001000\r\n"
	"FILE_ATTRIBUTE_NOT_CONTENT_INDEXED  0x00002000\r\n"
	};

	switch (message)
	{
	case WM_INITDIALOG:
	{
		//must manually set text edit focus,
		//otherwise stupid dialog selects all the text
		HWND txtInfo=GetDlgItem(hwnd, IDC_INFO);
		SendMessage(txtInfo, WM_SETTEXT, 0,(LPARAM)SomeText);
		SetFocus(txtInfo);
		break;
	}
	case WM_COMMAND:
		switch (wParam)
		{
		case IDOK:
		case IDCANCEL:
		case IDCLOSE:
			DestroyWindow(hwnd);
		}
		break;
	case WM_DESTROY:
		InfoHwnd=0;
	}
	return false;
}*/


BOOL CALLBACK AboutDlgProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	switch (message)
	{
	case WM_INITDIALOG:
	{
		//must manually set text edit focus,
		//otherwise stupid dialog selects all the text
		//HWND txtInfo=GetDlgItem(hwnd, IDC_INFO);
		//SendMessage(txtInfo, WM_SETTEXT, 0,(LPARAM)SomeText);
		//SetFocus(txtInfo);

		HWND lblVersion;
		HFONT hsbf; //system bold font
		NONCLIENTMETRICS ncm;
		short *comment; //Unicode ptr to comment in version resource

		if (!(lblVersion=GetDlgItem(hwnd, IDC_VERSION))) break;

		// set bold to About label
		ncm.cbSize = sizeof(ncm);
		SystemParametersInfo(SPI_GETNONCLIENTMETRICS, 0, &ncm, false);
		ncm.lfMessageFont.lfWeight=FW_BOLD; //make bold
		hsbf = CreateFontIndirect(&ncm.lfMessageFont);
		SendMessage(lblVersion, WM_SETFONT, (WPARAM)hsbf, (LPARAM)false);

		/*HRSRC hsrc;
		HGLOBAL hmem;
		short *pver;

		hsrc=FindResource(ProgMemBase, (LPTSTR)1, (LPTSTR)RT_VERSION);
		hmem=LoadResource(ProgMemBase, hsrc);
		pver=hmem; //pver=LockResource(hmem);
		debugwrite("hsrc=%d hmem=%d pver=%d", hsrc,hmem,pver);
		if (pver) {debugwrite("ver=%d %d %d", *(pver+88),*(pver+89),*(pver+90));}
		*/

		// Copy version info from resources to label
		// Note the code below is simple and hard code,
		// So if the comment attribute no longer exists
		// or is moved around, the label will show junk
		// +20 = VS_FIXEDFILEINFO
		// +49 = StringFileInfo
		// +79 = Comment key (in this case!)
		// +88 = comment value (in this case!)
		comment = (short*)LoadResource(ProgMemBase, FindResource(ProgMemBase, (LPTSTR)1, (LPTSTR)RT_VERSION))+88;
		//--WideCharToMultiByte(CP_ACP, 0, comment,-1, &textA[0], sizeof(textA), NULL,NULL);
		//--SetWindowText(lblVersion, &textA[0]);
		SetWindowText(lblVersion, comment);

		//SetDlgItemText(hwnd, IDC_ABOUT, TextAbout);
		break;
	}
	//AboutText
	case WM_COMMAND:
	{
		LPTSTR file=NULL;
		switch (wParam)
		{
		case IDC_WEBPAGE:
			file=ProgWebpage;
			break;
		case IDC_EMAIL:
			file=L"mailto:" ProgEmail;
			break;
		case IDC_README:
			file=ProgHelpFile;
			break;
		case IDOK:
		case IDCANCEL:
		case IDCLOSE:
			//DestroyWindow(hwnd);
			EndDialog(hwnd, 0);
		}
		if (file) ShellExecute(hwnd,NULL, file, NULL,NULL,SW_SHOWMAXIMIZED);
		break;
	}
	//case WM_DESTROY:
	//	InfoHwnd=0;
	}
	return false;
}


// if an old different dialog exists, close it
// if the new dialog already exists,
//   if the new dialog has focus, close it
//   else simply set focus to it
// if not exist, create the dialog
void ToggleSidePanel(AttribList *al)
{
	int style = SidePanel.style;
	if (SidePanel.hwnd == NULL || !(style & WS_VISIBLE)
	  || al == (AttribList*)GetWindowLong(SidePanel.hwnd, GWL_USERDATA) ) {
		SidePanel.style ^= WS_VISIBLE;
		ShowWindow(SidePanel.hwnd, (SidePanel.style & WS_VISIBLE) ? SW_SHOWNOACTIVATE : SW_HIDE);
	}
	if (SidePanel.style & WS_VISIBLE) {
		al->himl = ToolBarHiml;
		SendMessage(SidePanel.hwnd, LB_INITSTORAGE, 0, (LPARAM)al);
		//RedrawWindow(SidePanel.hwnd, NULL,NULL, RDW_INVALIDATE);
		if (!(style & WS_VISIBLE)) SetFocus(SidePanel.hwnd);
	}
	SizeMainWndChildren();

/*
	if (SidePanel.hwnd && SidePanel.hwnd!=*DlgHwnd) {
		SendMessage(SidePanel.hwnd, WM_CLOSE, 0,0);
		SidePanel.hwnd=NULL;
	}

	if (*DlgHwnd && IsWindow(*DlgHwnd)) {
		// close it
		if (IsChild(*DlgHwnd, GetFocus())) {
			LockWindowUpdate(MainHwnd);
			SendMessage(*DlgHwnd, WM_CLOSE, 0,0);
			//SidePanel.hwnd=NULL;
			//SizeMainWndChildren();
		} else {
		// set focus
			//SetActiveWindow((HWND)*DlgHwnd);
			SidePanel.hwnd=*DlgHwnd;
			SetFocus((HWND)*DlgHwnd);
		}
		return;
	}

	LockWindowUpdate(MainHwnd);
	*DlgHwnd=CreateDialogParam(ProgMemBase,
		(LPTSTR)DlgResId,
		MainHwnd,
		(DLGPROC)FiltersDlgProc,
		lParam);
	debugwrite("last win error=%d", GetLastError());

	SidePanel.hwnd = *DlgHwnd;
	SizeMainWndChildren();
	ShowWindow(*DlgHwnd, SW_SHOW);
	LockWindowUpdate(NULL);

	// remove any posted messages to resize panel
	PeekMessage(&msg, MainHwnd, WM_SIZE,WM_SIZE,PM_REMOVE);
*/
}

/*///
// nulls the window handles and posts a message
// to main window to resize its children because
// a panel was closed
void DialogPanelClosed(HWND* DlgHwnd) {
	// This IF is necessary because DefDlgProc likes to post close messages
	// instead of sending them (messing with my synchronization)
	// So, if you were create another panel immediately after closing one,
	// it resizes things wrongly.
	if (SidePanel.hwnd==*DlgHwnd)
		*DlgHwnd=SidePanel.hwnd=NULL;
	PostMessage(MainHwnd, WM_SIZE,0,0); //post fake resize message
}*/

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
		cws->param);

	if (!cws->hwnd) {
		TCHAR text[256];
		wsprintf(text, L"Failed to create child window:\nClass=%ls\nId=%d\n\nThe program will probably not work right :(.", cws->className,cws->id);
		MessageBox (0, text, ProgTitle, MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
		//if (MessageBox (0, text, ProgTitle, MB_OKCANCEL|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL) != IDOK)
			//ExitProcess (-1);
	}
}


// This scans the network separate from the main thread, just so that
// the main window won't be frozen if the scan is frozen because someone's
// computer just disconnected from the network, theirs was in sleep mode,
// or yours is waiting on the CD drive to start spinning. It uses a
// critical section for synchronization.
//
// Posts messages to the main window upon:
//	<fill in important events here>
//
PTHREAD_START_ROUTINE ScanThread(LPVOID lpThreadParameter)
{
	short *name;
	unsigned slen;  //temp name length or offset to significant portion
	unsigned int type;
	int count;		//generic counting var
	HOSTENT *host;
	//int next;		//index to next child
	//int depth;		//current depth counter
	//short errmsg[512];
	BOOL recurse;	//indicates has children and needs to be recursed further

	// jump WAY down to bottom
ScanThread_Sleep:
	while (ScanMode & ScanModePaused) {
		ScanMode|=ScanModeAck; //acknowledge alive to other threads
		debugwrite("ScanThread-sleeping");
		AppendLog(L"\r\nscanning thread paused (%d items)", LanListTotal);
		SuspendThread(ScanTh);
		//debugwrite("ScanThread-awoke");
		if (ScanMode & ScanModeDie) goto ScanThread_End;
	}
	AppendLog(L"\r\nscanning thread started");
	debugwrite("ScanThread-scanning");

	ScanPath.depth=0; //**hack
	ScanPath.plen=0; //**hack
	ScanPath.depth=0;

	ScanVolumeSerial=0; //set volume serial number zero to trigger reget

////// entering object name space
ScanThread_EnumEnter:

	ScanMode|=ScanModeAck; //acknowledge alive and responsive, may be reset in another thread

	// for(...)
	if (ScanPath.depth == 0) ScanParent=0; //index of root
	else ScanParent=ScanPath.child[ScanPath.depth-1]; //index of container being scanned
	ScanType = LanAtrs[ScanParent].flags & LlfTypeMask;
	ScanChild= LanAtrs[ScanParent].child;

	debugwrite("name=%ls d%d ts%d", LanAtrs[ScanParent].name, ScanPath.depth, LanNamesSize);
	switch (ScanType) {
	case LlfFolder:
	case LlfShare:
	case LlfDrive:
		name=StringCopy(LanAtrs[ScanParent].name,
			(short*)&ScanPath.path+ScanPath.plen,
			256);
			//LanListMaxPath-ScanPath.plens[ScanPath.depth]-3);
		// set name length in include existing path + current folder + "\"
		ScanPath.plens[ScanPath.depth]
			= ScanPath.plen
			= name-ScanPath.path+1;
		// add trailing "\*" to include all files
		StringCopy(L"\\*", name, 256);
		debugwrite("fp=%ls", &ScanPath.path);
		break;
	case LlfServer:
		StringCopy(L"\\\\", ScanPath.path, 256);
		name=StringCopy(LanAtrs[ScanParent].name,
			ScanPath.path+2,
			256);
			//LanListMaxPath-ScanPath.plens[ScanPath.depth]-3);
		debugwrite("np=%ls", &ScanPath.path);
		// set name length in include existing path + current folder + "\"
		ScanPath.plens[ScanPath.depth]
			= ScanPath.plen
			= name-&ScanPath.path[0]+1;
		break;
	case LlfVolume:
		ScanPath.plens[ScanPath.depth] = ScanPath.plen;
		break;
	case LlfNetwork:
		ScanNr.lpRemoteName=NULL;
		ScanNr.lpProvider=LanAtrs[ScanParent].name; //L"Microsoft Network"; //<- true on Win95
		// fall through
	case LlfComputer:
	case LlfRoot:
		ScanPath.plen=0;
		break;
	}

////// checking existing children and generating checksums
	ScanFnCsTotal=0; //total comparable items in current path
	ScanFnCsIdx=0; //internal pointer inside ScanList by ScanAddItem

	// Generate checksums for all filenames already in the listing
	// and fill the ScanFnCs array
	//
	//GenerateStrChecksum(LanAtrs[count].name);

////// actually scanning object
	recurse=false; //assume initially container has no children containers
				   //if container only has file, printer, or unknown children
				   //do not recurse any further and consider completely enumed
	if (ScanType != LlfShare && ScanType != LlfFolder) {
		GetSystemTime(&ScanYmdTime); //get current time
		SystemTimeToFileTime(&ScanYmdTime, &ScanTime); //convert to pure data/time
	}

	switch(ScanType)
	{
	case LlfDrive:
		ScanVolumeInfo(ScanPath.path);
		if (ScanError) {
			AppendLog(L"\r\ndrive error: %ls", &ScanPath.path);
			LanAtrs[ScanParent].flags |= LlfError;
			goto ScanThread_EnumExit;
		}
		if (ScanAddItem(ScanFd.cFileName, TRUE))
		{
			LanAtrs[ScanChild].timel = ScanTime.dwLowDateTime;
			LanAtrs[ScanChild].timeh = ScanTime.dwHighDateTime;
			LanAtrs[ScanChild].flags = LlfVolume|LlfContainer|ScanPath.depth; //**hack
			LanAtrs[ScanChild].serial = ScanVolumeSerial;

			//LanTree[LanListSize++]=ScanChild; //** hack
			recurse=true;
		}

		/*{	grr - all I want is the stinking volume date
			BY_HANDLE_FILE_INFORMATION hfi;
			HANDLE hdrive=CreateFile("\\\\.\\PHYSICALDRIVE1", 0,//GENERIC_READ,
				FILE_SHARE_READ|FILE_SHARE_WRITE,
				NULL, OPEN_EXISTING, 0, NULL);
			debugwrite("hdrive=%X err=%d", hdrive, GetLastError());
			GetFileInformationByHandle(hdrive, &hfi);
			debugwrite("volser=%X err=%d",hfi.dwVolumeSerialNumber, GetLastError());
			CloseHandle(hdrive);
		} */
		//debugwrite("fileattr=%X",GetFileAttributes("C:\\"));
		/*ScanHandle=FindFirstFile("C:\\", &ScanFd);
		debugwrite("fff label=%d",ScanHandle);
		if (ScanHandle != INVALID_HANDLE_VALUE) {
			do {
				debugwrite("fff label=%ls %d",ScanFd.cFileName,ScanFd.ftCreationTime);
			} while (FindNextFile(ScanHandle, &ScanFd));
			FindClose(ScanHandle);
		}*/
		break;

	case LlfVolume: //drive on local machine
		// ensure that currently inserted volume is the same
		if (!ScanVolumeSerial) {
			ScanVolumeInfo(ScanPath.path);
			if (!ScanError) { // false means getvol failed
				LanAtrs[ScanParent].flags |= LlfError;
				goto ScanThread_EnumExit;
			}
		}
		if (ScanVolumeSerial != LanAtrs[ScanParent].serial)
			// serial number does not match volume currently inserted
			// so gracefully exit to parent
			goto ScanThread_EnumExit;

		// ... fall through otherwise

	case LlfFolder: //folder on local or remote machine
	case LlfShare: //share on remote server
		//ScanFirstFile(L"\\\\piken-pc\\VIDEO\\*");
		//ScanFirstFile(L"\\\\ANGELFEESHY\\MUSIC FILES\\*");
		//ScanFirstFile(L"D:\\NET\\CONTENT.IE5\\NXUVWHUZ\\*");
		//ScanFirstFile(L"E:\\Users\\piken\\Local Settings\\Temporary Internet Files\\Content.IE5\\CDUB81I3\\*");
		//ScanFirstFile(L"\\\\CRAZYMIR\\MY MUSIC\\*");

		ScanFirstFile(ScanPath.path);
		debugwrite("folder=%ls",ScanPath.path);
		if (ScanHandle==INVALID_HANDLE_VALUE) {
			debugwrite("FindFirstFile error ret=%d err=%d", ScanHandle, ScanError);
			//MessageBox(MainHwnd, debugwrite_Buffer, ProgTitle, MB_OK);
			switch (ScanError) {
			case ERROR_ACCESS_DENIED:
				LanAtrs[ScanParent].flags |= LlfDenied;
				break;
			/*
			case ERROR_BAD_NETPATH //53 when server is bad
			case ERROR_BAD_NET_NAME //67 when share is bad
			case ERROR_PATH_NOT_FOUND //3
			case ERROR_BAD_PATHNAME //161 bad characters in name
			case ERROR_FILE_NOT_FOUND //2
			case ERROR_PATH_NOT_FOUND //3
			case ERROR_INVALID_PASSWORD //86
			case ROR_NOT_READY //21
			*/
			default:
				LanAtrs[ScanParent].flags |= LlfError;
			}
			goto ScanThread_EnumExit;
		}
		goto ScanThread_File;
		// continue scanning while return value true and scan mode active
		// note that boolean logic is reversed here for ScanError (1=continue)
		while (ScanError && !(ScanMode & (ScanModePaused|ScanModeDie)) ) {
			// word & byte ptrs to the same string
			TCHAR *fnp;	//filename character ptr to check valid chars
		ScanThread_File:
			// Skip entry if temporary or offline file
			// also skip hidden or system files if specified
			if (!(ScanFd.dwFileAttributes & ScanFileAtrFilters)) {
				// Skip silly . and .. entries; however, allow filenames starting
				// with '.' since they are common in Unix (like ".addressbook").
				// If it scans the whole string and finds only dots before reaching
				// the end (null char) then skip the entry.
				fnp = &ScanFd.cFileName[0];
				debugwrite("cfname=%S", &ScanFd.cFileName[0]);
				for (; *fnp=='.'; fnp++);	//Unicode words
				if (*fnp!=0) { // if not at end of string (null)
					// All ok, add name to list
					if (ScanAddItem(ScanFd.cFileName, TRUE)) {
						if (ScanFd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
							type=LlfFolder|LlfContainer;
							recurse=true;
						} else {
							type=LlfFile;
						}
						LanAtrs[ScanChild].flags = type|ScanPath.depth; //**hack
						LanAtrs[ScanChild].timel = ScanFd.ftLastWriteTime.dwLowDateTime;
						LanAtrs[ScanChild].timeh = ScanFd.ftLastWriteTime.dwHighDateTime;
						LanAtrs[ScanChild].size = ScanFd.nFileSizeLow;

						LanTree[LanListSize++]=ScanChild; //** hack
					}
				}
			}
			ScanError=FindNextFile(ScanHandle, &ScanFd);
		}
		FindClose(ScanHandle);
		break;

	case LlfDomain:
		ScanNr.lpRemoteName=LanAtrs[ScanParent].name;
		//ScanNr.lpRemoteName=L"DIXON";
		ScanNr.lpProvider=NULL;		
		goto ScanThread_Network;

	case LlfNetwork:
		//Already done above
		//ScanNr.lpRemoteName=NULL;
		//ScanNr.lpProvider=L"Microsoft Network"; //<- true on Win95
		//ScanNr.lpProvider=L"Microsoft Windows Network";
		//ScanNr.lpProvider=L"NetWare";
		goto ScanThread_Network;

	case LlfRoot: //root, so enumerate networks
		ScanNetOpenEnum(NULL);
		goto ScanThread_Root;

	case LlfServer:
		//ping server before attempting to access it,
		//otherwise the retarded function does not return
		//for two minutes, basically freezing the whole program >_<

		//...insert ping here...
		// if host name can not be found for some reason

		//if (ScanSocket==0) {
			ScanSocket = WsCreate(AF_INET, SOCK_STREAM, 0);
			AppendLog(L"\r\nSocket handle: %X", ScanSocket);
			WsIoControl(ScanSocket, FIONBIO, &ScanSocket); // nonblocked I/O, just pass the sockect as a value since it is alway nonzero
		//}
		WideCharToMultiByte(CP_ACP, 0, ScanPath.path+2,-1, ScanPath.pathA,LanListMaxPath, NULL,NULL);
		if (host=WsGetHostByName(ScanPath.pathA)) {
			static struct sockaddr SocketAddress = {AF_INET, //.sin_family
                0,139u,		//.sin_port (in silly 'network' order)
				0,0,0,0,	//.sin_addr (IP)
                "FLANSCA"};	//.sin_zero (socket name)

			AppendLog(L"\r\nhost name: %hs\r\nhost alias: %hs", host->h_name, host->h_aliases);
			ScanIp = *(int*)(*(host->h_addr_list));
			*(int*)(&SocketAddress.sa_data[2]) = ScanIp;
			AppendLog(L"\r\nhost ip: %X", ScanIp);

			if (WsConnect(ScanSocket, (struct sockaddr*)&SocketAddress, sizeof(struct sockaddr)) == 0) {
				WsDestroy(ScanSocket);
				AppendLog(L"\r\nconnected to: %X", ScanIp);				
			//} else if (GetLastError()==WSAECONNREFUSED) {
			} else if (GetLastError()==WSAEWOULDBLOCK) {				
				static struct timeval time = {6,0};
				struct fd_set wfds = {1, ScanSocket, -1},
					   xfds = {1, ScanSocket, -1};
				AppendLog(L"\r\nwaiting for connection %d", GetLastError());
				if (WsWait(0, NULL, &wfds, &xfds, &time) >= 1
					&& wfds.fd_count >= 1) {
					// connected
					WsDestroy(ScanSocket);
					AppendLog(L"\r\nconnected after wait");

				} else {
					//error connecting
					AppendLog(L"\r\nconnection failed at wait %d, #%d", GetLastError(), wfds.fd_count);
					goto ScanThread_EnumExit;
				}
			} else {
				//error connecting
				AppendLog(L"\r\nconnection failed at connect %d", GetLastError());
				goto ScanThread_EnumExit;
			}
		} else {
			//if ping fails, mark error on parent and break
			AppendLog(L"\r\nconnection failed at gethostbyname");
			goto ScanThread_EnumExit;
		}

		ScanNr.lpRemoteName=ScanPath.path;
		ScanNr.lpProvider=NULL;//L"Microsoft Windows Network"; //<- true on Win95
		//ScanNr.lpRemoteName = L"\\\\piken-pc";
		//ScanParent=3;
		//LanAtrs[ScanParent].name = L"piken-pc"; //!hack
		//ScanNr.lpProvider=L"Microsoft Windows Network"; //<- true on WinXP
		//if (ScanError = WNetOpenEnum(RESOURCE_GLOBALNET, RESOURCETYPE_DISK, RESOURCEUSAGE_ALL, &ScanNr, &ScanHandle) != NO_ERROR) {
		//if (ScanError = WNetOpenEnum(RESOURCE_GLOBALNET, RESOURCETYPE_DISK, 0, &ScanNr, &ScanHandle) != NO_ERROR) {

	ScanThread_Network:
		ScanNetOpenEnum(&ScanNr);
	ScanThread_Root:
		if (ScanError) {
			switch (ScanError) {
			case ERROR_NOT_AUTHENTICATED: //1244 (in other words bad password, server denied permission)
				LanAtrs[ScanParent].flags |= LlfDenied;
				break;
			case ERROR_BAD_NET_NAME: //67
			case ERROR_NOT_LOGGED_ON: //1245
			case ERROR_NO_NETWORK: //1222 either no network or service not started
				LanAtrs[ScanParent].flags |= LlfError;
				break;
			}
			debugwrite("OpenEnum ret=%d err=%d", ScanError, GetLastError());
			//char neterr[512], netprov[128];
			//WNetGetLastError(&ScanError, &debugwrite_Buffer,128, &debugwrite_Buffer[0],128);
			//debugwrite("neterr=%s\nprovider=%s", &neterr, &netprov);
			//MessageBox(MainHwnd, &debugwrite_Buffer, ProgTitle, MB_OK);
			goto ScanThread_EnumExit;
		}

		ScanCount = -1;
		ScanSize = sizeof(ScanBuffer);
		ScanNetResource();

		debugwrite("NetEnum ct=%d ret=%d err=%d", ScanCount, ScanError, GetLastError());
		/*debugwrite("ret=%d name=%s prov=%s scope=%d type=%d dtyp=%d usage=%d count=%d size=%d", 
			ScanError, 
			ScanBuffer[0].lpRemoteName, 
			ScanBuffer[0].lpProvider,
			ScanBuffer[0].dwScope, 
			ScanBuffer[0].dwType, 
			ScanBuffer[0].dwDisplayType, 
			ScanBuffer[0].dwUsage, 
			ScanCount,
			ScanSize);*/

		//get name of parent remote name
		slen=0;
		for (count=0; count<ScanCount && !(ScanMode & (ScanModePaused|ScanModeDie)); count++) {
			type=ScanBuffer[count].dwDisplayType;

			// extract name from net structure depending on type
			switch (type) {
			case RESOURCEDISPLAYTYPE_NETWORK: //is network provider, not rsrc name
				name=ScanBuffer[count].lpProvider;
				break;
			case RESOURCEDISPLAYTYPE_SERVER: //skip pointless two backslashes in front
				//--name=(short*)((char*)ScanBuffer[count].lpRemoteName+(2<<ScanNetUnicode));
				name=(short*)((char*)ScanBuffer[count].lpRemoteName+2);
				break;
			case RESOURCEDISPLAYTYPE_SHARE: //strip unneeded server name in front of share
				if (slen==0)
					//--slen=(lstrlenW(LanAtrs[ScanParent].name)+3)<<ScanNetUnicode;
					slen=(lstrlen(LanAtrs[ScanParent].name)+3)<<1;				
				name=(short*)((char*)ScanBuffer[count].lpRemoteName+slen);
				break;
			default:
				name=ScanBuffer[count].lpRemoteName; //lpComment
			}

			// add name and attributes
			if (ScanAddItem(name, TRUE))
			{
				type <<= LlfTypeShift;
				if (type>LlfTypeMax) type=LlfGeneric;
				if (ScanBuffer[count].dwUsage & RESOURCEUSAGE_CONTAINER) {
					type |= LlfContainer;
					recurse=true;
				}
				//|| dwType & RESOURCETYPE_DISK) |RESOURCEUSAGE_CONNECTABLE
				LanAtrs[ScanChild].flags = type |ScanPath.depth; //**hack
				LanAtrs[ScanChild].timel = ScanTime.dwLowDateTime;
				LanAtrs[ScanChild].timeh = ScanTime.dwHighDateTime;
				//LanAtrs[ScanChild].ip = 0; //(unknown)

				LanTree[LanListSize++]=ScanChild; //** hack
			}
		}
		WNetCloseEnum(ScanHandle);
		break;

	case LlfComputer:
	{
		unsigned int type;
		unsigned drives=GetLogicalDrives();
		short name[3] = {65,58,0}; //colon and null Unicode

		for (count=0; drives; count++,drives>>=1) {
			if (drives & 1) {
				ScanDrive[0] = name[0] = (wchar_t)('A'+count);
				type=GetDriveType(ScanDrive);
				debugwrite("drive=%hs type=%d",ScanDrive,type);
				if (ScanAddItem(name, TRUE))
				{
					LanAtrs[ScanChild].timel = ScanTime.dwLowDateTime;
					LanAtrs[ScanChild].timeh = ScanTime.dwHighDateTime;
					LanAtrs[ScanChild].size = 0; //(unknown)
					LanAtrs[ScanChild].flags = LlfDrive|LlfContainer
						| ( ((1<<type) & ScanDriveTypeFilters) ? LlfIgnore:0);

					LanTree[LanListSize++]=ScanChild; //** hack
				}
			}
		}
		recurse=true;
		break;
	}
	//default: //some object that I don't know how to enumerate
	//case LlfFile: //file (can't enumerate files because they are not containers!)
	//case LlfGroup:
	//case LlfShareAdmin:
	//case LlfTree:
	//case LlfNdsContainer:
	//case LlfPrinter:
	}

////// recursing object

	// if recurse && depth < maxdepth, then enter first subcontainer in object
	if (recurse && ScanPath.depth < LanListMaxDepth && !(ScanMode & (ScanModePaused|ScanModeDie))) {
		ScanChild = LanAtrs[ScanParent].child;
ScanThread_EnumNext:
		for	(; ScanChild != 0 && ScanChild < LanAtrsMax; ScanChild = LanAtrs[ScanChild].next)
		{
			// if container has not already been completely recursed, and if not ignored
			if ((LanAtrs[ScanChild].flags & (LlfContainer|LlfRecursed|LlfIgnore)) == LlfContainer) {
				ScanPath.child[ScanPath.depth++] = ScanChild;
				ScanParent=ScanChild;
				goto ScanThread_EnumEnter;
			}
		}
	}
		
	// recurse==false or some other reason
	LanAtrs[ScanParent].flags |= LlfEnumerated;

////// exiting object
ScanThread_EnumExit:

	//if user has selected another branch not yet enumerated or being
	//refreshed, then retreat up until reaching a parent of the branch
	//case ftp - close connection
	//case http - close connection
	//if visible, post WM_REFRESHLIST

////// returning up level
	//if (ScanPath.depth==2) MessageBox(MainHwnd, "near end", ProgTitle, MB_OK);
	if (ScanPath.depth > 0 && !(ScanMode & (ScanModePaused|ScanModeDie))) {
		ScanPath.depth--;
		ScanPath.plen = ScanPath.plens[ScanPath.depth];
		ScanChild = LanAtrs[ ScanPath.child[ScanPath.depth] ].next;
		ScanParent = ScanPath.child[ScanPath.depth-1];
		// alternately ScanParent = LanAtrs[ScanChild].parent
		goto ScanThread_EnumNext;
	}

	/*// output entire filename list
	{
		// dump name list to file
		HANDLE fout;
		int slen;
		int counter;
		char crlf[]="\r\n";
		fout=CreateFile("C:\\OUT.TXT", GENERIC_WRITE,0,NULL, CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL|FILE_FLAG_SEQUENTIAL_SCAN, 0);
		//WriteFile(fout, &LanNames[0], LanNamesMax*2, &dummy, NULL);
		for (counter=0; counter<LanListTotal; counter++) {
			slen=lstrlenW(LanAtrs[counter].name);
			WriteFile(fout, LanAtrs[counter].name, slen<<1, &dummy, NULL);
			WriteFile(fout, crlf, 2, &dummy, NULL);
		}
		CloseHandle(fout);
	}*/

	ScanMode|=(ScanModePaused //tell other threads that this one's done
			  |ScanModeAck); //acknowledge scanning, may be reset in another thread		
	goto ScanThread_Sleep; //jump all the way back up to top

ScanThread_End:
	//debugwrite("ScanThread-died");
	//ExitThread(0);
	return 0;
}

// Open enumeration handle for the network in either ANSI or Unicode
// depending on what the OS supports
// Win95's MPR.DLL has a Unicode stub but returns 'non supported' when called
// Does not enumerate printers, only disk shares.
//
// Returns:
//	ScanHandle - handle to enumeration resource
//	ScanError - success/error code (>0 if error)
//	ScanNetUnicode - if Unicode call was successful (only if OS supports it)
void ScanNetOpenEnum(NETRESOURCEW *EnumNr) {
	/*//--char PathA[MAX_PATH], ProviderA[MAX_PATH];
	if (!ScanNetUnicode) goto UseAnsi;
	if ((ScanError=WNetOpenEnumW(RESOURCE_GLOBALNET, RESOURCETYPE_DISK, RESOURCEUSAGE_ALL, EnumNr, &ScanHandle))
		!= 50)  //ROR_NOT_SUPPORTED
		return;
	ScanNetUnicode=false;				
UseAnsi:
	// do conversion if EnumNr is not null
	// which it would be for enumerating the root
	if (EnumNr) {
		if (EnumNr->lpRemoteName) {
			WideCharToMultiByte(CP_ACP, 0, EnumNr->lpRemoteName,-1, PathA,MAX_PATH, NULL,NULL);
			EnumNr->lpRemoteName = (short*)&PathA;
		}
		if (EnumNr->lpProvider) {
			WideCharToMultiByte(CP_ACP, 0, EnumNr->lpProvider,-1, ProviderA,MAX_PATH, NULL,NULL);
			EnumNr->lpProvider = (short*)&ProviderA;
		}
	}
	*/
	ScanError=WNetOpenEnum(RESOURCE_GLOBALNET, RESOURCETYPE_DISK, RESOURCEUSAGE_ALL, EnumNr, &ScanHandle);
	//--ScanError=WNetOpenEnumA(RESOURCE_GLOBALNET, RESOURCETYPE_DISK, RESOURCEUSAGE_ALL, (struct _NETRESOURCEA *)EnumNr, &ScanHandle);
}

//	Enumerates resources on the network. ScanNetOpenEnum must have
//	already been called.
//
// In:
//	ScanNetUnicode - returns Unicode if true, otherwise ANSI
//
// Returns:
//	ScanError - success/error code
//	ScanBuffer - fills with info
void ScanNetResource() {
	/*//--if (ScanNetUnicode)
		ScanError=WNetEnumResourceW(ScanHandle, &ScanCount, &ScanBuffer, &ScanSize);
	else
		ScanError=WNetEnumResourceA(ScanHandle, &ScanCount, &ScanBuffer, &ScanSize);
	*/
	ScanError=WNetEnumResource(ScanHandle, &ScanCount, &ScanBuffer, &ScanSize);
}

//	Enumerates files on local machine/server.
//
// Returns:
//	ScanHandle - handle to enumeration resource
//	ScanError - success/error code
//	ScanFd - fills file data with info of first file
void ScanFirstFile(LPWSTR path) {
	ScanError=0;
	ScanHandle=FindFirstFile(path, &ScanFd);
	if (ScanHandle == INVALID_HANDLE_VALUE)
		ScanError=GetLastError();

	/*//--char PathA[MAX_PATH];
	if (!ScanFileUnicode) goto UseAnsi;
	ScanHandle=FindFirstFileW(PathW, &ScanFd);
	if (ScanHandle != INVALID_HANDLE_VALUE || (ScanError=GetLastError()) != 120) return;
	ScanFileUnicode=false;
UseAnsi:
	WideCharToMultiByte(CP_ACP, 0, PathW,-1, PathA,MAX_PATH, NULL,NULL);
	ScanHandle=FindFirstFile((LPTSTR)&PathA, (WIN32_FIND_DATAA*)&ScanFd);
	if (ScanHandle == INVALID_HANDLE_VALUE) ScanError=GetLastError();
	*/
}

//	Gets the next filename in a directory. ScanFirstFile must have
//	already been called.
//
// In:
//
// Returns:
//	ScanError - success/error code
//	ScanFd - fills file data with info
//--void ScanNextFile() {
//	ScanError=FindNextFile(ScanHandle, &ScanFd);
//}

//	Gets volume's label and serial number. I WANT to get the DATE too!
//	But then you have to remember what OS you are dealing with -_-
//
// In:
//	path - only the first character (drive letter) is important.
//
// Returns:
//	ScanError - success/error code
//	ScanFd.cFileName - fills name with volume label
//	ScanVolumeSerial - sets volume serial number
void ScanVolumeInfo(LPTSTR path) {
	ScanDrive[0] = *path; //replace first character with drive letter
	debugwrite("drive=%hs", ScanDrive);
	ScanError = !GetVolumeInformation(
					ScanDrive,
					ScanFd.cFileName,
					MAX_PATH,
					&ScanVolumeSerial,
					NULL,NULL, NULL,0);
	#ifdef MYDEBUG
	if (!ScanError) {
		debugwrite("volinfo lbl=%s #%08X",ScanFd.cFileName, ScanVolumeSerial);
	}
	#endif
	debugwrite("GetVolInfo ret=%d err=%d", ScanError, GetLastError());
}

// Adds a new entry to the LAN list if:
//  the name is not filtered
//  the name is new, not already in the list
//	room in the data array for attributes
//  room in the text buffer for the name
// Expects:
//  ScanChild and ScanParent variables are valid
//  name checksum table for current path is already filled
// Returns:
//  0 - if filterd or failure like no more room for attributes or names 
//  1 - success but name already exists
//  2 - success and new name added to 
unsigned int ScanAddItem(short* Name, int Unicode)
{
	unsigned int CharCount;
	short *Dest=(&LanNames[0])+LanNamesSize;

	// check all conditions
	if (LanListTotal >= LanAtrsMax) {
		ScanMode&=~ScanModeActive;
		debugwrite("LanItemAdded-entries full");
		return false;
	}

	if (Unicode)
		CharCount=lstrlenW(Name);
	else
		CharCount=MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, (char*)Name,-1, Dest, LanNamesMax-LanNamesSize);

	if (CharCount==0 || LanNamesSize+CharCount+1 >= LanNamesMax) { //if end of name (plus null) would overwrite end of buffer
		ScanMode&=~ScanModeActive;
		debugwrite("LanItemAdded-names full");
		return false;
	}

	if (Unicode) RtlMoveMemory(Dest, Name, CharCount<<1);

	//debugwrite("cs=%d", GenerateStrChecksum(Dest));
	//SendMessage(DbgHwnd, LB_ADDSTRING, NULL, debugwrite_Buffer);

	// add new item, all conditions valid, set next/child pointers
	LanAtrs[LanListTotal].next = LanAtrs[LanListTotal].child = 0;
	if (ScanChild == 0)
		LanAtrs[ScanParent].child = LanListTotal;
	else
		LanAtrs[ScanChild].next = LanListTotal;

	LanAtrs[LanListTotal].parent=ScanParent;

	// set text ptrs
	LanAtrs[LanListTotal].name = Dest;
	Dest+=CharCount; *Dest=0; Dest++;
	LanNamesSize=Dest-&LanNames[0];

	ScanChild = LanListTotal;
	LanListTotal++;

	return true;
	// now it is up to the caller to fill in the remaining details
}

// purpose:
//	Builds a path string for the selected item that is compatible with
//	the OS's file system.
//
// returns:
//	Ptr to Unicode path.
short* __stdcall GetLanListOsPath(unsigned int item, int unicode)
{
	int depth=0;
	unsigned int children[LanListMaxDepth], child;
	static short path[LanListMaxPath];			//Unicode path string
	static char  pathA[LanListMaxPath];			//ANSI path string
	short *name=path;	// generic name ptr

	// work bottom up, from child to root
	while (item && depth < LanListMaxDepth) {
		children[depth++]=item;
		item = LanAtrs[item].parent;
	}

	path[0]=0; // set null initially
	while (depth-- > 0) {
		child = children[depth];
		switch (LanAtrs[child].flags & LlfTypeMask) {
		case LlfFolder:
		case LlfShare:
		case LlfFile:
			name=StringCopy(L"\\", name, 2);
		case LlfDrive:
			name=StringCopy(LanAtrs[child].name, name, 256);
			debugwrite("fp=%ls", path);
			break;
		case LlfServer:
			StringCopy(L"\\\\", path, 3);
			name=StringCopy(LanAtrs[child].name, path+2, 256);
			debugwrite("np=%ls", path);
			break;
		//case LlfVolume:
		//case LlfNetwork:
		//case LlfComputer:
		//case LlfRoot:
		}
	}

	if (unicode) {
		return path;
	} else {
		WideCharToMultiByte(CP_ACP, 0, path,-1, pathA, sizeof(pathA), NULL,NULL);
		return (short*)pathA;
	}
}

/*
fill current path

int first child
zero folder size
copy current folder table (for comparison)

switch entering into
network: set name to current network
workgroup: copy name to path
server: copy "\\"+name to path
folder,file: append name to path
ftp: connect to server given user/pass
else: append name to path
endswitch

<enumerate networks objects>
open network object
if error==access denied, folder as password protected
if error==does not exist
  if server does not exist, mark as ghost
  if share does not exist, delete share
endif
get all network objects
if error==access denied, folder as password protected
add all entries while more and continue scan
  switch type
  network: name=network provier
  group: name=resource name
  server: name=server name+2 (to skip "\\")
  share: name=first character after last "\"
  other: ??
  endswitch
  if new name (no existing object of same name, or exact same size and date)
    find entry for it, if all filled, quit scan
    copy name, if no space, quit scan
  else
    remove entry from table (to speed later comps)
  endif
  loop
endif
rescan if more left
quit:
close network handle
if more left in table, mark all as nonenumerated (not ghosts)

<enumerate file objects>
find first file
while continue && no error
  if new name (no existing object of same name, or exact same size and date), add entry
    find entry for it, if none left, quit scan
    copy name, if no space, quit scan
  else
    remove entry from table (to speed later comps)
  endif
  find next file
endwhile
if error==access denied, folder as password protected
quit:
close file handle
if more left in table, delete old files

<enumerate ftp objects - theory>
cd
list
...

<enumerate http objects - theory>
open index.html
scan for all links
add links to list (exclude any filename.asp?xxxx versions)
open any html,asp,dhtml,css pages
follow all links that point at or below base path
...

<enumerate local drives>
get drive mask
add to list all set bits

<enumerate scanned IPs>
do IP scan starting from lower range
  attempt connection to machine through NetBIOS port
  if IP does exist
	resolve host name, selecting correct one for NetBIOS if multiple
	add name to list
    if connection was refused, set error
  endif
  next IP is current+1 or lower range+pseudorandom value
loop until until done

if at least one object scanned, set first child in parent folder

if not continue scan, release critical section, post redraw message, suspend self

current child=first
while current child != NULL and continue
  if item is container and not already enumerated, enter and save stack
  current child=next child
endwhile
now reached last item in container list
mark as enumerated
post redraw message

restore stack vars and exit
switch exiting from
network:
workgroup:
server:
folder,file: do nothing
ftp: close server connection
http: close server connection
endswitch

*/


/*HWND hwnd; 
UINT message; 
WPARAM wParam; 
LPARAM lParam; */


void InitDummyList()
{
	short *Src;

#if 1
	typedef struct {
		short *name;
		int flags;
	} idlNode;
	static idlNode idlNodes[] = {
		//L"Microsoft Network",LlfNetwork|0,
		//L"Dixon",LlfDomain|1,
		//L"piken-pc",LlfServer|2,
  #if 1
		L"Local Machine",LlfComputer|0,
		L"A:",LlfDrive|LlfIgnore|1,
		L"C:",LlfDrive|1,
			L"My Toy (3E80-14E5)",LlfVolume|2,
				L"docs",LlfFolder|3,
				L"media",LlfFolder|3,
					L"Cowboy Bebop 01.avi",LlfFile|4,
					L"Cowboy Bebop 02.avi",LlfFile|4,
					L"Cowboy Bebop 03.avi",LlfFile|LlfChanged|4,
					L"Spirited Away.avi",LlfFile|LlfDeleted|4,
					L"\x30D4\x30A4\x30AF\x30F3.avi",LlfFile|4,
				L"pics",LlfFolder|3,
					L"acg",LlfFolder|4,
					L"anime",LlfFolder|LlfError|4,
					L"lefem",LlfFolder|LlfDenied|4,
				L"src",LlfFolder|3,
		L"D:",LlfDrive|1,
			L"MSDNCD20D2 (75A7-51C4)",LlfVolume|2,
			L"103 Ranma S3 (804B-6AC3)",LlfVolume|2,

		L"Microsoft Network",LlfNetwork|0,
		L"Dixon",LlfDomain|1,
		L"AlienMonkey (128.192.68.33)",LlfServer|LlfNew|2,
		L"AngelFeeshy",LlfServer|2,
		L"Divinelemon",LlfServer|LlfNew|LlfDenied|2,
		L"Hunter",LlfServer|2,
		L"Neo",LlfServer|LlfError|2,
		L"piken-pc",LlfServer|2,
			L"pics anime",LlfShare|3,
				L"amg",LlfFolder|4,
				L"bgc",LlfFolder|4,
				L"ccs",LlfFolder|LlfNew|4,
				L"uy",LlfFolder|4,
			L"docs",LlfShare|3,
			L"media",LlfShare|3,
				L"Cowboy Bebop 01.avi",LlfFile|4,
				L"Cowboy Bebop 02.avi",LlfFile|4,
				L"Cowboy Bebop 03.avi",LlfFile|LlfChanged|4,
				L"Spirited Away.avi",LlfFile|LlfNew|LlfDeleted|4,
				L"\x30D4\x30A4\x30AF\x30F3.avi",LlfFile|4,
			L"src",LlfShare|LlfDenied|3,
		L"Super-Fly",LlfServer|2,
		L"YOS",LlfServer|2,
		L"Sheila",LlfServer|LlfDenied|2,
		L"Kaci",LlfServer|2|LlfDenied,
		L"Katie",LlfServer|LlfError|2,
		L"Amber",LlfServer|2,
		L"Erin",LlfServer|2,
		L"Belinda",LlfServer|LlfDeleted|2,
		L"Margie",LlfServer|2,
		L"Danica",LlfServer|2,
		L"Darcy",LlfServer|2,
		L"Jennifer",LlfServer|2,
		L"Christina",LlfServer|2,
		L"Kendal",LlfServer|2,

		L"Azalea",LlfDomain|1,
		L"BartleMj",LlfServer|2,
		L"Marley",LlfServer|2,
		L"Nelsomar",LlfServer|2,


		L"Avery",LlfDomain|1,		

		L"ANCHORS",LlfServer|2,
		L"ANDREWKIEMNEC",LlfServer|2,
		L"BEPPO",LlfServer|2,
		L"CHAPPY",LlfServer|2,
		L"CLEB",LlfServer|2,
		L"DIESEL",LlfServer|2,
		L"J0UR-M0M",LlfServer|2,
		L"LUC",LlfServer|2,
		L"MUNKJA",LlfServer|2,
		L"OZYZO",LlfServer|2,
		L"RANDO",LlfServer|2,
		L"SCOTT",LlfServer|2,
		L"SMITHHAR",LlfServer|2,
		L"THE_BEAST",LlfServer|2,
		L"TOKIGMAN",LlfServer|2,
		L"WHITEKNIGHT",LlfServer|2,

		L"Heckart",LlfDomain|1,
		L"AEFIRPO",LlfServer|2,
		L"ANIMAL",LlfServer|2,
		L"BRASSMONKEY",LlfServer|2,
		L"D3L5",LlfServer|2,
		L"DELANEY",LlfServer|2,
		L"HANSOLOTHE3RD",LlfServer|2,
		L"METAMOTION",LlfServer|2,
		L"SCHONAU",LlfServer|2,
		L"SLN13",LlfServer|2,
		L"ZAFFO",LlfServer|2,

		L"Reed",LlfDomain|1,
		L"Bob the Builder",LlfServer|2,
		L"Patronbox",LlfServer|2,
		L"Scott",LlfServer|2,
  #endif
		0
	};
	//LanListTop=20;

	for (count=0; ;count++,LanListTotal++) {
		//debugwrite("initdummylist=%d",count);
		Src=idlNodes[count].name;
		if (Src==NULL) break;
		LanTree[count]=LanListTotal;
		LanAtrs[LanListTotal].name=Src;
		LanAtrs[LanListTotal].flags=idlNodes[count].flags;
	}
	LanListSize=count;

#elif 0
	; insert test data here
#endif
}


// Finds the item position of a given menu id.
//
// Stupid little function because Windows does not have
// a simple reverse ID to index function. Note that it
// can not return the index of a popup menu because for
// whatever tarded reason, popup items can not have IDs.
//
// Returns:
//	zero based position of menu item
//  -1 if ID does not exist in menu
//  -2 if ID is actually popup handle or separator
int MenuIdToPos(HMENU menu, unsigned int id)
{
	int count;
	if (id > 65535) return -2;

	count=GetMenuItemCount(menu)-1;
	for (; count>=0; count--)
		if (GetMenuItemID(menu, count) == id)
			return count;
	return -1;
}

// Displays a help tip for the current control or menu choice.
// Gets the tip message from the string table using the identifier 
// of the control or menu choice, and puts it at a fitting place.
//
// main menu/system menu/popup menu - displays on right side of choice
// window/control - displays slightly below top/left corner
// manual - places at specified offset from control
//
// Grr, this is all an ugly kludge just to compensate for what MS should
// have simply done correctly in the first place. This code would be so
// minimal if the functions would at least work logically, or even like 
// the documentation says >_<
//
// Works on Main window and child windows too.
void DisplayHelpTip (int id, int type, HANDLE handle, HANDLE handle2, int x, int y) {
	TCHAR text[256];
	HWND chwnd, owner;
	SIZE sz;
	int item;
	///debugwrite("- wm_help h=%X id=%X", handle, id);

	if (id<=0) return;
	HideHelpTip();

	if (type==HELPINFO_MENUITEM)
	{
		unsigned int pid=GetCurrentProcessId(), wpid;

		// this code below is wastefully complex and could
		// all be reduced to a few lines if MS had simply
		// written functions that actually worked correctly.

		// get the menu item position, which in this case is more
		// useful than the menu identifier passed in.
		item=MenuIdToPos(handle, id);
		if (item < 0) return;

		// get the menu's window location
		// Since there is no function to return the window handle
		// of the active menu, find it manually, using the mostly
		// undocumented class 'name' of menus. Ensure the found
		// menu belongs to this process. Originally I also made
		// sure the menu was visible, but then I discovered that
		// Windows sometimes sent the select message while the
		// menu was still hidden.
		chwnd=NULL;
		do {
			chwnd = FindWindowEx(NULL, chwnd,L"#32768",NULL);
			if (!(int)chwnd) return;
			GetWindowThreadProcessId(chwnd,&wpid);
			///debugwrite("menu hwnd=%X own=%X", chwnd, GetWindow(chwnd, GW_OWNER));
		} while (pid!=wpid); //&& !IsWindowVisible(chwnd));
		owner=GetWindow(chwnd, GW_OWNER);
		if (owner==NULL) owner=handle2; //cheap hack since Windows is causing me so much grief
		GetWindowRect(chwnd, &rect);
		x=rect.right;
		y=rect.top;
		///debugwrite("menu rect=%d,%d - %d,%d", rect.left, rect.top,rect.right,rect.bottom);

		//* debug showing xor outline around menu edge
		/*{
			HWND desk=GetDesktopWindow();
			HDC hdc=GetWindowDC(desk); //GetDC(desk);
			HPEN pen=CreatePen(PS_SOLID|PS_INSIDEFRAME,5,0xFF0000);
			//int err;
			SelectObject(hdc,GetStockObject(NULL_BRUSH));
			SelectObject(hdc,pen);
			SetROP2(hdc,R2_NOT);
			Rectangle(hdc,rect.left,rect.top,rect.right,rect.bottom);
			//err=Rectangle(hdc,100,100,400,400);
			//debugwrite("desk=%X hdc=%X rect=%d",desk,hdc,err);
			Sleep(50);
			Rectangle(hdc,rect.left,rect.top,rect.right,rect.bottom);
			ReleaseDC(desk,hdc);
			DeleteObject(pen);
		}*/

		// get the screen position of the selected menu item.
		// The function does NOT return the coordinates relative
		// to the actual screen position like would make sense or
		// even like the documentation says that it does. It does
		// not even at least return the rectangle relative to the
		// origin of the menu, which would also be useful. Instead, 
		// it returns some hybrid coordinates relative to both the
		// current item and the client area.
		GetMenuItemRect(owner, handle, item, &rect);
		ScreenToClient(owner, (POINT*)&rect);
		y+=rect.top;
		sz.cx=100; // set tooltip max width

	} else {
		if (type!=HELPINFO_WINDOW+4) { //just picked an arbitrary number high enough
			x=8;
			y=18;
		//else { //otherwise it equals itself
		//	x=x; y=y;
		}
		ClientToScreen(handle, (POINT*)&x);
		sz.cx=300; // set tooltip max width
	}

	// set tooltip text for command
	LoadString(ProgMemBase, id, text, sizeof(text));
	tti.lpszText = text[0] ? text : L"No help for this item";
	SendMessage(TtHwnd, TTM_SETMAXTIPWIDTH, 0,sz.cx); // set max width before wrapping text
	SendMessage(TtHwnd,TTM_UPDATETIPTEXT, 0,(LPARAM)&tti);
	//SetWindowText(StatBar.hwnd, tti.lpszText);
	//debugwrite("tooltip x=%d y=%d", handle, x, y);

	// This is truly a kludge, but the tooltip behavior forces it
	// I wanted to ensure that the tooltip was never off screen,
	// with half of the message obscured. So, I tried to set the
	// tooltip text, get the new size, reposition, then show it.
	// Sadly though, the tooltip would not calculate its until
	// it was actually shown. Either you had to deal with a 
	// brief flash of text from where the tooltip was previously
	// located, or get the wrong size from the previous message.
	// So this approach shows the tooltip, but offscreen. Then,
	// it simply moves it back on screen.
	SendMessage(TtHwnd,TTM_TRACKPOSITION, 0,(LPARAM)((-1024&0xFFFF) | -1024<<16)); // put way off screen
	SendMessage(TtHwnd,TTM_TRACKACTIVATE, (WPARAM)true,(LPARAM)&tti); // now show it so it calcs size
	SendMessage(TtHwnd,TTM_TRACKACTIVATE, (WPARAM)false,(LPARAM)&tti); // now show it so it calcs size

	// ensure none of it extends off screen
	GetWindowRect(TtHwnd, &rect); // get new size
	sz.cx=rect.right-rect.left;
	sz.cy=rect.bottom-rect.top;
	//debugwrite("tt cx=%d cy=%d",sz.cx,sz.cy);
	SystemParametersInfo(SPI_GETWORKAREA,0, &rect, FALSE);
	if (x > rect.right-sz.cx)	x = rect.right-sz.cx;
	if (x < rect.left)			x = rect.left;
	if (y > rect.bottom-sz.cy)	y = rect.bottom-sz.cy;
	if (y < rect.top)			y = rect.top;

	SendMessage(TtHwnd,TTM_TRACKPOSITION, 0,(LPARAM)(x|y<<16)); // reposition one last time
	SendMessage(TtHwnd,TTM_TRACKACTIVATE, (WPARAM)true,(LPARAM)&tti); // now show it so it calcs size
	//SendMessage(TtHwnd,TTM_TRACKACTIVATE, (WPARAM)true,(LPARAM)&tti); // now show it so it calcs size
	//<ShowHelpTip()>
	SetTimer(MainHwnd, WM_HELP, 4000, NULL);
	TtMsgId = id; // keep track of displayed message id

	return;
}

		
void EnterHelpTipMode () {
	HWND hhwnd = NULL;
	//**FlashWindow(MainHwnd, true);
	//**MessageBeep(MB_ICONEXCLAMATION);
	SetCapture(MainHwnd);
	SetCursor(LoadCursor(NULL, IDC_HELP));
	while(GetMessage(&msg, 0, 0,0)>0)
	{
		//**debugwrite("help msg=%X w=%X l=%X", msg.message, msg.wParam, msg.lParam);
		switch (msg.message) {
		case WM_NCMOUSEMOVE:
		case WM_MOUSEMOVE:
		{
			hhwnd = WindowFromPoint(msg.pt);
			GetClientRect(hhwnd, &rect);
			ClientToScreen(hhwnd, (POINT*)&rect);
			if (msg.pt.y <  rect.top
			 || msg.pt.y >= rect.top+rect.bottom
			 || msg.pt.x <  rect.left
			 || msg.pt.x >= rect.left+rect.right)
				break;

			SendMessage(hhwnd, msg.message, msg.wParam, msg.lParam);
			// must use send instead of dispatch

			if (hhwnd == ToolBar.hwnd) { //special case for Toolbar
				// get command identifier of hovered button
				// then get rectangle around button to place tooltip
				TBBUTTON tbb;
				int hot=SendMessage(ToolBar.hwnd, TB_GETHOTITEM, 0, 0);
				//**debugwrite("tbhot=%d", hot);
				if (hot >= 0) {
					SendMessage(ToolBar.hwnd, TB_GETBUTTON, hot, (LPARAM)&tbb);
					//**debugwrite("tbcmd=%d", tbb.idCommand);
					if (tbb.idCommand != TtMsgId) {
						SendMessage(ToolBar.hwnd, TB_GETITEMRECT, hot, (LPARAM)&rect);
						DisplayHelpTip(tbb.idCommand, HELPINFO_WINDOW+4, hhwnd, NULL, rect.left,rect.bottom);
					}
				}
			} else if (hhwnd != TtHwnd && hhwnd != MainHwnd) { //if hovered window is not main window or tooltip
				HELPINFO hi = {sizeof(HELPINFO),
							   HELPINFO_WINDOW,
							   GetDlgCtrlID(hhwnd),
							   hhwnd,
							   0,
							   msg.pt.x, msg.pt.y};
				SendMessage(hhwnd, WM_HELP, 0, (LPARAM)&hi);
				//DisplayHelpTip(GetDlgCtrlID(hhwnd), HELPINFO_WINDOW, hhwnd, null, msg.pt.x, msg.pt.y);
				//hhwnd = nhwnd;
			}
			break;
		}
		case WM_PAINT:
			DispatchMessage(&msg);
			break;
		case WM_KEYDOWN:
		case WM_NCLBUTTONDOWN:
		case WM_NCRBUTTONDOWN:
		case WM_LBUTTONDOWN:
		case WM_RBUTTONDOWN:
			//**MessageBeep(MB_ICONEXCLAMATION);
			//**FlashWindow(MainHwnd, true);
			HideHelpTip();
			ReleaseCapture();
			return;
		//default:
		// dispatch message to main window or dialog boxes
		//if(!IsDialogMessage(GetActiveWindow(), &msg))
		//	DispatchMessage(&msg);
		}
	}
	PostQuitMessage(0);
}
	
	
/*void ShowHelpTip() {
	// does not seem to work with tracking tooltips
	//SendMessage(TtHwnd,TTM_SETDELAYTIME, TTDT_AUTOPOP,(LPARAM)1000);
	SendMessage(TtHwnd,TTM_TRACKACTIVATE, (WPARAM)true,(LPARAM)&tti);
	SetTimer(MainHwnd, WM_HELP, 4000, NULL);
}*/


void HideHelpTip() {
	SendMessage(TtHwnd,TTM_TRACKACTIVATE, (WPARAM)false,(LPARAM)&tti);
	KillTimer(MainHwnd, WM_HELP);
	TtMsgId=0;
}


void RegisterClassTry(WNDCLASSW *wc)
{
	/*/--char ClassA[256];			//temp string for converted ANSI name
	int success;				//return value

	if (unicode) {
		success=RegisterClassW(wc);
	} else {
		WideCharToMultiByte(CP_ACP, 0, wc->lpszClassName,-1, ClassA, sizeof(ClassA), NULL,NULL);
		wc->lpszClassName = (short*)ClassA;
		success=RegisterClassA((WNDCLASSA*)wc);
	}
	if (!success) {
		TCHAR text[256];
		wsprintf(text,L"Failed to register window class:\n%hs\n\nThe program will probably not work right,\nbut if you really want to ignore it, you may.\nIt has been tested on Win 95, 98, & XP.", ClassA);
		if (MessageBox (0, text, ProgTitle, MB_OKCANCEL|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL) != IDOK)
			ExitProcess (-1);
	}*/
	if (!RegisterClass(wc)) {
		TCHAR text[256];
		wsprintf(text,
			L"Failed to register window class:\n%hs\n\n"
			L"The program will probably not work right,\n"
			L"but if you really want to ignore it, you may.\n"
			L"It has been tested on Win 95, 98, & XP.",
			wc->lpszClassName);
		if (MessageBox (0, text, ProgTitle, MB_OKCANCEL|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL) != IDOK)
			ExitProcess (-1);
	}
}


// append a status or informational message to log window
void AppendLog(LPWSTR text, ...)
{
	TCHAR msg[256*2]; // resulting msg

	SendMessage(txtLog.hwnd, EM_SETSEL, 32766,32766);
	//SendMessageW(txtLog.hwnd, EM_SCROLLCARET, 0,0);
	wvsprintf((LPWSTR)msg, (LPWSTR)text,  (char*)((&text)+1));
	SendMessage(txtLog.hwnd, EM_REPLACESEL, FALSE,(LPARAM)msg);
}

// display message box before ending program
void __stdcall FatalErrorMessage(LPTSTR Message)
{
	MessageBox(0, Message, ProgTitle, MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL);
	ExitProcess (-1);
}


// if raw

//#define WIN32_LEAN_AND_MEAN
//#include <wintemp.h>
//#include <winutemp.h>

/*
__declspec(dllimport)
int
__stdcall
MessageBoxA(
    int hWnd,
    char* lpText,
    char* lpCaption,
    int uType);

#define MessageBox MessageBoxA

typedef struct tagtester
{
	int az;
	short af;
	int bz;
	int cz;
} tester;

//extern MessageBox();
//#define MessageBox __imp__MessageBox@16

int __stdcall main (int hinstance, int hPrevInstance, char* lpCmdLine, int cmdShow)
//int APIENTRY WinMain (HINSTANCE hinstance, HINSTANCE hPrevInstance, LPTSTR lpCmdLine, int cmdShow)
{
    //MSG msg;
    //WNDCLASS wc;
	tester test = {1,1.5,2,3};

	//wvsprintf(StrDest, "testing %d here", testadr);
	//MessageBox(0, StrDest, "A do nothing caption", 0);
	MessageBox(0, "This program does absolutely nothing", "A do nothing caption", 0);

	return 0;

}
*/


#if 0
int __stdcall PknTextLabelProc(HWND hwnd, UINT message, long wParam, long lParam)
{
    switch (message) {
    case WM_CREATE:
		return false;
	case WM_DESTROY:
	case WM_PAINT:
	{
		// get window text and draw text
		PAINTSTRUCT ps;
		char text[256];
		RECT rect;

		BeginPaint(hwnd, &ps);
		DefWindowProc(hwnd, WM_GETTEXT, 256,&text);
		SetBkMode(ps.hdc, TRANSPARENT);
		GetClientRect(hwnd, &rect);
		SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
		DrawText(ps.hdc, &text, -1, &rect, DT_TOP|DT_CENTER);
		EndPaint(hwnd, &ps);
		return false;
	}
	case WM_ERASEBKGND:
		return true;
	default:
		return DefWindowProc(hwnd, message, wParam, lParam);
	}
}
//DrawCaption(hwnd, ps.hdc, &rect, DC_ACTIVE|DC_TEXT|DC_ICON|DC_GRADIENT);
#endif

// counting all subchildren (visible)
// enumeration
// ordering of current level
// insert spacing
// search current level for containers with at least one child

// enumerate and fill in from front, then respace to end
// src = childcount + ofs-1
// dest = subchildcount + ofs-1
// for (; src>=offset; src--, dest-=child spacing+1)


static int __stdcall TempRefreshList(unsigned int item)
{
	int child;
	if (!(LanAtrs[item].flags & LlfContainer)) return 0;
	LanListSize=0;

	child = LanAtrs[item].child;
	while (child) {
		LanTree[LanListSize++]=child;
		child = LanAtrs[child].next;
	}
	if (LanListSize<=0) {
		if (LanAtrs[item].child) {
			SetWindowText(LanList.hwnd, L"(folder has children but current filters hide them)");
		} else {
			if (LanAtrs[item].flags & LlfEnumerated)
				SetWindowText(LanList.hwnd, L"(folder is empty)");
			else if (LanAtrs[item].flags & LlfDenied)
				SetWindowText(LanList.hwnd, L"(folder is passworded)");
			else
				SetWindowText(LanList.hwnd, L"(folder has not been scanned yet)");
		}
	}

	InvalidateRect(LanList.hwnd, NULL,FALSE);
	LanListParent=item;
	//LanListSelect=0;
	LanListTop=0;
	return 1;
}
