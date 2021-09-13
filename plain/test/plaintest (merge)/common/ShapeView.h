/**
\file	ShapeView.h
\author	Dwayne Robinson
\since	2005-01-24
\date	2005-06-29
*/

#pragma once

typedef struct ShapeViewStruct {
	HWND hwnd;	// handle of ShapeView, can also be used as an 'id'
	int mxo;	// mouse x old
	int myo;	// mouse y old
	int mzo;	// mouse y old
	int mb;		// mouse button last pressed
	int ms;		// mouse state last
	int width;	// client region pixel width
	int height;	// client region pixel height

	void (*display)(ShapeViewStruct*);
	void (*keyboard)(ShapeViewStruct*, int key, int state);
	void (*mouse)(ShapeViewStruct*, int button, int state, int x, int y, int z);
	void (*motion)(ShapeViewStruct*, int x, int y, int z);
	void (*reshape)(ShapeViewStruct*, int width, int height);
} ShapeViewStruct;

#define GWL_PTR 0

#ifndef T
#ifdef UNICODE
  #define T(string) L##string
#else
  #define T(string) string
#endif
#endif

#define ShapeViewClass T("ShapeViewClass")


LRESULT __stdcall ShapeViewProc(HWND hwnd, UINT message, long wParam, long lParam);
int ShapeViewInitGl(HWND hwnd, BYTE type, DWORD flags);
void ShapeViewDisplayFunc(HWND hwnd, void (*display)(ShapeViewStruct*));
void ShapeViewKeyboardFunc (HWND hwnd, void (*keyboard)(ShapeViewStruct*, int key, int state));
void ShapeViewMouseFunc (HWND hwnd, void (*mouse)(ShapeViewStruct*, int button, int state, int x, int y, int z));
void ShapeViewMotionFunc (HWND hwnd, void (*motion)(ShapeViewStruct*, int x, int y, int z));
void ShapeViewReshapeFunc (HWND hwnd, void (*reshape)(ShapeViewStruct*, int width, int height));
void ShapeViewCopyImage(HWND hwnd);

#ifndef shapeview_cpp
extern WNDCLASS wcShapeView;
#endif

#ifndef __glut_h__
// Define these constants if they are not already defined.
// If the calling app wants to use GLUT, that's ok (albeit unwise);
// however, this little custom control avoids the inclusion
// of glut32.lib by redundantly defining a few constants.

/* Mouse buttons. */
#define GLUT_LEFT_BUTTON		0
#define GLUT_MIDDLE_BUTTON		1
#define GLUT_RIGHT_BUTTON		2

/* Mouse button  state. */
#define GLUT_DOWN			0
#define GLUT_UP				1
#define GLUT_REPEAT			2 // not a GLUT key constant

#endif //  __glut_h__
