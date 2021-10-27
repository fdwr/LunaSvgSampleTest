// FontCommandTool 1.0 (2013-10-02)
//
// Run with /? to see usage.

#include "precomp.h"


////////////////////////////////////////////////////////////////////////////////
// Misc helper functions.


#ifndef IFRDEBUG
#define IFRDEBUG(exp) {HRESULT hr = (exp); if (FAILED(hr)) {wprintf(L"Failed in %ls at %s, HR=%08X\n", __LPREFIX(__FUNCTION__), __LPREFIX( # exp ), hr); return hr;}}
#endif


void ShowError(_In_z_ const wchar_t* message);


namespace
{
    struct SetAndSaveConsoleColor
    {
        CONSOLE_SCREEN_BUFFER_INFO consoleInfo_;
        HANDLE hConsole_ = nullptr;

        SetAndSaveConsoleColor(WORD foregroundColor)
        {
            hConsole_ = GetStdHandle(STD_OUTPUT_HANDLE);
            GetConsoleScreenBufferInfo(hConsole_, &consoleInfo_);
            WORD attributes = consoleInfo_.wAttributes & 0xFFF0;
            attributes |= (foregroundColor & 0x000F);
            SetConsoleTextAttribute(hConsole_, attributes);
        }

        ~SetAndSaveConsoleColor()
        {
            SetConsoleTextAttribute(hConsole_, consoleInfo_.wAttributes);
        }
    };


    enum CommandLineParameter
    {
        CommandLineParameterNop,
        CommandLineParameterHelp,
        CommandLineParameterFontFiles,
        CommandLineParameterCreateFontCollection,
        CommandLineParameterCreateFontCollectionFaces,
        CommandLineParameterShowFontTableSizes,
        CommandLineParameterShowGlyfTableSizes,
        CommandLineParameterCompressFontFiles,
        CommandLineParameterCreateShellFontCollection,
        CommandLineParameterDrawFontFaceNames,
        CommandLineParameterProcessFontSetMetadata,
        CommandLineParameterShowFontNames,
        CommandLineParameterDWriteDllPath,
        CommandLineParameterWatchFolder,

        CommandLineParameterInvalid = -1,
    };

    struct NameToValueMapping
    {
        const wchar_t* name;
        const wchar_t* description;
        int32_t value;
    };

    const static NameToValueMapping g_commandLineCommandNames[] = {
        {L"Help", L"Displays command line parameter help", CommandLineParameterHelp},
        {L"CreateFontCollection", L"Creates font collection from path", CommandLineParameterCreateFontCollection},
        {L"CreateShellFontCollection", L"Creates font collection via shell", CommandLineParameterCreateShellFontCollection},
        {L"CreateFontCollectionFaces", L"Creates all font faces from the collection", CommandLineParameterCreateFontCollectionFaces},
        {L"ShowFontTableSizes", L"Shows the sizes of each font table", CommandLineParameterShowFontTableSizes},
        {L"ShowGlyfTableSizes", L"Shows the sizes of each font table", CommandLineParameterShowGlyfTableSizes},
        {L"CompressFontFiles", L"Compresses font files from a collection", CommandLineParameterCompressFontFiles},
        {L"DrawFontFaceNames", L"Draws each font in its own name", CommandLineParameterDrawFontFaceNames},
        {L"FontFiles", L"Specify font files to use", CommandLineParameterFontFiles},
        {L"ProcessFontSetMetadata", L"Processes fonts and exports font set JSON", CommandLineParameterProcessFontSetMetadata},
        {L"ShowFontNames", L"Displays names of all the fonts", CommandLineParameterShowFontNames},
        {L"DWriteDllPath", L"Specify the full path to the DWrite.dll to use", CommandLineParameterDWriteDllPath},
        {L"WatchFolder", L"Watch a folder path for changes in files", CommandLineParameterWatchFolder},
    };

} // namespace

int32_t GetValueFromName(
    __in_ecount(mappingsCount) const NameToValueMapping* mappings,
    uint32_t mappingsCount,
    __in_z const wchar_t* name,
    int32_t defaultValue // if not found
    )
{
    // Just a linear search and case-insensitive string match.
    for (uint32_t i = 0; i < mappingsCount; ++i)
    {
        if (_wcsicmp(name, mappings[i].name) == 0)
        {
            return mappings[i].value;
        }
    }
    return defaultValue;
}


int32_t GetValueFromName(
    __in_ecount(mappingsCount) const NameToValueMapping* mappings,
    uint32_t mappingsCount,
    __in_z const wchar_t* name,
    uint32_t nameLength,
    int32_t defaultValue // if not found
    )
{
    for (uint32_t i = 0; i < mappingsCount; ++i)
    {
        if (_wcsnicmp(name, mappings[i].name, nameLength) == 0
        &&  mappings[i].name[nameLength] == '\0')
        {
            return mappings[i].value;
        }
    }
    return defaultValue;
}


CommandLineParameter GetCommandEnumFromName(
    __in_z const wchar_t* name,
    uint32_t nameLength
    )
{
    auto value =
        GetValueFromName(
            g_commandLineCommandNames,
            ARRAY_SIZE(g_commandLineCommandNames),
            name,
            nameLength,
            /*defaultValue*/CommandLineParameterInvalid
            );
    return static_cast<CommandLineParameter>(value);
}


HRESULT CreateFontCollectionFaces(
    IDWriteFontCollection* fontCollection,
    OUT std::vector<ComPtr<IDWriteFontFace> >* fontFaces
    )
{
    // Create font faces from the entire font collection.

    if (fontCollection == nullptr)
        return E_INVALIDARG;

    for (uint32_t i = 0, ci = fontCollection->GetFontFamilyCount(); i < ci; ++i)
    {
        ComPtr<IDWriteFontFamily> fontFamily;
        IFR(fontCollection->GetFontFamily(i, OUT &fontFamily));
        if (fontFamily != nullptr)
        {
            for (uint32_t j = 0, cj = fontFamily->GetFontCount(); j < cj; ++j)
            {
                ComPtr<IDWriteFont> font;
                ComPtr<IDWriteFontFace> fontFace;

                IFR(fontFamily->GetFont(j, OUT &font));
                if (font != nullptr)
                {
                    if (font->GetSimulations() == DWRITE_FONT_SIMULATIONS_NONE) // Skip simulated ones.
                    {
                        IFR(font->CreateFontFace(OUT &fontFace));
                        if (fontFaces != nullptr)
                            fontFaces->push_back(fontFace);
                    }
                }
            }
        }
    }

    return S_OK;
}


HRESULT ShowFontNames(IDWriteFactory* dwriteFactory, IDWriteFontCollection* fontCollection)
{
    std::wstring name;

    for (uint32_t i = 0, ci = fontCollection->GetFontFamilyCount(); i < ci; ++i)
    {
        ComPtr<IDWriteFontFamily> fontFamily;
        IFR(fontCollection->GetFontFamily(i, OUT &fontFamily));
        if (fontFamily != nullptr)
        {
            ComPtr<IDWriteLocalizedStrings> familyStrings;
            familyStrings.Clear();
            fontFamily->GetFamilyNames(OUT &familyStrings);
            if (familyStrings != nullptr && familyStrings->GetCount() >= 2)
            {
                for (uint32_t j = 0, cj = familyStrings->GetCount(); j < cj; ++j)
                {
                    GetLocalizedStringLanguage(familyStrings, j, OUT name);
                    wprintf(L"%ls:", name.c_str());
                    GetLocalizedString(familyStrings, j, OUT name);
                    wprintf(L"%ls\t", name.c_str());
                }
            }

            for (uint32_t j = 0, cj = fontFamily->GetFontCount(); j < cj; ++j)
            {
                ComPtr<IDWriteFont> font;

                IFR(fontFamily->GetFont(j, OUT &font));
                if (font == nullptr || font->GetSimulations() != DWRITE_FONT_SIMULATIONS_NONE)
                    continue;

                ComPtr<IDWriteLocalizedStrings> nameStrings;
                BOOL exists;
                font->GetInformationalStrings(DWRITE_INFORMATIONAL_STRING_FULL_NAME, OUT &nameStrings, OUT &exists);
                GetLocalizedString(nameStrings, /*preferredLanguage*/nullptr, OUT name);
                wprintf(L"fullname:%ls\r\n", name.c_str());
            }
        }
    }

    return S_OK;
}


HRESULT ShowFontNames(IDWriteFactory* dwriteFactory, const std::wstring& filePaths)
{
    const wchar_t* filePath = filePaths.c_str();
    const wchar_t* filePathsEnd = filePath + filePaths.size();

    for (; filePath < filePathsEnd; filePath += wcslen(filePath) + 1)
    {
        // Read the entire file.
        //--const wchar_t* fileName = FindFileNameStart(filePath, filePathsEnd);
        //--wprintf(L"%ls\t", fileName); fflush(stdout);
        wprintf(L"%ls\t", filePath); fflush(stdout);

        ComPtr<IDWriteFontCollection> fontCollection;
        IFR(CreateFontCollection(
            dwriteFactory,
            filePath,
            static_cast<uint32_t>(wcslen(filePath) + 1),
            OUT &fontCollection
            ));

        ShowFontNames(dwriteFactory, fontCollection);
        wprintf(L"\r\n");
    }

    return S_OK;
}


// Read a single character from the standard input. If the pending event
// is not a key press, it returns 0. If there are no pending console input
// events, the function waits.
char32_t ReadStdinCharacter()
{
    INPUT_RECORD record;
    DWORD recordCount;

    if (ReadConsoleInput(GetStdHandle(STD_INPUT_HANDLE), &record, 1, &recordCount)
    &&  record.EventType == KEY_EVENT
    &&  record.Event.KeyEvent.bKeyDown)
    {
        return record.Event.KeyEvent.uChar.UnicodeChar;
    }

    return 0; // Ignore anything else that is not a key down.
}


HRESULT WatchFolderChanges(wchar_t const* filePath)
{
    std::wstring folderPath(filePath);

    // If the path contains any file name portion with wildcards,
    // then truncate the part to just the folder path.
    bool const fileNameContainsWildcards = FileContainsWildcard(folderPath.data(), folderPath.data() + folderPath.size());
    if (fileNameContainsWildcards)
    {
        wchar_t* fileNameStart = const_cast<wchar_t*>(FindFileNameStart(folderPath.data(), folderPath.data() + folderPath.size()));
        fileNameStart[0] = '\0';
    }

    FileHandle folderHandle = FindFirstChangeNotification(folderPath.c_str(), /*watchSubtree*/ false, FILE_NOTIFY_CHANGE_FILE_NAME|FILE_NOTIFY_CHANGE_DIR_NAME);
    if (folderHandle.IsNull())
    {
        HRESULT hr = HRESULT_FROM_WIN32(GetLastError());
        std::wstring errorMessage;
        GetFormattedString(OUT errorMessage, L"Could not watch folder '%ls'. FindFirstChangeNotification error=%08X.", filePath, hr);
        ShowError(errorMessage.c_str());
        return E_INVALIDARG;
    }

    // Wait for either a keypress or folder change.
    wprintf(L"Waiting for changes to '%ls'.\r\n" L"Press a key to quit.\r\n", filePath);

    HANDLE handles[2] = {GetStdHandle(STD_INPUT_HANDLE), folderHandle};
    bool shouldContinue = true;

    while (shouldContinue)
    {
        auto waitResult = WaitForMultipleObjects(ARRAY_SIZE(handles), handles, /*waitAll*/false, INFINITE);

        switch (waitResult)
        {
        case WAIT_OBJECT_0 + 0:
            // Exit if any ASCII generating key is pressed.
            {
                char32_t ch = ReadStdinCharacter();
                if (ch != 0)
                    shouldContinue = false;
            }
            break;

        case WAIT_OBJECT_0 + 1:
            {
                // Folder has changed.
                // However, we don't know if any matching files were affected yet.

                std::wstring filePaths;
                IFR(EnumerateMatchingFiles(
                        filePath,
                        fileNameContainsWildcards ? L"" : L"*", // originalFileMask
                        OUT filePaths
                        ));

                // If any matches, print all the matching filenames and make a sound.
                if (!filePaths.empty() || !fileNameContainsWildcards)
                {
                    wprintf(L"________________________________________\r\n");
                    MessageBeep(MB_ICONASTERISK);

                    uint32_t fileNameCount = 0;
                    wchar_t const* fileName = filePaths.c_str();
                    while (fileName[0] != '\0')
                    {
                        wprintf(L"%ls\r\n", fileName);
                        fileName += wcslen(fileName) + 1;
                        ++fileNameCount;
                    }

                    SYSTEMTIME systemTime;
                    GetLocalTime(OUT &systemTime);
                    wprintf(
                        L"Total files = %d, Time = %04d-%02d-%02dT%02d:%02d:%02d\r\n",
                        fileNameCount,
                        systemTime.wYear,
                        systemTime.wMonth,
                        systemTime.wDay,
                        systemTime.wHour,
                        systemTime.wMinute,
                        systemTime.wSecond
                        );
                }
            }

            FindNextChangeNotification(folderHandle);
            break;

        case WAIT_TIMEOUT:
        default: // Break if anything else.
            shouldContinue = false;
            break;
        }
    }

    return S_OK;
}


bool IsTtc(FontCheckedPtr fontPointer)
{
    // Check for TTC.
    uint32_t headerTag = fontPointer.ReadAt<OpenTypeULong>(0).GetRawInt();
    return (headerTag == DWRITE_MAKE_OPENTYPE_TAG('t','t','c','f'));
}


uint32_t GetTtfFaceCount(FontCheckedPtr fontPointer)
{
    // Check for TTC.
    if (IsTtc(fontPointer))
    {
        const auto& ttcHeader = fontPointer.ReadAt<TtcHeader>(0);
        return ttcHeader.numFonts;
    }

    return 1; // TTF, so only one font.
}


uint32_t GetTtfFileOffset(FontCheckedPtr fontPointer, uint32_t faceIndex = 0)
{
    uint32_t ttfStart = 0;
    if (IsTtc(fontPointer))
    {
        const auto& ttcHeader = fontPointer.ReadAt<TtcHeader>(0);
        faceIndex = (faceIndex >= ttcHeader.numFonts) ? 0 : faceIndex;
        ttfStart = ttcHeader.offsetTable[faceIndex];
    }

    return ttfStart;
}


bool IsRecognizedTtf(const TtfHeader& ttfHeader)
{
    return ttfHeader.version.ToInt() == 0x00010000
        || ttfHeader.version.ToInt() == DWRITE_MAKE_OPENTYPE_TAG('O','T','T','O');
}


class OpenTypeFontFaceDirectory
{
public:
    _Readable_elements_(tableCount_) OpenTypeTableRecord* tableRecords_ = nullptr;
    uint32_t tableCount_ = 0;

    OpenTypeFontFaceDirectory() = default;

    OpenTypeFontFaceDirectory(FontCheckedPtr fontPointer, uint32_t ttfStart = 0)
    {
        fontPointer += ttfStart;
        Initialize(fontPointer);
    }

    void Initialize(FontCheckedPtr fontPointer, uint32_t ttfStart = 0)
    {
        TtfHeader& ttfHeader = fontPointer.ReadAt<TtfHeader>(0);
        tableCount_ = ttfHeader.numTables;
        tableRecords_ = fontPointer.GetArrayAt<OpenTypeTableRecord>(0 + sizeof(TtfHeader), tableCount_);
    }

    uint32_t GetByteSize() const throw()
    {
        return sizeof(TtfHeader) + sizeof(OpenTypeTableRecord) * tableCount_;
    }

    // Map a file position to a table record.
    bool GetMatchingTableRecord(
        uint32_t offset,
        __out const OpenTypeTableRecord** tableRecord
        )
    {
        *tableRecord = nullptr;

        // Find the table a given offset lies within.
        for (uint32_t i = 0; i < tableCount_; ++i)
        {
            uint32_t begin = tableRecords_[i].offset;
            uint32_t end   = begin + tableRecords_[i].length;
            if (offset >= begin && offset < end)
            {
                *tableRecord = &tableRecords_[i];
                return true;
            }
        }
        return false;
    }

    // Use DWRITE_MAKE_OPENTYPE_TAG to make tableTag.
    bool FindTableWithTag(uint32_t tableTag, _Out_ uint32_t& recordIndex)
    {
        recordIndex = 0;
        for (uint32_t i = 0; i < tableCount_; ++i)
        {
            auto const& record = tableRecords_[i];
            if (record.tag == tableTag)
            {
                recordIndex = i;
                return true;
            }
        }
        return false;
    }

    static uint32_t CalculateCheckSum(const_byte_array_ref data)
    {
        size_t length = data.size();
        auto begin = reinterpret_cast<OpenTypeULong const*>(data.begin());
        auto flooredEnd = PtrAddByteOffset(begin, length & ~3);

        uint32_t sum = 0;
        auto p = begin;
        for (; p < flooredEnd; ++p)
        {
            sum += *p;
        }
        if (length & 3)
        {
            OpenTypeULong tail;
            auto residualLength = length & 3u;
            for (auto i = 0u; i < residualLength; ++i)
            {
                tail.value_[i] = p[i];
            }
            sum += tail;
        }

        return sum;
    }
};


union IsLittleEndianArchitectureData
{
    int i;
    char c[4];
};
static constexpr IsLittleEndianArchitectureData isLittleEndianArchitectureData{ 0x1 };

constexpr bool IsLittleEndianArchitecture() {
    return isLittleEndianArchitectureData.c[0] == 1;
}


class OpenTypeFontFace : public FileBlockDataEditor
{
public:
    OpenTypeFontFace(FileGraph& fileGraph, uint32_t blockIndex)
    :   FileBlockDataEditor(fileGraph, blockIndex)
    {}

    HRESULT Parse()
    {
        auto& fileBlock = GetFileBlock();

        OpenTypeFontFaceDirectory faceDirectory(FontCheckedPtr(fileBlock.data));
        tableBlockIndices_.resize(faceDirectory.tableCount_);

        // Allocate file blocks for all the tables.
        // If a table has already been allocated before for the same range,
        // due another face in a TTC also pointing to that table, then the
        // same child index is returned.
        uint32_t parentIndex = fileBlock.parent;
        uint32_t newChildIndex = 0;
        for (uint32_t tableIndex = 0; tableIndex < faceDirectory.tableCount_; ++tableIndex)
        {
            auto const& record = faceDirectory.tableRecords_[tableIndex];
            IFR(fileGraph_.AllocateFileBlock(parentIndex, newChildIndex, Range::FromCount(record.offset, record.length), OUT newChildIndex));
            fileGraph_.GetFileBlock(newChildIndex).SetAlignment(4/*bytes*/);
            tableBlockIndices_[tableIndex] = newChildIndex;
        }

        return S_OK;
    }

    // Use DWRITE_MAKE_OPENTYPE_TAG to make tableTag.
    bool FindTableWithTag(uint32_t tableTag, _Out_ uint32_t& recordIndex)
    {
        recordIndex = 0;
        auto& fileBlock = GetFileBlock();
        OpenTypeFontFaceDirectory faceDirectory(FontCheckedPtr(fileBlock.data));
        return faceDirectory.FindTableWithTag(tableTag, OUT recordIndex);
    }

