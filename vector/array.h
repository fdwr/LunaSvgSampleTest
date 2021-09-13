/*
Simply a bare bones hack of the STL vector
that avoids invalidating pointers inside
classes by using placement new rather than
using a stupid temporary copy.
*/

#error "Do not use this until I find the reallocation bug! Use std::vector instead."

#pragma once
#ifndef _ARRAY_
#define _ARRAY_
#include <new>
#include <memory>
#include <stdexcept>
#include <assert.h>

#pragma pack(push,8)
#pragma warning(push,3)

#pragma warning(disable: 4244)

_STD_BEGIN

template<class _Ty>
class array
{	// varying size array of values

	typedef _Ty* pointer;
	typedef _Ty* iterator;

public:
	array() : _Myfirst(0), _Mylast(0), _Myend(0)
	{
	}

	void _destroy_range(iterator front, iterator back)
	{
		if (front == 0) return;
		for (back--; back >= front; back--) {
			//delete pitem
			back->~_Ty();
		}
	}

	void _init_range(iterator front, iterator back)
	{
		for (; front < back; front++) {
			new ((void*)front) _Ty;
		}
	}

	~array()
	{
		_destroy_range(_Myfirst, _Mylast);
		free(_Myfirst);
		_Myfirst = _Mylast = _Myend = 0;
	}

	int capacity() const
	{	// return current length of allocated storage
		return (_Myfirst == 0 ? 0 : _Myend - _Myfirst);
	}

	int size() const
	{	// return length of sequence
		//return (_Myfirst == 0 ? 0 : _Mylast - _Myfirst);
		return _Mylast - _Myfirst;
	}

	bool empty() const
	{	// test if sequence is empty
		return (size() == 0);
	}

	_Ty& operator[](int _Pos)
	{	// subscript mutable sequence
		//return (*(begin() + _Pos));
		return *(_Myfirst + _Pos);
	}

private:
	void grow(int _Newsize)
	{
		if (begin() + _Newsize > _Myend) {
			int newCapacity = (_Myend - _Myfirst) * 2; // double buffer size
			if (_Newsize > newCapacity) newCapacity = _Newsize;
			if (_Myfirst == 0)
				_Myfirst = (pointer)malloc(sizeof(_Ty) * newCapacity);
			else
				_Myfirst = (pointer)realloc(_Myfirst, sizeof(_Ty) * newCapacity);
			assert(_Myfirst != 0);
			_Myend  = _Myfirst + newCapacity;
		}
		else {
			//_Myend = <same>
		}
		_Mylast = _Myfirst + _Newsize;
	}

public:
	void resize(int _Newsize)
	{	// determine new length, padding with _Val elements as needed
		int oldSize = size();
		if (_Newsize > oldSize) {
			//_Insert_n(end(), _Newsize - size(), _Val);
			grow(_Newsize);
			_init_range(begin() + oldSize, end());
		}
		else if (_Newsize < oldSize) {
			_destroy_range(begin() + _Newsize, end());
			_Mylast = _Myfirst + _Newsize;
		}
	}

	void trim()
	{
		//
	}

	iterator begin()
	{	// return iterator for beginning of mutable sequence
		return (_Myfirst);
	}

	iterator end()
	{	// return iterator for end of mutable sequence
		return (_Mylast);
	}

	void push_back(const _Ty& _Val)
	{	// insert element at end
		int oldSize = size();
		grow(oldSize+1);
		memcpy(begin() + oldSize, &_Val, sizeof(_Ty));
		//_init_range(begin() + oldSize, end());
	}

public:
	pointer _Myfirst;	// pointer to beginning of array
	pointer _Mylast;	// pointer to current end of sequence
	pointer _Myend;	// pointer to end of array
};

_STD_END
  #pragma warning(default: 4244)
#pragma warning(pop)
#pragma pack(pop)

#endif /* _ARRAY_ */
										