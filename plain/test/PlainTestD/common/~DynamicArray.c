/**
\file	DynamicArray.c
\author	Dwayne Robinson
\since	2004-11-11
\date	2004-05-31
\brief	Dynamic arrays that can grow/shrink and preserve content.

2004-06-29	Changed all commenting to Doxygen style.
*/

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#include <windows.h>
#include "DynamicArray.h"

#include "assert.h"

#if !defined(__cplusplus)
#define false 0
#define true 1
#endif

#ifdef DynamicArrayUseMalloc
  #include <malloc.h>
#else
  // use standard C malloc, free, realloc instead of system.
  #define malloc(size)			GlobalAlloc(GMEM_FIXED, size)
  #define free(ptr)				GlobalFree(ptr)
  #define realloc(ptr, size)	GlobalReAlloc(ptr, size, GMEM_MOVEABLE)
#endif

#ifndef _WINDOWS
  #define OutputDebugString //
#endif

/** Initializes a dynamic array with given data type and number of entries.

\param	dap			pointer to dynamic array
\param	pv			pointer to data (the actual array elements)
\param	granularity	step size to grow (when necessary)
\param	elsize		byte size of each element (int array = 4 bytes)

\return	true on success

\warning	Calling Init twice on the same dynamic array without
			freeing it in between WILL cause a memory leak.
*/
bool DynamicArrayInit(DynamicArray* dap, void* pv, int granularity, int elsize)
{
	assert(dap != NULL);
	assert(granularity > 0);
	assert(elsize > 0);

	dap->granularity = granularity;
	dap->elsize = elsize;

	// set address of array data pointer/handle
	if (pv) {
		// already allocated, so simply use it
		dap->pv = pv;
		//dap->size = GlobalSize(pv);
		dap->size = granularity*elsize;
	} else {
		// allocate one with initial number of elements
		dap->size = granularity*elsize;
		dap->pv = malloc(dap->size);
		if (dap->pv == NULL)
			return false;
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
void DynamicArrayFree(DynamicArray *dap)
{
	if (dap->pv != NULL) {
		free(dap->pv);
		dap->pv = NULL;
	}
	dap->size=0;
}


/**	Increases an array's size if necessary.
	Stays at least granularity entries ahead of needed entries
	plus one for safety.

\param	dap		dynamic array pointer
\param	entries	total entries needed

\return	true on success
*/
bool DynamicArrayGrow(DynamicArray* dap, int entries)
{
	int newsize = (entries + 1) * dap->elsize;

	if (newsize >= dap->size) {
		newsize += (dap->granularity * dap->elsize);
		dap->size = newsize;

		// adjust pointer to new memory block
		if (dap->pv == NULL) {
			// first time allocating mem block
			//__asm {int 3};
			dap->pv = malloc(newsize);
		}
		else {
			// reallocating to enlarge block
			void* pv = realloc(dap->pv, newsize);
			if (pv == NULL) {
				OutputDebugString("DynamicArrayGrow: Error allocating more memory!\n");
				return false;
			}
			dap->pv = pv;
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
bool DynamicArrayGrowPtr(DynamicArray* dap, int entries, void** ppv)
{
	assert(dap != NULL);
	assert(entries >= 0);
	assert(dap->elsize > 0);
	assert(dap->granularity > 0);
	assert(ppv != NULL);

	if (!DynamicArrayGrow(dap, entries))
		return false;

	*ppv = dap->pv;
	return true;
}

/**	Compacts the array to use just as much memory as it actually needs for the
	number of elements it contains. Since growth occurs in granular steps, the
	end of the array can have more entries than necessary.

\param	dap		dynamic array pointer
\param	entries	total entries actually used

\return	true on success
*/
bool DynamicArrayCompact(DynamicArray* dap, int entries)
{
	void* pv;

	assert(dap != NULL);
	assert(entries >= 0);
	assert(dap->elsize > 0);
	assert(dap->granularity > 0);

	dap->size = entries * dap->elsize;
	pv = realloc(dap->pv, dap->size);
	if (pv == NULL) {
		OutputDebugString("DynamicArrayCompact: Error reallocating memory!\n");
		return false;
	}
	dap->pv = pv;
	return true;
}
