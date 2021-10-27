//+---------------------------------------------------------------------------
//
//  Contents:   Helper for enumerating files.
//
//  History:    2013-10-04   dwayner    Created
//
//----------------------------------------------------------------------------
#include "precomp.h"

#include <windows.h>
#include <string>
#include <Shlwapi.h>
#include "FileHelpers.h"


// Including ntdef.h directly can give redefinition errors depending on the
// project structure. So include the minimum needed macros if it is not
// included.

#ifndef _NTDEF_
typedef _Return_type_success_(return >= 0) LONG NTSTATUS;

#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0)
#define NT_INFORMATION(Status) ((((ULONG)(Status)) >> 30) == 1)
#define NT_WARNING(Status) ((((ULONG)(Status)) >> 30) == 2)
#define NT_ERROR(Status) ((((ULONG)(Status)) >> 30) == 3)

#define APPLICATION_ERROR_MASK       0x20000000
#define ERROR_SEVERITY_SUCCESS       0x00000000
#define ERROR_SEVERITY_INFORMATIONAL 0x40000000
#define ERROR_SEVERITY_WARNING       0x80000000
#define ERROR_SEVERITY_ERROR         0xC0000000
#endif


enum PathPartType
{
    PathPartTypeInvalid             = 0x80000000,
    PathPartTypeFileName            = 0x00000000,   // "arial.ttf" (default enum value)
    PathPartTypeMask                = 0x00000001,   // "*.ttf"
    PathPartTypeMultipleMasks       = 0x00000002,   // "*.ttf;*.ttc;*.otf"
    PathPartTypeDirectory           = 0x00000004,   // windows in "c:\windows"
    PathPartTypeDirectoryRecursion  = 0x00000008,   // ** in "c:\users\**\*.otf"
};


HRESULT ReadTextFile(const wchar_t* filename, OUT std::wstring& text)
{
    unsigned long bytesRead;
    std::vector<char> fileData;

    ////////////////////
    // Open the file handle, and read the contents.

    HANDLE file = CreateFile(
                    filename,
                    GENERIC_READ,
                    FILE_SHARE_READ,
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
        fileData.resize(fileSize);
        text.resize(fileSize);
    }
    catch (...)
    {
        return E_OUTOFMEMORY;
    }

    if (!ReadFile(file, OUT fileData.data(), fileSize, OUT &bytesRead, nullptr))
    {
        text.clear();
        return HRESULT_FROM_WIN32(GetLastError());
    }

    scopedHandle.Clear();

    ////////////////////
    // Convert UTF-8 to UTF-16.

    ConvertText(fileData, OUT text);

    return S_OK;
}


HRESULT WriteTextFile(const wchar_t* filename, const std::wstring& text)
{
    return WriteTextFile(filename, text.c_str(), static_cast<uint32_t>(text.size()));
}


HRESULT WriteTextFile(
    const wchar_t* filename,
    __in_ecount(textLength) const wchar_t* text,
    uint32_t textLength
    )
{
    unsigned long bytesWritten;
    std::vector<uint8_t> fileData;

    ////////////////////
    // Copy from text into fileData, converting UTF-16 to UTF-8.

    unsigned long fileSize = 0;

    // Estimate the file size the first call.
    int32_t charsConverted = WideCharToMultiByte(
        CP_UTF8,
        0, // no flags for UTF8 (we allow invalid characters for testing)
        (LPCWSTR)&text[0],
        int32_t(textLength),
        nullptr, // multibyteString
        0, // multibyteCount
        nullptr, // defaultChar
        nullptr  // usedDefaultChar
        );

    fileSize = charsConverted;

    try
    {
        fileData.resize(fileSize);
    }
    catch (...)
    {
        return E_OUTOFMEMORY;
    }

    // Convert UTF-8 to UTF-16.
    WideCharToMultiByte(
        CP_UTF8,
        0, // no flags for UTF8 (we allow invalid characters for testing)
        (LPCWSTR)&text[0],
        int32_t(textLength),
        OUT (LPSTR)fileData.data(),
        int32_t(fileData.size()),
        nullptr, // defaultChar
        nullptr  // usedDefaultChar
        );

    ////////////////////
    // Open the file, and write the contents.

    HANDLE file = CreateFile(
                    filename,
                    GENERIC_WRITE,
                    0, // No FILE_SHARE_READ
                    nullptr,
                    CREATE_ALWAYS,
                    FILE_FLAG_SEQUENTIAL_SCAN,
                    nullptr
                    );
    FileHandle scopedHandle(file);

    if (file == INVALID_HANDLE_VALUE)
    {
        return HRESULT_FROM_WIN32(GetLastError());
    }

    if (!WriteFile(file, fileData.data(), fileSize, OUT &bytesWritten, nullptr))
    {
        return HRESULT_FROM_WIN32(GetLastError());
    }

    return S_OK;
}


