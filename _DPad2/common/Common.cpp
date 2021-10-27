//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Shared utility functions.
//
//----------------------------------------------------------------------------
#include "precomp.h"


#pragma prefast(disable:__WARNING_HARD_CODED_STRING_TO_UI_FN, "Use given title for sample app.")
#pragma prefast(disable:__WARNING_ANSI_APICALL, "We do explicitly want the ANSI version here.")


void FailProgram(__in_z const char* message, int functionResult, __in_z_opt const char* format)
{
    char buffer[1000];
    buffer[0] = 0;

    if (format == NULL)
        format = "%s\r\nError code = %X";

    StringCchPrintfA(
        buffer,
        ARRAY_SIZE(buffer),
        format,
        message,
        functionResult
        );

    MessageBoxA(
        NULL, 
        buffer,
        APPLICATION_TITLE,
        MB_OK|MB_ICONEXCLAMATION|MB_TASKMODAL
        );

    ExitProcess(functionResult);
}


void DebugLog(const wchar_t* logMessage, ...)
{
    va_list argList;
    va_start(argList, logMessage);

    wchar_t buffer[1000];
    buffer[0] = 0;
    StringCchVPrintf(
        buffer,
        ARRAY_SIZE(buffer),
        logMessage,
        argList
        );

    OutputDebugString(buffer);
}
