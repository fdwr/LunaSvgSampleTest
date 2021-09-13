/**
\file	stringex.h
\author	Dwayne Robinson
\date	2005-09-02
\since	2004-03-10
\remark	I know these work for ANSI, but I haven't verified all of them
		yet with Unicode :-/
*/

#ifndef stringex_h
#define stringex_h

#include <tchar.h>

#ifdef __cplusplus
extern "C" {
#endif

int strparse(TCHAR* string, TCHAR* words[], int wordsmax);
int strjoin(TCHAR* string, TCHAR* words[], int wordsmax, int strmax);
int strmatch(const TCHAR* string, const TCHAR* matches);
int strmatchn(const TCHAR* string, const TCHAR* matches);
TCHAR* strfilename(const TCHAR* filename);
TCHAR* strfileext(const TCHAR* filename);
TCHAR* strncpyex(TCHAR* dest, const TCHAR* src, int strmax);

#ifdef __cplusplus
}
#endif

#endif
