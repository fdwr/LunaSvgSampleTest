// Factors.cpp : Lists factors of a given number
// 2004-02-03

#include "stdafx.h"
#include "resource.h"


BOOL CALLBACK DialogProc(HWND hwnd, UINT message, long wParam, long lParam);


int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	DialogBox(ProgMemBase, (LPSTR)IDD_FACTORS, NULL, (DLGPROC)DialogProc);
	return 0;
}



BOOL CALLBACK DialogProc(HWND hwnd, UINT message, long wParam, long lParam) 
{
	int count;
	int quotient;
	char string[256];
	switch (message)
	{
	case WM_INITDIALOG:
		DefWindowProc(hwnd, WM_SETICON, true, (LPARAM)LoadIcon(ProgMemBase, (LPTSTR)1));
		return true;
	case WM_COMMAND:
		switch (wParam)
		{
		case IDOK:
			SendDlgItemMessage(hwnd, IDC_QUOTIENT, EM_SETSEL, 0,-1);

			// <<real code is here>>
			quotient = GetDlgItemInt(hwnd, IDC_QUOTIENT, NULL, FALSE);
			SendDlgItemMessage(hwnd,
				IDC_FACTORS,
				LB_RESETCONTENT,
				0,0);
			for (count=quotient>>1; count>=2; count--) {
				if (quotient % count == 0)
				{
					// add item to list
					wsprintf(string, "%d", quotient / count);
					SendDlgItemMessage(hwnd,
						IDC_FACTORS,
						LB_ADDSTRING,
						0, (long)(LPSTR)string);
				}			
			}
			break;
		case IDCLOSE:
		case IDCANCEL:
			EndDialog(hwnd,0);
			break;
		}
		break;
	default:
		return false;
	}
	return true;
}
