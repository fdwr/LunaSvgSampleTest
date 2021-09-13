// VisTest.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "resource.h"

BOOL CALLBACK DialogProc(HWND hwnd, UINT message, long wParam, long lParam);
void BitmapHeaderInit(int Width, int Height, int Bits);
void BitmapPaletteGen(RGBQUAD pal[], int type);
void BitmapPatternGen(int width, int height, unsigned char *BmpSrcPxl, int type);
void BitmapTransform(int width, int height, unsigned char *src, unsigned char *dest, int type);


HWND MainHwnd;
static struct {
	BITMAPINFOHEADER bmiHeader;
	RGBQUAD          bmiColors[256];
} BmpInfo;
unsigned char BmpSrcPxl[76800];
unsigned char BmpDstPxl[76800];

#define BitmapTransformMax 5
#define BitmapPaletteGenMax 2
#define BitmapPatternGenMax 3

int BitmapTransformType=4;
int BitmapPaletteGenType=1;
int BitmapPatternGenType=1;
int BitmapFrame=0;
int AnimateTimed=0;

int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	BitmapHeaderInit(320,240,8);
	BitmapPaletteGen(BmpInfo.bmiColors, BitmapPaletteGenType);
	BitmapPatternGen(320,240, BmpSrcPxl, BitmapPatternGenType);
	BitmapTransform(320, 240, BmpSrcPxl, BmpDstPxl, BitmapTransformType);
	BitmapFrame++;

	DialogBox(ProgMemBase, (LPSTR)IDD_VISTEST, NULL, (DLGPROC)DialogProc);

	return 0;
}

void BitmapHeaderInit(int width, int height, int Bits)
{
	BmpInfo.bmiHeader.biSize = 40;
	BmpInfo.bmiHeader.biWidth = width;
	BmpInfo.bmiHeader.biHeight = -height;
	BmpInfo.bmiHeader.biPlanes = 1;
	BmpInfo.bmiHeader.biBitCount = Bits;
	BmpInfo.bmiHeader.biCompression = 0;
	BmpInfo.bmiHeader.biSizeImage = (width*height*Bits) << 3;
	BmpInfo.bmiHeader.biXPelsPerMeter = 0;
	BmpInfo.bmiHeader.biYPelsPerMeter = 0;
	BmpInfo.bmiHeader.biClrUsed = 256;
	BmpInfo.bmiHeader.biClrImportant = 256;
}

void BitmapPaletteGen(RGBQUAD pal[], int type)
{
	int count;
	switch (type)
	{
	case 0: //grayscale
		for (count=0; count<256; count++)
		{
			pal[count].rgbRed=count;
			pal[count].rgbGreen=count;
			pal[count].rgbBlue=count;
		}
		break;
	case 1: // green to red
		for (count=0; count<256; count++)
		{
			pal[count].rgbGreen=(BYTE)( count*sin(count*.01) );
			pal[count].rgbBlue=count;
		}
		for (count=0; count<64; count++)
		{
			pal[count].rgbRed=(BYTE)( count*4*sin(count*.04908738521235) );
		}
		for (       ; count<256; count++)
		{
			pal[count].rgbRed=0;
		}
		break;
	default:
		break;
	}
}

void BitmapPatternGen(int width, int height, unsigned char *dest, int type)
{
	int x,y, i, size, top,bottom,left,right;
	unsigned char *dptr;
	size = height * width;

	switch (type)
	{
	case 0: //X lattice
	{
		int color;
		x = 0;
		for (y=0; y<height; y++)
		{
			color=192;
			for (x = ((BitmapFrame-y)&15); x<width; x+=16)
			{
				*(dest+x) = color;
				color-=8;
			}
			color=255;
			for (x = ((y+BitmapFrame)&15); x<width; x+=16)
			{
				*(dest+x) = color;
				color-=8;
			}
			dest+=width;
			color+=41;
		}
		break;
	}
	case 1: //rectangle
		x=abs((int)( (width>>2) *sin(BitmapFrame*.05)  ));
		left  =(width>>1)-x;
		right =(width>>1)+x;
		y=abs((int)( (height>>2)*sin(BitmapFrame*.061) ));
		top   =(height>>1)-y;
		bottom=(height>>1)+y;
		dptr = dest + (top*width+left);
		for (x=left; x<right; x++)
			(*dptr++) = 255;
		dptr = dest + bottom*width+left;
		for (x=left; x<right; x++)
			(*dptr++) = 255;
		dptr = dest + top*width+left;
		for (y=top; y<bottom; y++) {
			*dptr = 255;
			dptr += width;
		}
		dptr = dest + top*width+right;
		for (y=top; y<bottom; y++) {
			*dptr = 255;
			dptr += width;
		}
		break;
    case 2: // ring of dots
    {
		for (i = 0; i < 128; i++)
		{
			x=(int)( (width>>2) *cos((BitmapFrame+i)*.04)  ) + (width>>1);
			y=(int)( (height>>2)*sin((BitmapFrame+i)*.049) ) + (height>>1);
			*(dest+(y*width)+x) = 255;
		}
    }
	default:
		break;
	}
};


