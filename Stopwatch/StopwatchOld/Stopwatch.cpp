// Stopwatch.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "resource.h"

BOOL CALLBACK DialogProc(HWND hDlg,	UINT uMsg, WPARAM wParam, LPARAM lParam);
void StartTimer();
void StopTimer();
void ResetTimer();
void __stdcall IncrementTimer(HWND hwnd, UINT uMsg, UINT idEvent, DWORD dwTime);


int RealWorldSeconds = 0;
int HoursLimit = 8;
int DaysLimit = 5;
int WeeksLimit = 4;
int MonthsLimit = 0;
int MinutesPerDay = 0;
int DaysPrevious = 0;

const int SecondsPerTick = 1;

HWND MainWindow;


int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
 	// TODO: Place code here.
	DialogBox(GetModuleHandle(NULL), (LPTSTR)IddMain, NULL, &DialogProc);


	return 0;
}


BOOL CALLBACK DialogProc(
    HWND hDlg,	// handle to dialog box
    UINT uMsg,	// message
    WPARAM wParam,	// first message parameter
    LPARAM lParam 	// second message parameter
   )
{
	switch (uMsg) {
	case WM_INITDIALOG:
		/*
		SetDlgItemText(hdlg, IdcAboutText,
			T("Fractured v1.0\r\n")
			T("Copyright (c) 2005-11-30\r\n")
			T("Dwayne Robinson\r\n")
			T("http://oregonstate.edu/~robinsfr\r\n\r\n")
			T("Multiple layers of fractal images\r\n")
			T("to make pretty pictures for my\r\n")
			T("term project in CS535.")
			);
			*/
		MainWindow = hDlg;
		ResetTimer();
		SetDlgItemInt(MainWindow, IdcMinutesPerDay, 4, false);
		SetDlgItemInt(MainWindow, IdcMonthsLimit, 1, false);
		return TRUE;

	case WM_ACTIVATE:
		break;
	case WM_COMMAND:
		switch (wParam) {
		case IDOK:
			StartTimer();
			break;
		case IDCANCEL:
			StopTimer();
			break;
		case IDRESET:
			ResetTimer();
			break;
		}
		/*
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) 
		{
			PostMessage(hdlg, WM_CLOSE, 0,0);
			return TRUE;
		}
		*/
		break;
	case WM_CLOSE:
		EndDialog(hDlg, 0);
		break;
	case WM_DESTROY:
		//AboutHwnd = null;
		break;
	}

	return FALSE;
}


void StartTimer()
{
	HoursLimit = GetDlgItemInt(MainWindow, IdcHoursLimit, 0, false);
	DaysLimit = GetDlgItemInt(MainWindow, IdcDaysLimit, 0, false);
	WeeksLimit = GetDlgItemInt(MainWindow, IdcWeeksLimit, 0, false);
	MonthsLimit = GetDlgItemInt(MainWindow, IdcMonthsLimit, 0, false);
	MinutesPerDay = GetDlgItemInt(MainWindow, IdcHoursPerDay, 0, false);;

	HoursLimit = MonthsLimit*22*8 + WeeksLimit*5*8 + DaysLimit*8 + HoursLimit;

	SetTimer(MainWindow, 1234, SecondsPerTick*1000, &IncrementTimer);
}


void StopTimer()
{
	KillTimer(MainWindow, 1234);
}


void ResetTimer()
{
	KillTimer(MainWindow, 1234);

	SetDlgItemInt(MainWindow, IdcMonths, 0, false);
	SetDlgItemInt(MainWindow, IdcWeeks,  0, false);
	SetDlgItemInt(MainWindow, IdcDays,   0, false);
	SetDlgItemInt(MainWindow, IdcHours,  0, false);
	SetDlgItemInt(MainWindow, IdcMonthsTotal, 0, false);
	SetDlgItemInt(MainWindow, IdcWeeksTotal,  0, false);
	SetDlgItemInt(MainWindow, IdcDaysTotal,   0, false);
	SetDlgItemInt(MainWindow, IdcHoursTotal,  0, false);
	RealWorldSeconds = 0;
	DaysPrevious = 0;
}


void __stdcall IncrementTimer(
    HWND hwnd,	// handle of window for timer messages 
    UINT uMsg,	// WM_TIMER message
    UINT idEvent,	// timer identifier
    DWORD dwTime 	// current system time
   )
{
	int Hours = 0;
	int Days = 0;
	int Weeks = 0;
	int Months = 0;

	RealWorldSeconds++;

	Hours = RealWorldSeconds * 8 / (MinutesPerDay * 60);
	Days = Hours / 8;
	Weeks = Days / 5;
	Months = Days / 22;

	if (Hours >= HoursLimit) {
		MessageBeep(MB_ICONHAND);
		StopTimer();
		return;
	}
	if (Days != DaysPrevious) {
		DaysPrevious = Days;
		MessageBeep(MB_OK);
	}
	
	SetDlgItemInt(MainWindow, IdcHoursTotal, Hours, false);
	SetDlgItemInt(MainWindow, IdcDaysTotal, Days, false);
	SetDlgItemInt(MainWindow, IdcWeeksTotal, Weeks, false);
	SetDlgItemInt(MainWindow, IdcMonthsTotal, Months, false);

	SetDlgItemInt(MainWindow, IdcHours, Hours % 8, false);
	SetDlgItemInt(MainWindow, IdcDays, Days % 5, false);
	SetDlgItemInt(MainWindow, IdcWeeks, Weeks % 4, false);
	SetDlgItemInt(MainWindow, IdcMonths, Months, false);
}

