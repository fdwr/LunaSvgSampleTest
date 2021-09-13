// *** Use JPEGDump instead of this quick hack ***
// Attempts to extract JPEGs from larger archives
// by looking for JFIF streams contained within.

#include "std.h"
#include "basictypes.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <tchar.h>

////////////////////////////////////////////////////////////////
FILE* NextOutputFile();
int ScanForSignatures(FILE* infp);
int ExtractJPEG(uint8* inbuf, int inpos, int size);
extern "C" void FatalError(TCHAR* msg, ...);

////////////////////////////////////////////////////////////////
int nextFileNumber = 0;

////////////////////////////////////////////////////////////////
int main(int argc, char* argv[])
{
	//printf("Hello World!\n");
	if (argc < 2)
		FatalError(T("No source filename supplied\n"));

	FILE* infp = fopen(argv[1], "rb");
	if (infp == null)
		FatalError(T("Could not open source filename \"%s\"\n"), argv[1]);

	ScanForSignatures(infp);

	fclose(infp);
	return 0;
}


int ScanForSignatures(FILE* infp)
{
	int filesExtracted = 0;

	uint8* inbuf;

	fseek( infp, 0, SEEK_END );
	int insize = ftell(infp);
	rewind(infp);

	// allocate memory to contain the whole file.
	// and copy the file into the buffer.
	inbuf = (uint8*) malloc(insize+1);
	if (inbuf == null) FatalError("Could not allocate enough memory for file buffer. File could be too large?");
	fread( inbuf,1, insize,infp);
	inbuf[insize] = '\0';

	int inpos = 0;
	int matched = 0;
	insize -= 4;

	while (inpos < insize) {
		switch( inbuf[inpos] ) {
		case 0xFF:
			switch (matched) {
			case 2:
				matched = 3;
				//inpos = ExtractJPEG(inbuf, inpos-2, insize);
				break;
			default:
				matched = 1;
				break;
			}
			break;
		case 0xD8:
			if (matched == 1) matched = 2;
			break;
		case 0xE0:
			if (matched == 3) {
				matched = 0;
				inpos = ExtractJPEG(inbuf, inpos-3, insize);
				filesExtracted++;
			}
			break;
		default:
			matched = 0;
			break;
		}
		inpos++;
	}

	free(inbuf);

	return filesExtracted;
}


int ExtractJPEG(uint8* inbuf, int inpos, int insize)
{
	FILE* outfp = NextOutputFile();
	if (outfp == null) FatalError("Could not open next file for output.");

	fwrite(&inbuf[inpos], 2, 1, outfp);
	inpos+=2;
	while (inpos < insize) {
		if ( *(uint16*)(inbuf+inpos) == 0xD9FF ) 
			break;

		int length = inbuf[inpos+3] | (inbuf[inpos+2] << 8);
		if (length == 0) break;
		fwrite(&inbuf[inpos], length+2, 1, outfp);
		inpos += length+2;
	}
	uint8 eos[2] = {0xFF, 0xD9};
	fwrite(eos, 2, 1, outfp);
	fclose(outfp);

	/*if (outsize > elmsof(outbuf)-256) {
		fwrite(outbuf, outsize, 1, outfp);
		outsize = 0;
	}*/



	return inpos;
}


FILE* NextOutputFile()
{
	TCHAR fileName[1024];
	sprintf(fileName, "out%04d.jpg", nextFileNumber);
	FILE* fp = fopen(fileName, "wb");

	if (fp != null) nextFileNumber++;

	return fp;
}


////////////////////////////////////////////////////////////////////////////////

/** Global text message logger.

\param[in]	msg		Text message.
\param[in]	...		Variable number of parameters (anything printf can handle)
*/
extern "C" void FatalError(TCHAR* msg, ...)
{
	TCHAR text[1024];
	va_list args;
	va_start(args, msg);
	_vsntprintf(text, elmsof(text), msg, args);
	text[1023] = '\0';

	// delete old lines if too long
	#ifdef _DEBUG
	//OutputDebugString(text);
	#endif
	puts("StripScript 1.0 - Dwayne Robinson\r\nStrips javascript from HTML.\r\n");
	puts(text);

	exit(-1);
}
