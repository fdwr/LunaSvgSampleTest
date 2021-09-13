// CS450 - HW4
// Dwayne Robinson
// 2004-11-11
// DynamicArray.h

class DynamicArray {
public:
	void** ppv; // pointer to (pointer to data)
	int entries; // NOT used by the class, only outside users
	int size; // byte size of whole array (not including these header vars)
	int granularity; // entries per realloc
	int sizeofi; // byte size of each entry

	void  init(void** pptr, int newGranularity, int newSizeofi);
	void  free();
	void* grow(int entries);
	void* growOne();
};