HRESULT ReadBinaryFile(const wchar_t* filename, IN OUT std::vector<uint8_t>& fileData)
{
    fileData.clear();

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
        fileData.resize(fileSize);
    }
    catch (...)
    {
        return E_OUTOFMEMORY;
    }

    if (!ReadFile(file, fileData.data(), fileSize, &bytesRead, nullptr))
    {
        fileData.clear();
        return HRESULT_FROM_WIN32(GetLastError());
    }

    return S_OK;
}


HRESULT WriteBinaryFile(
    _In_z_ const wchar_t* filename,
    _In_reads_bytes_(fileDataSize) const void* fileData,
    uint32_t fileDataSize
    )
{
    unsigned long bytesWritten;

    HANDLE file = CreateFile(
                    filename,
                    GENERIC_WRITE,
                    FILE_SHARE_DELETE | FILE_SHARE_READ,
                    nullptr,
                    CREATE_ALWAYS,
                    FILE_FLAG_SEQUENTIAL_SCAN,
                    nullptr
                    );
    FileHandle scopedHandle(file);

    if (file == INVALID_HANDLE_VALUE)
    {
        return HRESULT_FROM_WIN32(GetLastError());
    }

    if (!WriteFile(file, fileData, fileDataSize, &bytesWritten, nullptr))
    {
        return HRESULT_FROM_WIN32(GetLastError());
    }

    return S_OK;
}


HRESULT WriteBinaryFile(const wchar_t* filename, const std::vector<uint8_t>& fileData)
{
    return WriteBinaryFile(filename, fileData.data(), static_cast<uint32_t>(fileData.size()));
}


const wchar_t* FindFileNameStart(const wchar_t* fileName, const wchar_t* fileNamesEnd)
{
    const wchar_t* p = std::find(fileName, fileNamesEnd, '\0');
    while (p != fileName)
    {
        --p;
        wchar_t ch = *p;
        if (ch == '\\' || ch == '/' || ch == ':')
        {
            ++p;
            break;
        }
    }

    return p;
}


bool FileContainsWildcard(const wchar_t* fileName, const wchar_t* fileNameEnd)
{
    for (const wchar_t* p = fileName; p != fileNameEnd && *p; ++p)
    {
        wchar_t ch = *p;
        if (ch == '*' || ch == '?')
        {
            return true;
        }
    }

    return false;
}


