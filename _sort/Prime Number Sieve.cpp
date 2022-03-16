namespace
{

// Returns the greatest prime number less than n, using the Sieve of
// Eratosthenes. Modified from RichEdit code to use bits instead of
// bytes. The input is expected to be fairly small 0..~10'000, so the
// fact that isn't generalizable to huge numbers is fine.
//
uint32_t FindPrimeLessThan(__range(0, 33554431) uint32_t n)
{
    const static uint32_t MaxRepresentableIntegerInFloat = (1<<(FLT_MANT_DIG+1))-1;
    if (n >= MaxRepresentableIntegerInFloat)
    {
        throw ArgumentException("n must be within range");
    }
    else if (n <= 0)
    {
        return 0;
    }

    // Initialize the sieve to mark all multiples of two as composite.
    size_t const sieveBufferSize = n / CHAR_BIT + 2;
    std::vector<uint8_t> sieveBuffer(sieveBufferSize, 0x55);
    uint8_t* sieve = &sieveBuffer[0];

    // Reset the first byte to clear 1 and 2, since they are prime.
    sieve[0] = 0x50;

    uint32_t squareRoot = static_cast<uint32_t>(sqrt(float(n)));

    // Mark all non-prime numbers.
    for (uint32_t i = 3; i <= squareRoot; )
    {
        for (uint32_t j = i * 2; j < n; j += i)
        {
            SetBit(sieve, j); // mark as composite
        }

        // Advance to next prime factor
        // (this deterministically stops due to the nature of primes)
        i++;
        while (TestBit(sieve, i))
        {
            i++;
        }
    }

    // Find first prime walking backwards
    for (uint32_t i = n - 1; i > 0 ; i--)
    {
        if (!TestBit(sieve, i))
        {
            return i;
        }
    }
     
    return 0;
}


} // end anonymous namespace


