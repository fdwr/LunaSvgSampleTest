#pragma once


struct uint24_t
{
    // Explicit getter returning native type. Converts from file representation,
    // which is little-endian.
    uint32_t Get() const throw()
    {
        return 
            (static_cast<uint32_t>(value[2]) << 16) | 
            (static_cast<uint32_t>(value[1]) << 8) | 
            value[0];
    }

    // Implicit conversion to native type.
    operator uint32_t() const throw()
    {
        return Get();
    }

    void Set(uint32_t v) throw()
    {
        value[0] = uint8_t(v);
        value[1] = uint8_t(v >> 8);
        value[2] = uint8_t(v >> 16);
    }

    uint24_t& operator =(uint32_t v) throw()
    {
        Set(v);
        return *this;
    }

    uint8_t value[3];
};

struct int24_t
{
    // Explicit getter returning native type. Converts from file representation,
    // which is little-endian.
    int32_t Get() const throw()
    {
        return value.Get();
    }

    // Implicit conversion to native type.
    operator int32_t() const throw()
    {
        // Get the 32-bit value from 24-bits, then extend sign.
        uint32_t integerValue = value.Get();
        return int32_t(integerValue << 8) >> 8;
    }

    void Set(int32_t v) throw()
    {
        value.Set(v);
    }

    int24_t& operator =(int32_t v) throw()
    {
        value.Set(v);
        return *this;
    }

    uint24_t value;
};