PathPartType GetNextPathPart(
    const wchar_t* filePath,
    size_t filePathStart,
    OUT size_t* filePathPartBegin,
    OUT size_t* filePathPartEnd
    )
{
    // Retrieve the next part of the path from the given start, returning
    // the beginning, ending, and type of the path part.
    //
    // Exactly one file with full path.
    //      "c:\windows\fonts\arial.ttf"
    //
    //      "c:"            - Directory
    //      "windows"       - Directory
    //      "fonts"         - Directory
    //      "arial.ttf"     - Filename
    //
    // All font files (TrueType or OpenType) starting with 'a' in all
    // subfolders.
    //
    //      "d:\fonts\micro*\**\a*.ttf;a*.otf"
    //
    //      "d:"            - Directory
    //      "fonts"         - Directory
    //      "micro*"        - Directory Mask
    //      "**"            - Directory Recursion
    //      "a*.ttf;a*.otf" - FileName Mask
    //
    *filePathPartBegin = filePathStart;
    *filePathPartEnd   = filePathStart;

    if (filePath[filePathStart] == '\0')
        return PathPartTypeInvalid;

    PathPartType type = PathPartTypeFileName;
    size_t offset = filePathStart;

    // Skip any leading slashes.
    wchar_t ch;
    while (ch = filePath[offset], ch != '\0')
    {
        if (ch != '\\' && ch != '/')
            break;

        ++offset;
    }
    size_t offsetStart = offset;
    *filePathPartBegin = offset;

    // Read up to a slash or end of the string.
    while (ch = filePath[offset], ch != '\0')
    {
        if (ch == '\\' || ch == '/')
        {
            type = PathPartType(type | PathPartTypeDirectory);
            break;
        }
        else if (ch == '*' || ch == '?')
        {
            type = PathPartType(type | PathPartTypeMask);
        }
        else if (ch == ';')
        {
            type = PathPartType(type | PathPartTypeMultipleMasks);
        }

        ++offset;
    }

    // Set the type according to what was found.
    if (type & PathPartTypeMask)
    {
        if (type & PathPartTypeDirectory)
        {
            if (offset - offsetStart == 2
            &&  filePath[offsetStart] == '*'
            &&  filePath[offsetStart + 1] == '*')
            {
                type = PathPartType(type | PathPartTypeDirectoryRecursion);
            }
        }
    }

    *filePathPartBegin = offsetStart;
    *filePathPartEnd   = offset;

    return type;
}


void EnumerateAndAddToQueue(
    PathPartType type,
    size_t filePathFileNameBegin,
    size_t fileMaskOffset,
    IN OUT std::wstring& filePath,      // full path plus mask on input, but arbitrarily modified on output
    IN OUT std::wstring& fileNames,     // accumulated list of nul-terminated filenames
    IN OUT std::wstring& directoryQueue // accumulated list of nul-terminated subdirectories remaining to process
    )
{
    // Read all the files in from the given filePath, and appending to the
    // fileNames and directoryQueue.
    //
    // Exactly one file with full path.
    //
    //      "c:\windows\fonts\arial.ttf"
    //
    // All font files (TrueType or OpenType) starting with 'a' in all
    // subfolders.
    //
    //      "d:\fonts\micro*\**\a*.ttf;a*.otf"

    std::wstring mask;
    if (type & PathPartTypeMultipleMasks)
    {
        // If the string contains multiple wildcards separated by
        // semicolons ("*.ttf;*.otf"), which FindFirstFile doesn't
        // understand, then set the FindFirstFile file mask to a
        // wildcard, and explicitly match each filename.
        mask = filePath.substr(filePathFileNameBegin);
        filePath.resize(filePathFileNameBegin);
        filePath.push_back('*');
    }

    WIN32_FIND_DATA findData;
    HANDLE findHandle = FindFirstFile(filePath.c_str(), OUT &findData);
    if (findHandle != INVALID_HANDLE_VALUE)
    {
        bool isFullPathAlreadyStoredInQueue = false;
        do
        {
            if (type & PathPartTypeMultipleMasks)
            {
                // FindFirstFile returns all filenames, so match explicitly.
                HRESULT hr = PathMatchSpecEx(findData.cFileName, mask.c_str(), PMSF_MULTIPLE);
                if (hr != S_OK)
                {
                    continue; // Skip this one, error or S_FALSE
                }
            }

            if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
            {
                if (type & PathPartTypeDirectory)
                {
                    // Skip the unnecessary self-referential entries.
                    if (findData.cFileName[0] == '.'
                    && (findData.cFileName[1] == '.' || findData.cFileName[1] == '\0'))
                    {
                        continue;
                    }

                    if (!isFullPathAlreadyStoredInQueue)
                    {
                        // Store the full directory path into the queue for
                        // the following subdirectory names.
                        filePath.resize(filePathFileNameBegin);
                        directoryQueue.push_back('\\');
                        directoryQueue.push_back(wchar_t(fileMaskOffset + 1)); // store the offset as a wchar_t
                        directoryQueue.append(filePath);
                        directoryQueue.push_back('\0');
                        isFullPathAlreadyStoredInQueue = true;
                    }

                    // Append subdirectory name to queue.
                    directoryQueue.append(findData.cFileName);
                    directoryQueue.push_back('\0');
                }
            }
            else
            {
                if (!(type & PathPartTypeDirectory))
                {
                    // Record filename.
                    filePath.resize(filePathFileNameBegin);
                    filePath.append(findData.cFileName);
                    fileNames.append(filePath);
                    fileNames.push_back('\0');
                }
            }
        }
        while (FindNextFile(findHandle, OUT &findData));

        FindClose(findHandle);
    }
}


