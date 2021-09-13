/**
\file	Darray.cpp
\author	Dwayne Robinson
\date	2004-08-06
\since	2004-05-31
\brief	Dynamic arrays that can grow/shrink and preserve content.

Can use either C or C++ form, depending on DarrayUseCpp is set.
Note that C compilers can only understand structs while C++ compilers
can use either mode.

2004-06-29	Changed all commenting to Doxygen style.
			Add force malloc option in case caller needs it.
2004-09-02	Renamed to Darray. Should this be scrapped in favor of STL?
*/

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#include <windows.h>
#define Darray_cpp
#include "Darray.h"

#include "assert.h"

#if !defined(__cplusplus) // define what should have been defined long ago
#define false 0
#define true 1
#endif
#define null 0

// Whichever method you use to allocate memory, you should be consistent.
// If you do mix allocation types, at least always free memory with the
// counterpart of what you malloced it with (so don't call free() on
// something that was GlobalAlloc'd).
#if defined(_WINDOWS) && defined(DarrayUseGlobalAlloc)
  // use standard C malloc, free, realloc instead of system.
  #define malloc(size)			GlobalAlloc(GMEM_FIXED, size)
  #define free(ptr)				GlobalFree(ptr)
  #define realloc(ptr, size)	GlobalReAlloc(ptr, size, GMEM_MOVEABLE)
#else
  #include <malloc.h>
#endif

#ifndef _WINDOWS
  #define OutputDebugString //
#endif

/** Initializes a dynamic array with given data type and number of entries.

\param	dap			pointer to dynamic array
\param	pv			pointer to existing data (leave null to allocate automatically)
\param	granularity	step size to grow (when necessary)
\param	elsize		byte size of each element (int array = 4 bytes)

\return	true on success

\warning	Calling Init twice on the same dynamic array without
			freeing it in between WILL cause a memory leak. If this is what
			you intend (because the previous array was already attached to
			some other object) then doing so is fine.
*/
bool api(init) (param  void* pv, int granularity, int elsize)
{
	assert(this != null);
	assert(granularity > 0);
	assert(elsize > 0);

	this->granularity = granularity;
	this->elsize = elsize;
	this->size = granularity * elsize;
	this->length = 0;

	// set address of array data pointer/handle
	if (pv) {
		// already allocated, so simply use it
		this->pv = pv;
		//this->size = GlobalSize(pv);
	} else {
		// allocate one with initial number of elements
		this->pv = malloc(this->size);
		if (this->pv == null) {
			this->size = 0;
			return false;
		}
	}
	return true;
}


/**	Frees the array entries associated with the given array.
	Does not clear the array information (like granularity
	and entry size) so that it can reused.
	It IS okay to safely call this more than once.

\param	dap		dynamic array pointer

\return	none (assumed to always succeed)

\warning	The base pointer is INVALID after calling this function.
*/
void api(free) (paramnc)
{
	if (this->pv != null) {
		::free(this->pv);
		this->pv = null;
	}
	this->size = 0;
	this->length = 0;
}


/**	Increases an array's size if necessary.
	Stays at least granularity entries ahead of needed entries
	plus one for safety.

\param	dap		dynamic array pointer
\param	entries	total entries needed

\return	true on success

\warning	This function MAY change the array base pointer.
*/
bool api(grow) (param  int entries)
{
	int newsize = (entries + 1) * this->elsize;

	if (entries > this->length)
		this->length = entries;
	if (newsize >= this->size) {
		newsize += (this->granularity * this->elsize);
		this->size = newsize;

		// adjust pointer to new memory block
		if (this->pv == null) {
			// first time allocating mem block
			this->pv = malloc(newsize);
		}
		else {
			// reallocating to enlarge block
			void* pv = realloc(this->pv, newsize);
			if (pv == null) {
				OutputDebugString("DarrayGrow: Error allocating more memory!\n");
				return false;
			}
			this->pv = pv;
		}
	}
	return true;
}