void BitmapTransform(int width, int height, unsigned char *src, unsigned char *dest, int type)
{
	int x,y, sx,sy, size, top,bottom,left,right;
    unsigned char *srcptr;
	size = height * width;
	bottom=height>>1;
	top=bottom-height;
	right=width>>1;
	left=right-width;

	switch (type)
	{
	case 0: //pure copy
		MoveMemory(dest,src,size);
		//for (y=0; y<height; y++)
		//{
		//	for (x=0; x<width; x++)
		//	{
		//		*dest++=*(src+(y*width)+x);
		//	}
		//}
		break;
	case 1: //invert
		for (y=0; y<height; y++)
		{
			for (x=0; x<width; x++)
			{
				*dest++ = 255- *(src+(y*width)+x);
			}
		}
		break;
	case 2: //flip x&y
		for (y=0; y<height; y++)
		{
			for (x=0; x<width; x++)
			{
				sy=height-y-1;
				sx=width-x-1;
				*dest++ = *(src+(sy*width)+sx);
			}
		}
		break;
	case 3: //DaveF-Diagonal Slice.txt
		for (y=0; y<height; y++)
		{
			for (x=0; x<width; x++)
			{
				sx=(int)(x-sin(y));
				sy=(int)(y * .99);
                srcptr = src+(sy*width)+sx;
				//*dest++ = *(src+(sy*width)+sx);
                /* *dest++ = (unsigned char)
                    (
                    (*(srcptr)         * .49) +
                    (*(srcptr+1)       * .20) +
                    (*(srcptr+width)   * .20) +
                    (*(srcptr+width+1) * .10)
                    );
					*/
                *dest++ = (unsigned char)
                    (
					(
                    (*(srcptr)         ) +
                    (*(srcptr+1)       ) +
                    (*(srcptr+width)   ) +
                    (*(srcptr+width+1) )
                    ) * .245
					);
			}
		}
		break;
	case 4:	//JB1 - Tunnel.txt
		src+= (-top*width)-left;
		for (y=top; y<bottom; y++)
		{
			for (x=left; x<right; x++)
			{
				sx=(int)(x*.96);//(sin(x) * cos(y<<1));
				sy=(int)(y+2*sin(x*.07));
                srcptr = src+(sy*width)+sx;
				//*dest++ = (unsigned char)(*(src+(sy*width)+sx) * .95);
                *dest++ = (unsigned char)
                    (
                    (*(srcptr)         * .49) +
                    (*(srcptr+1)       * .20) +
                    (*(srcptr+width)   * .20) +
                    (*(srcptr+width+1) * .10)
                    );
			}
		}
		break;
	default:
		break;
	}
};

/*
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	int wmId, wmEvent;
	//PAINTSTRUCT ps;
	//HDC hdc;
	//TCHAR szHello[MAX_LOADSTRING];
	//LoadString(hInst, IDS_HELLO, szHello, MAX_LOADSTRING);

	switch (message) 
	{
	case WM_COMMAND:
		wmId    = LOWORD(wParam); 
		wmEvent = HIWORD(wParam); 
		// Parse the menu selections:
		switch (wmId)
		{
			//case IDM_ABOUT:
			//   DialogBox(hInst, (LPCTSTR)IDD_ABOUTBOX, hWnd, (DLGPROC)About);
			//   break;
			//case IDM_EXIT:
			//   DestroyWindow(hWnd);
			//   break;
			default:
			   return DefWindowProc(hWnd, message, wParam, lParam);
		}
		break;
	case WM_PAINT:
		hdc = BeginPaint(hWnd, &ps);
		// TODO: Add any drawing code here...
		RECT rt;
		GetClientRect(hWnd, &rt);
		DrawText(hdc, szHello, strlen(szHello), &rt, DT_CENTER);
		EndPaint(hWnd, &ps);
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}
	return 0;
}
*/

