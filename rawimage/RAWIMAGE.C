// main.c - Raw Image converter
//
// Converts image files to raw pixels or raw pixels to image files.
// Reads bitmaps or PNGs. Can do simple color conversions.
// Does NOT discard alpha channel like many image editors.
//
// Written for Windows console, but could be converted to Unix without much
// difficulty.
//
// Todo:	Add bitmap reading
//			Add pixel format conversions
//			Add special conversions
//			Add PNG writing
//
// 20040802 Project started
// 20040803	Reads PNGs of all bitdepths (except the monochrome images
//			which show the wrong colors)
//			Accepts few generic command line options
//			Displays images to screen as temp hack
//			Writes raw data (including that alpha channel I've wanted!)
//
//
// Debugging strings:
//	d:\src\plain\pgfxtest\data\images08s.png -preview
//  d:\pic\misc\teoani.bmp -preview
//  format=RGB888 size=320,240 test24.raw -preview
//  size=48,300 offset=9776449 format=LE4 d:\emu\roms\ZELDA6~1.V64 -preview
//  size=44,300 offset=9243456 format=LE16 d:\emu\roms\STARFO~1.V64 -preview

//#define WIN32_LEAN_AND_MEAN
#define NO_STRICT
#define NOATOM
#define NOMETAFILE
#define NOSERVICE
#define NOSOUND
#define NOWH
#define NOCOMM
#define NOHELP
#define NOPROFILER
#define NOMCX

#include <windows.h>
#include <string.h>
#include <stdio.h>

#include "..\libpng\png.h"
#include "..\zlib\zlib.h"

#include "convert.h"

enum {	ImageType_raw, ImageType_bmp, ImageType_png, ImageType_zlg};
#define ImageTypesString "raw\0bmp\0png\0zlg\0\0"
// the pixel types order MUST match those found in convert.h
#define PixelTypesString \
	"LE1\0" \
	"BE1\0"	\
	"LE2\0"	\
	"BE2\0"	\
	"LE4\0"	\
	"BE4\0"	\
	"LE8\0"	\
	"BE8\0"	\
	"LE16\0" \
	"BE16\0" \
	"LE32\0" \
	"BE32\0" \
	"BGRA5551\0" \
	"RGBA5551\0" \
	"BGR565\0" \
	"RGB565\0" \
	"BGR888\0" \
	"RGB888\0" \
	"BGRA8888\0" \
	"RGBA8888\0" \
	"\0"

#define MaxImageRows 4096
#define MaxImageCols 4096
#define MaxImageBpp 32

typedef struct {
	char name[MAX_PATH]; // file path and name
	int type;	// file type: RAW, PNG, or BMP
	int align;	// byte alignment (usually 4)
	int ofs;	// file offset (start of pixel data in raw file)
	int len;	// byte length of file
	int alpha;	// explicit alpha value (for when no alpha in file)
} ImageFileSpecs;

typedef struct {
	int bpp;	// bits per pixel
	//int bpc;	// bits per component (not always used)
	int format;	// pixel format (LE4 BE16 RGB555 RGBA8888...)
	int width;	// pixel width
	int height;	// pixel height
	int rowbytes; // bytes per row
	int bytes;	// total bytes used for image data
	int palsize; // number of entries in palette
	unsigned __int32 pal[256]; // BGRA palette
	char *rows[MaxImageRows]; // row pointers
	char *pixels; // pixel data as 8bit or 32bit
} ImageData;


////////////////////////////////////////////////////////////////////////////////
// Function prototypes

int ExitWithMsg(char *msg, int code);
void PngFileRead(png_structp png_ptr, png_bytep data, png_uint_32 length);
void ImageRowsSetForward(ImageData* id);
void ImageRowsSetBackward(ImageData* id);
void ReadSrcImageData();
void WriteDestImageData();
void SetDefaultImageFormat(ImageData* id);

int strmatchusing(const char *string, const char *matches, int (*cmpfunc)(const char*, const char*));
int strmatch(const char *string, const char *matches);
char *strfileext(const char *filename);
int strcmpprefix(const char* string, const char* prefix);

////////////////////////////////////////////////////////////////////////////////
// Variables

HANDLE ImageFd;
png_structp png_ptr;
png_infop info_ptr;
int png_color_type;
int png_bit_depth;
int dummy; // variable for useless information

ImageFileSpecs
SrcFile = {"", ImageType_raw,	1,0,0,	255|(1<<31) },
DestFile = {"", ImageType_raw,	1,0,0,	255|(1<<31) };

