// old code not used anymore but kept around for recycling if needed.

#error "Do not compile this. Choose 'exclude from build'."

LoadString(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
LoadString(hInstance, IDC_FRACTURE, szWindowClass, MAX_LOADSTRING);
 

	/*{
		// Draw directly to display at top left.
		//HDC hdc = GetDC(MainWindow.hwnd);
		HDC hdc = GetDCEx(GetDesktopWindow(), nullptr, DCX_WINDOW | DCX_CACHE | 0x10000);
		//HDC hdc = GetDC(MainPreview.hwnd);
		struct {
			BITMAPINFOHEADER hdr;
			//RGBQUAD colors[256];
			int32 colors[256];
		} bmi;
		bmi.hdr.biSize = sizeof(BITMAPINFOHEADER);
		bmi.hdr.biWidth = pfl->canvas.width;
		bmi.hdr.biHeight = -pfl->canvas.height;
		bmi.hdr.biPlanes = 1;
		bmi.hdr.biBitCount = pfl->canvas.bipp;
		bmi.hdr.biCompression = BI_RGB;
		bmi.hdr.biSizeImage = 0;
		bmi.hdr.biXPelsPerMeter = 1;
		bmi.hdr.biYPelsPerMeter = 1;
		bmi.hdr.biClrUsed = 256;
		bmi.hdr.biClrImportant = 240;
		for (uint c = 0; c < bmi.hdr.biClrUsed; c++) {
			#define BLUE	(0x00000001)
			#define GREEN	(0x00000100)
			#define RED		(0x00010000)
			#define ALPHA	(0x01000000)
			bmi.colors[c] =
				ALPHA * c
				+ BLUE  * int(log(c+1.0) * 46)
				+ RED   * (255-int(sqrt(c+1.0) * 32))
				+ GREEN * int(sin(c*M_PI/32 + M_PI/4)*127+128);
				;
			#undef BLUE
			#undef GREEN
			#undef RED
			#undef ALPHA
		}
		SetDIBitsToDevice(hdc, 0,0, pfl->canvas.width,pfl->canvas.height, 0,0, 0,pfl->canvas.height, pfl->canvas.pixels, (BITMAPINFO*)&bmi, DIB_RGB_COLORS);
		ReleaseDC(GetDesktopWindow(), hdc);
	}
	*/



