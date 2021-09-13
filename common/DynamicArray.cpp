/**
\file	DynamicArray.cpp
\author	Dwayne Robinson
\since	2004-11-11
\date	2004-05-31
\brief	Dynamic arrays that can grow/shrink and preserve content.

Can use either C or C++ form, depending on DynamicArrayUseCpp is set.
Note that C compilers can only understand structs while C++ compilers
can use either mode.

2004-06-29	Changed all commenting to Doxygen style.
			Add force malloc option in case caller needs it.
*/

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#include <windows.h>
#define DynamicArray_cpp
#include "DynamicArray.h"

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
#if defined(_WINDOWS) && defined(DynamicArrayUseGlobalAlloc)
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
			freeing it in between WILL cause a memory leak.
*/
bool api(Init) (param  void* pv, int granularity, int elsize)
{
	assert(self != null);
	assert(granularity > 0);
	assert(elsize > 0);

	self->granularity = granularity;
	self->elsize = elsize;
	self->size = granularity * elsize;
	self->length = 0;

	// set address of array data pointer/handle
	if (pv) {
		// already allocated, so simply use it
		self->pv = pv;
		//self->size = GlobalSize(pv);
	} else {
		// allocate one with initial number of elements
		self->pv = malloc(self->size);
		if (self->pv == null) {
			self->size = 0;
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
*/
void api(Free) (paramnc)
{
	if (self->pv != null) {
		free(self->pv);
		self->pv = null;
	}
	self->size = 0;
	self->length = 0;
}


/**	Increases an array's size if necessary.
	Stays at least granularity entries ahead of needed entries
	plus one for safety.

\param	dap		dynamic array pointer
\param	entries	total entries needed

\return	true on success
*/
bool api(Grow) (param  int entries)
{
	int newsize = (entries + 1) * self->elsize;

	if (newsize >= self->size) {
		newsize += (self->granularity * self->elsize);
		self->size = newsize;
		self->length = entries;

		// adjust pointer to new memory block
		if (self->pv == null) {
			// first time allocating mem block
			self->pv = malloc(newsize);
		}
		else {
			// reallocating to enlarge block
			void* pv = realloc(self->pv, newsize);
			if (pv == null) {
				OutputDebugString("DynamicArrayGrow: Error allocating more memory!\n");
				return false;
			}
			self->pv = pv;
		}
	}
	return true;
}


/**	Increases array's size if necessary and adjusts pointer.

\param	dap		dynamic array pointer
\param	entries	total entries needed
\param	ppv		pointer to a pointer to adjust

\return	true on success
*/
bool api(GrowPtr) (param  int entries, void** ppv)
{
	assert(self != null);
	assert(entries >= 0);
	assert(self->elsize > 0);
	assert(self->granularity > 0);
	assert(ppv != null);

	if (!api(Grow)(paramnt  entries))
	//if (!DynamicArray::Grow(param  entries))
		return false;

	*ppv = self->pv;
	return true;
}


/**	Compacts the array to use just as much memory as it actually needs for the
	number of elements it contains. Since growth occurs in granular steps, the
	end of the array can have more entries than necessary.

\param	dap		dynamic array pointer
\param	entries	total entries actually used

\return	true on success
*/
bool api(Shrink) (param  int entries)
{
	assert(self != null);
	assert(entries >= 0);
	assert(self->elsize > 0);
	assert(self->granularity > 0);

	self->length = entries;
	return (api(Compact)(paramnc));
}

/**	Compacts the array to use just as much memory as it actually needs for the
	number of elements it contains. Since growth occurs in granular steps, the
	end of the array can have more entries than necessary.

\param	dap		dynamic array pointer
\param	entries	total entries actually used

\return	true on success
*/
bool api(Compact) (paramnc)
{
	void* pv;

	assert(self != null);
	assert(length >= 0);
	assert(self->elsize > 0);
	assert(self->granularity > 0);

	self->size = self->length * self->elsize;
	pv = realloc(self->pv, self->size);
	if (pv == null) {
		OutputDebugString("DynamicArrayCompact: Error reallocating memory!\n");
		return false;
	}
	self->pv = pv;
	return true;
}