ImageData SrcImage, DestImage;

////////////////////////////////////////////////////////////////////////////////
// Code

int main (int argc, char* argv[])
{
	int ArgFlags=0;
	enum {ArgFlagSrc=1, ArgFlagDest=2, ArgFlagPreview=4, ArgFlagSrcFmt=8, ArgFlagAlpha=16};

////////////////////////////////////////////////////////////////////////////////
// Init some vars with default values

	SrcImage.bpp = -1; //32;
	SrcImage.format = -1; //PixelType_BGRA8888;
	SrcImage.width = 320;
	SrcImage.height = 200;
	SrcImage.rowbytes = 320*4;
	SrcImage.bytes = 320*200*4;
	SrcImage.palsize = 0;
	SrcImage.pixels = NULL;

	DestImage.bpp = -1;
	DestImage.format = -1;
	DestImage.width = -1;
	DestImage.height = -1;
	DestImage.rowbytes = -1;
	DestImage.bytes = 0;
	DestImage.palsize = 0;
	DestImage.pixels = NULL;

////////////////////////////////////////////////////////////////////////////////
// Parse parameters
	{
		static const char ArgList[] = {
			"bpp=\0"
			"size=\0"
			"align=\0"
			"offset=\0"
			"alpha=\0"
			"format=\0"
			"-preview\0"
			//"type=\0"
			"\0" };
		enum { ArgBpp, ArgSize, ArgAlign, ArgOffset, ArgAlpha, ArgFormat, ArgPreview };

		int word;
		int command;
		int value;
		char *argptr;

		// display options if no params given
		printf(	"RawImage - PikenSoft 2004\n" );
		if (argc <= 1)
			ExitWithMsg(
				"Converts images to raw pixels or vice versa.\n"
				"No parameters were given. You can use the following:\n"
				"\n"
				"rawimage [srcoptions=#] sourcefile [destoptions=#] [destfile]\n"
				"\n"
				"bpp=#    bits per pixel 8/16/24/32 (default is same as source)\n"
				"format=$ BE1 BE2 BE4 BE8 LE16 BGR555 BGRA5551 BRG888 BGRA8888...\n"
				"size=#,# image size 1-4096 (only used when source is raw)\n"
				"align=#  align image row bytes 1-4096 (default is 4)\n"
				"offset=# file offset 0-endoffile (default is 0)\n"
				"\n"
				"Options apply to either the source or destination image depending on\n"
				"where you place them. Before the source filename apply to the source.\n"
				"Options after the source apply to the destination.\n"
				"File types supported: bmp,png,raw,zlg"
				, 87);

		// loop through each command line word
		for (word=1; argv[word]; word++) {
			command = strmatchusing(argv[word], ArgList, strcmpprefix);
			argptr = strchr(argv[word], '=');
			if (!argptr) argptr = argv[word]; // not an option, must be filename
			else argptr++; // skip '='

			switch ( command ) {
			case ArgBpp:
				if (strmatch(argptr, "1\0" "2\0" "4\0" "8\0" "16\0" "24\0" "32\0" "\0") < 0)
					ExitWithMsg("Pixel bitdepth must be 1/2/4/8/16/24/32", 87);
				value = atoi(argptr);
				if (ArgFlags & ArgFlagSrc) DestImage.bpp = value;
				else SrcImage.bpp = value;
				break;
			case ArgSize:
				value = atoi(argptr);
				if (value <= 0 || value > MaxImageCols)
					ExitWithMsg("Image width must be 1-4096", 87);
				if (ArgFlags & ArgFlagSrc) DestImage.width = value;
				else SrcImage.width = value;
				while (TRUE) {
					char chr = *argptr++;
					if (chr < '0' || chr > '9') {
						if (chr == ',') break;
						ExitWithMsg("Need both image width and height (size=W,H)", 87);
					}
				}
				value = atoi(argptr);
				if (value <= 0 || value > MaxImageRows)
					ExitWithMsg("Image height must be 1-4096", 87);
				if (ArgFlags & ArgFlagSrc) DestImage.height = value;
				else SrcImage.height = value;
				break;
			case ArgAlign: // (bytes to align)
				value = atoi(argptr);
				if (value <= 0 || value > MaxImageCols*4)
					ExitWithMsg("Image alignment must be 1-4096 (default is 4 bytes)", 87);
				if (ArgFlags & ArgFlagSrc) DestFile.align = value;
				else SrcFile.align = value;
				break;
			case ArgOffset:
				value = atoi(argptr);
				if (value < 0)
					ExitWithMsg("Image offset must be positive, 0-endoffile", 87);
				if (ArgFlags & ArgFlagSrc) DestFile.ofs = value;
				else SrcFile.ofs = value;
				break;
			case ArgAlpha:
				value = atoi(argptr);
				if (value < 0 || value > 255)
					ExitWithMsg("Alpha value must be 0-255", 87);
				SrcFile.alpha = value;
				ArgFlags |= ArgFlagAlpha;
				break;
			case ArgFormat:
				if ((value = strmatch(CharUpper(argptr), PixelTypesString)) < 0)
					ExitWithMsg("Unknown pixel format", 87);
				DestImage.format = value; // set dest = src
				if (ArgFlags & ArgFlagSrc) {
					//ArgFlags |= ArgFlagDestfmt;
				}
				else {
					SrcImage.format = value;
					ArgFlags |= ArgFlagSrcFmt;
				}
				break;
			case ArgPreview:
				ArgFlags |= ArgFlagPreview;
				break;

			default:
				if (*argptr == '-' || strchr(argv[word], '='))
					ExitWithMsg("Unrecognized parameter", 87);
				// must be source filename, unless input name already grabbed
				// otherwise it must be destination filename
				if (ArgFlags & ArgFlagDest) {
					ExitWithMsg("Too many filenames", 87);
				}
				else if (ArgFlags & ArgFlagSrc) {
					strcpy(DestFile.name, argptr);
					ArgFlags |= ArgFlagDest;
				}
				else {
					strcpy(SrcFile.name, argptr);
					ArgFlags |= ArgFlagSrc;
				}
			}
		}
		// read all parameters, now further validate

		// must have given a source file
		if (!(ArgFlags & ArgFlagSrc))
			ExitWithMsg("No source image file was given", 87);

		// determine source file type
		SrcFile.type = strmatchusing(strfileext(SrcFile.name), ImageTypesString, strcmpi);
		if (SrcFile.type < 0) {
			SrcFile.type = ImageType_raw;
			printf("Source file type not recognized. Treating as raw data.\n");
		}

		// no output file if previewing only
		if (ArgFlags & ArgFlagPreview) {
			DestFile.name[0] = '\0';
		}
		// if destination filename given
		else if (ArgFlags & ArgFlagDest) {
			argptr = strfileext(DestFile.name);
			DestFile.type = strmatchusing(argptr , ImageTypesString, strcmpi);
			if (DestFile.type < 0) {
				DestFile.type = ImageType_raw;
				printf("Destination file type not recognized. Will read as raw data.\n");
			}
		}
		// else no output filename was given,
		// so use source filename with different extension
		else {
			// set destination to raw
			printf("No destination file given. Will write as raw data.\n");
			strcpy(DestFile.name, SrcFile.name);
			argptr = strfileext(DestFile.name);
			if (*argptr)
				argptr--; // replace period
			*((int*)argptr) = 'war.';
			DestFile.type = ImageType_raw;
		}
	}

	printf(	"  Source file: %s\n"
			"    Dest file: %s\n",
			SrcFile.name,
			DestFile.name
		  );

////////////////////////////////////////////////////////////////////////////////
// Set source file image with default attributes

	SetDefaultImageFormat(&SrcImage);
	// make a default grayscale palette
	if (SrcImage.bpp <= 8) {
		int idx;
		int idxs=1 << SrcImage.bpp;
		int clr=0;
		int step=0x01010100 >> SrcImage.bpp;
		for (idx = 0; idx < idxs; idx++) {
			SrcImage.pal[idx] = clr;
			clr += step;
		}
	}

////////////////////////////////////////////////////////////////////////////////
// Open source file and get info

	// open source file
	ImageFd = CreateFile(
				SrcFile.name,
				GENERIC_READ,  FILE_SHARE_READ,
				NULL,
				OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN,
				NULL);
	if (ImageFd == INVALID_HANDLE_VALUE)
		ExitWithMsg("Source image could not be opened", GetLastError());

	SrcFile.len = SetFilePointer(ImageFd, 0,NULL, FILE_END);
	SetFilePointer(ImageFd, 0,NULL, FILE_BEGIN);
	if (SrcFile.len < 8) {
		// CloseHandle(ImageFd);
		ExitWithMsg("Source file size to small", GetLastError());
	}

	// get source image info
	switch (SrcFile.type) {
	case ImageType_raw:
		// maybe adjust height if (filesize / width) > height
		break;

	case ImageType_bmp:
	{
		// does not read OS/2 Presentation manager bitmaps
		struct {
			#pragma pack(push, 1) // for byte alignment
			BITMAPFILEHEADER bfh;
			BITMAPINFOHEADER bmih;
			#pragma pack(pop)     // for original alignment
		} BitmapHeader;
		//
		ReadFile(ImageFd, &BitmapHeader, sizeof(BitmapHeader), &dummy, NULL);
		if (dummy < sizeof(BitmapHeader)) {
			CloseHandle(ImageFd);
			ExitWithMsg("Bitmap header is corrupt (too small)", -1);
		}
		if (BitmapHeader.bfh.bfType != 'MB') {
			CloseHandle(ImageFd);
			ExitWithMsg("File is not a bitmap (does not have 'BM' bitmap signature)", -1);
		}
		if (BitmapHeader.bmih.biCompression != 0) {
			CloseHandle(ImageFd);
			ExitWithMsg("Compressed bitmap are unsupported (use another program to decompress)", -1);
		}
		SrcImage.width = BitmapHeader.bmih.biWidth;
		SrcImage.height = BitmapHeader.bmih.biHeight;
		SrcImage.bpp = BitmapHeader.bmih.biBitCount;
		SrcImage.palsize = BitmapHeader.bmih.biClrUsed;
		if (SrcImage.palsize <= 0 && SrcImage.bpp <= 8) {
			SrcImage.palsize = 1<<SrcImage.bpp;
		}
		if (SrcFile.align < 4) SrcFile.align=4;

		// set source image format
		// if not already overridden by user
		if (!(ArgFlags & ArgFlagSrcFmt)) {
			switch (SrcImage.bpp) {
			case 1:		SrcImage.format = PixelType_BE1;		break;
			case 2:		SrcImage.format = PixelType_BE2;		break;
			case 4:		SrcImage.format = PixelType_BE4;		break;
			case 8:		SrcImage.format = PixelType_BE8;		break;
			case 15:	SrcImage.format = PixelType_BGRA5551;	break;
			case 16:	SrcImage.format = PixelType_BGR565;		break;
			case 24:	SrcImage.format = PixelType_BGR888;		break;
			case 32:	SrcImage.format = PixelType_BGRA8888;	break;
			}
		}

		// advance to palette in case header is larger than usual 40 bytes
		SetFilePointer(ImageFd,
			BitmapHeader.bmih.biSize-sizeof(BitmapHeader.bmih), NULL,
			FILE_CURRENT);
		break;
	}
	case ImageType_png:
		png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, (png_voidp)NULL,NULL,NULL);
		if (!png_ptr) goto PngCreateReadError;
		info_ptr = png_create_info_struct(png_ptr);
		if (!info_ptr) goto PngCreateInfoError;
		if (setjmp(png_jmpbuf(png_ptr)))
		{
			png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);
			CloseHandle(ImageFd);
			ExitWithMsg("Unexpected fatal error reading PNG", -1);
		}
		//png_set_read_fn(png_structp read_ptr,
		//	voidp read_io_ptr, png_rw_ptr read_data_fn)
		png_set_read_fn(png_ptr, (void *)NULL, (png_rw_ptr)PngFileRead);

		png_read_info(png_ptr, info_ptr);
		png_get_IHDR(png_ptr, info_ptr, &SrcImage.width, &SrcImage.height,
			&png_bit_depth, &png_color_type, &dummy,
			&dummy, &dummy);
		SrcImage.bpp = png_bit_depth * png_get_channels(png_ptr, info_ptr);

		if (SrcImage.bpp == 8)
			SrcImage.format = PixelType_BE8;
		else
			SrcImage.format = PixelType_BGRA8888;

		break;

	  PngCreateInfoError:
		png_destroy_read_struct(&png_ptr, (png_infopp)&info_ptr, (png_infopp)NULL);
	  PngCreateReadError:
		ExitWithMsg("Unexpected error initializing PNG library", -1);
		//break;
	}

	printf(	"  Source size: %d bytes\n"
			" Source width: %d\n"
			"Source height: %d\n"
			"   Source BPP: %d\n",
			SrcFile.len,
			SrcImage.width,
			SrcImage.height,
			SrcImage.bpp
			);

