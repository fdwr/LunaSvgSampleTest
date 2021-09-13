/*
\file	common.h
\author	Dwayne Robinson
\since	2005-04-08
\date	2007-02-20

Declares little macros that should have been added to the
core language long ago.
*/

#pragma once
#ifndef common_h
#define common_h

// Fix visual studio 7 bug Q167748
// http://support.microsoft.com/kb/167748/
/*
#if defined(_MSC_VER) && _MSC_VER < 1400 // if older than Vis 2005
#define for if(0);else for
#endif
*/

// Squared value
template <typename Type>
    inline Type SQR(Type  val)                  { return val * val; }
// Absolute value
template <typename Type>
    inline Type ABS(Type  val)                  { return val < (Type)0 ? -val : val; }
// Absolute difference
template <typename Type>
    inline Type DIFF(Type  a, Type  b)          { return a < b ?  b-a : a-b; }
// Minimum value
template <typename Type>
    inline Type MIN(Type  a, Type  b)           { return a < b ?    a :   b; }
// Minimum value
template <typename Type>                                    
    inline Type MIN(Type  a, Type  b, Type c)   { return a < b ? (a < c ? a : c) : (b < c ? b : c); }
// Maximum value
template <typename Type>                                    
    inline Type MAX(Type  a, Type  b)           { return a > b ?    a :   b; }
// Maximum value.
template <typename Type>
    inline Type MAX(Type  a, Type  b, Type c)	{ return a > b ? (a > c ? a : c) : (b > c ? b : c); }
// Swap values
template <typename Type>                                    
    inline void SWAP(Type& a, Type& b)          { Type tmp = a; a = b; b = tmp; }
// Swap values
template <typename Type>
    inline void SWAP_XOR(Type& a, Type& b)      { a ^= b; b ^= a; a ^= b; }

/* // avoid using with libraries that use T as a template typename
#ifndef T
#if defined(UNICODE) || defined(_UNICODE)
  #define T(string) L##string
#else
  #define T(string) string
#endif
#endif
*/

//#define extc extern "C"

#ifdef __cplusplus
// slightly safer because you can't mix up the type cast
// or forget the sizeof() in the mutiplication.
#  define safefree(ptr) ::free(ptr); ptr=nullptr;
#  define safemalloc(type,elms) (type*) ::malloc((elms)*sizeof(type));
#  define saferealloc(type,ptr,elms) (type*) ::realloc((ptr),(elms)*sizeof((ptr)[0]));
#  define safememset(ptr,value,elms) ::memset(ptr,value,(elms)*sizeof((ptr)[0]));
#  define safememcpy(dest,src,elms) ::memcpy(dest,src,(elms)*sizeof((dest)[0]));
#else
#  define safefree(ptr) free(ptr); ptr=nullptr;
#  define safemalloc(type,elms) (type*) malloc((elms)*sizeof(type));
#  define saferealloc(type,ptr,elms) (type*) realloc((ptr),(elms)*sizeof((ptr)[0]));
#  define safememset(ptr,value,elms) memset(ptr,value,(elms)*sizeof((ptr)[0]));
#  define safememcpy(dest,src,elms) memcpy(dest,src,(elms)*sizeof((dest)[0]));
#endif

// Just define this here because MSVC requires that silly
// define just for PI to be included in math.h.
#ifndef M_2PI
#define M_2PI 6.283185307179586476925286766559    // 2.0 * pi.
#endif

#endif // common_h
