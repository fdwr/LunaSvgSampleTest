//+---------------------------------------------------------------------------
//
//  Contents:   File graph, for modifying the layout of binary files.
//
//  History:    2015-03-18   dwayner    Created
//
//----------------------------------------------------------------------------
#include "precomp.h"


FileBlockDataEditor::FileBlockDataEditor(
    FileGraph& fileGraph,
    uint32_t blockIndex
    )
:   fileGraph_(fileGraph),
    blockIndex_(blockIndex)
{}


FileBlockDataEditor::~FileBlockDataEditor()
{}


HRESULT FileBlockDataEditor::PreUpdateData()
{
    return S_OK;
}


HRESULT FileBlockDataEditor::UpdateData()
{
    return S_OK;
}


FileBlock& FileBlockDataEditor::GetFileBlock()
{
    return fileGraph_.GetFileBlock(blockIndex_);
}


FileGraphTarget::FileGraphTarget(_Out_writes_bytes_opt_(byteSize) void* bytes, uint32_t byteSize)
:   bytes_(bytes),
    byteSize_(byteSize)
{
}


FileBlockData::RefCountedBytes FileBlockData::emptyBytes_ = {/*size*/0, /*refCount*/1};


HRESULT FileGraphTarget::WriteBytes(uint32_t byteOffset, _In_reads_bytes_(byteSize) void const* bytes, uint32_t byteSize)
{
    auto newSize = byteOffset + byteSize;
    if (newSize < byteOffset)
    {
        return HRESULT_FROM_WIN32(ERROR_ARITHMETIC_OVERFLOW);
    }
    if (bytes != nullptr)
    {
        if (newSize > byteSize_)
        {
            return HRESULT_FROM_WIN32(ERROR_FILE_TOO_LARGE);
        }
        memcpy(OUT &reinterpret_cast<uint8_t*>(bytes_)[byteOffset], bytes, byteSize);
    }
    writtenSize_ = std::max(newSize, writtenSize_);
    return S_OK;
}


HRESULT FileGraphTarget::WriteBytes(_In_reads_bytes_(byteSize) void const* bytes, uint32_t byteSize)
{
    return WriteBytes(writtenSize_, bytes, byteSize);
}


HRESULT FileGraphTarget::WriteBytes(std::vector<uint8_t> const& v)
{
    return WriteBytes(v.data(), static_cast<uint32_t>(v.size()));
}


uint32_t FileGraphTarget::GetWrittenSize()
{
    assert(writtenSize_ <= byteSize_ || bytes_ == nullptr);
    return writtenSize_;
}


FileGraph::FileGraph()
{
    fileBlocks_.resize(1);
}


Range FileGraph::GetRange() const throw()
{
    assert(!fileBlocks_.empty());
    return fileBlocks_.front().range;
}


void FileGraph::SetRange(Range fileRange)
{
    assert(!fileBlocks_.empty());
    fileBlocks_.front().range = fileRange;
}


FileBlock& FileGraph::GetFileBlock(uint32_t blockIndex)
{
    if (blockIndex > fileBlocks_.size())
        throw std::out_of_range("blockIndex is greater than fileBlocks_ size");

    return fileBlocks_[blockIndex];
}


FileBlock& FileGraph::GetFileBlockForModification(uint32_t blockIndex)
{
    if (blockIndex > fileBlocks_.size())
        throw std::out_of_range("blockIndex is greater than fileBlocks_ size");

    // todo: set flags
    return fileBlocks_[blockIndex];
}


void FileGraph::SetStaleFileBlock(uint32_t blockIndex)
{
    //todo: recurse for ()
}