/**	Increases array's size if necessary and adjusts pointer.

\param	dap		dynamic array pointer
\param	entries	total entries needed
\param	ppv		pointer to a pointer to adjust

\return	true on success

\warning	This function MAY change the array base pointer.
*/
bool api(growPtr) (param  int entries, void** ppv)
{
	assert(this != null);
	assert(entries >= 0);
	assert(this->elsize > 0);
	assert(this->granularity > 0);
	assert(ppv != null);

	if (!api(grow)(paramnt  entries))
	//if (!Darray::Grow(param  entries))
		return false;

	*ppv = this->pv;
	return true;
}


/**	Increases an array's size by one entry.
	Stays at least granularity entries ahead of needed entries
	plus one for safety.

\param	dap		dynamic array pointer
\param	entries	total entries needed

\return	true on success

\remark	Just for convenience.

\warning	This function MAY change the array base pointer.
*/
bool api(growByOne) (paramnc)
{
	return (api(grow)(paramnt  this->length+1));
}


/**	Compacts the array to use just as much memory as it actually needs for the
	number of elements specified. Since growth occurs in granular steps, the
	end of the array can have more entries than necessary.

\param	dap		dynamic array pointer
\param	entries	total entries actually used

\return	true on success

\warning	This function MAY change the array base pointer.
*/
bool api(shrink) (param  int entries)
{
	assert(this != null);
	assert(entries >= 0);
	assert(this->elsize > 0);
	assert(this->granularity > 0);

	this->length = entries;
	return (api(compact)(paramnc));
}


/**	Compacts the array to use just as much memory as it actually needs for the
	number of elements it contains. Since growth occurs in granular steps, the
	end of the array can have more entries than necessary.

\param	dap		dynamic array pointer
\param	entries	total entries actually used

\return	true on success

\warning	This function MAY change the array base pointer.
*/
bool api(compact) (paramnc)
{
	void* pv;

	assert(this != null);
	assert(length >= 0);
	assert(this->elsize > 0);
	assert(this->granularity > 0);

	this->size = this->length * this->elsize;
	if (this->size <= 0) this->size = 1; // prevent it returning null
	pv = realloc(this->pv, this->size);
	if (pv == null) {
		OutputDebugString("DarrayCompact: Error reallocating memory!\n");
		return false;
	}
	this->pv = pv;
	return true;
}


/**	Deletes an indexed element from the array.

\param	dap		dynamic array pointer
\param	entry	index of array element to delete

\return	true on success

\remark	Just for convenience, so you need not do the error prone memmove.
\remark	The pointer does NOT change after calling this function.
\remark	Call Compact after using this function if you want to reclaim memory.

\warning	If the array consists of classes, call the class's destructor
			first.
*/
bool api(remove) (param  int entry)
{
	// \TODO - FUNCTION UNTESTED
	assert(this != null);
	assert(this->elsize > 0);
	assert(this->granularity > 0);

	if (entry >= this->length) return false;
	this->length--;
	memmove( // shift all elements lower
		this->pb + ((entry + 0) * this->elsize),
		this->pb + ((entry + 1) * this->elsize),
		(this->length -  entry) * this->elsize);
	return true;
}


/**	Inserts an indexed element to the array.

\param	dap		dynamic array pointer
\param	entry	index of array element to insert (0-length)

\return	true on success

\remark	Just for convenience, so you need not do the error prone memmove.

\warning	This function MAY change the array base pointer.
*/
bool api(insert) (param  int entry, void* pitem)
{
	// \TODO - FUNCTION UNTESTED
	assert(this != null);
	assert(this->elsize > 0);
	assert(this->granularity > 0);

	if (!api(grow)(paramnt  this->length))
	//if (!Darray::Grow(param  entries))
		return false;

	if (entry > this->length) return false;

	memmove( // shift all elements higher
		this->pb + ((entry + 1) * this->elsize),
		this->pb + ((entry + 0) * this->elsize),
		(this->length -  entry) * this->elsize);

	memcpy( // copy new element
		this->pb + ((entry + 0) * this->elsize),
		pitem,
		this->elsize);

	this->length++;
	return true;
}
