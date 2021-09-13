/*//////////////////////////////////////////////////////////////////////////////
fservew.c - Windows graphical interface.

Dwayne Robinson
CS372 - PROG1
2004-04-20

This is just the interface. All the real server code is in pknft.c.

Todo:
	Writing to generic handles, including devices and pipes
	Writing directly to memory for speed or temporary objects
	Multiple streams for multiplexing video and audio
	Callbacks or event triggers for each stream.
	Thinking of merging local and remote requests
*/

#include "stdafx.h"
#include "pknft.h"

enum {false, true};

extern HANDLE FservePin[2];

HICON FileIcon, FolderIcon;

HWND MainHwnd, FilesHwnd, AboutHwnd;

////////////////////////////////////////////////////////////////////////////////
// Enter main...
int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	InitCommonControls();
	PknftInit();
	LoadLibrary("RichEd20.dll");
	InitCommonControls();
	DialogBox(ProgMemBase, (LPSTR)IddMain, NULL, (DLGPROC)IddMainProc);
	PknftFree();

	return 0;
}

////////////////////////////////////////////////////////////////////////////////
// Main dialog callback
BOOL CALLBACK IddMainProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	char text[256];

	switch (message)
	{
	case WM_INITDIALOG:
		MainHwnd = hwnd;
		PknftSetVar(PknftSetHwnd, (int)hwnd); // want notifications
		DefWindowProc(hwnd, WM_SETICON, true, (LPARAM)LoadIcon(ProgMemBase, (LPTSTR)1));
		SetDlgItemText(hwnd,IdcAddress, "127.0.0.1");
		//SetDlgItemText(hwnd,IdcAddress, "128.193.54.5");
		//SetDlgItemText(hwnd,IdcAddress, "flip.engr.orst.edu");
		SetDlgItemText(hwnd,IdcPort, "1359");
		SetDlgItemText(hwnd,IdcLocalPath, "pknft.c");
		ShowWindow(hwnd, SW_SHOW);
		//FillFileList();
		// load other icons
		//FileIcon = LoadIcon(ProgMemBase, (LPTSTR)1);
		//SetCurrentDirectory("Z:/cs372/FtServe");
		CheckRadioButton(MainHwnd, IdcConnect, IdcDisconnect, IdcDisconnect);
		//SendDlgItemMessage(MainHwnd, IdcDisconnect, BM_SETCHECK, 1, 0);
		StatusLogAppend("PknFt ready");
		return true;
	case WM_COMMAND:
		switch (wParam)
		{
		case IDCANCEL:
		case IDCLOSE:
			EndDialog(hwnd,0);
			break;
		case IDOK:
			if (GetFocus() == GetDlgItem(hwnd, IdcMsg)) {
		case IdcSend:
				GetWindowText(GetDlgItem(hwnd, IdcMsg),text,sizeof(text)); //dbg
				SendDlgItemMessage(hwnd, IdcMsg, EM_SETSEL, 0,-1);
				PknftCommandStr(PknftCmdChat, text);
				SetFocus(GetDlgItem(hwnd, IdcMsg));
			}
			else {
		case IdcConnect:
				CheckRadioButton(MainHwnd, IdcConnect, IdcDisconnect, IdcConnect);
				PknftSetVar(PknftSetPort, GetDlgItemInt(hwnd,IdcPort, NULL,false) );
				PknftSetVar(PknftSetUser, GetDlgItemInt(hwnd,IdcUser, NULL,false) );
				PknftSetVar(PknftSetPass, GetDlgItemInt(hwnd,IdcPass, NULL,false) );
				GetDlgItemText(hwnd,IdcAddress, text,sizeof(text));
				PknftCommandStr(PknftCmdConnect, text);
			}
			break;
		case IdcListen:
			CheckRadioButton(MainHwnd, IdcConnect, IdcDisconnect, IdcListen);
			PknftCommandStr(PknftCmdListen, NULL);
			break;
		case IdcDisconnect:
			CheckRadioButton(MainHwnd, IdcConnect, IdcDisconnect, IdcDisconnect);
			PknftCommandStr(PknftCmdDisconnect, NULL);
			break;
		case IdcPut:
		{
			static OPENFILENAME ofn = {
				sizeof(OPENFILENAME), //lStructSize;
				NULL, //hwndOwner;
				ProgMemBase, //hInstance;
				"All files\0*.*\0\0", //lpstrFilter;
				NULL, //lpstrCustomFilter;
				0, //nMaxCustFilter;
				1, //nFilterIndex;
				NULL, //lpstrFile;
				MAX_PATH, //nMaxFile;
				NULL,//lpstrFileTitle;
				0, //nMaxFileTitle;
				NULL, //lpstrInitialDir;
				"Put file", //lpstrTitle;
				OFN_EXPLORER|OFN_FILEMUSTEXIST|OFN_HIDEREADONLY|OFN_PATHMUSTEXIST, //Flags;
				0, //nFileOffset; 
				0, //nFileExtension;
				NULL, //lpstrDefExt;
				0, //lCustData;
				NULL, //lpfnHook;
				NULL //lpTemplateName;
			};
			char filename[MAX_PATH];
			ofn.hwndOwner = hwnd;
			ofn.lpstrFile = filename;
			filename[0] = '\0';
			if (GetOpenFileName(&ofn)) {
				PknftCommandStr(PknftCmdPut, ofn.lpstrFile);
			}
			break;
		}
		case IdcGet:
			//GetDlgItemText(hwnd,IdcRemotePath ,text,sizeof(text));
			//PknftCommandStr(PknftCmdGet, text);
			break;
		case IdcExit:
			PostQuitMessage(0);
			break;
		case IdcAbout:
			DialogBox(ProgMemBase, (LPSTR)IddAbout, hwnd, (DLGPROC)IddAboutProc);
			break;
		case IdcFiles:
			if (FilesHwnd)
				SendMessage(FilesHwnd,WM_CLOSE,0,0);
			else
				CreateDialog(ProgMemBase, (LPSTR)IddFiles, hwnd, (DLGPROC)IddFilesProc);
			break;
		//MessageBeep(MB_OK);
		case IdmHelpReadme:
			ShellExecute(hwnd, "open", "_readme.txt", NULL, NULL, SW_SHOW);
			break;
		}
		break;
	case WM_USER+13: // really should use the message returned by RegisterMessage
		switch (wParam) {
		case PknftCmdStatus:
		{
			char status[1024];
			lstrcpy(status, "\r\n"); // prepend CR/LF
			lstrcpyn(status+2, (LPSTR)lParam, sizeof(status)-2);
			StatusLogAppend(status);
			break;
		}
		}
		break;

	case WM_DRAWITEM:
	{
		LPDRAWITEMSTRUCT lpdis = (LPDRAWITEMSTRUCT)lParam;
		HWND ctl = lpdis->hwndItem;
		int len;
		char text[MAX_PATH];
		SHFILEINFO shinfo;
		HIMAGELIST himl;

		switch (wParam) {
		//case IdcRemoteFiles:
		case IdcLocalFiles:
		{
			if ((unsigned)SendMessage(ctl, LB_GETTEXTLEN, lpdis->itemID, 0) < MAX_PATH) {
				len = SendMessage(ctl, LB_GETTEXT, lpdis->itemID, (LPARAM)text);
				//SHELLAPI DWORD WINAPI SHGetFileInfo(text, 0, &shinfo, sizeof(shinfo),SHGFI_SYSICONINDEX|SHGFI_SMALLICON); 
				//himl = (HIMAGELIST)SHGetFileInfo(text, 0, &shinfo,sizeof(shinfo), SHGFI_SYSICONINDEX | SHGFI_SMALLICON);
				//ImageList_Draw(himl, shinfo.iIcon, lpdis->hDC,lpdis->rcItem.left+1,lpdis->rcItem.top+1, ILD_NORMAL);
				//DrawIconEx(lpdis->hDC,lpdis->rcItem.left+1,lpdis->rcItem.top+1, FileIcon, 16,16, 0,NULL, DI_NORMAL);
				TextOut(lpdis->hDC, lpdis->rcItem.left+20, lpdis->rcItem.top+1, text, len);
			}
		}
		} // end select
	}
	default:
		return false;
	}
	return true;
}

