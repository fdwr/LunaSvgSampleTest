/**
File:	LargeCopy.cpp
Author:	Dwayne Robinson
Date:	20051018
Since:	20051018
Remark:	Main user interface for copier.
*/

#include "stdafx.h"
#include "LargeCopyClass.h"

#include <vector>

#include "resource.h"
#include "program.h"

typedef struct ConfirmActionList {
	TCHAR* message;
	TCHAR* actions;
} ConfirmActionList;

////////////////////////////////////////////////////////////////////////////////

BOOL CALLBACK MainDlgProc(HWND hwnd, UINT message, long wParam, long lParam);
BOOL CALLBACK ConfirmActionDlgProc(HWND hwnd, UINT message, long wParam, long lParam);

////////////////////////////////////////////////////////////////////////////////

HWND MainHwnd = NULL;

LargeCopyClass LargeCopy;

////////////////////////////////////////////////////////////////////////////////

int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	CoInitialize(null); // for silly shell

	MainHwnd = CreateDialog(GetModuleHandle(null), (LPTSTR)IddLargeCopy, null, (DLGPROC)(&MainDlgProc));
	ShowWindow( MainHwnd, SW_SHOW );
	//MessageBox(null, T("More later..."), T("Large Copy"), MB_OK);

	MSG msg;
	while(GetMessage(&msg, 0, 0,0)>0) {
		if (!IsDialogMessage(MainHwnd, &msg) ) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}

	return 0;
}




////////////////////////////////////////
void LargeCopyClass::getFileNames()
{
	fileNameList.clear(); // text of names
	fileNameIdxs.clear();

	HWND listHwnd = GetDlgItem(MainHwnd, IdcSourceFiles);
	TCHAR fileName[MAX_PATH];

	int index = 0;
	while (ListBox_GetText(listHwnd, index, fileName) != LB_ERR) {
		int size = fileNameList.size();
		fileNameList.resize( size + lstrlen(fileName)+1, 0);
		lstrcpy(&fileNameList[size], fileName);
		fileNameIdxs.push_back(size);
		index++;
	}
	//DragQueryFile(
	//fileNameList.pushBack();
	

}


////////////////////////////////////////
void LargeCopyClass::checkInput()
{
	// put peek'ed message loop here

	MSG msg;
	while (PeekMessage(&msg, null,0,0, PM_REMOVE)) {
		if (!IsDialogMessage(MainHwnd, &msg) ) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
		if (msg.message == WM_QUIT) PostQuitMessage(msg.wParam);
	}
	HWND fileProgressHwnd = GetDlgItem(MainHwnd, IdcFileProgress);
	ProgressBar_SetPos(fileProgressHwnd, filePos.valueLow);
}


////////////////////////////////////////
int LargeCopyClass::confirmAction(TCHAR* message, TCHAR* actions)
{
	ConfirmActionList cal;
	cal.message = message;
	cal.actions = actions;
	return DialogBoxParam(GetModuleHandle(null), (LPTSTR)IddConfirmAction, MainHwnd, (DLGPROC)(&ConfirmActionDlgProc), (long)&cal);
}


////////////////////////////////////////
void LargeCopyClass::fileCopyStarted()
{
	HWND sourceFilesHwnd = GetDlgItem(MainHwnd, IdcSourceFiles);
	ListBox_SetCurSel(sourceFilesHwnd, fileIndex);
	ListBox_SetTopIndex(sourceFilesHwnd, (fileIndex>1) ? fileIndex-1 : 0);
	HWND fileProgressHwnd = GetDlgItem(MainHwnd, IdcFileProgress);
	ProgressBar_SetRange(fileProgressHwnd, 0, fileSize.valueLow);
	ProgressBar_SetPos(fileProgressHwnd, 0);
}


////////////////////////////////////////
void LargeCopyClass::fileCopyStopped()
{
	// update list entry status
}


