/*
tchar2.h - redefinitions for generic international text functions

! anything commented is unfinished 20051130

These redefines fix the horribly inconsistent naming of C standard
library functions dealing with TCHARs.

Because they named the functions so inconsistently, they are
impossible to remember. Sometimes the 't' is a prefix, other times
a suffix, and in the worst cases, it's arbitrarily crammed between
words. Whatever the insane logic may be, it's not clear, and I don't
have time to deal with it everytime I need to recall a function's
malformed name.

They should have made it easy on everyone by simply appending
the t as a suffix like the Win32 API does.
(prefixing works too, but it's ugly)

Atoi should not have been renamed to wtoi since the 'a' stood for
alphanumeric character, not 'A'NSI.
*/

#if     _MSC_VER > 1000 /*IFSTRIP=IGN*/
#pragma once
#endif

#ifndef _INC_TCHAR2
#define _INC_TCHAR2

/* Formatted i/o */

#define printft _tprintf
#define cprintft _tcprintf
#define fprintft _ftprintf
#define sprintft _stprintf
#define scprintft _sctprintf
#define snprintft _sntprintf
#define vprintft _vtprintf
#define vfprintft _vftprintf
#define vsprintft _vstprintf
#define vscprintft _vsctprintf
#define vsnprintft _vsntprintf
#define scanft _tscanf
#define cscanft _tcscanf
#define fscanft _ftscanf
#define sscanft _stscanf
#define snscanft _sntscanf


/* Unformatted i/o */

//#define _fgettc     fgetwc
//#define _fgettchar  _fgetwchar
//#define _fgetts     fgetws
//#define _fputtc     fputwc
//#define _fputtchar  _fputwchar
//#define _fputts     fputws
//#define _cputts     _cputws
//#define _cgetts     _cgetws
//#define _gettc      getwc
//#define _gettch     _getwch
//#define _gettche    _getwche
//#define _gettchar   getwchar
//#define _getts      _getws
//#define _puttc      putwc
//#define _puttchar   putwchar
//#define _puttch     _putwch
//#define _putts      _putws
//#define _ungettc    ungetwc
//#define _ungettch   _ungetwch


/* String conversion functions */

//#define _tcstod     wcstod
//#define _tcstol     wcstol
//#define _tcstoul    wcstoul
//#define _tcstoi64   _wcstoi64
//#define _tcstoui64  _wcstoui64
#define atoft _tstof

#define itoat _itot
#define ltoat _ltot
#define ultoat _ultot
#define atoit _ttoi
#define atolt _ttol

#define atoi64t _ttoi64
#define i64toat _i64tot
#define ui64toat _ui64tot

/* String functions */

#define strcatt _tcscat
#define strchrt _tcschr
#define strcpyt _tcscpy
//#define _tcscspn    wcscspn
#define strlent _tcslen
#define strcatnt _tcsncat
#define strcpynt _tcsncpy
//#define _tcspbrk    wcspbrk
//#define _tcsrchr    wcsrchr
//#define _tcsspn     wcsspn
//#define _tcsstr     wcsstr
//#define _tcstok     wcstok
//#define _tcserror   _wcserror
//#define __tcserror  __wcserror

//#define _tcsdup     _wcsdup
//#define _tcsnset    _wcsnset
//#define _tcsrev     _wcsrev
//#define _tcsset     _wcsset

#define strcmpt _tcscmp
#define strcmpit _tcsicmp
#define strcmpnt _tcsnccmp
//#define _tcsncmp    wcsncmp
//#define _tcsncicmp  _wcsnicmp
#define strcmpnit _tcsnicmp

//#define _tcscoll    wcscoll
//#define _tcsicoll   _wcsicoll
//#define _tcsnccoll  _wcsncoll
//#define _tcsncoll   _wcsncoll
//#define _tcsncicoll _wcsnicoll
//#define _tcsnicoll  _wcsnicoll



/* Execute functions */


//#define _texecl     _wexecl
//#define _texecle    _wexecle
//#define _texeclp    _wexeclp
//#define _texeclpe   _wexeclpe
//#define _texecv     _wexecv
//#define _texecve    _wexecve
//#define _texecvp    _wexecvp
//#define _texecvpe   _wexecvpe