////////////////////////////////////////////////////////////////////////////////
// About dialog callback
BOOL CALLBACK IddAboutProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	switch (message)
	{
	case WM_INITDIALOG:
		AboutHwnd = hwnd;
		SetDlgItemText(hwnd, IdcMsg, "PknFt Server " PknFtVersion "\r\nDwayne Robinson (c)2004\r\nWindows version");
		return true;
	case WM_COMMAND:
		switch (wParam)
		{
		case IDOK:
		case IDCANCEL:
		case IDCLOSE:
			AboutHwnd = 0;
			EndDialog(hwnd,0);
			break;
		}
	case WM_ACTIVATE:
		if (LOWORD(wParam) == WA_INACTIVE)
			PostMessage(hwnd, WM_CLOSE, 0,0);
	}
	return false;
}

////////////////////////////////////////////////////////////////////////////////
// File dialog callback
BOOL CALLBACK IddFilesProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	switch (message)
	{
	case WM_INITDIALOG:
		SendDlgItemMessage(MainHwnd, IdcFiles, BM_SETCHECK, 1, 0);
		FilesHwnd = hwnd;
		return true;
	case WM_COMMAND:
		switch (wParam)
		{
		case IDOK:
		case IDCANCEL:
		case IDCLOSE:
			FilesHwnd = 0;
			SendDlgItemMessage(MainHwnd, IdcFiles, BM_SETCHECK, 0, 0);
			EndDialog(hwnd,0);
			break;
		case IdcPut:
			if (IsWindowEnabled(MainHwnd))
				PostMessage(MainHwnd, message, IdcPut, lParam);
			return true;
		}
	}
	return false;
}

