// *** Use JPEGDump instead of this quick hack ***
// This tool attempts to extract any JPEGs or PNG's
// from larger archives or executables by looking for
// JFIF and PNG streams contained within.

#define _CRT_SECURE_NO_WARNINGS // Oh shove it. fopen_s is no safer than fopen.
#include "std.h"
#include "basictypes.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <tchar.h>
#include <stdint.h>

// So tired of typing the stupid "_t" every time.
using uint8  = uint8_t;
using uint16 = uint16_t;
using uint32 = uint32_t;

////////////////////////////////////////////////////////////////
FILE* NextOutputFile(const char* filenamePattern);
int LoadFileAndScanForSignatures(FILE* inputFile);
int ScanForSignatures(const uint8* inputBuffer, int inputBufferSize);
int ExtractJPEG(const uint8* inputBuffer, int inputBufferSize);
int ExtractPNG(const uint8* inputBuffer, int inputBufferSize);
extern "C" void FatalError(TCHAR* msg, ...);
bool MemoryEqual(_In_reads_bytes_(bufferSize) void const* buffer1, _In_reads_bytes_(bufferSize) void const* buffer2, _In_ size_t bufferSize);

////////////////////////////////////////////////////////////////
int g_nextFileNumber = 0;

////////////////////////////////////////////////////////////////
int main(int argc, char* argv[])
{
    if (argc < 2)
        FatalError(T("No source filename supplied\n"));

    FILE* infp = fopen(argv[1], "rb");
    if (infp == null)
        FatalError(T("Could not open source filename \"%s\"\n"), argv[1]);

    LoadFileAndScanForSignatures(infp);

    fclose(infp);
    return 0;
}


bool MemoryEqual(
    _In_reads_bytes_(bufferSize) void const* buffer1,
    _In_reads_bytes_(bufferSize) void const* buffer2,
    _In_ size_t bufferSize
    )
{
    // Why isn't there just a memequal function that plainly returns a bool?
    // How many times have you ever wanted to know whether a block of memory is
    // less or greater than another ... 1%? How many times have you wanted to
    // know equality ... 99%?
    return memcmp(buffer1, buffer2, bufferSize) == 0;
}

int LoadFileAndScanForSignatures(FILE* infp)
{
    uint8* inbuf;

    fseek(infp, 0, SEEK_END);
    int insize = ftell(infp);
    rewind(infp);

    // allocate memory to contain the whole file.
    // and copy the file into the buffer.
    inbuf = (uint8*)malloc(insize + 1);
    if (inbuf == null)
    {
        FatalError("Could not allocate enough memory for file buffer. File could be too large?");
    }
    fread(inbuf, 1, insize, infp);
    inbuf[insize] = '\0';

    int filesExtracted = ScanForSignatures(inbuf, insize);

    free(inbuf);

    return filesExtracted;
}


int ScanForSignatures(const uint8* inputBuffer, int inputBufferSize)
{
    int filesExtracted = 0;

    int inputBufferOffset = 0;
    int headerByteCount = 0;


    const uint8 jpegSignature0[4] = {0xFF,0xD8,0xFF,0xE0};
    const uint8 jpegSignature1[4] = {0xFF,0xD8,0xFF,0xE1};
    const uint8 jpegSignature2[4] = {0xFF,0xD8,0xFF,0xE2};
    const uint8 jpegSignature3[4] = {0xFF,0xD8,0xFF,0xE8};
    const uint8 pngSignature[8] = {0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A};
    // 89       Has the high bit set to detect transmission systems that do not support 8-bit data and to reduce the chance that a text file is mistakenly interpreted as a PNG, or vice versa.
    // 50 4E 47 In ASCII, the letters PNG, allowing a person to identify the format easily if it is viewed in a text editor.
    // 0D 0A    A DOS-style line ending (CRLF) to detect DOS-Unix line ending conversion of the data.
    // 1A       A byte that stops display of the file under DOS when the command type has been used—the end-of-file character.
    // 0A       A Unix-style line ending (LF) to detect Unix-DOS line ending conversion.

    // Search for JPEG or PNG headers.
    while (inputBufferOffset < inputBufferSize)
    {
        const uint8* remainingBuffer = &inputBuffer[inputBufferOffset];
        uint32 remainingBufferSize = inputBufferSize - inputBufferOffset;

        switch (*remainingBuffer)
        {
        case 0xFF:
            if (remainingBufferSize >= sizeof(jpegSignature0))
            {
                if (MemoryEqual(remainingBuffer, jpegSignature0, sizeof(jpegSignature0))
                ||  MemoryEqual(remainingBuffer, jpegSignature1, sizeof(jpegSignature1))
                ||  MemoryEqual(remainingBuffer, jpegSignature2, sizeof(jpegSignature2))
                ||  MemoryEqual(remainingBuffer, jpegSignature3, sizeof(jpegSignature3)))
                {
                    inputBufferOffset += ExtractJPEG(remainingBuffer, remainingBufferSize);
                    ++filesExtracted;
                }
                else
                {
                    ++inputBufferOffset;
                }
            }
            break;

        case 0x89:
            if (remainingBufferSize >= sizeof(pngSignature))
            {
                if (MemoryEqual(remainingBuffer, pngSignature, sizeof(pngSignature)))
                {
                    inputBufferOffset += ExtractPNG(remainingBuffer, remainingBufferSize);
                    ++filesExtracted;
                }
                else
                {
                    ++inputBufferOffset;
                }
            }
            break;

        default:
            ++inputBufferOffset;
            break;
        }
    }

    return filesExtracted;
}


