//---------------------------------------------------------------------------
//  File:     Cpp0xSkeleton.h
//
//  Synopsis: Basic C++0x functionality to avoid requiring VC 2010.
//---------------------------------------------------------------------------

#pragma once

// 
namespace std
{

template <class T>
struct make_unsigned
{
};

template <>
struct make_unsigned<int>
{
   typedef unsigned int type;
};

};