////////////////////////////////////////////////////////////////////////////////
// Clears the log.
//
// accepts:	none
// returns:	none
void StatusLogClear()
{
	SetDlgItemText(MainHwnd, IdcLog, "");
}

////////////////////////////////////////////////////////////////////////////////
// Appends a text string to the log.
//
// accepts:	text - string to add
// returns:	none
void StatusLogAppend(char* text)
{
	HWND edit = GetDlgItem(MainHwnd, IdcLog);

	/* set color according to relevance
	CHARFORMAT2 recf;
	recf.cbSize = sizeof(recf);
	recf.dwMask = CFM_COLOR;
	recf.crTextColor = 0xFF0000;
	recf.dwEffects=0;
	SendMessage(edit, EM_SETCHARFORMAT, SCF_SELECTION, (long)&recf);
	*/

	// append text
	SendMessage(edit, EM_SETSEL, 32767, 32767);
	SendMessage(edit, EM_REPLACESEL, FALSE, (long)text);

	// scroll into view
	//SendMessage(edit, EM_LINESCROLL, 0, 32767);
	//SendMessage(edit, EM_SCROLLCARET, 0, 0); // does not work right with rich edit
	SendMessage(edit, EM_SCROLL, SB_PAGEDOWN, 0);

	UpdateWindow(MainHwnd);
}

////////////////////////////////////////////////////////////////////////////////
// Fills the local list box with filenames.
//
// accepts:	none
// returns:	none
void FillFileList() {
	HANDLE FindHandle;
	HWND List = GetDlgItem(MainHwnd, IdcLocalFiles);
	WIN32_FIND_DATA FindData;

	FindHandle = FindFirstFile("*", &FindData);
	if (FindHandle == INVALID_HANDLE_VALUE) return;
	do {
		SendMessage(List, LB_ADDSTRING, 0, (LPARAM)&FindData.cFileName);
	} while (FindNextFile(FindHandle, &FindData));

	FindClose(FindHandle);
}