// Read backwards endian (e.g. Motorola) order.
uint32 ReadUint16BE(const uint8* input)
{
    return (input[1] << 0)
         | (input[0] << 8);
}


uint32 ReadUint32BE(const uint8* input)
{
    return (input[3] <<  0)
         | (input[2] <<  8)
         | (input[1] << 16)
         | (input[0] << 24);
}


// Returns the first byte offset in the buffer after the JPEG.
int ExtractJPEG(const uint8* inputBuffer, int inputBufferSize)
{
    if (inputBufferSize < 2)
    {
        return 0; // Cannot be valid since chunk id's are 2 bytes.
    }

    FILE* outputFile = NextOutputFile("out%04d.jpg");
    if (outputFile == nullptr)
    {
        FatalError("Could not open next file for output.");
    }

    const uint32 idTagSize = 2;

    int inputBufferOffset = 0;
    fwrite(&inputBuffer[inputBufferOffset], idTagSize, 1, outputFile);
    inputBufferOffset += idTagSize;

    while (inputBufferOffset < inputBufferSize)
    {
        uint32 remainingBufferSize = inputBufferSize - inputBufferOffset;

        // Check for terminal chunk.
        if (remainingBufferSize < idTagSize)
            break;

        if (ReadUint16BE(inputBuffer + inputBufferOffset) == 0xFFD9)
            break;

        // Read 2-byte chunk length after 2-byte chunk id.
        if (remainingBufferSize < idTagSize + 2)
            break;

        uint32 length = ReadUint16BE(inputBuffer + inputBufferOffset + idTagSize);
        if (length == 0)
            break;

        if (idTagSize + length > remainingBufferSize)
            break;

        // Write out chunk.
        uint32 totalChunkLength = 2 + length;
        fwrite(&inputBuffer[inputBufferOffset], totalChunkLength, 1, outputFile);
        inputBufferOffset += totalChunkLength;
    }
    uint8 eos[2] = { 0xFF, 0xD9 };
    fwrite(eos, sizeof(eos), 1, outputFile);
    fclose(outputFile);

    return inputBufferOffset;
}


// Returns the first byte offset in the buffer after the JPEG.
int ExtractPNG(const uint8* inputBuffer, int inputBufferSize)
{
    const uint32 fileHeaderSize = 8;
    const uint32 chunkNondataSize = 12;

    if (inputBufferSize < fileHeaderSize + chunkNondataSize)
    {
        return 0; // Cannot be valid because smaller than header signature and minimum chunk.
    }

    FILE* outputFile = NextOutputFile("out%04d.png");
    if (outputFile == nullptr)
    {
        FatalError("Could not open next file for output.");
    }

    int inputBufferOffset = 0;
    fwrite(&inputBuffer[inputBufferOffset], fileHeaderSize, 1, outputFile);
    inputBufferOffset += fileHeaderSize;

    while (inputBufferOffset < inputBufferSize)
    {
        uint32 remainingBufferSize = inputBufferSize - inputBufferOffset;

        if (remainingBufferSize < chunkNondataSize) // Size of a single empty chunk.
            break;

        uint32 length = ReadUint32BE(inputBuffer + inputBufferOffset);
        uint32 totalChunkLength = chunkNondataSize + length;
        if (totalChunkLength > remainingBufferSize)
            break;

        // Check for terminal chunk.
        if (ReadUint32BE(inputBuffer + inputBufferOffset + 4) == 'IEND')
            break;

        // Write out chunk.
        fwrite(&inputBuffer[inputBufferOffset], totalChunkLength, 1, outputFile);
        inputBufferOffset += totalChunkLength;
    }
    uint8 eos[] = { 0x00,0x00,0x00,0x00,0x49,0x45,0x4E,0x44,0xAE,0x42,0x60,0x82 };
    fwrite(eos, sizeof(eos), 1, outputFile);
    fclose(outputFile);

    return inputBufferOffset;
}


FILE* NextOutputFile(const char* filenamePattern)
{
    TCHAR fileName[1024];
    sprintf_s(fileName, filenamePattern, g_nextFileNumber);
    FILE* fp = fopen(fileName, "wb");

    if (fp != nullptr)
    {
        ++g_nextFileNumber;
    }

    return fp;
}


////////////////////////////////////////////////////////////////////////////////

/** Global text message logger.

\param[in]	msg		Text message.
\param[in]	...		Variable number of parameters (anything printf can handle)
*/
extern "C" [[noreturn]] void FatalError(TCHAR* msg, ...)
{
    TCHAR text[1024];
    va_list args;
    va_start(args, msg);
    _vsntprintf_s(text, elmsof(text), msg, args);
    text[1023] = '\0';

    // delete old lines if too long
#ifdef _DEBUG
//OutputDebugString(text);
#endif
    puts("ExtractJfif 1.0 - Dwayne Robinson\r\nExports JPEG files from another file.\r\n");
    puts(text);

    exit(-1);
}