HRESULT EnumerateMatchingFiles(
    __in_z_opt const wchar_t* fileDirectory,
    __in_z_opt wchar_t const* originalFileMask,
    IN OUT std::wstring& fileNames
    )
{
    if (fileDirectory == nullptr)
        fileDirectory = L"";

    if (originalFileMask == nullptr)
        originalFileMask = L"*";

    std::wstring fileMask;      // file mask, combined with the file directory
    std::wstring filePath;      // current file path being enumerated
    std::wstring queuePath;     // most recent path from the queue
    std::wstring directoryQueue;// list of nul-terminated filenames

    size_t queueOffset = 0;
    size_t queueFileMaskOffset = 0;
    size_t fileMaskOffset = 0;
    size_t fileMaskPartBegin = 0;
    size_t fileMaskPartEnd = 0;

    // Combine the mask with file directory.
    fileMask.resize(MAX_PATH);
    PathCombine(&fileMask[0], fileDirectory, originalFileMask);
    fileMask.resize(wcslen(fileMask.data()));

    // Initialize the queue with the first directory to look at (it's actually empty).
    directoryQueue.push_back('\\');
    directoryQueue.push_back(wchar_t(1)); // fileMaskOffset=0+1
    directoryQueue.push_back('\0');

    // Pop an entry from the queue and read all the matching files/directories,
    // pushing any directories onto the queue.
    //
    // The queue stores a series of nul-terminated strings consisting of
    // file paths and subsequent subdirectory names. A file path starts
    // with a '\' and stores a 16-bit index value of where in the mask it
    // should continue matching from.
    //
    for (;;)
    {
        if (queueOffset >= directoryQueue.size())
            break;

        const wchar_t* queueEntryStart = &directoryQueue[queueOffset];
        const size_t queueEntryLength = wcslen(queueEntryStart);
        queueOffset += queueEntryLength + 1;

        // Reading a directory path
        if (*queueEntryStart == '\\')
        {
            queueEntryStart++;
            queueFileMaskOffset = size_t(*queueEntryStart) - 1; // Read wchar_t as size_t, number stored as character
            queueEntryStart++;
            queuePath.assign(queueEntryStart);
            filePath.assign(queuePath);
            if (!filePath.empty())
            {
                // We're just setting the current path, not enumerating subfolders yet.
                // If the file path is empty, then it's the special case of the first
                // time through the loop where the queue doesn't yet have any entries.
                continue;
            }
        }
        else
        {
            // Reading a subdirectory of the previous full directory path
            filePath.resize(queuePath.size());
            filePath.append(queueEntryStart, queueEntryLength);
            filePath.push_back('\\');
        }
        fileMaskOffset = queueFileMaskOffset;

        PathPartType type = GetNextPathPart(fileMask.data(), fileMaskOffset, OUT &fileMaskPartBegin, OUT &fileMaskPartEnd);
        while (type == PathPartTypeDirectory)
        {
            filePath.append(&fileMask[fileMaskPartBegin], fileMaskPartEnd - fileMaskPartBegin);
            filePath.push_back('\\');
            fileMaskOffset = fileMaskPartEnd;
            type = GetNextPathPart(fileMask.data(), fileMaskOffset, OUT &fileMaskPartBegin, OUT &fileMaskPartEnd);
        }

        const size_t filePathFileNameBegin = filePath.size();

        if (type & PathPartTypeDirectoryRecursion)
        {
            // Read all subdirectories in the current path.
            filePath.push_back(L'*');
            EnumerateAndAddToQueue(
                type,
                filePathFileNameBegin,
                fileMaskPartBegin,
                IN OUT filePath,
                IN OUT fileNames,
                IN OUT directoryQueue
                );
            filePath.resize(filePathFileNameBegin);

            fileMaskOffset = fileMaskPartEnd;
            type = GetNextPathPart(fileMask.data(), fileMaskOffset, OUT &fileMaskPartBegin, OUT &fileMaskPartEnd);
        }

        // Append the file or folder mask to complete the search path.
        filePath.append(&fileMask[fileMaskPartBegin], fileMaskPartEnd - fileMaskPartBegin);

        EnumerateAndAddToQueue(
            type,
            filePathFileNameBegin,
            fileMaskPartEnd,
            IN OUT filePath,
            IN OUT fileNames,
            IN OUT directoryQueue
            );
    }

    return S_OK;
}