//#define _tspawnl    _wspawnl
//#define _tspawnle   _wspawnle
//#define _tspawnlp   _wspawnlp
//#define _tspawnlpe  _wspawnlpe
//#define _tspawnv    _wspawnv
//#define _tspawnve   _wspawnve
//#define _tspawnvp   _wspawnvp
//#define _tspawnvp   _wspawnvp
//#define _tspawnvpe  _wspawnvpe

//#define _tsystem    _wsystem


/* Time functions */


//#define _tasctime   _wasctime
//#define _tctime     _wctime
//#define _tctime64   _wctime64
//#define _tstrdate   _wstrdate
//#define _tstrtime   _wstrtime
//#define _tutime     _wutime
//#define _tutime64   _wutime64
//#define _tcsftime   wcsftime


/* Directory functions */


//#define _tchdir     _wchdir
//#define _tgetcwd    _wgetcwd
//#define _tgetdcwd   _wgetdcwd
//#define _tmkdir     _wmkdir
//#define _trmdir     _wrmdir


/* Environment/Path functions */


//#define _tfullpath  _wfullpath
//#define _tgetenv    _wgetenv
//#define _tmakepath  _wmakepath
//#define _tpgmptr    _wpgmptr
//#define _tputenv    _wputenv
//#define _tsearchenv _wsearchenv
//#define _tsplitpath _wsplitpath


/* Stdio functions */


//#define _tfdopen    _wfdopen
//#define _tfsopen    _wfsopen
//#define _tfopen     _wfopen
//#define _tfreopen   _wfreopen
//#define _tperror    _wperror
//#define _tpopen     _wpopen
//#define _ttempnam   _wtempnam
//#define _ttmpnam    _wtmpnam


/* Io functions */


//#define _taccess    _waccess
//#define _tchmod     _wchmod
//#define _tcreat     _wcreat
//#define _tfindfirst _wfindfirst
//#define _tfindfirst64   _wfindfirst64
//#define _tfindfirsti64  _wfindfirsti64
//#define _tfindnext  _wfindnext
//#define _tfindnext64    _wfindnext64
//#define _tfindnexti64   _wfindnexti64
//#define _tmktemp    _wmktemp
//#define _topen      _wopen
//#define _tremove    _wremove
//#define _trename    _wrename
//#define _tsopen     _wsopen
//#define _tunlink    _wunlink

//#define _tfinddata_t    _wfinddata_t
//#define _tfinddata64_t  __wfinddata64_t
//#define _tfinddatai64_t _wfinddatai64_t


/* Stat functions */


//#define _tstat      _wstat
//#define _tstat64    _wstat64
//#define _tstati64   _wstati64


/* Setlocale functions */


//#define _tsetlocale _wsetlocale


/* Redundant "logical-character" mappings */

//#define _tcsnccpy   wcsncpy
//#define _tcsncset   _wcsnset

//#define _tcsdec     _wcsdec
//#define _tcsinc     _wcsinc
//#define _tcsnbcnt   _wcsncnt
//#define _tcsnccnt   _wcsncnt
//#define _tcsnextc   _wcsnextc
//#define _tcsninc    _wcsninc
//#define _tcsspnp    _wcsspnp

#define strlwrt _tcslwr
#define struprt _tcsupr
//#define _tcsxfrm    wcsxfrm


/* ctype functions */


//#define _istalnum   iswalnum
//#define _istalpha   iswalpha
//#define _istascii   iswascii
//#define _istcntrl   iswcntrl
//#define _istdigit   iswdigit
//#define _istgraph   iswgraph
//#define _istlower   iswlower
//#define _istprint   iswprint
//#define _istpunct   iswpunct
//#define _istspace   iswspace
//#define _istupper   iswupper
//#define _istxdigit  iswxdigit

#define touppert _totupper
#define tolowert _totlower

//#define _istlegal(_c)   (1)
//#define _istlead(_c)    (0)
//#define _istleadbyte(_c)    (0)

#endif  /* _INC_TCHAR */
