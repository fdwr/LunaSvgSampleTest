#include "precomp.h"


bool DeleteDirectoryTree(/*inout*/ std::wstring& path);


int wmain(int argc, wchar_t* argv[], wchar_t* envp[])
{
    void* previousRedirectionValue = nullptr;
    Wow64DisableWow64FsRedirection(OUT &previousRedirectionValue); // Want actual folder paths, not 32-bit virtualized ones.

    if (argc <= 1)
    {
        wprintf(L"Dwayne Robinson 2016-04-13..2021-12-08\n\nDeleteFiles usage:\n    DeleteFiles d:\\olddocuments\\largefolder\n\nThis utility will forcibly try to delete readonly files,\nbut currently open files cannot be deleted.");
    }
    else if (argc > 2)
    {
        wprintf(L"Too many parameters given.\n");
    }
    else
    {
        std::wstring s(argv[1]);
        DeleteDirectoryTree(s);
    }

    return 0;
}


size_t GetFilenameOffset(std::wstring_view path)
{
    size_t filenameOffset = path.size();
    for (size_t i = filenameOffset; i-- > 0; )
    {
        wchar_t ch = path[i];
        if (ch == '/' || ch == '\\' || ch == ':')
        {
            filenameOffset = i + 1;
            break;
        }
    }
    return filenameOffset;
}

uint32_t DeleteDirectoryTree_count = 0;
uint32_t DeleteDirectoryTree_errorCount = 0;

bool DeleteDirectoryTree(/*inout*/std::wstring& path)
{
    HANDLE findHandle;  // file handle
    WIN32_FIND_DATA findFileData;

    size_t directoryLength = path.size();
    bool isDirectory = true; // Assume true until known otherwise.

    // Ensure the path has a trailing backslash if it's a directory,
    // and not a file or file mask.
    if (path.back() != '\\')
    {
        auto fileAttributes = GetFileAttributes(path.c_str());
        if (fileAttributes != INVALID_FILE_ATTRIBUTES && (fileAttributes & FILE_ATTRIBUTE_DIRECTORY))
        {
            path.append(L"\\*");
            directoryLength++; // Count the "\" (but not the "*")
        }
        else // File or file mask.
        {
            isDirectory = false;
            directoryLength = GetFilenameOffset(path);
        }
    }
    else
    {
        path.push_back(L'*'); // Already has the trailing backslash.
        // directoryLength is already correct.
    }

    findHandle = FindFirstFileEx(
                    path.c_str(),
                    FindExInfoBasic, // No short name, meaning cAlternateFileName is not generated (slightly faster).
                    &findFileData,
                    FindExSearchNameMatch,
                    nullptr,
                    FIND_FIRST_EX_LARGE_FETCH
                    );

    if (findHandle == INVALID_HANDLE_VALUE)
    {
        wprintf_s(L"No matching files found for '%s'. FindFirstFileEx error=%d\r\n", path.c_str(), GetLastError());
        return false;
    }

    while (true) // Loop until we find a directory entry.
    {
        // Skip any dot entries like the current directory "." or parent directory "..",
        // but not entries like ".vs" or "..foo".
        bool isDotEntry = false;
        if (findFileData.cFileName[0] == '.')
        {
            wchar_t ch = findFileData.cFileName[1];
            isDotEntry = (ch == '\0' || (ch == '.' && findFileData.cFileName[2] == '\0'));
        }
        if (!isDotEntry)
        {
            path.resize(directoryLength);
            path.append(findFileData.cFileName);
            if ((findFileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY))
            {
                // Attempt early deletion if empty directory or if only contains virtual files.
                path.push_back('\\');
                if (RemoveDirectory(path.c_str()) == 0)
                {
                    // Deletion failed. So recurse to delete all subfolders and files first.
                    DeleteDirectoryTree(path);
                }
            }
            else
            {
                // Remove the read only attribute (if there is one).
                if (findFileData.dwFileAttributes & FILE_ATTRIBUTE_READONLY)
                {
                    SetFileAttributes(path.c_str(), FILE_ATTRIBUTE_NORMAL);
                }

                auto result = DeleteFile(path.c_str());
                if (!result)
                {
                    ++DeleteDirectoryTree_errorCount;
                    wprintf_s(L"Failed to delete file '%s'. DeleteFile error=%d\r\n", path.c_str(), GetLastError());
                }
            }

            if ((DeleteDirectoryTree_count & 2047) == 0)
            {
                wprintf_s(L"%d items deleted. Deleting '%s'.\r\n", DeleteDirectoryTree_count, path.c_str());
            }

            ++DeleteDirectoryTree_count;
        }

        if (!FindNextFile(findHandle, &findFileData))
        {
            auto result = GetLastError();
            if (result == ERROR_NO_MORE_FILES)
            {
                // No more files to read.
                break;
            }
            else {
                // some error occured, close the handle and return FALSE
                ++DeleteDirectoryTree_errorCount;
                wprintf_s(L"Failed to enumerate next file in '%s'. FindNextFile error=%d\r\n", path.c_str(), result);
                FindClose(findHandle);
                return false;
            }
        }
    }
    FindClose(findHandle);  // closing file handle

    // Now that all the children are deleted, try to delete the containing directory.
    bool result = true;
    if (isDirectory)
    {
        result = RemoveDirectory(path.c_str());
        if (result == 0)
        {
            wprintf_s(L"Failed to delete directory '%s'. RemoveDirectory error=%d\r\n", path.c_str(), GetLastError());
        }
    }

    return !!result; // remove the empty directory
}
