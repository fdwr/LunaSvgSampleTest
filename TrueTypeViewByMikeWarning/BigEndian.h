//---------------------------------------------------------------------------
//  File:       BigEndian.h
//
//  Synopsis:   Provide a generic class to read big-endian data
//---------------------------------------------------------------------------

#pragma once

typedef unsigned __int16 uint16_t;
typedef __int64          int64_t;



template <typename T>
struct BigEndian
{
    T   value;

    template <int S>
    T convert(const T & x) const;

    template <>
    T convert<2>(const T & x) const
    {
        USHORT r = _byteswap_ushort(* (USHORT *) &x);
        return * (T *) &r;
    }

    template <>
    T convert<4>(const T & x) const
    {
        ULONG r = _byteswap_ulong(* (ULONG *) &x);
        return * (T *) &r;
    }

    template <>
    T convert<8>(const T & x) const
    {
        unsigned __int64 r = _byteswap_uint64(* (unsigned __int64 *) &x);
        return * (T *) &r;
    }

    operator T () const {return convert<sizeof(T)>(value);}
};

