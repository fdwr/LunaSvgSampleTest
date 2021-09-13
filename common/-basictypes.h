/*
File: basictypes.h
Project: shared
Date: 2005-04-08

Very basic data types that ensure field size consistency between compilers
and languages. Consistent size is necessary if using share libraries or
mixing with other languages like assembly.
*/

#ifndef basictypes_h
#define basictypes_h

#if defined(_MSC_VER)
 	typedef	signed __int8		int8;
 	typedef	signed __int16		int16;
 	typedef	signed __int32		int32;
 	typedef	unsigned __int8		uint8;
 	typedef	unsigned __int16	uint16;
 	typedef	unsigned __int32	uint32;
#elif defined(__MWERKS__)
 	typedef	int8_t				int8;
 	typedef	int16_t				int16;
 	typedef	int32_t				int32;
 	typedef	unsigned int8_t		uint8;
 	typedef	unsigned int16_t	uint16;
 	typedef	unsigned int32_t	uint32;
#elif defined(__GNUC__)
 	typedef	signed char			int8;
 	typedef	signed short		int16;
 	typedef	signed int			int32;
 	typedef	unsigned char		uint8;
 	typedef	unsigned short		uint16;
 	typedef	unsigned int		uint32;
#endif

#ifndef NULL
#ifdef __cplusplus
#define NULL    0
#else
#define NULL    ((void *)0)
#endif
#endif

#ifndef T
#ifdef UNICODE
  #define T(string) L##string
#else
  #define T(string) string
#endif
#endif

#define extc extern "C"

#endif // BASICTYPES_H
