/**
program: StopWatch
author: Dwayne Robinson
date: 2006-07-20
description: Simple, large calendar display.
*/

#include "stdafx.h"
#include "tchar.h"

#define largecalendar_cpp
#include "largecalendar.h"

////////////////////////////////////////////////////////////////////////////////

static LRESULT __stdcall LargeCalendarWndProc(HWND hwnd, UINT message, long wParam, long lParam);

////////////////////////////////////////////////////////////////////////////////

TCHAR LargeCalendar::className[] = T("LargeCalendar");

WNDCLASS LargeCalendar::windowClass = {
	CS_OWNDC|CS_DBLCLKS|CS_HREDRAW|CS_VREDRAW, //style
	(WNDPROC)&LargeCalendarWndProc, //lpfnWndProc
	0, //cbClsExtra
	0, //cbWndExtra
	0, //hInstance
	0, //hIcon
	0, //hCursor
	0, //hbrBackground
	0, //lpszMenuName
	className //lpszClassName
};

const int MonthsPerYear = 12;
const int DaysPerWeek = 7;

////////////////////////////////////////////////////////////////////////////////

ATOM LargeCalendar::registerClass()
{
	windowClass.hInstance = GetModuleHandle(NULL);
	windowClass.hCursor = LoadCursor(0,IDC_ARROW);
	windowClass.hbrBackground = (int)GetStockObject(NULL_BRUSH);
	return RegisterClass(&windowClass);
}


LargeCalendar::LargeCalendar() :
	daySelected(0),
	dayPaid(5),
	daysPerWorkWeek(5),
	weeks(5),
	startingMonth(1),
	startingDay(1),
	startingDayOfWeek(1),
	topHeaderHeight(60),
	leftHeaderWidth(180)
{
}


LargeCalendar* LargeCalendar::getReference(HWND hwnd)
{
	return (LargeCalendar*)GetWindowLong(hwnd, GWL_USERDATA);
}


static LRESULT __stdcall LargeCalendarWndProc(
	HWND hwnd,
	UINT message,
	long wParam,
	long lParam)
{
	LargeCalendar* lcp = (LargeCalendar*)GetWindowLong(hwnd, GWL_USERDATA);
	return lcp->wndProc(hwnd, message, wParam, lParam);
}


