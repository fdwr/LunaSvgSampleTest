/**
program: StopWatch
author: Dwayne Robinson
date: 2006-07-20
description: Simple, large calendar display.
*/

class LargeCalendar
{
	////////////////////////////////////////
	// functions

public:

	LargeCalendar::LargeCalendar();

	static ATOM registerClass();
	LRESULT wndProc(
		HWND hwnd,
		UINT message,
		long wParam,
		long lParam);

	static LargeCalendar* LargeCalendar::getReference(HWND hwnd);

	void reformat(); /// updates any changes to screen
	void selectNextWorkDay(); /// advance next work day, skipping weekends

private:
	//...



	////////////////////////////////////////
	// variables

public:
	static TCHAR className[];
	static WNDCLASS windowClass;

	int daySelected; /// selected day, offset from first day (+0=first day, +1=next day...)
	int dayPaid; /// day checks are paid
	int daysPerWorkWeek; /// can be 0-7, typically 5
	int weeks; /// #weeks determines #rows high
	int startingMonth; /// first month to base days from (1=Jan, 12=Dec)
	int startingDay; /// first day to base days from (1=first, 31=last)
	int startingDayOfWeek; /// leftmost day to be first day of week (Sunday=0) or second day (Monday=1)

	int topHeaderHeight; /// pixel width of left week column
	int leftHeaderWidth; /// pixel height of top heahedr

private:
	HWND hwnd;
};