////////////////////////////////////////////////////////////////////////////////
// Load source file

	if (SrcImage.width > MaxImageCols)
		ExitWithMsg("Image width is larger than the maximum!", -1);
	if (SrcImage.height > MaxImageRows)
		ExitWithMsg("Image height is larger than the maximum!", -1);
	if (SrcImage.bpp > MaxImageBpp)
		ExitWithMsg("Image bits per pixel is larger than the maximum!", -1);

	// prepare source image buffer
	// Although the program is capable of reading and writing
	// any common bit format, while in memory, it only supports
	// 8bit and 32bit for transformations.
	SrcImage.rowbytes = SrcImage.width;
	if (SrcImage.bpp > 8) SrcImage.rowbytes <<= 2; // *4 bytes per pixel
	SrcImage.rowbytes = ((SrcImage.rowbytes+3) & ~3); // align to dwords
	SrcImage.bytes = SrcImage.rowbytes * SrcImage.height;
	SrcImage.pixels = malloc(SrcImage.bytes);
	if (!SrcImage.pixels)
		ExitWithMsg("Not enough memory for source image!", 8);
	ImageRowsSetForward(&SrcImage);

	printf(	"Reading source image...\n" );

	// load source image
	switch (SrcFile.type) {
	case ImageType_bmp:
		// use the raw loading code since bitmaps are so simple
		// can't simply use the Windows function LoadImage because
		// it loads them all UPSIDE down. Retarded format.

		// continue reading from last file position, just before palette
		ReadFile(ImageFd, &SrcImage.pal, SrcImage.palsize*4, &dummy, NULL);
		if (dummy < SrcImage.palsize*4) {
			CloseHandle(ImageFd);
			ExitWithMsg("Bitmap palette is corrupt (too small)", -1);
		}
		ImageRowsSetBackward(&SrcImage);
		ReadSrcImageData();
		break;

	case ImageType_raw:
		SetFilePointer(ImageFd, SrcFile.ofs,NULL, FILE_BEGIN);
		ReadSrcImageData();
		break;

	case ImageType_png:
	{
		png_colorp palette;
		if ( png_get_PLTE(png_ptr, info_ptr, &palette, &SrcImage.palsize) ) {
			ConvertRgbToBgr(&SrcImage.pal, palette, SrcImage.palsize);
		}
		else {
			SrcImage.palsize = 0;
		}

		if (png_bit_depth < 8)
			png_set_packing(png_ptr);
		if ( (png_color_type & ~PNG_COLOR_MASK_ALPHA ) == PNG_COLOR_TYPE_RGB) {
			if (png_bit_depth > 8)
				png_set_strip_16(png_ptr);
			// else png_bit_depth == 8
			if ((ArgFlags & ArgFlagAlpha) && (png_color_type & PNG_COLOR_MASK_ALPHA))
				png_set_strip_alpha(png_ptr);
			png_set_filler(png_ptr, SrcFile.alpha & 65535, PNG_FILLER_AFTER);
			png_set_bgr(png_ptr);
		}
		//if (bit_depth == 16)
		//	png_set_swap(png_ptr);

		png_read_image(png_ptr, SrcImage.rows);

		png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);
		break;
	  }
	}

	CloseHandle(ImageFd);

	printf(	" Palette size: %d entries\n",
			SrcImage.palsize
			);