    HRESULT DeleteTable(uint32_t tableDirectoryIndex)
    {
        uint32_t tableSize = static_cast<uint32_t>(tableBlockIndices_.size());
        if (tableDirectoryIndex >= tableSize)
            return E_BOUNDS;

        auto tableBlockIndex = 0;
        auto& fileBlock = GetFileBlock();

        byte_array_ref array = fileBlock.data;
        FontCheckedPtr fontPointer(array);

        // Write the new table count.
        auto& header = fontPointer.ReadAt<TtfHeader>(0);
        header.numTables = header.numTables - 1;

        // Delete the old table entry.
#if 0
        fileBlock.data.DeleteBytes(sizeof(TtfHeader) + tableDirectoryIndex * sizeof(OpenTypeTableRecord), sizeof(OpenTypeTableRecord))
#else
        array.remove_prefix(sizeof(TtfHeader));
        ShiftDataDown<OpenTypeTableRecord>(array, tableDirectoryIndex, 1);
#endif

        // Erase the corresponding block index for the table.
        tableBlockIndex = tableBlockIndices_[tableDirectoryIndex];
        tableBlockIndices_.erase(tableBlockIndices_.begin() + tableDirectoryIndex);

        fileBlock.data.ShrinkBy(sizeof(OpenTypeTableRecord));

        // Indicate this block is dirty, and mark the table block is deletable.
        fileGraph_.SetFlags(blockIndex_, FileBlock::FlagsStaleDataAndSize);
        fileGraph_.SetFlags(tableBlockIndex, FileBlock::FlagsIsDeletable);
    }

    // Link an existing OpenTypeFont table to this face.
    // Use DWRITE_MAKE_OPENTYPE_TAG to make tableTag.
    HRESULT InsertExistingTable(uint32_t tableTag, uint32_t tableBlockIndex)
    {
        uint32_t tableSize = static_cast<uint32_t>(tableBlockIndices_.size());
        uint32_t tableDirectoryIndex = GetTableDirectoryIndex(tableTag);
        if (tableDirectoryIndex > tableSize)
            return E_BOUNDS;

        auto& fileBlock = GetFileBlock();
        auto& tableFileBlock = fileGraph_.GetFileBlock(tableBlockIndex);

        // Write the new table count.
        tableBlockIndices_.reserve(tableBlockIndices_.size() + 1);

        // Insert the new table entry.
        OpenTypeTableRecord record = {};
        record.tag = tableTag;
        record.length = tableFileBlock.data.size();
        fileBlock.data.InsertBytes(sizeof(TtfHeader) + tableDirectoryIndex * sizeof(OpenTypeTableRecord), const_byte_array_ref::wrap(record));

        // Write the new table count.
        FontCheckedPtr fontPointer(fileBlock.data);
        auto& header = fontPointer.ReadAt<TtfHeader>(0);
        header.numTables = header.numTables + 1;

        // Keep track of the corresponding block index for the newly added table.
        tableBlockIndices_.insert(tableBlockIndices_.begin() + tableDirectoryIndex, tableBlockIndex);

        // Indicate this block is dirty.
        fileGraph_.SetFlags(blockIndex_, FileBlock::FlagsStaleDataAndSize);

        return S_OK;
    }

    uint32_t GetTableDirectoryCount()
    {
        return uint32_t(tableBlockIndices_.size());
    }

    static bool IsTagLess(uint32_t a, uint32_t b) throw()
    {
        if (IsLittleEndianArchitecture())
        {
            return reinterpret_cast<OpenTypeULong&>(a) < reinterpret_cast<OpenTypeULong&>(b);
        }
        else
        {
            return a < b;
        }
    }

    uint32_t GetTableDirectoryIndex(uint32_t tableTag)
    {
        auto& fileBlock = GetFileBlock();
        OpenTypeFontFaceDirectory faceDirectory(FontCheckedPtr(fileBlock.data));

        uint32_t tableIndex = 0;
        for ( ; tableIndex < faceDirectory.tableCount_; ++tableIndex)
        {
            auto const& record = faceDirectory.tableRecords_[tableIndex];
            if (IsTagLess(tableTag, record.tag))
            {
                break;
            }
        }
        return tableIndex;
    }

    virtual HRESULT UpdateData()
    {
        auto& fileBlock = GetFileBlock();
        OpenTypeFontFaceDirectory faceDirectory(FontCheckedPtr(fileBlock.data));

        uint32_t tableCount = faceDirectory.tableCount_;
        std::vector<uint32_t> orderIndices(tableCount);
        std::vector<OpenTypeTableRecord> tableRecords(tableCount);
        std::vector<uint32_t> fileBlockIndices(tableCount);

        // Order all table records by tag in alphabetic order.
        std::iota(orderIndices.begin(), orderIndices.end(), 0);
        std::sort(
            orderIndices.begin(),
            orderIndices.end(),
            [&](uint32_t a, uint32_t b) -> bool { return IsTagLess(faceDirectory.tableRecords_[a].tag, faceDirectory.tableRecords_[b].tag);}
            );

        // Zero the head table's checkSumAdjustment value.
        uint32_t headRecordIndex;
        if (FindTableWithTag(DWRITE_MAKE_OPENTYPE_TAG('h', 'e', 'a', 'd'), OUT headRecordIndex))
        {
            auto& tableBlock = fileGraph_.GetFileBlock(tableBlockIndices_[headRecordIndex]);
            FontHeader& headTable = FontCheckedPtr(tableBlock.data).ReadAt<FontHeader>(0);
            headTable.checkSumAdjustment = 0;
        }

        // Reorder the table records and block indices, copying all the
        // records to a separate block of memory temporarily in the new
        // order.
        for (uint32_t i = 0; i < tableCount; ++i)
        {
            uint32_t index = orderIndices[i];
            uint32_t fileBlockIndex = tableBlockIndices_[i];
            fileBlockIndices[i] = fileBlockIndex;
            auto& tableBlock = fileGraph_.GetFileBlock(fileBlockIndex);

            auto& tableDirectoryRecord = tableRecords[i];
            MemMove(OUT tableDirectoryRecord, faceDirectory.tableRecords_[index]);
            tableDirectoryRecord.offset = tableBlock.range.begin;
            tableDirectoryRecord.length = tableBlock.range.GetCount();
            tableDirectoryRecord.checkSum = OpenTypeFontFaceDirectory::CalculateCheckSum(tableBlock.data);
        }

        // Copy the reordered table records back over the data block.
        MemMoveCount(OUT faceDirectory.tableRecords_, tableRecords.data(), tableCount);
        std::swap(tableBlockIndices_, fileBlockIndices);

        return S_OK;
    }

    std::vector<uint32_t> tableBlockIndices_;
};


class OpenTypeFont : public FileBlockDataEditor
{
public:
    OpenTypeFont(FileGraph& fileGraph, uint32_t blockIndex)
    :   FileBlockDataEditor(fileGraph, blockIndex)
    {}

    HRESULT Parse()
    {
        auto& fileBlock = GetFileBlock();

        FontCheckedPtr fontPointer(fileBlock.data);
        uint32_t const faceCount = GetTtfFaceCount(fontPointer);

        faceBlockIndices_.reserve(faceCount);

        // Read the TTC header if present.
        uint32_t newChildIndex = 0;
        if (IsTtc(fontPointer))
        {
            // This tool does not understand anything except version 1.
            // So rewrite the header back out as v1 so we don't write
            // back out invalid bytes.
            TtcHeader& ttcHeader = fontPointer.ReadAt<TtcHeader>(0);
            if (ttcHeader.version != 0x00010000)
            {
                ttcHeader.version = 0x00010000;
                
            }
            uint32_t const ttcHeaderSize = offsetof(TtcHeader, offsetTable) + sizeof(OpenTypeTableRecord) * faceCount;
            IFR(fileGraph_.AllocateFileBlock(blockIndex_, newChildIndex, Range::FromCount(0, ttcHeaderSize), OUT newChildIndex));
        }

        // Allocate file blocks for each face's table directory.
        for (uint32_t faceIndex = 0; faceIndex < faceCount; ++faceIndex)
        {
            uint32_t const ttfOffset = GetTtfFileOffset(fontPointer, faceIndex);
            OpenTypeFontFaceDirectory fontTableDirectory(fontPointer, ttfOffset);
            auto ttfHeaderSize = fontTableDirectory.GetByteSize();

            IFR(fileGraph_.AllocateFileBlock(blockIndex_, newChildIndex, Range::FromCount(ttfOffset, ttfHeaderSize), OUT newChildIndex));
            faces_.emplace_back(fileGraph_, newChildIndex);
            faceBlockIndices_.push_back(newChildIndex);
        }

        for (uint32_t faceIndex = 0; faceIndex < faceCount; ++faceIndex)
        {
            auto& fontFace = faces_[faceIndex];
            IFR(fontFace.Parse());
        }

        return S_OK;
    }

    // Insert a table, without adding it to any specific face.
    HRESULT InsertTable(_Out_ uint32_t& tableBlockIndex)
    {
        tableBlockIndex = 0;
        IFR(fileGraph_.InsertFileBlock(blockIndex_, /*insertAfter*/true, OUT tableBlockIndex));
        auto& fileBlock = fileGraph_.GetFileBlock(tableBlockIndex);
        fileBlock.SetAlignment(4/*bytes*/);

        return S_OK;
    }

    // Use DWRITE_MAKE_OPENTYPE_TAG to make tableTag.
    HRESULT InsertTable(uint32_t faceIndex, uint32_t tableTag, _Out_ uint32_t& tableBlockIndex)
    {
        tableBlockIndex = 0;
        if (faceIndex >= faces_.size())
            return E_BOUNDS;

        OpenTypeFontFace& fontFace = faces_[faceIndex];
        IFR(InsertTable(OUT tableBlockIndex));
        IFR(fontFace.InsertExistingTable(tableTag, tableBlockIndex));

        return S_OK;
    }

    virtual HRESULT PreUpdateData()
    {
        for (auto& face : faces_)
        {
            IFR(face.PreUpdateData());
        }
        IFR(fileGraph_.RealignBlocks(blockIndex_));
        return S_OK;
    }

    virtual HRESULT UpdateData()
    {
        // Update the data of each face.
        for (auto& face : faces_)
        {
            IFR(face.UpdateData());
        }

        // Adjust the offsets to each face within a collection.
        FileBlock& fileBlock = GetFileBlock();
        FontCheckedPtr fontPointer(fileBlock.data);
        if (IsTtc(fontPointer))
        {
            auto& ttcHeader = fontPointer.ReadAt<TtcHeader>(0);

            for (uint32_t faceIndex = 0, faceCount = uint32_t(faces_.size()); faceIndex < faceCount; ++faceIndex)
            {
                uint32_t faceBlockIndex = faceBlockIndices_[faceIndex];
                FileBlock& faceBlock = fileGraph_.GetFileBlock(faceBlockIndex);
                ttcHeader.offsetTable[faceIndex] = faceBlock.range.begin;
            }
        }

        return S_OK;
    }

    uint32_t GetFontFaceCount() const throw()
    {
        return uint32_t(faces_.size());
    }

    OpenTypeFontFace& GetFontFace(uint32_t faceIndex)
    {
        if (faceIndex >= faces_.size())
            throw std::out_of_range("faceIndex is greater than faces_ size");

        return faces_[faceIndex];
    }

    std::vector<OpenTypeFontFace> faces_;
    std::vector<uint32_t> faceBlockIndices_;
};


class OpenTypeMetaTableEditor : public FileBlockDataEditor
{
public:
    OpenTypeMetaTableEditor(FileGraph& fileGraph, uint32_t blockIndex)
    :   FileBlockDataEditor(fileGraph, blockIndex)
    {}

    static HRESULT Create(OpenTypeFont& fontFace, uint32_t faceIndex, RefCountPtr<OpenTypeMetaTableEditor>& metaTableEditor)
    {
        uint32_t tableBlockIndex = 0;
        IFR(fontFace.InsertTable(faceIndex, DWRITE_MAKE_OPENTYPE_TAG('m', 'e', 't', 'a'), OUT tableBlockIndex));
        auto& fileBlock = fontFace.fileGraph_.GetFileBlock(tableBlockIndex);
        MetaTableHeader header = {};
        header.version = 1;
        header.flags = 0;
        header.dataOffset = sizeof(header);
        header.dataMapsCount = 0;
        fileBlock.data.InsertBytes(0, const_byte_array_ref::wrap(header));
        fontFace.fileGraph_.SetFlags(tableBlockIndex, FileBlock::FlagsStaleDataAndSize);
        metaTableEditor = new OpenTypeMetaTableEditor(fontFace.fileGraph_, tableBlockIndex);
        return S_OK;
    }

    HRESULT InsertMap(uint32_t tag, const_byte_array_ref mapData)
    {
        // https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6meta.html
        auto& fileBlock = GetFileBlock();
        {
            FontCheckedPtr fontPointer(fileBlock.data);
            auto& header = fontPointer.ReadAt<MetaTableHeader>(0);
            uint32_t dataOffset = std::max(uint32_t(header.dataOffset), sizeof(MetaTableHeader));
            uint32_t metaRecordOffset = sizeof(MetaTableHeader) + header.dataMapsCount * sizeof(MetaTableRecord);
            uint32_t mapDataOffset = fileBlock.data.size() - dataOffset; // Convert from offset in the table to data-block relative.
            MetaTableRecord record = {};
            record.tag = tag;
            record.dataOffset = mapDataOffset;
            record.dataLength = mapData.size();

            fileBlock.data.InsertBytes(metaRecordOffset, const_byte_array_ref::wrap(record));
            fileBlock.data.append(mapData);
        }

        {
            FontCheckedPtr fontPointer = fileBlock.data;
            auto& header = fontPointer.ReadAt<MetaTableHeader>(0);
            header.dataMapsCount = header.dataMapsCount + 1;
        }

        return S_OK;
    }

    // todo:::
    // https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6meta.html
};


struct FontTableEntry
{
    uint32_t offset;
    uint32_t length;
};


class CustomShellFontFileStream : public ComBase<IDWriteFontFileStream>
{
    #define CUSTOM_SHELL_FONT_FILE_STREAM_SHOW_READS

protected:
    ComPtr<IStream> stream_;
    uint8_t* streamMemory_ = nullptr;
    uint64_t streamMemorySize_ = 0;
    const wchar_t* fileName_ = nullptr;
    #ifdef CUSTOM_SHELL_FONT_FILE_STREAM_SHOW_READS
    OpenTypeFontFaceDirectory fontTableDirectory_;
    #endif

protected:
    IFACEMETHODIMP QueryInterface(IID const& iid, __out void** object) OVERRIDE
    {
        COM_BASE_RETURN_INTERFACE(iid, IDWriteFontFileStream, object);
        COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
        COM_BASE_RETURN_NO_INTERFACE(object);
    }

public:
    CustomShellFontFileStream()
    { }

    HRESULT Initialize(IStream* stream, __in_z const wchar_t* fileName)
    {
        if (stream == nullptr)
            return E_INVALIDARG;

        fileName_ = FindFileNameStart(fileName, fileName + wcslen(fileName));
        stream_ = stream;

        // Get the stream size.
        LARGE_INTEGER zeroFilePosition = {0};
        ULARGE_INTEGER fileSize = {0};
        stream->Seek(zeroFilePosition, STREAM_SEEK_END, OUT &fileSize);
        streamMemorySize_ = static_cast<uint64_t>(fileSize.QuadPart);
        stream->Seek(zeroFilePosition, STREAM_SEEK_SET, nullptr);

        // Allocate space for later file reads, equal to the file size.
        streamMemory_ = reinterpret_cast<uint8_t*>(malloc(size_t(streamMemorySize_)));
        if (streamMemory_ == nullptr)
            return E_OUTOFMEMORY; // This is the only exception type we need to worry about.

        #ifdef CUSTOM_SHELL_FONT_FILE_STREAM_SHOW_READS
        // Read the first 8KB, which should be more than enough 
        IFR(ReadFileFragment(0, std::min(uint64_t(8192), streamMemorySize_)));
        auto fontPointer = FontCheckedPtr(streamMemory_, uint32_t(streamMemorySize_));
        uint32_t ttfStart = GetTtfFileOffset(fontPointer);
        if (ttfStart > 4096u)
            IFR(ReadFileFragment(ttfStart, std::min(uint64_t(8192u), streamMemorySize_ - ttfStart)));
        fontPointer += ttfStart;
        fontTableDirectory_.Initialize(fontPointer);
        #endif

        return S_OK;
    }

    ~CustomShellFontFileStream()
    {
        free(streamMemory_);
    }


    HRESULT ReadFileFragment(
        uint64_t fileOffset,
        uint64_t fragmentSize
        )
    {
        unsigned long actualBytesRead = 0;

        // Read the fragment from the shell stream. Since we need to return a
        // pointer to a buffer, read it into our memory. We do not cache
        // repeat calls to the same fragment address, as these do happen,
        // but are rare or repeat small fragment sizes.
        LARGE_INTEGER filePosition;
        filePosition.QuadPart = fileOffset;
        IFRDEBUG(stream_->Seek(filePosition, STREAM_SEEK_SET, nullptr));
        IFRDEBUG(stream_->Read(OUT &streamMemory_[fileOffset], static_cast<unsigned long>(fragmentSize), OUT &actualBytesRead));
        assert(actualBytesRead >= fragmentSize);

        return S_OK;
    }

    IFACEMETHODIMP ReadFileFragment(
        _Outptr_result_bytebuffer_(fragmentSize) void const** fragmentStart,
        uint64_t fileOffset,
        uint64_t fragmentSize,
        _Out_ void** fragmentContext
        )
    {
        IFR(ReadFileFragment(fileOffset, fragmentSize));

        #ifdef CUSTOM_SHELL_FONT_FILE_STREAM_SHOW_READS
        const OpenTypeTableRecord* tableRecord;
        const char* tag = "????";
        if (fontTableDirectory_.GetMatchingTableRecord(uint32_t(fileOffset), OUT &tableRecord))
        {
            tag = reinterpret_cast<const char*>(&tableRecord->tag);
        }
        wprintf(L"ReadFragment:{f:%ls p:%d x:%d %0.4S}\n", fileName_, uint32_t(fileOffset), uint32_t(fragmentSize), tag);
        #endif

        *fragmentStart = &streamMemory_[fileOffset];
        *fragmentContext = nullptr;

        return S_OK;
    }

    IFACEMETHODIMP_(void) ReleaseFileFragment(
        void* fragmentContext
        )
    {
        // Nothing to do.
    }

    IFACEMETHODIMP GetFileSize(
        _Out_ uint64_t* fileSize
        )
    {
        *fileSize = streamMemorySize_;
        return S_OK;
    }

    STDMETHOD(GetLastWriteTime)(
        _Out_ uint64_t* lastWriteTime
        )
    {
        *lastWriteTime = 0;
        return S_OK;
    }
};

