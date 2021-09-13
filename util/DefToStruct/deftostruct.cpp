// deftostruct.cpp : Defines the entry point for the console application.
//

#pragma once

#include <stdio.h>
#include <string.h>

// TODO: reference additional headers your program requires here

int main(int argc, char* argv[])
{
	if (argc < 2) {
		printf(
			"No input filename was given.\n"
			"\n"
			"deftostruct input.txt                                   (prints to screen)\n"
			"deftostruct input.txt > output.c                        (writes output to file)\n"
			"find \"#define WM\" winuser.h | deftostruct con > msgs.c  (pipes all windows message names)\n"
			"find \"#define VK\" winuser.h | deftostruct con | more    (pipes all virtual key codes)\n"
			"\n"
			"Use con as filename to pipe from terminal.\n"
			);
		return -1;
	}
	FILE* fp;
	if (strcmp(argv[1], "con") == 0)
		fp = stdin;	
	else
		fp = fopen(argv[1], "r");
	if (fp == NULL) {
		printf("Could not read from input file :/\n");
		return -1;
	}

	printf(
		"#include <search.h>\n"
		"#ifndef elmsof\n"
		"#define elmsof(element) (sizeof(element)/sizeof(element[0]))\n"
		"#endif\n"
		"\n"
		"struct NameValuePair {\n"
		"	TCHAR* name;\n"
		"	int value;\n"
		"};\n"
		"\n"
		"static NameValuePair names[] = {\n"
		);

	char name[256];
	char text[1024];
	int value;
	while (!feof(fp)) {
		//fscanf(fp, "%s %x\n", name, &value);
		char* status = fgets(text, sizeof(text)/sizeof(text[0]), fp);
		// break if read error
		if (!status) break;
		// skip any line shorter than a full line
		if (strlen(text) <= 8) continue;
		// skip any line not a definition
		text[7] = '\0';
		//printf("[%s]",text);
		if (strcmp(text, "#define") != 0) continue;
		// read name and value
		// skipping if only name given but no value
		if (
			sscanf(&text[7+1], "%s %X", name, &value) < 2
			)
			continue;
		
		printf("_T(\"%s\"), 0x%.4X,\n", name, value);
	}

	printf(
		"};\n"
		"\n"
		"static int NameValuePair_cmp(const int* elem1, const NameValuePair* elem2)\n"
		"{\n"
		"	if (*elem1 <  elem2->value) return -1;\n"
		"	if (*elem1 >  elem2->value) return  1;\n"
		"	return  0;\n"
		"};\n"
		"\n"
		"extern \"C\" TCHAR* NameFromValue(int index, NameValuePair* names, int count)\n"
		"{\n"
		"	NameValuePair* match = (NameValuePair*)\n"
		"		bsearch(&index, names, count, sizeof(NameValuePair),\n"
		"			(int (__cdecl *)(const void *,const void *))&NameValuePair_cmp);\n"
		"	if (match == NULL) {\n"
		"		const static TCHAR text[] = _T(\"<unknown>\");\n"
		"		return (TCHAR*)text;\n"
		"	}\n"
		"	return match->name;\n"
		"}\n"
		"\n"
		"// sample call: NameFromValue(35, names, elmsof(names));\n"
		);

	return 0;
}