////////////////////////////////////////////////////////////////////////////////
// Do transforms here

	// hack to display image for now
	{
		HWND hwnd = GetDesktopWindow();
		HDC hdc = GetDCEx(hwnd, NULL, DCX_WINDOW|DCX_LOCKWINDOWUPDATE|DCX_CACHE);
		struct {
			BITMAPINFOHEADER bmih;
			RGBQUAD bmic[256];
		} DibInfo;
		DibInfo.bmih.biSize = 40;
		DibInfo.bmih.biWidth = SrcImage.width;
		DibInfo.bmih.biHeight = -SrcImage.height;
		DibInfo.bmih.biPlanes = 1;
		DibInfo.bmih.biBitCount = (SrcImage.bpp <= 8) ? 8:32;
		DibInfo.bmih.biCompression = 0;
		DibInfo.bmih.biSizeImage = (SrcImage.width*SrcImage.height*SrcImage.bpp) >> 3;
		//DibInfo.bmih.biXPelsPerMeter = ; nobody cares
		//DibInfo.bmih.biYPelsPerMeter = ;
		DibInfo.bmih.biClrUsed = SrcImage.palsize;
		DibInfo.bmih.biClrImportant = SrcImage.palsize;
		memcpy(&DibInfo.bmic, SrcImage.pal, sizeof(SrcImage.pal));

		SetDIBitsToDevice(hdc,	0,0, SrcImage.width,SrcImage.height,
								0,0, 0,SrcImage.height, SrcImage.pixels,
								(BITMAPINFO*)&DibInfo, DIB_RGB_COLORS);
		//Rectangle(hdc, 0,0, 320,240);
		ReleaseDC(hwnd, hdc);
	}


	// none yet

