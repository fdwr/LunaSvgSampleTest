/**
\file	ShapeView.cpp
\author	Dwayne Robinson
\since	2005-01-24
\brief	Just a wrapper for GLUT like interfaces.
*/

// define these for mouse wheel constants/macros
#ifndef WINVER
#define WINVER 0x0500
#endif

#ifndef _WIN32_IE
#define _WIN32_IE 0x0501
#endif

#ifndef _WIN32_WINDOWS
#define _WIN32_WINDOWS 0x0410
#endif

#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0500
#endif

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
// Windows Header Files:
#include <windows.h>
#include <GL/gl.h>			// OpenGL header file
#include <GL/glu.h>			// OpenGL utilities header file
//#include <GL/glut.h>		// Just need the constants
#define shapeview_cpp
#include "shapeview.h"

// could cause problems with 64bit, but I have none to test on.
#pragma warning(disable:4311) // pointer truncation from 'ShapeViewStruct *' to 'LONG'
#pragma warning(disable:4312) // conversion from 'LONG' to 'ShapeViewStruct *' of greater size

//static int MouseState = 0;
//static enum {MouseStateLeft=1, MouseStateRight=2, MouseStateMiddle=4};

#define ProgMemBase (HINSTANCE)0x400000
WNDCLASS wcShapeView = {
	CS_OWNDC|CS_DBLCLKS, //style
	(WNDPROC)ShapeViewProc, //lpfnWndProc
	0, //cbClsExtra
	sizeof(ShapeViewStruct*), //cbWndExtra
	ProgMemBase, //hInstance
	0, //hIcon
	0, //hCursor
	NULL, // no flicker! (HBRUSH)(COLOR_WINDOW + 1), //hbrBackground
	0, //lpszMenuName
	ShapeViewClass //lpszClassName
};