HRESULT FileGraph::LinkFileBlock(
    uint32_t parentIndex,
    uint32_t optionalSiblingIndex,
    uint32_t childIndex,
    bool insertAfter
    )
{
    // Stitch the new child block into the existing siblings.

    auto fileBlockSize = fileBlocks_.size();
    if (parentIndex >= fileBlockSize || childIndex >= fileBlockSize || optionalSiblingIndex >= fileBlockSize)
        return E_BOUNDS;

    if (childIndex == 0)
        return E_INVALIDARG;

    FileBlock& childFileBlock = fileBlocks_[childIndex];

    // The sibling index can be zero if adding a new child the first time,
    // or if adding additional children to the front of the list.
    uint32_t siblingIndex = optionalSiblingIndex;
    if (siblingIndex == 0)
    {
        FileBlock& parentFileBlock = fileBlocks_[parentIndex];
        siblingIndex = parentFileBlock.child;
        assert(fileBlocks_[siblingIndex].parent == parentIndex);

        if (siblingIndex == 0)
        {
            // If there are no children yet, assign the new block as the first child.
            parentFileBlock.child = childIndex;
            childFileBlock.parent = parentIndex;
            return S_OK;
        }
    }

    FileBlock& siblingFileBlock   = fileBlocks_[siblingIndex];
    uint32_t previousSiblingIndex = insertAfter ? siblingIndex : siblingFileBlock.previous;
    uint32_t nextSiblingIndex     = insertAfter ? siblingFileBlock.next : siblingIndex;
    uint32_t actualParentIndex    = siblingFileBlock.parent;

    if (parentIndex != actualParentIndex && parentIndex != 0)
        return E_INVALIDARG;

    childFileBlock.parent = actualParentIndex;
    childFileBlock.next = nextSiblingIndex;
    childFileBlock.previous = previousSiblingIndex;

    // Point the sibling after back to the child.
    if (nextSiblingIndex != 0)
    {
        FileBlock& nextSiblingFileBlock = fileBlocks_[nextSiblingIndex];
        assert(nextSiblingFileBlock.previous == previousSiblingIndex);
        nextSiblingFileBlock.previous = childIndex;
    }
    // Point the sibling before forward to the child.
    if (previousSiblingIndex != 0)
    {
        FileBlock& previousSiblingFileBlock = fileBlocks_[previousSiblingIndex];
        assert(previousSiblingFileBlock.next == nextSiblingIndex);
        previousSiblingFileBlock.next = childIndex;
    }

    return S_OK;
}


HRESULT FileGraph::AllocateFileBlock(_Out_ uint32_t& blockIndex)
{
    blockIndex = 0;
    uint32_t childIndex = static_cast<uint32_t>(fileBlocks_.size());
    fileBlocks_.resize(childIndex + 1);
    blockIndex = childIndex;
    return S_OK;
}


HRESULT FileGraph::AllocateFileBlock(
    uint32_t parentIndex,
    uint32_t optionalSiblingIndex,
    Range range,
    _Out_ uint32_t& newBlockIndex
    )
{
    newBlockIndex = 0;

    auto fileBlockSize = fileBlocks_.size();
    if (parentIndex >= fileBlockSize || optionalSiblingIndex >= fileBlockSize)
        return E_BOUNDS;

    // Determine which two blocks to insert the new file block if there are
    // existing children. Start from the optional hint index if given.
    uint32_t firstChildIndex = fileBlocks_[parentIndex].child;
    uint32_t siblingIndex = (optionalSiblingIndex == 0) ? firstChildIndex : optionalSiblingIndex;
    int32_t blockComparison = 0;
    if (firstChildIndex != 0)
    {
        IFR(FindBlockIndexFromRange(range, /*returnExactMatchesOnly*/true, IN OUT siblingIndex, OUT blockComparison));
        if (blockComparison == 0)
        {
            newBlockIndex = siblingIndex;
            return S_OK;
        }
    }

    // Create a child file block, and link it with its siblings.
    uint32_t childIndex;
    IFR(AllocateFileBlock(OUT childIndex));
    IFR(LinkFileBlock(parentIndex, siblingIndex, childIndex, /*insertAfter*/blockComparison >= 0))

    // Set the initial range, referring to data from the other block data.
    FileBlock& childFileBlock = fileBlocks_[childIndex];
    FileBlock const& parentFileBlock = fileBlocks_[parentIndex];
    childFileBlock.range = range;
    childFileBlock.data = parentFileBlock.data;
    childFileBlock.data.GetRange().OffsetAndIntersect(range);

    newBlockIndex = childIndex;

    return S_OK;
}