////////////////////////////////////////////////////////////////////////////////
// End here if preview only

	if (!DestFile.name[0])
		ExitWithMsg("No destination file created", 0);

////////////////////////////////////////////////////////////////////////////////
// Set destination file with default attributes

	if (DestImage.bpp > 0 || DestImage.format >= 0)
		SetDefaultImageFormat(&DestImage);

	// each one must be checked individually in case
	// user overrode one with command line argument.
	// otherwise it would be safe to solely use the SrcImage values.
	if (DestImage.bpp <= 0) DestImage.bpp = SrcImage.bpp;
	if (DestImage.format < 0) DestImage.format = SrcImage.format;
	if (DestImage.width <= 0 || DestImage.width > SrcImage.width)
		DestImage.width = SrcImage.width;
	if (DestImage.height <= 0 || DestImage.height > SrcImage.height)
		DestImage.height = SrcImage.height;

	DestImage.rowbytes = ((DestImage.width+3) & ~3); // align to dwords
	if (DestImage.bpp > 8) DestImage.rowbytes <<= 2; // *4 bytes per pixel
	DestImage.bytes = DestImage.height * DestImage.rowbytes;
	DestImage.palsize = SrcImage.palsize;
	if (!DestImage.pixels) DestImage.pixels = SrcImage.pixels; // share pointer for now

	ImageRowsSetForward(&DestImage);

