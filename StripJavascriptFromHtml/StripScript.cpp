// Strips <SCRIPT>...</SCRIPT> from HTML, useful for killing
// irritating Javascript in saved webpages.
// 2006-03-04 Dwayne Robinson
// 2021-12-15 Update for C++20

#include <ctype.h>
#include <stdarg.h>
#include <memory>
#include <span>
#include <string>
#include <assert.h>
#include <io.h>
#include "Precomp.h"

////////////////////////////////////////////////////////////////
void StripTagsFromFile(const char* inputFilename, const char* outputFilename);
size_t StripTags(std::span<const char8_t> input, std::span<char8_t> output, const char8_t* tagList);
int32_t GetMatchingStringIndexIcase(const char8_t* string, const char8_t* matches, /*out*/ const char8_t** match);
[[noreturn]] void FatalError(const char8_t* msg, ...);

#define elmsof(element) (sizeof(element) / sizeof(element[0]))

////////////////////////////////////////////////////////////////

int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        FatalError(u8"No source filename supplied");
    }
    if (argc > 3)
    {
        FatalError(u8"Too many parameters");
    }

    // Open output file.
    #ifndef _WIN32
        #error "Unknown operating system - update output statement below accordingly for Linux/Mac. Maybe /dev/tty ?"
    #endif

    const char* inputFilename = argv[1];
    const char* outputFilename = (argc > 2) ? argv[2] : "con:"; // /dev/tty on Linux?

    StripTagsFromFile(inputFilename, outputFilename);

    return 0;
}


void StripTagsFromFile(const char* inputFilename, const char* outputFilename)
{
    FILE* inputFile = nullptr;
    fopen_s(&inputFile, inputFilename, "rb");
    if (inputFile == nullptr)
    {
        FatalError(u8"Could not open source filename: %s", inputFilename);
    }

    // Get file size and read file into memory.
    fseek(inputFile, 0, SEEK_END);
    size_t inputSize = ftell(inputFile);
    rewind(inputFile);

    char8_t* textBuffer = (char8_t*)malloc(inputSize + 1);
    std::unique_ptr<char8_t> inputBufferWrapper((char8_t*)textBuffer);
    if (textBuffer == nullptr)
    {
        FatalError(u8"Could not allocate enough memory for file buffer. File could be too large?");
    }
    fread(/*out*/ textBuffer, 1, inputSize, inputFile);
    textBuffer[inputSize] = '\0';
    fclose(inputFile);

    // Strip all the tags.
    size_t outputSize = StripTags({ textBuffer, inputSize }, { textBuffer, inputSize }, u8"script\0");

    // Write the output.
    FILE* outputFile = nullptr;
    fopen_s(&outputFile, outputFilename, "wb");
    if (outputFile == nullptr)
    {
        FatalError(u8"Could not open target filename: %s", outputFilename);
    }
    fwrite(textBuffer, outputSize, 1, outputFile);
    fclose(outputFile);
}


// Strips a text buffer of undesired HTML tags.
// The output buffer must be as large as the input buffer.
// The output can alias the input, since the write occurs in place.
// The tagList is a null separated list, with a final nul terminating the whole list.
// e.g. "script\0embed\0" // the final nul \0 is implicit, making it a double null terminator.
size_t StripTags(std::span<const char8_t> input, std::span<char8_t> output, const char8_t* tagList)
{
    assert(output.size() >= input.size());

    size_t outputSize = 0;
    const char8_t* inputPos = input.data();
    const char8_t* inputEnd = input.data() + input.size();

    while (inputPos < inputEnd)
    {
        char8_t ch = *inputPos++;
        // Look for opening tag: [<]tag>
        if (ch == '<')
        {
            // Match tag name: <[tag]>
            const char8_t* match;
            int32_t matchingElementIndex = GetMatchingStringIndexIcase(inputPos, tagList, /*out*/ &match);
            if (matchingElementIndex >= 0)
            {
                size_t matchLength = strlen((const char*)match);
                if (inputPos + matchLength < inputEnd)
                {
                    ch = inputPos[matchLength];
                    // Accept a single tag or tag with attributes. <tag> or <tag ...>
                    if (ch == '>' || ch == ' ')
                    {
                        // Find end of opening tag. <tag[>]
                        inputPos += matchLength;
                        while (inputPos < inputEnd && *inputPos++ != '>')
                        {}

                        // Look for corresponding closing tag. </tag>
                        const char8_t* closingTagPos = inputPos;
                        while (closingTagPos < inputEnd)
                        {
                            if (
                                *closingTagPos++ == '<' &&
                                closingTagPos < inputEnd &&
                                *closingTagPos++ == '/' &&
                                _strnicmp((const char*)closingTagPos, (const char*)match, matchLength) == 0 &&
                                closingTagPos + matchLength < inputEnd &&
                                *(closingTagPos += matchLength) == '>'
                                )
                            {
                                // Found closing tag. Remove all content between it too.
                                inputPos = closingTagPos + 1;
                                goto NoCharacterCopy;
                            }
                        }
                    }
                }
            }
        }

        // No match. Just copy characters straight over.
        output[outputSize++] = ch;
    NoCharacterCopy:;
    }

    return outputSize;
}

/** Matches a string prefix against a list and returns the match index.
    Unlike strmatch, this matches only the prefix, meaning 'dogwood' and
    'doghouse' would both match with 'dog'. So the order of the items in
    the matches string is important. Always put the longer words first
    (otherwise they may match a shorter word first).

\param[in]  string  ASCIIZ string to match
\param[in]  matches list of several null separated strings, with
                    the final string being double null terminated.

\return     zero based match index or -1 if no match found
*/
int32_t GetMatchingStringIndexIcase(const char8_t* string, const char8_t* matches, /**/ const char8_t** match)
{
    int32_t matchIndex = 0;
    *match = u8"";

    while (true)
    {
        size_t matchLength = strlen((const char*)matches);
        if (matchLength == 0)
        {
            return -1; // Exhausted all possible match strings.
        }
        if (_strnicmp((const char*)string, (const char*)matches, matchLength) == 0)
        {
            *match = matches;
            return matchIndex;
        }
        matchIndex++;
        matches += matchLength + 1;
    }
}

////////////////////////////////////////////////////////////////////////////////

/** Global text message logger.

\param[in]  msg     Text message.
\param[in]  ...     Variable number of parameters (anything printf can handle)
*/
[[noreturn]] void FatalError(const char8_t* msg, ...)
{
    char8_t text[1024];
    va_list args;
    va_start(args, msg);
    vsprintf_s((char* const)text, elmsof(text), (const char* const)msg, args);
    text[1023] = '\0';

    // delete old lines if too long
    #ifdef _DEBUG
    //OutputDebugString(text);
    #endif
    fputs("StripScript 1.0 - Dwayne Robinson\r\nStrips javascript from HTML.\r\n", stdout);
    fputs((const char*)text, stderr);

    exit(-1);
}
