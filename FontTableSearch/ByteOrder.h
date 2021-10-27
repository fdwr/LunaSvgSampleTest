//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2007. All rights reserved.
//
//  File:       ByteOrder.h
//
//  Contents:   Classes that deal with integers serialized in big and little endian forms.
//
//  Author:     Mikhail Leonov (mleonov@microsoft.com)
//
//  History:    11-01-2007   mleonov    Moved byte order wrappers from Font code here.
//
//----------------------------------------------------------------------------
#pragma once

// Make sure the compiler does not add any padding to the structures defined below, as
// they must agree exactly with binary representation in font files.
#pragma pack(push, 1)

// Represents a 16-bit unsigned integer for file formats that use Little Endian conventions.
struct LittleEndianUShort
{
    // Explicit getter returning native type. Converts from file representation,
    // which is little-endian.
    uint16_t Get() const throw()
    {
        return 
            (static_cast<uint16_t>(value_[1]) << 8) | 
            value_[0];
    }

    // Implicit conversion to native type.
    operator uint16_t() const throw()
    {
        return Get();
    }

    uint8_t value_[2];
};

// Represents a 32-bit unsigned integer for file formats that use Little Endian conventions.
struct LittleEndianULong
{
    // Explicit getter returning native type. Converts from file representation,
    // which is little-endian.
    uint32_t Get() const throw()
    {
        return 
            (static_cast<uint32_t>(value_[3]) << 24) | 
            (static_cast<uint32_t>(value_[2]) << 16) | 
            (static_cast<uint32_t>(value_[1]) << 8) | 
            value_[0];
    }

    // Implicit conversion to native type.
    operator uint32_t() const throw()
    {
        return Get();
    }

    uint8_t value_[4];
};

// Represents a 16-bit unsigned integer for file formats that use Big Endian conventions.
struct BigEndianUShort
{
    // Explicit getter returning native type. Converts from file representation,
    // which is big-endian.
    uint16_t Get() const throw()
    {
        return 
            (static_cast<uint16_t>(value_[0]) << 8) | 
            value_[1];
    }

    // Implicit conversion to native type.
    operator uint16_t() const throw()
    {
        return Get();
    }

    uint8_t value_[2];
};


// Represents a 16-bit signed integer for file formats that use Big Endian conventions.
struct BigEndianShort
{
    // Explicit getter returning native type. Converts from file representation,
    // which is big-endian.
    int16_t Get() const throw()
    {
        // Use unsigned arithmetic for shifting, etc., and then convert to signed type.
        return value_.Get();
    }

    // Implicit conversion to native type.
    operator int16_t() const throw()
    {
        return Get();
    }

    BigEndianUShort value_;
};


// Represents a 32-bit unsigned integer for file formats that use Big Endian conventions.
struct BigEndianULong
{
    // Explicit getter returning native type. Converts from file representation,
    // which is big-endian.
    uint32_t Get() const throw()
    {
        return 
            (static_cast<uint32_t>(value_[0]) << 24) | 
            (static_cast<uint32_t>(value_[1]) << 16) | 
            (static_cast<uint32_t>(value_[2]) << 8) | 
            value_[3];
    }

    // Gets the raw integer exactly as-is, no concept of endianess.
    // This is important for table tag comparisons, where the tag
    // is a character sequence instead of a number.
    uint32_t GetRawInt() const throw()
    {
        return *(reinterpret_cast<const UNALIGNED uint32_t*>(value_));
    }

    // Implicit conversion to native type.
    operator uint32_t() const throw()
    {
        return Get();
    }

    uint8_t value_[4];
};


// Represents a 32-bit signed integer for file formats that use Big Endian conventions.
struct BigEndianLong
{
    // Explicit getter returning native type. Converts from file representation,
    // which is big-endian.
    int32_t Get() const throw()
    {
        // Use unsigned arithmetic for shifting, etc., and then convert to signed type.
        return value_.Get();
    }

    // Implicit conversion to native type.
    operator int32_t() const throw()
    {
        return Get();
    }

    BigEndianULong value_;
};

#pragma pack(pop)

