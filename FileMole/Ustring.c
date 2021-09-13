// Unicode string functions, since Win 9x does not support them.
//
// Forget this: I'm just going to use UnicoWs.dll instead.
//
// Note!
//	Expects calling program to set 'unicode' variable before calling any of
//	the string functions. If Unicode is set, it will allow Windows NT to
//	perform most operations; otherwise, it does them itself.
//	Setting this variable is easy:
//
//	unicode = IsWindowUnicode(GetDesktopWindow());

//#define WINVER 0x0401
//#define _WIN32_WINDOWS 0x0401
#define WIN32_LEAN_AND_MEAN
#define NO_STRICT
#define NOGDICAPMASKS
#define NOVIRTUALKEYCODES
#define NOWINMESSAGES
#define NOWINSTYLES
#define NOSYSMETRICS
#define NOMENUS
#define NOICONS
#define NOKEYSTATES
#define NOSYSCOMMANDS
#define NORASTEROPS
#define NOSHOWWINDOW
#define OEMRESOURCE
#define NOATOM
#define NOCLIPBOARD
#define NOCOLOR
#define NOCTLMGR
#define NODRAWTEXT
#define NOGDI
#define NOKERNEL          - All KERNEL defines and routines
//#define NOUSER            - All USER defines and routines
//#define NONLS             - All NLS defines and routines
#define NOMB
#define NOMEMMGR
#define NOMETAFILE
#define NOMINMAX
#define NOMSG
#define NOOPENFILE
#define NOSCROLL
#define NOSERVICE
#define NOSOUND
#define NOTEXTMETRIC
#define NOWH
#define NOWINOFFSETS
#define NOCOMM
#define NOKANJI
#define NOHELP
#define NOPROFILER
#define NODEFERWINDOWPOS
#define NOMCX
#include <windows.h>


LONG unicode;					// OS supports unicode


// purpose:
//	Copies a Unicode string from source to destination.
//	Does only minimal ptr checking (aborts if NULL)
//
// notes:
//	Count is the maximum size of the destination buffer.
//		This includes the trailing NULL character. If you
//		are sure the destination buffer will have enough
//		space, just pass some absurdly large number.
//	The only advantage of this function is that it returns
//		a pointer to the end of the last concatenated
//		piece, which makes it more convenient for chaining
//		multiple pieces than lstrcpy. It also has the 
//		parameters in the logical order src, dest.
//
// returns:
//	ptr to end of destination string (for chaining calls)
short* StringCopy(short* src, short* dest, int count)
{
	if (src!=NULL && dest!=NULL)
		for (; count>0; src++,dest++,count--) {
			*dest=*src;
			if (*src==0) break;
		}
	return dest;
}


/*//--
static short LowerMap[256];
static BOOL GotLowerMap=0;


// gets a text mapping for lowercase letters
void GetLowerMap()
{
	if (!unicode) {
		int count;
		for (count=0; count<256; count++)
			LowerMap[count]=(short)CharLowerA((LPSTR)count);
	}
	GotLowerMap=TRUE;
}

// lowers the case of a Unicode text string
// uses the Windows NT function if supported,
// otherwise does it itself.
void StringLower (short *text)
{
	if (unicode) {				// using Win NT/XP, so allow it do the job
		CharLowerW(text);
	} else {					// using Windows 9x, so lower it manually
		short *src=text;
		short charval;

		if (!GotLowerMap) GetLowerMap();
		for (;; src++) {
			charval=*src;
			if (charval <= 255)
				if (charval==0)
					break;
				else
					*src=LowerMap[charval];
		}
	}

}*/
//#define StringLower CharLowerW


// generates a simple checksum a text string from a Unicode string,
// first converting the the text to lowercase (which has a higher ASCII
// value and diverges checksums a tad more).
//
// Expects:
//  the string is short, like a name <1k
// Returns:
//  the checksum of the text.
unsigned int StringGenerateChecksum(short* text)
{
	short lower[1024];			// create temp string space
	unsigned int count = lstrlenW(text)<<1; //*2 for Unicode

	RtlMoveMemory(lower, text, count<2046 ? count:2046);
	lower[1023]=0; //add null just in case the copy did not work
	CharLowerW(lower);

	//--debugwrite("clw=%d", GetLastError());
	//SendMessage(DbgHwnd, LB_ADDSTRING, NULL, lower);
	//debugwrite("gsc=%s", lower);

	//lstrcmpW(text,lower);
	//debugwrite("str=%d", GetLastError());
	//SendMessage(DbgHwnd, LB_ADDSTRING, NULL, debugwrite_Buffer);

__asm {
	push esi
	xor ecx,ecx
	//mov esi,offset lower
	lea esi,[lower]
	xor eax,eax
NextChar:
	rol eax,3
	add eax,ecx
	mov cx,[esi]
	add esi,2
	test ecx,ecx
	jnz NextChar
	pop esi
	}
}

/*
// compares two Unicode text strings
// uses the Windows function if supported,
// otherwise does it itself.
int StringCompareNoCase (short* src, short* dest)
{
	if (unicode)
		return CompareStringW(LOCALE_USER_DEFAULT, NORM_IGNORECASE|NORM_IGNOREWIDTH|NORM_IGNOREKANATYPE, src,-1, dest,-1);
	else
		// not implemented yet
		return 0;
}
*/
#define StringCompareNoCase(lpString1, lpString2) CompareString(LOCALE_USER_DEFAULT, NORM_IGNORECASE|NORM_IGNOREKANATYPE, lpString1, -1, lpString2, -1);