class CustomShellFontFileLoader : public ComBase<IDWriteFontFileLoader, RefCountBaseStatic>
{
protected:
    IFACEMETHODIMP QueryInterface(IID const& iid, __out void** object) OVERRIDE
    {
        COM_BASE_RETURN_INTERFACE(iid, IDWriteFontFileLoader, object);
        COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
        COM_BASE_RETURN_NO_INTERFACE(object);
    }

public:
    IFACEMETHODIMP CreateStreamFromKey(
        _In_reads_bytes_(fontFileReferenceKeySize) void const* fontFileReferenceKey,
        uint32_t fontFileReferenceKeySize,
        _COM_Outptr_ IDWriteFontFileStream** fontFileStream
        )
    {
        if (fontFileReferenceKey == nullptr || fontFileReferenceKeySize < sizeof(wchar_t))
            return E_INVALIDARG;

        ComPtr<IBindCtx> bindContext;
        ComPtr<IShellItem> shellItem;
        ComPtr<IStream> shellStream;

        // The collectionKey actually points to the address of the custom IDWriteFontFileEnumerator.
        const wchar_t* fileName = reinterpret_cast<const wchar_t*>(fontFileReferenceKey);

        // Prepare parameters to indicate that the stream is read-only.
        IFR(CreateBindCtx(/*reserved*/0, OUT &bindContext));
        BIND_OPTS bindOptions = {};
        bindOptions.cbStruct = sizeof(BIND_OPTS);
        bindOptions.grfFlags = 0; 
        bindOptions.grfMode = STGM_READ; 
        bindOptions.dwTickCountDeadline = 0; 
        bindContext->SetBindOptions(&bindOptions); // ignorable error

        IFR(SHCreateItemFromParsingName(
            fileName,
            nullptr, // binding context
            IID_PPV_ARGS(OUT &shellItem)
            ));
        IFR(shellItem->BindToHandler(bindContext, BHID_Stream, IID_PPV_ARGS(OUT &shellStream)));

        auto* customShellFontFileStream = new CustomShellFontFileStream();
        ComPtr<IDWriteFontFileStream> customShellFontFileStreamScope(customShellFontFileStream);
        IFR(customShellFontFileStream->Initialize(shellStream, fileName));
        *fontFileStream = customShellFontFileStreamScope.Detach();

        return S_OK;
    }  
  
    static IDWriteFontFileLoader* GetInstance()  
    {  
        return &singleton_;
    }  
  
private:  
    static CustomShellFontFileLoader singleton_;
};

CustomShellFontFileLoader CustomShellFontFileLoader::singleton_;


HRESULT CreateFontFilesFromFileNames(
    IDWriteFactory* factory,
    _In_opt_ IDWriteFontFileLoader* fontFileLoader, // uses local file loader if nullptr
    std::wstring const& fileNames, // all filenames concatenated
    OUT std::vector<ComPtr<IDWriteFontFile> >& fontFiles
    )
{
    fontFiles.clear();

    for (const wchar_t* currentFileName = &fileNames[0], *lastFileName = currentFileName + fileNames.size();
            currentFileName <= lastFileName;
            currentFileName += wcslen(currentFileName) + 1
            )
    {
        ComPtr<IDWriteFontFile> fontFile;
        if (fontFileLoader == nullptr)
        {
            // Use local file loader.
            IFR(factory->CreateFontFileReference(
                    currentFileName,
                    nullptr, 
                    OUT &fontFile
                    ));
        }
        else
        {
            // Use custom file loader. Be sure to include the null terminator.
            const uint32_t fileNameLength = static_cast<uint32_t>((wcslen(currentFileName) + 1) * sizeof(wchar_t));
            IFR(factory->CreateCustomFontFileReference(
                    currentFileName,
                    fileNameLength,
                    fontFileLoader,
                    OUT &fontFile
                    ));
        }

        fontFiles.emplace_back(std::move(fontFile));
    }

    return S_OK;
}


HRESULT GetFilePathsFromFontFaces(
    _In_reads_(fontFacesCount) IDWriteFontFace** fontFaces,
    uint32_t fontFacesCount,
    OUT std::wstring& filePaths,
    OUT uint32_t& totalUniqueFileCount
    )
{
    totalUniqueFileCount = 0;
    filePaths.clear();

    std::set<std::wstring> seenStrings;
    std::wstring filePath;

    for (uint32_t fontFaceIndex = 0; fontFaceIndex < fontFacesCount; ++fontFaceIndex)
    {
        IDWriteFontFace* fontFace = fontFaces[fontFaceIndex];
        if (fontFace == nullptr)
            continue;

        GetFilePath(fontFace, OUT filePath);
        if (seenStrings.find(filePath) == seenStrings.end())
        {
            filePaths.append(filePath.c_str(), filePath.c_str() + filePath.size() + 1);
            seenStrings.insert(filePath);
            ++totalUniqueFileCount;
        }
    }

    return S_OK;
}


HRESULT CompressFontFaces(
    const std::wstring& filePaths,
    _Out_ uint64_t& originalTotalSize,
    _Out_ uint64_t& compressedTotalSize
    )
{
    originalTotalSize = 0;
    compressedTotalSize = 0;
    std::vector<uint8_t> fileBytes;
    uint32_t fileChunkSize = 16384;

    const wchar_t* filePath = filePaths.c_str();
    const wchar_t* filePathsEnd = filePath + filePaths.size();

    ////////////////////
    // Read all the table sizes from the table directories.
    for ( ; filePath < filePathsEnd; filePath += wcslen(filePath) + 1)
    {
        // Read the entire file.
        wprintf(L"File path: %ls ", filePath); fflush(stdout);
        IFRDEBUG(ReadBinaryFile(filePath, OUT fileBytes));

        // Compress each file block.
        const uint32_t fileSize = static_cast<uint32_t>(fileBytes.size());
        uint32_t compressedFileSize = 0;

        for (uint32_t filePosition = 0; filePosition < fileSize; filePosition += fileChunkSize)
        {
            // Read the next chunk.
            uint32_t sourceBufferSize = std::min(fileChunkSize, fileSize - filePosition);
            unsigned long compressedBufferSize = 0;
            uint8_t* compressedBuffer = NtosCompressData(&fileBytes[filePosition], sourceBufferSize, OUT &compressedBufferSize);
            free(compressedBuffer);
            compressedFileSize += compressedBufferSize;

            if (fileChunkSize >= INT32_MAX)
                break; // Indicates no chunk size (read entire file). So avoid wrap.
        }
        wprintf(L"(%d -> %d bytes)\n", fileSize, compressedFileSize);

        // Accumulate totals.
        originalTotalSize += fileSize;
        compressedTotalSize += compressedFileSize;
    }

    return S_OK;
}


bool GetFontTableEntries(
    const FontCheckedPtr fontPointer,
    uint32_t ttfStart,
    uint32_t tableEntriesCount,
    _In_reads_(tableEntriesCount) const uint32_t* desiredTableTags,
    _Out_writes_(tableEntriesCount) FontTableEntry* tableEntries
    )
{
    // Read OpenType directory.

    memset(tableEntries, 0, sizeof(*tableEntries) * tableEntriesCount);

    OpenTypeFontFaceDirectory directory(fontPointer, ttfStart);

    for (uint32_t tableIndex = 0; tableIndex < directory.tableCount_; ++tableIndex)
    {
        const auto& tableRecord = directory.tableRecords_[tableIndex];

        // Copy out the: tag, size, offset
        uint32_t tag = tableRecord.tag.GetRawInt();
        for (uint32_t desiredTableIndex = 0; desiredTableIndex < tableEntriesCount; ++desiredTableIndex)
        {
            if (tag == desiredTableTags[desiredTableIndex])
            {
                tableEntries[desiredTableIndex].offset = tableRecord.offset;
                tableEntries[desiredTableIndex].length = tableRecord.length;
            }
        }
    }

    for (uint32_t desiredTableIndex = 0; desiredTableIndex < tableEntriesCount; ++desiredTableIndex)
    {
        if (tableEntries[desiredTableIndex].offset == 0)
            return false;
    }

    return true;
}


HRESULT ShowFontTableSizes(const std::wstring& filePaths)
{
    std::vector<uint32_t> tableTags;
    std::vector<uint8_t> fileBytes;
    std::vector<uint32_t> tableSizes;
    std::vector<std::vector<uint32_t> > tableSizesPerFile;

    const wchar_t* filePath = filePaths.c_str();
    const wchar_t* filePathsEnd = filePath + filePaths.size();

    ////////////////////
    // Read all the table sizes from the table directories.
    for ( ; filePath < filePathsEnd; filePath += wcslen(filePath) + 1)
    {
        tableSizes.clear();

        // Read the entire file.
        wprintf(L"File path: %ls ", filePath); fflush(stdout);
        IFRDEBUG(ReadBinaryFile(filePath, OUT fileBytes));

        FontCheckedPtr fontPointer(fileBytes.data(), static_cast<uint32_t>(fileBytes.size()));

        // Check for TTC.
        uint32_t ttfStart = GetTtfFileOffset(fontPointer);

        // Read the TTF.
        const TtfHeader& ttfHeader = fontPointer.ReadAt<TtfHeader>(ttfStart);
        if (IsRecognizedTtf(ttfHeader))
        {
            // Read OpenType directory.

            OpenTypeFontFaceDirectory directory(fontPointer, ttfStart);
            for (uint32_t tableIndex = 0; tableIndex < directory.tableCount_; ++tableIndex)
            {
                const auto& tableRecord = directory.tableRecords_[tableIndex];
                uint32_t tableSize = tableRecord.length;

                uint32_t tag = tableRecord.tag.Get();
                size_t index;
                {
                    // Find the tag's index, adding it to the known tags list if not found yet.
                    auto tableTagsBegin = begin(tableTags);
                    auto tableTagsEnd = end(tableTags);
                    auto match = std::find(tableTagsBegin, tableTagsEnd, tag);
                    index = match - tableTagsBegin;
                    if (match == tableTagsEnd)
                    {
                        tableTags.push_back(tag);
                    }
                }
                size_t newMinimumArraySize = index + 1;
                if (newMinimumArraySize > tableSizes.size())
                {
                    tableSizes.resize(newMinimumArraySize);
                }
                tableSizes[index] = tableSize;
            }
        }
        else
        {
            wprintf(L"(format not recognized)");
        }
        wprintf(L"\n");

        // Append table sizes to end.
        tableSizesPerFile.resize(tableSizesPerFile.size() + 1);
        std::swap(tableSizesPerFile.back(), tableSizes);
    }

    ////////////////////
    // Print header row.

    const size_t tableTagsSize = tableTags.size();

    wprintf(L"\t");
    for (size_t i = 0; i < tableTagsSize; ++i)
    {
        wprintf((i + 1 < tableTagsSize) ? L"%.4S\t" : L"%.4S", &tableTags[i]);
    }
    wprintf(L"\n");

    ////////////////////
    // Print all the file sizes.
    filePath = filePaths.c_str();

    ////////////////////
    // Read all the table sizes from the table directories.
    for (size_t i = 0, ci = tableSizesPerFile.size(); i < ci && filePath < filePathsEnd; ++i, filePath += wcslen(filePath) + 1)
    {
        const wchar_t* fileName = FindFileNameStart(filePath, filePathsEnd);
        wprintf(L"%ls\t", fileName);

        const auto& fileTableSizes = tableSizesPerFile[i];
        for (uint32_t j = 0, cj = static_cast<uint32_t>(fileTableSizes.size()); j < tableTagsSize; ++j)
        {
            uint32_t tableSize = (j < cj) ? fileTableSizes[j] : 0;
            wprintf((j + 1 < tableTagsSize) ? L"%d\t" : L"%d", tableSize);
        }
        wprintf(L"\n");
    }

    return S_OK;
}


struct GlyphComponent
{
    uint16_t glyphId;
    int16_t transform[6];
    uint16_t point1, point2;    // may be both zero's (nop)

    bool operator < (const GlyphComponent& other) const throw()
    {
        if (glyphId < other.glyphId) return true;
        if (glyphId > other.glyphId) return false;
        if (transform[0] < other.transform[0]) return true;
        if (transform[0] > other.transform[0]) return false;
        if (transform[1] < other.transform[1]) return true;
        if (transform[1] > other.transform[1]) return false;
        if (transform[2] < other.transform[2]) return true;
        if (transform[2] > other.transform[2]) return false;
        if (transform[3] < other.transform[3]) return true;
        if (transform[3] > other.transform[3]) return false;
        if (transform[4] < other.transform[4]) return true;
        if (transform[4] > other.transform[4]) return false;
        if (transform[5] < other.transform[5]) return true;
        if (transform[5] > other.transform[5]) return false;
        return false;
    }

    bool IsSame(const GlyphComponent& other) const throw()
    {
        return glyphId == other.glyphId
            && transform[0] == other.transform[0]
            && transform[1] == other.transform[1]
            && transform[2] == other.transform[2]
            && transform[3] == other.transform[3]
            && transform[4] == other.transform[4]
            && transform[5] == other.transform[5];
    }
};


GlyphComponent GetCompositeGlyphComponent(
    FontCheckedPtr fontPointer,
    uint32_t compositeGlyphOffset,
    _Out_ uint32_t& finalCompositeGlyphOffset
    )
{
    GlyphComponent component = {0, 0x4000, 0x0000, 0x0000, 0x4000, 0x0000, 0x0000, 0, 0};

    const auto& compositeGlyph = fontPointer.ReadAt<GlyphHeader::CompositeGlyph>(compositeGlyphOffset);
    const uint16_t flags = compositeGlyph.flags;
    component.glyphId = compositeGlyph.glyphId;
    //wprintf(L"%d,", component.glyphId);

    compositeGlyphOffset += sizeof(OpenTypeUShort) * 2;     // USHORT flags;
                                                            // USHORT glyphIndex;
    uint16_t arg1 = 0, arg2 = 0;
    if (flags & GlyphHeader::CompositeGlyph::FlagsArgumentsAreWords)
    {
        arg1 = fontPointer.ReadAt<OpenTypeShort>(compositeGlyphOffset);
        arg2 = fontPointer.ReadAt<OpenTypeShort>(compositeGlyphOffset + sizeof(OpenTypeShort));
        compositeGlyphOffset += sizeof(OpenTypeShort) * 2;  // (SHORT or FWord) argument1;
                                                            // (SHORT or FWord) argument2;
    }
    else
    {
        uint16_t arg1and2 = fontPointer.ReadAt<OpenTypeUShort>(compositeGlyphOffset);
        arg1 = arg1and2 >> 8;
        arg2 = arg1and2 & 0xFF;
        compositeGlyphOffset += sizeof(OpenTypeByte)* 2;   // USHORT arg1and2; /* (arg1 << 8) | arg2 */
    }
    if (flags & GlyphHeader::CompositeGlyph::FlagsArgumentsAreXYValues)
    {
        component.transform[4] = arg1;
        component.transform[5] = arg2;
    }
    else
    {
        component.point1 = arg1;
        component.point2 = arg2;
    }
    if (flags & GlyphHeader::CompositeGlyph::FlagsHasScale)
    {
        const auto& transform = fontPointer.ReadAt<GlyphHeader::CompositeGlyph::Scale>(compositeGlyphOffset);
        uint16_t scale = transform.scale;
        component.transform[0] = scale;
        component.transform[3] = scale;
        compositeGlyphOffset += sizeof(transform);
    }
    else if (flags & GlyphHeader::CompositeGlyph::FlagsHasXYScale)
    {
        const auto& transform = fontPointer.ReadAt<GlyphHeader::CompositeGlyph::ScaleXY>(compositeGlyphOffset);
        component.transform[0] = transform.x;
        component.transform[3] = transform.y;
        compositeGlyphOffset += sizeof(transform);
    }
    else if (flags & GlyphHeader::CompositeGlyph::FlagsHas2x2)
    {
        const auto& transform = fontPointer.ReadAt<GlyphHeader::CompositeGlyph::Scale2x2>(compositeGlyphOffset);
        component.transform[0] = transform.xx;
        component.transform[1] = transform.xy;
        component.transform[2] = transform.yx;
        component.transform[3] = transform.yy;
        compositeGlyphOffset += sizeof(transform);
    }

    finalCompositeGlyphOffset = compositeGlyphOffset;
    return component;
}


class OpenTypeGlyfTableHelper
{
protected:
    const OpenTypeUShort* shortGlyphOffsets_ = nullptr;
    const OpenTypeULong* longGlyphOffsets_ = nullptr;
    uint32_t glyfTableOffset_ = 0;
    uint32_t glyphCount_ = 0;

public:
    OpenTypeGlyfTableHelper(
        FontCheckedPtr fontPointer,
        uint32_t glyfTableOffset,
        uint32_t locaTableOffset,
        uint32_t glyphCount,
        uint32_t locaIndexFormat
        )
        :   glyfTableOffset_(glyfTableOffset),
            glyphCount_(glyphCount)
    {
        switch (locaIndexFormat)
        {
        case 0:  shortGlyphOffsets_ = fontPointer.ReadArrayAt<OpenTypeUShort>(locaTableOffset, glyphCount); break;
        case 1:  longGlyphOffsets_ = fontPointer.ReadArrayAt<OpenTypeULong>(locaTableOffset, glyphCount);   break;
        }
    }

    uint32_t GetGlyphRecordOffset(uint16_t glyphId)
    {
        if (glyphId >= glyphCount_)
            return 0;

        uint32_t glyphOffsetInTable = (longGlyphOffsets_ ? uint32_t(longGlyphOffsets_[glyphId]) : uint32_t(shortGlyphOffsets_[glyphId] << 1));
        return glyfTableOffset_ + glyphOffsetInTable;
    }
};


#define COUNT_UNIQUE_GLYPH_COMPONENT_TRANSFORMS
//#define REMOVE_FONT_HINTS


