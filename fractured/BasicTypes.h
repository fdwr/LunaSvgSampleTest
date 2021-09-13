/*
\file	basictypes.h
\author	Dwayne Robinson
\since	2005-04-08
\date	2005-09-18

Very basic data types that ensure field size consistency between compilers
and languages. Consistent size is necessary if using share libraries or
mixing with other languages like assembly.

Also declares several little constants that should have been added to the
core language long ago. Putting these in here reduces dependencies on
system specific header files.
*/

#pragma once
#ifndef basictypes_h
#define basictypes_h

// essential primitives every version of C should have had from day 1
#if defined(_MSC_VER)
 	typedef	unsigned int		uint;
 	typedef	unsigned __int8		byte;
 	typedef	  signed __int8		sbyte;
 	typedef	  signed __int8		int8;
 	typedef	  signed __int16	int16;
 	typedef	  signed __int32	int32;
 	typedef	unsigned __int8		ubyte;
 	typedef	unsigned __int8		uint8;
 	typedef	unsigned __int16	uint16;
 	typedef	unsigned __int32	uint32;
#elif defined(__MWERKS__)
 	typedef	unsigned int		uint;
 	typedef	  signed int8_t		byte;
 	typedef	  signed int8_t		int8;
 	typedef	  signed int16_t	int16;
 	typedef	  signed int32_t	int32;
 	typedef	unsigned int8_t		ubyte;
 	typedef	unsigned int8_t		uint8;
 	typedef	unsigned int16_t	uint16;
 	typedef	unsigned int32_t	uint32;
#elif defined(__GNUC__)
 	typedef	unsigned int		uint;
 	typedef  signed char		byte;
 	typedef  signed char		int8;
 	typedef  signed short		int16;
 	typedef	 signed int			int32;
 	typedef	unsigned char		ubyte;
 	typedef	unsigned char		uint8;
 	typedef	unsigned short		uint16;
 	typedef	unsigned int		uint32;
#endif

// These two should also have been defined from the very beginning of C.
#if !defined(__cplusplus_cli) && !defined(__cplusplus)
#ifndef true
#define true  1
#define false 0
#endif
#endif

// Surprisingly, this essential primitive is sometimes undefined on Unix systems.
// Retardly, Visual Studio 2005 highlights the reserved name but only compiles
// correctly if the CLR is included. Bjarne Stroustrup advocates it in C++.
#if !defined(__cplusplus_cli)
# if defined(__GNUC__)
#  define nullptr __null
# elif defined(__cplusplus)
#  define nullptr 0
# else
#  define nullptr ((void*)0)
# endif
#endif

#define elif else if

// Define function parameter annotation
// since Visual Studio 7 does not support
// and has no <sal.h>.
//
// Specifiers are mainly for documentation
// and usually evaluate empty unless the compiler
// has specific support for them.
//
// in    - only needs to read (not the same as const though)
// out   - no reads, only writes to
// inout - both read and write
#ifndef __in
 #if defined(_MSC_VER) && _MSC_VER >= 1400 // if at least Vis 2005
  #include "sal.h"
 #else
  #define __in
  #define __out
  #define __inout
  //#define __specstrings
 #endif
#endif

#ifndef T
#if defined(UNICODE) || defined(_UNICODE)
  #define T(string) L##string
#else
  #define T(string) string
#endif
#endif

#define elmsof(element) (sizeof(element)/sizeof(element[0]))

#define extc extern "C"

#ifdef __cplusplus
// slightly safer because you can't mix up the type cast
// or forget the sizeof() in the mutiplication.
#  define sfree(ptr) ::free(ptr); ptr=nullptr;
#  define smalloc(type,elms) (type*) ::malloc((elms)*sizeof(type));
#  define srealloc(type,ptr,elms) (type*) ::realloc((ptr),(elms)*sizeof((ptr)[0]));
#  define smemset(ptr,value,elms) ::memset(ptr,value,(elms)*sizeof((ptr)[0]));
#  define smemcpy(dest,src,elms) ::memcpy(dest,src,(elms)*sizeof((dest)[0]));
#else
#  define sfree(ptr) free(ptr); ptr=nullptr;
#  define smalloc(type,elms) (type*) malloc((elms)*sizeof(type));
#  define srealloc(type,ptr,elms) (type*) realloc((ptr),(elms)*sizeof((ptr)[0]));
#  define smemset(ptr,value,elms) memset(ptr,value,(elms)*sizeof((ptr)[0]));
#  define smemcpy(dest,src,elms) memcpy(dest,src,(elms)*sizeof((dest)[0]));
#endif

#endif // BASICTYPES_H
