///////////////////////////////////////////////////////////////////////////////
// <string.c> - Various thread safe string functions that C should have
// Dwayne Robinson

#define NULL 0

#include <string.h>
#include <tchar.h>

#ifdef _WINDOWS
// If using Windows, use the API functions instead of standard
// ANIS only C. Don't bother including the WHOLE windows API though.
int __stdcall lstrcmpA(const char* lpString1, const char*lpString2);
int __stdcall lstrcmpW(const short* lpString1, const short* lpString2);
int __stdcall lstrlenA(const char* lpString);
int __stdcall lstrlenW(const short* lpString);
int __stdcall CompareStringA(unsigned long Locale, unsigned long dwCmpFlags, const char* lpString1, int cchCount1, const char* lpString2, int cchCount2);
int __stdcall CompareStringW(unsigned long Locale, unsigned long dwCmpFlags, const short* lpString1, int cchCount1, const short* lpString2, int cchCount2);

#ifdef UNICODE
  #define lstrcmp  lstrcmpW
  #define lstrlen  lstrlenW
  #define CompareString CompareStringW
#else
  #define lstrcmp  lstrcmpA
  #define lstrlen  lstrlenA
  #define CompareString CompareStringA
#endif // !UNICODE

#define strlen lstrlen
#define strcmp lstrcmp
#define strncmp(s1,s2,n2) CompareString(0, 0, s1,-1, s2,n2)-2

#endif

// splits space separated words of a string into an array of strings.
//
// accepts:	string - the ASCII string to parse the space separated words of.
//				Each word will be ended by a null.
//			words - array of string ptrs to the first character of each word.
//			wordsmax - the number of elements in the words array. string ptrs
//				between the number of words actually found and the maximum
//				will be set to NULL.
// returns:	the number of words found.
int strparse(char* string, char* words[], int wordsmax)
{
	int word = 0, count;
	char chr, *strptr;

	if (string == NULL) return 0;

	strptr = string;
	while (*strptr && word < wordsmax) {
		while ((chr=*strptr) == ' ') strptr++;
		if (chr=='\0' || chr=='\n') break;
		words[word++] = strptr++;
		while ((chr=*strptr)  > ' ') strptr++;
		if (chr=='\0' || chr=='\n') break;
		*strptr++ = '\0';
	}
	for (count = word; count < wordsmax; count++) {
		words[count] = NULL;
	}		
	return word;
}

// splits space separated words of a string into an array of strings.
//
// accepts:	string - the ASCII string to parse the space separated words of.
//				Each word will be ended by a null.
//			words - array of string ptrs to the first character of each word.
//			wordsmax - the number of elements in the words array. string ptrs
//				between the number of words actually found and the maximum
//				will be set to NULL.
// returns:	the number of words found.
int strunparse(char* string, char* words[], int wordsmax, int strmax)
{
	int word = 0;
	char chr, *strptr;

	if (wordsmax <= 0
	||  strmax <= 0
	||  string == NULL
	|| (strptr=words[0]) == NULL)
		return 0;

	*string = '\0';
	///printf("strunparse: string='%s' wordsmax=%d strmax=%d\n", string, wordsmax, strmax);

	while (1) {
		chr=*strptr++;
		if (chr=='\0') {
			if (++word >= wordsmax || (strptr=words[word]) == NULL)
				break;
			chr = ' ';
		}
		if (--strmax <= 0) break;
		*string++ = chr;
	}
	*string = '\0';

	///printf("strunparse: word=%d strmax=%d\n", word, strmax);
	return word;
}

// matches a string against a list and returns the match index.
//
// accepts:	string - the ASCII string to match
//			match - list of several null separated ASCII strings
//					the final string is double null terminated
// returns:	-1 if no match found
int strmatch(const TCHAR* string, const TCHAR* matches)
{
	int match = 0;

	while(*matches && strcmp(string, matches)) {
		match++;
		matches += (lstrlen(matches) + 1);
	}
	if (*matches == '\0') match = -1;
	return match;
}

// matches a string prefix against a list and returns the match index.
//
// accepts:	string - the ASCII string to match
//			match - list of several null separated ASCII strings
//					the final string is double null terminated
// returns:	-1 if no match found
int strmatchn(const TCHAR* string, const TCHAR* matches)
{
	int match = 0, len;

	while(len = strlen(matches), *matches && strncmp(string, matches, len)) {
		match++;
		matches += len + 1;
	}
	if (*matches == '\0') match = -1;
	return match;
}

// Returns a ptr to just the filename, without path
//
// accepts:	filename - the partial or fully qualified path and filename
// returns:	ptr to the filename extension
TCHAR* strfilename(const TCHAR* filename)
{
	TCHAR chr;
	TCHAR const *strptr = filename+lstrlen(filename);

	while (--strptr > filename) {
		chr = *strptr;
		if (chr == '/'
		 || chr == '\\') return (TCHAR*)strptr+1;
	}
	return (TCHAR*)filename;
}
// Returns a ptr to just the extension part of a filename.
// Never returns null. Instead, if no file extension is found,
// it returns an empty string (points to end of string).
//
// accepts:	filename - the partial or fully qualified path and filename
// returns:	ptr to the filename extension
const TCHAR* strfileext(const TCHAR* filename)
{
	TCHAR chr;
	const TCHAR* strptr = filename+strlen(filename);

	while (--strptr > filename) {
		chr = *strptr;
		if (chr == '.') return strptr+1;
		if (chr == '/'
		 || chr == '\\')
			break;
	}
	return filename+strlen(filename); // return empty string, pointing to end
}
