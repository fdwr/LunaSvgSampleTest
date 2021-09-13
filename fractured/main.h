/**
File: main.h
Since: 2005-11-30
*/

#include "resource.h"

#define MainWindowClass T("FracturedClass")
#define MainWindowTitle T("Fractured v1.0 / Dwayne Robinson / 2005-11-30")
#define MdiWindowClass T("FracturedMdiClass")

typedef struct ChildWindowStruct
{
	HWND hwnd;
	UINT id;
	TCHAR *className;
	TCHAR *caption;
	int x,y,width,height;
	UINT style;
	UINT styleEx;
	LPVOID param;
} ChildWindowStruct;
