/**
File: dockframe.h
Since: 2005-11-30
Remark: Dockable frame class.
*/

#if !defined(_WINDOWS_) && !defined(_WINDOWS_H)
#error "Include 'windows.h' before including this file, not after."
#endif

typedef struct DockFrameInfo {
	uint flags;
	HWND hwnd;
	LRESULT (__stdcall *dialogFunc)(HWND, UINT, WPARAM, LPARAM);
	enum {
		flagDialogFunc=1,
	};
} DockFrameInfo;


WNDCLASSEX* DockFrame_GetWndClass();
LRESULT CALLBACK DockFrame_WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
HWND DockFrame_Create(HWND parent, LPTSTR title, DWORD style, DWORD styleEx, int x,int y, int width,int height, int id, LRESULT (__stdcall *dialogFunc)(HWND, UINT, WPARAM, LPARAM) );

#define DockFrameClass T("PknDockFrameClass")
//T("PknDockFrameClass")

#define DockFrameStylePopup (WS_POPUP|WS_CLIPCHILDREN|WS_CLIPSIBLINGS|WS_SYSMENU|WS_CAPTION|WS_THICKFRAME)
#define DockFrameStyleExPopup (WS_EX_TOOLWINDOW|WS_EX_WINDOWEDGE)
#define DockFrameStyleChild (WS_CHILD|WS_CLIPCHILDREN|WS_CLIPSIBLINGS|WS_SYSMENU|WS_CAPTION|WS_THICKFRAME|WS_GROUP|WS_TABSTOP)
#define DockFrameStyleExChild (WS_EX_TOOLWINDOW|WS_EX_WINDOWEDGE|WS_EX_CONTROLPARENT)

enum {DockFrame_AlignmentMinDistance=20};
