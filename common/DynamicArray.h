/**
\file	DynamicArray.h
\author	Dwayne Robinson
\since	2004-11-11
\date	2004-05-31
*/

#pragma once
#ifndef DynamicArray_h
#define DynamicArray_h

// force standard C malloc for this project
//#define DynamicArrayForceMalloc

#define DynamicArrayUseCpp

#if !defined(__cplusplus) && !defined(bool)
typedef unsigned char bool; // define the same as C++ does
#endif

#ifdef DynamicArrayUseCpp  // use C++ class
	#ifndef __cplusplus
		#error "DynamicArrayUseCpp was defined, but compiler is not using C++ mode. Ensure file is cpp."
	#endif
	class DynamicArray {
	public:
		union {
			void* pv; // pointer to (pointer to data)
			signed char* pb;
			unsigned char* pub;
			short* ps;
			unsigned short* pus;
			int* pi;
			unsigned int* pui;
			float* pf;
			double* pd;
		};
		int granularity;	// entries per realloc
		int length;			// number of entries. Not actually needed by the
							// code. Just here for convenience.
		int size;			// byte size of whole array (not including these
							// vars). It is public for your information
							// convenience, but do NOT modify it.
	private:
		// this one is private because (a) once you create an array, its
		// type should not change and (b) only the allocator should touch the
		// actual byte size.
		int elsize; // byte size of each element (array index)

	public:
		bool Init(void* pv, int granularity, int elsize);
		void Free();
		bool Grow(int entries);
		bool GrowPtr(int entries, void** ppv);
		bool Shrink(int entries);
		bool Compact();
	};

	#ifdef DynamicArray_cpp
		#define api(name) DynamicArray::##name
		#define param
		#define paramnc // parameter with no comma
		#define paramnt // parameters with no type
		#define self this
	#endif

#else // use C struct
	#ifdef __cplusplus
	extern "C" {
	#endif

	typedef struct {
		union {
			void* pv; // pointer to (pointer to data)
			signed char* pb;
			unsigned char* pub;
			short* ps;
			unsigned short* pus;
			int* pi;
			unsigned int* pui;
			float* pf;
			double* pd;
		};
		int size; // byte size of whole array (not including these vars)
		int granularity; // entries per realloc
		int elsize; // byte size of each element (array index)
	} DynamicArray;

	bool DynamicArrayInit(DynamicArray* dap, void* pv, int granularity, int elsize);
	void DynamicArrayFree(DynamicArray* dap);
	bool DynamicArrayGrow(DynamicArray* dap, int entries);
	bool DynamicArrayGrowPtr(DynamicArray* dap, int entries, void** ppv);
	bool DynamicArrayShrink(DynamicArray* dap, int entries);
	bool DynamicArrayCompact(DynamicArray* dap);

	#ifdef DynamicArray_cpp
		#define api(name) DynamicArray##name
		#define param  DynamicArray* dap,
		#define paramnc DynamicArray* dap // parameter with no comma
		#define paramnt dap, // parameter with no type
		#define self dap
	#endif

	#ifdef __cplusplus
	}
	#endif
#endif

#endif