LRESULT __stdcall ShapeViewProc(HWND hwnd, UINT message, long wParam, long lParam)
{
	ShapeViewStruct *ptr = (ShapeViewStruct*)GetWindowLong(hwnd, GWL_PTR);
	int button, state, mx, my, mz;
	//-static HCURSOR hcarrow = NULL, hcpan = NULL;
	//self = hwnd;
	//al = (AttribList*)GetWindowLong(hwnd, GWL_USERDATA);

	//debugwrite("al  msg=%X wParam=%X lparam=%X", message, wParam, lParam);

	switch (message) {
	case WM_CREATE:
	{
		// create window's main structure
		ptr = (ShapeViewStruct*)GlobalAlloc(GMEM_FIXED, sizeof(ShapeViewStruct));
		if (!ptr) return -1;
		SetWindowLong(hwnd, GWL_PTR, (LONG)ptr);
		SetClassLong(hwnd, GCL_HCURSOR, (LONG)LoadCursor(NULL, IDC_ARROW));
		// and initialize it
		ptr->hwnd = hwnd;
		ptr->mxo = 0;
		ptr->myo = 0;
		ptr->mzo = 0;
		ptr->mb = 0;
		ptr->ms = GLUT_UP;
		ptr->display = NULL;
		ptr->mouse = NULL;
		ptr->motion = NULL;
		ptr->reshape = NULL;
		ptr->keyboard = NULL;
		break;
	}
	case WM_PAINT:
	{
		PAINTSTRUCT ps;
		HDC hdc;
		//RECT rect;
		//GetClientRect(hwnd, &rect);
		//FillRect(GetDC(hwnd), &rect, (HBRUSH)(COLOR_WINDOWTEXT+1));
		hdc = BeginPaint(hwnd, &ps);
		if (ptr->display) {
			ptr->display(ptr);
		}
		//SwapBuffers(hdc);			/* nop if singlebuffered */
		EndPaint(hwnd, &ps);
		//ValidateRect(hwnd, NULL);
		break;
	}
	case WM_ERASEBKGND:
		//if ((lParam & 0xFFFF) != HTCLIENT) goto DoDefWndProc;
		return TRUE;

	case WM_MOUSEACTIVATE:
		SetFocus(hwnd);
		return MA_ACTIVATE;

	case WM_LBUTTONDBLCLK:
    case WM_LBUTTONDOWN:
		SetCursor(LoadCursor(NULL, IDC_SIZEALL));
		button = GLUT_LEFT_BUTTON;
		state = GLUT_DOWN;
		goto ButtonPressed;
    case WM_RBUTTONDOWN:
		button = GLUT_RIGHT_BUTTON;
		state = GLUT_DOWN;
		goto ButtonPressed;
	case WM_MBUTTONDOWN:
		button = GLUT_MIDDLE_BUTTON;
		state = GLUT_DOWN;
		goto ButtonPressed;
	case WM_LBUTTONUP:
		button = GLUT_LEFT_BUTTON;
		state = GLUT_UP;
		goto ButtonPressed;
	case WM_RBUTTONUP:
		button = GLUT_RIGHT_BUTTON;
		state = GLUT_UP;
		goto ButtonPressed;
	case WM_MBUTTONUP:
		button = GLUT_MIDDLE_BUTTON;
		state = GLUT_UP;
		//goto ButtonPressed;
	//case WM_CAPTURECHANGED:
	ButtonPressed:
		mx = ((signed)(lParam << 16)) >> 16; // LOWORD(lParam);
		my = ((signed)lParam) >> 16; // HIWORD(lParam);
		ptr->mb = button;
		ptr->ms = state;
		//-void WriteMessage(LPTSTR msg, ...);
		//-WriteMessage("ms mm=%d\r\n", ptr->ms);
		if (state == GLUT_DOWN) {
			// if we don't set the capture we won't get mouse move
			//	messages when the mouse moves outside the window.
			SetCapture(hwnd);
		}
		else {
			// remember to release the capture when finished.
			ReleaseCapture();
			SetCursor(LoadCursor(NULL, IDC_SIZEALL));
		}
		ptr->mxo = mx;
		ptr->myo = my;
		if (ptr->mouse) {
			ptr->mouse(ptr, button, state, mx, my, ptr->mzo);
		}
		break;

    case WM_MOUSEMOVE:
		if (ptr->ms == GLUT_DOWN) { // && ptr->mb == GLUT_LEFT_BUTTON) {
			mx = ((signed)(lParam << 16)) >> 16; // LOWORD(lParam);
			my = ((signed)lParam) >> 16; // HIWORD(lParam);
			if (ptr->motion)
				ptr->motion(ptr, mx,my, ptr->mzo);
			//PostMessage(hWnd, WM_PAINT, 0, 0);
			ptr->mxo = mx;
			ptr->myo = my;
		}
		break;

	case WM_MOUSEWHEEL:
	{
		mz = GET_WHEEL_DELTA_WPARAM(wParam) + ptr->mzo;
		// do NOT update mx or my in mouse wheel message, even if they change
		// leave that for the mousemove message instead.
		if (ptr->motion)
			ptr->motion(ptr, ptr->mxo,ptr->myo, mz);
		ptr->mzo = mz;
		return TRUE;
	}

	case WM_KEYUP:
		if (ptr->keyboard)
			ptr->keyboard(ptr, wParam, GLUT_UP);
		break;
	case WM_KEYDOWN:
		if (ptr->keyboard)
			ptr->keyboard(ptr, wParam, (lParam & (1<<30)) ? GLUT_REPEAT : GLUT_DOWN);
		break;

	case WM_GETDLGCODE:
		return DLGC_WANTCHARS|DLGC_WANTARROWS; //|DLGC_WANTALLKEYS;

	case WM_SIZE:
	{
		RECT rect;
		GetClientRect(hwnd, &rect); // just in case not called by system
		ptr->width  = rect.right;
		ptr->height = rect.bottom;
		if (ptr->reshape) {
			ptr->reshape(ptr, rect.right, rect.bottom);
			//ptr->reshape(ptr, LOWORD(lParam), HIWORD(lParam));
		} else {
			glViewport(0, 0, rect.right, rect.bottom);
			InvalidateRect(hwnd, NULL, FALSE);
		}
		break;
	}
	// copy the image to the clipboard
	case WM_COPY:
		ShapeViewCopyImage(hwnd);
		break;

	case WM_DESTROY:
		GlobalFree(ptr);
		// fall through

	default:
	//DoDefWndProc:
		return DefWindowProc(hwnd, message, wParam, lParam);
	}
	return 0;
}

/** Initializes use of OpenGL on shape view window.

\param	hwnd	Window handle of the created shape view.
\param	pixtype	Pixel type (PFD_TYPE_RGBA...).
\param	flags	Pixel format flags (PFD_DRAW_TO_WINDOW|PFD_SUPPORT_OPENGL|...)

\return	-1 on error, 0 everything ok
*/
int ShapeViewInitGl(HWND hwnd, BYTE pixtype, DWORD flags)
{
	// initialize OpenGL to window
	// *copied from minimal.c from opengl.org
	int pf;
	HDC hDC;
	PIXELFORMATDESCRIPTOR pfd;

	if (!hwnd) return -1;
	hDC = GetDC(hwnd);

	/* there is no guarantee that the contents of the stack that become
	the pfd are zeroed, therefore _make sure_ to clear these bits. */
	memset(&pfd, 0, sizeof(pfd));
	pfd.nSize        = sizeof(pfd);
	pfd.nVersion     = 1;
	pfd.dwFlags      = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | flags;
	pfd.iPixelType   = pixtype;
	pfd.cColorBits   = 32;

	pf = ChoosePixelFormat(hDC, &pfd);
	if (pf == 0) {
		MessageBox(NULL, T("ChoosePixelFormat() failed:  ")
			T("Cannot find a suitable pixel format."), T("Error"), MB_OK); 
		return -1;
	} 

	if (SetPixelFormat(hDC, pf, &pfd) == FALSE) {
		MessageBox(NULL, T("SetPixelFormat() failed:  ")
			T("Cannot set format specified."), T("Error"), MB_OK);
		return -1;
	} 

	DescribePixelFormat(hDC, pf, sizeof(PIXELFORMATDESCRIPTOR), &pfd);

	RECT rect;
	GetClientRect(hwnd, &rect); // just in case not called by system
	glViewport(0, 0, rect.right, rect.bottom);

	ReleaseDC(hwnd, hDC);
	return 0;
}

