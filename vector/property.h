// These are useless on their own, and are meant to be subclassed.

#pragma once
#ifndef property_h
#define property_h

//#define __forceinline inline
// No point in calling a function for every get/set
// if no error checking is being done.

template <typename ValueType, typename OwningClass>
struct property
{
	friend OwningClass;

public:
	property()
	{
	}

	// Overload the = operator to set the value using the set member
	ValueType operator =(const ValueType& valueIn)
	{
		value = valueIn;
		return valueIn;
	}

	// Cast the property class to the internal type
	//inline operator ValueType()
	//{
	//    return value;
	//}

	inline operator ValueType()
	{
	    return value;
	}


protected:
	// only the containing class of the property should directly mess with it
	ValueType value;
};



template <typename ValueType, typename OwningClass>
struct property_readable
{
	friend class OwningClass;

public:
	property_readable()
	{
	}

	// Cast the property class to the internal type
	inline operator ValueType()
	{
	    return value;
	}

protected:
	// only the containing class of the property should directly mess with it
	ValueType value;
};



template <typename ValueType, typename OwningClass>
struct property_writeable
{
	friend class OwningClass;

public:
	property_writeable()
	{
	}

	// Overload the = operator to set the value using the set member
	ValueType operator =(const ValueType& valueIn)
	{
		value = valueIn;
		return valueIn;
	}

protected:
	// only the containing class of the property should directly mess with it
	ValueType value;
};


#ifdef ThisIsNeverDefined
// compiler specific extension
// plus, it supposedly creates two virtual function pointers
// which is overkill if you are just setting an integere.
#ifdef _MSC_VER //Visual C++ 7
class PropTest
{
	public:
	PropTest(){};
	int getCount() const {return m_nCount;}
	void setCount(int nCount){ m_nCount = nCount;}
	__declspec(property(get=getCount, put=setCount)) int Count;

protected:
	int m_nCount;
};	  
#endif
#endif

//#undef __forceinline

#endif