////////////////////////////////////////////////////////////////////////////////
// true color <-> indexed conversion if necessary

	if ((SrcImage.bpp <= 8 && DestImage.bpp > 8) // promote colors
	 || (SrcImage.bpp > 8 && DestImage.bpp <= 8)) { // demote colors
		int row;

		DestImage.pixels = malloc(DestImage.bytes);
		if (!DestImage.pixels)
			ExitWithMsg("Not enough memory for destination image!", 8);

		// read in each row and expand to 8bit or 32bit
		for (row=0; row < DestImage.height; row++) {
			if (DestImage.bpp > 8) // promote colors
				ConvertIndexedToRgb(DestImage.rows[row], SrcImage.rows[row], DestImage.width, SrcImage.pal);
			else // demote colors
				ConvertRgbToIndexed(DestImage.rows[row], SrcImage.rows[row], DestImage.width, SrcImage.pal);
		}
	}


////////////////////////////////////////////////////////////////////////////////
// Write destination file

	printf(	"Writing destination image...\n" );

	ImageFd = CreateFile(
				DestFile.name,
				GENERIC_WRITE, 0,
				NULL,
				CREATE_ALWAYS, FILE_FLAG_SEQUENTIAL_SCAN,
				NULL);
	if (ImageFd == INVALID_HANDLE_VALUE)
		ExitWithMsg("Destination image could not be created", GetLastError());

	switch (DestFile.type) {
	case ImageType_bmp:
	{
		// does not read OS/2 Presentation manager bitmaps
		struct {
			#pragma pack(push, 1) // for byte alignment
			BITMAPFILEHEADER bfh;
			BITMAPINFOHEADER bmih;
			#pragma pack(pop)     // for original alignment
		} BitmapHeader = {
			{ 'MB', 0, 0,0, 44 },
			{
				sizeof(BITMAPINFOHEADER),
				DestImage.width,
				DestImage.height,
				1,
				DestImage.bpp,
				0, // no compression
				0, // forget calcing size
				1,1,
				DestImage.palsize,DestImage.palsize
			}
		};
		WriteFile(ImageFd, &BitmapHeader, sizeof(BitmapHeader), &dummy, NULL);
		WriteFile(ImageFd, &SrcImage.pal, SrcImage.palsize*4, &dummy, NULL);
		//if (dummy < SrcImage.palsize*4) {
		//	CloseHandle(ImageFd);
		//	ExitWithMsg("Bitmap palette could not be written", -1);
		//}
		if (DestFile.align < 4) DestFile.align=4;
		ImageRowsSetBackward(&DestImage);
		WriteDestImageData();
		break;
	}
	case ImageType_raw:
		SetFilePointer(ImageFd, DestFile.ofs,NULL, FILE_BEGIN);
		WriteFile(ImageFd, SrcImage.pixels, SrcImage.bytes, &dummy, NULL);
		//WriteDestImageData();
		break;

	case ImageType_png:
		break;

	case ImageType_zlg:
		SetFilePointer(ImageFd, DestFile.ofs,NULL, FILE_BEGIN);
		DestImage.bytes = SrcImage.bytes + 1024;
		DestImage.pixels = malloc(DestImage.bytes);
		if (!DestImage.pixels)
			ExitWithMsg("Not enough memory for compressed buffer!", 8);
		compress2(DestImage.pixels, &DestImage.bytes, SrcImage.pixels, SrcImage.bytes, Z_BEST_COMPRESSION);
		WriteFile(ImageFd, DestImage.pixels, DestImage.bytes, &dummy, NULL);
		break;
	}

	CloseHandle(ImageFd);
}

