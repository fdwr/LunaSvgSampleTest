////////////////////////////////////////////////////////////////////////////////
// Include other includes

#define WIN32_LEAN_AND_MEAN
#define NO_STRICT
#define WINVER 0x0401
#define _WIN32_WINDOWS 0x0401
#define NOATOM
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
#include <commctrl.h>	// for status bar, tool bar
#include <commdlg.h>	// for file browse dialog
#include <winnetwk.h>	// for network enumeration
#include <winsock2.h>	// for server detection and name resolution
#include <shellapi.h>	// for shell execute
//#define INCL_WINSOCK_API_PROTOTYPES 0
#define WsCreate socket	// redefine stupid function names
#define WsDestroy closesocket
#define WsInitialize WSAStartup
#define WsConnect connect
#define WsGetHostByName gethostbyname
#define WsIoControl ioctlsocket
#define WsWait select
#define WsDisconnect shutdown
//#include <imm.h>

#ifdef UNICODE
#define T(string) L##string
#else
#define T(string) string
#endif

enum { false, true};

// restore what WINNT.H for some reason deffed out
/*#undef RtlMoveMemory
WINBASEAPI
HANDLE
WINAPI
RtlMoveMemory (
   VOID UNALIGNED *Destination,
   CONST VOID UNALIGNED *Source,
   SIZE_T Length
   );
*/

/*WINSOCK_API_LINKAGE //redefine function with more sensible parameter
LPTSTR
WSAAPI
inet_ntoa(
	unsigned int in_addr
	);*/

// Simply copied this snippet from SHLOBJ.H since it is all I need.
// format of CF_HDROP and CF_PRINTERS, in the HDROP case the data that follows
// is a double null terinated list of file names, for printers they are printer
// friendly names
//
typedef struct _DROPFILES {
   DWORD pFiles;                       // offset of file list
   POINT pt;                           // drop point (client coords)
   BOOL fNC;                           // is it on NonClient area
                                       // and pt is in screen coords
   BOOL fWide;                         // WIDE character switch
} DROPFILES, FAR * LPDROPFILES;

////////////////////////////////////////////////////////////////////////////////
// Generic program defs

typedef struct
{
	HWND hwnd;
	UINT id;
	wchar_t *className;
	wchar_t *caption;
	int x,y,width,height;
	UINT style;
	UINT styleEx;
	LPVOID param;
} ChildWindowStruct;

#define ProgMemBase (HINSTANCE)0x400000

////////////////////////////////////////////////////////////////////////////////
// Lan List defs

#include "filelist.h"

#define LanAtrsMax       100000 //hopefully network won't be larger than this
#define LanTreeMax       100000
#define LanFindsMax       10000	//should not show too many finds
#define LanFavsMax          100 //any more and you have too many 'favorite' locations
#define LanQueueMax         100 //even this amount is excessive
#define LanListFolderLimit 8192 //files per folder allowed
#define LanNamesMax     1048576 //up to two megabytes just for filenames (Unicode)

#define WM_REFRESHLIST 0x403

////////////////////////////////////////////////////////////////////////////////
// Attribute list defs

#include "..\win\AtrbList\atrblist.h"

////////////////////////////////////////////////////////////////////////////////
// Resize bar defs

#include "rsizebar.h"

////////////////////////////////////////////////////////////////////////////////
// Toolbar image list defs

typedef enum
{
	TbiNone,
	TbiBlank,
	TbiGotoBackward,
	TbiGotoForward,
	TbiGotoPrevious,
	TbiGotoNext,
	TbiGotoOut,
	TbiGotoIn,
	TbiGotoRoot,
	TbiStart,
	TbiRefresh,
	TbiStop,
	TbiClear,
	TbiViewFinds,
	TbiFileCopy,
	TbiFileQueue,
	TbiFileAddFav,
	TbiEditRemove,
	TbiEditCopy,
	TbiEditPaste,
	TbiFileDelete,
	TbiViewOptions,
	TbiViewFavs,
	TbiViewQueue,
	TbiViewProps,
	TbiTipPointer,
	TbiEditUndo,
	TbiEditRedo,
	TbiViewHistory,
	TbiViewFilters,
	TbiOrderNameA,
	TbiOrderSizeA,
	TbiOrderDateA,
	TbiOrderNameD,
	TbiOrderSizeD,
	TbiOrderDateD,
	TbiViewScan
};
