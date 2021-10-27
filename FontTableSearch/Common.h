//----------------------------------------------------------------------------
//  Author:     Dwayne Robinson
//  History:    2015-06-19 Created
//----------------------------------------------------------------------------
#pragma once

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
#define NOMINMAX
#endif

static_assert(sizeof(wchar_t) == sizeof(char16_t), "These casts only work on platforms where wchar_t is 16 bits.");
inline wchar_t* ToWChar(char16_t* p) { return reinterpret_cast<wchar_t*>(p); }
inline wchar_t** ToWChar(char16_t** p) { return reinterpret_cast<wchar_t**>(p); }
inline wchar_t const* ToWChar(char16_t const* p) { return reinterpret_cast<wchar_t const*>(p); }
inline wchar_t const** ToWChar(char16_t const** p) { return reinterpret_cast<wchar_t const**>(p); }
inline char16_t* ToChar16(wchar_t* p) { return reinterpret_cast<char16_t*>(p); }
inline char16_t const* ToChar16(wchar_t const* p) { return reinterpret_cast<char16_t const*>(p); }
inline char16_t const** ToChar16(wchar_t const** p) { return reinterpret_cast<char16_t const**>(p); }
