#define _CRT_SECURE_NO_WARNINGS // Shut up about fopen.

// Something is wrong with UnescapeString, as it produces the wrong output for https://github.com/ppcasm/HYCU/blob/master/HYCU_HS/image.h

#include <iostream>
#include <vector>
#include <span>
#include <cstddef>
#include <cassert>

void UnescapeString(
    std::span<std::byte> textData,
    /*out*/ std::vector<std::byte>& fileData
    )
{
    for (size_t i = 0; i < textData.size(); )
    {
        unsigned char ch = static_cast<unsigned char>(textData[i++]);

        switch (ch)
        {
        case '\\':
            ch = static_cast<unsigned char>(textData[i++]);
            switch (ch)
            {
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                {
                    uint32_t octalDigitCap = 2;
                    uint32_t octalValue = ch - '0';
                    while (i < textData.size() && octalDigitCap > 0)
                    {
                        ch = static_cast<unsigned char>(textData[i]);
                        if (ch < '0' || ch > '9')
                            break;
                        ++i;
                        octalValue = octalValue * 8 + ch - '0';
                        --octalDigitCap;
                    }
                    ch = static_cast<unsigned char>(octalValue);
                }
                break;

            case '\'': break; // single quote	byte 0x27 in ASCII encoding
            case '\"': break; // double quote	byte 0x22 in ASCII encoding
            case '?' : break; // question mark	byte 0x3f in ASCII encoding
            case '\\': break; // backslash	byte 0x5c in ASCII encoding
            case 'a' : ch = '\a'; break; // audible bell	byte 0x07 in ASCII encoding
            case 'b' : ch = '\b'; break; // backspace	byte 0x08 in ASCII encoding
            case 'f' : ch = '\f'; break; // form feed - new page	byte 0x0c in ASCII encoding
            case 'n' : ch = '\n'; break; // line feed - new line	byte 0x0a in ASCII encoding
            case 'r' : ch = '\r'; break; // carriage return	byte 0x0d in ASCII encoding
            case 't' : ch = '\t'; break; // horizontal tab	byte 0x09 in ASCII encoding
            case 'v' : ch = '\v'; break; // vertical tab	byte 0x0b in ASCII encoding

            case 'x': // Not supported.
            case 'U': // Not supported.
            default: // Any other character after escape code.
                assert(false);
                // Preserve invalid codes
            }
            break;

        default: // Pass any other character through.
            break;
        }

        fileData.push_back(std::byte(ch));
    }
}

int main()
{
    // TODO: Read argv and argc.
    const char* inputFileName = "o:/temp/ppcasm HYCU_HS@github image_bare.h";
    const char* outputFileName = "o:/temp/ppcasm HYCU_HS@github image_bare.bin";
    FILE* inputFile = std::fopen(inputFileName, "rb");
    FILE* outputFile = std::fopen(outputFileName, "wb");

    size_t fileSize = 0;
    std::fseek(inputFile, 0L, SEEK_END);
    fileSize = std::ftell(inputFile);
    std::fseek(inputFile, 0L, SEEK_SET);
    std::vector<std::byte> textData(fileSize);
    std::vector<std::byte> fileData;

    std::fread(textData.data(), 1, textData.size(), inputFile);
    UnescapeString(textData, /*out*/ fileData);
    std::fwrite(fileData.data(), 1, fileData.size(), outputFile);

    std::fclose(inputFile);
    std::fclose(outputFile);
}