HRESULT FileGraph::MakeFirstChild(uint32_t parentIndex, _Out_ uint32_t& childIndex)
{
    childIndex = 0;

    auto fileBlockSize = fileBlocks_.size();
    if (parentIndex >= fileBlockSize)
        return E_BOUNDS;

    uint32_t firstChildIndex = fileBlocks_[parentIndex].child;
    if (firstChildIndex == 0)
    {
        IFR(AllocateFileBlock(OUT firstChildIndex));
        auto& childFileBlock = fileBlocks_[firstChildIndex];
        auto& parentFileBlock = fileBlocks_[parentIndex];
        parentFileBlock.child = firstChildIndex;
        childFileBlock.parent = parentIndex;
    }
    childIndex = firstChildIndex;

    return S_OK;
}


HRESULT FileGraph::InsertFileBlock(
    uint32_t parentIndex,
    bool insertAfter,
    _Out_ uint32_t& newBlockIndex
    )
{
    newBlockIndex = 0;

    auto fileBlockSize = fileBlocks_.size();
    if (parentIndex >= fileBlockSize)
        return E_BOUNDS;

    // Get the sibling block to insert before or after.
    // If there is no sibling block, just use an empty range.
    uint32_t siblingIndex = 0;
    uint32_t firstChildIndex = fileBlocks_[parentIndex].child;
    Range range(0, 0);
    if (firstChildIndex != 0)
    {
        siblingIndex = firstChildIndex;
        if (insertAfter)
        {
            NavigateBlocks(NavigationDirectionSiblingNext, UINT32_MAX, IN OUT siblingIndex);
        }
        // Adopt the range of the sibling.
        FileBlock& siblingFileBlock = fileBlocks_[siblingIndex];
        range.begin = insertAfter ? siblingFileBlock.range.end : siblingFileBlock.range.begin;
        range.end = range.begin;
    }

    // Create a child file block, and link it with its siblings.
    uint32_t childIndex;
    IFR(AllocateFileBlock(OUT childIndex));
    IFR(LinkFileBlock(parentIndex, siblingIndex, childIndex, insertAfter));

    // Set the initial range.
    FileBlock& childFileBlock = fileBlocks_[childIndex];
    FileBlock const& parentFileBlock = fileBlocks_[parentIndex];
    childFileBlock.range = range;
    childFileBlock.data = parentFileBlock.data;
    childFileBlock.data.GetRange().OffsetAndIntersect(range);

    newBlockIndex = childIndex;

    return S_OK;
}


HRESULT FileGraph::InsertFileBlock(
    uint32_t parentIndex,
    uint32_t optionalSiblingIndex, // Allowed to be zero
    Range range,
    _Out_ uint32_t& newBlockIndex
    )
{
    newBlockIndex = 0;

    auto fileBlockSize = fileBlocks_.size();
    if (parentIndex >= fileBlockSize || optionalSiblingIndex >= fileBlockSize)
        return E_BOUNDS;

    // Determine which two blocks to insert the new file block if there are
    // existing children. Start from the optional hint index if given.
    uint32_t firstChildIndex = fileBlocks_[parentIndex].child;
    uint32_t siblingIndex = (optionalSiblingIndex == 0) ? firstChildIndex : optionalSiblingIndex;
    int32_t blockComparison = 0;
    if (firstChildIndex != 0)
    {
        IFR(FindBlockIndexFromRange(range, /*returnExactMatchesOnly*/false, IN OUT siblingIndex, OUT blockComparison));
    }

    // Create a child file block, and link it with its siblings.
    uint32_t childIndex;
    IFR(AllocateFileBlock(OUT childIndex));
    IFR(LinkFileBlock(parentIndex, siblingIndex, childIndex, /*insertAfter*/blockComparison >= 0))

    // Set the initial range.
    FileBlock& childFileBlock = fileBlocks_[childIndex];
    FileBlock const& parentFileBlock = fileBlocks_[parentIndex];
    childFileBlock.range = range;
    childFileBlock.data = parentFileBlock.data;
    childFileBlock.data.GetRange().OffsetAndIntersect(range);

    newBlockIndex = childIndex;

    return S_OK;
}