typedef DWORD  (__stdcall RtlCompressBuffer ) (
                IN ULONG    compressionFormat,
                IN void*    sourceBuffer,
                IN ULONG    sourceBufferLength,
                OUT void*   destinationBuffer,
                IN ULONG    destinationBufferLength,
                IN ULONG    unknown,
                OUT ULONG*  destinationSize,
                IN void*    workspaceBuffer
                );
 
typedef DWORD  (__stdcall RtlDecompressBuffer )(
                IN ULONG    compressionFormat,
                OUT void*   destinationBuffer,
                IN ULONG    destinationBufferLength,
                IN void*    sourceBuffer,
                IN ULONG    sourceBufferLength,
                OUT ULONG*  actualDestinationSize
                );
 
typedef DWORD  (__stdcall RtlDecompressBufferEx )(
                IN ULONG    compressionFormat,
                OUT void*   destinationBuffer,
                IN ULONG    destinationBufferLength,
                IN void*    sourceBuffer,
                IN ULONG    sourceBufferLength,
                OUT ULONG*  actualDestinationSize,
                IN void*    workspaceBuffer
                );
 
typedef DWORD  (__stdcall RtlGetCompressionWorkSpaceSize )(
                IN ULONG    compressionFormat,
                OUT ULONG*  neededBufferSize,
                OUT ULONG*  unknown
                );


