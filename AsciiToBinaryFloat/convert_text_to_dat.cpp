/**
Description: Quick and dirty text value to float convertor.
Author: Dwayne Robinson
Since: 2006-03-06
*/

#include "stdafx.h"
#include "float.h"

void fatality(char* msg, int error);
void fatality(char* msg);

//////////

int _tmain(int argc, _TCHAR* argv[])
{
	printf("Convert Text to Data - 1.0\nDwayne Robinson 2006-03-06\n\n");
	if (argc < 2)
		fatality("No filename supplied\n", -2);

	// open source filename
	FILE* inFp = fopen(argv[1], "r");
	if (inFp == NULL)
		fatality("Could not read source filename\n");

	// open destination filename
	TCHAR outFileName[1024];
	sprintf(outFileName, "%s.dat", argv[1]);
	FILE* outFp = fopen(outFileName, "wb");
	printf("Output filename: %s\n", outFileName);
	if (outFp == NULL)
		fatality("Could not write output filename\n");

	int height, width;

	// temp hack
	height = 105;
	width  = 201;

	// write header
	fwrite(&width, sizeof(height), 1, outFp);
	fwrite(&height, sizeof(width), 1, outFp);

	// write all data values
	float dummy = 5;
	int valueCount = 0;
	while (true) {
		float value = -FLT_MAX;
		fscanf( inFp, "%f", &value );
		if (value == -FLT_MAX) break; // eof
		fwrite( &value, sizeof(value), 1, outFp );
		valueCount++;
	}
	printf("Values converted: %d\n", valueCount);
	
	fclose(inFp);
	fclose(outFp);

	return 0;
}


void fatality(char* msg)
{
	fatality(msg, -1);
}

void fatality(char* msg, int error)
{
	printf(msg);
	fflush(NULL);
	exit(error);
}