/** Given a window handle, returns the pointer to its ShapeViewStruct.

\param	hwnd	Window handle of the created shape view.

\return	ptr to ShapeViewStruct
*/
static ShapeViewStruct* GetPtr(HWND hwnd)
{
	return (ShapeViewStruct*)GetWindowLong(hwnd, GWL_PTR);
}

/** Sets display callback for redrawing.

\param	hwnd		Window handle of the created shape view.
\param	display		Function pointer to call.
*/
void ShapeViewDisplayFunc(HWND hwnd, void (*display)(ShapeViewStruct*))
{
	GetPtr(hwnd)->display = display;
}

/** Sets callback for keypresses.

\param	hwnd		Window handle of the created shape view.
\param	keyboard	Function pointer to call.
*/
void ShapeViewKeyboardFunc (HWND hwnd, void (*keyboard)(ShapeViewStruct*, int key, int state))
{
	GetPtr(hwnd)->keyboard = keyboard;
}

/** Sets callback for mouse button events (press/release).

\param	hwnd		Window handle of the created shape view.
\param	mouse		Function pointer to call.
*/
void ShapeViewMouseFunc (HWND hwnd, void (*mouse)(ShapeViewStruct*, int button, int state, int x, int y, int z))
{
	GetPtr(hwnd)->mouse = mouse;
}

/** Sets callback for mouse motion and scroll.

\param	hwnd	Window handle of the created shape view.
\param	motion	Function pointer to call.
*/
void ShapeViewMotionFunc (HWND hwnd, void (*motion)(ShapeViewStruct*, int x, int y, int z))
{
	GetPtr(hwnd)->motion = motion;
}

/** Sets callback for window resize events.

\param	hwnd	Window handle of the created shape view.
\param	reshape	Function pointer to call.
*/
void ShapeViewReshapeFunc (HWND hwnd, void (*reshape)(ShapeViewStruct*, int width, int height))
{
	GetPtr(hwnd)->reshape = reshape;
}

/** Copies the currently displayed image to the clipboard.

\param	hwnd	Window handle of the created shape view.

\remark	The window must be visible. Any part of the window occluded will not
		be copied.
*/
void ShapeViewCopyImage(HWND hwnd)
{
	RECT rect;
	GetClientRect(hwnd, &rect); // just in case not called by system

	// create temp bitmap
	BITMAPINFOHEADER bmi; /* = {
		sizeof(BITMAPINFOHEADER),
			rect.right,
			-rect.bottom,
			1, 32,
			BI_RGB, rect.right*rect.bottom*4,
			1,1,
			0,0
	};
	*/
	bmi.biSize = sizeof(BITMAPINFOHEADER);
	bmi.biWidth = rect.right;
	bmi.biHeight = -rect.bottom;
	bmi.biPlanes = 1;
	bmi.biBitCount= 32;
	bmi.biCompression = BI_RGB;
	bmi.biSizeImage = 0;//ImageSrc.width*ImageSrc.height*1;
	bmi.biXPelsPerMeter = 1;
	bmi.biYPelsPerMeter = 1;
	bmi.biClrUsed = 0;
	bmi.biClrImportant = 0;

	// create empty bitmap
	HBITMAP hbmp = CreateBitmap(
		rect.right, rect.bottom,
		1, 32, NULL);

	HDC hdc  = GetDC(hwnd),
		hdc2 = CreateCompatibleDC(hdc);

	SelectObject(hdc2, hbmp);
	//HBRUSH hbrush = CreateSolidBrush(0xFFFFFF);
	//SelectObject(PgfxDisplay.hdcc, hbrush);
	//PatBlt(PgfxDisplay.hdcc,0,0,10000,10000, PATCOPY);

	/*SetDIBitsToDevice(PgfxDisplay.hdcc,
			0,0, ImageSrc.width, ImageSrc.height,
			0,0, 0,ImageSrc.height,
			ImageDest.pixels,
			(BITMAPINFO*)&bmi,
			DIB_RGB_COLORS);
	}*/
	BitBlt(hdc2, 0,0, rect.right, rect.bottom, hdc, 0,0, SRCCOPY);

	if (OpenClipboard(hwnd)) {
		EmptyClipboard(); // ! must empty or later sets will fail !?
		SetClipboardData(CF_BITMAP, hbmp);
		CloseClipboard();
	} else {
		MessageBeep(MB_ICONASTERISK);
	}

	DeleteDC(hdc2);
	//DeleteObject(hbrush);
	//DeleteObject(hbmp); // ! do not delete, or else disappears from clipboard
}
