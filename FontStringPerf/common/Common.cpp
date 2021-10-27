//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Shared utility functions.
//
//----------------------------------------------------------------------------
#include "precomp.h"


bool TestBit(void const* memoryBase, size_t bitIndex) throw()
{
    return _bittest( reinterpret_cast<long const*>(memoryBase), bitIndex) != 0;
}


bool ClearBit(void* memoryBase, size_t bitIndex) throw()
{
    return _bittestandreset( reinterpret_cast<long*>(memoryBase), bitIndex) != 0;
}


bool SetBit(void* memoryBase, size_t bitIndex) throw()
{
    return _bittestandset( reinterpret_cast<long*>(memoryBase), bitIndex) != 0;
}


HRESULT CopyToClipboard(const std::wstring& text)
{
    // Copies selected text to clipboard.

    HRESULT hr = E_FAIL;

    const uint32_t textLength = static_cast<uint32_t>(text.length());
    const wchar_t* rawInputText = text.c_str();
    
    // Open and empty existing contents.
    if (!OpenClipboard(nullptr))
    {
        hr = HRESULT_FROM_WIN32(GetLastError());
    }
    else
    {
        if (!EmptyClipboard())
        {
            hr = HRESULT_FROM_WIN32(GetLastError());
        }
        else
        {
            // Allocate room for the text
            const uint32_t byteSize = sizeof(wchar_t) * (textLength + 1);
            HGLOBAL hClipboardData  = GlobalAlloc(GMEM_DDESHARE | GMEM_ZEROINIT, byteSize);

            if (hClipboardData != nullptr)
            {
                void* memory = GlobalLock(hClipboardData);
                wchar_t* rawOutputText = reinterpret_cast<wchar_t*>(memory);

                if (memory == nullptr)
                {
                    hr = HRESULT_FROM_WIN32(GetLastError());
                }
                else
                {
                    // Copy text to memory block.
                    memcpy(rawOutputText, rawInputText, byteSize);
                    rawOutputText[textLength] = '\0'; // explicit nul terminator in case there is none
                    GlobalUnlock(hClipboardData);

                    if (SetClipboardData(CF_UNICODETEXT, hClipboardData) != nullptr)
                    {
                        hClipboardData = nullptr; // system now owns the clipboard, so don't touch it.
                        hr = S_OK;
                    }
                }
                GlobalFree(hClipboardData); // free if failed (still non-null)
            }
            CloseClipboard();
        }
    }

    return hr;
}


HRESULT PasteFromClipboard(OUT std::wstring& text)
{
    // Copy Unicode text from clipboard.

    HRESULT hr = E_FAIL;

    if (!OpenClipboard(nullptr))
    {
        hr = HRESULT_FROM_WIN32(GetLastError());
    }
    else
    {
        HGLOBAL hClipboardData = GetClipboardData(CF_UNICODETEXT);

        if (hClipboardData == nullptr)
        {
            hr = HRESULT_FROM_WIN32(GetLastError());
        }
        else
        {
            // Get text and size of text.
            size_t byteSize                 = GlobalSize(hClipboardData);
            void* memory                    = GlobalLock(hClipboardData); // [byteSize] in bytes
            const wchar_t* rawText          = reinterpret_cast<const wchar_t*>(memory);
            uint32_t textLength             = static_cast<uint32_t>(wcsnlen(rawText, byteSize / sizeof(wchar_t)));

            if (memory == nullptr)
            {
                hr = HRESULT_FROM_WIN32(GetLastError());
            }
            else
            {
                try
                {
                    text.assign(rawText, textLength);
                    hr = S_OK;
                }
                catch (...)
                {
                    hr = Application::ExceptionToHResult();
                }

                GlobalUnlock(hClipboardData);
            }
        }
        CloseClipboard();
    }

    return hr;
}


HRESULT ReadTextFile(const wchar_t* filename, OUT std::wstring& text)
{
    HRESULT hr = E_FAIL;
    unsigned long bytesRead;
    std::vector<uint8_t> fileBytes;

    HANDLE file = CreateFile(
                    filename,
                    GENERIC_READ,
                    FILE_SHARE_DELETE | FILE_SHARE_READ,
                    nullptr,
                    OPEN_EXISTING,
                    FILE_FLAG_SEQUENTIAL_SCAN,
                    nullptr
                    );
    FileHandle scopedHandle(file);

    if (file == INVALID_HANDLE_VALUE)
    {
        return HRESULT_FROM_WIN32(GetLastError());
    }

    const unsigned long fileSize = GetFileSize(file, nullptr);
    try
    {
        fileBytes.resize(fileSize);
        text.resize(fileSize);
    }
    catch (...)
    {
        return Application::ExceptionToHResult();
    }

    if (!ReadFile(file, &fileBytes[0], fileSize, &bytesRead, nullptr))
    {
        text.clear();
        return HRESULT_FROM_WIN32(GetLastError());
    }

    scopedHandle.Clear();

    // Check for byte-order-mark
    const static uint8_t utf8bom[] = {0xEF,0xBB,0xBF};
    bool hasBom = fileBytes.size() >= ARRAY_SIZE(utf8bom)
                && memcmp(&fileBytes[0], utf8bom, ARRAY_SIZE(utf8bom)) == 0;

    // We only support UTF8 or ASCII.
    int32_t charsConverted = static_cast<int32_t>(fileBytes.size());
    if (hasBom)
    {
        charsConverted = MultiByteToWideChar(
            CP_UTF8,
            0, // no flags for UTF8 (we allow invalid characters for testing)
            (LPCSTR)&fileBytes[0],
            int32_t(fileBytes.size()),
            &text[0],
            int32_t(text.size())
            );
    }
    else
    {
        std::copy(fileBytes.begin(), fileBytes.end(), text.begin());
    }

    // Shrink to actual size.
    text.resize(charsConverted);

    return S_OK;
}


HRESULT ReadBinaryFile(const wchar_t* filename, IN OUT std::vector<uint8_t>& fileBytes)
{
    HRESULT hr = E_FAIL;
    unsigned long bytesRead;

    HANDLE file = CreateFile(
                    filename,
                    GENERIC_READ,
                    FILE_SHARE_DELETE | FILE_SHARE_READ,
                    nullptr,
                    OPEN_EXISTING,
                    FILE_FLAG_SEQUENTIAL_SCAN,
                    nullptr
                    );
    FileHandle scopedHandle(file);

    if (file == INVALID_HANDLE_VALUE)
    {
        return HRESULT_FROM_WIN32(GetLastError());
    }

    const unsigned long fileSize = GetFileSize(file, nullptr);
    try
    {
        fileBytes.resize(fileSize);
    }
    catch (...)
    {
        return Application::ExceptionToHResult();
    }

    if (!ReadFile(file, &fileBytes[0], fileSize, &bytesRead, nullptr))
    {
        fileBytes.clear();
        return HRESULT_FROM_WIN32(GetLastError());
    }

    return S_OK;
}


void TrimSpaces(IN OUT std::wstring& text)
{
    // Trim leading spaces
    size_t firstPos = text.find_first_not_of(L" \t");
    if (firstPos != std::string::npos && firstPos != 0)
    {
        text.erase(0, firstPos);
    }

    // Trim trailing spaces
    size_t lastPos = text.find_last_not_of(L" \t");
    if (lastPos != std::string::npos)
    {
        text.erase(lastPos+1);
    }
}