int ExitWithMsg(char *msg, int code)
{
	printf("%s\r\n",msg);
	exit(code);
}

// callback to read a section from the file
void PngFileRead(png_structp png_ptr, png_bytep data, png_uint_32 length)
{
	//-
	//voidp read_io_ptr = png_get_io_ptr(read_ptr);
	//int t;
	//printf("png_ptr=%X data=%X length=%d\n", png_ptr, data, length);
	//MessageBox(NULL, "PngFileRead", "Raw Image", MB_OK);
	ReadFile(ImageFd, data, length, &dummy, NULL);
	//t = GetLastError();
	//printf("data=%s\n", data);
	//MessageBox(NULL, "PngFileRead", "Raw Image", MB_OK);
}

void ImageRowsSetForward(ImageData* id) {
	int row;
	char *rowptr;
	// set each row ptr to that row
	for (	row = 0, rowptr=id->pixels;
			row < id->height;
			row++, rowptr+=id->rowbytes) {
		id->rows[row] = rowptr;
	}
}

void ImageRowsSetBackward(ImageData* id) {
	int row;
	char *rowptr;
	// set each row ptr to that row
	for (	row = id->height - 1, rowptr=id->pixels;
			row >= 0;
			row--, rowptr+=id->rowbytes) {
		id->rows[row] = rowptr;
	}
}

void ReadSrcImageData() {
	char pixels[MaxImageCols*4];
	int row;
	int rowbytes = ((SrcImage.width * SrcImage.bpp)+7) >> 3;
	int rowskip = 0;

	if (SrcFile.align > 1 && (rowskip = rowbytes % SrcFile.align))
		rowskip = SrcFile.align - rowskip;

	// read in each row and expand to 8bit or 32bit
	//SetFilePointer(ImageFd, 0,NULL, FILE_BEGIN);
	for (row=0; row < SrcImage.height; row++) {
		ReadFile(ImageFd, &pixels, rowbytes, &dummy, NULL);
		//ReadFile(ImageFd, SrcImage.rows[row], rowbytes, &dummy, NULL);
		if (rowskip) {
			SetFilePointer(ImageFd, rowskip,NULL, FILE_CURRENT);
		}
		ConvertFormatFrom(SrcImage.rows[row], pixels, SrcImage.width, SrcImage.format, SrcFile.alpha);
	}
}

void WriteDestImageData() {
	char pixels[MaxImageCols*4];
	int row;
	int rowbytes = ((DestImage.width * DestImage.bpp)+7) >> 3;
	int rowskip = 0;

	if (DestFile.align > 1 && (rowskip = rowbytes % DestFile.align))
		rowskip = DestFile.align - rowskip;

	// read in each row and expand to 8bit or 32bit
	for (row=0; row < DestImage.height; row++) {
		ConvertFormatTo(DestImage.rows[row], pixels, DestImage.width, DestImage.format, DestFile.alpha);
		WriteFile(ImageFd, &pixels, rowbytes, &dummy, NULL);
		if (rowskip) {
			SetFilePointer(ImageFd, rowskip,NULL, FILE_CURRENT);
		}
	}
}