////////////////////////////////////////
BOOL CALLBACK MainDlgProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	switch (message) {
	case WM_INITDIALOG:
		{
			/*
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

			/--HRSRC hsrc;
			HGLOBAL hmem;
			short *pver;

			hsrc=FindResource(ProgMemBase, (LPTSTR)1, (LPTSTR)RT_VERSION);
			hmem=LoadResource(ProgMemBase, hsrc);
			pver=hmem; //pver=LockResource(hmem);
			debugwrite("hsrc=%d hmem=%d pver=%d", hsrc,hmem,pver);
			if (pver) {debugwrite("ver=%d %d %d", *(pver+88),*(pver+89),*(pver+90));}
			--/

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
			*/

			//SetDlgItemText(hwnd, IDC_ABOUT, TextAbout);
			Button_SetCheck(GetDlgItem(hwnd, IdcActionFirst+LargeCopy.duplicateAction), true);
			Button_SetCheck(GetDlgItem(hwnd, IdcFlush), true);
			{
				MEMORYSTATUS ms;
				GlobalMemoryStatus(&ms);
				//Edit_SetText(GetDlgItem(hwnd, IdcChunkSize), T("64"));
				int mem = ms.dwTotalPhys / (1048576*4); // 1/4 mem
				if (mem > 256) mem = 256; // limit to reasonable size
				SetDlgItemInt(hwnd, IdcChunkSize, mem, false);
			}

			DefWindowProc(hwnd, WM_SETICON, ICON_BIG, (long)LoadIcon(GetModuleHandle(null), (LPTSTR)1));
			break;
		}

	case WM_COMMAND:
		{
			switch (wParam)
			{
			case IdcActionResume: // these must be in the same order as the action enums
			case IdcActionReplace:
			case IdcActionSkip:
			case IdcActionPrompt:
				LargeCopy.duplicateAction = wParam - IdcActionFirst;
				break;

			case IdcDestPathBrowse:
				{
					#ifndef BIF_NEWDIALOGSTYLE
					#define BIF_NEWDIALOGSTYLE     0x0040
					// Use the new dialog layout with the ability to resize
                    // Caller needs to call OleInitialize() before using this API
					#endif

					BROWSEINFO bi = {
						MainHwnd, // HWND hwndOwner
						null, // LPCITEMIDLIST pidlRoot
						null, // LPSTR pszDisplayName
						T("Select the destination folder."), // LPCSTR lpszTitle
						BIF_RETURNONLYFSDIRS, // UINT ulFlags |BIF_NEWDIALOGSTYLE|BIF_EDITBOX
						// new dialog style stinks - initial focus is on the OK button!?!@#
						null, // BFFCALLBACK lpfn
						0, // LPARAM lParam
						0 // int iImage
					};

					LPITEMIDLIST pidl = SHBrowseForFolder ( &bi );
					// free retarded little PIDL
					if (pidl != null) {
						// get the name of the folder
						TCHAR path[MAX_PATH];
						if ( SHGetPathFromIDList( pidl, path ) )
						{
							Edit_SetText( GetDlgItem(hwnd, IdcDestPath), path);
						}

						// or CoTaskMemFree(pidl) ?
						IMalloc* imalloc = null;
						if ( SUCCEEDED( SHGetMalloc ( &imalloc )) )
						{
							imalloc->Free( pidl );
							imalloc->Release( );
						}
					}
				}
				break;

			case IdcFlush:
				LargeCopy.flush = Button_GetCheck(GetDlgItem(hwnd, IdcFlush));
				break;

			case IDOK:
				// begin copy
				if (LargeCopy.stillCopying) {
					MessageBeep(MB_ICONASTERISK);
				} else {
					// verify target path
					TCHAR fileName[MAX_PATH];
					HWND destPathHwnd = GetDlgItem(hwnd, IdcDestPath);
					Edit_GetText(destPathHwnd, fileName, elmsof(fileName));
					if (lstrlen(fileName) <= 0) {
						MessageBox(hwnd,
							T("The destination path is empty. The files must go SOMEwhere. Either type the path, browse for one, or drop the target folder onto the text field."),
							ProgramName,
							MB_OK|MB_ICONWARNING);
						SetFocus(destPathHwnd);
						break;
					}
					// validate chunk size
					HWND chunkSizeHwnd = GetDlgItem(hwnd, IdcChunkSize);
					LargeCopy.chunkSize = GetDlgItemInt(hwnd, IdcChunkSize, null, false) * 1048576;
					if (LargeCopy.chunkSize < 1048576) {
						MessageBox(hwnd,
							T("The chunk size must be a positive integer of at least 1 Megabyte."),
							ProgramName,
							MB_OK|MB_ICONWARNING);
						SetWindowText(chunkSizeHwnd, T("1"));
						SetFocus(chunkSizeHwnd);
						break;
					}

					// copy files from list box to internal list
					LargeCopy.getFileNames();

					// start the copy process
					HWND okHwnd = GetDlgItem(hwnd, IDOK);
					Button_Enable(okHwnd, false);

					LargeCopy.startCopy(fileName);

					Button_Enable(okHwnd, true);
					HWND fileProgressHwnd = GetDlgItem(MainHwnd, IdcFileProgress);
					ProgressBar_SetRange(fileProgressHwnd, 0, 0);
				}
				break;
			case IDRETRY:
				// clear source files list
				ListBox_ResetContent(GetDlgItem(hwnd, IdcSourceFiles));
				break;
			case IDCANCEL:
				if (LargeCopy.stillCopying) {
					LargeCopy.stillCopying = false;
					break;
				}
			case IDCLOSE:
				// end program
				//DestroyWindow(hwnd);
				EndDialog(hwnd, 0);
				PostQuitMessage(0);
				break;

			case IdcAbout:
				MessageBox(hwnd,
					ProgramName T(" ") ProgramVersionString T("\r\n")
					ProgramDateString T("\r\n")
					ProgramAuthor T("\r\n\r\n")
					T("Copies really large files. Reduces hard drive thrashing by using much large buffers than standard system. ")
					T("Less thrashing means happier, healthier hard drives. ")
					T("It can also resume file transfers, which is very useful for copying large files from remote sources or ")
					T("continuing several files (rather than dismissing dozens of irritating confirmation messages)."),
					T("About ") ProgramName, MB_OK|MB_ICONINFORMATION);
				break;
			case IdcWebpage:
				ShellExecute(hwnd,null, ProgramWebpage, null,null,SW_SHOWMAXIMIZED);
				break;
			}
		}
		break;

	case WM_DROPFILES:
		{
			TCHAR fileName[MAX_PATH];
			HDROP hdrop = (HDROP)wParam;
			POINT point;

			// determine what the files were dropped onto
			DragQueryPoint(hdrop, &point);
			HWND droppedHwnd = ChildWindowFromPoint(hwnd, point);
			if (droppedHwnd == NULL) break;

			switch (GetWindowID(droppedHwnd)) {
			case IdcSourceFiles:
				// add dropped files to list
				{
					int index = 0;
					bool addedFolder = false;
					while (DragQueryFile(hdrop, index++, fileName, elmsof(fileName) ) > 0) {
						//ListBox_AddString(GetDlgItem(hwnd, IdcSourceFiles), fileName);
						if (GetFileAttributes(fileName) & FILE_ATTRIBUTE_DIRECTORY) {
							addedFolder = true;
						} else {
							ListBox_AddString(droppedHwnd, fileName);
						}
					}
					if (addedFolder) {
						MessageBox(hwnd, T("Sorry, one of the objects dropped was a folder, and only files can be copied for now (not entire folders)."), ProgramName, MB_OK|MB_ICONWARNING|MB_SETFOREGROUND);
					}
				}
				break;
			case IdcDestPath:
				// add dropped folder to target path
				{
					if (DragQueryFile(hdrop, 0, fileName, elmsof(fileName) ) <= 0) break;

					//Edit_SetText(GetDlgItem(hwnd, IdcDestPath), fileName);
					if (GetFileAttributes(fileName) & FILE_ATTRIBUTE_DIRECTORY) {
						Edit_SetText(droppedHwnd, fileName);
					} else {
						MessageBox(hwnd, T("Only folders can be dropped here, not files or other objects."), ProgramName, MB_OK|MB_ICONWARNING|MB_SETFOREGROUND);
					}
					break;
				}
			default:
				MessageBox(hwnd, T("You can drop files to be copied onto the list, or drop the destination folder onto the text field."), ProgramName, MB_OK|MB_ICONINFORMATION|MB_SETFOREGROUND);
				break;
			}
		}
		break;
	//case WM_DESTROY:
	//	InfoHwnd=0;
	}
	return false;
}


////////////////////////////////////////
BOOL CALLBACK ConfirmActionDlgProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	switch (message) {
	case WM_INITDIALOG:
		{
			// set message
			ConfirmActionList* cal = (ConfirmActionList*)lParam;
			Edit_SetText(GetDlgItem(hwnd, IdcMessage), cal->message);

			// set action buttons
			TCHAR* actions = cal->actions;
			for (int index = 0; index < 4; index++) {
				int size = lstrlen(actions);
				if (size <= 0) break;
				HWND actionHwnd = GetDlgItem(hwnd, IdcAction0+index);
				Button_SetText(actionHwnd, actions);
				ShowWindow(actionHwnd, SW_SHOW);
				actions += size+1;
			}
		}
		break;
	case WM_COMMAND:
		{
			switch (wParam)
			{
			case IdcAction0:
			case IdcAction0+1:
			case IdcAction0+2:
			case IdcAction0+3:
				// end program
				//DestroyWindow(hwnd);
				EndDialog(hwnd, wParam-IdcAction0);
				break;
			case IDCLOSE:
			case IDCANCEL:
				return EndDialog(hwnd, -1);
			}
		}
		break;
	}

	return false;
}