HRESULT FileGraph::UnlinkFileBlock(uint32_t blockIndex)
{
    if (blockIndex >= fileBlocks_.size())
        return E_BOUNDS;

    FileBlock& fileBlock = fileBlocks_[blockIndex];

    // Relink the next and previous pointers between siblings.
    if (fileBlock.next != 0)
    {
        FileBlock& nextSiblingFileBlock = fileBlocks_[fileBlock.next];
        assert(nextSiblingFileBlock.previous == blockIndex);
        nextSiblingFileBlock.previous = fileBlock.previous;
    }
    if (fileBlock.previous != 0)
    {
        FileBlock& previousSiblingFileBlock = fileBlocks_[fileBlock.previous];
        assert(previousSiblingFileBlock.next == blockIndex);
        previousSiblingFileBlock.next = fileBlock.next;
    }

    // If removing the first child from a level, update the parent to point to
    // the new first child.
    FileBlock& parentFileBlock = fileBlocks_[fileBlock.parent];
    if (parentFileBlock.child == blockIndex)
    {
        parentFileBlock.child = fileBlock.next;
    }

    fileBlock.parent = 0;
    fileBlock.next = 0;
    fileBlock.previous = 0;

    // Note, just ignore all children - they are inaccessible anyway from the
    // graph and will be left silently in place. Also, keep them in case this
    // block is being unlinked, only to reparent it.

    return S_OK;
}


HRESULT FileGraph::DeleteFileBlock(uint32_t blockIndex)
{
    IFR(UnlinkFileBlock(blockIndex));

    FileBlock& fileBlock = fileBlocks_[blockIndex];
    fileBlock.flags |= FileBlock::FlagsIsDeleted;
    fileBlock.data.clear();

    // Note we don't bother deleting all children, since they are inaccessible anyway.

    return S_OK;
}


HRESULT FileGraph::SetFlags(uint32_t blockIndex, FileBlock::Flags set, FileBlock::Flags clear)
{
    if (blockIndex >= fileBlocks_.size())
        return E_BOUNDS;

    FileBlock& fileBlock = fileBlocks_[blockIndex];

    FileBlock::Flags newFlags = (fileBlock.flags & ~clear) | set;
    auto newlySetFlags = (newFlags ^ fileBlock.flags) & newFlags;
    fileBlock.flags = newFlags;

    // If the dirty flag was set, update the parent too.
    if ((newlySetFlags & (FileBlock::FlagsStaleData|FileBlock::FlagsStaleSize)) && (blockIndex != 0))
    {
        SetFlags(fileBlock.parent, set, clear);
    }

    return S_OK;
}


HRESULT FileGraph::WriteData(uint32_t blockIndex, _Inout_ std::vector<uint8_t>& v)
{
    if (blockIndex >= fileBlocks_.size())
        return E_BOUNDS;

    // Resize the vector, and write into it.
    FileBlock const& fileBlock = fileBlocks_[blockIndex];
    auto size = fileBlock.range.GetCount();
    v.resize(size);
    FileGraphTarget target(v.data(), size);
    return WriteData(blockIndex, OUT target);
}


