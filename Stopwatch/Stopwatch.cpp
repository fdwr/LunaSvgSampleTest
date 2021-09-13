/**
program: StopWatch
author: Dwayne Robinson
date: 2006-07-20
description: Main program with start/stop functions.
*/

#include "stdafx.h"
#include "resource.h"

#include "largecalendar.h"
#include <stdlib.h>

BOOL CALLBACK DialogProc(HWND hwnd,	UINT uMsg, WPARAM wParam, LPARAM lParam);
void StartTimer();
void StopTimer();
void ResetTimer();
void __stdcall IncrementTimer(HWND hwnd, UINT uMsg, UINT idEvent, DWORD dwTime);
void ResizedDialog(HWND hwnd);

////////////////////

int RealWorldSeconds = 0;

// These vars set an upper limit on how long to run
// the timer. For example, if you want to run it
// for 3 weeks and 2 days, you set WeeksLimit and
// DaysLimit, leaving the others zeroed.
int CounterLimitMonths = 0;
int CounterLimitWeeks = 0;
int CounterLimitDays = 0;
int CounterLimitHours = 0;
int CounterLimitTotalHours = 0; // do not set directly, total hour limit = months+weeks+days+hours

int CounterWrapDays = 5; /// days per week
int CounterWrapHours = 8; /// hours per day

float MinutesPerDay = 0; // number of real world minutes to elapse a virtual day
int   DaysPrevious = 0; // keeps track of day changes for beeps or calendar updates

const int SecondsPerTick = 1;

HWND MainWindow;

////////////////////


int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	LargeCalendar::registerClass();
	DialogBox(GetModuleHandle(NULL), (LPTSTR)IddMain, NULL, &DialogProc);

	return 0;
}


BOOL CALLBACK DialogProc(
    HWND hwnd,	// handle to dialog box
    UINT uMsg,	// message
    WPARAM wParam,	// first message parameter
    LPARAM lParam 	// second message parameter
   )
{
	switch (uMsg) {
	case WM_INITDIALOG:
		{
		/*
		SetDlgItemText(hwnd, IdcAboutText,
			T("StopWatch v1.0\r\n")
			T("Copyright (c) 2006-07-20\r\n")
			T("Dwayne Robinson\r\n")
			T("http://oregonstate.edu/~robinsfr\r\n\r\n")
			);
			*/
		MainWindow = hwnd;
		ResetTimer();
		SetDlgItemInt(MainWindow, IdcMinutesPerDay, 4, false);
		SetDlgItemInt(MainWindow, IdcCounterLimitWeeks, 4, false);
		SetDlgItemInt(MainWindow, IdcWrapDays, 6, false);
		SetDlgItemInt(MainWindow, IdcWrapHours, 8, false);

		LOGFONT lf = {
			50, //LONG lfHeight; 
			0, //LONG lfWidth; 
			0, //LONG lfEscapement; 
			0, //LONG lfOrientation; 
			FW_BOLD, //LONG lfWeight; 
			false, //BYTE lfItalic; 
			false, //BYTE lfUnderline; 
			false, //BYTE lfStrikeOut; 
			DEFAULT_CHARSET, //BYTE lfCharSet; 
			OUT_DEFAULT_PRECIS, //BYTE lfOutPrecision; 
			CLIP_DEFAULT_PRECIS, //BYTE lfClipPrecision; 
			DEFAULT_QUALITY, //BYTE lfQuality; 
			DEFAULT_PITCH|FF_SWISS, //BYTE lfPitchAndFamily; 
			T("") //TCHAR lfFaceName[LF_FACESIZE]; 
		};
		HFONT hf = CreateFontIndirect(&lf);
		SendDlgItemMessage(hwnd, IdcCalendar,     WM_SETFONT, (long)hf, false);
		SendDlgItemMessage(hwnd, IdcCounterLabel, WM_SETFONT, (long)hf, false);

		ShowWindow(hwnd, SW_MAXIMIZE);

		SetFocus(GetDlgItem(hwnd, IdcCounterLimitWeeks));

		DefWindowProc(hwnd, WM_SETICON, ICON_BIG, (LPARAM)LoadIcon(GetModuleHandle(NULL), (LPTSTR)1));
		
		return FALSE;
		}

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
			PostMessage(hwnd, WM_CLOSE, 0,0);
			return TRUE;
		}
		*/
		break;

	case WM_WINDOWPOSCHANGED:
		if (!(((LPWINDOWPOS)lParam)->flags & SWP_NOSIZE))
		{
			ResizedDialog(hwnd);
		}
		break;

	case WM_CLOSE:
		EndDialog(hwnd, 0);
		break;
	case WM_DESTROY:
		//AboutHwnd = null;
		break;
	}

	return FALSE;
}