HRESULT ShowGlyfTableSizes(
    FontCheckedPtr fontPointer,
    uint32_t ttfStart
    )
{
    const static uint32_t desiredTableTags[] = {
        DWRITE_MAKE_OPENTYPE_TAG('h','e','a','d'),
        DWRITE_MAKE_OPENTYPE_TAG('m','a','x','p'),
        DWRITE_MAKE_OPENTYPE_TAG('l','o','c','a'),
        DWRITE_MAKE_OPENTYPE_TAG('g','l','y','f'),
    };
    union {
        FontTableEntry tableEntries[4];
        struct {
            FontTableEntry headTableEntry;
            FontTableEntry maxpTableEntry;
            FontTableEntry locaTableEntry;
            FontTableEntry glyfTableEntry;
        };
    };
    static_assert(ARRAY_SIZE(desiredTableTags) == ARRAY_SIZE(tableEntries), "Arrays must be the same size");

    // Read OpenType directory to retrieve pointers to pertinent tables.
    if (!GetFontTableEntries(
            fontPointer,
            ttfStart,
            ARRAY_SIZE(tableEntries),
            desiredTableTags,
            OUT tableEntries
            ))
    {
        wprintf(L"(missing tables)\n");
        return DWRITE_E_FILEFORMAT;
    }

    const FontHeader& headTable = fontPointer.ReadAt<FontHeader>(headTableEntry.offset);
    const MaxpTable& maxpTable = fontPointer.ReadAt<MaxpTable>(maxpTableEntry.offset);
    const uint32_t glyphCount = maxpTable.numGlyphs;
    OpenTypeGlyfTableHelper glyfTableHelper(fontPointer, glyfTableEntry.offset, locaTableEntry.offset, glyphCount, headTable.indexToLocFormat);

    std::vector<bool> isComponentGlyph, isCompositeGlyph;
    uint32_t totalInstructionLength = 0;
    uint32_t totalCompositeGlyphCount = 0; // Number of glyphs that are composed from other components
    uint32_t totalComponentGlyphCount = 0; // Number of glyphs that serve as components for composite glyphs
    uint32_t totalPointlessCompositeGlyphCount = 0; // Number of component glyphs that point to just one other glyph (which is pointless).
    uint32_t totalComponentCompositeGlyphCount = 0; // Number of glyphs that serve as both components AND composite
    uint32_t totalComponentGlyphReferences = 0; // Total number of references to component glyphs
    uint32_t totalHintedGlyphCount = 0;
    uint32_t componentScaleCount = 0;
    uint32_t componentRotationCount = 0;
    isComponentGlyph.resize(glyphCount);
    isCompositeGlyph.resize(glyphCount);
    #ifdef COUNT_UNIQUE_GLYPH_COMPONENT_TRANSFORMS
    std::vector<GlyphComponent> glyphComponents;
    #endif

    for (uint32_t glyphId = 0; glyphId < glyphCount; ++glyphId)
    {
        uint32_t glyphOffsetInFile = glyfTableHelper.GetGlyphRecordOffset(uint16_t(glyphId));
        const GlyphHeader& glyphHeader = fontPointer.ReadAt<GlyphHeader>(glyphOffsetInFile);

        uint32_t instructionLength = 0;
        uint32_t instructionLengthOffset = 0;
        uint32_t componentCount = 0;

        if (glyphHeader.numberOfContours >= 0)
        {
            // Simple glyph. Skip the constant part and contour endpoints.
            uint32_t glyphOffset = glyphOffsetInFile;
            glyphOffset += sizeof(glyphHeader);
            glyphOffset += glyphHeader.numberOfContours * sizeof(OpenTypeUShort); // typeof(endPointsOfContours)
            instructionLengthOffset = glyphOffset;
        }
        else
        {
            isCompositeGlyph[glyphId] = true;
            bool isPointlessComposite = true;

            // Check for composite glyph.
            uint16_t flags = 0;
            uint32_t compositeGlyphOffset = glyphOffsetInFile + sizeof(glyphHeader); // Skip header, to the first glyph component.
            do
            {
                ++componentCount;
                ++totalComponentGlyphReferences;

                flags = fontPointer.ReadAt<OpenTypeUShort>(compositeGlyphOffset);
                GlyphComponent component = GetCompositeGlyphComponent(fontPointer, compositeGlyphOffset, OUT compositeGlyphOffset);

                bool hasTransform = false;
                if (component.transform[1] != 0x0000 || component.transform[2] != 0x0000)
                {
                    hasTransform = true;
                    ++componentRotationCount;
                }
                if (component.transform[0] != 0x4000 || component.transform[3] != 0x4000)
                {
                    hasTransform = true;
                    ++componentScaleCount;
                }
                if (component.transform[4] != 0x0 || component.transform[5] != 0x0)
                {
                    hasTransform = true;
                }

                if (componentCount > 1 || hasTransform || (flags & GlyphHeader::CompositeGlyph::FlagsHasMoreComponents))
                {
                    // This composite glyph refers to components, so mark any
                    // components as such. However, ignore cases where a composite
                    // glyph consists of exactly one component without any
                    // translation. These cases are pointless (the cmap should
                    // just point directly to the final glyph).
                    isPointlessComposite = false;
                    isComponentGlyph[component.glyphId] = true;
                }

                //wprintf(L"\tcompglyphid = %d 2x2[%d %d %d %d]\n", component.glyphId, component.transform[0],component.transform[1],component.transform[2],component.transform[3]);

                #ifdef COUNT_UNIQUE_GLYPH_COMPONENT_TRANSFORMS
                glyphComponents.push_back(component);
                #endif

            } while (flags & GlyphHeader::CompositeGlyph::FlagsHasMoreComponents);

            if (flags & GlyphHeader::CompositeGlyph::FlagsHasInstructions)
            {
                // USHORT numInstr
                // BYTE instr[numInstr]
                instructionLengthOffset = compositeGlyphOffset;
            }

            if (instructionLengthOffset > 0)
            {
                instructionLength = fontPointer.ReadAt<OpenTypeUShort>(instructionLengthOffset);
                if (instructionLength > 0)
                {
                    ++totalHintedGlyphCount;
                }
                #ifdef REMOVE_FONT_HINTS
                // Write a clear-stack instruction, which we use as a nop.
                uint8_t* instructions = fontPointer.GetArrayAt<uint8_t>(instructionLengthOffset + sizeof(OpenTypeUShort), instructionLength);
                memset(instructions, 0x22, instructionLength);
                #endif
            }

            ++totalCompositeGlyphCount;

            if (isPointlessComposite)
                ++totalPointlessCompositeGlyphCount;
        }

        //wprintf(L"\tglyph id = %d, instruction length = %d, componentCount = %d\n", componentGlyphId, instructionLength, componentCount);
        totalInstructionLength += instructionLength;
    } // for glyphId

    for (auto value : isComponentGlyph)
    {
        if (value)
            ++totalComponentGlyphCount;
    }

    for (size_t i = 0; i < glyphCount; ++i)
    {
        if (isComponentGlyph[i] && isCompositeGlyph[i])
            ++totalComponentCompositeGlyphCount;
    }

    #ifdef COUNT_UNIQUE_GLYPH_COMPONENT_TRANSFORMS
    std::sort(glyphComponents.begin(), glyphComponents.end());
    assert(totalComponentGlyphReferences == glyphComponents.size());
    size_t uniqueGlyphComponentReferences = std::min(1u, totalComponentGlyphReferences);

    for (size_t i = 1, ci = totalComponentGlyphReferences; i < ci; ++i)
    {
        auto& currentComponent = glyphComponents[i];
        auto& previousComponent = glyphComponents[uniqueGlyphComponentReferences - 1];
        if (!currentComponent.IsSame(previousComponent))
        {
            glyphComponents[uniqueGlyphComponentReferences] = currentComponent;
            ++uniqueGlyphComponentReferences;
        }
    }
    glyphComponents.resize(uniqueGlyphComponentReferences);
    //for (const auto& component : glyphComponents)
    //{
    //    wprintf(L"\tcompglyphid = %d 2x2[%d %d %d %d]\n", component.glyphId, component.transform[0],component.transform[1],component.transform[2],component.transform[3]);
    //}
    #endif

    // The ordering here must match the header printed by ShowGlyfTableSizes(filePaths)
    wprintf(
        L"%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d"
        #ifdef COUNT_UNIQUE_GLYPH_COMPONENT_TRANSFORMS
        L"\t%d"
        #endif
        L"\t%d\t%d\n"
        ,
        glyfTableEntry.length,
        totalInstructionLength,
        glyfTableEntry.length - totalInstructionLength,
        glyphCount,
        totalCompositeGlyphCount,
        totalComponentGlyphCount,
        totalComponentCompositeGlyphCount,
        totalPointlessCompositeGlyphCount,
        totalComponentGlyphReferences,
        totalHintedGlyphCount,
        #ifdef COUNT_UNIQUE_GLYPH_COMPONENT_TRANSFORMS
        static_cast<uint32_t>(uniqueGlyphComponentReferences),
        #endif
        componentScaleCount,
        componentRotationCount
        );

    #ifdef REMOVE_FONT_HINTS
    std::wstring outputFilePath(filePath);
    outputFilePath += L".out";
    IFRDEBUG(WriteBinaryFile(outputFilePath.c_str(), fileBytes));
    #endif

    return S_OK;
}

HRESULT ShowGlyfTableSizes(const std::wstring& filePaths)
{
    const wchar_t* filePath = filePaths.c_str();
    const wchar_t* filePathsEnd = filePath + filePaths.size();

    std::vector<uint8_t> fileBytes;

    wprintf(L"\tTable byte size"
            L"\tInstruction byte size"
            L"\tContour+other byte size"
            L"\tTotal glyph count"
            L"\tComposite glyph count"
            L"\tComponent glyph count"
            L"\tComponent&composite glyph count"
            L"\tPointless composite glyph count"
            L"\tComponent references"
            L"\tHinted glyph count"
            #ifdef COUNT_UNIQUE_GLYPH_COMPONENT_TRANSFORMS
            L"\tUnique component references"
            #endif
            L"\tComponent scale count"
            L"\tComponent rotation count"
            L"\n"
            );

    ////////////////////
    // Read all the table sizes from the table directories.
    for ( ; filePath < filePathsEnd; filePath += wcslen(filePath) + 1)
    {
        // Read the entire file.
        const wchar_t* fileName = FindFileNameStart(filePath, filePathsEnd);
        wprintf(L"%ls\t", fileName); fflush(stdout);
        IFRDEBUG(ReadBinaryFile(filePath, OUT fileBytes));

        FontCheckedPtr fontPointer(fileBytes.data(), static_cast<uint32_t>(fileBytes.size()));

        // Check for TTC.
        uint32_t ttfStart = GetTtfFileOffset(fontPointer);

        // Read the TTF.
        const TtfHeader& ttfHeader = fontPointer.ReadAt<TtfHeader>(ttfStart);
        if (!IsRecognizedTtf(ttfHeader))
        {
            wprintf(L"(format not recognized)\n");
            continue;
        }

        ShowGlyfTableSizes(fontPointer, ttfStart);
    }

    return S_OK;
}


class StackTextRendererTarget : public ComBase<IDWriteTextRenderer, RefCountBaseStatic>
{
protected:
    ComPtr<IDWriteBitmapRenderTarget> bitmapRenderTarget_;
    ComPtr<IDWriteRenderingParams> renderingParams_;

public:
    HRESULT Initialize(IDWriteFactory* dwriteFactory)
    {
        ComPtr<IDWriteGdiInterop> gdiInterop;
        IFR(dwriteFactory->GetGdiInterop(OUT &gdiInterop));
        IFR(gdiInterop->CreateBitmapRenderTarget(nullptr, 100,100, OUT &bitmapRenderTarget_));

        return S_OK;
    }

    // Renderer interface implementation

    IFACEMETHODIMP DrawGlyphRun(
        _In_ void* clientDrawingContext,
        _In_ float baselineOriginX,
        _In_ float baselineOriginY,
        DWRITE_MEASURING_MODE measuringMode,
        _In_ DWRITE_GLYPH_RUN const* glyphRun,
        _In_ DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
        _In_ IUnknown* clientDrawingEffect
        ) throw() OVERRIDE
    {
        bitmapRenderTarget_->DrawGlyphRun(
            baselineOriginX,
            baselineOriginY,
            measuringMode,
            glyphRun,
            renderingParams_,
            0x000000 // textColor
            );

        return S_OK;
    }

    IFACEMETHODIMP DrawGlyphRun(
        _In_ void* clientDrawingContext,
        _In_ float baselineOriginX,
        _In_ float baselineOriginY,
        _In_ DWRITE_GLYPH_ORIENTATION_ANGLE orientationAngle,
        DWRITE_MEASURING_MODE measuringMode,
        _In_ DWRITE_GLYPH_RUN const* glyphRun,
        _In_ DWRITE_GLYPH_RUN_DESCRIPTION const* glyphRunDescription,
        _In_ IUnknown* clientDrawingEffects
        ) throw()
    {
        bitmapRenderTarget_->DrawGlyphRun(
            baselineOriginX,
            baselineOriginY,
            measuringMode,
            glyphRun,
            renderingParams_,
            0x000000 // textColor
            );

        return S_OK;
    }

    IFACEMETHODIMP DrawUnderline(
        _In_ void* clientDrawingContext,
        _In_ float baselineOriginX,
        _In_ float baselineOriginY,
        _In_ DWRITE_UNDERLINE const* underline,
        _In_ IUnknown* clientDrawingEffects
        ) throw() OVERRIDE
    {
        return S_OK;
    }

    IFACEMETHODIMP DrawUnderline(
        _In_ void* clientDrawingContext,
        _In_ float baselineOriginX,
        _In_ float baselineOriginY,
        _In_ DWRITE_GLYPH_ORIENTATION_ANGLE orientationAngle,
        _In_ DWRITE_UNDERLINE const* underline,
        _In_ IUnknown* clientDrawingEffects
        ) throw()
    {
        return S_OK;
    }

    IFACEMETHODIMP DrawStrikethrough(
        _In_ void* clientDrawingContext,
        _In_ float baselineOriginX,
        _In_ float baselineOriginY,
        _In_ DWRITE_STRIKETHROUGH const* strikethrough,
        _In_ IUnknown* clientDrawingEffects
        ) throw() OVERRIDE
    {
        return S_OK;
    }

    IFACEMETHODIMP DrawStrikethrough(
        _In_ void* clientDrawingContext,
        _In_ float baselineOriginX,
        _In_ float baselineOriginY,
        _In_ DWRITE_GLYPH_ORIENTATION_ANGLE orientationAngle,
        _In_ DWRITE_STRIKETHROUGH const* strikethrough,
        _In_ IUnknown* clientDrawingEffects
        ) throw()
    {
        return S_OK;
    }

    IFACEMETHODIMP DrawInlineObject(
        _In_ void* clientDrawingContext,
        _In_ float originX,
        _In_ float originY,
        _In_ IDWriteInlineObject* inlineObject,
        _In_ BOOL isSideways,
        _In_ BOOL isRightToLeft,
        _In_ IUnknown* clientDrawingEffects
        ) throw()
    {
        return S_OK;
    }

    IFACEMETHODIMP DrawInlineObject(
        _In_ void* clientDrawingContext,
        _In_ float originX,
        _In_ float originY,
        _In_ DWRITE_GLYPH_ORIENTATION_ANGLE orientationAngle,
        _In_ IDWriteInlineObject* inlineObject,
        _In_ BOOL isSideways,
        _In_ BOOL isRightToLeft,
        _In_ IUnknown* clientDrawingEffects
        ) throw()
    {
        return S_OK;
    }

    IFACEMETHODIMP IsPixelSnappingDisabled(
        _Maybenull_ void* clientDrawingContext,
        _Out_ BOOL* isDisabled
        ) throw() OVERRIDE
    {
        return S_OK;
    }

    IFACEMETHODIMP GetCurrentTransform(
        _Maybenull_ void* clientDrawingContext,
        _Out_ DWRITE_MATRIX* transform
        ) throw() OVERRIDE
    {
        const static DWRITE_MATRIX identityTransform = {1,0,0,1,0,0};
        *transform = identityTransform;
        return S_OK;
    }

    IFACEMETHODIMP GetPixelsPerDip(
        _Maybenull_ void* clientDrawingContext,
        _Out_ float* pixelsPerDip
        ) throw() OVERRIDE
    {
        *pixelsPerDip = 1.0f;
        return S_OK;
    }

    // Static IUnknown interface
    // *It's test code, and there will only be one instance!

public:
    IFACEMETHODIMP QueryInterface(IID const& iid, _Out_ void** object) throw() OVERRIDE
    {
        // COM_BASE_RETURN_INTERFACE(iid, IDWriteTextRenderer1, object); // Requires <DWrite_2.h> on Windows 8.1
        COM_BASE_RETURN_INTERFACE(iid, IDWriteTextRenderer, object);
        COM_BASE_RETURN_INTERFACE(iid, IDWritePixelSnapping, object);
        COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
        COM_BASE_RETURN_NO_INTERFACE(object);
    }

    virtual unsigned long STDMETHODCALLTYPE AddRef() throw() OVERRIDE
    {
        return 1;
    }

    virtual unsigned long STDMETHODCALLTYPE Release() throw() OVERRIDE
    {
        return 1;
    }
};


HRESULT DrawFontFacesInTheirOwnNames(
    IDWriteFactory* dwriteFactory,
    IDWriteFontCollection* fontCollection
    )
{
    // Draw the names of all the font faces into an off-screen bitmap, just
    // to exercise the rendering code paths.

    wchar_t fullFamilyName[256];

    StackTextRendererTarget stackTextRendererTarget;
    stackTextRendererTarget.Initialize(dwriteFactory);

    for (uint32_t i = 0, ci = fontCollection->GetFontFamilyCount(); i < ci; ++i)
    {
        ComPtr<IDWriteFontFamily> fontFamily;
        IFR(fontCollection->GetFontFamily(i, OUT &fontFamily));

        for (uint32_t j = 0, cj = fontFamily->GetFontCount(); j < cj; ++j)
        {
            ComPtr<IDWriteFont> font;

            IFR(fontFamily->GetFont(j, OUT &font));
            if (font->GetSimulations() == DWRITE_FONT_SIMULATIONS_NONE) // Skip simulated ones.
            {
                BOOL exists = false;
                ComPtr<IDWriteLocalizedStrings> fullFamilyNameStrings;
                IFR(font->GetInformationalStrings(DWRITE_INFORMATIONAL_STRING_FULL_NAME, OUT &fullFamilyNameStrings, &exists));
                if (fullFamilyNameStrings != nullptr)
                {
                    fullFamilyName[0] = '\0';
                    fullFamilyNameStrings->GetString(/*index*/0, OUT fullFamilyName, ARRAY_SIZE(fullFamilyName));
                }

                ComPtr<IDWriteTextFormat> textFormat;
                IFR(dwriteFactory->CreateTextFormat(
                        fullFamilyName,
                        fontCollection,
                        DWRITE_FONT_WEIGHT_NORMAL,
                        DWRITE_FONT_STYLE_NORMAL,
                        DWRITE_FONT_STRETCH_NORMAL,
                        20,
                        L"en-us", // any locale is fine
                        OUT &textFormat
                        ));

                ComPtr<IDWriteTextLayout> textLayout;
                IFR(CreateTextLayout(
                        dwriteFactory,
                        fullFamilyName,
                        static_cast<uint32_t>(wcslen(fullFamilyName)),
                        textFormat,
                        100, // maxWidth
                        100, // maxHeight
                        DWRITE_MEASURING_MODE_NATURAL,
                        OUT &textLayout
                        ));

                IFR(textLayout->Draw(
                    nullptr, // clientDrawingContext
                    &stackTextRendererTarget,
                    0, // x
                    0  // y
                    ));
            }
        }
    }

    return S_OK;
}


bool ReadNumber(
    wchar_t const* dateBegin,
    wchar_t const* dateEnd,
    _Outptr_result_maybenull_ wchar_t const** newDateBegin,
    uint32_t radix,
    _Out_ uint32_t& value
    )
{
    assert(dateEnd >= dateBegin);
    assert(radix <= 36);
    value = 0;

    // Read the number.
    uint32_t computedValue = 0;
    bool isValidNumber = true;
    auto datePtr = dateBegin;
    for ( ; datePtr != dateEnd; ++datePtr)
    {
        char32_t ch = *datePtr;
        uint32_t num = ch - '0';
        if (num >= radix)
        {
            if (radix <= 10)
                break; // If binary/octal/decimal, then stop now.

            // Else try hexadecimal or another higher base.
            static_assert('a' - 'A' == 0x20, "Assume ASCII system.");
            ch &= ~0x20; // Force miniscule to majuscule cheaply.
            num = ch - 'A' + 10;
            if (num >= radix)
                break;
        }

        auto previousComputedValue = computedValue;
        computedValue = computedValue * radix + num;

        // Detect numeric overflow, but do not exit - keep reading numbers.
        if (computedValue < previousComputedValue)
        {
            isValidNumber = false;
        }
    }

    // Update the new end pointer.
    if (newDateBegin != nullptr)
        *newDateBegin = datePtr;

    value = computedValue;
    return isValidNumber && datePtr != dateBegin;
}

__success(return == true)
bool ReadDatePart(
    wchar_t const* dateBegin,
    wchar_t const* dateEnd,
    _Outptr_result_maybenull_ wchar_t const** newDateBegin,
    _Out_ uint16_t& value
    )
{
    // Avoid standard library functions like stol which inconveniently throw.
    // We just want to return false and let the caller act as desired.
    // Also avoid any locale specific non-determinism, since these are
    // standard numbers.

    uint32_t n;
    if (!ReadNumber(dateBegin, dateEnd, OUT newDateBegin, 10, OUT n) || n > UINT16_MAX)
        return false;

    value = decltype(value)(n);
    return true;
}


bool ReadDateSeparator(
    wchar_t const* dateBegin,
    wchar_t const* dateEnd,
    _Outptr_result_maybenull_ wchar_t const** newDateBegin,
    wchar_t expectedSeparator
    )
{
    if (dateBegin >= dateEnd)
        return false;

    if (*dateBegin != expectedSeparator)
        return false;

    *newDateBegin = dateBegin + 1;

    return true;
}