HRESULT FileGraph::WriteData(uint32_t blockIndex, _Inout_ FileGraphTarget& target)
{
    if (blockIndex >= fileBlocks_.size())
        return E_BOUNDS;

    uint32_t parentOffset = target.GetWrittenSize();
    std::vector<uint32_t> parentOffsets;

    for (;;)
    {
        assert(blockIndex < fileBlocks_.size());
        FileBlock const& fileBlock = fileBlocks_[blockIndex];

        // If this block has children, recurse into them.
        // Else as a terminal node, just write the data.
        bool shouldRecurse = (fileBlock.child != 0) || fileBlock.data.empty();
        uint32_t fileOffset = parentOffset + fileBlock.range.begin;
        if (!shouldRecurse)
        {
            // Write the data directly if already cached.
            IFR(target.WriteBytes(
                fileOffset,
                fileBlock.data.data(),
                static_cast<uint32_t>(fileBlock.data.size())
                ));
            wprintf(L"%d=@%d x%d\r\n", blockIndex, fileOffset, uint32_t(fileBlock.data.size()));
        }

        if (shouldRecurse && NavigateBlock(NavigationDirectionChild, IN OUT blockIndex))
        {
            // Recurse into each of the children.
            wprintf(L">>>%d\r\n", blockIndex);
            parentOffsets.push_back(parentOffset);
            parentOffset = fileOffset;
        }
        else while (!FileGraph::NavigateBlock(NavigationDirectionSiblingNext, IN OUT blockIndex))
        {
            if (!FileGraph::NavigateBlock(NavigationDirectionParent, IN OUT blockIndex))
                return S_OK;

            wprintf(L"<<<%d\r\n", blockIndex);
            parentOffset = parentOffsets.back();
            parentOffsets.pop_back();
        }
    }

    return S_OK;
}


bool FileGraph::NavigateBlock(NavigationDirection navigationDirection, _Inout_ uint32_t& blockIndex)
{
    auto newIndex = blockIndex;
    if (newIndex >= fileBlocks_.size())
        return false;

    auto const& fileBlock = fileBlocks_[newIndex];
    switch (navigationDirection & NavigationDirectionRelationshipMask)
    {
    case NavigationDirectionSiblingNext:
        newIndex = fileBlock.next;
        break;

    case NavigationDirectionSiblingPrevious:
        newIndex = fileBlock.previous;
        break;

    case NavigationDirectionChild:
        newIndex = fileBlock.child;
        break;

    case NavigationDirectionParent:
        newIndex = fileBlock.parent;
        if (newIndex == 0 && blockIndex != 0)
        {
            // Special case for root.
            blockIndex = newIndex;
            return true;
        }
        break;
    }

    if (newIndex != 0)
    {
        blockIndex = newIndex;
        return true;
    }

    return false;
}


bool FileGraph::NavigateBlocks(NavigationDirection navigationDirection, uint32_t count, _Inout_ uint32_t& blockIndex)
{
    for ( ; count > 0 && NavigateBlock(navigationDirection, IN OUT blockIndex); --count)
    { }

    return count == 0;
}


// Return the nearest block that covers the given range. If the range...
// - is within any block, it returns the block index and
//   isInsideBlock as true.
// - overlaps the block but is not wholly contained within, it returns
//   the first matching block but with isInsideBlock as false.
// - is in a gap between blocks, the index is rounded up to the next one.
// - is beyond the end of all blocks, it returns an index equal to the
//   total count of blocks.
//
// If returnExactMatchesOnly is set, then the function only returns zero when
// the range exactly matches (otherwise it will return 1 or -1). If false, then
// it returns 0 if the desired range is anywhere within but fully within the
// file block.
HRESULT FileGraph::FindBlockIndexFromRange(
    Range range,
    bool returnExactMatchesOnly,
    _Inout_ uint32_t& blockIndex,
    _Out_ int32_t& blockComparison // 0 if within/equal, 1 if beyond, -1 if below
    )
{
    blockComparison = 1;
    uint32_t matchingIndex = blockIndex;
    uint32_t matchingComparison = 1;

    if (matchingIndex >= fileBlocks_.size())
        return E_BOUNDS;

    // Determine which direction to search from the given block index.
    auto const& firstFileBlock = fileBlocks_[matchingIndex];
    bool isMovingForward = (range.begin >= firstFileBlock.range.begin);

    for (;;)
    {
        auto const& fileBlock = fileBlocks_[matchingIndex];
        if (returnExactMatchesOnly ? range.IsWithin(fileBlock.range) : range == fileBlock.range)
        {
            matchingComparison = 0;
            break;
        }
        else if (range.begin > fileBlock.range.begin)
        {
            matchingComparison = 1;
            if (!isMovingForward)
                break;
        }
        else if (range.begin <= fileBlock.range.begin)
        {
            matchingComparison = -1;
            if (isMovingForward)
                break;
        }
            
        auto nextIndex = isMovingForward ? fileBlock.next : fileBlock.previous;
        if (nextIndex == 0)
            break;

        matchingIndex = nextIndex;
    }

    blockIndex = matchingIndex;
    blockComparison = matchingComparison;
    return S_OK;
}