LRESULT LargeCalendar::wndProc(
	HWND hwnd,
	UINT message,
	long wParam,
	long lParam)
{
	//debugwrite("al  msg=%X wParam=%X lparam=%X", message, wParam, lParam);

	switch (message) {
	case WM_CREATE:
		{
		LargeCalendar* lcp = new LargeCalendar();
		if (lcp == nullptr)
			return -1;

		lcp->hwnd = hwnd;
		SetWindowLong(hwnd, GWL_USERDATA, (long)lcp); //todo: change to SetLongPtr
			
		HDC hdc=GetDC(hwnd);
		//SetBkMode(hdc, TRANSPARENT);
		//SetTextAlign(hdc, TA_LEFT);
		//SelectObject(hdc, GetStockObject(NULL_PEN));

		return 0;
		}

	case WM_DESTROY:
		{
			delete this;
			return 0;
		}

	case WM_ERASEBKGND:
		return TRUE;

	case WM_PAINT:
		{
			PAINTSTRUCT ps;
			RECT clientRect, rect;
			SIZE clientSize;
			const COLORREF
				colorBg   = RGB(255,255,255),
				colorHdr  = RGB(192,192,192),
				colorText = RGB(0,0,0),
				colorSel  = RGB(0,255,255),
				colorPaid = RGB(255,128,128);

			const int rows = weeks;
			const int cols = DaysPerWeek;

			BeginPaint(hwnd, &ps);

			GetClientRect(hwnd, &clientRect);
			clientRect.left = leftHeaderWidth; // adjust to day cells offset
			clientRect.top  = topHeaderHeight;
			clientSize.cx   = clientRect.right  - leftHeaderWidth;
			clientSize.cy   = clientRect.bottom - topHeaderHeight;

			// draw top header
			SetBkColor(ps.hdc, colorHdr);
			SetTextColor(ps.hdc, colorText);

			rect.top = 0;
			rect.bottom = clientRect.top;
			rect.left  = 0;
			rect.right = clientRect.left;

			{
				TCHAR text[80];

				SetTextAlign(ps.hdc, TA_LEFT);
				GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SABBREVMONTHNAME1+startingMonth-1, text, elmsof(text));
				ExtTextOut(ps.hdc, rect.left, rect.top, ETO_OPAQUE|ETO_CLIPPED, &rect, text, lstrlen(text), nullptr);
				DrawEdge(ps.hdc, &rect, BDR_RAISEDOUTER, BF_RECT);					

				// draw days of week
				SetTextAlign(ps.hdc, TA_CENTER);
				int cellWidthHalf = (clientSize.cx / cols) / 2;
				for (int col=0; col < cols; col++) {
					rect.left  = clientRect.left +  col    * clientSize.cx / cols;
					rect.right = clientRect.left + (col+1) * clientSize.cx / cols;
					GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SABBREVDAYNAME1+col, text, elmsof(text));
					ExtTextOut(ps.hdc, rect.left + cellWidthHalf, rect.top, ETO_OPAQUE|ETO_CLIPPED	, &rect, text, lstrlen(text), nullptr);
					DrawEdge(ps.hdc, &rect, BDR_RAISEDOUTER, BF_RECT);					
				}
			}

			// draw rows
			if (rows > 0) {
				int day = startingDay-1;
				int days = 0;

				int month = startingMonth-1;
				static const monthDaysArray[12] = {31,28,31,30,31,30,31,31,30,31,30,31};
				if (month < 0 || month >= elmsof(monthDaysArray)) month=0;
				int monthDays = monthDaysArray[month];

				HPEN payDayPen = CreatePen(PS_SOLID, 3, colorPaid);

				for (int row=0; row < rows; row++) {
					TCHAR text[10];

					rect.top    = clientRect.top +  row    * clientSize.cy / rows;
					rect.bottom = clientRect.top + (row+1) * clientSize.cy / rows;

					// draw left header with week#
					SetTextAlign(ps.hdc, TA_LEFT);
					SetBkColor(ps.hdc, colorHdr);
					SetTextColor(ps.hdc, colorText);

					rect.left  = 0;
					rect.right = clientRect.left;
					wsprintf(text, "Week %d", row+1);
					ExtTextOut(ps.hdc, rect.left, rect.top, ETO_OPAQUE|ETO_CLIPPED, &rect, text, lstrlen(text), nullptr);
					DrawEdge(ps.hdc, &rect, BDR_RAISEDOUTER, BF_RECT);					

					// draw cells with days
					SetTextAlign(ps.hdc, TA_RIGHT);
					for (int col=0; col < cols; col++) {
						rect.left  = clientRect.left +  col    * clientSize.cx / cols;
						rect.right = clientRect.left + (col+1) * clientSize.cx / cols;

						// set color depending on whether day is selected,
						// a pay day, or plain.
						if (days == daySelected) {
							SetBkColor(ps.hdc, colorSel);
						}
						//else if ((days+DaysPerWeek+startingDayOfWeek) % DaysPerWeek == dayPaid) {
						//	SetBkColor(ps.hdc, colorPaid);
						//}
						else {
							SetBkColor(ps.hdc, colorBg);
						}
						wsprintf(text, "%d", day+1);

						ExtTextOut(ps.hdc, rect.right, rect.top, ETO_OPAQUE|ETO_CLIPPED, &rect, text, lstrlen(text), nullptr);
						DrawEdge(ps.hdc, &rect, BDR_RAISEDINNER, BF_RECT);
						
						if ((days+DaysPerWeek+startingDayOfWeek) % DaysPerWeek == dayPaid) {
							SelectObject(ps.hdc, payDayPen);
							SelectObject(ps.hdc, GetStockObject(NULL_BRUSH));
							Ellipse(ps.hdc, rect.left, rect.top, rect.right, rect.bottom);
							SelectObject(ps.hdc, GetStockObject(NULL_PEN));
						}

						day++;
						days++;
						if (day >= monthDays) {
							month++;
							if (month >= MonthsPerYear) month = 0;
							monthDays = monthDaysArray[month];
							day = 0;
						}
					}
				}

				SelectObject(ps.hdc, GetStockObject(NULL_PEN));
				DeleteObject(payDayPen);
			}

			EndPaint(hwnd, &ps);
		}

	case WM_SETFONT:
		SelectObject(GetDC(hwnd), (HFONT)wParam);
		return 0;

	default:
		{
		return DefWindowProc(hwnd, message, wParam, lParam);
		}
	}
}


void LargeCalendar::reformat()
{
	InvalidateRect(hwnd, nullptr, false);
}


void LargeCalendar::selectNextWorkDay()
{
	daySelected++;
	if (daySelected % DaysPerWeek >= daysPerWorkWeek) {
		// advance by number of days remaining in current week
		daySelected += DaysPerWeek - (daySelected % DaysPerWeek);
	}
	InvalidateRect(hwnd, nullptr, false);
}

