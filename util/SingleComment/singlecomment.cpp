// singlecomment.cpp : Defines the entry point for the console application.
//

#if 0
/* This file itself is actually a kind of unit test */
/* Old style C comment */
// New C style comment
// /* this should not be touched */

// delete white space ->    
// delete tabs ->			
/* Should crop white space inside comment      */    
/* this line should NOT be modified
   nor should this one */
/*
*/
/* */ /*
	  */
printf("/* */");
printf("\"/* */");
printf("/*
printf("\"/*
z = z * 2 /* leave this alone */ + c
z = z * 2 /* leave this alone too */ + c /* but do get this one */
#endif

#include "stdhdr.h"

void stripTrailingSpace(char* str);

int _tmain(int argc, _TCHAR* argv[])
{
	char line[4096];
	bool done = false;

	if (argc <= 1) {
		printf(
			"SingleComment 1.0 - Dwayne Robinson 20051129\n"
			"Converts old C source code with /* */ comments\n"
			"to C99 or C++ single line comments.\n"
			"\n"
			"Usage: singlecomment file\n"
			"\n"
			"If you want to read from the console, use 'con'\n"
			"It will stop at the end of the piped file or ctrl+Z/D\n"
			);
		return 1;
	}
	FILE* fp = fopen(argv[1], "r");
	if (fp == null) {
		printf("Could not open input file \"%s\"\n", argv[1]);
		return 2;
	}
	while (!done && fgets(line, elmsof(line), fp) != null) {

		// kill CR/LF
		char* pos;
		pos = strchr(line, '\r'); if (pos != null) pos[0] = '\0';
		pos = strchr(line, '\n'); if (pos != null) pos[0] = '\0';

		stripTrailingSpace(line);

		// search for comments like /* ... */
		pos = line;
		char chr;
		char* commentStart = null;
		char* commentEnd = null;
		do {
			chr = *pos++;
			bool inComment = false;
			switch (chr) {
			case '"':
				inComment ^= true; // toggle
				break;
			case '\\':
				if (pos[0] == '"') pos++; // skip quotation mark escape sequence
				break;
			case '/': // if comment opener
				if (!inComment) {
					if (pos[0] == '*') {
						commentStart = pos-1;
						pos++; // skip comment
					}
					else if (pos[0] == '/') { // single line comment started
						chr = 0;
					}
				}
				break;
			case '*': // if comment closer
				if (!inComment) {
					if (pos[0] == '/') {
						// only if end of line, since things like this are possible:
						// z = z^2 /* complex number */ + c;
						// forcing such a line to single line comment form would strip the +c
						if (commentStart != null && pos[1] == '\0') {
							// replace with single line comment
							commentEnd = pos-1;
							commentStart[0] = '/';
							commentStart[1] = '/';
							if (commentStart[2] == '*') {
								commentStart[2] = '/';
								// added later to prevent lines for Doxygen
								// from being ignored "/** brief comment */"
								// turning them into  "/// brief comment"
							}
							commentStart = null; // reset
							commentEnd[0] = '\0';
							chr = 0;
						} else {
							pos++; // skip comment
						}
					}
				}
				break;
			case 4:	// ctrl+d
			case 27: // ctrl+z, escape
				done = true;
				break;
			}
		} while (chr);

		stripTrailingSpace(line);

		printf("%s\n", line);
	}
	return 0;
}


void stripTrailingSpace(char* str)
{
	// strip line of any trailing whitespace
	int idx = (int) strlen(str)-1; // start at last character
	while (idx >= 0 && (str[idx] == ' ' || str[idx] == '\t')) {
		str[idx] = '\0';
		idx--;
	}
}