HRESULT FileGraph::RealignBlocks(uint32_t parentBlockIndex)
{
    // Resequence all the blocks based on their new sizes.

    if (parentBlockIndex >= fileBlocks_.size())
        return E_BOUNDS;

    auto& parentFileBlock = fileBlocks_[parentBlockIndex];
    uint32_t dataOffset = 0;
    uint32_t blockIndex = parentFileBlock.child;

    while (blockIndex != 0)
    {
        auto& fileBlock = fileBlocks_[blockIndex];
        // If alignment is greater than a byte, align the offset up to
        // to a multiple (any multiple, not just powers of two).
        uint32_t alignment = fileBlock.GetAlignment();
        if (alignment > 1)
        {
            uint32_t dataRemainder = dataOffset % alignment;
            if (dataRemainder > 0)
            {
                dataOffset += alignment - dataRemainder;
            }
        }

        // Move the data block to its new location.
        uint32_t subdataSize = static_cast<uint32_t>(fileBlock.data.size());
        fileBlock.range.begin = dataOffset;
        fileBlock.range.end = dataOffset + subdataSize;
        dataOffset += subdataSize;

        blockIndex = fileBlock.next;
    }

    parentFileBlock.range.SetCount(dataOffset);

    return S_OK;
}


// Take make things simpler, file block data never points to nullptr,
// instead pointing to an empty block.
FileBlockData::FileBlockData()
:   data_(&emptyBytes_)
{ }


// The constructor always makes a copy.
FileBlockData::FileBlockData(_In_reads_(byteSize) void* p, uint32_t byteSize)
:   data_(RefCountedBytes::Create(byteSize))
{
    memcpy(data_->data(), p, byteSize);
    dataRange_.end = byteSize;
}


FileBlockData::FileBlockData(FileBlockData const& other)
:   data_(other.data_),
    dataRange_(other.dataRange_)
{ }


FileBlockData::FileBlockData(FileBlockData const& other, Range range)
:   data_(other.data_),
    dataRange_(other.dataRange_)
{
    dataRange_.OffsetAndIntersect(range);
}


void FileBlockData::clear() throw()
{
    data_.clear();
    dataRange_.clear();
}


inline uint8_t* FileBlockData::data() throw()
{
    return data_->data() + dataRange_.begin;
}


inline uint8_t const* FileBlockData::data() const throw()
{
    return data_->data() + dataRange_.begin;
}


FileBlockData::operator uint8_t*() throw()
{
    return data();
}


FileBlockData::operator uint8_t const*() const throw()
{
    return data();
}


uint8_t& FileBlockData::operator[](size_t i) throw()
{
    return data()[i];
}


uint8_t const& FileBlockData::operator[](size_t i) const throw()
{
    return data()[i];
}


FileBlockData::iterator FileBlockData::begin() throw()
{
    return data_->data() + dataRange_.begin;
}


FileBlockData::iterator FileBlockData::end() throw()
{
    return data_->data() + dataRange_.end;
}


FileBlockData::size_type FileBlockData::size() const throw()
{
    // Return the size of the data, not the underlying bytes which is
    // ofter larger than the subrange.
    return dataRange_.size();
}


bool FileBlockData::empty() const throw()
{
    return dataRange_.empty();
}


Range& FileBlockData::GetRange() throw()
{
    return dataRange_;
}


