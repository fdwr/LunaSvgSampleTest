// 2004-01-18
// EFOF.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "resource.h"

BOOL CALLBACK DialogProc(HWND hwnd, UINT message, long wParam, long lParam);
void BmpHeaderInit(int Width, int Height, int Bits);
void BmpPaletteGen(RGBQUAD pal[], int type);
void BmpForceGen(int width, int height, unsigned char *dest);
void BmpVisualGen(int width, int height, unsigned char *src, unsigned char *dest, int type);
//void BmpPatternGen(int width, int height, unsigned char *BmpSrcPxl, int type);
//void BmpTransform(int width, int height, unsigned char *src, unsigned char *dest, int type);


HWND MainHwnd;

#define BmpWidth  320
#define BmpHeight 240
static struct {
	BITMAPINFOHEADER bmiHeader;
	RGBQUAD          bmiColors[256];
} BmpInfo;
unsigned char BmpSrcPxl[BmpHeight*BmpWidth*2];	// force (absolute magnitude) & direction
unsigned char BmpDstPxl[BmpHeight*BmpWidth];	// visualization of fields

#define ChargePointsMax 128
static struct {
	int x;
	int	y;
	int q;	//magnitude of charge
} ChargePoints[ChargePointsMax];
int ChargePointsSize=0;

//int BitmapTransformType=4;
int BmpPaletteGenType=2;
int BmpVisualGenType=0;
int BmpFrame=0;
int AnimateTimed=0;

int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
	BmpHeaderInit(BmpWidth,BmpHeight,8);
	BmpPaletteGen(BmpInfo.bmiColors, BmpPaletteGenType);
	//BmpPatternGen(BmpWidth,BmpHeight, BmpSrcPxl, BitmapPatternGenType);
	//BmpTransform(BmpWidth, BmpHeight, BmpSrcPxl, BmpDstPxl, BitmapTransformType);


	ChargePointsSize=8;
	ChargePoints[0].x=50;
	ChargePoints[0].y=50;
	ChargePoints[0].q=-500000;
	ChargePoints[1].x=150;
	ChargePoints[1].y=160;
	ChargePoints[1].q=300000;
	ChargePoints[2].x=240;
	ChargePoints[2].y=40;
	ChargePoints[2].q=100000;
	ChargePoints[3].x=40;
	ChargePoints[3].y=40;
	ChargePoints[3].q=500000;
	ChargePoints[4].x=270;
	ChargePoints[4].y=70;
	ChargePoints[4].q=10000;

	ChargePoints[5].x=260;
	ChargePoints[5].y=180;
	ChargePoints[5].q=-3000;
	ChargePoints[6].x=280;
	ChargePoints[6].y=200;
	ChargePoints[6].q=-3000;
	ChargePoints[7].x=300;
	ChargePoints[7].y=220;
	ChargePoints[7].q=-3000;

	BmpForceGen(BmpWidth, BmpHeight, BmpSrcPxl);
	//BmpVisualGen(BmpWidth, BmpHeight, BmpSrcPxl, BmpDstPxl, BmpVisualGenType);
	BmpFrame++;

	DialogBox(ProgMemBase, (LPSTR)IDD_EFOF, NULL, (DLGPROC)DialogProc);

	return 0;
}

void BmpHeaderInit(int width, int height, int Bits)
{
	BmpInfo.bmiHeader.biSize = 40;
	BmpInfo.bmiHeader.biWidth = width;
	BmpInfo.bmiHeader.biHeight = -height;
	BmpInfo.bmiHeader.biPlanes = 1;
	BmpInfo.bmiHeader.biBitCount = Bits;
	BmpInfo.bmiHeader.biCompression = 0;
    BmpInfo.bmiHeader.biSizeImage = (width*height*Bits) >> 3;
	BmpInfo.bmiHeader.biXPelsPerMeter = 0;
	BmpInfo.bmiHeader.biYPelsPerMeter = 0;
	BmpInfo.bmiHeader.biClrUsed = 256;
	BmpInfo.bmiHeader.biClrImportant = 256;
}

void BmpPaletteGen(RGBQUAD pal[], int type)
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
	case 1:
		for (count=0; count<256; count++)
		{
			pal[count].rgbGreen=(BYTE)( count*sin(count*.01) );
			pal[count].rgbBlue=count;
		}
		for (count=0; count<64; count++)
		{
			pal[count].rgbRed=(BYTE)( count*4*sin(count*.04908738521235) );
		}
		break;
	case 2: //rainbow (red at bottom, green in middle, blue at top)
		for (count=0; count<256; count++)
		{
			pal[count].rgbRed=255-count;
			pal[count].rgbGreen=(unsigned char)(255*sin(count* 0.01227184630309));
			pal[count].rgbBlue=count;
		}
		break;
	default:
		break;
	}
}

