// CS450 - HW4
// Dwayne Robinson
// 2004-11-11
// DynamicArray.c

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#include <windows.h>
#include "dynamicarray.h"


// DynamicArray* dap

void DynamicArray::init(void** pptr, int newGranularity, int newSizeofi) {
	// assert	size >= 0
	//			granularity >= 0
	//			sizeofi >= 0
	//			pptr != NULL
	entries = 0;
	granularity = newGranularity;
	sizeofi = newSizeofi;
	size = newGranularity*newSizeofi;

	// set addrees of data pointer/handle
	ppv = pptr;
	*pptr = GlobalAlloc(GMEM_FIXED, size);
	// if ptr== NULL serious problem!
	// Calling Init twice on the same dynamic array without
	// freeing it in between WILL cause a memory leak.
}


// Frees the array entries associated with the given array.
// Does not clear the array information (like granularity
// and entry size) so that it can reused.
// It IS okay to safely call this more than once.
//
void DynamicArray::free() {
	if (ppv != NULL && *ppv != NULL) {
		GlobalFree(*ppv);
		*ppv = NULL;
	}
	size=0;
}


// Increases array entries by one.
void* DynamicArray::growOne() {
	return grow(++entries);
}

// Increases an array's size if necessary,
// always staying at least granularity entries ahead of
// needed entries plus one.
//
// In:	dap - dynamic array pointer
//		entries - total entries needed
// Returns: new pointer if changed 
//			old pointer if same
//
void* DynamicArray::grow(int entries) {
	int newsize = (entries + 1) * sizeofi;

	if (newsize >= size) {
		newsize += (granularity * sizeofi);
		size = newsize;

		// adjust pointer to new memory block
		if (ppv == NULL) {
			OutputDebugString("DynamicArray_Grow: Array pointer is null!\n");
			return NULL;
		}
		else {
			if (*ppv == NULL) {
				// first time allocating mem block
				//__asm {int 3};
				*ppv = GlobalAlloc(GMEM_FIXED, newsize);
			}
			else {
				// reallocating to enlarge block
				HGLOBAL ptr = GlobalReAlloc(*ppv, newsize, GMEM_MOVEABLE);
				if (ptr == NULL) {
					OutputDebugString("DynamicArray_Grow: Error allocating more memory!\n");
				}
				else {
					*ppv = ptr;
					return ptr;
				}
			}
		}
	}
	return *ppv;
}
