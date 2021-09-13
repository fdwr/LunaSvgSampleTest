// DeleteFiles.cpp : Defines the entry point for the console application.
//

#include "precomp.h"


bool DeleteDirectory(wchar_t const* sPath);
bool IsDots(wchar_t const* str);


int wmain(int argc, wchar_t* argv[], wchar_t* envp[])
{
    void* previousRedirectionValue = nullptr;
    Wow64DisableWow64FsRedirection(OUT &previousRedirectionValue); // Want actual folder paths, not 32-bit virtualized ones.

    //if (commandLine[0] != '')
    if (argc <= 1)
        wprintf(L"Supply the path to delete.\n");
    else if (argc > 2)
        wprintf(L"Too many parameters given.\n");
    else if (!DeleteDirectory(argv[1]))
        wprintf(L"Could not delete path: %s\n", argv[1]);

    return 0;
}


uint32_t DeleteDirectory_count = 0;

bool DeleteDirectory(wchar_t const* path)
{
    HANDLE findHandle;  // file handle
    WIN32_FIND_DATA findFileData;

    wchar_t dirPath[MAX_PATH * 4];
    wchar_t fileName[MAX_PATH * 4];

    wcscpy_s(dirPath,path);
    wcscat_s(dirPath,L"\\*");    // searching all files
    wcscpy_s(fileName,path);
    wcscat_s(fileName,L"\\");

    findHandle = FindFirstFileEx(
                    dirPath,
                    FindExInfoBasic, // No short name, meaning cAlternateFileName is not generated (slightly faster).
                    &findFileData,
                    FindExSearchNameMatch,
                    nullptr,
                    FIND_FIRST_EX_LARGE_FETCH
                    );

    if (findHandle == INVALID_HANDLE_VALUE)
        return false;

    wcscpy_s(dirPath, fileName);

    bool continueSearch = true;
    while(continueSearch) // until we finds an entry
    {
        if (FindNextFile(findHandle, &findFileData))
        {
            // Skip any dots.
            wchar_t ch;
            if ((findFileData.cFileName[0] == '.') && (ch = findFileData.cFileName[1], ch == '\0' || ch == '.'))
                continue;

            wcscat_s(fileName, findFileData.cFileName);
            if((findFileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY))
            {
                // we have found a directory, recurse
                auto result = DeleteDirectory(fileName);
                wcscpy_s(fileName, dirPath);
            }
            else
            {
                if (findFileData.dwFileAttributes & FILE_ATTRIBUTE_READONLY)
                    SetFileAttributes(fileName, FILE_ATTRIBUTE_NORMAL); // change read-only file mode

                auto result = DeleteFile(fileName);
                if (!result)
                {
                    wprintf_s(L"Failed to delete file '%s'. DeleteFile error=%d\r\n", fileName, GetLastError());

                    //FindClose(findHandle); 
                    //return false;
                }                 
                wcscpy_s(fileName, dirPath);
            }

            if ((DeleteDirectory_count & 2047) == 0)
                wprintf_s(L"%d items deleted. Deleting '%s'.\r\n", DeleteDirectory_count, path);

            ++DeleteDirectory_count;
        }
        else
        {
            auto result = GetLastError();
            if (result == ERROR_NO_MORE_FILES)
            {
                // no more files there
                continueSearch = false;
            }
            else {
                // some error occured, close the handle and return FALSE
                wprintf_s(L"Failed to enumerate next file in '%s'. FindNextFile error=%d\r\n", path, GetLastError());
                FindClose(findHandle); 
                return false;
            }

        }
    }
    FindClose(findHandle);  // closing file handle

    auto result = RemoveDirectory(path);
    if (result == 0)
        wprintf_s(L"Failed to remove directory '%s'. RemoveDirectory error=%d\r\n", path, GetLastError());

    return !!result; // remove the empty directory
}
