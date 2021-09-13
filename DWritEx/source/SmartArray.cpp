//---------------------------------------------------------------------------
//
//  No copyright. No rights reserved. No royalties nor permission needed.
//
//  This library is not produced by, endorsed by, or supported by Microsoft.
//  It is merely a supplementary library, dependent on the real DirectWrite,
//  written to augment and fill in functionality holes.
//
//  Feel free to use it for any projects, commercial or not, as a whole or in
//  parts. No warranty or guarantees of correctness! You have the code. Come
//  to your own conclusion regarding the robustness.
//
//----------------------------------------------------------------------------

#include "DWritExInternal.h"
#include "SmartArray.h"


void fooo(char* pc)
{
    static char x;
    x = pc[0];
}

void AutoVectorUnitTests()
{
    AutoVector<char, 10, false> av1;
    AutoVector<char, 10, true> av2;
    AutoVector<char, 0, false> av5;
    AutoVector<char, 10, true> av7(0);
    AutoVector<char, 10, true> av8(30);
    AutoVector<char, 0, true> av3;
    AutoVector<char, 0, false> av4;
    AutoVector<char, 0, false> av6(30);
    AutoVector<uint32_t, 16, false> av20;
    AutoVector<uint32_t, 0, false> av21;
    AutoVector<uint32_t, 0, true> av22;

    try
    {
        AutoVector<uint32_t, 0, true> av23(4000000000); // allocate larger than possible
    }
    catch (std::bad_alloc)
    {
        ; // there should have been an exception.
    }

    av7.reserve(5);
    av7.reserve(10);
    av7.reserve(11);
    av7.reserve(30);
    av7.size();
    av7.resize(0);
    av7.shrink_to_fit();
    av7.resize(20);
    av7.shrink_to_fit();
    av7.clear();
    av7.shrink_to_fit();

    av5.push_back(5);
    av5.pop_back();
    av5.push_back(1);
    av5.push_back(2);
    av5.resize(100);
    fooo(av5);
    av5.Clear();
    free(av5.Detach());

    av7.Clear();
    free(av7.Detach());
    free(av7.Detach()); // detach twice in a row
    av7.Clear();
    av7.resize(5);
    free(av7.Detach()); // detach while still using fixed size buffer
    av7.resize(30);
    free(av7.Detach()); // detach while using allocated buffer
    free(av7.Detach()); // attempt detach again
    av7.resize(30);     // resize after null from being detached

    {
        size_t size = 0;

        // Transfer empty array to another
        av5.Clear();
        size = av5.GetSize();
        av7.Attach(av5.Detach(), size);

        // Transfer from heap to fixed size
        av5.Resize(30);
        size = av5.GetSize();
        av7.Attach(av5.Detach(), size);

        // Transfer back to heap
        size = av7.GetSize();
        av5.Attach(av7.Detach(), size);

        // Transfer from fixed size to heap
        av7.Clear();
        av7.Resize(5);
        size = av7.GetSize();
        av5.Attach(av7.Detach(), size);
    }

    av7.ReserveCapacity(10);
    av7.Resize(5);
    av7.ShrinkCapacityToSize();
    av7.empty();
    av7.Insert(3);
    av7.Erase(3);
    av7.GetSizeInBytes();

    av22.resize(100);
    av22.push_back(5);
    av22.Insert(75);
    av22.front() = 13;
    av22.back()  = 42;

    std::sort(av22.begin(), av22.end());
    std::fill(av22.begin(), av22.end(), 0);
}