BOOL CALLBACK DialogProc(HWND hwnd, UINT message, long wParam, long lParam) 
{
	switch (message)
	{
	case WM_INITDIALOG:
		DefWindowProc(hwnd, WM_SETICON, true, (LPARAM)LoadIcon(ProgMemBase, (LPTSTR)1));
		MainHwnd = hwnd;
		return true;
	case WM_TIMER:
		if (wParam==13) goto NextFrame;
		break;
	case WM_COMMAND:
		switch (wParam)
		{
		case IDNEXT:
			if (AnimateTimed) KillTimer(hwnd, 13);
			AnimateTimed=FALSE;
		NextFrame:
			MoveMemory(BmpSrcPxl,BmpDstPxl,sizeof(BmpDstPxl));
			BitmapPatternGen(320,240, BmpSrcPxl, BitmapPatternGenType);
			BitmapTransform(320, 240, BmpSrcPxl, BmpDstPxl, BitmapTransformType);
			BitmapFrame++;
			PostMessage(hwnd, WM_PAINT, 0,0);
			break;
		case IDOK:
			FillMemory(BmpSrcPxl,sizeof(BmpSrcPxl),0);
			BitmapPatternGen(320,240, BmpSrcPxl, BitmapPatternGenType);
			BitmapTransform(320, 240, BmpSrcPxl, BmpDstPxl, BitmapTransformType);
			BitmapFrame++;
			PostMessage(hwnd, WM_PAINT, 0,0);
			break;
		case IDTIMED:
			if (AnimateTimed^=TRUE)
				SetTimer(hwnd, 13, 40, NULL);
			else
				KillTimer(hwnd, 13);
			break;
        case ID_SHAPE_BASE+0:
        case ID_SHAPE_BASE+1:
        case ID_SHAPE_BASE+2:
            //BitmapPatternGenType = (BitmapPatternGenType+1) % BitmapPatternGenMax;
			BitmapPatternGenType = wParam-ID_SHAPE_BASE;
			break;
        case ID_PALETTE_BASE+0:
        case ID_PALETTE_BASE+1:
            //BitmapPaletteGenType = (BitmapPaletteGenType+1) % BitmapPaletteGenMax;
			BitmapPaletteGenType = wParam-ID_PALETTE_BASE;
        	BitmapPaletteGen(BmpInfo.bmiColors, BitmapPaletteGenType);
			break;
        case ID_TRANSFORM_BASE+0:
        case ID_TRANSFORM_BASE+1:
        case ID_TRANSFORM_BASE+2:
        case ID_TRANSFORM_BASE+3:
        case ID_TRANSFORM_BASE+4:
            //BitmapTransformType = (BitmapTransformType+1) % BitmapTransformMax;
			BitmapTransformType = wParam-ID_TRANSFORM_BASE;
			break;
		case IDCANCEL:
		case IDCLOSE:
			DestroyWindow(hwnd);
			break;
		//default:
		//	SendMessage(GetParent(hwnd), message, wParam, lParam);
		}
		break;
	//case WM_DESTROY:
	case WM_PAINT:
	{
		PAINTSTRUCT ps;
		HDC hdc;
		HWND dchwnd;
		//MessageBeep(MB_OK);

		BeginPaint(hwnd, &ps);

		dchwnd = GetDlgItem(hwnd, IDC_PICSRC);
		hdc=GetDC(dchwnd);
		SetDIBitsToDevice(
			hdc,
			0,0,		// upper-left corner of dest. rect.
			320,240,	// source rectangle size
			0,0,		// lower-left corner of source rect.
			0,			// first scan line in array 
			240,		// number of scan lines 
			BmpSrcPxl,	// address of array with DIB bits 
			(BITMAPINFO*)&BmpInfo,	// address of structure with bitmap info. 
			DIB_RGB_COLORS // RGB or palette indices 
		);	
		ReleaseDC(dchwnd, hdc);

		/*dchwnd = GetDlgItem(hwnd, IDC_PICDST);
		hdc=GetDC(dchwnd);
		SetDIBitsToDevice(
			hdc,
			0,0,		// upper-left corner of dest. rect.
			320,240,	// source rectangle size
			0,0,		// lower-left corner of source rect.
			0,			// first scan line in array 
			240,		// number of scan lines 
			BmpDstPxl,	// address of array with DIB bits 
			(BITMAPINFO*)&BmpInfo,	// address of structure with bitmap info. 
			DIB_RGB_COLORS // RGB or palette indices 
		);
		ReleaseDC(dchwnd, hdc);
		*/

		EndPaint(hwnd, &ps);
		break;
	}
	}
	return false;
}







/*char szWindowClass[] = "VisTest";
WNDCLASSEX wcex = {
	sizeof(WNDCLASSEX),
	0, //CS_HREDRAW | CS_VREDRAW,
	(WNDPROC)WndProc,
	0,
	0,
	0x400000,
	NULL, //LoadIcon(hInstance, (LPCTSTR)IDI_AAA),
	NULL, //LoadCursor(NULL, IDC_ARROW),
	(HBRUSH)(COLOR_WINDOW+1),
	(LPCSTR)NULL,
	szWindowClass,
	NULL //LoadIcon(wcex.hInstance, (LPCTSTR)IDI_SMALL),
};
*/

/*	if (!RegisterClassEx(&wcex)) return FALSE;
	if (!hWnd = CreateWindow(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
	  CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, NULL, NULL, hInstance, NULL) )
		return FALSE;

    ShowWindow(hWnd, nCmdShow);
	UpdateWindow(hWnd);


	// Main message loop:
	while (GetMessage(&msg, NULL, 0, 0)) 
	{
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
*/