bool ParseDateISO8601(
    _In_reads_(dateLength) wchar_t const* date,
    uint32_t dateLength,
    _Out_ SYSTEMTIME* time
    )
{
    // The date must be one of these primary standard forms:
    //      "YYYY-MM-DDThh:mm:ssZ"  - complete time, Windows font backend
    //      "YYYY-MM-DDThh:mmZ"     - optional seconds
    //      "YYYY-MM-DD"            - date only, such as with Google font API's
    //
    // Time is always UTC (zero meridian), never local.
    SYSTEMTIME parsedTime = {};
    *time = parsedTime;

    auto dateEnd = date + dateLength;

    // Read the date.
    if (!ReadDatePart(date, dateEnd, OUT &date, OUT parsedTime.wYear        )) return false;
    if (!ReadDateSeparator(date, dateEnd, OUT &date, '-'))                     return false;
    if (!ReadDatePart(date, dateEnd, OUT &date, OUT parsedTime.wMonth       )) return false;
    if (!ReadDateSeparator(date, dateEnd, OUT &date, '-'))                     return false;
    if (!ReadDatePart(date, dateEnd, OUT &date, OUT parsedTime.wDayOfWeek   )) return false;
    if (date == dateEnd)                                                       return true; // Only the date part was present.

    // Read the time (UTC).
    if (!ReadDateSeparator(date, dateEnd, OUT &date, 'T'))                     return false;
    if (!ReadDatePart(date, dateEnd, OUT &date, OUT parsedTime.wDay         )) return false;
    if (!ReadDateSeparator(date, dateEnd, OUT &date, ':'))                     return false;
    if (!ReadDatePart(date, dateEnd, OUT &date, OUT parsedTime.wHour        )) return false;
    if (!ReadDateSeparator(date, dateEnd, OUT &date, ':'))                     return false;
    if (!ReadDatePart(date, dateEnd, OUT &date, OUT parsedTime.wMinute      )) return false;
    if (ReadDateSeparator(date, dateEnd, OUT &date, ':'))
    {
        // Seconds are optional.
        if (!ReadDatePart(date, dateEnd, OUT &date, OUT parsedTime.wSecond  )) return false;
    }
    if (!ReadDateSeparator(date, dateEnd, OUT &date, 'Z'))                     return false;

    return true; // Read the complete date. Ignore any following spurious text.
}


struct FamilyNameTags
{
    wchar_t const* fontName;
    wchar_t const* tags;
    wchar_t const* scripts;
};

