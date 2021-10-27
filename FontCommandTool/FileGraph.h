//+---------------------------------------------------------------------------
//
//  Contents:   File graph, for modifying the layout of binary files.
//
//  History:    2015-03-18   dwayner    Created
//
//----------------------------------------------------------------------------


class FileGraph;
struct FileBlock;
class FileBlockData;

// Arbitrary memory target for the FileGraph to write bytes to.
// - Note this class only writes to memory targets, not files, but you can write
//   to the view of a memory mapped file.
// - Passing nullptr to the constructor is a nop, but it still updates the
//   written size. This is useful if you want to just calculate the size before
//   actually writing anything yet.
class FileGraphTarget
{
public:
    FileGraphTarget(_Out_writes_bytes_opt_(byteSize) void* bytes, uint32_t byteSize);
    HRESULT WriteBytes(uint32_t byteOffset, _In_reads_bytes_(byteSize) void const* bytes, uint32_t byteSize);
    HRESULT WriteBytes(_In_reads_bytes_(byteSize) void const* bytes, uint32_t byteSize);
    HRESULT WriteBytes(std::vector<uint8_t> const& v);
    uint32_t GetWrittenSize();

protected:
    _Field_size_(byteSize_) void* bytes_= nullptr;
    uint32_t byteSize_ = 0;
    uint32_t writtenSize_ = 0;
};


// Base for any class that modifies/edits the data in a specific file block.
// For example, you might have an OpenTypeFontFace that edits OpenType data.
class FileBlockDataEditor : public RefCountBase
{
public:
    FileBlockDataEditor(FileGraph& fileGraph, uint32_t blockIndex);

    virtual ~FileBlockDataEditor();

    // Called by the FileGraph when a FileBlock is dirty so that the editor can
    // refresh any data blocks as needed.
    virtual HRESULT PreUpdateData();
    virtual HRESULT UpdateData();

    FileBlock& GetFileBlock();

    FileGraph& fileGraph_;
    uint32_t blockIndex_;
};


// Reference counted block of file data.
// The data is mutable, but since the block can be shared by multiple readers,
// each with a different view range into the raw data, changing the size
// generally creates a copy.
class FileBlockData
{
public:
    using size_type = uint32_t;
    using pointer = uint8_t*;
    using reference = uint8_t&;
    using iterator = pointer;

    // Take make things simpler, file block data never points to nullptr,
    // instead pointing to an empty block.
    FileBlockData();

    // The constructor always makes a copy.
    FileBlockData(_In_reads_(byteSize) void* p, uint32_t byteSize);
    FileBlockData(FileBlockData const& other);
    FileBlockData(FileBlockData const& other, Range range);

    void clear() throw();
    inline uint8_t* data() throw();
    inline uint8_t const* data() const throw();
    operator uint8_t*() throw();
    operator uint8_t const*() const throw();
    uint8_t& operator[](size_t i) throw();
    uint8_t const& operator[](size_t i) const throw();
    iterator begin() throw();
    iterator end() throw();
    size_type size() const throw();
    bool empty() const throw();
    Range& GetRange() throw();
    void resize(size_type newSize);
    void ShrinkBy(uint32_t reducedByteSize);
    void GrowBy(uint32_t additionalByteSize);
    void InsertBytes(uint32_t byteOffset, const_byte_array_ref data);
    void DeleteBytes(uint32_t byteOffset, uint32_t byteCount);
    void append(const_byte_array_ref newData);

    byte_array_ref get_array_ref() throw();
    operator byte_array_ref() throw();
    operator const_byte_array_ref() throw();

    template <typename T>
    array_ref<T> get_array_ref_as() throw()
    {
        return array_ref<T>(begin(), end());
    }

protected:
    struct RefCountedBytes : public RefCountBase
    {
        RefCountedBytes() throw() {};
        RefCountedBytes(uint32_t byteSize) throw() : capacity_(byteSize) {}
        RefCountedBytes(uint32_t byteSize, uint32_t refCount) throw() : RefCountBase(refCount), capacity_(byteSize) {}

        // Avoid accidental copying or moves. Only new blocks can be created.
        RefCountedBytes(RefCountedBytes&) = delete;
        RefCountedBytes& operator=(RefCountedBytes&) = delete;

        static RefCountedBytes* Create(uint32_t byteCount);

