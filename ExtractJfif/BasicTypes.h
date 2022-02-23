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

// surprisingly, this essential primitive is sometimes undefined on systems
#ifndef   null
  # ifdef __cplusplus
    #  define null 0
  # else
    #  define null ((void *)0)
  # endif
#endif
#ifndef  NULL
  # define NULL null
#endif

// these two should also have been defined from the very beginning of C
#ifndef __cplusplus
  #ifndef true
    #define true  1
    #define false 0
  #endif
#endif

#define elif else if

// Just indicators of parameter direction. They evaluate empty.
//    in - only needs to read (not the same as const though)
//    out - do not read, only write to
//    inout - both read and write
// These specifiers are mainly for documentation. They do not force
// the parameters passing to that mode. Passing an out parameter by
// value will not cause a copy out (since C does not support copy on
// return, it must be passed via address with either * or &).
// Similarly, an in value can still be modified on the local side,
// but it's value will not change the caller's version. So in is not
// the same as const.
#ifndef IN
#define IN
#define OUT
#define INOUT
#endif

#ifndef T
#if defined(UNICODE) || defined(_UNICODE)
  #define T(string) L##string
#else
  #define T(string) string
#endif
#endif

#define elmsof(element) sizeof(element)/sizeof(element[0])

#define extc extern "C"

#ifdef __cplusplus
#  define sfree(ptr) ::free(ptr); ptr=null;
#  define smalloc(type,elms) (type*) ::malloc((elms)*sizeof(type));
#  define srealloc(ptr,type,elms) (type*) ::realloc((ptr),(elms)*sizeof(type));
#else
#  define sfree(ptr) free(ptr); ptr=null;
#  define smalloc(type,elms) (type*) malloc((elms)*sizeof(type));
#  define srealloc(ptr,type,elms) (type*) realloc((ptr),(elms)*sizeof(type));
#endif

#endif // BASICTYPES_H