static FamilyNameTags const g_knownFamilyNameTags[] =
{
    { L"Agency FB", L"Display;", L"Latn;" },
    { L"Aharoni", L"Text;", L"Hebr;" },
    { L"Aharoni Bold", L"Display;", L"Hebr;" },
    { L"Ahn B", L"Display;", L"Kore;" },
    { L"Ahn L", L"Text;", L"Kore;" },
    { L"Ahn M", L"Text;", L"Kore;" },
    { L"Aldhabi", L"Text;", L"Arab;" },
    { L"Algerian", L"Display;", L"Latn;" },
    { L"Ami R", L"Text;", L"Kore;" },
    { L"Andalus", L"Display;", L"Arab;" },
    { L"Angsana New", L"Text;", L"Thai;" },
    { L"AngsanaUPC", L"Text;", L"Thai;" },
    { L"Aparajita", L"Display;", L"Deva;" },
    { L"Arabic Typesetting", L"Text;", L"Arab;" },
    { L"Arial", L"Text;", L"Latn;Grek;Cyrl;Hebr;Arab;" },
    { L"Arial Rounded MT", L"Display;", L"Latn;" },
    { L"Arial Unicode MS", L"Text;", L"Latn;Grek;Cyrl;Armn;Geor;Arab;Hebr;" },
    { L"Baskerville Old Face", L"Text;", L"Latn;" },
    { L"Batang", L"Text;", L"Kore;" },
    { L"Batang Old Hangul", L"Text;", L"Kore;" },
    { L"Batang Old Koreul", L"Text;", L"Kore;" },
    { L"BatangChe", L"Text;", L"Kore;" },
    { L"Bauhaus 93", L"Display;", L"Latn;" },
    { L"Bell MT", L"Text;", L"Latn;" },
    { L"Berlin Sans FB", L"Display;", L"Latn;" },
    { L"Bernard MT", L"Display;", L"Latn;" },
    { L"Big Round R", L"Display;", L"Kore;" },
    { L"Big Sans R", L"Display;", L"Kore;" },
    { L"Blackadder ITC", L"Display;", L"Latn;" },
    { L"Bodoni MT", L"Text;", L"Latn;" },
    { L"Bodoni MT Poster", L"Display;", L"Latn;" },
    { L"Book Antiqua", L"Text;", L"Latn;" },
    { L"Bookman Old Style", L"Text;", L"Latn;" },
    { L"Bookshelf Symbol 7", L"Symbol;", L"Zsym;" },
    { L"Bradley Hand ITC", L"Informal;", L"Latn;" },
    { L"Britannic", L"Display;", L"Latn;" },
    { L"Broadway", L"Display;", L"Latn;" },
    { L"Browallia New", L"Text;", L"Thai;" },
    { L"BrowalliaUPC", L"Text;", L"Thai;" },
    { L"Brush Script MT", L"Informal;", L"Latn;" },
    { L"Calibri", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Californian FB", L"Text;", L"Latn;" },
    { L"Calisto MT", L"Text;", L"Latn;" },
    { L"Cambria", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Cambria Math", L"Symbol;", L"Zsym;Zmth;" },
    { L"Candara", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Castellar", L"Display;", L"Latn;" },
    { L"Centaur", L"Text;", L"Latn;" },
    { L"Century", L"Text;", L"Latn;" },
    { L"Century Gothic", L"Display;", L"Latn;" },
    { L"Century Schoolbook", L"Text;", L"Latn;" },
    { L"Chiller", L"Display;", L"Latn;" },
    { L"Colonna MT", L"Display;", L"Latn;" },
    { L"Comic Sans MS", L"Informal;", L"Latn;Grek;Cyrl;" },
    { L"Consolas", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Constantia", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Cooper", L"Display;", L"Latn;" },
    { L"Copperplate Gothic", L"Display;", L"Latn;" },
    { L"Corbel", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Cordia New", L"Text;", L"Thai;" },
    { L"CordiaUPC", L"Text;", L"Thai;" },
    { L"Courier", L"Text;", L"Latn;" },
    { L"Courier New", L"Text;", L"Latn;Grek;Cyrl;Hebr;" },
    { L"Curlz MT", L"Display;", L"Latn;" },
    { L"DFKai-SB", L"Text;", L"Hant;" },
    { L"DaunPenh", L"Text;", L"Khmr;" },
    { L"David", L"Text;", L"Hebr;" },
    { L"DejaVu Sans", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"DejaVu Sans Mono", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"DejaVu Serif", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"DilleniaUPC", L"Text;", L"Thai;" },
    { L"DokChampa", L"Text;", L"Laoo;" },
    { L"Dotum", L"Text;", L"Kore;" },
    { L"Dotum Old Hangul", L"Text;", L"Kore;" },
    { L"Dotum Old Koreul", L"Text;", L"Kore;" },
    { L"DotumChe", L"Text;", L"Kore;" },
    { L"Ebrima", L"Text;", L"Vaii;Nkoo;Tfng;Osma;Ethi;" },
    { L"Edwardian Script ITC", L"Display;", L"Latn;" },
    { L"Elephant", L"Display;", L"Latn;" },
    { L"Engravers MT", L"Display;", L"Latn;" },
    { L"Eras ITC", L"Text;", L"Latn;" },
    { L"Eras ITC Medium", L"Display;", L"Latn;" },
    { L"Estrangelo Edessa", L"Text;", L"Syrc;" },
    { L"EucrosiaUPC", L"Text;", L"Thai;" },
    { L"Euphemia", L"Text;", L"Cans;" },
    { L"Expo B", L"Display;", L"Kore;" },
    { L"Expo L", L"Text;", L"Kore;" },
    { L"Expo M", L"Display;", L"Kore;" },
    { L"FZShuTi", L"Text;", L"Hans;" },
    { L"FZYaoTi", L"Text;", L"Hans;" },
    { L"FangSong", L"Text;", L"Hans;" },
    { L"Felix Titling", L"Display;", L"Latn;" },
    { L"Fixedsys", L"Text;", L"Latn;" },
    { L"Footlight MT", L"Text;", L"Latn;" },
    { L"Forte", L"Informal;", L"Latn;" },
    { L"FrankRuehl", L"Text;", L"Hebr;" },
    { L"Franklin Gothic", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Franklin Gothic Book", L"Text;", L"Latn;" },
    { L"FreesiaUPC", L"Text;", L"Thai;" },
    { L"Freestyle Script", L"Informal;", L"Latn;" },
    { L"French Script MT", L"Informal;", L"Latn;" },
    { L"Gabriola", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Gadugi", L"Text;", L"Cher;" },
    { L"Garam B", L"Text;", L"Kore;" },
    { L"Garamond", L"Text;", L"Latn;" },
    { L"Gautami", L"Text;", L"Telu;" },
    { L"Georgia", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Gigi", L"Display;", L"Latn;" },
    { L"Gill Sans", L"Display;", L"Latn;" },
    { L"Gill Sans MT", L"Text;", L"Latn;" },
    { L"Gisha", L"Text;", L"Hebr;" },
    { L"Gloucester MT", L"Display;", L"Latn;" },
    { L"Gothic B", L"Text;", L"Kore;" },
    { L"Gothic L", L"Text;", L"Kore;" },
    { L"Gothic Newsletter", L"Text;", L"Kore;" },
    { L"Gothic R", L"Text;", L"Kore;" },
    { L"Gothic Round B", L"Text;", L"Kore;" },
    { L"Gothic Round L", L"Text;", L"Kore;" },
    { L"Gothic Round R", L"Text;", L"Kore;" },
    { L"Gothic Round XB", L"Display;", L"Kore;" },
    { L"Gothic XB", L"Display;", L"Kore;" },
    { L"Goudy Old Style", L"Text;", L"Latn;" },
    { L"Goudy Stout", L"Display;", L"Latn;" },
    { L"Graphic B", L"Display;", L"Kore;" },
    { L"Graphic New R", L"Display;", L"Kore;" },
    { L"Graphic R", L"Text;", L"Kore;" },
    { L"Graphic Sans B", L"Display;", L"Kore;" },
    { L"Graphic Sans R", L"Text;", L"Kore;" },
    { L"Gulim", L"Text;", L"Kore;" },
    { L"GulimChe", L"Text;", L"Kore;" },
    { L"Gungsuh", L"Text;", L"Kore;" },
    { L"Gungsuh Old Hangul", L"Text;", L"Kore;" },
    { L"Gungsuh Old Koreul", L"Text;", L"Kore;" },
    { L"Gungsuh R", L"Text;", L"Kore;" },
    { L"GungsuhChe", L"Text;", L"Kore;" },
    { L"HGGothicE", L"Text;", L"Jpan;" },
    { L"HGGothicM", L"Text;", L"Jpan;" },
    { L"HGGyoshotai", L"Text;", L"Jpan;" },
    { L"HGKyokashotai", L"Text;", L"Jpan;" },
    { L"HGMaruGothicMPRO", L"Text;", L"Jpan;" },
    { L"HGMinchoB", L"Text;", L"Jpan;" },
    { L"HGMinchoE", L"Text;", L"Jpan;" },
    { L"HGPGothicE", L"Text;", L"Jpan;" },
    { L"HGPGothicM", L"Text;", L"Jpan;" },
    { L"HGPGyoshotai", L"Text;", L"Jpan;" },
    { L"HGPKyokashotai", L"Text;", L"Jpan;" },
    { L"HGPMinchoB", L"Text;", L"Jpan;" },
    { L"HGPMinchoE", L"Text;", L"Jpan;" },
    { L"HGPSoeiKakugothicUB", L"Display;", L"Jpan;" },
    { L"HGPSoeiKakupoptai", L"Display;", L"Jpan;" },
    { L"HGPSoeiPresenceEB", L"Text;", L"Jpan;" },
    { L"HGSGothicE", L"Text;", L"Jpan;" },
    { L"HGSGothicM", L"Text;", L"Jpan;" },
    { L"HGSGyoshotai", L"Text;", L"Jpan;" },
    { L"HGSKyokashotai", L"Text;", L"Jpan;" },
    { L"HGSMinchoB", L"Text;", L"Jpan;" },
    { L"HGSMinchoE", L"Text;", L"Jpan;" },
    { L"HGSSoeiKakugothicUB", L"Display;", L"Jpan;" },
    { L"HGSSoeiKakupoptai", L"Display;", L"Jpan;" },
    { L"HGSSoeiPresenceEB", L"Text;", L"Jpan;" },
    { L"HGSeikaishotaiPRO", L"Text;", L"Jpan;" },
    { L"HGSoeiKakugothicUB", L"Display;", L"Jpan;" },
    { L"HGSoeiKakupoptai", L"Display;", L"Jpan;" },
    { L"HGSoeiPresenceEB", L"Text;", L"Jpan;" },
    { L"HYBackSong", L"Display;", L"Kore;" },
    { L"HYBudle", L"Text;", L"Kore;" },
    { L"HYGothic", L"Text;", L"Kore;" },
    { L"HYGothic-Extra", L"Display;", L"Kore;" },
    { L"HYGraphic", L"Text;", L"Kore;" },
    { L"HYGungSo", L"Text;", L"Kore;" },
    { L"HYHaeSo", L"Text;", L"Kore;" },
    { L"HYHeadLine", L"Display;", L"Kore;" },
    { L"HYKHeadLine", L"Display;", L"Kore;" },
    { L"HYLongSamul", L"Display;", L"Kore;" },
    { L"HYMokGak", L"Display;", L"Kore;" },
    { L"HYMokPan", L"Display;", L"Kore;" },
    { L"HYMyeongJo", L"Text;", L"Kore;" },
    { L"HYMyeongJo Extra Bold", L"Display;", L"Kore;" },
    { L"HYMyeongJo-Extra", L"Text;", L"Kore;" },
    { L"HYPMokGak", L"Display;", L"Kore;" },
    { L"HYPMokPan", L"Display;", L"Kore;" },
    { L"HYPillGi", L"Informal;", L"Kore;" },
    { L"HYPost", L"Informal;", L"Kore;" },
    { L"HYRGothic", L"Text;", L"Kore;" },
    { L"HYSeNse", L"Informal;", L"Kore;" },
    { L"HYShortSamul", L"Text;", L"Kore;" },
    { L"HYSinGraphic", L"Text;", L"Kore;" },
    { L"HYSinMun-MyeongJo", L"Text;", L"Kore;" },
    { L"HYSinMyeongJo", L"Text;", L"Kore;" },
    { L"HYSinMyeongJo-Medium-HanjaA", L"Symbol;", L"Zsym;" },
    { L"HYSinMyeongJo-Medium-HanjaB", L"Symbol;", L"Zsym;" },
    { L"HYSinMyeongJo-Medium-HanjaC", L"Symbol;", L"Zsym;" },
    { L"HYSooN-MyeongJo", L"Text;", L"Kore;" },
    { L"HYSymbolA", L"Symbol;", L"Zsym;" },
    { L"HYSymbolB", L"Symbol;", L"Zsym;" },
    { L"HYSymbolC", L"Symbol;", L"Zsym;" },
    { L"HYSymbolD", L"Symbol;", L"Zsym;" },
    { L"HYSymbolE", L"Symbol;", L"Zsym;" },
    { L"HYSymbolF", L"Symbol;", L"Zsym;" },
    { L"HYSymbolG", L"Symbol;", L"Zsym;" },
    { L"HYSymbolH", L"Symbol;", L"Zsym;" },
    { L"HYTaJa", L"Text;", L"Kore;" },
    { L"HYTaJa Bold", L"Display;", L"Kore;" },
    { L"HYTaJaFull", L"Text;", L"Kore;" },
    { L"HYTaJaFull Bold", L"Display;", L"Kore;" },
    { L"HYTeBack", L"Display;", L"Kore;" },
    { L"HYYeaSo", L"Display;", L"Kore;" },
    { L"HYYeasoL", L"Display;", L"Kore;" },
    { L"HYYeatGul", L"Display;", L"Kore;" },
    { L"Haettenschweiler", L"Display;", L"Latn;" },
    { L"Harlow Solid", L"Display;", L"Latn;" },
    { L"Harrington", L"Display;", L"Latn;" },
    { L"Headline R", L"Display;", L"Kore;" },
    { L"Headline Sans R", L"Display;", L"Kore;" },
    { L"High Tower Text", L"Text;", L"Latn;" },
    { L"Impact", L"Display;", L"Latn;Grek;Cyrl;" },
    { L"Imprint MT Shadow", L"Display;", L"Latn;" },
    { L"Informal Roman", L"Informal;", L"Latn;" },
    { L"IrisUPC", L"Display;", L"Thai;" },
    { L"Iskoola Pota", L"Text;", L"Sinh;" },
    { L"JasmineUPC", L"Display;", L"Thai;" },
    { L"Jasu B", L"Display;", L"Kore;" },
    { L"Jasu L", L"Display;", L"Kore;" },
    { L"Jasu R", L"Display;", L"Kore;" },
    { L"Jasu XB", L"Display;", L"Kore;" },
    { L"Javanese Text", L"Text;", L"Java;" },
    { L"Jokerman", L"Display;", L"Latn;" },
    { L"Juice ITC", L"Display;", L"Latn;" },
    { L"KaiTi", L"Text;", L"Hans;" },
    { L"Kalinga", L"Text;", L"Orya;" },
    { L"Kartika", L"Text;", L"Mlym;" },
    { L"Khmer UI", L"Text;", L"Khmr;" },
    { L"KodchiangUPC", L"Display;", L"Thai;" },
    { L"Kokila", L"Text;", L"Deva;" },
    { L"Kristen ITC", L"Informal;", L"Latn;" },
    { L"Kunstler Script", L"Display;", L"Latn;" },
    { L"Lao UI", L"Text;", L"Laoo;" },
    { L"Latha", L"Text;", L"Taml;" },
    { L"Latin", L"Display;", L"Latn;" },
    { L"Leelawadee", L"Text;", L"Thai;" },
    { L"Leelawadee UI", L"Text;", L"Thai;Laoo;Bugi;Khmr;" },
    { L"Levenim MT", L"Display;", L"Hebr;" },
    { L"LiSu", L"Text;", L"Hans;" },
    { L"LilyUPC", L"Display;", L"Thai;" },
    { L"Lucida Bright", L"Text;", L"Latn;" },
    { L"Lucida Calligraphy", L"Display;", L"Latn;" },
    { L"Lucida Console", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Lucida Fax", L"Text;", L"Latn;" },
    { L"Lucida Handwriting", L"Informal;", L"Latn;" },
    { L"Lucida Sans", L"Text;", L"Latn;" },
    { L"Lucida Sans Typewriter", L"Text;", L"Latn;" },
    { L"Lucida Sans Unicode", L"Text;", L"Latn;Grek;Cyrl;Hebr;" },
    { L"MS Gothic", L"Text;", L"Jpan;" },
    { L"MS Mincho", L"Text;", L"Jpan;" },
    { L"MS Outlook", L"Symbol;", L"Zsym;" },
    { L"MS PGothic", L"Text;", L"Jpan;" },
    { L"MS PMincho", L"Text;", L"Jpan;" },
    { L"MS Reference Sans Serif", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"MS Reference Specialty", L"Symbol;", L"Zsym;" },
    { L"MS Sans Serif", L"Text;", L"Latn;" },
    { L"MS Serif", L"Text;", L"Latn;" },
    { L"MS UI Gothic", L"Text;", L"Jpan;" },
    { L"MV Boli", L"Text;", L"Thaa;" },
    { L"Magic R", L"Display;", L"Kore;" },
    { L"Magneto", L"Display;", L"Latn;" },
    { L"Maiandra GD", L"Text;", L"Latn;" },
    { L"Malgun Gothic", L"Text;", L"Kore;" },
    { L"Mangal", L"Text;", L"Deva;" },
    { L"Marlett", L"Symbol", L"Zsym;" },
    { L"Matura MT Script Capitals", L"Display;", L"Latn;" },
    { L"Meiryo", L"Text;", L"Jpan;" },
    { L"Meiryo UI", L"Text;", L"Jpan;" },
    { L"Meorimyungjo B", L"Display;", L"Kore;" },
    { L"Meorimyungjo XB", L"Display;", L"Kore;" },
    { L"Microsoft Himalaya", L"Text;", L"Tibt;" },
    { L"Microsoft JhengHei", L"Text;", L"Hant;" },
    { L"Microsoft JhengHei Light", L"Text;", L"Hant;" },
    { L"Microsoft JhengHei UI", L"Text;", L"Hant;" },
    { L"Microsoft JhengHei UI Light", L"Text;", L"Hant;" },
    { L"Microsoft New Tai Lue", L"Text;", L"Talu;" },
    { L"Microsoft PhagsPa", L"Text;", L"Phag;" },
    { L"Microsoft Sans Serif", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Microsoft Tai Le", L"Text;", L"Tale;" },
    { L"Microsoft Uighur", L"Text;", L"ug-Arab;" },
    { L"Microsoft YaHei", L"Text;", L"Hans;" },
    { L"Microsoft YaHei Light", L"Text;", L"Hans;" },
    { L"Microsoft YaHei UI", L"Text;", L"Hans;" },
    { L"Microsoft YaHei UI Light", L"Text;", L"Hans;" },
    { L"Microsoft Yi Baiti", L"Text;", L"Yiii;" },
    { L"MingLiU", L"Text;", L"Hant;" },
    { L"MingLiU-ExtB", L"Text;", L"Hant;" },
    { L"MingLiU_HKSCS", L"Text;", L"Hant-HK;" },
    { L"MingLiU_HKSCS-ExtB", L"Text;", L"Hant-HK;" },
    { L"Miriam", L"Text;", L"Hebr;" },
    { L"Miriam Fixed", L"Text;", L"Hebr;" },
    { L"Mistral", L"Informal;", L"Latn;" },
    { L"Modak R", L"Display;", L"Kore;" },
    { L"Modern", L"Text;", L"Latn;" },
    { L"Modern No. 20", L"Text;", L"Latn;" },
    { L"MoeumT B", L"Display;", L"Kore;" },
    { L"MoeumT L", L"Text;", L"Kore;" },
    { L"MoeumT R", L"Text;", L"Kore;" },
    { L"MoeumT XB", L"Display;", L"Kore;" },
    { L"Mongolian Baiti", L"Text;", L"Mong;" },
    { L"Monotype Corsiva", L"Informal;", L"Latn;" },
    { L"MoolBoran", L"Display;", L"Khmr;" },
    { L"Myanmar Text", L"Text;", L"Mymr;" },
    { L"Myungjo B", L"Text;", L"Kore;" },
    { L"Myungjo L", L"Text;", L"Kore;" },
    { L"Myungjo Newsletter", L"Text;", L"Kore;" },
    { L"Myungjo R", L"Text;", L"Kore;" },
    { L"Myungjo SK B", L"Text;", L"Kore;" },
    { L"Myungjo XB", L"Display;", L"Kore;" },
    { L"NSimSun", L"Text;", L"Hans;" },
    { L"Namu B", L"Informal;", L"Kore;" },
    { L"Namu L", L"Text;", L"Kore;" },
    { L"Namu R", L"Text;", L"Kore;" },
    { L"Namu XB", L"Display;", L"Kore;" },
    { L"Narkisim", L"Text;", L"Hebr;" },
    { L"New Batang", L"Text;", L"Kore;" },
    { L"New Dotum", L"Text;", L"Kore;" },
    { L"New Gulim", L"Text;", L"Kore;" },
    { L"New Gungsuh", L"Text;", L"Kore;" },
    { L"NewGulim Old Hangul", L"Text;", L"Kore;" },
    { L"NewGulim Old Koreul", L"Text;", L"Kore;" },
    { L"Niagara Engraved", L"Display;", L"Latn;" },
    { L"Niagara Solid", L"Display;", L"Latn;" },
    { L"Nirmala UI", L"Text;", L"Taml;Beng;Deva;Gujr;Guru;Knda;Mlym;Orya;Sinh;Telu;Olck;Sora;" },
    { L"Nyala", L"Text;", L"Ethi;" },
    { L"OCR A", L"Display;", L"Latn;" },
    { L"OCRB", L"Text;", L"Latn;" },
    { L"Old English Text MT", L"Display;", L"Latn;" },
    { L"Onyx", L"Display;", L"Latn;" },
    { L"OpenSymbol", L"Symbol;", L"Zsym;" },
    { L"PMingLiU", L"Text;", L"Hant;" },
    { L"PMingLiU-ExtB", L"Text;", L"Hant;" },
    { L"Palace Script MT", L"Display;", L"Latn;" },
    { L"Palatino Linotype", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Pam B", L"Display;", L"Kore;" },
    { L"Pam L", L"Text;", L"Kore;" },
    { L"Pam M", L"Text;", L"Kore;" },
    { L"Pam New B", L"Display;", L"Kore;" },
    { L"Pam New L", L"Text;", L"Kore;" },
    { L"Pam New M", L"Text;", L"Kore;" },
    { L"Panhwa R", L"Display;", L"Kore;" },
    { L"Papyrus", L"Informal;", L"Latn;" },
    { L"Parchment", L"Display;", L"Latn;" },
    { L"Perpetua", L"Text;", L"Latn;" },
    { L"Perpetua Titling MT", L"Display;", L"Latn;" },
    { L"Plantagenet Cherokee", L"Text;", L"Cher;" },
    { L"Playbill", L"Display;", L"Latn;" },
    { L"Poor Richard", L"Display;", L"Latn;" },
    { L"Pristina", L"Informal;", L"Latn;" },
    { L"Pyunji R", L"Informal;", L"Kore;" },
    { L"Raavi", L"Text;", L"Guru;" },
    { L"Rage", L"Informal;", L"Latn;" },
    { L"Ravie", L"Display;", L"Latn;" },
    { L"Rockwell", L"Text;", L"Latn;" },
    { L"Rod", L"Text;", L"Hebr;" },
    { L"Roman", L"Text;", L"Latn;" },
    { L"STCaiyun", L"Display;", L"Hans;" },
    { L"STFangsong", L"Text;", L"Hans;" },
    { L"STHupo", L"Display;", L"Hans;" },
    { L"STKaiti", L"Text;", L"Hans;" },
    { L"STLiti", L"Text;", L"Hans;" },
    { L"STSong", L"Text;", L"Hans;" },
    { L"STXihei", L"Text;", L"Hans;" },
    { L"STXingkai", L"Text;", L"Hans;" },
    { L"STXinwei", L"Text;", L"Hans;" },
    { L"STZhongsong", L"Text;", L"Hans;" },
    { L"SWGamekeys MT Regular", L"Symbol;", L"Zsym;" },
    { L"SWMacro Regular", L"Symbol;", L"Zsym;" },
    { L"Saenaegi B", L"Text;", L"Kore;" },
    { L"Saenaegi L", L"Text;", L"Kore;" },
    { L"Saenaegi R", L"Text;", L"Kore;" },
    { L"Saenaegi XB", L"Display;", L"Kore;" },
    { L"Sakkal Majalla", L"Text;", L"Arab;" },
    { L"Sam B", L"Display;", L"Kore;" },
    { L"Sam L", L"Text;", L"Kore;" },
    { L"Sam M", L"Text;", L"Kore;" },
    { L"Sam New B", L"Display;", L"Kore;" },
    { L"Sam New L", L"Text;", L"Kore;" },
    { L"Sam New M", L"Text;", L"Kore;" },
    { L"Script", L"Informal;", L"Latn;" },
    { L"Script MT", L"Display;", L"Latn;" },
    { L"Segoe Print", L"Informal;", L"Latn;Grek;Cyrl;" },
    { L"Segoe Script", L"Informal;", L"Latn;Grek;Cyrl;" },
    { L"Segoe UI", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Segoe UI Black", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Segoe UI Black Italic", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Segoe UI Bold", L"Text;", L"Latn;Grek;Cyrl;Armn;Geor;Geok;Arab;Hebr;Lisu;" },
    { L"Segoe UI Bold Italic", L"Text;", L"Latn;Grek;Cyrl;Armn;Geor;" },
    { L"Segoe UI Emoji", L"Symbol;", L"Zsym;" },
    { L"Segoe UI Italic", L"Text;", L"Latn;Grek;Cyrl;Armn;Geor;" },
    { L"Segoe UI Light", L"Text;", L"Latn;Grek;Cyrl;Armn;Geor;Geok;Arab;Hebr;Lisu;" },
    { L"Segoe UI Light Italic", L"Text;", L"Latn;Grek;Cyrl;Armn;Geor;" },
    { L"Segoe UI Regular", L"Text;", L"Latn;Grek;Cyrl;Armn;Geor;Geok;Arab;Hebr;Lisu;" },
    { L"Segoe UI Semibold", L"Text;", L"Latn;Grek;Cyrl;Armn;Geor;Geok;Arab;Hebr;Lisu;" },
    { L"Segoe UI Semibold Italic", L"Text;", L"Latn;Grek;Cyrl;Armn;Geor;" },
    { L"Segoe UI Semilight", L"Text;", L"Latn;Grek;Cyrl;Armn;Geor;Geok;Arab;Hebr;Lisu;" },
    { L"Segoe UI Semilight Italic", L"Text;", L"Latn;Grek;Cyrl;Armn;Geor;" },
    { L"Segoe UI Symbol", L"Symbol;", L"Zsym;Brai;Dsrt;Glag;Goth;Ital;Ogam;Orkh;Runr;Copt;Merc;" },
    { L"Shonar Bangla", L"Text;", L"Beng;" },
    { L"Showcard Gothic", L"Display;", L"Latn;" },
    { L"Shruti", L"Text;", L"Gujr;" },
    { L"SimHei", L"Text;", L"Hans;" },
    { L"SimSun", L"Text;", L"Hans;" },
    { L"SimSun-ExtB", L"Text;", L"Hans;" },
    { L"Simplified Arabic", L"Text;", L"Arab;" },
    { L"Simplified Arabic Fixed", L"Text;", L"Arab;" },
    { L"Sitka Banner", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Sitka Display", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Sitka Heading", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Sitka Small", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Sitka Subheading", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Sitka Text", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Small Fonts", L"Text;", L"Latn;" },
    { L"Snap ITC", L"Display;", L"Latn;" },
    { L"Soha R", L"Display;", L"Kore;" },
    { L"Stencil", L"Display;", L"Latn;" },
    { L"Sylfaen", L"Text;", L"Grek;Cyrl;Armn;Geor;" },
    { L"Symbol", L"Symbol;", L"Zsym;" },
    { L"System", L"Text;", L"Latn;" },
    { L"Tahoma", L"Text;", L"Latn;Grek;Cyrl;Armn;Hebr;" },
    { L"Tempus Sans ITC", L"Informal;", L"Latn;" },
    { L"Terminal", L"Text;", L"Latn;" },
    { L"Times New Roman", L"Text;", L"Latn;Grek;Cyrl;Hebr;" },
    { L"Traditional Arabic", L"Text;", L"Arab;" },
    { L"Trebuchet MS", L"Display;", L"Latn;Grek;Cyrl;" },
    { L"Tunga", L"Text;", L"Knda;" },
    { L"Tw Cen MT", L"Text;", L"Latn;" },
    { L"Urdu Typesetting", L"Text;", L"Arab;" },
    { L"Utsaah", L"Text;", L"Deva;" },
    { L"Vani", L"Text;", L"Telu;" },
    { L"Verdana", L"Text;", L"Latn;Grek;Cyrl;" },
    { L"Vijaya", L"Text;", L"Taml;" },
    { L"Viner Hand ITC", L"Informal;", L"Latn;" },
    { L"Vivaldi", L"Display;", L"Latn;" },
    { L"Vladimir Script", L"Display;", L"Latn;" },
    { L"Vrinda", L"Text;", L"Beng;" },
    { L"Webdings", L"Symbol;", L"Zsym;" },
    { L"Wingdings", L"Symbol;", L"Zsym;" },
    { L"Wingdings 2", L"Symbol;", L"Zsym;" },
    { L"Wingdings 3", L"Symbol;", L"Zsym;" },
    { L"Woorin R", L"Text;", L"Kore;" },
    { L"Yeopseo R", L"Informal;", L"Kore;" },
    { L"Yet R", L"Display;", L"Kore;" },
    { L"Yet Sans XB", L"Display;", L"Kore;" },
    { L"Yet Sans B", L"Text;", L"Kore;" },
    { L"Yet Sans L", L"Text;", L"Kore;" },
    { L"Yet Sans R", L"Text;", L"Kore;" },
    { L"YouYuan", L"Text;", L"Hans;" },
    { L"Yu Gothic", L"Text;", L"Jpan;" },
    { L"Yu Gothic Light", L"Text;", L"Jpan;" },
    { L"Yu Mincho", L"Text;", L"Jpan;" },
    { L"Yu Mincho Light", L"Text;", L"Jpan;" },
};

bool FindTagsFromKnownFontName(
    wchar_t const* fullFontName,
    wchar_t const* familyName,
    OUT wchar_t const** tags,
    OUT wchar_t const** scripts
    ) // not WWS or GDI name
{
    for (uint32_t i = 0; i < 2; ++i)
    {
        auto fontName = i == 0 ? fullFontName : familyName;
        if (fontName == nullptr || fontName[0] == '\0')
            continue;

        auto const* begin = g_knownFamilyNameTags;
        auto const* end = g_knownFamilyNameTags + ARRAYSIZE(g_knownFamilyNameTags);

        while (begin < end)
        {
            auto const* p = begin + (end - begin) / 2;

            auto cmp = _wcsicmp(fontName, p->fontName);
            if (cmp == 0)
            {
                *tags = p->tags;
                *scripts = p->scripts;
                return true;
            }

            cmp = wcscmp(fontName, p->fontName);
            if (cmp < 0)
            {
                end = p;
            }
            else // if (cmp > 0)
            {
                begin = p + 1;
            }
        }
    }

    return false;
}


HRESULT WriteLocalizedStrings(
    const std::wstring& stringsName,
    IDWriteLocalizedStrings* localizedStrings,
    __inout TextTree& data,
    uint32_t parentNodeIndex
    )
{
    if (localizedStrings == nullptr)
        return E_INVALIDARG;

    std::wstring language, value;
    uint32_t objectNodeIndex = 0, attributeNodeIndex, valueNodeIndex;
    if (data.FindKey(parentNodeIndex, stringsName.c_str(), OUT objectNodeIndex))
    {
        data.Delete(objectNodeIndex, /*shouldRemove*/ false);
    }
    data.AppendChild(parentNodeIndex, TextTree::Node::TypeObject, stringsName.c_str(), static_cast<uint32_t>(stringsName.size()), OUT objectNodeIndex);
    for (uint32_t i = 0, ci = localizedStrings->GetCount(); i < ci; ++i)
    {
        GetLocalizedStringLanguage(localizedStrings, i, OUT language);
        GetLocalizedString(localizedStrings, i, OUT value);
        data.AppendChild(objectNodeIndex, TextTree::Node::TypeAttribute, language.c_str(), static_cast<uint32_t>(language.size()), OUT attributeNodeIndex);
        data.AppendChild(attributeNodeIndex, TextTree::Node::TypeString, value.c_str(), static_cast<uint32_t>(value.size()), OUT valueNodeIndex);
    }
    return S_OK;
}


HRESULT WriteInformationalStrings(
    const std::wstring& stringsName,
    DWRITE_INFORMATIONAL_STRING_ID stringId,
    IDWriteFont* font,
    __inout TextTree& data,
    uint32_t parentNodeIndex
    )
{
    if (font == nullptr)
        return E_INVALIDARG;

    ComPtr<IDWriteLocalizedStrings> localizedStrings;
    BOOL ignorableExists;
    IFR(font->GetInformationalStrings(stringId, OUT &localizedStrings, OUT &ignorableExists));
    return WriteLocalizedStrings(stringsName, localizedStrings, IN OUT data, parentNodeIndex);
}


void AppendStringIfNotPresent(
    __in_z wchar_t* newString,
    __inout std::wstring& existingString
    )
{
    if (existingString.find(newString) == std::wstring::npos)
    {
        existingString.append(newString);
    }
}


HRESULT ProcessFontFileMetadata(
    IDWriteFactory* dwriteFactory,
    const std::wstring& fullUrl,
    const std::wstring& fontFilePath,
    uint32_t fontFaceIndex,
    __inout TextTree& data,
    uint32_t parentNodeIndex
    )
{
    std::wstring value;
    uint32_t nodeIndex = parentNodeIndex;

    // Print current font filename.
    wprintf(L"%ls - index %d\n", fontFilePath.c_str(), fontFaceIndex);

    // Generate UUID if one does not exist yet.
    if (!data.FindKey(parentNodeIndex, L"UUID", OUT nodeIndex))
    {
        UUID uuid;
        std::wstring uuidString;
        RPC_WSTR uuidRawString = nullptr;

        if (UuidCreate(OUT &uuid) < 0)
        {
            memset(&uuid, 0, sizeof(uuid));
        }

        if (UuidToString(&uuid, OUT &uuidRawString) >= 0)
        {
            uuidString = reinterpret_cast<wchar_t*>(uuidRawString);
            RpcStringFree(IN OUT &uuidRawString);
            std::transform(uuidString.begin(), uuidString.end(), uuidString.begin(), [](wchar_t ch){ return wchar_t(toupper(ch)); });
        }
        data.SetKeyValue(parentNodeIndex, L"UUID", uuidString);
    }

    // Set the filename based on the file path.
    if (!data.FindKey(parentNodeIndex, L"OriginalFileName", OUT nodeIndex))
    {
        value = FindFileNameStart(fontFilePath.c_str(), fontFilePath.c_str() + fontFilePath.size());
        data.SetKeyValue(parentNodeIndex, L"OriginalFileName", value);
    }

    data.SetKeyValue(parentNodeIndex, L"Path", fullUrl);

    // Create a font face to get the last modified date.
    ComPtr<IDWriteFontFace> fontFace;
    IFRDEBUG(CreateFontFaceFromFile(
        dwriteFactory,
        fontFilePath.c_str(),
        fontFaceIndex,
        DWRITE_FONT_SIMULATIONS_NONE,
        OUT &fontFace
        ));

    data.SetKeyValue(parentNodeIndex, L"FaceIndex", fontFaceIndex);

    SYSTEMTIME systemTime = {};
    WIN32_FILE_ATTRIBUTE_DATA attributes = {};
    GetFileAttributesEx(fontFilePath.c_str(), GetFileExInfoStandard, OUT &attributes);
    FileTimeToSystemTime(&attributes.ftLastWriteTime, OUT &systemTime);
    GetFormattedString(
        OUT value,
        L"%04d-%02d-%02dT%02d:%02d:%02dZ",
        systemTime.wYear,
        systemTime.wMonth,
        systemTime.wDay,
        systemTime.wHour,
        systemTime.wMinute,
        systemTime.wSecond
        );

    data.SetKeyValue(parentNodeIndex, L"DateModified", value);

    // Print all the informational strings.

    ComPtr<IDWriteFontCollection> fontCollection;
    ComPtr<IDWriteFontFamily> fontFamily;
    ComPtr<IDWriteFont> font;
    ComPtr<IDWriteFont2> font2;
    IFR(CreateFontCollection(
            dwriteFactory,
            fontFilePath.c_str(),
            static_cast<uint32_t>(fontFilePath.size()),
            OUT &fontCollection
            ));
    IFR(fontCollection->GetFontFromFontFace(fontFace, OUT &font));
    IFR(font->QueryInterface(OUT &font2));
    IFR(font->GetFontFamily(OUT &fontFamily));

    ComPtr<IDWriteLocalizedStrings> familyNames;
    ComPtr<IDWriteLocalizedStrings> faceNames;
    fontFamily->GetFamilyNames(OUT &familyNames);
    font->GetFaceNames(OUT &faceNames);
    WriteLocalizedStrings(L"FamilyName", familyNames, IN OUT data, parentNodeIndex);
    WriteLocalizedStrings(L"FaceName", faceNames, IN OUT data, parentNodeIndex);
    WriteInformationalStrings(L"PreferredFamilyName", DWRITE_INFORMATIONAL_STRING_PREFERRED_FAMILY_NAMES, font, IN OUT data, parentNodeIndex);
    WriteInformationalStrings(L"SubfamilyName", DWRITE_INFORMATIONAL_STRING_PREFERRED_SUBFAMILY_NAMES, font, IN OUT data, parentNodeIndex);
    WriteInformationalStrings(L"FullName", DWRITE_INFORMATIONAL_STRING_FULL_NAME, font, IN OUT data, parentNodeIndex);
    WriteInformationalStrings(L"GdiName", DWRITE_INFORMATIONAL_STRING_WIN32_FAMILY_NAMES, font, IN OUT data, parentNodeIndex);
    WriteInformationalStrings(L"PostscriptName", DWRITE_INFORMATIONAL_STRING_POSTSCRIPT_NAME, font, IN OUT data, parentNodeIndex);
    WriteInformationalStrings(L"Version", DWRITE_INFORMATIONAL_STRING_VERSION_STRINGS, font, IN OUT data, parentNodeIndex);

    data.SetKeyValue(parentNodeIndex, L"Weight", font->GetWeight());
    data.SetKeyValue(parentNodeIndex, L"Stretch", font->GetStretch());
    data.SetKeyValue(parentNodeIndex, L"Slope", font->GetStyle());

    // Write tags
    {
        std::wstring tags, scripts;

        // Initialize tags for known fonts, using hard-coded list.
        ComPtr<IDWriteLocalizedStrings> nameStrings;
        BOOL exists;
        font->GetInformationalStrings(DWRITE_INFORMATIONAL_STRING_FULL_NAME, OUT &nameStrings, OUT &exists);
        std::wstring fullFontName, familyName;
        GetLocalizedString(nameStrings, /*preferredLanguage*/nullptr, OUT fullFontName);
        GetLocalizedString(familyNames, /*preferredLanguage*/nullptr, OUT familyName);
        wchar_t const* initialTags;
        wchar_t const* initialScripts;
        if (FindTagsFromKnownFontName(fullFontName.c_str(), familyName.c_str(), OUT &initialTags, OUT &initialScripts))
        {
            tags = initialTags;
            scripts = initialScripts;
        }

        // Add default tags from font properties.
        if (font2->IsSymbolFont())
        {
            AppendStringIfNotPresent(L"Symbol;", IN OUT tags);
        }
        if (font2->IsMonospacedFont())
        {
            AppendStringIfNotPresent(L"Monospace;", IN OUT tags);
        }
        if (font2->IsColorFont())
        {
            AppendStringIfNotPresent(L"Color;", IN OUT tags);
        }

        DWRITE_PANOSE panose = {};
        font2->GetPanose(OUT &panose);
        uint8_t serifStyle = 0;
        switch (panose.familyKind)
        {
        case DWRITE_PANOSE_FAMILY_TEXT_DISPLAY: serifStyle = panose.text.serifStyle;         break;
        case DWRITE_PANOSE_FAMILY_DECORATIVE:   serifStyle = panose.decorative.serifVariant; break;
        }

        switch (serifStyle)
        {
        case DWRITE_PANOSE_SERIF_STYLE_NORMAL_SANS:
        case DWRITE_PANOSE_SERIF_STYLE_OBTUSE_SANS:
        case DWRITE_PANOSE_SERIF_STYLE_PERPENDICULAR_SANS:
        case DWRITE_PANOSE_SERIF_STYLE_FLARED:
        case DWRITE_PANOSE_SERIF_STYLE_ROUNDED:
            AppendStringIfNotPresent(L"Sans-Serif;", IN OUT tags);
            break;

        case DWRITE_PANOSE_SERIF_STYLE_COVE:
        case DWRITE_PANOSE_SERIF_STYLE_OBTUSE_COVE:
        case DWRITE_PANOSE_SERIF_STYLE_SQUARE_COVE:
        case DWRITE_PANOSE_SERIF_STYLE_OBTUSE_SQUARE_COVE:
        case DWRITE_PANOSE_SERIF_STYLE_SQUARE:
        case DWRITE_PANOSE_SERIF_STYLE_THIN:
        case DWRITE_PANOSE_SERIF_STYLE_OVAL:
        case DWRITE_PANOSE_SERIF_STYLE_EXAGGERATED:
        case DWRITE_PANOSE_SERIF_STYLE_TRIANGLE:
        case DWRITE_PANOSE_SERIF_STYLE_SCRIPT:
            AppendStringIfNotPresent(L"Serif;", IN OUT tags);
            break;
        }

        data.SetKeyValue(parentNodeIndex, L"Tags", tags);
        data.SetKeyValue(parentNodeIndex, L"Scripts", scripts);
    }

    return S_OK;
}


struct FontFilePathAndIndex
{
    std::wstring filePath;
    uint32_t faceIndex;

    bool operator < (const FontFilePathAndIndex& other) const
    {
        auto c = _wcsicmp(filePath.c_str(), other.filePath.c_str());
        if (c < 0) return true;
        if (c > 0) return false;
        if (faceIndex < other.faceIndex) return true;
        return false;
    }
};


HRESULT GetUrlFromFilePath(
    const std::wstring& inputFilePath,
    const std::wstring& baseFilePath,
    const std::wstring& baseServerPath,
    std::wstring& fullUrl
    )
{
    if (baseFilePath.empty())
    {
        fullUrl = inputFilePath;
        return S_OK; // Return full file path as-is, as a local file resource.
    }

    auto const baseStringLength = std::min(inputFilePath.size(), baseFilePath.size());
    if (_wcsnicmp(inputFilePath.c_str(), baseFilePath.c_str(), baseStringLength) != 0)
    {
        std::wstring errorMessage;
        GetFormattedString(
            OUT errorMessage,
            L"Input file name '%ls' is not under the base file path '%ls'",
            inputFilePath.c_str(),
            baseFilePath.c_str()
            );
        ShowError(errorMessage.c_str());
        return E_INVALIDARG;
    }

    // Strip the base file path from the input file name.
    fullUrl = baseServerPath;
    fullUrl.append(inputFilePath);
    fullUrl.erase(baseServerPath.size(), baseStringLength);
    std::for_each(fullUrl.begin(), fullUrl.end(), [=](wchar_t& c){ c = (c == '\\') ? '/' : c; });

    return S_OK;
}


HRESULT ProcessFontSetMetadata(
    IDWriteFactory* dwriteFactory,
    const std::wstring& filePaths,
    const std::wstring& inputFilename,
    const std::wstring& outputFilename,
    const std::wstring& baseFilePath,
    const std::wstring& baseServerPath
    )
{
    TextTree data;
    std::set<FontFilePathAndIndex> filePathsToAdd;
    std::wstring fullUrl;

    ////////////////////
    // Read all the already processed font data.

    wprintf(L"Reading existing font metadata from '%ls'\n", inputFilename.c_str());
    if (!inputFilename.empty())
    {
        std::wstring inputJson;
        IFR(ReadTextFile(inputFilename.c_str(), OUT inputJson));

        JsonexParser parser(inputJson, JsonexParser::OptionsDefault);
        parser.ReadNodes(IN OUT data);
    }

    uint32_t nodeIndex = 0;
    data.SkipRootNode(IN OUT nodeIndex);
    if (data.empty()
    ||  data.GetNode(nodeIndex).type != TextTree::Node::TypeArray
    ||  !data.AdvanceChildNode(IN OUT nodeIndex))
    {
        data.Clear();
        data.Append(TextTree::Node::TypeArray, 1, L"", 0);
        nodeIndex = 1;
    }

    ////////////////////
    // Add additional fonts to list.
    {
        FontFilePathAndIndex filePathAndIndex;

        const wchar_t* filePath = filePaths.c_str();
        const wchar_t* filePathsEnd = filePath + filePaths.size();
        for (; filePath < filePathsEnd; filePath += wcslen(filePath) + 1)
        {
            wprintf(L"%ls\n", filePath);
            ComPtr<IDWriteFontFile> fontFile;
            IFR(dwriteFactory->CreateFontFileReference(
                filePath,
                nullptr, // lastWriteTime
                OUT &fontFile
                ));

            BOOL isSupportedFontType;
            DWRITE_FONT_FILE_TYPE fontFileType;
            DWRITE_FONT_FACE_TYPE fontFaceType;
            uint32_t numberOfFaces;
            IFR(fontFile->Analyze(OUT &isSupportedFontType, OUT &fontFileType, OUT &fontFaceType, OUT &numberOfFaces));

            if (isSupportedFontType)
            {
                filePathAndIndex.filePath = filePath;
                for (uint32_t faceIndex = 0; faceIndex < numberOfFaces; ++faceIndex)
                {
                    filePathAndIndex.faceIndex = faceIndex;
                    filePathsToAdd.insert(filePathAndIndex);
                }
            }
        }
    }

    ////////////////////
    // Update data of any existing fonts.

    wprintf(L"Updating font metadata\n");
    {
        std::wstring filePath;
        std::wstring value;
        FontFilePathAndIndex filePathAndIndex;

        while (nodeIndex < data.GetNodeCount())
        {
            auto fontNodeIndex = nodeIndex;
            if (data.GetNode(fontNodeIndex).type == TextTree::Node::TypeObject)
            {
                if (data.GetKeyValue(fontNodeIndex, L"FilePath", OUT filePath))
                {
                    uint32_t faceIndex = 0;
                    if (data.GetKeyValue(fontNodeIndex, L"FaceIndex", OUT value))
                    {
                        faceIndex = _wtoi(value.c_str());
                    }

                    IFR(GetUrlFromFilePath(filePath, baseFilePath, baseServerPath, OUT fullUrl));
                    IFR(ProcessFontFileMetadata(
                        dwriteFactory,
                        fullUrl,
                        filePath,
                        faceIndex,
                        IN OUT data,
                        fontNodeIndex
                        ));

                    // Remove this file from the list of file paths to add, given it is already present.
                    filePathAndIndex.filePath = filePath;
                    filePathAndIndex.faceIndex = faceIndex;
                    filePathsToAdd.erase(filePathAndIndex);
                }
            }

            if (!data.AdvanceNextNode(IN OUT nodeIndex))
                break;
        }
    }

    ////////////////////
    // Update data of new fonts.
    for (auto& filePathAndIndex : filePathsToAdd)
    {
        auto fontNodeIndex = data.GetNodeCount();
        data.Append(TextTree::Node::TypeObject, /*level*/2, L"", 0);

        IFR(GetUrlFromFilePath(filePathAndIndex.filePath, baseFilePath, baseServerPath, OUT fullUrl));
        IFR(ProcessFontFileMetadata(
            dwriteFactory,
            fullUrl,
            filePathAndIndex.filePath,
            filePathAndIndex.faceIndex,
            IN OUT data,
            fontNodeIndex
            ));
    }

    ////////////////////
    // Write all the data back out.

    wprintf(L"Writing new font metadata\n");

    JsonexWriter writer(JsonexWriter::OptionsDefault);
    writer.WriteNodes(data);
    uint32_t outputJsonLength = 0;
    const wchar_t* outputJson = writer.GetText(OUT outputJsonLength);
    IFR(WriteTextFile(outputFilename.c_str(), outputJson, outputJsonLength));

    return S_OK;
}


////////////////////////////////////////////////////////////////////////////////
// Main application.


class Application
{
private:
    std::wstring    dwriteDllName_ = L"dwrite.dll";
    std::wstring    fontSearchMask_ = L"*.?t?";
    std::wstring    fontFilePaths_;
    uint32_t        fontTableTag_ = 'ESAB';
    bool            onlyShowMatches_ = false;
    TextTree        commands_;
    LARGE_INTEGER   startTime_;
    LARGE_INTEGER   endTime_;

    ModuleHandle dwriteModule_; // must be before all DWrite resources for destructor order.
    ComPtr<IDWriteFactory> dwriteFactory_;
    ComPtr<IDWriteFontCollection> fontCollection_;

public:
    ~Application();
    bool ParseCommandLine(_In_z_ const wchar_t* commandLine);
    HRESULT EnsureFontFilesExist();
    HRESULT EnsureFontCollectionExists();
    HRESULT PreprocessCommands();
    HRESULT ProcessCommands();
    HRESULT Initialize();
    void StartTimer(const wchar_t* message);
    void EndTimer(const wchar_t* message);
};


////////////////////////////////////////////////////////////////////////////////


HRESULT Application::Initialize()
{
    IFR(CoInitializeEx(nullptr, COINIT_MULTITHREADED));
    IFR(LoadDWrite(dwriteDllName_.c_str(), DWRITE_FACTORY_TYPE_SHARED, OUT &dwriteFactory_, OUT dwriteModule_));
    IFR(dwriteFactory_->RegisterFontFileLoader(CustomShellFontFileLoader::GetInstance()));

    return S_OK;
}


Application::~Application()
{
    if (dwriteFactory_ != nullptr)
    {
        dwriteFactory_->UnregisterFontFileLoader(CustomShellFontFileLoader::GetInstance());
    }
    CoUninitialize();
}


std::wstring UnescapeString(std::wstring& str)
{
    for (size_t i = 0; i < str.size(); ++i)
    {
        if (str[i] == '\\')
        {
            wchar_t* text = const_cast<wchar_t *>(str.c_str());
            wchar_t* escapeStart = text + i;
            wchar_t* escapeEnd = escapeStart + 1;
            std::wstring replacement = L"\\";

            switch (*escapeEnd)
            {
            case L'r':
                replacement = L'\r';
                ++escapeEnd;
                break;

            case L'n':
                replacement = L'\n';
                ++escapeEnd;
                break;

            case L't':
                replacement = L'\t';
                ++escapeEnd;
                break;

            case L'x':
            case L'u':
            case L'U':
                replacement = (wchar_t) wcstoul(escapeStart + 2, &escapeEnd, 16);
                break;

            case L'0': case L'1': case L'2': case L'3': case L'4':
            case L'5': case L'6': case L'7': case L'8': case L'9':
                // Support decimal here (octal is not supported)
                replacement = (wchar_t) wcstoul(escapeStart + 1, &escapeEnd, 10);
                break;
            }

            str.replace(escapeStart - text, escapeEnd - escapeStart, replacement);
            i += replacement.size() - 1;
        }
    }

    return str;
}


void Application::StartTimer(const wchar_t* message)
{
    wprintf(L"--------------------\nStarting %ls\n", message);
    QueryPerformanceCounter(OUT &startTime_);
}


void Application::EndTimer(const wchar_t* message)
{
    QueryPerformanceCounter(OUT &endTime_);

    LARGE_INTEGER frequency;
    QueryPerformanceFrequency(&frequency);
    uint32_t milliseconds = (unsigned) (1000 * (endTime_.QuadPart - startTime_.QuadPart) / frequency.QuadPart);
    wprintf(L"Ending %ls\n"
            L"Duration (ms): %d\n", message, milliseconds);
}


void ShowError(_In_z_ const wchar_t* message)
{
    SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_INTENSITY);
    fwprintf(stderr, L"%ls\n", message);
}


void ShowHelp()
{
    //       [---0----][---1----][---2----][---3----][---4----][---5----][---6----][---7----]
    wprintf(L"FontCommandTool 1.0 (2013-10-02)\n"
            L"\n"
            L"Options (order matters):\n"
            );
    for (uint32_t i = 0; i < ARRAY_SIZE(g_commandLineCommandNames); ++i)
    {
        wprintf(L"    %25ls %ls\n", g_commandLineCommandNames[i].name, g_commandLineCommandNames[i].description);
    }
    wprintf(L"\n"
            L"Example usage:\n"
            L"    FontCommandTool FontFiles=\"z:\\fonts\\Win8\\**\\*.tt?\" DrawFontFaceNames\n"
            L"    FontCommandTool FontFiles=\"d:\\fonts\\Office\\*.TT?\" ProcessFontSetMetadata{Output=\"D:\\output-fonts.json\"}\n"
            L"    FontCommandTool FontFiles=\"c:\\windows\\fonts\\*.TT?\" CreateShellFontCollection CreateFontCollectionFaces\n"
            L"    FontCommandTool.exe WatchFolder=\"c:\\Windows\\ServiceProfiles\\LocalService\\AppData\\Local\\FontCache\\*.dat\"\n"
            L"\n"
            );
}


void ShowKeyValue(_In_z_ const wchar_t* key, _In_z_ const wchar_t* value)
{
    SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY);
    wprintf(L"%ls: %ls\n", key, value);
}


HRESULT ValidateNodeDetailType(
    const TextTree::Node& node,
    TextTree::Node::Type expectedType,
    const wchar_t* message
    )
{
    if (node.type != expectedType)
    {
        ShowError(message);
        return E_INVALIDARG;
    }
    return S_OK;
}


bool Application::ParseCommandLine(_In_z_ const wchar_t* commandLine)
{
    // Parse all the parameters on the command line. However, do very little
    // work here, deferring all the processing to later, once the application
    // is more initialized.

    if (commandLine == nullptr
    ||  commandLine[0] == '\0'
    ||  (commandLine[0] == '-' || commandLine[0] == '/') && (commandLine[1] == '?' || commandLine[1] == 'h') && (commandLine[2] == '\0')
        )
    {
        ShowHelp();
        return false;
    }

    std::wstring inputCommands;
    JsonexParser parser;

    if (commandLine[0] == '@')
    {
        if (FAILED(ReadTextFile(commandLine + 1, OUT inputCommands)))
        {
            std::wstring errorMessage;
            GetFormattedString(OUT errorMessage, L"Could not load command file: '%ls'", commandLine + 1);
            ShowError(errorMessage.c_str());
            return false;
        }
        parser.Reset(inputCommands.c_str(), static_cast<uint32_t>(inputCommands.size()), TextTreeParser::OptionsDefault);
    }
    else
    {
        uint32_t textLength = static_cast<uint32_t>(wcslen(commandLine));
        parser.Reset(commandLine, textLength, TextTreeParser::OptionsNoEscapeSequence);
    }
    parser.ReadNodes(IN OUT commands_);

    // Display any parse errors.
    if (parser.GetErrorCount() > 0)
    {
        SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY);
        for (uint32_t errorIndex = 0, errorCount = parser.GetErrorCount(); errorIndex < errorCount; ++errorIndex)
        {
            uint32_t errorTextIndex;
            const wchar_t* errorMessage;
            parser.GetErrorDetails(errorIndex, OUT errorTextIndex, OUT &errorMessage);
            fwprintf(stderr, L"Syntax error: \"%.*s<*>%ls\" %ls\n", errorTextIndex, commandLine, &commandLine[errorTextIndex], errorMessage);
        }
    
        return false;
    }

    return true;
}


HRESULT Application::EnsureFontFilesExist()
{
    if (fontFilePaths_.empty())
    {
        ShowError(L"No font file paths given. Use FontFiles=\"*.ttf\"");
        return E_INVALIDARG;
    }

    return S_OK;
}


HRESULT Application::EnsureFontCollectionExists()
{
    if (fontCollection_ == nullptr)
    {
        IFR(EnsureFontFilesExist());

        fontCollection_.Clear();
        StartTimer(L"CreateFontCollection");
        IFR(CreateFontCollection(
                dwriteFactory_,
                fontFilePaths_.c_str(),
                static_cast<uint32_t>(fontFilePaths_.size()),
                OUT &fontCollection_
                ));
        EndTimer(L"CreateFontCollection");
    }

    return S_OK;
}


HRESULT Application::PreprocessCommands()
{
    // Preprocess certain parameters from the command line.

    // Skip any empty root nodes if present.
    uint32_t firstNodeIndex = 0;
    commands_.SkipEmptyNodes(IN OUT firstNodeIndex);

    // Validate all the top level commands first, and print them out.
    bool foundUnrecognizedCommand = false;
    std::wstring spaceBuffer;
    for (uint32_t nodeIndex = firstNodeIndex, nodeCount = commands_.GetNodeCount(); nodeIndex < nodeCount; )
    {
        const auto& node = commands_.GetNode(nodeIndex);

        const size_t spacesPerIndent = 4;
        const size_t spacesToIndent = std::min(size_t(48), node.level * spacesPerIndent);
        spaceBuffer.assign(spacesToIndent, ' ');

        uint32_t nodeTextLength;
        auto nodeText = commands_.GetText(node, OUT nodeTextLength);
        wprintf(L"%ls%.*s%ls",
            spaceBuffer.c_str(),
            nodeTextLength, nodeText,
            (node.GetGenericType() == TextTree::Node::TypeKey) ? L":" : L""
            );

        // Pre-validate the command names before actually executing them.
        // This spares the user the case where they just make a typing
        // mistake from getting partway through before realizing it.
        if (node.level == 0 && node.GetGenericType() != TextTree::Node::TypeComment)
        {
            uint32_t commandTextLength;
            auto commandText = commands_.GetText(node, OUT commandTextLength);
            int32_t command = GetCommandEnumFromName(commandText, commandTextLength);

            if (command == CommandLineParameterInvalid)
            {
                SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_INTENSITY);
                fwprintf(stderr, L" Unrecognized parameter: %.*s", commandTextLength, commandText);
                foundUnrecognizedCommand = true;
            }
        }

        wprintf(L"\n");

        if (!commands_.AdvanceNextNode(IN OUT nodeIndex))
            break;
    }
    if (foundUnrecognizedCommand)
        return E_INVALIDARG;

    for (uint32_t nodeIndex = firstNodeIndex, nodeCount = commands_.GetNodeCount(); nodeIndex < nodeCount; )
    {
        const auto& node = commands_.GetNode(nodeIndex);
        uint32_t nodeTextLength;
        auto nodeText = commands_.GetText(node, OUT nodeTextLength);

        switch (node.GetGenericType())
        {
        case TextTree::Node::TypeValue:
        case TextTree::Node::TypeKey:
            {
                CommandLineParameter command = GetCommandEnumFromName(nodeText, nodeTextLength);

                switch (command)
                {
                case CommandLineParameterHelp:
                    ShowHelp();
                    return S_OK;

                case CommandLineParameterDWriteDllPath:
                    {
                        std::wstring filePath;
                        commands_.GetSingleSubvalue(nodeIndex, OUT dwriteDllName_);
                        if (dwriteDllName_.empty())
                        {
                            ShowError(L"DWrite DLL parameter should be specified.");
                            return E_INVALIDARG;
                        }
                    }
                    break;
                }
                break;
            } // case Key or Value
        }

        if (!commands_.AdvanceNextNode(IN OUT nodeIndex))
            break;
    }

    return S_OK;
}


HRESULT Application::ProcessCommands()
{
    // Process all the parameters from the command line.

    // Skip any empty root nodes if present.
    uint32_t firstNodeIndex = 0;
    commands_.SkipEmptyNodes(IN OUT firstNodeIndex);

    // Execute all commands in order.

    for (uint32_t nodeIndex = firstNodeIndex, nodeCount = commands_.GetNodeCount(); nodeIndex < nodeCount; )
    {
        const auto& node = commands_.GetNode(nodeIndex);
        uint32_t nodeTextLength;
        auto nodeText = commands_.GetText(node, OUT nodeTextLength);
        CommandLineParameter command = CommandLineParameterInvalid;

        switch (node.GetGenericType())
        {
        case TextTree::Node::TypeComment:
            command = CommandLineParameterNop;
            break;

        case TextTree::Node::TypeValue:
        case TextTree::Node::TypeKey:
            {
                command = GetCommandEnumFromName(nodeText, nodeTextLength);

                switch (command)
                {
                case CommandLineParameterCreateFontCollection:
                    {
                        IFR(EnsureFontCollectionExists());

                        wprintf(L"Font collection family count: %d\n", fontCollection_->GetFontFamilyCount());
                    }
                    break;

                case CommandLineParameterCreateShellFontCollection:
                    {
                        IFR(EnsureFontFilesExist());

                        std::vector<ComPtr<IDWriteFontFile> > fontFiles;
                        IFR(CreateFontFilesFromFileNames(
                                dwriteFactory_,
                                CustomShellFontFileLoader::GetInstance(),
                                fontFilePaths_,
                                OUT fontFiles
                                ));

                        StartTimer(L"CreateShellFontCollection");
                        fontCollection_.Clear();
                        IFR(CreateFontCollection(
                                dwriteFactory_,
                                &fontFiles[0],
                                static_cast<uint32_t>(fontFiles.size()),
                                OUT &fontCollection_
                                ));
                        EndTimer(L"CreateShellFontCollection");

                        wprintf(L"Font collection family count: %d\n", fontCollection_->GetFontFamilyCount());
                    }
                    break;

                case CommandLineParameterCreateFontCollectionFaces:
                    IFR(EnsureFontCollectionExists());

                    StartTimer(L"CreateFontCollectionFaces");
                    IFR(CreateFontCollectionFaces(fontCollection_, /*fontFaces*/nullptr));
                    EndTimer(L"CreateFontCollectionFaces");
                    break;

                case CommandLineParameterCompressFontFiles:
                    {
                        if (fontFilePaths_.empty() && (fontCollection_ == nullptr || fontCollection_->GetFontFamilyCount() == 0))
                        {
                            wprintf(L"Empty font collection\n");
                            return E_INVALIDARG;
                        }

                        uint64_t originalTotalSize = 0;
                        uint64_t compressedTotalSize = 0;

                        if (fontFilePaths_.empty())
                        {
                            uint32_t totalUniqueFileCount = 0;
                            std::vector<ComPtr<IDWriteFontFace> > fontFaces;
                            std::wstring filePaths;

                            StartTimer(L"CompressFontFiles/CreateFontCollectionFaces");
                            IFR(CreateFontCollectionFaces(fontCollection_, OUT &fontFaces));
                            EndTimer(L"CompressFontFiles/CreateFontCollectionFaces");
                            wprintf(L"Total font faces: %d\n", static_cast<uint32_t>(fontFaces.size()));

                            StartTimer(L"CompressFontFiles/GetFilePathsFromFontFaces");
                            IFR(GetFilePathsFromFontFaces(&fontFaces[0], static_cast<uint32_t>(fontFaces.size()), OUT fontFilePaths_, OUT totalUniqueFileCount));
                            EndTimer(L"CompressFontFiles/GetFilePathsFromFontFaces");
                            wprintf(L"Total font files: %d\n", static_cast<uint32_t>(totalUniqueFileCount));
                        }

                        StartTimer(L"CompressFontFiles");
                        IFR(CompressFontFaces(fontFilePaths_, OUT originalTotalSize, OUT compressedTotalSize));
                        EndTimer(L"CompressFontFiles");

                        wprintf(L"Original total font file bytes:   %lld\n", originalTotalSize);
                        wprintf(L"Compressed total font file bytes: %lld\n", compressedTotalSize);
                    }
                    break;

                case CommandLineParameterDrawFontFaceNames:
                    {
                        IFR(EnsureFontCollectionExists());

                        StartTimer(L"DrawFontFaceNames");
                        IFR(DrawFontFacesInTheirOwnNames(dwriteFactory_, fontCollection_));
                        EndTimer(L"DrawFontFaceNames");
                    }
                    break;

                case CommandLineParameterFontFiles:
                    {
                        std::wstring filePath;
                        commands_.GetSingleSubvalue(nodeIndex, OUT filePath);
                        if (filePath.empty())
                        {
                            ShowError(L"FontFiles parameter should be specified.");
                            return E_INVALIDARG;
                        }
                        fontCollection_.Clear(); // Clear any built font collection since specifying a new file set.

                        // Expand any file paths with wildcards in them.
                        if (FileContainsWildcard(filePath.data(), filePath.data() + filePath.size()))
                        {
                            IFR(EnumerateMatchingFiles(
                                    filePath.c_str(),
                                    L"", // originalFileMask
                                    OUT fontFilePaths_
                                    ));
                        }
                        else
                        {
                            std::swap(filePath, fontFilePaths_);
                        }
                    }
                    break;

                case CommandLineParameterShowFontTableSizes:
                    {
                        IFR(EnsureFontFilesExist());
                        StartTimer(L"ShowFontTableSizes");
                        IFR(ShowFontTableSizes(fontFilePaths_));
                        EndTimer(L"ShowFontTableSizes");
                    }
                    break;

                case CommandLineParameterShowGlyfTableSizes:
                    {
                        IFR(EnsureFontFilesExist());
                        StartTimer(L"ShowFontTableSizes");
                        IFR(ShowGlyfTableSizes(fontFilePaths_));
                        EndTimer(L"ShowFontTableSizes");
                    }
                    break;

                case CommandLineParameterProcessFontSetMetadata:
                    {
                        std::wstring inputFilename, outputFilename, baseFilePath, baseServerPath;

                        commands_.GetKeyValue(nodeIndex, L"Input", OUT inputFilename);
                        commands_.GetKeyValue(nodeIndex, L"BaseFilePath", OUT baseFilePath);
                        commands_.GetKeyValue(nodeIndex, L"BaseServerPath", OUT baseServerPath);
                        if (!commands_.GetKeyValue(nodeIndex, L"Output", OUT outputFilename))
                        {
                            ShowError(L"Require input and output file names, e.g.: Input=FontPrimer.json Output=FontDatabase.json");
                            return E_INVALIDARG;
                        }

                        StartTimer(L"ProcessFontSetMetadata");
                        IFR(ProcessFontSetMetadata(
                            dwriteFactory_,
                            fontFilePaths_,
                            inputFilename,
                            outputFilename,
                            baseFilePath,
                            baseServerPath
                            ));
                        EndTimer(L"ProcessFontSetMetadata");
                    }
                    break;

                case CommandLineParameterShowFontNames:
                    {
                        IFR(EnsureFontFilesExist());
                        StartTimer(L"ShowFontNames");
                        IFR(ShowFontNames(dwriteFactory_, fontFilePaths_));
                        EndTimer(L"ShowFontNames");
                    }
                    break;

                case CommandLineParameterWatchFolder:
                    {
                        std::wstring folderPath;
                        commands_.GetSingleSubvalue(nodeIndex, OUT folderPath);
                        if (folderPath.empty())
                        {
                            ShowError(L"FolderPath parameter should be specified.");
                            return E_INVALIDARG;
                        }

                        WatchFolderChanges(folderPath.c_str());
                    }
                    break;
                }

                break;
            } // case Key or Value
        }

        if (command == CommandLineParameterInvalid)
        {
            SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_INTENSITY);
            fwprintf(stderr, L"Unrecognized parameter: %.*s\n", nodeTextLength, nodeText);

            return E_INVALIDARG;
        }

        if (!commands_.AdvanceNextNode(IN OUT nodeIndex))
            break;
    }

    return S_OK;
}


bool WasLaunchedFromShellOrDebugger()
{
    // Pause if launched outside a command line, such as directly from Explorer.
    // Otherwise the console window just flashes by without a chance to see the
    // error or help message.

    STARTUPINFO startupInfo = {};
    GetStartupInfo(&startupInfo);
    if (startupInfo.dwFlags & STARTF_USESHOWWINDOW)
    {
        return true;
    }

    if (IsDebuggerPresent())
    {
        return true;
    }

    return false;
}


#if 0
std::initializer_list<wchar_t> ToInitializerList(const std::vector<wchar_t>& v)
{
    return std::initializer_list<wchar_t>(v.data(), v.data() + v.size());
}


std::initializer_list<wchar_t> ToInitializerList(const std::wstring s)
{
    return std::initializer_list<wchar_t>(s.data(), s.data() + s.size());
}
#endif


#if 0
class Cat
{
public:
    Cat()
    {
        number = totalCats++;
        parentNumber = 0;
        constructions = 0;
        wprintf(L"Cat n%d p%d c%d %08p construct\r\n", number, parentNumber, constructions, this);
    }

    Cat(Cat const& cat)
    {
        number = totalCats++;
        parentNumber = cat.number;
        constructions = 0;
        wprintf(L"Cat n%d p%d c%d %08p construct copy\r\n", number, parentNumber, constructions, this);
    }

    void operator=(Cat const& cat)
    {
        parentNumber = cat.number;
        ++constructions;
        wprintf(L"Cat n%d p%d c%d %08p assign\r\n", number, parentNumber, constructions, this);
    }

    ~Cat()
    {
        wprintf(L"Cat n%d p%d c%d %08p delete\r\n", number, parentNumber, constructions, this);
    }

    int number;
    int parentNumber;
    int constructions;
    static int totalCats;
};
int Cat::totalCats = 0;


void foo(Cat cat3, Cat cat4, Cat cat5)
{
    Cat cat6;
}

Cat foo2(Cat& cat2)
{
    return cat2;
}
#endif

#if 0
struct Lock
{
    Lock(int newX)
    {
        x = newX;
    }

    operator bool() const throw()
    {
        return true;
    }

    int x;
};

void foor()
{
    wprintf(L"TryLocked");
    if (Lock lock = 1)
    {
        lock = 2;
        wprintf(L"Locked");
    }
    wprintf(L"EndLocked");
}
#endif

int __cdecl wmain(int argCount, _In_reads_(argCount) LPWSTR argv[])
{
    std::wstring commandLine;
    GetCommandLineArguments(IN OUT commandLine);

    _setmode(_fileno(stdout), _O_U16TEXT);

#if 1

    {
        std::vector<uint8_t> fileBytes;
        IFR(ReadBinaryFile(L"c:\\windows\\fonts\\msmincho.ttc", OUT fileBytes));
        FileGraph fileGraph;
        fileGraph.SetRange(Range(0, uint32_t(fileBytes.size())));
        fileGraph.GetFileBlock(0).data = FileBlockData(fileBytes.data(), uint32_t(fileBytes.size()));

        OpenTypeFont openTypeFont(fileGraph, /*blockIndex*/0);
        openTypeFont.Parse();
        uint32_t tableIndex = 0;
        IFR(openTypeFont.InsertTable(/*faceIndex*/0, DWRITE_MAKE_OPENTYPE_TAG('f', 'o', 'b', 'r'), OUT tableIndex));
        auto& fileBlock = fileGraph.GetFileBlock(tableIndex);
        fileBlock.data.resize(325);

        RefCountPtr<OpenTypeMetaTableEditor> metaTableEditor;
        IFR(OpenTypeMetaTableEditor::Create(openTypeFont, /*faceIndex*/0, OUT metaTableEditor));
        std::wstring metaTableText = L"en-US;ja-JP;";
        std::vector<char> utf8Text;
        ConvertText(metaTableText, OUT utf8Text);
        IFR(metaTableEditor->InsertMap(DWRITE_MAKE_OPENTYPE_TAG('d','l','n','g'), const_byte_array_ref::reinterpret(utf8Text)));

        IFR(openTypeFont.PreUpdateData());
        IFR(openTypeFont.UpdateData());

        std::vector<uint8_t> newFileBytes;
        IFR(fileGraph.WriteData(/*blockIndex*/0, OUT newFileBytes));
        IFR(WriteBinaryFile(L"o:\\temp\\msmincho.ttc", newFileBytes));
    }

#if 0
    MetaTable metaTable(fileGraph, blockIndex);
    uint32_t blockIndex;
    fileGraph.InsertFileBlock(/*parentIndex*/ 0, Range(0 , 20), OUT blockIndex);
    fileGraph.InsertFileBlock(/*parentIndex*/ 0, Range(20, 50), OUT blockIndex);
    fileGraph.InsertFileBlock(/*parentIndex*/ 0, Range(60, 80), OUT blockIndex);
    fileGraph.InsertFileBlock(/*parentIndex*/ 0, Range(50, 60), OUT blockIndex);
    auto& fileBlock = fileGraph.GetFileBlock(blockIndex);
    fileBlock.data.assign({ 1, 4, 6, 0, 20 });
    //fileGraph.RefreshBlocksData();
    //fileGraph.ResequenceBlocks();
    //AutoPointer<IFileBlockData> subdata;
    std::vector<uint8_t> bytes(100);
    FileGraphTarget graphTarget(bytes.data(), fileGraph.GetRange().end);
    fileGraph.WriteData(0, IN OUT graphTarget);
    fileGraph.RealignBlocks(1);
    fileGraph.DeleteFileBlock(2);
#endif
#endif

    try
     {
        Application app;
        if (app.ParseCommandLine(commandLine.c_str()))
        {
            HRESULT hr = S_OK;
            if (FAILED(hr = app.PreprocessCommands())
            ||  FAILED(hr = app.Initialize())
            ||  FAILED(hr = app.ProcessCommands()))
            {
                SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_INTENSITY);
                fwprintf(stderr, L"Error code: %08X\n", hr);
            }
        }
    }
    catch (std::exception const& e)
    {
        SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_INTENSITY);
        fwprintf(stderr, L"Error: %ls\n", e.what());
    }
    catch (...)
    {
        SetAndSaveConsoleColor cc(FOREGROUND_RED | FOREGROUND_INTENSITY);
        fwprintf(stderr, L"Unknown error\n");
    }

    if (WasLaunchedFromShellOrDebugger())
    {
        wprintf(L"Press any key to end\n");
        #pragma prefast(suppress:__WARNING_RETVAL_IGNORED_FUNC_COULD_FAIL, "Q: And just what key is the 'any' key exactly? A: It doesn't matter.")
        _getch();
    }
}