        inline uint8_t* data() throw() { return reinterpret_cast<uint8_t*>(this->bytes_); }
        inline uint8_t const* data() const throw() { return reinterpret_cast<uint8_t const*>(this->bytes_); }

        size_type capacity_ = 0; // Total byte size
        uint8_t bytes_[1];
    };

    static RefCountedBytes emptyBytes_;

    RefCountPtr<RefCountedBytes> data_; // Pointer to DataBlock
    Range dataRange_;
};


struct FileBlock
{
    enum Flags : uint32_t
    {
        FlagsNone        = 0,

        // Byte alignment from 1..255 (0 or 1 means none)
        // They need not be powers of two, but typically would be.
        // For example, OpenType tables are aligned to four byte multiples.
        FlagsAlignment   = 0x000000FFu,

        // The data has been modified.
        FlagsStaleData   = 0x00000100u,

        // Data size changed (need to recompute sibling offsets).
        FlagsStaleSize   = 0x00000200u,

        // The IsDeletable flag is useful for when an editor tries to delete
        // a file block when there may still be references to it from other
        // editors. In that case, the block is marked as deletable but not
        // actual deleted until the parent editor confirm thats, potentially
        // asking its children nodes whether any of them reference the blocks.
        // If so, the IsDeletable flag is reset, and the block is kept. This is
        // a deferred alternative to reference counting every block.
        //
        // Such a case exists with TrueType font collections where multiple
        // table directories all reference a shared table. Deleting a table
        // from one face does not actually delete the table from the file
        // unless the table is removed from all faces.
        FlagsIsDeletable = 0x00000400u,

        // This block is no longer accessible and has no data. The block index
        // is left in place so that references to other blocks remain valid,
        // and this file block is not recycled so that indices remain unique.
        FlagsIsDeleted   = 0x00000800u,

        FlagsStaleDataAndSize = FlagsStaleData | FlagsStaleSize,
    };

    // Byte data for this block.
    // If the data size is modified manually, the block needs to be marked as stale.
    // The data can be empty if all the data is contained in the child nodes.
    FileBlockData data;

    // Further break-down of the file data. May be null if pure data.
    RefCountPtr<FileBlockDataEditor> dataEditor;

    // Byte range this block occupies in the file. The range may be old if
    // the block's data is stale and needs to be recomputed, due to other
    // blocks changing in size.
    Range range = {0, 0};

    // Indices of previous and next block. Zero is actually legitimate index
    // (the root parent index), but because the root is never part of a linked
    // list, zero serves as a sentinel value for previous, next, and child.
    uint32_t previous = 0;
    uint32_t next     = 0;
    uint32_t child    = 0;
    uint32_t parent   = 0;

    // Dirty state and alignment.
    Flags flags = FlagsNone;

    inline uint32_t GetAlignment() const throw()
    {
        return flags & FlagsAlignment;
    }

    inline void SetAlignment(uint8_t alignment) throw()
    {
        flags = static_cast<Flags>((flags & ~FlagsAlignment) | alignment);
    }
};

DEFINE_ENUM_FLAG_OPERATORS(FileBlock::Flags);


class FileGraph
{
public:
    enum NavigationDirection
    {
        NavigationDirectionSiblingNext      = 0,
        NavigationDirectionSiblingPrevious  = 1,
        NavigationDirectionChild            = 2,
        NavigationDirectionParent           = 3,
        NavigationDirectionRelationshipMask = 3,
    };

    FileGraph();

    Range GetRange() const throw();
    void SetRange(Range fileRange);
    FileBlock& GetFileBlock(uint32_t blockIndex);
    FileBlock& GetFileBlockForModification(uint32_t blockIndex); // Marks the data block as stale.
    void SetStaleFileBlock(uint32_t blockIndex);
    HRESULT AllocateFileBlock(_Out_ uint32_t& blockIndex);
    HRESULT AllocateFileBlock(uint32_t parentIndex, uint32_t optionalSiblingIndex, Range range, _Out_ uint32_t& newIndex);
    HRESULT InsertFileBlock(uint32_t parentIndex, uint32_t optionalSiblingIndex, Range range, _Out_ uint32_t& newIndex);
    HRESULT InsertFileBlock(uint32_t parentIndex, Range range, uint32_t previousIndexHint, _Out_ uint32_t& newIndex);
    HRESULT InsertFileBlock(uint32_t parentIndex, bool insertAfter, _Out_ uint32_t& newBlockIndex);
    HRESULT DeleteFileBlock(uint32_t blockIndex);

