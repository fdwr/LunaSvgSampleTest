#pragma once

// Do not include this header directly in your project, as its definitions
// will pollute yours. This is only meant for other DWrite files to include.

#include <exception>
#include <xutility>
#include <assert.h>
#include <new>
#include <algorithm>
#include ".\stdintForVc.h"

// Undefine the infuriating Windows definitions for min and max
#undef max
#undef min

#ifdef NDEBUG
  #define DWRITEX_ASSERT
#else
  #define DWRITEX_ASSERT assert
#endif

// Exit function on failing HRESULT.
#define RETURN_IF_FAILED(exp) {HRESULT hr = (exp); if (FAILED(hr)) return (hr);}

/********************************************************************************
*   Compile assertion modified from
*   http://stackoverflow.com/questions/807244/c-compiler-asserts-how-to-implement
*   2009-10-10
*
*   Validate at compile time that the predicate is true without
*   generating code. This can be used at any point in a source file
*   where typedef is legal.
* 
*   On success, compilation proceeds normally.
* 
*   On failure, attempts to typedef an array type of negative size. The
*   offending line will look like
*       typedef assertion_failed_file_h_42[-1]
*******************************************************************************/

#if defined(_MSC_VER) || defined(__GNUC__)
    // Generate a unique number in the compilation.
    #define UNIQUE_COUNTER __COUNTER__
#else
    // Not as good, since the same line in two separate headers
    // could still cause us trouble, but it should mostly work.
    #define UNIQUE_COUNTER __LINE__
#endif

// Concatenate to identifiers.
#define CONCATENATE(a,b) a##b

// todo: replace with static_assert for compilers that support C++0x.
#define COMPILE_ASSERT_IMPL(predicate, counter) typedef char CONCATENATE(assertion_failed_##__LINE__##_, counter)[(predicate) ? 1 : -1];
#define COMPILE_ASSERT(predicate) COMPILE_ASSERT_IMPL(predicate, UNIQUE_COUNTER)



namespace DWritEx
{




} // namespace DWritEx


#if defined(_MSC_VER)
__if_not_exists(nullptr)
{
    #define COMPILER_LACKS_NULLPTR
}
#elif defined(__GCC__)
    // What GCC version supports it?
    typedef __nullptr nullptr;
#else
    #define COMPILER_LACKS_NULLPTR
#endif


#ifdef COMPILER_LACKS_NULLPTR
namespace std
{
    // Sigh, still waiting for C++0x
    const class nullptr_t
    {
    public:
        template<class T>
        operator T*() const { return 0; }

        template<class T, class U>
        operator T U::*() const { return 0; }

        operator bool() const { return false; }

    private:
        void* p;

        void operator&() {}

    } nullptr = nullptr_t();

    template<class T>
    bool operator==(T* lhs, const nullptr_t rhs) { return lhs == 0; }

    template<class T>
    bool operator==(const nullptr_t lhs, T* rhs) { return rhs == 0; }

    template<class T, class U>
    bool operator==(T U::* lhs, const nullptr_t rhs) { return lhs == 0; }

    template<class T, class U>
    bool operator==(const nullptr_t lhs, T U::* rhs) { return rhs == 0; }
} // namespace std

#undef NULL
#define NULL std::nullptr

#endif
