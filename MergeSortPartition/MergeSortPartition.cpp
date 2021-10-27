// MergeSortPartition.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <iostream>

int GetMergeSortPartitionBase(
    float* a,
    int aCount,
    float* b,
    int bCount,
    int diag
    )
{
    using T = float;
    int begin = std::max(0, diag - bCount);
    int end = std::min(diag, aCount);
    printf("diag=%d\r\n", diag);
 
    while(begin < end) {
        int mid = (begin + end)>> 1;
        T aKey = a[mid];
        T bKey = b[diag - 1 - mid];
        printf("    begin=%d, end=%d, akey=%f, bkey=%f\r\n", begin, end, aKey, bKey);

        bool pred = aKey < bKey;
        //bool pred = (MgpuBoundsUpper == Bounds) ? 
        //    aKey < bKey;
        //    comp(aKey, bKey) : 
        //    !comp(bKey, aKey);
        if (pred)
            begin = mid + 1;
        else
            end = mid;
    }
    printf("    begin a=%d\r\n", begin);
    printf("    begin b=%d\r\n", diag - begin);
    return begin;
}

void MergeSort(
    float* a,
    int aStart,
    int aLimit,
    float* b,
    int bStart,
    int bLimit,
    float* output,
    int outputStart,
    int outputCount
    )
{
    int aOffset = 0, bOffset = 0;
    for (int i = 0; i < outputCount; ++i)
    {
        float aValue = (aStart + aOffset < aLimit) ? a[aStart + aOffset] : FLT_MAX;
        float bValue = (bStart + bOffset < bLimit) ? b[bStart + bOffset] : FLT_MAX;
        bool useA = (aValue < bValue);
        float value = useA ? aValue : bValue;
        if (useA) ++aOffset; else ++bOffset;
        output[outputStart + i] = value;
    }
}

int main()
{
    float a[] = { 1,3,3,5,6,9,10,11 };
    float b[] = { 0,2,5,7,8,13,14,14 };
    //float a[] = { 0,0,0,0,0,0,0,0 };
    //float b[] = { 1,1,1,1,1,1,1,1 };
    //float a[] = { 1,1,1,1,1,1,1,1 };
    //float b[] = { 0,0,0,0,0,0,0,0 };
    float output[_countof(a) + _countof(b)] = {};
    memset(output, 0xFF, sizeof(output));

    int outputStep = 4;
    for (int diag = 0; diag < (_countof(output)); diag += outputStep)
    {
        int aBaseOffset = GetMergeSortPartitionBase(a, int(std::size(a)), b, int(std::size(b)), diag);
        int bBaseOffset = diag - aBaseOffset;

        int outputCount = std::min(outputStep, int(std::size(output)) - diag);

        MergeSort(
            a,
            aBaseOffset,
            int(std::size(a)),
            b,
            bBaseOffset,
            int(std::size(b)),
            output,
            diag,
            outputCount
        );
    }

    puts("output = [");
    for (auto i = 0u; i < _countof(output); ++i)
    {
        printf("%g,", output[i]);
    }
    puts("]");
}