// Having either only the bitdepth or pixel format is insufficient,
// so this function determines (picks the best) one from the other.
void SetDefaultImageFormat(ImageData* id) {
	int bpp = id->bpp;
	int format = id->format;

	if (bpp < 0) {
		// format given, so infer bitdepth
		#if (PixelType_Last != 20)
			#error "Adjust this switch statement for the current number of PixelTypes"
		#endif
		switch (format) {
		case PixelType_LE1:
		case PixelType_BE1:
			bpp = 1;
			break;
		case PixelType_LE2:
		case PixelType_BE2:
			bpp = 2;
			break;
		case PixelType_LE4:
		case PixelType_BE4:	// 16 color
			bpp = 4;
			break;
		case PixelType_LE8:
		case PixelType_BE8:	// 256 color
			bpp = 8;
			break;
		case PixelType_LE16:
		case PixelType_BE16: // raw 16bit
		case PixelType_BGRA5551:
		case PixelType_RGBA5551:// 15bit with 1bit alpha
		case PixelType_BGR565:
		case PixelType_RGB565: // 16bit
			bpp = 16;
			break;
		case PixelType_BGR888:
		case PixelType_RGB888: // 24bit
			bpp = 24;
			break;
		case PixelType_LE32:
		case PixelType_BE32: // raw 32bit
		case PixelType_BGRA8888:
		case PixelType_RGBA8888:// 32bit with alpha
		default:
			bpp = 32;
			break;
		}
	}
	if (format < 0) {
		// bitdepth given, so infer format
		switch (bpp) {
		case 1:		format = PixelType_BE1;			break;
		case 2:		format = PixelType_BE2;			break;
		case 4:		format = PixelType_BE4;			break;
		case 8:		format = PixelType_BE8;			break;
		case 15:	format = PixelType_BGRA5551;	break;
		case 16:	format = PixelType_BGR565;		break;
		case 24:	format = PixelType_BGR888;		break;
		case 32:
		default:	format = PixelType_BGRA8888;	break;
		}
	}

	id->bpp = bpp;
	id->format = format;
}


		/*
	 png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING,
	  png_voidp user_error_ptr, user_error_fn, user_warning_fn);

		png_structp png_ptr = png_create_read_struct
		   (PNG_LIBPNG_VER_STRING, (png_voidp)NULL,
			NULL, NULL);
		if (!png_ptr)
			return (ERROR);

		png_infop info_ptr = png_create_info_struct(png_ptr);
		if (!info_ptr)
		{
			png_destroy_read_struct(&png_ptr,
			   (png_infopp)NULL, (png_infopp)NULL);
			return (ERROR);
		}

		png_infop end_info = png_create_info_struct(png_ptr);
		if (!end_info)
		{
			png_destroy_read_struct(&png_ptr, &info_ptr,
			  (png_infopp)NULL);
			return (ERROR);
		}


		  if (setjmp(png_jmpbuf(png_ptr)))
		{
			png_destroy_read_struct(&png_ptr, &info_ptr,
			   &end_info);
			fclose(fp);
			return (ERROR);
		}


		png_set_read_fn(png_structp read_ptr,
			voidp read_io_ptr, png_rw_ptr read_data_fn)
	   png_set_read_fn(png_ptr, (void *)user_io_ptr, user_read_fn);


		  void user_read_data(png_structp png_ptr,
    png_bytep data, png_uint_32 length);
		voidp read_io_ptr = png_get_io_ptr(read_ptr);

		void read_row_callback(png_ptr ptr, png_uint_32 row, int pass);
		{
		  // put your code here
		}

		(You can give it another name that you like instead of "read_row_callback")

		To inform libpng about your function, use

			png_set_read_status_fn(png_ptr, read_row_callback);

	*/

	/*
	PNG_TRANSFORM_STRIP_16
	PNG_TRANSFORM_PACKING
	PNG_TRANSFORM_PACKSWAP
	PNG_TRANSFORM_BGR

	 row_pointers = png_malloc(png_ptr, height*sizeof(png_bytep));
   for (int i=0; i<height, i++)
	  row_pointers[i]=png_malloc(png_ptr, width*pixel_size);
   png_set_rows(png_ptr, info_ptr, &row_pointers); 


	//png_read_png(png_ptr, info_ptr, png_transforms, NULL)


		  png_get_PLTE(png_ptr, info_ptr, &palette,
						 &num_palette);
		palette        - the palette for the file
						 (array of png_color)
		num_palette    - number of entries in the palette



    else if (png_get_PLTE(png_ptr, info_ptr, &palette, &num_palette))

  if (bit_depth == 16)
    png_set_strip_16(png_ptr);
 if (color_type & PNG_COLOR_MASK_COLOR)
  png_set_bgr(png_ptr);
png_set_filler



if (bit_depth < 8)
    png_set_packing(png_ptr);
if (color_type == PNG_COLOR_TYPE_RGB ||
    color_type == PNG_COLOR_TYPE_RGB_ALPHA)
    png_set_bgr(png_ptr);
if (bit_depth == 8 && color_type ==
    PNG_COLOR_TYPE_RGB) png_set_filler(png_ptr,
    filler, PNG_FILLER_AFTER);


png_read_image(png_ptr, row_pointers);

png_read_end(png_ptr, info_ptr);

png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);


	*/


