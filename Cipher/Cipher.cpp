// Cipher.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include "precomp.h"

const char* g_helpText =
    "About:\r\n"
    "    Dwayne Robinson, 2019-01-29\r\n"
    "    Supports simple Ceasar and Vigenère ciphers.\r\n"
    "\r\n"
    "Usage:\r\n"
    "    Cipher.exe input key method\r\n"
    "\r\n"
    "Example:\r\n"
    "    (ROT13) Cipher.exe add \"Hello World\" D shift\r\n"
    "            Cipher.exe addinc \"Hello World\" 20190119\r\n"
    "            Cipher.exe subinc \"Hello World\" 20190119\r\n"
    "\r\n"
    ;

enum class CipherMethod
{
    Add,    // add (use 'D' for ROT13) each input character with each key character (repeated if shorter)
    Sub,    // subtract each input with each key (repeated if shorter)
    AddInc, // add with increment each element
    SubInc, // subtract with increment each element
};

constexpr std::string_view g_knownMethods[] =
{
    "add", // Ceasar cipher (if key length 1) or Vigenère cipher
    "sub",
    "addinc",
    "subinc",
};

uint32_t StringToIndex(
    std::string_view s,
    std::string_view const* knownStrings,
    size_t knownStringsSize,
    uint32_t defaultIndex = UINT32_MAX
)
{
    for (size_t i = 0; i < knownStringsSize; ++i)
    {
        if (knownStrings[i] == s)
        {
            return i;
        }
    }
    return defaultIndex;
}

uint32_t HexCharToValue(char32_t ch)
{
    if (ch <  '0') return 0;
    if (ch <= '9') return ch - '0';

    ch |= 'a' - 'A';
    if (ch < 'a') return 0;
    if (ch > 'z') return 0;
    return ch - 'a' + 10;
}

char32_t AddDeltaToCharWithWrap(char32_t ch, char32_t base, int32_t wrap, int32_t delta)
{
    ch -= base;
    int32_t modulus = int32_t(ch + delta) % wrap;
    modulus = (modulus >= 0) ? modulus : (modulus + wrap);
    return base + modulus;
}

char32_t AddDeltaToCharWithWrap(char32_t ch, int32_t delta)
{
    if (ch >= '0' && ch <= '9')
    {
        return AddDeltaToCharWithWrap(ch, '0', 10, delta);
    }
    else if (ch >= 'A' && ch <= 'Z')
    {
        return AddDeltaToCharWithWrap(ch, 'A', 26, delta);
    }
    else if (ch >= 'a' && ch <= 'z')
    {
        return AddDeltaToCharWithWrap(ch, 'a', 26, delta);
    }
    return ch;
}

std::string GetCipherOutput(
    CipherMethod cipherMethod,
    std::string_view input,
    std::string_view key
)
{
    std::string output;

    const size_t keyLength = key.length();
    size_t keyIndex = 0;
    if (keyLength == 0)
    {
        throw std::invalid_argument("Invalid key length.");
    }

    switch (cipherMethod)
    {
    case CipherMethod::Add:
    case CipherMethod::Sub:
    case CipherMethod::AddInc:
    case CipherMethod::SubInc:
        {
            int32_t cumulativeDelta = 0;
            for (char32_t ch : input)
            {
                char32_t m = key[keyIndex];
                int32_t delta = HexCharToValue(m);
                switch (cipherMethod)
                {
                case CipherMethod::Add: break;
                case CipherMethod::Sub: delta = -delta;  break;
                case CipherMethod::AddInc: cumulativeDelta += delta; delta = cumulativeDelta; break;
                case CipherMethod::SubInc: cumulativeDelta += delta; delta = -cumulativeDelta; break;
                }
                ch = AddDeltaToCharWithWrap(ch, delta);

                if (++keyIndex >= keyLength)
                {
                    keyIndex = 0;
                }
                output.push_back(static_cast<uint8_t>(ch));
            }
        }
        break;

    default:
        throw std::invalid_argument("Invalid method.");
        break;
    }

    return output;
}

int main(int argc, char const* argv[])
{
    try
    {
        if (argc < 4)
        {
            printf(g_helpText);
            return EXIT_FAILURE;
        }

        char const* method = argv[1];
        char const* input = argv[2];
        char const* key = argv[3];
        printf(
            "Input:    %s\r\n"
            "Key:      %s\r\n"
            "Method:   %s\r\n",
            input,
            key,
            method
        );

        const CipherMethod cipherMethod = static_cast<CipherMethod>(StringToIndex(
            method,
            g_knownMethods,
            std::size(g_knownMethods)
        ));
        if (static_cast<uint32_t>(cipherMethod) >= std::size(g_knownMethods))
        {
            printf("Unknown cipher method: %s\r\n", method);
            return EXIT_FAILURE;
        }

        std::string output = GetCipherOutput(cipherMethod, input, key);
        printf("Output:   %s\r\n", output.c_str());

        #ifndef NDEBUG
        // To verify the reverse direction yields the same as the input.
        const CipherMethod reverseCipherMethod = static_cast<CipherMethod>(uint32_t(cipherMethod) ^ 1);
        std::string originalInput = GetCipherOutput(reverseCipherMethod, output, key);
        printf("Reverse:  %s\r\n", originalInput.c_str());
        #endif
    }
    catch (std::exception const& e)
    {
        printf("Error: %s\r\n", e.what());
        return EXIT_FAILURE;
    }
    catch (...)
    {
        printf("Error\r\n");
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