// This FileBlockData class itself is not threadsafe, but
// the shared data block is.
void FileBlockData::resize(size_type newSize)
{
    // Shrinking is always safe and can just update the size directly.
    // Growing can be problematic if multiple views overlap data, but if
    // the new needed capacity is less than the already allocated bytes,
    // and this is the only FileBlockData that holds a reference to the
    // data, growing can safely update the size too. Otherwise allocate
    // a new block. Repeated resizes later will

    auto oldSize = dataRange_.size();
    if (newSize > oldSize)
    {
        auto newEnd = dataRange_.begin + newSize;
        if (newEnd > data_->capacity_ || newEnd < newSize || !data_->HasExclusiveAccess())
        {
            // Apply exponential growth pattern to minimize reallocations.
            auto minCapacity = std::min(data_->capacity_ / 2u, oldSize);
            auto newCapacity = std::max(minCapacity * 2u, newSize);
            RefCountPtr<RefCountedBytes> newBytes = RefCountedBytes::Create(newCapacity);
            memcpy(newBytes->data(), data(), oldSize);
            data_.swap(newBytes);
            dataRange_.begin = 0;
        }
    }
    dataRange_.end = dataRange_.begin + newSize;
}


void FileBlockData::ShrinkBy(uint32_t reducedByteSize)
{
    uint32_t totalByteCount = size() - reducedByteSize;
    if (totalByteCount < size())
        resize(totalByteCount);
}


void FileBlockData::GrowBy(uint32_t additionalByteSize)
{
    uint32_t totalByteCount = size() + additionalByteSize;
    if (totalByteCount < additionalByteSize)
        throw std::bad_alloc(); // Treat arithmetic overflow as a bad allocation.

    resize(totalByteCount);
}


void FileBlockData::InsertBytes(uint32_t byteOffset, const_byte_array_ref newData)
{
    if (byteOffset > dataRange_.size())
        throw std::out_of_range("offset is greater than FileBlockData size.");

    GrowBy(newData.size());
    ShiftDataUp<uint8_t>(*this, byteOffset, newData.size());
    memcpy(&data()[byteOffset], newData.data(), newData.size());
}


void FileBlockData::DeleteBytes(uint32_t byteOffset, uint32_t byteCount)
{
    // todo:
}


void FileBlockData::append(const_byte_array_ref newData)
{
    InsertBytes(dataRange_.size(), newData);
}


byte_array_ref FileBlockData::get_array_ref() throw()
{
    return byte_array_ref(begin(), end());
}


FileBlockData::operator byte_array_ref() throw()
{
    return byte_array_ref(begin(), end());
}


FileBlockData::operator const_byte_array_ref() throw()
{
    return const_byte_array_ref(begin(), end());
}


FileBlockData::RefCountedBytes* FileBlockData::RefCountedBytes::Create(uint32_t byteCount)
{
    uint32_t const totalByteCount = offsetof(RefCountedBytes, bytes_) + byteCount;
    if (totalByteCount < byteCount)
        throw std::bad_alloc(); // Treat arithmetic overflow as a bad allocation.

    void* p = operator new(totalByteCount);
    return new(p) RefCountedBytes(byteCount);
}


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

DEFINE_ENUM_FLAG_OPERATORS(IFileBlockData::Flags);

struct FileBlock
{
    // Byte data for this block. This data is a cached form of subdata,
    // which is called on demand when the subdata heirarchy is dirty.
    // The range size should equal blockSize, but it temporarily may not
    // if the file block's data has been modified and not recalculated yet.
    std::vector<uint8_t> data;

    // Further break-down of the file data. May be null if pure data.
    AutoPointer<IFileBlockData> subdata;

    // Byte range this block occupies, relative to the parent block
    // (not absolute file position, unless there is no higher parent).
    Range range;

    // A unique identifier for this block, at least unique to all its
    // siblings under the same parent.
    uint32_t blockId = 0;

    // Byte multiple to align the block's offset (range.begin).
    // Set to zero or one to align to packed bytes.
    uint32_t alignment = 0;
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

    void RealignBlocks()
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
