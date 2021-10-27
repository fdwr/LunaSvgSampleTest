//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Clipboard helper.
//
//----------------------------------------------------------------------------
#include "precomp.h"

using namespace DWritePad;
using namespace DWritePad::Implementation;

namespace DWritePad { namespace Implementation { 

    class ClipboardLock
    {
        HGLOBAL lock_;
        void* memory_;

    public:
        ClipboardLock(HGLOBAL lock);
        ~ClipboardLock();

        void* MemoryBlock() { return memory_; }
    };

} }

ClipboardLock::ClipboardLock(HGLOBAL lock)
: lock_(lock), memory_(NULL)
{
    if (lock == NULL)
    {
        throw Exception::OperationFailureException<E_FAIL>();
    }
    memory_ = GlobalLock(lock);
}

ClipboardLock::~ClipboardLock()
{
    GlobalUnlock(lock_);
}

Clipboard* Clipboard::Open(bool emptyClipboard)
{
    //try emptying the clipboard
    // (since we are using a NULL window handle, emptying will cause SetClipboardData to fail, 
    //  so we have to reopen it after this process)
    if (emptyClipboard)
    {
        Clipboard clipboard;
        //clear the current clipboard contents
        EmptyClipboard();
    }

    return new Clipboard();
}

Clipboard::Clipboard()
{
    if (!OpenClipboard(NULL))
    {
        throw Exception::OperationFailureException<E_FAIL>();
    }
}

Clipboard::~Clipboard()
{
    CloseClipboard();
}

void Clipboard::CopyText(std::wstring str)
{
    //allocate the global memory object
    HGLOBAL hClipboardData = NULL;
    size_t byteSize = sizeof(wchar_t) * (str.length() + 1);
    hClipboardData = GlobalAlloc(
        GMEM_DDESHARE,
        byteSize
        );

    try
    {
        //obtain the lock and memory block from the clipoard data
        ClipboardLock lock(hClipboardData);
        if (memcpy(
            lock.MemoryBlock(),
            str.c_str(),
            byteSize
            ) == NULL)
        {
            throw Exception::OperationFailureException<E_FAIL>();
        }

        //use CF_UNICODETEXT to indicate Unicode text
        if (NULL == SetClipboardData(
            CF_UNICODETEXT,
            hClipboardData
            ))
        {
            throw Exception::OperationFailureException<E_FAIL>();
        }
    }
    catch(...)
    {
        GlobalFree(hClipboardData);
        throw;
    }
}

std::wstring Clipboard::GetText()
{
    //if UNICODE or ANSI text is available, then copy the text
    if (IsClipboardFormatAvailable(CF_UNICODETEXT) != 0)
    {
        ClipboardLock lock(GetClipboardData(CF_UNICODETEXT));
        std::wstring string(reinterpret_cast<wchar_t*>(lock.MemoryBlock()));

        return string;
    }
    else if (IsClipboardFormatAvailable(CF_TEXT) != 0)
    {
        ClipboardLock lock(GetClipboardData(CF_TEXT));
        std::string string(reinterpret_cast<char*>(lock.MemoryBlock()));
        std::wstring retString;
        retString.resize(string.length());
        for (unsigned int i = 0; i < string.length(); ++i)
        {
            retString[i] = static_cast<wchar_t>(string[i]);
        }

        return retString;
    }

    return L"";
}