void BmpVisualGen(int width, int height, unsigned char *src, unsigned char *dest, int type)
{
	int x,y, sx,sy, size, top,bottom,left,right;

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
				*dest++ = *(src+(sy*width)+sx);
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
				*dest++ = (unsigned char)(*(src+(sy*width)+sx) * .95);
			}
		}
		break;
	default:
		break;
	}
};

void BmpForceGen(int width, int height, unsigned char *dest)
{
	int x,y, xd,yd, e,d, point;
	if (ChargePointsSize > ChargePointsMax) ChargePointsSize=ChargePointsMax;
	for (y=0; y<height; y++)
	{
		for (x=0; x<width; x++)
		{
			e=0;
			for (point=0; point<ChargePointsSize; point++)
			{
				xd = x-ChargePoints[point].x;
				yd = y-ChargePoints[point].y;
				d = (xd*xd)+(yd*yd);
				if (d) {
					e+= ChargePoints[point].q / d;
				} else {
					e+= ChargePoints[point].q;
				}
			}
			//e=e*10/log(abs(e));
			if (e > 127) e=255;
			else if (e < -128) e=0;
			else e+=128;
			*dest++ = (unsigned char)e;
		}
	}
}

/*
void BmpPatternGen(int width, int height, unsigned char *dest, int type)
{
	int x,y, size, top,bottom,left,right;
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
	default:
		break;
	}
};
*/

/*
void BmpTransform(int width, int height, unsigned char *src, unsigned char *dest, int type)
{
	int x,y, sx,sy, size, top,bottom,left,right;
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
				*dest++ = *(src+(sy*width)+sx);
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
				*dest++ = (unsigned char)(*(src+(sy*width)+sx) * .95);
			}
		}
		break;
	default:
		break;
	}
};
*/

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
	//case WM_TIMER:
	//	if (wParam==13) goto NextFrame;
	//	break;
	case WM_COMMAND:
		switch (wParam)
		{
		/*case IDNEXT:
			if (AnimateTimed) KillTimer(hwnd, 13);
			AnimateTimed=FALSE;
		NextFrame:
			MoveMemory(BmpSrcPxl,BmpDstPxl,sizeof(BmpDstPxl));
			BitmapPatternGen(BmpWidth,BmpHeight, BmpSrcPxl, BitmapPatternGenType);
			BitmapTransform(BmpWidth, BmpHeight, BmpSrcPxl, BmpDstPxl, BitmapTransformType);
			BitmapFrame++;
			PostMessage(hwnd, WM_PAINT, 0,0);
			break;
		case IDOK:
			FillMemory(BmpSrcPxl,sizeof(BmpSrcPxl),0);
			BitmapPatternGen(BmpWidth,BmpHeight, BmpSrcPxl, BitmapPatternGenType);
			BitmapTransform(BmpWidth, BmpHeight, BmpSrcPxl, BmpDstPxl, BitmapTransformType);
			BitmapFrame++;
			PostMessage(hwnd, WM_PAINT, 0,0);
			break;
		*/
		case IDTIMED:
			if (AnimateTimed^=TRUE)
				SetTimer(hwnd, 13, 40, NULL);
			else
				KillTimer(hwnd, 13);
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
			BmpWidth,BmpHeight,	// source rectangle size
			0,0,		// lower-left corner of source rect.
			0,			// first scan line in array 
			BmpHeight,	// number of scan lines 
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
			BmpWidth,BmpHeight,	// source rectangle size
			0,0,		// lower-left corner of source rect.
			0,			// first scan line in array 
			BmpHeight,	// number of scan lines 
			BmpDstPxl,	// address of array with DIB bits 
			(BITMAPINFO*)&BmpInfo,	// address of structure with bitmap info. 
			DIB_RGB_COLORS // RGB or palette indices 
		);
		ReleaseDC(dchwnd, hdc);
		*/

		EndPaint(hwnd, &ps);
		break;
	}
	case WM_MOUSEMOVE: // cheap temp hack!!
		if (!(wParam & MK_LBUTTON))
			break;
	case WM_LBUTTONDOWN: // cheap temp hack!!
		//GetWindowRect(hwnd, &rect);
		ChargePoints[0].x=LOWORD(lParam)-7;
		ChargePoints[0].y=HIWORD(lParam)-8;
		//ChargePoints[0].q=-500000;
		BmpForceGen(BmpWidth, BmpHeight, BmpSrcPxl);
		//BmpVisualGen(BmpWidth, BmpHeight, BmpSrcPxl, BmpDstPxl, BmpVisualGenType);
		BmpFrame++;
		PostMessage(hwnd, WM_PAINT, 0,0);
		break;
	}
	return false;
}
