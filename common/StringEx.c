/**
\file	stringex.c
\author	Dwayne Robinson
\since	2004-03-10
\date	2005-07-06
\brief	Extra string function that C should have (thread safe).
*/

#define NULL 0	// not always defined on some $nix's

#include <string.h>
#include <tchar.h>
#include <stringex.h>

#ifdef _WINDOWS
// If using Windows, use the API functions instead of standard
// ANSI only C. Don't bother including the WHOLE windows API though.
#ifdef UNICODE
	#define strcmp  lstrcmpW
	#define strlen  lstrlenW
	#define strncmp(s1,s2,n2) CompareStringW(0, 0, s1,-1, s2,n2)-2
	int __stdcall lstrcmpW(const short* lpString1, const short* lpString2);
	int __stdcall lstrlenW(const short* lpString);
	int __stdcall CompareStringW(unsigned long Locale, unsigned long dwCmpFlags, const short* lpString1, int cchCount1, const short* lpString2, int cchCount2);
#else
	#define strcmp  lstrcmpA
	#define strlen  lstrlenA
	#define strncmp(s1,s2,n2) CompareStringA(0, 0, s1,-1, s2,n2)-2
	int __stdcall lstrcmpA(const char* lpString1, const char*lpString2);
	int __stdcall lstrlenA(const char* lpString);
	int __stdcall CompareStringA(unsigned long Locale, unsigned long dwCmpFlags, const char* lpString1, int cchCount1, const char* lpString2, int cchCount2);
#endif // !UNICODE

#endif


/** Splits a string of space separated words into an array of strings.

\param[in]	string	ASCIIZ string to parse words.
					Each word will be ended by a null.
\param[out]	words	array of string ptrs to the first character of each word.
\param[in]	wordsmax number of elements in the words array. string ptrs
					between the number of words actually found and the maximum
					will be set to NULL.

\return		Number of words split.
*/
int strparse(TCHAR* string, TCHAR* words[], int wordsmax)
{
	int word = 0, count;
	TCHAR chr, *strptr;

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


/** Joins an array of strings into a string of space separated words.

\param[out]	string	ASCIIZ string to hold joined words.
					Each word must be ended by a null.
\param[in]	words	array of string ptrs to the first character of each word.
\param[in]	wordsmax number of elements in the words array.
\param[in]	strmax	maximum character size of buffer

\return		Number of words joined.
*/
int strjoin(TCHAR* string, TCHAR* words[], int wordsmax, int strmax)
{
	int word = 0;
	TCHAR chr, *strptr;

	if (wordsmax <= 0
	||  strmax <= 0
	||  string == NULL
	|| (strptr=words[0]) == NULL)
		return 0;

	*string = '\0';
	//printf("strunparse: string='%s' wordsmax=%d strmax=%d\n", string, wordsmax, strmax);

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

	//printf("strunparse: word=%d strmax=%d\n", word, strmax);
	return word;
}


/** Matches a string against a list and returns the match index.

\param[in]	string	ASCIIZ string to match
\param[in]	matches	list of several null separated strings, with
					the final string being double null terminated.

\return		zero based match index or -1 if no match found
*/
int strmatch(const TCHAR* string, const TCHAR* matches)
{
	int match = 0;

	while(*matches && strcmp(string, matches)) {
		match++;
		matches += (strlen(matches) + 1);
	}
	if (*matches == '\0') match = -1;
	return match;
}


/** Matches a string prefix against a list and returns the match index.
	Unlike strmatch, this matches only the prefix, meaning 'dogwood' and
	'doghouse' would both match with 'dog'. So the order of the items in
	the matches string is important. Always put the longer words first
	(otherwise they may match a shorter word first).

\param[in]	string	ASCIIZ string to match
\param[in]	matches	list of several null separated strings, with
					the final string being double null terminated.

\return		zero based match index or -1 if no match found
*/
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


/** Returns a ptr to just the filename, without any path.

\param[in]	filename	the partial or fully qualified path and filename

\return		ptr to the filename extension

Starts from the back of the string and searches forward until a separating
backslash, a colon, or the beginning of the string is encountered.
*/
TCHAR* strfilename(const TCHAR* filename)
{
	TCHAR chr;
	TCHAR const *strptr = filename+strlen(filename);

	while (--strptr > filename) {
		chr = *strptr;
		if (chr == '/'
		 || chr == '\\') return (TCHAR*)strptr+1;
	}
	return (TCHAR*)filename;
}


/** Returns a ptr to just the extension part of a filename.

\param[in]	filename	the partial or fully qualified path and filename

\return		ptr to the filename extension.
			Never returns null. Instead, if no file extension is found,
			it returns an empty string (points to end of string).
*/
TCHAR* strfileext(const TCHAR* filename)
{
	TCHAR chr;
	const TCHAR* strptr = filename+strlen(filename);
	const TCHAR* strend = strptr;

	while (--strptr > filename) {
		chr = *strptr;
		if (chr == '.') return (TCHAR*) strptr+1;
		if (chr == '/'
		 || chr == '\\')
			break;
	}
	return (TCHAR*) strend; // return empty string, pointing to end
}


/** Copies one character array to another up to bufsize elements.

\param[out]	dest	destination buffer to copy to.
\param[in]	src		source buffer to copy from. If this is null, an
					empty string will be copied to the buffer (this
					reduces the number of unnecessary if statements
					to check if something is null).
\param[in]	bufsize	size of buffer in characters (not bytes).

\return		ptr to the filename extension.
			Never returns null. Instead, if no file extension is found,
			it returns an empty string (points to end of string).

\remark		Unlike strcpy, the copy is always finitely limited.
\remark		Unlike strncpy, a terminating null will always be appended
			(even if it means truncating the string) and the remainder
			will not be padded with extra nulls.
*/
TCHAR* strncpyex(TCHAR* dest, const TCHAR* src, int bufsize)
{
	if (bufsize > 0) {
		if (src == NULL) {
			//if (dest == NULL) gpf!
			dest[0] = '\0';
		} else {
			int len = strlen(src)+1;
			len = (len < bufsize) ? len : bufsize;
			memmove(dest, src, len*sizeof(TCHAR));
		}
	}
	return dest; // return empty string, pointing to end
}
