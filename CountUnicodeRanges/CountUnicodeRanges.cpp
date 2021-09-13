// Read a text file of the form...
//
//  0041	A	LATIN CAPITAL LETTER A
//  0042	B	LATIN CAPITAL LETTER B
//  0043	C	LATIN CAPITAL LETTER C
//  0044	D	LATIN CAPITAL LETTER D
//  ...
//
// ...and and collapse it into ranges.

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>

int main()
{
    // Open the File
    std::string fileName = "c:/temp/UnicodeLetters.txt";
    std::ifstream in(fileName, std::ifstream::in | std::ifstream::binary);
    std::vector<std::string> vecOfStrs;

    // Check if object is valid
    if (!in)
    {
        std::cerr << "Cannot open the File : " << fileName << std::endl;
        return false;
    }

    // Read the next line from File until it reaches the end.
    std::string str;
    while (std::getline(in, /*out*/ str))
    {
        if (!str.empty())
        {
            vecOfStrs.push_back(str);
        }
    }
    // Close The File
    in.close();

    const char* bom = "\xEF\xBB\xBF";
    // Stupid C++ std::string_view. I should be able to just say
    //      vecOfStrs.front().starts_with(bom)
    // And have it check for {EF, BB, BF}, not have it decay to some
    // random char pointer and run off the end into garbage data.
    if (!vecOfStrs.empty() && vecOfStrs.front().starts_with(bom))
    {
        vecOfStrs.front().erase(0, 3);
    }

    int previousCharacter = 0;
    int rangeCount = 0;
    int largestDelta = 0;
    int largestRangeSpan = 0;
    int rangeSpan = 0;

    for (std::string& s : vecOfStrs)
    {
        int currentCharacter = strtol(s.c_str(), nullptr, 16);
        largestDelta = std::max(largestDelta, currentCharacter - previousCharacter);

        if (currentCharacter != previousCharacter + 1)
        {
            ++rangeCount;
            rangeSpan = 1;
        }
        else
        {
            ++rangeSpan;
            largestRangeSpan = std::max(largestRangeSpan, rangeSpan);
        }
        previousCharacter = currentCharacter;
    }
    printf("rangeCount: %d, delta: %d, span: %d", rangeCount, largestDelta, largestRangeSpan);
}