uint8_t* ReturnRecompressionDestinationBuffer(
    NTSTATUS status,
    _In_reads_bytes_(destinationBufferByteSize) uint8_t* destinationBuffer,
    _Inout_ DWORD& destinationBufferByteSize
    )
{
    // Free the buffer if any failured occurred.
    if (NT_SUCCESS(status))
    {
        uint8_t* newDestinationBuffer = (uint8_t*)realloc(destinationBuffer, destinationBufferByteSize);
        if (newDestinationBuffer != nullptr)
            destinationBuffer = newDestinationBuffer;
    }
    else
    {
        free(destinationBuffer);
        destinationBuffer = nullptr;
        destinationBufferByteSize = 0;
    }

    return destinationBuffer;
}

 
uint8_t* NtosCompressData(uint8_t* sourceBuffer, uint32_t sourceBufferSize, DWORD* dwSizeOut)
{
    *dwSizeOut = 0;
    NTSTATUS status = ERROR_SEVERITY_ERROR;
    
    const uint32_t destinationBufferSize = 16 * sourceBufferSize;
    uint8_t* destinationBuffer = (uint8_t*) malloc(destinationBufferSize);

    if (destinationBuffer != nullptr)
    {
        HANDLE hDll = LoadLibrary(L"ntdll.dll");
        if (hDll != nullptr)
        {
            RtlCompressBuffer* fRtlCompressBuffer = (RtlCompressBuffer*) GetProcAddress((HINSTANCE)hDll, "RtlCompressBuffer");
            RtlGetCompressionWorkSpaceSize* fRtlGetCompressionWorkSpaceSize = (RtlGetCompressionWorkSpaceSize*) GetProcAddress((HINSTANCE)hDll, "RtlGetCompressionWorkSpaceSize");
 
            if (fRtlCompressBuffer != nullptr && fRtlGetCompressionWorkSpaceSize != nullptr)
            {
                // We get compression workspace size
                DWORD dwRet, dwSize;
                status = (*fRtlGetCompressionWorkSpaceSize) (COMPRESSION_FORMAT_XPRESS_HUFF|COMPRESSION_ENGINE_MAXIMUM, OUT &dwSize, OUT &dwRet);
    
                if (NT_SUCCESS(status))
                {
                    void* workspace = LocalAlloc(LMEM_FIXED, dwSize);
                    if (workspace != nullptr)
                    {
                        // COMPRESS FUNCTION
                        status = (*fRtlCompressBuffer)(
                            COMPRESSION_FORMAT_XPRESS_HUFF|COMPRESSION_ENGINE_MAXIMUM, // compression format
                            sourceBuffer,
                            sourceBufferSize,
                            destinationBuffer,
                            destinationBufferSize,
                            0, // unknown chunk size?
                            OUT dwSizeOut, // new destination size 
                            IN OUT workspace
                            );
                    }
                    LocalFree(workspace);
                }
            }
        }
        FreeLibrary((HINSTANCE)hDll);
    }

    return ReturnRecompressionDestinationBuffer(status, destinationBuffer, IN OUT *dwSizeOut);
}


uint8_t* NtosDecompressData(_In_reads_bytes_(sourceBufferSize) uint8_t* sourceBuffer, uint32_t sourceBufferSize, DWORD* dwSizeOut)
{
    *dwSizeOut = 0;

    DWORD dwRet, dwSize;
    NTSTATUS status = ERROR_SEVERITY_ERROR;
    
    const uint32_t destinationBufferSize = 16 * sourceBufferSize;
    uint8_t* destinationBuffer = (uint8_t*) malloc(destinationBufferSize);

    if (destinationBuffer != nullptr)
    {
        HANDLE hDll = LoadLibrary(L"ntdll.dll");
        if (hDll != nullptr)
        {
            RtlDecompressBufferEx* fRtlDecompressBuffer = (RtlDecompressBufferEx*) GetProcAddress((HINSTANCE)hDll, "RtlDecompressBufferEx");
            RtlGetCompressionWorkSpaceSize* fRtlGetCompressionWorkSpaceSize = (RtlGetCompressionWorkSpaceSize*) GetProcAddress( (HINSTANCE)hDll, "RtlGetCompressionWorkSpaceSize");
 
            if (fRtlDecompressBuffer != nullptr && fRtlGetCompressionWorkSpaceSize != nullptr)
            {
                // We get compression workspace size
                status = (*fRtlGetCompressionWorkSpaceSize)(
                    COMPRESSION_FORMAT_LZNT1,
                    OUT &dwSize,
                    OUT &dwRet
                    );
 
                if (NT_SUCCESS(status))
                {
                    void* workspace = LocalAlloc(LMEM_FIXED, dwSize);
                    if (workspace != nullptr)
                    {
                        // DECOMPRESS FUNCTION
                        status = (*fRtlDecompressBuffer)(
                                    COMPRESSION_FORMAT_LZNT1 , // compression format
                                    destinationBuffer,
                                    destinationBufferSize,
                                    sourceBuffer,
                                    sourceBufferSize,
                                    OUT dwSizeOut,
                                    IN OUT workspace
                                    );
                    }
                    LocalFree(workspace);
                }
            }
        }
        FreeLibrary((HINSTANCE)hDll);
    }
 
    return ReturnRecompressionDestinationBuffer(status, destinationBuffer, IN OUT *dwSizeOut);
}
