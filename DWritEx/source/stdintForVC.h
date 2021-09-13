#pragma once

// Basic sized types that VC is somehow STILL missing,
// after 9 years! Anybody on the VS team could write
// this tiny little header file in < 1 hour and be done
// with it forever.
//
// Don't worry about any other compilers, since every
// other compiler in the world seems to have it.

#ifdef _MSC_VER
    __if_not_exists(int8_t)
    {
        typedef signed   __int8     int8_t;
        typedef signed   __int8     int8_t;
        typedef unsigned __int8     uint8_t;
        typedef signed   __int16    int16_t;
        typedef unsigned __int16    uint16_t;
        typedef signed   __int32    int32_t;
        typedef unsigned __int32    uint32_t;
    }
    __if_not_exists(char8_t)
    {
        typedef unsigned __int8     char8_t;    // Unicode characters should NEVER be signed
        typedef unsigned __int16    char16_t;
        typedef unsigned __int32    char32_t;
    }
#else
    // Just include the real stdint.h
    #include "stdint.h"
#endif

// Modified from Windows BaseTsd.h

#define INT8_MIN     ((int8_t)_I8_MIN)
#define INT8_MAX     _I8_MAX
#define INT16_MIN    ((int16_t)_I16_MIN)
#define INT16_MAX    _I16_MAX
#define INT32_MIN    ((int32_t)_I32_MIN)
#define INT32_MAX    _I32_MAX
#define INT64_MIN    ((int64_t)_I64_MIN)
#define INT64_MAX    _I64_MAX
#define UINT8_MAX    _UI8_MAX
#define UINT16_MAX   _UI16_MAX
#define UINT32_MAX   _UI32_MAX
#define UINT64_MAX   _UI64_MAX
