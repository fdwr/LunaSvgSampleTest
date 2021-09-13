﻿//----------------------------------------------------------------------------
//  Author:     Dwayne Robinson
//  History:    2015-06-19 Created
//----------------------------------------------------------------------------
#include "precomp.h"


bool ThrowIf(bool value, _In_opt_z_ char const* message)
{
    if (value)
        throw std::runtime_error(message != nullptr ? message : "Unexpected failure");

    return value;
}


bool TestBit(void const* memoryBase, uint32_t bitIndex) throw()
{
    return _bittest( reinterpret_cast<long const*>(memoryBase), bitIndex) != 0;
}


bool ClearBit(void* memoryBase, uint32_t bitIndex) throw()
{
    return _bittestandreset( reinterpret_cast<long*>(memoryBase), bitIndex) != 0;
}


bool SetBit(void* memoryBase, uint32_t bitIndex) throw()
{
    return _bittestandset( reinterpret_cast<long*>(memoryBase), bitIndex) != 0;
}

#if 0
void GetCommandLineArguments(_Inout_ std::u16string& commandLine)
{
    // Get the original command line argument string as a single string,
    // not the preparsed argv or CommandLineToArgvW, which fragments everything
    // into separate words which aren't really useable when you have your own
    // syntax to parse. Skip the module filename because we're only interested
    // in the parameters following it.

    // Skip the module name.
    const wchar_t* initialCommandLine = GetCommandLine();
    wchar_t ch = initialCommandLine[0];
    if (ch == '"')
    {
        do
        {
            ch = *(++initialCommandLine);
        } while (ch != '\0' && ch != '"');
        if (ch == '"')
            ++initialCommandLine;
    }
    else
    {
        while (ch != '\0' && ch != ' ')
        {
            ch = *(++initialCommandLine);
        }
    }

    // Assign it and strip any leading or trailing spaces.
    auto commandLineLength = wcslen(initialCommandLine);
    commandLine.assign(initialCommandLine, &initialCommandLine[commandLineLength]);
    TrimSpaces(IN OUT commandLine);
}
#endif
