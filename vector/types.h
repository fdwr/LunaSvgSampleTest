/*
\file	types.h
\author	Dwayne Robinson
\since	2005-04-08
\date	2007-02-25

Very basic data types that ensure field size consistency between compilers
and languages. Consistent size is necessary if using share libraries or
mixing with other languages like assembly.
*/

#pragma once
#ifndef types_h
#define types_h

// essential primitives every version of C should have had from day 1

// common to all compilers
typedef unsigned int			uint;
typedef unsigned char			uchar;
typedef unsigned short			ushort;
typedef unsigned long			ulong;
typedef signed   char			schar;
typedef signed   short			sshort;
typedef signed   int			sint;
typedef signed   long			slong;

// compiler specific
#if defined(_MSC_VER)
 	typedef	unsigned __int8		byte;
 	typedef	  signed __int8		sbyte;
 	typedef	  signed __int8		int8;
 	typedef	  signed __int16	int16;
 	typedef	  signed __int32	int32;
 	typedef	unsigned __int8		ubyte;
 	typedef	unsigned __int8		uint8;
 	typedef	unsigned __int16	uint16;
 	typedef	unsigned __int32	uint32;
 	typedef	unsigned __int64	uint64;
#elif defined(__MWERKS__)
 	typedef	unsigned int8_t		byte;
 	typedef	  signed int8_t		sbyte;
 	typedef	  signed int8_t		int8;
 	typedef	  signed int16_t	int16;
 	typedef	  signed int32_t	int32;
 	typedef	unsigned int8_t		ubyte;
 	typedef	unsigned int8_t		uint8;
 	typedef	unsigned int16_t	uint16;
 	typedef	unsigned int32_t	uint32;
 	typedef	unsigned int64_t	uint64;
#elif defined(__GNUC__)
 	typedef unsigned char		byte;
 	typedef   signed char		sbyte;
 	typedef   signed char		int8;
 	typedef   signed short		int16;
 	typedef	  signed int		int32;
 	typedef	unsigned char		ubyte;
 	typedef	unsigned char		uint8;
 	typedef	unsigned short		uint16;
 	typedef	unsigned int		uint32;
 	//typedef	unsigned long?	uint64;
#endif

// only define this at the project level,
// otherwise different modules may have different
// structure sizes.
#ifdef SINGLE_PRECISION
typedef float  Real;
#else
typedef double Real;
#endif

// These two should also have been defined from the very beginning of C.
#if !defined(__cplusplus) && !defined(__cplusplus_cli)
//#ifndef true
//#define true  1
//#define false 0
//#endif
enum {false=0, true=1};
#endif

// Bjarne Stroustrup advocates this keyword for C++ (and wholly agree).
// Surprisingly, this essential primitive is sometimes undefined on Unix systems.
// Retardly, Visual Studio 2005 highlights the reserved name but only compiles
// correctly if the CLR is included.
#if !defined(__cplusplus_cli)
	#if defined(__GNUC__)
		#define nullptr __null
	#elif defined(__cplusplus)
		#define nullptr 0
	#else
		#define nullptr ((void*)0)
	#endif
#endif

#define elif else if

// elements of
#define elmsof(element) (sizeof(element)/sizeof(element[0]))

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
#if !defined(_MSC_VER) || _MSC_VER < 1400 // if older than Vis 2005
	#ifndef __in
		#define __in
		#define __out
		#define __inout
		//#define ...
		#define __specstrings
	#endif
#else
	#include "sal.h"
#endif

#endif // types_h