void ResizedDialog(HWND hwnd)
{
	RECT clientRect;
	GetClientRect(hwnd, &clientRect);

	HWND hwItem = GetDlgItem(hwnd, IdcCalendar);
	int y = (80 * HIWORD(GetDialogBaseUnits()) ) / 8;
	SetWindowPos(hwItem, nullptr,
		8, y,
		clientRect.right-8*2, clientRect.bottom-y-8,
		SWP_NOZORDER);

	/*
	hwItem = GetDlgItem(hwnd, IdcCounterLabel);
	SetWindowPos(hwItem, nullptr,
		8, 130,
		clientRect.right-6*2, 40,
		SWP_NOZORDER);
	*/
}


void StartTimer()
{
	// get values from text boxes
	CounterLimitHours  = GetDlgItemInt(MainWindow, IdcCounterLimitHours,  0, false);
	CounterLimitDays   = GetDlgItemInt(MainWindow, IdcCounterLimitDays,   0, false);
	CounterLimitWeeks  = GetDlgItemInt(MainWindow, IdcCounterLimitWeeks,  0, false);
	CounterLimitMonths = GetDlgItemInt(MainWindow, IdcCounterLimitMonths, 0, false);

	CounterWrapDays    = GetDlgItemInt(MainWindow, IdcCounterWrapDays,    0, false);
	CounterWrapHours   = GetDlgItemInt(MainWindow, IdcCounterWrapHours,   0, false);
	int hoursPerWeek = CounterWrapDays * CounterWrapHours;
	
	{
		TCHAR text[30];
		GetDlgItemText(MainWindow, IdcMinutesPerDay, text, elmsof(text));
		MinutesPerDay = //GetDlgItemInt(MainWindow, IdcMinutesPerDay, 0, false);;
			float( atof( text ) );
	}

	CounterLimitTotalHours =
		CounterLimitMonths * int(31*CounterWrapHours/7) +
		CounterLimitWeeks  * hoursPerWeek +
		CounterLimitDays   * CounterWrapHours +
		CounterLimitHours;

	int weeks = CounterLimitWeeks;
	if (weeks < 5)
		weeks = 5;
	if (CounterLimitTotalHours > weeks * hoursPerWeek)
		weeks = (CounterLimitTotalHours+hoursPerWeek-1) / hoursPerWeek;

	LargeCalendar* lc = LargeCalendar::getReference(GetDlgItem(MainWindow, IdcCalendar));
	lc->weeks = weeks;
	lc->daysPerWorkWeek = CounterWrapDays;
	lc->reformat();

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
	SetDlgItemInt(MainWindow, IdcTotalMonths, 0, false);
	SetDlgItemInt(MainWindow, IdcTotalWeeks,  0, false);
	SetDlgItemInt(MainWindow, IdcTotalDays,   0, false);
	SetDlgItemInt(MainWindow, IdcTotalHours,  0, false);
	RealWorldSeconds = 0;
	DaysPrevious = 0;

	LargeCalendar* lc = LargeCalendar::getReference(GetDlgItem(MainWindow, IdcCalendar));
	lc->daySelected = 0;
	lc->reformat();

	SetDlgItemText(MainWindow, IdcCounterLabel, T(""));
}


void __stdcall IncrementTimer(
    HWND hwnd,	// handle of window for timer messages 
    UINT uMsg,	// WM_TIMER message
    UINT idEvent,	// timer identifier
    DWORD dwTime 	// current system time
   )
{
	RealWorldSeconds++;

	if (MinutesPerDay < 1/60.f) MinutesPerDay = 1/60.f;

	int hours = int( RealWorldSeconds * 8 / (MinutesPerDay * 60) );
	if (hours >= CounterLimitTotalHours) {
		hours  = CounterLimitTotalHours;
	}
	int days = hours / CounterWrapHours;
	int weeks = days / CounterWrapDays;
	int months = days / (31 * CounterWrapDays / 7);

	if (days != DaysPrevious) {
		DaysPrevious = days;

		LargeCalendar* lc = LargeCalendar::getReference(GetDlgItem(MainWindow, IdcCalendar));
		lc->selectNextWorkDay();

		MessageBeep(MB_OK);
	}

	SetDlgItemInt(MainWindow, IdcTotalHours, hours, false);
	SetDlgItemInt(MainWindow, IdcTotalDays, days, false);
	SetDlgItemInt(MainWindow, IdcTotalWeeks, weeks, false);
	SetDlgItemInt(MainWindow, IdcTotalMonths, months, false);

	SetDlgItemInt(MainWindow, IdcHours, hours % CounterWrapHours, false);
	SetDlgItemInt(MainWindow, IdcDays, days % CounterWrapDays, false);
	SetDlgItemInt(MainWindow, IdcWeeks, weeks % 4, false);
	SetDlgItemInt(MainWindow, IdcMonths, months, false);

	if (hours >= CounterLimitTotalHours) {
		MessageBeep(MB_ICONHAND);
		StopTimer();
		return;
	}

	{
		/*
		TCHAR text[80];
		wsprintf(text, "%d weeks, %d days, %d hours  -  %s", weeks, days, hours, (hours % 8 < 4) ? T("AM") : T("PM"));
		SetDlgItemText(MainWindow, IdcCounterLabel, text);
		*/
		SetDlgItemText(MainWindow, IdcCounterLabel, (hours % 8 < 4) ? T("AM") : T("PM"));
	}
}