    // Descend into a child, creating an empty child.
    HRESULT MakeFirstChild(uint32_t parentIndex, _Out_ uint32_t& childIndex);

    HRESULT LinkFileBlock(uint32_t parentIndex, uint32_t optionalSiblingIndex, uint32_t childIndex, bool insertAfter); // Links a block to another.
    HRESULT UnlinkFileBlock(uint32_t blockIndex); // Unlinks from tree without deleting.
    HRESULT WriteData(uint32_t blockIndex, _Inout_ FileGraphTarget& target); // Passing 0 means the root, which writes the whole file.
    HRESULT WriteData(uint32_t blockIndex, _Inout_ std::vector<uint8_t>& v); // Passing 0 means the root, which writes the whole file.
    HRESULT FindBlockIndexFromRange(Range range, bool returnExactMatchesOnly, _Inout_ uint32_t& blockIndex, _Out_ int32_t& blockComparison);

    HRESULT SetFlags(uint32_t blockIndex, FileBlock::Flags set, FileBlock::Flags clear = FileBlock::FlagsNone);

    // Move a single block in one direction. Returns true if the move was possible. Otherwise blockIndex remains unchanged.
    bool NavigateBlock(NavigationDirection navigationDirection, _Inout_ uint32_t& blockIndex);

    // Move multiple blocks. Returns true if a move was possible by count advances. Otherwise blockIndex points to the last one possible.
    bool NavigateBlocks(NavigationDirection navigationDirection, uint32_t count, _Inout_ uint32_t& blockIndex);

    HRESULT RealignBlocks(uint32_t firstBlockIndex);

protected:
    std::vector<FileBlock> fileBlocks_;
};


#if 0
interface IFileBlockData
{
    enum Flags
    {
        FlagsNone = 0,
        FlagsDirty = 1,
    };
    virtual ~IFileBlockData() {};
    virtual bool IsDirty() const throw() = 0;
    virtual void SetFlags(Flags set, Flags clear = FlagsNone) = 0;
    virtual std::vector<uint8_t> GetData() = 0;
};


class FileBlockData : public IFileBlockData
{
public:
    FileBlockData() = default;

    FileBlockData(IFileBlockData* parent) :
        parent_{parent}
    {
    }

    bool IsDirty() const throw() override
    {
        return !!(flags_ & FlagsDirty);
    }

    void SetFlags(Flags set, Flags clear = FlagsNone)
    {
        Flags newFlags = (flags_ & ~clear) | set;
        auto newlySetFlags = (newFlags ^ flags_) & newFlags;
        flags_ = newFlags;

        // If the dirty flag was set, update the parent too.
        if ((newlySetFlags & FlagsDirty) && (parent_ != nullptr))
        {
            parent_->SetFlags(FlagsDirty);
        }
    }

    std::vector<uint8_t> GetData()
    {
        if (IsDirty())
            RefreshBlocksData();
                
        // Do not call ResequenceBlocks() explicitly here,
        // leaving that up to the specific implementation.

        std::vector<uint8_t> data;

        // Determine the size by getting the ending offset of the greatest block.
        uint32_t dataSize = 0;
        for (auto& fileBlock : fileBlocks_)
        {
            dataSize = std::max(dataSize, fileBlock.range.end);
        }
        data.resize(dataSize);

        // Copy the data
        for (auto& fileBlock : fileBlocks_)
        {
            if (!fileBlock.range.IsEmpty())
            {
                memcpy(OUT &data[fileBlock.range.begin], fileBlock.data.data(), fileBlock.data.size());
            }
        }

        SetFlags(FlagsNone, FlagsDirty);

        return data;
    }

    uint32_t FindBlockIndexFromBlockId(uint32_t blockId)
    {
        uint32_t blockIndex = 0, blockCount = static_cast<uint32_t>(fileBlocks_.size());
        for (; blockIndex < blockCount && fileBlocks_[blockIndex].blockId != blockId; ++blockIndex)
        { }

        return blockIndex;
    }

