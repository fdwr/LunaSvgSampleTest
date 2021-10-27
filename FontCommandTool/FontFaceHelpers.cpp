//+---------------------------------------------------------------------------
//
//  File:       FontFaceHelpers.cpp
//
//  Author:     Dwayne Robinson (dwayner@microsoft.com)
//
//  History:    2013-10-24  dwayner     Adapted to FontCommandTool
//
//----------------------------------------------------------------------------
#include "precomp.h"


FontTablePtr::FontTablePtr(
    IDWriteFontFace* fontFace,
    uint32_t openTypeTableTag
    )
{
    if (fontFace == nullptr)
        return;

    const void* tableData;
    uint32_t tableSize;
    BOOL exists = false;

    fontFace->TryGetFontTable(
        openTypeTableTag,
        &tableData,
        OUT &tableSize,
        OUT &tableContext_,
        OUT &exists
        );

    if (exists)
    {
        *static_cast<Base*>(this) = Base(const_cast<void*>(tableData), tableSize);
        fontFace_ = fontFace;
    }
}


FontTablePtr::~FontTablePtr()
{
    if (fontFace_ != nullptr)
    {
        fontFace_->ReleaseFontTable(tableContext_);
    }
}
