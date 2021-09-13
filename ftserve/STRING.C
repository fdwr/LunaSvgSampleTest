///////////////////////////////////////////////////////////////////////////////
// <string.c> - Various thread safe string functions that C should have

#define NULL 0

#include <string.h>

// splits space separated words of a string into an array of strings.
//
// accepts:	string - the ASCII string to parse the space separated words of.
//				Each word will be ended by a null.
//			words - array of string ptrs to the first character of each word.
//			wordsmax - the number of elements in the words array. string ptrs
//				between the number of words actually found and the maximum
//				will be set to NULL.
// returns:	the number of words found.
int strparse(char *string, char *words[], int wordsmax)
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
int strunparse(char *string, char *words[], int wordsmax, int strmax)
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
// returns:	-1 if no match found
int strmatch(const char *string, const char *matches)
{
	int match = 0;

	while(*matches && strcmp(string, matches)) {
		match++;
		matches += (strlen(matches) + 1);
	}
	if (*matches == '\0') match = -1;
	return match;
}

// Returns a ptr to just the filename, without path
//
// accepts:	filename - the partial or fully qualified path and filename
// returns:	ptr to the filename extension
const char *strfilename(const char *filename)
{
	char chr;
	const char *strptr = filename+strlen(filename);

	while (--strptr > filename) {
		chr = *strptr;
		if (chr == '/'
		 || chr == '\\') return strptr+1;
	}
	return filename;
}
// Returns a ptr to just the extension part of a filename.
// Never returns null. Instead, if no file extension is found,
// it returns an empty string.
//
// accepts:	filename - the partial or fully qualified path and filename
// returns:	ptr to the filename extension
const char *strfileext(const char *filename)
{
	char chr;
	const char *strptr = filename+strlen(filename);

	while (--strptr > filename) {
		chr = *strptr;
		if (chr == '.') return strptr+1;
		if (chr == '/'
		 || chr == '\\')
			break;
	}
	return "";
}