    // Return the nearest block that covers the given range. If the range...
    // - is within any block, it returns the block index and
    //   isInsideBlock as true.
    // - overlaps the block but is not wholly contained within, it returns
    //   the first matching block but with isInsideBlock as false.
    // - is in a gap between blocks, the index is rounded up to the next one.
    // - is beyond the end of all blocks, it returns an index equal to the
    //   total count of blocks.
    uint32_t FindBlockIndexFromRange(
        Range range,
        _Out_ bool& isInsideBlock
        )
    {
        isInsideBlock = false;
        uint32_t blockIndex = 0;
        uint32_t blockCount = static_cast<uint32_t>(fileBlocks_.size());

        // Early out for the common case where multiple blocks are being
        // appended sequentially to the end while reading through a file.
        if (blockCount > 0 && range.begin >= fileBlocks_.back().range.end)
        {
            return blockCount;
        }

        // Search all blocks where blockOffset.
        for (; blockIndex < blockCount; ++blockIndex)
        {
            auto const& fileBlock = fileBlocks_[blockIndex];
            if (range.IsWithin(fileBlock.range))
            {
                isInsideBlock = true;
                break;
            }
            else if (fileBlock.range.begin >= range.begin)
            {
                // Else passed the desired offset. Return this block,
                // the rounded up index.
                break;
            }
        }

        // No match. Return fileBlocks_.size().
        return blockIndex;
    }

    // A block index beyond the total count of blocks is invalid.
    FileBlock& GetFileBlockByIndex(uint32_t blockIndex)
    {
        if (blockIndex > fileBlocks_.size())
            throw std::out_of_range("blockIndex is greater than fileBlocks_ size");

        return fileBlocks_[blockIndex];
    }

    // A block index beyond the total count of blocks is invalid.
    uint32_t InsertFileBlockByIndex(uint32_t blockIndex)
    {
        if (blockIndex > fileBlocks_.size())
            throw std::out_of_range("blockIndex is greater than fileBlocks_ size");

        auto it = fileBlocks_.emplace(fileBlocks_.begin() + blockIndex);
        it->blockId = nextBlockId_++;

        SetFlags(FlagsDirty);

        return blockIndex;
    }

    // Add a file block with offset and block size.
    uint32_t InsertFileBlock(uint32_t blockOffset, uint32_t blockSize, bool isNewBlock = true)
    {
        // Find where to insert the new block.
        auto newRange = Range::FromCount(blockOffset, blockSize);
        bool isInsideBlock;
        uint32_t blockIndex = FindBlockIndexFromRange(newRange, OUT isInsideBlock);
        auto insertionPoint = fileBlocks_.begin() + blockIndex;

        if (insertionPoint == fileBlocks_.end() || newRange != insertionPoint->range)
        {
            auto it = fileBlocks_.emplace(insertionPoint);
            it->blockId = nextBlockId_++;
            it->range = newRange;
        }

        // Mark the data as dirty if adding a new block.
        // The caller sets isNewBlock = false when adding an existing block.
        if (isNewBlock)
        {
            SetFlags(FlagsDirty);
        }

        return blockIndex;
    }

    void RefreshBlocksData()
    {
        // Refresh the data of any child blocks and cache it.
        for (auto& fileBlock : fileBlocks_)
        {
            if (fileBlock.subdata != nullptr && fileBlock.subdata->IsDirty())
            {
                // Cache the data again.
                fileBlock.data = fileBlock.subdata->GetData();
                uint32_t subdataSize = static_cast<uint32_t>(fileBlock.data.size());
                fileBlock.range.end = fileBlock.range.begin + subdataSize;
            }
        }
    }

    void ResequenceBlocks()
    {
        // Resequence all the blocks based on their new sizes.
        uint32_t dataSize = 0;
        for (auto& fileBlock : fileBlocks_)
        {
            // If alignment is greater than a byte, align the offset up to
            // to a multiple (any multiple, not just powers of two).
            if (fileBlock.alignment > 1)
            {
                uint32_t dataRemainder = dataSize % fileBlock.alignment;
                if (dataRemainder > 0)
                {
                    dataSize += fileBlock.alignment - dataRemainder;
                }
            }

            // Move the data block to its new location.
            uint32_t subdataSize = static_cast<uint32_t>(fileBlock.data.size());
            fileBlock.range.begin = dataSize;
            fileBlock.range.end = dataSize + subdataSize;
            dataSize += subdataSize;
        }
    }

protected:
    Flags flags_ = FlagsNone;
    uint32_t nextBlockId_ = 0;
    IFileBlockData* parent_ = nullptr; // Weak pointer to containing parent.

    std::vector<FileBlock> fileBlocks_;
};


#endif
