//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Clipboard helper.
//
//----------------------------------------------------------------------------
#pragma once

namespace DWritePad { namespace Implementation { 

    class Clipboard
    {
    private:
        Clipboard();

    public:
        static Clipboard* Open(bool emptyClipboard);

    public:
        ~Clipboard();

        void CopyText(std::wstring str);
        std::wstring GetText();
    };

} }